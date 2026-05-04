{{
    config(
        materialized='view',
        alias='kpi_daily_metrics',
        description='Daily aggregated KPI metrics for performance tracking'
    )
}}

-- Daily KPI snapshot for trend analysis
select
    {{ dbt_utils.generate_surrogate_key(['metric_date']) }} as metric_key,
    metric_date,
    extract(year from metric_date) as year,
    extract(month from metric_date) as month,
    extract(day from metric_date) as day,
    extract(week from metric_date) as week,
    extract(dayofweek from metric_date) as day_of_week,
    -- Revenue KPIs
    sum(total_amount) as daily_revenue,
    sum(total_orders) as daily_order_count,
    case
        when sum(total_orders) > 0 then sum(total_amount) / sum(total_orders)
        else 0
    end as daily_aov,
    -- Profit KPIs
    sum(daily_profit) as daily_profit,
    case
        when sum(total_amount) > 0 then (sum(daily_profit) / sum(total_amount)) * 100
        else 0
    end as daily_profit_margin_pct,
    -- Customer KPIs
    count(distinct customer_id) as daily_unique_customers,
    -- Order quality KPIs
    sum(case when order_status = 'delivered' then 1 else 0 end) as delivered_orders,
    sum(case when order_status = 'returned' then 1 else 0 end) as returned_orders,
    case
        when sum(total_orders) > 0
        then (sum(case when order_status = 'returned' then 1 else 0 end) / sum(total_orders)) * 100
        else 0
    end as daily_return_rate_pct
from (
    select
        o.order_date as metric_date,
        o.order_id,
        o.customer_id,
        o.total_amount,
        o.status as order_status,
        1 as total_orders,
        case
            when o.status = 'delivered' then 1
            else 0
        end as delivered_orders,
        sum(oi.profit) as daily_profit
    from {{ ref('fact_orders') }} o
    left join {{ ref('fact_order_items') }} oi
        on o.order_id = oi.order_id
    group by o.order_date, o.order_id, o.customer_id, o.total_amount, o.status
)
group by metric_date
order by metric_date desc