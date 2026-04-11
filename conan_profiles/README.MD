# Conan Profiles

Project-local Conan 2 host profiles are now platform baselines only.

Compiler, compiler version, C++ library (`compiler.libcxx`), runtime, SDK path,
and compiler executables are configured in `CMakePresets.json` and passed to
Conan through preset environment variables.

## Available profiles

- `conan_profiles/linux`
- `conan_profiles/macos`
- `conan_profiles/win-msys2`
- `conan_profiles/win-msvc`

## Usage

Profiles are used automatically by CMake presets via `CONAN_HOST_PROFILE`.

Manual example:

```bash
conan install . --output-folder=build/linux-gcc-debug \
  --build=missing \
  -pr:h conan_profiles/linux \
  -s:h build_type=Debug \
  -s:h compiler=gcc \
  -s:h compiler.version=15 \
  -s:h compiler.libcxx=libstdc++11
```

## Customization

- Update compiler/toolchain values in `CMakePresets.json`.
- Keep profile files focused on stable host baseline properties (such as
  `os` and `arch`).
