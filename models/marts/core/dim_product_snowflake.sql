{{
    config(
        materialized='table',
        alias='dim_product_snowflake',
        description='Product dimension with Snowflake Schema - normalized through subcategory to category'
    )
}}

-- Snowflake Schema: Normalized dimension with category/subcategory in separate tables
-- Trade-off: More storage efficient, but requires joins for complete product view
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
    p.launch_date,
    p.product_status,
    p.margin_amount,
    p.margin_pct,
    -- Normalized keys from snowflake
    p.subcategory_id,
    p.category_id,
    -- Category attributes (normalized out)
    c.category_name,
    c.category_description
from {{ ref('int_product_snowflake') }} p
left join {{ ref('stg_categories') }} c
    on p.category_id = c.category_id