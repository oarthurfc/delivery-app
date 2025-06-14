#!/bin/zsh

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "${YELLOW}🚀 Configurando ambiente de desenvolvimento...${NC}"

# Verifica se o arquivo .env existe
if [ ! -f .env ]; then
    echo "${YELLOW}📝 Criando arquivo .env a partir do .env.example...${NC}"
    cp .env.example .env
    echo "${GREEN}✅ Arquivo .env criado com sucesso!${NC}"
else
    echo "${YELLOW}ℹ️  Arquivo .env já existe${NC}"
fi

# Verifica se o Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo "${YELLOW}❌ Docker não está rodando. Por favor, inicie o Docker e tente novamente.${NC}"
    exit 1
fi

echo "${YELLOW}🔨 Construindo e iniciando os containers...${NC}"
docker-compose up -d --build

echo "${GREEN}✨ Ambiente configurado com sucesso!${NC}"
echo "${YELLOW}
Serviços disponíveis:
- API Gateway: http://localhost:8000
- RabbitMQ Management: http://localhost:15672
- PostgreSQL: localhost:5432
- MongoDB: localhost:27017${NC}"
