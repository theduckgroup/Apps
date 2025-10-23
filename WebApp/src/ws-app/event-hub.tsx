import eventHub from 'src/app/event-hub'

export default {
  onWSTemplatesChanged(callback: () => void): () => void {
    return eventHub.onEvent('ws-app:templates:changed', callback)
  }
}