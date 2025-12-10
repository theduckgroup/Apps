import { ObjectID } from 'bson'

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
    gstMethod: 'input' | 'tenPercent' | 'notApplicable'
  }

  export interface Section {
    id: string
    name: string
    rows: Row[]
  }

  export interface Row {
    supplierId: string
  }

  export function createDefaultSupplier(): Supplier {
    return {
      id: new ObjectID().toString(),
      name: 'Supplier',
      gstMethod: 'notApplicable'
    }
  }

  export function createDefaultSection(): Section {
    return {
      id: new ObjectID().toString(),
      name: 'Section',
      rows: []
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