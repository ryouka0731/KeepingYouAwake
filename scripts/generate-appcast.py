#!/usr/bin/env python3
"""Generate a Sparkle appcast.xml from this repo's GitHub Releases.

Usage:
    SPARKLE_ED_PRIVATE_KEY=<base64> python3 scripts/generate-appcast.py [out.xml]

If SPARKLE_ED_PRIVATE_KEY is unset, entries are emitted *without*
sparkle:edSignature attributes. Sparkle 2.x will refuse to install
unsigned updates, which is the safe default — until the secret is
configured, the appcast simply won't drive any installs.

Requires:
    - `gh` CLI authenticated (provided automatically inside GitHub
      Actions via env $GH_TOKEN).
    - `sign_update` binary on PATH if signing is desired (downloaded
      from a Sparkle release in the wrapper workflow).
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request
from datetime import datetime, timezone
from xml.sax.saxutils import escape

REPO = "ryouka0731/KeepingYouAwake-Amphetamine"
TAG_PREFIX = "v"
TAG_SUFFIX = "amphetamine."
APPCAST_TITLE = "KeepingYouAwake (Amphetamine)"
APPCAST_LINK = "https://ryouka0731.github.io/KeepingYouAwake-Amphetamine/appcast.xml"
DESCRIPTION = "A community fork of KeepingYouAwake with Amphetamine-style features."
MIN_SYSTEM_VERSION = "10.13"


def gh(*args):
    return subprocess.check_output(["gh", *args]).decode()


def list_releases():
    raw = gh(
        "release", "list",
        "--repo", REPO,
        "--limit", "100",
        "--json", "tagName,name,publishedAt,isDraft,isPrerelease",
    )
    releases = json.loads(raw)
    return [r for r in releases
            if not r["isDraft"]
            and not r.get("isPrerelease", False)
            and TAG_SUFFIX in r["tagName"]]


def fetch_release_assets(tag):
    raw = gh(
        "release", "view", tag,
        "--repo", REPO,
        "--json", "assets,publishedAt,body",
    )
    return json.loads(raw)


def find_dmg_asset(assets):
    for a in assets:
        if a["name"].endswith(".dmg"):
            return a
    return None


def parse_short_version(tag):
    return tag[len(TAG_PREFIX):] if tag.startswith(TAG_PREFIX) else tag


def parse_build_number(tag, body):
    # Tag format: v1.7.0-amphetamine.3 → bundle build = 1070003 by convention.
    # The build number is encoded as 1MMmmpppNNN where N = amphetamine.N.
    # We approximate: strip any non-digit then take last 7 digits, fallback to '1000000'.
    short = parse_short_version(tag)
    # Try to extract three-part marketing version + suffix counter.
    import re
    m = re.match(r"(\d+)\.(\d+)\.(\d+)-amphetamine\.(\d+)", short)
    if m:
        major, minor, patch, suffix = (int(g) for g in m.groups())
        # Must match the CURRENT_PROJECT_VERSION convention used by the
        # actual build: 1MMmmppp + suffix, e.g. v1.7.0-amphetamine.4
        # → 1070004 (7 digits). Earlier this used patch:04d which
        # produced 10700004 (8 digits), and Sparkle saw the appcast
        # version as numerically greater than the running app's
        # CFBundleVersion forever, looping the "update available"
        # prompt.
        return f"{major:01d}{minor:02d}{patch:03d}{suffix}"
    return "1000000"


def sign_dmg(url, name):
    """Download the dmg and run sign_update; return base64 EdDSA signature."""
    if not os.environ.get("SPARKLE_ED_PRIVATE_KEY"):
        return None, None
    if not shutil.which("sign_update"):
        print("warning: sign_update not on PATH; skipping signature", file=sys.stderr)
        return None, None

    with tempfile.NamedTemporaryFile(suffix=".dmg", delete=False) as tmp:
        urllib.request.urlretrieve(url, tmp.name)
        size = os.path.getsize(tmp.name)
        try:
            output = subprocess.check_output(
                ["sign_update", "-f", "-", tmp.name],
                input=os.environ["SPARKLE_ED_PRIVATE_KEY"].encode(),
            ).decode().strip()
            # sign_update prints: sparkle:edSignature="..." length="..."
            return output, size
        finally:
            os.unlink(tmp.name)


def render_item(release):
    tag = release["tagName"]
    detail = fetch_release_assets(tag)
    asset = find_dmg_asset(detail["assets"])
    if asset is None:
        return None
    short = parse_short_version(tag)
    build = parse_build_number(tag, detail.get("body", ""))
    pub = release["publishedAt"] or datetime.now(timezone.utc).isoformat()
    pubdate = datetime.fromisoformat(pub.replace("Z", "+00:00")).strftime("%a, %d %b %Y %H:%M:%S %z")

    sig_attr, signed_size = sign_dmg(asset["url"], asset["name"])
    size = signed_size if signed_size else asset["size"]

    notes_link = f"https://github.com/{REPO}/releases/tag/{tag}"
    enclosure = (
        f'<enclosure url="{escape(asset["url"])}" '
        f'length="{size}" '
        f'type="application/octet-stream"'
    )
    if sig_attr:
        # sign_update prints raw attributes already; splice them in.
        enclosure += " " + sig_attr.replace('length="' + str(size) + '"', "").strip()
    enclosure += "/>"

    return f"""        <item>
            <title>{escape(short)}</title>
            <pubDate>{pubdate}</pubDate>
            <sparkle:version>{escape(build)}</sparkle:version>
            <sparkle:shortVersionString>{escape(short)}</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>{MIN_SYSTEM_VERSION}</sparkle:minimumSystemVersion>
            <sparkle:releaseNotesLink>{escape(notes_link)}</sparkle:releaseNotesLink>
            {enclosure}
        </item>"""


def main():
    out_path = sys.argv[1] if len(sys.argv) > 1 else "appcast.xml"
    releases = list_releases()
    items = []
    for r in releases:
        rendered = render_item(r)
        if rendered:
            items.append(rendered)

    body = "\n".join(items)
    xml = f"""<?xml version="1.0" standalone="yes"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
    <channel>
        <title>{escape(APPCAST_TITLE)}</title>
        <link>{escape(APPCAST_LINK)}</link>
        <description>{escape(DESCRIPTION)}</description>
        <language>en</language>
{body}
    </channel>
</rss>
"""
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(xml)
    print(f"wrote {out_path} ({len(items)} item{'s' if len(items) != 1 else ''})")


if __name__ == "__main__":
    main()
