select
    cast(zone_id as integer) as zone_id,
    cast(zone_name as text) as zone_name,
    cast(city as text) as city
from {{ source('raw', 'raw_zones') }}