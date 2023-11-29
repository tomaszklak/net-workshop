#!/bin/bash
set -euxo pipefail
swanctl --initiate --child host-host
sleep 1
ipsec status
