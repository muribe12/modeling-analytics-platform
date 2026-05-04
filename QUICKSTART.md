# QUICKSTART: Running the Analytics Project

## 60-Second Setup

### Prerequisites
```bash
# Install dbt (requires Python 3.8+)
pip install dbt-core

# Install database adapter (example for DuckDB, local testing)
pip install dbt-duckdb

# Or for your production database:
# pip install dbt-snowflake
# pip install dbt-bigquery
# pip install dbt-redshift
```

### Step 1: Configure Database Connection
```bash
# macOS/Linux
mkdir ~/.dbt
cat > ~/.dbt/profiles.yml << EOF
analytics_modeling_layer:
  target: dev
  outputs:
    dev:
      type: duckdb  # or snowflake, bigquery, etc.
      path: 'analytics.duckdb'  # Local file for DuckDB
      # If using cloud DB, add credentials instead
EOF

# Windows (PowerShell)
mkdir $env:USERPROFILE\.dbt -Force
# Edit $env:USERPROFILE\.dbt\profiles.yml with same content
```

### Step 2: Initialize Project
```bash
cd analytics-modeling-layer
dbt debug  # ✅ Should show "all checks passed"
```

### Step 3: Run Full Pipeline
```bash
# Load seed data from CSVs
dbt seed
# ✅ Output: Loaded 7 seeds into analytics_db.analytics_layer

# Build all models
dbt run
# ✅ Output: 21 models built successfully

# Run all tests
dbt test
# ✅ Output: 10 tests passed

# Generate documentation
dbt docs generate
dbt docs serve  # Opens http://localhost:8000
```

---

## What Just Happened?

### 1. Seeds Loaded (CSVs → Database)
```
raw_customers.csv         → raw_customers table (20 rows)
raw_products.csv          → raw_products table (20 rows)
raw_orders.csv            → raw_orders table (60 rows)
raw_order_items.csv       → raw_order_items table (182 rows)
raw_stores.csv            → raw_stores table (3 rows)
raw_categories.csv        → raw_categories table (2 rows)
raw_subcategories.csv     → raw_subcategories table (12 rows)
```

### 2. Models Built (7 layers)

#### Staging (stg_*)
- `stg_customers` - Cleaned customer data
- `stg_products` - Products with margin calculations
- `stg_orders` - Orders with derived flags
- `stg_order_items` - Line items with calculations
- `stg_stores` - Store metadata
- `stg_categories`, `stg_subcategories` - Taxonomies

#### Intermediate (int_*)
- `int_product_snowflake` - Snowflake schema example
- `int_order_items_enriched` - Joins product + order data

#### Marts - Dimensions (dim_*)
- `dim_customer_scd1` - Current customer state only
- `dim_customer_scd2` - Full customer history (SCD Type 2 demo)
- `dim_product_star` - Denormalized product (Star schema)
- `dim_product_snowflake` - Normalized product (Snowflake schema)
- `dim_store` - Store locations
- `dim_date` - Date dimension (2023-2025)

#### Marts - Facts (fact_*)
- `fact_orders` - Order-level metrics
- `fact_order_items` - Line-item metrics

#### Marts - Reports (rpt_*)
- `rpt_product_performance` - Product KPIs
- `rpt_customer_performance` - Customer KPIs

#### Marts - Metrics (kpi_*)
- `kpi_catalog` - KPI definitions
- `kpi_daily_metrics` - Daily snapshots

### 3. Tests Ran (10 total)
✅ Unique/not-null on all keys  
✅ Referential integrity (no orphans)  
✅ Revenue ≥ 0  
✅ Profit ≤ revenue  
✅ SCD2 no overlapping dates  
✅ SCD2 one current per customer  
✅ Order date ≥ signup date  
✅ Accepted values (status, etc.)  

### 4. Documentation Generated
- dbt docs site with full lineage
- Model descriptions and column docs
- Test results and coverage report

---

## Verify Installation

