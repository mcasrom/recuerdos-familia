# 📸 Álbum Familiar

Sistema completo de álbum fotográfico familiar optimizado para **Odroid CE** con **DietPi**, generador estático **Hugo**, y despliegue automático en **GitHub Pages**.

## 🌟 Características Principales

- 🔐 **Autenticación dual**: Password para visualización y administración
- 📸 **Optimización automática**: Redimensionado y compresión inteligente
- 📅 **Organización temporal**: Por años, meses y fechas
- 🔍 **Filtrado avanzado**: Rango de fechas personalizable
- 🎨 **Interfaz responsive**: Optimizada para todos los dispositivos
- ⚡ **Rendimiento**: Generación estática ultrarrápida
- 🌐 **Hosting gratuito**: GitHub Pages
- 🛡️ **Protección por password**: Acceso restringido al álbum

## 🔑 Contraseñas

### Password de Visualización (Para familia)
```
Recuerdos@FAMILIA#
```

### Password de Administración (Para gestión)
```
recuerditos@familia
```

## 📋 Requisitos del Sistema

### Hardware
- Odroid CE (cualquier modelo)
- Mínimo 512MB RAM (recomendado 1GB)
- Mínimo 8GB almacenamiento (recomendado 32GB)

### Software
- DietPi (Debian 11/12 based)
- Conexión a Internet
- Cuenta de GitHub

## 🚀 Instalación Rápida

### Paso 1: Clonar o copiar archivos

```bash
cd ~
# Si tienes los archivos localmente
cp -r /ruta/a/album_familiar ~/album_familiar

# O si están en un repositorio
git clone https://github.com/TU_USUARIO/album-familiar.git ~/album_familiar
```

### Paso 2: Dar permisos de ejecución

```bash
cd ~/album_familiar
chmod +x scripts/*.sh
chmod +x setup.sh
```

### Paso 3: Ejecutar instalación

```bash
./setup.sh
```

Este script instalará automáticamente:
- Hugo Extended
- ImageMagick
- ExifTool
- jpegoptim
- Python Pillow
- Todas las dependencias necesarias

### Paso 4: Copiar archivos JavaScript

```bash
cp auth.js static/js/
cp gallery.js static/js/
cp date-filter.js static/js/
```

### Paso 5: Configurar GitHub

1. Crear repositorio en GitHub llamado `album-familiar`
2. Configurar GitHub Pages:
   - Settings → Pages
   - Source: GitHub Actions
3. Crear workflow:

```bash
mkdir -p .github/workflows
cp hugo.yml .github/workflows/
```

4. Inicializar Git y conectar:

```bash
git init
git add .
git commit -m "Initial commit: Album Familiar"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/album-familiar.git
git push -u origin main
```

5. Editar `config.toml` con tu URL:

```toml
baseURL = "https://TU_USUARIO.github.io/album-familiar/"
```

## 📖 Uso del Sistema

### Gestión de Fotografías

Ejecutar el script de gestión:

```bash
cd ~/album_familiar
./scripts/manage_photos.sh
```

El sistema solicitará el password de administración: `recuerditos@familia`

#### Opciones disponibles:

1. **📸 Subir fotografía**
   - Seleccionar archivo
   - Ingresa título y descripción
   - Optimización automática
   - Extracción de EXIF
   - Organización por fecha

2. **🗑️ Eliminar fotografía**
   - Lista de fotos existentes
   - Confirmación de seguridad
   - Eliminación completa

3. **✏️ Editar fotografía**
   - Modificar título
   - Modificar descripción
   - Actualización instantánea

4. **📊 Ver estadísticas**
   - Total de fotos
   - Fotos por año
   - Espacio utilizado
   - Última foto subida

5. **🔨 Generar sitio Hugo**
   - Build del sitio estático
   - Preparación para despliegue

### Desplegar a GitHub Pages

```bash
cd ~/album_familiar
./scripts/deploy.sh
```

Este script:
1. Verifica cambios
2. Genera sitio con Hugo
3. Commit automático
4. Push a GitHub
5. GitHub Actions despliega automáticamente

El sitio estará disponible en: `https://TU_USUARIO.github.io/album-familiar/`

### Acceso al Álbum

1. Navegar a la URL del sitio
2. Ingresar password: `Recuerdos@FAMILIA#`
3. Disfrutar del álbum familiar

#### Funcionalidades para visitantes:

- Ver fotos organizadas por fecha
- Filtrar por rango de fechas
- Ampliar fotos (lightbox)
- Vista de cuadrícula o lista
- Descargar fotos individuales
- Ver información EXIF

## 🎯 Optimización de Imágenes

### Configuración automática:

- **Resolución máxima**: 1920x1080 (Full HD)
- **Thumbnails**: 400x300 píxeles
- **Calidad JPEG**: 85%
- **Rotación automática**: Según EXIF
- **Advertencia**: Archivos > 10MB
- **Límite máximo**: 25MB

### Proceso de optimización:

1. Lee orientación EXIF
2. Rota si es necesario
3. Redimensiona manteniendo aspect ratio
4. Comprime a calidad óptima
5. Genera thumbnail
6. Elimina metadata innecesaria

## 📁 Estructura de Directorios

