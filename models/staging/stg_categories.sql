{{
    config(
        materialized='view',
        alias='stg_categories',
        description='Staging model for category taxonomy'
    )
}}

select
    category_id,
    category_name,
    category_description
from {{ source('ecommerce', 'raw_categories') }}