#!/usr/bin/bash
set -euxo pipefail

/shared/common/entrypoint.sh
ip route add fd00:3::40 via fd00:1::20 dev eth0
cp /shared/common/strongswanCert.pem /etc/swanctl/x509ca/strongswanCert.pem
cp /shared/common/moonCert.pem /etc/swanctl/x509/moonCert.pem
cp /shared/common/moonKey.pem /etc/swanctl/private/moonKey.pem
if [ "$ESP" -eq 0 ]; then
  cp /shared/unique/swanctl.conf /etc/swanctl/swanctl.conf
else
  
  cp /shared/unique/swanctl.conf.esp /etc/swanctl/swanctl.conf
fi
service ipsec start
sleep 1
swanctl --load-all
sleep infinity
