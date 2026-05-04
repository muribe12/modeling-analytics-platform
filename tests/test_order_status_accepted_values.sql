{{
    config(
        tags=['data_quality']
    )
}}

-- Test: Order status must be valid values
-- Business logic: Only expected order statuses should exist
select order_id, order_status
from {{ ref('fact_order_items') }}
where order_status not in ('delivered', 'returned', 'cancelled')