-- 02-active-subs.sql

.header on
.mode column

.echo on

-- mock data looks like

select * from mock_data limit 10;

-- how many active on 2021-01-01?

select count(distinct account_id) as active_count
from mock_data
where date(active_from) <= date('2021-01-01')
and date(active_to) >= date('2021-01-01');

-- how many active on 2021-01-01 by product?

select product, count(distinct account_id) as active_count
from mock_data
where date(active_from) <= date('2021-01-01')
and date(active_to) >= date('2021-01-01')
group by product
order by product asc
limit 10;

-- how many have more than 1 product on that date?

select account_id, count(distinct product) as product_count
from mock_data
where date(active_from) <= date('2021-01-01')
and date(active_to) >= date('2021-01-01')
group by account_id
having count(distinct product) > 1
limit 5;

-- how many active on 2021-01-31?

select count(distinct account_id) as active_count
from mock_data
where date(active_from) <= date('2021-01-31')
and date(active_to) >= date('2021-01-31');

-- incorrect churn rate. not cohort analysis.

select active_at_start, active_at_end, cast(active_at_end-active_at_start as real) / active_at_start as churn
from (
    select
        (
            select count(distinct account_id) as active_count
            from mock_data
            where date(active_from) <= date('2021-01-01')
            and date(active_to) >= date('2021-01-01')
        ) as active_at_start,
        (
            select count(distinct account_id) as active_count
            from mock_data
            where date(active_from) <= date('2021-01-31')
            and date(active_to) >= date('2021-01-31')
        ) as active_at_end
);

-- another incorrect churn. misses product changes, gaps.

select active_at_start, inactive_at_end, cast(inactive_at_end as real) / active_at_start as churn
from (
    select
        (
            select count(distinct account_id) as active_count
            from mock_data
            where date(active_from) <= date('2021-01-01')
            and date(active_to) >= date('2021-01-01')
        ) as active_at_start,
        (
            select count(distinct account_id) as active_count
            from mock_data
            -- check active at start
            where date(active_from) <= date('2021-01-01')
            and date(active_to) >= date('2021-01-01')
            -- and NOT active at end
            and date(active_to) < date('2021-01-31')
        ) as inactive_at_end
);

-- correct churn rate.

select active_at_start.account_id, active_at_end.account_id
from (
    select distinct account_id as account_id
    from mock_data
    where date(active_from) <= date('2021-01-01')
    and date(active_to) >= date('2021-01-01')
) active_at_start
left outer join (
    select distinct account_id as account_id
    from mock_data
    where date(active_from) <= date('2021-01-31')
    and date(active_to) >= date('2021-01-31')
) active_at_end
on active_at_start.account_id = active_at_end.account_id
where active_at_start.account_id in (
    'c2027e1a-33d4-4d1d-8bcb-8f1316f70df6',
    '4929fd22-d7d0-46bd-b97a-a6812d6a0fb1',
    'f14fb328-f587-4a32-8a3c-06bff7f8bd3a',
    '6fab13c1-68ab-430c-b6b9-52c90dfe0303',
    'b71933b0-4181-4484-8022-d35758f7211f',
    '6f77d65a-b488-4c84-8134-929aab9ac32c',
    'bfeec53b-b551-4b31-9ad7-c01c3655a552'
);

select
    active_at_start,
    active_at_end,
    active_at_start - active_at_end as inactive_at_end,
    (active_at_start - active_at_end) / cast(active_at_start as real) as churn
from (
    select count(active_at_start.account_id) as active_at_start, count(active_at_end.account_id) as active_at_end
    from (
        select distinct account_id as account_id
        from mock_data
        where date(active_from) <= date('2021-01-01')
        and date(active_to) >= date('2021-01-01')
    ) active_at_start
    left outer join (
        select distinct account_id as account_id
        from mock_data
        where date(active_from) <= date('2021-01-31')
        and date(active_to) >= date('2021-01-31')
    ) active_at_end
    on active_at_start.account_id = active_at_end.account_id
);

.echo off
