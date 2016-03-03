## Usage

This image is optimized for size, as such, stuff in the following
directories is removed:
```
/srv/binhost/
/usr/include/
/usr/lib64/debug/
/usr/portage/
/usr/share/applications/
/usr/share/doc/
/usr/share/gtk-doc/
/usr/share/info/
/usr/share/man/
/usr/share/mime/
/var/cache/paludis/metadata/
/var/cache/paludis/names/
/var/tmp/paludis/
```

When installing something, the hook in `ebuild_preinst_pre/cleanup_files.bash`
will remove files from the following directories from the package before
it is merged:
```
/usr/include/
/usr/lib64/debug/
/usr/share/applications/
/usr/share/doc/
/usr/share/gtk-doc/
/usr/share/info/
/usr/share/man/
/usr/share/mime/
```

When creating a derived image, you have to do the following before
you can attempt package installation, since the checked out files
of the main gentoo repositories are removed, while the git repository
data is still intact:
```sh
git -C /usr/portage checkout -- .
cave sync gentoo
```

A complete Dockerfile command to install something could look like this:
```
RUN chgrp paludisbuild /dev/tty && \
	git -C /usr/portage checkout -- . && \
	env-update && \
	source /etc/profile && \
	cave sync && \
	cave resolve <the-package-I-want> -x && \
	rm -rf /var/cache/paludis/names/* /var/cache/paludis/metadata/* \
		/var/tmp/paludis/* /usr/portage/* /srv/binhost/*
```

A few things to note are also:
* non-binary packages are not allowed, since /usr/include/ files are removed and compilation would probably fail hard (a complete rebuild via `cave resolve -e world -x` would be necessary after removing the `ebuild_preinst_pre/cleanup_files.bash` hook)
* the same goes for Dockerfiles that do local compilations, they will have to run `cave resolve -e world -x` in order to restore all development files
* a regular sync does not update the actual repositories, so we have a defined state (files in `/etc/paludis/repositories/*.conf` can be modified to allow that though)
