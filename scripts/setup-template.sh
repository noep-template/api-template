#!/bin/bash

# Script de configuration du template API
set -e

echo "🚀 Configuration du template API..."

# Variables
PROJECT_NAME=""
PROJECT_DESCRIPTION=""
AUTHOR_NAME=""
AUTHOR_EMAIL=""

# Fonction d'aide
show_help() {
    echo "🔄 Script de configuration du template API"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -n, --name        Nom du projet (obligatoire)"
    echo "  -d, --description Description du projet"
    echo "  -a, --author      Nom de l'auteur"
    echo "  -e, --email       Email de l'auteur"
    echo "  -h, --help        Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 --name my-api --description 'Mon API NestJS'"
    echo "  $0 -n my-api -d 'Mon API' -a 'John Doe' -e 'john@example.com'"
}

# Traiter les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -n|--name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -d|--description)
            PROJECT_DESCRIPTION="$2"
            shift 2
            ;;
        -a|--author)
            AUTHOR_NAME="$2"
            shift 2
            ;;
        -e|--email)
            AUTHOR_EMAIL="$2"
            shift 2
            ;;
        *)
            echo "❌ Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Vérifier que le nom du projet est fourni
if [ -z "$PROJECT_NAME" ]; then
    echo "❌ Le nom du projet est obligatoire"
    show_help
    exit 1
fi

# Valeurs par défaut
PROJECT_DESCRIPTION=${PROJECT_DESCRIPTION:-"API NestJS avec authentification, upload de fichiers et base de données PostgreSQL"}
AUTHOR_NAME=${AUTHOR_NAME:-"Développeur"}
AUTHOR_EMAIL=${AUTHOR_EMAIL:-"dev@example.com"}

echo "📝 Configuration du projet:"
echo "  Nom: $PROJECT_NAME"
echo "  Description: $PROJECT_DESCRIPTION"
echo "  Auteur: $AUTHOR_NAME"
echo "  Email: $AUTHOR_EMAIL"
echo ""

# Demander confirmation
read -p "Continuer avec cette configuration? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Configuration annulée"
    exit 1
fi

echo "🔧 Mise à jour des fichiers..."

# Mettre à jour package.json
if [ -f "package.json" ]; then
    echo "📦 Mise à jour package.json..."
    sed -i '' "s/\"name\": \"api-template\"/\"name\": \"$PROJECT_NAME\"/" package.json
    sed -i '' "s/\"description\": \"Template API NestJS avec authentification, upload de fichiers et base de données PostgreSQL\"/\"description\": \"$PROJECT_DESCRIPTION\"/" package.json
    sed -i '' "s/\"author\": \"\"/\"author\": \"$AUTHOR_NAME <$AUTHOR_EMAIL>\"/" package.json
fi

# Mettre à jour docker-compose.api.yml
if [ -f "docker-compose.api.yml" ]; then
    echo "🐳 Mise à jour docker-compose.api.yml..."
    sed -i '' "s/template-api/${PROJECT_NAME}-api/g" docker-compose.api.yml
    sed -i '' "s/template-db/${PROJECT_NAME}-db/g" docker-compose.api.yml
    sed -i '' "s/template-network/${PROJECT_NAME}-network/g" docker-compose.api.yml
    sed -i '' "s/template-api:${SHA}/${PROJECT_NAME}-api:${SHA}/g" docker-compose.api.yml
fi

# Mettre à jour docker-compose.yml (développement local)
if [ -f "docker-compose.yml" ]; then
    echo "🐳 Mise à jour docker-compose.yml..."
    sed -i '' "s/template-db/${PROJECT_NAME}-db/g" docker-compose.yml
    sed -i '' "s/container_name: template-db/container_name: ${PROJECT_NAME}-db/g" docker-compose.yml
    sed -i '' "s/template-api/${PROJECT_NAME}-api/g" docker-compose.yml
fi

# Mettre à jour les scripts
echo "📜 Mise à jour des scripts..."
find scripts/ -name "*.sh" -type f -exec sed -i '' "s/template-api/${PROJECT_NAME}-api/g" {} \;
find scripts/ -name "*.sh" -type f -exec sed -i '' "s/template-db/${PROJECT_NAME}-db/g" {} \;
find scripts/ -name "*.sh" -type f -exec sed -i '' "s/template_backup/${PROJECT_NAME}_backup/g" {} \;
find scripts/ -name "*.sh" -type f -exec sed -i '' "s/template/$PROJECT_NAME/g" {} \;

# Mettre à jour le workflow GitHub Actions
if [ -f ".github/workflows/deploy.yml" ]; then
    echo "⚙️  Mise à jour du workflow GitHub Actions..."
    sed -i '' "s/template-api/${PROJECT_NAME}-api/g" .github/workflows/deploy.yml
    sed -i '' "s|~/api-template|~/$(echo $PROJECT_NAME | tr '-' '_')|g" .github/workflows/deploy.yml
fi

# Mettre à jour le README
if [ -f "README.md" ]; then
    echo "📖 Mise à jour du README..."
    # Capitaliser la première lettre du nom du projet
    PROJECT_NAME_CAPITALIZED=$(echo "$PROJECT_NAME" | sed 's/^./\U&/')
    sed -i '' "s/Template API NestJS/${PROJECT_NAME_CAPITALIZED} API/" README.md
    sed -i '' "s/template-api/${PROJECT_NAME}-api/g" README.md
    sed -i '' "s/template_db/${PROJECT_NAME}_db/g" README.md
fi

# Créer le fichier .env
if [ ! -f ".env" ]; then
    echo "🔐 Création du fichier .env..."
    cp scripts/env.example .env
    echo "✅ Fichier .env créé. N'oubliez pas de le configurer!"
    echo "📝 Variables importantes à configurer :"
    echo "  - TYPEORM_PASSWORD : Mot de passe de votre base de données (actuellement: Azerty12!)"
    echo "  - JWT_SECRET : Secret JWT (actuellement: jwt - à changer pour la production)"
    echo "  - CRYPTO_SECRET : Secret pour le chiffrement (actuellement: test - à changer)"
    echo "  - API_KEY : Clé API pour l'authentification (actuellement: TODO:replace)"
else
    echo "ℹ️  Fichier .env existe déjà"
fi

# Rendre les scripts exécutables
echo "🔧 Rendre les scripts exécutables..."
chmod +x scripts/*.sh

echo ""
echo "✅ Configuration terminée avec succès!"
echo ""
echo "📋 Prochaines étapes:"
echo "1. Configurer le fichier .env avec vos paramètres"
echo "2. Installer les dépendances: yarn install"
echo "3. Démarrer la base de données: docker compose up -d ${PROJECT_NAME}-db"
echo "4. Exécuter les migrations: yarn run migrate"
echo "5. Démarrer l'application: yarn run start:dev"
echo ""
echo "🎉 Votre projet ${PROJECT_NAME} est prêt!" 