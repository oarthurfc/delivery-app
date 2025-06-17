// src/app.js
const express = require('express');
const cors = require('cors');
const swaggerUi = require('swagger-ui-express');
const swaggerSpecs = require('./config/swagger');
const trackingRoutes = require('./routes/tracking');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Documentação Swagger
app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpecs, {
  explorer: true,
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: "Tracking API Documentation"
}));

// Rotas
app.use('/tracking', trackingRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    service: 'Tracking Service',
    timestamp: new Date().toISOString(),
    documentation: '/api/docs'
  });
});

// Middleware de tratamento de erros
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Erro interno do servidor' });
});

// Middleware para rotas não encontradas
app.use('*', (req, res) => {
  res.status(404).json({ 
    error: 'Rota não encontrada',
    documentation: '/api/docs'
  });
});

module.exports = app;