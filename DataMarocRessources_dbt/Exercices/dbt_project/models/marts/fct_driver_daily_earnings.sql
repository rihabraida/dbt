with daily_earnings as (
    select
        driver_id,
        cast(requested_at as date) as ride_date,
        sum(fare_amount) as daily_earnings
    from {{ ref('fact_rides') }}
    group by driver_id, cast(requested_at as date)
)

select
    driver_id,
    ride_date,
    daily_earnings,

    sum(daily_earnings) over (
        partition by driver_id
        order by ride_date
        rows between unbounded preceding and current row
    ) as running_total,

    dense_rank() over (
        partition by ride_date
        order by daily_earnings desc
    ) as driver_rank_that_day

from daily_earnings