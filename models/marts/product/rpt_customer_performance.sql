{{
    config(
        materialized='table',
        alias='rpt_customer_performance',
        description='Customer performance report with LTV, order frequency, and behavioral metrics'
    )
}}

-- Customer-level aggregated metrics for BI reporting
select
    c.customer_id,
    c.full_name,
    c.email,
    c.customer_status,
    c.acquisition_channel,
    c.acquisition_type,
    c.region,
    c.country,
    c.signup_date,
    -- Aggregated order metrics
    count(o.order_id) as total_orders,
    sum(o.total_amount) as total_revenue,
    sum(o.subtotal) as total_subtotal,
    sum(o.tax_amount) as total_tax,
    sum(o.shipping_cost) as total_shipping,
    sum(o.discount_amount) as total_discounts,
    -- Order behavior metrics
    avg(o.total_amount) as avg_order_value,
    min(o.order_date) as first_order_date,
    max(o.order_date) as last_order_date,
    -- Customer lifecycle
    datediff(day, c.signup_date, max(o.order_date)) as customer_tenure_days,
    case
        when count(o.order_id) > 5 then 'High Value'
        when count(o.order_id) > 2 then 'Medium Value'
        else 'Low Value'
    end as customer_tier,
    -- Channel performance
    case
        when c.acquisition_channel in ('organic', 'referral') then 'Organic'
        else 'Paid'
    end as acquisition_category,
    -- Order status breakdown
    sum(case when o.status = 'delivered' then 1 else 0 end) as delivered_orders,
    sum(case when o.status = 'returned' then 1 else 0 end) as returned_orders,
    -- Shipping preferences
    sum(case when o.shipping_method = 'express' then 1 else 0 end) as express_orders,
    sum(case when o.shipping_method = 'standard' then 1 else 0 end) as standard_orders
from {{ ref('stg_customers') }} c
left join {{ ref('stg_orders') }} o
    on c.customer_id = o.customer_id and o.status != 'cancelled'
group by
    c.customer_id,
    c.full_name,
    c.email,
    c.customer_status,
    c.acquisition_channel,
    c.acquisition_type,
    c.region,
    c.country,
    c.signup_date
order by total_revenue desc