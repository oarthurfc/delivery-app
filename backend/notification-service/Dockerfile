# Dockerfile
FROM node:18-alpine

# Instalar dependências do sistema
RUN apk add --no-cache wget netcat-openbsd

# Criar diretório da aplicação
WORKDIR /app

# Copiar arquivos de dependências
COPY package*.json ./

# Instalar dependências (gera package-lock.json se não existir e depois usa npm ci)
RUN (test -f package-lock.json || npm install --package-lock-only) && npm ci --only=production && npm cache clean --force

# Copiar código fonte
COPY src/ ./src/

# Criar diretório de logs
RUN mkdir -p logs

# Expor porta
EXPOSE 3001

# Usuário não-root para segurança
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodeapp -u 1001
RUN chown -R nodeapp:nodejs /app
USER nodeapp

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3001/health || exit 1

# Comando de inicialização
CMD ["npm", "start"]