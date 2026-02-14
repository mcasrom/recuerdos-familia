# 🚀 HOWTO - Álbum Familiar
## Guía Rápida de Uso

---

## 📥 Instalación Inicial (Una sola vez)

### 1. Preparar el sistema

```bash
cd ~
# Copiar archivos del proyecto
cp -r /ruta/origen/album_familiar ~/album_familiar
cd ~/album_familiar
chmod +x *.sh scripts/*.sh
```

### 2. Ejecutar instalación

```bash
./setup.sh
```

⏱️ **Tiempo estimado:** 5-10 minutos

### 3. Configurar archivos

```bash
# Copiar JavaScript
cp auth.js static/js/
cp gallery.js static/js/
cp date-filter.js static/js/

# Copiar página principal
cp _index.md content/

# Editar configuración
nano config.toml
# Cambiar: baseURL = "https://TU_USUARIO.github.io/album-familiar/"
```

### 4. Configurar GitHub

**En GitHub.com:**

1. Crear repositorio nuevo: `album-familiar`
2. Settings → Pages → Source: **GitHub Actions**

**En tu Odroid:**

```bash
cd ~/album_familiar
mkdir -p .github/workflows
cp hugo.yml .github/workflows/

git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/album-familiar.git
git push -u origin main
```

✅ **¡Instalación completa!**

---

## 📸 Uso Diario

### Subir fotografías

```bash
cd ~/album_familiar
./scripts/manage_photos.sh
```

1. Ingresar password admin: `recuerditos@familia`
2. Opción `1` - Subir fotografía
3. Ruta de la imagen: `/ruta/a/foto.jpg`
4. Título: `Cumpleaños de María`
5. Descripción: `Celebración del cumpleaños`
6. ✅ ¡Foto optimizada y guardada!

**El sistema automáticamente:**
- ✅ Optimiza la imagen
- ✅ Crea thumbnail
- ✅ Extrae fecha EXIF
- ✅ Organiza por año/mes
- ✅ Genera página web

### Desplegar cambios

```bash
cd ~/album_familiar
./scripts/deploy.sh
```

⏱️ **Tiempo:** 1-3 minutos

🌐 **Tu álbum estará en:** `https://TU_USUARIO.github.io/album-familiar/`

---

## 🔑 Acceso al Álbum

### Para familia (visualización)

1. Ir a: `https://TU_USUARIO.github.io/album-familiar/`
2. Password: `Recuerdos@FAMILIA#`
3. ¡Disfruta el álbum!

### Funciones disponibles:

- 🖼️ Ver fotos en galería
- 🔍 Filtrar por fechas
- 📅 Navegar por años/meses
- 🔎 Ampliar fotos (lightbox)
- ⬇️ Descargar fotos
- 📱 Ver en móvil/tablet

---

## 🗑️ Eliminar fotografías

```bash
./scripts/manage_photos.sh
```

1. Password admin: `recuerditos@familia`
2. Opción `2` - Eliminar fotografía
3. Seleccionar número de foto
4. Confirmar: `ELIMINAR`
5. ✅ Foto eliminada

---

## ✏️ Editar información

```bash
./scripts/manage_photos.sh
```

1. Password admin: `recuerditos@familia`
2. Opción `3` - Editar fotografía
3. Seleccionar foto
4. Nuevo título / descripción
5. ✅ Información actualizada

---

## 📊 Ver estadísticas

```bash
./scripts/manage_photos.sh
```

1. Password admin: `recuerditos@familia`
2. Opción `4` - Ver estadísticas

Muestra:
- Total de fotos
- Fotos por año
- Espacio usado
- Última foto subida

---

## 💾 Backup Manual

```bash
cd ~/album_familiar
./scripts/backup_album.sh
```

Crea: `/mnt/backup/album_familiar_YYYYMMDD_HHMMSS.tar.gz`

### Restaurar backup

```bash
cd /mnt/backup
tar xzf album_familiar_YYYYMMDD_HHMMSS.tar.gz -C /tmp/
rsync -av /tmp/album_familiar_YYYYMMDD_HHMMSS/ ~/album_familiar/
```

---

## 🔄 Backup Automático

Editar crontab:

```bash
crontab -e
```

Agregar línea:

```cron
# Backup semanal domingos 3 AM
0 3 * * 0 /home/dietpi/album_familiar/scripts/backup_album.sh
```

