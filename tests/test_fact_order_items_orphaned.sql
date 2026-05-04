{{
    config(
        tags=['referential_integrity', 'critical']
    )
}}

-- Test: All order items reference valid orders
-- Business logic: Foreign key integrity - orphaned order items detection
select oi.order_item_id
from {{ ref('fact_order_items') }} oi
left join {{ ref('fact_orders') }} o
    on oi.order_id = o.order_id
where o.order_id is null