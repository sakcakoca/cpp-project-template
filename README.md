# C++ Project Template

A cross-platform C++23 project template with CMake presets, Conan 2, sanitizers,
Valgrind, Doxygen, PVS-Studio, clang-tidy, and CI for GitHub Actions, Travis CI,
and AppVeyor.

---

## Prerequisites

| Tool | Minimum Version | Purpose |
|------|-----------------|---------|
| **CMake** | 3.21+ | Build system |
| **Ninja** | any | Build backend (used by all presets) |
| **Conan** | 2.x | Package manager (`pip install conan`) |
| **GCC** or **Clang** or **MSVC** | C++23 capable | Compiler |
| **Python** | 3.8+ | Needed for Conan |

### Optional tools

| Tool | Purpose | Install |
|------|---------|---------|
| **Doxygen** | API documentation | `apt install doxygen` / `brew install doxygen` / `choco install doxygen.install` |
| **Valgrind** | Memory checking (Linux only) | `apt install valgrind` |
| **PVS-Studio** | Static analysis | [pvs-studio.com](https://pvs-studio.com) |
| **clang-tidy** | Linting (uses `.clang-tidy` config) | Included with Clang / LLVM |
| **gcov / lcov** | Code coverage | Included with GCC |

### Platform-specific setup

<details>
<summary>Linux</summary>

```bash
# Ubuntu/Debian
sudo apt-get install -y build-essential ninja-build cmake
pip install conan
conan profile detect

# Optional
sudo apt-get install -y clang doxygen valgrind
```
</details>

<details>
<summary>macOS</summary>

```bash
brew install gcc ninja cmake conan        # GCC toolchain
brew install llvm ninja cmake conan       # Clang toolchain
conan profile detect

# Optional
brew install doxygen
```
</details>

<details>
<summary>Windows — MSYS2 (GCC / Clang)</summary>

Open an MSYS2 MINGW64 terminal:
```bash
pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-ninja mingw-w64-x86_64-cmake mingw-w64-x86_64-python-pip
# For Clang additionally:
pacman -S mingw-w64-x86_64-clang

pip install conan
conan profile detect
```
</details>

<details>
<summary>Windows — MSVC</summary>

1. Install Visual Studio 2022 with the "Desktop development with C++" workload.
2. Install Ninja: `choco install ninja`
3. Install Conan: `pip install conan && conan profile detect`
4. Use a **Developer Command Prompt** or **Developer PowerShell** for all commands.
</details>

---

## Quick Start

### 1. List available presets

```bash
cmake --list-presets            # configure presets
cmake --build --list-presets    # build presets
ctest --list-presets            # test presets
```

### 2. Configure, build, and test

Pick the preset that matches your platform/compiler. Examples:

```bash
# ── Linux GCC ────────────────────────────────────────────────────────────
cmake --preset linux-gcc-debug
cmake --build --preset linux-gcc-debug
ctest --preset linux-gcc-test

# ── Linux Clang ──────────────────────────────────────────────────────────
cmake --preset linux-clang-debug
cmake --build --preset linux-clang-debug
ctest --preset linux-clang-test

# ── macOS GCC ────────────────────────────────────────────────────────────
cmake --preset macos-gcc-debug
cmake --build --preset macos-gcc-debug
ctest --preset macos-gcc-test

# ── macOS Clang ──────────────────────────────────────────────────────────
cmake --preset macos-clang-debug
cmake --build --preset macos-clang-debug
ctest --preset macos-clang-test

# ── Windows MSYS2 GCC (run from MINGW64 terminal) ───────────────────────
cmake --preset win-msys2-gcc-debug
cmake --build --preset win-msys2-gcc-debug
ctest --preset win-msys2-gcc-test

# ── Windows MSYS2 Clang (run from MINGW64 terminal) ─────────────────────
cmake --preset win-msys2-clang-debug
cmake --build --preset win-msys2-clang-debug
ctest --preset win-msys2-clang-test

# ── Windows MSVC (run from Developer Command Prompt) ────────────────────
# First enable vs build tools
"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64

#Then compile
cmake --preset win-msvc-debug
cmake --build --preset win-msvc-debug
ctest --preset win-msvc-test
```

**Note:** `linux-clang-debug-msan` is configured to use `libc++` and requires an MSan-compatible libc++ toolchain.

**Note:** On Windows MSYS2 environment, use `win-msys2-clang-libstdc++-debug` for MINGW64 and `win-msys2-clang-debug` for CLANG64.

**Note:** If you are switch between sanitized and non-sanitized builds then you may need to clean up conan cache and build: `conan remove -c "*"` and `conan cache clean *`

### 3. Release builds

Replace `-debug` with `-release` or `-relwithdebinfo`:

```bash
cmake --preset linux-gcc-release
cmake --build --preset linux-gcc-release
```

### 4. One-liner (configure + build + test)

```bash
cmake --preset linux-gcc-debug && cmake --build --preset linux-gcc-debug && ctest --preset linux-gcc-test
```

---

## Sanitizers

Run with sanitizers enabled (Debug builds only):

```bash
# AddressSanitizer + UndefinedBehaviorSanitizer
cmake --preset linux-gcc-debug-asan
cmake --build --preset linux-gcc-debug-asan
ctest --preset linux-gcc-test-asan

# ThreadSanitizer
cmake --preset linux-clang-debug-tsan
cmake --build --preset linux-clang-debug-tsan
ctest --preset linux-clang-test-tsan

# LeakSanitizer (Linux only)
cmake --preset linux-gcc-debug-lsan
cmake --build --preset linux-gcc-debug-lsan
ctest --preset linux-gcc-test-lsan

# Windows MSVC ASan
cmake --preset win-msvc-debug-asan
cmake --build --preset win-msvc-debug-asan
ctest --preset win-msvc-test-asan
```

---

## Valgrind Memcheck (Linux only)

```bash
cmake --preset linux-gcc-debug
cmake --build --preset linux-gcc-debug
ctest --test-dir build/linux-gcc-debug -T memcheck --output-on-failure
```

## Leaks Check (MacOS only)

On MacOS `valgrind` is not available but `leaks` tool can be used with the test executable instead of running `ctest`:

```bash
# macOS GCC Debug
MallocStackLogging=1 leaks --atExit -- ./build/macos-gcc-debug/test/MyProjectTest

# macOS Clang Debug
MallocStackLogging=1 leaks --atExit -- ./build/macos-clang-debug/test/MyProjectTest
```

---


## Doxygen Documentation

Doxygen runs automatically during build if installed. To build only docs:

```bash
cmake --preset linux-gcc-debug
cmake --build --preset linux-gcc-debug --target docs
```

Output is in `build/<preset>/docs/html/index.html`.

To customize what gets documented, edit `docs/CMakeLists.txt` (the
`doxygen_add_docs()` call) and `docs/mainpage.md`.

---

## PVS-Studio Static Analysis

If PVS-Studio is installed and licensed:

```bash
cmake --preset linux-gcc-debug
cmake --build --preset linux-gcc-debug
cmake --build --preset linux-gcc-debug --target pvs_analysis
```

The JSON report is written to `build/<preset>/pvs_report.json`.

---

## Code Coverage (GCC/Clang, not MSVC)

```bash
cmake --preset linux-gcc-debug -DENABLE_COVERAGE=ON
cmake --build --preset linux-gcc-debug
ctest --preset linux-gcc-test

# Generate HTML report
lcov --capture --directory build/linux-gcc-debug --output-file coverage.info
genhtml coverage.info --output-directory coverage_report
# Open coverage_report/index.html
```

---

## clang-tidy

The `.clang-tidy` config at the project root is automatically picked up by
clang-tidy. Integrate with your editor or run manually:

```bash
# After configuring (needs compile_commands.json):
cmake --preset linux-clang-debug
run-clang-tidy -p build/linux-clang-debug
```

---

## Creating a New Project from This Template

### Automatic setup (recommended)

Run the setup script with your project name:

```bash
python3 setup_project.py "String Calculator"
```

This automatically renames all files, directories, namespaces, CMake targets,
and include paths. Three name forms are derived:

| Input | PascalCase | snake_case | UPPER_CASE |
|-------|------------|------------|------------|
| `"String Calculator"` | `StringCalculator` | `string_calculator` | `STRINGCALCULATOR` |
| `Calculator` | `Calculator` | `calculator` | `CALCULATOR` |
| `my-widget` | `MyWidget` | `my_widget` | `MYWIDGET` |

Use `--dry-run` to preview changes without modifying anything:

```bash
python3 setup_project.py --dry-run Calculator
```

### Manual setup (6 steps)

1. **`CMakeLists.txt`** (root) — Change the `project()` name, version, and
   description. Update `MYPROJECT_BUILD_TESTING` to match (e.g.
   `MYWIDGET_BUILD_TESTING`).

2. **`src/`** — Rename `myproject.cpp` to your source file(s). Update
   `src/CMakeLists.txt`: change the library target name (`myproject_library`),
   and update the `SOURCES` and `HEADERS` lists with your actual file names.

3. **`include/myproject/`** — Rename the `myproject` folder and
   `myproject.hpp` to match your project. Update `#include` paths in all
   source files accordingly (e.g. `#include <mywidget/mywidget.hpp>`).

4. **`apps/`** — Update `apps/CMakeLists.txt` to link against your renamed
   library target.

5. **`test/`** — Rename `myproject_test.cpp` and update `test/CMakeLists.txt`
   with your test executable name and library target.

6. **`docs/`** — Update `docs/CMakeLists.txt` header path and
   `docs/mainpage.md`.

Everything else (cmake modules, presets, conan profiles, CI pipelines,
`.clang-tidy`, `.gitignore`) works as-is with no changes.

### Conan profiles

Compiler and Conan toolchain settings are owned by `CMakePresets.json`.
Profiles in `conan_profiles/` only keep stable platform baseline settings.
See `conan_profiles/README.MD` for details.

---

## CI Pipelines

Three pipeline configurations are included — all pre-configured and ready to use:

| File | Platform | What it tests |
|------|----------|---------------|
| `.github/workflows/ci.yml` | Linux, macOS, Windows | Tests, Valgrind, Leaks, Sanitizers |
| `.travis.yml` | Linux, macOS | Tests, Valgrind, Leaks, Sanitizers |
| `appveyor.yml` | Windows | Tests, Sanitizers |

No changes needed in pipeline files for a new project — they use the same CMake
presets.

---


## Project Structure

```
├── CMakeLists.txt              # Root build — change project() name here
├── CMakePresets.json           # All configure/build/test presets
├── conanfile.txt               # Conan dependencies
├── setup_project.py            # Rename template to your project name
├── .clang-tidy                 # clang-tidy configuration
├── .gitignore
├── .github/workflows/ci.yml   # GitHub Actions CI
├── .travis.yml                 # Travis CI
├── appveyor.yml                # AppVeyor CI
├── cmake/                      # CMake modules (reusable, no changes needed)
│   ├── CompilerWarnings.cmake
│   ├── ExecuteConanInstall.cmake
│   ├── ExecutePVSAnalyzer.cmake
│   ├── FindPVSExecutable.cmake
│   ├── PreventInSourceBuilds.cmake
│   ├── PrintToolVersions.cmake
│   ├── Sanitizers.cmake
│   └── StandardProjectSettings.cmake
├── conan_profiles/             # Platform-specific Conan profiles
│   ├── linux
│   ├── macos
│   ├── win-msys2
│   ├── win-msvc
│   └── README.MD
├── include/                    # Public headers (namespaced)
│   └── myproject/
│       └── myproject.hpp
├── src/                        # Library sources
│   ├── CMakeLists.txt
│   └── myproject.cpp
├── apps/                       # Application executables
│   ├── CMakeLists.txt
│   └── app.cpp
├── test/                       # Unit tests (Google Test)
│   ├── CMakeLists.txt
│   └── myproject_test.cpp
├── docs/                       # Doxygen documentation
│   ├── CMakeLists.txt
│   └── mainpage.md
└── pvs/                        # PVS-Studio configuration
    └── CMakeLists.txt
```
