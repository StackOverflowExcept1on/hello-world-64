@echo off

REM main.o will contain machine code
nasm main.asm -o main.o

REM locate MSVC build tools
set vswhere="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
for /f "usebackq tokens=*" %%i in (``) do (
    if exist "%%i" set dir=%%i
)

set vswhere="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set vcvarsLookup=call %vswhere% -latest -property installationPath

for /f "tokens=*" %%i in ('%vcvarsLookup%') do set vcvars="%%i\VC\Auxiliary\Build\vcvars64.bat"

call %vcvars%

REM making valid exe file from asm
nasm -f win64 main.asm && link main.obj /SUBSYSTEM:CONSOLE /ENTRY:_start /SECTION:.text,RWE
ndisasm -b64 main.o

REM run exe
main.exe || echo err
