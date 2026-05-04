# Analytics Modeling Layer - E-commerce Analytics Platform

## Executive Summary

This repository demonstrates a **production-ready dbt analytics project** that translates business requirements into trustworthy, auditable data models. It showcases best practices in:

- **Dimensional Modeling**: Star and Snowflake schemas for performance and flexibility
- **Slowly Changing Dimensions**: Type 1 (overwrite) and Type 2 (full history) implementations
- **KPI Definitions**: Business-facing metric catalog with clear ownership and SLA tracking
- **Data Quality**: Comprehensive test suite covering sanity checks and referential integrity
- **Documentation**: Analyst-friendly documentation and lineage tracking

---

## Problem → Solution → Impact

### The Problem
Most analytics projects focus on **building pipelines** rather than **modeling for business value**:
- ❌ Analysts struggle to understand which metrics are "correct"
- ❌ KPI definitions are scattered across Slack/Wiki/Excel
- ❌ Metric calculations differ across reports (Tableau vs Looker vs handwritten SQL)
- ❌ No audit trail when customer numbers don't match finance

### Our Solution
**A dimensional data model designed for trust and self-service**:
- ✅ Star schema for intuitive joins and fast queries
- ✅ SCD Type 2 for historical analysis (when did customer region change?)
- ✅ Unified KPI catalog with business logic in code
- ✅ Comprehensive tests (dbt test suite) preventing silent data corruption
- ✅ dbt docs = single source of truth for definitions

### The Impact
- **Faster Analytics**: Analysts write simpler queries against clean, conformed dimensions
- **Fewer Bugs**: Tests catch data issues before dashboards break
- **Better Decisions**: Everyone uses the same metric definition
- **Audit Ready**: Every number is traceable to business logic

---

## Project Structure

```
analytics-modeling-layer/
├── dbt_project.yml              # dbt configuration
├── packages.yml                 # External dependencies (dbt_utils)
├── README.md                    # This file
│
├── seeds/                       # CSV seed data (initial data load)
│   ├── raw_customers.csv
│   ├── raw_products.csv
│   ├── raw_orders.csv
│   ├── raw_order_items.csv
│   ├── raw_stores.csv
│   ├── raw_categories.csv
│   ├── raw_subcategories.csv
│   └── customer_updates.csv     # For SCD Type 2 demo
│
├── models/
│   ├── sources/
│   │   └── ecommerce_sources.yml       # Source definitions + freshness
│   │
│   ├── staging/                        # stg_* - Raw to cleaned
│   │   ├── stg_customers.sql
│   │   ├── stg_products.sql
│   │   ├── stg_orders.sql
│   │   ├── stg_order_items.sql
│   │   ├── stg_stores.sql
│   │   ├── stg_categories.sql
│   │   ├── stg_subcategories.sql
│   │   └── staging_schema.yml
│   │
│   ├── intermediate/                   # int_* - Business logic + joins
│   │   ├── int_product_snowflake.sql   # Snowflake schema example
│   │   ├── int_order_items_enriched.sql
│   │   └── intermediate_schema.yml
│   │
│   └── marts/                          # Production-ready tables
│       ├── core/                       # Dimensions + facts
│       │   ├── dim_customer_scd1.sql   # SCD Type 1 - current state only
│       │   ├── dim_customer_scd2.sql   # SCD Type 2 - full history
│       │   ├── dim_product_star.sql    # Star schema - denormalized
│       │   ├── dim_product_snowflake.sql # Snowflake schema - normalized
│       │   ├── dim_store.sql
│       │   ├── dim_date.sql            # Conformed date dimension
│       │   ├── fact_orders.sql         # Order-level fact table
│       │   ├── fact_order_items.sql    # Line-item fact table
│       │   └── marts_schema.yml
│       │
│       ├── product/                    # Product mart
│       │   ├── rpt_product_performance.sql
│       │   └── rpt_customer_performance.sql
│       │
│       └── metrics/                    # KPI layer
│           ├── kpi_catalog.sql         # KPI definitions
│           ├── kpi_daily_metrics.sql   # Daily metric snapshots
│           └── metrics_schema.yml
│
├── tests/
│   ├── test_kpi_revenue_non_negative.sql
│   ├── test_kpi_profit_validity.sql
│   ├── test_scd2_no_overlaps.sql
│   ├── test_scd2_one_current_per_customer.sql
│   ├── test_fact_order_items_orphaned.sql
│   ├── test_fact_orders_orphaned_customer.sql
│   ├── test_order_status_accepted_values.sql
│   ├── test_customer_status_accepted_values.sql
│   ├── test_order_item_quantity_positive.sql
│   └── test_order_date_after_signup.sql
│
└── macros/                      # (Future) Custom testing + transformations
```

