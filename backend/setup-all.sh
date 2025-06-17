#!/bin/bash

echo "🚀 Configurando Sistema Completo de Microsserviços..."

# Criar arquivo .env se não existir
if [ ! -f .env ]; then
    echo "📄 Criando arquivo .env..."
    cp .env.example .env
    echo "✅ Arquivo .env criado! Edite-o com suas configurações se necessário."
else
    echo "✅ Arquivo .env já existe."
fi

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker não está rodando. Por favor, inicie o Docker."
    exit 1
fi

echo "🐳 Docker está rodando."

# Parar containers existentes
echo "🛑 Parando containers existentes..."
docker-compose down

# Limpar imagens antigas
echo "🧹 Limpando imagens antigas..."
docker system prune -f

# Construir e subir todos os serviços
echo "🔨 Construindo e iniciando todos os microsserviços..."
docker-compose up --build -d

# Aguardar serviços estarem prontos
echo "⏳ Aguardando serviços iniciarem..."
sleep 30

# Verificar status dos containers
echo "📊 Status dos containers:"
docker-compose ps

echo ""
echo "🎉 Sistema completo configurado!"
echo ""
echo "📝 URLs dos serviços:"
echo "🔐 Auth Service: http://localhost:3000"
echo "📦 Order Service: http://localhost:8080"  
echo "📍 Tracking Service: http://localhost:8081"
echo "   └── Swagger: http://localhost:8081/api/docs"
echo "🌐 API Gateway: http://localhost:8000"
echo "🐰 RabbitMQ Management: http://localhost:15672 (delivery_user/delivery_pass)"
echo "🗄️ PostgreSQL (Orders): localhost:5432"
echo "🗄️ PostgreSQL (Tracking): localhost:5433"
echo "🍃 MongoDB: localhost:27017"
echo ""
echo "📝 Comandos úteis:"
echo "   docker-compose logs -f [nome-do-serviço]  # Ver logs em tempo real"
echo "   docker-compose down                       # Parar todos os serviços"
echo "   docker-compose up -d                      # Iniciar todos os serviços"
echo "   docker-compose ps                         # Ver status dos containers"
echo ""