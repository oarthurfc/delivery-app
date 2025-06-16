// src/routes/tracking.js
const express = require('express');
const TrackingController = require('../controllers/trackingController');
// const { authenticateToken, requireDriverRole } = require('../middleware/auth'); // Comentado para remover autenticação

const router = express.Router();

/**
 * @swagger
 * /api/tracking/location:
 *   post:
 *     summary: Atualizar localização do motorista
 *     description: Permite que um motorista atualize sua localização GPS atual para um pedido específico
 *     tags: [Rastreamento]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             allOf:
 *               - $ref: '#/components/schemas/LocationUpdate'
 *               - type: object
 *                 properties:
 *                   driverId:
 *                     type: integer
 *                     description: ID do motorista (obrigatório quando sem autenticação)
 *           examples:
 *             example1:
 *               summary: Atualização básica de localização
 *               value:
 *                 orderId: 123
 *                 driverId: 1
 *                 latitude: -19.9191
 *                 longitude: -43.9386
 *             example2:
 *               summary: Atualização completa com todos os dados
 *               value:
 *                 orderId: 456
 *                 driverId: 1
 *                 latitude: -19.9191
 *                 longitude: -43.9386
 *                 accuracy: 10.5
 *                 speed: 45.2
 *                 heading: 180.0
 *     responses:
 *       201:
 *         description: Localização atualizada com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       $ref: '#/components/schemas/LocationPoint'
 *       400:
 *         description: Dados inválidos
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
router.post('/location', 
  // authenticateToken, 
  // requireDriverRole, 
  TrackingController.updateLocation
);

/**
 * @swagger
 * /api/tracking/driver/{driverId}/summary:
 *   get:
 *     summary: Obter resumo de rastreamento do motorista
 *     description: Retorna um resumo das entregas ativas de um motorista específico
 *     tags: [Motorista]
 *     parameters:
 *       - in: path
 *         name: driverId
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID do motorista
 *         example: 1
 *     responses:
 *       200:
 *         description: Resumo obtido com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         driverId:
 *                           type: integer
 *                         activeOrders:
 *                           type: integer
 *                         locations:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/LocationPoint'
 */
router.get('/driver/:driverId/summary', 
  // authenticateToken, 
  // requireDriverRole, 
  TrackingController.getDriverSummaryById
);

/**
 * @swagger
 * /api/tracking/order/{orderId}/current:
 *   get:
 *     summary: Obter localização atual do pedido
 *     description: Retorna a localização GPS mais recente de um pedido específico
 *     tags: [Consulta]
 *     parameters:
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID do pedido
 *         example: 123
 *     responses:
 *       200:
 *         description: Localização atual encontrada
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         currentLocation:
 *                           $ref: '#/components/schemas/LocationPoint'
 *       404:
 *         description: Nenhuma localização encontrada para este pedido
 *       400:
 *         description: ID do pedido inválido
 */
router.get('/order/:orderId/current', 
  // authenticateToken, 
  TrackingController.getCurrentLocation
);

/**
 * @swagger
 * /api/tracking/order/{orderId}/history:
 *   get:
 *     summary: Obter histórico de localização do pedido
 *     description: Retorna o histórico completo de localizações de um pedido com estatísticas
 *     tags: [Consulta]
 *     parameters:
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID do pedido
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 50
 *           minimum: 1
 *           maximum: 200
 *         description: Número máximo de pontos a retornar
 *       - in: query
 *         name: offset
 *         schema:
 *           type: integer
 *           default: 0
 *           minimum: 0
 *         description: Número de pontos a pular (paginação)
 *     responses:
 *       200:
 *         description: Histórico obtido com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         locationHistory:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/LocationPoint'
 *                         totalDistance:
 *                           type: number
 *                           description: Distância total percorrida em km
 *                         totalPoints:
 *                           type: integer
 *                           description: Número total de pontos no histórico
 *                         averageSpeed:
 *                           type: number
 *                           description: Velocidade média em km/h
 *       400:
 *         description: ID do pedido inválido
 */
router.get('/order/:orderId/history', 
  // authenticateToken, 
  TrackingController.getLocationHistory
);

