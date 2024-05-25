USE mavenfuzzyfactory;

-- BACKGROUND:
-- 		we ran a new custom landing page "/lander-1" in a 50/50 test against the homepage "/home" on gsearch nonbrand traffic
-- 		we need to evaluate the bounced rate of the two groups until 2012-07-28

-- finding the first date of /lander-1 to set analysis timeframe (result: 2012-06-19)
SELECT
	MIN(website_pageviews.created_at) AS first_created_at,
    MIN(website_pageviews.website_pageview_id) AS first_pageview_id,
    MAX(website_pageviews.created_at) AS last_created_at,
    MAX(website_pageviews.website_pageview_id) AS last_pageview_id
FROM website_pageviews
LEFT JOIN website_sessions
	ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE pageview_url = "/lander-1";

-- landing page id
DROP TEMPORARY TABLE IF EXISTS first_pageview;
CREATE TEMPORARY TABLE first_pageview
SELECT
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pv_id
FROM website_pageviews
LEFT JOIN website_sessions
	ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE website_pageviews.created_at BETWEEN "2012-06-19" AND "2012-07-28"
	AND utm_source = "gsearch"
    AND utm_campaign = "nonbrand"
GROUP BY 1;

-- sessions with landing page
DROP TEMPORARY TABLE IF EXISTS sessions_w_landing_page;
CREATE TEMPORARY TABLE sessions_w_landing_page
SELECT
	first_pageview.website_session_id,
    website_pageviews.website_pageview_id,
    website_pageviews.pageview_url
FROM first_pageview
LEFT JOIN website_pageviews
	ON first_pageview.min_pv_id = website_pageviews.website_pageview_id
WHERE pageview_url IN ("/home", "/lander-1");

-- bounced sessions
DROP TEMPORARY TABLE IF EXISTS bounced_sessions;
CREATE TEMPORARY TABLE bounced_sessions
SELECT 
	sessions_w_landing_page.website_session_id,
    sessions_w_landing_page.pageview_url,
    COUNT(DISTINCT website_pageviews.website_pageview_id) AS pageview_count
FROM sessions_w_landing_page
LEFT JOIN website_pageviews
	ON sessions_w_landing_page.website_session_id = website_pageviews.website_session_id
GROUP BY 
	sessions_w_landing_page.website_session_id,
    sessions_w_landing_page.pageview_url
HAVING pageview_count = 1;

-- summarize the finding
SELECT
	sessions_w_landing_page.pageview_url AS landing_page,
    COUNT(DISTINCT sessions_w_landing_page.website_session_id) AS total_sessions,
    COUNT(DISTINCT bounced_sessions.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT bounced_sessions.website_session_id) / COUNT(DISTINCT sessions_w_landing_page.website_session_id) AS bounced_rate
FROM sessions_w_landing_page
LEFT JOIN bounced_sessions
	ON sessions_w_landing_page.website_session_id = bounced_sessions.website_session_id
GROUP BY landing_page

