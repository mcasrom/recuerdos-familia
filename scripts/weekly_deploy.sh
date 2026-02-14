#!/bin/bash
################################################################################
# Deployment Automático Semanal - Álbum Familiar
# Se ejecuta cada domingo a las 3:00 AM
################################################################################

LOG_FILE="$HOME/album_familiar/logs/weekly_deploy.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Iniciando deployment automático semanal" >> "$LOG_FILE"

cd $HOME/album_familiar

# 1. Backup primero
echo "[$DATE] Ejecutando backup..." >> "$LOG_FILE"
./scripts/backup_album.sh >> "$LOG_FILE" 2>&1

# 2. Verificar si hay cambios
if git status --porcelain | grep -q .; then
    echo "[$DATE] Cambios detectados, agregando archivos..." >> "$LOG_FILE"
    
    # Agregar todos los cambios
    git add .
    
    # Commit con fecha
    git commit -m "Auto-deploy: $(date '+%Y-%m-%d')" >> "$LOG_FILE" 2>&1
    
    # Push a GitHub
    echo "[$DATE] Haciendo push a GitHub..." >> "$LOG_FILE"
    git push >> "$LOG_FILE" 2>&1
    
    echo "[$DATE] Deployment completado exitosamente" >> "$LOG_FILE"
else
    echo "[$DATE] No hay cambios para desplegar" >> "$LOG_FILE"
fi

echo "[$DATE] Proceso finalizado" >> "$LOG_FILE"
echo "----------------------------------------" >> "$LOG_FILE"
