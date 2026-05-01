{{
    config(
        materialized='table',
        alias='dim_customer_scd2',
        description='Customer dimension with SCD Type 2 - maintains full history of customer attribute changes'
    )
}}

-- SCD Type 2: Full history tracking - maintains all historical versions of customer data
-- Use case: Customer status, region, lifetime value where historical analysis is important

with base_customers as (
    select
        customer_id,
        first_name,
        last_name,
        email,
        signup_date,
        customer_status,
        acquisition_channel,
        lifetime_value,
        region,
        country,
        full_name,
        is_active,
        acquisition_type
    from {{ ref('stg_customers') }}
),

-- Get customer updates from the updates table
updates as (
    select
        customer_id,
        email_change_date,
        old_email,
        new_email,
        old_status,
        new_status,
        old_region,
        new_region
    from {{ source('ecommerce', 'customer_updates') }}
),

-- Build historical records by unioning base data with updates
historical as (
    -- Current state (no valid_to = open-ended)
    select
        c.customer_id,
        c.email as email,
        c.customer_status as status,
        c.region as region,
        c.lifetime_value as lifetime_value,
        c.signup_date as valid_from,
        null::timestamp as valid_to,
        true as is_current,
        'current' as version_type
    from base_customers c
    
    union all
    
    -- Historical versions from updates table
    select
        u.customer_id,
        u.old_email as email,
        u.old_status as status,
        u.old_region as region,
        null::numeric as lifetime_value,  -- Lifetime value not tracked in updates
        u.email_change_date as valid_from,
        u.email_change_date as valid_to,  -- Closed interval
        false as is_current,
        'historical' as version_type
    from updates u
)

select
    -- Surrogate key for SCD2
    {{ dbt_utils.generate_surrogate_key(['customer_id', 'valid_from']) }} as customer_key,
    customer_id,
    email,
    status,
    region,
    lifetime_value,
    valid_from,
    valid_to,
    is_current,
    version_type
from historical
order by customer_id, valid_from desc