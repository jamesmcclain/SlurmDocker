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

The `--name` and `--hostname` flags respectively set the container name and the hostname within the container to `leader` and `leader`.
The `/scripts/leader.sh` script is executed within the container, setting the name of the control node and the list of compute nodes to `leader` and `leader`, respectively; there is one CPU per compute node.
The control daemon and the single compute daemon run within the same container.

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

To start the leader, type the following.
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

### Start ###

Clone this repository, and from the root directory of the repository type something like this
```bash
INSTANCE_PROFILE=xxx SECURITY_GROUP=yyy KEYPAIR=zzz make start-ec2
```
where `INSTANCE_PROFILE`, `SECURITY_GROUP`, and `KEYPAIR` are appropriately substituted.

   - `INSTANCE_PROFILE` should be the name of an instance profile that gives instances sufficient priviledges to use the AWS CLI tools.
That is necessary because the [boostrap script](scripts/bootstrap.sh.template) uses AWS CLI to determine the name of the leader and the names of the other nodes in the cluster.
A role with the policy `AmazonEC2ReadOnlyAccess` should be sufficient.
   - `SECURITY_GROUP` should be the name of a security group that allows intra-VPC traffic on all ports, as well as SSH access to the leader from your location.
   - `KEYPAIR` is the name of the keypair that you will use to SSH into the lead node.

By default, one leader node (with a control daemon as well as a regular slurm daemon running on it) will be created,
and two computes nodes (with just the slurm daemon running on them) will be created.

### Use ###

SSH into the leader.
```

       __|  __|_  )
       _|  (     /   Amazon Linux AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-ami/2017.03-release-notes/
1 package(s) needed for security, out of 3 available
Run "sudo yum update" to apply all updates.
ec2-user@ip-172-31-42-161:~]$
```

Check to make sure that the container is running.
```
ec2-user@ip-172-31-42-161 ~]$ docker ps -a
CONTAINER ID        IMAGE                  COMMAND                  CREATED              STATUS              PORTS                                                                    NAMES
888c24706393        jamesmcclain/slurm:0   "/scripts/leader.s..."   About a minute ago   Up About a minute   0.0.0.0:6817-6818->6817-6818/tcp, 0.0.0.0:33009-33013->33009-33013/tcp   ip-172-31-42-161
ec2-user@ip-172-31-42-161:~]$
```

The docker container on each EC2 instance will have the same name (and internal hostname) as the instance.
Shell into the container and check the cluster status.
```
[ec2-user@ip-172-31-42-161 ~]$ docker exec -it $HOSTNAME bash
root@ip-172-31-42-161:/# sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
queue*       up   infinite      3   idle ip-172-31-37-12,ip-172-31-42-[161,225]
```

You should now be able to run jobs.
```
root@ip-172-31-42-161:/# srun -n 1 hostname
ip-172-31-37-12
root@ip-172-31-42-161:/# srun -n 2 hostname                                                                                                                                                                                                    
ip-172-31-42-161
ip-172-31-37-12
root@ip-172-31-42-161:/# srun -n 3 hostname                                                                                                                                                                                                    
ip-172-31-42-161
ip-172-31-37-12
ip-172-31-42-225
root@ip-172-31-42-161:/# cat <<EOF > /tmp/local_script.sh
> #!/bin/bash
> hostname
> EOF
root@ip-172-31-42-161:/# chmod u+x /tmp/local_script.sh
root@ip-172-31-42-161:/# salloc -n 3
salloc: Granted job allocation 33
root@ip-172-31-42-161:/# sbcast /tmp/local_script.sh /tmp/script.sh
root@ip-172-31-42-161:/# srun /tmp/script.sh
ip-172-31-42-161
ip-172-31-42-225
ip-172-31-37-12
root@ip-172-31-42-161:/# exit
exit
salloc: Relinquishing job allocation 33
root@ip-172-31-42-161:/#
```

### Stop ###

To stop the cluster, type `make stop-ec2`.

# OpenMPI and Coarray Fortran #

This image can be used to run OpenMPI and Coarray Fortran codes locally and on AWS.
Given an already-compiled MPI or [Coarray Fortran program](https://gcc.gnu.org/wiki/CoarrayExample) located at `/tmp/a.out` in the contianer,
the process looks something like this (after having shelled-in to the container on the lead node).
```
root@ip-172-31-22-7:/tmp# salloc -n 3
salloc: Granted job allocation 107
root@ip-172-31-22-7:/tmp# sbcast a.out hello
root@ip-172-31-22-7:/tmp# srun hello
Hello James from image 2
Enter your name: Hello James from image 1
Hello James from image 3
root@ip-172-31-22-7:/tmp# srun hello
Enter your name: Hello James from image 1
Hello James from image 2
Hello James from image 3
root@ip-172-31-22-7:/tmp# exit
salloc: Relinquishing job allocation 107
root@ip-172-31-22-7:/tmp#
```
Note that it is necessary to first broadcast the executable to all of the nodes because by default they do not have shared storage.
After that, it is possible to [run the MPI program using srun](https://slurm.schedmd.com/mpi_guide.html).

By way of compatibility, it is important to remember that the image contains shared runtime libraries for gfortran 6.3.x and OpenMPI 2.1.1.
It probably makes sense to try to link any executables [as statically as possible](https://stackoverflow.com/questions/4156055/gcc-static-linking-only-some-libraries) to avoid difficulties.
Unfortunately, it does not currently appear that executables can be fully static because certain OpenMPI libraries seem to require dynamic linking.


# License #

The contents of this repository are covered under the [MIT License](LICENSE.md).
The actual pieces of software (Slurm, MUNGE, &c) belong to their respective owners and covered by their respective licenses.
