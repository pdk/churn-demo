# churn-demo

example sqlite to compute churn rate

to "run" the demo, do

    $ sqlite3 demo.db
    sqlite> .read 01-load-data.sql
    sqlite> .read 02-active-subs.sql
    sqlite> .read 03-churn-time-series.sql
    sqlite> .read 04-churn-rolling-window.sql
    sqlite> .read 05-create-big-fact.sql
    sqlite> .read 06-slice-churn.sql
