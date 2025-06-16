// src/config/swagger.js
const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Tracking Microservice API',
      version: '1.0.0',
      description: 'API para rastreamento em tempo real de entregas',
      contact: {
        name: 'Equipe de Desenvolvimento',
        email: 'dev@empresa.com'
      },
      license: {
        name: 'MIT',
        url: 'https://opensource.org/licenses/MIT'
      }
    },
    servers: [
      {
        url: process.env.API_URL || 'http://localhost:3003',
        description: 'Servidor de desenvolvimento'
      },
      {
        url: 'https://api.empresa.com',
        description: 'Servidor de produção'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Token JWT obtido do serviço de autenticação'
        }
      },
      schemas: {
        LocationPoint: {
          type: 'object',
          properties: {
            id: {
              type: 'integer',
              description: 'ID único do ponto de localização'
            },
            orderId: {
              type: 'integer',
              description: 'ID do pedido sendo rastreado'
            },
            driverId: {
              type: 'integer',
              description: 'ID do motorista'
            },
            latitude: {
              type: 'number',
              format: 'double',
              minimum: -90,
              maximum: 90,
              description: 'Latitude GPS'
            },
            longitude: {
              type: 'number',
              format: 'double',
              minimum: -180,
              maximum: 180,
              description: 'Longitude GPS'
            },
            createdAt: {
              type: 'string',
              format: 'date-time',
              description: 'Data e hora da localização'
            },
            accuracy: {
              type: 'number',
              format: 'double',
              description: 'Precisão do GPS em metros'
            },
            speed: {
              type: 'number',
              format: 'double',
              description: 'Velocidade em km/h'
            },
            heading: {
              type: 'number',
              format: 'double',
              minimum: 0,
              maximum: 360,
              description: 'Direção em graus (0-360)'
            }
          },
          required: ['id', 'orderId', 'driverId', 'latitude', 'longitude', 'createdAt']
        },
        LocationUpdate: {
          type: 'object',
          properties: {
            orderId: {
              type: 'integer',
              description: 'ID do pedido'
            },
            driverId: {
              type: 'integer',
              description: 'ID do motorista'
            },
            latitude: {
              type: 'number',
              format: 'double',
              minimum: -90,
              maximum: 90,
              description: 'Latitude GPS'
            },
            longitude: {
              type: 'number',
              format: 'double',
              minimum: -180,
              maximum: 180,
              description: 'Longitude GPS'
            },
            accuracy: {
              type: 'number',
              format: 'double',
              description: 'Precisão do GPS em metros'
            },
            speed: {
              type: 'number',
              format: 'double',
              description: 'Velocidade em km/h'
            },
            heading: {
              type: 'number',
              format: 'double',
              minimum: 0,
              maximum: 360,
              description: 'Direção em graus'
            }
          },
          required: ['orderId', 'driverId', 'latitude', 'longitude']
        },
        TrackingStatistics: {
          type: 'object',
          properties: {
            totalPoints: {
              type: 'integer',
              description: 'Total de pontos de localização registrados'
            },
            trackedOrders: {
              type: 'integer',
              description: 'Número de pedidos sendo rastreados'
            },
            activeDrivers: {
              type: 'integer',
              description: 'Número de motoristas ativos'
            },
            averageSpeed: {
              type: 'number',
              format: 'double',
              description: 'Velocidade média em km/h'
            },
            firstUpdate: {
              type: 'string',
              format: 'date-time',
              description: 'Data da primeira atualização'
            },
            lastUpdate: {
              type: 'string',
              format: 'date-time',
              description: 'Data da última atualização'
            }
          }
        },
        ApiResponse: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              description: 'Indica se a operação foi bem-sucedida'
            },
            message: {
              type: 'string',
              description: 'Mensagem de resposta'
            },
            data: {
              type: 'object',
              description: 'Dados da resposta'
            }
          }
        },
        ErrorResponse: {
          type: 'object',
          properties: {
            error: {
              type: 'string',
              description: 'Tipo do erro'
            },
            message: {
              type: 'string',
              description: 'Descrição detalhada do erro'
            }
          }
        }
      }
    },
    security: [] 
  },
  apis: ['./src/routes/*.js', './src/controllers/*.js'] // Caminhos para os arquivos com anotações
};

const specs = swaggerJsdoc(options);

module.exports = specs;