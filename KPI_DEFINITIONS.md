# KPI Definitions & Calculations Guide

## Overview

All KPIs in this analytics layer are defined in code (`models/marts/metrics/kpi_catalog.sql`) with:
- Clear business definition
- Exact SQL formula
- Grain (level of aggregation)
- Owner + SLA
- Filters/Exclusions

This document provides detailed context for each KPI.

---

## Revenue KPIs

### 1. Total Revenue
**Business Definition**: Sum of all order totals (excluding cancelled orders)

**Formula**:
```sql
SUM(total_amount) 
FROM fact_orders 
WHERE status != 'cancelled'
```

**Grain**: Aggregates to any level (daily, customer, product, region)

**Filters**: Excludes cancelled orders (no value captured)

**Owner**: Finance Team  
**SLA**: Daily reporting requirement

**Usage**:
- "What was Q4 revenue?" → Group by quarter
- "Revenue by region?" → Join to dim_customer_scd2 and group by region
- "Revenue per customer?" → Group by customer_id

**Business Rules**:
- ✅ Includes tax and shipping
- ✅ Includes discounts (in total_amount after discounts)
- ✅ Only delivered/returned orders (cancelled = $0 value)

---

### 2. Total Profit
**Business Definition**: Net profit from all order items (revenue minus cost of goods sold)

**Formula**:
```sql
SUM(profit)
FROM fact_order_items
WHERE 1=1
-- profit = net_line_total - (quantity * product_unit_cost)
```

**Grain**: Order item level (can aggregate to order, product, customer)

**Filters**: None (includes all orders)

**Owner**: Finance Team  
**SLA**: Daily

**Calculation Details**:
```sql
profit = (unit_price * quantity * (1 - discount_pct/100)) - (quantity * product_unit_cost)
```

**Example**:
| Metric | Value |
|--------|-------|
| Unit Price | $50.00 |
| Quantity | 2 |
| Discount % | 10% |
| Product Cost | $20.00 |
| **Revenue** | $50 * 2 * (1 - 0.1) = $90 |
| **Cost** | 2 * $20 = $40 |
| **Profit** | $90 - $40 = **$50** |

**Edge Cases**:
- ❌ Profit can be negative (e.g., clearance sales)
- ✅ Test prevents revenue < 0, but profit < 0 is valid

---

### 3. Profit Margin
**Business Definition**: Profit as percentage of revenue

**Formula**:
```sql
(SUM(profit) / SUM(net_line_total)) * 100
FROM fact_order_items
```

**Grain**: Aggregates to order, product, or customer level

**Filters**: None

**Owner**: Finance Team  
**SLA**: Daily (but typically reviewed weekly)

**Benchmark**:
- **Electronics**: 25-35% typical margin
- **Office Supplies**: 40-50% typical margin
- **Below 15%**: Investigate clearance/promotional sales

---

## Order KPIs

### 4. Total Orders
**Business Definition**: Count of all delivered orders

**Formula**:
```sql
COUNT(order_id)
FROM fact_orders
WHERE status = 'delivered'
```

**Grain**: Daily, by customer, by product, by region

**Filters**: 
- ✅ Only delivered orders
- ❌ Excludes returned orders (counted separately)

**Owner**: Operations Team  
**SLA**: Daily

**Relationship to Return Rate**:
```
Total Orders (delivered) + Returned Orders + Cancelled Orders = All Orders
```

---

### 5. Average Order Value (AOV)
**Business Definition**: Average revenue per order

**Formula**:
```sql
SUM(total_amount) / COUNT(order_id)
FROM fact_orders
WHERE status != 'cancelled'
```

**Grain**: Time period (day/month/quarter) or segment (region, channel)

**Owner**: Marketing Team  
**SLA**: Daily

**Interpretation**:
- **Increasing AOV** → Product mix improving or upsell working
- **Decreasing AOV** → Discounting increasing or lower-value customers

**Context**:
- Electronics store: $150-200 typical
- Office supplies: $50-100 typical

---

### 6. Return Rate
**Business Definition**: Percentage of orders that were returned

**Formula**:
```sql
(COUNT(CASE WHEN status = 'returned' THEN order_id END) / COUNT(order_id)) * 100
FROM fact_orders
```

**Grain**: Product category, time period, customer segment

**Owner**: Operations Team  
**SLA**: Daily

