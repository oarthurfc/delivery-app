const emailService = require('./email.service');
const pushService = require('./push.service');
const logger = require('../utils/logger');

class NotificationService {
    constructor() {
        this.stats = {
            processedOrders: 0,
            sentEmails: 0,
            sentPushNotifications: 0,
            campaigns: 0,
            errors: 0,
            startTime: new Date()
        };
    }

    /**
     * Processar pedido finalizado - envia emails E notificações
     */
    async processOrderCompleted(orderData) {
        logger.info(`🔄 Processando finalização de pedido: ${orderData.orderId}`);
        
        const results = {
            orderId: orderData.orderId,
            timestamp: new Date().toISOString(),
            email: null,
            pushNotification: null,
            success: false,
            errors: []
        };

        try {
            // 1. Enviar emails de resumo (via Azure Functions)
            try {
                results.email = await emailService.processOrderCompleted(orderData);
                this.stats.sentEmails++;
                logger.info(`✅ Emails processados para pedido: ${orderData.orderId}`);
            } catch (error) {
                results.errors.push(`Email: ${error.message}`);
                logger.error(`❌ Falha nos emails para pedido: ${orderData.orderId}`, error);
            }

            // 2. Enviar notificação de avaliação
            try {
                results.pushNotification = await pushService.sendEvaluationNotification(orderData);
                this.stats.sentPushNotifications++;
                logger.info(`✅ Notificação de avaliação processada para pedido: ${orderData.orderId}`);
            } catch (error) {
                results.errors.push(`Push: ${error.message}`);
                logger.error(`❌ Falha na notificação para pedido: ${orderData.orderId}`, error);
            }

            // Considerar sucesso se pelo menos um canal funcionou
            results.success = results.email?.success || results.pushNotification?.success;
            
            if (results.success) {
                this.stats.processedOrders++;
                logger.info(`✅ Pedido finalizado processado com sucesso: ${orderData.orderId}`, {
                    emailSent: !!results.email?.success,
                    pushSent: !!results.pushNotification?.success,
                    errors: results.errors.length
                });
            } else {
                this.stats.errors++;
                logger.error(`❌ Falha total no processamento do pedido: ${orderData.orderId}`, {
                    errors: results.errors
                });
            }

            return results;

        } catch (error) {
            this.stats.errors++;
            logger.error(`❌ Erro crítico ao processar pedido finalizado: ${orderData.orderId}`, error);
            
            results.errors.push(`Crítico: ${error.message}`);
            results.success = false;
            
            throw error;
        }
    }

    /**
     * Processar pedido criado - envia email de confirmação E notificação
     */
    async processOrderCreated(orderData) {
        logger.info(`🔄 Processando criação de pedido: ${orderData.orderId}`);
        
        const results = {
            orderId: orderData.orderId,
            timestamp: new Date().toISOString(),
            email: null,
            pushNotification: null,
            success: false,
            errors: []
        };

        try {
            // 1. Enviar email de confirmação
            try {
                results.email = await emailService.processOrderCreated(orderData);
                this.stats.sentEmails++;
                logger.info(`✅ Email de confirmação processado para pedido: ${orderData.orderId}`);
            } catch (error) {
                results.errors.push(`Email: ${error.message}`);
                logger.error(`❌ Falha no email de confirmação para pedido: ${orderData.orderId}`, error);
            }

            // 2. Enviar notificação de criação
            try {
                results.pushNotification = await pushService.sendOrderCreatedNotification(orderData);
                this.stats.sentPushNotifications++;
                logger.info(`✅ Notificação de criação processada para pedido: ${orderData.orderId}`);
            } catch (error) {
                results.errors.push(`Push: ${error.message}`);
                logger.error(`❌ Falha na notificação de criação para pedido: ${orderData.orderId}`, error);
            }

            // Considerar sucesso se pelo menos um canal funcionou
            results.success = results.email?.success || results.pushNotification?.success;
            
            if (results.success) {
                this.stats.processedOrders++;
                logger.info(`✅ Pedido criado processado com sucesso: ${orderData.orderId}`, {
                    emailSent: !!results.email?.success,
                    pushSent: !!results.pushNotification?.success,
                    errors: results.errors.length
                });
            } else {
                this.stats.errors++;
                logger.error(`❌ Falha total no processamento da criação do pedido: ${orderData.orderId}`, {
                    errors: results.errors
                });
            }

            return results;

        } catch (error) {
            this.stats.errors++;
            logger.error(`❌ Erro crítico ao processar pedido criado: ${orderData.orderId}`, error);
            
            results.errors.push(`Crítico: ${error.message}`);
            results.success = false;
            
            throw error;
        }
    }

