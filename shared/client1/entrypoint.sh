#!/bin/bash
ip route del default
ip route add default via 192.168.0.254 dev eth0
echo "secret" > secret.txt
python3 -m http.server 666
sleep infinity
