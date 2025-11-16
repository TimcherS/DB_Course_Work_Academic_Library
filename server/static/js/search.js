document.getElementById('searchInput').addEventListener('input', function (event) {
    const searchTerm = event.target.value.toLowerCase();
    
    // Универсальный селектор для любой таблицы
    const listItems = document.querySelectorAll('tbody tr');

    listItems.forEach(function (item) {
        const cells = item.querySelectorAll('td');
        let found = false;

        // Проверяем все ячейки строки (кроме первой с номером)
        for (let i = 1; i < cells.length; i++) {
            const cellText = cells[i].textContent.toLowerCase();
            if (cellText.includes(searchTerm)) {
                found = true;
                break;
            }
        }

        if (found || searchTerm === '') {
            item.style.display = '';
        } else {
            item.style.display = 'none';
        }
    });
});
