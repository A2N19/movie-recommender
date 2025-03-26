
--All animation movies released between 2017 and 2019 WITH rate more than 1, alphabetical

SELECT f.film_id, f.title, f.release_year, f.rental_rate --selecting fields from the table film
FROM film f 
INNER JOIN film_category fc USING (film_id) --inner join to connect the film_category and category tables
INNER JOIN category c USING (category_id)
WHERE c.name = 'Animation' --animation movies
AND f.release_year BETWEEN 2017 AND 2019 --movies released between 2017 AND 2019
AND f.rental_rate  > 1 --rate more than 1
ORDER BY f.release_year, f.title ; --alphabetically ordered

--The revenue earned by each rental store after March 2017 (columns: address and address2 – as one column, revenue)
SELECT s.store_id, a.address, SUM(p.amount) AS revenue --selects necessary fields and summing up the amount
FROM store s 
INNER JOIN address a USING (address_id) --joins to extract stores addresses (also the task says to concat columns address and address2, but there's null in the column address2)
INNER JOIN inventory i USING (store_id) -- use inventory and rental tables to reach the payment table
INNER JOIN rental r USING (inventory_id) 
INNER JOIN payment p USING (rental_id) --to sum the amounts
WHERE payment_date >= '2017-04-01' --filter data that after march 2017, that means FROM the 1st of april of 2017
GROUP BY s.store_id, a.address --grouping by store and its address
ORDER BY revenue DESC --orders by revenue in descending order


--Top-5 actors by number of movies (released after 2015) they took part in 
--(columns: first_name, last_name, number_of_movies, sorted by number_of_movies in DESCending order)
SELECT a.first_name, a.last_name, COUNT(fa.film_id) AS number_of_movies
FROM actor a 
INNER JOIN film_actor fa USING (actor_id) --joins fa table to count the num of movies and to connect film table
INNER JOIN film f USING (film_id) --joins to get the movies release year
WHERE f.release_year > 2015 --released after 2015, it means 2015 is excluded
GROUP BY a.actor_id --grouping by actors id
ORDER BY number_of_movies DESC --ordres from the biggest number of movies to the lowest
LIMIT 5 --remain only top 5

--Number of Drama, Travel, Documentary per year 
--(columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), 
--sorted by release year in descending order. Dealing with NULL values is encouraged)
WITH drama_movies AS (
		SELECT f.release_year, COUNT(*) AS number_of_drama_movies --use three almost exact CTEs to calculate number of films by category and each YEAR AND THEN CALL them IN the main request
		FROM category c
		INNER JOIN film_category fc USING (category_id)
		INNER JOIN film f USING (film_id)
		WHERE c.category_id = 7 --drama's id
		GROUP BY f.release_year 
		ORDER BY f.release_year DESC
),
travel_movies AS (
		SELECT f.release_year, COUNT(*) AS number_of_travel_movies
		FROM category c
		INNER JOIN film_category fc USING (category_id)
		INNER JOIN film f USING (film_id)
		WHERE c.category_id = 16 --travel's id
		GROUP BY f.release_year 
		ORDER BY f.release_year DESC
),
documentary_movies AS (
		SELECT f.release_year, COUNT(*) AS number_of_documentary_movies
		FROM category c
		INNER JOIN film_category fc USING (category_id)
		INNER JOIN film f USING (film_id)
		WHERE c.category_id = 6 --doc's id
		GROUP BY f.release_year 
		ORDER BY f.release_year DESC
)
SELECT COALESCE(dm.release_year, tm.release_year, docm.release_year) AS release_year, --USING COALESCE FUNCTIONS TO MERGE COLUMNS AND REPLACE NULL VALUES TO 0
		COALESCE(dm.number_of_drama_movies, 0) AS number_of_drama_movies,
		COALESCE(tm.number_of_travel_movies, 0) AS number_of_travel_movies,
    	COALESCE(docm.number_of_documentary_movies, 0) AS number_of_documentary_movies
FROM drama_movies dm
FULL JOIN travel_movies tm USING (release_year) --	use FULL JOIN TO combine ALL the ROWS even tough there's NO matches BETWEEN TABLES 
FULL JOIN documentary_movies docm USING (release_year)


--Which three employees generated the most revenue in 2017? They should be awarded a bonus for their outstANDing performance. 
SELECT s.staff_id, s.first_name, s.last_name, sum(p.amount) AS revenue
FROM staff s 
INNER JOIN payment p USING (staff_id)
WHERE p.payment_date BETWEEN '2017-01-01' AND '2017-12-31'
GROUP BY s.staff_id, s.first_name, s.last_name
ORDER BY revenue DESC
LIMIT 3


