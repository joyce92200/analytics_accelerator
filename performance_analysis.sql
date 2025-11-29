-- Marketing Analytics: Client Segmentation & Performance Analysis
-- Purpose: Analyze project profitability, user costs, and channel performance

-- ============================================================================
-- 1. PROJECT COST ANALYSIS
-- Calculate average monthly cost per project and identify high-burn projects
-- ============================================================================

WITH monthly_project_costs AS (
    SELECT
        project_id,
        DATE_TRUNC('month', cost_date) AS month_start,
        SUM(cost_amount) AS monthly_cost_total
    FROM costs
    WHERE cost_amount > 0  -- Exclude invalid/zero costs
    GROUP BY project_id, DATE_TRUNC('month', cost_date)
),

project_avg_costs AS (
    SELECT
        project_id,
        AVG(monthly_cost_total) AS avg_cost_per_project,
        COUNT(DISTINCT month_start) AS months_active,
        SUM(monthly_cost_total) AS total_project_cost
    FROM monthly_project_costs
    GROUP BY project_id
),

-- ============================================================================
-- 2. CLIENT SEGMENTATION
-- Categorize clients by tier (Free, Basic, Premium) and calculate costs
-- ============================================================================

client_segmentation AS (
    SELECT
        client_id,
        tier,
        project_id,
        DATE_TRUNC('month', cost_date) AS month_start,
        SUM(cost_amount) AS monthly_cost
    FROM costs c
    JOIN clients cl ON c.client_id = cl.id
    WHERE cost_amount > 0
    GROUP BY client_id, tier, project_id, DATE_TRUNC('month', cost_date)
),

-- ============================================================================
-- 3. USER COST ANALYSIS
-- Calculate average monthly cost per user across all projects
-- ============================================================================

user_monthly_costs AS (
    SELECT
        user_id,
        DATE_TRUNC('month', cost_date) AS month_start,
        SUM(cost_amount) AS monthly_user_cost
    FROM user_costs
    WHERE cost_amount > 0
    GROUP BY user_id, DATE_TRUNC('month', cost_date)
),

user_avg_costs AS (
    SELECT
        user_id,
        AVG(monthly_user_cost) AS avg_cost_per_user,
        COUNT(DISTINCT month_start) AS active_months,
        SUM(monthly_user_cost) AS total_user_cost
    FROM user_monthly_costs
    GROUP BY user_id
),

-- ============================================================================
-- 4. BONUS COUPON DISTRIBUTION
-- Analyze coupon usage by month and deliver_month
-- ============================================================================

coupon_analysis AS (
    SELECT
        DATE_TRUNC('month', order_date) AS order_month,
        deliver_month,
        COUNT(DISTINCT user_id) AS unique_users,
        COUNT(*) AS total_orders
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date), deliver_month
    ORDER BY order_month, deliver_month
),

-- ============================================================================
-- 5. REGISTRATION PERFORMANCE
-- Track user registrations by month and calculate growth metrics
-- ============================================================================

registration_stats AS (
    SELECT
        DATE_TRUNC('month', reg_date) AS reg_month,
        COUNT(DISTINCT user_id) AS new_registrations,
        COUNT(DISTINCT user_id) * 100.0 / SUM(COUNT(DISTINCT user_id)) OVER () AS pct_of_total
    FROM orders
    GROUP BY DATE_TRUNC('month', reg_date)
    ORDER BY reg_month
),

-- ============================================================================
-- 6. CHANNEL PERFORMANCE & EVENTS
-- Identify active marketing channels and forecast future traffic
-- ============================================================================

channel_events AS (
    SELECT
        DATE_TRUNC('day', occurred_at) AS event_day,
        channel,
        COUNT(*) AS event_count,
        COUNT(DISTINCT user_id) AS unique_users
    FROM events
    WHERE channel IS NOT NULL
    GROUP BY DATE_TRUNC('day', occurred_at), channel
    ORDER BY event_day DESC, event_count DESC
)

-- ============================================================================
-- MAIN OUTPUT: Combined Analytics Dashboard
-- ============================================================================

SELECT
    'Project Costs' AS metric_category,
    project_id AS dimension_id,
    avg_cost_per_project AS metric_value,
    months_active AS supporting_metric
FROM project_avg_costs

UNION ALL

SELECT
    'User Costs' AS metric_category,
    user_id AS dimension_id,
    avg_cost_per_user AS metric_value,
    active_months AS supporting_metric
FROM user_avg_costs

UNION ALL

SELECT
    'Registrations' AS metric_category,
    reg_month::TEXT AS dimension_id,
    new_registrations AS metric_value,
    pct_of_total AS supporting_metric
FROM registration_stats

ORDER BY metric_category, metric_value DESC;

-- ============================================================================
-- ADDITIONAL QUERIES FOR SPECIFIC INSIGHTS
-- ============================================================================

-- High-value clients analysis (uncomment to use)
/*
SELECT
    client_id,
    tier,
    COUNT(DISTINCT project_id) AS project_count,
    SUM(monthly_cost) AS total_spend,
    AVG(monthly_cost) AS avg_monthly_spend
FROM client_segmentation
GROUP BY client_id, tier
HAVING SUM(monthly_cost) > 10000
ORDER BY total_spend DESC;
*/

-- Channel ROI analysis (uncomment to use)
/*
SELECT
    channel,
    SUM(event_count) AS total_events,
    COUNT(DISTINCT event_day) AS active_days,
    AVG(unique_users) AS avg_daily_users
FROM channel_events
WHERE event_day >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY channel
ORDER BY total_events DESC;
*/
