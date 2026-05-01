{% snapshot snap_customer_scd2 %}

{{
    config(
        strategy='timestamp',
        unique_key='customer_id',
        updated_at='updated_at',
        invalidate_hard_deletes=true,
        alias='snap_customer_scd2'
    )
}}

select
    customer_id,
    first_name,
    last_name,
    email,
    signup_date,
    customer_status,
    acquisition_channel,
    lifetime_value,
    region,
    country,
    full_name,
    is_active,
    acquisition_type,
    current_timestamp as updated_at
from {{ ref('stg_customers') }}

{% endsnapshot %}