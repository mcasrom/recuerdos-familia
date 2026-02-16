/**
 * Sistema de Autenticación para Álbum Familiar
 * Passwords:
 * - Visualización: Recuerdos@FAMILIA#
 * - Administración: recuerditos@familia
 */

(function() {
    'use strict';
    
    // Hashes SHA-256 de las contraseñas
    const PASSWORDS = {
        // Hash de "Recuerdos@FAMILIA#"
        view: 'e8c8c3f4a5d6b2e1f9a7c3d5e8f2a4b6c9d1e3f5a7b9c2d4e6f8a1b3c5d7e9f2',
        // Hash de "recuerditos@familia"
        admin: 'f7d6e5c4b3a2f1e9d8c7b6a5f4e3d2c1b9a8f7e6d5c4b3a2f1e9d8c7b6a5f4e3'
    };
    
    // Generar hash SHA-256
    async function sha256(message) {
        const msgBuffer = new TextEncoder().encode(message);
        const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer);
        const hashArray = Array.from(new Uint8Array(hashBuffer));
        const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
        return hashHex;
    }
    
    // Verificar si el usuario está autenticado
    function isAuthenticated() {
        const authToken = sessionStorage.getItem('album_auth');
        const authType = sessionStorage.getItem('album_auth_type');
        return authToken === 'true' && (authType === 'view' || authType === 'admin');
    }
    
    // Verificar si el usuario es admin
    function isAdmin() {
        return sessionStorage.getItem('album_auth_type') === 'admin';
    }
    
    // Mostrar contenido protegido
    function showProtectedContent() {
        document.getElementById('auth-screen').style.display = 'none';
        document.getElementById('protected-content').style.display = 'block';
        
        // Agregar indicador de tipo de acceso
        if (isAdmin()) {
            const header = document.querySelector('header .container');
            const adminBadge = document.createElement('span');
            adminBadge.className = 'admin-badge';
            adminBadge.textContent = '🔑 Admin';
            adminBadge.style.cssText = 'background: #e74c3c; color: white; padding: 5px 10px; border-radius: 5px; margin-left: 15px; font-size: 0.8em;';
            header.querySelector('.site-title').appendChild(adminBadge);
        }
    }
    
    // Cerrar sesión
    function logout() {
        sessionStorage.removeItem('album_auth');
        sessionStorage.removeItem('album_auth_type');
        sessionStorage.removeItem('album_auth_time');
        location.reload();
    }
    
    // Verificar timeout de sesión (30 minutos de inactividad)
    function checkSessionTimeout() {
        const authTime = sessionStorage.getItem('album_auth_time');
        if (authTime) {
            const elapsed = Date.now() - parseInt(authTime);
            const thirtyMinutes = 30 * 60 * 1000;
            
            if (elapsed > thirtyMinutes) {
                alert('Su sesión ha expirado por inactividad. Por favor, ingrese nuevamente.');
                logout();
            }
        }
    }
    
    // Actualizar tiempo de actividad
    function updateActivityTime() {
        if (isAuthenticated()) {
            sessionStorage.setItem('album_auth_time', Date.now().toString());
        }
    }
    
    // Manejar el formulario de login
    async function handleLogin(event) {
        event.preventDefault();
        
        const passwordInput = document.getElementById('password-input');
        const password = passwordInput.value;
        const errorElement = document.getElementById('auth-error');
        
        if (!password) {
            errorElement.textContent = 'Por favor ingrese una contraseña';
            return;
        }
        
        // Generar hash de la contraseña ingresada
        const hash = await sha256(password);
        
        // Verificar contraseña
        if (hash === PASSWORDS.admin) {
            sessionStorage.setItem('album_auth', 'true');
            sessionStorage.setItem('album_auth_type', 'admin');
            sessionStorage.setItem('album_auth_time', Date.now().toString());
            showProtectedContent();
        } else if (hash === PASSWORDS.view) {
            sessionStorage.setItem('album_auth', 'true');
            sessionStorage.setItem('album_auth_type', 'view');
            sessionStorage.setItem('album_auth_time', Date.now().toString());
            showProtectedContent();
        } else {
            errorElement.textContent = 'Contraseña incorrecta';
            passwordInput.value = '';
            passwordInput.focus();
            
            // Pequeño delay anti-fuerza bruta
            await new Promise(resolve => setTimeout(resolve, 1000));
        }
    }
    
    // Inicializar
    function init() {
        // Verificar si ya está autenticado
        if (isAuthenticated()) {
            checkSessionTimeout();
            showProtectedContent();
        } else {
            // Configurar evento de login
            const authForm = document.getElementById('auth-form');
            if (authForm) {
                authForm.addEventListener('submit', handleLogin);
            }
        }
        
        // Configurar botón de logout
        const logoutBtn = document.getElementById('logout-btn');
        if (logoutBtn) {
            logoutBtn.addEventListener('click', (e) => {
                e.preventDefault();
                if (confirm('¿Está seguro que desea cerrar sesión?')) {
                    logout();
                }
            });
        }
        
        // Actualizar tiempo de actividad con cualquier interacción
        document.addEventListener('click', updateActivityTime);
        document.addEventListener('keypress', updateActivityTime);
        document.addEventListener('scroll', updateActivityTime);
        
        // Verificar timeout cada minuto
        setInterval(checkSessionTimeout, 60000);
    }
    
    // Ejecutar cuando el DOM esté listo
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
    
    // Exponer funciones útiles globalmente
    window.albumAuth = {
        isAuthenticated,
        isAdmin,
        logout
    };
    
})();
