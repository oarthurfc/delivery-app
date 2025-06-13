# Detalhamento dos Requisitos do Trabalho sobre Desenvolvimento em Nuvem

## Índice

- [Visão Geral da Arquitetura Serverless](#visão-geral-da-arquitetura-serverless)
- [API Gateway Serverless](#api-gateway-serverless)
- [Funções Serverless para Lógica de Negócio](#funções-serverless-para-lógica-de-negócio)
- [Banco de Dados Serverless](#banco-de-dados-serverless)
- [Mensageria Serverless](#mensageria-serverless)
- [Cache Serverless](#cache-serverless)
- [Armazenamento de Arquivos](#armazenamento-de-arquivos)
- [CI/CD para Serverless](#cicd-para-serverless)
- [Arquitetura de Referência (Serverless)](#arquitetura-de-referência-serverless)
- [Vantagens da Abordagem Serverless](#vantagens-da-abordagem-serverless)
- [Considerações para Implementação](#considerações-para-implementação)

## Visão Geral da Arquitetura Serverless

Nesta abordagem, substituiremos os microsserviços tradicionais por funções serverless e serviços gerenciados, mantendo a mesma funcionalidade do sistema original, mas com maior escalabilidade automática e menor necessidade de gerenciamento de infraestrutura. Nesta arquitetura serverless temos todos os benefícios da abordagem de microsserviços (independência, isolamento, escalabilidade), mas com menor sobrecarga operacional e melhor relação custo-benefício, sendo ideal em projetos que querem focar no desenvolvimento das funcionalidades sem se preocupar com a infraestrutura subjacente.

## API Gateway Serverless

- **Tecnologia sugerida**: AWS API Gateway, Azure API Management ou Google Cloud Endpoints
- **Funcionalidades principais**:
  - Definição de rotas para diferentes funcionalidades (pedidos, rastreamento, notificações)
  - Autenticação e autorização via JWT
  - Throttling e quotas para controle de tráfego
  - Cache de respostas para consultas frequentes

### Vantagens de API Gateway Serverless

- Escala automaticamente conforme o tráfego
- Gerencia automaticamente certificados SSL
- Cobrança baseada em requisições, não em tempo de execução

## Funções Serverless para Lógica de Negócio

### Serviço de Pedidos

- **Funções**:
  - `createOrder`: Criar novo pedido
  - `getOrder`: Consultar pedido por ID
  - `updateOrderStatus`: Atualizar status do pedido
  - `listOrders`: Listar pedidos com filtros
  - `calculateRoute`: Integrar com API de mapas para cálculo de rotas

### Serviço de Rastreamento

- **Funções**:
  - `updateLocation`: Receber atualizações de localização
  - `getLocationHistory`: Consultar histórico de localização
  - `getCurrentLocation`: Obter localização atual de uma entrega

### Serviço de Notificações

- **Funções**:
  - `sendPushNotification`: Enviar notificação push
  - `updateNotificationPreferences`: Atualizar preferências
  - `processNotificationQueue`: Processar fila de notificações

### Tecnologia sugerida

- AWS Lambda, Google Cloud Functions ou Azure Functions
- Arquivos de configuração para definir gatilhos, permissões e recursos

## Banco de Dados Serverless

- **Tecnologia sugerida**:
  - Amazon DynamoDB, Azure Cosmos DB ou Google Cloud Firestore
  - Esquema sem servidor (schemaless) com índices secundários para consultas eficientes

### Modelagem de dados

- Tabela de Pedidos (OrderID como chave primária)
- Tabela de Localizações (OrderID + Timestamp como chave composta)
- Tabela de Preferências de Notificação (UserID como chave primária)

### Vantagens de bancos de dados serverless

- Escala automaticamente tanto para leitura quanto para escrita
- Baixa latência global
- Pay-per-use sem mínimos fixos

## Mensageria Serverless

- **Tecnologia sugerida**:
  - AWS SQS/SNS, Google Cloud Pub/Sub ou Azure Service Bus
  - Tópicos para diferentes tipos de eventos

### Eventos principais

- `OrderStatusChanged`: Disparado quando o status de um pedido é alterado
- `LocationUpdated`: Disparado quando a localização é atualizada
- `NotificationTriggered`: Disparado quando uma notificação deve ser enviada

### Vantagens da mensageria serverless

- Desacoplamento completo entre serviços
- Processamento assíncrono de eventos
- Entrega garantida de mensagens

## Cache Serverless

- **Tecnologia sugerida**:
  - Amazon ElastiCache Serverless, Azure Cache for Redis ou Firebase Remote Config
  - Políticas de expiração automática

### Dados para cache

- Informações de rotas calculadas
- Status atual de entregas
- Tokens de autenticação

## Armazenamento de Arquivos

- **Tecnologia sugerida**:
  - Amazon S3, Google Cloud Storage ou Azure Blob Storage
  - Imagens com prova de entrega e documentação

### Integrações

- Uploads diretos do aplicativo móvel
- Integração com CDN para entrega de conteúdo

## CI/CD para Serverless

- **Tecnologia sugerida**:
  - AWS SAM, Serverless Framework ou Google Cloud Deployment Manager
  - GitHub Actions para automação de deploys

### Pipeline

- Teste de funções
- Deploy progressivo com possibilidade de rollback
- Versionamento de funções

## Arquitetura de Referência (Serverless)

```text
┌───────────────┐       ┌────────────────┐
│  Aplicativos  │ ─────►│   API Gateway  │
│    Móveis     │       │   Serverless   │
└───────────────┘       └────────┬───────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌────────▼────────┐     ┌────────▼────────┐     ┌────────▼────────┐
│  Funções Lambda │     │  Funções Lambda │     │  Funções Lambda │
│     Pedidos     │     │   Rastreamento  │     │   Notificações  │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  DynamoDB ou    │     │  Sistema de     │     │    SQS/SNS      │
│  Banco NoSQL    │◄────┤  Mensageria     │◄────┤    ou similar   │
│   Serverless    │     │   Serverless    │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         ▲                                               ▲
         │                                               │
         │                                               │
┌────────┴────────┐                             ┌────────┴────────┐
│  Cache Redis    │                             │ Armazenamento   │
│   Serverless    │                             │  S3 ou similar  │
└─────────────────┘                             └─────────────────┘

```

## Vantagens da Abordagem Serverless

1. **Custo otimizado**: Paga-se apenas pelo tempo de execução das funções e recursos utilizados

2. **Escalabilidade automática**: Escala de zero a milhares de instâncias sem intervenção manual

3. **Menor operação**: Sem necessidade de gerenciar servidores, patches, sistemas operacionais

4. **Alta disponibilidade**: Serviços gerenciados com SLAs garantidos pelo provedor de nuvem

5. **Agilidade**: Foco no desenvolvimento do código de negócio, não na infraestrutura

## Considerações para Implementação

1. **Cold starts**: Primeiras execuções podem ter latência maior; implemente estratégias para minimizar

2. **Limites de execução**: Funções serverless têm limites de tempo (geralmente 5-15 minutos); desenhe processos de longa duração adequadamente

3. **Observabilidade**: Implemente logs detalhados e rastreamento de transações distribuídas

4. **Gerenciamento de estado**: Armazene estado em serviços externos, não nas funções que são efêmeras

5. **Local development**: Use emuladores locais (AWS SAM, Serverless Framework) para desenvolvimento e testes
  
