#!/bin/bash

# Script de gestion des sauvegardes Fast Foodie
# Liste, affiche les infos et supprime les sauvegardes (DB + images)

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
DB_BACKUP_DIR="${BACKUP_DIR}"
IMAGES_BACKUP_DIR="${BACKUP_DIR}/images"
ACTION=${1:-"list"}

# Fonction pour afficher l'aide
show_help() {
    echo "🔧 Gestionnaire de sauvegardes Fast Foodie"
    echo ""
    echo "Usage: $0 [action] [options]"
    echo ""
    echo "Actions disponibles:"
    echo "  list                    - Lister toutes les sauvegardes (défaut)"
    echo "  info <file>             - Afficher les informations d'une sauvegarde"
    echo "  delete <file>           - Supprimer une sauvegarde"
    echo "  cleanup                 - Nettoyer les anciennes sauvegardes"
    echo "  stats                   - Afficher les statistiques"
    echo ""
    echo "Options:"
    echo "  -d, --db               - Opérations sur la base de données seulement"
    echo "  -i, --images           - Opérations sur les images seulement"
    echo "  -h, --help             - Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 list                # Lister toutes les sauvegardes"
    echo "  $0 list --db           # Lister seulement les sauvegardes DB"
    echo "  $0 list --images       # Lister seulement les sauvegardes images"
    echo "  $0 info fast_foodie_backup_20241201_020000.sql"
    echo "  $0 delete fast_foodie_backup_20241201_020000.sql"
    echo "  $0 cleanup"
}

# Variables
FILTER_DB=false
FILTER_IMAGES=false

# Traiter les arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--db)
            FILTER_DB=true
            shift
            ;;
        -i|--images)
            FILTER_IMAGES=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        list|info|delete|cleanup|stats)
            ACTION="$1"
            shift
            ;;
        -*)
            echo "❌ Option inconnue: $1"
            show_help
            exit 1
            ;;
        *)
            if [ "$ACTION" = "info" ] || [ "$ACTION" = "delete" ]; then
                FILE="$1"
            else
                echo "❌ Argument inattendu: $1"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Fonction pour lister les sauvegardes
