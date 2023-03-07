FROM frallan/elemental-cli:rootfs AS elemental-cli
FROM opensuse/tumbleweed as default

RUN zypper install -y grub2 grub2-i386-pc grub2-x86_64-efi grub2-x86_64-efi-extras shim dracut kernel kernel-firmware-all systemd \
                      bash syslinux lvm2 parted dosfstools e2fsprogs rsync util-linux-systemd coreutils \
                      squashfs NetworkManager device-mapper iproute2 tar curl ca-certificates ca-certificates-mozilla \
                      procps openssl openssh vim-small less iputils cryptsetup bind-utils wget jq

COPY --from=elemental-cli /usr/bin/elemental /usr/bin/elemental

COPY files/ /

RUN systemctl enable NetworkManager
RUN elemental init
RUN mkdir -p /run/overlayfs /run/ovlwork

COPY files/etc/cos /etc/cos
