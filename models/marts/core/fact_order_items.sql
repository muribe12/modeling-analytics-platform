{{
    config(
        materialized='table',
        alias='fact_order_items',
        description='Fact table for order line items - detailed grain for product analytics'
    )
}}

-- Fact table: Order item-level grain
-- Contains line-level metrics and foreign keys to dimensions
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
    -- Order details for joining
    o.order_date,
    o.customer_id,
    o.store_id,
    o.status as order_status,
    o.is_completed,
    o.order_year,
    o.order_month,
    o.order_quarter,
    -- Product details
    p.category,
    p.subcategory,
    p.department,
    p.brand,
    p.margin_amount as product_margin_amount,
    p.margin_pct as product_margin_pct,
    -- Date dimension key
    {{ dbt_utils.generate_surrogate_key(['order_date']) }} as date_key,
    -- Calculated metrics
    (oi.quantity * p.unit_cost) as cost_total,
    (oi.net_line_total - (oi.quantity * p.unit_cost)) as profit
from {{ ref('stg_order_items') }} oi
left join {{ ref('stg_orders') }} o
    on oi.order_id = o.order_id
left join {{ ref('stg_products') }} p
    on oi.product_id = p.product_id
where o.status != 'cancelled'  -- Exclude cancelled order items