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

# get the portage tree
RUN wget https://dev.gentoo.org/~hasufell/distfiles/portage-20150820.tar.xz
RUN tar xf portage-20150820.tar.xz -C /usr
RUN rm portage-20150820.tar.xz

# unmask latest paludis
RUN echo "sys-apps/paludis ~amd64" >> /etc/portage/package.accept_keywords

# install paludis and eselect-package-manager
RUN emerge sys-apps/paludis app-eselect/eselect-package-manager

# select paludis as default package manager
RUN eselect package-manager set paludis && . /etc/profile

# copy base configuration
COPY paludis-config /etc/paludis

# create necessary directories for paludis
RUN mkdir -p /var/cache/paludis/names /var/cache/paludis/metadata /var/tmp/paludis

# fix permissions on tmpdir
RUN chown paludisbuild:paludisbuild /var/tmp/paludis
RUN chmod g+w /var/tmp/paludis

# sync layman repo
RUN chgrp paludisbuild /dev/tty && cave sync layman

# fix cache
RUN chgrp paludisbuild /dev/tty && cave fix-cache

# fix permissions on distdir
RUN chown -R paludisbuild:paludisbuild /usr/portage/distfiles
RUN chmod g+w -R /usr/portage/distfiles

# update unmasked paludis in paludis config too
RUN echo "sys-apps/paludis ~amd64" >> /etc/paludis/keywords.conf

# install a few tools on top of stage3
RUN chgrp paludisbuild /dev/tty && cave resolve -z eix dev-vcs/git -x

# update eix-cache
RUN eix-update

# update world
RUN chgrp paludisbuild /dev/tty && cave resolve -c world -x

# cleanup
RUN rm -rf /usr/portage/distfiles/*
