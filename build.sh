#!/bin/sh
#
# Copyright (C) 2017 OVH OverTheBox
# Copyright (C) 2017-2020 Ycarus (Yannick Chabanois) <ycarus@zugaina.org> for OpenMPTCProuter project
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

set -e

umask 0022
unset GREP_OPTIONS SED

_get_repo() (
	mkdir -p "$1"
	cd "$1"
	[ -d .git ] || git init
	if git remote get-url origin >/dev/null 2>/dev/null; then
		git remote set-url origin "$2"
	else
		git remote add origin "$2"
	fi
	git fetch origin -f
	git fetch origin --tags -f
	git checkout -f "origin/$3" -B "build" 2>/dev/null || git checkout "$3" -B "build"
)

ManualVersion=gv2-v1.0.3

OMR_DIST=${OMR_DIST:-openmptcprouter}
OMR_HOST=${OMR_HOST:-$(curl -sS ifconfig.co)}
OMR_PORT=${OMR_PORT:-80}
OMR_KEEPBIN=${OMR_KEEPBIN:-no}
OMR_IMG=${OMR_IMG:-yes}
#OMR_UEFI=${OMR_UEFI:-yes}
OMR_PACKAGES=${OMR_PACKAGES:-full}
OMR_ALL_PACKAGES=${OMR_ALL_PACKAGES:-no}
OMR_TARGET=${OMR_TARGET:-rk3328-gather}
OMR_TARGET_CONFIG="config-$OMR_TARGET"
OMR_KERNEL=${OMR_KERNEL:-5.4}
SHORTCUT_FE=${SHORTCUT_FE:-yes}
#OMR_RELEASE=${OMR_RELEASE:-$(git describe --tags `git rev-list --tags --max-count=1` | sed 's/^\([0-9.]*\).*/\1/')}
#OMR_RELEASE=${OMR_RELEASE:-$(git tag --sort=committerdate | tail -1)}
OMR_RELEASE="gather-v2"
#${OMR_RELEASE:-$(git describe --tags `git rev-list --tags --max-count=1` | tail -1 | cut -d '-' -f1)}
OMR_REPO="localhost"
#${OMR_REPO:-http://$OMR_HOST:$OMR_PORT/release/$OMR_RELEASE/$OMR_TARGET}

OMR_FEED_URL="https://github.com/WillzenZou/openmptcprouter-feeds"
#"${OMR_FEED_URL:-https://github.com/suyuan168/openmptcprouter-feeds}"
OMR_FEED_SRC="0.78.0g"
#"${OMR_FEED_SRC:-158865a7dba8d05d0aa9f3ffe21474ee4ad94da4}"

CUSTOM_FEED_URL="${CUSTOM_FEED_URL}"

OMR_OPENWRT=${OMR_OPENWRT:-default}

if [ ! -f "$OMR_TARGET_CONFIG" ]; then
	echo "Target $OMR_TARGET not found !"
	#exit 1
fi

if [ "$OMR_TARGET" = "rpi3" ]; then
	OMR_REAL_TARGET="aarch64_cortex-a53"
elif [ "$OMR_TARGET" = "rpi4" ]; then
	OMR_REAL_TARGET="aarch64_cortex-a72"
elif [ "$OMR_TARGET" = "rpi2" ]; then
	OMR_REAL_TARGET="arm_cortex-a7_neon-vfpv4"
elif [ "$OMR_TARGET" = "wrt3200acm" ]; then
	OMR_REAL_TARGET="arm_cortex-a9_vfpv3"
elif [ "$OMR_TARGET" = "wrt32x" ]; then
	OMR_REAL_TARGET="arm_cortex-a9_vfpv3"
elif [ "$OMR_TARGET" = "bpi-r2" ]; then
	OMR_REAL_TARGET="arm_cortex-a7_neon-vfpv4"
elif [ "$OMR_TARGET" = "nanopi_neo" ]; then
	OMR_REAL_TARGET="arm_cortex-a7_neon-vfpv4"
