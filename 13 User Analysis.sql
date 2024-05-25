USE mavenfuzzyfactory;

-- 1. How many of our website visitors come back for another session
SELECT
	repeat_sessions,
    COUNT(DISTINCT user_id) AS users
FROM (
	SELECT 
		new_users_sessions.user_id,
		COUNT(DISTINCT website_sessions.website_session_id) AS repeat_sessions
	FROM (
		SELECT
			user_id,
			website_session_id AS first_session_id
		FROM website_sessions
		WHERE created_at BETWEEN "2014-01-01" AND "2014-11-01"
			AND is_repeat_session = 0
		) AS new_users_sessions
		
		LEFT JOIN website_sessions
			ON new_users_sessions.user_id = website_sessions.user_id
			AND new_users_sessions.first_session_id < website_sessions.website_session_id
            AND website_sessions.created_at BETWEEN "2014-01-01" AND "2014-11-01"
	GROUP BY 1
) AS users_w_repeat_sessions
GROUP BY 1;

-- a fair number of our customers do come back to our site after their first session


-- 2. Minimum, maximum and average time between the first and second session for customers who do come back
WITH first_two_sessions_w_dates AS (
SELECT 
	first_and_second_sessions.*,
    website_sessions.created_at AS second_session_timestamp
FROM (
	SELECT 
		s1.user_id,
		s1.website_session_id AS first_session_id,
		s1.created_at AS first_session_timestamp,
		MIN(s2.website_session_id) AS second_session_id
	FROM website_sessions s1
		INNER JOIN website_sessions s2
			ON s1.user_id = s2.user_id
			AND s1.is_repeat_session = 0
			AND s1.website_session_id < s2.website_session_id
			AND s1.created_at BETWEEN "2014-01-01" AND "2014-11-03"
			AND s2.created_at BETWEEN "2014-01-01" AND "2014-11-03"
	GROUP BY 1, 2, 3
	) AS first_and_second_sessions
	
    LEFT JOIN website_sessions
		ON first_and_second_sessions.second_session_id = website_sessions.website_session_id
)

SELECT 
	AVG(DATEDIFF(second_session_timestamp, first_session_timestamp)) AS avg_days_first_to_second,
    MIN(DATEDIFF(second_session_timestamp, first_session_timestamp)) AS min_days_first_to_second,
    MAX(DATEDIFF(second_session_timestamp, first_session_timestamp)) AS max_days_first_to_second
FROM first_two_sessions_w_dates;

-- 3. Comparing new vs repeat sessions by channel of repeat users
WITH sessions_w_channel_group AS (
	SELECT 
		*,
		CASE
			WHEN utm_campaign IS NULL AND http_referer IS NULL THEN "direct_type_in"
			WHEN utm_campaign IS NULL AND http_referer IS NOT NULL THEN "organic_search"
			WHEN utm_source = "socialbook" THEN "paid_social"
			WHEN utm_campaign = "nonbrand" THEN "paid_nonbrand"
			WHEN utm_campaign = "brand" THEN "paid_brand"
			ELSE "others"
		END AS channel_group
	FROM website_sessions
    WHERE created_at BETWEEN "2014-01-01" AND "2014-11-05"
)

SELECT 
	channel_group,
    COUNT(DISTINCT IF(is_repeat_session=0, website_session_id, NULL)) AS new_sessions,
    COUNT(DISTINCT IF(is_repeat_session=1, website_session_id, NULL)) AS repeat_sessions
FROM sessions_w_channel_group
GROUP BY 1
ORDER BY repeat_sessions DESC;

-- repeat customers come back mainly through organic search, direct type-in and paid brand
-- only 1/3 come through a paid channel, and a brand clicks are cheaper than nonbrand
-- all in all, we are not paying very much for these subsequent visits
-- this lead us to the question of whether these convert to orders...

-- 4. Conversion rates and revenue per session for repeat sessions vs new sessions
SELECT
	is_repeat_session,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
    SUM(orders.price_usd) / COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at BETWEEN "2014-01-01" AND "2014-11-08"
GROUP BY 1;

-- repeat sessions are more likely to convert and product more revenue per session
-- we should probably take this into account when bidding on paid traffic