# Navigation Guide

Welcome to the Analytics Modeling Layer! Here's how to navigate this comprehensive dbt project.

## 🎯 Start Here

**New to the project?** Start with these files in order:

1. **[README.md](README.md)** (START HERE)
   - 📖 Complete project overview
   - 🎓 Educational context
   - 🚀 60-second quick start
   - 📊 Data model explanation
   - 💡 Key concepts

2. **[QUICKSTART.md](QUICKSTART.md)** (SETUP)
   - 🔧 Step-by-step installation
   - ✅ Verification checks
   - ⚠️ Troubleshooting guide
   - 🎯 Common tasks

3. **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** (OVERVIEW)
   - 📋 Complete deliverables list
   - 📁 File structure
   - ✅ Quality assurance
   - 🎓 Learning outcomes

---

## 📚 Documentation by Audience

### For Data Analysts
1. **Start**: [README.md](README.md#star-schema) - Data Model section
2. **Learn**: [KPI_DEFINITIONS.md](KPI_DEFINITIONS.md) - All business metrics
3. **Explore**: dbt docs (run `dbt docs serve`)
4. **Query**: Connect to `fact_orders`, `rpt_customer_performance`

### For Data Engineers
1. **Start**: [MODELING_DECISIONS.md](MODELING_DECISIONS.md) - Architecture rationale
2. **Study**: [README.md](README.md#project-structure) - Project structure
3. **Implement**: Model files in `models/` directory
4. **Test**: Read `tests/` folder comments

### For Finance/Business Stakeholders
1. **Start**: [README.md](README.md#objective) - Executive summary
2. **Focus**: [KPI_DEFINITIONS.md](KPI_DEFINITIONS.md) - KPI specifications
3. **Use**: Query `kpi_catalog` or build dashboards
4. **Validate**: Work with Analytics team on metric definitions

### For dbt Beginners
1. **Start**: [README.md](README.md#data-model-overview) - Data model concepts
2. **Learn**: [MODELING_DECISIONS.md](MODELING_DECISIONS.md) - Best practices
3. **Practice**: Run models locally with [QUICKSTART.md](QUICKSTART.md)
4. **Explore**: Study model files in order: `staging/` → `intermediate/` → `marts/`

---

## 📁 File Organization Guide

### Core Documentation
```
/analytics-modeling-layer/
├── README.md                  ← Complete project guide (start here!)
├── QUICKSTART.md             ← Setup instructions
├── PROJECT_SUMMARY.md        ← Deliverables overview
├── MODELING_DECISIONS.md     ← Architecture decisions
├── KPI_DEFINITIONS.md        ← All 15 KPIs explained
├── INDEX.md                  ← You are here!
```

### Configuration
```
├── dbt_project.yml           ← dbt configuration
├── packages.yml              ← External dependencies
└── .gitignore               ← Git ignore patterns
```

### Data
```
seeds/
├── raw_customers.csv        ← 20 customer records
├── raw_products.csv         ← 20 product records
├── raw_orders.csv           ← 60 order records
├── raw_order_items.csv      ← 182 line items
├── raw_stores.csv           ← 3 store records
├── raw_categories.csv       ← 2 categories
├── raw_subcategories.csv    ← 12 subcategories
└── customer_updates.csv     ← SCD2 examples
```

### Models (21 total)
```
models/
├── sources/
│   └── ecommerce_sources.yml      ← Source definitions + freshness
│
├── staging/
│   ├── stg_customers.sql
│   ├── stg_products.sql
│   ├── stg_orders.sql
│   ├── stg_order_items.sql
│   ├── stg_stores.sql
│   ├── stg_categories.sql
│   ├── stg_subcategories.sql
│   └── staging_schema.yml
│
├── intermediate/
│   ├── int_product_snowflake.sql
│   ├── int_order_items_enriched.sql
│   └── intermediate_schema.yml
│
└── marts/
    ├── core/
    │   ├── dim_customer_scd1.sql      ← SCD Type 1
    │   ├── dim_customer_scd2.sql      ← SCD Type 2
    │   ├── dim_product_star.sql       ← Star schema
    │   ├── dim_product_snowflake.sql  ← Snowflake schema
    │   ├── dim_store.sql
    │   ├── dim_date.sql
    │   ├── fact_orders.sql
    │   ├── fact_order_items.sql
    │   └── marts_schema.yml
    │
    ├── product/
    │   ├── rpt_product_performance.sql
    │   └── rpt_customer_performance.sql
    │
    └── metrics/
        ├── kpi_catalog.sql           ← 15 KPI definitions
        ├── kpi_daily_metrics.sql
        └── metrics_schema.yml
```

### Tests (10 custom + built-in)
```
tests/
├── test_kpi_revenue_non_negative.sql
├── test_kpi_profit_validity.sql
├── test_scd2_no_overlaps.sql
├── test_scd2_one_current_per_customer.sql
├── test_fact_order_items_orphaned.sql
├── test_fact_orders_orphaned_customer.sql
├── test_order_status_accepted_values.sql
├── test_customer_status_accepted_values.sql
├── test_order_item_quantity_positive.sql
└── test_order_date_after_signup.sql
```

---

## 🔍 How to Find What You're Looking For

### "How do I run this project?"
→ [QUICKSTART.md](QUICKSTART.md)

### "I don't understand the data model"
→ [README.md - Data Model Overview](README.md#data-model-overview)

### "What is the difference between Star and Snowflake?"
→ [MODELING_DECISIONS.md - Star vs Snowflake](MODELING_DECISIONS.md#1-star-vs-snowflake-schema)

### "When should I use SCD Type 1 vs Type 2?"
→ [MODELING_DECISIONS.md - SCD Strategy](MODELING_DECISIONS.md#2-scd-type-1-vs-type-2-implementation)

### "What does this KPI mean?"
→ [KPI_DEFINITIONS.md](KPI_DEFINITIONS.md)

### "How do I query the data?"
→ [README.md - KPI Examples](README.md#kpi-consistency-example)

### "Why are there multiple product dimensions?"
→ [MODELING_DECISIONS.md](MODELING_DECISIONS.md) and [README.md](README.md#star-schema)

### "What tests are included?"
→ [PROJECT_SUMMARY.md - Test Coverage](PROJECT_SUMMARY.md#-test-coverage)

### "Where is the sample data?"
→ `seeds/` folder (7 CSV files)

### "I'm getting an error when running dbt"
→ [QUICKSTART.md - Troubleshooting](QUICKSTART.md#troubleshooting)

### "I want to learn dbt"
→ [MODELING_DECISIONS.md](MODELING_DECISIONS.md) for concepts + [README.md](README.md#layer-2-staging-modelsstaging) for patterns

---

## 📊 Data Model Navigation

### Understanding the Flow
```
Raw Data (CSV Seeds)
    ↓
Staging (stg_*) - Clean & standardize
    ↓
Intermediate (int_*) - Multi-source logic
    ↓
Marts (dim_*, fact_*) - Optimized for analytics
    ↓
Reports (rpt_*) - Pre-aggregated insights
    ↓
Metrics (kpi_*) - Business KPI definitions
```

### By Business Entity

**CUSTOMER ANALYSIS**
- Source: `raw_customers.csv`
- Staging: `stg_customers.sql`
- Dimension: `dim_customer_scd1.sql` (current) + `dim_customer_scd2.sql` (history)
- Report: `rpt_customer_performance.sql`
- KPIs: Total Customers, LTV, Repeat Rate, Conversion Rate

**PRODUCT ANALYSIS**
- Source: `raw_products.csv`
- Staging: `stg_products.sql`
- Dimension: `dim_product_star.sql` (primary) + `dim_product_snowflake.sql` (alternative)
- Report: `rpt_product_performance.sql`
- KPIs: Product Margin, Active Count, Products Per Order

**ORDER ANALYSIS**
- Sources: `raw_orders.csv`, `raw_order_items.csv`
- Staging: `stg_orders.sql`, `stg_order_items.sql`
- Facts: `fact_orders.sql` (order level), `fact_order_items.sql` (line level)
- KPIs: Total Revenue, AOV, Return Rate, Discount Rate

**STORE/LOCATION ANALYSIS**
- Source: `raw_stores.csv`
- Staging: `stg_stores.sql`
- Dimension: `dim_store.sql`
- Join point: `fact_orders.store_id`

**TIME ANALYSIS**
- Generated: Date range 2023-2025
- Dimension: `dim_date.sql` (conformed)
- Features: Fiscal quarters, weekends, holidays
- Used by: All fact tables via `date_key`

---

## 🧪 Testing Navigation

### What Gets Tested?

**Data Quality**
- Revenue non-negative (test_kpi_revenue_non_negative.sql)
- Profit validity (test_kpi_profit_validity.sql)
- Quantities positive (test_order_item_quantity_positive.sql)

**Referential Integrity**
- No orphaned order items (test_fact_order_items_orphaned.sql)
- No orphaned orders (test_fact_orders_orphaned_customer.sql)
- Category relationships (staging_schema.yml)

**Business Logic**
- Order dates ≥ signup dates (test_order_date_after_signup.sql)
- Accepted values for enums (test_*_accepted_values.sql)

**Slowly Changing Dimensions**
- No overlapping date ranges (test_scd2_no_overlaps.sql)
- Exactly one current version (test_scd2_one_current_per_customer.sql)

**Run Tests**
```bash
dbt test                                # All tests
dbt test --select tag:critical         # Critical only
dbt test --select dim_customer_scd1    # Specific model
```

---

## 📈 KPI Reference

All 15 KPIs defined in [KPI_DEFINITIONS.md](KPI_DEFINITIONS.md):

**Revenue** (3): Total Revenue, Total Profit, Profit Margin  
**Orders** (3): Total Orders, AOV, Return Rate  
**Customers** (4): Total Customers, LTV, Repeat Rate, Conversion Rate  
**Products** (3): Avg Margin, Active Count, Products Per Order  
**Operations** (2): Express Shipping %, Discount Rate  

Each KPI includes:
- Business definition
- SQL formula
- Grain (aggregation level)
- Owner + SLA
- Benchmark values

---

## 🚀 Running the Project

### Quick Commands
```bash
dbt seed                        # Load data
dbt run                         # Build models
dbt test                        # Run tests
dbt docs serve                  # View docs
```

### Selective Execution
```bash
dbt run --select staging        # Just staging
dbt test --select tag:critical # Critical tests
dbt docs generate               # Regenerate docs
```

See [QUICKSTART.md](QUICKSTART.md#common-tasks) for more commands.

---

## 📚 Learning Resources

### Within This Project
1. README.md - Comprehensive overview
2. MODELING_DECISIONS.md - Architecture decisions
3. KPI_DEFINITIONS.md - Metric specifications
4. Model comments in SQL files
5. Schema documentation (YAML files)

### External Resources
- dbt Documentation: https://docs.getdbt.com/
- Dimensional Modeling: https://en.wikipedia.org/wiki/Dimensional_modeling
- dbt Slack Community: https://slack.getdbt.com/

---

## ✅ Verification Checklist

After setup, verify:

- [ ] `dbt debug` passes
- [ ] `dbt seed` loads 7 files (392 total rows)
- [ ] `dbt run` builds 21 models
- [ ] `dbt test` passes 10+ custom tests
- [ ] `dbt docs serve` loads documentation
- [ ] Can query `select * from fact_orders` (60 rows)
- [ ] Can query `select * from kpi_catalog` (15 KPIs)

---

## 🎯 Project Goals

This project demonstrates:
- ✅ How dimensional modeling improves analytics
- ✅ When to use different schema patterns
- ✅ Implementing SCD Type 1 & 2
- ✅ Designing fact and dimension tables
- ✅ Defining business KPIs in code
- ✅ Comprehensive data quality testing
- ✅ Documentation as first-class artifact
- ✅ Production-ready dbt best practices

---

## 📞 Need Help?

| Question | Answer Location |
|----------|-----------------|
| "How do I run this?" | [QUICKSTART.md](QUICKSTART.md) |
| "What are these models?" | [README.md](README.md) |
| "Why this architecture?" | [MODELING_DECISIONS.md](MODELING_DECISIONS.md) |
| "What is this KPI?" | [KPI_DEFINITIONS.md](KPI_DEFINITIONS.md) |
| "What's included?" | [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) |
| "I got an error..." | [QUICKSTART.md#troubleshooting](QUICKSTART.md#troubleshooting) |

---

## 🎓 Recommended Reading Order

### For First-Time Setup
1. This file (you're reading it!)
2. [README.md](README.md) - Executive summary (5 min read)
3. [QUICKSTART.md](QUICKSTART.md) - Install & run (10 min)
4. [README.md](README.md#data-model-overview) - Data model (15 min)

### For Data Modeling Deep Dive
1. [MODELING_DECISIONS.md](MODELING_DECISIONS.md) - Decisions explained
2. [README.md](README.md#dimensional-modeling-star-schema) - Star schema
3. [README.md](README.md#slowly-changing-dimensions-scd) - SCD implementations
4. Model files: `models/marts/core/dim_*.sql`, `fact_*.sql`

### For KPI Understanding
1. [KPI_DEFINITIONS.md](KPI_DEFINITIONS.md) - Each KPI explained
2. `models/marts/metrics/kpi_catalog.sql` - Definitions in code
3. [README.md](README.md#kpi-definitions) - KPI overview

---

**Navigation Map Created**: May 2, 2026  
**Project Status**: ✅ COMPLETE  
**Happy Analyzing!** 📊