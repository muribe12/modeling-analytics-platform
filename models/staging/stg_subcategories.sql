{{
    config(
        materialized='view',
        alias='stg_subcategories',
        description='Staging model for subcategory taxonomy'
    )
}}

select
    subcategory_id,
    subcategory_name,
    category_id
from {{ source('ecommerce', 'raw_subcategories') }}