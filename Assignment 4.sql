use mavenmovies;

-- Q1.Identify a table in the Sakila database that violates 1NF. Explain how you would normalize it to achieve 1NF.

--      According to the Sakila deatabase in actor_award table the column 'awards' violates 1NF as it has multiple values in the same column. 
--      Explaination: To achieve 1NF, I will normalize the table by creating a separate table for awards and using a linking table 
--                    to represent the many-to-many relationship between actors and awards.


-- Q2.Choose a table in Sakila and describe how you would determine whether it is in 2NF. If it violates 2NF explain the steps to normalize it.

-- In Sakila Database I choose the "stuff" table. This table is already in the 2NF(Second Normal Form)
-- Reasons: 1.The table is already in 1NF (First Normal Form), because each column of the "stuff" table contains atomic values and there are no repeating groups.
--          2.All non-key attributes are fully functional dependent on the primary key.
-- Each non-key attribute (such as first_name, last_name, picture, email) are dependent on the whole primary key (staff_id).There are no partial dependencies where an attribute depends on only a part of the primary key.
-- Therefore, based on the table, it is already in 2NF.


-- Q3.Identify a table in Sakila that violates 3NF. Describe the transitive dependencies present and outline the steps to normalize the table to 3NF.
 
-- Transitive dependency occurs when a non-prime attribute  depends on another non-prime attribute rather than on the candidate keys directly.
-- In Sakila Database the table that violates 3NF is the "film" table because it has a column that depends on another non-key column instead of depending directly on the primary key.
-- If there is a column called 'language_name' that stores the name of the language associated with each film, derived from the language_id foreign key.
-- In this case, language_name would be transitively dependent on film_id through language_id, violating 3NF.
-- To normalize this table to 3NF, I will create a new table for languages, removing the 'language_name' column from the film table. 
-- The new language table might look like this: language_id (Primary Key)
--                                               name
-- Then, after updating the film table to remove the language_name column and replace it with a foreign key language_id that references the language table.


-- Q4.Take a specific table in Sakila and guide through the process of normalizing it from the initial unnormalized form up to at least 2NF.

-- Normalization of the 'film' Table in Sakila Database:

-- First Normal Form (1NF):
-- To ensure 1NF, we have to ensure that each column contains atomic values, and there are no repeating groups. The film table is already in 1NF as it does not contain any repeating values.

-- Second Normal Form (2NF)
-- To achieve 2NF, we need to identify any partial dependencies in the table. In the film table:
-- All non-key attributes (title, description, release_year, rental_duration, rental_rate, length, replacement_cost, rating, special_features, last_update) are fully functionally dependent on the primary key (film_id).
-- 'language_id' and 'original_language_id' are attributes that are functionally dependent on the primary key (film_id).
-- Normalization Steps for 2NF:
-- 1.Create a Language Table:
-- 2.Create a new table named 'language' with columns 'language_id' (Primary Key) and 'language_name'.
-- Populate the language table with unique language IDs and their corresponding names.
-- Modify the film Table:
--                        Remove the 'language_nam'e column from the film table.
--                        Add a foreign key constraint 'language_id' that references the language table.
-- After these steps, the film table will be in 2NF, with the language_id attribute no longer transitively dependent on the film_id. 


-- Q5.Write a query using a CTE to retrieve the distinct list of actor names and the number of films they have acted in from the actor and film_actor tables.
WITH ActorFilmCounts AS (
    SELECT
        a.actor_id,
        concat(a.first_name, ' ' , a.last_name) AS actor_name,
        COUNT(fa.film_id) AS film_count
    FROM actor a
    INNER JOIN film_actor fa ON a.actor_id = fa.actor_id
    GROUP BY a.actor_id, actor_name
)
SELECT
    actor_name,
    film_count
FROM ActorFilmCounts
ORDER BY actor_name;

-- Q6.Use a recursive CTE to generate a hierarchical list of categories and their subcategories from the category table in Sakila.
WITH RECURSIVE CategoryHierarchy AS (
    SELECT
        c.category_id,
        c.name AS category_name,
        NULL AS parent_category_id,
        0 AS level
    FROM
        category c
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM film_category fc
            WHERE fc.category_id = c.category_id
        )

    UNION ALL

    SELECT
        c.category_id,
        c.name AS category_name,
        fc.category_id AS parent_category_id,
        ch.level + 1 AS level
    FROM
        category c
    JOIN
        film_category fc ON c.category_id = fc.category_id
    JOIN
        CategoryHierarchy ch ON fc.category_id = ch.category_id
)

