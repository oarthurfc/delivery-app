// controllers/notification.controller.js - COM SWAGGER
const express = require('express');
const router = express.Router();
const notificationService = require('../services/notification.service');
const emailQueueListener = require('../listeners/email-queue-listener');
const pushQueueListener = require('../listeners/push-queue-listener');
const dependencyContainer = require('../utils/dependency-injection');
const rabbitmqConfig = require('../config/rabbitmq');
const logger = require('../utils/logger');

/**
 * @swagger
 * /health:
 *   get:
 *     tags: [⚕️ Sistema]
 *     summary: Health check completo do serviço
 *     description: |
 *       Verifica a saúde de todos os componentes do notification service:
 *       - ✅ Conectividade com RabbitMQ
 *       - ✅ Status dos listeners das filas
 *       - ✅ Conectividade dos provedores (email/push)
 *       - ✅ Estatísticas de processamento
 *     responses:
 *       200:
 *         description: Status de saúde do serviço
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/HealthResponse'
 *             example:
 *               status: "healthy"
 *               timestamp: "2024-01-15T10:30:00.000Z"
 *               services:
 *                 email:
 *                   success: true
 *                   provider: "local-email-provider"
 *                 push:
 *                   success: true  
 *                   provider: "local-push-provider"
 *               listeners:
 *                 email:
 *                   isRunning: true
 *                   queueName: "emails"
 *                 push:
 *                   isRunning: true
 *                   queueName: "push-notifications"
 *               rabbitmq:
 *                 connected: true
 *       500:
 *         $ref: '#/components/responses/ErrorResponse'
 */
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

/**
 * @swagger
 * /api/notifications/test/email:
 *   post:
 *     tags: [📧 Email]
 *     summary: Teste direto de envio de email (sem fila)
 *     description: |
 *       Envia um email diretamente usando o provedor configurado, sem passar pela fila RabbitMQ.
 *       
 *       **💡 Dica**: Use este endpoint para testes rápidos. Para uso em produção, prefira `/queue/email`.
 *       
 *       **🎨 Templates Automáticos**: Se `subject` ou `body` não forem informados, 
 *       o sistema usa templates baseados no `type`:
 *       - `welcome` → "Bem-vindo!"
 *       - `order_created` → "Pedido #{{orderId}} criado!"
 *       - `order_completed` → "Pedido #{{orderId}} finalizado!"
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               to:
 *                 type: string
 *                 format: email
 *                 description: Email do destinatário
 *                 example: "cliente@example.com"
 *               type:
 *                 type: string
 *                 enum: [welcome, order_created, order_completed, promotional]
 *                 default: "welcome"
 *                 description: Tipo do email (define template automático)
 *               subject:
 *                 type: string
 *                 description: Assunto (opcional, usa template se não informado)
 *                 example: "Bem-vindo ao Delivery!"
 *               body:
 *                 type: string
 *                 description: Corpo do email (opcional, usa template se não informado)
 *                 example: "Obrigado por se cadastrar!"
 *               template:
 *                 type: string
 *                 description: Template específico a ser usado
 *                 example: "welcome"
 *               variables:
 *                 type: object
 *                 description: Variáveis para substituição no template
 *                 example:
 *                   customerName: "João Silva"
 *                   orderId: 123
 *           examples:
 *             welcome:
 *               summary: Email de boas-vindas
 *               value:
 *                 to: "joao@example.com"
 *                 type: "welcome"
 *                 variables:
 *                   customerName: "João Silva"
 *             order_completed:
 *               summary: Pedido finalizado
 *               value:
 *                 to: "cliente@example.com"
 *                 type: "order_completed"
 *                 variables:
 *                   orderId: 123
 *                   customerName: "Maria Santos"
 *     responses:
 *       200:
 *         description: Email processado com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "Email de teste processado"
 *                 result:
 *                   type: object
 *                   description: Resultado do processamento
 *                 testData:
 *                   type: object
 *                   description: Dados que foram enviados
 *       500:
 *         $ref: '#/components/responses/ErrorResponse'
 */
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

