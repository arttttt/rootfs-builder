#!/bin/bash
DISTRO_NAME="Arch Linux ARM"

echo -e '
           \e[H\e[2J
          \e[0;36m.
         \e[0;36m/ \
        \e[0;36m/   \      \e[1;37m               #     \e[1;36m| *
       \e[0;36m/^.   \     \e[1;37m a##e #%" a#"e 6##%  \e[1;36m| | |-^-. |   | \ /
      \e[0;36m/  .-.  \    \e[1;37m.oOo# #   #    #  #  \e[1;36m| | |   | |   |  X
     \e[0;36m/  (   ) _\   \e[1;37m%OoO# #   %#e" #  #  \e[1;36m| | |   | ^._.| / \ \e[0;37mTM
    \e[1;36m/ _.~   ~._^\
   \e[1;36m/.^         ^.\ \e[0;37mTM"
'

if [ -z ${RFS_WIFI_SSID+x} ]; then
  echo "WIFI SSID not set! Using 'MIPAD'";
  WIFI_SSID="MIPAD"
fi

if [ -z ${RFS_WIFI_PASSWORD+x} ]; then
  echo "WIFI Password not set! Using 'password'";
  WIFI_PASSWORD="password!"
fi

function e_status(){
  echo -e '\e[1;36m'${1}'\e[0;37m'
}

function run_in_qemu(){
  PROOT_NO_SECCOMP=1 proot -0 -r $SYSROOT -q qemu-$ARCH-static -b /etc/resolv.conf -b /etc/mtab -b /proc -b /sys $*
}

if [ -f $TMP/rootfs_builder_$DISTRO.tar.gz ]; then
  e_status "$DISTRO_NAME tarball is already available in /tmp/, we're going to use this file."
else
  e_status "Downloading..."
  wget -O $TMP/rootfs_builder_$DISTRO.tar.gz -q 'http://os.archlinuxarm.org/os/ArchLinuxARM-armv7-latest.tar.gz'
fi

e_status "Extracting..."
bsdtar -xpf $TMP/rootfs_builder_$DISTRO.tar.gz -C $SYSROOT

e_status "QEMU-chrooting"

packages="lightdm 
lightdm-gtk-greeter 
xf86-video-fbdev 
binutils 
make 
noto-fonts 
sudo 
git 
gcc 
xorg-xinit 
xorg-server 
onboard 
bluez 
bluez-tools 
bluez-utils
openbox 
sudo 
kitty
netctl
wpa_supplicant
dhcpcd
dialog 
mesa
networkmanager"

e_status "Adding Pubkeys..."
run_in_qemu pacman-key --init
# HACK: `pacman-key --init && pacman-key --populate archlinuxarm` hangs.
cp distros/$DISTRO/pacman-gpg/* $SYSROOT/etc/pacman.d/gnupg

e_status "Installing packages..."
run_in_qemu pacman -Syu --needed --noconfirm $packages

e_status "Setting hostname..."
echo "mipad" > $SYSROOT/etc/hostname

run_in_qemu systemctl enable NetworkManager
run_in_qemu systemctl enable lightdm
run_in_qemu systemctl enable bluetooth
run_in_qemu systemctl enable dhcpcd

mkdir -p $SYSROOT/home/alarm/.config/openbox
cat > $SYSROOT/home/alarm/.config/openbox/autostart <<EOF 
kitty &
EOF

e_status "Removing /var/cache/ content"
rm -rf $SYSROOT/var/cache
mkdir -p $SYSROOT/var/cache

e_status "RootFS generation done."

unset RFS_WIFI_SSID
unset RFS_WIFI_PASSWORD
