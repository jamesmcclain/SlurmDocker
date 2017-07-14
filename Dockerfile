FROM ubuntu:17.04
MAINTAINER James McClain <james.mcclain@gmail.com>

RUN apt-get update && apt-get install -y gcc libgcrypt20-dev make python

ADD archives/munge-0.5.12.tar.xz /root/local/src/
ADD archives/slurm-17-02-6-1.tar.gz /root/local/src/

RUN cd /root/local/src/munge-0.5.12 && ./configure --prefix=/usr/local && make -j && make install
RUN cd /root/local/src/slurm-slurm-17-02-6-1 && ./configure --prefix=/usr/local && make -j && make install && ldconfig -n /usr/local/lib

COPY scripts/munged.sh /scripts/munged.sh
COPY config/slurm.conf /usr/local/etc/

RUN useradd munge -m
RUN useradd slurm -m && usermod -a -G root slurm
