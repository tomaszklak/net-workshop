# IPv6 routing

## IPv6 headers

<table>
  <tr>
    <th>Bit</th>
    <th colspan="2" width="25%">1</th>
    <th colspan="2" width="25%">2</th>
    <th colspan="2" width="25%">3</th>
    <th colspan="2" width="25%">4</th>
  </tr>
  <tr>
    <td >0</td>
    <td width="12.5%">Version</td>
    <td width="25%" colspan="2">Traffic Class</td>
    <td colspan=5>Flow Label</td>
  </tr>
  <tr>
    <td>32</td>
    <td colspan="4">Payload Length</td>
    <td colspan="2">Next Header</td>
    <td colspan="2">Hop Limit</td>
  </tr>
  <tr>
    <td>64</td>
    <td colspan="8" rowspan="4">Source Address</td>
  </tr>
  <tr><td>96</td></tr>
  <tr><td>128</td></tr>
  <tr><td>160</td></tr>
  <tr>
    <td>192</td>
    <td colspan="8" rowspan="4">Destination Address</td>
  </tr>
  <tr><td>224</td></tr>
  <tr><td>256</td></tr>
  <tr><td>288</td></tr>
</table>

  1. *Version (4 bits)* - Indicates the version of the Internet Protocol just 6.

  2. *Traffic Class (8 bits)* - has two parts:
   - DSCP - The first 6 bits of the Traffic Class field are used for the Differentiated Services Code Point (DSCP), which defines the class of service (looks quite complex)
   - ECN - The last 2 bits of the Traffic Class field can be used for Explicit Congestion Notification (ECN). ECN informs the end hosts about network congestion without dropping packets.

  3. *Flow Label (20 bits)* - Identifier for creating groups of packets, like TCP streams.

  4. *Payload Length (16 bits)* - Length of the payload including any extension headers, measured from the end of the IPv6 header to the end of the packet.

  5. *Next Header (8 bits)* - Identifies the type of the next extension header, or the type of the upper layer protocol if there are no extension headers.

  6. *Hop Limit (8 bits)* - How many hops can packet do before it dies? Just TTL.

  7. *Source Address (128 bits)* - The IP address of the sender of the packet.

  8. *Destination Address (128 bits)* - The IP address of the intended recipient of the packet.

## IPv6 Address Types

IPv6 addresses are 128-bit identifiers for interfaces and sets of interfaces.
The address itself consists of 8 `:` separated 16-bits parts presented as a hexadecimal number,
for example:

```
fd00:1:0:0:0:0:0:10
```

The addresses are often presented in the shorter form, where prefix and suffix are given
and the bits between them are considered zeros:
```
fd00:1::10
```

Let's have a look at some of the available types of IPv6 addresses.

### Unicast Addresses

A unicast address identifies a single interface. A packet sent to a unicast address is delivered to the interface identified by that address.

- **Global Unicast Address (GUA):**  
  Similar to IPv4 public IP addresses, GUAs are globally unique and routable on the global Internet. They are typically composed of a global routing prefix, a subnet ID, and an interface identifier.  
  Format: `2000::/3`

- **Link-Local Address:**  
  Used for communication between nodes on the same link (or network segment). These are not routable beyond their link and are used for network discovery or when no routers are present.  
  Format: `fe80::/10`

- **Unique Local Address (ULA):**  
  Intended for local communications within a site and are not meant to be routable on the global Internet. They are similar to IPv4 private addresses.  
  Format: `fc00::/7`

- **Special Addresses:**
  - **Loopback Address:** Used by a node to send packets to itself.  
    Format: `::1/128`
  - **Unspecified Address:** Used to indicate the absence of an address.  
    Format: `::/128`

### Multicast Addresses

A multicast address represents a group of interfaces, typically on different nodes. A packet sent to a multicast address is delivered to all interfaces identified by that address.
The multicast address pool is `FF00::/8`.

### Anycast Addresses

An anycast address is assigned to a group of interfaces, usually belonging to different nodes. Packets sent to an anycast address are delivered to the closest interface (as determined by the routing protocols in use).
The address are taken from unicast address pool (either GUA or ULA) and are assigned to more than one interface.

### Reserved Addresses

Some portions of the IPv6 address space are reserved for special purposes, much like in IPv4.

