// src/middleware/auth.js
const jwt = require('jsonwebtoken');

// Middleware de autenticação JWT
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ 
      error: 'Token de acesso requerido',
      message: 'Forneça um token JWT válido no header Authorization'
    });
  }

  jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret', (err, user) => {
    if (err) {
      return res.status(403).json({ 
        error: 'Token inválido',
        message: 'O token fornecido é inválido ou expirou'
      });
    }
    
    // Adicionar informações do usuário à requisição
    req.user = user;
    next();
  });
};

// Middleware opcional para verificar tipo de usuário
const requireDriverRole = (req, res, next) => {
  if (req.user && req.user.type === 'DRIVER') {
    next();
  } else {
    res.status(403).json({ 
      error: 'Acesso negado', 
      message: 'Esta operação requer privilégios de motorista'
    });
  }
};

const requireCustomerRole = (req, res, next) => {
  if (req.user && req.user.type === 'CUSTOMER') {
    next();
  } else {
    res.status(403).json({ 
      error: 'Acesso negado', 
      message: 'Esta operação requer privilégios de cliente'
    });
  }
};

module.exports = {
  authenticateToken,
  requireDriverRole,
  requireCustomerRole
};