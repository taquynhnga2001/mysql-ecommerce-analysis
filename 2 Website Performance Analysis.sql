USE mavenfuzzyfactory;

-- 1. most viewed pages
SELECT
	pageview_url,
    COUNT(DISTINCT website_pageview_id) AS page_views
FROM website_pageviews
WHERE website_pageview_id < 1000
GROUP BY 1
ORDER BY 2 DESC;

-- 2. most common entry pages
CREATE TEMPORARY TABLE first_pageview
SELECT
	website_session_id,
    MIN(website_pageview_id) AS min_pv_id
FROM website_pageviews
GROUP BY website_session_id;

SELECT 	
	website_pageviews.pageview_url AS landing_page,
	COUNT(DISTINCT first_pageview.website_session_id) AS session_hitting_this_lander
FROM first_pageview
LEFT JOIN website_pageviews
	ON first_pageview.min_pv_id = website_pageviews.website_pageview_id
GROUP BY 1;

-- 3. most-viewed website pages, ranked by session volume
SELECT 
	pageview_url,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_pageviews
WHERE created_at < "2012-06-09"
GROUP BY pageview_url
ORDER BY sessions DESC;

-- 4. top-entry pages, ranked by entry volume: /home page
SELECT
	pageview_url AS landing_page,
    COUNT(DISTINCT first_pageview.website_session_id) AS sessions_hitting_this_landing_page
FROM first_pageview
LEFT JOIN website_pageviews
	ON first_pageview.min_pv_id = website_pageviews.website_pageview_id
WHERE created_at < "2012-06-12"
GROUP BY 1
ORDER BY 2 DESC;


