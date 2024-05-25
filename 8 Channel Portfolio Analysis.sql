USE mavenfuzzyfactory;

-- 1. Marketing Channel Portfolio trends 
SELECT
	MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT IF(utm_source="gsearch", website_session_id, NULL)) AS gsearch_sessions,
	COUNT(DISTINCT IF(utm_source="bsearch", website_session_id, NULL)) AS bsearch_sessions
FROM website_sessions
WHERE created_at BETWEEN "2012-08-22" AND "2012-11-29"
	AND utm_campaign = "nonbrand"
GROUP BY YEARWEEK(created_at);

-- bsearch tends to get roughly one third the traffic of gsearch


-- 2. Traffic coming from mobile devices
SELECT
	utm_source,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT IF(device_type="mobile", website_session_id, NULL)) AS mobile_sessions,
    COUNT(DISTINCT IF(device_type="mobile", website_session_id, NULL)) / COUNT(DISTINCT website_session_id) AS pct_mobile
FROM website_sessions
WHERE created_at BETWEEN "2012-08-22" AND "2012-11-30"
	AND utm_campaign = "nonbrand"
GROUP BY utm_source;

-- desktop to mobile splits are quite different in these channels
-- we need to dig in conversion rate by channels and device type to decide if we should bid bsearch and gsearch the same


-- 3. Nonbrand conversion rate of channels and device type
SELECT
	device_type,
    utm_source,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at BETWEEN "2012-08-22" AND "2012-09-19"
	AND utm_campaign = "nonbrand"
GROUP BY 1, 2;

--  bsearch has lower session-to-order conversion rate. we should bid down bsearch based on its under-performance

-- we have bid down bsearch nonbrand from 2012-12-02
-- 4. Impact of Bid Changes
SELECT
	MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT IF(utm_source="gsearch" AND device_type="desktop", website_session_id, NULL)) AS gsearch_desktop_sessions,
    COUNT(DISTINCT IF(utm_source="bsearch" AND device_type="desktop", website_session_id, NULL)) AS bsearch_desktop_sessions,
	COUNT(DISTINCT IF(utm_source="bsearch" AND device_type="desktop", website_session_id, NULL)) 
		/ COUNT(DISTINCT IF(utm_source="gsearch" AND device_type="desktop", website_session_id, NULL)) AS b_pct_of_g_desktop_sessions,
    COUNT(DISTINCT IF(utm_source="gsearch" AND device_type="mobile", website_session_id, NULL)) AS gsearch_mobile_sessions,
    COUNT(DISTINCT IF(utm_source="bsearch" AND device_type="mobile", website_session_id, NULL)) AS bsearch_mobile_sessions,
	COUNT(DISTINCT IF(utm_source="bsearch" AND device_type="mobile", website_session_id, NULL)) 
		/ COUNT(DISTINCT IF(utm_source="gsearch" AND device_type="mobile", website_session_id, NULL)) AS b_pct_of_g_mobile_sessions
FROM website_sessions
WHERE created_at BETWEEN "2012-11-04" AND "2012-12-22"
	AND utm_campaign = "nonbrand"
GROUP BY YEARWEEK(created_at);

-- bsearch traffic dropped off a bit after the bid downn. gsearch was down also after Black Friday and Cyber Monday but bsearch dropped even more


-- 5. traffic volume breakdown
SELECT
	DATE_FORMAT(created_at, "%Y-%m") AS yyyy_mm,
    COUNT(DISTINCT IF(utm_campaign="nonbrand", website_session_id, NULL)) AS nonbrand,
    COUNT(DISTINCT IF(utm_campaign="brand", website_session_id, NULL)) AS brand,
    COUNT(DISTINCT IF(utm_campaign="brand", website_session_id, NULL)) 
		/ COUNT(DISTINCT IF(utm_campaign="nonbrand", website_session_id, NULL)) AS brand_pct_of_nonbrand,
    COUNT(DISTINCT IF(utm_source IS NULL AND http_referer IS NULL, website_session_id, NULL)) AS direct,
    COUNT(DISTINCT IF(utm_source IS NULL AND http_referer IS NULL, website_session_id, NULL)) 
		/ COUNT(DISTINCT IF(utm_campaign="nonbrand", website_session_id, NULL)) AS direct_pct_of_nonbrand,
    COUNT(DISTINCT IF(utm_source IS NULL AND http_referer IS NOT NULL, website_session_id, NULL)) AS organic,
    COUNT(DISTINCT IF(utm_source IS NULL AND http_referer IS NOT NULL, website_session_id, NULL)) 
		/ COUNT(DISTINCT IF(utm_campaign="nonbrand", website_session_id, NULL)) AS organic_pct_of_nonbrand
FROM website_sessions
WHERE created_at < "2012-12-23"
GROUP BY 1;

-- all brand, direct and organic traffic volumes are growing