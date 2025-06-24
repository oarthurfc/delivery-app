const httpClient = require('../utils/http-client');
const logger = require('../utils/logger');

class EmailService {
    constructor() {
        this.azureFunctionsBaseUrl = process.env.AZURE_FUNCTIONS_BASE_URL || 'http://localhost:7071';
        this.azureFunctionsApiKey = process.env.AZURE_FUNCTIONS_API_KEY || '';
        this.timeout = parseInt(process.env.AZURE_FUNCTIONS_TIMEOUT) || 30000;
    }

    /**
     * Processar pedido finalizado - envia emails de resumo
     */
    async processOrderCompleted(orderData) {
        try {
            logger.info(`📧 Processando emails para pedido finalizado: ${orderData.orderId}`);
            
            const response = await httpClient.post(
                `${this.azureFunctionsBaseUrl}/api/ProcessOrderCompleted`,
                orderData,
                {
                    headers: this.getHeaders(),
                    timeout: this.timeout
                }
            );

            logger.info(`✅ Emails de pedido finalizado enviados: ${orderData.orderId}`, {
                orderId: orderData.orderId,
                response: response.data
            });

            return {
                success: true,
                orderId: orderData.orderId,
                type: 'order_completed',
                result: response.data
            };

        } catch (error) {
            logger.error(`❌ Erro ao processar emails de pedido finalizado: ${orderData.orderId}`, {
                error: error.message,
                orderId: orderData.orderId,
                status: error.response?.status,
                statusText: error.response?.statusText
            });

            throw new Error(`Falha no envio de emails para pedido ${orderData.orderId}: ${error.message}`);
        }
    }

    /**
     * Processar pedido criado - envia email de confirmação
     */
    async processOrderCreated(orderData) {
        try {
            logger.info(`📧 Processando email de confirmação para pedido: ${orderData.orderId}`);
            
            const response = await httpClient.post(
                `${this.azureFunctionsBaseUrl}/api/ProcessOrderCreated`,
                orderData,
                {
                    headers: this.getHeaders(),
                    timeout: this.timeout
                }
            );

            logger.info(`✅ Email de confirmação enviado: ${orderData.orderId}`, {
                orderId: orderData.orderId,
                response: response.data
            });

            return {
                success: true,
                orderId: orderData.orderId,
                type: 'order_created',
                result: response.data
            };

        } catch (error) {
            logger.error(`❌ Erro ao processar email de confirmação: ${orderData.orderId}`, {
                error: error.message,
                orderId: orderData.orderId,
                status: error.response?.status,
                statusText: error.response?.statusText
            });

            throw new Error(`Falha no envio de email de confirmação para pedido ${orderData.orderId}: ${error.message}`);
        }
    }

    /**
     * Enviar campanha promocional
     */
    async sendPromotionalCampaign(campaignData) {
        try {
            logger.info(`📧 Enviando campanha promocional: ${campaignData.title}`);
            
            const response = await httpClient.post(
                `${this.azureFunctionsBaseUrl}/api/SendPromotionalCampaign`,
                campaignData,
                {
                    headers: this.getHeaders(),
                    timeout: this.timeout
                }
            );

            logger.info(`✅ Campanha promocional enviada: ${campaignData.title}`, {
                campaign: campaignData.title,
                response: response.data
            });

            return {
                success: true,
                campaignId: campaignData.campaignId,
                title: campaignData.title,
                type: 'promotional_campaign',
                result: response.data
            };

        } catch (error) {
            logger.error(`❌ Erro ao enviar campanha promocional: ${campaignData.title}`, {
                error: error.message,
                campaign: campaignData.title,
                status: error.response?.status,
                statusText: error.response?.statusText
            });

            throw new Error(`Falha no envio da campanha ${campaignData.title}: ${error.message}`);
        }
    }

    /**
     * Testar conexão com Azure Functions
     */
    async testConnection() {
        try {
            logger.info('🧪 Testando conexão com Azure Functions...');
            
            const testData = {
                test: true,
                timestamp: new Date().toISOString(),
                service: 'notification-service'
            };

            const response = await httpClient.post(
                `${this.azureFunctionsBaseUrl}/api/ProcessOrderCreated`,
                {
                    eventType: 'CONNECTION_TEST',
                    orderId: 'test-' + Date.now(),
                    customerId: 999,
                    ...testData
                },
                {
                    headers: this.getHeaders(),
                    timeout: 10000
                }
            );

            logger.info('✅ Conexão com Azure Functions testada com sucesso', {
                status: response.status,
                baseUrl: this.azureFunctionsBaseUrl
            });

            return {
                success: true,
                status: response.status,
                baseUrl: this.azureFunctionsBaseUrl,
                response: response.data
            };

        } catch (error) {
            logger.error('❌ Teste de conexão com Azure Functions falhou', {
                error: error.message,
                baseUrl: this.azureFunctionsBaseUrl,
                status: error.response?.status
            });

            return {
                success: false,
                error: error.message,
                baseUrl: this.azureFunctionsBaseUrl,
                status: error.response?.status
            };
        }
    }

    /**
     * Enviar email customizado (para uso futuro)
     */
    async sendCustomEmail(emailData) {
        try {
            logger.info(`📧 Enviando email customizado para: ${emailData.to}`);
            
            // Para emails customizados, pode usar uma função genérica
            const response = await httpClient.post(
                `${this.azureFunctionsBaseUrl}/api/SendCustomEmail`,
                emailData,
                {
                    headers: this.getHeaders(),
                    timeout: this.timeout
                }
            );

            logger.info(`✅ Email customizado enviado para: ${emailData.to}`);

            return {
                success: true,
                to: emailData.to,
                subject: emailData.subject,
                type: 'custom_email',
                result: response.data
            };

        } catch (error) {
            logger.error(`❌ Erro ao enviar email customizado para: ${emailData.to}`, {
                error: error.message,
                to: emailData.to,
                subject: emailData.subject
            });

            throw new Error(`Falha no envio de email para ${emailData.to}: ${error.message}`);
        }
    }

    /**
     * Obter headers para requisições às Azure Functions
     */
    getHeaders() {
        const headers = {
            'Content-Type': 'application/json',
            'User-Agent': 'notification-service/1.0.0'
        };

        if (this.azureFunctionsApiKey) {
            headers['x-functions-key'] = this.azureFunctionsApiKey;
        }

        return headers;
    }

    /**
     * Obter estatísticas do serviço
     */
    getStats() {
        return {
            service: 'email',
            baseUrl: this.azureFunctionsBaseUrl,
            hasApiKey: !!this.azureFunctionsApiKey,
            timeout: this.timeout,
            environment: process.env.NODE_ENV || 'development'
        };
    }
}

module.exports = new EmailService();