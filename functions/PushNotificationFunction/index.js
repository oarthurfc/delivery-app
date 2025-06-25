const admin = require("firebase-admin");

const serviceAccount = require("./firebase-service-account.json"); // caminho para o .json baixado

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

module.exports = async function (context, req) {
  const { fcmToken, title, body } = req.body;

  if (!fcmToken || !title || !body) {
    context.res = {
      status: 400,
      body: { error: "fcmToken, title e body são obrigatórios." },
    };
    return;
  }

  const message = {
    token: fcmToken,
    notification: {
      title,
      body,
    },
  };

  try {
    const response = await admin.messaging().send(message);
    context.res = {
      status: 200,
      body: { message: "Notificação enviada com sucesso.", response },
    };
  } catch (error) {
    context.log("Erro ao enviar notificação:", error);
    context.res = {
      status: 500,
      body: { error: "Erro ao enviar notificação.", details: error.message },
    };
  }
};
