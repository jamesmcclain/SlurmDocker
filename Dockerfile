FROM ubuntu:17.04
MAINTAINER James McClain <james.mcclain@gmail.com>

RUN apt-get update && apt-get install -y gcc libgcrypt20-dev libncurses5-dev make python

ADD archives/munge-0.5.12.tar.xz /root/local/src/
ADD archives/slurm-17-02-6-1.tar.gz /root/local/src/

RUN cd /root/local/src/munge-0.5.12 && ./configure --prefix=/usr/local && make -j && make install
RUN cd /root/local/src/slurm-slurm-17-02-6-1 && ./configure --prefix=/usr/local && make -j && make install && ldconfig -n /usr/local/lib
RUN useradd munge -m && useradd slurm -m && mkdir /tmp/slurm && chown slurm:slurm -R /tmp/slurm

COPY scripts/munged.sh /scripts/munged.sh
COPY scripts/slurm-config.sh /scripts/slurm-config.sh
COPY scripts/leader.sh /scripts/leader.sh
COPY scripts/follower.sh /scripts/follower.sh
COPY config/slurm.conf.template /usr/local/etc/
