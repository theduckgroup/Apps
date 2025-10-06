export interface Quiz {
  id: string
  name: string
  items: Quiz.Item[]
  sections: Quiz.Section[]
}

export namespace Quiz {
  export type Item = ListItem | SelectedResponseItem | TextInputItem

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
      optionsPerRow: 1 | 2 | 4
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

export interface QuizMetadata {
  id: string
  name: string
}