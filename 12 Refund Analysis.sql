USE mavenfuzzyfactory;

-- BACKGROUND
-- Our Mr.Fuzzy supplier had some quality issues which weren't corrected until Sep 2013.
-- Then they had a major problem in Aug/Sep 2014 with bears' arms 
-- We replaced a new supplier on 2014-09-16

SELECT
	product_id,
    product_name,
    created_at
FROM products;

-- Monthly product refund rates by product
SELECT
	DATE_FORMAT(order_items.created_at, "%Y-%m") AS yyyy_mm,
    COUNT(DISTINCT IF(order_items.product_id=1, order_items.order_item_id, NULL)) AS p1_orders,
    COUNT(DISTINCT IF(order_items.product_id=1, order_item_refunds.order_item_id, NULL)) / COUNT(DISTINCT IF(order_items.product_id=1, order_items.order_item_id, NULL)) AS p1_refund_rt,
    COUNT(DISTINCT IF(order_items.product_id=2, order_items.order_item_id, NULL)) AS p2_orders,
    COUNT(DISTINCT IF(order_items.product_id=2, order_item_refunds.order_item_id, NULL)) / COUNT(DISTINCT IF(order_items.product_id=2, order_items.order_item_id, NULL)) AS p2_refund_rt,
    COUNT(DISTINCT IF(order_items.product_id=3, order_items.order_item_id, NULL)) AS p3_orders,
    COUNT(DISTINCT IF(order_items.product_id=3, order_item_refunds.order_item_id, NULL)) / COUNT(DISTINCT IF(order_items.product_id=3, order_items.order_item_id, NULL)) AS p3_refund_rt,
    COUNT(DISTINCT IF(order_items.product_id=4, order_items.order_item_id, NULL)) AS p4_orders,
    COUNT(DISTINCT IF(order_items.product_id=4, order_item_refunds.order_item_id, NULL)) / COUNT(DISTINCT IF(order_items.product_id=4, order_items.order_item_id, NULL)) AS p4_refund_rt
FROM order_items
	LEFT JOIN order_item_refunds
		ON order_items.order_item_id = order_item_refunds.order_item_id
WHERE order_items.created_at < "2014-10-15"
GROUP BY 1;

-- The refund rates for Mr. Fuzzy did go down after the initial improvement in Sep 2013
-- but refund rtes were terible in Aug and Sep 2014 as expected
-- the new supplier seems to do much better so far in terms of quality