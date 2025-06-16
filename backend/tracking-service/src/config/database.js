// src/config/database.js
const { Pool } = require('pg');

// Configuração da conexão com PostgreSQL
const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'tracking_service',
  password: process.env.DB_PASSWORD || 'password',
  port: process.env.DB_PORT || 5432,
  max: 20, // máximo de conexões no pool
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Função para inicializar o banco de dados
const initDatabase = async () => {
  try {
    // Criar tabela de pontos de localização
    await pool.query(`
      CREATE TABLE IF NOT EXISTS location_points (
        id SERIAL PRIMARY KEY,
        order_id INTEGER NOT NULL,
        driver_id INTEGER NOT NULL,
        latitude DECIMAL(10, 8) NOT NULL,
        longitude DECIMAL(11, 8) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        accuracy DECIMAL(6, 2),
        speed DECIMAL(6, 2),
        heading DECIMAL(6, 2)
      )
    `);

    // Criar índices para performance
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_location_points_order_id ON location_points(order_id);
    `);
    
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_location_points_created_at ON location_points(created_at);
    `);

    console.log('✅ Banco de dados inicializado com sucesso');
  } catch (error) {
    console.error('❌ Erro ao inicializar banco de dados:', error);
    throw error;
  }
};

// Função para testar a conexão
const testConnection = async () => {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    client.release();
    console.log('✅ Conexão com banco estabelecida:', result.rows[0].now);
    return true;
  } catch (error) {
    console.error('❌ Erro na conexão com banco:', error);
    return false;
  }
};

module.exports = {
  pool,
  initDatabase,
  testConnection
};