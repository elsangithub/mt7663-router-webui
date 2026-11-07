#!/usr/bin/env python3
"""
MediaTek MT7663 / MT7668 Router Web UI Release Version Synchronization Script
Single Source of Truth (SSOT) automation script per Rule 2 & Rule 4.
Atomically synchronizes version strings across debian packaging, build scripts, and READMEs.
"""

import sys
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent

def get_current_version():
    ctrl_path = REPO_ROOT / "debian" / "control"
    if ctrl_path.exists():
        with open(ctrl_path, "r", encoding="utf-8") as f:
            for line in f:
                m = re.match(r'^\s*Version:\s*([^\s]+)', line)
                if m:
                    return m.group(1)
    return None

def update_file(path, pattern, replacement):
    if not path.exists():
        return False
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    new_content, count = re.subn(pattern, replacement, content)
    if count > 0:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)
        return True
    return False

def main():
    target_ver = sys.argv[1] if len(sys.argv) > 1 else None
    if not target_ver:
        target_ver = get_current_version()
    
    if not target_ver:
        print("[ERROR] No target version specified and unable to detect from debian/control.", file=sys.stderr)
        print("Usage: ./sync-version.sh <version> (e.g. ./sync-version.sh 1.0.6)", file=sys.stderr)
        sys.exit(1)

    target_ver = target_ver.lstrip("v")
    print("=" * 65)
    print(f" Synchronizing Router Web UI Release Version -> v{target_ver}")
    print("=" * 65)

    # 1. debian/control
    ctrl_file = REPO_ROOT / "debian" / "control"
    if update_file(ctrl_file, r'(?m)^Version:\s*.+$', f'Version: {target_ver}'):
        print(f" [OK] debian/control -> Version: {target_ver}")
    else:
        print(f" [-] debian/control -> already at Version: {target_ver}")

    # 2. build-deb.sh (ensure dynamic or fallback version is updated)
    build_file = REPO_ROOT / "build-deb.sh"
    if build_file.exists():
        with open(build_file, "r", encoding="utf-8") as f:
            b_content = f.read()
        if "debian/control" in b_content:
            print(" [OK] build-deb.sh -> dynamic debian/control extraction active")
        else:
            if update_file(build_file, r'VERSION=\${1:-[0-9.]+}', f'VERSION=${{1:-{target_ver}}}'):
                print(f" [OK] build-deb.sh -> VERSION=${{1:-{target_ver}}}")

    # 3. README.md & README.id.md
    for readme_name in ["README.md", "README.id.md"]:
        readme_path = REPO_ROOT / readme_name
        if readme_path.exists():
            with open(readme_path, "r", encoding="utf-8") as f:
                text = f.read()

            # Package download link
            text = re.sub(
                r'(releases/download/)v[0-9.]+(?:-[a-zA-Z0-9.]+)?/mt7663-router-webui_[0-9.]+(?:-[a-zA-Z0-9.]+)?_all\.deb',
                rf'\g<1>v{target_ver}/mt7663-router-webui_{target_ver}_all.deb',
                text
            )
            # dpkg / apt install command reference
            text = re.sub(
                r'mt7663-router-webui_[0-9.]+(?:-[a-zA-Z0-9.]+)?_all\.deb',
                f'mt7663-router-webui_{target_ver}_all.deb',
                text
            )
            # Release notes / download comment
            text = re.sub(
                r'\(v[0-9.]+(?:-[a-zA-Z0-9.]+)?\)',
                f'(v{target_ver})',
                text
            )

            with open(readme_path, "w", encoding="utf-8") as f:
                f.write(text)
            print(f" [OK] {readme_name} -> synchronized to v{target_ver}")

    print("=" * 65)
    print(" Synchronization complete! Verification:")
    print(f" - debian/control:   Version: {get_current_version()}")
    print("=" * 65)

if __name__ == "__main__":
    main()
