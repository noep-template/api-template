# Template API NestJS

Un template complet et réutilisable pour créer des APIs NestJS avec authentification, upload de fichiers et base de données PostgreSQL.

## 🚀 Fonctionnalités

- **Authentification JWT** avec stratégies Passport
- **Upload de fichiers** avec gestion d'images
- **Base de données PostgreSQL** avec TypeORM
- **Documentation Swagger** automatique
- **Déploiement Docker** avec CI/CD GitHub Actions
- **Sauvegardes automatiques** de la base de données et des fichiers
- **Scripts de gestion** pour maintenance et déploiement

## 📋 Prérequis

- Node.js 18+
- Docker et Docker Compose
- PostgreSQL (optionnel pour le développement local)
- Git

## 🛠️ Installation

### 1. Cloner le template

```bash
git clone <votre-repo-template>
cd api-template
```

### 2. Installer les dépendances

```bash
yarn install
```

### 3. Configuration de l'environnement

Copier le fichier d'environnement :

```bash
cp .env.example .env
```

Éditer le fichier `.env` avec vos configurations :

```env
# Base de données
TYPEORM_HOST=localhost
TYPEORM_PORT=5432
TYPEORM_USERNAME=postgres
TYPEORM_PASSWORD=votre_mot_de_passe
TYPEORM_DATABASE=template_db

# JWT
JWT_SECRET=votre_secret_jwt
JWT_EXPIRES_IN=24h

# API
PORT=8000
NODE_ENV=development
```

### 4. Base de données

#### Option A : Docker (recommandé)

```bash
docker compose up -d template-db
```

#### Option B : PostgreSQL local

Installer PostgreSQL et créer une base de données :

```sql
CREATE DATABASE template_db;
```

### 5. Migrations

```bash
npm run migrate
```

### 6. Démarrage

```bash
# Développement
yarn run start:dev

# Production
yarn run start:prod
```

## 🏗️ Structure du projet

```
src/
├── app.controller.ts          # Contrôleur principal
├── app.module.ts             # Module principal
├── app.service.ts            # Service principal
├── main.ts                   # Point d'entrée
├── decorators/               # Décorateurs personnalisés
├── errors/                   # Gestion d'erreurs
├── modules/                  # Modules de l'application
│   ├── auth/                 # Authentification
│   ├── user/                 # Gestion des utilisateurs
│   ├── media/                # Gestion des médias
│   └── admin/                # Administration
├── types/                    # Types TypeScript
├── utils/                    # Utilitaires
└── validations/              # Validations
```

## 🔐 Authentification

Le template inclut un système d'authentification complet :

- **Inscription** : `/auth/register`
- **Connexion** : `/auth/login`
- **Rafraîchissement** : `/auth/refresh`
- **Déconnexion** : `/auth/logout`

### Utilisation

```typescript
// Décorateur pour récupérer l'utilisateur connecté
@Get('profile')
@UseGuards(JwtAuthGuard)
getProfile(@GetCurrentUser() user: User) {
  return user;
}
```

## 📁 Upload de fichiers

Le template gère l'upload de fichiers avec :

- Validation des types de fichiers
- Redimensionnement automatique des images
- Stockage sécurisé
- Gestion des métadonnées

### Utilisation

```typescript
@Post('upload')
@UseGuards(JwtAuthGuard)
@UseInterceptors(FileInterceptor('file'))
uploadFile(@UploadedFile() file: Express.Multer.File) {
  return this.mediaService.uploadFile(file);
}
```

## 🐳 Déploiement Docker

### Développement local

```bash
# Construire et démarrer
docker compose up -d

# Voir les logs
docker compose logs -f

# Arrêter
docker compose down
```

### Production

Le template inclut un système de déploiement automatique via GitHub Actions :

1. **Build** de l'image Docker
2. **Push** vers GitHub Container Registry
3. **Déploiement** automatique sur le serveur
4. **Sauvegarde** avant mise à jour

## 📦 Scripts de gestion

### Sauvegardes

```bash
# Sauvegarde complète
./scripts/backup.sh

# Sauvegarde DB seulement
./scripts/backup.sh --db

# Sauvegarde images seulement
./scripts/backup.sh --images
```

### Restauration

```bash
# Restaurer la base de données
./scripts/restore.sh template_backup_20241201_020000.sql

# Restaurer les images
./scripts/restore.sh images_backup_20241201_020000.tar.gz
```

### Déploiement

```bash
# Déployer l'application
./scripts/deploy.sh
```

## 🔧 Configuration CI/CD

### Secrets GitHub requis

- `CR_PAT` : Token GitHub pour Container Registry
- `SERVER_HOST` : Adresse du serveur de production
- `SERVER_USER` : Utilisateur SSH
- `SSH_PRIVATE_KEY` : Clé SSH privée
- `SSH_PORT` : Port SSH (défaut: 22)

### Workflow GitHub Actions

Le workflow automatique :

1. Se déclenche sur push vers `main`
2. Build l'image Docker
3. Push vers GitHub Container Registry
4. Déploie sur le serveur de production
5. Configure les sauvegardes automatiques

## 📚 Documentation API

Une fois l'application démarrée, la documentation Swagger est disponible à :

```
http://localhost:8000/api
```

## 🧪 Tests

```bash
# Tests unitaires
yarn run test

# Tests e2e
yarn run test:e2e

# Couverture de code
yarn run test:cov
```

## 🔄 Migrations

```bash
# Générer une migration
yarn run migrate:generate

# Exécuter les migrations
yarn run migrate:run

# Voir les migrations
yarn run migrate:show
```

## 🛡️ Sécurité

- **Validation** des entrées avec Yup
- **Hachage** des mots de passe avec bcrypt
- **JWT** pour l'authentification
- **CORS** configuré
- **Rate limiting** (à implémenter selon vos besoins)
- **Validation** des fichiers uploadés

## 📝 Personnalisation

### 1. Renommer le projet

```bash
# Remplacer "template" par votre nom de projet
find . -type f -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.md" -o -name "*.sh" | xargs sed -i 's/template/votre-projet/g'
```

### 2. Modifier les variables d'environnement

Éditer le fichier `.env` et adapter les variables selon vos besoins.

### 3. Ajouter vos modules

Créer de nouveaux modules dans `src/modules/` en suivant la structure existante.

### 4. Personnaliser l'authentification

Modifier les stratégies dans `src/modules/auth/strategies/` selon vos besoins.

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🆘 Support

Pour toute question ou problème :

1. Consulter la documentation
2. Vérifier les issues existantes
3. Créer une nouvelle issue avec un exemple reproductible

## 🔄 Mises à jour

Pour mettre à jour le template :

```bash
git pull origin main
yarn install
yarn run migrate
```

---

**Note** : Ce template est conçu pour être un point de départ solide pour vos projets NestJS. Adaptez-le selon vos besoins spécifiques.
