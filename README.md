# Movie Rental Database System

## Overview
This project is a SQL-based movie rental system designed to manage memberships, rentals, and movie inventory. The system ensures proper handling of rental transactions, membership benefits, and overdue penalties.

## Features
- Tracks available copies of movies.
- Manages memberships with rental limits and discounts.
- Implements rental and return processes with proper updates.
- Applies overdue charges based on rental policies.
- Uses triggers and scheduled jobs for automation.

---

## Part 1: Database Design & Initial Implementation
### Requirements
- **Design and normalize** the database to ensure efficiency.
- **Create tables** with appropriate constraints (PK, FK, indexes).
- **Implement triggers** to handle automatic updates, such as `copies_available` when a movie is rented or returned.
- **Ensure data consistency** using constraints and relationships.

### What was done:
- Designed the schema to support movies, rentals, and memberships.
- Implemented triggers to manage rental transactions.
- Created sample data for testing.
- Defined relationships and constraints to maintain integrity.

---

## Part 2: Enhancements & Operations
### Requirements
- Provide **5 DDL** statements for improvements or fixes.
- Implement **12 SQL operations:**
  - 2 CREATE statements
  - 5 READ statements
  - 3 UPDATE statements
  - 2 DELETE statements
- Ensure `copies_available` updates correctly on rentals/returns.
- Modify membership structure:
  - Rename `rental_fee` to `membership_rental_discount`.
  - Basic membership has no yearly fee and a 1-rental limit.
- Replace `update_rental_status` trigger with a scheduled job for overdue rentals.
- Define how overdue charges apply (`purchase_fee` or `late_fee`).
- Prepare a **10-minute presentation** explaining the system.
- Submit `Project-part2-StudentNo.pdf` by Feb 9, 2025.

### What was done:
- Adjusted table structures and relationships based on Part 1 feedback.
- Replaced the `update_rental_status` trigger with a scheduled job.
- Ensured proper updates to `copies_available` on rentals and returns.
- Implemented all required SQL operations.
- Clarified the application of overdue charges.
- Created a presentation detailing system design and functionalities.

---

## How the Code Works
1. **Membership Management:**
   - Users can sign up for different membership levels.
   - Membership benefits (rental discounts, limits) are enforced.

2. **Movie Rentals:**
   - Users rent movies, reducing `copies_available`.
   - Returns update `copies_available` accordingly.

3. **Automated Overdue Handling:**
   - A scheduled job checks for overdue rentals daily.
   - Overdue charges are applied based on `late_fee`.

4. **SQL Operations Implemented:**
	- **CREATE:** New members and rental records.
	- **READ:** Retrieve movie availability, rental history, and customer records.
	- **UPDATE:** Modify membership details and rental statuses.
	- **DELETE:** Remove inactive members or expired rental records.

---
## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments
- This project was developed as part of a course assignment. All coding techniques and algorithms were implemented independently.
- Special thanks to the course instructors for their guidance throughout the development process.

## Author
Melissa :) <br>
Course: [Database] <br>
Date: January 2025