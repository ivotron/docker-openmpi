FROM debian:stretch

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y --no-install-recommends \
       install openssh-server openmpi-bin libopenmpi-dev make gcc && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /var/run/sshd && \
    sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && \
    sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config && \
    sed -i "s/PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
ADD entrypoint.sh /root/
ENV AUTHORIZED_KEYS **None**
ENV SSHD_PORT 22

ENTRYPOINT ["/root/entrypoint.sh"]
