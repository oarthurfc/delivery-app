// config/rabbitmq.js - Atualizado para suas variáveis
const amqp = require('amqplib');
const logger = require('../utils/logger');

class RabbitMQConfig {
    constructor() {
        this.connection = null;
        this.channel = null;
        this.reconnectDelay = 5000;
        this.maxReconnectAttempts = 10;
        this.reconnectAttempts = 0;
        
        // Configuração das filas para notificações
        this.config = {
            exchanges: [
                {
                    name: 'notification.exchange',
                    type: 'topic',
                    options: { durable: true }
                }
            ],
            queues: [
                {
                    name: 'emails',
                    options: { 
                        durable: true,
                        arguments: {
                            'x-dead-letter-exchange': 'notification.dlx',
                            'x-message-ttl': 3600000 // 1 hora
                        }
                    },
                    bindings: [
                        { exchange: 'notification.exchange', routingKey: 'email' },
                        { exchange: 'notification.exchange', routingKey: 'email.*' }
                    ]
                },
                {
                    name: 'push-notifications',
                    options: { 
                        durable: true,
                        arguments: {
                            'x-dead-letter-exchange': 'notification.dlx',
                            'x-message-ttl': 3600000
                        }
                    },
                    bindings: [
                        { exchange: 'notification.exchange', routingKey: 'push' },
                        { exchange: 'notification.exchange', routingKey: 'push.*' }
                    ]
                }
            ]
        };
    }

    async connect() {
        try {
            const rabbitmqUrl = this.buildConnectionUrl();
            logger.info(`🔌 Conectando ao RabbitMQ: ${this.maskPassword(rabbitmqUrl)}`);
            
            this.connection = await amqp.connect(rabbitmqUrl);
            this.channel = await this.connection.createChannel();
            
            await this.channel.prefetch(1);
            
            this.connection.on('error', this.handleConnectionError.bind(this));
            this.connection.on('close', this.handleConnectionClose.bind(this));
            
            this.reconnectAttempts = 0;
            logger.info('✅ Conectado ao RabbitMQ com sucesso');
            
        } catch (error) {
            logger.error('❌ Erro ao conectar RabbitMQ:', error.message);
            await this.handleReconnect();
        }
    }    buildConnectionUrl() {
        // Obter variáveis de ambiente diretamente do docker-compose
        const {
            RABBITMQ_HOST = 'localhost',
            RABBITMQ_PORT = '5672',
            RABBITMQ_USERNAME = process.env.RABBITMQ_USER, // Compatível com a variável do docker-compose
            RABBITMQ_PASSWORD = process.env.RABBITMQ_PASSWORD, // Compatível com a variável do docker-compose
            RABBITMQ_VHOST = '/'
        } = process.env;

        // Verificar se as variáveis essenciais estão definidas
        if (!RABBITMQ_HOST || !RABBITMQ_USERNAME || !RABBITMQ_PASSWORD) {
            logger.warn('⚠️ Variáveis de ambiente RabbitMQ incompletas, usando valores padrão');
        }

        return `amqp://${RABBITMQ_USERNAME}:${RABBITMQ_PASSWORD}@${RABBITMQ_HOST}:${RABBITMQ_PORT}${RABBITMQ_VHOST}`;
    }

    maskPassword(url) {
        return url.replace(/:([^:@]+)@/, ':****@');
    }

    async setupQueuesAndExchanges() {
        try {
            logger.info('⚙️ Configurando exchanges e filas de notificação...');
            
            // Criar exchanges
            for (const exchange of this.config.exchanges) {
                await this.channel.assertExchange(
                    exchange.name, 
                    exchange.type, 
                    exchange.options
                );
                logger.info(`📡 Exchange criado: ${exchange.name}`);
            }

            // Criar Dead Letter Exchange
            await this.channel.assertExchange('notification.dlx', 'direct', { durable: true });
            logger.info(`📡 Dead Letter Exchange criado: notification.dlx`);

            // Criar filas e bindings
            for (const queue of this.config.queues) {
                await this.channel.assertQueue(queue.name, queue.options);
                logger.info(`📥 Fila criada: ${queue.name}`);
                
                // Criar bindings
                for (const binding of queue.bindings) {
                    await this.channel.bindQueue(
                        queue.name,
                        binding.exchange,
                        binding.routingKey
                    );
                    logger.info(`🔗 Binding: ${queue.name} <- ${binding.exchange} (${binding.routingKey})`);
                }
            }

            // Criar fila DLQ
            await this.channel.assertQueue('notification.dlq', { durable: true });
            await this.channel.bindQueue('notification.dlq', 'notification.dlx', '#');
            logger.info(`💀 Dead Letter Queue criada: notification.dlq`);

            logger.info('✅ Todas as filas de notificação configuradas');
            
        } catch (error) {
            logger.error('❌ Erro ao configurar filas/exchanges:', error);
            throw error;
        }
    }

