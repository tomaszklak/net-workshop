#!/bin/bash

ip route del default
ip route add default via 3.0.0.254
sleep infinity