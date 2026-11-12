# PM2 ecosystem file for UnQue 2.0
# Start with:  pm2 start ecosystem.config.cjs
# or:          pm2 start ecosystem.config.cjs --env production

module.exports = {
  apps: [
    {
      name: "unque-api",
      script: "index.js",
      instances: "max",        // cluster mode — one per vCPU
      exec_mode: "cluster",
      watch: false,
      max_memory_restart: "400M",
      env: {
        NODE_ENV: "development",
        PORT: 5001,
      },
      env_production: {
        NODE_ENV: "production",
        PORT: 5001,
      },
      error_file: "logs/pm2-err.log",
      out_file: "logs/pm2-out.log",
      log_date_format: "YYYY-MM-DD HH:mm:ss Z",
    },
  ],
};
