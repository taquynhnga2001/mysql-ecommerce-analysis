USE mavenfuzzyfactory;

-- 1. Monthly volume pattern in 2012
SELECT
	DATE_FORMAT(website_sessions.created_at, "%Y-%m") AS month,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < "2013-01-01"
GROUP BY 1;

-- the traffic volume grew fairly steady all year 2012
-- significant volume around the holiday months (Nov and Dec)


-- 2. Weekly volume pattern in 2012
SELECT
	MIN(DATE(website_sessions.created_at)) AS week_start_date,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < "2013-01-01"
GROUP BY YEARWEEK(website_sessions.created_at);

-- significant volume around the holiday months especially the weeks of Black Friday and Cyber Monday


-- 3. Data for Customer Service
-- we are considering adding live chat support to improve customer experience
-- we want to analyse average website session volume by hour of day and day of the week (from Sep 15 to Nov 15)
SELECT
	hour,
    ROUND(AVG(IF(weekday=0, sessions, NULL)), 1) AS mon,
	ROUND(AVG(IF(weekday=1, sessions, NULL)), 1) AS tue,
	ROUND(AVG(IF(weekday=2, sessions, NULL)), 1) AS wed,
	ROUND(AVG(IF(weekday=3, sessions, NULL)), 1) AS thu,
	ROUND(AVG(IF(weekday=4, sessions, NULL)), 1) AS fri,
	ROUND(AVG(IF(weekday=5, sessions, NULL)), 1) AS sat,
	ROUND(AVG(IF(weekday=6, sessions, NULL)), 1) AS sun

FROM (
	SELECT
		DATE(created_at) AS date,
		HOUR(created_at) AS hour,
		WEEKDAY(created_at) AS weekday,
		COUNT(website_session_id) AS sessions
	FROM website_sessions
	WHERE created_at BETWEEN "2012-09-15" AND "2012-11-15"
	GROUP BY 
		1, 2, 3
	) AS daily_session_volume
GROUP BY hour
ORDER BY hour
