import { exec } from 'child_process'
import { promisify } from 'util'
import { readFile, writeFile, rm, mkdir } from 'fs/promises'
import { create as createTar } from 'tar'
import path from 'path'
import { parseISO } from 'date-fns'
import { formatInTimeZone } from 'date-fns-tz'
import supabaseClient from 'src/auth/supabase-client'
import { getDb } from 'src/db'
import env from 'src/env'
import logger from 'src/logger'

/*
To restore mongodump backup:

mongorestore 
--archive=/Users/knguyen/Downloads/{backup-file-name}.gz --gzip 
--uri="mongodb+srv://{username}:{password}@cluster0.puox5gp.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0" 
--nsFrom=apps-dev.* --nsTo=apps-backup-restore-test.*
--dryRun

Notes:
- --archive and --gzip: needed because we used them for creating backup
- Replace {username} and {password} with actual values
- --nsFrom and --nsTo: to rename the database, useful for testing, may not be needed in real world
- --dryRun: check for errors without making actual changes
*/

/**
 * Starts the backup service with periodic checks
 */
export function startBackupService(): void {
  startBackupServiceAsync()
    .catch(e => { }) // Error handled internally
}

async function startBackupServiceAsync(): Promise<void> {
  logger.info(`Starting backup service (check interval: ${formatDuration(config.checkIntervalMs)}, retention: ${formatDuration(config.retentionMs)})`)

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

      if (config.isSamePeriodFn(mostRecentBackup.createdAt, now)) {
        logger.info(`Backup already exists for backup period: ${mostRecentBackup.name}`)
        return
      }
    }

    // No backup for today, create one

    logger.info('No backup found for backup period, creating new backup...')
    await createBackupWithMongodump()

    // Delete old backups

    await deleteOldBackups(backupFiles)

  } catch (error) {
    logger.error(error, 'Error in backup check')
  }
}

/**
 * Creates a MongoDB backup using mongodump with gzip compression
 */
async function createBackupWithMongodump(): Promise<void> {
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
    const execAsync = promisify(exec)
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
 * Creates a MongoDB backup by exporting collections to separate JSON files and creating tar.gz archive
 */
async function createBackupAsJsonFiles(): Promise<void> {
  try {
    logger.info('Starting database backup...')

    // Ensure tmp folder exists
    await mkdir(TEMP_FOLDER, { recursive: true })

    // Generate paths
    const timestamp = formatInTimeZone(new Date(), 'UTC', "yyyy-MM-dd'T'HH-mm-ss'Z'")
    const backupDir = path.join(TEMP_FOLDER, timestamp)
    const archiveName = `${timestamp}.tar.gz`
    const archivePath = path.join(TEMP_FOLDER, archiveName)

    // Create backup directory
    await mkdir(backupDir, { recursive: true })

    // Export each collection to separate JSON file
    logger.info('Exporting database collections...')
    const db = await getDb()
    const collections = await db.listCollections().toArray()

    for (const collectionInfo of collections) {
      const collectionName = collectionInfo.name
      const collection = db.collection(collectionName)
      const documents = await collection.find({}).toArray()

      const jsonPath = path.join(backupDir, `${collectionName}.json`)
      await writeFile(jsonPath, JSON.stringify(documents, null, 2))

      logger.info(`Exported collection: ${collectionName} (${documents.length} documents)`)
    }

    // Create tar.gz archive

    logger.info('Creating tar.gz archive...')
    await createTar(
      {
        gzip: true,
        file: archivePath,
        cwd: TEMP_FOLDER
      },
      [timestamp]
    )

    logger.info(`Archive created: ${archivePath}`)

    // Read archive for upload
    const archiveData = await readFile(archivePath)
    logger.info(`Archive size: ${archiveData.length} bytes`)

    // Upload to Supabase Storage
    const filePath = `${config.supabaseBackupFolder}/${archiveName}`
    const { error } = await supabaseClient.storage
      .from(config.supabaseBucket)
      .upload(filePath, archiveData, {
        contentType: 'application/gzip',
        upsert: false
      })

    if (error) {
      throw error
    }

    logger.info(`Backup uploaded successfully: ${archiveName}`)

    // Clean up temp files
    await rm(backupDir, { recursive: true, force: true })
    await rm(archivePath, { force: true })
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
 * Formats milliseconds into a human-readable duration string
 */
function formatDuration(ms: number): string {
  const seconds = Math.floor(ms / 1000)
  const minutes = Math.floor(seconds / 60)
  const hours = Math.floor(minutes / 60)
  const days = Math.floor(hours / 24)

  const parts: string[] = []
  if (days > 0) parts.push(`${days}d`)
  if (hours % 24 > 0) parts.push(`${hours % 24}h`)
  if (minutes % 60 > 0) parts.push(`${minutes % 60}m`)
  if (seconds % 60 > 0) parts.push(`${seconds % 60}s`)

  return parts.length > 0 ? parts.join(' ') : '0s'
}

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
 * Checks if two dates are in the same hour (UTC)
 */
function isSameHourUTC(date1: Date, date2: Date): boolean {
  return (
    date1.getUTCFullYear() === date2.getUTCFullYear() &&
    date1.getUTCMonth() === date2.getUTCMonth() &&
    date1.getUTCDate() === date2.getUTCDate() &&
    date1.getUTCHours() === date2.getUTCHours()
  )
}

/**
 * Checks if two dates are in the same minute (UTC)
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


const config: Config = (() => {
  switch (env.nodeEnv) {
    case 'production':
      return {
        checkIntervalMs: 5 * 60 * 1000, // 5 minutes
        retentionMs: 30 * 24 * 60 * 60 * 1000, // 30 days
        isSamePeriodFn: isSameDayUTC,
        supabaseBucket: 'apps',
        supabaseBackupFolder: 'db-backup',
      }

    case 'development':
      return {
        checkIntervalMs: 5 * 60 * 1000,
        retentionMs: 12 * 60 * 60 * 1000,
        isSamePeriodFn: isSameHourUTC,
        supabaseBucket: 'apps-dev',
        supabaseBackupFolder: 'db-backup',
      }
  }
})()

interface Config {
  checkIntervalMs: number
  retentionMs: number
  isSamePeriodFn: (date1: Date, date2: Date) => boolean
  supabaseBucket: string
  supabaseBackupFolder: string
}

const TEMP_FOLDER = path.join(__dirname, '../tmp/backups')