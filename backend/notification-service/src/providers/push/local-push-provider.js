// providers/push/local-push.provider.js
const PushProviderInterface = require('../../interfaces/push-provider.interface');
const logger = require('../../utils/logger');

class LocalPushProvider extends PushProviderInterface {
    constructor() {
        super();
        this.name = 'local-push-provider';
        this.stats = {
            sent: 0,
            broadcasts: 0,
            errors: 0,
            startTime: new Date()
        };
    }

    async sendPushNotification(pushData) {
        try {
            const userIds = Array.isArray(pushData.userId) ? pushData.userId : [pushData.userId];
            
            logger.info(`🔔 [LOCAL] Enviando push notification para ${userIds.length} usuário(s)`, {
                userIds,
                title: pushData.title
            });

            const results = [];
            
            for (const userId of userIds) {
                const result = await this.sendSingleNotification({
                    ...pushData,
                    userId
                });
                results.push(result);
            }

            this.stats.sent += results.length;

            return {
                success: true,
                provider: this.name,
                sent: results.length,
                results,
                sentAt: new Date().toISOString()
            };

        } catch (error) {
            this.stats.errors++;
            logger.error(`❌ [LOCAL] Erro ao enviar push notification:`, {
                error: error.message,
                userId: pushData.userId
            });
            throw error;
        }
    }

    async sendSingleNotification(pushData) {
        await this.simulatePushSending(pushData);

        return {
            messageId: `local_push_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            userId: pushData.userId,
            title: pushData.title,
            status: 'sent'
        };
    }

    async sendBroadcast(broadcastData) {
        try {
            logger.info(`📡 [LOCAL] Enviando broadcast para ${broadcastData.userIds.length} usuários`, {
                title: broadcastData.title,
                userCount: broadcastData.userIds.length
            });

            const results = [];
            
            for (const userId of broadcastData.userIds) {
                try {
                    const result = await this.sendSingleNotification({
                        userId,
                        title: broadcastData.title,
                        body: broadcastData.body,
                        data: broadcastData.data
                    });
                    results.push(result);
                } catch (error) {
                    results.push({
                        userId,
                        status: 'failed',
                        error: error.message
                    });
                }
            }

            this.stats.broadcasts++;
            this.stats.sent += results.filter(r => r.status === 'sent').length;

            return {
                success: true,
                provider: this.name,
                totalUsers: broadcastData.userIds.length,
                sent: results.filter(r => r.status === 'sent').length,
                failed: results.filter(r => r.status === 'failed').length,
                results,
                sentAt: new Date().toISOString()
            };

        } catch (error) {
            this.stats.errors++;
            logger.error(`❌ [LOCAL] Erro ao enviar broadcast:`, error);
            throw error;
        }
    }

    async simulatePushSending(pushData) {
        // Simular delay de processamento
        await new Promise(resolve => setTimeout(resolve, 50 + Math.random() * 150));
        
        // Simular chance de falha (3%)
        if (Math.random() < 0.03) {
            throw new Error('Simulação de falha no push local');
        }

        // Log da "notificação" que seria enviada
        logger.debug(`🔔 [LOCAL] Notificação push:`, {
            userId: pushData.userId,
            title: pushData.title,
            body: pushData.body,
            data: pushData.data,
            deepLink: pushData.deepLink
        });
    }

    async testConnection() {
        try {
            logger.info('🧪 [LOCAL] Testando provedor local de push...');
            
            await this.simulatePushSending({
                userId: 'test-user',
                title: 'Teste de Conexão',
                body: 'Testando push notifications local',
                data: { test: true }
            });

            return {
                success: true,
                provider: this.name,
                status: 'connected',
                message: 'Provedor local de push funcionando corretamente'
            };

        } catch (error) {
            logger.error('❌ [LOCAL] Teste de push falhou:', error);
            return {
                success: false,
                provider: this.name,
                status: 'error',
                error: error.message
            };
        }
    }

    getConfig() {
        return {
            provider: this.name,
            type: 'local',
            stats: this.stats,
            features: ['single-notification', 'broadcast', 'deep-links']
        };
    }

    getStats() {
        return {
            ...this.stats,
            uptime: Date.now() - this.stats.startTime.getTime()
        };
    }
}

module.exports = LocalPushProvider;