# docker-openmpi

Image intended to be used for building MPI-based container images. It 
is based on 
[`ivotron/openssh`](https://github.com/ivotron/docker-openssh). 

## Building Images

Example `Dockerfile`:

```Dockerfile
FROM ivotron/openmpi

ADD mpi_helloworld.c /root/
ADD Makefile /root/

RUN cd /root && \
    make && \
    mv mpi_helloworld /usr/bin
```

Where `mpi_helloworld.c` is:

```c
#include <mpi.h>
#include <stdio.h>

int main(int argc, char** argv) {
  // Initialize the MPI environment. The two arguments to MPI Init are not
  // currently used by MPI implementations, but are there in case future
  // implementations might need the arguments.
  MPI_Init(NULL, NULL);

  // Get the number of processes
  int world_size;
  MPI_Comm_size(MPI_COMM_WORLD, &world_size);

  // Get the rank of the process
  int world_rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

  // Get the name of the processor
  char processor_name[MPI_MAX_PROCESSOR_NAME];
  int name_len;
  MPI_Get_processor_name(processor_name, &name_len);

  // Print off a hello world message
  printf("Hello world from processor %s, rank %d out of %d processors\n",
         processor_name, world_rank, world_size);

  // Finalize the MPI environment. No more MPI calls can be made after this
  MPI_Finalize();
}
```

And `Makefile`:

```Makefile
all: mpi_helloworld

mpi_helloworld: mpi_helloworld.c
  mpicc -o mpi_helloworld mpi_helloworld.c
```

## Running

For running an MPI application (say, with corresponding image 
`ivorton/mympiapp`), we launch the containers on multiple hosts and 
SSH into the master node (or run `docker exec` on it). For example:

```bash
# this runs on each docker host (e.g. host1 and host2)
docker run -d \
    --name=mympiapp \
    --net=host \
    -e SSHD_PORT=2222 \
    -e ADD_INSECURE_KEY=1 \
  ivorton/mympiapp

# on the master node (e.g. host1)
docker exec mympiapp mpirun \
  --allow-run-as-root \
  --host host1,host2 \
  --mca plm_rsh_args '-p 2222' \
  -np 8 \
  mpi_helloworld

Hello world from processor host1, rank 1 out of 8 processors
Hello world from processor host2, rank 5 out of 8 processors
Hello world from processor host1, rank 2 out of 8 processors
Hello world from processor host2, rank 7 out of 8 processors
Hello world from processor host1, rank 3 out of 8 processors
Hello world from processor host2, rank 4 out of 8 processors
Hello world from processor host2, rank 6 out of 8 processors
Hello world from processor host1, rank 0 out of 8 processors
```
