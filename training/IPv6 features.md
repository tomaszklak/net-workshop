### Flow Labels
#### Overview

```
    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |Version| Traffic Class |         **Flow Label**                |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |         Payload Length        |  Next Header  |   Hop Limit   |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                                                               |
   +                                                               +
   |                                                               |
   +                         Source Address                        +
   |                                                               |
   +                                                               +
   |                                                               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                                                               |
   +                                                               +
   |                                                               |
   +                      Destination Address                      +
   |                                                               |
   +                                                               +
   |                                                               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```
[rfc6437](https://www.rfc-editor.org/rfc/rfc6437#section-1):
> A flow is a sequence of packets sent from a particular source to a
   particular (unicast or multicast) destination for which the source
   desires special handling by the intervening routers.

Why we might want to use this feature:
>For example, the host can request non-default quality of service or real-time service. This important capability enables the support of applications that require some degree of consistent throughput, delay, or jitter. These types of applications are known as **multi media** or **real-time** applications.

[RFC6294 is sceptical](https://datatracker.ietf.org/doc/html/rfc6294):
>There was considerable debate in the IETF about the very purpose of
   the flow label.  Was it to be a handle for fast switching, as in
   CATNIP, or was it to be meaningful to applications and used to
   specify quality of service?  Must it be set by the sending host, or
   could it be set by routers?  Could it be modified en route, or must
   it be delivered with no change?
  Because of these uncertainties, and more urgent work, the flow label
   was consistently ignored by implementors, and today is set to zero in
   almost every IPv6 packet.  In fact, [[RFC2460](https://www.rfc-editor.org/rfc/rfc2460 ""Internet Protocol, Version 6 (IPv6) Specification"")] defined it as
   "experimental and subject to change".  There was considerable
   preliminary work, such as [[Metzler00](https://www.rfc-editor.org/rfc/rfc6294#ref-Metzler00)], [[Conta01a](https://www.rfc-editor.org/rfc/rfc6294#ref-Conta01a ""A proposal for the IPv6 Flow Label Specification"")], [[Conta01b](https://www.rfc-editor.org/rfc/rfc6294#ref-Conta01b ""A model for Diffserv use of the IPv6 Flow Label Specification"")], and
   [[Hagino01](https://www.rfc-editor.org/rfc/rfc6294#ref-Hagino01 ""Socket API for IPv6 flow label field"")].  The ensuing proposed standard "IPv6 Flow Label
   Specification" ([RFC 3697](https://www.rfc-editor.org/rfc/rfc3697)) [[RFC3697](https://www.rfc-editor.org/rfc/rfc3697 ""IPv6 Flow Label Specification"")] intended to clarify this
   situation by providing precise boundary conditions for use of the
   flow label.  **However, this has not proved successful in promoting use
   of the flow label in practice, as a result of which 20 bits are
   unused in every IPv6 packet header.**

On the other hand **Equal-cost multi-path routing** (available in OSPF) is a routing strategy where packet forwarding to a single destination can occur over multiple best paths with equal routing priority. In this algorithm the flow label can help ensure that packets belonging to the same communication session are consistently routed along the same path, contributing to a more predictable handling of traffic.

We can see flow labels in `tcpdump` in the verbose mode and use `ping6` or `scapy` to send test packets.

```
client1$ ping6 -c 1 fd00:3::40
client1$ ping6 -c 1 fd00:3::40
client1$ ping6 -c 1 -F 0x12345 fd00:3::40
client1$ python3 -c 'from scapy.all import IPv6, ICMPv6EchoRequest, send; send(IPv6(dst="fd00:3::40", fl=0x54321)/ICMPv6EchoRequest())'

server1$ tcpdump -nv icmp6 and icmp6[0] == 128
15:35:32.852401 IP6 (flowlabel 0x60096, hlim 64, next-header ICMPv6 (58) payload length: 64) fd00:1::10 > fd00:3::40: [icmp6 sum ok] ICMP6, echo request, id 11, seq 1
15:35:47.049669 IP6 (flowlabel 0x60096, hlim 64, next-header ICMPv6 (58) payload length: 64) fd00:1::10 > fd00:3::40: [icmp6 sum ok] ICMP6, echo request, id 12, seq 1
15:36:00.209578 IP6 (flowlabel 0x12345, hlim 64, next-header ICMPv6 (58) payload length: 64) fd00:1::10 > fd00:3::40: [icmp6 sum ok] ICMP6, echo request, id 13, seq 1
15:36:19.672426 IP6 (flowlabel 0x54321, hlim 64, next-header ICMPv6 (58) payload length: 8) fd00:1::10 > fd00:3::40: [icmp6 sum ok] ICMP6, echo request, id 0, seq 0
```

##### Exercise 1

Verify that you get the same results on our test network.

#### Traffic shaping

We can use `tc` (traffic control) command to control how flows with different labels behave. Before we do that it's useful to understand some of the terminology:

- A **class** in the context of `tc` refers to a category that holds a set of rules and parameters for managing a specific subset of network traffic.
- A **filters** in the context of `tc` are applied to classify packets based on specific criteria and direct them to the appropriate class, allowing for more granular control over the treatment of network traffic.
- **qdisc** (queueing discipline) and it is elementary to understanding traffic control. Whenever the kernel needs to send a packet to an interface, it is **enqueued** to the qdisc configured for that interface. Immediately afterwards, the kernel tries to get as many packets as possible from the qdisc, for giving them to the network adaptor driver.
- **HTB** stands for Hierarchical Token Bucket algorithm. It can be conceptually understood as follows:
	- A token is added to the bucket every *1/r* seconds.
	- The bucket can hold at the most *b* tokens. If a token arrives when the bucket is full, it is discarded.
	- When a packet of _n_ bytes arrives,
	    - if at least _n_ tokens are in the bucket, _n_ tokens are removed from the bucket, and the packet is sent to the network.
	    - if fewer than _n_ tokens are available, no tokens are removed from the bucket, and the packet is considered to be _non-conformant_.
- **netem** (network emulator) is an enhancement of the Linux traffic control facilities that allow one to add delay, packet loss, duplication and more other characteristics to packets outgoing from a selected network interface.

To set 100MBits/s limit for `0x12345` flow label and 200Mbits/s for `0x54321` we should:

1. `tc qdisc add dev eth1 root handle 1: htb default 12` - Adds an HTB qdisc to the root of the `eth1` interface, specifying a default class (`1:12`) for unmatched traffic.
2. `tc class add dev eth1 parent 1: classid 1:1 htb rate 100Mbit quantum 1500` - Adds a class (`1:1`) to the HTB qdisc with a rate limit of 200 Mbps
3. `tc class add dev eth1 parent 1: classid 1:2 htb rate 200mbit quantum 1500` - Adds a class (`1:2`) to the HTB qdisc with a rate limit of 100 Mbps
4. `tc filter add dev eth1 parent 1: protocol ipv6 u32 match ip6 flowlabel 0x54321 0xFFFFF flowid 1:1` - Attaches a filter to the root qdisc, directing traffic with flow label `0x54321` to the class with a rate of 200 Mbps
5. `tc filter add dev eth1 parent 1: protocol ipv6 u32 match ip6 flowlabel 0x12345 0xFFFFF flowid 1:2` - Attaches a filter to the root qdisc, directing traffic with flow label `0x12345` to the class with a rate of 100 Mbps

You can see everything you've added with:
```
$ tc qdisc show dev eth1
qdisc htb 1: root refcnt 11 r2q 10 default 0x12 direct_packets_stat 810445 direct_qlen 1000
$ tc class show dev eth1
class htb 1:1 root prio 0 rate 100Mbit ceil 100Mbit burst 1600b cburst 1600b
class htb 1:2 root prio 0 rate 200Mbit ceil 200Mbit burst 1600b cburst 1600b
$ tc filter show dev eth1
filter parent 1: protocol ipv6 pref 49151 u32 chain 0
filter parent 1: protocol ipv6 pref 49151 u32 chain 0 fh 801: ht divisor 1
filter parent 1: protocol ipv6 pref 49151 u32 chain 0 fh 801::800 order 2048 key ht 801 bkt 0 flowid 1:2 not_in_hw
  match 00012345/000fffff at 0
filter parent 1: protocol ipv6 pref 49152 u32 chain 0
filter parent 1: protocol ipv6 pref 49152 u32 chain 0 fh 800: ht divisor 1
filter parent 1: protocol ipv6 pref 49152 u32 chain 0 fh 800::800 order 2048 key ht 800 bkt 0 flowid 1:1 not_in_hw
  match 00054321/000fffff at 0
```
##### Exercise 2
Run above sequence of 5 command on `server1` (`eth1`) and use `iperf3` on `client1` to verify (against `iperf3` server running on `client2` (`fd00:3::40`)):
- single instance of `iperf3` client saturates full link speed (probably tens of Gbits/s) ``
- single instance of `iperf3` with flow label set to `0x12345`  (use `-L` option) reaches close to 200Mbps
- single instance of `iperf3` with flow label set to `0x54321` reaches close to 100Mbps
##### Exercise 3
Run 2 `iperf3` servers on `client2` on different ports (`--port`).
- verify that running 2 `iperf3` clients in parallel with **same** flow label keeps the total bandwidth under previously set limits 
- verify that running 2 `iperf3` clients in parallel with **different** flow labels makes it possible for both to reach 100Mbps/200Mbps at the same time
##### Exercise 4 (bonus)
Extend the previous exercise by introducing artificial 10% packet loss and observe how it impacts throughput. You can do this on `client1` with `tc qdisc add dev eth0 root netem loss 5%`. Play with the percentage.
### IP Extension headers

Before we understand next 2 extensions, we need to understand _Security Association_. It is a fundamental concept that defines the security parameters and the keying material required for the secure communication between two network entities. SAs are used to negotiate, establish, and manage the security attributes needed for the protection of IP packets. To secure typical, bi-directional communication between two IPsec-enabled systems, a pair of SAs (one in each direction) is required.

Each SA is associated with specific security parameters that define how the IP packets are to be secured. These parameters include:
- **Security Protocol**: Specifies whether the **Authentication Header** (**AH**) or the **Encapsulating Security Payload** (**ESP**) is used.
- **Security Algorithm:** Specifies the cryptographic algorithm used for integrity and/or encryption.
- **Keying Material:** The shared secret key or keys used by the entities to secure the communication.
- **Lifetime:** Defines the duration for which the SA is valid. SAs have a limited lifetime to enhance security.
#### Authentication
```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   | Next Header   |  Payload Len  |          RESERVED             |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                 Security Parameters Index (SPI)               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                    Sequence Number Field                      |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                                                               |
   +                Integrity Check Value-ICV (variable)           |
   |                                                               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```
Authentication header provides authentication, integrity, and optional anti-replay protection for IPv6 packets. The fields are:
- The SPI is an arbitrary 32-bit value that is used by a receiver to identify the SA to which an incoming packet is bound.
- Sequence Number is a counter value that increases by one for each packet sent (per-SA packet sequence number). Doesn't have to be processed.
- ICV is a variable length result of hash function
AH operates in two modes: Transport mode and Tunnel mode.
- **Transport Mode:** Protects the payload of the IPv6 packet.
- **Tunnel Mode:** Protects the entire IPv6 packet, including the original IPv6 header. In tunnel mode, a new IPv6 header is added before the protected packet. The AH header is inserted after the new IPv6 header and before the original payload.
##### Exercise 5
Start a packet capture of icmp6 packets with Authentication header on `server1` with `tcpdump -nvX ah`. On `client1`:
- start ipsec between `client1` and `client2` with `/shared/common/start_ipsec.sh`
- send one icmp packet from to `client2` with payload pattern set to `cafef00d` with `ping fd00:3::40 -c 1 -p cafef00d`
- make sure that you can see:
	- both request and reply
	- both packet have Authentication header
	- that the packets end with a `cafef00d` pattern:
```
16:23:51.771309 IP6 (flowlabel 0x60096, hlim 64, next-header AH (51) payload length: 88) fd00:1::10 > fd00:3::40: AH(length=4(24-bytes),spi=0xc4831e8c,seq=0x2,icv=0x85c3ad955fab6d0a4a8f6d8b): [icmp6 sum ok] ICMP6, echo request, id 15, seq 1
	0x0000:  6006 0096 0058 3340 fd00 0001 0000 0000  `....X3@........
	0x0010:  0000 0000 0000 0010 fd00 0003 0000 0000  ................
	0x0020:  0000 0000 0000 0040 3a04 0000 c483 1e8c  .......@:.......
	0x0030:  0000 0002 85c3 ad95 5fab 6d0a 4a8f 6d8b  ........_.m.J.m.
	0x0040:  8000 31bf 000f 0001 17b7 6865 0000 0000  ..1.......he....
	0x0050:  79c4 0b00 0000 0000 cafe f00d cafe f00d  y...............
	0x0060:  cafe f00d cafe f00d cafe f00d cafe f00d  ................
	0x0070:  cafe f00d cafe f00d cafe f00d cafe f00d  ................
16:23:51.771596 IP6 (flowlabel 0xfe6a5, hlim 62, next-header AH (51) payload length: 88) fd00:3::40 > fd00:1::10: AH(length=4(24-bytes),spi=0xcc53d11f,seq=0x2,icv=0x0cdf7ac6dd037108b386c491): [icmp6 sum ok] ICMP6, echo reply, id 15, seq 1
	0x0000:  600f e6a5 0058 333e fd00 0003 0000 0000  `....X3>........
	0x0010:  0000 0000 0000 0040 fd00 0001 0000 0000  .......@........
	0x0020:  0000 0000 0000 0010 3a04 0000 cc53 d11f  ........:....S..
	0x0030:  0000 0002 0cdf 7ac6 dd03 7108 b386 c491  ......z...q.....
	0x0040:  8100 30bf 000f 0001 17b7 6865 0000 0000  ..0.......he....
	0x0050:  79c4 0b00 0000 0000 cafe f00d cafe f00d  y...............
	0x0060:  cafe f00d cafe f00d cafe f00d cafe f00d  ................
	0x0070:  cafe f00d cafe f00d cafe f00d cafe f00d  ................
```
#### Encapsulation
```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ ----
|               Security Parameters Index (SPI)                 | ^Int.
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ |Cov-
|                      Sequence Number                          | |ered
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ | ----
|                    Payload Data* (variable)                   | |   ^
~                                                               ~ |   |
|                                                               | |Conf.
+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ |Cov-
|               |     Padding (0-255 bytes)                     | |ered*
+-+-+-+-+-+-+-+-+               +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ |   |
|                               |  Pad Length   | Next Header   | v   v
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ ------
|         Integrity Check Value-ICV   (variable)                |
~                                                               ~
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```
The Encapsulating Security Payload protocol offers the same set of services as AH, and also offers confidentiality via payload encryption. 
Let's restart our network in esp mode with:
```
docker compose down && docker compose build && ESP=1 docker compose up -d
```
And start ipsec from `client1` with `/shared/common/start_ipsec.sh`. We can now investigate the SA (a lot of that can also be found in `/etc/swanctl/swanctl.conf`):
```
$ swanctl --list-sas
host-host: #1, ESTABLISHED, IKEv2, b5d23b06411777a2_i* a0a9f16236d492dd_r
  local  'moon.strongswan.org' @ fd00:1::10[500]
  remote 'sun.strongswan.org' @ fd00:3::40[500]
  AES_CBC-128/HMAC_SHA2_256_128/PRF_HMAC_SHA2_256/CURVE_25519
  established 865s ago, reauth in 9413s
  host-host: #1, reqid 1, INSTALLED, TRANSPORT, ESP:AES_GCM_16-128
    installed 865s ago, rekeying in 4157s, expires in 5075s
    in  ce1f8f48,    256 bytes,     4 packets,   775s ago
    out ca082915,    256 bytes,     4 packets,   775s ago
    local  fd00:1::10/128
    remote fd00:3::40/128
```

The most interesting parts we can see here are:
- `host-host` connection defined in config is established and SA is using IKEv2
- the local and remote endpoints
- IKE crypto configuration:
	- encryption algorithm: `AES_CBC-128`
	- authentication algorithm: `HMAC_SHA2_256_128`
	- pseudo random function: `PRF_HMAC_SHA2_256`
	- Diffie-Hellman key exchange algorithm: `CURVE_25519`
- SA encryption algorithm: `AES_GCM_16-128`
- ESP is configured in `TRANSPORT` mode

##### Exercise 6
After starting ipsec in esp mode start capturing all packets on `server1` with `tcpdump -nvX`. Send one ping with custom payload pattern from `client1` to `client2` with `ping fd00:3::40 -c 1 -p cafef00d`. Can you see the `cafef00d` pattern in the captured packets?
##### Homework 1
Build strongswan from source with [save-keys](https://docs.strongswan.org/docs/5.9/plugins/save-keys.html) plugin so that you can capture **and** decode esp packet.
##### Homework 2
Compare outputs of `swanctl --list-sas` in AH mode with ESP mode. 
#### Hop-by-Hop
```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |  Next Header  |  Hdr Ext Len  |                               |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               +
    |                                                               |
    .                                                               .
    .                            Options                            .
    .                                                               .
    |                                                               |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

Hdr Ext Len is a length of the Hop-by-Hop Options header in 8-octet units, not including the first 8 octets.
[rfc2460](https://datatracker.ietf.org/doc/html/rfc2460#section-4.3):
>The Hop-by-Hop Options header is used to carry optional information that must be examined by **every node** along a packet's delivery path.

[rfc7045](https://datatracker.ietf.org/doc/html/rfc7045#section-2.2):
>... it is to be expected that high-performance routers will either ignore it or assign packets containing it to a slow processing path.  Designers planning to use a hop-by-hop option need to be aware of this likely behaviour.

Currently there are two described options:
- **Router Alert Option** serves the purpose of alerting routers along the packet's path to examine the contents of the packet more closely. The Router Alert Option is primarily used by specific network protocols (eg. **Resource Reservation Protocol**) to ensure that routers take special actions or provide additional processing for the packet.
- **Jumbo Payload Option** provides means for specifying payload lengths greater than 65,535 octets by introducing 32bit payload length 
