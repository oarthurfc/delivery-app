const { app } = require('@azure/functions');
const admin = require('firebase-admin');
const fs = require('fs');

/* Inicializa Firebase Admin uma única vez
if (!admin.apps.length) {
  const serviceAccount = JSON.parse(
    fs.readFileSync('./firebase-service-account.json', 'utf8')
  );

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}
*/

app.serviceBusTopic('function-push-notification', {
  connection: 'sb-delivery-app-brazil-south_RootManageSharedAccessKey_SERVICEBUS',
  topicName: 'order.finished',
  subscriptionName: 'push-notification',
  handler: async (message, context) => {
    context.log('📦 Mensagem recebida do tópico:', message);

    const { fcmToken, title, body } = message;

    // Validação mínima
    if (!fcmToken || !title || !body) {
      context.log('❌ Dados insuficientes para envio de push:', { fcmToken, title, body });
      return;
    }

    const pushMessage = {
      token: fcmToken,
      notification: {
        title,
        body,
      },
    };

    try {
      const response = await admin.messaging().send(pushMessage);
      context.log('✅ Push enviado com sucesso:', response);
    } catch (error) {
      context.log('❌ Erro ao enviar push notification:', error.message || error);
    }
  }
});