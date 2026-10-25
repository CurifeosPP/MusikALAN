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
title MusikALAN v2.6
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
echo    %C_TIT%MusikALAN v2.6%C_FIN% - preparando el entorno
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
title MusikALAN v2.6 - YouTube a AAC/MP3/FLAC/WAV/WMA/AVI
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
:::b21hbmRvIGFudGlndW8sIHF1ZSBlcyBsbyBxdWUgc2kgZnVuY2lvbmFiYSkuCgpV
:::c286ICBweXRob24gZGVzY2FyZ2Fkb3IucHkgICAobyBkb2JsZSBjbGljIGVuIERl
:::c2NhcmdhZG9yTXVzaWNhLmJhdCkKU2kgbGEgVVJMIHBlcnRlbmVjZSBhIHVuYSBs
:::aXN0YSBkZSByZXByb2R1Y2Npb24sIGVsIHByb2dyYW1hIHByZWd1bnRhCnNpIGJh
:::amFyIHNvbG8gbGEgY2FuY2lvbiBwZWdhZGEgbyBsYSBwbGF5bGlzdCBjb21wbGV0
:::YSAoY29uIHVuYSBwYXVzYQpkZSAyIHMgZW50cmUgY2FuY2lvbmVzIHBhcmEgbm8g
:::c2F0dXJhciBhIFlvdVR1YmUpLgoiIiIKCmltcG9ydCBqc29uCmltcG9ydCBvcwpp
:::bXBvcnQgcXVldWUKaW1wb3J0IHJlCmltcG9ydCBzaHV0aWwKaW1wb3J0IHN1YnBy
:::b2Nlc3MKaW1wb3J0IHN5cwppbXBvcnQgdGVtcGZpbGUKaW1wb3J0IHRocmVhZGlu
:::ZwppbXBvcnQgdGltZQppbXBvcnQgdHJhY2ViYWNrCmZyb20gcGF0aGxpYiBpbXBv
:::cnQgUGF0aApmcm9tIHVybGxpYi5wYXJzZSBpbXBvcnQgcGFyc2VfcXMsIHVybGVu
:::Y29kZSwgdXJscGFyc2UsIHVybHVucGFyc2UKZnJvbSB1cmxsaWIucmVxdWVzdCBp
:::bXBvcnQgdXJsb3BlbgoKQVBQX1YgPSAnMi42JwpBUFBfRElSID0gUGF0aChfX2Zp
:::bGVfXykucmVzb2x2ZSgpLnBhcmVudApSVVRBX0FKVVNURVMgPSBBUFBfRElSIC8g
:::J2FqdXN0ZXMuanNvbicKTE9HX0VSUk9SRVMgPSBBUFBfRElSIC8gJ2Rlc2Nhcmdh
:::ZG9yX2Vycm9yZXMubG9nJwoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIHNhbGlkYQojIEFs
:::IGVqZWN1dGFyc2UgY29uIHB5dGhvbncuZXhlIChzaW4gY29uc29sYSkgc3Rkb3V0
:::L3N0ZGVyciBzb24gTm9uZToKIyBjdWFscXVpZXIgcHJpbnQgZmFsbGFyaWEuIExv
:::cyByZWRpcmlnaW1vcyBhIHVuIHNpdGlvIHNlZ3Vyby4KdHJ5OgogICAgaWYgc3lz
:::LnN0ZG91dCBpcyBOb25lOgogICAgICAgIHN5cy5zdGRvdXQgPSBvcGVuKG9zLmRl
:::dm51bGwsICd3JywgZW5jb2Rpbmc9J3V0Zi04JykKZXhjZXB0IEV4Y2VwdGlvbjoK
:::ICAgIHBhc3MKdHJ5OgogICAgaWYgc3lzLnN0ZGVyciBpcyBOb25lOgogICAgICAg
:::IHN5cy5zdGRlcnIgPSBvcGVuKExPR19FUlJPUkVTLCAnYScsIGVuY29kaW5nPSd1
:::dGYtOCcpCmV4Y2VwdCBFeGNlcHRpb246CiAgICBwYXNzCgoKZGVmIF9yZWNvbmZp
:::Z3VyYXJfc2FsaWRhKCk6CiAgICAiIiJFdml0YSBjcmFzaGVzIHBvciBjYXJhY3Rl
:::cmVzIHJhcm9zIHNpIGxhIHNhbGlkYSBzZSByZWRpcmlnZS4iIiIKICAgIGZvciBz
:::IGluIChzeXMuc3Rkb3V0LCBzeXMuc3RkZXJyKToKICAgICAgICB0cnk6CiAgICAg
:::ICAgICAgIGlmIHMgYW5kIGhhc2F0dHIocywgJ3JlY29uZmlndXJlJyk6CiAgICAg
:::ICAgICAgICAgICBzLnJlY29uZmlndXJlKGVycm9ycz0ncmVwbGFjZScpCiAgICAg
:::ICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgcGFzcwoKCiMgLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLSB0a2ludGVyCnRyeToKICAgIGltcG9ydCB0a2ludGVyIGFzIHRr
:::CiAgICBmcm9tIHRraW50ZXIgaW1wb3J0IGZpbGVkaWFsb2csIG1lc3NhZ2Vib3gs
:::IHR0awogICAgZnJvbSB0a2ludGVyLnNjcm9sbGVkdGV4dCBpbXBvcnQgU2Nyb2xs
:::ZWRUZXh0CiAgICBUS19PSyA9IFRydWUKZXhjZXB0IEV4Y2VwdGlvbjoKICAgIFRL
:::X09LID0gRmFsc2UKCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gYWp1c3RlcwpkZWYgX2Nh
:::cnBldGFfbXVzaWNhKCk6CiAgICAiIiJDYXJwZXRhICdNdXNpY2EnIHJlYWwgZGVs
:::IHVzdWFyaW8gKEZPTERFUklEX011c2ljIGRlIFdpbmRvd3MpLiIiIgogICAgaWYg
:::b3MubmFtZSA9PSAnbnQnOgogICAgICAgIHRyeToKICAgICAgICAgICAgaW1wb3J0
:::IGN0eXBlcwoKICAgICAgICAgICAgY2xhc3MgX0dVSUQoY3R5cGVzLlN0cnVjdHVy
:::ZSk6CiAgICAgICAgICAgICAgICBfZmllbGRzXyA9IFsoJ0QxJywgY3R5cGVzLmNf
:::dWxvbmcpLCAoJ0QyJywgY3R5cGVzLmNfdXNob3J0KSwKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICgnRDMnLCBjdHlwZXMuY191c2hvcnQpLAogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgKCdENCcsIGN0eXBlcy5jX3VieXRlICogOCldCgog
:::ICAgICAgICAgICBtdXNpY2EgPSBfR1VJRCgweDRCRDhENTcxLCAweDZEMTksIDB4
:::NDhEMywKICAgICAgICAgICAgICAgICAgICAgICAgICAgKGN0eXBlcy5jX3VieXRl
:::ICogOCkoMHhCRSwgMHg5NywgMHgwMywgMHgzOCwKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgMHg1RiwgMHg3RiwgMHhDNSwg
:::MHhDRSkpCiAgICAgICAgICAgIHB0ciA9IGN0eXBlcy5jX3djaGFyX3AoKQogICAg
:::ICAgICAgICBpZiBjdHlwZXMud2luZGxsLnNoZWxsMzIuU0hHZXRLbm93bkZvbGRl
:::clBhdGgoCiAgICAgICAgICAgICAgICAgICAgY3R5cGVzLmJ5cmVmKG11c2ljYSks
:::IDAsIE5vbmUsCiAgICAgICAgICAgICAgICAgICAgY3R5cGVzLmJ5cmVmKHB0cikp
:::ID09IDAgYW5kIHB0ci52YWx1ZToKICAgICAgICAgICAgICAgIHJ1dGEgPSBwdHIu
:::dmFsdWUKICAgICAgICAgICAgICAgIGN0eXBlcy53aW5kbGwub2xlMzIuQ29UYXNr
:::TWVtRnJlZShwdHIpCiAgICAgICAgICAgICAgICByZXR1cm4gcnV0YQogICAgICAg
:::IGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgIHBhc3MKICAgIHJldHVybiBz
:::dHIoUGF0aC5ob21lKCkgLyAnTXVzaWMnKQoKCmRlZiBfZGVzdGlub19hcHBkYXRh
:::X3ZpZWpvKCk6CiAgICAiIiJDYXJwZXRhIGRlbCBwcm9ncmFtYSAoZXJhIGVsIGRl
:::c3Rpbm8gcG9yIGRlZmVjdG8gZW4gbGEgdjIuMikuIiIiCiAgICBiYXNlID0gb3Mu
:::ZW52aXJvbi5nZXQoJ0FQUERBVEEnKSBvciBzdHIoUGF0aC5ob21lKCkgLyAnQXBw
:::RGF0YScgLyAnUm9hbWluZycpCiAgICByZXR1cm4gc3RyKFBhdGgoYmFzZSkgLyAn
:::TXVzaWtBTEFOJykKCgpkZWYgX2Rlc3Rpbm9fcG9yX2RlZmVjdG8oKToKICAgICIi
:::IkxvcyBhcmNoaXZvcyBzZSBndWFyZGFuIGVuIGxhIGNhcnBldGEgTXVzaWNhIGRl
:::bCB1c3VhcmlvLiIiIgogICAgcmV0dXJuIF9jYXJwZXRhX211c2ljYSgpCgoKQUpV
:::U1RFU19ERUZFQ1RPID0gewogICAgJ2Rlc3Rpbm8nOiBfZGVzdGlub19wb3JfZGVm
:::ZWN0bygpLAogICAgJ3RlbWEnOiAnT3NjdXJvJywKICAgICdmb3JtYXRvJzogJ0FB
:::QycsCiAgICAnY2FsaWRhZCc6ICcxMjhrJywKICAgICdlbWJlYmVyJzogVHJ1ZSwK
:::fQoKCmRlZiBjYXJnYXJfYWp1c3RlcygpOgogICAgYSA9IGRpY3QoQUpVU1RFU19E
:::RUZFQ1RPKQogICAgdHJ5OgogICAgICAgIGEudXBkYXRlKGpzb24ubG9hZHMoUlVU
:::QV9BSlVTVEVTLnJlYWRfdGV4dChlbmNvZGluZz0ndXRmLTgnKSkpCiAgICBleGNl
:::cHQgRXhjZXB0aW9uOgogICAgICAgIHBhc3MKICAgIGEucG9wKCduYXZlZ2Fkb3In
:::LCBOb25lKSAgIyB2Mi4yIG8gYW50ZXJpb3I6IGxhIHNlY2Npb24gZGUgY29va2ll
:::cyB5YSBubyBleGlzdGUKICAgICMgbWlncmFjaW9uZXMgZGVsIGRlc3Rpbm8gZGUg
:::Z3VhcmRhZG86CiAgICAjICDCtyB2Mi4wLzIuMSB1c2FiYSBNdXNpYy9ZVERvd25s
:::b2FkZXIKICAgICMgIMK3IHYyLjIgdXNhYmEgbGEgY2FycGV0YSBkZWwgcHJvZ3Jh
:::bWEgKEFwcERhdGFcUm9hbWluZ1xNdXNpa0FMQU4pCiAgICAjIERlc2RlIGxhIHYy
:::LjMgZWwgZGVzdGlubyBwb3IgZGVmZWN0byBlcyBsYSBjYXJwZXRhIE11c2ljYSBk
:::ZWwgdXN1YXJpbywKICAgICMgYXNpIHF1ZSBzaSBlbCBhanVzdGUgYXB1bnRhIGEg
:::Y3VhbHF1aWVyYSBkZSBsb3MgZG9zLCBzZSBhY3R1YWxpemEuCiAgICBkZXN0aW5v
:::ID0gc3RyKGEuZ2V0KCdkZXN0aW5vJykgb3IgJycpLnJlcGxhY2UoJ1xcJywgJy8n
:::KS5yc3RyaXAoJy8nKS5sb3dlcigpCiAgICBpZiAneXRkb3dubG9hZGVyJyBpbiBk
:::ZXN0aW5vOgogICAgICAgIGFbJ2Rlc3Rpbm8nXSA9IEFKVVNURVNfREVGRUNUT1sn
:::ZGVzdGlubyddCiAgICBlbHNlOgogICAgICAgIHZpZWpvID0gX2Rlc3Rpbm9fYXBw
:::ZGF0YV92aWVqbygpLnJlcGxhY2UoJ1xcJywgJy8nKS5yc3RyaXAoJy8nKS5sb3dl
:::cigpCiAgICAgICAgaWYgZGVzdGlubyBhbmQgKGRlc3Rpbm8gPT0gdmllam8KICAg
:::ICAgICAgICAgICAgICAgICAgICAgb3IgZGVzdGluby5zdGFydHN3aXRoKHZpZWpv
:::ICsgJy8nKSk6CiAgICAgICAgICAgIGFbJ2Rlc3Rpbm8nXSA9IEFKVVNURVNfREVG
:::RUNUT1snZGVzdGlubyddCiAgICByZXR1cm4gYQoKCmRlZiBndWFyZGFyX2FqdXN0
:::ZXMoKToKICAgIHRyeToKICAgICAgICBSVVRBX0FKVVNURVMud3JpdGVfdGV4dCgK
:::ICAgICAgICAgICAganNvbi5kdW1wcyhBSlVTVEVTLCBlbnN1cmVfYXNjaWk9RmFs
:::c2UsIGluZGVudD0yKSwKICAgICAgICAgICAgZW5jb2Rpbmc9J3V0Zi04JykKICAg
:::IGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgcGFzcwoKCkFKVVNURVMgPSBjYXJn
:::YXJfYWp1c3RlcygpCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIHV0aWxzCmRlZiBmbXRf
:::dGFtKG4pOgogICAgaWYgbm90IG46CiAgICAgICAgcmV0dXJuICfigJQnCiAgICBu
:::ID0gZmxvYXQobikKICAgIGZvciB1IGluICgnQicsICdLaUInLCAnTWlCJywgJ0dp
:::QicpOgogICAgICAgIGlmIG4gPCAxMDI0IG9yIHUgPT0gJ0dpQic6CiAgICAgICAg
:::ICAgIHJldHVybiBmJ3tpbnQobil9IHt1fScgaWYgdSA9PSAnQicgZWxzZSBmJ3tu
:::Oi4xZn0ge3V9JwogICAgICAgIG4gLz0gMTAyNAoKCmRlZiBmbXRfdGllbShzKToK
:::ICAgIGlmIHMgaXMgTm9uZToKICAgICAgICByZXR1cm4gJ+KAlCcKICAgIHMgPSBp
:::bnQocykKICAgIGgsIHIgPSBkaXZtb2QocywgMzYwMCkKICAgIG0sIHggPSBkaXZt
:::b2QociwgNjApCiAgICByZXR1cm4gZid7aH06e206MDJkfTp7eDowMmR9JyBpZiBo
:::IGVsc2UgZid7bTowMmR9Ont4OjAyZH0nCgoKZGVmIGxpbXBpYXJfbm9tYnJlKHQp
:::OgogICAgdCA9IHJlLnN1YihyJ1s8PjoiL1xcfD8qXHgwMC1ceDFmXScsICdfJywg
:::c3RyKHQpKS5zdHJpcCgnIC4nKQogICAgcmV0dXJuIHRbOjE1MF0gb3IgJ3Npbl90
:::aXR1bG8nCgoKZGVmIHNpbl9wbGF5bGlzdCh1cmwpOgogICAgIiIiUXVpdGEgZWwg
:::cGFyw6FtZXRybyBsaXN0PSBkZSBsYSBVUkwgKG1vZG8gc29sbyB2aWRlbykuIiIi
:::CiAgICB0cnk6CiAgICAgICAgcCA9IHVybHBhcnNlKHVybCkKICAgICAgICBxID0g
:::cGFyc2VfcXMocC5xdWVyeSkKICAgICAgICBpZiAnbGlzdCcgaW4gcToKICAgICAg
:::ICAgICAgZGVsIHFbJ2xpc3QnXQogICAgICAgICAgICByZXR1cm4gdXJsdW5wYXJz
:::ZShwLl9yZXBsYWNlKHF1ZXJ5PXVybGVuY29kZShxLCBkb3NlcT1UcnVlKSkpLCBU
:::cnVlCiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHBhc3MKICAgIHJldHVy
:::biB1cmwsIEZhbHNlCgoKZGVmIGVzX3VybF9wbGF5bGlzdCh1cmwpOgogICAgIiIi
:::VHJ1ZSBzaSBsYSBVUkwgcGVydGVuZWNlIGEgdW5hIGxpc3RhIGRlIHJlcHJvZHVj
:::Y2nDs24gKGxsZXZhIGxpc3Q9KS4iIiIKICAgIHRyeToKICAgICAgICByZXR1cm4g
:::J2xpc3QnIGluIHBhcnNlX3FzKHVybHBhcnNlKHVybCkucXVlcnkpCiAgICBleGNl
:::cHQgRXhjZXB0aW9uOgogICAgICAgIHJldHVybiBGYWxzZQoKCmRlZiBlc19zb2xv
:::X2xpc3RhKHVybCk6CiAgICAiIiJUcnVlIHNpIGxhIFVSTCBlcyB1bmEgcGxheWxp
:::c3QgcHVyYSwgc2luIHZpZGVvIGluZGl2aWR1YWwgKHNpbiB2PSkuIiIiCiAgICB0
:::cnk6CiAgICAgICAgcCA9IHVybHBhcnNlKHVybCkKICAgICAgICBpZiAndicgaW4g
:::cGFyc2VfcXMocC5xdWVyeSkgb3IgJ3lvdXR1LmJlJyBpbiAocC5uZXRsb2Mgb3Ig
:::JycpOgogICAgICAgICAgICByZXR1cm4gRmFsc2UKICAgICAgICByZXR1cm4gKHAu
:::cGF0aCBvciAnJykucnN0cmlwKCcvJykuZW5kc3dpdGgoJy9wbGF5bGlzdCcpCiAg
:::ICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHJldHVybiBGYWxzZQoKCmRlZiBh
:::YnJpcl9jYXJwZXRhKHJ1dGEpOgogICAgdHJ5OgogICAgICAgIGlmIG9zLm5hbWUg
:::PT0gJ250JzoKICAgICAgICAgICAgb3Muc3RhcnRmaWxlKHN0cihydXRhKSkgICMg
:::bm9xYTogc29sbyBXaW5kb3dzCiAgICAgICAgZWxzZToKICAgICAgICAgICAgc3Vi
:::cHJvY2Vzcy5Qb3BlbihbJ3hkZy1vcGVuJywgc3RyKHJ1dGEpXSkKICAgIGV4Y2Vw
:::dCBFeGNlcHRpb246CiAgICAgICAgcGFzcwoKCiMgLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBm
:::Zm1wZWcKZGVmIGJ1c2Nhcl9mZm1wZWcoKToKICAgIGV4ZSA9IHNodXRpbC53aGlj
:::aCgnZmZtcGVnJykKICAgIGlmIGV4ZToKICAgICAgICByZXR1cm4gUGF0aChleGUp
:::CiAgICBjYW5kaWRhdG9zID0gWwogICAgICAgIEFQUF9ESVIgLyAnZmZtcGVnJyAv
:::ICdiaW4nIC8gJ2ZmbXBlZy5leGUnLAogICAgICAgIEFQUF9ESVIgLyAnZmZtcGVn
:::JyAvICdiaW4nIC8gJ2ZmbXBlZycsCiAgICAgICAgQVBQX0RJUiAvICdydW50aW1l
:::JyAvICdmZm1wZWcuZXhlJywKICAgIF0KICAgIGZvciBwIGluIGNhbmRpZGF0b3M6
:::CiAgICAgICAgaWYgcC5leGlzdHMoKToKICAgICAgICAgICAgcmV0dXJuIHAKICAg
:::IHJldHVybiBOb25lCgoKZGVmIGJ1c2Nhcl9mZnByb2JlKGZmbXBlZyk6CiAgICBp
:::ZiBmZm1wZWcgaXMgTm9uZToKICAgICAgICByZXR1cm4gc2h1dGlsLndoaWNoKCdm
:::ZnByb2JlJykKICAgIHAgPSBmZm1wZWcud2l0aF9uYW1lKCdmZnByb2JlLmV4ZScg
:::aWYgb3MubmFtZSA9PSAnbnQnIGVsc2UgJ2ZmcHJvYmUnKQogICAgaWYgcC5leGlz
:::dHMoKToKICAgICAgICByZXR1cm4gcAogICAgcmV0dXJuIHNodXRpbC53aGljaCgn
:::ZmZwcm9iZScpCgoKWVRfRExQID0gTm9uZSAgICMgbcOzZHVsbyB5dF9kbHA7IHNl
:::IHJlbGxlbmEgZW4gY29tcHJvYmFyX2VudG9ybm8oKQpGRk1QRUcgPSBOb25lICAg
:::IyBydXRhIGRlIGZmbXBlZwpGRlBST0JFID0gTm9uZSAgIyBydXRhIGRlIGZmcHJv
:::YmUKCgpkZWYgY29tcHJvYmFyX2VudG9ybm8oKToKICAgIGdsb2JhbCBZVF9ETFAs
:::IEZGTVBFRywgRkZQUk9CRQogICAgdHJ5OgogICAgICAgIGltcG9ydCB5dF9kbHAg
:::YXMgbW9kCiAgICAgICAgWVRfRExQID0gbW9kCiAgICBleGNlcHQgRXhjZXB0aW9u
:::OgogICAgICAgIHBhc3MKICAgIEZGTVBFRyA9IGJ1c2Nhcl9mZm1wZWcoKQogICAg
:::RkZQUk9CRSA9IGJ1c2Nhcl9mZnByb2JlKEZGTVBFRykKCgpjbGFzcyBSZWdpc3Ry
:::bzoKICAgICIiIkxvZ2dlciBwYXJhIHl0LWRscDogcmVlbnbDrWEgYXZpc29zL2Vy
:::cm9yZXMgYWwgcmVnaXN0cm8gZGUgbGEgR1VJLiIiIgoKICAgIGRlZiBfX2luaXRf
:::XyhzZWxmKToKICAgICAgICBzZWxmLmxvZyA9IE5vbmUgICMgbGEgR1VJIGxvIGNv
:::bmVjdGE6IGxvZyhtZW5zYWplLCBldGlxdWV0YSkKCiAgICBkZWYgZGVidWcoc2Vs
:::ZiwgbSk6CiAgICAgICAgcGFzcwoKICAgICMgQXZpc29zIGludGVybm9zIGRlIHl0
:::LWRscCBxdWUgc29sbyBtZXRlbiBydWlkbyBlbiBlbCByZWdpc3RybzoKICAgIEFW
:::SVNPU19SVUlET1NPUyA9ICgnTm8gc3VwcG9ydGVkIEphdmFTY3JpcHQgcnVudGlt
:::ZScsICdFSlMnKQoKICAgIGRlZiB3YXJuaW5nKHNlbGYsIG0pOgogICAgICAgIG0g
:::PSBzdHIobSkuc3RyaXAoKQogICAgICAgIGlmIG5vdCBtIG9yIGFueSh4IGluIG0g
:::Zm9yIHggaW4gc2VsZi5BVklTT1NfUlVJRE9TT1MpOgogICAgICAgICAgICByZXR1
:::cm4KICAgICAgICBpZiBzZWxmLmxvZzoKICAgICAgICAgICAgc2VsZi5sb2cobSwg
:::J2F2aXNvJykKCiAgICBkZWYgZXJyb3Ioc2VsZiwgbSk6CiAgICAgICAgbSA9IHN0
:::cihtKS5zdHJpcCgpCiAgICAgICAgaWYgbSBhbmQgc2VsZi5sb2c6CiAgICAgICAg
:::ICAgIHNlbGYubG9nKG0sICdlcnJvcicpCgoKUkVHSVNUUk8gPSBSZWdpc3Rybygp
:::CgpOT01CUkVTX1BQID0gewogICAgJ0ZGbXBlZ0V4dHJhY3RBdWRpbyc6ICdDb252
:::aXJ0aWVuZG8gZWwgYXVkaW8gY29uIEZGbXBlZycsCiAgICAnRkZtcGVnVGh1bWJu
:::YWlsc0NvbnZlcnRvcic6ICdDb252aXJ0aWVuZG8gbGEgY2Fyw6F0dWxhIGEgSlBH
:::JywKICAgICdGRm1wZWdNZXRhZGF0YSc6ICdFc2NyaWJpZW5kbyBldGlxdWV0YXMg
:::KHTDrXR1bG8vYXJ0aXN0YSknLAogICAgJ0VtYmVkVGh1bWJuYWlsJzogJ0luY3J1
:::c3RhbmRvIGxhIGNhcsOhdHVsYScsCiAgICAnTW92ZUZpbGVzJzogJ09yZ2FuaXph
:::bmRvIGFyY2hpdm9zJywKICAgICdGRm1wZWdNZXJnZXInOiAnVW5pZW5kbyBwaXN0
:::YXMgZGUgdmlkZW8geSBhdWRpbycsCiAgICAnRkZtcGVnVmlkZW9Db252ZXJ0b3In
:::OiAnQ29udmlydGllbmRvIGVsIHZpZGVvJywKfQoKIyAtLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::IGZvcm1hdG9zCkZPUk1BVE9TID0gewogICAgJ0FBQyc6IGRpY3QodGV4dG89J0FB
:::QyAoLm00YSknLCBleHQ9J200YScsCiAgICAgICAgICAgICAgICBjYWxpZGFkZXM9
:::Wyc5NmsnLCAnMTI4ayddLCBkZWZlY3RvPScxMjhrJyksCiAgICAnTVAzJzogZGlj
:::dCh0ZXh0bz0nTVAzICgubXAzKScsIGV4dD0nbXAzJywKICAgICAgICAgICAgICAg
:::IGNhbGlkYWRlcz1bJzk2aycsICcxMjhrJywgJzE5MmsnLCAnMjU2aycsICczMjBr
:::J10sCiAgICAgICAgICAgICAgICBkZWZlY3RvPSczMjBrJyksCiAgICAnRkxBQyc6
:::IGRpY3QodGV4dG89J0ZMQUMgKC5mbGFjKScsIGV4dD0nZmxhYycsCiAgICAgICAg
:::ICAgICAgICAgY2FsaWRhZGVzPVsnc2luIHBlcmRpZGEnXSwgZGVmZWN0bz0nc2lu
:::IHBlcmRpZGEnKSwKICAgICdXQVYnOiBkaWN0KHRleHRvPSdXQVYgKC53YXYpJywg
:::ZXh0PSd3YXYnLAogICAgICAgICAgICAgICAgY2FsaWRhZGVzPVsnc2luIHBlcmRp
:::ZGEnXSwgZGVmZWN0bz0nc2luIHBlcmRpZGEnKSwKICAgICdXTUEnOiBkaWN0KHRl
:::eHRvPSdXTUEgKC53bWEpJywgZXh0PSd3bWEnLAogICAgICAgICAgICAgICAgY2Fs
:::aWRhZGVzPVsnOTZrJywgJzEyOGsnXSwgZGVmZWN0bz0nMTI4aycpLAogICAgJ0FW
:::SSc6IGRpY3QodGV4dG89J0FWSSAtIHNoZWlqdSAxLjgiICgxMjh4MTYwKScsIGV4
:::dD0nYXZpJywKICAgICAgICAgICAgICAgIGNhbGlkYWRlcz1bJzEyOHgxNjAgwrcg
:::MTYgZnBzJ10sIGRlZmVjdG89JzEyOHgxNjAgwrcgMTYgZnBzJyksCn0KCgojIC0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0gcHJvZ3Jlc28KZGVmIGhvb2tzX2d1aShjb2xhKToKICAg
:::ICIiIkNyZWEgbG9zIGhvb2tzIGRlIHl0LWRscCBxdWUgcHVibGljYW4gZXZlbnRv
:::cyBlbiBsYSBjb2xhIGRlIGxhIEdVSS4iIiIKICAgIGVzdGFkbyA9IHsndGl0dWxv
:::JzogRmFsc2UsICdwcF91bHQnOiBOb25lfQoKICAgIGRlZiBsb2cobSwgdD0naW5m
:::bycpOgogICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgZGVmIHBy
:::b2dyZXNvKGQpOgogICAgICAgIGlmIGRbJ3N0YXR1cyddID09ICdkb3dubG9hZGlu
:::Zyc6CiAgICAgICAgICAgIGlmIG5vdCBlc3RhZG9bJ3RpdHVsbyddOgogICAgICAg
:::ICAgICAgICAgaW5mbyA9IGQuZ2V0KCdpbmZvX2RpY3QnKSBvciB7fQogICAgICAg
:::ICAgICAgICAgdCA9IGluZm8uZ2V0KCd0aXRsZScpIG9yIFBhdGgoZC5nZXQoJ2Zp
:::bGVuYW1lJykgb3IgJycpLnN0ZW0KICAgICAgICAgICAgICAgIGlmIHQ6CiAgICAg
:::ICAgICAgICAgICAgICAgbG9nKCfimaogJyArIHN0cih0KVs6OTBdLCAndGl0dWxv
:::JykKICAgICAgICAgICAgICAgICAgICBlc3RhZG9bJ3RpdHVsbyddID0gVHJ1ZQog
:::ICAgICAgICAgICB0b3RhbCA9IGQuZ2V0KCd0b3RhbF9ieXRlcycpIG9yIGQuZ2V0
:::KCd0b3RhbF9ieXRlc19lc3RpbWF0ZScpIG9yIDAKICAgICAgICAgICAgZG9uZSA9
:::IGQuZ2V0KCdkb3dubG9hZGVkX2J5dGVzJywgMCkKICAgICAgICAgICAgdmVsID0g
:::ZC5nZXQoJ3NwZWVkJykKICAgICAgICAgICAgZXRhID0gZC5nZXQoJ2V0YScpCiAg
:::ICAgICAgICAgIGlmIHRvdGFsOgogICAgICAgICAgICAgICAgcGN0ID0gZG9uZSAv
:::IHRvdGFsICogMTAwCiAgICAgICAgICAgICAgICB0ZXh0byA9IGYne3BjdDo1LjFm
:::fSUgwrcge2ZtdF90YW0oZG9uZSl9IC8ge2ZtdF90YW0odG90YWwpfScKICAgICAg
:::ICAgICAgICAgIGlmIHZlbDoKICAgICAgICAgICAgICAgICAgICB0ZXh0byArPSBm
:::JyDCtyB7Zm10X3RhbSh2ZWwpfS9zJwogICAgICAgICAgICAgICAgaWYgZXRhIGlz
:::IG5vdCBOb25lOgogICAgICAgICAgICAgICAgICAgIHRleHRvICs9IGYnIMK3IHF1
:::ZWRhbiB7Zm10X3RpZW0oZXRhKX0nCiAgICAgICAgICAgICAgICBjb2xhLnB1dCgo
:::J3Byb2cnLCBwY3QsIHRleHRvKSkKICAgICAgICAgICAgZWxzZToKICAgICAgICAg
:::ICAgICAgIHYgPSBmJ3tmbXRfdGFtKHZlbCl9L3MnIGlmIHZlbCBlbHNlICcnCiAg
:::ICAgICAgICAgICAgICBjb2xhLnB1dCgoJ3Byb2cnLCBOb25lLCBmJ3tmbXRfdGFt
:::KGRvbmUpfSDCtyB7dn0nKSkKICAgICAgICBlbGlmIGRbJ3N0YXR1cyddID09ICdm
:::aW5pc2hlZCc6CiAgICAgICAgICAgIGVzdGFkb1sncHBfdWx0J10gPSBOb25lCiAg
:::ICAgICAgICAgIGNvbGEucHV0KCgnbG9nJywgJ0Rlc2NhcmdhIHJlY2liaWRhLiBQ
:::cm9jZXNhbmRvLi4uJywgJ2dyaXMnKSkKICAgICAgICAgICAgY29sYS5wdXQoKCdw
:::cm9nJywgMCwgJ1Byb2Nlc2FuZG8uLi4nKSkKCiAgICBkZWYgcG9zdHByb2Nlc28o
:::ZCk6CiAgICAgICAgaWYgZFsnc3RhdHVzJ10gPT0gJ3N0YXJ0ZWQnOgogICAgICAg
:::ICAgICBub20gPSAoZC5nZXQoJ3Bvc3Rwcm9jZXNzb3JfbmFtZScpCiAgICAgICAg
:::ICAgICAgICAgICBvciBkLmdldCgncG9zdHByb2Nlc3NvcicpIG9yICdQb3N0cHJv
:::Y2VzbycpCiAgICAgICAgICAgIGlmIG5vbSA9PSBlc3RhZG9bJ3BwX3VsdCddOgog
:::ICAgICAgICAgICAgICAgcmV0dXJuICAjIHl0LWRscCBhIHZlY2VzIGFudW5jaWEg
:::ZWwgbWlzbW8gcGFzbyBkb3MgdmVjZXMKICAgICAgICAgICAgZXN0YWRvWydwcF91
:::bHQnXSA9IG5vbQogICAgICAgICAgICB0ZXh0byA9IE5PTUJSRVNfUFAuZ2V0KG5v
:::bSwgbm9tKSArICcuLi4nCiAgICAgICAgICAgIGNvbGEucHV0KCgnbG9nJywgJ+KG
:::kiAnICsgdGV4dG8sICdncmlzJykpCiAgICAgICAgICAgIGNvbGEucHV0KCgncHJv
:::ZycsIE5vbmUsIHRleHRvKSkKCiAgICByZXR1cm4gcHJvZ3Jlc28sIHBvc3Rwcm9j
:::ZXNvCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIG9wY2lvbmVzCmRlZiBvcHRzX2Jhc2Uo
:::Y2FycGV0YSwgY29sYSk6CiAgICBwcm9ncmVzbywgcG9zdHByb2Nlc28gPSBob29r
:::c19ndWkoY29sYSkKICAgIG8gPSB7CiAgICAgICAgJ291dHRtcGwnOiBzdHIoY2Fy
:::cGV0YSAvICclKHRpdGxlKXMuJShleHQpcycpLAogICAgICAgICdxdWlldCc6IFRy
:::dWUsCiAgICAgICAgJ25vX3dhcm5pbmdzJzogVHJ1ZSwKICAgICAgICAnbm9wcm9n
:::cmVzcyc6IFRydWUsCiAgICAgICAgJ25vcGxheWxpc3QnOiBUcnVlLAogICAgICAg
:::ICdpZ25vcmVlcnJvcnMnOiBGYWxzZSwKICAgICAgICAncmV0cmllcyc6IDEwLAog
:::ICAgICAgICdmcmFnbWVudF9yZXRyaWVzJzogMTAsCiAgICAgICAgJ3NvY2tldF90
:::aW1lb3V0JzogMzAsCiAgICAgICAgJ2NvbmN1cnJlbnRfZnJhZ21lbnRfZG93bmxv
:::YWRzJzogNCwKICAgICAgICAnd2luZG93c2ZpbGVuYW1lcyc6IFRydWUsCiAgICAg
:::ICAgJ292ZXJ3cml0ZXMnOiBGYWxzZSwKICAgICAgICAnbG9nZ2VyJzogUkVHSVNU
:::Uk8sCiAgICAgICAgJ3Byb2dyZXNzX2hvb2tzJzogW3Byb2dyZXNvXSwKICAgICAg
:::ICAncG9zdHByb2Nlc3Nvcl9ob29rcyc6IFtwb3N0cHJvY2Vzb10sCiAgICB9CiAg
:::ICBpZiBGRk1QRUc6CiAgICAgICAgb1snZmZtcGVnX2xvY2F0aW9uJ10gPSBzdHIo
:::RkZNUEVHLnBhcmVudCkKICAgIHJldHVybiBvCgoKZGVmIGNvbnZlcnRpcl9mZm1w
:::ZWcoY21kLCBldGlxdWV0YSwgY29sYSk6CiAgICAiIiJFamVjdXRhIEZGbXBlZyAo
:::bGlzdGEgZGUgYXJndW1lbnRvcywgc2luIHNoZWxsKSBjb24gbWFycXVlZS4iIiIK
:::ICAgIGNvbGEucHV0KCgncHJvZycsIE5vbmUsIGV0aXF1ZXRhKSkKCiAgICBkZWYg
:::bG9nKG0sIHQ9J2luZm8nKToKICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQp
:::KQoKICAgIHRyeToKICAgICAgICBwID0gc3VicHJvY2Vzcy5ydW4oY21kLCBzdGRv
:::dXQ9c3VicHJvY2Vzcy5QSVBFLAogICAgICAgICAgICAgICAgICAgICAgICAgICBz
:::dGRlcnI9c3VicHJvY2Vzcy5QSVBFLCB0ZXh0PVRydWUsCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIGVuY29kaW5nPSd1dGYtOCcsIGVycm9ycz0ncmVwbGFjZScp
:::CiAgICBleGNlcHQgRmlsZU5vdEZvdW5kRXJyb3I6CiAgICAgICAgcCA9IE5vbmUK
:::ICAgIGlmIHAgaXMgTm9uZSBvciBwLnJldHVybmNvZGUgIT0gMDoKICAgICAgICBs
:::b2coJ+KcliBGRm1wZWcgZGV2b2x2acOzIHVuIGVycm9yOicsICdlcnJvcicpCiAg
:::ICAgICAgaWYgcCBpcyBub3QgTm9uZToKICAgICAgICAgICAgZm9yIGxuIGluIChw
:::LnN0ZGVyciBvciAnJykuc3RyaXAoKS5zcGxpdGxpbmVzKClbLTQ6XToKICAgICAg
:::ICAgICAgICAgIGxvZygnICAgJyArIGxuWzoxODBdLCAnZ3JpcycpCiAgICAgICAg
:::Y29sYS5wdXQoKCdwcm9nJywgMCwgJycpKQogICAgICAgIHJldHVybiBGYWxzZQog
:::ICAgcmV0dXJuIFRydWUKCgpkZWYgYXJjaGl2b19maW5hbChpbmZvLCBjYXJwZXRh
:::LCBleHQpOgogICAgIiIiTG9jYWxpemEgZWwgYXJjaGl2byByZXN1bHRhbnRlICh5
:::dC1kbHAgbG8gcmVwb3J0YTsgZmFsbGJhY2s6IG3DoXMgbnVldm8pLiIiIgogICAg
:::dHJ5OgogICAgICAgIGZvciBkIGluIChpbmZvLmdldCgncmVxdWVzdGVkX2Rvd25s
:::b2FkcycpIG9yIFtdKToKICAgICAgICAgICAgZiA9IGQuZ2V0KCdmaWxlcGF0aCcp
:::CiAgICAgICAgICAgIGlmIGY6CiAgICAgICAgICAgICAgICByZXR1cm4gUGF0aChm
:::KQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICBwYXNzCiAgICBjYW5kID0g
:::c29ydGVkKGNhcnBldGEuZ2xvYignKi4nICsgZXh0KSwKICAgICAgICAgICAgICAg
:::ICAga2V5PWxhbWJkYSBwOiBwLnN0YXQoKS5zdF9tdGltZSwgcmV2ZXJzZT1UcnVl
:::KQogICAgcmV0dXJuIGNhbmRbMF0gaWYgY2FuZCBlbHNlIE5vbmUKCgpkZWYgbGlt
:::cGlhcl9taW5pYXR1cmFzKGNhcnBldGEsIGFyY2hpdm8pOgogICAgIiIiQm9ycmEg
:::bWluaWF0dXJhcyBzdWVsdGFzIHF1ZSBFbWJlZFRodW1ibmFpbCBkZWphcmEgc2lu
:::IGluY3J1c3Rhci4iIiIKICAgIGZvciBleHQgaW4gKCcud2VicCcsICcuanBnJywg
:::Jy5qcGVnJywgJy5wbmcnKToKICAgICAgICB0ID0gYXJjaGl2by53aXRoX3N1ZmZp
:::eChleHQpCiAgICAgICAgaWYgdC5leGlzdHMoKToKICAgICAgICAgICAgdHJ5Ogog
:::ICAgICAgICAgICAgICAgdC51bmxpbmsoKQogICAgICAgICAgICBleGNlcHQgT1NF
:::cnJvcjoKICAgICAgICAgICAgICAgIHBhc3MKCgpkZWYgX21pbmlhdHVyYV9ieXRl
:::cyhjYXJwZXRhLCBhcmNoaXZvKToKICAgICIiIkxlZSBsb3MgYnl0ZXMgZGUgbGEg
:::bWluaWF0dXJhIHF1ZSB5dC1kbHAgZGVqbyBqdW50byBhbCBhcmNoaXZvIGZpbmFs
:::LiIiIgogICAgaWYgbm90IGFyY2hpdm86CiAgICAgICAgcmV0dXJuIE5vbmUKICAg
:::IGZvciBleHQgaW4gKCcuanBnJywgJy5qcGVnJywgJy53ZWJwJywgJy5wbmcnKToK
:::ICAgICAgICB0ID0gYXJjaGl2by53aXRoX3N1ZmZpeChleHQpCiAgICAgICAgaWYg
:::dC5leGlzdHMoKToKICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgcmV0
:::dXJuIHQucmVhZF9ieXRlcygpCiAgICAgICAgICAgIGV4Y2VwdCBPU0Vycm9yOgog
:::ICAgICAgICAgICAgICAgcGFzcwogICAgcmV0dXJuIE5vbmUKCgpkZWYgX2VzX2pw
:::ZyhkYXRvcyk6CiAgICByZXR1cm4gYm9vbChkYXRvcykgYW5kIGRhdG9zWzozXSA9
:::PSBiJ1x4ZmZceGQ4XHhmZicKCgpkZWYgX2FfanBnKGRhdG9zKToKICAgICIiIkNv
:::bnZpZXJ0ZSBsb3MgYnl0ZXMgZGUgdW5hIGltYWdlbiAod2VicC9wbmcvLi4uKSBh
:::IEpQRUcgY29uIEZGbXBlZy4KCiAgICBMb3MgcmVwcm9kdWN0b3JlcyBiYXJhdG9z
:::ICh0aXBvIHNoZWlqdSkgc3VlbGVuIGxlZXIgc29sbyBKUEVHOiBsYQogICAgbWlu
:::aWF0dXJhIGRlIFlvdVR1YmUgdmllbmUgZW4gV2ViUCB5IEVtYmVkVGh1bWJuYWls
:::IGRlIHl0LWRscCBsYQogICAgY29udmllcnRlIGEgUE5HICgiUE5HIGlzIHByZWZl
:::cnJlZCBzaW5jZSBKUEVHIGlzIGxvc3N5IiksIGFzaSBxdWUKICAgIGFxdWkgbm9z
:::IGFzZWd1cmFtb3Mgbm9zb3Ryb3MgZGUgcXVlIGFjYWJlIGVuIEpQRUcuIiIiCiAg
:::ICBpZiBub3QgZGF0b3Mgb3Igbm90IEZGTVBFRzoKICAgICAgICByZXR1cm4gTm9u
:::ZQogICAgYmFzZSA9IFBhdGgodGVtcGZpbGUuZ2V0dGVtcGRpcigpKSAvICgnbXVz
:::aWthbGFuX2NhcmF0dWxhXyVkJyAlIG9zLmdldHBpZCgpKQogICAgb3JpZ2VuLCBk
:::ZXN0aW5vID0gYmFzZS53aXRoX3N1ZmZpeCgnLm9yaWcnKSwgYmFzZS53aXRoX3N1
:::ZmZpeCgnLmpwZycpCiAgICB0cnk6CiAgICAgICAgb3JpZ2VuLndyaXRlX2J5dGVz
:::KGRhdG9zKQogICAgICAgIHIgPSBzdWJwcm9jZXNzLnJ1bigKICAgICAgICAgICAg
:::W3N0cihGRk1QRUcpLCAnLXknLCAnLWxvZ2xldmVsJywgJ2Vycm9yJywgJy1pJywg
:::c3RyKG9yaWdlbiksCiAgICAgICAgICAgICAnLXE6dicsICcyJywgc3RyKGRlc3Rp
:::bm8pXSwKICAgICAgICAgICAgc3Rkb3V0PXN1YnByb2Nlc3MuREVWTlVMTCwgc3Rk
:::ZXJyPXN1YnByb2Nlc3MuREVWTlVMTCkKICAgICAgICBpZiByLnJldHVybmNvZGUg
:::PT0gMCBhbmQgZGVzdGluby5leGlzdHMoKToKICAgICAgICAgICAganBnID0gZGVz
:::dGluby5yZWFkX2J5dGVzKCkKICAgICAgICAgICAgaWYgX2VzX2pwZyhqcGcpOgog
:::ICAgICAgICAgICAgICAgcmV0dXJuIGpwZwogICAgZXhjZXB0IEV4Y2VwdGlvbjoK
:::ICAgICAgICBwYXNzCiAgICBmaW5hbGx5OgogICAgICAgIGZvciBmIGluIChvcmln
:::ZW4sIGRlc3Rpbm8pOgogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBm
:::LnVubGluaygpCiAgICAgICAgICAgIGV4Y2VwdCBPU0Vycm9yOgogICAgICAgICAg
:::ICAgICAgcGFzcwogICAgcmV0dXJuIE5vbmUKCgpkZWYgX3dtX3BpY3R1cmUoanBn
:::LCBkZXNjcmlwY2lvbj0nJyk6CiAgICAiIiJFbXBhcXVldGEgdW5vcyBieXRlcyBK
:::UEVHIGVuIGVsIGF0cmlidXRvIFdNL1BpY3R1cmUgZGVsIGNvbnRlbmVkb3IKICAg
:::IEFTRiAodGlwbyAzID0gcG9ydGFkYSBmcm9udGFsKSwgY29tbyBoYWNpYSBlbCBz
:::Y3JpcHQgYW50aWd1by4iIiIKICAgIGRlZiB1MTYocyk6CiAgICAgICAgcmV0dXJu
:::IHN0cihzKS5lbmNvZGUoJ3V0Zi0xNi1sZScpICsgYidceDAwXHgwMCcKCiAgICBt
:::aW1lID0gdTE2KCdpbWFnZS9qcGVnJykKICAgIGRlc2MgPSB1MTYoZGVzY3JpcGNp
:::b24pCiAgICByZXR1cm4gKGInXHgwMycgKyBsZW4obWltZSkudG9fYnl0ZXMoNCwg
:::J2xpdHRsZScpICsgbWltZQogICAgICAgICAgICArIGxlbihkZXNjKS50b19ieXRl
:::cyg0LCAnbGl0dGxlJykgKyBkZXNjICsganBnKQoKCiMgLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LSBldGlxdWV0YXMKZGVmIF9hcnRpc3RhX2xpbXBpbyhpbmZvKToKICAgICIiIk5v
:::bWJyZSBkZWwgYXJ0aXN0YSBsZWdpYmxlIHBhcmEgcmVwcm9kdWN0b3Jlcy4KCiAg
:::ICBMb3MgY2FuYWxlcyBhdXRvbWF0aWNvcyBkZSBtdXNpY2EgZGUgWW91VHViZSBz
:::ZSBsbGFtYW4gJ1ggLSBUb3BpYyc7CiAgICBlc2Ugc3VmaWpvIHNvYnJhIGN1YW5k
:::byBzZSB2ZSBlbiBsYSBwYW50YWxsYSBkZSB1biByZXByb2R1Y3Rvci4iIiIKICAg
:::IGEgPSAoaW5mby5nZXQoJ2FydGlzdCcpIG9yIGluZm8uZ2V0KCdjcmVhdG9yJykK
:::ICAgICAgICAgb3IgaW5mby5nZXQoJ3VwbG9hZGVyJykgb3IgaW5mby5nZXQoJ2No
:::YW5uZWwnKSBvciAnJykKICAgIGEgPSBzdHIoYSkuc3RyaXAoKQogICAgYSA9IHJl
:::LnN1YihyJ1xzKi1ccypUb3BpY1xzKiQnLCAnJywgYSwgZmxhZ3M9cmUuSSkuc3Ry
:::aXAoKQogICAgcmV0dXJuIGEKCgpkZWYgX2FsYnVtX2RlKGluZm8pOgogICAgIiIi
:::QWxidW0gcGFyYSBlbCBhcmNoaXZvIGZpbmFsLgoKICAgIHl0LWRscCBzb2xvIGVz
:::Y3JpYmUgYWxidW0gc2kgZWwgcHJvcGlvIHZpZGVvIGxvIHRyYWUgKGNhc2kgbnVu
:::Y2EpOgogICAgcG9yIGVzbyBsb3MgcmVwcm9kdWN0b3JlcyBtb3N0cmFiYW4gJ2Fs
:::YnVtIGRlc2Nvbm9jaWRvJy4gT3JkZW4gZGUKICAgIHByZWZlcmVuY2lhOiBhbGJ1
:::bSByZWFsIC0+IG5vbWJyZSBkZSBsYSBwbGF5bGlzdCAtPiBhcnRpc3RhLiIiIgog
:::ICAgZm9yIGNsYXZlIGluICgnYWxidW0nLCAncGxheWxpc3RfdGl0bGUnKToKICAg
:::ICAgICB2ID0gc3RyKGluZm8uZ2V0KGNsYXZlKSBvciAnJykuc3RyaXAoKQogICAg
:::ICAgIGlmIHY6CiAgICAgICAgICAgIHJldHVybiB2CiAgICByZXR1cm4gX2FydGlz
:::dGFfbGltcGlvKGluZm8pIG9yICdZb3VUdWJlJwoKCmRlZiBhcGxpY2FyX3RhZ3Mo
:::aW5mbywgYXJjaGl2bywgbG9nPU5vbmUsIGNhcmF0dWxhPU5vbmUpOgogICAgIiIi
:::RXNjcmliZSBjb24gbXV0YWdlbiBsYXMgZXRpcXVldGFzIGRlbCBhcmNoaXZvIGZp
:::bmFsLgoKICAgIEdhcmFudGl6YSBxdWUgVE9ET1MgbG9zIHJlcHJvZHVjdG9yZXMg
:::bXVlc3RyZW4gYXJ0aXN0YSB5IGFsYnVtLAogICAgYXVucXVlIEZGbXBlZ01ldGFk
:::YXRhIGRlIHl0LWRscCBubyBsb3MgaGF5YSBlc2NyaXRvLiBBZGVtYXM6CiAgICAg
:::IMK3IE1QMzogSUQzdjIuNCBjb24gdGV4dG9zIFVURi0xNiAoZW5jb2Rpbmc9MSkg
:::eSBBUElDKG1pbWUKICAgICAgICAnaW1hZ2UvanBnJywgdGlwbyAzLCBkZXNjICdh
:::dHRhY2hlZCBwaWN0dXJlJyksIGNhbGNhZG8gZGVsCiAgICAgICAgTVAzIGRlIHJl
:::ZmVyZW5jaWEgcXVlIGVsIHJlcHJvZHVjdG9yIGRlbCB1c3VhcmlvIG11ZXN0cmEK
:::ICAgICAgICBiaWVuLiBFbCBwYXNlIGFudGlndW8gdXNhYmEgZW5jb2Rpbmc9MyAo
:::VVRGLTgpIGRlbnRybyBkZSB1bgogICAgICAgIHRhZyB2Mi4zOiBmdWVyYSBkZSBl
:::c3BlY2lmaWNhY2lvbiwgeSBsb3MgcmVwcm9kdWN0b3JlcwogICAgICAgIGJhcmF0
:::b3MgZGVzY2FydGFiYW4gbGEgZXRpcXVldGEgRU5URVJBIChuaSBhcnRpc3RhLCBu
:::aQogICAgICAgIGFsYnVtLCBuaSBwb3J0YWRhKS4KICAgICAgwrcgbGEgY2FyYXR1
:::bGEgc2llbXByZSBhY2FiYSBlbiBKUEVHICh5dC1kbHAgaW5jcnVzdGEgbGFzCiAg
:::ICAgICAgbWluaWF0dXJhcyBkZSBZb3VUdWJlIGNvbW8gUE5HL1dlYlAgeSBtdWNo
:::b3MgcmVwcm9kdWN0b3JlcwogICAgICAgIGJhcmF0b3Mgc29sbyBsZWVuIEpQRUc7
:::IGN1YW5kbyBlbCBwYXJzZXIgZGUgbGEgY2FyYXR1bGEgZmFsbGEsCiAgICAgICAg
:::ZGVqYW4gZGUgbW9zdHJhciB0YW1iaWVuIGFydGlzdGEgeSBhbGJ1bSk7CiAgICAg
:::IMK3IHNpIEVtYmVkVGh1bWJuYWlsIG5vIGluY3J1c3RvIG5hZGEsIHNlIGluY3J1
:::c3RhIGBjYXJhdHVsYWA7CiAgICAgIMK3IGVsIGNvbWVudGFyaW8gZ3VhcmRhIGxh
:::IFVSTCBkZWwgdmlkZW8gKGNvbW8gZWwgc2NyaXB0IGFudGlndW8pOwogICAgICDC
:::tyBXTUEgbGxldmEgY2FyYXR1bGEgKFdNL1BpY3R1cmUpIHkgVVJMIChXTS9BdXRo
:::b3JVUkwpIHZpYSBtdXRhZ2VuLgogICAgYGNhcmF0dWxhYCBzb24gbG9zIGJ5dGVz
:::IGRlIGxhIG1pbmlhdHVyYSBkZXNjYXJnYWRhIChvcGNpb25hbCkuIiIiCiAgICB0
:::cnk6CiAgICAgICAgcCA9IFBhdGgoYXJjaGl2bykKICAgICAgICBpZiBub3QgcC5l
:::eGlzdHMoKToKICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgYXJ0aXN0YSA9IF9h
:::cnRpc3RhX2xpbXBpbyhpbmZvKQogICAgICAgIGFsYnVtID0gX2FsYnVtX2RlKGlu
:::Zm8pCiAgICAgICAgdGl0dWxvID0gc3RyKGluZm8uZ2V0KCd0cmFjaycpIG9yIGlu
:::Zm8uZ2V0KCd0aXRsZScpIG9yICcnKS5zdHJpcCgpCiAgICAgICAgZmVjaGEgPSBz
:::dHIoaW5mby5nZXQoJ3JlbGVhc2VfeWVhcicpIG9yICcnKQogICAgICAgIGlmIG5v
:::dCBmZWNoYToKICAgICAgICAgICAgZmVjaGEgPSBzdHIoaW5mby5nZXQoJ3VwbG9h
:::ZF9kYXRlJykgb3IgJycpCiAgICAgICAgICAgIGlmIGxlbihmZWNoYSkgPT0gOCBh
:::bmQgZmVjaGEuaXNkaWdpdCgpOgogICAgICAgICAgICAgICAgZmVjaGEgPSBmZWNo
:::YVs6NF0KICAgICAgICB1cmwgPSBzdHIoaW5mby5nZXQoJ3dlYnBhZ2VfdXJsJykg
:::b3IgJycpLnN0cmlwKCkKICAgICAgICBpZiBjYXJhdHVsYSBhbmQgbm90IF9lc19q
:::cGcoY2FyYXR1bGEpOgogICAgICAgICAgICBjYXJhdHVsYSA9IF9hX2pwZyhjYXJh
:::dHVsYSkKICAgICAgICBleHQgPSBwLnN1ZmZpeC5sb3dlcigpCiAgICAgICAgaWYg
:::ZXh0ID09ICcubTRhJzoKICAgICAgICAgICAgZnJvbSBtdXRhZ2VuLm1wNCBpbXBv
:::cnQgTVA0LCBNUDRDb3ZlcgogICAgICAgICAgICBtID0gTVA0KHN0cihwKSkKICAg
:::ICAgICAgICAgaWYgdGl0dWxvOgogICAgICAgICAgICAgICAgbVsnXHhhOW5hbSdd
:::ID0gW3RpdHVsb10KICAgICAgICAgICAgaWYgYXJ0aXN0YToKICAgICAgICAgICAg
:::ICAgIG1bJ1x4YTlBUlQnXSA9IFthcnRpc3RhXQogICAgICAgICAgICAgICAgbVsn
:::YUFSVCddID0gW2FydGlzdGFdCiAgICAgICAgICAgIGlmIGFsYnVtOgogICAgICAg
:::ICAgICAgICAgbVsnXHhhOWFsYiddID0gW2FsYnVtXQogICAgICAgICAgICBpZiBm
:::ZWNoYToKICAgICAgICAgICAgICAgIG1bJ1x4YTlkYXknXSA9IFtmZWNoYV0KICAg
:::ICAgICAgICAgaWYgdXJsOgogICAgICAgICAgICAgICAgbVsnXHhhOWNtdCddID0g
:::W3VybF0KICAgICAgICAgICAgIyAtLSBjYXJhdHVsYTogZ2FyYW50aXphbW9zIEpQ
:::RUcgU0lFTVBSRSAodGFtYmllbiBjdWFuZG8KICAgICAgICAgICAgIyAgICBFbWJl
:::ZFRodW1ibmFpbCB5YSBpbmNydXN0byBhbGdvKTsgYGNhcmF0dWxhYCBlcyBlbCBw
:::bGFuIEIKICAgICAgICAgICAgIyAgICBzaSBubyBxdWVkbyBuaW5ndW5hLiB5dC1k
:::bHAvRW1iZWRUaHVtYm5haWwgdXNhIGVsIGF0b21vCiAgICAgICAgICAgICMgICAg
:::ZXN0YW5kYXIgJ2NvdnInIChzaW4gZWwgcHJlZmlqbyAoYykpOyBlbiBtdXRhZ2Vu
:::IG1vZGVybm8KICAgICAgICAgICAgIyAgICBlc2NyaWJpciAnXHhhOWNvdnInIGxh
:::bnphIFR5cGVFcnJvci4KICAgICAgICAgICAgdmllamFzID0gbS5nZXQoJ2NvdnIn
:::KSBvciBtLmdldCgnXHhhOWNvdnInKSBvciBbXQogICAgICAgICAgICBpZiBub3Qg
:::dmllamFzOgogICAgICAgICAgICAgICAgaWYgY2FyYXR1bGE6CiAgICAgICAgICAg
:::ICAgICAgICAgbVsnY292ciddID0gW01QNENvdmVyKGNhcmF0dWxhLCBNUDRDb3Zl
:::ci5GT1JNQVRfSlBFRyldCiAgICAgICAgICAgIGVsaWYgYWxsKGMuaW1hZ2Vmb3Jt
:::YXQgIT0gTVA0Q292ZXIuRk9STUFUX0pQRUcKICAgICAgICAgICAgICAgICAgICAg
:::Zm9yIGMgaW4gdmllamFzKToKICAgICAgICAgICAgICAgIG51ZXZhID0gX2FfanBn
:::KGJ5dGVzKHZpZWphc1swXSkpIG9yIGNhcmF0dWxhCiAgICAgICAgICAgICAgICBp
:::ZiBudWV2YToKICAgICAgICAgICAgICAgICAgICBtWydjb3ZyJ10gPSBbTVA0Q292
:::ZXIobnVldmEsIE1QNENvdmVyLkZPUk1BVF9KUEVHKV0KICAgICAgICAgICAgICAg
:::ICAgICBtLnBvcCgnXHhhOWNvdnInLCBOb25lKQogICAgICAgICAgICBlbGlmIG0u
:::Z2V0KCdceGE5Y292cicpOgogICAgICAgICAgICAgICAgbVsnY292ciddID0gdmll
:::amFzCiAgICAgICAgICAgICAgICBtLnBvcCgnXHhhOWNvdnInLCBOb25lKQogICAg
:::ICAgICAgICBtLnNhdmUoKQogICAgICAgIGVsaWYgZXh0ID09ICcubXAzJzoKICAg
:::ICAgICAgICAgIyBGb3JtYXRvIEVYQUNUTyBkZWwgTVAzIGRlIHJlZmVyZW5jaWEg
:::KFNuYXB0dWJlLCBlc2NyaXRvIHBvcgogICAgICAgICAgICAjIEZGbXBlZy9MYXZm
:::KSBxdWUgZWwgcmVwcm9kdWN0b3IgZGVsIHVzdWFyaW8gU0kgbXVlc3RyYToKICAg
:::ICAgICAgICAgIyAgIElEM3YyLjQuMCArIFRJVDIvVFBFMS9UQUxCL0FQSUMgZW4g
:::ZW5jb2Rpbmc9MSAoVVRGLTE2IGNvbgogICAgICAgICAgICAjICAgQk9NKSArIEFQ
:::SUMobWltZSAnaW1hZ2UvanBnJywgdGlwbyAzID0gQ09WRVJfRlJPTlQsIGRlc2MK
:::ICAgICAgICAgICAgIyAgICdhdHRhY2hlZCBwaWN0dXJlJywgSlBFRyByZWFsKS4g
:::RWwgcGFzZSBhbnRlcmlvciBlc2NyaWJpYQogICAgICAgICAgICAjICAgZW5jb2Rp
:::bmc9MyAoVVRGLTgpIGRlbnRybyBkZSB1biB0YWcgdjIuMzogZnVlcmEgZGUKICAg
:::ICAgICAgICAgIyAgIGVzcGVjaWZpY2FjaW9uLCB5IGxvcyByZXByb2R1Y3RvcmVz
:::IGJhcmF0b3MgZGVzY2FydGFiYW4KICAgICAgICAgICAgIyAgIGxhIGV0aXF1ZXRh
:::IGVudGVyYSAobmkgYXJ0aXN0YSwgbmkgYWxidW0sIG5pIHBvcnRhZGEpLgogICAg
:::ICAgICAgICBmcm9tIG11dGFnZW4uaWQzIGltcG9ydCAoQVBJQywgQ09NTSwgSUQz
:::LCBUQUxCLCBURFJDLCBUSVQyLAogICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgVExFTiwgVFBFMSwgVFBFMikKICAgICAgICAgICAgdHJ5OgogICAg
:::ICAgICAgICAgICAgdGFncyA9IElEMyhzdHIocCkpCiAgICAgICAgICAgIGV4Y2Vw
:::dCBFeGNlcHRpb246CiAgICAgICAgICAgICAgICB0YWdzID0gSUQzKCkKICAgICAg
:::ICAgICAgaWYgdGl0dWxvOgogICAgICAgICAgICAgICAgdGFncy5zZXRhbGwoJ1RJ
:::VDInLCBbVElUMihlbmNvZGluZz0xLCB0ZXh0PVt0aXR1bG9dKV0pCiAgICAgICAg
:::ICAgIGlmIGFydGlzdGE6CiAgICAgICAgICAgICAgICB0YWdzLnNldGFsbCgnVFBF
:::MScsIFtUUEUxKGVuY29kaW5nPTEsIHRleHQ9W2FydGlzdGFdKV0pCiAgICAgICAg
:::ICAgICAgICB0YWdzLnNldGFsbCgnVFBFMicsIFtUUEUyKGVuY29kaW5nPTEsIHRl
:::eHQ9W2FydGlzdGFdKV0pCiAgICAgICAgICAgIGlmIGFsYnVtOgogICAgICAgICAg
:::ICAgICAgdGFncy5zZXRhbGwoJ1RBTEInLCBbVEFMQihlbmNvZGluZz0xLCB0ZXh0
:::PVthbGJ1bV0pXSkKICAgICAgICAgICAgaWYgZmVjaGE6CiAgICAgICAgICAgICAg
:::ICB0YWdzLnNldGFsbCgnVERSQycsIFtURFJDKGVuY29kaW5nPTEsIHRleHQ9W2Zl
:::Y2hhXSldKQogICAgICAgICAgICBkdXIgPSBpbmZvLmdldCgnZHVyYXRpb24nKQog
:::ICAgICAgICAgICBpZiBkdXI6CiAgICAgICAgICAgICAgICB0cnk6CiAgICAgICAg
:::ICAgICAgICAgICAgdGFncy5zZXRhbGwoJ1RMRU4nLCBbVExFTihlbmNvZGluZz0w
:::LCB0ZXh0PVsKICAgICAgICAgICAgICAgICAgICAgICAgc3RyKGludChmbG9hdChk
:::dXIpICogMTAwMCkpXSldKQogICAgICAgICAgICAgICAgZXhjZXB0IChUeXBlRXJy
:::b3IsIFZhbHVlRXJyb3IpOgogICAgICAgICAgICAgICAgICAgIHBhc3MKICAgICAg
:::ICAgICAgaWYgdXJsOgogICAgICAgICAgICAgICAgdGFncy5zZXRhbGwoJ0NPTU0n
:::LCBbQ09NTShlbmNvZGluZz0xLCBsYW5nPSdlbmcnLAogICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBkZXNjPScnLCB0ZXh0PVt1cmxdKV0p
:::CiAgICAgICAgICAgICMgUG9ydGFkYTogbWlzbWFzIGNvbnN0YW50ZXMgZGVsIGFy
:::Y2hpdm8gZGUgcmVmZXJlbmNpYS4KICAgICAgICAgICAgIyBCeXRlczogYGNhcmF0
:::dWxhYCBvLCBzaSBFbWJlZFRodW1ibmFpbCB5YSBpbmNydXN0byBhbGdvLAogICAg
:::ICAgICAgICAjIGxvcyBkYXRvcyBkZWwgQVBJQyBleGlzdGVudGU7IHNpZW1wcmUg
:::YWNhYmFtb3MgZW4gSlBFRy4KICAgICAgICAgICAgZGF0b3MgPSBjYXJhdHVsYQog
:::ICAgICAgICAgICBpZiBub3QgZGF0b3M6CiAgICAgICAgICAgICAgICBhcGljcyA9
:::IHRhZ3MuZ2V0YWxsKCdBUElDJykKICAgICAgICAgICAgICAgIGlmIGFwaWNzOgog
:::ICAgICAgICAgICAgICAgICAgIGRhdG9zID0gYXBpY3NbMF0uZGF0YQogICAgICAg
:::ICAgICBpZiBkYXRvcyBhbmQgbm90IF9lc19qcGcoZGF0b3MpOgogICAgICAgICAg
:::ICAgICAgZGF0b3MgPSBfYV9qcGcoZGF0b3MpCiAgICAgICAgICAgIGlmIGRhdG9z
:::OgogICAgICAgICAgICAgICAgdGFncy5zZXRhbGwoJ0FQSUMnLCBbQVBJQyhlbmNv
:::ZGluZz0xLCBtaW1lPSdpbWFnZS9qcGcnLAogICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICB0eXBlPTMsIGRlc2M9J2F0dGFjaGVkIHBpY3R1
:::cmUnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBk
:::YXRhPWRhdG9zKV0pCiAgICAgICAgICAgICMgdjIuNCArIFVURi0xNjogbGEgbWlz
:::bWEgY29tYmluYWNpb24gZGVsIGFyY2hpdm8gZGUKICAgICAgICAgICAgIyByZWZl
:::cmVuY2lhIChJRDN2Mi40LjAgZXNjcml0byBwb3IgTGF2ZjYwLjMuMTAwKS4KICAg
:::ICAgICAgICAgdGFncy5zYXZlKHN0cihwKSwgdjJfdmVyc2lvbj00KQogICAgICAg
:::IGVsaWYgZXh0ID09ICcud2F2JzoKICAgICAgICAgICAgZnJvbSBtdXRhZ2VuLmlk
:::MyBpbXBvcnQgKENPTU0sIFREUkMsIFRJVDIsIFRMRU4sIFRQRTEsIFRQRTIsCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBUQUxCKQogICAgICAg
:::ICAgICBmcm9tIG11dGFnZW4ud2F2ZSBpbXBvcnQgV0FWRQogICAgICAgICAgICB3
:::ID0gV0FWRShzdHIocCkpCiAgICAgICAgICAgIGlmIHcudGFncyBpcyBOb25lOgog
:::ICAgICAgICAgICAgICAgdy5hZGRfdGFncygpCiAgICAgICAgICAgICMgZW5jb2Rp
:::bmc9MSAoVVRGLTE2KSwgbWlzbWEgcmVnbGEgcXVlIGVuIE1QMzogbG9zCiAgICAg
:::ICAgICAgICMgcmVwcm9kdWN0b3JlcyBiYXJhdG9zIG5vIHBhcnNlYW4gZnJhbWVz
:::IFVURi04LgogICAgICAgICAgICBpZiB0aXR1bG86CiAgICAgICAgICAgICAgICB3
:::LnRhZ3Muc2V0YWxsKCdUSVQyJywgW1RJVDIoZW5jb2Rpbmc9MSwgdGV4dD1bdGl0
:::dWxvXSldKQogICAgICAgICAgICBpZiBhcnRpc3RhOgogICAgICAgICAgICAgICAg
:::dy50YWdzLnNldGFsbCgnVFBFMScsIFtUUEUxKGVuY29kaW5nPTEsIHRleHQ9W2Fy
:::dGlzdGFdKV0pCiAgICAgICAgICAgICAgICB3LnRhZ3Muc2V0YWxsKCdUUEUyJywg
:::W1RQRTIoZW5jb2Rpbmc9MSwgdGV4dD1bYXJ0aXN0YV0pXSkKICAgICAgICAgICAg
:::aWYgYWxidW06CiAgICAgICAgICAgICAgICB3LnRhZ3Muc2V0YWxsKCdUQUxCJywg
:::W1RBTEIoZW5jb2Rpbmc9MSwgdGV4dD1bYWxidW1dKV0pCiAgICAgICAgICAgIGlm
:::IGZlY2hhOgogICAgICAgICAgICAgICAgdy50YWdzLnNldGFsbCgnVERSQycsIFtU
:::RFJDKGVuY29kaW5nPTEsIHRleHQ9W2ZlY2hhXSldKQogICAgICAgICAgICBkdXIg
:::PSBpbmZvLmdldCgnZHVyYXRpb24nKQogICAgICAgICAgICBpZiBkdXI6CiAgICAg
:::ICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICAgICAgdy50YWdzLnNldGFs
:::bCgnVExFTicsIFtUTEVOKGVuY29kaW5nPTAsIHRleHQ9WwogICAgICAgICAgICAg
:::ICAgICAgICAgICBzdHIoaW50KGZsb2F0KGR1cikgKiAxMDAwKSldKV0pCiAgICAg
:::ICAgICAgICAgICBleGNlcHQgKFR5cGVFcnJvciwgVmFsdWVFcnJvcik6CiAgICAg
:::ICAgICAgICAgICAgICAgcGFzcwogICAgICAgICAgICBpZiB1cmw6CiAgICAgICAg
:::ICAgICAgICB3LnRhZ3Muc2V0YWxsKCdDT01NJywgW0NPTU0oZW5jb2Rpbmc9MSwg
:::bGFuZz0nZW5nJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICBkZXNjPScnLCB0ZXh0PVt1cmxdKV0pCiAgICAgICAgICAgIHcuc2F2
:::ZSgpCiAgICAgICAgZWxpZiBleHQgPT0gJy5mbGFjJzoKICAgICAgICAgICAgZnJv
:::bSBtdXRhZ2VuLmZsYWMgaW1wb3J0IEZMQUMsIFBpY3R1cmUKICAgICAgICAgICAg
:::ZiA9IEZMQUMoc3RyKHApKQogICAgICAgICAgICBpZiB0aXR1bG86CiAgICAgICAg
:::ICAgICAgICBmWyd0aXRsZSddID0gW3RpdHVsb10KICAgICAgICAgICAgaWYgYXJ0
:::aXN0YToKICAgICAgICAgICAgICAgIGZbJ2FydGlzdCddID0gW2FydGlzdGFdCiAg
:::ICAgICAgICAgICAgICBmWydhbGJ1bWFydGlzdCddID0gW2FydGlzdGFdCiAgICAg
:::ICAgICAgIGlmIGFsYnVtOgogICAgICAgICAgICAgICAgZlsnYWxidW0nXSA9IFth
:::bGJ1bV0KICAgICAgICAgICAgaWYgZmVjaGE6CiAgICAgICAgICAgICAgICBmWydk
:::YXRlJ10gPSBbZmVjaGFdCiAgICAgICAgICAgIGlmIHVybDoKICAgICAgICAgICAg
:::ICAgIGZbJ2NvbW1lbnQnXSA9IFt1cmxdCiAgICAgICAgICAgIGlmIG5vdCBmLnBp
:::Y3R1cmVzOgogICAgICAgICAgICAgICAgaWYgY2FyYXR1bGE6CiAgICAgICAgICAg
:::ICAgICAgICAgcGljID0gUGljdHVyZSgpCiAgICAgICAgICAgICAgICAgICAgcGlj
:::Lm1pbWUsIHBpYy50eXBlLCBwaWMuZGVzYyA9ICdpbWFnZS9qcGVnJywgMywgJ0Nv
:::dmVyJwogICAgICAgICAgICAgICAgICAgIHBpYy5kYXRhID0gY2FyYXR1bGEKICAg
:::ICAgICAgICAgICAgICAgICBmLmFkZF9waWN0dXJlKHBpYykKICAgICAgICAgICAg
:::ZWxpZiBhbGwocGkubWltZSAhPSAnaW1hZ2UvanBlZycgZm9yIHBpIGluIGYucGlj
:::dHVyZXMpOgogICAgICAgICAgICAgICAgbnVldmEgPSBfYV9qcGcoZi5waWN0dXJl
:::c1swXS5kYXRhKSBvciBjYXJhdHVsYQogICAgICAgICAgICAgICAgaWYgbnVldmE6
:::CiAgICAgICAgICAgICAgICAgICAgZm9yIHZpZWphIGluIGxpc3QoZi5waWN0dXJl
:::cyk6CiAgICAgICAgICAgICAgICAgICAgICAgIGYucmVtb3ZlX3BpY3R1cmUodmll
:::amEpCiAgICAgICAgICAgICAgICAgICAgcGljID0gUGljdHVyZSgpCiAgICAgICAg
:::ICAgICAgICAgICAgcGljLm1pbWUsIHBpYy50eXBlLCBwaWMuZGVzYyA9ICdpbWFn
:::ZS9qcGVnJywgMywgJ0NvdmVyJwogICAgICAgICAgICAgICAgICAgIHBpYy5kYXRh
:::ID0gbnVldmEKICAgICAgICAgICAgICAgICAgICBmLmFkZF9waWN0dXJlKHBpYykK
:::ICAgICAgICAgICAgZi5zYXZlKCkKICAgICAgICBlbGlmIGV4dCA9PSAnLndtYSc6
:::CiAgICAgICAgICAgIGZyb20gbXV0YWdlbi5hc2YgaW1wb3J0IEFTRiwgQVNGQnl0
:::ZUFycmF5QXR0cmlidXRlCiAgICAgICAgICAgIGEgPSBBU0Yoc3RyKHApKQogICAg
:::ICAgICAgICBpZiB0aXR1bG86CiAgICAgICAgICAgICAgICBhWydUaXRsZSddID0g
:::W3RpdHVsb10KICAgICAgICAgICAgaWYgYXJ0aXN0YToKICAgICAgICAgICAgICAg
:::IGFbJ0F1dGhvciddID0gW2FydGlzdGFdCiAgICAgICAgICAgICAgICBhWydXTS9B
:::bGJ1bUFydGlzdCddID0gW2FydGlzdGFdCiAgICAgICAgICAgIGlmIGFsYnVtOgog
:::ICAgICAgICAgICAgICAgYVsnV00vQWxidW1UaXRsZSddID0gW2FsYnVtXQogICAg
:::ICAgICAgICBpZiBmZWNoYToKICAgICAgICAgICAgICAgIGFbJ1dNL1llYXInXSA9
:::IFtmZWNoYV0KICAgICAgICAgICAgaWYgdXJsOgogICAgICAgICAgICAgICAgYVsn
:::RGVzY3JpcHRpb24nXSA9IFt1cmxdCiAgICAgICAgICAgICAgICBhWydXTS9BdXRo
:::b3JVUkwnXSA9IFt1cmxdCiAgICAgICAgICAgIGlmIGNhcmF0dWxhOgogICAgICAg
:::ICAgICAgICAgYVsnV00vUGljdHVyZSddID0gW0FTRkJ5dGVBcnJheUF0dHJpYnV0
:::ZSgKICAgICAgICAgICAgICAgICAgICBfd21fcGljdHVyZShjYXJhdHVsYSwgdGl0
:::dWxvIG9yICdDb3ZlcicpKV0KICAgICAgICAgICAgYS5zYXZlKCkKICAgICAgICBl
:::bHNlOgogICAgICAgICAgICByZXR1cm4KICAgICAgICBpZiBsb2c6CiAgICAgICAg
:::ICAgIGV4dHJhID0gJyDCtyBjYXLDoXR1bGEgSlBFRycgaWYgY2FyYXR1bGEgZWxz
:::ZSAnJwogICAgICAgICAgICBsb2coJ0V0aXF1ZXRhcyBlc2NyaXRhczogYXJ0aXN0
:::YSDCqyVzwrsgwrcgw6FsYnVtIMKrJXPCuyVzJwogICAgICAgICAgICAgICAgJSAo
:::YXJ0aXN0YSBvciAn4oCUJywgYWxidW0gb3IgJ+KAlCcsIGV4dHJhKSwgJ2dyaXMn
:::KQogICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBlOgogICAgICAgICMgbGFzIGV0aXF1
:::ZXRhcyBubyBzb24gY3JpdGljYXM6IG51bmNhIGRlYmVuIHJvbXBlciBsYSBkZXNj
:::YXJnYQogICAgICAgIGlmIGxvZzoKICAgICAgICAgICAgbG9nKCdObyBzZSBwdWRp
:::ZXJvbiBlc2NyaWJpciB0b2RhcyBsYXMgZXRpcXVldGFzOiAlcycgJSBlLAogICAg
:::ICAgICAgICAgICAgJ2F2aXNvJykKCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gZGVzY2Fy
:::Z2FzCmRlZiBkZXNjYXJnYXJfYXVkaW8odXJsLCBub21icmVfZm10LCBjYWxpZGFk
:::LCBkZXN0aW5vLCBlbWJlYmVyLCBjb2xhKToKICAgICIiIkFBQyAoLm00YSkgLyBN
:::UDMgLyBGTEFDIC8gV0FWIHbDrWEgcG9zdHByb2Nlc2Fkb3JlcyBkZSB5dC1kbHAu
:::CgogICAgTGEgY2Fyw6F0dWxhIHNlIGNvbnZpZXJ0ZSBhIEpQRyBBTlRFUyBkZSBp
:::bmNydXN0YXJsYSAobWlzbW8gb3JkZW4geQogICAgY2xhdmVzIHF1ZSBnZW5lcmEg
:::ZWwgQ0xJIGNvbiAtLWNvbnZlcnQtdGh1bWJuYWlscyBqcGcpOgogICAgRW1iZWRU
:::aHVtYm5haWwgc29sbyBjb252aWVydGUgbGFzIG1pbmlhdHVyYXMgV2ViUCBkZSBZ
:::b3VUdWJlIGEgUE5HCiAgICAoIlBORyBpcyBwcmVmZXJyZWQgc2luY2UgSlBFRyBp
:::cyBsb3NzeSIpIHkgbG9zIHJlcHJvZHVjdG9yZXMKICAgIGJhcmF0b3Mgc3VlbGVu
:::IGxlZXIgc29sbyBKUEVHLiIiIgogICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAg
:::ICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICBmbXQgPSBGT1JNQVRP
:::U1tub21icmVfZm10XQogICAgY2FycGV0YSA9IGRlc3Rpbm8gICAgICAgICAgIyB2
:::Mi4zOiBzaW4gc3ViY2FycGV0YXMgcG9yIGZvcm1hdG8KICAgIGNhcnBldGEubWtk
:::aXIocGFyZW50cz1UcnVlLCBleGlzdF9vaz1UcnVlKQogICAgY29kZWMgPSBmbXRb
:::J2V4dCddCiAgICBjb25fcG9ydGFkYSA9IGVtYmViZXIgYW5kIG5vbWJyZV9mbXQg
:::aW4gKCdBQUMnLCAnTVAzJywgJ0ZMQUMnKQogICAgY29uX3RhZ3MgPSBlbWJlYmVy
:::CiAgICBwcHMgPSBbXQogICAgaWYgY29uX3BvcnRhZGE6CiAgICAgICAgcHBzLmFw
:::cGVuZCh7J2tleSc6ICdGRm1wZWdUaHVtYm5haWxzQ29udmVydG9yJywgJ2Zvcm1h
:::dCc6ICdqcGcnLAogICAgICAgICAgICAgICAgICAgICd3aGVuJzogJ2JlZm9yZV9k
:::bCd9KQogICAgcHBzLmFwcGVuZCh7J2tleSc6ICdGRm1wZWdFeHRyYWN0QXVkaW8n
:::LCAncHJlZmVycmVkY29kZWMnOiBjb2RlYywKICAgICAgICAgICAgICAgICdwcmVm
:::ZXJyZWRxdWFsaXR5JzogY2FsaWRhZCBvciAnMCd9KQogICAgaWYgY29uX3RhZ3M6
:::CiAgICAgICAgcHBzLmFwcGVuZCh7J2tleSc6ICdGRm1wZWdNZXRhZGF0YScsICdh
:::ZGRfbWV0YWRhdGEnOiBUcnVlfSkKICAgIGlmIGNvbl9wb3J0YWRhOgogICAgICAg
:::IHBwcy5hcHBlbmQoeydrZXknOiAnRW1iZWRUaHVtYm5haWwnLAogICAgICAgICAg
:::ICAgICAgICAgICdhbHJlYWR5X2hhdmVfdGh1bWJuYWlsJzogRmFsc2V9KQogICAg
:::byA9IG9wdHNfYmFzZShjYXJwZXRhLCBjb2xhKQogICAgb1snZm9ybWF0J10gPSAn
:::YmVzdGF1ZGlvL2Jlc3QnCiAgICBvWydwb3N0cHJvY2Vzc29ycyddID0gcHBzCiAg
:::ICBvWyd3cml0ZXRodW1ibmFpbCddID0gY29uX3BvcnRhZGEKICAgIHdpdGggWVRf
:::RExQLllvdXR1YmVETChvKSBhcyB5ZGw6CiAgICAgICAgaW5mbyA9IHlkbC5leHRy
:::YWN0X2luZm8odXJsLCBkb3dubG9hZD1UcnVlKQogICAgYXJjaGl2byA9IGFyY2hp
:::dm9fZmluYWwoaW5mbywgY2FycGV0YSwgY29kZWMpCiAgICBjYXJhdHVsYSA9IF9t
:::aW5pYXR1cmFfYnl0ZXMoY2FycGV0YSwgYXJjaGl2bykKICAgIGlmIGFyY2hpdm8g
:::YW5kIGNvbl9wb3J0YWRhOgogICAgICAgIGxpbXBpYXJfbWluaWF0dXJhcyhjYXJw
:::ZXRhLCBhcmNoaXZvKQogICAgaWYgYXJjaGl2bzoKICAgICAgICBhcGxpY2FyX3Rh
:::Z3MoaW5mbywgYXJjaGl2bywgbG9nLCBjYXJhdHVsYSkKICAgIHJldHVybiBpbmZv
:::LCBhcmNoaXZvCgoKZGVmIGRlc2Nhcmdhcl93bWEodXJsLCBjYWxpZGFkLCBkZXN0
:::aW5vLCBlbWJlYmVyLCBjb2xhKToKICAgICIiIldNQSA5Ni8xMjgga2JwczogeXQt
:::ZGxwIG5vIHNvcG9ydGEgd21hLCBhc8OtIHF1ZSBzZSBiYWphIGEgV0FWIChjb24K
:::ICAgIGV0aXF1ZXRhcykgeSBsdWVnbyBGRm1wZWcgcmVjb2RpZmljYSBhIHdtYXYy
:::IGRlbnRybyBkZWwgLndtYSBmaW5hbC4KICAgIExhIGNhcsOhdHVsYSAoV00vUGlj
:::dHVyZSwgZW4gSlBFRykgeSBsYSBVUkwgKFdNL0F1dGhvclVSTCkgc2UKICAgIGlu
:::Y3J1c3RhbiBjb24gbXV0YWdlbiwgY29tbyBlbiBlbCBzY3JpcHQgYW50aWd1by4i
:::IiIKICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgogICAgICAgIGNvbGEucHV0KCgn
:::bG9nJywgbSwgdCkpCgogICAgY2FycGV0YSA9IGRlc3Rpbm8gICAgICAgICAgIyB2
:::Mi4zOiBzaW4gc3ViY2FycGV0YXMgcG9yIGZvcm1hdG8KICAgIHRtcCA9IGNhcnBl
:::dGEgLyAnX3RtcCcKICAgIHNodXRpbC5ybXRyZWUodG1wLCBpZ25vcmVfZXJyb3Jz
:::PVRydWUpCiAgICB0bXAubWtkaXIocGFyZW50cz1UcnVlLCBleGlzdF9vaz1UcnVl
:::KQogICAgbyA9IG9wdHNfYmFzZSh0bXAsIGNvbGEpCiAgICBvWydmb3JtYXQnXSA9
:::ICdiZXN0YXVkaW8vYmVzdCcKICAgIHBwcyA9IFt7J2tleSc6ICdGRm1wZWdFeHRy
:::YWN0QXVkaW8nLCAncHJlZmVycmVkY29kZWMnOiAnd2F2JywKICAgICAgICAgICAg
:::J3ByZWZlcnJlZHF1YWxpdHknOiAnMCd9XQogICAgaWYgZW1iZWJlcjoKICAgICAg
:::ICBwcHMuaW5zZXJ0KDAsIHsna2V5JzogJ0ZGbXBlZ1RodW1ibmFpbHNDb252ZXJ0
:::b3InLAogICAgICAgICAgICAgICAgICAgICAgICdmb3JtYXQnOiAnanBnJywgJ3do
:::ZW4nOiAnYmVmb3JlX2RsJ30pCiAgICAgICAgcHBzLmFwcGVuZCh7J2tleSc6ICdG
:::Rm1wZWdNZXRhZGF0YScsICdhZGRfbWV0YWRhdGEnOiBUcnVlfSkKICAgIG9bJ3Bv
:::c3Rwcm9jZXNzb3JzJ10gPSBwcHMKICAgIG9bJ3dyaXRldGh1bWJuYWlsJ10gPSBl
:::bWJlYmVyCiAgICB3aXRoIFlUX0RMUC5Zb3V0dWJlREwobykgYXMgeWRsOgogICAg
:::ICAgIGluZm8gPSB5ZGwuZXh0cmFjdF9pbmZvKHVybCwgZG93bmxvYWQ9VHJ1ZSkK
:::ICAgIHdhdiA9IGFyY2hpdm9fZmluYWwoaW5mbywgdG1wLCAnd2F2JykKICAgIGlm
:::IG5vdCB3YXY6CiAgICAgICAgcmFpc2UgUnVudGltZUVycm9yKCdObyBzZSBlbmNv
:::bnRyw7MgZWwgV0FWIGludGVybWVkaW8uJykKICAgIG1ldGEgPSBbXQogICAgaWYg
:::ZW1iZWJlcjoKICAgICAgICBhcnRpc3RhID0gKGluZm8uZ2V0KCdhcnRpc3QnKSBv
:::ciBpbmZvLmdldCgndXBsb2FkZXInKQogICAgICAgICAgICAgICAgICAgb3IgaW5m
:::by5nZXQoJ2NoYW5uZWwnKSBvciAnJykKICAgICAgICBpZiBpbmZvLmdldCgndGl0
:::bGUnKToKICAgICAgICAgICAgbWV0YSArPSBbJy1tZXRhZGF0YScsICd0aXRsZT0n
:::ICsgc3RyKGluZm9bJ3RpdGxlJ10pXQogICAgICAgIGlmIGFydGlzdGE6CiAgICAg
:::ICAgICAgIG1ldGEgKz0gWyctbWV0YWRhdGEnLCAnYXJ0aXN0PScgKyBzdHIoYXJ0
:::aXN0YSldCiAgICB3bWEgPSBjYXJwZXRhIC8gKGxpbXBpYXJfbm9tYnJlKGluZm8u
:::Z2V0KCd0aXRsZScpIG9yICdhdWRpbycpICsgJy53bWEnKQogICAgY21kID0gW3N0
:::cihGRk1QRUcpLCAnLXknLCAnLWknLCBzdHIod2F2KSwgJy12bicsCiAgICAgICAg
:::ICAgJy1jOmEnLCAnd21hdjInLCAnLWI6YScsIGYne2NhbGlkYWR9ayddICsgbWV0
:::YSArIFtzdHIod21hKV0KICAgIG9rID0gY29udmVydGlyX2ZmbXBlZygKICAgICAg
:::ICBjbWQsIGYnQ29udmlydGllbmRvIGEgV01BICh3bWF2MiDCtyB7Y2FsaWRhZH0g
:::a2JwcyknLCBjb2xhKQogICAgaWYgbm90IG9rOgogICAgICAgIHJhaXNlIFJ1bnRp
:::bWVFcnJvcignRkZtcGVnIG5vIHB1ZG8gY3JlYXIgZWwgYXJjaGl2byBXTUEuJykK
:::ICAgIGNhcmF0dWxhID0gTm9uZQogICAgaWYgZW1iZWJlcjoKICAgICAgICBqcGdz
:::ID0gc29ydGVkKHRtcC5nbG9iKCcqLmpwZycpLAogICAgICAgICAgICAgICAgICAg
:::ICAga2V5PWxhbWJkYSBxOiBxLnN0YXQoKS5zdF9tdGltZSwgcmV2ZXJzZT1UcnVl
:::KQogICAgICAgIGlmIGpwZ3M6CiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAg
:::ICAgIGNhcmF0dWxhID0ganBnc1swXS5yZWFkX2J5dGVzKCkKICAgICAgICAgICAg
:::ZXhjZXB0IE9TRXJyb3I6CiAgICAgICAgICAgICAgICBjYXJhdHVsYSA9IE5vbmUK
:::ICAgIGFwbGljYXJfdGFncyhpbmZvLCB3bWEsIGxvZywgY2FyYXR1bGEpCiAgICBz
:::aHV0aWwucm10cmVlKHRtcCwgaWdub3JlX2Vycm9ycz1UcnVlKQogICAgcmV0dXJu
:::IGluZm8sIHdtYQoKCiMgUGFyw6FtZXRyb3Mgb2ZpY2lhbGVzIGRlbCByZXBvIGZk
:::ZDRzL3BvcnRhYmxlX21wM19wbGF5ZXJfdmlkZW9fY29udmVydGVyX3Rvb2xzCiMg
:::KHZpZGVvMnNoZW5qdTE4LnNoKTogTUpQRUcgMTYgZnBzICsgUENNIDIyMDUwIEh6
:::LCByb3RhZG9zIHBhcmEgbGEgcGFudGFsbGEKIyB2ZXJ0aWNhbCBkZSAxMjh4MTYw
:::IGRlbCByZXByb2R1Y3RvciBzaGVpanUgZGUgMS44IHB1bGdhZGFzLgpWRl9TSEVJ
:::SlUgPSAnc2NhbGU9LTI6MTI4LCBjcm9wPTE2MDoxMjgsIHRyYW5zcG9zZT0yLCB2
:::ZmxpcCcKIyBWYXJpYW50ZSBhIHBydWViYSBkZSBiYWxhcyBwYXJhIHZpZGVvcyBj
:::dWFkcmFkb3MvdmVydGljYWxlcyAoU2hvcnRzKSwKIyBkb25kZSBlbCByZWNvcnRl
:::IDE2MDoxMjggb3JpZ2luYWwgc2Vyw61hIGltcG9zaWJsZToKVkZfU0VHVVJPID0g
:::KCdzY2FsZT0xNjA6MTI4OmZvcmNlX29yaWdpbmFsX2FzcGVjdF9yYXRpbz1kZWNy
:::ZWFzZSwnCiAgICAgICAgICAgICAncGFkPTE2MDoxMjg6KG93LWl3KS8yOihvaC1p
:::aCkvMix0cmFuc3Bvc2U9Mix2ZmxpcCcpCgoKZGVmIGRlc2Nhcmdhcl9hdmkodXJs
:::LCBkZXN0aW5vLCBjb2xhKToKICAgICIiIlZpZGVvIEFWSSBwYXJhIGVsIHJlcHJv
:::ZHVjdG9yIHNoZWlqdSAxLjgiIDEyOHgxNjAuIiIiCiAgICBkZWYgbG9nKG0sIHQ9
:::J2luZm8nKToKICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgIGNh
:::cnBldGEgPSBkZXN0aW5vICAgICAgICAgICMgdjIuMzogc2luIHN1YmNhcnBldGFz
:::IHBvciBmb3JtYXRvCiAgICB0bXAgPSBjYXJwZXRhIC8gJ190bXAnCiAgICBzaHV0
:::aWwucm10cmVlKHRtcCwgaWdub3JlX2Vycm9ycz1UcnVlKQogICAgdG1wLm1rZGly
:::KHBhcmVudHM9VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgIG8gPSBvcHRzX2Jhc2Uo
:::dG1wLCBjb2xhKQogICAgIyBQYXJhIHVuYSBwYW50YWxsYSBkZSAxMjh4MTYwIGJh
:::c3RhIGNvbiA0ODBwOiBhaG9ycmEgbXVjaGEgZGVzY2FyZ2EuCiAgICBvWydmb3Jt
:::YXQnXSA9ICgnYmVzdFtoZWlnaHQ8PTQ4MF1bZXh0PW1wNF0vYmVzdFtoZWlnaHQ8
:::PTQ4MF0vJwogICAgICAgICAgICAgICAgICAgJ2J2KltoZWlnaHQ8PTQ4MF0rYmEv
:::YicpCiAgICBvWydtZXJnZV9vdXRwdXRfZm9ybWF0J10gPSAnbXA0JwogICAgd2l0
:::aCBZVF9ETFAuWW91dHViZURMKG8pIGFzIHlkbDoKICAgICAgICBpbmZvID0geWRs
:::LmV4dHJhY3RfaW5mbyh1cmwsIGRvd25sb2FkPVRydWUpCiAgICBvcmlnZW4gPSBh
:::cmNoaXZvX2ZpbmFsKGluZm8sIHRtcCwgJ21wNCcpCiAgICBpZiBub3Qgb3JpZ2Vu
:::OgogICAgICAgIG9yaWdlbiA9IChhcmNoaXZvX2ZpbmFsKGluZm8sIHRtcCwgJ21r
:::dicpCiAgICAgICAgICAgICAgICAgIG9yIGFyY2hpdm9fZmluYWwoaW5mbywgdG1w
:::LCAnd2VibScpKQogICAgaWYgbm90IG9yaWdlbjoKICAgICAgICByYWlzZSBSdW50
:::aW1lRXJyb3IoJ05vIHNlIGVuY29udHLDsyBlbCB2aWRlbyBkZXNjYXJnYWRvLicp
:::CiAgICBhdmkgPSBjYXJwZXRhIC8gKGxpbXBpYXJfbm9tYnJlKGluZm8uZ2V0KCd0
:::aXRsZScpIG9yICd2aWRlbycpICsgJy5hdmknKQogICAgYmFzZSA9IFtzdHIoRkZN
:::UEVHKSwgJy15JywgJy1pJywgc3RyKG9yaWdlbiksICctcicsICcxNicsCiAgICAg
:::ICAgICAgICctYWNvZGVjJywgJ3BjbV9zMTZsZScsICctYWMnLCAnMicsICctYXIn
:::LCAnMjIwNTAnLAogICAgICAgICAgICAnLXBpeF9mbXQnLCAneXV2ajQyMHAnLCAn
:::LWM6dicsICdtanBlZycsICctcTp2JywgJzInXQogICAgb2sgPSBjb252ZXJ0aXJf
:::ZmZtcGVnKGJhc2UgKyBbJy12ZicsIFZGX1NIRUlKVSwgc3RyKGF2aSldLAogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICdDb252aXJ0aWVuZG8gYSBBVkkgMTI4eDE2
:::MCAoc2hlaWp1IDEuOCIpJywgY29sYSkKICAgIGlmIG5vdCBvazoKICAgICAgICBs
:::b2coJ1ZpZGVvIGNvbiBwcm9wb3JjacOzbiBubyBlc3TDoW5kYXI7ICcKICAgICAg
:::ICAgICAgJ3JlaW50ZW50YW5kbyBlbiBtb2RvIGNvbXBhdGlibGUuLi4nLCAnYXZp
:::c28nKQogICAgICAgIG9rID0gY29udmVydGlyX2ZmbXBlZyhiYXNlICsgWyctdmYn
:::LCBWRl9TRUdVUk8sIHN0cihhdmkpXSwKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgJ1JlY29udmlydGllbmRvIGEgQVZJIDEyOHgxNjAnLCBjb2xhKQogICAg
:::aWYgbm90IG9rOgogICAgICAgIHJhaXNlIFJ1bnRpbWVFcnJvcignRkZtcGVnIG5v
:::IHB1ZG8gY3JlYXIgZWwgYXJjaGl2byBBVkkuJykKICAgIHNodXRpbC5ybXRyZWUo
:::dG1wLCBpZ25vcmVfZXJyb3JzPVRydWUpCiAgICByZXR1cm4gaW5mbywgYXZpCgoK
:::IyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tIGVzdGltYWNpw7NuCktCUFNfRVNUSU1BRE9TID0g
:::ewogICAgJ0FBQyc6IDEyOCwgICAgICMgdGVjaG8gZGVsIGZvcm1hdG8KICAgICdX
:::TUEnOiAxMjgsCiAgICAnV0FWJzogMTQxMSwgICAgIyBQQ00gNDQuMSBrSHogwrcg
:::MTYgYml0IMK3IGVzdMOpcmVvCiAgICAnRkxBQyc6IDk1MCwgICAgIyB0w61waWNv
:::IGRlIG3DunNpY2EgcHJvY2VkZW50ZSBkZSBZb3VUdWJlCiAgICAnQVZJJzogMTQ5
:::MCwgICAgIyB+Nzg0IGticHMgTUpQRUcgMTZmcHMgKyA3MDYga2JwcyBQQ00gMjIw
:::NTAgZXN0w6lyZW8KfQoKCmRlZiBlc3RpbWFyX2J5dGVzKGR1cmFjaW9uX3MsIGZv
:::cm1hdG8sIGNhbGlkYWQsIGVtYmViZXIpOgogICAgIiIiRXN0aW1hIGVsIHRhbWHD
:::sW8gZmluYWwgZW4gYnl0ZXMgKGPDoWxjdWxvIHB1cm8sIHRlc3RlYWJsZSkuIiIi
:::CiAgICBpZiBmb3JtYXRvIGluICgnTVAzJywgJ0FBQycsICdXTUEnKToKICAgICAg
:::ICBrYnBzID0gaW50KHJlLnN1YihyJ1teMC05XScsICcnLCBzdHIoY2FsaWRhZCkp
:::IG9yIDApCiAgICAgICAgaWYgbm90IGticHM6CiAgICAgICAgICAgIGticHMgPSBL
:::QlBTX0VTVElNQURPUy5nZXQoZm9ybWF0bywgMTI4KQogICAgZWxzZToKICAgICAg
:::ICBrYnBzID0gS0JQU19FU1RJTUFET1MuZ2V0KGZvcm1hdG8sIDEyOCkKICAgIGV4
:::dHJhID0gMTIwXzAwMCBpZiAoZW1iZWJlciBhbmQgZm9ybWF0byBpbiAoJ0FBQycs
:::ICdNUDMnLCAnRkxBQycpKSBlbHNlIDAKICAgIHJldHVybiBkdXJhY2lvbl9zICog
:::a2JwcyAqIDEwMDAgLyA4ICsgZXh0cmEKCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gY2Fs
:::aWRhZApkZWYgY2xhc2VfY2FsaWRhZChleHQsIGticHMpOgogICAgIiIiQ2xhc2lm
:::aWNhIHVuIGFyY2hpdm8uIERldnVlbHZlICh0ZXh0bywgbml2ZWwpIGNvbiBuaXZl
:::bCAwPW9rIDE9bWVkaWEgMj1iYWphLiIiIgogICAgaWYgZXh0ID09ICcubXAzJzoK
:::ICAgICAgICBpZiBrYnBzID49IDMxNToKICAgICAgICAgICAgcmV0dXJuICczMjAg
:::a2JwcycsIDAKICAgICAgICBpZiBrYnBzID49IDI1MDoKICAgICAgICAgICAgcmV0
:::dXJuICcyNTYga2JwcycsIDAKICAgICAgICBpZiBrYnBzID49IDE4NToKICAgICAg
:::ICAgICAgcmV0dXJuICcxOTIga2JwcycsIDAKICAgICAgICBpZiBrYnBzID49IDEy
:::MDoKICAgICAgICAgICAgcmV0dXJuICcxMjgga2JwcycsIDEKICAgICAgICByZXR1
:::cm4gZid7a2Jwc30ga2JwcyAoYmFqYSknLCAyCiAgICBpZiBleHQgPT0gJy5tNGEn
:::OgogICAgICAgIGlmIGticHMgPj0gMTE1OgogICAgICAgICAgICByZXR1cm4gJ0V4
:::Y2VsZW50ZSAoQUFDIOKJpDEyOGspJywgMAogICAgICAgIGlmIGticHMgPj0gODI6
:::CiAgICAgICAgICAgIHJldHVybiAnOTYga2JwcycsIDEKICAgICAgICByZXR1cm4g
:::Zid7a2Jwc30ga2JwcyAoYmFqYSknLCAyCiAgICBpZiBleHQgPT0gJy53bWEnOgog
:::ICAgICAgIGlmIGticHMgPj0gMTE1OgogICAgICAgICAgICByZXR1cm4gJzEyOCBr
:::YnBzJywgMAogICAgICAgIGlmIGticHMgPj0gODg6CiAgICAgICAgICAgIHJldHVy
:::biAnOTYga2JwcycsIDEKICAgICAgICByZXR1cm4gZid7a2Jwc30ga2JwcyAoYmFq
:::YSknLCAyCiAgICBpZiBleHQgaW4gKCcuZmxhYycsICcud2F2Jyk6CiAgICAgICAg
:::cmV0dXJuICdTaW4gcMOpcmRpZGEnLCAwCiAgICBpZiBleHQgPT0gJy5hdmknOgog
:::ICAgICAgIGlmIGticHMgPj0gMTIwMDoKICAgICAgICAgICAgcmV0dXJuIGYne2ti
:::cHN9IGticHMgKE1KUEVHK1BDTSAxMjh4MTYwKScsIDAKICAgICAgICByZXR1cm4g
:::Zid7a2Jwc30ga2JwcyAoYWxnbyBiYWpvKScsIDEKICAgIHJldHVybiBmJ3trYnBz
:::fSBrYnBzJywgMQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSB0ZW1hcwpURU1BUyA9IHsK
:::ICAgICdPc2N1cm8nOiBkaWN0KAogICAgICAgIGZvbmRvPScjMWUxZjIyJywgY2Ft
:::cG89JyMyYTJkMzEnLCBjYW1wb19ib3JkZT0nIzNhM2U0NCcsCiAgICAgICAgdGV4
:::dG89JyNkOGRhZGMnLCB0ZXh0bzI9JyM5YTlmYTQnLAogICAgICAgIGJvdG9uPScj
:::M2EzZDQyJywgYm90b25fYWN0PScjNGE0ZTU1JywgYm90b25fdHh0PScjZThlYWVj
:::JywKICAgICAgICBsb2c9JyMxNDE1MTgnLCBsb2dfdHh0PScjY2ZkM2Q3JywgYWNl
:::bnRvPScjNGY5Y2Y5JywKICAgICAgICBvaz0nIzdlYzk3ZicsIGVycm9yPScjZTU3
:::MzczJywgYXZpc289JyNkOGI2NGEnLCB0cm91Z2g9JyMyNjI4MmMnLAogICAgICAg
:::IHBsYWNlaG9sZGVyPScjNzc3YzgyJyksCiAgICAnQ2xhcm8nOiBkaWN0KAogICAg
:::ICAgIGZvbmRvPScjZjJmM2Y1JywgY2FtcG89JyNmZmZmZmYnLCBjYW1wb19ib3Jk
:::ZT0nI2M0YzhjZCcsCiAgICAgICAgdGV4dG89JyMyNDI3MmEnLCB0ZXh0bzI9JyM2
:::YTcwNzYnLAogICAgICAgIGJvdG9uPScjZTNlNWU4JywgYm90b25fYWN0PScjZDJk
:::NWRhJywgYm90b25fdHh0PScjMjQyNzJhJywKICAgICAgICBsb2c9JyNmZmZmZmYn
:::LCBsb2dfdHh0PScjMmIyZTMxJywgYWNlbnRvPScjMWE2NmQ2JywKICAgICAgICBv
:::az0nIzFlN2UzNCcsIGVycm9yPScjYzYyODI4JywgYXZpc289JyM5YTY3MDAnLCB0
:::cm91Z2g9JyNkZmUxZTQnLAogICAgICAgIHBsYWNlaG9sZGVyPScjOWFhMGE2Jyks
:::Cn0KClBMQUNFSE9MREVSX1VSTCA9ICdodHRwczovL3d3dy55b3V0dWJlLmNvbS93
:::YXRjaD92PS4uLicKCkZVRU5URV9VSSA9ICgnU2Vnb2UgVUknLCA5KQpGVUVOVEVf
:::QlROID0gKCdTZWdvZSBVSScsIDEwKQpGVUVOVEVfQlROX0cgPSAoJ1NlZ29lIFVJ
:::JywgMTEpCkZVRU5URV9MT0cgPSAoJ0NvbnNvbGFzJywgMTApCgoKaWYgVEtfT0s6
:::CgogICAgY2xhc3MgQXBwKHRrLlRrKToKICAgICAgICAiIiJWZW50YW5hIHByaW5j
:::aXBhbCAoZGlzZcOxbyBlc3Blam8gZGVsIG1vY2t1cDogZ3J1cG9zIG9zY3Vyb3Mp
:::LiIiIgoKICAgICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLSBjb25zdHJ1Y2Npw7NuCiAgICAgICAgZGVmIF9faW5p
:::dF9fKHNlbGYpOgogICAgICAgICAgICBpZiBnZXRhdHRyKHN5cywgJ2Zyb3plbics
:::IEZhbHNlKToKICAgICAgICAgICAgICAgIHBhc3MKICAgICAgICAgICAgc3VwZXIo
:::KS5fX2luaXRfXygpCiAgICAgICAgICAgIHNlbGYudGl0bGUoJ011c2lrQUxBTicp
:::CiAgICAgICAgICAgIHNlbGYuZ2VvbWV0cnkoJzg2MHg4NDAnKQogICAgICAgICAg
:::ICBzZWxmLm1pbnNpemUoNzAwLCA2NjApCiAgICAgICAgICAgIHNlbGYuY29sYSA9
:::IHF1ZXVlLlF1ZXVlKCkKICAgICAgICAgICAgc2VsZi5fb2N1cGFkbyA9IEZhbHNl
:::CiAgICAgICAgICAgIHNlbGYuX2VuX3BsYWNlaG9sZGVyID0gVHJ1ZQogICAgICAg
:::ICAgICBzZWxmLl90ZW1hX2FjdHVhbCA9IEFKVVNURVMuZ2V0KCd0ZW1hJywgJ09z
:::Y3VybycpCiAgICAgICAgICAgIGlmIHNlbGYuX3RlbWFfYWN0dWFsIG5vdCBpbiBU
:::RU1BUzoKICAgICAgICAgICAgICAgIHNlbGYuX3RlbWFfYWN0dWFsID0gJ09zY3Vy
:::bycKCiAgICAgICAgICAgIHNlbGYuX2VzdGlsbyA9IHR0ay5TdHlsZShzZWxmKQog
:::ICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBzZWxmLl9lc3RpbG8udGhl
:::bWVfdXNlKCdjbGFtJykKICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAg
:::ICAgICAgICAgICAgIHBhc3MKCiAgICAgICAgICAgIHNlbGYuX2NvbnN0cnVpcigp
:::CiAgICAgICAgICAgIHNlbGYuX2FwbGljYXJfdGVtYSgpCiAgICAgICAgICAgIHNl
:::bGYuX2NvbmVjdGFyX2V2ZW50b3MoKQogICAgICAgICAgICBSRUdJU1RSTy5sb2cg
:::PSBsYW1iZGEgbSwgdD0nYXZpc28nOiBzZWxmLmNvbGEucHV0KCgnbG9nJywgbSwg
:::dCkpCiAgICAgICAgICAgIHNlbGYuYWZ0ZXIoODAsIHNlbGYuX2JvbWJlYXJfY29s
:::YSkKICAgICAgICAgICAgc2VsZi5hZnRlcigxNTAsIHNlbGYuX2FycmFucXVlKQoK
:::ICAgICAgICBkZWYgX2NvbnN0cnVpcihzZWxmKToKICAgICAgICAgICAgc2VsZi5f
:::d2cgPSB7fSAgICAgICAgICMgcmVmZXJlbmNpYXMgcGFyYSBlbCB0ZW1hCiAgICAg
:::ICAgICAgIHNlbGYuX2J0bnMgPSBbXSAgICAgICAjIGJvdG9uZXMgcGxhbm9zIChw
:::YXJhIGhvdmVyL3RlbWEpCiAgICAgICAgICAgIG1hcmNvID0gdGsuRnJhbWUoc2Vs
:::ZikKICAgICAgICAgICAgbWFyY28ucGFjayhmaWxsPSdib3RoJywgZXhwYW5kPVRy
:::dWUsIHBhZHg9MTAsIHBhZHk9OCkKICAgICAgICAgICAgc2VsZi5fd2dbJ21hcmNv
:::J10gPSBtYXJjbwogICAgICAgICAgICBtYXJjby5jb2x1bW5jb25maWd1cmUoMCwg
:::d2VpZ2h0PTEpCgogICAgICAgICAgICAjIC0tLSBmaWxhIFRlbWEgLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAg
:::ICAgIGYwID0gdGsuRnJhbWUobWFyY28pCiAgICAgICAgICAgIGYwLmdyaWQocm93
:::PTAsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgcGFkeT0oMCwgNikpCiAgICAgICAg
:::ICAgIHNlbGYuX3dnWydmMCddID0gZjAKICAgICAgICAgICAgc2VsZi5fd2dbJ2xi
:::bF90ZW1hJ10gPSB0ay5MYWJlbChmMCwgdGV4dD0nVGVtYTonLCBmb250PUZVRU5U
:::RV9VSSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF90ZW1hJ10ucGFjayhzaWRl
:::PSdsZWZ0JykKICAgICAgICAgICAgc2VsZi5jbWJfdGVtYSA9IHR0ay5Db21ib2Jv
:::eCgKICAgICAgICAgICAgICAgIGYwLCB2YWx1ZXM9bGlzdChURU1BUyksIHN0YXRl
:::PSdyZWFkb25seScsIHdpZHRoPTksCiAgICAgICAgICAgICAgICBmb250PUZVRU5U
:::RV9VSSwgc3R5bGU9J2d4LlRDb21ib2JveCcpCiAgICAgICAgICAgIHNlbGYuY21i
:::X3RlbWEuc2V0KHNlbGYuX3RlbWFfYWN0dWFsKQogICAgICAgICAgICBzZWxmLmNt
:::Yl90ZW1hLnBhY2soc2lkZT0nbGVmdCcsIHBhZHg9KDgsIDApLCBpcGFkeT0yKQoK
:::ICAgICAgICAgICAgIyAtLS0gZ3J1cG86IFVSTCBkZSBZb3VUdWJlIC0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAgICAgICBndSA9IHRr
:::LkxhYmVsRnJhbWUobWFyY28sIHRleHQ9J1VSTCBkZSBZb3VUdWJlJywgZm9udD1G
:::VUVOVEVfVUksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWxpZWY9
:::J3NvbGlkJywgYmQ9MSkKICAgICAgICAgICAgZ3UuZ3JpZChyb3c9MSwgY29sdW1u
:::PTAsIHN0aWNreT0nZXcnLCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYuX3dnWydn
:::dSddID0gZ3UKICAgICAgICAgICAgZ3UuY29sdW1uY29uZmlndXJlKDAsIHdlaWdo
:::dD0xKQogICAgICAgICAgICBzZWxmLmVudF91cmwgPSB0ay5FbnRyeShndSwgZm9u
:::dD1GVUVOVEVfVUksIHJlbGllZj0nZmxhdCcsCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgIGhpZ2hsaWdodHRoaWNrbmVzcz0xKQogICAgICAgICAg
:::ICBzZWxmLmVudF91cmwuZ3JpZChyb3c9MCwgY29sdW1uPTAsIHN0aWNreT0nZXcn
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4PTgsIHBhZHk9OCwg
:::aXBhZHk9NSkKICAgICAgICAgICAgc2VsZi5fcG9uZXJfcGxhY2Vob2xkZXIoKQog
:::ICAgICAgICAgICBzZWxmLmJ0bl94ID0gc2VsZi5fYm90b24oZ3UsICdYJywgc2Vs
:::Zi5fbGltcGlhcl91cmwsIHdpZHRoPTMpCiAgICAgICAgICAgIHNlbGYuYnRuX3gu
:::Z3JpZChyb3c9MCwgY29sdW1uPTEsIHN0aWNreT0nZScsIHBhZHg9KDAsIDgpLCBp
:::cGFkeT0zKQoKICAgICAgICAgICAgIyAtLS0gZ3J1cG86IEZvcm1hdG8geSBjYWxp
:::ZGFkIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAgICAg
:::ICBnZiA9IHRrLkxhYmVsRnJhbWUobWFyY28sIHRleHQ9J0Zvcm1hdG8geSBjYWxp
:::ZGFkJywgZm9udD1GVUVOVEVfVUksCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICByZWxpZWY9J3NvbGlkJywgYmQ9MSkKICAgICAgICAgICAgZ2YuZ3JpZChy
:::b3c9MiwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PTUpCiAgICAgICAgICAg
:::IHNlbGYuX3dnWydnZiddID0gZ2YKICAgICAgICAgICAgZ2YuY29sdW1uY29uZmln
:::dXJlKDEsIHdlaWdodD0xKQogICAgICAgICAgICBzZWxmLl93Z1snbGJsX2ZtdCdd
:::ID0gdGsuTGFiZWwoZ2YsIHRleHQ9J0Zvcm1hdG86JywgZm9udD1GVUVOVEVfVUkp
:::CiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfZm10J10uZ3JpZChyb3c9MCwgY29s
:::dW1uPTAsIHN0aWNreT0ndycsIHBhZHg9OCwgcGFkeT01KQogICAgICAgICAgICBz
:::ZWxmLmNtYl9mb3JtYXRvID0gdHRrLkNvbWJvYm94KAogICAgICAgICAgICAgICAg
:::Z2YsIHZhbHVlcz1bZlsndGV4dG8nXSBmb3IgZiBpbiBGT1JNQVRPUy52YWx1ZXMo
:::KV0sCiAgICAgICAgICAgICAgICBzdGF0ZT0ncmVhZG9ubHknLCBmb250PUZVRU5U
:::RV9VSSwgc3R5bGU9J2d4LlRDb21ib2JveCcpCiAgICAgICAgICAgIHNlbGYuY21i
:::X2Zvcm1hdG8uZ3JpZChyb3c9MCwgY29sdW1uPTEsIHN0aWNreT0nZXcnLAogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFkeD04LCBwYWR5PTUsIGlw
:::YWR5PTIpCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfY2FsJ10gPSB0ay5MYWJl
:::bChnZiwgdGV4dD0nQ2FsaWRhZDonLCBmb250PUZVRU5URV9VSSkKICAgICAgICAg
:::ICAgc2VsZi5fd2dbJ2xibF9jYWwnXS5ncmlkKHJvdz0xLCBjb2x1bW49MCwgc3Rp
:::Y2t5PSd3JywgcGFkeD04LCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYuY21iX2Nh
:::bGlkYWQgPSB0dGsuQ29tYm9ib3goCiAgICAgICAgICAgICAgICBnZiwgc3RhdGU9
:::J3JlYWRvbmx5JywgZm9udD1GVUVOVEVfVUksIHN0eWxlPSdneC5UQ29tYm9ib3gn
:::KQogICAgICAgICAgICBzZWxmLmNtYl9jYWxpZGFkLmdyaWQocm93PTEsIGNvbHVt
:::bj0xLCBzdGlja3k9J2V3JywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIHBhZHg9OCwgcGFkeT01LCBpcGFkeT0yKQogICAgICAgICAgICBzZWxmLl93
:::Z1snbGJsX2NhciddID0gdGsuTGFiZWwoZ2YsIHRleHQ9J0NhcnBldGE6JywgZm9u
:::dD1GVUVOVEVfVUkpCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfY2FyJ10uZ3Jp
:::ZChyb3c9MiwgY29sdW1uPTAsIHN0aWNreT0ndycsIHBhZHg9OCwgcGFkeT01KQog
:::ICAgICAgICAgICBmYyA9IHRrLkZyYW1lKGdmKQogICAgICAgICAgICBmYy5ncmlk
:::KHJvdz0yLCBjb2x1bW49MSwgc3RpY2t5PSdldycsIHBhZHg9OCwgcGFkeT01KQog
:::ICAgICAgICAgICBzZWxmLl93Z1snZmMnXSA9IGZjCiAgICAgICAgICAgIGZjLmNv
:::bHVtbmNvbmZpZ3VyZSgwLCB3ZWlnaHQ9MSkKICAgICAgICAgICAgc2VsZi5lbnRf
:::Y2FycGV0YSA9IHRrLkVudHJ5KGZjLCBmb250PUZVRU5URV9VSSwgcmVsaWVmPSdm
:::bGF0JywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGhp
:::Z2hsaWdodHRoaWNrbmVzcz0xKQogICAgICAgICAgICBzZWxmLmVudF9jYXJwZXRh
:::LmdyaWQocm93PTAsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgaXBhZHk9NCkKICAg
:::ICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5pbnNlcnQoMCwgQUpVU1RFU1snZGVz
:::dGlubyddKQogICAgICAgICAgICBzZWxmLmJ0bl9jYW1iaWFyID0gc2VsZi5fYm90
:::b24oZmMsICdDYW1iaWFyLi4uJywgc2VsZi5fY2FtYmlhcl9jYXJwZXRhKQogICAg
:::ICAgICAgICBzZWxmLmJ0bl9jYW1iaWFyLmdyaWQocm93PTAsIGNvbHVtbj0xLCBw
:::YWR4PSg4LCAwKSwgaXBhZHk9MykKICAgICAgICAgICAgc2VsZi5idG5fYWJyaXIg
:::PSBzZWxmLl9ib3RvbihmYywgJ0FicmlyJywgc2VsZi5fYWJyaXJfZGVzdGlubywg
:::d2lkdGg9NSkKICAgICAgICAgICAgc2VsZi5idG5fYWJyaXIuZ3JpZChyb3c9MCwg
:::Y29sdW1uPTIsIHBhZHg9KDYsIDApLCBpcGFkeT0zKQoKICAgICAgICAgICAgc2Vs
:::Zi52YXJfZW1iZWJlciA9IHRrLkJvb2xlYW5WYXIodmFsdWU9Ym9vbChBSlVTVEVT
:::LmdldCgnZW1iZWJlcicsIFRydWUpKSkKICAgICAgICAgICAgc2VsZi5jaGtfZW1i
:::ZWJlciA9IHRrLkNoZWNrYnV0dG9uKAogICAgICAgICAgICAgICAgZ2YsIHRleHQ9
:::J0VtYmViZXIgY2Fyw6F0dWxhLCBhcnRpc3RhIHkgw6FsYnVtJywKICAgICAgICAg
:::ICAgICAgIHZhcmlhYmxlPXNlbGYudmFyX2VtYmViZXIsIGZvbnQ9RlVFTlRFX1VJ
:::LCBhbmNob3I9J3cnLAogICAgICAgICAgICAgICAgcmVsaWVmPSdmbGF0JywgaGln
:::aGxpZ2h0dGhpY2tuZXNzPTAsIGJkPTApCiAgICAgICAgICAgIHNlbGYuY2hrX2Vt
:::YmViZXIuZ3JpZChyb3c9MywgY29sdW1uPTAsIGNvbHVtbnNwYW49MiwKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0aWNreT0nZXcnLCBwYWR4PTgs
:::IHBhZHk9KDIsIDYpKQoKICAgICAgICAgICAgIyAtLS0gZ3J1cG86IGVzdGltYWNp
:::w7NuIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KICAg
:::ICAgICAgICAgZ2UgPSB0ay5MYWJlbEZyYW1lKG1hcmNvLCB0ZXh0PSdFc3RpbWFj
:::acOzbicsIGZvbnQ9RlVFTlRFX1VJLAogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgcmVsaWVmPSdzb2xpZCcsIGJkPTEpCiAgICAgICAgICAgIGdlLmdyaWQo
:::cm93PTMsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgcGFkeT01KQogICAgICAgICAg
:::ICBzZWxmLl93Z1snZ2UnXSA9IGdlCiAgICAgICAgICAgIGdlLmNvbHVtbmNvbmZp
:::Z3VyZSgwLCB3ZWlnaHQ9MSkKICAgICAgICAgICAgc2VsZi5sYmxfZXN0aW1hY2lv
:::biA9IHRrLkxhYmVsKAogICAgICAgICAgICAgICAgZ2UsIHRleHQ9J0ludHJvZHVj
:::ZSB1bmEgVVJMIHkgcHVsc2EgRXN0aW1hci4nLAogICAgICAgICAgICAgICAgZm9u
:::dD1GVUVOVEVfVUksIGFuY2hvcj0ndycpCiAgICAgICAgICAgIHNlbGYubGJsX2Vz
:::dGltYWNpb24uZ3JpZChyb3c9MCwgY29sdW1uPTAsIHN0aWNreT0nZXcnLAogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFkeD04LCBwYWR5PTYp
:::CiAgICAgICAgICAgIHNlbGYuYnRuX2VzdGltYXIgPSBzZWxmLl9ib3RvbihnZSwg
:::J0VzdGltYXIgdGFtYW5vJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIHNlbGYuX2FjY2lvbl9lc3RpbWFyKQogICAgICAgICAgICBz
:::ZWxmLmJ0bl9lc3RpbWFyLmdyaWQocm93PTAsIGNvbHVtbj0xLCBzdGlja3k9J2Un
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFkeD04LCBpcGFk
:::eT0zKQoKICAgICAgICAgICAgIyAtLS0gYm90b25lcyBncmFuZGVzIC0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAgICAgICBz
:::ZWxmLmJ0bl9kZXNjYXJnYXIgPSBzZWxmLl9ib3RvbihtYXJjbywgJ0Rlc2Nhcmdh
:::ciB5IGNvbnZlcnRpcicsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIHNlbGYuX2FjY2lvbl9kZXNjYXJnYXIsCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGZ1ZW50ZT1GVUVOVEVf
:::QlROX0csIGFsdG89MikKICAgICAgICAgICAgc2VsZi5idG5fZGVzY2FyZ2FyLmdy
:::aWQocm93PTQsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgcGFkeT0oNywgNCkpCiAg
:::ICAgICAgICAgIHNlbGYuYnRuX2NvbXByb2JhciA9IHNlbGYuX2JvdG9uKAogICAg
:::ICAgICAgICAgICAgbWFyY28sICdDb21wcm9iYXIgY2FsaWRhZCBkZSBsYSBjYXJw
:::ZXRhJywKICAgICAgICAgICAgICAgIHNlbGYuX2FjY2lvbl9jb21wcm9iYXIsIGZ1
:::ZW50ZT1GVUVOVEVfQlROKQogICAgICAgICAgICBzZWxmLmJ0bl9jb21wcm9iYXIu
:::Z3JpZChyb3c9NSwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PTMpCgogICAg
:::ICAgICAgICAjIC0tLSBlc3RhZG8gKyBiYXJyYSBkZSBwcm9ncmVzbyAtLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAgICAgICBzZWxmLmxibF9l
:::c3RhZG8gPSB0ay5MYWJlbChtYXJjbywgdGV4dD0nJywgZm9udD1GVUVOVEVfVUks
:::CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGFuY2hvcj0n
:::dycpCiAgICAgICAgICAgIHNlbGYubGJsX2VzdGFkby5ncmlkKHJvdz02LCBjb2x1
:::bW49MCwgc3RpY2t5PSdldycsIHBhZHk9KDQsIDApKQogICAgICAgICAgICBzZWxm
:::LmJhcnJhID0gdHRrLlByb2dyZXNzYmFyKAogICAgICAgICAgICAgICAgbWFyY28s
:::IG1heGltdW09MTAwLCBzdHlsZT0nZ3guSG9yaXpvbnRhbC5UUHJvZ3Jlc3NiYXIn
:::KQogICAgICAgICAgICBzZWxmLmJhcnJhLmdyaWQocm93PTcsIGNvbHVtbj0wLCBz
:::dGlja3k9J2V3JywgcGFkeT0oMiwgNCkpCgogICAgICAgICAgICAjIC0tLSByZWdp
:::c3RybyAobG9nKSAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLQogICAgICAgICAgICBzZWxmLnR4dF9sb2cgPSBTY3JvbGxlZFRleHQo
:::bWFyY28sIGZvbnQ9RlVFTlRFX0xPRywgaGVpZ2h0PTEyLAogICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVsaWVmPSdmbGF0JywgYmQ9MCwg
:::d3JhcD0nd29yZCcsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICBzdGF0ZT0nZGlzYWJsZWQnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cu
:::Z3JpZChyb3c9OCwgY29sdW1uPTAsIHN0aWNreT0nbnNldycpCiAgICAgICAgICAg
:::IG1hcmNvLnJvd2NvbmZpZ3VyZSg4LCB3ZWlnaHQ9MSkKICAgICAgICAgICAgZm9y
:::IHRhZywgY29uZiBpbiAoCiAgICAgICAgICAgICAgICAgICAgKCdpbmZvJywge30p
:::LAogICAgICAgICAgICAgICAgICAgICgnZ3JpcycsIHt9KSwKICAgICAgICAgICAg
:::ICAgICAgICAoJ3RpdHVsbycsIHt9KSwKICAgICAgICAgICAgICAgICAgICAoJ29r
:::Jywge30pLAogICAgICAgICAgICAgICAgICAgICgnYXZpc28nLCB7fSksCiAgICAg
:::ICAgICAgICAgICAgICAgKCdlcnJvcicsIHt9KSk6CiAgICAgICAgICAgICAgICBz
:::ZWxmLnR4dF9sb2cudGFnX2NvbmZpZ3VyZSh0YWcsIGNvbmYpCgogICAgICAgICAg
:::ICAjIHNpbmNyb25pemFyIHZhbG9yZXMgZ3VhcmRhZG9zCiAgICAgICAgICAgIGZt
:::dCA9IEFKVVNURVMuZ2V0KCdmb3JtYXRvJywgJ0FBQycpCiAgICAgICAgICAgIGlm
:::IGZtdCBub3QgaW4gRk9STUFUT1M6CiAgICAgICAgICAgICAgICBmbXQgPSAnQUFD
:::JwogICAgICAgICAgICBzZWxmLmNtYl9mb3JtYXRvLnNldChGT1JNQVRPU1tmbXRd
:::Wyd0ZXh0byddKQogICAgICAgICAgICBzZWxmLl9yZWNhcmdhcl9jYWxpZGFkZXMo
:::Zm10LCBBSlVTVEVTLmdldCgnY2FsaWRhZCcpKQoKICAgICAgICAjIC0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBoZWxwZXJz
:::IHdpZGdldHMKICAgICAgICBkZWYgX2JvdG9uKHNlbGYsIHBhZHJlLCB0ZXh0bywg
:::Y21kLCB3aWR0aD1Ob25lLCBmdWVudGU9RlVFTlRFX0JUTiwKICAgICAgICAgICAg
:::ICAgICAgIGFsdG89MSk6CiAgICAgICAgICAgIGIgPSB0ay5CdXR0b24ocGFkcmUs
:::IHRleHQ9dGV4dG8sIGNvbW1hbmQ9Y21kLCBmb250PWZ1ZW50ZSwKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICByZWxpZWY9J2ZsYXQnLCBiZD0wLCBjdXJzb3I9J2hh
:::bmQyJywgaGVpZ2h0PWFsdG8sCiAgICAgICAgICAgICAgICAgICAgICAgICAgYWN0
:::aXZlZm9yZWdyb3VuZD0nI2ZmZmZmZicsIHRha2Vmb2N1cz0wKQogICAgICAgICAg
:::ICBpZiB3aWR0aDoKICAgICAgICAgICAgICAgIGIuY29uZmlndXJlKHdpZHRoPXdp
:::ZHRoKQogICAgICAgICAgICBiLmJpbmQoJzxFbnRlcj4nLCBsYW1iZGEgZSwgdz1i
:::OiB3LmNvbmZpZ3VyZSgKICAgICAgICAgICAgICAgIGJnPVRFTUFTW3NlbGYuX3Rl
:::bWFfYWN0dWFsXVsnYm90b25fYWN0J10pKQogICAgICAgICAgICBiLmJpbmQoJzxM
:::ZWF2ZT4nLCBsYW1iZGEgZSwgdz1iOiB3LmNvbmZpZ3VyZSgKICAgICAgICAgICAg
:::ICAgIGJnPVRFTUFTW3NlbGYuX3RlbWFfYWN0dWFsXVsnYm90b24nXSkpCiAgICAg
:::ICAgICAgIHNlbGYuX2J0bnMuYXBwZW5kKGIpCiAgICAgICAgICAgIHJldHVybiBi
:::CgogICAgICAgIGRlZiBfcG9uZXJfcGxhY2Vob2xkZXIoc2VsZik6CiAgICAgICAg
:::ICAgIGlmIG5vdCBzZWxmLmVudF91cmwuZ2V0KCk6CiAgICAgICAgICAgICAgICBz
:::ZWxmLl9lbl9wbGFjZWhvbGRlciA9IFRydWUKICAgICAgICAgICAgICAgIHNlbGYu
:::ZW50X3VybC5pbnNlcnQoMCwgUExBQ0VIT0xERVJfVVJMKQoKICAgICAgICBkZWYg
:::X2xpbXBpYXJfdXJsKHNlbGYpOgogICAgICAgICAgICBzZWxmLmVudF91cmwuZGVs
:::ZXRlKDAsICdlbmQnKQogICAgICAgICAgICBzZWxmLmVudF91cmwuZm9jdXNfc2V0
:::KCkKCiAgICAgICAgZGVmIF9yZXNldF91cmwoc2VsZik6CiAgICAgICAgICAgICIi
:::IkRlamEgZWwgY2FtcG8gZGUgVVJMIHZhY8OtbyBjb24gc3UgcGxhY2Vob2xkZXIg
:::KHRyYXMgdW4gw6l4aXRvKS4iIiIKICAgICAgICAgICAgc2VsZi5lbnRfdXJsLmRl
:::bGV0ZSgwLCAnZW5kJykKICAgICAgICAgICAgc2VsZi5fZW5fcGxhY2Vob2xkZXIg
:::PSBUcnVlCiAgICAgICAgICAgIHNlbGYuX3BvbmVyX3BsYWNlaG9sZGVyKCkKICAg
:::ICAgICAgICAgc2VsZi5fcmVmcmVzY2FyX3BsYWNlaG9sZGVyKCkKCiAgICAgICAg
:::IyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0gdGVtYQogICAgICAgIGRlZiBfYXBsaWNhcl90ZW1hKHNlbGYpOgogICAgICAg
:::ICAgICB0ID0gVEVNQVNbc2VsZi5fdGVtYV9hY3R1YWxdCiAgICAgICAgICAgIHcg
:::PSBzZWxmLl93ZwogICAgICAgICAgICBzZWxmLmNvbmZpZ3VyZShiZz10Wydmb25k
:::byddKQogICAgICAgICAgICBmb3Igbm9tYnJlIGluICgnbWFyY28nLCAnZjAnLCAn
:::Z3UnLCAnZ2YnLCAnZmMnLCAnZ2UnKToKICAgICAgICAgICAgICAgIHdbbm9tYnJl
:::XS5jb25maWd1cmUoYmc9dFsnZm9uZG8nXSkKICAgICAgICAgICAgZm9yIGxmIGlu
:::ICh3WydndSddLCB3WydnZiddLCB3WydnZSddKToKICAgICAgICAgICAgICAgIGxm
:::LmNvbmZpZ3VyZShiZz10Wydmb25kbyddLCBmZz10Wyd0ZXh0bzInXSkKICAgICAg
:::ICAgICAgZm9yIG5vbWJyZSBpbiAoJ2xibF90ZW1hJywgJ2xibF9mbXQnLCAnbGJs
:::X2NhbCcsICdsYmxfY2FyJyk6CiAgICAgICAgICAgICAgICB3W25vbWJyZV0uY29u
:::ZmlndXJlKGJnPXRbJ2ZvbmRvJ10sIGZnPXRbJ3RleHRvJ10pCiAgICAgICAgICAg
:::IHNlbGYubGJsX2VzdGltYWNpb24uY29uZmlndXJlKGJnPXRbJ2ZvbmRvJ10sIGZn
:::PXRbJ3RleHRvJ10pCiAgICAgICAgICAgIHNlbGYubGJsX2VzdGFkby5jb25maWd1
:::cmUoYmc9dFsnZm9uZG8nXSwgZmc9dFsndGV4dG8yJ10pCiAgICAgICAgICAgIHNl
:::bGYuZW50X3VybC5jb25maWd1cmUoCiAgICAgICAgICAgICAgICBiZz10WydjYW1w
:::byddLCBmZz10Wyd0ZXh0byddLCBpbnNlcnRiYWNrZ3JvdW5kPXRbJ3RleHRvJ10s
:::CiAgICAgICAgICAgICAgICBoaWdobGlnaHRiYWNrZ3JvdW5kPXRbJ2NhbXBvX2Jv
:::cmRlJ10sCiAgICAgICAgICAgICAgICBoaWdobGlnaHRjb2xvcj10WydhY2VudG8n
:::XSwKICAgICAgICAgICAgICAgIGRpc2FibGVkYmFja2dyb3VuZD10WydjYW1wbydd
:::LCBkaXNhYmxlZGZvcmVncm91bmQ9dFsndGV4dG8yJ10pCiAgICAgICAgICAgIHNl
:::bGYuZW50X2NhcnBldGEuY29uZmlndXJlKAogICAgICAgICAgICAgICAgYmc9dFsn
:::Y2FtcG8nXSwgZmc9dFsndGV4dG8nXSwgaW5zZXJ0YmFja2dyb3VuZD10Wyd0ZXh0
:::byddLAogICAgICAgICAgICAgICAgaGlnaGxpZ2h0YmFja2dyb3VuZD10WydjYW1w
:::b19ib3JkZSddLAogICAgICAgICAgICAgICAgaGlnaGxpZ2h0Y29sb3I9dFsnYWNl
:::bnRvJ10pCiAgICAgICAgICAgIHNlbGYuY2hrX2VtYmViZXIuY29uZmlndXJlKAog
:::ICAgICAgICAgICAgICAgYmc9dFsnZm9uZG8nXSwgZmc9dFsndGV4dG8nXSwgYWN0
:::aXZlYmFja2dyb3VuZD10Wydmb25kbyddLAogICAgICAgICAgICAgICAgYWN0aXZl
:::Zm9yZWdyb3VuZD10Wyd0ZXh0byddLCBzZWxlY3Rjb2xvcj10WydjYW1wbyddKQog
:::ICAgICAgICAgICBmb3IgYiBpbiBzZWxmLl9idG5zOgogICAgICAgICAgICAgICAg
:::Yi5jb25maWd1cmUoYmc9dFsnYm90b24nXSwgZmc9dFsnYm90b25fdHh0J10sCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBhY3RpdmViYWNrZ3JvdW5kPXRbJ2Jv
:::dG9uX2FjdCddLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgYWN0aXZlZm9y
:::ZWdyb3VuZD10Wydib3Rvbl90eHQnXSkKICAgICAgICAgICAgc2VsZi50eHRfbG9n
:::LmNvbmZpZ3VyZShiZz10Wydsb2cnXSwgZmc9dFsnbG9nX3R4dCddLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgIGluc2VydGJhY2tncm91bmQ9dFsn
:::bG9nX3R4dCddKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cudGFnX2NvbmZpZ3Vy
:::ZSgnaW5mbycsIGZvcmVncm91bmQ9dFsnbG9nX3R4dCddKQogICAgICAgICAgICBz
:::ZWxmLnR4dF9sb2cudGFnX2NvbmZpZ3VyZSgnZ3JpcycsIGZvcmVncm91bmQ9dFsn
:::dGV4dG8yJ10pCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy50YWdfY29uZmlndXJl
:::KCd0aXR1bG8nLCBmb3JlZ3JvdW5kPXRbJ3RleHRvJ10sCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgIGZvbnQ9KCdDb25zb2xhcycsIDEwLCAn
:::Ym9sZCcpKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cudGFnX2NvbmZpZ3VyZSgn
:::b2snLCBmb3JlZ3JvdW5kPXRbJ29rJ10pCiAgICAgICAgICAgIHNlbGYudHh0X2xv
:::Zy50YWdfY29uZmlndXJlKCdhdmlzbycsIGZvcmVncm91bmQ9dFsnYXZpc28nXSkK
:::ICAgICAgICAgICAgc2VsZi50eHRfbG9nLnRhZ19jb25maWd1cmUoJ2Vycm9yJywg
:::Zm9yZWdyb3VuZD10WydlcnJvciddKQogICAgICAgICAgICBlc3QgPSBzZWxmLl9l
:::c3RpbG8KICAgICAgICAgICAgZXN0LmNvbmZpZ3VyZSgnZ3guVENvbWJvYm94JywK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBmaWVsZGJhY2tncm91bmQ9dFsnY2Ft
:::cG8nXSwgYmFja2dyb3VuZD10Wydib3RvbiddLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgIGZvcmVncm91bmQ9dFsndGV4dG8nXSwgYXJyb3djb2xvcj10Wyd0ZXh0
:::byddLAogICAgICAgICAgICAgICAgICAgICAgICAgIGJvcmRlcmNvbG9yPXRbJ2Nh
:::bXBvX2JvcmRlJ10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgbGlnaHRjb2xv
:::cj10WydjYW1wb19ib3JkZSddLAogICAgICAgICAgICAgICAgICAgICAgICAgIGRh
:::cmtjb2xvcj10WydjYW1wb19ib3JkZSddLAogICAgICAgICAgICAgICAgICAgICAg
:::ICAgIGluc2VydGNvbG9yPXRbJ3RleHRvJ10pCiAgICAgICAgICAgIGVzdC5tYXAo
:::J2d4LlRDb21ib2JveCcsCiAgICAgICAgICAgICAgICAgICAgZmllbGRiYWNrZ3Jv
:::dW5kPVsoJ3JlYWRvbmx5JywgdFsnY2FtcG8nXSldLAogICAgICAgICAgICAgICAg
:::ICAgIGZvcmVncm91bmQ9WygncmVhZG9ubHknLCB0Wyd0ZXh0byddKV0pCiAgICAg
:::ICAgICAgIGVzdC5jb25maWd1cmUoJ2d4Lkhvcml6b250YWwuVFByb2dyZXNzYmFy
:::JywKICAgICAgICAgICAgICAgICAgICAgICAgICB0cm91Z2hjb2xvcj10Wyd0cm91
:::Z2gnXSwgYmFja2dyb3VuZD10WydhY2VudG8nXSwKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICBib3JkZXJjb2xvcj10Wydmb25kbyddLCBsaWdodGNvbG9yPXRbJ2Fj
:::ZW50byddLAogICAgICAgICAgICAgICAgICAgICAgICAgIGRhcmtjb2xvcj10Wydh
:::Y2VudG8nXSkKICAgICAgICAgICAgc2VsZi5vcHRpb25fYWRkKCcqVENvbWJvYm94
:::Kkxpc3Rib3guYmFja2dyb3VuZCcsIHRbJ2NhbXBvJ10pCiAgICAgICAgICAgIHNl
:::bGYub3B0aW9uX2FkZCgnKlRDb21ib2JveCpMaXN0Ym94LmZvcmVncm91bmQnLCB0
:::Wyd0ZXh0byddKQogICAgICAgICAgICBzZWxmLm9wdGlvbl9hZGQoJypUQ29tYm9i
:::b3gqTGlzdGJveC5zZWxlY3RCYWNrZ3JvdW5kJywKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgIHRbJ2JvdG9uX2FjdCddKQogICAgICAgICAgICBzZWxmLm9wdGlv
:::bl9hZGQoJypUQ29tYm9ib3gqTGlzdGJveC5zZWxlY3RGb3JlZ3JvdW5kJywKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgIHRbJ2JvdG9uX3R4dCddKQogICAgICAg
:::ICAgICBzZWxmLl9yZWZyZXNjYXJfcGxhY2Vob2xkZXIoKQoKICAgICAgICBkZWYg
:::X3JlZnJlc2Nhcl9wbGFjZWhvbGRlcihzZWxmKToKICAgICAgICAgICAgdCA9IFRF
:::TUFTW3NlbGYuX3RlbWFfYWN0dWFsXQogICAgICAgICAgICBpZiBzZWxmLl9lbl9w
:::bGFjZWhvbGRlcjoKICAgICAgICAgICAgICAgIHNlbGYuZW50X3VybC5jb25maWd1
:::cmUoZmc9dFsncGxhY2Vob2xkZXInXSkKICAgICAgICAgICAgZWxzZToKICAgICAg
:::ICAgICAgICAgIHNlbGYuZW50X3VybC5jb25maWd1cmUoZmc9dFsndGV4dG8nXSkK
:::CiAgICAgICAgIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0gZXZlbnRvcwogICAgICAgIGRlZiBfY29uZWN0YXJfZXZlbnRv
:::cyhzZWxmKToKICAgICAgICAgICAgc2VsZi5jbWJfdGVtYS5iaW5kKCc8PENvbWJv
:::Ym94U2VsZWN0ZWQ+PicsIHNlbGYuX29uX3RlbWEpCiAgICAgICAgICAgIHNlbGYu
:::Y21iX2Zvcm1hdG8uYmluZCgnPDxDb21ib2JveFNlbGVjdGVkPj4nLCBzZWxmLl9v
:::bl9mb3JtYXRvKQogICAgICAgICAgICBzZWxmLmNtYl9jYWxpZGFkLmJpbmQoJzw8
:::Q29tYm9ib3hTZWxlY3RlZD4+JywgbGFtYmRhIGU6IHNlbGYuX2d1YXJkYXIoKSkK
:::ICAgICAgICAgICAgc2VsZi5jaGtfZW1iZWJlci5jb25maWd1cmUoY29tbWFuZD1z
:::ZWxmLl9ndWFyZGFyKQogICAgICAgICAgICBzZWxmLmVudF91cmwuYmluZCgnPEZv
:::Y3VzSW4+Jywgc2VsZi5fb25fZm9jdXNfdXJsX2luKQogICAgICAgICAgICBzZWxm
:::LmVudF91cmwuYmluZCgnPEZvY3VzT3V0PicsIHNlbGYuX29uX2ZvY3VzX3VybF9v
:::dXQpCiAgICAgICAgICAgIHNlbGYuZW50X3VybC5iaW5kKCc8UmV0dXJuPicsIGxh
:::bWJkYSBlOiBzZWxmLl9hY2Npb25fZGVzY2FyZ2FyKCkpCiAgICAgICAgICAgIHNl
:::bGYuZW50X2NhcnBldGEuYmluZCgnPEZvY3VzT3V0PicsIHNlbGYuX29uX2NhcnBl
:::dGFfZXNjcml0YSkKICAgICAgICAgICAgc2VsZi5wcm90b2NvbCgnV01fREVMRVRF
:::X1dJTkRPVycsIHNlbGYuX2FsX2NlcnJhcikKICAgICAgICAgICAgc2VsZi5iaW5k
:::KCc8Q29udHJvbC11PicsIGxhbWJkYSBlOiBzZWxmLl9hY2Npb25fYWN0dWFsaXph
:::cigpKQogICAgICAgICAgICBzZWxmLmJpbmQoJzxDb250cm9sLWw+JywgbGFtYmRh
:::IGU6IHNlbGYuX2xpbXBpYXJfbG9nKCkpCiAgICAgICAgICAgIHNlbGYuYmluZCgn
:::PENvbnRyb2wtVT4nLCBsYW1iZGEgZTogc2VsZi5fYWNjaW9uX2FjdHVhbGl6YXIo
:::KSkKCiAgICAgICAgZGVmIF9vbl9mb2N1c191cmxfaW4oc2VsZiwgX2U9Tm9uZSk6
:::CiAgICAgICAgICAgIGlmIHNlbGYuX2VuX3BsYWNlaG9sZGVyOgogICAgICAgICAg
:::ICAgICAgc2VsZi5lbnRfdXJsLmRlbGV0ZSgwLCAnZW5kJykKICAgICAgICAgICAg
:::ICAgIHNlbGYuX2VuX3BsYWNlaG9sZGVyID0gRmFsc2UKICAgICAgICAgICAgICAg
:::IHNlbGYuX3JlZnJlc2Nhcl9wbGFjZWhvbGRlcigpCgogICAgICAgIGRlZiBfb25f
:::Zm9jdXNfdXJsX291dChzZWxmLCBfZT1Ob25lKToKICAgICAgICAgICAgaWYgbm90
:::IHNlbGYuZW50X3VybC5nZXQoKToKICAgICAgICAgICAgICAgIHNlbGYuX2VuX3Bs
:::YWNlaG9sZGVyID0gVHJ1ZQogICAgICAgICAgICAgICAgc2VsZi5fcG9uZXJfcGxh
:::Y2Vob2xkZXIoKQogICAgICAgICAgICAgICAgc2VsZi5fcmVmcmVzY2FyX3BsYWNl
:::aG9sZGVyKCkKCiAgICAgICAgZGVmIF9vbl90ZW1hKHNlbGYsIF9lPU5vbmUpOgog
:::ICAgICAgICAgICBzZWxmLl90ZW1hX2FjdHVhbCA9IHNlbGYuY21iX3RlbWEuZ2V0
:::KCkKICAgICAgICAgICAgQUpVU1RFU1sndGVtYSddID0gc2VsZi5fdGVtYV9hY3R1
:::YWwKICAgICAgICAgICAgZ3VhcmRhcl9hanVzdGVzKCkKICAgICAgICAgICAgc2Vs
:::Zi5fYXBsaWNhcl90ZW1hKCkKCiAgICAgICAgZGVmIF9vbl9mb3JtYXRvKHNlbGYs
:::IF9lPU5vbmUpOgogICAgICAgICAgICBmbXQgPSBzZWxmLl9mbXRfYWN0dWFsKCkK
:::ICAgICAgICAgICAgc2VsZi5fcmVjYXJnYXJfY2FsaWRhZGVzKGZtdCkKICAgICAg
:::ICAgICAgc2VsZi5fZ3VhcmRhcigpCiAgICAgICAgICAgIHNlbGYubGJsX2VzdGlt
:::YWNpb24uY29uZmlndXJlKAogICAgICAgICAgICAgICAgdGV4dD0nSW50cm9kdWNl
:::IHVuYSBVUkwgeSBwdWxzYSBFc3RpbWFyLicsCiAgICAgICAgICAgICAgICBmZz1U
:::RU1BU1tzZWxmLl90ZW1hX2FjdHVhbF1bJ3RleHRvJ10pCgogICAgICAgIGRlZiBf
:::Zm10X2FjdHVhbChzZWxmKToKICAgICAgICAgICAgdGV4dG8gPSBzZWxmLmNtYl9m
:::b3JtYXRvLmdldCgpCiAgICAgICAgICAgIGZvciBjbGF2ZSwgZiBpbiBGT1JNQVRP
:::Uy5pdGVtcygpOgogICAgICAgICAgICAgICAgaWYgZlsndGV4dG8nXSA9PSB0ZXh0
:::bzoKICAgICAgICAgICAgICAgICAgICByZXR1cm4gY2xhdmUKICAgICAgICAgICAg
:::cmV0dXJuICdBQUMnCgogICAgICAgIGRlZiBfcmVjYXJnYXJfY2FsaWRhZGVzKHNl
:::bGYsIGNsYXZlX2ZtdCwgY2FsaWRhZF9wcmV2aWE9Tm9uZSk6CiAgICAgICAgICAg
:::IGYgPSBGT1JNQVRPU1tjbGF2ZV9mbXRdCiAgICAgICAgICAgIHNlbGYuY21iX2Nh
:::bGlkYWRbJ3ZhbHVlcyddID0gZlsnY2FsaWRhZGVzJ10KICAgICAgICAgICAgaWYg
:::Y2FsaWRhZF9wcmV2aWEgYW5kIGNhbGlkYWRfcHJldmlhIGluIGZbJ2NhbGlkYWRl
:::cyddOgogICAgICAgICAgICAgICAgc2VsZi5jbWJfY2FsaWRhZC5zZXQoY2FsaWRh
:::ZF9wcmV2aWEpCiAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICBzZWxm
:::LmNtYl9jYWxpZGFkLnNldChmWydkZWZlY3RvJ10pCiAgICAgICAgICAgIEFKVVNU
:::RVNbJ2Zvcm1hdG8nXSA9IGNsYXZlX2ZtdAogICAgICAgICAgICBBSlVTVEVTWydj
:::YWxpZGFkJ10gPSBzZWxmLmNtYl9jYWxpZGFkLmdldCgpCgogICAgICAgIGRlZiBf
:::Z3VhcmRhcihzZWxmKToKICAgICAgICAgICAgQUpVU1RFU1snZm9ybWF0byddID0g
:::c2VsZi5fZm10X2FjdHVhbCgpCiAgICAgICAgICAgIEFKVVNURVNbJ2NhbGlkYWQn
:::XSA9IHNlbGYuY21iX2NhbGlkYWQuZ2V0KCkKICAgICAgICAgICAgQUpVU1RFU1sn
:::ZW1iZWJlciddID0gYm9vbChzZWxmLnZhcl9lbWJlYmVyLmdldCgpKQogICAgICAg
:::ICAgICBBSlVTVEVTWydkZXN0aW5vJ10gPSBzZWxmLmVudF9jYXJwZXRhLmdldCgp
:::LnN0cmlwKCkKICAgICAgICAgICAgZ3VhcmRhcl9hanVzdGVzKCkKCiAgICAgICAg
:::ZGVmIF9vbl9jYXJwZXRhX2VzY3JpdGEoc2VsZiwgX2U9Tm9uZSk6CiAgICAgICAg
:::ICAgIHAgPSBQYXRoKG9zLnBhdGguZXhwYW5kdmFycygKICAgICAgICAgICAgICAg
:::IHNlbGYuZW50X2NhcnBldGEuZ2V0KCkuc3RyaXAoKS5zdHJpcCgnIicpKSkKICAg
:::ICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgcC5ta2RpcihwYXJlbnRzPVRy
:::dWUsIGV4aXN0X29rPVRydWUpCiAgICAgICAgICAgICAgICBBSlVTVEVTWydkZXN0
:::aW5vJ10gPSBzdHIocCkKICAgICAgICAgICAgICAgIGd1YXJkYXJfYWp1c3Rlcygp
:::CiAgICAgICAgICAgIGV4Y2VwdCBPU0Vycm9yIGFzIGU6CiAgICAgICAgICAgICAg
:::ICBzZWxmLl9sb2coZidObyBzZSBwdWRvIHVzYXIgZXNhIGNhcnBldGE6IHtlfScs
:::ICdlcnJvcicpCgogICAgICAgIGRlZiBfY2FtYmlhcl9jYXJwZXRhKHNlbGYpOgog
:::ICAgICAgICAgICBhY3R1YWwgPSBzZWxmLmVudF9jYXJwZXRhLmdldCgpLnN0cmlw
:::KCkgb3IgQUpVU1RFU1snZGVzdGlubyddCiAgICAgICAgICAgIG51ZXZhID0gZmls
:::ZWRpYWxvZy5hc2tkaXJlY3RvcnkoCiAgICAgICAgICAgICAgICB0aXRsZT0nRWxp
:::Z2UgbGEgY2FycGV0YSBkb25kZSBndWFyZGFyIGxhcyBkZXNjYXJnYXMnLAogICAg
:::ICAgICAgICAgICAgaW5pdGlhbGRpcj1hY3R1YWwgaWYgb3MucGF0aC5pc2Rpcihh
:::Y3R1YWwpIGVsc2Ugc3RyKFBhdGguaG9tZSgpKSkKICAgICAgICAgICAgaWYgbm90
:::IG51ZXZhOgogICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgIHRyeToK
:::ICAgICAgICAgICAgICAgIFBhdGgobnVldmEpLm1rZGlyKHBhcmVudHM9VHJ1ZSwg
:::ZXhpc3Rfb2s9VHJ1ZSkKICAgICAgICAgICAgZXhjZXB0IE9TRXJyb3IgYXMgZToK
:::ICAgICAgICAgICAgICAgIG1lc3NhZ2Vib3guc2hvd2Vycm9yKCdDYXJwZXRhIG5v
:::IHbDoWxpZGEnLCBzdHIoZSkpCiAgICAgICAgICAgICAgICByZXR1cm4KICAgICAg
:::ICAgICAgc2VsZi5lbnRfY2FycGV0YS5kZWxldGUoMCwgJ2VuZCcpCiAgICAgICAg
:::ICAgIHNlbGYuZW50X2NhcnBldGEuaW5zZXJ0KDAsIG51ZXZhKQogICAgICAgICAg
:::ICBBSlVTVEVTWydkZXN0aW5vJ10gPSBudWV2YQogICAgICAgICAgICBndWFyZGFy
:::X2FqdXN0ZXMoKQogICAgICAgICAgICBzZWxmLl9sb2coJ0NhcnBldGEgZGUgZ3Vh
:::cmRhZG86ICcgKyBudWV2YSwgJ2dyaXMnKQoKICAgICAgICBkZWYgX2FicmlyX2Rl
:::c3Rpbm8oc2VsZik6CiAgICAgICAgICAgIHAgPSBQYXRoKG9zLnBhdGguZXhwYW5k
:::dmFycygKICAgICAgICAgICAgICAgIHNlbGYuZW50X2NhcnBldGEuZ2V0KCkuc3Ry
:::aXAoKS5zdHJpcCgnIicpKSkKICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAg
:::ICAgcC5ta2RpcihwYXJlbnRzPVRydWUsIGV4aXN0X29rPVRydWUpCiAgICAgICAg
:::ICAgIGV4Y2VwdCBPU0Vycm9yOgogICAgICAgICAgICAgICAgcGFzcwogICAgICAg
:::ICAgICBhYnJpcl9jYXJwZXRhKHApCgogICAgICAgIGRlZiBfYWxfY2VycmFyKHNl
:::bGYpOgogICAgICAgICAgICBpZiBzZWxmLl9vY3VwYWRvIGFuZCBub3QgbWVzc2Fn
:::ZWJveC5hc2tva2NhbmNlbCgKICAgICAgICAgICAgICAgICAgICAnU2FsaXInLCAn
:::SGF5IHVuYSB0YXJlYSBlbiBjdXJzby4gJwogICAgICAgICAgICAgICAgICAgICfC
:::v1NlZ3VybyBxdWUgcXVpZXJlcyBzYWxpcj8nKToKICAgICAgICAgICAgICAgIHJl
:::dHVybgogICAgICAgICAgICBzZWxmLmRlc3Ryb3koKQoKICAgICAgICAjIC0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSByZWdp
:::c3RybyAobG9nKQogICAgICAgIGRlZiBfbG9nKHNlbGYsIG1zZywgdGFnPSdpbmZv
:::Jyk6CiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5jb25maWd1cmUoc3RhdGU9J25v
:::cm1hbCcpCiAgICAgICAgICAgIG5fbGluZWFzID0gaW50KHNlbGYudHh0X2xvZy5p
:::bmRleCgnZW5kLTFjJykuc3BsaXQoJy4nKVswXSkKICAgICAgICAgICAgaWYgbl9s
:::aW5lYXMgPiA5MDA6CiAgICAgICAgICAgICAgICBzZWxmLnR4dF9sb2cuZGVsZXRl
:::KCcxLjAnLCAnMjAwLjAnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuaW5zZXJ0
:::KCdlbmQnLCBzdHIobXNnKSArICdcbicsIHRhZykKICAgICAgICAgICAgc2VsZi50
:::eHRfbG9nLnNlZSgnZW5kJykKICAgICAgICAgICAgc2VsZi50eHRfbG9nLmNvbmZp
:::Z3VyZShzdGF0ZT0nZGlzYWJsZWQnKQoKICAgICAgICBkZWYgX2xpbXBpYXJfbG9n
:::KHNlbGYpOgogICAgICAgICAgICBzZWxmLnR4dF9sb2cuY29uZmlndXJlKHN0YXRl
:::PSdub3JtYWwnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuZGVsZXRlKCcxLjAn
:::LCAnZW5kJykKICAgICAgICAgICAgc2VsZi50eHRfbG9nLmNvbmZpZ3VyZShzdGF0
:::ZT0nZGlzYWJsZWQnKQoKICAgICAgICBkZWYgX2JvbWJlYXJfY29sYShzZWxmKToK
:::ICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgd2hpbGUgVHJ1ZToKICAg
:::ICAgICAgICAgICAgICAgICBldiA9IHNlbGYuY29sYS5nZXRfbm93YWl0KCkKICAg
:::ICAgICAgICAgICAgICAgICB0aXBvID0gZXZbMF0KICAgICAgICAgICAgICAgICAg
:::ICBpZiB0aXBvID09ICdsb2cnOgogICAgICAgICAgICAgICAgICAgICAgICBzZWxm
:::Ll9sb2coZXZbMV0sIGV2WzJdKQogICAgICAgICAgICAgICAgICAgIGVsaWYgdGlw
:::byA9PSAncHJvZyc6CiAgICAgICAgICAgICAgICAgICAgICAgIHBjdCwgdGV4dG8g
:::PSBldlsxXSwgZXZbMl0KICAgICAgICAgICAgICAgICAgICAgICAgaWYgcGN0IGlz
:::IE5vbmU6CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzZWxmLmJhcnJhLnN0
:::b3AoKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5iYXJyYS5jb25m
:::aWd1cmUobW9kZT0naW5kZXRlcm1pbmF0ZScpCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICBzZWxmLmJhcnJhLnN0YXJ0KDYwKQogICAgICAgICAgICAgICAgICAg
:::ICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5iYXJy
:::YS5zdG9wKCkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYmFycmEu
:::Y29uZmlndXJlKG1vZGU9J2RldGVybWluYXRlJykKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgIHNlbGYuYmFycmEuY29uZmlndXJlKHZhbHVlPW1heCgwLCBtaW4o
:::MTAwLCBwY3QpKSkKICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5sYmxfZXN0
:::YWRvLmNvbmZpZ3VyZSh0ZXh0PXRleHRvKQogICAgICAgICAgICAgICAgICAgIGVs
:::aWYgdGlwbyA9PSAnZXN0aW1hY2lvbic6CiAgICAgICAgICAgICAgICAgICAgICAg
:::IHNlbGYubGJsX2VzdGltYWNpb24uY29uZmlndXJlKAogICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgdGV4dD1ldlsxXSwgZmc9VEVNQVNbc2VsZi5fdGVtYV9hY3R1
:::YWxdWydhY2VudG8nXSkKICAgICAgICAgICAgICAgICAgICBlbGlmIHRpcG8gPT0g
:::J2Zpbic6CiAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuX2Zpbl90YXJlYShl
:::dlsxXSwgZXZbMl0sIGV2WzNdIGlmIGxlbihldikgPiAzIGVsc2UgJycpCiAgICAg
:::ICAgICAgIGV4Y2VwdCBxdWV1ZS5FbXB0eToKICAgICAgICAgICAgICAgIHBhc3MK
:::ICAgICAgICAgICAgc2VsZi5hZnRlcig4MCwgc2VsZi5fYm9tYmVhcl9jb2xhKQoK
:::ICAgICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLSB0YXJlYXMKICAgICAgICBkZWYgX2hhYmlsaXRhcl9hY2Npb25l
:::cyhzZWxmLCBvbik6CiAgICAgICAgICAgIGVzdGFkbyA9ICdub3JtYWwnIGlmIG9u
:::IGVsc2UgJ2Rpc2FibGVkJwogICAgICAgICAgICBmb3IgYiBpbiAoc2VsZi5idG5f
:::ZGVzY2FyZ2FyLCBzZWxmLmJ0bl9jb21wcm9iYXIsCiAgICAgICAgICAgICAgICAg
:::ICAgICBzZWxmLmJ0bl9lc3RpbWFyLCBzZWxmLmJ0bl9jYW1iaWFyLCBzZWxmLmJ0
:::bl9hYnJpciwKICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYnRuX3gpOgogICAg
:::ICAgICAgICAgICAgYi5jb25maWd1cmUoc3RhdGU9ZXN0YWRvLCBjdXJzb3I9J2hh
:::bmQyJyBpZiBvbiBlbHNlICdhcnJvdycpCgogICAgICAgIGRlZiBfaW5pY2lhcihz
:::ZWxmLCBvYmpldGl2bywgY2ZnLCB0ZXh0byk6CiAgICAgICAgICAgIGlmIHNlbGYu
:::X29jdXBhZG86CiAgICAgICAgICAgICAgICBzZWxmLl9sb2coJ1lhIGhheSB1bmEg
:::dGFyZWEgZW4gY3Vyc287IGVzcGVyYSBhIHF1ZSB0ZXJtaW5lLicsCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgJ2F2aXNvJykKICAgICAgICAgICAgICAgIHJldHVy
:::biBGYWxzZQogICAgICAgICAgICBzZWxmLl9vY3VwYWRvID0gVHJ1ZQogICAgICAg
:::ICAgICBzZWxmLl9oYWJpbGl0YXJfYWNjaW9uZXMoRmFsc2UpCiAgICAgICAgICAg
:::IHNlbGYubGJsX2VzdGFkby5jb25maWd1cmUodGV4dD10ZXh0bykKICAgICAgICAg
:::ICAgdGhyZWFkaW5nLlRocmVhZCh0YXJnZXQ9b2JqZXRpdm8sIGFyZ3M9KGNmZywp
:::LCBkYWVtb249VHJ1ZSkuc3RhcnQoKQogICAgICAgICAgICByZXR1cm4gVHJ1ZQoK
:::ICAgICAgICBkZWYgX2Zpbl90YXJlYShzZWxmLCB0aXBvLCBvaywgbWVuc2FqZT0n
:::Jyk6CiAgICAgICAgICAgIHNlbGYuX29jdXBhZG8gPSBGYWxzZQogICAgICAgICAg
:::ICBzZWxmLl9oYWJpbGl0YXJfYWNjaW9uZXMoVHJ1ZSkKICAgICAgICAgICAgc2Vs
:::Zi5iYXJyYS5zdG9wKCkKICAgICAgICAgICAgc2VsZi5iYXJyYS5jb25maWd1cmUo
:::bW9kZT0nZGV0ZXJtaW5hdGUnKQogICAgICAgICAgICBzZWxmLmJhcnJhLmNvbmZp
:::Z3VyZSh2YWx1ZT0wKQogICAgICAgICAgICBpZiB0aXBvID09ICdkZXNjYXJnYScg
:::YW5kIG9rOgogICAgICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmNvbmZpZ3Vy
:::ZSh0ZXh0PSdMaXN0by4nKQogICAgICAgICAgICAgICAgIyBMYSBkZXNjYXJnYSBm
:::dWUgYmllbjogc2UgbGltcGlhIGxhIFVSTCBwYXJhIGxhIHNpZ3VpZW50ZS4KICAg
:::ICAgICAgICAgICAgIHNlbGYuX3Jlc2V0X3VybCgpCiAgICAgICAgICAgIGVsaWYg
:::bm90IG9rOgogICAgICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmNvbmZpZ3Vy
:::ZSh0ZXh0PSdUZXJtaW5hZG8gY29uIGVycm9yZXMuJykKICAgICAgICAgICAgICAg
:::IGlmIHRpcG8gPT0gJ2Rlc2NhcmdhJzoKICAgICAgICAgICAgICAgICAgICBtZXNz
:::YWdlYm94LnNob3dlcnJvcigKICAgICAgICAgICAgICAgICAgICAgICAgJ0Vycm9y
:::JywgbWVuc2FqZSBvciAnTm8gc2UgcHVkbyBjb21wbGV0YXIgbGEgdGFyZWEuICcK
:::ICAgICAgICAgICAgICAgICAgICAgICAgJ1JldmlzYSBlbCByZWdpc3RybyBwYXJh
:::IG3DoXMgZGV0YWxsZXMuJykKCiAgICAgICAgZGVmIF91cmxfdmFsaWRhKHNlbGYp
:::OgogICAgICAgICAgICBpZiBzZWxmLl9lbl9wbGFjZWhvbGRlcjoKICAgICAgICAg
:::ICAgICAgIHNlbGYuX2xvZygnUHJpbWVybyBwZWdhIGxhIFVSTCBkZWwgdmlkZW8g
:::ZGUgWW91VHViZS4nLCAnYXZpc28nKQogICAgICAgICAgICAgICAgcmV0dXJuIE5v
:::bmUKICAgICAgICAgICAgdSA9IHNlbGYuZW50X3VybC5nZXQoKS5zdHJpcCgpLnN0
:::cmlwKCciJykuc3RyaXAoIiciKQogICAgICAgICAgICBpZiBub3QgdToKICAgICAg
:::ICAgICAgICAgIHNlbGYuX2xvZygnTGEgVVJMIGVzdMOhIHZhY8OtYS4nLCAnYXZp
:::c28nKQogICAgICAgICAgICAgICAgcmV0dXJuIE5vbmUKICAgICAgICAgICAgaWYg
:::bm90IHJlLm1hdGNoKHInXmh0dHBzPzovLycsIHUsIHJlLkkpOgogICAgICAgICAg
:::ICAgICAgaWYgcmUubWF0Y2gocided3d3XC4nLCB1LCByZS5JKToKICAgICAgICAg
:::ICAgICAgICAgICB1ID0gJ2h0dHBzOi8vJyArIHUKICAgICAgICAgICAgICAgIGVs
:::c2U6CiAgICAgICAgICAgICAgICAgICAgc2VsZi5fbG9nKCdFc28gbm8gcGFyZWNl
:::IHVuYSBVUkwgKGRlYmUgZW1wZXphciBwb3IgJwogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAnaHR0cDovLyBvIGh0dHBzOi8vKScsICdlcnJvcicpCiAgICAg
:::ICAgICAgICAgICAgICAgcmV0dXJuIE5vbmUKICAgICAgICAgICAgIyBPSk86IGFx
:::dcOtIE5PIHNlIHF1aXRhIGxpc3Q9OyBzaSBsYSBVUkwgdHJhZSB1bmEgcGxheWxp
:::c3QsCiAgICAgICAgICAgICMgX2FjY2lvbl9kZXNjYXJnYXIgcHJlZ3VudGFyw6Eg
:::cXXDqSBoYWNlciBjb24gZWxsYS4KICAgICAgICAgICAgcmV0dXJuIHUKCiAgICAg
:::ICAgZGVmIF9hY2Npb25fZXN0aW1hcihzZWxmKToKICAgICAgICAgICAgdXJsID0g
:::c2VsZi5fdXJsX3ZhbGlkYSgpCiAgICAgICAgICAgIGlmIG5vdCB1cmw6CiAgICAg
:::ICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgc2VsZi5fZ3VhcmRhcigpCiAg
:::ICAgICAgICAgIGNmZyA9IHsndXJsJzogdXJsfQogICAgICAgICAgICBzZWxmLl9p
:::bmljaWFyKHNlbGYuX2hpbG9fZXN0aW1hciwgY2ZnLCAnRXN0aW1hbmRvIHRhbWHD
:::sW8uLi4nKQogICAgICAgICAgICBzZWxmLmxibF9lc3RpbWFjaW9uLmNvbmZpZ3Vy
:::ZSgKICAgICAgICAgICAgICAgIHRleHQ9J0NhbGN1bGFuZG8uLi4nLCBmZz1URU1B
:::U1tzZWxmLl90ZW1hX2FjdHVhbF1bJ3RleHRvMiddKQoKICAgICAgICBkZWYgX2Fj
:::Y2lvbl9kZXNjYXJnYXIoc2VsZik6CiAgICAgICAgICAgIHVybCA9IHNlbGYuX3Vy
:::bF92YWxpZGEoKQogICAgICAgICAgICBpZiBub3QgdXJsOgogICAgICAgICAgICAg
:::ICAgcmV0dXJuCiAgICAgICAgICAgIHNlbGYuX2d1YXJkYXIoKQogICAgICAgICAg
:::ICBwbGF5bGlzdCA9IEZhbHNlCiAgICAgICAgICAgIGlmIGVzX3VybF9wbGF5bGlz
:::dCh1cmwpOgogICAgICAgICAgICAgICAgciA9IG1lc3NhZ2Vib3guYXNreWVzbm9j
:::YW5jZWwoCiAgICAgICAgICAgICAgICAgICAgJ011c2lrQUxBTiDigJQgbGlzdGEg
:::ZGUgcmVwcm9kdWNjacOzbicsCiAgICAgICAgICAgICAgICAgICAgJ0VzdGEgVVJM
:::IHBlcnRlbmVjZSBhIHVuYSBsaXN0YSBkZSByZXByb2R1Y2Npw7NuLlxuXG4nCiAg
:::ICAgICAgICAgICAgICAgICAgJyAgU8ONICDihpIgIGRlc2NhcmdhciBsYSBwbGF5
:::bGlzdCBjb21wbGV0YVxuJwogICAgICAgICAgICAgICAgICAgICcgICAgICAgICAo
:::cGF1c2EgZGUgMiBzIGVudHJlIGNhbmNpb25lcylcbicKICAgICAgICAgICAgICAg
:::ICAgICAnICBOTyAg4oaSICBkZXNjYXJnYXIgc29sbyBlc3RhIGNhbmNpw7NuXG4n
:::CiAgICAgICAgICAgICAgICAgICAgJyAgQ2FuY2VsYXIgIOKGkiAgbm8gZGVzY2Fy
:::Z2FyIG5hZGEnKQogICAgICAgICAgICAgICAgaWYgciBpcyBOb25lOgogICAgICAg
:::ICAgICAgICAgICAgIHNlbGYuX2xvZygnRGVzY2FyZ2EgY2FuY2VsYWRhLicsICdn
:::cmlzJykKICAgICAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgICAg
:::IGlmIHI6CiAgICAgICAgICAgICAgICAgICAgcGxheWxpc3QgPSBUcnVlCiAgICAg
:::ICAgICAgICAgICBlbGlmIGVzX3NvbG9fbGlzdGEodXJsKToKICAgICAgICAgICAg
:::ICAgICAgICAjIEVzIHVuYSBwbGF5bGlzdCBwdXJhOiBubyBoYXkgInVuYSBjYW5j
:::acOzbiIgYWjDrQogICAgICAgICAgICAgICAgICAgIHNlbGYuX2xvZygnRXNhIFVS
:::TCBlcyB1bmEgbGlzdGEgY29tcGxldGE7IHNlIGRlc2NhcmdhcsOhICcKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgJ2VudGVyYS4nLCAnYXZpc28nKQogICAg
:::ICAgICAgICAgICAgICAgIHBsYXlsaXN0ID0gVHJ1ZQogICAgICAgICAgICBjZmcg
:::PSB7J3VybCc6IHVybCwgJ3BsYXlsaXN0JzogcGxheWxpc3R9CiAgICAgICAgICAg
:::IHNlbGYuX2luaWNpYXIoc2VsZi5faGlsb19kZXNjYXJnYXIsIGNmZywgJ0Rlc2Nh
:::cmdhbmRvLi4uJykKCiAgICAgICAgZGVmIF9hY2Npb25fY29tcHJvYmFyKHNlbGYp
:::OgogICAgICAgICAgICBzZWxmLl9ndWFyZGFyKCkKICAgICAgICAgICAgc2VsZi5f
:::aW5pY2lhcihzZWxmLl9oaWxvX2NvbXByb2Jhciwge30sCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgJ0NvbXByb2JhbmRvIGxhIGNhcnBldGEuLi4nKQoKICAgICAg
:::ICBkZWYgX2FjY2lvbl9hY3R1YWxpemFyKHNlbGYpOgogICAgICAgICAgICBpZiBu
:::b3QgWVRfRExQOgogICAgICAgICAgICAgICAgc2VsZi5fbG9nKCd5dC1kbHAgbm8g
:::ZXN0w6EgaW5zdGFsYWRvOyBlamVjdXRhICcKICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAnRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0LicsICdlcnJvcicpCiAgICAgICAg
:::ICAgICAgICByZXR1cm4KICAgICAgICAgICAgc2VsZi5faW5pY2lhcihzZWxmLl9o
:::aWxvX2FjdHVhbGl6YXIsIHt9LCAnQWN0dWFsaXphbmRvIHl0LWRscC4uLicpCgog
:::ICAgICAgICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tIGhpbG9zCiAgICAgICAgZGVmIF9oaWxvX2VzdGltYXIoc2VsZiwg
:::Y2ZnKToKICAgICAgICAgICAgY29sYSA9IHNlbGYuY29sYQoKICAgICAgICAgICAg
:::ZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAgICAgICAgICAgICAgICBjb2xhLnB1dCgo
:::J2xvZycsIG0sIHQpKQoKICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAg
:::aWYgWVRfRExQIGlzIE5vbmU6CiAgICAgICAgICAgICAgICAgICAgbG9nKCd5dC1k
:::bHAgbm8gZXN0w6EgaW5zdGFsYWRvLiBFamVjdXRhICcKICAgICAgICAgICAgICAg
:::ICAgICAgICAgJ0Rlc2NhcmdhZG9yTXVzaWNhLmJhdCBwYXJhIGluc3RhbGFybG8u
:::JywgJ2Vycm9yJykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2VzdGlt
:::YWNpb24nLCAneXQtZGxwIG5vIGRpc3BvbmlibGUnKSkKICAgICAgICAgICAgICAg
:::ICAgICByZXR1cm4KICAgICAgICAgICAgICAgIGxvZygnT2J0ZW5pZW5kbyBpbmZv
:::cm1hY2nDs24gZGVsIHZpZGVvLi4uJywgJ2dyaXMnKQogICAgICAgICAgICAgICAg
:::byA9IHsncXVpZXQnOiBUcnVlLCAnbm9fd2FybmluZ3MnOiBUcnVlLCAnbm9wbGF5
:::bGlzdCc6IFRydWUsCiAgICAgICAgICAgICAgICAgICAgICdzb2NrZXRfdGltZW91
:::dCc6IDMwLCAnbG9nZ2VyJzogUkVHSVNUUk99CiAgICAgICAgICAgICAgICBpZiBl
:::c191cmxfcGxheWxpc3QoY2ZnWyd1cmwnXSk6CiAgICAgICAgICAgICAgICAgICAg
:::bG9nKCcobGEgVVJMIGNvbnRpZW5lIHVuYSBwbGF5bGlzdDogbGEgZXN0aW1hY2nD
:::s24gZXMgJwogICAgICAgICAgICAgICAgICAgICAgICAnc29sbyBkZWwgdmlkZW8g
:::cGVnYWRvKScsICdncmlzJykKICAgICAgICAgICAgICAgIHdpdGggWVRfRExQLllv
:::dXR1YmVETChvKSBhcyB5ZGw6CiAgICAgICAgICAgICAgICAgICAgaW5mbyA9IHlk
:::bC5leHRyYWN0X2luZm8oY2ZnWyd1cmwnXSwgZG93bmxvYWQ9RmFsc2UpCiAgICAg
:::ICAgICAgICAgICBkdXIgPSBpbmZvLmdldCgnZHVyYXRpb24nKQogICAgICAgICAg
:::ICAgICAgaWYgbm90IGR1cjoKICAgICAgICAgICAgICAgICAgICBsb2coJ05vIHNl
:::IHB1ZG8gb2J0ZW5lciBsYSBkdXJhY2nDs24gZGVsIHZpZGVvLicsICdlcnJvcicp
:::CiAgICAgICAgICAgICAgICAgICAgY29sYS5wdXQoKCdlc3RpbWFjaW9uJywgJ1Np
:::biBkYXRvcyBwYXJhIGVzdGltYXInKSkKICAgICAgICAgICAgICAgICAgICByZXR1
:::cm4KICAgICAgICAgICAgICAgIGNsYXZlID0gc2VsZi5fZm10X2FjdHVhbF9zb2xv
:::KEFKVVNURVMuZ2V0KCdmb3JtYXRvJywgJ0FBQycpKQogICAgICAgICAgICAgICAg
:::dGFtID0gZXN0aW1hcl9ieXRlcyhkdXIsIGNsYXZlLCBBSlVTVEVTLmdldCgnY2Fs
:::aWRhZCcpLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBib29s
:::KEFKVVNURVMuZ2V0KCdlbWJlYmVyJywgVHJ1ZSkpKQogICAgICAgICAgICAgICAg
:::dGl0dWxvID0gc3RyKGluZm8uZ2V0KCd0aXRsZScpIG9yICcnKVs6NzBdCiAgICAg
:::ICAgICAgICAgICBpZiB0aXR1bG86CiAgICAgICAgICAgICAgICAgICAgbG9nKCfi
:::maogJyArIHRpdHVsbywgJ3RpdHVsbycpCiAgICAgICAgICAgICAgICB0ZXh0byA9
:::IChmJ357dGFtIC8gMTA0ODU3NjouMWZ9IE1CIMK3ICcKICAgICAgICAgICAgICAg
:::ICAgICAgICAgIGYnZHVyYWNpw7NuIHtmbXRfdGllbShkdXIpfSDCtyAnCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICBmJ3tjbGF2ZX0ge0FKVVNURVMuZ2V0KCJjYWxp
:::ZGFkIiwgIiIpfScucnN0cmlwKCkpCiAgICAgICAgICAgICAgICBjb2xhLnB1dCgo
:::J2VzdGltYWNpb24nLCB0ZXh0bykpCiAgICAgICAgICAgICAgICBsb2coJ0VzdGlt
:::YWNpw7NuOiAnICsgdGV4dG8sICdvaycpCiAgICAgICAgICAgICAgICBsb2coJ0Vs
:::IHRhbWHDsW8gcmVhbCBwdWVkZSB2YXJpYXIgYWxnbyBzZWfDum4gbGEgZnVlbnRl
:::LicsCiAgICAgICAgICAgICAgICAgICAgJ2dyaXMnKQogICAgICAgICAgICBleGNl
:::cHQgRXhjZXB0aW9uIGFzIGU6CiAgICAgICAgICAgICAgICBsb2coZidObyBzZSBw
:::dWRvIGVzdGltYXI6IHtzZWxmLl9tc2dfZXJyb3IoZSl9JywgJ2Vycm9yJykKICAg
:::ICAgICAgICAgICAgIGNvbGEucHV0KCgnZXN0aW1hY2lvbicsICdObyBzZSBwdWRv
:::IGVzdGltYXInKSkKICAgICAgICAgICAgZmluYWxseToKICAgICAgICAgICAgICAg
:::IGNvbGEucHV0KCgnZmluJywgJ2VzdGltYWNpb24nLCBUcnVlLCAnJykpCgogICAg
:::ICAgIGRlZiBfZm10X2FjdHVhbF9zb2xvKHNlbGYsIGNsYXZlKToKICAgICAgICAg
:::ICAgcmV0dXJuIGNsYXZlIGlmIGNsYXZlIGluIEZPUk1BVE9TIGVsc2UgJ0FBQycK
:::CiAgICAgICAgZGVmIF9kZXNjYXJnYXJfdW5hKHNlbGYsIHVybCwgY2xhdmUsIGNh
:::bGlkYWRfYXJnLCBlbWJlYmVyLCBkZXN0aW5vLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICBjb2xhKToKICAgICAgICAgICAgIiIiRGVzY2FyZ2EgeSBjb252aWVy
:::dGUgVU5BIFVSTC4gRGV2dWVsdmUgZWwgUGF0aCBmaW5hbCBvIE5vbmUuIiIiCiAg
:::ICAgICAgICAgIGlmIGNsYXZlID09ICdXTUEnOgogICAgICAgICAgICAgICAgcmV0
:::dXJuIGRlc2Nhcmdhcl93bWEodXJsLCBjYWxpZGFkX2FyZywgZGVzdGlubywgZW1i
:::ZWJlciwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbGEp
:::WzFdCiAgICAgICAgICAgIGlmIGNsYXZlID09ICdBVkknOgogICAgICAgICAgICAg
:::ICAgcmV0dXJuIGRlc2Nhcmdhcl9hdmkodXJsLCBkZXN0aW5vLCBjb2xhKVsxXQog
:::ICAgICAgICAgICByZXR1cm4gZGVzY2FyZ2FyX2F1ZGlvKHVybCwgY2xhdmUsIGNh
:::bGlkYWRfYXJnLCBkZXN0aW5vLCBlbWJlYmVyLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgIGNvbGEpWzFdCgogICAgICAgIGRlZiBfZGVzY2FyZ2Fy
:::X3BsYXlsaXN0KHNlbGYsIHVybCwgY2xhdmUsIGNhbGlkYWRfYXJnLCBlbWJlYmVy
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRlc3Rpbm8sIGNvbGEp
:::OgogICAgICAgICAgICAiIiJCYWphIHVuYSBsaXN0YSBlbnRlcmEsIGNvbiAyIHMg
:::ZGUgZGVzY2Fuc28gZW50cmUgY2FuY2lvbmVzCiAgICAgICAgICAgIHBhcmEgbm8g
:::c2F0dXJhciBhIFlvdVR1YmUuIERldnVlbHZlIChkZXNjYXJnYWRhcywgdG90YWwp
:::LiIiIgogICAgICAgICAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAgICAg
:::ICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgICAgICAgICBsb2co
:::J0xleWVuZG8gbGEgbGlzdGEgZGUgcmVwcm9kdWNjacOzbi4uLicsICdncmlzJykK
:::ICAgICAgICAgICAgbyA9IHsncXVpZXQnOiBUcnVlLCAnbm9fd2FybmluZ3MnOiBU
:::cnVlLAogICAgICAgICAgICAgICAgICdleHRyYWN0X2ZsYXQnOiAnaW5fcGxheWxp
:::c3QnLCAnc29ja2V0X3RpbWVvdXQnOiAzMCwKICAgICAgICAgICAgICAgICAnbG9n
:::Z2VyJzogUkVHSVNUUk99CiAgICAgICAgICAgIHdpdGggWVRfRExQLllvdXR1YmVE
:::TChvKSBhcyB5ZGw6CiAgICAgICAgICAgICAgICBpbmZvID0geWRsLmV4dHJhY3Rf
:::aW5mbyh1cmwsIGRvd25sb2FkPUZhbHNlKQogICAgICAgICAgICBlbnRyYWRhcyA9
:::IGxpc3QoaW5mby5nZXQoJ2VudHJpZXMnKSBvciBbXSkKICAgICAgICAgICAgaWYg
:::bm90IGVudHJhZGFzOgogICAgICAgICAgICAgICAgbG9nKCdObyBzZSB2aW8gbmlu
:::Z3VuYSBjYW5jacOzbiBlbiBsYSBsaXN0YTsgc2UgaW50ZW50YSAnCiAgICAgICAg
:::ICAgICAgICAgICAgJ2NvbW8gdmlkZW8gc3VlbHRvLicsICdhdmlzbycpCiAgICAg
:::ICAgICAgICAgICBhcmNoaXZvID0gc2VsZi5fZGVzY2FyZ2FyX3VuYShzaW5fcGxh
:::eWxpc3QodXJsKVswXSwgY2xhdmUsCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICBjYWxpZGFkX2FyZywgZW1iZWJlciwgZGVzdGlu
:::bywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::IGNvbGEpCiAgICAgICAgICAgICAgICByZXR1cm4gKDEgaWYgYXJjaGl2byBlbHNl
:::IDApLCAxCiAgICAgICAgICAgIHRpdHVsb19wbCA9IHN0cihpbmZvLmdldCgndGl0
:::bGUnKSBvciAnbGlzdGEnKVs6NzBdCiAgICAgICAgICAgIHRvdGFsID0gbGVuKGVu
:::dHJhZGFzKQogICAgICAgICAgICBsb2coZidQbGF5bGlzdCDCq3t0aXR1bG9fcGx9
:::wrsg4oCUIHt0b3RhbH0gdsOtZGVvKHMpLicsICd0aXR1bG8nKQogICAgICAgICAg
:::ICBva2FzID0gMAogICAgICAgICAgICBmYWxsb3MgPSBbXQogICAgICAgICAgICBm
:::b3IgaSwgZSBpbiBlbnVtZXJhdGUoZW50cmFkYXMpOgogICAgICAgICAgICAgICAg
:::dSA9IHN0cihlLmdldCgnd2VicGFnZV91cmwnKSBvciBlLmdldCgndXJsJykgb3Ig
:::JycpCiAgICAgICAgICAgICAgICBpZiB1IGFuZCBub3QgdS5zdGFydHN3aXRoKCdo
:::dHRwJyk6CiAgICAgICAgICAgICAgICAgICAgdSA9ICdodHRwczovL3d3dy55b3V0
:::dWJlLmNvbS93YXRjaD92PScgKyB1CiAgICAgICAgICAgICAgICBpZiBub3QgdSBh
:::bmQgZS5nZXQoJ2lkJyk6CiAgICAgICAgICAgICAgICAgICAgdSA9ICdodHRwczov
:::L3d3dy55b3V0dWJlLmNvbS93YXRjaD92PScgKyBzdHIoZVsnaWQnXSkKICAgICAg
:::ICAgICAgICAgIHRpdCA9IHN0cihlLmdldCgndGl0bGUnKSBvciB1IG9yICc/Jylb
:::OjcwXQogICAgICAgICAgICAgICAgaWYgaToKICAgICAgICAgICAgICAgICAgICB0
:::aW1lLnNsZWVwKDIpICAgIyBkZXNjYW5zbyBlbnRyZSBjYW5jaW9uZXMKICAgICAg
:::ICAgICAgICAgIGxvZyhmJ1t7aSArIDF9L3t0b3RhbH1dIOKZqiB7dGl0fScsICd0
:::aXR1bG8nKQogICAgICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgICAg
:::IGFyY2hpdm8gPSBzZWxmLl9kZXNjYXJnYXJfdW5hKHUsIGNsYXZlLCBjYWxpZGFk
:::X2FyZywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICBlbWJlYmVyLCBkZXN0aW5vLCBjb2xhKQogICAgICAgICAgICAgICAg
:::ZXhjZXB0IEV4Y2VwdGlvbiBhcyBlMjoKICAgICAgICAgICAgICAgICAgICBhcmNo
:::aXZvID0gTm9uZQogICAgICAgICAgICAgICAgICAgIGxvZyhmJ+KcliBbe2kgKyAx
:::fS97dG90YWx9XSBGYWxsw7M6IHtzZWxmLl9tc2dfZXJyb3IoZTIpfScsCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICdlcnJvcicpCiAgICAgICAgICAgICAgICBpZiBh
:::cmNoaXZvIGFuZCBQYXRoKGFyY2hpdm8pLmV4aXN0cygpOgogICAgICAgICAgICAg
:::ICAgICAgIHRyeToKICAgICAgICAgICAgICAgICAgICAgICAgdGFtID0gZm10X3Rh
:::bShQYXRoKGFyY2hpdm8pLnN0YXQoKS5zdF9zaXplKQogICAgICAgICAgICAgICAg
:::ICAgIGV4Y2VwdCBPU0Vycm9yOgogICAgICAgICAgICAgICAgICAgICAgICB0YW0g
:::PSAnPycKICAgICAgICAgICAgICAgICAgICBsb2coZicgICDinJQge1BhdGgoYXJj
:::aGl2bykubmFtZX0gICh7dGFtfSknLCAnb2snKQogICAgICAgICAgICAgICAgICAg
:::IG9rYXMgKz0gMQogICAgICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAg
:::ICAgICBmYWxsb3MuYXBwZW5kKHRpdCkKICAgICAgICAgICAgbG9nKGYnUGxheWxp
:::c3QgdGVybWluYWRhOiB7b2thc30gZGUge3RvdGFsfSBkZXNjYXJnYWRhKHMpLics
:::CiAgICAgICAgICAgICAgICAnb2snIGlmIG5vdCBmYWxsb3MgZWxzZSAnYXZpc28n
:::KQogICAgICAgICAgICBpZiBmYWxsb3M6CiAgICAgICAgICAgICAgICBsb2coJ1Np
:::biBkZXNjYXJnYXI6ICcKICAgICAgICAgICAgICAgICAgICArICcgwrcgJy5qb2lu
:::KGZbOjQwXSBmb3IgZiBpbiBmYWxsb3NbOjhdKQogICAgICAgICAgICAgICAgICAg
:::ICsgKCcuLi4nIGlmIGxlbihmYWxsb3MpID4gOCBlbHNlICcnKSwgJ2dyaXMnKQog
:::ICAgICAgICAgICByZXR1cm4gb2thcywgdG90YWwKCiAgICAgICAgZGVmIF9oaWxv
:::X2Rlc2NhcmdhcihzZWxmLCBjZmcpOgogICAgICAgICAgICBjb2xhID0gc2VsZi5j
:::b2xhCgogICAgICAgICAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAgICAg
:::ICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgICAgICAgICB1cmwg
:::PSBjZmdbJ3VybCddCiAgICAgICAgICAgIGNsYXZlID0gc2VsZi5fZm10X2FjdHVh
:::bF9zb2xvKEFKVVNURVMuZ2V0KCdmb3JtYXRvJywgJ0FBQycpKQogICAgICAgICAg
:::ICBjYWxpZGFkID0gQUpVU1RFUy5nZXQoJ2NhbGlkYWQnLCAnMTI4aycpCiAgICAg
:::ICAgICAgIGVtYmViZXIgPSBib29sKEFKVVNURVMuZ2V0KCdlbWJlYmVyJywgVHJ1
:::ZSkpCiAgICAgICAgICAgIGRlc3Rpbm8gPSBQYXRoKG9zLnBhdGguZXhwYW5kdmFy
:::cygKICAgICAgICAgICAgICAgIHN0cihBSlVTVEVTLmdldCgnZGVzdGlubycsIF9k
:::ZXN0aW5vX3Bvcl9kZWZlY3RvKCkpKSkpCiAgICAgICAgICAgIHRyeToKICAgICAg
:::ICAgICAgICAgIGlmIFlUX0RMUCBpcyBOb25lOgogICAgICAgICAgICAgICAgICAg
:::IGxvZygneXQtZGxwIG5vIGVzdMOhIGluc3RhbGFkby4gRWplY3V0YSAnCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICdEZXNjYXJnYWRvck11c2ljYS5iYXQgcGFyYSBp
:::bnN0YWxhcmxvLicsICdlcnJvcicpCiAgICAgICAgICAgICAgICAgICAgY29sYS5w
:::dXQoKCdmaW4nLCAnZGVzY2FyZ2EnLCBGYWxzZSwKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgJ3l0LWRscCBubyBlc3TDoSBpbnN0YWxhZG8uJykpCiAgICAg
:::ICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgICAgICBkZXN0aW5vLm1r
:::ZGlyKHBhcmVudHM9VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgICAgICAgICAgICAg
:::IGlmIGNsYXZlIGluICgnRkxBQycsICdXQVYnKToKICAgICAgICAgICAgICAgICAg
:::ICBjYWxpZGFkX2FyZyA9ICcwJwogICAgICAgICAgICAgICAgZWxzZToKICAgICAg
:::ICAgICAgICAgICAgICBjYWxpZGFkX2FyZyA9IChyZS5zdWIocidbXjAtOV0nLCAn
:::Jywgc3RyKGNhbGlkYWQpKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIG9yICgnMTI4JyBpZiBjbGF2ZSA9PSAnQUFDJyBlbHNlICczMjAnKSkKICAg
:::ICAgICAgICAgICAgIGlmIGNmZy5nZXQoJ3BsYXlsaXN0Jyk6CiAgICAgICAgICAg
:::ICAgICAgICAgb2thcywgdG90YWwgPSBzZWxmLl9kZXNjYXJnYXJfcGxheWxpc3Qo
:::CiAgICAgICAgICAgICAgICAgICAgICAgIHVybCwgY2xhdmUsIGNhbGlkYWRfYXJn
:::LCBlbWJlYmVyLCBkZXN0aW5vLCBjb2xhKQogICAgICAgICAgICAgICAgICAgIGlm
:::IG9rYXMgYW5kIG9rYXMgPT0gdG90YWw6CiAgICAgICAgICAgICAgICAgICAgICAg
:::IGxvZyhmJ0NhcnBldGE6IHtkZXN0aW5vfScsICdncmlzJykKICAgICAgICAgICAg
:::ICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnZGVzY2FyZ2EnLCBUcnVlLCAn
:::JykpCiAgICAgICAgICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgICAg
:::ICAgICAgY29sYS5wdXQoKAogICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2Zp
:::bicsICdkZXNjYXJnYScsIEZhbHNlLAogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgZidTZSBkZXNjYXJnYXJvbiB7b2thc30gZGUge3RvdGFsfSBkZSBsYSAnCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAncGxheWxpc3QuIExhIFVSTCBubyBz
:::ZSBoYSBib3JyYWRvIHBvciBzaSAnCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAncXVpZXJlcyByZWludGVudGFybG8uJykpCiAgICAgICAgICAgICAgICAgICAg
:::cmV0dXJuCiAgICAgICAgICAgICAgICBhcmNoaXZvID0gc2VsZi5fZGVzY2FyZ2Fy
:::X3VuYShzaW5fcGxheWxpc3QodXJsKVswXSwgY2xhdmUsCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjYWxpZGFkX2FyZywgZW1i
:::ZWJlciwgZGVzdGlubywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIGNvbGEpCiAgICAgICAgICAgICAgICBpZiBhcmNoaXZvIGFu
:::ZCBQYXRoKGFyY2hpdm8pLmV4aXN0cygpOgogICAgICAgICAgICAgICAgICAgIGFy
:::Y2hpdm8gPSBQYXRoKGFyY2hpdm8pCiAgICAgICAgICAgICAgICAgICAgdHJ5Ogog
:::ICAgICAgICAgICAgICAgICAgICAgICB0YW0gPSBmbXRfdGFtKGFyY2hpdm8uc3Rh
:::dCgpLnN0X3NpemUpCiAgICAgICAgICAgICAgICAgICAgZXhjZXB0IE9TRXJyb3I6
:::CiAgICAgICAgICAgICAgICAgICAgICAgIHRhbSA9ICc/JwogICAgICAgICAgICAg
:::ICAgICAgIGxvZyhmJ+KclCDCoUxpc3RvISAge2FyY2hpdm8ubmFtZX0gICh7dGFt
:::fSknLCAnb2snKQogICAgICAgICAgICAgICAgICAgIGxvZyhmJ0NhcnBldGE6IHth
:::cmNoaXZvLnBhcmVudH0nLCAnZ3JpcycpCiAgICAgICAgICAgICAgICAgICAgY29s
:::YS5wdXQoKCdmaW4nLCAnZGVzY2FyZ2EnLCBUcnVlLCAnJykpCiAgICAgICAgICAg
:::ICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgIGxvZygnRWwgYXJjaGl2byBm
:::aW5hbCBubyBhcGFyZWNpw7MgZG9uZGUgc2UgZXNwZXJhYmEuJywKICAgICAgICAg
:::ICAgICAgICAgICAgICAgJ2Vycm9yJykKICAgICAgICAgICAgICAgICAgICBjb2xh
:::LnB1dCgoJ2ZpbicsICdkZXNjYXJnYScsIEZhbHNlLCAnJykpCiAgICAgICAgICAg
:::IGV4Y2VwdCBFeGNlcHRpb24gYXMgZToKICAgICAgICAgICAgICAgIG5vbWJyZV9l
:::eGMgPSB0eXBlKGUpLl9fbmFtZV9fCiAgICAgICAgICAgICAgICBpZiBub21icmVf
:::ZXhjID09ICdEb3dubG9hZEVycm9yJzoKICAgICAgICAgICAgICAgICAgICBsaW5l
:::YXMgPSBbbCBmb3IgbCBpbiBzdHIoZSkuc3RyaXAoKS5zcGxpdGxpbmVzKCkgaWYg
:::bC5zdHJpcCgpXQogICAgICAgICAgICAgICAgICAgIG1zZyA9IGxpbmVhc1swXVs6
:::MzAwXSBpZiBsaW5lYXMgZWxzZSAnZXJyb3IgZGVzY29ub2NpZG8nCiAgICAgICAg
:::ICAgICAgICAgICAgbG9nKCfinJYgTm8gc2UgcHVkbyBkZXNjYXJnYXI6ICcgKyBt
:::c2csICdlcnJvcicpCiAgICAgICAgICAgICAgICAgICAgbG9nKCdDb25zZWpvczog
:::cmV2aXNhIGxhIFVSTCB5IHR1IGNvbmV4acOzbjsgc2kgWW91VHViZSAnCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICdjYW1iacOzIGFsZ28sIHB1bHNhIEN0cmwrVSAo
:::YWN0dWFsaXphciB5dC1kbHApIHkgJwogICAgICAgICAgICAgICAgICAgICAgICAn
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
