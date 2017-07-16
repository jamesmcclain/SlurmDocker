#!/bin/bash

NODES=${1:-"leader"}
CPUS=${2:-"ThreadsPerCore=2 CoresPerSocket=8 Sockets=2"}

sed -e "s/XXX/$NODES/" -e "s/YYY/$CPUS/" /usr/local/etc/slurm.conf.template > /usr/local/etc/slurm.conf
