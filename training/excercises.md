Here's the setup for today's training:
```
(192.168.0.10) client1 -----            ----- server1 (1.1.0.10)
                            \          /
                             \        /
          (192.168.0.254) eth0 router eth1 (1.1.0.254)
                             /        \
                            /          \
(192.168.0.20) client2 -----            ----- server2 (1.1.0.20)
```

1. Login into client1 and ping google's dns (8.8.8.8) and invalid IP (e.g. 0.1.2.3). Right after that look at contrack entries. What do the tuples look like?

2. From clinet1 `curl 1.1.0.10`. In the second terminal login into the router container. Look at contrack entries. What do the tuples look like?
   server1 cannot respond to client1. It has a private IP. We need to setup NAT on the router. Let's try adding that.
   Now that we have NAT setup, let's try the curl again. What do the contrack entries look like now?
   Helper questions:
      It is a common situation we have at home. Our devices have private IPs and we want to access the internet. What NAT should be used? SNAT or DNAT?
      What is the difference between SNAT and MASQUERADE? Can MASQUERADE be used here?

3. Now let's try to look at the packets traveling through the router's forward chain. We can use the following command:
   `iptables -t filter -A FORWARD -j NFQUEUE --queue-num 2`
   Now try to curl. Does it work? It shouldn't. That is because we are sending all packets to the queue but noone is processing them. Let's try to process them with:
   `python3 logger.py`
   Now try to curl again. What do you see in the logger? What do you see in the contrack entries? Does that make sense?

4. Now let's try to also monitor the packets going through the router's POSTROUTING chain. We can use the following command:
   `iptables -t nat -F POSTROUTING`
   `iptables -t nat -A POSTROUTING -o eth0 -m mark --mark 0 -j NFQUEUE --queue-num 1`
   `iptables -t nat -A POSTROUTING -o eth0 -m mark --mark 1 -j MASQUERADE`
   Now try to curl again. What do you see in the logger?
   Now let's talk a little bit about the magic with the marks and about the logger.py script.

5. To not have those messing with our tests lets flush the POSTROUTING chain in the nat table and FORWARD chain in the filter table.
   `iptables -t filter -F FORWARD`
   `iptables -t nat -F POSTROUTING`
   `iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE`

6. We have decided to run the local http server on client2. It listens on port 1234. We want to access it from the outside.
   Let's setup the router to forward the packets from port 88 to client2's port 1234.

7. We currently have a problem with our router. It does not have firewall enabled. We allow all the packets to flow through the FORWARD chain. We need to fix that.
   Try to curl from server2 this address: 192.168.0.10:666. We don't want it to work.
   We need to allow the packets to flow through the FORWARD chain only if they are related to the established connections or if they are destined to the client2's port 1234.
      - First let's try to set the default policy to DROP.
      - Now we let's allow for NEW connections only from the inside to the outside. It does not work. Why?
      - Let's allow the packets related to the established connections to flow through the FORWARD chain.
      - We still have a problem. We need to allow the packets destined to the client2's port 1234 to flow through the FORWARD chain. Let's fix thix.

Homework:
Debugging iptables can done with TRACE target. Unfortunatelly it will not work in a docker. Try to create a rule with -j TRACE target on your host machine and see the kernel logs.
You should see how the packet traverses the iptables rules.
Append this rule to the RAW chain.


HINTS IN RANDOM ORDER:
`iptables -t filter -A FORWARD -m conntrack --ctstate ESTABLISHED -j ACCEPT`
`iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE`
`iptables -t filter -A FORWARD -i eth1 -m conntrack --ctstate NEW -j ACCEPT`
`iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 88 -j DNAT --to-destination 192.168.0.20:1234`
`iptables -t filter -A FORWARD -d 192.168.0.20 -p tcp -m tcp --dport 1234 -j ACCEPT`
`iptables -t filter -P FORWARD DROP`
