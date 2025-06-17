db = db.getSiblingDB('admin');
db.auth('root', 'rootpassword');

// Configurar banco de dados de autenticação
db = db.getSiblingDB('auth_db');
db.createUser({
    user: 'auth_user',
    pwd: 'auth_password',
    roles: [{ role: 'dbOwner', db: 'auth_db' }]
});

// Criar índices necessários
db.users.createIndex({ "email": 1 }, { unique: true });

// Configurar banco de dados de tracking
db = db.getSiblingDB('tracking_db');
db.createUser({
    user: 'tracking_user',
    pwd: 'auth_password',
    roles: [{ role: 'dbOwner', db: 'tracking_db' }]
});
