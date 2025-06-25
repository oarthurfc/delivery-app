![NodeJS](https://img.shields.io/badge/node.js-6DA55F?style=for-the-badge&logo=node.js&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![RabbitMQ](https://img.shields.io/badge/Rabbitmq-FF6600?style=for-the-badge&logo=rabbitmq&logoColor=white)
![Azure](https://img.shields.io/badge/azure-%230072C6.svg?style=for-the-badge&logo=microsoftazure&logoColor=white)

# 🔔 Microsserviço de Notificações

Microsserviço responsável pelo envio de notificações (emails e push notifications) através de filas RabbitMQ, desenvolvido em Node.js com arquitetura desacoplada e suporte a múltiplos provedores.

## 🚀 Funcionalidades

- ✅ **Processamento via Filas**: Consome mensagens das filas `emails` e `push-notifications`
- ✅ **Múltiplos Provedores**: Suporte a implementações locais e Azure Functions
- ✅ **Troca em Runtime**: Alternar entre provedores sem reiniciar o serviço
- ✅ **Templates Automáticos**: Sistema de templates baseado no tipo de notificação
- ✅ **Dead Letter Queue**: Tratamento de mensagens com falha
- ✅ **Health Checks**: Monitoramento completo da saúde do serviço
- ✅ **API REST**: Interface para testes e gerenciamento
- ✅ **Logs Estruturados**: Sistema de logging detalhado
- ✅ **Graceful Shutdown**: Finalização limpa do serviço

## 🏗️ Arquitetura

```
┌─────────────────┐    ┌─────────────────┐
│   Order/Track   │    │   RabbitMQ      │
│   Services      │    │                 │
│                 │    │ ┌─────────────┐ │
│ Publicam msgs ──┼────┤ │   emails    │ │
│ nas filas       │    │ └─────────────┘ │
│                 │    │                 │
│                 │    │ ┌─────────────┐ │
│                 │    │ │push-notific.│ │
│                 │    │ └─────────────┘ │
└─────────────────┘    └─────────┬───────┘
                                 │
                       ┌─────────▼───────┐
                       │ Notification    │
                       │ Service         │
                       │                 │
                       │ ┌─────────────┐ │
                       │ │Email Queue  │ │
                       │ │Listener     │ │
                       │ └─────────────┘ │
                       │                 │
                       │ ┌─────────────┐ │
                       │ │Push Queue   │ │
                       │ │Listener     │ │
                       │ └─────────────┘ │
                       └─────────┬───────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
            ┌───────▼──────┐         ┌───────▼──────┐
            │ Email        │         │ Push         │
            │ Providers    │         │ Providers    │
            │              │         │              │
            │ • Local      │         │ • Local      │
            │ • Azure      │         │ • Azure      │
            └──────────────┘         └──────────────┘
```

## 🛠️ Tecnologias Utilizadas

- **Node.js** - Runtime JavaScript
- **Express.js** - Framework web
- **RabbitMQ** - Message broker (AMQP)
- **Azure Functions** - Provedores de notificação em nuvem
- **Docker** - Containerização
- **Winston** - Sistema de logging
- **Joi** - Validação de dados

## 📋 Pré-requisitos

- Docker Desktop
- Git
- RabbitMQ (incluído no docker-compose)

## 🚀 Como Executar

### Opção 1: Sistema Completo (Recomendado)

Execute o sistema completo de microsserviços da pasta `backend/`:

#### Windows
```bash
cd backend
./setup-all.bat
```

#### Linux/Mac
```bash
cd backend
chmod +x setup-all.sh
./setup-all.sh
```

### Opção 2: Apenas Notification Service

```bash
# 1. Ir para pasta backend
cd backend

# 2. Subir RabbitMQ primeiro
docker-compose up rabbitmq -d

# 3. Buildar e subir notification service
docker-compose up --build notification-service -d

# 4. Ver logs
docker-compose logs -f notification-service
```

## 📁 Estrutura do Projeto

```
notification-service/
├── src/
│   ├── app.js                          # Aplicação principal
│   ├── config/
│   │   ├── rabbitmq.js                 # Configuração RabbitMQ
│   │   └── azure-functions.js          # Cliente Azure Functions
│   ├── interfaces/
│   │   ├── email-provider.interface.js # Interface email
│   │   └── push-provider.interface.js  # Interface push
│   ├── providers/
│   │   ├── email/
│   │   │   ├── local-email.provider.js    # Implementação local
│   │   │   └── azure-email.provider.js    # Implementação Azure
│   │   └── push/
│   │       ├── local-push.provider.js     # Implementação local
│   │       └── azure-push.provider.js     # Implementação Azure
│   ├── services/
│   │   ├── email.service.js            # Lógica de negócio email
│   │   ├── push.service.js             # Lógica de negócio push
│   │   └── notification.service.js     # Orquestrador principal
│   ├── listeners/
│   │   ├── email-queue.listener.js     # Listener fila emails
│   │   └── push-queue.listener.js      # Listener fila push
│   ├── controllers/
│   │   └── notification.controller.js  # API REST
│   └── utils/
│       ├── logger.js                   # Sistema de logs
│       └── dependency-injection.js     # Container DI
├── logs/                               # Logs persistentes
├── package.json
├── Dockerfile
└── README.md
```

## 📚 Documentação da API

### URLs Disponíveis

- **⚕️ Health Check**: http://localhost:3001/health
- **🔗 API Base**: http://localhost:3001/api/notifications
- **🐰 RabbitMQ Management**: http://localhost:15672

### Principais Endpoints

#### 1. Health Check Completo
```http
GET /health

Response:
{
  "status": "healthy",
  "services": {
    "email": { "success": true, "provider": "local-email-provider" },
    "push": { "success": true, "provider": "local-push-provider" }
  },
  "listeners": {
    "email": { "isRunning": true, "queueName": "emails" },
    "push": { "isRunning": true, "queueName": "push-notifications" }
  },
  "rabbitmq": { "connected": true },
  "providers": {
    "email": { "name": "LocalEmailProvider", "config": {...} },
    "push": { "name": "LocalPushProvider", "config": {...} }
  }
}
```

#### 2. Publicar Email na Fila
```http
POST /api/notifications/queue/email
Content-Type: application/json

{
  "to": "cliente@example.com",
  "type": "order_completed",
  "subject": "Pedido Finalizado!",
  "orderId": 123,
  "customerName": "João Silva"
}
```

#### 3. Publicar Push Notification na Fila
```http
POST /api/notifications/queue/push
Content-Type: application/json

{
  "userId": "user123",
  "type": "order_completed",
  "title": "Pedido entregue!",
  "body": "Seu pedido foi finalizado com sucesso",
  "orderId": 123
}
```

#### 4. Teste Direto de Email (sem fila)
```http
POST /api/notifications/test/email
Content-Type: application/json

{
  "to": "test@example.com",
  "type": "welcome",
  "subject": "Bem-vindo!"
}
```

#### 5. Teste Direto de Push (sem fila)
```http
POST /api/notifications/test/push
Content-Type: application/json

{
  "userId": "test-user",
  "type": "welcome",
  "title": "Bem-vindo!",
  "body": "Obrigado por se cadastrar"
}
```

#### 6. Trocar Provider de Email
```http
POST /api/notifications/providers/email/switch
Content-Type: application/json

{
  "provider": "azure"  # ou "local"
}
```

#### 7. Trocar Provider de Push
```http
POST /api/notifications/providers/push/switch
Content-Type: application/json

{
  "provider": "azure"  # ou "local"
}
```

#### 8. Estatísticas Detalhadas
```http
GET /api/notifications/stats

Response:
{
  "service": "notification-service",
  "uptime": 3600000,
  "stats": {
    "totalProcessed": 150,
    "emailsProcessed": 100,
    "pushProcessed": 50,
    "errors": 2
  },
  "subServices": {
    "email": { "service": "email", "sent": 98, "errors": 2 },
    "push": { "service": "push", "sent": 50, "errors": 0 }
  }
}
```

#### 9. Informações dos Provedores
```http
GET /api/notifications/providers

Response:
{
  "email": {
    "name": "LocalEmailProvider",
    "config": { "provider": "local-email-provider", "type": "local" },
    "stats": { "sent": 98, "errors": 2, "uptime": 3600000 }
  },
  "push": {
    "name": "LocalPushProvider", 
    "config": { "provider": "local-push-provider", "type": "local" },
    "stats": { "sent": 50, "errors": 0, "uptime": 3600000 }
  }
}
```

#### 10. Testar Conectividade dos Provedores
```http
GET /api/notifications/providers/test

Response:
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "email": { "success": true, "provider": "local-email-provider" },
  "push": { "success": true, "provider": "local-push-provider" },
  "overall": true
}
```

## 📊 Sistema de Filas RabbitMQ

### Filas Criadas Automaticamente

```
Exchanges:
├── notification.exchange (topic)    # Exchange principal
└── notification.dlx (direct)        # Dead Letter Exchange

Queues:
├── emails                           # Fila para emails
├── push-notifications               # Fila para push notifications
└── notification.dlq                 # Dead Letter Queue

Bindings:
├── emails ← notification.exchange (routing: 'email')
└── push-notifications ← notification.exchange (routing: 'push')
```

### Formato das Mensagens

#### Email
```json
{
  "messageId": "email_1234567890_abc123",
  "to": "cliente@example.com",
  "type": "order_completed",
  "subject": "Pedido #123 finalizado!",
  "body": "Seu pedido foi entregue com sucesso.",
  "template": "order-completed",
  "variables": {
    "orderId": 123,
    "customerName": "João Silva"
  },
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

#### Push Notification
```json
{
  "messageId": "push_1234567890_xyz789",
  "userId": "user123",
  "type": "order_completed",
  "title": "Pedido entregue! ⭐",
  "body": "Seu pedido foi finalizado. Que tal avaliar?",
  "data": {
    "orderId": 123,
    "action": "EVALUATE_ORDER"
  },
  "deepLink": "app://evaluate/123",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## 🎨 Sistema de Templates

### Templates de Email

```javascript
{
  'order_completed': {
    subject: 'Pedido #{{orderId}} finalizado!',
    body: 'Seu pedido #{{orderId}} foi entregue com sucesso.',
    template: 'order-completed'
  },
  'order_created': {
    subject: 'Pedido #{{orderId}} criado!', 
    body: 'Seu pedido #{{orderId}} foi criado e está sendo processado.',
    template: 'order-created'
  },
  'welcome': {
    subject: 'Bem-vindo!',
    body: 'Seja bem-vindo ao nosso serviço!',
    template: 'welcome'
  },
  'promotional': {
    subject: '{{title}}',
    body: '{{content}}',
    template: 'promotional-campaign'
  }
}
```

### Templates de Push Notification

```javascript
{
  'order_completed': {
    title: 'Pedido entregue! ⭐',
    body: 'Seu pedido #{{orderId}} foi finalizado. Que tal avaliar?',
    deepLink: 'app://evaluate/{{orderId}}'
  },
  'order_created': {
    title: 'Pedido criado! 📦',
    body: 'Seu pedido #{{orderId}} foi criado com sucesso.',
    deepLink: 'app://track/{{orderId}}'
  },
  'evaluation_reminder': {
    title: 'Avalie sua entrega! ⭐',
    body: 'Conte-nos como foi sua experiência com o pedido #{{orderId}}',
    deepLink: 'app://evaluate/{{orderId}}'
  },
  'promotional': {
    title: '{{title}}',
    body: '{{content}}',
    deepLink: 'app://promotions'
  }
}
```

## ⚙️ Configuração de Provedores

### Providers Locais (Desenvolvimento)

Os providers locais simulam o envio de notificações para desenvolvimento:

```bash
# No .env
EMAIL_PROVIDER=local
PUSH_PROVIDER=local
```

**Características:**
- ✅ Simula envio com delay realístico
- ✅ Logs detalhados do que seria enviado
- ✅ Taxa de falha configurável (2-3% para testes)
- ✅ Estatísticas completas
- ✅ Não requer configuração externa

### Providers Azure Functions (Produção)

Para usar Azure Functions reais em produção:

```bash
# No .env
EMAIL_PROVIDER=azure
PUSH_PROVIDER=azure
AZURE_FUNCTIONS_BASE_URL=https://delivery-communication-functions-bufjf4bdahecb6ey.brazilsouth-01.azurewebsites.net
AZURE_FUNCTIONS_API_KEY=5Dj_N_9Hl_3Va_YHDrjH4E3qIV7fOaq8bPCA41PHICnAAzFuslCZiQ==
```

**Características:**
- ✅ Envio real de emails via Azure Functions
- ✅ Autenticação via API Key
- ✅ Timeout configurável
- ✅ Retry automático em falhas
- ✅ Logs de execução detalhados

### Modo Híbrido

Você pode usar providers diferentes para cada tipo:

```bash
# No .env
EMAIL_PROVIDER=azure     # Emails reais via Azure
PUSH_PROVIDER=local      # Push simulado local
```

## 🧪 Testando o Serviço

### 1. Teste Básico - Health Check
```bash
curl http://localhost:3001/health
```

### 2. Teste de Email via Fila
```bash
curl -X POST http://localhost:3001/api/notifications/queue/email \
  -H "Content-Type: application/json" \
  -d '{
    "to": "cliente@example.com",
    "type": "order_completed",
    "orderId": 123,
    "customerName": "João Silva"
  }'
```

### 3. Teste de Push via Fila
```bash
curl -X POST http://localhost:3001/api/notifications/queue/push \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "type": "order_completed",
    "orderId": 123
  }'
```

### 4. Trocar para Azure Functions
```bash
curl -X POST http://localhost:3001/api/notifications/providers/email/switch \
  -H "Content-Type: application/json" \
  -d '{"provider": "azure"}'
```

### 5. Verificar Estatísticas
```bash
curl http://localhost:3001/api/notifications/stats
```

### 6. Testar via RabbitMQ Management UI

1. Acesse: http://localhost:15672
2. Login: `delivery_user` / `delivery_pass`
3. Vá em "Queues" e veja as filas: `emails`, `push-notifications`
4. Publique uma mensagem de teste na fila `emails`
5. Veja o processamento nos logs: `docker-compose logs -f notification-service`

## 🔧 Integração com Outros Microsserviços

### Order Service → Notification Service

No Order Service (Spring Boot), quando um pedido for criado/finalizado:

```java
@Component
public class OrderEventPublisher {
    
    @Autowired
    private RabbitTemplate rabbitTemplate;
    
    public void publishOrderCompleted(Order order) {
        // Email de finalização
        Map<String, Object> emailMessage = Map.of(
            "messageId", "order_completed_" + order.getId(),
            "to", order.getCustomerEmail(),
            "type", "order_completed",
            "orderId", order.getId(),
            "customerName", order.getCustomerName()
        );
        
        rabbitTemplate.convertAndSend("notification.exchange", "email", emailMessage);
        
        // Push de avaliação
        Map<String, Object> pushMessage = Map.of(
            "messageId", "push_evaluation_" + order.getId(),
            "userId", order.getCustomerId(),
            "type", "evaluation_reminder",
            "orderId", order.getId()
        );
        
        rabbitTemplate.convertAndSend("notification.exchange", "push", pushMessage);
    }
}
```

### Tracking Service → Notification Service

No Tracking Service (Node.js), quando o status mudar:

```javascript
const rabbitmqConfig = require('./config/rabbitmq');

async function notifyOrderDelivered(orderId, customerId, customerEmail) {
    // Email de finalização
    const emailMessage = {
        messageId: `order_completed_${orderId}`,
        to: customerEmail,
        type: 'order_completed',
        orderId: orderId,
        timestamp: new Date().toISOString()
    };
    
    await rabbitmqConfig.publishMessage('notification.exchange', 'email', emailMessage);
    
    // Push de avaliação
    const pushMessage = {
        messageId: `push_evaluation_${orderId}`,
        userId: customerId,
        type: 'evaluation_reminder',
        orderId: orderId,
        timestamp: new Date().toISOString()
    };
    
    await rabbitmqConfig.publishMessage('notification.exchange', 'push', pushMessage);
}
```

## 🔧 Comandos Úteis

```bash
# Ver logs em tempo real
docker-compose logs -f notification-service

# Ver logs do RabbitMQ
docker-compose logs -f rabbitmq

# Parar apenas notification service
docker-compose stop notification-service

# Reiniciar notification service
docker-compose restart notification-service

# Reconstruir do zero
docker-compose down && docker-compose up --build notification-service -d

# Verificar status dos containers
docker-compose ps

# Acessar container do notification service
docker exec -it notification_service sh

# Ver filas no RabbitMQ via CLI
docker exec -it rabbitmq rabbitmqctl list_queues

# Ver bindings no RabbitMQ
docker exec -it rabbitmq rabbitmqctl list_bindings
```

## 🐛 Troubleshooting

### Problemas Comuns:

#### 1. **Erro "RabbitMQ connection failed"**
```bash
# Verificar se RabbitMQ está rodando
docker-compose ps rabbitmq

# Ver logs do RabbitMQ
docker-compose logs rabbitmq

# Aguardar RabbitMQ estar pronto
docker-compose logs -f notification-service
```

#### 2. **Mensagens não são processadas**
```bash
# Verificar se filas foram criadas
curl http://localhost:15672/api/queues

# Ver mensagens na fila
# Acesse RabbitMQ Management: http://localhost:15672

# Verificar listeners
curl http://localhost:3001/health
```

#### 3. **Azure Functions não funciona**
```bash
# Verificar configuração
curl http://localhost:3001/api/notifications/providers

# Testar conectividade
curl http://localhost:3001/api/notifications/providers/test

# Verificar API key
# Teste direto: https://delivery-communication-functions-bufjf4bdahecb6ey.brazilsouth-01.azurewebsites.net/api/email-sender?code=SUA_CHAVE
```

#### 4. **Container não inicia**
```bash
# Ver logs detalhados
docker-compose logs notification-service

# Verificar se porta está disponível
netstat -tulpn | grep :3001

# Reconstruir imagem
docker-compose build --no-cache notification-service
```

#### 5. **Providers não trocam**
```bash
# Verificar se DI está funcionando
curl http://localhost:3001/api/notifications/providers

# Trocar via API
curl -X POST http://localhost:3001/api/notifications/providers/email/switch \
  -d '{"provider": "local"}'

# Reiniciar com novo provider no .env
# EMAIL_PROVIDER=azure
docker-compose restart notification-service
```

### Logs de Debug:
```bash
# Ver todos os logs com timestamps
docker-compose logs -f -t notification-service

# Filtrar logs por nível
docker-compose logs notification-service | grep ERROR
docker-compose logs notification-service | grep "✅"

# Salvar logs em arquivo
docker-compose logs notification-service > debug.log
```

## 📊 Monitoramento e Métricas

### Health Checks Automáticos

O serviço inclui health checks automáticos que verificam:
- ✅ Conexão com RabbitMQ
- ✅ Status dos listeners das filas
- ✅ Conectividade dos provedores
- ✅ Estatísticas de processamento
- ✅ Tempo de atividade (uptime)

### Métricas Disponíveis

```json
{
  "totalProcessed": 1500,      // Total de notificações processadas
  "emailsProcessed": 900,      // Emails processados
  "pushProcessed": 600,        // Push notifications processadas
  "errors": 15,                // Total de erros
  "errorRate": 0.01,           // Taxa de erro (1%)
  "uptime": 86400000,          // Tempo ativo em ms
  "providers": {
    "email": {
      "sent": 885,             // Emails enviados com sucesso
      "errors": 15,            // Erros de email
      "provider": "azure"      // Provedor atual
    },
    "push": {
      "sent": 600,             // Push enviados com sucesso
      "errors": 0,             // Erros de push
      "provider": "local"      // Provedor atual
    }
  }
}
```



## 📈 Características Técnicas

### **🔄 Arquitetura Desacoplada**
- **Interfaces bem definidas**: Fácil adição de novos provedores
- **Injeção de dependência**: Troca de implementações em runtime
- **Separação de responsabilidades**: Cada camada tem função específica

### **📊 Escalabilidade**
- **Processamento assíncrono**: Via filas RabbitMQ
- **Múltiplos workers**: Fácil horizontal scaling
- **Providers independentes**: Email e push podem escalar separadamente

### **🛡️ Confiabilidade**
- **Dead Letter Queues**: Tratamento de mensagens falhadas
- **Retry automático**: Reprocessamento em falhas temporárias
- **Graceful shutdown**: Finalização limpa sem perda de mensagens
- **Health checks**: Monitoramento contínuo da saúde

### **🔍 Observabilidade**
- **Logs estruturados**: Winston com níveis configuráveis
- **Métricas detalhadas**: Estatísticas por provedor e tipo
- **Tracing de mensagens**: Acompanhamento completo do fluxo
- **APIs de debug**: Endpoints para diagnóstico

### **🚀 DevOps Ready**
- **Containerizado**: Docker com multi-stage build
- **Configuração externa**: Via variáveis de ambiente
- **Health checks**: Para orchestradores (Kubernetes, etc.)
- **Logs persistentes**: Volume para armazenamento

---

**Desenvolvido como parte do sistema de microsserviços para delivery**