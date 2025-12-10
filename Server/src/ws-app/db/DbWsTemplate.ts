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
    gstMethod: 'input' | 'tenPercent' | 'notApplicable'
  }

  export interface Section {
    id: string
    name: string
    rows: {
      supplierId: string
    }[]
  }
}