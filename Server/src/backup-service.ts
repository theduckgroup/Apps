import { exec } from 'child_process'
import { promisify } from 'util'
import { readFile, rm, mkdir } from 'fs/promises'
import path from 'path'
import supabaseClient from 'src/auth/supabase-client'
import env from 'src/env'
import logger from 'src/logger'

const execAsync = promisify(exec)

/**
 * Starts the backup service with periodic checks
 */
export function startBackupService(): void {
  logger.info(`Starting backup service (check interval: ${BACKUP_CHECK_INTERVAL_MS}ms, ${BACKUPS_PER_DAY} backup/day, retention: ${BACKUP_RETENTION_DAYS} days)`)

  // Run initial check
  void checkAndCreateBackup()

  // Schedule periodic checks
  setInterval(() => {
    void checkAndCreateBackup()
  }, BACKUP_CHECK_INTERVAL_MS)
}

/**
 * Checks if a backup is needed and creates one if necessary
 */
async function checkAndCreateBackup(): Promise<void> {
  try {
    const backupFiles = await listBackupFiles()
    const now = new Date()

    // Check if we have a backup from today
    if (backupFiles.length > 0) {
      const mostRecentBackup = backupFiles[0]

      if (isSameDay(mostRecentBackup.createdAt, now)) {
        logger.info(`Backup already exists for today: ${mostRecentBackup.name}`)
        return
      }
    }

    // No backup for today, create one
    logger.info('No backup found for today, creating new backup...')
    await createBackup()
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
    await mkdir(TMP_FOLDER, { recursive: true })

    // Generate filename and paths
    const filename = generateBackupFilename()
    const backupDir = path.join(TMP_FOLDER, `backup-${Date.now()}`)
    const archivePath = path.join(backupDir, filename)

    // Create backup directory
    await mkdir(backupDir, { recursive: true })

    // Run mongodump with gzip compression
    const mongodumpCmd = `mongodump --uri="${env.mongodb.uri}" --db="${env.mongodb.dbName}" --gzip --archive="${archivePath}"`

    logger.info('Running mongodump...')
    await execAsync(mongodumpCmd)

    logger.info(`Database dumped to: ${archivePath}`)

    // Read the compressed archive
    const archiveData = await readFile(archivePath)
    logger.info(`Archive size: ${archiveData.length} bytes`)

    // Upload to Supabase Storage
    const filePath = `${SUPABASE_BACKUP_FOLDER}/${filename}`
    const { error } = await supabaseClient.storage
      .from(SUPABASE_BUCKET)
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

    // Delete old backups after creating a new one
    await deleteOldBackups()

  } catch (error) {
    logger.error(error, 'Error creating backup')
    throw error
  }
}

/**
 * Deletes backups older than the retention period
 */
async function deleteOldBackups(): Promise<void> {
  try {
    const backupFiles = await listBackupFiles()
    const now = new Date()
    const retentionMs = BACKUP_RETENTION_DAYS * 24 * 60 * 60 * 1000

    const filesToDelete: string[] = []

    for (const backup of backupFiles) {
      const ageMs = now.getTime() - backup.createdAt.getTime()
      if (ageMs > retentionMs) {
        filesToDelete.push(backup.name)
      }
    }

    if (filesToDelete.length === 0) {
      logger.info('No old backups to delete')
      return
    }

    logger.info(`Deleting ${filesToDelete.length} old backup(s)...`)

    // Delete files from Supabase Storage
    const filePaths = filesToDelete.map(name => `${SUPABASE_BACKUP_FOLDER}/${name}`)
    const { error } = await supabaseClient.storage
      .from(SUPABASE_BUCKET)
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
      .from(SUPABASE_BUCKET)
      .list(SUPABASE_BACKUP_FOLDER, {
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
 * Returns null if the filename doesn't match the expected format
 */
function parseBackupFilename(filename: string): Date | null {
  // Match ISO 8601 format without spaces: YYYY-MM-DDTHH-MM-SSZ.gz
  const match = filename.match(/^(\d{4})-(\d{2})-(\d{2})T(\d{2})-(\d{2})-(\d{2})Z\.gz$/)

  if (!match) {
    return null
  }

  const [, year, month, day, hour, minute, second] = match
  const dateStr = `${year}-${month}-${day}T${hour}:${minute}:${second}Z`
  const date = new Date(dateStr)

  // Validate the date is valid
  if (isNaN(date.getTime())) {
    return null
  }

  return date
}

interface BackupFile {
  name: string
  createdAt: Date
}

// Utils

/**
 * Generates a backup filename using ISO 8601 format without spaces
 */
function generateBackupFilename(): string {
  const now = new Date()
  // Format: YYYY-MM-DDTHH-MM-SSZ.gz
  const isoString = now.toISOString().replace(/:/g, '-').replace(/\.\d{3}/, '')
  return `${isoString}.gz`
}

/**
 * Checks if two dates are on the same day (UTC)
 */
function isSameDay(date1: Date, date2: Date): boolean {
  return (
    date1.getUTCFullYear() === date2.getUTCFullYear() &&
    date1.getUTCMonth() === date2.getUTCMonth() &&
    date1.getUTCDate() === date2.getUTCDate()
  )
}

// Configuration - adjust these values for testing and production

const BACKUP_CHECK_INTERVAL_MS = 5 * 60 * 1000 // Check every 5 minutes
const BACKUPS_PER_DAY = 1 // One backup per day
const BACKUP_RETENTION_DAYS = 30 // Delete backups older than 30 days

const SUPABASE_BUCKET = 'apps'
const SUPABASE_BACKUP_FOLDER = 'db-backup'
const TMP_FOLDER = path.join(__dirname, '../tmp/backups')