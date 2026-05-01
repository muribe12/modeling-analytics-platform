{{
    config(
        materialized='view',
        alias='stg_stores',
        description='Staging model for store data with basic transformations'
    )
}}

select
    store_id,
    store_name,
    store_type,
    address,
    city,
    state,
    country,
    region,
    manager,
    opened_date,
    -- Derived fields
    case
        when store_type = 'flagship' then true
        else false
    end as is_flagship,
    case
        when store_type = 'international' then true
        else false
    end as is_international,
    extract(year from opened_date::date) as opened_year
from {{ source('ecommerce', 'raw_stores') }}