#!/bin/bash
################################################################################
# Script de Instalación - Álbum Familiar
# Sistema de álbum fotográfico optimizado para Odroid CE con DietPi
# Autor: Sistema SME Linux/Unix
# Fecha: 2026-02-14
################################################################################

set -e  # Salir si hay error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
INSTALL_DIR="$HOME/album_familiar"
HUGO_VERSION="0.122.0"
LOG_FILE="$INSTALL_DIR/setup.log"

################################################################################
# Funciones auxiliares
################################################################################

print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    ÁLBUM FAMILIAR - SETUP                      ║"
    echo "║           Sistema de Gestión Fotográfica para Odroid          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_step() {
    echo -e "${GREEN}[✓]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        log_step "$1 está instalado"
        return 0
    else
        log_warn "$1 no está instalado"
        return 1
    fi
}

################################################################################
# Inicio del script
################################################################################

print_header

# Crear directorio de instalación
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/logs"
cd "$INSTALL_DIR"

log_step "Iniciando instalación en $INSTALL_DIR"

################################################################################
# 1. Actualizar sistema
################################################################################

echo -e "\n${BLUE}═══ Paso 1: Actualización del Sistema ═══${NC}"
log_step "Actualizando lista de paquetes..."
sudo apt update

################################################################################
# 2. Instalar dependencias básicas
################################################################################

echo -e "\n${BLUE}═══ Paso 2: Instalación de Dependencias ═══${NC}"

DEPS=(
    "git"
    "wget"
    "curl"
    "imagemagick"
    "libimage-exiftool-perl"
    "jpegoptim"
    "optipng"
    "python3"
    "python3-pip"
    "jq"
)

for dep in "${DEPS[@]}"; do
    if dpkg -l | grep -q "^ii  $dep "; then
        log_step "$dep ya está instalado"
    else
        log_step "Instalando $dep..."
        sudo apt install -y "$dep" >> "$LOG_FILE" 2>&1
    fi
done

# Instalar Pillow para Python
log_step "Instalando Python Pillow..."
pip3 install Pillow --break-system-packages >> "$LOG_FILE" 2>&1

################################################################################
# 3. Instalar Hugo Extended
################################################################################

echo -e "\n${BLUE}═══ Paso 3: Instalación de Hugo Extended ═══${NC}"

if check_command hugo; then
    CURRENT_VERSION=$(hugo version | grep -oP 'v\K[0-9.]+' | head -1)
    log_step "Hugo versión $CURRENT_VERSION ya instalado"
