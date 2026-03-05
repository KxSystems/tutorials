# 🚀 GPU Tutorials

The GPU Edition of KDB-X is a new iteration of KDB-X that ships the `.gpu` namespace as a first-class, production-ready capability.
Everything q-related is untouched - same syntax, same data model, same table semantics - but the most compute-intensive operations in your stack can now be offloaded to NVIDIA GPUs, keeping data GPU-resident across multiple steps and only returning results to the CPU when you actually need them.
This tutorial highlights concrete examples where this new module can be leveraged to optimize performance that otherwise can be the source of CPU bottlenecks, accelerating various table and mathematical operations by several ??factors??.

This folder contains concrete examples to help developers quickly understand how to leverage GPUs to optimize performance that otherwise can be the source of CPU bottlenecks, accelerating various table and mathematical operations by several degrees.

**Important!** Intel-based macOS is not supported at this time.

## 📖 Tutorials
1️⃣ Accelerating as-of joins
- Utilize `.gpu.aj` to optimize table joins on a list of columns.
- xx `.gpu.xto` to map only specific columns to the gpu.

2️⃣ Sorting data in-memory and on-disk
- xx `.gpu.iasc` for sorting data in-memory
- xx `.gpu.xasc` for sorting data on-disk

## 💻 Setup

### Running Locally

#### Prerequisites

1. A working kdb-x install in `$HOME/.kx`
2. A kdb-x license file stored in `$HOME/.kx`
3. A `gpu.li64.so` file in `$HOME/.kx/mod/kx`

All commands are run from the repository root unless otherwise specified.

#### Building

Build the image using:

```
$ docker build -f examples/Dockerfile -t gpuexamples .
```

#### Running

Move into the example folder (e.g. joins) and run the image using:

```
$ docker run --rm -it -p 8888:8888 --gpus all -e QARGS='-s 48' -v $HOME/.kx:/app/.kx -v /storage/tier/db:/app/example/db -v .:/app/example gpuexamples notebook.ipynb
```

Note: The above command instructs `q` to use a maximum of 48 secondary threads. Modify `QARGS='-s 48'` to use the number of threads you desire.

#### Queries

Connect to the notebook at `localhost:8888/lab/tree/notebook.ipynb` and follow the instructions.

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

