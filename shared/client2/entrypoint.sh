#!/bin/bash
ip route del default
ip route add default via 192.168.0.254 dev eth0
head -c 1G /dev/urandom > sample.txt
python3 -m http.server 1234
sleep infinity