else
    log_step "Descargando Hugo Extended $HUGO_VERSION..."
    
    # Detectar arquitectura
    ARCH=$(uname -m)
    if [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        HUGO_ARCH="linux-arm64"
    elif [[ "$ARCH" == "armv7l" ]]; then
        HUGO_ARCH="linux-arm"
    else
        HUGO_ARCH="linux-amd64"
    fi
    
    HUGO_URL="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_${HUGO_ARCH}.deb"
    
    wget -q "$HUGO_URL" -O /tmp/hugo.deb
    sudo dpkg -i /tmp/hugo.deb >> "$LOG_FILE" 2>&1
    rm /tmp/hugo.deb
    
    log_step "Hugo Extended $HUGO_VERSION instalado correctamente"
fi

################################################################################
# 4. Crear estructura de directorios
################################################################################

echo -e "\n${BLUE}═══ Paso 4: Creación de Estructura de Directorios ═══${NC}"

DIRS=(
    "archetypes"
    "content/fotos"
    "content/fotos/2024"
    "content/fotos/2025"
    "content/fotos/2026"
    "layouts/_default"
    "layouts/partials"
    "layouts/fotos"
    "static/css"
    "static/js"
    "static/images"
    "static/admin"
    "scripts"
    "logs"
    "themes"
    "data"
)

for dir in "${DIRS[@]}"; do
    mkdir -p "$INSTALL_DIR/$dir"
    log_step "Creado directorio: $dir"
done

################################################################################
# 5. Crear configuración de Hugo
################################################################################

echo -e "\n${BLUE}═══ Paso 5: Configuración de Hugo ═══${NC}"

cat > "$INSTALL_DIR/config.toml" << 'EOF'
baseURL = "https://TU_USUARIO.github.io/album-familiar/"
languageCode = "es-es"
title = "Álbum Familiar"
theme = ""

[params]
  description = "Álbum fotográfico familiar privado"
  author = "Familia"
  dateFormat = "2 January 2006"
  
  # Configuración de imágenes
  imageMaxWidth = 1920
  imageMaxHeight = 1080
  thumbnailWidth = 400
  thumbnailHeight = 300
  
[permalinks]
  fotos = "/fotos/:year/:month/:filename/"

[taxonomies]
  year = "years"
  month = "months"
  tag = "tags"

[outputs]
  home = ["HTML", "RSS", "JSON"]
  section = ["HTML", "RSS"]

[imaging]
  quality = 85
  resampleFilter = "Lanczos"
  anchor = "Smart"

[minify]
  minifyOutput = true
  
[menu]
  [[menu.main]]
    name = "Inicio"
    url = "/"
    weight = 1
  [[menu.main]]
    name = "Por Año"
    url = "/years/"
    weight = 2
  [[menu.main]]
    name = "Por Mes"
    url = "/months/"
    weight = 3
  [[menu.main]]
    name = "Todas las Fotos"
    url = "/fotos/"
    weight = 4
EOF

log_step "Configuración de Hugo creada"

################################################################################
# 6. Crear archetype por defecto
################################################################################

cat > "$INSTALL_DIR/archetypes/default.md" << 'EOF'
---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
description: ""
image: ""
thumbnail: ""
camera: ""
focal_length: ""
aperture: ""
iso: ""
location: ""
year: {{ dateFormat "2006" .Date }}
month: {{ dateFormat "1" .Date }}
draft: false
---
EOF

log_step "Archetype creado"

################################################################################
# 7. Crear layouts base
################################################################################

echo -e "\n${BLUE}═══ Paso 6: Creación de Templates HTML ═══${NC}"

# baseof.html
cat > "$INSTALL_DIR/layouts/_default/baseof.html" << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ .Title }} - {{ .Site.Title }}</title>
    <meta name="description" content="{{ .Description | default .Site.Params.description }}">
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    {{ partial "auth.html" . }}
    <div id="protected-content" style="display:none;">
        {{ partial "header.html" . }}
        <main>
            {{ block "main" . }}{{ end }}
        </main>
        {{ partial "footer.html" . }}
    </div>
    <script src="/js/auth.js"></script>
    <script src="/js/gallery.js"></script>
    <script src="/js/date-filter.js"></script>
</body>
</html>
EOF

log_step "Layout base creado"

# header.html
cat > "$INSTALL_DIR/layouts/partials/header.html" << 'EOF'
<header>
    <div class="container">
        <h1 class="site-title">📸 {{ .Site.Title }}</h1>
        <nav>
            <ul>
                {{ range .Site.Menus.main }}
                <li><a href="{{ .URL }}">{{ .Name }}</a></li>
                {{ end }}
                <li><a href="#" id="logout-btn">Cerrar Sesión</a></li>
            </ul>
        </nav>
    </div>
</header>
EOF

log_step "Header creado"

# footer.html
cat > "$INSTALL_DIR/layouts/partials/footer.html" << 'EOF'
<footer>
    <div class="container">
        <p>&copy; {{ now.Year }} Álbum Familiar. Todos los derechos reservados.</p>
        <p>Generado con Hugo | Hosting en GitHub Pages</p>
    </div>
</footer>
EOF

log_step "Footer creado"

# auth.html
cat > "$INSTALL_DIR/layouts/partials/auth.html" << 'EOF'
<div id="auth-screen">
    <div class="auth-container">
        <div class="auth-box">
            <h1>🔐 Álbum Familiar</h1>
            <p>Ingrese la contraseña para acceder</p>
            <form id="auth-form">
                <input type="password" id="password-input" placeholder="Contraseña" autofocus>
                <button type="submit">Entrar</button>
            </form>
            <p id="auth-error" class="error"></p>
        </div>
    </div>
</div>
EOF

log_step "Pantalla de autenticación creada"

# list.html
cat > "$INSTALL_DIR/layouts/_default/list.html" << 'EOF'
{{ define "main" }}
<div class="container">
    <h1>{{ .Title }}</h1>
    
    {{ if eq .Section "fotos" }}
    <div class="filter-panel">
        <h3>Filtrar por Fecha</h3>
        <div class="filter-controls">
            <div class="filter-group">
                <label>Desde:</label>
                <select id="year-from"></select>
                <select id="month-from"></select>
            </div>
            <div class="filter-group">
                <label>Hasta:</label>
                <select id="year-to"></select>
                <select id="month-to"></select>
            </div>
            <button id="apply-filter">Filtrar</button>
            <button id="clear-filter">Limpiar</button>
        </div>
    </div>
    {{ end }}
    
    <div class="photo-grid">
        {{ range .Pages }}
        <div class="photo-card" data-year="{{ .Params.year }}" data-month="{{ .Params.month }}">
            <a href="{{ .Permalink }}">
                <img src="{{ .Params.thumbnail }}" alt="{{ .Title }}" loading="lazy">
                <div class="photo-info">
                    <h3>{{ .Title }}</h3>
                    <time>{{ .Date.Format "2 January 2006" }}</time>
                </div>
            </a>
        </div>
        {{ end }}
    </div>
