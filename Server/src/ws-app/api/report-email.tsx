import React from 'react'
import ReactDOMServer from 'react-dom/server'

import { mailer } from 'src/utils/mailer'
import { DbWsReport } from '../db/DbWsReport'
import { formatInTimeZone } from 'date-fns-tz'

export async function sendReportEmail(report: DbWsReport) {
  let recipients: mailer.Recipient[] = report.template.emailRecipients.map(x => ({
    name: '',
    email: x
  }))

  recipients = recipients.filter(x => x.email.toLowerCase() != report.user.email.toLowerCase())

  recipients.push({
    name: report.user.name,
    email: report.user.email
  })

  const formattedDate = formatInTimeZone(new Date(), 'Australia/Sydney', 'yyyy-MM-dd HH:mm:ss') // Date to avoid email grouping
  const subject = `[Weekly Spending] ${report.user.name} | ${formattedDate}`
  const contentHtml = generateReportEmail(report)

  await mailer.sendMail({ recipients, subject, contentHtml })
}

export function generateReportEmail(report: DbWsReport) {
  console.info(`report= ${JSON.stringify(report, null, 2)}`)
  const bodyHtml = ReactDOMServer.renderToStaticMarkup(<EmailTemplate report={report} />)

  return `
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        
        <!-- FORCE LIGHT MODE: Supported by Apple Mail & recent Clients -->
        <meta name="color-scheme" content="light">
        <meta name="supported-color-schemes" content="light">
        
        <title>${report.user.name} | Weekly Spending</title>
        <style type="text/css">
            body, table, td, a { -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
            table, td { mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
            img { -ms-interpolation-mode: bicubic; }
            @media screen and (max-width: 600px) {
                .container { width: 100% !important; }
            }
        </style>
    </head>
    <body style="margin: 0; padding: 0; background-color: #ffffff;">
        ${bodyHtml}
    </body>
    </html>
  `
}

// --- Styles ---

const themeColor = '#126b94'

// GMail does not support oklch!
// const darkBorderColor = 'oklch(90.5% 0.015 286.067)'
const darkBorderColor = '#dee2e6'

const styles: Record<string, React.CSSProperties> = {
  body: {
    backgroundColor: '#ffffff',
    fontFamily: 'Arial, sans-serif',
    fontSize: '14px',
    lineHeight: '1.5',
    color: '#333333',
    padding: '0 15px',
  },
  container: {
    maxWidth: '600px',
    margin: '0 auto',
    width: '100%',
    borderCollapse: 'collapse',
  },
  // Weekly Spending title, divider and subtitle
  mainTitle: {
    fontSize: '28px',
    fontWeight: 'bold',
    color: themeColor,
    paddingBottom: '10px',
    textAlign: 'left' as const
  },
  mainIcon: {
    paddingBottom: '10px',
    textAlign: 'right' as const
  },
  dividerRow: {
    borderBottom: '1px solid #cccccc', // The horizontal line
  },
  subtitle: {
    fontSize: '16px',
    color: '#555555',
    padding: '15px 0 30px 0', // Spacing below the line
    textAlign: 'left' as const,
  },
  // Store + Date header
  headerLabel: {
    fontWeight: 'bold',
    color: '#555555',
    padding: '8px 0',
    borderBottom: '1px solid #eeeeee',
  },
  headerValue: {
    fontWeight: 'regular',
    textAlign: 'left' as const,
    padding: '8px 0',
    borderBottom: '1px solid #eeeeee',
  },
  // Section header
  sectionTitle: {
    fontWeight: 'bold',
    color: '#333333',
    padding: '8px 0 4px 0',
    borderBottom: `2px solid ${darkBorderColor}`,
  },
  sectionTitleNotFirst: {
    fontWeight: 'bold',
    color: '#333333',
    padding: '8px 0 4px 0',
    borderBottom: `2px solid ${darkBorderColor}`,
  },
  columnHeader: {
    fontWeight: 'bold',
    color: '#555555',
    textAlign: 'right' as const,
    padding: '8px 0 4px 0',
    borderBottom: `2px solid ${darkBorderColor}`,
  },
  // Item
  itemCell: {
    padding: '6px 0',
    color: '#555555',
  },
  itemValue: {
    padding: '6px 0',
    textAlign: 'right' as const,
  },
  firstItemCell: {
    padding: '8px 0 6px 0',
    color: '#555555',
  },
  firstItemValue: {
    padding: '8px 0 6px 0',
    textAlign: 'right' as const,
  },
  // Bottom footer border
  footerBorder: {
    // borderBottom: '1px solid #333333',
    borderBottom: '1px solid #eeeeee',
  },
  // Total row
  totalHeader: {
    fontWeight: 'bold',
    fontSize: '15px',
    color: '#333333',
    padding: '18px 0 4px 0',
    borderBottom: `2px solid ${darkBorderColor}`,
  },
  totalHeaderRight: {
    fontWeight: 'bold',
    fontSize: '15px',
    color: '#333333',
    padding: '18px 0 4px 0',
    textAlign: 'right' as const,
    borderBottom: `2px solid ${darkBorderColor}`,
  },
  totalValue: {
    padding: '6px 0 6px 0',
    textAlign: 'right' as const,
    fontWeight: 'regular',
    fontSize: '15px',
    color: '#333333',
  }
}

