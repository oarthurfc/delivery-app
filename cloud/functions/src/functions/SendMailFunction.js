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
        clienteEmail,
        motoristaEmail
      } = message;

      const htmlBody = `
        <!DOCTYPE html>
        <html lang="pt-BR">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Pedido Finalizado</title>
        </head>
        <body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8fafc; line-height: 1.6;">
          
          <!-- Container Principal -->
          <table role="presentation" style="width: 100%; border-collapse: collapse; background-color: #f8fafc;">
            <tr>
              <td style="padding: 40px 20px;">
                
                <!-- Card Principal -->
                <table role="presentation" style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); overflow: hidden;">
                  
                  <!-- Header -->
                  <tr>
                    <td style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center;">
                      <h1 style="margin: 0; color: #ffffff; font-size: 28px; font-weight: 700; text-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                        🚚 Delivery App
                      </h1>
                      <p style="margin: 10px 0 0 0; color: #e2e8f0; font-size: 16px; opacity: 0.9;">
                        Pedido finalizado com sucesso
                      </p>
                    </td>
                  </tr>
                  
                  <!-- Status Badge -->
                  <tr>
                    <td style="padding: 0 30px; text-align: center; transform: translateY(-15px);">
                      <div style="display: inline-block; background-color: #10b981; color: white; padding: 8px 20px; border-radius: 20px; font-weight: 600; font-size: 14px; box-shadow: 0 2px 8px rgba(16, 185, 129, 0.3);">
                        ✅ ENTREGUE
                      </div>
                    </td>
                  </tr>
                  
                  <!-- Conteúdo -->
                  <tr>
                    <td style="padding: 20px 30px 30px 30px;">
                      
                      <!-- Número do Pedido -->
                      <div style="text-align: center; margin-bottom: 30px;">
                        <h2 style="margin: 0; color: #1e293b; font-size: 24px; font-weight: 600;">
                          Pedido #${pedidoId}
                        </h2>
                      </div>
                      
                      <!-- Descrição -->
                      <div style="background-color: #f1f5f9; border-radius: 8px; padding: 20px; margin-bottom: 25px; border-left: 4px solid #667eea;">
                        <h3 style="margin: 0 0 10px 0; color: #475569; font-size: 16px; font-weight: 600; display: flex; align-items: center;">
                          📦 Descrição do Pedido
                        </h3>
                        <p style="margin: 0; color: #64748b; font-size: 15px; line-height: 1.5;">
                          ${descricao || "Descrição não informada"}
                        </p>
                      </div>
                      
                      <!-- Trajeto -->
                      <div style="margin-bottom: 25px;">
                        <h3 style="margin: 0 0 15px 0; color: #475569; font-size: 16px; font-weight: 600;">
                          🗺️ Trajeto da Entrega
                        </h3>
                        
                        <!-- Origem -->
                        <div style="display: flex; align-items: flex-start; margin-bottom: 15px; padding: 15px; background-color: #ecfdf5; border-radius: 8px; border: 1px solid #d1fae5;">
                          <div style="background-color: #10b981; color: white; border-radius: 50%; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: bold; margin-right: 12px; flex-shrink: 0;">
                            A
                          </div>
                          <div>
                            <strong style="color: #065f46; display: block; margin-bottom: 4px; font-size: 14px;">Origem:</strong>
                            <span style="color: #047857; font-size: 14px; line-height: 1.4;">
                              ${origem || "Endereço não informado"}
                            </span>
                          </div>
                        </div>
                        
                        <!-- Linha conectora -->
                        <div style="text-align: center; margin: 10px 0;">
                          <div style="display: inline-block; width: 2px; height: 20px; background-color: #cbd5e1;"></div>
                        </div>
                        
                        <!-- Destino -->
                        <div style="display: flex; align-items: flex-start; padding: 15px; background-color: #fef3c7; border-radius: 8px; border: 1px solid #fcd34d;">
                          <div style="background-color: #f59e0b; color: white; border-radius: 50%; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: bold; margin-right: 12px; flex-shrink: 0;">
                            B
                          </div>
                          <div>
                            <strong style="color: #92400e; display: block; margin-bottom: 4px; font-size: 14px;">Destino:</strong>
                            <span style="color: #d97706; font-size: 14px; line-height: 1.4;">
                              ${destino || "Endereço não informado"}
                            </span>
                          </div>
                        </div>
                      </div>
                      
                      <!-- Mensagem de agradecimento -->
                      <div style="text-align: center; padding: 20px; background-color: #f8fafc; border-radius: 8px; border: 1px solid #e2e8f0;">
                        <h3 style="margin: 0 0 10px 0; color: #1e293b; font-size: 18px; font-weight: 600;">
                          🎉 Obrigado por confiar em nossos serviços!
                        </h3>
                        <p style="margin: 0; color: #64748b; font-size: 14px;">
                          Sua entrega foi realizada com sucesso. Esperamos vê-lo novamente em breve!
                        </p>
                      </div>
                      
                    </td>
                  </tr>
                  
                  <!-- Footer -->
                  <tr>
                    <td style="background-color: #f8fafc; padding: 25px 30px; text-align: center; border-top: 1px solid #e2e8f0;">
                      <p style="margin: 0; color: #94a3b8; font-size: 13px;">
                        Este é um e-mail automático, não responda esta mensagem.
                      </p>
                      <p style="margin: 8px 0 0 0; color: #cbd5e1; font-size: 12px;">
                        © 2025 Delivery App - Todos os direitos reservados
                      </p>
                    </td>
                  </tr>
                  
                </table>
                
              </td>
            </tr>
          </table>
          
        </body>
        </html>
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
          subject: `🎉 Pedido #${pedidoId} finalizado com sucesso`,
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