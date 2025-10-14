import { ObjectId } from 'bson'

export interface Quiz {
  id: string
  name: string
  code: string
  itemsPerPage: number
  items: Quiz.Item[]
  sections: Quiz.Section[]
}

export namespace Quiz {
  export type Item = ListItem | SelectedResponseItem | TextInputItem
  export type ItemKind = Item['kind']

  export interface ListItem {
    id: string
    kind: 'listItem'
    data: {
      prompt: string
      items: Item[]
    }
  }

  export interface SelectedResponseItem {
    id: string
    kind: 'selectedResponseItem'
    data: {
      prompt: string
      options: {
        id: string
        value: string
      }[]
    }
  }

  export interface TextInputItem {
    id: string
    kind: 'textInputItem'
    data: {
      prompt: string
    }
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

export namespace Quiz {
  export function createDefaultItem(kind: Quiz.ItemKind): Quiz.Item {
    const id = new ObjectId().toString()

    switch (kind) {
      case 'selectedResponseItem':
        return {
          id,
          kind,
          data: {
            prompt: '',
            options: [
              {
                id: new ObjectId().toString(),
                value: ''
              },
              {
                id: new ObjectId().toString(),
                value: ''
              }
            ]
          }
        }

      case 'textInputItem':
        return {
          id,
          kind,
          data: {
            prompt: ''
          }
        }

      case 'listItem':
        return {
          id,
          kind,
          data: {
            prompt: '',
            items: []
          }
        }
    }
  }

  export function createDefaultSection(): Quiz.Section {
    return {
      id: new ObjectId().toString(),
      name: '',
      rows: []
    }
  }
}

export interface QuizMetadata {
  id: string
  name: string
  code: string
  sectionCount: number
  itemCount: number
}