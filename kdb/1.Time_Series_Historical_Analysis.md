# Time Series & Historical Query Analysis

Welcome to this tutorial where we'll demonstrate how to work with large datasets in kdb+ to analyze time-series data. 

One of the key features of kdb+ is its ability to handle huge volumes of data with exceptional speed and efficiency. Whether it's reading massive datasets, performing time-based aggregations, or joining data from different sources, kdb+ excels at time-series analysis. By the end of this tutorial, you'll have a clear understanding of how to create, manipulate, store, and analyze data using kdb+/q. Along the way, we'll introduce several key concepts that are fundamental to working with kdb+/q.


Here, we'll cover:
- Creating a large time-series dataset from scratch
- Saving this data to a database on disk
- Scaling database to 1 Billion rows
- Performing time-based aggregations to analyze trends over time
- Using asof joins (aj) to combine time-series data (e.g., matching trades to quotes)

## 1. Prerequisites

Before starting this tutorial, ensure that you have kdb+ installed on your system. If you haven't installed it yet, you can download it from KX's official website and follow the installation instructions.

## 2. Create the Time Series Dataset

Let’s start by creating a sample dataset to work with. This dataset will simulate trade data over a period of time, with random values for price, size, and symbols.

First download the the [stocks.txt](stocks.txt) file locally and make sure the path below points to it.

```q
syms:100?`$read0 `:stocks.txt;
```
Above we are selecting 100 random stock symbols from an external text file containing a list of real stock tickers. 

Now we can generate the dataset:

```q
n:20000000;
day:2025.01.01;
trade:([] 
    time:asc (`timestamp$day) + n?24:00:00;     
    sym:n?syms;                                 
    price:n?100f;                              
    size:n?1000)
