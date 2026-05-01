{{
    config(
        materialized='view',
        alias='kpi_catalog',
        description='KPI Catalog with standardized definitions for business metrics'
    )
}}

-- ============================================================
-- KPI CATALOG: E-commerce Analytics Layer
-- ============================================================
-- This model defines all KPIs with:
-- - Business definition (plain English)
-- - Formula / logic (SQL)
-- - Grain (entity level)
-- - Filters / exclusions
-- - Owner + SLA notes
-- ============================================================

select
    'total_revenue' as kpi_name,
    'Total Revenue' as kpi_display_name,
    'Sum of all order totals (excluding cancelled)' as business_definition,
    'SUM(total_amount) FROM fact_orders WHERE status != ''cancelled''' as formula,
    'Order' as grain,
    'Excludes cancelled orders' as filters,
    'Finance Team' as owner,
    'Daily SLA' as sla_notes,
    'Revenue' as category
union all
select
    'total_orders' as kpi_name,
    'Total Orders' as kpi_display_name,
    'Count of all delivered orders' as business_definition,
    'COUNT(order_id) FROM fact_orders WHERE status = ''delivered''' as formula,
    'Order' as grain,
    'Only delivered orders' as filters,
    'Operations Team' as owner,
    'Daily SLA' as sla_notes,
    'Orders' as category
union all
select
    'average_order_value' as kpi_name,
    'Average Order Value (AOV)' as kpi_display_name,
    'Average revenue per order' as business_definition,
    'SUM(total_amount) / COUNT(order_id) FROM fact_orders WHERE status != ''cancelled''' as formula,
    'Order' as grain,
    'Excludes cancelled orders' as filters,
    'Marketing Team' as owner,
    'Daily SLA' as sla_notes,
    'Revenue' as category
union all
select
    'total_customers' as kpi_name,
    'Total Customers' as kpi_display_name,
    'Count of unique customers with at least one delivered order' as business_definition,
    'COUNT(DISTINCT customer_id) FROM fact_orders WHERE status = ''delivered''' as formula,
    'Customer' as grain,
    'Only customers with delivered orders' as filters,
    'Marketing Team' as owner,
    'Daily SLA' as sla_notes,
    'Customers' as category
union all
select
    'customer_lifetime_value' as kpi_name,
    'Customer Lifetime Value (LTV)' as kpi_display_name,
    'Average total revenue per customer over their lifetime' as business_definition,
    'SUM(total_amount) / COUNT(DISTINCT customer_id) FROM fact_orders WHERE status != ''cancelled''' as formula,
    'Customer' as grain,
    'All non-cancelled orders' as filters,
    'Finance Team' as owner,
    'Weekly SLA' as sla_notes,
    'Customers' as category
union all
select
    'conversion_rate' as kpi_name,
    'Order Conversion Rate' as kpi_display_name,
    'Percentage of customers who placed at least one delivered order' as business_definition,
    'COUNT(DISTINCT CASE WHEN status = ''delivered'' THEN customer_id END) * 100.0 / COUNT(DISTINCT customer_id) FROM fact_orders' as formula,
    'Customer' as grain,
    'All customers with orders' as filters,
    'Marketing Team' as owner,
    'Weekly SLA' as sla_notes,
    'Conversion' as category
union all
select
    'return_rate' as kpi_name,
    'Return Rate' as kpi_display_name,
    'Percentage of orders that were returned' as business_definition,
    'COUNT(CASE WHEN status = ''returned'' THEN order_id END) * 100.0 / COUNT(order_id) FROM fact_orders' as formula,
    'Order' as grain,
    'All orders including cancelled' as filters,
    'Operations Team' as owner,
    'Daily SLA' as sla_notes,
    'Orders' as category
union all
select
    'repeat_customer_rate' as kpi_name,
    'Repeat Customer Rate' as kpi_display_name,
    'Percentage of customers with more than one order' as business_definition,
    'COUNT(DISTINCT CASE WHEN order_count > 1 THEN customer_id END) * 100.0 / COUNT(DISTINCT customer_id) FROM (SELECT customer_id, COUNT(order_id) as order_count FROM fact_orders WHERE status != ''cancelled'' GROUP BY customer_id)' as formula,
    'Customer' as grain,
    'Non-cancelled orders only' as filters,
    'Marketing Team' as owner,
    'Weekly SLA' as sla_notes,
    'Customers' as category
union all
select
    'product_margin' as kpi_name,
    'Average Product Margin' as kpi_display_name,
    'Average margin percentage across all products' as business_definition,
    'AVG(margin_pct) FROM dim_product_star WHERE is_active = true' as formula,
    'Product' as grain,
    'Active products only' as filters,
    'Finance Team' as owner,
    'Weekly SLA' as sla_notes,
    'Products' as category
union all
select
    'express_shipping_pct' as kpi_name,
    'Express Shipping Rate' as kpi_display_name,
    'Percentage of orders shipped via express delivery' as business_definition,
    'SUM(CASE WHEN shipping_method = ''express'' THEN 1 ELSE 0 END) * 100.0 / COUNT(order_id) FROM fact_orders WHERE status != ''cancelled''' as formula,
    'Order' as grain,
    'Non-cancelled orders only' as filters,
    'Operations Team' as owner,
    'Daily SLA' as sla_notes,
    'Shipping' as category
union all
select
    'discount_rate' as kpi_name,
    'Discount Utilization Rate' as kpi_display_name,
    'Percentage of orders with applied discounts' as business_definition,
    'SUM(CASE WHEN discount_amount > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(order_id) FROM fact_orders WHERE status != ''cancelled''' as formula,
    'Order' as grain,
    'Non-cancelled orders only' as filters,
    'Marketing Team' as owner,
    'Weekly SLA' as sla_notes,
    'Promotions' as category
union all
select
    'total_profit' as kpi_name,
    'Total Profit' as kpi_display_name,
    'Total profit across all order items (revenue - cost)' as business_definition,
    'SUM(profit) FROM fact_order_items' as formula,
    'Order Item' as grain,
    'Excludes cancelled order items' as filters,
    'Finance Team' as owner,
    'Daily SLA' as sla_notes,
    'Profit' as category
union all
select
    'profit_margin' as kpi_name,
    'Profit Margin' as kpi_display_name,
    'Overall profit as percentage of revenue' as business_definition,
    'SUM(profit) * 100.0 / SUM(net_line_total) FROM fact_order_items' as formula,
    'Order Item' as grain,
    'All order items' as filters,
    'Finance Team' as owner,
    'Daily SLA' as sla_notes,
    'Profit' as category
union all
select
    'active_product_count' as kpi_name,
    'Active Product Count' as kpi_display_name,
    'Number of products currently available for sale' as business_definition,
    'COUNT(product_id) FROM dim_product_star WHERE is_active = true' as formula,
    'Product' as grain,
    'Active products only' as filters,
    'Product Team' as owner,
    'Daily SLA' as sla_notes,
    'Products' as category
union all
select
    'avg_products_per_order' as kpi_name,
    'Average Products Per Order' as kpi_display_name,
    'Average number of line items per order' as business_definition,
    'COUNT(order_item_id) * 1.0 / COUNT(DISTINCT order_id) FROM fact_order_items' as formula,
    'Order' as grain,
    'All order items' as filters,
    'Operations Team' as owner,
    'Weekly SLA' as sla_notes,
    'Orders' as category