```
~/album_familiar/
├── archetypes/
│   └── default.md
├── content/
│   └── fotos/
│       ├── 2024/
│       │   ├── 01-enero/
│       │   ├── 02-febrero/
│       │   └── ...
│       ├── 2025/
│       └── 2026/
├── layouts/
│   ├── _default/
│   │   ├── baseof.html
│   │   ├── list.html
│   │   └── single.html
│   └── partials/
│       ├── header.html
│       ├── footer.html
│       └── auth.html
├── static/
│   ├── css/
│   │   └── style.css
│   ├── js/
│   │   ├── auth.js
│   │   ├── gallery.js
│   │   └── date-filter.js
│   └── images/
│       ├── 2024/
│       ├── 2025/
│       └── 2026/
├── scripts/
│   ├── manage_photos.sh
│   ├── deploy.sh
│   └── backup_album.sh
├── .github/
│   └── workflows/
│       └── hugo.yml
├── config.toml
├── setup.sh
└── README.md
```

## 🔧 Configuración Avanzada

### Cambiar passwords

Editar `static/js/auth.js`:

```javascript
const PASSWORDS = {
    view: 'NUEVO_HASH_SHA256_VIEW',
    admin: 'NUEVO_HASH_SHA256_ADMIN'
};
```

Generar hash:
```bash
echo -n "TU_PASSWORD" | sha256sum
```

### Ajustar límites de optimización

Editar `scripts/manage_photos.sh`:

```bash
MAX_WIDTH=1920
MAX_HEIGHT=1080
JPEG_QUALITY=85
THUMB_WIDTH=400
THUMB_HEIGHT=300
WARNING_SIZE_MB=10
MAX_SIZE_MB=25
```

### Personalizar tema

Editar `static/css/style.css` para cambiar:
- Colores
- Fuentes
- Espaciado
- Animaciones

## 🔄 Backup y Restauración

### Crear backup manual

```bash
cd ~/album_familiar
./scripts/backup_album.sh
```

Esto crea: `/mnt/backup/album_YYYYMMDD.tar.gz`

### Programar backups automáticos

```bash
crontab -e
```

Agregar:
```cron
# Backup semanal los domingos a las 3 AM
0 3 * * 0 /home/dietpi/album_familiar/scripts/backup_album.sh
```

### Restaurar backup

```bash
cd /mnt/backup
tar xzf album_YYYYMMDD.tar.gz
rsync -av album_YYYYMMDD/ ~/album_familiar/
cd ~/album_familiar
hugo server  # Verificar
```

## 🐛 Solución de Problemas

### Hugo no genera el sitio

```bash
cd ~/album_familiar
hugo --verbose
hugo --cleanDestinationDir
hugo
```

### Imágenes no se muestran

```bash
cd ~/album_familiar
find static/images -type f -exec chmod 644 {} \;
find static/images -type d -exec chmod 755 {} \;
```

### GitHub Pages no actualiza

1. Verificar en: GitHub → Actions
2. Ver logs del último workflow
3. Forzar rebuild:

```bash
git commit --allow-empty -m "Trigger rebuild"
git push
```

### Password no funciona

Verificar hash en `static/js/auth.js`. Regenerar si es necesario:

```bash
echo -n "Recuerdos@FAMILIA#" | sha256sum
```

## 📊 Monitoreo

### Ver logs

```bash
# Logs de gestión
tail -f ~/album_familiar/logs/management.log

# Logs de optimización
tail -f ~/album_familiar/logs/optimization.log

# Logs de despliegue
tail -f ~/album_familiar/logs/deployment.log
```

### Estadísticas de espacio

```bash
du -sh ~/album_familiar/static/images/*
```

## 🎨 Personalización

### Cambiar título del sitio

Editar `config.toml`:

```toml
title = "Tu Título Personalizado"
```

### Agregar menú personalizado

Editar `config.toml`:

```toml
[[menu.main]]
  name = "Nueva Página"
  url = "/nueva-pagina/"
  weight = 5
```

### Modificar colores del tema

Editar `static/css/style.css`:

```css
:root {
    --primary: #TU_COLOR;
    --secondary: #TU_COLOR;
    --accent: #TU_COLOR;
}
```

## 🤝 Contribuir

Este es un proyecto familiar, pero si encuentras bugs o tienes sugerencias:

1. Crea un issue en GitHub
2. Describe el problema detalladamente
3. Incluye screenshots si es relevante

## 📝 Licencia

MIT License - Uso libre para fines personales y familiares.

## 📞 Soporte

Para problemas técnicos:
- Revisar logs en `~/album_familiar/logs/`
- Consultar documentación en `ALBUM_FAMILIAR_DOCUMENTATION.org`
- Crear issue en GitHub

## 🗺️ Roadmap

### Versión 1.1 (Próxima)
- [ ] Búsqueda por palabras clave
- [ ] Tags personalizados
- [ ] Álbumes temáticos
- [ ] Comentarios en fotos
- [ ] Geolocalización

### Versión 2.0 (Futuro)
- [ ] Reconocimiento facial
- [ ] Detección de duplicados
- [ ] Editor integrado
- [ ] App móvil

## 🙏 Agradecimientos

- **Hugo**: Generador estático ultrarrápido
- **GitHub Pages**: Hosting gratuito
- **ImageMagick**: Procesamiento de imágenes
- **Comunidad DietPi**: Soporte y documentación

---

**¡Disfruta tu Álbum Familiar!** 📸❤️

*Creado con ❤️ para preservar los recuerdos familiares*
