# DB_Course_Work_Academic_Library

Для запуска проекта следуйте инструкции.

Создайте базу данных "academic_library", а затем создайте таблицы и заполните их данными с помощью этих команд:
```
psql -U postgres -d academic_library -f sql/schema.sql
psql -U postgres -d academic_library -f sql/seed.sql
```

Создайте и активируйте виртуальное оружение:
```
python -m venv .venv
source .venv/Scripts/activate
```

Установите зависимости:
```
pip install -r requirements.txt
```

Создайте файл .env и укажите свои переменные:
| Переменная | Значение |
|-|-|
| DB_NAME | academic_library |
| DB_PASSWORD | 123456 |
| DB_USER | postgres |
| DB_HOST | localhost |
| DB_PORT | 5432 |

Запустите проект:
```
streamlit run src/main.py
```
