USE mavenfuzzyfactory;

-- 1. session to order conversion rate by utm_content
SELECT 
	w.utm_content,
    COUNT(DISTINCT w.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) / COUNT(DISTINCT w.website_session_id) AS session_to_order_conv_rt
FROM website_sessions w
LEFT JOIN orders o
	ON o.website_session_id = w.website_session_id
WHERE w.website_session_id BETWEEN 1000 AND 2000
GROUP BY w.utm_content
ORDER BY sessions DESC;

-- 2. the UTM source, campaign and referring domain that the bulk of website sessions came from (before 12/4/2012)
SELECT
	utm_source,
    utm_campaign,
    http_referer,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at < "2012-04-12"
GROUP BY
	utm_source,
    utm_campaign,
    http_referer
ORDER BY sessions DESC;

-- 3. gsearch nonbrand drives the most sessions. Let's check its conversion rate from sessions to orders.
-- overal gsearch nonbrand conversion rate is only 2.88%. Let's check the conversion rate by device type: 
SELECT
	COUNT(DISTINCT w.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) / COUNT(DISTINCT w.website_session_id) AS session_to_order_conv_rt
FROM website_sessions AS w
LEFT JOIN orders AS o
	ON w.website_session_id = o.website_session_id
WHERE
	w.created_at < "2012-04-14"
    AND utm_source = "gsearch"
    AND utm_campaign = "nonbrand"
GROUP BY device_type;

-- 4. from 2012-04-15, we bid down the gsearch nonbrand due to its relatively low conversion rate
-- let's see the trending of session volume by week of gsearch nonbrand before and after
SELECT
    MIN(DATE(created_at)) as week_start_date,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE 
	created_at < "2012-05-12"
    AND utm_source = "gsearch"
    AND utm_campaign = "nonbrand"
GROUP BY 
	YEAR(created_at),
	WEEK(created_at);
    
-- 5. conversion rates from session to order by device type
SELECT
	device_type,
    COUNT(DISTINCT w.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) / COUNT(DISTINCT w.website_session_id) AS session_to_order_conv_rate
FROM website_sessions w
LEFT JOIN orders o
	ON w.website_session_id = o.website_session_id
WHERE w.created_at < "2012-05-11"
	AND utm_source = "gsearch"
    AND utm_campaign = "nonbrand"
GROUP BY device_type;

-- 6. gsearch nonbrand desktop campaigns was bid up on 2012-05-19
-- let's look at the trending of session volume by week of desktop and mobile before and after
SELECT
	MIN(DATE(w.created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN device_type = "desktop" THEN w.website_session_id ELSE NULL END) AS dtop_sessions,
    COUNT(DISTINCT CASE WHEN device_type = "mobile" THEN w.website_session_id ELSE NULL END) AS mob_sessions
FROM website_sessions w
WHERE
	w.created_at BETWEEN "2012-04-15" AND "2012-06-09"
    AND utm_source = "gsearch"
    AND utm_campaign = "nonbrand"
GROUP BY WEEK(w.created_at)
ORDER BY 1;

    