CREATE EXTENSION pg_trgm;

begin; 

drop domain if exists book_states cascade;

DROP TABLE IF EXISTS publishers CASCADE;
DROP TABLE IF EXISTS themes CASCADE;
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF exists book_items cascade;
DROP TABLE IF EXISTS authors CASCADE;
DROP TABLE IF EXISTS author_book CASCADE;
DROP TABLE IF EXISTS readers CASCADE;
DROP TABLE IF EXISTS book_loans CASCADE;
DROP TABLE IF EXISTS reader_fine_logs CASCADE;


DROP ROUTINE IF EXISTS register_book; 
DROP ROUTINE IF EXISTS loan_book;
DROP ROUTINE IF EXISTS return_book;

DROP ROUTINE IF EXISTS add_authors(text);
DROP ROUTINE IF EXISTS add_publisher(text);
DROP ROUTINE IF EXISTS add_theme(text);
DROP ROUTINE IF EXISTS register_reader;






create domain book_states as text
default 'Доступна'
check (value in ('Доступна', 'Списана', 'Утеряна', 'Займ'));



CREATE TABLE publishers (
	publisher_id bigserial PRIMARY KEY,
	publisher_name text NOT null unique
);

CREATE TABLE themes (
	theme_id bigserial PRIMARY KEY,
	theme_name text not null unique
);


CREATE TABLE books (
	book_id bigserial PRIMARY KEY,
	book_name text NOT NULL,
	publisher_id bigint REFERENCES publishers(publisher_id),
	isbn text,
	release_date timestamptz,
	theme_id bigint REFERENCES themes(theme_id)
);
DROP INDEX IF EXISTS book_name_gin;
CREATE INDEX book_name_gin ON books USING gin(book_name gin_trgm_ops);


create table book_items (
	book_item_id bigserial primary key,
	book_id bigint references books(book_id),
	book_price bigint CHECK(book_price >= 0 OR book_price IS NULL),
	book_state book_states,
	acquisition_date timestamptz,
	write_off_reasons text,
	shelf_location text not NULL
);


CREATE TABLE authors (
	author_id bigserial PRIMARY KEY,
	author_name text not null unique
);



CREATE TABLE author_book (
	author_id bigint REFERENCES authors(author_id),
	book_id bigint REFERENCES books(book_id),
	PRIMARY KEY (author_id, book_id)
);


CREATE TABLE readers (
	reader_id bigserial PRIMARY KEY,
	FIO text NOT null unique,
	Dolzhnost text,
	Uchenaya_Stepen text
);
DROP INDEX IF EXISTS reader_name_gin;
CREATE INDEX reader_name_gin ON readers USING gin(FIO gin_trgm_ops);


CREATE TABLE book_loans (
	loan_id bigserial,
	loan_date timestamptz default now(),
	loan_due_date timestamptz,
	loan_return_date timestamptz default null,

	book_item_id bigint REFERENCES book_items(book_item_id),
	reader_id bigint REFERENCES readers(reader_id),
	
	PRIMARY KEY(loan_id, loan_date)
) PARTITION BY RANGE(loan_date);


CREATE TABLE book_loans_archive partition of book_loans
FOR VALUES FROM ('1800-01-01') TO ('2024-01-01');

CREATE TABLE book_loans_2024 partition of book_loans
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE book_loans_2025 partition of book_loans
FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE book_loans_default PARTITION OF book_loans
DEFAULT;

DROP INDEX IF EXISTS book_loans_archive_brin;
CREATE INDEX book_loans_archive_brin ON book_loans_archive USING brin(loan_date);

DROP INDEX IF EXISTS book_loans_idx;
CREATE INDEX book_loans_idx ON book_loans_2025(loan_date) WHERE loan_return_date IS null; 




--TRIGGERS
create or replace function book_loan_tg_fn()
RETURNS TRIGGER 
LANGUAGE plpgsql 
AS $$
DECLARE 
	v_unreturned_books bigint := 0;
	temp_loan record;
BEGIN 
	
	FOR temp_loan IN (SELECT * FROM book_loans AS bl WHERE bl.reader_id = NEW.reader_id AND loan_return_date IS NULL) 
	loop
		IF now() - temp_loan.loan_due_date > INTERVAL '30 days' 
		THEN 
			v_unreturned_books := v_unreturned_books + 1;
		END IF;	
	END loop;
	
	IF v_unreturned_books > 5 THEN
		raise EXCEPTION 'Читатель "%" больше чем на месяц просрочил % книг (Лимит 5)', NEW.reader_id, v_unreturned_books;
	END IF;
	
	RETURN NEW;
END;
$$;



CREATE TRIGGER book_loan_tg
BEFORE INSERT ON book_loans
FOR EACH ROW
EXECUTE FUNCTION book_loan_tg_fn();


--Аналитика по самым популярным жанрам (тяжелый запрос)
CREATE materialized VIEW most_popular_genres_view AS
SELECT
	t.theme_id,
	t.theme_name,
	count(*)
	
