# KDB-X Object Storage Tutorial: From Local to Cloud

## Overview

This tutorial demonstrates how to work with KDB-X's object storage module (`objstor`) using Google Cloud Platform. You'll learn how to:

1. 🌐 Query public datasets directly from GCS
2. 💾 Create a local compressed database
3. ☁️ Upload your database to cloud storage
4. 🔄 Query your private cloud data seamlessly

**What you'll learn:**
- Accessing public cloud databases without credentials
- Creating compressed KDB-X databases optimized for cloud
- Uploading and managing data in GCS buckets
- Querying cloud-based partitioned databases

**Resources**

- [Object Storage Documentation](https://code.kx.com/kdb-x/modules/objstor/overview.html)
- [KDB-X Developer Center](https://developer.kx.com)

**Prerequisites:**
- [KDB-X installed](https://developer.kx.com/products/kdb-x/install)
- Google Cloud SDK (`gcloud`) installed and authenticated
- A GCS bucket created (we'll use variable `bucket` throughout)

Note that this tutorial leverages GCP, but Kurl & REST are also compatible with AWS and Azure, see the docs for information on other cloud platforms.

Let's begin! 

---

## Part 1: Querying Public Cloud Data

KDB-X can query databases stored in public cloud buckets without any authentication. Let's explore the public KX Insights marketplace data.

### Step 1: Set Up Local Database Structure
```bash
gcloud init
mkdir db
gsutil cp gs://kxinsights-marketplace-data/sym ./db
printf "gs://kxinsights-marketplace-data/db" > db/par.txt
```

**What we just did:**
- Created a local `db` directory
- Downloaded the `sym` file (required locally for symbol enumeration)
- Created `par.txt` pointing to the cloud partition location

### Step 2: Start KDB-X and Load Object Storage
```q
q
```
```q
.objstor:use`kx.objstor
.objstor.init[]
```

### Step 3: Load and Query the Database
```q
\l db
```
```q
tables[]
```

Expected output: `` `s#`quote`trade``
```q
select count i by date from trade
```

**⏱️ Note:** This query may take ~2 minutes on first run as data is fetched from GCS. Subsequent queries will be faster if caching is enabled.

### Step 4: Explore the Data
```q
meta trade
```

```q
select count i, avg price, max price, min price by sym from trade where date=2020.01.01
```

**🎉 Success!** You've queried a production database stored entirely in the cloud without downloading it locally.

---

## Part 2: Creating Your Private Cloud Database

Now let's create our own compressed database and upload it to GCS.

### Step 1: Set Up GCP Authentication

Exit your q session with `\\` and run:
```bash
export GCP_TOKEN=$(gcloud auth print-access-token)
```

**💡 Important:** Set your bucket name as a variable for easy reuse:
```bash
export BUCKET="your-bucket-name-here"
```

### Step 2: Start a New q Session with Compression
```q
q
```
**Set compression parameters:**
```q
.z.zd:17 2 6
cz:enlist[`]!enlist .z.zd
```

**Compression settings explained:**
```
17 2 6
│  │ └─ Level (0-9): 6 is good balance of speed/compression
│  └─── Algorithm: 2=gzip, 3=snappy, 4=lz4hc
└────── Block size: 17 means 2^17 = 128KB blocks
```

### Step 3: Generate Sample Trade Data
```q
d:2021.09.01+til 20
```
```q
{[dt;n;cz](sv[`;.Q.par[`:localdb/db/;dt;`trade],`];cz) set .Q.en[`:localdb/db;([]sym:n?`AAPL`MSFT`GOOGL`AMZN`TSLA`META`NVDA`AMD;time:dt+09:30:00.000+asc n?06:30:00.000;price:100+n?100.0;size:100*1+n?100)]}[;10000;cz]each d
```

**What this does:**
- Creates 20 days of trade data (2021.09.01 to 2021.09.20)
- 10,000 trades per day across 8 major tech stocks
- Applies compression settings to all columns
- Saves to `localdb/db/` with proper partitioning

### Step 4: Verify Compression
```q
-21!`:localdb/db/2021.09.01/trade/price
```

Expected output:
```q
compressedLength  | 57817
uncompressedLength| 80016
algorithm         | 2i
logicalBlockSize  | 17i
zipLevel          | 6i
```

**✅ Success!** The file is compressed. Notice `compressedLength` is about ~70% of `uncompressedLength`. We could adjust the parameters to get even more compression.

### Step 5: Load and Query Local Database
**Load the database:**
```q
\l localdb/db
```
**What tables are in the db?**
```q
tables[]
```
Output: ``,`trade``

**Find data types of each column:**
```q
meta trade
```
Output:
```
c    | t f a
-----| -----
date | d
sym  | s
time | p
price| f
size | j
```
**Query for the count trades per symbol on a given date:**
```q
select count i by sym from trade where date=2021.09.01
```
Output:
```
sym  | x
-----| ----
AAPL | 1217
AMD  | 1272
AMZN | 1265
GOOGL| 1224
META | 1306
MSFT | 1210
NVDA | 1297
TSLA | 1209
```

**Query to find number of trades per date:** 
```q
select count i by date from trade
```
Output:
```
date      | x
----------| -----
2021.09.01| 10000
2021.09.02| 10000
2021.09.03| 10000
2021.09.04| 10000
2021.09.05| 10000
...
```

**🎯 Your local compressed database is ready for cloud upload!**

---

## Part 3: Upload to Google Cloud Storage

Now let's move our database to the cloud.

### Step 1: Upload Database Files

Exit q with `\\` and run:
```bash
gsutil -m cp -r localdb/db gs://$BUCKET/
gsutil cp localdb/sym gs://$BUCKET/
```

**⏱️ Note:** The `-m` flag enables parallel uploads for faster transfer.

### Step 2: Verify Upload
```bash
gsutil ls gs://$BUCKET/
```

Expected output:
```
gs://your-bucket/db/
gs://your-bucket/sym
```
```bash
gsutil ls gs://$BUCKET/db/
```

Should show all date partitions: `2021.09.01/` through `2021.09.20/`

---

## Part 4: Query Your Cloud Database

Time to access your private cloud data from KDB-X!

### Step 1: Create Cloud Database Structure Locally
```bash
mkdir clouddb_hdb
gsutil cp gs://$BUCKET/sym clouddb_hdb/
printf "gs://$BUCKET/db" > clouddb_hdb/par.txt
```

**Directory structure:**
```
clouddb_hdb/
├── par.txt  (contains: gs://your-bucket/db)
└── sym      (local copy)
```

### Step 2: Initialize Object Storage
```q
q
```
```q
.objstor:use`kx.objstor
.objstor.init[]
```

### Step 3: Verify Cloud Access

Before loading the database, let's verify we can access the bucket:

To list date partitions use `key`:
```q
key`$":gs://",getenv[`BUCKET],"/db"
```

To list files in a folder: (Returns `` `s#`.d`price`size`sym`time``)
```q
key`$":gs://",getenv[`BUCKET],"/db/2021.09.01/trade/"
```

To get the columns (in order) of a table: (Returns: `` `sym`time`price`size``)
```q
get`$":gs://",getenv[`BUCKET],"/db/2021.09.01/trade/.d"
```


### Step 4: Check File Properties
```q
hcount`$":gs://",getenv[`BUCKET],"/db/2021.09.01/trade/sym"
```
```q
-21!`$":gs://",getenv[`BUCKET],"/db/2021.09.01/trade/price"
```

**✅ Compression info confirmed!** Your cloud files are properly compressed.

### Step 5: Load Cloud Database
```q
\l clouddb_hdb
```
```q
tables[]
```

Expected: ``,`trade``
```q
meta trade
```
```q
select count i by sym from trade where date=2021.09.01
```

Expected output:
```q
sym  | x
-----| ----
AAPL | 1217
AMD  | 1272
AMZN | 1265
GOOGL| 1224
META | 1306
MSFT | 1210
NVDA | 1297
TSLA | 1209
```

### Step 6: Run Analytics
```q
select count i by date from trade
```
```q
select avg price, max price, min price, sum size by sym from trade
```
```q
select high:max price, low:min price, open:first price, close:last price by date, sym from trade where date within 2021.09.01 2021.09.05
```

**🎉 Congratulations!** You're now querying your private compressed database stored entirely in Google Cloud Storage!

---

## Part 5: Performance Optimization

### Enable Caching for Faster Queries

Cloud storage has high latency. Enable local caching to dramatically improve performance:

Exit q with `\\` and set cache location:
```bash
export KX_OBJSTR_CACHE_PATH=/tmp/kdb-cache
mkdir -p /tmp/kdb-cache
```

**For best performance, use shared memory:**
```bash
export KX_OBJSTR_CACHE_PATH=/dev/shm/cache
mkdir -p /dev/shm/cache
```

Restart q and reload:
```q
q
```
```q
.objstor:use`kx.objstor
.objstor.init[]
\l clouddb_hdb
```

**Test cache performance:**
```q
\t select count i by date from trade
```

First run: ~2000ms (fetching from cloud)
```q
\t select count i by date from trade
```

Second run: ~0ms (reading from cache) 🚀

### Use Secondary Threads

For better concurrency with cloud queries:
```bash
q -s 4
```

More threads = better performance for cloud data. Recommended: Use more threads than CPU cores.

---

## 🎯 Summary

You've successfully:

✅ Queried public cloud databases without authentication  
✅ Created a compressed local database optimized for cloud storage  
✅ Uploaded your database to Google Cloud Storage  
✅ Configured and queried your private cloud database  
✅ Optimized performance with caching and threading  

### Key Concepts Learned

**Object Storage Module:**
- `objstor` enables seamless cloud data access
- Works with AWS S3, Azure Blob, and GCS
- Requires only `sym` file locally, partitions stay in cloud

**Compression:**
- Set compression BEFORE creating data with `.z.zd:17 2 6`
- Reduces storage costs and transfer time
- Essential for cloud deployments

**Cloud Structure:**
- Local: `sym` file + `par.txt` pointing to cloud
- Cloud: Partitioned database in bucket
- Query just like local data!


Happy cloud querying! 🌥️