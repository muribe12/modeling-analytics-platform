{{
    config(
        materialized='table',
        alias='dim_product_star',
        description='Product dimension with Star Schema - denormalized for optimal BI query performance'
    )
}}

-- Star Schema: Denormalized dimension with all attributes in single table
-- Benefit: Fewer joins for BI tools, faster query performance, simpler for analysts
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
    product_status,
    margin_amount,
    margin_pct,
    -- Conformed dimension attributes for cross-subject analysis
    category as product_category,
    department as product_department,
    brand as product_brand
from {{ ref('stg_products') }}