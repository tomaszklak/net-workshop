#!/usr/bin/bash
/shared/common/entrypoint.sh
ip route add fd00:3::40 via fd00:2::30 dev eth1
sleep infinity
