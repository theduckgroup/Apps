import { DbWsTemplate } from './DbWsTemplate'

export interface DbWsReport {
  // _id: ObjectId
  template: DbWsTemplate
  user: {
    id: string
    email: string
    name: string
  },
  date: Date
  suppliers: DbWsReport.Supplier[]
}

export namespace DbWsReport {
  export interface Supplier {
    supplierId: string
    amount: number
  }
}