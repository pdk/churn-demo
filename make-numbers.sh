#!/bin/bash

echo 'number' > data/numbers.csv

cat data/MOCK_DATA-*.csv \
    data/MOCK_DATA-*.csv \
    data/MOCK_DATA-*.csv \
    data/MOCK_DATA-*.csv \
    data/MOCK_DATA-*.csv \
    data/MOCK_DATA-*.csv \
    data/MOCK_DATA-*.csv \
| egrep -n . | cut -d: -f1 >> data/numbers.csv
