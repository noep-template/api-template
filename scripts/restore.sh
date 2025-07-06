#!/bin/bash

# Script de restauration unifié Fast Foodie
# Restaure la base de données et/ou les images

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
DB_BACKUP_DIR="${BACKUP_DIR}"
IMAGES_BACKUP_DIR="${BACKUP_DIR}/images"
CONTAINER_NAME="fast-foodie-api"

# Fonction de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Fonction d'aide
show_help() {
    echo "🔄 Script de restauration unifié Fast Foodie"
    echo ""
    echo "Usage: $0 <fichier_sauvegarde> [options]"
    echo ""
    echo "Arguments:"
    echo "  fichier_sauvegarde    Nom du fichier de sauvegarde"
    echo "                        - *.sql pour la base de données"
    echo "                        - *.tar.gz pour les images"
    echo ""
    echo "Options:"
    echo "  -h, --help     Afficher cette aide"
    echo "  -f, --force    Forcer la restauration sans confirmation"
    echo "  -v, --verbose  Mode verbeux"
    echo ""
    echo "Exemples:"
    echo "  $0 fast_foodie_backup_20241201_020000.sql"
    echo "  $0 images_backup_20241201_020000.tar.gz"
    echo "  $0 fast_foodie_backup_20241201_020000.sql --force"
    echo "  $0 images_backup_20241201_020000.tar.gz --verbose"
}

# Variables
FORCE=false
VERBOSE=false

# Traiter les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -*)
            echo "❌ Option inconnue: $1"
            show_help
            exit 1
            ;;
        *)
            BACKUP_FILE="$1"
            shift
            ;;
    esac
done

