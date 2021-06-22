FROM centos:7

RUN yum install -y createrepo

RUN yum install -y yum-plugin-copr \
  && yum copr enable -y icon/lfit \
  && yum install -y gnupg22-static

WORKDIR /root/rpm
