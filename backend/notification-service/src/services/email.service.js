// services/email.service.js
const dependencyContainer = require('../utils/dependency-injection');
const logger = require('../utils/logger');

class EmailService {
    constructor() {
        this.stats = {
            processed: 0,
            errors: 0,
            startTime: new Date()
        };
    }

    get emailProvider() {
        return dependencyContainer.getEmailProvider();
    }

    /**
     * Processar mensagem da fila de emails
     */
    async processEmailMessage(messageData) {
        try {
            logger.info(`📧 Processando mensagem de email:`, {
                messageId: messageData.messageId,
                type: messageData.type,
                recipient: messageData.to
            });

            // Validar dados da mensagem
            this.validateEmailMessage(messageData);

            // Preparar dados do email
            const emailData = this.prepareEmailData(messageData);

            // Enviar via provider configurado
            const result = await this.emailProvider.sendEmail(emailData);

            this.stats.processed++;
            
            logger.info(`✅ Email processado com sucesso:`, {
                messageId: messageData.messageId,
                provider: result.provider,
                recipient: result.recipient
            });

            return {
                success: true,
                messageId: messageData.messageId,
                result
            };

        } catch (error) {
            this.stats.errors++;
            logger.error(`❌ Erro ao processar email:`, {
                messageId: messageData.messageId,
                error: error.message
            });
            throw error;
        }
    }

    validateEmailMessage(messageData) {
        const required = ['to', 'type'];
        const missing = required.filter(field => !messageData[field]);
        
        if (missing.length > 0) {
            throw new Error(`Campos obrigatórios ausentes: ${missing.join(', ')}`);
        }

        // Validar email
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(messageData.to)) {
            throw new Error(`Email inválido: ${messageData.to}`);
        }
    }

    prepareEmailData(messageData) {
        const emailData = {
            to: messageData.to,
            subject: messageData.subject,
            body: messageData.body,
            template: messageData.template,
            variables: messageData.variables || {}
        };

        // Se não tiver subject/body, usar template baseado no tipo
        if (!emailData.subject || !emailData.body) {
            const templateData = this.getTemplateByType(messageData.type, messageData);
            emailData.subject = emailData.subject || templateData.subject;
            emailData.body = emailData.body || templateData.body;
            emailData.template = emailData.template || templateData.template;
        }

        return emailData;
    }

    getTemplateByType(type, messageData) {
        const templates = {
            'order_completed': {
                subject: 'Pedido #{{orderId}} finalizado!',
                body: 'Seu pedido #{{orderId}} foi entregue com sucesso.',
                template: 'order-completed'
            },
            'order_created': {
                subject: 'Pedido #{{orderId}} criado!',
                body: 'Seu pedido #{{orderId}} foi criado e está sendo processado.',
                template: 'order-created'
            },
            'promotional': {
                subject: '{{title}}',
                body: '{{content}}',
                template: 'promotional-campaign'
            },
            'welcome': {
                subject: 'Bem-vindo!',
                body: 'Seja bem-vindo ao nosso serviço!',
                template: 'welcome'
            }
        };

        const template = templates[type] || templates['welcome'];
        
        // Substituir variáveis básicas
        const subject = this.replaceVariables(template.subject, messageData);
        const body = this.replaceVariables(template.body, messageData);

        return {
            subject,
            body,
            template: template.template
        };
    }

    replaceVariables(text, variables) {
        if (!text || !variables) return text;
        
        return text.replace(/\{\{(\w+)\}\}/g, (match, key) => {
            return variables[key] || match;
        });
    }

    async testConnection() {
        return await this.emailProvider.testConnection();
    }

    getStats() {
        const providerStats = this.emailProvider.getStats ? this.emailProvider.getStats() : {};
        
        return {
            service: 'email',
            ...this.stats,
            uptime: Date.now() - this.stats.startTime.getTime(),
            provider: providerStats
        };
    }
}

module.exports = new EmailService();