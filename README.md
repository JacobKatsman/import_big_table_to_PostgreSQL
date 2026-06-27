#About code

High-speed generation of 10^6 records in a PostgreSQL table with a left-skewed normal data distribution.
This implementation serves as a scalable template for developing production-grade data import pipelines.

#Bulk Insert Benchmark

## Result testing (1,000,000 string)

| Mehod | Time | Speed |
|-------|-------|----------|
| CALL + stringly | 37.35 сек | 26,770 rows/s |
| INSERT + executeMany | 6.81 сек | 146,800 rows/s |
| COPY | 1.28 сек | 782,000 rows/s |
