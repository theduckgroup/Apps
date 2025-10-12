import nodemailer from 'nodemailer'
import env from 'src/env'

export default {
  async sendMail({ recipients, subject, contentHtml }: {
    recipients: {
      name: string
      email: string
    }[],
    subject: string,
    contentHtml: string
  }) {
    const transporter = nodemailer.createTransport({
      host: "smtp.zoho.com",
      port: 465,
      secure: true,
      auth: {
        user: env.zohoMailer.username,
        pass: env.zohoMailer.password
      },
    })

    // console.log(`auth = ${JSON.stringify(auth)}`)

    const mail = {
      from: `"${env.zohoMailer.name}" <${env.zohoMailer.username}>`,
      to: recipients.map(x => `${x.name} <${x.email}>`).join(','),
      // bcc: adminUsers.map(user => `${user.name} <${user.email}>`).concat([order.user.email]).join(', '),
      subject: subject,
      html: contentHtml,
    }

    console.info(`Mail = ${JSON.stringify({ ...mail, html: undefined, attachments: undefined })}`)

    // console.log(`mail = ${JSON.stringify(mail)}`)

    await transporter.sendMail(mail)
  }
}