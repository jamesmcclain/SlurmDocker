#!/bin/bash

/scripts/slurm-config.sh $1 $2 $3
/scripts/munged.sh $4
/usr/local/sbin/slurmd
bash
