# docker-openmpi

Image intended to be used for building MPI-based container images. It 
is based on 
[`ivotron/openssh`](https://github.com/ivotron/docker-openssh). For an 
example on how to build on top of this image, take a look at the 
[`helloworld`](example/) MPI application (whose binary included in 
this image).

## `entrypoint` of derived images

The image contains an `mpirun_docker` utility that mimics the `mpirun` 
application. The command reads a `/tmp/mpihosts` file if exists. An 
error is thrown if not. This file should have one line per each docker 
host (hostname or IP address) that runs an MPI container. **NOTE**: 
while a regular `hostfile` can contain more than just the hostname or 
IP on each line, we assume this is not the case (for the purposes of 
shutting down the containers).

The `entrypoint` of the `openmpi` container is this `mpirun_docker` 
command. With this, the entrypoint specified in the `Dockerfile` can 
be something like:

```dockerfile
ENTRYPOINT ["mpirun_docker", "mympiapp"]
```

For an example, look at the [`mpi_helloworld` 
Dockerfile](example/Dockerfile). Note that with this approach, 
invoking `docker run <docker_flags> <image_name> <app_args>` can be 
seen as invoking `mpirun` and passing flags to the application.

An `MPIRUN_FLAGS` environment variable is passed to the `mpirun` 
command which can be used to specify additional options. The 
`mpirun_docker` command assumes that all the hosts specified in 
`/tmp/mpihosts` inside containers and using the same `sshd` port and 
authentication method.

## Running

In order to run an MPI application (say, with corresponding image 
`ivorton/mympiapp`), we launch the containers on multiple hosts.

```bash
# run on each docker host (e.g. host1)
docker run -d \
    --name=mympiapp \
    --net=host \
    -e SSHD_PORT=2222 \
    -e ADD_INSECURE_KEY=1 \
  ivorton/mympiapp
```

One of those containers needs to be "marked" as the head node by 
passing the `-e RANK0=1` flag. For example, a second node (`host0`) is 
launched by doing:

```bash
# launch the MPI head container (e.g. on host0)
docker run -d \
    --name=mympiapp \
    --net=host \
    -v `pwd`/output:/results \
    -e SSHD_PORT=2222 \
    -e ADD_INSECURE_KEY=1 \
    -e RANK0=1 \
  ivorton/mympiapp
```

> **Caveats**: The node marked with `RANK0` has a default TIMEOUT of 
> 60 seconds to wait for others to launch their corresponding `sshd` 
> daemon. That can be overridden with a `WAIT_SSHD_SECS` environment 
> variable. Also, if no container is marked as being `RANK0`, the 
> containers will run indefinitely since the only thing they do is to 
> initialize `sshd`.

The container runs `mpirun` on the container marked as `RANK0` and 
`stdout` and `stderr` are written to `mpirun.out` and `mpirun.err` 
files that are placed in a `/results` folder. To persist this files, 
one can bind-mount this folder from the host (as shown above). In the 
`helloworld` example, the contents of the `mpirun.out` file will be:

```
Hello world from processor host0, rank 1 out of 8 processors
Hello world from processor host0, rank 2 out of 8 processors
Hello world from processor host0, rank 3 out of 8 processors
Hello world from processor host0, rank 0 out of 8 processors
```

While other docker hosts' `mpirun.out` file (`host1` in this case) 
will show:

```
Hello world from processor host1, rank 7 out of 8 processors
Hello world from processor host1, rank 5 out of 8 processors
Hello world from processor host1, rank 6 out of 8 processors
Hello world from processor host1, rank 4 out of 8 processors
```

After the application exits, all the containers corresponding to the 
hosts referenced in `/tmp/mpihosts` file are terminated (using the 
`stopsshd` command from the [`openssh` base 
image](https://github.com/ivotron/docker-openssh)).

## Application-specific post-processing

The `mpirun_docker` command looks for a `mpipostrun` command in the 
`PATH` and, if available, it invokes it. This can be used to add 
user-defined logic for post-processing MPI output (e.g. copying log 
files). For an example look at 
[here](https://github.com/ivotron/docker-bench/tree/master/conceptual).
