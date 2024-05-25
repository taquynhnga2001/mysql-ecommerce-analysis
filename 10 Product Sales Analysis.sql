USE mavenfuzzyfactory;

-- 1. Monthly trends for sales, revenue and margin until 2013-01-04 
-- this serves as a baseline for future growth, because we had launched only 1 product at that time
SELECT 
	YEAR(created_at) AS yr,
    MONTH(created_at) AS mo,
    COUNT(DISTINCT order_id) AS number_of_orders,
    SUM(price_usd) AS total_revenue,
    SUM(price_usd - cogs_usd) AS total_margin
FROM orders
WHERE created_at < "2013-01-04"
GROUP BY 1, 2
ORDER BY 1, 2;

-- 2. Impact of New product launch until 2013-04-05
-- we launched a second product back on 2013-01-06
-- analyse the monthly trends in order volume, overall conversion rate, revenue per sessionn and breakdown of sales by product
SELECT
	DATE_FORMAT(website_sessions.created_at, "%Y-%m") AS yyyy_mm,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
    SUM(orders.price_usd) / COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session,
    COUNT(DISTINCT IF(order_items.product_id=1, order_items.order_id, NULL)) AS product_one_orders,
    COUNT(DISTINCT IF(order_items.product_id=2, order_items.order_id, NULL)) AS product_two_orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
	LEFT JOIN order_items
		ON orders.order_id = order_items.order_id
WHERE website_sessions.created_at BETWEEN "2012-04-01" AND "2013-04-01"
GROUP BY 1;


-- 3. Product-level Analysis: User path and conversion funnel
-- summarise number of sessions hit the '/products' page and clickthrough rates from '/products' of products since new product launch on 2013-01-06 till 2013-04-06
WITH prod_sessions_w_next_pg AS (
	SELECT
		p1.website_session_id,
		IF(p1.created_at < "2013-01-06", "A. Pre_Product_2", "B. Post_Product_2") AS time_period,
		MIN(p2.website_pageview_id) AS next_pageview
	FROM website_pageviews p1
		LEFT JOIN website_pageviews p2
			ON p1.website_session_id = p2.website_session_id
			AND p1.website_pageview_id < p2.website_pageview_id
	WHERE p1.created_at BETWEEN "2012-10-06" AND "2013-04-06"
		AND p1.pageview_url = '/products' 
	GROUP BY 1, 2
)
SELECT
	time_period,
	COUNT(DISTINCT prod_sessions_w_next_pg.website_session_id) AS sessions,
    COUNT(DISTINCT IF(prod_sessions_w_next_pg.next_pageview IS NOT NULL, prod_sessions_w_next_pg.website_session_id, NULL)) AS sessions_w_next_pg,
    COUNT(DISTINCT IF(prod_sessions_w_next_pg.next_pageview IS NOT NULL, prod_sessions_w_next_pg.website_session_id, NULL)) 
		/ COUNT(DISTINCT prod_sessions_w_next_pg.website_session_id) AS pct_w_next_pg,
    COUNT(DISTINCT IF(website_pageviews.pageview_url = '/the-original-mr-fuzzy', prod_sessions_w_next_pg.website_session_id, NULL)) AS to_mrfuzzy,
    COUNT(DISTINCT IF(website_pageviews.pageview_url = '/the-original-mr-fuzzy', prod_sessions_w_next_pg.website_session_id, NULL))
		/ COUNT(DISTINCT prod_sessions_w_next_pg.website_session_id) AS pct_to_mrfuzzy,
	COUNT(DISTINCT IF(website_pageviews.pageview_url = '/the-forever-love-bear', prod_sessions_w_next_pg.website_session_id, NULL)) AS to_lovebear,
    COUNT(DISTINCT IF(website_pageviews.pageview_url = '/the-forever-love-bear', prod_sessions_w_next_pg.website_session_id, NULL))
		/ COUNT(DISTINCT prod_sessions_w_next_pg.website_session_id) AS pct_to_lovebear
FROM prod_sessions_w_next_pg
	LEFT JOIN website_pageviews
		ON prod_sessions_w_next_pg.next_pageview = website_pageviews.website_pageview_id
GROUP BY 1
;


-- 4. Product Conversion Funnels (from 2013-01-06 to 2013-04-10) of the mrfuzzy and the-forever-love-bear products
DROP TEMPORARY TABLE IF EXISTS session_level_conversion_funnel;
CREATE TEMPORARY TABLE session_level_conversion_funnel
SELECT
    website_session_id,
    product_seen,
    MAX(to_cart) AS to_cart,
    MAX(to_shipping) AS to_shipping,
    MAX(to_billing) AS to_billing,
    MAX(to_thankyou) AS to_thankyou
FROM (
	SELECT
		p1.website_session_id,
		p1.pageview_url AS product_seen,
		p2.pageview_url AS next_pageview,
		IF(p2.pageview_url='/cart', 1, 0) AS to_cart,
		IF(p2.pageview_url='/shipping', 1, 0) AS to_shipping,
		IF(p2.pageview_url='/billing' OR p2.pageview_url='/billing-2', 1, 0) AS to_billing,
		IF(p2.pageview_url='/thank-you-for-your-order', 1, 0) AS to_thankyou
	FROM website_pageviews p1
		LEFT JOIN website_pageviews p2
			ON p1.website_session_id = p2.website_session_id
			AND p1.website_pageview_id < p2.website_pageview_id
	WHERE p1.created_at BETWEEN "2013-01-06" AND "2013-04-10"
		AND p1.pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear')
) AS sub
GROUP BY 1, 2;

-- show sessions volume in conversion funnel
SELECT
	IF(product_seen='/the-original-mr-fuzzy', 'mrfuzzy', 'lovebear') AS product_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    SUM(to_cart) AS to_cart,
    SUM(to_shipping) AS to_shipping,
    SUM(to_billing) AS to_billing,
    SUM(to_thankyou) AS to_thankyou
FROM session_level_conversion_funnel
GROUP BY 1;

-- show clickthrough rate in conversion funnel
SELECT
	IF(product_seen='/the-original-mr-fuzzy', 'mrfuzzy', 'lovebear') AS product_seen,
    SUM(to_cart) / COUNT(DISTINCT website_session_id) AS product_page_click_rate,
    SUM(to_shipping) / SUM(to_cart) AS cart_click_rate,
    SUM(to_billing) / SUM(to_shipping) AS shipping_click_rate,
    SUM(to_thankyou) / SUM(to_billing) AS billing_click_rate
FROM session_level_conversion_funnel
GROUP BY 1;