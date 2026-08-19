@echo off
rem Build 01_hello.bas against the static LCUI (single-exe, no LCUI DLLs)
setlocal
set HERE=%~dp0
set FBC64=D:\ProgramData\VisualFreeBasic6.1.0.3\Compile\FreeBASIC-1.10.1-winlibs-gcc-9.3.0\fbc64.exe
set LCUI_LIB=%HERE%lib\win64

pushd "%HERE%"
"%FBC64%" -p "%LCUI_LIB%" -l gdi32 -l shell32 -l imm32 -x 01_hello.exe 01_hello.bas
if errorlevel 1 goto :end

echo.
echo Built: 01_hello.exe  (static - no LCUI DLLs needed, close the LCUI Display window to exit)
:end
popd
endlocal
