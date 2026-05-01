{{
    config(
        materialized='view',
        alias='stg_order_items',
        description='Staging model for order item data with basic transformations'
    )
}}

select
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    discount_pct,
    line_total,
    -- Derived fields
    case
        when discount_pct > 0 then true
        else false
    end as has_discount,
    (unit_price * discount_pct / 100) as discount_amount,
    (unit_price * quantity) as gross_line_total,
    (unit_price * quantity * (1 - discount_pct / 100)) as net_line_total
from {{ source('ecommerce', 'raw_order_items') }}