#!/usr/bin/env bash

set -e

if [ "$#" -ne 1 ]; then
	echo "Error: please specify username as argument to the PredictionIO provision script"
	exit 1
fi

USER=$1
INSTALL_DIR=/opt
TEMP_DIR=/tmp
PIO_DIR=$INSTALL_DIR/PredictionIO
VENDORS_DIR=$PIO_DIR/vendors
HADOOP_DIR=$VENDORS_DIR/hadoop-1.2.1
MAHOUT_DIR=$VENDORS_DIR/mahout-0.8-snapshot
SETUP_DIR=/home/$USER/.pio

mkdir -p $SETUP_DIR
chown -R $USER:$USER $SETUP_DIR

if [ ! -f $SETUP_DIR/install ]; then

	echo "Installing required components ..."

	# MongoDB
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
	echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/10gen.list

	apt-get update
	apt-get install mongodb-10gen -y

	# Misc. Tools
	apt-get install unzip -y
	apt-get install curl -y

	# Java
	apt-get install openjdk-7-jre -y

	touch $SETUP_DIR/install
fi

if [ ! -f $SETUP_DIR/download ]; then

	# PredictionIO
	cd $TEMP_DIR
	wget http://download.prediction.io/PredictionIO-0.6.7.zip
	unzip PredictionIO-0.6.7.zip
	rm PredictionIO-0.6.7.zip
	mv PredictionIO-0.6.7 $PIO_DIR
	chown -R $USER:$USER $PIO_DIR

	# Hadoop
	mkdir -p $VENDORS_DIR
	cd $VENDORS_DIR

	wget http://archive.apache.org/dist/hadoop/core/hadoop-1.2.1/hadoop-1.2.1.tar.gz
	tar zxvf hadoop-1.2.1.tar.gz
	rm $VENDORS_DIR/hadoop-1.2.1.tar.gz
	cp $PIO_DIR/conf/hadoop/* $HADOOP_DIR/conf
	cp /vagrant/hdfs-site.xml $HADOOP_DIR/conf
	echo 'export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre' >> $HADOOP_DIR/conf/hadoop-env.sh
	echo 'io.prediction.commons.settings.hadoop.home=/opt/PredictionIO/vendors/hadoop-1.2.1' >> $PIO_DIR/conf/predictionio.conf
	mkdir -p $VENDORS_DIR/hadoop/nn
	mkdir -p $VENDORS_DIR/hadoop/dn

	chown -R $USER:$USER $VENDORS_DIR

	# mahout
	mkdir $MAHOUT_DIR
	cd $MAHOUT_DIR
	wget http://download.prediction.io/mahout-snapshots/1993/mahout-core-0.8-SNAPSHOT-job.jar
	chown -R $USER:$USER $MAHOUT_DIR

	touch $SETUP_DIR/download

fi

if [ ! -f $SETUP_DIR/keygen ]; then

	# Setup passwordless SSH access for Hadoop on first boot
	sudo -u $USER mkdir -p /home/$USER/.ssh
	sudo -u $USER echo "Host localhost" > /home/$USER/.ssh/config
	sudo -u $USER echo "    StrictHostKeyChecking no" >> /home/$USER/.ssh/config
	sudo -u $USER ssh-keygen -t dsa -P '' -f /home/$USER/.ssh/id_dsa
	sudo -u $USER cat /home/$USER/.ssh/id_dsa.pub >> /home/$USER/.ssh/authorized_keys
	sudo -u $USER $HADOOP_DIR/bin/hadoop namenode -format -force

	touch $SETUP_DIR/keygen

fi

if [ ! -f $SETUP_DIR/setup ]; then

	# Wait for MongoDB ready
	MONGO_WAIT=10
	MONGO_RETRY=20
	MONGO_TRY=1
	echo -e "Waiting for MongoDB... \c"
	while [ $MONGO_TRY -le $MONGO_RETRY ] ; do
		$PIO_DIR/bin/conncheck > /dev/null 2>&1
		if [ $? -eq 0 ] ; then
			echo "ready"
			MONGO_TRY=$MONGO_RETRY
		elif [ $MONGO_TRY -eq $MONGO_RETRY ] ; then
			echo "failed (Cannot connect to MongoDB)"
		exit 1
		fi
		sleep $MONGO_WAIT
		MONGO_TRY=$((MONGO_TRY+1))
	done

	# setup PIO
	sudo -u $USER $PIO_DIR/bin/setup.sh

	touch $SETUP_DIR/setup

fi

if [ -f $PIO_DIR/admin.pid ]; then
	echo "Found previous admin PID (probably due to unclean shutdown). Removing it ..."
	rm $PIO_DIR/admin.pid
fi

if [ -f $PIO_DIR/api.pid ]; then
	echo "Found previous api PID (probably due to unclean shutdown). Removing it ..."
	rm $PIO_DIR/api.pid
fi

if [ -f $PIO_DIR/scheduler.pid ]; then
	echo "Found previous scheduler PID (probably due to unclean shutdown). Removing it ..."
	rm $PIO_DIR/scheduler.pid
fi

echo "Start PredictionIO ..."
su -c "yes | $PIO_DIR/bin/start-all.sh" $USER
echo "Done."
