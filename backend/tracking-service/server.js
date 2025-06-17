require('dotenv').config();
const app = require('./src/app');
const { initDatabase } = require('./src/config/database');

const PORT = process.env.PORT || 8081;

const startServer = async () => {
  try {
    // Inicializar banco de dados
    await initDatabase();
    
    // Iniciar servidor
    app.listen(PORT, () => {
      console.log(`🚀 Serviço de Rastreamento rodando na porta ${PORT}`);
      console.log(`📖 Documentação Swagger: http://localhost:${PORT}/api/docs`);
      console.log(`📍 Endpoints disponíveis:`);
      console.log(`   POST /api/tracking/location - Atualizar localização`);
      console.log(`   GET  /api/tracking/order/:id/current - Localização atual`);
      console.log(`   GET  /api/tracking/order/:id/history - Histórico de localização`);
      console.log(`   GET  /api/tracking/nearby - Entregas próximas`);
      console.log(`   GET  /api/tracking/stats - Estatísticas`);
      console.log(`   GET  /api/tracking/health - Health check`);
    });
  } catch (error) {
    console.error('Erro ao iniciar servidor:', error);
    process.exit(1);
  }
};

startServer();