elif [ "$OMR_TARGET" = "bpi-r64" ]; then
	OMR_REAL_TARGET="aarch64_cortex-a53"
elif [ "$OMR_TARGET" = "espressobin" ]; then
	OMR_REAL_TARGET="aarch64_cortex-a53"
elif [ "$OMR_TARGET" = "x86" ]; then
	OMR_REAL_TARGET="i386_pentium4"
elif [ "$OMR_TARGET" = "r2s" ]; then
	OMR_REAL_TARGET="aarch64_generic"
elif [ "$OMR_TARGET" = "rk3328-gather" ]; then
        OMR_REAL_TARGET="aarch64_generic"
else
	OMR_REAL_TARGET=${OMR_TARGET}
fi

#_get_repo source https://github.com/ysurac/openmptcprouter-source "master"
echo "OpenWrt types: "${OMR_OPENWRT}
if [ "$OMR_OPENWRT" = "default" ]; then
	if [ "$OMR_KERNEL" = "5.4" ]; then
		_get_repo "$OMR_TARGET/source" https://github.com/openwrt/openwrt "f441be3921c769b732f0148f005d4f1bbace0508"
		_get_repo feeds/packages https://github.com/openwrt/packages "ab94e0709a9c796d34d723ddba44380f7b3d8698"
		_get_repo feeds/luci https://github.com/openwrt/luci "0818d835cacd9fa75b8685aabe6378ac09b95145"
	else
		_get_repo "$OMR_TARGET/source" https://github.com/openwrt/openwrt "02de391b086dd2b7a72c2394cfb66cec666a51c1"
		_get_repo feeds/packages https://github.com/openwrt/packages "7b2dd3e9efbc20ef4e7f47f60c3db9aaef37c0a5"
		_get_repo feeds/luci https://github.com/openwrt/luci "73e21c3b5791ac97aa7b437c8e683cdbea407395"
	fi
elif [ "$OMR_OPENWRT" = "master" ]; then
	_get_repo "$OMR_TARGET/source" https://github.com/openwrt/openwrt "master"
	_get_repo feeds/packages https://github.com/openwrt/packages "master"
	_get_repo feeds/luci https://github.com/openwrt/luci "master"
else
	_get_repo "$OMR_TARGET/source" https://github.com/openwrt/openwrt "${OMR_OPENWRT}"
	_get_repo feeds/packages https://github.com/openwrt/packages "${OMR_OPENWRT}"
	_get_repo feeds/luci https://github.com/openwrt/luci "${OMR_OPENWRT}"
fi

if [ -z "$OMR_FEED" ]; then
	OMR_FEED=feeds/openmptcprouter
	_get_repo "$OMR_FEED" "$OMR_FEED_URL" "$OMR_FEED_SRC"
fi

if [ -n "$CUSTOM_FEED_URL" ] && [ -z "$CUSTOM_FEED" ]; then
	CUSTOM_FEED=feeds/${OMR_DIST}
	_get_repo "$CUSTOM_FEED" "$CUSTOM_FEED_URL" "master"
fi

if [ -n "$1" ] && [ -f "$OMR_FEED/$1/Makefile" ]; then
	OMR_DIST=$1
	shift 1
fi

if [ "$OMR_KEEPBIN" = "no" ]; then 
	rm -rf "$OMR_TARGET/source/bin"
