-- Формирование каталога по тематике/интересам (ОК)
SELECT * FROM books
JOIN themes ON books.theme_id = themes.theme_id
WHERE theme_name = 'Математика' OR theme_name = 'Химия';


SELECT books.* FROM books
JOIN themes ON books.theme_id = themes.theme_id
WHERE theme_name IN ('Экономика', 'Социология', 'Иностранные языки')
UNION
SELECT * FROM books WHERE release_date = 2000;


SELECT books.* FROM books
JOIN themes ON books.theme_id = themes.theme_id
WHERE theme_name = 'Математика'
INTERSECT  
SELECT books.* FROM books
JOIN author_book ON books.book_id = author_book.book_id 
JOIN authors ON author_book.author_id = authors.author_id
WHERE authors.author_name = 'Джерард В.'
EXCEPT 
SELECT books.*
FROM books WHERE release_date = '1700';



-- Просмотр книг отсортированных по старости (ОК)
SELECT * FROM books ORDER BY books.release_date DESC;


-- Просмотр книг с определенного временного диапазона (ОК)
SELECT * FROM books WHERE books.release_date BETWEEN 1992 AND 2002;


-- Группировка книг по категориям (ОК)
SELECT theme_name, count(*) FROM books
JOIN themes ON books.theme_id = themes.theme_id
GROUP BY theme_name ORDER BY theme_name DESC;


-- Поиск книг по подстроке (ОК)
SELECT * FROM books WHERE books.book_name LIKE 'Дифф%';

SELECT * FROM books WHERE books.book_name LIKE 'Х_и_я%';


-- Поиск книг которых вышли позднее самой новой книги по Математике (ОК)
SELECT * FROM books WHERE release_date > 
ALL (
	SELECT release_date FROM books
	JOIN themes ON books.theme_id = themes.theme_id
	WHERE themes.theme_name = 'Математика'
);


-- Поиск читателей с конкретным именем (ОК)
SELECT * FROM readers WHERE split_part(readers.FIO, ' ', 2) = ANY(SELECT 'Сергей' UNION SELECT 'Иван');




-- Регистрация книг (ОК)

BEGIN;
DO $$
DECLARE 
	v_BOOK_NAME text := 'Грузоподъемные машины';
	v_ISBN text := '5-7038-1516-9';
	v_RELEASE_YEAR int := 2000;
	v_NUMBER_OF_BOOKS int := 5;

	v_AUTHOR_NAME text := 'Александров М.П.';
	v_PUBLISHER_NAME text := 'МГТУ им. Н.Э. Баумана';
	v_THEME text := 'Техника';
	v_ACQUISITION_DATE date := '2025-10-27';
	
	
	v_publisher_id int;
	v_theme_id int;
	v_author_id int;
	v_book_id int;
	
	v_book_found int;
BEGIN
	INSERT INTO authors(author_name)
	SELECT v_AUTHOR_NAME
	WHERE NOT EXISTS (SELECT 1 FROM authors WHERE authors.author_name = v_AUTHOR_NAME);
	
	
	INSERT INTO publishers(publisher_name)
	SELECT v_PUBLISHER_NAME
	WHERE NOT EXISTS (SELECT 1 FROM publishers WHERE publishers.publisher_name = v_PUBLISHER_NAME);
	
	
	INSERT INTO themes(theme_name)
	SELECT v_THEME
	WHERE NOT EXISTS (SELECT 1 FROM themes WHERE themes.theme_name = v_THEME);
	
	
	SELECT publisher_id INTO v_publisher_id FROM publishers WHERE publishers.publisher_name = v_PUBLISHER_NAME;
	SELECT theme_id INTO v_theme_id FROM themes WHERE themes.theme_name = v_THEME;
	
	
	INSERT INTO books (book_name, publisher_id, isbn, release_date, theme_id) 
	SELECT v_BOOK_NAME, v_publisher_id, v_ISBN, v_RELEASE_YEAR, v_theme_id
	WHERE NOT EXISTS(SELECT 1 FROM books WHERE isbn = v_ISBN);
	
	
	INSERT book_items(book_id, acquisition_date)
	select book_id, v_ACQUISITION_DATE
	FROM books AS b WHERE v_BOOK_NAME = b.book_name
	cross join lateral generate_series(1, v_NUMBER_OF_BOOKS);


	SELECT author_id INTO v_author_id FROM authors WHERE author_name = v_AUTHOR_NAME;
	SELECT book_id INTO v_book_id FROM books WHERE isbn = v_ISBN;
	
	
	INSERT INTO author_book (author_id, book_id)
	SELECT v_author_id, v_book_id;
	

END;
$$ language plpgsql;

COMMIT;





