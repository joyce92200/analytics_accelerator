-- IF you want to :
	-- 1. tell which project burns money fast
    -- 2. design client segmentation(Free, Basic, Premium)
	-- 3. know the monthly active user(MAU)
	-- 4. evaluate monthly performance by registration count per month
    -- 5. see which marketing channels are actually working, detect dying channels, and forecast future traffic
-- THEN use average cost CTE
	-- First CTE: organize all costs by month
	-- Second CTE: calculate one clean number(average)

-- examples
	-- 1. tell which project burns money fast: average monthly cost per project 
WITH monthly_project_costs AS (
  SELECT
    project_id,
    DATE_TRUNC('month', cost_date)::date AS month_start,
    SUM(cost_amount) AS monthly_cost -- not AVG(cost_amount) because AVG(cost_amount) averages rows(January 500 rows, October 2 rows), not by months.
  FROM costs
  GROUP BY project_id, month_start  -- group by month and please also include project names and THEN will average the monthly totals separately
)

SELECT
  project_id,
  AVG(monthly_cost) AS avg_cost_per_project
FROM monthly_project_costs  -- please include temporary table(previous CTE) name here
GROUP BY project_id
ORDER BY avg_cost_per_project DESC;

  -- 2. design client segmentation(Free, Basic, Premium). If our system costs €20/user to operate(resolving tickets, support calls, etc), but we only charge €10/user, we’re losing money every single month.
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

  -- 3. know the monthly active user(MAU) : bonus coupon distribution
SELECT
  DATE_TRUNC('month', order_date) :: DATE AS delivr_month,  -- Truncate the order date to the nearest month
  COUNT(DISTINCT user_id) AS mau -- Count the unique user IDs
FROM orders
GROUP BY delivr_month
ORDER BY delivr_month ASC; -- Order by month

  -- 4. evaluate monthly performance by registration count per month
WITH reg_dates AS (
  SELECT
    user_id,
    MIN(order_date) AS reg_date
  FROM orders
  GROUP BY user_id)

SELECT
  DATE_TRUNC('month', reg_date) :: DATE AS delivr_month,
  COUNT(DISTINCT user_id) AS regs -- Count the unique user IDs by registration month
FROM reg_dates
GROUP BY delivr_month
ORDER BY delivr_month ASC; 

-- 5. to see which marketing channels are actually working and detect dying channels and forecast future traffic
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
