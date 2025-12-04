// filters.js - фильтрация и сортировка книг

document.addEventListener('DOMContentLoaded', function() {
    // Валидация полей ввода года
    const minYearInput = document.getElementById('minYearInput');
    const maxYearInput = document.getElementById('maxYearInput');
    
    // Функция для синхронизации полей ввода
    function syncYearInputs() {
        const minYear = parseInt(minYearInput.value) || 1900;
        const maxYear = parseInt(maxYearInput.value) || 2030;
        
        // Гарантируем, что минимальный год не больше максимального
        if (minYear > maxYear) {
            minYearInput.value = maxYear;
        }
        
        // Гарантируем, что максимальный год не меньше минимального
        if (maxYear < minYear) {
            maxYearInput.value = minYear;
        }
        
        // Гарантируем, что значения в пределах допустимого диапазона
        if (minYear < 1900) minYearInput.value = 1900;
        if (minYear > 2030) minYearInput.value = 2030;
        if (maxYear < 1900) maxYearInput.value = 1900;
        if (maxYear > 2030) maxYearInput.value = 2030;
    }
    
    if (minYearInput) {
        minYearInput.addEventListener('change', syncYearInputs);
        minYearInput.addEventListener('blur', syncYearInputs);
    }
    
    if (maxYearInput) {
        maxYearInput.addEventListener('change', syncYearInputs);
        maxYearInput.addEventListener('blur', syncYearInputs);
    }

    // Применение фильтров
    const applyFiltersBtn = document.getElementById('applyFilters');
    if (applyFiltersBtn) {
        applyFiltersBtn.addEventListener('click', applyFilters);
    }

    // Сброс фильтров
    const resetFiltersBtn = document.getElementById('resetFilters');
    if (resetFiltersBtn) {
        resetFiltersBtn.addEventListener('click', resetFilters);
    }
});

function applyFilters() {
    const bookRows = document.querySelectorAll('.book-row');
    
    // Получаем значения диапазона годов
    const minYear = parseInt(document.getElementById('minYearInput').value) || 1900;
    const maxYear = parseInt(document.getElementById('maxYearInput').value) || 2030;
    
    // Получаем выбранный тип сортировки
    const sortType = document.querySelector('input[name="yearSort"]:checked').value;
    
    // Получаем выбранные темы
    const selectedThemes = Array.from(document.querySelectorAll('.theme-checkbox:checked'))
        .map(checkbox => checkbox.value);
    
    // Получаем выбранные статусы
    const selectedStatuses = Array.from(document.querySelectorAll('.status-checkbox:checked'))
        .map(checkbox => checkbox.value);

    let visibleRows = [];

    bookRows.forEach(row => {
        const rowYear = parseInt(row.getAttribute('data-release-year')) || 0;
        const rowTheme = row.getAttribute('data-theme');
        const rowStatus = row.getAttribute('data-status');

        // Проверяем фильтры
        const yearMatch = rowYear >= minYear && rowYear <= maxYear;
        const themeMatch = selectedThemes.length === 0 || selectedThemes.includes(rowTheme);
        const statusMatch = selectedStatuses.length === 0 || selectedStatuses.includes(rowStatus);

        if (yearMatch && themeMatch && statusMatch) {
            row.style.display = '';
            visibleRows.push(row);
        } else {
            row.style.display = 'none';
        }
    });

    // Сортировка по году в зависимости от выбранного типа
    if (sortType !== 'none') {
        sortBooksByYear(visibleRows, sortType);
    }
    
    // Обновляем номера строк
    updateRowNumbers(visibleRows);
}

function sortBooksByYear(rows, sortType) {
    const tbody = document.getElementById('booksTableBody');
    const sortedRows = Array.from(rows).sort((a, b) => {
        const yearA = parseInt(a.getAttribute('data-release-year')) || 0;
        const yearB = parseInt(b.getAttribute('data-release-year')) || 0;
        
        if (sortType === 'asc') {
            return yearA - yearB; // Сначала старые
        } else if (sortType === 'desc') {
            return yearB - yearA; // Сначала новые
        }
        return 0;
    });

    // Перемещаем строки в отсортированном порядке
    sortedRows.forEach(row => {
        tbody.appendChild(row);
    });
}

function updateRowNumbers(visibleRows) {
    visibleRows.forEach((row, index) => {
        const numberCell = row.querySelector('td:first-child');
        if (numberCell) {
            numberCell.textContent = index + 1;
        }
    });
}

function resetFilters() {
    // Сбрасываем поля ввода годов
    document.getElementById('minYearInput').value = 1900;
    document.getElementById('maxYearInput').value = 2030;
    
    // Сбрасываем радиокнопки сортировки
    document.getElementById('sortNone').checked = true;
    
    // Сбрасываем все чекбоксы тем
    document.querySelectorAll('.theme-checkbox').forEach(checkbox => {
        checkbox.checked = false;
    });
    
    // Сбрасываем все чекбоксы статусов к состоянию по умолчанию
    document.querySelectorAll('.status-checkbox').forEach(checkbox => {
        checkbox.checked = true;
    });
    
    // Показываем все строки и сбрасываем нумерацию
    const bookRows = document.querySelectorAll('.book-row');
    bookRows.forEach((row, index) => {
        row.style.display = '';
        const numberCell = row.querySelector('td:first-child');
        if (numberCell) {
            numberCell.textContent = index + 1;
        }
    });
}
