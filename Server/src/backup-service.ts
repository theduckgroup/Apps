import { exec } from 'child_process'
import { promisify } from 'util'
import { readFile, rm, mkdir } from 'fs/promises'
import path from 'path'
import { parseISO } from 'date-fns'
import { formatInTimeZone } from 'date-fns-tz'
import supabaseClient from 'src/auth/supabase-client'
import env from 'src/env'
import logger from 'src/logger'

const execAsync = promisify(exec)

/**
 * Starts the backup service with periodic checks
 */
export function startBackupService(): void {
  startBackupServiceAsync()
    .catch(e => { }) // Error handled internally
}

async function startBackupServiceAsync(): Promise<void> {
  logger.info(`Starting backup service (check interval: ${config.checkIntervalMs}ms, retention: ${config.retentionMs}ms)`)

  // Clean up temp folder
  await cleanupTempFolder()

  // Run initial check
  checkAndCreateBackup()
    .catch(e => { })

  // Schedule periodic checks
  setInterval(() => {
    checkAndCreateBackup()
      .catch(e => { })
  }, config.checkIntervalMs)
}

/**
 * Cleans up the temp folder to remove any leftover files from previous crashes
 */
async function cleanupTempFolder(): Promise<void> {
  try {
    logger.info(`Cleaning up backup tmp folder: ${TEMP_FOLDER}`)
    await rm(TEMP_FOLDER, { recursive: true, force: true })
    await mkdir(TEMP_FOLDER, { recursive: true })

  } catch (error) {
    // Log error and continue
    logger.error(error, 'Error cleaning up temp folder')

  }
}

/**
 * Checks if a backup is needed and creates one if necessary
 */
async function checkAndCreateBackup(): Promise<void> {
  try {
    logger.info('Checking backup...')

    const backupFiles = await listBackupFiles()
    const now = new Date()

    // Check if we have a backup from today (UTC)

    if (backupFiles.length > 0) {
      const mostRecentBackup = backupFiles[0]

      if (config.isSameDayFn(mostRecentBackup.createdAt, now)) {
        logger.info(`Backup already exists for today: ${mostRecentBackup.name}`)
        return
      }
    }

    // No backup for today, create one

    logger.info('No backup found for today, creating new backup...')
    await createBackup()

    // Delete old backups

    await deleteOldBackups(backupFiles)

  } catch (error) {
    logger.error(error, 'Error in backup check')
  }
}

/**
 * Creates a MongoDB backup using mongodump with gzip compression
 */
async function createBackup(): Promise<void> {
  try {
    logger.info('Starting database backup...')

    // Ensure tmp folder exists
    await mkdir(TEMP_FOLDER, { recursive: true })

    // Generate filename and paths
    const filename = generateBackupFilename()
    const backupDir = path.join(TEMP_FOLDER, path.basename(filename, path.extname(filename)))
    const archivePath = path.join(backupDir, filename)

    // Create backup directory
    await mkdir(backupDir, { recursive: true })

    // Run mongodump with --gzip and --archive
    const mongodumpCmd = `mongodump --uri="${env.mongodb.uri}" --db="${env.mongodb.dbName}" --gzip --archive="${archivePath}"`

    logger.info('Running mongodump...')
    await execAsync(mongodumpCmd)

    logger.info(`Database dumped to: ${archivePath}`)

    // Read the compressed archive
    const archiveData = await readFile(archivePath)
    logger.info(`Archive size: ${archiveData.length} bytes`)

    // Upload to Supabase Storage
    const filePath = `${config.supabaseBackupFolder}/${filename}`
    const { error } = await supabaseClient.storage
      .from(config.supabaseBucket)
      .upload(filePath, archiveData, {
        contentType: 'application/gzip',
        upsert: false
      })

    if (error) {
      throw error
    }

    logger.info(`Backup uploaded successfully: ${filename}`)

    // Clean up temp files
    await rm(backupDir, { recursive: true, force: true })
    logger.info('Temporary files cleaned up')

  } catch (error) {
    logger.error(error, 'Error creating backup')
    throw error
  }
}

/**
 * Deletes backups older than the retention period
 */
