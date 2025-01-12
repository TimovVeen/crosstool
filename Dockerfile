FROM docker.io/gentoo/portage:latest AS portage
FROM docker.io/gentoo/stage3:latest AS crosstool

COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

RUN echo 'FEATURES="-ipc-sandbox -pid-sandbox -network-sandbox -usersandbox -mount-sandbox -sandbox"' >> /etc/portage/make.conf

COPY keywords /etc/portage/package.accept_keywords/keywords
RUN emerge -qv crosstool-ng
COPY crosstool.conf /usr/share/crosstool-ng/.config
RUN cd /usr/share/crosstool-ng && ct-ng build

FROM docker.io/library/alpine:3.21
COPY --from=crosstool /opt/cross /opt/cross
RUN echo 'export PATH=/opt/cross/bin:$PATH' >> /etc/profile

RUN wget https://github.com/bazelbuild/bazelisk/releases/download/v1.25.0/bazelisk-linux-amd64 \
-O /usr/local/bin/bazel
RUN chmod +x /usr/local/bin/bazel

RUN apk add libstdc++
RUN apk add libgcc

CMD ["/bin/sh", "--login"]
