export default () => ({
  port: parseInt(String(process.env.PORT || '3000'), 10),

  database: {
    type: process.env.DB_TYPE || 'sqlite',
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(String(process.env.DB_PORT || '5432'), 10),
    username: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_NAME || 'hubspot_sync',
  },

  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(String(process.env.REDIS_PORT || '6379'), 10),
  },

  hubspot: {
    clientSecret: process.env.HUBSPOT_CLIENT_SECRET || '',
  },

  externalApi: {
    baseUrl: process.env.EXTERNAL_API_BASE_URL || 'https://upset-impalas-clap.loca.lt',
  },
});