const EmailTemplate: React.FC<{
  report: DbWsReport
}> = ({ report }) => {
  return (
    <table border={0} cellPadding={0} cellSpacing={0} width="100%" style={styles.body}>
      <tbody>
        <tr>
          <td align="center" style={{ padding: '20px 0' }}>

            {/* Title, divider, subtitle */}
            <table border={0} cellPadding={0} cellSpacing={0} width="600" style={styles.container}>
              <tbody>
                {/* Title */}
                <tr>
                  {/* Flex align-items is not supported in many email clients, using valign instead */}
                  <td style={styles.mainTitle} valign='bottom'>
                    Weekly Spending
                  </td>
                  <td style={styles.mainIcon}>
                    <img
                      src='https://ahvebevkycanekqtnthy.supabase.co/storage/v1/object/public/assets/DuckIcon-Font28px@3x.png'
                      height='26px'
                    />
                  </td>
                </tr>
                {/* Divider Line */}
                <tr>
                  <td style={styles.dividerRow}></td>
                  <td style={styles.dividerRow}></td>
                </tr>
                {/* Subtitle */}
                <tr>
                  <td style={styles.subtitle}>
                    Weekly spending report has been submitted.
                  </td>
                </tr>
              </tbody>
            </table>

            {/* Header Information */}
            <table border={0} cellPadding={0} cellSpacing={0} width="600" style={styles.container}>
              <tbody>
                <tr>
                  <td width="50px" style={styles.headerLabel}>
                    Store
                  </td>
                  <td style={styles.headerValue}>
                    {report.user.name}
                  </td>
                </tr>
                <tr>
                  <td style={styles.headerLabel}>
                    Date
                  </td>
                  <td style={styles.headerValue}>
                    {formatInTimeZone(report.date, 'Australia/Sydney', 'EEEE, d MMM yyyy, h:mm a')}
                  </td>
                </tr>
                <tr>
                  <td colSpan={2} style={{ height: '20px' }}>&nbsp;</td>
                </tr>
              </tbody>
            </table>

            {/* Data Sections */}
            <table border={0} cellPadding={0} cellSpacing={0} width="600" style={styles.container}>
              <tbody>
                {/* Suppliers */}
                {report.template.sections.map((section, sectionIndex) => {
                  const items: ItemComponentProps[] = section.rows.map(row => {
                    const supplier = report.template.suppliers.find(x => x.id == row.supplierId)
                    const supplierData = report.suppliersData.find(x => x.supplierId == row.supplierId)

                    if (!supplier || !supplierData) {
                      return { name: 'ERROR', amount: 0, gst: 0, credit: 0 }
                    }

                    return {
                      name: supplier.name,
                      amount: supplierData.amount,
                      gst: supplierData.gst,
                      credit: supplierData.credit
                    }
                  })

                  return (
                    <SectionComponent
                      name={section.name}
                      key={sectionIndex}
                      isFirst={sectionIndex == 0}
                      items={items}
                    />
                  )
                })}
                {/* Custom suppliers */}
                {
                  (() => {
                    const items: ItemComponentProps[] = report.customSuppliersData.map(supplierData => {
                      return {
                        name: supplierData.name,
                        amount: supplierData.amount,
                        gst: supplierData.gst,
                        credit: supplierData.credit
                      }
                    })

                    if (items.length == 0) {
                      return null
                    }

                    return (
                      <SectionComponent
                        name='Other Suppliers'
                        isFirst={report.template.sections.length == 0}
                        items={items}
                      />
                    )
                  })()
                }
                {/* Total Row */}
                {
                  (() => {
                    const totalAmount = report.suppliersData.reduce((sum, s) => sum + s.amount, 0) +
                      report.customSuppliersData.reduce((sum, s) => sum + s.amount, 0)
                    const totalCredit = report.suppliersData.reduce((sum, s) => sum + s.credit, 0) +
                      report.customSuppliersData.reduce((sum, s) => sum + s.credit, 0)

                    return (
                      <>
                        <tr>
                          <td width="40%" style={styles.totalHeader}>
                            Total
                          </td>
                          <td width="20%" style={styles.totalHeaderRight}>
                          </td>
                          <td width="20%" style={styles.totalHeaderRight}>
                            Amount
                          </td>
                          <td width="20%" style={styles.totalHeaderRight}>
                            Credit
                          </td>
                        </tr>
                        <tr>
                          <td style={styles.totalValue}>
                          </td>
                          <td style={styles.totalValue}>
                          </td>
                          <td style={styles.totalValue}>
                            {currencyFormat.format(totalAmount)}
                          </td>
                          <td style={styles.totalValue}>
                            {currencyFormat.format(totalCredit)}
                          </td>
                        </tr>
                      </>
                    )
                  })()
                }
              </tbody>
            </table>

          </td>
        </tr>
      </tbody>
    </table>
  )
}

