// listeners/email-queue.listener.js
const rabbitmqConfig = require('../config/rabbitmq');
const notificationService = require('../services/notification.service');
const logger = require('../utils/logger');
const Joi = require('joi');

class EmailQueueListener {
    constructor() {
        this.isRunning = false;
        this.consumerTag = null;
        this.queueName = 'emails';
        
        // Schema de validação para mensagens de email
        this.emailMessageSchema = Joi.object({
            messageId: Joi.string().required(),
            to: Joi.string().email().required(),
            type: Joi.string().required(),
            subject: Joi.string().optional(),
            body: Joi.string().optional(),
            template: Joi.string().optional(),
            variables: Joi.object().optional(),
            timestamp: Joi.date().iso().optional(),
            priority: Joi.string().valid('low', 'normal', 'high').default('normal')
        });
    }

    async start() {
        if (this.isRunning) {
            logger.warn(`⚠️ Email queue listener já está rodando`);
            return;
        }

        try {
            logger.info(`🎧 Iniciando listener para fila: ${this.queueName}`);
            
            this.consumerTag = await rabbitmqConfig.consumeQueue(
                this.queueName,
                this.handleEmailMessage.bind(this),
                { 
                    noAck: false,
                    prefetch: 1 // Processar uma mensagem por vez
                }
            );
            
            this.isRunning = true;
            logger.info(`✅ Email queue listener iniciado: ${this.queueName}`);

        } catch (error) {
            logger.error(`❌ Erro ao iniciar email queue listener:`, error);
            throw error;
        }
    }

    async stop() {
        if (!this.isRunning) {
            logger.warn(`⚠️ Email queue listener já está parado`);
            return;
        }

        try {
            logger.info(`🛑 Parando email queue listener...`);
            
            if (this.consumerTag) {
                await rabbitmqConfig.getChannel().cancel(this.consumerTag);
                logger.info(`🔌 Consumer parado: ${this.queueName}`);
            }
            
            this.isRunning = false;
            this.consumerTag = null;
            logger.info(`✅ Email queue listener parado`);

        } catch (error) {
            logger.error(`❌ Erro ao parar email queue listener:`, error);
            throw error;
        }
    }

    async handleEmailMessage(messageData, messageInfo) {
        const startTime = Date.now();
        
        logger.info(`📨 Recebida mensagem de email:`, {
            messageId: messageData.messageId,
            to: messageData.to,
            type: messageData.type,
            queueMessageId: messageInfo.messageId
        });
        //dar log da mensagem recebida
        logger.debug(`Mensagem completa:`, JSON.stringify(messageData, null, 2));

        try {
            // Validar dados da mensagem
            const validatedData = await this.validateMessage(messageData);
            
            // Adicionar informações da fila
            validatedData.queueInfo = {
                queue: messageInfo.queue,
                routingKey: messageInfo.routingKey,
                receivedAt: new Date().toISOString()
            };

            // Processar através do notification service
            const result = await notificationService.processNotification('email', validatedData);
            
            const processingTime = Date.now() - startTime;
            
            logger.info(`✅ Mensagem de email processada com sucesso:`, {
                messageId: validatedData.messageId,
                to: validatedData.to,
                processingTimeMs: processingTime,
                success: result.success
            });

        } catch (error) {
            const processingTime = Date.now() - startTime;
            
            logger.error(`❌ Erro ao processar mensagem de email:`, {
                messageId: messageData.messageId,
                to: messageData.to,
                error: error.message,
                processingTimeMs: processingTime
            });

            // Re-throw para que o RabbitMQ saiba que houve falha
            throw error;
        }
    }

    async validateMessage(messageData) {
        try {
            const { error, value } = this.emailMessageSchema.validate(messageData, {
                abortEarly: false,
                stripUnknown: true
            });

            if (error) {
                const errorDetails = error.details.map(detail => detail.message).join(', ');
                throw new Error(`Dados da mensagem de email inválidos: ${errorDetails}`);
            }

            // Adicionar messageId se não existir
            if (!value.messageId) {
                value.messageId = `email_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            }

            return value;

        } catch (error) {
            logger.error('❌ Erro na validação da mensagem de email:', {
                error: error.message,
                messageData: JSON.stringify(messageData, null, 2)
            });
            throw error;
        }
    }

    getStats() {
        return {
            queueName: this.queueName,
            isRunning: this.isRunning,
            consumerTag: this.consumerTag
        };
    }

    // Método para publicar mensagem de teste
    async publishTestMessage(testData = {}) {
        const testMessage = {
            messageId: `test_email_${Date.now()}`,
            to: testData.to || 'test@example.com',
            type: testData.type || 'welcome',
            subject: testData.subject || 'Teste de Email',
            body: testData.body || 'Esta é uma mensagem de teste.',
            timestamp: new Date().toISOString(),
            ...testData
        };

        await rabbitmqConfig.publishMessage('notification.exchange', 'email', testMessage);
        logger.info(`📤 Mensagem de teste publicada na fila emails:`, { messageId: testMessage.messageId });
        
        return testMessage;
    }
}

module.exports = new EmailQueueListener();