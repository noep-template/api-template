# Scripts de gestion Template API

Ce dossier contient les scripts de gestion pour l'application Template API, incluant les sauvegardes, restaurations et maintenance.

## 📋 Scripts disponibles

### 🚀 Configuration initiale

#### `setup-template.sh` - Configuration du template

Configure et personnalise le template pour votre projet.

```bash
# Configuration basique
./setup-template.sh --name my-api

# Configuration complète
./setup-template.sh \
  --name my-api \
  --description "Mon API NestJS personnalisée" \
  --author "John Doe" \
  --email "john@example.com"

# Afficher l'aide
./setup-template.sh --help
```

### 🔄 Scripts unifiés (recommandés)

#### `backup.sh` - Sauvegarde unifiée

Sauvegarde la base de données et/ou les images en une seule commande.

```bash
# Sauvegarde complète (DB + images)
./backup.sh

# Sauvegarde DB seulement
./backup.sh --db

# Sauvegarde images seulement
./backup.sh --images

# Sauvegarde forcée (même si pas de changements)
./backup.sh --force

# Mode verbeux
./backup.sh --verbose
```

#### `list-backups.sh` - Listing unifié

Liste, affiche les informations et supprime les sauvegardes.

```bash
# Lister toutes les sauvegardes
./list-backups.sh

# Lister seulement les sauvegardes DB
./list-backups.sh list --db

# Lister seulement les sauvegardes images
./list-backups.sh list --images

# Afficher les infos d'une sauvegarde
./list-backups.sh info template_backup_20241201_020000.sql
./list-backups.sh info images_backup_20241201_020000.tar.gz

# Supprimer une sauvegarde
./list-backups.sh delete template_backup_20241201_020000.sql

# Nettoyer les anciennes sauvegardes
./list-backups.sh cleanup

# Afficher les statistiques
./list-backups.sh stats
```

#### `restore.sh` - Restauration unifiée

Restaure la base de données ou les images depuis une sauvegarde.

```bash
# Restaurer la base de données
./restore.sh template_backup_20241201_020000.sql

# Restaurer les images
./restore.sh images_backup_20241201_020000.tar.gz

# Restauration forcée (sans confirmation)
./restore.sh template_backup_20241201_020000.sql --force

# Mode verbeux
./restore.sh images_backup_20241201_020000.tar.gz --verbose
```

### 🔧 Scripts spécialisés (anciens)

#### `backup-db.sh` - Sauvegarde base de données

```bash
./backup-db.sh [backup_name]
```

#### `backup-images.sh` - Sauvegarde images

```bash
./backup-images.sh [options]
# Options: --force, --verbose
```

#### `restore-db.sh` - Restauration base de données

```bash
./restore-db.sh <backup_file>
```

#### `restore-images.sh` - Restauration images

```bash
./restore-images.sh <backup_file> [options]
# Options: --force, --verbose
```

#### `list-image-backups.sh` - Gestion sauvegardes images

```bash
./list-image-backups.sh [commande] [options]
# Commandes: list, info, delete, cleanup, stats
# Options: --verbose
```

### ⚙️ Scripts de maintenance

#### `setup-backup-cron.sh` - Configuration cron

Configure la tâche cron pour les sauvegardes automatiques.

```bash
./setup-backup-cron.sh
```

## 📊 Configuration

### Variables d'environnement

- `BACKUP_DIR` : Répertoire de sauvegarde (défaut: `./backups`)
- `TYPEORM_HOST` : Host de la base de données
- `TYPEORM_PORT` : Port de la base de données
- `TYPEORM_DATABASE` : Nom de la base de données
- `TYPEORM_USERNAME` : Utilisateur de la base de données
- `TYPEORM_PASSWORD` : Mot de passe de la base de données

### Structure des sauvegardes

```
backups/
├── *.sql                    # Sauvegardes de base de données
└── images/
    └── images_backup_*.tar.gz  # Sauvegardes d'images
```

## 🔄 Sauvegardes automatiques

Les sauvegardes automatiques sont configurées via cron et s'exécutent :

- **Tous les jours à 2h00** : Sauvegarde complète (DB + images)
- **À chaque déploiement** : Sauvegarde de sécurité

### Rotation des sauvegardes

- **Base de données** : 7 sauvegardes maximum
- **Images** : 3 sauvegardes maximum

## 🛡️ Sécurité

### Sauvegardes de sécurité

Avant chaque restauration, une sauvegarde de sécurité est automatiquement créée :

- `safety_backup_YYYYMMDD_HHMMSS.sql` pour la DB
- `images_safety_YYYYMMDD_HHMMSS.tar.gz` pour les images

### Vérifications

- Vérification de l'existence des conteneurs Docker
- Vérification de l'existence des fichiers de sauvegarde
- Confirmation utilisateur (sauf avec `--force`)

## 💡 Bonnes pratiques

1. **Utilisez les scripts unifiés** pour une meilleure expérience
2. **Testez les restaurations** dans un environnement de développement
3. **Vérifiez les sauvegardes** avant de supprimer des données
4. **Utilisez `--force` avec précaution** en production
5. **Surveillez l'espace disque** des sauvegardes

## 🚨 Dépannage

### Erreurs courantes

- **Conteneur non trouvé** : Vérifiez que Docker est démarré
- **Permission refusée** : Vérifiez les droits d'exécution (`chmod +x scripts/*.sh`)
- **Fichier non trouvé** : Vérifiez le chemin et l'existence du fichier
- **Espace disque insuffisant** : Nettoyez les anciennes sauvegardes

### Commandes utiles

```bash
# Rendre les scripts exécutables
chmod +x scripts/*.sh

# Vérifier les cron
crontab -l

# Vérifier les logs
tail -f /var/log/syslog | grep backup

# Nettoyer manuellement
./list-backups.sh cleanup
```
