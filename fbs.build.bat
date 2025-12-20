@ECHO OFF
REM ==================================================================
REM  Forgescript Build System
REM  Author: Tuomo Kanniainen
REM  License: MIT (see LICENSE file)
REM ==================================================================

REM TODO Add log initialize to top, get rid of echoes
REM TODO Edit :READ_KEY_VAL_PAIRS_FROM_FILE so that it can be used with the clean labels (no conf_ prefix)

SETLOCAL EnableDelayedExpansion
ECHO [SCRIPT] Running from: %~f0

REM === Ensure we're in script dir ===
CD /D "%~dp0" || ECHO "Failed to change to script directory"

REM ===== Create a timestamp =====
CALL :MAKETIMESTAMP timestamp

REM IMPORTANT: DO NOT EDIT THESE or it can lead to stale/lost data when cleaning up project
SET "forgescript_path=%~dp0forgescript\"
SET "forgescript_log_file_name=forgescript_build_%timestamp%.log"
SET "forgescript_last_build_info_file_name=fbs_build.info"
SET "forgescript_build_conf_file_name=fbs_build.conf"

REM ===== DEFAULT (Low  precedence: can be overwritten by CUSTOM, config file, or cmd args) =====
SET "default_build_type=debug"
SET "default_src_dir=%~dp0"
SET "default_build_dir=%~dp0build\"
SET "default_output_name=program.exe"
SET "default_log_dir=%forgescript_path%log\"
SET "default_include_dirs=%~dp0include w spaces\;%~dp0include2\"

REM ===== CONFIG FILE (Mid precedence: can be overwritten by cmd args) =====
SET "conf_build_type="
SET "conf_src_dir="
SET "conf_build_dir="
SET "conf_output_name="
SET "conf_log_dir="
SET "conf_include_dirs="

REM ===== CMD (High precedence: cannot be overwritten) =====
SET "cmd_build_type="
SET "cmd_src_dir="
SET "cmd_build_dir="
SET "cmd_output_name="
SET "cmd_log_dir="
SET "cmd_include_dirs="

REM === Parse config file ===
CALL :READ_KEY_VAL_PAIRS_FROM_FILE "%forgescript_path%%forgescript_build_conf_file_name%"

REM === Parse command-line arguments ===
:PARSE_ARGS
IF "%~1"=="" GOTO :ARGS_DONE
SET "arg=%~1"
REM TODO FIX: CLEANING FLAG BUGGED --> BUILD DIR DOES NOT EXIST YET
:: Handle flags
IF /I "%arg%"=="--debug"         SET "cmd_build_type=debug"       & SHIFT & GOTO :PARSE_ARGS
IF /I "%arg%"=="--release"       SET "cmd_build_type=release"     & SHIFT & GOTO :PARSE_ARGS
IF /I "%arg%"=="--run"           SET "run_after_build=1"          & SHIFT & GOTO :PARSE_ARGS
IF /I "%arg%"=="--clean-logs"    CALL :CLEAN_LOGS                  & EXIT /B 0
IF /I "%arg%"=="--clean-build"   CALL :CLEAN_BUILD                 & EXIT /B 0
IF /I "%arg%"=="--clean"         CALL :CLEAN_BUILD & CALL :CLEAN_LOGS & EXIT /B 0

:: Unknown flag
ECHO "%arg%" | FINDSTR /B /I /C:"--" >NUL
IF NOT ERRORLEVEL 1 (
    ECHO "Unknown flag: %arg%"
    SHIFT
    GOTO :PARSE_ARGS
)

::Handle key:value
ECHO "%arg%" | FINDSTR /C:":" >NUL
IF ERRORLEVEL 1 (
    ECHO "Unknown argument: %arg% (use key:value)" & SHIFT & GOTO :PARSE_ARGS
)

:: Split on first ':' 
FOR /F "tokens=1,* delims=:" %%A IN ("%arg%") DO (
    SET "cmd_arg_key=%%A"
    SET "cmd_arg_val=%%B"
)

:: Remove surrounding quotes from key and value if present
CALL :STRIP_QUOTES_VAR cmd_arg_key
CALL :STRIP_QUOTES_VAR cmd_arg_val

::Map key to custom variable
IF /I "!cmd_arg_key!"=="src_dir"        SET "cmd_src_dir=!cmd_arg_val!"
IF /I "!cmd_arg_key!"=="build_dir"      SET "cmd_build_dir=!cmd_arg_val!"
IF /I "!cmd_arg_key!"=="output_name"    SET "cmd_output_name=!cmd_arg_val!"
IF /I "!cmd_arg_key!"=="log_dir"        SET "cmd_log_dir=!cmd_arg_val!"
IF /I "!cmd_arg_key!"=="include_dirs"   SET "cmd_include_dirs=!cmd_arg_val!"
SHIFT
GOTO :PARSE_ARGS
:ARGS_DONE