**Benchmarks**:
- **Acceptable**: 2-5% for e-commerce
- **Alert Level**: > 10% indicates product/quality issue

**Related KPI**:
```
Return Rate = Returned Orders / Total Orders
Quality Score = 100 - Return Rate
```

---

## Customer KPIs

### 7. Total Customers
**Business Definition**: Count of unique customers with at least one delivered order

**Formula**:
```sql
COUNT(DISTINCT customer_id)
FROM fact_orders
WHERE status = 'delivered'
```

**Grain**: Daily (new customers acquired), monthly, annual

**Owner**: Marketing Team  
**SLA**: Daily

**Interpretation**:
- **Growing**: Successful acquisition
- **Flat**: Acquisition = churn
- **Declining**: Churn > acquisition (alert!)

---

### 8. Customer Lifetime Value (LTV)
**Business Definition**: Average total revenue per customer over their lifetime

**Formula**:
```sql
SUM(total_amount) / COUNT(DISTINCT customer_id)
FROM fact_orders
WHERE status != 'cancelled'
```

**Grain**: Cohort (by acquisition date/channel), segment (by region)

**Owner**: Finance Team  
**SLA**: Weekly (expensive to recalculate)

**Interpretation**:
- **$500 LTV**: Average customer generates $500 in lifetime revenue
- **By Channel**: Organic ($600) > Paid ($450) → Organic acquisition better ROI

**Advanced**: Can be modeled as function of acquisition channel
```sql
select
    acquisition_channel,
    avg(total_revenue_per_customer) as ltv,
    count(*) as customer_count
from rpt_customer_performance
group by acquisition_channel
order by ltv desc
```

---

### 9. Repeat Customer Rate
**Business Definition**: Percentage of customers with 2+ orders

**Formula**:
```sql
(COUNT(DISTINCT CASE WHEN order_count > 1 THEN customer_id END) / 
 COUNT(DISTINCT customer_id)) * 100
FROM (
    SELECT customer_id, COUNT(order_id) as order_count
    FROM fact_orders
    WHERE status != 'cancelled'
    GROUP BY customer_id
)
```

**Grain**: Cohort, channel, time period

**Owner**: Marketing Team  
**SLA**: Weekly

**Interpretation**:
- **50%**: Half of customers made 2+ purchases
- **Lower repeat rate**: Investigate customer satisfaction or product fit

---

### 10. Conversion Rate
**Business Definition**: Percentage of customers who placed at least one delivered order

**Formula**:
```sql
(COUNT(DISTINCT CASE WHEN status = 'delivered' THEN customer_id END) / 
 COUNT(DISTINCT customer_id)) * 100
FROM fact_orders
```

**Grain**: Acquisition channel, time period

**Owner**: Marketing Team  
**SLA**: Weekly

**Interpretation**:
- **Baseline**: "What % of visitors become customers?" (requires website traffic data)
- **Here**: "What % of customers place orders?" ≈ 100% (by definition)
- **Better**: Segment by channel to compare repeat rates

---

## Product KPIs

### 11. Average Product Margin
**Business Definition**: Average profit margin % across all active products

**Formula**:
```sql
AVG(margin_pct)
FROM dim_product_star
WHERE is_active = true
```

**Grain**: Product, category, department

**Owner**: Product Team  
**SLA**: Weekly

**Calculation** (at product level):
```
margin_pct = (list_price - unit_cost) / list_price
```

**Example**:
| Product | List Price | Unit Cost | Margin % |
|---------|-----------|-----------|----------|
| USB Hub | $69.99 | $35 | 49.9% |
| Keyboard | $89.99 | $45 | 50.0% |
| **Average** | - | - | **49.95%** |

---

### 12. Active Product Count
**Business Definition**: Number of products currently available for sale

**Formula**:
```sql
COUNT(product_id)
FROM dim_product_star
WHERE is_active = true
```

**Grain**: Department, category

**Owner**: Product Team  
**SLA**: Daily

**Trend Analysis**:
- Increasing → Expanding catalog
- Decreasing → Pruning underperformers
- Combined with revenue → Revenue per SKU

---

### 13. Average Products Per Order
**Business Definition**: Average number of line items per order

**Formula**:
```sql
COUNT(order_item_id) * 1.0 / COUNT(DISTINCT order_id)
FROM fact_order_items
```

**Grain**: Product category, customer segment, time period

