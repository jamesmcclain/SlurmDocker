#!/bin/bash

for id in $(aws ec2 describe-instances --filter Name="tag:slurm",Values="leader,follower" Name="instance-state-name",Values="running" | jq '.Reservations[].Instances[].InstanceId' | tr -d '"'); do
    aws ec2 terminate-instances --instance-ids $id
done
