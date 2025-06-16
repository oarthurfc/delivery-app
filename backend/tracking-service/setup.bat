@echo off
echo 🚀 Configurando Microsserviço de Rastreamento...

REM Criar arquivo .env se não existir
if not exist .env (
    echo 📄 Criando arquivo .env...
    copy .env.example .env
    echo ✅ Arquivo .env criado! Edite-o com suas configurações.
) else (
    echo ✅ Arquivo .env já existe.
)

REM Verificar se Docker está rodando
docker info >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker não está rodando. Por favor, inicie o Docker Desktop.
    pause
    exit /b 1
)

echo 🐳 Docker está rodando.

REM Parar containers existentes
echo 🛑 Parando containers existentes...
docker-compose down

REM Remover imagens antigas se existirem
echo 🧹 Limpando imagens antigas...
docker image rm tracking-service-tracking_service 2>nul

REM Construir e subir os serviços
echo 🔨 Construindo e iniciando serviços...
docker-compose up --build -d

REM Aguardar serviços estarem prontos
echo ⏳ Aguardando serviços iniciarem...
timeout /t 15 /nobreak >nul

REM Verificar status dos containers
echo 📊 Status dos containers:
docker-compose ps

REM Mostrar logs iniciais
echo 📋 Logs dos últimos segundos:
docker-compose logs --tail=50

echo.
echo 🎉 Configuração concluída!
echo 📖 Documentação: http://localhost:3003/api/docs
echo ⚕️  Health Check: http://localhost:3003/api/tracking/health
echo.
echo 📝 Comandos úteis:
echo    docker-compose logs -f tracking_service    # Ver logs em tempo real
echo    docker-compose down                       # Parar serviços
echo    docker-compose up -d                      # Iniciar serviços
echo.
pause