**Owner**: Operations Team  
**SLA**: Weekly

**Interpretation**:
- **1.0**: Each order has exactly 1 product (rare)
- **1.5**: Average order has 1-2 products (typical for small e-commerce)
- **3.0+**: Bundle strategy working or accessories being sold

---

## Operational KPIs

### 14. Express Shipping Rate
**Business Definition**: Percentage of orders shipped via express delivery

**Formula**:
```sql
(SUM(CASE WHEN shipping_method = 'express' THEN 1 ELSE 0 END) / COUNT(order_id)) * 100
FROM fact_orders
WHERE status != 'cancelled'
```

**Grain**: Time period, region, customer segment

**Owner**: Operations Team  
**SLA**: Daily

**Interpretation**:
- **10%**: Small premium for expedited shipping
- **40%**: High customer willingness to pay for speed
- **>50%**: May indicate supply chain delays (customers opting for speed)

---

### 15. Discount Utilization Rate
**Business Definition**: Percentage of orders with applied discounts

**Formula**:
```sql
(SUM(CASE WHEN discount_amount > 0 THEN 1 ELSE 0 END) / COUNT(order_id)) * 100
FROM fact_orders
WHERE status != 'cancelled'
```

**Grain**: Time period, promo period, customer segment

**Owner**: Marketing Team  
**SLA**: Daily

**Context**:
- **5%**: Conservative discounting
- **30%**: Active promotion
- **>50%**: May indicate pricing strategy issue

**Relationship to AOV**:
```
High Discount Rate + Rising AOV → Bundling/volume incentives working
High Discount Rate + Falling AOV → Discounting eroding revenue
```

---

## Dashboard Layout Recommendations

### Revenue Dashboard
```
KPI Cards:
  - Total Revenue (big number, trend line)
  - Total Profit (big number, trend line)
  - Profit Margin % (percentage)

Charts:
  - Revenue Trend (line chart, daily)
  - Revenue by Category (bar chart)
  - Revenue by Region (map)
```

### Customer Dashboard
```
KPI Cards:
  - Total Customers (big number, trend)
  - Repeat Customer Rate (percentage)
  - Customer LTV (currency, trend)
  - Conversion Rate (percentage)

Charts:
  - New Customers (daily acquisition)
  - Customer Cohort Retention
  - Revenue by Acquisition Channel
```

### Operations Dashboard
```
KPI Cards:
  - Total Orders (big number, trend)
  - Return Rate (percentage)
  - Average Order Value (currency, trend)
  - Express Shipping Rate (percentage)

Charts:
  - Orders Trend (daily)
  - Return Rate by Category
  - Discount Utilization Trend
```

---

## Common Questions & Answers

**Q: Why is Return Rate < 1% but test `test_kpi_profit_validity` checks for negative profit?**
A: Negative profit can occur on returned items if discount was larger than margin. Example:
- Product cost: $20, list price: $49.99
- Customer buys at 20% discount = $40 revenue
- Customer returns (refund = $40)
- Loss = -$20

**Q: How do I drill down from Total Revenue to specific customer?**
A:
```sql
select c.customer_id, c.full_name, sum(o.total_amount) as customer_revenue
from fact_orders o
join dim_customer_scd1 c on o.customer_id = c.customer_id
group by c.customer_id, c.full_name
order by customer_revenue desc
```

**Q: Why does my KPI match Finance but differs from Hand-Counted?**
A: Check filters:
- Is 'cancelled' excluded? (affects Total Orders)
- Is tax/shipping included? (affects Total Revenue)
- Are partial refunds handled? (affects Return Rate)
- Is this month-to-date or full month?

---

## Maintenance & Updates

### When to Audit KPIs
- [ ] Monthly: Check for data anomalies
- [ ] Quarterly: Review calculations with Finance
- [ ] Annually: Assess KPI relevance to business strategy
- [ ] Always: After schema changes

### When to Add KPIs
- New strategic initiative
- New business unit
- New data source available
- Existing metric becomes irrelevant

### How to Change KPI Definition
1. Validate new definition with stakeholder
2. Add to `kpi_catalog.sql` (don't replace)
3. Mark old KPI as `deprecated`
4. Run `dbt test` to validate
5. Update documentation
6. Communicate changes to all users

---

**Last Updated**: May 2026  
**Author**: Analytics Team  
**Review Cycle**: Quarterly