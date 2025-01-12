FROM docker.io/gentoo/portage:latest AS portage
FROM docker.io/gentoo/stage3:latest AS buildtime

COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

RUN echo 'FEATURES="-ipc-sandbox -pid-sandbox -network-sandbox -usersandbox -mount-sandbox -sandbox"' >> /etc/portage/make.conf

COPY keywords /etc/portage/package.accept_keywords/keywords
RUN emerge -qv crosstool-ng
COPY crosstool.conf /usr/share/crosstool-ng/.config
RUN cd /usr/share/crosstool-ng && ct-ng build

RUN emerge -qv --root=/runtime sys-apps/baselayout
RUN emerge -qvk --root=/runtime busybox
RUN ln -s busybox /runtime/bin/sh
# RUN USE="multicall" emerge -qv --root=/runtime sys-apps/coreutils
# RUN USE="-*" emerge -qv --root=/runtime sys-apps/file
# RUN emerge -qv --root=/runtime app-shells/bash
# RUN emerge -qv --root=/runtime sys-apps/shadow
# RUN USE="minimal" emerge -qv --root=/runtime app-editors/nano
# might need glibc for coreutils

RUN emerge -qv --root=/runtime bazelisk
RUN emerge -qv --root=/runtime curl

RUN echo 'export PATH=/opt/cross/bin:$PATH' >> /runtime/etc/profile

RUN cp -r /usr/lib/gcc /runtime/usr/lib/gcc
RUN cp -r /etc/env.d/gcc /runtime/etc/env.d/gcc
RUN cp -r /etc/ld.so.conf.d /runtime/etc/

FROM scratch
COPY --from=buildtime /runtime /

RUN /sbin/ldconfig

RUN /bin/busybox --list-applets | while read -r; do \
		[ "${REPLY}" = "${REPLY#bin/}" ] && target=../bin/busybox || target=busybox; \
		busybox ln -s "${target}" /${REPLY} &>/dev/null || true; \
	done

CMD ["/bin/sh", "--login"]
