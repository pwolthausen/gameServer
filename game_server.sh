#! /bin/bash

TCP_PORTS=("7777" "7778" "27015" "32330")
UDP_PORTS=("7777" "7778" "27015")
SERVERS=("main" "lost" "genesis" "fjordur")

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
# Configure file limit
if ( grep -Fq file-max /etc/sysctl.conf );
then
  echo "Already configured";
else
  echo "fs.file-max=100000" >> /etc/sysctl.conf; 
fi

if ( grep -Fq "soft    nofile" /etc/security/limits.conf );
then
  echo "Already configured";
else
  echo '*               soft    nofile          1000000' >> /etc/security/limits.conf
  echo '*               hard    nofile          1000000' >> /etc/security/limits.conf;
fi

if ( grep -Fq "pam_limits.so" /etc/pam.d/common-session );
then
  echo "Already configured";
else
  echo 'session required pam_limits.so' >> /etc/pam.d/common-session; 
fi

# Install ShooterGame, if not already present
if test -f /home/steam/ARK/ShooterGame/Binaries/Linux/ShooterGameServer;
then 
  echo "Ark already installed";
else
  sudo -u steam /usr/games/steamcmd +force_install_dir /home/steam/ARK +login anonymous +app_update 376030 +quit;
fi

## Open ports in iptables for arkmanager
if [[ $EUID -ne 0 ]]; then
    echo "This must be run as root"
    exit 1
fi
for port in {7777..7785}; do
  iptables -t filter -I INPUT -p udp --dport $port -j ACCEPT
done
for port in {7777..7785}; do
  iptables -t filter -I INPUT -p tcp --dport $port -j ACCEPT
done
for port in {27015..27019}; do
  iptables -t filter -I INPUT -p udp --dport $port -j ACCEPT
done
for port in {27015..27025}; do
  iptables -t filter -I INPUT -p tcp --dport $port -j ACCEPT
done
# for port in ${UDP_PORTS[@]}; do
#   iptables -t filter -I INPUT -p udp --dport $port -j ACCEPT
# done
# for port in ${TCP_PORTS[@]}; do
#   iptables -t filter -I INPUT -p tcp --dport $port -j ACCEPT
# done

## Install arkmanager
if test -f /usr/local/bin/arkmanager;
then
  echo "Arkmanager already installed";
else
  curl -sL https://git.io/arkmanager | bash -s steam
fi

## Configure ark
curl -o /etc/arkmanager/arkmanager.cfg https://raw.githubusercontent.com/pwolthausen/gameServer/main/arkmanager.cfg
for server in ${SERVERS[@]}; do
  curl -o /etc/arkmanager/instances/$server.cfg https://raw.githubusercontent.com/pwolthausen/gameServer/main/$server.cfg
done
sudo -u steam curl -o /home/steam/ARK/ShooterGame/Config/DefaultGame.ini https://raw.githubusercontent.com/pwolthausen/gameServer/main/DefaultGame.ini

rm -f /etc/arkmanager/instances/main.cfg
rm -f /etc/arkmanager/instances/instance.cfg.example
sudo -u steam arkmanager install @all
sudo -u steam arkmanager installmods @all
sudo -u steam arkmanager update @all

#### Valheim ####
# https://linuxgsm.com/servers/vhserver/
useradd -m -s /bin/bash vhserver

sudo -u vhserver wget -O /home/vhserver/linuxgsm.sh https://linuxgsm.sh && chmod +x /home/vhserver/linuxgsm.sh && bash /home/vhserver/linuxgsm.sh /home/vhserver/vhserver
sudo -u vhserver /home/vhserver/vhserver install
