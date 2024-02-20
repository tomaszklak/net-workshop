FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt install -y iputils-ping net-tools nmap curl tcpdump iproute2 iperf3 nftables iptables traceroute vim build-essential python3-dev python3-pip libnetfilter-queue-dev conntrack libpcap-dev python3-scapy
RUN python3 -m pip install NetfilterQueue scapy
WORKDIR /shared
ENTRYPOINT [ "./entrypoint.sh" ]
