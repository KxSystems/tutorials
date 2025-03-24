# Time Series & Historical Query Analysis

Welcome to this tutorial where we'll demonstrate how to work with large datasets in kdb+ to analyze time-series data with PyKX.

One of the key features of PyKX is its ability to handle huge volumes of data with exceptional speed and efficiency. Whether it's reading massive datasets, performing time-based aggregations, or joining data from different sources, PyKX excels at time-series analysis through its tight connection to kdb+.

By the end of this tutorial, you'll have a clear understanding of how to create, manipulate, store, and analyze data using PyKX. Along the way, we'll introduce several key concepts that are fundamental to working with data in PyKX.


Here, we'll cover:
- Creating a large time-series dataset from scratch
- Saving this data to a database on disk
- Scaling database to 1 Billion rows
- Performing time-based aggregations to analyze trends over time
- Using asof joins (aj) to combine time-series data (e.g., matching trades to quotes)

## 1. Prerequisites

Before starting this tutorial, ensure that you have PyKX installed on your system. If you haven't installed it yet, you can follow the installation guide at https://code.kx.com/pykx/3.1/getting-started/installing.html.

## 2. Create the Time Series Dataset

Let’s start by creating a sample dataset to work with. This dataset will simulate trade data over a period of time, with random values for price, size, and symbols.

Firstly you can import PyKX and a number of additional libraries into your Python session

```python
import pykx as kx
from datetime import date
import numpy as np
import os
```

Next download the the [stocks.txt](stocks.txt) file locally and make sure the path below points to it.

```python
with open('stocks.txt', 'r') as f:
    py_symbols = f.read().split('\n')
syms = kx.random.random(100, py_symbols)
```

Above we are selecting 100 random stock symbols from an external text file containing a list of real stock tickers.

Now we can generate a time-series dataset:

```python
n = 20000000;
day = date(2025, 1, 1);
trade = kx.Table(data = {
     'time': kx.q.asc(day + kx.random.random(n, kx.q('24:00:00'))),
     'sym': kx.random.random(n, syms),
     'price': kx.random.random(n, 100.0),
     'size': kx.random.random(n, 1000)
    }
)
```

Here's a breakdown of what's happening:
- `n = 2000000` sets the number of rows we want to generate
- We define a new table using `kx.Table` with syntax similar to that used by Pandas
- The function `kx.random.random` is then used to create `n` randomly generated
    - `time` is populated with timestamps starting from midnight and increasing across a 24-hour period, with a random offset to simulate a spread of trades. These are then sorted in ascending order using `kx.q.asc`.
    - `sym` is populated with random symbols, selected from a list.
    - `price` and trade `size` are randomly generated

This table is now available in memory to investigate and query. Let's take a quick look at the following:

- Row count using `len`
- Schema details using the attributes `dtypes`
- Retrieve the first 10 rows using the method `head`

```python
len(trade)
```

