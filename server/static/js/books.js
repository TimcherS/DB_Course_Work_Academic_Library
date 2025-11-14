let selectedBookId = null;
let selectedBookName = null;

// Функции для модального окна
function openAddBookModal() {
    document.getElementById('addBookModal').classList.remove('hidden');
}

function closeAddBookModal() {
    document.getElementById('addBookModal').classList.add('hidden');
    document.getElementById('addBookForm').reset();
}

// Добавление книги
async function addBook(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const bookData = {
        book_name: formData.get('book_name'),
        authors: formData.get('authors'),
        publisher: formData.get('publisher'),
        isbn: formData.get('isbn'),
        release_date: formData.get('release_date'),
        theme: formData.get('theme'),
        number_of_books: formData.get('number_of_books')
    };

    try {
        const response = await fetch('/api/books', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(bookData)
        });

        if (response.ok) {
            closeAddBookModal();
            // Обновляем страницу для отображения новой книги
            window.location.reload();
        } else {
            const error = await response.json();
            alert('Ошибка при добавлении книги: ' + error.detail);
        }
    } catch (error) {
        console.error('Error:', error);
        alert('Произошла ошибка при добавлении книги');
    }
}

// Показать контекстное меню
document.addEventListener('DOMContentLoaded', function() {
    const contextMenuTriggers = document.querySelectorAll('.context-menu-trigger');
    const contextMenu = document.getElementById('contextMenu');
    
    contextMenuTriggers.forEach(trigger => {
        trigger.addEventListener('contextmenu', function(e) {
            e.preventDefault();
            selectedBookId = this.getAttribute('data-book-id');
            selectedBookName = this.getAttribute('data-book-name');
            
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
    document.getElementById('addBookModal').addEventListener('click', function(e) {
        if (e.target === this) {
            closeAddBookModal();
        }
    });
});

// Функции контекстного меню
function editBook() {
    if (selectedBookId) {
        alert('Редактирование книги: ' + selectedBookName + ' (ID: ' + selectedBookId + ')');
        // Здесь можно добавить логику редактирования
    }
}

function deleteBook() {
    if (selectedBookId) {
        if (confirm('Вы уверены, что хотите удалить книгу "' + selectedBookName + '"?')) {
            alert('Удаление книги: ' + selectedBookName + ' (ID: ' + selectedBookId + ')');
            // Здесь можно добавить логику удаления
        }
    }
}

function loanBook() {
    if (selectedBookId) {
        alert('Выдача книги: ' + selectedBookName + ' (ID: ' + selectedBookId + ')');
        // Здесь можно добавить логику выдачи книги
    }
}
