# Stage de construction
FROM node:18.17.0 AS builder
WORKDIR /app
COPY ./package.json ./
COPY .env.production .env
RUN npm install
COPY . .
RUN npm run build

# Stage de production
FROM node:18.17.0-alpine
WORKDIR /app
COPY --from=builder /app ./

RUN npm install sharp

CMD ["npm", "run", "start:prod"]
