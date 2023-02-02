FROM frallan/elemental-cli:rootfs AS elemental-cli
FROM quay.io/luet/base:0.33.0 AS luet

FROM registry.opensuse.org/opensuse/tumbleweed:latest AS build

COPY --from=luet /usr/bin/luet /usr/bin/luet
COPY luet.yaml /etc/luet/luet.yaml
ENV LUET_NOLOCK=true
SHELL ["/usr/bin/luet", "install", "-y", "--system-target", "/framework"]

RUN system/cos-setup
RUN cloud-config/upgrade_grub_hooks
RUN system/grub2-config
RUN system/base-dracut-modules

FROM registry.opensuse.org/home/flonnegren/container/flonnegren/base:latest as default

COPY --from=build /framework /
COPY --from=elemental-cli /usr/bin/elemental /usr/bin/elemental

COPY files/ /

RUN systemctl enable NetworkManager
RUN mkinitrd
