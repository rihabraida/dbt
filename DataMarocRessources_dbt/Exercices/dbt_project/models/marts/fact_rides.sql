{{
    config(
        materialized='incremental',
        unique_key='ride_id',
        incremental_strategy='merge'
    )
}}

select
    ride_id,
    driver_id,
    vehicle_id,
    pickup_zone_id,
    dropoff_zone_id,
    distance_km,
    fare_amount,
    requested_at,
    rating,
    rating_bracket
from {{ ref('int_rides_enriched') }}

{% if is_incremental() %}
where requested_at > (
    select coalesce(
        max(requested_at),
        timestamp '1900-01-01'
    )
    from {{ this }}
)
{% endif %}