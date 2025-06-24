const mongoose = require('mongoose');
const User = require('./src/models/user.model');
require('dotenv').config();

async function migrateFcmToken() {
  try {
    // Conectar ao MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/delivery');
    console.log('Conectado ao MongoDB');

    // Buscar todos os usuários que não têm fcmToken
    const usersWithoutFcmToken = await User.find({ fcmToken: { $exists: false } });
    
    if (usersWithoutFcmToken.length === 0) {
      console.log('Nenhum usuário encontrado sem fcmToken');
      return;
    }

    console.log(`Encontrados ${usersWithoutFcmToken.length} usuários sem fcmToken`);

    // Atualizar cada usuário com um fcmToken temporário
    for (const user of usersWithoutFcmToken) {
      const tempFcmToken = `temp_token_${user._id}_${Date.now()}`;
      
      await User.findByIdAndUpdate(user._id, {
        fcmToken: tempFcmToken
      });
      
      console.log(`Usuário ${user.email} atualizado com fcmToken temporário`);
    }

    console.log('Migração concluída com sucesso!');
    console.log('IMPORTANTE: Os usuários foram atualizados com tokens temporários.');
    console.log('Eles precisarão atualizar seus tokens reais através do app.');

  } catch (error) {
    console.error('Erro durante a migração:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Desconectado do MongoDB');
  }
}

// Executar migração se o script for chamado diretamente
if (require.main === module) {
  migrateFcmToken();
}

module.exports = migrateFcmToken; 