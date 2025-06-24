const express = require('express');
const router = express.Router();
const notificationService = require('../services/notification.service');
const emailService = require('../services/email.service');
const pushService = require('../services/push.service');
const orderListener = require('../listeners/order.listener');
const campaignListener = require('../listeners/campaign.listener');
const rabbitmqConfig = require('../config/rabbitmq');
const logger = require('../utils/logger');

// Health check detalhado
router.get('/health', async (req, res) => {
    try {
        const healthData = await notificationService.testAllServices();
        const stats = notificationService.getDetailedStats();
        
        res.json({
            status: healthData.overallHealth ? 'healthy' : 'unhealthy',
            timestamp: new Date().toISOString(),
            services: healthData,
            stats: stats,
            listeners: {
                order: orderListener.getStats(),
                campaign: campaignListener.getStats()
            },
            rabbitmq: {
                connected: rabbitmqConfig.isConnected()
            }
        });
    } catch (error) {
        logger.error('❌ Erro no health check:', error);
        res.status(500).json({
            status: 'error',
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

// Testar envio de email direto
router.post('/test/email', async (req, res) => {
    try {
        const { type = 'order_completed', orderId = 999, customerId = 1, driverId = 2 } = req.body;
        
        const testOrderData = {
            eventId: `test-${Date.now()}`,
            eventType: type.toUpperCase(),
            timestamp: new Date().toISOString(),
            orderId,
            customerId,
            driverId,
            status: 'COMPLETED',
            description: 'Pedido de teste para email',
            originAddress: {
                street: 'Rua Teste',
                number: '123',
                city: 'Belo Horizonte'
            },
            destinationAddress: {
                street: 'Rua Destino',
                number: '456',
                city: 'Belo Horizonte'
            }
        };

        let result;
        if (type === 'order_completed') {
            result = await emailService.processOrderCompleted(testOrderData);
        } else {
            result = await emailService.processOrderCreated(testOrderData);
        }

        res.json({
            success: true,
            message: 'Email de teste enviado',
            result,
            testData: testOrderData
        });

    } catch (error) {
        logger.error('❌ Erro no teste de email:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Testar notificação push
router.post('/test/push', async (req, res) => {
    try {
        const { type = 'evaluation', orderId = 999, customerId = 1 } = req.body;
        
        const testOrderData = {
            orderId,
            customerId,
            status: 'COMPLETED'
        };

        let result;
        if (type === 'evaluation') {
            result = await pushService.sendEvaluationNotification(testOrderData);
        } else {
            result = await pushService.sendOrderCreatedNotification(testOrderData);
        }

        res.json({
            success: true,
            message: 'Notificação push de teste enviada',
            result,
            testData: testOrderData
        });

    } catch (error) {
        logger.error('❌ Erro no teste de push:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Simular evento de pedido finalizado
router.post('/test/order-completed', async (req, res) => {
    try {
        const { orderId = 999, customerId = 1, driverId = 2 } = req.body;
        
        const testEvent = {
            eventId: `test-completed-${Date.now()}`,
            eventType: 'ORDER_COMPLETED',
            timestamp: new Date().toISOString(),
            orderId,
            customerId,
            driverId,
            status: 'COMPLETED',
            description: 'Pedido de teste finalizado',
            originAddress: {
                street: 'Rua de Origem',
                number: '123',
                neighborhood: 'Centro',
                city: 'Belo Horizonte'
            },
            destinationAddress: {
                street: 'Rua de Destino',
                number: '456',
                neighborhood: 'Savassi',
                city: 'Belo Horizonte'
            }
        };

        const result = await notificationService.processOrderCompleted(testEvent);

        res.json({
            success: true,
            message: 'Evento de pedido finalizado processado',
            result,
            testEvent
        });

    } catch (error) {
        logger.error('❌ Erro no teste de pedido finalizado:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Simular campanha promocional
router.post('/test/campaign', async (req, res) => {
    try {
        const {
            title = 'Promoção de Teste',
            content = 'Aproveite 20% de desconto em todas as entregas!',
            targetSegment = 'all'
        } = req.body;
        
        const testCampaign = {
            campaignId: `test-campaign-${Date.now()}`,
            title,
            content,
            targetSegment,
            targetUsers: [
                { id: 1, email: 'cliente1@teste.com', name: 'João Silva' },
                { id: 2, email: 'cliente2@teste.com', name: 'Maria Santos' }
            ],
            deepLink: 'app://promotions',
            timestamp: new Date().toISOString()
        };

        const result = await notificationService.processPromotionalCampaign(testCampaign);

        res.json({
            success: true,
            message: 'Campanha promocional de teste processada',
            result,
            testCampaign
        });

    } catch (error) {
        logger.error('❌ Erro no teste de campanha:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Publicar evento manualmente no RabbitMQ
router.post('/publish/order-event', async (req, res) => {
    try {
        const { eventType, orderData } = req.body;
        
        if (!eventType || !orderData) {
            return res.status(400).json({
                success: false,
                error: 'eventType e orderData são obrigatórios'
            });
        }

        const routingKey = eventType === 'ORDER_COMPLETED' ? 'order.completed' : 'order.created';
        
        await rabbitmqConfig.publishMessage('order.exchange', routingKey, orderData);

        res.json({
            success: true,
            message: `Evento ${eventType} publicado no RabbitMQ`,
            routingKey,
            orderData
        });

    } catch (error) {
        logger.error('❌ Erro ao publicar evento:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Obter estatísticas detalhadas
router.get('/stats', (req, res) => {
    try {
        const stats = notificationService.getDetailedStats();
        res.json(stats);
    } catch (error) {
        logger.error('❌ Erro ao obter estatísticas:', error);
        res.status(500).json({
            error: error.message
        });
    }
});

// Resetar estatísticas
router.post('/stats/reset', (req, res) => {
    try {
        notificationService.resetStats();
        res.json({
            success: true,
            message: 'Estatísticas resetadas',
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        logger.error('❌ Erro ao resetar estatísticas:', error);
        res.status(500).json({
            error: error.message
        });
    }
});

module.exports = router;