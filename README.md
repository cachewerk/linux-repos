# Relay packages and repositories for Linux

For detailed installations instruction see [relay.so](https://relay.so/docs/installation).

## Using APT (Debian, Ubuntu)

```bash
curl -fsSL "https://repos.r2.relay.so/key.gpg" | sudo apt-key add -
sudo add-apt-repository "deb https://repos.r2.relay.so/deb $(lsb_release -cs) main"

sudo apt install php-relay     # default php version
sudo apt install php8.1-relay  # specific php version
```

If `apt-key` or `add-apt-repository` are deprecated or not available, use:

```bash
curl -fsSL "https://repos.r2.relay.so/key.gpg" | sudo gpg --dearmor -o "/usr/share/keyrings/cachewerk.gpg"
echo "deb [signed-by=/usr/share/keyrings/cachewerk.gpg] https://repos.r2.relay.so/deb $(lsb_release -sc) main" \
  | sudo tee "/etc/apt/sources.list.d/cachewerk.list" > /dev/null
sudo apt-get update
```

## Using YUM (CentOS, RHEL, Rocky Linux)

```bash
curl -s -o "/etc/yum.repos.d/cachewerk.repo" "https://repos.r2.relay.so/rpm/el.repo"

yum install relay-php        # single php version
yum install php81-php-relay  # multiple php versions
```

### Amazon Linux 2

```bash
yum-config-manager --disable cachewerk-el
yum-config-manager --enable cachewerk-el7
```
