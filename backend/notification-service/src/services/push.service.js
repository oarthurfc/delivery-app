// listeners/push-queue-listener.js 
const rabbitmqConfig = require('../config/rabbitmq');
const notificationService = require('../services/notification.service');
const logger = require('../utils/logger');
const Joi = require('joi');

class PushQueueListener {
    constructor() {
        this.isRunning = false;
        this.consumerTag = null;
        this.queueName = 'push-notifications';
        
        // Schema de validação para notificações individuais
        this.individualPushSchema = Joi.object({
            messageId: Joi.string().required(),
            userId: Joi.alternatives().try(
                Joi.string(),
                Joi.number()
            ).optional(),
            fcmToken: Joi.string().optional(),
            type: Joi.string().required(),
            title: Joi.string().optional(),
            body: Joi.string().optional(),
            data: Joi.object().optional(),
            variables: Joi.object().optional(),
            timestamp: Joi.date().iso().optional(),
            priority: Joi.string().valid('low', 'normal', 'high').default('normal')
        });

        // Schema para notificação dentro de broadcast
        this.broadcastNotificationSchema = Joi.object({
            userId: Joi.alternatives().try(
                Joi.string(),
                Joi.number()
            ).optional(),
            fcmToken: Joi.string().optional(),
            customData: Joi.object().optional()
        });

        // Schema de validação para broadcasts
        this.broadcastPushSchema = Joi.object({
            messageId: Joi.string().required(),
            type: Joi.string().valid('broadcast').required(),
            title: Joi.string().optional(),
            body: Joi.string().optional(),
            data: Joi.object().optional(),
            notifications: Joi.array().items(this.broadcastNotificationSchema).min(1).required(),
            variables: Joi.object().optional(),
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
            type: messageData.type,
            userId: messageData.userId,
            isBroadcast: messageData.type === 'broadcast',
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
                type: validatedData.type,
                userId: validatedData.userId,
                processingTimeMs: processingTime,
                success: result.success
            });

        } catch (error) {
            const processingTime = Date.now() - startTime;
            
            logger.error(`❌ Erro ao processar mensagem de push:`, {
                messageId: messageData.messageId,
                type: messageData.type,
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
            // Escolher schema baseado no tipo
            const schema = messageData.type === 'broadcast' 
                ? this.broadcastPushSchema 
                : this.individualPushSchema;

            const { error, value } = schema.validate(messageData, {
                abortEarly: false,
                stripUnknown: true
            });

            if (error) {
                const errorDetails = error.details.map(detail => detail.message).join(', ');
                throw new Error(`Dados da mensagem de push inválidos: ${errorDetails}`);
            }

            // Validações adicionais
            await this.performAdditionalValidations(value);

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

    async performAdditionalValidations(messageData) {
        // Para notificações individuais
        if (messageData.type !== 'broadcast') {
            // Deve ter pelo menos fcmToken OU userId
            if (!messageData.fcmToken && !messageData.userId) {
                throw new Error('fcmToken ou userId é obrigatório para notificações individuais');
            }

            // Validar formato do FCM token se fornecido
            if (messageData.fcmToken && !this.isValidFcmToken(messageData.fcmToken)) {
                throw new Error('Formato de fcmToken inválido');
            }
        }

        // Para broadcasts
        if (messageData.type === 'broadcast') {
            // Validar cada notificação
            for (let i = 0; i < messageData.notifications.length; i++) {
                const notification = messageData.notifications[i];
                
                if (!notification.fcmToken && !notification.userId) {
                    throw new Error(`Notificação ${i}: fcmToken ou userId é obrigatório`);
                }

                if (notification.fcmToken && !this.isValidFcmToken(notification.fcmToken)) {
                    throw new Error(`Notificação ${i}: formato de fcmToken inválido`);
                }
            }
        }
    }

    isValidFcmToken(token) {
        // Validação básica do formato do FCM token
        // FCM tokens são tipicamente strings longas com caracteres alfanuméricos e alguns símbolos
        if (!token || typeof token !== 'string') {
            return false;
        }

        // Verificar se tem tamanho razoável (FCM tokens são geralmente 140+ caracteres)
        if (token.length < 20) {
            return false;
        }

        // Verificar se contém apenas caracteres válidos (letras, números, -, _, :)
        const validPattern = /^[a-zA-Z0-9_\-:]+$/;
        return validPattern.test(token);
    }

    getStats() {
        return {
            queueName: this.queueName,
            isRunning: this.isRunning,
            consumerTag: this.consumerTag
        };
    }

    // Método para publicar mensagem de teste individual
    async publishTestMessage(testData = {}) {
        const testMessage = {
            messageId: `test_push_${Date.now()}`,
            userId: testData.userId || 'test-user-123',
            fcmToken: testData.fcmToken || 'test_fcm_token_' + Date.now(),
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

    // Método para publicar mensagem de teste de broadcast
    async publishTestBroadcastMessage(testData = {}) {
        const testMessage = {
            messageId: `test_broadcast_${Date.now()}`,
            type: 'broadcast',
            title: testData.title || 'Broadcast de Teste',
            body: testData.body || 'Esta é uma mensagem de broadcast de teste.',
            data: testData.data || { test: true, broadcast: true },
            notifications: testData.notifications || [
                {
                    userId: 'user1',
                    fcmToken: 'test_fcm_token_user1_' + Date.now()
                },
                {
                    userId: 'user2', 
                    fcmToken: 'test_fcm_token_user2_' + Date.now()
                }
            ],
            timestamp: new Date().toISOString(),
            ...testData
        };

        await rabbitmqConfig.publishMessage('notification.exchange', 'push.broadcast', testMessage);
        logger.info(`📤 Mensagem de broadcast de teste publicada na fila push-notifications:`, { 
            messageId: testMessage.messageId,
            notificationCount: testMessage.notifications.length 
        });
        
        return testMessage;
    }
}

module.exports = new PushQueueListener();