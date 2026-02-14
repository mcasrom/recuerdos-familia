#!/bin/bash
################################################################################
# Script de Gestión de Fotografías - Álbum Familiar
# Funcionalidades: subir, eliminar, editar, optimizar imágenes
# VERSIÓN SIN AUTENTICACIÓN
################################################################################

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuración
ALBUM_DIR="$HOME/album_familiar"
CONTENT_DIR="$ALBUM_DIR/content/fotos"
IMAGES_DIR="$ALBUM_DIR/static/images"
LOG_FILE="$ALBUM_DIR/logs/management.log"
OPT_LOG="$ALBUM_DIR/logs/optimization.log"

# Límites de optimización
MAX_WIDTH=1920
MAX_HEIGHT=1080
JPEG_QUALITY=85
THUMB_WIDTH=400
THUMB_HEIGHT=300
WARNING_SIZE_MB=10
MAX_SIZE_MB=25

################################################################################
# Funciones auxiliares
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

print_header() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              ÁLBUM FAMILIAR - GESTIÓN DE FOTOS                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Verificar dependencias
check_dependencies() {
    local deps=("convert" "exiftool" "jpegoptim" "identify")
    local missing=()
    
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Dependencias faltantes: ${missing[*]}"
        print_info "Ejecute: ./setup.sh"
        exit 1
    fi
}

# Crear directorios
create_directories() {
    mkdir -p "$ALBUM_DIR/logs"
    mkdir -p "$CONTENT_DIR"
    mkdir -p "$IMAGES_DIR"
}

# Extraer fecha EXIF
extract_exif_date() {
    local file="$1"
    local date=$(exiftool -d "%Y-%m-%d %H:%M:%S" -DateTimeOriginal -s3 "$file" 2>/dev/null)
    
    if [ -z "$date" ]; then
        date=$(exiftool -d "%Y-%m-%d %H:%M:%S" -CreateDate -s3 "$file" 2>/dev/null)
    fi
    
    if [ -z "$date" ]; then
        date=$(date -r "$file" "+%Y-%m-%d %H:%M:%S")
    fi
    
    echo "$date"
}

# Obtener metadata EXIF
get_exif_metadata() {
    local file="$1"
    
    local camera=$(exiftool -Model -s3 "$file" 2>/dev/null || echo "")
    local focal=$(exiftool -FocalLength -s3 "$file" 2>/dev/null || echo "")
    local aperture=$(exiftool -FNumber -s3 "$file" 2>/dev/null || echo "")
    local iso=$(exiftool -ISO -s3 "$file" 2>/dev/null || echo "")
    
    echo "$camera|$focal|$aperture|$iso"
}

# Optimizar imagen
optimize_image() {
    local input="$1"
    local output_full="$2"
    local output_thumb="$3"
    
    print_info "Optimizando imagen..."
    
    local size_mb=$(du -m "$input" | cut -f1)
    
    if [ "$size_mb" -gt "$WARNING_SIZE_MB" ]; then
        print_warning "Archivo grande: ${size_mb}MB"
        echo -n "¿Continuar? (s/n): "
        read -r response
        [[ ! "$response" =~ ^[Ss]$ ]] && return 1
    fi
    
    [ "$size_mb" -gt "$MAX_SIZE_MB" ] && { print_error "Archivo > ${MAX_SIZE_MB}MB"; return 1; }
    
    convert "$input" -auto-orient "/tmp/temp_oriented.jpg" 2>> "$OPT_LOG"
    convert "/tmp/temp_oriented.jpg" -resize "${MAX_WIDTH}x${MAX_HEIGHT}>" -quality "$JPEG_QUALITY" "$output_full" 2>> "$OPT_LOG"
    jpegoptim --max="$JPEG_QUALITY" --strip-all "$output_full" >> "$OPT_LOG" 2>&1
    convert "$output_full" -resize "${THUMB_WIDTH}x${THUMB_HEIGHT}^" -gravity center -extent "${THUMB_WIDTH}x${THUMB_HEIGHT}" -quality "$JPEG_QUALITY" "$output_thumb" 2>> "$OPT_LOG"
    
    rm -f "/tmp/temp_oriented.jpg"
    
    local orig=$(du -k "$input" | cut -f1)
    local opt=$(du -k "$output_full" | cut -f1)
    local saved=$(( (orig - opt) * 100 / orig ))
    
    print_success "Optimizado: ${orig}KB → ${opt}KB (ahorro: ${saved}%)"
    log "Image optimized: $output_full"
    return 0
}

# Generar nombre único
generate_filename() {
    echo "foto_$(date +%Y%m%d_%H%M%S)_$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 6)"
}

