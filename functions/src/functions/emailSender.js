const { app } = require('@azure/functions');
const { google } = require('googleapis');
const { OAuth2Client } = require('google-auth-library');

// Configurações - coloque essas variáveis no Azure App Settings
const CLIENT_ID = process.env.GMAIL_CLIENT_ID;
const CLIENT_SECRET = process.env.GMAIL_CLIENT_SECRET;
const REFRESH_TOKEN = process.env.GMAIL_REFRESH_TOKEN;
const YOUR_EMAIL = process.env.YOUR_EMAIL; // seu email do Gmail

// Configurar cliente OAuth2
const oauth2Client = new OAuth2Client(CLIENT_ID, CLIENT_SECRET);
oauth2Client.setCredentials({
    refresh_token: REFRESH_TOKEN
});

// Função para enviar email
async function sendEmail(to, subject, message) {
    try {
        // Obter access token
        const { token } = await oauth2Client.getAccessToken();
        
        // Configurar Gmail API
        const gmail = google.gmail({ 
            version: 'v1',
            auth: oauth2Client 
        });

        // Criar mensagem de email no formato RFC 2822
        const emailMessage = [
            `To: ${to}`,
            `Subject: ${subject}`,
            `Content-Type: text/html; charset=utf-8`,
            '',
            message
        ].join('\n');

        // Codificar em base64
        const encodedMessage = Buffer.from(emailMessage)
            .toString('base64')
            .replace(/\+/g, '-')
            .replace(/\//g, '_')
            .replace(/=+$/, '');

        // Enviar email
        const result = await gmail.users.messages.send({
            userId: 'me',
            requestBody: {
                raw: encodedMessage
            }
        });

        return {
            success: true,
            messageId: result.data.id,
            message: 'Email enviado com sucesso!'
        };

    } catch (error) {
        console.error('Erro ao enviar email:', error);
        return {
            success: false,
            error: error.message
        };
    }
}

// Azure Function HTTP Trigger
app.http('sendEmail', {
    methods: ['POST'],
    authLevel: 'function',
    handler: async (request, context) => {
        try {
            // Validar se as variáveis de ambiente estão configuradas
            if (!CLIENT_ID || !CLIENT_SECRET || !REFRESH_TOKEN || !YOUR_EMAIL) {
                return {
                    status: 500,
                    body: JSON.stringify({
                        success: false,
                        error: 'Variáveis de ambiente não configuradas'
                    })
                };
            }

            // Obter dados do corpo da requisição
            const requestBody = await request.json();
            const { to, subject, message } = requestBody;

            // Validar campos obrigatórios
            if (!to || !subject || !message) {
                return {
                    status: 400,
                    body: JSON.stringify({
                        success: false,
                        error: 'Campos obrigatórios: to, subject, message'
                    })
                };
            }

            // Enviar email
            const result = await sendEmail(to, subject, message);

            if (result.success) {
                return {
                    status: 200,
                    body: JSON.stringify(result)
                };
            } else {
                return {
                    status: 500,
                    body: JSON.stringify(result)
                };
            }

        } catch (error) {
            context.log('Erro na função:', error);
            return {
                status: 500,
                body: JSON.stringify({
                    success: false,
                    error: 'Erro interno do servidor'
                })
            };
        }
    }
});