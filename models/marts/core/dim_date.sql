{{
    config(
        materialized='table',
        alias='dim_date',
        description='Date dimension for time-series analysis - conformed across all fact tables'
    )
}}

-- Generate date dimension from order dates
with date_range as (
    select
        generate_series(
            date '2023-01-01',
            date '2025-12-31',
            interval '1 day'
        ) as calendar_date
),

enriched as (
    select
        calendar_date,
        extract(year from calendar_date) as year,
        extract(month from calendar_date) as month,
        extract(day from calendar_date) as day,
        extract(quarter from calendar_date) as quarter,
        extract(week from calendar_date) as week_of_year,
        extract(dayofweek from calendar_date) as day_of_week,
        to_char(calendar_date, 'Month') as month_name,
        to_char(calendar_date, 'DY') as day_name,
        case
            when extract(dayofweek from calendar_date) in (1, 7) then true
            else false
        end as is_weekend,
        case
            when extract(month from calendar_date) in (11, 12) then true
            else false
        end as is_holiday_season,
        date_trunc('year', calendar_date) as fiscal_year_start,
        date_trunc('month', calendar_date) as fiscal_month_start
    from date_range
)

select
    {{ dbt_utils.generate_surrogate_key(['calendar_date']) }} as date_key,
    calendar_date as date,
    year,
    month,
    day,
    quarter,
    week_of_year,
    day_of_week,
    month_name,
    day_name,
    is_weekend,
    is_holiday_season,
    fiscal_year_start,
    fiscal_month_start,
    -- Fiscal periods
    case
        when month <= 3 then 'Q1'
        when month <= 6 then 'Q2'
        when month <= 9 then 'Q3'
        else 'Q4'
    end as fiscal_quarter,
    case
        when month <= 6 then 'H1'
        else 'H2'
    end as fiscal_half
from enriched
order by calendar_date