import React from 'react'
import ReactDOMServer from 'react-dom/server'
import { formatInTimeZone } from 'date-fns-tz'

import { DbQuizResponse } from '../db/DbQuizResponse'
import env from 'src/env'

export function generateQuizResponseEmail(response: DbQuizResponse) {
  const html = ReactDOMServer.renderToStaticMarkup(
    <EmailTemplate response={response} />
  )

  return `
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        
        <!-- FORCE LIGHT MODE: Supported by Apple Mail & recent Clients -->
        <meta name="color-scheme" content="light">
        <meta name="supported-color-schemes" content="light">
        
        <title>Store Report</title>
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
        ${html}
    </body>
    </html>
  `
}

// --- Styles ---

const EmailTemplate = ({ response }: {
  response: DbQuizResponse
}) => {
  // GMail does not support oklch!
  // const darkBorderColor = 'oklch(90.5% 0.015 286.067)'
  const darkBorderColor = '#dee2e6'

  const viewUrl = `${env.webappUrl}/fohtest/view/${response._id!.toString()}`

  const styles: Record<string, React.CSSProperties> = {
    body: {
      backgroundColor: '#ffffff',
      fontFamily: 'Arial, sans-serif',
      fontSize: '14px',
      lineHeight: '1.5',
      color: '#333333',
      padding: '20px 15px',
    },
    card: {
      backgroundColor: '#ffffff', width: '600px'
    },
    // "FOH Test" text + Duck icon
    headerCell: {
      color: '#286090',
      fontSize: '28px',
      fontWeight: 'bold',
      paddingBottom: '10px',
      border: 'none',
      borderBottom: '1px solid #cccccc',
    },
    headerIconCell: {
      paddingBottom: '10px',
      border: 'none',
      borderBottom: '1px solid #cccccc',
      textAlign: 'right' as const,
    },
    // "Test has been submitted" text
    introText: {
      color: '#555555',
      fontSize: '16px',
      lineHeight: 1.5,
      marginBottom: '20px'
    },
    // Name + Store + Date label
    dataListTable: {
      marginBottom: '27px'
    },
    labelCell: {
      padding: '12px 0',
      borderBottom: '1px solid #eeeeee',
      color: '#333333',
      fontSize: '14px',
      fontWeight: 'bold',
    },
    valueCell: {
      padding: '8px 0 8px 15px',
      borderBottom: '1px solid #eeeeee',
      color: '#333333',
      fontSize: '14px',
      textAlign: 'left'
    },
    button: {
      backgroundColor: '#286090',
      border: '1px solid #286090',
      borderRadius: '4px',
      color: '#ffffff',
      display: 'inline-block',
      fontFamily: 'Arial, sans-serif',
      fontSize: '16px',
      fontWeight: 400,
      padding: '6px 24px',
      textDecoration: 'none',
      verticalAlign: 'center',
    }
  }

  const formattedDate = formatInTimeZone(response.submittedDate, 'Australia/Sydney', 'MMM d, h:mm a')

  return (
    <table border={0} cellPadding={0} cellSpacing={0} width='100%' style={styles.body}>
      <tbody>
        <tr>
          <td align='center'>
            {/* The Card */}
            <table className='container' border={0} cellPadding={0} cellSpacing={0} width={600} style={styles.card}>
              <tbody>
                <tr>
                  <td className='content'>
                    {/* 1. Header */}
                    <table border={0} cellPadding={0} cellSpacing={0} width='100%'>
                      <tbody>
                        <tr>
                          {/* Flex align-items is not supported in many email clients, using valign instead if needed */}
                          <td style={styles.headerCell}>
                            FOH Test
                          </td>
                          <td style={styles.headerIconCell}>
                            <img
                              src='https://ahvebevkycanekqtnthy.supabase.co/storage/v1/object/public/assets/DuckIcon-Font28px@3x.png'
                              height='26px'
                            />
                          </td>
                        </tr>
                      </tbody>
                    </table>

                    {/* 2. Introduction Text */}
                    <p style={styles.introText}>
                      {response.quiz.name} has been submitted.
                    </p>

                    {/* 3. Data List */}
                    <table border={0} cellPadding={0} cellSpacing={0} width='100%' style={styles.dataListTable}>
                      <tbody>
                        {/* Name */}
                        <tr>
                          <td width='50px' style={styles.labelCell}>Name</td>
                          <td style={styles.valueCell}>{response.respondent.name}</td>
                        </tr>
                        {/* Store */}
                        <tr>
                          <td style={styles.labelCell}>Store</td>
                          <td style={styles.valueCell}>{response.respondent.store}</td>
                        </tr>
                        {/* Date */}
                        <tr>
                          <td style={styles.labelCell}>Date</td>
                          <td style={styles.valueCell}>{formattedDate}</td>
                        </tr>
                      </tbody>
                    </table>

                    {/* 4. The Button */}
                    <table border={0} cellPadding={0} cellSpacing={0} width='100%'>
                      <tbody>
                        <tr>
                          <td align='left'>
                            <a href={viewUrl} style={styles.button}>
                              View Test
                            </a>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </td>
                </tr>
              </tbody>
            </table>
            {/* End Card */}
          </td>
        </tr>
      </tbody>
    </table >
  )
}
