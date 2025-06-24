// interfaces/email-provider.interface.js
/**
 * Interface base para provedores de email
 */
class EmailProviderInterface {
    /**
     * Enviar email
     * @param {Object} emailData - Dados do email
     * @param {string} emailData.to - Destinatário
     * @param {string} emailData.subject - Assunto
     * @param {string} emailData.body - Corpo do email
     * @param {string} emailData.template - Template a ser usado
     * @param {Object} emailData.variables - Variáveis do template
     * @returns {Promise<Object>} Resultado do envio
     */
    async sendEmail(emailData) {
        throw new Error('Method sendEmail must be implemented');
    }

    /**
     * Testar conectividade
     * @returns {Promise<Object>} Status da conexão
     */
    async testConnection() {
        throw new Error('Method testConnection must be implemented');
    }

    /**
     * Obter configurações do provedor
     * @returns {Object} Configurações
     */
    getConfig() {
        throw new Error('Method getConfig must be implemented');
    }
}

module.exports = EmailProviderInterface;