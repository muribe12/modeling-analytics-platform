{{
    config(
        tags=['referential_integrity']
    )
}}

-- Test: All orders reference valid customers
-- Business logic: Foreign key integrity - orphaned order detection
select o.order_id
from {{ ref('fact_orders') }} o
left join {{ ref('dim_customer_scd1') }} c
    on o.customer_id = c.customer_id
where c.customer_id is null