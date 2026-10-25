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
title MusikALAN v2.5
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
echo    %C_TIT%MusikALAN v2.5%C_FIN% - preparando el entorno
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
title MusikALAN v2.5 - YouTube a AAC/MP3/FLAC/WAV/WMA/AVI
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
:::ZmlqbyAiIC0gVG9waWMiLCBhbGJ1bSwgdGl0dWxvLCBhbm8geSBVUkwpCnBhcmEg
:::cXVlIHRvZG9zIGxvcyByZXByb2R1Y3RvcmVzIGxhcyBtdWVzdHJlbiwgeSBsYSBj
:::YXJhdHVsYSBTSUVNUFJFCnNlIGluY3J1c3RhIGVuIEpQRUc6IGxhIG1pbmlhdHVy
:::YSBkZSBZb3VUdWJlIHZpZW5lIGVuIFdlYlAgeSBtdWNob3MKcmVwcm9kdWN0b3Jl
:::cyBiYXJhdG9zIHNvbG8gbGVlbiBKUEVHIChpZ3VhbCBxdWUgLS1jb252ZXJ0LXRo
:::dW1ibmFpbHMKanBnIGRlbCBjb21hbmRvIGFudGlndW8sIHF1ZSBlcyBsbyBxdWUg
:::c2kgZnVuY2lvbmFiYSkuCgpVc286ICBweXRob24gZGVzY2FyZ2Fkb3IucHkgICAo
:::byBkb2JsZSBjbGljIGVuIERlc2NhcmdhZG9yTXVzaWNhLmJhdCkKU2kgbGEgVVJM
:::IHBlcnRlbmVjZSBhIHVuYSBsaXN0YSBkZSByZXByb2R1Y2Npb24sIGVsIHByb2dy
:::YW1hIHByZWd1bnRhCnNpIGJhamFyIHNvbG8gbGEgY2FuY2lvbiBwZWdhZGEgbyBs
:::YSBwbGF5bGlzdCBjb21wbGV0YSAoY29uIHVuYSBwYXVzYQpkZSAyIHMgZW50cmUg
:::Y2FuY2lvbmVzIHBhcmEgbm8gc2F0dXJhciBhIFlvdVR1YmUpLgoiIiIKCmltcG9y
:::dCBqc29uCmltcG9ydCBvcwppbXBvcnQgcXVldWUKaW1wb3J0IHJlCmltcG9ydCBz
:::aHV0aWwKaW1wb3J0IHN1YnByb2Nlc3MKaW1wb3J0IHN5cwppbXBvcnQgdGVtcGZp
:::bGUKaW1wb3J0IHRocmVhZGluZwppbXBvcnQgdGltZQppbXBvcnQgdHJhY2ViYWNr
:::CmZyb20gcGF0aGxpYiBpbXBvcnQgUGF0aApmcm9tIHVybGxpYi5wYXJzZSBpbXBv
:::cnQgcGFyc2VfcXMsIHVybGVuY29kZSwgdXJscGFyc2UsIHVybHVucGFyc2UKZnJv
:::bSB1cmxsaWIucmVxdWVzdCBpbXBvcnQgdXJsb3BlbgoKQVBQX1YgPSAnMi41JwpB
:::UFBfRElSID0gUGF0aChfX2ZpbGVfXykucmVzb2x2ZSgpLnBhcmVudApSVVRBX0FK
:::VVNURVMgPSBBUFBfRElSIC8gJ2FqdXN0ZXMuanNvbicKTE9HX0VSUk9SRVMgPSBB
:::UFBfRElSIC8gJ2Rlc2NhcmdhZG9yX2Vycm9yZXMubG9nJwoKIyAtLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tIHNhbGlkYQojIEFsIGVqZWN1dGFyc2UgY29uIHB5dGhvbncuZXhlIChz
:::aW4gY29uc29sYSkgc3Rkb3V0L3N0ZGVyciBzb24gTm9uZToKIyBjdWFscXVpZXIg
:::cHJpbnQgZmFsbGFyaWEuIExvcyByZWRpcmlnaW1vcyBhIHVuIHNpdGlvIHNlZ3Vy
:::by4KdHJ5OgogICAgaWYgc3lzLnN0ZG91dCBpcyBOb25lOgogICAgICAgIHN5cy5z
:::dGRvdXQgPSBvcGVuKG9zLmRldm51bGwsICd3JywgZW5jb2Rpbmc9J3V0Zi04JykK
:::ZXhjZXB0IEV4Y2VwdGlvbjoKICAgIHBhc3MKdHJ5OgogICAgaWYgc3lzLnN0ZGVy
:::ciBpcyBOb25lOgogICAgICAgIHN5cy5zdGRlcnIgPSBvcGVuKExPR19FUlJPUkVT
:::LCAnYScsIGVuY29kaW5nPSd1dGYtOCcpCmV4Y2VwdCBFeGNlcHRpb246CiAgICBw
:::YXNzCgoKZGVmIF9yZWNvbmZpZ3VyYXJfc2FsaWRhKCk6CiAgICAiIiJFdml0YSBj
:::cmFzaGVzIHBvciBjYXJhY3RlcmVzIHJhcm9zIHNpIGxhIHNhbGlkYSBzZSByZWRp
:::cmlnZS4iIiIKICAgIGZvciBzIGluIChzeXMuc3Rkb3V0LCBzeXMuc3RkZXJyKToK
:::ICAgICAgICB0cnk6CiAgICAgICAgICAgIGlmIHMgYW5kIGhhc2F0dHIocywgJ3Jl
:::Y29uZmlndXJlJyk6CiAgICAgICAgICAgICAgICBzLnJlY29uZmlndXJlKGVycm9y
:::cz0ncmVwbGFjZScpCiAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAg
:::ICAgcGFzcwoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSB0a2ludGVyCnRyeToKICAgIGlt
:::cG9ydCB0a2ludGVyIGFzIHRrCiAgICBmcm9tIHRraW50ZXIgaW1wb3J0IGZpbGVk
:::aWFsb2csIG1lc3NhZ2Vib3gsIHR0awogICAgZnJvbSB0a2ludGVyLnNjcm9sbGVk
:::dGV4dCBpbXBvcnQgU2Nyb2xsZWRUZXh0CiAgICBUS19PSyA9IFRydWUKZXhjZXB0
:::IEV4Y2VwdGlvbjoKICAgIFRLX09LID0gRmFsc2UKCgojIC0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0gYWp1c3RlcwpkZWYgX2NhcnBldGFfbXVzaWNhKCk6CiAgICAiIiJDYXJwZXRh
:::ICdNdXNpY2EnIHJlYWwgZGVsIHVzdWFyaW8gKEZPTERFUklEX011c2ljIGRlIFdp
:::bmRvd3MpLiIiIgogICAgaWYgb3MubmFtZSA9PSAnbnQnOgogICAgICAgIHRyeToK
:::ICAgICAgICAgICAgaW1wb3J0IGN0eXBlcwoKICAgICAgICAgICAgY2xhc3MgX0dV
:::SUQoY3R5cGVzLlN0cnVjdHVyZSk6CiAgICAgICAgICAgICAgICBfZmllbGRzXyA9
:::IFsoJ0QxJywgY3R5cGVzLmNfdWxvbmcpLCAoJ0QyJywgY3R5cGVzLmNfdXNob3J0
:::KSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICgnRDMnLCBjdHlwZXMuY191
:::c2hvcnQpLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgKCdENCcsIGN0eXBl
:::cy5jX3VieXRlICogOCldCgogICAgICAgICAgICBtdXNpY2EgPSBfR1VJRCgweDRC
:::RDhENTcxLCAweDZEMTksIDB4NDhEMywKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgKGN0eXBlcy5jX3VieXRlICogOCkoMHhCRSwgMHg5NywgMHgwMywgMHgzOCwK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::MHg1RiwgMHg3RiwgMHhDNSwgMHhDRSkpCiAgICAgICAgICAgIHB0ciA9IGN0eXBl
:::cy5jX3djaGFyX3AoKQogICAgICAgICAgICBpZiBjdHlwZXMud2luZGxsLnNoZWxs
:::MzIuU0hHZXRLbm93bkZvbGRlclBhdGgoCiAgICAgICAgICAgICAgICAgICAgY3R5
:::cGVzLmJ5cmVmKG11c2ljYSksIDAsIE5vbmUsCiAgICAgICAgICAgICAgICAgICAg
:::Y3R5cGVzLmJ5cmVmKHB0cikpID09IDAgYW5kIHB0ci52YWx1ZToKICAgICAgICAg
:::ICAgICAgIHJ1dGEgPSBwdHIudmFsdWUKICAgICAgICAgICAgICAgIGN0eXBlcy53
:::aW5kbGwub2xlMzIuQ29UYXNrTWVtRnJlZShwdHIpCiAgICAgICAgICAgICAgICBy
:::ZXR1cm4gcnV0YQogICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAg
:::IHBhc3MKICAgIHJldHVybiBzdHIoUGF0aC5ob21lKCkgLyAnTXVzaWMnKQoKCmRl
:::ZiBfZGVzdGlub19hcHBkYXRhX3ZpZWpvKCk6CiAgICAiIiJDYXJwZXRhIGRlbCBw
:::cm9ncmFtYSAoZXJhIGVsIGRlc3Rpbm8gcG9yIGRlZmVjdG8gZW4gbGEgdjIuMiku
:::IiIiCiAgICBiYXNlID0gb3MuZW52aXJvbi5nZXQoJ0FQUERBVEEnKSBvciBzdHIo
:::UGF0aC5ob21lKCkgLyAnQXBwRGF0YScgLyAnUm9hbWluZycpCiAgICByZXR1cm4g
:::c3RyKFBhdGgoYmFzZSkgLyAnTXVzaWtBTEFOJykKCgpkZWYgX2Rlc3Rpbm9fcG9y
:::X2RlZmVjdG8oKToKICAgICIiIkxvcyBhcmNoaXZvcyBzZSBndWFyZGFuIGVuIGxh
:::IGNhcnBldGEgTXVzaWNhIGRlbCB1c3VhcmlvLiIiIgogICAgcmV0dXJuIF9jYXJw
:::ZXRhX211c2ljYSgpCgoKQUpVU1RFU19ERUZFQ1RPID0gewogICAgJ2Rlc3Rpbm8n
:::OiBfZGVzdGlub19wb3JfZGVmZWN0bygpLAogICAgJ3RlbWEnOiAnT3NjdXJvJywK
:::ICAgICdmb3JtYXRvJzogJ0FBQycsCiAgICAnY2FsaWRhZCc6ICcxMjhrJywKICAg
:::ICdlbWJlYmVyJzogVHJ1ZSwKfQoKCmRlZiBjYXJnYXJfYWp1c3RlcygpOgogICAg
:::YSA9IGRpY3QoQUpVU1RFU19ERUZFQ1RPKQogICAgdHJ5OgogICAgICAgIGEudXBk
:::YXRlKGpzb24ubG9hZHMoUlVUQV9BSlVTVEVTLnJlYWRfdGV4dChlbmNvZGluZz0n
:::dXRmLTgnKSkpCiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHBhc3MKICAg
:::IGEucG9wKCduYXZlZ2Fkb3InLCBOb25lKSAgIyB2Mi4yIG8gYW50ZXJpb3I6IGxh
:::IHNlY2Npb24gZGUgY29va2llcyB5YSBubyBleGlzdGUKICAgICMgbWlncmFjaW9u
:::ZXMgZGVsIGRlc3Rpbm8gZGUgZ3VhcmRhZG86CiAgICAjICDCtyB2Mi4wLzIuMSB1
:::c2FiYSBNdXNpYy9ZVERvd25sb2FkZXIKICAgICMgIMK3IHYyLjIgdXNhYmEgbGEg
:::Y2FycGV0YSBkZWwgcHJvZ3JhbWEgKEFwcERhdGFcUm9hbWluZ1xNdXNpa0FMQU4p
:::CiAgICAjIERlc2RlIGxhIHYyLjMgZWwgZGVzdGlubyBwb3IgZGVmZWN0byBlcyBs
:::YSBjYXJwZXRhIE11c2ljYSBkZWwgdXN1YXJpbywKICAgICMgYXNpIHF1ZSBzaSBl
:::bCBhanVzdGUgYXB1bnRhIGEgY3VhbHF1aWVyYSBkZSBsb3MgZG9zLCBzZSBhY3R1
:::YWxpemEuCiAgICBkZXN0aW5vID0gc3RyKGEuZ2V0KCdkZXN0aW5vJykgb3IgJycp
:::LnJlcGxhY2UoJ1xcJywgJy8nKS5yc3RyaXAoJy8nKS5sb3dlcigpCiAgICBpZiAn
:::eXRkb3dubG9hZGVyJyBpbiBkZXN0aW5vOgogICAgICAgIGFbJ2Rlc3Rpbm8nXSA9
:::IEFKVVNURVNfREVGRUNUT1snZGVzdGlubyddCiAgICBlbHNlOgogICAgICAgIHZp
:::ZWpvID0gX2Rlc3Rpbm9fYXBwZGF0YV92aWVqbygpLnJlcGxhY2UoJ1xcJywgJy8n
:::KS5yc3RyaXAoJy8nKS5sb3dlcigpCiAgICAgICAgaWYgZGVzdGlubyBhbmQgKGRl
:::c3Rpbm8gPT0gdmllam8KICAgICAgICAgICAgICAgICAgICAgICAgb3IgZGVzdGlu
:::by5zdGFydHN3aXRoKHZpZWpvICsgJy8nKSk6CiAgICAgICAgICAgIGFbJ2Rlc3Rp
:::bm8nXSA9IEFKVVNURVNfREVGRUNUT1snZGVzdGlubyddCiAgICByZXR1cm4gYQoK
:::CmRlZiBndWFyZGFyX2FqdXN0ZXMoKToKICAgIHRyeToKICAgICAgICBSVVRBX0FK
:::VVNURVMud3JpdGVfdGV4dCgKICAgICAgICAgICAganNvbi5kdW1wcyhBSlVTVEVT
:::LCBlbnN1cmVfYXNjaWk9RmFsc2UsIGluZGVudD0yKSwKICAgICAgICAgICAgZW5j
:::b2Rpbmc9J3V0Zi04JykKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgcGFz
:::cwoKCkFKVVNURVMgPSBjYXJnYXJfYWp1c3RlcygpCgoKIyAtLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tIHV0aWxzCmRlZiBmbXRfdGFtKG4pOgogICAgaWYgbm90IG46CiAgICAgICAg
:::cmV0dXJuICfigJQnCiAgICBuID0gZmxvYXQobikKICAgIGZvciB1IGluICgnQics
:::ICdLaUInLCAnTWlCJywgJ0dpQicpOgogICAgICAgIGlmIG4gPCAxMDI0IG9yIHUg
:::PT0gJ0dpQic6CiAgICAgICAgICAgIHJldHVybiBmJ3tpbnQobil9IHt1fScgaWYg
:::dSA9PSAnQicgZWxzZSBmJ3tuOi4xZn0ge3V9JwogICAgICAgIG4gLz0gMTAyNAoK
:::CmRlZiBmbXRfdGllbShzKToKICAgIGlmIHMgaXMgTm9uZToKICAgICAgICByZXR1
:::cm4gJ+KAlCcKICAgIHMgPSBpbnQocykKICAgIGgsIHIgPSBkaXZtb2QocywgMzYw
:::MCkKICAgIG0sIHggPSBkaXZtb2QociwgNjApCiAgICByZXR1cm4gZid7aH06e206
:::MDJkfTp7eDowMmR9JyBpZiBoIGVsc2UgZid7bTowMmR9Ont4OjAyZH0nCgoKZGVm
:::IGxpbXBpYXJfbm9tYnJlKHQpOgogICAgdCA9IHJlLnN1YihyJ1s8PjoiL1xcfD8q
:::XHgwMC1ceDFmXScsICdfJywgc3RyKHQpKS5zdHJpcCgnIC4nKQogICAgcmV0dXJu
:::IHRbOjE1MF0gb3IgJ3Npbl90aXR1bG8nCgoKZGVmIHNpbl9wbGF5bGlzdCh1cmwp
:::OgogICAgIiIiUXVpdGEgZWwgcGFyw6FtZXRybyBsaXN0PSBkZSBsYSBVUkwgKG1v
:::ZG8gc29sbyB2aWRlbykuIiIiCiAgICB0cnk6CiAgICAgICAgcCA9IHVybHBhcnNl
:::KHVybCkKICAgICAgICBxID0gcGFyc2VfcXMocC5xdWVyeSkKICAgICAgICBpZiAn
:::bGlzdCcgaW4gcToKICAgICAgICAgICAgZGVsIHFbJ2xpc3QnXQogICAgICAgICAg
:::ICByZXR1cm4gdXJsdW5wYXJzZShwLl9yZXBsYWNlKHF1ZXJ5PXVybGVuY29kZShx
:::LCBkb3NlcT1UcnVlKSkpLCBUcnVlCiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAg
:::ICAgIHBhc3MKICAgIHJldHVybiB1cmwsIEZhbHNlCgoKZGVmIGVzX3VybF9wbGF5
:::bGlzdCh1cmwpOgogICAgIiIiVHJ1ZSBzaSBsYSBVUkwgcGVydGVuZWNlIGEgdW5h
:::IGxpc3RhIGRlIHJlcHJvZHVjY2nDs24gKGxsZXZhIGxpc3Q9KS4iIiIKICAgIHRy
:::eToKICAgICAgICByZXR1cm4gJ2xpc3QnIGluIHBhcnNlX3FzKHVybHBhcnNlKHVy
:::bCkucXVlcnkpCiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHJldHVybiBG
:::YWxzZQoKCmRlZiBlc19zb2xvX2xpc3RhKHVybCk6CiAgICAiIiJUcnVlIHNpIGxh
:::IFVSTCBlcyB1bmEgcGxheWxpc3QgcHVyYSwgc2luIHZpZGVvIGluZGl2aWR1YWwg
:::KHNpbiB2PSkuIiIiCiAgICB0cnk6CiAgICAgICAgcCA9IHVybHBhcnNlKHVybCkK
:::ICAgICAgICBpZiAndicgaW4gcGFyc2VfcXMocC5xdWVyeSkgb3IgJ3lvdXR1LmJl
:::JyBpbiAocC5uZXRsb2Mgb3IgJycpOgogICAgICAgICAgICByZXR1cm4gRmFsc2UK
:::ICAgICAgICByZXR1cm4gKHAucGF0aCBvciAnJykucnN0cmlwKCcvJykuZW5kc3dp
:::dGgoJy9wbGF5bGlzdCcpCiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHJl
:::dHVybiBGYWxzZQoKCmRlZiBhYnJpcl9jYXJwZXRhKHJ1dGEpOgogICAgdHJ5Ogog
:::ICAgICAgIGlmIG9zLm5hbWUgPT0gJ250JzoKICAgICAgICAgICAgb3Muc3RhcnRm
:::aWxlKHN0cihydXRhKSkgICMgbm9xYTogc29sbyBXaW5kb3dzCiAgICAgICAgZWxz
:::ZToKICAgICAgICAgICAgc3VicHJvY2Vzcy5Qb3BlbihbJ3hkZy1vcGVuJywgc3Ry
:::KHJ1dGEpXSkKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgcGFzcwoKCiMg
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLSBmZm1wZWcKZGVmIGJ1c2Nhcl9mZm1wZWcoKToKICAg
:::IGV4ZSA9IHNodXRpbC53aGljaCgnZmZtcGVnJykKICAgIGlmIGV4ZToKICAgICAg
:::ICByZXR1cm4gUGF0aChleGUpCiAgICBjYW5kaWRhdG9zID0gWwogICAgICAgIEFQ
:::UF9ESVIgLyAnZmZtcGVnJyAvICdiaW4nIC8gJ2ZmbXBlZy5leGUnLAogICAgICAg
:::IEFQUF9ESVIgLyAnZmZtcGVnJyAvICdiaW4nIC8gJ2ZmbXBlZycsCiAgICAgICAg
:::QVBQX0RJUiAvICdydW50aW1lJyAvICdmZm1wZWcuZXhlJywKICAgIF0KICAgIGZv
:::ciBwIGluIGNhbmRpZGF0b3M6CiAgICAgICAgaWYgcC5leGlzdHMoKToKICAgICAg
:::ICAgICAgcmV0dXJuIHAKICAgIHJldHVybiBOb25lCgoKZGVmIGJ1c2Nhcl9mZnBy
:::b2JlKGZmbXBlZyk6CiAgICBpZiBmZm1wZWcgaXMgTm9uZToKICAgICAgICByZXR1
:::cm4gc2h1dGlsLndoaWNoKCdmZnByb2JlJykKICAgIHAgPSBmZm1wZWcud2l0aF9u
:::YW1lKCdmZnByb2JlLmV4ZScgaWYgb3MubmFtZSA9PSAnbnQnIGVsc2UgJ2ZmcHJv
:::YmUnKQogICAgaWYgcC5leGlzdHMoKToKICAgICAgICByZXR1cm4gcAogICAgcmV0
:::dXJuIHNodXRpbC53aGljaCgnZmZwcm9iZScpCgoKWVRfRExQID0gTm9uZSAgICMg
:::bcOzZHVsbyB5dF9kbHA7IHNlIHJlbGxlbmEgZW4gY29tcHJvYmFyX2VudG9ybm8o
:::KQpGRk1QRUcgPSBOb25lICAgIyBydXRhIGRlIGZmbXBlZwpGRlBST0JFID0gTm9u
:::ZSAgIyBydXRhIGRlIGZmcHJvYmUKCgpkZWYgY29tcHJvYmFyX2VudG9ybm8oKToK
:::ICAgIGdsb2JhbCBZVF9ETFAsIEZGTVBFRywgRkZQUk9CRQogICAgdHJ5OgogICAg
:::ICAgIGltcG9ydCB5dF9kbHAgYXMgbW9kCiAgICAgICAgWVRfRExQID0gbW9kCiAg
:::ICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHBhc3MKICAgIEZGTVBFRyA9IGJ1
:::c2Nhcl9mZm1wZWcoKQogICAgRkZQUk9CRSA9IGJ1c2Nhcl9mZnByb2JlKEZGTVBF
:::RykKCgpjbGFzcyBSZWdpc3RybzoKICAgICIiIkxvZ2dlciBwYXJhIHl0LWRscDog
:::cmVlbnbDrWEgYXZpc29zL2Vycm9yZXMgYWwgcmVnaXN0cm8gZGUgbGEgR1VJLiIi
:::IgoKICAgIGRlZiBfX2luaXRfXyhzZWxmKToKICAgICAgICBzZWxmLmxvZyA9IE5v
:::bmUgICMgbGEgR1VJIGxvIGNvbmVjdGE6IGxvZyhtZW5zYWplLCBldGlxdWV0YSkK
:::CiAgICBkZWYgZGVidWcoc2VsZiwgbSk6CiAgICAgICAgcGFzcwoKICAgICMgQXZp
:::c29zIGludGVybm9zIGRlIHl0LWRscCBxdWUgc29sbyBtZXRlbiBydWlkbyBlbiBl
:::bCByZWdpc3RybzoKICAgIEFWSVNPU19SVUlET1NPUyA9ICgnTm8gc3VwcG9ydGVk
:::IEphdmFTY3JpcHQgcnVudGltZScsICdFSlMnKQoKICAgIGRlZiB3YXJuaW5nKHNl
:::bGYsIG0pOgogICAgICAgIG0gPSBzdHIobSkuc3RyaXAoKQogICAgICAgIGlmIG5v
:::dCBtIG9yIGFueSh4IGluIG0gZm9yIHggaW4gc2VsZi5BVklTT1NfUlVJRE9TT1Mp
:::OgogICAgICAgICAgICByZXR1cm4KICAgICAgICBpZiBzZWxmLmxvZzoKICAgICAg
:::ICAgICAgc2VsZi5sb2cobSwgJ2F2aXNvJykKCiAgICBkZWYgZXJyb3Ioc2VsZiwg
:::bSk6CiAgICAgICAgbSA9IHN0cihtKS5zdHJpcCgpCiAgICAgICAgaWYgbSBhbmQg
:::c2VsZi5sb2c6CiAgICAgICAgICAgIHNlbGYubG9nKG0sICdlcnJvcicpCgoKUkVH
:::SVNUUk8gPSBSZWdpc3RybygpCgpOT01CUkVTX1BQID0gewogICAgJ0ZGbXBlZ0V4
:::dHJhY3RBdWRpbyc6ICdDb252aXJ0aWVuZG8gZWwgYXVkaW8gY29uIEZGbXBlZycs
:::CiAgICAnRkZtcGVnVGh1bWJuYWlsc0NvbnZlcnRvcic6ICdDb252aXJ0aWVuZG8g
:::bGEgY2Fyw6F0dWxhIGEgSlBHJywKICAgICdGRm1wZWdNZXRhZGF0YSc6ICdFc2Ny
:::aWJpZW5kbyBldGlxdWV0YXMgKHTDrXR1bG8vYXJ0aXN0YSknLAogICAgJ0VtYmVk
:::VGh1bWJuYWlsJzogJ0luY3J1c3RhbmRvIGxhIGNhcsOhdHVsYScsCiAgICAnTW92
:::ZUZpbGVzJzogJ09yZ2FuaXphbmRvIGFyY2hpdm9zJywKICAgICdGRm1wZWdNZXJn
:::ZXInOiAnVW5pZW5kbyBwaXN0YXMgZGUgdmlkZW8geSBhdWRpbycsCiAgICAnRkZt
:::cGVnVmlkZW9Db252ZXJ0b3InOiAnQ29udmlydGllbmRvIGVsIHZpZGVvJywKfQoK
:::IyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tIGZvcm1hdG9zCkZPUk1BVE9TID0gewogICAgJ0FB
:::Qyc6IGRpY3QodGV4dG89J0FBQyAoLm00YSknLCBleHQ9J200YScsCiAgICAgICAg
:::ICAgICAgICBjYWxpZGFkZXM9Wyc5NmsnLCAnMTI4ayddLCBkZWZlY3RvPScxMjhr
:::JyksCiAgICAnTVAzJzogZGljdCh0ZXh0bz0nTVAzICgubXAzKScsIGV4dD0nbXAz
:::JywKICAgICAgICAgICAgICAgIGNhbGlkYWRlcz1bJzk2aycsICcxMjhrJywgJzE5
:::MmsnLCAnMjU2aycsICczMjBrJ10sCiAgICAgICAgICAgICAgICBkZWZlY3RvPScz
:::MjBrJyksCiAgICAnRkxBQyc6IGRpY3QodGV4dG89J0ZMQUMgKC5mbGFjKScsIGV4
:::dD0nZmxhYycsCiAgICAgICAgICAgICAgICAgY2FsaWRhZGVzPVsnc2luIHBlcmRp
:::ZGEnXSwgZGVmZWN0bz0nc2luIHBlcmRpZGEnKSwKICAgICdXQVYnOiBkaWN0KHRl
:::eHRvPSdXQVYgKC53YXYpJywgZXh0PSd3YXYnLAogICAgICAgICAgICAgICAgY2Fs
:::aWRhZGVzPVsnc2luIHBlcmRpZGEnXSwgZGVmZWN0bz0nc2luIHBlcmRpZGEnKSwK
:::ICAgICdXTUEnOiBkaWN0KHRleHRvPSdXTUEgKC53bWEpJywgZXh0PSd3bWEnLAog
:::ICAgICAgICAgICAgICAgY2FsaWRhZGVzPVsnOTZrJywgJzEyOGsnXSwgZGVmZWN0
:::bz0nMTI4aycpLAogICAgJ0FWSSc6IGRpY3QodGV4dG89J0FWSSAtIHNoZWlqdSAx
:::LjgiICgxMjh4MTYwKScsIGV4dD0nYXZpJywKICAgICAgICAgICAgICAgIGNhbGlk
:::YWRlcz1bJzEyOHgxNjAgwrcgMTYgZnBzJ10sIGRlZmVjdG89JzEyOHgxNjAgwrcg
:::MTYgZnBzJyksCn0KCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gcHJvZ3Jlc28KZGVmIGhv
:::b2tzX2d1aShjb2xhKToKICAgICIiIkNyZWEgbG9zIGhvb2tzIGRlIHl0LWRscCBx
:::dWUgcHVibGljYW4gZXZlbnRvcyBlbiBsYSBjb2xhIGRlIGxhIEdVSS4iIiIKICAg
:::IGVzdGFkbyA9IHsndGl0dWxvJzogRmFsc2UsICdwcF91bHQnOiBOb25lfQoKICAg
:::IGRlZiBsb2cobSwgdD0naW5mbycpOgogICAgICAgIGNvbGEucHV0KCgnbG9nJywg
:::bSwgdCkpCgogICAgZGVmIHByb2dyZXNvKGQpOgogICAgICAgIGlmIGRbJ3N0YXR1
:::cyddID09ICdkb3dubG9hZGluZyc6CiAgICAgICAgICAgIGlmIG5vdCBlc3RhZG9b
:::J3RpdHVsbyddOgogICAgICAgICAgICAgICAgaW5mbyA9IGQuZ2V0KCdpbmZvX2Rp
:::Y3QnKSBvciB7fQogICAgICAgICAgICAgICAgdCA9IGluZm8uZ2V0KCd0aXRsZScp
:::IG9yIFBhdGgoZC5nZXQoJ2ZpbGVuYW1lJykgb3IgJycpLnN0ZW0KICAgICAgICAg
:::ICAgICAgIGlmIHQ6CiAgICAgICAgICAgICAgICAgICAgbG9nKCfimaogJyArIHN0
:::cih0KVs6OTBdLCAndGl0dWxvJykKICAgICAgICAgICAgICAgICAgICBlc3RhZG9b
:::J3RpdHVsbyddID0gVHJ1ZQogICAgICAgICAgICB0b3RhbCA9IGQuZ2V0KCd0b3Rh
:::bF9ieXRlcycpIG9yIGQuZ2V0KCd0b3RhbF9ieXRlc19lc3RpbWF0ZScpIG9yIDAK
:::ICAgICAgICAgICAgZG9uZSA9IGQuZ2V0KCdkb3dubG9hZGVkX2J5dGVzJywgMCkK
:::ICAgICAgICAgICAgdmVsID0gZC5nZXQoJ3NwZWVkJykKICAgICAgICAgICAgZXRh
:::ID0gZC5nZXQoJ2V0YScpCiAgICAgICAgICAgIGlmIHRvdGFsOgogICAgICAgICAg
:::ICAgICAgcGN0ID0gZG9uZSAvIHRvdGFsICogMTAwCiAgICAgICAgICAgICAgICB0
:::ZXh0byA9IGYne3BjdDo1LjFmfSUgwrcge2ZtdF90YW0oZG9uZSl9IC8ge2ZtdF90
:::YW0odG90YWwpfScKICAgICAgICAgICAgICAgIGlmIHZlbDoKICAgICAgICAgICAg
:::ICAgICAgICB0ZXh0byArPSBmJyDCtyB7Zm10X3RhbSh2ZWwpfS9zJwogICAgICAg
:::ICAgICAgICAgaWYgZXRhIGlzIG5vdCBOb25lOgogICAgICAgICAgICAgICAgICAg
:::IHRleHRvICs9IGYnIMK3IHF1ZWRhbiB7Zm10X3RpZW0oZXRhKX0nCiAgICAgICAg
:::ICAgICAgICBjb2xhLnB1dCgoJ3Byb2cnLCBwY3QsIHRleHRvKSkKICAgICAgICAg
:::ICAgZWxzZToKICAgICAgICAgICAgICAgIHYgPSBmJ3tmbXRfdGFtKHZlbCl9L3Mn
:::IGlmIHZlbCBlbHNlICcnCiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ3Byb2cn
:::LCBOb25lLCBmJ3tmbXRfdGFtKGRvbmUpfSDCtyB7dn0nKSkKICAgICAgICBlbGlm
:::IGRbJ3N0YXR1cyddID09ICdmaW5pc2hlZCc6CiAgICAgICAgICAgIGVzdGFkb1sn
:::cHBfdWx0J10gPSBOb25lCiAgICAgICAgICAgIGNvbGEucHV0KCgnbG9nJywgJ0Rl
:::c2NhcmdhIHJlY2liaWRhLiBQcm9jZXNhbmRvLi4uJywgJ2dyaXMnKSkKICAgICAg
:::ICAgICAgY29sYS5wdXQoKCdwcm9nJywgMCwgJ1Byb2Nlc2FuZG8uLi4nKSkKCiAg
:::ICBkZWYgcG9zdHByb2Nlc28oZCk6CiAgICAgICAgaWYgZFsnc3RhdHVzJ10gPT0g
:::J3N0YXJ0ZWQnOgogICAgICAgICAgICBub20gPSAoZC5nZXQoJ3Bvc3Rwcm9jZXNz
:::b3JfbmFtZScpCiAgICAgICAgICAgICAgICAgICBvciBkLmdldCgncG9zdHByb2Nl
:::c3NvcicpIG9yICdQb3N0cHJvY2VzbycpCiAgICAgICAgICAgIGlmIG5vbSA9PSBl
:::c3RhZG9bJ3BwX3VsdCddOgogICAgICAgICAgICAgICAgcmV0dXJuICAjIHl0LWRs
:::cCBhIHZlY2VzIGFudW5jaWEgZWwgbWlzbW8gcGFzbyBkb3MgdmVjZXMKICAgICAg
:::ICAgICAgZXN0YWRvWydwcF91bHQnXSA9IG5vbQogICAgICAgICAgICB0ZXh0byA9
:::IE5PTUJSRVNfUFAuZ2V0KG5vbSwgbm9tKSArICcuLi4nCiAgICAgICAgICAgIGNv
:::bGEucHV0KCgnbG9nJywgJ+KGkiAnICsgdGV4dG8sICdncmlzJykpCiAgICAgICAg
:::ICAgIGNvbGEucHV0KCgncHJvZycsIE5vbmUsIHRleHRvKSkKCiAgICByZXR1cm4g
:::cHJvZ3Jlc28sIHBvc3Rwcm9jZXNvCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIG9wY2lv
:::bmVzCmRlZiBvcHRzX2Jhc2UoY2FycGV0YSwgY29sYSk6CiAgICBwcm9ncmVzbywg
:::cG9zdHByb2Nlc28gPSBob29rc19ndWkoY29sYSkKICAgIG8gPSB7CiAgICAgICAg
:::J291dHRtcGwnOiBzdHIoY2FycGV0YSAvICclKHRpdGxlKXMuJShleHQpcycpLAog
:::ICAgICAgICdxdWlldCc6IFRydWUsCiAgICAgICAgJ25vX3dhcm5pbmdzJzogVHJ1
:::ZSwKICAgICAgICAnbm9wcm9ncmVzcyc6IFRydWUsCiAgICAgICAgJ25vcGxheWxp
:::c3QnOiBUcnVlLAogICAgICAgICdpZ25vcmVlcnJvcnMnOiBGYWxzZSwKICAgICAg
:::ICAncmV0cmllcyc6IDEwLAogICAgICAgICdmcmFnbWVudF9yZXRyaWVzJzogMTAs
:::CiAgICAgICAgJ3NvY2tldF90aW1lb3V0JzogMzAsCiAgICAgICAgJ2NvbmN1cnJl
:::bnRfZnJhZ21lbnRfZG93bmxvYWRzJzogNCwKICAgICAgICAnd2luZG93c2ZpbGVu
:::YW1lcyc6IFRydWUsCiAgICAgICAgJ292ZXJ3cml0ZXMnOiBGYWxzZSwKICAgICAg
:::ICAnbG9nZ2VyJzogUkVHSVNUUk8sCiAgICAgICAgJ3Byb2dyZXNzX2hvb2tzJzog
:::W3Byb2dyZXNvXSwKICAgICAgICAncG9zdHByb2Nlc3Nvcl9ob29rcyc6IFtwb3N0
:::cHJvY2Vzb10sCiAgICB9CiAgICBpZiBGRk1QRUc6CiAgICAgICAgb1snZmZtcGVn
:::X2xvY2F0aW9uJ10gPSBzdHIoRkZNUEVHLnBhcmVudCkKICAgIHJldHVybiBvCgoK
:::ZGVmIGNvbnZlcnRpcl9mZm1wZWcoY21kLCBldGlxdWV0YSwgY29sYSk6CiAgICAi
:::IiJFamVjdXRhIEZGbXBlZyAobGlzdGEgZGUgYXJndW1lbnRvcywgc2luIHNoZWxs
:::KSBjb24gbWFycXVlZS4iIiIKICAgIGNvbGEucHV0KCgncHJvZycsIE5vbmUsIGV0
:::aXF1ZXRhKSkKCiAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAgICBjb2xh
:::LnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgIHRyeToKICAgICAgICBwID0gc3VicHJv
:::Y2Vzcy5ydW4oY21kLCBzdGRvdXQ9c3VicHJvY2Vzcy5QSVBFLAogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICBzdGRlcnI9c3VicHJvY2Vzcy5QSVBFLCB0ZXh0PVRy
:::dWUsCiAgICAgICAgICAgICAgICAgICAgICAgICAgIGVuY29kaW5nPSd1dGYtOCcs
:::IGVycm9ycz0ncmVwbGFjZScpCiAgICBleGNlcHQgRmlsZU5vdEZvdW5kRXJyb3I6
:::CiAgICAgICAgcCA9IE5vbmUKICAgIGlmIHAgaXMgTm9uZSBvciBwLnJldHVybmNv
:::ZGUgIT0gMDoKICAgICAgICBsb2coJ+KcliBGRm1wZWcgZGV2b2x2acOzIHVuIGVy
:::cm9yOicsICdlcnJvcicpCiAgICAgICAgaWYgcCBpcyBub3QgTm9uZToKICAgICAg
:::ICAgICAgZm9yIGxuIGluIChwLnN0ZGVyciBvciAnJykuc3RyaXAoKS5zcGxpdGxp
:::bmVzKClbLTQ6XToKICAgICAgICAgICAgICAgIGxvZygnICAgJyArIGxuWzoxODBd
:::LCAnZ3JpcycpCiAgICAgICAgY29sYS5wdXQoKCdwcm9nJywgMCwgJycpKQogICAg
:::ICAgIHJldHVybiBGYWxzZQogICAgcmV0dXJuIFRydWUKCgpkZWYgYXJjaGl2b19m
:::aW5hbChpbmZvLCBjYXJwZXRhLCBleHQpOgogICAgIiIiTG9jYWxpemEgZWwgYXJj
:::aGl2byByZXN1bHRhbnRlICh5dC1kbHAgbG8gcmVwb3J0YTsgZmFsbGJhY2s6IG3D
:::oXMgbnVldm8pLiIiIgogICAgdHJ5OgogICAgICAgIGZvciBkIGluIChpbmZvLmdl
:::dCgncmVxdWVzdGVkX2Rvd25sb2FkcycpIG9yIFtdKToKICAgICAgICAgICAgZiA9
:::IGQuZ2V0KCdmaWxlcGF0aCcpCiAgICAgICAgICAgIGlmIGY6CiAgICAgICAgICAg
:::ICAgICByZXR1cm4gUGF0aChmKQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAg
:::ICBwYXNzCiAgICBjYW5kID0gc29ydGVkKGNhcnBldGEuZ2xvYignKi4nICsgZXh0
:::KSwKICAgICAgICAgICAgICAgICAga2V5PWxhbWJkYSBwOiBwLnN0YXQoKS5zdF9t
:::dGltZSwgcmV2ZXJzZT1UcnVlKQogICAgcmV0dXJuIGNhbmRbMF0gaWYgY2FuZCBl
:::bHNlIE5vbmUKCgpkZWYgbGltcGlhcl9taW5pYXR1cmFzKGNhcnBldGEsIGFyY2hp
:::dm8pOgogICAgIiIiQm9ycmEgbWluaWF0dXJhcyBzdWVsdGFzIHF1ZSBFbWJlZFRo
:::dW1ibmFpbCBkZWphcmEgc2luIGluY3J1c3Rhci4iIiIKICAgIGZvciBleHQgaW4g
:::KCcud2VicCcsICcuanBnJywgJy5qcGVnJywgJy5wbmcnKToKICAgICAgICB0ID0g
:::YXJjaGl2by53aXRoX3N1ZmZpeChleHQpCiAgICAgICAgaWYgdC5leGlzdHMoKToK
:::ICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgdC51bmxpbmsoKQogICAg
:::ICAgICAgICBleGNlcHQgT1NFcnJvcjoKICAgICAgICAgICAgICAgIHBhc3MKCgpk
:::ZWYgX21pbmlhdHVyYV9ieXRlcyhjYXJwZXRhLCBhcmNoaXZvKToKICAgICIiIkxl
:::ZSBsb3MgYnl0ZXMgZGUgbGEgbWluaWF0dXJhIHF1ZSB5dC1kbHAgZGVqbyBqdW50
:::byBhbCBhcmNoaXZvIGZpbmFsLiIiIgogICAgaWYgbm90IGFyY2hpdm86CiAgICAg
:::ICAgcmV0dXJuIE5vbmUKICAgIGZvciBleHQgaW4gKCcuanBnJywgJy5qcGVnJywg
:::Jy53ZWJwJywgJy5wbmcnKToKICAgICAgICB0ID0gYXJjaGl2by53aXRoX3N1ZmZp
:::eChleHQpCiAgICAgICAgaWYgdC5leGlzdHMoKToKICAgICAgICAgICAgdHJ5Ogog
:::ICAgICAgICAgICAgICAgcmV0dXJuIHQucmVhZF9ieXRlcygpCiAgICAgICAgICAg
:::IGV4Y2VwdCBPU0Vycm9yOgogICAgICAgICAgICAgICAgcGFzcwogICAgcmV0dXJu
:::IE5vbmUKCgpkZWYgX2VzX2pwZyhkYXRvcyk6CiAgICByZXR1cm4gYm9vbChkYXRv
:::cykgYW5kIGRhdG9zWzozXSA9PSBiJ1x4ZmZceGQ4XHhmZicKCgpkZWYgX2FfanBn
:::KGRhdG9zKToKICAgICIiIkNvbnZpZXJ0ZSBsb3MgYnl0ZXMgZGUgdW5hIGltYWdl
:::biAod2VicC9wbmcvLi4uKSBhIEpQRUcgY29uIEZGbXBlZy4KCiAgICBMb3MgcmVw
:::cm9kdWN0b3JlcyBiYXJhdG9zICh0aXBvIHNoZWlqdSkgc3VlbGVuIGxlZXIgc29s
:::byBKUEVHOiBsYQogICAgbWluaWF0dXJhIGRlIFlvdVR1YmUgdmllbmUgZW4gV2Vi
:::UCB5IEVtYmVkVGh1bWJuYWlsIGRlIHl0LWRscCBsYQogICAgY29udmllcnRlIGEg
:::UE5HICgiUE5HIGlzIHByZWZlcnJlZCBzaW5jZSBKUEVHIGlzIGxvc3N5IiksIGFz
:::aSBxdWUKICAgIGFxdWkgbm9zIGFzZWd1cmFtb3Mgbm9zb3Ryb3MgZGUgcXVlIGFj
:::YWJlIGVuIEpQRUcuIiIiCiAgICBpZiBub3QgZGF0b3Mgb3Igbm90IEZGTVBFRzoK
:::ICAgICAgICByZXR1cm4gTm9uZQogICAgYmFzZSA9IFBhdGgodGVtcGZpbGUuZ2V0
:::dGVtcGRpcigpKSAvICgnbXVzaWthbGFuX2NhcmF0dWxhXyVkJyAlIG9zLmdldHBp
:::ZCgpKQogICAgb3JpZ2VuLCBkZXN0aW5vID0gYmFzZS53aXRoX3N1ZmZpeCgnLm9y
:::aWcnKSwgYmFzZS53aXRoX3N1ZmZpeCgnLmpwZycpCiAgICB0cnk6CiAgICAgICAg
:::b3JpZ2VuLndyaXRlX2J5dGVzKGRhdG9zKQogICAgICAgIHIgPSBzdWJwcm9jZXNz
:::LnJ1bigKICAgICAgICAgICAgW3N0cihGRk1QRUcpLCAnLXknLCAnLWxvZ2xldmVs
:::JywgJ2Vycm9yJywgJy1pJywgc3RyKG9yaWdlbiksCiAgICAgICAgICAgICAnLXE6
:::dicsICcyJywgc3RyKGRlc3Rpbm8pXSwKICAgICAgICAgICAgc3Rkb3V0PXN1YnBy
:::b2Nlc3MuREVWTlVMTCwgc3RkZXJyPXN1YnByb2Nlc3MuREVWTlVMTCkKICAgICAg
:::ICBpZiByLnJldHVybmNvZGUgPT0gMCBhbmQgZGVzdGluby5leGlzdHMoKToKICAg
:::ICAgICAgICAganBnID0gZGVzdGluby5yZWFkX2J5dGVzKCkKICAgICAgICAgICAg
:::aWYgX2VzX2pwZyhqcGcpOgogICAgICAgICAgICAgICAgcmV0dXJuIGpwZwogICAg
:::ZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICBwYXNzCiAgICBmaW5hbGx5OgogICAg
:::ICAgIGZvciBmIGluIChvcmlnZW4sIGRlc3Rpbm8pOgogICAgICAgICAgICB0cnk6
:::CiAgICAgICAgICAgICAgICBmLnVubGluaygpCiAgICAgICAgICAgIGV4Y2VwdCBP
:::U0Vycm9yOgogICAgICAgICAgICAgICAgcGFzcwogICAgcmV0dXJuIE5vbmUKCgpk
:::ZWYgX3dtX3BpY3R1cmUoanBnLCBkZXNjcmlwY2lvbj0nJyk6CiAgICAiIiJFbXBh
:::cXVldGEgdW5vcyBieXRlcyBKUEVHIGVuIGVsIGF0cmlidXRvIFdNL1BpY3R1cmUg
:::ZGVsIGNvbnRlbmVkb3IKICAgIEFTRiAodGlwbyAzID0gcG9ydGFkYSBmcm9udGFs
:::KSwgY29tbyBoYWNpYSBlbCBzY3JpcHQgYW50aWd1by4iIiIKICAgIGRlZiB1MTYo
:::cyk6CiAgICAgICAgcmV0dXJuIHN0cihzKS5lbmNvZGUoJ3V0Zi0xNi1sZScpICsg
:::YidceDAwXHgwMCcKCiAgICBtaW1lID0gdTE2KCdpbWFnZS9qcGVnJykKICAgIGRl
:::c2MgPSB1MTYoZGVzY3JpcGNpb24pCiAgICByZXR1cm4gKGInXHgwMycgKyBsZW4o
:::bWltZSkudG9fYnl0ZXMoNCwgJ2xpdHRsZScpICsgbWltZQogICAgICAgICAgICAr
:::IGxlbihkZXNjKS50b19ieXRlcyg0LCAnbGl0dGxlJykgKyBkZXNjICsganBnKQoK
:::CiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLSBldGlxdWV0YXMKZGVmIF9hcnRpc3RhX2xpbXBp
:::byhpbmZvKToKICAgICIiIk5vbWJyZSBkZWwgYXJ0aXN0YSBsZWdpYmxlIHBhcmEg
:::cmVwcm9kdWN0b3Jlcy4KCiAgICBMb3MgY2FuYWxlcyBhdXRvbWF0aWNvcyBkZSBt
:::dXNpY2EgZGUgWW91VHViZSBzZSBsbGFtYW4gJ1ggLSBUb3BpYyc7CiAgICBlc2Ug
:::c3VmaWpvIHNvYnJhIGN1YW5kbyBzZSB2ZSBlbiBsYSBwYW50YWxsYSBkZSB1biBy
:::ZXByb2R1Y3Rvci4iIiIKICAgIGEgPSAoaW5mby5nZXQoJ2FydGlzdCcpIG9yIGlu
:::Zm8uZ2V0KCdjcmVhdG9yJykKICAgICAgICAgb3IgaW5mby5nZXQoJ3VwbG9hZGVy
:::Jykgb3IgaW5mby5nZXQoJ2NoYW5uZWwnKSBvciAnJykKICAgIGEgPSBzdHIoYSku
:::c3RyaXAoKQogICAgYSA9IHJlLnN1YihyJ1xzKi1ccypUb3BpY1xzKiQnLCAnJywg
:::YSwgZmxhZ3M9cmUuSSkuc3RyaXAoKQogICAgcmV0dXJuIGEKCgpkZWYgX2FsYnVt
:::X2RlKGluZm8pOgogICAgIiIiQWxidW0gcGFyYSBlbCBhcmNoaXZvIGZpbmFsLgoK
:::ICAgIHl0LWRscCBzb2xvIGVzY3JpYmUgYWxidW0gc2kgZWwgcHJvcGlvIHZpZGVv
:::IGxvIHRyYWUgKGNhc2kgbnVuY2EpOgogICAgcG9yIGVzbyBsb3MgcmVwcm9kdWN0
:::b3JlcyBtb3N0cmFiYW4gJ2FsYnVtIGRlc2Nvbm9jaWRvJy4gT3JkZW4gZGUKICAg
:::IHByZWZlcmVuY2lhOiBhbGJ1bSByZWFsIC0+IG5vbWJyZSBkZSBsYSBwbGF5bGlz
:::dCAtPiBhcnRpc3RhLiIiIgogICAgZm9yIGNsYXZlIGluICgnYWxidW0nLCAncGxh
:::eWxpc3RfdGl0bGUnKToKICAgICAgICB2ID0gc3RyKGluZm8uZ2V0KGNsYXZlKSBv
:::ciAnJykuc3RyaXAoKQogICAgICAgIGlmIHY6CiAgICAgICAgICAgIHJldHVybiB2
:::CiAgICByZXR1cm4gX2FydGlzdGFfbGltcGlvKGluZm8pIG9yICdZb3VUdWJlJwoK
:::CmRlZiBhcGxpY2FyX3RhZ3MoaW5mbywgYXJjaGl2bywgbG9nPU5vbmUsIGNhcmF0
:::dWxhPU5vbmUpOgogICAgIiIiRXNjcmliZSBjb24gbXV0YWdlbiBsYXMgZXRpcXVl
:::dGFzIGRlbCBhcmNoaXZvIGZpbmFsLgoKICAgIEdhcmFudGl6YSBxdWUgVE9ET1Mg
:::bG9zIHJlcHJvZHVjdG9yZXMgbXVlc3RyZW4gYXJ0aXN0YSB5IGFsYnVtLAogICAg
:::YXVucXVlIEZGbXBlZ01ldGFkYXRhIGRlIHl0LWRscCBubyBsb3MgaGF5YSBlc2Ny
:::aXRvLiBBZGVtYXM6CiAgICAgIMK3IGxhIGNhcmF0dWxhIHNpZW1wcmUgYWNhYmEg
:::ZW4gSlBFRyAoeXQtZGxwIGluY3J1c3RhIGxhcwogICAgICAgIG1pbmlhdHVyYXMg
:::ZGUgWW91VHViZSBjb21vIFBORy9XZWJQIHkgbXVjaG9zIHJlcHJvZHVjdG9yZXMK
:::ICAgICAgICBiYXJhdG9zIHNvbG8gbGVlbiBKUEVHOyBjdWFuZG8gZWwgcGFyc2Vy
:::IGRlIGxhIGNhcmF0dWxhIGZhbGxhLAogICAgICAgIGRlamFuIGRlIG1vc3RyYXIg
:::dGFtYmllbiBhcnRpc3RhIHkgYWxidW0pOwogICAgICDCtyBzaSBFbWJlZFRodW1i
:::bmFpbCBubyBpbmNydXN0byBuYWRhLCBzZSBpbmNydXN0YSBgY2FyYXR1bGFgOwog
:::ICAgICDCtyBlbCBjb21lbnRhcmlvIGd1YXJkYSBsYSBVUkwgZGVsIHZpZGVvIChj
:::b21vIGVsIHNjcmlwdCBhbnRpZ3VvKTsKICAgICAgwrcgV01BIGxsZXZhIGNhcmF0
:::dWxhIChXTS9QaWN0dXJlKSB5IFVSTCAoV00vQXV0aG9yVVJMKSB2aWEgbXV0YWdl
:::bi4KICAgIGBjYXJhdHVsYWAgc29uIGxvcyBieXRlcyBkZSBsYSBtaW5pYXR1cmEg
:::ZGVzY2FyZ2FkYSAob3BjaW9uYWwpLiIiIgogICAgdHJ5OgogICAgICAgIHAgPSBQ
:::YXRoKGFyY2hpdm8pCiAgICAgICAgaWYgbm90IHAuZXhpc3RzKCk6CiAgICAgICAg
:::ICAgIHJldHVybgogICAgICAgIGFydGlzdGEgPSBfYXJ0aXN0YV9saW1waW8oaW5m
:::bykKICAgICAgICBhbGJ1bSA9IF9hbGJ1bV9kZShpbmZvKQogICAgICAgIHRpdHVs
:::byA9IHN0cihpbmZvLmdldCgndHJhY2snKSBvciBpbmZvLmdldCgndGl0bGUnKSBv
:::ciAnJykuc3RyaXAoKQogICAgICAgIGZlY2hhID0gc3RyKGluZm8uZ2V0KCdyZWxl
:::YXNlX3llYXInKSBvciAnJykKICAgICAgICBpZiBub3QgZmVjaGE6CiAgICAgICAg
:::ICAgIGZlY2hhID0gc3RyKGluZm8uZ2V0KCd1cGxvYWRfZGF0ZScpIG9yICcnKQog
:::ICAgICAgICAgICBpZiBsZW4oZmVjaGEpID09IDggYW5kIGZlY2hhLmlzZGlnaXQo
:::KToKICAgICAgICAgICAgICAgIGZlY2hhID0gZmVjaGFbOjRdCiAgICAgICAgdXJs
:::ID0gc3RyKGluZm8uZ2V0KCd3ZWJwYWdlX3VybCcpIG9yICcnKS5zdHJpcCgpCiAg
:::ICAgICAgaWYgY2FyYXR1bGEgYW5kIG5vdCBfZXNfanBnKGNhcmF0dWxhKToKICAg
:::ICAgICAgICAgY2FyYXR1bGEgPSBfYV9qcGcoY2FyYXR1bGEpCiAgICAgICAgZXh0
:::ID0gcC5zdWZmaXgubG93ZXIoKQogICAgICAgIGlmIGV4dCA9PSAnLm00YSc6CiAg
:::ICAgICAgICAgIGZyb20gbXV0YWdlbi5tcDQgaW1wb3J0IE1QNCwgTVA0Q292ZXIK
:::ICAgICAgICAgICAgbSA9IE1QNChzdHIocCkpCiAgICAgICAgICAgIGlmIHRpdHVs
:::bzoKICAgICAgICAgICAgICAgIG1bJ1x4YTluYW0nXSA9IFt0aXR1bG9dCiAgICAg
:::ICAgICAgIGlmIGFydGlzdGE6CiAgICAgICAgICAgICAgICBtWydceGE5QVJUJ10g
:::PSBbYXJ0aXN0YV0KICAgICAgICAgICAgICAgIG1bJ2FBUlQnXSA9IFthcnRpc3Rh
:::XQogICAgICAgICAgICBpZiBhbGJ1bToKICAgICAgICAgICAgICAgIG1bJ1x4YTlh
:::bGInXSA9IFthbGJ1bV0KICAgICAgICAgICAgaWYgZmVjaGE6CiAgICAgICAgICAg
:::ICAgICBtWydceGE5ZGF5J10gPSBbZmVjaGFdCiAgICAgICAgICAgIGlmIHVybDoK
:::ICAgICAgICAgICAgICAgIG1bJ1x4YTljbXQnXSA9IFt1cmxdCiAgICAgICAgICAg
:::ICMgLS0gY2FyYXR1bGE6IGdhcmFudGl6YW1vcyBKUEVHIFNJRU1QUkUgKHRhbWJp
:::ZW4gY3VhbmRvCiAgICAgICAgICAgICMgICAgRW1iZWRUaHVtYm5haWwgeWEgaW5j
:::cnVzdG8gYWxnbyk7IGBjYXJhdHVsYWAgZXMgZWwgcGxhbiBCCiAgICAgICAgICAg
:::ICMgICAgc2kgbm8gcXVlZG8gbmluZ3VuYS4geXQtZGxwL0VtYmVkVGh1bWJuYWls
:::IHVzYSBlbCBhdG9tbwogICAgICAgICAgICAjICAgIGVzdGFuZGFyICdjb3ZyJyAo
:::c2luIGVsIHByZWZpam8gKGMpKTsgZW4gbXV0YWdlbiBtb2Rlcm5vCiAgICAgICAg
:::ICAgICMgICAgZXNjcmliaXIgJ1x4YTljb3ZyJyBsYW56YSBUeXBlRXJyb3IuCiAg
:::ICAgICAgICAgIHZpZWphcyA9IG0uZ2V0KCdjb3ZyJykgb3IgbS5nZXQoJ1x4YTlj
:::b3ZyJykgb3IgW10KICAgICAgICAgICAgaWYgbm90IHZpZWphczoKICAgICAgICAg
:::ICAgICAgIGlmIGNhcmF0dWxhOgogICAgICAgICAgICAgICAgICAgIG1bJ2NvdnIn
:::XSA9IFtNUDRDb3ZlcihjYXJhdHVsYSwgTVA0Q292ZXIuRk9STUFUX0pQRUcpXQog
:::ICAgICAgICAgICBlbGlmIGFsbChjLmltYWdlZm9ybWF0ICE9IE1QNENvdmVyLkZP
:::Uk1BVF9KUEVHCiAgICAgICAgICAgICAgICAgICAgIGZvciBjIGluIHZpZWphcyk6
:::CiAgICAgICAgICAgICAgICBudWV2YSA9IF9hX2pwZyhieXRlcyh2aWVqYXNbMF0p
:::KSBvciBjYXJhdHVsYQogICAgICAgICAgICAgICAgaWYgbnVldmE6CiAgICAgICAg
:::ICAgICAgICAgICAgbVsnY292ciddID0gW01QNENvdmVyKG51ZXZhLCBNUDRDb3Zl
:::ci5GT1JNQVRfSlBFRyldCiAgICAgICAgICAgICAgICAgICAgbS5wb3AoJ1x4YTlj
:::b3ZyJywgTm9uZSkKICAgICAgICAgICAgZWxpZiBtLmdldCgnXHhhOWNvdnInKToK
:::ICAgICAgICAgICAgICAgIG1bJ2NvdnInXSA9IHZpZWphcwogICAgICAgICAgICAg
:::ICAgbS5wb3AoJ1x4YTljb3ZyJywgTm9uZSkKICAgICAgICAgICAgbS5zYXZlKCkK
:::ICAgICAgICBlbGlmIGV4dCA9PSAnLm1wMyc6CiAgICAgICAgICAgIGZyb20gbXV0
:::YWdlbi5pZDMgaW1wb3J0IChBUElDLCBDT01NLCBJRDMsIFRBTEIsIFREUkMsIFRJ
:::VDIsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBUUEUxLCBU
:::UEUyKQogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICB0YWdzID0gSUQz
:::KHN0cihwKSkKICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAg
:::ICAgICAgIHRhZ3MgPSBJRDMoKQogICAgICAgICAgICBpZiB0aXR1bG86CiAgICAg
:::ICAgICAgICAgICB0YWdzLnNldGFsbCgnVElUMicsIFtUSVQyKGVuY29kaW5nPTMs
:::IHRleHQ9W3RpdHVsb10pXSkKICAgICAgICAgICAgaWYgYXJ0aXN0YToKICAgICAg
:::ICAgICAgICAgIHRhZ3Muc2V0YWxsKCdUUEUxJywgW1RQRTEoZW5jb2Rpbmc9Mywg
:::dGV4dD1bYXJ0aXN0YV0pXSkKICAgICAgICAgICAgICAgIHRhZ3Muc2V0YWxsKCdU
:::UEUyJywgW1RQRTIoZW5jb2Rpbmc9MywgdGV4dD1bYXJ0aXN0YV0pXSkKICAgICAg
:::ICAgICAgaWYgYWxidW06CiAgICAgICAgICAgICAgICB0YWdzLnNldGFsbCgnVEFM
:::QicsIFtUQUxCKGVuY29kaW5nPTMsIHRleHQ9W2FsYnVtXSldKQogICAgICAgICAg
:::ICBpZiBmZWNoYToKICAgICAgICAgICAgICAgIHRhZ3Muc2V0YWxsKCdURFJDJywg
:::W1REUkMoZW5jb2Rpbmc9MywgdGV4dD1bZmVjaGFdKV0pCiAgICAgICAgICAgIGlm
:::IHVybDoKICAgICAgICAgICAgICAgIHRhZ3Muc2V0YWxsKCdDT01NJywgW0NPTU0o
:::ZW5jb2Rpbmc9MywgbGFuZz0nZW5nJywKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgZGVzYz0nJywgdGV4dD1bdXJsXSldKQogICAgICAg
:::ICAgICBhcGljcyA9IHRhZ3MuZ2V0YWxsKCdBUElDJykKICAgICAgICAgICAgaWYg
:::bm90IGFwaWNzOgogICAgICAgICAgICAgICAgaWYgY2FyYXR1bGE6CiAgICAgICAg
:::ICAgICAgICAgICAgdGFncy5zZXRhbGwoJ0FQSUMnLCBbQVBJQyhlbmNvZGluZz0z
:::LCBtaW1lPSdpbWFnZS9qcGVnJywKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgIHR5cGU9MywgZGVzYz0nQ292ZXInLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YT1jYXJh
:::dHVsYSldKQogICAgICAgICAgICBlbGlmIGFsbChhLm1pbWUgIT0gJ2ltYWdlL2pw
:::ZWcnIGZvciBhIGluIGFwaWNzKToKICAgICAgICAgICAgICAgIG51ZXZhID0gX2Ff
:::anBnKGFwaWNzWzBdLmRhdGEpIG9yIGNhcmF0dWxhCiAgICAgICAgICAgICAgICBp
:::ZiBudWV2YToKICAgICAgICAgICAgICAgICAgICB0YWdzLnNldGFsbCgnQVBJQycs
:::IFtBUElDKGVuY29kaW5nPTMsIG1pbWU9J2ltYWdlL2pwZWcnLAogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZT1hcGljc1sw
:::XS50eXBlIG9yIDMsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICBkZXNjPWFwaWNzWzBdLmRlc2Mgb3IgJ0NvdmVyJywKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGE9bnVl
:::dmEpXSkKICAgICAgICAgICAgdGFncy5zYXZlKHN0cihwKSwgdjJfdmVyc2lvbj0z
:::KQogICAgICAgIGVsaWYgZXh0ID09ICcud2F2JzoKICAgICAgICAgICAgZnJvbSBt
:::dXRhZ2VuLmlkMyBpbXBvcnQgQ09NTSwgVERSQywgVElUMiwgVFBFMSwgVFBFMiwg
:::VEFMQgogICAgICAgICAgICBmcm9tIG11dGFnZW4ud2F2ZSBpbXBvcnQgV0FWRQog
:::ICAgICAgICAgICB3ID0gV0FWRShzdHIocCkpCiAgICAgICAgICAgIGlmIHcudGFn
:::cyBpcyBOb25lOgogICAgICAgICAgICAgICAgdy5hZGRfdGFncygpCiAgICAgICAg
:::ICAgIGlmIHRpdHVsbzoKICAgICAgICAgICAgICAgIHcudGFncy5zZXRhbGwoJ1RJ
:::VDInLCBbVElUMihlbmNvZGluZz0zLCB0ZXh0PVt0aXR1bG9dKV0pCiAgICAgICAg
:::ICAgIGlmIGFydGlzdGE6CiAgICAgICAgICAgICAgICB3LnRhZ3Muc2V0YWxsKCdU
:::UEUxJywgW1RQRTEoZW5jb2Rpbmc9MywgdGV4dD1bYXJ0aXN0YV0pXSkKICAgICAg
:::ICAgICAgICAgIHcudGFncy5zZXRhbGwoJ1RQRTInLCBbVFBFMihlbmNvZGluZz0z
:::LCB0ZXh0PVthcnRpc3RhXSldKQogICAgICAgICAgICBpZiBhbGJ1bToKICAgICAg
:::ICAgICAgICAgIHcudGFncy5zZXRhbGwoJ1RBTEInLCBbVEFMQihlbmNvZGluZz0z
:::LCB0ZXh0PVthbGJ1bV0pXSkKICAgICAgICAgICAgaWYgZmVjaGE6CiAgICAgICAg
:::ICAgICAgICB3LnRhZ3Muc2V0YWxsKCdURFJDJywgW1REUkMoZW5jb2Rpbmc9Mywg
:::dGV4dD1bZmVjaGFdKV0pCiAgICAgICAgICAgIGlmIHVybDoKICAgICAgICAgICAg
:::ICAgIHcudGFncy5zZXRhbGwoJ0NPTU0nLCBbQ09NTShlbmNvZGluZz0zLCBsYW5n
:::PSdlbmcnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIGRlc2M9JycsIHRleHQ9W3VybF0pXSkKICAgICAgICAgICAgdy5zYXZlKCkK
:::ICAgICAgICBlbGlmIGV4dCA9PSAnLmZsYWMnOgogICAgICAgICAgICBmcm9tIG11
:::dGFnZW4uZmxhYyBpbXBvcnQgRkxBQywgUGljdHVyZQogICAgICAgICAgICBmID0g
:::RkxBQyhzdHIocCkpCiAgICAgICAgICAgIGlmIHRpdHVsbzoKICAgICAgICAgICAg
:::ICAgIGZbJ3RpdGxlJ10gPSBbdGl0dWxvXQogICAgICAgICAgICBpZiBhcnRpc3Rh
:::OgogICAgICAgICAgICAgICAgZlsnYXJ0aXN0J10gPSBbYXJ0aXN0YV0KICAgICAg
:::ICAgICAgICAgIGZbJ2FsYnVtYXJ0aXN0J10gPSBbYXJ0aXN0YV0KICAgICAgICAg
:::ICAgaWYgYWxidW06CiAgICAgICAgICAgICAgICBmWydhbGJ1bSddID0gW2FsYnVt
:::XQogICAgICAgICAgICBpZiBmZWNoYToKICAgICAgICAgICAgICAgIGZbJ2RhdGUn
:::XSA9IFtmZWNoYV0KICAgICAgICAgICAgaWYgdXJsOgogICAgICAgICAgICAgICAg
:::ZlsnY29tbWVudCddID0gW3VybF0KICAgICAgICAgICAgaWYgbm90IGYucGljdHVy
:::ZXM6CiAgICAgICAgICAgICAgICBpZiBjYXJhdHVsYToKICAgICAgICAgICAgICAg
:::ICAgICBwaWMgPSBQaWN0dXJlKCkKICAgICAgICAgICAgICAgICAgICBwaWMubWlt
:::ZSwgcGljLnR5cGUsIHBpYy5kZXNjID0gJ2ltYWdlL2pwZWcnLCAzLCAnQ292ZXIn
:::CiAgICAgICAgICAgICAgICAgICAgcGljLmRhdGEgPSBjYXJhdHVsYQogICAgICAg
:::ICAgICAgICAgICAgIGYuYWRkX3BpY3R1cmUocGljKQogICAgICAgICAgICBlbGlm
:::IGFsbChwaS5taW1lICE9ICdpbWFnZS9qcGVnJyBmb3IgcGkgaW4gZi5waWN0dXJl
:::cyk6CiAgICAgICAgICAgICAgICBudWV2YSA9IF9hX2pwZyhmLnBpY3R1cmVzWzBd
:::LmRhdGEpIG9yIGNhcmF0dWxhCiAgICAgICAgICAgICAgICBpZiBudWV2YToKICAg
:::ICAgICAgICAgICAgICAgICBmb3IgdmllamEgaW4gbGlzdChmLnBpY3R1cmVzKToK
:::ICAgICAgICAgICAgICAgICAgICAgICAgZi5yZW1vdmVfcGljdHVyZSh2aWVqYSkK
:::ICAgICAgICAgICAgICAgICAgICBwaWMgPSBQaWN0dXJlKCkKICAgICAgICAgICAg
:::ICAgICAgICBwaWMubWltZSwgcGljLnR5cGUsIHBpYy5kZXNjID0gJ2ltYWdlL2pw
:::ZWcnLCAzLCAnQ292ZXInCiAgICAgICAgICAgICAgICAgICAgcGljLmRhdGEgPSBu
:::dWV2YQogICAgICAgICAgICAgICAgICAgIGYuYWRkX3BpY3R1cmUocGljKQogICAg
:::ICAgICAgICBmLnNhdmUoKQogICAgICAgIGVsaWYgZXh0ID09ICcud21hJzoKICAg
:::ICAgICAgICAgZnJvbSBtdXRhZ2VuLmFzZiBpbXBvcnQgQVNGLCBBU0ZCeXRlQXJy
:::YXlBdHRyaWJ1dGUKICAgICAgICAgICAgYSA9IEFTRihzdHIocCkpCiAgICAgICAg
:::ICAgIGlmIHRpdHVsbzoKICAgICAgICAgICAgICAgIGFbJ1RpdGxlJ10gPSBbdGl0
:::dWxvXQogICAgICAgICAgICBpZiBhcnRpc3RhOgogICAgICAgICAgICAgICAgYVsn
:::QXV0aG9yJ10gPSBbYXJ0aXN0YV0KICAgICAgICAgICAgICAgIGFbJ1dNL0FsYnVt
:::QXJ0aXN0J10gPSBbYXJ0aXN0YV0KICAgICAgICAgICAgaWYgYWxidW06CiAgICAg
:::ICAgICAgICAgICBhWydXTS9BbGJ1bVRpdGxlJ10gPSBbYWxidW1dCiAgICAgICAg
:::ICAgIGlmIGZlY2hhOgogICAgICAgICAgICAgICAgYVsnV00vWWVhciddID0gW2Zl
:::Y2hhXQogICAgICAgICAgICBpZiB1cmw6CiAgICAgICAgICAgICAgICBhWydEZXNj
:::cmlwdGlvbiddID0gW3VybF0KICAgICAgICAgICAgICAgIGFbJ1dNL0F1dGhvclVS
:::TCddID0gW3VybF0KICAgICAgICAgICAgaWYgY2FyYXR1bGE6CiAgICAgICAgICAg
:::ICAgICBhWydXTS9QaWN0dXJlJ10gPSBbQVNGQnl0ZUFycmF5QXR0cmlidXRlKAog
:::ICAgICAgICAgICAgICAgICAgIF93bV9waWN0dXJlKGNhcmF0dWxhLCB0aXR1bG8g
:::b3IgJ0NvdmVyJykpXQogICAgICAgICAgICBhLnNhdmUoKQogICAgICAgIGVsc2U6
:::CiAgICAgICAgICAgIHJldHVybgogICAgICAgIGlmIGxvZzoKICAgICAgICAgICAg
:::ZXh0cmEgPSAnIMK3IGNhcsOhdHVsYSBKUEVHJyBpZiBjYXJhdHVsYSBlbHNlICcn
:::CiAgICAgICAgICAgIGxvZygnRXRpcXVldGFzIGVzY3JpdGFzOiBhcnRpc3RhIMKr
:::JXPCuyDCtyDDoWxidW0gwqslc8K7JXMnCiAgICAgICAgICAgICAgICAlIChhcnRp
:::c3RhIG9yICfigJQnLCBhbGJ1bSBvciAn4oCUJywgZXh0cmEpLCAnZ3JpcycpCiAg
:::ICBleGNlcHQgRXhjZXB0aW9uIGFzIGU6CiAgICAgICAgIyBsYXMgZXRpcXVldGFz
:::IG5vIHNvbiBjcml0aWNhczogbnVuY2EgZGViZW4gcm9tcGVyIGxhIGRlc2Nhcmdh
:::CiAgICAgICAgaWYgbG9nOgogICAgICAgICAgICBsb2coJ05vIHNlIHB1ZGllcm9u
:::IGVzY3JpYmlyIHRvZGFzIGxhcyBldGlxdWV0YXM6ICVzJyAlIGUsCiAgICAgICAg
:::ICAgICAgICAnYXZpc28nKQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBkZXNjYXJnYXMK
:::ZGVmIGRlc2Nhcmdhcl9hdWRpbyh1cmwsIG5vbWJyZV9mbXQsIGNhbGlkYWQsIGRl
:::c3Rpbm8sIGVtYmViZXIsIGNvbGEpOgogICAgIiIiQUFDICgubTRhKSAvIE1QMyAv
:::IEZMQUMgLyBXQVYgdsOtYSBwb3N0cHJvY2VzYWRvcmVzIGRlIHl0LWRscC4KCiAg
:::ICBMYSBjYXLDoXR1bGEgc2UgY29udmllcnRlIGEgSlBHIEFOVEVTIGRlIGluY3J1
:::c3RhcmxhIChtaXNtbyBvcmRlbiB5CiAgICBjbGF2ZXMgcXVlIGdlbmVyYSBlbCBD
:::TEkgY29uIC0tY29udmVydC10aHVtYm5haWxzIGpwZyk6CiAgICBFbWJlZFRodW1i
:::bmFpbCBzb2xvIGNvbnZpZXJ0ZSBsYXMgbWluaWF0dXJhcyBXZWJQIGRlIFlvdVR1
:::YmUgYSBQTkcKICAgICgiUE5HIGlzIHByZWZlcnJlZCBzaW5jZSBKUEVHIGlzIGxv
:::c3N5IikgeSBsb3MgcmVwcm9kdWN0b3JlcwogICAgYmFyYXRvcyBzdWVsZW4gbGVl
:::ciBzb2xvIEpQRUcuIiIiCiAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAg
:::ICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgIGZtdCA9IEZPUk1BVE9TW25v
:::bWJyZV9mbXRdCiAgICBjYXJwZXRhID0gZGVzdGlubyAgICAgICAgICAjIHYyLjM6
:::IHNpbiBzdWJjYXJwZXRhcyBwb3IgZm9ybWF0bwogICAgY2FycGV0YS5ta2Rpcihw
:::YXJlbnRzPVRydWUsIGV4aXN0X29rPVRydWUpCiAgICBjb2RlYyA9IGZtdFsnZXh0
:::J10KICAgIGNvbl9wb3J0YWRhID0gZW1iZWJlciBhbmQgbm9tYnJlX2ZtdCBpbiAo
:::J0FBQycsICdNUDMnLCAnRkxBQycpCiAgICBjb25fdGFncyA9IGVtYmViZXIKICAg
:::IHBwcyA9IFtdCiAgICBpZiBjb25fcG9ydGFkYToKICAgICAgICBwcHMuYXBwZW5k
:::KHsna2V5JzogJ0ZGbXBlZ1RodW1ibmFpbHNDb252ZXJ0b3InLCAnZm9ybWF0Jzog
:::J2pwZycsCiAgICAgICAgICAgICAgICAgICAgJ3doZW4nOiAnYmVmb3JlX2RsJ30p
:::CiAgICBwcHMuYXBwZW5kKHsna2V5JzogJ0ZGbXBlZ0V4dHJhY3RBdWRpbycsICdw
:::cmVmZXJyZWRjb2RlYyc6IGNvZGVjLAogICAgICAgICAgICAgICAgJ3ByZWZlcnJl
:::ZHF1YWxpdHknOiBjYWxpZGFkIG9yICcwJ30pCiAgICBpZiBjb25fdGFnczoKICAg
:::ICAgICBwcHMuYXBwZW5kKHsna2V5JzogJ0ZGbXBlZ01ldGFkYXRhJywgJ2FkZF9t
:::ZXRhZGF0YSc6IFRydWV9KQogICAgaWYgY29uX3BvcnRhZGE6CiAgICAgICAgcHBz
:::LmFwcGVuZCh7J2tleSc6ICdFbWJlZFRodW1ibmFpbCcsCiAgICAgICAgICAgICAg
:::ICAgICAgJ2FscmVhZHlfaGF2ZV90aHVtYm5haWwnOiBGYWxzZX0pCiAgICBvID0g
:::b3B0c19iYXNlKGNhcnBldGEsIGNvbGEpCiAgICBvWydmb3JtYXQnXSA9ICdiZXN0
:::YXVkaW8vYmVzdCcKICAgIG9bJ3Bvc3Rwcm9jZXNzb3JzJ10gPSBwcHMKICAgIG9b
:::J3dyaXRldGh1bWJuYWlsJ10gPSBjb25fcG9ydGFkYQogICAgd2l0aCBZVF9ETFAu
:::WW91dHViZURMKG8pIGFzIHlkbDoKICAgICAgICBpbmZvID0geWRsLmV4dHJhY3Rf
:::aW5mbyh1cmwsIGRvd25sb2FkPVRydWUpCiAgICBhcmNoaXZvID0gYXJjaGl2b19m
:::aW5hbChpbmZvLCBjYXJwZXRhLCBjb2RlYykKICAgIGNhcmF0dWxhID0gX21pbmlh
:::dHVyYV9ieXRlcyhjYXJwZXRhLCBhcmNoaXZvKQogICAgaWYgYXJjaGl2byBhbmQg
:::Y29uX3BvcnRhZGE6CiAgICAgICAgbGltcGlhcl9taW5pYXR1cmFzKGNhcnBldGEs
:::IGFyY2hpdm8pCiAgICBpZiBhcmNoaXZvOgogICAgICAgIGFwbGljYXJfdGFncyhp
:::bmZvLCBhcmNoaXZvLCBsb2csIGNhcmF0dWxhKQogICAgcmV0dXJuIGluZm8sIGFy
:::Y2hpdm8KCgpkZWYgZGVzY2FyZ2FyX3dtYSh1cmwsIGNhbGlkYWQsIGRlc3Rpbm8s
:::IGVtYmViZXIsIGNvbGEpOgogICAgIiIiV01BIDk2LzEyOCBrYnBzOiB5dC1kbHAg
:::bm8gc29wb3J0YSB3bWEsIGFzw60gcXVlIHNlIGJhamEgYSBXQVYgKGNvbgogICAg
:::ZXRpcXVldGFzKSB5IGx1ZWdvIEZGbXBlZyByZWNvZGlmaWNhIGEgd21hdjIgZGVu
:::dHJvIGRlbCAud21hIGZpbmFsLgogICAgTGEgY2Fyw6F0dWxhIChXTS9QaWN0dXJl
:::LCBlbiBKUEVHKSB5IGxhIFVSTCAoV00vQXV0aG9yVVJMKSBzZQogICAgaW5jcnVz
:::dGFuIGNvbiBtdXRhZ2VuLCBjb21vIGVuIGVsIHNjcmlwdCBhbnRpZ3VvLiIiIgog
:::ICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAgICAgICAgY29sYS5wdXQoKCdsb2cn
:::LCBtLCB0KSkKCiAgICBjYXJwZXRhID0gZGVzdGlubyAgICAgICAgICAjIHYyLjM6
:::IHNpbiBzdWJjYXJwZXRhcyBwb3IgZm9ybWF0bwogICAgdG1wID0gY2FycGV0YSAv
:::ICdfdG1wJwogICAgc2h1dGlsLnJtdHJlZSh0bXAsIGlnbm9yZV9lcnJvcnM9VHJ1
:::ZSkKICAgIHRtcC5ta2RpcihwYXJlbnRzPVRydWUsIGV4aXN0X29rPVRydWUpCiAg
:::ICBvID0gb3B0c19iYXNlKHRtcCwgY29sYSkKICAgIG9bJ2Zvcm1hdCddID0gJ2Jl
:::c3RhdWRpby9iZXN0JwogICAgcHBzID0gW3sna2V5JzogJ0ZGbXBlZ0V4dHJhY3RB
:::dWRpbycsICdwcmVmZXJyZWRjb2RlYyc6ICd3YXYnLAogICAgICAgICAgICAncHJl
:::ZmVycmVkcXVhbGl0eSc6ICcwJ31dCiAgICBpZiBlbWJlYmVyOgogICAgICAgIHBw
:::cy5pbnNlcnQoMCwgeydrZXknOiAnRkZtcGVnVGh1bWJuYWlsc0NvbnZlcnRvcics
:::CiAgICAgICAgICAgICAgICAgICAgICAgJ2Zvcm1hdCc6ICdqcGcnLCAnd2hlbic6
:::ICdiZWZvcmVfZGwnfSkKICAgICAgICBwcHMuYXBwZW5kKHsna2V5JzogJ0ZGbXBl
:::Z01ldGFkYXRhJywgJ2FkZF9tZXRhZGF0YSc6IFRydWV9KQogICAgb1sncG9zdHBy
:::b2Nlc3NvcnMnXSA9IHBwcwogICAgb1snd3JpdGV0aHVtYm5haWwnXSA9IGVtYmVi
:::ZXIKICAgIHdpdGggWVRfRExQLllvdXR1YmVETChvKSBhcyB5ZGw6CiAgICAgICAg
:::aW5mbyA9IHlkbC5leHRyYWN0X2luZm8odXJsLCBkb3dubG9hZD1UcnVlKQogICAg
:::d2F2ID0gYXJjaGl2b19maW5hbChpbmZvLCB0bXAsICd3YXYnKQogICAgaWYgbm90
:::IHdhdjoKICAgICAgICByYWlzZSBSdW50aW1lRXJyb3IoJ05vIHNlIGVuY29udHLD
:::syBlbCBXQVYgaW50ZXJtZWRpby4nKQogICAgbWV0YSA9IFtdCiAgICBpZiBlbWJl
:::YmVyOgogICAgICAgIGFydGlzdGEgPSAoaW5mby5nZXQoJ2FydGlzdCcpIG9yIGlu
:::Zm8uZ2V0KCd1cGxvYWRlcicpCiAgICAgICAgICAgICAgICAgICBvciBpbmZvLmdl
:::dCgnY2hhbm5lbCcpIG9yICcnKQogICAgICAgIGlmIGluZm8uZ2V0KCd0aXRsZScp
:::OgogICAgICAgICAgICBtZXRhICs9IFsnLW1ldGFkYXRhJywgJ3RpdGxlPScgKyBz
:::dHIoaW5mb1sndGl0bGUnXSldCiAgICAgICAgaWYgYXJ0aXN0YToKICAgICAgICAg
:::ICAgbWV0YSArPSBbJy1tZXRhZGF0YScsICdhcnRpc3Q9JyArIHN0cihhcnRpc3Rh
:::KV0KICAgIHdtYSA9IGNhcnBldGEgLyAobGltcGlhcl9ub21icmUoaW5mby5nZXQo
:::J3RpdGxlJykgb3IgJ2F1ZGlvJykgKyAnLndtYScpCiAgICBjbWQgPSBbc3RyKEZG
:::TVBFRyksICcteScsICctaScsIHN0cih3YXYpLCAnLXZuJywKICAgICAgICAgICAn
:::LWM6YScsICd3bWF2MicsICctYjphJywgZid7Y2FsaWRhZH1rJ10gKyBtZXRhICsg
:::W3N0cih3bWEpXQogICAgb2sgPSBjb252ZXJ0aXJfZmZtcGVnKAogICAgICAgIGNt
:::ZCwgZidDb252aXJ0aWVuZG8gYSBXTUEgKHdtYXYyIMK3IHtjYWxpZGFkfSBrYnBz
:::KScsIGNvbGEpCiAgICBpZiBub3Qgb2s6CiAgICAgICAgcmFpc2UgUnVudGltZUVy
:::cm9yKCdGRm1wZWcgbm8gcHVkbyBjcmVhciBlbCBhcmNoaXZvIFdNQS4nKQogICAg
:::Y2FyYXR1bGEgPSBOb25lCiAgICBpZiBlbWJlYmVyOgogICAgICAgIGpwZ3MgPSBz
:::b3J0ZWQodG1wLmdsb2IoJyouanBnJyksCiAgICAgICAgICAgICAgICAgICAgICBr
:::ZXk9bGFtYmRhIHE6IHEuc3RhdCgpLnN0X210aW1lLCByZXZlcnNlPVRydWUpCiAg
:::ICAgICAgaWYganBnczoKICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAg
:::Y2FyYXR1bGEgPSBqcGdzWzBdLnJlYWRfYnl0ZXMoKQogICAgICAgICAgICBleGNl
:::cHQgT1NFcnJvcjoKICAgICAgICAgICAgICAgIGNhcmF0dWxhID0gTm9uZQogICAg
:::YXBsaWNhcl90YWdzKGluZm8sIHdtYSwgbG9nLCBjYXJhdHVsYSkKICAgIHNodXRp
:::bC5ybXRyZWUodG1wLCBpZ25vcmVfZXJyb3JzPVRydWUpCiAgICByZXR1cm4gaW5m
:::bywgd21hCgoKIyBQYXLDoW1ldHJvcyBvZmljaWFsZXMgZGVsIHJlcG8gZmRkNHMv
:::cG9ydGFibGVfbXAzX3BsYXllcl92aWRlb19jb252ZXJ0ZXJfdG9vbHMKIyAodmlk
:::ZW8yc2hlbmp1MTguc2gpOiBNSlBFRyAxNiBmcHMgKyBQQ00gMjIwNTAgSHosIHJv
:::dGFkb3MgcGFyYSBsYSBwYW50YWxsYQojIHZlcnRpY2FsIGRlIDEyOHgxNjAgZGVs
:::IHJlcHJvZHVjdG9yIHNoZWlqdSBkZSAxLjggcHVsZ2FkYXMuClZGX1NIRUlKVSA9
:::ICdzY2FsZT0tMjoxMjgsIGNyb3A9MTYwOjEyOCwgdHJhbnNwb3NlPTIsIHZmbGlw
:::JwojIFZhcmlhbnRlIGEgcHJ1ZWJhIGRlIGJhbGFzIHBhcmEgdmlkZW9zIGN1YWRy
:::YWRvcy92ZXJ0aWNhbGVzIChTaG9ydHMpLAojIGRvbmRlIGVsIHJlY29ydGUgMTYw
:::OjEyOCBvcmlnaW5hbCBzZXLDrWEgaW1wb3NpYmxlOgpWRl9TRUdVUk8gPSAoJ3Nj
:::YWxlPTE2MDoxMjg6Zm9yY2Vfb3JpZ2luYWxfYXNwZWN0X3JhdGlvPWRlY3JlYXNl
:::LCcKICAgICAgICAgICAgICdwYWQ9MTYwOjEyODoob3ctaXcpLzI6KG9oLWloKS8y
:::LHRyYW5zcG9zZT0yLHZmbGlwJykKCgpkZWYgZGVzY2FyZ2FyX2F2aSh1cmwsIGRl
:::c3Rpbm8sIGNvbGEpOgogICAgIiIiVmlkZW8gQVZJIHBhcmEgZWwgcmVwcm9kdWN0
:::b3Igc2hlaWp1IDEuOCIgMTI4eDE2MC4iIiIKICAgIGRlZiBsb2cobSwgdD0naW5m
:::bycpOgogICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgY2FycGV0
:::YSA9IGRlc3Rpbm8gICAgICAgICAgIyB2Mi4zOiBzaW4gc3ViY2FycGV0YXMgcG9y
:::IGZvcm1hdG8KICAgIHRtcCA9IGNhcnBldGEgLyAnX3RtcCcKICAgIHNodXRpbC5y
:::bXRyZWUodG1wLCBpZ25vcmVfZXJyb3JzPVRydWUpCiAgICB0bXAubWtkaXIocGFy
:::ZW50cz1UcnVlLCBleGlzdF9vaz1UcnVlKQogICAgbyA9IG9wdHNfYmFzZSh0bXAs
:::IGNvbGEpCiAgICAjIFBhcmEgdW5hIHBhbnRhbGxhIGRlIDEyOHgxNjAgYmFzdGEg
:::Y29uIDQ4MHA6IGFob3JyYSBtdWNoYSBkZXNjYXJnYS4KICAgIG9bJ2Zvcm1hdCdd
:::ID0gKCdiZXN0W2hlaWdodDw9NDgwXVtleHQ9bXA0XS9iZXN0W2hlaWdodDw9NDgw
:::XS8nCiAgICAgICAgICAgICAgICAgICAnYnYqW2hlaWdodDw9NDgwXStiYS9iJykK
:::ICAgIG9bJ21lcmdlX291dHB1dF9mb3JtYXQnXSA9ICdtcDQnCiAgICB3aXRoIFlU
:::X0RMUC5Zb3V0dWJlREwobykgYXMgeWRsOgogICAgICAgIGluZm8gPSB5ZGwuZXh0
:::cmFjdF9pbmZvKHVybCwgZG93bmxvYWQ9VHJ1ZSkKICAgIG9yaWdlbiA9IGFyY2hp
:::dm9fZmluYWwoaW5mbywgdG1wLCAnbXA0JykKICAgIGlmIG5vdCBvcmlnZW46CiAg
:::ICAgICAgb3JpZ2VuID0gKGFyY2hpdm9fZmluYWwoaW5mbywgdG1wLCAnbWt2JykK
:::ICAgICAgICAgICAgICAgICAgb3IgYXJjaGl2b19maW5hbChpbmZvLCB0bXAsICd3
:::ZWJtJykpCiAgICBpZiBub3Qgb3JpZ2VuOgogICAgICAgIHJhaXNlIFJ1bnRpbWVF
:::cnJvcignTm8gc2UgZW5jb250csOzIGVsIHZpZGVvIGRlc2NhcmdhZG8uJykKICAg
:::IGF2aSA9IGNhcnBldGEgLyAobGltcGlhcl9ub21icmUoaW5mby5nZXQoJ3RpdGxl
:::Jykgb3IgJ3ZpZGVvJykgKyAnLmF2aScpCiAgICBiYXNlID0gW3N0cihGRk1QRUcp
:::LCAnLXknLCAnLWknLCBzdHIob3JpZ2VuKSwgJy1yJywgJzE2JywKICAgICAgICAg
:::ICAgJy1hY29kZWMnLCAncGNtX3MxNmxlJywgJy1hYycsICcyJywgJy1hcicsICcy
:::MjA1MCcsCiAgICAgICAgICAgICctcGl4X2ZtdCcsICd5dXZqNDIwcCcsICctYzp2
:::JywgJ21qcGVnJywgJy1xOnYnLCAnMiddCiAgICBvayA9IGNvbnZlcnRpcl9mZm1w
:::ZWcoYmFzZSArIFsnLXZmJywgVkZfU0hFSUpVLCBzdHIoYXZpKV0sCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgJ0NvbnZpcnRpZW5kbyBhIEFWSSAxMjh4MTYwIChz
:::aGVpanUgMS44IiknLCBjb2xhKQogICAgaWYgbm90IG9rOgogICAgICAgIGxvZygn
:::VmlkZW8gY29uIHByb3BvcmNpw7NuIG5vIGVzdMOhbmRhcjsgJwogICAgICAgICAg
:::ICAncmVpbnRlbnRhbmRvIGVuIG1vZG8gY29tcGF0aWJsZS4uLicsICdhdmlzbycp
:::CiAgICAgICAgb2sgPSBjb252ZXJ0aXJfZmZtcGVnKGJhc2UgKyBbJy12ZicsIFZG
:::X1NFR1VSTywgc3RyKGF2aSldLAogICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAnUmVjb252aXJ0aWVuZG8gYSBBVkkgMTI4eDE2MCcsIGNvbGEpCiAgICBpZiBu
:::b3Qgb2s6CiAgICAgICAgcmFpc2UgUnVudGltZUVycm9yKCdGRm1wZWcgbm8gcHVk
:::byBjcmVhciBlbCBhcmNoaXZvIEFWSS4nKQogICAgc2h1dGlsLnJtdHJlZSh0bXAs
:::IGlnbm9yZV9lcnJvcnM9VHJ1ZSkKICAgIHJldHVybiBpbmZvLCBhdmkKCgojIC0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0gZXN0aW1hY2nDs24KS0JQU19FU1RJTUFET1MgPSB7CiAg
:::ICAnQUFDJzogMTI4LCAgICAgIyB0ZWNobyBkZWwgZm9ybWF0bwogICAgJ1dNQSc6
:::IDEyOCwKICAgICdXQVYnOiAxNDExLCAgICAjIFBDTSA0NC4xIGtIeiDCtyAxNiBi
:::aXQgwrcgZXN0w6lyZW8KICAgICdGTEFDJzogOTUwLCAgICAjIHTDrXBpY28gZGUg
:::bcO6c2ljYSBwcm9jZWRlbnRlIGRlIFlvdVR1YmUKICAgICdBVkknOiAxNDkwLCAg
:::ICAjIH43ODQga2JwcyBNSlBFRyAxNmZwcyArIDcwNiBrYnBzIFBDTSAyMjA1MCBl
:::c3TDqXJlbwp9CgoKZGVmIGVzdGltYXJfYnl0ZXMoZHVyYWNpb25fcywgZm9ybWF0
:::bywgY2FsaWRhZCwgZW1iZWJlcik6CiAgICAiIiJFc3RpbWEgZWwgdGFtYcOxbyBm
:::aW5hbCBlbiBieXRlcyAoY8OhbGN1bG8gcHVybywgdGVzdGVhYmxlKS4iIiIKICAg
:::IGlmIGZvcm1hdG8gaW4gKCdNUDMnLCAnQUFDJywgJ1dNQScpOgogICAgICAgIGti
:::cHMgPSBpbnQocmUuc3ViKHInW14wLTldJywgJycsIHN0cihjYWxpZGFkKSkgb3Ig
:::MCkKICAgICAgICBpZiBub3Qga2JwczoKICAgICAgICAgICAga2JwcyA9IEtCUFNf
:::RVNUSU1BRE9TLmdldChmb3JtYXRvLCAxMjgpCiAgICBlbHNlOgogICAgICAgIGti
:::cHMgPSBLQlBTX0VTVElNQURPUy5nZXQoZm9ybWF0bywgMTI4KQogICAgZXh0cmEg
:::PSAxMjBfMDAwIGlmIChlbWJlYmVyIGFuZCBmb3JtYXRvIGluICgnQUFDJywgJ01Q
:::MycsICdGTEFDJykpIGVsc2UgMAogICAgcmV0dXJuIGR1cmFjaW9uX3MgKiBrYnBz
:::ICogMTAwMCAvIDggKyBleHRyYQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBjYWxpZGFk
:::CmRlZiBjbGFzZV9jYWxpZGFkKGV4dCwga2Jwcyk6CiAgICAiIiJDbGFzaWZpY2Eg
:::dW4gYXJjaGl2by4gRGV2dWVsdmUgKHRleHRvLCBuaXZlbCkgY29uIG5pdmVsIDA9
:::b2sgMT1tZWRpYSAyPWJhamEuIiIiCiAgICBpZiBleHQgPT0gJy5tcDMnOgogICAg
:::ICAgIGlmIGticHMgPj0gMzE1OgogICAgICAgICAgICByZXR1cm4gJzMyMCBrYnBz
:::JywgMAogICAgICAgIGlmIGticHMgPj0gMjUwOgogICAgICAgICAgICByZXR1cm4g
:::JzI1NiBrYnBzJywgMAogICAgICAgIGlmIGticHMgPj0gMTg1OgogICAgICAgICAg
:::ICByZXR1cm4gJzE5MiBrYnBzJywgMAogICAgICAgIGlmIGticHMgPj0gMTIwOgog
:::ICAgICAgICAgICByZXR1cm4gJzEyOCBrYnBzJywgMQogICAgICAgIHJldHVybiBm
:::J3trYnBzfSBrYnBzIChiYWphKScsIDIKICAgIGlmIGV4dCA9PSAnLm00YSc6CiAg
:::ICAgICAgaWYga2JwcyA+PSAxMTU6CiAgICAgICAgICAgIHJldHVybiAnRXhjZWxl
:::bnRlIChBQUMg4omkMTI4ayknLCAwCiAgICAgICAgaWYga2JwcyA+PSA4MjoKICAg
:::ICAgICAgICAgcmV0dXJuICc5NiBrYnBzJywgMQogICAgICAgIHJldHVybiBmJ3tr
:::YnBzfSBrYnBzIChiYWphKScsIDIKICAgIGlmIGV4dCA9PSAnLndtYSc6CiAgICAg
:::ICAgaWYga2JwcyA+PSAxMTU6CiAgICAgICAgICAgIHJldHVybiAnMTI4IGticHMn
:::LCAwCiAgICAgICAgaWYga2JwcyA+PSA4ODoKICAgICAgICAgICAgcmV0dXJuICc5
:::NiBrYnBzJywgMQogICAgICAgIHJldHVybiBmJ3trYnBzfSBrYnBzIChiYWphKScs
:::IDIKICAgIGlmIGV4dCBpbiAoJy5mbGFjJywgJy53YXYnKToKICAgICAgICByZXR1
:::cm4gJ1NpbiBww6lyZGlkYScsIDAKICAgIGlmIGV4dCA9PSAnLmF2aSc6CiAgICAg
:::ICAgaWYga2JwcyA+PSAxMjAwOgogICAgICAgICAgICByZXR1cm4gZid7a2Jwc30g
:::a2JwcyAoTUpQRUcrUENNIDEyOHgxNjApJywgMAogICAgICAgIHJldHVybiBmJ3tr
:::YnBzfSBrYnBzIChhbGdvIGJham8pJywgMQogICAgcmV0dXJuIGYne2ticHN9IGti
:::cHMnLCAxCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIHRlbWFzClRFTUFTID0gewogICAg
:::J09zY3Vybyc6IGRpY3QoCiAgICAgICAgZm9uZG89JyMxZTFmMjInLCBjYW1wbz0n
:::IzJhMmQzMScsIGNhbXBvX2JvcmRlPScjM2EzZTQ0JywKICAgICAgICB0ZXh0bz0n
:::I2Q4ZGFkYycsIHRleHRvMj0nIzlhOWZhNCcsCiAgICAgICAgYm90b249JyMzYTNk
:::NDInLCBib3Rvbl9hY3Q9JyM0YTRlNTUnLCBib3Rvbl90eHQ9JyNlOGVhZWMnLAog
:::ICAgICAgIGxvZz0nIzE0MTUxOCcsIGxvZ190eHQ9JyNjZmQzZDcnLCBhY2VudG89
:::JyM0ZjljZjknLAogICAgICAgIG9rPScjN2VjOTdmJywgZXJyb3I9JyNlNTczNzMn
:::LCBhdmlzbz0nI2Q4YjY0YScsIHRyb3VnaD0nIzI2MjgyYycsCiAgICAgICAgcGxh
:::Y2Vob2xkZXI9JyM3NzdjODInKSwKICAgICdDbGFybyc6IGRpY3QoCiAgICAgICAg
:::Zm9uZG89JyNmMmYzZjUnLCBjYW1wbz0nI2ZmZmZmZicsIGNhbXBvX2JvcmRlPScj
:::YzRjOGNkJywKICAgICAgICB0ZXh0bz0nIzI0MjcyYScsIHRleHRvMj0nIzZhNzA3
:::NicsCiAgICAgICAgYm90b249JyNlM2U1ZTgnLCBib3Rvbl9hY3Q9JyNkMmQ1ZGEn
:::LCBib3Rvbl90eHQ9JyMyNDI3MmEnLAogICAgICAgIGxvZz0nI2ZmZmZmZicsIGxv
:::Z190eHQ9JyMyYjJlMzEnLCBhY2VudG89JyMxYTY2ZDYnLAogICAgICAgIG9rPScj
:::MWU3ZTM0JywgZXJyb3I9JyNjNjI4MjgnLCBhdmlzbz0nIzlhNjcwMCcsIHRyb3Vn
:::aD0nI2RmZTFlNCcsCiAgICAgICAgcGxhY2Vob2xkZXI9JyM5YWEwYTYnKSwKfQoK
:::UExBQ0VIT0xERVJfVVJMID0gJ2h0dHBzOi8vd3d3LnlvdXR1YmUuY29tL3dhdGNo
:::P3Y9Li4uJwoKRlVFTlRFX1VJID0gKCdTZWdvZSBVSScsIDkpCkZVRU5URV9CVE4g
:::PSAoJ1NlZ29lIFVJJywgMTApCkZVRU5URV9CVE5fRyA9ICgnU2Vnb2UgVUknLCAx
:::MSkKRlVFTlRFX0xPRyA9ICgnQ29uc29sYXMnLCAxMCkKCgppZiBUS19PSzoKCiAg
:::ICBjbGFzcyBBcHAodGsuVGspOgogICAgICAgICIiIlZlbnRhbmEgcHJpbmNpcGFs
:::IChkaXNlw7FvIGVzcGVqbyBkZWwgbW9ja3VwOiBncnVwb3Mgb3NjdXJvcykuIiIi
:::CgogICAgICAgICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tIGNvbnN0cnVjY2nDs24KICAgICAgICBkZWYgX19pbml0X18o
:::c2VsZik6CiAgICAgICAgICAgIGlmIGdldGF0dHIoc3lzLCAnZnJvemVuJywgRmFs
:::c2UpOgogICAgICAgICAgICAgICAgcGFzcwogICAgICAgICAgICBzdXBlcigpLl9f
:::aW5pdF9fKCkKICAgICAgICAgICAgc2VsZi50aXRsZSgnTXVzaWtBTEFOJykKICAg
:::ICAgICAgICAgc2VsZi5nZW9tZXRyeSgnODYweDg0MCcpCiAgICAgICAgICAgIHNl
:::bGYubWluc2l6ZSg3MDAsIDY2MCkKICAgICAgICAgICAgc2VsZi5jb2xhID0gcXVl
:::dWUuUXVldWUoKQogICAgICAgICAgICBzZWxmLl9vY3VwYWRvID0gRmFsc2UKICAg
:::ICAgICAgICAgc2VsZi5fZW5fcGxhY2Vob2xkZXIgPSBUcnVlCiAgICAgICAgICAg
:::IHNlbGYuX3RlbWFfYWN0dWFsID0gQUpVU1RFUy5nZXQoJ3RlbWEnLCAnT3NjdXJv
:::JykKICAgICAgICAgICAgaWYgc2VsZi5fdGVtYV9hY3R1YWwgbm90IGluIFRFTUFT
:::OgogICAgICAgICAgICAgICAgc2VsZi5fdGVtYV9hY3R1YWwgPSAnT3NjdXJvJwoK
:::ICAgICAgICAgICAgc2VsZi5fZXN0aWxvID0gdHRrLlN0eWxlKHNlbGYpCiAgICAg
:::ICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHNlbGYuX2VzdGlsby50aGVtZV91
:::c2UoJ2NsYW0nKQogICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAg
:::ICAgICAgICAgcGFzcwoKICAgICAgICAgICAgc2VsZi5fY29uc3RydWlyKCkKICAg
:::ICAgICAgICAgc2VsZi5fYXBsaWNhcl90ZW1hKCkKICAgICAgICAgICAgc2VsZi5f
:::Y29uZWN0YXJfZXZlbnRvcygpCiAgICAgICAgICAgIFJFR0lTVFJPLmxvZyA9IGxh
:::bWJkYSBtLCB0PSdhdmlzbyc6IHNlbGYuY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkK
:::ICAgICAgICAgICAgc2VsZi5hZnRlcig4MCwgc2VsZi5fYm9tYmVhcl9jb2xhKQog
:::ICAgICAgICAgICBzZWxmLmFmdGVyKDE1MCwgc2VsZi5fYXJyYW5xdWUpCgogICAg
:::ICAgIGRlZiBfY29uc3RydWlyKHNlbGYpOgogICAgICAgICAgICBzZWxmLl93ZyA9
:::IHt9ICAgICAgICAgIyByZWZlcmVuY2lhcyBwYXJhIGVsIHRlbWEKICAgICAgICAg
:::ICAgc2VsZi5fYnRucyA9IFtdICAgICAgICMgYm90b25lcyBwbGFub3MgKHBhcmEg
:::aG92ZXIvdGVtYSkKICAgICAgICAgICAgbWFyY28gPSB0ay5GcmFtZShzZWxmKQog
:::ICAgICAgICAgICBtYXJjby5wYWNrKGZpbGw9J2JvdGgnLCBleHBhbmQ9VHJ1ZSwg
:::cGFkeD0xMCwgcGFkeT04KQogICAgICAgICAgICBzZWxmLl93Z1snbWFyY28nXSA9
:::IG1hcmNvCiAgICAgICAgICAgIG1hcmNvLmNvbHVtbmNvbmZpZ3VyZSgwLCB3ZWln
:::aHQ9MSkKCiAgICAgICAgICAgICMgLS0tIGZpbGEgVGVtYSAtLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KICAgICAgICAgICAg
:::ZjAgPSB0ay5GcmFtZShtYXJjbykKICAgICAgICAgICAgZjAuZ3JpZChyb3c9MCwg
:::Y29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PSgwLCA2KSkKICAgICAgICAgICAg
:::c2VsZi5fd2dbJ2YwJ10gPSBmMAogICAgICAgICAgICBzZWxmLl93Z1snbGJsX3Rl
:::bWEnXSA9IHRrLkxhYmVsKGYwLCB0ZXh0PSdUZW1hOicsIGZvbnQ9RlVFTlRFX1VJ
:::KQogICAgICAgICAgICBzZWxmLl93Z1snbGJsX3RlbWEnXS5wYWNrKHNpZGU9J2xl
:::ZnQnKQogICAgICAgICAgICBzZWxmLmNtYl90ZW1hID0gdHRrLkNvbWJvYm94KAog
:::ICAgICAgICAgICAgICAgZjAsIHZhbHVlcz1saXN0KFRFTUFTKSwgc3RhdGU9J3Jl
:::YWRvbmx5Jywgd2lkdGg9OSwKICAgICAgICAgICAgICAgIGZvbnQ9RlVFTlRFX1VJ
:::LCBzdHlsZT0nZ3guVENvbWJvYm94JykKICAgICAgICAgICAgc2VsZi5jbWJfdGVt
:::YS5zZXQoc2VsZi5fdGVtYV9hY3R1YWwpCiAgICAgICAgICAgIHNlbGYuY21iX3Rl
:::bWEucGFjayhzaWRlPSdsZWZ0JywgcGFkeD0oOCwgMCksIGlwYWR5PTIpCgogICAg
:::ICAgICAgICAjIC0tLSBncnVwbzogVVJMIGRlIFlvdVR1YmUgLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAgIGd1ID0gdGsuTGFi
:::ZWxGcmFtZShtYXJjbywgdGV4dD0nVVJMIGRlIFlvdVR1YmUnLCBmb250PUZVRU5U
:::RV9VSSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlbGllZj0nc29s
:::aWQnLCBiZD0xKQogICAgICAgICAgICBndS5ncmlkKHJvdz0xLCBjb2x1bW49MCwg
:::c3RpY2t5PSdldycsIHBhZHk9NSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2d1J10g
:::PSBndQogICAgICAgICAgICBndS5jb2x1bW5jb25maWd1cmUoMCwgd2VpZ2h0PTEp
:::CiAgICAgICAgICAgIHNlbGYuZW50X3VybCA9IHRrLkVudHJ5KGd1LCBmb250PUZV
:::RU5URV9VSSwgcmVsaWVmPSdmbGF0JywKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgaGlnaGxpZ2h0dGhpY2tuZXNzPTEpCiAgICAgICAgICAgIHNl
:::bGYuZW50X3VybC5ncmlkKHJvdz0wLCBjb2x1bW49MCwgc3RpY2t5PSdldycsCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhZHg9OCwgcGFkeT04LCBpcGFk
:::eT01KQogICAgICAgICAgICBzZWxmLl9wb25lcl9wbGFjZWhvbGRlcigpCiAgICAg
:::ICAgICAgIHNlbGYuYnRuX3ggPSBzZWxmLl9ib3RvbihndSwgJ1gnLCBzZWxmLl9s
:::aW1waWFyX3VybCwgd2lkdGg9MykKICAgICAgICAgICAgc2VsZi5idG5feC5ncmlk
:::KHJvdz0wLCBjb2x1bW49MSwgc3RpY2t5PSdlJywgcGFkeD0oMCwgOCksIGlwYWR5
:::PTMpCgogICAgICAgICAgICAjIC0tLSBncnVwbzogRm9ybWF0byB5IGNhbGlkYWQg
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAgIGdm
:::ID0gdGsuTGFiZWxGcmFtZShtYXJjbywgdGV4dD0nRm9ybWF0byB5IGNhbGlkYWQn
:::LCBmb250PUZVRU5URV9VSSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::IHJlbGllZj0nc29saWQnLCBiZD0xKQogICAgICAgICAgICBnZi5ncmlkKHJvdz0y
:::LCBjb2x1bW49MCwgc3RpY2t5PSdldycsIHBhZHk9NSkKICAgICAgICAgICAgc2Vs
:::Zi5fd2dbJ2dmJ10gPSBnZgogICAgICAgICAgICBnZi5jb2x1bW5jb25maWd1cmUo
:::MSwgd2VpZ2h0PTEpCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfZm10J10gPSB0
:::ay5MYWJlbChnZiwgdGV4dD0nRm9ybWF0bzonLCBmb250PUZVRU5URV9VSSkKICAg
:::ICAgICAgICAgc2VsZi5fd2dbJ2xibF9mbXQnXS5ncmlkKHJvdz0wLCBjb2x1bW49
:::MCwgc3RpY2t5PSd3JywgcGFkeD04LCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYu
:::Y21iX2Zvcm1hdG8gPSB0dGsuQ29tYm9ib3goCiAgICAgICAgICAgICAgICBnZiwg
:::dmFsdWVzPVtmWyd0ZXh0byddIGZvciBmIGluIEZPUk1BVE9TLnZhbHVlcygpXSwK
:::ICAgICAgICAgICAgICAgIHN0YXRlPSdyZWFkb25seScsIGZvbnQ9RlVFTlRFX1VJ
:::LCBzdHlsZT0nZ3guVENvbWJvYm94JykKICAgICAgICAgICAgc2VsZi5jbWJfZm9y
:::bWF0by5ncmlkKHJvdz0wLCBjb2x1bW49MSwgc3RpY2t5PSdldycsCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4PTgsIHBhZHk9NSwgaXBhZHk9
:::MikKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF9jYWwnXSA9IHRrLkxhYmVsKGdm
:::LCB0ZXh0PSdDYWxpZGFkOicsIGZvbnQ9RlVFTlRFX1VJKQogICAgICAgICAgICBz
:::ZWxmLl93Z1snbGJsX2NhbCddLmdyaWQocm93PTEsIGNvbHVtbj0wLCBzdGlja3k9
:::J3cnLCBwYWR4PTgsIHBhZHk9NSkKICAgICAgICAgICAgc2VsZi5jbWJfY2FsaWRh
:::ZCA9IHR0ay5Db21ib2JveCgKICAgICAgICAgICAgICAgIGdmLCBzdGF0ZT0ncmVh
:::ZG9ubHknLCBmb250PUZVRU5URV9VSSwgc3R5bGU9J2d4LlRDb21ib2JveCcpCiAg
:::ICAgICAgICAgIHNlbGYuY21iX2NhbGlkYWQuZ3JpZChyb3c9MSwgY29sdW1uPTEs
:::IHN0aWNreT0nZXcnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::cGFkeD04LCBwYWR5PTUsIGlwYWR5PTIpCiAgICAgICAgICAgIHNlbGYuX3dnWyds
:::YmxfY2FyJ10gPSB0ay5MYWJlbChnZiwgdGV4dD0nQ2FycGV0YTonLCBmb250PUZV
:::RU5URV9VSSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF9jYXInXS5ncmlkKHJv
:::dz0yLCBjb2x1bW49MCwgc3RpY2t5PSd3JywgcGFkeD04LCBwYWR5PTUpCiAgICAg
:::ICAgICAgIGZjID0gdGsuRnJhbWUoZ2YpCiAgICAgICAgICAgIGZjLmdyaWQocm93
:::PTIsIGNvbHVtbj0xLCBzdGlja3k9J2V3JywgcGFkeD04LCBwYWR5PTUpCiAgICAg
:::ICAgICAgIHNlbGYuX3dnWydmYyddID0gZmMKICAgICAgICAgICAgZmMuY29sdW1u
:::Y29uZmlndXJlKDAsIHdlaWdodD0xKQogICAgICAgICAgICBzZWxmLmVudF9jYXJw
:::ZXRhID0gdGsuRW50cnkoZmMsIGZvbnQ9RlVFTlRFX1VJLCByZWxpZWY9J2ZsYXQn
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgaGlnaGxp
:::Z2h0dGhpY2tuZXNzPTEpCiAgICAgICAgICAgIHNlbGYuZW50X2NhcnBldGEuZ3Jp
:::ZChyb3c9MCwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBpcGFkeT00KQogICAgICAg
:::ICAgICBzZWxmLmVudF9jYXJwZXRhLmluc2VydCgwLCBBSlVTVEVTWydkZXN0aW5v
:::J10pCiAgICAgICAgICAgIHNlbGYuYnRuX2NhbWJpYXIgPSBzZWxmLl9ib3Rvbihm
:::YywgJ0NhbWJpYXIuLi4nLCBzZWxmLl9jYW1iaWFyX2NhcnBldGEpCiAgICAgICAg
:::ICAgIHNlbGYuYnRuX2NhbWJpYXIuZ3JpZChyb3c9MCwgY29sdW1uPTEsIHBhZHg9
:::KDgsIDApLCBpcGFkeT0zKQogICAgICAgICAgICBzZWxmLmJ0bl9hYnJpciA9IHNl
:::bGYuX2JvdG9uKGZjLCAnQWJyaXInLCBzZWxmLl9hYnJpcl9kZXN0aW5vLCB3aWR0
:::aD01KQogICAgICAgICAgICBzZWxmLmJ0bl9hYnJpci5ncmlkKHJvdz0wLCBjb2x1
:::bW49MiwgcGFkeD0oNiwgMCksIGlwYWR5PTMpCgogICAgICAgICAgICBzZWxmLnZh
:::cl9lbWJlYmVyID0gdGsuQm9vbGVhblZhcih2YWx1ZT1ib29sKEFKVVNURVMuZ2V0
:::KCdlbWJlYmVyJywgVHJ1ZSkpKQogICAgICAgICAgICBzZWxmLmNoa19lbWJlYmVy
:::ID0gdGsuQ2hlY2tidXR0b24oCiAgICAgICAgICAgICAgICBnZiwgdGV4dD0nRW1i
:::ZWJlciBjYXLDoXR1bGEsIGFydGlzdGEgeSDDoWxidW0nLAogICAgICAgICAgICAg
:::ICAgdmFyaWFibGU9c2VsZi52YXJfZW1iZWJlciwgZm9udD1GVUVOVEVfVUksIGFu
:::Y2hvcj0ndycsCiAgICAgICAgICAgICAgICByZWxpZWY9J2ZsYXQnLCBoaWdobGln
:::aHR0aGlja25lc3M9MCwgYmQ9MCkKICAgICAgICAgICAgc2VsZi5jaGtfZW1iZWJl
:::ci5ncmlkKHJvdz0zLCBjb2x1bW49MCwgY29sdW1uc3Bhbj0yLAogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgc3RpY2t5PSdldycsIHBhZHg9OCwgcGFk
:::eT0oMiwgNikpCgogICAgICAgICAgICAjIC0tLSBncnVwbzogZXN0aW1hY2nDs24g
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAg
:::ICAgICBnZSA9IHRrLkxhYmVsRnJhbWUobWFyY28sIHRleHQ9J0VzdGltYWNpw7Nu
:::JywgZm9udD1GVUVOVEVfVUksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICByZWxpZWY9J3NvbGlkJywgYmQ9MSkKICAgICAgICAgICAgZ2UuZ3JpZChyb3c9
:::MywgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PTUpCiAgICAgICAgICAgIHNl
:::bGYuX3dnWydnZSddID0gZ2UKICAgICAgICAgICAgZ2UuY29sdW1uY29uZmlndXJl
:::KDAsIHdlaWdodD0xKQogICAgICAgICAgICBzZWxmLmxibF9lc3RpbWFjaW9uID0g
:::dGsuTGFiZWwoCiAgICAgICAgICAgICAgICBnZSwgdGV4dD0nSW50cm9kdWNlIHVu
:::YSBVUkwgeSBwdWxzYSBFc3RpbWFyLicsCiAgICAgICAgICAgICAgICBmb250PUZV
:::RU5URV9VSSwgYW5jaG9yPSd3JykKICAgICAgICAgICAgc2VsZi5sYmxfZXN0aW1h
:::Y2lvbi5ncmlkKHJvdz0wLCBjb2x1bW49MCwgc3RpY2t5PSdldycsCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4PTgsIHBhZHk9NikKICAg
:::ICAgICAgICAgc2VsZi5idG5fZXN0aW1hciA9IHNlbGYuX2JvdG9uKGdlLCAnRXN0
:::aW1hciB0YW1hbm8nLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgc2VsZi5fYWNjaW9uX2VzdGltYXIpCiAgICAgICAgICAgIHNlbGYu
:::YnRuX2VzdGltYXIuZ3JpZChyb3c9MCwgY29sdW1uPTEsIHN0aWNreT0nZScsCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4PTgsIGlwYWR5PTMp
:::CgogICAgICAgICAgICAjIC0tLSBib3RvbmVzIGdyYW5kZXMgLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAgIHNlbGYu
:::YnRuX2Rlc2NhcmdhciA9IHNlbGYuX2JvdG9uKG1hcmNvLCAnRGVzY2FyZ2FyIHkg
:::Y29udmVydGlyJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgc2VsZi5fYWNjaW9uX2Rlc2NhcmdhciwKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZnVlbnRlPUZVRU5URV9CVE5f
:::RywgYWx0bz0yKQogICAgICAgICAgICBzZWxmLmJ0bl9kZXNjYXJnYXIuZ3JpZChy
:::b3c9NCwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PSg3LCA0KSkKICAgICAg
:::ICAgICAgc2VsZi5idG5fY29tcHJvYmFyID0gc2VsZi5fYm90b24oCiAgICAgICAg
:::ICAgICAgICBtYXJjbywgJ0NvbXByb2JhciBjYWxpZGFkIGRlIGxhIGNhcnBldGEn
:::LAogICAgICAgICAgICAgICAgc2VsZi5fYWNjaW9uX2NvbXByb2JhciwgZnVlbnRl
:::PUZVRU5URV9CVE4pCiAgICAgICAgICAgIHNlbGYuYnRuX2NvbXByb2Jhci5ncmlk
:::KHJvdz01LCBjb2x1bW49MCwgc3RpY2t5PSdldycsIHBhZHk9MykKCiAgICAgICAg
:::ICAgICMgLS0tIGVzdGFkbyArIGJhcnJhIGRlIHByb2dyZXNvIC0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAgIHNlbGYubGJsX2VzdGFk
:::byA9IHRrLkxhYmVsKG1hcmNvLCB0ZXh0PScnLCBmb250PUZVRU5URV9VSSwKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYW5jaG9yPSd3JykK
:::ICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmdyaWQocm93PTYsIGNvbHVtbj0w
:::LCBzdGlja3k9J2V3JywgcGFkeT0oNCwgMCkpCiAgICAgICAgICAgIHNlbGYuYmFy
:::cmEgPSB0dGsuUHJvZ3Jlc3NiYXIoCiAgICAgICAgICAgICAgICBtYXJjbywgbWF4
:::aW11bT0xMDAsIHN0eWxlPSdneC5Ib3Jpem9udGFsLlRQcm9ncmVzc2JhcicpCiAg
:::ICAgICAgICAgIHNlbGYuYmFycmEuZ3JpZChyb3c9NywgY29sdW1uPTAsIHN0aWNr
:::eT0nZXcnLCBwYWR5PSgyLCA0KSkKCiAgICAgICAgICAgICMgLS0tIHJlZ2lzdHJv
:::IChsb2cpIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tCiAgICAgICAgICAgIHNlbGYudHh0X2xvZyA9IFNjcm9sbGVkVGV4dChtYXJj
:::bywgZm9udD1GVUVOVEVfTE9HLCBoZWlnaHQ9MTIsCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICByZWxpZWY9J2ZsYXQnLCBiZD0wLCB3cmFw
:::PSd3b3JkJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::IHN0YXRlPSdkaXNhYmxlZCcpCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5ncmlk
:::KHJvdz04LCBjb2x1bW49MCwgc3RpY2t5PSduc2V3JykKICAgICAgICAgICAgbWFy
:::Y28ucm93Y29uZmlndXJlKDgsIHdlaWdodD0xKQogICAgICAgICAgICBmb3IgdGFn
:::LCBjb25mIGluICgKICAgICAgICAgICAgICAgICAgICAoJ2luZm8nLCB7fSksCiAg
:::ICAgICAgICAgICAgICAgICAgKCdncmlzJywge30pLAogICAgICAgICAgICAgICAg
:::ICAgICgndGl0dWxvJywge30pLAogICAgICAgICAgICAgICAgICAgICgnb2snLCB7
:::fSksCiAgICAgICAgICAgICAgICAgICAgKCdhdmlzbycsIHt9KSwKICAgICAgICAg
:::ICAgICAgICAgICAoJ2Vycm9yJywge30pKToKICAgICAgICAgICAgICAgIHNlbGYu
:::dHh0X2xvZy50YWdfY29uZmlndXJlKHRhZywgY29uZikKCiAgICAgICAgICAgICMg
:::c2luY3Jvbml6YXIgdmFsb3JlcyBndWFyZGFkb3MKICAgICAgICAgICAgZm10ID0g
:::QUpVU1RFUy5nZXQoJ2Zvcm1hdG8nLCAnQUFDJykKICAgICAgICAgICAgaWYgZm10
:::IG5vdCBpbiBGT1JNQVRPUzoKICAgICAgICAgICAgICAgIGZtdCA9ICdBQUMnCiAg
:::ICAgICAgICAgIHNlbGYuY21iX2Zvcm1hdG8uc2V0KEZPUk1BVE9TW2ZtdF1bJ3Rl
:::eHRvJ10pCiAgICAgICAgICAgIHNlbGYuX3JlY2FyZ2FyX2NhbGlkYWRlcyhmbXQs
:::IEFKVVNURVMuZ2V0KCdjYWxpZGFkJykpCgogICAgICAgICMgLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGhlbHBlcnMgd2lk
:::Z2V0cwogICAgICAgIGRlZiBfYm90b24oc2VsZiwgcGFkcmUsIHRleHRvLCBjbWQs
:::IHdpZHRoPU5vbmUsIGZ1ZW50ZT1GVUVOVEVfQlROLAogICAgICAgICAgICAgICAg
:::ICAgYWx0bz0xKToKICAgICAgICAgICAgYiA9IHRrLkJ1dHRvbihwYWRyZSwgdGV4
:::dD10ZXh0bywgY29tbWFuZD1jbWQsIGZvbnQ9ZnVlbnRlLAogICAgICAgICAgICAg
:::ICAgICAgICAgICAgIHJlbGllZj0nZmxhdCcsIGJkPTAsIGN1cnNvcj0naGFuZDIn
:::LCBoZWlnaHQ9YWx0bywKICAgICAgICAgICAgICAgICAgICAgICAgICBhY3RpdmVm
:::b3JlZ3JvdW5kPScjZmZmZmZmJywgdGFrZWZvY3VzPTApCiAgICAgICAgICAgIGlm
:::IHdpZHRoOgogICAgICAgICAgICAgICAgYi5jb25maWd1cmUod2lkdGg9d2lkdGgp
:::CiAgICAgICAgICAgIGIuYmluZCgnPEVudGVyPicsIGxhbWJkYSBlLCB3PWI6IHcu
:::Y29uZmlndXJlKAogICAgICAgICAgICAgICAgYmc9VEVNQVNbc2VsZi5fdGVtYV9h
:::Y3R1YWxdWydib3Rvbl9hY3QnXSkpCiAgICAgICAgICAgIGIuYmluZCgnPExlYXZl
:::PicsIGxhbWJkYSBlLCB3PWI6IHcuY29uZmlndXJlKAogICAgICAgICAgICAgICAg
:::Ymc9VEVNQVNbc2VsZi5fdGVtYV9hY3R1YWxdWydib3RvbiddKSkKICAgICAgICAg
:::ICAgc2VsZi5fYnRucy5hcHBlbmQoYikKICAgICAgICAgICAgcmV0dXJuIGIKCiAg
:::ICAgICAgZGVmIF9wb25lcl9wbGFjZWhvbGRlcihzZWxmKToKICAgICAgICAgICAg
:::aWYgbm90IHNlbGYuZW50X3VybC5nZXQoKToKICAgICAgICAgICAgICAgIHNlbGYu
:::X2VuX3BsYWNlaG9sZGVyID0gVHJ1ZQogICAgICAgICAgICAgICAgc2VsZi5lbnRf
:::dXJsLmluc2VydCgwLCBQTEFDRUhPTERFUl9VUkwpCgogICAgICAgIGRlZiBfbGlt
:::cGlhcl91cmwoc2VsZik6CiAgICAgICAgICAgIHNlbGYuZW50X3VybC5kZWxldGUo
:::MCwgJ2VuZCcpCiAgICAgICAgICAgIHNlbGYuZW50X3VybC5mb2N1c19zZXQoKQoK
:::ICAgICAgICBkZWYgX3Jlc2V0X3VybChzZWxmKToKICAgICAgICAgICAgIiIiRGVq
:::YSBlbCBjYW1wbyBkZSBVUkwgdmFjw61vIGNvbiBzdSBwbGFjZWhvbGRlciAodHJh
:::cyB1biDDqXhpdG8pLiIiIgogICAgICAgICAgICBzZWxmLmVudF91cmwuZGVsZXRl
:::KDAsICdlbmQnKQogICAgICAgICAgICBzZWxmLl9lbl9wbGFjZWhvbGRlciA9IFRy
:::dWUKICAgICAgICAgICAgc2VsZi5fcG9uZXJfcGxhY2Vob2xkZXIoKQogICAgICAg
:::ICAgICBzZWxmLl9yZWZyZXNjYXJfcGxhY2Vob2xkZXIoKQoKICAgICAgICAjIC0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSB0
:::ZW1hCiAgICAgICAgZGVmIF9hcGxpY2FyX3RlbWEoc2VsZik6CiAgICAgICAgICAg
:::IHQgPSBURU1BU1tzZWxmLl90ZW1hX2FjdHVhbF0KICAgICAgICAgICAgdyA9IHNl
:::bGYuX3dnCiAgICAgICAgICAgIHNlbGYuY29uZmlndXJlKGJnPXRbJ2ZvbmRvJ10p
:::CiAgICAgICAgICAgIGZvciBub21icmUgaW4gKCdtYXJjbycsICdmMCcsICdndScs
:::ICdnZicsICdmYycsICdnZScpOgogICAgICAgICAgICAgICAgd1tub21icmVdLmNv
:::bmZpZ3VyZShiZz10Wydmb25kbyddKQogICAgICAgICAgICBmb3IgbGYgaW4gKHdb
:::J2d1J10sIHdbJ2dmJ10sIHdbJ2dlJ10pOgogICAgICAgICAgICAgICAgbGYuY29u
:::ZmlndXJlKGJnPXRbJ2ZvbmRvJ10sIGZnPXRbJ3RleHRvMiddKQogICAgICAgICAg
:::ICBmb3Igbm9tYnJlIGluICgnbGJsX3RlbWEnLCAnbGJsX2ZtdCcsICdsYmxfY2Fs
:::JywgJ2xibF9jYXInKToKICAgICAgICAgICAgICAgIHdbbm9tYnJlXS5jb25maWd1
:::cmUoYmc9dFsnZm9uZG8nXSwgZmc9dFsndGV4dG8nXSkKICAgICAgICAgICAgc2Vs
:::Zi5sYmxfZXN0aW1hY2lvbi5jb25maWd1cmUoYmc9dFsnZm9uZG8nXSwgZmc9dFsn
:::dGV4dG8nXSkKICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmNvbmZpZ3VyZShi
:::Zz10Wydmb25kbyddLCBmZz10Wyd0ZXh0bzInXSkKICAgICAgICAgICAgc2VsZi5l
:::bnRfdXJsLmNvbmZpZ3VyZSgKICAgICAgICAgICAgICAgIGJnPXRbJ2NhbXBvJ10s
:::IGZnPXRbJ3RleHRvJ10sIGluc2VydGJhY2tncm91bmQ9dFsndGV4dG8nXSwKICAg
:::ICAgICAgICAgICAgIGhpZ2hsaWdodGJhY2tncm91bmQ9dFsnY2FtcG9fYm9yZGUn
:::XSwKICAgICAgICAgICAgICAgIGhpZ2hsaWdodGNvbG9yPXRbJ2FjZW50byddLAog
:::ICAgICAgICAgICAgICAgZGlzYWJsZWRiYWNrZ3JvdW5kPXRbJ2NhbXBvJ10sIGRp
:::c2FibGVkZm9yZWdyb3VuZD10Wyd0ZXh0bzInXSkKICAgICAgICAgICAgc2VsZi5l
:::bnRfY2FycGV0YS5jb25maWd1cmUoCiAgICAgICAgICAgICAgICBiZz10WydjYW1w
:::byddLCBmZz10Wyd0ZXh0byddLCBpbnNlcnRiYWNrZ3JvdW5kPXRbJ3RleHRvJ10s
:::CiAgICAgICAgICAgICAgICBoaWdobGlnaHRiYWNrZ3JvdW5kPXRbJ2NhbXBvX2Jv
:::cmRlJ10sCiAgICAgICAgICAgICAgICBoaWdobGlnaHRjb2xvcj10WydhY2VudG8n
:::XSkKICAgICAgICAgICAgc2VsZi5jaGtfZW1iZWJlci5jb25maWd1cmUoCiAgICAg
:::ICAgICAgICAgICBiZz10Wydmb25kbyddLCBmZz10Wyd0ZXh0byddLCBhY3RpdmVi
:::YWNrZ3JvdW5kPXRbJ2ZvbmRvJ10sCiAgICAgICAgICAgICAgICBhY3RpdmVmb3Jl
:::Z3JvdW5kPXRbJ3RleHRvJ10sIHNlbGVjdGNvbG9yPXRbJ2NhbXBvJ10pCiAgICAg
:::ICAgICAgIGZvciBiIGluIHNlbGYuX2J0bnM6CiAgICAgICAgICAgICAgICBiLmNv
:::bmZpZ3VyZShiZz10Wydib3RvbiddLCBmZz10Wydib3Rvbl90eHQnXSwKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgIGFjdGl2ZWJhY2tncm91bmQ9dFsnYm90b25f
:::YWN0J10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBhY3RpdmVmb3JlZ3Jv
:::dW5kPXRbJ2JvdG9uX3R4dCddKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuY29u
:::ZmlndXJlKGJnPXRbJ2xvZyddLCBmZz10Wydsb2dfdHh0J10sCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgaW5zZXJ0YmFja2dyb3VuZD10Wydsb2df
:::dHh0J10pCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy50YWdfY29uZmlndXJlKCdp
:::bmZvJywgZm9yZWdyb3VuZD10Wydsb2dfdHh0J10pCiAgICAgICAgICAgIHNlbGYu
:::dHh0X2xvZy50YWdfY29uZmlndXJlKCdncmlzJywgZm9yZWdyb3VuZD10Wyd0ZXh0
:::bzInXSkKICAgICAgICAgICAgc2VsZi50eHRfbG9nLnRhZ19jb25maWd1cmUoJ3Rp
:::dHVsbycsIGZvcmVncm91bmQ9dFsndGV4dG8nXSwKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgZm9udD0oJ0NvbnNvbGFzJywgMTAsICdib2xk
:::JykpCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy50YWdfY29uZmlndXJlKCdvaycs
:::IGZvcmVncm91bmQ9dFsnb2snXSkKICAgICAgICAgICAgc2VsZi50eHRfbG9nLnRh
:::Z19jb25maWd1cmUoJ2F2aXNvJywgZm9yZWdyb3VuZD10WydhdmlzbyddKQogICAg
:::ICAgICAgICBzZWxmLnR4dF9sb2cudGFnX2NvbmZpZ3VyZSgnZXJyb3InLCBmb3Jl
:::Z3JvdW5kPXRbJ2Vycm9yJ10pCiAgICAgICAgICAgIGVzdCA9IHNlbGYuX2VzdGls
:::bwogICAgICAgICAgICBlc3QuY29uZmlndXJlKCdneC5UQ29tYm9ib3gnLAogICAg
:::ICAgICAgICAgICAgICAgICAgICAgIGZpZWxkYmFja2dyb3VuZD10WydjYW1wbydd
:::LCBiYWNrZ3JvdW5kPXRbJ2JvdG9uJ10sCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgZm9yZWdyb3VuZD10Wyd0ZXh0byddLCBhcnJvd2NvbG9yPXRbJ3RleHRvJ10s
:::CiAgICAgICAgICAgICAgICAgICAgICAgICAgYm9yZGVyY29sb3I9dFsnY2FtcG9f
:::Ym9yZGUnXSwKICAgICAgICAgICAgICAgICAgICAgICAgICBsaWdodGNvbG9yPXRb
:::J2NhbXBvX2JvcmRlJ10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgZGFya2Nv
:::bG9yPXRbJ2NhbXBvX2JvcmRlJ10sCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::aW5zZXJ0Y29sb3I9dFsndGV4dG8nXSkKICAgICAgICAgICAgZXN0Lm1hcCgnZ3gu
:::VENvbWJvYm94JywKICAgICAgICAgICAgICAgICAgICBmaWVsZGJhY2tncm91bmQ9
:::WygncmVhZG9ubHknLCB0WydjYW1wbyddKV0sCiAgICAgICAgICAgICAgICAgICAg
:::Zm9yZWdyb3VuZD1bKCdyZWFkb25seScsIHRbJ3RleHRvJ10pXSkKICAgICAgICAg
:::ICAgZXN0LmNvbmZpZ3VyZSgnZ3guSG9yaXpvbnRhbC5UUHJvZ3Jlc3NiYXInLAog
:::ICAgICAgICAgICAgICAgICAgICAgICAgIHRyb3VnaGNvbG9yPXRbJ3Ryb3VnaCdd
:::LCBiYWNrZ3JvdW5kPXRbJ2FjZW50byddLAogICAgICAgICAgICAgICAgICAgICAg
:::ICAgIGJvcmRlcmNvbG9yPXRbJ2ZvbmRvJ10sIGxpZ2h0Y29sb3I9dFsnYWNlbnRv
:::J10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgZGFya2NvbG9yPXRbJ2FjZW50
:::byddKQogICAgICAgICAgICBzZWxmLm9wdGlvbl9hZGQoJypUQ29tYm9ib3gqTGlz
:::dGJveC5iYWNrZ3JvdW5kJywgdFsnY2FtcG8nXSkKICAgICAgICAgICAgc2VsZi5v
:::cHRpb25fYWRkKCcqVENvbWJvYm94Kkxpc3Rib3guZm9yZWdyb3VuZCcsIHRbJ3Rl
:::eHRvJ10pCiAgICAgICAgICAgIHNlbGYub3B0aW9uX2FkZCgnKlRDb21ib2JveCpM
:::aXN0Ym94LnNlbGVjdEJhY2tncm91bmQnLAogICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgdFsnYm90b25fYWN0J10pCiAgICAgICAgICAgIHNlbGYub3B0aW9uX2Fk
:::ZCgnKlRDb21ib2JveCpMaXN0Ym94LnNlbGVjdEZvcmVncm91bmQnLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgdFsnYm90b25fdHh0J10pCiAgICAgICAgICAg
:::IHNlbGYuX3JlZnJlc2Nhcl9wbGFjZWhvbGRlcigpCgogICAgICAgIGRlZiBfcmVm
:::cmVzY2FyX3BsYWNlaG9sZGVyKHNlbGYpOgogICAgICAgICAgICB0ID0gVEVNQVNb
:::c2VsZi5fdGVtYV9hY3R1YWxdCiAgICAgICAgICAgIGlmIHNlbGYuX2VuX3BsYWNl
:::aG9sZGVyOgogICAgICAgICAgICAgICAgc2VsZi5lbnRfdXJsLmNvbmZpZ3VyZShm
:::Zz10WydwbGFjZWhvbGRlciddKQogICAgICAgICAgICBlbHNlOgogICAgICAgICAg
:::ICAgICAgc2VsZi5lbnRfdXJsLmNvbmZpZ3VyZShmZz10Wyd0ZXh0byddKQoKICAg
:::ICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLSBldmVudG9zCiAgICAgICAgZGVmIF9jb25lY3Rhcl9ldmVudG9zKHNl
:::bGYpOgogICAgICAgICAgICBzZWxmLmNtYl90ZW1hLmJpbmQoJzw8Q29tYm9ib3hT
:::ZWxlY3RlZD4+Jywgc2VsZi5fb25fdGVtYSkKICAgICAgICAgICAgc2VsZi5jbWJf
:::Zm9ybWF0by5iaW5kKCc8PENvbWJvYm94U2VsZWN0ZWQ+PicsIHNlbGYuX29uX2Zv
:::cm1hdG8pCiAgICAgICAgICAgIHNlbGYuY21iX2NhbGlkYWQuYmluZCgnPDxDb21i
:::b2JveFNlbGVjdGVkPj4nLCBsYW1iZGEgZTogc2VsZi5fZ3VhcmRhcigpKQogICAg
:::ICAgICAgICBzZWxmLmNoa19lbWJlYmVyLmNvbmZpZ3VyZShjb21tYW5kPXNlbGYu
:::X2d1YXJkYXIpCiAgICAgICAgICAgIHNlbGYuZW50X3VybC5iaW5kKCc8Rm9jdXNJ
:::bj4nLCBzZWxmLl9vbl9mb2N1c191cmxfaW4pCiAgICAgICAgICAgIHNlbGYuZW50
:::X3VybC5iaW5kKCc8Rm9jdXNPdXQ+Jywgc2VsZi5fb25fZm9jdXNfdXJsX291dCkK
:::ICAgICAgICAgICAgc2VsZi5lbnRfdXJsLmJpbmQoJzxSZXR1cm4+JywgbGFtYmRh
:::IGU6IHNlbGYuX2FjY2lvbl9kZXNjYXJnYXIoKSkKICAgICAgICAgICAgc2VsZi5l
:::bnRfY2FycGV0YS5iaW5kKCc8Rm9jdXNPdXQ+Jywgc2VsZi5fb25fY2FycGV0YV9l
:::c2NyaXRhKQogICAgICAgICAgICBzZWxmLnByb3RvY29sKCdXTV9ERUxFVEVfV0lO
:::RE9XJywgc2VsZi5fYWxfY2VycmFyKQogICAgICAgICAgICBzZWxmLmJpbmQoJzxD
:::b250cm9sLXU+JywgbGFtYmRhIGU6IHNlbGYuX2FjY2lvbl9hY3R1YWxpemFyKCkp
:::CiAgICAgICAgICAgIHNlbGYuYmluZCgnPENvbnRyb2wtbD4nLCBsYW1iZGEgZTog
:::c2VsZi5fbGltcGlhcl9sb2coKSkKICAgICAgICAgICAgc2VsZi5iaW5kKCc8Q29u
:::dHJvbC1VPicsIGxhbWJkYSBlOiBzZWxmLl9hY2Npb25fYWN0dWFsaXphcigpKQoK
:::ICAgICAgICBkZWYgX29uX2ZvY3VzX3VybF9pbihzZWxmLCBfZT1Ob25lKToKICAg
:::ICAgICAgICAgaWYgc2VsZi5fZW5fcGxhY2Vob2xkZXI6CiAgICAgICAgICAgICAg
:::ICBzZWxmLmVudF91cmwuZGVsZXRlKDAsICdlbmQnKQogICAgICAgICAgICAgICAg
:::c2VsZi5fZW5fcGxhY2Vob2xkZXIgPSBGYWxzZQogICAgICAgICAgICAgICAgc2Vs
:::Zi5fcmVmcmVzY2FyX3BsYWNlaG9sZGVyKCkKCiAgICAgICAgZGVmIF9vbl9mb2N1
:::c191cmxfb3V0KHNlbGYsIF9lPU5vbmUpOgogICAgICAgICAgICBpZiBub3Qgc2Vs
:::Zi5lbnRfdXJsLmdldCgpOgogICAgICAgICAgICAgICAgc2VsZi5fZW5fcGxhY2Vo
:::b2xkZXIgPSBUcnVlCiAgICAgICAgICAgICAgICBzZWxmLl9wb25lcl9wbGFjZWhv
:::bGRlcigpCiAgICAgICAgICAgICAgICBzZWxmLl9yZWZyZXNjYXJfcGxhY2Vob2xk
:::ZXIoKQoKICAgICAgICBkZWYgX29uX3RlbWEoc2VsZiwgX2U9Tm9uZSk6CiAgICAg
:::ICAgICAgIHNlbGYuX3RlbWFfYWN0dWFsID0gc2VsZi5jbWJfdGVtYS5nZXQoKQog
:::ICAgICAgICAgICBBSlVTVEVTWyd0ZW1hJ10gPSBzZWxmLl90ZW1hX2FjdHVhbAog
:::ICAgICAgICAgICBndWFyZGFyX2FqdXN0ZXMoKQogICAgICAgICAgICBzZWxmLl9h
:::cGxpY2FyX3RlbWEoKQoKICAgICAgICBkZWYgX29uX2Zvcm1hdG8oc2VsZiwgX2U9
:::Tm9uZSk6CiAgICAgICAgICAgIGZtdCA9IHNlbGYuX2ZtdF9hY3R1YWwoKQogICAg
:::ICAgICAgICBzZWxmLl9yZWNhcmdhcl9jYWxpZGFkZXMoZm10KQogICAgICAgICAg
:::ICBzZWxmLl9ndWFyZGFyKCkKICAgICAgICAgICAgc2VsZi5sYmxfZXN0aW1hY2lv
:::bi5jb25maWd1cmUoCiAgICAgICAgICAgICAgICB0ZXh0PSdJbnRyb2R1Y2UgdW5h
:::IFVSTCB5IHB1bHNhIEVzdGltYXIuJywKICAgICAgICAgICAgICAgIGZnPVRFTUFT
:::W3NlbGYuX3RlbWFfYWN0dWFsXVsndGV4dG8nXSkKCiAgICAgICAgZGVmIF9mbXRf
:::YWN0dWFsKHNlbGYpOgogICAgICAgICAgICB0ZXh0byA9IHNlbGYuY21iX2Zvcm1h
:::dG8uZ2V0KCkKICAgICAgICAgICAgZm9yIGNsYXZlLCBmIGluIEZPUk1BVE9TLml0
:::ZW1zKCk6CiAgICAgICAgICAgICAgICBpZiBmWyd0ZXh0byddID09IHRleHRvOgog
:::ICAgICAgICAgICAgICAgICAgIHJldHVybiBjbGF2ZQogICAgICAgICAgICByZXR1
:::cm4gJ0FBQycKCiAgICAgICAgZGVmIF9yZWNhcmdhcl9jYWxpZGFkZXMoc2VsZiwg
:::Y2xhdmVfZm10LCBjYWxpZGFkX3ByZXZpYT1Ob25lKToKICAgICAgICAgICAgZiA9
:::IEZPUk1BVE9TW2NsYXZlX2ZtdF0KICAgICAgICAgICAgc2VsZi5jbWJfY2FsaWRh
:::ZFsndmFsdWVzJ10gPSBmWydjYWxpZGFkZXMnXQogICAgICAgICAgICBpZiBjYWxp
:::ZGFkX3ByZXZpYSBhbmQgY2FsaWRhZF9wcmV2aWEgaW4gZlsnY2FsaWRhZGVzJ106
:::CiAgICAgICAgICAgICAgICBzZWxmLmNtYl9jYWxpZGFkLnNldChjYWxpZGFkX3By
:::ZXZpYSkKICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgIHNlbGYuY21i
:::X2NhbGlkYWQuc2V0KGZbJ2RlZmVjdG8nXSkKICAgICAgICAgICAgQUpVU1RFU1sn
:::Zm9ybWF0byddID0gY2xhdmVfZm10CiAgICAgICAgICAgIEFKVVNURVNbJ2NhbGlk
:::YWQnXSA9IHNlbGYuY21iX2NhbGlkYWQuZ2V0KCkKCiAgICAgICAgZGVmIF9ndWFy
:::ZGFyKHNlbGYpOgogICAgICAgICAgICBBSlVTVEVTWydmb3JtYXRvJ10gPSBzZWxm
:::Ll9mbXRfYWN0dWFsKCkKICAgICAgICAgICAgQUpVU1RFU1snY2FsaWRhZCddID0g
:::c2VsZi5jbWJfY2FsaWRhZC5nZXQoKQogICAgICAgICAgICBBSlVTVEVTWydlbWJl
:::YmVyJ10gPSBib29sKHNlbGYudmFyX2VtYmViZXIuZ2V0KCkpCiAgICAgICAgICAg
:::IEFKVVNURVNbJ2Rlc3Rpbm8nXSA9IHNlbGYuZW50X2NhcnBldGEuZ2V0KCkuc3Ry
:::aXAoKQogICAgICAgICAgICBndWFyZGFyX2FqdXN0ZXMoKQoKICAgICAgICBkZWYg
:::X29uX2NhcnBldGFfZXNjcml0YShzZWxmLCBfZT1Ob25lKToKICAgICAgICAgICAg
:::cCA9IFBhdGgob3MucGF0aC5leHBhbmR2YXJzKAogICAgICAgICAgICAgICAgc2Vs
:::Zi5lbnRfY2FycGV0YS5nZXQoKS5zdHJpcCgpLnN0cmlwKCciJykpKQogICAgICAg
:::ICAgICB0cnk6CiAgICAgICAgICAgICAgICBwLm1rZGlyKHBhcmVudHM9VHJ1ZSwg
:::ZXhpc3Rfb2s9VHJ1ZSkKICAgICAgICAgICAgICAgIEFKVVNURVNbJ2Rlc3Rpbm8n
:::XSA9IHN0cihwKQogICAgICAgICAgICAgICAgZ3VhcmRhcl9hanVzdGVzKCkKICAg
:::ICAgICAgICAgZXhjZXB0IE9TRXJyb3IgYXMgZToKICAgICAgICAgICAgICAgIHNl
:::bGYuX2xvZyhmJ05vIHNlIHB1ZG8gdXNhciBlc2EgY2FycGV0YToge2V9JywgJ2Vy
:::cm9yJykKCiAgICAgICAgZGVmIF9jYW1iaWFyX2NhcnBldGEoc2VsZik6CiAgICAg
:::ICAgICAgIGFjdHVhbCA9IHNlbGYuZW50X2NhcnBldGEuZ2V0KCkuc3RyaXAoKSBv
:::ciBBSlVTVEVTWydkZXN0aW5vJ10KICAgICAgICAgICAgbnVldmEgPSBmaWxlZGlh
:::bG9nLmFza2RpcmVjdG9yeSgKICAgICAgICAgICAgICAgIHRpdGxlPSdFbGlnZSBs
:::YSBjYXJwZXRhIGRvbmRlIGd1YXJkYXIgbGFzIGRlc2NhcmdhcycsCiAgICAgICAg
:::ICAgICAgICBpbml0aWFsZGlyPWFjdHVhbCBpZiBvcy5wYXRoLmlzZGlyKGFjdHVh
:::bCkgZWxzZSBzdHIoUGF0aC5ob21lKCkpKQogICAgICAgICAgICBpZiBub3QgbnVl
:::dmE6CiAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgdHJ5OgogICAg
:::ICAgICAgICAgICAgUGF0aChudWV2YSkubWtkaXIocGFyZW50cz1UcnVlLCBleGlz
:::dF9vaz1UcnVlKQogICAgICAgICAgICBleGNlcHQgT1NFcnJvciBhcyBlOgogICAg
:::ICAgICAgICAgICAgbWVzc2FnZWJveC5zaG93ZXJyb3IoJ0NhcnBldGEgbm8gdsOh
:::bGlkYScsIHN0cihlKSkKICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAg
:::ICBzZWxmLmVudF9jYXJwZXRhLmRlbGV0ZSgwLCAnZW5kJykKICAgICAgICAgICAg
:::c2VsZi5lbnRfY2FycGV0YS5pbnNlcnQoMCwgbnVldmEpCiAgICAgICAgICAgIEFK
:::VVNURVNbJ2Rlc3Rpbm8nXSA9IG51ZXZhCiAgICAgICAgICAgIGd1YXJkYXJfYWp1
:::c3RlcygpCiAgICAgICAgICAgIHNlbGYuX2xvZygnQ2FycGV0YSBkZSBndWFyZGFk
:::bzogJyArIG51ZXZhLCAnZ3JpcycpCgogICAgICAgIGRlZiBfYWJyaXJfZGVzdGlu
:::byhzZWxmKToKICAgICAgICAgICAgcCA9IFBhdGgob3MucGF0aC5leHBhbmR2YXJz
:::KAogICAgICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5nZXQoKS5zdHJpcCgp
:::LnN0cmlwKCciJykpKQogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBw
:::Lm1rZGlyKHBhcmVudHM9VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgICAgICAgICAg
:::ZXhjZXB0IE9TRXJyb3I6CiAgICAgICAgICAgICAgICBwYXNzCiAgICAgICAgICAg
:::IGFicmlyX2NhcnBldGEocCkKCiAgICAgICAgZGVmIF9hbF9jZXJyYXIoc2VsZik6
:::CiAgICAgICAgICAgIGlmIHNlbGYuX29jdXBhZG8gYW5kIG5vdCBtZXNzYWdlYm94
:::LmFza29rY2FuY2VsKAogICAgICAgICAgICAgICAgICAgICdTYWxpcicsICdIYXkg
:::dW5hIHRhcmVhIGVuIGN1cnNvLiAnCiAgICAgICAgICAgICAgICAgICAgJ8K/U2Vn
:::dXJvIHF1ZSBxdWllcmVzIHNhbGlyPycpOgogICAgICAgICAgICAgICAgcmV0dXJu
:::CiAgICAgICAgICAgIHNlbGYuZGVzdHJveSgpCgogICAgICAgICMgLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIHJlZ2lzdHJv
:::IChsb2cpCiAgICAgICAgZGVmIF9sb2coc2VsZiwgbXNnLCB0YWc9J2luZm8nKToK
:::ICAgICAgICAgICAgc2VsZi50eHRfbG9nLmNvbmZpZ3VyZShzdGF0ZT0nbm9ybWFs
:::JykKICAgICAgICAgICAgbl9saW5lYXMgPSBpbnQoc2VsZi50eHRfbG9nLmluZGV4
:::KCdlbmQtMWMnKS5zcGxpdCgnLicpWzBdKQogICAgICAgICAgICBpZiBuX2xpbmVh
:::cyA+IDkwMDoKICAgICAgICAgICAgICAgIHNlbGYudHh0X2xvZy5kZWxldGUoJzEu
:::MCcsICcyMDAuMCcpCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5pbnNlcnQoJ2Vu
:::ZCcsIHN0cihtc2cpICsgJ1xuJywgdGFnKQogICAgICAgICAgICBzZWxmLnR4dF9s
:::b2cuc2VlKCdlbmQnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuY29uZmlndXJl
:::KHN0YXRlPSdkaXNhYmxlZCcpCgogICAgICAgIGRlZiBfbGltcGlhcl9sb2coc2Vs
:::Zik6CiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5jb25maWd1cmUoc3RhdGU9J25v
:::cm1hbCcpCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5kZWxldGUoJzEuMCcsICdl
:::bmQnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuY29uZmlndXJlKHN0YXRlPSdk
:::aXNhYmxlZCcpCgogICAgICAgIGRlZiBfYm9tYmVhcl9jb2xhKHNlbGYpOgogICAg
:::ICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICB3aGlsZSBUcnVlOgogICAgICAg
:::ICAgICAgICAgICAgIGV2ID0gc2VsZi5jb2xhLmdldF9ub3dhaXQoKQogICAgICAg
:::ICAgICAgICAgICAgIHRpcG8gPSBldlswXQogICAgICAgICAgICAgICAgICAgIGlm
:::IHRpcG8gPT0gJ2xvZyc6CiAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuX2xv
:::ZyhldlsxXSwgZXZbMl0pCiAgICAgICAgICAgICAgICAgICAgZWxpZiB0aXBvID09
:::ICdwcm9nJzoKICAgICAgICAgICAgICAgICAgICAgICAgcGN0LCB0ZXh0byA9IGV2
:::WzFdLCBldlsyXQogICAgICAgICAgICAgICAgICAgICAgICBpZiBwY3QgaXMgTm9u
:::ZToKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYmFycmEuc3RvcCgp
:::CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzZWxmLmJhcnJhLmNvbmZpZ3Vy
:::ZShtb2RlPSdpbmRldGVybWluYXRlJykKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIHNlbGYuYmFycmEuc3RhcnQoNjApCiAgICAgICAgICAgICAgICAgICAgICAg
:::IGVsc2U6CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzZWxmLmJhcnJhLnN0
:::b3AoKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5iYXJyYS5jb25m
:::aWd1cmUobW9kZT0nZGV0ZXJtaW5hdGUnKQogICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgc2VsZi5iYXJyYS5jb25maWd1cmUodmFsdWU9bWF4KDAsIG1pbigxMDAs
:::IHBjdCkpKQogICAgICAgICAgICAgICAgICAgICAgICBzZWxmLmxibF9lc3RhZG8u
:::Y29uZmlndXJlKHRleHQ9dGV4dG8pCiAgICAgICAgICAgICAgICAgICAgZWxpZiB0
:::aXBvID09ICdlc3RpbWFjaW9uJzoKICAgICAgICAgICAgICAgICAgICAgICAgc2Vs
:::Zi5sYmxfZXN0aW1hY2lvbi5jb25maWd1cmUoCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICB0ZXh0PWV2WzFdLCBmZz1URU1BU1tzZWxmLl90ZW1hX2FjdHVhbF1b
:::J2FjZW50byddKQogICAgICAgICAgICAgICAgICAgIGVsaWYgdGlwbyA9PSAnZmlu
:::JzoKICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5fZmluX3RhcmVhKGV2WzFd
:::LCBldlsyXSwgZXZbM10gaWYgbGVuKGV2KSA+IDMgZWxzZSAnJykKICAgICAgICAg
:::ICAgZXhjZXB0IHF1ZXVlLkVtcHR5OgogICAgICAgICAgICAgICAgcGFzcwogICAg
:::ICAgICAgICBzZWxmLmFmdGVyKDgwLCBzZWxmLl9ib21iZWFyX2NvbGEpCgogICAg
:::ICAgICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tIHRhcmVhcwogICAgICAgIGRlZiBfaGFiaWxpdGFyX2FjY2lvbmVzKHNl
:::bGYsIG9uKToKICAgICAgICAgICAgZXN0YWRvID0gJ25vcm1hbCcgaWYgb24gZWxz
:::ZSAnZGlzYWJsZWQnCiAgICAgICAgICAgIGZvciBiIGluIChzZWxmLmJ0bl9kZXNj
:::YXJnYXIsIHNlbGYuYnRuX2NvbXByb2JhciwKICAgICAgICAgICAgICAgICAgICAg
:::IHNlbGYuYnRuX2VzdGltYXIsIHNlbGYuYnRuX2NhbWJpYXIsIHNlbGYuYnRuX2Fi
:::cmlyLAogICAgICAgICAgICAgICAgICAgICAgc2VsZi5idG5feCk6CiAgICAgICAg
:::ICAgICAgICBiLmNvbmZpZ3VyZShzdGF0ZT1lc3RhZG8sIGN1cnNvcj0naGFuZDIn
:::IGlmIG9uIGVsc2UgJ2Fycm93JykKCiAgICAgICAgZGVmIF9pbmljaWFyKHNlbGYs
:::IG9iamV0aXZvLCBjZmcsIHRleHRvKToKICAgICAgICAgICAgaWYgc2VsZi5fb2N1
:::cGFkbzoKICAgICAgICAgICAgICAgIHNlbGYuX2xvZygnWWEgaGF5IHVuYSB0YXJl
:::YSBlbiBjdXJzbzsgZXNwZXJhIGEgcXVlIHRlcm1pbmUuJywKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAnYXZpc28nKQogICAgICAgICAgICAgICAgcmV0dXJuIEZh
:::bHNlCiAgICAgICAgICAgIHNlbGYuX29jdXBhZG8gPSBUcnVlCiAgICAgICAgICAg
:::IHNlbGYuX2hhYmlsaXRhcl9hY2Npb25lcyhGYWxzZSkKICAgICAgICAgICAgc2Vs
:::Zi5sYmxfZXN0YWRvLmNvbmZpZ3VyZSh0ZXh0PXRleHRvKQogICAgICAgICAgICB0
:::aHJlYWRpbmcuVGhyZWFkKHRhcmdldD1vYmpldGl2bywgYXJncz0oY2ZnLCksIGRh
:::ZW1vbj1UcnVlKS5zdGFydCgpCiAgICAgICAgICAgIHJldHVybiBUcnVlCgogICAg
:::ICAgIGRlZiBfZmluX3RhcmVhKHNlbGYsIHRpcG8sIG9rLCBtZW5zYWplPScnKToK
:::ICAgICAgICAgICAgc2VsZi5fb2N1cGFkbyA9IEZhbHNlCiAgICAgICAgICAgIHNl
:::bGYuX2hhYmlsaXRhcl9hY2Npb25lcyhUcnVlKQogICAgICAgICAgICBzZWxmLmJh
:::cnJhLnN0b3AoKQogICAgICAgICAgICBzZWxmLmJhcnJhLmNvbmZpZ3VyZShtb2Rl
:::PSdkZXRlcm1pbmF0ZScpCiAgICAgICAgICAgIHNlbGYuYmFycmEuY29uZmlndXJl
:::KHZhbHVlPTApCiAgICAgICAgICAgIGlmIHRpcG8gPT0gJ2Rlc2NhcmdhJyBhbmQg
:::b2s6CiAgICAgICAgICAgICAgICBzZWxmLmxibF9lc3RhZG8uY29uZmlndXJlKHRl
:::eHQ9J0xpc3RvLicpCiAgICAgICAgICAgICAgICAjIExhIGRlc2NhcmdhIGZ1ZSBi
:::aWVuOiBzZSBsaW1waWEgbGEgVVJMIHBhcmEgbGEgc2lndWllbnRlLgogICAgICAg
:::ICAgICAgICAgc2VsZi5fcmVzZXRfdXJsKCkKICAgICAgICAgICAgZWxpZiBub3Qg
:::b2s6CiAgICAgICAgICAgICAgICBzZWxmLmxibF9lc3RhZG8uY29uZmlndXJlKHRl
:::eHQ9J1Rlcm1pbmFkbyBjb24gZXJyb3Jlcy4nKQogICAgICAgICAgICAgICAgaWYg
:::dGlwbyA9PSAnZGVzY2FyZ2EnOgogICAgICAgICAgICAgICAgICAgIG1lc3NhZ2Vi
:::b3guc2hvd2Vycm9yKAogICAgICAgICAgICAgICAgICAgICAgICAnRXJyb3InLCBt
:::ZW5zYWplIG9yICdObyBzZSBwdWRvIGNvbXBsZXRhciBsYSB0YXJlYS4gJwogICAg
:::ICAgICAgICAgICAgICAgICAgICAnUmV2aXNhIGVsIHJlZ2lzdHJvIHBhcmEgbcOh
:::cyBkZXRhbGxlcy4nKQoKICAgICAgICBkZWYgX3VybF92YWxpZGEoc2VsZik6CiAg
:::ICAgICAgICAgIGlmIHNlbGYuX2VuX3BsYWNlaG9sZGVyOgogICAgICAgICAgICAg
:::ICAgc2VsZi5fbG9nKCdQcmltZXJvIHBlZ2EgbGEgVVJMIGRlbCB2aWRlbyBkZSBZ
:::b3VUdWJlLicsICdhdmlzbycpCiAgICAgICAgICAgICAgICByZXR1cm4gTm9uZQog
:::ICAgICAgICAgICB1ID0gc2VsZi5lbnRfdXJsLmdldCgpLnN0cmlwKCkuc3RyaXAo
:::JyInKS5zdHJpcCgiJyIpCiAgICAgICAgICAgIGlmIG5vdCB1OgogICAgICAgICAg
:::ICAgICAgc2VsZi5fbG9nKCdMYSBVUkwgZXN0w6EgdmFjw61hLicsICdhdmlzbycp
:::CiAgICAgICAgICAgICAgICByZXR1cm4gTm9uZQogICAgICAgICAgICBpZiBub3Qg
:::cmUubWF0Y2gocideaHR0cHM/Oi8vJywgdSwgcmUuSSk6CiAgICAgICAgICAgICAg
:::ICBpZiByZS5tYXRjaChyJ153d3dcLicsIHUsIHJlLkkpOgogICAgICAgICAgICAg
:::ICAgICAgIHUgPSAnaHR0cHM6Ly8nICsgdQogICAgICAgICAgICAgICAgZWxzZToK
:::ICAgICAgICAgICAgICAgICAgICBzZWxmLl9sb2coJ0VzbyBubyBwYXJlY2UgdW5h
:::IFVSTCAoZGViZSBlbXBlemFyIHBvciAnCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICdodHRwOi8vIG8gaHR0cHM6Ly8pJywgJ2Vycm9yJykKICAgICAgICAg
:::ICAgICAgICAgICByZXR1cm4gTm9uZQogICAgICAgICAgICAjIE9KTzogYXF1w60g
:::Tk8gc2UgcXVpdGEgbGlzdD07IHNpIGxhIFVSTCB0cmFlIHVuYSBwbGF5bGlzdCwK
:::ICAgICAgICAgICAgIyBfYWNjaW9uX2Rlc2NhcmdhciBwcmVndW50YXLDoSBxdcOp
:::IGhhY2VyIGNvbiBlbGxhLgogICAgICAgICAgICByZXR1cm4gdQoKICAgICAgICBk
:::ZWYgX2FjY2lvbl9lc3RpbWFyKHNlbGYpOgogICAgICAgICAgICB1cmwgPSBzZWxm
:::Ll91cmxfdmFsaWRhKCkKICAgICAgICAgICAgaWYgbm90IHVybDoKICAgICAgICAg
:::ICAgICAgIHJldHVybgogICAgICAgICAgICBzZWxmLl9ndWFyZGFyKCkKICAgICAg
:::ICAgICAgY2ZnID0geyd1cmwnOiB1cmx9CiAgICAgICAgICAgIHNlbGYuX2luaWNp
:::YXIoc2VsZi5faGlsb19lc3RpbWFyLCBjZmcsICdFc3RpbWFuZG8gdGFtYcOxby4u
:::LicpCiAgICAgICAgICAgIHNlbGYubGJsX2VzdGltYWNpb24uY29uZmlndXJlKAog
:::ICAgICAgICAgICAgICAgdGV4dD0nQ2FsY3VsYW5kby4uLicsIGZnPVRFTUFTW3Nl
:::bGYuX3RlbWFfYWN0dWFsXVsndGV4dG8yJ10pCgogICAgICAgIGRlZiBfYWNjaW9u
:::X2Rlc2NhcmdhcihzZWxmKToKICAgICAgICAgICAgdXJsID0gc2VsZi5fdXJsX3Zh
:::bGlkYSgpCiAgICAgICAgICAgIGlmIG5vdCB1cmw6CiAgICAgICAgICAgICAgICBy
:::ZXR1cm4KICAgICAgICAgICAgc2VsZi5fZ3VhcmRhcigpCiAgICAgICAgICAgIHBs
:::YXlsaXN0ID0gRmFsc2UKICAgICAgICAgICAgaWYgZXNfdXJsX3BsYXlsaXN0KHVy
:::bCk6CiAgICAgICAgICAgICAgICByID0gbWVzc2FnZWJveC5hc2t5ZXNub2NhbmNl
:::bCgKICAgICAgICAgICAgICAgICAgICAnTXVzaWtBTEFOIOKAlCBsaXN0YSBkZSBy
:::ZXByb2R1Y2Npw7NuJywKICAgICAgICAgICAgICAgICAgICAnRXN0YSBVUkwgcGVy
:::dGVuZWNlIGEgdW5hIGxpc3RhIGRlIHJlcHJvZHVjY2nDs24uXG5cbicKICAgICAg
:::ICAgICAgICAgICAgICAnICBTw40gIOKGkiAgZGVzY2FyZ2FyIGxhIHBsYXlsaXN0
:::IGNvbXBsZXRhXG4nCiAgICAgICAgICAgICAgICAgICAgJyAgICAgICAgIChwYXVz
:::YSBkZSAyIHMgZW50cmUgY2FuY2lvbmVzKVxuJwogICAgICAgICAgICAgICAgICAg
:::ICcgIE5PICDihpIgIGRlc2NhcmdhciBzb2xvIGVzdGEgY2FuY2nDs25cbicKICAg
:::ICAgICAgICAgICAgICAgICAnICBDYW5jZWxhciAg4oaSICBubyBkZXNjYXJnYXIg
:::bmFkYScpCiAgICAgICAgICAgICAgICBpZiByIGlzIE5vbmU6CiAgICAgICAgICAg
:::ICAgICAgICAgc2VsZi5fbG9nKCdEZXNjYXJnYSBjYW5jZWxhZGEuJywgJ2dyaXMn
:::KQogICAgICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICAgICAgaWYg
:::cjoKICAgICAgICAgICAgICAgICAgICBwbGF5bGlzdCA9IFRydWUKICAgICAgICAg
:::ICAgICAgIGVsaWYgZXNfc29sb19saXN0YSh1cmwpOgogICAgICAgICAgICAgICAg
:::ICAgICMgRXMgdW5hIHBsYXlsaXN0IHB1cmE6IG5vIGhheSAidW5hIGNhbmNpw7Nu
:::IiBhaMOtCiAgICAgICAgICAgICAgICAgICAgc2VsZi5fbG9nKCdFc2EgVVJMIGVz
:::IHVuYSBsaXN0YSBjb21wbGV0YTsgc2UgZGVzY2FyZ2Fyw6EgJwogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAnZW50ZXJhLicsICdhdmlzbycpCiAgICAgICAg
:::ICAgICAgICAgICAgcGxheWxpc3QgPSBUcnVlCiAgICAgICAgICAgIGNmZyA9IHsn
:::dXJsJzogdXJsLCAncGxheWxpc3QnOiBwbGF5bGlzdH0KICAgICAgICAgICAgc2Vs
:::Zi5faW5pY2lhcihzZWxmLl9oaWxvX2Rlc2NhcmdhciwgY2ZnLCAnRGVzY2FyZ2Fu
:::ZG8uLi4nKQoKICAgICAgICBkZWYgX2FjY2lvbl9jb21wcm9iYXIoc2VsZik6CiAg
:::ICAgICAgICAgIHNlbGYuX2d1YXJkYXIoKQogICAgICAgICAgICBzZWxmLl9pbmlj
:::aWFyKHNlbGYuX2hpbG9fY29tcHJvYmFyLCB7fSwKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAnQ29tcHJvYmFuZG8gbGEgY2FycGV0YS4uLicpCgogICAgICAgIGRl
:::ZiBfYWNjaW9uX2FjdHVhbGl6YXIoc2VsZik6CiAgICAgICAgICAgIGlmIG5vdCBZ
:::VF9ETFA6CiAgICAgICAgICAgICAgICBzZWxmLl9sb2coJ3l0LWRscCBubyBlc3TD
:::oSBpbnN0YWxhZG87IGVqZWN1dGEgJwogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICdEZXNjYXJnYWRvck11c2ljYS5iYXQuJywgJ2Vycm9yJykKICAgICAgICAgICAg
:::ICAgIHJldHVybgogICAgICAgICAgICBzZWxmLl9pbmljaWFyKHNlbGYuX2hpbG9f
:::YWN0dWFsaXphciwge30sICdBY3R1YWxpemFuZG8geXQtZGxwLi4uJykKCiAgICAg
:::ICAgIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0gaGlsb3MKICAgICAgICBkZWYgX2hpbG9fZXN0aW1hcihzZWxmLCBjZmcp
:::OgogICAgICAgICAgICBjb2xhID0gc2VsZi5jb2xhCgogICAgICAgICAgICBkZWYg
:::bG9nKG0sIHQ9J2luZm8nKToKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnbG9n
:::JywgbSwgdCkpCgogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBpZiBZ
:::VF9ETFAgaXMgTm9uZToKICAgICAgICAgICAgICAgICAgICBsb2coJ3l0LWRscCBu
:::byBlc3TDoSBpbnN0YWxhZG8uIEVqZWN1dGEgJwogICAgICAgICAgICAgICAgICAg
:::ICAgICAnRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0IHBhcmEgaW5zdGFsYXJsby4nLCAn
:::ZXJyb3InKQogICAgICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZXN0aW1hY2lv
:::bicsICd5dC1kbHAgbm8gZGlzcG9uaWJsZScpKQogICAgICAgICAgICAgICAgICAg
:::IHJldHVybgogICAgICAgICAgICAgICAgbG9nKCdPYnRlbmllbmRvIGluZm9ybWFj
:::acOzbiBkZWwgdmlkZW8uLi4nLCAnZ3JpcycpCiAgICAgICAgICAgICAgICBvID0g
:::eydxdWlldCc6IFRydWUsICdub193YXJuaW5ncyc6IFRydWUsICdub3BsYXlsaXN0
:::JzogVHJ1ZSwKICAgICAgICAgICAgICAgICAgICAgJ3NvY2tldF90aW1lb3V0Jzog
:::MzAsICdsb2dnZXInOiBSRUdJU1RST30KICAgICAgICAgICAgICAgIGlmIGVzX3Vy
:::bF9wbGF5bGlzdChjZmdbJ3VybCddKToKICAgICAgICAgICAgICAgICAgICBsb2co
:::JyhsYSBVUkwgY29udGllbmUgdW5hIHBsYXlsaXN0OiBsYSBlc3RpbWFjacOzbiBl
:::cyAnCiAgICAgICAgICAgICAgICAgICAgICAgICdzb2xvIGRlbCB2aWRlbyBwZWdh
:::ZG8pJywgJ2dyaXMnKQogICAgICAgICAgICAgICAgd2l0aCBZVF9ETFAuWW91dHVi
:::ZURMKG8pIGFzIHlkbDoKICAgICAgICAgICAgICAgICAgICBpbmZvID0geWRsLmV4
:::dHJhY3RfaW5mbyhjZmdbJ3VybCddLCBkb3dubG9hZD1GYWxzZSkKICAgICAgICAg
:::ICAgICAgIGR1ciA9IGluZm8uZ2V0KCdkdXJhdGlvbicpCiAgICAgICAgICAgICAg
:::ICBpZiBub3QgZHVyOgogICAgICAgICAgICAgICAgICAgIGxvZygnTm8gc2UgcHVk
:::byBvYnRlbmVyIGxhIGR1cmFjacOzbiBkZWwgdmlkZW8uJywgJ2Vycm9yJykKICAg
:::ICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2VzdGltYWNpb24nLCAnU2luIGRh
:::dG9zIHBhcmEgZXN0aW1hcicpKQogICAgICAgICAgICAgICAgICAgIHJldHVybgog
:::ICAgICAgICAgICAgICAgY2xhdmUgPSBzZWxmLl9mbXRfYWN0dWFsX3NvbG8oQUpV
:::U1RFUy5nZXQoJ2Zvcm1hdG8nLCAnQUFDJykpCiAgICAgICAgICAgICAgICB0YW0g
:::PSBlc3RpbWFyX2J5dGVzKGR1ciwgY2xhdmUsIEFKVVNURVMuZ2V0KCdjYWxpZGFk
:::JyksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJvb2woQUpV
:::U1RFUy5nZXQoJ2VtYmViZXInLCBUcnVlKSkpCiAgICAgICAgICAgICAgICB0aXR1
:::bG8gPSBzdHIoaW5mby5nZXQoJ3RpdGxlJykgb3IgJycpWzo3MF0KICAgICAgICAg
:::ICAgICAgIGlmIHRpdHVsbzoKICAgICAgICAgICAgICAgICAgICBsb2coJ+KZqiAn
:::ICsgdGl0dWxvLCAndGl0dWxvJykKICAgICAgICAgICAgICAgIHRleHRvID0gKGYn
:::fnt0YW0gLyAxMDQ4NTc2Oi4xZn0gTUIgwrcgJwogICAgICAgICAgICAgICAgICAg
:::ICAgICAgZidkdXJhY2nDs24ge2ZtdF90aWVtKGR1cil9IMK3ICcKICAgICAgICAg
:::ICAgICAgICAgICAgICAgIGYne2NsYXZlfSB7QUpVU1RFUy5nZXQoImNhbGlkYWQi
:::LCAiIil9Jy5yc3RyaXAoKSkKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZXN0
:::aW1hY2lvbicsIHRleHRvKSkKICAgICAgICAgICAgICAgIGxvZygnRXN0aW1hY2nD
:::s246ICcgKyB0ZXh0bywgJ29rJykKICAgICAgICAgICAgICAgIGxvZygnRWwgdGFt
:::YcOxbyByZWFsIHB1ZWRlIHZhcmlhciBhbGdvIHNlZ8O6biBsYSBmdWVudGUuJywK
:::ICAgICAgICAgICAgICAgICAgICAnZ3JpcycpCiAgICAgICAgICAgIGV4Y2VwdCBF
:::eGNlcHRpb24gYXMgZToKICAgICAgICAgICAgICAgIGxvZyhmJ05vIHNlIHB1ZG8g
:::ZXN0aW1hcjoge3NlbGYuX21zZ19lcnJvcihlKX0nLCAnZXJyb3InKQogICAgICAg
:::ICAgICAgICAgY29sYS5wdXQoKCdlc3RpbWFjaW9uJywgJ05vIHNlIHB1ZG8gZXN0
:::aW1hcicpKQogICAgICAgICAgICBmaW5hbGx5OgogICAgICAgICAgICAgICAgY29s
:::YS5wdXQoKCdmaW4nLCAnZXN0aW1hY2lvbicsIFRydWUsICcnKSkKCiAgICAgICAg
:::ZGVmIF9mbXRfYWN0dWFsX3NvbG8oc2VsZiwgY2xhdmUpOgogICAgICAgICAgICBy
:::ZXR1cm4gY2xhdmUgaWYgY2xhdmUgaW4gRk9STUFUT1MgZWxzZSAnQUFDJwoKICAg
:::ICAgICBkZWYgX2Rlc2Nhcmdhcl91bmEoc2VsZiwgdXJsLCBjbGF2ZSwgY2FsaWRh
:::ZF9hcmcsIGVtYmViZXIsIGRlc3Rpbm8sCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIGNvbGEpOgogICAgICAgICAgICAiIiJEZXNjYXJnYSB5IGNvbnZpZXJ0ZSBV
:::TkEgVVJMLiBEZXZ1ZWx2ZSBlbCBQYXRoIGZpbmFsIG8gTm9uZS4iIiIKICAgICAg
:::ICAgICAgaWYgY2xhdmUgPT0gJ1dNQSc6CiAgICAgICAgICAgICAgICByZXR1cm4g
:::ZGVzY2FyZ2FyX3dtYSh1cmwsIGNhbGlkYWRfYXJnLCBkZXN0aW5vLCBlbWJlYmVy
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sYSlbMV0K
:::ICAgICAgICAgICAgaWYgY2xhdmUgPT0gJ0FWSSc6CiAgICAgICAgICAgICAgICBy
:::ZXR1cm4gZGVzY2FyZ2FyX2F2aSh1cmwsIGRlc3Rpbm8sIGNvbGEpWzFdCiAgICAg
:::ICAgICAgIHJldHVybiBkZXNjYXJnYXJfYXVkaW8odXJsLCBjbGF2ZSwgY2FsaWRh
:::ZF9hcmcsIGRlc3Rpbm8sIGVtYmViZXIsCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgY29sYSlbMV0KCiAgICAgICAgZGVmIF9kZXNjYXJnYXJfcGxh
:::eWxpc3Qoc2VsZiwgdXJsLCBjbGF2ZSwgY2FsaWRhZF9hcmcsIGVtYmViZXIsCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGVzdGlubywgY29sYSk6CiAg
:::ICAgICAgICAgICIiIkJhamEgdW5hIGxpc3RhIGVudGVyYSwgY29uIDIgcyBkZSBk
:::ZXNjYW5zbyBlbnRyZSBjYW5jaW9uZXMKICAgICAgICAgICAgcGFyYSBubyBzYXR1
:::cmFyIGEgWW91VHViZS4gRGV2dWVsdmUgKGRlc2NhcmdhZGFzLCB0b3RhbCkuIiIi
:::CiAgICAgICAgICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgogICAgICAgICAgICAg
:::ICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICAgICAgICAgIGxvZygnTGV5
:::ZW5kbyBsYSBsaXN0YSBkZSByZXByb2R1Y2Npw7NuLi4uJywgJ2dyaXMnKQogICAg
:::ICAgICAgICBvID0geydxdWlldCc6IFRydWUsICdub193YXJuaW5ncyc6IFRydWUs
:::CiAgICAgICAgICAgICAgICAgJ2V4dHJhY3RfZmxhdCc6ICdpbl9wbGF5bGlzdCcs
:::ICdzb2NrZXRfdGltZW91dCc6IDMwLAogICAgICAgICAgICAgICAgICdsb2dnZXIn
:::OiBSRUdJU1RST30KICAgICAgICAgICAgd2l0aCBZVF9ETFAuWW91dHViZURMKG8p
:::IGFzIHlkbDoKICAgICAgICAgICAgICAgIGluZm8gPSB5ZGwuZXh0cmFjdF9pbmZv
:::KHVybCwgZG93bmxvYWQ9RmFsc2UpCiAgICAgICAgICAgIGVudHJhZGFzID0gbGlz
:::dChpbmZvLmdldCgnZW50cmllcycpIG9yIFtdKQogICAgICAgICAgICBpZiBub3Qg
:::ZW50cmFkYXM6CiAgICAgICAgICAgICAgICBsb2coJ05vIHNlIHZpbyBuaW5ndW5h
:::IGNhbmNpw7NuIGVuIGxhIGxpc3RhOyBzZSBpbnRlbnRhICcKICAgICAgICAgICAg
:::ICAgICAgICAnY29tbyB2aWRlbyBzdWVsdG8uJywgJ2F2aXNvJykKICAgICAgICAg
:::ICAgICAgIGFyY2hpdm8gPSBzZWxmLl9kZXNjYXJnYXJfdW5hKHNpbl9wbGF5bGlz
:::dCh1cmwpWzBdLCBjbGF2ZSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgIGNhbGlkYWRfYXJnLCBlbWJlYmVyLCBkZXN0aW5vLAog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29s
:::YSkKICAgICAgICAgICAgICAgIHJldHVybiAoMSBpZiBhcmNoaXZvIGVsc2UgMCks
:::IDEKICAgICAgICAgICAgdGl0dWxvX3BsID0gc3RyKGluZm8uZ2V0KCd0aXRsZScp
:::IG9yICdsaXN0YScpWzo3MF0KICAgICAgICAgICAgdG90YWwgPSBsZW4oZW50cmFk
:::YXMpCiAgICAgICAgICAgIGxvZyhmJ1BsYXlsaXN0IMKre3RpdHVsb19wbH3CuyDi
:::gJQge3RvdGFsfSB2w61kZW8ocykuJywgJ3RpdHVsbycpCiAgICAgICAgICAgIG9r
:::YXMgPSAwCiAgICAgICAgICAgIGZhbGxvcyA9IFtdCiAgICAgICAgICAgIGZvciBp
:::LCBlIGluIGVudW1lcmF0ZShlbnRyYWRhcyk6CiAgICAgICAgICAgICAgICB1ID0g
:::c3RyKGUuZ2V0KCd3ZWJwYWdlX3VybCcpIG9yIGUuZ2V0KCd1cmwnKSBvciAnJykK
:::ICAgICAgICAgICAgICAgIGlmIHUgYW5kIG5vdCB1LnN0YXJ0c3dpdGgoJ2h0dHAn
:::KToKICAgICAgICAgICAgICAgICAgICB1ID0gJ2h0dHBzOi8vd3d3LnlvdXR1YmUu
:::Y29tL3dhdGNoP3Y9JyArIHUKICAgICAgICAgICAgICAgIGlmIG5vdCB1IGFuZCBl
:::LmdldCgnaWQnKToKICAgICAgICAgICAgICAgICAgICB1ID0gJ2h0dHBzOi8vd3d3
:::LnlvdXR1YmUuY29tL3dhdGNoP3Y9JyArIHN0cihlWydpZCddKQogICAgICAgICAg
:::ICAgICAgdGl0ID0gc3RyKGUuZ2V0KCd0aXRsZScpIG9yIHUgb3IgJz8nKVs6NzBd
:::CiAgICAgICAgICAgICAgICBpZiBpOgogICAgICAgICAgICAgICAgICAgIHRpbWUu
:::c2xlZXAoMikgICAjIGRlc2NhbnNvIGVudHJlIGNhbmNpb25lcwogICAgICAgICAg
:::ICAgICAgbG9nKGYnW3tpICsgMX0ve3RvdGFsfV0g4pmqIHt0aXR9JywgJ3RpdHVs
:::bycpCiAgICAgICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICAgICAgYXJj
:::aGl2byA9IHNlbGYuX2Rlc2Nhcmdhcl91bmEodSwgY2xhdmUsIGNhbGlkYWRfYXJn
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIGVtYmViZXIsIGRlc3Rpbm8sIGNvbGEpCiAgICAgICAgICAgICAgICBleGNl
:::cHQgRXhjZXB0aW9uIGFzIGUyOgogICAgICAgICAgICAgICAgICAgIGFyY2hpdm8g
:::PSBOb25lCiAgICAgICAgICAgICAgICAgICAgbG9nKGYn4pyWIFt7aSArIDF9L3t0
:::b3RhbH1dIEZhbGzDszoge3NlbGYuX21zZ19lcnJvcihlMil9JywKICAgICAgICAg
:::ICAgICAgICAgICAgICAgJ2Vycm9yJykKICAgICAgICAgICAgICAgIGlmIGFyY2hp
:::dm8gYW5kIFBhdGgoYXJjaGl2bykuZXhpc3RzKCk6CiAgICAgICAgICAgICAgICAg
:::ICAgdHJ5OgogICAgICAgICAgICAgICAgICAgICAgICB0YW0gPSBmbXRfdGFtKFBh
:::dGgoYXJjaGl2bykuc3RhdCgpLnN0X3NpemUpCiAgICAgICAgICAgICAgICAgICAg
:::ZXhjZXB0IE9TRXJyb3I6CiAgICAgICAgICAgICAgICAgICAgICAgIHRhbSA9ICc/
:::JwogICAgICAgICAgICAgICAgICAgIGxvZyhmJyAgIOKclCB7UGF0aChhcmNoaXZv
:::KS5uYW1lfSAgKHt0YW19KScsICdvaycpCiAgICAgICAgICAgICAgICAgICAgb2th
:::cyArPSAxCiAgICAgICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAg
:::IGZhbGxvcy5hcHBlbmQodGl0KQogICAgICAgICAgICBsb2coZidQbGF5bGlzdCB0
:::ZXJtaW5hZGE6IHtva2FzfSBkZSB7dG90YWx9IGRlc2NhcmdhZGEocykuJywKICAg
:::ICAgICAgICAgICAgICdvaycgaWYgbm90IGZhbGxvcyBlbHNlICdhdmlzbycpCiAg
:::ICAgICAgICAgIGlmIGZhbGxvczoKICAgICAgICAgICAgICAgIGxvZygnU2luIGRl
:::c2NhcmdhcjogJwogICAgICAgICAgICAgICAgICAgICsgJyDCtyAnLmpvaW4oZls6
:::NDBdIGZvciBmIGluIGZhbGxvc1s6OF0pCiAgICAgICAgICAgICAgICAgICAgKyAo
:::Jy4uLicgaWYgbGVuKGZhbGxvcykgPiA4IGVsc2UgJycpLCAnZ3JpcycpCiAgICAg
:::ICAgICAgIHJldHVybiBva2FzLCB0b3RhbAoKICAgICAgICBkZWYgX2hpbG9fZGVz
:::Y2FyZ2FyKHNlbGYsIGNmZyk6CiAgICAgICAgICAgIGNvbGEgPSBzZWxmLmNvbGEK
:::CiAgICAgICAgICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgogICAgICAgICAgICAg
:::ICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICAgICAgICAgIHVybCA9IGNm
:::Z1sndXJsJ10KICAgICAgICAgICAgY2xhdmUgPSBzZWxmLl9mbXRfYWN0dWFsX3Nv
:::bG8oQUpVU1RFUy5nZXQoJ2Zvcm1hdG8nLCAnQUFDJykpCiAgICAgICAgICAgIGNh
:::bGlkYWQgPSBBSlVTVEVTLmdldCgnY2FsaWRhZCcsICcxMjhrJykKICAgICAgICAg
:::ICAgZW1iZWJlciA9IGJvb2woQUpVU1RFUy5nZXQoJ2VtYmViZXInLCBUcnVlKSkK
:::ICAgICAgICAgICAgZGVzdGlubyA9IFBhdGgob3MucGF0aC5leHBhbmR2YXJzKAog
:::ICAgICAgICAgICAgICAgc3RyKEFKVVNURVMuZ2V0KCdkZXN0aW5vJywgX2Rlc3Rp
:::bm9fcG9yX2RlZmVjdG8oKSkpKSkKICAgICAgICAgICAgdHJ5OgogICAgICAgICAg
:::ICAgICAgaWYgWVRfRExQIGlzIE5vbmU6CiAgICAgICAgICAgICAgICAgICAgbG9n
:::KCd5dC1kbHAgbm8gZXN0w6EgaW5zdGFsYWRvLiBFamVjdXRhICcKICAgICAgICAg
:::ICAgICAgICAgICAgICAgJ0Rlc2NhcmdhZG9yTXVzaWNhLmJhdCBwYXJhIGluc3Rh
:::bGFybG8uJywgJ2Vycm9yJykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgo
:::J2ZpbicsICdkZXNjYXJnYScsIEZhbHNlLAogICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAneXQtZGxwIG5vIGVzdMOhIGluc3RhbGFkby4nKSkKICAgICAgICAg
:::ICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgICAgIGRlc3Rpbm8ubWtkaXIo
:::cGFyZW50cz1UcnVlLCBleGlzdF9vaz1UcnVlKQogICAgICAgICAgICAgICAgaWYg
:::Y2xhdmUgaW4gKCdGTEFDJywgJ1dBVicpOgogICAgICAgICAgICAgICAgICAgIGNh
:::bGlkYWRfYXJnID0gJzAnCiAgICAgICAgICAgICAgICBlbHNlOgogICAgICAgICAg
:::ICAgICAgICAgIGNhbGlkYWRfYXJnID0gKHJlLnN1YihyJ1teMC05XScsICcnLCBz
:::dHIoY2FsaWRhZCkpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::b3IgKCcxMjgnIGlmIGNsYXZlID09ICdBQUMnIGVsc2UgJzMyMCcpKQogICAgICAg
:::ICAgICAgICAgaWYgY2ZnLmdldCgncGxheWxpc3QnKToKICAgICAgICAgICAgICAg
:::ICAgICBva2FzLCB0b3RhbCA9IHNlbGYuX2Rlc2Nhcmdhcl9wbGF5bGlzdCgKICAg
:::ICAgICAgICAgICAgICAgICAgICAgdXJsLCBjbGF2ZSwgY2FsaWRhZF9hcmcsIGVt
:::YmViZXIsIGRlc3Rpbm8sIGNvbGEpCiAgICAgICAgICAgICAgICAgICAgaWYgb2th
:::cyBhbmQgb2thcyA9PSB0b3RhbDoKICAgICAgICAgICAgICAgICAgICAgICAgbG9n
:::KGYnQ2FycGV0YToge2Rlc3Rpbm99JywgJ2dyaXMnKQogICAgICAgICAgICAgICAg
:::ICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdkZXNjYXJnYScsIFRydWUsICcnKSkK
:::ICAgICAgICAgICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgICAg
:::ICBjb2xhLnB1dCgoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZmluJywg
:::J2Rlc2NhcmdhJywgRmFsc2UsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBm
:::J1NlIGRlc2Nhcmdhcm9uIHtva2FzfSBkZSB7dG90YWx9IGRlIGxhICcKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICdwbGF5bGlzdC4gTGEgVVJMIG5vIHNlIGhh
:::IGJvcnJhZG8gcG9yIHNpICcKICAgICAgICAgICAgICAgICAgICAgICAgICAgICdx
:::dWllcmVzIHJlaW50ZW50YXJsby4nKSkKICAgICAgICAgICAgICAgICAgICByZXR1
:::cm4KICAgICAgICAgICAgICAgIGFyY2hpdm8gPSBzZWxmLl9kZXNjYXJnYXJfdW5h
:::KHNpbl9wbGF5bGlzdCh1cmwpWzBdLCBjbGF2ZSwKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNhbGlkYWRfYXJnLCBlbWJlYmVy
:::LCBkZXN0aW5vLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgY29sYSkKICAgICAgICAgICAgICAgIGlmIGFyY2hpdm8gYW5kIFBh
:::dGgoYXJjaGl2bykuZXhpc3RzKCk6CiAgICAgICAgICAgICAgICAgICAgYXJjaGl2
:::byA9IFBhdGgoYXJjaGl2bykKICAgICAgICAgICAgICAgICAgICB0cnk6CiAgICAg
:::ICAgICAgICAgICAgICAgICAgIHRhbSA9IGZtdF90YW0oYXJjaGl2by5zdGF0KCku
:::c3Rfc2l6ZSkKICAgICAgICAgICAgICAgICAgICBleGNlcHQgT1NFcnJvcjoKICAg
:::ICAgICAgICAgICAgICAgICAgICAgdGFtID0gJz8nCiAgICAgICAgICAgICAgICAg
:::ICAgbG9nKGYn4pyUIMKhTGlzdG8hICB7YXJjaGl2by5uYW1lfSAgKHt0YW19KScs
:::ICdvaycpCiAgICAgICAgICAgICAgICAgICAgbG9nKGYnQ2FycGV0YToge2FyY2hp
:::dm8ucGFyZW50fScsICdncmlzJykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1
:::dCgoJ2ZpbicsICdkZXNjYXJnYScsIFRydWUsICcnKSkKICAgICAgICAgICAgICAg
:::IGVsc2U6CiAgICAgICAgICAgICAgICAgICAgbG9nKCdFbCBhcmNoaXZvIGZpbmFs
:::IG5vIGFwYXJlY2nDsyBkb25kZSBzZSBlc3BlcmFiYS4nLAogICAgICAgICAgICAg
:::ICAgICAgICAgICAnZXJyb3InKQogICAgICAgICAgICAgICAgICAgIGNvbGEucHV0
:::KCgnZmluJywgJ2Rlc2NhcmdhJywgRmFsc2UsICcnKSkKICAgICAgICAgICAgZXhj
:::ZXB0IEV4Y2VwdGlvbiBhcyBlOgogICAgICAgICAgICAgICAgbm9tYnJlX2V4YyA9
:::IHR5cGUoZSkuX19uYW1lX18KICAgICAgICAgICAgICAgIGlmIG5vbWJyZV9leGMg
:::PT0gJ0Rvd25sb2FkRXJyb3InOgogICAgICAgICAgICAgICAgICAgIGxpbmVhcyA9
:::IFtsIGZvciBsIGluIHN0cihlKS5zdHJpcCgpLnNwbGl0bGluZXMoKSBpZiBsLnN0
:::cmlwKCldCiAgICAgICAgICAgICAgICAgICAgbXNnID0gbGluZWFzWzBdWzozMDBd
:::IGlmIGxpbmVhcyBlbHNlICdlcnJvciBkZXNjb25vY2lkbycKICAgICAgICAgICAg
:::ICAgICAgICBsb2coJ+KcliBObyBzZSBwdWRvIGRlc2NhcmdhcjogJyArIG1zZywg
:::J2Vycm9yJykKICAgICAgICAgICAgICAgICAgICBsb2coJ0NvbnNlam9zOiByZXZp
:::c2EgbGEgVVJMIHkgdHUgY29uZXhpw7NuOyBzaSBZb3VUdWJlICcKICAgICAgICAg
:::ICAgICAgICAgICAgICAgJ2NhbWJpw7MgYWxnbywgcHVsc2EgQ3RybCtVIChhY3R1
:::YWxpemFyIHl0LWRscCkgeSAnCiAgICAgICAgICAgICAgICAgICAgICAgICdyZWlu
:::dGVudGEuJywgJ2dyaXMnKQogICAgICAgICAgICAgICAgZWxzZToKICAgICAgICAg
:::ICAgICAgICAgICBsb2coZifinJYgRXJyb3IgaW5lc3BlcmFkbyAoe25vbWJyZV9l
:::eGN9KToge2V9JywgJ2Vycm9yJykKICAgICAgICAgICAgICAgICAgICB0YiA9IHRy
:::YWNlYmFjay5mb3JtYXRfZXhjKGxpbWl0PTMpCiAgICAgICAgICAgICAgICAgICAg
:::dHJ5OgogICAgICAgICAgICAgICAgICAgICAgICB3aXRoIG9wZW4oTE9HX0VSUk9S
:::RVMsICdhJywgZW5jb2Rpbmc9J3V0Zi04JykgYXMgZmg6CiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICBmaC53cml0ZSh0YiArICdcbicpCiAgICAgICAgICAgICAg
:::ICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgICAgICAgICAgICAg
:::cGFzcwogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnZGVzY2FyZ2En
:::LCBGYWxzZSwKICAgICAgICAgICAgICAgICAgICAgICAgICAnTm8gc2UgcHVkbyBj
:::b21wbGV0YXIgbGEgZGVzY2FyZ2EuIFJldmlzYSBlbCAnCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgJ3JlZ2lzdHJvIHBhcmEgbcOhcyBkZXRhbGxlcy4nKSkKCiAg
:::ICAgICAgZGVmIF9oaWxvX2NvbXByb2JhcihzZWxmLCBjZmcpOgogICAgICAgICAg
:::ICBjb2xhID0gc2VsZi5jb2xhCgogICAgICAgICAgICBkZWYgbG9nKG0sIHQ9J2lu
:::Zm8nKToKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgog
:::ICAgICAgICAgICBjYXJwZXRhID0gUGF0aChvcy5wYXRoLmV4cGFuZHZhcnMoCiAg
:::ICAgICAgICAgICAgICBzdHIoQUpVU1RFUy5nZXQoJ2Rlc3Rpbm8nLCBfZGVzdGlu
:::b19wb3JfZGVmZWN0bygpKSkpKQogICAgICAgICAgICB0cnk6CiAgICAgICAgICAg
:::ICAgICBpZiBub3QgY2FycGV0YS5pc19kaXIoKToKICAgICAgICAgICAgICAgICAg
:::ICBsb2coZidMYSBjYXJwZXRhIHRvZGF2w61hIG5vIGV4aXN0ZToge2NhcnBldGF9
:::JywgJ2F2aXNvJykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2Zpbics
:::ICdjb21wcm9iYWNpb24nLCBUcnVlLCAnJykpCiAgICAgICAgICAgICAgICAgICAg
:::cmV0dXJuCiAgICAgICAgICAgICAgICBpZiBGRlBST0JFIGlzIE5vbmU6CiAgICAg
:::ICAgICAgICAgICAgICAgbG9nKCdmZnByb2JlIG5vIGVzdMOhIGRpc3BvbmlibGUg
:::KHZpZW5lIGNvbiBGRm1wZWcpLiAnCiAgICAgICAgICAgICAgICAgICAgICAgICdF
:::amVjdXRhIERlc2NhcmdhZG9yTXVzaWNhLmJhdCBwYXJhIGluc3RhbGFybG8uJywK
:::ICAgICAgICAgICAgICAgICAgICAgICAgJ2Vycm9yJykKICAgICAgICAgICAgICAg
:::ICAgICBjb2xhLnB1dCgoJ2ZpbicsICdjb21wcm9iYWNpb24nLCBUcnVlLCAnJykp
:::CiAgICAgICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgICAgICBleHRz
:::ID0gKCcubTRhJywgJy5tcDMnLCAnLmZsYWMnLCAnLndhdicsICcud21hJywgJy5h
:::dmknKQogICAgICAgICAgICAgICAgYXJjaGl2b3MgPSBbcCBmb3IgcCBpbiBzb3J0
:::ZWQoY2FycGV0YS5yZ2xvYignKicpKQogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgaWYgcC5pc19maWxlKCkgYW5kIHAuc3VmZml4Lmxvd2VyKCkgaW4gZXh0cwog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgYW5kICdfdG1wJyBub3QgaW4gcC5w
:::YXJ0c10KICAgICAgICAgICAgICAgIGxvZyhmJ0NvbXByb2JhbmRvIHtsZW4oYXJj
:::aGl2b3MpfSBhcmNoaXZvKHMpIGVuICcKICAgICAgICAgICAgICAgICAgICBmJ3tj
:::YXJwZXRhfSAuLi4nLCAndGl0dWxvJykKICAgICAgICAgICAgICAgIGlmIG5vdCBh
:::cmNoaXZvczoKICAgICAgICAgICAgICAgICAgICBsb2coJ05vIGhheSBhcmNoaXZv
:::cyBkZSBhdWRpbyBvIHZpZGVvIHRvZGF2w61hLicsICdncmlzJykKICAgICAgICAg
:::ICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdjb21wcm9iYWNpb24nLCBUcnVl
:::LCAnJykpCiAgICAgICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgICAg
:::ICB0b3RhbCA9IDAKICAgICAgICAgICAgICAgIGJhamFzID0gMAogICAgICAgICAg
:::ICAgICAgZm9yIHAgaW4gYXJjaGl2b3M6CiAgICAgICAgICAgICAgICAgICAgdHJ5
:::OgogICAgICAgICAgICAgICAgICAgICAgICByID0gc3VicHJvY2Vzcy5ydW4oCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBbc3RyKEZGUFJPQkUpLCAnLXYnLCAn
:::ZXJyb3InLCAnLXNob3dfZW50cmllcycsCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgJ2Zvcm1hdD1iaXRfcmF0ZSxkdXJhdGlvbixzaXplJywgJy1vZicsICdq
:::c29uJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICBzdHIocCldLAogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgc3Rkb3V0PXN1YnByb2Nlc3MuUElQRSwg
:::c3RkZXJyPXN1YnByb2Nlc3MuUElQRSwKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIHRleHQ9VHJ1ZSwgZW5jb2Rpbmc9J3V0Zi04JywgZXJyb3JzPSdyZXBsYWNl
:::JywKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRpbWVvdXQ9MzApCiAgICAg
:::ICAgICAgICAgICAgICAgICAgIGRhdG9zID0ganNvbi5sb2FkcyhyLnN0ZG91dCBv
:::ciAne30nKS5nZXQoJ2Zvcm1hdCcsIHt9KQogICAgICAgICAgICAgICAgICAgICAg
:::ICBrYnBzID0gaW50KGZsb2F0KGRhdG9zLmdldCgnYml0X3JhdGUnKSBvciAwKSAv
:::IDEwMDApCiAgICAgICAgICAgICAgICAgICAgICAgIGR1ciA9IGZsb2F0KGRhdG9z
:::LmdldCgnZHVyYXRpb24nKSBvciAwKQogICAgICAgICAgICAgICAgICAgICAgICB0
:::YW0gPSBpbnQoZmxvYXQoZGF0b3MuZ2V0KCdzaXplJykgb3IgMCkpCiAgICAgICAg
:::ICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgICAgICAg
:::ICAgICAgbG9nKGYnwrcge3AubmFtZVs6NjBdfSDigJQgbm8gc2UgcHVkbyBsZWVy
:::JywgJ2F2aXNvJykKICAgICAgICAgICAgICAgICAgICAgICAgY29udGludWUKICAg
:::ICAgICAgICAgICAgICAgICB0b3RhbCArPSB0YW0KICAgICAgICAgICAgICAgICAg
:::ICB0ZXh0bywgbml2ZWwgPSBjbGFzZV9jYWxpZGFkKHAuc3VmZml4Lmxvd2VyKCks
:::IGticHMpCiAgICAgICAgICAgICAgICAgICAgaWYgbml2ZWwgPT0gMjoKICAgICAg
:::ICAgICAgICAgICAgICAgICAgYmFqYXMgKz0gMQogICAgICAgICAgICAgICAgICAg
:::IHRhZyA9ICgnb2snIGlmIG5pdmVsID09IDAKICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgZWxzZSAoJ2F2aXNvJyBpZiBuaXZlbCA9PSAxIGVsc2UgJ2Vycm9yJykp
:::CiAgICAgICAgICAgICAgICAgICAgbG9nKGYnwrcge3AubmFtZVs6NThdfSDigJQg
:::e3RleHRvfSDCtyB7Zm10X3RpZW0oZHVyKX0gwrcgJwogICAgICAgICAgICAgICAg
:::ICAgICAgICBmJ3tmbXRfdGFtKHRhbSl9JywgdGFnKQogICAgICAgICAgICAgICAg
:::bG9nKGYnUmVzdWx0YWRvOiB7bGVuKGFyY2hpdm9zKX0gYXJjaGl2byhzKSDCtyAn
:::CiAgICAgICAgICAgICAgICAgICAgZid7Zm10X3RhbSh0b3RhbCl9IGVuIHRvdGFs
:::IMK3IHtiYWphc30gY29uIGNhbGlkYWQgYmFqYScsCiAgICAgICAgICAgICAgICAg
:::ICAgJ3RpdHVsbycpCiAgICAgICAgICAgICAgICBpZiBiYWphczoKICAgICAgICAg
:::ICAgICAgICAgICBsb2coJ0NvbnNlam86IGxvcyBhcmNoaXZvcyBtYXJjYWRvcyBl
:::biByb2pvIHNlIHB1ZWRlbiAnCiAgICAgICAgICAgICAgICAgICAgICAgICd2b2x2
:::ZXIgYSBkZXNjYXJnYXIgY29uIG3DoXMgYml0cmF0ZS4nLCAnZ3JpcycpCiAgICAg
:::ICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZToKICAgICAgICAgICAgICAgIGxv
:::ZyhmJ0Vycm9yIGFsIGNvbXByb2JhciBsYSBjYXJwZXRhOiB7ZX0nLCAnZXJyb3In
:::KQogICAgICAgICAgICBmaW5hbGx5OgogICAgICAgICAgICAgICAgY29sYS5wdXQo
:::KCdmaW4nLCAnY29tcHJvYmFjaW9uJywgVHJ1ZSwgJycpKQoKICAgICAgICBkZWYg
:::X2hpbG9fYWN0dWFsaXphcihzZWxmLCBjZmcpOgogICAgICAgICAgICBjb2xhID0g
:::c2VsZi5jb2xhCgogICAgICAgICAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAg
:::ICAgICAgICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgICAgICAg
:::ICB0cnk6CiAgICAgICAgICAgICAgICBsb2coJ0FjdHVhbGl6YW5kbyB5dC1kbHAg
:::eSBtdXRhZ2VuLi4uJywgJ2dyaXMnKQogICAgICAgICAgICAgICAgcCA9IHN1YnBy
:::b2Nlc3MucnVuKAogICAgICAgICAgICAgICAgICAgIFtzeXMuZXhlY3V0YWJsZSwg
:::Jy1tJywgJ3BpcCcsICdpbnN0YWxsJywgJy0tdXBncmFkZScsCiAgICAgICAgICAg
:::ICAgICAgICAgICctLW5vLXdhcm4tc2NyaXB0LWxvY2F0aW9uJywgJ3l0LWRscCcs
:::ICdtdXRhZ2VuJ10sCiAgICAgICAgICAgICAgICAgICAgc3Rkb3V0PXN1YnByb2Nl
:::c3MuUElQRSwgc3RkZXJyPXN1YnByb2Nlc3MuU1RET1VULAogICAgICAgICAgICAg
:::ICAgICAgIHRleHQ9VHJ1ZSwgZW5jb2Rpbmc9J3V0Zi04JywgZXJyb3JzPSdyZXBs
:::YWNlJywgdGltZW91dD02MDApCiAgICAgICAgICAgICAgICBmb3IgbG4gaW4gKHAu
:::c3Rkb3V0IG9yICcnKS5zdHJpcCgpLnNwbGl0bGluZXMoKVstNjpdOgogICAgICAg
:::ICAgICAgICAgICAgIGxvZygnICAgJyArIGxuWzoxNjBdLCAnZ3JpcycpCiAgICAg
:::ICAgICAgICAgICBpZiBwLnJldHVybmNvZGUgPT0gMDoKICAgICAgICAgICAgICAg
:::ICAgICBsb2coJ3l0LWRscCBhY3R1YWxpemFkby4gUmVpbmljaWEgbGEgYXBsaWNh
:::Y2nDs24gcGFyYSAnCiAgICAgICAgICAgICAgICAgICAgICAgICd1c2FyIGxhIHZl
:::cnNpw7NuIG51ZXZhLicsICdvaycpCiAgICAgICAgICAgICAgICBlbHNlOgogICAg
:::ICAgICAgICAgICAgICAgIGxvZygnTGEgYWN0dWFsaXphY2nDs24gZmFsbMOzICjC
:::v3NpbiBpbnRlcm5ldD8pLicsICdlcnJvcicpCiAgICAgICAgICAgIGV4Y2VwdCBF
:::eGNlcHRpb24gYXMgZToKICAgICAgICAgICAgICAgIGxvZyhmJ05vIHNlIHB1ZG8g
:::ZWplY3V0YXIgcGlwOiB7ZX0nLCAnZXJyb3InKQogICAgICAgICAgICBmaW5hbGx5
:::OgogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnYWN0dWFsaXphY2lv
:::bicsIFRydWUsICcnKSkKCiAgICAgICAgZGVmIF9tc2dfZXJyb3Ioc2VsZiwgZSk6
:::CiAgICAgICAgICAgIGxpbmVhcyA9IFtsIGZvciBsIGluIHN0cihlKS5zdHJpcCgp
:::LnNwbGl0bGluZXMoKSBpZiBsLnN0cmlwKCldCiAgICAgICAgICAgIHJldHVybiAo
:::bGluZWFzWzBdWzoyNTBdIGlmIGxpbmVhcwogICAgICAgICAgICAgICAgICAgIGVs
:::c2UgZid7dHlwZShlKS5fX25hbWVfX306IHNpbiBkZXRhbGxlcycpCgogICAgICAg
:::ICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tIGFycmFucXVlCiAgICAgICAgZGVmIF9hcnJhbnF1ZShzZWxmKToKICAgICAg
:::ICAgICAgc2VsZi5fbG9nKGYnTXVzaWtBTEFOIHZ7QVBQX1Z9JywgJ3RpdHVsbycp
:::CiAgICAgICAgICAgIHNlbGYuX2xvZygnQ3RybCtVOiBhY3R1YWxpemFyIHl0LWRs
:::cCDCtyBDdHJsK0w6IGxpbXBpYXIgcmVnaXN0cm8nLAogICAgICAgICAgICAgICAg
:::ICAgICAgJ2dyaXMnKQogICAgICAgICAgICB0aHJlYWRpbmcuVGhyZWFkKHRhcmdl
:::dD1zZWxmLl9oaWxvX3ZlcnNpb24sIGRhZW1vbj1UcnVlKS5zdGFydCgpCgogICAg
:::ICAgIGRlZiBfaGlsb192ZXJzaW9uKHNlbGYpOgogICAgICAgICAgICBjb2xhID0g
:::c2VsZi5jb2xhCgogICAgICAgICAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAg
:::ICAgICAgICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgICAgICAg
:::ICBpZiBZVF9ETFAgaXMgTm9uZToKICAgICAgICAgICAgICAgIGxvZygneXQtZGxw
:::IG5vIGVzdMOhIGluc3RhbGFkby4gRWplY3V0YSAnCiAgICAgICAgICAgICAgICAg
:::ICAgJ0Rlc2NhcmdhZG9yTXVzaWNhLmJhdCBwYXJhIGluc3RhbGFybG8uJywgJ2Vy
:::cm9yJykKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ3ZlcnNpb24n
:::LCBUcnVlLCAnJykpCiAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAg
:::dHJ5OgogICAgICAgICAgICAgICAgaW5zdGFsYWRhID0gWVRfRExQLnZlcnNpb24u
:::X192ZXJzaW9uX18KICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAg
:::ICAgICAgICAgIGluc3RhbGFkYSA9ICc/JwogICAgICAgICAgICB1bHRpbWEgPSBO
:::b25lCiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHdpdGggdXJsb3Bl
:::bignaHR0cHM6Ly9weXBpLm9yZy9weXBpL3l0LWRscC9qc29uJywgdGltZW91dD0x
:::MikgYXMgcjoKICAgICAgICAgICAgICAgICAgICB1bHRpbWEgPSBqc29uLmxvYWRz
:::KHIucmVhZCgpLmRlY29kZSgndXRmLTgnKSlbJ2luZm8nXVsndmVyc2lvbiddCiAg
:::ICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgICAgICB1bHRp
:::bWEgPSBOb25lCiAgICAgICAgICAgIGlmIHVsdGltYSBpcyBOb25lOgogICAgICAg
:::ICAgICAgICAgbG9nKGYneXQtZGxwOiB2ZXJzacOzbiB7aW5zdGFsYWRhfSAnCiAg
:::ICAgICAgICAgICAgICAgICAgJyhubyBzZSBwdWRvIGNvbXByb2JhciBzaSBoYXkg
:::bm92ZWRhZGVzKS4nLCAnZ3JpcycpCiAgICAgICAgICAgIGVsaWYgc3RyKHVsdGlt
:::YSkgPT0gc3RyKGluc3RhbGFkYSk6CiAgICAgICAgICAgICAgICBsb2coZid5dC1k
:::bHA6IGVuIGxhIHVsdGltYSB2ZXJzaW9uICh7aW5zdGFsYWRhfSkuJywgJ2luZm8n
:::KQogICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgbG9nKGYneXQtZGxw
:::OiBoYXkgdmVyc2lvbiBudWV2YSAoe3VsdGltYX0pOyBpbnN0YWxhZGE6ICcKICAg
:::ICAgICAgICAgICAgICAgICBmJ3tpbnN0YWxhZGF9LiBQdWxzYSBDdHJsK1UgcGFy
:::YSBhY3R1YWxpemFyLicsICdhdmlzbycpCiAgICAgICAgICAgIGlmIEZGTVBFRyBp
:::cyBOb25lOgogICAgICAgICAgICAgICAgbG9nKCdGRm1wZWc6IE5PIEVOQ09OVFJB
:::RE8g4oCUIGVqZWN1dGEgRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0ICcKICAgICAgICAg
:::ICAgICAgICAgICAncGFyYSBpbnN0YWxhcmxvLicsICdlcnJvcicpCiAgICAgICAg
:::ICAgIGVsc2U6CiAgICAgICAgICAgICAgICBsb2coZidGRm1wZWc6IE9LICh7RkZN
:::UEVHfSknLCAnZ3JpcycpCiAgICAgICAgICAgIGxvZygnQ2FycGV0YSBkZSBndWFy
:::ZGFkbzogJyArIHN0cihBSlVTVEVTLmdldCgnZGVzdGlubycpKSwgJ2dyaXMnKQog
:::ICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICd2ZXJzaW9uJywgVHJ1ZSwgJycp
:::KQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBtYWluCmRlZiBtYWluKCk6CiAgICBfcmVj
:::b25maWd1cmFyX3NhbGlkYSgpCiAgICBpZiBub3QgVEtfT0s6CiAgICAgICAgcHJp
:::bnQoJ0VzdGEgYXBsaWNhY2nDs24gbmVjZXNpdGEgVGtpbnRlciAoaW50ZXJmYXog
:::Z3LDoWZpY2EpLicpCiAgICAgICAgcHJpbnQoJ0VsIFB5dGhvbiBhY3R1YWwgbm8g
:::bG8gaW5jbHV5ZS4nKQogICAgICAgIHByaW50KCdWdWVsdmUgYSBlamVjdXRhciBE
:::ZXNjYXJnYWRvck11c2ljYS5iYXQgcGFyYSBpbnN0YWxhciBlbCAnCiAgICAgICAg
:::ICAgICAgJ1B5dGhvbiBhZGVjdWFkby4nKQogICAgICAgIHJldHVybiAxCiAgICBj
:::b21wcm9iYXJfZW50b3JubygpCiAgICBhcHAgPSBBcHAoKQogICAgYXBwLm1haW5s
:::b29wKCkKICAgIHJldHVybiAwCgoKaWYgX19uYW1lX18gPT0gJ19fbWFpbl9fJzoK
:::ICAgIHRyeToKICAgICAgICBzeXMuZXhpdChtYWluKCkpCiAgICBleGNlcHQgU3lz
:::dGVtRXhpdDoKICAgICAgICByYWlzZQogICAgZXhjZXB0IEJhc2VFeGNlcHRpb246
:::CiAgICAgICAgdHJ5OgogICAgICAgICAgICB3aXRoIG9wZW4oTE9HX0VSUk9SRVMs
:::ICdhJywgZW5jb2Rpbmc9J3V0Zi04JykgYXMgZmg6CiAgICAgICAgICAgICAgICBm
:::aC53cml0ZSh0cmFjZWJhY2suZm9ybWF0X2V4YygpICsgJ1xuJykKICAgICAgICBl
:::eGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICBwYXNzCiAgICAgICAgcmFpc2UK
