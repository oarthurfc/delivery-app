/**
 * Este script verifica se o contador de usuários está inicializado
 * e cria se não existir.
 */
const Counter = require('../models/counter.model');

async function initializeCounters() {
  try {
    // Verificar se o contador de usuários existe
    const userCounter = await Counter.findById('userId');
    
    if (!userCounter) {
      console.log('Inicializando contador de usuários...');
      await Counter.create({ _id: 'userId', seq: 0 });
      console.log('Contador de usuários inicializado com sucesso!');
    } else {
      console.log('Contador de usuários já existe:', userCounter);
    }
  } catch (error) {
    console.error('Erro ao inicializar contadores:', error);
  }
}

module.exports = initializeCounters;
