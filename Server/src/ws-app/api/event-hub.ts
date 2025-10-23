import eventHub from 'src/event-hub'

export default {
  emitQuizzesChanged() {
    // io.of(`/temp`).emit('change')
    eventHub.emit('ws-app:templates:changed')
  }
}
