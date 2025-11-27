-- First CTE: organize all costs by month
-- Second CTE: calculate one clean number(average)

-- average monthly cost per project(CTE only) : This tells you which project burns money fast.
WITH monthly_project_costs AS (
  SELECT
    project_id,
    DATE_TRUNC('month', cost_date)::date AS month_start,
    SUM(cost_amount) AS monthly_cost -- not AVG(cost_amount) because AVG(cost_amount) averages rows(January 500 rows, October 2 rows), not months.
  FROM costs
  GROUP BY project_id, month_start  -- group by month and project names FIRST and THEN average the monthly totals next separately
)

SELECT
  project_id,
  AVG(monthly_cost) AS avg_cost_per_project
FROM monthly_project_costs
GROUP BY project_id
ORDER BY avg_cost_per_project DESC;

-- average cost per user(CTE only) : client segmentation(Free, Basic, VIP). If our system costs €20/user to operate(resolving tickets, support calls, etc), but we only charge €10/user, we’re losing money every single month.

WITH monthly_user_costs AS (
  SELECT
    user_id,
    DATE_TRUNC('month', cost_date)::date AS month_start,
    SUM(cost_amount) AS monthly_cost
  FROM user_costs
  GROUP BY user_id, month_start
)

SELECT
  user_id,
  AVG(monthly_cost) AS avg_cost_per_user
FROM monthly_user_costs
GROUP BY user_id
ORDER BY avg_cost_per_user DESC;

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

-- registration counts per month
WITH reg_dates AS (
  SELECT
    user_id,
    MIN(order_date) AS reg_date
  FROM orders
  GROUP BY user_id)

SELECT
  DATE_TRUNC('month', reg_date) :: DATE AS delivr_month,
  COUNT(DISTINCT user_id) AS regs
FROM reg_dates
GROUP BY delivr_month
ORDER BY delivr_month ASC; 

-- Count the unique user IDs by registration month
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

-- profit per month (revenue - cost)
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

-- average monthly cost before September
-- step 1: declare a CTE named monthly_cost
WITH monthly_cost AS (
  SELECT
    DATE_TRUNC('month', stocking_date)::DATE AS delivr_month,
    SUM(meal_cost * stocked_quantity) AS cost
  FROM meals
  JOIN stock ON meals.meal_id = stock.meal_id
  GROUP BY delivr_month)
--step 2: calculate the average monthly cost before September
SELECT
  AVG(cost)
FROM monthly_cost
WHERE monthly_cost.delivr_month < '2018-09-01' -- here please don't forget double single quote to indicate a date. 
