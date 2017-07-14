#!/bin/bash

if [ ! -f /tmp/munge.key ]; then ls -lh / > /tmp/munge.key; fi
chown munge:munge /tmp/munge.key
chmod go-rwx /tmp/munge.key
su munge -c "LD_LIBRARY_PATH=/usr/local/lib /usr/local/sbin/munged -f --syslog --key-file=/tmp/munge.key --pid-file=/tmp/munged.pid --socket=/tmp/munge.socket.2"
