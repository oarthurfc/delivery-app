![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)
# 📱 Delivery Mobile App

Aplicativo móvel Flutter para o sistema de entregas, desenvolvido como parte da primeira fase do projeto acadêmico. O app oferece interfaces dedicadas para **clientes** e **motoristas**, com funcionalidades completas de rastreamento, gestão de pedidos e integração com backend de microsserviços.

## 🚀 Visão Geral

O aplicativo móvel é construído em **Flutter/Dart** e implementa uma arquitetura robusta com armazenamento local, sincronização com APIs, geolocalização em tempo real e sistema de notificações. Projetado para funcionar tanto online quanto offline, garantindo uma experiência fluida para usuários finais.

## 🏗️ Arquitetura da Aplicação

### Padrões Arquiteturais
- **Repository Pattern**: Separação clara entre camadas de dados
- **Service Layer**: Isolamento de lógica de negócio
- **Widget-Based UI**: Componentes reutilizáveis e modulares
- **State Management**: Gerenciamento de estado com StatefulWidget
- **Offline-First**: Prioridade para funcionamento offline

### Estrutura de Pastas

```
mobile/
├── lib/
│   ├── database/                    # Camada de persistência
│   │   ├── database_helper.dart     # Configuração SQLite
│   │   └── repository/              # Repositórios de dados
│   │       ├── UserRepository.dart
│   │       ├── OrderRepository.dart
│   │       └── settings_repository.dart
│   │
│   ├── models/                      # Modelos de dados
│   │   ├── user.dart
│   │   ├── order.dart
│   │   ├── address.dart
│   │   └── settings.dart
│   │
│   ├── screens/                     # Telas da aplicação
│   │   ├── client/                  # Interface do cliente
│   │   │   ├── client_history_screen.dart
│   │   │   ├── client_profile_screen.dart
│   │   │   └── client_delivery_details_screen.dart
│   │   └── driver/                  # Interface do motorista
│   │       ├── driver_history_screen.dart
│   │       ├── driver_profile_screen.dart
│   │       ├── driver_delivery_details_screen.dart
│   │       └── delivery_tracking_history_screen.dart
│   │
│   ├── services/                    # Serviços e integrações
│   │   ├── api/                     # Integração com APIs
│   │   │   ├── ApiService.dart
│   │   │   └── repos/
│   │   │       ├── OrderRepository2.dart
│   │   │       └── DriverTrackingRepository.dart
│   │   ├── location_service.dart    # Geolocalização
│   │   ├── notification_service.dart # Notificações push
│   │   └── camera_service.dart      # Integração com câmera
│   │
│   ├── widgets/                     # Componentes reutilizáveis
│   │   ├── common/
│   │   │   ├── app_bar_widget.dart
│   │   │   └── app_bottom_nav_bar.dart
│   │   └── forms/
│   │
│   └── main.dart                    # Ponto de entrada da aplicação
│
├── android/                         # Configurações Android
├── ios/                            # Configurações iOS
├── pubspec.yaml                    # Dependências e metadados
└── pubspec.lock                    # Lock de versões
```

## 🎯 Funcionalidades Principais

### 👥 Interface do Cliente
- **Rastreamento em Tempo Real**: Acompanhamento da localização do motorista
- **Histórico de Pedidos**: Visualização de entregas passadas e atuais
- **Notificações Push**: Alertas sobre status da entrega
- **Perfil Pessoal**: Gerenciamento de dados e preferências

### 🚚 Interface do Motorista
- **Gestão de Entregas**: Aceitação e gerenciamento de pedidos
- **Navegação GPS**: Rotas otimizadas para destinos
- **Captura de Evidências**: Fotos com geolocalização para comprovação
- **Rastreamento Automático**: Envio periódico da localização atual
- **Histórico de Entregas**: Registro completo de trabalhos realizados

### 🔧 Funcionalidades Técnicas
- **Armazenamento Offline**: SQLite para funcionamento sem internet
- **Sincronização Automática**: Dados sincronizados quando online
- **Geolocalização Precisa**: GPS integrado para tracking em tempo real
- **Sistema de Preferências**: Configurações persistentes com SharedPreferences
- **Tratamento de Erros**: Gestão robusta de falhas e exceções

## 📱 Tecnologias e Dependências

### Core Framework
- **Flutter**: ^3.24.5 - Framework principal
- **Dart**: SDK de desenvolvimento

### Dependências Principais

#### Persistência e Dados
```yaml
sqflite: ^2.3.3+2          # Banco SQLite local
shared_preferences: ^2.3.3  # Preferências do usuário
flutter_secure_storage: ^9.2.4  # Armazenamento seguro
```

