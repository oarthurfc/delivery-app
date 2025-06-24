const axios = require('axios');
const logger = require('../utils/logger');

class AzureFunctionsConfig {
    constructor() {
        this.baseUrl = process.env.AZURE_FUNCTIONS_BASE_URL || 'http://localhost:7071';
        this.apiKey = process.env.AZURE_FUNCTIONS_API_KEY || '';
        this.timeout = parseInt(process.env.AZURE_FUNCTIONS_TIMEOUT) || 30000;
        
        // Endpoints das Azure Functions
        this.endpoints = {
            processOrderCompleted: '/api/ProcessOrderCompleted',
            processOrderCreated: '/api/ProcessOrderCreated',
            sendPromotionalCampaign: '/api/SendPromotionalCampaign',
            sendCustomEmail: '/api/SendCustomEmail',
            testConnection: '/api/TestEmail'
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
        
        // Adicionar API key se configurada
        if (this.apiKey) {
            this.client.defaults.headers['x-functions-key'] = this.apiKey;
        }
        
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
                    hasApiKey: !!this.apiKey
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
                    responseTime: response.headers['x-ms-execution-time-ms'] || 'unknown'
                });
                return response;
            },
            (error) => {
                if (error.response) {
                    logger.error(`❌ Azure Functions Error: ${error.response.status}`, {
                        status: error.response.status,
                        statusText: error.response.statusText,
                        url: error.config?.url,
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
     * Método genérico para chamar qualquer endpoint
     */
    async callEndpoint(endpointName, data, options = {}) {
        try {
            const endpoint = this.endpoints[endpointName];
            if (!endpoint) {
                throw new Error(`Endpoint '${endpointName}' não encontrado`);
            }

            logger.info(`📞 Chamando Azure Function: ${endpointName}`, {
                endpoint,
                dataKeys: Object.keys(data || {})
            });
            
            const response = await this.client.post(endpoint, data, options);
            
            return {
                success: true,
                data: response.data,
                status: response.status,
                executionTime: response.headers['x-ms-execution-time-ms']
            };
            
        } catch (error) {
            logger.error(`❌ Falha em ${endpointName}:`, {
                endpoint: endpointName,
                error: error.message,
                status: error.response?.status
            });
            
            throw new Error(`Azure Function ${endpointName} falhou: ${error.message}`);
        }
    }
    
    /**
     * Chamar endpoint de pedido finalizado
     */
    async callProcessOrderCompleted(orderData) {
        return this.callEndpoint('processOrderCompleted', orderData);
    }
    
    /**
     * Chamar endpoint de pedido criado
     */
    async callProcessOrderCreated(orderData) {
        return this.callEndpoint('processOrderCreated', orderData);
    }
    
    /**
     * Chamar endpoint de campanha promocional
     */
    async callSendPromotionalCampaign(campaignData) {
        return this.callEndpoint('sendPromotionalCampaign', campaignData);
    }

    /**
     * Chamar endpoint de email customizado
     */
    async callSendCustomEmail(emailData) {
        return this.callEndpoint('sendCustomEmail', emailData);
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
                service: 'notification-service'
            };
            
            // Tentar endpoint de teste primeiro
            let response;
            try {
                response = await this.callEndpoint('testConnection', testData);
            } catch (testError) {
                // Se endpoint de teste não existir, usar ProcessOrderCreated
                response = await this.callEndpoint('processOrderCreated', {
                    eventType: 'CONNECTION_TEST',
                    orderId: 'test-' + Date.now(),
                    customerId: 999,
                    ...testData
                });
            }
            
            logger.info('✅ Teste de conectividade com Azure Functions bem-sucedido', {
                status: response.status,
                baseUrl: this.baseUrl,
                executionTime: response.executionTime
            });
            
            return {
                success: true,
                status: response.status,
                baseUrl: this.baseUrl,
                hasApiKey: !!this.apiKey,
                response: response.data,
                executionTime: response.executionTime
            };
            
        } catch (error) {
            logger.error('❌ Teste de conectividade com Azure Functions falhou', {
                error: error.message,
                baseUrl: this.baseUrl
            });
            
            return {
                success: false,
                error: error.message,
                baseUrl: this.baseUrl,
                hasApiKey: !!this.apiKey,
                status: 'CONNECTION_FAILED'
            };
        }
    }
    
    /**
     * Verificar saúde das Azure Functions
     */
    async healthCheck() {
        try {
            // Tentar uma requisição simples para verificar se está rodando
            const response = await axios.get(`${this.baseUrl}`, { timeout: 5000 });
            
            return {
                available: true,
                status: response.status,
                baseUrl: this.baseUrl
            };
            
        } catch (error) {
            return {
                available: false,
                error: error.message,
                baseUrl: this.baseUrl,
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
            hasApiKey: !!this.apiKey,
            timeout: this.timeout,
            endpoints: this.endpoints
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
            if (this.apiKey) {
                this.client.defaults.headers['x-functions-key'] = this.apiKey;
            } else {
                delete this.client.defaults.headers['x-functions-key'];
            }
        }
        
        if (newConfig.timeout) {
            this.timeout = newConfig.timeout;
            this.client.defaults.timeout = this.timeout;
        }
        
        logger.info('🔧 Configuração do Azure Functions atualizada', this.getConfig());
    }

    /**
     * Adicionar novo endpoint dinamicamente
     */
    addEndpoint(name, path) {
        this.endpoints[name] = path;
        logger.info(`🔗 Novo endpoint adicionado: ${name} -> ${path}`);
    }

    /**
     * Listar todos os endpoints disponíveis
     */
    listEndpoints() {
        return Object.keys(this.endpoints);
    }
}

// Singleton instance
const azureFunctionsConfig = new AzureFunctionsConfig();
module.exports = azureFunctionsConfig;