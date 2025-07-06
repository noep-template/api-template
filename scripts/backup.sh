#!/bin/bash

# Script de sauvegarde unifié Template API
# Sauvegarde la base de données et les images

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
# S'assurer que le chemin est absolu si nécessaire
if [[ "$BACKUP_DIR" == ./* ]]; then
    BACKUP_DIR="$(pwd)/${BACKUP_DIR#./}"
fi
DB_BACKUP_DIR="${BACKUP_DIR}"
IMAGES_BACKUP_DIR="${BACKUP_DIR}/images"
CONTAINER_NAME="template-api"
MAX_DB_BACKUPS=7
MAX_IMAGE_BACKUPS=3

# Fonction de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Fonction d'aide
show_help() {
    echo "🔄 Script de sauvegarde unifié Template API"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Afficher cette aide"
    echo "  -d, --db       Sauvegarder seulement la base de données"
    echo "  -i, --images   Sauvegarder seulement les images"
    echo "  -f, --force    Forcer la sauvegarde même si pas de changements"
    echo "  -v, --verbose  Mode verbeux"
    echo ""
    echo "Exemples:"
    echo "  $0              # Sauvegarde complète (DB + images)"
    echo "  $0 --db         # Sauvegarde DB seulement"
    echo "  $0 --images     # Sauvegarde images seulement"
    echo "  $0 --force      # Sauvegarde forcée"
    echo "  $0 --verbose    # Mode détaillé"
}

# Variables
BACKUP_DB=true
BACKUP_IMAGES=true
FORCE=false
VERBOSE=false

# Traiter les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--db)
            BACKUP_DB=true
            BACKUP_IMAGES=false
            shift
            ;;
        -i|--images)
            BACKUP_DB=false
            BACKUP_IMAGES=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "❌ Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

log "🚀 Début de la sauvegarde unifiée Template API..."

# Créer les répertoires de sauvegarde
mkdir -p "${DB_BACKUP_DIR}"
mkdir -p "${IMAGES_BACKUP_DIR}"

# Vérifier que les répertoires ont été créés
if [ ! -d "${IMAGES_BACKUP_DIR}" ]; then
    log "❌ Impossible de créer le répertoire de sauvegarde images: ${IMAGES_BACKUP_DIR}"
    exit 1
fi

# Charger les variables d'environnement depuis .env
if [ -f ".env" ]; then
    log "📄 Chargement des variables d'environnement depuis .env..."
    export $(grep -v '^#' .env | xargs)
fi

# Variables d'environnement pour la DB
DB_HOST=${TYPEORM_HOST:-"template-db"}
DB_PORT=${TYPEORM_PORT:-"5432"}
DB_NAME=${TYPEORM_DATABASE:-"template_db"}
DB_USER=${TYPEORM_USERNAME:-"postgres"}
DB_PASSWORD=${TYPEORM_PASSWORD:-""}

# Sauvegarde de la base de données
if [ "$BACKUP_DB" = true ]; then
    log "💾 Sauvegarde de la base de données..."
    
    # Vérifier que le conteneur DB est en cours d'exécution
    if ! docker ps | grep -q "template-db"; then
        log "❌ Le conteneur template-db n'est pas en cours d'exécution"
        exit 1
    fi
    
    # Nom du fichier de sauvegarde DB
    DATE=$(date +%Y%m%d_%H%M%S)
    DB_BACKUP_NAME="template_backup_${DATE}"
    DB_BACKUP_FILE="${DB_BACKUP_DIR}/${DB_BACKUP_NAME}.sql"
    
    log "📄 Création du dump de la base de données..."
    
    # Effectuer la sauvegarde DB
    if docker exec -e PGPASSWORD="${DB_PASSWORD}" template-db pg_dump \
        -U "${DB_USER}" \
        -d "${DB_NAME}" \
        --verbose \
        --clean \
        --if-exists \
        --create \
        --no-owner \
        --no-privileges \
        --format=plain \
        > "${DB_BACKUP_FILE}"; then
        
        DB_SIZE=$(du -h "${DB_BACKUP_FILE}" | cut -f1)
        log "✅ Sauvegarde DB créée: ${DB_BACKUP_NAME}.sql (${DB_SIZE})"
        
        # Nettoyer les anciennes sauvegardes DB
        log "🧹 Nettoyage des anciennes sauvegardes DB..."
        cd "${DB_BACKUP_DIR}"
        BACKUP_COUNT=$(ls -1 *.sql 2>/dev/null | wc -l)
        if [ "$BACKUP_COUNT" -gt "$MAX_DB_BACKUPS" ]; then
            ls -1t *.sql | tail -n +$((MAX_DB_BACKUPS + 1)) | xargs rm -f
            log "✅ Nettoyage DB terminé"
        else
            log "ℹ️  Pas de nettoyage DB nécessaire ($BACKUP_COUNT sauvegardes)"
        fi
    else
        log "❌ Erreur lors de la sauvegarde de la base de données"
        exit 1
    fi
fi

# Sauvegarde des images
if [ "$BACKUP_IMAGES" = true ]; then
    log "🖼️  Sauvegarde des images..."
    
    # Vérifier que le conteneur API est en cours d'exécution
    if ! docker ps | grep -q "${CONTAINER_NAME}"; then
        log "❌ Le conteneur ${CONTAINER_NAME} n'est pas en cours d'exécution"
        exit 1
    fi
    
    # Vérifier que le répertoire des images existe dans le conteneur
    if ! docker exec "${CONTAINER_NAME}" test -d "/app/public/files"; then
        log "❌ Le répertoire des images n'existe pas dans le conteneur"
        exit 1
    fi
    
    # Nom du fichier de sauvegarde images
    DATE=$(date +%Y%m%d_%H%M%S)
    IMAGES_BACKUP_NAME="images_backup_${DATE}"
    IMAGES_BACKUP_FILE="${IMAGES_BACKUP_DIR}/${IMAGES_BACKUP_NAME}.tar.gz"
    
    # Vérifier s'il y a des images à sauvegarder
    IMAGE_COUNT=$(docker exec "${CONTAINER_NAME}" find "/app/public/files" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" -o -name "*.webp" \) | wc -l)
    
    if [ "$IMAGE_COUNT" -eq 0 ]; then
        log "ℹ️  Aucune image trouvée"
    else
        log "📊 Nombre d'images trouvées: ${IMAGE_COUNT}"
        
        # Vérifier s'il y a eu des changements depuis la dernière sauvegarde
        if [ "$FORCE" = false ]; then
            LAST_BACKUP=$(ls -t "${IMAGES_BACKUP_DIR}"/images_backup_*.tar.gz 2>/dev/null | head -1)
            if [ -n "$LAST_BACKUP" ]; then
                LAST_BACKUP_TIME=$(stat -c %Y "$LAST_BACKUP")
                IMAGES_MOD_TIME=$(docker exec "${CONTAINER_NAME}" find "/app/public/files" -type f -printf '%T@\n' | sort -n | tail -1)
                
                if [ "$IMAGES_MOD_TIME" -le "$LAST_BACKUP_TIME" ]; then
                    log "ℹ️  Aucun changement détecté depuis la dernière sauvegarde d'images"
                    log "💡 Utilisez --force pour forcer la sauvegarde"
                else
                    CREATE_IMAGE_BACKUP=true
                fi
            else
                CREATE_IMAGE_BACKUP=true
            fi
        else
            CREATE_IMAGE_BACKUP=true
        fi
        
        if [ "$CREATE_IMAGE_BACKUP" = true ]; then
            log "💾 Création de la sauvegarde d'images: ${IMAGES_BACKUP_NAME}"
            
            if [ "$VERBOSE" = true ]; then
                docker exec "${CONTAINER_NAME}" tar -czf - \
                    --exclude="*.tmp" \
                    --exclude="*.temp" \
                    --exclude="*.cache" \
                    -C "/app/public/files" . > "${IMAGES_BACKUP_FILE}"
            else
                docker exec "${CONTAINER_NAME}" tar -czf - \
                    --exclude="*.tmp" \
                    --exclude="*.temp" \
                    --exclude="*.cache" \
                    -C "/app/public/files" . > "${IMAGES_BACKUP_FILE}" 2>/dev/null
            fi
            
            if [ -f "${IMAGES_BACKUP_FILE}" ]; then
                IMAGES_SIZE=$(du -h "${IMAGES_BACKUP_FILE}" | cut -f1)
                log "✅ Sauvegarde images créée: ${IMAGES_BACKUP_NAME}.tar.gz (${IMAGES_SIZE})"
                
                # Nettoyer les anciennes sauvegardes images
                log "🧹 Nettoyage des anciennes sauvegardes images..."
                BACKUP_COUNT=$(ls -1 "${IMAGES_BACKUP_DIR}"/images_backup_*.tar.gz 2>/dev/null | wc -l)
                if [ "$BACKUP_COUNT" -gt "$MAX_IMAGE_BACKUPS" ]; then
                    TO_DELETE=$((BACKUP_COUNT - MAX_IMAGE_BACKUPS))
                    log "🗑️  Suppression de ${TO_DELETE} ancienne(s) sauvegarde(s) images..."
                    ls -1t "${IMAGES_BACKUP_DIR}"/images_backup_*.tar.gz | tail -n "$TO_DELETE" | xargs rm -f
                    log "✅ Nettoyage images terminé"
                else
                    log "ℹ️  Pas de nettoyage images nécessaire ($BACKUP_COUNT sauvegardes)"
                fi
            else
                log "❌ Erreur lors de la création de la sauvegarde d'images"
            fi
        fi
    fi
fi

# Afficher les statistiques finales
log "📊 Statistiques finales:"
TOTAL_DB_SIZE=$(du -sh "${DB_BACKUP_DIR}" 2>/dev/null | cut -f1 || echo "0")
TOTAL_IMAGES_SIZE=$(du -sh "${IMAGES_BACKUP_DIR}" 2>/dev/null | cut -f1 || echo "0")

log "💾 Taille totale des sauvegardes DB: ${TOTAL_DB_SIZE}"
log "🖼️  Taille totale des sauvegardes images: ${TOTAL_IMAGES_SIZE}"

log "✅ Sauvegarde terminée avec succès!" 