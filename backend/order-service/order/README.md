![Java](https://img.shields.io/badge/java-%23ED8B00.svg?style=for-the-badge&logo=openjdk&logoColor=white)
![Spring](https://img.shields.io/badge/spring-%236DB33F.svg?style=for-the-badge&logo=spring&logoColor=white)
![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)
# 📦 Order Service

Microsserviço de gerenciamento de pedidos do sistema de delivery, desenvolvido em Java 21 com Spring Boot. Responsável por criar, atualizar, consultar e gerenciar o ciclo de vida completo dos pedidos de entrega.

## 🚀 Tecnologias Utilizadas

- **Java 21** + **Spring Boot 3.5.0**
- **Spring Data JPA** para persistência
- **PostgreSQL** como banco de dados
- **Spring WebFlux** para programação reativa
- **Spring Validation** para validação de dados
- **Lombok** para redução de boilerplate
- **Azure Service Bus** para mensageria
- **Jackson** para serialização JSON

## 📋 Funcionalidades

- ✅ **CRUD completo** de pedidos
- ✅ **Paginação** de resultados
- ✅ **Consulta por motorista** com filtros
- ✅ **Finalização de pedidos** com comprovantes
- ✅ **Integração com Azure Service Bus** para eventos
- ✅ **Validação robusta** de dados
- ✅ **Health check** endpoint
- ✅ **Logs estruturados** com SLF4J

## 🏗️ Estrutura do Projeto

```
order-service/
├── src/main/java/com/service/order/
│   ├── config/            # Configurações do Spring
│   ├── controllers/        # REST Controllers
│   ├── dtos/              # Data Transfer Objects
│   ├── enums/             # Enumerações (OrderStatus, etc.)
│   ├── models/            # Entidades JPA
│   ├── repositories/      # Repositórios Spring Data
│   ├── services/          # Lógica de negócio
│   └── OrderApplication.java
├── src/main/resources/
│   └── application.properties    # Configurações
├── pom.xml
├── Dockerfile
└── README.md
```

## 🌐 Endpoints da API

### Pedidos
```http
GET    /orders              # Listar todos (paginado)
POST   /orders              # Criar novo pedido
GET    /orders/{id}         # Buscar por ID
PUT    /orders/{id}         # Atualizar pedido
DELETE /orders/{id}         # Deletar pedido
PUT    /orders/{id}/complete # Finalizar pedido

# Filtros específicos
GET    /orders/driver/{driverId}        # Pedidos do motorista
GET    /orders/driver/{driverId}/paged  # Pedidos do motorista (paginado)

# Sistema
GET    /orders/ok           # Health check
```

### Exemplos de Uso

#### Criar Pedido
```bash
curl -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": 1,
    "driverId": 2,
    "pickupAddress": "Rua A, 123",
    "deliveryAddress": "Rua B, 456",
    "description": "Entrega de documentos",
    "value": 25.50
  }'
```

#### Consultar Pedidos (Paginado)
```bash
curl "http://localhost:8080/orders?page=0&size=10&sort=createdAt,desc"
```

#### Finalizar Pedido
```bash
curl -X PUT http://localhost:8080/orders/1/complete \
  -H "Content-Type: application/json" \
  -d '{
    "deliveryPhoto": "base64-encoded-image",
    "deliveryNotes": "Entregue com sucesso"
  }'
```

#### Buscar Pedidos do Motorista
```bash
curl http://localhost:8080/orders/driver/2/paged?page=0&size=5
```

## 🗄️ Modelo de Dados

### Entidade Order
```java
@Entity
public class Order {
    private Long id;
    private Long customerId;
    private Long driverId;
    private String pickupAddress;
    private String deliveryAddress;
    private String description;
    private BigDecimal value;
    private OrderStatus status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private LocalDateTime completedAt;
    private String deliveryPhoto;
    private String deliveryNotes;
}
```

### Status dos Pedidos
- `PENDING` - Aguardando aceite
- `ACCEPTED` - Aceito pelo motorista
- `IN_PROGRESS` - Em andamento
- `COMPLETED` - Finalizado
- `CANCELLED` - Cancelado

## 🔧 Configuração

### Variáveis de Ambiente
```bash
SPRING_PROFILES_ACTIVE=docker
SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/delivery_db
SPRING_DATASOURCE_USERNAME=delivery_user
SPRING_DATASOURCE_PASSWORD=delivery_pass
AZURE_SERVICEBUS_CONNECTION_STRING=<sua-connection-string>
```

### PostgreSQL
- **Database**: `delivery_db`
- **Usuário**: `delivery_user`
- **Senha**: `delivery_pass`
- **Porta**: `5432`

## 🚀 Executando o Serviço

### Via Docker Compose (Recomendado)
```bash
# No diretório backend/
docker-compose up order-service -d
```

### Desenvolvimento Local
```bash
cd order-service/order/
./mvnw spring-boot:run
```

### Build da Aplicação
```bash
./mvnw clean package -DskipTests
```

## 🧪 Testando

### Health Check
```bash
curl http://localhost:8080/orders/ok
```

### Teste Completo CRUD
```bash
# 1. Criar pedido
ORDER_ID=$(curl -s -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d '{"customerId":1,"driverId":2,"pickupAddress":"Rua A","deliveryAddress":"Rua B","description":"Teste","value":30.00}' \
  | jq -r '.id')

# 2. Consultar pedido criado
curl http://localhost:8080/orders/$ORDER_ID

# 3. Atualizar pedido
curl -X PUT http://localhost:8080/orders/$ORDER_ID \
  -H "Content-Type: application/json" \
  -d '{"status":"ACCEPTED"}'

# 4. Finalizar pedido
curl -X PUT http://localhost:8080/orders/$ORDER_ID/complete \
  -H "Content-Type: application/json" \
  -d '{"deliveryNotes":"Entregue com sucesso"}'
```

## 🔄 Integração com Outros Serviços

### API Gateway
- **Rota**: `/api/orders/*` → `http://order-service:8080/orders/*`
- **Filtros**: Circuit breaker, retry, authentication

### Auth Service
- Recebe validação de JWT tokens via API Gateway
- Extrai informações do usuário autenticado

### Tracking Service
- Consome eventos de mudança de status dos pedidos
- Sincroniza dados para rastreamento

### Azure Service Bus
- Publica eventos quando pedidos são criados/atualizados
- Permite integração com funções serverless

## 📊 Observabilidade

### Logs
```bash
# Ver logs em tempo real
docker-compose logs -f order-service

# Logs incluem:
# - Requisições HTTP recebidas
# - Operações do banco de dados
# - Eventos publicados no Service Bus
# - Erros e exceptions
```

### Database
```bash
# Acessar PostgreSQL
docker exec -it postgres psql -U delivery_user -d delivery_db

# Consultas úteis
SELECT * FROM orders ORDER BY created_at DESC LIMIT 10;
SELECT status, COUNT(*) FROM orders GROUP BY status;
```

## 🏗️ Desenvolvimento

### Adicionando Novas Funcionalidades

1. **Criar DTO** em `dtos/`
2. **Atualizar Controller** em `controllers/`
3. **Implementar Service** em `services/`
4. **Adicionar validações** usando Bean Validation
5. **Escrever testes** unitários e de integração

### Padrões Utilizados
- **Repository Pattern** com Spring Data JPA
- **DTO Pattern** para transferência de dados
- **Service Layer** para lógica de negócio
- **Controller-Service-Repository** architecture

## 🐛 Troubleshooting

### Problemas Comuns

1. **Erro de conexão PostgreSQL**
   ```bash
   docker-compose logs postgres
   # Aguardar health check do banco
   ```

2. **Erro de build Maven**
   ```bash
   # Limpar cache local
   ./mvnw clean
   # Verificar versão do Java
   java -version  # Deve ser 21+
   ```

3. **Erro Azure Service Bus**
   ```bash
   # Verificar connection string
   echo $AZURE_SERVICEBUS_CONNECTION_STRING
   ```

---
