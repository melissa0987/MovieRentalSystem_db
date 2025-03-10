/*
	Melissa Louise Bangloy  
	Database Project Part 1
*/

-- DROP STATEMENTS
DROP TABLE IF EXISTS memberships CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS genres CASCADE;
DROP TABLE IF EXISTS movies CASCADE;
DROP TABLE IF EXISTS rentals CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS movie_reviews CASCADE;


-- CREATING TABLES 
CREATE TABLE memberships (
    membership_id SERIAL PRIMARY KEY,
    mem_type VARCHAR(50) UNIQUE NOT NULL,
    description TEXT NOT NULL,
    yearly_fee DECIMAL(7,2) NOT NULL CHECK (yearly_fee >= 0),
    rental_fee DECIMAL(7,2) NOT NULL CHECK (rental_fee >= 0),
    rental_limit INT NOT NULL CHECK (rental_limit >= 0),
    late_fee DECIMAL(7,2) CHECK (late_fee >= 0) DEFAULT 0
);

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    membership_id INT DEFAULT 1 REFERENCES memberships(membership_id) ON DELETE SET NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL CHECK (date_of_birth <= CURRENT_DATE - INTERVAL '18 years'),
    address TEXT NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    registered_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT unique_customer UNIQUE (first_name, last_name, date_of_birth)
);

