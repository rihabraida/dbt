select
    cast(driver_id as integer) as driver_id,
    cast(driver_name as text) as driver_name,
    cast(phone as text) as phone,
    cast(city as text) as city,
    cast(rating as numeric(3, 2)) as rating,
    cast(joined_date as date) as joined_date
from {{ source('raw', 'raw_drivers') }}