{{
    config(
        materialized='view',
        alias='stg_orders',
        description='Staging model for order data with basic transformations'
    )
}}

select
    order_id,
    order_date,
    customer_id,
    status,
    subtotal,
    tax_amount,
    shipping_cost,
    discount_amount,
    total_amount,
    payment_method,
    shipping_method,
    store_id,
    notes,
    -- Derived fields
    case
        when status = 'delivered' then true
        else false
    end as is_completed,
    case
        when status in ('cancelled', 'returned') then true
        else false
    end as is_returned_or_cancelled,
    case
        when shipping_method = 'express' then true
        else false
    end as is_express_shipping,
    case
        when discount_amount > 0 then true
        else false
    end as has_discount,
    extract(year from order_date) as order_year,
    extract(month from order_date) as order_month,
    extract(quarter from order_date) as order_quarter
from {{ source('ecommerce', 'raw_orders') }}