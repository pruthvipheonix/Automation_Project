#!/bin/bash

s3bucketname=upgrad-pruthvi
myname=pruthvi
service=apache2
bucketName=$s3bucketname

update_package(){
        echo "update_package:START"
        sudo apt update -y
        echo "Updating ubuntu linux packages finished"
}

## Installation of Apache2

apache_installation(){
        service=$1
        if systemctl --all --type service | grep -q "$serviceName"
        then
                echo "'$service'  : is installed!"
        else
                echo "'$service'  : is not installed"
                echo "Installing  : '$service'"
                sudo apt install "$service" -y
                echo "Installed   : '$service'"
        fi
}


## Installing and starting the service
apache_start(){
        service=$1
        STATUS="$(systemctl is-active $service)"
        if [ "${STATUS}" = "active" ]
        then
                echo "'$service': IS RUNNING"
        else
                echo "'$service': STARTING"
                sudo apt install "$service" -y
                sudo systemctl start "$service"
                echo "'$service': STARTED"
        fi
}

## Enabling the Service
apache_enable(){
        service=$1
        STATUS="$(systemctl is-enabled $service)"
        if [ "${STATUS}" = "enabled" ]
        then
                echo "$service: Enabled Already"
        else
                echo "$service: Enabling NOW"
                sudo systemctl enable "$service"
        fi

}

## Arciveing the logs
archive_logs(){
        echo "Logs : Started_Archive "
        timestamp=$(date '+%d%m%Y-%H%M%S')
        filename="$myname-httpd-logs-$timestamp.tar"
        tar -cvf $filename /var/log/apache2/*.log
        mv $filename /tmp/
        echo "Logs : Completed_Archive"
}


## Copying the Archive logs to S3 Bucket using Amazon CLI
## Install AWS CLI before copying to s3 bucket
 
#sudo apt update
#sudo apt install awscli

copy_archive_logs(){
        echo "Copying to S3 Bucket started";
        bucketName=$1
        aws s3 cp /tmp/$filename s3://$bucketName/$filename;
}


## Main Program
my_program(){
        echo "Starting Atomation Script";
        update_package;



        apache_installation "$service"
        apache_start "$service"
        apache_enable "$service"
        archive_logs



        copy_archive_logs "$bucketName"

        echo "Automation script finished";
}

my_program;
