# 🚀 Sistema de Microsserviços para Delivery

Sistema completo de backend baseado em arquitetura de microsserviços para aplicação de delivery, desenvolvido como trabalho acadêmico.

## 🏗️ Arquitetura

O sistema é composto por 5 microsserviços independentes que se comunicam através de APIs REST e mensageria:

```
                    ┌─────────────────┐
                    │   Mobile App    │
                    │    (Flutter)    │
                    └─────────┬───────┘
                              │
                 ┌────────────▼────────────┐
                 │     🌐 API Gateway      │
                 │        (Spring)         │
                 └────────────┬────────────┘
                              │
     ┌────────────────────────┼────────────────────────┐
     │                        │                        │
┌────▼────────┐    ┌─────────▼────────┐    ┌─────────▼────────┐
│  🔐 Auth     │    │  📦 Orders       │    │  📍 Tracking     │
│  Service     │    │  Service         │    │  Service         │
│  (Node.js)   │    │  (Spring Boot)   │    │  (Node.js)       │
└─────┬───────┘    └─────────┬────────┘    └─────────┬────────┘
      │                      │                       │
      ▼                      ▼                       ▼
 ┌─────────┐           ┌──────────┐             ┌──────────┐
 │ MongoDB │           │PostgreSQL│             │PostgreSQL│
 │         │           │(Orders)  │             │(Tracking)│
 └─────────┘           └──────────┘             └──────────┘
      │                      │                       │
      └──────────────────────┼───────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   🐰 RabbitMQ   │
                    │ (Mensageria)    │
                    └────────┬────────┘
                             │
                  ┌──────────▼──────────┐
                  │ 🔔 Notification     │
                  │    Service          │
                  │    (Node.js)        │
                  └────────┬───────────┘
                           │
                  ┌────────▼────────┐
                  │ ⚡ Azure         │
                  │   Functions     │
                  │ (Serverless)    │
                  └────────────────┘

```

## 🛠️ Tecnologias Utilizadas

### **Microsserviços**
- **🔐 Auth Service**: Node.js + Express + MongoDB + JWT
- **📦 Order Service**: Spring Boot + PostgreSQL + JPA
- **📍 Tracking Service**: Node.js + Express + PostgreSQL + Swagger
- **🔔 Notification Service**: Node.js + Express + RabbitMQ + Azure Functions
- **🌐 API Gateway**: Spring Cloud Gateway

### **Infraestrutura**
- **🐳 Docker & Docker Compose**: Containerização e orquestração
- **🗄️ PostgreSQL**: Banco relacional para orders e tracking
- **🍃 MongoDB**: Banco NoSQL para autenticação
- **🐰 RabbitMQ**: Message broker para comunicação assíncrona
- **⚡ Azure Functions**: Processamento serverless para notificações

### **Documentação & Monitoramento**
- **📖 Swagger/OpenAPI**: Documentação interativa das APIs
- **🔍 Health Checks**: Monitoramento da saúde dos serviços
- **📊 Logs Centralizados**: Rastreamento de eventos

## 📋 Pré-requisitos

- **Docker Desktop** (versão 4.0+)
- **Git**
- **8GB RAM** (recomendado para rodar todos os serviços)

## 🚀 Instalação e Execução

### **Método 1: Setup Automático (Recomendado)**

#### Windows
```bash
git clone <url-do-repositorio>
cd delivery/backend
./setup-all.bat
```

#### Linux/Mac
```bash
git clone <url-do-repositorio>
cd delivery/backend
chmod +x setup-all.sh
./setup-all.sh
```

### **Método 2: Manual**

```bash
# 1. Clone o repositório
git clone <url-do-repositorio>
cd delivery/backend

# 2. Configure variáveis de ambiente
cp .env.example .env
# Edite o .env se necessário

# 3. Construa e execute todos os serviços
docker-compose up --build -d

# 4. Verifique o status
docker-compose ps
```

## 🌐 URLs dos Serviços

Após a execução bem-sucedida, os serviços estarão disponíveis em:

