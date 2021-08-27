-- 04-churn-rolling-window.sql

.header on
.mode column

.echo on

-- churn rate time series.

with dates as (
    select *
    from date_dim
    where day_date between date('2021-07-01') and date('2021-09-01')
), thirty_days_ago as (
    select d.date_id, m.row_id
    from dates d
    left outer join mock_data m
    on date(m.active_from) <= date(d.thirty_days_ago_date)
    and date(d.thirty_days_ago_date) <= date(m.active_to)
), current as (
    select d.date_id, m.row_id
    from dates d
    left outer join mock_data m
    on date(m.active_from) <= date(d.day_date)
    and date(d.day_date) <= date(m.active_to)
), joined as (
    select date_id, row_id, max(thirty_days_ago_row_id) as thirty_days_ago_row_id, max(current_row_id) as current_row_id
    from (
        select date_id, row_id, row_id as thirty_days_ago_row_id, null as current_row_id
        from thirty_days_ago
        union all
        select date_id, row_id, null as thirty_days_ago_row_id, row_id as current_row_id
        from current
    )
    group by date_id, row_id
), offset_active as (
    select
        d.day_date,
        base.account_id,
        thirty_days_ago.account_id as thirty_days_ago_account_id,
        current.account_id as current_account_id,
        base.product,
        base.country
    from joined j
    inner join date_dim d
    on j.date_id = d.date_id
    left outer join mock_data base
    on j.row_id = base.row_id
    left outer join mock_data thirty_days_ago
    on j.thirty_days_ago_row_id = thirty_days_ago.row_id
    left outer join mock_data current
    on j.current_row_id = current.row_id
), distinct_offset_active as (
    select
        day_date,
        account_id,
        max(thirty_days_ago_account_id) as thirty_days_ago_account_id,
        max(current_account_id) as current_account_id
    from offset_active
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
from churn_data
order by day_date;

.echo off
