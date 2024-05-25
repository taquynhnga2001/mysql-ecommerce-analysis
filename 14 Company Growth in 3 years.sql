USE mavenfuzzyfactory;

-- 1. Volume growth by sessions, orders
SELECT
	YEAR(website_sessions.created_at) AS year,
    QUARTER(website_sessions.created_at) AS quarter,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < "2015-01-01"
GROUP BY 1, 2
ORDER BY 1, 2
;

-- 2. Efficiency improvement in session-to-order conversion rate, revenue per order and revenue per session
SELECT
	YEAR(website_sessions.created_at) AS year,
    QUARTER(website_sessions.created_at) AS quarter,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
    SUM(orders.price_usd) / COUNT(DISTINCT orders.order_id) AS revenue_per_order,
    SUM(orders.price_usd) / COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < "2015-01-01"
GROUP BY 1, 2
ORDER BY 1, 2
;
-- the conversion rate, revenue per order and revenue per session all increased as we launched new products

-- 3. Growth in user aquisition channels
SELECT
	YEAR(website_sessions.created_at) AS year,
	QUARTER(website_sessions.created_at) AS quarter,
    COUNT(DISTINCT IF(utm_source="gsearch" AND utm_campaign="nonbrand", orders.order_id, NULL)) AS gsearch_nonbrand_orders,
    COUNT(DISTINCT IF(utm_source="bsearch" AND utm_campaign="nonbrand", orders.order_id, NULL)) AS bsearch_nonbrand_orders,
    COUNT(DISTINCT IF(utm_campaign="brand", orders.order_id, NULL)) AS brand_search_orders,
    COUNT(DISTINCT IF(utm_campaign IS NULL AND http_referer IS NOT NULL, orders.order_id, NULL)) AS organic_search_orders,
    COUNT(DISTINCT IF(utm_campaign IS NULL AND http_referer IS NULL, orders.order_id, NULL)) AS direct_typein_orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < "2015-01-01"
GROUP BY 1, 2
ORDER BY 1, 2
;
-- the business become much less dependent on gsearch paid nonbrand campaign and started to build its own brand, organic and direct type-in traffic
-- which has better margin and less dependent on search engine

-- 4. Session-to-order conversion rate trends of the channels
SELECT
	YEAR(website_sessions.created_at) AS year,
	QUARTER(website_sessions.created_at) AS quarter,
    COUNT(DISTINCT IF(utm_source="gsearch" AND utm_campaign="nonbrand", orders.order_id, NULL)) 
		/ COUNT(DISTINCT IF(utm_source="gsearch" AND utm_campaign="nonbrand", website_sessions.website_session_id, NULL)) AS gsearch_nonbrand_conv_rate,
    COUNT(DISTINCT IF(utm_source="bsearch" AND utm_campaign="nonbrand", orders.order_id, NULL))
		/ COUNT(DISTINCT IF(utm_source="bsearch" AND utm_campaign="nonbrand", website_sessions.website_session_id, NULL)) AS bsearch_nonbrand_conv_rate,
    COUNT(DISTINCT IF(utm_campaign="brand", orders.order_id, NULL))
		/ COUNT(DISTINCT IF(utm_campaign="brand", website_sessions.website_session_id, NULL)) AS brand_search_conv_rate,
    COUNT(DISTINCT IF(utm_campaign IS NULL AND http_referer IS NOT NULL, orders.order_id, NULL))
		/ COUNT(DISTINCT IF(utm_campaign IS NULL AND http_referer IS NOT NULL, website_sessions.website_session_id, NULL)) AS organic_search_conv_rate,
    COUNT(DISTINCT IF(utm_campaign IS NULL AND http_referer IS NULL, orders.order_id, NULL)) 
		/ COUNT(DISTINCT IF(utm_campaign IS NULL AND http_referer IS NULL, website_sessions.website_session_id, NULL)) AS direct_typein_conv_rate
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < "2015-01-01"
GROUP BY 1, 2
ORDER BY 1, 2
;
-- all of the session-to-order conversion rate improved

