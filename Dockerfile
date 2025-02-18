ARG ELEMENTAL_IMAGE
FROM ${ELEMENTAL_IMAGE} AS elemental-cli

FROM registry.opensuse.org/opensuse/tumbleweed:latest as default

RUN ARCH=$(uname -m); \
    if [[ $ARCH == "aarch64" ]]; then ARCH="arm64"; fi; \
    zypper --non-interactive --gpg-auto-import-keys install --no-recommends -- \
      kernel-default \
      device-mapper \
      dracut \
      systemd-boot \
      systemd-experimental \
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
      sed \
      dialog \
      pcr-oracle \
      libtss2-tcti-device0 \
      tpm2-0-tss

RUN zypper --non-interactive addrepo -n unified --enable --refresh https://download.opensuse.org/repositories/home:vlefebvre:unified/openSUSE_Tumbleweed/home:vlefebvre:unified.repo && \
    zypper --non-interactive --gpg-auto-import-keys install --repo unified uki sdbootutil

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
RUN elemental init -f --debug

COPY files/system /system
