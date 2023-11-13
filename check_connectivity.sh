#!/bin/sh

for name in client1_ipv6 server1_ipv6 server2_ipv6 client2_ipv6; do
	docker exec -it $name /shared/common/check_connectivity.rb
done
