@echo off
setlocal

set "PROJECT_ROOT=%~dp0.."
set "GODOT_EXE=C:\Users\luz graciela\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe"
set "PRESET=Web QA"

if not exist "%PROJECT_ROOT%\builds\web" mkdir "%PROJECT_ROOT%\builds\web"

pushd "%PROJECT_ROOT%"
"%GODOT_EXE%" --headless --path "%PROJECT_ROOT%" --export-release "%PRESET%" "%PROJECT_ROOT%\builds\web\index.html"
set "EXPORT_ERROR=%ERRORLEVEL%"
popd

if not "%EXPORT_ERROR%"=="0" (
    echo ERROR: exportacion fallida.
    exit /b %EXPORT_ERROR%
)

echo Exportacion Web Release completada.
exit /b 0