list_backups() {
    echo "📋 Sauvegardes disponibles:"
    echo ""
    
    # Lister les sauvegardes de base de données
    if [ "$FILTER_IMAGES" = false ]; then
        echo "🗄️  Base de données:"
        echo "----------------------------------------"
        
        if [ ! -d "${DB_BACKUP_DIR}" ]; then
            echo "   ❌ Le répertoire de sauvegarde DB n'existe pas: ${DB_BACKUP_DIR}"
        elif [ ! "$(ls -A "${DB_BACKUP_DIR}"/*.sql 2>/dev/null)" ]; then
            echo "   ℹ️  Aucune sauvegarde DB trouvée"
        else
            for file in "${DB_BACKUP_DIR}"/*.sql; do
                if [ -f "$file" ]; then
                    filename=$(basename "$file")
                    size=$(du -h "$file" | cut -f1)
                    date=$(stat -c %y "$file" | cut -d' ' -f1)
                    time=$(stat -c %y "$file" | cut -d' ' -f2 | cut -d'.' -f1)
                    echo "   📄 ${filename}"
                    echo "      📏 Taille: ${size}"
                    echo "      📅 Date: ${date} à ${time}"
                    echo ""
                fi
            done
        fi
    fi
    
    # Lister les sauvegardes d'images
    if [ "$FILTER_DB" = false ]; then
        echo "🖼️  Images:"
        echo "----------------------------------------"
        
        if [ ! -d "${IMAGES_BACKUP_DIR}" ]; then
            echo "   ❌ Le répertoire de sauvegarde images n'existe pas: ${IMAGES_BACKUP_DIR}"
        elif [ ! "$(ls -A "${IMAGES_BACKUP_DIR}"/images_backup_*.tar.gz 2>/dev/null)" ]; then
            echo "   ℹ️  Aucune sauvegarde d'images trouvée"
        else
            for file in "${IMAGES_BACKUP_DIR}"/images_backup_*.tar.gz; do
                if [ -f "$file" ]; then
                    filename=$(basename "$file")
                    size=$(du -h "$file" | cut -f1)
                    date=$(stat -c %y "$file" | cut -d' ' -f1)
                    time=$(stat -c %y "$file" | cut -d' ' -f2 | cut -d'.' -f1)
                    echo "   📦 ${filename}"
                    echo "      📏 Taille: ${size}"
                    echo "      📅 Date: ${date} à ${time}"
                    echo ""
                fi
            done
        fi
    fi
}

# Fonction pour afficher les informations d'une sauvegarde
show_backup_info() {
    local file="$1"
    
    if [ -z "$file" ]; then
        echo "❌ Erreur: Veuillez spécifier un fichier de sauvegarde"
        return 1
    fi
    
    # Déterminer le type de sauvegarde et le chemin
    if [[ "$file" == *.sql ]]; then
        BACKUP_PATH="${DB_BACKUP_DIR}/${file}"
        BACKUP_TYPE="Base de données"
    elif [[ "$file" == *.tar.gz ]]; then
        BACKUP_PATH="${IMAGES_BACKUP_DIR}/${file}"
        BACKUP_TYPE="Images"
    else
        # Essayer les deux chemins
        if [ -f "${DB_BACKUP_DIR}/${file}" ]; then
            BACKUP_PATH="${DB_BACKUP_DIR}/${file}"
            BACKUP_TYPE="Base de données"
        elif [ -f "${IMAGES_BACKUP_DIR}/${file}" ]; then
            BACKUP_PATH="${IMAGES_BACKUP_DIR}/${file}"
            BACKUP_TYPE="Images"
        else
            echo "❌ Erreur: Le fichier '${file}' n'existe pas"
            return 1
        fi
    fi
    
    echo "📄 Informations sur la sauvegarde: ${file}"
    echo "📋 Type: ${BACKUP_TYPE}"
    echo ""
    
    local size=$(du -h "$BACKUP_PATH" | cut -f1)
    local date_created=$(stat -c %y "$BACKUP_PATH" | cut -d' ' -f1,2)
    
    echo "📊 Taille: $size"
    echo "📅 Créé le: $date_created"
    
    if [ "$BACKUP_TYPE" = "Base de données" ]; then
        echo ""
        echo "🗄️  Contenu de la base de données:"
        echo "--------------------------------"
        
        # Compter les lignes
        local total_lines=$(wc -l < "$BACKUP_PATH")
        echo "📝 Nombre total de lignes: $total_lines"
        
        # Chercher les tables
        local tables=$(grep -c "CREATE TABLE" "$BACKUP_PATH" 2>/dev/null || echo "0")
        echo "📋 Nombre de tables: $tables"
        
        # Chercher les insertions
        local inserts=$(grep -c "INSERT INTO" "$BACKUP_PATH" 2>/dev/null || echo "0")
        echo "📥 Nombre d'insertions: $inserts"
    else
        echo ""
        echo "🖼️  Contenu de la sauvegarde d'images:"
        echo "--------------------------------"
        
        # Lister le contenu de l'archive
        local file_count=$(tar -tzf "$BACKUP_PATH" | wc -l)
        echo "📁 Nombre de fichiers: $file_count"
        
        # Afficher les premiers fichiers
        echo "📄 Premiers fichiers:"
        tar -tzf "$BACKUP_PATH" | head -10 | while read -r line; do
            echo "   📄 $line"
        done
        
        if [ "$file_count" -gt 10 ]; then
            echo "   ... et $((file_count - 10)) autres fichiers"
        fi
    fi
}

# Fonction pour supprimer une sauvegarde
delete_backup() {
    local file="$1"
    
    if [ -z "$file" ]; then
        echo "❌ Erreur: Veuillez spécifier un fichier de sauvegarde"
        return 1
    fi
    
    # Déterminer le chemin du fichier
    if [[ "$file" == *.sql ]]; then
        BACKUP_PATH="${DB_BACKUP_DIR}/${file}"
    elif [[ "$file" == *.tar.gz ]]; then
        BACKUP_PATH="${IMAGES_BACKUP_DIR}/${file}"
    else
        # Essayer les deux chemins
        if [ -f "${DB_BACKUP_DIR}/${file}" ]; then
            BACKUP_PATH="${DB_BACKUP_DIR}/${file}"
        elif [ -f "${IMAGES_BACKUP_DIR}/${file}" ]; then
            BACKUP_PATH="${IMAGES_BACKUP_DIR}/${file}"
        else
            echo "❌ Erreur: Le fichier '${file}' n'existe pas"
            return 1
        fi
    fi
    
    echo "⚠️  ATTENTION: Vous êtes sur le point de supprimer la sauvegarde: ${file}"
    read -p "Êtes-vous sûr? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "${BACKUP_PATH}"
        echo "✅ Sauvegarde supprimée: ${file}"
    else
        echo "❌ Suppression annulée"
    fi
}

# Fonction pour nettoyer les anciennes sauvegardes
cleanup_backups() {
    echo "🧹 Nettoyage des anciennes sauvegardes..."
    
    # Nettoyer les sauvegardes DB
    if [ "$FILTER_IMAGES" = false ]; then
        echo "🗄️  Nettoyage des sauvegardes de base de données..."
        if [ -d "${DB_BACKUP_DIR}" ]; then
            cd "${DB_BACKUP_DIR}"
            local max_backups=7
            local backup_count=$(ls -1 *.sql 2>/dev/null | wc -l)
            
            if [ "$backup_count" -gt "$max_backups" ]; then
                local to_delete=$((backup_count - max_backups))
                echo "🗑️  Suppression de $to_delete ancienne(s) sauvegarde(s) DB..."
                
                ls -1t *.sql | tail -n "$to_delete" | while read file; do
                    echo "   Suppression: $file"
                    rm "$file"
                done
                
                echo "✅ Nettoyage DB terminé"
            else
                echo "ℹ️  Pas de nettoyage DB nécessaire ($backup_count sauvegardes)"
            fi
        fi
    fi
    
    # Nettoyer les sauvegardes d'images
    if [ "$FILTER_DB" = false ]; then
        echo "🖼️  Nettoyage des sauvegardes d'images..."
        if [ -d "${IMAGES_BACKUP_DIR}" ]; then
            local max_backups=3
            local backup_count=$(ls -1 "${IMAGES_BACKUP_DIR}"/images_backup_*.tar.gz 2>/dev/null | wc -l)
            
            if [ "$backup_count" -gt "$max_backups" ]; then
                local to_delete=$((backup_count - max_backups))
                echo "🗑️  Suppression de $to_delete ancienne(s) sauvegarde(s) images..."
                
                ls -1t "${IMAGES_BACKUP_DIR}"/images_backup_*.tar.gz | tail -n "$to_delete" | while read file; do
                    echo "   Suppression: $(basename "$file")"
                    rm "$file"
                done
                
                echo "✅ Nettoyage images terminé"
            else
                echo "ℹ️  Pas de nettoyage images nécessaire ($backup_count sauvegardes)"
            fi
        fi
    fi
}

# Fonction pour afficher les statistiques
show_stats() {
    echo "📊 Statistiques des sauvegardes:"
    echo ""
    
    # Statistiques DB
    if [ "$FILTER_IMAGES" = false ]; then
        echo "🗄️  Base de données:"
        if [ -d "${DB_BACKUP_DIR}" ]; then
            local total_files=$(ls -1 "${DB_BACKUP_DIR}"/*.sql 2>/dev/null | wc -l)
            local total_size=$(du -ch "${DB_BACKUP_DIR}"/*.sql 2>/dev/null | tail -1 | cut -f1 || echo "0")
            local oldest_file=$(ls -1t "${DB_BACKUP_DIR}"/*.sql 2>/dev/null | tail -1 2>/dev/null || echo "Aucune")
            local newest_file=$(ls -1t "${DB_BACKUP_DIR}"/*.sql 2>/dev/null | head -1 2>/dev/null || echo "Aucune")
            
            echo "   📁 Nombre total de sauvegardes: $total_files"
            echo "   💾 Taille totale: $total_size"
            echo "   📅 Plus ancienne: $(basename "$oldest_file")"
            echo "   📅 Plus récente: $(basename "$newest_file")"
        else
            echo "   ❌ Répertoire de sauvegarde DB inexistant"
        fi
        echo ""
    fi
    
    # Statistiques images
    if [ "$FILTER_DB" = false ]; then
        echo "🖼️  Images:"
        if [ -d "${IMAGES_BACKUP_DIR}" ]; then
            local total_files=$(ls -1 "${IMAGES_BACKUP_DIR}"/images_backup_*.tar.gz 2>/dev/null | wc -l)
            local total_size=$(du -sh "${IMAGES_BACKUP_DIR}" 2>/dev/null | cut -f1 || echo "0")
            local oldest_file=$(ls -1t "${IMAGES_BACKUP_DIR}"/images_backup_*.tar.gz 2>/dev/null | tail -1 2>/dev/null || echo "Aucune")
            local newest_file=$(ls -1t "${IMAGES_BACKUP_DIR}"/images_backup_*.tar.gz 2>/dev/null | head -1 2>/dev/null || echo "Aucune")
            
            echo "   📁 Nombre total de sauvegardes: $total_files"
            echo "   💾 Taille totale: $total_size"
            echo "   📅 Plus ancienne: $(basename "$oldest_file")"
            echo "   📅 Plus récente: $(basename "$newest_file")"
        else
            echo "   ❌ Répertoire de sauvegarde images inexistant"
        fi
    fi
}

# Gestion des actions
case "$ACTION" in
    "list")
        list_backups
        ;;
    "info")
        show_backup_info "$FILE"
        ;;
    "delete")
        delete_backup "$FILE"
        ;;
    "cleanup")
        cleanup_backups
        ;;
    "stats")
        show_stats
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo "❌ Action non reconnue: $ACTION"
        echo ""
        show_help
        exit 1
        ;;
esac 