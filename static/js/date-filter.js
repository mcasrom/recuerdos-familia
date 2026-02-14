/**
 * Sistema de Filtrado por Fechas para Álbum Familiar
 * Permite filtrar fotos por rango de fechas (año/mes)
 */

(function() {
    'use strict';
    
    let allPhotos = [];
    let currentYears = new Set();
    
    // Extraer años y meses de las fotos
    function extractDateData() {
        const photoCards = document.querySelectorAll('.photo-card');
        allPhotos = Array.from(photoCards);
        
        allPhotos.forEach(card => {
            const year = parseInt(card.dataset.year);
            const month = parseInt(card.dataset.month);
            
            if (!isNaN(year)) {
                currentYears.add(year);
            }
        });
    }
    
    // Poblar selectores de año
    function populateYearSelectors() {
        const yearFrom = document.getElementById('year-from');
        const yearTo = document.getElementById('year-to');
        
        if (!yearFrom || !yearTo) return;
        
        const years = Array.from(currentYears).sort((a, b) => a - b);
        
        // Agregar opción vacía
        yearFrom.innerHTML = '<option value="">Cualquier año</option>';
        yearTo.innerHTML = '<option value="">Cualquier año</option>';
        
        years.forEach(year => {
            const optionFrom = document.createElement('option');
            optionFrom.value = year;
            optionFrom.textContent = year;
            yearFrom.appendChild(optionFrom);
            
            const optionTo = document.createElement('option');
            optionTo.value = year;
            optionTo.textContent = year;
            yearTo.appendChild(optionTo);
        });
        
        // Seleccionar último año por defecto en "hasta"
        if (years.length > 0) {
            yearTo.value = years[years.length - 1];
        }
    }
    
    // Poblar selectores de mes
    function populateMonthSelectors() {
        const monthFrom = document.getElementById('month-from');
        const monthTo = document.getElementById('month-to');
        
        if (!monthFrom || !monthTo) return;
        
        const months = [
            'Cualquier mes',
            'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
            'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
        ];
        
        months.forEach((month, index) => {
            const optionFrom = document.createElement('option');
            optionFrom.value = index === 0 ? '' : index;
            optionFrom.textContent = month;
            monthFrom.appendChild(optionFrom);
            
            const optionTo = document.createElement('option');
            optionTo.value = index === 0 ? '' : index;
            optionTo.textContent = month;
            monthTo.appendChild(optionTo);
        });
    }
    
    // Aplicar filtro
    function applyFilter() {
        const yearFrom = document.getElementById('year-from').value;
        const monthFrom = document.getElementById('month-from').value;
        const yearTo = document.getElementById('year-to').value;
        const monthTo = document.getElementById('month-to').value;
        
        let fromDate = null;
        let toDate = null;
        
        // Construir fechas de inicio y fin
        if (yearFrom) {
            const month = monthFrom || 1;
            fromDate = new Date(yearFrom, month - 1, 1);
        }
        
        if (yearTo) {
            const month = monthTo || 12;
            // Último día del mes
            toDate = new Date(yearTo, month, 0, 23, 59, 59);
        }
        
        let visibleCount = 0;
        
        allPhotos.forEach(card => {
            const year = parseInt(card.dataset.year);
            const month = parseInt(card.dataset.month);
            
            if (isNaN(year) || isNaN(month)) {
                card.style.display = 'none';
                return;
            }
            
            const photoDate = new Date(year, month - 1, 15); // Medio del mes
            
            let visible = true;
            
            if (fromDate && photoDate < fromDate) {
                visible = false;
            }
            
            if (toDate && photoDate > toDate) {
                visible = false;
            }
            
            card.style.display = visible ? 'block' : 'none';
            if (visible) visibleCount++;
        });
        
        // Mostrar mensaje si no hay resultados
        showResultsMessage(visibleCount);
    }
    
    // Mostrar mensaje de resultados
    function showResultsMessage(count) {
        let messageDiv = document.getElementById('filter-results-message');
        
        if (!messageDiv) {
            messageDiv = document.createElement('div');
            messageDiv.id = 'filter-results-message';
            messageDiv.style.cssText = `
                background: #3498db;
                color: white;
                padding: 15px;
                border-radius: 5px;
                margin: 20px 0;
                text-align: center;
                font-weight: bold;
            `;
            
            const filterPanel = document.querySelector('.filter-panel');
            if (filterPanel && filterPanel.nextSibling) {
                filterPanel.parentNode.insertBefore(messageDiv, filterPanel.nextSibling);
            }
        }
        
        if (count === 0) {
            messageDiv.textContent = '❌ No se encontraron fotos en el rango seleccionado';
            messageDiv.style.background = '#e74c3c';
        } else if (count === allPhotos.length) {
            messageDiv.textContent = `📸 Mostrando todas las fotos (${count})`;
            messageDiv.style.background = '#2ecc71';
        } else {
            messageDiv.textContent = `📸 Mostrando ${count} de ${allPhotos.length} fotos`;
            messageDiv.style.background = '#3498db';
        }
        
        messageDiv.style.display = 'block';
    }
    
    // Limpiar filtro
    function clearFilter() {
        document.getElementById('year-from').value = '';
        document.getElementById('month-from').value = '';
        document.getElementById('year-to').value = '';
        document.getElementById('month-to').value = '';
        
        allPhotos.forEach(card => {
            card.style.display = 'block';
        });
        
        const messageDiv = document.getElementById('filter-results-message');
        if (messageDiv) {
            messageDiv.style.display = 'none';
        }
    }
    
    // Guardar filtro en localStorage
    function saveFilter() {
        const filter = {
            yearFrom: document.getElementById('year-from').value,
            monthFrom: document.getElementById('month-from').value,
            yearTo: document.getElementById('year-to').value,
            monthTo: document.getElementById('month-to').value
        };
        localStorage.setItem('album_filter', JSON.stringify(filter));
    }
    
    // Cargar filtro guardado
    function loadFilter() {
        const savedFilter = localStorage.getItem('album_filter');
        if (savedFilter) {
            try {
                const filter = JSON.parse(savedFilter);
                
                if (filter.yearFrom) document.getElementById('year-from').value = filter.yearFrom;
                if (filter.monthFrom) document.getElementById('month-from').value = filter.monthFrom;
                if (filter.yearTo) document.getElementById('year-to').value = filter.yearTo;
                if (filter.monthTo) document.getElementById('month-to').value = filter.monthTo;
                
                // Aplicar filtro guardado
                setTimeout(applyFilter, 100);
            } catch (e) {
                console.error('Error cargando filtro:', e);
            }
        }
    }
    
    // Inicializar
    function init() {
        // Solo ejecutar en páginas con filtro
        const filterPanel = document.querySelector('.filter-panel');
        if (!filterPanel) return;
        
        extractDateData();
        populateYearSelectors();
        populateMonthSelectors();
        
        // Configurar eventos
        const applyBtn = document.getElementById('apply-filter');
        const clearBtn = document.getElementById('clear-filter');
        
        if (applyBtn) {
            applyBtn.addEventListener('click', () => {
                applyFilter();
                saveFilter();
            });
        }
        
        if (clearBtn) {
            clearBtn.addEventListener('click', () => {
                clearFilter();
                localStorage.removeItem('album_filter');
            });
        }
        
        // Aplicar filtro al cambiar selectores
        ['year-from', 'month-from', 'year-to', 'month-to'].forEach(id => {
            const element = document.getElementById(id);
            if (element) {
                element.addEventListener('change', () => {
                    applyFilter();
                    saveFilter();
                });
            }
        });
        
        // Cargar filtro guardado
        loadFilter();
        
        // Estadísticas en consola
        console.log(`📊 Álbum Familiar - Estadísticas:`);
        console.log(`   Total de fotos: ${allPhotos.length}`);
        console.log(`   Años disponibles: ${Array.from(currentYears).sort().join(', ')}`);
    }
    
    // Ejecutar cuando el DOM esté listo
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
    
})();
