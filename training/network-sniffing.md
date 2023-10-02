# Network Sniffing/Listening And Taking Pcaps

## Prerequisites

- Clone the updated [network training lab](https://github.com/tomaszklak/net-workshop) and use the following command to ensure that everything works properly: `docker compose build && docker compose up -d && ./check_connectivity.sh`.
- Install wireshark on your host system.

This workshop does not require you to have finished the workshop or homework part of the previous network training lab setup workshop.

## OSI Model

- Physical layer - bit synchronization, bit rate control, physical topologies, transmission mode.
- Data Link Layer - framing, physical addressing, error control, flow Control, access control.
- Network Layer - routing, logical addressing.
- Transport Layer - segmentation and reassembly, service point addressing.
- Session Layer - session establishment, maintenance, and termination, synchronization, dialog controller.
- Presentation Layer - translation, encryption/decryption, compression.
- Application Layer - provide protocols that allow software to send and receive information and present meaningful data to users.

VPNs do not really fit into a specific OSI layer and depending on the VPN protocol they fit into different layers, but because NordVPN uses WireGuard, it fits into layer 3 (Network Layer) since it is a secure network tunnel and can encapsulate from this layer upwards.

>Note: The OSI layer is more of an ideal of how things SHOULD be and less so a technical guideline, so real life applications usually don't fall perfectly into a single layer.

>Note: The TCP/IP network model is considered more practical than the OSI model.

## Tools

### Wireshark

Wireshark is a GUI app for sniffing traffic network. It is a GUI alternative to TcpDump, but also often used to read pcaps captured by TcpDump.

The usage of Wireshark is a vast topic and learning it is a skill in itself, but [here](https://cdn.comparitech.com/wp-content/uploads/2019/06/Wireshark-Cheat-Sheet-1.jpg.webp) is a useful cheat sheet for quick reference of the various aspects of using Wireshark.

### TcpDump

TcpDump is the command line app used to capture packets. Even though Wireshark GUI may be more convenient for analyzing the packets, TcpDump can be run on a headless server (like a docker container) making it more convenient for the actual capture.

[Here](https://danielmiessler.com/p/tcpdump/) is a quick TcpDump tutorial with examples that can be used as reference.

>Note TcpDump is available on Unix like systems, but for Windows there is a port which is called [WinDump](https://www.winpcap.org/windump/) which should work the same way as TcpDump and only use a different capture library "under the hood".

### NetCat/SoCat

**netcat** is a utility that uses TCP/IP protocols to write or listen to data on networks. Often called the "Swiss army knife of networking".

It can also be used for port scanning, but **nmap** (which we used in the last network training workshop) is newer and better for that use case.
**socat** is a multi purpose relay tool for connecting sockets. It's often considered a newer alternative to netcat.

[Here's](https://fossies.org/linux/socat/EXAMPLES) a good resource for examples on how to use socat which also shows commands for the netcat alternatives.

We can use one of these tools to create and send data packets which we could sniff with TcpDump or Wireshark.

### Other Tools

[HTTP request echo server](https://echo-http-requests.appspot.com/) - useful for seeing what exactly HTTP request was sent to an external server and echoing it back to the client.

## Workshop

### Setup Echo Server

Let's set up a basic TCP echo server on server1 container using SoCat 

>Note: You may also use NetCat instead of SoCat if you feel more familiar with the former.

Open a terminal on server1.

```
docker exec --privileged -it server1 /bin/bash
```

Install SoCat

```
apt update && apt install -y socat
```

Run socat in TCP listen mode on port 12345. Here `fork,reuseaddr` means that the process will be forked and bound to an address which is in TIME_WAIT state for every new connection on port 12345 (port number chosen randomly) and `EXEC:cat` means that the received data will be piped into the executed command which in this case is `cat`.


```
socat TCP4-LISTEN:12345,fork,reuseaddr EXEC:cat
```

>Note: In case you have any issues with the randomly chosen port, you can use `nmap` to check if the port is already in use and search for a free one.

If you want to make sure the setup works correctly, you can test if the echo server works from loopback by starting another terminal on server1 and running the following command, then sending some random string. If you get back the same string that you sent, then everything is working fine.

```
socat STDIO TCP:127.0.0.1:12345
```

>Note: SoCat echoes the input string back to the terminal. To put it very simply on SoCat if you write a random string like "test" once and then you see the string "test" written twice on separate lines then the echo was successful.

### Setup Data Sending On The Client

Now let's setup the sending of the data on client1

Open another terminal on client1 (run this command on the host machine and not from server1).

```
docker exec -it client1 /bin/bash
```

Install socat and TcpDump.

```
apt update && install -y socat
```

Connect socat to the listener on server1.

```
socat STDIO TCP:192.168.57.22:12345
```
>Note: Here `192.168.57.22` is the IP of server1 and `12345` is port number that matches the one we chose randomly when setting up the echo server.

You can now test this setup by sending a random string like "test" once and after if you see the string "test" written twice on the terminal you're getting the echos back successfully.

### Setup The Network Sniffing

Open a second terminal on client1 (run this command on the host machine and not from client1).

```
docker exec -it client1 /bin/bash
```
Install TcpDump (on most platforms it is already preinstalled).

```
apt install -y tcpdump
```

Find out what interfaces are present on client1 by running the following command.

```
tcpdump -D
```

In the output of the command you should see two interfaces: `lo` (loopback) and `eth0` (ethernet). We can also run the command `route` and see which interface is default (this should also be `eth0`).

Because we're interested in the default ethernet interface, we can run `tcpdump` with the flag `-i eth0` so that we only see network data which is sent to and from ethernet. Also because we are working with a server that has no domain name, we can use the flag `-n` to suppress domain name resolution. And since the payload we're sending back and forth is in ASCII we can use the `-A` flag to see the actual ASCII payload of the packets. Finally we want to save the captured packets by using the `-w <pcap filename>` for viewing them later using Wireshark. Wireshark supports both `pcap` and `pcapng` file formats, but `pcap` is the recommended format for TcpDump.

```
tcpdump -nAi eth0 -w /shared/unique/packet-capture.pcap tcp
```

Now we can send our random string to the echo server once again using `SoCat` and stop `TcpDump`.

>Note: Here `packet-capture.pcap` is a randomly chosen file name for saving the captured network packets, but make sure you use the correct file extension (e.g. `.pcap`) or else you may have issues reading the file. We are using the `/shared/unique/` directory so that we can easily access the file with Wireshark from our host system.

>Note: The file format pcap-ng extends the simple pcap format features with the options to store more capture related information, like extended time stamp precision, capture interface information, capture statistics, mixed link layer types, name resolution information, user comments, etc.

We can view the captured packets by using TcpDump with the `-r <pcap filename>` flag.

```
tcpdump -r /shared/unique/packet-capture.pcap
```

Or we can view the file using Wireshark.

### Open Captured Packet In Wireshark

run Wireshark

```
wireshark
```

File->Open, then find the saved packet capture file in `shared/client1_unique/` directory.

>Note: If you hate light themes, you can use the following command to launch wireshark in dark mode install the dark theme for it `sudo apt install -y adwaita-qt` and then run it using `wireshark -style Adwaita-Dark`.

### Useful Things To Know About Wireshark

You can filter packets by TCP stream. Generally there's no such concept as a "stream" in TCP protocol, but Wireguard adds it by matching against the source and destination IPs. This makes tracing communication by two peers easier.

## Example Network Issues

### Network Issue 1

Run the following command on client1:

```
ip route add 192.168.57.22/32 dev lo
```

Here `192.168.57.22` is the server1 IP address and `lo` is the loopback network interface. This command routes all traffic that is supposed to go to server1 through the ethernet `eth0` interface into the loopback interface which cannot reach server1. Note that you have to install iproute2 package with `apt install -y iproute2` in order to be able to use ip route command.

This issue can be fixed using the following command which deletes the wrong route:

```
ip route del 192.168.57.22/32 dev lo
```

## Homework

### Create And Debug Your Own Network Issue

Requirements:

- Issue must be simulated inside our network lab environment (not on your host machine).
- Show how you traced the network issues in Wireshark, but capture the .pcap using tcpdump.
- This does not have to be difficult or complicated as long as you learn something from it.

Submit this homework to Juozapas Bočkus via Slack direct message containing:

- Explanation of the problem (diagram of the network containing the issue would be nice, but not mandatory).
- Screenshot(s) of the issue being discovered in Wireshark.
- Commands used to create and fix the issue.

### Decrypt HTTPS using wireshark

Follow [this](https://www.comparitech.com/net-admin/decrypt-ssl-with-wireshark/) or [any other](https://www.google.com/search?channel=fs&client=ubuntu-sn&q=decrypt+https+wireshark) tutorial to set up Wireshark to decrypt HTTPS.

In general you have to follow these steps:

>Note: These steps are for Linux platform. Refer to the provided tutorial for directions on how to do the same on Windows and MacOS or feel free to ask for help in the training chat, but the general idea is the same.

Get path for the the ssl-key.log file and populate it by visiting a TLS protected website.

The following command adds the .ssl-key.log file path to the variable `SSLKEYLOGFILE` and updates the terminal so that the variable is visible to the applications in the terminal.

```
echo 'export SSLKEYLOGFILE=~/.ssl-key.log' >> .bashrc && source ~/.bashrc
```
After this command is run, open your browser (best to do it in the same terminal where you ran the previous command) and visit a TLS protected website like google.com or youtube.com. After that you can run `cat $SSLKEYLOGFILE` to check if the file had been populated. If you get an error that the file does not exist or the file is empty, then something is wrong, if it is populated with data then you can continue.

>Note 2: If the ssl-key.log file does not get populated, you can try and use a different browser. Firefox has had bugs reported in the past relating to ssl-key.log generation. Some browsers also support CLI arguments for enabling the key generation.

Add the path to Wireshark preferences

Go to Edit->Preferences->Protocol->TLS and into the field marked (Pre)-Master-Secret log filename add the path to the .ssl-key.log file (you can get it by using the `echo $SSLKEYLOGFILE` command). Now everything should be set up and when you capture some HTTPS data, it should be displayed as adjacent HTTP2 data packets with the field "Decrypted TLS" next to them.

>Note 1: In older version of Wireshark the protocol is called "SSL" and in newer versions it's called "TLS".

>Note 3: Filtering the actual data from Wireshark is a skill on it's own and requires knowledge of various protocols and OS networking concepts that will be covered in future, so for now it is enough if the "Decrypted TLS" tab appears in Wiresharks window when a decrypted HTTP2 packet is selected.

Submit this homework to Juozapas Bočkus via Slack direct message containing:

- Output of cat `cat $SSLKEYLOGFILE` (there will be a lot of info in this file so it is enough to show that it is populated, no need to send all the exact data of the output)
- Screenshot of Wireshark TLS configuration
- Screenshot of the "Decrypted TLS" tab appearing in Wireguard when selecting a decrypted HTTP2 packet.