| Serviço | URL | Descrição |
|---------|-----|-----------|
| **🌐 API Gateway** | http://localhost:8000 | Ponto de entrada principal |
| **🔐 Auth Service** | http://localhost:3000 | Autenticação e autorização |
| **📦 Order Service** | http://localhost:8080 | Gerenciamento de pedidos |
| **📍 Tracking Service** | http://localhost:8081 | Rastreamento em tempo real |
| **🔔 Notification Service** | http://localhost:3001 | Gerenciamento de notificações |
| **📖 Tracking Docs** | http://localhost:8081/api/docs | Documentação Swagger |
| **🐰 RabbitMQ** | http://localhost:15672 | Management UI |

### **Bancos de Dados**
| Banco | Host | Porta | Usuário | Senha |
|-------|------|-------|---------|-------|
| **PostgreSQL (Orders)** | localhost | 5432 | delivery_user | delivery_pass |
| **PostgreSQL (Tracking)** | localhost | 5433 | root | root |
| **MongoDB** | localhost | 27017 | root | rootpassword |

## 📊 Estrutura do Projeto

```
backend/
├── 📁 auth-service/          # Microsserviço de Autenticação
│   ├── src/
│   ├── package.json
│   └── Dockerfile
├── 📁 order-service/         # Microsserviço de Pedidos  
│   ├── src/
│   ├── pom.xml
│   └── Dockerfile
├── 📁 tracking-service/      # Microsserviço de Rastreamento
│   ├── src/
│   ├── package.json
│   ├── README.md            # Documentação específica
│   └── Dockerfile
├── 📁 notification-service/  # Microsserviço de Notificações
│   ├── src/
│   ├── package.json
│   ├── README.md            # Documentação específica
│   └── Dockerfile
├── 📁 api-gateway/          # Gateway de APIs
│   ├── src/
│   ├── pom.xml
│   └── Dockerfile
├── 🐳 docker-compose.yml    # Orquestração dos serviços
├── 📝 .env.example          # Variáveis de ambiente
├── 🚀 setup-all.bat         # Script de setup (Windows)
├── 🚀 setup-all.sh          # Script de setup (Linux/Mac)
└── 📖 README.md             # Este arquivo
```

## 🧪 Testando o Sistema

### **1. Verificação Rápida**
```bash
# Health check de todos os serviços
curl http://localhost:3000/health  # Auth
curl http://localhost:8080/health  # Orders  
curl http://localhost:8081/api/tracking/health  # Tracking
curl http://localhost:3001/health  # Notification
curl http://localhost:8000/health  # Gateway
```

### **2. Teste do Tracking Service (Swagger)**
1. Acesse: http://localhost:8081/api/docs
2. Teste o endpoint `POST /api/tracking/location`:
```json
{
  "orderId": 123,
  "driverId": 1,
  "latitude": -19.9191,
  "longitude": -43.9386
}
```
3. Consulte a localização: `GET /api/tracking/order/123/current`

### **3. Teste via API Gateway**
```bash
# Teste através do gateway (porta 8000)
curl http://localhost:8000/api/tracking/health
curl http://localhost:8000/api/auth/health
curl http://localhost:8000/api/orders/health
curl http://localhost:8000/api/notifications/health
```

## 🔧 Comandos Úteis

### **Gerenciamento dos Serviços**
```bash
# Ver logs de todos os serviços
docker-compose logs -f

# Ver logs de um serviço específico
docker-compose logs -f tracking-service
docker-compose logs -f auth-service
docker-compose logs -f order-service
docker-compose logs -f notification-service

# Parar todos os serviços
docker-compose down

# Reiniciar um serviço específico
docker-compose restart tracking-service

# Reconstruir e reiniciar tudo
docker-compose down && docker-compose up --build -d

# Ver status dos containers
docker-compose ps

# Ver uso de recursos
docker stats
```

### **Acesso aos Bancos de Dados**
```bash
# PostgreSQL (Orders)
docker exec -it postgres psql -U delivery_user -d delivery_db

# PostgreSQL (Tracking)  
docker exec -it tracking_postgres psql -U root -d tracking_service

# MongoDB
docker exec -it mongodb mongosh -u root -p rootpassword
```

