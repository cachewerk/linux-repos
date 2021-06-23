# Relay packages and repositories for Linux

For detailed installations instruction see [relaycache.com](https://relaycache.com/docs/installation).

## Using APT (Debian/Ubuntu)

```bash
curl -s https://cachewerk.s3.amazonaws.com/repos/key.gpg | sudo apt-key add -
sudo add-apt-repository "deb https://cachewerk.s3.amazonaws.com/repos/deb $(lsb_release -cs) main"
sudo apt update

sudo apt install php-relay     # default php version
sudo apt install php8.0-relay  # specific php version
```

## Using YUM (CentOS)

```bash
curl -s -o /etc/yum.repos.d/cachewerk.repo "https://cachewerk.s3.amazonaws.com/repos/rpm/el.repo"

yum install relay-php        # single php version
yum install php80-php-relay  # multiple php versions
```
