USE mavenfuzzyfactory;

-- BACKGROUND:
-- 		after seeing the lower bounced rate in /lander-1 landing page group, we updated all nonbrand paid traffic to point to this new landing page
-- 		we are looking at the weekly bounced rate trend to make sure things are moving in the right direction (from 2012-06-01 to 2012-08-31)

-- paid search nonbrand landing pages on /home or /lander-1
DROP TEMPORARY TABLE IF EXISTS first_pageview;
CREATE TEMPORARY TABLE first_pageview
SELECT
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pv_id
FROM website_pageviews
LEFT JOIN website_sessions
	ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE website_pageviews.created_at BETWEEN "2012-06-01" AND "2012-08-31"
	AND utm_source = "gsearch"
    AND utm_campaign = "nonbrand"
GROUP BY 1;

-- sessions with landing page
DROP TEMPORARY TABLE IF EXISTS sessions_w_landing_page;
CREATE TEMPORARY TABLE sessions_w_landing_page
SELECT
	website_pageviews.website_session_id,
	website_pageviews.website_pageview_id,
    website_pageviews.created_at,
    website_pageviews.pageview_url AS landing_page
FROM first_pageview
LEFT JOIN website_pageviews
	ON first_pageview.min_pv_id = website_pageviews.website_pageview_id
WHERE pageview_url IN ("/home", "/lander-1")
ORDER BY created_at;

-- bounced sessions
DROP TEMPORARY TABLE IF EXISTS bounced_sessions;
CREATE TEMPORARY TABLE bounced_sessions
SELECT
	sessions_w_landing_page.website_session_id,
    COUNT(DISTINCT website_pageviews.website_pageview_id) AS pageview_count
FROM sessions_w_landing_page
LEFT JOIN website_pageviews
	ON sessions_w_landing_page.website_session_id = website_pageviews.website_session_id
GROUP BY sessions_w_landing_page.website_session_id
HAVING pageview_count = 1;

-- weekly trending of paid search nonbrand traffic landing on /home and /lander
SELECT
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT bounced_sessions.website_session_id) / COUNT(DISTINCT sessions_w_landing_page.website_session_id) AS bounced_rate,
    COUNT(DISTINCT CASE WHEN landing_page = "/home" THEN sessions_w_landing_page.website_session_id ELSE NULL END) AS home_session,
    COUNT(DISTINCT CASE WHEN landing_page = "/lander-1" THEN sessions_w_landing_page.website_session_id ELSE NULL END ) AS lander_session
FROM sessions_w_landing_page
LEFT JOIN bounced_sessions
	ON sessions_w_landing_page.website_session_id = bounced_sessions.website_session_id
GROUP BY WEEK(created_at);