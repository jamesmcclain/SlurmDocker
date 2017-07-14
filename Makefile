.PHONY: image


all: image

archives/munge-0.5.12.tar.xz:
	curl -L -C - -o $@ "https://github.com/dun/munge/releases/download/munge-0.5.12/munge-0.5.12.tar.xz"

archives/slurm-17-02-6-1.tar.gz:
	curl -L -C - -o $@ "https://github.com/SchedMD/slurm/archive/slurm-17-02-6-1.tar.gz"

image: archives/munge-0.5.12.tar.xz archives/slurm-17-02-6-1.tar.gz
	docker build \
           -t jamesmcclain/slurm:0 -f Dockerfile .
