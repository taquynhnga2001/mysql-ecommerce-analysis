USE mavenfuzzyfactory;

-- 1. Gsearch seems to be the biggest driver of our business. 
-- Let's check the monthly trends for gsearch sessions and orders to show the growth
SELECT
    DATE_FORMAT(website_sessions.created_at, "%Y-%m") AS month,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE utm_source = "gsearch"
	AND website_sessions.created_at < "2012-11-01"
GROUP BY 1
;

-- 2. Let's check the monthly trends for gsearch sessions and orders to show the growth, breakdown in nonbrand and brand campaigns
SELECT
    DATE_FORMAT(website_sessions.created_at, "%Y-%m") AS month,
    COUNT(DISTINCT CASE WHEN utm_campaign = "nonbrand" THEN website_sessions.website_session_id END) AS nonbrand_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = "nonbrand" THEN orders.order_id END) AS nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_campaign = "brand" THEN website_sessions.website_session_id END) AS brand_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = "brand" THEN orders.order_id END) AS brand_orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE utm_source = "gsearch"
	AND website_sessions.created_at < "2012-11-01"
GROUP BY 1
;

-- 3. dive into nonbrand, show monthly sessions and orders split by device type
SELECT
    DATE_FORMAT(website_sessions.created_at, "%Y-%m") AS month,
    COUNT(DISTINCT CASE WHEN device_type = "desktop" THEN website_sessions.website_session_id END) AS desktop_sessions,
    COUNT(DISTINCT CASE WHEN device_type = "desktop" THEN orders.order_id END) AS desktop_orders,
    COUNT(DISTINCT CASE WHEN device_type = "mobile" THEN website_sessions.website_session_id END) AS mobile_sessions,
    COUNT(DISTINCT CASE WHEN device_type = "mobile" THEN orders.order_id END) AS mobile_orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE utm_source = "gsearch"
	AND utm_campaign = "nonbrand"
	AND website_sessions.created_at < "2012-11-01"
GROUP BY 1
;

-- 4. monthly trends of gsearch and other channels
SELECT DISTINCT 
	utm_source,
    utm_campaign,
    http_referer
FROM website_sessions
WHERE created_at < "2012-11-01";

SELECT
    DATE_FORMAT(website_sessions.created_at, "%Y-%m") AS month,
    COUNT(DISTINCT CASE WHEN utm_source = "gsearch" THEN website_sessions.website_session_id END) AS gsearch_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = "bsearch" THEN website_sessions.website_session_id END) AS bsearch_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id END) AS organic_search_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id END) AS direct_typein_sessions
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < "2012-11-01"
GROUP BY 1
;

-- 5. session to order conversion rate by month
SELECT 
	DATE_FORMAT(website_sessions.created_at, "%Y-%m") AS month,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conversion_rate
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < "2012-11-01"
GROUP BY 1
;

-- 6. estimate the revenue that the A/B test on gsearch lander page earned for us
WITH gsearch_cte AS (
SELECT 
	website_pageviews.pageview_url,
    COUNT(DISTINCT website_sessions.website_session_id) AS total_sessions,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conversion_rate,
    SUM(orders.price_usd) AS total_revenue
FROM website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id = website_pageviews.website_session_id
        AND website_pageviews.pageview_url IN ("/home", "/lander-1")
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at BETWEEN "2012-06-19" AND "2012-07-28"
	AND utm_source = "gsearch"
    AND utm_campaign = "nonbrand"
GROUP BY 1
),
rate_increased AS (
SELECT 
	(SELECT conversion_rate FROM gsearch_cte WHERE pageview_url = "/lander-1") - (SELECT conversion_rate FROM gsearch_cte WHERE pageview_url = "/home") AS conversion_rate_increased,
    (SELECT conversion_rate FROM gsearch_cte WHERE pageview_url = "/lander-1") AS lander_1_conversion_rate,
    (SELECT total_revenue FROM gsearch_cte WHERE pageview_url = "/lander-1") AS lander_1_revenue
)

