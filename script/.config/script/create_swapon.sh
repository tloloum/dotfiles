#!/bin/bash 

sudo mkdir -p /var/cache/swap/\n 1075 
sudo dd if=/dev/zero of=/var/cache/swap/swap0 bs=64M count=64\n 1076 
sudo chmod 0600 /var/cache/swap/swap0\n 1077  
sudo mkswap /var/cache/swap/swap0\n 1078  
sudo swapon /var/cache/swap/swap0\n 1079  sudo swapon -s
