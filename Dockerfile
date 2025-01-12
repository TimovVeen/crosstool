FROM docker.io/gentoo/portage:latest AS portage
FROM docker.io/gentoo/stage3:latest AS buildtime

COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

RUN echo 'FEATURES="-ipc-sandbox -pid-sandbox -network-sandbox -usersandbox -mount-sandbox -sandbox"' >> /etc/portage/make.conf

RUN emerge -qv --root=/runtime baselayout

# RUN mkdir -p /etc/portage/savedconfig/sys-apps
# COPY busybox.conf /etc/portage/savedconfig/sys-apps/busybox
# RUN env USE="savedconfig" emerge -qvk --root=/runtime busybox
RUN USE="make-symlinks" emerge -qv --root=/runtime busybox
# RUN ln -s busybox /runtime/bin/sh

RUN emerge -qv --root=/runtime bazelisk
RUN emerge -qv --root=/runtime gcc

COPY keywords /etc/portage/package.accept_keywords/keywords
RUN emerge -qv crosstool-ng
COPY crosstool.conf /usr/share/crosstool-ng/.config

RUN cd /usr/share/crosstool-ng/ && ct-ng build

# RUN env-update

FROM scratch
COPY --from=buildtime /runtime /

CMD ["/bin/sh", "--login"]
