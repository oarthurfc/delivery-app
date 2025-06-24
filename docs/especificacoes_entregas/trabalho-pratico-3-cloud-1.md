# Trabalho de Laboratório de Desenvolvimento de Aplicações Distribuídas e Móveis

## ETAPA 3: Sistema de Pedidos de Transporte de Mercadorias com Arquitetura Serverless (30 pontos)

### Contextualização das Etapas do Trabalho

Este trabalho representa a **terceira e última etapa** de um projeto integrado de desenvolvimento de aplicações distribuídas:

- **ETAPA 1 - Aplicação Móvel**: Desenvolvimento da interface mobile para clientes e transportadores solicitarem e gerenciarem pedidos de transporte
- **ETAPA 2 - Backend em Microserviços**: Implementação da arquitetura de microserviços para gerenciar o core business (pedidos, usuários, etc.)
- **ETAPA 3 - Funcionalidades Serverless** (ATUAL): Implementação de funcionalidades complementares utilizando arquitetura serverless, filas e pub/sub para processamento assíncrono de eventos

### Objetivo da Etapa Atual
Expandir o sistema desenvolvido nas etapas anteriores, adicionando funcionalidades de comunicação e notificação através de uma arquitetura serverless que se integre aos microserviços já desenvolvidos, garantindo escalabilidade e desacoplamento para operações assíncronas.

### Integração com Etapas Anteriores
O sistema serverless desta etapa deve:
- **Integrar-se** com o backend de microserviços da Etapa 2 através de eventos e APIs
- **Complementar** a experiência do usuário da aplicação móvel da Etapa 1 com notificações e comunicações automatizadas
- **Manter** a consistência de dados e identidade visual estabelecidas nas etapas anteriores

### Contexto do Sistema Atual
Com base no aplicativo móvel e microserviços já desenvolvidos, você agora deve implementar a camada de processamento assíncrono que será responsável por:
- Reagir a eventos gerados pelo sistema de microserviços
- Processar comunicações automáticas (e-mails, notificações)
- Gerenciar campanhas promocionais em massa
- Garantir a entrega confiável de mensagens

### Funcionalidades Obrigatórias

