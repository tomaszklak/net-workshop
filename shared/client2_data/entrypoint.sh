#!/usr/bin/bash
/shared/common/entrypoint.sh
ip route add fd00:1::10 via fd00:3::30 dev eth0
cp /shared/common/strongswanCert.pem /etc/swanctl/x509ca/strongswanCert.pem
cp /shared/common/sunCert.pem /etc/swanctl/x509/sunCert.pem
cp /shared/common/sunKey.pem /etc/swanctl/private/sunKey.pem
if [ "$ESP" -eq 0 ]; then
  cp /shared/unique/swanctl.conf /etc/swanctl/swanctl.conf
else

  cp /shared/unique/swanctl.conf.esp /etc/swanctl/swanctl.conf
fi
service ipsec start
sleep 1
swanctl --load-all
sleep infinity
