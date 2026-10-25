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
title MusikALAN v2.8
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
echo    %C_TIT%MusikALAN v2.8%C_FIN% - preparando el entorno
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
title MusikALAN v2.8 - YouTube a AAC/MP3/FLAC/WAV/WMA/AVI
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
:::UF9WID0gJzIuOCcKQVBQX0RJUiA9IFBhdGgoX19maWxlX18pLnJlc29sdmUoKS5w
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
:::OiAnMTI4aycsCiAgICAnZW1iZWJlcic6IFRydWUsCn0KCgpkZWYgY2FyZ2FyX2Fq
:::dXN0ZXMoKToKICAgIGEgPSBkaWN0KEFKVVNURVNfREVGRUNUTykKICAgIHRyeToK
:::ICAgICAgICBhLnVwZGF0ZShqc29uLmxvYWRzKFJVVEFfQUpVU1RFUy5yZWFkX3Rl
:::eHQoZW5jb2Rpbmc9J3V0Zi04JykpKQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAg
:::ICAgICBwYXNzCiAgICBhLnBvcCgnbmF2ZWdhZG9yJywgTm9uZSkgICMgdjIuMiBv
:::IGFudGVyaW9yOiBsYSBzZWNjaW9uIGRlIGNvb2tpZXMgeWEgbm8gZXhpc3RlCiAg
:::ICAjIG1pZ3JhY2lvbmVzIGRlbCBkZXN0aW5vIGRlIGd1YXJkYWRvOgogICAgIyAg
:::wrcgdjIuMC8yLjEgdXNhYmEgTXVzaWMvWVREb3dubG9hZGVyCiAgICAjICDCtyB2
:::Mi4yIHVzYWJhIGxhIGNhcnBldGEgZGVsIHByb2dyYW1hIChBcHBEYXRhXFJvYW1p
:::bmdcTXVzaWtBTEFOKQogICAgIyBEZXNkZSBsYSB2Mi4zIGVsIGRlc3Rpbm8gcG9y
:::IGRlZmVjdG8gZXMgbGEgY2FycGV0YSBNdXNpY2EgZGVsIHVzdWFyaW8sCiAgICAj
:::IGFzaSBxdWUgc2kgZWwgYWp1c3RlIGFwdW50YSBhIGN1YWxxdWllcmEgZGUgbG9z
:::IGRvcywgc2UgYWN0dWFsaXphLgogICAgZGVzdGlubyA9IHN0cihhLmdldCgnZGVz
:::dGlubycpIG9yICcnKS5yZXBsYWNlKCdcXCcsICcvJykucnN0cmlwKCcvJykubG93
:::ZXIoKQogICAgaWYgJ3l0ZG93bmxvYWRlcicgaW4gZGVzdGlubzoKICAgICAgICBh
:::WydkZXN0aW5vJ10gPSBBSlVTVEVTX0RFRkVDVE9bJ2Rlc3Rpbm8nXQogICAgZWxz
:::ZToKICAgICAgICB2aWVqbyA9IF9kZXN0aW5vX2FwcGRhdGFfdmllam8oKS5yZXBs
:::YWNlKCdcXCcsICcvJykucnN0cmlwKCcvJykubG93ZXIoKQogICAgICAgIGlmIGRl
:::c3Rpbm8gYW5kIChkZXN0aW5vID09IHZpZWpvCiAgICAgICAgICAgICAgICAgICAg
:::ICAgIG9yIGRlc3Rpbm8uc3RhcnRzd2l0aCh2aWVqbyArICcvJykpOgogICAgICAg
:::ICAgICBhWydkZXN0aW5vJ10gPSBBSlVTVEVTX0RFRkVDVE9bJ2Rlc3Rpbm8nXQog
:::ICAgcmV0dXJuIGEKCgpkZWYgZ3VhcmRhcl9hanVzdGVzKCk6CiAgICB0cnk6CiAg
:::ICAgICAgUlVUQV9BSlVTVEVTLndyaXRlX3RleHQoCiAgICAgICAgICAgIGpzb24u
:::ZHVtcHMoQUpVU1RFUywgZW5zdXJlX2FzY2lpPUZhbHNlLCBpbmRlbnQ9MiksCiAg
:::ICAgICAgICAgIGVuY29kaW5nPSd1dGYtOCcpCiAgICBleGNlcHQgRXhjZXB0aW9u
:::OgogICAgICAgIHBhc3MKCgpBSlVTVEVTID0gY2FyZ2FyX2FqdXN0ZXMoKQoKCiMg
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLSB1dGlscwpkZWYgZm10X3RhbShuKToKICAgIGlmIG5v
:::dCBuOgogICAgICAgIHJldHVybiAn4oCUJwogICAgbiA9IGZsb2F0KG4pCiAgICBm
:::b3IgdSBpbiAoJ0InLCAnS2lCJywgJ01pQicsICdHaUInKToKICAgICAgICBpZiBu
:::IDwgMTAyNCBvciB1ID09ICdHaUInOgogICAgICAgICAgICByZXR1cm4gZid7aW50
:::KG4pfSB7dX0nIGlmIHUgPT0gJ0InIGVsc2UgZid7bjouMWZ9IHt1fScKICAgICAg
:::ICBuIC89IDEwMjQKCgpkZWYgZm10X3RpZW0ocyk6CiAgICBpZiBzIGlzIE5vbmU6
:::CiAgICAgICAgcmV0dXJuICfigJQnCiAgICBzID0gaW50KHMpCiAgICBoLCByID0g
:::ZGl2bW9kKHMsIDM2MDApCiAgICBtLCB4ID0gZGl2bW9kKHIsIDYwKQogICAgcmV0
:::dXJuIGYne2h9OnttOjAyZH06e3g6MDJkfScgaWYgaCBlbHNlIGYne206MDJkfTp7
:::eDowMmR9JwoKCmRlZiBsaW1waWFyX25vbWJyZSh0KToKICAgIHQgPSByZS5zdWIo
:::cidbPD46Ii9cXHw/Klx4MDAtXHgxZl0nLCAnXycsIHN0cih0KSkuc3RyaXAoJyAu
:::JykKICAgIHJldHVybiB0WzoxNTBdIG9yICdzaW5fdGl0dWxvJwoKCmRlZiBzaW5f
:::cGxheWxpc3QodXJsKToKICAgICIiIlF1aXRhIGVsIHBhcsOhbWV0cm8gbGlzdD0g
:::ZGUgbGEgVVJMIChtb2RvIHNvbG8gdmlkZW8pLiIiIgogICAgdHJ5OgogICAgICAg
:::IHAgPSB1cmxwYXJzZSh1cmwpCiAgICAgICAgcSA9IHBhcnNlX3FzKHAucXVlcnkp
:::CiAgICAgICAgaWYgJ2xpc3QnIGluIHE6CiAgICAgICAgICAgIGRlbCBxWydsaXN0
:::J10KICAgICAgICAgICAgcmV0dXJuIHVybHVucGFyc2UocC5fcmVwbGFjZShxdWVy
:::eT11cmxlbmNvZGUocSwgZG9zZXE9VHJ1ZSkpKSwgVHJ1ZQogICAgZXhjZXB0IEV4
:::Y2VwdGlvbjoKICAgICAgICBwYXNzCiAgICByZXR1cm4gdXJsLCBGYWxzZQoKCmRl
:::ZiBlc191cmxfcGxheWxpc3QodXJsKToKICAgICIiIlRydWUgc2kgbGEgVVJMIHBl
:::cnRlbmVjZSBhIHVuYSBsaXN0YSBkZSByZXByb2R1Y2Npw7NuIChsbGV2YSBsaXN0
:::PSkuIiIiCiAgICB0cnk6CiAgICAgICAgcmV0dXJuICdsaXN0JyBpbiBwYXJzZV9x
:::cyh1cmxwYXJzZSh1cmwpLnF1ZXJ5KQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAg
:::ICAgICByZXR1cm4gRmFsc2UKCgpkZWYgZXNfc29sb19saXN0YSh1cmwpOgogICAg
:::IiIiVHJ1ZSBzaSBsYSBVUkwgZXMgdW5hIHBsYXlsaXN0IHB1cmEsIHNpbiB2aWRl
:::byBpbmRpdmlkdWFsIChzaW4gdj0pLiIiIgogICAgdHJ5OgogICAgICAgIHAgPSB1
:::cmxwYXJzZSh1cmwpCiAgICAgICAgaWYgJ3YnIGluIHBhcnNlX3FzKHAucXVlcnkp
:::IG9yICd5b3V0dS5iZScgaW4gKHAubmV0bG9jIG9yICcnKToKICAgICAgICAgICAg
:::cmV0dXJuIEZhbHNlCiAgICAgICAgcmV0dXJuIChwLnBhdGggb3IgJycpLnJzdHJp
:::cCgnLycpLmVuZHN3aXRoKCcvcGxheWxpc3QnKQogICAgZXhjZXB0IEV4Y2VwdGlv
:::bjoKICAgICAgICByZXR1cm4gRmFsc2UKCgpkZWYgYWJyaXJfY2FycGV0YShydXRh
:::KToKICAgIHRyeToKICAgICAgICBpZiBvcy5uYW1lID09ICdudCc6CiAgICAgICAg
:::ICAgIG9zLnN0YXJ0ZmlsZShzdHIocnV0YSkpICAjIG5vcWE6IHNvbG8gV2luZG93
:::cwogICAgICAgIGVsc2U6CiAgICAgICAgICAgIHN1YnByb2Nlc3MuUG9wZW4oWyd4
:::ZGctb3BlbicsIHN0cihydXRhKV0pCiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAg
:::ICAgIHBhc3MKCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gZmZtcGVnCmRlZiBidXNjYXJf
:::ZmZtcGVnKCk6CiAgICBleGUgPSBzaHV0aWwud2hpY2goJ2ZmbXBlZycpCiAgICBp
:::ZiBleGU6CiAgICAgICAgcmV0dXJuIFBhdGgoZXhlKQogICAgY2FuZGlkYXRvcyA9
:::IFsKICAgICAgICBBUFBfRElSIC8gJ2ZmbXBlZycgLyAnYmluJyAvICdmZm1wZWcu
:::ZXhlJywKICAgICAgICBBUFBfRElSIC8gJ2ZmbXBlZycgLyAnYmluJyAvICdmZm1w
:::ZWcnLAogICAgICAgIEFQUF9ESVIgLyAncnVudGltZScgLyAnZmZtcGVnLmV4ZScs
:::CiAgICBdCiAgICBmb3IgcCBpbiBjYW5kaWRhdG9zOgogICAgICAgIGlmIHAuZXhp
:::c3RzKCk6CiAgICAgICAgICAgIHJldHVybiBwCiAgICByZXR1cm4gTm9uZQoKCmRl
:::ZiBidXNjYXJfZmZwcm9iZShmZm1wZWcpOgogICAgaWYgZmZtcGVnIGlzIE5vbmU6
:::CiAgICAgICAgcmV0dXJuIHNodXRpbC53aGljaCgnZmZwcm9iZScpCiAgICBwID0g
:::ZmZtcGVnLndpdGhfbmFtZSgnZmZwcm9iZS5leGUnIGlmIG9zLm5hbWUgPT0gJ250
:::JyBlbHNlICdmZnByb2JlJykKICAgIGlmIHAuZXhpc3RzKCk6CiAgICAgICAgcmV0
:::dXJuIHAKICAgIHJldHVybiBzaHV0aWwud2hpY2goJ2ZmcHJvYmUnKQoKCllUX0RM
:::UCA9IE5vbmUgICAjIG3Ds2R1bG8geXRfZGxwOyBzZSByZWxsZW5hIGVuIGNvbXBy
:::b2Jhcl9lbnRvcm5vKCkKRkZNUEVHID0gTm9uZSAgICMgcnV0YSBkZSBmZm1wZWcK
:::RkZQUk9CRSA9IE5vbmUgICMgcnV0YSBkZSBmZnByb2JlCgoKZGVmIGNvbXByb2Jh
:::cl9lbnRvcm5vKCk6CiAgICBnbG9iYWwgWVRfRExQLCBGRk1QRUcsIEZGUFJPQkUK
:::ICAgIHRyeToKICAgICAgICBpbXBvcnQgeXRfZGxwIGFzIG1vZAogICAgICAgIFlU
:::X0RMUCA9IG1vZAogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICBwYXNzCiAg
:::ICBGRk1QRUcgPSBidXNjYXJfZmZtcGVnKCkKICAgIEZGUFJPQkUgPSBidXNjYXJf
:::ZmZwcm9iZShGRk1QRUcpCgoKY2xhc3MgUmVnaXN0cm86CiAgICAiIiJMb2dnZXIg
:::cGFyYSB5dC1kbHA6IHJlZW52w61hIGF2aXNvcy9lcnJvcmVzIGFsIHJlZ2lzdHJv
:::IGRlIGxhIEdVSS4iIiIKCiAgICBkZWYgX19pbml0X18oc2VsZik6CiAgICAgICAg
:::c2VsZi5sb2cgPSBOb25lICAjIGxhIEdVSSBsbyBjb25lY3RhOiBsb2cobWVuc2Fq
:::ZSwgZXRpcXVldGEpCgogICAgZGVmIGRlYnVnKHNlbGYsIG0pOgogICAgICAgIHBh
:::c3MKCiAgICAjIEF2aXNvcyBpbnRlcm5vcyBkZSB5dC1kbHAgcXVlIHNvbG8gbWV0
:::ZW4gcnVpZG8gZW4gZWwgcmVnaXN0cm86CiAgICBBVklTT1NfUlVJRE9TT1MgPSAo
:::J05vIHN1cHBvcnRlZCBKYXZhU2NyaXB0IHJ1bnRpbWUnLCAnRUpTJykKCiAgICBk
:::ZWYgd2FybmluZyhzZWxmLCBtKToKICAgICAgICBtID0gc3RyKG0pLnN0cmlwKCkK
:::ICAgICAgICBpZiBub3QgbSBvciBhbnkoeCBpbiBtIGZvciB4IGluIHNlbGYuQVZJ
:::U09TX1JVSURPU09TKToKICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgaWYgc2Vs
:::Zi5sb2c6CiAgICAgICAgICAgIHNlbGYubG9nKG0sICdhdmlzbycpCgogICAgZGVm
:::IGVycm9yKHNlbGYsIG0pOgogICAgICAgIG0gPSBzdHIobSkuc3RyaXAoKQogICAg
:::ICAgIGlmIG0gYW5kIHNlbGYubG9nOgogICAgICAgICAgICBzZWxmLmxvZyhtLCAn
:::ZXJyb3InKQoKClJFR0lTVFJPID0gUmVnaXN0cm8oKQoKTk9NQlJFU19QUCA9IHsK
:::ICAgICdGRm1wZWdFeHRyYWN0QXVkaW8nOiAnQ29udmlydGllbmRvIGVsIGF1ZGlv
:::IGNvbiBGRm1wZWcnLAogICAgJ0ZGbXBlZ1RodW1ibmFpbHNDb252ZXJ0b3InOiAn
:::Q29udmlydGllbmRvIGxhIGNhcsOhdHVsYSBhIEpQRycsCiAgICAnRkZtcGVnTWV0
:::YWRhdGEnOiAnRXNjcmliaWVuZG8gZXRpcXVldGFzICh0w610dWxvL2FydGlzdGEp
:::JywKICAgICdFbWJlZFRodW1ibmFpbCc6ICdJbmNydXN0YW5kbyBsYSBjYXLDoXR1
:::bGEnLAogICAgJ01vdmVGaWxlcyc6ICdPcmdhbml6YW5kbyBhcmNoaXZvcycsCiAg
:::ICAnRkZtcGVnTWVyZ2VyJzogJ1VuaWVuZG8gcGlzdGFzIGRlIHZpZGVvIHkgYXVk
:::aW8nLAogICAgJ0ZGbXBlZ1ZpZGVvQ29udmVydG9yJzogJ0NvbnZpcnRpZW5kbyBl
:::bCB2aWRlbycsCn0KCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBmb3JtYXRvcwpGT1JNQVRP
:::UyA9IHsKICAgICdBQUMnOiBkaWN0KHRleHRvPSdBQUMgKC5tNGEpJywgZXh0PSdt
:::NGEnLAogICAgICAgICAgICAgICAgY2FsaWRhZGVzPVsnOTZrJywgJzEyOGsnXSwg
:::ZGVmZWN0bz0nMTI4aycpLAogICAgJ01QMyc6IGRpY3QodGV4dG89J01QMyAoLm1w
:::MyknLCBleHQ9J21wMycsCiAgICAgICAgICAgICAgICBjYWxpZGFkZXM9Wyc5Nmsn
:::LCAnMTI4aycsICcxOTJrJywgJzI1NmsnLCAnMzIwayddLAogICAgICAgICAgICAg
:::ICAgZGVmZWN0bz0nMzIwaycpLAogICAgJ0ZMQUMnOiBkaWN0KHRleHRvPSdGTEFD
:::ICguZmxhYyknLCBleHQ9J2ZsYWMnLAogICAgICAgICAgICAgICAgIGNhbGlkYWRl
:::cz1bJ3NpbiBwZXJkaWRhJ10sIGRlZmVjdG89J3NpbiBwZXJkaWRhJyksCiAgICAn
:::V0FWJzogZGljdCh0ZXh0bz0nV0FWICgud2F2KScsIGV4dD0nd2F2JywKICAgICAg
:::ICAgICAgICAgIGNhbGlkYWRlcz1bJ3NpbiBwZXJkaWRhJ10sIGRlZmVjdG89J3Np
:::biBwZXJkaWRhJyksCiAgICAnV01BJzogZGljdCh0ZXh0bz0nV01BICgud21hKScs
:::IGV4dD0nd21hJywKICAgICAgICAgICAgICAgIGNhbGlkYWRlcz1bJzk2aycsICcx
:::MjhrJ10sIGRlZmVjdG89JzEyOGsnKSwKICAgICdBVkknOiBkaWN0KHRleHRvPSdB
:::VkkgLSBzaGVpanUgMS44IiAoMTI4eDE2MCknLCBleHQ9J2F2aScsCiAgICAgICAg
:::ICAgICAgICBjYWxpZGFkZXM9WycxMjh4MTYwIMK3IDE2IGZwcyddLCBkZWZlY3Rv
:::PScxMjh4MTYwIMK3IDE2IGZwcycpLAp9CgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIHBy
:::b2dyZXNvCmRlZiBob29rc19ndWkoY29sYSk6CiAgICAiIiJDcmVhIGxvcyBob29r
:::cyBkZSB5dC1kbHAgcXVlIHB1YmxpY2FuIGV2ZW50b3MgZW4gbGEgY29sYSBkZSBs
:::YSBHVUkuIiIiCiAgICBlc3RhZG8gPSB7J3RpdHVsbyc6IEZhbHNlLCAncHBfdWx0
:::JzogTm9uZX0KCiAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAgICBjb2xh
:::LnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgIGRlZiBwcm9ncmVzbyhkKToKICAgICAg
:::ICBpZiBkWydzdGF0dXMnXSA9PSAnZG93bmxvYWRpbmcnOgogICAgICAgICAgICBp
:::ZiBub3QgZXN0YWRvWyd0aXR1bG8nXToKICAgICAgICAgICAgICAgIGluZm8gPSBk
:::LmdldCgnaW5mb19kaWN0Jykgb3Ige30KICAgICAgICAgICAgICAgIHQgPSBpbmZv
:::LmdldCgndGl0bGUnKSBvciBQYXRoKGQuZ2V0KCdmaWxlbmFtZScpIG9yICcnKS5z
:::dGVtCiAgICAgICAgICAgICAgICBpZiB0OgogICAgICAgICAgICAgICAgICAgIGxv
:::Zygn4pmqICcgKyBzdHIodClbOjkwXSwgJ3RpdHVsbycpCiAgICAgICAgICAgICAg
:::ICAgICAgZXN0YWRvWyd0aXR1bG8nXSA9IFRydWUKICAgICAgICAgICAgdG90YWwg
:::PSBkLmdldCgndG90YWxfYnl0ZXMnKSBvciBkLmdldCgndG90YWxfYnl0ZXNfZXN0
:::aW1hdGUnKSBvciAwCiAgICAgICAgICAgIGRvbmUgPSBkLmdldCgnZG93bmxvYWRl
:::ZF9ieXRlcycsIDApCiAgICAgICAgICAgIHZlbCA9IGQuZ2V0KCdzcGVlZCcpCiAg
:::ICAgICAgICAgIGV0YSA9IGQuZ2V0KCdldGEnKQogICAgICAgICAgICBpZiB0b3Rh
:::bDoKICAgICAgICAgICAgICAgIHBjdCA9IGRvbmUgLyB0b3RhbCAqIDEwMAogICAg
:::ICAgICAgICAgICAgdGV4dG8gPSBmJ3twY3Q6NS4xZn0lIMK3IHtmbXRfdGFtKGRv
:::bmUpfSAvIHtmbXRfdGFtKHRvdGFsKX0nCiAgICAgICAgICAgICAgICBpZiB2ZWw6
:::CiAgICAgICAgICAgICAgICAgICAgdGV4dG8gKz0gZicgwrcge2ZtdF90YW0odmVs
:::KX0vcycKICAgICAgICAgICAgICAgIGlmIGV0YSBpcyBub3QgTm9uZToKICAgICAg
:::ICAgICAgICAgICAgICB0ZXh0byArPSBmJyDCtyBxdWVkYW4ge2ZtdF90aWVtKGV0
:::YSl9JwogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdwcm9nJywgcGN0LCB0ZXh0
:::bykpCiAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICB2ID0gZid7Zm10
:::X3RhbSh2ZWwpfS9zJyBpZiB2ZWwgZWxzZSAnJwogICAgICAgICAgICAgICAgY29s
:::YS5wdXQoKCdwcm9nJywgTm9uZSwgZid7Zm10X3RhbShkb25lKX0gwrcge3Z9Jykp
:::CiAgICAgICAgZWxpZiBkWydzdGF0dXMnXSA9PSAnZmluaXNoZWQnOgogICAgICAg
:::ICAgICBlc3RhZG9bJ3BwX3VsdCddID0gTm9uZQogICAgICAgICAgICBjb2xhLnB1
:::dCgoJ2xvZycsICdEZXNjYXJnYSByZWNpYmlkYS4gUHJvY2VzYW5kby4uLicsICdn
:::cmlzJykpCiAgICAgICAgICAgIGNvbGEucHV0KCgncHJvZycsIDAsICdQcm9jZXNh
:::bmRvLi4uJykpCgogICAgZGVmIHBvc3Rwcm9jZXNvKGQpOgogICAgICAgIGlmIGRb
:::J3N0YXR1cyddID09ICdzdGFydGVkJzoKICAgICAgICAgICAgbm9tID0gKGQuZ2V0
:::KCdwb3N0cHJvY2Vzc29yX25hbWUnKQogICAgICAgICAgICAgICAgICAgb3IgZC5n
:::ZXQoJ3Bvc3Rwcm9jZXNzb3InKSBvciAnUG9zdHByb2Nlc28nKQogICAgICAgICAg
:::ICBpZiBub20gPT0gZXN0YWRvWydwcF91bHQnXToKICAgICAgICAgICAgICAgIHJl
:::dHVybiAgIyB5dC1kbHAgYSB2ZWNlcyBhbnVuY2lhIGVsIG1pc21vIHBhc28gZG9z
:::IHZlY2VzCiAgICAgICAgICAgIGVzdGFkb1sncHBfdWx0J10gPSBub20KICAgICAg
:::ICAgICAgdGV4dG8gPSBOT01CUkVTX1BQLmdldChub20sIG5vbSkgKyAnLi4uJwog
:::ICAgICAgICAgICBjb2xhLnB1dCgoJ2xvZycsICfihpIgJyArIHRleHRvLCAnZ3Jp
:::cycpKQogICAgICAgICAgICBjb2xhLnB1dCgoJ3Byb2cnLCBOb25lLCB0ZXh0bykp
:::CgogICAgcmV0dXJuIHByb2dyZXNvLCBwb3N0cHJvY2VzbwoKCiMgLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLSBvcGNpb25lcwpkZWYgb3B0c19iYXNlKGNhcnBldGEsIGNvbGEpOgog
:::ICAgcHJvZ3Jlc28sIHBvc3Rwcm9jZXNvID0gaG9va3NfZ3VpKGNvbGEpCiAgICBv
:::ID0gewogICAgICAgICdvdXR0bXBsJzogc3RyKGNhcnBldGEgLyAnJSh0aXRsZSlz
:::LiUoZXh0KXMnKSwKICAgICAgICAncXVpZXQnOiBUcnVlLAogICAgICAgICdub193
:::YXJuaW5ncyc6IFRydWUsCiAgICAgICAgJ25vcHJvZ3Jlc3MnOiBUcnVlLAogICAg
:::ICAgICdub3BsYXlsaXN0JzogVHJ1ZSwKICAgICAgICAnaWdub3JlZXJyb3JzJzog
:::RmFsc2UsCiAgICAgICAgJ3JldHJpZXMnOiAxMCwKICAgICAgICAnZnJhZ21lbnRf
:::cmV0cmllcyc6IDEwLAogICAgICAgICdzb2NrZXRfdGltZW91dCc6IDMwLAogICAg
:::ICAgICdjb25jdXJyZW50X2ZyYWdtZW50X2Rvd25sb2Fkcyc6IDQsCiAgICAgICAg
:::J3dpbmRvd3NmaWxlbmFtZXMnOiBUcnVlLAogICAgICAgICdvdmVyd3JpdGVzJzog
:::RmFsc2UsCiAgICAgICAgJ2xvZ2dlcic6IFJFR0lTVFJPLAogICAgICAgICdwcm9n
:::cmVzc19ob29rcyc6IFtwcm9ncmVzb10sCiAgICAgICAgJ3Bvc3Rwcm9jZXNzb3Jf
:::aG9va3MnOiBbcG9zdHByb2Nlc29dLAogICAgfQogICAgaWYgRkZNUEVHOgogICAg
:::ICAgIG9bJ2ZmbXBlZ19sb2NhdGlvbiddID0gc3RyKEZGTVBFRy5wYXJlbnQpCiAg
:::ICByZXR1cm4gbwoKCmRlZiBjb252ZXJ0aXJfZmZtcGVnKGNtZCwgZXRpcXVldGEs
:::IGNvbGEpOgogICAgIiIiRWplY3V0YSBGRm1wZWcgKGxpc3RhIGRlIGFyZ3VtZW50
:::b3MsIHNpbiBzaGVsbCkgY29uIG1hcnF1ZWUuIiIiCiAgICBjb2xhLnB1dCgoJ3By
:::b2cnLCBOb25lLCBldGlxdWV0YSkpCgogICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6
:::CiAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICB0cnk6CiAgICAg
:::ICAgcCA9IHN1YnByb2Nlc3MucnVuKGNtZCwgc3Rkb3V0PXN1YnByb2Nlc3MuUElQ
:::RSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgc3RkZXJyPXN1YnByb2Nlc3Mu
:::UElQRSwgdGV4dD1UcnVlLAogICAgICAgICAgICAgICAgICAgICAgICAgICBlbmNv
:::ZGluZz0ndXRmLTgnLCBlcnJvcnM9J3JlcGxhY2UnKQogICAgZXhjZXB0IEZpbGVO
:::b3RGb3VuZEVycm9yOgogICAgICAgIHAgPSBOb25lCiAgICBpZiBwIGlzIE5vbmUg
:::b3IgcC5yZXR1cm5jb2RlICE9IDA6CiAgICAgICAgbG9nKCfinJYgRkZtcGVnIGRl
:::dm9sdmnDsyB1biBlcnJvcjonLCAnZXJyb3InKQogICAgICAgIGlmIHAgaXMgbm90
:::IE5vbmU6CiAgICAgICAgICAgIGZvciBsbiBpbiAocC5zdGRlcnIgb3IgJycpLnN0
:::cmlwKCkuc3BsaXRsaW5lcygpWy00Ol06CiAgICAgICAgICAgICAgICBsb2coJyAg
:::ICcgKyBsbls6MTgwXSwgJ2dyaXMnKQogICAgICAgIGNvbGEucHV0KCgncHJvZycs
:::IDAsICcnKSkKICAgICAgICByZXR1cm4gRmFsc2UKICAgIHJldHVybiBUcnVlCgoK
:::ZGVmIGFyY2hpdm9fZmluYWwoaW5mbywgY2FycGV0YSwgZXh0KToKICAgICIiIkxv
:::Y2FsaXphIGVsIGFyY2hpdm8gcmVzdWx0YW50ZSAoeXQtZGxwIGxvIHJlcG9ydGE7
:::IGZhbGxiYWNrOiBtw6FzIG51ZXZvKS4iIiIKICAgIHRyeToKICAgICAgICBmb3Ig
:::ZCBpbiAoaW5mby5nZXQoJ3JlcXVlc3RlZF9kb3dubG9hZHMnKSBvciBbXSk6CiAg
:::ICAgICAgICAgIGYgPSBkLmdldCgnZmlsZXBhdGgnKQogICAgICAgICAgICBpZiBm
:::OgogICAgICAgICAgICAgICAgcmV0dXJuIFBhdGgoZikKICAgIGV4Y2VwdCBFeGNl
:::cHRpb246CiAgICAgICAgcGFzcwogICAgY2FuZCA9IHNvcnRlZChjYXJwZXRhLmds
:::b2IoJyouJyArIGV4dCksCiAgICAgICAgICAgICAgICAgIGtleT1sYW1iZGEgcDog
:::cC5zdGF0KCkuc3RfbXRpbWUsIHJldmVyc2U9VHJ1ZSkKICAgIHJldHVybiBjYW5k
:::WzBdIGlmIGNhbmQgZWxzZSBOb25lCgoKZGVmIGxpbXBpYXJfbWluaWF0dXJhcyhj
:::YXJwZXRhLCBhcmNoaXZvKToKICAgICIiIkJvcnJhIG1pbmlhdHVyYXMgc3VlbHRh
:::cyBxdWUgRW1iZWRUaHVtYm5haWwgZGVqYXJhIHNpbiBpbmNydXN0YXIuIiIiCiAg
:::ICBmb3IgZXh0IGluICgnLndlYnAnLCAnLmpwZycsICcuanBlZycsICcucG5nJyk6
:::CiAgICAgICAgdCA9IGFyY2hpdm8ud2l0aF9zdWZmaXgoZXh0KQogICAgICAgIGlm
:::IHQuZXhpc3RzKCk6CiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHQu
:::dW5saW5rKCkKICAgICAgICAgICAgZXhjZXB0IE9TRXJyb3I6CiAgICAgICAgICAg
:::ICAgICBwYXNzCgoKZGVmIF9taW5pYXR1cmFfYnl0ZXMoY2FycGV0YSwgYXJjaGl2
:::byk6CiAgICAiIiJMZWUgbG9zIGJ5dGVzIGRlIGxhIG1pbmlhdHVyYSBxdWUgeXQt
:::ZGxwIGRlam8ganVudG8gYWwgYXJjaGl2byBmaW5hbC4iIiIKICAgIGlmIG5vdCBh
:::cmNoaXZvOgogICAgICAgIHJldHVybiBOb25lCiAgICBmb3IgZXh0IGluICgnLmpw
:::ZycsICcuanBlZycsICcud2VicCcsICcucG5nJyk6CiAgICAgICAgdCA9IGFyY2hp
:::dm8ud2l0aF9zdWZmaXgoZXh0KQogICAgICAgIGlmIHQuZXhpc3RzKCk6CiAgICAg
:::ICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHJldHVybiB0LnJlYWRfYnl0ZXMo
:::KQogICAgICAgICAgICBleGNlcHQgT1NFcnJvcjoKICAgICAgICAgICAgICAgIHBh
:::c3MKICAgIHJldHVybiBOb25lCgoKZGVmIF9lc19qcGcoZGF0b3MpOgogICAgcmV0
:::dXJuIGJvb2woZGF0b3MpIGFuZCBkYXRvc1s6M10gPT0gYidceGZmXHhkOFx4ZmYn
:::CgoKZGVmIF9hX2pwZyhkYXRvcyk6CiAgICAiIiJDb252aWVydGUgbG9zIGJ5dGVz
:::IGRlIHVuYSBpbWFnZW4gKHdlYnAvcG5nLy4uLikgYSBKUEVHIGNvbiBGRm1wZWcu
:::CgogICAgTG9zIHJlcHJvZHVjdG9yZXMgYmFyYXRvcyAodGlwbyBzaGVpanUpIHN1
:::ZWxlbiBsZWVyIHNvbG8gSlBFRzogbGEKICAgIG1pbmlhdHVyYSBkZSBZb3VUdWJl
:::IHZpZW5lIGVuIFdlYlAgeSBFbWJlZFRodW1ibmFpbCBkZSB5dC1kbHAgbGEKICAg
:::IGNvbnZpZXJ0ZSBhIFBORyAoIlBORyBpcyBwcmVmZXJyZWQgc2luY2UgSlBFRyBp
:::cyBsb3NzeSIpLCBhc2kgcXVlCiAgICBhcXVpIG5vcyBhc2VndXJhbW9zIG5vc290
:::cm9zIGRlIHF1ZSBhY2FiZSBlbiBKUEVHLiIiIgogICAgaWYgbm90IGRhdG9zIG9y
:::IG5vdCBGRk1QRUc6CiAgICAgICAgcmV0dXJuIE5vbmUKICAgIGJhc2UgPSBQYXRo
:::KHRlbXBmaWxlLmdldHRlbXBkaXIoKSkgLyAoJ211c2lrYWxhbl9jYXJhdHVsYV8l
:::ZCcgJSBvcy5nZXRwaWQoKSkKICAgIG9yaWdlbiwgZGVzdGlubyA9IGJhc2Uud2l0
:::aF9zdWZmaXgoJy5vcmlnJyksIGJhc2Uud2l0aF9zdWZmaXgoJy5qcGcnKQogICAg
:::dHJ5OgogICAgICAgIG9yaWdlbi53cml0ZV9ieXRlcyhkYXRvcykKICAgICAgICBy
:::ID0gc3VicHJvY2Vzcy5ydW4oCiAgICAgICAgICAgIFtzdHIoRkZNUEVHKSwgJy15
:::JywgJy1sb2dsZXZlbCcsICdlcnJvcicsICctaScsIHN0cihvcmlnZW4pLAogICAg
:::ICAgICAgICAgJy1xOnYnLCAnMicsIHN0cihkZXN0aW5vKV0sCiAgICAgICAgICAg
:::IHN0ZG91dD1zdWJwcm9jZXNzLkRFVk5VTEwsIHN0ZGVycj1zdWJwcm9jZXNzLkRF
:::Vk5VTEwpCiAgICAgICAgaWYgci5yZXR1cm5jb2RlID09IDAgYW5kIGRlc3Rpbm8u
:::ZXhpc3RzKCk6CiAgICAgICAgICAgIGpwZyA9IGRlc3Rpbm8ucmVhZF9ieXRlcygp
:::CiAgICAgICAgICAgIGlmIF9lc19qcGcoanBnKToKICAgICAgICAgICAgICAgIHJl
:::dHVybiBqcGcKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgcGFzcwogICAg
:::ZmluYWxseToKICAgICAgICBmb3IgZiBpbiAob3JpZ2VuLCBkZXN0aW5vKToKICAg
:::ICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgZi51bmxpbmsoKQogICAgICAg
:::ICAgICBleGNlcHQgT1NFcnJvcjoKICAgICAgICAgICAgICAgIHBhc3MKICAgIHJl
:::dHVybiBOb25lCgoKZGVmIF93bV9waWN0dXJlKGpwZywgZGVzY3JpcGNpb249Jycp
:::OgogICAgIiIiRW1wYXF1ZXRhIHVub3MgYnl0ZXMgSlBFRyBlbiBlbCBhdHJpYnV0
:::byBXTS9QaWN0dXJlIGRlbCBjb250ZW5lZG9yCiAgICBBU0YgKHRpcG8gMyA9IHBv
:::cnRhZGEgZnJvbnRhbCksIGNvbW8gaGFjaWEgZWwgc2NyaXB0IGFudGlndW8uIiIi
:::CiAgICBkZWYgdTE2KHMpOgogICAgICAgIHJldHVybiBzdHIocykuZW5jb2RlKCd1
:::dGYtMTYtbGUnKSArIGInXHgwMFx4MDAnCgogICAgbWltZSA9IHUxNignaW1hZ2Uv
:::anBlZycpCiAgICBkZXNjID0gdTE2KGRlc2NyaXBjaW9uKQogICAgcmV0dXJuIChi
:::J1x4MDMnICsgbGVuKG1pbWUpLnRvX2J5dGVzKDQsICdsaXR0bGUnKSArIG1pbWUK
:::ICAgICAgICAgICAgKyBsZW4oZGVzYykudG9fYnl0ZXMoNCwgJ2xpdHRsZScpICsg
:::ZGVzYyArIGpwZykKCgpkZWYgX21vb3ZfcHJpbWVybyhydXRhKToKICAgICIiIlRy
:::dWUgc2kgZWwgYXRvbW8gJ21vb3YnIGVzdGEgQU5URVMgcXVlICdtZGF0JyBlbnRy
:::ZSBsYXMgY2FqYXMKICAgIHRvcC1sZXZlbCBkZWwgTVA0L000QSAoZWwgb3JkZW4g
:::J2Zhc3RzdGFydCcgZGUgaVR1bmVzKS4gU29sbyBsZWUKICAgIGxhIGNhYmVjZXJh
:::ICg0IE1CKSBjb24gdW4gcGFzZSBkZSB0YW1hbm9zOiBubyBjYXJnYSBlbCBhcmNo
:::aXZvLiIiIgogICAgdHJ5OgogICAgICAgIHdpdGggb3BlbihydXRhLCAncmInKSBh
:::cyBmaDoKICAgICAgICAgICAgY2FiID0gZmgucmVhZCg0IDw8IDIwKQogICAgZXhj
:::ZXB0IE9TRXJyb3I6CiAgICAgICAgcmV0dXJuIEZhbHNlCiAgICBwb3MsIGZpbiA9
:::IDAsIGxlbihjYWIpCiAgICB3aGlsZSBwb3MgKyA4IDw9IGZpbjoKICAgICAgICB0
:::aXBvID0gY2FiW3BvcyArIDQ6cG9zICsgOF0KICAgICAgICBpZiB0aXBvIGluIChi
:::J21vb3YnLCBiJ21kYXQnKToKICAgICAgICAgICAgcmV0dXJuIHRpcG8gPT0gYidt
:::b292JwogICAgICAgIHNpemUgPSBpbnQuZnJvbV9ieXRlcyhjYWJbcG9zOnBvcyAr
:::IDRdLCAnYmlnJykKICAgICAgICBpZiBzaXplID09IDE6ICAgICAgICAgICAgICAg
:::ICAgICAgICAjIGxhcmdlc2l6ZSBkZSA2NCBiaXRzCiAgICAgICAgICAgIGlmIHBv
:::cyArIDE2ID4gZmluOgogICAgICAgICAgICAgICAgcmV0dXJuIEZhbHNlCiAgICAg
:::ICAgICAgIHNpemUgPSBpbnQuZnJvbV9ieXRlcyhjYWJbcG9zICsgODpwb3MgKyAx
:::Nl0sICdiaWcnKQogICAgICAgICAgICBpZiBzaXplIDwgMTY6CiAgICAgICAgICAg
:::ICAgICByZXR1cm4gRmFsc2UKICAgICAgICBlbGlmIHNpemUgPCA4OiAgICAgICAg
:::ICAgICAgICAgICAgICAjIGNhamEgcm90YSBvIEVPRgogICAgICAgICAgICByZXR1
:::cm4gRmFsc2UKICAgICAgICBwb3MgKz0gc2l6ZQogICAgcmV0dXJuIEZhbHNlCgoK
:::ZGVmIF9tb292X2FsX3ByaW5jaXBpbyhwKToKICAgICIiInYyLjg6IGRlamEgZWwg
:::YXRvbW8gbW9vdiAocXVlIGxsZXZhIGxhcyBldGlxdWV0YXMpIGFsIFBSSU5DSVBJ
:::TwogICAgZGVsIC5tNGEsIGNvbW8gaGFjZSBpVHVuZXMgKCdmYXN0c3RhcnQnKS4K
:::CiAgICBGRm1wZWcgZXNjcmliZSBlbCBNNEEgY29uIG1vb3YgQUwgRklOQUwsIGRl
:::dHJhcyBkZSB0b2RvIGVsIGF1ZGlvCiAgICAobWRhdCkuIEVsIE1QMyBkZSByZWZl
:::cmVuY2lhIHF1ZSBlbCByZXByb2R1Y3RvciBkZWwgdXN1YXJpbyBzaSBsZWUKICAg
:::IGxsZXZhIHN1IElEM3YyIGFsIGluaWNpbyBkZWwgYXJjaGl2bywgeSBsb3MgcmVw
:::cm9kdWN0b3JlcyBiYXJhdG9zCiAgICBzdWVsZW4gYnVzY2FyIGxhcyBldGlxdWV0
:::YXMgZXNjYW5lYW5kbyBzb2xvIGxhIGNhYmVjZXJhIGRlbAogICAgYXJjaGl2bzog
:::cG9yIGVzbyBtb3N0cmFiYW4gJ3Vua25vd24nIGF1bnF1ZSBlbCBNNEEgZXN0dXZp
:::ZXJhCiAgICBwZXJmZWN0YW1lbnRlIGV0aXF1ZXRhZG8gKGF0b21zIGlsc3QgZXN0
:::YW5kYXIsIHZlcmlmaWNhZG8gZW4KICAgIHYyLjcpLiBDb24gLW1vdmZsYWdzICtm
:::YXN0c3RhcnQgZWwgbW9vdiBlbnRlcm8gKHkgZGVudHJvCiAgICBtb292LnVkdGEu
:::bWV0YS5pbHN0IGNvbiB0aXR1bG8vYXJ0aXN0YS9hbGJ1bS9jb3ZyKSBwYXNhIGRl
:::bGFudGUKICAgIGRlbCBtZGF0IFNJTiByZWNvZGlmaWNhciBuYWRhICgtYyBjb3B5
:::KS4gU2kgYWxnbyBmYWxsYSBzZSBkZXZ1ZWx2ZQogICAgRmFsc2UgeSBlbCBhcmNo
:::aXZvIHF1ZWRhIGNvbW8gZXN0YWJhOiBlc3RvIG51bmNhIGRlYmUgcm9tcGVyIGxh
:::CiAgICBkZXNjYXJnYSBuaSBsYXMgZXRpcXVldGFzIHlhIGVzY3JpdGFzLiIiIgog
:::ICAgaWYgbm90IEZGTVBFRyBvciBfbW9vdl9wcmltZXJvKHApOgogICAgICAgIHJl
:::dHVybiBGYWxzZQogICAgdG1wID0gcC53aXRoX25hbWUocC5zdGVtICsgJy5mYXN0
:::c3RhcnQubTRhJykKICAgIHRyeToKICAgICAgICByID0gc3VicHJvY2Vzcy5ydW4o
:::CiAgICAgICAgICAgIFtzdHIoRkZNUEVHKSwgJy15JywgJy1sb2dsZXZlbCcsICdl
:::cnJvcicsICctaScsIHN0cihwKSwKICAgICAgICAgICAgICctbWFwJywgJzAnLCAn
:::LWMnLCAnY29weScsICctbW92ZmxhZ3MnLCAnK2Zhc3RzdGFydCcsCiAgICAgICAg
:::ICAgICBzdHIodG1wKV0sCiAgICAgICAgICAgIHN0ZG91dD1zdWJwcm9jZXNzLkRF
:::Vk5VTEwsIHN0ZGVycj1zdWJwcm9jZXNzLkRFVk5VTEwpCiAgICAgICAgaWYgKHIu
:::cmV0dXJuY29kZSA9PSAwIGFuZCB0bXAuZXhpc3RzKCkKICAgICAgICAgICAgICAg
:::IGFuZCBfbW9vdl9wcmltZXJvKHRtcCkKICAgICAgICAgICAgICAgIGFuZCB0bXAu
:::c3RhdCgpLnN0X3NpemUgKiAxMDAKICAgICAgICAgICAgICAgID49IHAuc3RhdCgp
:::LnN0X3NpemUgKiA5MCk6CiAgICAgICAgICAgIG9zLnJlcGxhY2UodG1wLCBwKQog
:::ICAgICAgICAgICByZXR1cm4gVHJ1ZQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAg
:::ICAgICBwYXNzCiAgICBmaW5hbGx5OgogICAgICAgIHRyeToKICAgICAgICAgICAg
:::dG1wLnVubGluaygpCiAgICAgICAgZXhjZXB0IE9TRXJyb3I6CiAgICAgICAgICAg
:::IHBhc3MKICAgIHJldHVybiBGYWxzZQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBldGlx
:::dWV0YXMKZGVmIF9hcnRpc3RhX2xpbXBpbyhpbmZvKToKICAgICIiIk5vbWJyZSBk
:::ZWwgYXJ0aXN0YSBsZWdpYmxlIHBhcmEgcmVwcm9kdWN0b3Jlcy4KCiAgICBMb3Mg
:::Y2FuYWxlcyBhdXRvbWF0aWNvcyBkZSBtdXNpY2EgZGUgWW91VHViZSBzZSBsbGFt
:::YW4gJ1ggLSBUb3BpYyc7CiAgICBlc2Ugc3VmaWpvIHNvYnJhIGN1YW5kbyBzZSB2
:::ZSBlbiBsYSBwYW50YWxsYSBkZSB1biByZXByb2R1Y3Rvci4iIiIKICAgIGEgPSAo
:::aW5mby5nZXQoJ2FydGlzdCcpIG9yIGluZm8uZ2V0KCdjcmVhdG9yJykKICAgICAg
:::ICAgb3IgaW5mby5nZXQoJ3VwbG9hZGVyJykgb3IgaW5mby5nZXQoJ2NoYW5uZWwn
:::KSBvciAnJykKICAgIGEgPSBzdHIoYSkuc3RyaXAoKQogICAgYSA9IHJlLnN1Yihy
:::J1xzKi1ccypUb3BpY1xzKiQnLCAnJywgYSwgZmxhZ3M9cmUuSSkuc3RyaXAoKQog
:::ICAgcmV0dXJuIGEKCgpkZWYgX2FsYnVtX2RlKGluZm8pOgogICAgIiIiQWxidW0g
:::cGFyYSBlbCBhcmNoaXZvIGZpbmFsLgoKICAgIHl0LWRscCBzb2xvIGVzY3JpYmUg
:::YWxidW0gc2kgZWwgcHJvcGlvIHZpZGVvIGxvIHRyYWUgKGNhc2kgbnVuY2EpOgog
:::ICAgcG9yIGVzbyBsb3MgcmVwcm9kdWN0b3JlcyBtb3N0cmFiYW4gJ2FsYnVtIGRl
:::c2Nvbm9jaWRvJy4gT3JkZW4gZGUKICAgIHByZWZlcmVuY2lhOiBhbGJ1bSByZWFs
:::IC0+IG5vbWJyZSBkZSBsYSBwbGF5bGlzdCAtPiBhcnRpc3RhLiIiIgogICAgZm9y
:::IGNsYXZlIGluICgnYWxidW0nLCAncGxheWxpc3RfdGl0bGUnKToKICAgICAgICB2
:::ID0gc3RyKGluZm8uZ2V0KGNsYXZlKSBvciAnJykuc3RyaXAoKQogICAgICAgIGlm
:::IHY6CiAgICAgICAgICAgIHJldHVybiB2CiAgICByZXR1cm4gX2FydGlzdGFfbGlt
:::cGlvKGluZm8pIG9yICdZb3VUdWJlJwoKCmRlZiBhcGxpY2FyX3RhZ3MoaW5mbywg
:::YXJjaGl2bywgbG9nPU5vbmUsIGNhcmF0dWxhPU5vbmUpOgogICAgIiIiRXNjcmli
:::ZSBjb24gbXV0YWdlbiBsYXMgZXRpcXVldGFzIGRlbCBhcmNoaXZvIGZpbmFsLgoK
:::ICAgIEdhcmFudGl6YSBxdWUgVE9ET1MgbG9zIHJlcHJvZHVjdG9yZXMgbXVlc3Ry
:::ZW4gYXJ0aXN0YSB5IGFsYnVtLAogICAgYXVucXVlIEZGbXBlZ01ldGFkYXRhIGRl
:::IHl0LWRscCBubyBsb3MgaGF5YSBlc2NyaXRvLiBDYWRhIGZvcm1hdG8KICAgIGNv
:::biBTVSBmb3JtYSBlc3RhbmRhcjoKICAgICAgwrcgTVAzOiBJRDN2Mi40IGNvbiB0
:::ZXh0b3MgVVRGLTE2IChlbmNvZGluZz0xKSB5IEFQSUMobWltZQogICAgICAgICdp
:::bWFnZS9qcGcnLCB0aXBvIDMsIGRlc2MgJ2F0dGFjaGVkIHBpY3R1cmUnKSwgY2Fs
:::Y2FkbyBkZWwKICAgICAgICBNUDMgZGUgcmVmZXJlbmNpYSBxdWUgZWwgcmVwcm9k
:::dWN0b3IgZGVsIHVzdWFyaW8gbXVlc3RyYQogICAgICAgIGJpZW4uIEVsIHBhc2Ug
:::YW50aWd1byB1c2FiYSBlbmNvZGluZz0zIChVVEYtOCkgZGVudHJvIGRlIHVuCiAg
:::ICAgICAgdGFnIHYyLjM6IGZ1ZXJhIGRlIGVzcGVjaWZpY2FjaW9uLCB5IGxvcyBy
:::ZXByb2R1Y3RvcmVzCiAgICAgICAgYmFyYXRvcyBkZXNjYXJ0YWJhbiBsYSBldGlx
:::dWV0YSBFTlRFUkEgKG5pIGFydGlzdGEsIG5pCiAgICAgICAgYWxidW0sIG5pIHBv
:::cnRhZGEpLgogICAgICDCtyBNNEE6IGF0b21vcyBNUDQgZXN0YW5kYXIgKMKpbmFt
:::L8KpQVJUL2FBUlQvwqlhbGIvwqlkYXkvwqljbXQpIHkKICAgICAgICBjb3ZyIGVu
:::IEpQRUcsIGNvbW8gaVR1bmVzOyBhZGVtYXMgKHYyLjgpIGVsIGF0b21vIG1vb3Yg
:::cXVlZGEKICAgICAgICBBTCBQUklOQ0lQSU8gZGVsIGFyY2hpdm8gKGZhc3RzdGFy
:::dCk6IGZmbXBlZyBsbyBlc2NyaWJlIGFsCiAgICAgICAgZmluYWwgeSBsb3MgcmVw
:::cm9kdWN0b3JlcyBiYXJhdG9zIHNvbG8gZXNjYW5lYW4gbGEgY2FiZWNlcmEsCiAg
:::ICAgICAgcG9yIGVzbyBtb3N0cmFiYW4gJ3Vua25vd24nIGF1bnF1ZSBsYXMgZXRp
:::cXVldGFzIGVzdHV2aWVyYW4uCiAgICAgIMK3IFdBVjogSUQzIGRlbnRybyBkZWwg
:::UklGRiAobXV0YWdlbi53YXZlKSwgaWd1YWwgcXVlIGVsIE1QMywKICAgICAgICBt
:::YXMgQVBJQyBjb24gbGEgY2FyYXR1bGEgKG51ZXZvIGVuIHYyLjcpLgogICAgICDC
:::tyBGTEFDOiBWb3JiaXMgY29tbWVudHMgKyBQaWN0dXJlIGVuIEpQRUcuCiAgICAg
:::IMK3IFdNQTogQVNGIFRpdGxlL0F1dGhvci9XTS9BbGJ1bVRpdGxlL1dNL0F1dGhv
:::clVSTCArIFdNL1BpY3R1cmUuCiAgICAgIMK3IGxhIGNhcmF0dWxhIFNJRU1QUkUg
:::YWNhYmEgZW4gSlBFRyB5IHNlIGVzY3JpYmUgQVFVSSBjb24KICAgICAgICBtdXRh
:::Z2VuOiBkZXNkZSB2Mi43IEVtYmVkVGh1bWJuYWlsIHlhIG5vIHRvY2EgbGEgY2Fy
:::YXR1bGEKICAgICAgICAoc3UgbWV0b2RvIGNhbWJpYSBlbnRyZSB2ZXJzaW9uZXMg
:::ZGUgeXQtZGxwIHkgYWxndW5hCiAgICAgICAgY29udmVyc2lvbiBzdXlhIGRlamFi
:::YSBQTkcvV2ViUCBxdWUgbG9zIHJlcHJvZHVjdG9yZXMKICAgICAgICBiYXJhdG9z
:::IG5vIGxlZW4pOwogICAgICDCtyBlbCBjb21lbnRhcmlvIGd1YXJkYSBsYSBVUkwg
:::ZGVsIHZpZGVvIChjb21vIGVsIHNjcmlwdCBhbnRpZ3VvKS4KICAgIGBjYXJhdHVs
:::YWAgc29uIGxvcyBieXRlcyBkZSBsYSBtaW5pYXR1cmEgZGVzY2FyZ2FkYSAob3Bj
:::aW9uYWwpLiIiIgogICAgdHJ5OgogICAgICAgIHAgPSBQYXRoKGFyY2hpdm8pCiAg
:::ICAgICAgaWYgbm90IHAuZXhpc3RzKCk6CiAgICAgICAgICAgIHJldHVybgogICAg
:::ICAgIGFydGlzdGEgPSBfYXJ0aXN0YV9saW1waW8oaW5mbykKICAgICAgICBhbGJ1
:::bSA9IF9hbGJ1bV9kZShpbmZvKQogICAgICAgIHRpdHVsbyA9IHN0cihpbmZvLmdl
:::dCgndHJhY2snKSBvciBpbmZvLmdldCgndGl0bGUnKSBvciAnJykuc3RyaXAoKQog
:::ICAgICAgIGZlY2hhID0gc3RyKGluZm8uZ2V0KCdyZWxlYXNlX3llYXInKSBvciAn
:::JykKICAgICAgICBpZiBub3QgZmVjaGE6CiAgICAgICAgICAgIGZlY2hhID0gc3Ry
:::KGluZm8uZ2V0KCd1cGxvYWRfZGF0ZScpIG9yICcnKQogICAgICAgICAgICBpZiBs
:::ZW4oZmVjaGEpID09IDggYW5kIGZlY2hhLmlzZGlnaXQoKToKICAgICAgICAgICAg
:::ICAgIGZlY2hhID0gZmVjaGFbOjRdCiAgICAgICAgdXJsID0gc3RyKGluZm8uZ2V0
:::KCd3ZWJwYWdlX3VybCcpIG9yICcnKS5zdHJpcCgpCiAgICAgICAgaWYgY2FyYXR1
:::bGEgYW5kIG5vdCBfZXNfanBnKGNhcmF0dWxhKToKICAgICAgICAgICAgY2FyYXR1
:::bGEgPSBfYV9qcGcoY2FyYXR1bGEpCiAgICAgICAgZXh0ID0gcC5zdWZmaXgubG93
:::ZXIoKQogICAgICAgIGlmIGV4dCA9PSAnLm00YSc6CiAgICAgICAgICAgICMgdjIu
:::ODogQU5URVMgZGUgZXRpcXVldGFyLCBtb292ICh0aXR1bG8vYXJ0aXN0YS9hbGJ1
:::bS9jb3ZyKQogICAgICAgICAgICAjIGFsIHByaW5jaXBpbyBkZWwgYXJjaGl2bzsg
:::bXV0YWdlbiBjb25zZXJ2YSBlc2Ugb3JkZW4uCiAgICAgICAgICAgIGlmIF9tb292
:::X2FsX3ByaW5jaXBpbyhwKSBhbmQgbG9nOgogICAgICAgICAgICAgICAgbG9nKCdN
:::NEEgcmVvcmRlbmFkbzogZXRpcXVldGFzIGFsIGluaWNpbyAoZmFzdHN0YXJ0LCAn
:::CiAgICAgICAgICAgICAgICAgICAgJ2NvbW8gaVR1bmVzKScsICdncmlzJykKICAg
:::ICAgICAgICAgZnJvbSBtdXRhZ2VuLm1wNCBpbXBvcnQgTVA0LCBNUDRDb3Zlcgog
:::ICAgICAgICAgICBtID0gTVA0KHN0cihwKSkKICAgICAgICAgICAgaWYgdGl0dWxv
:::OgogICAgICAgICAgICAgICAgbVsnXHhhOW5hbSddID0gW3RpdHVsb10KICAgICAg
:::ICAgICAgaWYgYXJ0aXN0YToKICAgICAgICAgICAgICAgIG1bJ1x4YTlBUlQnXSA9
:::IFthcnRpc3RhXQogICAgICAgICAgICAgICAgbVsnYUFSVCddID0gW2FydGlzdGFd
:::CiAgICAgICAgICAgIGlmIGFsYnVtOgogICAgICAgICAgICAgICAgbVsnXHhhOWFs
:::YiddID0gW2FsYnVtXQogICAgICAgICAgICBpZiBmZWNoYToKICAgICAgICAgICAg
:::ICAgIG1bJ1x4YTlkYXknXSA9IFtmZWNoYV0KICAgICAgICAgICAgaWYgdXJsOgog
:::ICAgICAgICAgICAgICAgbVsnXHhhOWNtdCddID0gW3VybF0KICAgICAgICAgICAg
:::IyAtLSBjYXJhdHVsYTogZGVzZGUgdjIuNyBsYSBlc2NyaWJlIFNJRU1QUkUgZXN0
:::ZSBwYXNlIGNvbgogICAgICAgICAgICAjICAgIG11dGFnZW4gKEVtYmVkVGh1bWJu
:::YWlsIHlhIG5vIHBhcnRpY2lwYSkuIEF0b21vCiAgICAgICAgICAgICMgICAgZXN0
:::YW5kYXIgJ2NvdnInIChzaW4gZWwgcHJlZmlqbyAoYykpOyBlbiBtdXRhZ2VuCiAg
:::ICAgICAgICAgICMgICAgbW9kZXJubyBlc2NyaWJpciAnXHhhOWNvdnInIGxhbnph
:::IFR5cGVFcnJvci4KICAgICAgICAgICAgdmllamFzID0gbS5nZXQoJ2NvdnInKSBv
:::ciBtLmdldCgnXHhhOWNvdnInKSBvciBbXQogICAgICAgICAgICBpZiBub3Qgdmll
:::amFzOgogICAgICAgICAgICAgICAgaWYgY2FyYXR1bGE6CiAgICAgICAgICAgICAg
:::ICAgICAgbVsnY292ciddID0gW01QNENvdmVyKGNhcmF0dWxhLCBNUDRDb3Zlci5G
:::T1JNQVRfSlBFRyldCiAgICAgICAgICAgIGVsaWYgYWxsKGMuaW1hZ2Vmb3JtYXQg
:::IT0gTVA0Q292ZXIuRk9STUFUX0pQRUcKICAgICAgICAgICAgICAgICAgICAgZm9y
:::IGMgaW4gdmllamFzKToKICAgICAgICAgICAgICAgIG51ZXZhID0gX2FfanBnKGJ5
:::dGVzKHZpZWphc1swXSkpIG9yIGNhcmF0dWxhCiAgICAgICAgICAgICAgICBpZiBu
:::dWV2YToKICAgICAgICAgICAgICAgICAgICBtWydjb3ZyJ10gPSBbTVA0Q292ZXIo
:::bnVldmEsIE1QNENvdmVyLkZPUk1BVF9KUEVHKV0KICAgICAgICAgICAgICAgICAg
:::ICBtLnBvcCgnXHhhOWNvdnInLCBOb25lKQogICAgICAgICAgICBlbGlmIG0uZ2V0
:::KCdceGE5Y292cicpOgogICAgICAgICAgICAgICAgbVsnY292ciddID0gdmllamFz
:::CiAgICAgICAgICAgICAgICBtLnBvcCgnXHhhOWNvdnInLCBOb25lKQogICAgICAg
:::ICAgICBtLnNhdmUoKQogICAgICAgIGVsaWYgZXh0ID09ICcubXAzJzoKICAgICAg
:::ICAgICAgIyBGb3JtYXRvIEVYQUNUTyBkZWwgTVAzIGRlIHJlZmVyZW5jaWEgKFNu
:::YXB0dWJlLCBlc2NyaXRvIHBvcgogICAgICAgICAgICAjIEZGbXBlZy9MYXZmKSBx
:::dWUgZWwgcmVwcm9kdWN0b3IgZGVsIHVzdWFyaW8gU0kgbXVlc3RyYToKICAgICAg
:::ICAgICAgIyAgIElEM3YyLjQuMCArIFRJVDIvVFBFMS9UQUxCL0FQSUMgZW4gZW5j
:::b2Rpbmc9MSAoVVRGLTE2IGNvbgogICAgICAgICAgICAjICAgQk9NKSArIEFQSUMo
:::bWltZSAnaW1hZ2UvanBnJywgdGlwbyAzID0gQ09WRVJfRlJPTlQsIGRlc2MKICAg
:::ICAgICAgICAgIyAgICdhdHRhY2hlZCBwaWN0dXJlJywgSlBFRyByZWFsKS4gRWwg
:::cGFzZSBhbnRlcmlvciBlc2NyaWJpYQogICAgICAgICAgICAjICAgZW5jb2Rpbmc9
:::MyAoVVRGLTgpIGRlbnRybyBkZSB1biB0YWcgdjIuMzogZnVlcmEgZGUKICAgICAg
:::ICAgICAgIyAgIGVzcGVjaWZpY2FjaW9uLCB5IGxvcyByZXByb2R1Y3RvcmVzIGJh
:::cmF0b3MgZGVzY2FydGFiYW4KICAgICAgICAgICAgIyAgIGxhIGV0aXF1ZXRhIGVu
:::dGVyYSAobmkgYXJ0aXN0YSwgbmkgYWxidW0sIG5pIHBvcnRhZGEpLgogICAgICAg
:::ICAgICBmcm9tIG11dGFnZW4uaWQzIGltcG9ydCAoQVBJQywgQ09NTSwgSUQzLCBU
:::QUxCLCBURFJDLCBUSVQyLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgVExFTiwgVFBFMSwgVFBFMikKICAgICAgICAgICAgdHJ5OgogICAgICAg
:::ICAgICAgICAgdGFncyA9IElEMyhzdHIocCkpCiAgICAgICAgICAgIGV4Y2VwdCBF
:::eGNlcHRpb246CiAgICAgICAgICAgICAgICB0YWdzID0gSUQzKCkKICAgICAgICAg
:::ICAgaWYgdGl0dWxvOgogICAgICAgICAgICAgICAgdGFncy5zZXRhbGwoJ1RJVDIn
:::LCBbVElUMihlbmNvZGluZz0xLCB0ZXh0PVt0aXR1bG9dKV0pCiAgICAgICAgICAg
:::IGlmIGFydGlzdGE6CiAgICAgICAgICAgICAgICB0YWdzLnNldGFsbCgnVFBFMScs
:::IFtUUEUxKGVuY29kaW5nPTEsIHRleHQ9W2FydGlzdGFdKV0pCiAgICAgICAgICAg
:::ICAgICB0YWdzLnNldGFsbCgnVFBFMicsIFtUUEUyKGVuY29kaW5nPTEsIHRleHQ9
:::W2FydGlzdGFdKV0pCiAgICAgICAgICAgIGlmIGFsYnVtOgogICAgICAgICAgICAg
:::ICAgdGFncy5zZXRhbGwoJ1RBTEInLCBbVEFMQihlbmNvZGluZz0xLCB0ZXh0PVth
:::bGJ1bV0pXSkKICAgICAgICAgICAgaWYgZmVjaGE6CiAgICAgICAgICAgICAgICB0
:::YWdzLnNldGFsbCgnVERSQycsIFtURFJDKGVuY29kaW5nPTEsIHRleHQ9W2ZlY2hh
:::XSldKQogICAgICAgICAgICBkdXIgPSBpbmZvLmdldCgnZHVyYXRpb24nKQogICAg
:::ICAgICAgICBpZiBkdXI6CiAgICAgICAgICAgICAgICB0cnk6CiAgICAgICAgICAg
:::ICAgICAgICAgdGFncy5zZXRhbGwoJ1RMRU4nLCBbVExFTihlbmNvZGluZz0wLCB0
:::ZXh0PVsKICAgICAgICAgICAgICAgICAgICAgICAgc3RyKGludChmbG9hdChkdXIp
:::ICogMTAwMCkpXSldKQogICAgICAgICAgICAgICAgZXhjZXB0IChUeXBlRXJyb3Is
:::IFZhbHVlRXJyb3IpOgogICAgICAgICAgICAgICAgICAgIHBhc3MKICAgICAgICAg
:::ICAgaWYgdXJsOgogICAgICAgICAgICAgICAgdGFncy5zZXRhbGwoJ0NPTU0nLCBb
:::Q09NTShlbmNvZGluZz0xLCBsYW5nPSdlbmcnLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICBkZXNjPScnLCB0ZXh0PVt1cmxdKV0pCiAg
:::ICAgICAgICAgICMgUG9ydGFkYTogbWlzbWFzIGNvbnN0YW50ZXMgZGVsIGFyY2hp
:::dm8gZGUgcmVmZXJlbmNpYS4KICAgICAgICAgICAgIyBCeXRlczogYGNhcmF0dWxh
:::YCBvLCBzaSBFbWJlZFRodW1ibmFpbCB5YSBpbmNydXN0byBhbGdvLAogICAgICAg
:::ICAgICAjIGxvcyBkYXRvcyBkZWwgQVBJQyBleGlzdGVudGU7IHNpZW1wcmUgYWNh
:::YmFtb3MgZW4gSlBFRy4KICAgICAgICAgICAgZGF0b3MgPSBjYXJhdHVsYQogICAg
:::ICAgICAgICBpZiBub3QgZGF0b3M6CiAgICAgICAgICAgICAgICBhcGljcyA9IHRh
:::Z3MuZ2V0YWxsKCdBUElDJykKICAgICAgICAgICAgICAgIGlmIGFwaWNzOgogICAg
:::ICAgICAgICAgICAgICAgIGRhdG9zID0gYXBpY3NbMF0uZGF0YQogICAgICAgICAg
:::ICBpZiBkYXRvcyBhbmQgbm90IF9lc19qcGcoZGF0b3MpOgogICAgICAgICAgICAg
:::ICAgZGF0b3MgPSBfYV9qcGcoZGF0b3MpCiAgICAgICAgICAgIGlmIGRhdG9zOgog
:::ICAgICAgICAgICAgICAgdGFncy5zZXRhbGwoJ0FQSUMnLCBbQVBJQyhlbmNvZGlu
:::Zz0xLCBtaW1lPSdpbWFnZS9qcGcnLAogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICB0eXBlPTMsIGRlc2M9J2F0dGFjaGVkIHBpY3R1cmUn
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkYXRh
:::PWRhdG9zKV0pCiAgICAgICAgICAgICMgdjIuNCArIFVURi0xNjogbGEgbWlzbWEg
:::Y29tYmluYWNpb24gZGVsIGFyY2hpdm8gZGUKICAgICAgICAgICAgIyByZWZlcmVu
:::Y2lhIChJRDN2Mi40LjAgZXNjcml0byBwb3IgTGF2ZjYwLjMuMTAwKS4KICAgICAg
:::ICAgICAgdGFncy5zYXZlKHN0cihwKSwgdjJfdmVyc2lvbj00KQogICAgICAgIGVs
:::aWYgZXh0ID09ICcud2F2JzoKICAgICAgICAgICAgZnJvbSBtdXRhZ2VuLmlkMyBp
:::bXBvcnQgKEFQSUMsIENPTU0sIFREUkMsIFRJVDIsIFRMRU4sIFRQRTEsCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBUUEUyLCBUQUxCKQogICAg
:::ICAgICAgICBmcm9tIG11dGFnZW4ud2F2ZSBpbXBvcnQgV0FWRQogICAgICAgICAg
:::ICB3ID0gV0FWRShzdHIocCkpCiAgICAgICAgICAgIGlmIHcudGFncyBpcyBOb25l
:::OgogICAgICAgICAgICAgICAgdy5hZGRfdGFncygpCiAgICAgICAgICAgICMgZW5j
:::b2Rpbmc9MSAoVVRGLTE2KSwgbWlzbWEgcmVnbGEgcXVlIGVuIE1QMzogbG9zCiAg
:::ICAgICAgICAgICMgcmVwcm9kdWN0b3JlcyBiYXJhdG9zIG5vIHBhcnNlYW4gZnJh
:::bWVzIFVURi04LgogICAgICAgICAgICBpZiB0aXR1bG86CiAgICAgICAgICAgICAg
:::ICB3LnRhZ3Muc2V0YWxsKCdUSVQyJywgW1RJVDIoZW5jb2Rpbmc9MSwgdGV4dD1b
:::dGl0dWxvXSldKQogICAgICAgICAgICBpZiBhcnRpc3RhOgogICAgICAgICAgICAg
:::ICAgdy50YWdzLnNldGFsbCgnVFBFMScsIFtUUEUxKGVuY29kaW5nPTEsIHRleHQ9
:::W2FydGlzdGFdKV0pCiAgICAgICAgICAgICAgICB3LnRhZ3Muc2V0YWxsKCdUUEUy
:::JywgW1RQRTIoZW5jb2Rpbmc9MSwgdGV4dD1bYXJ0aXN0YV0pXSkKICAgICAgICAg
:::ICAgaWYgYWxidW06CiAgICAgICAgICAgICAgICB3LnRhZ3Muc2V0YWxsKCdUQUxC
:::JywgW1RBTEIoZW5jb2Rpbmc9MSwgdGV4dD1bYWxidW1dKV0pCiAgICAgICAgICAg
:::IGlmIGZlY2hhOgogICAgICAgICAgICAgICAgdy50YWdzLnNldGFsbCgnVERSQycs
:::IFtURFJDKGVuY29kaW5nPTEsIHRleHQ9W2ZlY2hhXSldKQogICAgICAgICAgICBk
:::dXIgPSBpbmZvLmdldCgnZHVyYXRpb24nKQogICAgICAgICAgICBpZiBkdXI6CiAg
:::ICAgICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICAgICAgdy50YWdzLnNl
:::dGFsbCgnVExFTicsIFtUTEVOKGVuY29kaW5nPTAsIHRleHQ9WwogICAgICAgICAg
:::ICAgICAgICAgICAgICBzdHIoaW50KGZsb2F0KGR1cikgKiAxMDAwKSldKV0pCiAg
:::ICAgICAgICAgICAgICBleGNlcHQgKFR5cGVFcnJvciwgVmFsdWVFcnJvcik6CiAg
:::ICAgICAgICAgICAgICAgICAgcGFzcwogICAgICAgICAgICBpZiB1cmw6CiAgICAg
:::ICAgICAgICAgICB3LnRhZ3Muc2V0YWxsKCdDT01NJywgW0NPTU0oZW5jb2Rpbmc9
:::MSwgbGFuZz0nZW5nJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICBkZXNjPScnLCB0ZXh0PVt1cmxdKV0pCiAgICAgICAgICAgICMg
:::djIuNzogY2FyYXR1bGEgZW4gZWwgSUQzIGRlbCBXQVYgKG1pc21hcyBjb25zdGFu
:::dGVzIHF1ZQogICAgICAgICAgICAjIGVsIE1QMyBkZSByZWZlcmVuY2lhKSwgcGFy
:::YSBsb3MgcmVwcm9kdWN0b3JlcyBxdWUgbGVlbgogICAgICAgICAgICAjIGVsIGNo
:::dW5rICdpZDMgJyBkZW50cm8gZGVsIFJJRkYuCiAgICAgICAgICAgIGRhdG9zID0g
:::Y2FyYXR1bGEKICAgICAgICAgICAgaWYgbm90IGRhdG9zOgogICAgICAgICAgICAg
:::ICAgYXBpY3MgPSB3LnRhZ3MuZ2V0YWxsKCdBUElDJykKICAgICAgICAgICAgICAg
:::IGlmIGFwaWNzOgogICAgICAgICAgICAgICAgICAgIGRhdG9zID0gYXBpY3NbMF0u
:::ZGF0YQogICAgICAgICAgICBpZiBkYXRvcyBhbmQgbm90IF9lc19qcGcoZGF0b3Mp
:::OgogICAgICAgICAgICAgICAgZGF0b3MgPSBfYV9qcGcoZGF0b3MpCiAgICAgICAg
:::ICAgIGlmIGRhdG9zOgogICAgICAgICAgICAgICAgdy50YWdzLnNldGFsbCgnQVBJ
:::QycsIFtBUElDKGVuY29kaW5nPTEsIG1pbWU9J2ltYWdlL2pwZycsCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZT0zLCBkZXNj
:::PSdhdHRhY2hlZCBwaWN0dXJlJywKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICBkYXRhPWRhdG9zKV0pCiAgICAgICAgICAgIHcuc2F2
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
:::CgogICAgeXQtZGxwIFNPTE8gYmFqYSwgY29udmllcnRlIHkgZXNjcmliZSBsb3Mg
:::bWV0YWRhdG9zIGRlIHRleHRvCiAgICAoRkZtcGVnTWV0YWRhdGEpLiBMYSBjYXLD
:::oXR1bGEgTk8gbGEgaW5jcnVzdGEgRW1iZWRUaHVtYm5haWw6IGRlc2RlCiAgICB2
:::Mi43IGxhIGVzY3JpYmUgYXBsaWNhcl90YWdzIGNvbiBtdXRhZ2VuIChjb3ZyIGVu
:::IG00YSwgQVBJQyBlbgogICAgbXAzL3dhdiwgUGljdHVyZSBlbiBmbGFjKSwgc2ll
:::bXByZSBlbiBKUEVHIHkgY29uIGxhIGVzdHJ1Y3R1cmEKICAgIGV4YWN0YSBxdWUg
:::bGVlbiBsb3MgcmVwcm9kdWN0b3Jlcy4gQXPDrSBlbCByZXN1bHRhZG8gbm8gZGVw
:::ZW5kZSBkZQogICAgbG9zIG3DqXRvZG9zIGludGVybm9zIGRlIEVtYmVkVGh1bWJu
:::YWlsLCBxdWUgY2FtYmlhbiBlbnRyZQogICAgdmVyc2lvbmVzIGRlIHl0LWRscCAo
:::YW50ZXMgY29udmVydMOtYSBsYSBwb3J0YWRhIGEgUE5HLCB5IHN1CiAgICBtw6l0
:::b2RvIGZmbXBlZyBhZGp1bnRhIGxhIGltYWdlbiBjb21vIHN0cmVhbSBkZSB2w61k
:::ZW8pLiIiIgogICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAgICAgICAgY29sYS5w
:::dXQoKCdsb2cnLCBtLCB0KSkKCiAgICBmbXQgPSBGT1JNQVRPU1tub21icmVfZm10
:::XQogICAgY2FycGV0YSA9IGRlc3Rpbm8gICAgICAgICAgIyB2Mi4zOiBzaW4gc3Vi
:::Y2FycGV0YXMgcG9yIGZvcm1hdG8KICAgIGNhcnBldGEubWtkaXIocGFyZW50cz1U
:::cnVlLCBleGlzdF9vaz1UcnVlKQogICAgY29kZWMgPSBmbXRbJ2V4dCddCiAgICBj
:::b25fcG9ydGFkYSA9IGVtYmViZXIgYW5kIG5vbWJyZV9mbXQgaW4gKCdBQUMnLCAn
:::TVAzJywgJ0ZMQUMnLCAnV0FWJykKICAgIGNvbl90YWdzID0gZW1iZWJlcgogICAg
:::cHBzID0gW10KICAgIGlmIGNvbl9wb3J0YWRhOgogICAgICAgIHBwcy5hcHBlbmQo
:::eydrZXknOiAnRkZtcGVnVGh1bWJuYWlsc0NvbnZlcnRvcicsICdmb3JtYXQnOiAn
:::anBnJywKICAgICAgICAgICAgICAgICAgICAnd2hlbic6ICdiZWZvcmVfZGwnfSkK
:::ICAgIHBwcy5hcHBlbmQoeydrZXknOiAnRkZtcGVnRXh0cmFjdEF1ZGlvJywgJ3By
:::ZWZlcnJlZGNvZGVjJzogY29kZWMsCiAgICAgICAgICAgICAgICAncHJlZmVycmVk
:::cXVhbGl0eSc6IGNhbGlkYWQgb3IgJzAnfSkKICAgIGlmIGNvbl90YWdzOgogICAg
:::ICAgIHBwcy5hcHBlbmQoeydrZXknOiAnRkZtcGVnTWV0YWRhdGEnLCAnYWRkX21l
:::dGFkYXRhJzogVHJ1ZX0pCiAgICAjIHYyLjc6IFNJTiBFbWJlZFRodW1ibmFpbC4g
:::TGEgbWluaWF0dXJhIChkZWphZGEgZW4gLmpwZyBqdW50byBhbAogICAgIyBhcmNo
:::aXZvIHBvciB3cml0ZXRodW1ibmFpbCArIENvbnZlcnRvcikgbGEgaW5jcnVzdGEg
:::YXBsaWNhcl90YWdzCiAgICAjIGNvbiBtdXRhZ2VuOiBlc3RydWN0dXJhIGdhcmFu
:::dGl6YWRhIGVuIHRvZG9zIGxvcyBmb3JtYXRvcyB5IHNpbgogICAgIyBkZXBlbmRl
:::ciBkZSBsb3MgbcOpdG9kb3MgaW50ZXJub3MgZGUgeXQtZGxwLgogICAgbyA9IG9w
:::dHNfYmFzZShjYXJwZXRhLCBjb2xhKQogICAgb1snZm9ybWF0J10gPSAnYmVzdGF1
:::ZGlvL2Jlc3QnCiAgICBvWydwb3N0cHJvY2Vzc29ycyddID0gcHBzCiAgICBvWyd3
:::cml0ZXRodW1ibmFpbCddID0gY29uX3BvcnRhZGEKICAgIHdpdGggWVRfRExQLllv
:::dXR1YmVETChvKSBhcyB5ZGw6CiAgICAgICAgaW5mbyA9IHlkbC5leHRyYWN0X2lu
:::Zm8odXJsLCBkb3dubG9hZD1UcnVlKQogICAgYXJjaGl2byA9IGFyY2hpdm9fZmlu
:::YWwoaW5mbywgY2FycGV0YSwgY29kZWMpCiAgICBjYXJhdHVsYSA9IF9taW5pYXR1
:::cmFfYnl0ZXMoY2FycGV0YSwgYXJjaGl2bykKICAgIGlmIGFyY2hpdm8gYW5kIGNv
:::bl9wb3J0YWRhOgogICAgICAgIGxpbXBpYXJfbWluaWF0dXJhcyhjYXJwZXRhLCBh
:::cmNoaXZvKQogICAgaWYgYXJjaGl2bzoKICAgICAgICBhcGxpY2FyX3RhZ3MoaW5m
:::bywgYXJjaGl2bywgbG9nLCBjYXJhdHVsYSkKICAgIHJldHVybiBpbmZvLCBhcmNo
:::aXZvCgoKZGVmIGRlc2Nhcmdhcl93bWEodXJsLCBjYWxpZGFkLCBkZXN0aW5vLCBl
:::bWJlYmVyLCBjb2xhKToKICAgICIiIldNQSA5Ni8xMjgga2JwczogeXQtZGxwIG5v
:::IHNvcG9ydGEgd21hLCBhc8OtIHF1ZSBzZSBiYWphIGEgV0FWIChjb24KICAgIGV0
:::aXF1ZXRhcykgeSBsdWVnbyBGRm1wZWcgcmVjb2RpZmljYSBhIHdtYXYyIGRlbnRy
:::byBkZWwgLndtYSBmaW5hbC4KICAgIExhIGNhcsOhdHVsYSAoV00vUGljdHVyZSwg
:::ZW4gSlBFRykgeSBsYSBVUkwgKFdNL0F1dGhvclVSTCkgc2UKICAgIGluY3J1c3Rh
:::biBjb24gbXV0YWdlbiwgY29tbyBlbiBlbCBzY3JpcHQgYW50aWd1by4iIiIKICAg
:::IGRlZiBsb2cobSwgdD0naW5mbycpOgogICAgICAgIGNvbGEucHV0KCgnbG9nJywg
:::bSwgdCkpCgogICAgY2FycGV0YSA9IGRlc3Rpbm8gICAgICAgICAgIyB2Mi4zOiBz
:::aW4gc3ViY2FycGV0YXMgcG9yIGZvcm1hdG8KICAgIHRtcCA9IGNhcnBldGEgLyAn
:::X3RtcCcKICAgIHNodXRpbC5ybXRyZWUodG1wLCBpZ25vcmVfZXJyb3JzPVRydWUp
:::CiAgICB0bXAubWtkaXIocGFyZW50cz1UcnVlLCBleGlzdF9vaz1UcnVlKQogICAg
:::byA9IG9wdHNfYmFzZSh0bXAsIGNvbGEpCiAgICBvWydmb3JtYXQnXSA9ICdiZXN0
:::YXVkaW8vYmVzdCcKICAgIHBwcyA9IFt7J2tleSc6ICdGRm1wZWdFeHRyYWN0QXVk
:::aW8nLCAncHJlZmVycmVkY29kZWMnOiAnd2F2JywKICAgICAgICAgICAgJ3ByZWZl
:::cnJlZHF1YWxpdHknOiAnMCd9XQogICAgaWYgZW1iZWJlcjoKICAgICAgICBwcHMu
:::aW5zZXJ0KDAsIHsna2V5JzogJ0ZGbXBlZ1RodW1ibmFpbHNDb252ZXJ0b3InLAog
:::ICAgICAgICAgICAgICAgICAgICAgICdmb3JtYXQnOiAnanBnJywgJ3doZW4nOiAn
:::YmVmb3JlX2RsJ30pCiAgICAgICAgcHBzLmFwcGVuZCh7J2tleSc6ICdGRm1wZWdN
:::ZXRhZGF0YScsICdhZGRfbWV0YWRhdGEnOiBUcnVlfSkKICAgIG9bJ3Bvc3Rwcm9j
:::ZXNzb3JzJ10gPSBwcHMKICAgIG9bJ3dyaXRldGh1bWJuYWlsJ10gPSBlbWJlYmVy
:::CiAgICB3aXRoIFlUX0RMUC5Zb3V0dWJlREwobykgYXMgeWRsOgogICAgICAgIGlu
:::Zm8gPSB5ZGwuZXh0cmFjdF9pbmZvKHVybCwgZG93bmxvYWQ9VHJ1ZSkKICAgIHdh
:::diA9IGFyY2hpdm9fZmluYWwoaW5mbywgdG1wLCAnd2F2JykKICAgIGlmIG5vdCB3
:::YXY6CiAgICAgICAgcmFpc2UgUnVudGltZUVycm9yKCdObyBzZSBlbmNvbnRyw7Mg
:::ZWwgV0FWIGludGVybWVkaW8uJykKICAgIG1ldGEgPSBbXQogICAgaWYgZW1iZWJl
:::cjoKICAgICAgICBhcnRpc3RhID0gKGluZm8uZ2V0KCdhcnRpc3QnKSBvciBpbmZv
:::LmdldCgndXBsb2FkZXInKQogICAgICAgICAgICAgICAgICAgb3IgaW5mby5nZXQo
:::J2NoYW5uZWwnKSBvciAnJykKICAgICAgICBpZiBpbmZvLmdldCgndGl0bGUnKToK
:::ICAgICAgICAgICAgbWV0YSArPSBbJy1tZXRhZGF0YScsICd0aXRsZT0nICsgc3Ry
:::KGluZm9bJ3RpdGxlJ10pXQogICAgICAgIGlmIGFydGlzdGE6CiAgICAgICAgICAg
:::IG1ldGEgKz0gWyctbWV0YWRhdGEnLCAnYXJ0aXN0PScgKyBzdHIoYXJ0aXN0YSld
:::CiAgICB3bWEgPSBjYXJwZXRhIC8gKGxpbXBpYXJfbm9tYnJlKGluZm8uZ2V0KCd0
:::aXRsZScpIG9yICdhdWRpbycpICsgJy53bWEnKQogICAgY21kID0gW3N0cihGRk1Q
:::RUcpLCAnLXknLCAnLWknLCBzdHIod2F2KSwgJy12bicsCiAgICAgICAgICAgJy1j
:::OmEnLCAnd21hdjInLCAnLWI6YScsIGYne2NhbGlkYWR9ayddICsgbWV0YSArIFtz
:::dHIod21hKV0KICAgIG9rID0gY29udmVydGlyX2ZmbXBlZygKICAgICAgICBjbWQs
:::IGYnQ29udmlydGllbmRvIGEgV01BICh3bWF2MiDCtyB7Y2FsaWRhZH0ga2Jwcykn
:::LCBjb2xhKQogICAgaWYgbm90IG9rOgogICAgICAgIHJhaXNlIFJ1bnRpbWVFcnJv
:::cignRkZtcGVnIG5vIHB1ZG8gY3JlYXIgZWwgYXJjaGl2byBXTUEuJykKICAgIGNh
:::cmF0dWxhID0gTm9uZQogICAgaWYgZW1iZWJlcjoKICAgICAgICBqcGdzID0gc29y
:::dGVkKHRtcC5nbG9iKCcqLmpwZycpLAogICAgICAgICAgICAgICAgICAgICAga2V5
:::PWxhbWJkYSBxOiBxLnN0YXQoKS5zdF9tdGltZSwgcmV2ZXJzZT1UcnVlKQogICAg
:::ICAgIGlmIGpwZ3M6CiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIGNh
:::cmF0dWxhID0ganBnc1swXS5yZWFkX2J5dGVzKCkKICAgICAgICAgICAgZXhjZXB0
:::IE9TRXJyb3I6CiAgICAgICAgICAgICAgICBjYXJhdHVsYSA9IE5vbmUKICAgIGFw
:::bGljYXJfdGFncyhpbmZvLCB3bWEsIGxvZywgY2FyYXR1bGEpCiAgICBzaHV0aWwu
:::cm10cmVlKHRtcCwgaWdub3JlX2Vycm9ycz1UcnVlKQogICAgcmV0dXJuIGluZm8s
:::IHdtYQoKCmRlZiBtZXRhX3JpZmZfaW5mbyhpbmZvKToKICAgICIiInYyLjc6IGFy
:::Z3VtZW50b3MgLW1ldGFkYXRhIHBhcmEgbG9zIHRhZ3MgUklGRiBJTkZPIGRlbCBB
:::VkkuCgogICAgRkZtcGVnIGxvcyBtYXBlYSBhIElOQU0gKHRpdHVsbyksIElBUlQg
:::KGFydGlzdGEpLCBJUFJEIChhbGJ1bSksCiAgICBJQ1JEIChmZWNoYSkgZSBJQ01U
:::IChjb21lbnRhcmlvKSBkZW50cm8gZGVsIGNodW5rIExJU1QvSU5GTyBkZWwKICAg
:::IFJJRkYsIHF1ZSBlcyBkb25kZSBsb3MgcmVwcm9kdWN0b3JlcyBidXNjYW4gbG9z
:::IGRhdG9zIGRlIHVuIEFWSS4iIiIKICAgIHRpdHVsbyA9IHN0cihpbmZvLmdldCgn
:::dHJhY2snKSBvciBpbmZvLmdldCgndGl0bGUnKSBvciAnJykuc3RyaXAoKQogICAg
:::YXJ0aXN0YSA9IF9hcnRpc3RhX2xpbXBpbyhpbmZvKQogICAgYWxidW0gPSBfYWxi
:::dW1fZGUoaW5mbykKICAgIGZlY2hhID0gc3RyKGluZm8uZ2V0KCdyZWxlYXNlX3ll
:::YXInKSBvciAnJykKICAgIGlmIG5vdCBmZWNoYToKICAgICAgICBmZWNoYSA9IHN0
:::cihpbmZvLmdldCgndXBsb2FkX2RhdGUnKSBvciAnJylbOjRdCiAgICB1cmwgPSBz
:::dHIoaW5mby5nZXQoJ3dlYnBhZ2VfdXJsJykgb3IgJycpLnN0cmlwKCkKICAgIG1l
:::dGEgPSBbXQogICAgaWYgdGl0dWxvOgogICAgICAgIG1ldGEgKz0gWyctbWV0YWRh
:::dGEnLCAndGl0bGU9JyArIHRpdHVsb10KICAgIGlmIGFydGlzdGE6CiAgICAgICAg
:::bWV0YSArPSBbJy1tZXRhZGF0YScsICdhcnRpc3Q9JyArIGFydGlzdGFdCiAgICBp
:::ZiBhbGJ1bToKICAgICAgICBtZXRhICs9IFsnLW1ldGFkYXRhJywgJ2FsYnVtPScg
:::KyBhbGJ1bV0KICAgIGlmIGZlY2hhOgogICAgICAgIG1ldGEgKz0gWyctbWV0YWRh
:::dGEnLCAnZGF0ZT0nICsgZmVjaGFdCiAgICBpZiB1cmw6CiAgICAgICAgbWV0YSAr
:::PSBbJy1tZXRhZGF0YScsICdjb21tZW50PScgKyB1cmxdCiAgICByZXR1cm4gbWV0
:::YQoKCiMgUGFyw6FtZXRyb3Mgb2ZpY2lhbGVzIGRlbCByZXBvIGZkZDRzL3BvcnRh
:::YmxlX21wM19wbGF5ZXJfdmlkZW9fY29udmVydGVyX3Rvb2xzCiMgKHZpZGVvMnNo
:::ZW5qdTE4LnNoKTogTUpQRUcgMTYgZnBzICsgUENNIDIyMDUwIEh6LCByb3RhZG9z
:::IHBhcmEgbGEgcGFudGFsbGEKIyB2ZXJ0aWNhbCBkZSAxMjh4MTYwIGRlbCByZXBy
:::b2R1Y3RvciBzaGVpanUgZGUgMS44IHB1bGdhZGFzLgpWRl9TSEVJSlUgPSAnc2Nh
:::bGU9LTI6MTI4LCBjcm9wPTE2MDoxMjgsIHRyYW5zcG9zZT0yLCB2ZmxpcCcKIyBW
:::YXJpYW50ZSBhIHBydWViYSBkZSBiYWxhcyBwYXJhIHZpZGVvcyBjdWFkcmFkb3Mv
:::dmVydGljYWxlcyAoU2hvcnRzKSwKIyBkb25kZSBlbCByZWNvcnRlIDE2MDoxMjgg
:::b3JpZ2luYWwgc2Vyw61hIGltcG9zaWJsZToKVkZfU0VHVVJPID0gKCdzY2FsZT0x
:::NjA6MTI4OmZvcmNlX29yaWdpbmFsX2FzcGVjdF9yYXRpbz1kZWNyZWFzZSwnCiAg
:::ICAgICAgICAgICAncGFkPTE2MDoxMjg6KG93LWl3KS8yOihvaC1paCkvMix0cmFu
:::c3Bvc2U9Mix2ZmxpcCcpCgoKZGVmIGRlc2Nhcmdhcl9hdmkodXJsLCBkZXN0aW5v
:::LCBjb2xhKToKICAgICIiIlZpZGVvIEFWSSBwYXJhIGVsIHJlcHJvZHVjdG9yIHNo
:::ZWlqdSAxLjgiIDEyOHgxNjAuIiIiCiAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToK
:::ICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgIGNhcnBldGEgPSBk
:::ZXN0aW5vICAgICAgICAgICMgdjIuMzogc2luIHN1YmNhcnBldGFzIHBvciBmb3Jt
:::YXRvCiAgICB0bXAgPSBjYXJwZXRhIC8gJ190bXAnCiAgICBzaHV0aWwucm10cmVl
:::KHRtcCwgaWdub3JlX2Vycm9ycz1UcnVlKQogICAgdG1wLm1rZGlyKHBhcmVudHM9
:::VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgIG8gPSBvcHRzX2Jhc2UodG1wLCBjb2xh
:::KQogICAgIyBQYXJhIHVuYSBwYW50YWxsYSBkZSAxMjh4MTYwIGJhc3RhIGNvbiA0
:::ODBwOiBhaG9ycmEgbXVjaGEgZGVzY2FyZ2EuCiAgICBvWydmb3JtYXQnXSA9ICgn
:::YmVzdFtoZWlnaHQ8PTQ4MF1bZXh0PW1wNF0vYmVzdFtoZWlnaHQ8PTQ4MF0vJwog
:::ICAgICAgICAgICAgICAgICAgJ2J2KltoZWlnaHQ8PTQ4MF0rYmEvYicpCiAgICBv
:::WydtZXJnZV9vdXRwdXRfZm9ybWF0J10gPSAnbXA0JwogICAgd2l0aCBZVF9ETFAu
:::WW91dHViZURMKG8pIGFzIHlkbDoKICAgICAgICBpbmZvID0geWRsLmV4dHJhY3Rf
:::aW5mbyh1cmwsIGRvd25sb2FkPVRydWUpCiAgICBvcmlnZW4gPSBhcmNoaXZvX2Zp
:::bmFsKGluZm8sIHRtcCwgJ21wNCcpCiAgICBpZiBub3Qgb3JpZ2VuOgogICAgICAg
:::IG9yaWdlbiA9IChhcmNoaXZvX2ZpbmFsKGluZm8sIHRtcCwgJ21rdicpCiAgICAg
:::ICAgICAgICAgICAgIG9yIGFyY2hpdm9fZmluYWwoaW5mbywgdG1wLCAnd2VibScp
:::KQogICAgaWYgbm90IG9yaWdlbjoKICAgICAgICByYWlzZSBSdW50aW1lRXJyb3Io
:::J05vIHNlIGVuY29udHLDsyBlbCB2aWRlbyBkZXNjYXJnYWRvLicpCiAgICBhdmkg
:::PSBjYXJwZXRhIC8gKGxpbXBpYXJfbm9tYnJlKGluZm8uZ2V0KCd0aXRsZScpIG9y
:::ICd2aWRlbycpICsgJy5hdmknKQogICAgIyB2Mi43OiBldGlxdWV0YXMgUklGRiBJ
:::TkZPIGRlbnRybyBkZWwgQVZJICh2ZXIgbWV0YV9yaWZmX2luZm8pCiAgICAjIHBh
:::cmEgcXVlIGVsIHZpZGVvIHRhbWJpZW4gbXVlc3RyZSB0aXR1bG8geSBhcnRpc3Rh
:::IGRvbmRlIGVsCiAgICAjIHJlcHJvZHVjdG9yIHNlcGEgbGVlcmxhcy4KICAgIG1l
:::dGEgPSBtZXRhX3JpZmZfaW5mbyhpbmZvKQogICAgYmFzZSA9IFtzdHIoRkZNUEVH
:::KSwgJy15JywgJy1pJywgc3RyKG9yaWdlbiksICctcicsICcxNicsCiAgICAgICAg
:::ICAgICctYWNvZGVjJywgJ3BjbV9zMTZsZScsICctYWMnLCAnMicsICctYXInLCAn
:::MjIwNTAnLAogICAgICAgICAgICAnLXBpeF9mbXQnLCAneXV2ajQyMHAnLCAnLWM6
:::dicsICdtanBlZycsICctcTp2JywgJzInXSArIG1ldGEKICAgIG9rID0gY29udmVy
:::dGlyX2ZmbXBlZyhiYXNlICsgWyctdmYnLCBWRl9TSEVJSlUsIHN0cihhdmkpXSwK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAnQ29udmlydGllbmRvIGEgQVZJIDEy
:::OHgxNjAgKHNoZWlqdSAxLjgiKScsIGNvbGEpCiAgICBpZiBub3Qgb2s6CiAgICAg
:::ICAgbG9nKCdWaWRlbyBjb24gcHJvcG9yY2nDs24gbm8gZXN0w6FuZGFyOyAnCiAg
:::ICAgICAgICAgICdyZWludGVudGFuZG8gZW4gbW9kbyBjb21wYXRpYmxlLi4uJywg
:::J2F2aXNvJykKICAgICAgICBvayA9IGNvbnZlcnRpcl9mZm1wZWcoYmFzZSArIFsn
:::LXZmJywgVkZfU0VHVVJPLCBzdHIoYXZpKV0sCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICdSZWNvbnZpcnRpZW5kbyBhIEFWSSAxMjh4MTYwJywgY29sYSkK
:::ICAgIGlmIG5vdCBvazoKICAgICAgICByYWlzZSBSdW50aW1lRXJyb3IoJ0ZGbXBl
:::ZyBubyBwdWRvIGNyZWFyIGVsIGFyY2hpdm8gQVZJLicpCiAgICBzaHV0aWwucm10
:::cmVlKHRtcCwgaWdub3JlX2Vycm9ycz1UcnVlKQogICAgcmV0dXJuIGluZm8sIGF2
:::aQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBlc3RpbWFjacOzbgpLQlBTX0VTVElNQURP
:::UyA9IHsKICAgICdBQUMnOiAxMjgsICAgICAjIHRlY2hvIGRlbCBmb3JtYXRvCiAg
:::ICAnV01BJzogMTI4LAogICAgJ1dBVic6IDE0MTEsICAgICMgUENNIDQ0LjEga0h6
:::IMK3IDE2IGJpdCDCtyBlc3TDqXJlbwogICAgJ0ZMQUMnOiA5NTAsICAgICMgdMOt
:::cGljbyBkZSBtw7pzaWNhIHByb2NlZGVudGUgZGUgWW91VHViZQogICAgJ0FWSSc6
:::IDE0OTAsICAgICMgfjc4NCBrYnBzIE1KUEVHIDE2ZnBzICsgNzA2IGticHMgUENN
:::IDIyMDUwIGVzdMOpcmVvCn0KCgpkZWYgZXN0aW1hcl9ieXRlcyhkdXJhY2lvbl9z
:::LCBmb3JtYXRvLCBjYWxpZGFkLCBlbWJlYmVyKToKICAgICIiIkVzdGltYSBlbCB0
:::YW1hw7FvIGZpbmFsIGVuIGJ5dGVzIChjw6FsY3VsbyBwdXJvLCB0ZXN0ZWFibGUp
:::LiIiIgogICAgaWYgZm9ybWF0byBpbiAoJ01QMycsICdBQUMnLCAnV01BJyk6CiAg
:::ICAgICAga2JwcyA9IGludChyZS5zdWIocidbXjAtOV0nLCAnJywgc3RyKGNhbGlk
:::YWQpKSBvciAwKQogICAgICAgIGlmIG5vdCBrYnBzOgogICAgICAgICAgICBrYnBz
:::ID0gS0JQU19FU1RJTUFET1MuZ2V0KGZvcm1hdG8sIDEyOCkKICAgIGVsc2U6CiAg
:::ICAgICAga2JwcyA9IEtCUFNfRVNUSU1BRE9TLmdldChmb3JtYXRvLCAxMjgpCiAg
:::ICBleHRyYSA9IDEyMF8wMDAgaWYgKGVtYmViZXIgYW5kIGZvcm1hdG8gaW4gKCdB
:::QUMnLCAnTVAzJywgJ0ZMQUMnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAnV0FWJykpIGVsc2UgMAogICAgcmV0dXJuIGR1
:::cmFjaW9uX3MgKiBrYnBzICogMTAwMCAvIDggKyBleHRyYQoKCiMgLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLSBjYWxpZGFkCmRlZiBjbGFzZV9jYWxpZGFkKGV4dCwga2Jwcyk6CiAg
:::ICAiIiJDbGFzaWZpY2EgdW4gYXJjaGl2by4gRGV2dWVsdmUgKHRleHRvLCBuaXZl
:::bCkgY29uIG5pdmVsIDA9b2sgMT1tZWRpYSAyPWJhamEuIiIiCiAgICBpZiBleHQg
:::PT0gJy5tcDMnOgogICAgICAgIGlmIGticHMgPj0gMzE1OgogICAgICAgICAgICBy
:::ZXR1cm4gJzMyMCBrYnBzJywgMAogICAgICAgIGlmIGticHMgPj0gMjUwOgogICAg
:::ICAgICAgICByZXR1cm4gJzI1NiBrYnBzJywgMAogICAgICAgIGlmIGticHMgPj0g
:::MTg1OgogICAgICAgICAgICByZXR1cm4gJzE5MiBrYnBzJywgMAogICAgICAgIGlm
:::IGticHMgPj0gMTIwOgogICAgICAgICAgICByZXR1cm4gJzEyOCBrYnBzJywgMQog
:::ICAgICAgIHJldHVybiBmJ3trYnBzfSBrYnBzIChiYWphKScsIDIKICAgIGlmIGV4
:::dCA9PSAnLm00YSc6CiAgICAgICAgaWYga2JwcyA+PSAxMTU6CiAgICAgICAgICAg
:::IHJldHVybiAnRXhjZWxlbnRlIChBQUMg4omkMTI4ayknLCAwCiAgICAgICAgaWYg
:::a2JwcyA+PSA4MjoKICAgICAgICAgICAgcmV0dXJuICc5NiBrYnBzJywgMQogICAg
:::ICAgIHJldHVybiBmJ3trYnBzfSBrYnBzIChiYWphKScsIDIKICAgIGlmIGV4dCA9
:::PSAnLndtYSc6CiAgICAgICAgaWYga2JwcyA+PSAxMTU6CiAgICAgICAgICAgIHJl
:::dHVybiAnMTI4IGticHMnLCAwCiAgICAgICAgaWYga2JwcyA+PSA4ODoKICAgICAg
:::ICAgICAgcmV0dXJuICc5NiBrYnBzJywgMQogICAgICAgIHJldHVybiBmJ3trYnBz
:::fSBrYnBzIChiYWphKScsIDIKICAgIGlmIGV4dCBpbiAoJy5mbGFjJywgJy53YXYn
:::KToKICAgICAgICByZXR1cm4gJ1NpbiBww6lyZGlkYScsIDAKICAgIGlmIGV4dCA9
:::PSAnLmF2aSc6CiAgICAgICAgaWYga2JwcyA+PSAxMjAwOgogICAgICAgICAgICBy
:::ZXR1cm4gZid7a2Jwc30ga2JwcyAoTUpQRUcrUENNIDEyOHgxNjApJywgMAogICAg
:::ICAgIHJldHVybiBmJ3trYnBzfSBrYnBzIChhbGdvIGJham8pJywgMQogICAgcmV0
:::dXJuIGYne2ticHN9IGticHMnLCAxCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIHRlbWFz
:::ClRFTUFTID0gewogICAgJ09zY3Vybyc6IGRpY3QoCiAgICAgICAgZm9uZG89JyMx
:::ZTFmMjInLCBjYW1wbz0nIzJhMmQzMScsIGNhbXBvX2JvcmRlPScjM2EzZTQ0JywK
:::ICAgICAgICB0ZXh0bz0nI2Q4ZGFkYycsIHRleHRvMj0nIzlhOWZhNCcsCiAgICAg
:::ICAgYm90b249JyMzYTNkNDInLCBib3Rvbl9hY3Q9JyM0YTRlNTUnLCBib3Rvbl90
:::eHQ9JyNlOGVhZWMnLAogICAgICAgIGxvZz0nIzE0MTUxOCcsIGxvZ190eHQ9JyNj
:::ZmQzZDcnLCBhY2VudG89JyM0ZjljZjknLAogICAgICAgIG9rPScjN2VjOTdmJywg
:::ZXJyb3I9JyNlNTczNzMnLCBhdmlzbz0nI2Q4YjY0YScsIHRyb3VnaD0nIzI2Mjgy
:::YycsCiAgICAgICAgcGxhY2Vob2xkZXI9JyM3NzdjODInKSwKICAgICdDbGFybyc6
:::IGRpY3QoCiAgICAgICAgZm9uZG89JyNmMmYzZjUnLCBjYW1wbz0nI2ZmZmZmZics
:::IGNhbXBvX2JvcmRlPScjYzRjOGNkJywKICAgICAgICB0ZXh0bz0nIzI0MjcyYScs
:::IHRleHRvMj0nIzZhNzA3NicsCiAgICAgICAgYm90b249JyNlM2U1ZTgnLCBib3Rv
:::bl9hY3Q9JyNkMmQ1ZGEnLCBib3Rvbl90eHQ9JyMyNDI3MmEnLAogICAgICAgIGxv
:::Zz0nI2ZmZmZmZicsIGxvZ190eHQ9JyMyYjJlMzEnLCBhY2VudG89JyMxYTY2ZDYn
:::LAogICAgICAgIG9rPScjMWU3ZTM0JywgZXJyb3I9JyNjNjI4MjgnLCBhdmlzbz0n
:::IzlhNjcwMCcsIHRyb3VnaD0nI2RmZTFlNCcsCiAgICAgICAgcGxhY2Vob2xkZXI9
:::JyM5YWEwYTYnKSwKfQoKUExBQ0VIT0xERVJfVVJMID0gJ2h0dHBzOi8vd3d3Lnlv
:::dXR1YmUuY29tL3dhdGNoP3Y9Li4uJwoKRlVFTlRFX1VJID0gKCdTZWdvZSBVSScs
:::IDkpCkZVRU5URV9CVE4gPSAoJ1NlZ29lIFVJJywgMTApCkZVRU5URV9CVE5fRyA9
:::ICgnU2Vnb2UgVUknLCAxMSkKRlVFTlRFX0xPRyA9ICgnQ29uc29sYXMnLCAxMCkK
:::CgppZiBUS19PSzoKCiAgICBjbGFzcyBBcHAodGsuVGspOgogICAgICAgICIiIlZl
:::bnRhbmEgcHJpbmNpcGFsIChkaXNlw7FvIGVzcGVqbyBkZWwgbW9ja3VwOiBncnVw
:::b3Mgb3NjdXJvcykuIiIiCgogICAgICAgICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGNvbnN0cnVjY2nDs24KICAgICAg
:::ICBkZWYgX19pbml0X18oc2VsZik6CiAgICAgICAgICAgIGlmIGdldGF0dHIoc3lz
:::LCAnZnJvemVuJywgRmFsc2UpOgogICAgICAgICAgICAgICAgcGFzcwogICAgICAg
:::ICAgICBzdXBlcigpLl9faW5pdF9fKCkKICAgICAgICAgICAgc2VsZi50aXRsZSgn
:::TXVzaWtBTEFOJykKICAgICAgICAgICAgc2VsZi5nZW9tZXRyeSgnODYweDg0MCcp
:::CiAgICAgICAgICAgIHNlbGYubWluc2l6ZSg3MDAsIDY2MCkKICAgICAgICAgICAg
:::c2VsZi5jb2xhID0gcXVldWUuUXVldWUoKQogICAgICAgICAgICBzZWxmLl9vY3Vw
:::YWRvID0gRmFsc2UKICAgICAgICAgICAgc2VsZi5fZW5fcGxhY2Vob2xkZXIgPSBU
:::cnVlCiAgICAgICAgICAgIHNlbGYuX3RlbWFfYWN0dWFsID0gQUpVU1RFUy5nZXQo
:::J3RlbWEnLCAnT3NjdXJvJykKICAgICAgICAgICAgaWYgc2VsZi5fdGVtYV9hY3R1
:::YWwgbm90IGluIFRFTUFTOgogICAgICAgICAgICAgICAgc2VsZi5fdGVtYV9hY3R1
:::YWwgPSAnT3NjdXJvJwoKICAgICAgICAgICAgc2VsZi5fZXN0aWxvID0gdHRrLlN0
:::eWxlKHNlbGYpCiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHNlbGYu
:::X2VzdGlsby50aGVtZV91c2UoJ2NsYW0nKQogICAgICAgICAgICBleGNlcHQgRXhj
:::ZXB0aW9uOgogICAgICAgICAgICAgICAgcGFzcwoKICAgICAgICAgICAgc2VsZi5f
:::Y29uc3RydWlyKCkKICAgICAgICAgICAgc2VsZi5fYXBsaWNhcl90ZW1hKCkKICAg
:::ICAgICAgICAgc2VsZi5fY29uZWN0YXJfZXZlbnRvcygpCiAgICAgICAgICAgIFJF
:::R0lTVFJPLmxvZyA9IGxhbWJkYSBtLCB0PSdhdmlzbyc6IHNlbGYuY29sYS5wdXQo
:::KCdsb2cnLCBtLCB0KSkKICAgICAgICAgICAgc2VsZi5hZnRlcig4MCwgc2VsZi5f
:::Ym9tYmVhcl9jb2xhKQogICAgICAgICAgICBzZWxmLmFmdGVyKDE1MCwgc2VsZi5f
:::YXJyYW5xdWUpCgogICAgICAgIGRlZiBfY29uc3RydWlyKHNlbGYpOgogICAgICAg
:::ICAgICBzZWxmLl93ZyA9IHt9ICAgICAgICAgIyByZWZlcmVuY2lhcyBwYXJhIGVs
:::IHRlbWEKICAgICAgICAgICAgc2VsZi5fYnRucyA9IFtdICAgICAgICMgYm90b25l
:::cyBwbGFub3MgKHBhcmEgaG92ZXIvdGVtYSkKICAgICAgICAgICAgbWFyY28gPSB0
:::ay5GcmFtZShzZWxmKQogICAgICAgICAgICBtYXJjby5wYWNrKGZpbGw9J2JvdGgn
:::LCBleHBhbmQ9VHJ1ZSwgcGFkeD0xMCwgcGFkeT04KQogICAgICAgICAgICBzZWxm
:::Ll93Z1snbWFyY28nXSA9IG1hcmNvCiAgICAgICAgICAgIG1hcmNvLmNvbHVtbmNv
:::bmZpZ3VyZSgwLCB3ZWlnaHQ9MSkKCiAgICAgICAgICAgICMgLS0tIGZpbGEgVGVt
:::YSAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0KICAgICAgICAgICAgZjAgPSB0ay5GcmFtZShtYXJjbykKICAgICAgICAgICAg
:::ZjAuZ3JpZChyb3c9MCwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PSgwLCA2
:::KSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2YwJ10gPSBmMAogICAgICAgICAgICBz
:::ZWxmLl93Z1snbGJsX3RlbWEnXSA9IHRrLkxhYmVsKGYwLCB0ZXh0PSdUZW1hOics
:::IGZvbnQ9RlVFTlRFX1VJKQogICAgICAgICAgICBzZWxmLl93Z1snbGJsX3RlbWEn
:::XS5wYWNrKHNpZGU9J2xlZnQnKQogICAgICAgICAgICBzZWxmLmNtYl90ZW1hID0g
:::dHRrLkNvbWJvYm94KAogICAgICAgICAgICAgICAgZjAsIHZhbHVlcz1saXN0KFRF
:::TUFTKSwgc3RhdGU9J3JlYWRvbmx5Jywgd2lkdGg9OSwKICAgICAgICAgICAgICAg
:::IGZvbnQ9RlVFTlRFX1VJLCBzdHlsZT0nZ3guVENvbWJvYm94JykKICAgICAgICAg
:::ICAgc2VsZi5jbWJfdGVtYS5zZXQoc2VsZi5fdGVtYV9hY3R1YWwpCiAgICAgICAg
:::ICAgIHNlbGYuY21iX3RlbWEucGFjayhzaWRlPSdsZWZ0JywgcGFkeD0oOCwgMCks
:::IGlwYWR5PTIpCgogICAgICAgICAgICAjIC0tLSBncnVwbzogVVJMIGRlIFlvdVR1
:::YmUgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAg
:::ICAgIGd1ID0gdGsuTGFiZWxGcmFtZShtYXJjbywgdGV4dD0nVVJMIGRlIFlvdVR1
:::YmUnLCBmb250PUZVRU5URV9VSSwKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIHJlbGllZj0nc29saWQnLCBiZD0xKQogICAgICAgICAgICBndS5ncmlkKHJv
:::dz0xLCBjb2x1bW49MCwgc3RpY2t5PSdldycsIHBhZHk9NSkKICAgICAgICAgICAg
:::c2VsZi5fd2dbJ2d1J10gPSBndQogICAgICAgICAgICBndS5jb2x1bW5jb25maWd1
:::cmUoMCwgd2VpZ2h0PTEpCiAgICAgICAgICAgIHNlbGYuZW50X3VybCA9IHRrLkVu
:::dHJ5KGd1LCBmb250PUZVRU5URV9VSSwgcmVsaWVmPSdmbGF0JywKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgaGlnaGxpZ2h0dGhpY2tuZXNzPTEp
:::CiAgICAgICAgICAgIHNlbGYuZW50X3VybC5ncmlkKHJvdz0wLCBjb2x1bW49MCwg
:::c3RpY2t5PSdldycsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhZHg9
:::OCwgcGFkeT04LCBpcGFkeT01KQogICAgICAgICAgICBzZWxmLl9wb25lcl9wbGFj
:::ZWhvbGRlcigpCiAgICAgICAgICAgIHNlbGYuYnRuX3ggPSBzZWxmLl9ib3Rvbihn
:::dSwgJ1gnLCBzZWxmLl9saW1waWFyX3VybCwgd2lkdGg9MykKICAgICAgICAgICAg
:::c2VsZi5idG5feC5ncmlkKHJvdz0wLCBjb2x1bW49MSwgc3RpY2t5PSdlJywgcGFk
:::eD0oMCwgOCksIGlwYWR5PTMpCgogICAgICAgICAgICAjIC0tLSBncnVwbzogRm9y
:::bWF0byB5IGNhbGlkYWQgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::CiAgICAgICAgICAgIGdmID0gdGsuTGFiZWxGcmFtZShtYXJjbywgdGV4dD0nRm9y
:::bWF0byB5IGNhbGlkYWQnLCBmb250PUZVRU5URV9VSSwKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgIHJlbGllZj0nc29saWQnLCBiZD0xKQogICAgICAgICAg
:::ICBnZi5ncmlkKHJvdz0yLCBjb2x1bW49MCwgc3RpY2t5PSdldycsIHBhZHk9NSkK
:::ICAgICAgICAgICAgc2VsZi5fd2dbJ2dmJ10gPSBnZgogICAgICAgICAgICBnZi5j
:::b2x1bW5jb25maWd1cmUoMSwgd2VpZ2h0PTEpCiAgICAgICAgICAgIHNlbGYuX3dn
:::WydsYmxfZm10J10gPSB0ay5MYWJlbChnZiwgdGV4dD0nRm9ybWF0bzonLCBmb250
:::PUZVRU5URV9VSSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF9mbXQnXS5ncmlk
:::KHJvdz0wLCBjb2x1bW49MCwgc3RpY2t5PSd3JywgcGFkeD04LCBwYWR5PTUpCiAg
:::ICAgICAgICAgIHNlbGYuY21iX2Zvcm1hdG8gPSB0dGsuQ29tYm9ib3goCiAgICAg
:::ICAgICAgICAgICBnZiwgdmFsdWVzPVtmWyd0ZXh0byddIGZvciBmIGluIEZPUk1B
:::VE9TLnZhbHVlcygpXSwKICAgICAgICAgICAgICAgIHN0YXRlPSdyZWFkb25seScs
:::IGZvbnQ9RlVFTlRFX1VJLCBzdHlsZT0nZ3guVENvbWJvYm94JykKICAgICAgICAg
:::ICAgc2VsZi5jbWJfZm9ybWF0by5ncmlkKHJvdz0wLCBjb2x1bW49MSwgc3RpY2t5
:::PSdldycsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4PTgs
:::IHBhZHk9NSwgaXBhZHk9MikKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF9jYWwn
:::XSA9IHRrLkxhYmVsKGdmLCB0ZXh0PSdDYWxpZGFkOicsIGZvbnQ9RlVFTlRFX1VJ
:::KQogICAgICAgICAgICBzZWxmLl93Z1snbGJsX2NhbCddLmdyaWQocm93PTEsIGNv
:::bHVtbj0wLCBzdGlja3k9J3cnLCBwYWR4PTgsIHBhZHk9NSkKICAgICAgICAgICAg
:::c2VsZi5jbWJfY2FsaWRhZCA9IHR0ay5Db21ib2JveCgKICAgICAgICAgICAgICAg
:::IGdmLCBzdGF0ZT0ncmVhZG9ubHknLCBmb250PUZVRU5URV9VSSwgc3R5bGU9J2d4
:::LlRDb21ib2JveCcpCiAgICAgICAgICAgIHNlbGYuY21iX2NhbGlkYWQuZ3JpZChy
:::b3c9MSwgY29sdW1uPTEsIHN0aWNreT0nZXcnLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgcGFkeD04LCBwYWR5PTUsIGlwYWR5PTIpCiAgICAgICAg
:::ICAgIHNlbGYuX3dnWydsYmxfY2FyJ10gPSB0ay5MYWJlbChnZiwgdGV4dD0nQ2Fy
:::cGV0YTonLCBmb250PUZVRU5URV9VSSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2xi
:::bF9jYXInXS5ncmlkKHJvdz0yLCBjb2x1bW49MCwgc3RpY2t5PSd3JywgcGFkeD04
:::LCBwYWR5PTUpCiAgICAgICAgICAgIGZjID0gdGsuRnJhbWUoZ2YpCiAgICAgICAg
:::ICAgIGZjLmdyaWQocm93PTIsIGNvbHVtbj0xLCBzdGlja3k9J2V3JywgcGFkeD04
:::LCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYuX3dnWydmYyddID0gZmMKICAgICAg
:::ICAgICAgZmMuY29sdW1uY29uZmlndXJlKDAsIHdlaWdodD0xKQogICAgICAgICAg
:::ICBzZWxmLmVudF9jYXJwZXRhID0gdGsuRW50cnkoZmMsIGZvbnQ9RlVFTlRFX1VJ
:::LCByZWxpZWY9J2ZsYXQnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgaGlnaGxpZ2h0dGhpY2tuZXNzPTEpCiAgICAgICAgICAgIHNlbGYu
:::ZW50X2NhcnBldGEuZ3JpZChyb3c9MCwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBp
:::cGFkeT00KQogICAgICAgICAgICBzZWxmLmVudF9jYXJwZXRhLmluc2VydCgwLCBB
:::SlVTVEVTWydkZXN0aW5vJ10pCiAgICAgICAgICAgIHNlbGYuYnRuX2NhbWJpYXIg
:::PSBzZWxmLl9ib3RvbihmYywgJ0NhbWJpYXIuLi4nLCBzZWxmLl9jYW1iaWFyX2Nh
:::cnBldGEpCiAgICAgICAgICAgIHNlbGYuYnRuX2NhbWJpYXIuZ3JpZChyb3c9MCwg
:::Y29sdW1uPTEsIHBhZHg9KDgsIDApLCBpcGFkeT0zKQogICAgICAgICAgICBzZWxm
:::LmJ0bl9hYnJpciA9IHNlbGYuX2JvdG9uKGZjLCAnQWJyaXInLCBzZWxmLl9hYnJp
:::cl9kZXN0aW5vLCB3aWR0aD01KQogICAgICAgICAgICBzZWxmLmJ0bl9hYnJpci5n
:::cmlkKHJvdz0wLCBjb2x1bW49MiwgcGFkeD0oNiwgMCksIGlwYWR5PTMpCgogICAg
:::ICAgICAgICBzZWxmLnZhcl9lbWJlYmVyID0gdGsuQm9vbGVhblZhcih2YWx1ZT1i
:::b29sKEFKVVNURVMuZ2V0KCdlbWJlYmVyJywgVHJ1ZSkpKQogICAgICAgICAgICBz
:::ZWxmLmNoa19lbWJlYmVyID0gdGsuQ2hlY2tidXR0b24oCiAgICAgICAgICAgICAg
:::ICBnZiwgdGV4dD0nRW1iZWJlciBjYXLDoXR1bGEsIGFydGlzdGEgeSDDoWxidW0n
:::LAogICAgICAgICAgICAgICAgdmFyaWFibGU9c2VsZi52YXJfZW1iZWJlciwgZm9u
:::dD1GVUVOVEVfVUksIGFuY2hvcj0ndycsCiAgICAgICAgICAgICAgICByZWxpZWY9
:::J2ZsYXQnLCBoaWdobGlnaHR0aGlja25lc3M9MCwgYmQ9MCkKICAgICAgICAgICAg
:::c2VsZi5jaGtfZW1iZWJlci5ncmlkKHJvdz0zLCBjb2x1bW49MCwgY29sdW1uc3Bh
:::bj0yLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgc3RpY2t5PSdl
:::dycsIHBhZHg9OCwgcGFkeT0oMiwgNikpCgogICAgICAgICAgICAjIC0tLSBncnVw
:::bzogZXN0aW1hY2nDs24gLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLQogICAgICAgICAgICBnZSA9IHRrLkxhYmVsRnJhbWUobWFyY28sIHRl
:::eHQ9J0VzdGltYWNpw7NuJywgZm9udD1GVUVOVEVfVUksCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICByZWxpZWY9J3NvbGlkJywgYmQ9MSkKICAgICAgICAg
:::ICAgZ2UuZ3JpZChyb3c9MywgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PTUp
:::CiAgICAgICAgICAgIHNlbGYuX3dnWydnZSddID0gZ2UKICAgICAgICAgICAgZ2Uu
:::Y29sdW1uY29uZmlndXJlKDAsIHdlaWdodD0xKQogICAgICAgICAgICBzZWxmLmxi
:::bF9lc3RpbWFjaW9uID0gdGsuTGFiZWwoCiAgICAgICAgICAgICAgICBnZSwgdGV4
:::dD0nSW50cm9kdWNlIHVuYSBVUkwgeSBwdWxzYSBFc3RpbWFyLicsCiAgICAgICAg
:::ICAgICAgICBmb250PUZVRU5URV9VSSwgYW5jaG9yPSd3JykKICAgICAgICAgICAg
:::c2VsZi5sYmxfZXN0aW1hY2lvbi5ncmlkKHJvdz0wLCBjb2x1bW49MCwgc3RpY2t5
:::PSdldycsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4
:::PTgsIHBhZHk9NikKICAgICAgICAgICAgc2VsZi5idG5fZXN0aW1hciA9IHNlbGYu
:::X2JvdG9uKGdlLCAnRXN0aW1hciB0YW1hbm8nLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5fYWNjaW9uX2VzdGltYXIpCiAg
:::ICAgICAgICAgIHNlbGYuYnRuX2VzdGltYXIuZ3JpZChyb3c9MCwgY29sdW1uPTEs
:::IHN0aWNreT0nZScsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBw
:::YWR4PTgsIGlwYWR5PTMpCgogICAgICAgICAgICAjIC0tLSBib3RvbmVzIGdyYW5k
:::ZXMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAg
:::ICAgICAgICAgIHNlbGYuYnRuX2Rlc2NhcmdhciA9IHNlbGYuX2JvdG9uKG1hcmNv
:::LCAnRGVzY2FyZ2FyIHkgY29udmVydGlyJywKICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5fYWNjaW9uX2Rlc2NhcmdhciwK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZnVl
:::bnRlPUZVRU5URV9CVE5fRywgYWx0bz0yKQogICAgICAgICAgICBzZWxmLmJ0bl9k
:::ZXNjYXJnYXIuZ3JpZChyb3c9NCwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5
:::PSg3LCA0KSkKICAgICAgICAgICAgc2VsZi5idG5fY29tcHJvYmFyID0gc2VsZi5f
:::Ym90b24oCiAgICAgICAgICAgICAgICBtYXJjbywgJ0NvbXByb2JhciBjYWxpZGFk
:::IGRlIGxhIGNhcnBldGEnLAogICAgICAgICAgICAgICAgc2VsZi5fYWNjaW9uX2Nv
:::bXByb2JhciwgZnVlbnRlPUZVRU5URV9CVE4pCiAgICAgICAgICAgIHNlbGYuYnRu
:::X2NvbXByb2Jhci5ncmlkKHJvdz01LCBjb2x1bW49MCwgc3RpY2t5PSdldycsIHBh
:::ZHk9MykKCiAgICAgICAgICAgICMgLS0tIGVzdGFkbyArIGJhcnJhIGRlIHByb2dy
:::ZXNvIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAg
:::IHNlbGYubGJsX2VzdGFkbyA9IHRrLkxhYmVsKG1hcmNvLCB0ZXh0PScnLCBmb250
:::PUZVRU5URV9VSSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgYW5jaG9yPSd3JykKICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmdyaWQo
:::cm93PTYsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgcGFkeT0oNCwgMCkpCiAgICAg
:::ICAgICAgIHNlbGYuYmFycmEgPSB0dGsuUHJvZ3Jlc3NiYXIoCiAgICAgICAgICAg
:::ICAgICBtYXJjbywgbWF4aW11bT0xMDAsIHN0eWxlPSdneC5Ib3Jpem9udGFsLlRQ
:::cm9ncmVzc2JhcicpCiAgICAgICAgICAgIHNlbGYuYmFycmEuZ3JpZChyb3c9Nywg
:::Y29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PSgyLCA0KSkKCiAgICAgICAgICAg
:::ICMgLS0tIHJlZ2lzdHJvIChsb2cpIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAgIHNlbGYudHh0X2xvZyA9IFNj
:::cm9sbGVkVGV4dChtYXJjbywgZm9udD1GVUVOVEVfTE9HLCBoZWlnaHQ9MTIsCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWxpZWY9J2Zs
:::YXQnLCBiZD0wLCB3cmFwPSd3b3JkJywKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgIHN0YXRlPSdkaXNhYmxlZCcpCiAgICAgICAgICAgIHNl
:::bGYudHh0X2xvZy5ncmlkKHJvdz04LCBjb2x1bW49MCwgc3RpY2t5PSduc2V3JykK
:::ICAgICAgICAgICAgbWFyY28ucm93Y29uZmlndXJlKDgsIHdlaWdodD0xKQogICAg
:::ICAgICAgICBmb3IgdGFnLCBjb25mIGluICgKICAgICAgICAgICAgICAgICAgICAo
:::J2luZm8nLCB7fSksCiAgICAgICAgICAgICAgICAgICAgKCdncmlzJywge30pLAog
:::ICAgICAgICAgICAgICAgICAgICgndGl0dWxvJywge30pLAogICAgICAgICAgICAg
:::ICAgICAgICgnb2snLCB7fSksCiAgICAgICAgICAgICAgICAgICAgKCdhdmlzbycs
:::IHt9KSwKICAgICAgICAgICAgICAgICAgICAoJ2Vycm9yJywge30pKToKICAgICAg
:::ICAgICAgICAgIHNlbGYudHh0X2xvZy50YWdfY29uZmlndXJlKHRhZywgY29uZikK
:::CiAgICAgICAgICAgICMgc2luY3Jvbml6YXIgdmFsb3JlcyBndWFyZGFkb3MKICAg
:::ICAgICAgICAgZm10ID0gQUpVU1RFUy5nZXQoJ2Zvcm1hdG8nLCAnQUFDJykKICAg
:::ICAgICAgICAgaWYgZm10IG5vdCBpbiBGT1JNQVRPUzoKICAgICAgICAgICAgICAg
:::IGZtdCA9ICdBQUMnCiAgICAgICAgICAgIHNlbGYuY21iX2Zvcm1hdG8uc2V0KEZP
:::Uk1BVE9TW2ZtdF1bJ3RleHRvJ10pCiAgICAgICAgICAgIHNlbGYuX3JlY2FyZ2Fy
:::X2NhbGlkYWRlcyhmbXQsIEFKVVNURVMuZ2V0KCdjYWxpZGFkJykpCgogICAgICAg
:::ICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tIGhlbHBlcnMgd2lkZ2V0cwogICAgICAgIGRlZiBfYm90b24oc2VsZiwgcGFk
:::cmUsIHRleHRvLCBjbWQsIHdpZHRoPU5vbmUsIGZ1ZW50ZT1GVUVOVEVfQlROLAog
:::ICAgICAgICAgICAgICAgICAgYWx0bz0xKToKICAgICAgICAgICAgYiA9IHRrLkJ1
:::dHRvbihwYWRyZSwgdGV4dD10ZXh0bywgY29tbWFuZD1jbWQsIGZvbnQ9ZnVlbnRl
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgIHJlbGllZj0nZmxhdCcsIGJkPTAs
:::IGN1cnNvcj0naGFuZDInLCBoZWlnaHQ9YWx0bywKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICBhY3RpdmVmb3JlZ3JvdW5kPScjZmZmZmZmJywgdGFrZWZvY3VzPTAp
:::CiAgICAgICAgICAgIGlmIHdpZHRoOgogICAgICAgICAgICAgICAgYi5jb25maWd1
:::cmUod2lkdGg9d2lkdGgpCiAgICAgICAgICAgIGIuYmluZCgnPEVudGVyPicsIGxh
:::bWJkYSBlLCB3PWI6IHcuY29uZmlndXJlKAogICAgICAgICAgICAgICAgYmc9VEVN
:::QVNbc2VsZi5fdGVtYV9hY3R1YWxdWydib3Rvbl9hY3QnXSkpCiAgICAgICAgICAg
:::IGIuYmluZCgnPExlYXZlPicsIGxhbWJkYSBlLCB3PWI6IHcuY29uZmlndXJlKAog
:::ICAgICAgICAgICAgICAgYmc9VEVNQVNbc2VsZi5fdGVtYV9hY3R1YWxdWydib3Rv
:::biddKSkKICAgICAgICAgICAgc2VsZi5fYnRucy5hcHBlbmQoYikKICAgICAgICAg
:::ICAgcmV0dXJuIGIKCiAgICAgICAgZGVmIF9wb25lcl9wbGFjZWhvbGRlcihzZWxm
:::KToKICAgICAgICAgICAgaWYgbm90IHNlbGYuZW50X3VybC5nZXQoKToKICAgICAg
:::ICAgICAgICAgIHNlbGYuX2VuX3BsYWNlaG9sZGVyID0gVHJ1ZQogICAgICAgICAg
:::ICAgICAgc2VsZi5lbnRfdXJsLmluc2VydCgwLCBQTEFDRUhPTERFUl9VUkwpCgog
:::ICAgICAgIGRlZiBfbGltcGlhcl91cmwoc2VsZik6CiAgICAgICAgICAgIHNlbGYu
:::ZW50X3VybC5kZWxldGUoMCwgJ2VuZCcpCiAgICAgICAgICAgIHNlbGYuZW50X3Vy
:::bC5mb2N1c19zZXQoKQoKICAgICAgICBkZWYgX3Jlc2V0X3VybChzZWxmKToKICAg
:::ICAgICAgICAgIiIiRGVqYSBlbCBjYW1wbyBkZSBVUkwgdmFjw61vIGNvbiBzdSBw
:::bGFjZWhvbGRlciAodHJhcyB1biDDqXhpdG8pLiIiIgogICAgICAgICAgICBzZWxm
:::LmVudF91cmwuZGVsZXRlKDAsICdlbmQnKQogICAgICAgICAgICBzZWxmLl9lbl9w
:::bGFjZWhvbGRlciA9IFRydWUKICAgICAgICAgICAgc2VsZi5fcG9uZXJfcGxhY2Vo
:::b2xkZXIoKQogICAgICAgICAgICBzZWxmLl9yZWZyZXNjYXJfcGxhY2Vob2xkZXIo
:::KQoKICAgICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLSB0ZW1hCiAgICAgICAgZGVmIF9hcGxpY2FyX3RlbWEoc2Vs
:::Zik6CiAgICAgICAgICAgIHQgPSBURU1BU1tzZWxmLl90ZW1hX2FjdHVhbF0KICAg
:::ICAgICAgICAgdyA9IHNlbGYuX3dnCiAgICAgICAgICAgIHNlbGYuY29uZmlndXJl
:::KGJnPXRbJ2ZvbmRvJ10pCiAgICAgICAgICAgIGZvciBub21icmUgaW4gKCdtYXJj
:::bycsICdmMCcsICdndScsICdnZicsICdmYycsICdnZScpOgogICAgICAgICAgICAg
:::ICAgd1tub21icmVdLmNvbmZpZ3VyZShiZz10Wydmb25kbyddKQogICAgICAgICAg
:::ICBmb3IgbGYgaW4gKHdbJ2d1J10sIHdbJ2dmJ10sIHdbJ2dlJ10pOgogICAgICAg
:::ICAgICAgICAgbGYuY29uZmlndXJlKGJnPXRbJ2ZvbmRvJ10sIGZnPXRbJ3RleHRv
:::MiddKQogICAgICAgICAgICBmb3Igbm9tYnJlIGluICgnbGJsX3RlbWEnLCAnbGJs
:::X2ZtdCcsICdsYmxfY2FsJywgJ2xibF9jYXInKToKICAgICAgICAgICAgICAgIHdb
:::bm9tYnJlXS5jb25maWd1cmUoYmc9dFsnZm9uZG8nXSwgZmc9dFsndGV4dG8nXSkK
:::ICAgICAgICAgICAgc2VsZi5sYmxfZXN0aW1hY2lvbi5jb25maWd1cmUoYmc9dFsn
:::Zm9uZG8nXSwgZmc9dFsndGV4dG8nXSkKICAgICAgICAgICAgc2VsZi5sYmxfZXN0
:::YWRvLmNvbmZpZ3VyZShiZz10Wydmb25kbyddLCBmZz10Wyd0ZXh0bzInXSkKICAg
:::ICAgICAgICAgc2VsZi5lbnRfdXJsLmNvbmZpZ3VyZSgKICAgICAgICAgICAgICAg
:::IGJnPXRbJ2NhbXBvJ10sIGZnPXRbJ3RleHRvJ10sIGluc2VydGJhY2tncm91bmQ9
:::dFsndGV4dG8nXSwKICAgICAgICAgICAgICAgIGhpZ2hsaWdodGJhY2tncm91bmQ9
:::dFsnY2FtcG9fYm9yZGUnXSwKICAgICAgICAgICAgICAgIGhpZ2hsaWdodGNvbG9y
:::PXRbJ2FjZW50byddLAogICAgICAgICAgICAgICAgZGlzYWJsZWRiYWNrZ3JvdW5k
:::PXRbJ2NhbXBvJ10sIGRpc2FibGVkZm9yZWdyb3VuZD10Wyd0ZXh0bzInXSkKICAg
:::ICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5jb25maWd1cmUoCiAgICAgICAgICAg
:::ICAgICBiZz10WydjYW1wbyddLCBmZz10Wyd0ZXh0byddLCBpbnNlcnRiYWNrZ3Jv
:::dW5kPXRbJ3RleHRvJ10sCiAgICAgICAgICAgICAgICBoaWdobGlnaHRiYWNrZ3Jv
:::dW5kPXRbJ2NhbXBvX2JvcmRlJ10sCiAgICAgICAgICAgICAgICBoaWdobGlnaHRj
:::b2xvcj10WydhY2VudG8nXSkKICAgICAgICAgICAgc2VsZi5jaGtfZW1iZWJlci5j
:::b25maWd1cmUoCiAgICAgICAgICAgICAgICBiZz10Wydmb25kbyddLCBmZz10Wyd0
:::ZXh0byddLCBhY3RpdmViYWNrZ3JvdW5kPXRbJ2ZvbmRvJ10sCiAgICAgICAgICAg
:::ICAgICBhY3RpdmVmb3JlZ3JvdW5kPXRbJ3RleHRvJ10sIHNlbGVjdGNvbG9yPXRb
:::J2NhbXBvJ10pCiAgICAgICAgICAgIGZvciBiIGluIHNlbGYuX2J0bnM6CiAgICAg
:::ICAgICAgICAgICBiLmNvbmZpZ3VyZShiZz10Wydib3RvbiddLCBmZz10Wydib3Rv
:::bl90eHQnXSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGFjdGl2ZWJhY2tn
:::cm91bmQ9dFsnYm90b25fYWN0J10sCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICBhY3RpdmVmb3JlZ3JvdW5kPXRbJ2JvdG9uX3R4dCddKQogICAgICAgICAgICBz
:::ZWxmLnR4dF9sb2cuY29uZmlndXJlKGJnPXRbJ2xvZyddLCBmZz10Wydsb2dfdHh0
:::J10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgaW5zZXJ0YmFj
:::a2dyb3VuZD10Wydsb2dfdHh0J10pCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy50
:::YWdfY29uZmlndXJlKCdpbmZvJywgZm9yZWdyb3VuZD10Wydsb2dfdHh0J10pCiAg
:::ICAgICAgICAgIHNlbGYudHh0X2xvZy50YWdfY29uZmlndXJlKCdncmlzJywgZm9y
:::ZWdyb3VuZD10Wyd0ZXh0bzInXSkKICAgICAgICAgICAgc2VsZi50eHRfbG9nLnRh
:::Z19jb25maWd1cmUoJ3RpdHVsbycsIGZvcmVncm91bmQ9dFsndGV4dG8nXSwKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZm9udD0oJ0NvbnNv
:::bGFzJywgMTAsICdib2xkJykpCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy50YWdf
:::Y29uZmlndXJlKCdvaycsIGZvcmVncm91bmQ9dFsnb2snXSkKICAgICAgICAgICAg
:::c2VsZi50eHRfbG9nLnRhZ19jb25maWd1cmUoJ2F2aXNvJywgZm9yZWdyb3VuZD10
:::WydhdmlzbyddKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cudGFnX2NvbmZpZ3Vy
:::ZSgnZXJyb3InLCBmb3JlZ3JvdW5kPXRbJ2Vycm9yJ10pCiAgICAgICAgICAgIGVz
:::dCA9IHNlbGYuX2VzdGlsbwogICAgICAgICAgICBlc3QuY29uZmlndXJlKCdneC5U
:::Q29tYm9ib3gnLAogICAgICAgICAgICAgICAgICAgICAgICAgIGZpZWxkYmFja2dy
:::b3VuZD10WydjYW1wbyddLCBiYWNrZ3JvdW5kPXRbJ2JvdG9uJ10sCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgZm9yZWdyb3VuZD10Wyd0ZXh0byddLCBhcnJvd2Nv
:::bG9yPXRbJ3RleHRvJ10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgYm9yZGVy
:::Y29sb3I9dFsnY2FtcG9fYm9yZGUnXSwKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICBsaWdodGNvbG9yPXRbJ2NhbXBvX2JvcmRlJ10sCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgZGFya2NvbG9yPXRbJ2NhbXBvX2JvcmRlJ10sCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgaW5zZXJ0Y29sb3I9dFsndGV4dG8nXSkKICAgICAgICAg
:::ICAgZXN0Lm1hcCgnZ3guVENvbWJvYm94JywKICAgICAgICAgICAgICAgICAgICBm
:::aWVsZGJhY2tncm91bmQ9WygncmVhZG9ubHknLCB0WydjYW1wbyddKV0sCiAgICAg
:::ICAgICAgICAgICAgICAgZm9yZWdyb3VuZD1bKCdyZWFkb25seScsIHRbJ3RleHRv
:::J10pXSkKICAgICAgICAgICAgZXN0LmNvbmZpZ3VyZSgnZ3guSG9yaXpvbnRhbC5U
:::UHJvZ3Jlc3NiYXInLAogICAgICAgICAgICAgICAgICAgICAgICAgIHRyb3VnaGNv
:::bG9yPXRbJ3Ryb3VnaCddLCBiYWNrZ3JvdW5kPXRbJ2FjZW50byddLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgIGJvcmRlcmNvbG9yPXRbJ2ZvbmRvJ10sIGxpZ2h0
:::Y29sb3I9dFsnYWNlbnRvJ10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgZGFy
:::a2NvbG9yPXRbJ2FjZW50byddKQogICAgICAgICAgICBzZWxmLm9wdGlvbl9hZGQo
:::JypUQ29tYm9ib3gqTGlzdGJveC5iYWNrZ3JvdW5kJywgdFsnY2FtcG8nXSkKICAg
:::ICAgICAgICAgc2VsZi5vcHRpb25fYWRkKCcqVENvbWJvYm94Kkxpc3Rib3guZm9y
:::ZWdyb3VuZCcsIHRbJ3RleHRvJ10pCiAgICAgICAgICAgIHNlbGYub3B0aW9uX2Fk
:::ZCgnKlRDb21ib2JveCpMaXN0Ym94LnNlbGVjdEJhY2tncm91bmQnLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgdFsnYm90b25fYWN0J10pCiAgICAgICAgICAg
:::IHNlbGYub3B0aW9uX2FkZCgnKlRDb21ib2JveCpMaXN0Ym94LnNlbGVjdEZvcmVn
:::cm91bmQnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgdFsnYm90b25fdHh0
:::J10pCiAgICAgICAgICAgIHNlbGYuX3JlZnJlc2Nhcl9wbGFjZWhvbGRlcigpCgog
:::ICAgICAgIGRlZiBfcmVmcmVzY2FyX3BsYWNlaG9sZGVyKHNlbGYpOgogICAgICAg
:::ICAgICB0ID0gVEVNQVNbc2VsZi5fdGVtYV9hY3R1YWxdCiAgICAgICAgICAgIGlm
:::IHNlbGYuX2VuX3BsYWNlaG9sZGVyOgogICAgICAgICAgICAgICAgc2VsZi5lbnRf
:::dXJsLmNvbmZpZ3VyZShmZz10WydwbGFjZWhvbGRlciddKQogICAgICAgICAgICBl
:::bHNlOgogICAgICAgICAgICAgICAgc2VsZi5lbnRfdXJsLmNvbmZpZ3VyZShmZz10
:::Wyd0ZXh0byddKQoKICAgICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBldmVudG9zCiAgICAgICAgZGVmIF9jb25l
:::Y3Rhcl9ldmVudG9zKHNlbGYpOgogICAgICAgICAgICBzZWxmLmNtYl90ZW1hLmJp
:::bmQoJzw8Q29tYm9ib3hTZWxlY3RlZD4+Jywgc2VsZi5fb25fdGVtYSkKICAgICAg
:::ICAgICAgc2VsZi5jbWJfZm9ybWF0by5iaW5kKCc8PENvbWJvYm94U2VsZWN0ZWQ+
:::PicsIHNlbGYuX29uX2Zvcm1hdG8pCiAgICAgICAgICAgIHNlbGYuY21iX2NhbGlk
:::YWQuYmluZCgnPDxDb21ib2JveFNlbGVjdGVkPj4nLCBsYW1iZGEgZTogc2VsZi5f
:::Z3VhcmRhcigpKQogICAgICAgICAgICBzZWxmLmNoa19lbWJlYmVyLmNvbmZpZ3Vy
:::ZShjb21tYW5kPXNlbGYuX2d1YXJkYXIpCiAgICAgICAgICAgIHNlbGYuZW50X3Vy
:::bC5iaW5kKCc8Rm9jdXNJbj4nLCBzZWxmLl9vbl9mb2N1c191cmxfaW4pCiAgICAg
:::ICAgICAgIHNlbGYuZW50X3VybC5iaW5kKCc8Rm9jdXNPdXQ+Jywgc2VsZi5fb25f
:::Zm9jdXNfdXJsX291dCkKICAgICAgICAgICAgc2VsZi5lbnRfdXJsLmJpbmQoJzxS
:::ZXR1cm4+JywgbGFtYmRhIGU6IHNlbGYuX2FjY2lvbl9kZXNjYXJnYXIoKSkKICAg
:::ICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5iaW5kKCc8Rm9jdXNPdXQ+Jywgc2Vs
:::Zi5fb25fY2FycGV0YV9lc2NyaXRhKQogICAgICAgICAgICBzZWxmLnByb3RvY29s
:::KCdXTV9ERUxFVEVfV0lORE9XJywgc2VsZi5fYWxfY2VycmFyKQogICAgICAgICAg
:::ICBzZWxmLmJpbmQoJzxDb250cm9sLXU+JywgbGFtYmRhIGU6IHNlbGYuX2FjY2lv
:::bl9hY3R1YWxpemFyKCkpCiAgICAgICAgICAgIHNlbGYuYmluZCgnPENvbnRyb2wt
:::bD4nLCBsYW1iZGEgZTogc2VsZi5fbGltcGlhcl9sb2coKSkKICAgICAgICAgICAg
:::c2VsZi5iaW5kKCc8Q29udHJvbC1VPicsIGxhbWJkYSBlOiBzZWxmLl9hY2Npb25f
:::YWN0dWFsaXphcigpKQoKICAgICAgICBkZWYgX29uX2ZvY3VzX3VybF9pbihzZWxm
:::LCBfZT1Ob25lKToKICAgICAgICAgICAgaWYgc2VsZi5fZW5fcGxhY2Vob2xkZXI6
:::CiAgICAgICAgICAgICAgICBzZWxmLmVudF91cmwuZGVsZXRlKDAsICdlbmQnKQog
:::ICAgICAgICAgICAgICAgc2VsZi5fZW5fcGxhY2Vob2xkZXIgPSBGYWxzZQogICAg
:::ICAgICAgICAgICAgc2VsZi5fcmVmcmVzY2FyX3BsYWNlaG9sZGVyKCkKCiAgICAg
:::ICAgZGVmIF9vbl9mb2N1c191cmxfb3V0KHNlbGYsIF9lPU5vbmUpOgogICAgICAg
:::ICAgICBpZiBub3Qgc2VsZi5lbnRfdXJsLmdldCgpOgogICAgICAgICAgICAgICAg
:::c2VsZi5fZW5fcGxhY2Vob2xkZXIgPSBUcnVlCiAgICAgICAgICAgICAgICBzZWxm
:::Ll9wb25lcl9wbGFjZWhvbGRlcigpCiAgICAgICAgICAgICAgICBzZWxmLl9yZWZy
:::ZXNjYXJfcGxhY2Vob2xkZXIoKQoKICAgICAgICBkZWYgX29uX3RlbWEoc2VsZiwg
:::X2U9Tm9uZSk6CiAgICAgICAgICAgIHNlbGYuX3RlbWFfYWN0dWFsID0gc2VsZi5j
:::bWJfdGVtYS5nZXQoKQogICAgICAgICAgICBBSlVTVEVTWyd0ZW1hJ10gPSBzZWxm
:::Ll90ZW1hX2FjdHVhbAogICAgICAgICAgICBndWFyZGFyX2FqdXN0ZXMoKQogICAg
:::ICAgICAgICBzZWxmLl9hcGxpY2FyX3RlbWEoKQoKICAgICAgICBkZWYgX29uX2Zv
:::cm1hdG8oc2VsZiwgX2U9Tm9uZSk6CiAgICAgICAgICAgIGZtdCA9IHNlbGYuX2Zt
:::dF9hY3R1YWwoKQogICAgICAgICAgICBzZWxmLl9yZWNhcmdhcl9jYWxpZGFkZXMo
:::Zm10KQogICAgICAgICAgICBzZWxmLl9ndWFyZGFyKCkKICAgICAgICAgICAgc2Vs
:::Zi5sYmxfZXN0aW1hY2lvbi5jb25maWd1cmUoCiAgICAgICAgICAgICAgICB0ZXh0
:::PSdJbnRyb2R1Y2UgdW5hIFVSTCB5IHB1bHNhIEVzdGltYXIuJywKICAgICAgICAg
:::ICAgICAgIGZnPVRFTUFTW3NlbGYuX3RlbWFfYWN0dWFsXVsndGV4dG8nXSkKCiAg
:::ICAgICAgZGVmIF9mbXRfYWN0dWFsKHNlbGYpOgogICAgICAgICAgICB0ZXh0byA9
:::IHNlbGYuY21iX2Zvcm1hdG8uZ2V0KCkKICAgICAgICAgICAgZm9yIGNsYXZlLCBm
:::IGluIEZPUk1BVE9TLml0ZW1zKCk6CiAgICAgICAgICAgICAgICBpZiBmWyd0ZXh0
:::byddID09IHRleHRvOgogICAgICAgICAgICAgICAgICAgIHJldHVybiBjbGF2ZQog
:::ICAgICAgICAgICByZXR1cm4gJ0FBQycKCiAgICAgICAgZGVmIF9yZWNhcmdhcl9j
:::YWxpZGFkZXMoc2VsZiwgY2xhdmVfZm10LCBjYWxpZGFkX3ByZXZpYT1Ob25lKToK
:::ICAgICAgICAgICAgZiA9IEZPUk1BVE9TW2NsYXZlX2ZtdF0KICAgICAgICAgICAg
:::c2VsZi5jbWJfY2FsaWRhZFsndmFsdWVzJ10gPSBmWydjYWxpZGFkZXMnXQogICAg
:::ICAgICAgICBpZiBjYWxpZGFkX3ByZXZpYSBhbmQgY2FsaWRhZF9wcmV2aWEgaW4g
:::ZlsnY2FsaWRhZGVzJ106CiAgICAgICAgICAgICAgICBzZWxmLmNtYl9jYWxpZGFk
:::LnNldChjYWxpZGFkX3ByZXZpYSkKICAgICAgICAgICAgZWxzZToKICAgICAgICAg
:::ICAgICAgIHNlbGYuY21iX2NhbGlkYWQuc2V0KGZbJ2RlZmVjdG8nXSkKICAgICAg
:::ICAgICAgQUpVU1RFU1snZm9ybWF0byddID0gY2xhdmVfZm10CiAgICAgICAgICAg
:::IEFKVVNURVNbJ2NhbGlkYWQnXSA9IHNlbGYuY21iX2NhbGlkYWQuZ2V0KCkKCiAg
:::ICAgICAgZGVmIF9ndWFyZGFyKHNlbGYpOgogICAgICAgICAgICBBSlVTVEVTWydm
:::b3JtYXRvJ10gPSBzZWxmLl9mbXRfYWN0dWFsKCkKICAgICAgICAgICAgQUpVU1RF
:::U1snY2FsaWRhZCddID0gc2VsZi5jbWJfY2FsaWRhZC5nZXQoKQogICAgICAgICAg
:::ICBBSlVTVEVTWydlbWJlYmVyJ10gPSBib29sKHNlbGYudmFyX2VtYmViZXIuZ2V0
:::KCkpCiAgICAgICAgICAgIEFKVVNURVNbJ2Rlc3Rpbm8nXSA9IHNlbGYuZW50X2Nh
:::cnBldGEuZ2V0KCkuc3RyaXAoKQogICAgICAgICAgICBndWFyZGFyX2FqdXN0ZXMo
:::KQoKICAgICAgICBkZWYgX29uX2NhcnBldGFfZXNjcml0YShzZWxmLCBfZT1Ob25l
:::KToKICAgICAgICAgICAgcCA9IFBhdGgob3MucGF0aC5leHBhbmR2YXJzKAogICAg
:::ICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5nZXQoKS5zdHJpcCgpLnN0cmlw
:::KCciJykpKQogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBwLm1rZGly
:::KHBhcmVudHM9VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgICAgICAgICAgICAgIEFK
:::VVNURVNbJ2Rlc3Rpbm8nXSA9IHN0cihwKQogICAgICAgICAgICAgICAgZ3VhcmRh
:::cl9hanVzdGVzKCkKICAgICAgICAgICAgZXhjZXB0IE9TRXJyb3IgYXMgZToKICAg
:::ICAgICAgICAgICAgIHNlbGYuX2xvZyhmJ05vIHNlIHB1ZG8gdXNhciBlc2EgY2Fy
:::cGV0YToge2V9JywgJ2Vycm9yJykKCiAgICAgICAgZGVmIF9jYW1iaWFyX2NhcnBl
:::dGEoc2VsZik6CiAgICAgICAgICAgIGFjdHVhbCA9IHNlbGYuZW50X2NhcnBldGEu
:::Z2V0KCkuc3RyaXAoKSBvciBBSlVTVEVTWydkZXN0aW5vJ10KICAgICAgICAgICAg
:::bnVldmEgPSBmaWxlZGlhbG9nLmFza2RpcmVjdG9yeSgKICAgICAgICAgICAgICAg
:::IHRpdGxlPSdFbGlnZSBsYSBjYXJwZXRhIGRvbmRlIGd1YXJkYXIgbGFzIGRlc2Nh
:::cmdhcycsCiAgICAgICAgICAgICAgICBpbml0aWFsZGlyPWFjdHVhbCBpZiBvcy5w
:::YXRoLmlzZGlyKGFjdHVhbCkgZWxzZSBzdHIoUGF0aC5ob21lKCkpKQogICAgICAg
:::ICAgICBpZiBub3QgbnVldmE6CiAgICAgICAgICAgICAgICByZXR1cm4KICAgICAg
:::ICAgICAgdHJ5OgogICAgICAgICAgICAgICAgUGF0aChudWV2YSkubWtkaXIocGFy
:::ZW50cz1UcnVlLCBleGlzdF9vaz1UcnVlKQogICAgICAgICAgICBleGNlcHQgT1NF
:::cnJvciBhcyBlOgogICAgICAgICAgICAgICAgbWVzc2FnZWJveC5zaG93ZXJyb3Io
:::J0NhcnBldGEgbm8gdsOhbGlkYScsIHN0cihlKSkKICAgICAgICAgICAgICAgIHJl
:::dHVybgogICAgICAgICAgICBzZWxmLmVudF9jYXJwZXRhLmRlbGV0ZSgwLCAnZW5k
:::JykKICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5pbnNlcnQoMCwgbnVldmEp
:::CiAgICAgICAgICAgIEFKVVNURVNbJ2Rlc3Rpbm8nXSA9IG51ZXZhCiAgICAgICAg
:::ICAgIGd1YXJkYXJfYWp1c3RlcygpCiAgICAgICAgICAgIHNlbGYuX2xvZygnQ2Fy
:::cGV0YSBkZSBndWFyZGFkbzogJyArIG51ZXZhLCAnZ3JpcycpCgogICAgICAgIGRl
:::ZiBfYWJyaXJfZGVzdGlubyhzZWxmKToKICAgICAgICAgICAgcCA9IFBhdGgob3Mu
:::cGF0aC5leHBhbmR2YXJzKAogICAgICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0
:::YS5nZXQoKS5zdHJpcCgpLnN0cmlwKCciJykpKQogICAgICAgICAgICB0cnk6CiAg
:::ICAgICAgICAgICAgICBwLm1rZGlyKHBhcmVudHM9VHJ1ZSwgZXhpc3Rfb2s9VHJ1
:::ZSkKICAgICAgICAgICAgZXhjZXB0IE9TRXJyb3I6CiAgICAgICAgICAgICAgICBw
:::YXNzCiAgICAgICAgICAgIGFicmlyX2NhcnBldGEocCkKCiAgICAgICAgZGVmIF9h
:::bF9jZXJyYXIoc2VsZik6CiAgICAgICAgICAgIGlmIHNlbGYuX29jdXBhZG8gYW5k
:::IG5vdCBtZXNzYWdlYm94LmFza29rY2FuY2VsKAogICAgICAgICAgICAgICAgICAg
:::ICdTYWxpcicsICdIYXkgdW5hIHRhcmVhIGVuIGN1cnNvLiAnCiAgICAgICAgICAg
:::ICAgICAgICAgJ8K/U2VndXJvIHF1ZSBxdWllcmVzIHNhbGlyPycpOgogICAgICAg
:::ICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgIHNlbGYuZGVzdHJveSgpCgogICAg
:::ICAgICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tIHJlZ2lzdHJvIChsb2cpCiAgICAgICAgZGVmIF9sb2coc2VsZiwgbXNn
:::LCB0YWc9J2luZm8nKToKICAgICAgICAgICAgc2VsZi50eHRfbG9nLmNvbmZpZ3Vy
:::ZShzdGF0ZT0nbm9ybWFsJykKICAgICAgICAgICAgbl9saW5lYXMgPSBpbnQoc2Vs
:::Zi50eHRfbG9nLmluZGV4KCdlbmQtMWMnKS5zcGxpdCgnLicpWzBdKQogICAgICAg
:::ICAgICBpZiBuX2xpbmVhcyA+IDkwMDoKICAgICAgICAgICAgICAgIHNlbGYudHh0
:::X2xvZy5kZWxldGUoJzEuMCcsICcyMDAuMCcpCiAgICAgICAgICAgIHNlbGYudHh0
:::X2xvZy5pbnNlcnQoJ2VuZCcsIHN0cihtc2cpICsgJ1xuJywgdGFnKQogICAgICAg
:::ICAgICBzZWxmLnR4dF9sb2cuc2VlKCdlbmQnKQogICAgICAgICAgICBzZWxmLnR4
:::dF9sb2cuY29uZmlndXJlKHN0YXRlPSdkaXNhYmxlZCcpCgogICAgICAgIGRlZiBf
:::bGltcGlhcl9sb2coc2VsZik6CiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5jb25m
:::aWd1cmUoc3RhdGU9J25vcm1hbCcpCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5k
:::ZWxldGUoJzEuMCcsICdlbmQnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuY29u
:::ZmlndXJlKHN0YXRlPSdkaXNhYmxlZCcpCgogICAgICAgIGRlZiBfYm9tYmVhcl9j
:::b2xhKHNlbGYpOgogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICB3aGls
:::ZSBUcnVlOgogICAgICAgICAgICAgICAgICAgIGV2ID0gc2VsZi5jb2xhLmdldF9u
:::b3dhaXQoKQogICAgICAgICAgICAgICAgICAgIHRpcG8gPSBldlswXQogICAgICAg
:::ICAgICAgICAgICAgIGlmIHRpcG8gPT0gJ2xvZyc6CiAgICAgICAgICAgICAgICAg
:::ICAgICAgIHNlbGYuX2xvZyhldlsxXSwgZXZbMl0pCiAgICAgICAgICAgICAgICAg
:::ICAgZWxpZiB0aXBvID09ICdwcm9nJzoKICAgICAgICAgICAgICAgICAgICAgICAg
:::cGN0LCB0ZXh0byA9IGV2WzFdLCBldlsyXQogICAgICAgICAgICAgICAgICAgICAg
:::ICBpZiBwY3QgaXMgTm9uZToKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNl
:::bGYuYmFycmEuc3RvcCgpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzZWxm
:::LmJhcnJhLmNvbmZpZ3VyZShtb2RlPSdpbmRldGVybWluYXRlJykKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgIHNlbGYuYmFycmEuc3RhcnQoNjApCiAgICAgICAg
:::ICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICBzZWxmLmJhcnJhLnN0b3AoKQogICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::c2VsZi5iYXJyYS5jb25maWd1cmUobW9kZT0nZGV0ZXJtaW5hdGUnKQogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgc2VsZi5iYXJyYS5jb25maWd1cmUodmFsdWU9
:::bWF4KDAsIG1pbigxMDAsIHBjdCkpKQogICAgICAgICAgICAgICAgICAgICAgICBz
:::ZWxmLmxibF9lc3RhZG8uY29uZmlndXJlKHRleHQ9dGV4dG8pCiAgICAgICAgICAg
:::ICAgICAgICAgZWxpZiB0aXBvID09ICdlc3RpbWFjaW9uJzoKICAgICAgICAgICAg
:::ICAgICAgICAgICAgc2VsZi5sYmxfZXN0aW1hY2lvbi5jb25maWd1cmUoCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICB0ZXh0PWV2WzFdLCBmZz1URU1BU1tzZWxm
:::Ll90ZW1hX2FjdHVhbF1bJ2FjZW50byddKQogICAgICAgICAgICAgICAgICAgIGVs
:::aWYgdGlwbyA9PSAnZmluJzoKICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5f
:::ZmluX3RhcmVhKGV2WzFdLCBldlsyXSwgZXZbM10gaWYgbGVuKGV2KSA+IDMgZWxz
:::ZSAnJykKICAgICAgICAgICAgZXhjZXB0IHF1ZXVlLkVtcHR5OgogICAgICAgICAg
:::ICAgICAgcGFzcwogICAgICAgICAgICBzZWxmLmFmdGVyKDgwLCBzZWxmLl9ib21i
:::ZWFyX2NvbGEpCgogICAgICAgICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tIHRhcmVhcwogICAgICAgIGRlZiBfaGFiaWxp
:::dGFyX2FjY2lvbmVzKHNlbGYsIG9uKToKICAgICAgICAgICAgZXN0YWRvID0gJ25v
:::cm1hbCcgaWYgb24gZWxzZSAnZGlzYWJsZWQnCiAgICAgICAgICAgIGZvciBiIGlu
:::IChzZWxmLmJ0bl9kZXNjYXJnYXIsIHNlbGYuYnRuX2NvbXByb2JhciwKICAgICAg
:::ICAgICAgICAgICAgICAgIHNlbGYuYnRuX2VzdGltYXIsIHNlbGYuYnRuX2NhbWJp
:::YXIsIHNlbGYuYnRuX2FicmlyLAogICAgICAgICAgICAgICAgICAgICAgc2VsZi5i
:::dG5feCk6CiAgICAgICAgICAgICAgICBiLmNvbmZpZ3VyZShzdGF0ZT1lc3RhZG8s
:::IGN1cnNvcj0naGFuZDInIGlmIG9uIGVsc2UgJ2Fycm93JykKCiAgICAgICAgZGVm
:::IF9pbmljaWFyKHNlbGYsIG9iamV0aXZvLCBjZmcsIHRleHRvKToKICAgICAgICAg
:::ICAgaWYgc2VsZi5fb2N1cGFkbzoKICAgICAgICAgICAgICAgIHNlbGYuX2xvZygn
:::WWEgaGF5IHVuYSB0YXJlYSBlbiBjdXJzbzsgZXNwZXJhIGEgcXVlIHRlcm1pbmUu
:::JywKICAgICAgICAgICAgICAgICAgICAgICAgICAnYXZpc28nKQogICAgICAgICAg
:::ICAgICAgcmV0dXJuIEZhbHNlCiAgICAgICAgICAgIHNlbGYuX29jdXBhZG8gPSBU
:::cnVlCiAgICAgICAgICAgIHNlbGYuX2hhYmlsaXRhcl9hY2Npb25lcyhGYWxzZSkK
:::ICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmNvbmZpZ3VyZSh0ZXh0PXRleHRv
:::KQogICAgICAgICAgICB0aHJlYWRpbmcuVGhyZWFkKHRhcmdldD1vYmpldGl2bywg
:::YXJncz0oY2ZnLCksIGRhZW1vbj1UcnVlKS5zdGFydCgpCiAgICAgICAgICAgIHJl
:::dHVybiBUcnVlCgogICAgICAgIGRlZiBfZmluX3RhcmVhKHNlbGYsIHRpcG8sIG9r
:::LCBtZW5zYWplPScnKToKICAgICAgICAgICAgc2VsZi5fb2N1cGFkbyA9IEZhbHNl
:::CiAgICAgICAgICAgIHNlbGYuX2hhYmlsaXRhcl9hY2Npb25lcyhUcnVlKQogICAg
:::ICAgICAgICBzZWxmLmJhcnJhLnN0b3AoKQogICAgICAgICAgICBzZWxmLmJhcnJh
:::LmNvbmZpZ3VyZShtb2RlPSdkZXRlcm1pbmF0ZScpCiAgICAgICAgICAgIHNlbGYu
:::YmFycmEuY29uZmlndXJlKHZhbHVlPTApCiAgICAgICAgICAgIGlmIHRpcG8gPT0g
:::J2Rlc2NhcmdhJyBhbmQgb2s6CiAgICAgICAgICAgICAgICBzZWxmLmxibF9lc3Rh
:::ZG8uY29uZmlndXJlKHRleHQ9J0xpc3RvLicpCiAgICAgICAgICAgICAgICAjIExh
:::IGRlc2NhcmdhIGZ1ZSBiaWVuOiBzZSBsaW1waWEgbGEgVVJMIHBhcmEgbGEgc2ln
:::dWllbnRlLgogICAgICAgICAgICAgICAgc2VsZi5fcmVzZXRfdXJsKCkKICAgICAg
:::ICAgICAgZWxpZiBub3Qgb2s6CiAgICAgICAgICAgICAgICBzZWxmLmxibF9lc3Rh
:::ZG8uY29uZmlndXJlKHRleHQ9J1Rlcm1pbmFkbyBjb24gZXJyb3Jlcy4nKQogICAg
:::ICAgICAgICAgICAgaWYgdGlwbyA9PSAnZGVzY2FyZ2EnOgogICAgICAgICAgICAg
:::ICAgICAgIG1lc3NhZ2Vib3guc2hvd2Vycm9yKAogICAgICAgICAgICAgICAgICAg
:::ICAgICAnRXJyb3InLCBtZW5zYWplIG9yICdObyBzZSBwdWRvIGNvbXBsZXRhciBs
:::YSB0YXJlYS4gJwogICAgICAgICAgICAgICAgICAgICAgICAnUmV2aXNhIGVsIHJl
:::Z2lzdHJvIHBhcmEgbcOhcyBkZXRhbGxlcy4nKQoKICAgICAgICBkZWYgX3VybF92
:::YWxpZGEoc2VsZik6CiAgICAgICAgICAgIGlmIHNlbGYuX2VuX3BsYWNlaG9sZGVy
:::OgogICAgICAgICAgICAgICAgc2VsZi5fbG9nKCdQcmltZXJvIHBlZ2EgbGEgVVJM
:::IGRlbCB2aWRlbyBkZSBZb3VUdWJlLicsICdhdmlzbycpCiAgICAgICAgICAgICAg
:::ICByZXR1cm4gTm9uZQogICAgICAgICAgICB1ID0gc2VsZi5lbnRfdXJsLmdldCgp
:::LnN0cmlwKCkuc3RyaXAoJyInKS5zdHJpcCgiJyIpCiAgICAgICAgICAgIGlmIG5v
:::dCB1OgogICAgICAgICAgICAgICAgc2VsZi5fbG9nKCdMYSBVUkwgZXN0w6EgdmFj
:::w61hLicsICdhdmlzbycpCiAgICAgICAgICAgICAgICByZXR1cm4gTm9uZQogICAg
:::ICAgICAgICBpZiBub3QgcmUubWF0Y2gocideaHR0cHM/Oi8vJywgdSwgcmUuSSk6
:::CiAgICAgICAgICAgICAgICBpZiByZS5tYXRjaChyJ153d3dcLicsIHUsIHJlLkkp
:::OgogICAgICAgICAgICAgICAgICAgIHUgPSAnaHR0cHM6Ly8nICsgdQogICAgICAg
:::ICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgICAgICBzZWxmLl9sb2coJ0Vz
:::byBubyBwYXJlY2UgdW5hIFVSTCAoZGViZSBlbXBlemFyIHBvciAnCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICdodHRwOi8vIG8gaHR0cHM6Ly8pJywgJ2Vy
:::cm9yJykKICAgICAgICAgICAgICAgICAgICByZXR1cm4gTm9uZQogICAgICAgICAg
:::ICAjIE9KTzogYXF1w60gTk8gc2UgcXVpdGEgbGlzdD07IHNpIGxhIFVSTCB0cmFl
:::IHVuYSBwbGF5bGlzdCwKICAgICAgICAgICAgIyBfYWNjaW9uX2Rlc2NhcmdhciBw
:::cmVndW50YXLDoSBxdcOpIGhhY2VyIGNvbiBlbGxhLgogICAgICAgICAgICByZXR1
:::cm4gdQoKICAgICAgICBkZWYgX2FjY2lvbl9lc3RpbWFyKHNlbGYpOgogICAgICAg
:::ICAgICB1cmwgPSBzZWxmLl91cmxfdmFsaWRhKCkKICAgICAgICAgICAgaWYgbm90
:::IHVybDoKICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICBzZWxmLl9n
:::dWFyZGFyKCkKICAgICAgICAgICAgY2ZnID0geyd1cmwnOiB1cmx9CiAgICAgICAg
:::ICAgIHNlbGYuX2luaWNpYXIoc2VsZi5faGlsb19lc3RpbWFyLCBjZmcsICdFc3Rp
:::bWFuZG8gdGFtYcOxby4uLicpCiAgICAgICAgICAgIHNlbGYubGJsX2VzdGltYWNp
:::b24uY29uZmlndXJlKAogICAgICAgICAgICAgICAgdGV4dD0nQ2FsY3VsYW5kby4u
:::LicsIGZnPVRFTUFTW3NlbGYuX3RlbWFfYWN0dWFsXVsndGV4dG8yJ10pCgogICAg
:::ICAgIGRlZiBfYWNjaW9uX2Rlc2NhcmdhcihzZWxmKToKICAgICAgICAgICAgdXJs
:::ID0gc2VsZi5fdXJsX3ZhbGlkYSgpCiAgICAgICAgICAgIGlmIG5vdCB1cmw6CiAg
:::ICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgc2VsZi5fZ3VhcmRhcigp
:::CiAgICAgICAgICAgIHBsYXlsaXN0ID0gRmFsc2UKICAgICAgICAgICAgaWYgZXNf
:::dXJsX3BsYXlsaXN0KHVybCk6CiAgICAgICAgICAgICAgICByID0gbWVzc2FnZWJv
:::eC5hc2t5ZXNub2NhbmNlbCgKICAgICAgICAgICAgICAgICAgICAnTXVzaWtBTEFO
:::IOKAlCBsaXN0YSBkZSByZXByb2R1Y2Npw7NuJywKICAgICAgICAgICAgICAgICAg
:::ICAnRXN0YSBVUkwgcGVydGVuZWNlIGEgdW5hIGxpc3RhIGRlIHJlcHJvZHVjY2nD
:::s24uXG5cbicKICAgICAgICAgICAgICAgICAgICAnICBTw40gIOKGkiAgZGVzY2Fy
:::Z2FyIGxhIHBsYXlsaXN0IGNvbXBsZXRhXG4nCiAgICAgICAgICAgICAgICAgICAg
:::JyAgICAgICAgIChwYXVzYSBkZSAyIHMgZW50cmUgY2FuY2lvbmVzKVxuJwogICAg
:::ICAgICAgICAgICAgICAgICcgIE5PICDihpIgIGRlc2NhcmdhciBzb2xvIGVzdGEg
:::Y2FuY2nDs25cbicKICAgICAgICAgICAgICAgICAgICAnICBDYW5jZWxhciAg4oaS
:::ICBubyBkZXNjYXJnYXIgbmFkYScpCiAgICAgICAgICAgICAgICBpZiByIGlzIE5v
:::bmU6CiAgICAgICAgICAgICAgICAgICAgc2VsZi5fbG9nKCdEZXNjYXJnYSBjYW5j
:::ZWxhZGEuJywgJ2dyaXMnKQogICAgICAgICAgICAgICAgICAgIHJldHVybgogICAg
:::ICAgICAgICAgICAgaWYgcjoKICAgICAgICAgICAgICAgICAgICBwbGF5bGlzdCA9
:::IFRydWUKICAgICAgICAgICAgICAgIGVsaWYgZXNfc29sb19saXN0YSh1cmwpOgog
:::ICAgICAgICAgICAgICAgICAgICMgRXMgdW5hIHBsYXlsaXN0IHB1cmE6IG5vIGhh
:::eSAidW5hIGNhbmNpw7NuIiBhaMOtCiAgICAgICAgICAgICAgICAgICAgc2VsZi5f
:::bG9nKCdFc2EgVVJMIGVzIHVuYSBsaXN0YSBjb21wbGV0YTsgc2UgZGVzY2FyZ2Fy
:::w6EgJwogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZW50ZXJhLicsICdh
:::dmlzbycpCiAgICAgICAgICAgICAgICAgICAgcGxheWxpc3QgPSBUcnVlCiAgICAg
:::ICAgICAgIGNmZyA9IHsndXJsJzogdXJsLCAncGxheWxpc3QnOiBwbGF5bGlzdH0K
:::ICAgICAgICAgICAgc2VsZi5faW5pY2lhcihzZWxmLl9oaWxvX2Rlc2Nhcmdhciwg
:::Y2ZnLCAnRGVzY2FyZ2FuZG8uLi4nKQoKICAgICAgICBkZWYgX2FjY2lvbl9jb21w
:::cm9iYXIoc2VsZik6CiAgICAgICAgICAgIHNlbGYuX2d1YXJkYXIoKQogICAgICAg
:::ICAgICBzZWxmLl9pbmljaWFyKHNlbGYuX2hpbG9fY29tcHJvYmFyLCB7fSwKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAnQ29tcHJvYmFuZG8gbGEgY2FycGV0YS4u
:::LicpCgogICAgICAgIGRlZiBfYWNjaW9uX2FjdHVhbGl6YXIoc2VsZik6CiAgICAg
:::ICAgICAgIGlmIG5vdCBZVF9ETFA6CiAgICAgICAgICAgICAgICBzZWxmLl9sb2co
:::J3l0LWRscCBubyBlc3TDoSBpbnN0YWxhZG87IGVqZWN1dGEgJwogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICdEZXNjYXJnYWRvck11c2ljYS5iYXQuJywgJ2Vycm9y
:::JykKICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICBzZWxmLl9pbmlj
:::aWFyKHNlbGYuX2hpbG9fYWN0dWFsaXphciwge30sICdBY3R1YWxpemFuZG8geXQt
:::ZGxwLi4uJykKCiAgICAgICAgIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0gaGlsb3MKICAgICAgICBkZWYgX2hpbG9fZXN0
:::aW1hcihzZWxmLCBjZmcpOgogICAgICAgICAgICBjb2xhID0gc2VsZi5jb2xhCgog
:::ICAgICAgICAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAgICAgICAgICAg
:::IGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgICAgICAgICB0cnk6CiAgICAg
:::ICAgICAgICAgICBpZiBZVF9ETFAgaXMgTm9uZToKICAgICAgICAgICAgICAgICAg
:::ICBsb2coJ3l0LWRscCBubyBlc3TDoSBpbnN0YWxhZG8uIEVqZWN1dGEgJwogICAg
:::ICAgICAgICAgICAgICAgICAgICAnRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0IHBhcmEg
:::aW5zdGFsYXJsby4nLCAnZXJyb3InKQogICAgICAgICAgICAgICAgICAgIGNvbGEu
:::cHV0KCgnZXN0aW1hY2lvbicsICd5dC1kbHAgbm8gZGlzcG9uaWJsZScpKQogICAg
:::ICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICAgICAgbG9nKCdPYnRl
:::bmllbmRvIGluZm9ybWFjacOzbiBkZWwgdmlkZW8uLi4nLCAnZ3JpcycpCiAgICAg
:::ICAgICAgICAgICBvID0geydxdWlldCc6IFRydWUsICdub193YXJuaW5ncyc6IFRy
:::dWUsICdub3BsYXlsaXN0JzogVHJ1ZSwKICAgICAgICAgICAgICAgICAgICAgJ3Nv
:::Y2tldF90aW1lb3V0JzogMzAsICdsb2dnZXInOiBSRUdJU1RST30KICAgICAgICAg
:::ICAgICAgIGlmIGVzX3VybF9wbGF5bGlzdChjZmdbJ3VybCddKToKICAgICAgICAg
:::ICAgICAgICAgICBsb2coJyhsYSBVUkwgY29udGllbmUgdW5hIHBsYXlsaXN0OiBs
:::YSBlc3RpbWFjacOzbiBlcyAnCiAgICAgICAgICAgICAgICAgICAgICAgICdzb2xv
:::IGRlbCB2aWRlbyBwZWdhZG8pJywgJ2dyaXMnKQogICAgICAgICAgICAgICAgd2l0
:::aCBZVF9ETFAuWW91dHViZURMKG8pIGFzIHlkbDoKICAgICAgICAgICAgICAgICAg
:::ICBpbmZvID0geWRsLmV4dHJhY3RfaW5mbyhjZmdbJ3VybCddLCBkb3dubG9hZD1G
:::YWxzZSkKICAgICAgICAgICAgICAgIGR1ciA9IGluZm8uZ2V0KCdkdXJhdGlvbicp
:::CiAgICAgICAgICAgICAgICBpZiBub3QgZHVyOgogICAgICAgICAgICAgICAgICAg
:::IGxvZygnTm8gc2UgcHVkbyBvYnRlbmVyIGxhIGR1cmFjacOzbiBkZWwgdmlkZW8u
:::JywgJ2Vycm9yJykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2VzdGlt
:::YWNpb24nLCAnU2luIGRhdG9zIHBhcmEgZXN0aW1hcicpKQogICAgICAgICAgICAg
:::ICAgICAgIHJldHVybgogICAgICAgICAgICAgICAgY2xhdmUgPSBzZWxmLl9mbXRf
:::YWN0dWFsX3NvbG8oQUpVU1RFUy5nZXQoJ2Zvcm1hdG8nLCAnQUFDJykpCiAgICAg
:::ICAgICAgICAgICB0YW0gPSBlc3RpbWFyX2J5dGVzKGR1ciwgY2xhdmUsIEFKVVNU
:::RVMuZ2V0KCdjYWxpZGFkJyksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgIGJvb2woQUpVU1RFUy5nZXQoJ2VtYmViZXInLCBUcnVlKSkpCiAgICAg
:::ICAgICAgICAgICB0aXR1bG8gPSBzdHIoaW5mby5nZXQoJ3RpdGxlJykgb3IgJycp
:::Wzo3MF0KICAgICAgICAgICAgICAgIGlmIHRpdHVsbzoKICAgICAgICAgICAgICAg
:::ICAgICBsb2coJ+KZqiAnICsgdGl0dWxvLCAndGl0dWxvJykKICAgICAgICAgICAg
:::ICAgIHRleHRvID0gKGYnfnt0YW0gLyAxMDQ4NTc2Oi4xZn0gTUIgwrcgJwogICAg
:::ICAgICAgICAgICAgICAgICAgICAgZidkdXJhY2nDs24ge2ZtdF90aWVtKGR1cil9
:::IMK3ICcKICAgICAgICAgICAgICAgICAgICAgICAgIGYne2NsYXZlfSB7QUpVU1RF
:::Uy5nZXQoImNhbGlkYWQiLCAiIil9Jy5yc3RyaXAoKSkKICAgICAgICAgICAgICAg
:::IGNvbGEucHV0KCgnZXN0aW1hY2lvbicsIHRleHRvKSkKICAgICAgICAgICAgICAg
:::IGxvZygnRXN0aW1hY2nDs246ICcgKyB0ZXh0bywgJ29rJykKICAgICAgICAgICAg
:::ICAgIGxvZygnRWwgdGFtYcOxbyByZWFsIHB1ZWRlIHZhcmlhciBhbGdvIHNlZ8O6
:::biBsYSBmdWVudGUuJywKICAgICAgICAgICAgICAgICAgICAnZ3JpcycpCiAgICAg
:::ICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZToKICAgICAgICAgICAgICAgIGxv
:::ZyhmJ05vIHNlIHB1ZG8gZXN0aW1hcjoge3NlbGYuX21zZ19lcnJvcihlKX0nLCAn
:::ZXJyb3InKQogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdlc3RpbWFjaW9uJywg
:::J05vIHNlIHB1ZG8gZXN0aW1hcicpKQogICAgICAgICAgICBmaW5hbGx5OgogICAg
:::ICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnZXN0aW1hY2lvbicsIFRydWUs
:::ICcnKSkKCiAgICAgICAgZGVmIF9mbXRfYWN0dWFsX3NvbG8oc2VsZiwgY2xhdmUp
:::OgogICAgICAgICAgICByZXR1cm4gY2xhdmUgaWYgY2xhdmUgaW4gRk9STUFUT1Mg
:::ZWxzZSAnQUFDJwoKICAgICAgICBkZWYgX2Rlc2Nhcmdhcl91bmEoc2VsZiwgdXJs
:::LCBjbGF2ZSwgY2FsaWRhZF9hcmcsIGVtYmViZXIsIGRlc3Rpbm8sCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgIGNvbGEpOgogICAgICAgICAgICAiIiJEZXNjYXJn
:::YSB5IGNvbnZpZXJ0ZSBVTkEgVVJMLiBEZXZ1ZWx2ZSBlbCBQYXRoIGZpbmFsIG8g
:::Tm9uZS4iIiIKICAgICAgICAgICAgaWYgY2xhdmUgPT0gJ1dNQSc6CiAgICAgICAg
:::ICAgICAgICByZXR1cm4gZGVzY2FyZ2FyX3dtYSh1cmwsIGNhbGlkYWRfYXJnLCBk
:::ZXN0aW5vLCBlbWJlYmVyLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgY29sYSlbMV0KICAgICAgICAgICAgaWYgY2xhdmUgPT0gJ0FWSSc6CiAg
:::ICAgICAgICAgICAgICByZXR1cm4gZGVzY2FyZ2FyX2F2aSh1cmwsIGRlc3Rpbm8s
:::IGNvbGEpWzFdCiAgICAgICAgICAgIHJldHVybiBkZXNjYXJnYXJfYXVkaW8odXJs
:::LCBjbGF2ZSwgY2FsaWRhZF9hcmcsIGRlc3Rpbm8sIGVtYmViZXIsCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sYSlbMV0KCiAgICAgICAgZGVm
:::IF9kZXNjYXJnYXJfcGxheWxpc3Qoc2VsZiwgdXJsLCBjbGF2ZSwgY2FsaWRhZF9h
:::cmcsIGVtYmViZXIsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGVz
:::dGlubywgY29sYSk6CiAgICAgICAgICAgICIiIkJhamEgdW5hIGxpc3RhIGVudGVy
:::YSwgY29uIDIgcyBkZSBkZXNjYW5zbyBlbnRyZSBjYW5jaW9uZXMKICAgICAgICAg
:::ICAgcGFyYSBubyBzYXR1cmFyIGEgWW91VHViZS4gRGV2dWVsdmUgKGRlc2Nhcmdh
:::ZGFzLCB0b3RhbCkuIiIiCiAgICAgICAgICAgIGRlZiBsb2cobSwgdD0naW5mbycp
:::OgogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICAg
:::ICAgICAgIGxvZygnTGV5ZW5kbyBsYSBsaXN0YSBkZSByZXByb2R1Y2Npw7NuLi4u
:::JywgJ2dyaXMnKQogICAgICAgICAgICBvID0geydxdWlldCc6IFRydWUsICdub193
:::YXJuaW5ncyc6IFRydWUsCiAgICAgICAgICAgICAgICAgJ2V4dHJhY3RfZmxhdCc6
:::ICdpbl9wbGF5bGlzdCcsICdzb2NrZXRfdGltZW91dCc6IDMwLAogICAgICAgICAg
:::ICAgICAgICdsb2dnZXInOiBSRUdJU1RST30KICAgICAgICAgICAgd2l0aCBZVF9E
:::TFAuWW91dHViZURMKG8pIGFzIHlkbDoKICAgICAgICAgICAgICAgIGluZm8gPSB5
:::ZGwuZXh0cmFjdF9pbmZvKHVybCwgZG93bmxvYWQ9RmFsc2UpCiAgICAgICAgICAg
:::IGVudHJhZGFzID0gbGlzdChpbmZvLmdldCgnZW50cmllcycpIG9yIFtdKQogICAg
:::ICAgICAgICBpZiBub3QgZW50cmFkYXM6CiAgICAgICAgICAgICAgICBsb2coJ05v
:::IHNlIHZpbyBuaW5ndW5hIGNhbmNpw7NuIGVuIGxhIGxpc3RhOyBzZSBpbnRlbnRh
:::ICcKICAgICAgICAgICAgICAgICAgICAnY29tbyB2aWRlbyBzdWVsdG8uJywgJ2F2
:::aXNvJykKICAgICAgICAgICAgICAgIGFyY2hpdm8gPSBzZWxmLl9kZXNjYXJnYXJf
:::dW5hKHNpbl9wbGF5bGlzdCh1cmwpWzBdLCBjbGF2ZSwKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNhbGlkYWRfYXJnLCBlbWJl
:::YmVyLCBkZXN0aW5vLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgY29sYSkKICAgICAgICAgICAgICAgIHJldHVybiAoMSBpZiBh
:::cmNoaXZvIGVsc2UgMCksIDEKICAgICAgICAgICAgdGl0dWxvX3BsID0gc3RyKGlu
:::Zm8uZ2V0KCd0aXRsZScpIG9yICdsaXN0YScpWzo3MF0KICAgICAgICAgICAgdG90
:::YWwgPSBsZW4oZW50cmFkYXMpCiAgICAgICAgICAgIGxvZyhmJ1BsYXlsaXN0IMKr
:::e3RpdHVsb19wbH3CuyDigJQge3RvdGFsfSB2w61kZW8ocykuJywgJ3RpdHVsbycp
:::CiAgICAgICAgICAgIG9rYXMgPSAwCiAgICAgICAgICAgIGZhbGxvcyA9IFtdCiAg
:::ICAgICAgICAgIGZvciBpLCBlIGluIGVudW1lcmF0ZShlbnRyYWRhcyk6CiAgICAg
:::ICAgICAgICAgICB1ID0gc3RyKGUuZ2V0KCd3ZWJwYWdlX3VybCcpIG9yIGUuZ2V0
:::KCd1cmwnKSBvciAnJykKICAgICAgICAgICAgICAgIGlmIHUgYW5kIG5vdCB1LnN0
:::YXJ0c3dpdGgoJ2h0dHAnKToKICAgICAgICAgICAgICAgICAgICB1ID0gJ2h0dHBz
:::Oi8vd3d3LnlvdXR1YmUuY29tL3dhdGNoP3Y9JyArIHUKICAgICAgICAgICAgICAg
:::IGlmIG5vdCB1IGFuZCBlLmdldCgnaWQnKToKICAgICAgICAgICAgICAgICAgICB1
:::ID0gJ2h0dHBzOi8vd3d3LnlvdXR1YmUuY29tL3dhdGNoP3Y9JyArIHN0cihlWydp
:::ZCddKQogICAgICAgICAgICAgICAgdGl0ID0gc3RyKGUuZ2V0KCd0aXRsZScpIG9y
:::IHUgb3IgJz8nKVs6NzBdCiAgICAgICAgICAgICAgICBpZiBpOgogICAgICAgICAg
:::ICAgICAgICAgIHRpbWUuc2xlZXAoMikgICAjIGRlc2NhbnNvIGVudHJlIGNhbmNp
:::b25lcwogICAgICAgICAgICAgICAgbG9nKGYnW3tpICsgMX0ve3RvdGFsfV0g4pmq
:::IHt0aXR9JywgJ3RpdHVsbycpCiAgICAgICAgICAgICAgICB0cnk6CiAgICAgICAg
:::ICAgICAgICAgICAgYXJjaGl2byA9IHNlbGYuX2Rlc2Nhcmdhcl91bmEodSwgY2xh
:::dmUsIGNhbGlkYWRfYXJnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgIGVtYmViZXIsIGRlc3Rpbm8sIGNvbGEpCiAgICAg
:::ICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uIGFzIGUyOgogICAgICAgICAgICAg
:::ICAgICAgIGFyY2hpdm8gPSBOb25lCiAgICAgICAgICAgICAgICAgICAgbG9nKGYn
:::4pyWIFt7aSArIDF9L3t0b3RhbH1dIEZhbGzDszoge3NlbGYuX21zZ19lcnJvcihl
:::Mil9JywKICAgICAgICAgICAgICAgICAgICAgICAgJ2Vycm9yJykKICAgICAgICAg
:::ICAgICAgIGlmIGFyY2hpdm8gYW5kIFBhdGgoYXJjaGl2bykuZXhpc3RzKCk6CiAg
:::ICAgICAgICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgICAgICAgICB0
:::YW0gPSBmbXRfdGFtKFBhdGgoYXJjaGl2bykuc3RhdCgpLnN0X3NpemUpCiAgICAg
:::ICAgICAgICAgICAgICAgZXhjZXB0IE9TRXJyb3I6CiAgICAgICAgICAgICAgICAg
:::ICAgICAgIHRhbSA9ICc/JwogICAgICAgICAgICAgICAgICAgIGxvZyhmJyAgIOKc
:::lCB7UGF0aChhcmNoaXZvKS5uYW1lfSAgKHt0YW19KScsICdvaycpCiAgICAgICAg
:::ICAgICAgICAgICAgb2thcyArPSAxCiAgICAgICAgICAgICAgICBlbHNlOgogICAg
:::ICAgICAgICAgICAgICAgIGZhbGxvcy5hcHBlbmQodGl0KQogICAgICAgICAgICBs
:::b2coZidQbGF5bGlzdCB0ZXJtaW5hZGE6IHtva2FzfSBkZSB7dG90YWx9IGRlc2Nh
:::cmdhZGEocykuJywKICAgICAgICAgICAgICAgICdvaycgaWYgbm90IGZhbGxvcyBl
:::bHNlICdhdmlzbycpCiAgICAgICAgICAgIGlmIGZhbGxvczoKICAgICAgICAgICAg
:::ICAgIGxvZygnU2luIGRlc2NhcmdhcjogJwogICAgICAgICAgICAgICAgICAgICsg
:::JyDCtyAnLmpvaW4oZls6NDBdIGZvciBmIGluIGZhbGxvc1s6OF0pCiAgICAgICAg
:::ICAgICAgICAgICAgKyAoJy4uLicgaWYgbGVuKGZhbGxvcykgPiA4IGVsc2UgJycp
:::LCAnZ3JpcycpCiAgICAgICAgICAgIHJldHVybiBva2FzLCB0b3RhbAoKICAgICAg
:::ICBkZWYgX2hpbG9fZGVzY2FyZ2FyKHNlbGYsIGNmZyk6CiAgICAgICAgICAgIGNv
:::bGEgPSBzZWxmLmNvbGEKCiAgICAgICAgICAgIGRlZiBsb2cobSwgdD0naW5mbycp
:::OgogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICAg
:::ICAgICAgIHVybCA9IGNmZ1sndXJsJ10KICAgICAgICAgICAgY2xhdmUgPSBzZWxm
:::Ll9mbXRfYWN0dWFsX3NvbG8oQUpVU1RFUy5nZXQoJ2Zvcm1hdG8nLCAnQUFDJykp
:::CiAgICAgICAgICAgIGNhbGlkYWQgPSBBSlVTVEVTLmdldCgnY2FsaWRhZCcsICcx
:::MjhrJykKICAgICAgICAgICAgZW1iZWJlciA9IGJvb2woQUpVU1RFUy5nZXQoJ2Vt
:::YmViZXInLCBUcnVlKSkKICAgICAgICAgICAgZGVzdGlubyA9IFBhdGgob3MucGF0
:::aC5leHBhbmR2YXJzKAogICAgICAgICAgICAgICAgc3RyKEFKVVNURVMuZ2V0KCdk
:::ZXN0aW5vJywgX2Rlc3Rpbm9fcG9yX2RlZmVjdG8oKSkpKSkKICAgICAgICAgICAg
:::dHJ5OgogICAgICAgICAgICAgICAgaWYgWVRfRExQIGlzIE5vbmU6CiAgICAgICAg
:::ICAgICAgICAgICAgbG9nKCd5dC1kbHAgbm8gZXN0w6EgaW5zdGFsYWRvLiBFamVj
:::dXRhICcKICAgICAgICAgICAgICAgICAgICAgICAgJ0Rlc2NhcmdhZG9yTXVzaWNh
:::LmJhdCBwYXJhIGluc3RhbGFybG8uJywgJ2Vycm9yJykKICAgICAgICAgICAgICAg
:::ICAgICBjb2xhLnB1dCgoJ2ZpbicsICdkZXNjYXJnYScsIEZhbHNlLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAneXQtZGxwIG5vIGVzdMOhIGluc3RhbGFk
:::by4nKSkKICAgICAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgICAg
:::IGRlc3Rpbm8ubWtkaXIocGFyZW50cz1UcnVlLCBleGlzdF9vaz1UcnVlKQogICAg
:::ICAgICAgICAgICAgaWYgY2xhdmUgaW4gKCdGTEFDJywgJ1dBVicpOgogICAgICAg
:::ICAgICAgICAgICAgIGNhbGlkYWRfYXJnID0gJzAnCiAgICAgICAgICAgICAgICBl
:::bHNlOgogICAgICAgICAgICAgICAgICAgIGNhbGlkYWRfYXJnID0gKHJlLnN1Yihy
:::J1teMC05XScsICcnLCBzdHIoY2FsaWRhZCkpCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgb3IgKCcxMjgnIGlmIGNsYXZlID09ICdBQUMnIGVsc2Ug
:::JzMyMCcpKQogICAgICAgICAgICAgICAgaWYgY2ZnLmdldCgncGxheWxpc3QnKToK
:::ICAgICAgICAgICAgICAgICAgICBva2FzLCB0b3RhbCA9IHNlbGYuX2Rlc2Nhcmdh
:::cl9wbGF5bGlzdCgKICAgICAgICAgICAgICAgICAgICAgICAgdXJsLCBjbGF2ZSwg
:::Y2FsaWRhZF9hcmcsIGVtYmViZXIsIGRlc3Rpbm8sIGNvbGEpCiAgICAgICAgICAg
:::ICAgICAgICAgaWYgb2thcyBhbmQgb2thcyA9PSB0b3RhbDoKICAgICAgICAgICAg
:::ICAgICAgICAgICAgbG9nKGYnQ2FycGV0YToge2Rlc3Rpbm99JywgJ2dyaXMnKQog
:::ICAgICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdkZXNjYXJn
:::YScsIFRydWUsICcnKSkKICAgICAgICAgICAgICAgICAgICBlbHNlOgogICAgICAg
:::ICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAnZmluJywgJ2Rlc2NhcmdhJywgRmFsc2UsCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICBmJ1NlIGRlc2Nhcmdhcm9uIHtva2FzfSBkZSB7dG90YWx9
:::IGRlIGxhICcKICAgICAgICAgICAgICAgICAgICAgICAgICAgICdwbGF5bGlzdC4g
:::TGEgVVJMIG5vIHNlIGhhIGJvcnJhZG8gcG9yIHNpICcKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICdxdWllcmVzIHJlaW50ZW50YXJsby4nKSkKICAgICAgICAg
:::ICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgICAgIGFyY2hpdm8gPSBzZWxm
:::Ll9kZXNjYXJnYXJfdW5hKHNpbl9wbGF5bGlzdCh1cmwpWzBdLCBjbGF2ZSwKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNhbGlk
:::YWRfYXJnLCBlbWJlYmVyLCBkZXN0aW5vLAogICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgY29sYSkKICAgICAgICAgICAgICAgIGlm
:::IGFyY2hpdm8gYW5kIFBhdGgoYXJjaGl2bykuZXhpc3RzKCk6CiAgICAgICAgICAg
:::ICAgICAgICAgYXJjaGl2byA9IFBhdGgoYXJjaGl2bykKICAgICAgICAgICAgICAg
:::ICAgICB0cnk6CiAgICAgICAgICAgICAgICAgICAgICAgIHRhbSA9IGZtdF90YW0o
:::YXJjaGl2by5zdGF0KCkuc3Rfc2l6ZSkKICAgICAgICAgICAgICAgICAgICBleGNl
:::cHQgT1NFcnJvcjoKICAgICAgICAgICAgICAgICAgICAgICAgdGFtID0gJz8nCiAg
:::ICAgICAgICAgICAgICAgICAgbG9nKGYn4pyUIMKhTGlzdG8hICB7YXJjaGl2by5u
:::YW1lfSAgKHt0YW19KScsICdvaycpCiAgICAgICAgICAgICAgICAgICAgbG9nKGYn
:::Q2FycGV0YToge2FyY2hpdm8ucGFyZW50fScsICdncmlzJykKICAgICAgICAgICAg
:::ICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdkZXNjYXJnYScsIFRydWUsICcnKSkK
:::ICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICAgICAgbG9nKCdF
:::bCBhcmNoaXZvIGZpbmFsIG5vIGFwYXJlY2nDsyBkb25kZSBzZSBlc3BlcmFiYS4n
:::LAogICAgICAgICAgICAgICAgICAgICAgICAnZXJyb3InKQogICAgICAgICAgICAg
:::ICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2Rlc2NhcmdhJywgRmFsc2UsICcnKSkK
:::ICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBlOgogICAgICAgICAgICAg
:::ICAgbm9tYnJlX2V4YyA9IHR5cGUoZSkuX19uYW1lX18KICAgICAgICAgICAgICAg
:::IGlmIG5vbWJyZV9leGMgPT0gJ0Rvd25sb2FkRXJyb3InOgogICAgICAgICAgICAg
:::ICAgICAgIGxpbmVhcyA9IFtsIGZvciBsIGluIHN0cihlKS5zdHJpcCgpLnNwbGl0
:::bGluZXMoKSBpZiBsLnN0cmlwKCldCiAgICAgICAgICAgICAgICAgICAgbXNnID0g
:::bGluZWFzWzBdWzozMDBdIGlmIGxpbmVhcyBlbHNlICdlcnJvciBkZXNjb25vY2lk
:::bycKICAgICAgICAgICAgICAgICAgICBsb2coJ+KcliBObyBzZSBwdWRvIGRlc2Nh
:::cmdhcjogJyArIG1zZywgJ2Vycm9yJykKICAgICAgICAgICAgICAgICAgICBsb2co
:::J0NvbnNlam9zOiByZXZpc2EgbGEgVVJMIHkgdHUgY29uZXhpw7NuOyBzaSBZb3VU
:::dWJlICcKICAgICAgICAgICAgICAgICAgICAgICAgJ2NhbWJpw7MgYWxnbywgcHVs
:::c2EgQ3RybCtVIChhY3R1YWxpemFyIHl0LWRscCkgeSAnCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICdyZWludGVudGEuJywgJ2dyaXMnKQogICAgICAgICAgICAgICAg
:::ZWxzZToKICAgICAgICAgICAgICAgICAgICBsb2coZifinJYgRXJyb3IgaW5lc3Bl
:::cmFkbyAoe25vbWJyZV9leGN9KToge2V9JywgJ2Vycm9yJykKICAgICAgICAgICAg
:::ICAgICAgICB0YiA9IHRyYWNlYmFjay5mb3JtYXRfZXhjKGxpbWl0PTMpCiAgICAg
:::ICAgICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgICAgICAgICB3aXRo
:::IG9wZW4oTE9HX0VSUk9SRVMsICdhJywgZW5jb2Rpbmc9J3V0Zi04JykgYXMgZmg6
:::CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBmaC53cml0ZSh0YiArICdcbicp
:::CiAgICAgICAgICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAg
:::ICAgICAgICAgICAgICAgcGFzcwogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdm
:::aW4nLCAnZGVzY2FyZ2EnLCBGYWxzZSwKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAnTm8gc2UgcHVkbyBjb21wbGV0YXIgbGEgZGVzY2FyZ2EuIFJldmlzYSBlbCAn
:::CiAgICAgICAgICAgICAgICAgICAgICAgICAgJ3JlZ2lzdHJvIHBhcmEgbcOhcyBk
:::ZXRhbGxlcy4nKSkKCiAgICAgICAgZGVmIF9oaWxvX2NvbXByb2JhcihzZWxmLCBj
:::ZmcpOgogICAgICAgICAgICBjb2xhID0gc2VsZi5jb2xhCgogICAgICAgICAgICBk
:::ZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgn
:::bG9nJywgbSwgdCkpCgogICAgICAgICAgICBjYXJwZXRhID0gUGF0aChvcy5wYXRo
:::LmV4cGFuZHZhcnMoCiAgICAgICAgICAgICAgICBzdHIoQUpVU1RFUy5nZXQoJ2Rl
:::c3Rpbm8nLCBfZGVzdGlub19wb3JfZGVmZWN0bygpKSkpKQogICAgICAgICAgICB0
:::cnk6CiAgICAgICAgICAgICAgICBpZiBub3QgY2FycGV0YS5pc19kaXIoKToKICAg
:::ICAgICAgICAgICAgICAgICBsb2coZidMYSBjYXJwZXRhIHRvZGF2w61hIG5vIGV4
:::aXN0ZToge2NhcnBldGF9JywgJ2F2aXNvJykKICAgICAgICAgICAgICAgICAgICBj
:::b2xhLnB1dCgoJ2ZpbicsICdjb21wcm9iYWNpb24nLCBUcnVlLCAnJykpCiAgICAg
:::ICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgICAgICBpZiBGRlBST0JF
:::IGlzIE5vbmU6CiAgICAgICAgICAgICAgICAgICAgbG9nKCdmZnByb2JlIG5vIGVz
:::dMOhIGRpc3BvbmlibGUgKHZpZW5lIGNvbiBGRm1wZWcpLiAnCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICdFamVjdXRhIERlc2NhcmdhZG9yTXVzaWNhLmJhdCBwYXJh
:::IGluc3RhbGFybG8uJywKICAgICAgICAgICAgICAgICAgICAgICAgJ2Vycm9yJykK
:::ICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdjb21wcm9iYWNp
:::b24nLCBUcnVlLCAnJykpCiAgICAgICAgICAgICAgICAgICAgcmV0dXJuCiAgICAg
:::ICAgICAgICAgICBleHRzID0gKCcubTRhJywgJy5tcDMnLCAnLmZsYWMnLCAnLndh
:::dicsICcud21hJywgJy5hdmknKQogICAgICAgICAgICAgICAgYXJjaGl2b3MgPSBb
:::cCBmb3IgcCBpbiBzb3J0ZWQoY2FycGV0YS5yZ2xvYignKicpKQogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgaWYgcC5pc19maWxlKCkgYW5kIHAuc3VmZml4Lmxv
:::d2VyKCkgaW4gZXh0cwogICAgICAgICAgICAgICAgICAgICAgICAgICAgYW5kICdf
:::dG1wJyBub3QgaW4gcC5wYXJ0c10KICAgICAgICAgICAgICAgIGxvZyhmJ0NvbXBy
:::b2JhbmRvIHtsZW4oYXJjaGl2b3MpfSBhcmNoaXZvKHMpIGVuICcKICAgICAgICAg
:::ICAgICAgICAgICBmJ3tjYXJwZXRhfSAuLi4nLCAndGl0dWxvJykKICAgICAgICAg
:::ICAgICAgIGlmIG5vdCBhcmNoaXZvczoKICAgICAgICAgICAgICAgICAgICBsb2co
:::J05vIGhheSBhcmNoaXZvcyBkZSBhdWRpbyBvIHZpZGVvIHRvZGF2w61hLicsICdn
:::cmlzJykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdjb21w
:::cm9iYWNpb24nLCBUcnVlLCAnJykpCiAgICAgICAgICAgICAgICAgICAgcmV0dXJu
:::CiAgICAgICAgICAgICAgICB0b3RhbCA9IDAKICAgICAgICAgICAgICAgIGJhamFz
:::ID0gMAogICAgICAgICAgICAgICAgZm9yIHAgaW4gYXJjaGl2b3M6CiAgICAgICAg
:::ICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgICAgICAgICByID0gc3Vi
:::cHJvY2Vzcy5ydW4oCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBbc3RyKEZG
:::UFJPQkUpLCAnLXYnLCAnZXJyb3InLCAnLXNob3dfZW50cmllcycsCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgJ2Zvcm1hdD1iaXRfcmF0ZSxkdXJhdGlvbixz
:::aXplJywgJy1vZicsICdqc29uJywKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICBzdHIocCldLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgc3Rkb3V0PXN1
:::YnByb2Nlc3MuUElQRSwgc3RkZXJyPXN1YnByb2Nlc3MuUElQRSwKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgIHRleHQ9VHJ1ZSwgZW5jb2Rpbmc9J3V0Zi04Jywg
:::ZXJyb3JzPSdyZXBsYWNlJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRp
:::bWVvdXQ9MzApCiAgICAgICAgICAgICAgICAgICAgICAgIGRhdG9zID0ganNvbi5s
:::b2FkcyhyLnN0ZG91dCBvciAne30nKS5nZXQoJ2Zvcm1hdCcsIHt9KQogICAgICAg
:::ICAgICAgICAgICAgICAgICBrYnBzID0gaW50KGZsb2F0KGRhdG9zLmdldCgnYml0
:::X3JhdGUnKSBvciAwKSAvIDEwMDApCiAgICAgICAgICAgICAgICAgICAgICAgIGR1
:::ciA9IGZsb2F0KGRhdG9zLmdldCgnZHVyYXRpb24nKSBvciAwKQogICAgICAgICAg
:::ICAgICAgICAgICAgICB0YW0gPSBpbnQoZmxvYXQoZGF0b3MuZ2V0KCdzaXplJykg
:::b3IgMCkpCiAgICAgICAgICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAg
:::ICAgICAgICAgICAgICAgICAgICAgbG9nKGYnwrcge3AubmFtZVs6NjBdfSDigJQg
:::bm8gc2UgcHVkbyBsZWVyJywgJ2F2aXNvJykKICAgICAgICAgICAgICAgICAgICAg
:::ICAgY29udGludWUKICAgICAgICAgICAgICAgICAgICB0b3RhbCArPSB0YW0KICAg
:::ICAgICAgICAgICAgICAgICB0ZXh0bywgbml2ZWwgPSBjbGFzZV9jYWxpZGFkKHAu
:::c3VmZml4Lmxvd2VyKCksIGticHMpCiAgICAgICAgICAgICAgICAgICAgaWYgbml2
:::ZWwgPT0gMjoKICAgICAgICAgICAgICAgICAgICAgICAgYmFqYXMgKz0gMQogICAg
:::ICAgICAgICAgICAgICAgIHRhZyA9ICgnb2snIGlmIG5pdmVsID09IDAKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgZWxzZSAoJ2F2aXNvJyBpZiBuaXZlbCA9PSAx
:::IGVsc2UgJ2Vycm9yJykpCiAgICAgICAgICAgICAgICAgICAgbG9nKGYnwrcge3Au
:::bmFtZVs6NThdfSDigJQge3RleHRvfSDCtyB7Zm10X3RpZW0oZHVyKX0gwrcgJwog
:::ICAgICAgICAgICAgICAgICAgICAgICBmJ3tmbXRfdGFtKHRhbSl9JywgdGFnKQog
:::ICAgICAgICAgICAgICAgbG9nKGYnUmVzdWx0YWRvOiB7bGVuKGFyY2hpdm9zKX0g
:::YXJjaGl2byhzKSDCtyAnCiAgICAgICAgICAgICAgICAgICAgZid7Zm10X3RhbSh0
:::b3RhbCl9IGVuIHRvdGFsIMK3IHtiYWphc30gY29uIGNhbGlkYWQgYmFqYScsCiAg
:::ICAgICAgICAgICAgICAgICAgJ3RpdHVsbycpCiAgICAgICAgICAgICAgICBpZiBi
:::YWphczoKICAgICAgICAgICAgICAgICAgICBsb2coJ0NvbnNlam86IGxvcyBhcmNo
:::aXZvcyBtYXJjYWRvcyBlbiByb2pvIHNlIHB1ZWRlbiAnCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICd2b2x2ZXIgYSBkZXNjYXJnYXIgY29uIG3DoXMgYml0cmF0ZS4n
:::LCAnZ3JpcycpCiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZToKICAg
:::ICAgICAgICAgICAgIGxvZyhmJ0Vycm9yIGFsIGNvbXByb2JhciBsYSBjYXJwZXRh
:::OiB7ZX0nLCAnZXJyb3InKQogICAgICAgICAgICBmaW5hbGx5OgogICAgICAgICAg
:::ICAgICAgY29sYS5wdXQoKCdmaW4nLCAnY29tcHJvYmFjaW9uJywgVHJ1ZSwgJycp
:::KQoKICAgICAgICBkZWYgX2hpbG9fYWN0dWFsaXphcihzZWxmLCBjZmcpOgogICAg
:::ICAgICAgICBjb2xhID0gc2VsZi5jb2xhCgogICAgICAgICAgICBkZWYgbG9nKG0s
:::IHQ9J2luZm8nKToKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwg
:::dCkpCgogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBsb2coJ0FjdHVh
:::bGl6YW5kbyB5dC1kbHAgeSBtdXRhZ2VuLi4uJywgJ2dyaXMnKQogICAgICAgICAg
:::ICAgICAgcCA9IHN1YnByb2Nlc3MucnVuKAogICAgICAgICAgICAgICAgICAgIFtz
:::eXMuZXhlY3V0YWJsZSwgJy1tJywgJ3BpcCcsICdpbnN0YWxsJywgJy0tdXBncmFk
:::ZScsCiAgICAgICAgICAgICAgICAgICAgICctLW5vLXdhcm4tc2NyaXB0LWxvY2F0
:::aW9uJywgJ3l0LWRscCcsICdtdXRhZ2VuJ10sCiAgICAgICAgICAgICAgICAgICAg
:::c3Rkb3V0PXN1YnByb2Nlc3MuUElQRSwgc3RkZXJyPXN1YnByb2Nlc3MuU1RET1VU
:::LAogICAgICAgICAgICAgICAgICAgIHRleHQ9VHJ1ZSwgZW5jb2Rpbmc9J3V0Zi04
:::JywgZXJyb3JzPSdyZXBsYWNlJywgdGltZW91dD02MDApCiAgICAgICAgICAgICAg
:::ICBmb3IgbG4gaW4gKHAuc3Rkb3V0IG9yICcnKS5zdHJpcCgpLnNwbGl0bGluZXMo
:::KVstNjpdOgogICAgICAgICAgICAgICAgICAgIGxvZygnICAgJyArIGxuWzoxNjBd
:::LCAnZ3JpcycpCiAgICAgICAgICAgICAgICBpZiBwLnJldHVybmNvZGUgPT0gMDoK
:::ICAgICAgICAgICAgICAgICAgICBsb2coJ3l0LWRscCBhY3R1YWxpemFkby4gUmVp
:::bmljaWEgbGEgYXBsaWNhY2nDs24gcGFyYSAnCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICd1c2FyIGxhIHZlcnNpw7NuIG51ZXZhLicsICdvaycpCiAgICAgICAgICAg
:::ICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgIGxvZygnTGEgYWN0dWFsaXph
:::Y2nDs24gZmFsbMOzICjCv3NpbiBpbnRlcm5ldD8pLicsICdlcnJvcicpCiAgICAg
:::ICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZToKICAgICAgICAgICAgICAgIGxv
:::ZyhmJ05vIHNlIHB1ZG8gZWplY3V0YXIgcGlwOiB7ZX0nLCAnZXJyb3InKQogICAg
:::ICAgICAgICBmaW5hbGx5OgogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4n
:::LCAnYWN0dWFsaXphY2lvbicsIFRydWUsICcnKSkKCiAgICAgICAgZGVmIF9tc2df
:::ZXJyb3Ioc2VsZiwgZSk6CiAgICAgICAgICAgIGxpbmVhcyA9IFtsIGZvciBsIGlu
:::IHN0cihlKS5zdHJpcCgpLnNwbGl0bGluZXMoKSBpZiBsLnN0cmlwKCldCiAgICAg
:::ICAgICAgIHJldHVybiAobGluZWFzWzBdWzoyNTBdIGlmIGxpbmVhcwogICAgICAg
:::ICAgICAgICAgICAgIGVsc2UgZid7dHlwZShlKS5fX25hbWVfX306IHNpbiBkZXRh
:::bGxlcycpCgogICAgICAgICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tIGFycmFucXVlCiAgICAgICAgZGVmIF9hcnJhbnF1
:::ZShzZWxmKToKICAgICAgICAgICAgc2VsZi5fbG9nKGYnTXVzaWtBTEFOIHZ7QVBQ
:::X1Z9JywgJ3RpdHVsbycpCiAgICAgICAgICAgIHNlbGYuX2xvZygnQ3RybCtVOiBh
:::Y3R1YWxpemFyIHl0LWRscCDCtyBDdHJsK0w6IGxpbXBpYXIgcmVnaXN0cm8nLAog
:::ICAgICAgICAgICAgICAgICAgICAgJ2dyaXMnKQogICAgICAgICAgICB0aHJlYWRp
:::bmcuVGhyZWFkKHRhcmdldD1zZWxmLl9oaWxvX3ZlcnNpb24sIGRhZW1vbj1UcnVl
:::KS5zdGFydCgpCgogICAgICAgIGRlZiBfaGlsb192ZXJzaW9uKHNlbGYpOgogICAg
:::ICAgICAgICBjb2xhID0gc2VsZi5jb2xhCgogICAgICAgICAgICBkZWYgbG9nKG0s
:::IHQ9J2luZm8nKToKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwg
:::dCkpCgogICAgICAgICAgICBpZiBZVF9ETFAgaXMgTm9uZToKICAgICAgICAgICAg
:::ICAgIGxvZygneXQtZGxwIG5vIGVzdMOhIGluc3RhbGFkby4gRWplY3V0YSAnCiAg
:::ICAgICAgICAgICAgICAgICAgJ0Rlc2NhcmdhZG9yTXVzaWNhLmJhdCBwYXJhIGlu
:::c3RhbGFybG8uJywgJ2Vycm9yJykKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgn
:::ZmluJywgJ3ZlcnNpb24nLCBUcnVlLCAnJykpCiAgICAgICAgICAgICAgICByZXR1
:::cm4KICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgaW5zdGFsYWRhID0g
:::WVRfRExQLnZlcnNpb24uX192ZXJzaW9uX18KICAgICAgICAgICAgZXhjZXB0IEV4
:::Y2VwdGlvbjoKICAgICAgICAgICAgICAgIGluc3RhbGFkYSA9ICc/JwogICAgICAg
:::ICAgICB1bHRpbWEgPSBOb25lCiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAg
:::ICAgIHdpdGggdXJsb3BlbignaHR0cHM6Ly9weXBpLm9yZy9weXBpL3l0LWRscC9q
:::c29uJywgdGltZW91dD0xMikgYXMgcjoKICAgICAgICAgICAgICAgICAgICB1bHRp
:::bWEgPSBqc29uLmxvYWRzKHIucmVhZCgpLmRlY29kZSgndXRmLTgnKSlbJ2luZm8n
:::XVsndmVyc2lvbiddCiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAg
:::ICAgICAgICAgICB1bHRpbWEgPSBOb25lCiAgICAgICAgICAgIGlmIHVsdGltYSBp
:::cyBOb25lOgogICAgICAgICAgICAgICAgbG9nKGYneXQtZGxwOiB2ZXJzacOzbiB7
:::aW5zdGFsYWRhfSAnCiAgICAgICAgICAgICAgICAgICAgJyhubyBzZSBwdWRvIGNv
:::bXByb2JhciBzaSBoYXkgbm92ZWRhZGVzKS4nLCAnZ3JpcycpCiAgICAgICAgICAg
:::IGVsaWYgc3RyKHVsdGltYSkgPT0gc3RyKGluc3RhbGFkYSk6CiAgICAgICAgICAg
:::ICAgICBsb2coZid5dC1kbHA6IGVuIGxhIHVsdGltYSB2ZXJzaW9uICh7aW5zdGFs
:::YWRhfSkuJywgJ2luZm8nKQogICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAg
:::ICAgbG9nKGYneXQtZGxwOiBoYXkgdmVyc2lvbiBudWV2YSAoe3VsdGltYX0pOyBp
:::bnN0YWxhZGE6ICcKICAgICAgICAgICAgICAgICAgICBmJ3tpbnN0YWxhZGF9LiBQ
:::dWxzYSBDdHJsK1UgcGFyYSBhY3R1YWxpemFyLicsICdhdmlzbycpCiAgICAgICAg
:::ICAgIGlmIEZGTVBFRyBpcyBOb25lOgogICAgICAgICAgICAgICAgbG9nKCdGRm1w
:::ZWc6IE5PIEVOQ09OVFJBRE8g4oCUIGVqZWN1dGEgRGVzY2FyZ2Fkb3JNdXNpY2Eu
:::YmF0ICcKICAgICAgICAgICAgICAgICAgICAncGFyYSBpbnN0YWxhcmxvLicsICdl
:::cnJvcicpCiAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICBsb2coZidG
:::Rm1wZWc6IE9LICh7RkZNUEVHfSknLCAnZ3JpcycpCiAgICAgICAgICAgIGxvZygn
:::Q2FycGV0YSBkZSBndWFyZGFkbzogJyArIHN0cihBSlVTVEVTLmdldCgnZGVzdGlu
:::bycpKSwgJ2dyaXMnKQogICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICd2ZXJz
:::aW9uJywgVHJ1ZSwgJycpKQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBtYWluCmRlZiBt
:::YWluKCk6CiAgICBfcmVjb25maWd1cmFyX3NhbGlkYSgpCiAgICBpZiBub3QgVEtf
:::T0s6CiAgICAgICAgcHJpbnQoJ0VzdGEgYXBsaWNhY2nDs24gbmVjZXNpdGEgVGtp
:::bnRlciAoaW50ZXJmYXogZ3LDoWZpY2EpLicpCiAgICAgICAgcHJpbnQoJ0VsIFB5
:::dGhvbiBhY3R1YWwgbm8gbG8gaW5jbHV5ZS4nKQogICAgICAgIHByaW50KCdWdWVs
:::dmUgYSBlamVjdXRhciBEZXNjYXJnYWRvck11c2ljYS5iYXQgcGFyYSBpbnN0YWxh
:::ciBlbCAnCiAgICAgICAgICAgICAgJ1B5dGhvbiBhZGVjdWFkby4nKQogICAgICAg
:::IHJldHVybiAxCiAgICBjb21wcm9iYXJfZW50b3JubygpCiAgICBhcHAgPSBBcHAo
:::KQogICAgYXBwLm1haW5sb29wKCkKICAgIHJldHVybiAwCgoKaWYgX19uYW1lX18g
:::PT0gJ19fbWFpbl9fJzoKICAgIHRyeToKICAgICAgICBzeXMuZXhpdChtYWluKCkp
:::CiAgICBleGNlcHQgU3lzdGVtRXhpdDoKICAgICAgICByYWlzZQogICAgZXhjZXB0
:::IEJhc2VFeGNlcHRpb246CiAgICAgICAgdHJ5OgogICAgICAgICAgICB3aXRoIG9w
:::ZW4oTE9HX0VSUk9SRVMsICdhJywgZW5jb2Rpbmc9J3V0Zi04JykgYXMgZmg6CiAg
:::ICAgICAgICAgICAgICBmaC53cml0ZSh0cmFjZWJhY2suZm9ybWF0X2V4YygpICsg
:::J1xuJykKICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICBwYXNz
:::CiAgICAgICAgcmFpc2UK
