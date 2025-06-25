// utils/dependency-injection.js
const logger = require('./logger');

// Provedores
const LocalEmailProvider = require('../providers/email/local-email-provider');
const AzureEmailProvider = require('../providers/email/azure-email-provider');
const LocalPushProvider = require('../providers/push/local-push-provider');
const AzurePushProvider = require('../providers/push/azure-push-provider');

class DependencyContainer {
    constructor() {
        this.services = new Map();
        this.initialized = false;
    }

    initialize() {
        if (this.initialized) {
            logger.warn('⚠️ Dependency container já foi inicializado');
            return;
        }

        try {
            this.registerEmailProvider();
            this.registerPushProvider();
            
            this.initialized = true;
            logger.info('✅ Dependency container inicializado', {
                emailProvider: this.get('emailProvider').constructor.name,
                pushProvider: this.get('pushProvider').constructor.name
            });

        } catch (error) {
            logger.error('❌ Erro ao inicializar dependency container:', error);
            throw error;
        }
    }

    registerEmailProvider() {
        const emailProviderType = process.env.EMAIL_PROVIDER || 'local';
        
        let emailProvider;
        switch (emailProviderType.toLowerCase()) {
            case 'azure':
                emailProvider = new AzureEmailProvider();
                logger.info('📧 Registrado Azure Email Provider');
                break;
            case 'local':
            default:
                emailProvider = new LocalEmailProvider();
                logger.info('📧 Registrado Local Email Provider');
                break;
        }
        
        this.register('emailProvider', emailProvider);
    }

    registerPushProvider() {
        const pushProviderType = process.env.PUSH_PROVIDER || 'local';
        
        let pushProvider;
        switch (pushProviderType.toLowerCase()) {
            case 'azure':
                pushProvider = new AzurePushProvider();
                logger.info('🔔 Registrado Azure Push Provider');
                break;
            case 'local':
            default:
                pushProvider = new LocalPushProvider();
                logger.info('🔔 Registrado Local Push Provider');
                break;
        }
        
        this.register('pushProvider', pushProvider);
    }

    register(name, service) {
        if (this.services.has(name)) {
            throw new Error(`Service ${name} já está registrado`);
        }
        
        this.services.set(name, service);
        logger.debug(`📦 Serviço registrado: ${name}`);
    }

    get(name) {
        if (!this.services.has(name)) {
            throw new Error(`Service ${name} não encontrado no container`);
        }
        
        return this.services.get(name);
    }

    has(name) {
        return this.services.has(name);
    }

    getAll() {
        return Array.from(this.services.keys());
    }

    // Métodos de conveniência
    getEmailProvider() {
        return this.get('emailProvider');
    }

    getPushProvider() {
        return this.get('pushProvider');
    }

    // Permitir trocar provedores em runtime (útil para testes)
    switchEmailProvider(providerType) {
        logger.info(`🔄 Trocando email provider para: ${providerType}`);
        
        let newProvider;
        switch (providerType.toLowerCase()) {
            case 'azure':
                newProvider = new AzureEmailProvider();
                break;
            case 'local':
                newProvider = new LocalEmailProvider();
                break;
            default:
                throw new Error(`Provedor de email desconhecido: ${providerType}`);
        }
        
        this.services.set('emailProvider', newProvider);
        logger.info(`✅ Email provider trocado para: ${newProvider.constructor.name}`);
    }

    switchPushProvider(providerType) {
        logger.info(`🔄 Trocando push provider para: ${providerType}`);
        
        let newProvider;
        switch (providerType.toLowerCase()) {
            case 'azure':
                newProvider = new AzurePushProvider();
                break;
            case 'local':
                newProvider = new LocalPushProvider();
                break;
            default:
                throw new Error(`Provedor de push desconhecido: ${providerType}`);
        }
        
        this.services.set('pushProvider', newProvider);
        logger.info(`✅ Push provider trocado para: ${newProvider.constructor.name}`);
    }

    // Obter informações sobre todos os provedores
    getProvidersInfo() {
        const emailProvider = this.getEmailProvider();
        const pushProvider = this.getPushProvider();
        
        return {
            email: {
                name: emailProvider.constructor.name,
                config: emailProvider.getConfig(),
                stats: emailProvider.getStats ? emailProvider.getStats() : null
            },
            push: {
                name: pushProvider.constructor.name,
                config: pushProvider.getConfig(),
                stats: pushProvider.getStats ? pushProvider.getStats() : null
            }
        };
    }

    // Testar conectividade de todos os provedores
    async testAllProviders() {
        const results = {
            timestamp: new Date().toISOString(),
            email: null,
            push: null,
            overall: false
        };

        try {
            // Testar email provider
            const emailProvider = this.getEmailProvider();
            results.email = await emailProvider.testConnection();
            
            // Testar push provider
            const pushProvider = this.getPushProvider();
            results.push = await pushProvider.testConnection();
            
            // Status geral
            results.overall = results.email.success && results.push.success;
            
            logger.info('🧪 Teste de todos os provedores concluído', {
                emailOk: results.email.success,
                pushOk: results.push.success,
                overall: results.overall
            });

        } catch (error) {
            logger.error('❌ Erro no teste dos provedores:', error);
            results.error = error.message;
        }

        return results;
    }

    // Reset (útil para testes)
    reset() {
        logger.info('🔄 Resetando dependency container');
        this.services.clear();
        this.initialized = false;
    }
}

// Singleton instance
const dependencyContainer = new DependencyContainer();
module.exports = dependencyContainer;