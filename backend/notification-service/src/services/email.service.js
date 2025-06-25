// services/email.service.js
const dependencyContainer = require('../utils/dependency-injection');
const logger = require('../utils/logger');

class EmailService {
    constructor() {
        this.stats = {
            processed: 0,
            errors: 0,
            startTime: new Date()
        };
    }

    get emailProvider() {
        return dependencyContainer.getEmailProvider();
    }

    /**
     * Processar mensagem da fila de emails
     */
    async processEmailMessage(messageData) {
        try {
            logger.info(`📧 Processando mensagem de email:`, {
                messageId: messageData.messageId,
                type: messageData.type,
                recipient: messageData.to
            });

            // Validar dados da mensagem
            this.validateEmailMessage(messageData);

            // Preparar dados do email
            const emailData = this.prepareEmailData(messageData);

            // Enviar via provider configurado
            const result = await this.emailProvider.sendEmail(emailData);

            this.stats.processed++;
            
            logger.info(`✅ Email processado com sucesso:`, {
                messageId: messageData.messageId,
                provider: result.provider,
                recipient: result.recipient
            });

            return {
                success: true,
                messageId: messageData.messageId,
                result
            };

        } catch (error) {
            this.stats.errors++;
            logger.error(`❌ Erro ao processar email:`, {
                messageId: messageData.messageId,
                error: error.message
            });
            throw error;
        }
    }