- **IPv4-Mapped Addresses:**  
  These are used to represent IPv4 addresses within an IPv6 context and are used in certain transition mechanisms.  
  Format: `::ffff:0:0/96`

- **IPv6 Addresses for Documentation:**  
  Specifically designated for use in documentation.  
  Format: `2001:db8::/32`

## IPv6 Extension Headers:
Following the main header, these optional headers provide additional packet handling instructions:

- **Hop-by-Hop Options Header**: Examined by every device along the packet's path.
- **Routing Header**: Allows source-defined routing through intermediate nodes.
- **Fragment Header**: Used for fragmenting over-sized packets.
- **Authentication Header (AH)**: Provides authentication and integrity, and protects against replay attacks.
- **Encapsulating Security Payload (ESP) Header**: Offers confidentiality, along with authentication services.
- **Destination Options Header**: Examined only by the packet's final destination.
- **Mobility Header**: Assists mobile devices in maintaining connections while moving across networks.

### Routing Extension Header

<table>
  <tr>
    <td width="25%">Next header</td>
    <td width="25%">Header extension length</td>
    <td width="25%">Routing type</td>
    <td width="25%">Segments left</td>
  </tr>
  <tr>
    <td colspan="4" width="100%">Intermediate address 2</td>
  </tr>
  <tr>
    <td colspan="4" width="100%">...</td>
  </tr>
  <tr>
    <td colspan="4" width="100%">Destination address</td>
  </tr>
</table>

Routing header may allow to add additional steps to the packet routing,
providing a couple of addresses to which packet should be sent after reaching
its original destination.

We can create such packet using a simple python script using `scapy`:
```
from scapy.all import IPv6, IPv6ExtHdrRouting, ICMPv6EchoRequest, send

# Create an IPv6 packet
packet = IPv6(src="fd00:1::10", dst="fd00:1::20")

# Add a Routing Header
routing_header = IPv6ExtHdrRouting(addresses=["fd00:2::30", "fd00:3::40"], segleft=2)
packet /= routing_header

# Add an ICMPv6 Echo Request (Ping) layer
packet /= ICMPv6EchoRequest()

# Send the packet
send(packet)
```

While it seems to be nice feature and quite a simple way to route a packet on a network which
is not routed properly, support for this header is considered dangerous and the header itself
is deprecated and thus not supported.

## IPv6 static routing

### Basic Concept of Static Routing

- Each node maintains a routing table that directs where packets should be forwarded based on their destination address.
- In static routing, these routes are manually configured and do not change unless manually updated.
- The `ip -6 route` command is typically used for manipulating routing tables in IPv6.

### Configuring Routes for Docker Nodes

Let's add some routes, to be able to send packets from `client1` to `server2` and vice versa.
To do that, we will need to set two additional routes:

 1. To make sure that packets from `client1` which should go to network `fd00:2` will go through `server2`, add a route on `client1`:
    ```
    ip -6 route add fd00:2::/32 via fd00:1::20 dev eth0
    ```
 2. To make sure that packets from `server2` which should go to network `fd00:1` will go through `server1` add route on `server2`:
    ```
    ip -6 route add fd00:1::/32 via fd00:2::20 dev eth0
    ```

It is also necessary to make sure that IPv6 forwarding is enabled on `server1`:
```
sysctl -w net.ipv6.conf.all.forwarding=1
```

Now a ping should reach from `client1` to `server2`.

## Network Discovery Protocol (NDP)

Neighbor Discovery Protocol (NDP) is a key protocol in IPv6, serving a role similar to several protocols in IPv4 such as ARP, ICMP Router Discovery, and ICMP Redirect.
The messages used by the protocol are link-local - they use Link-local IPv6 addresses (which usually use MAC addresses as a component - they are much smaller and should be unique, so why not?).

### Neighbour discovery

For neighbor discovery two types of messages are used:

1. **Neighbor Solicitation**: Sent by devices to determine the link-layer address of a neighbor or to verify a neighbor's reachability.
2. **Neighbor Advertisement**: Sent in response to Neighbor Solicitations or to announce a link-layer address change, contains the link-layer address.

