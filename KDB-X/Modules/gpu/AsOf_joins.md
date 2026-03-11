# As-of Joins on GPU

As-of joins are a foundational building block in time-series analytics, powering many of the most data-intensive workflows in finance and beyond.
Whether that be for trade-quote alignment, order book reconstruction, signal and feature alignment, protfolio valuation/risk snapshots, or IoT and sensor data synchronization, the KDB-X GPU Edition utilizes `.gpu.aj` to parallelize binary searches across every symbol simultaneously, using thousands of GPU cores.

This tutorial demonstrates the performance enhancement to as-of joins that the `gpu` module brings to the table.

## 1. Prerequisites

1. Requires KDB-X to be installed, you can sign up at https://developer.kx.com/products/kdb-x/install.
2. Ensure you are able to run `src/genHDB.sh` script, which:
    1. Downloads compressed CSVs using `wget -c`. Flag `-c` is sued to resume downloading if internet connection breaks.
    2. Extracts files.
    3. Generates an HDB using modified KX TAQ scripts in `src/tq.q`.

## 2. Loading and Preparing the Data

The path of the HDB directory can be passed as the first parameter of `genHDB.sh`.

```
export SIZE=medium
export QEXEC=`which q`
export DATE=$(curl -s https://ftp.nyse.com/Historical%20Data%20Samples/DAILY%20TAQ/| grep -oE 'EQY_US_ALL_TRADE_2[0-9]{7}' | grep -oE '2[0-9]{7}'|head -1)
bash genHDB.sh ./HDB $DATE
```

A single day of NYSE TAQ files contain a large amount of data.  The test can be sped up if only a part of the BBO split CSV files (source of table `quote`) are considered.
Set the `SIZE` environment variable to control the amount of data ingested into the HDB - except for the `full` mode, only a subset of the BBO split CSV files are downloaded and only those corresponding trades will be converted into HDB.

Some statistics of various DB sizes with data from 2025.01.02 are below:

| `SIZE` | Symbol first letters | HDB size (GB) | # of quote symbols | # of quotes | 
| --- | --- | ---: | ---: | ---: |
| `small` | Z | 1 | 94 | 4 607 158 |
| `medium` | I | 13 | 555 | 180 827 332 |
| `large` | A-H| 52 | 4849 | 707 738 295 |
| `full` | A-Z | 233 | 11155 | 2 313 872 956 |

After generating the HDB and extracting data, launch a q session and load the GPU module:
```q
.gpu:use`kx.gpu
```

## 3. Performing as-of joins

Now, we can step through an example joining trade and quote data on timestamp, comparing GPU vs. CPU.
The core function we expose is `.gpu.aj` which is called as follows:
```q
.gpu.aj[c;t1;t2]
```
where:
- t1 is a table
- t2 is a table
- c is a symbol list of `n` column names, common to `t1` and `t2`, and of matching type
- column c[n] is of a sortable type (typically time)

Important to note that:
- columns in the list `c` may be mapped to the gpu for imporved performance
- the list of valuees `c` can of length 2 at most
- if `c` is of length 2, the only attribute supported on c[0] is the grouped attribute ``g#`

Data can be transferred between CPU and GPU as follows:
```q
.gpu.to t
```

To map only specific columns to the gpu, (`time` and `sym` here), use `.gpu.xto`:
```q
.gpu.xto[`time`sym] t
```

For asof joins (`aj`):
- API automatically transfers to and from for CPU resident tables
- Better performance will be achieved by leaving target columns resident on GPU and using append for updates
- Limited to x2 columns

```q
// can use tables as is that will complete a round trip
.gpu.aj[`time;trade;quote]      // single col
.gpu.aj[`sym`time;trade;quote]  // limited to two cols
```

```q
show (count t;count q)
show 3#t
show 3#q
```

```q
t:get `t
q:get `q
\t t:select from t where i > -1
\t q:select time,`g#sym,mid from q where i > -1
\t T:.gpu.xto[`time`sym] t
\t Q:.gpu.xto[`time`sym] q
```

```q
\t:5 aj[`sym`time;t;q]
\t:5 .gpu.aj[`sym`time;t;Q]
\t:5 .gpu.aj[`sym`time;T;Q]
```

Putting cols on GPU is much faster as you save the roundtrip - use this with append:
```q
q:.gpu.xto[`time`sym;quote]
t:.gpu.xto[`time`sym;trade]
.gpu.from .gpu.aj[`sym`time;t;q]
```

This will also be much faster with the grouped attribute applied ***Test for groupby aggs***
```q
q:.gpu.xgroup[enlist`sym;q]
.gpu.from .gpu.aj[`sym`time;t;q]    / much faster than above
```

## 4. Conclusion

This tutorial demonstrated how to:
- Push specific columns to live on the GPU using `.gpu.xto` so wide tables aren't transferred across PCIe.
- Perform GPU accelerated as-of joins to optimize the cost of performing these operations.

To learn more about KDB-X modules, visit [KDB-X Module Management](https://code.kx.com/kdb-x/modules/module-framework/overview.html).
