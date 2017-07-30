LEADER_AMI ?= "ami-a4c7edb2"
LEADER_TYPE ?= "t2.micro"
FOLLOWER_AMI ?= "ami-a4c7edb2"
FOLLOWER_TYPE ?= "t2.micro"
REGION ?= us-east-1
NODES ?= 2

.PHONY: image start-leader-ec2 start-followers-ec2 start-ec2 stop-ec2


all: image

archives/munge-0.5.12.tar.xz:
	curl -L -C - -o $@ "https://github.com/dun/munge/releases/download/munge-0.5.12/munge-0.5.12.tar.xz"

archives/slurm-17-02-6-1.tar.gz:
	curl -L -C - -o $@ "https://github.com/SchedMD/slurm/archive/slurm-17-02-6-1.tar.gz"

archives/openmpi-2.1.1.tar.bz2:
	curl -L -C - -o $@ "https://www.open-mpi.org/software/ompi/v2.1/downloads/openmpi-2.1.1.tar.bz2"

image: archives/munge-0.5.12.tar.xz archives/slurm-17-02-6-1.tar.gz archives/openmpi-2.1.1.tar.bz2
	docker build \
           -t jamesmcclain/slurm:0 -f Dockerfile .

start-leader-ec2:
	sed -e "s/XXX/$(REGION)/" $(shell pwd)/scripts/bootstrap.sh.template > /tmp/leader-bootstrap.sh
	aws ec2 run-instances \
           --image-id $(LEADER_AMI) \
           --instance-type $(LEADER_TYPE) \
           --key-name $(KEYPAIR) \
           --security-groups $(SECURITY_GROUP) \
           --tag-specifications 'ResourceType=instance,Tags=[{Key=slurm,Value=leader}]' \
           --iam-instance-profile Name=$(INSTANCE_PROFILE) \
           --user-data file:///tmp/leader-bootstrap.sh \
           --count 1

start-followers-ec2:
	sed -e "s/XXX/$(REGION)/" $(shell pwd)/scripts/bootstrap.sh.template > /tmp/follower-bootstrap.sh
	aws ec2 run-instances \
           --image-id $(FOLLOWER_AMI) \
           --instance-type $(FOLLOWER_TYPE) \
           --key-name $(KEYPAIR) \
           --security-groups $(SECURITY_GROUP) \
           --tag-specifications 'ResourceType=instance,Tags=[{Key=slurm,Value=follower}]' \
           --iam-instance-profile Name=$(INSTANCE_PROFILE) \
           --user-data file:///tmp/follower-bootstrap.sh \
           --count $(NODES)

start-ec2: start-leader-ec2 start-followers-ec2

stop-ec2:
	./scripts/stop.sh
