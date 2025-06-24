const axios = require('axios');
const logger = require('./logger');

class HttpClient {
    constructor() {
        this.client = axios.create({
            timeout: 30000,
            headers: {
                'Content-Type': 'application/json',
                'User-Agent': 'notification-service/1.0.0'
            }
        });

        // Interceptors para logging
        this.setupInterceptors();
    }

    setupInterceptors() {
        // Request interceptor
        this.client.interceptors.request.use(
            (config) => {
                logger.debug(`🌐 HTTP Request: ${config.method?.toUpperCase()} ${config.url}`, {
                    url: config.url,
                    method: config.method,
                    headers: this.sanitizeHeaders(config.headers),
                    dataSize: config.data ? JSON.stringify(config.data).length : 0
                });
                return config;
            },
            (error) => {
                logger.error('❌ HTTP Request Error:', error);
                return Promise.reject(error);
            }
        );

        // Response interceptor
        this.client.interceptors.response.use(
            (response) => {
                logger.debug(`✅ HTTP Response: ${response.status} ${response.config.url}`, {
                    url: response.config.url,
                    status: response.status,
                    statusText: response.statusText,
                    responseSize: JSON.stringify(response.data).length
                });
                return response;
            },
            (error) => {
                if (error.response) {
                    logger.error(`❌ HTTP Response Error: ${error.response.status} ${error.config?.url}`, {
                        url: error.config?.url,
                        status: error.response.status,
                        statusText: error.response.statusText,
                        data: error.response.data
                    });
                } else if (error.request) {
                    logger.error(`❌ HTTP Request Failed: ${error.config?.url}`, {
                        url: error.config?.url,
                        message: error.message,
                        code: error.code
                    });
                } else {
                    logger.error('❌ HTTP Client Error:', error.message);
                }
                return Promise.reject(error);
            }
        );
    }

    sanitizeHeaders(headers) {
        const sanitized = { ...headers };
        
        // Remover headers sensíveis dos logs
        const sensitiveHeaders = ['authorization', 'x-functions-key', 'cookie'];
        sensitiveHeaders.forEach(header => {
            if (sanitized[header]) {
                sanitized[header] = '***';
            }
        });
        
        return sanitized;
    }

    async get(url, config = {}) {
        return this.client.get(url, config);
    }

    async post(url, data, config = {}) {
        return this.client.post(url, data, config);
    }

    async put(url, data, config = {}) {
        return this.client.put(url, data, config);
    }

    async delete(url, config = {}) {
        return this.client.delete(url, config);
    }

    async patch(url, data, config = {}) {
        return this.client.patch(url, data, config);
    }
}

module.exports = new HttpClient();