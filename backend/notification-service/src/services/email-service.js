const azureFunctionsConfig = require('../config/azure-functions');
const logger = require('../utils/logger');

class EmailService {
    constructor() {
        // Usar a configuração centralizada do Azure Functions
        this.azureFunctions = azureFunctionsConfig;
    }

    /**
     * Processar pedido finalizado - envia emails de resumo
     */
    async processOrderCompleted(orderData) {
        try {
            logger.info(`📧 Processando emails para pedido finalizado: ${orderData.orderId}`);
            
            const result = await this.azureFunctions.callProcessOrderCompleted(orderData);
            
            logger.info(`✅ Emails de pedido finalizado enviados: ${orderData.orderId}`, {
                orderId: orderData.orderId,
                executionTime: result.executionTime
            });

            return {
                success: true,
                orderId: orderData.orderId,
                type: 'order_completed',
                result: result.data,
                executionTime: result.executionTime
            };

        } catch (error) {
            logger.error(`❌ Erro ao processar emails de pedido finalizado: ${orderData.orderId}`, {
                error: error.message,
                orderId: orderData.orderId
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
            
            const result = await this.azureFunctions.callProcessOrderCreated(orderData);
            
            logger.info(`✅ Email de confirmação enviado: ${orderData.orderId}`, {
                orderId: orderData.orderId,
                executionTime: result.executionTime
            });

            return {
                success: true,
                orderId: orderData.orderId,
                type: 'order_created',
                result: result.data,
                executionTime: result.executionTime
            };

        } catch (error) {
            logger.error(`❌ Erro ao processar email de confirmação: ${orderData.orderId}`, {
                error: error.message,
                orderId: orderData.orderId
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
            
            const result = await this.azureFunctions.callSendPromotionalCampaign(campaignData);
            
            logger.info(`✅ Campanha promocional enviada: ${campaignData.title}`, {
                campaign: campaignData.title,
                executionTime: result.executionTime
            });

            return {
                success: true,
                campaignId: campaignData.campaignId,
                title: campaignData.title,
                type: 'promotional_campaign',
                result: result.data,
                executionTime: result.executionTime
            };

        } catch (error) {
            logger.error(`❌ Erro ao enviar campanha promocional: ${campaignData.title}`, {
                error: error.message,
                campaign: campaignData.title
            });

            throw new Error(`Falha no envio da campanha ${campaignData.title}: ${error.message}`);
        }
    }

    /**
     * Testar conexão com Azure Functions
     */
    async testConnection() {
        try {
            logger.info('🧪 Testando conexão com Azure Functions via EmailService...');
            
            const result = await this.azureFunctions.testConnection();
            
            if (result.success) {
                logger.info('✅ Teste de conexão EmailService bem-sucedido');
            } else {
                logger.warn('⚠️ Teste de conexão EmailService retornou falha');
            }

            return result;

        } catch (error) {
            logger.error('❌ Teste de conexão EmailService falhou', {
                error: error.message
            });

            return {
                success: false,
                error: error.message,
                service: 'email'
            };
        }
    }

    /**
     * Enviar email customizado (implementação futura)
     */
    async sendCustomEmail(emailData) {
        try {
            logger.info(`📧 Enviando email customizado para: ${emailData.to}`);
            
            // Por enquanto, usar endpoint genérico ou lançar erro
            throw new Error('Endpoint SendCustomEmail não implementado nas Azure Functions ainda');

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
     * Verificar se Azure Functions estão disponíveis
     */
    async isAvailable() {
        try {
            const healthCheck = await this.azureFunctions.healthCheck();
            return healthCheck.available;
        } catch (error) {
            logger.error('❌ Erro ao verificar disponibilidade das Azure Functions:', error);
            return false;
        }
    }

    /**
     * Obter estatísticas do serviço
     */
    getStats() {
        const azureConfig = this.azureFunctions.getConfig();
        
        return {
            service: 'email',
            azureFunctions: {
                baseUrl: azureConfig.baseUrl,
                hasApiKey: azureConfig.hasApiKey,
                timeout: azureConfig.timeout,
                endpoints: Object.keys(azureConfig.endpoints)
            },
            environment: process.env.NODE_ENV || 'development'
        };
    }

    /**
     * Atualizar configurações das Azure Functions
     */
    updateAzureFunctionsConfig(newConfig) {
        logger.info('🔧 Atualizando configuração das Azure Functions via EmailService');
        this.azureFunctions.updateConfig(newConfig);
    }

    /**
     * Obter configuração atual das Azure Functions
     */
    getAzureFunctionsConfig() {
        return this.azureFunctions.getConfig();
    }
}

module.exports = new EmailService();