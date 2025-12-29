# forgescript-build-system 🛠️

**A lightweight, fully customizable C++ build system written in pure Batch script**  
Windows-only (for now) • Powered by Clang • Incremental compilation • Simple configuration

[![Windows](https://img.shields.io/badge/platform-Windows-blue.svg)](https://www.microsoft.com/windows)
[![Clang](https://img.shields.io/badge/compiler-Clang-orange.svg)](https://clang.llvm.org/)
[![Batch](https://img.shields.io/badge/language-Batch-critical.svg)]()
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)

> A simple tool that started as "just a few lines to compile a program" — and grew into a feature-rich incremental build system using only Windows Batch scripting.
## Table of Contents

- [Warning & Safety Guidelines](#warning--safety-guidelines)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
  - [Via `fbs_build.conf` (Recommended)](#via-fbs_buildconf-recommended)
  - [Via Command-Line Arguments](#via-command-line-arguments)
  - [Via Default Variables in Script](#via-default-variables-in-script)
- [Command-Line Flags](#command-line-flags)
- [Example config: Executable (clang-cl)](#example-config-executable-clang-cl)
- [Example config: Dynamic library (clang-cl)](#example-config-dynamic-library-clang-cl)
- [Example config: Static library (clang-cl)](#example-config-static-library-clang-cl)
- [Example config: Executable (clang++)](#example-config-executable-clang)
- [Example config: Shared library (clang++)](#example-config-shared-library-clang)
- [Example config: Static library (clang++)](#example-config-static-library-clang)
- [Example: Hello World Project](#example-hello-world-project)
- [Known Limitations](#known-limitations)
- [Future Plans](#future-plans)
- [License](#license)

## Warning & Safety Guidelines

This project is written in **Batch scripting**, which can be fragile and is not ideal for security-critical environments.

**Please follow these guidelines to minimize risk:**

1. **Never run the script as Administrator**
2. Keep logs and build output **inside your project folder** (subdirectories only)
3. Run the script **from within your project directory**
4. Use only for **personal, non-production projects**
5. Always review changes before running

> The script has been carefully written and tested, but use at your own risk.

## Features

- Fully customizable build settings
- **Incremental compilation** – only modified files are recompiled
- Detailed logging with timestamps
- Automatic directory creation
- Support for custom include paths, library paths, and linked libraries
- Clean commands (`--clean`, `--clean-build`, `--clean-logs`)
- Optional auto-run after successful build (Work in progress)
- Uses **clang/clang++/clang-cl** for excellent diagnostics and modern C++ support

## Prerequisites

- **Windows** operating system
- **clang/clang++/clang-cl** installed and added to your `PATH`  
  (e.g., via LLVM installer or Visual Studio Build Tools with Clang)

Test it in a terminal:
```bat
clang++ --version
```

## Quick Start

1. Copy `fbs.build.bat` into your project root folder
2. Open a terminal in that folder and run:
   ```bat
   fbs.build.bat
   ```
3. The script will create a `forgescript` folder with `fbs_build.conf`
4. Edit `fbs_build.conf` to match your project structure (see below)
5. Add your `.cpp` files to the source directory
6. Run `fbs.build.bat` again — your project will compile!

Use `--help` anytime for usage info:
```bat
fbs.build.bat --help
```

## Configuration

Settings follow this precedence (high to low):

**High** → Command-line arguments  
**Medium** → `forgescript/fbs_build.conf`  
**Low** → Default values in the script

> **Tip:** Use **absolute paths** for maximum reliability.

### Via `fbs_build.conf` (Recommended)

Located in `forgescript/fbs_build.conf` after first run.

| Key                  | Example Value                                      | Description                       |
|----------------------|----------------------------------------------------|-----------------------------------|
| `compiler`           | `clang++`                                          | Compiler (clang/clang++/clang-cl  |
| `src_dir`            | `C:\Users\me\Projects\MyApp\src\`                  | Source directory (recursive)      |
| `build_dir`          | `C:\Users\me\Projects\MyApp\build\`                | Output directory for executables  |
| `intermediate_dir`   | `C:\Users\me\Projects\MyApp\build\intermediate\`   | Object file directory             |
| `output_name`        | `myapp.exe`                                        | Executable name                   |
| `log_dir`            | `C:\Users\me\Projects\MyApp\forgescript\log\`      | Log storage                       |
| `include_dirs`       | `C:\path\include1\;C:\path\include2\`              | Semicolon-separated include paths |
| `lib_dirs`           | `C:\path\libs\;C:\other\libs\`                     | Semicolon-separated library paths |
| `libs`               | `glfw3;opengl32;gdi32;user32`                      | Semicolon-separated libraries     |
| `compiler_flags`     | `-g;-O0;-Wall`                                     | Semicolon-separated Clang flags   |
| `linker_flags`       | `-Wl,--verbose;-shared`                            | Semicolon-separated linker flags  |

### Via Command-Line Arguments

Same keys as config file, but passed as arguments:

```bat
fbs.build.bat ^
  "src_dir:C:\MyProject\src\" ^
  "build_dir:C:\MyProject\build\" ^
  output_name:mygame.exe ^
  "libs:glfw3;opengl32"
```

Quote any key:value containing spaces or semicolons.

### Via Default Variables in Script

Edit the `default_*` variables near the top of `fbs.build.bat`:

```bat
SET "default_compiler=clang++"
SET "default_src_dir=%~dp0src\"
SET "default_build_dir=%~dp0build\"
SET "default_output_name=program.exe"
REM ... etc
```

These are **lowest priority** — useful for templates or if you want to obscure absolute paths in a github repo.

## Command-Line Flags

| Flag             | Description                                      |
|------------------|--------------------------------------------------|
| `--help`         | Show help message                                |
| `--run`          | Run the executable after successful build        |
| `--clean-logs`   | Delete all logs                                  |
| `--clean-build`  | Delete all build artifacts (`build/` folder)     |
| `--clean`        | Clean both logs and build                        |
| `--force`        | Required when cleaning external build/log paths  |

## Example config: Executable (clang-cl)
```
compiler:clang-cl
output_name:myapp.exe
compiler_flags:/Zi;/Od;/Wall;/W4
linker_flags:/SUBSYSTEM:CONSOLE;/VERBOSE
include_dirs:C:\libs\include\;C:\libs\include2\
lib_dirs:C:\libs\win64\;C:\libs\extra\
libs:ws2_32;user32;gdi32;opengl32
```

## Example config: Dynamic library (clang-cl)
```
compiler:clang-cl
output_name:firelink.dll
compiler_flags:/Zi;/O2;/Wall
linker_flags:/DLL;/VERBOSE;/EXPORT:initializeLibrary;/EXPORT:shutdownLibrary
include_dirs:include\;external\asio\include\;external\spdlog\include\
lib_dirs:lib\win64\;external\libs\
libs:ws2_32;iphlpapi
```

## Example config: Static library (clang-cl)
```
compiler:clang-cl
output_name:firelink.lib
compiler_flags:/Zi;/O2;/MT;/Wall
linker_flags:/VERBOSE
include_dirs:include\;third_party\headers\;third_party\utils\
lib_dirs:lib\static\;external\static_libs\
libs:ws2_32
```

## Example config: Executable (clang++)
```
compiler:clang++
output_name:myapp
compiler_flags:-g;-O0;-Wall;-Wextra;-std=c++20
linker_flags:-Wl,--verbose;-pthread
include_dirs:/usr/local/include/;/opt/libs/include/;./include/
lib_dirs:/usr/local/lib/;/opt/libs/lib/
libs:pthread;dl;m
```

## Example config: Shared library (clang++)
```
compiler:clang++
output_name:libfirelink.so
compiler_flags:-g;-O2;-Wall;-fPIC;-std=c++20
linker_flags:-shared;-Wl,--verbose;-Wl,-soname,libfirelink.so.1
include_dirs:include/;external/boost/include/;external/fmt/include/
lib_dirs:/usr/local/lib/;external/lib/
libs: pthread;dl
```

## Example config: Static library (clang++)
```
compiler:clang++
output_name:libfirelink.a
compiler_flags:-g;-O2;-Wall;-fPIC;-std=c++20
linker_flags:-Wl,--verbose
include_dirs:include/;third_party/json/include/;third_party/logger/include/
lib_dirs:/usr/lib/;external/static/
libs: pthread
```

## Example: Hello World Project

Desired structure:
```
HelloWorld/
├── src/
│   └── hello_world.cpp
├── build/
│   └── intermediate/
├── forgescript/
│   └── log/
├── libraries1/
├── libraries2/
└── fbs.build.bat
```

1. Place `fbs.build.bat` in `HelloWorld`
2. Run it once → creates `forgescript/fbs_build.conf`
3. Edit config with your absolute paths
4. Create `src/hello_world.cpp`:
   ```cpp
   #include <iostream>
   int main() {
       std::cout << "Hello World!" << std::endl;
       return 0;
   }
   ```
5. Run `fbs.build.bat` → compiles to `build/hello_world.exe`

Check `forgescript/log/` for detailed output on errors.

## Known Limitations

- Windows-only (Ubuntu support planned)
- Batch scripting quirks (paths with special characters may need care)
- Relative paths not thoroughly tested
- No parallel compilation yet

## Future Plans

- Ubuntu/Linux support
- More build modes (Debug/Release)
- Dependency scanning for headers
- Better error handling and user feedback
- Optional auto-run after successful build

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

Made with dedication (and a lot of `ECHO` debugging) 💻
