CREATE TABLE krisha.krisha_apartments (
    price UInt64,
    city String,
    province String,
    room_size UInt8,
    square_meters Float32,
    kitchen_meters Float32,
    year_built UInt16,
    house_type String,
    complex_name String,
    toilet_type String,
    apartment_floor UInt8,
    total_floor_of_house UInt8,
    parking String,
    mortgaged String,
    ceiling_height String,
    url String
)
ENGINE = MergeTree()
ORDER BY (city, province, price);

SELECT COUNT(url) AS check_duplicates
FROM krisha.krisha_apartments
--GROUP BY url
--HAVING check_duplicates > 1

SELECT province, ROUND(AVG(price)) AS average_price
FROM krisha.krisha_apartments
WHERE room_size = 2
GROUP BY province
ORDER BY average_price DESC

--Средняя цена по количеству комнат
CREATE VIEW IF NOT EXISTS krisha.krisha_avg_price_by_room AS
SELECT
    room_size,
    round(avg(price)) AS avg_price,
    count(*) AS listings
FROM krisha.krisha_apartments
GROUP BY room_size
ORDER BY room_size;


SELECT * FROM krisha_avg_price_by_room kapbr 

--Средняя стоимость за квадратный метр по районам
CREATE OR REPLACE VIEW krisha.krisha_avg_price_per_m2_by_province AS
SELECT
    province,
    round(avg(price / square_meters)) AS avg_price_per_m2,
    count() AS listings
FROM krisha.krisha_apartments
WHERE square_meters > 0
GROUP BY province
ORDER BY avg_price_per_m2 DESC;


SELECT * FROM krisha.krisha_avg_price_per_m2_by_province

--Средняя стоимость за квадратный метр по году постройки
CREATE OR REPLACE VIEW krisha.krisha_avg_price_per_m2_by_year AS
SELECT
    year_built,
    round(avg(price / square_meters)) AS avg_price_per_m2,
    count() AS listings
FROM krisha.krisha_apartments
WHERE square_meters > 0 AND year_built > 1900
GROUP BY year_built
ORDER BY year_built;

SELECT * FROM krisha.krisha_avg_price_per_m2_by_year


--Средняя стоимость за квадратный метр по типу дома
CREATE OR REPLACE VIEW krisha.krisha_avg_price_per_m2_by_house_type AS
SELECT
    house_type,
    round(avg(price / square_meters)) AS avg_price_per_m2,
    count() AS listings
FROM krisha.krisha_apartments
WHERE square_meters > 0
GROUP BY house_type
ORDER BY avg_price_per_m2 DESC;

SELECT * FROM krisha.krisha_avg_price_per_m2_by_house_type


--Средний год постройки по районам
CREATE OR REPLACE VIEW krisha.krisha_avg_year_by_province AS
SELECT
    province,
    round(avg(year_built)) AS avg_year_built,
    count() AS listings
FROM krisha.krisha_apartments
WHERE year_built > 1900
GROUP BY province;

SELECT * FROM krisha.krisha_avg_year_by_province

--Средняя этажность домов по районам
CREATE OR REPLACE VIEW krisha.krisha_avg_floors_by_province AS
SELECT
    province,
    round(avg(total_floor_of_house)) AS avg_floors,
    count() AS listings
FROM krisha.krisha_apartments
WHERE total_floor_of_house > 0
GROUP BY province;

SELECT * FROM krisha.krisha_avg_floors_by_province

--Средняя стоимость по районам
CREATE OR REPLACE VIEW krisha.krisha_avg_price_by_province AS
SELECT
    province,
    round(avg(price)) AS avg_price,
    count() AS listings
FROM krisha.krisha_apartments
GROUP BY province;

SELECT * FROM krisha.krisha_avg_price_by_province

-- Средняя стоимость за м² по жилому комплексу
CREATE OR REPLACE VIEW krisha.krisha_avg_price_per_m2_by_complex AS
SELECT
    complex_name,
    round(avg(price / square_meters)) AS avg_price_per_m2,
    count() AS listings
FROM krisha.krisha_apartments
WHERE square_meters > 0 AND complex_name != ''
GROUP BY complex_name
ORDER BY avg_price_per_m2 DESC;

SELECT * FROM krisha.krisha_avg_price_per_m2_by_complex

--Средняя комнатность по районам
CREATE OR REPLACE VIEW krisha.krisha_avg_room_size_by_province AS
SELECT
    province,
    round(avg(room_size)) AS avg_room_size,
    count() AS listings
FROM krisha.krisha_apartments
WHERE room_size > 0
GROUP BY province
ORDER BY avg_room_size DESC;

SELECT * FROM krisha.krisha_avg_room_size_by_province
















