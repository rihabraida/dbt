select
    cast(ride_id as text) as ride_id,
    cast(driver_id as integer) as driver_id,
    cast(pickup_zone_id as integer) as pickup_zone_id,
    cast(dropoff_zone_id as integer) as dropoff_zone_id,
    cast(distance_km as numeric(6, 1)) as distance_km,
    cast(fare_amount as numeric(10, 2)) as fare_amount,
    cast(requested_at as timestamp) as requested_at
from {{ source('raw', 'raw_ride_events') }}
where cast(requested_at as timestamp)
    >= cast('{{ var("start_date") }}' as timestamp)