-- Выдача/получение книг с проверкой возможности (ОК)
BEGIN; 
DO $$
DECLARE 
	v_READER_FIO text := 'Лукин Владимир Николаевич';
	v_BOOK_TO_LOAN text := 'Дифференциальные уравнения';

	v_book_id int;
	v_book_item_id int;
	v_reader_id int;
	
	v_LOAN_DATE date := '2025-10-21';
	v_LOAN_DUE_DATE date := '2025-10-28';
	
BEGIN

	SELECT reader_id INTO v_reader_id FROM readers WHERE FIO = v_READER_FIO;
	IF NOT FOUND THEN 
		raise EXCEPTION 'Читатель "%" не найден!', v_READER_FIO;
	END IF;
	
	
	SELECT book_id INTO v_book_id FROM books WHERE book_name = v_BOOK_TO_LOAN;
	IF NOT FOUND THEN
		raise EXCEPTION 'Книги "%" в библиотеке нет!', v_BOOK_TO_LOAN;
	END IF;
	
	
	SELECT book_item_id INTO v_book_item_id 
	FROM book_items 
	JOIN books
	ON book_items.book_id = books.book_id
	WHERE book_items.book_status = 'Доступна'
	AND books.book_name = v_BOOK_TO_LOAN
	LIMIT 1
	FOR UPDATE;
	
	
	IF NOT FOUND THEN
		raise EXCEPTION 'Все экземлпяры книги "%" разданы!', v_BOOK_TO_LOAN;
	ELSE 
		INSERT INTO book_loans (loan_date, loan_due_date, book_item_id, reader_id)
		SELECT v_LOAN_DATE, v_LOAN_DUE_DATE, v_book_item_id, v_reader_id;
	
	
		UPDATE book_items SET book_status = 'Займ'
		WHERE book_item_id = v_book_item_id;

		
	END IF;
	
	
END;
$$ language plpgsql;
	
	
COMMIT;

-- Проверка получения Лукиным книги (ОК)
SELECT *
FROM book_loans bl
JOIN readers r ON r.reader_id = bl.reader_id
WHERE r.FIO = 'Лукин Владимир Николаевич' AND bl.loan_date = '2025-10-21';






-- Возврат книг (ОК)
BEGIN;

DO $$
DECLARE 
	v_READER_FIO text := 'Лукин Владимир Николаевич';
	v_BOOK_TO_LOAN text := 'Дифференциальные уравнения';

	v_book_item_id int := 123;
BEGIN 
	
	
	SELECT * FROM book_items AS bi
	JOIN book_loans AS bl ON bi.book_item_id = bl.book_item_id
	JOIN readers AS r ON bl.reader_id = r.reader_id
	WHERE r.FIO = v_READER_FIO
	AND bi.book_item_id = v_book_item_id
	AND bi.book_status = 'Займ';
	
	
	IF FOUND
	THEN 
		UPDATE book_items SET book_status = 'Доступна'
		WHERE book_item_id = v_book_item_id;
	
		UPDATE book_loans SET loan_return_date = current_date 
		WHERE book_item_id = v_book_item_id AND loan_return_date = null;

		
	ELSE 
		SELECT * FROM book_items AS bi
		JOIN book_loans AS bl ON bi.book_item_id = bl.book_item_id
		JOIN readers AS r ON bl.reader_id = r.reader_id
		WHERE r.FIO = v_READER_FIO
		AND bi.book_item_id = v_book_item_id
		AND bi.book_status = 'Списана' OR bi.book_status = 'Утеряна';
	
		IF FOUND 
			raise EXCEPTION 'Книга уже была возвращена или она была утеряна/списана библиотекой!', v_BOOK_TO_LOAN;
		END IF;
	
		
	END IF;

END;
$$ language plpgsql;


COMMIT;


-- Деление на русские и советские книги (ОК)
SELECT book_name, release_date,
CASE 
	WHEN release_date <= 1991 THEN 'СССР'
	WHEN release_date > 1991 THEN 'Россия'
	ELSE 'Даты выпуска нет'
END AS Страна
FROM books;


-- Учет читателей (ОК)
SELECT * FROM readers;


# Учет активных читателей (должников книг) (ОК)
SELECT * FROM readers WHERE EXISTS (SELECT 1 FROM book_loans WHERE book_loans.reader_id = readers.reader_id);


-- Списание книг (ОК)

BEGIN;

DO $$
	

BEGIN
	UPDATE book_items
	SET book_status = 'Списана'
	WHERE book_item_id IN 
	(
		SELECT book_items.book_item_id
		FROM books
		JOIN book_items ON books.book_id = book_items.book_id
		WHERE books.release_date < 1800;
	);
	
END;
$$ language plpgsql;

COMMIT;







