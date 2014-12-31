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
PIO_VERSION=0.8.4
VENDORS_DIR=$PIO_DIR/vendors
SPARK_DIR=$VENDORS_DIR/spark-1.2.0
ELASTIC_DIR=$VENDORS_DIR/elasticsearch-1.4.0
HBASE_DIR=$VENDORS_DIR/hbase-0.98.6
SETUP_DIR=/home/$USER/.pio

mkdir -p $SETUP_DIR
chown -R $USER:$USER $SETUP_DIR

if [ ! -f $SETUP_DIR/install ]; then

	echo "Installing required components ..."

	sudo apt-get update

	# Java
	sudo apt-get install openjdk-7-jdk -y

	# Misc. Tools
	sudo apt-get install unzip -y
	sudo apt-get install curl -y
	sudo apt-get install libgfortran3 -y

	touch $SETUP_DIR/install
fi

if [ ! -f $SETUP_DIR/download ]; then

	# PredictionIO
	cd $TEMP_DIR
	if [ ! -f PredictionIO-$PIO_VERSION.tar.gz ]; then
		wget http://download.prediction.io/PredictionIO-$PIO_VERSION.tar.gz
	fi
	tar zxvf PredictionIO-$PIO_VERSION.tar.gz
	rm -rf $PIO_DIR
	mv PredictionIO-$PIO_VERSION $PIO_DIR
	mkdir $VENDORS_DIR
	chown -R $USER:$USER $PIO_DIR

	# Spark
	if [ ! -f spark-1.2.0-bin-hadoop2.4.tgz ]; then
                wget http://d3kbcqa49mib13.cloudfront.net/spark-1.2.0-bin-hadoop2.4.tgz
        fi
        tar xvf spark-1.2.0-bin-hadoop2.4.tgz
        rm -rf $SPARK_DIR
        mv spark-1.2.0-bin-hadoop2.4 $SPARK_DIR
	sed -i 's/SPARK_HOME=\/path_to_apache_spark/SPARK_HOME=\/opt\/PredictionIO\/vendors\/spark-1.2.0/g' $PIO_DIR/conf/pio-env.sh

	# Elasticsearch
	if [ ! -f elasticsearch-1.4.0.tar.gz ]; then
		wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.0.tar.gz
	fi
	tar zxvf elasticsearch-1.4.0.tar.gz
	rm -rf $ELASTIC_DIR
	mv elasticsearch-1.4.0 $ELASTIC_DIR
	echo 'network.host: 127.0.0.1' >> $ELASTIC_DIR/config/elasticsearch.yml

	# HBase
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

sudo $ELASTIC_DIR/bin/elasticsearch -d
sudo $HBASE_DIR/bin/start-hbase.sh

echo "IMPORTANT: You'll have to start the eventserver manually:"
echo "1. Run './pio eventserver --ip 0.0.0.0'"
echo "2. Check the eventserver status with 'curl -i -X GET http://localhost:7070'"
echo "3. Use ./pio {train/deploy/...} commands"
echo "4. Profit!"
