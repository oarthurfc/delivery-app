![Java](https://img.shields.io/badge/java-%23ED8B00.svg?style=for-the-badge&logo=openjdk&logoColor=white)
![Spring](https://img.shields.io/badge/spring-%236DB33F.svg?style=for-the-badge&logo=spring&logoColor=white)
# 🌐 API Gateway

Gateway de APIs do sistema de delivery, desenvolvido com Spring Cloud Gateway. Atua como ponto de entrada único para todos os microsserviços, fornecendo roteamento, autenticação, circuit breaker e outras funcionalidades transversais.

## 🚀 Tecnologias Utilizadas

- **Java 21** + **Spring Boot 3.5.0**
- **Spring Cloud Gateway** para roteamento
- **Spring WebFlux** (programação reativa)
- **Resilience4j** para circuit breaker e retry
- **JWT** para validação de tokens
- **CORS** configurado globalmente

## 📋 Funcionalidades

- ✅ **Roteamento inteligente** para microsserviços
- ✅ **Autenticação JWT** centralizada
- ✅ **Circuit Breaker** para tolerância a falhas
- ✅ **Retry automático** em caso de falha
- ✅ **CORS** configurado globalmente
- ✅ **Fallback controllers** para alta disponibilidade
- ✅ **Timeout configurável** por rota
- ✅ **Logs detalhados** para debugging

## 🏗️ Estrutura do Projeto

```
api-gateway/
├── src/main/java/com/example/gateway/
│   ├── config/
│   │   ├── RouteConfiguration.java        # Configuração das rotas
│   │   ├── CorsConfig.java               # Configuração CORS
│   │   └── CircuitBreakerConfiguration.java # Configuração do circuit breaker
│   ├── controller/
│   │   ├── FallbackController.java      # Controllers de fallback
│   │   ├── CircuitBreakerController.java # Controller do circuit breaker
│   │   └── CircuitBreakerTestController.java # Testes do circuit breaker
│   ├── filter/
│   │   └── JwtAuthFilter.java         # Filtro de autenticação
│   └── GatewayApplication.java
├── src/main/resources/
│   └── application.yml                # Configurações
├── pom.xml
├── Dockerfile
└── README.md
```

## 🌐 Roteamento de APIs

### Rotas Configuradas

| Rota Original | Destino | Serviço |
|---------------|---------|---------|
| `/api/auth/**` | `http://auth-service:3000/auth/**` | Auth Service |
| `/api/orders/**` | `http://order-service:8080/orders/**` | Order Service |
| `/api/tracking/**` | `http://tracking-service:8081/api/tracking/**` | Tracking Service |

### Exemplo de Uso
```bash
# Todas as requisições passam pelo gateway na porta 8000

# Auth Service (via gateway)
curl http://localhost:8000/api/auth/login

# Order Service (via gateway)  
curl http://localhost:8000/api/orders

# Tracking Service (via gateway)
curl http://localhost:8000/api/tracking/health
```

## 🔄 Fluxo de Requisições

```
1. Cliente → API Gateway (porta 8000)
2. Gateway → Validação JWT (se necessário)
3. Gateway → Circuit Breaker check
4. Gateway → Roteamento para microsserviço
5. Microsserviço → Processamento
6. Gateway ← Resposta do microsserviço
7. Cliente ← Resposta final
```

### Em Caso de Falha
```
1. Falha no microsserviço
2. Circuit Breaker ativado
3. Retry automático (se configurado)
4. Fallback response
5. Cliente recebe resposta de erro amigável
```

## 🔒 Autenticação

### Rotas Públicas (sem autenticação)
```http
POST /api/auth/login
POST /api/auth/register
```

### Rotas Protegidas
Todas as outras rotas requerem header `Authorization: Bearer <token>`

### Exemplo com Token
```bash
# 1. Obter token
TOKEN=$(curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"123456"}' \
  | jq -r '.token')

# 2. Usar token em requisições protegidas
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/api/orders
```

## ⚡ Circuit Breaker & Resilience

### Configuração por Serviço

#### Auth Service
- **Sliding Window**: 10 chamadas
- **Failure Rate**: 50%
- **Wait Duration**: 5 segundos
- **Timeout**: 3 segundos

#### Order Service
- **Retry**: 3 tentativas
- **Circuit Breaker**: Mesmas configurações do Auth
- **Fallback**: `/fallback/order`

#### Tracking Service
- **Retry**: 3 tentativas
- **Circuit Breaker**: Configuração padrão
- **Fallback**: `/fallback/tracking`

### Testando Circuit Breaker
```bash
# Simular falha do serviço (parar container)
docker-compose stop auth-service

# Testar fallback
curl http://localhost:8000/api/auth/login
# Retorna: {"status":"error","message":"Serviço de autenticação temporariamente indisponível..."}
```

## 🔧 Configuração

### Variáveis de Ambiente
```bash
AUTH_SERVICE_URL=http://auth-service:3000
ORDER_SERVICE_URL=http://order-service:8080
TRACKING_SERVICE_URL=http://tracking-service:8081
JWT_SECRET=ml2V8C#p9qK3&nX5^zA7@wR4tY6*hJ
```

### CORS Configuration
```yaml
spring:
  cloud:
    gateway:
      globalcors:
        cors-configurations:
          '[/**]':
            allowedOriginPatterns: "*"
            allowedMethods: [GET, POST, PUT, DELETE, OPTIONS]
            allowedHeaders: "*"
            allowCredentials: true
```

## 🚀 Executando o Gateway

### Via Docker Compose (Recomendado)
```bash
# No diretório backend/
docker-compose up api-gateway -d
```

### Desenvolvimento Local
```bash
cd api-gateway/gateway/
./mvnw spring-boot:run
```

### Build da Aplicação
```bash
./mvnw clean package -DskipTests
```

## 🧪 Testando

### Health Check dos Serviços
```bash
# Através do gateway
curl http://localhost:8000/api/auth/health     # ❌ Rota não existe no auth
curl http://localhost:8000/api/orders/ok       # ✅ Order service
curl http://localhost:8000/api/tracking/health # ✅ Tracking service

# Health do próprio gateway
curl http://localhost:8000/actuator/health     # Se habilitado
```

### Teste de Roteamento
```bash
# 1. Teste auth service
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123456"}'

# 2. Teste order service
curl http://localhost:8000/api/orders/ok

# 3. Teste tracking service  
curl http://localhost:8000/api/tracking/health
```

### Teste de Autenticação
```bash
# Requisição sem token (deve falhar)
curl http://localhost:8000/api/orders
# Esperado: 401 Unauthorized

# Requisição com token inválido
curl -H "Authorization: Bearer invalid-token" \
  http://localhost:8000/api/orders
# Esperado: 401 Unauthorized
```

## 📊 Monitoramento

### Logs
```bash
# Ver logs do gateway
docker-compose logs -f api-gateway

# Logs incluem:
# - Requisições recebidas
# - Roteamento para microsserviços
# - Falhas e circuit breaker ativado
# - Tentativas de retry
# - Validação JWT
```

### Métricas do Circuit Breaker
```bash
# Ver status dos circuit breakers
curl http://localhost:8000/actuator/circuitbreakers
# (Se actuator estiver habilitado)
```

## 🔧 Customização

### Adicionando Novo Serviço
1. **Adicionar rota** em `RouteConfiguration.java`
2. **Configurar circuit breaker** em `application.yml`
3. **Criar fallback** em `FallbackController.java`
4. **Atualizar variáveis** de ambiente

### Exemplo: Adicionando Notification Service
```java
// Em RouteConfiguration.java
.route("notification-service", r -> r
    .path("/api/notifications/**")
    .filters(f -> f
        .stripPrefix(1)
        .circuitBreaker(config -> config
            .setName("notificationCircuitBreaker")
            .setFallbackUri("forward:/fallback/notification")))
    .uri(notificationServiceUrl))
```

## 🐛 Troubleshooting

### Problemas Comuns

1. **504 Gateway Timeout**
   ```bash
   # Verificar se microsserviços estão rodando
   docker-compose ps
   # Verificar configuração de timeout
   ```

2. **401 Unauthorized** 
   ```bash
   # Verificar JWT_SECRET
   echo $JWT_SECRET
   # Deve ser igual ao do auth-service
   ```

3. **CORS Error**
   ```bash
   # Verificar configuração CORS em application.yml
   # Adicionar origem do frontend se necessário
   ```

4. **Circuit Breaker sempre aberto**
   ```bash
   # Verificar saúde dos microsserviços
   # Ajustar configuração de failure rate
   ```

---