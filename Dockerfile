FROM ubuntu:22.04

RUN apt update && apt install -y ruby iputils-ping net-tools nmap curl
