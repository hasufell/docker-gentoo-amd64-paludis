FROM busybox
MAINTAINER Julian Ospald <hasufell@posteo.de>


########### BOOTSTRAP ###########

# This one should be present by running the build.sh script
ADD build.sh /

# get up stage3
RUN /build.sh amd64 x86_64

# Setup the (virtually) current runlevel
RUN echo "default" > /run/openrc/softlevel

# Setup the rc_sys
RUN sed -e 's/#rc_sys=""/rc_sys="lxc"/g' -i /etc/rc.conf

# Setup the net.lo runlevel
RUN ln -s /etc/init.d/net.lo /run/openrc/started/net.lo

# Setup the net.eth0 runlevel
RUN ln -s /etc/init.d/net.lo /etc/init.d/net.eth0
RUN ln -s /etc/init.d/net.eth0 /run/openrc/started/net.eth0

# By default, UTC system
RUN echo 'UTC' > /etc/timezone

# set locale
# eselect probably doesn't do much, we need to use ENV to persistently set this
RUN eselect locale set en_US.utf8 && env-update && source /etc/profile
ENV LANG en_US.utf8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.utf8

# unmask latest paludis
RUN echo "sys-apps/paludis pbins search-index xml" >> \
	/etc/portage/package.use/paludis.use
RUN echo "sys-apps/paludis ~amd64" >> /etc/portage/package.accept_keywords

# install paludis and eselect-package-manager
RUN emerge-webrsync && \
	emerge sys-apps/paludis app-eselect/eselect-package-manager && \
	eselect package-manager set paludis && . /etc/profile && \
	emerge dev-vcs/git app-portage/eix && \
	rm -r /usr/portage

# clone repositories
RUN git -C /usr clone --depth=1 https://github.com/gentoo/gentoo.git portage

RUN git clone --depth=1 https://github.com/hasufell/gentoo-binhost.git \
		/usr/gentoo-binhost && \
	git clone --depth=1 https://github.com/hasufell/libressl.git \
		/var/db/paludis/repositories/libressl && \
	git clone --depth=1 https://github.com/MOSAIKSoftware/mosaik-overlay.git \
		/var/db/paludis/repositories/mosaik-overlay

# get paludis config
RUN git clone --depth=1 https://github.com/hasufell/gentoo-server-config.git \
		/etc/paludis

# allow non-binary packages
RUN rm /etc/paludis/package_mask.conf.d/binhost.conf

# rm etckeeper, we don't need it here
RUN rm /etc/paludis/hooks/ebuild_postinst_post/etckeeper.bash \
	/etc/paludis/hooks/ebuild_postrm_post/etckeeper.bash \
	/etc/paludis/hooks/ebuild_preinst_post/etckeeper.bash \
	/etc/paludis/hooks/ebuild_prerm_post/etckeeper.bash

# create various paludis related directories/files and fix permissions
RUN mkdir /usr/portage/distfiles && \
	chown paludisbuild:paludisbuild /usr/portage/distfiles && \
	chmod g+w /usr/portage/distfiles && \
	mkdir -p /var/cache/paludis/names /var/cache/paludis/metadata \
		/var/tmp/paludis && \
	chown paludisbuild:paludisbuild /var/tmp/paludis && \
	chmod g+w /var/tmp/paludis && \
	mkdir -p /etc/paludis/tmp /srv/binhost && \
	touch /etc/paludis/tmp/cave_resume /etc/paludis/tmp/cave-search-index && \
	chown paludisbuild:paludisbuild /etc/paludis/tmp/cave_resume \
		/etc/paludis/tmp/cave-search-index /etc/paludis/tmp /srv/binhost && \
	chmod g+w /etc/paludis/tmp/cave_resume /etc/paludis/tmp/cave-search-index \
		/etc/paludis/tmp /srv/binhost

# add /etc/env.d/90cave
RUN echo 'CAVE_RESUME_FILE_OPT="--resume-file /etc/paludis/tmp/cave_resume"' \
		> /etc/env.d/90cave && \
	echo 'CAVE_SEARCH_INDEX=/etc/paludis/tmp/cave-search-index' \
		>> /etc/env.d/90cave

# sync
RUN chgrp paludisbuild /dev/tty && env-update && . /etc/profile && \
	cave sync

#################################


##### PACKAGE INSTALLATION #####

# install everything
RUN chgrp paludisbuild /dev/tty && \
	cave resolve -c toolchain -x -f && \
	cave resolve -c world -x -f \
		-D dev-libs/openssl -D virtual/udev -D sys-fs/udev \
		-F sys-fs/eudev -U '*/*' \
		--permit-old-version '*/*' && \
	cave resolve -c world -x \
		-D dev-libs/openssl -D virtual/udev -D sys-fs/udev \
		-F sys-fs/eudev -U '*/*' \
		--permit-old-version '*/*' && \
	cave fix-linkage -x && \
	rm -rf /usr/portage/distfiles/* /srv/binhost/*

# certificates sometimes have broken links in stage3, fix it
RUN chgrp paludisbuild /dev/tty && \
	cave resolve -z -1 app-misc/ca-certificates -x && \
	rm -rf /usr/portage/distfiles/*

# update etc files... hope this doesn't screw up
RUN etc-update --automode -5

################################



