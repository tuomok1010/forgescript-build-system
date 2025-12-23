# forgescript-build-system
Simple build system to create and build C++ projects. Windows only for now, Ubuntu release planned.

## A quick warning
This project has been made with the batch scripting language. It was originally planned to be quick few lines of code for compiling a simple program. However it bloated as I required (well, wanted) more features. The language itself can be fairly fragile and cryptic, and in terms of security far from the best choice. While I have done my best to keep the program bug-free, you should use it at your own risk.

## Features
* Fully customizable build settings.
* Incremental compiling process.
* Logging.
* Uses Clang++ under the hood.

## Prerequisites
This program requires that you have the clang compiler tools installed and added into your environment path variable.

## Quick guide
1. Copy the "fbs.build.bat" file into your project's root folder.
2. Run the script. It will first initialize itself by creating a folder called "forgescript".
3. (Optional) Run fbs.build.bat --help for information about the tool. The same(and more) information is covered in this quick guide.

NOTE: There are three ways to configure forgescript. These are the "fbs_build.conf" file, command line arguments, and the script source code itself (by editing variables containing default values). Each method has a certain precedence: HIGH cmd line args, MID .conf file, LOW default values in script. Higher precedence values overwrite lower precedence values! We will cover all three methods of customization next.

### Customizing the .conf file
After running the script for the first time, inside the "forgescript" folder is a file called "fbs_build.conf". This file is the main method of customizing the tool. It contains key:value pairs of the various tool settings. The keys (and example values) are:

src_dir:C:\Users\my_user\Projects\MyProject\src\
  - Directory path to search for source files. Subdirectories will be searched too. If the folder does not exist, it will be created.

build_dir:C:\Users\my_user\Projects\MyProject\build\
  - Directory path where to place the program executables. If the folder does not exist, it will be created.

intermediate_dir:C:\Users\my_user\Projects\MyProject\build\intermediate\
  - Directory path where to place the object files. If the folder does not exist, it will be created.

output_name:hello_world.exe
  - Name of the executable. Should contain the extension.

log_dir:C:\Users\my_user\Projects\MyProject\forgescript\log\
  - Directory path where to store forgescript logs. If the folder does not exist, it will be created.

include_dirs:C:\Users\my_user\Projects\MyProject\include\;C:\Users\my_user\Projects\MyProject\include2\
  - Additional include directories' paths. Separated by ";" character. If the folders does not exist, they will be created.

lib_dirs:C:\Users\my_user\Projects\MyProject\libraries\
  - Additional library directories' paths. Separated by ";" character. If the folders does not exist, they will be created.

libs:glfw3;opengl32;gdi32;user32
  - Libraries to link to the program. Separated by ";" character.

compiler_flags:-g;-O0;-Wall
  - Flags for the clang compiler. Separated by ";" character.

linker_flags:-g
  - Flags for the clang linker. Separated by ";" character.