REM === Set variables to cmd var > custom var > default var ===
CALL :SETOR build_type     cmd_build_type     conf_build_type     default_build_type
CALL :SETOR src_dir        cmd_src_dir        conf_src_dir        default_src_dir
CALL :SETOR build_dir      cmd_build_dir      conf_build_dir      default_build_dir
CALL :SETOR output_name    cmd_output_name    conf_output_name    default_output_name
CALL :SETOR log_dir        cmd_log_dir        conf_log_dir        default_log_dir
CALL :SETOR include_dirs   cmd_include_dirs   conf_include_dirs   default_include_dirs

REM === Create folders if they do not exist
:: Create forgescript settings directory
IF NOT EXIST "%forgescript_path%" MKDIR "%forgescript_path%" 2>NUL

:: Create build directory
IF NOT EXIST "%build_dir%" MKDIR "%build_dir%" 2>NUL

:: Create source directory
IF NOT EXIST "%src_dir%" MKDIR "%src_dir%" 2>NUL

:: Create log directory
IF NOT EXIST "%log_dir%" MKDIR "%log_dir%" 2>NUL

:: Create include directories
SET "list=!include_dirs!"
:CREATE_INCLUDE_DIRS_LOOP
IF NOT DEFINED list GOTO :CREATE_INCLUDE_DIRS_LOOP_DONE
:: Split off the first path (%%A) and keep the rest (%%B)
FOR /F "tokens=1,* delims=;" %%A IN ("!list!") DO (
    :: include_dirs should contain paths that are not quoted
    SET "clean_path=%%A"

    :: Create directory
    IF NOT EXIST "!clean_path!" MKDIR "!clean_path!" 2>NUL

    :: Prepare the remaining part for next iteration
    SET "list=%%B"
)
GOTO :CREATE_INCLUDE_DIRS_LOOP
:CREATE_INCLUDE_DIRS_LOOP_DONE

REM === Save current build config ===
ECHO build_type:%build_type%> "%forgescript_path%%forgescript_last_build_info_file_name%"
ECHO src_dir:%src_dir%>> "%forgescript_path%%forgescript_last_build_info_file_name%"
ECHO build_dir:%build_dir%>> "%forgescript_path%%forgescript_last_build_info_file_name%"
ECHO output_name:%output_name%>> "%forgescript_path%%forgescript_last_build_info_file_name%"
ECHO log_dir:%log_dir%>> "%forgescript_path%%forgescript_last_build_info_file_name%"
ECHO include_dirs:%include_dirs%>> "%forgescript_path%%forgescript_last_build_info_file_name%"

REM === Initialize log ===
(
    ECHO.
    ECHO ========================================
    ECHO  BUILD STARTED: %DATE% %TIME%
    ECHO  Script: %~f0
    ECHO  Build: %build_type%
    ECHO  src_dir: %src_dir%
    ECHO  build_dir: %build_dir%
    ECHO  output_name: %output_name%
    ECHO  log_dir: %log_dir%
    ECHO  include_dirs: %include_dirs%
    ECHO ========================================
    ECHO.
) > "%log_dir%%forgescript_log_file_name%"

GOTO :MAIN

REM === Clean the build directory ===
:CLEAN_BUILD
REM TODO READ THE LAST BUILD INFO FILE AND ASSIGN TO THE build_dir etc. variables
IF NOT EXIST "%build_dir%" GOTO :EOF
ECHO "Cleaning build directory: %build_dir%..."
CALL :IS_SUBDIR "%build_dir%" "%~dp0" is_safe
IF /I "%is_safe%"=="YES" (
    ECHO "Cleaning project-local build files: %build_dir%"
    DEL /Q /F "%build_dir%%output_name%" 2>NUL
    DEL /Q /F "%build_dir%%output_name%.exe" 2>NUL
    DEL /Q /F "%build_dir%%output_name%.ilk" 2>NUL
    DEL /Q /F "%build_dir%%output_name%.pdb" 2>NUL
) ELSE IF DEFINED force_clean (
    ECHO "FORCE: Cleaning external build dir: %build_dir%"
    DEL /Q /F "%build_dir%%output_name%" 2>NUL
    DEL /Q /F "%build_dir%%output_name%.exe" 2>NUL
    DEL /Q /F "%build_dir%%output_name%.ilk" 2>NUL
    DEL /Q /F "%build_dir%%output_name%.pdb" 2>NUL
) ELSE (
    ECHO "build_dir outside project. Use --clean --force to clean."
)
CALL :LOG INFO "Done."
GOTO :EOF

