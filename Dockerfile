FROM node:19 AS builder
WORKDIR /app
COPY ./package.json ./
COPY .env.production .env
RUN npm install
COPY . .
RUN npm run build


FROM node:19-alpine
WORKDIR /app
COPY --from=builder /app ./
CMD ["npm", "run", "start:prod"]