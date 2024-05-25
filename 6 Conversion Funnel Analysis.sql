USE mavenfuzzyfactory;

-- BACKGROUND:
--   we would like to understand where we lose our gsearch visitors between the new /lander-1 page and placing an order
--   we are analyzing the conversion funnel to see how many customers make it to each step (from 2012-08-05 to 2012-09-05)
--   start from /lander-1 page to /thank-you page 

DROP TEMPORARY TABLE IF EXISTS gsearch_lander_1_pageviews;
CREATE TEMPORARY TABLE gsearch_lander_1_pageviews
SELECT
	website_pageviews.website_session_id,
    website_pageviews.website_pageview_id,
    website_pageviews.created_at,
    website_pageviews.pageview_url
FROM website_pageviews
	LEFT JOIN website_sessions
		ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE website_pageviews.created_at BETWEEN "2012-08-05" AND "2012-09-05"
	AND utm_source = "gsearch"
    AND utm_campaign = "nonbrand"
    AND website_pageviews.website_session_id IN (
		SELECT DISTINCT pv.website_session_id
        FROM website_pageviews pv
        WHERE pv.pageview_url = "/lander-1"
    )
;

-- build conversion funnel table
DROP TEMPORARY TABLE IF EXISTS session_level_with_steps;
CREATE TEMPORARY TABLE session_level_with_steps
SELECT
	website_session_id,
    MAX(to_products) AS to_products,
    MAX(to_mrfuzzy) AS to_mrfuzzy,
    MAX(to_cart) AS to_cart,
    MAX(to_shipping) AS to_shipping,
    MAX(to_billing) AS to_billing,
    MAX(to_thankyou) AS to_thankyou
FROM (
	SELECT 
		website_session_id,
		pageview_url,
		IF(pageview_url = "/products", 1, 0) AS to_products,
		IF(pageview_url = "/the-original-mr-fuzzy", 1, 0) AS to_mrfuzzy,
		IF(pageview_url = "/cart", 1, 0) AS to_cart,
		IF(pageview_url = "/shipping", 1, 0) AS to_shipping,
		IF(pageview_url = "/billing", 1, 0) AS to_billing,
		IF(pageview_url = "/thank-you-for-your-order", 1, 0) AS to_thankyou
	FROM gsearch_lander_1_pageviews
	WHERE pageview_url IN ("/lander-1", "/products", "/the-original-mr-fuzzy", "/cart", "/shipping", "/billing", "/thank-you-for-your-order")
) AS pageview_level
GROUP BY website_session_id;

-- conversion volumne
SELECT 
	COUNT(DISTINCT website_session_id) AS sessions,
    SUM(to_products) AS to_products,
    SUM(to_mrfuzzy) AS to_mrfuzzy,
    SUM(to_cart) AS to_cart,
    SUM(to_shipping) AS to_shipping,
    SUM(to_billing) AS to_billing,
    SUM(to_thankyou) AS to_thankyou
FROM session_level_with_steps;

-- conversion clickthrough rate
SELECT
	SUM(to_products) / COUNT(DISTINCT website_session_id) AS lander_ctr,
    SUM(to_mrfuzzy) / SUM(to_products) AS products_ctr,
    SUM(to_cart) / SUM(to_mrfuzzy) AS mrfuzzy_ctr,
    SUM(to_shipping) / SUM(to_cart) AS cart_ctr,
    SUM(to_billing) / SUM(to_shipping) AS shipping_ctr,
    SUM(to_thankyou) / SUM(to_billing) AS billing_ctr
FROM session_level_with_steps;


-- looks like we need to focus on the landing page, Mr.fuzzy page and the billing page, those have the lowest click rates
-- an A/B test on 2 version of billing page was ran between "/billing" and "/billing-2"

-- the first running date of the A/B test is 2012-09-10
SELECT
    MIN(website_pageview_id) AS first_billing_2_pageview_id,
    MIN(created_at) AS start_date_billing_2
FROM website_pageviews
WHERE pageview_url = "/billing-2";

SELECT
	website_pageviews.pageview_url AS billing_version_seen,
    COUNT(DISTINCT website_pageviews.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_pageviews.website_session_id) AS billing_to_order_rate
FROM website_pageviews
	LEFT JOIN orders
		ON website_pageviews.website_session_id = orders.website_session_id
WHERE website_pageviews.created_at BETWEEN "2012-09-10" AND "2012-11-10"
	AND website_pageviews.pageview_url IN ("/billing", "/billing-2")
GROUP BY website_pageviews.pageview_url;