# Vérifier qu'un fichier de sauvegarde a été spécifié
if [ -z "$BACKUP_FILE" ]; then
    echo "❌ Erreur: Veuillez spécifier un fichier de sauvegarde"
    echo ""
    echo "📋 Sauvegardes disponibles:"
    echo ""
    echo "🗄️  Base de données:"
    ls -la "${DB_BACKUP_DIR}"/*.sql 2>/dev/null || echo "   Aucune sauvegarde DB trouvée"
    echo ""
    echo "🖼️  Images:"
    ls -la "${IMAGES_BACKUP_DIR}"/images_backup_*.tar.gz 2>/dev/null || echo "   Aucune sauvegarde d'images trouvée"
    echo ""
    show_help
    exit 1
fi

# Déterminer le type de sauvegarde et le chemin
if [[ "$BACKUP_FILE" == *.sql ]]; then
    BACKUP_TYPE="Base de données"
    BACKUP_PATH="${DB_BACKUP_DIR}/${BACKUP_FILE}"
    RESTORE_FUNCTION="restore_db"
elif [[ "$BACKUP_FILE" == *.tar.gz ]]; then
    BACKUP_TYPE="Images"
    BACKUP_PATH="${IMAGES_BACKUP_DIR}/${BACKUP_FILE}"
    RESTORE_FUNCTION="restore_images"
else
    # Essayer les deux chemins
    if [ -f "${DB_BACKUP_DIR}/${BACKUP_FILE}" ]; then
        BACKUP_TYPE="Base de données"
        BACKUP_PATH="${DB_BACKUP_DIR}/${BACKUP_FILE}"
        RESTORE_FUNCTION="restore_db"
    elif [ -f "${IMAGES_BACKUP_DIR}/${BACKUP_FILE}" ]; then
        BACKUP_TYPE="Images"
        BACKUP_PATH="${IMAGES_BACKUP_DIR}/${BACKUP_FILE}"
        RESTORE_FUNCTION="restore_images"
    else
        echo "❌ Erreur: Le fichier de sauvegarde '${BACKUP_FILE}' n'existe pas"
        echo ""
        echo "📋 Sauvegardes disponibles:"
        echo ""
        echo "🗄️  Base de données:"
        ls -la "${DB_BACKUP_DIR}"/*.sql 2>/dev/null || echo "   Aucune sauvegarde DB trouvée"
        echo ""
        echo "🖼️  Images:"
        ls -la "${IMAGES_BACKUP_DIR}"/images_backup_*.tar.gz 2>/dev/null || echo "   Aucune sauvegarde d'images trouvée"
        exit 1
    fi
fi

log "🔄 Début de la restauration: ${BACKUP_TYPE}"
log "📄 Fichier de sauvegarde: ${BACKUP_FILE}"

# Demander confirmation sauf si --force
if [ "$FORCE" = false ]; then
    echo ""
    echo "⚠️  ATTENTION: Cette opération va écraser les données actuelles!"
    echo "📋 Type: ${BACKUP_TYPE}"
    echo "📄 Fichier: ${BACKUP_FILE}"
    echo ""
    read -p "Êtes-vous sûr de vouloir continuer? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "❌ Restauration annulée par l'utilisateur"
        exit 1
    fi
fi

# Fonction de restauration de la base de données
restore_db() {
    log "🗄️  Restauration de la base de données..."
    
    # Variables d'environnement pour la DB
    DB_HOST=${TYPEORM_HOST:-"fast-foodie-db"}
    DB_PORT=${TYPEORM_PORT:-"5432"}
    DB_NAME=${TYPEORM_DATABASE:-"fast_foodie_db"}
    DB_USER=${TYPEORM_USERNAME:-"postgres"}
    DB_PASSWORD=${TYPEORM_PASSWORD:-""}
    
    # Vérifier que le conteneur DB est en cours d'exécution
    if ! docker ps | grep -q "fast-foodie-db"; then
        log "❌ Le conteneur fast-foodie-db n'est pas en cours d'exécution"
        exit 1
    fi
    
    # Créer une sauvegarde de sécurité avant restauration
    log "🛡️  Création d'une sauvegarde de sécurité..."
    SAFETY_BACKUP="${DB_BACKUP_DIR}/safety_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    docker exec -e PGPASSWORD="${DB_PASSWORD}" fast-foodie-db pg_dump \
        -U "${DB_USER}" \
        -d "${DB_NAME}" \
        --verbose \
        --clean \
        --if-exists \
        --create \
        --no-owner \
        --no-privileges \
        --format=plain \
        > "${SAFETY_BACKUP}"
    
    log "✅ Sauvegarde de sécurité créée: $(basename "${SAFETY_BACKUP}")"
    
    # Effectuer la restauration
    log "🔄 Restauration de la base de données..."
    
    if docker exec -i fast-foodie-db psql \
        -U "${DB_USER}" \
        -d "postgres" \
        < "${BACKUP_PATH}"; then
        
        log "✅ Restauration de la base de données terminée avec succès!"
        log "📊 Base de données '${DB_NAME}' restaurée depuis '${BACKUP_FILE}'"
    else
        log "❌ Erreur lors de la restauration de la base de données"
        log "💡 Vous pouvez restaurer la sauvegarde de sécurité: $(basename "${SAFETY_BACKUP}")"
        exit 1
    fi
}

# Fonction de restauration des images
restore_images() {
    log "🖼️  Restauration des images..."
    
    # Vérifier que le conteneur API est en cours d'exécution
    if ! docker ps | grep -q "${CONTAINER_NAME}"; then
        log "❌ Le conteneur ${CONTAINER_NAME} n'est pas en cours d'exécution"
        exit 1
    fi
    
    # Créer une sauvegarde de sécurité avant restauration
    SAFETY_BACKUP="images_safety_$(date '+%Y%m%d_%H%M%S').tar.gz"
    SAFETY_PATH="${IMAGES_BACKUP_DIR}/${SAFETY_BACKUP}"
    
    if docker exec "${CONTAINER_NAME}" test -d "/app/public/files" && [ "$(docker exec "${CONTAINER_NAME}" ls -A "/app/public/files" 2>/dev/null)" ]; then
        log "🛡️  Création d'une sauvegarde de sécurité: ${SAFETY_BACKUP}"
        
        if [ "$VERBOSE" = true ]; then
            docker exec "${CONTAINER_NAME}" tar -czf - -C "/app/public/files" . > "$SAFETY_PATH"
        else
            docker exec "${CONTAINER_NAME}" tar -czf - -C "/app/public/files" . > "$SAFETY_PATH" 2>/dev/null
        fi
        
        log "✅ Sauvegarde de sécurité créée: ${SAFETY_BACKUP}"
    fi
    
    # Sauvegarder les images actuelles si elles existent
    if docker exec "${CONTAINER_NAME}" test -d "/app/public/files" && [ "$(docker exec "${CONTAINER_NAME}" ls -A "/app/public/files" 2>/dev/null)" ]; then
        log "📦 Sauvegarde des images actuelles..."
        CURRENT_BACKUP="images_current_$(date '+%Y%m%d_%H%M%S').tar.gz"
        CURRENT_PATH="${IMAGES_BACKUP_DIR}/${CURRENT_BACKUP}"
        
        if [ "$VERBOSE" = true ]; then
            docker exec "${CONTAINER_NAME}" tar -czf - -C "/app/public/files" . > "$CURRENT_PATH"
        else
            docker exec "${CONTAINER_NAME}" tar -czf - -C "/app/public/files" . > "$CURRENT_PATH" 2>/dev/null
        fi
        
        log "✅ Images actuelles sauvegardées: ${CURRENT_BACKUP}"
    fi
    
    # Vider le répertoire de destination
    log "🧹 Nettoyage du répertoire de destination..."
    docker exec "${CONTAINER_NAME}" rm -rf "/app/public/files"/*
    docker exec "${CONTAINER_NAME}" mkdir -p "/app/public/files"
    
    # Restaurer les images
    log "🔄 Restauration des images depuis: ${BACKUP_FILE}"
    
    if [ "$VERBOSE" = true ]; then
        cat "$BACKUP_PATH" | docker exec -i "${CONTAINER_NAME}" tar -xzf - -C "/app/public/files"
    else
        cat "$BACKUP_PATH" | docker exec -i "${CONTAINER_NAME}" tar -xzf - -C "/app/public/files" >/dev/null 2>&1
    fi
    
    # Vérifier que la restauration a réussi
    RESTORED_COUNT=$(docker exec "${CONTAINER_NAME}" find "/app/public/files" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" -o -name "*.webp" \) | wc -l)
    
    if [ "$RESTORED_COUNT" -eq 0 ]; then
        log "⚠️  Aucune image restaurée. Vérifiez le contenu de la sauvegarde."
    else
        log "✅ Restauration terminée: ${RESTORED_COUNT} image(s) restaurée(s)"
    fi
    
    # Afficher les informations finales
    log "📊 Informations finales:"
    BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
    log "   📦 Taille de la sauvegarde: ${BACKUP_SIZE}"
    log "   📁 Répertoire de destination: /app/public/files"
    log "   🖼️  Images restaurées: ${RESTORED_COUNT}"
    
    log "🎉 Restauration des images terminée avec succès!"
    log "💡 Sauvegarde de sécurité conservée: ${SAFETY_BACKUP}"
}

# Exécuter la fonction de restauration appropriée
$RESTORE_FUNCTION 