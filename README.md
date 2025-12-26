# forgescript-build-system
Simple build system to create and build C++ projects. Windows only for now, Ubuntu release planned.

## A quick warning
This project has been made with the batch scripting language. It was originally planned to be quick few lines of code for compiling a simple program. However it bloated as I required (well, wanted) more features. The language itself can be fairly fragile and cryptic, and in terms of security far from the best choice. While I have done my best to keep the program bug-free, you should use it at your own risk. Here are some general guidelines to minimize any risks:
1. Do not run this script as the administrator.
2. Do not use external folders for forgescript logs/build files. Use subdirectories within your project folder instead.
3. Keep the script file within your project's folder, and run it from that folder.
4. Do not use the script in an actual production environment. Use it for personal projects only.
5. Follow the instructions/best practices in this document.

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

There are three ways to configure forgescript. These are the "fbs_build.conf" file, command line arguments, and the script source code itself (by editing variables containing default values). Each method has a certain precedence: HIGH cmd line args, MID .conf file, LOW default values in script. Higher precedence values overwrite lower precedence values! We will cover all three methods of customization next.

NOTE: It is highly recommended to use absolute paths! Relative paths have NOT been tested with this tool.

### Customizing with the .conf file
After running the script for the first time, inside the "forgescript" folder is a file called "fbs_build.conf". This file is the main method of customizing the tool. It contains key:value pairs of the various tool settings. NOTE: Do not confuse this with the fbs_build.info file which may exist in the same folder! The keys(bold) and example values are:

**src_dir**:C:\Users\my_user\Projects\MyProject\src\
  - Directory path to search for source files. Subdirectories will be searched too. If the folder does not exist, it will be created.

**build_dir**:C:\Users\my_user\Projects\MyProject\build\
  - Directory path where to place the program executables. If the folder does not exist, it will be created.

**intermediate_dir**:C:\Users\my_user\Projects\MyProject\build\intermediate\
  - Directory path where to place the object files. If the folder does not exist, it will be created.

**output_name**:hello_world.exe
  - Name of the executable. Should contain the extension.

**log_dir**:C:\Users\my_user\Projects\MyProject\forgescript\log\
  - Directory path where to store forgescript logs. If the folder does not exist, it will be created.

**include_dirs**:C:\Users\my_user\Projects\MyProject\include\;C:\Users\my_user\Projects\MyProject\include2\
  - Additional include directories' paths. Separated by ";" character. If the folders does not exist, they will be created.

**lib_dirs**:C:\Users\my_user\Projects\MyProject\libraries\
  - Additional library directories' paths. Separated by ";" character. If the folders does not exist, they will be created.

**libs**:glfw3;opengl32;gdi32;user32
  - Libraries to link to the program. Separated by ";" character.

**compiler_flags**:-g;-O0;-Wall
  - Flags for the clang compiler. Separated by ";" character.

**linker_flags**:-g
  - Flags for the clang linker. Separated by ";" character.

### Customizing with command line arguments
You can customize all of the same key:value pairs through the command line arguments as you can through the .conf file. However you must include quotes around the key:value pairs that are multi-variable OR contain spaces (such as file paths with spaces). If you want to be extra safe, you can quote all of the arguments. In addition to the key:value pairs, you can also pass flags to the tool. Currently the only way to pass flags to the tool is by using the command line arguments. Keys(bold) and example values that you can pass are as follows (pay attention to the quotes, they cover both the key and the value!):

**"src_dir**:C:\Users\my_user\Projects\MyProject\src\"
  - Directory path to search for source files. Subdirectories will be searched too. If the folder does not exist, it will be created.

**"build_dir**:C:\Users\my_user\Projects\MyProject\build\"
  - Directory path where to place the program executables. If the folder does not exist, it will be created.

**"intermediate_dir**:C:\Users\my_user\Projects\MyProject\build\intermediate\"
  - Directory path where to place the object files. If the folder does not exist, it will be created.

**output_name**:hello_world.exe
  - Name of the executable. Should contain the extension.

**"log_dir**:C:\Users\my_user\Projects\MyProject\forgescript\log\"
  - Directory path where to store forgescript logs. If the folder does not exist, it will be created.

**"include_dirs**:C:\Users\my_user\Projects\MyProject\include\;C:\Users\my_user\Projects\MyProject\include2\"
  - Additional include directories' paths. Separated by ";" character. If the folders does not exist, they will be created.

**"lib_dirs**:C:\Users\my_user\Projects\MyProject\libraries\"
  - Additional library directories' paths. Separated by ";" character. If the folders does not exist, they will be created.

