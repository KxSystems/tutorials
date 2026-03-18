# 🚀 KDB-X GPU Edition Tutorials

The GPU Edition of KDB-X is a new iteration of KDB-X that ships the `.gpu` namespace as a first-class, production-ready capability.
Everything q-related is untouched - same syntax, same data model, same table semantics - but the most compute-intensive operations in your stack can now be offloaded to NVIDIA GPUs, keeping data GPU-resident across multiple steps and only returning results to the CPU when you actually need them.
This folder contains concise, step-by-step tutorials designed to help developers optimize performance that otherwise can be the source of CPU bottlenecks, accelerating various table and mathematical operations.

The GPU module provides a number of APIs allowing users to build KDB-X workloads which can leverage GPU compute for specific operations:
- Joins: `aj` (asof joins)
- Sorts and Searches: `iasc`, `asc`, `xasc`, and `bin`
- Functional `selects` including binary operations, whereclause and group by aggregations

KDB-X workloads can be built from existing GPU enabled KDB-X ecosystems.
Operations can be performed on data resident across both CPU and GPU devices.
In each of the following tutorials, we explore the APIs used to manage data transfers across devices.

## 📖 Tutorials
GPU Module User Guide (`userguide.ipynb`)
- Showcase the different APIs to be utilized in building KDB-X workloads that leverage GPU compute on CPU-intensive operations

Accelerating as-of joins (`asOf_joins.md`)
- Utilize `.gpu.aj` to optimize table joins on a list of columns
- xx `.gpu.xto` to map only specific columns to the gpu

Sorting data in-memory and on-disk (`sorting.ipynb`)
- xx `.gpu.iasc` for sorting data in-memory
- xx `.gpu.xasc` for sorting data on-disk

## Running a KDB-X GPU Application

### Prerequisites

For running a KDB-X CUDA application in a configured environment:
1. A working KDB-X install in `$HOME/.kx`
2. A KDB-X license file stored in `$HOME/.kx`
3. A `gpu.li64.so` file in `$HOME/.kx/mod/kx`

### Building

All commands are run from this current location (`tutorials/KDB-X/Modules/gpu`) unless otherwise specified.

Build the image using:

```
$ docker build -f Dockerfile -t kdbx-gpu .
```

#### Running

From this repository (within `gpu` folder), run the image using:

```
$ docker run --rm -it -p 8888:8888 --gpus all -e QARGS='-s 48' -v $HOME/.kx:/app/.kx -v /storage/tier/db:/app/example/db -v .:/app/example kdbxgpu <notebook_name>.ipynb
```

Replace `<notebook_name>.ipynb` in the above command with either `sorting.ipynb` to run the Sorting tutorial, or `asOf_joins.ipynb` to run the AsOf Joins tutorial.

Note: The above command instructs `q` to use a maximum of 48 secondary threads. Modify `QARGS='-s 48'` to use the number of threads you desire.

#### Queries

Connect to the notebook at `localhost:8888/lab/tree/<notebook_name>.ipynb` and follow the instructions.

## 🤝 Got a question?
Want to connect with other developers or get help? Join our Slack community https://kx.com/slack or ask a question on https://forum.kx.com

================================================================================================

## 2. GPU-accelerated sorting

### Full table sort: `.gpu.xasc`

### Index-based sort: `.gpu.iasc`

### On-disk sorting

## 3. Scaling VaR across multiple GPUs

## 4. Matrix Multiplication

## 5. Vector Similarity Searches

## Key Takeaways

- **Interoperability:** Being able to use q with Parquet open file format means users can exchange data with ecosystems such as Spark, Pandas, Arrow etc.
- **Fast Analytics at Scale:**  Query large Parquet datasets efficiently with virtual tables.
- **Seamless Integration:** Use q queries directly on Parquet files, alongside in-memory or partitioned tables.

To learn more about KDB-X modules, visit [KDB-X Module Management](https://code.kx.com/kdb-x/modules/module-framework/overview.html).

