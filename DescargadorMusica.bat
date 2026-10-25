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
title MusikALAN v2.7
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
echo    %C_TIT%MusikALAN v2.7%C_FIN% - preparando el entorno
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
title MusikALAN v2.7 - YouTube a AAC/MP3/FLAC/WAV/WMA/AVI
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
:::UF9WID0gJzIuNycKQVBQX0RJUiA9IFBhdGgoX19maWxlX18pLnJlc29sdmUoKS5w
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
:::ZGVzYyArIGpwZykKCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gZXRpcXVldGFzCmRlZiBf
:::YXJ0aXN0YV9saW1waW8oaW5mbyk6CiAgICAiIiJOb21icmUgZGVsIGFydGlzdGEg
:::bGVnaWJsZSBwYXJhIHJlcHJvZHVjdG9yZXMuCgogICAgTG9zIGNhbmFsZXMgYXV0
:::b21hdGljb3MgZGUgbXVzaWNhIGRlIFlvdVR1YmUgc2UgbGxhbWFuICdYIC0gVG9w
:::aWMnOwogICAgZXNlIHN1ZmlqbyBzb2JyYSBjdWFuZG8gc2UgdmUgZW4gbGEgcGFu
:::dGFsbGEgZGUgdW4gcmVwcm9kdWN0b3IuIiIiCiAgICBhID0gKGluZm8uZ2V0KCdh
:::cnRpc3QnKSBvciBpbmZvLmdldCgnY3JlYXRvcicpCiAgICAgICAgIG9yIGluZm8u
:::Z2V0KCd1cGxvYWRlcicpIG9yIGluZm8uZ2V0KCdjaGFubmVsJykgb3IgJycpCiAg
:::ICBhID0gc3RyKGEpLnN0cmlwKCkKICAgIGEgPSByZS5zdWIocidccyotXHMqVG9w
:::aWNccyokJywgJycsIGEsIGZsYWdzPXJlLkkpLnN0cmlwKCkKICAgIHJldHVybiBh
:::CgoKZGVmIF9hbGJ1bV9kZShpbmZvKToKICAgICIiIkFsYnVtIHBhcmEgZWwgYXJj
:::aGl2byBmaW5hbC4KCiAgICB5dC1kbHAgc29sbyBlc2NyaWJlIGFsYnVtIHNpIGVs
:::IHByb3BpbyB2aWRlbyBsbyB0cmFlIChjYXNpIG51bmNhKToKICAgIHBvciBlc28g
:::bG9zIHJlcHJvZHVjdG9yZXMgbW9zdHJhYmFuICdhbGJ1bSBkZXNjb25vY2lkbycu
:::IE9yZGVuIGRlCiAgICBwcmVmZXJlbmNpYTogYWxidW0gcmVhbCAtPiBub21icmUg
:::ZGUgbGEgcGxheWxpc3QgLT4gYXJ0aXN0YS4iIiIKICAgIGZvciBjbGF2ZSBpbiAo
:::J2FsYnVtJywgJ3BsYXlsaXN0X3RpdGxlJyk6CiAgICAgICAgdiA9IHN0cihpbmZv
:::LmdldChjbGF2ZSkgb3IgJycpLnN0cmlwKCkKICAgICAgICBpZiB2OgogICAgICAg
:::ICAgICByZXR1cm4gdgogICAgcmV0dXJuIF9hcnRpc3RhX2xpbXBpbyhpbmZvKSBv
:::ciAnWW91VHViZScKCgpkZWYgYXBsaWNhcl90YWdzKGluZm8sIGFyY2hpdm8sIGxv
:::Zz1Ob25lLCBjYXJhdHVsYT1Ob25lKToKICAgICIiIkVzY3JpYmUgY29uIG11dGFn
:::ZW4gbGFzIGV0aXF1ZXRhcyBkZWwgYXJjaGl2byBmaW5hbC4KCiAgICBHYXJhbnRp
:::emEgcXVlIFRPRE9TIGxvcyByZXByb2R1Y3RvcmVzIG11ZXN0cmVuIGFydGlzdGEg
:::eSBhbGJ1bSwKICAgIGF1bnF1ZSBGRm1wZWdNZXRhZGF0YSBkZSB5dC1kbHAgbm8g
:::bG9zIGhheWEgZXNjcml0by4gQ2FkYSBmb3JtYXRvCiAgICBjb24gU1UgZm9ybWEg
:::ZXN0YW5kYXI6CiAgICAgIMK3IE1QMzogSUQzdjIuNCBjb24gdGV4dG9zIFVURi0x
:::NiAoZW5jb2Rpbmc9MSkgeSBBUElDKG1pbWUKICAgICAgICAnaW1hZ2UvanBnJywg
:::dGlwbyAzLCBkZXNjICdhdHRhY2hlZCBwaWN0dXJlJyksIGNhbGNhZG8gZGVsCiAg
:::ICAgICAgTVAzIGRlIHJlZmVyZW5jaWEgcXVlIGVsIHJlcHJvZHVjdG9yIGRlbCB1
:::c3VhcmlvIG11ZXN0cmEKICAgICAgICBiaWVuLiBFbCBwYXNlIGFudGlndW8gdXNh
:::YmEgZW5jb2Rpbmc9MyAoVVRGLTgpIGRlbnRybyBkZSB1bgogICAgICAgIHRhZyB2
:::Mi4zOiBmdWVyYSBkZSBlc3BlY2lmaWNhY2lvbiwgeSBsb3MgcmVwcm9kdWN0b3Jl
:::cwogICAgICAgIGJhcmF0b3MgZGVzY2FydGFiYW4gbGEgZXRpcXVldGEgRU5URVJB
:::IChuaSBhcnRpc3RhLCBuaQogICAgICAgIGFsYnVtLCBuaSBwb3J0YWRhKS4KICAg
:::ICAgwrcgTTRBOiBhdG9tb3MgTVA0IGVzdGFuZGFyICjCqW5hbS/CqUFSVC9hQVJU
:::L8KpYWxiL8KpZGF5L8KpY210KSB5CiAgICAgICAgY292ciBlbiBKUEVHLCBjb21v
:::IGlUdW5lcy4KICAgICAgwrcgV0FWOiBJRDMgZGVudHJvIGRlbCBSSUZGIChtdXRh
:::Z2VuLndhdmUpLCBpZ3VhbCBxdWUgZWwgTVAzLAogICAgICAgIG1hcyBBUElDIGNv
:::biBsYSBjYXJhdHVsYSAobnVldm8gZW4gdjIuNykuCiAgICAgIMK3IEZMQUM6IFZv
:::cmJpcyBjb21tZW50cyArIFBpY3R1cmUgZW4gSlBFRy4KICAgICAgwrcgV01BOiBB
:::U0YgVGl0bGUvQXV0aG9yL1dNL0FsYnVtVGl0bGUvV00vQXV0aG9yVVJMICsgV00v
:::UGljdHVyZS4KICAgICAgwrcgbGEgY2FyYXR1bGEgU0lFTVBSRSBhY2FiYSBlbiBK
:::UEVHIHkgc2UgZXNjcmliZSBBUVVJIGNvbgogICAgICAgIG11dGFnZW46IGRlc2Rl
:::IHYyLjcgRW1iZWRUaHVtYm5haWwgeWEgbm8gdG9jYSBsYSBjYXJhdHVsYQogICAg
:::ICAgIChzdSBtZXRvZG8gY2FtYmlhIGVudHJlIHZlcnNpb25lcyBkZSB5dC1kbHAg
:::eSBhbGd1bmEKICAgICAgICBjb252ZXJzaW9uIHN1eWEgZGVqYWJhIFBORy9XZWJQ
:::IHF1ZSBsb3MgcmVwcm9kdWN0b3JlcwogICAgICAgIGJhcmF0b3Mgbm8gbGVlbik7
:::CiAgICAgIMK3IGVsIGNvbWVudGFyaW8gZ3VhcmRhIGxhIFVSTCBkZWwgdmlkZW8g
:::KGNvbW8gZWwgc2NyaXB0IGFudGlndW8pLgogICAgYGNhcmF0dWxhYCBzb24gbG9z
:::IGJ5dGVzIGRlIGxhIG1pbmlhdHVyYSBkZXNjYXJnYWRhIChvcGNpb25hbCkuIiIi
:::CiAgICB0cnk6CiAgICAgICAgcCA9IFBhdGgoYXJjaGl2bykKICAgICAgICBpZiBu
:::b3QgcC5leGlzdHMoKToKICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgYXJ0aXN0
:::YSA9IF9hcnRpc3RhX2xpbXBpbyhpbmZvKQogICAgICAgIGFsYnVtID0gX2FsYnVt
:::X2RlKGluZm8pCiAgICAgICAgdGl0dWxvID0gc3RyKGluZm8uZ2V0KCd0cmFjaycp
:::IG9yIGluZm8uZ2V0KCd0aXRsZScpIG9yICcnKS5zdHJpcCgpCiAgICAgICAgZmVj
:::aGEgPSBzdHIoaW5mby5nZXQoJ3JlbGVhc2VfeWVhcicpIG9yICcnKQogICAgICAg
:::IGlmIG5vdCBmZWNoYToKICAgICAgICAgICAgZmVjaGEgPSBzdHIoaW5mby5nZXQo
:::J3VwbG9hZF9kYXRlJykgb3IgJycpCiAgICAgICAgICAgIGlmIGxlbihmZWNoYSkg
:::PT0gOCBhbmQgZmVjaGEuaXNkaWdpdCgpOgogICAgICAgICAgICAgICAgZmVjaGEg
:::PSBmZWNoYVs6NF0KICAgICAgICB1cmwgPSBzdHIoaW5mby5nZXQoJ3dlYnBhZ2Vf
:::dXJsJykgb3IgJycpLnN0cmlwKCkKICAgICAgICBpZiBjYXJhdHVsYSBhbmQgbm90
:::IF9lc19qcGcoY2FyYXR1bGEpOgogICAgICAgICAgICBjYXJhdHVsYSA9IF9hX2pw
:::ZyhjYXJhdHVsYSkKICAgICAgICBleHQgPSBwLnN1ZmZpeC5sb3dlcigpCiAgICAg
:::ICAgaWYgZXh0ID09ICcubTRhJzoKICAgICAgICAgICAgZnJvbSBtdXRhZ2VuLm1w
:::NCBpbXBvcnQgTVA0LCBNUDRDb3ZlcgogICAgICAgICAgICBtID0gTVA0KHN0cihw
:::KSkKICAgICAgICAgICAgaWYgdGl0dWxvOgogICAgICAgICAgICAgICAgbVsnXHhh
:::OW5hbSddID0gW3RpdHVsb10KICAgICAgICAgICAgaWYgYXJ0aXN0YToKICAgICAg
:::ICAgICAgICAgIG1bJ1x4YTlBUlQnXSA9IFthcnRpc3RhXQogICAgICAgICAgICAg
:::ICAgbVsnYUFSVCddID0gW2FydGlzdGFdCiAgICAgICAgICAgIGlmIGFsYnVtOgog
:::ICAgICAgICAgICAgICAgbVsnXHhhOWFsYiddID0gW2FsYnVtXQogICAgICAgICAg
:::ICBpZiBmZWNoYToKICAgICAgICAgICAgICAgIG1bJ1x4YTlkYXknXSA9IFtmZWNo
:::YV0KICAgICAgICAgICAgaWYgdXJsOgogICAgICAgICAgICAgICAgbVsnXHhhOWNt
:::dCddID0gW3VybF0KICAgICAgICAgICAgIyAtLSBjYXJhdHVsYTogZGVzZGUgdjIu
:::NyBsYSBlc2NyaWJlIFNJRU1QUkUgZXN0ZSBwYXNlIGNvbgogICAgICAgICAgICAj
:::ICAgIG11dGFnZW4gKEVtYmVkVGh1bWJuYWlsIHlhIG5vIHBhcnRpY2lwYSkuIEF0
:::b21vCiAgICAgICAgICAgICMgICAgZXN0YW5kYXIgJ2NvdnInIChzaW4gZWwgcHJl
:::ZmlqbyAoYykpOyBlbiBtdXRhZ2VuCiAgICAgICAgICAgICMgICAgbW9kZXJubyBl
:::c2NyaWJpciAnXHhhOWNvdnInIGxhbnphIFR5cGVFcnJvci4KICAgICAgICAgICAg
:::dmllamFzID0gbS5nZXQoJ2NvdnInKSBvciBtLmdldCgnXHhhOWNvdnInKSBvciBb
:::XQogICAgICAgICAgICBpZiBub3QgdmllamFzOgogICAgICAgICAgICAgICAgaWYg
:::Y2FyYXR1bGE6CiAgICAgICAgICAgICAgICAgICAgbVsnY292ciddID0gW01QNENv
:::dmVyKGNhcmF0dWxhLCBNUDRDb3Zlci5GT1JNQVRfSlBFRyldCiAgICAgICAgICAg
:::IGVsaWYgYWxsKGMuaW1hZ2Vmb3JtYXQgIT0gTVA0Q292ZXIuRk9STUFUX0pQRUcK
:::ICAgICAgICAgICAgICAgICAgICAgZm9yIGMgaW4gdmllamFzKToKICAgICAgICAg
:::ICAgICAgIG51ZXZhID0gX2FfanBnKGJ5dGVzKHZpZWphc1swXSkpIG9yIGNhcmF0
:::dWxhCiAgICAgICAgICAgICAgICBpZiBudWV2YToKICAgICAgICAgICAgICAgICAg
:::ICBtWydjb3ZyJ10gPSBbTVA0Q292ZXIobnVldmEsIE1QNENvdmVyLkZPUk1BVF9K
:::UEVHKV0KICAgICAgICAgICAgICAgICAgICBtLnBvcCgnXHhhOWNvdnInLCBOb25l
:::KQogICAgICAgICAgICBlbGlmIG0uZ2V0KCdceGE5Y292cicpOgogICAgICAgICAg
:::ICAgICAgbVsnY292ciddID0gdmllamFzCiAgICAgICAgICAgICAgICBtLnBvcCgn
:::XHhhOWNvdnInLCBOb25lKQogICAgICAgICAgICBtLnNhdmUoKQogICAgICAgIGVs
:::aWYgZXh0ID09ICcubXAzJzoKICAgICAgICAgICAgIyBGb3JtYXRvIEVYQUNUTyBk
:::ZWwgTVAzIGRlIHJlZmVyZW5jaWEgKFNuYXB0dWJlLCBlc2NyaXRvIHBvcgogICAg
:::ICAgICAgICAjIEZGbXBlZy9MYXZmKSBxdWUgZWwgcmVwcm9kdWN0b3IgZGVsIHVz
:::dWFyaW8gU0kgbXVlc3RyYToKICAgICAgICAgICAgIyAgIElEM3YyLjQuMCArIFRJ
:::VDIvVFBFMS9UQUxCL0FQSUMgZW4gZW5jb2Rpbmc9MSAoVVRGLTE2IGNvbgogICAg
:::ICAgICAgICAjICAgQk9NKSArIEFQSUMobWltZSAnaW1hZ2UvanBnJywgdGlwbyAz
:::ID0gQ09WRVJfRlJPTlQsIGRlc2MKICAgICAgICAgICAgIyAgICdhdHRhY2hlZCBw
:::aWN0dXJlJywgSlBFRyByZWFsKS4gRWwgcGFzZSBhbnRlcmlvciBlc2NyaWJpYQog
:::ICAgICAgICAgICAjICAgZW5jb2Rpbmc9MyAoVVRGLTgpIGRlbnRybyBkZSB1biB0
:::YWcgdjIuMzogZnVlcmEgZGUKICAgICAgICAgICAgIyAgIGVzcGVjaWZpY2FjaW9u
:::LCB5IGxvcyByZXByb2R1Y3RvcmVzIGJhcmF0b3MgZGVzY2FydGFiYW4KICAgICAg
:::ICAgICAgIyAgIGxhIGV0aXF1ZXRhIGVudGVyYSAobmkgYXJ0aXN0YSwgbmkgYWxi
:::dW0sIG5pIHBvcnRhZGEpLgogICAgICAgICAgICBmcm9tIG11dGFnZW4uaWQzIGlt
:::cG9ydCAoQVBJQywgQ09NTSwgSUQzLCBUQUxCLCBURFJDLCBUSVQyLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgVExFTiwgVFBFMSwgVFBFMikK
:::ICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgdGFncyA9IElEMyhzdHIo
:::cCkpCiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgICAg
:::ICB0YWdzID0gSUQzKCkKICAgICAgICAgICAgaWYgdGl0dWxvOgogICAgICAgICAg
:::ICAgICAgdGFncy5zZXRhbGwoJ1RJVDInLCBbVElUMihlbmNvZGluZz0xLCB0ZXh0
:::PVt0aXR1bG9dKV0pCiAgICAgICAgICAgIGlmIGFydGlzdGE6CiAgICAgICAgICAg
:::ICAgICB0YWdzLnNldGFsbCgnVFBFMScsIFtUUEUxKGVuY29kaW5nPTEsIHRleHQ9
:::W2FydGlzdGFdKV0pCiAgICAgICAgICAgICAgICB0YWdzLnNldGFsbCgnVFBFMics
:::IFtUUEUyKGVuY29kaW5nPTEsIHRleHQ9W2FydGlzdGFdKV0pCiAgICAgICAgICAg
:::IGlmIGFsYnVtOgogICAgICAgICAgICAgICAgdGFncy5zZXRhbGwoJ1RBTEInLCBb
:::VEFMQihlbmNvZGluZz0xLCB0ZXh0PVthbGJ1bV0pXSkKICAgICAgICAgICAgaWYg
:::ZmVjaGE6CiAgICAgICAgICAgICAgICB0YWdzLnNldGFsbCgnVERSQycsIFtURFJD
:::KGVuY29kaW5nPTEsIHRleHQ9W2ZlY2hhXSldKQogICAgICAgICAgICBkdXIgPSBp
:::bmZvLmdldCgnZHVyYXRpb24nKQogICAgICAgICAgICBpZiBkdXI6CiAgICAgICAg
:::ICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICAgICAgdGFncy5zZXRhbGwoJ1RM
:::RU4nLCBbVExFTihlbmNvZGluZz0wLCB0ZXh0PVsKICAgICAgICAgICAgICAgICAg
:::ICAgICAgc3RyKGludChmbG9hdChkdXIpICogMTAwMCkpXSldKQogICAgICAgICAg
:::ICAgICAgZXhjZXB0IChUeXBlRXJyb3IsIFZhbHVlRXJyb3IpOgogICAgICAgICAg
:::ICAgICAgICAgIHBhc3MKICAgICAgICAgICAgaWYgdXJsOgogICAgICAgICAgICAg
:::ICAgdGFncy5zZXRhbGwoJ0NPTU0nLCBbQ09NTShlbmNvZGluZz0xLCBsYW5nPSdl
:::bmcnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBk
:::ZXNjPScnLCB0ZXh0PVt1cmxdKV0pCiAgICAgICAgICAgICMgUG9ydGFkYTogbWlz
:::bWFzIGNvbnN0YW50ZXMgZGVsIGFyY2hpdm8gZGUgcmVmZXJlbmNpYS4KICAgICAg
:::ICAgICAgIyBCeXRlczogYGNhcmF0dWxhYCBvLCBzaSBFbWJlZFRodW1ibmFpbCB5
:::YSBpbmNydXN0byBhbGdvLAogICAgICAgICAgICAjIGxvcyBkYXRvcyBkZWwgQVBJ
:::QyBleGlzdGVudGU7IHNpZW1wcmUgYWNhYmFtb3MgZW4gSlBFRy4KICAgICAgICAg
:::ICAgZGF0b3MgPSBjYXJhdHVsYQogICAgICAgICAgICBpZiBub3QgZGF0b3M6CiAg
:::ICAgICAgICAgICAgICBhcGljcyA9IHRhZ3MuZ2V0YWxsKCdBUElDJykKICAgICAg
:::ICAgICAgICAgIGlmIGFwaWNzOgogICAgICAgICAgICAgICAgICAgIGRhdG9zID0g
:::YXBpY3NbMF0uZGF0YQogICAgICAgICAgICBpZiBkYXRvcyBhbmQgbm90IF9lc19q
:::cGcoZGF0b3MpOgogICAgICAgICAgICAgICAgZGF0b3MgPSBfYV9qcGcoZGF0b3Mp
:::CiAgICAgICAgICAgIGlmIGRhdG9zOgogICAgICAgICAgICAgICAgdGFncy5zZXRh
:::bGwoJ0FQSUMnLCBbQVBJQyhlbmNvZGluZz0xLCBtaW1lPSdpbWFnZS9qcGcnLAog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB0eXBlPTMs
:::IGRlc2M9J2F0dGFjaGVkIHBpY3R1cmUnLAogICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICBkYXRhPWRhdG9zKV0pCiAgICAgICAgICAgICMg
:::djIuNCArIFVURi0xNjogbGEgbWlzbWEgY29tYmluYWNpb24gZGVsIGFyY2hpdm8g
:::ZGUKICAgICAgICAgICAgIyByZWZlcmVuY2lhIChJRDN2Mi40LjAgZXNjcml0byBw
:::b3IgTGF2ZjYwLjMuMTAwKS4KICAgICAgICAgICAgdGFncy5zYXZlKHN0cihwKSwg
:::djJfdmVyc2lvbj00KQogICAgICAgIGVsaWYgZXh0ID09ICcud2F2JzoKICAgICAg
:::ICAgICAgZnJvbSBtdXRhZ2VuLmlkMyBpbXBvcnQgKEFQSUMsIENPTU0sIFREUkMs
:::IFRJVDIsIFRMRU4sIFRQRTEsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICBUUEUyLCBUQUxCKQogICAgICAgICAgICBmcm9tIG11dGFnZW4ud2F2
:::ZSBpbXBvcnQgV0FWRQogICAgICAgICAgICB3ID0gV0FWRShzdHIocCkpCiAgICAg
:::ICAgICAgIGlmIHcudGFncyBpcyBOb25lOgogICAgICAgICAgICAgICAgdy5hZGRf
:::dGFncygpCiAgICAgICAgICAgICMgZW5jb2Rpbmc9MSAoVVRGLTE2KSwgbWlzbWEg
:::cmVnbGEgcXVlIGVuIE1QMzogbG9zCiAgICAgICAgICAgICMgcmVwcm9kdWN0b3Jl
:::cyBiYXJhdG9zIG5vIHBhcnNlYW4gZnJhbWVzIFVURi04LgogICAgICAgICAgICBp
:::ZiB0aXR1bG86CiAgICAgICAgICAgICAgICB3LnRhZ3Muc2V0YWxsKCdUSVQyJywg
:::W1RJVDIoZW5jb2Rpbmc9MSwgdGV4dD1bdGl0dWxvXSldKQogICAgICAgICAgICBp
:::ZiBhcnRpc3RhOgogICAgICAgICAgICAgICAgdy50YWdzLnNldGFsbCgnVFBFMScs
:::IFtUUEUxKGVuY29kaW5nPTEsIHRleHQ9W2FydGlzdGFdKV0pCiAgICAgICAgICAg
:::ICAgICB3LnRhZ3Muc2V0YWxsKCdUUEUyJywgW1RQRTIoZW5jb2Rpbmc9MSwgdGV4
:::dD1bYXJ0aXN0YV0pXSkKICAgICAgICAgICAgaWYgYWxidW06CiAgICAgICAgICAg
:::ICAgICB3LnRhZ3Muc2V0YWxsKCdUQUxCJywgW1RBTEIoZW5jb2Rpbmc9MSwgdGV4
:::dD1bYWxidW1dKV0pCiAgICAgICAgICAgIGlmIGZlY2hhOgogICAgICAgICAgICAg
:::ICAgdy50YWdzLnNldGFsbCgnVERSQycsIFtURFJDKGVuY29kaW5nPTEsIHRleHQ9
:::W2ZlY2hhXSldKQogICAgICAgICAgICBkdXIgPSBpbmZvLmdldCgnZHVyYXRpb24n
:::KQogICAgICAgICAgICBpZiBkdXI6CiAgICAgICAgICAgICAgICB0cnk6CiAgICAg
:::ICAgICAgICAgICAgICAgdy50YWdzLnNldGFsbCgnVExFTicsIFtUTEVOKGVuY29k
:::aW5nPTAsIHRleHQ9WwogICAgICAgICAgICAgICAgICAgICAgICBzdHIoaW50KGZs
:::b2F0KGR1cikgKiAxMDAwKSldKV0pCiAgICAgICAgICAgICAgICBleGNlcHQgKFR5
:::cGVFcnJvciwgVmFsdWVFcnJvcik6CiAgICAgICAgICAgICAgICAgICAgcGFzcwog
:::ICAgICAgICAgICBpZiB1cmw6CiAgICAgICAgICAgICAgICB3LnRhZ3Muc2V0YWxs
:::KCdDT01NJywgW0NPTU0oZW5jb2Rpbmc9MSwgbGFuZz0nZW5nJywKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZXNjPScnLCB0ZXh0
:::PVt1cmxdKV0pCiAgICAgICAgICAgICMgdjIuNzogY2FyYXR1bGEgZW4gZWwgSUQz
:::IGRlbCBXQVYgKG1pc21hcyBjb25zdGFudGVzIHF1ZQogICAgICAgICAgICAjIGVs
:::IE1QMyBkZSByZWZlcmVuY2lhKSwgcGFyYSBsb3MgcmVwcm9kdWN0b3JlcyBxdWUg
:::bGVlbgogICAgICAgICAgICAjIGVsIGNodW5rICdpZDMgJyBkZW50cm8gZGVsIFJJ
:::RkYuCiAgICAgICAgICAgIGRhdG9zID0gY2FyYXR1bGEKICAgICAgICAgICAgaWYg
:::bm90IGRhdG9zOgogICAgICAgICAgICAgICAgYXBpY3MgPSB3LnRhZ3MuZ2V0YWxs
:::KCdBUElDJykKICAgICAgICAgICAgICAgIGlmIGFwaWNzOgogICAgICAgICAgICAg
:::ICAgICAgIGRhdG9zID0gYXBpY3NbMF0uZGF0YQogICAgICAgICAgICBpZiBkYXRv
:::cyBhbmQgbm90IF9lc19qcGcoZGF0b3MpOgogICAgICAgICAgICAgICAgZGF0b3Mg
:::PSBfYV9qcGcoZGF0b3MpCiAgICAgICAgICAgIGlmIGRhdG9zOgogICAgICAgICAg
:::ICAgICAgdy50YWdzLnNldGFsbCgnQVBJQycsIFtBUElDKGVuY29kaW5nPTEsIG1p
:::bWU9J2ltYWdlL2pwZycsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgdHlwZT0zLCBkZXNjPSdhdHRhY2hlZCBwaWN0dXJlJywKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkYXRhPWRh
:::dG9zKV0pCiAgICAgICAgICAgIHcuc2F2ZSgpCiAgICAgICAgZWxpZiBleHQgPT0g
:::Jy5mbGFjJzoKICAgICAgICAgICAgZnJvbSBtdXRhZ2VuLmZsYWMgaW1wb3J0IEZM
:::QUMsIFBpY3R1cmUKICAgICAgICAgICAgZiA9IEZMQUMoc3RyKHApKQogICAgICAg
:::ICAgICBpZiB0aXR1bG86CiAgICAgICAgICAgICAgICBmWyd0aXRsZSddID0gW3Rp
:::dHVsb10KICAgICAgICAgICAgaWYgYXJ0aXN0YToKICAgICAgICAgICAgICAgIGZb
:::J2FydGlzdCddID0gW2FydGlzdGFdCiAgICAgICAgICAgICAgICBmWydhbGJ1bWFy
:::dGlzdCddID0gW2FydGlzdGFdCiAgICAgICAgICAgIGlmIGFsYnVtOgogICAgICAg
:::ICAgICAgICAgZlsnYWxidW0nXSA9IFthbGJ1bV0KICAgICAgICAgICAgaWYgZmVj
:::aGE6CiAgICAgICAgICAgICAgICBmWydkYXRlJ10gPSBbZmVjaGFdCiAgICAgICAg
:::ICAgIGlmIHVybDoKICAgICAgICAgICAgICAgIGZbJ2NvbW1lbnQnXSA9IFt1cmxd
:::CiAgICAgICAgICAgIGlmIG5vdCBmLnBpY3R1cmVzOgogICAgICAgICAgICAgICAg
:::aWYgY2FyYXR1bGE6CiAgICAgICAgICAgICAgICAgICAgcGljID0gUGljdHVyZSgp
:::CiAgICAgICAgICAgICAgICAgICAgcGljLm1pbWUsIHBpYy50eXBlLCBwaWMuZGVz
:::YyA9ICdpbWFnZS9qcGVnJywgMywgJ0NvdmVyJwogICAgICAgICAgICAgICAgICAg
:::IHBpYy5kYXRhID0gY2FyYXR1bGEKICAgICAgICAgICAgICAgICAgICBmLmFkZF9w
:::aWN0dXJlKHBpYykKICAgICAgICAgICAgZWxpZiBhbGwocGkubWltZSAhPSAnaW1h
:::Z2UvanBlZycgZm9yIHBpIGluIGYucGljdHVyZXMpOgogICAgICAgICAgICAgICAg
:::bnVldmEgPSBfYV9qcGcoZi5waWN0dXJlc1swXS5kYXRhKSBvciBjYXJhdHVsYQog
:::ICAgICAgICAgICAgICAgaWYgbnVldmE6CiAgICAgICAgICAgICAgICAgICAgZm9y
:::IHZpZWphIGluIGxpc3QoZi5waWN0dXJlcyk6CiAgICAgICAgICAgICAgICAgICAg
:::ICAgIGYucmVtb3ZlX3BpY3R1cmUodmllamEpCiAgICAgICAgICAgICAgICAgICAg
:::cGljID0gUGljdHVyZSgpCiAgICAgICAgICAgICAgICAgICAgcGljLm1pbWUsIHBp
:::Yy50eXBlLCBwaWMuZGVzYyA9ICdpbWFnZS9qcGVnJywgMywgJ0NvdmVyJwogICAg
:::ICAgICAgICAgICAgICAgIHBpYy5kYXRhID0gbnVldmEKICAgICAgICAgICAgICAg
:::ICAgICBmLmFkZF9waWN0dXJlKHBpYykKICAgICAgICAgICAgZi5zYXZlKCkKICAg
:::ICAgICBlbGlmIGV4dCA9PSAnLndtYSc6CiAgICAgICAgICAgIGZyb20gbXV0YWdl
:::bi5hc2YgaW1wb3J0IEFTRiwgQVNGQnl0ZUFycmF5QXR0cmlidXRlCiAgICAgICAg
:::ICAgIGEgPSBBU0Yoc3RyKHApKQogICAgICAgICAgICBpZiB0aXR1bG86CiAgICAg
:::ICAgICAgICAgICBhWydUaXRsZSddID0gW3RpdHVsb10KICAgICAgICAgICAgaWYg
:::YXJ0aXN0YToKICAgICAgICAgICAgICAgIGFbJ0F1dGhvciddID0gW2FydGlzdGFd
:::CiAgICAgICAgICAgICAgICBhWydXTS9BbGJ1bUFydGlzdCddID0gW2FydGlzdGFd
:::CiAgICAgICAgICAgIGlmIGFsYnVtOgogICAgICAgICAgICAgICAgYVsnV00vQWxi
:::dW1UaXRsZSddID0gW2FsYnVtXQogICAgICAgICAgICBpZiBmZWNoYToKICAgICAg
:::ICAgICAgICAgIGFbJ1dNL1llYXInXSA9IFtmZWNoYV0KICAgICAgICAgICAgaWYg
:::dXJsOgogICAgICAgICAgICAgICAgYVsnRGVzY3JpcHRpb24nXSA9IFt1cmxdCiAg
:::ICAgICAgICAgICAgICBhWydXTS9BdXRob3JVUkwnXSA9IFt1cmxdCiAgICAgICAg
:::ICAgIGlmIGNhcmF0dWxhOgogICAgICAgICAgICAgICAgYVsnV00vUGljdHVyZSdd
:::ID0gW0FTRkJ5dGVBcnJheUF0dHJpYnV0ZSgKICAgICAgICAgICAgICAgICAgICBf
:::d21fcGljdHVyZShjYXJhdHVsYSwgdGl0dWxvIG9yICdDb3ZlcicpKV0KICAgICAg
:::ICAgICAgYS5zYXZlKCkKICAgICAgICBlbHNlOgogICAgICAgICAgICByZXR1cm4K
:::ICAgICAgICBpZiBsb2c6CiAgICAgICAgICAgIGV4dHJhID0gJyDCtyBjYXLDoXR1
:::bGEgSlBFRycgaWYgY2FyYXR1bGEgZWxzZSAnJwogICAgICAgICAgICBsb2coJ0V0
:::aXF1ZXRhcyBlc2NyaXRhczogYXJ0aXN0YSDCqyVzwrsgwrcgw6FsYnVtIMKrJXPC
:::uyVzJwogICAgICAgICAgICAgICAgJSAoYXJ0aXN0YSBvciAn4oCUJywgYWxidW0g
:::b3IgJ+KAlCcsIGV4dHJhKSwgJ2dyaXMnKQogICAgZXhjZXB0IEV4Y2VwdGlvbiBh
:::cyBlOgogICAgICAgICMgbGFzIGV0aXF1ZXRhcyBubyBzb24gY3JpdGljYXM6IG51
:::bmNhIGRlYmVuIHJvbXBlciBsYSBkZXNjYXJnYQogICAgICAgIGlmIGxvZzoKICAg
:::ICAgICAgICAgbG9nKCdObyBzZSBwdWRpZXJvbiBlc2NyaWJpciB0b2RhcyBsYXMg
:::ZXRpcXVldGFzOiAlcycgJSBlLAogICAgICAgICAgICAgICAgJ2F2aXNvJykKCgoj
:::IC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0gZGVzY2FyZ2FzCmRlZiBkZXNjYXJnYXJfYXVkaW8o
:::dXJsLCBub21icmVfZm10LCBjYWxpZGFkLCBkZXN0aW5vLCBlbWJlYmVyLCBjb2xh
:::KToKICAgICIiIkFBQyAoLm00YSkgLyBNUDMgLyBGTEFDIC8gV0FWIHbDrWEgcG9z
:::dHByb2Nlc2Fkb3JlcyBkZSB5dC1kbHAuCgogICAgeXQtZGxwIFNPTE8gYmFqYSwg
:::Y29udmllcnRlIHkgZXNjcmliZSBsb3MgbWV0YWRhdG9zIGRlIHRleHRvCiAgICAo
:::RkZtcGVnTWV0YWRhdGEpLiBMYSBjYXLDoXR1bGEgTk8gbGEgaW5jcnVzdGEgRW1i
:::ZWRUaHVtYm5haWw6IGRlc2RlCiAgICB2Mi43IGxhIGVzY3JpYmUgYXBsaWNhcl90
:::YWdzIGNvbiBtdXRhZ2VuIChjb3ZyIGVuIG00YSwgQVBJQyBlbgogICAgbXAzL3dh
:::diwgUGljdHVyZSBlbiBmbGFjKSwgc2llbXByZSBlbiBKUEVHIHkgY29uIGxhIGVz
:::dHJ1Y3R1cmEKICAgIGV4YWN0YSBxdWUgbGVlbiBsb3MgcmVwcm9kdWN0b3Jlcy4g
:::QXPDrSBlbCByZXN1bHRhZG8gbm8gZGVwZW5kZSBkZQogICAgbG9zIG3DqXRvZG9z
:::IGludGVybm9zIGRlIEVtYmVkVGh1bWJuYWlsLCBxdWUgY2FtYmlhbiBlbnRyZQog
:::ICAgdmVyc2lvbmVzIGRlIHl0LWRscCAoYW50ZXMgY29udmVydMOtYSBsYSBwb3J0
:::YWRhIGEgUE5HLCB5IHN1CiAgICBtw6l0b2RvIGZmbXBlZyBhZGp1bnRhIGxhIGlt
:::YWdlbiBjb21vIHN0cmVhbSBkZSB2w61kZW8pLiIiIgogICAgZGVmIGxvZyhtLCB0
:::PSdpbmZvJyk6CiAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICBm
:::bXQgPSBGT1JNQVRPU1tub21icmVfZm10XQogICAgY2FycGV0YSA9IGRlc3Rpbm8g
:::ICAgICAgICAgIyB2Mi4zOiBzaW4gc3ViY2FycGV0YXMgcG9yIGZvcm1hdG8KICAg
:::IGNhcnBldGEubWtkaXIocGFyZW50cz1UcnVlLCBleGlzdF9vaz1UcnVlKQogICAg
:::Y29kZWMgPSBmbXRbJ2V4dCddCiAgICBjb25fcG9ydGFkYSA9IGVtYmViZXIgYW5k
:::IG5vbWJyZV9mbXQgaW4gKCdBQUMnLCAnTVAzJywgJ0ZMQUMnLCAnV0FWJykKICAg
:::IGNvbl90YWdzID0gZW1iZWJlcgogICAgcHBzID0gW10KICAgIGlmIGNvbl9wb3J0
:::YWRhOgogICAgICAgIHBwcy5hcHBlbmQoeydrZXknOiAnRkZtcGVnVGh1bWJuYWls
:::c0NvbnZlcnRvcicsICdmb3JtYXQnOiAnanBnJywKICAgICAgICAgICAgICAgICAg
:::ICAnd2hlbic6ICdiZWZvcmVfZGwnfSkKICAgIHBwcy5hcHBlbmQoeydrZXknOiAn
:::RkZtcGVnRXh0cmFjdEF1ZGlvJywgJ3ByZWZlcnJlZGNvZGVjJzogY29kZWMsCiAg
:::ICAgICAgICAgICAgICAncHJlZmVycmVkcXVhbGl0eSc6IGNhbGlkYWQgb3IgJzAn
:::fSkKICAgIGlmIGNvbl90YWdzOgogICAgICAgIHBwcy5hcHBlbmQoeydrZXknOiAn
:::RkZtcGVnTWV0YWRhdGEnLCAnYWRkX21ldGFkYXRhJzogVHJ1ZX0pCiAgICAjIHYy
:::Ljc6IFNJTiBFbWJlZFRodW1ibmFpbC4gTGEgbWluaWF0dXJhIChkZWphZGEgZW4g
:::LmpwZyBqdW50byBhbAogICAgIyBhcmNoaXZvIHBvciB3cml0ZXRodW1ibmFpbCAr
:::IENvbnZlcnRvcikgbGEgaW5jcnVzdGEgYXBsaWNhcl90YWdzCiAgICAjIGNvbiBt
:::dXRhZ2VuOiBlc3RydWN0dXJhIGdhcmFudGl6YWRhIGVuIHRvZG9zIGxvcyBmb3Jt
:::YXRvcyB5IHNpbgogICAgIyBkZXBlbmRlciBkZSBsb3MgbcOpdG9kb3MgaW50ZXJu
:::b3MgZGUgeXQtZGxwLgogICAgbyA9IG9wdHNfYmFzZShjYXJwZXRhLCBjb2xhKQog
:::ICAgb1snZm9ybWF0J10gPSAnYmVzdGF1ZGlvL2Jlc3QnCiAgICBvWydwb3N0cHJv
:::Y2Vzc29ycyddID0gcHBzCiAgICBvWyd3cml0ZXRodW1ibmFpbCddID0gY29uX3Bv
:::cnRhZGEKICAgIHdpdGggWVRfRExQLllvdXR1YmVETChvKSBhcyB5ZGw6CiAgICAg
:::ICAgaW5mbyA9IHlkbC5leHRyYWN0X2luZm8odXJsLCBkb3dubG9hZD1UcnVlKQog
:::ICAgYXJjaGl2byA9IGFyY2hpdm9fZmluYWwoaW5mbywgY2FycGV0YSwgY29kZWMp
:::CiAgICBjYXJhdHVsYSA9IF9taW5pYXR1cmFfYnl0ZXMoY2FycGV0YSwgYXJjaGl2
:::bykKICAgIGlmIGFyY2hpdm8gYW5kIGNvbl9wb3J0YWRhOgogICAgICAgIGxpbXBp
:::YXJfbWluaWF0dXJhcyhjYXJwZXRhLCBhcmNoaXZvKQogICAgaWYgYXJjaGl2bzoK
:::ICAgICAgICBhcGxpY2FyX3RhZ3MoaW5mbywgYXJjaGl2bywgbG9nLCBjYXJhdHVs
:::YSkKICAgIHJldHVybiBpbmZvLCBhcmNoaXZvCgoKZGVmIGRlc2Nhcmdhcl93bWEo
:::dXJsLCBjYWxpZGFkLCBkZXN0aW5vLCBlbWJlYmVyLCBjb2xhKToKICAgICIiIldN
:::QSA5Ni8xMjgga2JwczogeXQtZGxwIG5vIHNvcG9ydGEgd21hLCBhc8OtIHF1ZSBz
:::ZSBiYWphIGEgV0FWIChjb24KICAgIGV0aXF1ZXRhcykgeSBsdWVnbyBGRm1wZWcg
:::cmVjb2RpZmljYSBhIHdtYXYyIGRlbnRybyBkZWwgLndtYSBmaW5hbC4KICAgIExh
:::IGNhcsOhdHVsYSAoV00vUGljdHVyZSwgZW4gSlBFRykgeSBsYSBVUkwgKFdNL0F1
:::dGhvclVSTCkgc2UKICAgIGluY3J1c3RhbiBjb24gbXV0YWdlbiwgY29tbyBlbiBl
:::bCBzY3JpcHQgYW50aWd1by4iIiIKICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgog
:::ICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgY2FycGV0YSA9IGRl
:::c3Rpbm8gICAgICAgICAgIyB2Mi4zOiBzaW4gc3ViY2FycGV0YXMgcG9yIGZvcm1h
:::dG8KICAgIHRtcCA9IGNhcnBldGEgLyAnX3RtcCcKICAgIHNodXRpbC5ybXRyZWUo
:::dG1wLCBpZ25vcmVfZXJyb3JzPVRydWUpCiAgICB0bXAubWtkaXIocGFyZW50cz1U
:::cnVlLCBleGlzdF9vaz1UcnVlKQogICAgbyA9IG9wdHNfYmFzZSh0bXAsIGNvbGEp
:::CiAgICBvWydmb3JtYXQnXSA9ICdiZXN0YXVkaW8vYmVzdCcKICAgIHBwcyA9IFt7
:::J2tleSc6ICdGRm1wZWdFeHRyYWN0QXVkaW8nLCAncHJlZmVycmVkY29kZWMnOiAn
:::d2F2JywKICAgICAgICAgICAgJ3ByZWZlcnJlZHF1YWxpdHknOiAnMCd9XQogICAg
:::aWYgZW1iZWJlcjoKICAgICAgICBwcHMuaW5zZXJ0KDAsIHsna2V5JzogJ0ZGbXBl
:::Z1RodW1ibmFpbHNDb252ZXJ0b3InLAogICAgICAgICAgICAgICAgICAgICAgICdm
:::b3JtYXQnOiAnanBnJywgJ3doZW4nOiAnYmVmb3JlX2RsJ30pCiAgICAgICAgcHBz
:::LmFwcGVuZCh7J2tleSc6ICdGRm1wZWdNZXRhZGF0YScsICdhZGRfbWV0YWRhdGEn
:::OiBUcnVlfSkKICAgIG9bJ3Bvc3Rwcm9jZXNzb3JzJ10gPSBwcHMKICAgIG9bJ3dy
:::aXRldGh1bWJuYWlsJ10gPSBlbWJlYmVyCiAgICB3aXRoIFlUX0RMUC5Zb3V0dWJl
:::REwobykgYXMgeWRsOgogICAgICAgIGluZm8gPSB5ZGwuZXh0cmFjdF9pbmZvKHVy
:::bCwgZG93bmxvYWQ9VHJ1ZSkKICAgIHdhdiA9IGFyY2hpdm9fZmluYWwoaW5mbywg
:::dG1wLCAnd2F2JykKICAgIGlmIG5vdCB3YXY6CiAgICAgICAgcmFpc2UgUnVudGlt
:::ZUVycm9yKCdObyBzZSBlbmNvbnRyw7MgZWwgV0FWIGludGVybWVkaW8uJykKICAg
:::IG1ldGEgPSBbXQogICAgaWYgZW1iZWJlcjoKICAgICAgICBhcnRpc3RhID0gKGlu
:::Zm8uZ2V0KCdhcnRpc3QnKSBvciBpbmZvLmdldCgndXBsb2FkZXInKQogICAgICAg
:::ICAgICAgICAgICAgb3IgaW5mby5nZXQoJ2NoYW5uZWwnKSBvciAnJykKICAgICAg
:::ICBpZiBpbmZvLmdldCgndGl0bGUnKToKICAgICAgICAgICAgbWV0YSArPSBbJy1t
:::ZXRhZGF0YScsICd0aXRsZT0nICsgc3RyKGluZm9bJ3RpdGxlJ10pXQogICAgICAg
:::IGlmIGFydGlzdGE6CiAgICAgICAgICAgIG1ldGEgKz0gWyctbWV0YWRhdGEnLCAn
:::YXJ0aXN0PScgKyBzdHIoYXJ0aXN0YSldCiAgICB3bWEgPSBjYXJwZXRhIC8gKGxp
:::bXBpYXJfbm9tYnJlKGluZm8uZ2V0KCd0aXRsZScpIG9yICdhdWRpbycpICsgJy53
:::bWEnKQogICAgY21kID0gW3N0cihGRk1QRUcpLCAnLXknLCAnLWknLCBzdHIod2F2
:::KSwgJy12bicsCiAgICAgICAgICAgJy1jOmEnLCAnd21hdjInLCAnLWI6YScsIGYn
:::e2NhbGlkYWR9ayddICsgbWV0YSArIFtzdHIod21hKV0KICAgIG9rID0gY29udmVy
:::dGlyX2ZmbXBlZygKICAgICAgICBjbWQsIGYnQ29udmlydGllbmRvIGEgV01BICh3
:::bWF2MiDCtyB7Y2FsaWRhZH0ga2JwcyknLCBjb2xhKQogICAgaWYgbm90IG9rOgog
:::ICAgICAgIHJhaXNlIFJ1bnRpbWVFcnJvcignRkZtcGVnIG5vIHB1ZG8gY3JlYXIg
:::ZWwgYXJjaGl2byBXTUEuJykKICAgIGNhcmF0dWxhID0gTm9uZQogICAgaWYgZW1i
:::ZWJlcjoKICAgICAgICBqcGdzID0gc29ydGVkKHRtcC5nbG9iKCcqLmpwZycpLAog
:::ICAgICAgICAgICAgICAgICAgICAga2V5PWxhbWJkYSBxOiBxLnN0YXQoKS5zdF9t
:::dGltZSwgcmV2ZXJzZT1UcnVlKQogICAgICAgIGlmIGpwZ3M6CiAgICAgICAgICAg
:::IHRyeToKICAgICAgICAgICAgICAgIGNhcmF0dWxhID0ganBnc1swXS5yZWFkX2J5
:::dGVzKCkKICAgICAgICAgICAgZXhjZXB0IE9TRXJyb3I6CiAgICAgICAgICAgICAg
:::ICBjYXJhdHVsYSA9IE5vbmUKICAgIGFwbGljYXJfdGFncyhpbmZvLCB3bWEsIGxv
:::ZywgY2FyYXR1bGEpCiAgICBzaHV0aWwucm10cmVlKHRtcCwgaWdub3JlX2Vycm9y
:::cz1UcnVlKQogICAgcmV0dXJuIGluZm8sIHdtYQoKCmRlZiBtZXRhX3JpZmZfaW5m
:::byhpbmZvKToKICAgICIiInYyLjc6IGFyZ3VtZW50b3MgLW1ldGFkYXRhIHBhcmEg
:::bG9zIHRhZ3MgUklGRiBJTkZPIGRlbCBBVkkuCgogICAgRkZtcGVnIGxvcyBtYXBl
:::YSBhIElOQU0gKHRpdHVsbyksIElBUlQgKGFydGlzdGEpLCBJUFJEIChhbGJ1bSks
:::CiAgICBJQ1JEIChmZWNoYSkgZSBJQ01UIChjb21lbnRhcmlvKSBkZW50cm8gZGVs
:::IGNodW5rIExJU1QvSU5GTyBkZWwKICAgIFJJRkYsIHF1ZSBlcyBkb25kZSBsb3Mg
:::cmVwcm9kdWN0b3JlcyBidXNjYW4gbG9zIGRhdG9zIGRlIHVuIEFWSS4iIiIKICAg
:::IHRpdHVsbyA9IHN0cihpbmZvLmdldCgndHJhY2snKSBvciBpbmZvLmdldCgndGl0
:::bGUnKSBvciAnJykuc3RyaXAoKQogICAgYXJ0aXN0YSA9IF9hcnRpc3RhX2xpbXBp
:::byhpbmZvKQogICAgYWxidW0gPSBfYWxidW1fZGUoaW5mbykKICAgIGZlY2hhID0g
:::c3RyKGluZm8uZ2V0KCdyZWxlYXNlX3llYXInKSBvciAnJykKICAgIGlmIG5vdCBm
:::ZWNoYToKICAgICAgICBmZWNoYSA9IHN0cihpbmZvLmdldCgndXBsb2FkX2RhdGUn
:::KSBvciAnJylbOjRdCiAgICB1cmwgPSBzdHIoaW5mby5nZXQoJ3dlYnBhZ2VfdXJs
:::Jykgb3IgJycpLnN0cmlwKCkKICAgIG1ldGEgPSBbXQogICAgaWYgdGl0dWxvOgog
:::ICAgICAgIG1ldGEgKz0gWyctbWV0YWRhdGEnLCAndGl0bGU9JyArIHRpdHVsb10K
:::ICAgIGlmIGFydGlzdGE6CiAgICAgICAgbWV0YSArPSBbJy1tZXRhZGF0YScsICdh
:::cnRpc3Q9JyArIGFydGlzdGFdCiAgICBpZiBhbGJ1bToKICAgICAgICBtZXRhICs9
:::IFsnLW1ldGFkYXRhJywgJ2FsYnVtPScgKyBhbGJ1bV0KICAgIGlmIGZlY2hhOgog
:::ICAgICAgIG1ldGEgKz0gWyctbWV0YWRhdGEnLCAnZGF0ZT0nICsgZmVjaGFdCiAg
:::ICBpZiB1cmw6CiAgICAgICAgbWV0YSArPSBbJy1tZXRhZGF0YScsICdjb21tZW50
:::PScgKyB1cmxdCiAgICByZXR1cm4gbWV0YQoKCiMgUGFyw6FtZXRyb3Mgb2ZpY2lh
:::bGVzIGRlbCByZXBvIGZkZDRzL3BvcnRhYmxlX21wM19wbGF5ZXJfdmlkZW9fY29u
:::dmVydGVyX3Rvb2xzCiMgKHZpZGVvMnNoZW5qdTE4LnNoKTogTUpQRUcgMTYgZnBz
:::ICsgUENNIDIyMDUwIEh6LCByb3RhZG9zIHBhcmEgbGEgcGFudGFsbGEKIyB2ZXJ0
:::aWNhbCBkZSAxMjh4MTYwIGRlbCByZXByb2R1Y3RvciBzaGVpanUgZGUgMS44IHB1
:::bGdhZGFzLgpWRl9TSEVJSlUgPSAnc2NhbGU9LTI6MTI4LCBjcm9wPTE2MDoxMjgs
:::IHRyYW5zcG9zZT0yLCB2ZmxpcCcKIyBWYXJpYW50ZSBhIHBydWViYSBkZSBiYWxh
:::cyBwYXJhIHZpZGVvcyBjdWFkcmFkb3MvdmVydGljYWxlcyAoU2hvcnRzKSwKIyBk
:::b25kZSBlbCByZWNvcnRlIDE2MDoxMjggb3JpZ2luYWwgc2Vyw61hIGltcG9zaWJs
:::ZToKVkZfU0VHVVJPID0gKCdzY2FsZT0xNjA6MTI4OmZvcmNlX29yaWdpbmFsX2Fz
:::cGVjdF9yYXRpbz1kZWNyZWFzZSwnCiAgICAgICAgICAgICAncGFkPTE2MDoxMjg6
:::KG93LWl3KS8yOihvaC1paCkvMix0cmFuc3Bvc2U9Mix2ZmxpcCcpCgoKZGVmIGRl
:::c2Nhcmdhcl9hdmkodXJsLCBkZXN0aW5vLCBjb2xhKToKICAgICIiIlZpZGVvIEFW
:::SSBwYXJhIGVsIHJlcHJvZHVjdG9yIHNoZWlqdSAxLjgiIDEyOHgxNjAuIiIiCiAg
:::ICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAgICBjb2xhLnB1dCgoJ2xvZycs
:::IG0sIHQpKQoKICAgIGNhcnBldGEgPSBkZXN0aW5vICAgICAgICAgICMgdjIuMzog
:::c2luIHN1YmNhcnBldGFzIHBvciBmb3JtYXRvCiAgICB0bXAgPSBjYXJwZXRhIC8g
:::J190bXAnCiAgICBzaHV0aWwucm10cmVlKHRtcCwgaWdub3JlX2Vycm9ycz1UcnVl
:::KQogICAgdG1wLm1rZGlyKHBhcmVudHM9VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAg
:::IG8gPSBvcHRzX2Jhc2UodG1wLCBjb2xhKQogICAgIyBQYXJhIHVuYSBwYW50YWxs
:::YSBkZSAxMjh4MTYwIGJhc3RhIGNvbiA0ODBwOiBhaG9ycmEgbXVjaGEgZGVzY2Fy
:::Z2EuCiAgICBvWydmb3JtYXQnXSA9ICgnYmVzdFtoZWlnaHQ8PTQ4MF1bZXh0PW1w
:::NF0vYmVzdFtoZWlnaHQ8PTQ4MF0vJwogICAgICAgICAgICAgICAgICAgJ2J2Klto
:::ZWlnaHQ8PTQ4MF0rYmEvYicpCiAgICBvWydtZXJnZV9vdXRwdXRfZm9ybWF0J10g
:::PSAnbXA0JwogICAgd2l0aCBZVF9ETFAuWW91dHViZURMKG8pIGFzIHlkbDoKICAg
:::ICAgICBpbmZvID0geWRsLmV4dHJhY3RfaW5mbyh1cmwsIGRvd25sb2FkPVRydWUp
:::CiAgICBvcmlnZW4gPSBhcmNoaXZvX2ZpbmFsKGluZm8sIHRtcCwgJ21wNCcpCiAg
:::ICBpZiBub3Qgb3JpZ2VuOgogICAgICAgIG9yaWdlbiA9IChhcmNoaXZvX2ZpbmFs
:::KGluZm8sIHRtcCwgJ21rdicpCiAgICAgICAgICAgICAgICAgIG9yIGFyY2hpdm9f
:::ZmluYWwoaW5mbywgdG1wLCAnd2VibScpKQogICAgaWYgbm90IG9yaWdlbjoKICAg
:::ICAgICByYWlzZSBSdW50aW1lRXJyb3IoJ05vIHNlIGVuY29udHLDsyBlbCB2aWRl
:::byBkZXNjYXJnYWRvLicpCiAgICBhdmkgPSBjYXJwZXRhIC8gKGxpbXBpYXJfbm9t
:::YnJlKGluZm8uZ2V0KCd0aXRsZScpIG9yICd2aWRlbycpICsgJy5hdmknKQogICAg
:::IyB2Mi43OiBldGlxdWV0YXMgUklGRiBJTkZPIGRlbnRybyBkZWwgQVZJICh2ZXIg
:::bWV0YV9yaWZmX2luZm8pCiAgICAjIHBhcmEgcXVlIGVsIHZpZGVvIHRhbWJpZW4g
:::bXVlc3RyZSB0aXR1bG8geSBhcnRpc3RhIGRvbmRlIGVsCiAgICAjIHJlcHJvZHVj
:::dG9yIHNlcGEgbGVlcmxhcy4KICAgIG1ldGEgPSBtZXRhX3JpZmZfaW5mbyhpbmZv
:::KQogICAgYmFzZSA9IFtzdHIoRkZNUEVHKSwgJy15JywgJy1pJywgc3RyKG9yaWdl
:::biksICctcicsICcxNicsCiAgICAgICAgICAgICctYWNvZGVjJywgJ3BjbV9zMTZs
:::ZScsICctYWMnLCAnMicsICctYXInLCAnMjIwNTAnLAogICAgICAgICAgICAnLXBp
:::eF9mbXQnLCAneXV2ajQyMHAnLCAnLWM6dicsICdtanBlZycsICctcTp2JywgJzIn
:::XSArIG1ldGEKICAgIG9rID0gY29udmVydGlyX2ZmbXBlZyhiYXNlICsgWyctdmYn
:::LCBWRl9TSEVJSlUsIHN0cihhdmkpXSwKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAnQ29udmlydGllbmRvIGEgQVZJIDEyOHgxNjAgKHNoZWlqdSAxLjgiKScsIGNv
:::bGEpCiAgICBpZiBub3Qgb2s6CiAgICAgICAgbG9nKCdWaWRlbyBjb24gcHJvcG9y
:::Y2nDs24gbm8gZXN0w6FuZGFyOyAnCiAgICAgICAgICAgICdyZWludGVudGFuZG8g
:::ZW4gbW9kbyBjb21wYXRpYmxlLi4uJywgJ2F2aXNvJykKICAgICAgICBvayA9IGNv
:::bnZlcnRpcl9mZm1wZWcoYmFzZSArIFsnLXZmJywgVkZfU0VHVVJPLCBzdHIoYXZp
:::KV0sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICdSZWNvbnZpcnRpZW5k
:::byBhIEFWSSAxMjh4MTYwJywgY29sYSkKICAgIGlmIG5vdCBvazoKICAgICAgICBy
:::YWlzZSBSdW50aW1lRXJyb3IoJ0ZGbXBlZyBubyBwdWRvIGNyZWFyIGVsIGFyY2hp
:::dm8gQVZJLicpCiAgICBzaHV0aWwucm10cmVlKHRtcCwgaWdub3JlX2Vycm9ycz1U
:::cnVlKQogICAgcmV0dXJuIGluZm8sIGF2aQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBl
:::c3RpbWFjacOzbgpLQlBTX0VTVElNQURPUyA9IHsKICAgICdBQUMnOiAxMjgsICAg
:::ICAjIHRlY2hvIGRlbCBmb3JtYXRvCiAgICAnV01BJzogMTI4LAogICAgJ1dBVic6
:::IDE0MTEsICAgICMgUENNIDQ0LjEga0h6IMK3IDE2IGJpdCDCtyBlc3TDqXJlbwog
:::ICAgJ0ZMQUMnOiA5NTAsICAgICMgdMOtcGljbyBkZSBtw7pzaWNhIHByb2NlZGVu
:::dGUgZGUgWW91VHViZQogICAgJ0FWSSc6IDE0OTAsICAgICMgfjc4NCBrYnBzIE1K
:::UEVHIDE2ZnBzICsgNzA2IGticHMgUENNIDIyMDUwIGVzdMOpcmVvCn0KCgpkZWYg
:::ZXN0aW1hcl9ieXRlcyhkdXJhY2lvbl9zLCBmb3JtYXRvLCBjYWxpZGFkLCBlbWJl
:::YmVyKToKICAgICIiIkVzdGltYSBlbCB0YW1hw7FvIGZpbmFsIGVuIGJ5dGVzIChj
:::w6FsY3VsbyBwdXJvLCB0ZXN0ZWFibGUpLiIiIgogICAgaWYgZm9ybWF0byBpbiAo
:::J01QMycsICdBQUMnLCAnV01BJyk6CiAgICAgICAga2JwcyA9IGludChyZS5zdWIo
:::cidbXjAtOV0nLCAnJywgc3RyKGNhbGlkYWQpKSBvciAwKQogICAgICAgIGlmIG5v
:::dCBrYnBzOgogICAgICAgICAgICBrYnBzID0gS0JQU19FU1RJTUFET1MuZ2V0KGZv
:::cm1hdG8sIDEyOCkKICAgIGVsc2U6CiAgICAgICAga2JwcyA9IEtCUFNfRVNUSU1B
:::RE9TLmdldChmb3JtYXRvLCAxMjgpCiAgICBleHRyYSA9IDEyMF8wMDAgaWYgKGVt
:::YmViZXIgYW5kIGZvcm1hdG8gaW4gKCdBQUMnLCAnTVAzJywgJ0ZMQUMnLAogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAnV0FW
:::JykpIGVsc2UgMAogICAgcmV0dXJuIGR1cmFjaW9uX3MgKiBrYnBzICogMTAwMCAv
:::IDggKyBleHRyYQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBjYWxpZGFkCmRlZiBjbGFz
:::ZV9jYWxpZGFkKGV4dCwga2Jwcyk6CiAgICAiIiJDbGFzaWZpY2EgdW4gYXJjaGl2
:::by4gRGV2dWVsdmUgKHRleHRvLCBuaXZlbCkgY29uIG5pdmVsIDA9b2sgMT1tZWRp
:::YSAyPWJhamEuIiIiCiAgICBpZiBleHQgPT0gJy5tcDMnOgogICAgICAgIGlmIGti
:::cHMgPj0gMzE1OgogICAgICAgICAgICByZXR1cm4gJzMyMCBrYnBzJywgMAogICAg
:::ICAgIGlmIGticHMgPj0gMjUwOgogICAgICAgICAgICByZXR1cm4gJzI1NiBrYnBz
:::JywgMAogICAgICAgIGlmIGticHMgPj0gMTg1OgogICAgICAgICAgICByZXR1cm4g
:::JzE5MiBrYnBzJywgMAogICAgICAgIGlmIGticHMgPj0gMTIwOgogICAgICAgICAg
:::ICByZXR1cm4gJzEyOCBrYnBzJywgMQogICAgICAgIHJldHVybiBmJ3trYnBzfSBr
:::YnBzIChiYWphKScsIDIKICAgIGlmIGV4dCA9PSAnLm00YSc6CiAgICAgICAgaWYg
:::a2JwcyA+PSAxMTU6CiAgICAgICAgICAgIHJldHVybiAnRXhjZWxlbnRlIChBQUMg
:::4omkMTI4ayknLCAwCiAgICAgICAgaWYga2JwcyA+PSA4MjoKICAgICAgICAgICAg
:::cmV0dXJuICc5NiBrYnBzJywgMQogICAgICAgIHJldHVybiBmJ3trYnBzfSBrYnBz
:::IChiYWphKScsIDIKICAgIGlmIGV4dCA9PSAnLndtYSc6CiAgICAgICAgaWYga2Jw
:::cyA+PSAxMTU6CiAgICAgICAgICAgIHJldHVybiAnMTI4IGticHMnLCAwCiAgICAg
:::ICAgaWYga2JwcyA+PSA4ODoKICAgICAgICAgICAgcmV0dXJuICc5NiBrYnBzJywg
:::MQogICAgICAgIHJldHVybiBmJ3trYnBzfSBrYnBzIChiYWphKScsIDIKICAgIGlm
:::IGV4dCBpbiAoJy5mbGFjJywgJy53YXYnKToKICAgICAgICByZXR1cm4gJ1NpbiBw
:::w6lyZGlkYScsIDAKICAgIGlmIGV4dCA9PSAnLmF2aSc6CiAgICAgICAgaWYga2Jw
:::cyA+PSAxMjAwOgogICAgICAgICAgICByZXR1cm4gZid7a2Jwc30ga2JwcyAoTUpQ
:::RUcrUENNIDEyOHgxNjApJywgMAogICAgICAgIHJldHVybiBmJ3trYnBzfSBrYnBz
:::IChhbGdvIGJham8pJywgMQogICAgcmV0dXJuIGYne2ticHN9IGticHMnLCAxCgoK
:::IyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tIHRlbWFzClRFTUFTID0gewogICAgJ09zY3Vybyc6
:::IGRpY3QoCiAgICAgICAgZm9uZG89JyMxZTFmMjInLCBjYW1wbz0nIzJhMmQzMScs
:::IGNhbXBvX2JvcmRlPScjM2EzZTQ0JywKICAgICAgICB0ZXh0bz0nI2Q4ZGFkYycs
:::IHRleHRvMj0nIzlhOWZhNCcsCiAgICAgICAgYm90b249JyMzYTNkNDInLCBib3Rv
:::bl9hY3Q9JyM0YTRlNTUnLCBib3Rvbl90eHQ9JyNlOGVhZWMnLAogICAgICAgIGxv
:::Zz0nIzE0MTUxOCcsIGxvZ190eHQ9JyNjZmQzZDcnLCBhY2VudG89JyM0ZjljZjkn
:::LAogICAgICAgIG9rPScjN2VjOTdmJywgZXJyb3I9JyNlNTczNzMnLCBhdmlzbz0n
:::I2Q4YjY0YScsIHRyb3VnaD0nIzI2MjgyYycsCiAgICAgICAgcGxhY2Vob2xkZXI9
:::JyM3NzdjODInKSwKICAgICdDbGFybyc6IGRpY3QoCiAgICAgICAgZm9uZG89JyNm
:::MmYzZjUnLCBjYW1wbz0nI2ZmZmZmZicsIGNhbXBvX2JvcmRlPScjYzRjOGNkJywK
:::ICAgICAgICB0ZXh0bz0nIzI0MjcyYScsIHRleHRvMj0nIzZhNzA3NicsCiAgICAg
:::ICAgYm90b249JyNlM2U1ZTgnLCBib3Rvbl9hY3Q9JyNkMmQ1ZGEnLCBib3Rvbl90
:::eHQ9JyMyNDI3MmEnLAogICAgICAgIGxvZz0nI2ZmZmZmZicsIGxvZ190eHQ9JyMy
:::YjJlMzEnLCBhY2VudG89JyMxYTY2ZDYnLAogICAgICAgIG9rPScjMWU3ZTM0Jywg
:::ZXJyb3I9JyNjNjI4MjgnLCBhdmlzbz0nIzlhNjcwMCcsIHRyb3VnaD0nI2RmZTFl
:::NCcsCiAgICAgICAgcGxhY2Vob2xkZXI9JyM5YWEwYTYnKSwKfQoKUExBQ0VIT0xE
:::RVJfVVJMID0gJ2h0dHBzOi8vd3d3LnlvdXR1YmUuY29tL3dhdGNoP3Y9Li4uJwoK
:::RlVFTlRFX1VJID0gKCdTZWdvZSBVSScsIDkpCkZVRU5URV9CVE4gPSAoJ1NlZ29l
:::IFVJJywgMTApCkZVRU5URV9CVE5fRyA9ICgnU2Vnb2UgVUknLCAxMSkKRlVFTlRF
:::X0xPRyA9ICgnQ29uc29sYXMnLCAxMCkKCgppZiBUS19PSzoKCiAgICBjbGFzcyBB
:::cHAodGsuVGspOgogICAgICAgICIiIlZlbnRhbmEgcHJpbmNpcGFsIChkaXNlw7Fv
:::IGVzcGVqbyBkZWwgbW9ja3VwOiBncnVwb3Mgb3NjdXJvcykuIiIiCgogICAgICAg
:::ICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tIGNvbnN0cnVjY2nDs24KICAgICAgICBkZWYgX19pbml0X18oc2VsZik6CiAg
:::ICAgICAgICAgIGlmIGdldGF0dHIoc3lzLCAnZnJvemVuJywgRmFsc2UpOgogICAg
:::ICAgICAgICAgICAgcGFzcwogICAgICAgICAgICBzdXBlcigpLl9faW5pdF9fKCkK
:::ICAgICAgICAgICAgc2VsZi50aXRsZSgnTXVzaWtBTEFOJykKICAgICAgICAgICAg
:::c2VsZi5nZW9tZXRyeSgnODYweDg0MCcpCiAgICAgICAgICAgIHNlbGYubWluc2l6
:::ZSg3MDAsIDY2MCkKICAgICAgICAgICAgc2VsZi5jb2xhID0gcXVldWUuUXVldWUo
:::KQogICAgICAgICAgICBzZWxmLl9vY3VwYWRvID0gRmFsc2UKICAgICAgICAgICAg
:::c2VsZi5fZW5fcGxhY2Vob2xkZXIgPSBUcnVlCiAgICAgICAgICAgIHNlbGYuX3Rl
:::bWFfYWN0dWFsID0gQUpVU1RFUy5nZXQoJ3RlbWEnLCAnT3NjdXJvJykKICAgICAg
:::ICAgICAgaWYgc2VsZi5fdGVtYV9hY3R1YWwgbm90IGluIFRFTUFTOgogICAgICAg
:::ICAgICAgICAgc2VsZi5fdGVtYV9hY3R1YWwgPSAnT3NjdXJvJwoKICAgICAgICAg
:::ICAgc2VsZi5fZXN0aWxvID0gdHRrLlN0eWxlKHNlbGYpCiAgICAgICAgICAgIHRy
:::eToKICAgICAgICAgICAgICAgIHNlbGYuX2VzdGlsby50aGVtZV91c2UoJ2NsYW0n
:::KQogICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICAgICAg
:::cGFzcwoKICAgICAgICAgICAgc2VsZi5fY29uc3RydWlyKCkKICAgICAgICAgICAg
:::c2VsZi5fYXBsaWNhcl90ZW1hKCkKICAgICAgICAgICAgc2VsZi5fY29uZWN0YXJf
:::ZXZlbnRvcygpCiAgICAgICAgICAgIFJFR0lTVFJPLmxvZyA9IGxhbWJkYSBtLCB0
:::PSdhdmlzbyc6IHNlbGYuY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKICAgICAgICAg
:::ICAgc2VsZi5hZnRlcig4MCwgc2VsZi5fYm9tYmVhcl9jb2xhKQogICAgICAgICAg
:::ICBzZWxmLmFmdGVyKDE1MCwgc2VsZi5fYXJyYW5xdWUpCgogICAgICAgIGRlZiBf
:::Y29uc3RydWlyKHNlbGYpOgogICAgICAgICAgICBzZWxmLl93ZyA9IHt9ICAgICAg
:::ICAgIyByZWZlcmVuY2lhcyBwYXJhIGVsIHRlbWEKICAgICAgICAgICAgc2VsZi5f
:::YnRucyA9IFtdICAgICAgICMgYm90b25lcyBwbGFub3MgKHBhcmEgaG92ZXIvdGVt
:::YSkKICAgICAgICAgICAgbWFyY28gPSB0ay5GcmFtZShzZWxmKQogICAgICAgICAg
:::ICBtYXJjby5wYWNrKGZpbGw9J2JvdGgnLCBleHBhbmQ9VHJ1ZSwgcGFkeD0xMCwg
:::cGFkeT04KQogICAgICAgICAgICBzZWxmLl93Z1snbWFyY28nXSA9IG1hcmNvCiAg
:::ICAgICAgICAgIG1hcmNvLmNvbHVtbmNvbmZpZ3VyZSgwLCB3ZWlnaHQ9MSkKCiAg
:::ICAgICAgICAgICMgLS0tIGZpbGEgVGVtYSAtLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KICAgICAgICAgICAgZjAgPSB0ay5G
:::cmFtZShtYXJjbykKICAgICAgICAgICAgZjAuZ3JpZChyb3c9MCwgY29sdW1uPTAs
:::IHN0aWNreT0nZXcnLCBwYWR5PSgwLCA2KSkKICAgICAgICAgICAgc2VsZi5fd2db
:::J2YwJ10gPSBmMAogICAgICAgICAgICBzZWxmLl93Z1snbGJsX3RlbWEnXSA9IHRr
:::LkxhYmVsKGYwLCB0ZXh0PSdUZW1hOicsIGZvbnQ9RlVFTlRFX1VJKQogICAgICAg
:::ICAgICBzZWxmLl93Z1snbGJsX3RlbWEnXS5wYWNrKHNpZGU9J2xlZnQnKQogICAg
:::ICAgICAgICBzZWxmLmNtYl90ZW1hID0gdHRrLkNvbWJvYm94KAogICAgICAgICAg
:::ICAgICAgZjAsIHZhbHVlcz1saXN0KFRFTUFTKSwgc3RhdGU9J3JlYWRvbmx5Jywg
:::d2lkdGg9OSwKICAgICAgICAgICAgICAgIGZvbnQ9RlVFTlRFX1VJLCBzdHlsZT0n
:::Z3guVENvbWJvYm94JykKICAgICAgICAgICAgc2VsZi5jbWJfdGVtYS5zZXQoc2Vs
:::Zi5fdGVtYV9hY3R1YWwpCiAgICAgICAgICAgIHNlbGYuY21iX3RlbWEucGFjayhz
:::aWRlPSdsZWZ0JywgcGFkeD0oOCwgMCksIGlwYWR5PTIpCgogICAgICAgICAgICAj
:::IC0tLSBncnVwbzogVVJMIGRlIFlvdVR1YmUgLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAgIGd1ID0gdGsuTGFiZWxGcmFtZSht
:::YXJjbywgdGV4dD0nVVJMIGRlIFlvdVR1YmUnLCBmb250PUZVRU5URV9VSSwKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlbGllZj0nc29saWQnLCBiZD0x
:::KQogICAgICAgICAgICBndS5ncmlkKHJvdz0xLCBjb2x1bW49MCwgc3RpY2t5PSdl
:::dycsIHBhZHk9NSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2d1J10gPSBndQogICAg
:::ICAgICAgICBndS5jb2x1bW5jb25maWd1cmUoMCwgd2VpZ2h0PTEpCiAgICAgICAg
:::ICAgIHNlbGYuZW50X3VybCA9IHRrLkVudHJ5KGd1LCBmb250PUZVRU5URV9VSSwg
:::cmVsaWVmPSdmbGF0JywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgaGlnaGxpZ2h0dGhpY2tuZXNzPTEpCiAgICAgICAgICAgIHNlbGYuZW50X3Vy
:::bC5ncmlkKHJvdz0wLCBjb2x1bW49MCwgc3RpY2t5PSdldycsCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgIHBhZHg9OCwgcGFkeT04LCBpcGFkeT01KQogICAg
:::ICAgICAgICBzZWxmLl9wb25lcl9wbGFjZWhvbGRlcigpCiAgICAgICAgICAgIHNl
:::bGYuYnRuX3ggPSBzZWxmLl9ib3RvbihndSwgJ1gnLCBzZWxmLl9saW1waWFyX3Vy
:::bCwgd2lkdGg9MykKICAgICAgICAgICAgc2VsZi5idG5feC5ncmlkKHJvdz0wLCBj
:::b2x1bW49MSwgc3RpY2t5PSdlJywgcGFkeD0oMCwgOCksIGlwYWR5PTMpCgogICAg
:::ICAgICAgICAjIC0tLSBncnVwbzogRm9ybWF0byB5IGNhbGlkYWQgLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAgIGdmID0gdGsuTGFi
:::ZWxGcmFtZShtYXJjbywgdGV4dD0nRm9ybWF0byB5IGNhbGlkYWQnLCBmb250PUZV
:::RU5URV9VSSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlbGllZj0n
:::c29saWQnLCBiZD0xKQogICAgICAgICAgICBnZi5ncmlkKHJvdz0yLCBjb2x1bW49
:::MCwgc3RpY2t5PSdldycsIHBhZHk9NSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2dm
:::J10gPSBnZgogICAgICAgICAgICBnZi5jb2x1bW5jb25maWd1cmUoMSwgd2VpZ2h0
:::PTEpCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfZm10J10gPSB0ay5MYWJlbChn
:::ZiwgdGV4dD0nRm9ybWF0bzonLCBmb250PUZVRU5URV9VSSkKICAgICAgICAgICAg
:::c2VsZi5fd2dbJ2xibF9mbXQnXS5ncmlkKHJvdz0wLCBjb2x1bW49MCwgc3RpY2t5
:::PSd3JywgcGFkeD04LCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYuY21iX2Zvcm1h
:::dG8gPSB0dGsuQ29tYm9ib3goCiAgICAgICAgICAgICAgICBnZiwgdmFsdWVzPVtm
:::Wyd0ZXh0byddIGZvciBmIGluIEZPUk1BVE9TLnZhbHVlcygpXSwKICAgICAgICAg
:::ICAgICAgIHN0YXRlPSdyZWFkb25seScsIGZvbnQ9RlVFTlRFX1VJLCBzdHlsZT0n
:::Z3guVENvbWJvYm94JykKICAgICAgICAgICAgc2VsZi5jbWJfZm9ybWF0by5ncmlk
:::KHJvdz0wLCBjb2x1bW49MSwgc3RpY2t5PSdldycsCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICBwYWR4PTgsIHBhZHk9NSwgaXBhZHk9MikKICAgICAg
:::ICAgICAgc2VsZi5fd2dbJ2xibF9jYWwnXSA9IHRrLkxhYmVsKGdmLCB0ZXh0PSdD
:::YWxpZGFkOicsIGZvbnQ9RlVFTlRFX1VJKQogICAgICAgICAgICBzZWxmLl93Z1sn
:::bGJsX2NhbCddLmdyaWQocm93PTEsIGNvbHVtbj0wLCBzdGlja3k9J3cnLCBwYWR4
:::PTgsIHBhZHk9NSkKICAgICAgICAgICAgc2VsZi5jbWJfY2FsaWRhZCA9IHR0ay5D
:::b21ib2JveCgKICAgICAgICAgICAgICAgIGdmLCBzdGF0ZT0ncmVhZG9ubHknLCBm
:::b250PUZVRU5URV9VSSwgc3R5bGU9J2d4LlRDb21ib2JveCcpCiAgICAgICAgICAg
:::IHNlbGYuY21iX2NhbGlkYWQuZ3JpZChyb3c9MSwgY29sdW1uPTEsIHN0aWNreT0n
:::ZXcnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFkeD04LCBw
:::YWR5PTUsIGlwYWR5PTIpCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfY2FyJ10g
:::PSB0ay5MYWJlbChnZiwgdGV4dD0nQ2FycGV0YTonLCBmb250PUZVRU5URV9VSSkK
:::ICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF9jYXInXS5ncmlkKHJvdz0yLCBjb2x1
:::bW49MCwgc3RpY2t5PSd3JywgcGFkeD04LCBwYWR5PTUpCiAgICAgICAgICAgIGZj
:::ID0gdGsuRnJhbWUoZ2YpCiAgICAgICAgICAgIGZjLmdyaWQocm93PTIsIGNvbHVt
:::bj0xLCBzdGlja3k9J2V3JywgcGFkeD04LCBwYWR5PTUpCiAgICAgICAgICAgIHNl
:::bGYuX3dnWydmYyddID0gZmMKICAgICAgICAgICAgZmMuY29sdW1uY29uZmlndXJl
:::KDAsIHdlaWdodD0xKQogICAgICAgICAgICBzZWxmLmVudF9jYXJwZXRhID0gdGsu
:::RW50cnkoZmMsIGZvbnQ9RlVFTlRFX1VJLCByZWxpZWY9J2ZsYXQnLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgaGlnaGxpZ2h0dGhpY2tu
:::ZXNzPTEpCiAgICAgICAgICAgIHNlbGYuZW50X2NhcnBldGEuZ3JpZChyb3c9MCwg
:::Y29sdW1uPTAsIHN0aWNreT0nZXcnLCBpcGFkeT00KQogICAgICAgICAgICBzZWxm
:::LmVudF9jYXJwZXRhLmluc2VydCgwLCBBSlVTVEVTWydkZXN0aW5vJ10pCiAgICAg
:::ICAgICAgIHNlbGYuYnRuX2NhbWJpYXIgPSBzZWxmLl9ib3RvbihmYywgJ0NhbWJp
:::YXIuLi4nLCBzZWxmLl9jYW1iaWFyX2NhcnBldGEpCiAgICAgICAgICAgIHNlbGYu
:::YnRuX2NhbWJpYXIuZ3JpZChyb3c9MCwgY29sdW1uPTEsIHBhZHg9KDgsIDApLCBp
:::cGFkeT0zKQogICAgICAgICAgICBzZWxmLmJ0bl9hYnJpciA9IHNlbGYuX2JvdG9u
:::KGZjLCAnQWJyaXInLCBzZWxmLl9hYnJpcl9kZXN0aW5vLCB3aWR0aD01KQogICAg
:::ICAgICAgICBzZWxmLmJ0bl9hYnJpci5ncmlkKHJvdz0wLCBjb2x1bW49MiwgcGFk
:::eD0oNiwgMCksIGlwYWR5PTMpCgogICAgICAgICAgICBzZWxmLnZhcl9lbWJlYmVy
:::ID0gdGsuQm9vbGVhblZhcih2YWx1ZT1ib29sKEFKVVNURVMuZ2V0KCdlbWJlYmVy
:::JywgVHJ1ZSkpKQogICAgICAgICAgICBzZWxmLmNoa19lbWJlYmVyID0gdGsuQ2hl
:::Y2tidXR0b24oCiAgICAgICAgICAgICAgICBnZiwgdGV4dD0nRW1iZWJlciBjYXLD
:::oXR1bGEsIGFydGlzdGEgeSDDoWxidW0nLAogICAgICAgICAgICAgICAgdmFyaWFi
:::bGU9c2VsZi52YXJfZW1iZWJlciwgZm9udD1GVUVOVEVfVUksIGFuY2hvcj0ndycs
:::CiAgICAgICAgICAgICAgICByZWxpZWY9J2ZsYXQnLCBoaWdobGlnaHR0aGlja25l
:::c3M9MCwgYmQ9MCkKICAgICAgICAgICAgc2VsZi5jaGtfZW1iZWJlci5ncmlkKHJv
:::dz0zLCBjb2x1bW49MCwgY29sdW1uc3Bhbj0yLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgc3RpY2t5PSdldycsIHBhZHg9OCwgcGFkeT0oMiwgNikp
:::CgogICAgICAgICAgICAjIC0tLSBncnVwbzogZXN0aW1hY2nDs24gLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAgICAgICBnZSA9
:::IHRrLkxhYmVsRnJhbWUobWFyY28sIHRleHQ9J0VzdGltYWNpw7NuJywgZm9udD1G
:::VUVOVEVfVUksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWxpZWY9
:::J3NvbGlkJywgYmQ9MSkKICAgICAgICAgICAgZ2UuZ3JpZChyb3c9MywgY29sdW1u
:::PTAsIHN0aWNreT0nZXcnLCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYuX3dnWydn
:::ZSddID0gZ2UKICAgICAgICAgICAgZ2UuY29sdW1uY29uZmlndXJlKDAsIHdlaWdo
:::dD0xKQogICAgICAgICAgICBzZWxmLmxibF9lc3RpbWFjaW9uID0gdGsuTGFiZWwo
:::CiAgICAgICAgICAgICAgICBnZSwgdGV4dD0nSW50cm9kdWNlIHVuYSBVUkwgeSBw
:::dWxzYSBFc3RpbWFyLicsCiAgICAgICAgICAgICAgICBmb250PUZVRU5URV9VSSwg
:::YW5jaG9yPSd3JykKICAgICAgICAgICAgc2VsZi5sYmxfZXN0aW1hY2lvbi5ncmlk
:::KHJvdz0wLCBjb2x1bW49MCwgc3RpY2t5PSdldycsCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICBwYWR4PTgsIHBhZHk9NikKICAgICAgICAgICAg
:::c2VsZi5idG5fZXN0aW1hciA9IHNlbGYuX2JvdG9uKGdlLCAnRXN0aW1hciB0YW1h
:::bm8nLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::c2VsZi5fYWNjaW9uX2VzdGltYXIpCiAgICAgICAgICAgIHNlbGYuYnRuX2VzdGlt
:::YXIuZ3JpZChyb3c9MCwgY29sdW1uPTEsIHN0aWNreT0nZScsCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICBwYWR4PTgsIGlwYWR5PTMpCgogICAgICAg
:::ICAgICAjIC0tLSBib3RvbmVzIGdyYW5kZXMgLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAgIHNlbGYuYnRuX2Rlc2Nh
:::cmdhciA9IHNlbGYuX2JvdG9uKG1hcmNvLCAnRGVzY2FyZ2FyIHkgY29udmVydGly
:::JywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::c2VsZi5fYWNjaW9uX2Rlc2NhcmdhciwKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgZnVlbnRlPUZVRU5URV9CVE5fRywgYWx0bz0y
:::KQogICAgICAgICAgICBzZWxmLmJ0bl9kZXNjYXJnYXIuZ3JpZChyb3c9NCwgY29s
:::dW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PSg3LCA0KSkKICAgICAgICAgICAgc2Vs
:::Zi5idG5fY29tcHJvYmFyID0gc2VsZi5fYm90b24oCiAgICAgICAgICAgICAgICBt
:::YXJjbywgJ0NvbXByb2JhciBjYWxpZGFkIGRlIGxhIGNhcnBldGEnLAogICAgICAg
:::ICAgICAgICAgc2VsZi5fYWNjaW9uX2NvbXByb2JhciwgZnVlbnRlPUZVRU5URV9C
:::VE4pCiAgICAgICAgICAgIHNlbGYuYnRuX2NvbXByb2Jhci5ncmlkKHJvdz01LCBj
:::b2x1bW49MCwgc3RpY2t5PSdldycsIHBhZHk9MykKCiAgICAgICAgICAgICMgLS0t
:::IGVzdGFkbyArIGJhcnJhIGRlIHByb2dyZXNvIC0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tCiAgICAgICAgICAgIHNlbGYubGJsX2VzdGFkbyA9IHRrLkxh
:::YmVsKG1hcmNvLCB0ZXh0PScnLCBmb250PUZVRU5URV9VSSwKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgYW5jaG9yPSd3JykKICAgICAgICAg
:::ICAgc2VsZi5sYmxfZXN0YWRvLmdyaWQocm93PTYsIGNvbHVtbj0wLCBzdGlja3k9
:::J2V3JywgcGFkeT0oNCwgMCkpCiAgICAgICAgICAgIHNlbGYuYmFycmEgPSB0dGsu
:::UHJvZ3Jlc3NiYXIoCiAgICAgICAgICAgICAgICBtYXJjbywgbWF4aW11bT0xMDAs
:::IHN0eWxlPSdneC5Ib3Jpem9udGFsLlRQcm9ncmVzc2JhcicpCiAgICAgICAgICAg
:::IHNlbGYuYmFycmEuZ3JpZChyb3c9NywgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBw
:::YWR5PSgyLCA0KSkKCiAgICAgICAgICAgICMgLS0tIHJlZ2lzdHJvIChsb2cpIC0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAg
:::ICAgICAgIHNlbGYudHh0X2xvZyA9IFNjcm9sbGVkVGV4dChtYXJjbywgZm9udD1G
:::VUVOVEVfTE9HLCBoZWlnaHQ9MTIsCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICByZWxpZWY9J2ZsYXQnLCBiZD0wLCB3cmFwPSd3b3JkJywK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0YXRlPSdk
:::aXNhYmxlZCcpCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5ncmlkKHJvdz04LCBj
:::b2x1bW49MCwgc3RpY2t5PSduc2V3JykKICAgICAgICAgICAgbWFyY28ucm93Y29u
:::ZmlndXJlKDgsIHdlaWdodD0xKQogICAgICAgICAgICBmb3IgdGFnLCBjb25mIGlu
:::ICgKICAgICAgICAgICAgICAgICAgICAoJ2luZm8nLCB7fSksCiAgICAgICAgICAg
:::ICAgICAgICAgKCdncmlzJywge30pLAogICAgICAgICAgICAgICAgICAgICgndGl0
:::dWxvJywge30pLAogICAgICAgICAgICAgICAgICAgICgnb2snLCB7fSksCiAgICAg
:::ICAgICAgICAgICAgICAgKCdhdmlzbycsIHt9KSwKICAgICAgICAgICAgICAgICAg
:::ICAoJ2Vycm9yJywge30pKToKICAgICAgICAgICAgICAgIHNlbGYudHh0X2xvZy50
:::YWdfY29uZmlndXJlKHRhZywgY29uZikKCiAgICAgICAgICAgICMgc2luY3Jvbml6
:::YXIgdmFsb3JlcyBndWFyZGFkb3MKICAgICAgICAgICAgZm10ID0gQUpVU1RFUy5n
:::ZXQoJ2Zvcm1hdG8nLCAnQUFDJykKICAgICAgICAgICAgaWYgZm10IG5vdCBpbiBG
:::T1JNQVRPUzoKICAgICAgICAgICAgICAgIGZtdCA9ICdBQUMnCiAgICAgICAgICAg
:::IHNlbGYuY21iX2Zvcm1hdG8uc2V0KEZPUk1BVE9TW2ZtdF1bJ3RleHRvJ10pCiAg
:::ICAgICAgICAgIHNlbGYuX3JlY2FyZ2FyX2NhbGlkYWRlcyhmbXQsIEFKVVNURVMu
:::Z2V0KCdjYWxpZGFkJykpCgogICAgICAgICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGhlbHBlcnMgd2lkZ2V0cwogICAg
:::ICAgIGRlZiBfYm90b24oc2VsZiwgcGFkcmUsIHRleHRvLCBjbWQsIHdpZHRoPU5v
:::bmUsIGZ1ZW50ZT1GVUVOVEVfQlROLAogICAgICAgICAgICAgICAgICAgYWx0bz0x
:::KToKICAgICAgICAgICAgYiA9IHRrLkJ1dHRvbihwYWRyZSwgdGV4dD10ZXh0bywg
:::Y29tbWFuZD1jbWQsIGZvbnQ9ZnVlbnRlLAogICAgICAgICAgICAgICAgICAgICAg
:::ICAgIHJlbGllZj0nZmxhdCcsIGJkPTAsIGN1cnNvcj0naGFuZDInLCBoZWlnaHQ9
:::YWx0bywKICAgICAgICAgICAgICAgICAgICAgICAgICBhY3RpdmVmb3JlZ3JvdW5k
:::PScjZmZmZmZmJywgdGFrZWZvY3VzPTApCiAgICAgICAgICAgIGlmIHdpZHRoOgog
:::ICAgICAgICAgICAgICAgYi5jb25maWd1cmUod2lkdGg9d2lkdGgpCiAgICAgICAg
:::ICAgIGIuYmluZCgnPEVudGVyPicsIGxhbWJkYSBlLCB3PWI6IHcuY29uZmlndXJl
:::KAogICAgICAgICAgICAgICAgYmc9VEVNQVNbc2VsZi5fdGVtYV9hY3R1YWxdWydi
:::b3Rvbl9hY3QnXSkpCiAgICAgICAgICAgIGIuYmluZCgnPExlYXZlPicsIGxhbWJk
:::YSBlLCB3PWI6IHcuY29uZmlndXJlKAogICAgICAgICAgICAgICAgYmc9VEVNQVNb
:::c2VsZi5fdGVtYV9hY3R1YWxdWydib3RvbiddKSkKICAgICAgICAgICAgc2VsZi5f
:::YnRucy5hcHBlbmQoYikKICAgICAgICAgICAgcmV0dXJuIGIKCiAgICAgICAgZGVm
:::IF9wb25lcl9wbGFjZWhvbGRlcihzZWxmKToKICAgICAgICAgICAgaWYgbm90IHNl
:::bGYuZW50X3VybC5nZXQoKToKICAgICAgICAgICAgICAgIHNlbGYuX2VuX3BsYWNl
:::aG9sZGVyID0gVHJ1ZQogICAgICAgICAgICAgICAgc2VsZi5lbnRfdXJsLmluc2Vy
:::dCgwLCBQTEFDRUhPTERFUl9VUkwpCgogICAgICAgIGRlZiBfbGltcGlhcl91cmwo
:::c2VsZik6CiAgICAgICAgICAgIHNlbGYuZW50X3VybC5kZWxldGUoMCwgJ2VuZCcp
:::CiAgICAgICAgICAgIHNlbGYuZW50X3VybC5mb2N1c19zZXQoKQoKICAgICAgICBk
:::ZWYgX3Jlc2V0X3VybChzZWxmKToKICAgICAgICAgICAgIiIiRGVqYSBlbCBjYW1w
:::byBkZSBVUkwgdmFjw61vIGNvbiBzdSBwbGFjZWhvbGRlciAodHJhcyB1biDDqXhp
:::dG8pLiIiIgogICAgICAgICAgICBzZWxmLmVudF91cmwuZGVsZXRlKDAsICdlbmQn
:::KQogICAgICAgICAgICBzZWxmLl9lbl9wbGFjZWhvbGRlciA9IFRydWUKICAgICAg
:::ICAgICAgc2VsZi5fcG9uZXJfcGxhY2Vob2xkZXIoKQogICAgICAgICAgICBzZWxm
:::Ll9yZWZyZXNjYXJfcGxhY2Vob2xkZXIoKQoKICAgICAgICAjIC0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSB0ZW1hCiAgICAg
:::ICAgZGVmIF9hcGxpY2FyX3RlbWEoc2VsZik6CiAgICAgICAgICAgIHQgPSBURU1B
:::U1tzZWxmLl90ZW1hX2FjdHVhbF0KICAgICAgICAgICAgdyA9IHNlbGYuX3dnCiAg
:::ICAgICAgICAgIHNlbGYuY29uZmlndXJlKGJnPXRbJ2ZvbmRvJ10pCiAgICAgICAg
:::ICAgIGZvciBub21icmUgaW4gKCdtYXJjbycsICdmMCcsICdndScsICdnZicsICdm
:::YycsICdnZScpOgogICAgICAgICAgICAgICAgd1tub21icmVdLmNvbmZpZ3VyZShi
:::Zz10Wydmb25kbyddKQogICAgICAgICAgICBmb3IgbGYgaW4gKHdbJ2d1J10sIHdb
:::J2dmJ10sIHdbJ2dlJ10pOgogICAgICAgICAgICAgICAgbGYuY29uZmlndXJlKGJn
:::PXRbJ2ZvbmRvJ10sIGZnPXRbJ3RleHRvMiddKQogICAgICAgICAgICBmb3Igbm9t
:::YnJlIGluICgnbGJsX3RlbWEnLCAnbGJsX2ZtdCcsICdsYmxfY2FsJywgJ2xibF9j
:::YXInKToKICAgICAgICAgICAgICAgIHdbbm9tYnJlXS5jb25maWd1cmUoYmc9dFsn
:::Zm9uZG8nXSwgZmc9dFsndGV4dG8nXSkKICAgICAgICAgICAgc2VsZi5sYmxfZXN0
:::aW1hY2lvbi5jb25maWd1cmUoYmc9dFsnZm9uZG8nXSwgZmc9dFsndGV4dG8nXSkK
:::ICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmNvbmZpZ3VyZShiZz10Wydmb25k
:::byddLCBmZz10Wyd0ZXh0bzInXSkKICAgICAgICAgICAgc2VsZi5lbnRfdXJsLmNv
:::bmZpZ3VyZSgKICAgICAgICAgICAgICAgIGJnPXRbJ2NhbXBvJ10sIGZnPXRbJ3Rl
:::eHRvJ10sIGluc2VydGJhY2tncm91bmQ9dFsndGV4dG8nXSwKICAgICAgICAgICAg
:::ICAgIGhpZ2hsaWdodGJhY2tncm91bmQ9dFsnY2FtcG9fYm9yZGUnXSwKICAgICAg
:::ICAgICAgICAgIGhpZ2hsaWdodGNvbG9yPXRbJ2FjZW50byddLAogICAgICAgICAg
:::ICAgICAgZGlzYWJsZWRiYWNrZ3JvdW5kPXRbJ2NhbXBvJ10sIGRpc2FibGVkZm9y
:::ZWdyb3VuZD10Wyd0ZXh0bzInXSkKICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0
:::YS5jb25maWd1cmUoCiAgICAgICAgICAgICAgICBiZz10WydjYW1wbyddLCBmZz10
:::Wyd0ZXh0byddLCBpbnNlcnRiYWNrZ3JvdW5kPXRbJ3RleHRvJ10sCiAgICAgICAg
:::ICAgICAgICBoaWdobGlnaHRiYWNrZ3JvdW5kPXRbJ2NhbXBvX2JvcmRlJ10sCiAg
:::ICAgICAgICAgICAgICBoaWdobGlnaHRjb2xvcj10WydhY2VudG8nXSkKICAgICAg
:::ICAgICAgc2VsZi5jaGtfZW1iZWJlci5jb25maWd1cmUoCiAgICAgICAgICAgICAg
:::ICBiZz10Wydmb25kbyddLCBmZz10Wyd0ZXh0byddLCBhY3RpdmViYWNrZ3JvdW5k
:::PXRbJ2ZvbmRvJ10sCiAgICAgICAgICAgICAgICBhY3RpdmVmb3JlZ3JvdW5kPXRb
:::J3RleHRvJ10sIHNlbGVjdGNvbG9yPXRbJ2NhbXBvJ10pCiAgICAgICAgICAgIGZv
:::ciBiIGluIHNlbGYuX2J0bnM6CiAgICAgICAgICAgICAgICBiLmNvbmZpZ3VyZShi
:::Zz10Wydib3RvbiddLCBmZz10Wydib3Rvbl90eHQnXSwKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIGFjdGl2ZWJhY2tncm91bmQ9dFsnYm90b25fYWN0J10sCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBhY3RpdmVmb3JlZ3JvdW5kPXRbJ2Jv
:::dG9uX3R4dCddKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuY29uZmlndXJlKGJn
:::PXRbJ2xvZyddLCBmZz10Wydsb2dfdHh0J10sCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgaW5zZXJ0YmFja2dyb3VuZD10Wydsb2dfdHh0J10pCiAg
:::ICAgICAgICAgIHNlbGYudHh0X2xvZy50YWdfY29uZmlndXJlKCdpbmZvJywgZm9y
:::ZWdyb3VuZD10Wydsb2dfdHh0J10pCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy50
:::YWdfY29uZmlndXJlKCdncmlzJywgZm9yZWdyb3VuZD10Wyd0ZXh0bzInXSkKICAg
:::ICAgICAgICAgc2VsZi50eHRfbG9nLnRhZ19jb25maWd1cmUoJ3RpdHVsbycsIGZv
:::cmVncm91bmQ9dFsndGV4dG8nXSwKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgZm9udD0oJ0NvbnNvbGFzJywgMTAsICdib2xkJykpCiAgICAg
:::ICAgICAgIHNlbGYudHh0X2xvZy50YWdfY29uZmlndXJlKCdvaycsIGZvcmVncm91
:::bmQ9dFsnb2snXSkKICAgICAgICAgICAgc2VsZi50eHRfbG9nLnRhZ19jb25maWd1
:::cmUoJ2F2aXNvJywgZm9yZWdyb3VuZD10WydhdmlzbyddKQogICAgICAgICAgICBz
:::ZWxmLnR4dF9sb2cudGFnX2NvbmZpZ3VyZSgnZXJyb3InLCBmb3JlZ3JvdW5kPXRb
:::J2Vycm9yJ10pCiAgICAgICAgICAgIGVzdCA9IHNlbGYuX2VzdGlsbwogICAgICAg
:::ICAgICBlc3QuY29uZmlndXJlKCdneC5UQ29tYm9ib3gnLAogICAgICAgICAgICAg
:::ICAgICAgICAgICAgIGZpZWxkYmFja2dyb3VuZD10WydjYW1wbyddLCBiYWNrZ3Jv
:::dW5kPXRbJ2JvdG9uJ10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgZm9yZWdy
:::b3VuZD10Wyd0ZXh0byddLCBhcnJvd2NvbG9yPXRbJ3RleHRvJ10sCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgYm9yZGVyY29sb3I9dFsnY2FtcG9fYm9yZGUnXSwK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBsaWdodGNvbG9yPXRbJ2NhbXBvX2Jv
:::cmRlJ10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgZGFya2NvbG9yPXRbJ2Nh
:::bXBvX2JvcmRlJ10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgaW5zZXJ0Y29s
:::b3I9dFsndGV4dG8nXSkKICAgICAgICAgICAgZXN0Lm1hcCgnZ3guVENvbWJvYm94
:::JywKICAgICAgICAgICAgICAgICAgICBmaWVsZGJhY2tncm91bmQ9WygncmVhZG9u
:::bHknLCB0WydjYW1wbyddKV0sCiAgICAgICAgICAgICAgICAgICAgZm9yZWdyb3Vu
:::ZD1bKCdyZWFkb25seScsIHRbJ3RleHRvJ10pXSkKICAgICAgICAgICAgZXN0LmNv
:::bmZpZ3VyZSgnZ3guSG9yaXpvbnRhbC5UUHJvZ3Jlc3NiYXInLAogICAgICAgICAg
:::ICAgICAgICAgICAgICAgIHRyb3VnaGNvbG9yPXRbJ3Ryb3VnaCddLCBiYWNrZ3Jv
:::dW5kPXRbJ2FjZW50byddLAogICAgICAgICAgICAgICAgICAgICAgICAgIGJvcmRl
:::cmNvbG9yPXRbJ2ZvbmRvJ10sIGxpZ2h0Y29sb3I9dFsnYWNlbnRvJ10sCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgZGFya2NvbG9yPXRbJ2FjZW50byddKQogICAg
:::ICAgICAgICBzZWxmLm9wdGlvbl9hZGQoJypUQ29tYm9ib3gqTGlzdGJveC5iYWNr
:::Z3JvdW5kJywgdFsnY2FtcG8nXSkKICAgICAgICAgICAgc2VsZi5vcHRpb25fYWRk
:::KCcqVENvbWJvYm94Kkxpc3Rib3guZm9yZWdyb3VuZCcsIHRbJ3RleHRvJ10pCiAg
:::ICAgICAgICAgIHNlbGYub3B0aW9uX2FkZCgnKlRDb21ib2JveCpMaXN0Ym94LnNl
:::bGVjdEJhY2tncm91bmQnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgdFsn
:::Ym90b25fYWN0J10pCiAgICAgICAgICAgIHNlbGYub3B0aW9uX2FkZCgnKlRDb21i
:::b2JveCpMaXN0Ym94LnNlbGVjdEZvcmVncm91bmQnLAogICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgdFsnYm90b25fdHh0J10pCiAgICAgICAgICAgIHNlbGYuX3Jl
:::ZnJlc2Nhcl9wbGFjZWhvbGRlcigpCgogICAgICAgIGRlZiBfcmVmcmVzY2FyX3Bs
:::YWNlaG9sZGVyKHNlbGYpOgogICAgICAgICAgICB0ID0gVEVNQVNbc2VsZi5fdGVt
:::YV9hY3R1YWxdCiAgICAgICAgICAgIGlmIHNlbGYuX2VuX3BsYWNlaG9sZGVyOgog
:::ICAgICAgICAgICAgICAgc2VsZi5lbnRfdXJsLmNvbmZpZ3VyZShmZz10WydwbGFj
:::ZWhvbGRlciddKQogICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgc2Vs
:::Zi5lbnRfdXJsLmNvbmZpZ3VyZShmZz10Wyd0ZXh0byddKQoKICAgICAgICAjIC0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBl
:::dmVudG9zCiAgICAgICAgZGVmIF9jb25lY3Rhcl9ldmVudG9zKHNlbGYpOgogICAg
:::ICAgICAgICBzZWxmLmNtYl90ZW1hLmJpbmQoJzw8Q29tYm9ib3hTZWxlY3RlZD4+
:::Jywgc2VsZi5fb25fdGVtYSkKICAgICAgICAgICAgc2VsZi5jbWJfZm9ybWF0by5i
:::aW5kKCc8PENvbWJvYm94U2VsZWN0ZWQ+PicsIHNlbGYuX29uX2Zvcm1hdG8pCiAg
:::ICAgICAgICAgIHNlbGYuY21iX2NhbGlkYWQuYmluZCgnPDxDb21ib2JveFNlbGVj
:::dGVkPj4nLCBsYW1iZGEgZTogc2VsZi5fZ3VhcmRhcigpKQogICAgICAgICAgICBz
:::ZWxmLmNoa19lbWJlYmVyLmNvbmZpZ3VyZShjb21tYW5kPXNlbGYuX2d1YXJkYXIp
:::CiAgICAgICAgICAgIHNlbGYuZW50X3VybC5iaW5kKCc8Rm9jdXNJbj4nLCBzZWxm
:::Ll9vbl9mb2N1c191cmxfaW4pCiAgICAgICAgICAgIHNlbGYuZW50X3VybC5iaW5k
:::KCc8Rm9jdXNPdXQ+Jywgc2VsZi5fb25fZm9jdXNfdXJsX291dCkKICAgICAgICAg
:::ICAgc2VsZi5lbnRfdXJsLmJpbmQoJzxSZXR1cm4+JywgbGFtYmRhIGU6IHNlbGYu
:::X2FjY2lvbl9kZXNjYXJnYXIoKSkKICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0
:::YS5iaW5kKCc8Rm9jdXNPdXQ+Jywgc2VsZi5fb25fY2FycGV0YV9lc2NyaXRhKQog
:::ICAgICAgICAgICBzZWxmLnByb3RvY29sKCdXTV9ERUxFVEVfV0lORE9XJywgc2Vs
:::Zi5fYWxfY2VycmFyKQogICAgICAgICAgICBzZWxmLmJpbmQoJzxDb250cm9sLXU+
:::JywgbGFtYmRhIGU6IHNlbGYuX2FjY2lvbl9hY3R1YWxpemFyKCkpCiAgICAgICAg
:::ICAgIHNlbGYuYmluZCgnPENvbnRyb2wtbD4nLCBsYW1iZGEgZTogc2VsZi5fbGlt
:::cGlhcl9sb2coKSkKICAgICAgICAgICAgc2VsZi5iaW5kKCc8Q29udHJvbC1VPics
:::IGxhbWJkYSBlOiBzZWxmLl9hY2Npb25fYWN0dWFsaXphcigpKQoKICAgICAgICBk
:::ZWYgX29uX2ZvY3VzX3VybF9pbihzZWxmLCBfZT1Ob25lKToKICAgICAgICAgICAg
:::aWYgc2VsZi5fZW5fcGxhY2Vob2xkZXI6CiAgICAgICAgICAgICAgICBzZWxmLmVu
:::dF91cmwuZGVsZXRlKDAsICdlbmQnKQogICAgICAgICAgICAgICAgc2VsZi5fZW5f
:::cGxhY2Vob2xkZXIgPSBGYWxzZQogICAgICAgICAgICAgICAgc2VsZi5fcmVmcmVz
:::Y2FyX3BsYWNlaG9sZGVyKCkKCiAgICAgICAgZGVmIF9vbl9mb2N1c191cmxfb3V0
:::KHNlbGYsIF9lPU5vbmUpOgogICAgICAgICAgICBpZiBub3Qgc2VsZi5lbnRfdXJs
:::LmdldCgpOgogICAgICAgICAgICAgICAgc2VsZi5fZW5fcGxhY2Vob2xkZXIgPSBU
:::cnVlCiAgICAgICAgICAgICAgICBzZWxmLl9wb25lcl9wbGFjZWhvbGRlcigpCiAg
:::ICAgICAgICAgICAgICBzZWxmLl9yZWZyZXNjYXJfcGxhY2Vob2xkZXIoKQoKICAg
:::ICAgICBkZWYgX29uX3RlbWEoc2VsZiwgX2U9Tm9uZSk6CiAgICAgICAgICAgIHNl
:::bGYuX3RlbWFfYWN0dWFsID0gc2VsZi5jbWJfdGVtYS5nZXQoKQogICAgICAgICAg
:::ICBBSlVTVEVTWyd0ZW1hJ10gPSBzZWxmLl90ZW1hX2FjdHVhbAogICAgICAgICAg
:::ICBndWFyZGFyX2FqdXN0ZXMoKQogICAgICAgICAgICBzZWxmLl9hcGxpY2FyX3Rl
:::bWEoKQoKICAgICAgICBkZWYgX29uX2Zvcm1hdG8oc2VsZiwgX2U9Tm9uZSk6CiAg
:::ICAgICAgICAgIGZtdCA9IHNlbGYuX2ZtdF9hY3R1YWwoKQogICAgICAgICAgICBz
:::ZWxmLl9yZWNhcmdhcl9jYWxpZGFkZXMoZm10KQogICAgICAgICAgICBzZWxmLl9n
:::dWFyZGFyKCkKICAgICAgICAgICAgc2VsZi5sYmxfZXN0aW1hY2lvbi5jb25maWd1
:::cmUoCiAgICAgICAgICAgICAgICB0ZXh0PSdJbnRyb2R1Y2UgdW5hIFVSTCB5IHB1
:::bHNhIEVzdGltYXIuJywKICAgICAgICAgICAgICAgIGZnPVRFTUFTW3NlbGYuX3Rl
:::bWFfYWN0dWFsXVsndGV4dG8nXSkKCiAgICAgICAgZGVmIF9mbXRfYWN0dWFsKHNl
:::bGYpOgogICAgICAgICAgICB0ZXh0byA9IHNlbGYuY21iX2Zvcm1hdG8uZ2V0KCkK
:::ICAgICAgICAgICAgZm9yIGNsYXZlLCBmIGluIEZPUk1BVE9TLml0ZW1zKCk6CiAg
:::ICAgICAgICAgICAgICBpZiBmWyd0ZXh0byddID09IHRleHRvOgogICAgICAgICAg
:::ICAgICAgICAgIHJldHVybiBjbGF2ZQogICAgICAgICAgICByZXR1cm4gJ0FBQycK
:::CiAgICAgICAgZGVmIF9yZWNhcmdhcl9jYWxpZGFkZXMoc2VsZiwgY2xhdmVfZm10
:::LCBjYWxpZGFkX3ByZXZpYT1Ob25lKToKICAgICAgICAgICAgZiA9IEZPUk1BVE9T
:::W2NsYXZlX2ZtdF0KICAgICAgICAgICAgc2VsZi5jbWJfY2FsaWRhZFsndmFsdWVz
:::J10gPSBmWydjYWxpZGFkZXMnXQogICAgICAgICAgICBpZiBjYWxpZGFkX3ByZXZp
:::YSBhbmQgY2FsaWRhZF9wcmV2aWEgaW4gZlsnY2FsaWRhZGVzJ106CiAgICAgICAg
:::ICAgICAgICBzZWxmLmNtYl9jYWxpZGFkLnNldChjYWxpZGFkX3ByZXZpYSkKICAg
:::ICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgIHNlbGYuY21iX2NhbGlkYWQu
:::c2V0KGZbJ2RlZmVjdG8nXSkKICAgICAgICAgICAgQUpVU1RFU1snZm9ybWF0bydd
:::ID0gY2xhdmVfZm10CiAgICAgICAgICAgIEFKVVNURVNbJ2NhbGlkYWQnXSA9IHNl
:::bGYuY21iX2NhbGlkYWQuZ2V0KCkKCiAgICAgICAgZGVmIF9ndWFyZGFyKHNlbGYp
:::OgogICAgICAgICAgICBBSlVTVEVTWydmb3JtYXRvJ10gPSBzZWxmLl9mbXRfYWN0
:::dWFsKCkKICAgICAgICAgICAgQUpVU1RFU1snY2FsaWRhZCddID0gc2VsZi5jbWJf
:::Y2FsaWRhZC5nZXQoKQogICAgICAgICAgICBBSlVTVEVTWydlbWJlYmVyJ10gPSBi
:::b29sKHNlbGYudmFyX2VtYmViZXIuZ2V0KCkpCiAgICAgICAgICAgIEFKVVNURVNb
:::J2Rlc3Rpbm8nXSA9IHNlbGYuZW50X2NhcnBldGEuZ2V0KCkuc3RyaXAoKQogICAg
:::ICAgICAgICBndWFyZGFyX2FqdXN0ZXMoKQoKICAgICAgICBkZWYgX29uX2NhcnBl
:::dGFfZXNjcml0YShzZWxmLCBfZT1Ob25lKToKICAgICAgICAgICAgcCA9IFBhdGgo
:::b3MucGF0aC5leHBhbmR2YXJzKAogICAgICAgICAgICAgICAgc2VsZi5lbnRfY2Fy
:::cGV0YS5nZXQoKS5zdHJpcCgpLnN0cmlwKCciJykpKQogICAgICAgICAgICB0cnk6
:::CiAgICAgICAgICAgICAgICBwLm1rZGlyKHBhcmVudHM9VHJ1ZSwgZXhpc3Rfb2s9
:::VHJ1ZSkKICAgICAgICAgICAgICAgIEFKVVNURVNbJ2Rlc3Rpbm8nXSA9IHN0cihw
:::KQogICAgICAgICAgICAgICAgZ3VhcmRhcl9hanVzdGVzKCkKICAgICAgICAgICAg
:::ZXhjZXB0IE9TRXJyb3IgYXMgZToKICAgICAgICAgICAgICAgIHNlbGYuX2xvZyhm
:::J05vIHNlIHB1ZG8gdXNhciBlc2EgY2FycGV0YToge2V9JywgJ2Vycm9yJykKCiAg
:::ICAgICAgZGVmIF9jYW1iaWFyX2NhcnBldGEoc2VsZik6CiAgICAgICAgICAgIGFj
:::dHVhbCA9IHNlbGYuZW50X2NhcnBldGEuZ2V0KCkuc3RyaXAoKSBvciBBSlVTVEVT
:::WydkZXN0aW5vJ10KICAgICAgICAgICAgbnVldmEgPSBmaWxlZGlhbG9nLmFza2Rp
:::cmVjdG9yeSgKICAgICAgICAgICAgICAgIHRpdGxlPSdFbGlnZSBsYSBjYXJwZXRh
:::IGRvbmRlIGd1YXJkYXIgbGFzIGRlc2NhcmdhcycsCiAgICAgICAgICAgICAgICBp
:::bml0aWFsZGlyPWFjdHVhbCBpZiBvcy5wYXRoLmlzZGlyKGFjdHVhbCkgZWxzZSBz
:::dHIoUGF0aC5ob21lKCkpKQogICAgICAgICAgICBpZiBub3QgbnVldmE6CiAgICAg
:::ICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAg
:::ICAgUGF0aChudWV2YSkubWtkaXIocGFyZW50cz1UcnVlLCBleGlzdF9vaz1UcnVl
:::KQogICAgICAgICAgICBleGNlcHQgT1NFcnJvciBhcyBlOgogICAgICAgICAgICAg
:::ICAgbWVzc2FnZWJveC5zaG93ZXJyb3IoJ0NhcnBldGEgbm8gdsOhbGlkYScsIHN0
:::cihlKSkKICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICBzZWxmLmVu
:::dF9jYXJwZXRhLmRlbGV0ZSgwLCAnZW5kJykKICAgICAgICAgICAgc2VsZi5lbnRf
:::Y2FycGV0YS5pbnNlcnQoMCwgbnVldmEpCiAgICAgICAgICAgIEFKVVNURVNbJ2Rl
:::c3Rpbm8nXSA9IG51ZXZhCiAgICAgICAgICAgIGd1YXJkYXJfYWp1c3RlcygpCiAg
:::ICAgICAgICAgIHNlbGYuX2xvZygnQ2FycGV0YSBkZSBndWFyZGFkbzogJyArIG51
:::ZXZhLCAnZ3JpcycpCgogICAgICAgIGRlZiBfYWJyaXJfZGVzdGlubyhzZWxmKToK
:::ICAgICAgICAgICAgcCA9IFBhdGgob3MucGF0aC5leHBhbmR2YXJzKAogICAgICAg
:::ICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5nZXQoKS5zdHJpcCgpLnN0cmlwKCci
:::JykpKQogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBwLm1rZGlyKHBh
:::cmVudHM9VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgICAgICAgICAgZXhjZXB0IE9T
:::RXJyb3I6CiAgICAgICAgICAgICAgICBwYXNzCiAgICAgICAgICAgIGFicmlyX2Nh
:::cnBldGEocCkKCiAgICAgICAgZGVmIF9hbF9jZXJyYXIoc2VsZik6CiAgICAgICAg
:::ICAgIGlmIHNlbGYuX29jdXBhZG8gYW5kIG5vdCBtZXNzYWdlYm94LmFza29rY2Fu
:::Y2VsKAogICAgICAgICAgICAgICAgICAgICdTYWxpcicsICdIYXkgdW5hIHRhcmVh
:::IGVuIGN1cnNvLiAnCiAgICAgICAgICAgICAgICAgICAgJ8K/U2VndXJvIHF1ZSBx
:::dWllcmVzIHNhbGlyPycpOgogICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAg
:::ICAgIHNlbGYuZGVzdHJveSgpCgogICAgICAgICMgLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIHJlZ2lzdHJvIChsb2cpCiAg
:::ICAgICAgZGVmIF9sb2coc2VsZiwgbXNnLCB0YWc9J2luZm8nKToKICAgICAgICAg
:::ICAgc2VsZi50eHRfbG9nLmNvbmZpZ3VyZShzdGF0ZT0nbm9ybWFsJykKICAgICAg
:::ICAgICAgbl9saW5lYXMgPSBpbnQoc2VsZi50eHRfbG9nLmluZGV4KCdlbmQtMWMn
:::KS5zcGxpdCgnLicpWzBdKQogICAgICAgICAgICBpZiBuX2xpbmVhcyA+IDkwMDoK
:::ICAgICAgICAgICAgICAgIHNlbGYudHh0X2xvZy5kZWxldGUoJzEuMCcsICcyMDAu
:::MCcpCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5pbnNlcnQoJ2VuZCcsIHN0ciht
:::c2cpICsgJ1xuJywgdGFnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuc2VlKCdl
:::bmQnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuY29uZmlndXJlKHN0YXRlPSdk
:::aXNhYmxlZCcpCgogICAgICAgIGRlZiBfbGltcGlhcl9sb2coc2VsZik6CiAgICAg
:::ICAgICAgIHNlbGYudHh0X2xvZy5jb25maWd1cmUoc3RhdGU9J25vcm1hbCcpCiAg
:::ICAgICAgICAgIHNlbGYudHh0X2xvZy5kZWxldGUoJzEuMCcsICdlbmQnKQogICAg
:::ICAgICAgICBzZWxmLnR4dF9sb2cuY29uZmlndXJlKHN0YXRlPSdkaXNhYmxlZCcp
:::CgogICAgICAgIGRlZiBfYm9tYmVhcl9jb2xhKHNlbGYpOgogICAgICAgICAgICB0
:::cnk6CiAgICAgICAgICAgICAgICB3aGlsZSBUcnVlOgogICAgICAgICAgICAgICAg
:::ICAgIGV2ID0gc2VsZi5jb2xhLmdldF9ub3dhaXQoKQogICAgICAgICAgICAgICAg
:::ICAgIHRpcG8gPSBldlswXQogICAgICAgICAgICAgICAgICAgIGlmIHRpcG8gPT0g
:::J2xvZyc6CiAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuX2xvZyhldlsxXSwg
:::ZXZbMl0pCiAgICAgICAgICAgICAgICAgICAgZWxpZiB0aXBvID09ICdwcm9nJzoK
:::ICAgICAgICAgICAgICAgICAgICAgICAgcGN0LCB0ZXh0byA9IGV2WzFdLCBldlsy
:::XQogICAgICAgICAgICAgICAgICAgICAgICBpZiBwY3QgaXMgTm9uZToKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYmFycmEuc3RvcCgpCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICBzZWxmLmJhcnJhLmNvbmZpZ3VyZShtb2RlPSdp
:::bmRldGVybWluYXRlJykKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYu
:::YmFycmEuc3RhcnQoNjApCiAgICAgICAgICAgICAgICAgICAgICAgIGVsc2U6CiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBzZWxmLmJhcnJhLnN0b3AoKQogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5iYXJyYS5jb25maWd1cmUobW9k
:::ZT0nZGV0ZXJtaW5hdGUnKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgc2Vs
:::Zi5iYXJyYS5jb25maWd1cmUodmFsdWU9bWF4KDAsIG1pbigxMDAsIHBjdCkpKQog
:::ICAgICAgICAgICAgICAgICAgICAgICBzZWxmLmxibF9lc3RhZG8uY29uZmlndXJl
:::KHRleHQ9dGV4dG8pCiAgICAgICAgICAgICAgICAgICAgZWxpZiB0aXBvID09ICdl
:::c3RpbWFjaW9uJzoKICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5sYmxfZXN0
:::aW1hY2lvbi5jb25maWd1cmUoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0
:::ZXh0PWV2WzFdLCBmZz1URU1BU1tzZWxmLl90ZW1hX2FjdHVhbF1bJ2FjZW50bydd
:::KQogICAgICAgICAgICAgICAgICAgIGVsaWYgdGlwbyA9PSAnZmluJzoKICAgICAg
:::ICAgICAgICAgICAgICAgICAgc2VsZi5fZmluX3RhcmVhKGV2WzFdLCBldlsyXSwg
:::ZXZbM10gaWYgbGVuKGV2KSA+IDMgZWxzZSAnJykKICAgICAgICAgICAgZXhjZXB0
:::IHF1ZXVlLkVtcHR5OgogICAgICAgICAgICAgICAgcGFzcwogICAgICAgICAgICBz
:::ZWxmLmFmdGVyKDgwLCBzZWxmLl9ib21iZWFyX2NvbGEpCgogICAgICAgICMgLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIHRh
:::cmVhcwogICAgICAgIGRlZiBfaGFiaWxpdGFyX2FjY2lvbmVzKHNlbGYsIG9uKToK
:::ICAgICAgICAgICAgZXN0YWRvID0gJ25vcm1hbCcgaWYgb24gZWxzZSAnZGlzYWJs
:::ZWQnCiAgICAgICAgICAgIGZvciBiIGluIChzZWxmLmJ0bl9kZXNjYXJnYXIsIHNl
:::bGYuYnRuX2NvbXByb2JhciwKICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYnRu
:::X2VzdGltYXIsIHNlbGYuYnRuX2NhbWJpYXIsIHNlbGYuYnRuX2FicmlyLAogICAg
:::ICAgICAgICAgICAgICAgICAgc2VsZi5idG5feCk6CiAgICAgICAgICAgICAgICBi
:::LmNvbmZpZ3VyZShzdGF0ZT1lc3RhZG8sIGN1cnNvcj0naGFuZDInIGlmIG9uIGVs
:::c2UgJ2Fycm93JykKCiAgICAgICAgZGVmIF9pbmljaWFyKHNlbGYsIG9iamV0aXZv
:::LCBjZmcsIHRleHRvKToKICAgICAgICAgICAgaWYgc2VsZi5fb2N1cGFkbzoKICAg
:::ICAgICAgICAgICAgIHNlbGYuX2xvZygnWWEgaGF5IHVuYSB0YXJlYSBlbiBjdXJz
:::bzsgZXNwZXJhIGEgcXVlIHRlcm1pbmUuJywKICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAnYXZpc28nKQogICAgICAgICAgICAgICAgcmV0dXJuIEZhbHNlCiAgICAg
:::ICAgICAgIHNlbGYuX29jdXBhZG8gPSBUcnVlCiAgICAgICAgICAgIHNlbGYuX2hh
:::YmlsaXRhcl9hY2Npb25lcyhGYWxzZSkKICAgICAgICAgICAgc2VsZi5sYmxfZXN0
:::YWRvLmNvbmZpZ3VyZSh0ZXh0PXRleHRvKQogICAgICAgICAgICB0aHJlYWRpbmcu
:::VGhyZWFkKHRhcmdldD1vYmpldGl2bywgYXJncz0oY2ZnLCksIGRhZW1vbj1UcnVl
:::KS5zdGFydCgpCiAgICAgICAgICAgIHJldHVybiBUcnVlCgogICAgICAgIGRlZiBf
:::ZmluX3RhcmVhKHNlbGYsIHRpcG8sIG9rLCBtZW5zYWplPScnKToKICAgICAgICAg
:::ICAgc2VsZi5fb2N1cGFkbyA9IEZhbHNlCiAgICAgICAgICAgIHNlbGYuX2hhYmls
:::aXRhcl9hY2Npb25lcyhUcnVlKQogICAgICAgICAgICBzZWxmLmJhcnJhLnN0b3Ao
:::KQogICAgICAgICAgICBzZWxmLmJhcnJhLmNvbmZpZ3VyZShtb2RlPSdkZXRlcm1p
:::bmF0ZScpCiAgICAgICAgICAgIHNlbGYuYmFycmEuY29uZmlndXJlKHZhbHVlPTAp
:::CiAgICAgICAgICAgIGlmIHRpcG8gPT0gJ2Rlc2NhcmdhJyBhbmQgb2s6CiAgICAg
:::ICAgICAgICAgICBzZWxmLmxibF9lc3RhZG8uY29uZmlndXJlKHRleHQ9J0xpc3Rv
:::LicpCiAgICAgICAgICAgICAgICAjIExhIGRlc2NhcmdhIGZ1ZSBiaWVuOiBzZSBs
:::aW1waWEgbGEgVVJMIHBhcmEgbGEgc2lndWllbnRlLgogICAgICAgICAgICAgICAg
:::c2VsZi5fcmVzZXRfdXJsKCkKICAgICAgICAgICAgZWxpZiBub3Qgb2s6CiAgICAg
:::ICAgICAgICAgICBzZWxmLmxibF9lc3RhZG8uY29uZmlndXJlKHRleHQ9J1Rlcm1p
:::bmFkbyBjb24gZXJyb3Jlcy4nKQogICAgICAgICAgICAgICAgaWYgdGlwbyA9PSAn
:::ZGVzY2FyZ2EnOgogICAgICAgICAgICAgICAgICAgIG1lc3NhZ2Vib3guc2hvd2Vy
:::cm9yKAogICAgICAgICAgICAgICAgICAgICAgICAnRXJyb3InLCBtZW5zYWplIG9y
:::ICdObyBzZSBwdWRvIGNvbXBsZXRhciBsYSB0YXJlYS4gJwogICAgICAgICAgICAg
:::ICAgICAgICAgICAnUmV2aXNhIGVsIHJlZ2lzdHJvIHBhcmEgbcOhcyBkZXRhbGxl
:::cy4nKQoKICAgICAgICBkZWYgX3VybF92YWxpZGEoc2VsZik6CiAgICAgICAgICAg
:::IGlmIHNlbGYuX2VuX3BsYWNlaG9sZGVyOgogICAgICAgICAgICAgICAgc2VsZi5f
:::bG9nKCdQcmltZXJvIHBlZ2EgbGEgVVJMIGRlbCB2aWRlbyBkZSBZb3VUdWJlLics
:::ICdhdmlzbycpCiAgICAgICAgICAgICAgICByZXR1cm4gTm9uZQogICAgICAgICAg
:::ICB1ID0gc2VsZi5lbnRfdXJsLmdldCgpLnN0cmlwKCkuc3RyaXAoJyInKS5zdHJp
:::cCgiJyIpCiAgICAgICAgICAgIGlmIG5vdCB1OgogICAgICAgICAgICAgICAgc2Vs
:::Zi5fbG9nKCdMYSBVUkwgZXN0w6EgdmFjw61hLicsICdhdmlzbycpCiAgICAgICAg
:::ICAgICAgICByZXR1cm4gTm9uZQogICAgICAgICAgICBpZiBub3QgcmUubWF0Y2go
:::cideaHR0cHM/Oi8vJywgdSwgcmUuSSk6CiAgICAgICAgICAgICAgICBpZiByZS5t
:::YXRjaChyJ153d3dcLicsIHUsIHJlLkkpOgogICAgICAgICAgICAgICAgICAgIHUg
:::PSAnaHR0cHM6Ly8nICsgdQogICAgICAgICAgICAgICAgZWxzZToKICAgICAgICAg
:::ICAgICAgICAgICBzZWxmLl9sb2coJ0VzbyBubyBwYXJlY2UgdW5hIFVSTCAoZGVi
:::ZSBlbXBlemFyIHBvciAnCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICdo
:::dHRwOi8vIG8gaHR0cHM6Ly8pJywgJ2Vycm9yJykKICAgICAgICAgICAgICAgICAg
:::ICByZXR1cm4gTm9uZQogICAgICAgICAgICAjIE9KTzogYXF1w60gTk8gc2UgcXVp
:::dGEgbGlzdD07IHNpIGxhIFVSTCB0cmFlIHVuYSBwbGF5bGlzdCwKICAgICAgICAg
:::ICAgIyBfYWNjaW9uX2Rlc2NhcmdhciBwcmVndW50YXLDoSBxdcOpIGhhY2VyIGNv
:::biBlbGxhLgogICAgICAgICAgICByZXR1cm4gdQoKICAgICAgICBkZWYgX2FjY2lv
:::bl9lc3RpbWFyKHNlbGYpOgogICAgICAgICAgICB1cmwgPSBzZWxmLl91cmxfdmFs
:::aWRhKCkKICAgICAgICAgICAgaWYgbm90IHVybDoKICAgICAgICAgICAgICAgIHJl
:::dHVybgogICAgICAgICAgICBzZWxmLl9ndWFyZGFyKCkKICAgICAgICAgICAgY2Zn
:::ID0geyd1cmwnOiB1cmx9CiAgICAgICAgICAgIHNlbGYuX2luaWNpYXIoc2VsZi5f
:::aGlsb19lc3RpbWFyLCBjZmcsICdFc3RpbWFuZG8gdGFtYcOxby4uLicpCiAgICAg
:::ICAgICAgIHNlbGYubGJsX2VzdGltYWNpb24uY29uZmlndXJlKAogICAgICAgICAg
:::ICAgICAgdGV4dD0nQ2FsY3VsYW5kby4uLicsIGZnPVRFTUFTW3NlbGYuX3RlbWFf
:::YWN0dWFsXVsndGV4dG8yJ10pCgogICAgICAgIGRlZiBfYWNjaW9uX2Rlc2Nhcmdh
:::cihzZWxmKToKICAgICAgICAgICAgdXJsID0gc2VsZi5fdXJsX3ZhbGlkYSgpCiAg
:::ICAgICAgICAgIGlmIG5vdCB1cmw6CiAgICAgICAgICAgICAgICByZXR1cm4KICAg
:::ICAgICAgICAgc2VsZi5fZ3VhcmRhcigpCiAgICAgICAgICAgIHBsYXlsaXN0ID0g
:::RmFsc2UKICAgICAgICAgICAgaWYgZXNfdXJsX3BsYXlsaXN0KHVybCk6CiAgICAg
:::ICAgICAgICAgICByID0gbWVzc2FnZWJveC5hc2t5ZXNub2NhbmNlbCgKICAgICAg
:::ICAgICAgICAgICAgICAnTXVzaWtBTEFOIOKAlCBsaXN0YSBkZSByZXByb2R1Y2Np
:::w7NuJywKICAgICAgICAgICAgICAgICAgICAnRXN0YSBVUkwgcGVydGVuZWNlIGEg
:::dW5hIGxpc3RhIGRlIHJlcHJvZHVjY2nDs24uXG5cbicKICAgICAgICAgICAgICAg
:::ICAgICAnICBTw40gIOKGkiAgZGVzY2FyZ2FyIGxhIHBsYXlsaXN0IGNvbXBsZXRh
:::XG4nCiAgICAgICAgICAgICAgICAgICAgJyAgICAgICAgIChwYXVzYSBkZSAyIHMg
:::ZW50cmUgY2FuY2lvbmVzKVxuJwogICAgICAgICAgICAgICAgICAgICcgIE5PICDi
:::hpIgIGRlc2NhcmdhciBzb2xvIGVzdGEgY2FuY2nDs25cbicKICAgICAgICAgICAg
:::ICAgICAgICAnICBDYW5jZWxhciAg4oaSICBubyBkZXNjYXJnYXIgbmFkYScpCiAg
:::ICAgICAgICAgICAgICBpZiByIGlzIE5vbmU6CiAgICAgICAgICAgICAgICAgICAg
:::c2VsZi5fbG9nKCdEZXNjYXJnYSBjYW5jZWxhZGEuJywgJ2dyaXMnKQogICAgICAg
:::ICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICAgICAgaWYgcjoKICAgICAg
:::ICAgICAgICAgICAgICBwbGF5bGlzdCA9IFRydWUKICAgICAgICAgICAgICAgIGVs
:::aWYgZXNfc29sb19saXN0YSh1cmwpOgogICAgICAgICAgICAgICAgICAgICMgRXMg
:::dW5hIHBsYXlsaXN0IHB1cmE6IG5vIGhheSAidW5hIGNhbmNpw7NuIiBhaMOtCiAg
:::ICAgICAgICAgICAgICAgICAgc2VsZi5fbG9nKCdFc2EgVVJMIGVzIHVuYSBsaXN0
:::YSBjb21wbGV0YTsgc2UgZGVzY2FyZ2Fyw6EgJwogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAnZW50ZXJhLicsICdhdmlzbycpCiAgICAgICAgICAgICAgICAg
:::ICAgcGxheWxpc3QgPSBUcnVlCiAgICAgICAgICAgIGNmZyA9IHsndXJsJzogdXJs
:::LCAncGxheWxpc3QnOiBwbGF5bGlzdH0KICAgICAgICAgICAgc2VsZi5faW5pY2lh
:::cihzZWxmLl9oaWxvX2Rlc2NhcmdhciwgY2ZnLCAnRGVzY2FyZ2FuZG8uLi4nKQoK
:::ICAgICAgICBkZWYgX2FjY2lvbl9jb21wcm9iYXIoc2VsZik6CiAgICAgICAgICAg
:::IHNlbGYuX2d1YXJkYXIoKQogICAgICAgICAgICBzZWxmLl9pbmljaWFyKHNlbGYu
:::X2hpbG9fY29tcHJvYmFyLCB7fSwKICAgICAgICAgICAgICAgICAgICAgICAgICAn
:::Q29tcHJvYmFuZG8gbGEgY2FycGV0YS4uLicpCgogICAgICAgIGRlZiBfYWNjaW9u
:::X2FjdHVhbGl6YXIoc2VsZik6CiAgICAgICAgICAgIGlmIG5vdCBZVF9ETFA6CiAg
:::ICAgICAgICAgICAgICBzZWxmLl9sb2coJ3l0LWRscCBubyBlc3TDoSBpbnN0YWxh
:::ZG87IGVqZWN1dGEgJwogICAgICAgICAgICAgICAgICAgICAgICAgICdEZXNjYXJn
:::YWRvck11c2ljYS5iYXQuJywgJ2Vycm9yJykKICAgICAgICAgICAgICAgIHJldHVy
:::bgogICAgICAgICAgICBzZWxmLl9pbmljaWFyKHNlbGYuX2hpbG9fYWN0dWFsaXph
:::ciwge30sICdBY3R1YWxpemFuZG8geXQtZGxwLi4uJykKCiAgICAgICAgIyAtLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gaGls
:::b3MKICAgICAgICBkZWYgX2hpbG9fZXN0aW1hcihzZWxmLCBjZmcpOgogICAgICAg
:::ICAgICBjb2xhID0gc2VsZi5jb2xhCgogICAgICAgICAgICBkZWYgbG9nKG0sIHQ9
:::J2luZm8nKToKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkp
:::CgogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBpZiBZVF9ETFAgaXMg
:::Tm9uZToKICAgICAgICAgICAgICAgICAgICBsb2coJ3l0LWRscCBubyBlc3TDoSBp
:::bnN0YWxhZG8uIEVqZWN1dGEgJwogICAgICAgICAgICAgICAgICAgICAgICAnRGVz
:::Y2FyZ2Fkb3JNdXNpY2EuYmF0IHBhcmEgaW5zdGFsYXJsby4nLCAnZXJyb3InKQog
:::ICAgICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZXN0aW1hY2lvbicsICd5dC1k
:::bHAgbm8gZGlzcG9uaWJsZScpKQogICAgICAgICAgICAgICAgICAgIHJldHVybgog
:::ICAgICAgICAgICAgICAgbG9nKCdPYnRlbmllbmRvIGluZm9ybWFjacOzbiBkZWwg
:::dmlkZW8uLi4nLCAnZ3JpcycpCiAgICAgICAgICAgICAgICBvID0geydxdWlldCc6
:::IFRydWUsICdub193YXJuaW5ncyc6IFRydWUsICdub3BsYXlsaXN0JzogVHJ1ZSwK
:::ICAgICAgICAgICAgICAgICAgICAgJ3NvY2tldF90aW1lb3V0JzogMzAsICdsb2dn
:::ZXInOiBSRUdJU1RST30KICAgICAgICAgICAgICAgIGlmIGVzX3VybF9wbGF5bGlz
:::dChjZmdbJ3VybCddKToKICAgICAgICAgICAgICAgICAgICBsb2coJyhsYSBVUkwg
:::Y29udGllbmUgdW5hIHBsYXlsaXN0OiBsYSBlc3RpbWFjacOzbiBlcyAnCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICdzb2xvIGRlbCB2aWRlbyBwZWdhZG8pJywgJ2dy
:::aXMnKQogICAgICAgICAgICAgICAgd2l0aCBZVF9ETFAuWW91dHViZURMKG8pIGFz
:::IHlkbDoKICAgICAgICAgICAgICAgICAgICBpbmZvID0geWRsLmV4dHJhY3RfaW5m
:::byhjZmdbJ3VybCddLCBkb3dubG9hZD1GYWxzZSkKICAgICAgICAgICAgICAgIGR1
:::ciA9IGluZm8uZ2V0KCdkdXJhdGlvbicpCiAgICAgICAgICAgICAgICBpZiBub3Qg
:::ZHVyOgogICAgICAgICAgICAgICAgICAgIGxvZygnTm8gc2UgcHVkbyBvYnRlbmVy
:::IGxhIGR1cmFjacOzbiBkZWwgdmlkZW8uJywgJ2Vycm9yJykKICAgICAgICAgICAg
:::ICAgICAgICBjb2xhLnB1dCgoJ2VzdGltYWNpb24nLCAnU2luIGRhdG9zIHBhcmEg
:::ZXN0aW1hcicpKQogICAgICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAg
:::ICAgICAgY2xhdmUgPSBzZWxmLl9mbXRfYWN0dWFsX3NvbG8oQUpVU1RFUy5nZXQo
:::J2Zvcm1hdG8nLCAnQUFDJykpCiAgICAgICAgICAgICAgICB0YW0gPSBlc3RpbWFy
:::X2J5dGVzKGR1ciwgY2xhdmUsIEFKVVNURVMuZ2V0KCdjYWxpZGFkJyksCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJvb2woQUpVU1RFUy5nZXQo
:::J2VtYmViZXInLCBUcnVlKSkpCiAgICAgICAgICAgICAgICB0aXR1bG8gPSBzdHIo
:::aW5mby5nZXQoJ3RpdGxlJykgb3IgJycpWzo3MF0KICAgICAgICAgICAgICAgIGlm
:::IHRpdHVsbzoKICAgICAgICAgICAgICAgICAgICBsb2coJ+KZqiAnICsgdGl0dWxv
:::LCAndGl0dWxvJykKICAgICAgICAgICAgICAgIHRleHRvID0gKGYnfnt0YW0gLyAx
:::MDQ4NTc2Oi4xZn0gTUIgwrcgJwogICAgICAgICAgICAgICAgICAgICAgICAgZidk
:::dXJhY2nDs24ge2ZtdF90aWVtKGR1cil9IMK3ICcKICAgICAgICAgICAgICAgICAg
:::ICAgICAgIGYne2NsYXZlfSB7QUpVU1RFUy5nZXQoImNhbGlkYWQiLCAiIil9Jy5y
:::c3RyaXAoKSkKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZXN0aW1hY2lvbics
:::IHRleHRvKSkKICAgICAgICAgICAgICAgIGxvZygnRXN0aW1hY2nDs246ICcgKyB0
:::ZXh0bywgJ29rJykKICAgICAgICAgICAgICAgIGxvZygnRWwgdGFtYcOxbyByZWFs
:::IHB1ZWRlIHZhcmlhciBhbGdvIHNlZ8O6biBsYSBmdWVudGUuJywKICAgICAgICAg
:::ICAgICAgICAgICAnZ3JpcycpCiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb24g
:::YXMgZToKICAgICAgICAgICAgICAgIGxvZyhmJ05vIHNlIHB1ZG8gZXN0aW1hcjog
:::e3NlbGYuX21zZ19lcnJvcihlKX0nLCAnZXJyb3InKQogICAgICAgICAgICAgICAg
:::Y29sYS5wdXQoKCdlc3RpbWFjaW9uJywgJ05vIHNlIHB1ZG8gZXN0aW1hcicpKQog
:::ICAgICAgICAgICBmaW5hbGx5OgogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdm
:::aW4nLCAnZXN0aW1hY2lvbicsIFRydWUsICcnKSkKCiAgICAgICAgZGVmIF9mbXRf
:::YWN0dWFsX3NvbG8oc2VsZiwgY2xhdmUpOgogICAgICAgICAgICByZXR1cm4gY2xh
:::dmUgaWYgY2xhdmUgaW4gRk9STUFUT1MgZWxzZSAnQUFDJwoKICAgICAgICBkZWYg
:::X2Rlc2Nhcmdhcl91bmEoc2VsZiwgdXJsLCBjbGF2ZSwgY2FsaWRhZF9hcmcsIGVt
:::YmViZXIsIGRlc3Rpbm8sCiAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbGEp
:::OgogICAgICAgICAgICAiIiJEZXNjYXJnYSB5IGNvbnZpZXJ0ZSBVTkEgVVJMLiBE
:::ZXZ1ZWx2ZSBlbCBQYXRoIGZpbmFsIG8gTm9uZS4iIiIKICAgICAgICAgICAgaWYg
:::Y2xhdmUgPT0gJ1dNQSc6CiAgICAgICAgICAgICAgICByZXR1cm4gZGVzY2FyZ2Fy
:::X3dtYSh1cmwsIGNhbGlkYWRfYXJnLCBkZXN0aW5vLCBlbWJlYmVyLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sYSlbMV0KICAgICAgICAg
:::ICAgaWYgY2xhdmUgPT0gJ0FWSSc6CiAgICAgICAgICAgICAgICByZXR1cm4gZGVz
:::Y2FyZ2FyX2F2aSh1cmwsIGRlc3Rpbm8sIGNvbGEpWzFdCiAgICAgICAgICAgIHJl
:::dHVybiBkZXNjYXJnYXJfYXVkaW8odXJsLCBjbGF2ZSwgY2FsaWRhZF9hcmcsIGRl
:::c3Rpbm8sIGVtYmViZXIsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgY29sYSlbMV0KCiAgICAgICAgZGVmIF9kZXNjYXJnYXJfcGxheWxpc3Qoc2Vs
:::ZiwgdXJsLCBjbGF2ZSwgY2FsaWRhZF9hcmcsIGVtYmViZXIsCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgZGVzdGlubywgY29sYSk6CiAgICAgICAgICAg
:::ICIiIkJhamEgdW5hIGxpc3RhIGVudGVyYSwgY29uIDIgcyBkZSBkZXNjYW5zbyBl
:::bnRyZSBjYW5jaW9uZXMKICAgICAgICAgICAgcGFyYSBubyBzYXR1cmFyIGEgWW91
:::VHViZS4gRGV2dWVsdmUgKGRlc2NhcmdhZGFzLCB0b3RhbCkuIiIiCiAgICAgICAg
:::ICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgogICAgICAgICAgICAgICAgY29sYS5w
:::dXQoKCdsb2cnLCBtLCB0KSkKCiAgICAgICAgICAgIGxvZygnTGV5ZW5kbyBsYSBs
:::aXN0YSBkZSByZXByb2R1Y2Npw7NuLi4uJywgJ2dyaXMnKQogICAgICAgICAgICBv
:::ID0geydxdWlldCc6IFRydWUsICdub193YXJuaW5ncyc6IFRydWUsCiAgICAgICAg
:::ICAgICAgICAgJ2V4dHJhY3RfZmxhdCc6ICdpbl9wbGF5bGlzdCcsICdzb2NrZXRf
:::dGltZW91dCc6IDMwLAogICAgICAgICAgICAgICAgICdsb2dnZXInOiBSRUdJU1RS
:::T30KICAgICAgICAgICAgd2l0aCBZVF9ETFAuWW91dHViZURMKG8pIGFzIHlkbDoK
:::ICAgICAgICAgICAgICAgIGluZm8gPSB5ZGwuZXh0cmFjdF9pbmZvKHVybCwgZG93
:::bmxvYWQ9RmFsc2UpCiAgICAgICAgICAgIGVudHJhZGFzID0gbGlzdChpbmZvLmdl
:::dCgnZW50cmllcycpIG9yIFtdKQogICAgICAgICAgICBpZiBub3QgZW50cmFkYXM6
:::CiAgICAgICAgICAgICAgICBsb2coJ05vIHNlIHZpbyBuaW5ndW5hIGNhbmNpw7Nu
:::IGVuIGxhIGxpc3RhOyBzZSBpbnRlbnRhICcKICAgICAgICAgICAgICAgICAgICAn
:::Y29tbyB2aWRlbyBzdWVsdG8uJywgJ2F2aXNvJykKICAgICAgICAgICAgICAgIGFy
:::Y2hpdm8gPSBzZWxmLl9kZXNjYXJnYXJfdW5hKHNpbl9wbGF5bGlzdCh1cmwpWzBd
:::LCBjbGF2ZSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgIGNhbGlkYWRfYXJnLCBlbWJlYmVyLCBkZXN0aW5vLAogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sYSkKICAgICAg
:::ICAgICAgICAgIHJldHVybiAoMSBpZiBhcmNoaXZvIGVsc2UgMCksIDEKICAgICAg
:::ICAgICAgdGl0dWxvX3BsID0gc3RyKGluZm8uZ2V0KCd0aXRsZScpIG9yICdsaXN0
:::YScpWzo3MF0KICAgICAgICAgICAgdG90YWwgPSBsZW4oZW50cmFkYXMpCiAgICAg
:::ICAgICAgIGxvZyhmJ1BsYXlsaXN0IMKre3RpdHVsb19wbH3CuyDigJQge3RvdGFs
:::fSB2w61kZW8ocykuJywgJ3RpdHVsbycpCiAgICAgICAgICAgIG9rYXMgPSAwCiAg
:::ICAgICAgICAgIGZhbGxvcyA9IFtdCiAgICAgICAgICAgIGZvciBpLCBlIGluIGVu
:::dW1lcmF0ZShlbnRyYWRhcyk6CiAgICAgICAgICAgICAgICB1ID0gc3RyKGUuZ2V0
:::KCd3ZWJwYWdlX3VybCcpIG9yIGUuZ2V0KCd1cmwnKSBvciAnJykKICAgICAgICAg
:::ICAgICAgIGlmIHUgYW5kIG5vdCB1LnN0YXJ0c3dpdGgoJ2h0dHAnKToKICAgICAg
:::ICAgICAgICAgICAgICB1ID0gJ2h0dHBzOi8vd3d3LnlvdXR1YmUuY29tL3dhdGNo
:::P3Y9JyArIHUKICAgICAgICAgICAgICAgIGlmIG5vdCB1IGFuZCBlLmdldCgnaWQn
:::KToKICAgICAgICAgICAgICAgICAgICB1ID0gJ2h0dHBzOi8vd3d3LnlvdXR1YmUu
:::Y29tL3dhdGNoP3Y9JyArIHN0cihlWydpZCddKQogICAgICAgICAgICAgICAgdGl0
:::ID0gc3RyKGUuZ2V0KCd0aXRsZScpIG9yIHUgb3IgJz8nKVs6NzBdCiAgICAgICAg
:::ICAgICAgICBpZiBpOgogICAgICAgICAgICAgICAgICAgIHRpbWUuc2xlZXAoMikg
:::ICAjIGRlc2NhbnNvIGVudHJlIGNhbmNpb25lcwogICAgICAgICAgICAgICAgbG9n
:::KGYnW3tpICsgMX0ve3RvdGFsfV0g4pmqIHt0aXR9JywgJ3RpdHVsbycpCiAgICAg
:::ICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICAgICAgYXJjaGl2byA9IHNl
:::bGYuX2Rlc2Nhcmdhcl91bmEodSwgY2xhdmUsIGNhbGlkYWRfYXJnLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGVtYmVi
:::ZXIsIGRlc3Rpbm8sIGNvbGEpCiAgICAgICAgICAgICAgICBleGNlcHQgRXhjZXB0
:::aW9uIGFzIGUyOgogICAgICAgICAgICAgICAgICAgIGFyY2hpdm8gPSBOb25lCiAg
:::ICAgICAgICAgICAgICAgICAgbG9nKGYn4pyWIFt7aSArIDF9L3t0b3RhbH1dIEZh
:::bGzDszoge3NlbGYuX21zZ19lcnJvcihlMil9JywKICAgICAgICAgICAgICAgICAg
:::ICAgICAgJ2Vycm9yJykKICAgICAgICAgICAgICAgIGlmIGFyY2hpdm8gYW5kIFBh
:::dGgoYXJjaGl2bykuZXhpc3RzKCk6CiAgICAgICAgICAgICAgICAgICAgdHJ5Ogog
:::ICAgICAgICAgICAgICAgICAgICAgICB0YW0gPSBmbXRfdGFtKFBhdGgoYXJjaGl2
:::bykuc3RhdCgpLnN0X3NpemUpCiAgICAgICAgICAgICAgICAgICAgZXhjZXB0IE9T
:::RXJyb3I6CiAgICAgICAgICAgICAgICAgICAgICAgIHRhbSA9ICc/JwogICAgICAg
:::ICAgICAgICAgICAgIGxvZyhmJyAgIOKclCB7UGF0aChhcmNoaXZvKS5uYW1lfSAg
:::KHt0YW19KScsICdvaycpCiAgICAgICAgICAgICAgICAgICAgb2thcyArPSAxCiAg
:::ICAgICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgIGZhbGxvcy5h
:::cHBlbmQodGl0KQogICAgICAgICAgICBsb2coZidQbGF5bGlzdCB0ZXJtaW5hZGE6
:::IHtva2FzfSBkZSB7dG90YWx9IGRlc2NhcmdhZGEocykuJywKICAgICAgICAgICAg
:::ICAgICdvaycgaWYgbm90IGZhbGxvcyBlbHNlICdhdmlzbycpCiAgICAgICAgICAg
:::IGlmIGZhbGxvczoKICAgICAgICAgICAgICAgIGxvZygnU2luIGRlc2Nhcmdhcjog
:::JwogICAgICAgICAgICAgICAgICAgICsgJyDCtyAnLmpvaW4oZls6NDBdIGZvciBm
:::IGluIGZhbGxvc1s6OF0pCiAgICAgICAgICAgICAgICAgICAgKyAoJy4uLicgaWYg
:::bGVuKGZhbGxvcykgPiA4IGVsc2UgJycpLCAnZ3JpcycpCiAgICAgICAgICAgIHJl
:::dHVybiBva2FzLCB0b3RhbAoKICAgICAgICBkZWYgX2hpbG9fZGVzY2FyZ2FyKHNl
:::bGYsIGNmZyk6CiAgICAgICAgICAgIGNvbGEgPSBzZWxmLmNvbGEKCiAgICAgICAg
:::ICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgogICAgICAgICAgICAgICAgY29sYS5w
:::dXQoKCdsb2cnLCBtLCB0KSkKCiAgICAgICAgICAgIHVybCA9IGNmZ1sndXJsJ10K
:::ICAgICAgICAgICAgY2xhdmUgPSBzZWxmLl9mbXRfYWN0dWFsX3NvbG8oQUpVU1RF
:::Uy5nZXQoJ2Zvcm1hdG8nLCAnQUFDJykpCiAgICAgICAgICAgIGNhbGlkYWQgPSBB
:::SlVTVEVTLmdldCgnY2FsaWRhZCcsICcxMjhrJykKICAgICAgICAgICAgZW1iZWJl
:::ciA9IGJvb2woQUpVU1RFUy5nZXQoJ2VtYmViZXInLCBUcnVlKSkKICAgICAgICAg
:::ICAgZGVzdGlubyA9IFBhdGgob3MucGF0aC5leHBhbmR2YXJzKAogICAgICAgICAg
:::ICAgICAgc3RyKEFKVVNURVMuZ2V0KCdkZXN0aW5vJywgX2Rlc3Rpbm9fcG9yX2Rl
:::ZmVjdG8oKSkpKSkKICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgaWYg
:::WVRfRExQIGlzIE5vbmU6CiAgICAgICAgICAgICAgICAgICAgbG9nKCd5dC1kbHAg
:::bm8gZXN0w6EgaW5zdGFsYWRvLiBFamVjdXRhICcKICAgICAgICAgICAgICAgICAg
:::ICAgICAgJ0Rlc2NhcmdhZG9yTXVzaWNhLmJhdCBwYXJhIGluc3RhbGFybG8uJywg
:::J2Vycm9yJykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdk
:::ZXNjYXJnYScsIEZhbHNlLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAn
:::eXQtZGxwIG5vIGVzdMOhIGluc3RhbGFkby4nKSkKICAgICAgICAgICAgICAgICAg
:::ICByZXR1cm4KICAgICAgICAgICAgICAgIGRlc3Rpbm8ubWtkaXIocGFyZW50cz1U
:::cnVlLCBleGlzdF9vaz1UcnVlKQogICAgICAgICAgICAgICAgaWYgY2xhdmUgaW4g
:::KCdGTEFDJywgJ1dBVicpOgogICAgICAgICAgICAgICAgICAgIGNhbGlkYWRfYXJn
:::ID0gJzAnCiAgICAgICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAg
:::IGNhbGlkYWRfYXJnID0gKHJlLnN1YihyJ1teMC05XScsICcnLCBzdHIoY2FsaWRh
:::ZCkpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgb3IgKCcxMjgn
:::IGlmIGNsYXZlID09ICdBQUMnIGVsc2UgJzMyMCcpKQogICAgICAgICAgICAgICAg
:::aWYgY2ZnLmdldCgncGxheWxpc3QnKToKICAgICAgICAgICAgICAgICAgICBva2Fz
:::LCB0b3RhbCA9IHNlbGYuX2Rlc2Nhcmdhcl9wbGF5bGlzdCgKICAgICAgICAgICAg
:::ICAgICAgICAgICAgdXJsLCBjbGF2ZSwgY2FsaWRhZF9hcmcsIGVtYmViZXIsIGRl
:::c3Rpbm8sIGNvbGEpCiAgICAgICAgICAgICAgICAgICAgaWYgb2thcyBhbmQgb2th
:::cyA9PSB0b3RhbDoKICAgICAgICAgICAgICAgICAgICAgICAgbG9nKGYnQ2FycGV0
:::YToge2Rlc3Rpbm99JywgJ2dyaXMnKQogICAgICAgICAgICAgICAgICAgICAgICBj
:::b2xhLnB1dCgoJ2ZpbicsICdkZXNjYXJnYScsIFRydWUsICcnKSkKICAgICAgICAg
:::ICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgICAgICBjb2xhLnB1
:::dCgoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZmluJywgJ2Rlc2Nhcmdh
:::JywgRmFsc2UsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBmJ1NlIGRlc2Nh
:::cmdhcm9uIHtva2FzfSBkZSB7dG90YWx9IGRlIGxhICcKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICdwbGF5bGlzdC4gTGEgVVJMIG5vIHNlIGhhIGJvcnJhZG8g
:::cG9yIHNpICcKICAgICAgICAgICAgICAgICAgICAgICAgICAgICdxdWllcmVzIHJl
:::aW50ZW50YXJsby4nKSkKICAgICAgICAgICAgICAgICAgICByZXR1cm4KICAgICAg
:::ICAgICAgICAgIGFyY2hpdm8gPSBzZWxmLl9kZXNjYXJnYXJfdW5hKHNpbl9wbGF5
:::bGlzdCh1cmwpWzBdLCBjbGF2ZSwKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgIGNhbGlkYWRfYXJnLCBlbWJlYmVyLCBkZXN0aW5v
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::Y29sYSkKICAgICAgICAgICAgICAgIGlmIGFyY2hpdm8gYW5kIFBhdGgoYXJjaGl2
:::bykuZXhpc3RzKCk6CiAgICAgICAgICAgICAgICAgICAgYXJjaGl2byA9IFBhdGgo
:::YXJjaGl2bykKICAgICAgICAgICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAg
:::ICAgICAgICAgIHRhbSA9IGZtdF90YW0oYXJjaGl2by5zdGF0KCkuc3Rfc2l6ZSkK
:::ICAgICAgICAgICAgICAgICAgICBleGNlcHQgT1NFcnJvcjoKICAgICAgICAgICAg
:::ICAgICAgICAgICAgdGFtID0gJz8nCiAgICAgICAgICAgICAgICAgICAgbG9nKGYn
:::4pyUIMKhTGlzdG8hICB7YXJjaGl2by5uYW1lfSAgKHt0YW19KScsICdvaycpCiAg
:::ICAgICAgICAgICAgICAgICAgbG9nKGYnQ2FycGV0YToge2FyY2hpdm8ucGFyZW50
:::fScsICdncmlzJykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2Zpbics
:::ICdkZXNjYXJnYScsIFRydWUsICcnKSkKICAgICAgICAgICAgICAgIGVsc2U6CiAg
:::ICAgICAgICAgICAgICAgICAgbG9nKCdFbCBhcmNoaXZvIGZpbmFsIG5vIGFwYXJl
:::Y2nDsyBkb25kZSBzZSBlc3BlcmFiYS4nLAogICAgICAgICAgICAgICAgICAgICAg
:::ICAnZXJyb3InKQogICAgICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywg
:::J2Rlc2NhcmdhJywgRmFsc2UsICcnKSkKICAgICAgICAgICAgZXhjZXB0IEV4Y2Vw
:::dGlvbiBhcyBlOgogICAgICAgICAgICAgICAgbm9tYnJlX2V4YyA9IHR5cGUoZSku
:::X19uYW1lX18KICAgICAgICAgICAgICAgIGlmIG5vbWJyZV9leGMgPT0gJ0Rvd25s
:::b2FkRXJyb3InOgogICAgICAgICAgICAgICAgICAgIGxpbmVhcyA9IFtsIGZvciBs
:::IGluIHN0cihlKS5zdHJpcCgpLnNwbGl0bGluZXMoKSBpZiBsLnN0cmlwKCldCiAg
:::ICAgICAgICAgICAgICAgICAgbXNnID0gbGluZWFzWzBdWzozMDBdIGlmIGxpbmVh
:::cyBlbHNlICdlcnJvciBkZXNjb25vY2lkbycKICAgICAgICAgICAgICAgICAgICBs
:::b2coJ+KcliBObyBzZSBwdWRvIGRlc2NhcmdhcjogJyArIG1zZywgJ2Vycm9yJykK
:::ICAgICAgICAgICAgICAgICAgICBsb2coJ0NvbnNlam9zOiByZXZpc2EgbGEgVVJM
:::IHkgdHUgY29uZXhpw7NuOyBzaSBZb3VUdWJlICcKICAgICAgICAgICAgICAgICAg
:::ICAgICAgJ2NhbWJpw7MgYWxnbywgcHVsc2EgQ3RybCtVIChhY3R1YWxpemFyIHl0
:::LWRscCkgeSAnCiAgICAgICAgICAgICAgICAgICAgICAgICdyZWludGVudGEuJywg
:::J2dyaXMnKQogICAgICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgICAg
:::ICBsb2coZifinJYgRXJyb3IgaW5lc3BlcmFkbyAoe25vbWJyZV9leGN9KToge2V9
:::JywgJ2Vycm9yJykKICAgICAgICAgICAgICAgICAgICB0YiA9IHRyYWNlYmFjay5m
:::b3JtYXRfZXhjKGxpbWl0PTMpCiAgICAgICAgICAgICAgICAgICAgdHJ5OgogICAg
:::ICAgICAgICAgICAgICAgICAgICB3aXRoIG9wZW4oTE9HX0VSUk9SRVMsICdhJywg
:::ZW5jb2Rpbmc9J3V0Zi04JykgYXMgZmg6CiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICBmaC53cml0ZSh0YiArICdcbicpCiAgICAgICAgICAgICAgICAgICAgZXhj
:::ZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgICAgICAgICAgICAgcGFzcwogICAg
:::ICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnZGVzY2FyZ2EnLCBGYWxzZSwK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAnTm8gc2UgcHVkbyBjb21wbGV0YXIg
:::bGEgZGVzY2FyZ2EuIFJldmlzYSBlbCAnCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgJ3JlZ2lzdHJvIHBhcmEgbcOhcyBkZXRhbGxlcy4nKSkKCiAgICAgICAgZGVm
:::IF9oaWxvX2NvbXByb2JhcihzZWxmLCBjZmcpOgogICAgICAgICAgICBjb2xhID0g
:::c2VsZi5jb2xhCgogICAgICAgICAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAg
:::ICAgICAgICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgICAgICAg
:::ICBjYXJwZXRhID0gUGF0aChvcy5wYXRoLmV4cGFuZHZhcnMoCiAgICAgICAgICAg
:::ICAgICBzdHIoQUpVU1RFUy5nZXQoJ2Rlc3Rpbm8nLCBfZGVzdGlub19wb3JfZGVm
:::ZWN0bygpKSkpKQogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBpZiBu
:::b3QgY2FycGV0YS5pc19kaXIoKToKICAgICAgICAgICAgICAgICAgICBsb2coZidM
:::YSBjYXJwZXRhIHRvZGF2w61hIG5vIGV4aXN0ZToge2NhcnBldGF9JywgJ2F2aXNv
:::JykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdjb21wcm9i
:::YWNpb24nLCBUcnVlLCAnJykpCiAgICAgICAgICAgICAgICAgICAgcmV0dXJuCiAg
:::ICAgICAgICAgICAgICBpZiBGRlBST0JFIGlzIE5vbmU6CiAgICAgICAgICAgICAg
:::ICAgICAgbG9nKCdmZnByb2JlIG5vIGVzdMOhIGRpc3BvbmlibGUgKHZpZW5lIGNv
:::biBGRm1wZWcpLiAnCiAgICAgICAgICAgICAgICAgICAgICAgICdFamVjdXRhIERl
:::c2NhcmdhZG9yTXVzaWNhLmJhdCBwYXJhIGluc3RhbGFybG8uJywKICAgICAgICAg
:::ICAgICAgICAgICAgICAgJ2Vycm9yJykKICAgICAgICAgICAgICAgICAgICBjb2xh
:::LnB1dCgoJ2ZpbicsICdjb21wcm9iYWNpb24nLCBUcnVlLCAnJykpCiAgICAgICAg
:::ICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgICAgICBleHRzID0gKCcubTRh
:::JywgJy5tcDMnLCAnLmZsYWMnLCAnLndhdicsICcud21hJywgJy5hdmknKQogICAg
:::ICAgICAgICAgICAgYXJjaGl2b3MgPSBbcCBmb3IgcCBpbiBzb3J0ZWQoY2FycGV0
:::YS5yZ2xvYignKicpKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgaWYgcC5p
:::c19maWxlKCkgYW5kIHAuc3VmZml4Lmxvd2VyKCkgaW4gZXh0cwogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgYW5kICdfdG1wJyBub3QgaW4gcC5wYXJ0c10KICAg
:::ICAgICAgICAgICAgIGxvZyhmJ0NvbXByb2JhbmRvIHtsZW4oYXJjaGl2b3MpfSBh
:::cmNoaXZvKHMpIGVuICcKICAgICAgICAgICAgICAgICAgICBmJ3tjYXJwZXRhfSAu
:::Li4nLCAndGl0dWxvJykKICAgICAgICAgICAgICAgIGlmIG5vdCBhcmNoaXZvczoK
:::ICAgICAgICAgICAgICAgICAgICBsb2coJ05vIGhheSBhcmNoaXZvcyBkZSBhdWRp
:::byBvIHZpZGVvIHRvZGF2w61hLicsICdncmlzJykKICAgICAgICAgICAgICAgICAg
:::ICBjb2xhLnB1dCgoJ2ZpbicsICdjb21wcm9iYWNpb24nLCBUcnVlLCAnJykpCiAg
:::ICAgICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgICAgICB0b3RhbCA9
:::IDAKICAgICAgICAgICAgICAgIGJhamFzID0gMAogICAgICAgICAgICAgICAgZm9y
:::IHAgaW4gYXJjaGl2b3M6CiAgICAgICAgICAgICAgICAgICAgdHJ5OgogICAgICAg
:::ICAgICAgICAgICAgICAgICByID0gc3VicHJvY2Vzcy5ydW4oCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICBbc3RyKEZGUFJPQkUpLCAnLXYnLCAnZXJyb3InLCAn
:::LXNob3dfZW50cmllcycsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2Zv
:::cm1hdD1iaXRfcmF0ZSxkdXJhdGlvbixzaXplJywgJy1vZicsICdqc29uJywKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBzdHIocCldLAogICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgc3Rkb3V0PXN1YnByb2Nlc3MuUElQRSwgc3RkZXJyPXN1
:::YnByb2Nlc3MuUElQRSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRleHQ9
:::VHJ1ZSwgZW5jb2Rpbmc9J3V0Zi04JywgZXJyb3JzPSdyZXBsYWNlJywKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgIHRpbWVvdXQ9MzApCiAgICAgICAgICAgICAg
:::ICAgICAgICAgIGRhdG9zID0ganNvbi5sb2FkcyhyLnN0ZG91dCBvciAne30nKS5n
:::ZXQoJ2Zvcm1hdCcsIHt9KQogICAgICAgICAgICAgICAgICAgICAgICBrYnBzID0g
:::aW50KGZsb2F0KGRhdG9zLmdldCgnYml0X3JhdGUnKSBvciAwKSAvIDEwMDApCiAg
:::ICAgICAgICAgICAgICAgICAgICAgIGR1ciA9IGZsb2F0KGRhdG9zLmdldCgnZHVy
:::YXRpb24nKSBvciAwKQogICAgICAgICAgICAgICAgICAgICAgICB0YW0gPSBpbnQo
:::ZmxvYXQoZGF0b3MuZ2V0KCdzaXplJykgb3IgMCkpCiAgICAgICAgICAgICAgICAg
:::ICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgICAgICAgICAgICAgbG9n
:::KGYnwrcge3AubmFtZVs6NjBdfSDigJQgbm8gc2UgcHVkbyBsZWVyJywgJ2F2aXNv
:::JykKICAgICAgICAgICAgICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAg
:::ICAgICAgICB0b3RhbCArPSB0YW0KICAgICAgICAgICAgICAgICAgICB0ZXh0bywg
:::bml2ZWwgPSBjbGFzZV9jYWxpZGFkKHAuc3VmZml4Lmxvd2VyKCksIGticHMpCiAg
:::ICAgICAgICAgICAgICAgICAgaWYgbml2ZWwgPT0gMjoKICAgICAgICAgICAgICAg
:::ICAgICAgICAgYmFqYXMgKz0gMQogICAgICAgICAgICAgICAgICAgIHRhZyA9ICgn
:::b2snIGlmIG5pdmVsID09IDAKICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxz
:::ZSAoJ2F2aXNvJyBpZiBuaXZlbCA9PSAxIGVsc2UgJ2Vycm9yJykpCiAgICAgICAg
:::ICAgICAgICAgICAgbG9nKGYnwrcge3AubmFtZVs6NThdfSDigJQge3RleHRvfSDC
:::tyB7Zm10X3RpZW0oZHVyKX0gwrcgJwogICAgICAgICAgICAgICAgICAgICAgICBm
:::J3tmbXRfdGFtKHRhbSl9JywgdGFnKQogICAgICAgICAgICAgICAgbG9nKGYnUmVz
:::dWx0YWRvOiB7bGVuKGFyY2hpdm9zKX0gYXJjaGl2byhzKSDCtyAnCiAgICAgICAg
:::ICAgICAgICAgICAgZid7Zm10X3RhbSh0b3RhbCl9IGVuIHRvdGFsIMK3IHtiYWph
:::c30gY29uIGNhbGlkYWQgYmFqYScsCiAgICAgICAgICAgICAgICAgICAgJ3RpdHVs
:::bycpCiAgICAgICAgICAgICAgICBpZiBiYWphczoKICAgICAgICAgICAgICAgICAg
:::ICBsb2coJ0NvbnNlam86IGxvcyBhcmNoaXZvcyBtYXJjYWRvcyBlbiByb2pvIHNl
:::IHB1ZWRlbiAnCiAgICAgICAgICAgICAgICAgICAgICAgICd2b2x2ZXIgYSBkZXNj
:::YXJnYXIgY29uIG3DoXMgYml0cmF0ZS4nLCAnZ3JpcycpCiAgICAgICAgICAgIGV4
:::Y2VwdCBFeGNlcHRpb24gYXMgZToKICAgICAgICAgICAgICAgIGxvZyhmJ0Vycm9y
:::IGFsIGNvbXByb2JhciBsYSBjYXJwZXRhOiB7ZX0nLCAnZXJyb3InKQogICAgICAg
:::ICAgICBmaW5hbGx5OgogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAn
:::Y29tcHJvYmFjaW9uJywgVHJ1ZSwgJycpKQoKICAgICAgICBkZWYgX2hpbG9fYWN0
:::dWFsaXphcihzZWxmLCBjZmcpOgogICAgICAgICAgICBjb2xhID0gc2VsZi5jb2xh
:::CgogICAgICAgICAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAgICAgICAg
:::ICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgICAgICAgICB0cnk6CiAg
:::ICAgICAgICAgICAgICBsb2coJ0FjdHVhbGl6YW5kbyB5dC1kbHAgeSBtdXRhZ2Vu
:::Li4uJywgJ2dyaXMnKQogICAgICAgICAgICAgICAgcCA9IHN1YnByb2Nlc3MucnVu
:::KAogICAgICAgICAgICAgICAgICAgIFtzeXMuZXhlY3V0YWJsZSwgJy1tJywgJ3Bp
:::cCcsICdpbnN0YWxsJywgJy0tdXBncmFkZScsCiAgICAgICAgICAgICAgICAgICAg
:::ICctLW5vLXdhcm4tc2NyaXB0LWxvY2F0aW9uJywgJ3l0LWRscCcsICdtdXRhZ2Vu
:::J10sCiAgICAgICAgICAgICAgICAgICAgc3Rkb3V0PXN1YnByb2Nlc3MuUElQRSwg
:::c3RkZXJyPXN1YnByb2Nlc3MuU1RET1VULAogICAgICAgICAgICAgICAgICAgIHRl
:::eHQ9VHJ1ZSwgZW5jb2Rpbmc9J3V0Zi04JywgZXJyb3JzPSdyZXBsYWNlJywgdGlt
:::ZW91dD02MDApCiAgICAgICAgICAgICAgICBmb3IgbG4gaW4gKHAuc3Rkb3V0IG9y
:::ICcnKS5zdHJpcCgpLnNwbGl0bGluZXMoKVstNjpdOgogICAgICAgICAgICAgICAg
:::ICAgIGxvZygnICAgJyArIGxuWzoxNjBdLCAnZ3JpcycpCiAgICAgICAgICAgICAg
:::ICBpZiBwLnJldHVybmNvZGUgPT0gMDoKICAgICAgICAgICAgICAgICAgICBsb2co
:::J3l0LWRscCBhY3R1YWxpemFkby4gUmVpbmljaWEgbGEgYXBsaWNhY2nDs24gcGFy
:::YSAnCiAgICAgICAgICAgICAgICAgICAgICAgICd1c2FyIGxhIHZlcnNpw7NuIG51
:::ZXZhLicsICdvaycpCiAgICAgICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAg
:::ICAgICAgIGxvZygnTGEgYWN0dWFsaXphY2nDs24gZmFsbMOzICjCv3NpbiBpbnRl
:::cm5ldD8pLicsICdlcnJvcicpCiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb24g
:::YXMgZToKICAgICAgICAgICAgICAgIGxvZyhmJ05vIHNlIHB1ZG8gZWplY3V0YXIg
:::cGlwOiB7ZX0nLCAnZXJyb3InKQogICAgICAgICAgICBmaW5hbGx5OgogICAgICAg
:::ICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnYWN0dWFsaXphY2lvbicsIFRydWUs
:::ICcnKSkKCiAgICAgICAgZGVmIF9tc2dfZXJyb3Ioc2VsZiwgZSk6CiAgICAgICAg
:::ICAgIGxpbmVhcyA9IFtsIGZvciBsIGluIHN0cihlKS5zdHJpcCgpLnNwbGl0bGlu
:::ZXMoKSBpZiBsLnN0cmlwKCldCiAgICAgICAgICAgIHJldHVybiAobGluZWFzWzBd
:::WzoyNTBdIGlmIGxpbmVhcwogICAgICAgICAgICAgICAgICAgIGVsc2UgZid7dHlw
:::ZShlKS5fX25hbWVfX306IHNpbiBkZXRhbGxlcycpCgogICAgICAgICMgLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGFycmFu
:::cXVlCiAgICAgICAgZGVmIF9hcnJhbnF1ZShzZWxmKToKICAgICAgICAgICAgc2Vs
:::Zi5fbG9nKGYnTXVzaWtBTEFOIHZ7QVBQX1Z9JywgJ3RpdHVsbycpCiAgICAgICAg
:::ICAgIHNlbGYuX2xvZygnQ3RybCtVOiBhY3R1YWxpemFyIHl0LWRscCDCtyBDdHJs
:::K0w6IGxpbXBpYXIgcmVnaXN0cm8nLAogICAgICAgICAgICAgICAgICAgICAgJ2dy
:::aXMnKQogICAgICAgICAgICB0aHJlYWRpbmcuVGhyZWFkKHRhcmdldD1zZWxmLl9o
:::aWxvX3ZlcnNpb24sIGRhZW1vbj1UcnVlKS5zdGFydCgpCgogICAgICAgIGRlZiBf
:::aGlsb192ZXJzaW9uKHNlbGYpOgogICAgICAgICAgICBjb2xhID0gc2VsZi5jb2xh
:::CgogICAgICAgICAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAgICAgICAg
:::ICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgICAgICAgICBpZiBZVF9E
:::TFAgaXMgTm9uZToKICAgICAgICAgICAgICAgIGxvZygneXQtZGxwIG5vIGVzdMOh
:::IGluc3RhbGFkby4gRWplY3V0YSAnCiAgICAgICAgICAgICAgICAgICAgJ0Rlc2Nh
:::cmdhZG9yTXVzaWNhLmJhdCBwYXJhIGluc3RhbGFybG8uJywgJ2Vycm9yJykKICAg
:::ICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ3ZlcnNpb24nLCBUcnVlLCAn
:::JykpCiAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgdHJ5OgogICAg
:::ICAgICAgICAgICAgaW5zdGFsYWRhID0gWVRfRExQLnZlcnNpb24uX192ZXJzaW9u
:::X18KICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgICAg
:::IGluc3RhbGFkYSA9ICc/JwogICAgICAgICAgICB1bHRpbWEgPSBOb25lCiAgICAg
:::ICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHdpdGggdXJsb3BlbignaHR0cHM6
:::Ly9weXBpLm9yZy9weXBpL3l0LWRscC9qc29uJywgdGltZW91dD0xMikgYXMgcjoK
:::ICAgICAgICAgICAgICAgICAgICB1bHRpbWEgPSBqc29uLmxvYWRzKHIucmVhZCgp
:::LmRlY29kZSgndXRmLTgnKSlbJ2luZm8nXVsndmVyc2lvbiddCiAgICAgICAgICAg
:::IGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgICAgICB1bHRpbWEgPSBOb25l
:::CiAgICAgICAgICAgIGlmIHVsdGltYSBpcyBOb25lOgogICAgICAgICAgICAgICAg
:::bG9nKGYneXQtZGxwOiB2ZXJzacOzbiB7aW5zdGFsYWRhfSAnCiAgICAgICAgICAg
:::ICAgICAgICAgJyhubyBzZSBwdWRvIGNvbXByb2JhciBzaSBoYXkgbm92ZWRhZGVz
:::KS4nLCAnZ3JpcycpCiAgICAgICAgICAgIGVsaWYgc3RyKHVsdGltYSkgPT0gc3Ry
:::KGluc3RhbGFkYSk6CiAgICAgICAgICAgICAgICBsb2coZid5dC1kbHA6IGVuIGxh
:::IHVsdGltYSB2ZXJzaW9uICh7aW5zdGFsYWRhfSkuJywgJ2luZm8nKQogICAgICAg
:::ICAgICBlbHNlOgogICAgICAgICAgICAgICAgbG9nKGYneXQtZGxwOiBoYXkgdmVy
:::c2lvbiBudWV2YSAoe3VsdGltYX0pOyBpbnN0YWxhZGE6ICcKICAgICAgICAgICAg
:::ICAgICAgICBmJ3tpbnN0YWxhZGF9LiBQdWxzYSBDdHJsK1UgcGFyYSBhY3R1YWxp
:::emFyLicsICdhdmlzbycpCiAgICAgICAgICAgIGlmIEZGTVBFRyBpcyBOb25lOgog
:::ICAgICAgICAgICAgICAgbG9nKCdGRm1wZWc6IE5PIEVOQ09OVFJBRE8g4oCUIGVq
:::ZWN1dGEgRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0ICcKICAgICAgICAgICAgICAgICAg
:::ICAncGFyYSBpbnN0YWxhcmxvLicsICdlcnJvcicpCiAgICAgICAgICAgIGVsc2U6
:::CiAgICAgICAgICAgICAgICBsb2coZidGRm1wZWc6IE9LICh7RkZNUEVHfSknLCAn
:::Z3JpcycpCiAgICAgICAgICAgIGxvZygnQ2FycGV0YSBkZSBndWFyZGFkbzogJyAr
:::IHN0cihBSlVTVEVTLmdldCgnZGVzdGlubycpKSwgJ2dyaXMnKQogICAgICAgICAg
:::ICBjb2xhLnB1dCgoJ2ZpbicsICd2ZXJzaW9uJywgVHJ1ZSwgJycpKQoKCiMgLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLSBtYWluCmRlZiBtYWluKCk6CiAgICBfcmVjb25maWd1cmFy
:::X3NhbGlkYSgpCiAgICBpZiBub3QgVEtfT0s6CiAgICAgICAgcHJpbnQoJ0VzdGEg
:::YXBsaWNhY2nDs24gbmVjZXNpdGEgVGtpbnRlciAoaW50ZXJmYXogZ3LDoWZpY2Ep
:::LicpCiAgICAgICAgcHJpbnQoJ0VsIFB5dGhvbiBhY3R1YWwgbm8gbG8gaW5jbHV5
:::ZS4nKQogICAgICAgIHByaW50KCdWdWVsdmUgYSBlamVjdXRhciBEZXNjYXJnYWRv
:::ck11c2ljYS5iYXQgcGFyYSBpbnN0YWxhciBlbCAnCiAgICAgICAgICAgICAgJ1B5
:::dGhvbiBhZGVjdWFkby4nKQogICAgICAgIHJldHVybiAxCiAgICBjb21wcm9iYXJf
:::ZW50b3JubygpCiAgICBhcHAgPSBBcHAoKQogICAgYXBwLm1haW5sb29wKCkKICAg
:::IHJldHVybiAwCgoKaWYgX19uYW1lX18gPT0gJ19fbWFpbl9fJzoKICAgIHRyeToK
:::ICAgICAgICBzeXMuZXhpdChtYWluKCkpCiAgICBleGNlcHQgU3lzdGVtRXhpdDoK
:::ICAgICAgICByYWlzZQogICAgZXhjZXB0IEJhc2VFeGNlcHRpb246CiAgICAgICAg
:::dHJ5OgogICAgICAgICAgICB3aXRoIG9wZW4oTE9HX0VSUk9SRVMsICdhJywgZW5j
:::b2Rpbmc9J3V0Zi04JykgYXMgZmg6CiAgICAgICAgICAgICAgICBmaC53cml0ZSh0
:::cmFjZWJhY2suZm9ybWF0X2V4YygpICsgJ1xuJykKICAgICAgICBleGNlcHQgRXhj
:::ZXB0aW9uOgogICAgICAgICAgICBwYXNzCiAgICAgICAgcmFpc2UK
