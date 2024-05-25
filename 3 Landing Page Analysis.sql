USE mavenfuzzyfactory;

-- create a landing page id table for sessions
DROP TEMPORARY TABLE IF EXISTS first_pageview;
CREATE TEMPORARY TABLE first_pageview  
SELECT 
	website_session_id,
    MIN(website_pageview_id) AS min_pv_id
FROM website_pageviews
WHERE created_at < "2012-06-14"
GROUP BY 1;

-- landing page table with url
DROP TEMPORARY TABLE IF EXISTS entry_page_sessions;
CREATE TEMPORARY TABLE entry_page_sessions
SELECT
	website_pageviews.website_session_id,
    website_pageview_id,
    pageview_url
FROM first_pageview
LEFT JOIN website_pageviews
	ON first_pageview.min_pv_id = website_pageviews.website_pageview_id
WHERE created_at < "2012-06-14";

-- bounced sessions
DROP TEMPORARY TABLE IF EXISTS bounced_sessions;
CREATE TEMPORARY TABLE bounced_sessions
SELECT 
	website_session_id
FROM website_pageviews
WHERE created_at < "2012-06-14"
GROUP BY website_session_id
HAVING COUNT(DISTINCT website_pageview_id) = 1;

-- summarize landing page analysis
SELECT
	pageview_url,
    COUNT(DISTINCT entry_page_sessions.website_session_id) AS total_sessions,
    COUNT(DISTINCT bounced_sessions.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT bounced_sessions.website_session_id) / COUNT(DISTINCT entry_page_sessions.website_session_id) AS bounced_rate
FROM entry_page_sessions
LEFT JOIN bounced_sessions
	ON entry_page_sessions.website_session_id = bounced_sessions.website_session_id
GROUP BY 1;

