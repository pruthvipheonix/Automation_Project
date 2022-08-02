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
copy_archive_logs(){
        echo "Copying to S3 Bucket started";
        bucketName=$1
        aws s3 cp /tmp/$filename s3://$bucketName/$filename;
}



## Bookkeeping

inventory_update(){
                inventory_file=/var/www/html/inventory.html
                log_type="httpd-logs"
                timestamp=$(stat --printf=%y /tmp/$filename | cut -d.  -f1)
                file_type=${filename##*.}
                size=$(ls -lh /tmp/${filename} | cut -d " " -f5)


                echo "File_Name : $filename"
                echo "Log_Type : $log_type"
                echo "Time_Of_Creation : $timestamp"
                echo "Type_Of_File : $file_type"
                echo "File_Size : $size"

                if  test -f "$inventory_file"
                then
                        echo "<br>${log_type}&nbsp;&nbsp;&nbsp;&nbsp;${timestamp}&nbsp;&nbsp;&nbsp;&nbsp;${file_type}&nbsp;&nbsp;&nbsp;&nbsp;${size}">>"${inventory_file}"
                        echo "Inventory file has been updated"
                else
                        echo "Creating '$inventory_file'"
                       `touch ${inventory_file}`
                        echo "<b>Log Type&nbsp;&nbsp;&nbsp;&nbsp;Date Created&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Type&nbsp;&nbsp;&nbsp;Size</b>">>"${inventory_file}"
                        echo "<br>${log_type}&nbsp;&nbsp;&nbsp;&nbsp;${timestamp}&nbsp;&nbsp;&nbsp;&nbsp;${file_type}&nbsp;&nbsp;&nbsp;&nbsp;${size}">>"${inventory_file}"
                        echo "UPDATED '$inventory_file' HEADER and Data"
                fi

}



#Creating Cron Job to execute automation.sh every day
cron_file_check(){
                cron_file=/etc/cron.d/automation
                if test -f "$cron_file"
                then
                        echo "Cron Exists"
                else
                        echo "Creating Cron File $cron_file"
                        touch $cron_file
                        echo "SHELL=/bin/bash" > $cron_file
                        echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin" >> $cron_file
                        echo "0 0 * * * root /root/Automation_Project/automation.sh" >> $cron_file
                        echo "Cron file created"
                fi

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
        inventory_update
        cron_file_check

        echo "Automation script finished";
}

my_program;

