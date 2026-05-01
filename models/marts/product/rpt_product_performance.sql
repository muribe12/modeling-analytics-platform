{{
    config(
        materialized='table',
        alias='rpt_product_performance',
        description='Product performance report combining sales, margin, and KPI metrics'
    )
}}

-- Product-level aggregated metrics for BI reporting
select
    p.product_id,
    p.product_name,
    p.category,
    p.subcategory,
    p.department,
    p.brand,
    p.list_price,
    p.unit_cost,
    p.margin_amount,
    p.margin_pct,
    p.is_active,
    -- Aggregated metrics
    count(distinct oi.order_id) as total_orders,
    sum(oi.quantity) as total_quantity_sold,
    sum(oi.net_line_total) as total_revenue,
    sum(oi.quantity * p.unit_cost) as total_cost,
    sum(oi.net_line_total - (oi.quantity * p.unit_cost)) as total_profit,
    -- Average metrics
    avg(oi.net_line_total) as avg_order_value,
    count(distinct o.customer_id) as unique_customers,
    -- KPI calculations
    case
        when sum(oi.quantity) > 0 then sum(oi.net_line_total) / sum(oi.quantity)
        else 0
    end as avg_unit_price,
    case
        when sum(oi.quantity * p.unit_cost) > 0 
        then (sum(oi.net_line_total) - sum(oi.quantity * p.unit_cost)) / sum(oi.quantity * p.unit_cost)
        else 0
    end as profit_margin_pct
from {{ ref('stg_products') }} p
left join {{ ref('stg_order_items') }} oi
    on p.product_id = oi.product_id
left join {{ ref('stg_orders') }} o
    on oi.order_id = o.order_id and o.status != 'cancelled'
group by
    p.product_id,
    p.product_name,
    p.category,
    p.subcategory,
    p.department,
    p.brand,
    p.list_price,
    p.unit_cost,
    p.margin_amount,
    p.margin_pct,
    p.is_active
order by total_revenue desc