# Crear Markdown
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
    
    print_success "Markdown creado"
    log "Markdown: $output_file"
}

################################################################################
# Función 1: Subir fotografía
################################################################################

upload_photo() {
    print_header
    echo -e "${MAGENTA}═══ SUBIR FOTOGRAFÍA ═══${NC}\n"
    
    echo -n "Ruta de la imagen (o 'q' para salir): "
    read -r photo_path
    
    [[ "$photo_path" == "q" || "$photo_path" == "Q" ]] && return
    
    [ ! -f "$photo_path" ] && { print_error "Archivo no encontrado"; read -p "Enter..."; return; }
    
    # Detectar formato (case-insensitive)
    local extension="${photo_path##*.}"
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
    
    if [[ ! "$extension" =~ ^(jpg|jpeg|png)$ ]]; then
        print_error "Formato no soportado: .$extension"
        print_info "Formatos aceptados: .jpg .JPG .jpeg .JPEG .png .PNG"
        read -p "Enter..."
        return
    fi
    
    # Verificar que sea realmente una imagen
    local mime=$(file --mime-type -b "$photo_path" 2>/dev/null)
    if [[ ! "$mime" =~ ^image/ ]]; then
        print_error "El archivo no es una imagen válida"
        read -p "Enter..."
        return
    fi
    
    print_success "Formato detectado: .$extension → se convertirá a .jpg optimizado"
    
    print_info "Extrayendo EXIF..."
    local exif_date=$(extract_exif_date "$photo_path")
    local metadata=$(get_exif_metadata "$photo_path")
    
    local year=$(echo "$exif_date" | cut -d'-' -f1)
    local month=$(echo "$exif_date" | cut -d'-' -f2)
    local month_num=$(echo "$month" | sed 's/^0*//')
    local months=("" "enero" "febrero" "marzo" "abril" "mayo" "junio" "julio" "agosto" "septiembre" "octubre" "noviembre" "diciembre")
    local month_name="${months[$month_num]}"
    
    print_info "Fecha: $exif_date ($month_name $year)"
    
    echo -n "Título: "
    read -r title
    echo -n "Descripción: "
    read -r description
    
    local filename=$(generate_filename)
    local month_dir="$IMAGES_DIR/$year/$month"
    local content_month_dir="$CONTENT_DIR/$year/$month-$month_name"
    
    mkdir -p "$month_dir" "$content_month_dir"
    
    local output_full="$month_dir/${filename}_full.jpg"
    local output_thumb="$month_dir/${filename}_thumb.jpg"
    
    optimize_image "$photo_path" "$output_full" "$output_thumb" || { read -p "Enter..."; return; }
    
    local web_image="/images/$year/$month/${filename}_full.jpg"
    local web_thumb="/images/$year/$month/${filename}_thumb.jpg"
    local markdown="$content_month_dir/${filename}.md"
    
    create_photo_markdown "$title" "$description" "$exif_date" "$web_image" "$web_thumb" "$metadata" "$markdown"
    
    print_success "✓ Foto subida: $web_image"
    log "Uploaded: $title"
    
    read -p "Enter..."
}

################################################################################
# Función 2: Eliminar fotografía
################################################################################

