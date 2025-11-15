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
async function editReader() {
    if (selectedReaderId) {
        try {
            // Загружаем данные читателя для редактирования
            const response = await fetch(`/api/readers/${selectedReaderId}`);
            if (!response.ok) {
                throw new Error('Ошибка загрузки данных читателя');
            }
            
            const readerData = await response.json();
            
            // Открываем модальное окно редактирования
            openEditReaderModal(readerData);
            
        } catch (error) {
            console.error('Error loading reader data:', error);
            alert('Ошибка при загрузке данных читателя');
        }
    }
}

async function deleteReader() {
    if (selectedReaderId) {
        if (confirm('Вы уверены, что хотите удалить читателя "' + selectedReaderName + '"?')) {
            try {
                const response = await fetch(`/api/readers/${selectedReaderId}`, {
                    method: 'DELETE',
                    headers: {
                        'Content-Type': 'application/json',
                    }
                });

                if (response.ok) {
                    alert('Читатель успешно удален');
                    // Обновляем страницу
                    window.location.reload();
                } else {
                    const error = await response.json();
                    alert('Ошибка при удалении читателя: ' + error.detail);
                }
            } catch (error) {
                console.error('Error:', error);
                alert('Произошла ошибка при удалении читателя');
            }
        }
    }
}

function viewReaderLoans() {
    if (selectedReaderId) {
        alert('Просмотр займов читателя: ' + selectedReaderName + ' (ID: ' + selectedReaderId + ')');
        // Здесь можно добавить логику просмотра займов
    }
}

// Функция для открытия модального окна редактирования
function openEditReaderModal(readerData) {
    // Создаем или находим модальное окно редактирования
    let editModal = document.getElementById('editReaderModal');
    
    if (!editModal) {
        // Создаем модальное окно, если его нет
        editModal = document.createElement('div');
        editModal.id = 'editReaderModal';
        editModal.className = 'fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full hidden z-50';
        editModal.innerHTML = `
            <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
                <div class="mt-3">
                    <h3 class="text-lg font-medium text-gray-900 mb-4">Редактировать читателя</h3>
                    
                    <form id="editReaderForm" onsubmit="updateReader(event)">
                        <input type="hidden" id="edit_reader_id" name="reader_id">
                        <div class="mb-4">
                            <label for="edit_fio" class="block text-sm font-medium text-gray-700 mb-1">
                                ФИО *
                            </label>
                            <input type="text" id="edit_fio" name="fio" required
                                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                        </div>

                        <div class="mb-4">
                            <label for="edit_dolzhnost" class="block text-sm font-medium text-gray-700 mb-1">
                                Должность
                            </label>
                            <input type="text" id="edit_dolzhnost" name="dolzhnost"
                                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                        </div>

                        <div class="mb-4">
                            <label for="edit_uchenaya_stepen" class="block text-sm font-medium text-gray-700 mb-1">
                                Учёная степень
                            </label>
                            <input type="text" id="edit_uchenaya_stepen" name="uchenaya_stepen"
                                   class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                        </div>

                        <div class="flex items-center justify-end gap-3 mt-6">
                            <button type="button" onclick="closeEditReaderModal()" 
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
                closeEditReaderModal();
            }
        });
    }
    
    // Заполняем форму данными
    document.getElementById('edit_reader_id').value = readerData.id;
    document.getElementById('edit_fio').value = readerData.fio || '';
    document.getElementById('edit_dolzhnost').value = readerData.dolzhnost || '';
    document.getElementById('edit_uchenaya_stepen').value = readerData.uchenaya_stepen || '';
    
    // Показываем модальное окно
    editModal.classList.remove('hidden');
}

// Функция для закрытия модального окна редактирования
function closeEditReaderModal() {
    const editModal = document.getElementById('editReaderModal');
    if (editModal) {
        editModal.classList.add('hidden');
        document.getElementById('editReaderForm').reset();
    }
}

// Функция для обновления читателя
async function updateReader(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const readerId = formData.get('reader_id');
    const readerData = {
        fio: formData.get('fio'),
        dolzhnost: formData.get('dolzhnost'),
        uchenaya_stepen: formData.get('uchenaya_stepen')
    };

    try {
        const response = await fetch(`/api/readers/${readerId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(readerData)
        });

        if (response.ok) {
            closeEditReaderModal();
            // Обновляем страницу для отображения изменений
            window.location.reload();
        } else {
            const error = await response.json();
            alert('Ошибка при обновлении читателя: ' + error.detail);
        }
    } catch (error) {
        console.error('Error:', error);
        alert('Произошла ошибка при обновлении читателя');
    }
}
