#!/usr/bin/env bash
#
# https://properinter.net

set -e

INCLUDE_MT7615_KO=NO
read -p "Enter pppoe-wan username: " WAN_USERNAME
read -p "Enter pppoe-wan password: " WAN_PASSWORD
read -p "MT7615 kernel module [~/mt7615-common.ko]: " MT7615_KO_PATH
MT7615_KO_PATH=${MT7615_KO_PATH:-~/mt7615-common.ko}

if [ -f $MT7615_KO_PATH ]; then
    INCLUDE_MT7615_KO=YES
else
    echo "Skipping MT7615 custom kernel, $MT7615_KO_PATH not found.."
fi

# install system dependencies
sudo apt update
sudo apt install -y build-essential libncurses-dev zlib1g-dev gawk git \
    gettext libssl-dev xsltproc rsync wget unzip python3 python3-setuptools

# prepare openwrt image builder
wget https://downloads.openwrt.org/snapshots/targets/mediatek/filogic/openwrt-imagebuilder-mediatek-filogic.Linux-x86_64.tar.zst
tar --use-compress-program=unzstd -xvf openwrt-imagebuilder-mediatek-filogic.Linux-x86_64.tar.zst

cd openwrt-imagebuilder-mediatek-filogic.Linux-x86_64
mkdir files
cd files
git clone https://github.com/proper-internet/etc.git
rm -rf etc/.git
# update network configuration with your ISP credentials
sed -i -e "s/username@t-online.de/$WAN_USERNAME/" etc/config/network
sed -i -e "s/'password'/'$WAN_PASSWORD'/" etc/config/network
cd ..

if [ $INCLUDE_MT7615_KO = 'YES' ]; then
    KERNEL_VERSION=$(cat .targetinfo | grep "Linux-Version" | head -n 1 | cut -f 2 -d' ')
    mkdir -p files/lib/modules/$KERNEL_VERSION
    cp $MT7615_KO_PATH ./files/lib/modules/$KERNEL_VERSION/
fi

export PROFILE=bananapi_bpi-r4
export PACKAGES="luci luci-ssl iptables-nft sqm-scripts luci-app-sqm wireguard-tools luci-proto-wireguard netperf htop pciutils unbound-daemon unbound-control luci-app-unbound odhcpd kmod-mt7615e kmod-mt7615-common kmod-mt7615-firmware gawk curl ca-bundle ca-certificates tcpdump adblock luci-app-adblock -dnsmasq -odhcpd-ipv6only"
make image PROFILE="$PROFILE" PACKAGES="$PACKAGES" FILES="files"

ls bin/targets/mediatek/filogic/openwrt-mediatek-filogic-bananapi_bpi-r4-sdcard.img.gz
cp bin/targets/mediatek/filogic/openwrt-mediatek-filogic-bananapi_bpi-r4-sdcard.img.gz ~/
echo "OpenWrt image copied to ~/openwrt-mediatek-filogic-bananapi_bpi-r4-sdcard.img.gz"
