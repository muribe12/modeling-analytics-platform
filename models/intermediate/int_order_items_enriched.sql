{{
    config(
        materialized='view',
        alias='int_order_items_enriched',
        description='Intermediate model enriching order items with product and order details'
    )
}}

select
    oi.order_item_id,
    oi.order_id,
    oi.product_id,
    oi.quantity,
    oi.unit_price,
    oi.discount_pct,
    oi.line_total,
    oi.has_discount,
    oi.discount_amount,
    oi.gross_line_total,
    oi.net_line_total,
    -- Order details
    o.order_date,
    o.customer_id,
    o.status as order_status,
    o.is_completed,
    o.is_returned_or_cancelled,
    o.shipping_method,
    o.store_id,
    o.order_year,
    o.order_month,
    o.order_quarter,
    -- Product details
    p.product_name,
    p.category,
    p.subcategory,
    p.department,
    p.brand,
    p.unit_cost as product_unit_cost,
    p.list_price as product_list_price,
    p.margin_amount as product_margin_amount,
    p.margin_pct as product_margin_pct
from {{ ref('stg_order_items') }} oi
left join {{ ref('stg_orders') }} o
    on oi.order_id = o.order_id
left join {{ ref('stg_products') }} p
    on oi.product_id = p.product_id