# Relay packages and repositories for Linux

For detailed installations instruction see [relay.so](https://relay.so/docs/installation).

## Using APT (Debian, Ubuntu)

```bash
curl -s https://cachewerk.s3.amazonaws.com/repos/key.gpg | sudo apt-key add -
sudo add-apt-repository "deb https://cachewerk.s3.amazonaws.com/repos/deb $(lsb_release -cs) main"
sudo apt update

sudo apt install php-relay     # default php version
sudo apt install php8.1-relay  # specific php version
```

## Using YUM (CentOS, RHEL)

```bash
curl -s -o /etc/yum.repos.d/cachewerk.repo "https://cachewerk.s3.amazonaws.com/repos/rpm/el.repo"

yum install relay-php        # single php version
yum install php81-php-relay  # multiple php versions
```

### Amazon Linux 2

```bash
yum-config-manager --disable cachewerk-el
yum-config-manager --enable cachewerk-el7
```
