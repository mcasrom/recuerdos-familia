#!/bin/bash
################################################################################
# Script de Backup - Álbum Familiar
# Crea backup completo del álbum con compresión
################################################################################

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuración
ALBUM_DIR="$HOME/album_familiar"
BACKUP_BASE_DIR="/mnt/backup"
DATE_STAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="album_familiar_${DATE_STAMP}"
BACKUP_DIR="${BACKUP_BASE_DIR}/${BACKUP_NAME}"
BACKUP_ARCHIVE="${BACKUP_BASE_DIR}/${BACKUP_NAME}.tar.gz"
LOG_FILE="$ALBUM_DIR/logs/backup.log"

# Retención (días)
RETENTION_DAYS=30

################################################################################
# Funciones
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

print_step() {
    echo -e "${GREEN}[✓]${NC} $1"
    log "$1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
    log "ERROR: $1"
}

print_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              ÁLBUM FAMILIAR - BACKUP AUTOMÁTICO                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

################################################################################
# Verificaciones previas
################################################################################

check_requirements() {
    # Verificar directorio fuente
    if [ ! -d "$ALBUM_DIR" ]; then
        print_error "Directorio del álbum no encontrado: $ALBUM_DIR"
        exit 1
    fi
    
    # Crear directorio de backup si no existe
    if [ ! -d "$BACKUP_BASE_DIR" ]; then
        print_info "Creando directorio de backup: $BACKUP_BASE_DIR"
        sudo mkdir -p "$BACKUP_BASE_DIR"
        sudo chown $USER:$USER "$BACKUP_BASE_DIR"
    fi
    
    # Verificar espacio disponible
    local required_space=$(du -sm "$ALBUM_DIR" | cut -f1)
    local available_space=$(df -m "$BACKUP_BASE_DIR" | tail -1 | awk '{print $4}')
    
    if [ "$available_space" -lt "$required_space" ]; then
        print_error "Espacio insuficiente en $BACKUP_BASE_DIR"
        print_info "Requerido: ${required_space}MB, Disponible: ${available_space}MB"
        exit 1
    fi
}

################################################################################
# Proceso de backup
################################################################################

create_backup() {
    print_header
    
    log "Starting backup process"
    print_step "Iniciando backup del álbum..."
    
    # Crear directorio temporal de backup
    print_step "Creando directorio temporal..."
    mkdir -p "$BACKUP_DIR"
    
    # Copiar archivos con rsync
    print_step "Copiando archivos..."
    rsync -av --progress \
        --exclude='public/' \
        --exclude='resources/' \
        --exclude='.git/' \
        --exclude='*.log' \
        --exclude='node_modules/' \
        "$ALBUM_DIR/" "$BACKUP_DIR/" 2>&1 | tee -a "$LOG_FILE"
    
    # Crear lista de archivos
    print_step "Creando inventario..."
    find "$BACKUP_DIR" -type f > "${BACKUP_DIR}/file_list.txt"
    
    # Crear archivo de información
    cat > "${BACKUP_DIR}/backup_info.txt" << EOF
Álbum Familiar - Información de Backup
========================================
Fecha: $(date '+%Y-%m-%d %H:%M:%S')
Hostname: $(hostname)
Usuario: $USER
Directorio origen: $ALBUM_DIR
Directorio backup: $BACKUP_DIR

Estadísticas:
-------------
Total archivos: $(find "$BACKUP_DIR" -type f | wc -l)
Total directorios: $(find "$BACKUP_DIR" -type d | wc -l)
Tamaño total: $(du -sh "$BACKUP_DIR" | cut -f1)

Contenido por tipo:
------------------
Fotografías (.jpg): $(find "$BACKUP_DIR" -name "*.jpg" | wc -l)
Markdown (.md): $(find "$BACKUP_DIR" -name "*.md" | wc -l)
Configuración: $(find "$BACKUP_DIR" -name "*.toml" -o -name "*.yml" | wc -l)
Scripts: $(find "$BACKUP_DIR" -name "*.sh" | wc -l)
EOF
    
    print_step "Información de backup creada"
    
    # Comprimir
    print_step "Comprimiendo backup..."
    cd "$BACKUP_BASE_DIR"
    tar czf "$BACKUP_ARCHIVE" "$BACKUP_NAME" 2>&1 | tee -a "$LOG_FILE"
    
    # Verificar integridad
    print_step "Verificando integridad..."
    if tar tzf "$BACKUP_ARCHIVE" > /dev/null 2>&1; then
        print_step "Archivo comprimido verificado correctamente"
    else
        print_error "Error en la verificación del archivo"
        exit 1
    fi
    
    # Eliminar directorio temporal
    print_step "Limpiando archivos temporales..."
    rm -rf "$BACKUP_DIR"
    
    # Calcular checksums
    print_step "Calculando checksums..."
    md5sum "$BACKUP_ARCHIVE" > "${BACKUP_ARCHIVE}.md5"
    sha256sum "$BACKUP_ARCHIVE" > "${BACKUP_ARCHIVE}.sha256"
}