CREATE TABLE genres (
    genre_id SERIAL PRIMARY KEY,
    genre_name VARCHAR(250) UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE movies (
    movie_id SERIAL PRIMARY KEY,
    title VARCHAR(250) NOT NULL,
    genre_id INT REFERENCES genres(genre_id) ON DELETE SET NULL,
    release_date DATE NOT NULL,
    director VARCHAR(150) NOT NULL,
    duration_minutes INT CHECK (duration_minutes > 0) NOT NULL,
    language VARCHAR(50) NOT NULL,
    age_rating VARCHAR(10) CHECK (age_rating IN ('G', 'PG', 'PG-13', 'R', 'NC-17')) NOT NULL,
    copies_available INT CHECK (copies_available >= 0) NOT NULL DEFAULT 0,
    rental_price DECIMAL(7,2) CHECK (rental_price >= 0) NOT NULL DEFAULT 0,
    format VARCHAR(50) CHECK (format IN ('DVD', 'Blu-ray', '4K UHD')) NOT NULL,
    purchase_fee DECIMAL(7,2) CHECK (purchase_fee >= 0) NOT NULL
);

CREATE TABLE rentals (
    rental_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    movie_id INT NOT NULL REFERENCES movies(movie_id) ON DELETE CASCADE,
    rental_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    due_date TIMESTAMP NOT NULL CHECK (due_date > rental_date), 
    return_date TIMESTAMP,
    status VARCHAR(20) CHECK (status IN ('Rented', 'Returned', 'Overdue')) NOT NULL DEFAULT 'Rented'
);

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    rental_id INT NOT NULL REFERENCES rentals(rental_id) ON DELETE CASCADE,
    transaction_type VARCHAR(50) CHECK (
        transaction_type IN ('Membership Registration', 'Membership Renewal', 'Rental', 'Late Fee', 'Purchase', 'Refund', 'Penalty', 'Additional Charges', 'Unreturned Item')
    ) NOT NULL,
    amount DECIMAL(10,2) CHECK (amount > 0) NOT NULL,
    payment_type VARCHAR(50) CHECK (payment_type IN ('Credit Card', 'Debit Card', 'Cash', 'Online Payment', 'Store Credit')),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE movie_reviews (
    review_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    movie_id INT NOT NULL REFERENCES movies(movie_id) ON DELETE CASCADE,
    review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    rating DECIMAL(2,1) CHECK (rating BETWEEN 1 AND 10),
    content TEXT
);


-- Function to check overdue rentals and charge the user if overdue by 14 days
CREATE OR REPLACE FUNCTION check_overdue_and_charge()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the rental is overdue (more than 14 days after due date)
    IF NEW.status = 'Rented' AND NEW.return_date IS NULL AND NEW.due_date < NOW() - INTERVAL '14 days' THEN
        -- Insert a payment for the overdue rental (purchase fee)
        INSERT INTO payments (rental_id, transaction_type, amount, payment_type)
        VALUES (NEW.rental_id, 'Purchase', 
                (SELECT purchase_fee FROM movies WHERE movie_id = NEW.movie_id), 
                'Credit Card');
    END IF;

    -- Return the modified row
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--funtion that updates rentals table if the return date is sill null and over 14 days
CREATE OR REPLACE FUNCTION update_rental_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the rental is overdue (14 days past due date and not returned)
    IF NEW.status = 'Rented' AND NEW.return_date IS NULL AND NEW.due_date < NOW() - INTERVAL '14 days' THEN
        -- Update the status to Overdue
        UPDATE rentals
        SET status = 'Overdue'
        WHERE rental_id = NEW.rental_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Drop old triggers if they exist
DROP TRIGGER IF EXISTS check_overdue_trigger ON rentals;
DROP TRIGGER IF EXISTS rental_status_trigger ON rentals;

-- Trigger to call the check_overdue_and_charge function after an update on the rentals table
CREATE TRIGGER check_overdue_trigger AFTER UPDATE ON rentals
	FOR EACH ROW
	EXECUTE FUNCTION check_overdue_and_charge();

CREATE TRIGGER rental_status_trigger AFTER INSERT OR UPDATE ON rentals
	FOR EACH ROW
	EXECUTE FUNCTION update_rental_status();


--===================
--INSERT STATEMENTS
INSERT INTO memberships (membership_id, mem_type, description, yearly_fee, rental_fee, late_fee, rental_limit) VALUES
(1, 'Basic', 'Basic membership provides access to limited rentals with a small fee per item. Ideal for casual users.', 99.99, 5.00, 1.50, 2), 
(2, 'Premium', 'Premium membership gives access to more rentals and a reduced fee per item. Ideal for frequent users.', 199.99, 3.00, 0.50, 5), 
(3, 'VIP', 'VIP membership includes unlimited rentals with zero late fees. Ideal for frequent renters with flexible limits.', 399.99, 0.00, 0.00, 100);

INSERT INTO customers (customer_id, membership_id, first_name, last_name, date_of_birth, address, email, phone_number) VALUES 
(1, 1, 'John', 'Doe', '1990-05-12', '123 Main St, Springfield', 'john.doe@example.com', '123-456-7890'),
(2, 1, 'Jane', 'Smith', '1985-07-22', '456 Elm St, Shelbyville', 'jane.smith@example.com', '987-654-3210'),
(3, 2, 'Michael', 'Johnson', '2000-03-11', '789 Oak St, Capital City', 'michael.johnson@example.com', '555-123-4567'),
(4, 2, 'Emily', 'Davis', '1993-01-29', '321 Pine St, Springfield', 'emily.davis@example.com', '555-765-4321'),
(5, 1, 'Chris', 'Wilson', '1988-11-04', '654 Cedar St, Shelbyville', 'chris.wilson@example.com', '555-987-6543'),
(6, 1, 'Jessica', 'Brown', '1995-10-20', '987 Birch St, Capital City', 'jessica.brown@example.com', '555-246-8102'),
(7, 1, 'David', 'Lee', '1982-09-13', '135 Maple St, Springfield', 'david.lee@example.com', '555-135-7924'),
(8, 2, 'Sarah', 'Kim', '1997-06-25', '246 Redwood St, Shelbyville', 'sarah.kim@example.com', '555-864-2097'),
(9, 2, 'Brian', 'White', '1999-08-18', '369 Willow St, Capital City', 'brian.white@example.com', '555-753-1596'),
(10, 2, 'Olivia', 'Martinez', '1994-04-09', '258 Chestnut St, Springfield', 'olivia.martinez@example.com', '555-468-1357'),
(11, 3, 'Jack', 'Taylor', '1985-12-01', '101 Beach Ave, Miami', 'jack.taylor@example.com', '305-123-7890'), 
(12, 3, 'Isabella', 'Harris', '1992-09-30', '202 Ocean Blvd, Miami', 'isabella.harris@example.com', '305-456-1234'),  
(13, 3, 'Thomas', 'Garcia', '1975-04-25', '505 Park Ave, New York', 'thomas.garcia@example.com', '212-555-4433'),  
(14, 2, 'Charlotte', 'Miller', '1991-11-15', '123 Broadway, New York', 'charlotte.miller@example.com', '212-555-8765'), 
(15, 1, 'Aiden', 'Wilson', '1996-03-19', '456 Lexington Ave, New York', 'aiden.wilson@example.com', '212-555-1122');  

INSERT INTO genres (genre_id, genre_name, description) VALUES 
(1, 'Action', 'Movies with high-energy scenes, including intense physical action, chase sequences, and combat. Popular among adventure fans.'),
(2, 'Comedy', 'Movies that use humor and satire to entertain and amuse the audience. Often lighthearted and designed to create laughter.'),
(3, 'Drama', 'Movies focusing on realistic storytelling with strong character development and emotional depth. Popular for those who enjoy heartfelt narratives.'),
(4, 'Horror', 'Movies designed to evoke fear, suspense, and shock, often through supernatural or psychological themes. Great for thrill-seekers.'),
(5, 'Sci-Fi', 'Movies based on speculative science, futuristic technology, and often set in outer space or dystopian settings. Ideal for science fiction enthusiasts.'),
(6, 'Fantasy', 'Movies featuring magical elements, fantastical creatures, and imaginary worlds. Typically set in a fictional universe.'),
(7, 'Romance', 'Movies that center around romantic relationships, focusing on emotional connections and love stories.'),
(8, 'Thriller', 'Movies filled with suspense and excitement, keeping the audience on the edge of their seats. Often involves mystery, danger, and tension.'),
(9, 'Documentary', 'Movies that provide factual information, exploring real-life events, people, or topics. Informative and educational content.'),
(10, 'Animation', 'Movies created using animation techniques, either 2D or 3D, often targeting both children and adult audiences with creative storytelling.'),
(11, 'Mystery', 'Movies focused on solving a puzzle, often involving detectives or unexpected twists. Popular for fans of suspense and problem-solving.'),
(12, 'Adventure', 'Movies that involve exploration, journeys, and thrilling quests, often combined with action.'),
(13, 'Crime', 'Movies that revolve around criminal activity, law enforcement, and the investigation of illegal acts.'),
(14, 'Family', 'Movies suitable for all ages, often with light-hearted and wholesome themes for children and adults to enjoy together.'),
(15, 'Musical', 'Movies that integrate songs and dances into the storyline, often featuring large-scale performances. Perfect for musical enthusiasts.');

INSERT INTO movies (movie_id, title, genre_id, release_date, director, duration_minutes, language, age_rating, copies_available, rental_price, format, purchase_fee) VALUES 
(1, 'Avengers: Endgame', 1, '2019-04-26', 'Anthony Russo, Joe Russo', 181, 'English', 'PG-13', 10, 5.99, 'Blu-ray', 29.99),
(2, 'The Hangover', 2, '2009-06-05', 'Todd Phillips', 100, 'English', 'R', 8, 3.99, 'DVD', 14.99),
(3, 'The Shawshank Redemption', 3, '1994-09-22', 'Frank Darabont', 142, 'English', 'R', 5, 4.99, 'Blu-ray', 19.99),
(4, 'The Conjuring', 4, '2013-07-19', 'James Wan', 112, 'English', 'R', 4, 4.49, 'DVD', 12.99),
(5, 'Inception', 5, '2010-07-16', 'Christopher Nolan', 148, 'English', 'PG-13', 7, 5.49, 'Blu-ray', 21.99),
(6, 'Harry Potter and the Sorcerers Stone', 6, '2001-11-11', 'Chris Columbus', 152, 'English', 'PG', 6, 5.99, 'Blu-ray', 22.99),
(7, 'Titanic', 7, '1997-12-19', 'James Cameron', 195, 'English', 'PG-13', 9, 4.49, 'DVD', 18.99),
(8, 'The Dark Knight', 8, '2008-07-18', 'Christopher Nolan', 152, 'English', 'PG-13', 10, 6.99, '4K UHD', 29.99),
(9, 'Won’t You Be My Neighbor?', 9, '2018-06-08', 'Morgan Neville', 94, 'English', 'PG-13', 3, 3.99, 'DVD', 9.99),
(10, 'Toy Story', 10, '1995-11-22', 'John Lasseter', 81, 'English', 'G', 15, 4.99, 'Blu-ray', 14.99),
(11, 'The Matrix', 5, '1999-03-31', 'The Wachowskis', 136, 'English', 'R', 10, 3.99, 'DVD', 16.99),
(12, 'Jurassic Park', 5, '1993-06-11', 'Steven Spielberg', 127, 'English', 'PG-13', 8, 4.49, 'Blu-ray', 17.99),
(13, 'The Godfather', 3, '1972-03-24', 'Francis Ford Coppola', 175, 'English', 'R', 5, 4.99, 'DVD', 24.99),
(14, 'Pulp Fiction', 3, '1994-10-14', 'Quentin Tarantino', 154, 'English', 'R', 7, 5.49, 'Blu-ray', 21.99),
(15, 'The Lord of the Rings: The Fellowship of the Ring', 6, '2001-12-19', 'Peter Jackson', 178, 'English', 'PG-13', 9, 5.99, 'Blu-ray', 25.99),
(16, 'Star Wars: Episode IV - A New Hope', 5, '1977-05-25', 'George Lucas', 121, 'English', 'PG', 10, 7.49, '4K UHD', 34.99),
(17, 'Frozen', 10, '2013-11-27', 'Chris Buck, Jennifer Lee', 102, 'English', 'PG', 12, 3.99, 'DVD', 14.99),
(18, 'The Lion King', 10, '1994-06-15', 'Roger Allers, Rob Minkoff', 88, 'English', 'G', 6, 4.49, 'Blu-ray', 17.99),
(19, 'The Terminator', 5, '1984-10-26', 'James Cameron', 107, 'English', 'R', 5, 4.99, 'Blu-ray', 16.99),
(20, 'Guardians of the Galaxy', 1, '2014-08-01', 'James Gunn', 121, 'English', 'PG-13', 8, 5.99, 'Blu-ray', 19.99),
(21, 'Forrest Gump', 3, '1994-07-06', 'Robert Zemeckis', 142, 'English', 'PG-13', 4, 4.49, 'DVD', 16.99),
(22, 'The Silence of the Lambs', 4, '1991-02-14', 'Jonathan Demme', 118, 'English', 'R', 3, 3.99, 'DVD', 14.99),
(23, 'Black Panther', 1, '2018-02-16', 'Ryan Coogler', 134, 'English', 'PG-13', 7, 6.49, 'Blu-ray', 24.99),
(24, 'Spider-Man: No Way Home', 1, '2021-12-17', 'Jon Watts', 148, 'English', 'PG-13', 10, 7.49, '4K UHD', 39.99),
(25, 'Shrek', 10, '2001-04-22', 'Andrew Adamson, Vicky Jenson', 90, 'English', 'PG', 8, 3.99, 'DVD', 13.99),
(26, 'Deadpool', 1, '2016-02-12', 'Tim Miller', 108, 'English', 'R', 9, 5.49, 'Blu-ray', 22.99),
(27, 'The Incredibles', 10, '2004-11-05', 'Brad Bird', 115, 'English', 'PG', 10, 4.99, 'Blu-ray', 18.99),
(28, 'Zootopia', 10, '2016-03-17', 'Byron Howard, Rich Moore', 108, 'English', 'PG', 7, 4.49, 'DVD', 16.99),
(29, 'Mad Max: Fury Road', 5, '2015-05-15', 'George Miller', 120, 'English', 'R', 6, 7.49, '4K UHD', 29.99),
(30, 'Interstellar', 5, '2014-11-07', 'Christopher Nolan', 169, 'English', 'PG-13', 8, 5.49, 'Blu-ray', 24.99),
(31, 'Dune', 5, '2021-10-22', 'Denis Villeneuve', 155, 'English', 'PG-13', 10, 8.49, '4K UHD', 39.99),
(32, 'Spider-Man: Into the Spider-Verse', 10, '2018-12-14', 'Bob Persichetti, Peter Ramsey, Rodney Rothman', 117, 'English', 'PG', 12, 5.99, 'Blu-ray', 29.99);

INSERT INTO rentals (rental_id, customer_id, movie_id, rental_date, due_date, return_date, status) VALUES 
(1, 1, 1, '2025-01-01 10:00:00', '2025-01-02 10:00:00', NULL, 'Rented'),
(2, 1, 2, '2025-01-02 12:00:00', '2025-01-06 12:00:00', '2025-01-07 12:00:00', 'Returned'),
(3, 2, 2, '2025-01-03 14:00:00', '2025-01-07 14:00:00', '2025-01-08 14:00:00', 'Returned'),
(4, 2, 3, '2025-01-04 16:00:00', '2025-01-08 16:00:00', '2025-01-10 16:00:00', 'Returned'),
(5, 3, 1, '2025-01-05 18:00:00', '2025-01-09 18:00:00', NULL, 'Rented'),
(6, 5, 5, '2025-01-06 20:00:00', '2025-01-10 20:00:00', '2025-01-11 20:00:00', 'Returned'),
(7, 5, 9, '2025-01-07 22:00:00', '2025-01-11 22:00:00', NULL, 'Rented'),
(8, 8, 10, '2025-01-08 11:00:00', '2025-01-12 11:00:00', '2025-01-13 11:00:00', 'Returned'),
(9, 2, 3, '2025-01-09 13:00:00', '2025-01-13 13:00:00', NULL, 'Rented'),
(10, 4, 7, '2025-01-10 15:00:00', '2025-01-11 15:00:00', NULL, 'Rented'),
(11, 9, 8, '2025-01-10 15:00:00', '2025-01-14 15:00:00', '2025-01-15 15:00:00', 'Returned'),
(12, 9, 5, '2025-01-10 15:00:00', '2025-01-12 15:00:00', '2025-01-12 15:00:00', 'Returned'),
(13, 6, 2, '2025-01-10 15:00:00', '2025-01-14 15:00:00', '2025-01-14 15:00:00', 'Returned'),
(14, 4, 2, '2025-01-10 15:00:00', '2025-01-12 15:00:00', '2025-01-12 15:00:00', 'Returned'),
(15, 8, 2, '2025-01-10 15:00:00', '2025-01-14 15:00:00', '2025-01-15 15:00:00', 'Returned'),
(16, 10, 4, '2025-01-11 08:00:00', '2025-01-15 08:00:00', NULL, 'Rented'),
(17, 10, 6, '2025-01-12 14:30:00', '2025-01-16 14:30:00', NULL, 'Rented'),
(18, 9, 7, '2025-01-13 16:00:00', '2025-01-17 16:00:00', NULL, 'Rented'),
(19, 9, 10, '2025-01-14 10:00:00', '2025-01-18 10:00:00', NULL, 'Rented'),
(20, 3, 8, '2025-01-15 18:30:00', '2025-01-19 18:30:00', NULL, 'Rented'),
(21, 2, 3, '2025-01-16 12:00:00', '2025-01-20 12:00:00', NULL, 'Rented'),
(22, 1, 2, '2025-01-17 13:00:00', '2025-01-21 13:00:00', NULL, 'Rented'),
(23, 1, 1, '2025-01-18 14:00:00', '2025-01-22 14:00:00', NULL, 'Rented'),
(24, 6, 9, '2025-01-19 15:00:00', '2025-01-23 15:00:00', NULL, 'Rented'),
(25, 6, 4, '2025-01-20 16:30:00', '2025-01-24 16:30:00', NULL, 'Rented'),
(26, 8, 6, '2025-01-21 17:00:00', '2025-01-25 17:00:00', NULL, 'Rented'),
(27, 9, 8, '2025-01-22 19:00:00', '2025-01-26 19:00:00', NULL, 'Rented'),
(28, 7, 7, '2025-01-23 21:00:00', '2025-01-27 21:00:00', NULL, 'Rented'),
(29, 10, 10, '2025-01-24 22:00:00', '2025-01-28 22:00:00', NULL, 'Rented'),
(30, 10, 5, '2025-01-25 23:00:00', '2025-01-29 23:00:00', NULL, 'Rented');

INSERT INTO payments (rental_id, transaction_type, amount, payment_type) VALUES
(1, 'Rental', 3.99, 'Credit Card'), 
(2, 'Rental', 3.99, 'Debit Card'),
(3, 'Rental', 3.99, 'Cash'),
(4, 'Rental', 3.99, 'Cash'),
(5, 'Rental', 3.99, 'Credit Card'),
(6, 'Rental', 4.49, 'Debit Card'),
(7, 'Rental', 4.49, 'Cash'),
(8, 'Rental', 3.99, 'Credit Card'),
(9, 'Rental', 3.99, 'Credit Card'),
(10, 'Rental', 3.99, 'Debit Card'),
(11, 'Rental', 3.99, 'Credit Card'),
(12, 'Rental', 4.49, 'Debit Card'),
(13, 'Rental', 4.49, 'Credit Card'),
(14, 'Rental', 3.99, 'Cash'),
(15, 'Rental', 3.99, 'Debit Card'),
(16, 'Rental', 3.99, 'Credit Card'),
(17, 'Rental', 4.49, 'Cash'),
(18, 'Late Fee', 2.50, 'Credit Card'),
(19, 'Rental', 3.99, 'Debit Card'),
(20, 'Rental', 4.49, 'Online Payment'),
(21, 'Rental', 4.49, 'Credit Card'),
(22, 'Late Fee', 3.00, 'Cash'),
(23, 'Rental', 3.99, 'Debit Card'),
(24, 'Rental', 3.99, 'Online Payment'),
(25, 'Membership Renewal', 45.00, 'Store Credit'),
(26, 'Unreturned Item', 15.00, 'Credit Card'),
(27, 'Rental', 3.99, 'Credit Card'),
(28, 'Rental', 3.99, 'Debit Card'),
(29, 'Late Fee', 3.50, 'Credit Card'),
(30, 'Rental', 4.49, 'Cash');

INSERT INTO movie_reviews (review_id, customer_id, movie_id, review_date, rating, content) VALUES
(1, 1, 1, '2025-01-01 10:00:00', 8.0, 'Great action-packed movie!'),
(2, 2, 2, '2025-01-02 12:00:00', 7.5, 'A funny and entertaining film.'),
(3, 3, 3, '2025-01-03 14:00:00', 9.0, 'One of the best dramas I have ever watched.'),
(4, 4, 4, '2025-01-04 16:00:00', 6.5, 'Scary but predictable.'),
(5, 5, 5, '2025-01-05 18:00:00', 8.5, 'A must-see for sci-fi lovers!'),
(6, 6, 6, '2025-01-06 20:00:00', 9.5, 'An incredible magical journey!'),
(7, 7, 7, '2025-01-07 22:00:00', 7.0, 'Heartwarming romance but a bit slow.'),
(8, 8, 8, '2025-01-08 11:00:00', 8.0, 'Full of suspense, a real thriller!'),
(9, 9, 9, '2025-01-09 13:00:00', 8.5, 'An emotional and touching documentary.'),
(10, 10, 10, '2025-01-10 15:00:00', 7.0, 'A fun family movie, but a little outdated.');


--QUESTIONS
--1. DELETE VIP membership from memberships table
--2. Add a new customer
--3. UPDATE a customer's information with customer_id 4
--4. DELETE customer with customer_id 10
--5. View all available movies in a specific genre (genre_name = Action)
--6. List all customers full name who rented the movie 'The Hangover'
--7. Update movie Shrek's rental price
--8. Delete a movie (Dune) from the inventory
--9. Update a movie review with review_id = 5
--10. Add a new movie review
--11. Generate a report of total rental income 
--12. Generate a report of overdue rentals (rented but not returned within due date)
--13. Get the average rating for all movie, order by movie_id
--14. Check and list all movies with low availability (less than 5 copies available):
--15. Calculate the total income generated from all movies
--16. Generate a report of the most rented movies (top 5)
--17. Calculate total income from all rentals for a particular membership type
--18. Generate a list of customers who have overdue rentals and have not paid their late fees.
--19. Update a customer's membership type and fee for a specific membership_id.
--20 List the movies that have received a rating of 8 or higher from customers.
