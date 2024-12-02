#!/usr/bin/env bash
#
# https://properinter.net

set -e

# get the commit hash from the snapshot build info
GIT_COMMIT=$(curl -s https://downloads.openwrt.org/snapshots/targets/mediatek/filogic/version.buildinfo | grep -oP '\-\K[0-9a-f]+')

# install system dependencies
sudo apt update
sudo apt -y install build-essential clang flex bison g++ gawk \
    gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev \
    python3-setuptools rsync swig unzip zlib1g-dev file wget quilt

# configure quilt to match openwrt's patch format
cat << EOF > ~/.quiltrc
QUILT_DIFF_ARGS="--no-timestamps --no-index -p ab --color=auto"
QUILT_REFRESH_ARGS="--no-timestamps --no-index -p ab"
QUILT_SERIES_ARGS="--color=auto"
QUILT_PATCH_OPTS="--unified"
QUILT_DIFF_OPTS="-p"
EDITOR="vim"
EOF

# prepare the openwrt build system
git clone https://github.com/openwrt/openwrt.git
cd openwrt
# checkout the same revision as you're using in your openwrt build
git checkout $GIT_COMMIT
./scripts/feeds update -a
./scripts/feeds install -a

# get the config build for the latest snapshot
wget https://downloads.openwrt.org/snapshots/targets/mediatek/filogic/config.buildinfo -O .config
make defconfig
# prepare the toolchain
make -j$(nproc) tools/install
make -j$(nproc) toolchain/install

# make package/kernel/mt76/{clean,prepare,build} will not build modules, only
# package them. if they weren't built previously then you'll only get empty
# module packages. we need to build the kernel modules first.
make -j$(nproc) target/linux/compile

# prepare the mt76 module with quilt so we can apply the patch before the build
make -j$(nproc) package/mt76/{clean,prepare} V=s QUILT=1
cd $(ls -d build_dir/target-aarch64_cortex-a53_musl/linux-mediatek_filogic/mt76-* | head -n 1)
# apply existing patches first, if any
if [ -f patches/series ]; then
    quilt push -a
fi
wget https://raw.githubusercontent.com/proper-internet/patches/refs/heads/main/package/kernel/mt76/010-mt7615_txpower_fix.patch -P /tmp
quilt import /tmp/010-mt7615_txpower_fix.patch
quilt push
cd -
make -j$(nproc) package/kernel/mt76/update V=s
# build the kernel module
make -j$(nproc) package/kernel/mt76/{clean,compile} package/index V=s

# copy the kernel module to the home folder
ls $(ls -d build_dir/target-aarch64_cortex-a53_musl/linux-mediatek_filogic/mt76-*/.pkgdir/kmod-mt7615-common/lib/modules/*/)/mt7615-common.ko
cp $(ls -d build_dir/target-aarch64_cortex-a53_musl/linux-mediatek_filogic/mt76-*/.pkgdir/kmod-mt7615-common/lib/modules/*/)/mt7615-common.ko ~/
echo "MT615 kernel module copied to ~/mt7615-common.ko"
