{{
    config(
        materialized='view',
        alias='stg_customers',
        description='Staging model for customer data with basic transformations'
    )
}}

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
    -- Derived fields
    concat(first_name, ' ', last_name) as full_name,
    case
        when customer_status = 'active' then true
        else false
    end as is_active,
    case
        when acquisition_channel in ('organic', 'referral') then 'organic'
        when acquisition_channel in ('paid_search', 'social', 'email') then 'paid'
        else 'other'
    end as acquisition_type
from {{ source('ecommerce', 'raw_customers') }}