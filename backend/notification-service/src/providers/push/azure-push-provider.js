// providers/push/azure-push.provider.js
const PushProviderInterface = require('../../interfaces/push-provider-interface');
const azureFunctionsConfig = require('../../config/azure-functions');
const logger = require('../../utils/logger');

class AzurePushProvider extends PushProviderInterface {
    constructor() {
        super();
        this.name = 'azure-push-provider';
        this.azureFunctions = azureFunctionsConfig;
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
            
            logger.info(`🔔 [AZURE] Enviando push via Azure Functions para ${userIds.length} usuário(s)`, {
                userIds,
                title: pushData.title
            });

            // Mapear dados para formato esperado pelo Azure Functions
            const azurePushData = this.mapToAzureFormat(pushData, userIds);
            
            const result = await this.azureFunctions.callEndpoint('sendPushNotification', azurePushData);
            
            this.stats.sent += userIds.length;

            const response = {
                success: true,
                provider: this.name,
                sent: userIds.length,
                sentAt: new Date().toISOString(),
                executionTime: result.executionTime,
                azureResponse: result.data
            };

            logger.info(`✅ [AZURE] Push notifications enviadas: ${userIds.length}`);
            return response;

        } catch (error) {
            this.stats.errors++;
            logger.error(`❌ [AZURE] Erro ao enviar push notification:`, {
                error: error.message,
                userId: pushData.userId
            });
            throw new Error(`Azure Functions push failed: ${error.message}`);
        }
    }

    async sendBroadcast(broadcastData) {
        try {
            logger.info(`📡 [AZURE] Enviando broadcast via Azure Functions para ${broadcastData.userIds.length} usuários`, {
                title: broadcastData.title,
                userCount: broadcastData.userIds.length
            });

            const azureBroadcastData = {
                userIds: broadcastData.userIds,
                title: broadcastData.title,
                body: broadcastData.body,
                data: broadcastData.data || {},
                type: 'broadcast'
            };
            
            const result = await this.azureFunctions.callEndpoint('sendBroadcastNotification', azureBroadcastData);
            
            this.stats.broadcasts++;
            this.stats.sent += broadcastData.userIds.length;

            const response = {
                success: true,
                provider: this.name,
                totalUsers: broadcastData.userIds.length,
                sent: result.data.sent || broadcastData.userIds.length,
                failed: result.data.failed || 0,
                sentAt: new Date().toISOString(),
                executionTime: result.executionTime,
                azureResponse: result.data
            };

            logger.info(`✅ [AZURE] Broadcast enviado com sucesso`);
            return response;

        } catch (error) {
            this.stats.errors++;
            logger.error(`❌ [AZURE] Erro ao enviar broadcast:`, error);
            throw new Error(`Azure Functions broadcast failed: ${error.message}`);
        }
    }

    mapToAzureFormat(pushData, userIds) {
        return {
            userIds: userIds || [pushData.userId],
            title: pushData.title,
            body: pushData.body,
            data: pushData.data || {},
            deepLink: pushData.deepLink,
            type: 'notification'
        };
    }

    async testConnection() {
        try {
            logger.info('🧪 [AZURE] Testando push notifications via Azure Functions...');
            
            const testResult = await this.azureFunctions.testConnection();
            
            if (testResult.success) {
                logger.info('✅ [AZURE] Azure Functions push acessível');
                return {
                    success: true,
                    provider: this.name,
                    status: 'connected',
                    message: 'Azure Functions push disponível',
                    azureResult: testResult
                };
            } else {
                logger.warn('⚠️ [AZURE] Azure Functions push não acessível');
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
        const azureConfig = this.azureFunctions.getConfig();
        return {
            provider: this.name,
            type: 'azure-functions',
            stats: this.stats,
            azure: {
                baseUrl: azureConfig.baseUrl,
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
    }}