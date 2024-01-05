#!/bin/bash

rm /etc/frr/frr.conf
zebra -d
bgpd -d
sleep infinity