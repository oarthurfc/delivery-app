# 🔐 Auth Service

Microsserviço de autenticação e autorização do sistema de delivery, responsável por gerenciar usuários, login, registro e validação de JWT tokens.

## 🚀 Tecnologias Utilizadas

- **Node.js 20** + Express.js
- **MongoDB** (via Mongoose)
- **JWT** (JSON Web Tokens) para autenticação
- **bcryptjs** para hash de senhas
- **express-validator** para validação de dados
- **Helmet** para segurança HTTP
- **CORS** para controle de origem
- **Morgan** para logs de requisições

## 📋 Funcionalidades

- ✅ **Registro de usuários** (clientes e motoristas)
- ✅ **Login com JWT** tokens
- ✅ **Validação de tokens** para outros microsserviços
- ✅ **Criptografia de senhas** com bcrypt
- ✅ **Validação de dados** de entrada
- ✅ **Health check** endpoint
- ✅ **Logs estruturados** de requisições

## 🏗️ Estrutura do Projeto

```
auth-service/
├── src/
│   ├── controllers/     # Controladores das rotas
│   ├── middleware/      # Middlewares de autenticação
│   ├── models/         # Modelos do MongoDB
│   ├── routes/         # Definição das rotas
│   ├── services/       # Lógica de negócio
│   ├── utils/          # Utilitários
│   └── index.js        # Ponto de entrada
├── package.json
├── Dockerfile
└── README.md
```

## 🌐 Endpoints da API

### Autenticação
```http
POST /auth/register     # Registrar novo usuário
POST /auth/login        # Fazer login
POST /auth/validate     # Validar token JWT
GET  /health           # Health check
```

### Exemplos de Uso

#### Registrar Usuário
```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "João Silva",
    "email": "joao@example.com",
    "password": "senha123",
    "userType": "cliente"
  }'
```

#### Fazer Login
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "joao@example.com",
    "password": "senha123"
  }'
```

#### Validar Token
```bash
curl -X POST http://localhost:3000/auth/validate \
  -H "Authorization: Bearer <seu-jwt-token>"
```

## 🔧 Configuração

### Variáveis de Ambiente

```bash
NODE_ENV=development
PORT=3000
JWT_SECRET=sua-chave-secreta-jwt
JWT_EXPIRES_IN=24h
MONGODB_URI=mongodb://auth_user:auth_password@mongodb:27017/auth_db
CORS_ORIGINS=http://localhost:3000,http://localhost:8000
```

### MongoDB

O serviço conecta automaticamente ao MongoDB configurado no Docker Compose:
- **Database**: `auth_db`
- **Usuário**: `auth_user`
- **Senha**: `auth_password`

## 🚀 Executando o Serviço

### Via Docker Compose (Recomendado)
```bash
# No diretório backend/
docker-compose up auth-service -d
```

### Desenvolvimento Local
```bash
cd auth-service/
npm install
npm run dev  # Usa nodemon para auto-reload
```

### Produção
```bash
npm start
```

## 🧪 Testando

### Health Check
```bash
curl http://localhost:3000/health
```

### Teste Completo de Fluxo
```bash
# 1. Registrar usuário
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"123456","userType":"cliente"}'

# 2. Fazer login
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123456"}'

# 3. Validar token (usar o token retornado do login)
curl -X POST http://localhost:3000/auth/validate \
  -H "Authorization: Bearer <token-aqui>"
```

## 🔒 Segurança

- **Senhas criptografadas** com bcrypt (salt rounds: 12)
- **JWT tokens** com expiração configurável
- **Validação rigorosa** de entrada com express-validator
- **Headers de segurança** via Helmet
- **CORS configurado** para domínios específicos
- **Rate limiting** (via API Gateway)

## 🐛 Troubleshooting

### Problemas Comuns

1. **Erro de conexão MongoDB**
   ```bash
   # Verificar se MongoDB está rodando
   docker-compose logs mongodb
   ```

2. **Token inválido**
   ```bash
   # Verificar se JWT_SECRET é o mesmo em todos os serviços
   echo $JWT_SECRET
   ```

3. **Erro de CORS**
   ```bash
   # Verificar CORS_ORIGINS no .env
   # Adicionar origem do frontend se necessário
   ```

## 🔄 Integração com Outros Serviços

### API Gateway
- **Rota**: `/api/auth/*` → `http://auth-service:3000/auth/*`
- **Filtros**: Circuit breaker, retry, timeout

### Order Service
- Valida tokens JWT via middleware
- Extrai informações do usuário do token

### Tracking Service  
- Valida tokens JWT para operações protegidas
- Identifica usuário através do token

## 📊 Monitoramento

### Logs
```bash
# Ver logs em tempo real
docker-compose logs -f auth-service

# Logs estruturados incluem:
# - Requisições HTTP (via Morgan)
# - Erros de autenticação
# - Conexões do banco
# - Operações de validação
```

### Métricas
- Health endpoint disponível em `/health`
- Logs de performance para debugging
- Monitoramento via Docker healthcheck

---
