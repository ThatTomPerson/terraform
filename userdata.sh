#!/bin/bash -xve
# install awscli
yum -y update
yum -y install awscli

# start attaching the ebs volume
INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
AWS_DEFAULT_REGION=ap-southeast-2 aws ec2 attach-volume --device /dev/xvdf --instance-id $INSTANCE_ID --volume-id ${ebs_volume}

# download and install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# mount factorio ebs volume
mkdir /mnt/factorio
mount /dev/xvdf /mnt/factorio

# start factorio
cd /mnt/factorio/compose && docker-compose up -d