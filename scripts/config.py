#!/usr/bin/env python3
#
#  config.py
#  MacJi
#
#  Created: 2026-11-26
#  Shared values for MacJi's Python scripts; mirrors scripts/config.sh (check.sh keeps them in sync).
#

####################
#### Project identity
### The bundle ID and certificate name are permanent after the first release: the Accessibility
### grant and the login item stay valid only while both stay the same.

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP_NAME = "MacJi"
SCHEME = "MacJi"
PROJECT = ROOT / "MacJi.xcodeproj"
BUNDLE_ID = "io.github.mayank-devac.macji"
SIGNING_IDENTITY = "MacJi Release"
SPARKLE_KEY_ACCOUNT = "macji"

#### Keep in sync with scripts/config.sh and Config/Base.xcconfig.
##################

####################
#### Paths, repositories and the update feed
### Release archives are attached to GitHub Releases of the source repository; the appcast lives
### in the small macji-dist repository so publishing a feed never needs a push to the source repo.

DERIVED_DATA = ROOT / ".build/DerivedData"
RELEASE_DIR = ROOT / ".build/release"
XCCONFIG = ROOT / "Config/Base.xcconfig"
INFO_PLIST = ROOT / "MacJi/Resources/Info.plist"
ENTITLEMENTS = ROOT / "MacJi/Resources/MacJi.entitlements"
CHANGELOG = ROOT / "CHANGELOG.md"
DIST_DIR = ROOT / "dist"
SOURCE_REPO = "mayank-devac/macji"
DIST_REPO = "mayank-devac/macji-dist"
FEED_URL = f"https://raw.githubusercontent.com/{DIST_REPO}/main/appcast.xml"
PLACEHOLDER_PUBLIC_KEY = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
MINIMUM_SYSTEM = "14.6"

##################
