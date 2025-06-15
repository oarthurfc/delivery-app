const jwt = require('jsonwebtoken');
const config = require('../config');

exports.authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader) {
      return res.status(401).json({ message: 'Token não fornecido' });
    }

    const [, token] = authHeader.split(' ');

    const decoded = jwt.verify(token, config.jwtSecret);
    req.user = decoded;
    
    next();
  } catch (error) {
    return res.status(401).json({ message: 'Token inválido' });
  }
};

exports.authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ 
        message: 'Acesso negado: permissão insuficiente'
      });
    }
    next();
  };
};
