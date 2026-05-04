{{
    config(
        tags=['scd2', 'critical']
    )
}}

-- Test: SCD2 no overlapping valid ranges
-- Business logic: Customer versions should not have overlapping valid_from and valid_to ranges
select customer_id, valid_from, valid_to
from {{ ref('dim_customer_scd2') }} a
where exists (
    select 1
    from {{ ref('dim_customer_scd2') }} b
    where a.customer_id = b.customer_id
        and a.customer_key != b.customer_key
        and a.valid_from < b.valid_to
        and (a.valid_to is null or a.valid_to > b.valid_from)
)