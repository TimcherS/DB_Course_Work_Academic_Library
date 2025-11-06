from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import streamlit as st

from models.models import Base
from settings import DB_CONFIG


class Database:
    def __init__(self):
        self.engine = None
        self.SessionLocal = None
        
    def init_connection(self):
        try:
            self.engine = create_engine(
                f"postgresql://{DB_CONFIG['user']}:{DB_CONFIG['password']}"
                f"@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['name']}"
            )
            self.SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)
            return True
        except Exception as e:
            st.error(f"Ошибка подключения к базе данных: {e}")
            return False
    
    def get_session(self):
        if self.SessionLocal is None:
            self.init_connection()
        return self.SessionLocal()

db = Database()