</div>
{{ end }}
EOF

log_step "Template de listado creado"

# single.html
cat > "$INSTALL_DIR/layouts/_default/single.html" << 'EOF'
{{ define "main" }}
<div class="container">
    <article class="photo-detail">
        <h1>{{ .Title }}</h1>
        <div class="photo-meta">
            <time>{{ .Date.Format "2 January 2006" }}</time>
            {{ with .Params.location }}
            <span class="location">📍 {{ . }}</span>
            {{ end }}
        </div>
        
        <div class="photo-container">
            <img src="{{ .Params.image }}" alt="{{ .Title }}" class="photo-full">
        </div>
        
        {{ with .Description }}
        <div class="photo-description">
            {{ . }}
        </div>
        {{ end }}
        
        {{ if .Content }}
        <div class="photo-content">
            {{ .Content }}
        </div>
        {{ end }}
        
        {{ if or .Params.camera .Params.focal_length .Params.aperture .Params.iso }}
        <div class="photo-exif">
            <h3>Información Técnica</h3>
            <dl>
                {{ with .Params.camera }}<dt>Cámara:</dt><dd>{{ . }}</dd>{{ end }}
                {{ with .Params.focal_length }}<dt>Distancia Focal:</dt><dd>{{ . }}</dd>{{ end }}
                {{ with .Params.aperture }}<dt>Apertura:</dt><dd>{{ . }}</dd>{{ end }}
                {{ with .Params.iso }}<dt>ISO:</dt><dd>{{ . }}</dd>{{ end }}
            </dl>
        </div>
        {{ end }}
        
        <div class="photo-actions">
            <a href="{{ .Params.image }}" download class="btn">Descargar</a>
            <a href="/fotos/" class="btn">Volver al Álbum</a>
        </div>
    </article>
</div>
{{ end }}
EOF

log_step "Template de foto individual creado"

################################################################################
# 8. Crear archivos CSS
################################################################################

echo -e "\n${BLUE}═══ Paso 7: Creación de Estilos CSS ═══${NC}"

cat > "$INSTALL_DIR/static/css/style.css" << 'EOF'
/* Reset y Base */
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

:root {
    --primary: #2c3e50;
    --secondary: #3498db;
    --accent: #e74c3c;
    --bg: #ecf0f1;
    --text: #2c3e50;
    --border: #bdc3c7;
    --shadow: rgba(0, 0, 0, 0.1);
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
    line-height: 1.6;
    color: var(--text);
    background: var(--bg);
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 20px;
}

/* Auth Screen */
#auth-screen {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 9999;
}

.auth-container {
    width: 100%;
    max-width: 400px;
    padding: 20px;
}

.auth-box {
    background: white;
    padding: 40px;
    border-radius: 10px;
    box-shadow: 0 10px 40px var(--shadow);
    text-align: center;
}

.auth-box h1 {
    color: var(--primary);
    margin-bottom: 10px;
    font-size: 2em;
}

.auth-box p {
    color: #7f8c8d;
    margin-bottom: 20px;
}

#auth-form input {
    width: 100%;
    padding: 12px;
    border: 2px solid var(--border);
    border-radius: 5px;
    font-size: 16px;
    margin-bottom: 15px;
}

#auth-form button {
    width: 100%;
    padding: 12px;
    background: var(--secondary);
    color: white;
    border: none;
    border-radius: 5px;
    font-size: 16px;
    cursor: pointer;
    transition: background 0.3s;
}

#auth-form button:hover {
    background: #2980b9;
}

.error {
    color: var(--accent);
    margin-top: 10px;
    font-size: 14px;
}

/* Header */
header {
    background: var(--primary);
    color: white;
    padding: 20px 0;
    box-shadow: 0 2px 10px var(--shadow);
}

.site-title {
    font-size: 2em;
    margin-bottom: 10px;
}

nav ul {
    list-style: none;
    display: flex;
    gap: 20px;
    flex-wrap: wrap;
}

nav a {
    color: white;
    text-decoration: none;
    padding: 8px 15px;
    border-radius: 5px;
    transition: background 0.3s;
}

