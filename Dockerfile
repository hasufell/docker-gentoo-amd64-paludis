FROM busybox

MAINTAINER Julian Ospald <hasufell@gentoo.org>

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
RUN echo "sys-apps/paludis search-index xml" >> \
	/etc/portage/package.use/paludis.use
RUN echo "sys-apps/paludis ~amd64" >> /etc/portage/package.accept_keywords

# install paludis and eselect-package-manager
RUN emerge-webrsync && \
	emerge sys-apps/paludis app-eselect/eselect-package-manager && \
	eselect package-manager set paludis && . /etc/profile && \
	emerge dev-vcs/git && \
	rm -r /usr/portage

# copy base configuration
COPY paludis-config /etc/paludis

# copy hooks and gentoo repository configuration from a submodule
# these set up a git based sync system for the gentoo repository
COPY paludis-gentoo-git-config/hooks /etc/paludis/hooks
COPY paludis-gentoo-git-config/repositories/gentoo.conf /etc/paludis/repositories/gentoo.conf

# create necessary directories for paludis
RUN mkdir -p /var/cache/paludis/names /var/cache/paludis/metadata /var/tmp/paludis

# fix permissions on tmpdir
RUN chown paludisbuild:paludisbuild /var/tmp/paludis
RUN chmod g+w /var/tmp/paludis

# sync tree via paludis
RUN git -C /usr clone --depth=1 https://github.com/gentoo/gentoo.git portage
RUN chgrp paludisbuild /dev/tty && cave sync
RUN mkdir /usr/portage/distfiles

# fix cache
RUN chgrp paludisbuild /dev/tty && cave fix-cache

# fix permissions on distdir
RUN chown paludisbuild:paludisbuild /usr/portage/distfiles
RUN chmod g+w /usr/portage/distfiles

# update unmasked paludis in paludis config too
RUN echo "sys-apps/paludis ~amd64" >> /etc/paludis/keywords.conf

# install eix
RUN chgrp paludisbuild /dev/tty && cave resolve -z eix -x && \
	rm -rf /usr/portage/distfiles/*

# update eix-cache
RUN eix-update

# update world
RUN chgrp paludisbuild /dev/tty && cave resolve -c world -x && \
	rm -rf /usr/portage/distfiles/*

# certificates sometimes have broken links in stage3, fix it
RUN chgrp paludisbuild /dev/tty && \
	cave resolve -z -1 app-misc/ca-certificates -x && \
	rm -rf /usr/portage/distfiles/*
