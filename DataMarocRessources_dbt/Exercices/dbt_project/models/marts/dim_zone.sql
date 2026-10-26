select
    zone_id,
    zone_name,
    city
from {{ ref('stg_zones') }}