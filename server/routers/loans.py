from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime

from database import get_db
from models import *

router = APIRouter(prefix="/api/loans", tags=["loans"])

@router.post("/{loan_id}/return")
async def return_loan(loan_id: int, return_data: dict, db: Session = Depends(get_db)):
    try:
        # Находим займ
        loan = db.query(BookLoan).filter(BookLoan.loan_id == loan_id).first()
        if not loan:
            raise HTTPException(status_code=404, detail="Займ не найден")
        
        # Проверяем, не возвращена ли уже книга
        if loan.loan_return_date:
            raise HTTPException(status_code=400, detail="Книга уже возвращена")
        
        # Обновляем дату возврата
        loan.loan_return_date = datetime.now()
        
        # Обновляем статус книги
        book_item = db.query(BookItem).filter(BookItem.book_item_id == loan.book_item_id).first()
        if book_item:
            book_item.book_state = 'Доступна'
        
        db.commit()
        
        return {"message": "Книга успешно возвращена"}
        
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        print(f"Error returning loan: {e}")
        raise HTTPException(status_code=500, detail=f"Ошибка при возврате книги: {str(e)}")
