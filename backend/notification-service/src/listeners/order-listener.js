const rabbitmqConfig = require('../config/rabbitmq');
const notificationService = require('../services/notification.service');
const logger = require('../utils/logger');
const Joi = require('joi');

class OrderListener {
    constructor() {
        this.isRunning = false;
        this.consumers = new Map(); // Track active consumers
        
        // Schema de validação para eventos de pedidos
        this.orderEventSchema = Joi.object({
            eventId: Joi.string().required(),
            eventType: Joi.string().valid('ORDER_COMPLETED', 'ORDER_CREATED').required(),
            timestamp: Joi.date().iso().required(),
            orderId: Joi.number().integer().positive().required(),
            customerId: Joi.number().integer().positive().required(),
            driverId: Joi.number().integer().positive().allow(null),
            status: Joi.string().required(),
            description: Joi.string().allow('', null),
            imageUrl: Joi.string().uri().allow('', null),
            originAddress: Joi.object({
                street: Joi.string().allow(''),
                number: Joi.string().allow(''),
                neighborhood: Joi.string().allow(''),
                city: Joi.string().required(),
                latitude: Joi.number().allow(null),
                longitude: Joi.number().allow(null)
            }).allow(null),
            destinationAddress: Joi.object({
                street: Joi.string().allow(''),
                number: Joi.string().allow(''),
                neighborhood: Joi.string().allow(''),
                city: Joi.string().required(),
                latitude: Joi.number().allow(null),
                longitude: Joi.number().allow(null)
            }).allow(null)
        });
    }

    /**
     * Iniciar listeners para eventos de pedidos
     */
    async start() {
        if (this.isRunning) {
            logger.warn('⚠️ Order listener já está rodando');
            return;
        }

        try {
            logger.info('🎧 Iniciando Order Listener...');
            
            // Listener para pedidos finalizados
            await this.startOrderCompletedListener();
            
            // Listener para pedidos criados
            await this.startOrderCreatedListener();
            
            this.isRunning = true;
            logger.info('✅ Order Listener iniciado com sucesso');

        } catch (error) {
            logger.error('❌ Erro ao iniciar Order Listener:', error);
            throw error;
        }
    }

    /**
     * Parar todos os listeners
     */
    async stop() {
        if (!this.isRunning) {
            logger.warn('⚠️ Order listener já está parado');
            return;
        }

        try {
            logger.info('🛑 Parando Order Listener...');
            
            // Parar todos os consumers
            for (const [queueName, consumerTag] of this.consumers) {
                try {
                    await rabbitmqConfig.getChannel().cancel(consumerTag);
                    logger.info(`🔌 Consumer parado: ${queueName}`);
                } catch (error) {
                    logger.error(`❌ Erro ao parar consumer ${queueName}:`, error);
                }
            }
            
            this.consumers.clear();
            this.isRunning = false;
            logger.info('✅ Order Listener parado com sucesso');

        } catch (error) {
            logger.error('❌ Erro ao parar Order Listener:', error);
            throw error;
        }
    }

    /**
     * Iniciar listener para pedidos finalizados
     */
    async startOrderCompletedListener() {
        const queueName = 'order.completed';
        
        logger.info(`👂 Configurando listener para: ${queueName}`);
        
        const consumerTag = await rabbitmqConfig.consumeQueue(
            queueName,
            this.handleOrderCompleted.bind(this),
            { 
                noAck: false,
                prefetch: 1 // Processar uma mensagem por vez
            }
        );
        
        this.consumers.set(queueName, consumerTag);
        logger.info(`✅ Listener ativo para pedidos finalizados: ${queueName}`);
    }

    /**
     * Iniciar listener para pedidos criados
     */
    async startOrderCreatedListener() {
        const queueName = 'order.created';
        
        logger.info(`👂 Configurando listener para: ${queueName}`);
        
        const consumerTag = await rabbitmqConfig.consumeQueue(
            queueName,
            this.handleOrderCreated.bind(this),
            { 
                noAck: false,
                prefetch: 1
            }
        );
        
        this.consumers.set(queueName, consumerTag);
        logger.info(`✅ Listener ativo para pedidos criados: ${queueName}`);
    }

