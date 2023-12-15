# Dynamic routing - RIP (Routing Information Protocol)

RIP is one of the oldest dynamic routing solutions, and is not longer that widely used. It is a distance-vector routing protocol, meaning that it determines the best path to a destination by the number of routers that lie in between the source and the destination. The largest number of hops allowed for RIP is 15, after that the network is considered unreachable.

RIP supports two types of messages
- **Request**: ask others routers for routing tables
- **Response**: send routing table

Responses are sent even if there are no requests.

RIP has three important timers (or four if you're using a cisco router)
- **Update timer** - How often routing information is shared. The update timer has a small random variance to it, which was thought to make the updates spread out more over time, but that is not the case. Default is 30 seconds
- **Invalid timer** - How long a routing entry can be in the routing table without being updated. After that time, the hop count for that destination is set to 16. Default is 180 seconds
- **Flush timer** - How long to wait after an update to remove the destination from the routing table. Default is 240 
- **Hold down timer (Cisco-specific)** - How long to wait after a destination has been updated before allowing that entry to be updated again. Allows routes to stabilize. Default is 180 seconds

A RIP router will share its routing table if it recieves a request from another router, or every <update timer> seconds. RIP has no mechanism for retransmission, so if a message gets lost, you have to wait for the next update to be sent.

When a router receives the routing table of another node, it will only update its own routing table for destinations that are either new or if there is a route with a lower hop count than what is currently stored for that destination. The routing table is then updated with the IP of the destination, the hop count, and the next hop.

If there are two routes to a network with the same hop count, both will be stored in the routing table. If that happens, the router will do equal-cost load balancing over the routes.

RIP has a few ways to prevent loops in the routing table
- **Split horizon**: Routes are not sent to the neighbor from which it was learned
- **Route poisoning**: If something is wrong with a router, it will send 16 as the hop count for its routes to show that it's unreachable
- **Holddown**: When a router receives information that a destination is unreachable, it will wait a certain amount of time before allowing that destination to be updated to a reachable hop count

RIP supports a silent mode, where the router will send requests and receice the routing tables of other routers, but will not share its own routing table. 

RIPv1 and RIPv2 use port 520, RIPng uses port 521, all version use UDP.

### Advantages

- Simple
- Automatic routing table updates
- Low bandwidth overhead for small networks

### Disadvantages

- Limited scalability
- RIPv1 lacks security
- High bandwidth for bigger networks
- Doesn't consider speed or stability, only hop count

## RIPv1

- Communicates using broadcasts
- Doesn't support authentication, making it vulnerable to various attacks
- Classful (doesn't send subnet mask information, no CIDR support)

## FRR

Open source software IP router, forked from quagga a long time ago. Currently under the linux foundation umbrella.

### zebra

IP routing manager. Interacts with the kernel and updates routing tables etc.

### ripd

Allows FRR and zebra to use the RIP protocol.

### Exercises

#### Setup

Do these steps on each docker container

FRR contains more services than we care about, so let's stop it and only run what we need:
`service frr stop`

FRR has a "master config" that will make the different services ignore their specific configs. Let's remove it
`rm /etc/frr/frr.conf`

Copy our config to the correct place
`cp /shared/unique/ripd.conf /etc/frr/`

Start zebra daemon
`zebra -d`

Start ripd in terminal mode. This allows us to interact with to check things like routing table etc.
`ripd -t`

#### Observe

On one of the container, additionally run `tcpdump -ni any -X -v`. Look at the rip messages in there. What can you see?

You can inspect the routing information by running `show ip rip` in the terminal where we ran `ripd -t`. To get more information about the router itself, you can run `show ip rip status` in that same terminal.

Notable information:
- Only the shortest path to a destination is stored in the routing table
- The entries in `tcpdump` doesn't contain subnet information
- The messages are sent via broadcast on port 520

## RIPv2

- Communicates using multicast, on IP 224.0.0.9
- Supports different types of authentication
- Has route tags  to distinguish routes learned from RIP vs other protocols
- Classless (sends subnet mask information, also supports classful)
- Maintains hop limit for backward compatibility

RIPv2 routers understand RIPv1, but no the other way around. RIPv2 routers can be configured to receive updates from v1, or be pure v2. 

### Exercises

Stop all the routers. Change router 5 to use RIPv2, but allow receiving v1. What happens?

Stop all routers. Change routers 1-4 to be pure v2 routers, make router 5 v1. What happens?

Notable information:
- Messages are sent via multicast on IP 224.0.0.9, on port 520
- The entries in `tcpdump` contain subnet information

## RIPng

- Mostly RIPv2 but for IPv6
- Changes the authentication mechanism to use IPSec

## Homework
- Authentication for RIPv2
- Redo exercises but for RIPng