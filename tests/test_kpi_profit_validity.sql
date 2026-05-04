{{
    config(
        tags=['kpi_sanity', 'critical']
    )
}}

-- Test: Profit KPI must be less than or equal to revenue
-- Business logic: Profit cannot exceed net line total (revenue after discount)
select order_item_id
from {{ ref('fact_order_items') }}
where profit > net_line_total
   or profit < 0