---

## Data Model Overview

### 1. Star Schema (Primary Pattern)

**Why Star Schema?**
- **Analyst Friendly**: Minimal joins, self-explanatory
- **Query Performance**: Fewer joins = faster queries, easier for BI tools to optimize
- **Maintenance**: All attributes in one place, easier to update

**Star Schema Example**:
```
                    ┌─────────────────┐
                    │   dim_date      │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
    ┌──────────────▶│  fact_orders    │◀────────────┐
    │               └─────┬──────────┘             │
    │                     │                       │
┌───┴──────────┐  ┌───────┴──────────┐  ┌────────┴────┐
│dim_customer  │  │  dim_product     │  │  dim_store  │
│   (SCD1)     │  │    (Star)        │  │             │
└──────────────┘  └──────────────────┘  └─────────────┘
```

**Models**:
- `dim_customer_scd1`: Denormalized current customer state
- `dim_product_star`: Denormalized product with all category/department data
- `dim_store`: Store locations and metadata
- `dim_date`: Conformed date dimension for time analysis
- `fact_orders`: Order metrics aggregated to order level

**Analyst Query Example**:
```sql
select
    d.fiscal_quarter,
    c.region,
    p.category,
    sum(f.total_amount) as revenue,
    count(f.order_id) as order_count
from fact_orders f
join dim_date d on f.date_key = d.date_key
join dim_customer_scd1 c on f.customer_id = c.customer_id
join dim_product_star p on f.product_id = p.product_id
group by d.fiscal_quarter, c.region, p.category
```

---

### 2. Snowflake Schema (Alternative Pattern)

**Why Snowflake Schema?**
- **Storage Efficient**: Normalized dimensions reduce redundancy
- **Maintenance**: Update category name in one place
- **Trade-off**: Requires more joins, slightly more complex queries

**Snowflake Example**:
```
┌────────────────────────┐
│   dim_category         │ ◀────┐
│  (normalized)          │       │
└────────────────────────┘       │
         ▲                        │
         │                   ┌────┴──────────┐
    ┌────┴─────────────┐     │   dim_product  │
    │ dim_subcategory  │────▶│   (snowflake)  │
    │  (normalized)    │     └────────────────┘
    └──────────────────┘
```

**Models**:
- `int_product_snowflake`: Joins Product → Subcategory → Category
- `dim_product_snowflake`: Final normalized product dimension
- `stg_categories`: Base category table
- `stg_subcategories`: Base subcategory table

**Trade-off Analysis**:
| Aspect | Star | Snowflake |
|--------|------|-----------|
| Query Joins | Few (simpler) | More (complex) |
| Storage | Redundant | Efficient |
| Update Category | Update 1000s rows | Update 1 row |
| BI Tool Support | Native | Native |
| Analyst Preference | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |

**In this project**: Star schema is primary, Snowflake available as alternative for specific use cases.

---

## Slowly Changing Dimensions (SCD)

### SCD Type 1 (Overwrite)

**When to Use**:
- Email addresses
- Customer phone numbers
- Current region
- Any attribute where **history is not needed**

**Implementation** (`dim_customer_scd1`):
```sql
select
    customer_id,
    email,           -- Always current (overwritten)
    customer_status, -- Always current
    region,          -- Always current
    current_timestamp as updated_at
from stg_customers
```

**SQL Example - Problem**:
> "What was Alice's email 6 months ago?" ❌ Can't answer - we overwrote it

---

### SCD Type 2 (Full History)

**When to Use**:
- Customer status changes (active → churned → reactivated)
- Regional expansion tracking
- Customer tier progression
- Any attribute where **temporal analysis matters**

**Implementation** (`dim_customer_scd2`):
```sql
-- SCD2 attributes:
select
    customer_key,      -- Surrogate key for each version
    customer_id,       -- Natural key (same for all versions)
    email,             -- Value at this time period
    status,            -- Status at this time period
    valid_from,        -- Start of validity
    valid_to,          -- End of validity (null = current)
    is_current         -- Boolean flag
from dim_customer_scd2
```

