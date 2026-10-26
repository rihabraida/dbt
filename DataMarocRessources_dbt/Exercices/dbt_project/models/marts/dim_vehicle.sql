select
    vehicle_id,
    driver_id,
    make,
    model,
    plate_number,
    vehicle_type
from {{ ref('stg_vehicles') }}