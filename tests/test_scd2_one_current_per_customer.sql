{{
    config(
        tags=['scd2', 'critical']
    )
}}

-- Test: SCD2 only one current version per customer
-- Business logic: Each customer should have exactly one record where is_current = true
select customer_id
from {{ ref('dim_customer_scd2') }}
where is_current = true
group by customer_id
having count(*) > 1