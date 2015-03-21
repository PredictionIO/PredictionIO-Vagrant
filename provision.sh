#!/usr/bin/env bash

SETUP_DIR=$HOME/.pio
INSTALLED_FLAG=$SETUP_DIR/installed

SPARK_VERSION=1.2.1
ELASTICSEARCH_VERSION=1.4.4
HBASE_VERSION=0.98.11
PIO_DIR=$HOME/PredictionIO

pio_dir=$PIO_DIR
vendors_dir=$pio_dir/vendors
spark_dir=$vendors_dir/spark-$SPARK_VERSION
elasticsearch_dir=$vendors_dir/elasticsearch-$ELASTICSEARCH_VERSION
hbase_dir=$vendors_dir/hbase-$HBASE_VERSION
zookeeper_dir=$vendors_dir/zookeeper

mkdir -p $SETUP_DIR

if [ ! -f $INSTALLED_FLAG ]; then

  echo "Installing PredictionIO..."
  bash -e -c "$(curl -s https://install.prediction.io/install.sh)" 0 -y
  if [ $? -ne 0 ]; then

    echo "ERROR: PredictionIO installation failed."
    echo "ERROR: Please try to destory and re-setup VM again by running (in the same current directory):"
    echo "ERROR: $ vagrant destroy"
    echo "ERROR: (enter y) followed by"
    echo "ERROR: $ vagrant up"
    echo "ERROR: If problem persists, please use this forum for support:"
    echo "ERROR: https://groups.google.com/forum/#!forum/predictionio-user"
    exit 1

  else

    echo "Finish PredictionIO installation."
    touch $INSTALLED_FLAG

  fi

else

  echo "PredictionIO already installed. Skip installation."
  echo "Starting ElasticSearch...."
  $elasticsearch_dir/bin/elasticsearch -d
  echo "Starting HBase..."
  $hbase_dir/bin/start-hbase.sh
  echo "Wait for 15 seconds for HBase to be ready..."
  sleep 15s
  echo "--------------------------------------------------------------------------------"
  echo -e "\033[1;32mPredictionIO VM is up!\033[0m"
  echo "You could run 'pio status' inside VM ('vagrant ssh' to VM first) to confirm if PredictionIO is ready."
  echo -e "\033[1;33mIMPORTANT: You still have to start the eventserver manually (inside VM):\033[0m"
  echo -e "Run: '\033[1mpio eventserver --ip 0.0.0.0\033[0m'"
  echo "--------------------------------------------------------------------------------"
fi
