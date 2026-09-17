#!/usr/bin/env python3
"""Plan revisioned packages and publish them without replacing existing bytes."""

import argparse
from concurrent.futures import ThreadPoolExecutor
import gzip
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parent.parent
FORMATS = ("deb", "rpm")


def read_json(path):
    return json.loads(path.read_text())


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n")


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def check_tag(tag):
    if not isinstance(tag, str) or not re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+", tag):
        raise ValueError("Expected a stable upstream tag such as v0.50.0")


def check_revisions(revisions):
    if set(revisions) != set(FORMATS) or any(
        type(value) is not int or value < 1 for value in revisions.values()
    ):
        raise ValueError("DEB and RPM revisions must be positive integers")


def filename(package, tag, revision):
    return (
        f"{package['name']}-{tag[1:]}-{revision}-php{package['php']}-"
        f"{package['distro']}-{package['arch']}.{package['format']}"
    )


def destination(package, tag):
    if package["format"] == "deb":
        return Path("deb/pool") / tag / package["filename"]
    return Path("rpm") / package["distro"] / tag / package["filename"]


def identity(package, version):
    # The single-PHP RPMs share a name/version/arch across PHP versions.
    return tuple(package[k] for k in ("format", "distro", "name", "arch", "php")) + (version,)


def published_packages(root):
    """Read indices, including legacy RPM Release 1 files without a suffix."""
    published = {}

    def add(fmt, distro, name, arch, version, location, checksum):
        php = re.search(r"-php([0-9]+\.[0-9]+)-", location)
        if not php:
            raise ValueError(f"Cannot identify PHP version in {location}")
        key = (fmt, distro, name, arch, php[1], version)
        published.setdefault(key, set()).add(checksum)

    for path in sorted((root / "deb/dists").glob("*/main/binary-*/Packages")):
        distro = path.parents[2].name
        for stanza in path.read_text().strip().split("\n\n"):
            fields = dict(line.split(": ", 1) for line in stanza.splitlines()
                          if ": " in line and not line.startswith(" "))
            if fields:
                add("deb", distro, fields["Package"], fields["Architecture"],
                    fields["Version"], fields["Filename"], fields["SHA256"])

    ns = {"r": "http://linux.duke.edu/metadata/repo",
          "c": "http://linux.duke.edu/metadata/common"}
    for path in sorted((root / "rpm").glob("*/repodata/repomd.xml")):
        distro = path.parents[1].name
        repomd = ET.parse(path)
        location = repomd.find("r:data[@type='primary']/r:location", ns).attrib["href"]
        primary = path.parents[1] / location
        with gzip.open(primary) as stream:
            packages = ET.parse(stream)
        for package in packages.findall("c:package", ns):
            version = package.find("c:version", ns).attrib
            checksum = package.find("c:checksum", ns)
            if checksum.attrib["type"] != "sha256":
                raise ValueError(f"Expected SHA256 checksums in {primary}")
            add("rpm", distro, package.findtext("c:name", namespaces=ns),
                package.findtext("c:arch", namespaces=ns),
                f"{version['ver']}-{version['rel']}",
                package.find("c:location", ns).attrib["href"], checksum.text)
    return published


def output(name, value):
    print(f"{name}={value}")
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a") as stream:
            stream.write(f"{name}={value}\n")


def plan(root, tag):
    check_tag(tag)
    revisions = {}
    for fmt in FORMATS:
        path = root / f"build/revisions/{fmt}.json"
        records = read_json(path)
        if tag not in records:
            raise ValueError(f"Add {tag} to {path.relative_to(root)} before building")
        revisions[fmt] = records[tag]
    check_revisions(revisions)
    published = published_packages(root)
    for key in published:
        match = re.fullmatch(re.escape(tag[1:]) + r"-([0-9]+)", key[-1])
        if match and int(match[1]) > revisions[key[0]]:
            raise ValueError(f"{key[0]} revision {revisions[key[0]]} is older than published {key[-1]}")

    env = dict(os.environ, **{f"{fmt.upper()}_REVISION": str(rev) for fmt, rev in revisions.items()})
    candidates = subprocess.check_output(
        ["bash", str(root / "build/fpm.sh"), tag, "--list"], env=env, text=True
    )
    selected = []
    skipped = dict.fromkeys(FORMATS, 0)
    for line in candidates.splitlines():
        package = dict(zip(("format", "distro", "arch", "php", "name", "filename"),
                           line.split("\t"), strict=True))
        fmt = package["format"]
        expected = filename(package, tag, revisions[fmt])
        if package["filename"] != expected:
            raise ValueError(f"Unexpected candidate filename: {package['filename']}")
        if identity(package, f"{tag[1:]}-{revisions[fmt]}") in published:
            skipped[fmt] += 1
        else:
            selected.append(package)
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
    manifest = {"schema": 1, "tag": tag, "revisions": revisions,
                "source_commit": commit, "packages": selected}
    write_json(root / "build/plan.json", manifest)
    (root / "build/selected-packages.txt").write_text("".join(p["filename"] + "\n" for p in selected))
    for fmt in FORMATS:
        count = sum(p["format"] == fmt for p in selected)
        print(f"{fmt.upper()} revision {revisions[fmt]}: build {count}, already published {skipped[fmt]}")
        output(f"{fmt}_revision", revisions[fmt])
    output("has_packages", str(bool(selected)).lower())
    return manifest


