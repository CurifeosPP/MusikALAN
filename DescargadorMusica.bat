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
title MusikALAN v2.4
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
echo    %C_TIT%MusikALAN v2.4%C_FIN% - preparando el entorno
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
title MusikALAN v2.4 - YouTube a AAC/MP3/FLAC/WAV/WMA/AVI
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
:::IChjb2RpZmljYWRvciB3bWF2MiBkZSBGRm1wZWc7IGVsIGNvbnRlbmVkb3IKICAg
:::ICAgICAgICAgICAgICBBU0Ygbm8gYWRtaXRlIGNhcmF0dWxhIGluY3J1c3RhZGEp
:::CiAgwrcgQVZJICAoLmF2aSkgIHZpZGVvIHJlY29kaWZpY2FkbyBwYXJhIGVsIHJl
:::cHJvZHVjdG9yIHNoZWlqdSAxLjgiCiAgICAgICAgICAgICAgICAgMTI4eDE2MCwg
:::Y29uIGxvcyBwYXJhbWV0cm9zIG9maWNpYWxlcyBkZWwgcmVwb3NpdG9yaW8KICAg
:::ICAgICAgICAgICAgICBnaXRodWIuY29tL2ZkZDRzL3BvcnRhYmxlX21wM19wbGF5
:::ZXJfdmlkZW9fY29udmVydGVyX3Rvb2xzCiAgICAgICAgICAgICAgICAgKHNjcmlw
:::dCB2aWRlbzJzaGVuanUxOC5zaCkKCkxhIGluc3RhbGFjaW9uIGRlIFB5dGhvbiwg
:::eXQtZGxwIHkgRkZtcGVnIGxhIGhhY2UgYXV0b21hdGljYW1lbnRlIGVsCmFyY2hp
:::dm8gRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0OyBlc3RlIHNjcmlwdCBlcyBsYSB2ZW50
:::YW5hIHF1ZSBzZSB1c2EgYQpkaWFyaW8gKHRlbWEgb3NjdXJvL2NsYXJvLCBlc3Rp
:::bWFjaW9uIGRlIHRhbWFubyB5IGNvbXByb2JhZG9yIGRlCmNhbGlkYWQgZGUgbGEg
:::Y2FycGV0YSkuIExhIGNhcnBldGEgZGUgZ3VhcmRhZG8gcG9yIGRlZmVjdG8gZXMg
:::bGEKY2FycGV0YSBNdXNpY2EgZGUgV2luZG93cywgeSBsb3MgYXJjaGl2b3MgdmFu
:::IGRpcmVjdG9zIGEgZWxsYSwgc2luCnN1YmNhcnBldGFzIHBvciBmb3JtYXRvLiBU
:::cmFzIGNhZGEgZGVzY2FyZ2Egc2UgZXNjcmliZW4gbGFzIGV0aXF1ZXRhcwpkZWwg
:::YXJjaGl2byAoYXJ0aXN0YSBzaW4gZWwgc3VmaWpvICIgLSBUb3BpYyIsIGFsYnVt
:::LCB0aXR1bG8geSBhbm8pCnBhcmEgcXVlIHRvZG9zIGxvcyByZXByb2R1Y3RvcmVz
:::IGxhcyBtdWVzdHJlbi4KClVzbzogIHB5dGhvbiBkZXNjYXJnYWRvci5weSAgIChv
:::IGRvYmxlIGNsaWMgZW4gRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0KQpTaSBsYSBVUkwg
:::cGVydGVuZWNlIGEgdW5hIGxpc3RhIGRlIHJlcHJvZHVjY2lvbiwgZWwgcHJvZ3Jh
:::bWEgcHJlZ3VudGEKc2kgYmFqYXIgc29sbyBsYSBjYW5jaW9uIHBlZ2FkYSBvIGxh
:::IHBsYXlsaXN0IGNvbXBsZXRhIChjb24gdW5hIHBhdXNhCmRlIDIgcyBlbnRyZSBj
:::YW5jaW9uZXMgcGFyYSBubyBzYXR1cmFyIGEgWW91VHViZSkuCiIiIgoKaW1wb3J0
:::IGpzb24KaW1wb3J0IG9zCmltcG9ydCBxdWV1ZQppbXBvcnQgcmUKaW1wb3J0IHNo
:::dXRpbAppbXBvcnQgc3VicHJvY2VzcwppbXBvcnQgc3lzCmltcG9ydCB0aHJlYWRp
:::bmcKaW1wb3J0IHRpbWUKaW1wb3J0IHRyYWNlYmFjawpmcm9tIHBhdGhsaWIgaW1w
:::b3J0IFBhdGgKZnJvbSB1cmxsaWIucGFyc2UgaW1wb3J0IHBhcnNlX3FzLCB1cmxl
:::bmNvZGUsIHVybHBhcnNlLCB1cmx1bnBhcnNlCmZyb20gdXJsbGliLnJlcXVlc3Qg
:::aW1wb3J0IHVybG9wZW4KCkFQUF9WID0gJzIuNCcKQVBQX0RJUiA9IFBhdGgoX19m
:::aWxlX18pLnJlc29sdmUoKS5wYXJlbnQKUlVUQV9BSlVTVEVTID0gQVBQX0RJUiAv
:::ICdhanVzdGVzLmpzb24nCkxPR19FUlJPUkVTID0gQVBQX0RJUiAvICdkZXNjYXJn
:::YWRvcl9lcnJvcmVzLmxvZycKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBzYWxpZGEKIyBB
:::bCBlamVjdXRhcnNlIGNvbiBweXRob253LmV4ZSAoc2luIGNvbnNvbGEpIHN0ZG91
:::dC9zdGRlcnIgc29uIE5vbmU6CiMgY3VhbHF1aWVyIHByaW50IGZhbGxhcmlhLiBM
:::b3MgcmVkaXJpZ2ltb3MgYSB1biBzaXRpbyBzZWd1cm8uCnRyeToKICAgIGlmIHN5
:::cy5zdGRvdXQgaXMgTm9uZToKICAgICAgICBzeXMuc3Rkb3V0ID0gb3Blbihvcy5k
:::ZXZudWxsLCAndycsIGVuY29kaW5nPSd1dGYtOCcpCmV4Y2VwdCBFeGNlcHRpb246
:::CiAgICBwYXNzCnRyeToKICAgIGlmIHN5cy5zdGRlcnIgaXMgTm9uZToKICAgICAg
:::ICBzeXMuc3RkZXJyID0gb3BlbihMT0dfRVJST1JFUywgJ2EnLCBlbmNvZGluZz0n
:::dXRmLTgnKQpleGNlcHQgRXhjZXB0aW9uOgogICAgcGFzcwoKCmRlZiBfcmVjb25m
:::aWd1cmFyX3NhbGlkYSgpOgogICAgIiIiRXZpdGEgY3Jhc2hlcyBwb3IgY2FyYWN0
:::ZXJlcyByYXJvcyBzaSBsYSBzYWxpZGEgc2UgcmVkaXJpZ2UuIiIiCiAgICBmb3Ig
:::cyBpbiAoc3lzLnN0ZG91dCwgc3lzLnN0ZGVycik6CiAgICAgICAgdHJ5OgogICAg
:::ICAgICAgICBpZiBzIGFuZCBoYXNhdHRyKHMsICdyZWNvbmZpZ3VyZScpOgogICAg
:::ICAgICAgICAgICAgcy5yZWNvbmZpZ3VyZShlcnJvcnM9J3JlcGxhY2UnKQogICAg
:::ICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgIHBhc3MKCgojIC0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0gdGtpbnRlcgp0cnk6CiAgICBpbXBvcnQgdGtpbnRlciBhcyB0
:::awogICAgZnJvbSB0a2ludGVyIGltcG9ydCBmaWxlZGlhbG9nLCBtZXNzYWdlYm94
:::LCB0dGsKICAgIGZyb20gdGtpbnRlci5zY3JvbGxlZHRleHQgaW1wb3J0IFNjcm9s
:::bGVkVGV4dAogICAgVEtfT0sgPSBUcnVlCmV4Y2VwdCBFeGNlcHRpb246CiAgICBU
:::S19PSyA9IEZhbHNlCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGFqdXN0ZXMKZGVmIF9j
:::YXJwZXRhX211c2ljYSgpOgogICAgIiIiQ2FycGV0YSAnTXVzaWNhJyByZWFsIGRl
:::bCB1c3VhcmlvIChGT0xERVJJRF9NdXNpYyBkZSBXaW5kb3dzKS4iIiIKICAgIGlm
:::IG9zLm5hbWUgPT0gJ250JzoKICAgICAgICB0cnk6CiAgICAgICAgICAgIGltcG9y
:::dCBjdHlwZXMKCiAgICAgICAgICAgIGNsYXNzIF9HVUlEKGN0eXBlcy5TdHJ1Y3R1
:::cmUpOgogICAgICAgICAgICAgICAgX2ZpZWxkc18gPSBbKCdEMScsIGN0eXBlcy5j
:::X3Vsb25nKSwgKCdEMicsIGN0eXBlcy5jX3VzaG9ydCksCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAoJ0QzJywgY3R5cGVzLmNfdXNob3J0KSwKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICgnRDQnLCBjdHlwZXMuY191Ynl0ZSAqIDgpXQoK
:::ICAgICAgICAgICAgbXVzaWNhID0gX0dVSUQoMHg0QkQ4RDU3MSwgMHg2RDE5LCAw
:::eDQ4RDMsCiAgICAgICAgICAgICAgICAgICAgICAgICAgIChjdHlwZXMuY191Ynl0
:::ZSAqIDgpKDB4QkUsIDB4OTcsIDB4MDMsIDB4MzgsCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIDB4NUYsIDB4N0YsIDB4QzUs
:::IDB4Q0UpKQogICAgICAgICAgICBwdHIgPSBjdHlwZXMuY193Y2hhcl9wKCkKICAg
:::ICAgICAgICAgaWYgY3R5cGVzLndpbmRsbC5zaGVsbDMyLlNIR2V0S25vd25Gb2xk
:::ZXJQYXRoKAogICAgICAgICAgICAgICAgICAgIGN0eXBlcy5ieXJlZihtdXNpY2Ep
:::LCAwLCBOb25lLAogICAgICAgICAgICAgICAgICAgIGN0eXBlcy5ieXJlZihwdHIp
:::KSA9PSAwIGFuZCBwdHIudmFsdWU6CiAgICAgICAgICAgICAgICBydXRhID0gcHRy
:::LnZhbHVlCiAgICAgICAgICAgICAgICBjdHlwZXMud2luZGxsLm9sZTMyLkNvVGFz
:::a01lbUZyZWUocHRyKQogICAgICAgICAgICAgICAgcmV0dXJuIHJ1dGEKICAgICAg
:::ICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICBwYXNzCiAgICByZXR1cm4g
:::c3RyKFBhdGguaG9tZSgpIC8gJ011c2ljJykKCgpkZWYgX2Rlc3Rpbm9fYXBwZGF0
:::YV92aWVqbygpOgogICAgIiIiQ2FycGV0YSBkZWwgcHJvZ3JhbWEgKGVyYSBlbCBk
:::ZXN0aW5vIHBvciBkZWZlY3RvIGVuIGxhIHYyLjIpLiIiIgogICAgYmFzZSA9IG9z
:::LmVudmlyb24uZ2V0KCdBUFBEQVRBJykgb3Igc3RyKFBhdGguaG9tZSgpIC8gJ0Fw
:::cERhdGEnIC8gJ1JvYW1pbmcnKQogICAgcmV0dXJuIHN0cihQYXRoKGJhc2UpIC8g
:::J011c2lrQUxBTicpCgoKZGVmIF9kZXN0aW5vX3Bvcl9kZWZlY3RvKCk6CiAgICAi
:::IiJMb3MgYXJjaGl2b3Mgc2UgZ3VhcmRhbiBlbiBsYSBjYXJwZXRhIE11c2ljYSBk
:::ZWwgdXN1YXJpby4iIiIKICAgIHJldHVybiBfY2FycGV0YV9tdXNpY2EoKQoKCkFK
:::VVNURVNfREVGRUNUTyA9IHsKICAgICdkZXN0aW5vJzogX2Rlc3Rpbm9fcG9yX2Rl
:::ZmVjdG8oKSwKICAgICd0ZW1hJzogJ09zY3VybycsCiAgICAnZm9ybWF0byc6ICdB
:::QUMnLAogICAgJ2NhbGlkYWQnOiAnMTI4aycsCiAgICAnZW1iZWJlcic6IFRydWUs
:::Cn0KCgpkZWYgY2FyZ2FyX2FqdXN0ZXMoKToKICAgIGEgPSBkaWN0KEFKVVNURVNf
:::REVGRUNUTykKICAgIHRyeToKICAgICAgICBhLnVwZGF0ZShqc29uLmxvYWRzKFJV
:::VEFfQUpVU1RFUy5yZWFkX3RleHQoZW5jb2Rpbmc9J3V0Zi04JykpKQogICAgZXhj
:::ZXB0IEV4Y2VwdGlvbjoKICAgICAgICBwYXNzCiAgICBhLnBvcCgnbmF2ZWdhZG9y
:::JywgTm9uZSkgICMgdjIuMiBvIGFudGVyaW9yOiBsYSBzZWNjaW9uIGRlIGNvb2tp
:::ZXMgeWEgbm8gZXhpc3RlCiAgICAjIG1pZ3JhY2lvbmVzIGRlbCBkZXN0aW5vIGRl
:::IGd1YXJkYWRvOgogICAgIyAgwrcgdjIuMC8yLjEgdXNhYmEgTXVzaWMvWVREb3du
:::bG9hZGVyCiAgICAjICDCtyB2Mi4yIHVzYWJhIGxhIGNhcnBldGEgZGVsIHByb2dy
:::YW1hIChBcHBEYXRhXFJvYW1pbmdcTXVzaWtBTEFOKQogICAgIyBEZXNkZSBsYSB2
:::Mi4zIGVsIGRlc3Rpbm8gcG9yIGRlZmVjdG8gZXMgbGEgY2FycGV0YSBNdXNpY2Eg
:::ZGVsIHVzdWFyaW8sCiAgICAjIGFzaSBxdWUgc2kgZWwgYWp1c3RlIGFwdW50YSBh
:::IGN1YWxxdWllcmEgZGUgbG9zIGRvcywgc2UgYWN0dWFsaXphLgogICAgZGVzdGlu
:::byA9IHN0cihhLmdldCgnZGVzdGlubycpIG9yICcnKS5yZXBsYWNlKCdcXCcsICcv
:::JykucnN0cmlwKCcvJykubG93ZXIoKQogICAgaWYgJ3l0ZG93bmxvYWRlcicgaW4g
:::ZGVzdGlubzoKICAgICAgICBhWydkZXN0aW5vJ10gPSBBSlVTVEVTX0RFRkVDVE9b
:::J2Rlc3Rpbm8nXQogICAgZWxzZToKICAgICAgICB2aWVqbyA9IF9kZXN0aW5vX2Fw
:::cGRhdGFfdmllam8oKS5yZXBsYWNlKCdcXCcsICcvJykucnN0cmlwKCcvJykubG93
:::ZXIoKQogICAgICAgIGlmIGRlc3Rpbm8gYW5kIChkZXN0aW5vID09IHZpZWpvCiAg
:::ICAgICAgICAgICAgICAgICAgICAgIG9yIGRlc3Rpbm8uc3RhcnRzd2l0aCh2aWVq
:::byArICcvJykpOgogICAgICAgICAgICBhWydkZXN0aW5vJ10gPSBBSlVTVEVTX0RF
:::RkVDVE9bJ2Rlc3Rpbm8nXQogICAgcmV0dXJuIGEKCgpkZWYgZ3VhcmRhcl9hanVz
:::dGVzKCk6CiAgICB0cnk6CiAgICAgICAgUlVUQV9BSlVTVEVTLndyaXRlX3RleHQo
:::CiAgICAgICAgICAgIGpzb24uZHVtcHMoQUpVU1RFUywgZW5zdXJlX2FzY2lpPUZh
:::bHNlLCBpbmRlbnQ9MiksCiAgICAgICAgICAgIGVuY29kaW5nPSd1dGYtOCcpCiAg
:::ICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHBhc3MKCgpBSlVTVEVTID0gY2Fy
:::Z2FyX2FqdXN0ZXMoKQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSB1dGlscwpkZWYgZm10
:::X3RhbShuKToKICAgIGlmIG5vdCBuOgogICAgICAgIHJldHVybiAn4oCUJwogICAg
:::biA9IGZsb2F0KG4pCiAgICBmb3IgdSBpbiAoJ0InLCAnS2lCJywgJ01pQicsICdH
:::aUInKToKICAgICAgICBpZiBuIDwgMTAyNCBvciB1ID09ICdHaUInOgogICAgICAg
:::ICAgICByZXR1cm4gZid7aW50KG4pfSB7dX0nIGlmIHUgPT0gJ0InIGVsc2UgZid7
:::bjouMWZ9IHt1fScKICAgICAgICBuIC89IDEwMjQKCgpkZWYgZm10X3RpZW0ocyk6
:::CiAgICBpZiBzIGlzIE5vbmU6CiAgICAgICAgcmV0dXJuICfigJQnCiAgICBzID0g
:::aW50KHMpCiAgICBoLCByID0gZGl2bW9kKHMsIDM2MDApCiAgICBtLCB4ID0gZGl2
:::bW9kKHIsIDYwKQogICAgcmV0dXJuIGYne2h9OnttOjAyZH06e3g6MDJkfScgaWYg
:::aCBlbHNlIGYne206MDJkfTp7eDowMmR9JwoKCmRlZiBsaW1waWFyX25vbWJyZSh0
:::KToKICAgIHQgPSByZS5zdWIocidbPD46Ii9cXHw/Klx4MDAtXHgxZl0nLCAnXycs
:::IHN0cih0KSkuc3RyaXAoJyAuJykKICAgIHJldHVybiB0WzoxNTBdIG9yICdzaW5f
:::dGl0dWxvJwoKCmRlZiBzaW5fcGxheWxpc3QodXJsKToKICAgICIiIlF1aXRhIGVs
:::IHBhcsOhbWV0cm8gbGlzdD0gZGUgbGEgVVJMIChtb2RvIHNvbG8gdmlkZW8pLiIi
:::IgogICAgdHJ5OgogICAgICAgIHAgPSB1cmxwYXJzZSh1cmwpCiAgICAgICAgcSA9
:::IHBhcnNlX3FzKHAucXVlcnkpCiAgICAgICAgaWYgJ2xpc3QnIGluIHE6CiAgICAg
:::ICAgICAgIGRlbCBxWydsaXN0J10KICAgICAgICAgICAgcmV0dXJuIHVybHVucGFy
:::c2UocC5fcmVwbGFjZShxdWVyeT11cmxlbmNvZGUocSwgZG9zZXE9VHJ1ZSkpKSwg
:::VHJ1ZQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICBwYXNzCiAgICByZXR1
:::cm4gdXJsLCBGYWxzZQoKCmRlZiBlc191cmxfcGxheWxpc3QodXJsKToKICAgICIi
:::IlRydWUgc2kgbGEgVVJMIHBlcnRlbmVjZSBhIHVuYSBsaXN0YSBkZSByZXByb2R1
:::Y2Npw7NuIChsbGV2YSBsaXN0PSkuIiIiCiAgICB0cnk6CiAgICAgICAgcmV0dXJu
:::ICdsaXN0JyBpbiBwYXJzZV9xcyh1cmxwYXJzZSh1cmwpLnF1ZXJ5KQogICAgZXhj
:::ZXB0IEV4Y2VwdGlvbjoKICAgICAgICByZXR1cm4gRmFsc2UKCgpkZWYgZXNfc29s
:::b19saXN0YSh1cmwpOgogICAgIiIiVHJ1ZSBzaSBsYSBVUkwgZXMgdW5hIHBsYXls
:::aXN0IHB1cmEsIHNpbiB2aWRlbyBpbmRpdmlkdWFsIChzaW4gdj0pLiIiIgogICAg
:::dHJ5OgogICAgICAgIHAgPSB1cmxwYXJzZSh1cmwpCiAgICAgICAgaWYgJ3YnIGlu
:::IHBhcnNlX3FzKHAucXVlcnkpIG9yICd5b3V0dS5iZScgaW4gKHAubmV0bG9jIG9y
:::ICcnKToKICAgICAgICAgICAgcmV0dXJuIEZhbHNlCiAgICAgICAgcmV0dXJuIChw
:::LnBhdGggb3IgJycpLnJzdHJpcCgnLycpLmVuZHN3aXRoKCcvcGxheWxpc3QnKQog
:::ICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICByZXR1cm4gRmFsc2UKCgpkZWYg
:::YWJyaXJfY2FycGV0YShydXRhKToKICAgIHRyeToKICAgICAgICBpZiBvcy5uYW1l
:::ID09ICdudCc6CiAgICAgICAgICAgIG9zLnN0YXJ0ZmlsZShzdHIocnV0YSkpICAj
:::IG5vcWE6IHNvbG8gV2luZG93cwogICAgICAgIGVsc2U6CiAgICAgICAgICAgIHN1
:::YnByb2Nlc3MuUG9wZW4oWyd4ZGctb3BlbicsIHN0cihydXRhKV0pCiAgICBleGNl
:::cHQgRXhjZXB0aW9uOgogICAgICAgIHBhc3MKCgojIC0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0g
:::ZmZtcGVnCmRlZiBidXNjYXJfZmZtcGVnKCk6CiAgICBleGUgPSBzaHV0aWwud2hp
:::Y2goJ2ZmbXBlZycpCiAgICBpZiBleGU6CiAgICAgICAgcmV0dXJuIFBhdGgoZXhl
:::KQogICAgY2FuZGlkYXRvcyA9IFsKICAgICAgICBBUFBfRElSIC8gJ2ZmbXBlZycg
:::LyAnYmluJyAvICdmZm1wZWcuZXhlJywKICAgICAgICBBUFBfRElSIC8gJ2ZmbXBl
:::ZycgLyAnYmluJyAvICdmZm1wZWcnLAogICAgICAgIEFQUF9ESVIgLyAncnVudGlt
:::ZScgLyAnZmZtcGVnLmV4ZScsCiAgICBdCiAgICBmb3IgcCBpbiBjYW5kaWRhdG9z
:::OgogICAgICAgIGlmIHAuZXhpc3RzKCk6CiAgICAgICAgICAgIHJldHVybiBwCiAg
:::ICByZXR1cm4gTm9uZQoKCmRlZiBidXNjYXJfZmZwcm9iZShmZm1wZWcpOgogICAg
:::aWYgZmZtcGVnIGlzIE5vbmU6CiAgICAgICAgcmV0dXJuIHNodXRpbC53aGljaCgn
:::ZmZwcm9iZScpCiAgICBwID0gZmZtcGVnLndpdGhfbmFtZSgnZmZwcm9iZS5leGUn
:::IGlmIG9zLm5hbWUgPT0gJ250JyBlbHNlICdmZnByb2JlJykKICAgIGlmIHAuZXhp
:::c3RzKCk6CiAgICAgICAgcmV0dXJuIHAKICAgIHJldHVybiBzaHV0aWwud2hpY2go
:::J2ZmcHJvYmUnKQoKCllUX0RMUCA9IE5vbmUgICAjIG3Ds2R1bG8geXRfZGxwOyBz
:::ZSByZWxsZW5hIGVuIGNvbXByb2Jhcl9lbnRvcm5vKCkKRkZNUEVHID0gTm9uZSAg
:::ICMgcnV0YSBkZSBmZm1wZWcKRkZQUk9CRSA9IE5vbmUgICMgcnV0YSBkZSBmZnBy
:::b2JlCgoKZGVmIGNvbXByb2Jhcl9lbnRvcm5vKCk6CiAgICBnbG9iYWwgWVRfRExQ
:::LCBGRk1QRUcsIEZGUFJPQkUKICAgIHRyeToKICAgICAgICBpbXBvcnQgeXRfZGxw
:::IGFzIG1vZAogICAgICAgIFlUX0RMUCA9IG1vZAogICAgZXhjZXB0IEV4Y2VwdGlv
:::bjoKICAgICAgICBwYXNzCiAgICBGRk1QRUcgPSBidXNjYXJfZmZtcGVnKCkKICAg
:::IEZGUFJPQkUgPSBidXNjYXJfZmZwcm9iZShGRk1QRUcpCgoKY2xhc3MgUmVnaXN0
:::cm86CiAgICAiIiJMb2dnZXIgcGFyYSB5dC1kbHA6IHJlZW52w61hIGF2aXNvcy9l
:::cnJvcmVzIGFsIHJlZ2lzdHJvIGRlIGxhIEdVSS4iIiIKCiAgICBkZWYgX19pbml0
:::X18oc2VsZik6CiAgICAgICAgc2VsZi5sb2cgPSBOb25lICAjIGxhIEdVSSBsbyBj
:::b25lY3RhOiBsb2cobWVuc2FqZSwgZXRpcXVldGEpCgogICAgZGVmIGRlYnVnKHNl
:::bGYsIG0pOgogICAgICAgIHBhc3MKCiAgICAjIEF2aXNvcyBpbnRlcm5vcyBkZSB5
:::dC1kbHAgcXVlIHNvbG8gbWV0ZW4gcnVpZG8gZW4gZWwgcmVnaXN0cm86CiAgICBB
:::VklTT1NfUlVJRE9TT1MgPSAoJ05vIHN1cHBvcnRlZCBKYXZhU2NyaXB0IHJ1bnRp
:::bWUnLCAnRUpTJykKCiAgICBkZWYgd2FybmluZyhzZWxmLCBtKToKICAgICAgICBt
:::ID0gc3RyKG0pLnN0cmlwKCkKICAgICAgICBpZiBub3QgbSBvciBhbnkoeCBpbiBt
:::IGZvciB4IGluIHNlbGYuQVZJU09TX1JVSURPU09TKToKICAgICAgICAgICAgcmV0
:::dXJuCiAgICAgICAgaWYgc2VsZi5sb2c6CiAgICAgICAgICAgIHNlbGYubG9nKG0s
:::ICdhdmlzbycpCgogICAgZGVmIGVycm9yKHNlbGYsIG0pOgogICAgICAgIG0gPSBz
:::dHIobSkuc3RyaXAoKQogICAgICAgIGlmIG0gYW5kIHNlbGYubG9nOgogICAgICAg
:::ICAgICBzZWxmLmxvZyhtLCAnZXJyb3InKQoKClJFR0lTVFJPID0gUmVnaXN0cm8o
:::KQoKTk9NQlJFU19QUCA9IHsKICAgICdGRm1wZWdFeHRyYWN0QXVkaW8nOiAnQ29u
:::dmlydGllbmRvIGVsIGF1ZGlvIGNvbiBGRm1wZWcnLAogICAgJ0ZGbXBlZ01ldGFk
:::YXRhJzogJ0VzY3JpYmllbmRvIGV0aXF1ZXRhcyAodMOtdHVsby9hcnRpc3RhKScs
:::CiAgICAnRW1iZWRUaHVtYm5haWwnOiAnSW5jcnVzdGFuZG8gbGEgY2Fyw6F0dWxh
:::JywKICAgICdNb3ZlRmlsZXMnOiAnT3JnYW5pemFuZG8gYXJjaGl2b3MnLAogICAg
:::J0ZGbXBlZ01lcmdlcic6ICdVbmllbmRvIHBpc3RhcyBkZSB2aWRlbyB5IGF1ZGlv
:::JywKICAgICdGRm1wZWdWaWRlb0NvbnZlcnRvcic6ICdDb252aXJ0aWVuZG8gZWwg
:::dmlkZW8nLAp9CgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gZm9ybWF0b3MKRk9STUFUT1Mg
:::PSB7CiAgICAnQUFDJzogZGljdCh0ZXh0bz0nQUFDICgubTRhKScsIGV4dD0nbTRh
:::JywKICAgICAgICAgICAgICAgIGNhbGlkYWRlcz1bJzk2aycsICcxMjhrJ10sIGRl
:::ZmVjdG89JzEyOGsnKSwKICAgICdNUDMnOiBkaWN0KHRleHRvPSdNUDMgKC5tcDMp
:::JywgZXh0PSdtcDMnLAogICAgICAgICAgICAgICAgY2FsaWRhZGVzPVsnOTZrJywg
:::JzEyOGsnLCAnMTkyaycsICcyNTZrJywgJzMyMGsnXSwKICAgICAgICAgICAgICAg
:::IGRlZmVjdG89JzMyMGsnKSwKICAgICdGTEFDJzogZGljdCh0ZXh0bz0nRkxBQyAo
:::LmZsYWMpJywgZXh0PSdmbGFjJywKICAgICAgICAgICAgICAgICBjYWxpZGFkZXM9
:::WydzaW4gcGVyZGlkYSddLCBkZWZlY3RvPSdzaW4gcGVyZGlkYScpLAogICAgJ1dB
:::Vic6IGRpY3QodGV4dG89J1dBViAoLndhdiknLCBleHQ9J3dhdicsCiAgICAgICAg
:::ICAgICAgICBjYWxpZGFkZXM9WydzaW4gcGVyZGlkYSddLCBkZWZlY3RvPSdzaW4g
:::cGVyZGlkYScpLAogICAgJ1dNQSc6IGRpY3QodGV4dG89J1dNQSAoLndtYSknLCBl
:::eHQ9J3dtYScsCiAgICAgICAgICAgICAgICBjYWxpZGFkZXM9Wyc5NmsnLCAnMTI4
:::ayddLCBkZWZlY3RvPScxMjhrJyksCiAgICAnQVZJJzogZGljdCh0ZXh0bz0nQVZJ
:::IC0gc2hlaWp1IDEuOCIgKDEyOHgxNjApJywgZXh0PSdhdmknLAogICAgICAgICAg
:::ICAgICAgY2FsaWRhZGVzPVsnMTI4eDE2MCDCtyAxNiBmcHMnXSwgZGVmZWN0bz0n
:::MTI4eDE2MCDCtyAxNiBmcHMnKSwKfQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBwcm9n
:::cmVzbwpkZWYgaG9va3NfZ3VpKGNvbGEpOgogICAgIiIiQ3JlYSBsb3MgaG9va3Mg
:::ZGUgeXQtZGxwIHF1ZSBwdWJsaWNhbiBldmVudG9zIGVuIGxhIGNvbGEgZGUgbGEg
:::R1VJLiIiIgogICAgZXN0YWRvID0geyd0aXR1bG8nOiBGYWxzZSwgJ3BwX3VsdCc6
:::IE5vbmV9CgogICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAgICAgICAgY29sYS5w
:::dXQoKCdsb2cnLCBtLCB0KSkKCiAgICBkZWYgcHJvZ3Jlc28oZCk6CiAgICAgICAg
:::aWYgZFsnc3RhdHVzJ10gPT0gJ2Rvd25sb2FkaW5nJzoKICAgICAgICAgICAgaWYg
:::bm90IGVzdGFkb1sndGl0dWxvJ106CiAgICAgICAgICAgICAgICBpbmZvID0gZC5n
:::ZXQoJ2luZm9fZGljdCcpIG9yIHt9CiAgICAgICAgICAgICAgICB0ID0gaW5mby5n
:::ZXQoJ3RpdGxlJykgb3IgUGF0aChkLmdldCgnZmlsZW5hbWUnKSBvciAnJykuc3Rl
:::bQogICAgICAgICAgICAgICAgaWYgdDoKICAgICAgICAgICAgICAgICAgICBsb2co
:::J+KZqiAnICsgc3RyKHQpWzo5MF0sICd0aXR1bG8nKQogICAgICAgICAgICAgICAg
:::ICAgIGVzdGFkb1sndGl0dWxvJ10gPSBUcnVlCiAgICAgICAgICAgIHRvdGFsID0g
:::ZC5nZXQoJ3RvdGFsX2J5dGVzJykgb3IgZC5nZXQoJ3RvdGFsX2J5dGVzX2VzdGlt
:::YXRlJykgb3IgMAogICAgICAgICAgICBkb25lID0gZC5nZXQoJ2Rvd25sb2FkZWRf
:::Ynl0ZXMnLCAwKQogICAgICAgICAgICB2ZWwgPSBkLmdldCgnc3BlZWQnKQogICAg
:::ICAgICAgICBldGEgPSBkLmdldCgnZXRhJykKICAgICAgICAgICAgaWYgdG90YWw6
:::CiAgICAgICAgICAgICAgICBwY3QgPSBkb25lIC8gdG90YWwgKiAxMDAKICAgICAg
:::ICAgICAgICAgIHRleHRvID0gZid7cGN0OjUuMWZ9JSDCtyB7Zm10X3RhbShkb25l
:::KX0gLyB7Zm10X3RhbSh0b3RhbCl9JwogICAgICAgICAgICAgICAgaWYgdmVsOgog
:::ICAgICAgICAgICAgICAgICAgIHRleHRvICs9IGYnIMK3IHtmbXRfdGFtKHZlbCl9
:::L3MnCiAgICAgICAgICAgICAgICBpZiBldGEgaXMgbm90IE5vbmU6CiAgICAgICAg
:::ICAgICAgICAgICAgdGV4dG8gKz0gZicgwrcgcXVlZGFuIHtmbXRfdGllbShldGEp
:::fScKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgncHJvZycsIHBjdCwgdGV4dG8p
:::KQogICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgdiA9IGYne2ZtdF90
:::YW0odmVsKX0vcycgaWYgdmVsIGVsc2UgJycKICAgICAgICAgICAgICAgIGNvbGEu
:::cHV0KCgncHJvZycsIE5vbmUsIGYne2ZtdF90YW0oZG9uZSl9IMK3IHt2fScpKQog
:::ICAgICAgIGVsaWYgZFsnc3RhdHVzJ10gPT0gJ2ZpbmlzaGVkJzoKICAgICAgICAg
:::ICAgZXN0YWRvWydwcF91bHQnXSA9IE5vbmUKICAgICAgICAgICAgY29sYS5wdXQo
:::KCdsb2cnLCAnRGVzY2FyZ2EgcmVjaWJpZGEuIFByb2Nlc2FuZG8uLi4nLCAnZ3Jp
:::cycpKQogICAgICAgICAgICBjb2xhLnB1dCgoJ3Byb2cnLCAwLCAnUHJvY2VzYW5k
:::by4uLicpKQoKICAgIGRlZiBwb3N0cHJvY2VzbyhkKToKICAgICAgICBpZiBkWydz
:::dGF0dXMnXSA9PSAnc3RhcnRlZCc6CiAgICAgICAgICAgIG5vbSA9IChkLmdldCgn
:::cG9zdHByb2Nlc3Nvcl9uYW1lJykKICAgICAgICAgICAgICAgICAgIG9yIGQuZ2V0
:::KCdwb3N0cHJvY2Vzc29yJykgb3IgJ1Bvc3Rwcm9jZXNvJykKICAgICAgICAgICAg
:::aWYgbm9tID09IGVzdGFkb1sncHBfdWx0J106CiAgICAgICAgICAgICAgICByZXR1
:::cm4gICMgeXQtZGxwIGEgdmVjZXMgYW51bmNpYSBlbCBtaXNtbyBwYXNvIGRvcyB2
:::ZWNlcwogICAgICAgICAgICBlc3RhZG9bJ3BwX3VsdCddID0gbm9tCiAgICAgICAg
:::ICAgIHRleHRvID0gTk9NQlJFU19QUC5nZXQobm9tLCBub20pICsgJy4uLicKICAg
:::ICAgICAgICAgY29sYS5wdXQoKCdsb2cnLCAn4oaSICcgKyB0ZXh0bywgJ2dyaXMn
:::KSkKICAgICAgICAgICAgY29sYS5wdXQoKCdwcm9nJywgTm9uZSwgdGV4dG8pKQoK
:::ICAgIHJldHVybiBwcm9ncmVzbywgcG9zdHByb2Nlc28KCgojIC0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0gb3BjaW9uZXMKZGVmIG9wdHNfYmFzZShjYXJwZXRhLCBjb2xhKToKICAg
:::IHByb2dyZXNvLCBwb3N0cHJvY2VzbyA9IGhvb2tzX2d1aShjb2xhKQogICAgbyA9
:::IHsKICAgICAgICAnb3V0dG1wbCc6IHN0cihjYXJwZXRhIC8gJyUodGl0bGUpcy4l
:::KGV4dClzJyksCiAgICAgICAgJ3F1aWV0JzogVHJ1ZSwKICAgICAgICAnbm9fd2Fy
:::bmluZ3MnOiBUcnVlLAogICAgICAgICdub3Byb2dyZXNzJzogVHJ1ZSwKICAgICAg
:::ICAnbm9wbGF5bGlzdCc6IFRydWUsCiAgICAgICAgJ2lnbm9yZWVycm9ycyc6IEZh
:::bHNlLAogICAgICAgICdyZXRyaWVzJzogMTAsCiAgICAgICAgJ2ZyYWdtZW50X3Jl
:::dHJpZXMnOiAxMCwKICAgICAgICAnc29ja2V0X3RpbWVvdXQnOiAzMCwKICAgICAg
:::ICAnY29uY3VycmVudF9mcmFnbWVudF9kb3dubG9hZHMnOiA0LAogICAgICAgICd3
:::aW5kb3dzZmlsZW5hbWVzJzogVHJ1ZSwKICAgICAgICAnb3ZlcndyaXRlcyc6IEZh
:::bHNlLAogICAgICAgICdsb2dnZXInOiBSRUdJU1RSTywKICAgICAgICAncHJvZ3Jl
:::c3NfaG9va3MnOiBbcHJvZ3Jlc29dLAogICAgICAgICdwb3N0cHJvY2Vzc29yX2hv
:::b2tzJzogW3Bvc3Rwcm9jZXNvXSwKICAgIH0KICAgIGlmIEZGTVBFRzoKICAgICAg
:::ICBvWydmZm1wZWdfbG9jYXRpb24nXSA9IHN0cihGRk1QRUcucGFyZW50KQogICAg
:::cmV0dXJuIG8KCgpkZWYgY29udmVydGlyX2ZmbXBlZyhjbWQsIGV0aXF1ZXRhLCBj
:::b2xhKToKICAgICIiIkVqZWN1dGEgRkZtcGVnIChsaXN0YSBkZSBhcmd1bWVudG9z
:::LCBzaW4gc2hlbGwpIGNvbiBtYXJxdWVlLiIiIgogICAgY29sYS5wdXQoKCdwcm9n
:::JywgTm9uZSwgZXRpcXVldGEpKQoKICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgog
:::ICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgdHJ5OgogICAgICAg
:::IHAgPSBzdWJwcm9jZXNzLnJ1bihjbWQsIHN0ZG91dD1zdWJwcm9jZXNzLlBJUEUs
:::CiAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0ZGVycj1zdWJwcm9jZXNzLlBJ
:::UEUsIHRleHQ9VHJ1ZSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgZW5jb2Rp
:::bmc9J3V0Zi04JywgZXJyb3JzPSdyZXBsYWNlJykKICAgIGV4Y2VwdCBGaWxlTm90
:::Rm91bmRFcnJvcjoKICAgICAgICBwID0gTm9uZQogICAgaWYgcCBpcyBOb25lIG9y
:::IHAucmV0dXJuY29kZSAhPSAwOgogICAgICAgIGxvZygn4pyWIEZGbXBlZyBkZXZv
:::bHZpw7MgdW4gZXJyb3I6JywgJ2Vycm9yJykKICAgICAgICBpZiBwIGlzIG5vdCBO
:::b25lOgogICAgICAgICAgICBmb3IgbG4gaW4gKHAuc3RkZXJyIG9yICcnKS5zdHJp
:::cCgpLnNwbGl0bGluZXMoKVstNDpdOgogICAgICAgICAgICAgICAgbG9nKCcgICAn
:::ICsgbG5bOjE4MF0sICdncmlzJykKICAgICAgICBjb2xhLnB1dCgoJ3Byb2cnLCAw
:::LCAnJykpCiAgICAgICAgcmV0dXJuIEZhbHNlCiAgICByZXR1cm4gVHJ1ZQoKCmRl
:::ZiBhcmNoaXZvX2ZpbmFsKGluZm8sIGNhcnBldGEsIGV4dCk6CiAgICAiIiJMb2Nh
:::bGl6YSBlbCBhcmNoaXZvIHJlc3VsdGFudGUgKHl0LWRscCBsbyByZXBvcnRhOyBm
:::YWxsYmFjazogbcOhcyBudWV2bykuIiIiCiAgICB0cnk6CiAgICAgICAgZm9yIGQg
:::aW4gKGluZm8uZ2V0KCdyZXF1ZXN0ZWRfZG93bmxvYWRzJykgb3IgW10pOgogICAg
:::ICAgICAgICBmID0gZC5nZXQoJ2ZpbGVwYXRoJykKICAgICAgICAgICAgaWYgZjoK
:::ICAgICAgICAgICAgICAgIHJldHVybiBQYXRoKGYpCiAgICBleGNlcHQgRXhjZXB0
:::aW9uOgogICAgICAgIHBhc3MKICAgIGNhbmQgPSBzb3J0ZWQoY2FycGV0YS5nbG9i
:::KCcqLicgKyBleHQpLAogICAgICAgICAgICAgICAgICBrZXk9bGFtYmRhIHA6IHAu
:::c3RhdCgpLnN0X210aW1lLCByZXZlcnNlPVRydWUpCiAgICByZXR1cm4gY2FuZFsw
:::XSBpZiBjYW5kIGVsc2UgTm9uZQoKCmRlZiBsaW1waWFyX21pbmlhdHVyYXMoY2Fy
:::cGV0YSwgYXJjaGl2byk6CiAgICAiIiJCb3JyYSBtaW5pYXR1cmFzIHN1ZWx0YXMg
:::cXVlIEVtYmVkVGh1bWJuYWlsIGRlamFyYSBzaW4gaW5jcnVzdGFyLiIiIgogICAg
:::Zm9yIGV4dCBpbiAoJy53ZWJwJywgJy5qcGcnLCAnLmpwZWcnLCAnLnBuZycpOgog
:::ICAgICAgIHQgPSBhcmNoaXZvLndpdGhfc3VmZml4KGV4dCkKICAgICAgICBpZiB0
:::LmV4aXN0cygpOgogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICB0LnVu
:::bGluaygpCiAgICAgICAgICAgIGV4Y2VwdCBPU0Vycm9yOgogICAgICAgICAgICAg
:::ICAgcGFzcwoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBldGlxdWV0YXMKZGVmIF9hcnRp
:::c3RhX2xpbXBpbyhpbmZvKToKICAgICIiIk5vbWJyZSBkZWwgYXJ0aXN0YSBsZWdp
:::YmxlIHBhcmEgcmVwcm9kdWN0b3Jlcy4KCiAgICBMb3MgY2FuYWxlcyBhdXRvbWF0
:::aWNvcyBkZSBtdXNpY2EgZGUgWW91VHViZSBzZSBsbGFtYW4gJ1ggLSBUb3BpYyc7
:::CiAgICBlc2Ugc3VmaWpvIHNvYnJhIGN1YW5kbyBzZSB2ZSBlbiBsYSBwYW50YWxs
:::YSBkZSB1biByZXByb2R1Y3Rvci4iIiIKICAgIGEgPSAoaW5mby5nZXQoJ2FydGlz
:::dCcpIG9yIGluZm8uZ2V0KCdjcmVhdG9yJykKICAgICAgICAgb3IgaW5mby5nZXQo
:::J3VwbG9hZGVyJykgb3IgaW5mby5nZXQoJ2NoYW5uZWwnKSBvciAnJykKICAgIGEg
:::PSBzdHIoYSkuc3RyaXAoKQogICAgYSA9IHJlLnN1YihyJ1xzKi1ccypUb3BpY1xz
:::KiQnLCAnJywgYSwgZmxhZ3M9cmUuSSkuc3RyaXAoKQogICAgcmV0dXJuIGEKCgpk
:::ZWYgX2FsYnVtX2RlKGluZm8pOgogICAgIiIiQWxidW0gcGFyYSBlbCBhcmNoaXZv
:::IGZpbmFsLgoKICAgIHl0LWRscCBzb2xvIGVzY3JpYmUgYWxidW0gc2kgZWwgcHJv
:::cGlvIHZpZGVvIGxvIHRyYWUgKGNhc2kgbnVuY2EpOgogICAgcG9yIGVzbyBsb3Mg
:::cmVwcm9kdWN0b3JlcyBtb3N0cmFiYW4gJ2FsYnVtIGRlc2Nvbm9jaWRvJy4gT3Jk
:::ZW4gZGUKICAgIHByZWZlcmVuY2lhOiBhbGJ1bSByZWFsIC0+IG5vbWJyZSBkZSBs
:::YSBwbGF5bGlzdCAtPiBhcnRpc3RhLiIiIgogICAgZm9yIGNsYXZlIGluICgnYWxi
:::dW0nLCAncGxheWxpc3RfdGl0bGUnKToKICAgICAgICB2ID0gc3RyKGluZm8uZ2V0
:::KGNsYXZlKSBvciAnJykuc3RyaXAoKQogICAgICAgIGlmIHY6CiAgICAgICAgICAg
:::IHJldHVybiB2CiAgICByZXR1cm4gX2FydGlzdGFfbGltcGlvKGluZm8pIG9yICdZ
:::b3VUdWJlJwoKCmRlZiBhcGxpY2FyX3RhZ3MoaW5mbywgYXJjaGl2bywgbG9nPU5v
:::bmUpOgogICAgIiIiRXNjcmliZSBjb24gbXV0YWdlbiBsYXMgZXRpcXVldGFzIGRl
:::bCBhcmNoaXZvIGZpbmFsLgoKICAgIEdhcmFudGl6YSBxdWUgVE9ET1MgbG9zIHJl
:::cHJvZHVjdG9yZXMgbXVlc3RyZW4gYXJ0aXN0YSB5IGFsYnVtLAogICAgYXVucXVl
:::IEZGbXBlZ01ldGFkYXRhIGRlIHl0LWRscCBubyBsb3MgaGF5YSBlc2NyaXRvLiBM
:::YSBjYXJhdHVsYQogICAgcXVlIEVtYmVkVGh1bWJuYWlsIHlhIGluY3J1c3RvIHNl
:::IGNvbnNlcnZhIChzb2xvIHNlIHRvY2FuIGxhcwogICAgY2xhdmVzIGRlIHRleHRv
:::KS4gRm9ybWF0b3M6IG00YSwgbXAzLCB3YXYsIGZsYWMgeSB3bWEuIiIiCiAgICB0
:::cnk6CiAgICAgICAgcCA9IFBhdGgoYXJjaGl2bykKICAgICAgICBpZiBub3QgcC5l
:::eGlzdHMoKToKICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgYXJ0aXN0YSA9IF9h
:::cnRpc3RhX2xpbXBpbyhpbmZvKQogICAgICAgIGFsYnVtID0gX2FsYnVtX2RlKGlu
:::Zm8pCiAgICAgICAgdGl0dWxvID0gc3RyKGluZm8uZ2V0KCd0cmFjaycpIG9yIGlu
:::Zm8uZ2V0KCd0aXRsZScpIG9yICcnKS5zdHJpcCgpCiAgICAgICAgZmVjaGEgPSBz
:::dHIoaW5mby5nZXQoJ3JlbGVhc2VfeWVhcicpIG9yICcnKQogICAgICAgIGlmIG5v
:::dCBmZWNoYToKICAgICAgICAgICAgZmVjaGEgPSBzdHIoaW5mby5nZXQoJ3VwbG9h
:::ZF9kYXRlJykgb3IgJycpCiAgICAgICAgICAgIGlmIGxlbihmZWNoYSkgPT0gOCBh
:::bmQgZmVjaGEuaXNkaWdpdCgpOgogICAgICAgICAgICAgICAgZmVjaGEgPSBmZWNo
:::YVs6NF0KICAgICAgICBleHQgPSBwLnN1ZmZpeC5sb3dlcigpCiAgICAgICAgaWYg
:::ZXh0ID09ICcubTRhJzoKICAgICAgICAgICAgZnJvbSBtdXRhZ2VuLm1wNCBpbXBv
:::cnQgTVA0CiAgICAgICAgICAgIG0gPSBNUDQoc3RyKHApKQogICAgICAgICAgICBp
:::ZiB0aXR1bG86CiAgICAgICAgICAgICAgICBtWydceGE5bmFtJ10gPSBbdGl0dWxv
:::XQogICAgICAgICAgICBpZiBhcnRpc3RhOgogICAgICAgICAgICAgICAgbVsnXHhh
:::OUFSVCddID0gW2FydGlzdGFdCiAgICAgICAgICAgICAgICBtWydhQVJUJ10gPSBb
:::YXJ0aXN0YV0KICAgICAgICAgICAgaWYgYWxidW06CiAgICAgICAgICAgICAgICBt
:::WydceGE5YWxiJ10gPSBbYWxidW1dCiAgICAgICAgICAgIGlmIGZlY2hhOgogICAg
:::ICAgICAgICAgICAgbVsnXHhhOWRheSddID0gW2ZlY2hhXQogICAgICAgICAgICBt
:::LnNhdmUoKQogICAgICAgIGVsaWYgZXh0ID09ICcubXAzJzoKICAgICAgICAgICAg
:::ZnJvbSBtdXRhZ2VuLmlkMyBpbXBvcnQgSUQzLCBUQUxCLCBURFJDLCBUSVQyLCBU
:::UEUxLCBUUEUyCiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHRhZ3Mg
:::PSBJRDMoc3RyKHApKQogICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAg
:::ICAgICAgICAgICAgdGFncyA9IElEMygpCiAgICAgICAgICAgIGlmIHRpdHVsbzoK
:::ICAgICAgICAgICAgICAgIHRhZ3Muc2V0YWxsKCdUSVQyJywgW1RJVDIoZW5jb2Rp
:::bmc9MywgdGV4dD1bdGl0dWxvXSldKQogICAgICAgICAgICBpZiBhcnRpc3RhOgog
:::ICAgICAgICAgICAgICAgdGFncy5zZXRhbGwoJ1RQRTEnLCBbVFBFMShlbmNvZGlu
:::Zz0zLCB0ZXh0PVthcnRpc3RhXSldKQogICAgICAgICAgICAgICAgdGFncy5zZXRh
:::bGwoJ1RQRTInLCBbVFBFMihlbmNvZGluZz0zLCB0ZXh0PVthcnRpc3RhXSldKQog
:::ICAgICAgICAgICBpZiBhbGJ1bToKICAgICAgICAgICAgICAgIHRhZ3Muc2V0YWxs
:::KCdUQUxCJywgW1RBTEIoZW5jb2Rpbmc9MywgdGV4dD1bYWxidW1dKV0pCiAgICAg
:::ICAgICAgIGlmIGZlY2hhOgogICAgICAgICAgICAgICAgdGFncy5zZXRhbGwoJ1RE
:::UkMnLCBbVERSQyhlbmNvZGluZz0zLCB0ZXh0PVtmZWNoYV0pXSkKICAgICAgICAg
:::ICAgdGFncy5zYXZlKHN0cihwKSwgdjJfdmVyc2lvbj0zKQogICAgICAgIGVsaWYg
:::ZXh0ID09ICcud2F2JzoKICAgICAgICAgICAgZnJvbSBtdXRhZ2VuLmlkMyBpbXBv
:::cnQgVEFMQiwgVERSQywgVElUMiwgVFBFMSwgVFBFMgogICAgICAgICAgICBmcm9t
:::IG11dGFnZW4ud2F2ZSBpbXBvcnQgV0FWRQogICAgICAgICAgICB3ID0gV0FWRShz
:::dHIocCkpCiAgICAgICAgICAgIGlmIHcudGFncyBpcyBOb25lOgogICAgICAgICAg
:::ICAgICAgdy5hZGRfdGFncygpCiAgICAgICAgICAgIGlmIHRpdHVsbzoKICAgICAg
:::ICAgICAgICAgIHcudGFncy5zZXRhbGwoJ1RJVDInLCBbVElUMihlbmNvZGluZz0z
:::LCB0ZXh0PVt0aXR1bG9dKV0pCiAgICAgICAgICAgIGlmIGFydGlzdGE6CiAgICAg
:::ICAgICAgICAgICB3LnRhZ3Muc2V0YWxsKCdUUEUxJywgW1RQRTEoZW5jb2Rpbmc9
:::MywgdGV4dD1bYXJ0aXN0YV0pXSkKICAgICAgICAgICAgICAgIHcudGFncy5zZXRh
:::bGwoJ1RQRTInLCBbVFBFMihlbmNvZGluZz0zLCB0ZXh0PVthcnRpc3RhXSldKQog
:::ICAgICAgICAgICBpZiBhbGJ1bToKICAgICAgICAgICAgICAgIHcudGFncy5zZXRh
:::bGwoJ1RBTEInLCBbVEFMQihlbmNvZGluZz0zLCB0ZXh0PVthbGJ1bV0pXSkKICAg
:::ICAgICAgICAgaWYgZmVjaGE6CiAgICAgICAgICAgICAgICB3LnRhZ3Muc2V0YWxs
:::KCdURFJDJywgW1REUkMoZW5jb2Rpbmc9MywgdGV4dD1bZmVjaGFdKV0pCiAgICAg
:::ICAgICAgIHcuc2F2ZSgpCiAgICAgICAgZWxpZiBleHQgPT0gJy5mbGFjJzoKICAg
:::ICAgICAgICAgZnJvbSBtdXRhZ2VuLmZsYWMgaW1wb3J0IEZMQUMKICAgICAgICAg
:::ICAgZiA9IEZMQUMoc3RyKHApKQogICAgICAgICAgICBpZiB0aXR1bG86CiAgICAg
:::ICAgICAgICAgICBmWyd0aXRsZSddID0gW3RpdHVsb10KICAgICAgICAgICAgaWYg
:::YXJ0aXN0YToKICAgICAgICAgICAgICAgIGZbJ2FydGlzdCddID0gW2FydGlzdGFd
:::CiAgICAgICAgICAgICAgICBmWydhbGJ1bWFydGlzdCddID0gW2FydGlzdGFdCiAg
:::ICAgICAgICAgIGlmIGFsYnVtOgogICAgICAgICAgICAgICAgZlsnYWxidW0nXSA9
:::IFthbGJ1bV0KICAgICAgICAgICAgaWYgZmVjaGE6CiAgICAgICAgICAgICAgICBm
:::WydkYXRlJ10gPSBbZmVjaGFdCiAgICAgICAgICAgIGYuc2F2ZSgpCiAgICAgICAg
:::ZWxpZiBleHQgPT0gJy53bWEnOgogICAgICAgICAgICBmcm9tIG11dGFnZW4uYXNm
:::IGltcG9ydCBBU0YKICAgICAgICAgICAgYSA9IEFTRihzdHIocCkpCiAgICAgICAg
:::ICAgIGlmIHRpdHVsbzoKICAgICAgICAgICAgICAgIGFbJ1RpdGxlJ10gPSBbdGl0
:::dWxvXQogICAgICAgICAgICBpZiBhcnRpc3RhOgogICAgICAgICAgICAgICAgYVsn
:::QXV0aG9yJ10gPSBbYXJ0aXN0YV0KICAgICAgICAgICAgICAgIGFbJ1dNL0FsYnVt
:::QXJ0aXN0J10gPSBbYXJ0aXN0YV0KICAgICAgICAgICAgaWYgYWxidW06CiAgICAg
:::ICAgICAgICAgICBhWydXTS9BbGJ1bVRpdGxlJ10gPSBbYWxidW1dCiAgICAgICAg
:::ICAgIGlmIGZlY2hhOgogICAgICAgICAgICAgICAgYVsnV00vWWVhciddID0gW2Zl
:::Y2hhXQogICAgICAgICAgICBhLnNhdmUoKQogICAgICAgIGVsc2U6CiAgICAgICAg
:::ICAgIHJldHVybgogICAgICAgIGlmIGxvZzoKICAgICAgICAgICAgbG9nKCdFdGlx
:::dWV0YXMgZXNjcml0YXM6IGFydGlzdGEgwqslc8K7IMK3IMOhbGJ1bSDCqyVzwrsn
:::CiAgICAgICAgICAgICAgICAlIChhcnRpc3RhIG9yICfigJQnLCBhbGJ1bSBvciAn
:::4oCUJyksICdncmlzJykKICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZToKICAgICAg
:::ICAjIGxhcyBldGlxdWV0YXMgbm8gc29uIGNyaXRpY2FzOiBudW5jYSBkZWJlbiBy
:::b21wZXIgbGEgZGVzY2FyZ2EKICAgICAgICBpZiBsb2c6CiAgICAgICAgICAgIGxv
:::ZygnTm8gc2UgcHVkaWVyb24gZXNjcmliaXIgdG9kYXMgbGFzIGV0aXF1ZXRhczog
:::JXMnICUgZSwKICAgICAgICAgICAgICAgICdhdmlzbycpCgoKIyAtLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tIGRlc2NhcmdhcwpkZWYgZGVzY2FyZ2FyX2F1ZGlvKHVybCwgbm9tYnJl
:::X2ZtdCwgY2FsaWRhZCwgZGVzdGlubywgZW1iZWJlciwgY29sYSk6CiAgICAiIiJB
:::QUMgKC5tNGEpIC8gTVAzIC8gRkxBQyAvIFdBViB2w61hIHBvc3Rwcm9jZXNhZG9y
:::ZXMgZGUgeXQtZGxwLiIiIgogICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAgICAg
:::ICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICBmbXQgPSBGT1JNQVRPU1tu
:::b21icmVfZm10XQogICAgY2FycGV0YSA9IGRlc3Rpbm8gICAgICAgICAgIyB2Mi4z
:::OiBzaW4gc3ViY2FycGV0YXMgcG9yIGZvcm1hdG8KICAgIGNhcnBldGEubWtkaXIo
:::cGFyZW50cz1UcnVlLCBleGlzdF9vaz1UcnVlKQogICAgY29kZWMgPSBmbXRbJ2V4
:::dCddCiAgICBjb25fcG9ydGFkYSA9IGVtYmViZXIgYW5kIG5vbWJyZV9mbXQgaW4g
:::KCdBQUMnLCAnTVAzJywgJ0ZMQUMnKQogICAgY29uX3RhZ3MgPSBlbWJlYmVyCiAg
:::ICBwcHMgPSBbeydrZXknOiAnRkZtcGVnRXh0cmFjdEF1ZGlvJywgJ3ByZWZlcnJl
:::ZGNvZGVjJzogY29kZWMsCiAgICAgICAgICAgICdwcmVmZXJyZWRxdWFsaXR5Jzog
:::Y2FsaWRhZCBvciAnMCd9XQogICAgaWYgY29uX3RhZ3M6CiAgICAgICAgcHBzLmFw
:::cGVuZCh7J2tleSc6ICdGRm1wZWdNZXRhZGF0YScsICdhZGRfbWV0YWRhdGEnOiBU
:::cnVlfSkKICAgIGlmIGNvbl9wb3J0YWRhOgogICAgICAgIHBwcy5hcHBlbmQoeydr
:::ZXknOiAnRW1iZWRUaHVtYm5haWwnLAogICAgICAgICAgICAgICAgICAgICdhbHJl
:::YWR5X2hhdmVfdGh1bWJuYWlsJzogRmFsc2V9KQogICAgbyA9IG9wdHNfYmFzZShj
:::YXJwZXRhLCBjb2xhKQogICAgb1snZm9ybWF0J10gPSAnYmVzdGF1ZGlvL2Jlc3Qn
:::CiAgICBvWydwb3N0cHJvY2Vzc29ycyddID0gcHBzCiAgICBvWyd3cml0ZXRodW1i
:::bmFpbCddID0gY29uX3BvcnRhZGEKICAgIHdpdGggWVRfRExQLllvdXR1YmVETChv
:::KSBhcyB5ZGw6CiAgICAgICAgaW5mbyA9IHlkbC5leHRyYWN0X2luZm8odXJsLCBk
:::b3dubG9hZD1UcnVlKQogICAgYXJjaGl2byA9IGFyY2hpdm9fZmluYWwoaW5mbywg
:::Y2FycGV0YSwgY29kZWMpCiAgICBpZiBhcmNoaXZvIGFuZCBjb25fcG9ydGFkYToK
:::ICAgICAgICBsaW1waWFyX21pbmlhdHVyYXMoY2FycGV0YSwgYXJjaGl2bykKICAg
:::IGlmIGFyY2hpdm86CiAgICAgICAgYXBsaWNhcl90YWdzKGluZm8sIGFyY2hpdm8s
:::IGxvZykKICAgIHJldHVybiBpbmZvLCBhcmNoaXZvCgoKZGVmIGRlc2Nhcmdhcl93
:::bWEodXJsLCBjYWxpZGFkLCBkZXN0aW5vLCBlbWJlYmVyLCBjb2xhKToKICAgICIi
:::IldNQSA5Ni8xMjgga2JwczogeXQtZGxwIG5vIHNvcG9ydGEgd21hLCBhc8OtIHF1
:::ZSBzZSBiYWphIGEgV0FWIChjb24KICAgIGV0aXF1ZXRhcykgeSBsdWVnbyBGRm1w
:::ZWcgcmVjb2RpZmljYSBhIHdtYXYyIGRlbnRybyBkZWwgLndtYSBmaW5hbC4KICAg
:::IChFbCBjb250ZW5lZG9yIEFTRiBkZSBmZm1wZWcgbm8gc29wb3J0YSBjYXLDoXR1
:::bGEgaW5jcnVzdGFkYS4pIiIiCiAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAg
:::ICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgIGNhcnBldGEgPSBkZXN0
:::aW5vICAgICAgICAgICMgdjIuMzogc2luIHN1YmNhcnBldGFzIHBvciBmb3JtYXRv
:::CiAgICB0bXAgPSBjYXJwZXRhIC8gJ190bXAnCiAgICBzaHV0aWwucm10cmVlKHRt
:::cCwgaWdub3JlX2Vycm9ycz1UcnVlKQogICAgdG1wLm1rZGlyKHBhcmVudHM9VHJ1
:::ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgIG8gPSBvcHRzX2Jhc2UodG1wLCBjb2xhKQog
:::ICAgb1snZm9ybWF0J10gPSAnYmVzdGF1ZGlvL2Jlc3QnCiAgICBwcHMgPSBbeydr
:::ZXknOiAnRkZtcGVnRXh0cmFjdEF1ZGlvJywgJ3ByZWZlcnJlZGNvZGVjJzogJ3dh
:::dicsCiAgICAgICAgICAgICdwcmVmZXJyZWRxdWFsaXR5JzogJzAnfV0KICAgIGlm
:::IGVtYmViZXI6CiAgICAgICAgcHBzLmFwcGVuZCh7J2tleSc6ICdGRm1wZWdNZXRh
:::ZGF0YScsICdhZGRfbWV0YWRhdGEnOiBUcnVlfSkKICAgIG9bJ3Bvc3Rwcm9jZXNz
:::b3JzJ10gPSBwcHMKICAgIHdpdGggWVRfRExQLllvdXR1YmVETChvKSBhcyB5ZGw6
:::CiAgICAgICAgaW5mbyA9IHlkbC5leHRyYWN0X2luZm8odXJsLCBkb3dubG9hZD1U
:::cnVlKQogICAgd2F2ID0gYXJjaGl2b19maW5hbChpbmZvLCB0bXAsICd3YXYnKQog
:::ICAgaWYgbm90IHdhdjoKICAgICAgICByYWlzZSBSdW50aW1lRXJyb3IoJ05vIHNl
:::IGVuY29udHLDsyBlbCBXQVYgaW50ZXJtZWRpby4nKQogICAgbWV0YSA9IFtdCiAg
:::ICBpZiBlbWJlYmVyOgogICAgICAgIGFydGlzdGEgPSAoaW5mby5nZXQoJ2FydGlz
:::dCcpIG9yIGluZm8uZ2V0KCd1cGxvYWRlcicpCiAgICAgICAgICAgICAgICAgICBv
:::ciBpbmZvLmdldCgnY2hhbm5lbCcpIG9yICcnKQogICAgICAgIGlmIGluZm8uZ2V0
:::KCd0aXRsZScpOgogICAgICAgICAgICBtZXRhICs9IFsnLW1ldGFkYXRhJywgJ3Rp
:::dGxlPScgKyBzdHIoaW5mb1sndGl0bGUnXSldCiAgICAgICAgaWYgYXJ0aXN0YToK
:::ICAgICAgICAgICAgbWV0YSArPSBbJy1tZXRhZGF0YScsICdhcnRpc3Q9JyArIHN0
:::cihhcnRpc3RhKV0KICAgIHdtYSA9IGNhcnBldGEgLyAobGltcGlhcl9ub21icmUo
:::aW5mby5nZXQoJ3RpdGxlJykgb3IgJ2F1ZGlvJykgKyAnLndtYScpCiAgICBjbWQg
:::PSBbc3RyKEZGTVBFRyksICcteScsICctaScsIHN0cih3YXYpLCAnLXZuJywKICAg
:::ICAgICAgICAnLWM6YScsICd3bWF2MicsICctYjphJywgZid7Y2FsaWRhZH1rJ10g
:::KyBtZXRhICsgW3N0cih3bWEpXQogICAgb2sgPSBjb252ZXJ0aXJfZmZtcGVnKAog
:::ICAgICAgIGNtZCwgZidDb252aXJ0aWVuZG8gYSBXTUEgKHdtYXYyIMK3IHtjYWxp
:::ZGFkfSBrYnBzKScsIGNvbGEpCiAgICBpZiBub3Qgb2s6CiAgICAgICAgcmFpc2Ug
:::UnVudGltZUVycm9yKCdGRm1wZWcgbm8gcHVkbyBjcmVhciBlbCBhcmNoaXZvIFdN
:::QS4nKQogICAgYXBsaWNhcl90YWdzKGluZm8sIHdtYSwgbG9nKQogICAgc2h1dGls
:::LnJtdHJlZSh0bXAsIGlnbm9yZV9lcnJvcnM9VHJ1ZSkKICAgIHJldHVybiBpbmZv
:::LCB3bWEKCgojIFBhcsOhbWV0cm9zIG9maWNpYWxlcyBkZWwgcmVwbyBmZGQ0cy9w
:::b3J0YWJsZV9tcDNfcGxheWVyX3ZpZGVvX2NvbnZlcnRlcl90b29scwojICh2aWRl
:::bzJzaGVuanUxOC5zaCk6IE1KUEVHIDE2IGZwcyArIFBDTSAyMjA1MCBIeiwgcm90
:::YWRvcyBwYXJhIGxhIHBhbnRhbGxhCiMgdmVydGljYWwgZGUgMTI4eDE2MCBkZWwg
:::cmVwcm9kdWN0b3Igc2hlaWp1IGRlIDEuOCBwdWxnYWRhcy4KVkZfU0hFSUpVID0g
:::J3NjYWxlPS0yOjEyOCwgY3JvcD0xNjA6MTI4LCB0cmFuc3Bvc2U9MiwgdmZsaXAn
:::CiMgVmFyaWFudGUgYSBwcnVlYmEgZGUgYmFsYXMgcGFyYSB2aWRlb3MgY3VhZHJh
:::ZG9zL3ZlcnRpY2FsZXMgKFNob3J0cyksCiMgZG9uZGUgZWwgcmVjb3J0ZSAxNjA6
:::MTI4IG9yaWdpbmFsIHNlcsOtYSBpbXBvc2libGU6ClZGX1NFR1VSTyA9ICgnc2Nh
:::bGU9MTYwOjEyODpmb3JjZV9vcmlnaW5hbF9hc3BlY3RfcmF0aW89ZGVjcmVhc2Us
:::JwogICAgICAgICAgICAgJ3BhZD0xNjA6MTI4Oihvdy1pdykvMjoob2gtaWgpLzIs
:::dHJhbnNwb3NlPTIsdmZsaXAnKQoKCmRlZiBkZXNjYXJnYXJfYXZpKHVybCwgZGVz
:::dGlubywgY29sYSk6CiAgICAiIiJWaWRlbyBBVkkgcGFyYSBlbCByZXByb2R1Y3Rv
:::ciBzaGVpanUgMS44IiAxMjh4MTYwLiIiIgogICAgZGVmIGxvZyhtLCB0PSdpbmZv
:::Jyk6CiAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICBjYXJwZXRh
:::ID0gZGVzdGlubyAgICAgICAgICAjIHYyLjM6IHNpbiBzdWJjYXJwZXRhcyBwb3Ig
:::Zm9ybWF0bwogICAgdG1wID0gY2FycGV0YSAvICdfdG1wJwogICAgc2h1dGlsLnJt
:::dHJlZSh0bXAsIGlnbm9yZV9lcnJvcnM9VHJ1ZSkKICAgIHRtcC5ta2RpcihwYXJl
:::bnRzPVRydWUsIGV4aXN0X29rPVRydWUpCiAgICBvID0gb3B0c19iYXNlKHRtcCwg
:::Y29sYSkKICAgICMgUGFyYSB1bmEgcGFudGFsbGEgZGUgMTI4eDE2MCBiYXN0YSBj
:::b24gNDgwcDogYWhvcnJhIG11Y2hhIGRlc2NhcmdhLgogICAgb1snZm9ybWF0J10g
:::PSAoJ2Jlc3RbaGVpZ2h0PD00ODBdW2V4dD1tcDRdL2Jlc3RbaGVpZ2h0PD00ODBd
:::LycKICAgICAgICAgICAgICAgICAgICdidipbaGVpZ2h0PD00ODBdK2JhL2InKQog
:::ICAgb1snbWVyZ2Vfb3V0cHV0X2Zvcm1hdCddID0gJ21wNCcKICAgIHdpdGggWVRf
:::RExQLllvdXR1YmVETChvKSBhcyB5ZGw6CiAgICAgICAgaW5mbyA9IHlkbC5leHRy
:::YWN0X2luZm8odXJsLCBkb3dubG9hZD1UcnVlKQogICAgb3JpZ2VuID0gYXJjaGl2
:::b19maW5hbChpbmZvLCB0bXAsICdtcDQnKQogICAgaWYgbm90IG9yaWdlbjoKICAg
:::ICAgICBvcmlnZW4gPSAoYXJjaGl2b19maW5hbChpbmZvLCB0bXAsICdta3YnKQog
:::ICAgICAgICAgICAgICAgICBvciBhcmNoaXZvX2ZpbmFsKGluZm8sIHRtcCwgJ3dl
:::Ym0nKSkKICAgIGlmIG5vdCBvcmlnZW46CiAgICAgICAgcmFpc2UgUnVudGltZUVy
:::cm9yKCdObyBzZSBlbmNvbnRyw7MgZWwgdmlkZW8gZGVzY2FyZ2Fkby4nKQogICAg
:::YXZpID0gY2FycGV0YSAvIChsaW1waWFyX25vbWJyZShpbmZvLmdldCgndGl0bGUn
:::KSBvciAndmlkZW8nKSArICcuYXZpJykKICAgIGJhc2UgPSBbc3RyKEZGTVBFRyks
:::ICcteScsICctaScsIHN0cihvcmlnZW4pLCAnLXInLCAnMTYnLAogICAgICAgICAg
:::ICAnLWFjb2RlYycsICdwY21fczE2bGUnLCAnLWFjJywgJzInLCAnLWFyJywgJzIy
:::MDUwJywKICAgICAgICAgICAgJy1waXhfZm10JywgJ3l1dmo0MjBwJywgJy1jOnYn
:::LCAnbWpwZWcnLCAnLXE6dicsICcyJ10KICAgIG9rID0gY29udmVydGlyX2ZmbXBl
:::ZyhiYXNlICsgWyctdmYnLCBWRl9TSEVJSlUsIHN0cihhdmkpXSwKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAnQ29udmlydGllbmRvIGEgQVZJIDEyOHgxNjAgKHNo
:::ZWlqdSAxLjgiKScsIGNvbGEpCiAgICBpZiBub3Qgb2s6CiAgICAgICAgbG9nKCdW
:::aWRlbyBjb24gcHJvcG9yY2nDs24gbm8gZXN0w6FuZGFyOyAnCiAgICAgICAgICAg
:::ICdyZWludGVudGFuZG8gZW4gbW9kbyBjb21wYXRpYmxlLi4uJywgJ2F2aXNvJykK
:::ICAgICAgICBvayA9IGNvbnZlcnRpcl9mZm1wZWcoYmFzZSArIFsnLXZmJywgVkZf
:::U0VHVVJPLCBzdHIoYXZpKV0sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICdSZWNvbnZpcnRpZW5kbyBhIEFWSSAxMjh4MTYwJywgY29sYSkKICAgIGlmIG5v
:::dCBvazoKICAgICAgICByYWlzZSBSdW50aW1lRXJyb3IoJ0ZGbXBlZyBubyBwdWRv
:::IGNyZWFyIGVsIGFyY2hpdm8gQVZJLicpCiAgICBzaHV0aWwucm10cmVlKHRtcCwg
:::aWdub3JlX2Vycm9ycz1UcnVlKQogICAgcmV0dXJuIGluZm8sIGF2aQoKCiMgLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLSBlc3RpbWFjacOzbgpLQlBTX0VTVElNQURPUyA9IHsKICAg
:::ICdBQUMnOiAxMjgsICAgICAjIHRlY2hvIGRlbCBmb3JtYXRvCiAgICAnV01BJzog
:::MTI4LAogICAgJ1dBVic6IDE0MTEsICAgICMgUENNIDQ0LjEga0h6IMK3IDE2IGJp
:::dCDCtyBlc3TDqXJlbwogICAgJ0ZMQUMnOiA5NTAsICAgICMgdMOtcGljbyBkZSBt
:::w7pzaWNhIHByb2NlZGVudGUgZGUgWW91VHViZQogICAgJ0FWSSc6IDE0OTAsICAg
:::ICMgfjc4NCBrYnBzIE1KUEVHIDE2ZnBzICsgNzA2IGticHMgUENNIDIyMDUwIGVz
:::dMOpcmVvCn0KCgpkZWYgZXN0aW1hcl9ieXRlcyhkdXJhY2lvbl9zLCBmb3JtYXRv
:::LCBjYWxpZGFkLCBlbWJlYmVyKToKICAgICIiIkVzdGltYSBlbCB0YW1hw7FvIGZp
:::bmFsIGVuIGJ5dGVzIChjw6FsY3VsbyBwdXJvLCB0ZXN0ZWFibGUpLiIiIgogICAg
:::aWYgZm9ybWF0byBpbiAoJ01QMycsICdBQUMnLCAnV01BJyk6CiAgICAgICAga2Jw
:::cyA9IGludChyZS5zdWIocidbXjAtOV0nLCAnJywgc3RyKGNhbGlkYWQpKSBvciAw
:::KQogICAgICAgIGlmIG5vdCBrYnBzOgogICAgICAgICAgICBrYnBzID0gS0JQU19F
:::U1RJTUFET1MuZ2V0KGZvcm1hdG8sIDEyOCkKICAgIGVsc2U6CiAgICAgICAga2Jw
:::cyA9IEtCUFNfRVNUSU1BRE9TLmdldChmb3JtYXRvLCAxMjgpCiAgICBleHRyYSA9
:::IDEyMF8wMDAgaWYgKGVtYmViZXIgYW5kIGZvcm1hdG8gaW4gKCdBQUMnLCAnTVAz
:::JywgJ0ZMQUMnKSkgZWxzZSAwCiAgICByZXR1cm4gZHVyYWNpb25fcyAqIGticHMg
:::KiAxMDAwIC8gOCArIGV4dHJhCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGNhbGlkYWQK
:::ZGVmIGNsYXNlX2NhbGlkYWQoZXh0LCBrYnBzKToKICAgICIiIkNsYXNpZmljYSB1
:::biBhcmNoaXZvLiBEZXZ1ZWx2ZSAodGV4dG8sIG5pdmVsKSBjb24gbml2ZWwgMD1v
:::ayAxPW1lZGlhIDI9YmFqYS4iIiIKICAgIGlmIGV4dCA9PSAnLm1wMyc6CiAgICAg
:::ICAgaWYga2JwcyA+PSAzMTU6CiAgICAgICAgICAgIHJldHVybiAnMzIwIGticHMn
:::LCAwCiAgICAgICAgaWYga2JwcyA+PSAyNTA6CiAgICAgICAgICAgIHJldHVybiAn
:::MjU2IGticHMnLCAwCiAgICAgICAgaWYga2JwcyA+PSAxODU6CiAgICAgICAgICAg
:::IHJldHVybiAnMTkyIGticHMnLCAwCiAgICAgICAgaWYga2JwcyA+PSAxMjA6CiAg
:::ICAgICAgICAgIHJldHVybiAnMTI4IGticHMnLCAxCiAgICAgICAgcmV0dXJuIGYn
:::e2ticHN9IGticHMgKGJhamEpJywgMgogICAgaWYgZXh0ID09ICcubTRhJzoKICAg
:::ICAgICBpZiBrYnBzID49IDExNToKICAgICAgICAgICAgcmV0dXJuICdFeGNlbGVu
:::dGUgKEFBQyDiiaQxMjhrKScsIDAKICAgICAgICBpZiBrYnBzID49IDgyOgogICAg
:::ICAgICAgICByZXR1cm4gJzk2IGticHMnLCAxCiAgICAgICAgcmV0dXJuIGYne2ti
:::cHN9IGticHMgKGJhamEpJywgMgogICAgaWYgZXh0ID09ICcud21hJzoKICAgICAg
:::ICBpZiBrYnBzID49IDExNToKICAgICAgICAgICAgcmV0dXJuICcxMjgga2Jwcycs
:::IDAKICAgICAgICBpZiBrYnBzID49IDg4OgogICAgICAgICAgICByZXR1cm4gJzk2
:::IGticHMnLCAxCiAgICAgICAgcmV0dXJuIGYne2ticHN9IGticHMgKGJhamEpJywg
:::MgogICAgaWYgZXh0IGluICgnLmZsYWMnLCAnLndhdicpOgogICAgICAgIHJldHVy
:::biAnU2luIHDDqXJkaWRhJywgMAogICAgaWYgZXh0ID09ICcuYXZpJzoKICAgICAg
:::ICBpZiBrYnBzID49IDEyMDA6CiAgICAgICAgICAgIHJldHVybiBmJ3trYnBzfSBr
:::YnBzIChNSlBFRytQQ00gMTI4eDE2MCknLCAwCiAgICAgICAgcmV0dXJuIGYne2ti
:::cHN9IGticHMgKGFsZ28gYmFqbyknLCAxCiAgICByZXR1cm4gZid7a2Jwc30ga2Jw
:::cycsIDEKCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gdGVtYXMKVEVNQVMgPSB7CiAgICAn
:::T3NjdXJvJzogZGljdCgKICAgICAgICBmb25kbz0nIzFlMWYyMicsIGNhbXBvPScj
:::MmEyZDMxJywgY2FtcG9fYm9yZGU9JyMzYTNlNDQnLAogICAgICAgIHRleHRvPScj
:::ZDhkYWRjJywgdGV4dG8yPScjOWE5ZmE0JywKICAgICAgICBib3Rvbj0nIzNhM2Q0
:::MicsIGJvdG9uX2FjdD0nIzRhNGU1NScsIGJvdG9uX3R4dD0nI2U4ZWFlYycsCiAg
:::ICAgICAgbG9nPScjMTQxNTE4JywgbG9nX3R4dD0nI2NmZDNkNycsIGFjZW50bz0n
:::IzRmOWNmOScsCiAgICAgICAgb2s9JyM3ZWM5N2YnLCBlcnJvcj0nI2U1NzM3Mycs
:::IGF2aXNvPScjZDhiNjRhJywgdHJvdWdoPScjMjYyODJjJywKICAgICAgICBwbGFj
:::ZWhvbGRlcj0nIzc3N2M4MicpLAogICAgJ0NsYXJvJzogZGljdCgKICAgICAgICBm
:::b25kbz0nI2YyZjNmNScsIGNhbXBvPScjZmZmZmZmJywgY2FtcG9fYm9yZGU9JyNj
:::NGM4Y2QnLAogICAgICAgIHRleHRvPScjMjQyNzJhJywgdGV4dG8yPScjNmE3MDc2
:::JywKICAgICAgICBib3Rvbj0nI2UzZTVlOCcsIGJvdG9uX2FjdD0nI2QyZDVkYScs
:::IGJvdG9uX3R4dD0nIzI0MjcyYScsCiAgICAgICAgbG9nPScjZmZmZmZmJywgbG9n
:::X3R4dD0nIzJiMmUzMScsIGFjZW50bz0nIzFhNjZkNicsCiAgICAgICAgb2s9JyMx
:::ZTdlMzQnLCBlcnJvcj0nI2M2MjgyOCcsIGF2aXNvPScjOWE2NzAwJywgdHJvdWdo
:::PScjZGZlMWU0JywKICAgICAgICBwbGFjZWhvbGRlcj0nIzlhYTBhNicpLAp9CgpQ
:::TEFDRUhPTERFUl9VUkwgPSAnaHR0cHM6Ly93d3cueW91dHViZS5jb20vd2F0Y2g/
:::dj0uLi4nCgpGVUVOVEVfVUkgPSAoJ1NlZ29lIFVJJywgOSkKRlVFTlRFX0JUTiA9
:::ICgnU2Vnb2UgVUknLCAxMCkKRlVFTlRFX0JUTl9HID0gKCdTZWdvZSBVSScsIDEx
:::KQpGVUVOVEVfTE9HID0gKCdDb25zb2xhcycsIDEwKQoKCmlmIFRLX09LOgoKICAg
:::IGNsYXNzIEFwcCh0ay5Uayk6CiAgICAgICAgIiIiVmVudGFuYSBwcmluY2lwYWwg
:::KGRpc2XDsW8gZXNwZWpvIGRlbCBtb2NrdXA6IGdydXBvcyBvc2N1cm9zKS4iIiIK
:::CiAgICAgICAgIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0gY29uc3RydWNjacOzbgogICAgICAgIGRlZiBfX2luaXRfXyhz
:::ZWxmKToKICAgICAgICAgICAgaWYgZ2V0YXR0cihzeXMsICdmcm96ZW4nLCBGYWxz
:::ZSk6CiAgICAgICAgICAgICAgICBwYXNzCiAgICAgICAgICAgIHN1cGVyKCkuX19p
:::bml0X18oKQogICAgICAgICAgICBzZWxmLnRpdGxlKCdNdXNpa0FMQU4nKQogICAg
:::ICAgICAgICBzZWxmLmdlb21ldHJ5KCc4NjB4ODQwJykKICAgICAgICAgICAgc2Vs
:::Zi5taW5zaXplKDcwMCwgNjYwKQogICAgICAgICAgICBzZWxmLmNvbGEgPSBxdWV1
:::ZS5RdWV1ZSgpCiAgICAgICAgICAgIHNlbGYuX29jdXBhZG8gPSBGYWxzZQogICAg
:::ICAgICAgICBzZWxmLl9lbl9wbGFjZWhvbGRlciA9IFRydWUKICAgICAgICAgICAg
:::c2VsZi5fdGVtYV9hY3R1YWwgPSBBSlVTVEVTLmdldCgndGVtYScsICdPc2N1cm8n
:::KQogICAgICAgICAgICBpZiBzZWxmLl90ZW1hX2FjdHVhbCBub3QgaW4gVEVNQVM6
:::CiAgICAgICAgICAgICAgICBzZWxmLl90ZW1hX2FjdHVhbCA9ICdPc2N1cm8nCgog
:::ICAgICAgICAgICBzZWxmLl9lc3RpbG8gPSB0dGsuU3R5bGUoc2VsZikKICAgICAg
:::ICAgICAgdHJ5OgogICAgICAgICAgICAgICAgc2VsZi5fZXN0aWxvLnRoZW1lX3Vz
:::ZSgnY2xhbScpCiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAg
:::ICAgICAgICBwYXNzCgogICAgICAgICAgICBzZWxmLl9jb25zdHJ1aXIoKQogICAg
:::ICAgICAgICBzZWxmLl9hcGxpY2FyX3RlbWEoKQogICAgICAgICAgICBzZWxmLl9j
:::b25lY3Rhcl9ldmVudG9zKCkKICAgICAgICAgICAgUkVHSVNUUk8ubG9nID0gbGFt
:::YmRhIG0sIHQ9J2F2aXNvJzogc2VsZi5jb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQog
:::ICAgICAgICAgICBzZWxmLmFmdGVyKDgwLCBzZWxmLl9ib21iZWFyX2NvbGEpCiAg
:::ICAgICAgICAgIHNlbGYuYWZ0ZXIoMTUwLCBzZWxmLl9hcnJhbnF1ZSkKCiAgICAg
:::ICAgZGVmIF9jb25zdHJ1aXIoc2VsZik6CiAgICAgICAgICAgIHNlbGYuX3dnID0g
:::e30gICAgICAgICAjIHJlZmVyZW5jaWFzIHBhcmEgZWwgdGVtYQogICAgICAgICAg
:::ICBzZWxmLl9idG5zID0gW10gICAgICAgIyBib3RvbmVzIHBsYW5vcyAocGFyYSBo
:::b3Zlci90ZW1hKQogICAgICAgICAgICBtYXJjbyA9IHRrLkZyYW1lKHNlbGYpCiAg
:::ICAgICAgICAgIG1hcmNvLnBhY2soZmlsbD0nYm90aCcsIGV4cGFuZD1UcnVlLCBw
:::YWR4PTEwLCBwYWR5PTgpCiAgICAgICAgICAgIHNlbGYuX3dnWydtYXJjbyddID0g
:::bWFyY28KICAgICAgICAgICAgbWFyY28uY29sdW1uY29uZmlndXJlKDAsIHdlaWdo
:::dD0xKQoKICAgICAgICAgICAgIyAtLS0gZmlsYSBUZW1hIC0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAgICAgICBm
:::MCA9IHRrLkZyYW1lKG1hcmNvKQogICAgICAgICAgICBmMC5ncmlkKHJvdz0wLCBj
:::b2x1bW49MCwgc3RpY2t5PSdldycsIHBhZHk9KDAsIDYpKQogICAgICAgICAgICBz
:::ZWxmLl93Z1snZjAnXSA9IGYwCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfdGVt
:::YSddID0gdGsuTGFiZWwoZjAsIHRleHQ9J1RlbWE6JywgZm9udD1GVUVOVEVfVUkp
:::CiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfdGVtYSddLnBhY2soc2lkZT0nbGVm
:::dCcpCiAgICAgICAgICAgIHNlbGYuY21iX3RlbWEgPSB0dGsuQ29tYm9ib3goCiAg
:::ICAgICAgICAgICAgICBmMCwgdmFsdWVzPWxpc3QoVEVNQVMpLCBzdGF0ZT0ncmVh
:::ZG9ubHknLCB3aWR0aD05LAogICAgICAgICAgICAgICAgZm9udD1GVUVOVEVfVUks
:::IHN0eWxlPSdneC5UQ29tYm9ib3gnKQogICAgICAgICAgICBzZWxmLmNtYl90ZW1h
:::LnNldChzZWxmLl90ZW1hX2FjdHVhbCkKICAgICAgICAgICAgc2VsZi5jbWJfdGVt
:::YS5wYWNrKHNpZGU9J2xlZnQnLCBwYWR4PSg4LCAwKSwgaXBhZHk9MikKCiAgICAg
:::ICAgICAgICMgLS0tIGdydXBvOiBVUkwgZGUgWW91VHViZSAtLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KICAgICAgICAgICAgZ3UgPSB0ay5MYWJl
:::bEZyYW1lKG1hcmNvLCB0ZXh0PSdVUkwgZGUgWW91VHViZScsIGZvbnQ9RlVFTlRF
:::X1VJLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVsaWVmPSdzb2xp
:::ZCcsIGJkPTEpCiAgICAgICAgICAgIGd1LmdyaWQocm93PTEsIGNvbHVtbj0wLCBz
:::dGlja3k9J2V3JywgcGFkeT01KQogICAgICAgICAgICBzZWxmLl93Z1snZ3UnXSA9
:::IGd1CiAgICAgICAgICAgIGd1LmNvbHVtbmNvbmZpZ3VyZSgwLCB3ZWlnaHQ9MSkK
:::ICAgICAgICAgICAgc2VsZi5lbnRfdXJsID0gdGsuRW50cnkoZ3UsIGZvbnQ9RlVF
:::TlRFX1VJLCByZWxpZWY9J2ZsYXQnLAogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICBoaWdobGlnaHR0aGlja25lc3M9MSkKICAgICAgICAgICAgc2Vs
:::Zi5lbnRfdXJsLmdyaWQocm93PTAsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFkeD04LCBwYWR5PTgsIGlwYWR5
:::PTUpCiAgICAgICAgICAgIHNlbGYuX3BvbmVyX3BsYWNlaG9sZGVyKCkKICAgICAg
:::ICAgICAgc2VsZi5idG5feCA9IHNlbGYuX2JvdG9uKGd1LCAnWCcsIHNlbGYuX2xp
:::bXBpYXJfdXJsLCB3aWR0aD0zKQogICAgICAgICAgICBzZWxmLmJ0bl94LmdyaWQo
:::cm93PTAsIGNvbHVtbj0xLCBzdGlja3k9J2UnLCBwYWR4PSgwLCA4KSwgaXBhZHk9
:::MykKCiAgICAgICAgICAgICMgLS0tIGdydXBvOiBGb3JtYXRvIHkgY2FsaWRhZCAt
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KICAgICAgICAgICAgZ2Yg
:::PSB0ay5MYWJlbEZyYW1lKG1hcmNvLCB0ZXh0PSdGb3JtYXRvIHkgY2FsaWRhZCcs
:::IGZvbnQ9RlVFTlRFX1VJLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::cmVsaWVmPSdzb2xpZCcsIGJkPTEpCiAgICAgICAgICAgIGdmLmdyaWQocm93PTIs
:::IGNvbHVtbj0wLCBzdGlja3k9J2V3JywgcGFkeT01KQogICAgICAgICAgICBzZWxm
:::Ll93Z1snZ2YnXSA9IGdmCiAgICAgICAgICAgIGdmLmNvbHVtbmNvbmZpZ3VyZSgx
:::LCB3ZWlnaHQ9MSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF9mbXQnXSA9IHRr
:::LkxhYmVsKGdmLCB0ZXh0PSdGb3JtYXRvOicsIGZvbnQ9RlVFTlRFX1VJKQogICAg
:::ICAgICAgICBzZWxmLl93Z1snbGJsX2ZtdCddLmdyaWQocm93PTAsIGNvbHVtbj0w
:::LCBzdGlja3k9J3cnLCBwYWR4PTgsIHBhZHk9NSkKICAgICAgICAgICAgc2VsZi5j
:::bWJfZm9ybWF0byA9IHR0ay5Db21ib2JveCgKICAgICAgICAgICAgICAgIGdmLCB2
:::YWx1ZXM9W2ZbJ3RleHRvJ10gZm9yIGYgaW4gRk9STUFUT1MudmFsdWVzKCldLAog
:::ICAgICAgICAgICAgICAgc3RhdGU9J3JlYWRvbmx5JywgZm9udD1GVUVOVEVfVUks
:::IHN0eWxlPSdneC5UQ29tYm9ib3gnKQogICAgICAgICAgICBzZWxmLmNtYl9mb3Jt
:::YXRvLmdyaWQocm93PTAsIGNvbHVtbj0xLCBzdGlja3k9J2V3JywKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgIHBhZHg9OCwgcGFkeT01LCBpcGFkeT0y
:::KQogICAgICAgICAgICBzZWxmLl93Z1snbGJsX2NhbCddID0gdGsuTGFiZWwoZ2Ys
:::IHRleHQ9J0NhbGlkYWQ6JywgZm9udD1GVUVOVEVfVUkpCiAgICAgICAgICAgIHNl
:::bGYuX3dnWydsYmxfY2FsJ10uZ3JpZChyb3c9MSwgY29sdW1uPTAsIHN0aWNreT0n
:::dycsIHBhZHg9OCwgcGFkeT01KQogICAgICAgICAgICBzZWxmLmNtYl9jYWxpZGFk
:::ID0gdHRrLkNvbWJvYm94KAogICAgICAgICAgICAgICAgZ2YsIHN0YXRlPSdyZWFk
:::b25seScsIGZvbnQ9RlVFTlRFX1VJLCBzdHlsZT0nZ3guVENvbWJvYm94JykKICAg
:::ICAgICAgICAgc2VsZi5jbWJfY2FsaWRhZC5ncmlkKHJvdz0xLCBjb2x1bW49MSwg
:::c3RpY2t5PSdldycsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBw
:::YWR4PTgsIHBhZHk9NSwgaXBhZHk9MikKICAgICAgICAgICAgc2VsZi5fd2dbJ2xi
:::bF9jYXInXSA9IHRrLkxhYmVsKGdmLCB0ZXh0PSdDYXJwZXRhOicsIGZvbnQ9RlVF
:::TlRFX1VJKQogICAgICAgICAgICBzZWxmLl93Z1snbGJsX2NhciddLmdyaWQocm93
:::PTIsIGNvbHVtbj0wLCBzdGlja3k9J3cnLCBwYWR4PTgsIHBhZHk9NSkKICAgICAg
:::ICAgICAgZmMgPSB0ay5GcmFtZShnZikKICAgICAgICAgICAgZmMuZ3JpZChyb3c9
:::MiwgY29sdW1uPTEsIHN0aWNreT0nZXcnLCBwYWR4PTgsIHBhZHk9NSkKICAgICAg
:::ICAgICAgc2VsZi5fd2dbJ2ZjJ10gPSBmYwogICAgICAgICAgICBmYy5jb2x1bW5j
:::b25maWd1cmUoMCwgd2VpZ2h0PTEpCiAgICAgICAgICAgIHNlbGYuZW50X2NhcnBl
:::dGEgPSB0ay5FbnRyeShmYywgZm9udD1GVUVOVEVfVUksIHJlbGllZj0nZmxhdCcs
:::CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBoaWdobGln
:::aHR0aGlja25lc3M9MSkKICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5ncmlk
:::KHJvdz0wLCBjb2x1bW49MCwgc3RpY2t5PSdldycsIGlwYWR5PTQpCiAgICAgICAg
:::ICAgIHNlbGYuZW50X2NhcnBldGEuaW5zZXJ0KDAsIEFKVVNURVNbJ2Rlc3Rpbm8n
:::XSkKICAgICAgICAgICAgc2VsZi5idG5fY2FtYmlhciA9IHNlbGYuX2JvdG9uKGZj
:::LCAnQ2FtYmlhci4uLicsIHNlbGYuX2NhbWJpYXJfY2FycGV0YSkKICAgICAgICAg
:::ICAgc2VsZi5idG5fY2FtYmlhci5ncmlkKHJvdz0wLCBjb2x1bW49MSwgcGFkeD0o
:::OCwgMCksIGlwYWR5PTMpCiAgICAgICAgICAgIHNlbGYuYnRuX2FicmlyID0gc2Vs
:::Zi5fYm90b24oZmMsICdBYnJpcicsIHNlbGYuX2FicmlyX2Rlc3Rpbm8sIHdpZHRo
:::PTUpCiAgICAgICAgICAgIHNlbGYuYnRuX2FicmlyLmdyaWQocm93PTAsIGNvbHVt
:::bj0yLCBwYWR4PSg2LCAwKSwgaXBhZHk9MykKCiAgICAgICAgICAgIHNlbGYudmFy
:::X2VtYmViZXIgPSB0ay5Cb29sZWFuVmFyKHZhbHVlPWJvb2woQUpVU1RFUy5nZXQo
:::J2VtYmViZXInLCBUcnVlKSkpCiAgICAgICAgICAgIHNlbGYuY2hrX2VtYmViZXIg
:::PSB0ay5DaGVja2J1dHRvbigKICAgICAgICAgICAgICAgIGdmLCB0ZXh0PSdFbWJl
:::YmVyIGNhcsOhdHVsYSwgYXJ0aXN0YSB5IMOhbGJ1bScsCiAgICAgICAgICAgICAg
:::ICB2YXJpYWJsZT1zZWxmLnZhcl9lbWJlYmVyLCBmb250PUZVRU5URV9VSSwgYW5j
:::aG9yPSd3JywKICAgICAgICAgICAgICAgIHJlbGllZj0nZmxhdCcsIGhpZ2hsaWdo
:::dHRoaWNrbmVzcz0wLCBiZD0wKQogICAgICAgICAgICBzZWxmLmNoa19lbWJlYmVy
:::LmdyaWQocm93PTMsIGNvbHVtbj0wLCBjb2x1bW5zcGFuPTIsCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICBzdGlja3k9J2V3JywgcGFkeD04LCBwYWR5
:::PSgyLCA2KSkKCiAgICAgICAgICAgICMgLS0tIGdydXBvOiBlc3RpbWFjacOzbiAt
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAg
:::ICAgIGdlID0gdGsuTGFiZWxGcmFtZShtYXJjbywgdGV4dD0nRXN0aW1hY2nDs24n
:::LCBmb250PUZVRU5URV9VSSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::IHJlbGllZj0nc29saWQnLCBiZD0xKQogICAgICAgICAgICBnZS5ncmlkKHJvdz0z
:::LCBjb2x1bW49MCwgc3RpY2t5PSdldycsIHBhZHk9NSkKICAgICAgICAgICAgc2Vs
:::Zi5fd2dbJ2dlJ10gPSBnZQogICAgICAgICAgICBnZS5jb2x1bW5jb25maWd1cmUo
:::MCwgd2VpZ2h0PTEpCiAgICAgICAgICAgIHNlbGYubGJsX2VzdGltYWNpb24gPSB0
:::ay5MYWJlbCgKICAgICAgICAgICAgICAgIGdlLCB0ZXh0PSdJbnRyb2R1Y2UgdW5h
:::IFVSTCB5IHB1bHNhIEVzdGltYXIuJywKICAgICAgICAgICAgICAgIGZvbnQ9RlVF
:::TlRFX1VJLCBhbmNob3I9J3cnKQogICAgICAgICAgICBzZWxmLmxibF9lc3RpbWFj
:::aW9uLmdyaWQocm93PTAsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhZHg9OCwgcGFkeT02KQogICAg
:::ICAgICAgICBzZWxmLmJ0bl9lc3RpbWFyID0gc2VsZi5fYm90b24oZ2UsICdFc3Rp
:::bWFyIHRhbWFubycsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICBzZWxmLl9hY2Npb25fZXN0aW1hcikKICAgICAgICAgICAgc2VsZi5i
:::dG5fZXN0aW1hci5ncmlkKHJvdz0wLCBjb2x1bW49MSwgc3RpY2t5PSdlJywKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhZHg9OCwgaXBhZHk9MykK
:::CiAgICAgICAgICAgICMgLS0tIGJvdG9uZXMgZ3JhbmRlcyAtLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KICAgICAgICAgICAgc2VsZi5i
:::dG5fZGVzY2FyZ2FyID0gc2VsZi5fYm90b24obWFyY28sICdEZXNjYXJnYXIgeSBj
:::b252ZXJ0aXInLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICBzZWxmLl9hY2Npb25fZGVzY2FyZ2FyLAogICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICBmdWVudGU9RlVFTlRFX0JUTl9H
:::LCBhbHRvPTIpCiAgICAgICAgICAgIHNlbGYuYnRuX2Rlc2Nhcmdhci5ncmlkKHJv
:::dz00LCBjb2x1bW49MCwgc3RpY2t5PSdldycsIHBhZHk9KDcsIDQpKQogICAgICAg
:::ICAgICBzZWxmLmJ0bl9jb21wcm9iYXIgPSBzZWxmLl9ib3RvbigKICAgICAgICAg
:::ICAgICAgIG1hcmNvLCAnQ29tcHJvYmFyIGNhbGlkYWQgZGUgbGEgY2FycGV0YScs
:::CiAgICAgICAgICAgICAgICBzZWxmLl9hY2Npb25fY29tcHJvYmFyLCBmdWVudGU9
:::RlVFTlRFX0JUTikKICAgICAgICAgICAgc2VsZi5idG5fY29tcHJvYmFyLmdyaWQo
:::cm93PTUsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgcGFkeT0zKQoKICAgICAgICAg
:::ICAgIyAtLS0gZXN0YWRvICsgYmFycmEgZGUgcHJvZ3Jlc28gLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0KICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRv
:::ID0gdGsuTGFiZWwobWFyY28sIHRleHQ9JycsIGZvbnQ9RlVFTlRFX1VJLAogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBhbmNob3I9J3cnKQog
:::ICAgICAgICAgICBzZWxmLmxibF9lc3RhZG8uZ3JpZChyb3c9NiwgY29sdW1uPTAs
:::IHN0aWNreT0nZXcnLCBwYWR5PSg0LCAwKSkKICAgICAgICAgICAgc2VsZi5iYXJy
:::YSA9IHR0ay5Qcm9ncmVzc2JhcigKICAgICAgICAgICAgICAgIG1hcmNvLCBtYXhp
:::bXVtPTEwMCwgc3R5bGU9J2d4Lkhvcml6b250YWwuVFByb2dyZXNzYmFyJykKICAg
:::ICAgICAgICAgc2VsZi5iYXJyYS5ncmlkKHJvdz03LCBjb2x1bW49MCwgc3RpY2t5
:::PSdldycsIHBhZHk9KDIsIDQpKQoKICAgICAgICAgICAgIyAtLS0gcmVnaXN0cm8g
:::KGxvZykgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0KICAgICAgICAgICAgc2VsZi50eHRfbG9nID0gU2Nyb2xsZWRUZXh0KG1hcmNv
:::LCBmb250PUZVRU5URV9MT0csIGhlaWdodD0xMiwKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgIHJlbGllZj0nZmxhdCcsIGJkPTAsIHdyYXA9
:::J3dvcmQnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::c3RhdGU9J2Rpc2FibGVkJykKICAgICAgICAgICAgc2VsZi50eHRfbG9nLmdyaWQo
:::cm93PTgsIGNvbHVtbj0wLCBzdGlja3k9J25zZXcnKQogICAgICAgICAgICBtYXJj
:::by5yb3djb25maWd1cmUoOCwgd2VpZ2h0PTEpCiAgICAgICAgICAgIGZvciB0YWcs
:::IGNvbmYgaW4gKAogICAgICAgICAgICAgICAgICAgICgnaW5mbycsIHt9KSwKICAg
:::ICAgICAgICAgICAgICAgICAoJ2dyaXMnLCB7fSksCiAgICAgICAgICAgICAgICAg
:::ICAgKCd0aXR1bG8nLCB7fSksCiAgICAgICAgICAgICAgICAgICAgKCdvaycsIHt9
:::KSwKICAgICAgICAgICAgICAgICAgICAoJ2F2aXNvJywge30pLAogICAgICAgICAg
:::ICAgICAgICAgICgnZXJyb3InLCB7fSkpOgogICAgICAgICAgICAgICAgc2VsZi50
:::eHRfbG9nLnRhZ19jb25maWd1cmUodGFnLCBjb25mKQoKICAgICAgICAgICAgIyBz
:::aW5jcm9uaXphciB2YWxvcmVzIGd1YXJkYWRvcwogICAgICAgICAgICBmbXQgPSBB
:::SlVTVEVTLmdldCgnZm9ybWF0bycsICdBQUMnKQogICAgICAgICAgICBpZiBmbXQg
:::bm90IGluIEZPUk1BVE9TOgogICAgICAgICAgICAgICAgZm10ID0gJ0FBQycKICAg
:::ICAgICAgICAgc2VsZi5jbWJfZm9ybWF0by5zZXQoRk9STUFUT1NbZm10XVsndGV4
:::dG8nXSkKICAgICAgICAgICAgc2VsZi5fcmVjYXJnYXJfY2FsaWRhZGVzKGZtdCwg
:::QUpVU1RFUy5nZXQoJ2NhbGlkYWQnKSkKCiAgICAgICAgIyAtLS0tLS0tLS0tLS0t
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
:::cCgpCiAgICAgICAgICAgIGd1YXJkYXJfYWp1c3RlcygpCgogICAgICAgIGRlZiBf
:::b25fY2FycGV0YV9lc2NyaXRhKHNlbGYsIF9lPU5vbmUpOgogICAgICAgICAgICBw
:::ID0gUGF0aChvcy5wYXRoLmV4cGFuZHZhcnMoCiAgICAgICAgICAgICAgICBzZWxm
:::LmVudF9jYXJwZXRhLmdldCgpLnN0cmlwKCkuc3RyaXAoJyInKSkpCiAgICAgICAg
:::ICAgIHRyeToKICAgICAgICAgICAgICAgIHAubWtkaXIocGFyZW50cz1UcnVlLCBl
:::eGlzdF9vaz1UcnVlKQogICAgICAgICAgICAgICAgQUpVU1RFU1snZGVzdGlubydd
:::ID0gc3RyKHApCiAgICAgICAgICAgICAgICBndWFyZGFyX2FqdXN0ZXMoKQogICAg
:::ICAgICAgICBleGNlcHQgT1NFcnJvciBhcyBlOgogICAgICAgICAgICAgICAgc2Vs
:::Zi5fbG9nKGYnTm8gc2UgcHVkbyB1c2FyIGVzYSBjYXJwZXRhOiB7ZX0nLCAnZXJy
:::b3InKQoKICAgICAgICBkZWYgX2NhbWJpYXJfY2FycGV0YShzZWxmKToKICAgICAg
:::ICAgICAgYWN0dWFsID0gc2VsZi5lbnRfY2FycGV0YS5nZXQoKS5zdHJpcCgpIG9y
:::IEFKVVNURVNbJ2Rlc3Rpbm8nXQogICAgICAgICAgICBudWV2YSA9IGZpbGVkaWFs
:::b2cuYXNrZGlyZWN0b3J5KAogICAgICAgICAgICAgICAgdGl0bGU9J0VsaWdlIGxh
:::IGNhcnBldGEgZG9uZGUgZ3VhcmRhciBsYXMgZGVzY2FyZ2FzJywKICAgICAgICAg
:::ICAgICAgIGluaXRpYWxkaXI9YWN0dWFsIGlmIG9zLnBhdGguaXNkaXIoYWN0dWFs
:::KSBlbHNlIHN0cihQYXRoLmhvbWUoKSkpCiAgICAgICAgICAgIGlmIG5vdCBudWV2
:::YToKICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICB0cnk6CiAgICAg
:::ICAgICAgICAgICBQYXRoKG51ZXZhKS5ta2RpcihwYXJlbnRzPVRydWUsIGV4aXN0
:::X29rPVRydWUpCiAgICAgICAgICAgIGV4Y2VwdCBPU0Vycm9yIGFzIGU6CiAgICAg
:::ICAgICAgICAgICBtZXNzYWdlYm94LnNob3dlcnJvcignQ2FycGV0YSBubyB2w6Fs
:::aWRhJywgc3RyKGUpKQogICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAg
:::IHNlbGYuZW50X2NhcnBldGEuZGVsZXRlKDAsICdlbmQnKQogICAgICAgICAgICBz
:::ZWxmLmVudF9jYXJwZXRhLmluc2VydCgwLCBudWV2YSkKICAgICAgICAgICAgQUpV
:::U1RFU1snZGVzdGlubyddID0gbnVldmEKICAgICAgICAgICAgZ3VhcmRhcl9hanVz
:::dGVzKCkKICAgICAgICAgICAgc2VsZi5fbG9nKCdDYXJwZXRhIGRlIGd1YXJkYWRv
:::OiAnICsgbnVldmEsICdncmlzJykKCiAgICAgICAgZGVmIF9hYnJpcl9kZXN0aW5v
:::KHNlbGYpOgogICAgICAgICAgICBwID0gUGF0aChvcy5wYXRoLmV4cGFuZHZhcnMo
:::CiAgICAgICAgICAgICAgICBzZWxmLmVudF9jYXJwZXRhLmdldCgpLnN0cmlwKCku
:::c3RyaXAoJyInKSkpCiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHAu
:::bWtkaXIocGFyZW50cz1UcnVlLCBleGlzdF9vaz1UcnVlKQogICAgICAgICAgICBl
:::eGNlcHQgT1NFcnJvcjoKICAgICAgICAgICAgICAgIHBhc3MKICAgICAgICAgICAg
:::YWJyaXJfY2FycGV0YShwKQoKICAgICAgICBkZWYgX2FsX2NlcnJhcihzZWxmKToK
:::ICAgICAgICAgICAgaWYgc2VsZi5fb2N1cGFkbyBhbmQgbm90IG1lc3NhZ2Vib3gu
:::YXNrb2tjYW5jZWwoCiAgICAgICAgICAgICAgICAgICAgJ1NhbGlyJywgJ0hheSB1
:::bmEgdGFyZWEgZW4gY3Vyc28uICcKICAgICAgICAgICAgICAgICAgICAnwr9TZWd1
:::cm8gcXVlIHF1aWVyZXMgc2FsaXI/Jyk6CiAgICAgICAgICAgICAgICByZXR1cm4K
:::ICAgICAgICAgICAgc2VsZi5kZXN0cm95KCkKCiAgICAgICAgIyAtLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gcmVnaXN0cm8g
:::KGxvZykKICAgICAgICBkZWYgX2xvZyhzZWxmLCBtc2csIHRhZz0naW5mbycpOgog
:::ICAgICAgICAgICBzZWxmLnR4dF9sb2cuY29uZmlndXJlKHN0YXRlPSdub3JtYWwn
:::KQogICAgICAgICAgICBuX2xpbmVhcyA9IGludChzZWxmLnR4dF9sb2cuaW5kZXgo
:::J2VuZC0xYycpLnNwbGl0KCcuJylbMF0pCiAgICAgICAgICAgIGlmIG5fbGluZWFz
:::ID4gOTAwOgogICAgICAgICAgICAgICAgc2VsZi50eHRfbG9nLmRlbGV0ZSgnMS4w
:::JywgJzIwMC4wJykKICAgICAgICAgICAgc2VsZi50eHRfbG9nLmluc2VydCgnZW5k
:::Jywgc3RyKG1zZykgKyAnXG4nLCB0YWcpCiAgICAgICAgICAgIHNlbGYudHh0X2xv
:::Zy5zZWUoJ2VuZCcpCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5jb25maWd1cmUo
:::c3RhdGU9J2Rpc2FibGVkJykKCiAgICAgICAgZGVmIF9saW1waWFyX2xvZyhzZWxm
:::KToKICAgICAgICAgICAgc2VsZi50eHRfbG9nLmNvbmZpZ3VyZShzdGF0ZT0nbm9y
:::bWFsJykKICAgICAgICAgICAgc2VsZi50eHRfbG9nLmRlbGV0ZSgnMS4wJywgJ2Vu
:::ZCcpCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5jb25maWd1cmUoc3RhdGU9J2Rp
:::c2FibGVkJykKCiAgICAgICAgZGVmIF9ib21iZWFyX2NvbGEoc2VsZik6CiAgICAg
:::ICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHdoaWxlIFRydWU6CiAgICAgICAg
:::ICAgICAgICAgICAgZXYgPSBzZWxmLmNvbGEuZ2V0X25vd2FpdCgpCiAgICAgICAg
:::ICAgICAgICAgICAgdGlwbyA9IGV2WzBdCiAgICAgICAgICAgICAgICAgICAgaWYg
:::dGlwbyA9PSAnbG9nJzoKICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5fbG9n
:::KGV2WzFdLCBldlsyXSkKICAgICAgICAgICAgICAgICAgICBlbGlmIHRpcG8gPT0g
:::J3Byb2cnOgogICAgICAgICAgICAgICAgICAgICAgICBwY3QsIHRleHRvID0gZXZb
:::MV0sIGV2WzJdCiAgICAgICAgICAgICAgICAgICAgICAgIGlmIHBjdCBpcyBOb25l
:::OgogICAgICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5iYXJyYS5zdG9wKCkK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYmFycmEuY29uZmlndXJl
:::KG1vZGU9J2luZGV0ZXJtaW5hdGUnKQogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgc2VsZi5iYXJyYS5zdGFydCg2MCkKICAgICAgICAgICAgICAgICAgICAgICAg
:::ZWxzZToKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYmFycmEuc3Rv
:::cCgpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzZWxmLmJhcnJhLmNvbmZp
:::Z3VyZShtb2RlPSdkZXRlcm1pbmF0ZScpCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICBzZWxmLmJhcnJhLmNvbmZpZ3VyZSh2YWx1ZT1tYXgoMCwgbWluKDEwMCwg
:::cGN0KSkpCiAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYubGJsX2VzdGFkby5j
:::b25maWd1cmUodGV4dD10ZXh0bykKICAgICAgICAgICAgICAgICAgICBlbGlmIHRp
:::cG8gPT0gJ2VzdGltYWNpb24nOgogICAgICAgICAgICAgICAgICAgICAgICBzZWxm
:::LmxibF9lc3RpbWFjaW9uLmNvbmZpZ3VyZSgKICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgIHRleHQ9ZXZbMV0sIGZnPVRFTUFTW3NlbGYuX3RlbWFfYWN0dWFsXVsn
:::YWNlbnRvJ10pCiAgICAgICAgICAgICAgICAgICAgZWxpZiB0aXBvID09ICdmaW4n
:::OgogICAgICAgICAgICAgICAgICAgICAgICBzZWxmLl9maW5fdGFyZWEoZXZbMV0s
:::IGV2WzJdLCBldlszXSBpZiBsZW4oZXYpID4gMyBlbHNlICcnKQogICAgICAgICAg
:::ICBleGNlcHQgcXVldWUuRW1wdHk6CiAgICAgICAgICAgICAgICBwYXNzCiAgICAg
:::ICAgICAgIHNlbGYuYWZ0ZXIoODAsIHNlbGYuX2JvbWJlYXJfY29sYSkKCiAgICAg
:::ICAgIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0gdGFyZWFzCiAgICAgICAgZGVmIF9oYWJpbGl0YXJfYWNjaW9uZXMoc2Vs
:::Ziwgb24pOgogICAgICAgICAgICBlc3RhZG8gPSAnbm9ybWFsJyBpZiBvbiBlbHNl
:::ICdkaXNhYmxlZCcKICAgICAgICAgICAgZm9yIGIgaW4gKHNlbGYuYnRuX2Rlc2Nh
:::cmdhciwgc2VsZi5idG5fY29tcHJvYmFyLAogICAgICAgICAgICAgICAgICAgICAg
:::c2VsZi5idG5fZXN0aW1hciwgc2VsZi5idG5fY2FtYmlhciwgc2VsZi5idG5fYWJy
:::aXIsCiAgICAgICAgICAgICAgICAgICAgICBzZWxmLmJ0bl94KToKICAgICAgICAg
:::ICAgICAgIGIuY29uZmlndXJlKHN0YXRlPWVzdGFkbywgY3Vyc29yPSdoYW5kMicg
:::aWYgb24gZWxzZSAnYXJyb3cnKQoKICAgICAgICBkZWYgX2luaWNpYXIoc2VsZiwg
:::b2JqZXRpdm8sIGNmZywgdGV4dG8pOgogICAgICAgICAgICBpZiBzZWxmLl9vY3Vw
:::YWRvOgogICAgICAgICAgICAgICAgc2VsZi5fbG9nKCdZYSBoYXkgdW5hIHRhcmVh
:::IGVuIGN1cnNvOyBlc3BlcmEgYSBxdWUgdGVybWluZS4nLAogICAgICAgICAgICAg
:::ICAgICAgICAgICAgICdhdmlzbycpCiAgICAgICAgICAgICAgICByZXR1cm4gRmFs
:::c2UKICAgICAgICAgICAgc2VsZi5fb2N1cGFkbyA9IFRydWUKICAgICAgICAgICAg
:::c2VsZi5faGFiaWxpdGFyX2FjY2lvbmVzKEZhbHNlKQogICAgICAgICAgICBzZWxm
:::LmxibF9lc3RhZG8uY29uZmlndXJlKHRleHQ9dGV4dG8pCiAgICAgICAgICAgIHRo
:::cmVhZGluZy5UaHJlYWQodGFyZ2V0PW9iamV0aXZvLCBhcmdzPShjZmcsKSwgZGFl
:::bW9uPVRydWUpLnN0YXJ0KCkKICAgICAgICAgICAgcmV0dXJuIFRydWUKCiAgICAg
:::ICAgZGVmIF9maW5fdGFyZWEoc2VsZiwgdGlwbywgb2ssIG1lbnNhamU9JycpOgog
:::ICAgICAgICAgICBzZWxmLl9vY3VwYWRvID0gRmFsc2UKICAgICAgICAgICAgc2Vs
:::Zi5faGFiaWxpdGFyX2FjY2lvbmVzKFRydWUpCiAgICAgICAgICAgIHNlbGYuYmFy
:::cmEuc3RvcCgpCiAgICAgICAgICAgIHNlbGYuYmFycmEuY29uZmlndXJlKG1vZGU9
:::J2RldGVybWluYXRlJykKICAgICAgICAgICAgc2VsZi5iYXJyYS5jb25maWd1cmUo
:::dmFsdWU9MCkKICAgICAgICAgICAgaWYgdGlwbyA9PSAnZGVzY2FyZ2EnIGFuZCBv
:::azoKICAgICAgICAgICAgICAgIHNlbGYubGJsX2VzdGFkby5jb25maWd1cmUodGV4
:::dD0nTGlzdG8uJykKICAgICAgICAgICAgICAgICMgTGEgZGVzY2FyZ2EgZnVlIGJp
:::ZW46IHNlIGxpbXBpYSBsYSBVUkwgcGFyYSBsYSBzaWd1aWVudGUuCiAgICAgICAg
:::ICAgICAgICBzZWxmLl9yZXNldF91cmwoKQogICAgICAgICAgICBlbGlmIG5vdCBv
:::azoKICAgICAgICAgICAgICAgIHNlbGYubGJsX2VzdGFkby5jb25maWd1cmUodGV4
:::dD0nVGVybWluYWRvIGNvbiBlcnJvcmVzLicpCiAgICAgICAgICAgICAgICBpZiB0
:::aXBvID09ICdkZXNjYXJnYSc6CiAgICAgICAgICAgICAgICAgICAgbWVzc2FnZWJv
:::eC5zaG93ZXJyb3IoCiAgICAgICAgICAgICAgICAgICAgICAgICdFcnJvcicsIG1l
:::bnNhamUgb3IgJ05vIHNlIHB1ZG8gY29tcGxldGFyIGxhIHRhcmVhLiAnCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICdSZXZpc2EgZWwgcmVnaXN0cm8gcGFyYSBtw6Fz
:::IGRldGFsbGVzLicpCgogICAgICAgIGRlZiBfdXJsX3ZhbGlkYShzZWxmKToKICAg
:::ICAgICAgICAgaWYgc2VsZi5fZW5fcGxhY2Vob2xkZXI6CiAgICAgICAgICAgICAg
:::ICBzZWxmLl9sb2coJ1ByaW1lcm8gcGVnYSBsYSBVUkwgZGVsIHZpZGVvIGRlIFlv
:::dVR1YmUuJywgJ2F2aXNvJykKICAgICAgICAgICAgICAgIHJldHVybiBOb25lCiAg
:::ICAgICAgICAgIHUgPSBzZWxmLmVudF91cmwuZ2V0KCkuc3RyaXAoKS5zdHJpcCgn
:::IicpLnN0cmlwKCInIikKICAgICAgICAgICAgaWYgbm90IHU6CiAgICAgICAgICAg
:::ICAgICBzZWxmLl9sb2coJ0xhIFVSTCBlc3TDoSB2YWPDrWEuJywgJ2F2aXNvJykK
:::ICAgICAgICAgICAgICAgIHJldHVybiBOb25lCiAgICAgICAgICAgIGlmIG5vdCBy
:::ZS5tYXRjaChyJ15odHRwcz86Ly8nLCB1LCByZS5JKToKICAgICAgICAgICAgICAg
:::IGlmIHJlLm1hdGNoKHInXnd3d1wuJywgdSwgcmUuSSk6CiAgICAgICAgICAgICAg
:::ICAgICAgdSA9ICdodHRwczovLycgKyB1CiAgICAgICAgICAgICAgICBlbHNlOgog
:::ICAgICAgICAgICAgICAgICAgIHNlbGYuX2xvZygnRXNvIG5vIHBhcmVjZSB1bmEg
:::VVJMIChkZWJlIGVtcGV6YXIgcG9yICcKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgJ2h0dHA6Ly8gbyBodHRwczovLyknLCAnZXJyb3InKQogICAgICAgICAg
:::ICAgICAgICAgIHJldHVybiBOb25lCiAgICAgICAgICAgICMgT0pPOiBhcXXDrSBO
:::TyBzZSBxdWl0YSBsaXN0PTsgc2kgbGEgVVJMIHRyYWUgdW5hIHBsYXlsaXN0LAog
:::ICAgICAgICAgICAjIF9hY2Npb25fZGVzY2FyZ2FyIHByZWd1bnRhcsOhIHF1w6kg
:::aGFjZXIgY29uIGVsbGEuCiAgICAgICAgICAgIHJldHVybiB1CgogICAgICAgIGRl
:::ZiBfYWNjaW9uX2VzdGltYXIoc2VsZik6CiAgICAgICAgICAgIHVybCA9IHNlbGYu
:::X3VybF92YWxpZGEoKQogICAgICAgICAgICBpZiBub3QgdXJsOgogICAgICAgICAg
:::ICAgICAgcmV0dXJuCiAgICAgICAgICAgIHNlbGYuX2d1YXJkYXIoKQogICAgICAg
:::ICAgICBjZmcgPSB7J3VybCc6IHVybH0KICAgICAgICAgICAgc2VsZi5faW5pY2lh
:::cihzZWxmLl9oaWxvX2VzdGltYXIsIGNmZywgJ0VzdGltYW5kbyB0YW1hw7FvLi4u
:::JykKICAgICAgICAgICAgc2VsZi5sYmxfZXN0aW1hY2lvbi5jb25maWd1cmUoCiAg
:::ICAgICAgICAgICAgICB0ZXh0PSdDYWxjdWxhbmRvLi4uJywgZmc9VEVNQVNbc2Vs
:::Zi5fdGVtYV9hY3R1YWxdWyd0ZXh0bzInXSkKCiAgICAgICAgZGVmIF9hY2Npb25f
:::ZGVzY2FyZ2FyKHNlbGYpOgogICAgICAgICAgICB1cmwgPSBzZWxmLl91cmxfdmFs
:::aWRhKCkKICAgICAgICAgICAgaWYgbm90IHVybDoKICAgICAgICAgICAgICAgIHJl
:::dHVybgogICAgICAgICAgICBzZWxmLl9ndWFyZGFyKCkKICAgICAgICAgICAgcGxh
:::eWxpc3QgPSBGYWxzZQogICAgICAgICAgICBpZiBlc191cmxfcGxheWxpc3QodXJs
:::KToKICAgICAgICAgICAgICAgIHIgPSBtZXNzYWdlYm94LmFza3llc25vY2FuY2Vs
:::KAogICAgICAgICAgICAgICAgICAgICdNdXNpa0FMQU4g4oCUIGxpc3RhIGRlIHJl
:::cHJvZHVjY2nDs24nLAogICAgICAgICAgICAgICAgICAgICdFc3RhIFVSTCBwZXJ0
:::ZW5lY2UgYSB1bmEgbGlzdGEgZGUgcmVwcm9kdWNjacOzbi5cblxuJwogICAgICAg
:::ICAgICAgICAgICAgICcgIFPDjSAg4oaSICBkZXNjYXJnYXIgbGEgcGxheWxpc3Qg
:::Y29tcGxldGFcbicKICAgICAgICAgICAgICAgICAgICAnICAgICAgICAgKHBhdXNh
:::IGRlIDIgcyBlbnRyZSBjYW5jaW9uZXMpXG4nCiAgICAgICAgICAgICAgICAgICAg
:::JyAgTk8gIOKGkiAgZGVzY2FyZ2FyIHNvbG8gZXN0YSBjYW5jacOzblxuJwogICAg
:::ICAgICAgICAgICAgICAgICcgIENhbmNlbGFyICDihpIgIG5vIGRlc2NhcmdhciBu
:::YWRhJykKICAgICAgICAgICAgICAgIGlmIHIgaXMgTm9uZToKICAgICAgICAgICAg
:::ICAgICAgICBzZWxmLl9sb2coJ0Rlc2NhcmdhIGNhbmNlbGFkYS4nLCAnZ3Jpcycp
:::CiAgICAgICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgICAgICBpZiBy
:::OgogICAgICAgICAgICAgICAgICAgIHBsYXlsaXN0ID0gVHJ1ZQogICAgICAgICAg
:::ICAgICAgZWxpZiBlc19zb2xvX2xpc3RhKHVybCk6CiAgICAgICAgICAgICAgICAg
:::ICAgIyBFcyB1bmEgcGxheWxpc3QgcHVyYTogbm8gaGF5ICJ1bmEgY2FuY2nDs24i
:::IGFow60KICAgICAgICAgICAgICAgICAgICBzZWxmLl9sb2coJ0VzYSBVUkwgZXMg
:::dW5hIGxpc3RhIGNvbXBsZXRhOyBzZSBkZXNjYXJnYXLDoSAnCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICdlbnRlcmEuJywgJ2F2aXNvJykKICAgICAgICAg
:::ICAgICAgICAgICBwbGF5bGlzdCA9IFRydWUKICAgICAgICAgICAgY2ZnID0geyd1
:::cmwnOiB1cmwsICdwbGF5bGlzdCc6IHBsYXlsaXN0fQogICAgICAgICAgICBzZWxm
:::Ll9pbmljaWFyKHNlbGYuX2hpbG9fZGVzY2FyZ2FyLCBjZmcsICdEZXNjYXJnYW5k
:::by4uLicpCgogICAgICAgIGRlZiBfYWNjaW9uX2NvbXByb2JhcihzZWxmKToKICAg
:::ICAgICAgICAgc2VsZi5fZ3VhcmRhcigpCiAgICAgICAgICAgIHNlbGYuX2luaWNp
:::YXIoc2VsZi5faGlsb19jb21wcm9iYXIsIHt9LAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICdDb21wcm9iYW5kbyBsYSBjYXJwZXRhLi4uJykKCiAgICAgICAgZGVm
:::IF9hY2Npb25fYWN0dWFsaXphcihzZWxmKToKICAgICAgICAgICAgaWYgbm90IFlU
:::X0RMUDoKICAgICAgICAgICAgICAgIHNlbGYuX2xvZygneXQtZGxwIG5vIGVzdMOh
:::IGluc3RhbGFkbzsgZWplY3V0YSAnCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::J0Rlc2NhcmdhZG9yTXVzaWNhLmJhdC4nLCAnZXJyb3InKQogICAgICAgICAgICAg
:::ICAgcmV0dXJuCiAgICAgICAgICAgIHNlbGYuX2luaWNpYXIoc2VsZi5faGlsb19h
:::Y3R1YWxpemFyLCB7fSwgJ0FjdHVhbGl6YW5kbyB5dC1kbHAuLi4nKQoKICAgICAg
:::ICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLSBoaWxvcwogICAgICAgIGRlZiBfaGlsb19lc3RpbWFyKHNlbGYsIGNmZyk6
:::CiAgICAgICAgICAgIGNvbGEgPSBzZWxmLmNvbGEKCiAgICAgICAgICAgIGRlZiBs
:::b2cobSwgdD0naW5mbycpOgogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdsb2cn
:::LCBtLCB0KSkKCiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIGlmIFlU
:::X0RMUCBpcyBOb25lOgogICAgICAgICAgICAgICAgICAgIGxvZygneXQtZGxwIG5v
:::IGVzdMOhIGluc3RhbGFkby4gRWplY3V0YSAnCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICdEZXNjYXJnYWRvck11c2ljYS5iYXQgcGFyYSBpbnN0YWxhcmxvLicsICdl
:::cnJvcicpCiAgICAgICAgICAgICAgICAgICAgY29sYS5wdXQoKCdlc3RpbWFjaW9u
:::JywgJ3l0LWRscCBubyBkaXNwb25pYmxlJykpCiAgICAgICAgICAgICAgICAgICAg
:::cmV0dXJuCiAgICAgICAgICAgICAgICBsb2coJ09idGVuaWVuZG8gaW5mb3JtYWNp
:::w7NuIGRlbCB2aWRlby4uLicsICdncmlzJykKICAgICAgICAgICAgICAgIG8gPSB7
:::J3F1aWV0JzogVHJ1ZSwgJ25vX3dhcm5pbmdzJzogVHJ1ZSwgJ25vcGxheWxpc3Qn
:::OiBUcnVlLAogICAgICAgICAgICAgICAgICAgICAnc29ja2V0X3RpbWVvdXQnOiAz
:::MCwgJ2xvZ2dlcic6IFJFR0lTVFJPfQogICAgICAgICAgICAgICAgaWYgZXNfdXJs
:::X3BsYXlsaXN0KGNmZ1sndXJsJ10pOgogICAgICAgICAgICAgICAgICAgIGxvZygn
:::KGxhIFVSTCBjb250aWVuZSB1bmEgcGxheWxpc3Q6IGxhIGVzdGltYWNpw7NuIGVz
:::ICcKICAgICAgICAgICAgICAgICAgICAgICAgJ3NvbG8gZGVsIHZpZGVvIHBlZ2Fk
:::byknLCAnZ3JpcycpCiAgICAgICAgICAgICAgICB3aXRoIFlUX0RMUC5Zb3V0dWJl
:::REwobykgYXMgeWRsOgogICAgICAgICAgICAgICAgICAgIGluZm8gPSB5ZGwuZXh0
:::cmFjdF9pbmZvKGNmZ1sndXJsJ10sIGRvd25sb2FkPUZhbHNlKQogICAgICAgICAg
:::ICAgICAgZHVyID0gaW5mby5nZXQoJ2R1cmF0aW9uJykKICAgICAgICAgICAgICAg
:::IGlmIG5vdCBkdXI6CiAgICAgICAgICAgICAgICAgICAgbG9nKCdObyBzZSBwdWRv
:::IG9idGVuZXIgbGEgZHVyYWNpw7NuIGRlbCB2aWRlby4nLCAnZXJyb3InKQogICAg
:::ICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZXN0aW1hY2lvbicsICdTaW4gZGF0
:::b3MgcGFyYSBlc3RpbWFyJykpCiAgICAgICAgICAgICAgICAgICAgcmV0dXJuCiAg
:::ICAgICAgICAgICAgICBjbGF2ZSA9IHNlbGYuX2ZtdF9hY3R1YWxfc29sbyhBSlVT
:::VEVTLmdldCgnZm9ybWF0bycsICdBQUMnKSkKICAgICAgICAgICAgICAgIHRhbSA9
:::IGVzdGltYXJfYnl0ZXMoZHVyLCBjbGF2ZSwgQUpVU1RFUy5nZXQoJ2NhbGlkYWQn
:::KSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYm9vbChBSlVT
:::VEVTLmdldCgnZW1iZWJlcicsIFRydWUpKSkKICAgICAgICAgICAgICAgIHRpdHVs
:::byA9IHN0cihpbmZvLmdldCgndGl0bGUnKSBvciAnJylbOjcwXQogICAgICAgICAg
:::ICAgICAgaWYgdGl0dWxvOgogICAgICAgICAgICAgICAgICAgIGxvZygn4pmqICcg
:::KyB0aXR1bG8sICd0aXR1bG8nKQogICAgICAgICAgICAgICAgdGV4dG8gPSAoZid+
:::e3RhbSAvIDEwNDg1NzY6LjFmfSBNQiDCtyAnCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICBmJ2R1cmFjacOzbiB7Zm10X3RpZW0oZHVyKX0gwrcgJwogICAgICAgICAg
:::ICAgICAgICAgICAgICAgZid7Y2xhdmV9IHtBSlVTVEVTLmdldCgiY2FsaWRhZCIs
:::ICIiKX0nLnJzdHJpcCgpKQogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdlc3Rp
:::bWFjaW9uJywgdGV4dG8pKQogICAgICAgICAgICAgICAgbG9nKCdFc3RpbWFjacOz
:::bjogJyArIHRleHRvLCAnb2snKQogICAgICAgICAgICAgICAgbG9nKCdFbCB0YW1h
:::w7FvIHJlYWwgcHVlZGUgdmFyaWFyIGFsZ28gc2Vnw7puIGxhIGZ1ZW50ZS4nLAog
:::ICAgICAgICAgICAgICAgICAgICdncmlzJykKICAgICAgICAgICAgZXhjZXB0IEV4
:::Y2VwdGlvbiBhcyBlOgogICAgICAgICAgICAgICAgbG9nKGYnTm8gc2UgcHVkbyBl
:::c3RpbWFyOiB7c2VsZi5fbXNnX2Vycm9yKGUpfScsICdlcnJvcicpCiAgICAgICAg
:::ICAgICAgICBjb2xhLnB1dCgoJ2VzdGltYWNpb24nLCAnTm8gc2UgcHVkbyBlc3Rp
:::bWFyJykpCiAgICAgICAgICAgIGZpbmFsbHk6CiAgICAgICAgICAgICAgICBjb2xh
:::LnB1dCgoJ2ZpbicsICdlc3RpbWFjaW9uJywgVHJ1ZSwgJycpKQoKICAgICAgICBk
:::ZWYgX2ZtdF9hY3R1YWxfc29sbyhzZWxmLCBjbGF2ZSk6CiAgICAgICAgICAgIHJl
:::dHVybiBjbGF2ZSBpZiBjbGF2ZSBpbiBGT1JNQVRPUyBlbHNlICdBQUMnCgogICAg
:::ICAgIGRlZiBfZGVzY2FyZ2FyX3VuYShzZWxmLCB1cmwsIGNsYXZlLCBjYWxpZGFk
:::X2FyZywgZW1iZWJlciwgZGVzdGlubywKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgY29sYSk6CiAgICAgICAgICAgICIiIkRlc2NhcmdhIHkgY29udmllcnRlIFVO
:::QSBVUkwuIERldnVlbHZlIGVsIFBhdGggZmluYWwgbyBOb25lLiIiIgogICAgICAg
:::ICAgICBpZiBjbGF2ZSA9PSAnV01BJzoKICAgICAgICAgICAgICAgIHJldHVybiBk
:::ZXNjYXJnYXJfd21hKHVybCwgY2FsaWRhZF9hcmcsIGRlc3Rpbm8sIGVtYmViZXIs
:::CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xhKVsxXQog
:::ICAgICAgICAgICBpZiBjbGF2ZSA9PSAnQVZJJzoKICAgICAgICAgICAgICAgIHJl
:::dHVybiBkZXNjYXJnYXJfYXZpKHVybCwgZGVzdGlubywgY29sYSlbMV0KICAgICAg
:::ICAgICAgcmV0dXJuIGRlc2Nhcmdhcl9hdWRpbyh1cmwsIGNsYXZlLCBjYWxpZGFk
:::X2FyZywgZGVzdGlubywgZW1iZWJlciwKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICBjb2xhKVsxXQoKICAgICAgICBkZWYgX2Rlc2Nhcmdhcl9wbGF5
:::bGlzdChzZWxmLCB1cmwsIGNsYXZlLCBjYWxpZGFkX2FyZywgZW1iZWJlciwKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICBkZXN0aW5vLCBjb2xhKToKICAg
:::ICAgICAgICAgIiIiQmFqYSB1bmEgbGlzdGEgZW50ZXJhLCBjb24gMiBzIGRlIGRl
:::c2NhbnNvIGVudHJlIGNhbmNpb25lcwogICAgICAgICAgICBwYXJhIG5vIHNhdHVy
:::YXIgYSBZb3VUdWJlLiBEZXZ1ZWx2ZSAoZGVzY2FyZ2FkYXMsIHRvdGFsKS4iIiIK
:::ICAgICAgICAgICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAgICAgICAgICAgICAg
:::ICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgICAgICAgICAgbG9nKCdMZXll
:::bmRvIGxhIGxpc3RhIGRlIHJlcHJvZHVjY2nDs24uLi4nLCAnZ3JpcycpCiAgICAg
:::ICAgICAgIG8gPSB7J3F1aWV0JzogVHJ1ZSwgJ25vX3dhcm5pbmdzJzogVHJ1ZSwK
:::ICAgICAgICAgICAgICAgICAnZXh0cmFjdF9mbGF0JzogJ2luX3BsYXlsaXN0Jywg
:::J3NvY2tldF90aW1lb3V0JzogMzAsCiAgICAgICAgICAgICAgICAgJ2xvZ2dlcic6
:::IFJFR0lTVFJPfQogICAgICAgICAgICB3aXRoIFlUX0RMUC5Zb3V0dWJlREwobykg
:::YXMgeWRsOgogICAgICAgICAgICAgICAgaW5mbyA9IHlkbC5leHRyYWN0X2luZm8o
:::dXJsLCBkb3dubG9hZD1GYWxzZSkKICAgICAgICAgICAgZW50cmFkYXMgPSBsaXN0
:::KGluZm8uZ2V0KCdlbnRyaWVzJykgb3IgW10pCiAgICAgICAgICAgIGlmIG5vdCBl
:::bnRyYWRhczoKICAgICAgICAgICAgICAgIGxvZygnTm8gc2UgdmlvIG5pbmd1bmEg
:::Y2FuY2nDs24gZW4gbGEgbGlzdGE7IHNlIGludGVudGEgJwogICAgICAgICAgICAg
:::ICAgICAgICdjb21vIHZpZGVvIHN1ZWx0by4nLCAnYXZpc28nKQogICAgICAgICAg
:::ICAgICAgYXJjaGl2byA9IHNlbGYuX2Rlc2Nhcmdhcl91bmEoc2luX3BsYXlsaXN0
:::KHVybClbMF0sIGNsYXZlLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgY2FsaWRhZF9hcmcsIGVtYmViZXIsIGRlc3Rpbm8sCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xh
:::KQogICAgICAgICAgICAgICAgcmV0dXJuICgxIGlmIGFyY2hpdm8gZWxzZSAwKSwg
:::MQogICAgICAgICAgICB0aXR1bG9fcGwgPSBzdHIoaW5mby5nZXQoJ3RpdGxlJykg
:::b3IgJ2xpc3RhJylbOjcwXQogICAgICAgICAgICB0b3RhbCA9IGxlbihlbnRyYWRh
:::cykKICAgICAgICAgICAgbG9nKGYnUGxheWxpc3Qgwqt7dGl0dWxvX3BsfcK7IOKA
:::lCB7dG90YWx9IHbDrWRlbyhzKS4nLCAndGl0dWxvJykKICAgICAgICAgICAgb2th
:::cyA9IDAKICAgICAgICAgICAgZmFsbG9zID0gW10KICAgICAgICAgICAgZm9yIGks
:::IGUgaW4gZW51bWVyYXRlKGVudHJhZGFzKToKICAgICAgICAgICAgICAgIHUgPSBz
:::dHIoZS5nZXQoJ3dlYnBhZ2VfdXJsJykgb3IgZS5nZXQoJ3VybCcpIG9yICcnKQog
:::ICAgICAgICAgICAgICAgaWYgdSBhbmQgbm90IHUuc3RhcnRzd2l0aCgnaHR0cCcp
:::OgogICAgICAgICAgICAgICAgICAgIHUgPSAnaHR0cHM6Ly93d3cueW91dHViZS5j
:::b20vd2F0Y2g/dj0nICsgdQogICAgICAgICAgICAgICAgaWYgbm90IHUgYW5kIGUu
:::Z2V0KCdpZCcpOgogICAgICAgICAgICAgICAgICAgIHUgPSAnaHR0cHM6Ly93d3cu
:::eW91dHViZS5jb20vd2F0Y2g/dj0nICsgc3RyKGVbJ2lkJ10pCiAgICAgICAgICAg
:::ICAgICB0aXQgPSBzdHIoZS5nZXQoJ3RpdGxlJykgb3IgdSBvciAnPycpWzo3MF0K
:::ICAgICAgICAgICAgICAgIGlmIGk6CiAgICAgICAgICAgICAgICAgICAgdGltZS5z
:::bGVlcCgyKSAgICMgZGVzY2Fuc28gZW50cmUgY2FuY2lvbmVzCiAgICAgICAgICAg
:::ICAgICBsb2coZidbe2kgKyAxfS97dG90YWx9XSDimaoge3RpdH0nLCAndGl0dWxv
:::JykKICAgICAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgICAgICBhcmNo
:::aXZvID0gc2VsZi5fZGVzY2FyZ2FyX3VuYSh1LCBjbGF2ZSwgY2FsaWRhZF9hcmcs
:::CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgZW1iZWJlciwgZGVzdGlubywgY29sYSkKICAgICAgICAgICAgICAgIGV4Y2Vw
:::dCBFeGNlcHRpb24gYXMgZTI6CiAgICAgICAgICAgICAgICAgICAgYXJjaGl2byA9
:::IE5vbmUKICAgICAgICAgICAgICAgICAgICBsb2coZifinJYgW3tpICsgMX0ve3Rv
:::dGFsfV0gRmFsbMOzOiB7c2VsZi5fbXNnX2Vycm9yKGUyKX0nLAogICAgICAgICAg
:::ICAgICAgICAgICAgICAnZXJyb3InKQogICAgICAgICAgICAgICAgaWYgYXJjaGl2
:::byBhbmQgUGF0aChhcmNoaXZvKS5leGlzdHMoKToKICAgICAgICAgICAgICAgICAg
:::ICB0cnk6CiAgICAgICAgICAgICAgICAgICAgICAgIHRhbSA9IGZtdF90YW0oUGF0
:::aChhcmNoaXZvKS5zdGF0KCkuc3Rfc2l6ZSkKICAgICAgICAgICAgICAgICAgICBl
:::eGNlcHQgT1NFcnJvcjoKICAgICAgICAgICAgICAgICAgICAgICAgdGFtID0gJz8n
:::CiAgICAgICAgICAgICAgICAgICAgbG9nKGYnICAg4pyUIHtQYXRoKGFyY2hpdm8p
:::Lm5hbWV9ICAoe3RhbX0pJywgJ29rJykKICAgICAgICAgICAgICAgICAgICBva2Fz
:::ICs9IDEKICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICAgICAg
:::ZmFsbG9zLmFwcGVuZCh0aXQpCiAgICAgICAgICAgIGxvZyhmJ1BsYXlsaXN0IHRl
:::cm1pbmFkYToge29rYXN9IGRlIHt0b3RhbH0gZGVzY2FyZ2FkYShzKS4nLAogICAg
:::ICAgICAgICAgICAgJ29rJyBpZiBub3QgZmFsbG9zIGVsc2UgJ2F2aXNvJykKICAg
:::ICAgICAgICAgaWYgZmFsbG9zOgogICAgICAgICAgICAgICAgbG9nKCdTaW4gZGVz
:::Y2FyZ2FyOiAnCiAgICAgICAgICAgICAgICAgICAgKyAnIMK3ICcuam9pbihmWzo0
:::MF0gZm9yIGYgaW4gZmFsbG9zWzo4XSkKICAgICAgICAgICAgICAgICAgICArICgn
:::Li4uJyBpZiBsZW4oZmFsbG9zKSA+IDggZWxzZSAnJyksICdncmlzJykKICAgICAg
:::ICAgICAgcmV0dXJuIG9rYXMsIHRvdGFsCgogICAgICAgIGRlZiBfaGlsb19kZXNj
:::YXJnYXIoc2VsZiwgY2ZnKToKICAgICAgICAgICAgY29sYSA9IHNlbGYuY29sYQoK
:::ICAgICAgICAgICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAgICAgICAgICAgICAg
:::ICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgICAgICAgICAgdXJsID0gY2Zn
:::Wyd1cmwnXQogICAgICAgICAgICBjbGF2ZSA9IHNlbGYuX2ZtdF9hY3R1YWxfc29s
:::byhBSlVTVEVTLmdldCgnZm9ybWF0bycsICdBQUMnKSkKICAgICAgICAgICAgY2Fs
:::aWRhZCA9IEFKVVNURVMuZ2V0KCdjYWxpZGFkJywgJzEyOGsnKQogICAgICAgICAg
:::ICBlbWJlYmVyID0gYm9vbChBSlVTVEVTLmdldCgnZW1iZWJlcicsIFRydWUpKQog
:::ICAgICAgICAgICBkZXN0aW5vID0gUGF0aChvcy5wYXRoLmV4cGFuZHZhcnMoCiAg
:::ICAgICAgICAgICAgICBzdHIoQUpVU1RFUy5nZXQoJ2Rlc3Rpbm8nLCBfZGVzdGlu
:::b19wb3JfZGVmZWN0bygpKSkpKQogICAgICAgICAgICB0cnk6CiAgICAgICAgICAg
:::ICAgICBpZiBZVF9ETFAgaXMgTm9uZToKICAgICAgICAgICAgICAgICAgICBsb2co
:::J3l0LWRscCBubyBlc3TDoSBpbnN0YWxhZG8uIEVqZWN1dGEgJwogICAgICAgICAg
:::ICAgICAgICAgICAgICAnRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0IHBhcmEgaW5zdGFs
:::YXJsby4nLCAnZXJyb3InKQogICAgICAgICAgICAgICAgICAgIGNvbGEucHV0KCgn
:::ZmluJywgJ2Rlc2NhcmdhJywgRmFsc2UsCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICd5dC1kbHAgbm8gZXN0w6EgaW5zdGFsYWRvLicpKQogICAgICAgICAg
:::ICAgICAgICAgIHJldHVybgogICAgICAgICAgICAgICAgZGVzdGluby5ta2Rpcihw
:::YXJlbnRzPVRydWUsIGV4aXN0X29rPVRydWUpCiAgICAgICAgICAgICAgICBpZiBj
:::bGF2ZSBpbiAoJ0ZMQUMnLCAnV0FWJyk6CiAgICAgICAgICAgICAgICAgICAgY2Fs
:::aWRhZF9hcmcgPSAnMCcKICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAg
:::ICAgICAgICAgY2FsaWRhZF9hcmcgPSAocmUuc3ViKHInW14wLTldJywgJycsIHN0
:::cihjYWxpZGFkKSkKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBv
:::ciAoJzEyOCcgaWYgY2xhdmUgPT0gJ0FBQycgZWxzZSAnMzIwJykpCiAgICAgICAg
:::ICAgICAgICBpZiBjZmcuZ2V0KCdwbGF5bGlzdCcpOgogICAgICAgICAgICAgICAg
:::ICAgIG9rYXMsIHRvdGFsID0gc2VsZi5fZGVzY2FyZ2FyX3BsYXlsaXN0KAogICAg
:::ICAgICAgICAgICAgICAgICAgICB1cmwsIGNsYXZlLCBjYWxpZGFkX2FyZywgZW1i
:::ZWJlciwgZGVzdGlubywgY29sYSkKICAgICAgICAgICAgICAgICAgICBpZiBva2Fz
:::IGFuZCBva2FzID09IHRvdGFsOgogICAgICAgICAgICAgICAgICAgICAgICBsb2co
:::ZidDYXJwZXRhOiB7ZGVzdGlub30nLCAnZ3JpcycpCiAgICAgICAgICAgICAgICAg
:::ICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2Rlc2NhcmdhJywgVHJ1ZSwgJycpKQog
:::ICAgICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICAgICAgICAg
:::IGNvbGEucHV0KCgKICAgICAgICAgICAgICAgICAgICAgICAgICAgICdmaW4nLCAn
:::ZGVzY2FyZ2EnLCBGYWxzZSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGYn
:::U2UgZGVzY2FyZ2Fyb24ge29rYXN9IGRlIHt0b3RhbH0gZGUgbGEgJwogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgJ3BsYXlsaXN0LiBMYSBVUkwgbm8gc2UgaGEg
:::Ym9ycmFkbyBwb3Igc2kgJwogICAgICAgICAgICAgICAgICAgICAgICAgICAgJ3F1
:::aWVyZXMgcmVpbnRlbnRhcmxvLicpKQogICAgICAgICAgICAgICAgICAgIHJldHVy
:::bgogICAgICAgICAgICAgICAgYXJjaGl2byA9IHNlbGYuX2Rlc2Nhcmdhcl91bmEo
:::c2luX3BsYXlsaXN0KHVybClbMF0sIGNsYXZlLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgY2FsaWRhZF9hcmcsIGVtYmViZXIs
:::IGRlc3Rpbm8sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICBjb2xhKQogICAgICAgICAgICAgICAgaWYgYXJjaGl2byBhbmQgUGF0
:::aChhcmNoaXZvKS5leGlzdHMoKToKICAgICAgICAgICAgICAgICAgICBhcmNoaXZv
:::ID0gUGF0aChhcmNoaXZvKQogICAgICAgICAgICAgICAgICAgIHRyeToKICAgICAg
:::ICAgICAgICAgICAgICAgICAgdGFtID0gZm10X3RhbShhcmNoaXZvLnN0YXQoKS5z
:::dF9zaXplKQogICAgICAgICAgICAgICAgICAgIGV4Y2VwdCBPU0Vycm9yOgogICAg
:::ICAgICAgICAgICAgICAgICAgICB0YW0gPSAnPycKICAgICAgICAgICAgICAgICAg
:::ICBsb2coZifinJQgwqFMaXN0byEgIHthcmNoaXZvLm5hbWV9ICAoe3RhbX0pJywg
:::J29rJykKICAgICAgICAgICAgICAgICAgICBsb2coZidDYXJwZXRhOiB7YXJjaGl2
:::by5wYXJlbnR9JywgJ2dyaXMnKQogICAgICAgICAgICAgICAgICAgIGNvbGEucHV0
:::KCgnZmluJywgJ2Rlc2NhcmdhJywgVHJ1ZSwgJycpKQogICAgICAgICAgICAgICAg
:::ZWxzZToKICAgICAgICAgICAgICAgICAgICBsb2coJ0VsIGFyY2hpdm8gZmluYWwg
:::bm8gYXBhcmVjacOzIGRvbmRlIHNlIGVzcGVyYWJhLicsCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICdlcnJvcicpCiAgICAgICAgICAgICAgICAgICAgY29sYS5wdXQo
:::KCdmaW4nLCAnZGVzY2FyZ2EnLCBGYWxzZSwgJycpKQogICAgICAgICAgICBleGNl
:::cHQgRXhjZXB0aW9uIGFzIGU6CiAgICAgICAgICAgICAgICBub21icmVfZXhjID0g
:::dHlwZShlKS5fX25hbWVfXwogICAgICAgICAgICAgICAgaWYgbm9tYnJlX2V4YyA9
:::PSAnRG93bmxvYWRFcnJvcic6CiAgICAgICAgICAgICAgICAgICAgbGluZWFzID0g
:::W2wgZm9yIGwgaW4gc3RyKGUpLnN0cmlwKCkuc3BsaXRsaW5lcygpIGlmIGwuc3Ry
:::aXAoKV0KICAgICAgICAgICAgICAgICAgICBtc2cgPSBsaW5lYXNbMF1bOjMwMF0g
:::aWYgbGluZWFzIGVsc2UgJ2Vycm9yIGRlc2Nvbm9jaWRvJwogICAgICAgICAgICAg
:::ICAgICAgIGxvZygn4pyWIE5vIHNlIHB1ZG8gZGVzY2FyZ2FyOiAnICsgbXNnLCAn
:::ZXJyb3InKQogICAgICAgICAgICAgICAgICAgIGxvZygnQ29uc2Vqb3M6IHJldmlz
:::YSBsYSBVUkwgeSB0dSBjb25leGnDs247IHNpIFlvdVR1YmUgJwogICAgICAgICAg
:::ICAgICAgICAgICAgICAnY2FtYmnDsyBhbGdvLCBwdWxzYSBDdHJsK1UgKGFjdHVh
:::bGl6YXIgeXQtZGxwKSB5ICcKICAgICAgICAgICAgICAgICAgICAgICAgJ3JlaW50
:::ZW50YS4nLCAnZ3JpcycpCiAgICAgICAgICAgICAgICBlbHNlOgogICAgICAgICAg
:::ICAgICAgICAgIGxvZyhmJ+KcliBFcnJvciBpbmVzcGVyYWRvICh7bm9tYnJlX2V4
:::Y30pOiB7ZX0nLCAnZXJyb3InKQogICAgICAgICAgICAgICAgICAgIHRiID0gdHJh
:::Y2ViYWNrLmZvcm1hdF9leGMobGltaXQ9MykKICAgICAgICAgICAgICAgICAgICB0
:::cnk6CiAgICAgICAgICAgICAgICAgICAgICAgIHdpdGggb3BlbihMT0dfRVJST1JF
:::UywgJ2EnLCBlbmNvZGluZz0ndXRmLTgnKSBhcyBmaDoKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIGZoLndyaXRlKHRiICsgJ1xuJykKICAgICAgICAgICAgICAg
:::ICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICAgICAgICAgICAgICBw
:::YXNzCiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdkZXNjYXJnYScs
:::IEZhbHNlLAogICAgICAgICAgICAgICAgICAgICAgICAgICdObyBzZSBwdWRvIGNv
:::bXBsZXRhciBsYSBkZXNjYXJnYS4gUmV2aXNhIGVsICcKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAncmVnaXN0cm8gcGFyYSBtw6FzIGRldGFsbGVzLicpKQoKICAg
:::ICAgICBkZWYgX2hpbG9fY29tcHJvYmFyKHNlbGYsIGNmZyk6CiAgICAgICAgICAg
:::IGNvbGEgPSBzZWxmLmNvbGEKCiAgICAgICAgICAgIGRlZiBsb2cobSwgdD0naW5m
:::bycpOgogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAg
:::ICAgICAgICAgIGNhcnBldGEgPSBQYXRoKG9zLnBhdGguZXhwYW5kdmFycygKICAg
:::ICAgICAgICAgICAgIHN0cihBSlVTVEVTLmdldCgnZGVzdGlubycsIF9kZXN0aW5v
:::X3Bvcl9kZWZlY3RvKCkpKSkpCiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAg
:::ICAgIGlmIG5vdCBjYXJwZXRhLmlzX2RpcigpOgogICAgICAgICAgICAgICAgICAg
:::IGxvZyhmJ0xhIGNhcnBldGEgdG9kYXbDrWEgbm8gZXhpc3RlOiB7Y2FycGV0YX0n
:::LCAnYXZpc28nKQogICAgICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywg
:::J2NvbXByb2JhY2lvbicsIFRydWUsICcnKSkKICAgICAgICAgICAgICAgICAgICBy
:::ZXR1cm4KICAgICAgICAgICAgICAgIGlmIEZGUFJPQkUgaXMgTm9uZToKICAgICAg
:::ICAgICAgICAgICAgICBsb2coJ2ZmcHJvYmUgbm8gZXN0w6EgZGlzcG9uaWJsZSAo
:::dmllbmUgY29uIEZGbXBlZykuICcKICAgICAgICAgICAgICAgICAgICAgICAgJ0Vq
:::ZWN1dGEgRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0IHBhcmEgaW5zdGFsYXJsby4nLAog
:::ICAgICAgICAgICAgICAgICAgICAgICAnZXJyb3InKQogICAgICAgICAgICAgICAg
:::ICAgIGNvbGEucHV0KCgnZmluJywgJ2NvbXByb2JhY2lvbicsIFRydWUsICcnKSkK
:::ICAgICAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgICAgIGV4dHMg
:::PSAoJy5tNGEnLCAnLm1wMycsICcuZmxhYycsICcud2F2JywgJy53bWEnLCAnLmF2
:::aScpCiAgICAgICAgICAgICAgICBhcmNoaXZvcyA9IFtwIGZvciBwIGluIHNvcnRl
:::ZChjYXJwZXRhLnJnbG9iKCcqJykpCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICBpZiBwLmlzX2ZpbGUoKSBhbmQgcC5zdWZmaXgubG93ZXIoKSBpbiBleHRzCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBhbmQgJ190bXAnIG5vdCBpbiBwLnBh
:::cnRzXQogICAgICAgICAgICAgICAgbG9nKGYnQ29tcHJvYmFuZG8ge2xlbihhcmNo
:::aXZvcyl9IGFyY2hpdm8ocykgZW4gJwogICAgICAgICAgICAgICAgICAgIGYne2Nh
:::cnBldGF9IC4uLicsICd0aXR1bG8nKQogICAgICAgICAgICAgICAgaWYgbm90IGFy
:::Y2hpdm9zOgogICAgICAgICAgICAgICAgICAgIGxvZygnTm8gaGF5IGFyY2hpdm9z
:::IGRlIGF1ZGlvIG8gdmlkZW8gdG9kYXbDrWEuJywgJ2dyaXMnKQogICAgICAgICAg
:::ICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2NvbXByb2JhY2lvbicsIFRydWUs
:::ICcnKSkKICAgICAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgICAg
:::IHRvdGFsID0gMAogICAgICAgICAgICAgICAgYmFqYXMgPSAwCiAgICAgICAgICAg
:::ICAgICBmb3IgcCBpbiBhcmNoaXZvczoKICAgICAgICAgICAgICAgICAgICB0cnk6
:::CiAgICAgICAgICAgICAgICAgICAgICAgIHIgPSBzdWJwcm9jZXNzLnJ1bigKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgIFtzdHIoRkZQUk9CRSksICctdicsICdl
:::cnJvcicsICctc2hvd19lbnRyaWVzJywKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAnZm9ybWF0PWJpdF9yYXRlLGR1cmF0aW9uLHNpemUnLCAnLW9mJywgJ2pz
:::b24nLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0cihwKV0sCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICBzdGRvdXQ9c3VicHJvY2Vzcy5QSVBFLCBz
:::dGRlcnI9c3VicHJvY2Vzcy5QSVBFLAogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgdGV4dD1UcnVlLCBlbmNvZGluZz0ndXRmLTgnLCBlcnJvcnM9J3JlcGxhY2Un
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgdGltZW91dD0zMCkKICAgICAg
:::ICAgICAgICAgICAgICAgICAgZGF0b3MgPSBqc29uLmxvYWRzKHIuc3Rkb3V0IG9y
:::ICd7fScpLmdldCgnZm9ybWF0Jywge30pCiAgICAgICAgICAgICAgICAgICAgICAg
:::IGticHMgPSBpbnQoZmxvYXQoZGF0b3MuZ2V0KCdiaXRfcmF0ZScpIG9yIDApIC8g
:::MTAwMCkKICAgICAgICAgICAgICAgICAgICAgICAgZHVyID0gZmxvYXQoZGF0b3Mu
:::Z2V0KCdkdXJhdGlvbicpIG9yIDApCiAgICAgICAgICAgICAgICAgICAgICAgIHRh
:::bSA9IGludChmbG9hdChkYXRvcy5nZXQoJ3NpemUnKSBvciAwKSkKICAgICAgICAg
:::ICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICAgICAgICAg
:::ICAgICBsb2coZifCtyB7cC5uYW1lWzo2MF19IOKAlCBubyBzZSBwdWRvIGxlZXIn
:::LCAnYXZpc28nKQogICAgICAgICAgICAgICAgICAgICAgICBjb250aW51ZQogICAg
:::ICAgICAgICAgICAgICAgIHRvdGFsICs9IHRhbQogICAgICAgICAgICAgICAgICAg
:::IHRleHRvLCBuaXZlbCA9IGNsYXNlX2NhbGlkYWQocC5zdWZmaXgubG93ZXIoKSwg
:::a2JwcykKICAgICAgICAgICAgICAgICAgICBpZiBuaXZlbCA9PSAyOgogICAgICAg
:::ICAgICAgICAgICAgICAgICBiYWphcyArPSAxCiAgICAgICAgICAgICAgICAgICAg
:::dGFnID0gKCdvaycgaWYgbml2ZWwgPT0gMAogICAgICAgICAgICAgICAgICAgICAg
:::ICAgICBlbHNlICgnYXZpc28nIGlmIG5pdmVsID09IDEgZWxzZSAnZXJyb3InKSkK
:::ICAgICAgICAgICAgICAgICAgICBsb2coZifCtyB7cC5uYW1lWzo1OF19IOKAlCB7
:::dGV4dG99IMK3IHtmbXRfdGllbShkdXIpfSDCtyAnCiAgICAgICAgICAgICAgICAg
:::ICAgICAgIGYne2ZtdF90YW0odGFtKX0nLCB0YWcpCiAgICAgICAgICAgICAgICBs
:::b2coZidSZXN1bHRhZG86IHtsZW4oYXJjaGl2b3MpfSBhcmNoaXZvKHMpIMK3ICcK
:::ICAgICAgICAgICAgICAgICAgICBmJ3tmbXRfdGFtKHRvdGFsKX0gZW4gdG90YWwg
:::wrcge2JhamFzfSBjb24gY2FsaWRhZCBiYWphJywKICAgICAgICAgICAgICAgICAg
:::ICAndGl0dWxvJykKICAgICAgICAgICAgICAgIGlmIGJhamFzOgogICAgICAgICAg
:::ICAgICAgICAgIGxvZygnQ29uc2VqbzogbG9zIGFyY2hpdm9zIG1hcmNhZG9zIGVu
:::IHJvam8gc2UgcHVlZGVuICcKICAgICAgICAgICAgICAgICAgICAgICAgJ3ZvbHZl
:::ciBhIGRlc2NhcmdhciBjb24gbcOhcyBiaXRyYXRlLicsICdncmlzJykKICAgICAg
:::ICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBlOgogICAgICAgICAgICAgICAgbG9n
:::KGYnRXJyb3IgYWwgY29tcHJvYmFyIGxhIGNhcnBldGE6IHtlfScsICdlcnJvcicp
:::CiAgICAgICAgICAgIGZpbmFsbHk6CiAgICAgICAgICAgICAgICBjb2xhLnB1dCgo
:::J2ZpbicsICdjb21wcm9iYWNpb24nLCBUcnVlLCAnJykpCgogICAgICAgIGRlZiBf
:::aGlsb19hY3R1YWxpemFyKHNlbGYsIGNmZyk6CiAgICAgICAgICAgIGNvbGEgPSBz
:::ZWxmLmNvbGEKCiAgICAgICAgICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgogICAg
:::ICAgICAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICAgICAgICAg
:::IHRyeToKICAgICAgICAgICAgICAgIGxvZygnQWN0dWFsaXphbmRvIHl0LWRscCB5
:::IG11dGFnZW4uLi4nLCAnZ3JpcycpCiAgICAgICAgICAgICAgICBwID0gc3VicHJv
:::Y2Vzcy5ydW4oCiAgICAgICAgICAgICAgICAgICAgW3N5cy5leGVjdXRhYmxlLCAn
:::LW0nLCAncGlwJywgJ2luc3RhbGwnLCAnLS11cGdyYWRlJywKICAgICAgICAgICAg
:::ICAgICAgICAgJy0tbm8td2Fybi1zY3JpcHQtbG9jYXRpb24nLCAneXQtZGxwJywg
:::J211dGFnZW4nXSwKICAgICAgICAgICAgICAgICAgICBzdGRvdXQ9c3VicHJvY2Vz
:::cy5QSVBFLCBzdGRlcnI9c3VicHJvY2Vzcy5TVERPVVQsCiAgICAgICAgICAgICAg
:::ICAgICAgdGV4dD1UcnVlLCBlbmNvZGluZz0ndXRmLTgnLCBlcnJvcnM9J3JlcGxh
:::Y2UnLCB0aW1lb3V0PTYwMCkKICAgICAgICAgICAgICAgIGZvciBsbiBpbiAocC5z
:::dGRvdXQgb3IgJycpLnN0cmlwKCkuc3BsaXRsaW5lcygpWy02Ol06CiAgICAgICAg
:::ICAgICAgICAgICAgbG9nKCcgICAnICsgbG5bOjE2MF0sICdncmlzJykKICAgICAg
:::ICAgICAgICAgIGlmIHAucmV0dXJuY29kZSA9PSAwOgogICAgICAgICAgICAgICAg
:::ICAgIGxvZygneXQtZGxwIGFjdHVhbGl6YWRvLiBSZWluaWNpYSBsYSBhcGxpY2Fj
:::acOzbiBwYXJhICcKICAgICAgICAgICAgICAgICAgICAgICAgJ3VzYXIgbGEgdmVy
:::c2nDs24gbnVldmEuJywgJ29rJykKICAgICAgICAgICAgICAgIGVsc2U6CiAgICAg
:::ICAgICAgICAgICAgICAgbG9nKCdMYSBhY3R1YWxpemFjacOzbiBmYWxsw7MgKMK/
:::c2luIGludGVybmV0PykuJywgJ2Vycm9yJykKICAgICAgICAgICAgZXhjZXB0IEV4
:::Y2VwdGlvbiBhcyBlOgogICAgICAgICAgICAgICAgbG9nKGYnTm8gc2UgcHVkbyBl
:::amVjdXRhciBwaXA6IHtlfScsICdlcnJvcicpCiAgICAgICAgICAgIGZpbmFsbHk6
:::CiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdhY3R1YWxpemFjaW9u
:::JywgVHJ1ZSwgJycpKQoKICAgICAgICBkZWYgX21zZ19lcnJvcihzZWxmLCBlKToK
:::ICAgICAgICAgICAgbGluZWFzID0gW2wgZm9yIGwgaW4gc3RyKGUpLnN0cmlwKCku
:::c3BsaXRsaW5lcygpIGlmIGwuc3RyaXAoKV0KICAgICAgICAgICAgcmV0dXJuIChs
:::aW5lYXNbMF1bOjI1MF0gaWYgbGluZWFzCiAgICAgICAgICAgICAgICAgICAgZWxz
:::ZSBmJ3t0eXBlKGUpLl9fbmFtZV9ffTogc2luIGRldGFsbGVzJykKCiAgICAgICAg
:::IyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0gYXJyYW5xdWUKICAgICAgICBkZWYgX2FycmFucXVlKHNlbGYpOgogICAgICAg
:::ICAgICBzZWxmLl9sb2coZidNdXNpa0FMQU4gdntBUFBfVn0nLCAndGl0dWxvJykK
:::ICAgICAgICAgICAgc2VsZi5fbG9nKCdDdHJsK1U6IGFjdHVhbGl6YXIgeXQtZGxw
:::IMK3IEN0cmwrTDogbGltcGlhciByZWdpc3RybycsCiAgICAgICAgICAgICAgICAg
:::ICAgICAnZ3JpcycpCiAgICAgICAgICAgIHRocmVhZGluZy5UaHJlYWQodGFyZ2V0
:::PXNlbGYuX2hpbG9fdmVyc2lvbiwgZGFlbW9uPVRydWUpLnN0YXJ0KCkKCiAgICAg
:::ICAgZGVmIF9oaWxvX3ZlcnNpb24oc2VsZik6CiAgICAgICAgICAgIGNvbGEgPSBz
:::ZWxmLmNvbGEKCiAgICAgICAgICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgogICAg
:::ICAgICAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICAgICAgICAg
:::IGlmIFlUX0RMUCBpcyBOb25lOgogICAgICAgICAgICAgICAgbG9nKCd5dC1kbHAg
:::bm8gZXN0w6EgaW5zdGFsYWRvLiBFamVjdXRhICcKICAgICAgICAgICAgICAgICAg
:::ICAnRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0IHBhcmEgaW5zdGFsYXJsby4nLCAnZXJy
:::b3InKQogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAndmVyc2lvbics
:::IFRydWUsICcnKSkKICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICB0
:::cnk6CiAgICAgICAgICAgICAgICBpbnN0YWxhZGEgPSBZVF9ETFAudmVyc2lvbi5f
:::X3ZlcnNpb25fXwogICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAg
:::ICAgICAgICAgaW5zdGFsYWRhID0gJz8nCiAgICAgICAgICAgIHVsdGltYSA9IE5v
:::bmUKICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgd2l0aCB1cmxvcGVu
:::KCdodHRwczovL3B5cGkub3JnL3B5cGkveXQtZGxwL2pzb24nLCB0aW1lb3V0PTEy
:::KSBhcyByOgogICAgICAgICAgICAgICAgICAgIHVsdGltYSA9IGpzb24ubG9hZHMo
:::ci5yZWFkKCkuZGVjb2RlKCd1dGYtOCcpKVsnaW5mbyddWyd2ZXJzaW9uJ10KICAg
:::ICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgICAgIHVsdGlt
:::YSA9IE5vbmUKICAgICAgICAgICAgaWYgdWx0aW1hIGlzIE5vbmU6CiAgICAgICAg
:::ICAgICAgICBsb2coZid5dC1kbHA6IHZlcnNpw7NuIHtpbnN0YWxhZGF9ICcKICAg
:::ICAgICAgICAgICAgICAgICAnKG5vIHNlIHB1ZG8gY29tcHJvYmFyIHNpIGhheSBu
:::b3ZlZGFkZXMpLicsICdncmlzJykKICAgICAgICAgICAgZWxpZiBzdHIodWx0aW1h
:::KSA9PSBzdHIoaW5zdGFsYWRhKToKICAgICAgICAgICAgICAgIGxvZyhmJ3l0LWRs
:::cDogZW4gbGEgdWx0aW1hIHZlcnNpb24gKHtpbnN0YWxhZGF9KS4nLCAnaW5mbycp
:::CiAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICBsb2coZid5dC1kbHA6
:::IGhheSB2ZXJzaW9uIG51ZXZhICh7dWx0aW1hfSk7IGluc3RhbGFkYTogJwogICAg
:::ICAgICAgICAgICAgICAgIGYne2luc3RhbGFkYX0uIFB1bHNhIEN0cmwrVSBwYXJh
:::IGFjdHVhbGl6YXIuJywgJ2F2aXNvJykKICAgICAgICAgICAgaWYgRkZNUEVHIGlz
:::IE5vbmU6CiAgICAgICAgICAgICAgICBsb2coJ0ZGbXBlZzogTk8gRU5DT05UUkFE
:::TyDigJQgZWplY3V0YSBEZXNjYXJnYWRvck11c2ljYS5iYXQgJwogICAgICAgICAg
:::ICAgICAgICAgICdwYXJhIGluc3RhbGFybG8uJywgJ2Vycm9yJykKICAgICAgICAg
:::ICAgZWxzZToKICAgICAgICAgICAgICAgIGxvZyhmJ0ZGbXBlZzogT0sgKHtGRk1Q
:::RUd9KScsICdncmlzJykKICAgICAgICAgICAgbG9nKCdDYXJwZXRhIGRlIGd1YXJk
:::YWRvOiAnICsgc3RyKEFKVVNURVMuZ2V0KCdkZXN0aW5vJykpLCAnZ3JpcycpCiAg
:::ICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ3ZlcnNpb24nLCBUcnVlLCAnJykp
:::CgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tIG1haW4KZGVmIG1haW4oKToKICAgIF9yZWNv
:::bmZpZ3VyYXJfc2FsaWRhKCkKICAgIGlmIG5vdCBUS19PSzoKICAgICAgICBwcmlu
:::dCgnRXN0YSBhcGxpY2FjacOzbiBuZWNlc2l0YSBUa2ludGVyIChpbnRlcmZheiBn
:::csOhZmljYSkuJykKICAgICAgICBwcmludCgnRWwgUHl0aG9uIGFjdHVhbCBubyBs
:::byBpbmNsdXllLicpCiAgICAgICAgcHJpbnQoJ1Z1ZWx2ZSBhIGVqZWN1dGFyIERl
:::c2NhcmdhZG9yTXVzaWNhLmJhdCBwYXJhIGluc3RhbGFyIGVsICcKICAgICAgICAg
:::ICAgICAnUHl0aG9uIGFkZWN1YWRvLicpCiAgICAgICAgcmV0dXJuIDEKICAgIGNv
:::bXByb2Jhcl9lbnRvcm5vKCkKICAgIGFwcCA9IEFwcCgpCiAgICBhcHAubWFpbmxv
:::b3AoKQogICAgcmV0dXJuIDAKCgppZiBfX25hbWVfXyA9PSAnX19tYWluX18nOgog
:::ICAgdHJ5OgogICAgICAgIHN5cy5leGl0KG1haW4oKSkKICAgIGV4Y2VwdCBTeXN0
:::ZW1FeGl0OgogICAgICAgIHJhaXNlCiAgICBleGNlcHQgQmFzZUV4Y2VwdGlvbjoK
:::ICAgICAgICB0cnk6CiAgICAgICAgICAgIHdpdGggb3BlbihMT0dfRVJST1JFUywg
:::J2EnLCBlbmNvZGluZz0ndXRmLTgnKSBhcyBmaDoKICAgICAgICAgICAgICAgIGZo
:::LndyaXRlKHRyYWNlYmFjay5mb3JtYXRfZXhjKCkgKyAnXG4nKQogICAgICAgIGV4
:::Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgIHBhc3MKICAgICAgICByYWlzZQo=
