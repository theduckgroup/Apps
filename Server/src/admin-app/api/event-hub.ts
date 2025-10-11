import eventHub from 'src/event-hub'

export default {
  emitUsersChanged() {
    // io.of(`/temp`).emit('change')
    eventHub.emit('admin:users:changed')
  }
}