![Diagrama das Funcionalidades](https://uml.planttext.com/plantuml/svg/hLTDRnit4BtlhvZeuWYfODbkt7O15t7yaHIm0wTIBwq0WzwbrqIvv9OVGfiW_wL13qKBv1Jqqkl-iGuvIsbNjbCNg6735Zapd9dtvf7Edbd7ZFErp1wv6rvpQ2GJAdF2IGupOHsl6PGSveOfssZZE4pWrAj2QCMaA5d9BSouMN8ZkRNm-CInXi7UECksu9XV2oNQtzlVD9JQGeD7YK8qJ3bkizud61qs3Pot7vTSBbGNOsSy0cO1TuQcvw8mskAH65dRbVakcP_FXjOdIuw_NdlkUToFVmrDpbXzLR9ObSEoGiXrHHILJ8PkhxGJrw9WmIUsG1HqHDpuPIEDcWavi8ehGwCBVxKzyrSmruqeRBJ29LmPcXqpnwwOfJ37pxFiu6034jZ9uLI4JszOrtuE5xmKfOQ3WomBtPvyZRtAuKWhPp0Wxbnt7j14ounXEvOC4SUUPkUpu77yF8T3vyaCgUEyHMIJ0zd43kSXSudT0Hu0q30YcyjqIAb7cT8Ot8ZgnkKGSShXxK915-vIb3cCTdRtHf-5nK8AjE2q-ldJ_MvrbJvjVF7bLxJXHCqnmRh1nTtfxjF9T7-oip_VcUPxqtmw_NwqKE-ohEI38cFgeGR2EqVQYwhY9XLnguPrZpg68EilZ2wGEAmc5sQOv18HGB1KHnd4v2-Q07YrNYAO3fSOcpvcW5yTEpkuNfpCOPlIiDjlHVaE7YFWE5k5hXl9dRRZw1MWwDLn76tMI0q34s4H0xKKYBwtDwjC0xcZTH-hKKSbR7uXVVkXr8yMAkRDGKCQJMXCG2007GBG8U4uP5-WnyOfy0IhvuqKwiUDz0BflkKLYf5X87M5hUnt4ll4fUKn-zZ1aqaShGSqRnipzBM-lsC1FU1tnOlZcw_01XHAb4xi4IRGSmWGKpuKwuXO7FV25-d2EXv1G06Wbzqc18VMUgGNOd620y0h5WQPm618xJ3LlFsxrA5p8SYA7p4QzQkVrcgC_iVCPea8f-kP7wJMiHAZKWsKcogpyDEVpJHSjuLk5nKCXvofco2MHjSwxWeRTMuBlb7jXoBGWa7HsI4lavdCVhXZsEyql9NB7TJg9CgccOojjRmAIa1C7MSRD3j3LiSBDlds0oUZ5Sa6iGRoEUll05xK-K9Du4mNwpiWB9mQ_fDl_yGMnaEzZQilCOdsen5579zkGCB64P86x_nEofG6XfTna3ZITZfCOQNeZbUM9abxONo3w1wbRbmONWjVRmmGtMozUw9EKV2k88zBQeeTtLAWSwuigz2buSRgZbrieP3bM88Djm9cnMt3iL9XepyTsDUxLLzbHA7fvVblQeKOLw7Cv3Gc3TeiFSXMwD7CR-h7fyh7MH1CNrelRrSUEKwD3sQXTYhxsd2qgapxtZsqODDbPxli7b1qpsLOybm7nkDtglq_rCkal1_gDDw0evbgJH3ZX9KcNPIVADUbv8f-SWyezyfeLXRCkZ5fqZsNKjt-uN1ycEthp60-ptHbuqZ6Tbd00rILnkorntSTwLcuFS8z5jVdx6T6AoIFTqdYLX1uZ1XKHED0-_QzGRrhVxKaNzrJe_VY-oxPU2VekRUYLE-LjweD6urFOHjV9xtYicVO4Fo_uHy0)

#### 1. Processamento de Finalização de Pedido
Quando um contratado finalizar um pedido de entrega **através do app móvel** (que comunica com os microserviços), o sistema serverless deve ser **acionado automaticamente** para:

**1.1 Notificação de Avaliação**
- Receber evento de conclusão do pedido dos microserviços
- Enviar notificação ao cliente solicitante através do app móvel
- Registrar o envio da notificação para auditoria

**1.2 Envio de E-mail de Resumo**
- Processar dados do pedido obtidos via API dos microserviços
- Enviar e-mail simultaneamente para cliente e contratado
- Conteúdo do e-mail deve incluir:
  - Dados completos do pedido (integrados dos microserviços)
  - Call-to-action para nova solicitação (app móvel)

#### 2. Sistema de Notificações Promocionais
Desenvolver sistema independente de campanhas que utilize dados dos microserviços:

**2.1 Segmentação Inteligente**
- Consumir dados de clientes dos microserviços de usuários
- Desejavel criar grupos dinâmicos baseados em:
  - Histórico de pedidos (frequência, valor médio)
  - Localização geográfica
  - Comportamento no app móvel
  - Sazonalidade de uso

**2.2 Campanhas Promocionais**
- Envio de notificações para o app móvel
- Segmentação por grupos de interesse

### Requisitos Técnicos Específicos

#### Integração Obrigatória
- **Event-Driven Architecture**: Os microserviços devem publicar eventos que acionam as funções serverless
- **API Integration**: Funções serverless devem consumir APIs dos microserviços quando necessário
- **Shared Database**: Acesso aos mesmos dados utilizados pelos microserviços (com permissões adequadas)
- **Authentication**: Manter consistência de autenticação/autorização entre as camadas

#### Arquitetura Serverless
- **Serverless Functions**: Implementação de todas as funcionalidades como functions
- **Event Triggers**: Acionamento automático via eventos dos microserviços
- **Message Queues**: Filas para garantir processamento confiável
- **Pub/Sub Topics**: Tópicos para campanhas promocionais

### Entregáveis Específicos da Etapa 3

1. **Código Fonte e Configuração**
   - Funções serverless implementadas
   - Configuração de filas, tópicos e triggers
   - Scripts de integração com microserviços

2. **Demonstração Integrada**
   - Video de demonstração completa: App → Microserviços → Serverless
   - Evidências de funcionamento das notificações

### Observações Importantes para a Etapa Final

- **Reutilize** ao máximo os componentes das etapas anteriores
- **Mantenha** a consistência de UX/UI estabelecida no app móvel
- **Preserve** a integridade dos dados dos microserviços

### Entrega Final do Projeto Completo
Ao final desta etapa, você terá um sistema completo de transporte de mercadorias com:
- ✅ **Frontend móvel** nativo e responsivo
- ✅ **Backend robusto** em microserviços
- ✅ **Processamento assíncrono** serverless e escalável
