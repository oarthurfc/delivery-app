#!/bin/bash

echo "🚀 Configurando Microsserviço de Rastreamento..."

# Criar arquivo .env se não existir
if [ ! -f .env ]; then
    echo "📄 Criando arquivo .env..."
    cp .env.example .env
    echo "✅ Arquivo .env criado! Edite-o com suas configurações."
else
    echo "✅ Arquivo .env já existe."
fi

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker não está rodando. Por favor, inicie o Docker Desktop."
    exit 1
fi

echo "🐳 Docker está rodando."

# Parar containers existentes
echo "🛑 Parando containers existentes..."
docker-compose down

# Remover imagens antigas se existirem
echo "🧹 Limpando imagens antigas..."
docker image rm tracking-service-tracking_service 2>/dev/null || true

# Construir e subir os serviços
echo "🔨 Construindo e iniciando serviços..."
docker-compose up --build -d

# Aguardar serviços estarem prontos
echo "⏳ Aguardando serviços iniciarem..."
sleep 10

# Verificar status dos containers
echo "📊 Status dos containers:"
docker-compose ps

# Mostrar logs iniciais
echo "📋 Logs dos últimos 20 segundos:"
docker-compose logs --tail=50

echo ""
echo "🎉 Configuração concluída!"
echo "📖 Documentação: http://localhost:3003/api/docs"
echo "⚕️  Health Check: http://localhost:3003/api/tracking/health"
echo ""
echo "📝 Comandos úteis:"
echo "   docker-compose logs -f tracking_service    # Ver logs em tempo real"
echo "   docker-compose down                       # Parar serviços"
echo "   docker-compose up -d                      # Iniciar serviços"