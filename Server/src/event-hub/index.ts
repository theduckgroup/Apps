
import { Server as Server } from 'socket.io'
import { } from 'express'
import http from 'http'

let io: Server

const eventHub = {
  init(httpServer: http.Server) {
    if (io) {
      throw new Error('Attempting to init event hub twice')
    }

    // /socketio is not authorized
    // It is also configured in vite proxy

    io = new Server(httpServer, { path: '/socketio' })

    console.info(`! Event hub initialized`)

    io.on('connection', socket => {
      console.info(`! Client connected ${socket.client.request.url!}`)
    })

    // io.of('/vendor:[a-z]')
    // io.of('/temp')
  },
  emitVendorChange(vendorId: string) {
    // io.of(`/vendor:${vendorId}`).emit('change')
    console.info(`! emit vendor change ${vendorId}`)
    // io.of(`/temp`).emit('change')
    io.emit(`event.vendor:${vendorId}.change`)
  },
}

export default eventHub