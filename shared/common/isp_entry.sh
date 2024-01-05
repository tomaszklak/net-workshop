#!/bin/bash

rm /etc/frr/frr.conf
cp /shared/unique/bgp.conf /etc/frr/bgpd.conf
zebra -d
bgpd -d
sleep infinity