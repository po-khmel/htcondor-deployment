#!/bin/bash

sudo mkdir -p /data/share
sudo chown rocky:rocky -R /data/share

mkfs -t xfs /dev/vdb
echo "/dev/vdb  /data/share xfs defaults,nofail 0 2" >> /etc/fstab
mount /data/share

