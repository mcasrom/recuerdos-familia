#!/bin/bash
################################################################################
# Script Simplificado - Procesar Carpeta de Fotos
################################################################################

# Colores
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         PROCESAR CARPETA DE FOTOS                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Pedir carpeta
echo -n "Carpeta con fotos (ej: fotos_para_subir/2026/cumpleaños): "
read folder_path

# Expandir ruta
cd ~/album_familiar
[[ "$folder_path" != /* ]] && folder_path="$PWD/$folder_path"

# Verificar carpeta
if [ ! -d "$folder_path" ]; then
    echo "✗ Carpeta no encontrada: $folder_path"
    exit 1
fi

# Contar fotos
photo_count=$(find "$folder_path" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | wc -l)

if [ $photo_count -eq 0 ]; then
    echo "✗ No hay fotos en esa carpeta"
    exit 1
fi

echo "ℹ Encontradas: $photo_count fotos"

# Pedir título
echo -n "Título base (se numerará): "
read base_title

# Pedir descripción
echo -n "Descripción: "
read base_desc

# Confirmar
echo ""
echo -n "¿Procesar $photo_count fotos? (s/n): "
read confirm

if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    echo "Cancelado"
    exit 0
fi

echo ""
echo "Procesando..."
echo ""

counter=1
success=0

for foto in "$folder_path"/*.{jpg,JPG,jpeg,JPEG,png,PNG}; do
    [ -f "$foto" ] || continue
    
    echo "[$counter/$photo_count] $(basename "$foto")"
    
    # Extraer fecha EXIF
    fecha=$(exiftool -d "%Y-%m-%d %H:%M:%S" -DateTimeOriginal -s3 "$foto" 2>/dev/null)
    [ -z "$fecha" ] && fecha=$(date -r "$foto" "+%Y-%m-%d %H:%M:%S")
    
    year=$(echo "$fecha" | cut -d'-' -f1)
    month=$(echo "$fecha" | cut -d'-' -f2)
    month_num=$(echo "$month" | sed 's/^0*//')
    
    months=("" "enero" "febrero" "marzo" "abril" "mayo" "junio" "julio" "agosto" "septiembre" "octubre" "noviembre" "diciembre")
    month_name="${months[$month_num]}"
    
    filename="foto_$(date +%Y%m%d_%H%M%S)_$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 6)"
    
    mkdir -p "static/images/$year/$month"
    mkdir -p "content/fotos/$year/$month-$month_name"
    
    output_full="static/images/$year/$month/${filename}_full.jpg"
    output_thumb="static/images/$year/$month/${filename}_thumb.jpg"
    
    # Optimizar
    convert "$foto" -auto-orient -resize "1920x1080>" -quality 85 "$output_full" 2>/dev/null
    jpegoptim --max=85 --strip-all "$output_full" >/dev/null 2>&1 || true
    convert "$output_full" -resize "400x300^" -gravity center -extent "400x300" -quality 85 "$output_thumb" 2>/dev/null
    
    # Crear Markdown
    web_image="/images/$year/$month/${filename}_full.jpg"
    web_thumb="/images/$year/$month/${filename}_thumb.jpg"
    markdown="content/fotos/$year/$month-$month_name/${filename}.md"
    
    cat > "$markdown" << MDEOF
---
title: "$base_title $counter"
date: ${fecha}
description: "$base_desc"
image: "$web_image"
thumbnail: "$web_thumb"
year: $year
month: $month_num
draft: false
---

$base_desc
MDEOF
    
    echo "  ✓ Procesada"
    ((counter++))
    ((success++))
    sleep 0.3
done

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  ✓ COMPLETADO                                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Procesadas: $success fotos"
echo ""
echo "Siguiente paso:"
echo "  hugo --cleanDestinationDir"
echo "  ./scripts/deploy.sh"
echo ""
