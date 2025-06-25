const PushProviderInterface = require('../../interfaces/push-provider-interface');
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
            logger.info(`🔔 [LOCAL] Enviando push notification`, {
                userId: pushData.userId,
                fcmToken: pushData.fcmToken ? `${pushData.fcmToken.substring(0, 20)}...` : 'not provided',
                title: pushData.title
            });

            const result = await this.sendSingleNotification(pushData);
            this.stats.sent++;

            return {
                success: true,
                provider: this.name,
                sent: 1,
                result,
                sentAt: new Date().toISOString()
            };

        } catch (error) {
            this.stats.errors++;
            logger.error(`❌ [LOCAL] Erro ao enviar push notification:`, {
                error: error.message,
                userId: pushData.userId,
                fcmToken: pushData.fcmToken ? `${pushData.fcmToken.substring(0, 20)}...` : 'not provided'
            });
            throw error;
        }
    }

    async sendSingleNotification(pushData) {
        await this.simulatePushSending(pushData);

        return {
            messageId: `local_push_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            userId: pushData.userId,
            fcmToken: pushData.fcmToken ? `${pushData.fcmToken.substring(0, 20)}...` : 'not provided',
            title: pushData.title,
            body: pushData.body,
            status: 'sent'
        };
    }

    async sendBroadcast(broadcastData) {
        try {
            logger.info(`📡 [LOCAL] Enviando broadcast para ${broadcastData.notifications.length} notifications`, {
                title: broadcastData.title,
                notificationCount: broadcastData.notifications.length
            });

            const results = [];
            let successCount = 0;
            let failureCount = 0;
            
            for (const notification of broadcastData.notifications) {
                try {
                    const pushData = {
                        userId: notification.userId,
                        fcmToken: notification.fcmToken,
                        title: broadcastData.title,
                        body: broadcastData.body,
                        data: {
                            ...broadcastData.data,
                            ...notification.customData
                        }
                    };

                    const result = await this.sendSingleNotification(pushData);
                    results.push({
                        userId: notification.userId,
                        fcmToken: notification.fcmToken ? `${notification.fcmToken.substring(0, 20)}...` : 'not provided',
                        status: 'sent',
                        messageId: result.messageId
                    });
                    successCount++;

                } catch (error) {
                    results.push({
                        userId: notification.userId,
                        fcmToken: notification.fcmToken ? `${notification.fcmToken.substring(0, 20)}...` : 'not provided',
                        status: 'failed',
                        error: error.message
                    });
                    failureCount++;
                }
            }

            this.stats.broadcasts++;
            this.stats.sent += successCount;

            return {
                success: true,
                provider: this.name,
                totalNotifications: broadcastData.notifications.length,
                sent: successCount,
                failed: failureCount,
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
        logger.debug(`🔔 [LOCAL] Notificação push simulada:`, {
            userId: pushData.userId,
            fcmToken: pushData.fcmToken ? `${pushData.fcmToken.substring(0, 20)}...` : 'not provided',
            title: pushData.title,
            body: pushData.body,
            data: pushData.data
        });
    }

    async testConnection() {
        try {
            logger.info('🧪 [LOCAL] Testando provedor local de push...');
            
            await this.simulatePushSending({
                userId: 'test-user',
                fcmToken: 'test_fcm_token_' + Date.now(),
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
            features: ['single-notification', 'broadcast', 'fcm-tokens', 'simulation']
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