import datetime

from fastapi import FastAPI, Request, Depends, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.templating import Jinja2Templates
from fastapi.responses import RedirectResponse

from sqlalchemy import and_, func, text

from database import get_db, SessionLocal
from models import *


app = FastAPI()
app.add_middleware(GZipMiddleware, minimum_size=500)
app.mount("/static", StaticFiles(directory="static"), name="static")

templates = Jinja2Templates(directory="templates")


@app.get("/", response_class=HTMLResponse)
async def home_page(request: Request, db = Depends(get_db)):
    try:
        # Получаем статистику
        total_books = db.query(func.count(Book.book_id)).scalar()
        total_available = db.query(func.count(BookItem.book_item_id)).filter(BookItem.book_state == 'Доступна').scalar()
        total_readers = db.query(func.count(Reader.reader_id)).scalar()
        active_loans = db.query(func.count(BookLoan.loan_id)).filter(BookLoan.loan_return_date == None).scalar()

        stats = {
            "total_books": total_books,
            "total_available": total_available,
            "total_readers": total_readers,
            "active_loans": active_loans
        }

        return templates.TemplateResponse(
            request=request, name="homepage.html", context={"stats": stats}
        )

    except Exception as e:
        print(e)
        return "<h1>Server Error: Could not load data.</h1>"





@app.get("/books", response_class=HTMLResponse)
async def books_route(request: Request, search: str = "", db = Depends(get_db)):
    try:
        search_param = f"%{search.strip()}%" if search.strip() else "%"
        
        # Создаем подзапрос для подсчета доступных экземпляров
        from sqlalchemy import func
        
        available_count_subquery = db.query(
            BookItem.book_id,
            func.count(BookItem.book_item_id).label('available_count')
        ).filter(BookItem.book_state == 'Доступна')\
         .group_by(BookItem.book_id)\
         .subquery()
        
        # Основной запрос для получения книг с OUTER JOIN
        query = db.query(
            Book.book_id,
            Book.book_name,
            Theme.theme_name,
            Publisher.publisher_name,
            Book.release_date,
            Book.isbn,
            func.coalesce(available_count_subquery.c.available_count, 0).label('available_book_count')
        ).outerjoin(Publisher, Book.publisher_id == Publisher.publisher_id)\
         .outerjoin(Theme, Book.theme_id == Theme.theme_id)\
         .outerjoin(available_count_subquery, Book.book_id == available_count_subquery.c.book_id)\
         .filter(Book.book_name.ilike(search_param))
        
        values = query.all()
        
        books = []
        for row in values:
            books.append({
                "id": row.book_id,
                "name": row.book_name,
                "theme": row.theme_name or "Не указана",
                "publisher": row.publisher_name or "Не указан",
                "release_date": row.release_date or "Не указана",
                "isbn": row.isbn or "Не указан",
                "available_book_count": row.available_book_count
            })
        
        return templates.TemplateResponse(request=request, name="books.html", context={"books": books, "search": search})
        
    except Exception as e:
        print(e)
        return "<h1>Server Error: Could not load books data.</h1>"




@app.get("/readers", response_class=HTMLResponse)
async def readers_page(request: Request, search: str = "", db = Depends(get_db)):
    try:
        search_param = f"{search.strip()}%"

        query = db.query(
            Reader.reader_id,
            Reader.fio,
            Reader.dolzhnost,
            Reader.uchenaya_stepen,
            func.count(BookLoan.loan_id).label('active_loans_count')
        ).outerjoin(BookLoan, and_(
            BookLoan.reader_id == Reader.reader_id,
            BookLoan.loan_return_date == None
        )).filter(Reader.fio.ilike(search_param))\
         .group_by(
             Reader.reader_id,
             Reader.fio,
             Reader.dolzhnost,
             Reader.uchenaya_stepen
         )

        readers_data = query.all()
        
        readers = []
        for row in readers_data:
            readers.append({
                "id": row.reader_id,
                "fio": row.fio,
                "dolzhnost": row.dolzhnost or "Не указано",
                "uchenaya_stepen": row.uchenaya_stepen or "Не указано",
                "active_loans": row.active_loans_count
            })
        
        return templates.TemplateResponse(
            request=request, name="readers.html", context={"readers": readers, "search": search}
        )
        
    except Exception as e:
        print(e)
        return "<h1>Server Error: Could not load readers data.</h1>"









