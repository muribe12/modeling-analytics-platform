{{
    config(
        materialized='view',
        alias='int_product_snowflake',
        description='Intermediate model building snowflake schema for products: Product -> Subcategory -> Category'
    )
}}

-- This creates a snowflake schema by normalizing product data through subcategory to category
select
    p.product_id,
    p.product_name,
    p.sku,
    p.category,
    p.subcategory,
    p.department,
    p.brand,
    p.unit_cost,
    p.list_price,
    p.weight_kg,
    p.is_active,
    p.product_status,
    p.margin_amount,
    p.margin_pct,
    -- Subcategory level (normalized)
    s.subcategory_id,
    s.subcategory_name,
    -- Category level (normalized - creates snowflake)
    c.category_id,
    c.category_name,
    c.category_description
from {{ ref('stg_products') }} p
left join {{ ref('stg_subcategories') }} s
    on p.subcategory = s.subcategory_name
left join {{ ref('stg_categories') }} c
    on s.category_id = c.category_id