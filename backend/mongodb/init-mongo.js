db.auth('${MONGO_INITDB_ROOT_USERNAME}', '${MONGO_INITDB_ROOT_PASSWORD}')

db = db.getSiblingDB('auth_db')

db.createUser({
  user: '${MONGO_INITDB_ROOT_USERNAME}',
  pwd: '${MONGO_INITDB_ROOT_PASSWORD}',
  roles: [
    { role: 'readWrite', db: 'auth_db' }
  ]
})
