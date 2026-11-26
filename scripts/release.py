#!/usr/bin/env python3
#
#  release.py
#  MacJi
#
#  Created: 2026-11-26
#  Builds a signed MacJi release: certificate and key checks → version bump → unsigned archive →
#  sign with "MacJi Release" → verify → zip + DMG → EdDSA sign → appcast → verify-update.
#  Stops on the first failure. Never notarizes, pushes, tags or publishes: it prints those commands.
#  Ported from Octopus: scripts/beta-release.py
#
####################
#### Usage
### scripts/release.py patch|minor|major      bump, build, sign, package, update dist/appcast.xml
### scripts/release.py patch --dry-run        everything except changing tracked files (output only)
### scripts/release.py --allow-key-rotation   accept a new EdDSA key OR a new certificate (never both)
# Example: scripts/release.py patch --dry-run
# Output goes to .build/release/<version>/. See docs/RELEASING.md for the one-time setup.
##################

import argparse
import hashlib
import json
import plistlib
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from email.utils import format_datetime
from pathlib import Path
from xml.etree import ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parent))
import config  # noqa: E402

SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", SPARKLE_NS)
IDENTITY_FILE = config.DIST_DIR / "signing-identity.json"


class ReleaseError(Exception):
    pass


def step(message):
    print(f"› {message}", flush=True)


def run(*args, capture=False):
    result = subprocess.run([str(a) for a in args], cwd=config.ROOT, text=True, capture_output=True)
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip().splitlines()[-5:]
        raise ReleaseError(f"{Path(str(args[0])).name} failed:\n  " + "\n  ".join(detail))
    return result.stdout if capture else None


####################
#### Preflight: certificate, EdDSA key, identity rotation
### The certificate and the EdDSA key are what keep updates working: Sparkle trusts a new key only
### through a matching code signature, and a new certificate only through a matching key.
# So one of the two may change in a release, never both (dist/signing-identity.json remembers them).


def check_certificate():
    identities = run("security", "find-identity", "-p", "codesigning", capture=True)
    if f'"{config.SIGNING_IDENTITY}"' not in identities:
        raise ReleaseError(f'Certificate "{config.SIGNING_IDENTITY}" is not in your Keychain. '
                           "Create it once as described in docs/RELEASING.md.")


def sparkle_tool(name):
    matches = sorted((config.DERIVED_DATA / "SourcePackages/artifacts").glob(f"sparkle/*/bin/{name}"))
    if not matches:
        raise ReleaseError(f"Sparkle's {name} was not found. Run ./build.sh once so packages resolve.")
    return matches[0]


def check_public_key():
    configured = plistlib.loads(config.INFO_PLIST.read_bytes()).get("SUPublicEDKey", "")
    if configured == config.PLACEHOLDER_PUBLIC_KEY:
        raise ReleaseError("SUPublicEDKey in Info.plist is still the placeholder. See docs/RELEASING.md → EdDSA key.")
    keychain = run(sparkle_tool("generate_keys"), "--account", config.SPARKLE_KEY_ACCOUNT, "-p", capture=True).strip()
    if keychain != configured:
        raise ReleaseError("The Keychain's Sparkle public key differs from SUPublicEDKey in Info.plist.")
    return configured


def check_rotation(public_key, leaf_hash, allow_rotation):
    if not IDENTITY_FILE.exists():
        return
    previous = json.loads(IDENTITY_FILE.read_text())
    key_changed = previous["ed_public_key"] != public_key
    cert_changed = previous["certificate_leaf_sha1"] != leaf_hash
    if key_changed and cert_changed:
        raise ReleaseError("Both the EdDSA key and the signing certificate changed. Existing users could never "
                           "update again. Restore one of them.")
    if (key_changed or cert_changed) and not allow_rotation:
        changed = "EdDSA key" if key_changed else "signing certificate"
        raise ReleaseError(f"The {changed} changed since the last release. If that is intended, rerun with "
                           "--allow-key-rotation (and change nothing else this release).")

#### A first release has no identity file yet; it records one.
##################


####################
#### Version


def read_version():
    text = config.XCCONFIG.read_text()
    version = re.search(r"^MARKETING_VERSION = (\S+)$", text, re.M)
    build = re.search(r"^CURRENT_PROJECT_VERSION = (\d+)$", text, re.M)
    if not version or not build:
        raise ReleaseError("Cannot read the version from Config/Base.xcconfig.")
    return version.group(1), build.group(1)


def next_version(kind, version, build):
    major, minor, patch = map(int, version.split("."))
    bumped = {"major": (major + 1, 0, 0), "minor": (major, minor + 1, 0), "patch": (major, minor, patch + 1)}[kind]
    return ".".join(map(str, bumped)), str(int(build) + 1)

##################


####################
#### Build, sign and verify
### The archive is built unsigned; every nested bundle and helper is then signed inside-out with the
### release certificate, and the app last with MacJi's entitlements and the hardened runtime.
# A self-signed certificate has no Team ID, so the hardened runtime's library validation would refuse
# to load Sparkle; MacJi.entitlements disables library validation for exactly that reason.


