FROM ubuntu:20.04

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y dpkg-dev apt-utils

WORKDIR /root/deb
