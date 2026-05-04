# Data Modeling Decisions

## 1. Star vs. Snowflake Schema

### Why Primary is Star Schema?

**Context**: E-commerce analytics has 2-3 key entities (Customer, Product, Order)

**Decision**: Use Star schema for primary model (`dim_product_star`), offer Snowflake as alternative

**Reasoning**:
- **Analyst Preference**: 80% of analyst queries prefer simple joins
- **BI Tool Performance**: Tableau/Looker optimize for star schemas
- **Query Simplicity**: `fact_orders → dim_product_star` vs `fact_orders → dim_product → dim_subcategory → dim_category`
- **Materialization**: Tables are fast; joins aren't a bottleneck in data warehouse

**Trade-offs**:
- **Storage**: ~5% more space (redundant category names)
- **Maintenance**: Update category name in `dim_product_star` only (easy with dbt)
- **Alternative Available**: `dim_product_snowflake` for storage-constrained systems

**Example Query - Star (2 joins)**:
```sql
select p.category, sum(f.total_amount) as revenue
from fact_orders f
join dim_product_star p on f.product_id = p.product_id
where f.order_date >= '2024-01-01'
group by p.category
```

**Example Query - Snowflake (4 joins)**:
```sql
select c.category_name, sum(f.total_amount) as revenue
from fact_orders f
join dim_product_snowflake p on f.product_id = p.product_id
join dim_subcategory s on p.subcategory_id = s.subcategory_id
join dim_category c on s.category_id = c.category_id
where f.order_date >= '2024-01-01'
group by c.category_name
```

---

## 2. SCD Type 1 vs. Type 2 Implementation

### Use SCD Type 1 (Overwrite) for:
- **Email, Phone**: Not needed historically
- **Current Region**: History tracked separately if needed
- **Account Status**: When updates are frequent and don't drive analysis

**Implementation** (`dim_customer_scd1`):
```sql
-- Always reflects current state
select customer_id, email, status, region, current_timestamp as updated_at
from stg_customers
```

**Storage**: 1 row per customer (minimal)

### Use SCD Type 2 (Full History) for:
- **Customer Status** (active → churned → reactivated): Defines customer lifetime
- **Region**: Critical for geographic trend analysis
- **Acquisition Channel**: May change due to data corrections
- **Any KPI dimension**: Where "as of date" matters

**Implementation** (`dim_customer_scd2`):
```sql
-- Multiple rows per customer, one per validity period
with historical as (
    select customer_id, email, status, region, valid_from, valid_to, is_current
    from stg_customers  -- Current records
    union all
    select customer_id, old_email, old_status, old_region, change_date, change_date, false
    from customer_updates  -- Historical records
)
select distinct * from historical
```

**Storage**: 1-5 rows per customer (depends on update frequency)

**Critical for Accuracy**:
```sql
-- ✅ CORRECT: Orders with customer status at order time
select o.order_date, c.status
from fact_orders o
join dim_customer_scd2 c
    on o.customer_id = c.customer_id
    and o.order_date >= c.valid_from
    and (o.order_date < c.valid_to or c.valid_to is null)

-- ❌ WRONG: Current status only (biases analysis)
select o.order_date, c.status
from fact_orders o
join dim_customer_scd2 c
    on o.customer_id = c.customer_id
    and c.is_current = true  -- ⚠️ Wrong date!
```

---

## 3. Fact Table Grain Selection

### `fact_orders` - Order Level

**Grain**: One row per order

**Why**: 
- Natural business entity
- Additive metrics (revenue, tax, shipping)
- Joins cleanly to dimensions

**Dimensions**:
- `customer_id` → `dim_customer_scd2` (join on order_date for historical accuracy)
- `product_id` → NOT JOINED (orders can have multiple products)
- `store_id` → `dim_store`
- `order_date` → `dim_date`

**Metrics**:
- `total_amount` (additive: can sum)
- `tax_amount` (additive)
- `discount_amount` (additive)

### `fact_order_items` - Line Item Level

**Grain**: One row per product in an order

**Why**: 
- Product-level analysis (not possible in `fact_orders`)
- Individual margin calculations
- Supports "products ordered together" analysis

**Dimensions**:
- `product_id` → `dim_product_star`
- `order_id` → `fact_orders` (relationship, not dimension)
- `customer_id` → `dim_customer_scd2`
- `category` (denormalized for performance)
- `order_date` → `dim_date`

**Metrics**:
- `line_total` (additive)
- `profit` (additive: can sum by product)
- `quantity` (additive)

### When Grains Conflict

**Problem**: Customer ordered Product A and B in same order
- Do we count as 1 order or 2?
- **Answer**: Depends on analysis!

**Solution**: Two separate facts
- `fact_orders`: 1 row = 1 customer order decision
- `fact_order_items`: 2 rows = 2 product decisions

**Example**:
```sql
-- "How many orders?" → Use fact_orders
select count(distinct order_id) from fact_orders

-- "Which products sell together?" → Use fact_order_items
select product_a, product_b, count(*)
from fact_order_items a
join fact_order_items b on a.order_id = b.order_id and a.product_id < b.product_id
group by product_a, product_b

-- "Average items per order?" → Join both
select sum(oi.quantity) / count(distinct o.order_id)
from fact_orders o
join fact_order_items oi on o.order_id = oi.order_id
```

