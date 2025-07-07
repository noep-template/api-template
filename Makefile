# Makefile pour Template API
.PHONY: help install setup dev build test clean docker-up docker-down backup restore deploy

# Variables
PROJECT_NAME ?= template-api
DOCKER_COMPOSE_FILE = docker-compose.yml

# Afficher l'aide
help:
	@echo "🚀 Template API - Commandes disponibles:"
	@echo ""
	@echo "📦 Installation et configuration:"
	@echo "  make install     - Installer les dépendances"
	@echo "  make setup       - Configurer le template (interactif)"
	@echo ""
	@echo "🛠️  Développement:"
	@echo "  make dev         - Démarrer en mode développement"
	@echo "  make build       - Construire l'application"
	@echo "  make test        - Exécuter les tests"
	@echo "  make clean       - Nettoyer les fichiers générés"
	@echo ""
	@echo "🐳 Docker (développement):"
	@echo "  make docker-up   - Démarrer la base de données"
	@echo "  make docker-down - Arrêter la base de données"
	@echo "  make docker-logs - Afficher les logs de la DB"
	@echo "  make docker-clean - Nettoyer et redémarrer la DB"
	@echo ""
	@echo "📦 Sauvegardes et déploiement:"
	@echo "  make backup      - Créer une sauvegarde"
	@echo "  make restore     - Restaurer depuis une sauvegarde"
	@echo ""
	@echo "🔧 Maintenance:"
	@echo "  make migrate     - Exécuter les migrations"
	@echo "  make migrate-gen - Générer une migration"
	@echo "  make lint        - Linter le code"
	@echo "  make format      - Formater le code"
	@echo ""
	@echo "📁 Modules:"
	@echo "  make module.create - Créer un nouveau module"

# Installation des dépendances
install:
	@echo "📦 Installation des dépendances..."
	yarn
	@echo "✅ Dépendances installées"

# Configuration du template
setup:
	@echo "🚀 Configuration du template..."
	@echo "📝 Veuillez fournir les informations suivantes:"
	@read -p "Nom du projet (obligatoire): " project_name; \
	read -p "Description du projet (optionnel): " project_description; \
	read -p "Nom de l'auteur (optionnel): " author_name; \
	read -p "Email de l'auteur (optionnel): " author_email; \
	if [ -f "scripts/setup-template.sh" ]; then \
		chmod +x scripts/setup-template.sh; \
		args="--name \"$$project_name\""; \
		if [ -n "$$project_description" ]; then \
			args="$$args --description \"$$project_description\""; \
		fi; \
		if [ -n "$$author_name" ]; then \
			args="$$args --author \"$$author_name\""; \
		fi; \
		if [ -n "$$author_email" ]; then \
			args="$$args --email \"$$author_email\""; \
		fi; \
		eval "./scripts/setup-template.sh $$args"; \
	else \
		echo "❌ Script de configuration non trouvé"; \
		exit 1; \
	fi

# Mode développement
dev:
	@echo "🛠️  Démarrage en mode développement..."
	yarn run start:dev

# Construction de l'application
build:
	@echo "🔨 Construction de l'application..."
	yarn run build

# Tests
test:
	@echo "🧪 Exécution des tests..."
	yarn run test

# Tests avec couverture
test-cov:
	@echo "🧪 Exécution des tests avec couverture..."
	yarn run test:cov

# Tests e2e
test-e2e:
	@echo "🧪 Exécution des tests e2e..."
	yarn run test:e2e

# Nettoyage
clean:
	@echo "🧹 Nettoyage des fichiers générés..."
	rm -rf dist/
	rm -rf coverage/
	rm -rf node_modules/
	@echo "✅ Nettoyage terminé"

# Docker - Démarrer (développement)
docker-up:
	@echo "🐳 Démarrage de la base de données (développement)..."
	docker compose -f $(DOCKER_COMPOSE_FILE) up -d
	@echo "✅ Base de données démarrée"

# Docker - Nettoyer et redémarrer (développement)
docker-clean:
	@echo "🧹 Nettoyage des conteneurs et volumes..."
	docker compose -f $(DOCKER_COMPOSE_FILE) down -v
	docker compose -f $(DOCKER_COMPOSE_FILE) up -d
	@echo "✅ Base de données nettoyée et redémarrée"

# Docker - Arrêter (développement)
docker-down:
	@echo "🐳 Arrêt de la base de données (développement)..."
	docker compose -f $(DOCKER_COMPOSE_FILE) down
	@echo "✅ Base de données arrêtée"

# Docker - Logs (développement)
docker-logs:
	@echo "📋 Logs de la base de données (développement)..."
	docker compose -f $(DOCKER_COMPOSE_FILE) logs -f

# Docker - Rebuild (développement)
docker-rebuild:
	@echo "🔨 Reconstruction de la base de données (développement)..."
	docker compose -f $(DOCKER_COMPOSE_FILE) down
	docker compose -f $(DOCKER_COMPOSE_FILE) build --no-cache
	docker compose -f $(DOCKER_COMPOSE_FILE) up -d
	@echo "✅ Base de données reconstruite et démarrée"