    validateEmailMessage(messageData) {
        const required = ['to', 'type'];
        const missing = required.filter(field => !messageData[field]);
        
        if (missing.length > 0) {
            throw new Error(`Campos obrigatórios ausentes: ${missing.join(', ')}`);
        }

        // Validar email
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(messageData.to)) {
            throw new Error(`Email inválido: ${messageData.to}`);
        }
    }

    prepareEmailData(messageData) {
        const emailData = {
            to: messageData.to,
            subject: messageData.subject,
            body: messageData.body,
            template: messageData.template,
            variables: messageData.variables || {}
        };

        // Se não tiver subject/body, usar template baseado no tipo
        if (!emailData.subject || !emailData.body) {
            const templateData = this.getTemplateByType(messageData.type, messageData);
            emailData.subject = emailData.subject || templateData.subject;
            emailData.body = emailData.body || templateData.body;
            emailData.template = emailData.template || templateData.template;
        }

        return emailData;
    }

    getTemplateByType(type, messageData) {
        // Determinar se é para motorista baseado nas variáveis enviadas
        const isDriver = messageData.variables && messageData.variables.recipientType === 'DRIVER';
        
        const templates = {
            'ORDER_COMPLETED': {
                subject: isDriver ? '✅ Entrega concluída - Pedido #{{orderId}}' : '🎉 Pedido #{{orderId}} entregue com sucesso!',
                body: isDriver ? this.getDriverOrderCompletedBody() : this.getCustomerOrderCompletedBody(),
                template: isDriver ? 'driver-order-completed' : 'order-completed'
            },
            'order_completed': { // Manter compatibilidade
                subject: isDriver ? '✅ Entrega concluída - Pedido #{{orderId}}' : '🎉 Pedido #{{orderId}} entregue com sucesso!',
                body: isDriver ? this.getDriverOrderCompletedBody() : this.getCustomerOrderCompletedBody(),
                template: isDriver ? 'driver-order-completed' : 'order-completed'
            },
            'ORDER_CREATED': {
                subject: '📦 Pedido #{{orderId}} criado com sucesso!',
                body: this.getOrderCreatedBody(),
                template: 'order-created'
            },
            'order_created': { // Manter compatibilidade
                subject: '📦 Pedido #{{orderId}} criado com sucesso!',
                body: this.getOrderCreatedBody(),
                template: 'order-created'
            },
            'promotional': {
                subject: '{{title}}',
                body: '{{content}}',
                template: 'promotional-campaign'
            },
            'welcome': {
                subject: 'Bem-vindo ao nosso serviço de delivery! 🚀',
                body: 'Seja bem-vindo! Estamos prontos para suas entregas.',
                template: 'welcome'
            }
        };

        const template = templates[type] || templates['welcome'];
        
        // Substituir variáveis básicas no subject e body
        const subject = this.replaceVariables(template.subject, messageData.variables || messageData);
        const body = this.replaceVariables(template.body, messageData.variables || messageData);

        return {
            subject,
            body,
            template: template.template
        };
    }

    /**
     * Template detalhado para pedido completado - CLIENTE
     */
    getCustomerOrderCompletedBody() {
        return `Olá {{customerName}}!

🎉 Temos uma ótima notícia para você!

Seu pedido #{{orderId}} foi entregue com sucesso!

📋 Detalhes da entrega:
• Descrição: {{orderDescription}}
• Endereço de entrega: {{deliveryAddress}}
• Data/hora da entrega: {{completedAt}}

✅ Sua entrega foi confirmada e já está disponível no endereço informado.

Obrigado por confiar em nosso serviço de delivery!

---
Equipe de Entregas
📞 Precisa de ajuda? Entre em contato conosco!`;
    }

    /**
     * Template detalhado para pedido completado - MOTORISTA
     */
    getDriverOrderCompletedBody() {
        return `Olá {{customerName}}!

✅ Entrega finalizada com sucesso!

Você concluiu a entrega do pedido #{{orderId}}.

📋 Detalhes da entrega:
• Descrição: {{orderDescription}}
• Retirada: {{originAddress}}
• Entrega: {{deliveryAddress}}
• Finalizada em: {{completedAt}}

💰 A entrega foi confirmada e será computada em seus ganhos.

Parabéns pelo excelente trabalho!

---
Equipe de Entregas
🚛 Continue assim e obtenha mais entregas!`;
    }

    /**
     * Template para pedido criado (compatibilidade)
     * @deprecated Use getCustomerOrderCreatedBody
     */
    getOrderCompletedBody() {
        return this.getCustomerOrderCompletedBody();
    }

    /**
     * Template para pedido criado
     */
    getOrderCreatedBody() {
        return `Olá {{customerName}}!

📦 Seu pedido foi criado com sucesso!

Pedido #{{orderId}} está sendo processado e em breve será atribuído a um entregador.

📋 Detalhes do pedido:
• Descrição: {{orderDescription}}
• Endereço de entrega: {{deliveryAddress}}
• Criado em: {{createdAt}}

🚀 Você receberá atualizações sobre o status do seu pedido por email e push notifications.

Obrigado por escolher nosso serviço!

---
Equipe de Entregas`;
    }

    /**
     * Substituir variáveis no texto usando {{variavel}}
     */
    replaceVariables(text, variables) {
        if (!text || !variables) return text;
        
        let result = text;
        
        // Substituir variáveis principais
        result = result.replace(/\{\{(\w+)\}\}/g, (match, key) => {
            // Se a variável existe, usar seu valor
            if (variables[key] !== undefined && variables[key] !== null) {
                return variables[key];
            }
            
            // Valores padrão para campos importantes
            const defaults = {
                customerName: 'Cliente',
                orderDescription: 'Sua entrega',
                deliveryAddress: 'Endereço não informado',
                completedAt: this.formatDateTime(new Date()),
                createdAt: this.formatDateTime(new Date())
            };
            
            return defaults[key] || match;
        });
        
        // Formatar data se vier do Java (LocalDateTime.toString())
        result = this.formatJavaDateTimes(result, variables);
        
        return result;
    }

    /**
     * Formatar datas que vem do Java (formato ISO)
     */
    formatJavaDateTimes(text, variables) {
        if (variables.completedAt && typeof variables.completedAt === 'string') {
            try {
                const date = new Date(variables.completedAt);
                const formatted = this.formatDateTime(date);
                text = text.replace(variables.completedAt, formatted);
            } catch (error) {
                logger.warn('Erro ao formatar data completedAt:', variables.completedAt);
            }
        }
        
        if (variables.createdAt && typeof variables.createdAt === 'string') {
            try {
                const date = new Date(variables.createdAt);
                const formatted = this.formatDateTime(date);
                text = text.replace(variables.createdAt, formatted);
            } catch (error) {
                logger.warn('Erro ao formatar data createdAt:', variables.createdAt);
            }
        }
        
        return text;
    }

    /**
     * Formatar data e hora para exibição
     */
    formatDateTime(date) {
        if (!date || !(date instanceof Date)) return 'Data não disponível';
        
        return date.toLocaleString('pt-BR', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            timeZone: 'America/Sao_Paulo'
        });
    }

    async testConnection() {
        return await this.emailProvider.testConnection();
    }

    getStats() {
        const providerStats = this.emailProvider.getStats ? this.emailProvider.getStats() : {};
        
        return {
            service: 'email',
            ...this.stats,
            uptime: Date.now() - this.stats.startTime.getTime(),
            provider: providerStats
        };
    }
}

module.exports = new EmailService();