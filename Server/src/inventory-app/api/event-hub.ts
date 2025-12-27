import eventHub from 'src/event-hub'

export default {
  emitStoresChanged() {
    eventHub.emit('inventory-app:stores:changed')
  },
  emitStoreChanged(storeId: string) {
    eventHub.emit(`inventory-app:store:${storeId}:changed`)
    this.emitStoresChanged()
  }
}
