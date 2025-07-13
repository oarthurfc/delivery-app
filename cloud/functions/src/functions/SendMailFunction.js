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
        pedidoId,
        origem,
        destino,
        descricao,
        destinatario,
        preco,
        clienteEmail,
        motoristaEmail
      } = message;

      const htmlBody = `
        <h2>🚚 Pedido #${pedidoId} Finalizado</h2>

        <p><strong>Descrição:</strong> ${descricao}</p>

        <p><strong>Origem:</strong><br />
        ${origem || "Endereço não informado"}</p>

        <p><strong>Destino:</strong><br />
        ${destino || "Endereço não informado"}</p>

        <p><strong>Preço:</strong> R$ ${preco?.toFixed(2) || "Não informado"}</p>

        <p><strong>Destinatário:</strong> ${destinatario || "Não informado"}</p>
      `;

      const recipients = [];

      if (clienteEmail) {
        recipients.push(clienteEmail);
      } else {
        context.log('⚠️ Email do cliente não encontrado.');
      }

      if (motoristaEmail) {
        recipients.push(motoristaEmail);
      } else {
        context.log('⚠️ Email do motorista não encontrado.');
      }

      if (recipients.length > 0) {
        const msg = {
          to: recipients,
          from: {
            name: process.env.EMAIL_FROM_NAME || 'Delivery App',
            email: process.env.EMAIL_FROM_ADDRESS || 'noreply@delivery.com'
          },
          subject: `Pedido #${pedidoId} finalizado com sucesso`,
          html: htmlBody
        };

        await sgMail.send(msg);
        context.log(`✅ Email enviado com sucesso para: ${recipients.join(', ')}`);
      } else {
        context.log('⚠️ Nenhum destinatário encontrado para envio de e-mail.');
      }
    } catch (err) {
      context.log('❌ Erro ao processar ou enviar e-mail:', err.response?.body || err);
    }
  }
});