You can trigger neighbour discovery manually by running:
```
ndisc6 <address> <interface>
```
for example if you want discover MAC of `fd00:1:20` from `client1`, the command would be:
```
ndisc6 fd00:1::20 eth0
```

### Router discovery

1. **Router Solicitation**: Sent by devices to discover routers.
2. **Router Advertisement**: Routers advertise their presence along with various parameters.


You can manually discover routers on the given interface by running:
```
rdisc6 <address> <interface>
```

The router need to be prepared to reply to the Router Solicitation messages,
which feature is provided by `radvd` command.
To run it properly, you need a sufficient configuration (stored in `/etc/radvd.conf`), which, for `server1`, may look like:

```
interface eth0 {
    AdvSendAdvert on;

    prefix fd00:1::/32 {
        AdvRouterAddr on;
    };

    route fd00:2::/32 {
        AdvRoutePreference high;  # Can be low, medium, or high
        AdvRouteLifetime 3600;    # Time in seconds (0 means do not use)
    };
};

interface eth1 {
    AdvSendAdvert on;

    prefix fd00:2::/32 {
        AdvRouterAddr on;
    };

    route fd00:1::/32 {
        AdvRoutePreference high;  # Can be low, medium, or high
        AdvRouteLifetime 3600;    # Time in seconds (0 means do not use)
    };
};
```

After adding a configuration, you can run `radvd` daemon by running:

```radvd -n```

You can omit the `-n` option if you want to run it as a daemon, but it might be helpful for playing with configs.

#### Additional configuration

There are a few configuration options which might be necessary to make this setting work:
```
sysctl -w net.ipv6.conf.all.accept_ra=2
```

to allow router advertisement autoconfiguration on nodes which are also routers,
```
sysctl -w net.ipv6.conf.all.accept_ra_rt_info_max_plen=64
```
to make the node automatically adding routes with long prefixes on RA message.

## Using docker images with IPv6

Working IPv6 in docker may need additional configuration.
If it won't work for you out-of-the-box, try adding such config in `/etc/docker/daemon.json`:
```
{
  "ipv6": true,
  "experimental": true,
  "ip6tables": true
}
```
and then run `sudo systemctl docker restart`.

## Excersises

 0. Run the new `docker-compose.yml` from the `IPv6_routing` branch and that its `check_connectivity.sh` script gives the expected result:
 ```
Can connect from client1_ipv6 to server1_ipv6 on fd00:1::20: true
Can connect from client1_ipv6 to server1_ipv6 on fd00:2::20: false
Can connect from client1_ipv6 to server2_ipv6 on fd00:3::30: false
Can connect from client1_ipv6 to server2_ipv6 on fd00:2::30: false
Can connect from client1_ipv6 to client2_ipv6 on fd00:3::40: false

Can connect from server1_ipv6 to client1_ipv6 on fd00:1::10: true
Can connect from server1_ipv6 to server2_ipv6 on fd00:3::30: false
Can connect from server1_ipv6 to server2_ipv6 on fd00:2::30: true
Can connect from server1_ipv6 to client2_ipv6 on fd00:3::40: false

Can connect from server2_ipv6 to client1_ipv6 on fd00:1::10: false
Can connect from server2_ipv6 to server1_ipv6 on fd00:1::20: false
Can connect from server2_ipv6 to server1_ipv6 on fd00:2::20: true
Can connect from server2_ipv6 to client2_ipv6 on fd00:3::40: true

Can connect from client2_ipv6 to client1_ipv6 on fd00:1::10: false
Can connect from client2_ipv6 to server1_ipv6 on fd00:1::20: false
Can connect from client2_ipv6 to server1_ipv6 on fd00:2::20: false
Can connect from client2_ipv6 to server2_ipv6 on fd00:3::30: true
Can connect from client2_ipv6 to server2_ipv6 on fd00:2::30: false
```
 
 1. Route the rest of the network, so you can ping `client2` from `client1`.

 2. Restart the docker containers, so they won't be routed anymore and use `radvd` on `server1` and `server2` to route them again.

 3. (*) Ping `client1` from `client2` with a large ping message (see `-s` ping option), dump the traffic on `server1` and see which extension header can be spotted in Wireshark.

## Homework

 1. Add another node connected to `server2` with IPv6 network and route it statically, making it pingable from both `client1` and `client2`.

