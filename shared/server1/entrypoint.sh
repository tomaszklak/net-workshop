#!/bin/bash
ip route del default
python3 -m http.server 80
sleep infinity
