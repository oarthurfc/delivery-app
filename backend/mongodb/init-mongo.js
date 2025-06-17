db = db.getSiblingDB('admin');
db.auth(process.env.MONGO_INITDB_ROOT_USERNAME, process.env.MONGO_INITDB_ROOT_PASSWORD);

// Configurar banco de dados de autenticação
db = db.getSiblingDB('auth_db');
db.createUser({
    user: 'auth_user',
    pwd: 'auth_password',
    roles: [{ role: 'dbOwner', db: 'auth_db' }]
});

db.users.createIndex({ "email": 1 }, { unique: true });
