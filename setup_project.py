#!/usr/bin/env python3
"""Rename the template project to a new name.

Usage:
    python3 setup_project.py Calculator
    python3 setup_project.py MyWidget --std 20
    python3 setup_project.py "Traffic Scheduler"   # spaces are stripped

The script performs all the renaming steps described in the README:
  - Renames files and directories containing 'myproject' / 'MyProject'
  - Replaces text inside CMakeLists, source, header, test, and doc files
  - Derives three name forms from the input:
      PascalCase  (e.g. TrafficScheduler)  -> project(), test names
      snake_case  (e.g. traffic_scheduler) -> files, namespaces, targets
      UPPER_CASE  (e.g. TRAFFICSCHEDULER)  -> CMake option prefix
  - Optionally updates the C++ standard version across all files

After running, the template is ready to build - no manual edits needed.
"""

import argparse
import re
import shutil
from pathlib import Path
from typing import List, Tuple


class ProjectName:
    """Derives PascalCase, snake_case, and UPPER_CASE from a raw project name."""

    def __init__(self, raw: str) -> None:
        self.pascal = self._to_pascal(raw)
        self.snake = self._to_snake(self.pascal)
        self.upper = self.pascal.upper()

    @staticmethod
    def _to_pascal(name: str) -> str:
        """Convert an arbitrary name to PascalCase."""
        parts = re.split(r"[\s_\-]+", name.strip())
        return "".join(p.capitalize() for p in parts if p)

    @staticmethod
    def _to_snake(pascal: str) -> str:
        """Convert PascalCase to snake_case."""
        result = re.sub(r"(?<=[a-z0-9])([A-Z])", r"_\1", pascal)
        return result.lower()

    def __str__(self) -> str:
        return (
            f"PascalCase : {self.pascal}\n"
            f"snake_case : {self.snake}\n"
            f"UPPER_CASE : {self.upper}"
        )


class ProjectRenamer:
    """Applies text replacements and file/directory renames to the template."""

    # Files to perform text replacements in (relative to project root).
    _TEXT_FILES = (
        "CMakeLists.txt",
        "sonar-project.properties",
        "src/CMakeLists.txt",
        "apps/CMakeLists.txt",
        "test/CMakeLists.txt",
        "docs/CMakeLists.txt",
        "docs/mainpage.md",
        "src/myproject.cpp",
        "include/myproject/myproject.hpp",
        "apps/app.cpp",
        "test/myproject_test.cpp",
    )

    # Paths to rename (deepest first to avoid conflicts).
    _RENAME_RULES = (
        ("include/myproject/myproject.hpp", "include/{s}/{s}.hpp"),
        ("src/myproject.cpp",              "src/{s}.cpp"),
        ("test/myproject_test.cpp",        "test/{s}_test.cpp"),
        ("include/myproject",              "include/{s}"),
    )

    def __init__(self, root: Path, name: ProjectName) -> None:
        self._root = root
        self._name = name
        self._replacements = self._build_replacements()

    def _build_replacements(self) -> List[Tuple[str, str]]:
        """Build ordered (old, new) replacement pairs.

        Order matters: longer/more specific patterns come first to prevent
        partial matches.
        """
        snake = self._name.snake
        pascal = self._name.pascal
        upper = self._name.upper
        return [
            ("MYPROJECT_BUILD_TESTING", f"{upper}_BUILD_TESTING"),
            ("MyProjectTest",          f"{pascal}Test"),
            ("MyProject",              pascal),
            ("cpp-project-template",   snake),
            ("myproject_library",      f"{snake}_library"),
            ("myproject_test",         f"{snake}_test"),
            ("myproject.hpp",          f"{snake}.hpp"),
            ("myproject.cpp",          f"{snake}.cpp"),
            ("myproject::",            f"{snake}::"),
            ("include/myproject/",     f"include/{snake}/"),
            ("include/myproject",      f"include/{snake}"),
            ("namespace myproject",    f"namespace {snake}"),
            ("} // namespace myproject", f"}} // namespace {snake}"),
            ("myproject",              snake),
        ]

    def _replace_in_file(self, filepath: Path) -> None:
        """Apply all text replacements to a single file."""
        content = filepath.read_text(encoding="utf-8")
        for old_text, new_text in self._replacements:
            content = content.replace(old_text, new_text)
        filepath.write_text(content, encoding="utf-8")

    def _rename_path(self, old_rel: str, pattern: str) -> None:
        """Rename a file or directory using the snake_case name."""
        old_path = self._root / old_rel
        new_rel = pattern.format(s=self._name.snake)
        new_path = self._root / new_rel
        if old_path.exists():
            new_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(old_path), str(new_path))
            print(f"  [rename] {old_rel} -> {new_rel}")

    def run(self, dry_run: bool = False) -> None:
        """Execute all replacements and renames."""
        print(f"Project name : {self._name.pascal}")
        print(self._name)
        print()

        for rel_path in self._TEXT_FILES:
            filepath = self._root / rel_path
            if not filepath.exists():
                continue
            if not dry_run:
                self._replace_in_file(filepath)
            print(f"  [text] {rel_path}")

        print()
        for old_rel, pattern in self._RENAME_RULES:
            if not (self._root / old_rel).exists():
                continue
            if dry_run:
                new_rel = pattern.format(s=self._name.snake)
                print(f"  [rename] {old_rel} -> {new_rel}")
            else:
                self._rename_path(old_rel, pattern)

        print()
        if dry_run:
            print("Dry run complete. No files were modified.")
        else:
            print("Done! Your project is ready to build:")
            print()
            print("  cmake --list-presets")
            print("  cmake --preset <preset>")
            print("  cmake --build --preset <preset>")
            print("  ctest --preset <preset>")


