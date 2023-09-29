#!/bin/sh

for name in client1 server1 server2 client2 client3; do
    docker exec -it $name /shared/common/check_connectivity.rb
done