def archive(output, version, build):
    archive_path = output / f"{config.APP_NAME}.xcarchive"
    run("xcodebuild", "-project", config.PROJECT, "-scheme", config.SCHEME, "-configuration", "Release",
        "-destination", "generic/platform=macOS", "-derivedDataPath", config.DERIVED_DATA,
        "-archivePath", archive_path, "-onlyUsePackageVersionsFromResolvedFile", "archive",
        "CODE_SIGNING_ALLOWED=NO", "ONLY_ACTIVE_ARCH=NO", "ARCHS=arm64 x86_64",
        f"MARKETING_VERSION={version}", f"CURRENT_PROJECT_VERSION={build}", "SWIFT_SERIALIZE_DEBUGGING_OPTIONS=NO")
    app = archive_path / f"Products/Applications/{config.APP_NAME}.app"
    if not app.is_dir():
        raise ReleaseError(f"The archive has no {config.APP_NAME}.app.")
    return app


def nested_code(app):
    frameworks = app / "Contents/Frameworks"
    bundles = [p for p in frameworks.rglob("*") if p.suffix in {".xpc", ".app", ".framework"} and not p.is_symlink()]
    # Loose helpers such as Sparkle's Autoupdate; a framework's own binary is signed with its bundle.
    helpers = [p for p in frameworks.rglob("*") if p.is_file() and not p.is_symlink() and p.parent.name == "B"
               and p.stat().st_mode & 0o111 and p.name != p.parents[2].stem]
    return sorted(set(bundles + helpers), key=lambda p: len(p.parts), reverse=True)


def sign(app):
    for code in nested_code(app):
        run("codesign", "--force", "--sign", config.SIGNING_IDENTITY, "--options", "runtime", "--timestamp=none",
            "--preserve-metadata=entitlements", code)
    run("codesign", "--force", "--sign", config.SIGNING_IDENTITY, "--options", "runtime", "--timestamp=none",
        "--entitlements", config.ENTITLEMENTS, app)


def verify_signature(app):
    run("codesign", "--verify", "--deep", "--strict", app)
    for code in [app] + nested_code(app):
        details = subprocess.run(["codesign", "--display", "--verbose=4", str(code)], text=True, capture_output=True).stderr
        if f"Authority={config.SIGNING_IDENTITY}\n" not in details:
            raise ReleaseError(f"{code.name} is not signed by {config.SIGNING_IDENTITY}.")
        if not re.search(r"^TeamIdentifier=not set$", details, re.M):
            raise ReleaseError(f"{code.name} carries an Apple Team ID; release builds must not.")
    requirement = subprocess.run(["codesign", "--display", "-r-", str(app)], text=True, capture_output=True)
    leaf = re.search(r'certificate leaf = H"([0-9a-f]+)"', requirement.stdout + requirement.stderr)
    if not leaf:
        raise ReleaseError("The designated requirement is not pinned to the release certificate.")
    executable = app / "Contents/MacOS" / config.APP_NAME
    if re.search(r"/Users/[^/\s]+/", run("strings", executable, capture=True)):
        raise ReleaseError("The executable contains a local /Users/ path. Inspect it before publishing.")
    return leaf.group(1)

#### The pinned leaf certificate is what keeps the Accessibility grant valid across updates.
##################


####################
#### Package, EdDSA-sign and describe the update
### The DMG stays unsigned on purpose. macOS assesses a signed disk image when it is opened, and an
### unnotarized one is blocked, so a signed DMG costs the user a second "Open Anyway" before the
### app's own. The app inside is signed and is what Gatekeeper, Sparkle and Accessibility check.


def package(app, output, version):
    zip_path = output / f"{config.APP_NAME}-{version}.zip"
    run("ditto", "-c", "-k", "--norsrc", "--noextattr", "--keepParent", app, zip_path)
    staging = output / "dmg"
    staging.mkdir()
    run("ditto", app, staging / app.name)
    (staging / "Applications").symlink_to("/Applications")
    dmg_path = output / f"{config.APP_NAME}-{version}.dmg"
    run("hdiutil", "create", "-volname", config.APP_NAME, "-srcfolder", staging, "-format", "UDZO", "-ov", dmg_path)
    shutil.rmtree(staging)
    return zip_path, dmg_path


def sign_update(zip_path):
    # Error output is suppressed: malformed-key diagnostics can contain key material.
    result = subprocess.run([str(sparkle_tool("sign_update")), "--account", config.SPARKLE_KEY_ACCOUNT, "-p", str(zip_path)],
                            text=True, capture_output=True)
    if result.returncode != 0 or not result.stdout.strip():
        raise ReleaseError("sign_update failed. Check Keychain access to the Sparkle key; no key was exported.")
    return result.stdout.strip()


def release_notes(heading):
    match = re.search(rf"^## \[{re.escape(heading)}\][^\n]*\n(.*?)(?=^## \[|\Z)", config.CHANGELOG.read_text(), re.S | re.M)
    notes = match.group(1).strip() if match else ""
    if not notes:
        raise ReleaseError(f"CHANGELOG.md has no notes under [{heading}]. Write them, then rerun.")
    return notes