**Example Data**:
```
customer_key | customer_id | email           | status  | valid_from | valid_to   | is_current
─────────────┼─────────────┼─────────────────┼─────────┼────────────┼────────────┼───────────
     1       │   C004      │ old@email.com   │ active  │ 2023-04-05 │ 2024-02-15 │ false
     2       │   C004      │ new@email.com   │ churned │ 2024-02-15 │ NULL       │ true
```

**SQL Example - Solution**:
```sql
-- When was Alice churned?
select valid_from
from dim_customer_scd2
where customer_id = 'C004'
  and is_current = true
  and status = 'churned'
```

**Referential Integrity with SCD2**:

✅ **Correct**: Join fact table to SCD2 using order date + is_current
```sql
select
    o.order_id,
    o.order_date,
    c.status  -- Gets correct status at order time
from fact_orders o
join dim_customer_scd2 c
    on o.customer_id = c.customer_id
    and o.order_date >= c.valid_from
    and (o.order_date < c.valid_to or c.valid_to is null)
```

❌ **Wrong**: Joining without considering valid dates
```sql
-- This gets CURRENT status, not status AT ORDER TIME
select o.order_id, c.status
from fact_orders o
join dim_customer_scd2 c on o.customer_id = c.customer_id
where c.is_current = true  -- ⚠️ Wrong!
```

---

## KPI Definitions

### KPI Catalog (`kpi_catalog`)

All KPIs are defined in **code** with business context:

```sql
KPI Name:            total_revenue
Display Name:        Total Revenue
Business Def:        Sum of all order totals (excluding cancelled)
Formula:             SUM(total_amount) FROM fact_orders WHERE status != 'cancelled'
Grain:               Order (can aggregate to customer/product/region)
Filters:             Excludes cancelled orders
Owner:               Finance Team
SLA Notes:           Daily SLA
Category:            Revenue
```

### Available KPIs

| KPI | Description | Grain | Formula |
|-----|-------------|-------|---------|
| `total_revenue` | Revenue (excl. cancelled) | Order | SUM(total_amount) |
| `total_orders` | Delivered orders | Order | COUNT(order_id) WHERE status='delivered' |
| `average_order_value` | AOV | Order | SUM(total_amount) / COUNT(order_id) |
| `total_customers` | Unique customers | Customer | COUNT(DISTINCT customer_id) |
| `customer_lifetime_value` | LTV | Customer | SUM(total_amount) / COUNT(DISTINCT customer_id) |
| `conversion_rate` | % with orders | Customer | COUNT(customers_with_orders) / COUNT(all_customers) |
| `return_rate` | % returned orders | Order | COUNT(returned) / COUNT(all) |
| `repeat_customer_rate` | % with 2+ orders | Customer | COUNT(repeat) / COUNT(all_customers) |
| `product_margin` | Avg margin % | Product | AVG(margin_pct) WHERE active=true |
| `express_shipping_pct` | % express orders | Order | COUNT(express) / COUNT(total) |
| `discount_rate` | % with discounts | Order | COUNT(discounted) / COUNT(total) |
| `total_profit` | Net profit | Order Item | SUM(profit) |
| `profit_margin` | Profit % of revenue | Order Item | SUM(profit) / SUM(revenue) |

### KPI Consistency Example

**Finance Report Says**: "January Revenue = $47,230"
**Looker Dashboard Shows**: "January Revenue = $47,230" ✅
**Ad-hoc SQL Query Gets**: Same number ✅

**Why?** Because `kpi_catalog` defines the formula once, and all tools reference it.

---

## Tests & Data Quality

### Built-in dbt Tests

Used on dimensions, facts, and staging models:

```yaml
# Test uniqueness and non-nullness
columns:
  - name: customer_id
    tests:
      - unique
      - not_null

# Test referential integrity
  - name: category_id
    tests:
      - relationships:
          to: ref('stg_categories')
          field: category_id

# Test accepted values
  - name: status
    tests:
      - accepted_values:
          values: ['active', 'inactive', 'churned']
```

### Custom Data Quality Tests

| Test | Purpose | Example |
|------|---------|---------|
| `test_kpi_revenue_non_negative` | Revenue sanity | Catch negative order totals |
| `test_kpi_profit_validity` | Profit ≤ revenue | Ensure COGS calculations correct |
| `test_scd2_no_overlaps` | SCD2 validity | No overlapping time ranges |
| `test_scd2_one_current_per_customer` | SCD2 integrity | Exactly 1 current version per customer |
| `test_fact_order_items_orphaned` | Referential integrity | No order items without orders |
| `test_fact_orders_orphaned_customer` | Referential integrity | No orders without customers |
| `test_order_status_accepted_values` | Data validity | Only valid statuses |
| `test_customer_status_accepted_values` | Data validity | Only valid customer statuses |
| `test_order_item_quantity_positive` | Business logic | Quantities > 0 |
| `test_order_date_after_signup` | Temporal logic | Order date ≥ signup date |

