// controllers/notification.controller.js
const express = require('express');
const router = express.Router();
const notificationService = require('../services/notification.service');
const emailQueueListener = require('../listeners/email-queue.listener');
const pushQueueListener = require('../listeners/push-queue.listener');
const dependencyContainer = require('../utils/dependency-injection');
const rabbitmqConfig = require('../config/rabbitmq');
const logger = require('../utils/logger');

// Health check detalhado
router.get('/health', async (req, res) => {
    try {
        const healthData = await notificationService.testAllServices();
        const stats = notificationService.getDetailedStats();
        
        res.json({
            status: healthData.overall ? 'healthy' : 'unhealthy',
            timestamp: new Date().toISOString(),
            services: healthData,
            stats: stats,
            listeners: {
                email: emailQueueListener.getStats(),
                push: pushQueueListener.getStats()
            },
            rabbitmq: {
                connected: rabbitmqConfig.isConnected()
            },
            providers: dependencyContainer.getProvidersInfo()
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

// Testar envio de email direto (sem fila)
router.post('/test/email', async (req, res) => {
    try {
        const { 
            to = 'test@example.com', 
            type = 'welcome',
            subject = 'Email de Teste',
            body = 'Este é um email de teste.',
            template,
            variables = {}
        } = req.body;
        
        const testEmailData = {
            messageId: `test_email_${Date.now()}`,
            to,
            type,
            subject,
            body,
            template,
            variables,
            timestamp: new Date().toISOString()
        };

        const result = await notificationService.processNotification('email', testEmailData);

        res.json({
            success: true,
            message: 'Email de teste processado',
            result,
            testData: testEmailData
        });

    } catch (error) {
        logger.error('❌ Erro no teste de email:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Testar notificação push direta (sem fila)
router.post('/test/push', async (req, res) => {
    try {
        const { 
            userId = 'test-user-123',
            type = 'welcome',
            title = 'Notificação de Teste',
            body = 'Esta é uma notificação de teste.',
            data = { test: true },
            deepLink = 'app://home'
        } = req.body;
        
        const testPushData = {
            messageId: `test_push_${Date.now()}`,
            userId,
            type,
            title,
            body,
            data,
            deepLink,
            timestamp: new Date().toISOString()
        };

        const result = await notificationService.processNotification('push', testPushData);

        res.json({
            success: true,
            message: 'Push notification de teste processada',
            result,
            testData: testPushData
        });

    } catch (error) {
        logger.error('❌ Erro no teste de push:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Publicar mensagem na fila de emails
router.post('/queue/email', async (req, res) => {
    try {
        const { 
            to, 
            type = 'welcome',
            subject,
            body,
            template,
            variables,
            priority = 'normal'
        } = req.body;
        
        if (!to) {
            return res.status(400).json({
                success: false,
                error: 'Campo "to" é obrigatório'
            });
        }

        const emailMessage = {
            messageId: `queue_email_${Date.now()}`,
            to,
            type,
            subject,
            body,
            template,
            variables: variables || {},
            priority,
            timestamp: new Date().toISOString()
        };

        await rabbitmqConfig.publishEmailMessage(emailMessage);

        res.json({
            success: true,
            message: 'Mensagem publicada na fila de emails',
            messageId: emailMessage.messageId,
            queue: 'emails'
        });

    } catch (error) {
        logger.error('❌ Erro ao publicar na fila de emails:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Publicar mensagem na fila de push
router.post('/queue/push', async (req, res) => {
    try {
        const { 
            userId,
            type = 'welcome',
            title,
            body,
            data,
            deepLink,
            priority = 'normal'
        } = req.body;
        
        if (!userId) {
            return res.status(400).json({
                success: false,
                error: 'Campo "userId" é obrigatório'
            });
        }

        const pushMessage = {
            messageId: `queue_push_${Date.now()}`,
            userId,
            type,
            title,
            body,
            data: data || {},
            deepLink,
            priority,
            timestamp: new Date().toISOString()
        };

        await rabbitmqConfig.publishPushMessage(pushMessage);

        res.json({
            success: true,
            message: 'Mensagem publicada na fila de push notifications',
            messageId: pushMessage.messageId,
            queue: 'push-notifications'
        });

    } catch (error) {
        logger.error('❌ Erro ao publicar na fila de push:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Publicar mensagem de teste na fila de emails
router.post('/queue/email/test', async (req, res) => {
    try {
        const testMessage = await emailQueueListener.publishTestMessage(req.body);
        
        res.json({
            success: true,
            message: 'Mensagem de teste publicada na fila de emails',
            testMessage
        });

    } catch (error) {
        logger.error('❌ Erro ao publicar teste na fila de emails:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Publicar mensagem de teste na fila de push
router.post('/queue/push/test', async (req, res) => {
    try {
        const testMessage = await pushQueueListener.publishTestMessage(req.body);
        
        res.json({
            success: true,
            message: 'Mensagem de teste publicada na fila de push',
            testMessage
        });

    } catch (error) {
        logger.error('❌ Erro ao publicar teste na fila de push:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Trocar provedor de email em runtime
router.post('/providers/email/switch', async (req, res) => {
    try {
        const { provider } = req.body;
        
        if (!provider || !['local', 'azure'].includes(provider.toLowerCase())) {
            return res.status(400).json({
                success: false,
                error: 'Provider deve ser "local" ou "azure"'
            });
        }

        dependencyContainer.switchEmailProvider(provider);
        
        res.json({
            success: true,
            message: `Email provider trocado para: ${provider}`,
            newProvider: dependencyContainer.getEmailProvider().constructor.name
        });

    } catch (error) {
        logger.error('❌ Erro ao trocar email provider:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Trocar provedor de push em runtime
router.post('/providers/push/switch', async (req, res) => {
    try {
        const { provider } = req.body;
        
        if (!provider || !['local', 'azure'].includes(provider.toLowerCase())) {
            return res.status(400).json({
                success: false,
                error: 'Provider deve ser "local" ou "azure"'
            });
        }

        dependencyContainer.switchPushProvider(provider);
        
        res.json({
            success: true,
            message: `Push provider trocado para: ${provider}`,
            newProvider: dependencyContainer.getPushProvider().constructor.name
        });

    } catch (error) {
        logger.error('❌ Erro ao trocar push provider:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Obter informações dos provedores
router.get('/providers', (req, res) => {
    try {
        const providersInfo = dependencyContainer.getProvidersInfo();
        res.json(providersInfo);
    } catch (error) {
        logger.error('❌ Erro ao obter info dos provedores:', error);
        res.status(500).json({
            error: error.message
        });
    }
});

// Testar conectividade de todos os provedores
router.get('/providers/test', async (req, res) => {
    try {
        const testResults = await dependencyContainer.testAllProviders();
        res.json(testResults);
    } catch (error) {
        logger.error('❌ Erro no teste dos provedores:', error);
        res.status(500).json({
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

// Obter configuração das filas RabbitMQ
router.get('/rabbitmq/config', (req, res) => {
    try {
        const config = rabbitmqConfig.getQueueConfig();
        res.json({
            connected: rabbitmqConfig.isConnected(),
            config
        });
    } catch (error) {
        logger.error('❌ Erro ao obter config RabbitMQ:', error);
        res.status(500).json({
            error: error.message
        });
    }
});

module.exports = router;