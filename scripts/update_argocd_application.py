#!/usr/bin/env python3

import argparse
import pathlib
import re
import sys


def replace_line(content: str, marker: str, new_line: str) -> str:
    pattern = re.compile(rf"^.*# {re.escape(marker)}\s*$", re.MULTILINE)
    match = pattern.search(content)
    if not match:
        raise ValueError(f"Marker '{marker}' not found")

    return f"{content[:match.start()]}{new_line}{content[match.end():]}"


def main() -> int:
    parser = argparse.ArgumentParser(description="Update pinned values in an Argo CD Application manifest.")
    parser.add_argument("--file", required=True)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--nginx-tag", required=True)
    parser.add_argument("--php-tag", required=True)
    args = parser.parse_args()

    path = pathlib.Path(args.file)
    content = path.read_text()

    try:
        updated = replace_line(
            content,
            "gitops-source-revision",
            f"    targetRevision: {args.revision} # gitops-source-revision",
        )
        updated = replace_line(
            updated,
            "gitops-nginx-tag",
            f'            tag: "{args.nginx_tag}" # gitops-nginx-tag',
        )
        updated = replace_line(
            updated,
            "gitops-php-tag",
            f'            tag: "{args.php_tag}" # gitops-php-tag',
        )
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    path.write_text(updated)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