WITH staff_revenue AS ( -- counts top 3 staff worker BY 2017 revenue 
    SELECT 
        p.staff_id, 
        SUM(p.amount) AS revenue
    FROM payment p
    WHERE p.payment_date BETWEEN '2017-01-01' AND '2017-12-31'
    GROUP BY p.staff_id
    ORDER BY revenue DESC
    LIMIT 3
),
last_payment AS ( -- finding the LAST payment OF staff worker
    SELECT 
        p.staff_id, 
        MAX(p.payment_date) AS last_payment
    FROM payment p
    WHERE p.payment_date BETWEEN '2017-01-01' AND '2017-12-31'
    GROUP BY p.staff_id
),
store_by_last_payment AS ( -- defines the LAST store that staff worker had the payment
    SELECT 
        lp.staff_id, 
        s.store_id
    FROM last_payment lp
    INNER JOIN staff s USING (staff_id)
)
SELECT 
    sr.staff_id, 
    s.first_name, 
    s.last_name, 
    sr.revenue, 
    sb.store_id
FROM staff_revenue sr
INNER JOIN staff s USING (staff_id) --joins the staff TABLE TO GET fullnames OF staff
INNER JOIN store_by_last_payment sb USING (staff_id) --calls the cte store_by_last_payment
ORDER BY sr.revenue DESC; --orders BY revwnue IN descending ORDER


--Which 5 movies were rented more than others (number of rentals), AND what's the expected age of the audience for these movies? 
--To determine expected age please use 'Motion Picture Association film rating system

SELECT f.title, COUNT(i.film_id) AS number_of_rents, f.rating --counts the amount OF films that were rented BY id
FROM rental r 
INNER JOIN 	inventory i USING (inventory_id) --bridge BETWEEN rental AND film 
INNER JOIN film f USING (film_id)
GROUP BY f.title, f.rating --GROUPS BY movies title AND rating 
ORDER BY number_of_rents DESC --orders IN descending order
LIMIT 5 --leaves the top 5

--Which actors/actresses didn't act for a longer period of time than the others? 
--V1: gap BETWEEN the latest release_year AND current year per each actor

SELECT a.first_name, a.last_name, EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year) AS years_without_films --exracts YEAR FROM the CURRENT date AND THEN subtracts the YEAR OF the LAST film OF actor
FROM actor a
INNER JOIN film_actor fa USING (actor_id) --bridge BETWEEN actor AND film TABLES 
INNER JOIN film f USING (film_id)
GROUP BY a.first_name, a.last_name --GROUPS BY their fullname
ORDER BY years_without_films DESC --orders IN descending ORDER TO VIEW who has the longest PERIOD OF time WITHOUT films


--Calculate revenue per store for each month of 2017 
--Also rank months within each store based on revenue (1 = highest)
--(columns: store_id, month, monthly_revenue, rank_in_store)

SELECT 
    s.store_id, --store ID
    DATE_TRUNC('month', p.payment_date) AS month, --extracting month from the payment date
    SUM(p.amount) AS monthly_revenue, --calculates total revenue per store per month
    RANK() OVER (PARTITION BY s.store_id ORDER BY SUM(p.amount) DESC) AS rank_in_store --ranks months by revenue within each store
FROM store s 
INNER JOIN inventory i USING (store_id) --joining inventory to reach rentals
INNER JOIN rental r USING (inventory_id) --joining rental to access payment info
INNER JOIN payment p USING (rental_id) --joining payment to calculate revenue
WHERE p.payment_date BETWEEN '2017-01-01' AND '2017-12-31' --filter only 2017 data
GROUP BY s.store_id, month --group by store and month
ORDER BY s.store_id, rank_in_store; --sorts results by store and their top months


--Identify movies with the longest time gap between any two rentals
--Returns top 5 movies with the largest rental gaps in days
--(columns: title, max_rental_gap_days)

WITH rental_dates AS ( 
    SELECT 
        f.film_id,
        f.title,
        r.rental_date,
        ROW_NUMBER() OVER (PARTITION BY f.film_id ORDER BY r.rental_date) AS rn --ranks rentals chronologically per film
    FROM film f 
    INNER JOIN inventory i USING (film_id) --joins to link rentals to movies
    INNER JOIN rental r USING (inventory_id) --retrieves all rental dates
),
rental_gaps AS (
    SELECT 
        film_id,
        title,
        rental_date AS current_rent,
        LAG(rental_date) OVER (PARTITION BY film_id ORDER BY rental_date) AS prev_rent --gets previous rental per film
    FROM rental_dates
)
SELECT 
    title,
    MAX(DATE_PART('day', current_rent - prev_rent)) AS max_rental_gap_days --calculates max day difference
FROM rental_gaps
WHERE prev_rent IS NOT NULL --ignores rows without a previous rental
GROUP BY film_id, title --group by film to get maximum per movie
ORDER BY max_rental_gap_days DESC --returns top 5 longest gaps
LIMIT 5;


--Create index on payment_date for faster filtering by date range
CREATE INDEX idx_payment_date ON payment(payment_date);

--Create index on rental_id to improve rental/payment joins
CREATE INDEX idx_payment_rental_id ON payment(rental_id);

--Create index on film_id to optimize film joins via inventory
CREATE INDEX idx_inventory_film_id ON inventory(film_id);

