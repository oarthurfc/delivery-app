# Detalhamento dos Requisitos do Trabalho sobre Microsserviços (30 pontos)

## Índice

- [Serviço de Autenticação](#serviço-de-autenticação)
- [Serviço de Pedidos](#serviço-de-pedidos)
- [Serviço de Rastreamento](#serviço-de-rastreamento)
- [API Gateway](#api-gateway)
- [Arquitetura de Referência (Simplificada)](#arquitetura-de-referência-simplificada)
- [Dicas para Implementação](#dicas-para-implementação)
- [Avaliação Prática](#avaliação-prática)


## Serviço de Autenticação

### Gerenciamento seguro de identidade e acesso com JWT

- **Objetivo**: Prover autenticação e autorização seguras para os usuários (clientes e motoristas) do sistema, utilizando tokens JWT para acesso aos serviços distribuídos.

- **Funcionalidades principais**:
  - Implementar endpoint para **registro de usuários** (com validação de dados como email, senha, tipo de usuário)
  - Implementar endpoint para **login**, com verificação de credenciais e emissão de token JWT
  - Implementar endpoint para **validação de token JWT** (verificar se o token é válido e extrair claims)
  - Suporte à renovação de tokens (refresh tokens, opcional)

- **Tecnologia sugerida**: Spring Boot, Node.js ou Go

---


## Serviço de Pedidos

### CRUD de pedidos

- **Objetivo**: Criar uma API REST para gerenciar o ciclo de vida completo dos pedidos.
- **Funcionalidades principais**:
  - Criar novos pedidos com informações básicas (origem, destino, cliente, tipo de mercadoria)
  - Consultar pedidos por ID, cliente ou status
  - Atualizar status do pedido (em processamento, em rota, entregue, etc.)
  - Cancelar/remover pedidos
- **Tecnologia sugerida**: Spring Boot ou Express.js com um banco de dados relacional como PostgreSQL

### Cálculo de rotas otimizadas

- **Objetivo**: Integrar com uma API externa de mapas para calcular a melhor rota entre pontos de coleta e entrega.
- **Funcionamento básico**:
  - Receber pontos de origem e destino
  - Fazer requisição para a API externa (OpenStreetMap, Mapbox ou similar)
  - Retornar a rota otimizada, distância e tempo estimado
- **Dica de implementação**: Comece com uma API gratuita como o OSRM (Open Source Routing Machine) para desenvolvimento

## Serviço de Rastreamento

### Atualização e consulta de localização em tempo real

- **Objetivo**: Criar um serviço que permita atualizações eficientes da localização dos veículos e consultas em tempo real.

- **Funcionalidades principais**:
  - Implementar endpoint para motoristas enviarem atualizações de localização (latitude, longitude, timestamp)
  - Implementar endpoint para clientes consultarem a localização atual de sua entrega
- **Tecnologia sugerida**: Spring Boot, Node ou Go

### Integração com sistema de geolocalização

- **Objetivo**: Armazenar e processar dados de localização para uso em consultas e análises.
- **Funcionamento básico**:
  - Armazenar coordenadas geográficas com timestamps
  - Implementar consultas simples como "encontrar entregas próximas"
  - Calcular distâncias entre pontos

- **Dica de implementação**: Use um banco que suporte operações geoespaciais como MongoDB ou PostgreSQL com extensão PostGIS

## API Gateway

### Roteamento de requisições

- **Objetivo**: Criar um ponto de entrada único que direciona requisições para os microsserviços apropriados.
- **Funcionamento básico**:
  - Mapear rotas de API para os serviços internos (/pedidos, /rastreamento, /notificacoes)
  - Lidar com autenticação e autorização (JWT)

- **Tecnologia sugerida**: Spring Cloud Gateway, Kong Gateway (versão gratuita) ou implementação simples com Express.js


## Arquitetura de Referência (Simplificada)

```text
                                Cliente/App Móvel
                                      │
                                      ▼
┌───────────────────────────────────────────────────────────────────────┐
│                            API Gateway                                │
│              Autenticação, Roteamento, Pedidos e Notificação          │ 
└─────┬──────────────────┬──────────────────────┬─────────────────┬─────┘
      ▼                  ▼                      ▼                 ▼
┌──────────┐      ┌─────────────┐       ┌─────────────┐   ┌─────────────┐
│ Serviço  │      │   Serviço   │       │ Serviço     │   | Serviço de  |
│ Pedidos  │      │Rastreamento │       │Notificacação│   | Autenticação|
└──────────┘      └─────────────┘       └─────────────┘   └─────────────┘

```

## Dicas para Implementação

1. **Comece simples**: Implemente primeiro uma versão básica de cada serviço antes de adicionar recursos avançados.

2. **Documente as APIs**: Use Swagger/OpenAPI para documentar os endpoints de cada serviço.

3. **Comunicação entre serviços**:
    - Síncrona: REST para operações simples
    - Assíncrona: RabbitMQ para eventos e operações de longa duração
    
4. **Teste local**: Crie scripts para executar todo o sistema localmente.

## Avaliação Prática

O trabalho será avaliado considerando:

1. **Funcionalidade básica**: Cada serviço deve implementar as funcionalidades essenciais descritas.

2. **Integração**: Os serviços devem se comunicar corretamente entre si.

3. **Resiliência**: O sistema deve lidar adequadamente com falhas temporárias (retry, circuit breaker).

4. **Documentação**: Cada serviço deve ter sua API documentada e instruções de execução.

---
