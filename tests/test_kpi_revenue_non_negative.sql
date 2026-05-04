{{
    config(
        tags=['kpi_sanity', 'critical']
    )
}}

-- Test: Revenue KPI must be non-negative
-- Business logic: Revenue should never be negative
select order_id
from {{ ref('fact_orders') }}
where total_amount < 0