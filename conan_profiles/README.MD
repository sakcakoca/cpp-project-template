# Conan Profiles

Project-local Conan 2 host profiles for each supported platform/compiler.

## Usage

Profiles are used automatically by CMake presets via the `CONAN_HOST_PROFILE`
environment variable. You can also reference them manually:

```bash
conan install . --output-folder=build/linux-gcc-debug \
  --build=missing -pr:h conan_profiles/linux-gcc -s build_type=Debug
```

## Customisation

Each profile specifies `compiler.version` with a common default. Update it to
match your installed compiler:

```bash
gcc --version          # Check GCC version
clang --version        # Check Clang version
```

Edit the relevant profile file and change `compiler.version=XX` accordingly.

### macOS Notes

- Profiles default to Apple Silicon (`arch=armv8`). For Intel Macs, change to
  `arch=x86_64` and update compiler paths from `/opt/homebrew/` to
  `/usr/local/`.
- If your Homebrew GCC version differs from 15, update both the profile and
  the compiler paths in the CMake preset (via `CMakeUserPresets.json`).

### Adding a new profile

Copy an existing profile, update the settings, and reference it from a new
CMake preset via the `CONAN_HOST_PROFILE` environment variable.