    /**
     * Processar evento de pedido finalizado
     */
    async handleOrderCompleted(orderData, messageInfo) {
        const startTime = Date.now();
        
        logger.info(`📨 Recebido evento ORDER_COMPLETED:`, {
            orderId: orderData.orderId,
            messageId: messageInfo.messageId,
            routingKey: messageInfo.routingKey
        });

        try {
            // Validar dados do evento
            const validatedData = await this.validateOrderEvent(orderData);
            
            // Verificar se é evento duplicado (opcional - baseado em eventId)
            if (await this.isDuplicateEvent(validatedData.eventId)) {
                logger.warn(`⚠️ Evento duplicado ignorado: ${validatedData.eventId}`, {
                    orderId: validatedData.orderId
                });
                return; // Não processar evento duplicado
            }

            // Processar através do notification service
            const result = await notificationService.processOrderCompleted(validatedData);
            
            const processingTime = Date.now() - startTime;
            
            logger.info(`✅ Evento ORDER_COMPLETED processado com sucesso:`, {
                orderId: validatedData.orderId,
                eventId: validatedData.eventId,
                processingTimeMs: processingTime,
                emailSent: result.email?.success,
                pushSent: result.pushNotification?.success,
                errors: result.errors.length
            });

        } catch (error) {
            const processingTime = Date.now() - startTime;
            
            logger.error(`❌ Erro ao processar ORDER_COMPLETED:`, {
                orderId: orderData.orderId,
                messageId: messageInfo.messageId,
                error: error.message,
                processingTimeMs: processingTime
            });

            // Re-throw para que o RabbitMQ saiba que houve falha
            throw error;
        }
    }

    /**
     * Processar evento de pedido criado
     */
    async handleOrderCreated(orderData, messageInfo) {
        const startTime = Date.now();
        
        logger.info(`📨 Recebido evento ORDER_CREATED:`, {
            orderId: orderData.orderId,
            messageId: messageInfo.messageId,
            routingKey: messageInfo.routingKey
        });

        try {
            // Validar dados do evento
            const validatedData = await this.validateOrderEvent(orderData);
            
            // Verificar se é evento duplicado
            if (await this.isDuplicateEvent(validatedData.eventId)) {
                logger.warn(`⚠️ Evento duplicado ignorado: ${validatedData.eventId}`, {
                    orderId: validatedData.orderId
                });
                return;
            }

            // Processar através do notification service
            const result = await notificationService.processOrderCreated(validatedData);
            
            const processingTime = Date.now() - startTime;
            
            logger.info(`✅ Evento ORDER_CREATED processado com sucesso:`, {
                orderId: validatedData.orderId,
                eventId: validatedData.eventId,
                processingTimeMs: processingTime,
                emailSent: result.email?.success,
                pushSent: result.pushNotification?.success,
                errors: result.errors.length
            });

        } catch (error) {
            const processingTime = Date.now() - startTime;
            
            logger.error(`❌ Erro ao processar ORDER_CREATED:`, {
                orderId: orderData.orderId,
                messageId: messageInfo.messageId,
                error: error.message,
                processingTimeMs: processingTime
            });

            throw error;
        }
    }

    /**
     * Validar dados do evento de pedido
     */
    async validateOrderEvent(orderData) {
        try {
            const { error, value } = this.orderEventSchema.validate(orderData, {
                abortEarly: false,
                stripUnknown: true
            });

            if (error) {
                const errorDetails = error.details.map(detail => detail.message).join(', ');
                throw new Error(`Dados do evento inválidos: ${errorDetails}`);
            }

            return value;

        } catch (error) {
            logger.error('❌ Erro na validação do evento:', {
                error: error.message,
                orderData: JSON.stringify(orderData, null, 2)
            });
            throw error;
        }
    }

    /**
     * Verificar se evento já foi processado (prevenção de duplicatas)
     * Em produção, usar Redis ou banco de dados
     */
    async isDuplicateEvent(eventId) {
        // Por enquanto, implementação simples em memória
        // Em produção, usar Redis com TTL
        if (!this.processedEvents) {
            this.processedEvents = new Set();
        }

        if (this.processedEvents.has(eventId)) {
            return true;
        }

        // Adicionar à lista de processados
        this.processedEvents.add(eventId);
        
        // Limitar tamanho do Set (simples cleanup)
        if (this.processedEvents.size > 10000) {
            const eventsArray = Array.from(this.processedEvents);
            this.processedEvents = new Set(eventsArray.slice(-5000)); // Manter últimos 5000
        }

        return false;
    }

    /**
     * Obter estatísticas do listener
     */
    getStats() {
        return {
            isRunning: this.isRunning,
            activeConsumers: Array.from(this.consumers.keys()),
            processedEventsCount: this.processedEvents?.size || 0
        };
    }

    /**
     * Reprocessar mensagem específica (para testes/debug)
     */
    async reprocessMessage(queueName, messageData) {
        logger.info(`🔄 Reprocessando mensagem manual: ${queueName}`);
        
        try {
            const messageInfo = {
                queue: queueName,
                messageId: `manual-${Date.now()}`,
                timestamp: Date.now(),
                routingKey: 'manual.reprocess'
            };

            if (queueName === 'order.completed') {
                await this.handleOrderCompleted(messageData, messageInfo);
            } else if (queueName === 'order.created') {
                await this.handleOrderCreated(messageData, messageInfo);
            } else {
                throw new Error(`Fila não suportada: ${queueName}`);
            }

            logger.info(`✅ Reprocessamento manual concluído: ${queueName}`);
            return { success: true };

        } catch (error) {
            logger.error(`❌ Erro no reprocessamento manual: ${queueName}`, error);
            throw error;
        }
    }
}

module.exports = new OrderListener();