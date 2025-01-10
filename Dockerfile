FROM docker.io/gentoo/portage:latest AS portage
FROM docker.io/gentoo/stage3:latest AS buildtime

COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

RUN echo 'FEATURES="-ipc-sandbox -pid-sandbox -network-sandbox -usersandbox -mount-sandbox -sandbox"' >> /etc/portage/make.conf

RUN getuto

# RUN mkdir -p /etc/portage/savedconfig/sys-apps
# COPY busybox.conf /etc/portage/savedconfig/sys-apps/busybox
# RUN env USE="savedconfig" emerge -qvk --root=/runtime busybox
RUN emerge -qvk --root=/runtime busybox
RUN ln -s busybox /runtime/bin/sh

RUN emerge -qvk --root=/runtime bazelisk

COPY keywords /etc/portage/package.accept_keywords/keywords
RUN emerge -qvk crosstool-ng
COPY crosstool.conf /usr/share/crosstool-ng/.config

RUN cd /usr/share/crosstool-ng/ && ct-ng build

# RUN env-update

FROM scratch
# COPY --from=buildtime /etc/profile /etc/profile
# COPY --from=buildtime /etc/profile.env /etc/profile.env

COPY --from=buildtime /runtime /

RUN /bin/busybox --list-applets | while read -r; do \
		[ "${REPLY}" = "${REPLY#bin/}" ] && target=../bin/busybox || target=busybox; \
		busybox ln -s "${target}" /${REPLY} &>/dev/null || true; \
	done
CMD ["/bin/sh", "--login"]
