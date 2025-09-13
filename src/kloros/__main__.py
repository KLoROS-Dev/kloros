from __future__ import annotations

import argparse
import logging

from kloros._version import __version__
from kloros.utils.health import ping


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="kloros", description="KLoROS command-line interface")
    sub = p.add_subparsers(dest="cmd", required=False)

    sub.add_parser("ping", help="Health check (prints pong)")
    sub.add_parser("version", help="Print version")
    sub.add_parser("info", help="Basic info")

    return p


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    logging.basicConfig(level=logging.INFO, format="%(levelname)s | %(message)s")

    cmd = args.cmd or "ping"

    if cmd == "ping":
        print(ping())
        return 0
    if cmd == "version":
        print(__version__)
        return 0
    if cmd == "info":
        print(f"KLoROS {__version__} - CLI ready")
        return 0

    parser.print_help()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
