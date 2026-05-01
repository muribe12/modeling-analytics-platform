{{
    config(
        materialized='view',
        alias='stg_products',
        description='Staging model for product data with basic transformations'
    )
}}

select
    product_id,
    product_name,
    sku,
    category,
    subcategory,
    department,
    brand,
    unit_cost,
    list_price,
    weight_kg,
    is_active,
    launch_date,
    -- Derived fields
    case
        when is_active = true then 'Active'
        else 'Discontinued'
    end as product_status,
    (list_price - unit_cost) as margin_amount,
    round((list_price - unit_cost) / list_price, 4) as margin_pct
from {{ source('ecommerce', 'raw_products') }}