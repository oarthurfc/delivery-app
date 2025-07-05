const { app } = require('@azure/functions');
const sgMail = require('@sendgrid/mail');

sgMail.setApiKey(process.env.SENDGRID_API_KEY);

app.serviceBusTopic('function-send-mail', {
  connection: 'sb-delivery-app-brazil-south_RootManageSharedAccessKey_SERVICEBUS',
  topicName: 'order.finished',
  subscriptionName: 'send-mail-subscriber',
  handler: async (message, context) => {
    context.log('📨 Mensagem recebida do Service Bus:', message);

    try {
      const {
        id,
        status,
        description,
        originAddress,
        destinationAddress,
        imageUrl
      } = message;

      const htmlBody = `
        <h2>🚚 Pedido #${id} Finalizado</h2>

        <p><strong>Descrição:</strong> ${description}</p>

        <p><strong>Origem:</strong><br />
        ${originAddress?.street || "Endereço não informado"}</p>

        <p><strong>Destino:</strong><br />
        ${destinationAddress?.street || "Endereço não informado"}</p>

        <p><strong>Status:</strong> ${status}</p>

        ${
          imageUrl
            ? `<p><img src="${imageUrl}" alt="Imagem do pedido" style="max-width: 400px; border-radius: 8px;" /></p>`
            : ""
        }
      `;

      const msg = {
        to: 'ponge2004@gmail.com', //Tornar isso dinâmico depois mandando p/ cliente e entregador
        from: {
          name: process.env.EMAIL_FROM_NAME || 'Delivery App',
          email: process.env.EMAIL_FROM_ADDRESS || 'noreply@delivery.com'
        },
        subject: `Pedido #${id} finalizado com sucesso`,
        html: htmlBody
      };

      await sgMail.send(msg);
      context.log('✅ Email enviado com sucesso.');
    } catch (err) {
      context.log('❌ Erro ao processar ou enviar e-mail:', err.response?.body || err);
    }
  }
});
