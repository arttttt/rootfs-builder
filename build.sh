#!/bin/bash
#set -e
#. ./env.sh

export ARCH=arm
export RFS_WIFI_SSID=$WIFI_SSID
export RFS_WIFI_PASSWORD=$WIFI_PASSWORD

export TOP=$PWD
export SYSROOT=$TOP/fs
export TMP=$TOP/tmp
OUT=$TOP/out

if [[ -d "$SYSROOT" ]]; then
	mkdir $SYSROOT;
fi;

if [[ -d "$TMP" ]]; then
	mkdir$TMP;
fi;

if [[ -d "$OUT" ]]; then
	mkdir$OUT;
fi;

function makeRootFS() {
if [ ! -d "distros/$DISTRO" ]; then
	echo "Distro \"$DISTRO\" not found!";
	return;
fi

	sudo chown -R $UID:$GID $SYSROOT

	distros/$DISTRO/build.sh

	if [ "$?" -ne "0" ]; then
  		exit 1;
	fi;

	nvidia/apply_binaries.sh

	# Chmod
	sudo chown -R 0:0 $SYSROOT/
	sudo chown -R 1000:1000 $SYSROOT/home/alarm

	sudo chmod +s $SYSROOT/usr/bin/chfn
	sudo chmod +s $SYSROOT/usr/bin/newgrp
	sudo chmod +s $SYSROOT/usr/bin/passwd
	sudo chmod +s $SYSROOT/usr/bin/chsh
	sudo chmod +s $SYSROOT/usr/bin/gpasswd
	sudo chmod +s $SYSROOT/bin/umount
	sudo chmod +s $SYSROOT/bin/mount
	sudo chmod +s $SYSROOT/bin/su

	cd $SYSROOT
	sudo tar -cpzf $OUT/${DISTRO}_rootfs.tar.gz .
}

function clean() {
	echo "$SYSROOT will be cleaned";
	rm -r $SYSROOT/*
}

function main()
{
	clear
	echo "---------------------------------------------------"
	echo "Choose distro                                     -"
	echo "---------------------------------------------------"
	echo "1 - arch                                          -"
	echo "---------------------------------------------------"
	echo "2 - debian(not adapted yet)                       -"
	echo "---------------------------------------------------"
	echo "3 - ubuntu(not adapted yet)                       -"
	echo "---------------------------------------------------"
	echo "4 - clean                                         -"
	echo "---------------------------------------------------"
	echo "5 - exit                                          -"
	echo "---------------------------------------------------"
	printf %s "your choice: "
	read env

	case $env in
		1) DISTRO="arch";makeRootFS;;
		2) DISTRO="none";makeRootFS;;
		3) DISTRO="none";makeRootFS;;
		4) clean;;
		5) clear;return;;
		*) main;;
	esac
}

main
