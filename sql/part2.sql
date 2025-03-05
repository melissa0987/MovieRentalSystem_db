/*
	Melissa Louise Bangloy  
	Database Project Part 2
*/

--==================================
-- Function to manage copies_available and handle overdue rentals
--==================================
/*
	-manages copies_available in the movies table on rental and return events.
	-handles overdue rentals by marking them as 'Overdue', 
		charging the user a purchase fee, and updating the rental status.
	-ensures the rental and movie inventory systems stay in sync as rentals are processed, 
		 and it also ensures overdue rentals are appropriately managed and charged.
*/
CREATE OR REPLACE FUNCTION update_copies_available()
RETURNS TRIGGER AS $$
BEGIN
   -- Adjust copies_available when a rental is made (INSERT)
    IF TG_OP = 'INSERT' THEN
        UPDATE movies SET copies_available = copies_available - 1
        WHERE movie_id = NEW.movie_id;

    -- Adjust copies_available when the rental is updated (RETURNED or PURCHASED)
    ELSIF TG_OP = 'UPDATE' THEN

	-- If the rental status is 'Purchased' (item is overdue and considered purchased)
        IF NEW.status = 'Purchased' THEN
            UPDATE movies SET copies_available = copies_available - 1
            WHERE movie_id = NEW.movie_id;
	
        -- If the return_date is not NULL (item is returned)
        ELSIF NEW.return_date IS NOT NULL THEN
            UPDATE movies SET copies_available = copies_available + 1
            WHERE movie_id = NEW.movie_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- DROP TRIGGER STATEMENT
DROP TRIGGER IF EXISTS rental_insert_trigger ON rentals;
DROP TRIGGER IF EXISTS rental_return_purchase_trigger ON rentals;
-- Trigger when item is rented (INSERT)

CREATE TRIGGER rental_insert_trigger
    AFTER INSERT ON rentals
    FOR EACH ROW
    EXECUTE FUNCTION update_copies_available();

-- Trigger when item is returned or purchased (UPDATE)
CREATE TRIGGER rental_return_purchase_trigger
    AFTER UPDATE OF return_date ON rentals
    FOR EACH ROW
    EXECUTE FUNCTION update_copies_available();


--===============================
-- UPDATE INSERT STATEMENT that should trigger update_copies_available()
--===============================
/*
	if the item hasnt been returned after 14 days
*/
-- Alter rentals table to include 'Purchased' as a valid status
ALTER TABLE rentals DROP CONSTRAINT IF EXISTS rentals_status_check;

-- Add a new check constraint with 'Purchased' as a valid status
ALTER TABLE rentals ADD CONSTRAINT rentals_status_check 
	CHECK (status IN ('Rented', 'Returned', 'Overdue', 'Purchased'));

--UPDATING ALREADY INSERTED DATA to rentals and payments
UPDATE rentals
SET status = 'Purchased', return_date = CURRENT_TIMESTAMP
WHERE status = 'Overdue' AND due_date < CURRENT_DATE - INTERVAL '14 days';

INSERT INTO payments (rental_id, transaction_type, amount, payment_type)
	SELECT rental_id, 'Purchase', purchase_fee, 'Credit Card'
	FROM rentals
	JOIN movies ON rentals.movie_id = movies.movie_id
	WHERE due_date < current_date - INTERVAL '14 days';



--===========================================================
-- Function to process unreturned rentals after 14 days and reduce available copies
/*
	-handles overdue rentals by marking them as "purchased" after 14 days.
	-charges the user a purchase_fee for each overdue rental and records the payment.
	-updates the inventory by reducing the number of available copies for the movie, 
		effectively treating the overdue movie as "Purchased."
*/
-- sdding rental_price to rentals table
-- a function will check if rental_price is decided by membership_type or 
--		the base price (movies)
ALTER TABLE rentals ADD COLUMN rental_price DECIMAL(7, 2);

-- Rename rental_fee to membership_rental_fee
ALTER TABLE memberships RENAME COLUMN rental_fee TO membership_rental_fee;

ALTER TABLE memberships
	ADD CONSTRAINT membership_rental_fee_check
	CHECK (membership_rental_fee >= 0);

