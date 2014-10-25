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
SPARK_DIR=$VENDORS_DIR/spark-1.1.0
ELASTIC_DIR=$VENDORS_DIR/elasticsearch-1.3.2
HBASE_DIR=$VENDORS_DIR/hbase-0.98.6
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

	sudo apt-get install python-software-properties -y
	sudo add-apt-repository ppa:ondrej/php5 -y
	sudo apt-get update

	sudo apt-get install php5 php5-curl -y

	# Java
	apt-get install openjdk-7-jre -y

	touch $SETUP_DIR/install
fi

if [ ! -f $SETUP_DIR/download ]; then

	# PredictionIO
	cd $TEMP_DIR
	if [ ! -f PredictionIO-0.8.0.tar.gz ]; then
		wget http://download.prediction.io/PredictionIO-0.8.0.tar.gz
	fi
	tar zxvf PredictionIO-0.8.0.tar.gz
	rm -rf $PIO_DIR
	mv PredictionIO-0.8.0 $PIO_DIR
	mkdir $VENDORS_DIR
	chown -R $USER:$USER $PIO_DIR

	# Spark
	if [ ! -f spark-1.1.0-bin-hadoop2.4.tgz ]; then
                wget http://d3kbcqa49mib13.cloudfront.net/spark-1.1.0-bin-hadoop2.4.tgz
        fi
        tar xvf spark-1.1.0-bin-hadoop2.4.tgz
        rm -rf $SPARK_DIR
        mv spark-1.1.0-bin-hadoop2.4 $SPARK_DIR
	sed -i 's/SPARK_HOME=\/path_to_apache_spark/SPARK_HOME=\/opt\/PredictionIO\/vendors\/spark-1.1.0/g' $PIO_DIR/conf/pio-env.sh

	# Elasticsearch
	if [ ! -f elasticsearch-1.3.2.tar.gz ]; then
		wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.3.2.tar.gz
	fi
	tar zxvf elasticsearch-1.3.2.tar.gz
	rm -rf $ELASTIC_DIR
	mv elasticsearch-1.3.2 $ELASTIC_DIR
	echo 'network.host: 127.0.0.1' >> $ELASTIC_DIR/config/elasticsearch.yml

	if [ ! -f hbase-0.98.6-hadoop2-bin.tar.gz ]; then
		wget http://archive.apache.org/dist/hbase/hbase-0.98.6/hbase-0.98.6-hadoop2-bin.tar.gz	
	fi
	tar zxvf hbase-0.98.6-hadoop2-bin.tar.gz
	rm -rf $HBASE_DIR
	mv hbase-0.98.6-hadoop2 $HBASE_DIR

	cat <<EOT > $HBASE_DIR/conf/hbase-site.xml
<configuration>
  <property>
    <name>hbase.rootdir</name>
    <value>file:///home/vagrant/hbase</value>
  </property>
  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>/home/vagrant/zookeeper</value>
  </property>
</configuration>
EOT
	echo 'export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-amd64' >> $HBASE_DIR/conf/hbase-env.sh

	chown -R $USER:$USER $VENDORS_DIR

	touch $SETUP_DIR/download

fi

sudo $ELASTIC_DIR/bin/elasticsearch &
sudo $HBASE_DIR/bin/start-hbase.sh

echo "IMPORTANT: You'll have to start the eventserver manually:"
echo "1. Run './pio eventserver --ip 0.0.0.0'"
echo "2. Check the eventserver status with 'curl -i -X GET http://localhost:7070'"
echo "3. Use ./pio {train/deploy/...} commands"
echo "4. Profit!"
