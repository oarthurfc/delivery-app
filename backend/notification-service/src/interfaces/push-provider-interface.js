// interfaces/push-provider.interface.js
/**
 * Interface base para provedores de push notification
 */
class PushProviderInterface {
    /**
     * Enviar notificação push
     * @param {Object} pushData - Dados da notificação
     * @param {string|Array} pushData.userId - ID do usuário ou array de IDs
     * @param {string} pushData.title - Título da notificação
     * @param {string} pushData.body - Corpo da notificação
     * @param {Object} pushData.data - Dados adicionais
     * @param {string} pushData.deepLink - Deep link da notificação
     * @returns {Promise<Object>} Resultado do envio
     */
    async sendPushNotification(pushData) {
        throw new Error('Method sendPushNotification must be implemented');
    }

    /**
     * Enviar notificação para múltiplos usuários
     * @param {Object} broadcastData - Dados da notificação broadcast
     * @param {Array} broadcastData.userIds - Array de IDs dos usuários
     * @param {string} broadcastData.title - Título
     * @param {string} broadcastData.body - Corpo
     * @param {Object} broadcastData.data - Dados adicionais
     * @returns {Promise<Object>} Resultado do envio
     */
    async sendBroadcast(broadcastData) {
        throw new Error('Method sendBroadcast must be implemented');
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

module.exports = PushProviderInterface;