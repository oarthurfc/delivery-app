# FCM Token Integration

## Mudanças Implementadas

### 1. Modelo de Usuário (`src/models/user.model.js`)
- Adicionado campo `fcmToken` obrigatório no schema do usuário
- Campo é do tipo String, obrigatório e com trim

### 2. Controller (`src/controllers/auth.controller.js`)
- **Register**: Agora requer `fcmToken` obrigatório na criação do usuário
- **Login**: Retorna o `fcmToken` do usuário na resposta
- **updateFcmToken**: Novo método para atualizar o FCM token do usuário

### 3. Rotas (`src/routes/auth.routes.js`)
- **POST /register**: Validação obrigatória do `fcmToken`
- **PUT /update-fcm-token**: Nova rota protegida para atualizar o FCM token

### 4. Middleware (`src/middleware/auth.middleware.js`)
- Corrigido `validateToken` para funcionar como middleware

## Endpoints Disponíveis

### 1. Registrar Usuário
```http
POST /register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "123456",
  "name": "Nome do Usuário",
  "role": "customer",
  "fcmToken": "fcm_token_aqui"
}
```

### 2. Login
```http
POST /login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "123456"
}
```

### 3. Atualizar FCM Token
```http
PUT /update-fcm-token
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "fcmToken": "novo_fcm_token_aqui"
}
```

### 4. Validar Token
```http
POST /validate
Authorization: Bearer <jwt_token>
```

## Migração de Dados

Para usuários existentes, execute o script de migração:

```bash
node migrate-fcm-token.js
```

Este script irá:
1. Conectar ao MongoDB
2. Buscar usuários sem `fcmToken`
3. Atualizar com tokens temporários
4. Os usuários precisarão atualizar seus tokens reais via app

## Respostas de Exemplo

### Register Response
```json
{
  "message": "Usuário criado com sucesso",
  "token": "jwt_token_aqui",
  "user": {
    "id": 123,
    "email": "user@example.com",
    "name": "Nome do Usuário",
    "role": "customer",
    "fcmToken": "fcm_token_aqui"
  }
}
```

### Login Response
```json
{
  "message": "Login realizado com sucesso",
  "token": "jwt_token_aqui",
  "user": {
    "id": 123,
    "email": "user@example.com",
    "name": "Nome do Usuário",
    "role": "customer",
    "fcmToken": "fcm_token_aqui"
  }
}
```

### Update FCM Token Response
```json
{
  "message": "FCM Token atualizado com sucesso",
  "user": {
    "id": 123,
    "email": "user@example.com",
    "name": "Nome do Usuário",
    "role": "customer",
    "fcmToken": "novo_fcm_token_aqui"
  }
}
```

## Validações

- `fcmToken` é obrigatório no registro
- `fcmToken` não pode estar vazio
- `fcmToken` é automaticamente trimado
- Token JWT é necessário para atualizar o FCM token

## Integração com Frontend

O frontend deve:
1. Obter o FCM token do dispositivo
2. Enviar o token no registro
3. Atualizar o token quando necessário via `/update-fcm-token`
4. Usar o token para enviar notificações push 