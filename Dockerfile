# Stage de construction
FROM node:20-alpine AS builder
WORKDIR /app

# Copier tous les fichiers nécessaires
COPY . .

# Installer toutes les dépendances (incluant dev pour la construction)
RUN yarn install

# Construire l'application
RUN yarn build

# Stage de production
FROM node:20-alpine AS production
WORKDIR /app

# Installer les dépendances de production
RUN apk add --no-cache dumb-init

# Copier les fichiers nécessaires
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/tsconfig*.json ./
COPY --from=builder /app/nest-cli.json ./
COPY --from=builder /app/ormconfig.ts ./
COPY --from=builder /app/public ./public

# Installer les dépendances de production + celles nécessaires aux migrations
RUN yarn install --production && \
    yarn add ts-node tsconfig-paths @types/node

# Créer les répertoires nécessaires
RUN mkdir -p /app/public/files /app/public

# Créer un fichier index.html simple pour éviter les erreurs
RUN echo '<!DOCTYPE html><html><head><title>API Template</title></head><body><h1>API Template</h1><p>API is running successfully!</p></body></html>' > /app/public/index.html

# Ajout d'un utilisateur non-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Utiliser dumb-init pour une meilleure gestion des signaux
ENV NODE_ENV=production
ENTRYPOINT ["dumb-init", "--"]
CMD ["yarn", "run", "start:prod"]