-- 5. Monthly trend of revenue and margin by product, total sales and total revenue
SELECT
	YEAR(orders.created_at) AS year,
	MONTH(orders.created_at) AS month,
    SUM(IF(order_items.product_id=1, order_items.price_usd, NULL)) AS product_1_revenue,
    SUM(IF(order_items.product_id=1, order_items.price_usd - order_items.cogs_usd, NULL)) AS product_1_margin,
    SUM(IF(order_items.product_id=2, order_items.price_usd, NULL)) AS product_1_revenue,
    SUM(IF(order_items.product_id=2, order_items.price_usd - order_items.cogs_usd, NULL)) AS product_2_margin,
    SUM(IF(order_items.product_id=3, order_items.price_usd, NULL)) AS product_1_revenue,
    SUM(IF(order_items.product_id=3, order_items.price_usd - order_items.cogs_usd, NULL)) AS product_3_margin,
    SUM(IF(order_items.product_id=4, order_items.price_usd, NULL)) AS product_1_revenue,
    SUM(IF(order_items.product_id=4, order_items.price_usd - order_items.cogs_usd, NULL)) AS product_4_margin
FROM orders
	LEFT JOIN order_items
		ON orders.order_id = order_items.order_id
WHERE orders.created_at < "2015-03-01"
GROUP BY 1, 2
ORDER BY 1, 2
;
-- product 1's sales increase in holiday months (Nov and Dec)
-- product 2's sales increase in Feb (Valentine's Day)

-- 6. Impact of introducting new products in conversion from /products page
WITH from_product_pg_to_another AS (
SELECT
	product_pageviews_w_next_pv_id.website_session_id,
    product_pageviews_w_next_pv_id.created_at,
    product_pageviews_w_next_pv_id.next_pageview_id,
    orders.order_id
FROM (
	SELECT
		pv1.website_session_id,
		pv1.created_at,
		pv1.pageview_url,
		MIN(pv2.website_pageview_id) AS next_pageview_id
	FROM website_pageviews pv1
		LEFT JOIN website_pageviews pv2
			ON pv1.website_session_id = pv2.website_session_id
			AND pv1.website_pageview_id < pv2.website_pageview_id
	WHERE pv1.pageview_url = "/products"
	GROUP BY 1, 2
    ) AS product_pageviews_w_next_pv_id
    
	LEFT JOIN orders
		ON product_pageviews_w_next_pv_id.website_session_id = orders.website_session_id
)
SELECT 
	YEAR(created_at) AS yr,
    MONTH(created_at) AS mo,
    COUNT(DISTINCT website_session_id) AS sessions_to_product_page,
    COUNT(DISTINCT next_pageview_id) AS clickthrough_another_page,
    COUNT(DISTINCT next_pageview_id) / COUNT(DISTINCT website_session_id) AS clickthrough_rate,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id) AS conv_rate_to_orders
FROM from_product_pg_to_another
GROUP BY 1, 2
ORDER BY 1, 2
;
-- clickthrough rate and conversion rate improve through months

-- 7. The 4th product available as a primary product on 2014-12-05 (which was previously cross-sell item only)
-- How well each product cross-sells from one another since then
SELECT
	orders.primary_product_id,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN orders.order_id END) / COUNT(DISTINCT orders.order_id) AS product_1_sales_pct,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN orders.order_id END) / COUNT(DISTINCT orders.order_id) AS product_2_sales_pct,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN orders.order_id END) / COUNT(DISTINCT orders.order_id) AS product_3_sales_pct,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN orders.order_id END) / COUNT(DISTINCT orders.order_id) AS product_4_sales_pct
FROM orders
	LEFT JOIN order_items
		ON orders.order_id = order_items.order_id
WHERE orders.created_at > "2014-12-05"
GROUP BY 1
;
-- product 4 cross-sells from all other products at a high rates ~20-22%
-- product 1 and 3 cross-sells well from each others (9-12%)

