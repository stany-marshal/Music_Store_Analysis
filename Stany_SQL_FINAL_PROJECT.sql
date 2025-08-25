create database music_store;
use music_store;


CREATE TABLE Genre (
	genre_id INT PRIMARY KEY,
	name VARCHAR(120)
);

CREATE TABLE MediaType (
	media_type_id INT PRIMARY KEY,
	name VARCHAR(120)
);

-- 2. Employee
CREATE TABLE Employee (
	employee_id INT PRIMARY KEY,
	last_name VARCHAR(120),
	first_name VARCHAR(120),
	title VARCHAR(120),
	reports_to INT,
  levels VARCHAR(255),
	birthdate DATE,
	hire_date DATE,
	address VARCHAR(255),
	city VARCHAR(100),
	state VARCHAR(100),
	country VARCHAR(100),
	postal_code VARCHAR(20),
	phone VARCHAR(50),
	fax VARCHAR(50),
	email VARCHAR(100)
);

-- 3. Customer
CREATE TABLE Customer (
	customer_id INT PRIMARY KEY,
	first_name VARCHAR(120),
	last_name VARCHAR(120),
	company VARCHAR(120),
	address VARCHAR(255),
	city VARCHAR(100),
	state VARCHAR(100),
	country VARCHAR(100),
	postal_code VARCHAR(20),
	phone VARCHAR(50),
	fax VARCHAR(50),
	email VARCHAR(100),
	support_rep_id INT,
	FOREIGN KEY (support_rep_id) REFERENCES Employee(employee_id)
);

-- 4. Artist
CREATE TABLE Artist (
	artist_id INT PRIMARY KEY,
	name VARCHAR(120)
);

-- 5. Album
CREATE TABLE Album (
	album_id INT PRIMARY KEY,
	title VARCHAR(160),
	artist_id INT,
	FOREIGN KEY (artist_id) REFERENCES Artist(artist_id)
);

-- 6. Track
CREATE TABLE Track (
	track_id INT PRIMARY KEY,
	name VARCHAR(200),
	album_id INT,
	media_type_id INT,
	genre_id INT,
	composer VARCHAR(220),
	milliseconds INT,
	bytes INT,
	unit_price DECIMAL(10,2),
	FOREIGN KEY (album_id) REFERENCES Album(album_id),
	FOREIGN KEY (media_type_id) REFERENCES MediaType(media_type_id),
	FOREIGN KEY (genre_id) REFERENCES Genre(genre_id)
);

-- 7. Invoice
CREATE TABLE Invoice (
	invoice_id INT PRIMARY KEY,
	customer_id INT,
	invoice_date DATE,
	billing_address VARCHAR(255),
	billing_city VARCHAR(100),
	billing_state VARCHAR(100),
	billing_country VARCHAR(100),
	billing_postal_code VARCHAR(20),
	total DECIMAL(10,2),
	FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);

-- 8. InvoiceLine
CREATE TABLE InvoiceLine (
	invoice_line_id INT PRIMARY KEY,
	invoice_id INT,
	track_id INT,
	unit_price DECIMAL(10,2),
	quantity INT,
	FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id),
	FOREIGN KEY (track_id) REFERENCES Track(track_id)
);

-- 9. Playlist
CREATE TABLE Playlist (
 	playlist_id INT PRIMARY KEY,
	name VARCHAR(255)
);

-- 10. PlaylistTrack
CREATE TABLE PlaylistTrack (
	playlist_id INT,
	track_id INT,
	PRIMARY KEY (playlist_id, track_id),
	FOREIGN KEY (playlist_id) REFERENCES Playlist(playlist_id),
	FOREIGN KEY (track_id) REFERENCES Track(track_id)
);



select * from album;
select * from artist;
select * from customer;
select * from employee;
select * from genre;
select * from invoice;
select * from invoiceline;
select * from mediatype;
select * from playlist;
select * from playlisttrack;
select * from track;

SHOW VARIABLES LIKE 'secure_file_priv';

SET GLOBAL local_infile = 1;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/track.csv'
INTO TABLE track
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(track_id, name, album_id, media_type_id, genre_id, composer, milliseconds, bytes, unit_price);

-- 1. Who is the senior most employee based on job title? 

SELECT hire_date,CONCAT(first_name, ' ', last_name)
 AS senior_most_employee,TITLE
FROM employee
ORDER BY hire_date ASC limit 1;