class CppStandardUpdater:
    """Updates the C++ standard version across all relevant files."""

    # The current default standard in the template.
    _DEFAULT_STD = "23"

    _VALID_STANDARDS = ("11", "14", "17", "20", "23", "26")

    # Files that contain C++ standard references.
    _FILES = (
        "CMakeLists.txt",
        "CMakePresets.json",
        "src/CMakeLists.txt",
        "apps/CMakeLists.txt",
        "test/CMakeLists.txt",
        "cmake/CompilerWarnings.cmake",
        "README.md",
        "conan_profiles/linux",
        "conan_profiles/macos",
        "conan_profiles/win-msys2",
        "conan_profiles/win-msvc",
    )

    def __init__(self, root: Path, new_std: str) -> None:
        if new_std not in self._VALID_STANDARDS:
            raise ValueError(
                f"Invalid C++ standard '{new_std}'. "
                f"Valid values: {', '.join(self._VALID_STANDARDS)}"
            )
        self._root = root
        self._old = self._DEFAULT_STD
        self._new = new_std
        self._replacements = [
            (f"cxx_std_{self._old}",            f"cxx_std_{self._new}"),
            (f"compiler.cppstd={self._old}",    f"compiler.cppstd={self._new}"),
            (f"CONAN_SETTING_COMPILER_CPPSTD\": \"{self._old}\"", f"CONAN_SETTING_COMPILER_CPPSTD\": \"{self._new}\""),
            (f"CMAKE_CXX_STANDARD {self._old}", f"CMAKE_CXX_STANDARD {self._new}"),
            (f"C++{self._old}",                 f"C++{self._new}"),
        ]

    def run(self, dry_run: bool = False) -> None:
        """Apply C++ standard replacements to all relevant files."""
        if self._old == self._new:
            print(f"C++ standard : {self._new} (unchanged)")
            return

        print(f"C++ standard : {self._old} -> {self._new}")
        print()

        for rel_path in self._FILES:
            filepath = self._root / rel_path
            if not filepath.exists():
                continue
            if not dry_run:
                content = filepath.read_text(encoding="utf-8")
                for old_text, new_text in self._replacements:
                    content = content.replace(old_text, new_text)
                filepath.write_text(content, encoding="utf-8")
            print(f"  [std]  {rel_path}")

        print()


def main() -> None:
    """Parse arguments and run the renamer."""
    parser = argparse.ArgumentParser(
        description="Rename the C++ project template to a new project name."
    )
    parser.add_argument(
        "name",
        help='Project name (e.g. "Calculator", "MyWidget", "Traffic Scheduler")',
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be changed without modifying files.",
    )
    parser.add_argument(
        "--std",
        metavar="VER",
        choices=("11", "14", "17", "20", "23", "26"),
        default=None,
        help="C++ standard version (e.g. 20, 23, 26). Default: no change.",
    )
    args = parser.parse_args()

    project_name = ProjectName(args.name)
    root = Path(__file__).resolve().parent
    renamer = ProjectRenamer(root, project_name)
    renamer.run(dry_run=args.dry_run)

    if args.std:
        updater = CppStandardUpdater(root, args.std)
        updater.run(dry_run=args.dry_run)


if __name__ == "__main__":
    main()
