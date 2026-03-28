FROM node:20-alpine AS assets

WORKDIR /app

COPY app/package*.json ./

RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

COPY app/ ./

RUN npm run build

FROM nginx:1.27-alpine

WORKDIR /var/www/html

COPY app/public ./public
COPY --from=assets /app/public/build ./public/build

EXPOSE 8080