### Check Key Tables
```sql
-- Connect to your database and run:
select count(*) as order_count from fact_orders;
select count(*) as customer_count from dim_customer_scd1;
select count(*) as profit_margin from rpt_product_performance;
```

### Check dbt Artifacts
```bash
# These files created by dbt:
ls -la target/
# manifest.json - full DAG
# catalog.json - table/column metadata
# compiled/ - compiled SQL
```

---

## Common Tasks

### Run Only Staging Models
```bash
dbt run --select staging
# Materializes: stg_customers, stg_products, etc.
```

### Run Only Tests
```bash
dbt test
# Runs all tests in tests/ folder

dbt test --select tag:critical
# Runs only critical tests (faster)
```

### Run Specific Model
```bash
dbt run --select fact_orders
# Also builds upstream dependencies automatically
```

### Debug a Failed Model
```bash
dbt run --select fact_orders --debug
# Shows compiled SQL + detailed error messages

dbt parse
# Checks YAML syntax without running SQL
```

### Rebuild Everything from Scratch
```bash
dbt clean                    # Remove target/ folder
dbt deps                     # Reinstall packages
dbt seed --full-refresh      # Reload all CSVs
dbt run --full-refresh       # Rebuild all models
dbt test                     # Re-run tests
```

---

## Data Lineage Example

### What happens when you run `dbt run --select fact_orders`?

```
dbt identifies upstream dependencies:
  fact_orders
    ├── stg_orders (view)
    │   └── raw_orders (seed)
    ├── stg_order_items (view)
    │   └── raw_order_items (seed)
    ├── stg_products (view)
    │   └── raw_products (seed)
    └── stg_stores (view)
        └── raw_stores (seed)

dbt then builds in dependency order:
  1. Sources/seeds already exist (no build needed)
  2. Build stg_orders
  3. Build stg_order_items
  4. Build stg_products
  5. Build stg_stores
  6. Build fact_orders

Output: fact_orders table ready for analysis
```

### View Full DAG (Directed Acyclic Graph)
```bash
dbt docs generate
dbt docs serve
# Opens http://localhost:8000 with interactive graph
```

---

## Troubleshooting

### `dbt debug` fails - "Connection refused"
```
Problem: Database not running or credentials wrong
Solution:
  1. Verify database is running
  2. Check profiles.yml credentials
  3. Test connection manually (psql, mysql, etc.)
```

### `dbt seed` fails - "File not found"
```
Problem: Running from wrong directory
Solution: cd analytics-modeling-layer && dbt seed
```

### `dbt run` fails - "Column doesn't exist"
```
Problem: Upstream model changed, schema mismatch
Solution:
  1. dbt compile --select upstream_model
  2. Check if columns renamed/deleted
  3. Update downstream model reference
```

### Test fails - "Found 5 records"
```
Problem: Data violates test condition
Solution:
  1. View failed query in logs/debug.log
  2. Inspect source data: select * from raw_* where [condition]
  3. Fix either test logic or source data
```

### Performance: Slow dbt run
```
Problem: Too many models or large data
Solution:
  1. Run only needed: dbt run --select tag:critical
  2. Add --threads 8 (if database supports)
  3. Check dbt logs for specific bottleneck
```

---

## Next Steps After Setup

### 1. Explore the Data
```bash
# View interactive documentation
dbt docs serve

# Or query directly:
select * from fact_orders limit 10;
select * from dim_customer_scd1 limit 5;
select * from kpi_catalog;
```

### 2. Review Models
```bash
# Key files to understand:
cat models/marts/core/fact_orders.sql
cat models/marts/core/dim_customer_scd2.sql
cat models/marts/metrics/kpi_catalog.sql
```