fi
rm -rf "$OMR_TARGET/source/files" "$OMR_TARGET/source/tmp"
#rm -rf "$OMR_TARGET/source/target/linux/mediatek/patches-4.14"
cp -rf root/* "$OMR_TARGET/source"

# $(git -C "$OMR_FEED" tag --sort=committerdate | tail -1)
cat >> "$OMR_TARGET/source/package/base-files/files/etc/banner" <<EOF
------------------------------------------------------------------------------
 PACKAGE:     $OMR_DIST
 VERSION:     $ManualVersion
 TARGET:      $OMR_TARGET
 ARCH:        $OMR_REAL_TARGET
 BUILD DATE:  $(date -u)
------------------------------------------------------------------------------
EOF

cat > "$OMR_TARGET/source/feeds.conf" <<EOF
src-link packages $(readlink -f feeds/packages)
src-link luci $(readlink -f feeds/luci)
src-link openmptcprouter $(readlink -f "$OMR_FEED")
src-link NanoHatOLED $(readlink -f patches/GatherOLED)
src-link GatherHMI $(readlink -f patches/GatherHMI)
EOF

if [ -n "$CUSTOM_FEED" ]; then
	echo "src-link ${OMR_DIST} $(readlink -f ${CUSTOM_FEED})" >> "$OMR_TARGET/source/feeds.conf"
fi

if [ "$OMR_DIST" = "openmptcprouter" ]; then
	cat > "$OMR_TARGET/source/package/system/opkg/files/customfeeds.conf" <<-EOF
	src/gz openwrt_luci http://packages.openmptcprouter.com/${OMR_RELEASE}/${OMR_REAL_TARGET}/luci
	src/gz openwrt_packages http://packages.openmptcprouter.com/${OMR_RELEASE}/${OMR_REAL_TARGET}/packages
	src/gz openwrt_base http://packages.openmptcprouter.com/${OMR_RELEASE}/${OMR_REAL_TARGET}/base
	src/gz openwrt_routing http://packages.openmptcprouter.com/${OMR_RELEASE}/${OMR_REAL_TARGET}/routing
	src/gz openwrt_telephony http://packages.openmptcprouter.com/${OMR_RELEASE}/${OMR_REAL_TARGET}/telephony
	EOF
elif [ -n "$OMR_PACKAGES_URL" ]; then
	cat > "$OMR_TARGET/source/package/system/opkg/files/customfeeds.conf" <<-EOF
	src/gz openwrt_luci ${OMR_PACKAGES_URL}/${OMR_RELEASE}/${OMR_REAL_TARGET}/luci
	src/gz openwrt_packages ${OMR_PACKAGES_URL}/${OMR_RELEASE}/${OMR_REAL_TARGET}/packages
	src/gz openwrt_base ${OMR_PACKAGES_URL}/${OMR_RELEASE}/${OMR_REAL_TARGET}/base
	src/gz openwrt_routing ${OMR_PACKAGES_URL}/${OMR_RELEASE}/${OMR_REAL_TARGET}/routing
	src/gz openwrt_telephony ${OMR_PACKAGES_URL}/${OMR_RELEASE}/${OMR_REAL_TARGET}/telephony
	EOF
else
	cat > "$OMR_TARGET/source/package/system/opkg/files/customfeeds.conf" <<-EOF
	src/gz openwrt_luci http://downloads.openwrt.org/snapshots/packages/${OMR_REAL_TARGET}/luci
	src/gz openwrt_packages http://downloads.openwrt.org/snapshots/packages/${OMR_REAL_TARGET}/packages
	src/gz openwrt_base http://downloads.openwrt.org/snapshots/packages/${OMR_REAL_TARGET}/base
	src/gz openwrt_routing http://downloads.openwrt.org/snapshots/packages/${OMR_REAL_TARGET}/routing
	src/gz openwrt_telephony http://downloads.openwrt.org/snapshots/packages/${OMR_REAL_TARGET}/telephony
	EOF
fi
#cat > "$OMR_TARGET/source/package/system/opkg/files/customfeeds.conf" <<EOF
#src/gz openwrt_luci http://downloads.openwrt.org/releases/18.06.0/packages/${OMR_REAL_TARGET}/luci
#src/gz openwrt_packages http://downloads.openwrt.org/releases/18.06.0/packages/${OMR_REAL_TARGET}/packages
#src/gz openwrt_base http://downloads.openwrt.org/releases/18.06.0/packages/${OMR_REAL_TARGET}/base
#src/gz openwrt_routing http://downloads.openwrt.org/releases/18.06.0/packages/${OMR_REAL_TARGET}/routing
#src/gz openwrt_telephony http://downloads.openwrt.org/releases/18.06.0/packages/${OMR_REAL_TARGET}/telephony
#EOF

# $(git -C "$OMR_FEED" tag --sort=committerdate | tail -1)
# $(git -C "$OMR_FEED" tag --sort=committerdate | tail -1)-$(git -C "$OMR_FEED" rev-parse --short HEAD)
if [ -f "$OMR_TARGET_CONFIG" ]; then
	cat "$OMR_TARGET_CONFIG" config -> "$OMR_TARGET/source/.config" <<-EOF
	CONFIG_IMAGEOPT=y
	CONFIG_VERSIONOPT=y
	CONFIG_VERSION_DIST="$OMR_DIST"
	CONFIG_VERSION_REPO="$OMR_REPO"
	CONFIG_VERSION_NUMBER="$ManualVersion"
	EOF
else
	cat config -> "$OMR_TARGET/source/.config" <<-EOF
	CONFIG_IMAGEOPT=y
	CONFIG_VERSIONOPT=y
	CONFIG_VERSION_DIST="$OMR_DIST"
	CONFIG_VERSION_REPO="$OMR_REPO"
	CONFIG_VERSION_NUMBER="$ManualVersion"
	EOF
fi
if [ "$OMR_ALL_PACKAGES" = "yes" ]; then
	echo 'CONFIG_ALL=y' >> "$OMR_TARGET/source/.config"
	echo 'CONFIG_ALL_NONSHARED=y' >> "$OMR_TARGET/source/.config"
fi
if [ "$OMR_IMG" = "yes" ] && [ "$OMR_TARGET" = "x86_64" ]; then 
	echo 'CONFIG_VDI_IMAGES=y' >> "$OMR_TARGET/source/.config"
	echo 'CONFIG_VMDK_IMAGES=y' >> "$OMR_TARGET/source/.config"
	echo 'CONFIG_VHDX_IMAGES=y' >> "$OMR_TARGET/source/.config"
fi

if [ "$OMR_PACKAGES" = "full" ]; then
	echo "CONFIG_PACKAGE_${OMR_DIST}-full=y" >> "$OMR_TARGET/source/.config"
fi
if [ "$OMR_PACKAGES" = "mini" ]; then
	echo "CONFIG_PACKAGE_${OMR_DIST}-mini=y" >> "$OMR_TARGET/source/.config"
fi
if [ "$OMR_PACKAGES" = "zuixiao" ]; then
	echo "CONFIG_PACKAGE_${OMR_DIST}-zuixiao=y" >> "$OMR_TARGET/source/.config"
fi

if [ "$SHORTCUT_FE" = "yes" ] && [ "$OMR_KERNEL" = "5.4" ]; then
	echo "# CONFIG_PACKAGE_kmod-fast-classifier is not set" >> "$OMR_TARGET/source/.config"
	echo "CONFIG_PACKAGE_kmod-fast-classifier-noload=y" >> "$OMR_TARGET/source/.config"
	echo "CONFIG_PACKAGE_kmod-shortcut-fe-cm=y" >> "$OMR_TARGET/source/.config"
	echo "CONFIG_PACKAGE_kmod-shortcut-fe=y" >> "$OMR_TARGET/source/.config"
else
	echo "# CONFIG_PACKAGE_kmod-fast-classifier is not set" >> "$OMR_TARGET/source/.config"
	echo "# CONFIG_PACKAGE_kmod-fast-classifier-noload is not set" >> "$OMR_TARGET/source/.config"
	echo "# CONFIG_PACKAGE_kmod-shortcut-fe-cm is not set" >> "$OMR_TARGET/source/.config"
	echo "# CONFIG_PACKAGE_kmod-shortcut-fe is not set" >> "$OMR_TARGET/source/.config"
fi
if ([ "$OMR_KERNEL" != "5.4" ] || [ $OMR_TARGET = "nanopi_neo" ]) && [ "$OMR_TARGET" != "x86_64" ] && [ "$OMR_TARGET" != "x86" ]; then
        echo "# CONFIG_PACKAGE_kmod-r8125 is not set" >> "$OMR_TARGET/source/.config"
        echo "# CONFIG_PACKAGE_kmod-r8168 is not set" >> "$OMR_TARGET/source/.config"
fi

cd "$OMR_TARGET/source"

#if [ "$OMR_UEFI" = "yes" ] && [ "$OMR_TARGET" = "x86_64" ]; then 
#	echo "Checking if UEFI patch is set or not"
#	if [ "$(grep 'EFI_IMAGES' target/linux/x86/image/Makefile)" = "" ]; then
#		patch -N -p1 -s < ../../patches/uefi.patch
#	fi
#	echo "Done"
#else
#	if [ "$(grep 'EFI_IMAGES' target/linux/x86/image/Makefile)" != "" ]; then
#		patch -N -R -p1 -s < ../../patches/uefi.patch
#	fi
#fi

#if [ "$OMR_TARGET" = "x86_64" ]; then 
#	echo "Checking if Hyper-V patch is set or not"
#	if ! patch -Rf -N -p1 -s --dry-run < ../../patches/images.patch; then
#		patch -N -p1 -s < ../../patches/images.patch
#	fi
#	echo "Done"
#fi

echo "Checking if No check patch is set or not"
if ! patch -Rf -N -p1 -s --dry-run < ../../patches/nocheck.patch; then
	echo "apply..."
	patch -N -p1 -s < ../../patches/nocheck.patch
fi
echo "Done"

echo "Checking if Nanqinlang patch is set or not"
if ! patch -Rf -N -p1 -s --dry-run < ../../patches/nanqinlang.patch; then
	echo "apply..."
	patch -N -p1 -s < ../../patches/nanqinlang.patch
fi
echo "Done"

# Add BBR2 patch, only working on 64bits images for now
if [ "$OMR_TARGET" = "x86_64" ] || [ "$OMR_TARGET" = "bpi-r64" ] || [ "$OMR_TARGET" = "rpi4" ] || [ "$OMR_TARGET" = "espressobin" ] || [ "$OMR_TARGET" = "r2s" ] || [ "$OMR_TARGET" = "rpi3" ] || [ "$OMR_TARGET" = "rk3328-gather" ]; then
	echo "Checking if BBRv2 patch is set or not"
	if ! patch -Rf -N -p1 -s --dry-run < ../../patches/bbr2.patch; then
		echo "apply..."
		patch -N -p1 -s < ../../patches/bbr2.patch
	fi
	echo "Done"
fi

echo "Checking if smsc75xx patch is set or not"
if ! patch -Rf -N -p1 -s --dry-run < ../../patches/smsc75xx.patch; then
	echo "apply..."
	patch -N -p1 -s < ../../patches/smsc75xx.patch
fi
echo "Done"

#echo "Checking if ipt-nat patch is set or not"
#if ! patch -Rf -N -p1 -s --dry-run < ../../patches/ipt-nat6.patch; then
#	echo "apply..."
#	patch -N -p1 -s < ../../patches/ipt-nat6.patch
#fi
#echo "Done"

#echo "Checking if mvebu patch is set or not"
#if [ ! -d target/linux/mvebu/patches-5.4 ]; then
#	echo "apply..."
#	patch -N -p1 -s < ../../patches/mvebu-5.14.patch
#fi
#echo "Done"

#echo "Checking if opkg install arguement too long patch is set or not"
#if ! patch -Rf -N -p1 -s --dry-run < ../../patches/package-too-long.patch; then
#	echo "apply..."
#	patch -N -p1 -s < ../../patches/package-too-long.patch
#fi
#echo "Done"

echo "Download via IPv4"
if ! patch -Rf -N -p1 -s --dry-run < ../../patches/download-ipv4.patch; then
	patch -N -p1 -s < ../../patches/download-ipv4.patch
fi
echo "Done"

#echo "Remove check rsync"
#if [ "$(grep rsync include/prereq-build.mk)" != "" ]; then
#	patch -N -p1 -s < ../../patches/check-rsync.patch
#fi
#echo "Done"

if [ -f target/linux/mediatek/patches-5.4/0999-hnat.patch ]; then
	rm -f target/linux/mediatek/patches-5.4/0999-hnat.patch
fi

if [ -f target/linux/ipq40xx/patches-5.4/100-GPIO-add-named-gpio-exports.patch ]; then
	rm -f target/linux/ipq40xx/patches-5.4/100-GPIO-add-named-gpio-exports.patch
fi

if [ -f package/boot/uboot-rockchip/patches/100-rockchip-rk3328-Add-support-for-FriendlyARM-NanoPi-R.patch ]; then
	rm -f package/boot/uboot-rockchip/patches/100-rockchip-rk3328-Add-support-for-FriendlyARM-NanoPi-R.patch
fi

#echo "Patch protobuf wrong hash"
#patch -N -R -p1 -s < ../../patches/protobuf_hash.patch
#echo "Done"

#echo "Remove gtime dependency"
#if ! patch -Rf -N -p1 -s --dry-run < ../../patches/gtime.patch; then
#	patch -N -p1 -s < ../../patches/gtime.patch
#fi
#echo "Done"

#if [ -f target/linux/generic/backport-5.4/370-netfilter-nf_flow_table-fix-offloaded-connection-tim.patch ]; then
#	rm -f target/linux/generic/backport-5.4/370-netfilter-nf_flow_table-fix-offloaded-connection-tim.patch
#fi
#if [ -f target/linux/generic/pending-5.4/640-netfilter-nf_flow_table-add-hardware-offload-support.patch ]; then
#	rm -f target/linux/generic/pending-5.4/640-netfilter-nf_flow_table-add-hardware-offload-support.patch
#fi
#if [ -f target/linux/generic/pending-5.4/641-netfilter-nf_flow_table-support-hw-offload-through-v.patch ]; then
#	rm -f target/linux/generic/pending-5.4/641-netfilter-nf_flow_table-support-hw-offload-through-v.patch
#fi
#if [ -f target/linux/generic/pending-5.4/642-net-8021q-support-hardware-flow-table-offload.patch ]; then
#	rm -f target/linux/generic/pending-5.4/642-net-8021q-support-hardware-flow-table-offload.patch
#fi
#if [ -f target/linux/generic/pending-5.4/643-net-bridge-support-hardware-flow-table-offload.patch ]; then
#	rm -f target/linux/generic/pending-5.4/643-net-bridge-support-hardware-flow-table-offload.patch
#fi
#if [ -f target/linux/generic/pending-5.4/644-net-pppoe-support-hardware-flow-table-offload.patch ]; then
#	rm -f target/linux/generic/pending-5.4/644-net-pppoe-support-hardware-flow-table-offload.patch
#fi
#if [ -f target/linux/generic/pending-5.4/645-netfilter-nf_flow_table-rework-hardware-offload-time.patch ]; then
#	rm -f target/linux/generic/pending-5.4/645-netfilter-nf_flow_table-rework-hardware-offload-time.patch
#fi
#if [ -f target/linux/generic/pending-5.4/647-net-dsa-support-hardware-flow-table-offload.patch ]; then
#	rm -f target/linux/generic/pending-5.4/647-net-dsa-support-hardware-flow-table-offload.patch
#fi
#if [ -f target/linux/generic/hack-5.4/650-netfilter-add-xt_OFFLOAD-target.patch ]; then
#	rm -f target/linux/generic/hack-5.4/650-netfilter-add-xt_OFFLOAD-target.patch
#fi
#if [ -f target/linux/generic/pending-5.4/690-net-add-support-for-threaded-NAPI-polling.patch ]; then
#	rm -f target/linux/generic/pending-5.4/690-net-add-support-for-threaded-NAPI-polling.patch
#fi
#if [ -f target/linux/generic/hack-5.4/647-netfilter-flow-acct.patch ]; then
#	rm -f target/linux/generic/hack-5.4/647-netfilter-flow-acct.patch
#fi
#if [ -f target/linux/generic/hack-5.4/953-net-patch-linux-kernel-to-support-shortcut-fe.patch ]; then
#	rm -f target/linux/generic/hack-5.4/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
#fi
if [ -f target/linux/bcm27xx/patches-5.4/950-1031-net-lan78xx-Ack-pending-PHY-ints-when-resetting.patch ]; then
	rm -f target/linux/bcm27xx/patches-5.4/950-1031-net-lan78xx-Ack-pending-PHY-ints-when-resetting.patch
fi
#if [ -f target/linux/generic/pending-5.4/770-16-net-ethernet-mediatek-mtk_eth_soc-add-flow-offloadin.patch ]; then
#	rm -f target/linux/generic/pending-5.4/770-16-net-ethernet-mediatek-mtk_eth_soc-add-flow-offloadin.patch
#fi

# add rtl8812au-ac
echo "Checking if rtl8812au-ac patch is set or not"
if ! patch -Rf -N -p1 -s --dry-run < ../../patches/rtl8812au-ac-update-wireless-5.8.patch; then
	echo "apply..."
	patch -N -p1 -s < ../../patches/rtl8812au-ac-update-wireless-5.8.patch
fi
echo "Done"

# add rtl8821cu.patch
echo "Checking if rtl8821cu patch is set or not"
if ! patch -Rf -N -p1 -s --dry-run < ../../patches/rtl8821cu.patch; then
	echo "apply..."
	patch -N -p1 -s < ../../patches/rtl8821cu.patch
fi
echo "Done"

if [ "$OMR_TARGET" = "nanopi_neo" ]; then 
# add nanopi neo core supported
for i in `ls ../../patches/linux-sunxi-5.4`; do [ ! -e target/linux/sunxi/patches-5.4/$i ] && cp ../../patches/linux-sunxi-5.4/$i target/linux/sunxi/patches-5.4/$i; done
for i in `ls ../../patches/uboot-sunxi`; do [ ! -e package/boot/uboot-sunxi/patches/$i ] && cp ../../patches/uboot-sunxi/$i package/boot/uboot-sunxi/patches/$i; done
cp ../../patches/boot/uEnv-default.txt package/boot/uboot-sunxi/uEnv-default.txt
cp ../../patches/boot/uEnv-pangolin.txt package/boot/uboot-sunxi/uEnv-pangolin.txt
elif [ "$OMR_TARGET" = "rk3328-gather" ]; then
for i in `ls ../../patches/linux-rockchip-5.4`; do [ ! -e target/linux/rockchip/patches-5.4/$i ] && cp ../../patches/linux-rockchip-5.4/$i target/linux/rockchip/patches-5.4/$i; done
for i in `ls ../../patches/uboot-rockchip`; do [ ! -e package/boot/uboot-rockchip/patches/$i ] && cp ../../patches/uboot-rockchip/$i package/boot/uboot-rockchip/patches/$i; done
fi

if [ "$OMR_KERNEL" = "5.4" ]; then
	echo "Set to kernel 5.4 for rpi arch"
	find target/linux/bcm27xx -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=4.19%KERNEL_PATCHVER:=5.4%g' {} \;
	echo "Done"
	echo "Set to kernel 5.4 for x86 arch"
	find target/linux/x86 -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=4.19%KERNEL_PATCHVER:=5.4%g' {} \;
	echo "Done"
	echo "Set to kernel 5.4 for mvebu arch (WRT)"
	find target/linux/mvebu -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=4.19%KERNEL_PATCHVER:=5.4%g' {} \;
	echo "Done"
	echo "Set to kernel 5.4 for mediatek arch (BPI-R2)"
	find target/linux/mediatek -type f -name Makefile -exec sed -i 's%KERNEL_PATCHVER:=4.19%KERNEL_PATCHVER:=5.4%g' {} \;
	echo "Done"
fi

#rm -rf feeds/packages/libs/libwebp
cd "../.."
rm -rf feeds/luci/modules/luci-mod-network
rm -rf feeds/openmptcprouter/luci-theme-argon
rm -rf feeds/openmptcprouter/luci-theme-openwrt-2020
[ -d feeds/${OMR_DIST}/luci-mod-status ] && rm -rf feeds/luci/modules/luci-mod-status
[ -d feeds/${OMR_DIST}/luci-app-statistics ] && rm -rf feeds/luci/applications/luci-app-statistics
[ -d feeds/${OMR_DIST}/luci-proto-modemmanager ] && rm -rf feeds/luci/protocols/luci-proto-modemmanager

echo "Add Occitan translation support"
if ! patch -Rf -N -p1 -s --dry-run < patches/luci-occitan.patch; then
	patch -N -p1 -s < patches/luci-occitan.patch
	#sh wfeeds/luci/build/i18n-add-language.sh oc
fi
[ -d $OMR_FEED/luci-base/po/oc ] && cp -rf $OMR_FEED/luci-base/po/oc feeds/luci/modules/luci-base/po/
echo "Done"

#Patch omr
cd $OMR_FEED
for i in `ls ../../patches/openmptcprouter/*.patch`; do
        echo "Patch OMR changes now: $i"
        if ! patch -Rf -N -p1 -s --dry-run < $i; then
                patch -N -p1 -s < $i
        fi
done
cd ../../

#Mod
cp -R patches/openmptcprouter/files/* feeds/openmptcprouter/
cp -R patches/luci/files/* feeds/luci/

cd feeds/luci
# patch luci
for i in `ls ../../patches/luci/*.patch`; do
	echo "Patch luci changes now: $i"
	if ! patch -Rf -N -p1 -s --dry-run < $i; then
	        patch -N -p1 -s < $i
	fi
done
cd ../../

cd "$OMR_TARGET/source"
echo "Update feeds index"
cp .config .config.keep
scripts/feeds clean
scripts/feeds install -a
scripts/feeds update -a

#cd -
#echo "Checking if fullconenat-luci patch is set or not"
##if ! patch -Rf -N -p1 -s --dry-run < patches/fullconenat-luci.patch; then
#	echo "apply..."
#	patch -N -p1 -s < patches/fullconenat-luci.patch
#fi
#echo "Done"
#cd "$OMR_TARGET/source"

rm -rf feeds/openmptcprouter/serdisplib
#scripts/feeds install -d y -p packages lcd4linux
#scripts/feeds install -d y -p packages serdisplib
scripts/feeds install gatheroled
scripts/feeds install gatherhmi

if [ "$OMR_ALL_PACKAGES" = "yes" ]; then
	scripts/feeds install -a -d m -p packages
	scripts/feeds install -a -d m -p luci
fi
if [ -n "$CUSTOM_FEED" ]; then
	scripts/feeds install -a -d m -p openmptcprouter
	scripts/feeds install -a -d y -f -p ${OMR_DIST}
else
	scripts/feeds install -a -d y -f -p openmptcprouter
fi
scripts/feeds install kmod-macremapper
scripts/feeds install -p luci luci-app-user
scripts/feeds install python3-pyserial
cp .config.keep .config
echo "Done"

if [ ! -f "../../$OMR_TARGET_CONFIG" ]; then
	echo "Target $OMR_TARGET not found ! You have to configure and compile your kernel manually."
	exit 1
fi

echo "Building $OMR_DIST for the target $OMR_TARGET"
make defconfig
#fix rtl8812ct problem
sed -i 's/CONFIG_PACKAGE_kmod-rtl8812au-ct=y/# CONFIG_PACKAGE_kmod-rtl8812au-ct is not set/g' .config

make IGNORE_ERRORS=m V=99 "$@"
echo "Done"
