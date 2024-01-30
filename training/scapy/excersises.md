
## Scapy

### Overview

Scapy allows users to creating, sending, capturing, and analyzing network packets at various
layers of the network stack, including Ethernet, ARP, IP, TCP, UDP, and more. It's widely used in network
testing, security research, and troubleshooting due to its flexibility and the extensive features it offers.
Additionally, Scapy operates within a Python environment, making it highly extensible and programmable for
custom network applications and protocols.

### Basic Features

1. **Packet Crafting**
   Scapy can create or modify various network packets, their constructors use their names and parameters
   are usually named exactly as in RFC. Most of the frequently used protocols are supported out of the box,
   to use some more sophisticated, one can either 
   For protocols which are not supported, you can use `Raw` layer (provided as `str` or `bytes`), which can contain whatever byte sequence you want.

     ```python
     # Create basic ICMP with isp2 as destination
     ping1 = IP(dst="192.168.1.3") / ICMP()

     # You can also use a known name
     ping2 = IP(dst="isp1") / ICMP()

     # We can modify it to be a ping reply with some raw payload
     ping3 = IP(dst="isp1") / ICMP(type=0) / "This is a ping reply"

     # This works as well
     weird_ping = IP(dst="isp1") / ICMP() / TCP() / IP(dst="127.0.0.1") / ICMP()

     # Shows a short info about the package
     ping1.summary()

     # Shows the whole packet content
     weird_ping.display()

2. **Packet Modification and Analysis**
    We can change packets as any other Python objects, but scapy offers a bunch of useful
    tools made particularly for packet modification.

     ```python
     # Change destination address - like any other field
     # For the given packet we have access to the bottom layer fields
     packet.src = "8.8.8.8"

     # We can check whether the packet has some layer
     packet.haslayer(UDP)

     # Or get some layers
     packet.getlayer(IP)

     # They have also nively overloaded array operator
     packet[Raw] = "Packet's new payload"
     tcp_layer = packet[TCP]

     # 
     packet.remove_payload()

     # But now the packet is invalid - we need to recalculate checksum!
     del packet.chksum
     packet = packet.__class__(bytes(packet))

     # We can also split packet into subpackets
     subpackets = packet.fragment()
     ```

3. **Packet Sending and Receiving**
   It allows also to send the crafted packets using `send` and `sr` (send-receive) methods:
   (You can sniff them on ISP1 and ISP2 with tcpdump)

     ```python
     # You can just send a ping
     send(ping1)

     # Or send and get the answer
     ans1, _ = sr(ping2)

     # Receive just one answer
     ans = sr1(ping2)
     
     # The answer is a list of pairs: (sent_packet -> received_answer)
     # This [0][1] means the first packet's answer
     ans1[0][1].display()

     # The ping is sent and received, but scapy don't see the response
     _, unans1 = sr(weird_ping)

     # We can confirm it checking the first packet on the unanswered list
     unans[0].display()

     # And ping reply shouldn't get any answer at all
     _, unans2 = sr(ping3)
     unans2[0].display()
     ```

4. **Sniffing**
   Scapy can sniff the network traffic for you like tcpdump, and then you can easily
   manipulate them like any other python objects. It doesn't work with `any` interface
   though, so you need to know which interface you need to use.

     ```python
     # Let's capture 4 ICMP packages - you need to know the interface
     packets = sniff(count=4, filter="icmp", iface="eth1")

     # Let's see how these packages look like
     packets.summary()

     # Invesitigate one of the received packages more
     packets[2].display()

     # When you need to respond to some packets, you can use sniffing with handler
     def packet_handler(packet):
         if packet.haslayer(RAW) and b'STUN' in packet[RAW]:
             print("Found some packet with bicycle")

     sniff(filter="icmp", prn=packet_handler, store=0)

     # You can also store packets to the pcap file
     wrpcap('packets.pcap', packets)

     # Or load them
     packets = rdpcap('packets.pcap')
     ```
     ```

5. **Adding custom protocols**
   While most of the frequently used packets are already supported, you can create your own packet classes.

     ```python
     # Create new protcol class
     class MyProtocol(Packet):
         name = "MyProtocol"
         fields_desc = [ShortField("my_field", 0)]

     # Bind it, so the IP layer knows how to represent your protocol
     bind_layers(IP, MyProtocol, proto=253)

     # Create some packet and see how the new layer looks like
     # Pay Attention to IP.proto and MyProtocol.my_field fields
     packet = IP() / MyProtocol(my_field=13)
     packet.display()
     ```


### Excersises

 1. Craft the UDP packets with spoofed source addresses: open a netcat listener for UDP packets on `ISP1` and send scapy crafted UDP packets to `ISP1` as `ISP3` from `ISP2`, `router1` and `internet_client1`.
    Can you see any difference how this packets are handled? Why is that happening?

 2. Run a scapy sniffer on `ISP1` to capture pings going to some `ISP1` network node which does not exist (e.g. `1.0.0.23`), reply to them so the `ping` command can see the incoming replies.
    What should you consider:
    * It would be nice if the `ping` command output looked exactly like pinging a completely valid node
    * You may need to drop some packets with `iptables`
    * It may work only on some nodes (because sniffer works for some particular interface)

 3. Using Scapy you can easily simulate UDP hole punch. You can use the following simple setup:
    * Setup scapy clients on `local_client1`, `local_client2` and `isp3`
    * Setup netcat listeners on `local_client1` and `local_client2` on your favorite ports.
    Then you can try UDP hole punching:
    * On the local clients craft UDP packages with the same port on which you opened listeners - use the `isp3` scapy server as your STUN server so you can see how they are translated, 
    * Try to send UDP packets in one of the directions - NAT firewall should block them
    * Send a bunch of UDP packets in both directions, using the obtained ports