# Sauvegarde
backup:
	@echo "💾 Création d'une sauvegarde..."
	@if [ -f "scripts/backup.sh" ]; then \
		chmod +x scripts/backup.sh; \
		./scripts/backup.sh; \
	else \
		echo "❌ Script de sauvegarde non trouvé"; \
		exit 1; \
	fi

# Restauration
restore:
	@echo "🔄 Restauration depuis une sauvegarde..."
	@if [ -f "scripts/restore.sh" ]; then \
		chmod +x scripts/restore.sh; \
		./scripts/restore.sh; \
	else \
		echo "❌ Script de restauration non trouvé"; \
		exit 1; \
	fi

# Migrations
migrate:
	@echo "🔄 Exécution des migrations..."
	yarn migrate:run

# Génération de migration
migrate-gen:
	@echo "📝 Génération d'une migration..."
	yarn migrate:generate

# Affichage des migrations
migrate-show:
	@echo "📋 Affichage des migrations..."
	yarn migrate:show

# Création de module
module.create: ## Create module
	@read -p "Entrer le nom du module: " name; \
	upperName=$$(echo $$name | awk '{print toupper(substr($$0,1,1)) tolower(substr($$0,2))}'); \
	allUpperName=$$(echo $$name | awk '{print toupper($$0)}'); \
	nest g module modules/$$name --no-spec; \
	nest g service modules/$$name --no-spec; \
	nest g controller modules/$$name --no-spec; \
	touch ./src/modules/$$name/$$name.entity.ts; \
	echo "import { Entity } from 'typeorm';\nimport { BaseEntity } from '../base.entity';\n\n@Entity()\nexport class $${upperName} extends BaseEntity {}" >> ./src/modules/$$name/$$name.entity.ts; \
	touch ./src/types/api/$$upperName.ts; \
	echo "export interface Create$${upperName}Api {}\n\nexport interface Update$${upperName}Api {}" >> ./src/types/api/$$upperName.ts; \
	echo "export * from './$${upperName}';" >> ./src/types/api/index.ts; \
	touch ./src/types/dto/$$upperName.ts; \
	echo "import { BaseDto } from './BaseDto';\n\nexport interface $${upperName}Dto extends BaseDto {}" >> ./src/types/dto/$$upperName.ts; \
	echo "export * from './$${upperName}';" >> ./src/types/dto/index.ts; \
	touch ./src/validations/$$name.ts; \
	echo "import { Create$${upperName}Api, Update$${upperName}Api } from 'src/types';\nimport * as yup from 'yup';\n\nconst create: yup.ObjectSchema<Create$${upperName}Api> = yup.object({});\n\nconst update: yup.ObjectSchema<Update$${upperName}Api> = yup.object({});\n\nexport const $${name}Validation = {\n  create,\n  update,\n};" >> ./src/validations/$$name.ts; \
	echo "export * from './$${name}';" >> ./src/validations/index.ts;

# Linting
lint:
	@echo "🔍 Linting du code..."
	yarn run lint

# Formatage
format:
	@echo "✨ Formatage du code..."
	yarn run format

# Configuration des sauvegardes automatiques
setup-backup-cron:
	@echo "⏰ Configuration des sauvegardes automatiques..."
	@if [ -f "scripts/setup-backup-cron.sh" ]; then \
		chmod +x scripts/setup-backup-cron.sh; \
		./scripts/setup-backup-cron.sh daily 02:00; \
	else \
		echo "❌ Script de configuration cron non trouvé"; \
		exit 1; \
	fi

# Affichage des sauvegardes
list-backups:
	@echo "📋 Liste des sauvegardes..."
	@if [ -f "scripts/list-backups.sh" ]; then \
		chmod +x scripts/list-backups.sh; \
		./scripts/list-backups.sh; \
	else \
		echo "❌ Script de listing des sauvegardes non trouvé"; \
		exit 1; \
	fi

# Nettoyage des sauvegardes
cleanup-backups:
	@echo "🧹 Nettoyage des anciennes sauvegardes..."
	@if [ -f "scripts/list-backups.sh" ]; then \
		chmod +x scripts/list-backups.sh; \
		./scripts/list-backups.sh cleanup; \
	else \
		echo "❌ Script de nettoyage non trouvé"; \
		exit 1; \
	fi

# Installation complète (pour nouveaux projets)
install-full: install setup docker-up migrate-gen migrate 
	@echo "🎉 Installation complète terminée!"
	@echo "📋 Prochaines étapes:"
	@echo "1. Configurer le fichier .env"
	@echo "2. Démarrer l'application: make dev"
	@echo "3. Accéder à l'API: http://localhost:8000"
	@echo "4. Documentation Swagger: http://localhost:8000/api"
	@echo ""
	@echo "💡 Note: Le docker-compose.yml démarre seulement la base de données"
	@echo "   L'API s'exécute en local avec 'make dev'"