def write_appcast(template, destination, version, build, zip_path, signature, notes):
    tree = ET.parse(template)
    channel = tree.getroot().find("channel")
    for item in channel.findall("item"):
        if int(item.findtext(f"{{{SPARKLE_NS}}}version", "0")) >= int(build):
            raise ReleaseError(f"The appcast already has build {build} or newer.")
    item = ET.Element("item")
    ET.SubElement(item, "title").text = f"{config.APP_NAME} {version}"
    ET.SubElement(item, "pubDate").text = format_datetime(datetime.now(timezone.utc), usegmt=True)
    ET.SubElement(item, f"{{{SPARKLE_NS}}}version").text = build
    ET.SubElement(item, f"{{{SPARKLE_NS}}}shortVersionString").text = version
    ET.SubElement(item, f"{{{SPARKLE_NS}}}minimumSystemVersion").text = config.MINIMUM_SYSTEM
    ET.SubElement(item, "description", {f"{{{SPARKLE_NS}}}format": "plain-text"}).text = notes
    ET.SubElement(item, "enclosure", {
        "url": f"https://github.com/{config.SOURCE_REPO}/releases/download/v{version}/{zip_path.name}",
        "length": str(zip_path.stat().st_size), "type": "application/octet-stream",
        f"{{{SPARKLE_NS}}}edSignature": signature})
    position = list(channel).index(channel.find("language")) + 1
    channel.insert(position, item)
    ET.indent(tree, space="  ")
    tree.write(destination, encoding="utf-8", xml_declaration=True)

##################


def main():
    parser = argparse.ArgumentParser(description="Build a signed MacJi release (never publishes).")
    parser.add_argument("bump", choices=["major", "minor", "patch"])
    parser.add_argument("--dry-run", action="store_true", help="change no tracked file; write output only")
    parser.add_argument("--allow-key-rotation", action="store_true")
    args = parser.parse_args()

    step("Checking certificate and EdDSA key")
    check_certificate()
    public_key = check_public_key()
    dirty = run("git", "status", "--porcelain", capture=True).strip()
    if dirty and not args.dry_run:
        raise ReleaseError("Commit or stash your changes first; a release is built from a clean tree.")

    version, build = next_version(args.bump, *read_version())
    notes = release_notes("Unreleased")
    output = config.RELEASE_DIR / version
    if output.exists():
        raise ReleaseError(f"{output} already exists. Remove it (scripts/clean.sh) or choose another version.")
    output.mkdir(parents=True)
    if not args.dry_run:
        run(config.ROOT / "scripts/bump-version.sh", args.bump)

    step(f"Archiving {config.APP_NAME} {version} ({build}) unsigned")
    app = archive(output, version, build)
    step(f"Signing with {config.SIGNING_IDENTITY}")
    sign(app)
    leaf_hash = verify_signature(app)
    check_rotation(public_key, leaf_hash, args.allow_key_rotation)
    step("Packaging zip and DMG")
    zip_path, dmg_path = package(app, output, version)
    step("Signing the update with EdDSA and writing the appcast")
    signature = sign_update(zip_path)
    appcast = output / "appcast.xml"
    write_appcast(config.DIST_DIR / "appcast.xml", appcast, version, build, zip_path, signature, notes)
    run("swift", config.ROOT / "scripts/verify-update.swift", zip_path, appcast, public_key)
    sums = "".join(f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.name}\n" for p in (zip_path, dmg_path))
    (output / "SHA256SUMS.txt").write_text(sums)
    (output / "notes.md").write_text(notes + "\n")
    if not args.dry_run:
        shutil.copyfile(appcast, config.DIST_DIR / "appcast.xml")
        IDENTITY_FILE.write_text(json.dumps({"certificate_leaf_sha1": leaf_hash, "ed_public_key": public_key}, indent=2) + "\n")

    rel = output.relative_to(config.ROOT)
    print(f"✓ {config.APP_NAME} {version} ({build}) is ready in {rel}. Nothing was published.\n")
    print("Publish it yourself when you have tested the DMG:")
    if not args.dry_run:
        print(f'  git add Config/Base.xcconfig CHANGELOG.md dist && git commit -m "Release {version}"')
    print(f"  git tag v{version} && git push origin v{version}")
    print(f"  gh release create v{version} {rel}/{zip_path.name} {rel}/{dmg_path.name} {rel}/SHA256SUMS.txt "
          f"--repo {config.SOURCE_REPO} --title \"{config.APP_NAME} {version}\" --notes-file {rel}/notes.md")
    print("  git push origin HEAD:main      (publishes dist/appcast.xml; the feed goes live last)")


if __name__ == "__main__":
    try:
        main()
    except (ReleaseError, OSError, ET.ParseError, KeyError, ValueError) as error:
        print(f"✗ Release stopped: {error}", file=sys.stderr)
        sys.exit(1)
