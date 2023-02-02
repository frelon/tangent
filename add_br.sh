#!/bin/bash
ip link add vbr0 type bridge
ip link set vbr0 up
ip link set enp2s0f0 master vbr0
dhclient vbr0
