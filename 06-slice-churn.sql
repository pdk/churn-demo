-- 06-slice-churn.sql

.header on
.mode column

.echo on

-- get rolling churn rate for Ford

with distinct_offset_active as (
    select
        day_date,
        account_id,
        max(thirty_days_ago_account_id) as thirty_days_ago_account_id,
        max(current_account_id) as current_account_id
    from big_fact
    where day_date between date('2021-07-01') and date('2021-09-01')
    and product = 'Ford'
    group by
        day_date,
        account_id
), churn_data as (
    select
        day_date,
        count(distinct thirty_days_ago_account_id) as active_thirty_days_ago_count,
        count(distinct current_account_id) as current_active_count,
        count(distinct (case when thirty_days_ago_account_id is not null and current_account_id is not null then current_account_id end)) as remaining_count,
        count(distinct (case when thirty_days_ago_account_id is not null and current_account_id is null then thirty_days_ago_account_id end)) as churn_count,
        count(distinct (case when thirty_days_ago_account_id is null and current_account_id is not null then current_account_id end)) as acquired_count
    from distinct_offset_active
    group by day_date
)
select
    day_date,
    active_thirty_days_ago_count,
    current_active_count,
    active_thirty_days_ago_count - churn_count + acquired_count as check1,
    remaining_count + acquired_count as check2,
    remaining_count,
    churn_count,
    churn_count / cast(active_thirty_days_ago_count as real) as churn_rate,
    acquired_count,
    acquired_count / cast(active_thirty_days_ago_count as real) as acquisition_rate
from churn_data;

-- get rolling churn rate for Cambodia

with distinct_offset_active as (
    select
        day_date,
        account_id,
        max(thirty_days_ago_account_id) as thirty_days_ago_account_id,
        max(current_account_id) as current_account_id
    from big_fact
    where day_date between date('2021-07-01') and date('2021-09-01')
    and country = 'Cambodia'
    group by
        day_date,
        account_id
), churn_data as (
    select
        day_date,
        count(distinct thirty_days_ago_account_id) as active_thirty_days_ago_count,
        count(distinct current_account_id) as current_active_count,
        count(distinct (case when thirty_days_ago_account_id is not null and current_account_id is not null then current_account_id end)) as remaining_count,
        count(distinct (case when thirty_days_ago_account_id is not null and current_account_id is null then thirty_days_ago_account_id end)) as churn_count,
        count(distinct (case when thirty_days_ago_account_id is null and current_account_id is not null then current_account_id end)) as acquired_count
    from distinct_offset_active
    group by day_date
)
select
    day_date,
    active_thirty_days_ago_count,
    current_active_count,
    active_thirty_days_ago_count - churn_count + acquired_count as check1,
    remaining_count + acquired_count as check2,
    remaining_count,
    churn_count,
    churn_count / cast(active_thirty_days_ago_count as real) as churn_rate,
    acquired_count,
    acquired_count / cast(active_thirty_days_ago_count as real) as acquisition_rate
from churn_data;


-- get rolling churn rate by country

with distinct_offset_active as (
    select
        day_date,
        country,
        account_id,
        max(thirty_days_ago_account_id) as thirty_days_ago_account_id,
        max(current_account_id) as current_account_id
    from big_fact
    where day_date = date('2021-08-25')
    group by
        day_date,
        country,
        account_id
), churn_data as (
    select
        day_date,
        country,
        count(distinct thirty_days_ago_account_id) as active_thirty_days_ago_count,
        count(distinct current_account_id) as current_active_count,
        count(distinct (case when thirty_days_ago_account_id is not null and current_account_id is not null then current_account_id end)) as remaining_count,
        count(distinct (case when thirty_days_ago_account_id is not null and current_account_id is null then thirty_days_ago_account_id end)) as churn_count,
        count(distinct (case when thirty_days_ago_account_id is null and current_account_id is not null then current_account_id end)) as acquired_count
    from distinct_offset_active
    group by day_date, country
)
select
    day_date,
    country,
    active_thirty_days_ago_count,
    current_active_count,
    active_thirty_days_ago_count - churn_count + acquired_count as check1,
    remaining_count + acquired_count as check2,
    remaining_count,
    churn_count,
    churn_count / cast(active_thirty_days_ago_count as real) as churn_rate,
    acquired_count,
    acquired_count / cast(active_thirty_days_ago_count as real) as acquisition_rate
from churn_data
order by country;


.echo off
