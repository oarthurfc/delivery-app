// listeners/push-queue.listener.js
const rabbitmqConfig = require('../config/rabbitmq');
const notificationService = require('../services/notification.service');
const logger = require('../utils/logger');
const Joi = require('joi');

class PushQueueListener {
    constructor() {
        this.isRunning = false;
        this.consumerTag = null;
        this.queueName = 'push-notifications';
        
        // Schema de validação para mensagens de push
        this.pushMessageSchema = Joi.object({
            messageId: Joi.string().required(),
            userId: Joi.alternatives().try(
                Joi.string(),
                Joi.number(),
                Joi.array().items(Joi.alternatives().try(Joi.string(), Joi.number()))
            ).required(),
            type: Joi.string().required(),
            title: Joi.string().optional(),
            body: Joi.string().optional(),
            data: Joi.object().optional(),
            deepLink: Joi.string().optional(),
            timestamp: Joi.date().iso().optional(),
            priority: Joi.string().valid('low', 'normal', 'high').default('normal')
        });
    }

    async start() {
        if (this.isRunning) {
            logger.warn(`⚠️ Push queue listener já está rodando`);
            return;
        }

        try {
            logger.info(`🎧 Iniciando listener para fila: ${this.queueName}`);
            
            this.consumerTag = await rabbitmqConfig.consumeQueue(
                this.queueName,
                this.handlePushMessage.bind(this),
                { 
                    noAck: false,
                    prefetch: 1
                }
            );
            
            this.isRunning = true;
            logger.info(`✅ Push queue listener iniciado: ${this.queueName}`);

        } catch (error) {
            logger.error(`❌ Erro ao iniciar push queue listener:`, error);
            throw error;
        }
    }

    async stop() {
        if (!this.isRunning) {
            logger.warn(`⚠️ Push queue listener já está parado`);
            return;
        }

        try {
            logger.info(`🛑 Parando push queue listener...`);
            
            if (this.consumerTag) {
                await rabbitmqConfig.getChannel().cancel(this.consumerTag);
                logger.info(`🔌 Consumer parado: ${this.queueName}`);
            }
            
            this.isRunning = false;
            this.consumerTag = null;
            logger.info(`✅ Push queue listener parado`);

        } catch (error) {
            logger.error(`❌ Erro ao parar push queue listener:`, error);
            throw error;
        }
    }

    async handlePushMessage(messageData, messageInfo) {
        const startTime = Date.now();
        
        logger.info(`📨 Recebida mensagem de push:`, {
            messageId: messageData.messageId,
            userId: messageData.userId,
            type: messageData.type,
            queueMessageId: messageInfo.messageId
        });

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
            const result = await notificationService.processNotification('push', validatedData);
            
            const processingTime = Date.now() - startTime;
            
            logger.info(`✅ Mensagem de push processada com sucesso:`, {
                messageId: validatedData.messageId,
                userId: validatedData.userId,
                processingTimeMs: processingTime,
                success: result.success
            });

        } catch (error) {
            const processingTime = Date.now() - startTime;
            
            logger.error(`❌ Erro ao processar mensagem de push:`, {
                messageId: messageData.messageId,
                userId: messageData.userId,
                error: error.message,
                processingTimeMs: processingTime
            });

            // Re-throw para que o RabbitMQ saiba que houve falha
            throw error;
        }
    }

    async validateMessage(messageData) {
        try {
            const { error, value } = this.pushMessageSchema.validate(messageData, {
                abortEarly: false,
                stripUnknown: true
            });

            if (error) {
                const errorDetails = error.details.map(detail => detail.message).join(', ');
                throw new Error(`Dados da mensagem de push inválidos: ${errorDetails}`);
            }

            // Adicionar messageId se não existir
            if (!value.messageId) {
                value.messageId = `push_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            }

            return value;

        } catch (error) {
            logger.error('❌ Erro na validação da mensagem de push:', {
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
            messageId: `test_push_${Date.now()}`,
            userId: testData.userId || 'test-user-123',
            type: testData.type || 'welcome',
            title: testData.title || 'Notificação de Teste',
            body: testData.body || 'Esta é uma notificação de teste.',
            data: testData.data || { test: true },
            timestamp: new Date().toISOString(),
            ...testData
        };

        await rabbitmqConfig.publishMessage('notification.exchange', 'push', testMessage);
        logger.info(`📤 Mensagem de teste publicada na fila push-notifications:`, { messageId: testMessage.messageId });
        
        return testMessage;
    }
}

module.exports = new PushQueueListener();
        