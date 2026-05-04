{{
    config(
        tags=['data_quality']
    )
}}

-- Test: Customer status must be valid values
-- Business logic: Only expected customer statuses should exist
select customer_id, status
from {{ ref('dim_customer_scd1') }}
where status not in ('active', 'inactive', 'churned')