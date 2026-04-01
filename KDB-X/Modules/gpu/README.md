# 🚀 KDB-X GPU Acceleration Tutorials

GPU Acceleration is a new offering of KDB-X that ships the `gpu` module as a first-class, production-ready capability.
This folder contains concise, step-by-step tutorials designed to help developers optimize performance that otherwise can be the source of CPU bottlenecks, accelerating various table and analytical operations.

The [GPU module](https://code.kx.com/kdb-x/modules/gpu/introduction.html) provides a number of APIs allowing users to build KDB-X workloads which can leverage GPU computing for specific operations:
- As-Of Joins: `aj`
- Sorts and Searches: `iasc`, `asc`, `xasc`, and `bin`
- Functional `selects` including binary operations, whereclause and group by aggregations

The full API reference can be found on the [GPU reference card](https://code.kx.com/kdb-x/modules/gpu/reference.html)

## 📖 Tutorials

[Accelerating as-of joins](asOfJoins.ipynb)

[Sorting data in-memory and on-disk](sorting.ipynb)

## Running a KDB-X GPU Application

### Prerequisites

The following are required to run a KDB-X GPU application in a CUDA configured environment:
1. A working KDB-X install in `$HOME/.kx`
2. A KDB-X license file stored in `$HOME/.kx` (`gpu` flagged license is required)
3. A `gpu.li64.so` file in `$HOME/.kx/mod/kx`

To learn more about the configuration for a KDB-X CUDA environment, read about the GPU Setup here: [GPU Enabled Environment for KDB-X](https://code.kx.com/kdb-x/modules/gpu/quickstart/gpu-env.html)

### Building

All below commands are run from within the top level of this tutorial (`tutorials/KDB-X/Modules/gpu`).

In order to walk through some of the examples, we first want to build a docker image to isolate a CUDA software environment.

The image can be built by running:

```bash
docker build -f Dockerfile -t kdbxgpu .
```

#### Running

We can now run a docker container hosting our tutorial notebooks - use the following commands to start them up:

**Sorting.ipynb**
```bash
docker run --rm -it -p 8888:8888 --gpus all -v $HOME/.kx:/app/.kx -v .:/app/example kdbxgpu Sorting.ipynb
```
**asOfJoins.ipynb**
```bash
docker run --rm -it -p 8888:8888 --gpus all -v $HOME/.kx:/app/.kx -v .:/app/example kdbxgpu asOfJoins.ipynb
```

#### Queries

Once up and running, these notebooks can be interacted with in several ways:
1. Connect to the notebook at `localhost:8888/lab/tree/<notebook_name>.ipynb` and follow the instructions
2. In VSCode, the Jupyter Notebook file can be pointed directly at `http://127.0.0.1:8888/lab` and code can then be executed directly from within the VSCode notebook (may require the [Jupyter extension](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter))
3. To run via q terminal within the container, connect to the running docker container using `docker exec -it <docker_container_id> /bin/bash` - from this bash terminal, run `q` to start a q session, and all q code could then be executed directly from there

To learn more about KDB-X modules, visit [KDB-X Module Management](https://code.kx.com/kdb-x/modules/module-framework/overview.html).

Happy coding! 🎯