-- adjusted the memberships table data (pricing)
UPDATE memberships
	SET yearly_fee = 125.00, rental_limit = 8, 
		membership_rental_fee = 0.50, 
		late_fee = 0.10
	WHERE mem_type = 'VIP';

UPDATE memberships
	SET yearly_fee = 60.99, rental_limit = 5,
		late_fee = 0.50
	WHERE mem_type = 'Premium';

UPDATE memberships
	SET yearly_fee = 0, rental_limit = 1
	WHERE mem_type = 'Basic';

--funtion that calculates rental price (membership_rental_fee), checks if the member has a discount
DROP FUNCTION calculate_effective_rental_price(integer,integer);
-- Function to calculate rental price (based on membership or movie price)
CREATE OR REPLACE FUNCTION calculate_effective_rental_price(member_id INT, movie_id_param INT)
RETURNS DECIMAL(7, 2) AS $$
DECLARE
    membership_rental_fee DECIMAL(7, 2);
    movie_rental_price DECIMAL(7, 2);
    member_type VARCHAR(20);
BEGIN
    -- Retrieve the membership type and rental discount
    SELECT m.mem_type, COALESCE(m.membership_rental_fee, 0)
    INTO member_type, membership_rental_fee
    FROM memberships m
    JOIN customers c ON m.membership_id = c.membership_id
    WHERE c.customer_id = member_id;

    -- Retrieve the movie's rental price
    SELECT rental_price INTO movie_rental_price FROM movies WHERE movie_id = movie_id_param;

    -- Apply discount for VIP & Premium members, Basic members pay full price
    RETURN CASE 
        WHEN member_type IN ('VIP', 'Premium') THEN membership_rental_fee
        ELSE movie_rental_price  -- Basic & unknown memberships pay full price
    END;
END;
$$ LANGUAGE plpgsql;


-- Function to set the rental price based on membership discount
CREATE OR REPLACE FUNCTION set_rental_price()
RETURNS TRIGGER AS $$
BEGIN
    -- Set the rental price based on membership discount
    NEW.rental_price := calculate_effective_rental_price(NEW.customer_id, NEW.movie_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop previous trigger if it exists
DROP TRIGGER IF EXISTS rental_price_trigger ON rentals;

-- Trigger to fire before inserting a rental record
CREATE TRIGGER rental_price_trigger
    BEFORE INSERT ON rentals
    FOR EACH ROW
    EXECUTE FUNCTION set_rental_price();



-- Insert statement to trigger calculate_effective_rental_price() 
INSERT INTO rentals (rental_id, customer_id, movie_id, due_date, status)
VALUES 
(31, 5, 3, '2025-02-20', 'Rented'), 
(32, 11, 3, '2025-02-18', 'Rented'), 
(33, 12, 3, '2025-02-19', 'Rented');

--updates all rentals data calculating the the rental_price
UPDATE rentals r
	SET rental_price = calculate_effective_rental_price(r.customer_id, r.movie_id)
	WHERE r.rental_date IS NOT NULL;


---CREATE TABLE for rental_status 
--rental_status into a separate table (Optional, for integrity)
DROP TABLE IF EXISTS rental_status CASCADE;
CREATE TABLE rental_status (
	status_id SERIAL PRIMARY KEY, 
    status VARCHAR(20) NOT NULL CHECK (status IN ('Rented', 'Returned', 'Overdue', 'Purchased'))
);

INSERT INTO rental_status (status_id, status)
VALUES
    (1, 'Rented'),
    (2, 'Returned'),
    (3, 'Overdue'),
    (4, 'Purchased');

-- altering payments table
ALTER TABLE rentals ADD COLUMN status_id SERIAL; 

-- Update rentals table with status_id from rental_status table
UPDATE rentals r
	SET status_id = rs.status_id
	FROM rental_status rs
	WHERE r.status = rs.status;

--add constrains
ALTER TABLE rentals 
    ADD CONSTRAINT fk_rental_status_id
    FOREIGN KEY (status_id) REFERENCES rental_status(status_id) ON DELETE CASCADE;
--since the data has been move/updated, we delete rentals.status
ALTER TABLE rentals DROP COLUMN status;


--=================================
-- Create payment_methods table with the predefined options
DROP TABLE IF EXISTS payment_methods CASCADE;
CREATE TABLE payment_methods (
    method_id SERIAL PRIMARY KEY,
    method_type VARCHAR(50) UNIQUE NOT NULL 
		CHECK (method_type IN ('Credit Card', 'Debit Card', 'Cash', 'Online Payment', 'Store Credit'))
);
INSERT INTO payment_methods (method_id, method_type) VALUES
    (1, 'Credit Card'),
    (2, 'Debit Card'),
    (3, 'Cash'),
    (4, 'Online Payment'),
    (5, 'Store Credit');

-- altering payments table
ALTER TABLE payments ADD COLUMN method_id SERIAL;

-- Update payments table by mapping payment_type to method_id
UPDATE payments p
	SET method_id = pm.method_id
	FROM payment_methods pm
	WHERE p.payment_type = pm.method_type;


--add constrains
ALTER TABLE payments 
    ADD CONSTRAINT fk_payment_method_id
    FOREIGN KEY (method_id) REFERENCES payment_methods(method_id) ON DELETE CASCADE;
--since the data has been move/updated, we delete payments.payment_type
ALTER TABLE payments DROP COLUMN payment_type;


-- Ensure copies_available updates correctly, even if rentals are canceled
ALTER TABLE movies ADD CONSTRAINT copies_available_check CHECK (copies_available >= 0);

--DELETE
--delete old rental records (2 years)
DELETE FROM rentals 
	WHERE return_date IS NOT NULL AND return_date < CURRENT_DATE - INTERVAL '2 year';

--delete customers that hasnt rented for 2 years 
DELETE FROM customers 
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id FROM rentals 
    WHERE rental_date >= CURRENT_DATE - INTERVAL '2 years'
);

