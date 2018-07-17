FROM ivotron/openssh:7.7 AS base

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y --no-install-recommends --no-install-suggests install \
       openmpi-bin libopenmpi-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    echo 'Host *' > /root/.ssh/config && \
    echo 'StrictHostKeyChecking no' >> /root/.ssh/config && \
    echo 'LogLevel quiet' >> /root/.ssh/config && \
    chmod 600 /root/.ssh/config

FROM base AS openmpi

RUN apt-get update && \
    apt-get -y --no-install-recommends --no-install-suggests install \
       g++ make && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD example/ /example/
RUN make -C /example

FROM base AS release

COPY --from=openmpi /example/mpi_helloworld /usr/bin/
ADD mpirun_docker /usr/bin
ADD copyresults /usr/bin

ENTRYPOINT ["mpirun_docker"]
