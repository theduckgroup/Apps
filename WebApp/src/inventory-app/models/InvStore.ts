
export interface InvStore {
  id: string
  name: string
  catalog: {
    items: InvStore.Item[]
    sections: InvStore.Section[]
  }
}

export namespace InvStore {
  export interface Item {
    id: string
    name: string
    code: string
  }

  export interface Section {
    id: string
    name: string
    rows: Row[]
  }

  export interface Row {
    itemId: string
  }
}