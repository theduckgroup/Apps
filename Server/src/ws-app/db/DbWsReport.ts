import { ObjectId } from 'mongodb'
import { DbWsTemplate } from './DbWsTemplate'

export interface DbWsReport {
  _id?: ObjectId
  template: DbWsTemplate
  user: {
    id: string
    email: string
    name: string
  },
  date: Date
  suppliersData: DbWsReport.SupplierData[]
  customSuppliersData: DbWsReport.CustomSupplierData[]
}

export namespace DbWsReport {
  export interface SupplierData {
    supplierId: string
    amount: number
    gst: number
    credit: number
  }

  export interface CustomSupplierData {
    name: string
    amount: number
    gst: number
    credit: number
  }
}