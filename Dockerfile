FROM ubuntu:17.04
MAINTAINER James McClain <james.mcclain@gmail.com>

RUN apt-get update && apt-get install -y gcc libgcrypt20-dev make python

ADD archives/munge-0.5.12.tar.xz /root/local/src/
ADD archives/slurm-17-02-6-1.tar.gz /root/local/src/

