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

```bash
# Construire et démarrer
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
