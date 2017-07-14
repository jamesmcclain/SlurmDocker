FROM ubuntu:17.04
MAINTAINER James McClain <james.mcclain@gmail.com>

RUN apt-get update && apt-get install -y gcc libgcrypt20-dev make python
