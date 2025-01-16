FROM docker.io/gentoo/portage:latest AS portage
FROM docker.io/gentoo/stage3:latest AS buildtime

# portage image is more frequently updated than the stage3
# so copy the package repo to keep it up to date
COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

# copy portage settings
COPY make.conf /etc/portage/make.conf
COPY flags /etc/portage/package.use/flags

# setup cross compiler
# RUN emerge crosstool-ng
# COPY crosstool.conf /usr/share/crosstool-ng/.config
# RUN cd /usr/share/crosstool-ng && ct-ng build

# emerge packages for devcontainer
RUN emerge --root=/runtime sys-apps/baselayout
RUN emerge --root=/runtime qemu
RUN emerge --root=/runtime busybox
RUN ln -s busybox /runtime/bin/sh
RUN emerge --root=/runtime sys-apps/file

RUN emerge --root=/runtime bazelisk
RUN emerge --root=/runtime curl
RUN emerge --root=/runtime make

# add cross compiler to path
RUN echo 'export PATH=/opt/cross/bin:$PATH' >> /runtime/etc/profile

# only copy c++ runtime libs from gcc, no full native compiler needed
RUN cp -r /usr/lib/gcc /runtime/usr/lib/gcc
RUN cp -r /etc/env.d/gcc /runtime/etc/env.d/gcc
RUN cp -r /etc/ld.so.conf.d /runtime/etc/

FROM scratch
COPY --from=buildtime /runtime /

# reload dynamic linker paths so gcc libs can be found
RUN /sbin/ldconfig

# symlink busybox applets
RUN /bin/busybox --list-applets | while read -r; do \
		[ "${REPLY}" = "${REPLY#bin/}" ] && target=../bin/busybox || target=busybox; \
		busybox ln -s "${target}" /${REPLY} &>/dev/null || true; \
	done

CMD ["/bin/sh", "--login"]
