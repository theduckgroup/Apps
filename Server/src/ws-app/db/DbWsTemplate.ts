export interface DbWsTemplate {
  // _id: ObjectId
  name: string
  code: string
  emailRecipients: string[]
  suppliers: DbWsTemplate.Supplier[]
  sections: DbWsTemplate.Section[]
}

export namespace DbWsTemplate {
  export interface Supplier {
    id: string
    name: string
    gstMethod: 'notApplicable' | 'tenPercent' | 'input'
  }

  export interface Section {
    id: string
    name: string
    rows: Row[]
  }

  export interface Row {
supplierId: string
  }
}