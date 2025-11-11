@ECHO OFF
REM ==================================================================
REM  Forgescript Build System
REM  Author: Tuomo Kanniainen
REM  License: MIT (see LICENSE file)
REM ==================================================================

SETLOCAL EnableDelayedExpansion
ECHO [SCRIPT] Running from: %~f0
CALL :MAKETIMESTAMP timestamp

REM IMPORTANT: DO NOT EDIT THIS (log_file_name), or it can lead to stale/lost data when cleaning up project
SET "log_file_name=forgescript_build_%timestamp%.log"

REM ===== CUSTOM (Mid precedence: can be overwritten by cmd args) =====
SET "custom_build_type="
SET "custom_src_dir="
SET "custom_build_dir="
SET "custom_output_name="
SET "custom_log_dir="
SET "custom_include_dirs="

REM ===== DEFAULT (Low precedence: can be overwritten by CUSTOM or cmd args) =====
SET "default_build_type=debug"
SET "default_src_dir=%~dp0"
SET "default_build_dir=%~dp0build\"
SET "default_output_name=program.exe"
SET "default_log_dir=%~dp0log\"
SET "default_include_dirs=%~dp0include\ %~dp0include2\"

REM ===== CMD (High precedence: cannot be overwritten) =====
SET "cmd_build_type="
SET "cmd_src_dir="
SET "cmd_build_dir="
SET "cmd_output_name="
SET "cmd_log_dir="
SET "cmd_include_dirs="

REM === Parse command-line arguments ===
:PARSE_ARGS
IF "%~1"=="" GOTO :ARGS_DONE
SET "arg=%~1"

:: Handle flags
ECHO "%arg%" | FINDSTR /I "^--debug$ ^--release$ ^--init-project$ ^--clean$ ^--run$" >NUL
IF NOT ERRORLEVEL 1 (
    IF /I "%arg%"=="--init-project" CALL :INIT_PROJECT & EXIT /B 0
    IF /I "%arg%"=="--clean"        CALL :CLEAN_BUILD  & EXIT /B 0
    IF /I "%arg%"=="--debug"        SET "cmd_build_type=debug"     & SHIFT & GOTO :PARSE_ARGS
    IF /I "%arg%"=="--release"      SET "cmd_build_type=release"   & SHIFT & GOTO :PARSE_ARGS
    IF /I "%arg%"=="--run"          SET "run_after_build=1"        & SHIFT & GOTO :PARSE_ARGS
)

:: Handle key=value pairs
ECHO "%arg%" | FINDSTR /C:"=" >NUL
IF ERRORLEVEL 1 (
    CALL :LOG WARN "Unknown argument: %arg%"
    SHIFT
    GOTO :PARSE_ARGS
)

REM Split on first '='
FOR /F "tokens=1,* delims==" %%A IN ("%arg%") DO (
    SET "key=%%A"
    SET "val=%%B"
)

REM Remove surrounding quotes from value if present
IF DEFINED val (
    SET "val=!val:=!"
    IF "!val:~0,1!"=="""" SET "val=!val:~1!"
    IF "!val:~-1!"=="""" SET "val=!val:~0,-1!"
)

REM Map key to custom variable
IF /I "!key!"=="src_dir"        SET "cmd_src_dir=!val!"
IF /I "!key!"=="build_dir"      SET "cmd_build_dir=!val!"
IF /I "!key!"=="output_name"    SET "cmd_output_name=!val!"
IF /I "!key!"=="log_dir"        SET "cmd_log_dir=!val!"
IF /I "!key!"=="include_dirs"   SET "cmd_include_dirs=!val!"
SHIFT
GOTO :PARSE_ARGS
:ARGS_DONE

REM === Set variables to cmd var > custom var > default var ===
CALL :SETOR build_type     cmd_build_type     custom_build_type     default_build_type
CALL :SETOR src_dir        cmd_src_dir        custom_src_dir        default_src_dir
CALL :SETOR build_dir      cmd_build_dir      custom_build_dir      default_build_dir
CALL :SETOR output_name    cmd_output_name    custom_output_name    default_output_name
CALL :SETOR log_dir        cmd_log_dir        custom_log_dir        default_log_dir
CALL :SETOR include_dirs   cmd_include_dirs   custom_include_dirs   default_include_dirs

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
:: TODO: Should we add quotes to paths if path is not quoted?
IF NOT EXIST "%build_dir%" MKDIR "%build_dir%" 2>NUL
IF NOT EXIST "%src_dir%" MKDIR "%src_dir%" 2>NUL
IF NOT EXIST "%log_dir%" MKDIR "%log_dir%" 2>NUL

FOR %%i IN (%include_dirs%) DO (
    SET "quoted_dir="%%i""
    IF NOT EXIST "!quoted_dir!" MKDIR "!quoted_dir!" 2>NUL
)
GOTO :EOF

REM === Clean the build directory ===
:CLEAN_BUILD
CALL :LOG INFO "Cleaning build directory: %build_dir%..."
IF EXIST "%build_dir%" (RMDIR /S /Q "%build_dir%" & MKDIR "%build_dir")
CALL :LOG INFO "Done."
GOTO :EOF

REM === Clean the log directory ===
:CLEAN_LOGS
IF NOT EXIST "%log_dir%" GOTO :EOF

CALL :IS_SUBDIR "%log_dir%" "%~dp0" is_safe
IF /I "%is_safe%"=="YES" (
    CALL :LOG INFO "Cleaning project-local logs: %log_dir%"
    DEL /Q /F "%log_dir%build_*.log" 2>NUL
) ELSE IF DEFINED force_clean (
    CALL :LOG WARN "FORCE: Cleaning external log dir: %log_dir%"
    DEL /Q /F "%log_dir%build_*.log" 2>NUL
) ELSE (
    CALL :LOG WARN "log_dir outside project. Use --clean --force to clean."
)
GOTO :EOF

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
:: Set target = cmd var > custom var > default var
:: %1 = target
:: %2 = cmd var
:: %3 = custom var
:: %4 = default var
IF DEFINED %2 (
    SET "%~1=!%~2!"
    GOTO :EOF
)
IF DEFINED %3 (
    SET "%~1=!%~3!"
    GOTO :EOF
)
SET "%~1=!%~4!"
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

:IS_SUBDIR
SET "child=%~f1"
SET "parent=%~f2"
SET "result=NO"

REM Normalize paths (remove trailing slashes)
IF "%child:~-1%"=="\" SET "child=%child:~0,-1%"
IF "%parent:~-1%"=="\" SET "parent=%parent:~0,-1%"

CALL SET "parent_uppercased=%%parent%%"
CALL SET "child_uppercased=%%child%%"

ECHO %child_uppercased% | FINDSTR /I /B /C:"%parent_uppercased%" >NUL
IF NOT ERRORLEVEL 1 SET "result=YES"

SET "%~3=%result%"
GOTO :EOF
