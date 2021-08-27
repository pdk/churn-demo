-- 05-create-big-fact.sql

.header on
.mode column

-- .echo on
.echo off

drop table if exists big_fact;

create table big_fact
as
with dates as (
    select *
    from date_dim
    -- where day_date between date('2019-01-01') and date('2021-09-01')
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
    -- full outer join not supported by sqlite
    select date_id, row_id, max(thirty_days_ago_row_id) as thirty_days_ago_row_id, max(current_row_id) as current_row_id
    from (
        select date_id, row_id, row_id as thirty_days_ago_row_id, null as current_row_id
        from thirty_days_ago
        union all
        select date_id, row_id, null as thirty_days_ago_row_id, row_id as current_row_id
        from current
    )
    group by date_id, row_id
)
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
;

select count(*) from mock_data;

select count(*) from big_fact;

.echo off