SELECT lander_1_revenue / lander_1_conversion_rate * conversion_rate_increased AS revenue_earned
FROM rate_increased
;

-- 7. show the full conversion funnel from /home and /lander-1 landing pages to orders of the above A/B test
SELECT 
	landing_page,
    COUNT(DISTINCT website_session_id) AS sessions,
	SUM(to_products) / COUNT(DISTINCT website_session_id) AS lander_ctr,
    SUM(to_mrfuzzy) / SUM(to_products) AS products_ctr,
    SUM(to_cart) / SUM(to_mrfuzzy) AS mrfuzzy_ctr,
    SUM(to_shipping) / SUM(to_cart) AS cart_ctr,
    SUM(to_billing) / SUM(to_shipping) AS shipping_ctr,
    SUM(to_thankyou) / SUM(to_billing) AS billing_ctr
FROM (
	SELECT
		website_sessions.website_session_id,
		pv2.pageview_url AS landing_page,
		MAX(IF(website_pageviews.pageview_url = "/products", 1, 0)) AS to_products,
		MAX(IF(website_pageviews.pageview_url = "/the-original-mr-fuzzy", 1, 0)) AS to_mrfuzzy,
		MAX(IF(website_pageviews.pageview_url = "/cart", 1, 0)) AS to_cart,
		MAX(IF(website_pageviews.pageview_url = "/shipping", 1, 0)) AS to_shipping,
		MAX(IF(website_pageviews.pageview_url = "/billing", 1, 0)) AS to_billing,
		MAX(IF(website_pageviews.pageview_url = "/thank-you-for-your-order", 1, 0)) AS to_thankyou
	FROM website_sessions
		LEFT JOIN website_pageviews
			ON website_sessions.website_session_id = website_pageviews.website_session_id
		LEFT JOIN (
			SELECT 
				pv1.website_session_id,
				MIN(pv1.website_pageview_id) AS min_pv_id
			FROM website_pageviews AS pv1
			GROUP BY 1
		) AS first_pageviews
			ON first_pageviews.website_session_id = website_sessions.website_session_id
		LEFT JOIN website_pageviews pv2
			ON pv2.website_pageview_id = first_pageviews.min_pv_id
	WHERE website_sessions.created_at BETWEEN "2012-06-19" AND "2012-07-28"
		AND utm_source = "gsearch"
		AND utm_campaign = "nonbrand"
	GROUP BY landing_page, website_session_id
) AS session_level_funnel
GROUP BY landing_page
;

-- 8. impact of billing test in terms of revenue per billing page sessions
SELECT
	website_pageviews.pageview_url AS billing_version_seen,
    COUNT(DISTINCT website_pageviews.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_pageviews.website_session_id) AS billing_to_order_rate,
    SUM(orders.price_usd) AS total_revenue,
    SUM(orders.price_usd) / COUNT(DISTINCT website_pageviews.website_session_id) AS revenue_per_billing_page_sessions
FROM website_pageviews
	LEFT JOIN orders
		ON website_pageviews.website_session_id = orders.website_session_id
WHERE website_pageviews.created_at BETWEEN "2012-09-10" AND "2012-11-10"
	AND website_pageviews.pageview_url IN ("/billing", "/billing-2")
GROUP BY website_pageviews.pageview_url;

-- $22.83 revenue per billing session for the old /billing page version
-- $31.34 revenue per billing session for the new /billing-2 page version
-- LIFT: $8.51 per billing session

SELECT
	COUNT(DISTINCT website_pageviews.website_session_id) AS sessions
FROM website_pageviews
WHERE website_pageviews.created_at BETWEEN "2012-10-27" AND "2012-11-27"
	AND pageview_url IN ("/billing", "/billing-2");
    
-- 1,193 blling session last month (2012-10-27 to 2012-11-27)
-- LIFT: $8.51 per billing session
-- VALUE of the Billing Test: $10,160 over the past month