################################################################################
# Limpieza de backups antiguos
################################################################################

cleanup_old_backups() {
    print_step "Limpiando backups antiguos (>${RETENTION_DAYS} días)..."
    
    local deleted_count=0
    
    find "$BACKUP_BASE_DIR" -name "album_familiar_*.tar.gz" -mtime +${RETENTION_DAYS} | while read -r old_backup; do
        print_info "Eliminando: $(basename "$old_backup")"
        rm -f "$old_backup"
        rm -f "${old_backup}.md5"
        rm -f "${old_backup}.sha256"
        ((deleted_count++))
    done
    
    if [ "$deleted_count" -gt 0 ]; then
        print_step "Eliminados $deleted_count backup(s) antiguo(s)"
    else
        print_info "No hay backups antiguos para eliminar"
    fi
}

################################################################################
# Estadísticas finales
################################################################################

show_statistics() {
    local archive_size=$(du -h "$BACKUP_ARCHIVE" | cut -f1)
    local file_count=$(tar tzf "$BACKUP_ARCHIVE" | wc -l)
    
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║             ✓ BACKUP COMPLETADO EXITOSAMENTE                   ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${BLUE}Información del Backup:${NC}"
    echo "  • Archivo: $(basename "$BACKUP_ARCHIVE")"
    echo "  • Tamaño: $archive_size"
    echo "  • Archivos: $file_count"
    echo "  • Ubicación: $BACKUP_ARCHIVE"
    
    echo -e "\n${BLUE}Checksums:${NC}"
    echo "  • MD5: $(cut -d' ' -f1 "${BACKUP_ARCHIVE}.md5")"
    echo "  • SHA256: $(cut -d' ' -f1 "${BACKUP_ARCHIVE}.sha256")"
    
    # Listar backups disponibles
    echo -e "\n${BLUE}Backups disponibles:${NC}"
    ls -lh "$BACKUP_BASE_DIR"/album_familiar_*.tar.gz 2>/dev/null | awk '{print "  •", $9, "("$5")"}'
    
    log "Backup completed successfully: $BACKUP_ARCHIVE"
}

################################################################################
# Script principal
################################################################################

main() {
    # Verificar requisitos
    check_requirements
    
    # Crear backup
    create_backup
    
    # Limpiar antiguos
    cleanup_old_backups
    
    # Mostrar estadísticas
    show_statistics
    
    # Sugerencia de restauración
    echo -e "\n${YELLOW}Para restaurar este backup:${NC}"
    echo "  tar xzf $BACKUP_ARCHIVE -C /tmp/"
    echo "  rsync -av /tmp/${BACKUP_NAME}/ ~/album_familiar/"
}

# Ejecutar
main
