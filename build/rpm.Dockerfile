FROM centos:7

RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

RUN yum update -y

RUN yum install -y createrepo

RUN yum install -y yum-plugin-copr \
  && yum copr enable -y icon/lfit \
  && yum install -y gnupg22-static

WORKDIR /root/rpm
