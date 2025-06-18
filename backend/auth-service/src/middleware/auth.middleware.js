const jwt = require('jsonwebtoken');

exports.authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Token não fornecido ou formato inválido' });
    }

    const token = authHeader.split(' ')[1];

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
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

exports.validateToken = (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Token não fornecido ou formato inválido' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    return res.json({
      userId: decoded.id,
      email: decoded.email,
      role: decoded.role,
      name: decoded.name
    });
  } catch (error) {
    return res.status(401).json({ message: 'Token inválido' });
  }
};
