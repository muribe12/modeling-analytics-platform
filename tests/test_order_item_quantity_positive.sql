{{
    config(
        tags=['data_quality', 'critical']
    )
}}

-- Test: Order quantities must be positive
-- Business logic: Quantity cannot be zero or negative
select order_item_id, quantity
from {{ ref('fact_order_items') }}
where quantity <= 0