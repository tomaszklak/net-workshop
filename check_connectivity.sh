#!/bin/sh

for s in client1 server1 server2 client2; do 
    vagrant ssh $s -c '/vagrant_common/check_connectivity.rb'
done
