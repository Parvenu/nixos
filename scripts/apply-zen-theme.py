"""Apply the bundled CSS to a local Zen Flatpak profile, without migrating data."""

import argparse
import configparser
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

APP_ID = "app.zen_browser.zen"
CSS_FILES = ("userChrome.css", "rose-pine-main.css")
BEGIN = "// BEGIN nixos-cosmic Zen theme"
END = "// END nixos-cosmic Zen theme"
PREFERENCE = 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'


def select_profile(root):
    registry = root / "profiles.ini"
    if not registry.is_file():
        raise ValueError("Launch Zen once, fully quit it, then rerun apply-zen-theme.")

    ini = configparser.ConfigParser(interpolation=None)
    ini.read(registry, encoding="utf-8")
    profiles = []
    defaults = []
    installs = []
    for section in ini.sections():
        entry = ini[section]
        if section.startswith("Profile") and "Path" in entry:
            path = Path(entry["Path"])
            if entry.get("IsRelative", "1") == "1":
                path = root / path
            profiles.append(path)
            if entry.get("Default") == "1":
                defaults.append(path)
        elif section.startswith("Install") and "Default" in entry:
            installs.append(root / entry["Default"])

    # Firefox-style install defaults take precedence over the legacy Default=1.
    candidates = set(installs or defaults or profiles)
    if len(candidates) != 1:
        raise ValueError(
            "Cannot choose a unique Zen profile. In Zen, open about:support and "
            "find Profile Folder; quit Zen, then run apply-zen-theme --profile "
            "\"the full profile folder path\"."
        )
    return candidates.pop()


def with_preference(original):
    if BEGIN in original or END in original:
        if original.count(BEGIN) != 1 or original.count(END) != 1:
            raise ValueError("Ambiguous managed block in user.js; no files changed.")
        start = original.index(BEGIN)
        end = original.index(END)
        if end < start:
            raise ValueError("Malformed managed block in user.js; no files changed.")
        original = original[:start] + original[end + len(END):].lstrip("\r\n")
    # Put the preference last so an older conflicting user_pref cannot override it.
    return original.rstrip("\r\n") + "\n\n" + BEGIN + "\n" + PREFERENCE + "\n" + END + "\n"


def apply_theme(source, profile):
    if not profile.is_dir() or not (profile / "prefs.js").is_file():
        raise ValueError("Not an initialized Zen profile. Launch Zen once and quit it first.")
    chrome = profile / "chrome"
    targets = [chrome / name for name in CSS_FILES] + [profile / "user.js"]
    if chrome.is_symlink() or any(path.is_symlink() for path in targets):
        raise ValueError("Refusing symlinked theme files or chrome directory; no files changed.")
    if chrome.exists() and not chrome.is_dir():
        raise ValueError("The profile's chrome path is not a directory; no files changed.")
    if any(path.exists() and not path.is_file() for path in targets):
        raise ValueError("A theme destination is not a regular file; no files changed.")

    user_js = profile / "user.js"
    original = user_js.read_text(encoding="utf-8") if user_js.exists() else ""
    contents = [
        (source / name).read_bytes() for name in CSS_FILES
    ] + [with_preference(original).encode("utf-8")]
    changes = [
        (path, content)
        for path, content in zip(targets, contents)
        if not path.exists() or path.read_bytes() != content
    ]

    # Back up only the files we replace, never the entire browser profile.
    suffix = ".before-nixos-cosmic-" + str(time.time_ns())
    for path, _ in changes:
        if path.exists():
            backup = path.with_name(path.name + suffix)
            shutil.copy2(path, backup)
            print(f"Backup: {backup}")
    chrome.mkdir(exist_ok=True)
    for path, content in changes:
        path.write_bytes(content)
    print(f"Rosé Pine theme ready in {profile}. Reopen Zen to use it.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="bundled CSS directory (supplied by Nix)")
    parser.add_argument("--profile", type=Path, help="explicit profile folder from about:support")
    args = parser.parse_args()
    try:
        if os.geteuid() == 0:
            raise ValueError("Run apply-zen-theme as your desktop user, not with sudo.")
        running = subprocess.run(
            ["flatpak", "ps", "--columns=application"],
            check=True, capture_output=True, text=True,
        )
        if APP_ID in running.stdout.splitlines():
            raise ValueError("Fully quit Zen before applying its theme; no files changed.")
        root = Path.home() / ".var/app" / APP_ID / ".zen"
        profile = args.profile.expanduser() if args.profile else select_profile(root)
        apply_theme(args.source, profile)
    except (OSError, ValueError, configparser.Error, subprocess.CalledProcessError) as error:
        print(f"apply-zen-theme: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
