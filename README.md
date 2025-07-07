# Template API

Un template complet et réutilisable pour créer des APIs NestJS avec authentification, upload de fichiers et base de données PostgreSQL.

## 🚀 Démarrage rapide

### 1. Installation complète (recommandé)

```bash
# Installation complète en une commande
make install-full
```

Cette commande va :

- Installer les dépendances
- Configurer le template (nom, description, auteur)
- Démarrer la base de données Docker
- Exécuter les migrations

### 2. Installation étape par étape

```bash
# 1. Installer les dépendances
make install

# 2. Configurer le template (interactif)
make setup

# 3. Démarrer la base de données
make docker-up

# 4. Exécuter les migrations
make migrate

# 5. Démarrer l'application
make dev
```

## 📋 Commandes principales

### 🛠️ Développement

```bash
make dev          # Démarrer en mode développement
make build        # Construire l'application
make test         # Exécuter les tests
make clean        # Nettoyer les fichiers générés
```

### 🐳 Docker

```bash
make docker-up    # Démarrer la base de données
make docker-down  # Arrêter la base de données
make docker-logs  # Afficher les logs
```

### 🔄 Migrations

```bash
make migrate      # Exécuter les migrations
make migrate-gen  # Générer une migration
make migrate-show # Afficher les migrations
```

### 📁 Modules

```bash
make module.create # Créer un nouveau module
```

### 📦 Sauvegardes

```bash
make backup       # Créer une sauvegarde
make restore      # Restaurer depuis une sauvegarde
make list-backups # Lister les sauvegardes
```

## 🔐 Configuration

### Variables d'environnement importantes

Créer/modifier le fichier `.env` :

```env
# Base de données
TYPEORM_PASSWORD=votre_mot_de_passe
TYPEORM_DATABASE=template_db

# JWT
JWT_SECRET=votre_secret_jwt

# API
PORT=8000
```

## 📚 Documentation API

Une fois l'application démarrée :

```
http://localhost:8000/api
```

## 🏗️ Structure du projet

```
src/
├── modules/                  # Modules de l'application
│   ├── auth/                # Authentification
│   ├── user/                # Gestion des utilisateurs
│   ├── media/               # Gestion des médias
│   └── admin/               # Administration
├── types/                   # Types TypeScript
├── validations/             # Validations
└── decorators/              # Décorateurs personnalisés
```

## 🔐 Authentification

Endpoints disponibles :

- `POST /auth/register` - Inscription
- `POST /auth/login` - Connexion
- `POST /auth/refresh` - Rafraîchissement du token
- `POST /auth/logout` - Déconnexion

## 📁 Upload de fichiers

```typescript
@Post('upload')
@UseGuards(JwtAuthGuard)
@UseInterceptors(FileInterceptor('file'))
uploadFile(@UploadedFile() file: Express.Multer.File) {
  return this.mediaService.uploadFile(file);
}
```

## 🐳 Déploiement

### Développement

```bash
make docker-up   # Base de données seulement
make dev         # API en local
```

### Production

#### 1. Configuration du serveur

Avant le premier déploiement, configurer le serveur de production :

```bash
# Se connecter au serveur
ssh user@votre-serveur.com

# Créer le répertoire du projet
mkdir -p ~/votre-projet
cd ~/votre-projet

# Configurer les variables d'environnement
nano .env
# Ajouter les variables nécessaires
# Dévoloppement
NODE_ENV=production
JWT_SECRET=votre_secret_jwt
API_PORT=8000
API_KEY=votre_api_key
API_URL=http://votre-serveur.com:8000

FILES_PATH=./public/files

# DB
TYPEORM_HOST=localhost
TYPEORM_PORT=5432
TYPEORM_USERNAME=postgres
TYPEORM_PASSWORD=votre_mot_de_passe
TYPEORM_NAME=votre_base_de_données
TYPEORM_DATABASE=votre_base_de_données
```

#### 2. Configuration GitHub Actions

Dans votre repository GitHub, configurer les secrets suivants :

- `CR_PAT` : Token GitHub pour Container Registry
- `SERVER_HOST` : Adresse IP de votre serveur
- `SERVER_USER` : Nom d'utilisateur SSH
- `SSH_PRIVATE_KEY` : Clé SSH privée pour se connecter au serveur
- `SSH_PORT` : Port SSH (défaut: 22)

#### 3. Déploiement automatique

Le déploiement se fait automatiquement à chaque push vers `main` :

```bash
# Développer vos fonctionnalités
git add .
git commit -m "Nouvelle fonctionnalité"
git push origin main
```

Le workflow GitHub Actions va automatiquement :

1. **Build** l'image Docker
2. **Push** vers GitHub Container Registry
3. **Déployer** sur le serveur de production
4. **Configurer** les sauvegardes automatiques

#### 4. Vérification du déploiement

```bash
# Vérifier le statut des conteneurs
docker ps

# Voir les logs de l'application
docker logs votre-projet-api

# Tester l'API
curl http://votre-serveur.com:8000/health
```

#### 5. Sauvegardes automatiques

Les sauvegardes sont configurées automatiquement :

- **Base de données** : Sauvegarde quotidienne à 02:00
- **Fichiers uploadés** : Sauvegarde hebdomadaire
- **Rétention** : 30 jours pour les sauvegardes

#### 6. Rollback en cas de problème

```bash
# Se connecter au serveur
ssh user@votre-serveur.com
cd ~/votre-projet

# Restaurer depuis une sauvegarde
./scripts/restore.sh backup_20241201_020000.sql
```

### Déploiement manuel (si nécessaire)

```bash
# Construire et démarrer manuellement
docker compose -f docker-compose.api.yml up -d
```

## 🧪 Tests

```bash
make test        # Tests unitaires
make test-e2e    # Tests e2e
make test-cov    # Tests avec couverture
```

## 🔧 Maintenance

```bash
make lint        # Linter le code
make format      # Formater le code
make setup-backup-cron # Configurer sauvegardes automatiques
```

## 🆘 Aide

```bash
make help        # Afficher toutes les commandes disponibles
```

---

**Note** : Ce template est conçu pour être un point de départ solide. Adaptez-le selon vos besoins spécifiques.
