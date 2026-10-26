select
    cast(vehicle_id as integer) as vehicle_id,
    cast(driver_id as integer) as driver_id,
    cast(make as text) as make,
    cast(model as text) as model,
    cast(plate_number as text) as plate_number,
    cast(vehicle_type as text) as vehicle_type
from {{ source('raw', 'raw_vehicles') }}