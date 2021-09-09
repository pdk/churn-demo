-- export.sql

.headers on
.mode csv
.output mock-data.csv

select * from mock_data order by row_id;

.output date-dim.csv

select * from date_dim order by date_id;

.mode column
