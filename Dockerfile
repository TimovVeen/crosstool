# pin image tags to ensure reproducable builds
FROM docker.io/gentoo/portage:20250117 AS portage
FROM docker.io/gentoo/stage3:nomultilib-20250113 AS buildtime

# portage image is more frequently updated than the stage3
# so copy the package repo to keep it up to date
COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

# copy portage settings
COPY make.conf /etc/portage/make.conf
COPY flags /etc/portage/package.use/flags

# setup cross compiler
# make sure the git version of crosstool-ng is masked, since arm64 isn't keyworded
RUN echo '=sys-devel/crosstool-ng-9999' >> /etc/portage/package.mask/masks
RUN emerge crosstool-ng
COPY crosstool.conf /usr/share/crosstool-ng/.config
RUN cd /usr/share/crosstool-ng && ct-ng build

# devcontainer packages
RUN emerge --root=/runtime sys-apps/baselayout
RUN mkdir /runtime/usr/bin
RUN ln -s usr/bin /runtime/bin && ln -s usr/bin /runtime/sbin
RUN emerge --root=/runtime sys-apps/file net-misc/curl dev-build/bazelisk \
    dev-build/make sys-apps/busybox
RUN ln -s busybox /runtime/usr/bin/sh

# set up qemu for arm32 userspace emulation
RUN emerge qemu
RUN cp /usr/bin/qemu-arm /runtime/usr/bin/qemu-arm-base
COPY qemu-wrapper.c /qemu-wrapper.c
RUN gcc -static /qemu-wrapper.c -O3 -s -o /runtime/usr/bin/qemu-arm

# only copy c++ runtime libs from gcc, no full native compiler needed
RUN cp -r /usr/lib/gcc /runtime/usr/lib/gcc
RUN cp -r /etc/env.d/gcc /runtime/etc/env.d/gcc
RUN cp -r /etc/ld.so.conf.d /runtime/etc/

# add cross compiler to path
RUN echo 'export PATH=/opt/cross/bin:$PATH' >> /runtime/etc/profile
RUN echo 'export CC=armv7a-xilinx-linux-musleabi-gcc' >> /runtime/etc/profile
RUN echo 'export CXX=armv7a-xilinx-linux-musleabi-g++' >> /runtime/etc/profile
RUN echo 'export PS1="\w: "' >> /runtime/etc/profile

FROM scratch
COPY --from=buildtime /runtime /

# reload dynamic linker paths so gcc libs can be found
RUN /sbin/ldconfig

# symlink busybox applets
RUN /bin/busybox --list-applets | while read -r; do \
    [ "${REPLY}" = "${REPLY#bin/}" ] && target=../bin/busybox || target=busybox; \
    busybox ln -s "${target}" /${REPLY} &>/dev/null || true; \
    done

VOLUME [ "/project" ]
WORKDIR /project
CMD ["/bin/sh", "--login"]
