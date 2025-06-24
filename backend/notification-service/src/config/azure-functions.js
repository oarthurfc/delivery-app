// config/azure-functions.js - CONFIGURAÇÃO REAL
const axios = require('axios');
const logger = require('../utils/logger');

class AzureFunctionsConfig {
    constructor() {
        this.baseUrl = process.env.AZURE_FUNCTIONS_BASE_URL || 'http://localhost:7071';
        this.apiKey = process.env.AZURE_FUNCTIONS_API_KEY || '';
        this.timeout = parseInt(process.env.AZURE_FUNCTIONS_TIMEOUT) || 30000;
        
        // CONFIGURAÇÃO REAL: Apenas uma função
        this.endpoints = {
            emailSender: '/api/email-sender'  // A única função que vocês têm
        };
        
        // Configurar cliente HTTP
        this.client = axios.create({
            baseURL: this.baseUrl,
            timeout: this.timeout,
            headers: {
                'Content-Type': 'application/json',
                'User-Agent': 'notification-service/1.0.0'
            }
        });
        
        // NÃO usar header - Azure Functions espera code no query string
        // (baseado no que seu amigo passou)
        
        this.setupInterceptors();
    }
    
    setupInterceptors() {
        // Request interceptor
        this.client.interceptors.request.use(
            (config) => {
                logger.debug(`🌐 Azure Functions Request: ${config.method?.toUpperCase()} ${config.url}`, {
                    url: config.url,
                    method: config.method,
                    timeout: config.timeout,
                    hasApiKey: !!this.apiKey,
                    authMethod: this.apiKey ? 'query string (code)' : 'anonymous'
                });
                return config;
            },
            (error) => {
                logger.error('❌ Azure Functions Request Error:', error);
                return Promise.reject(error);
            }
        );
        
        // Response interceptor
        this.client.interceptors.response.use(
            (response) => {
                logger.debug(`✅ Azure Functions Response: ${response.status}`, {
                    status: response.status,
                    statusText: response.statusText,
                    url: response.config.url,
                    executionTime: response.headers['x-ms-execution-time'] || 'unknown'
                });
                return response;
            },
            (error) => {
                if (error.response) {
                    const status = error.response.status;
                    let errorMessage = error.response.data?.error || error.response.statusText;
                    
                    if (status === 401) {
                        errorMessage = 'Authentication failed - check API key (code parameter)';
                    } else if (status === 404) {
                        errorMessage = 'Azure Function email-sender not found';
                    } else if (status === 500) {
                        errorMessage = 'Azure Function internal error';
                    }
                    
                    logger.error(`❌ Azure Functions Error: ${status}`, {
                        status,
                        statusText: error.response.statusText,
                        url: error.config?.url,
                        error: errorMessage,
                        data: error.response.data
                    });
                } else if (error.request) {
                    logger.error(`❌ Azure Functions Network Error`, {
                        url: error.config?.url,
                        code: error.code,
                        message: error.message
                    });
                } else {
                    logger.error('❌ Azure Functions Config Error:', error.message);
                }
                return Promise.reject(error);
            }
        );
    }
    
    /**
     * Chamar a única Azure Function: email-sender
     */
    async callEmailSender(emailData, requestType = 'email') {
        try {
            const endpoint = this.endpoints.emailSender;
            
            logger.info(`📞 Chamando Azure Function: email-sender`, {
                endpoint,
                requestType,
                recipient: emailData.to,
                hasApiKey: !!this.apiKey
            });
            
            // Preparar URL com query string se tiver API key
            let url = endpoint;
            const params = {};
            
            if (this.apiKey) {
                params.code = this.apiKey;
            }
            
            // Preparar payload baseado no tipo de notificação
            const payload = this.preparePayload(emailData, requestType);
            
            // Fazer requisição para Azure Function
            const response = await this.client.post(url, payload, { params });
            
            return {
                success: true,
                data: response.data,
                status: response.status,
                executionTime: response.headers['x-ms-execution-time']
            };
            
        } catch (error) {
            logger.error(`❌ Falha em Azure Function email-sender:`, {
                error: error.message,
                status: error.response?.status,
                hasApiKey: !!this.apiKey
            });
            
            throw new Error(`Azure Function email-sender falhou: ${error.message}`);
        }
    }
    