```

Here's a breakdown of what's happening:
- `n: 2000000` sets the number of rows we want to generate
- We define a new table with table notation `([] col1:<values>; col2:<values>: ...)`
- We use `?` to generate random values for 4 columns:
    - `time` is populated with timestamps starting from midnight and increasing across a 24-hour period, with a random offset to simulate a spread of trades.
    - `sym` is populated with random symbols, selected from a list.
    - `price` and trade `size` are randomnly generated

This table is now available in memory to investigate and query. Let's take a quick look at the row [`count`](#https://code.kx.com/q/ref/count/), schema details with [`meta`](#https://code.kx.com/q/ref/meta/) and first 10 rows using [`sublist`](#https://code.kx.com/q/ref/sublist/).

```q
count trade
```
```q
meta trade
```
    c    | t f a
    -----| -----
    time | p   s
    sym  | s    
    price| f    
    size | j    


The following columns are produced when we run `meta`:
- c: column name
- t: <a href="https://code.kx.com/q/ref/#datatypes" target="_blank">column type</a>
- f: <a href="https://code.kx.com/q4m3/8_Tables/#85-foreign-keys-and-virtual-columns" target="_blank">foreign keys</a>
- a: <a href="https://code.kx.com/q/ref/set-attribute/" target="_blank">attributes</a> (modifiers applied for performance optimisation)


```q
10 sublist trade
```

    time                          sym   price    size
    -------------------------------------------------
    2025.01.01D00:00:00.000000000 MFICL 64.20376 597 
    2025.01.01D00:00:00.000000000 TEAM  30.63798 172 
    2025.01.01D00:00:00.000000000 RVYL  40.56048 879 
    2025.01.01D00:00:00.000000000 SIGI  57.2691  829 
    2025.01.01D00:00:00.000000000 DVSP  54.74414 658 
    2025.01.01D00:00:00.000000000 HYDR  61.67117 925 
    2025.01.01D00:00:00.000000000 ELAB  6.223127 784 
    2025.01.01D00:00:00.000000000 HYLS  75.65475 755 
    2025.01.01D00:00:00.000000000 WGMI  78.49312 596 
    2025.01.01D00:00:00.000000000 NRES  40.66333 747 


## 3.  Save Data to Disk

Once the data is generated, you’ll likely want to save it to disk for persistent storage.

Because we want the ability to scale, partitioning by date will be a good approach for this dataset. Without partitioning, queries that span large time periods would require scanning entire datasets, which can be very slow and resource-intensive. By partitioning data, kdb+ can limit the query scope to the relevant partitions, significantly speeding up the process.

First let's define some filepaths to make things easier to manage, you can change your `homeDir` to wherever you wish to save your data.
```q
homeDir:getenv[`HOME];
dbDir:homeDir,"/data";
dbPath:hsym `$dbDir;
```
In the above:
- <a href="https://code.kx.com/q/ref/getenv/" target="_blank">getenv</a>: Get the value of an environment variable, in our case `HOME`  
- <a href="https://code.kx.com/q/ref/hsym/" target="_blank">hsym</a>: This function prefixes the directory location with a colon to make it a file handle

Then we set the compression parameters using [.z.zd](#https://code.kx.com/q/ref/dotz/#zzd-compressionencryption-defaults).

```q
.z.zd:(17;2;6)
```

To partition by date we can use the inbuilt function [`.Q.dpft`](#https://code.kx.com/q/ref/dotq/#dpft-save-table) to save the data to disk - this may take ~20 seconds to complete.
```q
.Q.dpft[dbPath;day;`sym;`trade]
```

In the above:
- <a href="https://code.kx.com/q/ref/dotq/#dpft-save-table" target="_blank">.Q.dpft[d;p;f;t]</a>: This command saves data to a <b>(d)</b>atabase location, targeting a particular <b>(p)</b>artition and indexes the data on a chosen <b>(f)</b>ield for the specified <b>(t)</b>able.

Once persisted, the table name is returned. We can test its worked as expected by deleting the `trade` table we have in memory and reloading the database from disk.


```q
delete trade from `.;           
system"l ",dbDir;    
meta trade              
```

    c    | t f a
    -----| -----
    date | d    
    sym  | s   p
    time | p    
    price| f    
    size | j    


kdb+ actually offers a number of different methods to store tables which will allow for efficient storage and querying for different sized datasets: flat, splayed, partitioned and segmented.

A general rule of thumb around which format to choose depends on three things:

- Will the table continue to grow at a fast rate?
- Am I working in a RAM/memory constrained environment?
- What level of performance do I want?

To learn more about these types and when to choose which <a href="https://code.kx.com/q/database/" target="_blank">see here</a>.

## 4 Scaling Dataset to 1 Billion Rows

In this section, we scale our dataset to 1 billion rows by duplicating an existing partition across multiple days. This approach ensures we have sufficient data for performance testing and analytics validation.

Before making copies, we check the disk space usage to ensure enough storage is available. The below system command displays the available and used disk space in megabytes, helping us monitor the impact of our operations.

```q
system"df -mh ."
```

> **Note on Disk Space**: To create 1 Billion rows this will require ~10GB of data space. If you have less than 10GB available, please reduce the days below otherwise you will run out of space.

Let's generate a list of new dates and copy the existing partition (2025.01.01) to these new dates. This may take ~40 seconds to complete.


```q
days:day +1 +til 49;
cmds: "cp -r ../data/2025.01.01 ../data/",/:string[days];
system each cmds  
```
In the above:
- Using [`til`](#https://code.kx.com/q/ref/til/)we generate 49 additional days = 10GB of data on disk
- Create shell commands to execute, we use the [, join](#https://code.kx.com/q/ref/join/) operator here
- Execute shell commands to copy partitions using [each](#https://code.kx.com/q/wp/iterators/#each-each-parallel) to iterate over all the days


Once the partitions are created, we verify how much disk space was consumed and check the new partitions exist.


```q
system"df -mh .";
system"ls -la ../data"
```


Finially since kdb+ manages partitioned data at the filesystem level, we must reload the database to reflect the newly added partitions.


```q
delete trade from `.;
system"l ",dbDir ;
select count i by date from trade
```
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


## 5. Time Series Analytics

Now that we have 1 Billion rows of data, let's dive into some basic time-series analytics.

### Total Trade Volume Every Hour

Let's find a symbol to analyse from the randomly generated list we created earlier and then run our query.


```q
symbol:first syms;
select sum size by date,60 xbar time.minute from trade where sym=symbol
```

    date       minute| size   
    -----------------| -------
    2025.01.01 00:00 | 4168236
    2025.01.01 01:00 | 4160249
    2025.01.01 02:00 | 4186595
    2025.01.01 03:00 | 4187285
    2025.01.01 04:00 | 4180584
    2025.01.01 05:00 | 4113079
    2025.01.01 06:00 | 4205680
    2025.01.01 07:00 | 4101998
    2025.01.01 08:00 | 4167611
    2025.01.01 09:00 | 4108081
    2025.01.01 10:00 | 4138310
    2025.01.01 11:00 | 4178508
    2025.01.01 12:00 | 4134138
    2025.01.01 13:00 | 4161473
    2025.01.01 14:00 | 4128168
    2025.01.01 15:00 | 4204660
    2025.01.01 16:00 | 4221971
    2025.01.01 17:00 | 4186433
    2025.01.01 18:00 | 4203052
    2025.01.01 19:00 | 4155269
    ..


#### qSQL & Temporal Arithmetic
Here we are using <a href="https://code.kx.com/q/basics/qsql/" target="_blank">qSQL</a>, the inbuilt table query language in kdb+. If you have used SQL, you will find the syntax of qSQL queries very similar.
- Just as in SQL, table results called using `select` and `from` and can be filtered by expressions following a `where`
- Multiple filter criteria, separated by ,, are evaluated starting from the left
- To group similar values together we can use the `by` clause. This is particularly useful in combination with used with an aggregation like `sum`,`max`,`min` etc.

kdb+/q supports several temporal types and arithmetic between them. See here for a summary of <a href="https://code.kx.com/q/ref/#datatypes" target="_blank">datatypes</a>.

In this tutorial:
- The `time` column in the data has a type of timestamp, which includes both date and time values.
- We convert the `time` values to their minute values (including hours and minutes)
- We then aggregate further on time by using <a href="https://code.kx.com/q/ref/xbar/" target="_blank">xbar</a> to bucket the minutes into hours (60-unit buckets)

### Weighted Average Price and Last Trade Price Every 15 Minutes 


```q
select lastPx:last price, vwapPx:size wavg price by date, 15 xbar time.minute from trade where sym=symbol
```

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
    2025.01.01 02:00 | 34.01241 49.25463
    2025.01.01 02:15 | 80.39318 50.41682
    2025.01.01 02:30 | 57.6013  49.74883
    2025.01.01 02:45 | 35.34707 48.33145
    2025.01.01 03:00 | 62.20132 50.13491
    2025.01.01 03:15 | 55.43684 48.93589
    2025.01.01 03:30 | 71.24645 49.03167
    2025.01.01 03:45 | 41.56698 50.04032
    2025.01.01 04:00 | 21.19538 49.90231
    2025.01.01 04:15 | 24.41028 49.78817
    2025.01.01 04:30 | 41.9978  49.86906
    2025.01.01 04:45 | 32.51881 49.48584
    ..


This is similar to the previous analytic, but this time we make use of the built in `wavg` function to find out the weighted average over time intervals. 

In finance, volume-weighted averages give a more accurate reflection of a stock’s price movement by incorporating trading volume at different price levels. This can be especially useful in understanding whether a price move is supported by strong market participation or is just a result of a few trades.

Let's time this anayltic with `\t` to see how long it takes in milliseconds to crunch through 1 Billion records.


```q
\t select lastPx:last price, vwapPx:size wavg price by date, 15 xbar time.minute from trade where sym=symbol
```


The query processed 1 Billion records in 1-2 seconda, efficiently aggregating last price (`lastPx`) and volume-weighted-average price (`vwapPx`) for these trades. The use of `by date, 15 xbar time.minute` optimized the grouping, making the computation fast. This demonstrates the power of kdb+/q for high-speed time-series analytics.

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

One of the most powerful features in kdb+/q is the asof join (`aj`), which is designed to match records from two tables based on the most recent timestamp. Unlike a standard SQL join, where records must match exactly on a key, an asof join finds the most recent match.

Why Use Asof Joins?
In time-series data, we often deal with information arriving at different intervals. For examplel:
- Trade and Quote Data: A trade occurs at a given time, and we want to match it with the latest available quote.
- Sensor Data: A sensor records temperature every second, while another logs environmental data every 10 seconds—matching the closest reading is crucial.


#### Generate synthetic quote data for one day


```q
n:2000000;
quote:([] 
    time:asc (`timestamp$day) + n?86400000000000;
    sym:n?syms;
    bid:n?100f;
    ask:n?100f)
```

As we're keeping this table in memory we need to perform one extra step before joining, we apply the parted (p#) attribute to the sym column of the quote table. Our trade table on disk already has the parted attribute on the sym column, we see this in the column `a` when we run `meta trade`.


```q
meta trade
```

    c    | t f a
    -----| -----
    date | d    
    sym  | s   p
    time | p    
    price| f    
    size | j    


This is crucial for optimizing asof joins, as it ensures faster lookups when performing symbol-based joins. Before applying parted to quote, we first sort the table by sym using [`xasc`](#https://code.kx.com/q/ref/asc/), as the parted attribute requires the column to be sorted for it to work efficiently.


```q
quote:`sym xasc quote;
quote:update `p#sym from quote
```

In the above:
- `xasc` Sorts the quote table by sym in ascending order
- `#`  Applies the parted attribute to sym, optimizing symbol-based lookups.

#### Peform Asof Join

We now match each trade with the most recent available quote for todays date using [`aj`](#https://code.kx.com/q/ref/aj/).

```q
aj[`sym`time; select from trade where date=day; quote]
```

    date       sym  time                          price    size bid      ask     
    -----------------------------------------------------------------------------
    2025.01.01 AAME 2025.01.01D00:00:00.000000000 11.13743 579                   
    2025.01.01 AAME 2025.01.01D00:00:01.000000000 25.39669 530                   
    2025.01.01 AAME 2025.01.01D00:00:02.000000000 52.84274 139                   
    2025.01.01 AAME 2025.01.01D00:00:03.000000000 29.17217 227                   
    2025.01.01 AAME 2025.01.01D00:00:03.000000000 95.41841 735                   
    2025.01.01 AAME 2025.01.01D00:00:04.000000000 60.95445 995                   
    2025.01.01 AAME 2025.01.01D00:00:04.000000000 63.20168 324                   
    2025.01.01 AAME 2025.01.01D00:00:04.000000000 78.9044  684                   
    2025.01.01 AAME 2025.01.01D00:00:04.000000000 18.60533 47                    
    2025.01.01 AAME 2025.01.01D00:00:05.000000000 41.88837 882                   
    2025.01.01 AAME 2025.01.01D00:00:06.000000000 17.04109 901  10.01786 8.147825
    2025.01.01 AAME 2025.01.01D00:00:07.000000000 38.12558 377  10.01786 8.147825
    2025.01.01 AAME 2025.01.01D00:00:07.000000000 2.801231 474  10.01786 8.147825
    2025.01.01 AAME 2025.01.01D00:00:08.000000000 90.15238 745  10.01786 8.147825
    2025.01.01 AAME 2025.01.01D00:00:08.000000000 62.14185 393  10.01786 8.147825
    2025.01.01 AAME 2025.01.01D00:00:09.000000000 65.49808 42   10.01786 8.147825
    2025.01.01 AAME 2025.01.01D00:00:09.000000000 3.75946  778  10.01786 8.147825
    2025.01.01 AAME 2025.01.01D00:00:09.000000000 41.3384  901  10.01786 8.147825
    2025.01.01 AAME 2025.01.01D00:00:09.000000000 35.3266  859  10.01786 8.147825
    2025.01.01 AAME 2025.01.01D00:00:10.000000000 58.99907 507  10.01786 8.147825
    ..


In the above:
- `aj` performs an asof join on the `sym` and `time` columns
- Each trade record gets matched with the latest available quote at or before the trade’s timestamp.
- We can see this means the first few `bid` and `ask` values are empty because there was no quote data prior to those trades.

This approach ensures that for every trade, we have the best available quote information, allowing traders to analyze trade execution relative to the prevailing bid/ask spread at the time.


