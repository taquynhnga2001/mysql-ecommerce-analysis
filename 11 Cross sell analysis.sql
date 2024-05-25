USE mavenfuzzyfactory;

-- BACKGROUND:
-- Cross-sell analysis is about understanding which products users are most likely to purchase together and offering smart product recommendations
-- From 2013-09-25, we started giving customers the option to add the 2nd product while on the '/cart' page (cross-selling)

-- 1. Impact of cross-selling on the clickthrough rates from '/cart' page, Avg products per order, Avg order value and revenue per '/cart' page view
SELECT
	time_period,
    COUNT(DISTINCT cart_session_id) AS cart_sessions,
    COUNT(DISTINCT shipping_session_id) AS clickthroughs,
    COUNT(DISTINCT shipping_session_id) / COUNT(DISTINCT cart_session_id) AS cart_ctr,
    SUM(items_purchased) / COUNT(DISTINCT order_session_id) AS products_per_order,
    SUM(price_usd) / COUNT(DISTINCT order_session_id) AS average_order_value,
    SUM(price_usd) / COUNT(DISTINCT cart_session_id) AS revenue_per_cart_session
FROM (
	SELECT
		CASE
			WHEN p1.created_at < "2013-09-25" THEN "A. Pre_Cross_Sell"
			WHEN p1.created_at >= "2013-09-25" THEN "B. Post_Cross_Sell"
			ELSE "other"
		END AS time_period,
		p1.website_session_id AS cart_session_id,
		p2.website_session_id AS shipping_session_id,
		orders.order_id AS order_session_id,
		orders.items_purchased,
		orders.price_usd
	FROM website_pageviews p1
		LEFT JOIN website_pageviews p2
			ON p1.website_session_id = p2.website_session_id
			AND p2.pageview_url = '/shipping'
		LEFT JOIN orders
			ON p2.website_session_id = orders.website_session_id
	WHERE p1.created_at BETWEEN "2013-08-25" AND "2013-10-25"
		AND p1.pageview_url = '/cart'
) AS session_level_conversion_funnel
GROUP BY 1;

-- clickthrough rate from the '/cart' page didn't go down and all other metrics were slightly up since the cross-sell feature was added


-- 2. Portfolio Expansion Analysis
-- we launched a third product the-birthday-bear on 2013-12-12
-- analyse the impact of the new product launch comparing the month before vs the month after
SELECT
	IF(website_sessions.created_at < "2013-12-12", "A. Pre_Birthday_Bear", "B. Post_Birthday_Bear") AS time_period,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_conv_rate,
    SUM(orders.price_usd) AS total_revenue,
    SUM(orders.price_usd) / COUNT(DISTINCT orders.order_id) AS average_order_value,
    SUM(orders.items_purchased) / COUNT(DISTINCT orders.order_id) AS products_per_order,
    SUM(orders.price_usd) / COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at BETWEEN "2013-11-12" AND "2014-01-12"
GROUP BY 1

-- all metrics have improved since we launched the third product

