# Detalhamento dos Requisitos do Trabalho de Desenvolvimento Móvel

## Índice

- [Visão Geral](#visão-geral)
- [Requisitos Obrigatórios](#requisitos-obrigatórios)
- [Requisitos Técnicos](#requisitos-técnicos)

## Visão Geral

Desenvolver um aplicativo móvel em Flutter para clientes e motoristas:

1. Interface para clientes:
   - Rastreamento em tempo real das encomendas
   - Histórico de pedidos
   - Notificações push sobre status da entrega

2. Interface para motoristas:
   - Visualização e aceitação de entregas
   - Navegação e otimização de rotas
   - Atualização do status da entrega com o uso da câmera

3. Armazenamento local de dados (SQLite) para funcionamento offline

4. Sincronização de dados com o backend quando online

5. Geolocalização para rastreamento de veículos e cálculo de rotas

## Requisitos Obrigatórios

A aplicação deve conter os seguintes elementos:

### Uso da Câmera e GPS

- O Motorista deve ser capaz de tirar foto da entrega assinada pelo cliente.
- A localização atual do usuário deve ser capturada no momento da foto.
- Deverá ser utilizado o serviço de Mapa e GPS do motorista para rastrear a entrega.

### Armazenamento com SQLite

- O sistema deve armazenar localmente dados da entrega e última localização.
- Deve haver uma tela que lista os pedidos entreues.

### Uso de Shared Preferences

- O aplicativo deve permitir salvar configurações do usuário, como tema claro/escuro e preferências de exibição.
- As configurações devem ser persistentes entre sessões.

### Notificações Push

- O sistema do cliente deve ter permissão para exibir notificações push do status da entrega.

### Tratamento de Erros

- Deve implementar estratégias de tratamento de erro, incluindo:
  - Tratamento de falhas na requisição da API (ex.: falta de internet, erro no servidor).
  - Tratamento de permissões negadas pelo usuário para câmera ou localização.
  - Tratamento de falhas no armazenamento de dados (SQLite e Shared Preferences).

## Requisitos Técnicos

- O projeto deve ser desenvolvido em **Flutter**.
- Deve utilizar **Dart** como linguagem principal.
- As bibliotecas recomendadas incluem:
  - `http` para consumo de APIs.
  - `camera` para uso da câmera.
  - `shared_preferences` para armazenamento de configurações.
  - `sqflite` para banco de dados SQLite.
  - `geolocator` e `google_maps_flutter` para uso do GPS.

---
