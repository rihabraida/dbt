# InDrive Analytics with dbt

This project transforms four raw CSV datasets into tested PostgreSQL models for ride analytics.

**Data flow**

```text
CSV seeds -> raw tables -> staging views
                            |-> driver snapshot (rating history)
                            |-> vehicle and zone dimensions
                            |-> ephemeral enriched rides -> incremental fact_rides
                                                           -> daily driver earnings
```

Raw tables live in `raw`, models in `dbt_dev`, and the driver snapshot in `snapshots`. The folders `staging`, `intermediate`, and `marts` organize project files; they are not separate database schemas in this configuration.

**Run the project**

Start the containers from the parent `Exercices` folder:

```bash
docker compose up -d
```

Activate your Python environment, install `dbt-postgres`, and configure `~/.dbt/profiles.yml` using `profiles.yml.example`. Then run these commands from this `dbt_project` folder:

```bash
dbt debug
dbt seed
dbt run --select staging
dbt snapshot
dbt run
dbt test
```

The staging ride model reads `var('start_date')`, whose default is `2026-01-01` in `dbt_project.yml`. It keeps rides requested on or after that date.

`dbt source freshness` checks the latest `requested_at` in raw ride events, warning after 24 hours and failing after 48 hours. The supplied September 2026 sample will therefore fail this check when it is older than the thresholds; that is separate from the model tests.

**Q4 — Grain of the fact table**

Each row in `fact_rides` represents one ride, uniquely identified by `ride_id`.

The fact contains dimension IDs, the requested timestamp, fare, distance, and the driver rating and bracket calculated when that ride is processed.

**Q5 — Why Type 1 for vehicles and zones?**

Type 1 is sufficient because this exercise needs current vehicle and zone attributes, without analyzing their previous versions.

`dim_vehicle` and `dim_zone` are table models rebuilt from their staging views. They provide descriptive information that rides reference through IDs.

**Q6 — Why a snapshot for drivers?**

Driver ratings can change, and a snapshot preserves previous ratings instead of replacing them. `drivers_snapshot` uses `driver_id` to identify a driver and `strategy='check'` on `rating` to detect changes.

When a change is detected, dbt closes the previous version by setting `dbt_valid_to` and adds a current version with `dbt_valid_to` set to SQL `NULL`. Changes are detected only when `dbt snapshot` runs; it cannot recover earlier or unobserved changes.

Vehicles and zones do not need this history for the chosen analysis, so simple Type 1 dimensions are enough. Drivers are also a dimension conceptually; this project uses their snapshot directly rather than adding a separate `dim_driver` model.

**Q7 — Why LEFT JOIN in the intermediate model?**

`int_rides_enriched` joins rides to the current driver snapshot version (`dbt_valid_to is null`) and to vehicles using `LEFT JOIN`. This keeps rides whose driver is missing, allowing the fact's driver relationship test to detect the invalid reference. An inner join would remove those rides and hide the problem.

The join uses the current observed rating, not the rating valid at the ride's historical timestamp. The vehicle join assumes one vehicle per driver in the supplied data; multiple matching vehicles would duplicate rides and violate the fact's grain.

**Q9 — Why a macro rather than a variable?**

`rating_bracket` generates reusable SQL classification logic: below 4.5 is `low`, 4.5 through 4.8 is `medium`, and above 4.8 is `high`. A missing rating produces SQL `NULL`.

A macro is appropriate because this is logic applied to a column. A variable supplies a value, such as the project's `start_date`.

**Q10 — What happens after changing a driver rating?**

After changing a raw rating and running `dbt snapshot`, the snapshot records a new version. Running `dbt run --select fact_rides` keeps the old ratings on previously stored rides because the incremental filter only selects `requested_at` values greater than the latest timestamp already in the fact.

The fact uses `unique_key='ride_id'` and the `merge` strategy, but merging can only update rows selected by that filter. Rating changes alone do not select older rides.

The flag that recalculates every ride using the current rating is:

```bash
dbt run --select fact_rides --full-refresh
```

This replaces ratings on existing fact rows; it does not make the fact a history table. The snapshot retains the rating versions. This simple date filter also misses late-arriving rides with timestamps at or before the existing maximum.

**Q12 — Which test catches a ride with a nonexistent driver?**

The expected failure is the `relationships` test on `fact_rides.driver_id`, referencing `stg_drivers.driver_id`. With a unique test ride ID and valid zone IDs, the other configured tests should still pass.

The LEFT JOIN preserves the invalid ride's original `driver_id`, so the relationship test can find it. After deleting the injected ride from the raw table, rebuild the fact with `--full-refresh` and run `dbt test` again. The current incremental logic does not propagate source deletions automatically.

**Q13 — Window-function mart**

`fct_driver_daily_earnings` has one row per driver per day. It sums `fare_amount` as daily earnings, calculates a running total per driver, and uses `dense_rank()` to rank drivers by earnings each day. Ties share a rank. Earnings here means gross fares, without commission or expense deductions.

This mart is a table and is fully rebuilt when its model runs.

**Q14 — Does the ephemeral model appear in lineage?**

Yes. `int_rides_enriched` appears in dbt's lineage because dbt tracks it as a model and records its dependencies. It creates no separate table or view: dbt embeds its SQL into the query for `fact_rides`.

```bash
dbt docs generate
dbt docs serve
```

Open `http://localhost:8080` and inspect the lineage for `fact_rides`.

**Validation evidence**

The existing `logs/dbt.log` records a successful full `dbt run`, followed by a successful `dbt test`:

```text
dbt run:  PASS=8  WARN=0 ERROR=0 SKIP=0 TOTAL=8
dbt test: PASS=18 WARN=0 ERROR=0 SKIP=0 TOTAL=18
```

The eight executed models are four staging views, three mart tables, and one incremental fact table. The ephemeral intermediate model creates no separate database object. The 18 tests cover staging primary keys, dimension and fact primary keys, accepted vehicle types, and driver and zone relationships.

To reproduce the final check after future changes:

```bash
dbt run && dbt test
```