    /**
     * Processar campanha promocional - envia emails E notificações
     */
    async processPromotionalCampaign(campaignData) {
        logger.info(`🔄 Processando campanha promocional: ${campaignData.title}`);
        
        const results = {
            campaignId: campaignData.campaignId,
            title: campaignData.title,
            timestamp: new Date().toISOString(),
            email: null,
            pushNotifications: null,
            success: false,
            errors: []
        };

        try {
            // 1. Enviar emails da campanha
            try {
                results.email = await emailService.sendPromotionalCampaign(campaignData);
                this.stats.sentEmails += results.email.result?.sent?.length || 0;
                logger.info(`✅ Emails promocionais processados: ${campaignData.title}`);
            } catch (error) {
                results.errors.push(`Email: ${error.message}`);
                logger.error(`❌ Falha nos emails promocionais: ${campaignData.title}`, error);
            }

            // 2. Enviar notificações push da campanha
            try {
                // Simular usuários alvo (no futuro, vir do próprio campaignData)
                const targetUsers = campaignData.targetUsers || [
                    { id: 1, name: 'João' },
                    { id: 2, name: 'Maria' }
                ];
                
                results.pushNotifications = await pushService.sendPromotionalNotification(campaignData, targetUsers);
                this.stats.sentPushNotifications += results.pushNotifications.sent || 0;
                logger.info(`✅ Notificações promocionais processadas: ${campaignData.title}`);
            } catch (error) {
                results.errors.push(`Push: ${error.message}`);
                logger.error(`❌ Falha nas notificações promocionais: ${campaignData.title}`, error);
            }

            // Considerar sucesso se pelo menos um canal funcionou
            results.success = results.email?.success || results.pushNotifications?.success;
            
            if (results.success) {
                this.stats.campaigns++;
                logger.info(`✅ Campanha promocional processada com sucesso: ${campaignData.title}`, {
                    emailsSent: results.email?.result?.sent?.length || 0,
                    pushSent: results.pushNotifications?.sent || 0,
                    errors: results.errors.length
                });
            } else {
                this.stats.errors++;
                logger.error(`❌ Falha total na campanha promocional: ${campaignData.title}`, {
                    errors: results.errors
                });
            }

            return results;

        } catch (error) {
            this.stats.errors++;
            logger.error(`❌ Erro crítico ao processar campanha: ${campaignData.title}`, error);
            
            results.errors.push(`Crítico: ${error.message}`);
            results.success = false;
            
            throw error;
        }
    }

    /**
     * Testar conectividade com todos os serviços
     */
    async testAllServices() {
        logger.info('🧪 Testando conectividade de todos os serviços...');
        
        const results = {
            timestamp: new Date().toISOString(),
            email: null,
            push: null,
            overallHealth: false
        };

        try {
            // Testar serviço de email
            results.email = await emailService.testConnection();
            
            // Testar serviço de push
            results.push = await pushService.testConnection();
            
            // Considerar saudável se pelo menos um serviço funciona
            results.overallHealth = results.email?.success || results.push?.success;
            
            logger.info('🏥 Teste de saúde concluído', {
                emailHealthy: results.email?.success,
                pushHealthy: results.push?.success,
                overallHealth: results.overallHealth
            });

            return results;

        } catch (error) {
            logger.error('❌ Erro no teste de saúde dos serviços', error);
            results.overallHealth = false;
            results.error = error.message;
            
            return results;
        }
    }

    /**
     * Obter estatísticas detalhadas do serviço
     */
    getDetailedStats() {
        const uptime = Date.now() - this.stats.startTime.getTime();
        
        return {
            service: 'notification-service',
            version: '1.0.0',
            uptime: {
                milliseconds: uptime,
                seconds: Math.floor(uptime / 1000),
                minutes: Math.floor(uptime / 60000),
                hours: Math.floor(uptime / 3600000)
            },
            stats: {
                ...this.stats,
                startTime: this.stats.startTime.toISOString()
            },
            subServices: {
                email: emailService.getStats(),
                push: pushService.getStats()
            },
            healthStatus: {
                overall: this.stats.errors < this.stats.processedOrders * 0.1, // <10% erro
                errorRate: this.stats.processedOrders > 0 ? (this.stats.errors / this.stats.processedOrders) : 0
            }
        };
    }

    /**
     * Resetar estatísticas
     */
    resetStats() {
        logger.info('🔄 Resetando estatísticas do serviço');
        
        this.stats = {
            processedOrders: 0,
            sentEmails: 0,
            sentPushNotifications: 0,
            campaigns: 0,
            errors: 0,
            startTime: new Date()
        };
    }
}

module.exports = new NotificationService();