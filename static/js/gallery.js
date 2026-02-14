/**
 * Funcionalidad de Galería para Álbum Familiar
 * Incluye lightbox, navegación, lazy loading y optimizaciones
 */

(function() {
    'use strict';
    
    // Crear lightbox para vista ampliada
    function createLightbox() {
        const lightbox = document.createElement('div');
        lightbox.id = 'lightbox';
        lightbox.style.cssText = `
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.95);
            z-index: 10000;
            cursor: zoom-out;
        `;
        
        const img = document.createElement('img');
        img.id = 'lightbox-img';
        img.style.cssText = `
            max-width: 90%;
            max-height: 90%;
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            box-shadow: 0 0 50px rgba(255, 255, 255, 0.2);
        `;
        
        const closeBtn = document.createElement('button');
        closeBtn.textContent = '✕';
        closeBtn.style.cssText = `
            position: absolute;
            top: 20px;
            right: 20px;
            background: rgba(255, 255, 255, 0.2);
            border: none;
            color: white;
            font-size: 30px;
            cursor: pointer;
            width: 50px;
            height: 50px;
            border-radius: 50%;
            transition: background 0.3s;
        `;
        
        closeBtn.addEventListener('mouseenter', () => {
            closeBtn.style.background = 'rgba(255, 255, 255, 0.3)';
        });
        
        closeBtn.addEventListener('mouseleave', () => {
            closeBtn.style.background = 'rgba(255, 255, 255, 0.2)';
        });
        
        const prevBtn = document.createElement('button');
        prevBtn.textContent = '❮';
        prevBtn.id = 'lightbox-prev';
        prevBtn.style.cssText = `
            position: absolute;
            left: 20px;
            top: 50%;
            transform: translateY(-50%);
            background: rgba(255, 255, 255, 0.2);
            border: none;
            color: white;
            font-size: 40px;
            cursor: pointer;
            width: 60px;
            height: 60px;
            border-radius: 50%;
            transition: background 0.3s;
        `;
        
        const nextBtn = document.createElement('button');
        nextBtn.textContent = '❯';
        nextBtn.id = 'lightbox-next';
        nextBtn.style.cssText = prevBtn.style.cssText.replace('left: 20px', 'right: 20px');
        
        const caption = document.createElement('div');
        caption.id = 'lightbox-caption';
        caption.style.cssText = `
            position: absolute;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
            color: white;
            background: rgba(0, 0, 0, 0.7);
            padding: 15px 30px;
            border-radius: 5px;
            max-width: 80%;
            text-align: center;
        `;
        
        lightbox.appendChild(img);
        lightbox.appendChild(closeBtn);
        lightbox.appendChild(prevBtn);
        lightbox.appendChild(nextBtn);
        lightbox.appendChild(caption);
        document.body.appendChild(lightbox);
        
        // Eventos
        closeBtn.addEventListener('click', closeLightbox);
        lightbox.addEventListener('click', (e) => {
            if (e.target === lightbox) closeLightbox();
        });
        
        // Navegación con teclado
        document.addEventListener('keydown', (e) => {
            if (lightbox.style.display === 'block') {
                if (e.key === 'Escape') closeLightbox();
                if (e.key === 'ArrowLeft') navigateLightbox('prev');
                if (e.key === 'ArrowRight') navigateLightbox('next');
            }
        });
        
        prevBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            navigateLightbox('prev');
        });
        
        nextBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            navigateLightbox('next');
        });
    }
    
    let currentPhotoIndex = 0;
    let visiblePhotos = [];
    
    // Abrir lightbox
    function openLightbox(imgSrc, title, index) {
        const lightbox = document.getElementById('lightbox');
        const img = document.getElementById('lightbox-img');
        const caption = document.getElementById('lightbox-caption');
        
        img.src = imgSrc;
        caption.textContent = title;
        lightbox.style.display = 'block';
        document.body.style.overflow = 'hidden';
        
        currentPhotoIndex = index;
        updateNavigationButtons();
    }
    
    // Cerrar lightbox
    function closeLightbox() {
        const lightbox = document.getElementById('lightbox');
        lightbox.style.display = 'none';
        document.body.style.overflow = '';
    }
    
    // Navegar en lightbox
    function navigateLightbox(direction) {
        if (direction === 'prev' && currentPhotoIndex > 0) {
            currentPhotoIndex--;
        } else if (direction === 'next' && currentPhotoIndex < visiblePhotos.length - 1) {
            currentPhotoIndex++;
        } else {
            return;
        }
        
        const photo = visiblePhotos[currentPhotoIndex];
        const img = photo.querySelector('img');
        const title = photo.querySelector('h3').textContent;
        const fullSrc = img.src.replace('_thumb.jpg', '_full.jpg');
        
        document.getElementById('lightbox-img').src = fullSrc;
        document.getElementById('lightbox-caption').textContent = title;
        
        updateNavigationButtons();
    }
    
    // Actualizar botones de navegación
    function updateNavigationButtons() {
        const prevBtn = document.getElementById('lightbox-prev');
        const nextBtn = document.getElementById('lightbox-next');
        
        prevBtn.style.display = currentPhotoIndex > 0 ? 'block' : 'none';
        nextBtn.style.display = currentPhotoIndex < visiblePhotos.length - 1 ? 'block' : 'none';
    }
    
    // Configurar galería
    function setupGallery() {
        visiblePhotos = Array.from(document.querySelectorAll('.photo-card'))
            .filter(card => card.style.display !== 'none');
        
        visiblePhotos.forEach((card, index) => {
            const link = card.querySelector('a');
            const img = card.querySelector('img');
            const title = card.querySelector('h3');
            
            if (link && img && title) {
                // Agregar evento de click para lightbox
                link.addEventListener('click', (e) => {
                    // Solo abrir lightbox si no es un link a página de detalle
                    if (!link.href.includes('/fotos/')) {
                        e.preventDefault();
                        const fullSrc = img.src.replace('_thumb.jpg', '_full.jpg');
                        openLightbox(fullSrc, title.textContent, index);
                    }
                });
                
                // Precargar imagen siguiente para navegación rápida
                img.addEventListener('mouseenter', () => {
                    if (index < visiblePhotos.length - 1) {
                        const nextImg = visiblePhotos[index + 1].querySelector('img');
                        if (nextImg) {
                            const preload = new Image();
                            preload.src = nextImg.src.replace('_thumb.jpg', '_full.jpg');
                        }
                    }
                });
            }
        });
    }
    
    // Lazy loading de imágenes
    function setupLazyLoading() {
        const images = document.querySelectorAll('img[loading="lazy"]');
        
        if ('IntersectionObserver' in window) {
            const imageObserver = new IntersectionObserver((entries, observer) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        const img = entry.target;
                        img.src = img.dataset.src || img.src;
                        img.classList.add('loaded');
                        observer.unobserve(img);
                    }
                });
            }, {
                rootMargin: '50px'
            });
            
            images.forEach(img => imageObserver.observe(img));
        }
    }
    
    // Animaciones de entrada
    function setupAnimations() {
        const photoCards = document.querySelectorAll('.photo-card');
        
        if ('IntersectionObserver' in window) {
            const cardObserver = new IntersectionObserver((entries) => {
                entries.forEach((entry, index) => {
                    if (entry.isIntersecting) {
                        setTimeout(() => {
                            entry.target.style.opacity = '1';
                            entry.target.style.transform = 'translateY(0)';
                        }, index * 50);
                    }
                });
            }, {
                threshold: 0.1
            });
            
            photoCards.forEach(card => {
                card.style.opacity = '0';
                card.style.transform = 'translateY(20px)';
                card.style.transition = 'opacity 0.5s, transform 0.5s';
                cardObserver.observe(card);
            });
        }
    }
    
    // Vista de cuadrícula vs lista
    function setupViewToggle() {
        // Crear botón de toggle si no existe
        const filterPanel = document.querySelector('.filter-panel');
        if (filterPanel && !document.getElementById('view-toggle')) {
            const toggleContainer = document.createElement('div');
            toggleContainer.style.cssText = 'margin-top: 15px; display: flex; gap: 10px;';
            
            const gridBtn = document.createElement('button');
            gridBtn.textContent = '⊞ Cuadrícula';
            gridBtn.className = 'view-toggle active';
            
            const listBtn = document.createElement('button');
            listBtn.textContent = '☰ Lista';
            listBtn.className = 'view-toggle';
            
            toggleContainer.appendChild(gridBtn);
            toggleContainer.appendChild(listBtn);
            filterPanel.appendChild(toggleContainer);
            
            // Estilos
            const style = document.createElement('style');
            style.textContent = `
                .view-toggle {
                    padding: 8px 15px;
                    background: white;
                    border: 2px solid #bdc3c7;
                    border-radius: 5px;
                    cursor: pointer;
                    transition: all 0.3s;
                }
                .view-toggle:hover {
                    border-color: #3498db;
                }
                .view-toggle.active {
                    background: #3498db;
                    color: white;
                    border-color: #3498db;
                }
                .photo-grid.list-view {
                    grid-template-columns: 1fr;
                }
                .photo-grid.list-view .photo-card {
                    display: flex;
                    flex-direction: row;
                }
                .photo-grid.list-view .photo-card img {
                    width: 200px;
                    height: 150px;
                    flex-shrink: 0;
                }
            `;
            document.head.appendChild(style);
            
            // Eventos
            gridBtn.addEventListener('click', () => {
                document.querySelector('.photo-grid').classList.remove('list-view');
                gridBtn.classList.add('active');
                listBtn.classList.remove('active');
                localStorage.setItem('album_view', 'grid');
            });
            
            listBtn.addEventListener('click', () => {
                document.querySelector('.photo-grid').classList.add('list-view');
                listBtn.classList.add('active');
                gridBtn.classList.remove('active');
                localStorage.setItem('album_view', 'list');
            });
            
            // Cargar vista guardada
            const savedView = localStorage.getItem('album_view');
            if (savedView === 'list') {
                listBtn.click();
            }
        }
    }
    
    // Estadísticas de carga
    function logPerformance() {
        if (window.performance && console.table) {
            const perfData = performance.getEntriesByType('navigation')[0];
            console.log('📊 Rendimiento de Carga:');
            console.table({
                'DNS Lookup': `${perfData.domainLookupEnd - perfData.domainLookupStart}ms`,
                'TCP Connection': `${perfData.connectEnd - perfData.connectStart}ms`,
                'Request Time': `${perfData.responseStart - perfData.requestStart}ms`,
                'Response Time': `${perfData.responseEnd - perfData.responseStart}ms`,
                'DOM Processing': `${perfData.domComplete - perfData.domLoading}ms`,
                'Total Load Time': `${perfData.loadEventEnd - perfData.fetchStart}ms`
            });
        }
    }
    
    // Inicializar
    function init() {
        createLightbox();
        setupGallery();
        setupLazyLoading();
        setupAnimations();
        setupViewToggle();
        
        // Reconfigurar galería cuando cambie el filtro
        const observer = new MutationObserver(() => {
            setupGallery();
        });
        
        const photoGrid = document.querySelector('.photo-grid');
        if (photoGrid) {
            observer.observe(photoGrid, {
                childList: true,
                subtree: true,
                attributes: true,
                attributeFilter: ['style']
            });
        }
        
        // Log de performance en desarrollo
        if (window.location.hostname === 'localhost') {
            window.addEventListener('load', logPerformance);
        }
    }
    
    // Ejecutar cuando el DOM esté listo
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
    
})();