@app.post("/api/books")
async def add_book(
    book_data: dict,
    db = Depends(get_db)
):
    try:
        # Получаем данные из запроса
        book_name = book_data.get('book_name')
        authors = book_data.get('authors', '')
        publisher = book_data.get('publisher', '')
        isbn = book_data.get('isbn', '')
        release_date = book_data.get('release_date')
        theme = book_data.get('theme', '')
        number_of_books = book_data.get('number_of_books', 1)
        
        # Проверяем обязательное поле
        if not book_name:
            raise HTTPException(status_code=400, detail="Название книги обязательно")
        
        # Преобразуем типы данных
        if release_date:
            try:
                release_date = int(release_date)
            except ValueError:
                release_date = None
            
        if number_of_books:
            try:
                number_of_books = int(number_of_books)
            except ValueError:
                number_of_books = 1
        
        # Получаем текущую дату
        acquisition_date = datetime.date.today()
        
        # Находим или создаем издателя
        publisher_obj = None
        if publisher:
            publisher_obj = db.query(Publisher).filter(Publisher.publisher_name == publisher).first()
            if not publisher_obj:
                publisher_obj = Publisher(publisher_name=publisher)
                db.add(publisher_obj)
                db.flush()  # Получаем ID
        
        # Находим или создаем тему
        theme_obj = None
        if theme:
            theme_obj = db.query(Theme).filter(Theme.theme_name == theme).first()
            if not theme_obj:
                theme_obj = Theme(theme_name=theme)
                db.add(theme_obj)
                db.flush()  # Получаем ID
        
        # Создаем книгу
        book = Book(
            book_name=book_name,
            publisher_id=publisher_obj.publisher_id if publisher_obj else None,
            isbn=isbn if isbn else None,
            release_date=release_date,
            theme_id=theme_obj.theme_id if theme_obj else None
        )
        db.add(book)
        db.flush()  # Получаем ID книги
        
        # Добавляем авторов
        if authors:
            author_names = [name.strip() for name in authors.split(',') if name.strip()]
            for author_name in author_names:
                author = db.query(Author).filter(Author.author_name == author_name).first()
                if not author:
                    author = Author(author_name=author_name)
                    db.add(author)
                    db.flush()  # Получаем ID автора
                
                # Связываем автора с книгой
                author_book = AuthorBook(author_id=author.author_id, book_id=book.book_id)
                db.add(author_book)
        
        # Создаем экземпляры книг
        for _ in range(number_of_books):
            book_item = BookItem(
                book_id=book.book_id,
                book_state='Доступна',
                acquisition_date=acquisition_date
            )
            db.add(book_item)
        
        # Сохраняем все изменения
        db.commit()
        
        return JSONResponse({"message": "Книга успешно добавлена"})
        
    except Exception as e:
        db.rollback()
        print(f"Error adding book: {e}")
        raise HTTPException(status_code=500, detail=f"Ошибка при добавлении книги: {str(e)}")




@app.post("/api/readers")
async def add_reader(
    reader_data: dict,
    db = Depends(get_db)
):
    try:
        # Получаем данные из запроса
        fio = reader_data.get('fio')
        dolzhnost = reader_data.get('dolzhnost', '')
        uchenaya_stepen = reader_data.get('uchenaya_stepen', '')
        
        # Проверяем обязательное поле
        if not fio:
            raise HTTPException(status_code=400, detail="ФИО обязательно")
        
        # Проверяем, нет ли уже читателя с таким ФИО
        existing_reader = db.query(Reader).filter(Reader.fio == fio).first()
        if existing_reader:
            raise HTTPException(status_code=400, detail="Читатель с таким ФИО уже существует")
        
        # Создаем читателя
        reader = Reader(
            fio=fio.strip(),
            dolzhnost=dolzhnost.strip() if dolzhnost else None,
            uchenaya_stepen=uchenaya_stepen.strip() if uchenaya_stepen else None
        )
        
        db.add(reader)
        db.commit()
        
        return JSONResponse({"message": "Читатель успешно добавлен"})
        
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        print(f"Error adding reader: {e}")
        raise HTTPException(status_code=500, detail=f"Ошибка при добавлении читателя: {str(e)}")
    