nav a:hover {
    background: rgba(255, 255, 255, 0.1);
}

/* Main Content */
main {
    min-height: calc(100vh - 300px);
    padding: 40px 0;
}

/* Filter Panel */
.filter-panel {
    background: white;
    padding: 20px;
    border-radius: 10px;
    margin-bottom: 30px;
    box-shadow: 0 2px 10px var(--shadow);
}

.filter-controls {
    display: flex;
    gap: 15px;
    flex-wrap: wrap;
    align-items: flex-end;
    margin-top: 15px;
}

.filter-group {
    display: flex;
    flex-direction: column;
    gap: 5px;
}

.filter-group select {
    padding: 8px;
    border: 2px solid var(--border);
    border-radius: 5px;
    font-size: 14px;
}

.filter-controls button {
    padding: 8px 20px;
    background: var(--secondary);
    color: white;
    border: none;
    border-radius: 5px;
    cursor: pointer;
    transition: background 0.3s;
}

.filter-controls button:hover {
    background: #2980b9;
}

#clear-filter {
    background: #95a5a6;
}

#clear-filter:hover {
    background: #7f8c8d;
}

/* Photo Grid */
.photo-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 20px;
}

.photo-card {
    background: white;
    border-radius: 10px;
    overflow: hidden;
    box-shadow: 0 2px 10px var(--shadow);
    transition: transform 0.3s, box-shadow 0.3s;
}

.photo-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 5px 20px var(--shadow);
}

.photo-card img {
    width: 100%;
    height: 250px;
    object-fit: cover;
    display: block;
}

.photo-info {
    padding: 15px;
}

.photo-info h3 {
    color: var(--primary);
    margin-bottom: 5px;
    font-size: 1.1em;
}

.photo-info time {
    color: #7f8c8d;
    font-size: 0.9em;
}

.photo-card a {
    text-decoration: none;
    color: inherit;
}

/* Photo Detail */
.photo-detail {
    background: white;
    padding: 30px;
    border-radius: 10px;
    box-shadow: 0 2px 10px var(--shadow);
}

.photo-meta {
    display: flex;
    gap: 20px;
    margin-bottom: 20px;
    color: #7f8c8d;
    flex-wrap: wrap;
}

.photo-container {
    margin: 30px 0;
    text-align: center;
}

.photo-full {
    max-width: 100%;
    height: auto;
    border-radius: 5px;
    box-shadow: 0 5px 20px var(--shadow);
}

.photo-description,
.photo-content {
    margin: 20px 0;
    line-height: 1.8;
}

.photo-exif {
    background: var(--bg);
    padding: 20px;
    border-radius: 5px;
    margin: 20px 0;
}

.photo-exif h3 {
    margin-bottom: 15px;
    color: var(--primary);
}

.photo-exif dl {
    display: grid;
    grid-template-columns: 150px 1fr;
    gap: 10px;
}

.photo-exif dt {
    font-weight: bold;
}

.photo-actions {
    display: flex;
    gap: 15px;
    margin-top: 30px;
    flex-wrap: wrap;
}

.btn {
    padding: 10px 20px;
    background: var(--secondary);
    color: white;
    text-decoration: none;
    border-radius: 5px;
    transition: background 0.3s;
}

.btn:hover {
    background: #2980b9;
}

/* Footer */
footer {
    background: var(--primary);
    color: white;
    text-align: center;
    padding: 30px 0;
    margin-top: 50px;
}

footer p {
    margin: 5px 0;
}

/* Responsive */
@media (max-width: 768px) {
    .photo-grid {
        grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
        gap: 15px;
    }
    
    nav ul {
        flex-direction: column;
        gap: 10px;
    }
    
    .filter-controls {
        flex-direction: column;
        align-items: stretch;
    }
    
    .photo-exif dl {
        grid-template-columns: 1fr;
    }
}
EOF

log_step "Estilos CSS creados"

################################################################################
# Configuración completada
################################################################################

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          ✓ INSTALACIÓN COMPLETADA EXITOSAMENTE                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${BLUE}Próximos pasos:${NC}"
echo "1. Editar config.toml y cambiar la baseURL"
echo "2. Ejecutar: cd ~/album_familiar"
echo "3. Crear archivos JavaScript de autenticación"
echo "4. Ejecutar scripts de gestión"
echo "5. Configurar GitHub y desplegar"

echo -e "\n${YELLOW}Logs guardados en:${NC} $LOG_FILE"
echo -e "${YELLOW}Directorio de instalación:${NC} $INSTALL_DIR"

log_step "Instalación finalizada correctamente"
