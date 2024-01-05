#!/bin/bash

ip route del default
ip route add default via 1.0.1.254
sleep infinity