/**
 * @swagger
 * /api/notifications/test/push:
 *   post:
 *     tags: [🔔 Push]
 *     summary: Teste direto de push notification (sem fila) - REFATORADO
 *     description: |
 *       **🔄 REFATORADO**: Envia uma push notification diretamente, sem passar pela fila RabbitMQ.
 *       
 *       **🆕 Novo Formato**: Agora requer `fcmToken` para uso com Azure Functions.
 *       
 *       **💡 Dica**: Use este endpoint para testes rápidos. Para uso em produção, prefira `/queue/push`.
 *       
 *       **🎨 Templates Automáticos**: Se `title` ou `body` não forem informados, 
 *       o sistema usa templates baseados no `type`:
 *       - `welcome` → "Bem-vindo! 👋"
 *       - `order_created` → "Pedido criado! 📦"
 *       - `order_completed` → "Pedido entregue! ⭐"
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userId:
 *                 type: string
 *                 description: ID do usuário destinatário (opcional se tiver fcmToken)
 *                 example: "user123"
 *               fcmToken:
 *                 type: string
 *                 description: FCM Token do dispositivo (obrigatório para Azure)
 *                 example: "fnTJ06FQRxeXG-Bxp4eywu:APA91bG2cmCd9mx8..."
 *               type:
 *                 type: string
 *                 enum: [welcome, order_created, order_completed, evaluation_reminder, promotional]
 *                 default: "welcome"
 *                 description: Tipo da notificação
 *               title:
 *                 type: string
 *                 description: Título (opcional, usa template se não informado)
 *                 example: "Bem-vindo! 👋"
 *               body:
 *                 type: string
 *                 description: Corpo (opcional, usa template se não informado)
 *                 example: "Obrigado por se cadastrar!"
 *               data:
 *                 type: object
 *                 description: Dados adicionais da notificação
 *                 example:
 *                   action: "OPEN_PROFILE"
 *                   orderId: 123
 *               variables:
 *                 type: object
 *                 description: Variáveis para substituição no template
 *                 example:
 *                   customerName: "João Silva"
 *                   orderId: 123
 *           examples:
 *             welcome:
 *               summary: Boas-vindas
 *               value:
 *                 userId: "user123"
 *                 fcmToken: "fnTJ06FQRxeXG-Bxp4eywu:APA91bG2cmCd9mx8_h93kH3QlyaPLmbUkk1sBxdsbWl-dCWyUrbN-8BQfAdayAeH"
 *                 type: "welcome"
 *                 variables:
 *                   customerName: "João Silva"
 *             order_completed:
 *               summary: Pedido finalizado
 *               value:
 *                 userId: "user456"
 *                 fcmToken: "dGhpc0lzQVRlc3RUb2tlbkZvckZDTQ:APA91bHabc123def456ghi789"
 *                 type: "order_completed"
 *                 variables:
 *                   orderId: 123
 *                   customerName: "Maria Santos"
 *     responses:
 *       200:
 *         description: Push notification processada com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "Push notification de teste processada"
 *                 result:
 *                   type: object
 *                   description: Resultado do processamento
 *                 testData:
 *                   type: object
 *                   description: Dados que foram enviados
 *       400:
 *         description: Dados inválidos
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 error:
 *                   type: string
 *                   example: "fcmToken ou userId é obrigatório"
 *       500:
 *         $ref: '#/components/responses/ErrorResponse'
 */