**"libs**:glfw3;opengl32;gdi32;user32"
  - Libraries to link to the program. Separated by ";" character.

**"compiler_flags**:-g;-O0;-Wall"
  - Flags for the clang compiler. Separated by ";" character.

**"linker_flags**:-g"
  - Flags for the clang linker. Separated by ";" character.

Here is the list of flags you can pass to the tool:<br/><br/>
**--help**<br/>
  - Print this help message<br/>

**--run**<br/>
  - Run the program after compiling.<br/>
  
**--clean-logs**<br/>
  - Clean the logs in the log folder.<br/>
  
**--clean-build**<br/>
  - Clean all of the build files in the build folder.<br/>
  
**--clean**<br/>
  - Clean both logs and build files.<br/>

### Customizing with the default variables in the script
You can edit the values of the default variables in the fbs.build.bat script. These variables give the tool a set of default values to use. Note that these are low precedence. They will be overwritten by command line args and the .conf file. When you open the fbs.build.bat file in an editor, close to the start of the file you should see the following lines (or very similiar to these) which you can edit:<br/><br/>
SET "default_src_dir=%~dp0"<br/>
SET "default_build_dir=%~dp0build\"<br/>
SET "default_intermediate_dir=%default_build_dir%intermediate\"<br/>
SET "default_output_name=program.exe"<br/>
SET "default_log_dir=%forgescript_path%log\"<br/>
SET "default_include_dirs="<br/>
SET "default_lib_dirs="<br/>
SET "default_libs="<br/>
SET "default_compiler_flags=-g -O0 -Wall"<br/>
SET "default_linker_flags=-g"<br/>

NOTE: There are other variables that are named similar to these. Do NOT edit those. Only edit the ones that have the "default_" prefix and are located near the top of the file!

## Example: Initializing an empty project and compiling
Let's say we are planning on creating a new C++ Hello World project. Create a HelloWorld folder and put the fbs.build.bat file in there. For this example, we will assume that the HelloWorld folder resides in C:\Users\test\Projects\. We want our project's folder structure to look like this (do not create these folders yourself apart from the HelloWorld folder, we will let the tool to create them):
```
[HelloWorld]
    |
    +--[build]
    |     |
    |     +--[intermediate]
    |
    +--[forgescript]
    |     |
    |     +--[log]
    |
    +--[libraries1]
    |
    +--[libraries2]
    |
    +--[src]
```

The first thing we need to do, is run the fbs.build.bat file so that it initializes the tool (creates the forgescript folder and the .conf file in there). Do not click the script directly, as this will cause the CLI to close instantly after the script has finished running, preventing you from seeing the output. Open a CLI first, navigate to the script folder, and then run the script from the command line. After running the program, our folder structure will look like this:

```
[HelloWorld]
    |
    +--[forgescript]
    |     |
    |     +--fbs_build.conf
    |
    +--fbs.build.bat
```

The next thing we need to do, is edit the .conf file to match our desired folder structure. Here is the content we want:

```
src_dir:C:\Users\test\Projects\HelloWorld\src\
build_dir:C:\Users\test\Projects\HelloWorld\build\
intermediate_dir:C:\Users\test\Projects\HelloWorld\build\intermediate\
output_name:hello_world.exe
log_dir:C:\Users\test\Projects\HelloWorld\forgescript\log\
include_dirs:
lib_dirs:C:\Users\test\Projects\HelloWorld\libraries1\;C:\Users\test\Projects\HelloWorld\libraries2\
libs:
compiler_flags:-g;-O0;-Wall
linker_flags:-g
```

Next we run the fbs.build.bat again. You should see that the tool creates all of the folders listed in the key:value pairs in the .conf file. It does not find any source files, so the tool will exit without compiling anything. Notice however, that the forgescript folder now contains an additional file called fbs_build.info. This file is used by the tool to save the latest build settings and it is used by the --clean/--clean-logs/--clean-build flags when logs/build files are cleaned. Next we will create a simple hello_world.cpp file in the "src" folder with the following content:

```
#include <iostream>

int main(int argc, char *argv[])
{
  std::cout << "Hello World!" << std::endl;
  return 0;
}
```

After creating this file, run the fbs.build.bat script again. The program should compile succesfully. If there are any errors, check the output in the console, and also the log file which is located at the log_dir (in this example C:\Users\test\Projects\HelloWorld\forgescript\log\). 

That's it! The most basic usage of this tool. More complicated examples coming sooner or later.

