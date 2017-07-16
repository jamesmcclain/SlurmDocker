LEADER_AMI ?= "ami-a4c7edb2"
LEADER_TYPE ?= "t2.micro"

.PHONY: image ec2-start ec2-stop


all: image

archives/munge-0.5.12.tar.xz:
	curl -L -C - -o $@ "https://github.com/dun/munge/releases/download/munge-0.5.12/munge-0.5.12.tar.xz"

archives/slurm-17-02-6-1.tar.gz:
	curl -L -C - -o $@ "https://github.com/SchedMD/slurm/archive/slurm-17-02-6-1.tar.gz"

image: archives/munge-0.5.12.tar.xz archives/slurm-17-02-6-1.tar.gz
	docker build \
           -t jamesmcclain/slurm:0 -f Dockerfile .

ec2-leader:
	aws ec2 run-instances \
           --image-id $(LEADER_AMI) \
           --instance-type $(LEADER_TYPE) \
           --key-name $(KEYPAIR) \
           --security-groups $(GROUP_NAME) \
           --tag-specifications 'ResourceType=instance,Tags=[{Key=slurm,Value=leader}]' \
           --iam-instance-profile Name=$(INSTANCE_PROFILE) \
           --count 1
	# aws ec2 describe-instances --filters "Name=tag:Purpose,Values=test"

ec2-stop:
	# aws ec2 describe-instances | jq '.Reservations[].Instances[].InstanceId'
	# aws ec2 terminate-instances --instance-ids ...
