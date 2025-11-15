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
async function editBook() {
    if (selectedBookId) {
        try {
            // Загружаем данные книги для редактирования
            const response = await fetch(`/api/books/${selectedBookId}`);
            if (!response.ok) {
                throw new Error('Ошибка загрузки данных книги');
            }
            
            const bookData = await response.json();
            
            // Заполняем форму редактирования (можно открыть модальное окно редактирования)
            openEditBookModal(bookData);
            
        } catch (error) {
            console.error('Error loading book data:', error);
            alert('Ошибка при загрузке данных книги');
        }
    }
}

async function deleteBook() {
    if (selectedBookId) {
        if (confirm('Вы уверены, что хотите удалить книгу "' + selectedBookName + '"?')) {
            try {
                const response = await fetch(`/api/books/${selectedBookId}`, {
                    method: 'DELETE',
                    headers: {
                        'Content-Type': 'application/json',
                    }
                });

                if (response.ok) {
                    alert('Книга успешно удалена');
                    // Обновляем страницу
                    window.location.reload();
                } else {
                    const error = await response.json();
                    alert('Ошибка при удалении книги: ' + error.detail);
                }
            } catch (error) {
                console.error('Error:', error);
                alert('Произошла ошибка при удалении книги');
            }
        }
    }
}

function loanBook() {
    if (selectedBookId) {
        alert('Выдача книги: ' + selectedBookName + ' (ID: ' + selectedBookId + ')');
        // Здесь можно добавить логику выдачи книги
    }
}

// Функция для открытия модального окна редактирования
function openEditBookModal(bookData) {
    // Создаем или находим модальное окно редактирования
    let editModal = document.getElementById('editBookModal');
    
    if (!editModal) {
        // Создаем модальное окно, если его нет
        editModal = document.createElement('div');
        editModal.id = 'editBookModal';
        editModal.className = 'fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full hidden z-50';
        editModal.innerHTML = `
            <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
                <div class="mt-3">
                    <h3 class="text-lg font-medium text-gray-900 mb-4">Редактировать книгу</h3>
                    
                    <form id="editBookForm" onsubmit="updateBook(event)">
                        <input type="hidden" id="edit_book_id" name="book_id">
                        <div class="mb-4">
                            <label for="edit_book_name" class="block text-sm font-medium text-gray-700 mb-1">
                                Название книги *
                            </label>
                            <input type="text" id="edit_book_name" name="book_name" required
                                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                        </div>

                        <div class="mb-4">
                            <label for="edit_authors" class="block text-sm font-medium text-gray-700 mb-1">
                                Авторы (через запятую)
                            </label>
                            <input type="text" id="edit_authors" name="authors"
                                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                   placeholder="Иван Иванов, Петр Петров">
                        </div>

                        <div class="mb-4">
                            <label for="edit_publisher" class="block text-sm font-medium text-gray-700 mb-1">
                                Издатель
                            </label>
                            <input type="text" id="edit_publisher" name="publisher"
                                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                        </div>

                        <div class="mb-4">
                            <label for="edit_isbn" class="block text-sm font-medium text-gray-700 mb-1">
                                ISBN
                            </label>
                            <input type="text" id="edit_isbn" name="isbn"
                                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                        </div>

                        <div class="mb-4">
                            <label for="edit_release_date" class="block text-sm font-medium text-gray-700 mb-1">
                                Год выпуска
                            </label>
                            <input type="number" id="edit_release_date" name="release_date" min="1900" max="2030"
                                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                        </div>

                        <div class="mb-4">
                            <label for="edit_theme" class="block text-sm font-medium text-gray-700 mb-1">
                                Тема
                            </label>
                            <input type="text" id="edit_theme" name="theme"
                                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                        </div>

                        <div class="flex items-center justify-end gap-3 mt-6">
                            <button type="button" onclick="closeEditBookModal()" 
                                    class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-200 rounded-md hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-gray-500">
                                Отмена
                            </button>
                            <button type="submit" 
                                    class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500">
                                Сохранить изменения
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        `;
        document.body.appendChild(editModal);
        
        // Добавляем обработчик закрытия по клику вне окна
        editModal.addEventListener('click', function(e) {
            if (e.target === this) {
                closeEditBookModal();
            }
        });
    }
    
    // Заполняем форму данными
    document.getElementById('edit_book_id').value = bookData.id;
    document.getElementById('edit_book_name').value = bookData.name || '';
    document.getElementById('edit_authors').value = bookData.authors || '';
    document.getElementById('edit_publisher').value = bookData.publisher || '';
    document.getElementById('edit_isbn').value = bookData.isbn || '';
    document.getElementById('edit_release_date').value = bookData.release_date || '';
    document.getElementById('edit_theme').value = bookData.theme || '';
    
    // Показываем модальное окно
    editModal.classList.remove('hidden');
}

// Функция для закрытия модального окна редактирования
function closeEditBookModal() {
    const editModal = document.getElementById('editBookModal');
    if (editModal) {
        editModal.classList.add('hidden');
        document.getElementById('editBookForm').reset();
    }
}

// Функция для обновления книги
async function updateBook(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const bookId = formData.get('book_id');
    const bookData = {
        book_name: formData.get('book_name'),
        authors: formData.get('authors'),
        publisher: formData.get('publisher'),
        isbn: formData.get('isbn'),
        release_date: formData.get('release_date'),
        theme: formData.get('theme')
    };

    try {
        const response = await fetch(`/api/books/${bookId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(bookData)
        });

        if (response.ok) {
            closeEditBookModal();
            // Обновляем страницу для отображения изменений
            window.location.reload();
        } else {
            const error = await response.json();
            alert('Ошибка при обновлении книги: ' + error.detail);
        }
    } catch (error) {
        console.error('Error:', error);
        alert('Произошла ошибка при обновлении книги');
    }
}
