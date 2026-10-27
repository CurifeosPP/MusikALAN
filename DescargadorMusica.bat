@echo off
rem ================================================================
rem  MUSIKALAN - instalador y lanzador todo-en-uno (antes Descargador de Musica)
rem  ----------------------------------------------------------------
rem  Este unico archivo .bat:
rem    [1] Restaura la aplicacion (script Python embebido en base64)
rem    [2] Comprueba Python 3.9+ con Tkinter; si falta, descarga un
rem        Python portatil COMPLETO dentro de la carpeta de datos
rem        %APPDATA%\MusikALAN\runtime (sin permisos de administrador;
rem        incluye la interfaz grafica)
rem    [3] Instala yt-dlp y mutagen con pip si no estan
rem    [4] Comprueba FFmpeg ; si falta, lo descarga de los espejos
rem        rapidos de GitHub (GyanD / BtbN) y de gyan.dev de reserva
rem    [5] Abre la ventana de descargas (YouTube Downloader)
rem  Requisitos: Windows 10 1803 o superior. Internet solo la primera vez.
rem  Desde la v2.4 todo se instala en %APPDATA%\MusikALAN aunque el .bat
rem  este en Descargas; una instalacion vieja junto al .bat se mueve sola.
rem  Parametro opcional:  --reinstalar   (vuelve a extraer descargador.py)
rem  NOTA: este archivo debe ser ASCII puro y CRLF (no tocar a mano).
rem ================================================================
setlocal EnableExtensions
title MusikALAN v2.9
cd /d "%~dp0"

rem --- carpeta de datos del programa: %APPDATA%\MusikALAN ---
rem Desde la v2.4 los componentes (script, Python, FFmpeg) se guardan en
rem AppData, NO junto al .bat, para no llenar la carpeta de Descargas.
set "APPDIR=%~dp0"
if defined APPDATA set "APPDIR=%APPDATA%\MusikALAN\"
if not exist "%APPDIR%" mkdir "%APPDIR%" 2>nul
if not exist "%APPDIR%" set "APPDIR=%~dp0"
set "RUNTIME=%APPDIR%runtime"
set "FFDIR=%APPDIR%ffmpeg"
set "SCRIPT=%APPDIR%descargador.py"
set "TMPDIR=%APPDIR%_instalacion_tmp"
set "PYEXE="
set "PYARGS="
set "GUIEXE="
set "GUIARGS="

rem --- arquitectura del equipo (para elegir la descarga correcta) ---
set "ARCH=%PROCESSOR_ARCHITECTURE%"
if defined PROCESSOR_ARCHITEW6432 set "ARCH=%PROCESSOR_ARCHITEW6432%"

if not exist "%TMPDIR%" mkdir "%TMPDIR%"

rem --- capturar el caracter ESC y activar colores ANSI (Windows 10+) ---
rem Si no se logra, las variables C_* quedan vacias y el texto sale
rem plano pero funcional (degradacion segura, nunca se corta el flujo).
set "ESC="
for /f "delims=" %%E in ('forfiles /m "%~nx0" /c "cmd /c echo 0x1B" 2^>nul') do set "ESC=%%E"
set "C_FIN="
set "C_TIT="
set "C_OK="
set "C_INFO="
set "C_AVI="
set "C_ERR="
set "C_GRI="
if defined ESC (
    set "C_FIN=%ESC%[0m"
    set "C_TIT=%ESC%[1;96m"
    set "C_OK=%ESC%[92m"
    set "C_INFO=%ESC%[96m"
    set "C_AVI=%ESC%[93m"
    set "C_ERR=%ESC%[1;91m"
    set "C_GRI=%ESC%[90m"
    color 0F
) else (
    color 0B
)
set "TINI=%time: =0%"

cls
echo.
echo  %C_TIT% __  __ _   _ ___ ___ _  __   _   _      _   _  _%C_FIN%
echo  %C_TIT%^|  \/  ^| ^| ^| / __^|_ _^| ^|/ /  /_\ ^| ^|    /_\ ^| \^| ^|%C_FIN%
echo  %C_TIT%^| ^|\/^| ^| ^|_^| \__ \^| ^|^| ' ^<  / _ \^| ^|__ / _ \^| .` ^|%C_FIN%
echo  %C_TIT%^|_^|  ^|_^|\___/^|___/___^|_^|\_\/_/ \_\____/_/ \_\_^|\_^|%C_FIN%
echo.
echo   %C_GRI%--------------------------------------------------------------------%C_FIN%
echo    %C_TIT%MusikALAN v2.9%C_FIN% - preparando el entorno
echo    Instalador portable: no pide permisos de administrador.
echo    Si falta algo (Python, yt-dlp, FFmpeg) se descarga e instala aqui.
echo   %C_GRI%--------------------------------------------------------------------%C_FIN%
echo    Sistema : Windows 10 o superior, %ARCH%
echo    Datos   : %APPDIR%
echo    Musica  : las canciones se guardan en tu carpeta de Musica
echo.

rem --- migracion: si hay una instalacion antigua junto al .bat, se
rem     mueve a la carpeta de datos para no descargarla otra vez ---
if not exist "%SCRIPT%" if exist "%~dp0descargador.py" move /y "%~dp0descargador.py" "%SCRIPT%" >nul 2>nul
if not exist "%APPDIR%ajustes.json" if exist "%~dp0ajustes.json" move /y "%~dp0ajustes.json" "%APPDIR%ajustes.json" >nul 2>nul
if not exist "%RUNTIME%\python\python.exe" if exist "%~dp0runtime" call :migrar_carpeta "%~dp0runtime" "%RUNTIME%" "%RUNTIME%\python\python.exe"
if not exist "%FFDIR%\bin\ffmpeg.exe" if exist "%~dp0ffmpeg" call :migrar_carpeta "%~dp0ffmpeg" "%FFDIR%" "%FFDIR%\bin\ffmpeg.exe"
if exist "%~dp0_instalacion_tmp" rmdir /s /q "%~dp0_instalacion_tmp" 2>nul

