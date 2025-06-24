# Use Node.js 18 Alpine para menor tamanho
FROM node:18-alpine

# Definir variáveis de build
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# Criar diretório da aplicação
WORKDIR /app

# Criar usuário não-root para segurança
RUN addgroup -g 1001 -S nodejs && \
    adduser -S notificationuser -u 1001

# Instalar dumb-init para melhor handling de sinais
RUN apk add --no-cache dumb-init

# Copiar package.json e package-lock.json (se existir)
COPY package*.json ./

# Instalar dependências
RUN npm ci --only=production && \
    npm cache clean --force

# Copiar código fonte
COPY . .

# Criar diretório de logs com permissões corretas
RUN mkdir -p logs && \
    chown -R notificationuser:nodejs logs && \
    chown -R notificationuser:nodejs /app

# Mudar para usuário não-root
USER notificationuser

# Expor porta da aplicação
EXPOSE 3001

# Health check para verificar se a aplicação está saudável
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD node -e " \
        const http = require('http'); \
        const options = { \
            hostname: 'localhost', \
            port: 3001, \
            path: '/health', \
            method: 'GET', \
            timeout: 5000 \
        }; \
        const req = http.request(options, (res) => { \
            process.exit(res.statusCode === 200 ? 0 : 1); \
        }); \
        req.on('error', () => process.exit(1)); \
        req.on('timeout', () => process.exit(1)); \
        req.end(); \
    "

# Labels para metadados
LABEL maintainer="Delivery Team" \
      version="1.0.0" \
      description="Notification Service for Delivery System" \
      service="notification-service"

# Usar dumb-init como entrypoint para melhor handling de sinais SIGTERM/SIGKILL
ENTRYPOINT ["dumb-init", "--"]

# Comando para iniciar a aplicação
CMD ["node", "src/app.js"]