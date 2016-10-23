FROM ivotron/openmpi

ARG DEBIAN_FRONTEND=noninteractive

ADD mpi_helloworld.c /root/
ADD Makefile /root/

RUN cd /root/ && make

ENTRYPOINT ["mpirun_docker", "/root/mpi_helloworld"]

