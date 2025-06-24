// providers/email/local-email.provider.js
const EmailProviderInterface = require('../../interfaces/email-provider-interface');
const logger = require('../../utils/logger');

class LocalEmailProvider extends EmailProviderInterface {
    constructor() {
        super();
        this.name = 'local-email-provider';
        this.stats = {
            sent: 0,
            errors: 0,
            startTime: new Date()
        };
    }

    async sendEmail(emailData) {
        try {
            logger.info(`📧 [LOCAL] Enviando email para: ${emailData.to}`, {
                subject: emailData.subject,
                template: emailData.template
            });

            // Simular processamento de email
            await this.simulateEmailSending(emailData);

            this.stats.sent++;
            
            const result = {
                success: true,
                messageId: `local_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
                provider: this.name,
                recipient: emailData.to,
                subject: emailData.subject,
                sentAt: new Date().toISOString()
            };

            logger.info(`✅ [LOCAL] Email enviado com sucesso: ${result.messageId}`);
            return result;

        } catch (error) {
            this.stats.errors++;
            logger.error(`❌ [LOCAL] Erro ao enviar email:`, {
                error: error.message,
                recipient: emailData.to
            });
            throw error;
        }
    }

    async simulateEmailSending(emailData) {
        // Simular delay de processamento
        await new Promise(resolve => setTimeout(resolve, 100 + Math.random() * 300));
        
        // Simular chance de falha (2%)
        if (Math.random() < 0.02) {
            throw new Error('Simulação de falha no envio local');
        }

        // Log do "email" que seria enviado
        logger.debug(`📧 [LOCAL] Conteúdo do email:`, {
            to: emailData.to,
            subject: emailData.subject,
            template: emailData.template,
            variables: emailData.variables,
            body: emailData.body ? emailData.body.substring(0, 100) + '...' : null
        });
    }

    async testConnection() {
        try {
            logger.info('🧪 [LOCAL] Testando provedor local de email...');
            
            await this.simulateEmailSending({
                to: 'test@example.com',
                subject: 'Teste de Conexão',
                template: 'connection-test',
                variables: { test: true }
            });

            return {
                success: true,
                provider: this.name,
                status: 'connected',
                message: 'Provedor local funcionando corretamente'
            };

        } catch (error) {
            logger.error('❌ [LOCAL] Teste de conexão falhou:', error);
            return {
                success: false,
                provider: this.name,
                status: 'error',
                error: error.message
            };
        }
    }

    getConfig() {
        return {
            provider: this.name,
            type: 'local',
            stats: this.stats,
            features: ['template-support', 'variable-substitution']
        };
    }

    getStats() {
        return {
            ...this.stats,
            uptime: Date.now() - this.stats.startTime.getTime()
        };
    }
}

module.exports = LocalEmailProvider;