---

## Getting Started

### Prerequisites
- dbt >= 1.0
- Python 3.8+
- A supported database (Snowflake, BigQuery, Redshift, DuckDB, etc.)
- dbt packages (installed via `dbt deps`)

### Installation

```bash
# 1. Clone or navigate to project
cd analytics-modeling-layer

# 2. Install dbt packages
dbt deps

# 3. (If needed) Configure profiles.yml with your database credentials
# See: https://docs.getdbt.com/docs/core/dbt-cli/configure-your-profile

# 4. Test database connection
dbt debug
```

### Running the Project

```bash
# 1. Load seed data (initial CSV load)
dbt seed
# ✅ Creates raw_customers, raw_products, raw_orders, etc.

# 2. Run all models (sources → staging → intermediate → marts)
dbt run
# ✅ Materializes tables/views in your database

# 3. Run all tests
dbt test
# ✅ Validates data quality, catches issues

# 4. Generate documentation
dbt docs generate

# 5. View interactive lineage and documentation
dbt docs serve
# Opens http://localhost:8000 with full dbt docs
```

### Selective Execution

```bash
# Run only staging models
dbt run --select staging

# Run only fact tables
dbt run --select tag:fact

# Run only KPI metrics
dbt run --select path:models/marts/metrics

# Run tests for a specific model
dbt test --select dim_customer_scd1

# Run tests tagged 'critical'
dbt test --select tag:critical
```

---

## Model Layering

### Layer 1: Sources (`sources/`)
- **Purpose**: Define raw data connections
- **Materialization**: None (queries source data)
- **Example**: `source('ecommerce', 'raw_customers')`
- **Tests**: Freshness checks, unique/not-null on keys

### Layer 2: Staging (`staging/`)
- **Purpose**: Clean, standardize, add basic derived fields
- **Materialization**: Views (lightweight)
- **Naming**: `stg_*`
- **Logic**: Single source truth, minimal joins
- **Example**: Clean email addresses, extract year from date

### Layer 3: Intermediate (`intermediate/`)
- **Purpose**: Build business logic, complex joins, denormalization
- **Materialization**: Views (transient)
- **Naming**: `int_*`
- **Logic**: Multi-source joins, aggregations, snowflake building
- **Example**: Combine order + customer + product data

### Layer 4: Marts (`marts/`)
- **Purpose**: Optimized for end-user queries (analysts, BI tools)
- **Materialization**: Tables (for performance)
- **Naming**: `dim_*`, `fact_*`, `rpt_*`
- **Logic**: Specific use cases, indexed for queries
- **Example**: `fact_orders` ready for Tableau/Looker

---

## Performance Considerations

### Materialization Strategy

| Model Type | Materialization | Reason |
|-----------|-----------------|--------|
| Sources | None | External reference |
| stg_* | Views | Small, reusable logic |
| int_* | Views | Intermediate, non-reporting |
| dim_* | Tables | Frequently joined, stable |
| fact_* | Tables | Large, frequently queried |
| rpt_* | Tables | Pre-aggregated for BI |
| kpi_* | Views | Lightweight catalog |

### Query Optimization Tips

1. **Always filter by date**: Fact tables have order_date
   ```sql
   where order_date >= '2024-01-01'
   ```

2. **Use dimension keys**: Smaller integers vs UUIDs
   ```sql
   join dim_date d on f.date_key = d.date_key  -- Fast
   ```

3. **Aggregate in fact table**: Pre-compute daily/monthly metrics
   ```sql
   select date, revenue, order_count
   from kpi_daily_metrics
   ```

---

## Trade-offs & Limitations

### Star vs. Snowflake
- ✅ **Star**: Simpler for analysts
- ✅ **Snowflake**: More efficient storage
- 🤔 **Decision**: Use Star as primary, Snowflake for specific high-cardinality attributes

### SCD Type 1 vs. Type 2
- ✅ **SCD1**: Fast inserts, simple logic
- ✅ **SCD2**: Full history, audit trail
- ⚠️ **Storage**: SCD2 uses 2-5x more space
- 🤔 **Decision**: Use SCD1 for frequently-updated, low-priority attributes (email); SCD2 for business-critical metrics (status, region)

