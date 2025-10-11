
import { io } from "socket.io-client"

console.info(`! Init socket`)

// Trailing slash is important
const socket = io({ path: '/socketio' })

socket.on('connect', () => {
  // console.info(`! socket connected, client id = ${socket.id}`)
})

socket.on('connect_error', (data) => {
  console.error(`Socket connect error ${JSON.stringify(data)}`)
})

console.info(`! Connecting socket`)
socket.connect()

const eventHub = {
  onEvent: (eventName: string, callback: () => void): () => void => {
    console.info(`! Listening to ${eventName}`)
    
    const listener = () => {
      console.info(`! Received ${eventName}`)
      callback()
    }

    socket.on(eventName, listener)

    // Very important to remove listener

    return () => {
      console.info(`! Unregister ${eventName}`)
      socket.off(eventName, listener)
    }
  }
}

export default eventHub