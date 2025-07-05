const { app } = require('@azure/functions');
const admin = require('firebase-admin');

function initializeFirebaseAdmin() {
  try {
    if (admin.apps.length === 0) {
      const requiredVars = [
        'FIREBASE_TYPE',
        'FIREBASE_PROJECT_ID',
        'FIREBASE_PRIVATE_KEY_ID',
        'FIREBASE_PRIVATE_KEY',
        'FIREBASE_CLIENT_EMAIL',
        'FIREBASE_CLIENT_ID',
        'FIREBASE_AUTH_URI',
        'FIREBASE_TOKEN_URI',
        'FIREBASE_AUTH_PROVIDER_CERT_URL',
        'FIREBASE_CLIENT_CERT_URL',
        'FIREBASE_UNIVERSE_DOMAIN',
      ];

      for (const key of requiredVars) {
        if (!process.env[key]) {
          throw new Error(`❌ Missing environment variable: ${key}`);
        }
      }

      const serviceAccount = {
        type: process.env.FIREBASE_TYPE,
        project_id: process.env.FIREBASE_PROJECT_ID,
        private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
        private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        client_email: process.env.FIREBASE_CLIENT_EMAIL,
        client_id: process.env.FIREBASE_CLIENT_ID,
        auth_uri: process.env.FIREBASE_AUTH_URI,
        token_uri: process.env.FIREBASE_TOKEN_URI,
        auth_provider_x509_cert_url: process.env.FIREBASE_AUTH_PROVIDER_CERT_URL,
        client_x509_cert_url: process.env.FIREBASE_CLIENT_CERT_URL,
      };

      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });

      console.log("✅ Firebase Admin SDK initialized successfully.");
    }
  } catch (error) {
    console.error("❌ Failed to initialize Firebase Admin SDK:", error.message || error);
    throw error; // impede deploy silencioso com erro
  }
}

initializeFirebaseAdmin();

app.serviceBusTopic('function-push-notification', {
  connection: 'sb-delivery-app-brazil-south_RootManageSharedAccessKey_SERVICEBUS',
  topicName: 'order.finished',
  subscriptionName: 'push-notification',
  handler: async (message, context) => {
    context.log('📦 Mensagem recebida do tópico:', message);

    const { fcmToken, title, body } = message;

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
