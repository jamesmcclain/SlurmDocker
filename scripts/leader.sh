#!/bin/bash

/scripts/slurm-config.sh $1 $2
/scripts/munged.sh $3
/usr/local/sbin/slurmctld
/usr/local/sbin/slurmd
