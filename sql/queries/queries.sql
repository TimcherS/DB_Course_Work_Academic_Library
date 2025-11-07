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
FROM books WHERE release_date = 1700;



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


-- Поиск количества каждой книги
SELECT book_name, count(*) as book_count
FROM books AS b
JOIN book_items AS bi
ON b.book_id = bi.book_id
where bi.book_state = 'Доступна'
group by b.book_name 


--1
SELECT 
	book_name,
	theme_name,
	publisher_name,
	release_date,
	isbn,
	select(*) as avaible_book_count
FROM books as b
JOIN publishers as p
on b.publisher_id = p.publisher_id
join themes as t
on b.theme_id = t.theme_id
JOIN book_items AS bi
ON b.book_id = bi.book_id
where book_name ilike $1
and bi.book_state = 'Доступна'
group by b.book_name;



-- Регистрация книг (ОК)
BEGIN;
do $$
begin 
	perform register_book(
		'Грузоподъемные машины'::text, 
		'Александров М.П.'::text, 
		'МГТУ им. Н.Э. Баумана'::text,
		'5-7038-1516-9'::text,
		2000::smallint, 
		'Техника'::text,
		5::smallint, 
		'2025-10-27'::date);
END;
$$ language plpgsql;
COMMIT;




begin;
do $$
begin
	perform loan_book('Лукин Владимир Николаевич'::text, 'Дифференциальные уравнения'::text, '2025-10-21'::date, '2025-10-28'::date);
end;
$$ language plpgsql;

commit;

-- Проверка получения Лукиным книги (ОК)
SELECT *
FROM book_loans bl
JOIN readers r ON r.reader_id = bl.reader_id
WHERE r.FIO = 'Лукин Владимир Николаевич' AND bl.loan_date = '2025-10-21';





-- Лукин вернул книги
begin;
do $$
begin
	perform return book('Лукин Владимир Николаевич', '')
end;
$$ language plpgsql;
commit;



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
	SET book_state = 'Списана'
	WHERE book_item_id IN 
	(
		SELECT book_items.book_item_id
		FROM books AS b
		JOIN book_items AS bi ON b.book_id = bi.book_id
		WHERE b.release_date < 1800
		AND bi.book_state = 'Доступна';
	);
	
END;
$$ language plpgsql;

COMMIT;







