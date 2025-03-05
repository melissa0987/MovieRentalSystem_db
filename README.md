# MovieRentalSystem_db

#Project Overview
This project is a PostgreSQL-based Movie Rental System designed to manage movies, customers, rentals, returns, late fees, and movie reviews. The database supports CRUD operations and complex queries to facilitate rental transactions and customer interactions.

#Features
Membership Management: Different membership types with rental limits and fees.

Customer Management: Store customer details, memberships, and rental history.

Movie Inventory: Maintain details of available movies, genres, and formats.

Rental & Return Management: Track movie rentals, due dates, returns, and overdue charges.

Payment Processing: Manage transactions for rentals, purchases, and late fees.

Movie Reviews: Allow customers to review and rate movies.

Automated Status Updates: Functions and triggers to handle overdue rentals and charge penalties.


#Database Schema

The system includes the following tables:

memberships - Stores membership plans and rental restrictions.

customers - Stores customer information and membership details.

genres - Categorizes movies into different genres.

movies - Stores details about each movie, including format and rental price.

rentals - Tracks rented movies, due dates, return status, and overdue charges.

payments - Stores payment records for transactions.

movie_reviews - Allows customers to rate and review movies.


#SQL Scripts

Table Creation: Scripts to define the database schema with constraints and relationships.

Sample Data Insertion: Example data for testing functionalities.

Triggers & Functions:

check_overdue_and_charge() - Applies overdue purchase charges.

update_rental_status() - Marks rentals as 'Overdue' after 14 days.

Queries for Functionalities:

CRUD operations (Add, Update, Delete, View records)

Generate reports on rental income, overdue rentals, popular movies, and customer activity.