FROM
	books AS b
	JOIN themes AS t ON b.theme_id = t.theme_id
	JOIN book_items AS bi ON b.book_id = bi.book_id
	JOIN book_loans AS bl ON bl.book_item_id = bi.book_item_id
	GROUP BY t.theme_id, t.theme_name
ORDER BY count(*) DESC;


CREATE TABLE reader_fine_logs (
	fine_id bigserial,
	reader_id bigint REFERENCES readers(reader_id),
	book_item_id bigint REFERENCES book_items(book_item_id),
	fine_sum numeric(10,2)
);






CREATE OR replace FUNCTION calculate_fine(
	p_loan_id bigint
) RETURNS numeric(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
	v_loan_due_date timestamptz;
	v_loan_return_date timestamptz;
	v_book_price bigint;
	v_fine_sum numeric(10,2);
BEGIN
	select bl.loan_due_date, bl.loan_return_date, bi.book_price
	INTO v_loan_due_date, v_loan_return_date, v_book_price
	FROM book_loans AS bl
	JOIN book_items AS bi
	ON bl.book_item_id = bi.book_item_id
	WHERE bl.loan_id = p_loan_id;
	
	v_fine_sum := EXTRACT(DAY FROM (v_loan_return_date - v_loan_due_date)) * v_book_price * 0.01;
	
	IF v_fine_sum < 0
		THEN RETURN NULL;
	END IF;
	
	RETURN v_fine_sum;
END;
$$;


CREATE OR replace FUNCTION book_loan_after_trg_fn()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
	v_fine_sum numeric(10,2);
BEGIN
	v_fine_sum := calculate_fine(NEW.loan_id);
	IF v_fine_sum > 0 then
		INSERT INTO reader_fine_logs(reader_id, book_item_id, fine_sum) VALUES
		(NEW.reader_id, NEW.book_item_id, v_fine_sum);
	END IF;
	RETURN NEW;
END;
$$;



CREATE TRIGGER book_loan_after_trg
AFTER update of loan_return_date ON book_loans
FOR EACH row
WHEN (OLD.loan_return_date IS NULL AND NEW.loan_return_date IS NOT NULL)
EXECUTE FUNCTION book_loan_after_trg_fn();






-- Регистрация книг (ОК)
create or replace procedure register_book(
	p_BOOK_NAME text,
	p_AUTHORS_LIST text,
	p_PUBLISHER_NAME text,
	p_ISBN text,
	p_RELEASE_DATE timestamptz,
	p_THEME text,
	p_NUMBER_OF_BOOKS bigint,
	p_ACQUISITION_DATE timestamptz,
	p_PRICE bigint DEFAULT NULL, 
    p_SHELF_LOCATION text DEFAULT NULL
) as $$
DECLARE 

	v_publisher_id bigint;
	v_theme_id bigint;
	v_book_id bigint;
	
	v_book_found bigint;
BEGIN


	CALL add_authors(p_AUTHORS_LIST);
	CALL add_publisher(p_PUBLISHER_NAME);
	CALL add_theme(p_THEME);
	
	
	
	SELECT publisher_id INTO v_publisher_id FROM publishers WHERE publishers.publisher_name = p_PUBLISHER_NAME;
	SELECT theme_id INTO v_theme_id FROM themes WHERE themes.theme_name = p_THEME;

	SELECT book_id INTO v_book_id 
	FROM books WHERE isbn is not distinct from p_ISBN and book_name = p_BOOK_NAME;

	if not found then
		INSERT INTO books (book_name, publisher_id, isbn, release_date, theme_id) 
		SELECT p_BOOK_NAME, v_publisher_id, p_ISBN, p_RELEASE_DATE, v_theme_id
		WHERE NOT EXISTS(SELECT 1 FROM books WHERE isbn = p_ISBN)
		returning book_id into v_book_id;
	end if;
		


	INSERT into book_items(book_id, acquisition_date, book_price, shelf_location, book_state)
	select v_book_id, p_ACQUISITION_DATE, p_PRICE, p_SHELF_LOCATION, 'Доступна'
	FROM generate_series(1, p_NUMBER_OF_BOOKS);
	

	INSERT INTO author_book(book_id, author_id)
	select DISTINCT
	    v_book_id,
	    a.author_id
	from unnest(string_to_array(p_AUTHORS_LIST, ',')) AS t(parsed_author_name)
	join
		authors as a on a.author_name = trim(t.parsed_author_name)
	WHERE
	    p_AUTHORS_LIST IS NOT NULL
		AND TRIM(t.parsed_author_name) <> ''
	ON CONFLICT (author_id, book_id) DO NOTHING;
	

END;
$$ language plpgsql;



-- Выдача/получение книг с проверкой возможности (ОК)
create or replace procedure loan_book(
	p_READER_FIO text,
	p_BOOK_TO_LOAN text,
	p_LOAN_DATE timestamptz,
	p_LOAN_DUE_DATE timestamptz
) as $$
DECLARE 
	v_book_id bigint;
	v_book_item_id bigint;
	v_reader_id bigint;
BEGIN

	SELECT reader_id INTO v_reader_id FROM readers WHERE FIO = p_READER_FIO;
	IF NOT FOUND THEN 
		raise EXCEPTION 'Читатель "%" не найден!', p_READER_FIO;
	END IF;
	
	
	SELECT book_id INTO v_book_id FROM books WHERE book_name = p_BOOK_TO_LOAN;
	IF NOT FOUND THEN
		raise EXCEPTION 'Книги "%" в библиотеке нет!', p_BOOK_TO_LOAN;
	END IF;
	
	
	SELECT book_item_id INTO v_book_item_id 
	FROM book_items 
	JOIN books
	ON book_items.book_id = books.book_id
	WHERE book_items.book_state = 'Доступна'
	AND books.book_name = p_BOOK_TO_LOAN
	LIMIT 1
	FOR UPDATE;
	
	
	IF NOT FOUND THEN
		raise EXCEPTION 'Все экземлпяры книги "%" разданы!', p_BOOK_TO_LOAN;
	ELSE 
		INSERT INTO book_loans (loan_date, loan_due_date, book_item_id, reader_id)
		SELECT p_LOAN_DATE, p_LOAN_DUE_DATE, v_book_item_id, v_reader_id;
	
	
		UPDATE book_items SET book_state = 'Займ'
		WHERE book_item_id = v_book_item_id;

		
	END IF;
	
	
END;
$$ language plpgsql;



-- Возврат книг (ОК)
CREATE OR replace procedure return_book(
	p_READER_FIO text,
	p_book_item_id bigint
) AS $$
DECLARE 
	v_book_name text;
BEGIN 
	
	
	perform 1 FROM book_items AS bi
	JOIN book_loans AS bl ON bi.book_item_id = bl.book_item_id
	JOIN readers AS r ON bl.reader_id = r.reader_id
	WHERE r.FIO = p_READER_FIO
	AND bi.book_item_id = p_book_item_id
	AND bi.book_state = 'Займ';
	
	
	IF FOUND
	THEN 
		UPDATE book_items SET book_state = 'Доступна'
		WHERE book_item_id = p_book_item_id;
	
		UPDATE book_loans SET loan_return_date = current_timestamp
		WHERE book_item_id = p_book_item_id AND loan_return_date is null;

		
	ELSE 
		perform 1 FROM book_items AS bi
		JOIN book_loans AS bl ON bi.book_item_id = bl.book_item_id
		JOIN readers AS r ON bl.reader_id = r.reader_id
		WHERE r.FIO = p_READER_FIO
		AND bi.book_item_id = p_book_item_id
		AND (bi.book_state = 'Списана' OR bi.book_state = 'Утеряна');
	
	
		SELECT book_name INTO v_book_name 
		FROM books AS b
		JOIN book_items AS bi
		ON b.book_id = bi.book_id
		WHERE bi.book_item_id = p_book_item_id;
	
		IF FOUND 
		then 
			raise EXCEPTION 'Книга "%" уже была возвращена или она была утеряна/списана библиотекой!', v_book_name;
		END IF;
	
		
	END IF;

END;
$$ language plpgsql;


CREATE OR replace procedure add_authors (
	p_AUTHORS_LIST text
) AS $$
BEGIN
	
	INSERT INTO authors(author_name)
	SELECT
	    trim(name)
	FROM 
		unnest(string_to_array(p_AUTHORS_LIST, ',')) AS author_name(name)
	WHERE
	    TRIM(name) <> ''
	ON conflict (author_name) do nothing;
END;
$$ LANGUAGE plpgsql;


CREATE OR replace PROCEDURE add_publisher (
	p_PUBLISHERS_LIST text
) AS $$
BEGIN
	
	INSERT INTO publishers(publisher_name)
	SELECT
	    trim(name)
	FROM 
		unnest(string_to_array(p_PUBLISHERS_LIST, ',')) AS publisher_name(name)
	WHERE
	    TRIM(name) <> ''
	ON conflict (publisher_name) do nothing;
END;
$$ LANGUAGE plpgsql;


CREATE OR replace procedure add_theme (
	p_THEMES_LIST text
) AS $$
BEGIN
	
	INSERT INTO themes(theme_name)
	SELECT
	    trim(name)
	FROM 
		unnest(string_to_array(p_THEMES_LIST, ',')) AS theme_name(name)
	WHERE
	    TRIM(name) <> ''
	ON conflict (theme_name) do nothing;
END;
$$ LANGUAGE plpgsql;


CREATE OR replace procedure register_reader (
	p_FIO text,
	p_Dolzhnost text,
	p_Uchenaya_Stepen text
) AS $$
BEGIN
	
	INSERT INTO readers(FIO, Dolzhnost, Uchenaya_Stepen)
	values
	    (trim(p_FIO), trim(p_Dolzhnost), trim(p_Uchenaya_Stepen))
	ON conflict (FIO) do nothing;
END;
$$ LANGUAGE plpgsql;


commit;