### Grain Consistency
- ⚠️ **Risk**: Mixing grains in fact table (orders + order items)
- ✅ **Solution**: Separate fact tables (`fact_orders` vs `fact_order_items`)
- 🤔 **Trade-off**: More tables, clearer semantics, easier aggregations

### Test Coverage
- ✅ **What's tested**: Keys, statuses, date logic, referential integrity
- ❌ **What's not**: Business logic edge cases (e.g., "Is $100K AOV realistic?")
- 🤔 **Solution**: Add custom tests as you learn your data

---

## If This Were Production...

### Monitoring & Alerts
```sql
-- Alert if revenue drops > 30% day-over-day
select
    current_date,
    coalesce(lag(daily_revenue) over (order by metric_date), 0) as prev_revenue,
    daily_revenue,
    ((daily_revenue - prev_revenue) / prev_revenue) * 100 as pct_change
from kpi_daily_metrics
where pct_change < -30
```

### Incremental Snapshots
```sql
-- dbt snapshot for slowly changing dimensions
{% snapshot dim_customer_scd2_snapshot %}
  select * from {{ ref('stg_customers') }}
  where true
{% endsnapshot %}
```

### Access Control (dbt Cloud)
```yaml
# Restrict analyst edit access
- name: finance_team
  grants:
    select: true
    update: false  # Read-only
    delete: false
```

### Data Freshness SLAs
```yaml
freshness:
  warn_after: {count: 12, period: hour}  # Alert Slack
  error_after: {count: 24, period: hour} # Page oncall
loaded_at_field: _loaded_at
```

### Lineage Tracking
- **dbt DAG**: See which models depend on which sources
- **dbt Artifacts**: Export to data governance tools (Alation, Collibra)
- **Audit Logging**: Track who ran what model when

### CI/CD Pipeline (GitHub Actions)
```yaml
# Run dbt on every PR
- dbt seed
- dbt run
- dbt test  # Fail PR if tests fail
- dbt docs generate
```

---

## Directory Examples

### What's in `seeds/`?
```csv
customer_id,email,first_name,last_name,signup_date
C001,john@email.com,John,Smith,2023-01-15
C002,jane@email.com,Jane,Doe,2023-02-20
```
→ Run `dbt seed` to load into database

### What's in `models/staging/`?
- Clean, standardized data
- Add derived fields (full_name = first_name + last_name)
- Light transformations
- Single source per model

### What's in `models/marts/`?
- Optimized for analysis
- Fact/dimension pattern
- Ready for dashboards
- Pre-computed aggregations

### What's in `tests/`?
- SQL queries that fail if data is wrong
- Named `test_*.sql`
- Run with `dbt test`
- Output: PASS or FAIL

---

## Quick Reference: Common dbt Commands

```bash
# Development
dbt run                          # Build all models
dbt test                         # Run all tests
dbt docs generate && dbt docs serve  # View docs

# Debugging
dbt parse                        # Check YAML syntax
dbt compile                      # Compile without running
dbt run --select model_name      # Build single model
dbt test --select dimension_name # Test single model

# Ci/CD
dbt run --select state:modified+ # Run modified + downstream
dbt test --select tag:critical   # Run critical tests only
dbt snapshot                     # Run SCD snapshots

# Cleanup
dbt clean                        # Remove compiled artifacts
```

---

## Key Takeaways

1. **Dimensional modeling is about clarity**: Star schemas make analysis intuitive
2. **SCD2 preserves history**: Essential for audits and temporal analysis
3. **KPIs in code prevent confusion**: One source of truth for metric definitions
4. **Tests catch errors early**: Prevent dashboard outages from bad data
5. **Documentation is a feature**: dbt docs == your data dictionary
6. **Layering is about reusability**: Sources → Staging → Intermediate → Marts

---

## Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [Dimensional Modeling (Ralph Kimball)](https://en.wikipedia.org/wiki/Dimensional_modeling)
- [Slowly Changing Dimensions](https://en.wikipedia.org/wiki/Slowly_changing_dimension)
- [Analytics Engineering (Silicon Valley Data Science)](https://www.siliconvalleydatascience.com/analytics-engineering-guide/)

---

## Support

Questions? Issues? Check:
1. `dbt debug` - Verify connection
2. `dbt parse` - Check YAML syntax
3. `dbt run --debug` - Verbose SQL logging
4. dbt Slack Community - [link](https://slack.getdbt.com/)

---

**Last Updated**: May 2026  
**Owner**: Analytics Engineering Team  
**Status**: Production Ready ✅