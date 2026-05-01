{{
    config(
        materialized='table',
        alias='dim_store',
        description='Store dimension - single table denormalized for star schema'
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
    is_flagship,
    is_international,
    opened_year
from {{ ref('stg_stores') }}