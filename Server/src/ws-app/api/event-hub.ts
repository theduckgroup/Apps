import eventHub from 'src/event-hub'

export default {
  emitTemplatesChanged() {
    // io.of(`/temp`).emit('change')
    eventHub.emit('ws-app:templates:changed')
  },

  emitUserReportsChanged(userId: string) {
    eventHub.emit(`ws-app:user:${userId}:reports:changed`)
  }
}
