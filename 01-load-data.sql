-- 01-load-data.sql

.headers on
.mode csv

drop table if exists numbers;

.import data/numbers.csv numbers

drop table if exists mock_data_1;
drop table if exists mock_data_2;
drop table if exists mock_data_3;
drop table if exists mock_data_4;
drop table if exists mock_data_5;

.import data/MOCK_DATA-1.csv mock_data_1
.import data/MOCK_DATA-2.csv mock_data_2
.import data/MOCK_DATA-3.csv mock_data_3
.import data/MOCK_DATA-4.csv mock_data_4
.import data/MOCK_DATA-5.csv mock_data_5

.mode column

select 'mock_data_1' as tbl, count(*) as rows from mock_data_1 union all
select 'mock_data_2' as tbl, count(*) as rows from mock_data_2 union all
select 'mock_data_3' as tbl, count(*) as rows from mock_data_3 union all
select 'mock_data_4' as tbl, count(*) as rows from mock_data_4 union all
select 'mock_data_5' as tbl, count(*) as rows from mock_data_5;

drop table if exists name_id_map;

create table name_id_map
as
select min(id) as id, first_name as name
from (
    select * from mock_data_1 union all
    select * from mock_data_2 union all
    select * from mock_data_3 union all
    select * from mock_data_4 union all
    select * from mock_data_5
)
group by first_name;

drop table if exists country_map;

create table country_map
as
select substr(country, 1, 1) as country_first_letter, min(country) as country
from (
    select * from mock_data_1 union all
    select * from mock_data_2 union all
    select * from mock_data_3 union all
    select * from mock_data_4 union all
    select * from mock_data_5
)
group by substr(country, 1, 1);

drop table if exists mock_data;

CREATE TABLE mock_data (
  row_id INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id TEXT,
  name TEXT,
  product TEXT,
  country TEXT,
  active_from DATE,
  active_to DATE
);

.mode column

insert into mock_data (
    account_id, name, product, country, active_from, active_to
)
select m.id, d.first_name, d.product, c.country, d.active_from, date(d.active_from, '+'||d.days_active||' days') active_to
from (
    select * from mock_data_1 union all
    select * from mock_data_2 union all
    select * from mock_data_3 union all
    select * from mock_data_4 union all
    select * from mock_data_5
) d
inner join name_id_map m
on d.first_name = m.name
inner join country_map c
on substr(d.country, 1, 1) = c.country_first_letter
;

.mode column

select
    count(*) as row_count,
    count(distinct account_id) as account_id_count,
    count(distinct product) as product_count,
    count(distinct country) as country_count,
    min(active_from) as min_active_from,
    max(active_from) as max_active_from,
    min(active_to) as min_active_to,
    max(active_to) as max_active_to
from mock_data;

-- date dimension from 2015-01-01 to 2021-12-31

-- sqlite> select julianday('2021-08-31'), julianday('2015-01-01'), julianday('2021-08-31') - julianday('2015-01-01');
-- julianday('2021-08-31')  julianday('2015-01-01')  julianday('2021-08-31') - julianday('2015-01-01')
-- -----------------------  -----------------------  -------------------------------------------------
-- 2459457.5                2457023.5                2434.0

drop table if exists date_dim;

create table date_dim
as
select
    cast(number as int)+2457022 as date_id,
    date('2014-12-31', '+'||number||' days') as day_date,
    date('2014-12-31', '+'||number||' days','-1 month') as month_ago_date,
    date('2014-12-31', '+'||number||' days','-30 days') as thirty_days_ago_date,
    date('2014-12-31', '+'||number||' days') like '________01' as is_month_start,
    date('2014-12-31', '+'||(number+1)||' days') like '________01' as is_month_end
from numbers
where cast(number as int) < 2558
order by cast(number as int) asc;

.mode column

select julianday(day_date) as julian, date_id, day_date, is_month_start, is_month_end, month_ago_date, thirty_days_ago_date
from date_dim
where day_date < '2015-01-05'
or day_date > '2021-12-27'
order by 1;

-- julian      date_id     day_date
-- ----------  ----------  ----------
-- 2457023.5   2457023     2015-01-01
-- 2457024.5   2457024     2015-01-02
-- 2457025.5   2457025     2015-01-03
-- 2457026.5   2457026     2015-01-04
-- 2459576.5   2459576     2021-12-28
-- 2459577.5   2459577     2021-12-29
-- 2459578.5   2459578     2021-12-30
-- 2459579.5   2459579     2021-12-31

