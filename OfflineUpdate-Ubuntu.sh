#!/usr/bin/env bash
# Check if running as super user
if [ $(id -u) != 0 ]
then
	echo '[!] Please run this script as super user'
	exit
fi

# Make sure apt-offline is installed
apt search apt-offline | grep installed 2>&1 /dev/null
if [[ $? == 1 ]]
then
	echo '[!] Missing package: apt-offline cannot continue'
	exit
fi

__date=$(date +%F)
sig_file=$(hostname)-${__date}.sig
download_dir=$(hostname)-${__date}-update
sudo apt-offline set ~/${sig_file}

# Make sure we have a directory to track updates via file creation
if ! [[ -d /var/log/apt/offline-update ]] 
then 
	mkdir /var/log/apt/offline-update
fi

echo -e "Sig file: ${sig_file}\n\nSteps:\n1. Copy the sig file to an online machine\n2. Run the following commands:\nmkdir ${download_dir} && apt-offline get -d ${download_dir} ${sig_file} && tar czf ${download_dir}.tar.gz ${download_dir}\n\n3. Transfer the tarball to the offline machine and run the following commands:\ntar xf ${download_dir}.tar.gz && sudo apt-offline install ./${download_dir} && sudo touch /var/log/apt/offline-update/$(date +%F)"

# Make sure to keep the file permissions in order
chown -R root:adm /var/log/apt/offline-update
