/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT 
product_name || ', ' || COALESCE(product_size, '') || ' (' || COALESCE(product_qty_type, 'unit') || ')'
FROM product;



--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

SELECT 
    customer_id,
    market_date,
    ROW_NUMBER() OVER( PARTITION BY customer_id ORDER BY market_date) AS visit_number
FROM (
    SELECT DISTINCT customer_id, market_date
    FROM customer_purchases
) AS unique_visits
ORDER BY customer_id, visit_number;


/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

SELECT customer_id, market_date
FROM (
    SELECT 
	customer_id,
	market_date,
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY market_date DESC) AS visit_number
    FROM (
        SELECT DISTINCT customer_id, market_date
        FROM customer_purchases
    ) AS unique_visits
) x
WHERE visit_number = 1
ORDER BY customer_id;

/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

SELECT 
	customer_id,
    product_id,
    market_date,
    quantity,
    cost_to_customer_per_qty,
    COUNT(*) OVER(
        PARTITION BY customer_id, product_id
    ) AS purchase_count
FROM customer_purchases
ORDER BY customer_id, product_id, market_date;

-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

SELECT  product_id, product_name,
    CASE 
        WHEN INSTR(product_name, '-') > 0 THEN 
            TRIM(SUBSTR(product_name, INSTR(product_name, '-') + 1))
        ELSE 
            NULL
    END AS description, 
	product_size, product_qty_type
FROM product;

/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

SELECT  product_id, product_name,
    CASE 
        WHEN INSTR(product_name, '-') > 0 THEN 
            TRIM(SUBSTR(product_name, INSTR(product_name, '-') + 1))
        ELSE 
            NULL
    END AS description, 
	product_size, product_qty_type
FROM product
WHERE product_size REGEXP '[0-9]';

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */
-- Answer is in two alternate ways RESULT QUERY 1 and RESULT QUERY 2

-- *** RESULT QUERY 1: ***
DROP VIEW IF EXISTS vendor_daily_sales;
CREATE VIEW IF NOT EXISTS vendor_daily_sales AS
	SELECT md.market_date, market_day, market_year, vendor_name
	,SUM(quantity*cost_to_customer_per_qty) as sales
	FROM market_date_info md
	INNER JOIN customer_purchases cp
		ON md.market_date = cp.market_date
	INNER JOIN vendor v										-- This JOIN is optional in this query 
		ON v.vendor_id = cp.vendor_id
    GROUP BY cp.market_date, v.vendor_id;
	
	-- Execute following query after running the above query (part of RESULT QUERY 1).

WITH daily_sales AS (
    SELECT market_date, SUM(sales) AS total_sales FROM vendor_daily_sales  GROUP BY market_date),
total_sales_days AS (
    SELECT market_date, total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS best_rank,
        RANK() OVER (ORDER BY total_sales ASC) AS worst_rank
    FROM daily_sales)
	
SELECT market_date, total_sales, 'Best Day' AS max_min_sales FROM total_sales_days WHERE best_rank = 1
UNION
SELECT market_date, total_sales, 'Worst Day' AS max_min_sales FROM total_sales_days WHERE worst_rank = 1 
ORDER BY max_min_sales;

-- ***END*** RESULT QUERY 1

-- *** RESULT QUERY 2: *** (You can run whole RESULT QUERY 2 altogether)

DROP VIEW IF EXISTS vendor_daily_sales;
CREATE VIEW IF NOT EXISTS vendor_daily_sales AS
	SELECT md.market_date, market_day, market_year, vendor_name
	,SUM(quantity*cost_to_customer_per_qty) as sales
	FROM market_date_info md
	INNER JOIN customer_purchases cp
		ON md.market_date = cp.market_date
	INNER JOIN vendor v										-- This JOIN is optional in this query 
		ON v.vendor_id = cp.vendor_id
    GROUP BY cp.market_date, v.vendor_id;
	
SELECT market_date, total_sales, 'Best Day' AS max_min_sales 
FROM (
	SELECT market_date, total_sales, 
		RANK() OVER (ORDER BY total_sales DESC) AS best_rank,
        RANK() OVER (ORDER BY total_sales ASC) AS worst_rank
    FROM (
		SELECT market_date, SUM(sales) AS total_sales FROM vendor_daily_sales GROUP BY market_date
	) as daily_sales
) as total_sales_days WHERE best_rank = 1

UNION

SELECT market_date, total_sales, 'Worst Day' AS max_min_sales 
FROM (
	SELECT market_date, total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS best_rank,
        RANK() OVER (ORDER BY total_sales ASC) AS worst_rank
    FROM (
		SELECT market_date, SUM(sales) AS total_sales FROM vendor_daily_sales GROUP BY market_date
	) as daily_sales
) as total_sales_days WHERE worst_rank = 1

ORDER BY max_min_sales;

-- ***END*** RESULT QUERY 2

/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

-- Not sure if we have to calculate the profit as well. We can also calculate profit by uncommenting lines in the following query.

WITH vendor_products AS (
    SELECT 
        v.vendor_id,
        v.vendor_name,
        p.product_id,
        p.product_name,
		--cp.cost_to_customer_per_qty,
        vi.original_price
    FROM vendor_inventory vi
    INNER JOIN vendor v ON vi.vendor_id = v.vendor_id
    INNER JOIN product p ON vi.product_id = p.product_id
	INNER JOIN customer_purchases cp ON vi.vendor_id = cp.vendor_id
),
customers AS (
    SELECT 
        customer_id
    FROM customer
),
expected_sales AS (
    SELECT 
        vp.vendor_id,
        vp.vendor_name,
        vp.product_id,
        vp.product_name,
		--vp.cost_to_customer_per_qty * 5 AS revenue_per_customer,
        vp.original_price * 5 AS cost_per_customer
    FROM vendor_products vp
    CROSS JOIN customers c
)

SELECT 
    vendor_id,
    vendor_name,
    product_name,
    --SUM(revenue_per_customer) AS total_revenue,
	SUM(cost_per_customer) AS total_expected_revenue--,
    --SUM(revenue_per_customer - cost_per_customer) AS total_profit
FROM expected_sales
GROUP BY vendor_id, vendor_name, product_name
ORDER BY vendor_name, product_name;


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

DROP TABLE IF EXISTS product_units;
CREATE TABLE product_units AS
SELECT *, CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit';


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units (product_id, product_name, product_size, product_category_id, product_qty_type, snapshot_timestamp)
VALUES (6666,  'Strawberry Pie', '9 inch', 3, 'unit', CURRENT_TIMESTAMP);

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DELETE FROM product_units WHERE product_id = 6666;

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

ALTER TABLE product_units
ADD COLUMN current_quantity INT;

SELECT product_id, COALESCE(MAX(quantity), 0) AS latest_quantity
FROM vendor_inventory
GROUP BY product_id;

UPDATE product_units
SET current_quantity = (
    SELECT COALESCE(MAX(vi.quantity), 0) FROM vendor_inventory vi
    WHERE vi.product_id = product_units.product_id
)
WHERE EXISTS (
    SELECT 1 FROM vendor_inventory vi
    WHERE vi.product_id = product_units.product_id
);
