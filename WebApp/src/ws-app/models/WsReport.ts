import { WsTemplate } from './WsTemplate'

export interface WsReport {
  template: WsTemplate
  user: {
    id: string
    email: string
    name: string  
  },
  date: Date
  suppliers: WsReport.Supplier[]
}

export namespace WsReport {
  export interface Supplier {
    supplierId: string
    amount: number
  }
}