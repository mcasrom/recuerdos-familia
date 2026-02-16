// AUTH DESACTIVADO 100% - CONTENIDO SIEMPRE VISIBLE
document.addEventListener("DOMContentLoaded", () => {
  const authScreen = document.getElementById("auth-screen");
  if (authScreen) authScreen.remove();
  const protectedContent = document.getElementById("protected-content");
  if (protectedContent) protectedContent.style.display = "block";
  console.log("Auth desactivado completamente - galería visible");
});
