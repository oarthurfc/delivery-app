// services/push.service.js
const dependencyContainer = require('../utils/dependency-injection');
const logger = require('../utils/logger');

class PushService {
    constructor() {
        this.stats = {
            processed: 0,
            broadcasts: 0,
            errors: 0,
            startTime: new Date()
        };
    }

    get pushProvider() {
        return dependencyContainer.getPushProvider();
    }

    /**
     * Processar mensagem da fila de push notifications
     */
    async processPushMessage(messageData) {
        try {
            logger.info(`🔔 Processando mensagem de push:`, {
                messageId: messageData.messageId,
                type: messageData.type,
                userId: messageData.userId
            });

            // Validar dados da mensagem
            this.validatePushMessage(messageData);

            // Preparar dados da notificação
            const pushData = this.preparePushData(messageData);

            // Decidir se é broadcast ou notificação única
            let result;
            if (messageData.type === 'broadcast' || Array.isArray(messageData.userId)) {
                result = await this.processBroadcast(pushData);
                this.stats.broadcasts++;
            } else {
                result = await this.pushProvider.sendPushNotification(pushData);
            }

            this.stats.processed++;
            
            logger.info(`✅ Push notification processada com sucesso:`, {
                messageId: messageData.messageId,
                provider: result.provider,
                sent: result.sent || 1
            });

            return {
                success: true,
                messageId: messageData.messageId,
                result
            };

        } catch (error) {
            this.stats.errors++;
            logger.error(`❌ Erro ao processar push notification:`, {
                messageId: messageData.messageId,
                error: error.message
            });
            throw error;
        }
    }

    validatePushMessage(messageData) {
        const required = ['userId', 'type'];
        const missing = required.filter(field => !messageData[field]);
        
        if (missing.length > 0) {
            throw new Error(`Campos obrigatórios ausentes: ${missing.join(', ')}`);
        }

        // Validar userId
        if (messageData.type !== 'broadcast' && !messageData.userId) {
            throw new Error('userId é obrigatório para notificações individuais');
        }
    }

    preparePushData(messageData) {
        const pushData = {
            userId: messageData.userId,
            title: messageData.title,
            body: messageData.body,
            data: messageData.data || {},
            deepLink: messageData.deepLink
        };

        // Se não tiver título/corpo, usar template baseado no tipo
        if (!pushData.title || !pushData.body) {
            const templateData = this.getTemplateByType(messageData.type, messageData);
            pushData.title = pushData.title || templateData.title;
            pushData.body = pushData.body || templateData.body;
            pushData.deepLink = pushData.deepLink || templateData.deepLink;
        }

        return pushData;
    }

    async processBroadcast(pushData) {
        const userIds = Array.isArray(pushData.userId) ? pushData.userId : [pushData.userId];
        
        const broadcastData = {
            userIds,
            title: pushData.title,
            body: pushData.body,
            data: pushData.data
        };

        return await this.pushProvider.sendBroadcast(broadcastData);
    }

    getTemplateByType(type, messageData) {
        const templates = {
            'order_completed': {
                title: 'Pedido entregue! ⭐',
                body: 'Seu pedido #{{orderId}} foi finalizado. Que tal avaliar?',
                deepLink: 'app://evaluate/{{orderId}}'
            },
            'order_created': {
                title: 'Pedido criado! 📦',
                body: 'Seu pedido #{{orderId}} foi criado com sucesso.',
                deepLink: 'app://track/{{orderId}}'
            },
            'promotional': {
                title: '{{title}}',
                body: '{{content}}',
                deepLink: 'app://promotions'
            },
            'evaluation_reminder': {
                title: 'Avalie sua entrega! ⭐',
                body: 'Conte-nos como foi sua experiência com o pedido #{{orderId}}',
                deepLink: 'app://evaluate/{{orderId}}'
            }
        };

        const template = templates[type] || {
            title: 'Notificação',
            body: 'Você tem uma nova notificação',
            deepLink: 'app://home'
        };
        
        // Substituir variáveis básicas
        const title = this.replaceVariables(template.title, messageData);
        const body = this.replaceVariables(template.body, messageData);
        const deepLink = this.replaceVariables(template.deepLink, messageData);

        return { title, body, deepLink };
    }

    replaceVariables(text, variables) {
        if (!text || !variables) return text;
        
        return text.replace(/\{\{(\w+)\}\}/g, (match, key) => {
            return variables[key] || match;
        });
    }

    async testConnection() {
        return await this.pushProvider.testConnection();
    }

    getStats() {
        const providerStats = this.pushProvider.getStats ? this.pushProvider.getStats() : {};
        
        return {
            service: 'push',
            ...this.stats,
            uptime: Date.now() - this.stats.startTime.getTime(),
            provider: providerStats
        };
    }
}

module.exports = new PushService();