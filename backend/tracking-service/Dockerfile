FROM node:18-alpine

# Instalar netcat para aguardar o banco
RUN apk add --no-cache netcat-openbsd

# Criar diretório da aplicação
WORKDIR /app

# Copiar package.json e package-lock.json primeiro para cache de dependências
COPY package*.json ./

# Instalar dependências (incluindo swagger)
RUN npm ci --only=production && npm cache clean --force

# Copiar código da aplicação
COPY . .

# Criar usuário não-root para segurança
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Mudar proprietário dos arquivos
RUN chown -R nodejs:nodejs /app

# Mudar para usuário não-root
USER nodejs

# Expor a porta (configurável via ENV)
EXPOSE 8081

# Comando padrão
CMD ["npm", "start"]