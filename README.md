Bring Up PredictionIO VM with Vagrant
======================================

Install Vagrant
-----------------

Follow instructions in http://docs.vagrantup.com/v2/installation/index.html. Download and install Vagrant.

Install Virtual Box
--------------------

Follow instructions in https://www.virtualbox.org/wiki/Downloads. Download and install Virtual Box.

Add Precise64 Box
------------------

	$ vagrant box add precise64 http://files.vagrantup.com/precise64.box

Start Vagrant
----------------

	$ vagrant up

Vagrant will bring up the VM and setup the PredictionIO.

Now you have a VM with PredictionIO running!

Accessing PredictionIO VM from the Host Machine
------------------------------------------------

In the default Vagrantfile setup, the ports 8000, 9000, 50030 and 50070 are forwarded from VM to the host machine:

* Port 8000 - PredictionIO API server
* Port 9000 - PredictionIO web admin server
* Port 50030 - Hadoop Job tracker
* Port 50070 - Hadoop Namenode

You can access the PredictionIO admin panel with the host machine browser http://localhost:9000.

You can import data to the PredictionIO from your host machine through the API server http://localhost:8000 using PredictionIO SDK.

You can browse the HDFS filesystem at http://localhost:50070 with the host machine browser.

You can also ssh to the VM by running

	$ vagrant ssh

Shutdown PredictionIO VM
---------------------------

To shutdown the VM without deleting any PredictionIO data, execute 

	$ vagrant halt

Later you can execute

	$ vagrant up 

again to bring up the PredictionIO VM.

You can completely remove the VM and delete all data with

	$ vagrant destroy

See http://docs.vagrantup.com/v2/getting-started/teardown.html for more details.


SUPPORT
===========

Forum
-----

https://groups.google.com/group/predictionio-user

