FROM ivotron/openssh

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y --no-install-recommends install \
       openmpi-bin libopenmpi-dev make g++ && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    echo 'Host *' > /root/.ssh/config && \
    echo 'StrictHostKeyChecking no' >> /root/.ssh/config && \
    echo 'LogLevel quiet' >> /root/.ssh/config && \
    chmod 600 /root/.ssh/config

ADD mpirun_docker /usr/bin
ADD mpistop /usr/bin