delete_photo() {
    print_header
    echo -e "${MAGENTA}═══ ELIMINAR FOTOGRAFÍA ═══${NC}\n"
    
    local counter=1
    declare -A photo_map
    
    while IFS= read -r -d '' md_file; do
        local title=$(grep "^title:" "$md_file" | cut -d'"' -f2)
        local date=$(grep "^date:" "$md_file" | cut -d' ' -f2)
        echo "  [$counter] $title ($date)"
        photo_map[$counter]="$md_file"
        ((counter++))
    done < <(find "$CONTENT_DIR" -name "*.md" -type f -print0 2>/dev/null | sort -z)
    
    [ ${#photo_map[@]} -eq 0 ] && { print_warning "Sin fotos"; read -p "Enter..."; return; }
    
    echo -n "\nNúmero a eliminar (q=cancelar): "
    read -r selection
    
    [[ "$selection" == "q" || "$selection" == "Q" ]] && return
    [ -z "${photo_map[$selection]}" ] && { print_error "Inválido"; read -p "Enter..."; return; }
    
    local md_file="${photo_map[$selection]}"
    local title=$(grep "^title:" "$md_file" | cut -d'"' -f2)
    
    echo -e "\n${RED}ELIMINAR:${NC} $title"
    echo -n "Confirmar (escriba ELIMINAR): "
    read -r conf
    
    [ "$conf" != "ELIMINAR" ] && { print_info "Cancelado"; read -p "Enter..."; return; }
    
    local image=$(grep "^image:" "$md_file" | cut -d'"' -f2)
    local thumb=$(grep "^thumbnail:" "$md_file" | cut -d'"' -f2)
    
    rm -f "$md_file" "$ALBUM_DIR/static${image}" "$ALBUM_DIR/static${thumb}"
    
    print_success "✓ Eliminado"
    log "Deleted: $title"
    read -p "Enter..."
}

################################################################################
# Función 3: Editar fotografía
################################################################################

edit_photo() {
    print_header
    echo -e "${MAGENTA}═══ EDITAR FOTOGRAFÍA ═══${NC}\n"
    
    local counter=1
    declare -A photo_map
    
    while IFS= read -r -d '' md_file; do
        local title=$(grep "^title:" "$md_file" | cut -d'"' -f2)
        echo "  [$counter] $title"
        photo_map[$counter]="$md_file"
        ((counter++))
    done < <(find "$CONTENT_DIR" -name "*.md" -type f -print0 2>/dev/null | sort -z)
    
    [ ${#photo_map[@]} -eq 0 ] && { print_warning "Sin fotos"; read -p "Enter..."; return; }
    
    echo -n "\nNúmero a editar (q=cancelar): "
    read -r selection
    
    [[ "$selection" == "q" ]] && return
    [ -z "${photo_map[$selection]}" ] && { print_error "Inválido"; read -p "Enter..."; return; }
    
    local md_file="${photo_map[$selection]}"
    local cur_title=$(grep "^title:" "$md_file" | cut -d'"' -f2)
    local cur_desc=$(grep "^description:" "$md_file" | cut -d'"' -f2)
    
    echo -e "\n${CYAN}Actual:${NC}"
    echo "  Título: $cur_title"
    echo "  Descripción: $cur_desc"
    
    echo -n "\nNuevo título (Enter=mantener): "
    read -r new_title
    [ -z "$new_title" ] && new_title="$cur_title"
    
    echo -n "Nueva descripción (Enter=mantener): "
    read -r new_desc
    [ -z "$new_desc" ] && new_desc="$cur_desc"
    
    sed -i "s/^title:.*/title: \"$new_title\"/" "$md_file"
    sed -i "s/^description:.*/description: \"$new_desc\"/" "$md_file"
    
    print_success "✓ Editado"
    log "Edited: $new_title"
    read -p "Enter..."
}

################################################################################
# Función 4: Estadísticas
################################################################################

show_statistics() {
    print_header
    echo -e "${MAGENTA}═══ ESTADÍSTICAS ═══${NC}\n"
    
    local total=$(find "$CONTENT_DIR" -name "*.md" -type f 2>/dev/null | wc -l)
    print_info "Total: $total fotos"
    
    echo -e "\n${CYAN}Por año:${NC}"
    for year_dir in "$CONTENT_DIR"/*; do
        [ -d "$year_dir" ] || continue
        local year=$(basename "$year_dir")
        local count=$(find "$year_dir" -name "*.md" -type f 2>/dev/null | wc -l)
        [ $count -gt 0 ] && echo "  $year: $count"
    done
    
    [ -d "$IMAGES_DIR" ] && echo -e "\n${CYAN}Espacio:${NC} $(du -sh "$IMAGES_DIR" | cut -f1)"
    
    read -p "\nEnter..."
}

################################################################################
# Función 5: Generar sitio
################################################################################

generate_site() {
    print_header
    echo -e "${MAGENTA}═══ GENERAR SITIO ═══${NC}\n"
    
    cd "$ALBUM_DIR"
    hugo --cleanDestinationDir && print_success "✓ Generado en: public/" || print_error "Error"
    log "Site generated"
    read -p "\nEnter..."
}

################################################################################
# Menú principal
################################################################################

show_menu() {
    print_header
    echo -e "${BLUE}Opciones:${NC}\n"
    echo "  1. 📸 Subir foto"
    echo "  2. 🗑️  Eliminar foto"
    echo "  3. ✏️  Editar foto"
    echo "  4. 📊 Estadísticas"
    echo "  5. 🔨 Generar sitio"
    echo "  6. 🚪 Salir"
    echo
}

main() {
    check_dependencies
    create_directories
    
    while true; do
        show_menu
        echo -n "Opción: "
        read -r option
        
        case $option in
            1) upload_photo ;;
            2) delete_photo ;;
            3) edit_photo ;;
            4) show_statistics ;;
            5) generate_site ;;
            6) print_info "¡Adiós!"; exit 0 ;;
            *) print_error "Inválido"; read -p "Enter..." ;;
        esac
    done
}

main
