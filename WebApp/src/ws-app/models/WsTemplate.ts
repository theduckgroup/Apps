import { ObjectId } from 'bson'

export interface WsTemplate {
  id: string
  name: string
  code: string
  emailRecipients: string[]
  suppliers: WsTemplate.Supplier[]
  sections: WsTemplate.Section[]
}

export namespace WsTemplate {
  export interface Supplier {
    id: string
    name: string
    gstMethod: GstMethod
  }

  export type GstMethod = 'notApplicable' | '10%' | 'input'

  export interface Section {
    id: string
    name: string
    rows: Row[]
  }

  export interface Row {
    supplierId: string
  }

  export function newSupplier(): Supplier {
    return {
      id: new ObjectId().toString(),
      name: '',
      gstMethod: 'notApplicable'
    }
  }

  export function newSection(): Section {
    return {
      id: new ObjectId().toString(),
      name: '',
      rows: []
    }
  }

  export function gstMethodName(value: GstMethod) {
    switch (value) {
      case 'notApplicable': return 'N/A'
      case '10%': return '10%'
      case 'input': return 'Manual'
    }
  }
}

export interface WsTemplateMetadata {
  id: string
  name: string
  code: string
  sectionCount: number
  supplierCount: number
}