# 📦 Delivery System

Um sistema completo de entregas desenvolvido como projeto acadêmico na PUC Minas, implementando uma arquitetura moderna com aplicativo móvel Flutter, microsserviços em backend e infraestrutura serverless na nuvem.

## 🎥 Demonstração

[![Demonstração do Sistema](https://img.shields.io/badge/▶️-Assistir%20Demo-red?style=for-the-badge&logo=youtube)](https://www.youtube.com/shorts/lNh5pR27yVE)

## 🚀 Visão Geral

O projeto Delivery é uma solução completa para gerenciamento e rastreamento de entregas, oferecendo interfaces dedicadas para clientes e motoristas. O sistema foi desenvolvido seguindo os princípios de arquitetura moderna, com foco em escalabilidade, performance e experiência do usuário.

**Principais características:**
- 📱 Aplicativo móvel híbrido desenvolvido em Flutter
- 🔧 Arquitetura de microsserviços para o backend
- ☁️ Infraestrutura serverless para alta disponibilidade
- 📍 Rastreamento em tempo real com geolocalização
- 🔔 Sistema de notificações push
- 📸 Captura de fotos para comprovação de entrega

## 📁 Estrutura do Projeto

```
delivery/
├── mobile/                 # Aplicativo móvel Flutter
│   ├── lib/               # Código fonte Dart
│   ├── android/           # Configurações Android
│   ├── ios/              # Configurações iOS
│   └── pubspec.yaml      # Dependências Flutter
│
├── backend/               # Microsserviços e API Gateway
│   ├── api-gateway/      # Gateway de APIs
│   ├── auth-service/     # Serviço de autenticação
│   ├── order-service/    # Serviço de pedidos
│   ├── tracking-service/ # Serviço de rastreamento
│   └── notification-service/ # Serviço de notificações
│
├── cloud/                 # Infraestrutura serverless
│   ├── functions/        # Funções serverless
│   ├── infrastructure/   # Configurações de infraestrutura
│   └── ci-cd/           # Pipelines de deploy
│
└── docs/                  # Documentação do projeto
    ├── api/              # Documentação das APIs
    ├── architecture/     # Diagramas de arquitetura
    └── deployment/       # Guias de deployment
```

## 🏗️ Fases do Desenvolvimento

### Fase 1: Desenvolvimento Mobile
A primeira fase focou na criação do aplicativo móvel usando Flutter, implementando interfaces distintas para clientes e motoristas. O app inclui funcionalidades como rastreamento em tempo real, histórico de pedidos, captura de fotos com geolocalização para comprovação de entrega, e armazenamento offline com SQLite. Também foram implementadas notificações push, sistema de preferências com Shared Preferences, e tratamento robusto de erros para cenários como falta de conectividade e permissões negadas.

### Fase 2: Arquitetura de Microsserviços
Na segunda fase, foi desenvolvido o backend utilizando arquitetura de microsserviços, criando serviços independentes para autenticação (com JWT), gerenciamento de pedidos (CRUD completo), rastreamento em tempo real, e sistema de notificações. A comunicação entre serviços foi implementada tanto de forma síncrona (REST) quanto assíncrona (mensageria), com um API Gateway centralizando o roteamento e autenticação. Esta arquitetura garante escalabilidade, manutenibilidade e isolamento de falhas.

### Fase 3: Infraestrutura Serverless
A fase final migrou a arquitetura para uma abordagem serverless na nuvem, substituindo os microsserviços tradicionais por funções serverless (AWS Lambda, Google Cloud Functions, etc.) e serviços gerenciados. Esta implementação inclui API Gateway serverless, banco de dados NoSQL escalável, sistema de mensageria em nuvem, cache distribuído, e armazenamento de arquivos. O resultado é uma infraestrutura que escala automaticamente, com menor custo operacional e alta disponibilidade garantida pelo provedor de nuvem.

## 🚀 Como Executar o Projeto

### Pré-requisitos
- Flutter SDK (versão 3.0+)
- Dart SDK
- Android Studio / Xcode (para desenvolvimento mobile)
- Docker e Docker Compose (para microsserviços)
- Conta em provedor de nuvem (AWS/Google Cloud/Azure) para fase serverless

### Executando o Mobile
```bash
cd mobile/
flutter pub get
flutter run
```

### Executando os Microsserviços
COLOCAR INSTRUÇÃO DO DOCKER

### Deploy Serverless


## 📚 Documentação

Para informações detalhadas sobre arquitetura, APIs e deployment, consulte a pasta `docs/`.

## 🛠️ Tecnologias Utilizadas

- **Mobile:** Flutter, Dart, SQLite, GPS, Camera
- **Backend:** Spring Boot, Node.js, PostgreSQL, RabbitMQ
- **Cloud:** ???
- **DevOps:** Docker

---

