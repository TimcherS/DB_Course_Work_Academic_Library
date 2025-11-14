let selectedReaderId = null;
let selectedReaderName = null;

// Функции для модального окна
function openAddReaderModal() {
    document.getElementById('addReaderModal').classList.remove('hidden');
}

function closeAddReaderModal() {
    document.getElementById('addReaderModal').classList.add('hidden');
    document.getElementById('addReaderForm').reset();
}

// Добавление читателя
async function addReader(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const readerData = {
        fio: formData.get('fio'),
        dolzhnost: formData.get('dolzhnost'),
        uchenaya_stepen: formData.get('uchenaya_stepen')
    };

    try {
        const response = await fetch('/api/readers', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(readerData)
        });

        if (response.ok) {
            closeAddReaderModal();
            // Обновляем страницу для отображения нового читателя
            window.location.reload();
        } else {
            const error = await response.json();
            alert('Ошибка при добавлении читателя: ' + error.detail);
        }
    } catch (error) {
        console.error('Error:', error);
        alert('Произошла ошибка при добавлении читателя');
    }
}

// Показать контекстное меню
document.addEventListener('DOMContentLoaded', function() {
    const contextMenuTriggers = document.querySelectorAll('.context-menu-trigger');
    const contextMenu = document.getElementById('contextMenu');
    
    contextMenuTriggers.forEach(trigger => {
        trigger.addEventListener('contextmenu', function(e) {
            e.preventDefault();
            selectedReaderId = this.getAttribute('data-reader-id');
            selectedReaderName = this.getAttribute('data-reader-name');
            
            // Позиционирование меню
            contextMenu.style.display = 'block';
            contextMenu.style.left = e.pageX + 'px';
            contextMenu.style.top = e.pageY + 'px';
        });
    });
    
    // Скрыть меню при клике вне его
    document.addEventListener('click', function() {
        contextMenu.style.display = 'none';
    });
    
    // Предотвратить скрытие при клике внутри меню
    contextMenu.addEventListener('click', function(e) {
        e.stopPropagation();
    });

    // Закрытие модального окна при клике вне его
    document.getElementById('addReaderModal').addEventListener('click', function(e) {
        if (e.target === this) {
            closeAddReaderModal();
        }
    });
});

// Функции контекстного меню
function editReader() {
    if (selectedReaderId) {
        alert('Редактирование читателя: ' + selectedReaderName + ' (ID: ' + selectedReaderId + ')');
        // Здесь можно добавить логику редактирования
    }
}

function deleteReader() {
    if (selectedReaderId) {
        if (confirm('Вы уверены, что хотите удалить читателя "' + selectedReaderName + '"?')) {
            alert('Удаление читателя: ' + selectedReaderName + ' (ID: ' + selectedReaderId + ')');
            // Здесь можно добавить логику удаления
        }
    }
}

function viewReaderLoans() {
    if (selectedReaderId) {
        alert('Просмотр займов читателя: ' + selectedReaderName + ' (ID: ' + selectedReaderId + ')');
        // Здесь можно добавить логику просмотра займов
    }
}