---

## 🐛 Problemas Comunes

### Hugo no funciona

```bash
hugo version
# Si no existe:
./setup.sh  # Reinstalar
```

### Imágenes no se ven

```bash
cd ~/album_familiar
chmod 644 static/images/*/*/*
chmod 755 static/images/*
```

### GitHub Pages no actualiza

```bash
cd ~/album_familiar
git commit --allow-empty -m "Force rebuild"
git push
```

Luego ir a: `https://github.com/TU_USUARIO/album-familiar/actions`

### Password no funciona

Verificar en `static/js/auth.js` que los hashes sean correctos.

Regenerar:
```bash
echo -n "Recuerdos@FAMILIA#" | sha256sum
```

---

## 🎨 Personalización Rápida

### Cambiar título

```bash
nano config.toml
```

Cambiar: `title = "Tu Nuevo Título"`

### Cambiar colores

```bash
nano static/css/style.css
```

Modificar sección `:root`:

```css
:root {
    --primary: #2c3e50;     /* Color principal */
    --secondary: #3498db;   /* Color secundario */
    --accent: #e74c3c;      /* Color de acento */
}
```

### Desplegar cambios

```bash
./scripts/deploy.sh
```

---

## 📋 Checklist Rápido

### Primera vez:
- [ ] Ejecutar `./setup.sh`
- [ ] Copiar archivos JavaScript
- [ ] Configurar `config.toml`
- [ ] Crear repositorio GitHub
- [ ] Configurar GitHub Pages
- [ ] Subir primera foto
- [ ] Desplegar con `./scripts/deploy.sh`
- [ ] Verificar acceso con password

### Uso regular:
- [ ] Subir fotos con `manage_photos.sh`
- [ ] Desplegar con `deploy.sh`
- [ ] Verificar en web

### Mantenimiento:
- [ ] Backup semanal (automático)
- [ ] Revisar espacio disponible
- [ ] Actualizar Hugo (si necesario)

---

## 📞 Comandos de Referencia Rápida

```bash
# Ver sitio localmente (sin desplegar)
cd ~/album_familiar && hugo server -D
# Acceder en: http://localhost:1313

# Gestión de fotos
~/album_familiar/scripts/manage_photos.sh

# Desplegar a GitHub
~/album_familiar/scripts/deploy.sh

# Backup
~/album_familiar/scripts/backup_album.sh

# Ver logs
tail -f ~/album_familiar/logs/management.log

# Ver espacio usado
du -sh ~/album_familiar/static/images/

# Limpiar y regenerar
cd ~/album_familiar
rm -rf public/
hugo
```

---

## ⚡ Tips Rápidos

### Subir múltiples fotos

El script `manage_photos.sh` permite subir fotos una por una. Para múltiples:

```bash
for foto in /ruta/*.jpg; do
    # Ejecutar manage_photos.sh para cada foto
    # (requiere automatización adicional)
done
```

### Optimizar fotos antes de subir

```bash
# Redimensionar antes
mogrify -resize 1920x1080\> -quality 85 *.jpg
```

### Ver sitio sin internet

```bash
cd ~/album_familiar
hugo server -D
# Abrir: http://192.168.1.X:1313
```

### Cambiar password rápidamente

```bash
echo -n "MI_NUEVO_PASSWORD" | sha256sum
# Copiar hash a static/js/auth.js
```

---

## 📚 Recursos Adicionales

- **Documentación completa:** `ALBUM_FAMILIAR_DOCUMENTATION.org`
- **README detallado:** `README.md`
- **Logs del sistema:** `~/album_familiar/logs/`
- **Hugo Docs:** https://gohugo.io/documentation/

---

## 🎯 Workflow Típico

```
1. Tomar fotos en evento familiar
         ↓
2. Transferir a Odroid
         ↓
3. ./scripts/manage_photos.sh → Subir fotos
         ↓
4. ./scripts/deploy.sh → Desplegar
         ↓
5. Compartir URL con familia
         ↓
6. Familia accede con password
         ↓
7. ¡Disfrutar los recuerdos! 📸❤️
```

---

**¡Eso es todo! Tu álbum familiar está listo para usar.** 🎉

*Para dudas específicas, consulta la documentación completa en `ALBUM_FAMILIAR_DOCUMENTATION.org`*
