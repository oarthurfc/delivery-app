// providers/email/azure-email.provider.js
const EmailProviderInterface = require('../../interfaces/email-provider-interface');
const azureFunctionsConfig = require('../../config/azure-functions');
const logger = require('../../utils/logger');

class AzureEmailProvider extends EmailProviderInterface {
    constructor() {
        super();
        this.name = 'azure-email-provider';
        this.azureFunctions = azureFunctionsConfig;
        this.stats = {
            sent: 0,
            errors: 0,
            startTime: new Date()
        };
    }

    async sendEmail(emailData) {
        try {
            logger.info(`📧 [AZURE] Enviando email via Azure Functions: ${emailData.to}`, {
                subject: emailData.subject,
                template: emailData.template
            });

            // Mapear dados para formato esperado pelo Azure Functions
            const azureEmailData = this.mapToAzureFormat(emailData);
            
            const result = await this.azureFunctions.sendEmail(azureEmailData);
            
            this.stats.sent++;

            const response = {
                success: true,
                messageId: result.data.messageId || `azure_${Date.now()}`,
                provider: this.name,
                recipient: emailData.to,
                subject: emailData.subject,
                sentAt: new Date().toISOString(),
                executionTime: result.executionTime,
                azureResponse: result.data
            };

            logger.info(`✅ [AZURE] Email enviado com sucesso: ${response.messageId}`);
            return response;

        } catch (error) {
            this.stats.errors++;
            logger.error(`❌ [AZURE] Erro ao enviar email:`, {
                error: error.message,
                recipient: emailData.to
            });
            throw new Error(`Azure Functions email failed: ${error.message}`);
        }
    }

    mapToAzureFormat(emailData) {
        return {
            to: emailData.to,
            subject: emailData.subject,
            template: emailData.template,
            variables: emailData.variables || {},
            body: emailData.body,
            // Adicionar outros campos que o Azure Functions espera
            fromName: process.env.EMAIL_FROM_NAME || 'Notification Service',
            fromEmail: process.env.EMAIL_FROM_ADDRESS || 'noreply@example.com'
        };
    }

    async testConnection() {
        try {
            logger.info('🧪 [AZURE] Testando conectividade com Azure Functions...');
            
            const testResult = await this.azureFunctions.testConnection();
            
            if (testResult.success) {
                logger.info('✅ [AZURE] Conexão com Azure Functions bem-sucedida');
                return {
                    success: true,
                    provider: this.name,
                    status: 'connected',
                    message: 'Azure Functions acessível',
                    azureResult: testResult
                };
            } else {
                logger.warn('⚠️ [AZURE] Azure Functions não está acessível');
                return {
                    success: false,
                    provider: this.name,
                    status: 'unavailable',
                    error: testResult.error
                };
            }

        } catch (error) {
            logger.error('❌ [AZURE] Teste de conexão falhou:', error);
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
    }
}

module.exports = AzureEmailProvider;
