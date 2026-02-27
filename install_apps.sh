#!/bin/bash
apt update && apt upgrade -y 
#declare -a packages=("p7zip" "audacity" "firefox" "gimp" "handbrake" "inkscape" "krita" "libreoffice" "tux-paint" "vlc")
for package in ${packages[@]}; do
    echo "******************" 
    echo $package
    echo "******************"
    apt install  $package -y
done
wget https://zoom.us/client/latest/zoom_amd64.deb -O /tmp/zoom_amd64.deb 
echo "******************" 
echo zoom
echo "******************"
apt install --fix-broken /tmp/zoom_amd64.deb -y

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/google-chrome-stable_current_amd64.deb
apt install /tmp/google-chrome-stable_current_amd64.deb -y
wget https://cdn.novabench.net/novabench-x64.tar.gz
tar xvf novabench-x64.tar.gz
./harden_debian_simple.sh

#KindWorks Stuff
git clone  https://github.com/LenovoGuy98/KindWorks_Infomation.gitz
cd KindWorks_Infomation
./install.sh