echo  %C_INFO%[1/5]%C_FIN% %C_TIT%Preparando la aplicacion%C_FIN% (script embebido)...
if "%~1"=="--reinstalar" if exist "%SCRIPT%" del /q "%SCRIPT%"
if exist "%SCRIPT%" goto script_listo
for /f "tokens=1 delims=:" %%a in ('findstr /b /c:":::" "%~f0"') do >>"%TMPDIR%\payload.b64" echo(%%a
certutil -f -decode "%TMPDIR%\payload.b64" "%SCRIPT%" >nul 2>nul
if errorlevel 1 goto err_payload
del /q "%TMPDIR%\payload.b64" >nul 2>nul
echo    %C_OK%OK%C_FIN% descargador.py restaurado del instalador.
goto script_listo

:err_payload
echo    %C_ERR%ERROR%C_FIN% no se pudo extraer el script embebido.
echo    Vuelve a descargar el archivo DescargadorMusica.bat completo
echo    (se pudo cortar al copiarlo o enviarlo).
goto fin_error

:script_listo
echo  %C_INFO%[2/5]%C_FIN% %C_TIT%Buscando Python%C_FIN% con soporte de interfaz grafica...
if exist "%RUNTIME%\python\python.exe" goto py_portatil
py -3 -c "import sys,tkinter;sys.exit(not sys.version_info>=(3,9))" >nul 2>nul
if not errorlevel 1 goto py_sys_py
python -c "import sys,tkinter;sys.exit(not sys.version_info>=(3,9))" >nul 2>nul
if not errorlevel 1 goto py_sys_plain
call :instalar_python
if errorlevel 1 goto fin_error
goto py_listo

:py_portatil
set "PYEXE=%RUNTIME%\python\python.exe"
set "PYARGS="
set "GUIEXE=%RUNTIME%\python\pythonw.exe"
set "GUIARGS="
echo    %C_OK%OK%C_FIN% Python portatil propio (carpeta runtime).
goto py_listo

:py_sys_py
set "PYEXE=py"
set "PYARGS=-3"
set "GUIEXE="
set "GUIARGS="
pyw -3 -c "import tkinter" >nul 2>nul
if errorlevel 1 goto py_sys_py_fin
set "GUIEXE=pyw"
set "GUIARGS=-3"
:py_sys_py_fin
echo    %C_OK%OK%C_FIN% Python del sistema encontrado (py launcher).
goto py_listo

:py_sys_plain
set "PYEXE=python"
set "PYARGS="
set "GUIEXE="
set "GUIARGS="
pythonw -c "import tkinter" >nul 2>nul
if errorlevel 1 goto py_plain_busca
set "GUIEXE=pythonw"
goto py_plain_fin
:py_plain_busca
set "PYSYS="
for /f "delims=" %%P in ('python -c "import sys, os; print(os.path.dirname(sys.executable))" 2^>nul') do set "PYSYS=%%P"
if defined PYSYS if exist "%PYSYS%\pythonw.exe" set "GUIEXE=%PYSYS%\pythonw.exe"
:py_plain_fin
echo    %C_OK%OK%C_FIN% Python del sistema encontrado.
goto py_listo

:py_listo
echo  %C_INFO%[3/5]%C_FIN% %C_TIT%Verificando yt-dlp y mutagen%C_FIN%...
"%PYEXE%" %PYARGS% -c "import pip" >nul 2>nul
if errorlevel 1 "%PYEXE%" %PYARGS% -m ensurepip --upgrade >nul 2>nul
"%PYEXE%" %PYARGS% -c "import yt_dlp, mutagen" >nul 2>nul
if not errorlevel 1 goto ytdlp_ok
echo    Instalando yt-dlp y mutagen (solo la primera vez, un momento)...
"%PYEXE%" %PYARGS% -m pip install --upgrade --no-warn-script-location yt-dlp mutagen
if not errorlevel 1 goto ytdlp_ok
echo    %C_AVI%Aviso%C_FIN% reintentando con instalacion por usuario...
"%PYEXE%" %PYARGS% -m pip install --upgrade --user --no-warn-script-location yt-dlp mutagen
if not errorlevel 1 goto ytdlp_ok
echo    %C_ERR%ERROR%C_FIN% no se pudo instalar yt-dlp. Revisa tu conexion a internet.
goto fin_error

:ytdlp_ok
echo    %C_OK%OK%C_FIN% yt-dlp y mutagen listos.

echo  %C_INFO%[4/5]%C_FIN% %C_TIT%Buscando FFmpeg%C_FIN%...
if exist "%FFDIR%\bin\ffmpeg.exe" goto ff_local
ffmpeg -version >nul 2>nul
if not errorlevel 1 goto ff_sistema
call :instalar_ffmpeg
if errorlevel 1 goto fin_error

:ff_local
set "PATH=%FFDIR%\bin;%PATH%"
echo    %C_OK%OK%C_FIN% FFmpeg listo (carpeta ffmpeg\bin).
goto ff_listo

:ff_sistema
echo    %C_OK%OK%C_FIN% FFmpeg del sistema encontrado.
:ff_listo

echo  %C_INFO%[5/5]%C_FIN% %C_TIT%Todo listo%C_FIN% - abriendo la aplicacion...
rmdir /s /q "%TMPDIR%" >nul 2>nul
set "TEND=%time: =0%"
set /a "ELA_I=((1%TINI:~0,2%-100)*360000)+((1%TINI:~3,2%-100)*6000)+((1%TINI:~6,2%-100)*100)+(1%TINI:~9,2%-100)" 2>nul
set /a "ELA_T=((1%TEND:~0,2%-100)*360000)+((1%TEND:~3,2%-100)*6000)+((1%TEND:~6,2%-100)*100)+(1%TEND:~9,2%-100)" 2>nul
if defined ELA_I if defined ELA_T set /a "SEG=(ELA_T-ELA_I)/100" 2>nul
set "SEG_TXT="
if defined SEG if %SEG% GTR 0 set "SEG_TXT=   (tardo %SEG% segundos)"
echo.
echo   %C_GRI%--------------------------------------------------------------------%C_FIN%
echo   %C_OK%Instalacion completada%C_FIN%%SEG_TXT%
echo   El programa vive en: %APPDIR%
echo   La musica se guarda en tu carpeta de Musica.
echo   La ventana de descargas se abre a continuacion.
echo   %C_GRI%--------------------------------------------------------------------%C_FIN%
echo.
title MusikALAN v2.9 - YouTube a AAC/MP3/FLAC/WAV/WMA/AVI
if defined GUIEXE goto lanzar_gui
echo    %C_AVI%Aviso%C_FIN% este equipo no ofrece ventana independiente;
echo    deja esta consola abierta mientras uses el programa.
"%PYEXE%" %PYARGS% "%SCRIPT%"
if errorlevel 1 goto fin_error_run
endlocal
exit /b 0

:lanzar_gui
start "" "%GUIEXE%" %GUIARGS% "%SCRIPT%"
endlocal
exit /b 0

:fin_error_run
echo.
echo  %C_ERR%El programa se cerro con un error.%C_FIN% Sugerencias:
echo    - Ejecuta este archivo de nuevo.
echo    - Revisa el archivo descargador_errores.log si existe.
echo    - Borra las carpetas "runtime" y "ffmpeg" que hay dentro de
echo      %APPDIR% y ejecuta este archivo de nuevo.
goto fin_pausa

:fin_error
echo.
echo  %C_ERR%La instalacion no se completo.%C_FIN% Ejecuta este archivo de nuevo
echo  y revisa tu conexion a internet.
:fin_pausa
echo.
pause
exit /b 1

rem ==================== SUBRUTINAS ====================

:instalar_python
echo    %C_AVI%Aviso%C_FIN% Python 3.9+ con Tkinter no encontrado en este PC.
set "PBSARCH=x86_64"
if /i "%ARCH%"=="X86" set "PBSARCH=i686"
if /i "%ARCH%"=="ARM64" goto ip_arm
echo    Descargando Python portatil completo, unos 42 MB, solo la primera vez...
call :Descargar "https://github.com/astral-sh/python-build-standalone/releases/download/20250517/cpython-3.12.10+20250517-%PBSARCH%-pc-windows-msvc-install_only.tar.gz" "%TMPDIR%\python.tar.gz"
if errorlevel 1 goto ip_err_desc
if not exist "%RUNTIME%" mkdir "%RUNTIME%"
echo    Descomprimiendo Python, un momento...
tar -xzf "%TMPDIR%\python.tar.gz" -C "%RUNTIME%"
if errorlevel 1 goto ip_err_tar
del /q "%TMPDIR%\python.tar.gz" >nul 2>nul
if not exist "%RUNTIME%\python\python.exe" goto ip_err_zip
set "PYEXE=%RUNTIME%\python\python.exe"
set "PYARGS="
set "GUIEXE=%RUNTIME%\python\pythonw.exe"
set "GUIARGS="
echo    %C_OK%OK%C_FIN% Python portatil instalado en la carpeta "runtime".
exit /b 0

:ip_arm
echo    Descargando Python ARM64 para Windows, unos 26 MB...
call :Descargar "https://www.python.org/ftp/python/3.12.10/python-3.12.10-arm64.exe" "%TMPDIR%\python-arm64.exe"
if errorlevel 1 goto ip_err_desc
echo    Instalando Python en silencio, un momento...
"%TMPDIR%\python-arm64.exe" /quiet InstallAllUsers=0 TargetDir="%RUNTIME%\python" Include_launcher=0 AssociateFiles=0 Shortcuts=0 PrependPath=0 Include_test=0 Include_doc=0
set "IPEC=%errorlevel%"
if "%IPEC%"=="3010" set "IPEC=0"
del /q "%TMPDIR%\python-arm64.exe" >nul 2>nul
if not "%IPEC%"=="0" goto ip_err_zip
if not exist "%RUNTIME%\python\python.exe" goto ip_err_zip
set "PYEXE=%RUNTIME%\python\python.exe"
set "PYARGS="
set "GUIEXE=%RUNTIME%\python\pythonw.exe"
set "GUIARGS="
echo    %C_OK%OK%C_FIN% Python ARM64 instalado en la carpeta "runtime".
exit /b 0

:ip_err_desc
echo    %C_ERR%ERROR%C_FIN% fallo la descarga. Revisa tu conexion e intentalo de nuevo.
exit /b 1

:ip_err_tar
echo    %C_ERR%ERROR%C_FIN% no se pudo descomprimir Python con tar.
echo    Se necesita Windows 10 version 1803 o mas nueva.
exit /b 1

:ip_err_zip
echo    %C_ERR%ERROR%C_FIN% la instalacion de Python no termino bien.
echo    Borra la carpeta "runtime" y ejecuta este archivo de nuevo.
exit /b 1

:instalar_ffmpeg
echo    %C_AVI%Aviso%C_FIN% FFmpeg no encontrado en este PC.
if /i "%ARCH%"=="ARM64" goto ff_url_arm
if /i "%ARCH%"=="X86" goto ff_url_x86
echo    Descargando FFmpeg 64-bit del espejo rapido de GitHub, unos 90 MB...
call :Descargar "https://github.com/GyanD/codexffmpeg/releases/download/9.0/ffmpeg-9.0-essentials_build.zip" "%TMPDIR%\ffmpeg.zip"
if not errorlevel 1 goto ff_extraer
echo    %C_AVI%Aviso%C_FIN% espejo 1 fallo, probando espejo 2 (GitHub BtbN)...
call :Descargar "https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-gpl.zip" "%TMPDIR%\ffmpeg.zip"
if not errorlevel 1 goto ff_extraer
echo    %C_AVI%Aviso%C_FIN% espejo 2 fallo, probando el servidor clasico (gyan.dev)...
call :Descargar "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" "%TMPDIR%\ffmpeg.zip"
if errorlevel 1 goto ff_err_desc
goto ff_extraer

:ff_url_arm
echo    Descargando FFmpeg para Windows ARM64 (espejo de GitHub)...
call :Descargar "https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-winarm64-gpl.zip" "%TMPDIR%\ffmpeg.zip"
if errorlevel 1 goto ff_err_desc
goto ff_extraer

:ff_url_x86
echo    Descargando FFmpeg para Windows 32-bit (espejo de GitHub)...
call :Descargar "https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win32-gpl.zip" "%TMPDIR%\ffmpeg.zip"
if errorlevel 1 goto ff_err_desc

:ff_extraer
echo    Descomprimiendo FFmpeg, solo unos segundos...
if exist "%TMPDIR%\ffx" rmdir /s /q "%TMPDIR%\ffx"
mkdir "%TMPDIR%\ffx"
call :Extraer "%TMPDIR%\ffmpeg.zip" "%TMPDIR%\ffx"
if errorlevel 1 goto ff_err_zip
if not exist "%FFDIR%" mkdir "%FFDIR%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$d=(Get-ChildItem -LiteralPath '%TMPDIR%\ffx' -Directory | Select-Object -First 1).FullName; Move-Item -LiteralPath (Join-Path $d 'bin') -Destination '%FFDIR%\bin' -Force"
if errorlevel 1 goto ff_err_zip
if not exist "%FFDIR%\bin\ffmpeg.exe" goto ff_err_zip
echo    %C_OK%OK%C_FIN% FFmpeg instalado en la carpeta "ffmpeg".
exit /b 0

:ff_err_desc
echo    %C_ERR%ERROR%C_FIN% fallo la descarga de FFmpeg. Revisa tu conexion.
exit /b 1

:ff_err_zip
echo    %C_ERR%ERROR%C_FIN% no se pudo descomprimir FFmpeg.
exit /b 1

:Descargar
rem  Uso: call :Descargar "URL" "archivo destino"
rem  Usa curl (incluido en Windows 10+) y cae a PowerShell si falta.
where curl >nul 2>nul
if errorlevel 1 goto Descargar_ps
curl -L -f --retry 3 --retry-delay 2 --connect-timeout 20 -o "%~2" "%~1"
if not errorlevel 1 exit /b 0
echo    %C_AVI%Aviso%C_FIN% curl fallo, probando con PowerShell...
:Descargar_ps
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol='Tls12'; (New-Object Net.WebClient).DownloadFile('%~1','%~2')"
exit /b %errorlevel%

:Extraer
rem  Uso: call :Extraer "archivo.zip" "carpeta destino"
rem  Usa tar (incluido en Windows 10+) y cae a PowerShell si falta.
tar -xf "%~1" -C "%~2" >nul 2>nul
if not errorlevel 1 exit /b 0
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%~1' -DestinationPath '%~2' -Force"
exit /b %errorlevel%

:migrar_carpeta
rem  Uso: call :migrar_carpeta "carpeta vieja" "destino nuevo" "archivo clave"
rem  Mueve una instalacion antigua (la que quedo junto al .bat) hacia la
rem  carpeta de datos de AppData. Si algo falla, el flujo normal la
rem  descargara de cero sin quejarse.
if exist "%~3" exit /b 0
if not exist "%~1" exit /b 0
echo    %C_INFO%Moviendo%C_FIN% la carpeta "%~nx1" a su nueva ubicacion...
if not exist "%~2" move "%~1" "%~2" >nul 2>nul
if exist "%~3" goto migrar_fin
robocopy "%~1" "%~2" /e /move /nfl /ndl /njh /njs >nul 2>nul
if not exist "%~3" exit /b 0
:migrar_fin
rmdir /s /q "%~1" >nul 2>nul
echo    %C_OK%OK%C_FIN% "%~nx1" ya esta en la carpeta de datos.
exit /b 0

rem ============ SCRIPT PYTHON EMBEBIDO (generado; no editar) ============
:::IyEvdXNyL2Jpbi9lbnYgcHl0aG9uMwojIC0qLSBjb2Rpbmc6IHV0Zi04IC0qLQoi
:::IiIKTXVzaWtBTEFOIOKAlCBpbnRlcmZheiBncmFmaWNhIChUa2ludGVyKSBwYXJh
:::IHl0LWRscCArIEZGbXBlZwo9PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
:::PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PQpBcHAgZGUg
:::ZXNjcml0b3JpbyBwYXJhIGRlc2NhcmdhciBtdXNpY2EgeSB2aWRlb3MgZGUgWW91
:::VHViZSBlbiBmb3JtYXRvcwphcHRvcyBwYXJhIHJlcHJvZHVjdG9yZXMgcG9ydGF0
:::aWxlcyBhbnRpZ3VvcyAodGlwbyAic2hlaWp1IiBNUDMgZGUgMS44IgpwdWxnYWRh
:::cyB5IHBhbnRhbGxhIDEyOHgxNjApOgoKICDCtyBBQUMgICgubTRhKSAgOTYgLyAx
:::Mjgga2JwcwogIMK3IE1QMyAgKC5tcDMpICA5NiAvIDEyOCAvIDE5MiAvIDI1NiAv
:::IDMyMCBrYnBzIChkZXNwbGVnYWJsZSAiQ2FsaWRhZCIpCiAgwrcgRkxBQyAoLmZs
:::YWMpIHNpbiBwZXJkaWRhCiAgwrcgV0FWICAoLndhdikgIHNpbiBwZXJkaWRhIChh
:::cmNoaXZvcyBncmFuZGVzKQogIMK3IFdNQSAgKC53bWEpICA5NiAvIDEyOCBrYnBz
:::IChjb2RpZmljYWRvciB3bWF2MiBkZSBGRm1wZWcsIGNvbiBjYXJhdHVsYQogICAg
:::ICAgICAgICAgICAgIHkgVVJMIGluY3J1c3RhZGFzIHZpYSBtdXRhZ2VuOiBXTS9Q
:::aWN0dXJlICsgV00vQXV0aG9yVVJMKQogIMK3IEFWSSAgKC5hdmkpICB2aWRlbyBy
:::ZWNvZGlmaWNhZG8gcGFyYSBlbCByZXByb2R1Y3RvciBzaGVpanUgMS44IgogICAg
:::ICAgICAgICAgICAgIDEyOHgxNjAsIGNvbiBsb3MgcGFyYW1ldHJvcyBvZmljaWFs
:::ZXMgZGVsIHJlcG9zaXRvcmlvCiAgICAgICAgICAgICAgICAgZ2l0aHViLmNvbS9m
:::ZGQ0cy9wb3J0YWJsZV9tcDNfcGxheWVyX3ZpZGVvX2NvbnZlcnRlcl90b29scwog
:::ICAgICAgICAgICAgICAgIChzY3JpcHQgdmlkZW8yc2hlbmp1MTguc2gpCgpMYSBp
:::bnN0YWxhY2lvbiBkZSBQeXRob24sIHl0LWRscCB5IEZGbXBlZyBsYSBoYWNlIGF1
:::dG9tYXRpY2FtZW50ZSBlbAphcmNoaXZvIERlc2NhcmdhZG9yTXVzaWNhLmJhdDsg
:::ZXN0ZSBzY3JpcHQgZXMgbGEgdmVudGFuYSBxdWUgc2UgdXNhIGEKZGlhcmlvICh0
:::ZW1hIG9zY3Vyby9jbGFybywgZXN0aW1hY2lvbiBkZSB0YW1hbm8geSBjb21wcm9i
:::YWRvciBkZQpjYWxpZGFkIGRlIGxhIGNhcnBldGEpLiBMYSBjYXJwZXRhIGRlIGd1
:::YXJkYWRvIHBvciBkZWZlY3RvIGVzIGxhCmNhcnBldGEgTXVzaWNhIGRlIFdpbmRv
:::d3MsIHkgbG9zIGFyY2hpdm9zIHZhbiBkaXJlY3RvcyBhIGVsbGEsIHNpbgpzdWJj
:::YXJwZXRhcyBwb3IgZm9ybWF0by4gVHJhcyBjYWRhIGRlc2NhcmdhIHNlIGVzY3Jp
:::YmVuIGxhcyBldGlxdWV0YXMKZGVsIGFyY2hpdm8gKGFydGlzdGEgc2luIGVsIHN1
:::ZmlqbyAiIC0gVG9waWMiLCBhbGJ1bSwgdGl0dWxvLCBhbm8sIFVSTCkKZW4gZWwg
:::TUlTTU8gZm9ybWF0byBiaW5hcmlvIHF1ZSB1c2EgRkZtcGVnIGVuIGxvcyBNUDMg
:::cXVlIGxvcwpyZXByb2R1Y3RvcmVzIGJhcmF0b3MgU0kgbGVlbiAoSUQzdjIuNCAr
:::IHRleHRvcyBVVEYtMTYgY29uIEJPTSwKdmVyaWZpY2FkbyBjb250cmEgdW4gTVAz
:::IHJlYWwgZGVzY2FyZ2FkbyBjb24gU25hcHR1YmUpLCB5IGxhIGNhcmF0dWxhClNJ
:::RU1QUkUgc2UgaW5jcnVzdGEgZW4gSlBFRzogbGEgbWluaWF0dXJhIGRlIFlvdVR1
:::YmUgdmllbmUgZW4gV2ViUCB5Cm11Y2hvcyByZXByb2R1Y3RvcmVzIHNvbG8gbGVl
:::biBKUEVHIChpZ3VhbCBxdWUgLS1jb252ZXJ0LXRodW1ibmFpbHMKanBnIGRlbCBj
:::b21hbmRvIGFudGlndW8sIHF1ZSBlcyBsbyBxdWUgc2kgZnVuY2lvbmFiYSkuCgpE
:::ZXNkZSBsYSB2Mi43IFRPRE9TIGxvcyBmb3JtYXRvcyBsbGV2YW4gbGFzIGV0aXF1
:::ZXRhcyBlbiBzdSBmb3JtYQplc3RhbmRhciB5IHZlcmlmaWNhZGE6IElEM3YyLjQg
:::KyBVVEYtMTYgZW4gLm1wMywgYXRvbW9zIE1QNCAowqluYW0sCsKpQVJULCDCqWFs
:::YiwgY292ci4uLikgZW4gLm00YSBjb21vIGlUdW5lcywgSUQzIGRlbnRybyBkZWwg
:::UklGRiBlbgoud2F2LCBWb3JiaXMgKyBQaWN0dXJlIGVuIC5mbGFjLCBBU0YgKFRp
:::dGxlL0F1dGhvci9XTS8qKSBlbiAud21hIHkKUklGRiBJTkZPIChJTkFNL0lBUlQv
:::SVBSRCkgZW4gLmF2aS4gTGEgY2FyYXR1bGEgc2UgZXNjcmliZSBTSUVNUFJFCmNv
:::biBtdXRhZ2VuLCBudW5jYSB2aWEgRW1iZWRUaHVtYm5haWwgZGUgeXQtZGxwOiBz
:::dXMgbWV0b2RvcwppbnRlcm5vcyBjYW1iaWFuIGVudHJlIHZlcnNpb25lcyB5IGZ1
:::ZXJvbiBsYSBmdWVudGUgZGUgcG9ydGFkYXMKUE5HL21hbCBjb252ZXJ0aWRhcyBx
:::dWUgaGFjaWFuIHF1ZSBsb3MgcmVwcm9kdWN0b3JlcyBiYXJhdG9zCmRlc2NhcnRh
:::cmFuIHRhbWJpZW4gYXJ0aXN0YSB5IGFsYnVtLgoKVXNvOiAgcHl0aG9uIGRlc2Nh
:::cmdhZG9yLnB5ICAgKG8gZG9ibGUgY2xpYyBlbiBEZXNjYXJnYWRvck11c2ljYS5i
:::YXQpClNpIGxhIFVSTCBwZXJ0ZW5lY2UgYSB1bmEgbGlzdGEgZGUgcmVwcm9kdWNj
:::aW9uLCBlbCBwcm9ncmFtYSBwcmVndW50YQpzaSBiYWphciBzb2xvIGxhIGNhbmNp
:::b24gcGVnYWRhIG8gbGEgcGxheWxpc3QgY29tcGxldGEgKGNvbiB1bmEgcGF1c2EK
:::ZGUgMiBzIGVudHJlIGNhbmNpb25lcyBwYXJhIG5vIHNhdHVyYXIgYSBZb3VUdWJl
:::KS4KIiIiCgppbXBvcnQganNvbgppbXBvcnQgb3MKaW1wb3J0IHF1ZXVlCmltcG9y
:::dCByZQppbXBvcnQgc2h1dGlsCmltcG9ydCBzdWJwcm9jZXNzCmltcG9ydCBzeXMK
:::aW1wb3J0IHRlbXBmaWxlCmltcG9ydCB0aHJlYWRpbmcKaW1wb3J0IHRpbWUKaW1w
:::b3J0IHRyYWNlYmFjawpmcm9tIHBhdGhsaWIgaW1wb3J0IFBhdGgKZnJvbSB1cmxs
:::aWIucGFyc2UgaW1wb3J0IHBhcnNlX3FzLCB1cmxlbmNvZGUsIHVybHBhcnNlLCB1
:::cmx1bnBhcnNlCmZyb20gdXJsbGliLnJlcXVlc3QgaW1wb3J0IHVybG9wZW4KCkFQ
:::UF9WID0gJzIuOScKQVBQX0RJUiA9IFBhdGgoX19maWxlX18pLnJlc29sdmUoKS5w
:::YXJlbnQKUlVUQV9BSlVTVEVTID0gQVBQX0RJUiAvICdhanVzdGVzLmpzb24nCkxP
:::R19FUlJPUkVTID0gQVBQX0RJUiAvICdkZXNjYXJnYWRvcl9lcnJvcmVzLmxvZycK
:::CiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLSBzYWxpZGEKIyBBbCBlamVjdXRhcnNlIGNvbiBw
:::eXRob253LmV4ZSAoc2luIGNvbnNvbGEpIHN0ZG91dC9zdGRlcnIgc29uIE5vbmU6
:::CiMgY3VhbHF1aWVyIHByaW50IGZhbGxhcmlhLiBMb3MgcmVkaXJpZ2ltb3MgYSB1
:::biBzaXRpbyBzZWd1cm8uCnRyeToKICAgIGlmIHN5cy5zdGRvdXQgaXMgTm9uZToK
:::ICAgICAgICBzeXMuc3Rkb3V0ID0gb3Blbihvcy5kZXZudWxsLCAndycsIGVuY29k
:::aW5nPSd1dGYtOCcpCmV4Y2VwdCBFeGNlcHRpb246CiAgICBwYXNzCnRyeToKICAg
:::IGlmIHN5cy5zdGRlcnIgaXMgTm9uZToKICAgICAgICBzeXMuc3RkZXJyID0gb3Bl
:::bihMT0dfRVJST1JFUywgJ2EnLCBlbmNvZGluZz0ndXRmLTgnKQpleGNlcHQgRXhj
:::ZXB0aW9uOgogICAgcGFzcwoKCmRlZiBfcmVjb25maWd1cmFyX3NhbGlkYSgpOgog
:::ICAgIiIiRXZpdGEgY3Jhc2hlcyBwb3IgY2FyYWN0ZXJlcyByYXJvcyBzaSBsYSBz
:::YWxpZGEgc2UgcmVkaXJpZ2UuIiIiCiAgICBmb3IgcyBpbiAoc3lzLnN0ZG91dCwg
:::c3lzLnN0ZGVycik6CiAgICAgICAgdHJ5OgogICAgICAgICAgICBpZiBzIGFuZCBo
:::YXNhdHRyKHMsICdyZWNvbmZpZ3VyZScpOgogICAgICAgICAgICAgICAgcy5yZWNv
:::bmZpZ3VyZShlcnJvcnM9J3JlcGxhY2UnKQogICAgICAgIGV4Y2VwdCBFeGNlcHRp
:::b246CiAgICAgICAgICAgIHBhc3MKCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gdGtpbnRl
:::cgp0cnk6CiAgICBpbXBvcnQgdGtpbnRlciBhcyB0awogICAgZnJvbSB0a2ludGVy
:::IGltcG9ydCBmaWxlZGlhbG9nLCBtZXNzYWdlYm94LCB0dGsKICAgIGZyb20gdGtp
:::bnRlci5zY3JvbGxlZHRleHQgaW1wb3J0IFNjcm9sbGVkVGV4dAogICAgVEtfT0sg
:::PSBUcnVlCmV4Y2VwdCBFeGNlcHRpb246CiAgICBUS19PSyA9IEZhbHNlCgoKIyAt
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tIGFqdXN0ZXMKZGVmIF9jYXJwZXRhX211c2ljYSgpOgog
:::ICAgIiIiQ2FycGV0YSAnTXVzaWNhJyByZWFsIGRlbCB1c3VhcmlvIChGT0xERVJJ
:::RF9NdXNpYyBkZSBXaW5kb3dzKS4iIiIKICAgIGlmIG9zLm5hbWUgPT0gJ250JzoK
:::ICAgICAgICB0cnk6CiAgICAgICAgICAgIGltcG9ydCBjdHlwZXMKCiAgICAgICAg
:::ICAgIGNsYXNzIF9HVUlEKGN0eXBlcy5TdHJ1Y3R1cmUpOgogICAgICAgICAgICAg
:::ICAgX2ZpZWxkc18gPSBbKCdEMScsIGN0eXBlcy5jX3Vsb25nKSwgKCdEMicsIGN0
:::eXBlcy5jX3VzaG9ydCksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAoJ0Qz
:::JywgY3R5cGVzLmNfdXNob3J0KSwKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICgnRDQnLCBjdHlwZXMuY191Ynl0ZSAqIDgpXQoKICAgICAgICAgICAgbXVzaWNh
:::ID0gX0dVSUQoMHg0QkQ4RDU3MSwgMHg2RDE5LCAweDQ4RDMsCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgIChjdHlwZXMuY191Ynl0ZSAqIDgpKDB4QkUsIDB4OTcs
:::IDB4MDMsIDB4MzgsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIDB4NUYsIDB4N0YsIDB4QzUsIDB4Q0UpKQogICAgICAgICAg
:::ICBwdHIgPSBjdHlwZXMuY193Y2hhcl9wKCkKICAgICAgICAgICAgaWYgY3R5cGVz
:::LndpbmRsbC5zaGVsbDMyLlNIR2V0S25vd25Gb2xkZXJQYXRoKAogICAgICAgICAg
:::ICAgICAgICAgIGN0eXBlcy5ieXJlZihtdXNpY2EpLCAwLCBOb25lLAogICAgICAg
:::ICAgICAgICAgICAgIGN0eXBlcy5ieXJlZihwdHIpKSA9PSAwIGFuZCBwdHIudmFs
:::dWU6CiAgICAgICAgICAgICAgICBydXRhID0gcHRyLnZhbHVlCiAgICAgICAgICAg
:::ICAgICBjdHlwZXMud2luZGxsLm9sZTMyLkNvVGFza01lbUZyZWUocHRyKQogICAg
:::ICAgICAgICAgICAgcmV0dXJuIHJ1dGEKICAgICAgICBleGNlcHQgRXhjZXB0aW9u
:::OgogICAgICAgICAgICBwYXNzCiAgICByZXR1cm4gc3RyKFBhdGguaG9tZSgpIC8g
:::J011c2ljJykKCgpkZWYgX2Rlc3Rpbm9fYXBwZGF0YV92aWVqbygpOgogICAgIiIi
:::Q2FycGV0YSBkZWwgcHJvZ3JhbWEgKGVyYSBlbCBkZXN0aW5vIHBvciBkZWZlY3Rv
:::IGVuIGxhIHYyLjIpLiIiIgogICAgYmFzZSA9IG9zLmVudmlyb24uZ2V0KCdBUFBE
:::QVRBJykgb3Igc3RyKFBhdGguaG9tZSgpIC8gJ0FwcERhdGEnIC8gJ1JvYW1pbmcn
:::KQogICAgcmV0dXJuIHN0cihQYXRoKGJhc2UpIC8gJ011c2lrQUxBTicpCgoKZGVm
:::IF9kZXN0aW5vX3Bvcl9kZWZlY3RvKCk6CiAgICAiIiJMb3MgYXJjaGl2b3Mgc2Ug
:::Z3VhcmRhbiBlbiBsYSBjYXJwZXRhIE11c2ljYSBkZWwgdXN1YXJpby4iIiIKICAg
:::IHJldHVybiBfY2FycGV0YV9tdXNpY2EoKQoKCkFKVVNURVNfREVGRUNUTyA9IHsK
:::ICAgICdkZXN0aW5vJzogX2Rlc3Rpbm9fcG9yX2RlZmVjdG8oKSwKICAgICd0ZW1h
:::JzogJ09zY3VybycsCiAgICAnZm9ybWF0byc6ICdBQUMnLAogICAgJ2NhbGlkYWQn
:::OiAnMTI4aycsCiAgICAnZW1iZWJlcic6IFRydWUsCiAgICAnY29va2llcyc6ICcn
:::LCAgICAjIHYyLjk6IG5hdmVnYWRvciBjdXlhcyBjb29raWVzIHVzYXIgc2kgWW91
:::VHViZSBibG9xdWVhCn0KCgpkZWYgY2FyZ2FyX2FqdXN0ZXMoKToKICAgIGEgPSBk
:::aWN0KEFKVVNURVNfREVGRUNUTykKICAgIHRyeToKICAgICAgICBhLnVwZGF0ZShq
:::c29uLmxvYWRzKFJVVEFfQUpVU1RFUy5yZWFkX3RleHQoZW5jb2Rpbmc9J3V0Zi04
:::JykpKQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICBwYXNzCiAgICBhLnBv
:::cCgnbmF2ZWdhZG9yJywgTm9uZSkgICMgdjIuMiBvIGFudGVyaW9yOiBsYSBzZWNj
:::aW9uIGRlIGNvb2tpZXMgeWEgbm8gZXhpc3RlCiAgICAjIG1pZ3JhY2lvbmVzIGRl
:::bCBkZXN0aW5vIGRlIGd1YXJkYWRvOgogICAgIyAgwrcgdjIuMC8yLjEgdXNhYmEg
:::TXVzaWMvWVREb3dubG9hZGVyCiAgICAjICDCtyB2Mi4yIHVzYWJhIGxhIGNhcnBl
:::dGEgZGVsIHByb2dyYW1hIChBcHBEYXRhXFJvYW1pbmdcTXVzaWtBTEFOKQogICAg
:::IyBEZXNkZSBsYSB2Mi4zIGVsIGRlc3Rpbm8gcG9yIGRlZmVjdG8gZXMgbGEgY2Fy
:::cGV0YSBNdXNpY2EgZGVsIHVzdWFyaW8sCiAgICAjIGFzaSBxdWUgc2kgZWwgYWp1
:::c3RlIGFwdW50YSBhIGN1YWxxdWllcmEgZGUgbG9zIGRvcywgc2UgYWN0dWFsaXph
:::LgogICAgZGVzdGlubyA9IHN0cihhLmdldCgnZGVzdGlubycpIG9yICcnKS5yZXBs
:::YWNlKCdcXCcsICcvJykucnN0cmlwKCcvJykubG93ZXIoKQogICAgaWYgJ3l0ZG93
:::bmxvYWRlcicgaW4gZGVzdGlubzoKICAgICAgICBhWydkZXN0aW5vJ10gPSBBSlVT
:::VEVTX0RFRkVDVE9bJ2Rlc3Rpbm8nXQogICAgZWxzZToKICAgICAgICB2aWVqbyA9
:::IF9kZXN0aW5vX2FwcGRhdGFfdmllam8oKS5yZXBsYWNlKCdcXCcsICcvJykucnN0
:::cmlwKCcvJykubG93ZXIoKQogICAgICAgIGlmIGRlc3Rpbm8gYW5kIChkZXN0aW5v
:::ID09IHZpZWpvCiAgICAgICAgICAgICAgICAgICAgICAgIG9yIGRlc3Rpbm8uc3Rh
:::cnRzd2l0aCh2aWVqbyArICcvJykpOgogICAgICAgICAgICBhWydkZXN0aW5vJ10g
:::PSBBSlVTVEVTX0RFRkVDVE9bJ2Rlc3Rpbm8nXQogICAgcmV0dXJuIGEKCgpkZWYg
:::Z3VhcmRhcl9hanVzdGVzKCk6CiAgICB0cnk6CiAgICAgICAgUlVUQV9BSlVTVEVT
:::LndyaXRlX3RleHQoCiAgICAgICAgICAgIGpzb24uZHVtcHMoQUpVU1RFUywgZW5z
:::dXJlX2FzY2lpPUZhbHNlLCBpbmRlbnQ9MiksCiAgICAgICAgICAgIGVuY29kaW5n
:::PSd1dGYtOCcpCiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHBhc3MKCgpB
:::SlVTVEVTID0gY2FyZ2FyX2FqdXN0ZXMoKQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSB1
:::dGlscwpkZWYgZm10X3RhbShuKToKICAgIGlmIG5vdCBuOgogICAgICAgIHJldHVy
:::biAn4oCUJwogICAgbiA9IGZsb2F0KG4pCiAgICBmb3IgdSBpbiAoJ0InLCAnS2lC
:::JywgJ01pQicsICdHaUInKToKICAgICAgICBpZiBuIDwgMTAyNCBvciB1ID09ICdH
:::aUInOgogICAgICAgICAgICByZXR1cm4gZid7aW50KG4pfSB7dX0nIGlmIHUgPT0g
:::J0InIGVsc2UgZid7bjouMWZ9IHt1fScKICAgICAgICBuIC89IDEwMjQKCgpkZWYg
:::Zm10X3RpZW0ocyk6CiAgICBpZiBzIGlzIE5vbmU6CiAgICAgICAgcmV0dXJuICfi
:::gJQnCiAgICBzID0gaW50KHMpCiAgICBoLCByID0gZGl2bW9kKHMsIDM2MDApCiAg
:::ICBtLCB4ID0gZGl2bW9kKHIsIDYwKQogICAgcmV0dXJuIGYne2h9OnttOjAyZH06
:::e3g6MDJkfScgaWYgaCBlbHNlIGYne206MDJkfTp7eDowMmR9JwoKCmRlZiBsaW1w
:::aWFyX25vbWJyZSh0KToKICAgIHQgPSByZS5zdWIocidbPD46Ii9cXHw/Klx4MDAt
:::XHgxZl0nLCAnXycsIHN0cih0KSkuc3RyaXAoJyAuJykKICAgIHJldHVybiB0Wzox
:::NTBdIG9yICdzaW5fdGl0dWxvJwoKCmRlZiBzaW5fcGxheWxpc3QodXJsKToKICAg
:::ICIiIlF1aXRhIGVsIHBhcsOhbWV0cm8gbGlzdD0gZGUgbGEgVVJMIChtb2RvIHNv
:::bG8gdmlkZW8pLiIiIgogICAgdHJ5OgogICAgICAgIHAgPSB1cmxwYXJzZSh1cmwp
:::CiAgICAgICAgcSA9IHBhcnNlX3FzKHAucXVlcnkpCiAgICAgICAgaWYgJ2xpc3Qn
:::IGluIHE6CiAgICAgICAgICAgIGRlbCBxWydsaXN0J10KICAgICAgICAgICAgcmV0
:::dXJuIHVybHVucGFyc2UocC5fcmVwbGFjZShxdWVyeT11cmxlbmNvZGUocSwgZG9z
:::ZXE9VHJ1ZSkpKSwgVHJ1ZQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICBw
:::YXNzCiAgICByZXR1cm4gdXJsLCBGYWxzZQoKCmRlZiBlc191cmxfcGxheWxpc3Qo
:::dXJsKToKICAgICIiIlRydWUgc2kgbGEgVVJMIHBlcnRlbmVjZSBhIHVuYSBsaXN0
:::YSBkZSByZXByb2R1Y2Npw7NuIChsbGV2YSBsaXN0PSkuIiIiCiAgICB0cnk6CiAg
:::ICAgICAgcmV0dXJuICdsaXN0JyBpbiBwYXJzZV9xcyh1cmxwYXJzZSh1cmwpLnF1
:::ZXJ5KQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICByZXR1cm4gRmFsc2UK
:::CgpkZWYgZXNfc29sb19saXN0YSh1cmwpOgogICAgIiIiVHJ1ZSBzaSBsYSBVUkwg
:::ZXMgdW5hIHBsYXlsaXN0IHB1cmEsIHNpbiB2aWRlbyBpbmRpdmlkdWFsIChzaW4g
:::dj0pLiIiIgogICAgdHJ5OgogICAgICAgIHAgPSB1cmxwYXJzZSh1cmwpCiAgICAg
:::ICAgaWYgJ3YnIGluIHBhcnNlX3FzKHAucXVlcnkpIG9yICd5b3V0dS5iZScgaW4g
:::KHAubmV0bG9jIG9yICcnKToKICAgICAgICAgICAgcmV0dXJuIEZhbHNlCiAgICAg
:::ICAgcmV0dXJuIChwLnBhdGggb3IgJycpLnJzdHJpcCgnLycpLmVuZHN3aXRoKCcv
:::cGxheWxpc3QnKQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICByZXR1cm4g
:::RmFsc2UKCgpkZWYgYWJyaXJfY2FycGV0YShydXRhKToKICAgIHRyeToKICAgICAg
:::ICBpZiBvcy5uYW1lID09ICdudCc6CiAgICAgICAgICAgIG9zLnN0YXJ0ZmlsZShz
:::dHIocnV0YSkpICAjIG5vcWE6IHNvbG8gV2luZG93cwogICAgICAgIGVsc2U6CiAg
:::ICAgICAgICAgIHN1YnByb2Nlc3MuUG9wZW4oWyd4ZGctb3BlbicsIHN0cihydXRh
:::KV0pCiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHBhc3MKCgojIC0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0gZmZtcGVnCmRlZiBidXNjYXJfZmZtcGVnKCk6CiAgICBleGUg
:::PSBzaHV0aWwud2hpY2goJ2ZmbXBlZycpCiAgICBpZiBleGU6CiAgICAgICAgcmV0
:::dXJuIFBhdGgoZXhlKQogICAgY2FuZGlkYXRvcyA9IFsKICAgICAgICBBUFBfRElS
:::IC8gJ2ZmbXBlZycgLyAnYmluJyAvICdmZm1wZWcuZXhlJywKICAgICAgICBBUFBf
:::RElSIC8gJ2ZmbXBlZycgLyAnYmluJyAvICdmZm1wZWcnLAogICAgICAgIEFQUF9E
:::SVIgLyAncnVudGltZScgLyAnZmZtcGVnLmV4ZScsCiAgICBdCiAgICBmb3IgcCBp
:::biBjYW5kaWRhdG9zOgogICAgICAgIGlmIHAuZXhpc3RzKCk6CiAgICAgICAgICAg
:::IHJldHVybiBwCiAgICByZXR1cm4gTm9uZQoKCmRlZiBidXNjYXJfZmZwcm9iZShm
:::Zm1wZWcpOgogICAgaWYgZmZtcGVnIGlzIE5vbmU6CiAgICAgICAgcmV0dXJuIHNo
:::dXRpbC53aGljaCgnZmZwcm9iZScpCiAgICBwID0gZmZtcGVnLndpdGhfbmFtZSgn
:::ZmZwcm9iZS5leGUnIGlmIG9zLm5hbWUgPT0gJ250JyBlbHNlICdmZnByb2JlJykK
:::ICAgIGlmIHAuZXhpc3RzKCk6CiAgICAgICAgcmV0dXJuIHAKICAgIHJldHVybiBz
:::aHV0aWwud2hpY2goJ2ZmcHJvYmUnKQoKCllUX0RMUCA9IE5vbmUgICAjIG3Ds2R1
:::bG8geXRfZGxwOyBzZSByZWxsZW5hIGVuIGNvbXByb2Jhcl9lbnRvcm5vKCkKRkZN
:::UEVHID0gTm9uZSAgICMgcnV0YSBkZSBmZm1wZWcKRkZQUk9CRSA9IE5vbmUgICMg
:::cnV0YSBkZSBmZnByb2JlCgoKZGVmIGNvbXByb2Jhcl9lbnRvcm5vKCk6CiAgICBn
:::bG9iYWwgWVRfRExQLCBGRk1QRUcsIEZGUFJPQkUKICAgIHRyeToKICAgICAgICBp
:::bXBvcnQgeXRfZGxwIGFzIG1vZAogICAgICAgIFlUX0RMUCA9IG1vZAogICAgZXhj
:::ZXB0IEV4Y2VwdGlvbjoKICAgICAgICBwYXNzCiAgICBGRk1QRUcgPSBidXNjYXJf
:::ZmZtcGVnKCkKICAgIEZGUFJPQkUgPSBidXNjYXJfZmZwcm9iZShGRk1QRUcpCgoK
:::Y2xhc3MgUmVnaXN0cm86CiAgICAiIiJMb2dnZXIgcGFyYSB5dC1kbHA6IHJlZW52
:::w61hIGF2aXNvcy9lcnJvcmVzIGFsIHJlZ2lzdHJvIGRlIGxhIEdVSS4iIiIKCiAg
:::ICBkZWYgX19pbml0X18oc2VsZik6CiAgICAgICAgc2VsZi5sb2cgPSBOb25lICAj
:::IGxhIEdVSSBsbyBjb25lY3RhOiBsb2cobWVuc2FqZSwgZXRpcXVldGEpCgogICAg
:::ZGVmIGRlYnVnKHNlbGYsIG0pOgogICAgICAgIHBhc3MKCiAgICAjIEF2aXNvcyBp
:::bnRlcm5vcyBkZSB5dC1kbHAgcXVlIHNvbG8gbWV0ZW4gcnVpZG8gZW4gZWwgcmVn
:::aXN0cm86CiAgICBBVklTT1NfUlVJRE9TT1MgPSAoJ05vIHN1cHBvcnRlZCBKYXZh
:::U2NyaXB0IHJ1bnRpbWUnLCAnRUpTJykKCiAgICBkZWYgd2FybmluZyhzZWxmLCBt
:::KToKICAgICAgICBtID0gc3RyKG0pLnN0cmlwKCkKICAgICAgICBpZiBub3QgbSBv
:::ciBhbnkoeCBpbiBtIGZvciB4IGluIHNlbGYuQVZJU09TX1JVSURPU09TKToKICAg
:::ICAgICAgICAgcmV0dXJuCiAgICAgICAgaWYgc2VsZi5sb2c6CiAgICAgICAgICAg
:::IHNlbGYubG9nKG0sICdhdmlzbycpCgogICAgZGVmIGVycm9yKHNlbGYsIG0pOgog
:::ICAgICAgIG0gPSBzdHIobSkuc3RyaXAoKQogICAgICAgIGlmIG0gYW5kIHNlbGYu
:::bG9nOgogICAgICAgICAgICBzZWxmLmxvZyhtLCAnZXJyb3InKQoKClJFR0lTVFJP
:::ID0gUmVnaXN0cm8oKQoKTk9NQlJFU19QUCA9IHsKICAgICdGRm1wZWdFeHRyYWN0
:::QXVkaW8nOiAnQ29udmlydGllbmRvIGVsIGF1ZGlvIGNvbiBGRm1wZWcnLAogICAg
:::J0ZGbXBlZ1RodW1ibmFpbHNDb252ZXJ0b3InOiAnQ29udmlydGllbmRvIGxhIGNh
:::csOhdHVsYSBhIEpQRycsCiAgICAnRkZtcGVnTWV0YWRhdGEnOiAnRXNjcmliaWVu
:::ZG8gZXRpcXVldGFzICh0w610dWxvL2FydGlzdGEpJywKICAgICdFbWJlZFRodW1i
:::bmFpbCc6ICdJbmNydXN0YW5kbyBsYSBjYXLDoXR1bGEnLAogICAgJ01vdmVGaWxl
:::cyc6ICdPcmdhbml6YW5kbyBhcmNoaXZvcycsCiAgICAnRkZtcGVnTWVyZ2VyJzog
:::J1VuaWVuZG8gcGlzdGFzIGRlIHZpZGVvIHkgYXVkaW8nLAogICAgJ0ZGbXBlZ1Zp
:::ZGVvQ29udmVydG9yJzogJ0NvbnZpcnRpZW5kbyBlbCB2aWRlbycsCn0KCiMgLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLSBmb3JtYXRvcwpGT1JNQVRPUyA9IHsKICAgICdBQUMnOiBk
:::aWN0KHRleHRvPSdBQUMgKC5tNGEpJywgZXh0PSdtNGEnLAogICAgICAgICAgICAg
:::ICAgY2FsaWRhZGVzPVsnOTZrJywgJzEyOGsnXSwgZGVmZWN0bz0nMTI4aycpLAog
:::ICAgJ01QMyc6IGRpY3QodGV4dG89J01QMyAoLm1wMyknLCBleHQ9J21wMycsCiAg
:::ICAgICAgICAgICAgICBjYWxpZGFkZXM9Wyc5NmsnLCAnMTI4aycsICcxOTJrJywg
:::JzI1NmsnLCAnMzIwayddLAogICAgICAgICAgICAgICAgZGVmZWN0bz0nMzIwaycp
:::LAogICAgJ0ZMQUMnOiBkaWN0KHRleHRvPSdGTEFDICguZmxhYyknLCBleHQ9J2Zs
:::YWMnLAogICAgICAgICAgICAgICAgIGNhbGlkYWRlcz1bJ3NpbiBwZXJkaWRhJ10s
:::IGRlZmVjdG89J3NpbiBwZXJkaWRhJyksCiAgICAnV0FWJzogZGljdCh0ZXh0bz0n
:::V0FWICgud2F2KScsIGV4dD0nd2F2JywKICAgICAgICAgICAgICAgIGNhbGlkYWRl
:::cz1bJ3NpbiBwZXJkaWRhJ10sIGRlZmVjdG89J3NpbiBwZXJkaWRhJyksCiAgICAn
:::V01BJzogZGljdCh0ZXh0bz0nV01BICgud21hKScsIGV4dD0nd21hJywKICAgICAg
:::ICAgICAgICAgIGNhbGlkYWRlcz1bJzk2aycsICcxMjhrJ10sIGRlZmVjdG89JzEy
:::OGsnKSwKICAgICdBVkknOiBkaWN0KHRleHRvPSdBVkkgLSBzaGVpanUgMS44IiAo
:::MTI4eDE2MCknLCBleHQ9J2F2aScsCiAgICAgICAgICAgICAgICBjYWxpZGFkZXM9
:::WycxMjh4MTYwIMK3IDE2IGZwcyddLCBkZWZlY3RvPScxMjh4MTYwIMK3IDE2IGZw
:::cycpLAp9CgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIHByb2dyZXNvCmRlZiBob29rc19n
:::dWkoY29sYSk6CiAgICAiIiJDcmVhIGxvcyBob29rcyBkZSB5dC1kbHAgcXVlIHB1
:::YmxpY2FuIGV2ZW50b3MgZW4gbGEgY29sYSBkZSBsYSBHVUkuIiIiCiAgICBlc3Rh
:::ZG8gPSB7J3RpdHVsbyc6IEZhbHNlLCAncHBfdWx0JzogTm9uZX0KCiAgICBkZWYg
:::bG9nKG0sIHQ9J2luZm8nKToKICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQp
:::KQoKICAgIGRlZiBwcm9ncmVzbyhkKToKICAgICAgICBpZiBkWydzdGF0dXMnXSA9
:::PSAnZG93bmxvYWRpbmcnOgogICAgICAgICAgICBpZiBub3QgZXN0YWRvWyd0aXR1
:::bG8nXToKICAgICAgICAgICAgICAgIGluZm8gPSBkLmdldCgnaW5mb19kaWN0Jykg
:::b3Ige30KICAgICAgICAgICAgICAgIHQgPSBpbmZvLmdldCgndGl0bGUnKSBvciBQ
:::YXRoKGQuZ2V0KCdmaWxlbmFtZScpIG9yICcnKS5zdGVtCiAgICAgICAgICAgICAg
:::ICBpZiB0OgogICAgICAgICAgICAgICAgICAgIGxvZygn4pmqICcgKyBzdHIodClb
:::OjkwXSwgJ3RpdHVsbycpCiAgICAgICAgICAgICAgICAgICAgZXN0YWRvWyd0aXR1
:::bG8nXSA9IFRydWUKICAgICAgICAgICAgdG90YWwgPSBkLmdldCgndG90YWxfYnl0
:::ZXMnKSBvciBkLmdldCgndG90YWxfYnl0ZXNfZXN0aW1hdGUnKSBvciAwCiAgICAg
:::ICAgICAgIGRvbmUgPSBkLmdldCgnZG93bmxvYWRlZF9ieXRlcycsIDApCiAgICAg
:::ICAgICAgIHZlbCA9IGQuZ2V0KCdzcGVlZCcpCiAgICAgICAgICAgIGV0YSA9IGQu
:::Z2V0KCdldGEnKQogICAgICAgICAgICBpZiB0b3RhbDoKICAgICAgICAgICAgICAg
:::IHBjdCA9IGRvbmUgLyB0b3RhbCAqIDEwMAogICAgICAgICAgICAgICAgdGV4dG8g
:::PSBmJ3twY3Q6NS4xZn0lIMK3IHtmbXRfdGFtKGRvbmUpfSAvIHtmbXRfdGFtKHRv
:::dGFsKX0nCiAgICAgICAgICAgICAgICBpZiB2ZWw6CiAgICAgICAgICAgICAgICAg
:::ICAgdGV4dG8gKz0gZicgwrcge2ZtdF90YW0odmVsKX0vcycKICAgICAgICAgICAg
:::ICAgIGlmIGV0YSBpcyBub3QgTm9uZToKICAgICAgICAgICAgICAgICAgICB0ZXh0
:::byArPSBmJyDCtyBxdWVkYW4ge2ZtdF90aWVtKGV0YSl9JwogICAgICAgICAgICAg
:::ICAgY29sYS5wdXQoKCdwcm9nJywgcGN0LCB0ZXh0bykpCiAgICAgICAgICAgIGVs
:::c2U6CiAgICAgICAgICAgICAgICB2ID0gZid7Zm10X3RhbSh2ZWwpfS9zJyBpZiB2
:::ZWwgZWxzZSAnJwogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdwcm9nJywgTm9u
:::ZSwgZid7Zm10X3RhbShkb25lKX0gwrcge3Z9JykpCiAgICAgICAgZWxpZiBkWydz
:::dGF0dXMnXSA9PSAnZmluaXNoZWQnOgogICAgICAgICAgICBlc3RhZG9bJ3BwX3Vs
:::dCddID0gTm9uZQogICAgICAgICAgICBjb2xhLnB1dCgoJ2xvZycsICdEZXNjYXJn
:::YSByZWNpYmlkYS4gUHJvY2VzYW5kby4uLicsICdncmlzJykpCiAgICAgICAgICAg
:::IGNvbGEucHV0KCgncHJvZycsIDAsICdQcm9jZXNhbmRvLi4uJykpCgogICAgZGVm
:::IHBvc3Rwcm9jZXNvKGQpOgogICAgICAgIGlmIGRbJ3N0YXR1cyddID09ICdzdGFy
:::dGVkJzoKICAgICAgICAgICAgbm9tID0gKGQuZ2V0KCdwb3N0cHJvY2Vzc29yX25h
:::bWUnKQogICAgICAgICAgICAgICAgICAgb3IgZC5nZXQoJ3Bvc3Rwcm9jZXNzb3In
:::KSBvciAnUG9zdHByb2Nlc28nKQogICAgICAgICAgICBpZiBub20gPT0gZXN0YWRv
:::WydwcF91bHQnXToKICAgICAgICAgICAgICAgIHJldHVybiAgIyB5dC1kbHAgYSB2
:::ZWNlcyBhbnVuY2lhIGVsIG1pc21vIHBhc28gZG9zIHZlY2VzCiAgICAgICAgICAg
:::IGVzdGFkb1sncHBfdWx0J10gPSBub20KICAgICAgICAgICAgdGV4dG8gPSBOT01C
:::UkVTX1BQLmdldChub20sIG5vbSkgKyAnLi4uJwogICAgICAgICAgICBjb2xhLnB1
:::dCgoJ2xvZycsICfihpIgJyArIHRleHRvLCAnZ3JpcycpKQogICAgICAgICAgICBj
:::b2xhLnB1dCgoJ3Byb2cnLCBOb25lLCB0ZXh0bykpCgogICAgcmV0dXJuIHByb2dy
:::ZXNvLCBwb3N0cHJvY2VzbwoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLSBhbnRpLWJsb3F1ZW8gZGUgWW91VHViZSAodjIuOSkK
:::IyBDdWFuZG8gWW91VHViZSBkZXNjb25mw61hIGRlIHVuYSByZWQgKHdpZmkgY29t
:::cGFydGlkbywgZGF0b3MgbcOzdmlsZXMsIFZQTgojIG8gbXVjaGFzIGRlc2Nhcmdh
:::cyBzZWd1aWRhcykgcmVzcG9uZGUgYSBsb3MgY2xpZW50ZXMgd2ViIGNvbiAiU2ln
:::biBpbiB0bwojIGNvbmZpcm0geW91J3JlIG5vdCBhIGJvdCIgbyBIVFRQIDQyOS4g
:::RGVmZW5zYSBlbiBjYXBhczoKIyAgIDEpIFBvciBkZWZlY3RvIGxvcyBmb3JtYXRv
:::cyBzZSBwaWRlbiBjb24gbG9zIGNsaWVudGVzIGRlIGxhcyBBUFBTCiMgICAgICBt
:::w7N2aWxlcyAoYW5kcm9pZC9pb3MvbXdlYiksIHF1ZSBlbiBsYSBtYXlvcsOtYSBk
:::ZSBsYXMgcmVkZXMgbm8gcGFzYW4KIyAgICAgIHBvciBlc2UgY2hlcXVlby4KIyAg
:::IDIpIFNpIGF1biBhc8OtIFlvdVR1YmUgaW5zaXN0ZSwgbGEgZGVzY2FyZ2Egc2Ug
:::cmVpbnRlbnRhIFVOQSB2ZXogc29sYQojICAgICAgY29uIGVsIGNvbWJvIDIgKGFu
:::ZHJvaWRfdnIvYW5kcm9pZC9pb3MsIHNpbiBjbGllbnRlcyB3ZWIpIHRyYXMgdW5h
:::CiMgICAgICBwZXF1ZcOxYSBwYXVzYSBwYXJhIGRlamFyIGVuZnJpYXIgZWwgNDI5
:::LgojICAgMykgw5psdGltYSBsw61uZWE6IGVsIGRlc3BsZWdhYmxlICJTaSBZb3VU
:::dWJlIGJsb3F1ZWE6IiBwZXJtaXRlIHVzYXIgbGFzCiMgICAgICBDT09LSUVTIGRl
:::bCBuYXZlZ2Fkb3IgZGVsIHVzdWFyaW8gKGNvbiBzZXNpw7NuIGFiaWVydGEgWW91
:::VHViZSBubwojICAgICAgcGlkZSB2ZXJpZmljYWNpw7NuKS4gRXMgbGEgdsOtYSBv
:::ZmljaWFsIHJlY29tZW5kYWRhIHBvciB5dC1kbHAuCkNPTUJPU19BTlRJX0JPVCA9
:::ICgKICAgICgnYW5kcm9pZCcsICdpb3MnLCAnbXdlYicpLAogICAgKCdhbmRyb2lk
:::X3ZyJywgJ2FuZHJvaWQnLCAnaW9zJyksCikKTkFWRUdBRE9SRVNfQ09PS0lFUyA9
:::ICgnZmlyZWZveCcsICdjaHJvbWUnLCAnZWRnZScsICdicmF2ZScsICdvcGVyYScs
:::CiAgICAgICAgICAgICAgICAgICAgICAgJ3ZpdmFsZGknKQpfQU5USV9CT1QgPSB7
:::J2NvbWJvJzogMH0gICAgICAjIGNvbWJvIGVuIGN1cnNvIChkaWN0IG11dGFibGUg
:::PSBnbG9iYWwpCgoKZGVmIF9hbnRpX2JvdChvKToKICAgICIiIklueWVjdGEgZW4g
:::bGFzIG9wY2lvbmVzIGRlIHl0LWRscCBsYSB2w61hIGFudGktYmxvcXVlbyBlbiBj
:::dXJzby4iIiIKICAgIG9bJ2V4dHJhY3Rvcl9hcmdzJ10gPSB7J3lvdXR1YmUnOiB7
:::J3BsYXllcl9jbGllbnQnOgogICAgICAgICAgICAgICAgICAgICAgICAgIGxpc3Qo
:::Q09NQk9TX0FOVElfQk9UW19BTlRJX0JPVFsnY29tYm8nXV0pfX0KICAgIG9bJ2Zv
:::cmNlaXB2NCddID0gVHJ1ZQogICAgbmF2ZWdhZG9yID0gc3RyKEFKVVNURVMuZ2V0
:::KCdjb29raWVzJywgJycpIG9yICcnKS5zdHJpcCgpLmxvd2VyKCkKICAgIGlmIG5h
:::dmVnYWRvciBpbiBOQVZFR0FET1JFU19DT09LSUVTOgogICAgICAgIG9bJ2Nvb2tp
:::ZXNmcm9tYnJvd3NlciddID0gKG5hdmVnYWRvciwpCiAgICByZXR1cm4gbwoKCmRl
:::ZiBfZXNfYmxvcXVlb19ib3QodGV4dG8pOgogICAgIiIiVHJ1ZSBzaSBlbCBlcnJv
:::ciBkZSB5dC1kbHAgZXMgZWwgY2hlcXVlbyBhbnRpLWJvdCBvIHVuIDQyOS4iIiIK
:::ICAgIHQgPSAodGV4dG8gb3IgJycpLmxvd2VyKCkKICAgIHJldHVybiAoJ25vdCBh
:::IGJvdCcgaW4gdCBvciAnc2lnbiBpbiB0byBjb25maXJtJyBpbiB0CiAgICAgICAg
:::ICAgIG9yICd0b28gbWFueSByZXF1ZXN0cycgaW4gdCBvciAnaHR0cCBlcnJvciA0
:::MjknIGluIHQKICAgICAgICAgICAgb3IgJyBlcnJvciA0MjknIGluIHQpCgoKIyAt
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tIG9wY2lvbmVzCmRlZiBvcHRzX2Jhc2UoY2FycGV0YSwg
:::Y29sYSk6CiAgICBwcm9ncmVzbywgcG9zdHByb2Nlc28gPSBob29rc19ndWkoY29s
:::YSkKICAgIG8gPSB7CiAgICAgICAgJ291dHRtcGwnOiBzdHIoY2FycGV0YSAvICcl
:::KHRpdGxlKXMuJShleHQpcycpLAogICAgICAgICdxdWlldCc6IFRydWUsCiAgICAg
:::ICAgJ25vX3dhcm5pbmdzJzogVHJ1ZSwKICAgICAgICAnbm9wcm9ncmVzcyc6IFRy
:::dWUsCiAgICAgICAgJ25vcGxheWxpc3QnOiBUcnVlLAogICAgICAgICdpZ25vcmVl
:::cnJvcnMnOiBGYWxzZSwKICAgICAgICAncmV0cmllcyc6IDEwLAogICAgICAgICdm
:::cmFnbWVudF9yZXRyaWVzJzogMTAsCiAgICAgICAgJ3NvY2tldF90aW1lb3V0Jzog
:::MzAsCiAgICAgICAgJ2NvbmN1cnJlbnRfZnJhZ21lbnRfZG93bmxvYWRzJzogNCwK
:::ICAgICAgICAnd2luZG93c2ZpbGVuYW1lcyc6IFRydWUsCiAgICAgICAgJ292ZXJ3
:::cml0ZXMnOiBGYWxzZSwKICAgICAgICAnbG9nZ2VyJzogUkVHSVNUUk8sCiAgICAg
:::ICAgJ3Byb2dyZXNzX2hvb2tzJzogW3Byb2dyZXNvXSwKICAgICAgICAncG9zdHBy
:::b2Nlc3Nvcl9ob29rcyc6IFtwb3N0cHJvY2Vzb10sCiAgICB9CiAgICBpZiBGRk1Q
:::RUc6CiAgICAgICAgb1snZmZtcGVnX2xvY2F0aW9uJ10gPSBzdHIoRkZNUEVHLnBh
:::cmVudCkKICAgIF9hbnRpX2JvdChvKQogICAgcmV0dXJuIG8KCgpkZWYgY29udmVy
:::dGlyX2ZmbXBlZyhjbWQsIGV0aXF1ZXRhLCBjb2xhKToKICAgICIiIkVqZWN1dGEg
:::RkZtcGVnIChsaXN0YSBkZSBhcmd1bWVudG9zLCBzaW4gc2hlbGwpIGNvbiBtYXJx
:::dWVlLiIiIgogICAgY29sYS5wdXQoKCdwcm9nJywgTm9uZSwgZXRpcXVldGEpKQoK
:::ICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgogICAgICAgIGNvbGEucHV0KCgnbG9n
:::JywgbSwgdCkpCgogICAgdHJ5OgogICAgICAgIHAgPSBzdWJwcm9jZXNzLnJ1bihj
:::bWQsIHN0ZG91dD1zdWJwcm9jZXNzLlBJUEUsCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgIHN0ZGVycj1zdWJwcm9jZXNzLlBJUEUsIHRleHQ9VHJ1ZSwKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgZW5jb2Rpbmc9J3V0Zi04JywgZXJyb3JzPSdy
:::ZXBsYWNlJykKICAgIGV4Y2VwdCBGaWxlTm90Rm91bmRFcnJvcjoKICAgICAgICBw
:::ID0gTm9uZQogICAgaWYgcCBpcyBOb25lIG9yIHAucmV0dXJuY29kZSAhPSAwOgog
:::ICAgICAgIGxvZygn4pyWIEZGbXBlZyBkZXZvbHZpw7MgdW4gZXJyb3I6JywgJ2Vy
:::cm9yJykKICAgICAgICBpZiBwIGlzIG5vdCBOb25lOgogICAgICAgICAgICBmb3Ig
:::bG4gaW4gKHAuc3RkZXJyIG9yICcnKS5zdHJpcCgpLnNwbGl0bGluZXMoKVstNDpd
:::OgogICAgICAgICAgICAgICAgbG9nKCcgICAnICsgbG5bOjE4MF0sICdncmlzJykK
:::ICAgICAgICBjb2xhLnB1dCgoJ3Byb2cnLCAwLCAnJykpCiAgICAgICAgcmV0dXJu
:::IEZhbHNlCiAgICByZXR1cm4gVHJ1ZQoKCmRlZiBhcmNoaXZvX2ZpbmFsKGluZm8s
:::IGNhcnBldGEsIGV4dCk6CiAgICAiIiJMb2NhbGl6YSBlbCBhcmNoaXZvIHJlc3Vs
:::dGFudGUgKHl0LWRscCBsbyByZXBvcnRhOyBmYWxsYmFjazogbcOhcyBudWV2byku
:::IiIiCiAgICB0cnk6CiAgICAgICAgZm9yIGQgaW4gKGluZm8uZ2V0KCdyZXF1ZXN0
:::ZWRfZG93bmxvYWRzJykgb3IgW10pOgogICAgICAgICAgICBmID0gZC5nZXQoJ2Zp
:::bGVwYXRoJykKICAgICAgICAgICAgaWYgZjoKICAgICAgICAgICAgICAgIHJldHVy
:::biBQYXRoKGYpCiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHBhc3MKICAg
:::IGNhbmQgPSBzb3J0ZWQoY2FycGV0YS5nbG9iKCcqLicgKyBleHQpLAogICAgICAg
:::ICAgICAgICAgICBrZXk9bGFtYmRhIHA6IHAuc3RhdCgpLnN0X210aW1lLCByZXZl
:::cnNlPVRydWUpCiAgICByZXR1cm4gY2FuZFswXSBpZiBjYW5kIGVsc2UgTm9uZQoK
:::CmRlZiBsaW1waWFyX21pbmlhdHVyYXMoY2FycGV0YSwgYXJjaGl2byk6CiAgICAi
:::IiJCb3JyYSBtaW5pYXR1cmFzIHN1ZWx0YXMgcXVlIEVtYmVkVGh1bWJuYWlsIGRl
:::amFyYSBzaW4gaW5jcnVzdGFyLiIiIgogICAgZm9yIGV4dCBpbiAoJy53ZWJwJywg
:::Jy5qcGcnLCAnLmpwZWcnLCAnLnBuZycpOgogICAgICAgIHQgPSBhcmNoaXZvLndp
:::dGhfc3VmZml4KGV4dCkKICAgICAgICBpZiB0LmV4aXN0cygpOgogICAgICAgICAg
:::ICB0cnk6CiAgICAgICAgICAgICAgICB0LnVubGluaygpCiAgICAgICAgICAgIGV4
:::Y2VwdCBPU0Vycm9yOgogICAgICAgICAgICAgICAgcGFzcwoKCmRlZiBfbWluaWF0
:::dXJhX2J5dGVzKGNhcnBldGEsIGFyY2hpdm8pOgogICAgIiIiTGVlIGxvcyBieXRl
:::cyBkZSBsYSBtaW5pYXR1cmEgcXVlIHl0LWRscCBkZWpvIGp1bnRvIGFsIGFyY2hp
:::dm8gZmluYWwuIiIiCiAgICBpZiBub3QgYXJjaGl2bzoKICAgICAgICByZXR1cm4g
:::Tm9uZQogICAgZm9yIGV4dCBpbiAoJy5qcGcnLCAnLmpwZWcnLCAnLndlYnAnLCAn
:::LnBuZycpOgogICAgICAgIHQgPSBhcmNoaXZvLndpdGhfc3VmZml4KGV4dCkKICAg
:::ICAgICBpZiB0LmV4aXN0cygpOgogICAgICAgICAgICB0cnk6CiAgICAgICAgICAg
:::ICAgICByZXR1cm4gdC5yZWFkX2J5dGVzKCkKICAgICAgICAgICAgZXhjZXB0IE9T
:::RXJyb3I6CiAgICAgICAgICAgICAgICBwYXNzCiAgICByZXR1cm4gTm9uZQoKCmRl
:::ZiBfZXNfanBnKGRhdG9zKToKICAgIHJldHVybiBib29sKGRhdG9zKSBhbmQgZGF0
:::b3NbOjNdID09IGInXHhmZlx4ZDhceGZmJwoKCmRlZiBfYV9qcGcoZGF0b3MpOgog
:::ICAgIiIiQ29udmllcnRlIGxvcyBieXRlcyBkZSB1bmEgaW1hZ2VuICh3ZWJwL3Bu
:::Zy8uLi4pIGEgSlBFRyBjb24gRkZtcGVnLgoKICAgIExvcyByZXByb2R1Y3RvcmVz
:::IGJhcmF0b3MgKHRpcG8gc2hlaWp1KSBzdWVsZW4gbGVlciBzb2xvIEpQRUc6IGxh
:::CiAgICBtaW5pYXR1cmEgZGUgWW91VHViZSB2aWVuZSBlbiBXZWJQIHkgRW1iZWRU
:::aHVtYm5haWwgZGUgeXQtZGxwIGxhCiAgICBjb252aWVydGUgYSBQTkcgKCJQTkcg
:::aXMgcHJlZmVycmVkIHNpbmNlIEpQRUcgaXMgbG9zc3kiKSwgYXNpIHF1ZQogICAg
:::YXF1aSBub3MgYXNlZ3VyYW1vcyBub3NvdHJvcyBkZSBxdWUgYWNhYmUgZW4gSlBF
:::Ry4iIiIKICAgIGlmIG5vdCBkYXRvcyBvciBub3QgRkZNUEVHOgogICAgICAgIHJl
:::dHVybiBOb25lCiAgICBiYXNlID0gUGF0aCh0ZW1wZmlsZS5nZXR0ZW1wZGlyKCkp
:::IC8gKCdtdXNpa2FsYW5fY2FyYXR1bGFfJWQnICUgb3MuZ2V0cGlkKCkpCiAgICBv
:::cmlnZW4sIGRlc3Rpbm8gPSBiYXNlLndpdGhfc3VmZml4KCcub3JpZycpLCBiYXNl
:::LndpdGhfc3VmZml4KCcuanBnJykKICAgIHRyeToKICAgICAgICBvcmlnZW4ud3Jp
:::dGVfYnl0ZXMoZGF0b3MpCiAgICAgICAgciA9IHN1YnByb2Nlc3MucnVuKAogICAg
:::ICAgICAgICBbc3RyKEZGTVBFRyksICcteScsICctbG9nbGV2ZWwnLCAnZXJyb3In
:::LCAnLWknLCBzdHIob3JpZ2VuKSwKICAgICAgICAgICAgICctcTp2JywgJzInLCBz
:::dHIoZGVzdGlubyldLAogICAgICAgICAgICBzdGRvdXQ9c3VicHJvY2Vzcy5ERVZO
:::VUxMLCBzdGRlcnI9c3VicHJvY2Vzcy5ERVZOVUxMKQogICAgICAgIGlmIHIucmV0
:::dXJuY29kZSA9PSAwIGFuZCBkZXN0aW5vLmV4aXN0cygpOgogICAgICAgICAgICBq
:::cGcgPSBkZXN0aW5vLnJlYWRfYnl0ZXMoKQogICAgICAgICAgICBpZiBfZXNfanBn
:::KGpwZyk6CiAgICAgICAgICAgICAgICByZXR1cm4ganBnCiAgICBleGNlcHQgRXhj
:::ZXB0aW9uOgogICAgICAgIHBhc3MKICAgIGZpbmFsbHk6CiAgICAgICAgZm9yIGYg
:::aW4gKG9yaWdlbiwgZGVzdGlubyk6CiAgICAgICAgICAgIHRyeToKICAgICAgICAg
:::ICAgICAgIGYudW5saW5rKCkKICAgICAgICAgICAgZXhjZXB0IE9TRXJyb3I6CiAg
:::ICAgICAgICAgICAgICBwYXNzCiAgICByZXR1cm4gTm9uZQoKCmRlZiBfd21fcGlj
:::dHVyZShqcGcsIGRlc2NyaXBjaW9uPScnKToKICAgICIiIkVtcGFxdWV0YSB1bm9z
:::IGJ5dGVzIEpQRUcgZW4gZWwgYXRyaWJ1dG8gV00vUGljdHVyZSBkZWwgY29udGVu
:::ZWRvcgogICAgQVNGICh0aXBvIDMgPSBwb3J0YWRhIGZyb250YWwpLCBjb21vIGhh
:::Y2lhIGVsIHNjcmlwdCBhbnRpZ3VvLiIiIgogICAgZGVmIHUxNihzKToKICAgICAg
:::ICByZXR1cm4gc3RyKHMpLmVuY29kZSgndXRmLTE2LWxlJykgKyBiJ1x4MDBceDAw
:::JwoKICAgIG1pbWUgPSB1MTYoJ2ltYWdlL2pwZWcnKQogICAgZGVzYyA9IHUxNihk
:::ZXNjcmlwY2lvbikKICAgIHJldHVybiAoYidceDAzJyArIGxlbihtaW1lKS50b19i
:::eXRlcyg0LCAnbGl0dGxlJykgKyBtaW1lCiAgICAgICAgICAgICsgbGVuKGRlc2Mp
:::LnRvX2J5dGVzKDQsICdsaXR0bGUnKSArIGRlc2MgKyBqcGcpCgoKZGVmIF9tb292
:::X3ByaW1lcm8ocnV0YSk6CiAgICAiIiJUcnVlIHNpIGVsIGF0b21vICdtb292JyBl
:::c3RhIEFOVEVTIHF1ZSAnbWRhdCcgZW50cmUgbGFzIGNhamFzCiAgICB0b3AtbGV2
:::ZWwgZGVsIE1QNC9NNEEgKGVsIG9yZGVuICdmYXN0c3RhcnQnIGRlIGlUdW5lcyku
:::IFNvbG8gbGVlCiAgICBsYSBjYWJlY2VyYSAoNCBNQikgY29uIHVuIHBhc2UgZGUg
:::dGFtYW5vczogbm8gY2FyZ2EgZWwgYXJjaGl2by4iIiIKICAgIHRyeToKICAgICAg
:::ICB3aXRoIG9wZW4ocnV0YSwgJ3JiJykgYXMgZmg6CiAgICAgICAgICAgIGNhYiA9
:::IGZoLnJlYWQoNCA8PCAyMCkKICAgIGV4Y2VwdCBPU0Vycm9yOgogICAgICAgIHJl
:::dHVybiBGYWxzZQogICAgcG9zLCBmaW4gPSAwLCBsZW4oY2FiKQogICAgd2hpbGUg
:::cG9zICsgOCA8PSBmaW46CiAgICAgICAgdGlwbyA9IGNhYltwb3MgKyA0OnBvcyAr
:::IDhdCiAgICAgICAgaWYgdGlwbyBpbiAoYidtb292JywgYidtZGF0Jyk6CiAgICAg
:::ICAgICAgIHJldHVybiB0aXBvID09IGInbW9vdicKICAgICAgICBzaXplID0gaW50
:::LmZyb21fYnl0ZXMoY2FiW3Bvczpwb3MgKyA0XSwgJ2JpZycpCiAgICAgICAgaWYg
:::c2l6ZSA9PSAxOiAgICAgICAgICAgICAgICAgICAgICAgIyBsYXJnZXNpemUgZGUg
:::NjQgYml0cwogICAgICAgICAgICBpZiBwb3MgKyAxNiA+IGZpbjoKICAgICAgICAg
:::ICAgICAgIHJldHVybiBGYWxzZQogICAgICAgICAgICBzaXplID0gaW50LmZyb21f
:::Ynl0ZXMoY2FiW3BvcyArIDg6cG9zICsgMTZdLCAnYmlnJykKICAgICAgICAgICAg
:::aWYgc2l6ZSA8IDE2OgogICAgICAgICAgICAgICAgcmV0dXJuIEZhbHNlCiAgICAg
:::ICAgZWxpZiBzaXplIDwgODogICAgICAgICAgICAgICAgICAgICAgIyBjYWphIHJv
:::dGEgbyBFT0YKICAgICAgICAgICAgcmV0dXJuIEZhbHNlCiAgICAgICAgcG9zICs9
:::IHNpemUKICAgIHJldHVybiBGYWxzZQoKCmRlZiBfbW9vdl9hbF9wcmluY2lwaW8o
:::cCk6CiAgICAiIiJ2Mi44OiBkZWphIGVsIGF0b21vIG1vb3YgKHF1ZSBsbGV2YSBs
:::YXMgZXRpcXVldGFzKSBhbCBQUklOQ0lQSU8KICAgIGRlbCAubTRhLCBjb21vIGhh
:::Y2UgaVR1bmVzICgnZmFzdHN0YXJ0JykuCgogICAgRkZtcGVnIGVzY3JpYmUgZWwg
:::TTRBIGNvbiBtb292IEFMIEZJTkFMLCBkZXRyYXMgZGUgdG9kbyBlbCBhdWRpbwog
:::ICAgKG1kYXQpLiBFbCBNUDMgZGUgcmVmZXJlbmNpYSBxdWUgZWwgcmVwcm9kdWN0
:::b3IgZGVsIHVzdWFyaW8gc2kgbGVlCiAgICBsbGV2YSBzdSBJRDN2MiBhbCBpbmlj
:::aW8gZGVsIGFyY2hpdm8sIHkgbG9zIHJlcHJvZHVjdG9yZXMgYmFyYXRvcwogICAg
:::c3VlbGVuIGJ1c2NhciBsYXMgZXRpcXVldGFzIGVzY2FuZWFuZG8gc29sbyBsYSBj
:::YWJlY2VyYSBkZWwKICAgIGFyY2hpdm86IHBvciBlc28gbW9zdHJhYmFuICd1bmtu
:::b3duJyBhdW5xdWUgZWwgTTRBIGVzdHV2aWVyYQogICAgcGVyZmVjdGFtZW50ZSBl
:::dGlxdWV0YWRvIChhdG9tcyBpbHN0IGVzdGFuZGFyLCB2ZXJpZmljYWRvIGVuCiAg
:::ICB2Mi43KS4gQ29uIC1tb3ZmbGFncyArZmFzdHN0YXJ0IGVsIG1vb3YgZW50ZXJv
:::ICh5IGRlbnRybwogICAgbW9vdi51ZHRhLm1ldGEuaWxzdCBjb24gdGl0dWxvL2Fy
:::dGlzdGEvYWxidW0vY292cikgcGFzYSBkZWxhbnRlCiAgICBkZWwgbWRhdCBTSU4g
:::cmVjb2RpZmljYXIgbmFkYSAoLWMgY29weSkuIFNpIGFsZ28gZmFsbGEgc2UgZGV2
:::dWVsdmUKICAgIEZhbHNlIHkgZWwgYXJjaGl2byBxdWVkYSBjb21vIGVzdGFiYTog
:::ZXN0byBudW5jYSBkZWJlIHJvbXBlciBsYQogICAgZGVzY2FyZ2EgbmkgbGFzIGV0
:::aXF1ZXRhcyB5YSBlc2NyaXRhcy4iIiIKICAgIGlmIG5vdCBGRk1QRUcgb3IgX21v
:::b3ZfcHJpbWVybyhwKToKICAgICAgICByZXR1cm4gRmFsc2UKICAgIHRtcCA9IHAu
:::d2l0aF9uYW1lKHAuc3RlbSArICcuZmFzdHN0YXJ0Lm00YScpCiAgICB0cnk6CiAg
:::ICAgICAgciA9IHN1YnByb2Nlc3MucnVuKAogICAgICAgICAgICBbc3RyKEZGTVBF
:::RyksICcteScsICctbG9nbGV2ZWwnLCAnZXJyb3InLCAnLWknLCBzdHIocCksCiAg
:::ICAgICAgICAgICAnLW1hcCcsICcwJywgJy1jJywgJ2NvcHknLCAnLW1vdmZsYWdz
:::JywgJytmYXN0c3RhcnQnLAogICAgICAgICAgICAgc3RyKHRtcCldLAogICAgICAg
:::ICAgICBzdGRvdXQ9c3VicHJvY2Vzcy5ERVZOVUxMLCBzdGRlcnI9c3VicHJvY2Vz
:::cy5ERVZOVUxMKQogICAgICAgIGlmIChyLnJldHVybmNvZGUgPT0gMCBhbmQgdG1w
:::LmV4aXN0cygpCiAgICAgICAgICAgICAgICBhbmQgX21vb3ZfcHJpbWVybyh0bXAp
:::CiAgICAgICAgICAgICAgICBhbmQgdG1wLnN0YXQoKS5zdF9zaXplICogMTAwCiAg
:::ICAgICAgICAgICAgICA+PSBwLnN0YXQoKS5zdF9zaXplICogOTApOgogICAgICAg
:::ICAgICBvcy5yZXBsYWNlKHRtcCwgcCkKICAgICAgICAgICAgcmV0dXJuIFRydWUK
:::ICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgcGFzcwogICAgZmluYWxseToK
:::ICAgICAgICB0cnk6CiAgICAgICAgICAgIHRtcC51bmxpbmsoKQogICAgICAgIGV4
:::Y2VwdCBPU0Vycm9yOgogICAgICAgICAgICBwYXNzCiAgICByZXR1cm4gRmFsc2UK
:::CgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0gZXRpcXVldGFzCmRlZiBfYXJ0aXN0YV9saW1w
:::aW8oaW5mbyk6CiAgICAiIiJOb21icmUgZGVsIGFydGlzdGEgbGVnaWJsZSBwYXJh
:::IHJlcHJvZHVjdG9yZXMuCgogICAgTG9zIGNhbmFsZXMgYXV0b21hdGljb3MgZGUg
:::bXVzaWNhIGRlIFlvdVR1YmUgc2UgbGxhbWFuICdYIC0gVG9waWMnOwogICAgZXNl
:::IHN1ZmlqbyBzb2JyYSBjdWFuZG8gc2UgdmUgZW4gbGEgcGFudGFsbGEgZGUgdW4g
:::cmVwcm9kdWN0b3IuIiIiCiAgICBhID0gKGluZm8uZ2V0KCdhcnRpc3QnKSBvciBp
:::bmZvLmdldCgnY3JlYXRvcicpCiAgICAgICAgIG9yIGluZm8uZ2V0KCd1cGxvYWRl
:::cicpIG9yIGluZm8uZ2V0KCdjaGFubmVsJykgb3IgJycpCiAgICBhID0gc3RyKGEp
:::LnN0cmlwKCkKICAgIGEgPSByZS5zdWIocidccyotXHMqVG9waWNccyokJywgJycs
:::IGEsIGZsYWdzPXJlLkkpLnN0cmlwKCkKICAgIHJldHVybiBhCgoKZGVmIF9hbGJ1
:::bV9kZShpbmZvKToKICAgICIiIkFsYnVtIHBhcmEgZWwgYXJjaGl2byBmaW5hbC4K
:::CiAgICB5dC1kbHAgc29sbyBlc2NyaWJlIGFsYnVtIHNpIGVsIHByb3BpbyB2aWRl
:::byBsbyB0cmFlIChjYXNpIG51bmNhKToKICAgIHBvciBlc28gbG9zIHJlcHJvZHVj
:::dG9yZXMgbW9zdHJhYmFuICdhbGJ1bSBkZXNjb25vY2lkbycuIE9yZGVuIGRlCiAg
:::ICBwcmVmZXJlbmNpYTogYWxidW0gcmVhbCAtPiBub21icmUgZGUgbGEgcGxheWxp
:::c3QgLT4gYXJ0aXN0YS4iIiIKICAgIGZvciBjbGF2ZSBpbiAoJ2FsYnVtJywgJ3Bs
:::YXlsaXN0X3RpdGxlJyk6CiAgICAgICAgdiA9IHN0cihpbmZvLmdldChjbGF2ZSkg
:::b3IgJycpLnN0cmlwKCkKICAgICAgICBpZiB2OgogICAgICAgICAgICByZXR1cm4g
:::dgogICAgcmV0dXJuIF9hcnRpc3RhX2xpbXBpbyhpbmZvKSBvciAnWW91VHViZScK
:::CgpkZWYgYXBsaWNhcl90YWdzKGluZm8sIGFyY2hpdm8sIGxvZz1Ob25lLCBjYXJh
:::dHVsYT1Ob25lKToKICAgICIiIkVzY3JpYmUgY29uIG11dGFnZW4gbGFzIGV0aXF1
:::ZXRhcyBkZWwgYXJjaGl2byBmaW5hbC4KCiAgICBHYXJhbnRpemEgcXVlIFRPRE9T
:::IGxvcyByZXByb2R1Y3RvcmVzIG11ZXN0cmVuIGFydGlzdGEgeSBhbGJ1bSwKICAg
:::IGF1bnF1ZSBGRm1wZWdNZXRhZGF0YSBkZSB5dC1kbHAgbm8gbG9zIGhheWEgZXNj
:::cml0by4gQ2FkYSBmb3JtYXRvCiAgICBjb24gU1UgZm9ybWEgZXN0YW5kYXI6CiAg
:::ICAgIMK3IE1QMzogSUQzdjIuNCBjb24gdGV4dG9zIFVURi0xNiAoZW5jb2Rpbmc9
:::MSkgeSBBUElDKG1pbWUKICAgICAgICAnaW1hZ2UvanBnJywgdGlwbyAzLCBkZXNj
:::ICdhdHRhY2hlZCBwaWN0dXJlJyksIGNhbGNhZG8gZGVsCiAgICAgICAgTVAzIGRl
:::IHJlZmVyZW5jaWEgcXVlIGVsIHJlcHJvZHVjdG9yIGRlbCB1c3VhcmlvIG11ZXN0
:::cmEKICAgICAgICBiaWVuLiBFbCBwYXNlIGFudGlndW8gdXNhYmEgZW5jb2Rpbmc9
:::MyAoVVRGLTgpIGRlbnRybyBkZSB1bgogICAgICAgIHRhZyB2Mi4zOiBmdWVyYSBk
:::ZSBlc3BlY2lmaWNhY2lvbiwgeSBsb3MgcmVwcm9kdWN0b3JlcwogICAgICAgIGJh
:::cmF0b3MgZGVzY2FydGFiYW4gbGEgZXRpcXVldGEgRU5URVJBIChuaSBhcnRpc3Rh
:::LCBuaQogICAgICAgIGFsYnVtLCBuaSBwb3J0YWRhKS4KICAgICAgwrcgTTRBOiBh
:::dG9tb3MgTVA0IGVzdGFuZGFyICjCqW5hbS/CqUFSVC9hQVJUL8KpYWxiL8KpZGF5
:::L8KpY210KSB5CiAgICAgICAgY292ciBlbiBKUEVHLCBjb21vIGlUdW5lczsgYWRl
:::bWFzICh2Mi44KSBlbCBhdG9tbyBtb292IHF1ZWRhCiAgICAgICAgQUwgUFJJTkNJ
:::UElPIGRlbCBhcmNoaXZvIChmYXN0c3RhcnQpOiBmZm1wZWcgbG8gZXNjcmliZSBh
:::bAogICAgICAgIGZpbmFsIHkgbG9zIHJlcHJvZHVjdG9yZXMgYmFyYXRvcyBzb2xv
:::IGVzY2FuZWFuIGxhIGNhYmVjZXJhLAogICAgICAgIHBvciBlc28gbW9zdHJhYmFu
:::ICd1bmtub3duJyBhdW5xdWUgbGFzIGV0aXF1ZXRhcyBlc3R1dmllcmFuLgogICAg
:::ICDCtyBXQVY6IElEMyBkZW50cm8gZGVsIFJJRkYgKG11dGFnZW4ud2F2ZSksIGln
:::dWFsIHF1ZSBlbCBNUDMsCiAgICAgICAgbWFzIEFQSUMgY29uIGxhIGNhcmF0dWxh
:::IChudWV2byBlbiB2Mi43KS4KICAgICAgwrcgRkxBQzogVm9yYmlzIGNvbW1lbnRz
:::ICsgUGljdHVyZSBlbiBKUEVHLgogICAgICDCtyBXTUE6IEFTRiBUaXRsZS9BdXRo
:::b3IvV00vQWxidW1UaXRsZS9XTS9BdXRob3JVUkwgKyBXTS9QaWN0dXJlLgogICAg
:::ICDCtyBsYSBjYXJhdHVsYSBTSUVNUFJFIGFjYWJhIGVuIEpQRUcgeSBzZSBlc2Ny
:::aWJlIEFRVUkgY29uCiAgICAgICAgbXV0YWdlbjogZGVzZGUgdjIuNyBFbWJlZFRo
:::dW1ibmFpbCB5YSBubyB0b2NhIGxhIGNhcmF0dWxhCiAgICAgICAgKHN1IG1ldG9k
:::byBjYW1iaWEgZW50cmUgdmVyc2lvbmVzIGRlIHl0LWRscCB5IGFsZ3VuYQogICAg
:::ICAgIGNvbnZlcnNpb24gc3V5YSBkZWphYmEgUE5HL1dlYlAgcXVlIGxvcyByZXBy
:::b2R1Y3RvcmVzCiAgICAgICAgYmFyYXRvcyBubyBsZWVuKTsKICAgICAgwrcgZWwg
:::Y29tZW50YXJpbyBndWFyZGEgbGEgVVJMIGRlbCB2aWRlbyAoY29tbyBlbCBzY3Jp
:::cHQgYW50aWd1bykuCiAgICBgY2FyYXR1bGFgIHNvbiBsb3MgYnl0ZXMgZGUgbGEg
:::bWluaWF0dXJhIGRlc2NhcmdhZGEgKG9wY2lvbmFsKS4iIiIKICAgIHRyeToKICAg
:::ICAgICBwID0gUGF0aChhcmNoaXZvKQogICAgICAgIGlmIG5vdCBwLmV4aXN0cygp
:::OgogICAgICAgICAgICByZXR1cm4KICAgICAgICBhcnRpc3RhID0gX2FydGlzdGFf
:::bGltcGlvKGluZm8pCiAgICAgICAgYWxidW0gPSBfYWxidW1fZGUoaW5mbykKICAg
:::ICAgICB0aXR1bG8gPSBzdHIoaW5mby5nZXQoJ3RyYWNrJykgb3IgaW5mby5nZXQo
:::J3RpdGxlJykgb3IgJycpLnN0cmlwKCkKICAgICAgICBmZWNoYSA9IHN0cihpbmZv
:::LmdldCgncmVsZWFzZV95ZWFyJykgb3IgJycpCiAgICAgICAgaWYgbm90IGZlY2hh
:::OgogICAgICAgICAgICBmZWNoYSA9IHN0cihpbmZvLmdldCgndXBsb2FkX2RhdGUn
:::KSBvciAnJykKICAgICAgICAgICAgaWYgbGVuKGZlY2hhKSA9PSA4IGFuZCBmZWNo
:::YS5pc2RpZ2l0KCk6CiAgICAgICAgICAgICAgICBmZWNoYSA9IGZlY2hhWzo0XQog
:::ICAgICAgIHVybCA9IHN0cihpbmZvLmdldCgnd2VicGFnZV91cmwnKSBvciAnJyku
:::c3RyaXAoKQogICAgICAgIGlmIGNhcmF0dWxhIGFuZCBub3QgX2VzX2pwZyhjYXJh
:::dHVsYSk6CiAgICAgICAgICAgIGNhcmF0dWxhID0gX2FfanBnKGNhcmF0dWxhKQog
:::ICAgICAgIGV4dCA9IHAuc3VmZml4Lmxvd2VyKCkKICAgICAgICBpZiBleHQgPT0g
:::Jy5tNGEnOgogICAgICAgICAgICAjIHYyLjg6IEFOVEVTIGRlIGV0aXF1ZXRhciwg
:::bW9vdiAodGl0dWxvL2FydGlzdGEvYWxidW0vY292cikKICAgICAgICAgICAgIyBh
:::bCBwcmluY2lwaW8gZGVsIGFyY2hpdm87IG11dGFnZW4gY29uc2VydmEgZXNlIG9y
:::ZGVuLgogICAgICAgICAgICBpZiBfbW9vdl9hbF9wcmluY2lwaW8ocCkgYW5kIGxv
:::ZzoKICAgICAgICAgICAgICAgIGxvZygnTTRBIHJlb3JkZW5hZG86IGV0aXF1ZXRh
:::cyBhbCBpbmljaW8gKGZhc3RzdGFydCwgJwogICAgICAgICAgICAgICAgICAgICdj
:::b21vIGlUdW5lcyknLCAnZ3JpcycpCiAgICAgICAgICAgIGZyb20gbXV0YWdlbi5t
:::cDQgaW1wb3J0IE1QNCwgTVA0Q292ZXIKICAgICAgICAgICAgbSA9IE1QNChzdHIo
:::cCkpCiAgICAgICAgICAgIGlmIHRpdHVsbzoKICAgICAgICAgICAgICAgIG1bJ1x4
:::YTluYW0nXSA9IFt0aXR1bG9dCiAgICAgICAgICAgIGlmIGFydGlzdGE6CiAgICAg
:::ICAgICAgICAgICBtWydceGE5QVJUJ10gPSBbYXJ0aXN0YV0KICAgICAgICAgICAg
:::ICAgIG1bJ2FBUlQnXSA9IFthcnRpc3RhXQogICAgICAgICAgICBpZiBhbGJ1bToK
:::ICAgICAgICAgICAgICAgIG1bJ1x4YTlhbGInXSA9IFthbGJ1bV0KICAgICAgICAg
:::ICAgaWYgZmVjaGE6CiAgICAgICAgICAgICAgICBtWydceGE5ZGF5J10gPSBbZmVj
:::aGFdCiAgICAgICAgICAgIGlmIHVybDoKICAgICAgICAgICAgICAgIG1bJ1x4YTlj
:::bXQnXSA9IFt1cmxdCiAgICAgICAgICAgICMgLS0gY2FyYXR1bGE6IGRlc2RlIHYy
:::LjcgbGEgZXNjcmliZSBTSUVNUFJFIGVzdGUgcGFzZSBjb24KICAgICAgICAgICAg
:::IyAgICBtdXRhZ2VuIChFbWJlZFRodW1ibmFpbCB5YSBubyBwYXJ0aWNpcGEpLiBB
:::dG9tbwogICAgICAgICAgICAjICAgIGVzdGFuZGFyICdjb3ZyJyAoc2luIGVsIHBy
:::ZWZpam8gKGMpKTsgZW4gbXV0YWdlbgogICAgICAgICAgICAjICAgIG1vZGVybm8g
:::ZXNjcmliaXIgJ1x4YTljb3ZyJyBsYW56YSBUeXBlRXJyb3IuCiAgICAgICAgICAg
:::IHZpZWphcyA9IG0uZ2V0KCdjb3ZyJykgb3IgbS5nZXQoJ1x4YTljb3ZyJykgb3Ig
:::W10KICAgICAgICAgICAgaWYgbm90IHZpZWphczoKICAgICAgICAgICAgICAgIGlm
:::IGNhcmF0dWxhOgogICAgICAgICAgICAgICAgICAgIG1bJ2NvdnInXSA9IFtNUDRD
:::b3ZlcihjYXJhdHVsYSwgTVA0Q292ZXIuRk9STUFUX0pQRUcpXQogICAgICAgICAg
:::ICBlbGlmIGFsbChjLmltYWdlZm9ybWF0ICE9IE1QNENvdmVyLkZPUk1BVF9KUEVH
:::CiAgICAgICAgICAgICAgICAgICAgIGZvciBjIGluIHZpZWphcyk6CiAgICAgICAg
:::ICAgICAgICBudWV2YSA9IF9hX2pwZyhieXRlcyh2aWVqYXNbMF0pKSBvciBjYXJh
:::dHVsYQogICAgICAgICAgICAgICAgaWYgbnVldmE6CiAgICAgICAgICAgICAgICAg
:::ICAgbVsnY292ciddID0gW01QNENvdmVyKG51ZXZhLCBNUDRDb3Zlci5GT1JNQVRf
:::SlBFRyldCiAgICAgICAgICAgICAgICAgICAgbS5wb3AoJ1x4YTljb3ZyJywgTm9u
:::ZSkKICAgICAgICAgICAgZWxpZiBtLmdldCgnXHhhOWNvdnInKToKICAgICAgICAg
:::ICAgICAgIG1bJ2NvdnInXSA9IHZpZWphcwogICAgICAgICAgICAgICAgbS5wb3Ao
:::J1x4YTljb3ZyJywgTm9uZSkKICAgICAgICAgICAgbS5zYXZlKCkKICAgICAgICBl
:::bGlmIGV4dCA9PSAnLm1wMyc6CiAgICAgICAgICAgICMgRm9ybWF0byBFWEFDVE8g
:::ZGVsIE1QMyBkZSByZWZlcmVuY2lhIChTbmFwdHViZSwgZXNjcml0byBwb3IKICAg
:::ICAgICAgICAgIyBGRm1wZWcvTGF2ZikgcXVlIGVsIHJlcHJvZHVjdG9yIGRlbCB1
:::c3VhcmlvIFNJIG11ZXN0cmE6CiAgICAgICAgICAgICMgICBJRDN2Mi40LjAgKyBU
:::SVQyL1RQRTEvVEFMQi9BUElDIGVuIGVuY29kaW5nPTEgKFVURi0xNiBjb24KICAg
:::ICAgICAgICAgIyAgIEJPTSkgKyBBUElDKG1pbWUgJ2ltYWdlL2pwZycsIHRpcG8g
:::MyA9IENPVkVSX0ZST05ULCBkZXNjCiAgICAgICAgICAgICMgICAnYXR0YWNoZWQg
:::cGljdHVyZScsIEpQRUcgcmVhbCkuIEVsIHBhc2UgYW50ZXJpb3IgZXNjcmliaWEK
:::ICAgICAgICAgICAgIyAgIGVuY29kaW5nPTMgKFVURi04KSBkZW50cm8gZGUgdW4g
:::dGFnIHYyLjM6IGZ1ZXJhIGRlCiAgICAgICAgICAgICMgICBlc3BlY2lmaWNhY2lv
:::biwgeSBsb3MgcmVwcm9kdWN0b3JlcyBiYXJhdG9zIGRlc2NhcnRhYmFuCiAgICAg
:::ICAgICAgICMgICBsYSBldGlxdWV0YSBlbnRlcmEgKG5pIGFydGlzdGEsIG5pIGFs
:::YnVtLCBuaSBwb3J0YWRhKS4KICAgICAgICAgICAgZnJvbSBtdXRhZ2VuLmlkMyBp
:::bXBvcnQgKEFQSUMsIENPTU0sIElEMywgVEFMQiwgVERSQywgVElUMiwKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFRMRU4sIFRQRTEsIFRQRTIp
:::CiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHRhZ3MgPSBJRDMoc3Ry
:::KHApKQogICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICAg
:::ICAgdGFncyA9IElEMygpCiAgICAgICAgICAgIGlmIHRpdHVsbzoKICAgICAgICAg
:::ICAgICAgIHRhZ3Muc2V0YWxsKCdUSVQyJywgW1RJVDIoZW5jb2Rpbmc9MSwgdGV4
:::dD1bdGl0dWxvXSldKQogICAgICAgICAgICBpZiBhcnRpc3RhOgogICAgICAgICAg
:::ICAgICAgdGFncy5zZXRhbGwoJ1RQRTEnLCBbVFBFMShlbmNvZGluZz0xLCB0ZXh0
:::PVthcnRpc3RhXSldKQogICAgICAgICAgICAgICAgdGFncy5zZXRhbGwoJ1RQRTIn
:::LCBbVFBFMihlbmNvZGluZz0xLCB0ZXh0PVthcnRpc3RhXSldKQogICAgICAgICAg
:::ICBpZiBhbGJ1bToKICAgICAgICAgICAgICAgIHRhZ3Muc2V0YWxsKCdUQUxCJywg
:::W1RBTEIoZW5jb2Rpbmc9MSwgdGV4dD1bYWxidW1dKV0pCiAgICAgICAgICAgIGlm
:::IGZlY2hhOgogICAgICAgICAgICAgICAgdGFncy5zZXRhbGwoJ1REUkMnLCBbVERS
:::QyhlbmNvZGluZz0xLCB0ZXh0PVtmZWNoYV0pXSkKICAgICAgICAgICAgZHVyID0g
:::aW5mby5nZXQoJ2R1cmF0aW9uJykKICAgICAgICAgICAgaWYgZHVyOgogICAgICAg
:::ICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgICAgIHRhZ3Muc2V0YWxsKCdU
:::TEVOJywgW1RMRU4oZW5jb2Rpbmc9MCwgdGV4dD1bCiAgICAgICAgICAgICAgICAg
:::ICAgICAgIHN0cihpbnQoZmxvYXQoZHVyKSAqIDEwMDApKV0pXSkKICAgICAgICAg
:::ICAgICAgIGV4Y2VwdCAoVHlwZUVycm9yLCBWYWx1ZUVycm9yKToKICAgICAgICAg
:::ICAgICAgICAgICBwYXNzCiAgICAgICAgICAgIGlmIHVybDoKICAgICAgICAgICAg
:::ICAgIHRhZ3Muc2V0YWxsKCdDT01NJywgW0NPTU0oZW5jb2Rpbmc9MSwgbGFuZz0n
:::ZW5nJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ZGVzYz0nJywgdGV4dD1bdXJsXSldKQogICAgICAgICAgICAjIFBvcnRhZGE6IG1p
:::c21hcyBjb25zdGFudGVzIGRlbCBhcmNoaXZvIGRlIHJlZmVyZW5jaWEuCiAgICAg
:::ICAgICAgICMgQnl0ZXM6IGBjYXJhdHVsYWAgbywgc2kgRW1iZWRUaHVtYm5haWwg
:::eWEgaW5jcnVzdG8gYWxnbywKICAgICAgICAgICAgIyBsb3MgZGF0b3MgZGVsIEFQ
:::SUMgZXhpc3RlbnRlOyBzaWVtcHJlIGFjYWJhbW9zIGVuIEpQRUcuCiAgICAgICAg
:::ICAgIGRhdG9zID0gY2FyYXR1bGEKICAgICAgICAgICAgaWYgbm90IGRhdG9zOgog
:::ICAgICAgICAgICAgICAgYXBpY3MgPSB0YWdzLmdldGFsbCgnQVBJQycpCiAgICAg
:::ICAgICAgICAgICBpZiBhcGljczoKICAgICAgICAgICAgICAgICAgICBkYXRvcyA9
:::IGFwaWNzWzBdLmRhdGEKICAgICAgICAgICAgaWYgZGF0b3MgYW5kIG5vdCBfZXNf
:::anBnKGRhdG9zKToKICAgICAgICAgICAgICAgIGRhdG9zID0gX2FfanBnKGRhdG9z
:::KQogICAgICAgICAgICBpZiBkYXRvczoKICAgICAgICAgICAgICAgIHRhZ3Muc2V0
:::YWxsKCdBUElDJywgW0FQSUMoZW5jb2Rpbmc9MSwgbWltZT0naW1hZ2UvanBnJywK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZT0z
:::LCBkZXNjPSdhdHRhY2hlZCBwaWN0dXJlJywKICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgZGF0YT1kYXRvcyldKQogICAgICAgICAgICAj
:::IHYyLjQgKyBVVEYtMTY6IGxhIG1pc21hIGNvbWJpbmFjaW9uIGRlbCBhcmNoaXZv
:::IGRlCiAgICAgICAgICAgICMgcmVmZXJlbmNpYSAoSUQzdjIuNC4wIGVzY3JpdG8g
:::cG9yIExhdmY2MC4zLjEwMCkuCiAgICAgICAgICAgIHRhZ3Muc2F2ZShzdHIocCks
:::IHYyX3ZlcnNpb249NCkKICAgICAgICBlbGlmIGV4dCA9PSAnLndhdic6CiAgICAg
:::ICAgICAgIGZyb20gbXV0YWdlbi5pZDMgaW1wb3J0IChBUElDLCBDT01NLCBURFJD
:::LCBUSVQyLCBUTEVOLCBUUEUxLAogICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgVFBFMiwgVEFMQikKICAgICAgICAgICAgZnJvbSBtdXRhZ2VuLndh
:::dmUgaW1wb3J0IFdBVkUKICAgICAgICAgICAgdyA9IFdBVkUoc3RyKHApKQogICAg
:::ICAgICAgICBpZiB3LnRhZ3MgaXMgTm9uZToKICAgICAgICAgICAgICAgIHcuYWRk
:::X3RhZ3MoKQogICAgICAgICAgICAjIGVuY29kaW5nPTEgKFVURi0xNiksIG1pc21h
:::IHJlZ2xhIHF1ZSBlbiBNUDM6IGxvcwogICAgICAgICAgICAjIHJlcHJvZHVjdG9y
:::ZXMgYmFyYXRvcyBubyBwYXJzZWFuIGZyYW1lcyBVVEYtOC4KICAgICAgICAgICAg
:::aWYgdGl0dWxvOgogICAgICAgICAgICAgICAgdy50YWdzLnNldGFsbCgnVElUMics
:::IFtUSVQyKGVuY29kaW5nPTEsIHRleHQ9W3RpdHVsb10pXSkKICAgICAgICAgICAg
:::aWYgYXJ0aXN0YToKICAgICAgICAgICAgICAgIHcudGFncy5zZXRhbGwoJ1RQRTEn
:::LCBbVFBFMShlbmNvZGluZz0xLCB0ZXh0PVthcnRpc3RhXSldKQogICAgICAgICAg
:::ICAgICAgdy50YWdzLnNldGFsbCgnVFBFMicsIFtUUEUyKGVuY29kaW5nPTEsIHRl
:::eHQ9W2FydGlzdGFdKV0pCiAgICAgICAgICAgIGlmIGFsYnVtOgogICAgICAgICAg
:::ICAgICAgdy50YWdzLnNldGFsbCgnVEFMQicsIFtUQUxCKGVuY29kaW5nPTEsIHRl
:::eHQ9W2FsYnVtXSldKQogICAgICAgICAgICBpZiBmZWNoYToKICAgICAgICAgICAg
:::ICAgIHcudGFncy5zZXRhbGwoJ1REUkMnLCBbVERSQyhlbmNvZGluZz0xLCB0ZXh0
:::PVtmZWNoYV0pXSkKICAgICAgICAgICAgZHVyID0gaW5mby5nZXQoJ2R1cmF0aW9u
:::JykKICAgICAgICAgICAgaWYgZHVyOgogICAgICAgICAgICAgICAgdHJ5OgogICAg
:::ICAgICAgICAgICAgICAgIHcudGFncy5zZXRhbGwoJ1RMRU4nLCBbVExFTihlbmNv
:::ZGluZz0wLCB0ZXh0PVsKICAgICAgICAgICAgICAgICAgICAgICAgc3RyKGludChm
:::bG9hdChkdXIpICogMTAwMCkpXSldKQogICAgICAgICAgICAgICAgZXhjZXB0IChU
:::eXBlRXJyb3IsIFZhbHVlRXJyb3IpOgogICAgICAgICAgICAgICAgICAgIHBhc3MK
:::ICAgICAgICAgICAgaWYgdXJsOgogICAgICAgICAgICAgICAgdy50YWdzLnNldGFs
:::bCgnQ09NTScsIFtDT01NKGVuY29kaW5nPTEsIGxhbmc9J2VuZycsCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGVzYz0nJywgdGV4
:::dD1bdXJsXSldKQogICAgICAgICAgICAjIHYyLjc6IGNhcmF0dWxhIGVuIGVsIElE
:::MyBkZWwgV0FWIChtaXNtYXMgY29uc3RhbnRlcyBxdWUKICAgICAgICAgICAgIyBl
:::bCBNUDMgZGUgcmVmZXJlbmNpYSksIHBhcmEgbG9zIHJlcHJvZHVjdG9yZXMgcXVl
:::IGxlZW4KICAgICAgICAgICAgIyBlbCBjaHVuayAnaWQzICcgZGVudHJvIGRlbCBS
:::SUZGLgogICAgICAgICAgICBkYXRvcyA9IGNhcmF0dWxhCiAgICAgICAgICAgIGlm
:::IG5vdCBkYXRvczoKICAgICAgICAgICAgICAgIGFwaWNzID0gdy50YWdzLmdldGFs
:::bCgnQVBJQycpCiAgICAgICAgICAgICAgICBpZiBhcGljczoKICAgICAgICAgICAg
:::ICAgICAgICBkYXRvcyA9IGFwaWNzWzBdLmRhdGEKICAgICAgICAgICAgaWYgZGF0
:::b3MgYW5kIG5vdCBfZXNfanBnKGRhdG9zKToKICAgICAgICAgICAgICAgIGRhdG9z
:::ID0gX2FfanBnKGRhdG9zKQogICAgICAgICAgICBpZiBkYXRvczoKICAgICAgICAg
:::ICAgICAgIHcudGFncy5zZXRhbGwoJ0FQSUMnLCBbQVBJQyhlbmNvZGluZz0xLCBt
:::aW1lPSdpbWFnZS9qcGcnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIHR5cGU9MywgZGVzYz0nYXR0YWNoZWQgcGljdHVyZScsCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YT1k
:::YXRvcyldKQogICAgICAgICAgICB3LnNhdmUoKQogICAgICAgIGVsaWYgZXh0ID09
:::ICcuZmxhYyc6CiAgICAgICAgICAgIGZyb20gbXV0YWdlbi5mbGFjIGltcG9ydCBG
:::TEFDLCBQaWN0dXJlCiAgICAgICAgICAgIGYgPSBGTEFDKHN0cihwKSkKICAgICAg
:::ICAgICAgaWYgdGl0dWxvOgogICAgICAgICAgICAgICAgZlsndGl0bGUnXSA9IFt0
:::aXR1bG9dCiAgICAgICAgICAgIGlmIGFydGlzdGE6CiAgICAgICAgICAgICAgICBm
:::WydhcnRpc3QnXSA9IFthcnRpc3RhXQogICAgICAgICAgICAgICAgZlsnYWxidW1h
:::cnRpc3QnXSA9IFthcnRpc3RhXQogICAgICAgICAgICBpZiBhbGJ1bToKICAgICAg
:::ICAgICAgICAgIGZbJ2FsYnVtJ10gPSBbYWxidW1dCiAgICAgICAgICAgIGlmIGZl
:::Y2hhOgogICAgICAgICAgICAgICAgZlsnZGF0ZSddID0gW2ZlY2hhXQogICAgICAg
:::ICAgICBpZiB1cmw6CiAgICAgICAgICAgICAgICBmWydjb21tZW50J10gPSBbdXJs
:::XQogICAgICAgICAgICBpZiBub3QgZi5waWN0dXJlczoKICAgICAgICAgICAgICAg
:::IGlmIGNhcmF0dWxhOgogICAgICAgICAgICAgICAgICAgIHBpYyA9IFBpY3R1cmUo
:::KQogICAgICAgICAgICAgICAgICAgIHBpYy5taW1lLCBwaWMudHlwZSwgcGljLmRl
:::c2MgPSAnaW1hZ2UvanBlZycsIDMsICdDb3ZlcicKICAgICAgICAgICAgICAgICAg
:::ICBwaWMuZGF0YSA9IGNhcmF0dWxhCiAgICAgICAgICAgICAgICAgICAgZi5hZGRf
:::cGljdHVyZShwaWMpCiAgICAgICAgICAgIGVsaWYgYWxsKHBpLm1pbWUgIT0gJ2lt
:::YWdlL2pwZWcnIGZvciBwaSBpbiBmLnBpY3R1cmVzKToKICAgICAgICAgICAgICAg
:::IG51ZXZhID0gX2FfanBnKGYucGljdHVyZXNbMF0uZGF0YSkgb3IgY2FyYXR1bGEK
:::ICAgICAgICAgICAgICAgIGlmIG51ZXZhOgogICAgICAgICAgICAgICAgICAgIGZv
:::ciB2aWVqYSBpbiBsaXN0KGYucGljdHVyZXMpOgogICAgICAgICAgICAgICAgICAg
:::ICAgICBmLnJlbW92ZV9waWN0dXJlKHZpZWphKQogICAgICAgICAgICAgICAgICAg
:::IHBpYyA9IFBpY3R1cmUoKQogICAgICAgICAgICAgICAgICAgIHBpYy5taW1lLCBw
:::aWMudHlwZSwgcGljLmRlc2MgPSAnaW1hZ2UvanBlZycsIDMsICdDb3ZlcicKICAg
:::ICAgICAgICAgICAgICAgICBwaWMuZGF0YSA9IG51ZXZhCiAgICAgICAgICAgICAg
:::ICAgICAgZi5hZGRfcGljdHVyZShwaWMpCiAgICAgICAgICAgIGYuc2F2ZSgpCiAg
:::ICAgICAgZWxpZiBleHQgPT0gJy53bWEnOgogICAgICAgICAgICBmcm9tIG11dGFn
:::ZW4uYXNmIGltcG9ydCBBU0YsIEFTRkJ5dGVBcnJheUF0dHJpYnV0ZQogICAgICAg
:::ICAgICBhID0gQVNGKHN0cihwKSkKICAgICAgICAgICAgaWYgdGl0dWxvOgogICAg
:::ICAgICAgICAgICAgYVsnVGl0bGUnXSA9IFt0aXR1bG9dCiAgICAgICAgICAgIGlm
:::IGFydGlzdGE6CiAgICAgICAgICAgICAgICBhWydBdXRob3InXSA9IFthcnRpc3Rh
:::XQogICAgICAgICAgICAgICAgYVsnV00vQWxidW1BcnRpc3QnXSA9IFthcnRpc3Rh
:::XQogICAgICAgICAgICBpZiBhbGJ1bToKICAgICAgICAgICAgICAgIGFbJ1dNL0Fs
:::YnVtVGl0bGUnXSA9IFthbGJ1bV0KICAgICAgICAgICAgaWYgZmVjaGE6CiAgICAg
:::ICAgICAgICAgICBhWydXTS9ZZWFyJ10gPSBbZmVjaGFdCiAgICAgICAgICAgIGlm
:::IHVybDoKICAgICAgICAgICAgICAgIGFbJ0Rlc2NyaXB0aW9uJ10gPSBbdXJsXQog
:::ICAgICAgICAgICAgICAgYVsnV00vQXV0aG9yVVJMJ10gPSBbdXJsXQogICAgICAg
:::ICAgICBpZiBjYXJhdHVsYToKICAgICAgICAgICAgICAgIGFbJ1dNL1BpY3R1cmUn
:::XSA9IFtBU0ZCeXRlQXJyYXlBdHRyaWJ1dGUoCiAgICAgICAgICAgICAgICAgICAg
:::X3dtX3BpY3R1cmUoY2FyYXR1bGEsIHRpdHVsbyBvciAnQ292ZXInKSldCiAgICAg
:::ICAgICAgIGEuc2F2ZSgpCiAgICAgICAgZWxzZToKICAgICAgICAgICAgcmV0dXJu
:::CiAgICAgICAgaWYgbG9nOgogICAgICAgICAgICBleHRyYSA9ICcgwrcgY2Fyw6F0
:::dWxhIEpQRUcnIGlmIGNhcmF0dWxhIGVsc2UgJycKICAgICAgICAgICAgbG9nKCdF
:::dGlxdWV0YXMgZXNjcml0YXM6IGFydGlzdGEgwqslc8K7IMK3IMOhbGJ1bSDCqyVz
:::wrslcycKICAgICAgICAgICAgICAgICUgKGFydGlzdGEgb3IgJ+KAlCcsIGFsYnVt
:::IG9yICfigJQnLCBleHRyYSksICdncmlzJykKICAgIGV4Y2VwdCBFeGNlcHRpb24g
:::YXMgZToKICAgICAgICAjIGxhcyBldGlxdWV0YXMgbm8gc29uIGNyaXRpY2FzOiBu
:::dW5jYSBkZWJlbiByb21wZXIgbGEgZGVzY2FyZ2EKICAgICAgICBpZiBsb2c6CiAg
:::ICAgICAgICAgIGxvZygnTm8gc2UgcHVkaWVyb24gZXNjcmliaXIgdG9kYXMgbGFz
:::IGV0aXF1ZXRhczogJXMnICUgZSwKICAgICAgICAgICAgICAgICdhdmlzbycpCgoK
:::IyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tIGRlc2NhcmdhcwpkZWYgZGVzY2FyZ2FyX2F1ZGlv
:::KHVybCwgbm9tYnJlX2ZtdCwgY2FsaWRhZCwgZGVzdGlubywgZW1iZWJlciwgY29s
:::YSk6CiAgICAiIiJBQUMgKC5tNGEpIC8gTVAzIC8gRkxBQyAvIFdBViB2w61hIHBv
:::c3Rwcm9jZXNhZG9yZXMgZGUgeXQtZGxwLgoKICAgIHl0LWRscCBTT0xPIGJhamEs
:::IGNvbnZpZXJ0ZSB5IGVzY3JpYmUgbG9zIG1ldGFkYXRvcyBkZSB0ZXh0bwogICAg
:::KEZGbXBlZ01ldGFkYXRhKS4gTGEgY2Fyw6F0dWxhIE5PIGxhIGluY3J1c3RhIEVt
:::YmVkVGh1bWJuYWlsOiBkZXNkZQogICAgdjIuNyBsYSBlc2NyaWJlIGFwbGljYXJf
:::dGFncyBjb24gbXV0YWdlbiAoY292ciBlbiBtNGEsIEFQSUMgZW4KICAgIG1wMy93
:::YXYsIFBpY3R1cmUgZW4gZmxhYyksIHNpZW1wcmUgZW4gSlBFRyB5IGNvbiBsYSBl
:::c3RydWN0dXJhCiAgICBleGFjdGEgcXVlIGxlZW4gbG9zIHJlcHJvZHVjdG9yZXMu
:::IEFzw60gZWwgcmVzdWx0YWRvIG5vIGRlcGVuZGUgZGUKICAgIGxvcyBtw6l0b2Rv
:::cyBpbnRlcm5vcyBkZSBFbWJlZFRodW1ibmFpbCwgcXVlIGNhbWJpYW4gZW50cmUK
:::ICAgIHZlcnNpb25lcyBkZSB5dC1kbHAgKGFudGVzIGNvbnZlcnTDrWEgbGEgcG9y
:::dGFkYSBhIFBORywgeSBzdQogICAgbcOpdG9kbyBmZm1wZWcgYWRqdW50YSBsYSBp
:::bWFnZW4gY29tbyBzdHJlYW0gZGUgdsOtZGVvKS4iIiIKICAgIGRlZiBsb2cobSwg
:::dD0naW5mbycpOgogICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAg
:::Zm10ID0gRk9STUFUT1Nbbm9tYnJlX2ZtdF0KICAgIGNhcnBldGEgPSBkZXN0aW5v
:::ICAgICAgICAgICMgdjIuMzogc2luIHN1YmNhcnBldGFzIHBvciBmb3JtYXRvCiAg
:::ICBjYXJwZXRhLm1rZGlyKHBhcmVudHM9VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAg
:::IGNvZGVjID0gZm10WydleHQnXQogICAgY29uX3BvcnRhZGEgPSBlbWJlYmVyIGFu
:::ZCBub21icmVfZm10IGluICgnQUFDJywgJ01QMycsICdGTEFDJywgJ1dBVicpCiAg
:::ICBjb25fdGFncyA9IGVtYmViZXIKICAgIHBwcyA9IFtdCiAgICBpZiBjb25fcG9y
:::dGFkYToKICAgICAgICBwcHMuYXBwZW5kKHsna2V5JzogJ0ZGbXBlZ1RodW1ibmFp
:::bHNDb252ZXJ0b3InLCAnZm9ybWF0JzogJ2pwZycsCiAgICAgICAgICAgICAgICAg
:::ICAgJ3doZW4nOiAnYmVmb3JlX2RsJ30pCiAgICBwcHMuYXBwZW5kKHsna2V5Jzog
:::J0ZGbXBlZ0V4dHJhY3RBdWRpbycsICdwcmVmZXJyZWRjb2RlYyc6IGNvZGVjLAog
:::ICAgICAgICAgICAgICAgJ3ByZWZlcnJlZHF1YWxpdHknOiBjYWxpZGFkIG9yICcw
:::J30pCiAgICBpZiBjb25fdGFnczoKICAgICAgICBwcHMuYXBwZW5kKHsna2V5Jzog
:::J0ZGbXBlZ01ldGFkYXRhJywgJ2FkZF9tZXRhZGF0YSc6IFRydWV9KQogICAgIyB2
:::Mi43OiBTSU4gRW1iZWRUaHVtYm5haWwuIExhIG1pbmlhdHVyYSAoZGVqYWRhIGVu
:::IC5qcGcganVudG8gYWwKICAgICMgYXJjaGl2byBwb3Igd3JpdGV0aHVtYm5haWwg
:::KyBDb252ZXJ0b3IpIGxhIGluY3J1c3RhIGFwbGljYXJfdGFncwogICAgIyBjb24g
:::bXV0YWdlbjogZXN0cnVjdHVyYSBnYXJhbnRpemFkYSBlbiB0b2RvcyBsb3MgZm9y
:::bWF0b3MgeSBzaW4KICAgICMgZGVwZW5kZXIgZGUgbG9zIG3DqXRvZG9zIGludGVy
:::bm9zIGRlIHl0LWRscC4KICAgIG8gPSBvcHRzX2Jhc2UoY2FycGV0YSwgY29sYSkK
:::ICAgIG9bJ2Zvcm1hdCddID0gJ2Jlc3RhdWRpby9iZXN0JwogICAgb1sncG9zdHBy
:::b2Nlc3NvcnMnXSA9IHBwcwogICAgb1snd3JpdGV0aHVtYm5haWwnXSA9IGNvbl9w
:::b3J0YWRhCiAgICB3aXRoIFlUX0RMUC5Zb3V0dWJlREwobykgYXMgeWRsOgogICAg
:::ICAgIGluZm8gPSB5ZGwuZXh0cmFjdF9pbmZvKHVybCwgZG93bmxvYWQ9VHJ1ZSkK
:::ICAgIGFyY2hpdm8gPSBhcmNoaXZvX2ZpbmFsKGluZm8sIGNhcnBldGEsIGNvZGVj
:::KQogICAgY2FyYXR1bGEgPSBfbWluaWF0dXJhX2J5dGVzKGNhcnBldGEsIGFyY2hp
:::dm8pCiAgICBpZiBhcmNoaXZvIGFuZCBjb25fcG9ydGFkYToKICAgICAgICBsaW1w
:::aWFyX21pbmlhdHVyYXMoY2FycGV0YSwgYXJjaGl2bykKICAgIGlmIGFyY2hpdm86
:::CiAgICAgICAgYXBsaWNhcl90YWdzKGluZm8sIGFyY2hpdm8sIGxvZywgY2FyYXR1
:::bGEpCiAgICByZXR1cm4gaW5mbywgYXJjaGl2bwoKCmRlZiBkZXNjYXJnYXJfd21h
:::KHVybCwgY2FsaWRhZCwgZGVzdGlubywgZW1iZWJlciwgY29sYSk6CiAgICAiIiJX
:::TUEgOTYvMTI4IGticHM6IHl0LWRscCBubyBzb3BvcnRhIHdtYSwgYXPDrSBxdWUg
:::c2UgYmFqYSBhIFdBViAoY29uCiAgICBldGlxdWV0YXMpIHkgbHVlZ28gRkZtcGVn
:::IHJlY29kaWZpY2EgYSB3bWF2MiBkZW50cm8gZGVsIC53bWEgZmluYWwuCiAgICBM
:::YSBjYXLDoXR1bGEgKFdNL1BpY3R1cmUsIGVuIEpQRUcpIHkgbGEgVVJMIChXTS9B
:::dXRob3JVUkwpIHNlCiAgICBpbmNydXN0YW4gY29uIG11dGFnZW4sIGNvbW8gZW4g
:::ZWwgc2NyaXB0IGFudGlndW8uIiIiCiAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToK
:::ICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgIGNhcnBldGEgPSBk
:::ZXN0aW5vICAgICAgICAgICMgdjIuMzogc2luIHN1YmNhcnBldGFzIHBvciBmb3Jt
:::YXRvCiAgICB0bXAgPSBjYXJwZXRhIC8gJ190bXAnCiAgICBzaHV0aWwucm10cmVl
:::KHRtcCwgaWdub3JlX2Vycm9ycz1UcnVlKQogICAgdG1wLm1rZGlyKHBhcmVudHM9
:::VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgIG8gPSBvcHRzX2Jhc2UodG1wLCBjb2xh
:::KQogICAgb1snZm9ybWF0J10gPSAnYmVzdGF1ZGlvL2Jlc3QnCiAgICBwcHMgPSBb
:::eydrZXknOiAnRkZtcGVnRXh0cmFjdEF1ZGlvJywgJ3ByZWZlcnJlZGNvZGVjJzog
:::J3dhdicsCiAgICAgICAgICAgICdwcmVmZXJyZWRxdWFsaXR5JzogJzAnfV0KICAg
:::IGlmIGVtYmViZXI6CiAgICAgICAgcHBzLmluc2VydCgwLCB7J2tleSc6ICdGRm1w
:::ZWdUaHVtYm5haWxzQ29udmVydG9yJywKICAgICAgICAgICAgICAgICAgICAgICAn
:::Zm9ybWF0JzogJ2pwZycsICd3aGVuJzogJ2JlZm9yZV9kbCd9KQogICAgICAgIHBw
:::cy5hcHBlbmQoeydrZXknOiAnRkZtcGVnTWV0YWRhdGEnLCAnYWRkX21ldGFkYXRh
:::JzogVHJ1ZX0pCiAgICBvWydwb3N0cHJvY2Vzc29ycyddID0gcHBzCiAgICBvWyd3
:::cml0ZXRodW1ibmFpbCddID0gZW1iZWJlcgogICAgd2l0aCBZVF9ETFAuWW91dHVi
:::ZURMKG8pIGFzIHlkbDoKICAgICAgICBpbmZvID0geWRsLmV4dHJhY3RfaW5mbyh1
:::cmwsIGRvd25sb2FkPVRydWUpCiAgICB3YXYgPSBhcmNoaXZvX2ZpbmFsKGluZm8s
:::IHRtcCwgJ3dhdicpCiAgICBpZiBub3Qgd2F2OgogICAgICAgIHJhaXNlIFJ1bnRp
:::bWVFcnJvcignTm8gc2UgZW5jb250csOzIGVsIFdBViBpbnRlcm1lZGlvLicpCiAg
:::ICBtZXRhID0gW10KICAgIGlmIGVtYmViZXI6CiAgICAgICAgYXJ0aXN0YSA9IChp
:::bmZvLmdldCgnYXJ0aXN0Jykgb3IgaW5mby5nZXQoJ3VwbG9hZGVyJykKICAgICAg
:::ICAgICAgICAgICAgIG9yIGluZm8uZ2V0KCdjaGFubmVsJykgb3IgJycpCiAgICAg
:::ICAgaWYgaW5mby5nZXQoJ3RpdGxlJyk6CiAgICAgICAgICAgIG1ldGEgKz0gWyct
:::bWV0YWRhdGEnLCAndGl0bGU9JyArIHN0cihpbmZvWyd0aXRsZSddKV0KICAgICAg
:::ICBpZiBhcnRpc3RhOgogICAgICAgICAgICBtZXRhICs9IFsnLW1ldGFkYXRhJywg
:::J2FydGlzdD0nICsgc3RyKGFydGlzdGEpXQogICAgd21hID0gY2FycGV0YSAvIChs
:::aW1waWFyX25vbWJyZShpbmZvLmdldCgndGl0bGUnKSBvciAnYXVkaW8nKSArICcu
:::d21hJykKICAgIGNtZCA9IFtzdHIoRkZNUEVHKSwgJy15JywgJy1pJywgc3RyKHdh
:::diksICctdm4nLAogICAgICAgICAgICctYzphJywgJ3dtYXYyJywgJy1iOmEnLCBm
:::J3tjYWxpZGFkfWsnXSArIG1ldGEgKyBbc3RyKHdtYSldCiAgICBvayA9IGNvbnZl
:::cnRpcl9mZm1wZWcoCiAgICAgICAgY21kLCBmJ0NvbnZpcnRpZW5kbyBhIFdNQSAo
:::d21hdjIgwrcge2NhbGlkYWR9IGticHMpJywgY29sYSkKICAgIGlmIG5vdCBvazoK
:::ICAgICAgICByYWlzZSBSdW50aW1lRXJyb3IoJ0ZGbXBlZyBubyBwdWRvIGNyZWFy
:::IGVsIGFyY2hpdm8gV01BLicpCiAgICBjYXJhdHVsYSA9IE5vbmUKICAgIGlmIGVt
:::YmViZXI6CiAgICAgICAganBncyA9IHNvcnRlZCh0bXAuZ2xvYignKi5qcGcnKSwK
:::ICAgICAgICAgICAgICAgICAgICAgIGtleT1sYW1iZGEgcTogcS5zdGF0KCkuc3Rf
:::bXRpbWUsIHJldmVyc2U9VHJ1ZSkKICAgICAgICBpZiBqcGdzOgogICAgICAgICAg
:::ICB0cnk6CiAgICAgICAgICAgICAgICBjYXJhdHVsYSA9IGpwZ3NbMF0ucmVhZF9i
:::eXRlcygpCiAgICAgICAgICAgIGV4Y2VwdCBPU0Vycm9yOgogICAgICAgICAgICAg
:::ICAgY2FyYXR1bGEgPSBOb25lCiAgICBhcGxpY2FyX3RhZ3MoaW5mbywgd21hLCBs
:::b2csIGNhcmF0dWxhKQogICAgc2h1dGlsLnJtdHJlZSh0bXAsIGlnbm9yZV9lcnJv
:::cnM9VHJ1ZSkKICAgIHJldHVybiBpbmZvLCB3bWEKCgpkZWYgbWV0YV9yaWZmX2lu
:::Zm8oaW5mbyk6CiAgICAiIiJ2Mi43OiBhcmd1bWVudG9zIC1tZXRhZGF0YSBwYXJh
:::IGxvcyB0YWdzIFJJRkYgSU5GTyBkZWwgQVZJLgoKICAgIEZGbXBlZyBsb3MgbWFw
:::ZWEgYSBJTkFNICh0aXR1bG8pLCBJQVJUIChhcnRpc3RhKSwgSVBSRCAoYWxidW0p
:::LAogICAgSUNSRCAoZmVjaGEpIGUgSUNNVCAoY29tZW50YXJpbykgZGVudHJvIGRl
:::bCBjaHVuayBMSVNUL0lORk8gZGVsCiAgICBSSUZGLCBxdWUgZXMgZG9uZGUgbG9z
:::IHJlcHJvZHVjdG9yZXMgYnVzY2FuIGxvcyBkYXRvcyBkZSB1biBBVkkuIiIiCiAg
:::ICB0aXR1bG8gPSBzdHIoaW5mby5nZXQoJ3RyYWNrJykgb3IgaW5mby5nZXQoJ3Rp
:::dGxlJykgb3IgJycpLnN0cmlwKCkKICAgIGFydGlzdGEgPSBfYXJ0aXN0YV9saW1w
:::aW8oaW5mbykKICAgIGFsYnVtID0gX2FsYnVtX2RlKGluZm8pCiAgICBmZWNoYSA9
:::IHN0cihpbmZvLmdldCgncmVsZWFzZV95ZWFyJykgb3IgJycpCiAgICBpZiBub3Qg
:::ZmVjaGE6CiAgICAgICAgZmVjaGEgPSBzdHIoaW5mby5nZXQoJ3VwbG9hZF9kYXRl
:::Jykgb3IgJycpWzo0XQogICAgdXJsID0gc3RyKGluZm8uZ2V0KCd3ZWJwYWdlX3Vy
:::bCcpIG9yICcnKS5zdHJpcCgpCiAgICBtZXRhID0gW10KICAgIGlmIHRpdHVsbzoK
:::ICAgICAgICBtZXRhICs9IFsnLW1ldGFkYXRhJywgJ3RpdGxlPScgKyB0aXR1bG9d
:::CiAgICBpZiBhcnRpc3RhOgogICAgICAgIG1ldGEgKz0gWyctbWV0YWRhdGEnLCAn
:::YXJ0aXN0PScgKyBhcnRpc3RhXQogICAgaWYgYWxidW06CiAgICAgICAgbWV0YSAr
:::PSBbJy1tZXRhZGF0YScsICdhbGJ1bT0nICsgYWxidW1dCiAgICBpZiBmZWNoYToK
:::ICAgICAgICBtZXRhICs9IFsnLW1ldGFkYXRhJywgJ2RhdGU9JyArIGZlY2hhXQog
:::ICAgaWYgdXJsOgogICAgICAgIG1ldGEgKz0gWyctbWV0YWRhdGEnLCAnY29tbWVu
:::dD0nICsgdXJsXQogICAgcmV0dXJuIG1ldGEKCgojIFBhcsOhbWV0cm9zIG9maWNp
:::YWxlcyBkZWwgcmVwbyBmZGQ0cy9wb3J0YWJsZV9tcDNfcGxheWVyX3ZpZGVvX2Nv
:::bnZlcnRlcl90b29scwojICh2aWRlbzJzaGVuanUxOC5zaCk6IE1KUEVHIDE2IGZw
:::cyArIFBDTSAyMjA1MCBIeiwgcm90YWRvcyBwYXJhIGxhIHBhbnRhbGxhCiMgdmVy
:::dGljYWwgZGUgMTI4eDE2MCBkZWwgcmVwcm9kdWN0b3Igc2hlaWp1IGRlIDEuOCBw
:::dWxnYWRhcy4KVkZfU0hFSUpVID0gJ3NjYWxlPS0yOjEyOCwgY3JvcD0xNjA6MTI4
:::LCB0cmFuc3Bvc2U9MiwgdmZsaXAnCiMgVmFyaWFudGUgYSBwcnVlYmEgZGUgYmFs
:::YXMgcGFyYSB2aWRlb3MgY3VhZHJhZG9zL3ZlcnRpY2FsZXMgKFNob3J0cyksCiMg
:::ZG9uZGUgZWwgcmVjb3J0ZSAxNjA6MTI4IG9yaWdpbmFsIHNlcsOtYSBpbXBvc2li
:::bGU6ClZGX1NFR1VSTyA9ICgnc2NhbGU9MTYwOjEyODpmb3JjZV9vcmlnaW5hbF9h
:::c3BlY3RfcmF0aW89ZGVjcmVhc2UsJwogICAgICAgICAgICAgJ3BhZD0xNjA6MTI4
:::Oihvdy1pdykvMjoob2gtaWgpLzIsdHJhbnNwb3NlPTIsdmZsaXAnKQoKCmRlZiBk
:::ZXNjYXJnYXJfYXZpKHVybCwgZGVzdGlubywgY29sYSk6CiAgICAiIiJWaWRlbyBB
:::VkkgcGFyYSBlbCByZXByb2R1Y3RvciBzaGVpanUgMS44IiAxMjh4MTYwLiIiIgog
:::ICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAgICAgICAgY29sYS5wdXQoKCdsb2cn
:::LCBtLCB0KSkKCiAgICBjYXJwZXRhID0gZGVzdGlubyAgICAgICAgICAjIHYyLjM6
:::IHNpbiBzdWJjYXJwZXRhcyBwb3IgZm9ybWF0bwogICAgdG1wID0gY2FycGV0YSAv
:::ICdfdG1wJwogICAgc2h1dGlsLnJtdHJlZSh0bXAsIGlnbm9yZV9lcnJvcnM9VHJ1
:::ZSkKICAgIHRtcC5ta2RpcihwYXJlbnRzPVRydWUsIGV4aXN0X29rPVRydWUpCiAg
:::ICBvID0gb3B0c19iYXNlKHRtcCwgY29sYSkKICAgICMgUGFyYSB1bmEgcGFudGFs
:::bGEgZGUgMTI4eDE2MCBiYXN0YSBjb24gNDgwcDogYWhvcnJhIG11Y2hhIGRlc2Nh
:::cmdhLgogICAgb1snZm9ybWF0J10gPSAoJ2Jlc3RbaGVpZ2h0PD00ODBdW2V4dD1t
:::cDRdL2Jlc3RbaGVpZ2h0PD00ODBdLycKICAgICAgICAgICAgICAgICAgICdidipb
:::aGVpZ2h0PD00ODBdK2JhL2InKQogICAgb1snbWVyZ2Vfb3V0cHV0X2Zvcm1hdCdd
:::ID0gJ21wNCcKICAgIHdpdGggWVRfRExQLllvdXR1YmVETChvKSBhcyB5ZGw6CiAg
:::ICAgICAgaW5mbyA9IHlkbC5leHRyYWN0X2luZm8odXJsLCBkb3dubG9hZD1UcnVl
:::KQogICAgb3JpZ2VuID0gYXJjaGl2b19maW5hbChpbmZvLCB0bXAsICdtcDQnKQog
:::ICAgaWYgbm90IG9yaWdlbjoKICAgICAgICBvcmlnZW4gPSAoYXJjaGl2b19maW5h
:::bChpbmZvLCB0bXAsICdta3YnKQogICAgICAgICAgICAgICAgICBvciBhcmNoaXZv
:::X2ZpbmFsKGluZm8sIHRtcCwgJ3dlYm0nKSkKICAgIGlmIG5vdCBvcmlnZW46CiAg
:::ICAgICAgcmFpc2UgUnVudGltZUVycm9yKCdObyBzZSBlbmNvbnRyw7MgZWwgdmlk
:::ZW8gZGVzY2FyZ2Fkby4nKQogICAgYXZpID0gY2FycGV0YSAvIChsaW1waWFyX25v
:::bWJyZShpbmZvLmdldCgndGl0bGUnKSBvciAndmlkZW8nKSArICcuYXZpJykKICAg
:::ICMgdjIuNzogZXRpcXVldGFzIFJJRkYgSU5GTyBkZW50cm8gZGVsIEFWSSAodmVy
:::IG1ldGFfcmlmZl9pbmZvKQogICAgIyBwYXJhIHF1ZSBlbCB2aWRlbyB0YW1iaWVu
:::IG11ZXN0cmUgdGl0dWxvIHkgYXJ0aXN0YSBkb25kZSBlbAogICAgIyByZXByb2R1
:::Y3RvciBzZXBhIGxlZXJsYXMuCiAgICBtZXRhID0gbWV0YV9yaWZmX2luZm8oaW5m
:::bykKICAgIGJhc2UgPSBbc3RyKEZGTVBFRyksICcteScsICctaScsIHN0cihvcmln
:::ZW4pLCAnLXInLCAnMTYnLAogICAgICAgICAgICAnLWFjb2RlYycsICdwY21fczE2
:::bGUnLCAnLWFjJywgJzInLCAnLWFyJywgJzIyMDUwJywKICAgICAgICAgICAgJy1w
:::aXhfZm10JywgJ3l1dmo0MjBwJywgJy1jOnYnLCAnbWpwZWcnLCAnLXE6dicsICcy
:::J10gKyBtZXRhCiAgICBvayA9IGNvbnZlcnRpcl9mZm1wZWcoYmFzZSArIFsnLXZm
:::JywgVkZfU0hFSUpVLCBzdHIoYXZpKV0sCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgJ0NvbnZpcnRpZW5kbyBhIEFWSSAxMjh4MTYwIChzaGVpanUgMS44IiknLCBj
:::b2xhKQogICAgaWYgbm90IG9rOgogICAgICAgIGxvZygnVmlkZW8gY29uIHByb3Bv
:::cmNpw7NuIG5vIGVzdMOhbmRhcjsgJwogICAgICAgICAgICAncmVpbnRlbnRhbmRv
:::IGVuIG1vZG8gY29tcGF0aWJsZS4uLicsICdhdmlzbycpCiAgICAgICAgb2sgPSBj
:::b252ZXJ0aXJfZmZtcGVnKGJhc2UgKyBbJy12ZicsIFZGX1NFR1VSTywgc3RyKGF2
:::aSldLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAnUmVjb252aXJ0aWVu
:::ZG8gYSBBVkkgMTI4eDE2MCcsIGNvbGEpCiAgICBpZiBub3Qgb2s6CiAgICAgICAg
:::cmFpc2UgUnVudGltZUVycm9yKCdGRm1wZWcgbm8gcHVkbyBjcmVhciBlbCBhcmNo
:::aXZvIEFWSS4nKQogICAgc2h1dGlsLnJtdHJlZSh0bXAsIGlnbm9yZV9lcnJvcnM9
:::VHJ1ZSkKICAgIHJldHVybiBpbmZvLCBhdmkKCgojIC0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0g
:::ZXN0aW1hY2nDs24KS0JQU19FU1RJTUFET1MgPSB7CiAgICAnQUFDJzogMTI4LCAg
:::ICAgIyB0ZWNobyBkZWwgZm9ybWF0bwogICAgJ1dNQSc6IDEyOCwKICAgICdXQVYn
:::OiAxNDExLCAgICAjIFBDTSA0NC4xIGtIeiDCtyAxNiBiaXQgwrcgZXN0w6lyZW8K
:::ICAgICdGTEFDJzogOTUwLCAgICAjIHTDrXBpY28gZGUgbcO6c2ljYSBwcm9jZWRl
:::bnRlIGRlIFlvdVR1YmUKICAgICdBVkknOiAxNDkwLCAgICAjIH43ODQga2JwcyBN
:::SlBFRyAxNmZwcyArIDcwNiBrYnBzIFBDTSAyMjA1MCBlc3TDqXJlbwp9CgoKZGVm
:::IGVzdGltYXJfYnl0ZXMoZHVyYWNpb25fcywgZm9ybWF0bywgY2FsaWRhZCwgZW1i
:::ZWJlcik6CiAgICAiIiJFc3RpbWEgZWwgdGFtYcOxbyBmaW5hbCBlbiBieXRlcyAo
:::Y8OhbGN1bG8gcHVybywgdGVzdGVhYmxlKS4iIiIKICAgIGlmIGZvcm1hdG8gaW4g
:::KCdNUDMnLCAnQUFDJywgJ1dNQScpOgogICAgICAgIGticHMgPSBpbnQocmUuc3Vi
:::KHInW14wLTldJywgJycsIHN0cihjYWxpZGFkKSkgb3IgMCkKICAgICAgICBpZiBu
:::b3Qga2JwczoKICAgICAgICAgICAga2JwcyA9IEtCUFNfRVNUSU1BRE9TLmdldChm
:::b3JtYXRvLCAxMjgpCiAgICBlbHNlOgogICAgICAgIGticHMgPSBLQlBTX0VTVElN
:::QURPUy5nZXQoZm9ybWF0bywgMTI4KQogICAgZXh0cmEgPSAxMjBfMDAwIGlmIChl
:::bWJlYmVyIGFuZCBmb3JtYXRvIGluICgnQUFDJywgJ01QMycsICdGTEFDJywKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ1dB
:::VicpKSBlbHNlIDAKICAgIHJldHVybiBkdXJhY2lvbl9zICoga2JwcyAqIDEwMDAg
:::LyA4ICsgZXh0cmEKCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gY2FsaWRhZApkZWYgY2xh
:::c2VfY2FsaWRhZChleHQsIGticHMpOgogICAgIiIiQ2xhc2lmaWNhIHVuIGFyY2hp
:::dm8uIERldnVlbHZlICh0ZXh0bywgbml2ZWwpIGNvbiBuaXZlbCAwPW9rIDE9bWVk
:::aWEgMj1iYWphLiIiIgogICAgaWYgZXh0ID09ICcubXAzJzoKICAgICAgICBpZiBr
:::YnBzID49IDMxNToKICAgICAgICAgICAgcmV0dXJuICczMjAga2JwcycsIDAKICAg
:::ICAgICBpZiBrYnBzID49IDI1MDoKICAgICAgICAgICAgcmV0dXJuICcyNTYga2Jw
:::cycsIDAKICAgICAgICBpZiBrYnBzID49IDE4NToKICAgICAgICAgICAgcmV0dXJu
:::ICcxOTIga2JwcycsIDAKICAgICAgICBpZiBrYnBzID49IDEyMDoKICAgICAgICAg
:::ICAgcmV0dXJuICcxMjgga2JwcycsIDEKICAgICAgICByZXR1cm4gZid7a2Jwc30g
:::a2JwcyAoYmFqYSknLCAyCiAgICBpZiBleHQgPT0gJy5tNGEnOgogICAgICAgIGlm
:::IGticHMgPj0gMTE1OgogICAgICAgICAgICByZXR1cm4gJ0V4Y2VsZW50ZSAoQUFD
:::IOKJpDEyOGspJywgMAogICAgICAgIGlmIGticHMgPj0gODI6CiAgICAgICAgICAg
:::IHJldHVybiAnOTYga2JwcycsIDEKICAgICAgICByZXR1cm4gZid7a2Jwc30ga2Jw
:::cyAoYmFqYSknLCAyCiAgICBpZiBleHQgPT0gJy53bWEnOgogICAgICAgIGlmIGti
:::cHMgPj0gMTE1OgogICAgICAgICAgICByZXR1cm4gJzEyOCBrYnBzJywgMAogICAg
:::ICAgIGlmIGticHMgPj0gODg6CiAgICAgICAgICAgIHJldHVybiAnOTYga2Jwcycs
:::IDEKICAgICAgICByZXR1cm4gZid7a2Jwc30ga2JwcyAoYmFqYSknLCAyCiAgICBp
:::ZiBleHQgaW4gKCcuZmxhYycsICcud2F2Jyk6CiAgICAgICAgcmV0dXJuICdTaW4g
:::cMOpcmRpZGEnLCAwCiAgICBpZiBleHQgPT0gJy5hdmknOgogICAgICAgIGlmIGti
:::cHMgPj0gMTIwMDoKICAgICAgICAgICAgcmV0dXJuIGYne2ticHN9IGticHMgKE1K
:::UEVHK1BDTSAxMjh4MTYwKScsIDAKICAgICAgICByZXR1cm4gZid7a2Jwc30ga2Jw
:::cyAoYWxnbyBiYWpvKScsIDEKICAgIHJldHVybiBmJ3trYnBzfSBrYnBzJywgMQoK
:::CiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLSB0ZW1hcwpURU1BUyA9IHsKICAgICdPc2N1cm8n
:::OiBkaWN0KAogICAgICAgIGZvbmRvPScjMWUxZjIyJywgY2FtcG89JyMyYTJkMzEn
:::LCBjYW1wb19ib3JkZT0nIzNhM2U0NCcsCiAgICAgICAgdGV4dG89JyNkOGRhZGMn
:::LCB0ZXh0bzI9JyM5YTlmYTQnLAogICAgICAgIGJvdG9uPScjM2EzZDQyJywgYm90
:::b25fYWN0PScjNGE0ZTU1JywgYm90b25fdHh0PScjZThlYWVjJywKICAgICAgICBs
:::b2c9JyMxNDE1MTgnLCBsb2dfdHh0PScjY2ZkM2Q3JywgYWNlbnRvPScjNGY5Y2Y5
:::JywKICAgICAgICBvaz0nIzdlYzk3ZicsIGVycm9yPScjZTU3MzczJywgYXZpc289
:::JyNkOGI2NGEnLCB0cm91Z2g9JyMyNjI4MmMnLAogICAgICAgIHBsYWNlaG9sZGVy
:::PScjNzc3YzgyJyksCiAgICAnQ2xhcm8nOiBkaWN0KAogICAgICAgIGZvbmRvPScj
:::ZjJmM2Y1JywgY2FtcG89JyNmZmZmZmYnLCBjYW1wb19ib3JkZT0nI2M0YzhjZCcs
:::CiAgICAgICAgdGV4dG89JyMyNDI3MmEnLCB0ZXh0bzI9JyM2YTcwNzYnLAogICAg
:::ICAgIGJvdG9uPScjZTNlNWU4JywgYm90b25fYWN0PScjZDJkNWRhJywgYm90b25f
:::dHh0PScjMjQyNzJhJywKICAgICAgICBsb2c9JyNmZmZmZmYnLCBsb2dfdHh0PScj
:::MmIyZTMxJywgYWNlbnRvPScjMWE2NmQ2JywKICAgICAgICBvaz0nIzFlN2UzNCcs
:::IGVycm9yPScjYzYyODI4JywgYXZpc289JyM5YTY3MDAnLCB0cm91Z2g9JyNkZmUx
:::ZTQnLAogICAgICAgIHBsYWNlaG9sZGVyPScjOWFhMGE2JyksCn0KClBMQUNFSE9M
:::REVSX1VSTCA9ICdodHRwczovL3d3dy55b3V0dWJlLmNvbS93YXRjaD92PS4uLicK
:::CkZVRU5URV9VSSA9ICgnU2Vnb2UgVUknLCA5KQpGVUVOVEVfQlROID0gKCdTZWdv
:::ZSBVSScsIDEwKQpGVUVOVEVfQlROX0cgPSAoJ1NlZ29lIFVJJywgMTEpCkZVRU5U
:::RV9MT0cgPSAoJ0NvbnNvbGFzJywgMTApCgoKaWYgVEtfT0s6CgogICAgY2xhc3Mg
:::QXBwKHRrLlRrKToKICAgICAgICAiIiJWZW50YW5hIHByaW5jaXBhbCAoZGlzZcOx
:::byBlc3Blam8gZGVsIG1vY2t1cDogZ3J1cG9zIG9zY3Vyb3MpLiIiIgoKICAgICAg
:::ICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLSBjb25zdHJ1Y2Npw7NuCiAgICAgICAgZGVmIF9faW5pdF9fKHNlbGYpOgog
:::ICAgICAgICAgICBpZiBnZXRhdHRyKHN5cywgJ2Zyb3plbicsIEZhbHNlKToKICAg
:::ICAgICAgICAgICAgIHBhc3MKICAgICAgICAgICAgc3VwZXIoKS5fX2luaXRfXygp
:::CiAgICAgICAgICAgIHNlbGYudGl0bGUoJ011c2lrQUxBTicpCiAgICAgICAgICAg
:::IHNlbGYuZ2VvbWV0cnkoJzg2MHg4NDAnKQogICAgICAgICAgICBzZWxmLm1pbnNp
:::emUoNzAwLCA2NjApCiAgICAgICAgICAgIHNlbGYuY29sYSA9IHF1ZXVlLlF1ZXVl
:::KCkKICAgICAgICAgICAgc2VsZi5fb2N1cGFkbyA9IEZhbHNlCiAgICAgICAgICAg
:::IHNlbGYuX2VuX3BsYWNlaG9sZGVyID0gVHJ1ZQogICAgICAgICAgICBzZWxmLl90
:::ZW1hX2FjdHVhbCA9IEFKVVNURVMuZ2V0KCd0ZW1hJywgJ09zY3VybycpCiAgICAg
:::ICAgICAgIGlmIHNlbGYuX3RlbWFfYWN0dWFsIG5vdCBpbiBURU1BUzoKICAgICAg
:::ICAgICAgICAgIHNlbGYuX3RlbWFfYWN0dWFsID0gJ09zY3VybycKCiAgICAgICAg
:::ICAgIHNlbGYuX2VzdGlsbyA9IHR0ay5TdHlsZShzZWxmKQogICAgICAgICAgICB0
:::cnk6CiAgICAgICAgICAgICAgICBzZWxmLl9lc3RpbG8udGhlbWVfdXNlKCdjbGFt
:::JykKICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgICAg
:::IHBhc3MKCiAgICAgICAgICAgIHNlbGYuX2NvbnN0cnVpcigpCiAgICAgICAgICAg
:::IHNlbGYuX2FwbGljYXJfdGVtYSgpCiAgICAgICAgICAgIHNlbGYuX2NvbmVjdGFy
:::X2V2ZW50b3MoKQogICAgICAgICAgICBSRUdJU1RSTy5sb2cgPSBsYW1iZGEgbSwg
:::dD0nYXZpc28nOiBzZWxmLmNvbGEucHV0KCgnbG9nJywgbSwgdCkpCiAgICAgICAg
:::ICAgIHNlbGYuYWZ0ZXIoODAsIHNlbGYuX2JvbWJlYXJfY29sYSkKICAgICAgICAg
:::ICAgc2VsZi5hZnRlcigxNTAsIHNlbGYuX2FycmFucXVlKQoKICAgICAgICBkZWYg
:::X2NvbnN0cnVpcihzZWxmKToKICAgICAgICAgICAgc2VsZi5fd2cgPSB7fSAgICAg
:::ICAgICMgcmVmZXJlbmNpYXMgcGFyYSBlbCB0ZW1hCiAgICAgICAgICAgIHNlbGYu
:::X2J0bnMgPSBbXSAgICAgICAjIGJvdG9uZXMgcGxhbm9zIChwYXJhIGhvdmVyL3Rl
:::bWEpCiAgICAgICAgICAgIG1hcmNvID0gdGsuRnJhbWUoc2VsZikKICAgICAgICAg
:::ICAgbWFyY28ucGFjayhmaWxsPSdib3RoJywgZXhwYW5kPVRydWUsIHBhZHg9MTAs
:::IHBhZHk9OCkKICAgICAgICAgICAgc2VsZi5fd2dbJ21hcmNvJ10gPSBtYXJjbwog
:::ICAgICAgICAgICBtYXJjby5jb2x1bW5jb25maWd1cmUoMCwgd2VpZ2h0PTEpCgog
:::ICAgICAgICAgICAjIC0tLSBmaWxhIFRlbWEgLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAgIGYwID0gdGsu
:::RnJhbWUobWFyY28pCiAgICAgICAgICAgIGYwLmdyaWQocm93PTAsIGNvbHVtbj0w
:::LCBzdGlja3k9J2V3JywgcGFkeT0oMCwgNikpCiAgICAgICAgICAgIHNlbGYuX3dn
:::WydmMCddID0gZjAKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF90ZW1hJ10gPSB0
:::ay5MYWJlbChmMCwgdGV4dD0nVGVtYTonLCBmb250PUZVRU5URV9VSSkKICAgICAg
:::ICAgICAgc2VsZi5fd2dbJ2xibF90ZW1hJ10ucGFjayhzaWRlPSdsZWZ0JykKICAg
:::ICAgICAgICAgc2VsZi5jbWJfdGVtYSA9IHR0ay5Db21ib2JveCgKICAgICAgICAg
:::ICAgICAgIGYwLCB2YWx1ZXM9bGlzdChURU1BUyksIHN0YXRlPSdyZWFkb25seScs
:::IHdpZHRoPTksCiAgICAgICAgICAgICAgICBmb250PUZVRU5URV9VSSwgc3R5bGU9
:::J2d4LlRDb21ib2JveCcpCiAgICAgICAgICAgIHNlbGYuY21iX3RlbWEuc2V0KHNl
:::bGYuX3RlbWFfYWN0dWFsKQogICAgICAgICAgICBzZWxmLmNtYl90ZW1hLnBhY2so
:::c2lkZT0nbGVmdCcsIHBhZHg9KDgsIDApLCBpcGFkeT0yKQoKICAgICAgICAgICAg
:::IyAtLS0gZ3J1cG86IFVSTCBkZSBZb3VUdWJlIC0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLQogICAgICAgICAgICBndSA9IHRrLkxhYmVsRnJhbWUo
:::bWFyY28sIHRleHQ9J1VSTCBkZSBZb3VUdWJlJywgZm9udD1GVUVOVEVfVUksCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWxpZWY9J3NvbGlkJywgYmQ9
:::MSkKICAgICAgICAgICAgZ3UuZ3JpZChyb3c9MSwgY29sdW1uPTAsIHN0aWNreT0n
:::ZXcnLCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYuX3dnWydndSddID0gZ3UKICAg
:::ICAgICAgICAgZ3UuY29sdW1uY29uZmlndXJlKDAsIHdlaWdodD0xKQogICAgICAg
:::ICAgICBzZWxmLmVudF91cmwgPSB0ay5FbnRyeShndSwgZm9udD1GVUVOVEVfVUks
:::IHJlbGllZj0nZmxhdCcsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIGhpZ2hsaWdodHRoaWNrbmVzcz0xKQogICAgICAgICAgICBzZWxmLmVudF91
:::cmwuZ3JpZChyb3c9MCwgY29sdW1uPTAsIHN0aWNreT0nZXcnLAogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICBwYWR4PTgsIHBhZHk9OCwgaXBhZHk9NSkKICAg
:::ICAgICAgICAgc2VsZi5fcG9uZXJfcGxhY2Vob2xkZXIoKQogICAgICAgICAgICBz
:::ZWxmLmJ0bl94ID0gc2VsZi5fYm90b24oZ3UsICdYJywgc2VsZi5fbGltcGlhcl91
:::cmwsIHdpZHRoPTMpCiAgICAgICAgICAgIHNlbGYuYnRuX3guZ3JpZChyb3c9MCwg
:::Y29sdW1uPTEsIHN0aWNreT0nZScsIHBhZHg9KDAsIDgpLCBpcGFkeT0zKQoKICAg
:::ICAgICAgICAgIyAtLS0gZ3J1cG86IEZvcm1hdG8geSBjYWxpZGFkIC0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAgICAgICBnZiA9IHRrLkxh
:::YmVsRnJhbWUobWFyY28sIHRleHQ9J0Zvcm1hdG8geSBjYWxpZGFkJywgZm9udD1G
:::VUVOVEVfVUksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWxpZWY9
:::J3NvbGlkJywgYmQ9MSkKICAgICAgICAgICAgZ2YuZ3JpZChyb3c9MiwgY29sdW1u
:::PTAsIHN0aWNreT0nZXcnLCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYuX3dnWydn
:::ZiddID0gZ2YKICAgICAgICAgICAgZ2YuY29sdW1uY29uZmlndXJlKDEsIHdlaWdo
:::dD0xKQogICAgICAgICAgICBzZWxmLl93Z1snbGJsX2ZtdCddID0gdGsuTGFiZWwo
:::Z2YsIHRleHQ9J0Zvcm1hdG86JywgZm9udD1GVUVOVEVfVUkpCiAgICAgICAgICAg
:::IHNlbGYuX3dnWydsYmxfZm10J10uZ3JpZChyb3c9MCwgY29sdW1uPTAsIHN0aWNr
:::eT0ndycsIHBhZHg9OCwgcGFkeT01KQogICAgICAgICAgICBzZWxmLmNtYl9mb3Jt
:::YXRvID0gdHRrLkNvbWJvYm94KAogICAgICAgICAgICAgICAgZ2YsIHZhbHVlcz1b
:::ZlsndGV4dG8nXSBmb3IgZiBpbiBGT1JNQVRPUy52YWx1ZXMoKV0sCiAgICAgICAg
:::ICAgICAgICBzdGF0ZT0ncmVhZG9ubHknLCBmb250PUZVRU5URV9VSSwgc3R5bGU9
:::J2d4LlRDb21ib2JveCcpCiAgICAgICAgICAgIHNlbGYuY21iX2Zvcm1hdG8uZ3Jp
:::ZChyb3c9MCwgY29sdW1uPTEsIHN0aWNreT0nZXcnLAogICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgcGFkeD04LCBwYWR5PTUsIGlwYWR5PTIpCiAgICAg
:::ICAgICAgIHNlbGYuX3dnWydsYmxfY2FsJ10gPSB0ay5MYWJlbChnZiwgdGV4dD0n
:::Q2FsaWRhZDonLCBmb250PUZVRU5URV9VSSkKICAgICAgICAgICAgc2VsZi5fd2db
:::J2xibF9jYWwnXS5ncmlkKHJvdz0xLCBjb2x1bW49MCwgc3RpY2t5PSd3JywgcGFk
:::eD04LCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYuY21iX2NhbGlkYWQgPSB0dGsu
:::Q29tYm9ib3goCiAgICAgICAgICAgICAgICBnZiwgc3RhdGU9J3JlYWRvbmx5Jywg
:::Zm9udD1GVUVOVEVfVUksIHN0eWxlPSdneC5UQ29tYm9ib3gnKQogICAgICAgICAg
:::ICBzZWxmLmNtYl9jYWxpZGFkLmdyaWQocm93PTEsIGNvbHVtbj0xLCBzdGlja3k9
:::J2V3JywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhZHg9OCwg
:::cGFkeT01LCBpcGFkeT0yKQogICAgICAgICAgICBzZWxmLl93Z1snbGJsX2Nhcidd
:::ID0gdGsuTGFiZWwoZ2YsIHRleHQ9J0NhcnBldGE6JywgZm9udD1GVUVOVEVfVUkp
:::CiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfY2FyJ10uZ3JpZChyb3c9MiwgY29s
:::dW1uPTAsIHN0aWNreT0ndycsIHBhZHg9OCwgcGFkeT01KQogICAgICAgICAgICBm
:::YyA9IHRrLkZyYW1lKGdmKQogICAgICAgICAgICBmYy5ncmlkKHJvdz0yLCBjb2x1
:::bW49MSwgc3RpY2t5PSdldycsIHBhZHg9OCwgcGFkeT01KQogICAgICAgICAgICBz
:::ZWxmLl93Z1snZmMnXSA9IGZjCiAgICAgICAgICAgIGZjLmNvbHVtbmNvbmZpZ3Vy
:::ZSgwLCB3ZWlnaHQ9MSkKICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0YSA9IHRr
:::LkVudHJ5KGZjLCBmb250PUZVRU5URV9VSSwgcmVsaWVmPSdmbGF0JywKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGhpZ2hsaWdodHRoaWNr
:::bmVzcz0xKQogICAgICAgICAgICBzZWxmLmVudF9jYXJwZXRhLmdyaWQocm93PTAs
:::IGNvbHVtbj0wLCBzdGlja3k9J2V3JywgaXBhZHk9NCkKICAgICAgICAgICAgc2Vs
:::Zi5lbnRfY2FycGV0YS5pbnNlcnQoMCwgQUpVU1RFU1snZGVzdGlubyddKQogICAg
:::ICAgICAgICBzZWxmLmJ0bl9jYW1iaWFyID0gc2VsZi5fYm90b24oZmMsICdDYW1i
:::aWFyLi4uJywgc2VsZi5fY2FtYmlhcl9jYXJwZXRhKQogICAgICAgICAgICBzZWxm
:::LmJ0bl9jYW1iaWFyLmdyaWQocm93PTAsIGNvbHVtbj0xLCBwYWR4PSg4LCAwKSwg
:::aXBhZHk9MykKICAgICAgICAgICAgc2VsZi5idG5fYWJyaXIgPSBzZWxmLl9ib3Rv
:::bihmYywgJ0FicmlyJywgc2VsZi5fYWJyaXJfZGVzdGlubywgd2lkdGg9NSkKICAg
:::ICAgICAgICAgc2VsZi5idG5fYWJyaXIuZ3JpZChyb3c9MCwgY29sdW1uPTIsIHBh
:::ZHg9KDYsIDApLCBpcGFkeT0zKQoKICAgICAgICAgICAgc2VsZi52YXJfZW1iZWJl
:::ciA9IHRrLkJvb2xlYW5WYXIodmFsdWU9Ym9vbChBSlVTVEVTLmdldCgnZW1iZWJl
:::cicsIFRydWUpKSkKICAgICAgICAgICAgc2VsZi5jaGtfZW1iZWJlciA9IHRrLkNo
:::ZWNrYnV0dG9uKAogICAgICAgICAgICAgICAgZ2YsIHRleHQ9J0VtYmViZXIgY2Fy
:::w6F0dWxhLCBhcnRpc3RhIHkgw6FsYnVtJywKICAgICAgICAgICAgICAgIHZhcmlh
:::YmxlPXNlbGYudmFyX2VtYmViZXIsIGZvbnQ9RlVFTlRFX1VJLCBhbmNob3I9J3cn
:::LAogICAgICAgICAgICAgICAgcmVsaWVmPSdmbGF0JywgaGlnaGxpZ2h0dGhpY2tu
:::ZXNzPTAsIGJkPTApCiAgICAgICAgICAgIHNlbGYuY2hrX2VtYmViZXIuZ3JpZChy
:::b3c9MywgY29sdW1uPTAsIGNvbHVtbnNwYW49MiwKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgIHN0aWNreT0nZXcnLCBwYWR4PTgsIHBhZHk9KDIsIDYp
:::KQogICAgICAgICAgICAjIHYyLjk6IHbDrWEgYW50aS1ibG9xdWVvIChjb29raWVz
:::IGRlbCBuYXZlZ2Fkb3Igc2kgWW91VHViZQogICAgICAgICAgICAjIHBpZGUgdmVy
:::aWZpY2FjacOzbikKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF9jb29raWVzJ10g
:::PSB0ay5MYWJlbCgKICAgICAgICAgICAgICAgIGdmLCB0ZXh0PSdTaSBZb3VUdWJl
:::IGJsb3F1ZWE6JywgZm9udD1GVUVOVEVfVUkpCiAgICAgICAgICAgIHNlbGYuX3dn
:::WydsYmxfY29va2llcyddLmdyaWQocm93PTQsIGNvbHVtbj0wLCBzdGlja3k9J3cn
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhZHg9
:::OCwgcGFkeT01KQogICAgICAgICAgICBzZWxmLmNtYl9jb29raWVzID0gdHRrLkNv
:::bWJvYm94KAogICAgICAgICAgICAgICAgZ2YsIHZhbHVlcz0oWydBdXRvbcOhdGlj
:::byAocmVjb21lbmRhZG8pJ10KICAgICAgICAgICAgICAgICAgICAgICAgICAgICsg
:::WydVc2FyIGNvb2tpZXMgZGUgJyArIG4uY2FwaXRhbGl6ZSgpCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICBmb3IgbiBpbiBOQVZFR0FET1JFU19DT09LSUVT
:::XSksCiAgICAgICAgICAgICAgICBzdGF0ZT0ncmVhZG9ubHknLCBmb250PUZVRU5U
:::RV9VSSwgc3R5bGU9J2d4LlRDb21ib2JveCcpCiAgICAgICAgICAgIHNlbGYuY21i
:::X2Nvb2tpZXMuZ3JpZChyb3c9NCwgY29sdW1uPTEsIHN0aWNreT0nZXcnLAogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFkeD04LCBwYWR5PTUsIGlw
:::YWR5PTIpCiAgICAgICAgICAgIHNlbGYuY21iX2Nvb2tpZXMuc2V0KCdBdXRvbcOh
:::dGljbyAocmVjb21lbmRhZG8pJykKCiAgICAgICAgICAgICMgLS0tIGdydXBvOiBl
:::c3RpbWFjacOzbiAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tCiAgICAgICAgICAgIGdlID0gdGsuTGFiZWxGcmFtZShtYXJjbywgdGV4dD0n
:::RXN0aW1hY2nDs24nLCBmb250PUZVRU5URV9VSSwKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIHJlbGllZj0nc29saWQnLCBiZD0xKQogICAgICAgICAgICBn
:::ZS5ncmlkKHJvdz0zLCBjb2x1bW49MCwgc3RpY2t5PSdldycsIHBhZHk9NSkKICAg
:::ICAgICAgICAgc2VsZi5fd2dbJ2dlJ10gPSBnZQogICAgICAgICAgICBnZS5jb2x1
:::bW5jb25maWd1cmUoMCwgd2VpZ2h0PTEpCiAgICAgICAgICAgIHNlbGYubGJsX2Vz
:::dGltYWNpb24gPSB0ay5MYWJlbCgKICAgICAgICAgICAgICAgIGdlLCB0ZXh0PSdJ
:::bnRyb2R1Y2UgdW5hIFVSTCB5IHB1bHNhIEVzdGltYXIuJywKICAgICAgICAgICAg
:::ICAgIGZvbnQ9RlVFTlRFX1VJLCBhbmNob3I9J3cnKQogICAgICAgICAgICBzZWxm
:::LmxibF9lc3RpbWFjaW9uLmdyaWQocm93PTAsIGNvbHVtbj0wLCBzdGlja3k9J2V3
:::JywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhZHg9OCwg
:::cGFkeT02KQogICAgICAgICAgICBzZWxmLmJ0bl9lc3RpbWFyID0gc2VsZi5fYm90
:::b24oZ2UsICdFc3RpbWFyIHRhbWFubycsCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICBzZWxmLl9hY2Npb25fZXN0aW1hcikKICAgICAg
:::ICAgICAgc2VsZi5idG5fZXN0aW1hci5ncmlkKHJvdz0wLCBjb2x1bW49MSwgc3Rp
:::Y2t5PSdlJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhZHg9
:::OCwgaXBhZHk9MykKCiAgICAgICAgICAgICMgLS0tIGJvdG9uZXMgZ3JhbmRlcyAt
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KICAgICAg
:::ICAgICAgc2VsZi5idG5fZGVzY2FyZ2FyID0gc2VsZi5fYm90b24obWFyY28sICdE
:::ZXNjYXJnYXIgeSBjb252ZXJ0aXInLAogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICBzZWxmLl9hY2Npb25fZGVzY2FyZ2FyLAogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBmdWVudGU9
:::RlVFTlRFX0JUTl9HLCBhbHRvPTIpCiAgICAgICAgICAgIHNlbGYuYnRuX2Rlc2Nh
:::cmdhci5ncmlkKHJvdz00LCBjb2x1bW49MCwgc3RpY2t5PSdldycsIHBhZHk9KDcs
:::IDQpKQogICAgICAgICAgICBzZWxmLmJ0bl9jb21wcm9iYXIgPSBzZWxmLl9ib3Rv
:::bigKICAgICAgICAgICAgICAgIG1hcmNvLCAnQ29tcHJvYmFyIGNhbGlkYWQgZGUg
:::bGEgY2FycGV0YScsCiAgICAgICAgICAgICAgICBzZWxmLl9hY2Npb25fY29tcHJv
:::YmFyLCBmdWVudGU9RlVFTlRFX0JUTikKICAgICAgICAgICAgc2VsZi5idG5fY29t
:::cHJvYmFyLmdyaWQocm93PTUsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgcGFkeT0z
:::KQoKICAgICAgICAgICAgIyAtLS0gZXN0YWRvICsgYmFycmEgZGUgcHJvZ3Jlc28g
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KICAgICAgICAgICAgc2Vs
:::Zi5sYmxfZXN0YWRvID0gdGsuTGFiZWwobWFyY28sIHRleHQ9JycsIGZvbnQ9RlVF
:::TlRFX1VJLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBh
:::bmNob3I9J3cnKQogICAgICAgICAgICBzZWxmLmxibF9lc3RhZG8uZ3JpZChyb3c9
:::NiwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PSg0LCAwKSkKICAgICAgICAg
:::ICAgc2VsZi5iYXJyYSA9IHR0ay5Qcm9ncmVzc2JhcigKICAgICAgICAgICAgICAg
:::IG1hcmNvLCBtYXhpbXVtPTEwMCwgc3R5bGU9J2d4Lkhvcml6b250YWwuVFByb2dy
:::ZXNzYmFyJykKICAgICAgICAgICAgc2VsZi5iYXJyYS5ncmlkKHJvdz03LCBjb2x1
:::bW49MCwgc3RpY2t5PSdldycsIHBhZHk9KDIsIDQpKQoKICAgICAgICAgICAgIyAt
:::LS0gcmVnaXN0cm8gKGxvZykgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0KICAgICAgICAgICAgc2VsZi50eHRfbG9nID0gU2Nyb2xs
:::ZWRUZXh0KG1hcmNvLCBmb250PUZVRU5URV9MT0csIGhlaWdodD0xMiwKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlbGllZj0nZmxhdCcs
:::IGJkPTAsIHdyYXA9J3dvcmQnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgc3RhdGU9J2Rpc2FibGVkJykKICAgICAgICAgICAgc2VsZi50
:::eHRfbG9nLmdyaWQocm93PTgsIGNvbHVtbj0wLCBzdGlja3k9J25zZXcnKQogICAg
:::ICAgICAgICBtYXJjby5yb3djb25maWd1cmUoOCwgd2VpZ2h0PTEpCiAgICAgICAg
:::ICAgIGZvciB0YWcsIGNvbmYgaW4gKAogICAgICAgICAgICAgICAgICAgICgnaW5m
:::bycsIHt9KSwKICAgICAgICAgICAgICAgICAgICAoJ2dyaXMnLCB7fSksCiAgICAg
:::ICAgICAgICAgICAgICAgKCd0aXR1bG8nLCB7fSksCiAgICAgICAgICAgICAgICAg
:::ICAgKCdvaycsIHt9KSwKICAgICAgICAgICAgICAgICAgICAoJ2F2aXNvJywge30p
:::LAogICAgICAgICAgICAgICAgICAgICgnZXJyb3InLCB7fSkpOgogICAgICAgICAg
:::ICAgICAgc2VsZi50eHRfbG9nLnRhZ19jb25maWd1cmUodGFnLCBjb25mKQoKICAg
:::ICAgICAgICAgIyBzaW5jcm9uaXphciB2YWxvcmVzIGd1YXJkYWRvcwogICAgICAg
:::ICAgICBmbXQgPSBBSlVTVEVTLmdldCgnZm9ybWF0bycsICdBQUMnKQogICAgICAg
:::ICAgICBpZiBmbXQgbm90IGluIEZPUk1BVE9TOgogICAgICAgICAgICAgICAgZm10
:::ID0gJ0FBQycKICAgICAgICAgICAgc2VsZi5jbWJfZm9ybWF0by5zZXQoRk9STUFU
:::T1NbZm10XVsndGV4dG8nXSkKICAgICAgICAgICAgc2VsZi5fcmVjYXJnYXJfY2Fs
:::aWRhZGVzKGZtdCwgQUpVU1RFUy5nZXQoJ2NhbGlkYWQnKSkKICAgICAgICAgICAg
:::Y29va2llcyA9IHN0cihBSlVTVEVTLmdldCgnY29va2llcycsICcnKSBvciAnJyku
:::c3RyaXAoKS5sb3dlcigpCiAgICAgICAgICAgIGlmIGNvb2tpZXMgaW4gTkFWRUdB
:::RE9SRVNfQ09PS0lFUzoKICAgICAgICAgICAgICAgIHNlbGYuY21iX2Nvb2tpZXMu
:::c2V0KCdVc2FyIGNvb2tpZXMgZGUgJwogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgKyBjb29raWVzLmNhcGl0YWxpemUoKSkKICAgICAgICAgICAg
:::ZWxzZToKICAgICAgICAgICAgICAgIHNlbGYuY21iX2Nvb2tpZXMuc2V0KCdBdXRv
:::bcOhdGljbyAocmVjb21lbmRhZG8pJykKCiAgICAgICAgIyAtLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gaGVscGVycyB3aWRn
:::ZXRzCiAgICAgICAgZGVmIF9ib3RvbihzZWxmLCBwYWRyZSwgdGV4dG8sIGNtZCwg
:::d2lkdGg9Tm9uZSwgZnVlbnRlPUZVRU5URV9CVE4sCiAgICAgICAgICAgICAgICAg
:::ICBhbHRvPTEpOgogICAgICAgICAgICBiID0gdGsuQnV0dG9uKHBhZHJlLCB0ZXh0
:::PXRleHRvLCBjb21tYW5kPWNtZCwgZm9udD1mdWVudGUsCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgcmVsaWVmPSdmbGF0JywgYmQ9MCwgY3Vyc29yPSdoYW5kMics
:::IGhlaWdodD1hbHRvLAogICAgICAgICAgICAgICAgICAgICAgICAgIGFjdGl2ZWZv
:::cmVncm91bmQ9JyNmZmZmZmYnLCB0YWtlZm9jdXM9MCkKICAgICAgICAgICAgaWYg
:::d2lkdGg6CiAgICAgICAgICAgICAgICBiLmNvbmZpZ3VyZSh3aWR0aD13aWR0aCkK
:::ICAgICAgICAgICAgYi5iaW5kKCc8RW50ZXI+JywgbGFtYmRhIGUsIHc9Yjogdy5j
:::b25maWd1cmUoCiAgICAgICAgICAgICAgICBiZz1URU1BU1tzZWxmLl90ZW1hX2Fj
:::dHVhbF1bJ2JvdG9uX2FjdCddKSkKICAgICAgICAgICAgYi5iaW5kKCc8TGVhdmU+
:::JywgbGFtYmRhIGUsIHc9Yjogdy5jb25maWd1cmUoCiAgICAgICAgICAgICAgICBi
:::Zz1URU1BU1tzZWxmLl90ZW1hX2FjdHVhbF1bJ2JvdG9uJ10pKQogICAgICAgICAg
:::ICBzZWxmLl9idG5zLmFwcGVuZChiKQogICAgICAgICAgICByZXR1cm4gYgoKICAg
:::ICAgICBkZWYgX3BvbmVyX3BsYWNlaG9sZGVyKHNlbGYpOgogICAgICAgICAgICBp
:::ZiBub3Qgc2VsZi5lbnRfdXJsLmdldCgpOgogICAgICAgICAgICAgICAgc2VsZi5f
:::ZW5fcGxhY2Vob2xkZXIgPSBUcnVlCiAgICAgICAgICAgICAgICBzZWxmLmVudF91
:::cmwuaW5zZXJ0KDAsIFBMQUNFSE9MREVSX1VSTCkKCiAgICAgICAgZGVmIF9saW1w
:::aWFyX3VybChzZWxmKToKICAgICAgICAgICAgc2VsZi5lbnRfdXJsLmRlbGV0ZSgw
:::LCAnZW5kJykKICAgICAgICAgICAgc2VsZi5lbnRfdXJsLmZvY3VzX3NldCgpCgog
:::ICAgICAgIGRlZiBfcmVzZXRfdXJsKHNlbGYpOgogICAgICAgICAgICAiIiJEZWph
:::IGVsIGNhbXBvIGRlIFVSTCB2YWPDrW8gY29uIHN1IHBsYWNlaG9sZGVyICh0cmFz
:::IHVuIMOpeGl0bykuIiIiCiAgICAgICAgICAgIHNlbGYuZW50X3VybC5kZWxldGUo
:::MCwgJ2VuZCcpCiAgICAgICAgICAgIHNlbGYuX2VuX3BsYWNlaG9sZGVyID0gVHJ1
:::ZQogICAgICAgICAgICBzZWxmLl9wb25lcl9wbGFjZWhvbGRlcigpCiAgICAgICAg
:::ICAgIHNlbGYuX3JlZnJlc2Nhcl9wbGFjZWhvbGRlcigpCgogICAgICAgICMgLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIHRl
:::bWEKICAgICAgICBkZWYgX2FwbGljYXJfdGVtYShzZWxmKToKICAgICAgICAgICAg
:::dCA9IFRFTUFTW3NlbGYuX3RlbWFfYWN0dWFsXQogICAgICAgICAgICB3ID0gc2Vs
:::Zi5fd2cKICAgICAgICAgICAgc2VsZi5jb25maWd1cmUoYmc9dFsnZm9uZG8nXSkK
:::ICAgICAgICAgICAgZm9yIG5vbWJyZSBpbiAoJ21hcmNvJywgJ2YwJywgJ2d1Jywg
:::J2dmJywgJ2ZjJywgJ2dlJyk6CiAgICAgICAgICAgICAgICB3W25vbWJyZV0uY29u
:::ZmlndXJlKGJnPXRbJ2ZvbmRvJ10pCiAgICAgICAgICAgIGZvciBsZiBpbiAod1sn
:::Z3UnXSwgd1snZ2YnXSwgd1snZ2UnXSk6CiAgICAgICAgICAgICAgICBsZi5jb25m
:::aWd1cmUoYmc9dFsnZm9uZG8nXSwgZmc9dFsndGV4dG8yJ10pCiAgICAgICAgICAg
:::IGZvciBub21icmUgaW4gKCdsYmxfdGVtYScsICdsYmxfZm10JywgJ2xibF9jYWwn
:::LCAnbGJsX2NhcicpOgogICAgICAgICAgICAgICAgd1tub21icmVdLmNvbmZpZ3Vy
:::ZShiZz10Wydmb25kbyddLCBmZz10Wyd0ZXh0byddKQogICAgICAgICAgICBzZWxm
:::LmxibF9lc3RpbWFjaW9uLmNvbmZpZ3VyZShiZz10Wydmb25kbyddLCBmZz10Wyd0
:::ZXh0byddKQogICAgICAgICAgICBzZWxmLmxibF9lc3RhZG8uY29uZmlndXJlKGJn
:::PXRbJ2ZvbmRvJ10sIGZnPXRbJ3RleHRvMiddKQogICAgICAgICAgICBzZWxmLmVu
:::dF91cmwuY29uZmlndXJlKAogICAgICAgICAgICAgICAgYmc9dFsnY2FtcG8nXSwg
:::Zmc9dFsndGV4dG8nXSwgaW5zZXJ0YmFja2dyb3VuZD10Wyd0ZXh0byddLAogICAg
:::ICAgICAgICAgICAgaGlnaGxpZ2h0YmFja2dyb3VuZD10WydjYW1wb19ib3JkZSdd
:::LAogICAgICAgICAgICAgICAgaGlnaGxpZ2h0Y29sb3I9dFsnYWNlbnRvJ10sCiAg
:::ICAgICAgICAgICAgICBkaXNhYmxlZGJhY2tncm91bmQ9dFsnY2FtcG8nXSwgZGlz
:::YWJsZWRmb3JlZ3JvdW5kPXRbJ3RleHRvMiddKQogICAgICAgICAgICBzZWxmLmVu
:::dF9jYXJwZXRhLmNvbmZpZ3VyZSgKICAgICAgICAgICAgICAgIGJnPXRbJ2NhbXBv
:::J10sIGZnPXRbJ3RleHRvJ10sIGluc2VydGJhY2tncm91bmQ9dFsndGV4dG8nXSwK
:::ICAgICAgICAgICAgICAgIGhpZ2hsaWdodGJhY2tncm91bmQ9dFsnY2FtcG9fYm9y
:::ZGUnXSwKICAgICAgICAgICAgICAgIGhpZ2hsaWdodGNvbG9yPXRbJ2FjZW50bydd
:::KQogICAgICAgICAgICBzZWxmLmNoa19lbWJlYmVyLmNvbmZpZ3VyZSgKICAgICAg
:::ICAgICAgICAgIGJnPXRbJ2ZvbmRvJ10sIGZnPXRbJ3RleHRvJ10sIGFjdGl2ZWJh
:::Y2tncm91bmQ9dFsnZm9uZG8nXSwKICAgICAgICAgICAgICAgIGFjdGl2ZWZvcmVn
:::cm91bmQ9dFsndGV4dG8nXSwgc2VsZWN0Y29sb3I9dFsnY2FtcG8nXSkKICAgICAg
:::ICAgICAgZm9yIGIgaW4gc2VsZi5fYnRuczoKICAgICAgICAgICAgICAgIGIuY29u
:::ZmlndXJlKGJnPXRbJ2JvdG9uJ10sIGZnPXRbJ2JvdG9uX3R4dCddLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgYWN0aXZlYmFja2dyb3VuZD10Wydib3Rvbl9h
:::Y3QnXSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGFjdGl2ZWZvcmVncm91
:::bmQ9dFsnYm90b25fdHh0J10pCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5jb25m
:::aWd1cmUoYmc9dFsnbG9nJ10sIGZnPXRbJ2xvZ190eHQnXSwKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICBpbnNlcnRiYWNrZ3JvdW5kPXRbJ2xvZ190
:::eHQnXSkKICAgICAgICAgICAgc2VsZi50eHRfbG9nLnRhZ19jb25maWd1cmUoJ2lu
:::Zm8nLCBmb3JlZ3JvdW5kPXRbJ2xvZ190eHQnXSkKICAgICAgICAgICAgc2VsZi50
:::eHRfbG9nLnRhZ19jb25maWd1cmUoJ2dyaXMnLCBmb3JlZ3JvdW5kPXRbJ3RleHRv
:::MiddKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cudGFnX2NvbmZpZ3VyZSgndGl0
:::dWxvJywgZm9yZWdyb3VuZD10Wyd0ZXh0byddLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICBmb250PSgnQ29uc29sYXMnLCAxMCwgJ2JvbGQn
:::KSkKICAgICAgICAgICAgc2VsZi50eHRfbG9nLnRhZ19jb25maWd1cmUoJ29rJywg
:::Zm9yZWdyb3VuZD10WydvayddKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cudGFn
:::X2NvbmZpZ3VyZSgnYXZpc28nLCBmb3JlZ3JvdW5kPXRbJ2F2aXNvJ10pCiAgICAg
:::ICAgICAgIHNlbGYudHh0X2xvZy50YWdfY29uZmlndXJlKCdlcnJvcicsIGZvcmVn
:::cm91bmQ9dFsnZXJyb3InXSkKICAgICAgICAgICAgZXN0ID0gc2VsZi5fZXN0aWxv
:::CiAgICAgICAgICAgIGVzdC5jb25maWd1cmUoJ2d4LlRDb21ib2JveCcsCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgZmllbGRiYWNrZ3JvdW5kPXRbJ2NhbXBvJ10s
:::IGJhY2tncm91bmQ9dFsnYm90b24nXSwKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICBmb3JlZ3JvdW5kPXRbJ3RleHRvJ10sIGFycm93Y29sb3I9dFsndGV4dG8nXSwK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBib3JkZXJjb2xvcj10WydjYW1wb19i
:::b3JkZSddLAogICAgICAgICAgICAgICAgICAgICAgICAgIGxpZ2h0Y29sb3I9dFsn
:::Y2FtcG9fYm9yZGUnXSwKICAgICAgICAgICAgICAgICAgICAgICAgICBkYXJrY29s
:::b3I9dFsnY2FtcG9fYm9yZGUnXSwKICAgICAgICAgICAgICAgICAgICAgICAgICBp
:::bnNlcnRjb2xvcj10Wyd0ZXh0byddKQogICAgICAgICAgICBlc3QubWFwKCdneC5U
:::Q29tYm9ib3gnLAogICAgICAgICAgICAgICAgICAgIGZpZWxkYmFja2dyb3VuZD1b
:::KCdyZWFkb25seScsIHRbJ2NhbXBvJ10pXSwKICAgICAgICAgICAgICAgICAgICBm
:::b3JlZ3JvdW5kPVsoJ3JlYWRvbmx5JywgdFsndGV4dG8nXSldKQogICAgICAgICAg
:::ICBlc3QuY29uZmlndXJlKCdneC5Ib3Jpem9udGFsLlRQcm9ncmVzc2JhcicsCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgdHJvdWdoY29sb3I9dFsndHJvdWdoJ10s
:::IGJhY2tncm91bmQ9dFsnYWNlbnRvJ10sCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgYm9yZGVyY29sb3I9dFsnZm9uZG8nXSwgbGlnaHRjb2xvcj10WydhY2VudG8n
:::XSwKICAgICAgICAgICAgICAgICAgICAgICAgICBkYXJrY29sb3I9dFsnYWNlbnRv
:::J10pCiAgICAgICAgICAgIHNlbGYub3B0aW9uX2FkZCgnKlRDb21ib2JveCpMaXN0
:::Ym94LmJhY2tncm91bmQnLCB0WydjYW1wbyddKQogICAgICAgICAgICBzZWxmLm9w
:::dGlvbl9hZGQoJypUQ29tYm9ib3gqTGlzdGJveC5mb3JlZ3JvdW5kJywgdFsndGV4
:::dG8nXSkKICAgICAgICAgICAgc2VsZi5vcHRpb25fYWRkKCcqVENvbWJvYm94Kkxp
:::c3Rib3guc2VsZWN0QmFja2dyb3VuZCcsCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICB0Wydib3Rvbl9hY3QnXSkKICAgICAgICAgICAgc2VsZi5vcHRpb25fYWRk
:::KCcqVENvbWJvYm94Kkxpc3Rib3guc2VsZWN0Rm9yZWdyb3VuZCcsCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICB0Wydib3Rvbl90eHQnXSkKICAgICAgICAgICAg
:::c2VsZi5fcmVmcmVzY2FyX3BsYWNlaG9sZGVyKCkKCiAgICAgICAgZGVmIF9yZWZy
:::ZXNjYXJfcGxhY2Vob2xkZXIoc2VsZik6CiAgICAgICAgICAgIHQgPSBURU1BU1tz
:::ZWxmLl90ZW1hX2FjdHVhbF0KICAgICAgICAgICAgaWYgc2VsZi5fZW5fcGxhY2Vo
:::b2xkZXI6CiAgICAgICAgICAgICAgICBzZWxmLmVudF91cmwuY29uZmlndXJlKGZn
:::PXRbJ3BsYWNlaG9sZGVyJ10pCiAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAg
:::ICAgICBzZWxmLmVudF91cmwuY29uZmlndXJlKGZnPXRbJ3RleHRvJ10pCgogICAg
:::ICAgICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tIGV2ZW50b3MKICAgICAgICBkZWYgX2NvbmVjdGFyX2V2ZW50b3Moc2Vs
:::Zik6CiAgICAgICAgICAgIHNlbGYuY21iX3RlbWEuYmluZCgnPDxDb21ib2JveFNl
:::bGVjdGVkPj4nLCBzZWxmLl9vbl90ZW1hKQogICAgICAgICAgICBzZWxmLmNtYl9m
:::b3JtYXRvLmJpbmQoJzw8Q29tYm9ib3hTZWxlY3RlZD4+Jywgc2VsZi5fb25fZm9y
:::bWF0bykKICAgICAgICAgICAgc2VsZi5jbWJfY2FsaWRhZC5iaW5kKCc8PENvbWJv
:::Ym94U2VsZWN0ZWQ+PicsIGxhbWJkYSBlOiBzZWxmLl9ndWFyZGFyKCkpCiAgICAg
:::ICAgICAgIHNlbGYuY2hrX2VtYmViZXIuY29uZmlndXJlKGNvbW1hbmQ9c2VsZi5f
:::Z3VhcmRhcikKICAgICAgICAgICAgc2VsZi5lbnRfdXJsLmJpbmQoJzxGb2N1c0lu
:::PicsIHNlbGYuX29uX2ZvY3VzX3VybF9pbikKICAgICAgICAgICAgc2VsZi5lbnRf
:::dXJsLmJpbmQoJzxGb2N1c091dD4nLCBzZWxmLl9vbl9mb2N1c191cmxfb3V0KQog
:::ICAgICAgICAgICBzZWxmLmVudF91cmwuYmluZCgnPFJldHVybj4nLCBsYW1iZGEg
:::ZTogc2VsZi5fYWNjaW9uX2Rlc2NhcmdhcigpKQogICAgICAgICAgICBzZWxmLmVu
:::dF9jYXJwZXRhLmJpbmQoJzxGb2N1c091dD4nLCBzZWxmLl9vbl9jYXJwZXRhX2Vz
:::Y3JpdGEpCiAgICAgICAgICAgIHNlbGYucHJvdG9jb2woJ1dNX0RFTEVURV9XSU5E
:::T1cnLCBzZWxmLl9hbF9jZXJyYXIpCiAgICAgICAgICAgIHNlbGYuYmluZCgnPENv
:::bnRyb2wtdT4nLCBsYW1iZGEgZTogc2VsZi5fYWNjaW9uX2FjdHVhbGl6YXIoKSkK
:::ICAgICAgICAgICAgc2VsZi5iaW5kKCc8Q29udHJvbC1sPicsIGxhbWJkYSBlOiBz
:::ZWxmLl9saW1waWFyX2xvZygpKQogICAgICAgICAgICBzZWxmLmJpbmQoJzxDb250
:::cm9sLVU+JywgbGFtYmRhIGU6IHNlbGYuX2FjY2lvbl9hY3R1YWxpemFyKCkpCgog
:::ICAgICAgIGRlZiBfb25fZm9jdXNfdXJsX2luKHNlbGYsIF9lPU5vbmUpOgogICAg
:::ICAgICAgICBpZiBzZWxmLl9lbl9wbGFjZWhvbGRlcjoKICAgICAgICAgICAgICAg
:::IHNlbGYuZW50X3VybC5kZWxldGUoMCwgJ2VuZCcpCiAgICAgICAgICAgICAgICBz
:::ZWxmLl9lbl9wbGFjZWhvbGRlciA9IEZhbHNlCiAgICAgICAgICAgICAgICBzZWxm
:::Ll9yZWZyZXNjYXJfcGxhY2Vob2xkZXIoKQoKICAgICAgICBkZWYgX29uX2ZvY3Vz
:::X3VybF9vdXQoc2VsZiwgX2U9Tm9uZSk6CiAgICAgICAgICAgIGlmIG5vdCBzZWxm
:::LmVudF91cmwuZ2V0KCk6CiAgICAgICAgICAgICAgICBzZWxmLl9lbl9wbGFjZWhv
:::bGRlciA9IFRydWUKICAgICAgICAgICAgICAgIHNlbGYuX3BvbmVyX3BsYWNlaG9s
:::ZGVyKCkKICAgICAgICAgICAgICAgIHNlbGYuX3JlZnJlc2Nhcl9wbGFjZWhvbGRl
:::cigpCgogICAgICAgIGRlZiBfb25fdGVtYShzZWxmLCBfZT1Ob25lKToKICAgICAg
:::ICAgICAgc2VsZi5fdGVtYV9hY3R1YWwgPSBzZWxmLmNtYl90ZW1hLmdldCgpCiAg
:::ICAgICAgICAgIEFKVVNURVNbJ3RlbWEnXSA9IHNlbGYuX3RlbWFfYWN0dWFsCiAg
:::ICAgICAgICAgIGd1YXJkYXJfYWp1c3RlcygpCiAgICAgICAgICAgIHNlbGYuX2Fw
:::bGljYXJfdGVtYSgpCgogICAgICAgIGRlZiBfb25fZm9ybWF0byhzZWxmLCBfZT1O
:::b25lKToKICAgICAgICAgICAgZm10ID0gc2VsZi5fZm10X2FjdHVhbCgpCiAgICAg
:::ICAgICAgIHNlbGYuX3JlY2FyZ2FyX2NhbGlkYWRlcyhmbXQpCiAgICAgICAgICAg
:::IHNlbGYuX2d1YXJkYXIoKQogICAgICAgICAgICBzZWxmLmxibF9lc3RpbWFjaW9u
:::LmNvbmZpZ3VyZSgKICAgICAgICAgICAgICAgIHRleHQ9J0ludHJvZHVjZSB1bmEg
:::VVJMIHkgcHVsc2EgRXN0aW1hci4nLAogICAgICAgICAgICAgICAgZmc9VEVNQVNb
:::c2VsZi5fdGVtYV9hY3R1YWxdWyd0ZXh0byddKQoKICAgICAgICBkZWYgX2ZtdF9h
:::Y3R1YWwoc2VsZik6CiAgICAgICAgICAgIHRleHRvID0gc2VsZi5jbWJfZm9ybWF0
:::by5nZXQoKQogICAgICAgICAgICBmb3IgY2xhdmUsIGYgaW4gRk9STUFUT1MuaXRl
:::bXMoKToKICAgICAgICAgICAgICAgIGlmIGZbJ3RleHRvJ10gPT0gdGV4dG86CiAg
:::ICAgICAgICAgICAgICAgICAgcmV0dXJuIGNsYXZlCiAgICAgICAgICAgIHJldHVy
:::biAnQUFDJwoKICAgICAgICBkZWYgX3JlY2FyZ2FyX2NhbGlkYWRlcyhzZWxmLCBj
:::bGF2ZV9mbXQsIGNhbGlkYWRfcHJldmlhPU5vbmUpOgogICAgICAgICAgICBmID0g
:::Rk9STUFUT1NbY2xhdmVfZm10XQogICAgICAgICAgICBzZWxmLmNtYl9jYWxpZGFk
:::Wyd2YWx1ZXMnXSA9IGZbJ2NhbGlkYWRlcyddCiAgICAgICAgICAgIGlmIGNhbGlk
:::YWRfcHJldmlhIGFuZCBjYWxpZGFkX3ByZXZpYSBpbiBmWydjYWxpZGFkZXMnXToK
:::ICAgICAgICAgICAgICAgIHNlbGYuY21iX2NhbGlkYWQuc2V0KGNhbGlkYWRfcHJl
:::dmlhKQogICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgc2VsZi5jbWJf
:::Y2FsaWRhZC5zZXQoZlsnZGVmZWN0byddKQogICAgICAgICAgICBBSlVTVEVTWydm
:::b3JtYXRvJ10gPSBjbGF2ZV9mbXQKICAgICAgICAgICAgQUpVU1RFU1snY2FsaWRh
:::ZCddID0gc2VsZi5jbWJfY2FsaWRhZC5nZXQoKQoKICAgICAgICBkZWYgX2d1YXJk
:::YXIoc2VsZik6CiAgICAgICAgICAgIEFKVVNURVNbJ2Zvcm1hdG8nXSA9IHNlbGYu
:::X2ZtdF9hY3R1YWwoKQogICAgICAgICAgICBBSlVTVEVTWydjYWxpZGFkJ10gPSBz
:::ZWxmLmNtYl9jYWxpZGFkLmdldCgpCiAgICAgICAgICAgIEFKVVNURVNbJ2VtYmVi
:::ZXInXSA9IGJvb2woc2VsZi52YXJfZW1iZWJlci5nZXQoKSkKICAgICAgICAgICAg
:::QUpVU1RFU1snZGVzdGlubyddID0gc2VsZi5lbnRfY2FycGV0YS5nZXQoKS5zdHJp
:::cCgpCiAgICAgICAgICAgIHZhbCA9IHNlbGYuY21iX2Nvb2tpZXMuZ2V0KCkKICAg
:::ICAgICAgICAgQUpVU1RFU1snY29va2llcyddID0gKCcnIGlmIHZhbC5zdGFydHN3
:::aXRoKCdBdXRvbcOhdGljbycpIGVsc2UKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgIHZhbC5yZXBsYWNlKCdVc2FyIGNvb2tpZXMgZGUgJywgJycpCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAuc3RyaXAoKS5sb3dlcigp
:::KQogICAgICAgICAgICBndWFyZGFyX2FqdXN0ZXMoKQoKICAgICAgICBkZWYgX29u
:::X2NhcnBldGFfZXNjcml0YShzZWxmLCBfZT1Ob25lKToKICAgICAgICAgICAgcCA9
:::IFBhdGgob3MucGF0aC5leHBhbmR2YXJzKAogICAgICAgICAgICAgICAgc2VsZi5l
:::bnRfY2FycGV0YS5nZXQoKS5zdHJpcCgpLnN0cmlwKCciJykpKQogICAgICAgICAg
:::ICB0cnk6CiAgICAgICAgICAgICAgICBwLm1rZGlyKHBhcmVudHM9VHJ1ZSwgZXhp
:::c3Rfb2s9VHJ1ZSkKICAgICAgICAgICAgICAgIEFKVVNURVNbJ2Rlc3Rpbm8nXSA9
:::IHN0cihwKQogICAgICAgICAgICAgICAgZ3VhcmRhcl9hanVzdGVzKCkKICAgICAg
:::ICAgICAgZXhjZXB0IE9TRXJyb3IgYXMgZToKICAgICAgICAgICAgICAgIHNlbGYu
:::X2xvZyhmJ05vIHNlIHB1ZG8gdXNhciBlc2EgY2FycGV0YToge2V9JywgJ2Vycm9y
:::JykKCiAgICAgICAgZGVmIF9jYW1iaWFyX2NhcnBldGEoc2VsZik6CiAgICAgICAg
:::ICAgIGFjdHVhbCA9IHNlbGYuZW50X2NhcnBldGEuZ2V0KCkuc3RyaXAoKSBvciBB
:::SlVTVEVTWydkZXN0aW5vJ10KICAgICAgICAgICAgbnVldmEgPSBmaWxlZGlhbG9n
:::LmFza2RpcmVjdG9yeSgKICAgICAgICAgICAgICAgIHRpdGxlPSdFbGlnZSBsYSBj
:::YXJwZXRhIGRvbmRlIGd1YXJkYXIgbGFzIGRlc2NhcmdhcycsCiAgICAgICAgICAg
:::ICAgICBpbml0aWFsZGlyPWFjdHVhbCBpZiBvcy5wYXRoLmlzZGlyKGFjdHVhbCkg
:::ZWxzZSBzdHIoUGF0aC5ob21lKCkpKQogICAgICAgICAgICBpZiBub3QgbnVldmE6
:::CiAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgdHJ5OgogICAgICAg
:::ICAgICAgICAgUGF0aChudWV2YSkubWtkaXIocGFyZW50cz1UcnVlLCBleGlzdF9v
:::az1UcnVlKQogICAgICAgICAgICBleGNlcHQgT1NFcnJvciBhcyBlOgogICAgICAg
:::ICAgICAgICAgbWVzc2FnZWJveC5zaG93ZXJyb3IoJ0NhcnBldGEgbm8gdsOhbGlk
:::YScsIHN0cihlKSkKICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICBz
:::ZWxmLmVudF9jYXJwZXRhLmRlbGV0ZSgwLCAnZW5kJykKICAgICAgICAgICAgc2Vs
:::Zi5lbnRfY2FycGV0YS5pbnNlcnQoMCwgbnVldmEpCiAgICAgICAgICAgIEFKVVNU
:::RVNbJ2Rlc3Rpbm8nXSA9IG51ZXZhCiAgICAgICAgICAgIGd1YXJkYXJfYWp1c3Rl
:::cygpCiAgICAgICAgICAgIHNlbGYuX2xvZygnQ2FycGV0YSBkZSBndWFyZGFkbzog
:::JyArIG51ZXZhLCAnZ3JpcycpCgogICAgICAgIGRlZiBfYWJyaXJfZGVzdGlubyhz
:::ZWxmKToKICAgICAgICAgICAgcCA9IFBhdGgob3MucGF0aC5leHBhbmR2YXJzKAog
:::ICAgICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5nZXQoKS5zdHJpcCgpLnN0
:::cmlwKCciJykpKQogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBwLm1r
:::ZGlyKHBhcmVudHM9VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgICAgICAgICAgZXhj
:::ZXB0IE9TRXJyb3I6CiAgICAgICAgICAgICAgICBwYXNzCiAgICAgICAgICAgIGFi
:::cmlyX2NhcnBldGEocCkKCiAgICAgICAgZGVmIF9hbF9jZXJyYXIoc2VsZik6CiAg
:::ICAgICAgICAgIGlmIHNlbGYuX29jdXBhZG8gYW5kIG5vdCBtZXNzYWdlYm94LmFz
:::a29rY2FuY2VsKAogICAgICAgICAgICAgICAgICAgICdTYWxpcicsICdIYXkgdW5h
:::IHRhcmVhIGVuIGN1cnNvLiAnCiAgICAgICAgICAgICAgICAgICAgJ8K/U2VndXJv
:::IHF1ZSBxdWllcmVzIHNhbGlyPycpOgogICAgICAgICAgICAgICAgcmV0dXJuCiAg
:::ICAgICAgICAgIHNlbGYuZGVzdHJveSgpCgogICAgICAgICMgLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIHJlZ2lzdHJvIChs
:::b2cpCiAgICAgICAgZGVmIF9sb2coc2VsZiwgbXNnLCB0YWc9J2luZm8nKToKICAg
:::ICAgICAgICAgc2VsZi50eHRfbG9nLmNvbmZpZ3VyZShzdGF0ZT0nbm9ybWFsJykK
:::ICAgICAgICAgICAgbl9saW5lYXMgPSBpbnQoc2VsZi50eHRfbG9nLmluZGV4KCdl
:::bmQtMWMnKS5zcGxpdCgnLicpWzBdKQogICAgICAgICAgICBpZiBuX2xpbmVhcyA+
:::IDkwMDoKICAgICAgICAgICAgICAgIHNlbGYudHh0X2xvZy5kZWxldGUoJzEuMCcs
:::ICcyMDAuMCcpCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5pbnNlcnQoJ2VuZCcs
:::IHN0cihtc2cpICsgJ1xuJywgdGFnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cu
:::c2VlKCdlbmQnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuY29uZmlndXJlKHN0
:::YXRlPSdkaXNhYmxlZCcpCgogICAgICAgIGRlZiBfbGltcGlhcl9sb2coc2VsZik6
:::CiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5jb25maWd1cmUoc3RhdGU9J25vcm1h
:::bCcpCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5kZWxldGUoJzEuMCcsICdlbmQn
:::KQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuY29uZmlndXJlKHN0YXRlPSdkaXNh
:::YmxlZCcpCgogICAgICAgIGRlZiBfYm9tYmVhcl9jb2xhKHNlbGYpOgogICAgICAg
:::ICAgICB0cnk6CiAgICAgICAgICAgICAgICB3aGlsZSBUcnVlOgogICAgICAgICAg
:::ICAgICAgICAgIGV2ID0gc2VsZi5jb2xhLmdldF9ub3dhaXQoKQogICAgICAgICAg
:::ICAgICAgICAgIHRpcG8gPSBldlswXQogICAgICAgICAgICAgICAgICAgIGlmIHRp
:::cG8gPT0gJ2xvZyc6CiAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuX2xvZyhl
:::dlsxXSwgZXZbMl0pCiAgICAgICAgICAgICAgICAgICAgZWxpZiB0aXBvID09ICdw
:::cm9nJzoKICAgICAgICAgICAgICAgICAgICAgICAgcGN0LCB0ZXh0byA9IGV2WzFd
:::LCBldlsyXQogICAgICAgICAgICAgICAgICAgICAgICBpZiBwY3QgaXMgTm9uZToK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYmFycmEuc3RvcCgpCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBzZWxmLmJhcnJhLmNvbmZpZ3VyZSht
:::b2RlPSdpbmRldGVybWluYXRlJykKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::IHNlbGYuYmFycmEuc3RhcnQoNjApCiAgICAgICAgICAgICAgICAgICAgICAgIGVs
:::c2U6CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzZWxmLmJhcnJhLnN0b3Ao
:::KQogICAgICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5iYXJyYS5jb25maWd1
:::cmUobW9kZT0nZGV0ZXJtaW5hdGUnKQogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgc2VsZi5iYXJyYS5jb25maWd1cmUodmFsdWU9bWF4KDAsIG1pbigxMDAsIHBj
:::dCkpKQogICAgICAgICAgICAgICAgICAgICAgICBzZWxmLmxibF9lc3RhZG8uY29u
:::ZmlndXJlKHRleHQ9dGV4dG8pCiAgICAgICAgICAgICAgICAgICAgZWxpZiB0aXBv
:::ID09ICdlc3RpbWFjaW9uJzoKICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5s
:::YmxfZXN0aW1hY2lvbi5jb25maWd1cmUoCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICB0ZXh0PWV2WzFdLCBmZz1URU1BU1tzZWxmLl90ZW1hX2FjdHVhbF1bJ2Fj
:::ZW50byddKQogICAgICAgICAgICAgICAgICAgIGVsaWYgdGlwbyA9PSAnZmluJzoK
:::ICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5fZmluX3RhcmVhKGV2WzFdLCBl
:::dlsyXSwgZXZbM10gaWYgbGVuKGV2KSA+IDMgZWxzZSAnJykKICAgICAgICAgICAg
:::ZXhjZXB0IHF1ZXVlLkVtcHR5OgogICAgICAgICAgICAgICAgcGFzcwogICAgICAg
:::ICAgICBzZWxmLmFmdGVyKDgwLCBzZWxmLl9ib21iZWFyX2NvbGEpCgogICAgICAg
:::ICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tIHRhcmVhcwogICAgICAgIGRlZiBfaGFiaWxpdGFyX2FjY2lvbmVzKHNlbGYs
:::IG9uKToKICAgICAgICAgICAgZXN0YWRvID0gJ25vcm1hbCcgaWYgb24gZWxzZSAn
:::ZGlzYWJsZWQnCiAgICAgICAgICAgIGZvciBiIGluIChzZWxmLmJ0bl9kZXNjYXJn
:::YXIsIHNlbGYuYnRuX2NvbXByb2JhciwKICAgICAgICAgICAgICAgICAgICAgIHNl
:::bGYuYnRuX2VzdGltYXIsIHNlbGYuYnRuX2NhbWJpYXIsIHNlbGYuYnRuX2Ficmly
:::LAogICAgICAgICAgICAgICAgICAgICAgc2VsZi5idG5feCk6CiAgICAgICAgICAg
:::ICAgICBiLmNvbmZpZ3VyZShzdGF0ZT1lc3RhZG8sIGN1cnNvcj0naGFuZDInIGlm
:::IG9uIGVsc2UgJ2Fycm93JykKCiAgICAgICAgZGVmIF9pbmljaWFyKHNlbGYsIG9i
:::amV0aXZvLCBjZmcsIHRleHRvKToKICAgICAgICAgICAgaWYgc2VsZi5fb2N1cGFk
:::bzoKICAgICAgICAgICAgICAgIHNlbGYuX2xvZygnWWEgaGF5IHVuYSB0YXJlYSBl
:::biBjdXJzbzsgZXNwZXJhIGEgcXVlIHRlcm1pbmUuJywKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAnYXZpc28nKQogICAgICAgICAgICAgICAgcmV0dXJuIEZhbHNl
:::CiAgICAgICAgICAgIHNlbGYuX29jdXBhZG8gPSBUcnVlCiAgICAgICAgICAgIHNl
:::bGYuX2hhYmlsaXRhcl9hY2Npb25lcyhGYWxzZSkKICAgICAgICAgICAgc2VsZi5s
:::YmxfZXN0YWRvLmNvbmZpZ3VyZSh0ZXh0PXRleHRvKQogICAgICAgICAgICB0aHJl
:::YWRpbmcuVGhyZWFkKHRhcmdldD1vYmpldGl2bywgYXJncz0oY2ZnLCksIGRhZW1v
:::bj1UcnVlKS5zdGFydCgpCiAgICAgICAgICAgIHJldHVybiBUcnVlCgogICAgICAg
:::IGRlZiBfZmluX3RhcmVhKHNlbGYsIHRpcG8sIG9rLCBtZW5zYWplPScnKToKICAg
:::ICAgICAgICAgc2VsZi5fb2N1cGFkbyA9IEZhbHNlCiAgICAgICAgICAgIHNlbGYu
:::X2hhYmlsaXRhcl9hY2Npb25lcyhUcnVlKQogICAgICAgICAgICBzZWxmLmJhcnJh
:::LnN0b3AoKQogICAgICAgICAgICBzZWxmLmJhcnJhLmNvbmZpZ3VyZShtb2RlPSdk
:::ZXRlcm1pbmF0ZScpCiAgICAgICAgICAgIHNlbGYuYmFycmEuY29uZmlndXJlKHZh
:::bHVlPTApCiAgICAgICAgICAgIGlmIHRpcG8gPT0gJ2Rlc2NhcmdhJyBhbmQgb2s6
:::CiAgICAgICAgICAgICAgICBzZWxmLmxibF9lc3RhZG8uY29uZmlndXJlKHRleHQ9
:::J0xpc3RvLicpCiAgICAgICAgICAgICAgICAjIExhIGRlc2NhcmdhIGZ1ZSBiaWVu
:::OiBzZSBsaW1waWEgbGEgVVJMIHBhcmEgbGEgc2lndWllbnRlLgogICAgICAgICAg
:::ICAgICAgc2VsZi5fcmVzZXRfdXJsKCkKICAgICAgICAgICAgZWxpZiBub3Qgb2s6
:::CiAgICAgICAgICAgICAgICBzZWxmLmxibF9lc3RhZG8uY29uZmlndXJlKHRleHQ9
:::J1Rlcm1pbmFkbyBjb24gZXJyb3Jlcy4nKQogICAgICAgICAgICAgICAgaWYgdGlw
:::byA9PSAnZGVzY2FyZ2EnOgogICAgICAgICAgICAgICAgICAgIG1lc3NhZ2Vib3gu
:::c2hvd2Vycm9yKAogICAgICAgICAgICAgICAgICAgICAgICAnRXJyb3InLCBtZW5z
:::YWplIG9yICdObyBzZSBwdWRvIGNvbXBsZXRhciBsYSB0YXJlYS4gJwogICAgICAg
:::ICAgICAgICAgICAgICAgICAnUmV2aXNhIGVsIHJlZ2lzdHJvIHBhcmEgbcOhcyBk
:::ZXRhbGxlcy4nKQoKICAgICAgICBkZWYgX3VybF92YWxpZGEoc2VsZik6CiAgICAg
:::ICAgICAgIGlmIHNlbGYuX2VuX3BsYWNlaG9sZGVyOgogICAgICAgICAgICAgICAg
:::c2VsZi5fbG9nKCdQcmltZXJvIHBlZ2EgbGEgVVJMIGRlbCB2aWRlbyBkZSBZb3VU
:::dWJlLicsICdhdmlzbycpCiAgICAgICAgICAgICAgICByZXR1cm4gTm9uZQogICAg
:::ICAgICAgICB1ID0gc2VsZi5lbnRfdXJsLmdldCgpLnN0cmlwKCkuc3RyaXAoJyIn
:::KS5zdHJpcCgiJyIpCiAgICAgICAgICAgIGlmIG5vdCB1OgogICAgICAgICAgICAg
:::ICAgc2VsZi5fbG9nKCdMYSBVUkwgZXN0w6EgdmFjw61hLicsICdhdmlzbycpCiAg
:::ICAgICAgICAgICAgICByZXR1cm4gTm9uZQogICAgICAgICAgICBpZiBub3QgcmUu
:::bWF0Y2gocideaHR0cHM/Oi8vJywgdSwgcmUuSSk6CiAgICAgICAgICAgICAgICBp
:::ZiByZS5tYXRjaChyJ153d3dcLicsIHUsIHJlLkkpOgogICAgICAgICAgICAgICAg
:::ICAgIHUgPSAnaHR0cHM6Ly8nICsgdQogICAgICAgICAgICAgICAgZWxzZToKICAg
:::ICAgICAgICAgICAgICAgICBzZWxmLl9sb2coJ0VzbyBubyBwYXJlY2UgdW5hIFVS
:::TCAoZGViZSBlbXBlemFyIHBvciAnCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICdodHRwOi8vIG8gaHR0cHM6Ly8pJywgJ2Vycm9yJykKICAgICAgICAgICAg
:::ICAgICAgICByZXR1cm4gTm9uZQogICAgICAgICAgICAjIE9KTzogYXF1w60gTk8g
:::c2UgcXVpdGEgbGlzdD07IHNpIGxhIFVSTCB0cmFlIHVuYSBwbGF5bGlzdCwKICAg
:::ICAgICAgICAgIyBfYWNjaW9uX2Rlc2NhcmdhciBwcmVndW50YXLDoSBxdcOpIGhh
:::Y2VyIGNvbiBlbGxhLgogICAgICAgICAgICByZXR1cm4gdQoKICAgICAgICBkZWYg
:::X2FjY2lvbl9lc3RpbWFyKHNlbGYpOgogICAgICAgICAgICB1cmwgPSBzZWxmLl91
:::cmxfdmFsaWRhKCkKICAgICAgICAgICAgaWYgbm90IHVybDoKICAgICAgICAgICAg
:::ICAgIHJldHVybgogICAgICAgICAgICBzZWxmLl9ndWFyZGFyKCkKICAgICAgICAg
:::ICAgY2ZnID0geyd1cmwnOiB1cmx9CiAgICAgICAgICAgIHNlbGYuX2luaWNpYXIo
:::c2VsZi5faGlsb19lc3RpbWFyLCBjZmcsICdFc3RpbWFuZG8gdGFtYcOxby4uLicp
:::CiAgICAgICAgICAgIHNlbGYubGJsX2VzdGltYWNpb24uY29uZmlndXJlKAogICAg
:::ICAgICAgICAgICAgdGV4dD0nQ2FsY3VsYW5kby4uLicsIGZnPVRFTUFTW3NlbGYu
:::X3RlbWFfYWN0dWFsXVsndGV4dG8yJ10pCgogICAgICAgIGRlZiBfYWNjaW9uX2Rl
:::c2NhcmdhcihzZWxmKToKICAgICAgICAgICAgdXJsID0gc2VsZi5fdXJsX3ZhbGlk
:::YSgpCiAgICAgICAgICAgIGlmIG5vdCB1cmw6CiAgICAgICAgICAgICAgICByZXR1
:::cm4KICAgICAgICAgICAgc2VsZi5fZ3VhcmRhcigpCiAgICAgICAgICAgIHBsYXls
:::aXN0ID0gRmFsc2UKICAgICAgICAgICAgaWYgZXNfdXJsX3BsYXlsaXN0KHVybCk6
:::CiAgICAgICAgICAgICAgICByID0gbWVzc2FnZWJveC5hc2t5ZXNub2NhbmNlbCgK
:::ICAgICAgICAgICAgICAgICAgICAnTXVzaWtBTEFOIOKAlCBsaXN0YSBkZSByZXBy
:::b2R1Y2Npw7NuJywKICAgICAgICAgICAgICAgICAgICAnRXN0YSBVUkwgcGVydGVu
:::ZWNlIGEgdW5hIGxpc3RhIGRlIHJlcHJvZHVjY2nDs24uXG5cbicKICAgICAgICAg
:::ICAgICAgICAgICAnICBTw40gIOKGkiAgZGVzY2FyZ2FyIGxhIHBsYXlsaXN0IGNv
:::bXBsZXRhXG4nCiAgICAgICAgICAgICAgICAgICAgJyAgICAgICAgIChwYXVzYSBk
:::ZSAyIHMgZW50cmUgY2FuY2lvbmVzKVxuJwogICAgICAgICAgICAgICAgICAgICcg
:::IE5PICDihpIgIGRlc2NhcmdhciBzb2xvIGVzdGEgY2FuY2nDs25cbicKICAgICAg
:::ICAgICAgICAgICAgICAnICBDYW5jZWxhciAg4oaSICBubyBkZXNjYXJnYXIgbmFk
:::YScpCiAgICAgICAgICAgICAgICBpZiByIGlzIE5vbmU6CiAgICAgICAgICAgICAg
:::ICAgICAgc2VsZi5fbG9nKCdEZXNjYXJnYSBjYW5jZWxhZGEuJywgJ2dyaXMnKQog
:::ICAgICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICAgICAgaWYgcjoK
:::ICAgICAgICAgICAgICAgICAgICBwbGF5bGlzdCA9IFRydWUKICAgICAgICAgICAg
:::ICAgIGVsaWYgZXNfc29sb19saXN0YSh1cmwpOgogICAgICAgICAgICAgICAgICAg
:::ICMgRXMgdW5hIHBsYXlsaXN0IHB1cmE6IG5vIGhheSAidW5hIGNhbmNpw7NuIiBh
:::aMOtCiAgICAgICAgICAgICAgICAgICAgc2VsZi5fbG9nKCdFc2EgVVJMIGVzIHVu
:::YSBsaXN0YSBjb21wbGV0YTsgc2UgZGVzY2FyZ2Fyw6EgJwogICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAnZW50ZXJhLicsICdhdmlzbycpCiAgICAgICAgICAg
:::ICAgICAgICAgcGxheWxpc3QgPSBUcnVlCiAgICAgICAgICAgIGNmZyA9IHsndXJs
:::JzogdXJsLCAncGxheWxpc3QnOiBwbGF5bGlzdH0KICAgICAgICAgICAgc2VsZi5f
:::aW5pY2lhcihzZWxmLl9oaWxvX2Rlc2NhcmdhciwgY2ZnLCAnRGVzY2FyZ2FuZG8u
:::Li4nKQoKICAgICAgICBkZWYgX2FjY2lvbl9jb21wcm9iYXIoc2VsZik6CiAgICAg
:::ICAgICAgIHNlbGYuX2d1YXJkYXIoKQogICAgICAgICAgICBzZWxmLl9pbmljaWFy
:::KHNlbGYuX2hpbG9fY29tcHJvYmFyLCB7fSwKICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAnQ29tcHJvYmFuZG8gbGEgY2FycGV0YS4uLicpCgogICAgICAgIGRlZiBf
:::YWNjaW9uX2FjdHVhbGl6YXIoc2VsZik6CiAgICAgICAgICAgIGlmIG5vdCBZVF9E
:::TFA6CiAgICAgICAgICAgICAgICBzZWxmLl9sb2coJ3l0LWRscCBubyBlc3TDoSBp
:::bnN0YWxhZG87IGVqZWN1dGEgJwogICAgICAgICAgICAgICAgICAgICAgICAgICdE
:::ZXNjYXJnYWRvck11c2ljYS5iYXQuJywgJ2Vycm9yJykKICAgICAgICAgICAgICAg
:::IHJldHVybgogICAgICAgICAgICBzZWxmLl9pbmljaWFyKHNlbGYuX2hpbG9fYWN0
:::dWFsaXphciwge30sICdBY3R1YWxpemFuZG8geXQtZGxwLi4uJykKCiAgICAgICAg
:::IyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0gaGlsb3MKICAgICAgICBkZWYgX2hpbG9fZXN0aW1hcihzZWxmLCBjZmcpOgog
:::ICAgICAgICAgICBjb2xhID0gc2VsZi5jb2xhCgogICAgICAgICAgICBkZWYgbG9n
:::KG0sIHQ9J2luZm8nKToKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnbG9nJywg
:::bSwgdCkpCgogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBpZiBZVF9E
:::TFAgaXMgTm9uZToKICAgICAgICAgICAgICAgICAgICBsb2coJ3l0LWRscCBubyBl
:::c3TDoSBpbnN0YWxhZG8uIEVqZWN1dGEgJwogICAgICAgICAgICAgICAgICAgICAg
:::ICAnRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0IHBhcmEgaW5zdGFsYXJsby4nLCAnZXJy
:::b3InKQogICAgICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZXN0aW1hY2lvbics
:::ICd5dC1kbHAgbm8gZGlzcG9uaWJsZScpKQogICAgICAgICAgICAgICAgICAgIHJl
:::dHVybgogICAgICAgICAgICAgICAgbG9nKCdPYnRlbmllbmRvIGluZm9ybWFjacOz
:::biBkZWwgdmlkZW8uLi4nLCAnZ3JpcycpCiAgICAgICAgICAgICAgICBvID0geydx
:::dWlldCc6IFRydWUsICdub193YXJuaW5ncyc6IFRydWUsICdub3BsYXlsaXN0Jzog
:::VHJ1ZSwKICAgICAgICAgICAgICAgICAgICAgJ3NvY2tldF90aW1lb3V0JzogMzAs
:::ICdsb2dnZXInOiBSRUdJU1RST30KICAgICAgICAgICAgICAgIF9hbnRpX2JvdChv
:::KQogICAgICAgICAgICAgICAgaWYgZXNfdXJsX3BsYXlsaXN0KGNmZ1sndXJsJ10p
:::OgogICAgICAgICAgICAgICAgICAgIGxvZygnKGxhIFVSTCBjb250aWVuZSB1bmEg
:::cGxheWxpc3Q6IGxhIGVzdGltYWNpw7NuIGVzICcKICAgICAgICAgICAgICAgICAg
:::ICAgICAgJ3NvbG8gZGVsIHZpZGVvIHBlZ2FkbyknLCAnZ3JpcycpCiAgICAgICAg
:::ICAgICAgICB3aXRoIFlUX0RMUC5Zb3V0dWJlREwobykgYXMgeWRsOgogICAgICAg
:::ICAgICAgICAgICAgIGluZm8gPSB5ZGwuZXh0cmFjdF9pbmZvKGNmZ1sndXJsJ10s
:::IGRvd25sb2FkPUZhbHNlKQogICAgICAgICAgICAgICAgZHVyID0gaW5mby5nZXQo
:::J2R1cmF0aW9uJykKICAgICAgICAgICAgICAgIGlmIG5vdCBkdXI6CiAgICAgICAg
:::ICAgICAgICAgICAgbG9nKCdObyBzZSBwdWRvIG9idGVuZXIgbGEgZHVyYWNpw7Nu
:::IGRlbCB2aWRlby4nLCAnZXJyb3InKQogICAgICAgICAgICAgICAgICAgIGNvbGEu
:::cHV0KCgnZXN0aW1hY2lvbicsICdTaW4gZGF0b3MgcGFyYSBlc3RpbWFyJykpCiAg
:::ICAgICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgICAgICBjbGF2ZSA9
:::IHNlbGYuX2ZtdF9hY3R1YWxfc29sbyhBSlVTVEVTLmdldCgnZm9ybWF0bycsICdB
:::QUMnKSkKICAgICAgICAgICAgICAgIHRhbSA9IGVzdGltYXJfYnl0ZXMoZHVyLCBj
:::bGF2ZSwgQUpVU1RFUy5nZXQoJ2NhbGlkYWQnKSwKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgYm9vbChBSlVTVEVTLmdldCgnZW1iZWJlcicsIFRy
:::dWUpKSkKICAgICAgICAgICAgICAgIHRpdHVsbyA9IHN0cihpbmZvLmdldCgndGl0
:::bGUnKSBvciAnJylbOjcwXQogICAgICAgICAgICAgICAgaWYgdGl0dWxvOgogICAg
:::ICAgICAgICAgICAgICAgIGxvZygn4pmqICcgKyB0aXR1bG8sICd0aXR1bG8nKQog
:::ICAgICAgICAgICAgICAgdGV4dG8gPSAoZid+e3RhbSAvIDEwNDg1NzY6LjFmfSBN
:::QiDCtyAnCiAgICAgICAgICAgICAgICAgICAgICAgICBmJ2R1cmFjacOzbiB7Zm10
:::X3RpZW0oZHVyKX0gwrcgJwogICAgICAgICAgICAgICAgICAgICAgICAgZid7Y2xh
:::dmV9IHtBSlVTVEVTLmdldCgiY2FsaWRhZCIsICIiKX0nLnJzdHJpcCgpKQogICAg
:::ICAgICAgICAgICAgY29sYS5wdXQoKCdlc3RpbWFjaW9uJywgdGV4dG8pKQogICAg
:::ICAgICAgICAgICAgbG9nKCdFc3RpbWFjacOzbjogJyArIHRleHRvLCAnb2snKQog
:::ICAgICAgICAgICAgICAgbG9nKCdFbCB0YW1hw7FvIHJlYWwgcHVlZGUgdmFyaWFy
:::IGFsZ28gc2Vnw7puIGxhIGZ1ZW50ZS4nLAogICAgICAgICAgICAgICAgICAgICdn
:::cmlzJykKICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBlOgogICAgICAg
:::ICAgICAgICAgbG9nKGYnTm8gc2UgcHVkbyBlc3RpbWFyOiB7c2VsZi5fbXNnX2Vy
:::cm9yKGUpfScsICdlcnJvcicpCiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2Vz
:::dGltYWNpb24nLCAnTm8gc2UgcHVkbyBlc3RpbWFyJykpCiAgICAgICAgICAgIGZp
:::bmFsbHk6CiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdlc3RpbWFj
:::aW9uJywgVHJ1ZSwgJycpKQoKICAgICAgICBkZWYgX2ZtdF9hY3R1YWxfc29sbyhz
:::ZWxmLCBjbGF2ZSk6CiAgICAgICAgICAgIHJldHVybiBjbGF2ZSBpZiBjbGF2ZSBp
:::biBGT1JNQVRPUyBlbHNlICdBQUMnCgogICAgICAgIGRlZiBfZGVzY2FyZ2FyX3Vu
:::YShzZWxmLCB1cmwsIGNsYXZlLCBjYWxpZGFkX2FyZywgZW1iZWJlciwgZGVzdGlu
:::bywKICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sYSk6CiAgICAgICAgICAg
:::ICIiIkRlc2NhcmdhIHkgY29udmllcnRlIFVOQSBVUkwuIERldnVlbHZlIGVsIFBh
:::dGggZmluYWwgbyBOb25lLiIiIgogICAgICAgICAgICBpZiBjbGF2ZSA9PSAnV01B
:::JzoKICAgICAgICAgICAgICAgIHJldHVybiBkZXNjYXJnYXJfd21hKHVybCwgY2Fs
:::aWRhZF9hcmcsIGRlc3Rpbm8sIGVtYmViZXIsCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICBjb2xhKVsxXQogICAgICAgICAgICBpZiBjbGF2ZSA9
:::PSAnQVZJJzoKICAgICAgICAgICAgICAgIHJldHVybiBkZXNjYXJnYXJfYXZpKHVy
:::bCwgZGVzdGlubywgY29sYSlbMV0KICAgICAgICAgICAgcmV0dXJuIGRlc2Nhcmdh
:::cl9hdWRpbyh1cmwsIGNsYXZlLCBjYWxpZGFkX2FyZywgZGVzdGlubywgZW1iZWJl
:::ciwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xhKVsxXQoK
:::ICAgICAgICBkZWYgX2Rlc2Nhcmdhcl9wbGF5bGlzdChzZWxmLCB1cmwsIGNsYXZl
:::LCBjYWxpZGFkX2FyZywgZW1iZWJlciwKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICBkZXN0aW5vLCBjb2xhKToKICAgICAgICAgICAgIiIiQmFqYSB1bmEg
:::bGlzdGEgZW50ZXJhLCBjb24gMiBzIGRlIGRlc2NhbnNvIGVudHJlIGNhbmNpb25l
:::cwogICAgICAgICAgICBwYXJhIG5vIHNhdHVyYXIgYSBZb3VUdWJlLiBEZXZ1ZWx2
:::ZSAoZGVzY2FyZ2FkYXMsIHRvdGFsKS4iIiIKICAgICAgICAgICAgZGVmIGxvZyht
:::LCB0PSdpbmZvJyk6CiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0s
:::IHQpKQoKICAgICAgICAgICAgbG9nKCdMZXllbmRvIGxhIGxpc3RhIGRlIHJlcHJv
:::ZHVjY2nDs24uLi4nLCAnZ3JpcycpCiAgICAgICAgICAgIG8gPSB7J3F1aWV0Jzog
:::VHJ1ZSwgJ25vX3dhcm5pbmdzJzogVHJ1ZSwKICAgICAgICAgICAgICAgICAnZXh0
:::cmFjdF9mbGF0JzogJ2luX3BsYXlsaXN0JywgJ3NvY2tldF90aW1lb3V0JzogMzAs
:::CiAgICAgICAgICAgICAgICAgJ2xvZ2dlcic6IFJFR0lTVFJPfQogICAgICAgICAg
:::ICBfYW50aV9ib3QobykKICAgICAgICAgICAgd2l0aCBZVF9ETFAuWW91dHViZURM
:::KG8pIGFzIHlkbDoKICAgICAgICAgICAgICAgIGluZm8gPSB5ZGwuZXh0cmFjdF9p
:::bmZvKHVybCwgZG93bmxvYWQ9RmFsc2UpCiAgICAgICAgICAgIGVudHJhZGFzID0g
:::bGlzdChpbmZvLmdldCgnZW50cmllcycpIG9yIFtdKQogICAgICAgICAgICBpZiBu
:::b3QgZW50cmFkYXM6CiAgICAgICAgICAgICAgICBsb2coJ05vIHNlIHZpbyBuaW5n
:::dW5hIGNhbmNpw7NuIGVuIGxhIGxpc3RhOyBzZSBpbnRlbnRhICcKICAgICAgICAg
:::ICAgICAgICAgICAnY29tbyB2aWRlbyBzdWVsdG8uJywgJ2F2aXNvJykKICAgICAg
:::ICAgICAgICAgIGFyY2hpdm8gPSBzZWxmLl9kZXNjYXJnYXJfdW5hKHNpbl9wbGF5
:::bGlzdCh1cmwpWzBdLCBjbGF2ZSwKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgIGNhbGlkYWRfYXJnLCBlbWJlYmVyLCBkZXN0aW5v
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::Y29sYSkKICAgICAgICAgICAgICAgIHJldHVybiAoMSBpZiBhcmNoaXZvIGVsc2Ug
:::MCksIDEKICAgICAgICAgICAgdGl0dWxvX3BsID0gc3RyKGluZm8uZ2V0KCd0aXRs
:::ZScpIG9yICdsaXN0YScpWzo3MF0KICAgICAgICAgICAgdG90YWwgPSBsZW4oZW50
:::cmFkYXMpCiAgICAgICAgICAgIGxvZyhmJ1BsYXlsaXN0IMKre3RpdHVsb19wbH3C
:::uyDigJQge3RvdGFsfSB2w61kZW8ocykuJywgJ3RpdHVsbycpCiAgICAgICAgICAg
:::IG9rYXMgPSAwCiAgICAgICAgICAgIGZhbGxvcyA9IFtdCiAgICAgICAgICAgIGZv
:::ciBpLCBlIGluIGVudW1lcmF0ZShlbnRyYWRhcyk6CiAgICAgICAgICAgICAgICB1
:::ID0gc3RyKGUuZ2V0KCd3ZWJwYWdlX3VybCcpIG9yIGUuZ2V0KCd1cmwnKSBvciAn
:::JykKICAgICAgICAgICAgICAgIGlmIHUgYW5kIG5vdCB1LnN0YXJ0c3dpdGgoJ2h0
:::dHAnKToKICAgICAgICAgICAgICAgICAgICB1ID0gJ2h0dHBzOi8vd3d3LnlvdXR1
:::YmUuY29tL3dhdGNoP3Y9JyArIHUKICAgICAgICAgICAgICAgIGlmIG5vdCB1IGFu
:::ZCBlLmdldCgnaWQnKToKICAgICAgICAgICAgICAgICAgICB1ID0gJ2h0dHBzOi8v
:::d3d3LnlvdXR1YmUuY29tL3dhdGNoP3Y9JyArIHN0cihlWydpZCddKQogICAgICAg
:::ICAgICAgICAgdGl0ID0gc3RyKGUuZ2V0KCd0aXRsZScpIG9yIHUgb3IgJz8nKVs6
:::NzBdCiAgICAgICAgICAgICAgICBpZiBpOgogICAgICAgICAgICAgICAgICAgIHRp
:::bWUuc2xlZXAoMikgICAjIGRlc2NhbnNvIGVudHJlIGNhbmNpb25lcwogICAgICAg
:::ICAgICAgICAgbG9nKGYnW3tpICsgMX0ve3RvdGFsfV0g4pmqIHt0aXR9JywgJ3Rp
:::dHVsbycpCiAgICAgICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICAgICAg
:::YXJjaGl2byA9IHNlbGYuX2Rlc2Nhcmdhcl91bmEodSwgY2xhdmUsIGNhbGlkYWRf
:::YXJnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgIGVtYmViZXIsIGRlc3Rpbm8sIGNvbGEpCiAgICAgICAgICAgICAgICBl
:::eGNlcHQgRXhjZXB0aW9uIGFzIGUyOgogICAgICAgICAgICAgICAgICAgIGlmIF9l
:::c19ibG9xdWVvX2JvdChzdHIoZTIpKToKICAgICAgICAgICAgICAgICAgICAgICAg
:::IyBibG9xdWVvIGFudGktYm90OiBhYm9ydGFyIHBhcmEgcXVlIGVsIHJlaW50ZW50
:::bwogICAgICAgICAgICAgICAgICAgICAgICAjIGF1dG9tw6F0aWNvIGRlIF9oaWxv
:::X2Rlc2NhcmdhciBzZSBlbmNhcmd1ZQogICAgICAgICAgICAgICAgICAgICAgICBy
:::YWlzZQogICAgICAgICAgICAgICAgICAgIGFyY2hpdm8gPSBOb25lCiAgICAgICAg
:::ICAgICAgICAgICAgbG9nKGYn4pyWIFt7aSArIDF9L3t0b3RhbH1dIEZhbGzDszog
:::e3NlbGYuX21zZ19lcnJvcihlMil9JywKICAgICAgICAgICAgICAgICAgICAgICAg
:::J2Vycm9yJykKICAgICAgICAgICAgICAgIGlmIGFyY2hpdm8gYW5kIFBhdGgoYXJj
:::aGl2bykuZXhpc3RzKCk6CiAgICAgICAgICAgICAgICAgICAgdHJ5OgogICAgICAg
:::ICAgICAgICAgICAgICAgICB0YW0gPSBmbXRfdGFtKFBhdGgoYXJjaGl2bykuc3Rh
:::dCgpLnN0X3NpemUpCiAgICAgICAgICAgICAgICAgICAgZXhjZXB0IE9TRXJyb3I6
:::CiAgICAgICAgICAgICAgICAgICAgICAgIHRhbSA9ICc/JwogICAgICAgICAgICAg
:::ICAgICAgIGxvZyhmJyAgIOKclCB7UGF0aChhcmNoaXZvKS5uYW1lfSAgKHt0YW19
:::KScsICdvaycpCiAgICAgICAgICAgICAgICAgICAgb2thcyArPSAxCiAgICAgICAg
:::ICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgIGZhbGxvcy5hcHBlbmQo
:::dGl0KQogICAgICAgICAgICBsb2coZidQbGF5bGlzdCB0ZXJtaW5hZGE6IHtva2Fz
:::fSBkZSB7dG90YWx9IGRlc2NhcmdhZGEocykuJywKICAgICAgICAgICAgICAgICdv
:::aycgaWYgbm90IGZhbGxvcyBlbHNlICdhdmlzbycpCiAgICAgICAgICAgIGlmIGZh
:::bGxvczoKICAgICAgICAgICAgICAgIGxvZygnU2luIGRlc2NhcmdhcjogJwogICAg
:::ICAgICAgICAgICAgICAgICsgJyDCtyAnLmpvaW4oZls6NDBdIGZvciBmIGluIGZh
:::bGxvc1s6OF0pCiAgICAgICAgICAgICAgICAgICAgKyAoJy4uLicgaWYgbGVuKGZh
:::bGxvcykgPiA4IGVsc2UgJycpLCAnZ3JpcycpCiAgICAgICAgICAgIHJldHVybiBv
:::a2FzLCB0b3RhbAoKICAgICAgICBkZWYgX2hpbG9fZGVzY2FyZ2FyKHNlbGYsIGNm
:::Zyk6CiAgICAgICAgICAgIGNvbGEgPSBzZWxmLmNvbGEKCiAgICAgICAgICAgIGRl
:::ZiBsb2cobSwgdD0naW5mbycpOgogICAgICAgICAgICAgICAgY29sYS5wdXQoKCds
:::b2cnLCBtLCB0KSkKCiAgICAgICAgICAgIHVybCA9IGNmZ1sndXJsJ10KICAgICAg
:::ICAgICAgY2xhdmUgPSBzZWxmLl9mbXRfYWN0dWFsX3NvbG8oQUpVU1RFUy5nZXQo
:::J2Zvcm1hdG8nLCAnQUFDJykpCiAgICAgICAgICAgIGNhbGlkYWQgPSBBSlVTVEVT
:::LmdldCgnY2FsaWRhZCcsICcxMjhrJykKICAgICAgICAgICAgZW1iZWJlciA9IGJv
:::b2woQUpVU1RFUy5nZXQoJ2VtYmViZXInLCBUcnVlKSkKICAgICAgICAgICAgZGVz
:::dGlubyA9IFBhdGgob3MucGF0aC5leHBhbmR2YXJzKAogICAgICAgICAgICAgICAg
:::c3RyKEFKVVNURVMuZ2V0KCdkZXN0aW5vJywgX2Rlc3Rpbm9fcG9yX2RlZmVjdG8o
:::KSkpKSkKICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgaWYgWVRfRExQ
:::IGlzIE5vbmU6CiAgICAgICAgICAgICAgICAgICAgbG9nKCd5dC1kbHAgbm8gZXN0
:::w6EgaW5zdGFsYWRvLiBFamVjdXRhICcKICAgICAgICAgICAgICAgICAgICAgICAg
:::J0Rlc2NhcmdhZG9yTXVzaWNhLmJhdCBwYXJhIGluc3RhbGFybG8uJywgJ2Vycm9y
:::JykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdkZXNjYXJn
:::YScsIEZhbHNlLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAneXQtZGxw
:::IG5vIGVzdMOhIGluc3RhbGFkby4nKSkKICAgICAgICAgICAgICAgICAgICByZXR1
:::cm4KICAgICAgICAgICAgICAgIGRlc3Rpbm8ubWtkaXIocGFyZW50cz1UcnVlLCBl
:::eGlzdF9vaz1UcnVlKQogICAgICAgICAgICAgICAgaWYgY2xhdmUgaW4gKCdGTEFD
:::JywgJ1dBVicpOgogICAgICAgICAgICAgICAgICAgIGNhbGlkYWRfYXJnID0gJzAn
:::CiAgICAgICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgIGNhbGlk
:::YWRfYXJnID0gKHJlLnN1YihyJ1teMC05XScsICcnLCBzdHIoY2FsaWRhZCkpCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb3IgKCcxMjgnIGlmIGNs
:::YXZlID09ICdBQUMnIGVsc2UgJzMyMCcpKQogICAgICAgICAgICAgICAgaWYgY2Zn
:::LmdldCgncGxheWxpc3QnKToKICAgICAgICAgICAgICAgICAgICBva2FzLCB0b3Rh
:::bCA9IHNlbGYuX2Rlc2Nhcmdhcl9wbGF5bGlzdCgKICAgICAgICAgICAgICAgICAg
:::ICAgICAgdXJsLCBjbGF2ZSwgY2FsaWRhZF9hcmcsIGVtYmViZXIsIGRlc3Rpbm8s
:::IGNvbGEpCiAgICAgICAgICAgICAgICAgICAgaWYgb2thcyBhbmQgb2thcyA9PSB0
:::b3RhbDoKICAgICAgICAgICAgICAgICAgICAgICAgbG9nKGYnQ2FycGV0YToge2Rl
:::c3Rpbm99JywgJ2dyaXMnKQogICAgICAgICAgICAgICAgICAgICAgICBjb2xhLnB1
:::dCgoJ2ZpbicsICdkZXNjYXJnYScsIFRydWUsICcnKSkKICAgICAgICAgICAgICAg
:::ICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAnZmluJywgJ2Rlc2NhcmdhJywgRmFs
:::c2UsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBmJ1NlIGRlc2Nhcmdhcm9u
:::IHtva2FzfSBkZSB7dG90YWx9IGRlIGxhICcKICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICdwbGF5bGlzdC4gTGEgVVJMIG5vIHNlIGhhIGJvcnJhZG8gcG9yIHNp
:::ICcKICAgICAgICAgICAgICAgICAgICAgICAgICAgICdxdWllcmVzIHJlaW50ZW50
:::YXJsby4nKSkKICAgICAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAg
:::ICAgIGFyY2hpdm8gPSBzZWxmLl9kZXNjYXJnYXJfdW5hKHNpbl9wbGF5bGlzdCh1
:::cmwpWzBdLCBjbGF2ZSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIGNhbGlkYWRfYXJnLCBlbWJlYmVyLCBkZXN0aW5vLAogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sYSkK
:::ICAgICAgICAgICAgICAgIGlmIGFyY2hpdm8gYW5kIFBhdGgoYXJjaGl2bykuZXhp
:::c3RzKCk6CiAgICAgICAgICAgICAgICAgICAgYXJjaGl2byA9IFBhdGgoYXJjaGl2
:::bykKICAgICAgICAgICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICAgICAg
:::ICAgIHRhbSA9IGZtdF90YW0oYXJjaGl2by5zdGF0KCkuc3Rfc2l6ZSkKICAgICAg
:::ICAgICAgICAgICAgICBleGNlcHQgT1NFcnJvcjoKICAgICAgICAgICAgICAgICAg
:::ICAgICAgdGFtID0gJz8nCiAgICAgICAgICAgICAgICAgICAgbG9nKGYn4pyUIMKh
:::TGlzdG8hICB7YXJjaGl2by5uYW1lfSAgKHt0YW19KScsICdvaycpCiAgICAgICAg
:::ICAgICAgICAgICAgbG9nKGYnQ2FycGV0YToge2FyY2hpdm8ucGFyZW50fScsICdn
:::cmlzJykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdkZXNj
:::YXJnYScsIFRydWUsICcnKSkKICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAg
:::ICAgICAgICAgICAgbG9nKCdFbCBhcmNoaXZvIGZpbmFsIG5vIGFwYXJlY2nDsyBk
:::b25kZSBzZSBlc3BlcmFiYS4nLAogICAgICAgICAgICAgICAgICAgICAgICAnZXJy
:::b3InKQogICAgICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2Rlc2Nh
:::cmdhJywgRmFsc2UsICcnKSkKICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBh
:::cyBlOgogICAgICAgICAgICAgICAgbm9tYnJlX2V4YyA9IHR5cGUoZSkuX19uYW1l
:::X18KICAgICAgICAgICAgICAgIGlmIG5vbWJyZV9leGMgPT0gJ0Rvd25sb2FkRXJy
:::b3InOgogICAgICAgICAgICAgICAgICAgIGxpbmVhcyA9IFtsIGZvciBsIGluIHN0
:::cihlKS5zdHJpcCgpLnNwbGl0bGluZXMoKSBpZiBsLnN0cmlwKCldCiAgICAgICAg
:::ICAgICAgICAgICAgbXNnID0gbGluZWFzWzBdWzozMDBdIGlmIGxpbmVhcyBlbHNl
:::ICdlcnJvciBkZXNjb25vY2lkbycKICAgICAgICAgICAgICAgICAgICBpZiBfZXNf
:::YmxvcXVlb19ib3Qoc3RyKGUpKToKICAgICAgICAgICAgICAgICAgICAgICAgaWYg
:::X0FOVElfQk9UWydjb21ibyddID09IDA6CiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICBsb2coJ1lvdVR1YmUgZXN0w6EgcGlkaWVuZG8gdmVyaWZpY2FjacOzbiAn
:::CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2FudGktYm90IHBhcmEg
:::ZXN0YSByZWQuIFJlaW50ZW50YW5kbyBjb24gJwogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICd1bmEgdsOtYSBpbnRlcm5hIGFsdGVybmF0aXZhLi4uJywg
:::J2F2aXNvJykKICAgICAgICAgICAgICAgICAgICAgICAgICAgIF9BTlRJX0JPVFsn
:::Y29tYm8nXSA9IDEKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRyeToKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aW1lLnNsZWVwKDMpICAgIyBy
:::ZXNwaXJvIHBhcmEgZWwgNDI5CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgc2VsZi5faGlsb19kZXNjYXJnYXIoY2ZnKQogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ZmluYWxseToKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBfQU5USV9C
:::T1RbJ2NvbWJvJ10gPSAwCiAgICAgICAgICAgICAgICAgICAgICAgIGxvZygn4pyW
:::IFlvdVR1YmUgc2lndWUgcGlkaWVuZG8gdmVyaWZpY2FjacOzbjogJwogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgKyBtc2csICdlcnJvcicpCiAgICAgICAgICAg
:::ICAgICAgICAgICAgIGxvZygnU29sdWNpw7NuIGZpYWJsZTogZW4gwqtTaSBZb3VU
:::dWJlIGJsb3F1ZWE6wrsgJwogICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2Vs
:::aWdlIFVzYXIgY29va2llcyBkZSBGaXJlZm94IChvIHR1ICcKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICduYXZlZ2Fkb3IpIHkgcmVpbnRlbnRhOiBjb24gdHUg
:::c2VzacOzbiAnCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnYWJpZXJ0YSBZ
:::b3VUdWJlIG5vIHZ1ZWx2ZSBhIHBlZGlyICcKICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICd2ZXJpZmljYWNpw7NuLicsICdncmlzJykKICAgICAgICAgICAgICAg
:::ICAgICAgICAgbG9nKCdUYW1iacOpbiBzdWVsZW4gZnVuY2lvbmFyOiBlc3BlcmFy
:::IHVub3MgJwogICAgICAgICAgICAgICAgICAgICAgICAgICAgJ21pbnV0b3MsIHB1
:::bHNhciBDdHJsK1UgKGFjdHVhbGl6YXIgeXQtZGxwKSAnCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAnbyBwcm9iYXIgY29uIG90cmEgcmVkIChlbCB3aWZpIGRl
:::IGNhc2EpLicsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZ3JpcycpCiAg
:::ICAgICAgICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgICAgICAgICAg
:::bG9nKCfinJYgTm8gc2UgcHVkbyBkZXNjYXJnYXI6ICcgKyBtc2csICdlcnJvcicp
:::CiAgICAgICAgICAgICAgICAgICAgICAgIGxvZygnQ29uc2Vqb3M6IHJldmlzYSBs
:::YSBVUkwgeSB0dSBjb25leGnDs247IHNpICcKICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICdZb3VUdWJlIGNhbWJpw7MgYWxnbywgcHVsc2EgQ3RybCtVICcKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICcoYWN0dWFsaXphciB5dC1kbHApIHkg
:::cmVpbnRlbnRhLicsICdncmlzJykKICAgICAgICAgICAgICAgIGVsc2U6CiAgICAg
:::ICAgICAgICAgICAgICAgbG9nKGYn4pyWIEVycm9yIGluZXNwZXJhZG8gKHtub21i
:::cmVfZXhjfSk6IHtlfScsICdlcnJvcicpCiAgICAgICAgICAgICAgICAgICAgdGIg
:::PSB0cmFjZWJhY2suZm9ybWF0X2V4YyhsaW1pdD0zKQogICAgICAgICAgICAgICAg
:::ICAgIHRyeToKICAgICAgICAgICAgICAgICAgICAgICAgd2l0aCBvcGVuKExPR19F
:::UlJPUkVTLCAnYScsIGVuY29kaW5nPSd1dGYtOCcpIGFzIGZoOgogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgZmgud3JpdGUodGIgKyAnXG4nKQogICAgICAgICAg
:::ICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgICAgICAgICAg
:::ICAgIHBhc3MKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2Rlc2Nh
:::cmdhJywgRmFsc2UsCiAgICAgICAgICAgICAgICAgICAgICAgICAgJ05vIHNlIHB1
:::ZG8gY29tcGxldGFyIGxhIGRlc2NhcmdhLiBSZXZpc2EgZWwgJwogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICdyZWdpc3RybyBwYXJhIG3DoXMgZGV0YWxsZXMuJykp
:::CgogICAgICAgIGRlZiBfaGlsb19jb21wcm9iYXIoc2VsZiwgY2ZnKToKICAgICAg
:::ICAgICAgY29sYSA9IHNlbGYuY29sYQoKICAgICAgICAgICAgZGVmIGxvZyhtLCB0
:::PSdpbmZvJyk6CiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQp
:::KQoKICAgICAgICAgICAgY2FycGV0YSA9IFBhdGgob3MucGF0aC5leHBhbmR2YXJz
:::KAogICAgICAgICAgICAgICAgc3RyKEFKVVNURVMuZ2V0KCdkZXN0aW5vJywgX2Rl
:::c3Rpbm9fcG9yX2RlZmVjdG8oKSkpKSkKICAgICAgICAgICAgdHJ5OgogICAgICAg
:::ICAgICAgICAgaWYgbm90IGNhcnBldGEuaXNfZGlyKCk6CiAgICAgICAgICAgICAg
:::ICAgICAgbG9nKGYnTGEgY2FycGV0YSB0b2RhdsOtYSBubyBleGlzdGU6IHtjYXJw
:::ZXRhfScsICdhdmlzbycpCiAgICAgICAgICAgICAgICAgICAgY29sYS5wdXQoKCdm
:::aW4nLCAnY29tcHJvYmFjaW9uJywgVHJ1ZSwgJycpKQogICAgICAgICAgICAgICAg
:::ICAgIHJldHVybgogICAgICAgICAgICAgICAgaWYgRkZQUk9CRSBpcyBOb25lOgog
:::ICAgICAgICAgICAgICAgICAgIGxvZygnZmZwcm9iZSBubyBlc3TDoSBkaXNwb25p
:::YmxlICh2aWVuZSBjb24gRkZtcGVnKS4gJwogICAgICAgICAgICAgICAgICAgICAg
:::ICAnRWplY3V0YSBEZXNjYXJnYWRvck11c2ljYS5iYXQgcGFyYSBpbnN0YWxhcmxv
:::LicsCiAgICAgICAgICAgICAgICAgICAgICAgICdlcnJvcicpCiAgICAgICAgICAg
:::ICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnY29tcHJvYmFjaW9uJywgVHJ1ZSwg
:::JycpKQogICAgICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICAgICAg
:::ZXh0cyA9ICgnLm00YScsICcubXAzJywgJy5mbGFjJywgJy53YXYnLCAnLndtYScs
:::ICcuYXZpJykKICAgICAgICAgICAgICAgIGFyY2hpdm9zID0gW3AgZm9yIHAgaW4g
:::c29ydGVkKGNhcnBldGEucmdsb2IoJyonKSkKICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgIGlmIHAuaXNfZmlsZSgpIGFuZCBwLnN1ZmZpeC5sb3dlcigpIGluIGV4
:::dHMKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGFuZCAnX3RtcCcgbm90IGlu
:::IHAucGFydHNdCiAgICAgICAgICAgICAgICBsb2coZidDb21wcm9iYW5kbyB7bGVu
:::KGFyY2hpdm9zKX0gYXJjaGl2byhzKSBlbiAnCiAgICAgICAgICAgICAgICAgICAg
:::Zid7Y2FycGV0YX0gLi4uJywgJ3RpdHVsbycpCiAgICAgICAgICAgICAgICBpZiBu
:::b3QgYXJjaGl2b3M6CiAgICAgICAgICAgICAgICAgICAgbG9nKCdObyBoYXkgYXJj
:::aGl2b3MgZGUgYXVkaW8gbyB2aWRlbyB0b2RhdsOtYS4nLCAnZ3JpcycpCiAgICAg
:::ICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnY29tcHJvYmFjaW9uJywg
:::VHJ1ZSwgJycpKQogICAgICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAg
:::ICAgICAgdG90YWwgPSAwCiAgICAgICAgICAgICAgICBiYWphcyA9IDAKICAgICAg
:::ICAgICAgICAgIGZvciBwIGluIGFyY2hpdm9zOgogICAgICAgICAgICAgICAgICAg
:::IHRyeToKICAgICAgICAgICAgICAgICAgICAgICAgciA9IHN1YnByb2Nlc3MucnVu
:::KAogICAgICAgICAgICAgICAgICAgICAgICAgICAgW3N0cihGRlBST0JFKSwgJy12
:::JywgJ2Vycm9yJywgJy1zaG93X2VudHJpZXMnLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICdmb3JtYXQ9Yml0X3JhdGUsZHVyYXRpb24sc2l6ZScsICctb2Yn
:::LCAnanNvbicsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgc3RyKHApXSwK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0ZG91dD1zdWJwcm9jZXNzLlBJ
:::UEUsIHN0ZGVycj1zdWJwcm9jZXNzLlBJUEUsCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICB0ZXh0PVRydWUsIGVuY29kaW5nPSd1dGYtOCcsIGVycm9ycz0ncmVw
:::bGFjZScsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aW1lb3V0PTMwKQog
:::ICAgICAgICAgICAgICAgICAgICAgICBkYXRvcyA9IGpzb24ubG9hZHMoci5zdGRv
:::dXQgb3IgJ3t9JykuZ2V0KCdmb3JtYXQnLCB7fSkKICAgICAgICAgICAgICAgICAg
:::ICAgICAga2JwcyA9IGludChmbG9hdChkYXRvcy5nZXQoJ2JpdF9yYXRlJykgb3Ig
:::MCkgLyAxMDAwKQogICAgICAgICAgICAgICAgICAgICAgICBkdXIgPSBmbG9hdChk
:::YXRvcy5nZXQoJ2R1cmF0aW9uJykgb3IgMCkKICAgICAgICAgICAgICAgICAgICAg
:::ICAgdGFtID0gaW50KGZsb2F0KGRhdG9zLmdldCgnc2l6ZScpIG9yIDApKQogICAg
:::ICAgICAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgICAg
:::ICAgICAgICAgIGxvZyhmJ8K3IHtwLm5hbWVbOjYwXX0g4oCUIG5vIHNlIHB1ZG8g
:::bGVlcicsICdhdmlzbycpCiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnRpbnVl
:::CiAgICAgICAgICAgICAgICAgICAgdG90YWwgKz0gdGFtCiAgICAgICAgICAgICAg
:::ICAgICAgdGV4dG8sIG5pdmVsID0gY2xhc2VfY2FsaWRhZChwLnN1ZmZpeC5sb3dl
:::cigpLCBrYnBzKQogICAgICAgICAgICAgICAgICAgIGlmIG5pdmVsID09IDI6CiAg
:::ICAgICAgICAgICAgICAgICAgICAgIGJhamFzICs9IDEKICAgICAgICAgICAgICAg
:::ICAgICB0YWcgPSAoJ29rJyBpZiBuaXZlbCA9PSAwCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgIGVsc2UgKCdhdmlzbycgaWYgbml2ZWwgPT0gMSBlbHNlICdlcnJv
:::cicpKQogICAgICAgICAgICAgICAgICAgIGxvZyhmJ8K3IHtwLm5hbWVbOjU4XX0g
:::4oCUIHt0ZXh0b30gwrcge2ZtdF90aWVtKGR1cil9IMK3ICcKICAgICAgICAgICAg
:::ICAgICAgICAgICAgZid7Zm10X3RhbSh0YW0pfScsIHRhZykKICAgICAgICAgICAg
:::ICAgIGxvZyhmJ1Jlc3VsdGFkbzoge2xlbihhcmNoaXZvcyl9IGFyY2hpdm8ocykg
:::wrcgJwogICAgICAgICAgICAgICAgICAgIGYne2ZtdF90YW0odG90YWwpfSBlbiB0
:::b3RhbCDCtyB7YmFqYXN9IGNvbiBjYWxpZGFkIGJhamEnLAogICAgICAgICAgICAg
:::ICAgICAgICd0aXR1bG8nKQogICAgICAgICAgICAgICAgaWYgYmFqYXM6CiAgICAg
:::ICAgICAgICAgICAgICAgbG9nKCdDb25zZWpvOiBsb3MgYXJjaGl2b3MgbWFyY2Fk
:::b3MgZW4gcm9qbyBzZSBwdWVkZW4gJwogICAgICAgICAgICAgICAgICAgICAgICAn
:::dm9sdmVyIGEgZGVzY2FyZ2FyIGNvbiBtw6FzIGJpdHJhdGUuJywgJ2dyaXMnKQog
:::ICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uIGFzIGU6CiAgICAgICAgICAgICAg
:::ICBsb2coZidFcnJvciBhbCBjb21wcm9iYXIgbGEgY2FycGV0YToge2V9JywgJ2Vy
:::cm9yJykKICAgICAgICAgICAgZmluYWxseToKICAgICAgICAgICAgICAgIGNvbGEu
:::cHV0KCgnZmluJywgJ2NvbXByb2JhY2lvbicsIFRydWUsICcnKSkKCiAgICAgICAg
:::ZGVmIF9oaWxvX2FjdHVhbGl6YXIoc2VsZiwgY2ZnKToKICAgICAgICAgICAgY29s
:::YSA9IHNlbGYuY29sYQoKICAgICAgICAgICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6
:::CiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgICAg
:::ICAgICAgdHJ5OgogICAgICAgICAgICAgICAgbG9nKCdBY3R1YWxpemFuZG8geXQt
:::ZGxwIHkgbXV0YWdlbi4uLicsICdncmlzJykKICAgICAgICAgICAgICAgIHAgPSBz
:::dWJwcm9jZXNzLnJ1bigKICAgICAgICAgICAgICAgICAgICBbc3lzLmV4ZWN1dGFi
:::bGUsICctbScsICdwaXAnLCAnaW5zdGFsbCcsICctLXVwZ3JhZGUnLAogICAgICAg
:::ICAgICAgICAgICAgICAnLS1uby13YXJuLXNjcmlwdC1sb2NhdGlvbicsICd5dC1k
:::bHAnLCAnbXV0YWdlbiddLAogICAgICAgICAgICAgICAgICAgIHN0ZG91dD1zdWJw
:::cm9jZXNzLlBJUEUsIHN0ZGVycj1zdWJwcm9jZXNzLlNURE9VVCwKICAgICAgICAg
:::ICAgICAgICAgICB0ZXh0PVRydWUsIGVuY29kaW5nPSd1dGYtOCcsIGVycm9ycz0n
:::cmVwbGFjZScsIHRpbWVvdXQ9NjAwKQogICAgICAgICAgICAgICAgZm9yIGxuIGlu
:::IChwLnN0ZG91dCBvciAnJykuc3RyaXAoKS5zcGxpdGxpbmVzKClbLTY6XToKICAg
:::ICAgICAgICAgICAgICAgICBsb2coJyAgICcgKyBsbls6MTYwXSwgJ2dyaXMnKQog
:::ICAgICAgICAgICAgICAgaWYgcC5yZXR1cm5jb2RlID09IDA6CiAgICAgICAgICAg
:::ICAgICAgICAgbG9nKCd5dC1kbHAgYWN0dWFsaXphZG8uIFJlaW5pY2lhIGxhIGFw
:::bGljYWNpw7NuIHBhcmEgJwogICAgICAgICAgICAgICAgICAgICAgICAndXNhciBs
:::YSB2ZXJzacOzbiBudWV2YS4nLCAnb2snKQogICAgICAgICAgICAgICAgZWxzZToK
:::ICAgICAgICAgICAgICAgICAgICBsb2coJ0xhIGFjdHVhbGl6YWNpw7NuIGZhbGzD
:::syAowr9zaW4gaW50ZXJuZXQ/KS4nLCAnZXJyb3InKQogICAgICAgICAgICBleGNl
:::cHQgRXhjZXB0aW9uIGFzIGU6CiAgICAgICAgICAgICAgICBsb2coZidObyBzZSBw
:::dWRvIGVqZWN1dGFyIHBpcDoge2V9JywgJ2Vycm9yJykKICAgICAgICAgICAgZmlu
:::YWxseToKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2FjdHVhbGl6
:::YWNpb24nLCBUcnVlLCAnJykpCgogICAgICAgIGRlZiBfbXNnX2Vycm9yKHNlbGYs
:::IGUpOgogICAgICAgICAgICBsaW5lYXMgPSBbbCBmb3IgbCBpbiBzdHIoZSkuc3Ry
:::aXAoKS5zcGxpdGxpbmVzKCkgaWYgbC5zdHJpcCgpXQogICAgICAgICAgICByZXR1
:::cm4gKGxpbmVhc1swXVs6MjUwXSBpZiBsaW5lYXMKICAgICAgICAgICAgICAgICAg
:::ICBlbHNlIGYne3R5cGUoZSkuX19uYW1lX199OiBzaW4gZGV0YWxsZXMnKQoKICAg
:::ICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLSBhcnJhbnF1ZQogICAgICAgIGRlZiBfYXJyYW5xdWUoc2VsZik6CiAg
:::ICAgICAgICAgIHNlbGYuX2xvZyhmJ011c2lrQUxBTiB2e0FQUF9WfScsICd0aXR1
:::bG8nKQogICAgICAgICAgICBzZWxmLl9sb2coJ0N0cmwrVTogYWN0dWFsaXphciB5
:::dC1kbHAgwrcgQ3RybCtMOiBsaW1waWFyIHJlZ2lzdHJvJywKICAgICAgICAgICAg
:::ICAgICAgICAgICdncmlzJykKICAgICAgICAgICAgdGhyZWFkaW5nLlRocmVhZCh0
:::YXJnZXQ9c2VsZi5faGlsb192ZXJzaW9uLCBkYWVtb249VHJ1ZSkuc3RhcnQoKQoK
:::ICAgICAgICBkZWYgX2hpbG9fdmVyc2lvbihzZWxmKToKICAgICAgICAgICAgY29s
:::YSA9IHNlbGYuY29sYQoKICAgICAgICAgICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6
:::CiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgICAg
:::ICAgICAgaWYgWVRfRExQIGlzIE5vbmU6CiAgICAgICAgICAgICAgICBsb2coJ3l0
:::LWRscCBubyBlc3TDoSBpbnN0YWxhZG8uIEVqZWN1dGEgJwogICAgICAgICAgICAg
:::ICAgICAgICdEZXNjYXJnYWRvck11c2ljYS5iYXQgcGFyYSBpbnN0YWxhcmxvLics
:::ICdlcnJvcicpCiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICd2ZXJz
:::aW9uJywgVHJ1ZSwgJycpKQogICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAg
:::ICAgIHRyeToKICAgICAgICAgICAgICAgIGluc3RhbGFkYSA9IFlUX0RMUC52ZXJz
:::aW9uLl9fdmVyc2lvbl9fCiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAg
:::ICAgICAgICAgICAgICBpbnN0YWxhZGEgPSAnPycKICAgICAgICAgICAgdWx0aW1h
:::ID0gTm9uZQogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICB3aXRoIHVy
:::bG9wZW4oJ2h0dHBzOi8vcHlwaS5vcmcvcHlwaS95dC1kbHAvanNvbicsIHRpbWVv
:::dXQ9MTIpIGFzIHI6CiAgICAgICAgICAgICAgICAgICAgdWx0aW1hID0ganNvbi5s
:::b2FkcyhyLnJlYWQoKS5kZWNvZGUoJ3V0Zi04JykpWydpbmZvJ11bJ3ZlcnNpb24n
:::XQogICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICAgICAg
:::dWx0aW1hID0gTm9uZQogICAgICAgICAgICBpZiB1bHRpbWEgaXMgTm9uZToKICAg
:::ICAgICAgICAgICAgIGxvZyhmJ3l0LWRscDogdmVyc2nDs24ge2luc3RhbGFkYX0g
:::JwogICAgICAgICAgICAgICAgICAgICcobm8gc2UgcHVkbyBjb21wcm9iYXIgc2kg
:::aGF5IG5vdmVkYWRlcykuJywgJ2dyaXMnKQogICAgICAgICAgICBlbGlmIHN0cih1
:::bHRpbWEpID09IHN0cihpbnN0YWxhZGEpOgogICAgICAgICAgICAgICAgbG9nKGYn
:::eXQtZGxwOiBlbiBsYSB1bHRpbWEgdmVyc2lvbiAoe2luc3RhbGFkYX0pLicsICdp
:::bmZvJykKICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgIGxvZyhmJ3l0
:::LWRscDogaGF5IHZlcnNpb24gbnVldmEgKHt1bHRpbWF9KTsgaW5zdGFsYWRhOiAn
:::CiAgICAgICAgICAgICAgICAgICAgZid7aW5zdGFsYWRhfS4gUHVsc2EgQ3RybCtV
:::IHBhcmEgYWN0dWFsaXphci4nLCAnYXZpc28nKQogICAgICAgICAgICBpZiBGRk1Q
:::RUcgaXMgTm9uZToKICAgICAgICAgICAgICAgIGxvZygnRkZtcGVnOiBOTyBFTkNP
:::TlRSQURPIOKAlCBlamVjdXRhIERlc2NhcmdhZG9yTXVzaWNhLmJhdCAnCiAgICAg
:::ICAgICAgICAgICAgICAgJ3BhcmEgaW5zdGFsYXJsby4nLCAnZXJyb3InKQogICAg
:::ICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgbG9nKGYnRkZtcGVnOiBPSyAo
:::e0ZGTVBFR30pJywgJ2dyaXMnKQogICAgICAgICAgICBsb2coJ0NhcnBldGEgZGUg
:::Z3VhcmRhZG86ICcgKyBzdHIoQUpVU1RFUy5nZXQoJ2Rlc3Rpbm8nKSksICdncmlz
:::JykKICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAndmVyc2lvbicsIFRydWUs
:::ICcnKSkKCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gbWFpbgpkZWYgbWFpbigpOgogICAg
:::X3JlY29uZmlndXJhcl9zYWxpZGEoKQogICAgaWYgbm90IFRLX09LOgogICAgICAg
:::IHByaW50KCdFc3RhIGFwbGljYWNpw7NuIG5lY2VzaXRhIFRraW50ZXIgKGludGVy
:::ZmF6IGdyw6FmaWNhKS4nKQogICAgICAgIHByaW50KCdFbCBQeXRob24gYWN0dWFs
:::IG5vIGxvIGluY2x1eWUuJykKICAgICAgICBwcmludCgnVnVlbHZlIGEgZWplY3V0
:::YXIgRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0IHBhcmEgaW5zdGFsYXIgZWwgJwogICAg
:::ICAgICAgICAgICdQeXRob24gYWRlY3VhZG8uJykKICAgICAgICByZXR1cm4gMQog
:::ICAgY29tcHJvYmFyX2VudG9ybm8oKQogICAgYXBwID0gQXBwKCkKICAgIGFwcC5t
:::YWlubG9vcCgpCiAgICByZXR1cm4gMAoKCmlmIF9fbmFtZV9fID09ICdfX21haW5f
:::Xyc6CiAgICB0cnk6CiAgICAgICAgc3lzLmV4aXQobWFpbigpKQogICAgZXhjZXB0
:::IFN5c3RlbUV4aXQ6CiAgICAgICAgcmFpc2UKICAgIGV4Y2VwdCBCYXNlRXhjZXB0
:::aW9uOgogICAgICAgIHRyeToKICAgICAgICAgICAgd2l0aCBvcGVuKExPR19FUlJP
:::UkVTLCAnYScsIGVuY29kaW5nPSd1dGYtOCcpIGFzIGZoOgogICAgICAgICAgICAg
:::ICAgZmgud3JpdGUodHJhY2ViYWNrLmZvcm1hdF9leGMoKSArICdcbicpCiAgICAg
:::ICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgcGFzcwogICAgICAgIHJh
:::aXNlCg==
