#KindWorks Script for Arch
echo "================="
echo "Starting installs"
echo "================="
echo .
sudo pacman -Syu
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay-git.git
cd yay-git
makepkg -sri
yay -S zoom google-chrome libreoffice audacity --noconfirm

mkdir /home/$USER/kindworks
cd /home/$USER/kindworks
wget https://github.com/LenovoGuy98/kw-startup-go/raw/refs/heads/master/kw.desktop
wget https://github.com/LenovoGuy98/kw-startup-go/raw/refs/heads/master/kw-startup
wget https://github.com/LenovoGuy98/kw-startup-go/raw/refs/heads/master/kindworks.png
wget https://github.com/LenovoGuy98/kw-startup-go/raw/refs/heads/master/Your-Linux-system.pdf
chmod 755 kw-startup
mv kw.desktop /home/$USER/.config/autostart/
sudo ufw enable
