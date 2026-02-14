#!/bin/bash
################################################################################
# Script de Despliegue - Álbum Familiar a GitHub Pages
# Genera sitio estático y despliega automáticamente
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
LOG_FILE="$ALBUM_DIR/logs/deployment.log"

################################################################################
# Funciones
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

print_header() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         ÁLBUM FAMILIAR - DESPLIEGUE A GITHUB PAGES             ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
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
    echo -e "${YELLOW}[ℹ]${NC} $1"
}

################################################################################
# Proceso de despliegue
################################################################################

main() {
    print_header
    
    cd "$ALBUM_DIR" || exit 1
    
    # Verificar que estamos en un repositorio Git
    if [ ! -d ".git" ]; then
        print_error "Este directorio no es un repositorio Git"
        print_info "Inicialice Git primero: git init"
        exit 1
    fi
    
    # Verificar cambios pendientes
    print_step "Verificando cambios pendientes..."
    if ! git diff-index --quiet HEAD --; then
        print_info "Se detectaron cambios sin commitear"
        
        # Mostrar archivos modificados
        echo -e "\n${YELLOW}Archivos modificados:${NC}"
        git status --short
        
        echo -n -e "\n¿Desea continuar con el despliegue? (s/n): "
        read -r response
        if [[ ! "$response" =~ ^[Ss]$ ]]; then
            print_info "Despliegue cancelado"
            exit 0
        fi
    else
        print_step "No hay cambios pendientes"
    fi
    
    # Limpiar build anterior
    print_step "Limpiando build anterior..."
    rm -rf public/
    
    # Generar sitio estático con Hugo
    print_step "Generando sitio estático con Hugo..."
    if hugo --cleanDestinationDir --minify; then
        print_step "Sitio generado exitosamente"
    else
        print_error "Error al generar el sitio"
        exit 1
    fi
    
    # Verificar que se generó el sitio
    if [ ! -d "public" ] || [ -z "$(ls -A public)" ]; then
        print_error "El directorio public/ está vacío"
        exit 1
    fi
    
    # Estadísticas del sitio generado
    local file_count=$(find public -type f | wc -l)
    local total_size=$(du -sh public | cut -f1)
    print_info "Sitio generado: $file_count archivos, $total_size"
    
    # Git add
    print_step "Agregando archivos al staging..."
    git add .
    
    # Git commit
    print_step "Creando commit..."
    local commit_msg="Deploy: $(date '+%Y-%m-%d %H:%M:%S')"
    
    if git commit -m "$commit_msg"; then
        print_step "Commit creado: $commit_msg"
    else
        print_info "No hay cambios para commitear"
    fi
    
    # Git push
    print_step "Subiendo a GitHub..."
    echo -e "\n${YELLOW}Nota: Puede solicitar credenciales de GitHub${NC}\n"
    
    if git push origin main; then
        print_step "Push exitoso a GitHub"
    else
        print_error "Error al hacer push"
        print_info "Verifique sus credenciales y conexión"
        exit 1
    fi
    
    # Información final
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          ✓ DESPLIEGUE COMPLETADO EXITOSAMENTE                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${BLUE}Información del despliegue:${NC}"
    echo "  • Commit: $commit_msg"
    echo "  • Archivos: $file_count"
    echo "  • Tamaño: $total_size"
    
    # Obtener remote URL
    local remote_url=$(git remote get-url origin)
    local repo_name=$(basename -s .git "$remote_url")
    local username=$(dirname "$remote_url" | xargs basename)
    
    if [[ "$remote_url" == https://* ]]; then
        username=$(echo "$remote_url" | sed -E 's|https://github.com/([^/]+)/.*|\1|')
    fi
    
    echo -e "\n${YELLOW}GitHub Actions iniciará el build automáticamente${NC}"
    echo -e "${YELLOW}Puede tardar 1-3 minutos${NC}"
    
    echo -e "\n${BLUE}URLs útiles:${NC}"
    echo "  • Repositorio: https://github.com/${username}/${repo_name}"
    echo "  • Actions: https://github.com/${username}/${repo_name}/actions"
    echo "  • Sitio web: https://${username}.github.io/${repo_name}/"
    
    log "Deployment completed successfully"
}

# Ejecutar
main