const SectionComponent: React.FC<SectionComponentProps> = ({ name, isFirst, items }) => {
  return (
    <>
      {/* Section Header */}
      {isFirst ? (
        <tr>
          <td width="40%" style={styles.sectionTitle}>
            {name}
          </td>
          <td width="20%" style={styles.columnHeader}>
            Amount
          </td>
          <td width="20%" style={styles.columnHeader}>
            GST
          </td>
          <td width="20%" style={styles.columnHeader}>
            Credit
          </td>
        </tr>
      ) : (
        <tr>
          <td colSpan={4} style={styles.sectionTitleNotFirst}>
            {name}
          </td>
        </tr>
      )}

      {/* Section Items */}
      {items.map((item, itemIndex) => {
        const isFirstItem = itemIndex === 0
        const cellStyle = isFirstItem ? styles.firstItemCell : styles.itemCell
        const valueStyle = isFirstItem ? styles.firstItemValue : styles.itemValue

        return (
          <tr key={itemIndex}>
            <td style={cellStyle}>
              {item.name}
            </td>
            <td style={valueStyle}>
              {currencyFormat.format(item.amount)}
            </td>
            <td style={valueStyle}>
              {currencyFormat.format(item.gst)}
            </td>
            <td style={valueStyle}>
              {currencyFormat.format(item.credit)}
            </td>
          </tr>
        )
      })}
    </>
  )
}

type SectionComponentProps = {
  name: string
  isFirst: boolean
  items: ItemComponentProps[]
}

type ItemComponentProps = {
  name: string
  amount: number
  gst: number
  credit: number
}

const currencyFormat = new Intl.NumberFormat('en-AU', { style: 'currency', currency: 'AUD' });

