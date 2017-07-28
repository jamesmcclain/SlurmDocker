# Obtaining #

To build the image, clone the repository and execute the `image` makefile target.
```bash
git clone 'git@github.com:jamesmcclain/SlurmDocker.git'
cd SlurmDocker
make image
```

Or, the image can be pulled from [DockerHub](https://hub.docker.com/r/jamesmcclain/slurm/).
```bash
docker pull 'jamesmcclain/slurm:0'
```

# Usage #

The image can be used locally or on AWS.

## Local ##

### Single Node ###

To run a single local instance, type the following.
```bash
docker run \
   -it --rm \
   --name leader --hostname leader \
   jamesmcclain/slurm:0 /scripts/leader.sh leader leader CPUs=1
```

The `--name` and `--hostname` flags respectively set the container name and the hostname within the container to `leader`.
The `/scripts/leader.sh` script is executed within the container, setting the name of the control node and the list of compute nodes to `leader` and `leader`, respectively; there is one CPU per compute node.
The control node and the single compute node run within the same container.

Executing the command above will bring you to shell prompt within the container.
Here is an example interaction.
```
root@leader:/# sinfo 
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
queue*       up   infinite      1   idle leader
root@leader:/# srun hostname
leader
root@leader:/#
```

### Multi-Node ###

To run multiple local nodes, first create a bridge network on-which the nodes can communicate.
```bash
docker network create --driver bridge slurm
```

To start the leader node, type the following.
```bash
docker run \
   --net=slurm \
   -it --rm \
   --name leader --hostname leader \
   jamesmcclain/slurm:0 /scripts/leader.sh leader leader,follower CPUs=1
```

This is the same as the invocation above, except that the list of compute nodes is now `leader,follower` instead of just `leader`.

To start the follower, type the following in a different terminal.
```bash
docker run \
   --net=slurm \
   -it --rm \
   --name follower --hostname follower \
   jamesmcclain/slurm:0 /scripts/follower.sh leader leader,follower CPUs=1
```

You should now be able to submit jobs that run both/either of the nodes.
Here is a sample interaction on the leader node.
```
root@leader:/# sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
queue*       up   infinite      2   idle follower,leader
root@leader:/# srun -n 2 hostname
leader
follower
root@leader:/# cat <<EOF > /tmp/local_script.sh
> #!/bin/bash
> hostname
> EOF
root@leader:/# chmod u+x /tmp/local_script.sh
root@leader:/# salloc -n 2
salloc: Granted job allocation 13
root@leader:/# sbcast /tmp/local_script.sh /tmp/script.sh
root@leader:/# srun /tmp/script.sh
follower
leader
root@leader:/# exit
salloc: Relinquishing job allocation 13
```

## AWS ##

# License #

The contents of this repository are covered under the [MIT License](https://github.com/jamesmcclain/SlurmDocker/blob/master/LICENSE.md).
The actual pieces of software (Slurm, MUNGE, &c) belong to their respective owners and covered by their respective licenses.
