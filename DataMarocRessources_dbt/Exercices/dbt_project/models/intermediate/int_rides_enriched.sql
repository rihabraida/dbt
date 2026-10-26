
select
    rides.ride_id,
    rides.driver_id,
    rides.pickup_zone_id,
    rides.dropoff_zone_id,
    rides.distance_km,
    rides.fare_amount,
    rides.requested_at,
    vehicles.vehicle_id,
    drivers.rating,
    {{ rating_bracket('drivers.rating') }} as rating_bracket

from {{ ref('stg_ride_events') }} as rides

left join {{ ref('drivers_snapshot') }} as drivers
    on rides.driver_id = drivers.driver_id
    and drivers.dbt_valid_to is null

left join {{ ref('stg_vehicles') }} as vehicles
    on rides.driver_id = vehicles.driver_id