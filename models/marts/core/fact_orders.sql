{{
    config(
        materialized='table',
        alias='fact_orders',
        description='Fact table for order-level metrics - central to star schema for order analytics'
    )
}}

-- Fact table: Order-level grain
-- Contains additive metrics (amounts, counts) and foreign keys to dimensions
select
    o.order_id,
    o.order_date,
    o.customer_id,
    o.store_id,
    o.status,
    o.subtotal,
    o.tax_amount,
    o.shipping_cost,
    o.discount_amount,
    o.total_amount,
    o.payment_method,
    o.shipping_method,
    o.is_completed,
    o.is_returned_or_cancelled,
    o.has_discount,
    o.order_year,
    o.order_month,
    o.order_quarter,
    -- Date dimension key
    {{ dbt_utils.generate_surrogate_key(['order_date']) }} as date_key,
    -- Customer dimension keys (for SCD1 and SCD2)
    o.customer_id as customer_key_scd1,
    -- For SCD2, we'd need to join to dim_customer_scd2 to get the appropriate customer_key based on order_date
    -- This is handled in downstream models
    case
        when o.status = 'delivered' then 1
        else 0
    end as is_delivered_flag
from {{ ref('stg_orders') }} o
where o.status != 'cancelled'  -- Exclude cancelled orders from fact table