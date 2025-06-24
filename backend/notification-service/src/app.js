const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const logger = require('./utils/logger');
const rabbitmqConfig = require('./config/rabbitmq');
const notificationController = require('./controllers/notification.controller');

// Importar listeners
const orderListener = require('./listeners/order.listener');
const campaignListener = require('./listeners/campaign.listener');

class NotificationService {
    constructor() {
        this.app = express();
        this.port = process.env.PORT || 3001;
        this.isShuttingDown = false;
        
        this.setupMiddlewares();
        this.setupRoutes();
        this.setupGracefulShutdown();
    }

    setupMiddlewares() {
        // Segurança e logs
        this.app.use(helmet());
        this.app.use(cors());
        this.app.use(morgan('combined', { 
            stream: { write: (message) => logger.info(message.trim()) }
        }));
        
        // Parse JSON
        this.app.use(express.json({ limit: '10mb' }));
        this.app.use(express.urlencoded({ extended: true }));
    }

    setupRoutes() {
        // Health check
        this.app.get('/health', (req, res) => {
            res.json({
                status: 'healthy',
                service: 'notification-service',
                timestamp: new Date().toISOString(),
                uptime: process.uptime(),
                environment: process.env.NODE_ENV || 'development'
            });
        });

        // API routes
        this.app.use('/api/notifications', notificationController);

        // 404 handler
        this.app.use('*', (req, res) => {
            res.status(404).json({
                error: 'Route not found',
                path: req.originalUrl,
                method: req.method
            });
        });

        // Error handler
        this.app.use((error, req, res, next) => {
            logger.error('Unhandled error:', error);
            res.status(500).json({
                error: 'Internal server error',
                message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
            });
        });
    }

    async setupRabbitMQ() {
        try {
            logger.info('🐰 Conectando ao RabbitMQ...');
            
            // Inicializar conexão RabbitMQ
            await rabbitmqConfig.connect();
            
            // Configurar filas e exchanges
            await rabbitmqConfig.setupQueuesAndExchanges();
            
            // Inicializar listeners
            await orderListener.start();
            await campaignListener.start();
            
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
                // Parar de aceitar novas conexões
                this.server.close(() => {
                    logger.info('🌐 Servidor HTTP fechado');
                });

                // Fechar conexões RabbitMQ
                await orderListener.stop();
                await campaignListener.stop();
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
        process.on('SIGUSR2', () => shutdown('SIGUSR2')); // nodemon restart
    }

    async start() {
        try {
            // Conectar ao RabbitMQ primeiro
            await this.setupRabbitMQ();
            
            // Iniciar servidor HTTP
            this.server = this.app.listen(this.port, () => {
                logger.info(`🚀 Notification Service iniciado na porta ${this.port}`);
                logger.info(`📍 Health check: http://localhost:${this.port}/health`);
                logger.info(`🔗 API base: http://localhost:${this.port}/api/notifications`);
            });

        } catch (error) {
            logger.error('❌ Erro ao iniciar serviço:', error);
            process.exit(1);
        }
    }
}

// Inicializar aplicação
const service = new NotificationService();
service.start().catch(error => {
    logger.error('❌ Falha crítica na inicialização:', error);
    process.exit(1);
});

module.exports = service;