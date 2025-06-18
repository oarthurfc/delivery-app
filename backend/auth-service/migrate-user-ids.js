/**
 * Script para migrar IDs de usuários para valores numéricos
 * 
 * Este script deve ser executado uma única vez para converter os IDs existentes
 * no formato ObjectId para IDs numéricos sequenciais.
 * 
 * Como executar:
 * node migrate-user-ids.js
 */

const mongoose = require('mongoose');
const config = require('./src/config');
const Counter = require('./src/models/counter.model');

// Conectar ao MongoDB
mongoose.connect(config.mongoURI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
}).then(() => {
  console.log('Conectado ao MongoDB...');
  migrateUserIds();
}).catch(err => {
  console.error('Erro ao conectar ao MongoDB:', err);
  process.exit(1);
});

// Esquema direto para usar durante a migração
const oldUserSchema = new mongoose.Schema({}, { strict: false });
const OldUser = mongoose.model('OldUser', oldUserSchema, 'users');

// Novo esquema de usuário (como no modelo principal)
const userSchema = new mongoose.Schema({
  _id: Number,
  email: String,
  password: String,
  name: String,
  role: String,
  active: Boolean,
  createdAt: Date,
  updatedAt: Date
});
const NewUser = mongoose.model('NewUser', userSchema, 'users_new');

async function migrateUserIds() {
  try {
    console.log('Iniciando migração de IDs...');
    
    // Criar coleção temporária
    await mongoose.connection.db.createCollection('users_new');
    console.log('Coleção temporária criada...');

    // Inicializar contador
    let counter = await Counter.findOneAndUpdate(
      { _id: 'userId' },
      { $set: { seq: 0 } },
      { upsert: true, new: true }
    );
    console.log('Contador inicializado:', counter);

    // Buscar todos os usuários existentes
    const oldUsers = await OldUser.find({});
    console.log(`Encontrados ${oldUsers.length} usuários para migrar...`);

    // Migrar cada usuário
    for (const oldUser of oldUsers) {
      // Incrementar contador
      counter = await Counter.findOneAndUpdate(
        { _id: 'userId' },
        { $inc: { seq: 1 } },
        { new: true }
      );

      // Criar usuário com ID numérico
      const newUser = new NewUser({
        _id: counter.seq,
        email: oldUser.email,
        password: oldUser.password,
        name: oldUser.name,
        role: oldUser.role,
        active: oldUser.active || true,
        createdAt: oldUser.createdAt || new Date(),
        updatedAt: oldUser.updatedAt || new Date()
      });

      await newUser.save();
      console.log(`Usuário migrado: ${oldUser._id} -> ${counter.seq}`);
    }

    // Criar backup da coleção original
    await mongoose.connection.db.collection('users').rename('users_backup');
    console.log('Backup da coleção original criado (users_backup)...');

    // Renomear nova coleção
    await mongoose.connection.db.collection('users_new').rename('users');
    console.log('Nova coleção renomeada para users...');

    console.log('Migração concluída com sucesso!');
    process.exit(0);
  } catch (error) {
    console.error('Erro durante a migração:', error);
    process.exit(1);
  }
}