    /**
     * Preparar payload baseado no tipo de requisição
     */
    preparePayload(data, requestType) {
        const basePayload = {
            timestamp: new Date().toISOString(),
            source: 'notification-service',
            type: requestType
        };
        
        if (requestType === 'email') {
            return {
                ...basePayload,
                to: data.to,
                subject: data.subject,
                body: data.body,
                template: data.template,
                variables: data.variables || {},
                from: {
                    name: process.env.EMAIL_FROM_NAME || 'Delivery Notification Service',
                    email: process.env.EMAIL_FROM_ADDRESS || 'noreply@delivery.com'
                }
            };
        } else if (requestType === 'push') {
            return {
                ...basePayload,
                userIds: Array.isArray(data.userId) ? data.userId : [data.userId],
                title: data.title,
                body: data.body,
                data: data.data || {},
                deepLink: data.deepLink
            };
        } else if (requestType === 'test') {
            return {
                ...basePayload,
                test: true,
                message: 'Testing connectivity with Azure Functions'
            };
        }
        
        return { ...basePayload, ...data };
    }
    
    /**
     * Enviar email via Azure Function
     */
    async sendEmail(emailData) {
        return this.callEmailSender(emailData, 'email');
    }
    
    /**
     * Enviar push notification via Azure Function
     * (se a função suportar múltiplos tipos)
     */
    async sendPushNotification(pushData) {
        return this.callEmailSender(pushData, 'push');
    }
    
    /**
     * Testar conectividade com Azure Functions
     */
    async testConnection() {
        try {
            logger.info('🧪 Testando conectividade com Azure Functions...');
            
            const testData = {
                test: true,
                timestamp: new Date().toISOString(),
                source: 'notification-service'
            };
            
            const response = await this.callEmailSender(testData, 'test');
            
            logger.info('✅ Teste de conectividade com Azure Functions bem-sucedido', {
                status: response.status,
                baseUrl: this.baseUrl,
                executionTime: response.executionTime,
                hasApiKey: !!this.apiKey
            });
            
            return {
                success: true,
                status: response.status,
                baseUrl: this.baseUrl,
                endpoint: this.endpoints.emailSender,
                hasApiKey: !!this.apiKey,
                authMethod: this.apiKey ? 'Query string (code parameter)' : 'Anonymous',
                response: response.data,
                executionTime: response.executionTime
            };
            
        } catch (error) {
            logger.error('❌ Teste de conectividade com Azure Functions falhou', {
                error: error.message,
                baseUrl: this.baseUrl,
                hasApiKey: !!this.apiKey
            });
            
            return {
                success: false,
                error: error.message,
                baseUrl: this.baseUrl,
                endpoint: this.endpoints.emailSender,
                hasApiKey: !!this.apiKey,
                authMethod: this.apiKey ? 'Query string (code parameter)' : 'Anonymous',
                status: 'CONNECTION_FAILED'
            };
        }
    }
    
    /**
     * Verificar saúde das Azure Functions
     */
    async healthCheck() {
        try {
            // Tentar uma requisição GET simples para verificar se está rodando
            const url = `${this.baseUrl}${this.endpoints.emailSender}`;
            const params = this.apiKey ? { code: this.apiKey } : {};
            
            const response = await axios.get(url, { 
                timeout: 5000,
                params
            });
            
            return {
                available: true,
                status: response.status,
                baseUrl: this.baseUrl,
                endpoint: this.endpoints.emailSender
            };
            
        } catch (error) {
            // Se 405 (Method Not Allowed), significa que está rodando mas só aceita POST
            if (error.response?.status === 405) {
                return {
                    available: true,
                    status: 'running',
                    baseUrl: this.baseUrl,
                    endpoint: this.endpoints.emailSender,
                    note: 'Function App rodando (GET não permitido, apenas POST)'
                };
            }
            
            return {
                available: false,
                error: error.message,
                baseUrl: this.baseUrl,
                endpoint: this.endpoints.emailSender,
                status: error.response?.status || 'UNAVAILABLE'
            };
        }
    }
    
    /**
     * Obter configurações atuais
     */
    getConfig() {
        return {
            baseUrl: this.baseUrl,
            endpoint: this.endpoints.emailSender,
            hasApiKey: !!this.apiKey,
            authMethod: this.apiKey ? 'Query string (code parameter)' : 'Anonymous',
            timeout: this.timeout
        };
    }
    
    /**
     * Atualizar configurações
     */
    updateConfig(newConfig) {
        if (newConfig.baseUrl) {
            this.baseUrl = newConfig.baseUrl;
            this.client.defaults.baseURL = this.baseUrl;
        }
        
        if (newConfig.apiKey !== undefined) {
            this.apiKey = newConfig.apiKey;
        }
        
        if (newConfig.timeout) {
            this.timeout = newConfig.timeout;
            this.client.defaults.timeout = this.timeout;
        }
        
        logger.info('🔧 Configuração do Azure Functions atualizada', this.getConfig());
    }
}

// Singleton instance
const azureFunctionsConfig = new AzureFunctionsConfig();
module.exports = azureFunctionsConfig;