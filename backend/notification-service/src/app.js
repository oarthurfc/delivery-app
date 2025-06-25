const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const logger = require('./utils/logger');
const rabbitmqConfig = require('./config/rabbitmq');
const dependencyContainer = require('./utils/dependency-injection');
const notificationController = require('./controllers/notification-controller');
const emailQueueListener = require('./listeners/email-queue-listener');
const pushQueueListener = require('./listeners/push-queue-listener');

// Swagger configuration
const swaggerConfig = require('./config/swagger');

class NotificationService {
    constructor() {
        this.app = express();
        this.port = process.env.PORT || 3001;
        this.isShuttingDown = false;
        
        this.setupDependencies();
        this.setupMiddlewares();
        this.setupSwagger();
        this.setupRoutes();
        this.setupGracefulShutdown();
    }

    setupDependencies() {
        // Inicializar container de dependências
        dependencyContainer.initialize();
        logger.info('📦 Dependências inicializadas');
    }

    setupMiddlewares() {
        // Configurar helmet com exceção para Swagger UI
        this.app.use(helmet({
            contentSecurityPolicy: {
                directives: {
                    defaultSrc: ["'self'"],
                    styleSrc: ["'self'", "'unsafe-inline'"],
                    scriptSrc: ["'self'", "'unsafe-inline'"],
                    imgSrc: ["'self'", "data:", "https:"],
                },
            },
        }));
        
        this.app.use(cors());
        this.app.use(morgan('combined', { 
            stream: { write: (message) => logger.info(message.trim()) }
        }));
        
        this.app.use(express.json({ limit: '10mb' }));
        this.app.use(express.urlencoded({ extended: true }));
    }

    setupSwagger() {
        // Configurar Swagger UI
        this.app.use('/api/docs', swaggerConfig.serve, swaggerConfig.setup);
        
        // Redirect para docs
        this.app.get('/docs', (req, res) => {
            res.redirect('/api/docs');
        });
        
        logger.info('📖 Swagger UI configurado em /api/docs');
    }

    setupRoutes() {
        // Health check básico
        this.app.get('/health', (req, res) => {
            res.json({
                status: 'healthy',
                service: 'notification-service',
                timestamp: new Date().toISOString(),
                uptime: process.uptime(),
                environment: process.env.NODE_ENV || 'development',
                providers: {
                    email: process.env.EMAIL_PROVIDER || 'local',
                    push: process.env.PUSH_PROVIDER || 'local'
                },
                docs: {
                    swagger: `${req.protocol}://${req.get('host')}/api/docs`,
                    healthDetailed: `${req.protocol}://${req.get('host')}/api/notifications/health`
                }
            });
        });

        // API routes
        this.app.use('/api/notifications', notificationController);

        // Rota de documentação rápida
        this.app.get('/', (req, res) => {
            res.json({
                service: '🔔 Notification Service',
                version: '1.0.0',
                description: 'Microsserviço de notificações com suporte a emails e push notifications',
                endpoints: {
                    documentation: `${req.protocol}://${req.get('host')}/api/docs`,
                    health: `${req.protocol}://${req.get('host')}/health`,
                    api: `${req.protocol}://${req.get('host')}/api/notifications`
                },
                features: [
                    '📧 Processamento de emails via fila',
                    '🔔 Push notifications via fila',
                    '🔄 Múltiplos provedores (local/azure)',
                    '🎨 Templates automáticos',
                    '📊 Monitoramento e estatísticas',
                    '⚙️ Troca de provedores em runtime'
                ],
                quickStart: {
                    testEmail: {
                        method: 'POST',
                        url: `${req.protocol}://${req.get('host')}/api/notifications/test/email`,
                        body: {
                            to: 'test@example.com',
                            type: 'welcome'
                        }
                    },
                    queueEmail: {
                        method: 'POST',
                        url: `${req.protocol}://${req.get('host')}/api/notifications/queue/email`,
                        body: {
                            to: 'cliente@example.com',
                            type: 'order_completed',
                            variables: { orderId: 123 }
                        }
                    }
                }
            });
        });

        // 404 handler
        this.app.use('*', (req, res) => {
            res.status(404).json({
                error: 'Route not found',
                path: req.originalUrl,
                method: req.method,
                availableEndpoints: {
                    documentation: '/api/docs',
                    health: '/health',
                    api: '/api/notifications'
                }
            });
        });

        // Error handler
        this.app.use((error, req, res, next) => {
            logger.error('Unhandled error:', error);
            res.status(500).json({
                error: 'Internal server error',
                message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong',
                timestamp: new Date().toISOString()
            });
        });
    }

    async setupRabbitMQ() {
        try {
            logger.info('🐰 Conectando ao RabbitMQ...');
            
            await rabbitmqConfig.connect();
            await rabbitmqConfig.setupQueuesAndExchanges();
            
            // Inicializar listeners das filas
            await emailQueueListener.start();
            await pushQueueListener.start();
            
            logger.info('✅ RabbitMQ configurado e listeners iniciados');
        } catch (error) {
            logger.error('❌ Erro ao configurar RabbitMQ:', error);
            throw error;
        }
    }

    setupGracefulShutdown() {
        const shutdown = async (signal) => {
            if (this.isShuttingDown) return;
            this.isShuttingDown = true;
            
            logger.info(`📴 Recebido signal ${signal}. Iniciando graceful shutdown...`);
            
            try {
                this.server.close(() => {
                    logger.info('🌐 Servidor HTTP fechado');
                });

                await emailQueueListener.stop();
                await pushQueueListener.stop();
                await rabbitmqConfig.disconnect();
                
                logger.info('✅ Graceful shutdown concluído');
                process.exit(0);
            } catch (error) {
                logger.error('❌ Erro durante shutdown:', error);
                process.exit(1);
            }
        };

        process.on('SIGTERM', () => shutdown('SIGTERM'));
        process.on('SIGINT', () => shutdown('SIGINT'));
        process.on('SIGUSR2', () => shutdown('SIGUSR2'));
    }

    async start() {
        try {
            await this.setupRabbitMQ();
            
            this.server = this.app.listen(this.port, () => {
                logger.info(`🚀 Notification Service iniciado na porta ${this.port}`);
                logger.info(`📍 Health check: http://localhost:${this.port}/health`);
                logger.info(`🔗 API base: http://localhost:${this.port}/api/notifications`);
                logger.info(`📖 Swagger UI: http://localhost:${this.port}/api/docs`);
                logger.info(`⚙️ Providers: Email=${process.env.EMAIL_PROVIDER || 'local'}, Push=${process.env.PUSH_PROVIDER || 'local'}`);
            });

        } catch (error) {
            logger.error('❌ Erro ao iniciar serviço:', error);
            process.exit(1);
        }
    }
}

const service = new NotificationService();
service.start().catch(error => {
    logger.error('❌ Falha crítica na inicialização:', error);
    process.exit(1);
});

module.exports = service;