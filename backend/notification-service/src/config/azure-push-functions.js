const axios = require('axios');
const logger = require('../utils/logger');

class AzurePushFunctionsConfig {
    constructor() {
        this.baseUrl = process.env.AZURE_PUSH_FUNCTIONS_BASE_URL || 'http://localhost:7072';
        this.apiKey = process.env.AZURE_PUSH_FUNCTIONS_API_KEY || '';
        this.timeout = parseInt(process.env.AZURE_PUSH_FUNCTIONS_TIMEOUT) || 30000;
        
        this.endpoints = {
            pushSender: '/api/PushFunction'  
        };
        
        // Configurar cliente HTTP específico para push
        this.client = axios.create({
            baseURL: this.baseUrl,
            timeout: this.timeout,
            headers: {
                'Content-Type': 'application/json',
                'User-Agent': 'notification-service-push/1.0.0'
            }
        });
        
        this.setupInterceptors();
    }
    
    setupInterceptors() {
        // Request interceptor
        this.client.interceptors.request.use(
            (config) => {
                logger.debug(`🌐 Azure Push Functions Request: ${config.method?.toUpperCase()} ${config.url}`, {
                    url: config.url,
                    method: config.method,
                    timeout: config.timeout,
                    hasApiKey: !!this.apiKey,
                    authMethod: this.apiKey ? 'query string (code)' : 'anonymous'
                });
                return config;
            },
            (error) => {
                logger.error('❌ Azure Push Functions Request Error:', error);
                return Promise.reject(error);
            }
        );
        
        // Response interceptor
        this.client.interceptors.response.use(
            (response) => {
                logger.debug(`✅ Azure Push Functions Response: ${response.status}`, {
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
                        errorMessage = 'Authentication failed - check Push API key (code parameter)';
                    } else if (status === 404) {
                        errorMessage = 'Azure Function push-sender not found';
                    } else if (status === 500) {
                        errorMessage = 'Azure Function push internal error';
                    }
                    
                    logger.error(`❌ Azure Push Functions Error: ${status}`, {
                        status,
                        statusText: error.response.statusText,
                        url: error.config?.url,
                        error: errorMessage,
                        data: error.response.data
                    });
                } else if (error.request) {
                    logger.error(`❌ Azure Push Functions Network Error`, {
                        url: error.config?.url,
                        code: error.code,
                        message: error.message
                    });
                } else {
                    logger.error('❌ Azure Push Functions Config Error:', error.message);
                }
                return Promise.reject(error);
            }
        );
    }
    
    /**
     * Chamar a Azure Function específica para push notifications
     */
    async callPushSender(pushData) {
        try {
            const endpoint = this.endpoints.pushSender;
            
            logger.info(`📞 Chamando Azure Push Function: push-sender`, {
                endpoint,
                fcmToken: pushData.fcmToken ? `${pushData.fcmToken.substring(0, 20)}...` : 'not provided',
                hasApiKey: !!this.apiKey
            });
            
            // Preparar URL com query string se tiver API key
            let url = endpoint;
            const params = {};
            
            if (this.apiKey) {
                params.code = this.apiKey;
            }
            
            // Preparar payload no formato esperado pela Azure Function
            const payload = {
                fcmToken: pushData.fcmToken,
                title: pushData.title,
                body: pushData.body,
                data: pushData.data || {},
                timestamp: new Date().toISOString(),
                source: 'notification-service'
            };
            
            // Fazer requisição para Azure Function
            const response = await this.client.post(url, payload, { params });
            
            return {
                success: true,
                data: response.data,
                status: response.status,
                executionTime: response.headers['x-ms-execution-time']
            };
            
        } catch (error) {
            logger.error(`❌ Falha em Azure Push Function:`, {
                error: error.message,
                status: error.response?.status,
                fcmToken: pushData.fcmToken ? `${pushData.fcmToken.substring(0, 20)}...` : 'not provided',
                hasApiKey: !!this.apiKey
            });
            
            throw new Error(`Azure Push Function falhou: ${error.message}`);
        }
    }
    
    /**
     * Testar conectividade com Azure Push Functions
     */
    async testConnection() {
        try {
            logger.info('🧪 Testando conectividade com Azure Push Functions...');
            
            // Para teste, usar um FCM token fake mas válido no formato
            const testData = {
                fcmToken: 'test_token_' + Date.now(),
                title: 'Teste de Conectividade',
                body: 'Testing Azure Push Functions connection',
                data: {
                    test: true,
                    timestamp: new Date().toISOString()
                }
            };
            
            const response = await this.callPushSender(testData);
            
            logger.info('✅ Teste de conectividade com Azure Push Functions bem-sucedido', {
                status: response.status,
                baseUrl: this.baseUrl,
                executionTime: response.executionTime,
                hasApiKey: !!this.apiKey
            });
            
            return {
                success: true,
                status: response.status,
                baseUrl: this.baseUrl,
                endpoint: this.endpoints.pushSender,
                hasApiKey: !!this.apiKey,
                authMethod: this.apiKey ? 'Query string (code parameter)' : 'Anonymous',
                response: response.data,
                executionTime: response.executionTime
            };
            
        } catch (error) {
            logger.error('❌ Teste de conectividade com Azure Push Functions falhou', {
                error: error.message,
                baseUrl: this.baseUrl,
                hasApiKey: !!this.apiKey
            });
            
            return {
                success: false,
                error: error.message,
                baseUrl: this.baseUrl,
                endpoint: this.endpoints.pushSender,
                hasApiKey: !!this.apiKey,
                authMethod: this.apiKey ? 'Query string (code parameter)' : 'Anonymous',
                status: 'CONNECTION_FAILED'
            };
        }
    }
    
    /**
     * Verificar saúde das Azure Push Functions
     */
    async healthCheck() {
        try {
            // Tentar uma requisição GET simples para verificar se está rodando
            const url = `${this.baseUrl}${this.endpoints.pushSender}`;
            const params = this.apiKey ? { code: this.apiKey } : {};
            
            const response = await axios.get(url, { 
                timeout: 5000,
                params
            });
            
            return {
                available: true,
                status: response.status,
                baseUrl: this.baseUrl,
                endpoint: this.endpoints.pushSender
            };
            
        } catch (error) {
            // Se 405 (Method Not Allowed), significa que está rodando mas só aceita POST
            if (error.response?.status === 405) {
                return {
                    available: true,
                    status: 'running',
                    baseUrl: this.baseUrl,
                    endpoint: this.endpoints.pushSender,
                    note: 'Push Function App rodando (GET não permitido, apenas POST)'
                };
            }
            
            return {
                available: false,
                error: error.message,
                baseUrl: this.baseUrl,
                endpoint: this.endpoints.pushSender,
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
            endpoint: this.endpoints.pushSender,
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
        
        logger.info('🔧 Configuração do Azure Push Functions atualizada', this.getConfig());
    }
}

// Singleton instance
const azurePushFunctionsConfig = new AzurePushFunctionsConfig();
module.exports = azurePushFunctionsConfig;