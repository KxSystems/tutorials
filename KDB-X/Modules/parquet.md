# KDB-X Parquet Tutorial
## Overview

Parquet is a columnar storage format designed for efficient storage and retrieval. 
KDB-X supports reading and writing Parquet files through the `pq` module. 

## Use Cases
- Data interchange: Share Parquet datasets between KDB-X and tools like Spark, Pandas, and Hive.
- Efficient analytics: Run SQL or q queries directly against Parquet files with row group pruning.
- Archival storage: Keep large historical datasets compressed but queryable.
- Hybrid queries: Join or aggregate across in-memory tables and Parquet-backed virtual tables in one query.

This tutorial outlines how to integrate KDB-X with tables in Parquet format on disk, and how to seamlessly perform common operations and calculations on both single tables and mutliple tables in memory. 

## Prerequisites 
1. View the [KDB-X Docs](https://docs.kx.com/public-preview/kdb-x/home.htm) for full details on KDB-X and KDB-X Python.
Requires KDB-X to be installed, you can sign up [here](https://developer.kx.com/products/kdb-x/install). For full install instructions see: [KDB-X Install](https://docs.kx.com/public-preview/kdb-x/Get_Started/kdb-x-install.htm).
2. Download the dataset from [Kaggle](https://www.kaggle.com/datasets/zahinawosaf/forex-tick-data) and extract the files
```
#!/bin/bash 
curl -L -o ~/parquet/forex-tick-data.zip https://www.kaggle.com/api/v1/datasets/download/zahinawosaf/forex-tick-data 

unzip parquet/forex-tick-data.zip 
```
Then launch a q sessions by running `q`
```q
Welcome to KDB-X Community Edition! 
For Community support, please visit https://kx.com/slack 
Tutorials can be found at https://github.com/KxSystems/tutorials 
Ready to go beyond the Community Edition? Email preview@kx.com 
q)
```
First, let's find the data we just downloaded from Kaggle
```q
system "find parquet/AUDUSD | head" 

system "find parquet/AUDUSD | wc -l"
```
```
"253"
```
We can see that there are over 250 files in this dataset. 

Now, we will load the Parquet module
```q
([pq]):use`kx.pq
```

### Single Table Example

Let's load in one of the tables, so that we can see what we're working with
```q
quote: pq `$":parquet/AUDUSD/AUDUSD - 2004-04-01 - 2004-04-30.parquet"
```
Straight away, we can run some basic functions and aggregations on this table using q:
```q
select rows:count i from quote 
```
```
rows 
------- 
2213548 
```
```q
meta quote 
```
```
c         | t f a 
----------| ----- 
timestamp | p 
symbol    | C 
ask_price | f 
bid_price | f 
ask_volume| i 
bid_volume| i 
```
As you can see from above, we can treat this table just like a q table, and run built-in qSQL functions like `select from quote` and `meta quote`.

We can also query using common q functionality like `xbar` and the parquet column names: 
```q
10#select spread:max ask_price-bid_price by 0D01 xbar timestamp from quote where ask_price>=bid_price, not null ask_volume 
```
```
timestamp                    | spread
-----------------------------| -------
2004.04.01D00:00:00.000000000| 0.0006
2004.04.01D01:00:00.000000000| 0.0005
2004.04.01D02:00:00.000000000| 0.00056
2004.04.01D03:00:00.000000000| 0.0006
2004.04.01D04:00:00.000000000| 0.0005
2004.04.01D05:00:00.000000000| 0.00056
2004.04.01D06:00:00.000000000| 0.0005
2004.04.01D07:00:00.000000000| 0.0005
2004.04.01D08:00:00.000000000| 0.0004
2004.04.01D09:00:00.000000000| 0.0004
``` 
 
### Multiple Table Example

The virtual table API allows combining multiple Parquet files into a single virtual table using virtual partition columns:
```q
tb:use`kx.pq.t
```
Let's have a look at the file structure and then extract the file names as a column:
```q
path:`:parquet/AUDUSD;
files:([]file:` sv'path,/:key path);
count files
```
```
252
```
```q
10#files
```
``` 
file 
-------------------------------------------------------- 
:parquet/AUDUSD/AUDUSD - 2004-01-01 - 2004-01-31.parquet 
:parquet/AUDUSD/AUDUSD - 2004-02-01 - 2004-02-29.parquet 
:parquet/AUDUSD/AUDUSD - 2004-03-01 - 2004-03-31.parquet 
:parquet/AUDUSD/AUDUSD - 2004-04-01 - 2004-04-30.parquet 
:parquet/AUDUSD/AUDUSD - 2004-05-01 - 2004-05-31.parquet 
:parquet/AUDUSD/AUDUSD - 2004-06-01 - 2004-06-30.parquet 
:parquet/AUDUSD/AUDUSD - 2004-07-01 - 2004-07-31.parquet 
:parquet/AUDUSD/AUDUSD - 2004-08-01 - 2004-08-31.parquet 
:parquet/AUDUSD/AUDUSD - 2004-09-01 - 2004-09-30.parquet 
:parquet/AUDUSD/AUDUSD - 2004-10-01 - 2004-10-31.parquet 
```

Creating the columns that will act as our virtual columns, using the filename and the month:

```q
virt:pq each files`file;
part:update month:2004.01m+til count files from files;
10#part
```
```
file                                                     month 
---------------------------------------------------------------- 
:parquet/AUDUSD/AUDUSD - 2004-01-01 - 2004-01-31.parquet 2004.01 
:parquet/AUDUSD/AUDUSD - 2004-02-01 - 2004-02-29.parquet 2004.02 
:parquet/AUDUSD/AUDUSD - 2004-03-01 - 2004-03-31.parquet 2004.03 
:parquet/AUDUSD/AUDUSD - 2004-04-01 - 2004-04-30.parquet 2004.04 
:parquet/AUDUSD/AUDUSD - 2004-05-01 - 2004-05-31.parquet 2004.05 
:parquet/AUDUSD/AUDUSD - 2004-06-01 - 2004-06-30.parquet 2004.06 
:parquet/AUDUSD/AUDUSD - 2004-07-01 - 2004-07-31.parquet 2004.07 
:parquet/AUDUSD/AUDUSD - 2004-08-01 - 2004-08-31.parquet 2004.08 
:parquet/AUDUSD/AUDUSD - 2004-09-01 - 2004-09-30.parquet 2004.09 
:parquet/AUDUSD/AUDUSD - 2004-10-01 - 2004-10-31.parquet 2004.10 
```

Now that we have our virtual columns, we can create one virtual table in memory pulling Parquet data from each file
```q
quote_all:tb.mkP part!virt; 
meta quote_all
```
```
c         | t f a 
----------| ----- 
file      | s 
month     | m 
timestamp | p 
symbol    | C 
ask_price | f 
bid_price | f 
ask_volume| i 
bid_volume| i 
```

The table in memory now contains all the data from each file in the dataset:
```q
select rows:count i from quote_all 
```
```
rows 
--------- 
353889010 
```

We can now start to query this data just like we would query a `q` table:
```q
select rows:count i by file from quote_all 
```
```
file                                                    | rows 
--------------------------------------------------------| ------- 
:parquet/AUDUSD/AUDUSD - 2004-01-01 - 2004-01-31.parquet| 2027152 
:parquet/AUDUSD/AUDUSD - 2004-02-01 - 2004-02-29.parquet| 1963657 
:parquet/AUDUSD/AUDUSD - 2004-03-01 - 2004-03-31.parquet| 2253977 
:parquet/AUDUSD/AUDUSD - 2004-04-01 - 2004-04-30.parquet| 2213548 
:parquet/AUDUSD/AUDUSD - 2004-05-01 - 2004-05-31.parquet| 1929827 
:parquet/AUDUSD/AUDUSD - 2004-06-01 - 2004-06-30.parquet| 616357 
:parquet/AUDUSD/AUDUSD - 2004-07-01 - 2004-07-31.parquet| 638555 
:parquet/AUDUSD/AUDUSD - 2004-08-01 - 2004-08-31.parquet| 649610 
:parquet/AUDUSD/AUDUSD - 2004-09-01 - 2004-09-30.parquet| 664278 
:parquet/AUDUSD/AUDUSD - 2004-10-01 - 2004-10-31.parquet| 634990 
:parquet/AUDUSD/AUDUSD - 2004-11-01 - 2004-11-30.parquet| 655733 
:parquet/AUDUSD/AUDUSD - 2004-12-01 - 2004-12-31.parquet| 694420 
..
```

We can perform huge calculations and aggregate over years of Parquet data using q:

```q
calc:{[st;et;bkt] 
       tmp:ungroup select timestamp, 
             mid:(bid_price+ask_price)%2, 
             bboSize:(bid_volume+ask_volume)%2, 
             spread:ask_price-bid_price,
             e_n:((bid_price>=prev bid_price)*bid_volume)
               -((bid_price<=prev bid_price)*prev bid_volume)
               -((ask_price<=prev ask_price)*ask_volume)
               +((ask_price>=prev ask_price)*prev ask_volume)
             by date:`date$timestamp, `$symbol from quote_all where month within (st;et); 
             
       select start_time:st, end_time:et, 
              ofi:sum e_n, 
              dP:last mid-first mid, 
              n:count e_n, 
              avg_spread: avg spread, 
              avg_bbo_size:avg bboSize 
         by bkt xbar timestamp, symbol from tmp 
};
```
We can use `\ts` to see the power of using KDB-X to perform fast anaylytics at scale: 
```q
\ts calc[2004.01m;2006.01m;0D01]
```
```
7541 3489661664
```
## Key Takeaways
- **Interoperability:** Being able to use q with Parquet open file format means users can exchange data with ecosystems such as Spark, Pandas, Arrow etc.
- **Fast Analytics at Scale:**  Query large Parquet datasets efficiently with virtual tables.
- **Seamless Integration:** Use q queries directly on Parquet files, alongside in-memory or partitioned tables.

To learn more about KDB-X modules, visit [KDB-X Module Management](https://docs.kx.com/latest/kdb-x/integrations/module-management.htm).