SELECT
    category_id,
    category_name,
    parent_category_id,
    level
FROM
    CategoryHierarchy
ORDER BY
    level, category_id;

-- Q7.Create a CTE that combines information from the film and language tables to display the film title, language name, and rental rate.
WITH FilmLanguage AS (
    SELECT 
        f.title,
        f.rental_rate,
        l.name AS language_name
    FROM film f
    JOIN language l ON f.language_id = l.language_id
)
SELECT 
    title,
    rental_rate,
    language_name
FROM FilmLanguage;

-- Q8.Write a query using a CTE to find the total revenue generated by each customer (sum of payments) from the customer and payment tables.
WITH CustomerRevenue AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(p.amount) AS total_revenue
    FROM customer c
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY 
        c.customer_id,
        c.first_name,
        c.last_name
)
SELECT 
    customer_id,
    first_name,
    last_name,
    total_revenue
FROM CustomerRevenue;

-- Q9.Utilize a CTE with a window function to rank films based on their rental duration from the table.
WITH RankedFilms AS (
    SELECT
        film_id,
        title,
        rental_duration,
        ROW_NUMBER() OVER (ORDER BY rental_duration DESC) AS rental_duration_rank
    FROM film
)
SELECT
    film_id,
    title,
    rental_duration,
    rental_duration_rank
FROM RankedFilms;

-- Q10.Create a CTE to list customers who have made more than two rentals, and then join this CTE with the customer table to retrieve additional customer details.
WITH CustomerRentals AS (
    SELECT
        customer_id,
        COUNT(*) AS rental_count
    FROM rental
    GROUP BY customer_id
    HAVING rental_count > 2
)
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    cr.rental_count
FROM customer c
JOIN CustomerRentals cr ON c.customer_id = cr.customer_id;


-- Q11.Write a query using a CTE to find the total number of rentals made each month, considering the from the table. 
WITH MonthlyRentalCounts AS (
    SELECT
        DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
        COUNT(*) AS rental_count
    FROM rental
    GROUP BY DATE_FORMAT(rental_date, '%Y-%m')
)
SELECT
    rental_month,
    rental_count
FROM MonthlyRentalCounts
ORDER BY rental_month;

-- Q12. Use a CTE to pivot the data from the payment table to display the total payments made by each customer in separate columns for different payment methods.
WITH CustomerPayments AS (
    SELECT 
        pa.customer_id,
        SUM(CASE WHEN pa.amount > 0 THEN pa.amount ELSE 0 END) AS total_cash_payments,
        SUM(CASE WHEN pa.amount <= 0 THEN pa.amount ELSE 0 END) AS total_credit_card_payments
    FROM payment pa
    INNER JOIN customer c ON pa.customer_id = c.customer_id
    GROUP BY pa.customer_id
)
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    cp.total_cash_payments,
    cp.total_credit_card_payments
FROM CustomerPayments cp
INNER JOIN customer c ON cp.customer_id = c.customer_id;


-- Q13.Create a CTE to generate a report showing pairs of actors who have appeared in the same film together,using the film_actor table.  
WITH ActorPairs AS (
    SELECT
        fa1.actor_id AS actor1_id,
        fa2.actor_id AS actor2_id,
        f.title AS film_title
    FROM film_actor fa1
    INNER JOIN
        film_actor fa2 ON fa1.film_id = fa2.film_id
    INNER JOIN
        film f ON fa1.film_id = f.film_id
    WHERE
        fa1.actor_id < fa2.actor_id
)
SELECT
    actor1_id,
    actor2_id,
    film_title
FROM ActorPairs;

-- Q14. Implement a recursive CTE to find all employees in the staff table who report to a specific manager,considering the reports_to column.
WITH RECURSIVE EmployeesHierarchy AS (
Select store_id, manager_staff_id
From store where manager_staff_id is not null
UNION 
Select s.store_id, s.manager_staff_id
From EmployeesHierarchy H
inner join store s on H.manager_staff_id = s.manager_staff_id
)
select * From EmployeesHierarchy H2
inner join staff st2 on st2.store_id = H2.manager_staff_id;







