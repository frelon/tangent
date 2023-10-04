FROM ghcr.io/frelon/elemental-cli:mount AS elemental-cli
FROM opensuse/tumbleweed as default

RUN ARCH=$(uname -m); \
    if [[ $ARCH == "aarch64" ]]; then ARCH="arm64"; fi; \
    zypper --non-interactive install --no-recommends -- \
      kernel-default \
      device-mapper \
      dracut \
      grub2 \
      grub2-${ARCH}-efi \
      shim \
      haveged \
      systemd \
      NetworkManager \
      openssh-server \
      openssh-clients \
      timezone \
      parted \
      e2fsprogs \
      dosfstools \
      mtools \
      xorriso \
      findutils \
      gptfdisk \
      rsync \
      squashfs \
      lvm2 \
      tar \
      gzip \
      neovim \
      which \
      less \
      sudo \
      curl \
      ca-certificates \
      ca-certificates-mozilla \
      iproute2 \
      iputils \
      cryptsetup \
      wget \
      jq \
      lsof \
      sed

COPY --from=elemental-cli /usr/bin/elemental /usr/bin/elemental

COPY files/ /

RUN echo "PermitRootLogin yes" > /etc/ssh/sshd_config.d/rootlogin.conf

ARG REPO
ARG VERSION

RUN echo IMAGE_REPO=\"${REPO}\"         >> /etc/os-release && \
    echo IMAGE_TAG=\"${VERSION}\"           >> /etc/os-release && \
    echo IMAGE=\"${REPO}:${VERSION}\" >> /etc/os-release && \
    echo TIMESTAMP="`date +'%Y%m%d%H%M%S'`" >> /etc/os-release && \
    echo GRUB_ENTRY_NAME=\"Tangent\" >> /etc/os-release

RUN systemctl enable NetworkManager
RUN elemental init -f --debug elemental-rootfs,elemental-setup,grub-config,dracut-config,cloud-config-defaults,cloud-config-essentials

COPY files/system /system
