begin; 


drop domain if exists book_status cascade;

DROP TABLE IF EXISTS temp_raw_books CASCADE;
DROP TABLE IF EXISTS publishers CASCADE;
DROP TABLE IF EXISTS themes CASCADE;
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF exists book_items cascade;
DROP TABLE IF EXISTS authors CASCADE;
DROP TABLE IF EXISTS author_book CASCADE;
DROP TABLE IF EXISTS readers CASCADE;
DROP TABLE IF EXISTS book_loans CASCADE;
DROP TABLE IF EXISTS temp_book_loans_raw CASCADE;


create domain book_status as text
default 'Доступна'
check (value in ('Доступна', 'Списана', 'Утеряна', 'Займ'));


CREATE TABLE temp_raw_books (
    id SERIAL PRIMARY KEY,
    book_name TEXT,
    authors_list TEXT,
    publisher_name TEXT,
    isbn TEXT,
    release_date smallint,
    theme_name text,
    number_of_books smallint,
    acquisition_date date default current_date
);


CREATE TABLE publishers (
	publisher_id serial PRIMARY KEY,
	publisher_name text NOT NULL
);

CREATE TABLE themes (
	theme_id serial PRIMARY KEY, 
	theme_name text
);


CREATE TABLE books (
	book_id serial PRIMARY KEY,
	book_name text NOT NULL,
	publisher_id int REFERENCES publishers(publisher_id),	
	isbn text,
	release_date smallint,
	theme_id int REFERENCES themes(theme_id)
);

create table book_items (
	book_item_id serial primary key,
	book_id int references books(book_id),
	book_state book_status default null,
	acquisition_date date,
	write_of_reasons text
);


CREATE TABLE authors (
	author_id serial PRIMARY KEY,
	author_name text
);



CREATE TABLE author_book (
	author_id int REFERENCES authors(author_id),
	book_id int REFERENCES books(book_id),
	PRIMARY KEY (author_id, book_id)
);


CREATE TABLE readers (
	reader_id serial PRIMARY KEY,
	FIO text NOT NULL,
	Dolzhnost text,
	Uchenaya_Stepen text
);

CREATE TABLE book_loans (
	loan_id serial PRIMARY KEY,
	loan_date date NOT NULL,
	loan_due_date date,

	book_item_id int REFERENCES book_items(book_item_id),
	reader_id int REFERENCES readers(reader_id)
);

CREATE TABLE temp_book_loans_raw (
	id serial PRIMARY KEY,
	loan_date date,
	FIO text,
	book_name text
);

commit;