const amqp = require('amqplib');
const logger = require('../utils/logger');

class RabbitMQConfig {
    constructor() {
        this.connection = null;
        this.channel = null;
        this.reconnectDelay = 5000;
        this.maxReconnectAttempts = 10;
        this.reconnectAttempts = 0;
        
        // Configuração das filas e exchanges
        this.config = {
            exchanges: [
                {
                    name: 'order.exchange',
                    type: 'topic',
                    options: { durable: true }
                },
                {
                    name: 'promotional.exchange',
                    type: 'topic',
                    options: { durable: true }
                }
            ],
            queues: [
                {
                    name: 'order.completed',
                    options: { 
                        durable: true,
                        arguments: {
                            'x-dead-letter-exchange': 'order.dlx',
                            'x-message-ttl': 3600000 // 1 hora
                        }
                    },
                    bindings: [
                        { exchange: 'order.exchange', routingKey: 'order.completed' }
                    ]
                },
                {
                    name: 'order.created',
                    options: { 
                        durable: true,
                        arguments: {
                            'x-dead-letter-exchange': 'order.dlx',
                            'x-message-ttl': 3600000
                        }
                    },
                    bindings: [
                        { exchange: 'order.exchange', routingKey: 'order.created' }
                    ]
                },
                {
                    name: 'promotional.campaigns',
                    options: { 
                        durable: true,
                        arguments: {
                            'x-dead-letter-exchange': 'promotional.dlx',
                            'x-message-ttl': 7200000 // 2 horas
                        }
                    },
                    bindings: [
                        { exchange: 'promotional.exchange', routingKey: 'promotional.send' }
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
            
            // Configurar prefetch para processar mensagens uma por vez
            await this.channel.prefetch(1);
            
            // Configurar handlers de erro
            this.connection.on('error', this.handleConnectionError.bind(this));
            this.connection.on('close', this.handleConnectionClose.bind(this));
            
            this.reconnectAttempts = 0;
            logger.info('✅ Conectado ao RabbitMQ com sucesso');
            
        } catch (error) {
            logger.error('❌ Erro ao conectar RabbitMQ:', error.message);
            await this.handleReconnect();
        }
    }

    buildConnectionUrl() {
        const {
            RABBITMQ_HOST = 'localhost',
            RABBITMQ_PORT = '5672',
            RABBITMQ_USERNAME = 'delivery_user',
            RABBITMQ_PASSWORD = 'delivery_pass123',
            RABBITMQ_VHOST = '/'
        } = process.env;

        return `amqp://${RABBITMQ_USERNAME}:${RABBITMQ_PASSWORD}@${RABBITMQ_HOST}:${RABBITMQ_PORT}${RABBITMQ_VHOST}`;
    }

    maskPassword(url) {
        return url.replace(/:([^:@]+)@/, ':****@');
    }

    async setupQueuesAndExchanges() {
        try {
            logger.info('⚙️ Configurando exchanges e filas...');
            
            // Criar exchanges
            for (const exchange of this.config.exchanges) {
                await this.channel.assertExchange(
                    exchange.name, 
                    exchange.type, 
                    exchange.options
                );
                logger.info(`📡 Exchange criado: ${exchange.name}`);
            }

            // Criar Dead Letter Exchanges
            await this.channel.assertExchange('order.dlx', 'direct', { durable: true });
            await this.channel.assertExchange('promotional.dlx', 'direct', { durable: true });

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

            logger.info('✅ Todas as filas e exchanges configuradas');
            
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
                logger.info(`📤 Mensagem publicada: ${exchange}/${routingKey}`);
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

            await this.channel.consume(
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

                            logger.info(`📨 Processando mensagem: ${queueName} (${messageInfo.messageId})`);
                            
                            await callback(content, messageInfo);
                            
                            // Confirmar processamento
                            this.channel.ack(message);
                            logger.info(`✅ Mensagem processada: ${messageInfo.messageId}`);

                        } catch (error) {
                            logger.error(`❌ Erro ao processar mensagem ${message.properties.messageId}:`, error);
                            
                            // Rejeitar mensagem (vai para DLQ se configurado)
                            this.channel.nack(message, false, false);
                        }
                    }
                },
                { ...defaultOptions, ...options }
            );

            logger.info(`👂 Escutando fila: ${queueName}`);

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
        return this.connection && !this.connection.connection.serverProperties;
    }
}

// Singleton instance
const rabbitmqConfig = new RabbitMQConfig();
module.exports = rabbitmqConfig;