#!/bin/bash

set -e

# By default, UTC system
echo 'UTC' > /etc/timezone

# set locale
# eselect probably doesn't do much, we need to use ENV to persistently set this
eselect locale set en_US.utf8
env-update
source /etc/profile
export LANG=en_US.utf8
export LANGUAGE=en_US:en
export LC_ALL=en_US.utf8
cat << EOF > /etc/locale.gen
en_US ISO-8859-1
en_US.UTF-8 UTF-8
EOF
locale-gen

# unmask latest paludis
echo "sys-apps/paludis pbins search-index xml" >> \
	/etc/portage/package.use/paludis.use
echo "app-text/xmlto -text" >> \
	/etc/portage/package.use/paludis.use
echo "sys-apps/paludis ~amd64" >> /etc/portage/package.accept_keywords

# install paludis and eselect-package-manager
emerge-webrsync
emerge sys-apps/paludis app-eselect/eselect-package-manager
eselect package-manager set paludis
source /etc/profile
emerge dev-vcs/git
rm -r /usr/portage

# clone repositories

git -C /usr clone --depth=1 https://github.com/gentoo/gentoo.git portage

# get paludis config
git clone --depth=1 https://github.com/hasufell/gentoo-server-config.git \
	/etc/paludis

# rm etckeeper, we don't need it here
rm /etc/paludis/hooks/ebuild_postinst_post/etckeeper.bash \
	/etc/paludis/hooks/ebuild_postrm_post/etckeeper.bash \
	/etc/paludis/hooks/ebuild_preinst_post/etckeeper.bash \
	/etc/paludis/hooks/ebuild_prerm_post/etckeeper.bash

# create various paludis related directories/files and fix permissions
mkdir /usr/portage/distfiles
chown paludisbuild:paludisbuild /usr/portage/distfiles
chmod g+w /usr/portage/distfiles
mkdir -p /var/cache/paludis/names /var/cache/paludis/metadata \
	/var/tmp/paludis
chown paludisbuild:paludisbuild /var/tmp/paludis
chmod g+w /var/tmp/paludis
mkdir -p /etc/paludis/tmp /srv/binhost
touch /etc/paludis/tmp/cave_resume /etc/paludis/tmp/cave-search-index
chown paludisbuild:paludisbuild /etc/paludis/tmp/cave_resume \
	/etc/paludis/tmp/cave-search-index /etc/paludis/tmp /srv/binhost
chmod g+w /etc/paludis/tmp/cave_resume /etc/paludis/tmp/cave-search-index \
	/etc/paludis/tmp /srv/binhost

# add /etc/env.d/90cave
echo 'CAVE_RESUME_FILE_OPT="--resume-file /etc/paludis/tmp/cave_resume"' \
	> /etc/env.d/90cave
echo 'CAVE_SEARCH_INDEX=/etc/paludis/tmp/cave-search-index' \
	>> /etc/env.d/90cave


# sync
chgrp paludisbuild /dev/tty
env-update
source /etc/profile
cave sync


##### PACKAGE INSTALLATION #####
chgrp paludisbuild /dev/tty
eselect python set python2.7
cave resolve -c world -x -f \
	-D dev-libs/openssl -D virtual/udev \
	-D dev-lang/perl \
	-D dev-lang/python \
	-F sys-fs/eudev -U '*/*' \
	--permit-old-version '*/*'
cave resolve -c world -x \
	-D dev-libs/openssl -D virtual/udev \
	-D dev-lang/perl \
	-D dev-lang/python \
	-F sys-fs/eudev -U '*/*' \
	--permit-old-version '*/*'
cave purge -x
cave fix-linkage -x

# # we only need one python
cave resolve -z -1 app-misc/ca-certificates \
	\!dev-lang/python:3.4 --favour-matching dev-lang/python:2.7 -x

rm -rf /build.sh