## 🐛 Solução de Problemas

### **Problemas Comuns**

#### **1. Porta já em uso**
```bash
# Ver o que está usando a porta
netstat -tulpn | grep :8000

# Parar processo específico
sudo kill -9 <PID>

# Ou mudar porta no .env
API_GATEWAY_PORT=8001
```

#### **2. Container não inicia**
```bash
# Ver logs detalhados
docker-compose logs [nome-do-serviço]

# Reconstruir imagem
docker-compose build --no-cache [nome-do-serviço]

# Verificar recursos disponíveis
docker system df
```

#### **3. Banco de dados não conecta**
```bash
# Verificar se container está rodando
docker-compose ps

# Aguardar health check
docker-compose logs postgres

# Testar conexão manualmente
docker exec -it postgres pg_isready
```

#### **4. Serviços não se comunicam**
```bash
# Verificar redes Docker
docker network ls
docker network inspect backend_frontend

# Testar conectividade entre containers
docker exec -it api-gateway ping tracking-service
```

### **Logs de Debug**
```bash
# Ver todos os logs com timestamps
docker-compose logs -f -t

# Filtrar logs por nível de erro
docker-compose logs | grep ERROR

# Salvar logs em arquivo
docker-compose logs > debug.log
```

## 📈 Características do Sistema

### **🔒 Segurança**
- ✅ Autenticação JWT compartilhada entre serviços
- ✅ Redes Docker isoladas (database, message_bus, frontend)
- ✅ Validação de dados nas APIs
- ✅ Sanitização de inputs

### **📊 Escalabilidade**
- ✅ Arquitetura de microsserviços independentes
- ✅ Comunicação assíncrona via RabbitMQ
- ✅ Bancos de dados específicos por domínio
- ✅ Load balancing via API Gateway

### **🔍 Observabilidade**
- ✅ Health checks em todos os serviços
- ✅ Logs estruturados e centralizados
- ✅ Documentação Swagger interativa
- ✅ Monitoramento de recursos

### **🚀 DevOps**
- ✅ Containerização completa com Docker
- ✅ Orquestração via Docker Compose
- ✅ Scripts de setup automatizados
- ✅ Configuração via variáveis de ambiente

## 🤝 Integração com Frontend

### **Endpoints Principais para Mobile/Web**

```javascript
// Configuração base
const API_BASE = 'http://localhost:8000';

// Autenticação
POST ${API_BASE}/api/auth/login
POST ${API_BASE}/api/auth/register

// Pedidos
GET    ${API_BASE}/api/orders
POST   ${API_BASE}/api/orders
GET    ${API_BASE}/api/orders/{id}

// Rastreamento
GET    ${API_BASE}/api/tracking/order/{id}/current
GET    ${API_BASE}/api/tracking/order/{id}/history
POST   ${API_BASE}/api/tracking/location

// Notificações
POST   ${API_BASE}/api/notifications/queue/email
POST   ${API_BASE}/api/notifications/queue/push
GET    ${API_BASE}/api/notifications/stats
```

### **Exemplo de Integração Flutter**
```dart
class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  
  // Rastreamento em tempo real
  Future<LocationData> getCurrentLocation(int orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tracking/order/$orderId/current'),
    );
    return LocationData.fromJson(json.decode(response.body));
  }
}
```

## 📝 Documentação dos Serviços

Cada microsserviço possui sua própria documentação detalhada:

- **📍 Tracking Service**: `./tracking-service/README.md`
- **🔐 Auth Service**: `./auth-service/README.md`
- **📦 Order Service**: `./order-service/README.md`
- **🔔 Notification Service**: `./notification-service/README.md`
- **🌐 API Gateway**: `./api-gateway/README.md`

## 📄 Licença

Este projeto foi desenvolvido para fins acadêmicos como parte do trabalho de **Laboratório de Desenvolvimento de Dispositivos Móveis e Distribuídos**.

---

