#!/usr/bin/env python3
"""Inject CI run metadata into docs/mainpage.md for Doxygen builds."""

import argparse
import datetime as dt
import os
import pathlib
import sys


def build_run_url(repository: str, run_id: str) -> str:
    """Build the GitHub Actions run URL from repository and run id."""
    return f"https://github.com/{repository}/actions/runs/{run_id}"


def build_replacement_block(
    begin_marker: str,
    end_marker: str,
    utc_now: str,
    ref_name: str,
    commit_sha: str,
    run_id: str,
    run_url: str,
) -> str:
    """Build the markdown block that is inserted between metadata markers."""
    return (
        f"{begin_marker}\n"
        f"_Last CI docs build: {utc_now}_  \n"
        f"_Ref: `{ref_name}`_  \n"
        f"_Commit: `{commit_sha}`_  \n"
        f"_Run: [{run_id}]({run_url})_\n"
        f"{end_marker}"
    )


def upsert_marker_block(
    text: str,
    begin_marker: str,
    end_marker: str,
    replacement_block: str,
) -> str:
    """Replace the existing marker block or append a new one if missing."""
    if begin_marker in text and end_marker in text:
        start = text.index(begin_marker)
        stop = text.index(end_marker, start) + len(end_marker)
        return text[:start] + replacement_block + text[stop:]
    return text.rstrip() + "\n\n" + replacement_block + "\n"


class DocsMetadataInjector:
    """Update a markdown file with CI metadata used in generated docs."""

    _BEGIN_MARKER = "<!-- CI_RUN_METADATA:BEGIN -->"
    _END_MARKER = "<!-- CI_RUN_METADATA:END -->"

    def inject(self, mainpage_path: pathlib.Path) -> None:
        metadata = self._load_ci_metadata()
        original = mainpage_path.read_text(encoding="utf-8")

        replacement = build_replacement_block(
            begin_marker=self._BEGIN_MARKER,
            end_marker=self._END_MARKER,
            utc_now=metadata["utc_now"],
            ref_name=metadata["ref_name"],
            commit_sha=metadata["commit_sha"],
            run_id=metadata["run_id"],
            run_url=build_run_url(metadata["repository"], metadata["run_id"]),
        )

        updated = upsert_marker_block(
            text=original,
            begin_marker=self._BEGIN_MARKER,
            end_marker=self._END_MARKER,
            replacement_block=replacement,
        )
        mainpage_path.write_text(updated, encoding="utf-8")

    @staticmethod
    def _load_ci_metadata() -> dict[str, str]:
        repository = os.getenv("GITHUB_REPOSITORY")
        run_id = os.getenv("GITHUB_RUN_ID")
        ref_name = os.getenv("GITHUB_REF_NAME")
        commit_sha = os.getenv("GITHUB_SHA")
        utc_now = os.getenv("UTC_NOW") or dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%d %H:%M:%SZ")

        missing = [
            name
            for name, value in {
                "GITHUB_REPOSITORY": repository,
                "GITHUB_RUN_ID": run_id,
                "GITHUB_REF_NAME": ref_name,
                "GITHUB_SHA": commit_sha,
            }.items()
            if not value
        ]
        if missing:
            raise ValueError(f"Missing required environment variables: {', '.join(missing)}")

        return {
            "repository": repository,
            "run_id": run_id,
            "ref_name": ref_name,
            "commit_sha": commit_sha,
            "utc_now": utc_now,
        }


class InjectDocsMetadataCli:
    """CLI entrypoint for docs metadata injection in CI."""

    def __init__(self) -> None:
        self._injector = DocsMetadataInjector()

    @staticmethod
    def _build_parser() -> argparse.ArgumentParser:
        parser = argparse.ArgumentParser()
        parser.add_argument(
            "--mainpage",
            default="docs/mainpage.md",
            help="Path to docs mainpage markdown file",
        )
        return parser

    def run(self, argv: list[str] | None = None) -> int:
        args = self._build_parser().parse_args(argv)
        mainpage = pathlib.Path(args.mainpage)
        if not mainpage.is_file():
            print(f"Mainpage file not found: {mainpage}", file=sys.stderr)
            return 1

        try:
            self._injector.inject(mainpage)
        except ValueError as exc:
            print(str(exc), file=sys.stderr)
            return 2

        return 0


def main() -> int:
    return InjectDocsMetadataCli().run()


if __name__ == "__main__":
    raise SystemExit(main())

