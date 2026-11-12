# ---- Build stage ----
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

# ---- Production image ----
FROM node:20-alpine

WORKDIR /app

# Create a non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=builder /app /app

# AWS DocumentDB TLS certificate (global bundle)
RUN apk add --no-cache curl && \
    curl -sS https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem \
         -o /app/global-bundle.pem && \
    chown appuser:appgroup /app/global-bundle.pem

USER appuser

EXPOSE 5001

CMD ["node", "index.js"]