--====================================================
---SELECT queries
--list rental transactions and its status (overdue for late items, purchased for unreturned items )
SELECT r.rental_id, 
       r.due_date, 
       r.return_date, 
       m.title AS movie_title,
       CASE 
           WHEN r.return_date IS NULL THEN AGE(current_date, r.due_date)  
           ELSE AGE(r.return_date, r.due_date)  
       END AS rented_duration, 
       rs.status
FROM rental_status rs 
JOIN rentals r ON r.status_id = rs.status_id
JOIN movies m ON r.movie_id = m.movie_id  
ORDER BY r.rental_id;

-- list available copies per each movie
SELECT movie_id, title, copies_available  FROM movies ORDER BY movie_id;

--Showcase Membership Rental Discounts Applied (keep an eye for column membership_discount, movie_rental_fee and rental_price)
--if client has basic membership, they pay movie_rental_fee, while Premium and VIP, pays using membership_discount
SELECT r.rental_id, 
       c.first_name || ' ' || c.last_name AS client_full_name,
       mem.mem_type,
       mem.membership_rental_fee AS membership_discount,
       m.rental_price AS movie_rental_fee,
       r.rental_price,
       AGE(current_date, r.due_date) AS rented_duration, 
       rs.status
FROM rental_status rs 
JOIN rentals r ON r.status_id = rs.status_id
JOIN customers c ON r.customer_id = c.customer_id  
JOIN memberships mem ON c.membership_id = mem.membership_id  
JOIN movies m ON r.movie_id = m.movie_id  
ORDER BY r.rental_id;



--to showcase method payment
SELECT p.payment_id, p.amount, p.payment_date, 
       pm.method_type AS payment_method
	FROM payments p
	JOIN payment_methods pm ON p.method_id = pm.method_id
	ORDER BY p.payment_id;


--retrieves all rental records from the rentals table 
--and their associated rental status from the rental_status table
SELECT  r.rental_id, r.customer_id, 
	r.movie_id,
    r.rental_date, r.due_date, r.return_date, 
	rs.status_id AS rental_status_id,
    rs.status AS rental_status
FROM  rentals r
JOIN  rental_status rs  ON r.status_id = rs.status_id
ORDER BY r.rental_id;