### 3. Run Specific Analyses
```bash
-- Revenue by product category
select
    category,
    sum(net_line_total) as total_revenue,
    count(distinct order_id) as order_count
from fact_order_items
group by category
order by total_revenue desc;

-- Customer LTV by acquisition channel
select
    acquisition_channel,
    count(distinct customer_id) as customer_count,
    round(sum(total_revenue) / count(distinct customer_id), 2) as avg_ltv
from rpt_customer_performance
group by acquisition_channel;
```

### 4. Understand Dimensional Models
- Read [MODELING_DECISIONS.md](MODELING_DECISIONS.md)
- Understand Star vs. Snowflake trade-offs
- Learn when to use SCD Type 1 vs Type 2

### 5. Deep Dive into KPIs
- Read [KPI_DEFINITIONS.md](KPI_DEFINITIONS.md)
- Understand each KPI's formula and grain
- Learn how to combine KPIs in dashboards

---

## Connect to BI Tool

### Tableau
```
1. Data Source → New Connection → Your Database
2. Connect to fact_orders, dim_customer_scd1, dim_product_star
3. Drag fields to rows/columns
4. Create KPI cards from kpi_catalog
```

### Looker (LookML)
```
view: fact_orders {
  sql_table_name: fact_orders ;;
  
  dimension: order_id {
    primary_key: yes
    sql: ${TABLE}.order_id ;;
  }
  
  measure: total_revenue {
    type: sum
    sql: ${TABLE}.total_amount ;;
  }
}
```

### Power BI
```
1. Get Data → Database → Your Database
2. Choose fact_orders, dimensions
3. Create relationships (order_id → customer_id, etc.)
4. Build visuals using KPI definitions
```

---

## Production Checklist

Before deploying to production:

- [ ] All tests pass (`dbt test`)
- [ ] Data freshness configured (see `dbt_project.yml`)
- [ ] Incremental models implemented (if data > 10M rows)
- [ ] Documentation complete (all models have descriptions)
- [ ] KPI definitions validated with Finance/Analytics stakeholders
- [ ] Access control implemented (who can see what data?)
- [ ] Monitoring/alerts set up (if daily SLA required)
- [ ] dbt Cloud or similar scheduled (for daily/weekly runs)
- [ ] Backups configured (for prod database)
- [ ] Disaster recovery tested (can we rebuild?)

---

## File Structure Recap

```
analytics-modeling-layer/
├── README.md                          ← Start here!
├── QUICKSTART.md                      ← You are here
├── MODELING_DECISIONS.md              ← Architecture decisions
├── KPI_DEFINITIONS.md                 ← Business metrics
├── dbt_project.yml                    ← dbt config
├── packages.yml                       ← External dependencies
│
├── seeds/                             ← Sample data (CSVs)
├── models/
│   ├── sources/ecommerce_sources.yml  ← Data definitions
│   ├── staging/                       ← Clean data layer
│   ├── intermediate/                  ← Business logic
│   └── marts/
│       ├── core/                      ← Fact/Dimension tables
│       ├── product/                   ← Product reports
│       └── metrics/                   ← KPI definitions
│
├── tests/                             ← Data quality tests
└── target/                            ← Generated artifacts
    ├── compiled/                      ← Compiled SQL
    └── manifest.json                  ← Full DAG
```

---

## Success Criteria

✅ You've succeeded if:

1. `dbt run` completes with 21 models ✅
2. `dbt test` passes all 10 tests ✅
3. `dbt docs serve` loads without error ✅
4. You can query `select * from fact_orders` and get 60 rows ✅
5. You can query `select * from kpi_catalog` and see all KPIs ✅
6. Documentation shows full lineage graph ✅

---

## Support & Resources

- **dbt Documentation**: https://docs.getdbt.com/
- **dbt Slack Community**: https://slack.getdbt.com/
- **This Project README**: [README.md](README.md)
- **Modeling Decisions**: [MODELING_DECISIONS.md](MODELING_DECISIONS.md)
- **KPI Reference**: [KPI_DEFINITIONS.md](KPI_DEFINITIONS.md)

---

**Happy Analyzing! 📊**