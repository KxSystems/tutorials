# 🚀 KDB-X GPU Acceleration Tutorials

The GPU Acceleration of KDB-X is a new iteration of KDB-X that ships the `.gpu` namespace as a first-class, production-ready capability.
Everything q-related is untouched - same syntax, same data model, same table semantics - but the most compute-intensive operations in your stack can now be offloaded to NVIDIA GPUs, keeping data GPU-resident across multiple steps and only returning results to the CPU when you actually need them.
This folder contains concise, step-by-step tutorials designed to help developers optimize performance that otherwise can be the source of CPU bottlenecks, accelerating various table and mathematical operations.

The GPU module provides a number of APIs allowing users to build KDB-X workloads which can leverage GPU compute for specific operations:
- Joins: `aj` (asof joins)
- Sorts and Searches: `iasc`, `asc`, `xasc`, and `bin`
- Functional `selects` including binary operations, whereclause and group by aggregations
**Will need to change this link when the docks are live**
The full library of examples can be found here: [GPU Examples](https://kxdev.gitlab.io/-/documentation/docs-next/-/jobs/13580876958/artifacts/public/modules/gpu/examples.html)

KDB-X workloads can be built from existing GPU enabled KDB-X ecosystems.
Operations can be performed on data resident across both CPU and GPU devices.
In each of the following tutorials, we explore the APIs used to manage data transfers across devices.

## 📖 Tutorials

[Accelerating as-of joins](asOfJoins.ipynb)

[Sorting data in-memory and on-disk](sorting.ipynb)

## Running a KDB-X GPU Application

### Prerequisites

For running a KDB-X CUDA application in a configured environment:
1. A working KDB-X install in `$HOME/.kx`
2. A KDB-X license file stored in `$HOME/.kx`
3. A `gpu.li64.so` file in `$HOME/.kx/mod/kx`

**Will need to change this link when the docks are live**
To learn more about the configuration for a KDB-X CUDA environment, read about the GPU Setup here: [GPU Enabled Environment for KDB-X](https://kxdev.gitlab.io/-/documentation/docs-next/-/jobs/13580876958/artifacts/public/modules/gpu/quickstart/gpu-env.html)

### Building

All commands are run from this current location (`tutorials/KDB-X/Modules/gpu`) unless otherwise specified.

Build the image using:

```
$ docker build -f Dockerfile -t kdbxgpu .
```

#### Running

From this repository (within `gpu` folder), run the image and `Sorting.ipynb` notebook using:

```
$ docker run --rm -it -p 8888:8888 --gpus all -e QARGS='-s 48' -v $HOME/.kx:/app/.kx -v /storage/tier/db:/app/example/db -v .:/app/example kdbxgpu Sorting.ipynb
```

Note: The above command instructs `q` to use a maximum of 48 secondary threads. Modify `QARGS='-s 48'` to use the number of threads you desire.

To run the `asOfJoins.ipynb` notebook, we first need to download the associated dataset into a directory before running the Docker container. Description on this can be found here: [hdbDataGen](docs/hdbDataGen.md)

Once our data has been downloaded and HDB has been created, we want to run the Docker container with this data mounted to a volume so it can be loaded into the asOfJoins notebook.

Keep in mind the directory used to download the data - by default, this will be downloaded to `/src/HDB/tq/zd0_0_0`. If your configured directory differs, replace `"$(pwd)/src/HDB/tq/zd0_0_0/` with the proper directory path.
Now to run the `asOfJoins.ipynb` notebook on the docker image, execute the following:
```bash
docker run --rm -it \
  -p 8888:8888 \
  --gpus all \
  -e QARGS='-s 48' \
  -v "$HOME/.kx:/app/.kx" \
  -v /storage/tier/db:/app/example/db \
  -v "$(pwd):/app/example" \
  -v "$(pwd)/src/HDB/tq/zd0_0_0/:/app/example/HDB/data" \
  kdbxgpu asOfJoins.ipynb
```

#### Queries

These notebook can be interacted with in several ways:
1. Connect to the notebook at `localhost:8888/lab/tree/<notebook_name>.ipynb` and follow the instructions
2. In VSCode, the Jupyter Notebook file can be pointed directly at `http://127.0.0.1:8888/lab` and code can then be executed directly from the VSCode file
3. To run via q terminal, connect to the running docker container using `docker exec -it <docker_container_id> /bin/bash` - in this bash terminal, run `q` to start a q session, and all q code could then be executed directly from there

To learn more about KDB-X modules, visit [KDB-X Module Management](https://code.kx.com/kdb-x/modules/module-framework/overview.html).