router.post('/test/push', async (req, res) => {
    try {
        const { 
            userId,
            fcmToken,
            type = 'welcome',
            title,
            body,
            data = { test: true },
            variables = {}
        } = req.body;
        
        // Validar se tem pelo menos fcmToken ou userId
        if (!fcmToken && !userId) {
            return res.status(400).json({
                success: false,
                error: 'fcmToken ou userId é obrigatório'
            });
        }
        
        const testPushData = {
            messageId: `test_push_${Date.now()}`,
            userId: userId || 'test-user',
            fcmToken: fcmToken || `test_fcm_token_${Date.now()}`,
            type,
            title,
            body,
            data,
            variables,
            timestamp: new Date().toISOString()
        };

        const result = await notificationService.processNotification('push', testPushData);

        res.json({
            success: true,
            message: 'Push notification de teste processada (refatorado)',
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

/**
 * @swagger
 * /api/notifications/queue/email:
 *   post:
 *     tags: [📬 Filas]
 *     summary: Publicar mensagem na fila de emails
 *     description: |
 *       **🚀 Método Recomendado**: Publica uma mensagem na fila `emails` do RabbitMQ 
 *       para processamento assíncrono.
 *       
 *       **⚡ Vantagens**:
 *       - Processamento assíncrono e resiliente
 *       - Dead Letter Queue para tratamento de falhas
 *       - Retry automático em caso de problemas temporários
 *       - Melhor performance para alto volume
 *       
 *       **🎨 Sistema de Templates**: O serviço possui templates automáticos baseados no `type`:
 *       
 *       | Tipo | Template | Exemplo |
 *       |------|----------|---------|
 *       | `order_created` | "Pedido #{{orderId}} criado!" | Confirmação de pedido |
 *       | `order_completed` | "Pedido #{{orderId}} finalizado!" | Entrega concluída |
 *       | `welcome` | "Bem-vindo!" | Novo usuário |
 *       | `promotional` | "{{title}}" | Campanhas |
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/EmailMessage'
 *           examples:
 *             order_created:
 *               summary: 📦 Pedido Criado
 *               description: Email automático quando um novo pedido é criado
 *               value:
 *                 to: "cliente@example.com"
 *                 type: "order_created"
 *                 variables:
 *                   orderId: 123
 *                   customerName: "João Silva"
 *                   estimatedTime: "30 minutos"
 *             order_completed:
 *               summary: ✅ Pedido Finalizado
 *               description: Email de confirmação de entrega
 *               value:
 *                 to: "cliente@example.com"
 *                 type: "order_completed"
 *                 variables:
 *                   orderId: 123
 *                   customerName: "Maria Santos"
 *                   driverName: "Carlos"
 *             welcome:
 *               summary: 👋 Boas-vindas
 *               description: Email de boas-vindas para novos usuários
 *               value:
 *                 to: "novousuario@example.com"
 *                 type: "welcome"
 *                 variables:
 *                   customerName: "Ana Costa"
 *             promotional:
 *               summary: 🎯 Promocional
 *               description: Email de campanha promocional
 *               value:
 *                 to: "cliente@example.com"
 *                 type: "promotional"
 *                 subject: "🔥 Promoção Especial - 20% OFF"
 *                 body: "Aproveite nossa promoção especial!"
 *                 variables:
 *                   discountPercent: 20
 *                   validUntil: "31/01/2024"
 *     responses:
 *       200:
 *         description: Mensagem publicada na fila com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "Mensagem publicada na fila de emails"
 *                 messageId:
 *                   type: string
 *                   example: "queue_email_1642248600000"
 *                 queue:
 *                   type: string
 *                   example: "emails"
 *       400:
 *         description: Dados inválidos
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *             example:
 *               success: false
 *               error: 'Campo "to" é obrigatório'
 *       500:
 *         $ref: '#/components/responses/ErrorResponse'
 */
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

/**
 * @swagger
 * /api/notifications/queue/push:
 *   post:
 *     tags: [📬 Filas]
 *     summary: Publicar mensagem na fila de push notifications - REFATORADO
 *     description: |
 *       **🔄 REFATORADO**: Publica uma mensagem na fila `push-notifications` 
 *       do RabbitMQ para processamento assíncrono.
 *       
 *       **🆕 Novo Formato**: Agora suporta `fcmToken` para integração com Azure Functions.
 *       
 *       **⚡ Vantagens**:
 *       - Processamento assíncrono e resiliente
 *       - Dead Letter Queue para tratamento de falhas
 *       - Retry automático em caso de problemas temporários
 *       - Suporte a FCM tokens e dados customizados
 *       
 *       **📱 Templates Automáticos**: O serviço possui templates baseados no `type`:
 *       
 *       | Tipo | Template | Dados Extras |
 *       |------|----------|-------------|
 *       | `order_created` | "Pedido criado! 📦" | `action: TRACK_ORDER` |
 *       | `order_completed` | "Pedido entregue! ⭐" | `action: EVALUATE_ORDER` |
 *       | `evaluation_reminder` | "Avalie sua entrega! ⭐" | `action: EVALUATE_ORDER` |
 *       | `welcome` | "Bem-vindo! 👋" | `action: OPEN_HOME` |
 *       | `promotional` | "{{title}}" | `action: OPEN_PROMOTIONS` |
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userId:
 *                 type: string
 *                 description: ID do usuário destinatário (opcional se tiver fcmToken)
 *                 example: "user123"
 *               fcmToken:
 *                 type: string
 *                 description: FCM Token do dispositivo (recomendado para Azure)
 *                 example: "fnTJ06FQRxeXG-Bxp4eywu:APA91bG2cmCd9mx8..."
 *               type:
 *                 type: string
 *                 enum: [welcome, order_created, order_completed, evaluation_reminder, promotional]
 *                 description: Tipo da notificação
 *                 example: "order_completed"
 *               title:
 *                 type: string
 *                 description: Título (opcional, usa template se não informado)
 *                 example: "Pedido entregue!"
 *               body:
 *                 type: string
 *                 description: Corpo (opcional, usa template se não informado)
 *                 example: "Seu pedido foi finalizado com sucesso"
 *               data:
 *                 type: object
 *                 description: Dados adicionais da notificação
 *                 example:
 *                   orderId: 123
 *                   action: "EVALUATE_ORDER"
 *               variables:
 *                 type: object
 *                 description: Variáveis para substituição no template
 *                 example:
 *                   orderId: 123
 *                   customerName: "João Silva"
 *               priority:
 *                 type: string
 *                 enum: [low, normal, high]
 *                 default: normal
 *                 description: Prioridade da mensagem
 *           examples:
 *             order_completed:
 *               summary: ✅ Pedido Finalizado
 *               description: Notificação de entrega concluída
 *               value:
 *                 userId: "user456"
 *                 fcmToken: "fnTJ06FQRxeXG-Bxp4eywu:APA91bG2cmCd9mx8_h93kH3QlyaPLmbUkk1sBxdsbWl-dCWyUrbN-8BQfAdayAeH"
 *                 type: "order_completed"
 *                 variables:
 *                   orderId: 123
 *                   customerName: "Maria Santos"
 *             welcome_with_fcm:
 *               summary: 👋 Boas-vindas com FCM
 *               description: Boas-vindas para novos usuários
 *               value:
 *                 userId: "newuser789"
 *                 fcmToken: "dGhpc0lzQVRlc3RUb2tlbkZvckZDTQ:APA91bHabc123def456ghi789"
 *                 type: "welcome"
 *                 variables:
 *                   customerName: "Ana Costa"
 *     responses:
 *       200:
 *         description: Mensagem publicada na fila com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "Mensagem publicada na fila de push notifications (refatorado)"
 *                 messageId:
 *                   type: string
 *                   example: "queue_push_1642248600000"
 *                 queue:
 *                   type: string
 *                   example: "push-notifications"
 *       400:
 *         description: Dados inválidos
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 error:
 *                   type: string
 *                   example: 'fcmToken ou userId é obrigatório'
 *       500:
 *         $ref: '#/components/responses/ErrorResponse'
 */
router.post('/queue/push', async (req, res) => {
    try {
        const { 
            userId,
            fcmToken,
            type = 'welcome',
            title,
            body,
            data,
            variables,
            priority = 'normal'
        } = req.body;
        
        // Validar se tem pelo menos fcmToken ou userId
        if (!fcmToken && !userId) {
            return res.status(400).json({
                success: false,
                error: 'fcmToken ou userId é obrigatório'
            });
        }

        const pushMessage = {
            messageId: `queue_push_${Date.now()}`,
            userId,
            fcmToken,
            type,
            title,
            body,
            data: data || {},
            variables: variables || {},
            priority,
            timestamp: new Date().toISOString()
        };

        await rabbitmqConfig.publishPushMessage(pushMessage);

        res.json({
            success: true,
            message: 'Mensagem publicada na fila de push notifications (refatorado)',
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

/**
 * @swagger
 * /api/notifications/queue/push/broadcast:
 *   post:
 *     tags: [📬 Filas]
 *     summary: Publicar broadcast na fila de push notifications - NOVO
 *     description: |
 *       **🆕 NOVO ENDPOINT**: Publica uma mensagem de broadcast na fila `push-notifications` 
 *       para envio para múltiplos usuários.
 *       
 *       **📡 Funcionalidade de Broadcast**:
 *       - Envio para múltiplos usuários
 *       - Cada usuário pode ter seu próprio fcmToken
 *       - Dados customizados por usuário
 *       - Processamento assíncrono via fila
 *       
 *       **💡 Casos de Uso**:
 *       - Campanhas promocionais
 *       - Avisos gerais
 *       - Notificações de sistema
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *                 description: Título do broadcast
 *                 example: "🔥 Promoção Especial!"
 *               body:
 *                 type: string
 *                 description: Corpo do broadcast
 *                 example: "20% de desconto em todos os pedidos hoje!"
 *               data:
 *                 type: object
 *                 description: Dados compartilhados para todos
 *                 example:
 *                   campaign: "WEEKEND_SPECIAL"
 *                   discount: 20
 *               notifications:
 *                 type: array
 *                 description: Lista de usuários para receber o broadcast
 *                 items:
 *                   type: object
 *                   properties:
 *                     userId:
 *                       type: string
 *                       description: ID do usuário
 *                       example: "user123"
 *                     fcmToken:
 *                       type: string
 *                       description: FCM Token do usuário
 *                       example: "fnTJ06FQRxeXG-Bxp4eywu:APA91bG2cmCd9mx8..."
 *                     customData:
 *                       type: object
 *                       description: Dados específicos do usuário
 *                       example:
 *                         customerName: "João Silva"
 *               priority:
 *                 type: string
 *                 enum: [low, normal, high]
 *                 default: normal
 *           examples:
 *             promotional_broadcast:
 *               summary: 🎯 Broadcast Promocional
 *               value:
 *                 title: "🔥 Promoção Especial!"
 *                 body: "20% de desconto em todos os pedidos hoje!"
 *                 data:
 *                   campaign: "WEEKEND_SPECIAL"
 *                   discount: 20
 *                 notifications:
 *                   - userId: "user123"
 *                     fcmToken: "fnTJ06FQRxeXG-Bxp4eywu:APA91bG2cmCd9mx8_h93kH3QlyaPLmbUkk1sBxdsbWl-dCWyUrbN-8BQfAdayAeH"
 *                     customData:
 *                       customerName: "João Silva"
 *                   - userId: "user456"
 *                     fcmToken: "dGhpc0lzQVRlc3RUb2tlbkZvckZDTQ:APA91bHabc123def456ghi789"
 *                     customData:
 *                       customerName: "Maria Santos"
 *     responses:
 *       200:
 *         description: Broadcast publicado na fila com sucesso
 *       400:
 *         description: Dados inválidos
 *       500:
 *         $ref: '#/components/responses/ErrorResponse'
 */
router.post('/queue/push/broadcast', async (req, res) => {
    try {
        const { 
            title,
            body,
            data,
            notifications,
            priority = 'normal'
        } = req.body;
        
        // Validações
        if (!title || !body) {
            return res.status(400).json({
                success: false,
                error: 'title e body são obrigatórios para broadcasts'
            });
        }

        if (!notifications || !Array.isArray(notifications) || notifications.length === 0) {
            return res.status(400).json({
                success: false,
                error: 'notifications array é obrigatório e deve ter pelo menos um item'
            });
        }

        // Validar cada notificação
        for (let i = 0; i < notifications.length; i++) {
            const notification = notifications[i];
            if (!notification.fcmToken && !notification.userId) {
                return res.status(400).json({
                    success: false,
                    error: `Notificação ${i}: fcmToken ou userId é obrigatório`
                });
            }
        }

        const broadcastMessage = {
            messageId: `queue_broadcast_${Date.now()}`,
            type: 'broadcast',
            title,
            body,
            data: data || {},
            notifications,
            priority,
            timestamp: new Date().toISOString()
        };

        await rabbitmqConfig.publishMessage('notification.exchange', 'push.broadcast', broadcastMessage);

        res.json({
            success: true,
            message: 'Broadcast publicado na fila de push notifications',
            messageId: broadcastMessage.messageId,
            notificationCount: notifications.length,
            queue: 'push-notifications'
        });

    } catch (error) {
        logger.error('❌ Erro ao publicar broadcast na fila de push:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * @swagger
 * /api/notifications/queue/email/test:
 *   post:
 *     tags: [📬 Filas]
 *     summary: Publicar mensagem de teste na fila de emails
 *     description: |
 *       Publica uma mensagem de teste pré-configurada na fila de emails.
 *       Útil para testes rápidos do sistema de filas.
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               to:
 *                 type: string
 *                 format: email
 *                 description: Email destinatário (opcional)
 *                 example: "test@example.com"
 *               type:
 *                 type: string
 *                 description: Tipo do teste (opcional)
 *                 example: "welcome"
 *     responses:
 *       200:
 *         $ref: '#/components/responses/SuccessResponse'
 *       500:
 *         $ref: '#/components/responses/ErrorResponse'
 */
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

/**
 * @swagger
 * /api/notifications/queue/push/test:
 *   post:
 *     tags: [📬 Filas]
 *     summary: Publicar mensagem de teste na fila de push - REFATORADO
 *     description: |
 *       **🔄 REFATORADO**: Publica uma mensagem de teste pré-configurada na fila de push notifications.
 *       Agora inclui suporte a FCM tokens.
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userId:
 *                 type: string
 *                 description: ID do usuário (opcional)
 *                 example: "test-user"
 *               fcmToken:
 *                 type: string
 *                 description: FCM Token para teste (opcional)
 *                 example: "test_fcm_token_123"
 *               type:
 *                 type: string
 *                 description: Tipo do teste (opcional)
 *                 example: "welcome"
 *     responses:
 *       200:
 *         $ref: '#/components/responses/SuccessResponse'
 *       500:
 *         $ref: '#/components/responses/ErrorResponse'
 */
router.post('/queue/push/test', async (req, res) => {
    try {
        const testMessage = await pushQueueListener.publishTestMessage(req.body);
        
        res.json({
            success: true,
            message: 'Mensagem de teste publicada na fila de push (refatorado)',
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

/**
 * @swagger
 * /api/notifications/queue/push/test/broadcast:
 *   post:
 *     tags: [📬 Filas]
 *     summary: Publicar teste de broadcast na fila - NOVO
 *     description: |
 *       **🆕 NOVO ENDPOINT**: Publica uma mensagem de teste de broadcast 
 *       pré-configurada na fila de push notifications.
 *     responses:
 *       200:
 *         $ref: '#/components/responses/SuccessResponse'
 *       500:
 *         $ref: '#/components/responses/ErrorResponse'
 */
router.post('/queue/push/test/broadcast', async (req, res) => {
    try {
        const testMessage = await pushQueueListener.publishTestBroadcastMessage(req.body);
        
        res.json({
            success: true,
            message: 'Broadcast de teste publicado na fila de push',
            testMessage
        });

    } catch (error) {
        logger.error('❌ Erro ao publicar broadcast de teste na fila de push:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * @swagger
 * /api/notifications/providers/email/switch:
 *   post:
 *     tags: [⚙️ Provedores]
 *     summary: Trocar provedor de email em runtime
 *     description: |
 *       **🔄 Troca Dinâmica**: Alterna entre provedores de email sem necessidade 
 *       de reiniciar o serviço.
 *       
 *       **📋 Provedores Disponíveis**:
 *       - **`local`**: Simulação para desenvolvimento/testes
 *         - ✅ Não requer configuração externa
 *         - ✅ Logs detalhados do que seria enviado
 *         - ✅ Estatísticas completas
 *       
 *       - **`azure`**: Azure Functions para produção
 *         - ✅ Envio real de emails
 *         - ✅ Integração com Azure Functions
 *         - ⚙️ Requer `AZURE_FUNCTIONS_BASE_URL` e `AZURE_FUNCTIONS_API_KEY`
 *       
 *       **💡 Casos de Uso**:
 *       - Desenvolvimento → Produção
 *       - Testes A/B de provedores
 *       - Fallback em caso de problemas
 *       - Manutenção sem downtime
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ProviderSwitch'
 *           examples:
 *             to_azure:
 *               summary: 🔄 Trocar para Azure
 *               description: Ativar envio real via Azure Functions
 *               value:
 *                 provider: "azure"
 *             to_local:
 *               summary: 🔄 Trocar para Local
 *               description: Voltar para simulação local
 *               value:
 *                 provider: "local"
 *     responses:
 *       200:
 *         description: Provedor trocado com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "Email provider trocado para: azure"
 *                 newProvider:
 *                   type: string
 *                   example: "AzureEmailProvider"
 *       400:
 *         description: Provedor inválido
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *             example:
 *               success: false
 *               error: 'Provider deve ser "local" ou "azure"'
 *       500:
 *         $ref: '#/components/responses/ErrorResponse'
 */
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

/**
 * @swagger
 * /api/notifications/providers/push/switch:
 *   post:
 *     tags: [⚙️ Provedores]
 *     summary: Trocar provedor de push em runtime
 *     description: |
 *       **🔄 Troca Dinâmica**: Alterna entre provedores de push notifications 
 *       sem necessidade de reiniciar o serviço.
 *       
 *       **📋 Provedores Disponíveis**:
 *       - **`local`**: Simulação para desenvolvimento/testes
 *         - ✅ Não requer configuração externa
 *         - ✅ Logs detalhados do que seria enviado
 *         - ✅ Suporte a deep links e dados customizados
 *       
 *       - **`azure`**: Azure Functions para produção
 *         - ✅ Push notifications reais
 *         - ✅ Integração com Azure Functions
 *         - ⚙️ Requer configuração do Azure Functions
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ProviderSwitch'
 *     responses:
 *       200:
 *         description: Provedor trocado com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "Push provider trocado para: azure"
 *                 newProvider:
 *                   type: string
 *                   example: "AzurePushProvider"
 *       400:
 *         description: Provedor inválido
 *       500:
 *         $ref: '#/components/responses/ErrorResponse'
 */
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

/**
 * @swagger
 * /api/notifications/providers:
 *   get:
 *     tags: [⚙️ Provedores]
 *     summary: Obter informações dos provedores ativos
 *     description: |
 *       Retorna informações detalhadas sobre os provedores atualmente configurados,
 *       incluindo configurações e estatísticas de uso.
 *       
 *       **📊 Informações Incluídas**:
 *       - Nome e tipo do provedor
 *       - Configurações ativas
 *       - Estatísticas de envio
 *       - Tempo de atividade
 *       - Status de conectividade
 *     responses:
 *       200:
 *         description: Informações dos provedores
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 email:
 *                   type: object
 *                   properties:
 *                     name:
 *                       type: string
 *                       example: "LocalEmailProvider"
 *                     config:
 *                       type: object
 *                       example:
 *                         provider: "local-email-provider"
 *                         type: "local"
 *                         features: ["template-support", "variable-substitution"]
 *                     stats:
 *                       type: object
 *                       example:
 *                         sent: 150
 *                         errors: 2
 *                         uptime: 3600000
 *                 push:
 *                   type: object
 *                   properties:
 *                     name:
 *                       type: string
 *                       example: "LocalPushProvider"
 *                     config:
 *                       type: object
 *                       example:
 *                         provider: "local-push-provider"
 *                         type: "local"
 *                         features: ["single-notification", "broadcast", "deep-links"]
 *                     stats:
 *                       type: object
 *                       example:
 *                         sent: 75
 *                         broadcasts: 5
 *                         errors: 0
 *                         uptime: 3600000
 *       500:
 *         $ref: '#/components/responses/ErrorResponse'
 */
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

/**
 * @swagger
 * /api/notifications/providers/test:
 *   get:
 *     tags: [⚙️ Provedores]
 *     summary: Testar conectividade de todos os provedores
 *     description: |
 *       Executa testes de conectividade em todos os provedores configurados.
 *       
 *       **🧪 Testes Realizados**:
 *       - Conectividade com Azure Functions (se configurado)
 *       - Simulação de envio (providers locais)
 *       - Validação de configurações
 *       - Tempo de resposta
 *       
 *       **💡 Use este endpoint para**:
 *       - Verificar se Azure Functions está acessível
 *       - Validar configurações antes de trocar providers
 *       - Diagnóstico de problemas de conectividade
 *       - Monitoramento periódico
 *     responses:
 *       200:
 *         description: Resultados dos testes de conectividade
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 timestamp:
 *                   type: string
 *                   format: date-time
 *                   example: "2024-01-15T10:30:00.000Z"
 *                 email:
 *                   type: object
 *                   properties:
 *                     success:
 *                       type: boolean
 *                       example: true
 *                     provider:
 *                       type: string
 *                       example: "local-email-provider"
 *                     status:
 *                       type: string
 *                       example: "connected"
 *                     message:
 *                       type: string
 *                       example: "Provedor local funcionando corretamente"
 *                 push:
 *                   type: object
 *                   properties:
 *                     success:
 *                       type: boolean
 *                       example: true
 *                     provider:
 *                       type: string
 *                       example: "local-push-provider"
 *                     status:
 *                       type: string
 *                       example: "connected"
 *                 overall:
 *                   type: boolean
 *                   example: true
 *                   description: Status geral (true se todos os provedores estão funcionando)
 *       500:
 *         $ref: '#/components/responses/ErrorResponse'
 */
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

/**
 * @swagger
 * /api/notifications/stats:
 *   get:
 *     tags: [📊 Estatísticas]
 *     summary: Obter estatísticas detalhadas do serviço
 *     description: |
 *       Retorna métricas completas de performance e uso do notification service.
 *       
 *       **📈 Métricas Incluídas**:
 *       - Total de notificações processadas
 *       - Breakdown por tipo (email/push)
 *       - Taxa de erro e sucesso
 *       - Tempo de atividade (uptime)
 *       - Estatísticas por provedor
 *       - Performance dos sub-serviços
 *       
 *       **💡 Use para**:
 *       - Monitoramento de performance
 *       - Identificação de problemas
 *       - Relatórios de uso
 *       - Planejamento de capacidade
 *     responses:
 *       200:
 *         description: Estatísticas detalhadas do serviço
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 service:
 *                   type: string
 *                   example: "notification-service"
 *                 version:
 *                   type: string
 *                   example: "1.0.0"
 *                 uptime:
 *                   type: object
 *                   properties:
 *                     milliseconds:
 *                       type: number
 *                       example: 3600000
 *                     seconds:
 *                       type: number
 *                       example: 3600
 *                     minutes:
 *                       type: number
 *                       example: 60
 *                     hours:
 *                       type: number
 *                       example: 1
 *                 stats:
 *                   type: object
 *                   properties:
 *                     totalProcessed:
 *                       type: number
 *                       example: 1500
 *                       description: Total de notificações processadas
 *                     emailsProcessed:
 *                       type: number
 *                       example: 900
 *                       description: Emails processados
 *                     pushProcessed:
 *                       type: number
 *                       example: 600
 *                       description: Push notifications processadas
 *                     errors:
 *                       type: number
 *                       example: 15
 *                       description: Total de erros
 *                     startTime:
 *                       type: string
 *                       format: date-time
 *                       example: "2024-01-15T09:30:00.000Z"
 *                 subServices:
 *                   type: object
 *                   properties:
 *                     email:
 *                       type: object
 *                       properties:
 *                         service:
 *                           type: string
 *                           example: "email"
 *                         processed:
 *                           type: number
 *                           example: 900
 *                         errors:
 *                           type: number
 *                           example: 10
 *                         provider:
 *                           type: object
 *                           example:
 *                             sent: 890
 *                             errors: 10
 *                             uptime: 3600000
 *                     push:
 *                       type: object
 *                       properties:
 *                         service:
 *                           type: string
 *                           example: "push"
 *                         processed:
 *                           type: number
 *                           example: 600
 *                         errors:
 *                           type: number
 *                           example: 5
 *                 healthStatus:
 *                   type: object
 *                   properties:
 *                     overall:
 *                       type: boolean
 *                       example: true
 *                       description: Status geral de saúde (erro < 10%)
 *                     errorRate:
 *                       type: number
 *                       example: 0.01
 *                       description: Taxa de erro (0.01 = 1%)
 *       500:
 *         $ref: '#/components/responses/ErrorResponse'
 */
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

/**
 * @swagger
 * /api/notifications/stats/reset:
 *   post:
 *     tags: [📊 Estatísticas]
 *     summary: Resetar estatísticas do serviço
 *     description: |
 *       **⚠️ Ação Destrutiva**: Reseta todas as estatísticas do serviço para zero.
 *       
 *       **🔄 O que é resetado**:
 *       - Contadores de mensagens processadas
 *       - Contadores de erros
 *       - Estatísticas de tempo de atividade
 *       - Métricas dos provedores
 *       
 *       **💡 Use quando**:
 *       - Início de novo período de monitoramento
 *       - Após manutenção ou atualizações
 *       - Para limpar dados de teste
 *       - Debugging e troubleshooting
 *     responses:
 *       200:
 *         description: Estatísticas resetadas com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: "Estatísticas resetadas"
 *                 timestamp:
 *                   type: string
 *                   format: date-time
 *                   example: "2024-01-15T10:30:00.000Z"
 *       500:
 *         $ref: '#/components/responses/ErrorResponse'
 */
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

/**
 * @swagger
 * /api/notifications/rabbitmq/config:
 *   get:
 *     tags: [🐰 RabbitMQ]
 *     summary: Obter configuração das filas RabbitMQ
 *     description: |
 *       Retorna informações sobre a configuração atual do RabbitMQ,
 *       incluindo status de conexão e configuração das filas.
 *       
 *       **📋 Informações Incluídas**:
 *       - Status de conexão com RabbitMQ
 *       - Configuração dos exchanges
 *       - Configuração das filas (emails, push-notifications)
 *       - Bindings entre exchanges e filas
 *       - Configurações de Dead Letter Queue
 *       
 *       **💡 Use para**:
 *       - Verificar se RabbitMQ está conectado
 *       - Debugar problemas de filas
 *       - Validar configurações
 *       - Documentar arquitetura
 *     responses:
 *       200:
 *         description: Configuração do RabbitMQ
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 connected:
 *                   type: boolean
 *                   example: true
 *                   description: Status da conexão com RabbitMQ
 *                 config:
 *                   type: object
 *                   properties:
 *                     exchanges:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           name:
 *                             type: string
 *                             example: "notification.exchange"
 *                           type:
 *                             type: string
 *                             example: "topic"
 *                           options:
 *                             type: object
 *                             example:
 *                               durable: true
 *                     queues:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           name:
 *                             type: string
 *                             example: "emails"
 *                           options:
 *                             type: object
 *                             example:
 *                               durable: true
 *                               arguments:
 *                                 x-dead-letter-exchange: "notification.dlx"
 *                                 x-message-ttl: 3600000
 *                           bindings:
 *                             type: array
 *                             items:
 *                               type: object
 *                               properties:
 *                                 exchange:
 *                                   type: string
 *                                   example: "notification.exchange"
 *                                 routingKey:
 *                                   type: string
 *                                   example: "email"
 *       500:
 *         $ref: '#/components/responses/ErrorResponse'
 */
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