from sqlalchemy.orm import Session
from sqlalchemy import select, func
import pandas as pd

from models.models import Reader, BookLoan
from repositories.database import db


class ReaderRepository:
    def get_all_readers(self):
        """Получить всех читателей с информацией о текущих займах"""
        session = db.get_session()
        try:
            # Подзапрос для подсчета активных займов
            active_loans_subq = (
                select(
                    BookLoan.reader_id,
                    func.count(BookLoan.loan_id).label('active_loans')
                )
                .where(BookLoan.loan_due_date.is_(None))
                .group_by(BookLoan.reader_id)
                .subquery()
            )
            
            stmt = (
                select(
                    Reader.reader_id,
                    Reader.fio,
                    Reader.dolzhnost,
                    Reader.uchenaya_stepen,
                    func.coalesce(active_loans_subq.c.active_loans, 0).label('active_loans')
                )
                .select_from(Reader)
                .join(active_loans_subq, Reader.reader_id == active_loans_subq.c.reader_id, isouter=True)
                .order_by(Reader.fio)
            )
            
            result = session.execute(stmt)
            readers_data = []
            
            for row in result:
                readers_data.append({
                    'reader_id': row.reader_id,
                    'fio': row.fio,
                    'dolzhnost': row.dolzhnost,
                    'uchenaya_stepen': row.uchenaya_stepen,
                    'active_loans': row.active_loans
                })
            
            return pd.DataFrame(readers_data)
            
        except Exception as e:
            print(f"Ошибка при получении читателей: {e}")
            return pd.DataFrame()
        finally:
            session.close()

reader_repository = ReaderRepository()
