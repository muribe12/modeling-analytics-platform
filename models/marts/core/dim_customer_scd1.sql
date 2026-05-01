{{
    config(
        materialized='table',
        alias='dim_customer_scd1',
        description='Customer dimension with SCD Type 1 - overwrites historical data with current values only'
    )
}}

-- SCD Type 1: Overwrite strategy - only keeps latest customer information
-- Use case: Email addresses, phone numbers where historical tracking is not needed
select
    customer_id,
    first_name,
    last_name,
    email,
    signup_date,
    customer_status as status,
    acquisition_channel,
    lifetime_value,
    region,
    country,
    full_name,
    is_active,
    acquisition_type,
    -- Current record metadata
    current_timestamp as updated_at
from {{ ref('stg_customers') }}