ARG ELEMENTAL_IMAGE
FROM ${ELEMENTAL_IMAGE} AS elemental-cli

FROM registry.opensuse.org/opensuse/tumbleweed:latest as default

RUN ARCH=$(uname -m); \
    zypper --non-interactive removerepo repo-update || true; \
    [[ "${ARCH}" == "aarch64" ]] && ARCH="arm64"; \
    zypper --non-interactive --gpg-auto-import-keys install --no-recommends -- \
      kernel-default \
      device-mapper \
      dracut \
      shim \
      grub2 \
      grub2-${ARCH}-efi \
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
      vim \
      which \
      less \
      sudo \
      curl \
      sed \
      patch \
      iproute2 && \
    zypper clean --all

COPY --from=elemental-cli /usr/bin/elemental /usr/bin/elemental

COPY files/ /

RUN mkdir -p /etc/ssh/sshd_config.d && echo "PermitRootLogin yes" > /etc/ssh/sshd_config.d/rootlogin.conf

ARG REPO
ARG VERSION

RUN echo IMAGE_REPO=\"${REPO}\"         >> /etc/os-release && \
    echo IMAGE_TAG=\"${VERSION}\"           >> /etc/os-release && \
    echo IMAGE=\"${REPO}:${VERSION}\" >> /etc/os-release && \
    echo TIMESTAMP="`date +'%Y%m%d%H%M%S'`" >> /etc/os-release && \
    echo GRUB_ENTRY_NAME=\"Tangent\" >> /etc/os-release

RUN systemctl enable NetworkManager
RUN elemental init -f --debug
