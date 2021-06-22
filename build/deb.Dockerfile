FROM ubuntu:20.04

RUN apt update
RUN apt upgrade -y
RUN apt install -y dpkg-dev apt-utils

WORKDIR /root/deb