---

## 4. Date Dimension Strategy

### `dim_date` - Conformed Across All Facts

**Why "Conformed"?**
- All fact tables use same date dimension
- Guarantees consistent fiscal calendars
- Enables drill-down: Year → Quarter → Month → Day

**Attributes**:
- Calendar (year, month, day, day_name)
- Fiscal (fiscal_year_start, fiscal_quarter, fiscal_half)
- Business (is_weekend, is_holiday_season)

**Example: Fiscal Year Analysis**
```sql
select
    d.fiscal_quarter,
    sum(f.total_amount) as revenue
from fact_orders f
join dim_date d on f.date_key = d.date_key
where d.fiscal_year_start = '2024-01-01'
group by d.fiscal_quarter
```

**Pre-filled vs Generated**:
- ✅ Pre-fill 3-5 years (our approach)
- ✅ Regenerate quarterly (if business calendar changes)
- ✅ Update holidays/promotions annually

---

## 5. Conformed Dimensions

### Principle: Same Dimension Used by Multiple Facts

**Example**: `dim_store` used by both `fact_orders` and future `fact_store_revenue`

**Benefits**:
- Consistency: "Store performance" same definition everywhere
- Simplicity: One place to update store name
- Performance: Dimension tables are small, cacheable

**Convention**:
- Dimension names don't include grain: `dim_store` (not `dim_store_daily`)
- Prefix matches entity: `dim_customer_*`, `dim_product_*`

---

## 6. Test Strategy

### Layer 1: Source Tests (Freshness)
```yaml
sources:
  - name: ecommerce
    freshness:
      warn_after: {count: 12, period: hour}
      error_after: {count: 24, period: hour}
```
**Purpose**: Alert if data stops refreshing

### Layer 2: Staging Tests (Built-in)
```yaml
tests:
  - unique
  - not_null
  - relationships
  - accepted_values
```
**Purpose**: Catch data quality issues early

### Layer 3: Mart Tests (Custom)
```sql
-- KPI sanity: Revenue never negative
-- SCD2 validity: No overlapping dates
-- Referential: No orphaned records
```
**Purpose**: Ensure business logic correctness

### When Tests Run
```bash
dbt test --select tag:critical  # Pre-deployment (fast)
dbt test                         # Post-deployment (comprehensive)
```

---

## 7. Incremental vs. Full Refresh

### Current: Full Refresh All Models

**Why?**
- Small dataset (50K rows)
- Staging models run in seconds
- Simplicity > optimization

**If This Grows**: Use Incremental
```sql
-- Staging stays full refresh (quick)
-- Marts become incremental (fast updates)
{{
    config(
        materialized='incremental',
        unique_key=['order_id'],
        on_schema_change='fail',
    )
}}

select * from {{ ref('stg_orders') }}
{% if execute %}
    where order_date > (select max(order_date) from {{ this }})
{% endif %}
```

---

## 8. Naming Conventions

### Model Files
```
stg_customers.sql       # Staging: Raw → Clean
int_product_snowflake.sql  # Intermediate: Multi-source logic
dim_customer_scd1.sql   # Dimension: Conformed entity
fact_orders.sql         # Fact: Measurable events
rpt_product_performance.sql  # Report: Pre-aggregated for BI
kpi_catalog.sql         # Metrics: Business definitions
```

### Model Names in Code
```sql
-- ✅ GOOD: Predictable pattern
select * from {{ ref('stg_customers') }}
select * from {{ source('ecommerce', 'raw_customers') }}

-- ❌ BAD: Ambiguous
select * from customers
select * from customer_dimension
```

### Column Names
```sql
-- ✅ GOOD: Descriptive
customer_id, order_date, order_total_amount

-- ❌ BAD: Ambiguous
id, date, amt
```

---

## 9. Documentation Standards

Every model MUST have:

1. **Description**: Business purpose (not technical)
   ```yaml
   description: Customer dimension with SCD Type 1 - overwrites historical data with current values only
   ```

2. **Column Definitions**: Explain business meaning
   ```yaml
   columns:
     - name: customer_status
       description: Current customer status (active, inactive, churned)
   ```

3. **Test Coverage**: At least 1 test per PK/FK
   ```yaml
   tests:
     - unique
     - not_null
   ```

4. **Updated At**: When last reviewed
   (Automatically via `current_timestamp()` in models)

---

## 10. Future Enhancements

### When to Add Complexity

| Feature | When | Cost |
|---------|------|------|
| Incremental models | Dataset > 1M rows | +20% build time |
| Parameterized tests | >10 custom tests | +time to maintain |
| dbt Cloud scheduling | >50 stakeholders | +$ per month |
| Great Expectations | Regulatory requirements | +engineering effort |
| Data contracts (dbt) | Cross-team dependencies | +coordination |

---

**Questions?** See README.md or reach out to Analytics Team.