```python
trade.dtypes
```
    pykx.Table(pykx.q('
    columns datatypes
    --------------------------
    time    "kx.TimestampAtom"
    sym     "kx.SymbolAtom"
    price   "kx.FloatAtom"
    size    "kx.LongAtom"
    '))
```python
trade.head(10)
```
    pykx.Table(pykx.q('
    time                          sym   price    size
    -------------------------------------------------
    2025.01.01D00:00:00.000000000 DVAX  9.225738 63
    2025.01.01D00:00:00.000000000 BAYAR 82.30603 913
    2025.01.01D00:00:00.000000000 YYGH  72.3243  548
    2025.01.01D00:00:00.000000000 SOXQ  77.90728 282
    2025.01.01D00:00:00.000000000 FWONA 77.26276 168
    2025.01.01D00:00:00.000000000 BWEN  18.88928 653
    2025.01.01D00:00:00.000000000 QABA  45.66406 776
    2025.01.01D00:00:00.000000000 SSSSL 42.81835 19
    2025.01.01D00:00:00.000000000 FV    52.86591 399
    2025.01.01D00:00:00.000000000 PRCT  12.54231 534
    '))

## 3.  Save Data to Disk

Once the data is generated, you’ll likely want to save it to disk for persistent storage.

Because we want the ability to scale, partitioning by date will be a good approach for this dataset. Without partitioning, queries that span large time periods would require scanning entire datasets, which can be very slow and resource-intensive. By partitioning data, kdb+ can limit the query scope to the relevant partitions, significantly speeding up the process.

First let's define some filepaths to make things easier to manage, you can change your `homeDir` to wherever you wish to save your data.

```python
home_dir = os.getenv('HOME')
db_dir = home_dir + '/data'
```

Now that we have access to the location you can initialize a `kx.DB` class object which you can use to interact with your database.

```python
database = kx.DB(path = db_dir)
```

Now that you have the location for your database is available we can persist a table to our database

```python
database.create(trade, 'trade', day)
```

Once persisted you can list the tables associated with the database.

```python
database.tables
```

Accessing the table for query via Python can be done by accessing the named table attribute, for example as follows accessing the `trade` table

```python
database.trade
```
    pykx.PartitionedTable(pykx.q('
    date       sym   time                          price    size
    ------------------------------------------------------------
    2025.01.01 DVAX  2025.01.01D00:00:00.000000000 9.225738 63
    2025.01.01 BAYAR 2025.01.01D00:00:00.000000000 82.30603 913
    2025.01.01 YYGH  2025.01.01D00:00:00.000000000 72.3243  548
    2025.01.01 SOXQ  2025.01.01D00:00:00.000000000 77.90728 282
    2025.01.01 FWONA 2025.01.01D00:00:00.000000000 77.26276 168
    2025.01.01 BWEN  2025.01.01D00:00:00.000000000 18.88928 653
    2025.01.01 QABA  2025.01.01D00:00:00.000000000 45.66406 776
    2025.01.01 SSSSL 2025.01.01D00:00:00.000000000 42.81835 19
    2025.01.01 FV    2025.01.01D00:00:00.000000000 52.86591 399
    2025.01.01 PRCT  2025.01.01D00:00:00.000000000 12.54231 534
    2025.01.01 FID   2025.01.01D00:00:00.000000000 65.39818 9
    2025.01.01 STI   2025.01.01D00:00:00.000000000 92.57709 622
    2025.01.01 ALDF  2025.01.01D00:00:00.000000000 1.183345 812
    2025.01.01 MDIA  2025.01.01D00:00:00.000000000 70.1431  886
    2025.01.01 NCPL  2025.01.01D00:00:00.000000000 65.53554 367
    2025.01.01 FV    2025.01.01D00:00:00.000000000 1.988985 910
    2025.01.01 NEGG  2025.01.01D00:00:00.000000000 39.48223 803
    2025.01.01 NBTX  2025.01.01D00:00:00.000000000 15.49415 309
    2025.01.01 KPLT  2025.01.01D00:00:00.000000000 11.61893 603
    2025.01.01 BSET  2025.01.01D00:00:00.000000000 16.13565 810
    ..
    '))

PyKX and kdb+ offers a number of different methods to store tables which will allow for efficient storage and querying for different sized datasets: flat, splayed, partitioned and segmented.

A general rule of thumb around which format to choose depends on three things:

- Will the table continue to grow at a fast rate?
- Am I working in a RAM/memory constrained environment?
- What level of performance do I want?

To learn more about these types and when to choose which <a href="https://code.kx.com/q/database/" target="_blank">see here</a>.

## 4 Scaling Dataset to 1 Billion Rows

In this section, we scale our dataset to 1 billion rows by duplicating an existing partition across multiple days. This approach ensures we have sufficient data for performance testing and analytics validation.

Before making copies, we check the disk space usage to ensure enough storage is available. The below system command displays the available and used disk space in megabytes, helping us monitor the impact of our operations.

```python
os.system('df -mh .')
```

> **Note on Disk Space**: To create 1 Billion rows this will require ~10GB of data space. If you have less than 10GB available, please reduce the days below otherwise you will run out of space.

Let's generate a list of new dates and copy the existing partition (2025.01.01) to these new dates. This may take ~60 seconds to complete.


```python
for i in range(1, 50):
   date = (day + kx.q(str(i) + 'D')).date
   data = trade.update({'time': trade.exec('time') + kx.q(str(i) + 'D')})
   database.create(data, 'trade', date)
```

In the above:
- Looping over 49 days and creating an updated date for each partition achieved by adding one day at each interval and retrieving the `date`.
- Using the `update` method to increase the date for the `time` columns used within the database where the `time` column has been retrieved using the `exec` method.
- Add the database partitions by running the `create` method on the previously initialised `database` object.


Once the partitions are created, we verify how much disk space was consumed and check the new partitions exist.


```python
os.system('df -mh .')
os.system('ls -la ' + db_dir)
```

To validate the amount of data within our loaded database we can run a `select` query on the data


```python
database.trade.select(
    columns = kx.Column('time').count(),
    by = kx.Column('date')
)
```

This should return a table that looks as follows:

    pykx.KeyedTable(pykx.q('
    date      | x
    ----------| --------
    2025.01.01| 20000000
    2025.01.02| 20000000
    2025.01.03| 20000000
    2025.01.04| 20000000
    2025.01.05| 20000000
    2025.01.06| 20000000
    2025.01.07| 20000000
    2025.01.08| 20000000
    2025.01.09| 20000000
    2025.01.10| 20000000
    2025.01.11| 20000000
    2025.01.12| 20000000
    2025.01.13| 20000000
    2025.01.14| 20000000
    2025.01.15| 20000000
    2025.01.16| 20000000
    2025.01.17| 20000000
    2025.01.18| 20000000
    2025.01.19| 20000000
    2025.01.20| 20000000
    ..
    '))



## 5. Time Series Analytics

Now that we have 1 Billion rows of data, let's dive into some basic time-series analytics.

### Total Trade Volume Every Hour

Let's find a symbol to analyse from the randomly generated list we created earlier and then run our query. In the below query we're calculating the total traded volume size per-hour for our specified symbol across our 1 Billion datapoints.


```python
symbol = syms[0]
database.trade.select(
    columns = kx.Column('size').sum(),
    by = kx.Column('date') & kx.Column('time').minute.xbar(60),
    where = kx.Column('sym') == symbol
)
```
    pykx.KeyedTable(pykx.q('
    date       time | size
    ----------------| -------
    2025.01.02 00:00| 4161526
    2025.01.02 01:00| 4291162
    2025.01.02 02:00| 4251908
    2025.01.02 03:00| 4194820
    2025.01.02 04:00| 4143345
    2025.01.02 05:00| 4200231
    2025.01.02 06:00| 4175393
    2025.01.02 07:00| 4121591
    2025.01.02 08:00| 4193462
    2025.01.02 09:00| 4167368
    2025.01.02 10:00| 4199019
    2025.01.02 11:00| 4230971
    2025.01.02 12:00| 4201560
    2025.01.02 13:00| 4150440
    2025.01.02 14:00| 4126077
    2025.01.02 15:00| 4119997
    2025.01.02 16:00| 4175387
    2025.01.02 17:00| 4124853
    2025.01.02 18:00| 4193938
    2025.01.02 19:00| 4142369
    ..
    '))

#### PyKX querying & Temporal Arithmetic

In the following section we will make use of the Pythonic Query API provided by PyKX for querying kdb+ databases. This is outlined in more detail <a href="https://code.kx.com/pykx/3.1/user-guide/fundamentals/query/pyquery.html" target="_blank">here</a>.

kdb+/q and as a result PyKX supports several temporal types and arithmetic between them. See here for a summary of <a href="https://code.kx.com/q/ref/#datatypes" target="_blank">datatypes</a>.

In this tutorial:

- The `time` column in the data has a type of timestamp, which includes both date and time values.
- We convert the `time` values to their minute values (including hours and minutes)
- We then aggregate further on time by using <a href="https://code.kx.com/pykx/3.1/api/columns.html#pykx.wrappers.Column.xbar" target="_blank">xbar</a> to bucket the minutes into hours (60-unit buckets)

### Weighted Average Price and Last Trade Price Every 15 Minutes


```python
database.trade.select(
    columns = kx.Column('price').last().name('lastPx') &
              kx.Column('size').wavg(kx.Column('price')).name('vwapPx'),
    by = kx.Column('date') & kx.Column('time').minute.xbar(15),
    where = kx.Column('sym') == symbol
)
```

    pykx.KeyedTable(pykx.q('
    date       minute| lastPx   vwapPx
    -----------------| -----------------
    2025.01.01 00:00 | 12.02315 49.7027
    2025.01.01 00:15 | 89.32436 50.23902
    2025.01.01 00:30 | 69.63196 49.84172
    2025.01.01 00:45 | 45.60034 49.13936
    2025.01.01 01:00 | 76.59549 49.59122
    2025.01.01 01:15 | 72.53248 51.27943
    2025.01.01 01:30 | 6.074879 49.90891
    2025.01.01 01:45 | 64.48105 50.05766
    ..
    '))


This is similar to the previous analytic, but this time we make use of the built in `wavg` function to find out the weighted average over time intervals.

In finance, volume-weighted averages give a more accurate reflection of a stock’s price movement by incorporating trading volume at different price levels. This can be especially useful in understanding whether a price move is supported by strong market participation or is just a result of a few trades.

The query processed 1 Billion records in seconds, efficiently aggregating last price (`lastPx`) and volume-weighted-average price (`vwapPx`) for these trades. The use of `by date, 15 xbar time.minute` optimized the grouping, making the computation fast. This demonstrates the power of kdb+/q for high-speed time-series analytics.

 ### SQL Comparison

A SQL version of this query above would look something like:

```

SELECT
    (array_agg(price ORDER BY time DESC))[1] AS lastPx,
    SUM(price * size) / NULLIF(SUM(size), 0) AS vwapPx,
    DATE_TRUNC('day', time),
    TRUNC(time, 'MI') + (FLOOR(TO_NUMBER(TO_CHAR(time, 'MI')) / 15) * INTERVAL '15' MINUTE)
FROM
    trade
WHERE
    sym = 'MSFT'
GROUP BY
    DATE_TRUNC('day', time),
    TRUNC(time, 'MI') + (FLOOR(TO_NUMBER(TO_CHAR(time, 'MI')) / 15) * INTERVAL '15' MINUTE)
ORDER BY
    DATE_TRUNC('day', time),
    TRUNC(time, 'MI') + (FLOOR(TO_NUMBER(TO_CHAR(time, 'MI')) / 15) * INTERVAL '15' MINUTE);

```

SQL is more complex due to several factors:
- **Time-series Calculations**: The SQL version involves the creation of custom logic for common time-series calculations such as volume-weighted-averages. In the q-sql version, these functionalities are implicit, and the syntax is more concise when working with vectors. The SQL equivalent requires custom definitions and is often more verbose leaving room for error.
- **Grouping and Aggregation**: In the q-sql version, grouping by date and a 15 minute window is done with a single, simple syntax, which is an efficient and intuitive way to express time bucketing. In SQL, similar behavior requires explicitly defining how time intervals are handled and aggregating the results using GROUP BY with custom time expressions which are often repeated throughout the query.
- **Temporal Formatting**: SQL queries often require repetitive conversion for handling timestamp formats, which is more cumbersome compared to q-sql, where time-based operations like xbar (interval-based bucketing) can be done directly in a streamlined manner. Temporal primitives also make it extremely easy to convert a nanosecond timestamp to it's equivalent minute using dot notation e.g. time.minute
- **Data Transformation**: The q language is optimized for high-performance, in-memory, columnar data transformations, which allows for more compact expressions on vectors of data. SQL, on the other hand, is typically too general purpose for even simple transformations on time-series data. This is down to how kdb+/q is designed, where operations execute on ordered lists, whereas SQL (based on set theory) treats data as records instead of columns e.g. selecting the (last) value in a series, or understanding prior states (deltas) for series movements would require re-ordering the column data
- **Performance Considerations**: q-sql is designed for high-performance analytics on large datasets, and many operations that would require complex SQL expressions can be done efficiently with q-sql syntax. In SQL, complex operations requires workarounds such as additional processing with temporary tables, sub-expressions, re-indexing, changing data models, or heavily leveraging partitions and window functions.

Thus, while the core logic of the query is similar in both languages, the SQL version requires much more overhead in terms of complexity and verbosity. This inefficiency will also become more pronounced with large datasets, leading to challenges with query performance.

While these are just basic analytics, they highlight kdb+/q’s ability to storage and analyse large-scale time-series datasets quickly.

## 6. Asof Join – Matching Trades with Quotes

One of the most powerful features in kdb+/q is the asof join (`aj`), this is accessible in PyKX as the `merge_asof` method on table objects and is designed to match records from two tables based on the most recent timestamp. Unlike a standard SQL join, where records must match exactly on a key, an asof join finds the most recent match.

Why Use Asof Joins?

In time-series data, we often deal with information arriving at different intervals. For example:

- Trade and Quote Data: A trade occurs at a given time, and we want to match it with the latest available quote.
- Sensor Data: A sensor records temperature every second, while another logs environmental data every 10 seconds—matching the closest reading is crucial.


#### Generate synthetic quote data for one day


```q
quote = kx.Table(data = {
     'time': kx.q.asc(day + kx.random.random(n, kx.q('24:00:00'))),
     'sym': kx.random.random(n, syms),
     'bid': kx.random.random(n, 100.0),
     'ask': kx.random.random(n, 1000)
    }
)
```

As we're keeping this table in memory we need to perform one extra step before joining, we apply the parted attribute to the sym column of the quote table. Our trade table on disk already has the parted attribute on the sym column, we see this in the column `a` when we run the following:


```python
kx.q.meta(database.trade)
```

    c    | t f a
    -----| -----
    date | d
    sym  | s   p
    time | p
    price| f
    size | j


This is crucial for optimizing asof joins, as it ensures faster lookups when performing symbol-based joins. Before applying parted to quote, we first sort the table by sym using [`kx.q.xasc`](#https://code.kx.com/pykx/3.1/api/pykx-execution/q.html#xasc), as the parted attribute requires the column to be sorted for it to work efficiently.


```python
quote = kx.q.xasc('sym', quote)
quote = quote.parted('sym')
```

In the above:
- `kx.q.xasc` Sorts the quote table by sym in ascending order
- `parted`  Applies the parted attribute to sym, optimizing symbol-based lookups.

#### Peform Asof Join

We now match each trade with the most recent available quote for todays date using <a href="https://code.kx.com/pykx/3.1/user-guide/advanced/Pandas_API.html#tablemerge_asof" target="_blank">merge_asof</a>.

```python
subtrade = database.trade.select(where=kx.Column('date') == day)
subtrade.merge_asof(quote, ['sym', 'time'])
```


    pykx.Table(pykx.q('
    date       time                          sym   price    size bid      ask
    -------------------------------------------------------------------------
    2025.01.01 2025.01.01D00:00:00.000000000 DVAX  9.225738 63   83.49145 853
    2025.01.01 2025.01.01D00:00:00.000000000 BAYAR 82.30603 913  78.34594 106
    2025.01.01 2025.01.01D00:00:00.000000000 YYGH  72.3243  548  52.96264 342
    2025.01.01 2025.01.01D00:00:00.000000000 SOXQ  77.90728 282  91.99564 670
    ..
    '))



In the above:
- `merge_asof` performs an asof join on the `sym` and `time` columns
- Each trade record gets matched with the latest available quote at or before the trade’s timestamp.
- We can see this means the first few `bid` and `ask` values are empty because there was no quote data prior to those trades.

This approach ensures that for every trade, we have the best available quote information, allowing traders to analyze trade execution relative to the prevailing bid/ask spread at the time.
~                                                                                                                                                                                            
