import { DbWsTemplate } from './DbWsTemplate'

export interface DbWsReport {
  // _id: ObjectId
  template: DbWsTemplate
  submittedDate: Date
  store: {},
  suppliers: DbWsReport.Supplier[]
}

export namespace DbWsReport {
  export interface Supplier {
    supplierId: string
    amount: number
    reference: string
  }
}