-- 2, Which countries have the most Invoices?
SELECT billing_country, COUNT(*) AS most_invoices
FROM invoice
GROUP BY billing_country
ORDER BY most_invoices DESC limit 1;

-- 3. What are the top 3 values of total invoice?

SELECT invoice_id, customer_id, invoice_date,total 
FROM invoice
ORDER BY total DESC LIMIT 3;


-- 4. Which city has the best customers? - We would like to throw a promotional Music Festival in the city we made the most money. 
-- Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals

SELECT billing_city, SUM(total) AS best_customers_city
FROM invoice
GROUP BY billing_city
ORDER BY best_customers_city DESC
LIMIT 1;

-- 5. Who is the best customer? - The customer who has spent the most money will be declared the best customer.
-- Write a query that returns the person who has spent the most money

SELECT customer_id,CONCAT(first_name, ' ', last_name) AS full_name,
SUM(total) AS most_revenue
FROM customer 
JOIN
    invoice USING (customer_id)
GROUP BY customer_id
ORDER BY most_revenue DESC limit 1;

-- 6. Write a query to return the email, first name, last name, & Genre of all Rock Music listeners.
-- Return your list ordered alphabetically by email starting with A

SELECT DISTINCT c.Email, c.First_Name, c.Last_Name, g.Name AS Genre
FROM Customer c
JOIN Invoice i using (Customer_Id)
JOIN InvoiceLine il using (Invoice_Id)
JOIN Track t using (Track_Id)
JOIN Genre g using (Genre_Id) 
WHERE g.Name LIKE 'Rock%'
ORDER BY c.Email ASC;

-- 7. Let's invite the artists who have written the most rock music in our dataset.
 -- Write a query that returns the Artist name and total track count of the top 10 rock bands 

SELECT ar.artist_id, ar.name AS Artist_Name, COUNT(t.track_id) AS Track_count
FROM artist ar
JOIN album al USING (artist_id)
JOIN track t USING (album_id)
JOIN genre g USING (genre_id)
WHERE g.name LIKE 'Rock'
GROUP BY ar.artist_id, ar.name
ORDER BY Track_count DESC limit 10;

-- 8. Return all the track names that have a song length longer than the average song length.- 
-- Return the Name and Milliseconds for each track. Order by the song length, with the longest songs listed first

SELECT name, milliseconds
FROM track 
WHERE milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY milliseconds;

-- 9. Find how much amount is spent by each customer on artists? Write a query to return customer name, artist name and total spent 

SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
ar.name AS artist_name, SUM(il.unit_price * il.quantity)
AS total_spent
FROM customer c
JOIN invoice i USING (customer_id)
JOIN invoiceline il USING (invoice_id)
JOIN track t USING (track_id)
JOIN album al USING (album_id)
JOIN artist ar USING (artist_id)
GROUP BY customer_id, artist_name
ORDER BY total_spent DESC;

-- 10. We want to find out the most popular music Genre for each country. 
-- We determine the most popular genre as the genre with the highest amount of purchases.
-- Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared, return all Genres


WITH GenreSales AS (
SELECT c.country, g.name AS genre_name, 
COUNT(il.invoice_line_id) AS purchase_count,
RANK() OVER (PARTITION BY c.country 
ORDER BY COUNT(il.invoice_line_id) DESC) AS rank_in_country
FROM customer c
JOIN invoice i using (customer_id)
JOIN invoiceline il using(invoice_id)
JOIN track t using (track_id)
JOIN genre g using (genre_id)
GROUP BY c.country, g.name)
SELECT country,genre_name, purchase_count
FROM GenreSales
WHERE rank_in_country = 1
ORDER BY country;

-- 11. Write a query that determines the customer that has spent the most on music for each country.
--  Write a query that returns the country along with the top customer and how much they spent.
 -- For countries where the top amount spent is shared, provide all customers who spent this amount

WITH ranked_customers AS (
SELECT CONCAT(first_name, ' ', last_name) AS Customers, country,
SUM(total) AS total_amount_spent,
RANK() OVER (PARTITION BY country 
ORDER BY SUM(total) DESC) AS rank_in_country
FROM customer
join invoice USING (customer_id)
GROUP BY Customers, country
)
SELECT country,Customers, total_amount_spent
FROM ranked_customers
WHERE rank_in_country = 1
ORDER BY country;