/**
 * @swagger
 * /api/tracking/order/{orderId}/check:
 *   get:
 *     summary: Verificar se pedido está sendo rastreado
 *     description: Verifica se um pedido específico possui dados de rastreamento
 *     tags: [Consulta]
 *     parameters:
 *       - in: path
 *         name: orderId
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID do pedido
 *     responses:
 *       200:
 *         description: Status de rastreamento verificado
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         orderId:
 *                           type: integer
 *                         isBeingTracked:
 *                           type: boolean
 *       400:
 *         description: ID do pedido inválido
 */
router.get('/order/:orderId/check', 
  // authenticateToken, 
  TrackingController.checkOrderTracking
);

/**
 * @swagger
 * /api/tracking/nearby:
 *   get:
 *     summary: Encontrar entregas próximas
 *     description: Busca entregas em um raio específico de uma localização
 *     tags: [Geolocalização]
 *     parameters:
 *       - in: query
 *         name: latitude
 *         required: true
 *         schema:
 *           type: number
 *           format: double
 *           minimum: -90
 *           maximum: 90
 *         description: Latitude do ponto central
 *         example: -19.9191
 *       - in: query
 *         name: longitude
 *         required: true
 *         schema:
 *           type: number
 *           format: double
 *           minimum: -180
 *           maximum: 180
 *         description: Longitude do ponto central
 *         example: -43.9386
 *       - in: query
 *         name: radius
 *         schema:
 *           type: number
 *           default: 5
 *           minimum: 0.1
 *           maximum: 50
 *         description: Raio de busca em quilômetros
 *     responses:
 *       200:
 *         description: Entregas próximas encontradas
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         nearbyDeliveries:
 *                           type: array
 *                           items:
 *                             allOf:
 *                               - $ref: '#/components/schemas/LocationPoint'
 *                               - type: object
 *                                 properties:
 *                                   distance:
 *                                     type: number
 *                                     description: Distância em km do ponto central
 *                         searchCenter:
 *                           type: object
 *                           properties:
 *                             latitude:
 *                               type: number
 *                             longitude:
 *                               type: number
 *                         searchRadius:
 *                           type: number
 *                         totalFound:
 *                           type: integer
 *       400:
 *         description: Coordenadas inválidas
 */
router.get('/nearby', 
  // authenticateToken, 
  TrackingController.findNearbyDeliveries
);

/**
 * @swagger
 * /api/tracking/stats:
 *   get:
 *     summary: Obter estatísticas de rastreamento
 *     description: Retorna estatísticas gerais do sistema de rastreamento
 *     tags: [Estatísticas]
 *     parameters:
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Data inicial do período (YYYY-MM-DD)
 *         example: "2024-01-01"
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Data final do período (YYYY-MM-DD)
 *         example: "2024-12-31"
 *     responses:
 *       200:
 *         description: Estatísticas obtidas com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               allOf:
 *                 - $ref: '#/components/schemas/ApiResponse'
 *                 - type: object
 *                   properties:
 *                     data:
 *                       type: object
 *                       properties:
 *                         statistics:
 *                           $ref: '#/components/schemas/TrackingStatistics'
 */
router.get('/stats', 
  // authenticateToken, 
  TrackingController.getStatistics
);

/**
 * @swagger
 * /api/tracking/health:
 *   get:
 *     summary: Health check do serviço
 *     description: Verifica se o serviço de rastreamento está funcionando corretamente
 *     tags: [Sistema]
 *     responses:
 *       200:
 *         description: Serviço funcionando normalmente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   example: "OK"
 *                 service:
 *                   type: string
 *                   example: "Tracking Service"
 *                 timestamp:
 *                   type: string
 *                   format: date-time
 *                 stats:
 *                   type: object
 *                   properties:
 *                     totalPoints:
 *                       type: integer
 *                     trackedOrders:
 *                       type: integer
 *                     activeDrivers:
 *                       type: integer
 *       503:
 *         description: Serviço indisponível
 */
router.get('/health', TrackingController.healthCheck);

module.exports = router;