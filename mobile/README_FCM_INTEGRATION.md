# FCM Token Integration - Mobile

## Mudanças Implementadas

### 1. **NotificationService** (`lib/services/notification_service.dart`)
- ✅ Adicionado método `getFcmToken()` para obter o token do dispositivo
- ✅ Método retorna o FCM token atual ou null se não conseguir obter

### 2. **AuthService** (`lib/services/auth_service.dart`)
- ✅ **Register**: Agora obtém automaticamente o FCM token e envia na requisição
- ✅ **updateFcmToken**: Novo método para atualizar o FCM token no backend
- ✅ Validação para garantir que o FCM token seja obtido antes do registro

### 3. **AuthProvider** (`lib/providers/auth_provider.dart`)
- ✅ **Register**: Agora inclui logs para rastrear o processo de registro com FCM
- ✅ **updateFcmToken**: Novo método para atualizar o FCM token via provider

### 4. **RegisterScreen** (`lib/screens/auth/register_screen.dart`)
- ✅ Adicionado card informativo sobre notificações
- ✅ Interface mais amigável para o usuário entender sobre permissões

## Fluxo de Funcionamento

### 1. **Registro de Usuário**
```dart
// O usuário preenche o formulário de registro
// O sistema automaticamente:
// 1. Obtém o FCM token do dispositivo
// 2. Valida se o token foi obtido
// 3. Envia a requisição com o token
// 4. Salva o usuário localmente
```

### 2. **Atualização de FCM Token**
```dart
// Quando o token mudar (ex: reinstalação do app)
await authProvider.updateFcmToken();
```

## Como Usar

### 1. **Registro Automático**
O FCM token é obtido automaticamente durante o registro. O usuário só precisa:
- Preencher os dados do formulário
- Permitir notificações quando solicitado
- Clicar em "Registrar"

### 2. **Atualização Manual do Token**
```dart
// Em qualquer lugar do app
final authProvider = context.read<AuthProvider>();
await authProvider.updateFcmToken();
```

### 3. **Verificação de Token**
```dart
// Para verificar se o token está disponível
final token = await NotificationService.getFcmToken();
if (token != null) {
  print('FCM Token: $token');
} else {
  print('Token não disponível');
}
```

## Tratamento de Erros

### 1. **Token Não Disponível**
- Se o FCM token não puder ser obtido, o registro falha
- Mensagem de erro informativa é exibida
- Usuário é orientado a verificar permissões

### 2. **Falha na Atualização**
- Logs detalhados para debug
- Método retorna false em caso de falha
- Não interrompe o fluxo principal do app

## Logs de Debug

O sistema inclui logs detalhados para facilitar o debug:

```
🔔 FCM Token obtido: fnTJ06FQRxeXG-Bxp4eywu:APA91bG2cmCd9mx8_h93kH3QlyaPLmbUkk1sBxdsbWl-dCWyUrbN-8BQfAdayAeH-DQ8yon4UfFS4G8-Kkw1o9-s1XNepEemwdvAFgQ7jEOz5K_ziG1iJ8Y
AuthService: Registrando com FCM token: fnTJ06FQRxeXG-Bxp4eywu:APA91bG2cmCd9mx8_h93kH3QlyaPLmbUkk1sBxdsbWl-dCWyUrbN-8BQfAdayAeH-DQ8yon4UfFS4G8-Kkw1o9-s1XNepEemwdvAFgQ7jEOz5K_ziG1iJ8Y
AuthProvider: Iniciando registro com FCM token
```

## Integração com Backend

### 1. **Requisição de Registro**
```json
POST /auth/register
{
  "name": "Nome do Usuário",
  "email": "user@example.com",
  "password": "123456",
  "role": "customer",
  "fcmToken": "fcm_token_aqui"
}
```

### 2. **Atualização de Token**
```json
PUT /auth/update-fcm-token
Authorization: Bearer <jwt_token>
{
  "fcmToken": "novo_fcm_token_aqui"
}
```

## Permissões Necessárias

### Android
- `android.permission.INTERNET`
- `android.permission.WAKE_LOCK`
- `android.permission.VIBRATE`
- `android.permission.RECEIVE_BOOT_COMPLETED`

### iOS
- Permissão de notificação solicitada automaticamente
- Configuração no `Info.plist`

## Próximos Passos

1. **Testar o registro** com FCM token
2. **Implementar atualização automática** do token quando necessário
3. **Adicionar notificações push** para diferentes eventos
4. **Configurar diferentes tipos** de notificação (pedidos, status, etc.)

## Troubleshooting

### Problema: Token não é obtido
**Solução:**
1. Verificar se o Firebase está configurado corretamente
2. Verificar permissões do dispositivo
3. Verificar logs do NotificationService

### Problema: Registro falha
**Solução:**
1. Verificar se o backend está rodando
2. Verificar se o endpoint `/auth/register` aceita `fcmToken`
3. Verificar logs do AuthService

### Problema: Notificações não chegam
**Solução:**
1. Verificar se o token está sendo salvo no backend
2. Verificar se o Firebase Console está configurado
3. Testar envio manual pelo Firebase Console 