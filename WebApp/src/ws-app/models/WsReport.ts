import { WsTemplate } from './WsTemplate'

export interface WsReport {
  template: WsTemplate
  submittedDate: Date
  submittedBy: {
    id: string,
    email: string,
    name: string  
  },
  suppliers: WsReport.Supplier[]
}

export namespace WsReport {
  export interface Supplier {
    supplierId: string
    amount: number
    reference: string
  }
}