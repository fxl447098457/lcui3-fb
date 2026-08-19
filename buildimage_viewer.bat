@echo off
rem Build 01_hello.bas against the static LCUI (32-bit, single-exe, no LCUI DLLs)
setlocal
set HERE=%~dp0
set FBC32=D:\ProgramData\VisualFreeBasic6.1.0.3\Compile\FreeBASIC-1.10.1-winlibs-gcc-9.3.0\fbc32.exe
set LCUI_LIB=%HERE%lib\win32

pushd "%HERE%"
"%FBC32%" -p "%LCUI_LIB%" -l gdi32 -l shell32 -l imm32 -x 01_hello32.exe 01_hello.bas
if errorlevel 1 goto :end

echo.
echo Built: 01_hello32.exe  (static 32-bit - no LCUI DLLs needed, close the LCUI Display window to exit)
:end
popd
endlocal
