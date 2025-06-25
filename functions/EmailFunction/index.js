const sgMail = require("@sendgrid/mail");

sgMail.setApiKey(process.env.SENDGRID_API_KEY);

module.exports = async function (context, req) {
  const emailData = req.body;

  const msg = {
    to: Array.isArray(emailData.to) ? emailData.to : [emailData.to],
    from: {
      name: process.env.EMAIL_FROM_NAME || "Notification Service",
      email: process.env.EMAIL_FROM_ADDRESS || "noreply@example.com"
    },
    subject: emailData.subject,
    html: emailData.body || ""
  };

  try {
    await sgMail.send(msg);
    context.res = {
      status: 200,
      body: { message: "Email enviado com sucesso." }
    };
  } catch (error) {
    context.log("Erro:", error);
    context.res = {
      status: 500,
      body: { error: "Falha ao enviar e-mail." }
    };
  }
};
