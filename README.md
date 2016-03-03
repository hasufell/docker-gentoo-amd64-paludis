## Usage

This image is optimized for size, as such, stuff in the following
directories is removed:
```
/usr/portage/
/srv/binhost/
/usr/include/
/usr/share/doc/
/usr/lib64/debug/
/usr/share/man/
/usr/share/gtk-doc/
/usr/share/info/
/usr/share/mime/
/usr/share/applications/
/var/cache/paludis/names/
/var/cache/paludis/metadata/
/var/tmp/paludis/
```

When installing something, the hook in `ebuild_preinst_pre/cleanup_files.bash`
will remove files from the following directories from the package before
it is merged:
```
/usr/include/
/usr/share/doc/
/usr/lib64/debug/
/usr/share/man/
/usr/share/gtk-doc/
/usr/share/info/
/usr/share/mime/
/usr/share/applications/
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
RUN git -C /usr/portage checkout -- . && \
	env-update && \
	source /etc/profile && \
	cave sync gentoo && \
	cave resolve -z www-servers/nginx:0 && \
	rm -rf /var/cache/paludis/names/* /var/cache/paludis/metadata/* \
		/var/tmp/paludis/* /usr/portage/* /srv/binhost/*
```

A few things to note are also:
* non-binary packages are not allowed, since /usr/include/ files are removed and compilation would probably fail hard (a complete rebuild via `cave resolve -e world -x` would be necessary after removing the `ebuild_preinst_pre/cleanup_files.bash` hook)
* a regular sync does not update the actual repositories, so we have a defined state (files in `/etc/paludis/repositories/*.conf` can be modified to allow that though)