#### Geolocalização e Mapas
```yaml
geolocator: ^12.0.0        # Serviços de localização
flutter_map: ^6.2.1       # Mapas interativos
latlong2: ^0.9.1          # Cálculos geográficos
```

#### Multimídia e Câmera
```yaml
camera: ^0.11.0+2          # Integração com câmera
image_picker: ^1.1.2       # Seleção de imagens
```

#### Rede e APIs
```yaml
http: ^1.2.2               # Requisições HTTP
dio: ^5.7.0               # Cliente HTTP avançado
```

#### Notificações
```yaml
flutter_local_notifications: ^17.2.4  # Notificações locais
```

#### UI e Utilitários
```yaml
intl: ^0.20.2             # Internacionalização
```

## 🚀 Como Executar

### Pré-requisitos
- **Flutter SDK** (versão 3.0+)
- **Dart SDK** 
- **Android Studio** ou **Xcode** (para desenvolvimento)
- **Dispositivo físico** ou emulador configurado

### Instalação e Execução

1. **Clone o projeto e navegue para a pasta mobile:**
```bash
cd mobile/
```

2. **Instale as dependências:**
```bash
flutter pub get
```

3. **Verifique se há dispositivos conectados:**
```bash
flutter devices
```

4. **Execute o aplicativo:**
```bash
flutter run
```

### Executar em Dispositivos Específicos
```bash
# Android
flutter run -d android

# iOS (apenas no macOS)
flutter run -d ios
```

## 🗃️ Estrutura do Banco de Dados

### Tabelas SQLite

```sql
-- Usuários (clientes e motoristas)
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  user_type TEXT NOT NULL,
  created_at TEXT NOT NULL
);

-- Pedidos de entrega
CREATE TABLE orders (
  id INTEGER PRIMARY KEY,
  customer_id INTEGER NOT NULL,
  driver_id INTEGER,
  status TEXT NOT NULL,
  origin_address TEXT NOT NULL,
  destination_address TEXT NOT NULL,
  description TEXT NOT NULL,
  image_url TEXT,
  price REAL NOT NULL DEFAULT 0.0,
  receiver_name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'SYNCED'
);

-- Pontos de localização para rastreamento
CREATE TABLE location_points (
  id INTEGER PRIMARY KEY,
  order_id INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  sync_status TEXT NOT NULL DEFAULT 'SYNCED'
);

-- Configurações do usuário
CREATE TABLE settings (
  user_id INTEGER PRIMARY KEY,
  is_dark_theme INTEGER NOT NULL DEFAULT 0,
  show_completed_orders INTEGER NOT NULL DEFAULT 1,
  sync_status TEXT NOT NULL DEFAULT 'SYNCED'
);
```

## 🔗 Integração com Backend

### Endpoints da API

O aplicativo móvel se integra com o sistema de microsserviços através do API Gateway:

```dart
// Configuração base
const String API_BASE_URL = 'http://localhost:8000';

// Autenticação
POST /api/auth/login
POST /api/auth/register

// Gestão de pedidos
GET  /api/orders
POST /api/orders
GET  /api/orders/{id}
PUT  /api/orders/{id}/status

// Rastreamento
GET  /api/tracking/order/{id}/current
POST /api/tracking/location
GET  /api/tracking/order/{id}/history
```

### Sincronização de Dados

O app implementa um sistema híbrido de dados:

1. **Modo Online**: Dados salvos localmente E sincronizados com API
2. **Modo Offline**: Operações salvas localmente para sincronização posterior
3. **Sincronização Automática**: Quando a conectividade é restaurada

```dart
// Exemplo de repositório híbrido
class OrderRepository2 {
  Future<List<Order>> getOrdersByCustomerId(int customerId) async {
    try {
      // Tenta buscar da API primeiro
      final apiOrders = await _fetchFromAPI(customerId);
      // Salva localmente
      await _saveLocally(apiOrders);
      return apiOrders;
    } catch (e) {
      // Se falhar, busca do cache local
      return await _getFromLocalDB(customerId);
    }
  }
}
```

## 📍 Sistema de Geolocalização

### Rastreamento em Tempo Real

O app implementa rastreamento contínuo para motoristas:

```dart
// Configuração de envio de localização
static const int secondsPerUpdate = 30; // A cada 30 segundos

Timer? _locationTimer;

void _startLocationTracking() {
  _locationTimer = Timer.periodic(
    Duration(seconds: secondsPerUpdate),
    (timer) => _sendCurrentLocation(),
  );
}
```

