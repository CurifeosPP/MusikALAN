@echo off
rem ================================================================
rem  MUSIKALAN - instalador y lanzador todo-en-uno (antes Descargador de Musica)
rem  ----------------------------------------------------------------
rem  Este unico archivo .bat:
rem    [1] Restaura la aplicacion (script Python embebido en base64)
rem    [2] Comprueba Python 3.9+ con Tkinter; si falta, descarga un
rem        Python portatil COMPLETO en la carpeta "runtime"
rem        (sin permisos de administrador; incluye la interfaz grafica)
rem    [3] Instala yt-dlp y mutagen con pip si no estan
rem    [4] Comprueba FFmpeg ; si falta, lo descarga de los espejos
rem        rapidos de GitHub (GyanD / BtbN) y de gyan.dev de reserva
rem    [5] Abre la ventana de descargas (YouTube Downloader)
rem  Requisitos: Windows 10 1803 o superior. Internet solo la primera vez.
rem  Parametro opcional:  --reinstalar   (vuelve a extraer descargador.py)
rem  NOTA: este archivo debe ser ASCII puro y CRLF (no tocar a mano).
rem ================================================================
setlocal EnableExtensions
title MusikALAN v2.3
cd /d "%~dp0"

set "APPDIR=%~dp0"
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
echo    %C_TIT%MusikALAN v2.3%C_FIN% - preparando el entorno
echo    Instalador portable: no pide permisos de administrador.
echo    Si falta algo (Python, yt-dlp, FFmpeg) se descarga e instala aqui.
echo   %C_GRI%--------------------------------------------------------------------%C_FIN%
echo    Sistema : Windows 10 o superior, %ARCH%
echo    Carpeta : %APPDIR%
echo    Destino : %APPDATA%\MusikALAN
echo.

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
echo   Descargas en: %APPDATA%\MusikALAN (cambiable en la ventana)
echo   La ventana de descargas se abre a continuacion.
echo   %C_GRI%--------------------------------------------------------------------%C_FIN%
echo.
title MusikALAN v2.3 - YouTube a AAC/MP3/FLAC/WAV/WMA/AVI
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
echo    - Borra las carpetas "runtime" y "ffmpeg" y ejecuta de nuevo.
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
:::IGRpcmVjdG9zIGEgZWxsYSwgc2luCnN1YmNhcnBldGFzIHBvciBmb3JtYXRvLgoK
:::VXNvOiAgcHl0aG9uIGRlc2NhcmdhZG9yLnB5ICAgKG8gZG9ibGUgY2xpYyBlbiBE
:::ZXNjYXJnYWRvck11c2ljYS5iYXQpClNpIGxhIFVSTCBwZXJ0ZW5lY2UgYSB1bmEg
:::bGlzdGEgZGUgcmVwcm9kdWNjaW9uLCBlbCBwcm9ncmFtYSBwcmVndW50YQpzaSBi
:::YWphciBzb2xvIGxhIGNhbmNpb24gcGVnYWRhIG8gbGEgcGxheWxpc3QgY29tcGxl
:::dGEgKGNvbiB1bmEgcGF1c2EKZGUgMiBzIGVudHJlIGNhbmNpb25lcyBwYXJhIG5v
:::IHNhdHVyYXIgYSBZb3VUdWJlKS4KIiIiCgppbXBvcnQganNvbgppbXBvcnQgb3MK
:::aW1wb3J0IHF1ZXVlCmltcG9ydCByZQppbXBvcnQgc2h1dGlsCmltcG9ydCBzdWJw
:::cm9jZXNzCmltcG9ydCBzeXMKaW1wb3J0IHRocmVhZGluZwppbXBvcnQgdGltZQpp
:::bXBvcnQgdHJhY2ViYWNrCmZyb20gcGF0aGxpYiBpbXBvcnQgUGF0aApmcm9tIHVy
:::bGxpYi5wYXJzZSBpbXBvcnQgcGFyc2VfcXMsIHVybGVuY29kZSwgdXJscGFyc2Us
:::IHVybHVucGFyc2UKZnJvbSB1cmxsaWIucmVxdWVzdCBpbXBvcnQgdXJsb3BlbgoK
:::QVBQX1YgPSAnMi4zJwpBUFBfRElSID0gUGF0aChfX2ZpbGVfXykucmVzb2x2ZSgp
:::LnBhcmVudApSVVRBX0FKVVNURVMgPSBBUFBfRElSIC8gJ2FqdXN0ZXMuanNvbicK
:::TE9HX0VSUk9SRVMgPSBBUFBfRElSIC8gJ2Rlc2NhcmdhZG9yX2Vycm9yZXMubG9n
:::JwoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tIHNhbGlkYQojIEFsIGVqZWN1dGFyc2UgY29u
:::IHB5dGhvbncuZXhlIChzaW4gY29uc29sYSkgc3Rkb3V0L3N0ZGVyciBzb24gTm9u
:::ZToKIyBjdWFscXVpZXIgcHJpbnQgZmFsbGFyaWEuIExvcyByZWRpcmlnaW1vcyBh
:::IHVuIHNpdGlvIHNlZ3Vyby4KdHJ5OgogICAgaWYgc3lzLnN0ZG91dCBpcyBOb25l
:::OgogICAgICAgIHN5cy5zdGRvdXQgPSBvcGVuKG9zLmRldm51bGwsICd3JywgZW5j
:::b2Rpbmc9J3V0Zi04JykKZXhjZXB0IEV4Y2VwdGlvbjoKICAgIHBhc3MKdHJ5Ogog
:::ICAgaWYgc3lzLnN0ZGVyciBpcyBOb25lOgogICAgICAgIHN5cy5zdGRlcnIgPSBv
:::cGVuKExPR19FUlJPUkVTLCAnYScsIGVuY29kaW5nPSd1dGYtOCcpCmV4Y2VwdCBF
:::eGNlcHRpb246CiAgICBwYXNzCgoKZGVmIF9yZWNvbmZpZ3VyYXJfc2FsaWRhKCk6
:::CiAgICAiIiJFdml0YSBjcmFzaGVzIHBvciBjYXJhY3RlcmVzIHJhcm9zIHNpIGxh
:::IHNhbGlkYSBzZSByZWRpcmlnZS4iIiIKICAgIGZvciBzIGluIChzeXMuc3Rkb3V0
:::LCBzeXMuc3RkZXJyKToKICAgICAgICB0cnk6CiAgICAgICAgICAgIGlmIHMgYW5k
:::IGhhc2F0dHIocywgJ3JlY29uZmlndXJlJyk6CiAgICAgICAgICAgICAgICBzLnJl
:::Y29uZmlndXJlKGVycm9ycz0ncmVwbGFjZScpCiAgICAgICAgZXhjZXB0IEV4Y2Vw
:::dGlvbjoKICAgICAgICAgICAgcGFzcwoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSB0a2lu
:::dGVyCnRyeToKICAgIGltcG9ydCB0a2ludGVyIGFzIHRrCiAgICBmcm9tIHRraW50
:::ZXIgaW1wb3J0IGZpbGVkaWFsb2csIG1lc3NhZ2Vib3gsIHR0awogICAgZnJvbSB0
:::a2ludGVyLnNjcm9sbGVkdGV4dCBpbXBvcnQgU2Nyb2xsZWRUZXh0CiAgICBUS19P
:::SyA9IFRydWUKZXhjZXB0IEV4Y2VwdGlvbjoKICAgIFRLX09LID0gRmFsc2UKCgoj
:::IC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0gYWp1c3RlcwpkZWYgX2NhcnBldGFfbXVzaWNhKCk6
:::CiAgICAiIiJDYXJwZXRhICdNdXNpY2EnIHJlYWwgZGVsIHVzdWFyaW8gKEZPTERF
:::UklEX011c2ljIGRlIFdpbmRvd3MpLiIiIgogICAgaWYgb3MubmFtZSA9PSAnbnQn
:::OgogICAgICAgIHRyeToKICAgICAgICAgICAgaW1wb3J0IGN0eXBlcwoKICAgICAg
:::ICAgICAgY2xhc3MgX0dVSUQoY3R5cGVzLlN0cnVjdHVyZSk6CiAgICAgICAgICAg
:::ICAgICBfZmllbGRzXyA9IFsoJ0QxJywgY3R5cGVzLmNfdWxvbmcpLCAoJ0QyJywg
:::Y3R5cGVzLmNfdXNob3J0KSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICgn
:::RDMnLCBjdHlwZXMuY191c2hvcnQpLAogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgKCdENCcsIGN0eXBlcy5jX3VieXRlICogOCldCgogICAgICAgICAgICBtdXNp
:::Y2EgPSBfR1VJRCgweDRCRDhENTcxLCAweDZEMTksIDB4NDhEMywKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgKGN0eXBlcy5jX3VieXRlICogOCkoMHhCRSwgMHg5
:::NywgMHgwMywgMHgzOCwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgMHg1RiwgMHg3RiwgMHhDNSwgMHhDRSkpCiAgICAgICAg
:::ICAgIHB0ciA9IGN0eXBlcy5jX3djaGFyX3AoKQogICAgICAgICAgICBpZiBjdHlw
:::ZXMud2luZGxsLnNoZWxsMzIuU0hHZXRLbm93bkZvbGRlclBhdGgoCiAgICAgICAg
:::ICAgICAgICAgICAgY3R5cGVzLmJ5cmVmKG11c2ljYSksIDAsIE5vbmUsCiAgICAg
:::ICAgICAgICAgICAgICAgY3R5cGVzLmJ5cmVmKHB0cikpID09IDAgYW5kIHB0ci52
:::YWx1ZToKICAgICAgICAgICAgICAgIHJ1dGEgPSBwdHIudmFsdWUKICAgICAgICAg
:::ICAgICAgIGN0eXBlcy53aW5kbGwub2xlMzIuQ29UYXNrTWVtRnJlZShwdHIpCiAg
:::ICAgICAgICAgICAgICByZXR1cm4gcnV0YQogICAgICAgIGV4Y2VwdCBFeGNlcHRp
:::b246CiAgICAgICAgICAgIHBhc3MKICAgIHJldHVybiBzdHIoUGF0aC5ob21lKCkg
:::LyAnTXVzaWMnKQoKCmRlZiBfZGVzdGlub19hcHBkYXRhX3ZpZWpvKCk6CiAgICAi
:::IiJDYXJwZXRhIGRlbCBwcm9ncmFtYSAoZXJhIGVsIGRlc3Rpbm8gcG9yIGRlZmVj
:::dG8gZW4gbGEgdjIuMikuIiIiCiAgICBiYXNlID0gb3MuZW52aXJvbi5nZXQoJ0FQ
:::UERBVEEnKSBvciBzdHIoUGF0aC5ob21lKCkgLyAnQXBwRGF0YScgLyAnUm9hbWlu
:::ZycpCiAgICByZXR1cm4gc3RyKFBhdGgoYmFzZSkgLyAnTXVzaWtBTEFOJykKCgpk
:::ZWYgX2Rlc3Rpbm9fcG9yX2RlZmVjdG8oKToKICAgICIiIkxvcyBhcmNoaXZvcyBz
:::ZSBndWFyZGFuIGVuIGxhIGNhcnBldGEgTXVzaWNhIGRlbCB1c3VhcmlvLiIiIgog
:::ICAgcmV0dXJuIF9jYXJwZXRhX211c2ljYSgpCgoKQUpVU1RFU19ERUZFQ1RPID0g
:::ewogICAgJ2Rlc3Rpbm8nOiBfZGVzdGlub19wb3JfZGVmZWN0bygpLAogICAgJ3Rl
:::bWEnOiAnT3NjdXJvJywKICAgICdmb3JtYXRvJzogJ0FBQycsCiAgICAnY2FsaWRh
:::ZCc6ICcxMjhrJywKICAgICdlbWJlYmVyJzogVHJ1ZSwKfQoKCmRlZiBjYXJnYXJf
:::YWp1c3RlcygpOgogICAgYSA9IGRpY3QoQUpVU1RFU19ERUZFQ1RPKQogICAgdHJ5
:::OgogICAgICAgIGEudXBkYXRlKGpzb24ubG9hZHMoUlVUQV9BSlVTVEVTLnJlYWRf
:::dGV4dChlbmNvZGluZz0ndXRmLTgnKSkpCiAgICBleGNlcHQgRXhjZXB0aW9uOgog
:::ICAgICAgIHBhc3MKICAgIGEucG9wKCduYXZlZ2Fkb3InLCBOb25lKSAgIyB2Mi4y
:::IG8gYW50ZXJpb3I6IGxhIHNlY2Npb24gZGUgY29va2llcyB5YSBubyBleGlzdGUK
:::ICAgICMgbWlncmFjaW9uZXMgZGVsIGRlc3Rpbm8gZGUgZ3VhcmRhZG86CiAgICAj
:::ICDCtyB2Mi4wLzIuMSB1c2FiYSBNdXNpYy9ZVERvd25sb2FkZXIKICAgICMgIMK3
:::IHYyLjIgdXNhYmEgbGEgY2FycGV0YSBkZWwgcHJvZ3JhbWEgKEFwcERhdGFcUm9h
:::bWluZ1xNdXNpa0FMQU4pCiAgICAjIERlc2RlIGxhIHYyLjMgZWwgZGVzdGlubyBw
:::b3IgZGVmZWN0byBlcyBsYSBjYXJwZXRhIE11c2ljYSBkZWwgdXN1YXJpbywKICAg
:::ICMgYXNpIHF1ZSBzaSBlbCBhanVzdGUgYXB1bnRhIGEgY3VhbHF1aWVyYSBkZSBs
:::b3MgZG9zLCBzZSBhY3R1YWxpemEuCiAgICBkZXN0aW5vID0gc3RyKGEuZ2V0KCdk
:::ZXN0aW5vJykgb3IgJycpLnJlcGxhY2UoJ1xcJywgJy8nKS5yc3RyaXAoJy8nKS5s
:::b3dlcigpCiAgICBpZiAneXRkb3dubG9hZGVyJyBpbiBkZXN0aW5vOgogICAgICAg
:::IGFbJ2Rlc3Rpbm8nXSA9IEFKVVNURVNfREVGRUNUT1snZGVzdGlubyddCiAgICBl
:::bHNlOgogICAgICAgIHZpZWpvID0gX2Rlc3Rpbm9fYXBwZGF0YV92aWVqbygpLnJl
:::cGxhY2UoJ1xcJywgJy8nKS5yc3RyaXAoJy8nKS5sb3dlcigpCiAgICAgICAgaWYg
:::ZGVzdGlubyBhbmQgKGRlc3Rpbm8gPT0gdmllam8KICAgICAgICAgICAgICAgICAg
:::ICAgICAgb3IgZGVzdGluby5zdGFydHN3aXRoKHZpZWpvICsgJy8nKSk6CiAgICAg
:::ICAgICAgIGFbJ2Rlc3Rpbm8nXSA9IEFKVVNURVNfREVGRUNUT1snZGVzdGlubydd
:::CiAgICByZXR1cm4gYQoKCmRlZiBndWFyZGFyX2FqdXN0ZXMoKToKICAgIHRyeToK
:::ICAgICAgICBSVVRBX0FKVVNURVMud3JpdGVfdGV4dCgKICAgICAgICAgICAganNv
:::bi5kdW1wcyhBSlVTVEVTLCBlbnN1cmVfYXNjaWk9RmFsc2UsIGluZGVudD0yKSwK
:::ICAgICAgICAgICAgZW5jb2Rpbmc9J3V0Zi04JykKICAgIGV4Y2VwdCBFeGNlcHRp
:::b246CiAgICAgICAgcGFzcwoKCkFKVVNURVMgPSBjYXJnYXJfYWp1c3RlcygpCgoK
:::IyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tIHV0aWxzCmRlZiBmbXRfdGFtKG4pOgogICAgaWYg
:::bm90IG46CiAgICAgICAgcmV0dXJuICfigJQnCiAgICBuID0gZmxvYXQobikKICAg
:::IGZvciB1IGluICgnQicsICdLaUInLCAnTWlCJywgJ0dpQicpOgogICAgICAgIGlm
:::IG4gPCAxMDI0IG9yIHUgPT0gJ0dpQic6CiAgICAgICAgICAgIHJldHVybiBmJ3tp
:::bnQobil9IHt1fScgaWYgdSA9PSAnQicgZWxzZSBmJ3tuOi4xZn0ge3V9JwogICAg
:::ICAgIG4gLz0gMTAyNAoKCmRlZiBmbXRfdGllbShzKToKICAgIGlmIHMgaXMgTm9u
:::ZToKICAgICAgICByZXR1cm4gJ+KAlCcKICAgIHMgPSBpbnQocykKICAgIGgsIHIg
:::PSBkaXZtb2QocywgMzYwMCkKICAgIG0sIHggPSBkaXZtb2QociwgNjApCiAgICBy
:::ZXR1cm4gZid7aH06e206MDJkfTp7eDowMmR9JyBpZiBoIGVsc2UgZid7bTowMmR9
:::Ont4OjAyZH0nCgoKZGVmIGxpbXBpYXJfbm9tYnJlKHQpOgogICAgdCA9IHJlLnN1
:::YihyJ1s8PjoiL1xcfD8qXHgwMC1ceDFmXScsICdfJywgc3RyKHQpKS5zdHJpcCgn
:::IC4nKQogICAgcmV0dXJuIHRbOjE1MF0gb3IgJ3Npbl90aXR1bG8nCgoKZGVmIHNp
:::bl9wbGF5bGlzdCh1cmwpOgogICAgIiIiUXVpdGEgZWwgcGFyw6FtZXRybyBsaXN0
:::PSBkZSBsYSBVUkwgKG1vZG8gc29sbyB2aWRlbykuIiIiCiAgICB0cnk6CiAgICAg
:::ICAgcCA9IHVybHBhcnNlKHVybCkKICAgICAgICBxID0gcGFyc2VfcXMocC5xdWVy
:::eSkKICAgICAgICBpZiAnbGlzdCcgaW4gcToKICAgICAgICAgICAgZGVsIHFbJ2xp
:::c3QnXQogICAgICAgICAgICByZXR1cm4gdXJsdW5wYXJzZShwLl9yZXBsYWNlKHF1
:::ZXJ5PXVybGVuY29kZShxLCBkb3NlcT1UcnVlKSkpLCBUcnVlCiAgICBleGNlcHQg
:::RXhjZXB0aW9uOgogICAgICAgIHBhc3MKICAgIHJldHVybiB1cmwsIEZhbHNlCgoK
:::ZGVmIGVzX3VybF9wbGF5bGlzdCh1cmwpOgogICAgIiIiVHJ1ZSBzaSBsYSBVUkwg
:::cGVydGVuZWNlIGEgdW5hIGxpc3RhIGRlIHJlcHJvZHVjY2nDs24gKGxsZXZhIGxp
:::c3Q9KS4iIiIKICAgIHRyeToKICAgICAgICByZXR1cm4gJ2xpc3QnIGluIHBhcnNl
:::X3FzKHVybHBhcnNlKHVybCkucXVlcnkpCiAgICBleGNlcHQgRXhjZXB0aW9uOgog
:::ICAgICAgIHJldHVybiBGYWxzZQoKCmRlZiBlc19zb2xvX2xpc3RhKHVybCk6CiAg
:::ICAiIiJUcnVlIHNpIGxhIFVSTCBlcyB1bmEgcGxheWxpc3QgcHVyYSwgc2luIHZp
:::ZGVvIGluZGl2aWR1YWwgKHNpbiB2PSkuIiIiCiAgICB0cnk6CiAgICAgICAgcCA9
:::IHVybHBhcnNlKHVybCkKICAgICAgICBpZiAndicgaW4gcGFyc2VfcXMocC5xdWVy
:::eSkgb3IgJ3lvdXR1LmJlJyBpbiAocC5uZXRsb2Mgb3IgJycpOgogICAgICAgICAg
:::ICByZXR1cm4gRmFsc2UKICAgICAgICByZXR1cm4gKHAucGF0aCBvciAnJykucnN0
:::cmlwKCcvJykuZW5kc3dpdGgoJy9wbGF5bGlzdCcpCiAgICBleGNlcHQgRXhjZXB0
:::aW9uOgogICAgICAgIHJldHVybiBGYWxzZQoKCmRlZiBhYnJpcl9jYXJwZXRhKHJ1
:::dGEpOgogICAgdHJ5OgogICAgICAgIGlmIG9zLm5hbWUgPT0gJ250JzoKICAgICAg
:::ICAgICAgb3Muc3RhcnRmaWxlKHN0cihydXRhKSkgICMgbm9xYTogc29sbyBXaW5k
:::b3dzCiAgICAgICAgZWxzZToKICAgICAgICAgICAgc3VicHJvY2Vzcy5Qb3Blbihb
:::J3hkZy1vcGVuJywgc3RyKHJ1dGEpXSkKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAg
:::ICAgICAgcGFzcwoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBmZm1wZWcKZGVmIGJ1c2Nh
:::cl9mZm1wZWcoKToKICAgIGV4ZSA9IHNodXRpbC53aGljaCgnZmZtcGVnJykKICAg
:::IGlmIGV4ZToKICAgICAgICByZXR1cm4gUGF0aChleGUpCiAgICBjYW5kaWRhdG9z
:::ID0gWwogICAgICAgIEFQUF9ESVIgLyAnZmZtcGVnJyAvICdiaW4nIC8gJ2ZmbXBl
:::Zy5leGUnLAogICAgICAgIEFQUF9ESVIgLyAnZmZtcGVnJyAvICdiaW4nIC8gJ2Zm
:::bXBlZycsCiAgICAgICAgQVBQX0RJUiAvICdydW50aW1lJyAvICdmZm1wZWcuZXhl
:::JywKICAgIF0KICAgIGZvciBwIGluIGNhbmRpZGF0b3M6CiAgICAgICAgaWYgcC5l
:::eGlzdHMoKToKICAgICAgICAgICAgcmV0dXJuIHAKICAgIHJldHVybiBOb25lCgoK
:::ZGVmIGJ1c2Nhcl9mZnByb2JlKGZmbXBlZyk6CiAgICBpZiBmZm1wZWcgaXMgTm9u
:::ZToKICAgICAgICByZXR1cm4gc2h1dGlsLndoaWNoKCdmZnByb2JlJykKICAgIHAg
:::PSBmZm1wZWcud2l0aF9uYW1lKCdmZnByb2JlLmV4ZScgaWYgb3MubmFtZSA9PSAn
:::bnQnIGVsc2UgJ2ZmcHJvYmUnKQogICAgaWYgcC5leGlzdHMoKToKICAgICAgICBy
:::ZXR1cm4gcAogICAgcmV0dXJuIHNodXRpbC53aGljaCgnZmZwcm9iZScpCgoKWVRf
:::RExQID0gTm9uZSAgICMgbcOzZHVsbyB5dF9kbHA7IHNlIHJlbGxlbmEgZW4gY29t
:::cHJvYmFyX2VudG9ybm8oKQpGRk1QRUcgPSBOb25lICAgIyBydXRhIGRlIGZmbXBl
:::ZwpGRlBST0JFID0gTm9uZSAgIyBydXRhIGRlIGZmcHJvYmUKCgpkZWYgY29tcHJv
:::YmFyX2VudG9ybm8oKToKICAgIGdsb2JhbCBZVF9ETFAsIEZGTVBFRywgRkZQUk9C
:::RQogICAgdHJ5OgogICAgICAgIGltcG9ydCB5dF9kbHAgYXMgbW9kCiAgICAgICAg
:::WVRfRExQID0gbW9kCiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHBhc3MK
:::ICAgIEZGTVBFRyA9IGJ1c2Nhcl9mZm1wZWcoKQogICAgRkZQUk9CRSA9IGJ1c2Nh
:::cl9mZnByb2JlKEZGTVBFRykKCgpjbGFzcyBSZWdpc3RybzoKICAgICIiIkxvZ2dl
:::ciBwYXJhIHl0LWRscDogcmVlbnbDrWEgYXZpc29zL2Vycm9yZXMgYWwgcmVnaXN0
:::cm8gZGUgbGEgR1VJLiIiIgoKICAgIGRlZiBfX2luaXRfXyhzZWxmKToKICAgICAg
:::ICBzZWxmLmxvZyA9IE5vbmUgICMgbGEgR1VJIGxvIGNvbmVjdGE6IGxvZyhtZW5z
:::YWplLCBldGlxdWV0YSkKCiAgICBkZWYgZGVidWcoc2VsZiwgbSk6CiAgICAgICAg
:::cGFzcwoKICAgICMgQXZpc29zIGludGVybm9zIGRlIHl0LWRscCBxdWUgc29sbyBt
:::ZXRlbiBydWlkbyBlbiBlbCByZWdpc3RybzoKICAgIEFWSVNPU19SVUlET1NPUyA9
:::ICgnTm8gc3VwcG9ydGVkIEphdmFTY3JpcHQgcnVudGltZScsICdFSlMnKQoKICAg
:::IGRlZiB3YXJuaW5nKHNlbGYsIG0pOgogICAgICAgIG0gPSBzdHIobSkuc3RyaXAo
:::KQogICAgICAgIGlmIG5vdCBtIG9yIGFueSh4IGluIG0gZm9yIHggaW4gc2VsZi5B
:::VklTT1NfUlVJRE9TT1MpOgogICAgICAgICAgICByZXR1cm4KICAgICAgICBpZiBz
:::ZWxmLmxvZzoKICAgICAgICAgICAgc2VsZi5sb2cobSwgJ2F2aXNvJykKCiAgICBk
:::ZWYgZXJyb3Ioc2VsZiwgbSk6CiAgICAgICAgbSA9IHN0cihtKS5zdHJpcCgpCiAg
:::ICAgICAgaWYgbSBhbmQgc2VsZi5sb2c6CiAgICAgICAgICAgIHNlbGYubG9nKG0s
:::ICdlcnJvcicpCgoKUkVHSVNUUk8gPSBSZWdpc3RybygpCgpOT01CUkVTX1BQID0g
:::ewogICAgJ0ZGbXBlZ0V4dHJhY3RBdWRpbyc6ICdDb252aXJ0aWVuZG8gZWwgYXVk
:::aW8gY29uIEZGbXBlZycsCiAgICAnRkZtcGVnTWV0YWRhdGEnOiAnRXNjcmliaWVu
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
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBvcGNpb25lcwpk
:::ZWYgb3B0c19iYXNlKGNhcnBldGEsIGNvbGEpOgogICAgcHJvZ3Jlc28sIHBvc3Rw
:::cm9jZXNvID0gaG9va3NfZ3VpKGNvbGEpCiAgICBvID0gewogICAgICAgICdvdXR0
:::bXBsJzogc3RyKGNhcnBldGEgLyAnJSh0aXRsZSlzLiUoZXh0KXMnKSwKICAgICAg
:::ICAncXVpZXQnOiBUcnVlLAogICAgICAgICdub193YXJuaW5ncyc6IFRydWUsCiAg
:::ICAgICAgJ25vcHJvZ3Jlc3MnOiBUcnVlLAogICAgICAgICdub3BsYXlsaXN0Jzog
:::VHJ1ZSwKICAgICAgICAnaWdub3JlZXJyb3JzJzogRmFsc2UsCiAgICAgICAgJ3Jl
:::dHJpZXMnOiAxMCwKICAgICAgICAnZnJhZ21lbnRfcmV0cmllcyc6IDEwLAogICAg
:::ICAgICdzb2NrZXRfdGltZW91dCc6IDMwLAogICAgICAgICdjb25jdXJyZW50X2Zy
:::YWdtZW50X2Rvd25sb2Fkcyc6IDQsCiAgICAgICAgJ3dpbmRvd3NmaWxlbmFtZXMn
:::OiBUcnVlLAogICAgICAgICdvdmVyd3JpdGVzJzogRmFsc2UsCiAgICAgICAgJ2xv
:::Z2dlcic6IFJFR0lTVFJPLAogICAgICAgICdwcm9ncmVzc19ob29rcyc6IFtwcm9n
:::cmVzb10sCiAgICAgICAgJ3Bvc3Rwcm9jZXNzb3JfaG9va3MnOiBbcG9zdHByb2Nl
:::c29dLAogICAgfQogICAgaWYgRkZNUEVHOgogICAgICAgIG9bJ2ZmbXBlZ19sb2Nh
:::dGlvbiddID0gc3RyKEZGTVBFRy5wYXJlbnQpCiAgICByZXR1cm4gbwoKCmRlZiBj
:::b252ZXJ0aXJfZmZtcGVnKGNtZCwgZXRpcXVldGEsIGNvbGEpOgogICAgIiIiRWpl
:::Y3V0YSBGRm1wZWcgKGxpc3RhIGRlIGFyZ3VtZW50b3MsIHNpbiBzaGVsbCkgY29u
:::IG1hcnF1ZWUuIiIiCiAgICBjb2xhLnB1dCgoJ3Byb2cnLCBOb25lLCBldGlxdWV0
:::YSkpCgogICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAgICAgICAgY29sYS5wdXQo
:::KCdsb2cnLCBtLCB0KSkKCiAgICB0cnk6CiAgICAgICAgcCA9IHN1YnByb2Nlc3Mu
:::cnVuKGNtZCwgc3Rkb3V0PXN1YnByb2Nlc3MuUElQRSwKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgc3RkZXJyPXN1YnByb2Nlc3MuUElQRSwgdGV4dD1UcnVlLAog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBlbmNvZGluZz0ndXRmLTgnLCBlcnJv
:::cnM9J3JlcGxhY2UnKQogICAgZXhjZXB0IEZpbGVOb3RGb3VuZEVycm9yOgogICAg
:::ICAgIHAgPSBOb25lCiAgICBpZiBwIGlzIE5vbmUgb3IgcC5yZXR1cm5jb2RlICE9
:::IDA6CiAgICAgICAgbG9nKCfinJYgRkZtcGVnIGRldm9sdmnDsyB1biBlcnJvcjon
:::LCAnZXJyb3InKQogICAgICAgIGlmIHAgaXMgbm90IE5vbmU6CiAgICAgICAgICAg
:::IGZvciBsbiBpbiAocC5zdGRlcnIgb3IgJycpLnN0cmlwKCkuc3BsaXRsaW5lcygp
:::Wy00Ol06CiAgICAgICAgICAgICAgICBsb2coJyAgICcgKyBsbls6MTgwXSwgJ2dy
:::aXMnKQogICAgICAgIGNvbGEucHV0KCgncHJvZycsIDAsICcnKSkKICAgICAgICBy
:::ZXR1cm4gRmFsc2UKICAgIHJldHVybiBUcnVlCgoKZGVmIGFyY2hpdm9fZmluYWwo
:::aW5mbywgY2FycGV0YSwgZXh0KToKICAgICIiIkxvY2FsaXphIGVsIGFyY2hpdm8g
:::cmVzdWx0YW50ZSAoeXQtZGxwIGxvIHJlcG9ydGE7IGZhbGxiYWNrOiBtw6FzIG51
:::ZXZvKS4iIiIKICAgIHRyeToKICAgICAgICBmb3IgZCBpbiAoaW5mby5nZXQoJ3Jl
:::cXVlc3RlZF9kb3dubG9hZHMnKSBvciBbXSk6CiAgICAgICAgICAgIGYgPSBkLmdl
:::dCgnZmlsZXBhdGgnKQogICAgICAgICAgICBpZiBmOgogICAgICAgICAgICAgICAg
:::cmV0dXJuIFBhdGgoZikKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgcGFz
:::cwogICAgY2FuZCA9IHNvcnRlZChjYXJwZXRhLmdsb2IoJyouJyArIGV4dCksCiAg
:::ICAgICAgICAgICAgICAgIGtleT1sYW1iZGEgcDogcC5zdGF0KCkuc3RfbXRpbWUs
:::IHJldmVyc2U9VHJ1ZSkKICAgIHJldHVybiBjYW5kWzBdIGlmIGNhbmQgZWxzZSBO
:::b25lCgoKZGVmIGxpbXBpYXJfbWluaWF0dXJhcyhjYXJwZXRhLCBhcmNoaXZvKToK
:::ICAgICIiIkJvcnJhIG1pbmlhdHVyYXMgc3VlbHRhcyBxdWUgRW1iZWRUaHVtYm5h
:::aWwgZGVqYXJhIHNpbiBpbmNydXN0YXIuIiIiCiAgICBmb3IgZXh0IGluICgnLndl
:::YnAnLCAnLmpwZycsICcuanBlZycsICcucG5nJyk6CiAgICAgICAgdCA9IGFyY2hp
:::dm8ud2l0aF9zdWZmaXgoZXh0KQogICAgICAgIGlmIHQuZXhpc3RzKCk6CiAgICAg
:::ICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHQudW5saW5rKCkKICAgICAgICAg
:::ICAgZXhjZXB0IE9TRXJyb3I6CiAgICAgICAgICAgICAgICBwYXNzCgoKIyAtLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tIGRlc2NhcmdhcwpkZWYgZGVzY2FyZ2FyX2F1ZGlvKHVybCwg
:::bm9tYnJlX2ZtdCwgY2FsaWRhZCwgZGVzdGlubywgZW1iZWJlciwgY29sYSk6CiAg
:::ICAiIiJBQUMgKC5tNGEpIC8gTVAzIC8gRkxBQyAvIFdBViB2w61hIHBvc3Rwcm9j
:::ZXNhZG9yZXMgZGUgeXQtZGxwLiIiIgogICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6
:::CiAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICBmbXQgPSBGT1JN
:::QVRPU1tub21icmVfZm10XQogICAgY2FycGV0YSA9IGRlc3Rpbm8gICAgICAgICAg
:::IyB2Mi4zOiBzaW4gc3ViY2FycGV0YXMgcG9yIGZvcm1hdG8KICAgIGNhcnBldGEu
:::bWtkaXIocGFyZW50cz1UcnVlLCBleGlzdF9vaz1UcnVlKQogICAgY29kZWMgPSBm
:::bXRbJ2V4dCddCiAgICBjb25fcG9ydGFkYSA9IGVtYmViZXIgYW5kIG5vbWJyZV9m
:::bXQgaW4gKCdBQUMnLCAnTVAzJywgJ0ZMQUMnKQogICAgY29uX3RhZ3MgPSBlbWJl
:::YmVyCiAgICBwcHMgPSBbeydrZXknOiAnRkZtcGVnRXh0cmFjdEF1ZGlvJywgJ3By
:::ZWZlcnJlZGNvZGVjJzogY29kZWMsCiAgICAgICAgICAgICdwcmVmZXJyZWRxdWFs
:::aXR5JzogY2FsaWRhZCBvciAnMCd9XQogICAgaWYgY29uX3RhZ3M6CiAgICAgICAg
:::cHBzLmFwcGVuZCh7J2tleSc6ICdGRm1wZWdNZXRhZGF0YScsICdhZGRfbWV0YWRh
:::dGEnOiBUcnVlfSkKICAgIGlmIGNvbl9wb3J0YWRhOgogICAgICAgIHBwcy5hcHBl
:::bmQoeydrZXknOiAnRW1iZWRUaHVtYm5haWwnLAogICAgICAgICAgICAgICAgICAg
:::ICdhbHJlYWR5X2hhdmVfdGh1bWJuYWlsJzogRmFsc2V9KQogICAgbyA9IG9wdHNf
:::YmFzZShjYXJwZXRhLCBjb2xhKQogICAgb1snZm9ybWF0J10gPSAnYmVzdGF1ZGlv
:::L2Jlc3QnCiAgICBvWydwb3N0cHJvY2Vzc29ycyddID0gcHBzCiAgICBvWyd3cml0
:::ZXRodW1ibmFpbCddID0gY29uX3BvcnRhZGEKICAgIHdpdGggWVRfRExQLllvdXR1
:::YmVETChvKSBhcyB5ZGw6CiAgICAgICAgaW5mbyA9IHlkbC5leHRyYWN0X2luZm8o
:::dXJsLCBkb3dubG9hZD1UcnVlKQogICAgYXJjaGl2byA9IGFyY2hpdm9fZmluYWwo
:::aW5mbywgY2FycGV0YSwgY29kZWMpCiAgICBpZiBhcmNoaXZvIGFuZCBjb25fcG9y
:::dGFkYToKICAgICAgICBsaW1waWFyX21pbmlhdHVyYXMoY2FycGV0YSwgYXJjaGl2
:::bykKICAgIHJldHVybiBpbmZvLCBhcmNoaXZvCgoKZGVmIGRlc2Nhcmdhcl93bWEo
:::dXJsLCBjYWxpZGFkLCBkZXN0aW5vLCBlbWJlYmVyLCBjb2xhKToKICAgICIiIldN
:::QSA5Ni8xMjgga2JwczogeXQtZGxwIG5vIHNvcG9ydGEgd21hLCBhc8OtIHF1ZSBz
:::ZSBiYWphIGEgV0FWIChjb24KICAgIGV0aXF1ZXRhcykgeSBsdWVnbyBGRm1wZWcg
:::cmVjb2RpZmljYSBhIHdtYXYyIGRlbnRybyBkZWwgLndtYSBmaW5hbC4KICAgIChF
:::bCBjb250ZW5lZG9yIEFTRiBkZSBmZm1wZWcgbm8gc29wb3J0YSBjYXLDoXR1bGEg
:::aW5jcnVzdGFkYS4pIiIiCiAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAg
:::ICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgIGNhcnBldGEgPSBkZXN0aW5v
:::ICAgICAgICAgICMgdjIuMzogc2luIHN1YmNhcnBldGFzIHBvciBmb3JtYXRvCiAg
:::ICB0bXAgPSBjYXJwZXRhIC8gJ190bXAnCiAgICBzaHV0aWwucm10cmVlKHRtcCwg
:::aWdub3JlX2Vycm9ycz1UcnVlKQogICAgdG1wLm1rZGlyKHBhcmVudHM9VHJ1ZSwg
:::ZXhpc3Rfb2s9VHJ1ZSkKICAgIG8gPSBvcHRzX2Jhc2UodG1wLCBjb2xhKQogICAg
:::b1snZm9ybWF0J10gPSAnYmVzdGF1ZGlvL2Jlc3QnCiAgICBwcHMgPSBbeydrZXkn
:::OiAnRkZtcGVnRXh0cmFjdEF1ZGlvJywgJ3ByZWZlcnJlZGNvZGVjJzogJ3dhdics
:::CiAgICAgICAgICAgICdwcmVmZXJyZWRxdWFsaXR5JzogJzAnfV0KICAgIGlmIGVt
:::YmViZXI6CiAgICAgICAgcHBzLmFwcGVuZCh7J2tleSc6ICdGRm1wZWdNZXRhZGF0
:::YScsICdhZGRfbWV0YWRhdGEnOiBUcnVlfSkKICAgIG9bJ3Bvc3Rwcm9jZXNzb3Jz
:::J10gPSBwcHMKICAgIHdpdGggWVRfRExQLllvdXR1YmVETChvKSBhcyB5ZGw6CiAg
:::ICAgICAgaW5mbyA9IHlkbC5leHRyYWN0X2luZm8odXJsLCBkb3dubG9hZD1UcnVl
:::KQogICAgd2F2ID0gYXJjaGl2b19maW5hbChpbmZvLCB0bXAsICd3YXYnKQogICAg
:::aWYgbm90IHdhdjoKICAgICAgICByYWlzZSBSdW50aW1lRXJyb3IoJ05vIHNlIGVu
:::Y29udHLDsyBlbCBXQVYgaW50ZXJtZWRpby4nKQogICAgbWV0YSA9IFtdCiAgICBp
:::ZiBlbWJlYmVyOgogICAgICAgIGFydGlzdGEgPSAoaW5mby5nZXQoJ2FydGlzdCcp
:::IG9yIGluZm8uZ2V0KCd1cGxvYWRlcicpCiAgICAgICAgICAgICAgICAgICBvciBp
:::bmZvLmdldCgnY2hhbm5lbCcpIG9yICcnKQogICAgICAgIGlmIGluZm8uZ2V0KCd0
:::aXRsZScpOgogICAgICAgICAgICBtZXRhICs9IFsnLW1ldGFkYXRhJywgJ3RpdGxl
:::PScgKyBzdHIoaW5mb1sndGl0bGUnXSldCiAgICAgICAgaWYgYXJ0aXN0YToKICAg
:::ICAgICAgICAgbWV0YSArPSBbJy1tZXRhZGF0YScsICdhcnRpc3Q9JyArIHN0cihh
:::cnRpc3RhKV0KICAgICAgICBtZXRhICs9IFsnLW1ldGFkYXRhJywgJ2FsYnVtPVlv
:::dVR1YmUnXQogICAgd21hID0gY2FycGV0YSAvIChsaW1waWFyX25vbWJyZShpbmZv
:::LmdldCgndGl0bGUnKSBvciAnYXVkaW8nKSArICcud21hJykKICAgIGNtZCA9IFtz
:::dHIoRkZNUEVHKSwgJy15JywgJy1pJywgc3RyKHdhdiksICctdm4nLAogICAgICAg
:::ICAgICctYzphJywgJ3dtYXYyJywgJy1iOmEnLCBmJ3tjYWxpZGFkfWsnXSArIG1l
:::dGEgKyBbc3RyKHdtYSldCiAgICBvayA9IGNvbnZlcnRpcl9mZm1wZWcoCiAgICAg
:::ICAgY21kLCBmJ0NvbnZpcnRpZW5kbyBhIFdNQSAod21hdjIgwrcge2NhbGlkYWR9
:::IGticHMpJywgY29sYSkKICAgIGlmIG5vdCBvazoKICAgICAgICByYWlzZSBSdW50
:::aW1lRXJyb3IoJ0ZGbXBlZyBubyBwdWRvIGNyZWFyIGVsIGFyY2hpdm8gV01BLicp
:::CiAgICBzaHV0aWwucm10cmVlKHRtcCwgaWdub3JlX2Vycm9ycz1UcnVlKQogICAg
:::cmV0dXJuIGluZm8sIHdtYQoKCiMgUGFyw6FtZXRyb3Mgb2ZpY2lhbGVzIGRlbCBy
:::ZXBvIGZkZDRzL3BvcnRhYmxlX21wM19wbGF5ZXJfdmlkZW9fY29udmVydGVyX3Rv
:::b2xzCiMgKHZpZGVvMnNoZW5qdTE4LnNoKTogTUpQRUcgMTYgZnBzICsgUENNIDIy
:::MDUwIEh6LCByb3RhZG9zIHBhcmEgbGEgcGFudGFsbGEKIyB2ZXJ0aWNhbCBkZSAx
:::Mjh4MTYwIGRlbCByZXByb2R1Y3RvciBzaGVpanUgZGUgMS44IHB1bGdhZGFzLgpW
:::Rl9TSEVJSlUgPSAnc2NhbGU9LTI6MTI4LCBjcm9wPTE2MDoxMjgsIHRyYW5zcG9z
:::ZT0yLCB2ZmxpcCcKIyBWYXJpYW50ZSBhIHBydWViYSBkZSBiYWxhcyBwYXJhIHZp
:::ZGVvcyBjdWFkcmFkb3MvdmVydGljYWxlcyAoU2hvcnRzKSwKIyBkb25kZSBlbCBy
:::ZWNvcnRlIDE2MDoxMjggb3JpZ2luYWwgc2Vyw61hIGltcG9zaWJsZToKVkZfU0VH
:::VVJPID0gKCdzY2FsZT0xNjA6MTI4OmZvcmNlX29yaWdpbmFsX2FzcGVjdF9yYXRp
:::bz1kZWNyZWFzZSwnCiAgICAgICAgICAgICAncGFkPTE2MDoxMjg6KG93LWl3KS8y
:::OihvaC1paCkvMix0cmFuc3Bvc2U9Mix2ZmxpcCcpCgoKZGVmIGRlc2Nhcmdhcl9h
:::dmkodXJsLCBkZXN0aW5vLCBjb2xhKToKICAgICIiIlZpZGVvIEFWSSBwYXJhIGVs
:::IHJlcHJvZHVjdG9yIHNoZWlqdSAxLjgiIDEyOHgxNjAuIiIiCiAgICBkZWYgbG9n
:::KG0sIHQ9J2luZm8nKToKICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoK
:::ICAgIGNhcnBldGEgPSBkZXN0aW5vICAgICAgICAgICMgdjIuMzogc2luIHN1YmNh
:::cnBldGFzIHBvciBmb3JtYXRvCiAgICB0bXAgPSBjYXJwZXRhIC8gJ190bXAnCiAg
:::ICBzaHV0aWwucm10cmVlKHRtcCwgaWdub3JlX2Vycm9ycz1UcnVlKQogICAgdG1w
:::Lm1rZGlyKHBhcmVudHM9VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgIG8gPSBvcHRz
:::X2Jhc2UodG1wLCBjb2xhKQogICAgIyBQYXJhIHVuYSBwYW50YWxsYSBkZSAxMjh4
:::MTYwIGJhc3RhIGNvbiA0ODBwOiBhaG9ycmEgbXVjaGEgZGVzY2FyZ2EuCiAgICBv
:::Wydmb3JtYXQnXSA9ICgnYmVzdFtoZWlnaHQ8PTQ4MF1bZXh0PW1wNF0vYmVzdFto
:::ZWlnaHQ8PTQ4MF0vJwogICAgICAgICAgICAgICAgICAgJ2J2KltoZWlnaHQ8PTQ4
:::MF0rYmEvYicpCiAgICBvWydtZXJnZV9vdXRwdXRfZm9ybWF0J10gPSAnbXA0Jwog
:::ICAgd2l0aCBZVF9ETFAuWW91dHViZURMKG8pIGFzIHlkbDoKICAgICAgICBpbmZv
:::ID0geWRsLmV4dHJhY3RfaW5mbyh1cmwsIGRvd25sb2FkPVRydWUpCiAgICBvcmln
:::ZW4gPSBhcmNoaXZvX2ZpbmFsKGluZm8sIHRtcCwgJ21wNCcpCiAgICBpZiBub3Qg
:::b3JpZ2VuOgogICAgICAgIG9yaWdlbiA9IChhcmNoaXZvX2ZpbmFsKGluZm8sIHRt
:::cCwgJ21rdicpCiAgICAgICAgICAgICAgICAgIG9yIGFyY2hpdm9fZmluYWwoaW5m
:::bywgdG1wLCAnd2VibScpKQogICAgaWYgbm90IG9yaWdlbjoKICAgICAgICByYWlz
:::ZSBSdW50aW1lRXJyb3IoJ05vIHNlIGVuY29udHLDsyBlbCB2aWRlbyBkZXNjYXJn
:::YWRvLicpCiAgICBhdmkgPSBjYXJwZXRhIC8gKGxpbXBpYXJfbm9tYnJlKGluZm8u
:::Z2V0KCd0aXRsZScpIG9yICd2aWRlbycpICsgJy5hdmknKQogICAgYmFzZSA9IFtz
:::dHIoRkZNUEVHKSwgJy15JywgJy1pJywgc3RyKG9yaWdlbiksICctcicsICcxNics
:::CiAgICAgICAgICAgICctYWNvZGVjJywgJ3BjbV9zMTZsZScsICctYWMnLCAnMics
:::ICctYXInLCAnMjIwNTAnLAogICAgICAgICAgICAnLXBpeF9mbXQnLCAneXV2ajQy
:::MHAnLCAnLWM6dicsICdtanBlZycsICctcTp2JywgJzInXQogICAgb2sgPSBjb252
:::ZXJ0aXJfZmZtcGVnKGJhc2UgKyBbJy12ZicsIFZGX1NIRUlKVSwgc3RyKGF2aSld
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICdDb252aXJ0aWVuZG8gYSBBVkkg
:::MTI4eDE2MCAoc2hlaWp1IDEuOCIpJywgY29sYSkKICAgIGlmIG5vdCBvazoKICAg
:::ICAgICBsb2coJ1ZpZGVvIGNvbiBwcm9wb3JjacOzbiBubyBlc3TDoW5kYXI7ICcK
:::ICAgICAgICAgICAgJ3JlaW50ZW50YW5kbyBlbiBtb2RvIGNvbXBhdGlibGUuLi4n
:::LCAnYXZpc28nKQogICAgICAgIG9rID0gY29udmVydGlyX2ZmbXBlZyhiYXNlICsg
:::WyctdmYnLCBWRl9TRUdVUk8sIHN0cihhdmkpXSwKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgJ1JlY29udmlydGllbmRvIGEgQVZJIDEyOHgxNjAnLCBjb2xh
:::KQogICAgaWYgbm90IG9rOgogICAgICAgIHJhaXNlIFJ1bnRpbWVFcnJvcignRkZt
:::cGVnIG5vIHB1ZG8gY3JlYXIgZWwgYXJjaGl2byBBVkkuJykKICAgIHNodXRpbC5y
:::bXRyZWUodG1wLCBpZ25vcmVfZXJyb3JzPVRydWUpCiAgICByZXR1cm4gaW5mbywg
:::YXZpCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGVzdGltYWNpw7NuCktCUFNfRVNUSU1B
:::RE9TID0gewogICAgJ0FBQyc6IDEyOCwgICAgICMgdGVjaG8gZGVsIGZvcm1hdG8K
:::ICAgICdXTUEnOiAxMjgsCiAgICAnV0FWJzogMTQxMSwgICAgIyBQQ00gNDQuMSBr
:::SHogwrcgMTYgYml0IMK3IGVzdMOpcmVvCiAgICAnRkxBQyc6IDk1MCwgICAgIyB0
:::w61waWNvIGRlIG3DunNpY2EgcHJvY2VkZW50ZSBkZSBZb3VUdWJlCiAgICAnQVZJ
:::JzogMTQ5MCwgICAgIyB+Nzg0IGticHMgTUpQRUcgMTZmcHMgKyA3MDYga2JwcyBQ
:::Q00gMjIwNTAgZXN0w6lyZW8KfQoKCmRlZiBlc3RpbWFyX2J5dGVzKGR1cmFjaW9u
:::X3MsIGZvcm1hdG8sIGNhbGlkYWQsIGVtYmViZXIpOgogICAgIiIiRXN0aW1hIGVs
:::IHRhbWHDsW8gZmluYWwgZW4gYnl0ZXMgKGPDoWxjdWxvIHB1cm8sIHRlc3RlYWJs
:::ZSkuIiIiCiAgICBpZiBmb3JtYXRvIGluICgnTVAzJywgJ0FBQycsICdXTUEnKToK
:::ICAgICAgICBrYnBzID0gaW50KHJlLnN1YihyJ1teMC05XScsICcnLCBzdHIoY2Fs
:::aWRhZCkpIG9yIDApCiAgICAgICAgaWYgbm90IGticHM6CiAgICAgICAgICAgIGti
:::cHMgPSBLQlBTX0VTVElNQURPUy5nZXQoZm9ybWF0bywgMTI4KQogICAgZWxzZToK
:::ICAgICAgICBrYnBzID0gS0JQU19FU1RJTUFET1MuZ2V0KGZvcm1hdG8sIDEyOCkK
:::ICAgIGV4dHJhID0gMTIwXzAwMCBpZiAoZW1iZWJlciBhbmQgZm9ybWF0byBpbiAo
:::J0FBQycsICdNUDMnLCAnRkxBQycpKSBlbHNlIDAKICAgIHJldHVybiBkdXJhY2lv
:::bl9zICoga2JwcyAqIDEwMDAgLyA4ICsgZXh0cmEKCgojIC0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0gY2FsaWRhZApkZWYgY2xhc2VfY2FsaWRhZChleHQsIGticHMpOgogICAgIiIi
:::Q2xhc2lmaWNhIHVuIGFyY2hpdm8uIERldnVlbHZlICh0ZXh0bywgbml2ZWwpIGNv
:::biBuaXZlbCAwPW9rIDE9bWVkaWEgMj1iYWphLiIiIgogICAgaWYgZXh0ID09ICcu
:::bXAzJzoKICAgICAgICBpZiBrYnBzID49IDMxNToKICAgICAgICAgICAgcmV0dXJu
:::ICczMjAga2JwcycsIDAKICAgICAgICBpZiBrYnBzID49IDI1MDoKICAgICAgICAg
:::ICAgcmV0dXJuICcyNTYga2JwcycsIDAKICAgICAgICBpZiBrYnBzID49IDE4NToK
:::ICAgICAgICAgICAgcmV0dXJuICcxOTIga2JwcycsIDAKICAgICAgICBpZiBrYnBz
:::ID49IDEyMDoKICAgICAgICAgICAgcmV0dXJuICcxMjgga2JwcycsIDEKICAgICAg
:::ICByZXR1cm4gZid7a2Jwc30ga2JwcyAoYmFqYSknLCAyCiAgICBpZiBleHQgPT0g
:::Jy5tNGEnOgogICAgICAgIGlmIGticHMgPj0gMTE1OgogICAgICAgICAgICByZXR1
:::cm4gJ0V4Y2VsZW50ZSAoQUFDIOKJpDEyOGspJywgMAogICAgICAgIGlmIGticHMg
:::Pj0gODI6CiAgICAgICAgICAgIHJldHVybiAnOTYga2JwcycsIDEKICAgICAgICBy
:::ZXR1cm4gZid7a2Jwc30ga2JwcyAoYmFqYSknLCAyCiAgICBpZiBleHQgPT0gJy53
:::bWEnOgogICAgICAgIGlmIGticHMgPj0gMTE1OgogICAgICAgICAgICByZXR1cm4g
:::JzEyOCBrYnBzJywgMAogICAgICAgIGlmIGticHMgPj0gODg6CiAgICAgICAgICAg
:::IHJldHVybiAnOTYga2JwcycsIDEKICAgICAgICByZXR1cm4gZid7a2Jwc30ga2Jw
:::cyAoYmFqYSknLCAyCiAgICBpZiBleHQgaW4gKCcuZmxhYycsICcud2F2Jyk6CiAg
:::ICAgICAgcmV0dXJuICdTaW4gcMOpcmRpZGEnLCAwCiAgICBpZiBleHQgPT0gJy5h
:::dmknOgogICAgICAgIGlmIGticHMgPj0gMTIwMDoKICAgICAgICAgICAgcmV0dXJu
:::IGYne2ticHN9IGticHMgKE1KUEVHK1BDTSAxMjh4MTYwKScsIDAKICAgICAgICBy
:::ZXR1cm4gZid7a2Jwc30ga2JwcyAoYWxnbyBiYWpvKScsIDEKICAgIHJldHVybiBm
:::J3trYnBzfSBrYnBzJywgMQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSB0ZW1hcwpURU1B
:::UyA9IHsKICAgICdPc2N1cm8nOiBkaWN0KAogICAgICAgIGZvbmRvPScjMWUxZjIy
:::JywgY2FtcG89JyMyYTJkMzEnLCBjYW1wb19ib3JkZT0nIzNhM2U0NCcsCiAgICAg
:::ICAgdGV4dG89JyNkOGRhZGMnLCB0ZXh0bzI9JyM5YTlmYTQnLAogICAgICAgIGJv
:::dG9uPScjM2EzZDQyJywgYm90b25fYWN0PScjNGE0ZTU1JywgYm90b25fdHh0PScj
:::ZThlYWVjJywKICAgICAgICBsb2c9JyMxNDE1MTgnLCBsb2dfdHh0PScjY2ZkM2Q3
:::JywgYWNlbnRvPScjNGY5Y2Y5JywKICAgICAgICBvaz0nIzdlYzk3ZicsIGVycm9y
:::PScjZTU3MzczJywgYXZpc289JyNkOGI2NGEnLCB0cm91Z2g9JyMyNjI4MmMnLAog
:::ICAgICAgIHBsYWNlaG9sZGVyPScjNzc3YzgyJyksCiAgICAnQ2xhcm8nOiBkaWN0
:::KAogICAgICAgIGZvbmRvPScjZjJmM2Y1JywgY2FtcG89JyNmZmZmZmYnLCBjYW1w
:::b19ib3JkZT0nI2M0YzhjZCcsCiAgICAgICAgdGV4dG89JyMyNDI3MmEnLCB0ZXh0
:::bzI9JyM2YTcwNzYnLAogICAgICAgIGJvdG9uPScjZTNlNWU4JywgYm90b25fYWN0
:::PScjZDJkNWRhJywgYm90b25fdHh0PScjMjQyNzJhJywKICAgICAgICBsb2c9JyNm
:::ZmZmZmYnLCBsb2dfdHh0PScjMmIyZTMxJywgYWNlbnRvPScjMWE2NmQ2JywKICAg
:::ICAgICBvaz0nIzFlN2UzNCcsIGVycm9yPScjYzYyODI4JywgYXZpc289JyM5YTY3
:::MDAnLCB0cm91Z2g9JyNkZmUxZTQnLAogICAgICAgIHBsYWNlaG9sZGVyPScjOWFh
:::MGE2JyksCn0KClBMQUNFSE9MREVSX1VSTCA9ICdodHRwczovL3d3dy55b3V0dWJl
:::LmNvbS93YXRjaD92PS4uLicKCkZVRU5URV9VSSA9ICgnU2Vnb2UgVUknLCA5KQpG
:::VUVOVEVfQlROID0gKCdTZWdvZSBVSScsIDEwKQpGVUVOVEVfQlROX0cgPSAoJ1Nl
:::Z29lIFVJJywgMTEpCkZVRU5URV9MT0cgPSAoJ0NvbnNvbGFzJywgMTApCgoKaWYg
:::VEtfT0s6CgogICAgY2xhc3MgQXBwKHRrLlRrKToKICAgICAgICAiIiJWZW50YW5h
:::IHByaW5jaXBhbCAoZGlzZcOxbyBlc3Blam8gZGVsIG1vY2t1cDogZ3J1cG9zIG9z
:::Y3Vyb3MpLiIiIgoKICAgICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBjb25zdHJ1Y2Npw7NuCiAgICAgICAgZGVm
:::IF9faW5pdF9fKHNlbGYpOgogICAgICAgICAgICBpZiBnZXRhdHRyKHN5cywgJ2Zy
:::b3plbicsIEZhbHNlKToKICAgICAgICAgICAgICAgIHBhc3MKICAgICAgICAgICAg
:::c3VwZXIoKS5fX2luaXRfXygpCiAgICAgICAgICAgIHNlbGYudGl0bGUoJ011c2lr
:::QUxBTicpCiAgICAgICAgICAgIHNlbGYuZ2VvbWV0cnkoJzg2MHg4NDAnKQogICAg
:::ICAgICAgICBzZWxmLm1pbnNpemUoNzAwLCA2NjApCiAgICAgICAgICAgIHNlbGYu
:::Y29sYSA9IHF1ZXVlLlF1ZXVlKCkKICAgICAgICAgICAgc2VsZi5fb2N1cGFkbyA9
:::IEZhbHNlCiAgICAgICAgICAgIHNlbGYuX2VuX3BsYWNlaG9sZGVyID0gVHJ1ZQog
:::ICAgICAgICAgICBzZWxmLl90ZW1hX2FjdHVhbCA9IEFKVVNURVMuZ2V0KCd0ZW1h
:::JywgJ09zY3VybycpCiAgICAgICAgICAgIGlmIHNlbGYuX3RlbWFfYWN0dWFsIG5v
:::dCBpbiBURU1BUzoKICAgICAgICAgICAgICAgIHNlbGYuX3RlbWFfYWN0dWFsID0g
:::J09zY3VybycKCiAgICAgICAgICAgIHNlbGYuX2VzdGlsbyA9IHR0ay5TdHlsZShz
:::ZWxmKQogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBzZWxmLl9lc3Rp
:::bG8udGhlbWVfdXNlKCdjbGFtJykKICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlv
:::bjoKICAgICAgICAgICAgICAgIHBhc3MKCiAgICAgICAgICAgIHNlbGYuX2NvbnN0
:::cnVpcigpCiAgICAgICAgICAgIHNlbGYuX2FwbGljYXJfdGVtYSgpCiAgICAgICAg
:::ICAgIHNlbGYuX2NvbmVjdGFyX2V2ZW50b3MoKQogICAgICAgICAgICBSRUdJU1RS
:::Ty5sb2cgPSBsYW1iZGEgbSwgdD0nYXZpc28nOiBzZWxmLmNvbGEucHV0KCgnbG9n
:::JywgbSwgdCkpCiAgICAgICAgICAgIHNlbGYuYWZ0ZXIoODAsIHNlbGYuX2JvbWJl
:::YXJfY29sYSkKICAgICAgICAgICAgc2VsZi5hZnRlcigxNTAsIHNlbGYuX2FycmFu
:::cXVlKQoKICAgICAgICBkZWYgX2NvbnN0cnVpcihzZWxmKToKICAgICAgICAgICAg
:::c2VsZi5fd2cgPSB7fSAgICAgICAgICMgcmVmZXJlbmNpYXMgcGFyYSBlbCB0ZW1h
:::CiAgICAgICAgICAgIHNlbGYuX2J0bnMgPSBbXSAgICAgICAjIGJvdG9uZXMgcGxh
:::bm9zIChwYXJhIGhvdmVyL3RlbWEpCiAgICAgICAgICAgIG1hcmNvID0gdGsuRnJh
:::bWUoc2VsZikKICAgICAgICAgICAgbWFyY28ucGFjayhmaWxsPSdib3RoJywgZXhw
:::YW5kPVRydWUsIHBhZHg9MTAsIHBhZHk9OCkKICAgICAgICAgICAgc2VsZi5fd2db
:::J21hcmNvJ10gPSBtYXJjbwogICAgICAgICAgICBtYXJjby5jb2x1bW5jb25maWd1
:::cmUoMCwgd2VpZ2h0PTEpCgogICAgICAgICAgICAjIC0tLSBmaWxhIFRlbWEgLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAg
:::ICAgICAgICAgIGYwID0gdGsuRnJhbWUobWFyY28pCiAgICAgICAgICAgIGYwLmdy
:::aWQocm93PTAsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgcGFkeT0oMCwgNikpCiAg
:::ICAgICAgICAgIHNlbGYuX3dnWydmMCddID0gZjAKICAgICAgICAgICAgc2VsZi5f
:::d2dbJ2xibF90ZW1hJ10gPSB0ay5MYWJlbChmMCwgdGV4dD0nVGVtYTonLCBmb250
:::PUZVRU5URV9VSSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF90ZW1hJ10ucGFj
:::ayhzaWRlPSdsZWZ0JykKICAgICAgICAgICAgc2VsZi5jbWJfdGVtYSA9IHR0ay5D
:::b21ib2JveCgKICAgICAgICAgICAgICAgIGYwLCB2YWx1ZXM9bGlzdChURU1BUyks
:::IHN0YXRlPSdyZWFkb25seScsIHdpZHRoPTksCiAgICAgICAgICAgICAgICBmb250
:::PUZVRU5URV9VSSwgc3R5bGU9J2d4LlRDb21ib2JveCcpCiAgICAgICAgICAgIHNl
:::bGYuY21iX3RlbWEuc2V0KHNlbGYuX3RlbWFfYWN0dWFsKQogICAgICAgICAgICBz
:::ZWxmLmNtYl90ZW1hLnBhY2soc2lkZT0nbGVmdCcsIHBhZHg9KDgsIDApLCBpcGFk
:::eT0yKQoKICAgICAgICAgICAgIyAtLS0gZ3J1cG86IFVSTCBkZSBZb3VUdWJlIC0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAgICAgICBn
:::dSA9IHRrLkxhYmVsRnJhbWUobWFyY28sIHRleHQ9J1VSTCBkZSBZb3VUdWJlJywg
:::Zm9udD1GVUVOVEVfVUksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBy
:::ZWxpZWY9J3NvbGlkJywgYmQ9MSkKICAgICAgICAgICAgZ3UuZ3JpZChyb3c9MSwg
:::Y29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYu
:::X3dnWydndSddID0gZ3UKICAgICAgICAgICAgZ3UuY29sdW1uY29uZmlndXJlKDAs
:::IHdlaWdodD0xKQogICAgICAgICAgICBzZWxmLmVudF91cmwgPSB0ay5FbnRyeShn
:::dSwgZm9udD1GVUVOVEVfVUksIHJlbGllZj0nZmxhdCcsCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgIGhpZ2hsaWdodHRoaWNrbmVzcz0xKQogICAg
:::ICAgICAgICBzZWxmLmVudF91cmwuZ3JpZChyb3c9MCwgY29sdW1uPTAsIHN0aWNr
:::eT0nZXcnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4PTgsIHBh
:::ZHk9OCwgaXBhZHk9NSkKICAgICAgICAgICAgc2VsZi5fcG9uZXJfcGxhY2Vob2xk
:::ZXIoKQogICAgICAgICAgICBzZWxmLmJ0bl94ID0gc2VsZi5fYm90b24oZ3UsICdY
:::Jywgc2VsZi5fbGltcGlhcl91cmwsIHdpZHRoPTMpCiAgICAgICAgICAgIHNlbGYu
:::YnRuX3guZ3JpZChyb3c9MCwgY29sdW1uPTEsIHN0aWNreT0nZScsIHBhZHg9KDAs
:::IDgpLCBpcGFkeT0zKQoKICAgICAgICAgICAgIyAtLS0gZ3J1cG86IEZvcm1hdG8g
:::eSBjYWxpZGFkIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAg
:::ICAgICAgICBnZiA9IHRrLkxhYmVsRnJhbWUobWFyY28sIHRleHQ9J0Zvcm1hdG8g
:::eSBjYWxpZGFkJywgZm9udD1GVUVOVEVfVUksCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICByZWxpZWY9J3NvbGlkJywgYmQ9MSkKICAgICAgICAgICAgZ2Yu
:::Z3JpZChyb3c9MiwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PTUpCiAgICAg
:::ICAgICAgIHNlbGYuX3dnWydnZiddID0gZ2YKICAgICAgICAgICAgZ2YuY29sdW1u
:::Y29uZmlndXJlKDEsIHdlaWdodD0xKQogICAgICAgICAgICBzZWxmLl93Z1snbGJs
:::X2ZtdCddID0gdGsuTGFiZWwoZ2YsIHRleHQ9J0Zvcm1hdG86JywgZm9udD1GVUVO
:::VEVfVUkpCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfZm10J10uZ3JpZChyb3c9
:::MCwgY29sdW1uPTAsIHN0aWNreT0ndycsIHBhZHg9OCwgcGFkeT01KQogICAgICAg
:::ICAgICBzZWxmLmNtYl9mb3JtYXRvID0gdHRrLkNvbWJvYm94KAogICAgICAgICAg
:::ICAgICAgZ2YsIHZhbHVlcz1bZlsndGV4dG8nXSBmb3IgZiBpbiBGT1JNQVRPUy52
:::YWx1ZXMoKV0sCiAgICAgICAgICAgICAgICBzdGF0ZT0ncmVhZG9ubHknLCBmb250
:::PUZVRU5URV9VSSwgc3R5bGU9J2d4LlRDb21ib2JveCcpCiAgICAgICAgICAgIHNl
:::bGYuY21iX2Zvcm1hdG8uZ3JpZChyb3c9MCwgY29sdW1uPTEsIHN0aWNreT0nZXcn
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFkeD04LCBwYWR5
:::PTUsIGlwYWR5PTIpCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfY2FsJ10gPSB0
:::ay5MYWJlbChnZiwgdGV4dD0nQ2FsaWRhZDonLCBmb250PUZVRU5URV9VSSkKICAg
:::ICAgICAgICAgc2VsZi5fd2dbJ2xibF9jYWwnXS5ncmlkKHJvdz0xLCBjb2x1bW49
:::MCwgc3RpY2t5PSd3JywgcGFkeD04LCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYu
:::Y21iX2NhbGlkYWQgPSB0dGsuQ29tYm9ib3goCiAgICAgICAgICAgICAgICBnZiwg
:::c3RhdGU9J3JlYWRvbmx5JywgZm9udD1GVUVOVEVfVUksIHN0eWxlPSdneC5UQ29t
:::Ym9ib3gnKQogICAgICAgICAgICBzZWxmLmNtYl9jYWxpZGFkLmdyaWQocm93PTEs
:::IGNvbHVtbj0xLCBzdGlja3k9J2V3JywKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgIHBhZHg9OCwgcGFkeT01LCBpcGFkeT0yKQogICAgICAgICAgICBz
:::ZWxmLl93Z1snbGJsX2NhciddID0gdGsuTGFiZWwoZ2YsIHRleHQ9J0NhcnBldGE6
:::JywgZm9udD1GVUVOVEVfVUkpCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfY2Fy
:::J10uZ3JpZChyb3c9MiwgY29sdW1uPTAsIHN0aWNreT0ndycsIHBhZHg9OCwgcGFk
:::eT01KQogICAgICAgICAgICBmYyA9IHRrLkZyYW1lKGdmKQogICAgICAgICAgICBm
:::Yy5ncmlkKHJvdz0yLCBjb2x1bW49MSwgc3RpY2t5PSdldycsIHBhZHg9OCwgcGFk
:::eT01KQogICAgICAgICAgICBzZWxmLl93Z1snZmMnXSA9IGZjCiAgICAgICAgICAg
:::IGZjLmNvbHVtbmNvbmZpZ3VyZSgwLCB3ZWlnaHQ9MSkKICAgICAgICAgICAgc2Vs
:::Zi5lbnRfY2FycGV0YSA9IHRrLkVudHJ5KGZjLCBmb250PUZVRU5URV9VSSwgcmVs
:::aWVmPSdmbGF0JywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIGhpZ2hsaWdodHRoaWNrbmVzcz0xKQogICAgICAgICAgICBzZWxmLmVudF9j
:::YXJwZXRhLmdyaWQocm93PTAsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgaXBhZHk9
:::NCkKICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5pbnNlcnQoMCwgQUpVU1RF
:::U1snZGVzdGlubyddKQogICAgICAgICAgICBzZWxmLmJ0bl9jYW1iaWFyID0gc2Vs
:::Zi5fYm90b24oZmMsICdDYW1iaWFyLi4uJywgc2VsZi5fY2FtYmlhcl9jYXJwZXRh
:::KQogICAgICAgICAgICBzZWxmLmJ0bl9jYW1iaWFyLmdyaWQocm93PTAsIGNvbHVt
:::bj0xLCBwYWR4PSg4LCAwKSwgaXBhZHk9MykKICAgICAgICAgICAgc2VsZi5idG5f
:::YWJyaXIgPSBzZWxmLl9ib3RvbihmYywgJ0FicmlyJywgc2VsZi5fYWJyaXJfZGVz
:::dGlubywgd2lkdGg9NSkKICAgICAgICAgICAgc2VsZi5idG5fYWJyaXIuZ3JpZChy
:::b3c9MCwgY29sdW1uPTIsIHBhZHg9KDYsIDApLCBpcGFkeT0zKQoKICAgICAgICAg
:::ICAgc2VsZi52YXJfZW1iZWJlciA9IHRrLkJvb2xlYW5WYXIodmFsdWU9Ym9vbChB
:::SlVTVEVTLmdldCgnZW1iZWJlcicsIFRydWUpKSkKICAgICAgICAgICAgc2VsZi5j
:::aGtfZW1iZWJlciA9IHRrLkNoZWNrYnV0dG9uKAogICAgICAgICAgICAgICAgZ2Ys
:::IHRleHQ9J0VtYmViZXIgY2Fyw6F0dWxhLCBhcnRpc3RhIHkgw6FsYnVtJywKICAg
:::ICAgICAgICAgICAgIHZhcmlhYmxlPXNlbGYudmFyX2VtYmViZXIsIGZvbnQ9RlVF
:::TlRFX1VJLCBhbmNob3I9J3cnLAogICAgICAgICAgICAgICAgcmVsaWVmPSdmbGF0
:::JywgaGlnaGxpZ2h0dGhpY2tuZXNzPTAsIGJkPTApCiAgICAgICAgICAgIHNlbGYu
:::Y2hrX2VtYmViZXIuZ3JpZChyb3c9MywgY29sdW1uPTAsIGNvbHVtbnNwYW49MiwK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0aWNreT0nZXcnLCBw
:::YWR4PTgsIHBhZHk9KDIsIDYpKQoKICAgICAgICAgICAgIyAtLS0gZ3J1cG86IGVz
:::dGltYWNpw7NuIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0KICAgICAgICAgICAgZ2UgPSB0ay5MYWJlbEZyYW1lKG1hcmNvLCB0ZXh0PSdF
:::c3RpbWFjacOzbicsIGZvbnQ9RlVFTlRFX1VJLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgcmVsaWVmPSdzb2xpZCcsIGJkPTEpCiAgICAgICAgICAgIGdl
:::LmdyaWQocm93PTMsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgcGFkeT01KQogICAg
:::ICAgICAgICBzZWxmLl93Z1snZ2UnXSA9IGdlCiAgICAgICAgICAgIGdlLmNvbHVt
:::bmNvbmZpZ3VyZSgwLCB3ZWlnaHQ9MSkKICAgICAgICAgICAgc2VsZi5sYmxfZXN0
:::aW1hY2lvbiA9IHRrLkxhYmVsKAogICAgICAgICAgICAgICAgZ2UsIHRleHQ9J0lu
:::dHJvZHVjZSB1bmEgVVJMIHkgcHVsc2EgRXN0aW1hci4nLAogICAgICAgICAgICAg
:::ICAgZm9udD1GVUVOVEVfVUksIGFuY2hvcj0ndycpCiAgICAgICAgICAgIHNlbGYu
:::bGJsX2VzdGltYWNpb24uZ3JpZChyb3c9MCwgY29sdW1uPTAsIHN0aWNreT0nZXcn
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFkeD04LCBw
:::YWR5PTYpCiAgICAgICAgICAgIHNlbGYuYnRuX2VzdGltYXIgPSBzZWxmLl9ib3Rv
:::bihnZSwgJ0VzdGltYXIgdGFtYW5vJywKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgIHNlbGYuX2FjY2lvbl9lc3RpbWFyKQogICAgICAg
:::ICAgICBzZWxmLmJ0bl9lc3RpbWFyLmdyaWQocm93PTAsIGNvbHVtbj0xLCBzdGlj
:::a3k9J2UnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFkeD04
:::LCBpcGFkeT0zKQoKICAgICAgICAgICAgIyAtLS0gYm90b25lcyBncmFuZGVzIC0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAg
:::ICAgICBzZWxmLmJ0bl9kZXNjYXJnYXIgPSBzZWxmLl9ib3RvbihtYXJjbywgJ0Rl
:::c2NhcmdhciB5IGNvbnZlcnRpcicsCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgIHNlbGYuX2FjY2lvbl9kZXNjYXJnYXIsCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGZ1ZW50ZT1G
:::VUVOVEVfQlROX0csIGFsdG89MikKICAgICAgICAgICAgc2VsZi5idG5fZGVzY2Fy
:::Z2FyLmdyaWQocm93PTQsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgcGFkeT0oNywg
:::NCkpCiAgICAgICAgICAgIHNlbGYuYnRuX2NvbXByb2JhciA9IHNlbGYuX2JvdG9u
:::KAogICAgICAgICAgICAgICAgbWFyY28sICdDb21wcm9iYXIgY2FsaWRhZCBkZSBs
:::YSBjYXJwZXRhJywKICAgICAgICAgICAgICAgIHNlbGYuX2FjY2lvbl9jb21wcm9i
:::YXIsIGZ1ZW50ZT1GVUVOVEVfQlROKQogICAgICAgICAgICBzZWxmLmJ0bl9jb21w
:::cm9iYXIuZ3JpZChyb3c9NSwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PTMp
:::CgogICAgICAgICAgICAjIC0tLSBlc3RhZG8gKyBiYXJyYSBkZSBwcm9ncmVzbyAt
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAgICAgICBzZWxm
:::LmxibF9lc3RhZG8gPSB0ay5MYWJlbChtYXJjbywgdGV4dD0nJywgZm9udD1GVUVO
:::VEVfVUksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGFu
:::Y2hvcj0ndycpCiAgICAgICAgICAgIHNlbGYubGJsX2VzdGFkby5ncmlkKHJvdz02
:::LCBjb2x1bW49MCwgc3RpY2t5PSdldycsIHBhZHk9KDQsIDApKQogICAgICAgICAg
:::ICBzZWxmLmJhcnJhID0gdHRrLlByb2dyZXNzYmFyKAogICAgICAgICAgICAgICAg
:::bWFyY28sIG1heGltdW09MTAwLCBzdHlsZT0nZ3guSG9yaXpvbnRhbC5UUHJvZ3Jl
:::c3NiYXInKQogICAgICAgICAgICBzZWxmLmJhcnJhLmdyaWQocm93PTcsIGNvbHVt
:::bj0wLCBzdGlja3k9J2V3JywgcGFkeT0oMiwgNCkpCgogICAgICAgICAgICAjIC0t
:::LSByZWdpc3RybyAobG9nKSAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLQogICAgICAgICAgICBzZWxmLnR4dF9sb2cgPSBTY3JvbGxl
:::ZFRleHQobWFyY28sIGZvbnQ9RlVFTlRFX0xPRywgaGVpZ2h0PTEyLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVsaWVmPSdmbGF0Jywg
:::YmQ9MCwgd3JhcD0nd29yZCcsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICBzdGF0ZT0nZGlzYWJsZWQnKQogICAgICAgICAgICBzZWxmLnR4
:::dF9sb2cuZ3JpZChyb3c9OCwgY29sdW1uPTAsIHN0aWNreT0nbnNldycpCiAgICAg
:::ICAgICAgIG1hcmNvLnJvd2NvbmZpZ3VyZSg4LCB3ZWlnaHQ9MSkKICAgICAgICAg
:::ICAgZm9yIHRhZywgY29uZiBpbiAoCiAgICAgICAgICAgICAgICAgICAgKCdpbmZv
:::Jywge30pLAogICAgICAgICAgICAgICAgICAgICgnZ3JpcycsIHt9KSwKICAgICAg
:::ICAgICAgICAgICAgICAoJ3RpdHVsbycsIHt9KSwKICAgICAgICAgICAgICAgICAg
:::ICAoJ29rJywge30pLAogICAgICAgICAgICAgICAgICAgICgnYXZpc28nLCB7fSks
:::CiAgICAgICAgICAgICAgICAgICAgKCdlcnJvcicsIHt9KSk6CiAgICAgICAgICAg
:::ICAgICBzZWxmLnR4dF9sb2cudGFnX2NvbmZpZ3VyZSh0YWcsIGNvbmYpCgogICAg
:::ICAgICAgICAjIHNpbmNyb25pemFyIHZhbG9yZXMgZ3VhcmRhZG9zCiAgICAgICAg
:::ICAgIGZtdCA9IEFKVVNURVMuZ2V0KCdmb3JtYXRvJywgJ0FBQycpCiAgICAgICAg
:::ICAgIGlmIGZtdCBub3QgaW4gRk9STUFUT1M6CiAgICAgICAgICAgICAgICBmbXQg
:::PSAnQUFDJwogICAgICAgICAgICBzZWxmLmNtYl9mb3JtYXRvLnNldChGT1JNQVRP
:::U1tmbXRdWyd0ZXh0byddKQogICAgICAgICAgICBzZWxmLl9yZWNhcmdhcl9jYWxp
:::ZGFkZXMoZm10LCBBSlVTVEVTLmdldCgnY2FsaWRhZCcpKQoKICAgICAgICAjIC0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBo
:::ZWxwZXJzIHdpZGdldHMKICAgICAgICBkZWYgX2JvdG9uKHNlbGYsIHBhZHJlLCB0
:::ZXh0bywgY21kLCB3aWR0aD1Ob25lLCBmdWVudGU9RlVFTlRFX0JUTiwKICAgICAg
:::ICAgICAgICAgICAgIGFsdG89MSk6CiAgICAgICAgICAgIGIgPSB0ay5CdXR0b24o
:::cGFkcmUsIHRleHQ9dGV4dG8sIGNvbW1hbmQ9Y21kLCBmb250PWZ1ZW50ZSwKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICByZWxpZWY9J2ZsYXQnLCBiZD0wLCBjdXJz
:::b3I9J2hhbmQyJywgaGVpZ2h0PWFsdG8sCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgYWN0aXZlZm9yZWdyb3VuZD0nI2ZmZmZmZicsIHRha2Vmb2N1cz0wKQogICAg
:::ICAgICAgICBpZiB3aWR0aDoKICAgICAgICAgICAgICAgIGIuY29uZmlndXJlKHdp
:::ZHRoPXdpZHRoKQogICAgICAgICAgICBiLmJpbmQoJzxFbnRlcj4nLCBsYW1iZGEg
:::ZSwgdz1iOiB3LmNvbmZpZ3VyZSgKICAgICAgICAgICAgICAgIGJnPVRFTUFTW3Nl
:::bGYuX3RlbWFfYWN0dWFsXVsnYm90b25fYWN0J10pKQogICAgICAgICAgICBiLmJp
:::bmQoJzxMZWF2ZT4nLCBsYW1iZGEgZSwgdz1iOiB3LmNvbmZpZ3VyZSgKICAgICAg
:::ICAgICAgICAgIGJnPVRFTUFTW3NlbGYuX3RlbWFfYWN0dWFsXVsnYm90b24nXSkp
:::CiAgICAgICAgICAgIHNlbGYuX2J0bnMuYXBwZW5kKGIpCiAgICAgICAgICAgIHJl
:::dHVybiBiCgogICAgICAgIGRlZiBfcG9uZXJfcGxhY2Vob2xkZXIoc2VsZik6CiAg
:::ICAgICAgICAgIGlmIG5vdCBzZWxmLmVudF91cmwuZ2V0KCk6CiAgICAgICAgICAg
:::ICAgICBzZWxmLl9lbl9wbGFjZWhvbGRlciA9IFRydWUKICAgICAgICAgICAgICAg
:::IHNlbGYuZW50X3VybC5pbnNlcnQoMCwgUExBQ0VIT0xERVJfVVJMKQoKICAgICAg
:::ICBkZWYgX2xpbXBpYXJfdXJsKHNlbGYpOgogICAgICAgICAgICBzZWxmLmVudF91
:::cmwuZGVsZXRlKDAsICdlbmQnKQogICAgICAgICAgICBzZWxmLmVudF91cmwuZm9j
:::dXNfc2V0KCkKCiAgICAgICAgZGVmIF9yZXNldF91cmwoc2VsZik6CiAgICAgICAg
:::ICAgICIiIkRlamEgZWwgY2FtcG8gZGUgVVJMIHZhY8OtbyBjb24gc3UgcGxhY2Vo
:::b2xkZXIgKHRyYXMgdW4gw6l4aXRvKS4iIiIKICAgICAgICAgICAgc2VsZi5lbnRf
:::dXJsLmRlbGV0ZSgwLCAnZW5kJykKICAgICAgICAgICAgc2VsZi5fZW5fcGxhY2Vo
:::b2xkZXIgPSBUcnVlCiAgICAgICAgICAgIHNlbGYuX3BvbmVyX3BsYWNlaG9sZGVy
:::KCkKICAgICAgICAgICAgc2VsZi5fcmVmcmVzY2FyX3BsYWNlaG9sZGVyKCkKCiAg
:::ICAgICAgIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0gdGVtYQogICAgICAgIGRlZiBfYXBsaWNhcl90ZW1hKHNlbGYpOgog
:::ICAgICAgICAgICB0ID0gVEVNQVNbc2VsZi5fdGVtYV9hY3R1YWxdCiAgICAgICAg
:::ICAgIHcgPSBzZWxmLl93ZwogICAgICAgICAgICBzZWxmLmNvbmZpZ3VyZShiZz10
:::Wydmb25kbyddKQogICAgICAgICAgICBmb3Igbm9tYnJlIGluICgnbWFyY28nLCAn
:::ZjAnLCAnZ3UnLCAnZ2YnLCAnZmMnLCAnZ2UnKToKICAgICAgICAgICAgICAgIHdb
:::bm9tYnJlXS5jb25maWd1cmUoYmc9dFsnZm9uZG8nXSkKICAgICAgICAgICAgZm9y
:::IGxmIGluICh3WydndSddLCB3WydnZiddLCB3WydnZSddKToKICAgICAgICAgICAg
:::ICAgIGxmLmNvbmZpZ3VyZShiZz10Wydmb25kbyddLCBmZz10Wyd0ZXh0bzInXSkK
:::ICAgICAgICAgICAgZm9yIG5vbWJyZSBpbiAoJ2xibF90ZW1hJywgJ2xibF9mbXQn
:::LCAnbGJsX2NhbCcsICdsYmxfY2FyJyk6CiAgICAgICAgICAgICAgICB3W25vbWJy
:::ZV0uY29uZmlndXJlKGJnPXRbJ2ZvbmRvJ10sIGZnPXRbJ3RleHRvJ10pCiAgICAg
:::ICAgICAgIHNlbGYubGJsX2VzdGltYWNpb24uY29uZmlndXJlKGJnPXRbJ2ZvbmRv
:::J10sIGZnPXRbJ3RleHRvJ10pCiAgICAgICAgICAgIHNlbGYubGJsX2VzdGFkby5j
:::b25maWd1cmUoYmc9dFsnZm9uZG8nXSwgZmc9dFsndGV4dG8yJ10pCiAgICAgICAg
:::ICAgIHNlbGYuZW50X3VybC5jb25maWd1cmUoCiAgICAgICAgICAgICAgICBiZz10
:::WydjYW1wbyddLCBmZz10Wyd0ZXh0byddLCBpbnNlcnRiYWNrZ3JvdW5kPXRbJ3Rl
:::eHRvJ10sCiAgICAgICAgICAgICAgICBoaWdobGlnaHRiYWNrZ3JvdW5kPXRbJ2Nh
:::bXBvX2JvcmRlJ10sCiAgICAgICAgICAgICAgICBoaWdobGlnaHRjb2xvcj10Wydh
:::Y2VudG8nXSwKICAgICAgICAgICAgICAgIGRpc2FibGVkYmFja2dyb3VuZD10Wydj
:::YW1wbyddLCBkaXNhYmxlZGZvcmVncm91bmQ9dFsndGV4dG8yJ10pCiAgICAgICAg
:::ICAgIHNlbGYuZW50X2NhcnBldGEuY29uZmlndXJlKAogICAgICAgICAgICAgICAg
:::Ymc9dFsnY2FtcG8nXSwgZmc9dFsndGV4dG8nXSwgaW5zZXJ0YmFja2dyb3VuZD10
:::Wyd0ZXh0byddLAogICAgICAgICAgICAgICAgaGlnaGxpZ2h0YmFja2dyb3VuZD10
:::WydjYW1wb19ib3JkZSddLAogICAgICAgICAgICAgICAgaGlnaGxpZ2h0Y29sb3I9
:::dFsnYWNlbnRvJ10pCiAgICAgICAgICAgIHNlbGYuY2hrX2VtYmViZXIuY29uZmln
:::dXJlKAogICAgICAgICAgICAgICAgYmc9dFsnZm9uZG8nXSwgZmc9dFsndGV4dG8n
:::XSwgYWN0aXZlYmFja2dyb3VuZD10Wydmb25kbyddLAogICAgICAgICAgICAgICAg
:::YWN0aXZlZm9yZWdyb3VuZD10Wyd0ZXh0byddLCBzZWxlY3Rjb2xvcj10WydjYW1w
:::byddKQogICAgICAgICAgICBmb3IgYiBpbiBzZWxmLl9idG5zOgogICAgICAgICAg
:::ICAgICAgYi5jb25maWd1cmUoYmc9dFsnYm90b24nXSwgZmc9dFsnYm90b25fdHh0
:::J10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBhY3RpdmViYWNrZ3JvdW5k
:::PXRbJ2JvdG9uX2FjdCddLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgYWN0
:::aXZlZm9yZWdyb3VuZD10Wydib3Rvbl90eHQnXSkKICAgICAgICAgICAgc2VsZi50
:::eHRfbG9nLmNvbmZpZ3VyZShiZz10Wydsb2cnXSwgZmc9dFsnbG9nX3R4dCddLAog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGluc2VydGJhY2tncm91
:::bmQ9dFsnbG9nX3R4dCddKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cudGFnX2Nv
:::bmZpZ3VyZSgnaW5mbycsIGZvcmVncm91bmQ9dFsnbG9nX3R4dCddKQogICAgICAg
:::ICAgICBzZWxmLnR4dF9sb2cudGFnX2NvbmZpZ3VyZSgnZ3JpcycsIGZvcmVncm91
:::bmQ9dFsndGV4dG8yJ10pCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy50YWdfY29u
:::ZmlndXJlKCd0aXR1bG8nLCBmb3JlZ3JvdW5kPXRbJ3RleHRvJ10sCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGZvbnQ9KCdDb25zb2xhcycs
:::IDEwLCAnYm9sZCcpKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cudGFnX2NvbmZp
:::Z3VyZSgnb2snLCBmb3JlZ3JvdW5kPXRbJ29rJ10pCiAgICAgICAgICAgIHNlbGYu
:::dHh0X2xvZy50YWdfY29uZmlndXJlKCdhdmlzbycsIGZvcmVncm91bmQ9dFsnYXZp
:::c28nXSkKICAgICAgICAgICAgc2VsZi50eHRfbG9nLnRhZ19jb25maWd1cmUoJ2Vy
:::cm9yJywgZm9yZWdyb3VuZD10WydlcnJvciddKQogICAgICAgICAgICBlc3QgPSBz
:::ZWxmLl9lc3RpbG8KICAgICAgICAgICAgZXN0LmNvbmZpZ3VyZSgnZ3guVENvbWJv
:::Ym94JywKICAgICAgICAgICAgICAgICAgICAgICAgICBmaWVsZGJhY2tncm91bmQ9
:::dFsnY2FtcG8nXSwgYmFja2dyb3VuZD10Wydib3RvbiddLAogICAgICAgICAgICAg
:::ICAgICAgICAgICAgIGZvcmVncm91bmQ9dFsndGV4dG8nXSwgYXJyb3djb2xvcj10
:::Wyd0ZXh0byddLAogICAgICAgICAgICAgICAgICAgICAgICAgIGJvcmRlcmNvbG9y
:::PXRbJ2NhbXBvX2JvcmRlJ10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgbGln
:::aHRjb2xvcj10WydjYW1wb19ib3JkZSddLAogICAgICAgICAgICAgICAgICAgICAg
:::ICAgIGRhcmtjb2xvcj10WydjYW1wb19ib3JkZSddLAogICAgICAgICAgICAgICAg
:::ICAgICAgICAgIGluc2VydGNvbG9yPXRbJ3RleHRvJ10pCiAgICAgICAgICAgIGVz
:::dC5tYXAoJ2d4LlRDb21ib2JveCcsCiAgICAgICAgICAgICAgICAgICAgZmllbGRi
:::YWNrZ3JvdW5kPVsoJ3JlYWRvbmx5JywgdFsnY2FtcG8nXSldLAogICAgICAgICAg
:::ICAgICAgICAgIGZvcmVncm91bmQ9WygncmVhZG9ubHknLCB0Wyd0ZXh0byddKV0p
:::CiAgICAgICAgICAgIGVzdC5jb25maWd1cmUoJ2d4Lkhvcml6b250YWwuVFByb2dy
:::ZXNzYmFyJywKICAgICAgICAgICAgICAgICAgICAgICAgICB0cm91Z2hjb2xvcj10
:::Wyd0cm91Z2gnXSwgYmFja2dyb3VuZD10WydhY2VudG8nXSwKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICBib3JkZXJjb2xvcj10Wydmb25kbyddLCBsaWdodGNvbG9y
:::PXRbJ2FjZW50byddLAogICAgICAgICAgICAgICAgICAgICAgICAgIGRhcmtjb2xv
:::cj10WydhY2VudG8nXSkKICAgICAgICAgICAgc2VsZi5vcHRpb25fYWRkKCcqVENv
:::bWJvYm94Kkxpc3Rib3guYmFja2dyb3VuZCcsIHRbJ2NhbXBvJ10pCiAgICAgICAg
:::ICAgIHNlbGYub3B0aW9uX2FkZCgnKlRDb21ib2JveCpMaXN0Ym94LmZvcmVncm91
:::bmQnLCB0Wyd0ZXh0byddKQogICAgICAgICAgICBzZWxmLm9wdGlvbl9hZGQoJypU
:::Q29tYm9ib3gqTGlzdGJveC5zZWxlY3RCYWNrZ3JvdW5kJywKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgIHRbJ2JvdG9uX2FjdCddKQogICAgICAgICAgICBzZWxm
:::Lm9wdGlvbl9hZGQoJypUQ29tYm9ib3gqTGlzdGJveC5zZWxlY3RGb3JlZ3JvdW5k
:::JywKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRbJ2JvdG9uX3R4dCddKQog
:::ICAgICAgICAgICBzZWxmLl9yZWZyZXNjYXJfcGxhY2Vob2xkZXIoKQoKICAgICAg
:::ICBkZWYgX3JlZnJlc2Nhcl9wbGFjZWhvbGRlcihzZWxmKToKICAgICAgICAgICAg
:::dCA9IFRFTUFTW3NlbGYuX3RlbWFfYWN0dWFsXQogICAgICAgICAgICBpZiBzZWxm
:::Ll9lbl9wbGFjZWhvbGRlcjoKICAgICAgICAgICAgICAgIHNlbGYuZW50X3VybC5j
:::b25maWd1cmUoZmc9dFsncGxhY2Vob2xkZXInXSkKICAgICAgICAgICAgZWxzZToK
:::ICAgICAgICAgICAgICAgIHNlbGYuZW50X3VybC5jb25maWd1cmUoZmc9dFsndGV4
:::dG8nXSkKCiAgICAgICAgIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0gZXZlbnRvcwogICAgICAgIGRlZiBfY29uZWN0YXJf
:::ZXZlbnRvcyhzZWxmKToKICAgICAgICAgICAgc2VsZi5jbWJfdGVtYS5iaW5kKCc8
:::PENvbWJvYm94U2VsZWN0ZWQ+PicsIHNlbGYuX29uX3RlbWEpCiAgICAgICAgICAg
:::IHNlbGYuY21iX2Zvcm1hdG8uYmluZCgnPDxDb21ib2JveFNlbGVjdGVkPj4nLCBz
:::ZWxmLl9vbl9mb3JtYXRvKQogICAgICAgICAgICBzZWxmLmNtYl9jYWxpZGFkLmJp
:::bmQoJzw8Q29tYm9ib3hTZWxlY3RlZD4+JywgbGFtYmRhIGU6IHNlbGYuX2d1YXJk
:::YXIoKSkKICAgICAgICAgICAgc2VsZi5jaGtfZW1iZWJlci5jb25maWd1cmUoY29t
:::bWFuZD1zZWxmLl9ndWFyZGFyKQogICAgICAgICAgICBzZWxmLmVudF91cmwuYmlu
:::ZCgnPEZvY3VzSW4+Jywgc2VsZi5fb25fZm9jdXNfdXJsX2luKQogICAgICAgICAg
:::ICBzZWxmLmVudF91cmwuYmluZCgnPEZvY3VzT3V0PicsIHNlbGYuX29uX2ZvY3Vz
:::X3VybF9vdXQpCiAgICAgICAgICAgIHNlbGYuZW50X3VybC5iaW5kKCc8UmV0dXJu
:::PicsIGxhbWJkYSBlOiBzZWxmLl9hY2Npb25fZGVzY2FyZ2FyKCkpCiAgICAgICAg
:::ICAgIHNlbGYuZW50X2NhcnBldGEuYmluZCgnPEZvY3VzT3V0PicsIHNlbGYuX29u
:::X2NhcnBldGFfZXNjcml0YSkKICAgICAgICAgICAgc2VsZi5wcm90b2NvbCgnV01f
:::REVMRVRFX1dJTkRPVycsIHNlbGYuX2FsX2NlcnJhcikKICAgICAgICAgICAgc2Vs
:::Zi5iaW5kKCc8Q29udHJvbC11PicsIGxhbWJkYSBlOiBzZWxmLl9hY2Npb25fYWN0
:::dWFsaXphcigpKQogICAgICAgICAgICBzZWxmLmJpbmQoJzxDb250cm9sLWw+Jywg
:::bGFtYmRhIGU6IHNlbGYuX2xpbXBpYXJfbG9nKCkpCiAgICAgICAgICAgIHNlbGYu
:::YmluZCgnPENvbnRyb2wtVT4nLCBsYW1iZGEgZTogc2VsZi5fYWNjaW9uX2FjdHVh
:::bGl6YXIoKSkKCiAgICAgICAgZGVmIF9vbl9mb2N1c191cmxfaW4oc2VsZiwgX2U9
:::Tm9uZSk6CiAgICAgICAgICAgIGlmIHNlbGYuX2VuX3BsYWNlaG9sZGVyOgogICAg
:::ICAgICAgICAgICAgc2VsZi5lbnRfdXJsLmRlbGV0ZSgwLCAnZW5kJykKICAgICAg
:::ICAgICAgICAgIHNlbGYuX2VuX3BsYWNlaG9sZGVyID0gRmFsc2UKICAgICAgICAg
:::ICAgICAgIHNlbGYuX3JlZnJlc2Nhcl9wbGFjZWhvbGRlcigpCgogICAgICAgIGRl
:::ZiBfb25fZm9jdXNfdXJsX291dChzZWxmLCBfZT1Ob25lKToKICAgICAgICAgICAg
:::aWYgbm90IHNlbGYuZW50X3VybC5nZXQoKToKICAgICAgICAgICAgICAgIHNlbGYu
:::X2VuX3BsYWNlaG9sZGVyID0gVHJ1ZQogICAgICAgICAgICAgICAgc2VsZi5fcG9u
:::ZXJfcGxhY2Vob2xkZXIoKQogICAgICAgICAgICAgICAgc2VsZi5fcmVmcmVzY2Fy
:::X3BsYWNlaG9sZGVyKCkKCiAgICAgICAgZGVmIF9vbl90ZW1hKHNlbGYsIF9lPU5v
:::bmUpOgogICAgICAgICAgICBzZWxmLl90ZW1hX2FjdHVhbCA9IHNlbGYuY21iX3Rl
:::bWEuZ2V0KCkKICAgICAgICAgICAgQUpVU1RFU1sndGVtYSddID0gc2VsZi5fdGVt
:::YV9hY3R1YWwKICAgICAgICAgICAgZ3VhcmRhcl9hanVzdGVzKCkKICAgICAgICAg
:::ICAgc2VsZi5fYXBsaWNhcl90ZW1hKCkKCiAgICAgICAgZGVmIF9vbl9mb3JtYXRv
:::KHNlbGYsIF9lPU5vbmUpOgogICAgICAgICAgICBmbXQgPSBzZWxmLl9mbXRfYWN0
:::dWFsKCkKICAgICAgICAgICAgc2VsZi5fcmVjYXJnYXJfY2FsaWRhZGVzKGZtdCkK
:::ICAgICAgICAgICAgc2VsZi5fZ3VhcmRhcigpCiAgICAgICAgICAgIHNlbGYubGJs
:::X2VzdGltYWNpb24uY29uZmlndXJlKAogICAgICAgICAgICAgICAgdGV4dD0nSW50
:::cm9kdWNlIHVuYSBVUkwgeSBwdWxzYSBFc3RpbWFyLicsCiAgICAgICAgICAgICAg
:::ICBmZz1URU1BU1tzZWxmLl90ZW1hX2FjdHVhbF1bJ3RleHRvJ10pCgogICAgICAg
:::IGRlZiBfZm10X2FjdHVhbChzZWxmKToKICAgICAgICAgICAgdGV4dG8gPSBzZWxm
:::LmNtYl9mb3JtYXRvLmdldCgpCiAgICAgICAgICAgIGZvciBjbGF2ZSwgZiBpbiBG
:::T1JNQVRPUy5pdGVtcygpOgogICAgICAgICAgICAgICAgaWYgZlsndGV4dG8nXSA9
:::PSB0ZXh0bzoKICAgICAgICAgICAgICAgICAgICByZXR1cm4gY2xhdmUKICAgICAg
:::ICAgICAgcmV0dXJuICdBQUMnCgogICAgICAgIGRlZiBfcmVjYXJnYXJfY2FsaWRh
:::ZGVzKHNlbGYsIGNsYXZlX2ZtdCwgY2FsaWRhZF9wcmV2aWE9Tm9uZSk6CiAgICAg
:::ICAgICAgIGYgPSBGT1JNQVRPU1tjbGF2ZV9mbXRdCiAgICAgICAgICAgIHNlbGYu
:::Y21iX2NhbGlkYWRbJ3ZhbHVlcyddID0gZlsnY2FsaWRhZGVzJ10KICAgICAgICAg
:::ICAgaWYgY2FsaWRhZF9wcmV2aWEgYW5kIGNhbGlkYWRfcHJldmlhIGluIGZbJ2Nh
:::bGlkYWRlcyddOgogICAgICAgICAgICAgICAgc2VsZi5jbWJfY2FsaWRhZC5zZXQo
:::Y2FsaWRhZF9wcmV2aWEpCiAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAg
:::ICBzZWxmLmNtYl9jYWxpZGFkLnNldChmWydkZWZlY3RvJ10pCiAgICAgICAgICAg
:::IEFKVVNURVNbJ2Zvcm1hdG8nXSA9IGNsYXZlX2ZtdAogICAgICAgICAgICBBSlVT
:::VEVTWydjYWxpZGFkJ10gPSBzZWxmLmNtYl9jYWxpZGFkLmdldCgpCgogICAgICAg
:::IGRlZiBfZ3VhcmRhcihzZWxmKToKICAgICAgICAgICAgQUpVU1RFU1snZm9ybWF0
:::byddID0gc2VsZi5fZm10X2FjdHVhbCgpCiAgICAgICAgICAgIEFKVVNURVNbJ2Nh
:::bGlkYWQnXSA9IHNlbGYuY21iX2NhbGlkYWQuZ2V0KCkKICAgICAgICAgICAgQUpV
:::U1RFU1snZW1iZWJlciddID0gYm9vbChzZWxmLnZhcl9lbWJlYmVyLmdldCgpKQog
:::ICAgICAgICAgICBBSlVTVEVTWydkZXN0aW5vJ10gPSBzZWxmLmVudF9jYXJwZXRh
:::LmdldCgpLnN0cmlwKCkKICAgICAgICAgICAgZ3VhcmRhcl9hanVzdGVzKCkKCiAg
:::ICAgICAgZGVmIF9vbl9jYXJwZXRhX2VzY3JpdGEoc2VsZiwgX2U9Tm9uZSk6CiAg
:::ICAgICAgICAgIHAgPSBQYXRoKG9zLnBhdGguZXhwYW5kdmFycygKICAgICAgICAg
:::ICAgICAgIHNlbGYuZW50X2NhcnBldGEuZ2V0KCkuc3RyaXAoKS5zdHJpcCgnIicp
:::KSkKICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgcC5ta2RpcihwYXJl
:::bnRzPVRydWUsIGV4aXN0X29rPVRydWUpCiAgICAgICAgICAgICAgICBBSlVTVEVT
:::WydkZXN0aW5vJ10gPSBzdHIocCkKICAgICAgICAgICAgICAgIGd1YXJkYXJfYWp1
:::c3RlcygpCiAgICAgICAgICAgIGV4Y2VwdCBPU0Vycm9yIGFzIGU6CiAgICAgICAg
:::ICAgICAgICBzZWxmLl9sb2coZidObyBzZSBwdWRvIHVzYXIgZXNhIGNhcnBldGE6
:::IHtlfScsICdlcnJvcicpCgogICAgICAgIGRlZiBfY2FtYmlhcl9jYXJwZXRhKHNl
:::bGYpOgogICAgICAgICAgICBhY3R1YWwgPSBzZWxmLmVudF9jYXJwZXRhLmdldCgp
:::LnN0cmlwKCkgb3IgQUpVU1RFU1snZGVzdGlubyddCiAgICAgICAgICAgIG51ZXZh
:::ID0gZmlsZWRpYWxvZy5hc2tkaXJlY3RvcnkoCiAgICAgICAgICAgICAgICB0aXRs
:::ZT0nRWxpZ2UgbGEgY2FycGV0YSBkb25kZSBndWFyZGFyIGxhcyBkZXNjYXJnYXMn
:::LAogICAgICAgICAgICAgICAgaW5pdGlhbGRpcj1hY3R1YWwgaWYgb3MucGF0aC5p
:::c2RpcihhY3R1YWwpIGVsc2Ugc3RyKFBhdGguaG9tZSgpKSkKICAgICAgICAgICAg
:::aWYgbm90IG51ZXZhOgogICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAg
:::IHRyeToKICAgICAgICAgICAgICAgIFBhdGgobnVldmEpLm1rZGlyKHBhcmVudHM9
:::VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgICAgICAgICAgZXhjZXB0IE9TRXJyb3Ig
:::YXMgZToKICAgICAgICAgICAgICAgIG1lc3NhZ2Vib3guc2hvd2Vycm9yKCdDYXJw
:::ZXRhIG5vIHbDoWxpZGEnLCBzdHIoZSkpCiAgICAgICAgICAgICAgICByZXR1cm4K
:::ICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5kZWxldGUoMCwgJ2VuZCcpCiAg
:::ICAgICAgICAgIHNlbGYuZW50X2NhcnBldGEuaW5zZXJ0KDAsIG51ZXZhKQogICAg
:::ICAgICAgICBBSlVTVEVTWydkZXN0aW5vJ10gPSBudWV2YQogICAgICAgICAgICBn
:::dWFyZGFyX2FqdXN0ZXMoKQogICAgICAgICAgICBzZWxmLl9sb2coJ0NhcnBldGEg
:::ZGUgZ3VhcmRhZG86ICcgKyBudWV2YSwgJ2dyaXMnKQoKICAgICAgICBkZWYgX2Fi
:::cmlyX2Rlc3Rpbm8oc2VsZik6CiAgICAgICAgICAgIHAgPSBQYXRoKG9zLnBhdGgu
:::ZXhwYW5kdmFycygKICAgICAgICAgICAgICAgIHNlbGYuZW50X2NhcnBldGEuZ2V0
:::KCkuc3RyaXAoKS5zdHJpcCgnIicpKSkKICAgICAgICAgICAgdHJ5OgogICAgICAg
:::ICAgICAgICAgcC5ta2RpcihwYXJlbnRzPVRydWUsIGV4aXN0X29rPVRydWUpCiAg
:::ICAgICAgICAgIGV4Y2VwdCBPU0Vycm9yOgogICAgICAgICAgICAgICAgcGFzcwog
:::ICAgICAgICAgICBhYnJpcl9jYXJwZXRhKHApCgogICAgICAgIGRlZiBfYWxfY2Vy
:::cmFyKHNlbGYpOgogICAgICAgICAgICBpZiBzZWxmLl9vY3VwYWRvIGFuZCBub3Qg
:::bWVzc2FnZWJveC5hc2tva2NhbmNlbCgKICAgICAgICAgICAgICAgICAgICAnU2Fs
:::aXInLCAnSGF5IHVuYSB0YXJlYSBlbiBjdXJzby4gJwogICAgICAgICAgICAgICAg
:::ICAgICfCv1NlZ3VybyBxdWUgcXVpZXJlcyBzYWxpcj8nKToKICAgICAgICAgICAg
:::ICAgIHJldHVybgogICAgICAgICAgICBzZWxmLmRlc3Ryb3koKQoKICAgICAgICAj
:::IC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LSByZWdpc3RybyAobG9nKQogICAgICAgIGRlZiBfbG9nKHNlbGYsIG1zZywgdGFn
:::PSdpbmZvJyk6CiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5jb25maWd1cmUoc3Rh
:::dGU9J25vcm1hbCcpCiAgICAgICAgICAgIG5fbGluZWFzID0gaW50KHNlbGYudHh0
:::X2xvZy5pbmRleCgnZW5kLTFjJykuc3BsaXQoJy4nKVswXSkKICAgICAgICAgICAg
:::aWYgbl9saW5lYXMgPiA5MDA6CiAgICAgICAgICAgICAgICBzZWxmLnR4dF9sb2cu
:::ZGVsZXRlKCcxLjAnLCAnMjAwLjAnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cu
:::aW5zZXJ0KCdlbmQnLCBzdHIobXNnKSArICdcbicsIHRhZykKICAgICAgICAgICAg
:::c2VsZi50eHRfbG9nLnNlZSgnZW5kJykKICAgICAgICAgICAgc2VsZi50eHRfbG9n
:::LmNvbmZpZ3VyZShzdGF0ZT0nZGlzYWJsZWQnKQoKICAgICAgICBkZWYgX2xpbXBp
:::YXJfbG9nKHNlbGYpOgogICAgICAgICAgICBzZWxmLnR4dF9sb2cuY29uZmlndXJl
:::KHN0YXRlPSdub3JtYWwnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuZGVsZXRl
:::KCcxLjAnLCAnZW5kJykKICAgICAgICAgICAgc2VsZi50eHRfbG9nLmNvbmZpZ3Vy
:::ZShzdGF0ZT0nZGlzYWJsZWQnKQoKICAgICAgICBkZWYgX2JvbWJlYXJfY29sYShz
:::ZWxmKToKICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgd2hpbGUgVHJ1
:::ZToKICAgICAgICAgICAgICAgICAgICBldiA9IHNlbGYuY29sYS5nZXRfbm93YWl0
:::KCkKICAgICAgICAgICAgICAgICAgICB0aXBvID0gZXZbMF0KICAgICAgICAgICAg
:::ICAgICAgICBpZiB0aXBvID09ICdsb2cnOgogICAgICAgICAgICAgICAgICAgICAg
:::ICBzZWxmLl9sb2coZXZbMV0sIGV2WzJdKQogICAgICAgICAgICAgICAgICAgIGVs
:::aWYgdGlwbyA9PSAncHJvZyc6CiAgICAgICAgICAgICAgICAgICAgICAgIHBjdCwg
:::dGV4dG8gPSBldlsxXSwgZXZbMl0KICAgICAgICAgICAgICAgICAgICAgICAgaWYg
:::cGN0IGlzIE5vbmU6CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzZWxmLmJh
:::cnJhLnN0b3AoKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5iYXJy
:::YS5jb25maWd1cmUobW9kZT0naW5kZXRlcm1pbmF0ZScpCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICBzZWxmLmJhcnJhLnN0YXJ0KDYwKQogICAgICAgICAgICAg
:::ICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgICAgICAgICAgc2Vs
:::Zi5iYXJyYS5zdG9wKCkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYu
:::YmFycmEuY29uZmlndXJlKG1vZGU9J2RldGVybWluYXRlJykKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgIHNlbGYuYmFycmEuY29uZmlndXJlKHZhbHVlPW1heCgw
:::LCBtaW4oMTAwLCBwY3QpKSkKICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5s
:::YmxfZXN0YWRvLmNvbmZpZ3VyZSh0ZXh0PXRleHRvKQogICAgICAgICAgICAgICAg
:::ICAgIGVsaWYgdGlwbyA9PSAnZXN0aW1hY2lvbic6CiAgICAgICAgICAgICAgICAg
:::ICAgICAgIHNlbGYubGJsX2VzdGltYWNpb24uY29uZmlndXJlKAogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgdGV4dD1ldlsxXSwgZmc9VEVNQVNbc2VsZi5fdGVt
:::YV9hY3R1YWxdWydhY2VudG8nXSkKICAgICAgICAgICAgICAgICAgICBlbGlmIHRp
:::cG8gPT0gJ2Zpbic6CiAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuX2Zpbl90
:::YXJlYShldlsxXSwgZXZbMl0sIGV2WzNdIGlmIGxlbihldikgPiAzIGVsc2UgJycp
:::CiAgICAgICAgICAgIGV4Y2VwdCBxdWV1ZS5FbXB0eToKICAgICAgICAgICAgICAg
:::IHBhc3MKICAgICAgICAgICAgc2VsZi5hZnRlcig4MCwgc2VsZi5fYm9tYmVhcl9j
:::b2xhKQoKICAgICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLSB0YXJlYXMKICAgICAgICBkZWYgX2hhYmlsaXRhcl9h
:::Y2Npb25lcyhzZWxmLCBvbik6CiAgICAgICAgICAgIGVzdGFkbyA9ICdub3JtYWwn
:::IGlmIG9uIGVsc2UgJ2Rpc2FibGVkJwogICAgICAgICAgICBmb3IgYiBpbiAoc2Vs
:::Zi5idG5fZGVzY2FyZ2FyLCBzZWxmLmJ0bl9jb21wcm9iYXIsCiAgICAgICAgICAg
:::ICAgICAgICAgICBzZWxmLmJ0bl9lc3RpbWFyLCBzZWxmLmJ0bl9jYW1iaWFyLCBz
:::ZWxmLmJ0bl9hYnJpciwKICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYnRuX3gp
:::OgogICAgICAgICAgICAgICAgYi5jb25maWd1cmUoc3RhdGU9ZXN0YWRvLCBjdXJz
:::b3I9J2hhbmQyJyBpZiBvbiBlbHNlICdhcnJvdycpCgogICAgICAgIGRlZiBfaW5p
:::Y2lhcihzZWxmLCBvYmpldGl2bywgY2ZnLCB0ZXh0byk6CiAgICAgICAgICAgIGlm
:::IHNlbGYuX29jdXBhZG86CiAgICAgICAgICAgICAgICBzZWxmLl9sb2coJ1lhIGhh
:::eSB1bmEgdGFyZWEgZW4gY3Vyc287IGVzcGVyYSBhIHF1ZSB0ZXJtaW5lLicsCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgJ2F2aXNvJykKICAgICAgICAgICAgICAg
:::IHJldHVybiBGYWxzZQogICAgICAgICAgICBzZWxmLl9vY3VwYWRvID0gVHJ1ZQog
:::ICAgICAgICAgICBzZWxmLl9oYWJpbGl0YXJfYWNjaW9uZXMoRmFsc2UpCiAgICAg
:::ICAgICAgIHNlbGYubGJsX2VzdGFkby5jb25maWd1cmUodGV4dD10ZXh0bykKICAg
:::ICAgICAgICAgdGhyZWFkaW5nLlRocmVhZCh0YXJnZXQ9b2JqZXRpdm8sIGFyZ3M9
:::KGNmZywpLCBkYWVtb249VHJ1ZSkuc3RhcnQoKQogICAgICAgICAgICByZXR1cm4g
:::VHJ1ZQoKICAgICAgICBkZWYgX2Zpbl90YXJlYShzZWxmLCB0aXBvLCBvaywgbWVu
:::c2FqZT0nJyk6CiAgICAgICAgICAgIHNlbGYuX29jdXBhZG8gPSBGYWxzZQogICAg
:::ICAgICAgICBzZWxmLl9oYWJpbGl0YXJfYWNjaW9uZXMoVHJ1ZSkKICAgICAgICAg
:::ICAgc2VsZi5iYXJyYS5zdG9wKCkKICAgICAgICAgICAgc2VsZi5iYXJyYS5jb25m
:::aWd1cmUobW9kZT0nZGV0ZXJtaW5hdGUnKQogICAgICAgICAgICBzZWxmLmJhcnJh
:::LmNvbmZpZ3VyZSh2YWx1ZT0wKQogICAgICAgICAgICBpZiB0aXBvID09ICdkZXNj
:::YXJnYScgYW5kIG9rOgogICAgICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmNv
:::bmZpZ3VyZSh0ZXh0PSdMaXN0by4nKQogICAgICAgICAgICAgICAgIyBMYSBkZXNj
:::YXJnYSBmdWUgYmllbjogc2UgbGltcGlhIGxhIFVSTCBwYXJhIGxhIHNpZ3VpZW50
:::ZS4KICAgICAgICAgICAgICAgIHNlbGYuX3Jlc2V0X3VybCgpCiAgICAgICAgICAg
:::IGVsaWYgbm90IG9rOgogICAgICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmNv
:::bmZpZ3VyZSh0ZXh0PSdUZXJtaW5hZG8gY29uIGVycm9yZXMuJykKICAgICAgICAg
:::ICAgICAgIGlmIHRpcG8gPT0gJ2Rlc2NhcmdhJzoKICAgICAgICAgICAgICAgICAg
:::ICBtZXNzYWdlYm94LnNob3dlcnJvcigKICAgICAgICAgICAgICAgICAgICAgICAg
:::J0Vycm9yJywgbWVuc2FqZSBvciAnTm8gc2UgcHVkbyBjb21wbGV0YXIgbGEgdGFy
:::ZWEuICcKICAgICAgICAgICAgICAgICAgICAgICAgJ1JldmlzYSBlbCByZWdpc3Ry
:::byBwYXJhIG3DoXMgZGV0YWxsZXMuJykKCiAgICAgICAgZGVmIF91cmxfdmFsaWRh
:::KHNlbGYpOgogICAgICAgICAgICBpZiBzZWxmLl9lbl9wbGFjZWhvbGRlcjoKICAg
:::ICAgICAgICAgICAgIHNlbGYuX2xvZygnUHJpbWVybyBwZWdhIGxhIFVSTCBkZWwg
:::dmlkZW8gZGUgWW91VHViZS4nLCAnYXZpc28nKQogICAgICAgICAgICAgICAgcmV0
:::dXJuIE5vbmUKICAgICAgICAgICAgdSA9IHNlbGYuZW50X3VybC5nZXQoKS5zdHJp
:::cCgpLnN0cmlwKCciJykuc3RyaXAoIiciKQogICAgICAgICAgICBpZiBub3QgdToK
:::ICAgICAgICAgICAgICAgIHNlbGYuX2xvZygnTGEgVVJMIGVzdMOhIHZhY8OtYS4n
:::LCAnYXZpc28nKQogICAgICAgICAgICAgICAgcmV0dXJuIE5vbmUKICAgICAgICAg
:::ICAgaWYgbm90IHJlLm1hdGNoKHInXmh0dHBzPzovLycsIHUsIHJlLkkpOgogICAg
:::ICAgICAgICAgICAgaWYgcmUubWF0Y2gocided3d3XC4nLCB1LCByZS5JKToKICAg
:::ICAgICAgICAgICAgICAgICB1ID0gJ2h0dHBzOi8vJyArIHUKICAgICAgICAgICAg
:::ICAgIGVsc2U6CiAgICAgICAgICAgICAgICAgICAgc2VsZi5fbG9nKCdFc28gbm8g
:::cGFyZWNlIHVuYSBVUkwgKGRlYmUgZW1wZXphciBwb3IgJwogICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAnaHR0cDovLyBvIGh0dHBzOi8vKScsICdlcnJvcicp
:::CiAgICAgICAgICAgICAgICAgICAgcmV0dXJuIE5vbmUKICAgICAgICAgICAgIyBP
:::Sk86IGFxdcOtIE5PIHNlIHF1aXRhIGxpc3Q9OyBzaSBsYSBVUkwgdHJhZSB1bmEg
:::cGxheWxpc3QsCiAgICAgICAgICAgICMgX2FjY2lvbl9kZXNjYXJnYXIgcHJlZ3Vu
:::dGFyw6EgcXXDqSBoYWNlciBjb24gZWxsYS4KICAgICAgICAgICAgcmV0dXJuIHUK
:::CiAgICAgICAgZGVmIF9hY2Npb25fZXN0aW1hcihzZWxmKToKICAgICAgICAgICAg
:::dXJsID0gc2VsZi5fdXJsX3ZhbGlkYSgpCiAgICAgICAgICAgIGlmIG5vdCB1cmw6
:::CiAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgc2VsZi5fZ3VhcmRh
:::cigpCiAgICAgICAgICAgIGNmZyA9IHsndXJsJzogdXJsfQogICAgICAgICAgICBz
:::ZWxmLl9pbmljaWFyKHNlbGYuX2hpbG9fZXN0aW1hciwgY2ZnLCAnRXN0aW1hbmRv
:::IHRhbWHDsW8uLi4nKQogICAgICAgICAgICBzZWxmLmxibF9lc3RpbWFjaW9uLmNv
:::bmZpZ3VyZSgKICAgICAgICAgICAgICAgIHRleHQ9J0NhbGN1bGFuZG8uLi4nLCBm
:::Zz1URU1BU1tzZWxmLl90ZW1hX2FjdHVhbF1bJ3RleHRvMiddKQoKICAgICAgICBk
:::ZWYgX2FjY2lvbl9kZXNjYXJnYXIoc2VsZik6CiAgICAgICAgICAgIHVybCA9IHNl
:::bGYuX3VybF92YWxpZGEoKQogICAgICAgICAgICBpZiBub3QgdXJsOgogICAgICAg
:::ICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgIHNlbGYuX2d1YXJkYXIoKQogICAg
:::ICAgICAgICBwbGF5bGlzdCA9IEZhbHNlCiAgICAgICAgICAgIGlmIGVzX3VybF9w
:::bGF5bGlzdCh1cmwpOgogICAgICAgICAgICAgICAgciA9IG1lc3NhZ2Vib3guYXNr
:::eWVzbm9jYW5jZWwoCiAgICAgICAgICAgICAgICAgICAgJ011c2lrQUxBTiDigJQg
:::bGlzdGEgZGUgcmVwcm9kdWNjacOzbicsCiAgICAgICAgICAgICAgICAgICAgJ0Vz
:::dGEgVVJMIHBlcnRlbmVjZSBhIHVuYSBsaXN0YSBkZSByZXByb2R1Y2Npw7NuLlxu
:::XG4nCiAgICAgICAgICAgICAgICAgICAgJyAgU8ONICDihpIgIGRlc2NhcmdhciBs
:::YSBwbGF5bGlzdCBjb21wbGV0YVxuJwogICAgICAgICAgICAgICAgICAgICcgICAg
:::ICAgICAocGF1c2EgZGUgMiBzIGVudHJlIGNhbmNpb25lcylcbicKICAgICAgICAg
:::ICAgICAgICAgICAnICBOTyAg4oaSICBkZXNjYXJnYXIgc29sbyBlc3RhIGNhbmNp
:::w7NuXG4nCiAgICAgICAgICAgICAgICAgICAgJyAgQ2FuY2VsYXIgIOKGkiAgbm8g
:::ZGVzY2FyZ2FyIG5hZGEnKQogICAgICAgICAgICAgICAgaWYgciBpcyBOb25lOgog
:::ICAgICAgICAgICAgICAgICAgIHNlbGYuX2xvZygnRGVzY2FyZ2EgY2FuY2VsYWRh
:::LicsICdncmlzJykKICAgICAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAg
:::ICAgICAgIGlmIHI6CiAgICAgICAgICAgICAgICAgICAgcGxheWxpc3QgPSBUcnVl
:::CiAgICAgICAgICAgICAgICBlbGlmIGVzX3NvbG9fbGlzdGEodXJsKToKICAgICAg
:::ICAgICAgICAgICAgICAjIEVzIHVuYSBwbGF5bGlzdCBwdXJhOiBubyBoYXkgInVu
:::YSBjYW5jacOzbiIgYWjDrQogICAgICAgICAgICAgICAgICAgIHNlbGYuX2xvZygn
:::RXNhIFVSTCBlcyB1bmEgbGlzdGEgY29tcGxldGE7IHNlIGRlc2NhcmdhcsOhICcK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2VudGVyYS4nLCAnYXZpc28n
:::KQogICAgICAgICAgICAgICAgICAgIHBsYXlsaXN0ID0gVHJ1ZQogICAgICAgICAg
:::ICBjZmcgPSB7J3VybCc6IHVybCwgJ3BsYXlsaXN0JzogcGxheWxpc3R9CiAgICAg
:::ICAgICAgIHNlbGYuX2luaWNpYXIoc2VsZi5faGlsb19kZXNjYXJnYXIsIGNmZywg
:::J0Rlc2NhcmdhbmRvLi4uJykKCiAgICAgICAgZGVmIF9hY2Npb25fY29tcHJvYmFy
:::KHNlbGYpOgogICAgICAgICAgICBzZWxmLl9ndWFyZGFyKCkKICAgICAgICAgICAg
:::c2VsZi5faW5pY2lhcihzZWxmLl9oaWxvX2NvbXByb2Jhciwge30sCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgJ0NvbXByb2JhbmRvIGxhIGNhcnBldGEuLi4nKQoK
:::ICAgICAgICBkZWYgX2FjY2lvbl9hY3R1YWxpemFyKHNlbGYpOgogICAgICAgICAg
:::ICBpZiBub3QgWVRfRExQOgogICAgICAgICAgICAgICAgc2VsZi5fbG9nKCd5dC1k
:::bHAgbm8gZXN0w6EgaW5zdGFsYWRvOyBlamVjdXRhICcKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAnRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0LicsICdlcnJvcicpCiAg
:::ICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgc2VsZi5faW5pY2lhcihz
:::ZWxmLl9oaWxvX2FjdHVhbGl6YXIsIHt9LCAnQWN0dWFsaXphbmRvIHl0LWRscC4u
:::LicpCgogICAgICAgICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tIGhpbG9zCiAgICAgICAgZGVmIF9oaWxvX2VzdGltYXIo
:::c2VsZiwgY2ZnKToKICAgICAgICAgICAgY29sYSA9IHNlbGYuY29sYQoKICAgICAg
:::ICAgICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAgICAgICAgICAgICAgICBjb2xh
:::LnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgICAgICAgICAgdHJ5OgogICAgICAgICAg
:::ICAgICAgaWYgWVRfRExQIGlzIE5vbmU6CiAgICAgICAgICAgICAgICAgICAgbG9n
:::KCd5dC1kbHAgbm8gZXN0w6EgaW5zdGFsYWRvLiBFamVjdXRhICcKICAgICAgICAg
:::ICAgICAgICAgICAgICAgJ0Rlc2NhcmdhZG9yTXVzaWNhLmJhdCBwYXJhIGluc3Rh
:::bGFybG8uJywgJ2Vycm9yJykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgo
:::J2VzdGltYWNpb24nLCAneXQtZGxwIG5vIGRpc3BvbmlibGUnKSkKICAgICAgICAg
:::ICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgICAgIGxvZygnT2J0ZW5pZW5k
:::byBpbmZvcm1hY2nDs24gZGVsIHZpZGVvLi4uJywgJ2dyaXMnKQogICAgICAgICAg
:::ICAgICAgbyA9IHsncXVpZXQnOiBUcnVlLCAnbm9fd2FybmluZ3MnOiBUcnVlLCAn
:::bm9wbGF5bGlzdCc6IFRydWUsCiAgICAgICAgICAgICAgICAgICAgICdzb2NrZXRf
:::dGltZW91dCc6IDMwLCAnbG9nZ2VyJzogUkVHSVNUUk99CiAgICAgICAgICAgICAg
:::ICBpZiBlc191cmxfcGxheWxpc3QoY2ZnWyd1cmwnXSk6CiAgICAgICAgICAgICAg
:::ICAgICAgbG9nKCcobGEgVVJMIGNvbnRpZW5lIHVuYSBwbGF5bGlzdDogbGEgZXN0
:::aW1hY2nDs24gZXMgJwogICAgICAgICAgICAgICAgICAgICAgICAnc29sbyBkZWwg
:::dmlkZW8gcGVnYWRvKScsICdncmlzJykKICAgICAgICAgICAgICAgIHdpdGggWVRf
:::RExQLllvdXR1YmVETChvKSBhcyB5ZGw6CiAgICAgICAgICAgICAgICAgICAgaW5m
:::byA9IHlkbC5leHRyYWN0X2luZm8oY2ZnWyd1cmwnXSwgZG93bmxvYWQ9RmFsc2Up
:::CiAgICAgICAgICAgICAgICBkdXIgPSBpbmZvLmdldCgnZHVyYXRpb24nKQogICAg
:::ICAgICAgICAgICAgaWYgbm90IGR1cjoKICAgICAgICAgICAgICAgICAgICBsb2co
:::J05vIHNlIHB1ZG8gb2J0ZW5lciBsYSBkdXJhY2nDs24gZGVsIHZpZGVvLicsICdl
:::cnJvcicpCiAgICAgICAgICAgICAgICAgICAgY29sYS5wdXQoKCdlc3RpbWFjaW9u
:::JywgJ1NpbiBkYXRvcyBwYXJhIGVzdGltYXInKSkKICAgICAgICAgICAgICAgICAg
:::ICByZXR1cm4KICAgICAgICAgICAgICAgIGNsYXZlID0gc2VsZi5fZm10X2FjdHVh
:::bF9zb2xvKEFKVVNURVMuZ2V0KCdmb3JtYXRvJywgJ0FBQycpKQogICAgICAgICAg
:::ICAgICAgdGFtID0gZXN0aW1hcl9ieXRlcyhkdXIsIGNsYXZlLCBBSlVTVEVTLmdl
:::dCgnY2FsaWRhZCcpLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICBib29sKEFKVVNURVMuZ2V0KCdlbWJlYmVyJywgVHJ1ZSkpKQogICAgICAgICAg
:::ICAgICAgdGl0dWxvID0gc3RyKGluZm8uZ2V0KCd0aXRsZScpIG9yICcnKVs6NzBd
:::CiAgICAgICAgICAgICAgICBpZiB0aXR1bG86CiAgICAgICAgICAgICAgICAgICAg
:::bG9nKCfimaogJyArIHRpdHVsbywgJ3RpdHVsbycpCiAgICAgICAgICAgICAgICB0
:::ZXh0byA9IChmJ357dGFtIC8gMTA0ODU3NjouMWZ9IE1CIMK3ICcKICAgICAgICAg
:::ICAgICAgICAgICAgICAgIGYnZHVyYWNpw7NuIHtmbXRfdGllbShkdXIpfSDCtyAn
:::CiAgICAgICAgICAgICAgICAgICAgICAgICBmJ3tjbGF2ZX0ge0FKVVNURVMuZ2V0
:::KCJjYWxpZGFkIiwgIiIpfScucnN0cmlwKCkpCiAgICAgICAgICAgICAgICBjb2xh
:::LnB1dCgoJ2VzdGltYWNpb24nLCB0ZXh0bykpCiAgICAgICAgICAgICAgICBsb2co
:::J0VzdGltYWNpw7NuOiAnICsgdGV4dG8sICdvaycpCiAgICAgICAgICAgICAgICBs
:::b2coJ0VsIHRhbWHDsW8gcmVhbCBwdWVkZSB2YXJpYXIgYWxnbyBzZWfDum4gbGEg
:::ZnVlbnRlLicsCiAgICAgICAgICAgICAgICAgICAgJ2dyaXMnKQogICAgICAgICAg
:::ICBleGNlcHQgRXhjZXB0aW9uIGFzIGU6CiAgICAgICAgICAgICAgICBsb2coZidO
:::byBzZSBwdWRvIGVzdGltYXI6IHtzZWxmLl9tc2dfZXJyb3IoZSl9JywgJ2Vycm9y
:::JykKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZXN0aW1hY2lvbicsICdObyBz
:::ZSBwdWRvIGVzdGltYXInKSkKICAgICAgICAgICAgZmluYWxseToKICAgICAgICAg
:::ICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2VzdGltYWNpb24nLCBUcnVlLCAnJykp
:::CgogICAgICAgIGRlZiBfZm10X2FjdHVhbF9zb2xvKHNlbGYsIGNsYXZlKToKICAg
:::ICAgICAgICAgcmV0dXJuIGNsYXZlIGlmIGNsYXZlIGluIEZPUk1BVE9TIGVsc2Ug
:::J0FBQycKCiAgICAgICAgZGVmIF9kZXNjYXJnYXJfdW5hKHNlbGYsIHVybCwgY2xh
:::dmUsIGNhbGlkYWRfYXJnLCBlbWJlYmVyLCBkZXN0aW5vLAogICAgICAgICAgICAg
:::ICAgICAgICAgICAgICBjb2xhKToKICAgICAgICAgICAgIiIiRGVzY2FyZ2EgeSBj
:::b252aWVydGUgVU5BIFVSTC4gRGV2dWVsdmUgZWwgUGF0aCBmaW5hbCBvIE5vbmUu
:::IiIiCiAgICAgICAgICAgIGlmIGNsYXZlID09ICdXTUEnOgogICAgICAgICAgICAg
:::ICAgcmV0dXJuIGRlc2Nhcmdhcl93bWEodXJsLCBjYWxpZGFkX2FyZywgZGVzdGlu
:::bywgZW1iZWJlciwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::IGNvbGEpWzFdCiAgICAgICAgICAgIGlmIGNsYXZlID09ICdBVkknOgogICAgICAg
:::ICAgICAgICAgcmV0dXJuIGRlc2Nhcmdhcl9hdmkodXJsLCBkZXN0aW5vLCBjb2xh
:::KVsxXQogICAgICAgICAgICByZXR1cm4gZGVzY2FyZ2FyX2F1ZGlvKHVybCwgY2xh
:::dmUsIGNhbGlkYWRfYXJnLCBkZXN0aW5vLCBlbWJlYmVyLAogICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgIGNvbGEpWzFdCgogICAgICAgIGRlZiBfZGVz
:::Y2FyZ2FyX3BsYXlsaXN0KHNlbGYsIHVybCwgY2xhdmUsIGNhbGlkYWRfYXJnLCBl
:::bWJlYmVyLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRlc3Rpbm8s
:::IGNvbGEpOgogICAgICAgICAgICAiIiJCYWphIHVuYSBsaXN0YSBlbnRlcmEsIGNv
:::biAyIHMgZGUgZGVzY2Fuc28gZW50cmUgY2FuY2lvbmVzCiAgICAgICAgICAgIHBh
:::cmEgbm8gc2F0dXJhciBhIFlvdVR1YmUuIERldnVlbHZlIChkZXNjYXJnYWRhcywg
:::dG90YWwpLiIiIgogICAgICAgICAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAg
:::ICAgICAgICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgICAgICAg
:::ICBsb2coJ0xleWVuZG8gbGEgbGlzdGEgZGUgcmVwcm9kdWNjacOzbi4uLicsICdn
:::cmlzJykKICAgICAgICAgICAgbyA9IHsncXVpZXQnOiBUcnVlLCAnbm9fd2Fybmlu
:::Z3MnOiBUcnVlLAogICAgICAgICAgICAgICAgICdleHRyYWN0X2ZsYXQnOiAnaW5f
:::cGxheWxpc3QnLCAnc29ja2V0X3RpbWVvdXQnOiAzMCwKICAgICAgICAgICAgICAg
:::ICAnbG9nZ2VyJzogUkVHSVNUUk99CiAgICAgICAgICAgIHdpdGggWVRfRExQLllv
:::dXR1YmVETChvKSBhcyB5ZGw6CiAgICAgICAgICAgICAgICBpbmZvID0geWRsLmV4
:::dHJhY3RfaW5mbyh1cmwsIGRvd25sb2FkPUZhbHNlKQogICAgICAgICAgICBlbnRy
:::YWRhcyA9IGxpc3QoaW5mby5nZXQoJ2VudHJpZXMnKSBvciBbXSkKICAgICAgICAg
:::ICAgaWYgbm90IGVudHJhZGFzOgogICAgICAgICAgICAgICAgbG9nKCdObyBzZSB2
:::aW8gbmluZ3VuYSBjYW5jacOzbiBlbiBsYSBsaXN0YTsgc2UgaW50ZW50YSAnCiAg
:::ICAgICAgICAgICAgICAgICAgJ2NvbW8gdmlkZW8gc3VlbHRvLicsICdhdmlzbycp
:::CiAgICAgICAgICAgICAgICBhcmNoaXZvID0gc2VsZi5fZGVzY2FyZ2FyX3VuYShz
:::aW5fcGxheWxpc3QodXJsKVswXSwgY2xhdmUsCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBjYWxpZGFkX2FyZywgZW1iZWJlciwg
:::ZGVzdGlubywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgIGNvbGEpCiAgICAgICAgICAgICAgICByZXR1cm4gKDEgaWYgYXJjaGl2
:::byBlbHNlIDApLCAxCiAgICAgICAgICAgIHRpdHVsb19wbCA9IHN0cihpbmZvLmdl
:::dCgndGl0bGUnKSBvciAnbGlzdGEnKVs6NzBdCiAgICAgICAgICAgIHRvdGFsID0g
:::bGVuKGVudHJhZGFzKQogICAgICAgICAgICBsb2coZidQbGF5bGlzdCDCq3t0aXR1
:::bG9fcGx9wrsg4oCUIHt0b3RhbH0gdsOtZGVvKHMpLicsICd0aXR1bG8nKQogICAg
:::ICAgICAgICBva2FzID0gMAogICAgICAgICAgICBmYWxsb3MgPSBbXQogICAgICAg
:::ICAgICBmb3IgaSwgZSBpbiBlbnVtZXJhdGUoZW50cmFkYXMpOgogICAgICAgICAg
:::ICAgICAgdSA9IHN0cihlLmdldCgnd2VicGFnZV91cmwnKSBvciBlLmdldCgndXJs
:::Jykgb3IgJycpCiAgICAgICAgICAgICAgICBpZiB1IGFuZCBub3QgdS5zdGFydHN3
:::aXRoKCdodHRwJyk6CiAgICAgICAgICAgICAgICAgICAgdSA9ICdodHRwczovL3d3
:::dy55b3V0dWJlLmNvbS93YXRjaD92PScgKyB1CiAgICAgICAgICAgICAgICBpZiBu
:::b3QgdSBhbmQgZS5nZXQoJ2lkJyk6CiAgICAgICAgICAgICAgICAgICAgdSA9ICdo
:::dHRwczovL3d3dy55b3V0dWJlLmNvbS93YXRjaD92PScgKyBzdHIoZVsnaWQnXSkK
:::ICAgICAgICAgICAgICAgIHRpdCA9IHN0cihlLmdldCgndGl0bGUnKSBvciB1IG9y
:::ICc/JylbOjcwXQogICAgICAgICAgICAgICAgaWYgaToKICAgICAgICAgICAgICAg
:::ICAgICB0aW1lLnNsZWVwKDIpICAgIyBkZXNjYW5zbyBlbnRyZSBjYW5jaW9uZXMK
:::ICAgICAgICAgICAgICAgIGxvZyhmJ1t7aSArIDF9L3t0b3RhbH1dIOKZqiB7dGl0
:::fScsICd0aXR1bG8nKQogICAgICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAg
:::ICAgICAgIGFyY2hpdm8gPSBzZWxmLl9kZXNjYXJnYXJfdW5hKHUsIGNsYXZlLCBj
:::YWxpZGFkX2FyZywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICBlbWJlYmVyLCBkZXN0aW5vLCBjb2xhKQogICAgICAgICAg
:::ICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBlMjoKICAgICAgICAgICAgICAgICAg
:::ICBhcmNoaXZvID0gTm9uZQogICAgICAgICAgICAgICAgICAgIGxvZyhmJ+KcliBb
:::e2kgKyAxfS97dG90YWx9XSBGYWxsw7M6IHtzZWxmLl9tc2dfZXJyb3IoZTIpfScs
:::CiAgICAgICAgICAgICAgICAgICAgICAgICdlcnJvcicpCiAgICAgICAgICAgICAg
:::ICBpZiBhcmNoaXZvIGFuZCBQYXRoKGFyY2hpdm8pLmV4aXN0cygpOgogICAgICAg
:::ICAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgICAgICAgICAgdGFtID0g
:::Zm10X3RhbShQYXRoKGFyY2hpdm8pLnN0YXQoKS5zdF9zaXplKQogICAgICAgICAg
:::ICAgICAgICAgIGV4Y2VwdCBPU0Vycm9yOgogICAgICAgICAgICAgICAgICAgICAg
:::ICB0YW0gPSAnPycKICAgICAgICAgICAgICAgICAgICBsb2coZicgICDinJQge1Bh
:::dGgoYXJjaGl2bykubmFtZX0gICh7dGFtfSknLCAnb2snKQogICAgICAgICAgICAg
:::ICAgICAgIG9rYXMgKz0gMQogICAgICAgICAgICAgICAgZWxzZToKICAgICAgICAg
:::ICAgICAgICAgICBmYWxsb3MuYXBwZW5kKHRpdCkKICAgICAgICAgICAgbG9nKGYn
:::UGxheWxpc3QgdGVybWluYWRhOiB7b2thc30gZGUge3RvdGFsfSBkZXNjYXJnYWRh
:::KHMpLicsCiAgICAgICAgICAgICAgICAnb2snIGlmIG5vdCBmYWxsb3MgZWxzZSAn
:::YXZpc28nKQogICAgICAgICAgICBpZiBmYWxsb3M6CiAgICAgICAgICAgICAgICBs
:::b2coJ1NpbiBkZXNjYXJnYXI6ICcKICAgICAgICAgICAgICAgICAgICArICcgwrcg
:::Jy5qb2luKGZbOjQwXSBmb3IgZiBpbiBmYWxsb3NbOjhdKQogICAgICAgICAgICAg
:::ICAgICAgICsgKCcuLi4nIGlmIGxlbihmYWxsb3MpID4gOCBlbHNlICcnKSwgJ2dy
:::aXMnKQogICAgICAgICAgICByZXR1cm4gb2thcywgdG90YWwKCiAgICAgICAgZGVm
:::IF9oaWxvX2Rlc2NhcmdhcihzZWxmLCBjZmcpOgogICAgICAgICAgICBjb2xhID0g
:::c2VsZi5jb2xhCgogICAgICAgICAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAg
:::ICAgICAgICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgICAgICAg
:::ICB1cmwgPSBjZmdbJ3VybCddCiAgICAgICAgICAgIGNsYXZlID0gc2VsZi5fZm10
:::X2FjdHVhbF9zb2xvKEFKVVNURVMuZ2V0KCdmb3JtYXRvJywgJ0FBQycpKQogICAg
:::ICAgICAgICBjYWxpZGFkID0gQUpVU1RFUy5nZXQoJ2NhbGlkYWQnLCAnMTI4aycp
:::CiAgICAgICAgICAgIGVtYmViZXIgPSBib29sKEFKVVNURVMuZ2V0KCdlbWJlYmVy
:::JywgVHJ1ZSkpCiAgICAgICAgICAgIGRlc3Rpbm8gPSBQYXRoKG9zLnBhdGguZXhw
:::YW5kdmFycygKICAgICAgICAgICAgICAgIHN0cihBSlVTVEVTLmdldCgnZGVzdGlu
:::bycsIF9kZXN0aW5vX3Bvcl9kZWZlY3RvKCkpKSkpCiAgICAgICAgICAgIHRyeToK
:::ICAgICAgICAgICAgICAgIGlmIFlUX0RMUCBpcyBOb25lOgogICAgICAgICAgICAg
:::ICAgICAgIGxvZygneXQtZGxwIG5vIGVzdMOhIGluc3RhbGFkby4gRWplY3V0YSAn
:::CiAgICAgICAgICAgICAgICAgICAgICAgICdEZXNjYXJnYWRvck11c2ljYS5iYXQg
:::cGFyYSBpbnN0YWxhcmxvLicsICdlcnJvcicpCiAgICAgICAgICAgICAgICAgICAg
:::Y29sYS5wdXQoKCdmaW4nLCAnZGVzY2FyZ2EnLCBGYWxzZSwKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgJ3l0LWRscCBubyBlc3TDoSBpbnN0YWxhZG8uJykp
:::CiAgICAgICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgICAgICBkZXN0
:::aW5vLm1rZGlyKHBhcmVudHM9VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgICAgICAg
:::ICAgICAgIGlmIGNsYXZlIGluICgnRkxBQycsICdXQVYnKToKICAgICAgICAgICAg
:::ICAgICAgICBjYWxpZGFkX2FyZyA9ICcwJwogICAgICAgICAgICAgICAgZWxzZToK
:::ICAgICAgICAgICAgICAgICAgICBjYWxpZGFkX2FyZyA9IChyZS5zdWIocidbXjAt
:::OV0nLCAnJywgc3RyKGNhbGlkYWQpKQogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgIG9yICgnMTI4JyBpZiBjbGF2ZSA9PSAnQUFDJyBlbHNlICczMjAn
:::KSkKICAgICAgICAgICAgICAgIGlmIGNmZy5nZXQoJ3BsYXlsaXN0Jyk6CiAgICAg
:::ICAgICAgICAgICAgICAgb2thcywgdG90YWwgPSBzZWxmLl9kZXNjYXJnYXJfcGxh
:::eWxpc3QoCiAgICAgICAgICAgICAgICAgICAgICAgIHVybCwgY2xhdmUsIGNhbGlk
:::YWRfYXJnLCBlbWJlYmVyLCBkZXN0aW5vLCBjb2xhKQogICAgICAgICAgICAgICAg
:::ICAgIGlmIG9rYXMgYW5kIG9rYXMgPT0gdG90YWw6CiAgICAgICAgICAgICAgICAg
:::ICAgICAgIGxvZyhmJ0NhcnBldGE6IHtkZXN0aW5vfScsICdncmlzJykKICAgICAg
:::ICAgICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnZGVzY2FyZ2EnLCBU
:::cnVlLCAnJykpCiAgICAgICAgICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAg
:::ICAgICAgICAgICAgY29sYS5wdXQoKAogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgJ2ZpbicsICdkZXNjYXJnYScsIEZhbHNlLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgZidTZSBkZXNjYXJnYXJvbiB7b2thc30gZGUge3RvdGFsfSBkZSBs
:::YSAnCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAncGxheWxpc3QuIExhIFVS
:::TCBubyBzZSBoYSBib3JyYWRvIHBvciBzaSAnCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAncXVpZXJlcyByZWludGVudGFybG8uJykpCiAgICAgICAgICAgICAg
:::ICAgICAgcmV0dXJuCiAgICAgICAgICAgICAgICBhcmNoaXZvID0gc2VsZi5fZGVz
:::Y2FyZ2FyX3VuYShzaW5fcGxheWxpc3QodXJsKVswXSwgY2xhdmUsCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjYWxpZGFkX2Fy
:::ZywgZW1iZWJlciwgZGVzdGlubywKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgIGNvbGEpCiAgICAgICAgICAgICAgICBpZiBhcmNo
:::aXZvIGFuZCBQYXRoKGFyY2hpdm8pLmV4aXN0cygpOgogICAgICAgICAgICAgICAg
:::ICAgIGFyY2hpdm8gPSBQYXRoKGFyY2hpdm8pCiAgICAgICAgICAgICAgICAgICAg
:::dHJ5OgogICAgICAgICAgICAgICAgICAgICAgICB0YW0gPSBmbXRfdGFtKGFyY2hp
:::dm8uc3RhdCgpLnN0X3NpemUpCiAgICAgICAgICAgICAgICAgICAgZXhjZXB0IE9T
:::RXJyb3I6CiAgICAgICAgICAgICAgICAgICAgICAgIHRhbSA9ICc/JwogICAgICAg
:::ICAgICAgICAgICAgIGxvZyhmJ+KclCDCoUxpc3RvISAge2FyY2hpdm8ubmFtZX0g
:::ICh7dGFtfSknLCAnb2snKQogICAgICAgICAgICAgICAgICAgIGxvZyhmJ0NhcnBl
:::dGE6IHthcmNoaXZvLnBhcmVudH0nLCAnZ3JpcycpCiAgICAgICAgICAgICAgICAg
:::ICAgY29sYS5wdXQoKCdmaW4nLCAnZGVzY2FyZ2EnLCBUcnVlLCAnJykpCiAgICAg
:::ICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgIGxvZygnRWwgYXJj
:::aGl2byBmaW5hbCBubyBhcGFyZWNpw7MgZG9uZGUgc2UgZXNwZXJhYmEuJywKICAg
:::ICAgICAgICAgICAgICAgICAgICAgJ2Vycm9yJykKICAgICAgICAgICAgICAgICAg
:::ICBjb2xhLnB1dCgoJ2ZpbicsICdkZXNjYXJnYScsIEZhbHNlLCAnJykpCiAgICAg
:::ICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZToKICAgICAgICAgICAgICAgIG5v
:::bWJyZV9leGMgPSB0eXBlKGUpLl9fbmFtZV9fCiAgICAgICAgICAgICAgICBpZiBu
:::b21icmVfZXhjID09ICdEb3dubG9hZEVycm9yJzoKICAgICAgICAgICAgICAgICAg
:::ICBsaW5lYXMgPSBbbCBmb3IgbCBpbiBzdHIoZSkuc3RyaXAoKS5zcGxpdGxpbmVz
:::KCkgaWYgbC5zdHJpcCgpXQogICAgICAgICAgICAgICAgICAgIG1zZyA9IGxpbmVh
:::c1swXVs6MzAwXSBpZiBsaW5lYXMgZWxzZSAnZXJyb3IgZGVzY29ub2NpZG8nCiAg
:::ICAgICAgICAgICAgICAgICAgbG9nKCfinJYgTm8gc2UgcHVkbyBkZXNjYXJnYXI6
:::ICcgKyBtc2csICdlcnJvcicpCiAgICAgICAgICAgICAgICAgICAgbG9nKCdDb25z
:::ZWpvczogcmV2aXNhIGxhIFVSTCB5IHR1IGNvbmV4acOzbjsgc2kgWW91VHViZSAn
:::CiAgICAgICAgICAgICAgICAgICAgICAgICdjYW1iacOzIGFsZ28sIHB1bHNhIEN0
:::cmwrVSAoYWN0dWFsaXphciB5dC1kbHApIHkgJwogICAgICAgICAgICAgICAgICAg
:::ICAgICAncmVpbnRlbnRhLicsICdncmlzJykKICAgICAgICAgICAgICAgIGVsc2U6
:::CiAgICAgICAgICAgICAgICAgICAgbG9nKGYn4pyWIEVycm9yIGluZXNwZXJhZG8g
:::KHtub21icmVfZXhjfSk6IHtlfScsICdlcnJvcicpCiAgICAgICAgICAgICAgICAg
:::ICAgdGIgPSB0cmFjZWJhY2suZm9ybWF0X2V4YyhsaW1pdD0zKQogICAgICAgICAg
:::ICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgICAgICAgICAgd2l0aCBvcGVu
:::KExPR19FUlJPUkVTLCAnYScsIGVuY29kaW5nPSd1dGYtOCcpIGFzIGZoOgogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgZmgud3JpdGUodGIgKyAnXG4nKQogICAg
:::ICAgICAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgICAg
:::ICAgICAgICAgIHBhc3MKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywg
:::J2Rlc2NhcmdhJywgRmFsc2UsCiAgICAgICAgICAgICAgICAgICAgICAgICAgJ05v
:::IHNlIHB1ZG8gY29tcGxldGFyIGxhIGRlc2NhcmdhLiBSZXZpc2EgZWwgJwogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICdyZWdpc3RybyBwYXJhIG3DoXMgZGV0YWxs
:::ZXMuJykpCgogICAgICAgIGRlZiBfaGlsb19jb21wcm9iYXIoc2VsZiwgY2ZnKToK
:::ICAgICAgICAgICAgY29sYSA9IHNlbGYuY29sYQoKICAgICAgICAgICAgZGVmIGxv
:::ZyhtLCB0PSdpbmZvJyk6CiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2xvZycs
:::IG0sIHQpKQoKICAgICAgICAgICAgY2FycGV0YSA9IFBhdGgob3MucGF0aC5leHBh
:::bmR2YXJzKAogICAgICAgICAgICAgICAgc3RyKEFKVVNURVMuZ2V0KCdkZXN0aW5v
:::JywgX2Rlc3Rpbm9fcG9yX2RlZmVjdG8oKSkpKSkKICAgICAgICAgICAgdHJ5Ogog
:::ICAgICAgICAgICAgICAgaWYgbm90IGNhcnBldGEuaXNfZGlyKCk6CiAgICAgICAg
:::ICAgICAgICAgICAgbG9nKGYnTGEgY2FycGV0YSB0b2RhdsOtYSBubyBleGlzdGU6
:::IHtjYXJwZXRhfScsICdhdmlzbycpCiAgICAgICAgICAgICAgICAgICAgY29sYS5w
:::dXQoKCdmaW4nLCAnY29tcHJvYmFjaW9uJywgVHJ1ZSwgJycpKQogICAgICAgICAg
:::ICAgICAgICAgIHJldHVybgogICAgICAgICAgICAgICAgaWYgRkZQUk9CRSBpcyBO
:::b25lOgogICAgICAgICAgICAgICAgICAgIGxvZygnZmZwcm9iZSBubyBlc3TDoSBk
:::aXNwb25pYmxlICh2aWVuZSBjb24gRkZtcGVnKS4gJwogICAgICAgICAgICAgICAg
:::ICAgICAgICAnRWplY3V0YSBEZXNjYXJnYWRvck11c2ljYS5iYXQgcGFyYSBpbnN0
:::YWxhcmxvLicsCiAgICAgICAgICAgICAgICAgICAgICAgICdlcnJvcicpCiAgICAg
:::ICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnY29tcHJvYmFjaW9uJywg
:::VHJ1ZSwgJycpKQogICAgICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAg
:::ICAgICAgZXh0cyA9ICgnLm00YScsICcubXAzJywgJy5mbGFjJywgJy53YXYnLCAn
:::LndtYScsICcuYXZpJykKICAgICAgICAgICAgICAgIGFyY2hpdm9zID0gW3AgZm9y
:::IHAgaW4gc29ydGVkKGNhcnBldGEucmdsb2IoJyonKSkKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIGlmIHAuaXNfZmlsZSgpIGFuZCBwLnN1ZmZpeC5sb3dlcigp
:::IGluIGV4dHMKICAgICAgICAgICAgICAgICAgICAgICAgICAgIGFuZCAnX3RtcCcg
:::bm90IGluIHAucGFydHNdCiAgICAgICAgICAgICAgICBsb2coZidDb21wcm9iYW5k
:::byB7bGVuKGFyY2hpdm9zKX0gYXJjaGl2byhzKSBlbiAnCiAgICAgICAgICAgICAg
:::ICAgICAgZid7Y2FycGV0YX0gLi4uJywgJ3RpdHVsbycpCiAgICAgICAgICAgICAg
:::ICBpZiBub3QgYXJjaGl2b3M6CiAgICAgICAgICAgICAgICAgICAgbG9nKCdObyBo
:::YXkgYXJjaGl2b3MgZGUgYXVkaW8gbyB2aWRlbyB0b2RhdsOtYS4nLCAnZ3Jpcycp
:::CiAgICAgICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnY29tcHJvYmFj
:::aW9uJywgVHJ1ZSwgJycpKQogICAgICAgICAgICAgICAgICAgIHJldHVybgogICAg
:::ICAgICAgICAgICAgdG90YWwgPSAwCiAgICAgICAgICAgICAgICBiYWphcyA9IDAK
:::ICAgICAgICAgICAgICAgIGZvciBwIGluIGFyY2hpdm9zOgogICAgICAgICAgICAg
:::ICAgICAgIHRyeToKICAgICAgICAgICAgICAgICAgICAgICAgciA9IHN1YnByb2Nl
:::c3MucnVuKAogICAgICAgICAgICAgICAgICAgICAgICAgICAgW3N0cihGRlBST0JF
:::KSwgJy12JywgJ2Vycm9yJywgJy1zaG93X2VudHJpZXMnLAogICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICdmb3JtYXQ9Yml0X3JhdGUsZHVyYXRpb24sc2l6ZScs
:::ICctb2YnLCAnanNvbicsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgc3Ry
:::KHApXSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0ZG91dD1zdWJwcm9j
:::ZXNzLlBJUEUsIHN0ZGVycj1zdWJwcm9jZXNzLlBJUEUsCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICB0ZXh0PVRydWUsIGVuY29kaW5nPSd1dGYtOCcsIGVycm9y
:::cz0ncmVwbGFjZScsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aW1lb3V0
:::PTMwKQogICAgICAgICAgICAgICAgICAgICAgICBkYXRvcyA9IGpzb24ubG9hZHMo
:::ci5zdGRvdXQgb3IgJ3t9JykuZ2V0KCdmb3JtYXQnLCB7fSkKICAgICAgICAgICAg
:::ICAgICAgICAgICAga2JwcyA9IGludChmbG9hdChkYXRvcy5nZXQoJ2JpdF9yYXRl
:::Jykgb3IgMCkgLyAxMDAwKQogICAgICAgICAgICAgICAgICAgICAgICBkdXIgPSBm
:::bG9hdChkYXRvcy5nZXQoJ2R1cmF0aW9uJykgb3IgMCkKICAgICAgICAgICAgICAg
:::ICAgICAgICAgdGFtID0gaW50KGZsb2F0KGRhdG9zLmdldCgnc2l6ZScpIG9yIDAp
:::KQogICAgICAgICAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAg
:::ICAgICAgICAgICAgICAgIGxvZyhmJ8K3IHtwLm5hbWVbOjYwXX0g4oCUIG5vIHNl
:::IHB1ZG8gbGVlcicsICdhdmlzbycpCiAgICAgICAgICAgICAgICAgICAgICAgIGNv
:::bnRpbnVlCiAgICAgICAgICAgICAgICAgICAgdG90YWwgKz0gdGFtCiAgICAgICAg
:::ICAgICAgICAgICAgdGV4dG8sIG5pdmVsID0gY2xhc2VfY2FsaWRhZChwLnN1ZmZp
:::eC5sb3dlcigpLCBrYnBzKQogICAgICAgICAgICAgICAgICAgIGlmIG5pdmVsID09
:::IDI6CiAgICAgICAgICAgICAgICAgICAgICAgIGJhamFzICs9IDEKICAgICAgICAg
:::ICAgICAgICAgICB0YWcgPSAoJ29rJyBpZiBuaXZlbCA9PSAwCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgIGVsc2UgKCdhdmlzbycgaWYgbml2ZWwgPT0gMSBlbHNl
:::ICdlcnJvcicpKQogICAgICAgICAgICAgICAgICAgIGxvZyhmJ8K3IHtwLm5hbWVb
:::OjU4XX0g4oCUIHt0ZXh0b30gwrcge2ZtdF90aWVtKGR1cil9IMK3ICcKICAgICAg
:::ICAgICAgICAgICAgICAgICAgZid7Zm10X3RhbSh0YW0pfScsIHRhZykKICAgICAg
:::ICAgICAgICAgIGxvZyhmJ1Jlc3VsdGFkbzoge2xlbihhcmNoaXZvcyl9IGFyY2hp
:::dm8ocykgwrcgJwogICAgICAgICAgICAgICAgICAgIGYne2ZtdF90YW0odG90YWwp
:::fSBlbiB0b3RhbCDCtyB7YmFqYXN9IGNvbiBjYWxpZGFkIGJhamEnLAogICAgICAg
:::ICAgICAgICAgICAgICd0aXR1bG8nKQogICAgICAgICAgICAgICAgaWYgYmFqYXM6
:::CiAgICAgICAgICAgICAgICAgICAgbG9nKCdDb25zZWpvOiBsb3MgYXJjaGl2b3Mg
:::bWFyY2Fkb3MgZW4gcm9qbyBzZSBwdWVkZW4gJwogICAgICAgICAgICAgICAgICAg
:::ICAgICAndm9sdmVyIGEgZGVzY2FyZ2FyIGNvbiBtw6FzIGJpdHJhdGUuJywgJ2dy
:::aXMnKQogICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uIGFzIGU6CiAgICAgICAg
:::ICAgICAgICBsb2coZidFcnJvciBhbCBjb21wcm9iYXIgbGEgY2FycGV0YToge2V9
:::JywgJ2Vycm9yJykKICAgICAgICAgICAgZmluYWxseToKICAgICAgICAgICAgICAg
:::IGNvbGEucHV0KCgnZmluJywgJ2NvbXByb2JhY2lvbicsIFRydWUsICcnKSkKCiAg
:::ICAgICAgZGVmIF9oaWxvX2FjdHVhbGl6YXIoc2VsZiwgY2ZnKToKICAgICAgICAg
:::ICAgY29sYSA9IHNlbGYuY29sYQoKICAgICAgICAgICAgZGVmIGxvZyhtLCB0PSdp
:::bmZvJyk6CiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoK
:::ICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgbG9nKCdBY3R1YWxpemFu
:::ZG8geXQtZGxwIHkgbXV0YWdlbi4uLicsICdncmlzJykKICAgICAgICAgICAgICAg
:::IHAgPSBzdWJwcm9jZXNzLnJ1bigKICAgICAgICAgICAgICAgICAgICBbc3lzLmV4
:::ZWN1dGFibGUsICctbScsICdwaXAnLCAnaW5zdGFsbCcsICctLXVwZ3JhZGUnLAog
:::ICAgICAgICAgICAgICAgICAgICAnLS1uby13YXJuLXNjcmlwdC1sb2NhdGlvbics
:::ICd5dC1kbHAnLCAnbXV0YWdlbiddLAogICAgICAgICAgICAgICAgICAgIHN0ZG91
:::dD1zdWJwcm9jZXNzLlBJUEUsIHN0ZGVycj1zdWJwcm9jZXNzLlNURE9VVCwKICAg
:::ICAgICAgICAgICAgICAgICB0ZXh0PVRydWUsIGVuY29kaW5nPSd1dGYtOCcsIGVy
:::cm9ycz0ncmVwbGFjZScsIHRpbWVvdXQ9NjAwKQogICAgICAgICAgICAgICAgZm9y
:::IGxuIGluIChwLnN0ZG91dCBvciAnJykuc3RyaXAoKS5zcGxpdGxpbmVzKClbLTY6
:::XToKICAgICAgICAgICAgICAgICAgICBsb2coJyAgICcgKyBsbls6MTYwXSwgJ2dy
:::aXMnKQogICAgICAgICAgICAgICAgaWYgcC5yZXR1cm5jb2RlID09IDA6CiAgICAg
:::ICAgICAgICAgICAgICAgbG9nKCd5dC1kbHAgYWN0dWFsaXphZG8uIFJlaW5pY2lh
:::IGxhIGFwbGljYWNpw7NuIHBhcmEgJwogICAgICAgICAgICAgICAgICAgICAgICAn
:::dXNhciBsYSB2ZXJzacOzbiBudWV2YS4nLCAnb2snKQogICAgICAgICAgICAgICAg
:::ZWxzZToKICAgICAgICAgICAgICAgICAgICBsb2coJ0xhIGFjdHVhbGl6YWNpw7Nu
:::IGZhbGzDsyAowr9zaW4gaW50ZXJuZXQ/KS4nLCAnZXJyb3InKQogICAgICAgICAg
:::ICBleGNlcHQgRXhjZXB0aW9uIGFzIGU6CiAgICAgICAgICAgICAgICBsb2coZidO
:::byBzZSBwdWRvIGVqZWN1dGFyIHBpcDoge2V9JywgJ2Vycm9yJykKICAgICAgICAg
:::ICAgZmluYWxseToKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2Fj
:::dHVhbGl6YWNpb24nLCBUcnVlLCAnJykpCgogICAgICAgIGRlZiBfbXNnX2Vycm9y
:::KHNlbGYsIGUpOgogICAgICAgICAgICBsaW5lYXMgPSBbbCBmb3IgbCBpbiBzdHIo
:::ZSkuc3RyaXAoKS5zcGxpdGxpbmVzKCkgaWYgbC5zdHJpcCgpXQogICAgICAgICAg
:::ICByZXR1cm4gKGxpbmVhc1swXVs6MjUwXSBpZiBsaW5lYXMKICAgICAgICAgICAg
:::ICAgICAgICBlbHNlIGYne3R5cGUoZSkuX19uYW1lX199OiBzaW4gZGV0YWxsZXMn
:::KQoKICAgICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLSBhcnJhbnF1ZQogICAgICAgIGRlZiBfYXJyYW5xdWUoc2Vs
:::Zik6CiAgICAgICAgICAgIHNlbGYuX2xvZyhmJ011c2lrQUxBTiB2e0FQUF9WfScs
:::ICd0aXR1bG8nKQogICAgICAgICAgICBzZWxmLl9sb2coJ0N0cmwrVTogYWN0dWFs
:::aXphciB5dC1kbHAgwrcgQ3RybCtMOiBsaW1waWFyIHJlZ2lzdHJvJywKICAgICAg
:::ICAgICAgICAgICAgICAgICdncmlzJykKICAgICAgICAgICAgdGhyZWFkaW5nLlRo
:::cmVhZCh0YXJnZXQ9c2VsZi5faGlsb192ZXJzaW9uLCBkYWVtb249VHJ1ZSkuc3Rh
:::cnQoKQoKICAgICAgICBkZWYgX2hpbG9fdmVyc2lvbihzZWxmKToKICAgICAgICAg
:::ICAgY29sYSA9IHNlbGYuY29sYQoKICAgICAgICAgICAgZGVmIGxvZyhtLCB0PSdp
:::bmZvJyk6CiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoK
:::ICAgICAgICAgICAgaWYgWVRfRExQIGlzIE5vbmU6CiAgICAgICAgICAgICAgICBs
:::b2coJ3l0LWRscCBubyBlc3TDoSBpbnN0YWxhZG8uIEVqZWN1dGEgJwogICAgICAg
:::ICAgICAgICAgICAgICdEZXNjYXJnYWRvck11c2ljYS5iYXQgcGFyYSBpbnN0YWxh
:::cmxvLicsICdlcnJvcicpCiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2Zpbics
:::ICd2ZXJzaW9uJywgVHJ1ZSwgJycpKQogICAgICAgICAgICAgICAgcmV0dXJuCiAg
:::ICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIGluc3RhbGFkYSA9IFlUX0RM
:::UC52ZXJzaW9uLl9fdmVyc2lvbl9fCiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRp
:::b246CiAgICAgICAgICAgICAgICBpbnN0YWxhZGEgPSAnPycKICAgICAgICAgICAg
:::dWx0aW1hID0gTm9uZQogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICB3
:::aXRoIHVybG9wZW4oJ2h0dHBzOi8vcHlwaS5vcmcvcHlwaS95dC1kbHAvanNvbics
:::IHRpbWVvdXQ9MTIpIGFzIHI6CiAgICAgICAgICAgICAgICAgICAgdWx0aW1hID0g
:::anNvbi5sb2FkcyhyLnJlYWQoKS5kZWNvZGUoJ3V0Zi04JykpWydpbmZvJ11bJ3Zl
:::cnNpb24nXQogICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAg
:::ICAgICAgdWx0aW1hID0gTm9uZQogICAgICAgICAgICBpZiB1bHRpbWEgaXMgTm9u
:::ZToKICAgICAgICAgICAgICAgIGxvZyhmJ3l0LWRscDogdmVyc2nDs24ge2luc3Rh
:::bGFkYX0gJwogICAgICAgICAgICAgICAgICAgICcobm8gc2UgcHVkbyBjb21wcm9i
:::YXIgc2kgaGF5IG5vdmVkYWRlcykuJywgJ2dyaXMnKQogICAgICAgICAgICBlbGlm
:::IHN0cih1bHRpbWEpID09IHN0cihpbnN0YWxhZGEpOgogICAgICAgICAgICAgICAg
:::bG9nKGYneXQtZGxwOiBlbiBsYSB1bHRpbWEgdmVyc2lvbiAoe2luc3RhbGFkYX0p
:::LicsICdpbmZvJykKICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgIGxv
:::ZyhmJ3l0LWRscDogaGF5IHZlcnNpb24gbnVldmEgKHt1bHRpbWF9KTsgaW5zdGFs
:::YWRhOiAnCiAgICAgICAgICAgICAgICAgICAgZid7aW5zdGFsYWRhfS4gUHVsc2Eg
:::Q3RybCtVIHBhcmEgYWN0dWFsaXphci4nLCAnYXZpc28nKQogICAgICAgICAgICBp
:::ZiBGRk1QRUcgaXMgTm9uZToKICAgICAgICAgICAgICAgIGxvZygnRkZtcGVnOiBO
:::TyBFTkNPTlRSQURPIOKAlCBlamVjdXRhIERlc2NhcmdhZG9yTXVzaWNhLmJhdCAn
:::CiAgICAgICAgICAgICAgICAgICAgJ3BhcmEgaW5zdGFsYXJsby4nLCAnZXJyb3In
:::KQogICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgbG9nKGYnRkZtcGVn
:::OiBPSyAoe0ZGTVBFR30pJywgJ2dyaXMnKQogICAgICAgICAgICBsb2coJ0NhcnBl
:::dGEgZGUgZ3VhcmRhZG86ICcgKyBzdHIoQUpVU1RFUy5nZXQoJ2Rlc3Rpbm8nKSks
:::ICdncmlzJykKICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAndmVyc2lvbics
:::IFRydWUsICcnKSkKCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gbWFpbgpkZWYgbWFpbigp
:::OgogICAgX3JlY29uZmlndXJhcl9zYWxpZGEoKQogICAgaWYgbm90IFRLX09LOgog
:::ICAgICAgIHByaW50KCdFc3RhIGFwbGljYWNpw7NuIG5lY2VzaXRhIFRraW50ZXIg
:::KGludGVyZmF6IGdyw6FmaWNhKS4nKQogICAgICAgIHByaW50KCdFbCBQeXRob24g
:::YWN0dWFsIG5vIGxvIGluY2x1eWUuJykKICAgICAgICBwcmludCgnVnVlbHZlIGEg
:::ZWplY3V0YXIgRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0IHBhcmEgaW5zdGFsYXIgZWwg
:::JwogICAgICAgICAgICAgICdQeXRob24gYWRlY3VhZG8uJykKICAgICAgICByZXR1
:::cm4gMQogICAgY29tcHJvYmFyX2VudG9ybm8oKQogICAgYXBwID0gQXBwKCkKICAg
:::IGFwcC5tYWlubG9vcCgpCiAgICByZXR1cm4gMAoKCmlmIF9fbmFtZV9fID09ICdf
:::X21haW5fXyc6CiAgICB0cnk6CiAgICAgICAgc3lzLmV4aXQobWFpbigpKQogICAg
:::ZXhjZXB0IFN5c3RlbUV4aXQ6CiAgICAgICAgcmFpc2UKICAgIGV4Y2VwdCBCYXNl
:::RXhjZXB0aW9uOgogICAgICAgIHRyeToKICAgICAgICAgICAgd2l0aCBvcGVuKExP
:::R19FUlJPUkVTLCAnYScsIGVuY29kaW5nPSd1dGYtOCcpIGFzIGZoOgogICAgICAg
:::ICAgICAgICAgZmgud3JpdGUodHJhY2ViYWNrLmZvcm1hdF9leGMoKSArICdcbicp
:::CiAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgcGFzcwogICAg
:::ICAgIHJhaXNlCg==
