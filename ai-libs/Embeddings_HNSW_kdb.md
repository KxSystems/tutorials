# Hacker News Embeddings with HNSW in kdb+
> **Note**: This tutorial is part of a beta release of software that is not yet publicly available. Please contact KX for access.
> 
This tutorial walks through the process of creating a kdb+ historical database (HDB) filled with Hacker News data and embeddings. It then demonstrates how to build an HNSW (Hierarchical Navigable Small World) index per partition for efficient nearest neighbor searches.

## 1. Prerequisites

1. Reqiures a beta release of kdb+ to be installed.
2. Download the ai-libs, also part of the beta release.
3. Ensure you have the necessary dataset:
   1. Download the dataset from Kaggle: [Hacker News OpenAI Embeddings](https://www.kaggle.com/datasets/julien040/hacker-news-openai-embeddings?resource=download)
   2. Extract `archive.zip` into the same directory as this script. The file `story.csv` should be available in this directory.

## 2: Extracting Data and Creating the HDB

Launch a q session and load the ai-libs initialization script in:
```q
\l kdbai/init.q
```

Load the dataset into a table:

```q
tab: ("JSSJJSS*"; enlist ",") 0: `:story.csv;
tab: update embeddings:0^flip (1536#"E"; ",") 0: embeddings from tab;
tab: update time: ("p"$(time*1e9) - 946684800000000000) from tab;
```

Convert timestamps and extract unique dates:

```q
dts: asc exec distinct `date$time from tab;
```

Now, we create an HNSW index per partition. This process can take some time, but you can filter the dataset for a smaller subset if necessary:

```q
{[dt;t]
    hnswobj: .ai.hnsw.put[();(); exec embeddings from t where dt=`date$time; `L2; 8; 0Ne; 8];
    hnsw: ([] hnsw: enlist hnswobj);
    (hsym `$"db/", string[dt], "/hnsw/") set hnsw;
    (hsym `$"db/", string[dt], "/news/") set .Q.en[`:db] `time xasc select from t where dt=`date$time;
    .Q.gc[]; // Garbage collection to optimize memory usage
}[;tab] each dts;
```

Verify database integrity:

```q
.Q.chk[`:db]
```

Load the database:

```q
.Q.lo[`:db;0;0];
```

## Part 2: Querying the HNSW Index

Find an example query vector by selecting a title of interest:

```q
5 sublist select title, score from news where date within (2022.01.01; 2023.01.01);
```

Example output:

```
Title: Finding your home in game graphics programming
```

Retrieve the embedding for this article:

```q
q: first exec embeddings from (select embeddings from news where date within (2022.01.01; 2023.01.01)) where i=4;
```

Run a nearest neighbor search using HNSW:

```q
\t t1: .walkthroughUtil.queryPartitionHnsw[q; 2022.01.01; 2023.01.01; (); 5; `L2; 8];
```

Run a nearest neighbor search using a flat search:

```q
\t t2: .walkthroughUtil.queryPartitionFlat[q; 2022.01.01; 2023.01.01; (); 5; `L2];
```

Compare the results:

```q
t1 ~ t2;
```

Retrieve results:

```q
select dist, title, score from t1;
```

Example output:

```
| dist      | title                                                  | score |
|-----------|--------------------------------------------------------|-------|
| 0         | Finding your home in game graphics programming        | 247   |
| 0.2746519 | Why are 2D vector graphics so much harder than 3D?    | 135   |
| 0.3037856 | The harsh truth of video games programming            | 175   |
| 0.3080716 | A Great Old-Timey Game-Programming Hack               | 140   |
| 0.3113103 | The Apple GPU and the impossible bug                  | 965   |
```

### Filtering by Score

Determine the range of scores in the dataset:

```q
select max score, min score, avg score from news;
```

Run a filtered search for high-score articles:

```q
\t t1: .walkthroughUtil.queryPartitionHnsw[q; 2022.01.01; 2023.01.01; enlist (<;500;`score); 5; `L2; 8];
\t t2: .walkthroughUtil.queryPartitionFlat[q; 2022.01.01; 2023.01.01; enlist (<;500;`score); 5; `L2];
```

Compare results:

```q
t1 ~ t2;
```

Retrieve results:

```q
select dist, title, score from t1;
```

Example output:

```
| dist      | title                                                  | score |
|-----------|--------------------------------------------------------|-------|
| 0.3113103 | The Apple GPU and the impossible bug                  | 965   |
| 0.3219757 | Aging programmer                                      | 596   |
| 0.3530114 | I’m a productive programmer with a memory of a fruit fly | 650   |
| 0.3765028 | Electrical engineers on the brink of extinction       | 526   |
| 0.3849241 | Tales of the M1 GPU                                   | 601   |
```

### Conclusion

This guide demonstrated how to:
- Load Hacker News data into kdb+
- Create an HDB with partitions
- Generate HNSW indexes for fast nearest-neighbor searches
- Query for similar articles using HNSW and flat search
- Filter search results by specific conditions

In this case, since there are relatively few vectors per partition, flat searches can sometimes be faster than HNSW. However, for larger datasets, HNSW provides significant performance improvements.

---

This markdown provides a structured explanation of the kdb+/q script, guiding users through data loading, indexing, and querying while showcasing performance trade-offs.

