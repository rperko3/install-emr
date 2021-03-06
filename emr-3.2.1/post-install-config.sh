#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
	USER_COUNT=1
else
	USER_COUNT=$1
fi

echo "USER_COUNT=$USER_COUNT"
# give hadoop a password
# echo "hadoop:hadoop" | sudo chpasswd

hadoop fs -mkdir /tmp

#download data & scripts
# wget --no-check-certificate https://s3-us-west-2.amazonaws.com/velocity1/vast-data/Activity_1.2.R
#wget --no-check-certificate https://s3-us-west-2.amazonaws.com/velocity1/vast-data/Activity_1.2_solutions.R
# wget --no-check-certificate https://s3-us-west-2.amazonaws.com/velocity1/vast-data/Activity_1.3.R
# wget --no-check-certificate https://s3-us-west-2.amazonaws.com/velocity1/vast-data/Activity_1.3_solutions.R
# wget --no-check-certificate https://s3-us-west-2.amazonaws.com/velocity1/vast-data/Activity_1.4.R
# wget --no-check-certificate https://s3-us-west-2.amazonaws.com/velocity1/vast-data/Activity_1.4_solutions.R
# wget --no-check-certificate https://s3-us-west-2.amazonaws.com/velocity1/vast-data/Activity_1.5.R
# wget --no-check-certificate https://s3-us-west-2.amazonaws.com/velocity1/vast-data/Activity_1.5_solutions.R
# wget --no-check-certificate https://s3-us-west-2.amazonaws.com/velocity1/vast-data/Activity_2.1.R
# wget --no-check-certificate https://s3-us-west-2.amazonaws.com/velocity1/vast-data/Activity_2.2.R
# wget --no-check-certificate https://s3-us-west-2.amazonaws.com/velocity1/vast-data/Activity_2.3.R
# wget --no-check-certificate https://s3-us-west-2.amazonaws.com/velocity1/vast-data/dailycount.Rdata
# wget --no-check-certificate https://s3-us-west-2.amazonaws.com/velocity1/vast-data/nf-week2-sample.csv
wget --no-check-certificate https://s3-us-west-2.amazonaws.com/velocity1/vast-data/nf-week2.csv
# wget --no-check-certificate https://s3-us-west-2.amazonaws.com/velocity1/vast-data/some_fake_data.csv


#create users
USER_COUNT=$1
PORT=52901
for i in $(eval echo "{1..$USER_COUNT}")
  do
	  # create user
	  sudo useradd -m bootcamp-user-$i
	  # give them a password
	  echo "bootcamp-user-$i:bootcamp" | sudo chpasswd
	  # create data dir in hadoop
  	  hadoop fs -mkdir -p /user/bootcamp-user-$i/vast/raw/nf
	  # put the data in hdfs
	  hadoop fs -put nf-week2.csv /user/bootcamp-user-$i/vast/raw/nf/nf-week2.csv
	    
      # change perms
	  hadoop fs -chown -R bootcamp-user-$i /user/bootcamp-user-$i
	  # copy scripts and sample data to user home dir
	  sudo cp nf-week2-sample.csv Activity* some_* /home/bootcamp-user-$i
	  # create R lib directory
	  sudo mkdir -p /home/bootcamp-user-$i/R/lib
      # create tmp
      sudo mkdir /home/bootcamp-user-$i/tmp
	  # give everyone persmissions
	  sudo chown -R bootcamp-user-$i /home/bootcamp-user-$i
	  # set some R environment variables
	  echo "TR_PORT=$PORT" | sudo tee -a /home/bootcamp-user-$i/.Renviron
	  echo "HDFS_USER_VAST=/user/bootcamp-user-$i/vast" | sudo tee -a /home/bootcamp-user-$i/.Renviron
	  # increment the trelliscope port
	  PORT=$[PORT + 1]
 done

# rwx to the entire world
# hadoop fs -chmod -R 777 /

echo "#!/usr/bin/env bash" >/tmp/fireup.sh
echo "	if [ \"/home/hadoop/bin/hadoop fs -test -d /mnt\" ]; then" >>/tmp/fireup.sh
echo "		/home/hadoop/bin/hadoop fs -mkdir /user/user3" >>/tmp/fireup.sh
echo "		/home/hadoop/bin/hadoop fs -mkdir /tmp" >>/tmp/fireup.sh
echo "		/home/hadoop/bin/hadoop fs -chmod -R 777 /" >>/tmp/fireup.sh
echo "		sudo -u shiny nohup shiny-server &" >>/tmp/fireup.sh
# Anything you would like to add (configurations or installations) that require Hadoop, HDFS to be running
# use a shell script format and enter after this comment, preferably before the empty crontab entry.
# PLEASE TAKE CARE OF BASHISMS, AMAZON AMI BASH IS NOT STANDARD BASH

echo "		echo \"\" >/tmp/crontab.txt">>/tmp/fireup.sh
echo "		crontab /tmp/crontab.txt" >>/tmp/fireup.sh
echo "	fi" >>/tmp/fireup.sh
chmod +x /tmp/fireup.sh


echo "*/1 * * * * export JAVA_HOME=/usr/lib/jvm/java-7-oracle; /tmp/fireup.sh" >/tmp/crontab.txt
crontab /tmp/crontab.txt
hadoop fs -chmod -R 777 /

