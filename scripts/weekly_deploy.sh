#!/bin/bash
################################################################################
# Deployment Automático Semanal - Álbum Familiar
################################################################################

LOG_FILE="$HOME/album_familiar/logs/weekly_deploy.log"
BACKUP_DIR="/mnt/backup"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

echo "[$DATE] Iniciando deployment automático semanal" >> "$LOG_FILE"

cd $HOME/album_familiar || exit 1

# 1. Backup automático (sin confirmación)
echo "[$DATE] Creando backup..." >> "$LOG_FILE"

if [ -d "$BACKUP_DIR" ]; then
    BACKUP_FILE="$BACKUP_DIR/album_familiar_auto_${TIMESTAMP}.tar.gz"
    tar -czf "$BACKUP_FILE" \
        --exclude='public' \
        --exclude='resources' \
        --exclude='.git' \
        --exclude='node_modules' \
        -C $HOME album_familiar/ >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        echo "[$DATE] Backup creado: $BACKUP_FILE" >> "$LOG_FILE"
        
        # Limpiar backups automáticos antiguos (>30 días)
        find "$BACKUP_DIR" -name "album_familiar_auto_*.tar.gz" -type f -mtime +30 -delete
    else
        echo "[$DATE] Error creando backup" >> "$LOG_FILE"
    fi
else
    echo "[$DATE] Directorio de backup no existe, saltando..." >> "$LOG_FILE"
fi

# 2. Verificar si hay cambios
if git status --porcelain | grep -q .; then
    echo "[$DATE] Cambios detectados" >> "$LOG_FILE"
    
    # Regenerar sitio Hugo
    echo "[$DATE] Regenerando sitio..." >> "$LOG_FILE"
    hugo --cleanDestinationDir --baseURL "https://mcasrom.github.io/recuerdos-familia/" >> "$LOG_FILE" 2>&1
    
    # Agregar cambios
    git add . >> "$LOG_FILE" 2>&1
    
    # Commit
    git commit -m "Auto-deploy: $(date '+%Y-%m-%d')" >> "$LOG_FILE" 2>&1
    
    # Push a GitHub
    echo "[$DATE] Pushing to GitHub..." >> "$LOG_FILE"
    if git push >> "$LOG_FILE" 2>&1; then
        echo "[$DATE] ✓ Deployment exitoso" >> "$LOG_FILE"
    else
        echo "[$DATE] ✗ Error en push" >> "$LOG_FILE"
    fi
else
    echo "[$DATE] No hay cambios para desplegar" >> "$LOG_FILE"
fi

echo "[$DATE] Proceso finalizado" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
