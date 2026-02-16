#!/bin/bash
################################################################################
# Script de Procesamiento MASIVO - Álbum Familiar (CORREGIDO)
################################################################################

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuración
ALBUM_DIR="$HOME/album_familiar"
CONTENT_DIR="$ALBUM_DIR/content/fotos"
IMAGES_DIR="$ALBUM_DIR/static/images"
LOG_FILE="$ALBUM_DIR/logs/batch_upload.log"

# Límites
MAX_WIDTH=1920
MAX_HEIGHT=1080
JPEG_QUALITY=85
THUMB_WIDTH=400
THUMB_HEIGHT=300

print_header() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         PROCESAMIENTO MASIVO DE FOTOGRAFÍAS                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

extract_exif_date() {
    local file="$1"
    local date=$(exiftool -d "%Y-%m-%d %H:%M:%S" -DateTimeOriginal -s3 "$file" 2>/dev/null)
    
    if [ -z "$date" ]; then
        date=$(exiftool -d "%Y-%m-%d %H:%M:%S" -CreateDate -s3 "$file" 2>/dev/null)
    fi
    
    if [ -z "$date" ] || [[ "$date" =~ "0000:00:00" ]] || [[ "$date" =~ "    :" ]]; then
        date=$(stat -c "%y" "$file" 2>/dev/null | cut -d'.' -f1)
    fi
    
    if [[ ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
        date="2024-01-01 12:00:00"
    fi
    
    echo "$date"
}

get_exif_metadata() {
    local file="$1"
    local camera=$(exiftool -Model -s3 "$file" 2>/dev/null || echo "")
    local focal=$(exiftool -FocalLength -s3 "$file" 2>/dev/null || echo "")
    local aperture=$(exiftool -FNumber -s3 "$file" 2>/dev/null || echo "")
    local iso=$(exiftool -ISO -s3 "$file" 2>/dev/null || echo "")
    echo "$camera|$focal|$aperture|$iso"
}

optimize_image() {
    local input="$1"
    local output_full="$2"
    local output_thumb="$3"
    
    convert "$input" -auto-orient -resize "${MAX_WIDTH}x${MAX_HEIGHT}>" \
        -quality "$JPEG_QUALITY" "$output_full" 2>/dev/null || return 1
    
    jpegoptim --max="$JPEG_QUALITY" --strip-all "$output_full" >/dev/null 2>&1 || true
    
    convert "$output_full" -resize "${THUMB_WIDTH}x${THUMB_HEIGHT}^" \
        -gravity center -extent "${THUMB_WIDTH}x${THUMB_HEIGHT}" \
        -quality "$JPEG_QUALITY" "$output_thumb" 2>/dev/null || return 1
    
    return 0
}

generate_filename() {
    echo "foto_$(date +%Y%m%d_%H%M%S)_$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 6)"
}

create_photo_markdown() {
    local title="$1"
    local description="$2"
    local date="$3"
    local image_path="$4"
    local thumb_path="$5"
    local metadata="$6"
    local output_file="$7"
    
    IFS='|' read -r camera focal aperture iso <<< "$metadata"
    local year=$(echo "$date" | cut -d'-' -f1)
    local month=$(echo "$date" | cut -d'-' -f2 | sed 's/^0*//')
    
    cat > "$output_file" << EOF
---
title: "$title"
date: ${date}
description: "$description"
image: "$image_path"
thumbnail: "$thumb_path"
camera: "$camera"
focal_length: "$focal"
aperture: "$aperture"
iso: "$iso"
year: $year
month: $month
draft: false
---

$description
EOF
}

process_photo() {
    local photo_path="$1"
    local title="$2"
    local description="$3"
    
    local extension="${photo_path##*.}"
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
    
    if [[ ! "$extension" =~ ^(jpg|jpeg|png)$ ]]; then
        print_warning "Saltando (formato no válido): $(basename "$photo_path")"
        return 1
    fi
    
    local exif_date=$(extract_exif_date "$photo_path")
    local metadata=$(get_exif_metadata "$photo_path")
    
    local year=$(echo "$exif_date" | cut -d'-' -f1)
    local month=$(echo "$exif_date" | cut -d'-' -f2)
    local month_num=$(echo "$month" | sed 's/^0*//')
    local months=("" "enero" "febrero" "marzo" "abril" "mayo" "junio" "julio" "agosto" "septiembre" "octubre" "noviembre" "diciembre")
    local month_name="${months[$month_num]}"
    
    local month_dir="$IMAGES_DIR/$year/$month"
    local content_month_dir="$CONTENT_DIR/$year/$month-$month_name"
    mkdir -p "$month_dir" "$content_month_dir"
    
    local filename=$(generate_filename)
    local output_full="$month_dir/${filename}_full.jpg"
    local output_thumb="$month_dir/${filename}_thumb.jpg"
    
    if ! optimize_image "$photo_path" "$output_full" "$output_thumb"; then
        print_error "Error optimizando: $(basename "$photo_path")"
        return 1
    fi
    
    local web_image="/images/$year/$month/${filename}_full.jpg"
    local web_thumb="/images/$year/$month/${filename}_thumb.jpg"
    local markdown="$content_month_dir/${filename}.md"
    
    create_photo_markdown "$title" "$description" "$exif_date" "$web_image" "$web_thumb" "$metadata" "$markdown"
    
    print_success "$(basename "$photo_path") → $web_image"
    log "Processed: $photo_path"
    
    return 0
}

main() {
    print_header
    
    for cmd in convert exiftool jpegoptim; do
        if ! command -v "$cmd" &>/dev/null; then
            print_error "Falta: $cmd - ejecute ./setup.sh"
            exit 1
        fi
    done
    
    echo -e "${BLUE}Este script procesa TODAS las fotos de una carpeta${NC}\n"
    
    echo -n "Ruta de la carpeta con fotos (ej: fotos_para_subir/2024): "
    read -r folder_path
    
    [[ "$folder_path" != /* ]] && folder_path="$ALBUM_DIR/$folder_path"
    
    if [ ! -d "$folder_path" ]; then
        print_error "Carpeta no encontrada: $folder_path"
        exit 1
    fi
    
    local photo_count=0
    for foto in "$folder_path"/*.jpg "$folder_path"/*.JPG "$folder_path"/*.jpeg "$folder_path"/*.JPEG "$folder_path"/*.png "$folder_path"/*.PNG; do
        [ -f "$foto" ] && ((photo_count++))
    done
    
    if [ $photo_count -eq 0 ]; then
        print_warning "No se encontraron fotos en: $folder_path"
        exit 0
    fi
    
    print_info "Fotos encontradas: $photo_count"
    
    echo -n "Título base para todas (se numerará automáticamente): "
    read -r base_title
    
    echo -n "Descripción común (opcional): "
    read -r base_description
    
    echo -e "\n${YELLOW}¿Procesar todas las fotos?${NC} (s/n): "
    read -r confirm
    
    [[ ! "$confirm" =~ ^[Ss]$ ]] && { print_info "Cancelado"; exit 0; }
    
    echo -e "\n${CYAN}Procesando fotos...${NC}\n"
    
    local counter=1
    local success=0
    local failed=0
    
    for foto in "$folder_path"/*.jpg "$folder_path"/*.JPG "$folder_path"/*.jpeg "$folder_path"/*.JPEG "$folder_path"/*.png "$folder_path"/*.PNG; do
        [ -f "$foto" ] || continue
        
        local title="$base_title $counter"
        local desc="$base_description"
        
        if process_photo "$foto" "$title" "$desc"; then
            ((success++))
        else
            ((failed++))
        fi
        
        ((counter++))
        sleep 0.3
    done
    
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  PROCESAMIENTO COMPLETADO                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${BLUE}Resumen:${NC}"
    echo "  ✓ Exitosas: $success"
    [ $failed -gt 0 ] && echo "  ✗ Fallidas: $failed"
    echo "  📁 Carpeta: $folder_path"
    
    log "Batch processing completed: $success success, $failed failed"
}

main
