FROM node:20.10-alpine3.18

WORKDIR /usr/src/app

# Copiar apenas os arquivos necessários para instalar dependências
COPY package*.json ./
RUN npm install

# Copiar o resto do código
COPY src/ ./src/

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["npm", "start"]