    async handleConnectionError(error) {
        logger.error('🚨 Erro na conexão RabbitMQ:', error.message);
    }

    async handleConnectionClose() {
        logger.warn('🔌 Conexão RabbitMQ fechada. Tentando reconectar...');
        await this.handleReconnect();
    }

    async handleReconnect() {
        if (this.reconnectAttempts >= this.maxReconnectAttempts) {
            logger.error(`❌ Máximo de tentativas de reconexão atingido (${this.maxReconnectAttempts})`);
            process.exit(1);
        }

        this.reconnectAttempts++;
        logger.info(`🔄 Tentativa de reconexão ${this.reconnectAttempts}/${this.maxReconnectAttempts} em ${this.reconnectDelay}ms`);
        
        setTimeout(async () => {
            try {
                await this.connect();
                await this.setupQueuesAndExchanges();
            } catch (error) {
                logger.error('❌ Falha na reconexão:', error.message);
            }
        }, this.reconnectDelay);
    }

    async publishMessage(exchange, routingKey, message, options = {}) {
        try {
            if (!this.channel) {
                throw new Error('Canal RabbitMQ não está disponível');
            }

            const messageBuffer = Buffer.from(JSON.stringify(message));
            const defaultOptions = {
                persistent: true,
                timestamp: Date.now(),
                messageId: this.generateMessageId()
            };

            const result = this.channel.publish(
                exchange,
                routingKey,
                messageBuffer,
                { ...defaultOptions, ...options }
            );

            if (result) {
                logger.info(`📤 Mensagem publicada: ${exchange}/${routingKey}`, {
                    messageId: message.messageId || defaultOptions.messageId
                });
                return true;
            } else {
                logger.warn(`⚠️ Mensagem não foi aceita: ${exchange}/${routingKey}`);
                return false;
            }

        } catch (error) {
            logger.error('❌ Erro ao publicar mensagem:', error);
            throw error;
        }
    }

    async consumeQueue(queueName, callback, options = {}) {
        try {
            if (!this.channel) {
                throw new Error('Canal RabbitMQ não está disponível');
            }

            const defaultOptions = {
                noAck: false,
                exclusive: false
            };

            const consumerInfo = await this.channel.consume(
                queueName,
                async (message) => {
                    if (message) {
                        try {
                            const content = JSON.parse(message.content.toString());
                            const messageInfo = {
                                queue: queueName,
                                routingKey: message.fields.routingKey,
                                exchange: message.fields.exchange,
                                messageId: message.properties.messageId,
                                timestamp: message.properties.timestamp
                            };

                            logger.debug(`📨 Processando mensagem: ${queueName} (${messageInfo.messageId})`);
                            
                            await callback(content, messageInfo);
                            
                            this.channel.ack(message);
                            logger.debug(`✅ Mensagem confirmada: ${messageInfo.messageId}`);

                        } catch (error) {
                            logger.error(`❌ Erro ao processar mensagem ${message.properties.messageId}:`, error);
                            this.channel.nack(message, false, false);
                        }
                    }
                },
                { ...defaultOptions, ...options }
            );

            logger.info(`👂 Escutando fila: ${queueName} (consumer: ${consumerInfo.consumerTag})`);
            return consumerInfo.consumerTag;

        } catch (error) {
            logger.error(`❌ Erro ao consumir fila ${queueName}:`, error);
            throw error;
        }
    }

    generateMessageId() {
        return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    }

    async disconnect() {
        try {
            if (this.channel) {
                await this.channel.close();
                logger.info('📛 Canal RabbitMQ fechado');
            }
            
            if (this.connection) {
                await this.connection.close();
                logger.info('🔌 Conexão RabbitMQ fechada');
            }
        } catch (error) {
            logger.error('❌ Erro ao fechar conexão RabbitMQ:', error);
        }
    }

    // Getters
    getChannel() {
        return this.channel;
    }

    getConnection() {
        return this.connection;
    }

    isConnected() {
        return this.connection && !this.connection.connection.destroyed;
    }

    // Métodos utilitários
    async publishEmailMessage(emailData) {
        return this.publishMessage('notification.exchange', 'email', emailData);
    }

    async publishPushMessage(pushData) {
        return this.publishMessage('notification.exchange', 'push', pushData);
    }

    getQueueConfig() {
        return this.config;
    }
}

// Singleton instance
const rabbitmqConfig = new RabbitMQConfig();
module.exports = rabbitmqConfig;