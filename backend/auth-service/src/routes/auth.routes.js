const express = require('express');
const { body } = require('express-validator');
const authController = require('../controllers/auth.controller');
const { validateToken } = require('../middleware/auth.middleware');


const router = express.Router();

// Validações comuns
const emailValidation = body('email')
  .isEmail()
  .normalizeEmail()
  .withMessage('Email inválido');

const passwordValidation = body('password')
  .isLength({ min: 6 })
  .withMessage('A senha deve ter no mínimo 6 caracteres');

// Rotas públicas
router.post(
  '/register',
  [
    emailValidation,
    passwordValidation,
    body('name').trim().notEmpty().withMessage('Nome é obrigatório'),
    body('role').isIn(['customer', 'driver']).withMessage('Tipo de usuário inválido')
  ],
  authController.register
);

router.post(
  '/login',
  [
    emailValidation,
    body('password').notEmpty().withMessage('Senha é obrigatória')
  ],
  authController.login
);

router.post('/validate', validateToken, (req, res) => {
    const userData = {
        userId: req.user.id,
        email: req.user.email,
        role: req.user.role,
    };
    
    res.json(userData);
});

module.exports = router;
