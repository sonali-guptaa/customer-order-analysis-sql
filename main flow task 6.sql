create database main_task6;
use main_task6;

-- creating three tables to peform the task:

-- customers – stores customer details
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    registration_date DATE
);

-- products – stores product details
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10, 2)
);

-- orders – stores order details, linking customers and products
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    order_date DATE,
    quantity INT,
    total_amount DECIMAL(10, 2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Inserting Sample Data for analysis
-- Insert customers
INSERT INTO customers (customer_id, first_name, last_name, email, registration_date)
VALUES 
(1, 'Alice', 'Johnson', 'alice@example.com', '2023-01-15'),
(2, 'Bob', 'Smith', 'bob@example.com', '2023-02-10'),
(3, 'Charlie', 'Brown', 'charlie@example.com', '2023-03-05'),
(4, 'David', 'Williams', 'david@example.com', '2023-04-20'),
(5, 'Eve', 'Davis', 'eve@example.com', '2023-05-25');

-- Insert products
INSERT INTO products (product_id, product_name, category, price)
VALUES 
(1, 'Laptop', 'Electronics', 800.00),
(2, 'Smartphone', 'Electronics', 500.00),
(3, 'Headphones', 'Accessories', 100.00),
(4, 'Office Chair', 'Furniture', 150.00),
(5, 'Backpack', 'Accessories', 50.00);

-- Insert orders
INSERT INTO orders (order_id, customer_id, product_id, order_date, quantity, total_amount)
VALUES 
(1, 1, 1, '2023-06-01', 1, 800.00),
(2, 2, 2, '2023-06-02', 2, 1000.00),
(3, 3, 3, '2023-06-03', 1, 100.00),
(4, 1, 5, '2023-06-05', 3, 150.00),
(5, 4, 4, '2023-06-07', 2, 300.00),
(6, 5, 1, '2023-06-10', 1, 800.00),
(7, 3, 2, '2023-06-12', 1, 500.00),
(8, 2, 3, '2023-06-14', 2, 200.00);


-- Data Exploration
-- View structure of tables
DESCRIBE customers;


DESCRIBE products;


DESCRIBE orders;

-- Count the number of records in each table:
SELECT 'customers' AS table_name, COUNT(*) AS record_count FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders;

-- Preview sample data:
SELECT * FROM customers LIMIT 5;


SELECT * FROM products LIMIT 5;


SELECT * FROM orders LIMIT 5;

-- Data Extraction

-- 1. Get the total number of orders:
SELECT COUNT(*) AS total_orders FROM orders;

-- 2. Calculate the average order value:
SELECT 
    AVG(total_amount) AS avg_order_value 
FROM orders;

-- 3. Find the top 3 best-selling products:
SELECT 
    p.product_name, 
    SUM(o.quantity) AS total_sold
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_sold DESC
LIMIT 3;

-- Data Analysis
-- 1. Find the most frequently purchased product:
SELECT 
    p.product_name, 
    COUNT(o.order_id) AS purchase_count
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.product_name
ORDER BY purchase_count DESC
LIMIT 1;

-- 2. Analyze peak order times (daily trends):
SELECT 
    DAYNAME(order_date) AS order_day, 
    COUNT(*) AS order_count
FROM orders
GROUP BY order_day
ORDER BY order_count DESC;

-- 3. Find the customers who have made the most purchases:
SELECT 
    c.first_name, 
    c.last_name, 
    COUNT(o.order_id) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id
ORDER BY total_orders DESC
LIMIT 5;

-- Reporting
-- 1. Generate a summary of key insights:
SELECT 
    (SELECT COUNT(*) FROM customers) AS total_customers,
    (SELECT COUNT(*) FROM orders) AS total_orders,
    (SELECT AVG(total_amount) FROM orders) AS avg_order_value,
    (SELECT product_name FROM products WHERE product_id = 
        (SELECT product_id FROM orders GROUP BY product_id ORDER BY COUNT(*) DESC LIMIT 1)
    ) AS top_product;
    
-- 2. Monthly order trends:
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month, 
    COUNT(*) AS order_count
FROM orders
GROUP BY month
ORDER BY month;

-- Cohort analysis helps in tracking customer behavior over time by grouping them based on their first purchase (or registration) date and observing their repeat orders in subsequent months.
-- Prepare the Data for Cohort Analysis
-- Creating a cohort based on the customer's registration month and track how many customers return in the following months.

WITH customer_first_order AS (
    SELECT 
        customer_id, 
        MIN(order_date) AS first_order_date
    FROM orders
    GROUP BY customer_id
), cohort_data AS (
    SELECT 
        c.customer_id,
        DATE_FORMAT(f.first_order_date, '%Y-%m') AS cohort_month, 
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month
    FROM orders o
    JOIN customer_first_order f ON o.customer_id = f.customer_id
    JOIN customers c ON o.customer_id = c.customer_id
)
SELECT 
    cohort_month,
    order_month,
    COUNT(DISTINCT customer_id) AS customer_count
FROM cohort_data
GROUP BY cohort_month, order_month
ORDER BY cohort_month, order_month;

-- Calculating the retention rate by finding the percentage of customers retained in each subsequent month.
WITH cohort_counts AS (
    SELECT 
        DATE_FORMAT(f.first_order_date, '%Y-%m') AS cohort_month,
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
        COUNT(DISTINCT o.customer_id) AS customer_count
    FROM orders o
    JOIN (SELECT customer_id, MIN(order_date) AS first_order_date FROM orders GROUP BY customer_id) f
    ON o.customer_id = f.customer_id
    GROUP BY cohort_month, order_month
), cohort_size AS (
    SELECT 
        cohort_month, 
        SUM(customer_count) AS cohort_size 
    FROM cohort_counts 
    GROUP BY cohort_month
)
SELECT 
    c.cohort_month, 
    c.order_month, 
    c.customer_count,
    ROUND(100.0 * c.customer_count / s.cohort_size, 2) AS retention_rate
FROM cohort_counts c
JOIN cohort_size s ON c.cohort_month = s.cohort_month
ORDER BY c.cohort_month, c.order_month;