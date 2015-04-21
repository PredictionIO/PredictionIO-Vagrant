#!/usr/bin/env bash

SETUP_DIR=$HOME/.pio
INSTALLED_FLAG=$SETUP_DIR/installed

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
  pio-start-all
  echo "--------------------------------------------------------------------------------"
  echo -e "\033[1;32mPredictionIO VM is up!\033[0m"
  echo "You could run 'pio status' inside VM ('vagrant ssh' to VM first) to confirm if PredictionIO is ready."
  echo -e "\033[1;33mIMPORTANT: You still have to start the eventserver manually (inside VM):\033[0m"
  echo -e "Run: '\033[1mpio eventserver --ip 0.0.0.0\033[0m'"
  echo "--------------------------------------------------------------------------------"
fi
