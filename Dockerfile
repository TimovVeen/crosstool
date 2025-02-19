# pin image tags to ensure reproducable builds
FROM docker.io/gentoo/portage:20250117 AS portage
FROM docker.io/gentoo/stage3:llvm-20250113 AS buildtime

# portage image is more frequently updated than the stage3
# so copy the package repo to keep it up to date
COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

# copy portage settings
COPY make.conf /etc/portage/make.conf
COPY flags /etc/portage/package.use/flags

# devcontainer packages
RUN emerge --root=/runtime sys-apps/baselayout
RUN mkdir /runtime/usr/bin
RUN ln -s usr/bin /runtime/bin && ln -s usr/bin /runtime/sbin
RUN emerge --root=/runtime net-misc/curl dev-build/bazelisk dev-build/make sys-apps/coreutils llvm-core/clang app-arch/tar app-arch/xz-utils app-alternatives/sh app-shells/bash


# set up qemu for arm32 userspace emulation
RUN echo 'app-emulation/qemu ~amd64 ~arm64' > /etc/portage/package.accept_keywords/qemu
RUN emerge qemu
RUN cp /usr/bin/qemu-arm /runtime/usr/bin/qemu-arm
COPY qemu-wrapper.c /qemu-wrapper.c
RUN gcc /qemu-wrapper.c -O3 -s -o /runtime/usr/bin/qemu-wrapper

# COPY arm32-crosschain-x86_64.sh /arm32-crosschain-x86_64.sh
# RUN ./arm32-crosschain-x86_64.sh -y -d /runtime/opt/cross

# add cross compiler to path
# RUN echo 'export PATH=/opt/cross/bin:$PATH' >> /runtime/etc/profile
# RUN echo 'export CC=armv7a-xilinx-linux-musleabi-gcc' >> /runtime/etc/profile
# RUN echo 'export CXX=armv7a-xilinx-linux-musleabi-g++' >> /runtime/etc/profile
# RUN echo 'export PS1="\w: "' >> /runtime/etc/profile

FROM scratch
COPY --from=buildtime /runtime /

VOLUME [ "/project" ]
WORKDIR /project
CMD ["/bin/sh", "--login"]
