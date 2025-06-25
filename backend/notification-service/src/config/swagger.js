// config/swagger.js
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Notification Service API',
      version: '1.0.0',
      description: `
# 🔔 Microsserviço de Notificações

Microsserviço responsável pelo envio de notificações (emails e push notifications) através de filas RabbitMQ.

## 🚀 Funcionalidades Principais

- **📧 Processamento de Emails**: Via fila \`emails\`
- **🔔 Push Notifications**: Via fila \`push-notifications\`
- **🔄 Múltiplos Provedores**: Local e Azure Functions
- **🎨 Templates Automáticos**: Baseados no tipo de notificação
- **📊 Monitoramento**: Health checks e estatísticas
- **⚙️ Configuração Dinâmica**: Troca de provedores em runtime

## 🏗️ Arquitetura

O serviço utiliza uma arquitetura baseada em filas (RabbitMQ) com provedores intercambiáveis:

\`\`\`
Order/Tracking Services → RabbitMQ → Notification Service → Providers (Local/Azure)
\`\`\`

## 🎯 Como Usar

1. **Envio via Fila (Recomendado)**: Use os endpoints \`/queue/*\` para publicar mensagens nas filas
2. **Teste Direto**: Use os endpoints \`/test/*\` para testar sem fila
3. **Troca de Providers**: Use \`/providers/*/switch\` para alternar entre local e Azure
4. **Monitoramento**: Use \`/health\` e \`/stats\` para acompanhar o status

## 📋 Tipos de Notificação Suportados

- \`order_created\` - Pedido criado
- \`order_completed\` - Pedido finalizado  
- \`evaluation_reminder\` - Lembrete de avaliação
- \`promotional\` - Campanhas promocionais
- \`welcome\` - Boas-vindas
      `,
      contact: {
        name: 'Delivery Team',
        email: 'dev@delivery.com'
      },
      license: {
        name: 'MIT',
        url: 'https://opensource.org/licenses/MIT'
      }
    },
    servers: [
      {
        url: 'http://localhost:3001',
        description: 'Ambiente de Desenvolvimento'
      },
      {
        url: 'http://localhost:8000/api/notifications',
        description: 'Via API Gateway'
      }
    ],
    tags: [
      {
        name: '⚕️ Sistema',
        description: 'Health checks e status do sistema'
      },
      {
        name: '📧 Email',
        description: 'Operações relacionadas a emails'
      },
      {
        name: '🔔 Push',
        description: 'Operações de push notifications'
      },
      {
        name: '📬 Filas',
        description: 'Publicação de mensagens nas filas RabbitMQ'
      },
      {
        name: '⚙️ Provedores',
        description: 'Gerenciamento e troca de provedores'
      },
      {
        name: '📊 Estatísticas',
        description: 'Métricas e relatórios do serviço'
      },
      {
        name: '🐰 RabbitMQ',
        description: 'Configurações e status do RabbitMQ'
      }
    ],
    components: {
      schemas: {
        // Schemas de request/response
        EmailMessage: {
          type: 'object',
          required: ['to', 'type'],
          properties: {
            to: {
              type: 'string',
              format: 'email',
              description: 'Email do destinatário',
              example: 'cliente@example.com'
            },
            type: {
              type: 'string',
              enum: ['order_created', 'order_completed', 'welcome', 'promotional'],
              description: 'Tipo da notificação (define template automático)',
              example: 'order_completed'
            },
            subject: {
              type: 'string',
              description: 'Assunto do email (opcional, usa template se não informado)',
              example: 'Pedido #123 finalizado!'
            },
            body: {
              type: 'string',
              description: 'Corpo do email (opcional, usa template se não informado)',
              example: 'Seu pedido foi entregue com sucesso.'
            },
            template: {
              type: 'string',
              description: 'Template específico a ser usado',
              example: 'order-completed'
            },
            variables: {
              type: 'object',
              description: 'Variáveis para substituição no template',
              example: {
                orderId: 123,
                customerName: 'João Silva'
              }
            },
            priority: {
              type: 'string',
              enum: ['low', 'normal', 'high'],
              default: 'normal',
              description: 'Prioridade da mensagem'
            }
          }
        },
        PushMessage: {
          type: 'object',
          required: ['userId', 'type'],
          properties: {
            userId: {
              type: 'string',
              description: 'ID do usuário destinatário',
              example: 'user123'
            },
            type: {
              type: 'string',
              enum: ['order_created', 'order_completed', 'evaluation_reminder', 'promotional', 'welcome'],
              description: 'Tipo da notificação',
              example: 'order_completed'
            },
            title: {
              type: 'string',
              description: 'Título da notificação (opcional, usa template se não informado)',
              example: 'Pedido entregue! ⭐'
            },
            body: {
              type: 'string',
              description: 'Corpo da notificação (opcional, usa template se não informado)',
              example: 'Seu pedido foi finalizado. Que tal avaliar?'
            },
            data: {
              type: 'object',
              description: 'Dados adicionais da notificação',
              example: {
                orderId: 123,
                action: 'EVALUATE_ORDER'
              }
            },
            deepLink: {
              type: 'string',
              description: 'Deep link da notificação',
              example: 'app://evaluate/123'
            },
            priority: {
              type: 'string',
              enum: ['low', 'normal', 'high'],
              default: 'normal',
              description: 'Prioridade da mensagem'
            }
          }
        },
        ProviderSwitch: {
          type: 'object',
          required: ['provider'],
          properties: {
            provider: {
              type: 'string',
              enum: ['local', 'azure'],
              description: 'Tipo de provedor para trocar',
              example: 'azure'
            }
          }
        },
        HealthResponse: {
          type: 'object',
          properties: {
            status: {
              type: 'string',
              enum: ['healthy', 'unhealthy'],
              example: 'healthy'
            },
            timestamp: {
              type: 'string',
              format: 'date-time',
              example: '2024-01-15T10:30:00.000Z'
            },
            services: {
              type: 'object',
              properties: {
                email: {
                  type: 'object',
                  properties: {
                    success: { type: 'boolean', example: true },
                    provider: { type: 'string', example: 'local-email-provider' }
                  }
                },
                push: {
                  type: 'object',
                  properties: {
                    success: { type: 'boolean', example: true },
                    provider: { type: 'string', example: 'local-push-provider' }
                  }
                }
              }
            },
            listeners: {
              type: 'object',
              properties: {
                email: {
                  type: 'object',
                  properties: {
                    isRunning: { type: 'boolean', example: true },
                    queueName: { type: 'string', example: 'emails' }
                  }
                },
                push: {
                  type: 'object',
                  properties: {
                    isRunning: { type: 'boolean', example: true },
                    queueName: { type: 'string', example: 'push-notifications' }
                  }
                }
              }
            },
            rabbitmq: {
              type: 'object',
              properties: {
                connected: { type: 'boolean', example: true }
              }
            }
          }
        },
        SuccessResponse: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: true
            },
            message: {
              type: 'string',
              example: 'Operação realizada com sucesso'
            },
            messageId: {
              type: 'string',
              example: 'queue_email_1234567890'
            }
          }
        },
        ErrorResponse: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: false
            },
            error: {
              type: 'string',
              example: 'Mensagem de erro descritiva'
            }
          }
        }
      },
      responses: {
        SuccessResponse: {
          description: 'Operação realizada com sucesso',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/SuccessResponse'
              }
            }
          }
        },
        ErrorResponse: {
          description: 'Erro na operação',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/ErrorResponse'
              }
            }
          }
        }
      }
    }
  },
  apis: ['./src/controllers/*.js'], // Caminho para os arquivos com anotações
};

const specs = swaggerJsdoc(options);

module.exports = {
  specs,
  swaggerUi,
  serve: swaggerUi.serve,
  setup: swaggerUi.setup(specs, {
    explorer: true,
    customCss: `
      .swagger-ui .topbar { display: none }
      .swagger-ui .info { margin: 20px 0 }
      .swagger-ui .scheme-container { margin: 20px 0 }
    `,
    customSiteTitle: '🔔 Notification Service API',
    customfavIcon: 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><text y=".9em" font-size="90">🔔</text></svg>'
  })
};