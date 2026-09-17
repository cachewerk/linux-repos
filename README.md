# Relay packages and repositories for Linux

For detailed installations instruction see [relay.so](https://relay.so/docs/installation).

## Publishing packages

The **Build packages** action takes an upstream Relay tag, such as `v0.50.0`.
Packaging revisions are recorded separately for each format in
[`build/revisions/deb.json`](build/revisions/deb.json) and
[`build/revisions/rpm.json`](build/revisions/rpm.json), keyed by upstream tag.
Both files must contain the tag; revisions are positive integers.

- For a new Relay release, add its tag to both files with revision `1`.
- For a packaging fix, increment the affected format's revision for that tag.
  A shared change affecting both formats requires both revisions to increase.
- Adding a distribution or PHP target can use the existing revision: only
  missing packages are built. Existing packages are skipped even if packaging
  code changed, so bump the revision when those packages need the change.
- Commit the revision changes before running the action. Revisions are shared
  across distributions, architectures, and PHP variants within each format.

DEBs use `Version: 0.50.0-1`; RPMs use `Version: 0.50.0` and `Release: 1`.
Filenames also include the revision. Upstream downloads still use `v0.50.0`.
When adopting this scheme, existing unsuffixed DEBs advance to revision `1`.
Existing RPMs already have Release `1`, despite their old filenames, and are
skipped until the RPM revision increases to `2`.

The action prints a build/skip count for each format. A rerun with no missing
packages is a successful no-op. To preview the plan locally without downloading
or building packages (Python 3.10+ and Bash are required):

```bash
python3 build/packages.py plan v0.50.0
```

The artifact includes `manifest.json`, recording the upstream tag, revisions,
build commit, filenames, and SHA256 checksums. **Update repositories** consumes
that manifest and updates only formats with built packages. Automatic publishing
is restricted to builds from this repository's default branch; branch builds
produce reviewable artifacts without publishing them.

Published package files are immutable. Publication rejects conflicting versions
and uses conditional R2 writes to prevent overwrites, while allowing identical
retries. Old revisions and their download URLs are retained. If publication
fails partway through, rerun **Update repositories** for the original build so
it can finish publishing the same artifacts; rebuilding may produce different
bytes. Repository metadata is uploaded after the package files.

Run the packaging regression tests with:

```bash
python3 -m unittest discover -s tests -v
```

## Using APT (Debian, Ubuntu)

```bash
curl -fsSL "https://repos.r2.relay.so/key.gpg" | sudo apt-key add -
sudo add-apt-repository "deb https://repos.r2.relay.so/deb $(lsb_release -cs) main"

sudo apt install php-relay      # default php version
sudo apt install php8.1-relay   # specific php version
sudo apt install lsphp81-relay  # for litespeed setups
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
yum install lsphp81-relay    # for litespeed setups
```

### Amazon Linux 2

```bash
yum-config-manager --disable cachewerk-el
yum-config-manager --enable cachewerk-el7
```

## Dependencies 

If the operating system cannot fill the dependencies (especially `hiredis` or `ck`) check out the how the [Docker examples](https://github.com/cachewerk/relay/tree/main/docker) are installing the packages, or alternatively install them from source:

```bash
# Install hiredis
curl -L https://github.com/redis/hiredis/archive/refs/tags/v1.2.0.tar.gz | tar -xzC /tmp \
  && USE_SSL=1 make -C /tmp/hiredis-1.2.0 install

# Install Concurrency Kit
curl -L https://github.com/concurrencykit/ck/archive/refs/tags/0.7.2.tar.gz | tar -xzC /tmp \
  && cd /tmp/ck-0.7.2 && ./configure && make -j$(nproc) && make install
```
