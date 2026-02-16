// AUTH COMPLETAMENTE DESACTIVADO - CONTENIDO SIEMPRE VISIBLE
document.addEventListener("DOMContentLoaded", () => {
  document.getElementById("auth-screen")?.remove();
  const content = document.getElementById("protected-content");
  if (content) content.style.display = "block";
  console.log("Auth desactivado - contenido forzado visible");
});
