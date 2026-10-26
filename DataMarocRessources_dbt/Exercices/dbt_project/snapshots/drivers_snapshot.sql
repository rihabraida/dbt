{% snapshot drivers_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='driver_id',
        strategy='check',
        check_cols=['rating']
    )
}}

select
    driver_id,
    driver_name,
    phone,
    city,
    rating,
    joined_date
from {{ ref('stg_drivers') }}

{% endsnapshot %}