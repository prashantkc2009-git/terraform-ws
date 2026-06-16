#!/bin/bash
yum update -y
yum install -y httpd
systemctl enable httpd
systemctl start httpd
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
echo "<h1>App1 - Instance: $INSTANCE_ID (AZ: $AZ)</h1>" > /var/www/html/index.html
