suffix=$3 # e.g. -hardened
arch=$1
busybox_version=$2
dist="http://distfiles.gentoo.org/releases/${arch}/autobuilds/"
stage3="$(wget -q -O- ${dist}/latest-stage3-${arch}${suffix}.txt | tail -n 1 | cut -f 1 -d ' ')"

mkdir newWorldOrder; cd newWorldOrder
echo "Downloading and extracting ${stage3}..."
wget -c "${dist}/${stage3}"
bunzip2 -c $(basename ${stage3}) | tar --exclude "./etc/hosts" --exclude "./sys/*" -xf -
rm -f $(basename ${stage3})
wget -O /busybox "http://www.busybox.net/downloads/binaries/latest/busybox-${busybox_version}"
chmod +x /busybox
/busybox rm -rf /lib* /usr /var /bin /sbin /opt /mnt /media /root /home /run /tmp
/busybox cp -fRap lib* /
/busybox cp -fRap bin boot home media mnt opt root run sbin tmp usr var /
/busybox cp -fRap etc/* /etc/
cd /
#commit suicide
/busybox rm -rf newWorldOrder /busybox /build.sh /linuxrc


latest_stage3=$(curl "${base_url}/latest-stage3-amd64.txt" 2>/dev/null | grep -v '#' | awk '{print $1}')
stage3=$(basename "${latest_stage3}")


# Self destruct
rm -f /Dockerfile /build.sh

echo "Bootstrapped ${stage3} into /:"
ls --color -lah
