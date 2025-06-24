const winston = require('winston');

// Configurar formato customizado
const customFormat = winston.format.combine(
    winston.format.timestamp({
        format: 'YYYY-MM-DD HH:mm:ss'
    }),
    winston.format.errors({ stack: true }),
    winston.format.json(),
    winston.format.printf(({ timestamp, level, message, ...meta }) => {
        let log = `${timestamp} [${level.toUpperCase()}] ${message}`;
        
        // Adicionar metadados se existirem
        if (Object.keys(meta).length > 0) {
            log += ` ${JSON.stringify(meta, null, 2)}`;
        }
        
        return log;
    })
);

// Configurar transportes
const transports = [
    new winston.transports.Console({
        format: winston.format.combine(
            winston.format.colorize(),
            winston.format.simple()
        )
    })
];

// Adicionar arquivo de log em produção
if (process.env.NODE_ENV === 'production') {
    transports.push(
        new winston.transports.File({
            filename: 'logs/error.log',
            level: 'error',
            format: customFormat
        }),
        new winston.transports.File({
            filename: 'logs/combined.log',
            format: customFormat
        })
    );
}

const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: customFormat,
    transports,
    exitOnError: false
});

module.exports = logger;