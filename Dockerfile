FROM ubuntu:22.04

ARG IPV4_EXCERCISE

RUN apt update && apt install -y ruby iputils-ping net-tools nmap curl tcpdump iproute2 socat iperf3 iptables traceroute

ENV IPV4_EXCERCISE=$IPV4_EXCERCISE
