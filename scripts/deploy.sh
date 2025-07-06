#!/bin/bash

# Script de déploiement pour Fast Foodie API
set -e

echo "🚀 Démarrage du déploiement..."

# Variables
PROJECT_DIR="$HOME/fast-foodie"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.api.yml"
BACKUP_DIR="$PROJECT_DIR/backups"

# Créer le répertoire de projet s'il n'existe pas
mkdir -p "$PROJECT_DIR"
mkdir -p "$BACKUP_DIR"

# Vérifier la présence du fichier .env
if [ -f "$PROJECT_DIR/.env" ]; then
    echo "✅ Fichier .env trouvé"
else
    echo "⚠️  Fichier .env non trouvé dans $PROJECT_DIR"
fi

# Fonction de sauvegarde
backup_database() {
    echo "📦 Sauvegarde de la base de données..."
    
    # Vérifier si le conteneur de base de données existe et fonctionne
    if docker ps | grep -q "fast-foodie-db"; then
        echo "✅ Conteneur de base de données trouvé, sauvegarde en cours..."
        
        # Déboguer les variables d'environnement
        echo "🔍 Débogage des variables d'environnement:"
        echo "  TYPEORM_HOST: ${TYPEORM_HOST:-non défini}"
        echo "  TYPEORM_PORT: ${TYPEORM_PORT:-non défini}"
        echo "  TYPEORM_USERNAME: ${TYPEORM_USERNAME:-non défini}"
        echo "  TYPEORM_DATABASE: ${TYPEORM_DATABASE:-non défini}"
        echo "  TYPEORM_PASSWORD: ${TYPEORM_PASSWORD:+défini}"
        
        if [ -f "$PROJECT_DIR/scripts/backup.sh" ]; then
            chmod +x "$PROJECT_DIR/scripts/backup.sh"
            # Exécuter le script de sauvegarde unifié avec le bon répertoire
            cd "$PROJECT_DIR"
            BACKUP_DIR="$BACKUP_DIR" "$PROJECT_DIR/scripts/backup.sh"
        else
            echo "❌ Script de sauvegarde non trouvé: $PROJECT_DIR/scripts/backup.sh"
        fi
    else
        echo "⚠️  Conteneur de base de données non trouvé, pas de sauvegarde"
        echo "ℹ️  C'est normal pour le premier déploiement"
    fi
}

# Fonction de nettoyage
cleanup() {
    echo "🧹 Nettoyage des images Docker..."
    docker image prune -f
    docker system prune -f --volumes
    
    # Nettoyer les fichiers de développement s'ils existent
    echo "🧹 Nettoyage des fichiers de développement..."
    cd "$PROJECT_DIR"
    rm -rf src/ package*.json tsconfig*.json nest-cli.json ormconfig.ts Dockerfile* 2>/dev/null || true
    echo "✅ Fichiers de développement supprimés"
}

# Fonction de déploiement
deploy() {
    echo "🔧 Déploiement de l'application..."
    
    # Arrêter les conteneurs existants
    if [ -f "$COMPOSE_FILE" ]; then
        echo "⏹️  Arrêt des conteneurs existants..."
        docker compose -f "$COMPOSE_FILE" down
    fi
    
    # Login to ghcr.io if CR_PAT is available
    if [ -n "$CR_PAT" ]; then
        echo "$CR_PAT" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin
    fi
    
    # Pull et démarrer les conteneurs
    echo "⬇️  Téléchargement et démarrage des conteneurs..."
    if docker compose -f "$COMPOSE_FILE" pull && docker compose -f "$COMPOSE_FILE" up -d; then
        echo "✅ Conteneurs démarrés avec succès"
    else
        echo "❌ Erreur lors du démarrage des conteneurs"
        echo "📋 Logs des conteneurs:"
        docker compose -f "$COMPOSE_FILE" logs
        exit 1
    fi
    
    # Vérifier le statut immédiatement
    echo "📊 Statut des conteneurs:"
    docker compose -f "$COMPOSE_FILE" ps
    
    # Attendre un peu et vérifier les logs
    echo "⏳ Attente de 5 secondes pour le démarrage..."
    sleep 5
    
    echo "📋 Logs du conteneur API:"
    docker logs fast-foodie-api --tail 20 || echo "Impossible de récupérer les logs du conteneur API"
    
    echo "📋 Logs du conteneur base de données:"
    docker logs fast-foodie-db --tail 10 || echo "Impossible de récupérer les logs du conteneur DB"
}

# Fonction de vérification de santé
health_check() {
    echo "🏥 Vérification de la santé de l'application..."
    
    # Afficher les logs du conteneur API pour diagnostiquer
    echo "📋 Logs du conteneur API:"
    docker logs fast-foodie-api --tail 20 || echo "Impossible de récupérer les logs"
    
    echo "📋 Logs du conteneur base de données:"
    docker logs fast-foodie-db --tail 10 || echo "Impossible de récupérer les logs"
    
    sleep 10
    
    # Attendre que l'API soit prête
    for i in {1..30}; do
        if curl -f http://localhost:8000/health > /dev/null 2>&1; then
            echo "✅ L'application est prête!"
            return 0
        fi
        echo "⏳ Attente... ($i/30)"
        sleep 2
    done
    
    echo "❌ L'application n'a pas démarré correctement"
    echo "📋 Logs finaux du conteneur API:"
    docker logs fast-foodie-api --tail 50 || echo "Impossible de récupérer les logs"
    return 1
}

# Exécution principale
main() {
    deploy
    # Sauvegarde seulement si c'est pas le premier déploiement
    if docker ps | grep -q "fast-foodie-db"; then
        backup_database
    else
        echo "ℹ️  Premier déploiement, pas de sauvegarde"
    fi
    cleanup
    health_check
    
    echo "🎉 Déploiement terminé avec succès!"
}

# Gestion des erreurs
trap 'echo "❌ Erreur lors du déploiement"; exit 1' ERR

# Exécuter le script principal
main "$@" 