// providers/push/azure-push-provider.js - REFATORADO
const PushProviderInterface = require('../../interfaces/push-provider-interface');
const azurePushFunctionsConfig = require('../../config/azure-push-functions');
const logger = require('../../utils/logger');

class AzurePushProvider extends PushProviderInterface {
    constructor() {
        super();
        this.name = 'azure-push-provider';
        this.azurePushFunctions = azurePushFunctionsConfig;
        this.stats = {
            sent: 0,
            broadcasts: 0,
            errors: 0,
            startTime: new Date()
        };
    }

    async sendPushNotification(pushData) {
        try {
            // Validar se tem fcmToken
            if (!pushData.fcmToken) {
                throw new Error('fcmToken é obrigatório para push notifications via Azure');
            }

            logger.info(`🔔 [AZURE] Enviando push notification via Azure Functions`, {
                fcmToken: `${pushData.fcmToken.substring(0, 20)}...`,
                title: pushData.title,
                userId: pushData.userId
            });

            // Preparar dados no formato esperado pela Azure Function
            const azurePushData = this.mapToAzureFormat(pushData);
            
            const result = await this.azurePushFunctions.callPushSender(azurePushData);
            
            this.stats.sent++;

            const response = {
                success: true,
                messageId: result.data.messageId || `azure_push_${Date.now()}`,
                provider: this.name,
                fcmToken: `${pushData.fcmToken.substring(0, 20)}...`,
                title: pushData.title,
                userId: pushData.userId,
                sentAt: new Date().toISOString(),
                executionTime: result.executionTime,
                azureResponse: result.data
            };

            logger.info(`✅ [AZURE] Push notification enviada com sucesso: ${response.messageId}`);
            return response;

        } catch (error) {
            this.stats.errors++;
            logger.error(`❌ [AZURE] Erro ao enviar push notification:`, {
                error: error.message,
                fcmToken: pushData.fcmToken ? `${pushData.fcmToken.substring(0, 20)}...` : 'not provided',
                userId: pushData.userId
            });
            throw new Error(`Azure Push Function failed: ${error.message}`);
        }
    }

    async sendBroadcast(broadcastData) {
        try {
            logger.info(`📡 [AZURE] Enviando broadcast via Azure Functions para ${broadcastData.notifications.length} notifications`, {
                title: broadcastData.title,
                notificationCount: broadcastData.notifications.length
            });

            const results = [];
            let successCount = 0;
            let failureCount = 0;

            // Enviar cada notificação individualmente
            for (const notification of broadcastData.notifications) {
                try {
                    const pushData = {
                        fcmToken: notification.fcmToken,
                        userId: notification.userId,
                        title: broadcastData.title,
                        body: broadcastData.body,
                        data: broadcastData.data || {}
                    };

                    const result = await this.sendPushNotification(pushData);
                    results.push({
                        userId: notification.userId,
                        fcmToken: `${notification.fcmToken.substring(0, 20)}...`,
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

            const response = {
                success: true,
                provider: this.name,
                totalNotifications: broadcastData.notifications.length,
                sent: successCount,
                failed: failureCount,
                results,
                sentAt: new Date().toISOString()
            };

            logger.info(`✅ [AZURE] Broadcast enviado: ${successCount} enviadas, ${failureCount} falharam`);
            return response;

        } catch (error) {
            this.stats.errors++;
            logger.error(`❌ [AZURE] Erro ao enviar broadcast:`, error);
            throw new Error(`Azure Push Functions broadcast failed: ${error.message}`);
        }
    }

    mapToAzureFormat(pushData) {
        // Formato exato esperado pela Azure Function
        const azurePayload = {
            fcmToken: pushData.fcmToken,
            title: pushData.title,
            body: pushData.body
        };

        // Adicionar dados adicionais se existirem
        if (pushData.data && Object.keys(pushData.data).length > 0) {
            azurePayload.data = pushData.data;
        }

        return azurePayload;
    }

    async testConnection() {
        try {
            logger.info('🧪 [AZURE] Testando push notifications via Azure Functions...');
            
            const testResult = await this.azurePushFunctions.testConnection();
            
            if (testResult.success) {
                logger.info('✅ [AZURE] Azure Push Functions acessível');
                return {
                    success: true,
                    provider: this.name,
                    status: 'connected',
                    message: 'Azure Push Functions disponível',
                    azureResult: testResult
                };
            } else {
                logger.warn('⚠️ [AZURE] Azure Push Functions não acessível');
                return {
                    success: false,
                    provider: this.name,
                    status: 'unavailable',
                    error: testResult.error
                };
            }

        } catch (error) {
            logger.error('❌ [AZURE] Teste de push falhou:', error);
            return {
                success: false,
                provider: this.name,
                status: 'error',
                error: error.message
            };
        }
    }

    getConfig() {
        const azureConfig = this.azurePushFunctions.getConfig();
        return {
            provider: this.name,
            type: 'azure-push-functions',
            stats: this.stats,
            azure: {
                baseUrl: azureConfig.baseUrl,
                endpoint: azureConfig.endpoint,
                hasApiKey: azureConfig.hasApiKey,
                timeout: azureConfig.timeout
            }
        };
    }

    getStats() {
        return {
            ...this.stats,
            uptime: Date.now() - this.stats.startTime.getTime()
        };
    }
}

module.exports = AzurePushProvider;