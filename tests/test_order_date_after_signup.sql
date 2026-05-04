{{
    config(
        tags=['data_quality']
    )
}}

-- Test: Order date must be after customer signup date
-- Business logic: Customers cannot order before they sign up
select o.order_id, o.order_date, c.signup_date
from {{ ref('fact_orders') }} o
left join {{ ref('dim_customer_scd1') }} c
    on o.customer_id = c.customer_id
where o.order_date < c.signup_date