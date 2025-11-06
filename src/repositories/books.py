from sqlalchemy.orm import Session
from sqlalchemy import select, func, case
import pandas as pd

from models.models import Book, BookItem, Author, Publisher, Theme, author_book
from repositories.database import db


class BookRepository:
    def get_all_books(self):
        """Получить все книги с информацией об авторах и количестве экземпляров"""
        session = db.get_session()
        try:
            # Сначала получаем авторов для книг отдельно
            authors_subq = (
                select(
                    author_book.c.book_id,
                    func.string_agg(Author.author_name, ', ').label('authors')
                )
                .join(Author, author_book.c.author_id == Author.author_id)
                .group_by(author_book.c.book_id)
                .subquery()
            )
            
            # Затем получаем информацию об экземплярах книг
            copies_subq = (
                select(
                    BookItem.book_id,
                    func.count(BookItem.book_item_id).label('total_copies'),
                    func.count(
                        case(
                            (BookItem.book_state == 'Доступна', BookItem.book_item_id),
                            else_=None
                        )
                    ).label('available_copies')
                )
                .group_by(BookItem.book_id)
                .subquery()
            )
            
            # Основной запрос
            stmt = (
                select(
                    Book.book_id,
                    Book.book_name,
                    Book.isbn,
                    Book.release_date,
                    Publisher.publisher_name,
                    Theme.theme_name,
                    authors_subq.c.authors,
                    func.coalesce(copies_subq.c.total_copies, 0).label('total_copies'),
                    func.coalesce(copies_subq.c.available_copies, 0).label('available_copies')
                )
                .select_from(Book)
                .join(Publisher, Book.publisher_id == Publisher.publisher_id)
                .join(Theme, Book.theme_id == Theme.theme_id)
                .join(authors_subq, Book.book_id == authors_subq.c.book_id)
                .join(copies_subq, Book.book_id == copies_subq.c.book_id, isouter=True)
                .order_by(Book.book_name)
            )
            
            result = session.execute(stmt)
            books_data = []
            
            for row in result:
                books_data.append({
                    'book_id': row.book_id,
                    'book_name': row.book_name,
                    'authors': row.authors,
                    'publisher': row.publisher_name,
                    'isbn': row.isbn,
                    'release_date': row.release_date,
                    'theme': row.theme_name,
                    'total_copies': row.total_copies,
                    'available_copies': row.available_copies
                })
            
            return pd.DataFrame(books_data)
            
        except Exception as e:
            print(f"Ошибка при получении книг: {e}")
            return pd.DataFrame()
        finally:
            session.close()
    
    def get_book_items(self, book_id):
        """Получить экземпляры конкретной книги"""
        session = db.get_session()
        try:
            from models.models import BookItem
            stmt = (
                select(BookItem)
                .where(BookItem.book_id == book_id)
                .order_by(BookItem.book_item_id)
            )
            result = session.execute(stmt)
            return result.scalars().all()
        except Exception as e:
            print(f"Ошибка при получении экземпляров книги: {e}")
            return []
        finally:
            session.close()

book_repository = BookRepository()
