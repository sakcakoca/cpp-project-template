#!/usr/bin/env python3
"""Resolve TEST_EXECUTABLE_NAME from test/CMakeLists.txt for CI workflows."""

import argparse
import pathlib
import re
import sys


class TestExecutableResolver:
    """Extract TEST_EXECUTABLE_NAME from a CMakeLists file."""

    _PATTERN = re.compile(
        r"set\s*\(\s*TEST_EXECUTABLE_NAME\s+\"?([^\"\)\s]+)\"?\s*\)",
        re.IGNORECASE | re.MULTILINE,
    )

    def resolve_from_file(self, cmake_file: pathlib.Path) -> str:
        content = cmake_file.read_text(encoding="utf-8")
        match = self._PATTERN.search(content)
        if not match:
            raise ValueError(
                f"Could not find TEST_EXECUTABLE_NAME in '{cmake_file}'. "
                "Expected: set(TEST_EXECUTABLE_NAME \"MyProjectTest\")"
            )
        return match.group(1)


class ResolveExecutableCli:
    """CLI entrypoint for resolving the test executable name."""

    def __init__(self) -> None:
        self._resolver = TestExecutableResolver()

    @staticmethod
    def _build_parser() -> argparse.ArgumentParser:
        parser = argparse.ArgumentParser()
        parser.add_argument(
            "--cmake-file",
            default="test/CMakeLists.txt",
            help="Path to the CMake file that defines TEST_EXECUTABLE_NAME",
        )
        return parser

    def run(self, argv: list[str] | None = None) -> int:
        args = self._build_parser().parse_args(argv)

        cmake_file = pathlib.Path(args.cmake_file)
        if not cmake_file.is_file():
            print(f"CMake file not found: {cmake_file}", file=sys.stderr)
            return 1

        try:
            print(self._resolver.resolve_from_file(cmake_file))
        except ValueError as exc:
            print(str(exc), file=sys.stderr)
            return 2

        return 0


def main() -> int:
    return ResolveExecutableCli().run()


if __name__ == "__main__":
    raise SystemExit(main())

