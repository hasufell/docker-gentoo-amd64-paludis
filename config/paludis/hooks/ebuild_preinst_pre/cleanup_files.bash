#!/bin/bash

source "${PALUDIS_EBUILD_DIR}/echo_functions.bash"

if [[ ${CATEGORY}/${PN} == "net-mail/dovecot" ]] ; then
	files=(
		"${D}"/usr/include/*
		"${D}"/usr/lib64/debug/*
		"${D}"/usr/share/man/*
		"${D}"/usr/share/gtk-doc/*
		"${D}"/usr/share/info/*
		"${D}"/usr/share/mime/*
		"${D}"/usr/share/applications/*
	)
else
	files=(
		"${D}"/usr/include/*
		"${D}"/usr/share/doc/*
		"${D}"/usr/lib64/debug/*
		"${D}"/usr/share/man/*
		"${D}"/usr/share/gtk-doc/*
		"${D}"/usr/share/info/*
		"${D}"/usr/share/mime/*
		"${D}"/usr/share/applications/*
	)
fi


einfo "Removing ${files[@]}"

rm -rf "${files[@]}"

