#! /bin/bash

TCP_PORTS=("7777" "7778" "27015" "32330")
UDP_PORTS=("7777" "7778" "27015")

## Update and install dependancies
apt update
apt upgrade -y

add-apt-repository multiverse
apt install software-properties-common
dpkg --add-architecture i386
apt update

apt install vim curl wget steamcmd perl-modules lsof libc6-i386 lib32gcc-s1 bzip2 -y

## Create Steam User
useradd -m -s /bin/bash steam

#### Arkmanager ####

## Install Ark
echo 'fs.file-max=100000' >> /etc/sysctl.conf
echo '*               soft    nofile          1000000' >> /etc/security/limits.conf
echo '*               hard    nofile          1000000' >> /etc/security/limits.conf
echo 'session required pam_limits.so' >> /etc/pam.d/common-session
sudo -u steam /usr/games/steamcmd +force_install_dir /home/steam +login anonymous +app_update 376030 +quit

## Open ports in iptables for arkmanager
if [[ $EUID -ne 0 ]]; then
    echo "This must be run as root"
    exit 1
fi
for port in ${UDP_PORTS[@]}; do
  iptables -t filter -I INPUT -p udp --dport $port -j ACCEPT
done
for port in ${TCP_PORTS[@]}; do
  iptables -t filter -I INPUT -p tcp --dport $port -j ACCEPT
done

## Install arkmanager
curl -sL https://git.io/arkmanager | bash -s steam

## Configure ark
curl -o /etc/arkmanager/arkmanager.cfg https://raw.githubusercontent.com/pwolthausen/gameServer/main/arkmanager.cfg
for server in lost genesis fjordur; do
  curl -o /etc/arkmanager/instances/$server.cfg https://raw.githubusercontent.com/pwolthausen/gameServer/main/$server.cfg
done
sudo -u steam curl -o /home/steam/ShooterGame/Config/DefaultGame.ini https://raw.githubusercontent.com/pwolthausen/gameServer/main/DefaultGame.ini

sudo -u steam arkmanager install @lost
sudo -u steam arkmanager install @genesis
sudo -u steam arkmanager install @fjordur
sudo -u steam arkmanager installmods @all
sudo -u steam arkmanager update @all
