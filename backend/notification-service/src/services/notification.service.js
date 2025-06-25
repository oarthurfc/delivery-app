// services/notification.service.js
const emailService = require('./email.service');
const pushService = require('./push.service');
const logger = require('../utils/logger');

class NotificationService {
    constructor() {
        this.stats = {
            totalProcessed: 0,
            emailsProcessed: 0,
            pushProcessed: 0,
            errors: 0,
            startTime: new Date()
        };
    }

    /**
     * Processar qualquer tipo de notificação
     */
    async processNotification(type, messageData) {
        try {
            logger.info(`🔄 Processando notificação: ${type}`, {
                messageId: messageData.messageId,
                type
            });

            let result;
            switch (type) {
                case 'email':
                    result = await emailService.processEmailMessage(messageData);
                    this.stats.emailsProcessed++;
                    break;
                case 'push':
                    result = await pushService.processPushMessage(messageData);
                    this.stats.pushProcessed++;
                    break;
                default:
                    throw new Error(`Tipo de notificação não suportado: ${type}`);
            }

            this.stats.totalProcessed++;
            
            logger.info(`✅ Notificação processada com sucesso: ${type}`, {
                messageId: messageData.messageId
            });

            return result;

        } catch (error) {
            this.stats.errors++;
            logger.error(`❌ Erro ao processar notificação ${type}:`, {
                messageId: messageData.messageId,
                error: error.message
            });
            throw error;
        }
    }

    async testAllServices() {
        const results = {
            timestamp: new Date().toISOString(),
            email: null,
            push: null,
            overall: false
        };

        try {
            results.email = await emailService.testConnection();
            results.push = await pushService.testConnection();
            results.overall = results.email.success && results.push.success;
            
        } catch (error) {
            logger.error('❌ Erro no teste de serviços:', error);
            results.error = error.message;
        }

        return results;
    }

    getDetailedStats() {
        return {
            service: 'notification-service',
            uptime: Date.now() - this.stats.startTime.getTime(),
            stats: this.stats,
            subServices: {
                email: emailService.getStats(),
                push: pushService.getStats()
            }
        };
    }

    resetStats() {
        this.stats = {
            totalProcessed: 0,
            emailsProcessed: 0,
            pushProcessed: 0,
            errors: 0,
            startTime: new Date()
        };
        
        logger.info('🔄 Estatísticas resetadas');
    }
}

module.exports = new NotificationService();