async function deleteOldBackups(backupFiles: BackupFile[]): Promise<void> {
  try {
    const now = new Date()

    const filesToDelete: string[] = []

    for (const backup of backupFiles) {
      const ageMs = now.getTime() - backup.createdAt.getTime()
      if (ageMs > config.retentionMs) {
        filesToDelete.push(backup.name)
      }
    }

    if (filesToDelete.length === 0) {
      logger.info('No old backups to delete')
      return
    }

    logger.info(`Deleting ${filesToDelete.length} old backup(s)...`)

    // Delete files from Supabase Storage
    const filePaths = filesToDelete.map(name => `${config.supabaseBackupFolder}/${name}`)
    const { error } = await supabaseClient.storage
      .from(config.supabaseBucket)
      .remove(filePaths)

    if (error) {
      throw error
    }

    logger.info(`Successfully deleted ${filesToDelete.length} old backup(s)`)

  } catch (error) {
    logger.error(error, 'Error deleting old backups')
  }
}

/**
 * Lists backup files from Supabase Storage, sorted by date (most recent first)
 */
async function listBackupFiles(): Promise<BackupFile[]> {
  try {
    const { data, error } = await supabaseClient.storage
      .from(config.supabaseBucket)
      .list(config.supabaseBackupFolder, {
        sortBy: { column: 'created_at', order: 'desc' }
      })

    if (error) {
      throw error
    }

    if (!data) {
      return []
    }

    // Parse filenames and filter out invalid ones
    const backupFiles: BackupFile[] = []
    for (const file of data) {
      const createdAt = parseBackupFilename(file.name)
      if (createdAt) {
        backupFiles.push({ name: file.name, createdAt })
      }
    }

    // Sort by date descending (most recent first)
    backupFiles.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())

    return backupFiles

  } catch (error) {
    logger.error(error, 'Error listing backup files')
    return []
  }
}

/**
 * Parses ISO 8601 filename (e.g., "2026-01-03T10-30-00Z.gz")
 * 
 * Returns null if the filename doesn't match the expected format
 */
function parseBackupFilename(filename: string): Date | null {
  // Match ISO 8601 format without spaces: YYYY-MM-DDTHH-MM-SSZ.gz
  const match = filename.match(/^(\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}Z)\.gz$/)

  if (!match) {
    return null
  }

  try {
    // Convert hyphens back to colons for ISO 8601 parsing
    const isoString = match[1].replace(/T(\d{2})-(\d{2})-(\d{2})Z/, 'T$1:$2:$3Z')
    const date = parseISO(isoString)

    // Validate the date is valid
    if (isNaN(date.getTime())) {
      return null
    }

    return date
  } catch {
    return null
  }
}

interface BackupFile {
  name: string
  createdAt: Date
}

// Utils

/**
 * Generates a backup filename using ISO 8601 format without spaces (UTC timezone)
 */
function generateBackupFilename(): string {
  // Format: YYYY-MM-DDTHH-MM-SSZ.gz (colons replaced with hyphens for filename compatibility)
  const isoString = formatInTimeZone(new Date(), 'UTC', "yyyy-MM-dd'T'HH-mm-ss'Z'")
  return `${isoString}.gz`
}

/**
 * Checks if two dates are on the same day (UTC)
 */
function isSameDayUTC(date1: Date, date2: Date): boolean {
  return (
    date1.getUTCFullYear() === date2.getUTCFullYear() &&
    date1.getUTCMonth() === date2.getUTCMonth() &&
    date1.getUTCDate() === date2.getUTCDate()
  )
}

/**
 * Checks if two dates are in the same minute (UTC) - for testing
 */
function isSameMinuteUTC(date1: Date, date2: Date): boolean {
  return (
    date1.getUTCFullYear() === date2.getUTCFullYear() &&
    date1.getUTCMonth() === date2.getUTCMonth() &&
    date1.getUTCDate() === date2.getUTCDate() &&
    date1.getUTCHours() === date2.getUTCHours() &&
    date1.getUTCMinutes() === date2.getUTCMinutes()
  )
}

// Configuration
// Adjust these values for testing and production

const config: Config = env.nodeEnv == 'production' ?
  {
    checkIntervalMs: 5 * 60 * 1000, // 5 minutes
    retentionMs: 30 * 24 * 60 * 60 * 1000, // 30 days
    supabaseBucket: 'apps',
    supabaseBackupFolder: 'db-backup',
    isSameDayFn: isSameDayUTC
  } :
  {
    checkIntervalMs: 30 * 1000, // 30 seconds
    retentionMs: 2 * 60 * 1000, // 2 minutes
    supabaseBucket: 'apps-dev',
    supabaseBackupFolder: 'db-backup',
    isSameDayFn: isSameMinuteUTC
  }

interface Config {
  checkIntervalMs: number
  retentionMs: number
  supabaseBucket: string
  supabaseBackupFolder: string
  isSameDayFn: (date1: Date, date2: Date) => boolean
}

const TEMP_FOLDER = path.join(__dirname, '../tmp/backups')