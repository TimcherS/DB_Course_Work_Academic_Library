from sqlalchemy import Column, Integer, String, Date, SmallInteger, Text, Boolean, ForeignKey, Table
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship


Base = declarative_base()

author_book = Table(
    'author_book',
    Base.metadata,
    Column('author_id', Integer, ForeignKey('authors.author_id'), primary_key=True),
    Column('book_id', Integer, ForeignKey('books.book_id'), primary_key=True)
)


class Publisher(Base):
    __tablename__ = 'publishers'
    
    publisher_id = Column(Integer, primary_key=True)
    publisher_name = Column(Text, nullable=False)
    
    books = relationship("Book", back_populates="publisher")


class Theme(Base):
    __tablename__ = 'themes'
    
    theme_id = Column(Integer, primary_key=True)
    theme_name = Column(Text)
    
    books = relationship("Book", back_populates="theme")


class Book(Base):
    __tablename__ = 'books'
    
    book_id = Column(Integer, primary_key=True)
    book_name = Column(Text, nullable=False)
    publisher_id = Column(Integer, ForeignKey('publishers.publisher_id'))
    isbn = Column(Text)
    release_date = Column(SmallInteger)
    theme_id = Column(Integer, ForeignKey('themes.theme_id'))
    
    publisher = relationship("Publisher", back_populates="books")
    theme = relationship("Theme", back_populates="books")
    authors = relationship("Author", secondary=author_book, back_populates="books")
    book_items = relationship("BookItem", back_populates="book")


class Author(Base):
    __tablename__ = 'authors'
    
    author_id = Column(Integer, primary_key=True)
    author_name = Column(Text)
    
    books = relationship("Book", secondary=author_book, back_populates="authors")


class BookItem(Base):
    __tablename__ = 'book_items'
    
    book_item_id = Column(Integer, primary_key=True)
    book_id = Column(Integer, ForeignKey('books.book_id'))
    book_state = Column(Text)
    acquisition_date = Column(Date)
    write_of_reasons = Column(Text)
    
    book = relationship("Book", back_populates="book_items")
    loans = relationship("BookLoan", back_populates="book_item")


class Reader(Base):
    __tablename__ = 'readers'
    
    reader_id = Column(Integer, primary_key=True)
    fio = Column(Text, nullable=False)
    dolzhnost = Column(Text)
    uchenaya_stepen = Column(Text)
    
    loans = relationship("BookLoan", back_populates="reader")


class BookLoan(Base):
    __tablename__ = 'book_loans'
    
    loan_id = Column(Integer, primary_key=True)
    loan_date = Column(Date, nullable=False)
    loan_due_date = Column(Date)
    book_item_id = Column(Integer, ForeignKey('book_items.book_item_id'))
    reader_id = Column(Integer, ForeignKey('readers.reader_id'))
    
    book_item = relationship("BookItem", back_populates="loans")
    reader = relationship("Reader", back_populates="loans")
