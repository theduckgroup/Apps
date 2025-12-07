export interface WsTemplate {
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
    bsb: string
    accountNumber: string
  }

  export interface Section {
    id: string
    name: string
    rows: {
      supplierId: string
    }[]
  }
}

export interface WsTemplateMetadata {
  id: string
  name: string
  code: string
  sectionCount: number
  supplierCount: number
}