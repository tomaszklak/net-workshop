#!/bin/bash

ip route del default
ip route add default via 2.0.0.254
sleep infinity