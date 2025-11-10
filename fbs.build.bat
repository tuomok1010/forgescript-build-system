@ECHO OFF
REM ==================================================================
REM  Forgescript Build System
REM  Author: Tuomo Kanniainen
REM  License: MIT (see LICENSE file)
REM ==================================================================

SETLOCAL EnableDelayedExpansion
ECHO [SCRIPT] Running from: %~f0

REM ===== CUSTOM (can be overwritten by cmd args =====
SET "custom_build_type="
SET "custom_src_dir="
SET "custom_build_dir="
SET "custom_output_name="
SET "custom_log_dir="
SET "custom_log_file_name="
SET "custom_include_dirs="

CALL :MAKETIMESTAMP timestamp

REM ===== DEFAULT (can be overwritten by CUSTOM or cmd args =====
SET "default_build_type=debug"
SET "default_src_dir=%~dp0"
SET "default_build_dir=%~dp0build\"
SET "default_output_name=program.exe"
SET "default_log_dir=%~dp0log\"
SET "default_log_file_name=build_%timestamp%.log"
SET "default_include_dirs=%~dp0include\ %~dp0include2\"


CALL :SETOR build_type     custom_build_type     default_build_type
CALL :SETOR src_dir        custom_src_dir        default_src_dir
CALL :SETOR build_dir      custom_build_dir      default_build_dir
CALL :SETOR output_name    custom_output_name    default_output_name
CALL :SETOR log_dir        custom_log_dir        default_log_dir
CALL :SETOR log_file_name  custom_log_file_name  default_log_file_name
CALL :SETOR include_dirs   custom_include_dirs   default_include_dirs

REM === Parse command-line arguments === TODO continue from here
:PARSE_ARGS
IF "%~1"=="" GOTO :ARGS_DONE
IF /I "%~1"=="--debug"   SET "custom_build_type=debug"   & SHIFT
IF /I "%~1"=="--release" SET "custom_build_type=release" & SHIFT
IF /I "%~1"=="--init-project" (
    GOTO :INIT_PROJECT
)
SHIFT
GOTO :PARSE_ARGS
:ARGS_DONE

REM === Initialize log ===
(
    ECHO.
    ECHO ========================================
    ECHO  BUILD STARTED: %DATE% %TIME%
    ECHO  Script: %~f0
    ECHO  Build Type: %build_type%
    ECHO  Source: "%src_dir%"
    ECHO  Output: "%build_dir%"
    ECHO ========================================
    ECHO.
) > "%log_dir%%log_file_name%"

GOTO :MAIN

REM === Initialize project directory structure based on the DEFAULT/CUSTOM/CMD ARGS values ===
:INIT_PROJECT
REM Build directories if they do not exist, but only if --init-project arg exists
IF NOT EXIST "%build_dir%" MKDIR "%build_dir%" 2>NUL
IF NOT EXIST "%src_dir%" MKDIR "%src_dir%" 2>NUL
IF NOT EXIST "%log_dir%" MKDIR "%log_dir%" 2>NUL

FOR %%i IN (%include_dirs%) DO (
    SET "quoted="%%i""
    IF NOT EXIST "!quoted!" MKDIR "!quoted!" 2>NUL
)
EXIT /B 0

REM === Logging Function ===
:LOG
    SET "level=%~1"
    SET "msg=%~2"
    SET "log_line=[%timestamp%] [%level%] %msg%"
    ECHO !log_line!
    ECHO !log_line! >> "%log_dir%%log_file_name%"
    IF /I "%level%"=="ERROR" (
        EXIT /B 1
    )
    EXIT /B 0

:MAIN
REM === Ensure we're in script dir ===
CD /D "%~dp0" || CALL :LOG ERROR "Failed to change to script directory"

CALL :LOG INFO "Building %output_name%"

REM === Collect source files ===
SET "src_files="
SET "file_count=0"

FOR /R "%src_dir%" %%F IN (*.cpp *.c) DO (
    IF EXIST "%%F" (
        SET "src_files=!src_files! "%%F""
        SET /A file_count+=1
        CALL :LOG INFO "Found source: %%F"
    )
)

REM remove leading space
IF DEFINED src_files SET "src_files=!src_files:~1!"

IF %file_count% EQU 0 (
    CALL :LOG ERROR "No .cpp or .c files found in '%src_dir%'"
)

CALL :LOG INFO "Found %file_count% source file(s)"

REM Collect include dirs
SET "include_dirs_with_compiler_arg_prefixes="
FOR %%i IN (%include_dirs%) DO (
    SET "trimmed_path=%%i"

    :: Trim trailing backslash, because they can cause a bug in the compiler -I argument
    IF "!trimmed_path:~-1!" == "\" SET "trimmed_path=!trimmed_path:~0,-1!"
    
    SET "quoted_path="!trimmed_path!""
    SET "include_dirs_with_compiler_arg_prefixes=!include_dirs_with_compiler_arg_prefixes! -I!quoted_path!"
)

REM Remove leading space
IF DEFINED include_dirs_with_compiler_arg_prefixes SET "include_dirs_with_compiler_arg_prefixes=!include_dirs_with_compiler_arg_prefixes:~1!"

REM Compile 
CALL :LOG INFO "Compiling: !src_files!"
CALL :LOG INFO "Output: %build_dir%%output_name%"

clang++ -g -O0 -Wall ^
    !include_dirs_with_compiler_arg_prefixes!^
    !src_files! ^
    -o "%build_dir%%output_name%" ^
    2>> "%log_dir%%log_file_name%"

IF !ERRORLEVEL! NEQ 0 (
    CALL :LOG ERROR "Compilation failed! See '%log_dir%%log_file_name%' for details"
) ELSE (
    CALL :LOG SUCCESS "Build completed successfully: %build_dir%%output_name%"
)

ENDLOCAL
EXIT /B 0

:SETOR
:: Set variable to custom var or fall back to default
:: %1 = target var name
:: %2 = custom var name
:: %3 = default var name
IF NOT DEFINED %2 (
    SET "%~1=!%~3!"
) ELSE (
    SET "%~1=!%~2!"
)
GOTO :EOF


:MAKETIMESTAMP
:: Make a time stamp suitable for file names
SET "d=%DATE%"
SET "t=%TIME%"

:: List of characters to replace (must be quoted and safe)
FOR %%s IN ("/" "\" "|" "-" "." "," ":" " " "%%" "&" "[" "]" "(" ")") DO (
    SET "d=!d:%%~s=_!"
    SET "t=!t:%%~s=_!"
)

:: Remove AM/PM
FOR %%a IN (" AM" " PM" " am" " pm") DO (
    SET "t=!t:%%~a=!"
)

:: Combine with underscore
SET "%~1=%d%_%t%"
GOTO :EOF