REM === Clean the log directory ===
:CLEAN_LOGS
REM TODO READ THE LAST BUILD INFO FILE AND ASSIGN TO THE build_dir etc. variables
IF NOT EXIST "%log_dir%" GOTO :EOF
ECHO "Cleaning log directory: %log_dir%..."
CALL :IS_SUBDIR "%log_dir%" "%~dp0" is_safe
IF /I "%is_safe%"=="YES" (
    ECHO "Cleaning project-local logs: %log_dir%"
    DEL /Q /F "%log_dir%forgescript_build_*.log" 2>NUL
) ELSE IF DEFINED force_clean (
    ECHO "FORCE: Cleaning external log dir: %log_dir%"
    DEL /Q /F "%log_dir%forgescript_build_*.log" 2>NUL
) ELSE (
    ECHO "log_dir outside project. Use --clean --force to clean."
)
CALL :LOG INFO "Done."
GOTO :EOF

REM === Logging Function ===
:LOG
SET "level=%~1"
SET "msg=%~2"
SET "log_line=[%timestamp%] [%level%] %msg%"
ECHO !log_line!
ECHO !log_line! >> "%log_dir%%forgescript_log_file_name%"
IF /I "%level%"=="ERROR" (
    EXIT /B 1
)
EXIT /B 0

:MAIN
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

REM Collect the include dirs
SET "list=!include_dirs!"
:INCLUDE_DIR_LOOP
IF NOT DEFINED list GOTO :INCLUDE_DIR_LOOP_DONE
:: Split off the first path (%%A) and keep the rest (%%B)
FOR /F "tokens=1,* delims=;" %%A IN ("!list!") DO (
    :: include_dirs should contain paths that are not quoted
    set "clean_path=%%A"

    :: Remove trailing backslash if present
    IF "!clean_path:~-1!"=="\" SET "clean_path=!clean_path:~0,-1!"

    :: Quote the path properly
    SET "quoted_path="!clean_path!""

    ECHO include_dir after trim and quotation: !quoted_path!

    :: Append to the final argument list
    SET "include_dirs_with_compiler_arg_prefixes=!include_dirs_with_compiler_arg_prefixes! -I!quoted_path!"

    :: Prepare the remaining part for next iteration
    SET "list=%%B"
)
GOTO :INCLUDE_DIR_LOOP
:INCLUDE_DIR_LOOP_DONE

REM Remove leading space
IF DEFINED include_dirs_with_compiler_arg_prefixes SET "include_dirs_with_compiler_arg_prefixes=!include_dirs_with_compiler_arg_prefixes:~1!"

REM Compile 
CALL :LOG INFO "Compiling: !src_files!"
CALL :LOG INFO "Output: %build_dir%%output_name%"

clang++ -g -O0 -Wall ^
    !include_dirs_with_compiler_arg_prefixes!^
    !src_files! ^
    -o "%build_dir%%output_name%" ^
    2>> "%log_dir%%forgescript_log_file_name%"

IF !ERRORLEVEL! NEQ 0 (
    CALL :LOG ERROR "Compilation failed! See '%log_dir%%forgescript_log_file_name%' for details"
) ELSE (
    CALL :LOG SUCCESS "Build completed successfully: %build_dir%%output_name%"
)

ENDLOCAL
EXIT /B 0

:SETOR
:: Set target = cmd var > conf var > default var
:: %1 = target
:: %2 = cmd var
:: %3 = conf var
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

:: Normalize paths (remove trailing slashes)
IF "%child:~-1%"=="\" SET "child=%child:~0,-1%"
IF "%parent:~-1%"=="\" SET "parent=%parent:~0,-1%"

CALL SET "parent_uppercased=%%parent%%"
CALL SET "child_uppercased=%%child%%"

ECHO %child_uppercased% | FINDSTR /I /B /C:"%parent_uppercased%" >NUL
IF NOT ERRORLEVEL 1 SET "result=YES"

SET "%~3=%result%"
GOTO :EOF

:READ_KEY_VAL_PAIRS_FROM_FILE
SET "fpath=%~f1"
IF NOT EXIST "%fpath%" (
    ECHO No config file found: %fpath%
    GOTO :EOF
)

FOR /F "usebackq tokens=1* delims=:" %%A IN ("%fpath%") DO (
    SET "key=%%A"
    SET "value=%%B"
    CALL :PROCESS_KEY_VAL key value
)
GOTO :EOF

:PROCESS_KEY_VAL
IF NOT DEFINED value (
    REM Skip lines without value  do nothing
) ELSE (
    REM Trim key
    FOR /F "tokens=*" %%K IN ("!key!") DO SET "key=%%K"

    REM Trim value
    FOR /F "tokens=*" %%V IN ("!value!") DO SET "value=%%V"

    REM Remove surrounding quotes from value
    IF "!value:~0,1!"=="""" SET "value=!value:~1,-1!"

    REM Safe assignment
    ENDLOCAL
    SET "conf_!key!=!value!"
    SETLOCAL EnableDelayedExpansion
)
GOTO :EOF

:STRIP_QUOTES_VAR
:: %1 = variable name to modify in place
FOR %%Q IN ("!%~1!") DO SET "%~1=%%~Q"
GOTO :EOF
