// Este script será executado durante a inicialização do container MongoDB
const dbName = process.env.MONGO_INITDB_DATABASE;

db = db.getSiblingDB(dbName)

// Criar usuário com permissões apropriadas
db.createUser({
  user: process.env.MONGO_INITDB_ROOT_USERNAME,
  pwd: process.env.MONGO_INITDB_ROOT_PASSWORD,
  roles: [
    { role: 'dbOwner', db: dbName }
  ]
})

// Criar um índice único para o campo email na coleção users
db.users.createIndex({ "email": 1 }, { unique: true })
