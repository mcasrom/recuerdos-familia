╔═══════════════════════════════════════════════════════════════╗
║         CARPETA PARA FOTOS - INSTRUCCIONES                    ║
╚═══════════════════════════════════════════════════════════════╝

📸 ¿QUÉ ES ESTA CARPETA?
═══════════════════════════════════════════════════════════════

Esta es tu carpeta de STAGING para fotos antes de procesarlas
y subirlas al álbum familiar.

📂 ESTRUCTURA:

  fotos_para_subir/
  ├── 2024/     ← Pon aquí las fotos del 2024
  ├── 2025/     ← Pon aquí las fotos del 2025
  └── 2026/     ← Pon aquí las fotos del 2026


═══════════════════════════════════════════════════════════════
🚀 CÓMO USAR
═══════════════════════════════════════════════════════════════

1️⃣  COPIAR TUS FOTOS AQUÍ

   Ejemplo organizado por evento:
   
   fotos_para_subir/2024/
   ├── cumpleaños_maria/
   │   ├── foto1.jpg
   │   ├── foto2.jpg
   │   └── foto3.jpg
   ├── vacaciones_playa/
   │   ├── playa1.jpg
   │   └── playa2.jpg
   └── navidad/
       └── navidad.jpg

2️⃣  EJECUTAR EL SCRIPT

   cd ~/album_familiar
   ./scripts/manage_photos.sh

3️⃣  SELECCIONAR OPCIÓN 1: Subir fotografía

4️⃣  INDICAR LA RUTA

   Ejemplo:
   Ruta: ~/album_familiar/fotos_para_subir/2024/cumpleaños_maria/foto1.jpg
   
   O más corto:
   Ruta: fotos_para_subir/2024/cumpleaños_maria/foto1.jpg

5️⃣  EL SCRIPT HACE TODO AUTOMÁTICAMENTE:
   ✓ Lee la fecha de la foto (EXIF)
   ✓ Optimiza el tamaño
   ✓ Crea thumbnail
   ✓ Organiza por año/mes
   ✓ Crea página web para la foto


═══════════════════════════════════════════════════════════════
📥 MÉTODOS DE TRANSFERENCIA
═══════════════════════════════════════════════════════════════

🔹 Desde Windows/Mac/Linux por red (SCP):
   scp mis_fotos/*.jpg dietpi@IP_ODROID:~/album_familiar/fotos_para_subir/2024/

🔹 Con USB directo en Odroid:
   cp /media/usb/*.jpg ~/album_familiar/fotos_para_subir/2024/

🔹 Por FileZilla/WinSCP:
   Conectar a: dietpi@IP_ODROID
   Navegar a: /home/dietpi/album_familiar/fotos_para_subir/
   Arrastrar archivos

🔹 Por carpeta compartida Samba:
   Ver GUIA_STORAGE_FOTOS.txt para configurar


═══════════════════════════════════════════════════════════════
⚠️  IMPORTANTE
═══════════════════════════════════════════════════════════════

✅ Las fotos originales NO se borran automáticamente
   (tú decides si las mantienes o borras después)

✅ Formatos soportados: JPG, JPEG, PNG

✅ Tamaño recomendado: menos de 10MB por foto

✅ El script lee la fecha EXIF automáticamente

✅ Puedes organizar por subcarpetas (eventos, fechas, etc.)


═══════════════════════════════════════════════════════════════
🧹 LIMPIEZA (OPCIONAL)
═══════════════════════════════════════════════════════════════

Después de procesar tus fotos, puedes borrar las originales:

# Borrar todas las fotos de 2024
rm -rf fotos_para_subir/2024/*

# O borrar evento específico
rm -rf fotos_para_subir/2024/cumpleaños_maria/

# O mantenerlas como backup (recomendado)
mv fotos_para_subir/2024/cumpleaños_maria/ fotos_backup/


═══════════════════════════════════════════════════════════════
💡 TIPS
═══════════════════════════════════════════════════════════════

🔸 Organiza por eventos ANTES de procesar:
   2024/cumpleaños/
   2024/vacaciones/
   2024/navidad/

🔸 Renombra fotos descriptivamente:
   cumpleaños_01.jpg
   cumpleaños_02.jpg
   
   En lugar de:
   IMG_001.jpg
   IMG_002.jpg

🔸 Puedes procesar una foto a la vez o preparar todas
   y procesarlas en lote

🔸 El script te pedirá título y descripción para cada foto


═══════════════════════════════════════════════════════════════
📞 AYUDA
═══════════════════════════════════════════════════════════════

Para más detalles, consulta:
• GUIA_STORAGE_FOTOS.txt (guía completa)
• README.md (manual del proyecto)
• HOWTO.md (referencia rápida)

═══════════════════════════════════════════════════════════════

¡Listo para empezar a subir tus fotos! 📸
