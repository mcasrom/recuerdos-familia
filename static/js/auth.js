echo '// Auth desactivado completamente - contenido siempre visible' > auth.js
echo 'document.addEventListener("DOMContentLoaded", () => {' >> auth.js
echo '  const auth = document.getElementById("auth-screen");' >> auth.js
echo '  if (auth) auth.remove();' >> auth.js
echo '  const content = document.getElementById("protected-content");' >> auth.js
echo '  if (content) content.style.display = "block";' >> auth.js
echo '});' >> auth.js
