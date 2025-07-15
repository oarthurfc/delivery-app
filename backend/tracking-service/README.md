![NodeJS](https://img.shields.io/badge/node.js-6DA55F?style=for-the-badge&logo=node.js&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Swagger](https://img.shields.io/badge/-Swagger-%23Clojure?style=for-the-badge&logo=swagger&logoColor=white)
![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)
# 📍 Microsserviço de Rastreamento

Microsserviço responsável pelo rastreamento em tempo real de entregas, desenvolvido em Node.js com PostgreSQL.

## 🚀 Funcionalidades

- ✅ **Atualização de localização**: Motoristas podem enviar suas coordenadas GPS
- ✅ **Consulta de localização atual**: Clientes podem ver onde está sua entrega
- ✅ **Histórico de rastreamento**: Visualizar todo o percurso da entrega
- ✅ **Entregas próximas**: Encontrar entregas em um raio específico
- ✅ **Estatísticas de rastreamento**: Métricas do serviço
- ✅ **Cálculo de distâncias**: Usando fórmula de Haversine
- ✅ **Documentação Swagger**: Interface interativa para testar APIs

## 🛠️ Tecnologias Utilizadas

- **Node.js** - Runtime JavaScript
- **Express.js** - Framework web
- **PostgreSQL** - Banco de dados relacional
- **Swagger/OpenAPI** - Documentação interativa da API
- **Docker** - Containerização

## 📋 Pré-requisitos

- Docker Desktop
- Git

## 🚀 Como Executar

### Opção 1: Script Automático (Recomendado)

#### Windows
```bash
./setup.bat
```

#### Linux/Mac
```bash
chmod +x setup.sh
./setup.sh
```

### Opção 2: Docker Manual

```bash
# 1. Criar arquivo .env
cp .env.example .env

# 2. Construir e subir serviços
docker-compose up --build -d

# 3. Ver logs
docker-compose logs -f tracking_service
```

## 📁 Estrutura do Projeto

```
tracking-microservice/
├── src/
│   ├── controllers/        # Controladores da API
│   │   └── trackingController.js
│   ├── middleware/         # Middlewares de autenticação
│   │   └── auth.js
│   ├── models/            # Modelos de dados
│   │   └── locationPoint.js
│   ├── routes/            # Definição das rotas
│   │   └── tracking.js
│   ├── services/          # Lógica de negócio
│   │   └── trackingService.js
│   ├── utils/             # Utilitários
│   │   └── geoUtils.js
│   ├── config/            # Configurações
│   │   ├── database.js
│   │   └── swagger.js
│   └── app.js             # Configuração do Express
├── tests/                 # Testes automatizados
├── server.js              # Ponto de entrada
├── setup.bat              # Script de setup (Windows)
├── setup.sh               # Script de setup (Linux/Mac)
├── package.json
├── .env.example
├── .gitignore
├── Dockerfile
├── docker-compose.yml
└── README.md
```

## 📚 Documentação da API

### Swagger/OpenAPI

A documentação completa da API está disponível via Swagger UI:

```
http://localhost:3003/api/docs
```

### URLs Disponíveis

- **📖 Documentação**: http://localhost:3003/api/docs
- **⚕️ Health Check**: http://localhost:3003/api/tracking/health
- **🗄️ PostgreSQL**: localhost:5433

### Tags de Endpoints

- **🔐 Rastreamento** - Atualização de localização (motoristas)
- **👤 Motorista** - Funcionalidades específicas para motoristas  
- **🔍 Consulta** - Consulta de localizações (clientes/motoristas)
- **📍 Geolocalização** - Busca por proximidade
- **📊 Estatísticas** - Métricas e relatórios
- **⚕️ Sistema** - Health checks e status

### Principais Endpoints

#### 1. Atualizar Localização
```http
POST /api/tracking/location
Content-Type: application/json

{
  "orderId": 123,
  "driverId": 1,
  "latitude": -19.9191,
  "longitude": -43.9386,
  "accuracy": 10.5,
  "speed": 45.2,
  "heading": 180.0
}
```

#### 2. Localização Atual do Pedido
```http
GET /api/tracking/order/123/current
```

#### 3. Histórico de Localização
```http
GET /api/tracking/order/123/history?limit=50&offset=0
```

#### 4. Entregas Próximas
```http
GET /api/tracking/nearby?latitude=-19.9191&longitude=-43.9386&radius=5
```

#### 5. Estatísticas
```http
GET /api/tracking/stats
```

#### 6. Resumo do Motorista
```http
GET /api/tracking/driver/1/summary
```

## 📊 Estrutura do Banco de Dados

### Tabela: location_points
```sql
CREATE TABLE location_points (
  id SERIAL PRIMARY KEY,
  order_id INTEGER NOT NULL,
  driver_id INTEGER NOT NULL,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  accuracy DECIMAL(6, 2),
  speed DECIMAL(6, 2),
  heading DECIMAL(6, 2)
);
```

## 🧪 Testando a API

### 1. Teste Básico - Health Check
```bash
curl http://localhost:3003/api/tracking/health
```

### 2. Adicionar Localização
```bash
curl -X POST http://localhost:3003/api/tracking/location \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": 123,
    "driverId": 1,
    "latitude": -19.9191,
    "longitude": -43.9386
  }'
```

### 3. Consultar Localização Atual
```bash
curl http://localhost:3003/api/tracking/order/123/current
```

### 4. Ver Estatísticas
```bash
curl http://localhost:3003/api/tracking/stats
```

## 🔧 Comandos Úteis

```bash
# Ver logs em tempo real
docker-compose logs -f tracking_service

# Parar serviços
docker-compose down

# Reconstruir do zero
docker-compose down && docker-compose up --build -d

# Verificar status dos containers
docker-compose ps

# Acessar container do PostgreSQL
docker exec -it tracking_postgres psql -U root -d tracking_service
```

## 🐛 Troubleshooting

### Problemas Comuns:

1. **Erro "Port already in use"**
   - Mude as portas no `docker-compose.yml`
   - Ou pare outros serviços: `docker stop $(docker ps -q)`

2. **Container não inicia**
   - Verifique logs: `docker-compose logs tracking_service`
   - Reconstrua: `docker-compose up --build -d`

3. **Banco não conecta**
   - Aguarde alguns segundos para o PostgreSQL inicializar
   - Verifique se container está rodando: `docker-compose ps`

4. **API retorna erro 500**
   - Verifique se as tabelas foram criadas
   - Consulte logs para detalhes do erro

## 🤝 Integração com Outros Microsserviços

Este microsserviço foi projetado para ser **totalmente independente** e pode ser integrado via:

- **API Gateway**: Roteamento de `/api/tracking/*`
- **Frontend Flutter**: Consumo direto das APIs REST
- **Outros Microsserviços**: Comunicação via HTTP/REST

### Exemplo de Integração via API Gateway:
```bash
# Rotas mapeadas no gateway
/api/v1/tracking/* -> http://tracking-service:3003/api/tracking/*
```

## 📈 Características Técnicas

- **🔄 Independente**: Não depende de outros microsserviços
- **📊 Escalável**: Estrutura preparada para crescimento
- **🛡️ Seguro**: Validação de dados e sanitização
- **📖 Documentado**: Swagger UI completo
- **🐳 Containerizado**: Pronto para deploy
- **🧪 Testável**: APIs facilmente testáveis

---