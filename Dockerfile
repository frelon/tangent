FROM frallan/elemental-cli:rootfs AS elemental-cli
FROM registry.opensuse.org/home/flonnegren/container/flonnegren/base:latest as default

COPY --from=elemental-cli /usr/bin/elemental /usr/bin/elemental

COPY files/ /

RUN systemctl enable NetworkManager
RUN elemental init

COPY files/etc/cos /etc/cos