### Permissões Necessárias

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Este aplicativo precisa de acesso à sua localização para mostrar no mapa.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Este aplicativo precisa de acesso à sua localização para mostrar no mapa.</string>
```

## 📷 Integração com Câmera

### Captura de Evidências

Funcionalidade essencial para motoristas comprovarem entregas:

```dart
// Captura de foto com metadados de localização
Future<File?> captureDeliveryPhoto() async {
  try {
    final image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (image != null) {
      // Adiciona metadados de geolocalização
      final position = await Geolocator.getCurrentPosition();
      return await _addLocationMetadata(File(image.path), position);
    }
  } catch (e) {
    print('Erro ao capturar foto: $e');
  }
  return null;
}
```

## 🔔 Sistema de Notificações

### Notificações Locais e Push

```dart
class NotificationService {
  static Future<void> showDeliveryNotification(String message) async {
    await _flutterLocalNotificationsPlugin.show(
      0,
      'Atualização da Entrega',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'delivery_channel',
          'Delivery Notifications',
          importance: Importance.high,
        ),
      ),
    );
  }
}
```

## 🎨 Interface do Usuário

### Componentes Reutilizáveis

- **AppBarWidget**: Barra superior padronizada
- **AppBottomNavBar**: Navegação inferior consistente
- **Loading States**: Indicadores de carregamento
- **Error Handling**: Tratamento visual de erros

### Temas e Personalização

O app suporta tema claro/escuro com preferências persistentes:

```dart
// Configuração de tema salva no SharedPreferences
await _settingsRepository.updateSettings(
  userId,
  isDarkMode,
  showCompletedOrders,
);
```

## 🔧 Tratamento de Erros

### Estratégias Implementadas

1. **Conectividade**: Detecção automática de estado online/offline
2. **Permissões**: Solicitação e tratamento de permissões negadas
3. **API Failures**: Fallback para dados locais
4. **GPS**: Tratamento de falhas de localização
5. **Camera**: Fallback para galeria em caso de erro

```dart
try {
  final result = await _apiCall();
  return result;
} on SocketException {
  // Sem internet - usar cache local
  return await _getFromLocalCache();
} on LocationServiceDisabledException {
  // GPS desabilitado - mostrar alerta
  _showLocationAlert();
} catch (e) {
  // Erro genérico - log e notificação
  _logError(e);
  _showErrorNotification(e.toString());
}
```

## 🚦 Estados de Pedidos

### Fluxo de Status

```dart
enum OrderStatus {
  pending,     // Aguardando motorista
  accepted,    // Aceito pelo motorista  
  inProgress,  // Em andamento
  delivered,   // Entregue
  cancelled    // Cancelado
}
```

### Atualizações em Tempo Real

O app monitora mudanças de status através de:
- Polling periódico da API
- Notificações push do backend
- Atualização automática da interface

## 📊 Performance e Otimização

### Estratégias Aplicadas

- **Lazy Loading**: Carregamento sob demanda de dados
- **Caching Inteligente**: Armazenamento estratégico em SQLite
- **Compressão de Imagens**: Redução de tamanho de fotos
- **Debouncing**: Evita chamadas excessivas de localização

## 🧪 Testing e Debug

### Comandos Úteis

```bash
# Executar em modo debug
flutter run --debug

# Ver logs detalhados
flutter logs

# Analisar performance
flutter run --profile

# Build para produção
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

### Debug de Banco de Dados

```dart
// Verificar dados SQLite
final db = await DatabaseHelper.instance.database;
final result = await db.query('orders');
print('Orders in DB: $result');
```

## 🔒 Segurança

### Medidas Implementadas

- **Secure Storage**: Dados sensíveis em armazenamento seguro
- **Input Validation**: Validação de todas as entradas
- **JWT Tokens**: Autenticação segura com backend
- **HTTPS**: Comunicação criptografada com APIs

## 🤝 Integração com Sistema Completo

Este aplicativo móvel é parte de uma arquitetura maior:

- **Backend Microsserviços**: [`../backend/README.md`](../backend/README.md)
- **Funções Serverless**: [`../functions-sb/README.md`](../functions-sb/README.md)
- **Documentação Completa**: [`../docs/`](../docs/)

## 📄 Licença

Desenvolvido para fins acadêmicos como parte do projeto de **Laboratório de Desenvolvimento de Dispositivos Móveis e Distribuídos** - PUC Minas.

---

**💡 Dica**: Para uma experiência completa, execute primeiro o backend de microsserviços antes de testar o aplicativo móvel. Consulte a documentação do backend para instruções detalhadas.