import express from 'express'
import path from 'path'

const router = express.Router()

router.get('/naked-blend-app/privacy', async (req, res) => {
  const file = path.resolve(path.join(__dirname, 'pages/naked-blend-app-privacy.html'))
  res.sendFile(file)
})

router.get('/foh-test-app/privacy', async (req, res) => {
  const file = path.resolve(path.join(__dirname, 'pages/foh-test-app-privacy.html'))
  res.sendFile(file)
})

router.get('/contact-us', async (req, res) => {
  const file = path.resolve(path.join(__dirname, 'pages/contact-us.html'))
  res.sendFile(file)
})

router.get('/*splat', async (req, res) => {
  res.status(404).send()
})

export default router