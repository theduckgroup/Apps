import eventHub from 'src/app/event-hub'

export default {
  onStoresChanged(callback: () => void) {
    return eventHub.onEvent(`inventory-app:stores:changed`, callback)
  },
  onStoreChanged(storeId: string, callback: () => void){
    return eventHub.onEvent(`inventory-app:store:${storeId}:changed`, callback)
  },
  onStoreChangedByCode(code: string, callback: () => void){
    return eventHub.onEvent(`inventory-app:store:code=${code}:changed`, callback)
  },
}