Excercises:

To run the excercise run the following commands:
```
export IPV4_EXCERCISE=<NUMBER>
docker compose down && docker compose build && docker compose up -d
```

We have 4 excercises for today:
* Excercise 1, 2 and 3 are about debugging routing tables. Run the excercise and try to ping client2 from client1. If you can't ping client2, try to debug the network and find out why.
You should be able to do it with two tools: ping itself and traceroute. If you need you can use tcpdump.
* Excercise 4 is similar by try to fix it using proxy ARP. Run the excercise and try to ping client2 from client1. You will not be able to do that. Look at the routing table on the clinet1 and try to understand why. To enable proxy arp on Ubuntu run:
```
echo 1 > /proc/sys/net/ipv4/conf/all/proxy_arp
```
