#!/bin/bash

#Script by PrivateHeberg (Théo Lgt) - Feb 2018

#Colors
RED='\033[0;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
RESET='\033[0m'

#Check if user has root access
if [ $(id -u) != 0 ]; then
    echo "${RED}Merci de lancer le script avec les droits d'administrateur (root)${RESET}"
    exit
fi

echo "-----------------------------------------------"
echo "Installation automatique de MineOS sous Debian"
echo "Par PrivateHeberg (privateheberg.com)"
echo "${GREEN}Lancement dans 5 secondes${RESET}"
echo "-----------------------------------------------"

sleep 5

echo "Mise à jour des packets"
apt update

echo "${BLUE}Installation des dépendances (1/2)...${RESET}"
apt -y install curl ca-certificates

echo "${BLUE}Installation de NodeJs...${RESET}"
curl -sL https://deb.nodesource.com/setup_4.x | bash -
apt-get -y install nodejs

echo "${BLUE}Installation des dépendances (2/2)...${RESET}"
apt-get update
apt-get install -y git supervisor rdiff-backup screen build-essential

echo "${BLUE}Installation de OpenJDK 8${RESET}"
echo "deb http://http.debian.net/debian jessie-backports main" >> /etc/apt/sources.list
apt-get update
apt-get install -y -t jessie-backports openjdk-8-jre-headless ca-certificates-java

echo "${BLUE}Installation des scripts MineOS${RESET}"
mkdir -p /usr/games
cd /usr/games
git clone https://github.com/hexparrot/mineos-node.git minecraft
cd minecraft
git config core.filemode false
chmod +x service.js mineos_console.js generate-sslcert.sh webui.js
npm install
ln -s /usr/games/minecraft/mineos_console.js /usr/local/bin/mineos
cp mineos.conf /etc/mineos.conf

echo "${BLUE}Génération des certificats SSL${RESET}"
cd /usr/games/minecraft 
./generate-sslcert.sh

echo "${BLUE}Voulez-vous que l'interface WEB démarre au lancement du VPS ? (o/n)${RESET}"
read responseSB

if [ $responseSB = "o" ]; then
    cp init/supervisor_conf /etc/supervisor/conf.d/mineos.conf
    supervisorctl reload
    echo "${GREEN}L'interface se lancera avec le VPS${RESET}"
else
    echo "${RED}L'interface ne se lancera pas avec le VPS${RESET}"
fi

echo "${BLUE}Pour lancer l'interface WEB, utilisez: \"supervisorctl start mineos\"${RESET}"
echo "${BLUE}Pour stopper l'interface WEB, utilisez: \"supervisorctl stop mineos\"${RESET}"

echo "${RED}Il est nécessaire de créer un nouvel utilisateur pour utiliser MineOS, vous pouvez en créer un avec la commande \"useradd <nom>\"${RESET}"

echo "Voulez-vous en créer un? (o/n)"
read responseUser

if [ $responseUser = "o" ]; then
    echo "Quel est le nom de l'utilisateur?"
    read username
    adduser $username
fi

#Get ip of server of eth0
ip=$(LANG=c ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}' | tee /dev/tty)

#If eth0 doesn't exist, try to get ip of venet0:0
if [ -z $ip ]; then
    ip=$(LANG=c ifconfig venet0:0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}' | tee /dev/tty)
fi

#Display url of web panel
echo "${GREEN}MineOS est maintenant installé, il est accessible depuis https://$ip:8443${RESET}"
