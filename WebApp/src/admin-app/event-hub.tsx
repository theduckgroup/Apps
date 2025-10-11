import eventHub from 'src/app/event-hub'

export default {
  onUsersChanged(callback: () => void): () => void {
    return eventHub.onEvent('admin:users:changed', callback)
  }
}