def validate_manifest(manifest):
    if manifest.get("schema") != 1:
        raise ValueError("Unsupported package manifest schema")
    check_tag(manifest["tag"])
    check_revisions(manifest["revisions"])
    if not re.fullmatch(r"[0-9a-f]{40}", manifest["source_commit"]):
        raise ValueError("Invalid source commit")
    seen = set()
    for package in manifest["packages"]:
        fmt = package["format"]
        if fmt not in FORMATS:
            raise ValueError(f"Unknown package format: {fmt}")
        for field in ("name", "distro", "arch", "php"):
            if not re.fullmatch(r"[a-z0-9][a-z0-9._+-]*", package[field]):
                raise ValueError(f"Invalid package {field}")
        expected = filename(package, manifest["tag"], manifest["revisions"][fmt])
        if package["filename"] != expected or expected in seen:
            raise ValueError(f"Invalid or duplicate filename: {package['filename']}")
        seen.add(expected)


def finish_manifest(root):
    manifest = read_json(root / "build/plan.json")
    validate_manifest(manifest)
    dist = root / "build/dist"
    dist.mkdir(exist_ok=True)
    expected = {p["filename"] for p in manifest["packages"]}
    actual = {p.name for fmt in FORMATS for p in dist.glob(f"*.{fmt}")}
    if expected != actual:
        raise ValueError(f"Build output differs from plan: missing {expected - actual}, extra {actual - expected}")
    for package in manifest["packages"]:
        package["sha256"] = sha256(dist / package["filename"])
    write_json(dist / "manifest.json", manifest)


def load_artifacts(artifacts):
    manifest = read_json(artifacts / "manifest.json")
    validate_manifest(manifest)
    for package in manifest["packages"]:
        if sha256(artifacts / package["filename"]) != package["sha256"]:
            raise ValueError(f"Checksum mismatch: {package['filename']}")
    return manifest


def stage(root, artifacts, fmt, source_commit):
    manifest = load_artifacts(artifacts)
    if manifest["source_commit"] != source_commit:
        raise ValueError("Artifact source commit does not match the build workflow")
    published = published_packages(root)
    packages = [p for p in manifest["packages"] if p["format"] == fmt]
    # Validate the entire batch before copying anything.
    for package in packages:
        version = f"{manifest['tag'][1:]}-{manifest['revisions'][fmt]}"
        checksums = published.get(identity(package, version), set())
        if checksums and checksums != {package["sha256"]}:
            raise ValueError(f"Published identity has different bytes: {package['filename']}; bump the revision")
        dest = root / destination(package, manifest["tag"])
        if dest.exists() and sha256(dest) != package["sha256"]:
            raise ValueError(f"Refusing to overwrite {dest}; bump the revision")
    for package in packages:
        dest = root / destination(package, manifest["tag"])
        dest.parent.mkdir(parents=True, exist_ok=True)
        if not dest.exists():
            shutil.copyfile(artifacts / package["filename"], dest)
    output("tag", manifest["tag"])
    output("revision", manifest["revisions"][fmt])
    output("has_packages", str(bool(packages)).lower())


def upload_object(source, key, checksum, bucket, endpoint):
    command = ["aws", "s3api", "--endpoint-url", endpoint]
    result = subprocess.run(command + [
        "put-object", "--bucket", bucket, "--key", key, "--body", str(source),
        "--if-none-match", "*",
    ], text=True, capture_output=True)
    if result.returncode:
        if "PreconditionFailed" not in result.stderr and "ConditionalRequestConflict" not in result.stderr:
            raise RuntimeError(result.stderr)
        # A retry may encounter an already uploaded object. Compare actual bytes;
        # ETags are not necessarily content hashes (e.g. multipart uploads).
        with tempfile.TemporaryDirectory() as tmp:
            previous = Path(tmp) / "package"
            subprocess.run(command + ["get-object", "--bucket", bucket, "--key", key,
                                      str(previous)], check=True, stdout=subprocess.DEVNULL)
            if sha256(previous) != checksum:
                raise ValueError(f"Published object has different bytes: {key}; bump the revision")
    print(f"Verified package object: {key}")


def upload(artifacts, fmt, bucket, endpoint):
    manifest = load_artifacts(artifacts)
    objects = []
    for package in manifest["packages"]:
        if package["format"] != fmt:
            continue
        source = artifacts / package["filename"]
        keys = [destination(package, manifest["tag"]).as_posix()]
        if fmt == "deb":
            # dpkg-scanpackages refers to the distribution symlinks, which use
            # an underscore before the architecture. Publish both URLs.
            alias = package["filename"].removesuffix(f"-{package['arch']}.deb") + f"_{package['arch']}.deb"
            keys.append(f"deb/pools/{package['distro']}/{manifest['tag']}/{alias}")
        objects.extend((source, key, package["sha256"], bucket, endpoint) for key in keys)
    with ThreadPoolExecutor(max_workers=8) as executor:
        list(executor.map(lambda args: upload_object(*args), objects))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("plan").add_argument("tag")
    commands.add_parser("manifest")
    for name in ("stage", "upload"):
        sub = commands.add_parser(name)
        sub.add_argument("format", choices=FORMATS)
        sub.add_argument("--artifacts", type=Path, default=Path("artifacts/packages"))
        if name == "stage":
            sub.add_argument("--source-commit", required=True)
        else:
            sub.add_argument("--bucket", required=True)
            sub.add_argument("--endpoint", required=True)
    args = parser.parse_args()
    try:
        if args.command == "plan":
            plan(ROOT, args.tag)
        elif args.command == "manifest":
            finish_manifest(ROOT)
        elif args.command == "stage":
            stage(ROOT, args.artifacts, args.format, args.source_commit)
        else:
            upload(args.artifacts, args.format, args.bucket, args.endpoint)
    except (ValueError, KeyError, OSError, RuntimeError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Error: {error}\n")


if __name__ == "__main__":
    main()
