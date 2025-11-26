--CHAPTER 3 : JOIN
--3.11.1. Provide a table for all web_events associated with account name of Walmart. There should be three columns. Be sure to include the primary_poc, time of the event, and the channel for each event. Additionally, you might choose to add a fourth column to assure only Walmart events were chosen.
SELECT name, primary_poc, occurred_at, channel FROM web_events
JOIN accounts 
  ON web_events.id = accounts.id
WHERE accounts.name = 'Walmart';

-- 3.11.1 solution
SELECT a.primary_poc, w.occurred_at, w.channel, a.name
FROM web_events w
JOIN accounts a
ON w.account_id = a.id
WHERE a.name = 'Walmart';

--3.11.2. Provide a table that provides the region for each sales_rep along with their associated accounts. Your final table should include three columns: the region name, the sales rep name, and the account name. Sort the accounts alphabetically (A-Z) according to account name. 
SELECT region.name, sales_reps.name, accounts.name
FROM region
JOIN sales_reps 
  ON region.id = sales_reps.region_id
JOIN accounts 
  ON sales_reps.region_id = accounts.sales_rep_id;
ORDER BY account.name ASC

  --3.11.2 solution
SELECT r.name region, s.name rep, a.name account
FROM sales_reps s
JOIN region r
ON s.region_id = r.id
JOIN accounts a
ON a.sales_rep_id = s.id
ORDER BY a.name; 

--3.11.3. Provide the name for each region for every order, as well as the account name and the unit price they paid (total_amt_usd/total) for the order. Your final table should have 3 columns: region name, account name, and unit price. A few accounts have 0 for total, so I divided by (total + 0.01) to assure not dividing by zero.
SELECT region.name, 
accounts.name,
orders.total_amt_usd/(orders.total+0.01) AS unit_price
FROM region
JOIN sales_reps ON sales_reps.id = region.id
JOIN accounts ON sales_reps.id = accounts.sales_rep_id
JOIN orders ON accounts.id = orders.account_id;

--3.11.3 solution
SELECT r.name region, a.name account, 
       o.total_amt_usd/(o.total + 0.01) unit_price
FROM region r
JOIN sales_reps s
ON s.region_id = r.id
JOIN accounts a
ON a.sales_rep_id = s.id
JOIN orders o
ON o.account_id = a.id;

--CHAPTER 4 : AGGREGATION, total costs
SELECT SUM(meal_cost * stocked_quantity) AS total_cost 
FROM meals
JOIN stock
 ON meals.meal_id = stock.meal_id;
--4.27.1 DATE PART/TRUNC/ DOW - calculate the costs by month
SELECT
  -- Calculate cost
  DATE_TRUNC('month', stocking_date)::DATE AS delivr_month,
  -- :: DATE means "convert this value to DATE type. Don't forget the single qquotation"
  SUM(meal_cost * stocked_quantity) AS cost
FROM meals
JOIN stock ON meals.meal_id = stock.meal_id
GROUP BY delivr_month
ORDER BY delivr_month ASC;

--declare a CTE named monthly_cost
-- Declare a CTE named monthly_cost
WITH monthly_cost AS (
  SELECT
    DATE_TRUNC('month', stocking_date)::DATE AS delivr_month,
    SUM(meal_cost * stocked_quantity) AS cost
  FROM meals
  JOIN stock ON meals.meal_id = stock.meal_id
  GROUP BY delivr_month)

SELECT
  -- Calculate the average monthly cost before September
  AVG(cost)
FROM monthly_cost
WHERE monthly_cost.delivr_month < '2018-09-01';
-- here please don't forget double single quote to indicate a date. 

-- calculating profit 
WITH revenue AS (
  -- Calculate revenue per eatery
  SELECT eatery,
         SUM(meal_price * order_quantity) AS revenue
    FROM meals
    JOIN orders ON meals.meal_id = orders.meal_id
   GROUP BY eatery),

  cost AS (
  -- Calculate cost per eatery
  SELECT eatery,
         SUM(meal_cost * stocked_quantity) AS cost
    FROM meals
    JOIN stock ON meals.meal_id = stock.meal_id
   GROUP BY eatery)

   -- Calculate profit per eatery
   SELECT revenue.eatery,
          SUM(revenue - cost) AS profit
     FROM revenue
     JOIN cost ON revenue.eatery = cost.eatery
    GROUP BY revenue.eatery 
    ORDER BY profit DESC;

-- profit per month
-- Set up the revenue CTE
WITH revenue AS ( 
	SELECT
		DATE_TRUNC('month', order_date) :: DATE AS delivr_month,
		SUM(meal_price * order_quantity) AS revenue
	FROM meals
	JOIN orders ON meals.meal_id = orders.meal_id
	GROUP BY delivr_month),
-- Set up the cost CTE
  cost AS (
 	SELECT
		DATE_TRUNC('month', stocking_date) :: DATE AS delivr_month,
		SUM(meal_cost * stocked_quantity) AS cost
	FROM meals
    JOIN stock ON meals.meal_id = stock.meal_id
	GROUP BY delivr_month)
-- Calculate profit by joining the CTEs
SELECT
	revenue.delivr_month,
	SUM(revenue - cost) AS profit
FROM revenue 
JOIN cost ON revenue.delivr_month = cost.delivr_month
GROUP BY revenue.delivr_month
ORDER BY revenue.delivr_month ASC;

--4.31.1 CASE WHEN THEN END AS/ WHEN THEN / ELSE END AS 
--- registratio counts per month
WITH reg_dates AS (
  SELECT
    user_id,
    MIN(order_date) AS reg_date
  FROM orders
  GROUP BY user_id)

SELECT
  -- Count the unique user IDs by registration month
  DATE_TRUNC('month', reg_date) :: DATE AS delivr_month,
  COUNT(DISTINCT user_id) AS regs
FROM reg_dates
GROUP BY delivr_month
ORDER BY delivr_month ASC; 


WITH events AS (
  SELECT DATE_TRUNC('day', occurred_at) AS day,
          channel, 
          COUNT(*) AS events
  FROM web_events
  GROUP BY day, channel) 

SELECT channel, AVG(events) AS average_events
FROM events
GROUP BY channel
ORDER BY average_events DESC ;

-- monthly active users(MAU)
SELECT
  -- Truncate the order date to the nearest month
  DATE_TRUNC('month', order_date) :: DATE AS delivr_month,
  -- Count the unique user IDs
  COUNT(DISTINCT user_id) AS mau
FROM orders
GROUP BY delivr_month
-- Order by month
ORDER BY delivr_month ASC;

