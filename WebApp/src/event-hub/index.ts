
import { io } from "socket.io-client"

console.info(`! Init socket`)

// Trailing slash is important
const socket = io({ path: '/socketio' })

socket.on('connect', () => {
  // console.info(`! socket connected, client id = ${socket.id}`)
})

socket.on('connect_error', (data) => {
  console.error(`! Socket connect error ${JSON.stringify(data)}`)
})

console.info(`! Connecting socket`)
socket.connect()

const eventHub = {
  /**
   * Listens to vendor change event.
   * 
   * @returns Function that can be used to stop listening.
   */
  onVendorChanged: (vendorId: string, callback: () => void): () => void => {
    console.info(`! Listening...`)
    const listener = () => {
      console.info(`! Received vendor event`)
      callback()
    }

    const event = `event.vendor:${vendorId}.change`
    socket.on(event, listener)

    // Very important to remove listener

    return () => {
      console.info(`! Unregister listener`)
      socket.off(event, listener) 
    }
  }
}

export default eventHub