const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const config = require('./config');

// Rotas
const authRoutes = require('./routes/auth.routes');

const app = express();

// Middleware
app.use(cors({
  origin: config.corsOrigins,
  credentials: true
}));
app.use(helmet());
app.use(morgan('dev'));
app.use(express.json());

// Rotas
app.use('/auth', authRoutes);

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    message: 'Algo deu errado!',
    error: config.nodeEnv === 'development' ? err.message : undefined
  });
});

// Conexão com MongoDB
mongoose.connect(config.mongoUri)
  .then(() => {
    console.log('Conectado ao MongoDB');
    
    // Iniciar servidor
    app.listen(config.port, () => {
      console.log(`Servidor rodando na porta ${config.port}`);
    });
  })
  .catch(err => {
    console.error('Erro ao conectar ao MongoDB:', err);
    process.exit(1);
  });
