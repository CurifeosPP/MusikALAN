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
title MusikALAN v2.2
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
echo    %C_TIT%MusikALAN v2.2%C_FIN% - preparando el entorno
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
title MusikALAN v2.2 - YouTube a AAC/MP3/FLAC/WAV/WMA/AVI
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
:::cyB5IHBhbnRhbGxhIDEyOHgxNjApOgoKICDCtyBBQUMgICgubTRhKSAgbWF4aW1v
:::IDEyOCBrYnBzCiAgwrcgTVAzICAoLm1wMykgIDEyOCAvIDE5MiAvIDI1NiAvIDMy
:::MCBrYnBzIChkZXNwbGVnYWJsZSAiQ2FsaWRhZCIpCiAgwrcgRkxBQyAoLmZsYWMp
:::IHNpbiBwZXJkaWRhCiAgwrcgV0FWICAoLndhdikgIHNpbiBwZXJkaWRhIChhcmNo
:::aXZvcyBncmFuZGVzKQogIMK3IFdNQSAgKC53bWEpICAxMjgga2JwcyAoY29kaWZp
:::Y2Fkb3Igd21hdjIgZGUgRkZtcGVnOyBlbCBjb250ZW5lZG9yCiAgICAgICAgICAg
:::ICAgICAgQVNGIG5vIGFkbWl0ZSBjYXJhdHVsYSBpbmNydXN0YWRhKQogIMK3IEFW
:::SSAgKC5hdmkpICB2aWRlbyByZWNvZGlmaWNhZG8gcGFyYSBlbCByZXByb2R1Y3Rv
:::ciBzaGVpanUgMS44IgogICAgICAgICAgICAgICAgIDEyOHgxNjAsIGNvbiBsb3Mg
:::cGFyYW1ldHJvcyBvZmljaWFsZXMgZGVsIHJlcG9zaXRvcmlvCiAgICAgICAgICAg
:::ICAgICAgZ2l0aHViLmNvbS9mZGQ0cy9wb3J0YWJsZV9tcDNfcGxheWVyX3ZpZGVv
:::X2NvbnZlcnRlcl90b29scwogICAgICAgICAgICAgICAgIChzY3JpcHQgdmlkZW8y
:::c2hlbmp1MTguc2gpCgpMYSBpbnN0YWxhY2lvbiBkZSBQeXRob24sIHl0LWRscCB5
:::IEZGbXBlZyBsYSBoYWNlIGF1dG9tYXRpY2FtZW50ZSBlbAphcmNoaXZvIERlc2Nh
:::cmdhZG9yTXVzaWNhLmJhdDsgZXN0ZSBzY3JpcHQgZXMgbGEgdmVudGFuYSBxdWUg
:::c2UgdXNhIGEKZGlhcmlvICh0ZW1hIG9zY3Vyby9jbGFybywgY29va2llcyBkZWwg
:::bmF2ZWdhZG9yLCBlc3RpbWFjaW9uIGRlIHRhbWFubwp5IGNvbXByb2JhZG9yIGRl
:::IGNhbGlkYWQgZGUgbGEgY2FycGV0YSkuCgpVc286ICBweXRob24gZGVzY2FyZ2Fk
:::b3IucHkgICAobyBkb2JsZSBjbGljIGVuIERlc2NhcmdhZG9yTXVzaWNhLmJhdCkK
:::U29sbyBkZXNjYXJnYSB2aWRlb3MgaW5kaXZpZHVhbGVzOiBzaSBsYSBVUkwgdHJh
:::ZSBsaXN0YSBkZSByZXByb2R1Y2Npb24sCnNlIGlnbm9yYSBsYSBsaXN0YSB5IHNl
:::IGJhamEgdW5pY2FtZW50ZSBlbCB2aWRlbyBwZWdhZG8uCiIiIgoKaW1wb3J0IGpz
:::b24KaW1wb3J0IG9zCmltcG9ydCBxdWV1ZQppbXBvcnQgcmUKaW1wb3J0IHNodXRp
:::bAppbXBvcnQgc3VicHJvY2VzcwppbXBvcnQgc3lzCmltcG9ydCB0aHJlYWRpbmcK
:::aW1wb3J0IHRyYWNlYmFjawpmcm9tIHBhdGhsaWIgaW1wb3J0IFBhdGgKZnJvbSB1
:::cmxsaWIucGFyc2UgaW1wb3J0IHBhcnNlX3FzLCB1cmxlbmNvZGUsIHVybHBhcnNl
:::LCB1cmx1bnBhcnNlCmZyb20gdXJsbGliLnJlcXVlc3QgaW1wb3J0IHVybG9wZW4K
:::CkFQUF9WID0gJzIuMicKQVBQX0RJUiA9IFBhdGgoX19maWxlX18pLnJlc29sdmUo
:::KS5wYXJlbnQKUlVUQV9BSlVTVEVTID0gQVBQX0RJUiAvICdhanVzdGVzLmpzb24n
:::CkxPR19FUlJPUkVTID0gQVBQX0RJUiAvICdkZXNjYXJnYWRvcl9lcnJvcmVzLmxv
:::ZycKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBzYWxpZGEKIyBBbCBlamVjdXRhcnNlIGNv
:::biBweXRob253LmV4ZSAoc2luIGNvbnNvbGEpIHN0ZG91dC9zdGRlcnIgc29uIE5v
:::bmU6CiMgY3VhbHF1aWVyIHByaW50IGZhbGxhcmlhLiBMb3MgcmVkaXJpZ2ltb3Mg
:::YSB1biBzaXRpbyBzZWd1cm8uCnRyeToKICAgIGlmIHN5cy5zdGRvdXQgaXMgTm9u
:::ZToKICAgICAgICBzeXMuc3Rkb3V0ID0gb3Blbihvcy5kZXZudWxsLCAndycsIGVu
:::Y29kaW5nPSd1dGYtOCcpCmV4Y2VwdCBFeGNlcHRpb246CiAgICBwYXNzCnRyeToK
:::ICAgIGlmIHN5cy5zdGRlcnIgaXMgTm9uZToKICAgICAgICBzeXMuc3RkZXJyID0g
:::b3BlbihMT0dfRVJST1JFUywgJ2EnLCBlbmNvZGluZz0ndXRmLTgnKQpleGNlcHQg
:::RXhjZXB0aW9uOgogICAgcGFzcwoKCmRlZiBfcmVjb25maWd1cmFyX3NhbGlkYSgp
:::OgogICAgIiIiRXZpdGEgY3Jhc2hlcyBwb3IgY2FyYWN0ZXJlcyByYXJvcyBzaSBs
:::YSBzYWxpZGEgc2UgcmVkaXJpZ2UuIiIiCiAgICBmb3IgcyBpbiAoc3lzLnN0ZG91
:::dCwgc3lzLnN0ZGVycik6CiAgICAgICAgdHJ5OgogICAgICAgICAgICBpZiBzIGFu
:::ZCBoYXNhdHRyKHMsICdyZWNvbmZpZ3VyZScpOgogICAgICAgICAgICAgICAgcy5y
:::ZWNvbmZpZ3VyZShlcnJvcnM9J3JlcGxhY2UnKQogICAgICAgIGV4Y2VwdCBFeGNl
:::cHRpb246CiAgICAgICAgICAgIHBhc3MKCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gdGtp
:::bnRlcgp0cnk6CiAgICBpbXBvcnQgdGtpbnRlciBhcyB0awogICAgZnJvbSB0a2lu
:::dGVyIGltcG9ydCBmaWxlZGlhbG9nLCBtZXNzYWdlYm94LCB0dGsKICAgIGZyb20g
:::dGtpbnRlci5zY3JvbGxlZHRleHQgaW1wb3J0IFNjcm9sbGVkVGV4dAogICAgVEtf
:::T0sgPSBUcnVlCmV4Y2VwdCBFeGNlcHRpb246CiAgICBUS19PSyA9IEZhbHNlCgoK
:::IyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tIGFqdXN0ZXMKZGVmIF9kZXN0aW5vX3Bvcl9kZWZl
:::Y3RvKCk6CiAgICBiYXNlID0gb3MuZW52aXJvbi5nZXQoJ0FQUERBVEEnKSBvciBz
:::dHIoUGF0aC5ob21lKCkgLyAnQXBwRGF0YScgLyAnUm9hbWluZycpCiAgICByZXR1
:::cm4gc3RyKFBhdGgoYmFzZSkgLyAnTXVzaWtBTEFOJykKCgpBSlVTVEVTX0RFRkVD
:::VE8gPSB7CiAgICAnZGVzdGlubyc6IF9kZXN0aW5vX3Bvcl9kZWZlY3RvKCksCiAg
:::ICAndGVtYSc6ICdPc2N1cm8nLAogICAgJ2Zvcm1hdG8nOiAnQUFDJywKICAgICdj
:::YWxpZGFkJzogJzEyOGsnLAogICAgJ2VtYmViZXInOiBUcnVlLAogICAgJ25hdmVn
:::YWRvcic6ICcobmluZ3VubyknLAp9CgoKZGVmIGNhcmdhcl9hanVzdGVzKCk6CiAg
:::ICBhID0gZGljdChBSlVTVEVTX0RFRkVDVE8pCiAgICB0cnk6CiAgICAgICAgYS51
:::cGRhdGUoanNvbi5sb2FkcyhSVVRBX0FKVVNURVMucmVhZF90ZXh0KGVuY29kaW5n
:::PSd1dGYtOCcpKSkKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgcGFzcwog
:::ICAgIyBtaWdyYWNpb246IGxhIHYyLjAvMi4xIGd1YXJkYWJhIHBvciBkZWZlY3Rv
:::IE11c2ljL1lURG93bmxvYWRlcjsKICAgICMgc2kgZWwgZGVzdGlubyBndWFyZGFk
:::byBhcHVudGEgYWhpLCBzZSBwYXNhIGEgQXBwRGF0YVxSb2FtaW5nXE11c2lrQUxB
:::TgogICAgZGVzdGlub192aWVqbyA9IHN0cihhLmdldCgnZGVzdGlubycpIG9yICcn
:::KS5yZXBsYWNlKCdcXCcsICcvJykubG93ZXIoKQogICAgaWYgJ3l0ZG93bmxvYWRl
:::cicgaW4gZGVzdGlub192aWVqbzoKICAgICAgICBhWydkZXN0aW5vJ10gPSBBSlVT
:::VEVTX0RFRkVDVE9bJ2Rlc3Rpbm8nXQogICAgcmV0dXJuIGEKCgpkZWYgZ3VhcmRh
:::cl9hanVzdGVzKCk6CiAgICB0cnk6CiAgICAgICAgUlVUQV9BSlVTVEVTLndyaXRl
:::X3RleHQoCiAgICAgICAgICAgIGpzb24uZHVtcHMoQUpVU1RFUywgZW5zdXJlX2Fz
:::Y2lpPUZhbHNlLCBpbmRlbnQ9MiksCiAgICAgICAgICAgIGVuY29kaW5nPSd1dGYt
:::OCcpCiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHBhc3MKCgpBSlVTVEVT
:::ID0gY2FyZ2FyX2FqdXN0ZXMoKQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSB1dGlscwpk
:::ZWYgZm10X3RhbShuKToKICAgIGlmIG5vdCBuOgogICAgICAgIHJldHVybiAn4oCU
:::JwogICAgbiA9IGZsb2F0KG4pCiAgICBmb3IgdSBpbiAoJ0InLCAnS2lCJywgJ01p
:::QicsICdHaUInKToKICAgICAgICBpZiBuIDwgMTAyNCBvciB1ID09ICdHaUInOgog
:::ICAgICAgICAgICByZXR1cm4gZid7aW50KG4pfSB7dX0nIGlmIHUgPT0gJ0InIGVs
:::c2UgZid7bjouMWZ9IHt1fScKICAgICAgICBuIC89IDEwMjQKCgpkZWYgZm10X3Rp
:::ZW0ocyk6CiAgICBpZiBzIGlzIE5vbmU6CiAgICAgICAgcmV0dXJuICfigJQnCiAg
:::ICBzID0gaW50KHMpCiAgICBoLCByID0gZGl2bW9kKHMsIDM2MDApCiAgICBtLCB4
:::ID0gZGl2bW9kKHIsIDYwKQogICAgcmV0dXJuIGYne2h9OnttOjAyZH06e3g6MDJk
:::fScgaWYgaCBlbHNlIGYne206MDJkfTp7eDowMmR9JwoKCmRlZiBsaW1waWFyX25v
:::bWJyZSh0KToKICAgIHQgPSByZS5zdWIocidbPD46Ii9cXHw/Klx4MDAtXHgxZl0n
:::LCAnXycsIHN0cih0KSkuc3RyaXAoJyAuJykKICAgIHJldHVybiB0WzoxNTBdIG9y
:::ICdzaW5fdGl0dWxvJwoKCmRlZiBzaW5fcGxheWxpc3QodXJsKToKICAgICIiIlF1
:::aXRhIGVsIHBhcsOhbWV0cm8gbGlzdD0gZGUgbGEgVVJMIChtb2RvIHNvbG8gdmlk
:::ZW8pLiIiIgogICAgdHJ5OgogICAgICAgIHAgPSB1cmxwYXJzZSh1cmwpCiAgICAg
:::ICAgcSA9IHBhcnNlX3FzKHAucXVlcnkpCiAgICAgICAgaWYgJ2xpc3QnIGluIHE6
:::CiAgICAgICAgICAgIGRlbCBxWydsaXN0J10KICAgICAgICAgICAgcmV0dXJuIHVy
:::bHVucGFyc2UocC5fcmVwbGFjZShxdWVyeT11cmxlbmNvZGUocSwgZG9zZXE9VHJ1
:::ZSkpKSwgVHJ1ZQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICBwYXNzCiAg
:::ICByZXR1cm4gdXJsLCBGYWxzZQoKCmRlZiBhYnJpcl9jYXJwZXRhKHJ1dGEpOgog
:::ICAgdHJ5OgogICAgICAgIGlmIG9zLm5hbWUgPT0gJ250JzoKICAgICAgICAgICAg
:::b3Muc3RhcnRmaWxlKHN0cihydXRhKSkgICMgbm9xYTogc29sbyBXaW5kb3dzCiAg
:::ICAgICAgZWxzZToKICAgICAgICAgICAgc3VicHJvY2Vzcy5Qb3BlbihbJ3hkZy1v
:::cGVuJywgc3RyKHJ1dGEpXSkKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAg
:::cGFzcwoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBmZm1wZWcKZGVmIGJ1c2Nhcl9mZm1w
:::ZWcoKToKICAgIGV4ZSA9IHNodXRpbC53aGljaCgnZmZtcGVnJykKICAgIGlmIGV4
:::ZToKICAgICAgICByZXR1cm4gUGF0aChleGUpCiAgICBjYW5kaWRhdG9zID0gWwog
:::ICAgICAgIEFQUF9ESVIgLyAnZmZtcGVnJyAvICdiaW4nIC8gJ2ZmbXBlZy5leGUn
:::LAogICAgICAgIEFQUF9ESVIgLyAnZmZtcGVnJyAvICdiaW4nIC8gJ2ZmbXBlZycs
:::CiAgICAgICAgQVBQX0RJUiAvICdydW50aW1lJyAvICdmZm1wZWcuZXhlJywKICAg
:::IF0KICAgIGZvciBwIGluIGNhbmRpZGF0b3M6CiAgICAgICAgaWYgcC5leGlzdHMo
:::KToKICAgICAgICAgICAgcmV0dXJuIHAKICAgIHJldHVybiBOb25lCgoKZGVmIGJ1
:::c2Nhcl9mZnByb2JlKGZmbXBlZyk6CiAgICBpZiBmZm1wZWcgaXMgTm9uZToKICAg
:::ICAgICByZXR1cm4gc2h1dGlsLndoaWNoKCdmZnByb2JlJykKICAgIHAgPSBmZm1w
:::ZWcud2l0aF9uYW1lKCdmZnByb2JlLmV4ZScgaWYgb3MubmFtZSA9PSAnbnQnIGVs
:::c2UgJ2ZmcHJvYmUnKQogICAgaWYgcC5leGlzdHMoKToKICAgICAgICByZXR1cm4g
:::cAogICAgcmV0dXJuIHNodXRpbC53aGljaCgnZmZwcm9iZScpCgoKWVRfRExQID0g
:::Tm9uZSAgICMgbcOzZHVsbyB5dF9kbHA7IHNlIHJlbGxlbmEgZW4gY29tcHJvYmFy
:::X2VudG9ybm8oKQpGRk1QRUcgPSBOb25lICAgIyBydXRhIGRlIGZmbXBlZwpGRlBS
:::T0JFID0gTm9uZSAgIyBydXRhIGRlIGZmcHJvYmUKCgpkZWYgY29tcHJvYmFyX2Vu
:::dG9ybm8oKToKICAgIGdsb2JhbCBZVF9ETFAsIEZGTVBFRywgRkZQUk9CRQogICAg
:::dHJ5OgogICAgICAgIGltcG9ydCB5dF9kbHAgYXMgbW9kCiAgICAgICAgWVRfRExQ
:::ID0gbW9kCiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHBhc3MKICAgIEZG
:::TVBFRyA9IGJ1c2Nhcl9mZm1wZWcoKQogICAgRkZQUk9CRSA9IGJ1c2Nhcl9mZnBy
:::b2JlKEZGTVBFRykKCgpjbGFzcyBSZWdpc3RybzoKICAgICIiIkxvZ2dlciBwYXJh
:::IHl0LWRscDogcmVlbnbDrWEgYXZpc29zL2Vycm9yZXMgYWwgcmVnaXN0cm8gZGUg
:::bGEgR1VJLiIiIgoKICAgIGRlZiBfX2luaXRfXyhzZWxmKToKICAgICAgICBzZWxm
:::LmxvZyA9IE5vbmUgICMgbGEgR1VJIGxvIGNvbmVjdGE6IGxvZyhtZW5zYWplLCBl
:::dGlxdWV0YSkKCiAgICBkZWYgZGVidWcoc2VsZiwgbSk6CiAgICAgICAgcGFzcwoK
:::ICAgIGRlZiB3YXJuaW5nKHNlbGYsIG0pOgogICAgICAgIG0gPSBzdHIobSkuc3Ry
:::aXAoKQogICAgICAgIGlmIG0gYW5kIHNlbGYubG9nOgogICAgICAgICAgICBzZWxm
:::LmxvZyhtLCAnYXZpc28nKQoKICAgIGRlZiBlcnJvcihzZWxmLCBtKToKICAgICAg
:::ICBtID0gc3RyKG0pLnN0cmlwKCkKICAgICAgICBpZiBtIGFuZCBzZWxmLmxvZzoK
:::ICAgICAgICAgICAgc2VsZi5sb2cobSwgJ2Vycm9yJykKCgpSRUdJU1RSTyA9IFJl
:::Z2lzdHJvKCkKCk5PTUJSRVNfUFAgPSB7CiAgICAnRkZtcGVnRXh0cmFjdEF1ZGlv
:::JzogJ0NvbnZpcnRpZW5kbyBlbCBhdWRpbyBjb24gRkZtcGVnJywKICAgICdGRm1w
:::ZWdNZXRhZGF0YSc6ICdFc2NyaWJpZW5kbyBldGlxdWV0YXMgKHTDrXR1bG8vYXJ0
:::aXN0YSknLAogICAgJ0VtYmVkVGh1bWJuYWlsJzogJ0luY3J1c3RhbmRvIGxhIGNh
:::csOhdHVsYScsCiAgICAnTW92ZUZpbGVzJzogJ09yZ2FuaXphbmRvIGFyY2hpdm9z
:::JywKICAgICdGRm1wZWdNZXJnZXInOiAnVW5pZW5kbyBwaXN0YXMgZGUgdmlkZW8g
:::eSBhdWRpbycsCiAgICAnRkZtcGVnVmlkZW9Db252ZXJ0b3InOiAnQ29udmlydGll
:::bmRvIGVsIHZpZGVvJywKfQoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGZvcm1hdG9zCkZP
:::Uk1BVE9TID0gewogICAgJ0FBQyc6IGRpY3QodGV4dG89J0FBQyAoLm00YSknLCBj
:::YXJwZXRhPSdBQUMnLCBleHQ9J200YScsCiAgICAgICAgICAgICAgICBjYWxpZGFk
:::ZXM9WycxMjhrJ10sIGRlZmVjdG89JzEyOGsnKSwKICAgICdNUDMnOiBkaWN0KHRl
:::eHRvPSdNUDMgKC5tcDMpJywgY2FycGV0YT0nTVAzJywgZXh0PSdtcDMnLAogICAg
:::ICAgICAgICAgICAgY2FsaWRhZGVzPVsnMTI4aycsICcxOTJrJywgJzI1NmsnLCAn
:::MzIwayddLCBkZWZlY3RvPSczMjBrJyksCiAgICAnRkxBQyc6IGRpY3QodGV4dG89
:::J0ZMQUMgKC5mbGFjKScsIGNhcnBldGE9J0ZMQUMnLCBleHQ9J2ZsYWMnLAogICAg
:::ICAgICAgICAgICAgIGNhbGlkYWRlcz1bJ3NpbiBwZXJkaWRhJ10sIGRlZmVjdG89
:::J3NpbiBwZXJkaWRhJyksCiAgICAnV0FWJzogZGljdCh0ZXh0bz0nV0FWICgud2F2
:::KScsIGNhcnBldGE9J1dBVicsIGV4dD0nd2F2JywKICAgICAgICAgICAgICAgIGNh
:::bGlkYWRlcz1bJ3NpbiBwZXJkaWRhJ10sIGRlZmVjdG89J3NpbiBwZXJkaWRhJyks
:::CiAgICAnV01BJzogZGljdCh0ZXh0bz0nV01BICgud21hKScsIGNhcnBldGE9J1dN
:::QScsIGV4dD0nd21hJywKICAgICAgICAgICAgICAgIGNhbGlkYWRlcz1bJzEyOGsn
:::XSwgZGVmZWN0bz0nMTI4aycpLAogICAgJ0FWSSc6IGRpY3QodGV4dG89J0FWSSAt
:::IHNoZWlqdSAxLjgiICgxMjh4MTYwKScsIGNhcnBldGE9J0FWSScsIGV4dD0nYXZp
:::JywKICAgICAgICAgICAgICAgIGNhbGlkYWRlcz1bJzEyOHgxNjAgwrcgMTYgZnBz
:::J10sIGRlZmVjdG89JzEyOHgxNjAgwrcgMTYgZnBzJyksCn0KCgojIC0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0gcHJvZ3Jlc28KZGVmIGhvb2tzX2d1aShjb2xhKToKICAgICIiIkNy
:::ZWEgbG9zIGhvb2tzIGRlIHl0LWRscCBxdWUgcHVibGljYW4gZXZlbnRvcyBlbiBs
:::YSBjb2xhIGRlIGxhIEdVSS4iIiIKICAgIGVzdGFkbyA9IHsndGl0dWxvJzogRmFs
:::c2V9CgogICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAgICAgICAgY29sYS5wdXQo
:::KCdsb2cnLCBtLCB0KSkKCiAgICBkZWYgcHJvZ3Jlc28oZCk6CiAgICAgICAgaWYg
:::ZFsnc3RhdHVzJ10gPT0gJ2Rvd25sb2FkaW5nJzoKICAgICAgICAgICAgaWYgbm90
:::IGVzdGFkb1sndGl0dWxvJ106CiAgICAgICAgICAgICAgICBpbmZvID0gZC5nZXQo
:::J2luZm9fZGljdCcpIG9yIHt9CiAgICAgICAgICAgICAgICB0ID0gaW5mby5nZXQo
:::J3RpdGxlJykgb3IgUGF0aChkLmdldCgnZmlsZW5hbWUnKSBvciAnJykuc3RlbQog
:::ICAgICAgICAgICAgICAgaWYgdDoKICAgICAgICAgICAgICAgICAgICBsb2coJ+KZ
:::qiAnICsgc3RyKHQpWzo5MF0sICd0aXR1bG8nKQogICAgICAgICAgICAgICAgICAg
:::IGVzdGFkb1sndGl0dWxvJ10gPSBUcnVlCiAgICAgICAgICAgIHRvdGFsID0gZC5n
:::ZXQoJ3RvdGFsX2J5dGVzJykgb3IgZC5nZXQoJ3RvdGFsX2J5dGVzX2VzdGltYXRl
:::Jykgb3IgMAogICAgICAgICAgICBkb25lID0gZC5nZXQoJ2Rvd25sb2FkZWRfYnl0
:::ZXMnLCAwKQogICAgICAgICAgICB2ZWwgPSBkLmdldCgnc3BlZWQnKQogICAgICAg
:::ICAgICBldGEgPSBkLmdldCgnZXRhJykKICAgICAgICAgICAgaWYgdG90YWw6CiAg
:::ICAgICAgICAgICAgICBwY3QgPSBkb25lIC8gdG90YWwgKiAxMDAKICAgICAgICAg
:::ICAgICAgIHRleHRvID0gZid7cGN0OjUuMWZ9JSDCtyB7Zm10X3RhbShkb25lKX0g
:::LyB7Zm10X3RhbSh0b3RhbCl9JwogICAgICAgICAgICAgICAgaWYgdmVsOgogICAg
:::ICAgICAgICAgICAgICAgIHRleHRvICs9IGYnIMK3IHtmbXRfdGFtKHZlbCl9L3Mn
:::CiAgICAgICAgICAgICAgICBpZiBldGEgaXMgbm90IE5vbmU6CiAgICAgICAgICAg
:::ICAgICAgICAgdGV4dG8gKz0gZicgwrcgcXVlZGFuIHtmbXRfdGllbShldGEpfScK
:::ICAgICAgICAgICAgICAgIGNvbGEucHV0KCgncHJvZycsIHBjdCwgdGV4dG8pKQog
:::ICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgdiA9IGYne2ZtdF90YW0o
:::dmVsKX0vcycgaWYgdmVsIGVsc2UgJycKICAgICAgICAgICAgICAgIGNvbGEucHV0
:::KCgncHJvZycsIE5vbmUsIGYne2ZtdF90YW0oZG9uZSl9IMK3IHt2fScpKQogICAg
:::ICAgIGVsaWYgZFsnc3RhdHVzJ10gPT0gJ2ZpbmlzaGVkJzoKICAgICAgICAgICAg
:::Y29sYS5wdXQoKCdsb2cnLCAnRGVzY2FyZ2EgcmVjaWJpZGEuIFByb2Nlc2FuZG8u
:::Li4nLCAnZ3JpcycpKQogICAgICAgICAgICBjb2xhLnB1dCgoJ3Byb2cnLCAwLCAn
:::UHJvY2VzYW5kby4uLicpKQoKICAgIGRlZiBwb3N0cHJvY2VzbyhkKToKICAgICAg
:::ICBpZiBkWydzdGF0dXMnXSA9PSAnc3RhcnRlZCc6CiAgICAgICAgICAgIG5vbSA9
:::IChkLmdldCgncG9zdHByb2Nlc3Nvcl9uYW1lJykKICAgICAgICAgICAgICAgICAg
:::IG9yIGQuZ2V0KCdwb3N0cHJvY2Vzc29yJykgb3IgJ1Bvc3Rwcm9jZXNvJykKICAg
:::ICAgICAgICAgdGV4dG8gPSBOT01CUkVTX1BQLmdldChub20sIG5vbSkgKyAnLi4u
:::JwogICAgICAgICAgICBjb2xhLnB1dCgoJ2xvZycsICfihpIgJyArIHRleHRvLCAn
:::Z3JpcycpKQogICAgICAgICAgICBjb2xhLnB1dCgoJ3Byb2cnLCBOb25lLCB0ZXh0
:::bykpCgogICAgcmV0dXJuIHByb2dyZXNvLCBwb3N0cHJvY2VzbwoKCiMgLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLSBvcGNpb25lcwpkZWYgb3B0c19iYXNlKGNhcnBldGEsIGNvb2tp
:::ZXMsIGNvbGEpOgogICAgcHJvZ3Jlc28sIHBvc3Rwcm9jZXNvID0gaG9va3NfZ3Vp
:::KGNvbGEpCiAgICBvID0gewogICAgICAgICdvdXR0bXBsJzogc3RyKGNhcnBldGEg
:::LyAnJSh0aXRsZSlzLiUoZXh0KXMnKSwKICAgICAgICAncXVpZXQnOiBUcnVlLAog
:::ICAgICAgICdub193YXJuaW5ncyc6IFRydWUsCiAgICAgICAgJ25vcHJvZ3Jlc3Mn
:::OiBUcnVlLAogICAgICAgICdub3BsYXlsaXN0JzogVHJ1ZSwKICAgICAgICAnaWdu
:::b3JlZXJyb3JzJzogRmFsc2UsCiAgICAgICAgJ3JldHJpZXMnOiAxMCwKICAgICAg
:::ICAnZnJhZ21lbnRfcmV0cmllcyc6IDEwLAogICAgICAgICdzb2NrZXRfdGltZW91
:::dCc6IDMwLAogICAgICAgICdjb25jdXJyZW50X2ZyYWdtZW50X2Rvd25sb2Fkcyc6
:::IDQsCiAgICAgICAgJ3dpbmRvd3NmaWxlbmFtZXMnOiBUcnVlLAogICAgICAgICdv
:::dmVyd3JpdGVzJzogRmFsc2UsCiAgICAgICAgJ2xvZ2dlcic6IFJFR0lTVFJPLAog
:::ICAgICAgICdwcm9ncmVzc19ob29rcyc6IFtwcm9ncmVzb10sCiAgICAgICAgJ3Bv
:::c3Rwcm9jZXNzb3JfaG9va3MnOiBbcG9zdHByb2Nlc29dLAogICAgfQogICAgaWYg
:::Y29va2llcyBhbmQgY29va2llcyAhPSAnKG5pbmd1bm8pJzoKICAgICAgICBvWydj
:::b29raWVzZnJvbWJyb3dzZXInXSA9IChjb29raWVzLCkKICAgIGlmIEZGTVBFRzoK
:::ICAgICAgICBvWydmZm1wZWdfbG9jYXRpb24nXSA9IHN0cihGRk1QRUcucGFyZW50
:::KQogICAgcmV0dXJuIG8KCgpkZWYgY29udmVydGlyX2ZmbXBlZyhjbWQsIGV0aXF1
:::ZXRhLCBjb2xhKToKICAgICIiIkVqZWN1dGEgRkZtcGVnIChsaXN0YSBkZSBhcmd1
:::bWVudG9zLCBzaW4gc2hlbGwpIGNvbiBtYXJxdWVlLiIiIgogICAgY29sYS5wdXQo
:::KCdwcm9nJywgTm9uZSwgZXRpcXVldGEpKQoKICAgIGRlZiBsb2cobSwgdD0naW5m
:::bycpOgogICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgdHJ5Ogog
:::ICAgICAgIHAgPSBzdWJwcm9jZXNzLnJ1bihjbWQsIHN0ZG91dD1zdWJwcm9jZXNz
:::LlBJUEUsCiAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0ZGVycj1zdWJwcm9j
:::ZXNzLlBJUEUsIHRleHQ9VHJ1ZSwKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ZW5jb2Rpbmc9J3V0Zi04JywgZXJyb3JzPSdyZXBsYWNlJykKICAgIGV4Y2VwdCBG
:::aWxlTm90Rm91bmRFcnJvcjoKICAgICAgICBwID0gTm9uZQogICAgaWYgcCBpcyBO
:::b25lIG9yIHAucmV0dXJuY29kZSAhPSAwOgogICAgICAgIGxvZygn4pyWIEZGbXBl
:::ZyBkZXZvbHZpw7MgdW4gZXJyb3I6JywgJ2Vycm9yJykKICAgICAgICBpZiBwIGlz
:::IG5vdCBOb25lOgogICAgICAgICAgICBmb3IgbG4gaW4gKHAuc3RkZXJyIG9yICcn
:::KS5zdHJpcCgpLnNwbGl0bGluZXMoKVstNDpdOgogICAgICAgICAgICAgICAgbG9n
:::KCcgICAnICsgbG5bOjE4MF0sICdncmlzJykKICAgICAgICBjb2xhLnB1dCgoJ3By
:::b2cnLCAwLCAnJykpCiAgICAgICAgcmV0dXJuIEZhbHNlCiAgICByZXR1cm4gVHJ1
:::ZQoKCmRlZiBhcmNoaXZvX2ZpbmFsKGluZm8sIGNhcnBldGEsIGV4dCk6CiAgICAi
:::IiJMb2NhbGl6YSBlbCBhcmNoaXZvIHJlc3VsdGFudGUgKHl0LWRscCBsbyByZXBv
:::cnRhOyBmYWxsYmFjazogbcOhcyBudWV2bykuIiIiCiAgICB0cnk6CiAgICAgICAg
:::Zm9yIGQgaW4gKGluZm8uZ2V0KCdyZXF1ZXN0ZWRfZG93bmxvYWRzJykgb3IgW10p
:::OgogICAgICAgICAgICBmID0gZC5nZXQoJ2ZpbGVwYXRoJykKICAgICAgICAgICAg
:::aWYgZjoKICAgICAgICAgICAgICAgIHJldHVybiBQYXRoKGYpCiAgICBleGNlcHQg
:::RXhjZXB0aW9uOgogICAgICAgIHBhc3MKICAgIGNhbmQgPSBzb3J0ZWQoY2FycGV0
:::YS5nbG9iKCcqLicgKyBleHQpLAogICAgICAgICAgICAgICAgICBrZXk9bGFtYmRh
:::IHA6IHAuc3RhdCgpLnN0X210aW1lLCByZXZlcnNlPVRydWUpCiAgICByZXR1cm4g
:::Y2FuZFswXSBpZiBjYW5kIGVsc2UgTm9uZQoKCmRlZiBsaW1waWFyX21pbmlhdHVy
:::YXMoY2FycGV0YSwgYXJjaGl2byk6CiAgICAiIiJCb3JyYSBtaW5pYXR1cmFzIHN1
:::ZWx0YXMgcXVlIEVtYmVkVGh1bWJuYWlsIGRlamFyYSBzaW4gaW5jcnVzdGFyLiIi
:::IgogICAgZm9yIGV4dCBpbiAoJy53ZWJwJywgJy5qcGcnLCAnLmpwZWcnLCAnLnBu
:::ZycpOgogICAgICAgIHQgPSBhcmNoaXZvLndpdGhfc3VmZml4KGV4dCkKICAgICAg
:::ICBpZiB0LmV4aXN0cygpOgogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAg
:::ICB0LnVubGluaygpCiAgICAgICAgICAgIGV4Y2VwdCBPU0Vycm9yOgogICAgICAg
:::ICAgICAgICAgcGFzcwoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBkZXNjYXJnYXMKZGVm
:::IGRlc2Nhcmdhcl9hdWRpbyh1cmwsIG5vbWJyZV9mbXQsIGNhbGlkYWQsIGRlc3Rp
:::bm8sIGVtYmViZXIsIGNvb2tpZXMsIGNvbGEpOgogICAgIiIiQUFDICgubTRhKSAv
:::IE1QMyAvIEZMQUMgLyBXQVYgdsOtYSBwb3N0cHJvY2VzYWRvcmVzIGRlIHl0LWRs
:::cC4iIiIKICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgogICAgICAgIGNvbGEucHV0
:::KCgnbG9nJywgbSwgdCkpCgogICAgZm10ID0gRk9STUFUT1Nbbm9tYnJlX2ZtdF0K
:::ICAgIGNhcnBldGEgPSBkZXN0aW5vIC8gZm10WydjYXJwZXRhJ10KICAgIGNhcnBl
:::dGEubWtkaXIocGFyZW50cz1UcnVlLCBleGlzdF9vaz1UcnVlKQogICAgY29kZWMg
:::PSBmbXRbJ2V4dCddCiAgICBjb25fcG9ydGFkYSA9IGVtYmViZXIgYW5kIG5vbWJy
:::ZV9mbXQgaW4gKCdBQUMnLCAnTVAzJywgJ0ZMQUMnKQogICAgY29uX3RhZ3MgPSBl
:::bWJlYmVyCiAgICBwcHMgPSBbeydrZXknOiAnRkZtcGVnRXh0cmFjdEF1ZGlvJywg
:::J3ByZWZlcnJlZGNvZGVjJzogY29kZWMsCiAgICAgICAgICAgICdwcmVmZXJyZWRx
:::dWFsaXR5JzogY2FsaWRhZCBvciAnMCd9XQogICAgaWYgY29uX3RhZ3M6CiAgICAg
:::ICAgcHBzLmFwcGVuZCh7J2tleSc6ICdGRm1wZWdNZXRhZGF0YScsICdhZGRfbWV0
:::YWRhdGEnOiBUcnVlfSkKICAgIGlmIGNvbl9wb3J0YWRhOgogICAgICAgIHBwcy5h
:::cHBlbmQoeydrZXknOiAnRW1iZWRUaHVtYm5haWwnLAogICAgICAgICAgICAgICAg
:::ICAgICdhbHJlYWR5X2hhdmVfdGh1bWJuYWlsJzogRmFsc2V9KQogICAgbyA9IG9w
:::dHNfYmFzZShjYXJwZXRhLCBjb29raWVzLCBjb2xhKQogICAgb1snZm9ybWF0J10g
:::PSAnYmVzdGF1ZGlvL2Jlc3QnCiAgICBvWydwb3N0cHJvY2Vzc29ycyddID0gcHBz
:::CiAgICBvWyd3cml0ZXRodW1ibmFpbCddID0gY29uX3BvcnRhZGEKICAgIHdpdGgg
:::WVRfRExQLllvdXR1YmVETChvKSBhcyB5ZGw6CiAgICAgICAgaW5mbyA9IHlkbC5l
:::eHRyYWN0X2luZm8odXJsLCBkb3dubG9hZD1UcnVlKQogICAgYXJjaGl2byA9IGFy
:::Y2hpdm9fZmluYWwoaW5mbywgY2FycGV0YSwgY29kZWMpCiAgICBpZiBhcmNoaXZv
:::IGFuZCBjb25fcG9ydGFkYToKICAgICAgICBsaW1waWFyX21pbmlhdHVyYXMoY2Fy
:::cGV0YSwgYXJjaGl2bykKICAgIHJldHVybiBpbmZvLCBhcmNoaXZvCgoKZGVmIGRl
:::c2Nhcmdhcl93bWEodXJsLCBkZXN0aW5vLCBlbWJlYmVyLCBjb29raWVzLCBjb2xh
:::KToKICAgICIiIldNQSAxMjgga2JwczogeXQtZGxwIG5vIHNvcG9ydGEgd21hLCBh
:::c8OtIHF1ZSBzZSBiYWphIGEgV0FWIChjb24KICAgIGV0aXF1ZXRhcykgeSBsdWVn
:::byBGRm1wZWcgcmVjb2RpZmljYSBhIHdtYXYyIGRlbnRybyBkZWwgLndtYSBmaW5h
:::bC4KICAgIChFbCBjb250ZW5lZG9yIEFTRiBkZSBmZm1wZWcgbm8gc29wb3J0YSBj
:::YXLDoXR1bGEgaW5jcnVzdGFkYS4pIiIiCiAgICBkZWYgbG9nKG0sIHQ9J2luZm8n
:::KToKICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgIGNhcnBldGEg
:::PSBkZXN0aW5vIC8gJ1dNQScKICAgIHRtcCA9IGNhcnBldGEgLyAnX3RtcCcKICAg
:::IHNodXRpbC5ybXRyZWUodG1wLCBpZ25vcmVfZXJyb3JzPVRydWUpCiAgICB0bXAu
:::bWtkaXIocGFyZW50cz1UcnVlLCBleGlzdF9vaz1UcnVlKQogICAgbyA9IG9wdHNf
:::YmFzZSh0bXAsIGNvb2tpZXMsIGNvbGEpCiAgICBvWydmb3JtYXQnXSA9ICdiZXN0
:::YXVkaW8vYmVzdCcKICAgIHBwcyA9IFt7J2tleSc6ICdGRm1wZWdFeHRyYWN0QXVk
:::aW8nLCAncHJlZmVycmVkY29kZWMnOiAnd2F2JywKICAgICAgICAgICAgJ3ByZWZl
:::cnJlZHF1YWxpdHknOiAnMCd9XQogICAgaWYgZW1iZWJlcjoKICAgICAgICBwcHMu
:::YXBwZW5kKHsna2V5JzogJ0ZGbXBlZ01ldGFkYXRhJywgJ2FkZF9tZXRhZGF0YSc6
:::IFRydWV9KQogICAgb1sncG9zdHByb2Nlc3NvcnMnXSA9IHBwcwogICAgd2l0aCBZ
:::VF9ETFAuWW91dHViZURMKG8pIGFzIHlkbDoKICAgICAgICBpbmZvID0geWRsLmV4
:::dHJhY3RfaW5mbyh1cmwsIGRvd25sb2FkPVRydWUpCiAgICB3YXYgPSBhcmNoaXZv
:::X2ZpbmFsKGluZm8sIHRtcCwgJ3dhdicpCiAgICBpZiBub3Qgd2F2OgogICAgICAg
:::IHJhaXNlIFJ1bnRpbWVFcnJvcignTm8gc2UgZW5jb250csOzIGVsIFdBViBpbnRl
:::cm1lZGlvLicpCiAgICBtZXRhID0gW10KICAgIGlmIGVtYmViZXI6CiAgICAgICAg
:::YXJ0aXN0YSA9IChpbmZvLmdldCgnYXJ0aXN0Jykgb3IgaW5mby5nZXQoJ3VwbG9h
:::ZGVyJykKICAgICAgICAgICAgICAgICAgIG9yIGluZm8uZ2V0KCdjaGFubmVsJykg
:::b3IgJycpCiAgICAgICAgaWYgaW5mby5nZXQoJ3RpdGxlJyk6CiAgICAgICAgICAg
:::IG1ldGEgKz0gWyctbWV0YWRhdGEnLCAndGl0bGU9JyArIHN0cihpbmZvWyd0aXRs
:::ZSddKV0KICAgICAgICBpZiBhcnRpc3RhOgogICAgICAgICAgICBtZXRhICs9IFsn
:::LW1ldGFkYXRhJywgJ2FydGlzdD0nICsgc3RyKGFydGlzdGEpXQogICAgICAgIG1l
:::dGEgKz0gWyctbWV0YWRhdGEnLCAnYWxidW09WW91VHViZSddCiAgICB3bWEgPSBj
:::YXJwZXRhIC8gKGxpbXBpYXJfbm9tYnJlKGluZm8uZ2V0KCd0aXRsZScpIG9yICdh
:::dWRpbycpICsgJy53bWEnKQogICAgY21kID0gW3N0cihGRk1QRUcpLCAnLXknLCAn
:::LWknLCBzdHIod2F2KSwgJy12bicsCiAgICAgICAgICAgJy1jOmEnLCAnd21hdjIn
:::LCAnLWI6YScsICcxMjhrJ10gKyBtZXRhICsgW3N0cih3bWEpXQogICAgb2sgPSBj
:::b252ZXJ0aXJfZmZtcGVnKGNtZCwgJ0NvbnZpcnRpZW5kbyBhIFdNQSAod21hdjIg
:::wrcgMTI4IGticHMpJywgY29sYSkKICAgIGlmIG5vdCBvazoKICAgICAgICByYWlz
:::ZSBSdW50aW1lRXJyb3IoJ0ZGbXBlZyBubyBwdWRvIGNyZWFyIGVsIGFyY2hpdm8g
:::V01BLicpCiAgICBzaHV0aWwucm10cmVlKHRtcCwgaWdub3JlX2Vycm9ycz1UcnVl
:::KQogICAgcmV0dXJuIGluZm8sIHdtYQoKCiMgUGFyw6FtZXRyb3Mgb2ZpY2lhbGVz
:::IGRlbCByZXBvIGZkZDRzL3BvcnRhYmxlX21wM19wbGF5ZXJfdmlkZW9fY29udmVy
:::dGVyX3Rvb2xzCiMgKHZpZGVvMnNoZW5qdTE4LnNoKTogTUpQRUcgMTYgZnBzICsg
:::UENNIDIyMDUwIEh6LCByb3RhZG9zIHBhcmEgbGEgcGFudGFsbGEKIyB2ZXJ0aWNh
:::bCBkZSAxMjh4MTYwIGRlbCByZXByb2R1Y3RvciBzaGVpanUgZGUgMS44IHB1bGdh
:::ZGFzLgpWRl9TSEVJSlUgPSAnc2NhbGU9LTI6MTI4LCBjcm9wPTE2MDoxMjgsIHRy
:::YW5zcG9zZT0yLCB2ZmxpcCcKIyBWYXJpYW50ZSBhIHBydWViYSBkZSBiYWxhcyBw
:::YXJhIHZpZGVvcyBjdWFkcmFkb3MvdmVydGljYWxlcyAoU2hvcnRzKSwKIyBkb25k
:::ZSBlbCByZWNvcnRlIDE2MDoxMjggb3JpZ2luYWwgc2Vyw61hIGltcG9zaWJsZToK
:::VkZfU0VHVVJPID0gKCdzY2FsZT0xNjA6MTI4OmZvcmNlX29yaWdpbmFsX2FzcGVj
:::dF9yYXRpbz1kZWNyZWFzZSwnCiAgICAgICAgICAgICAncGFkPTE2MDoxMjg6KG93
:::LWl3KS8yOihvaC1paCkvMix0cmFuc3Bvc2U9Mix2ZmxpcCcpCgoKZGVmIGRlc2Nh
:::cmdhcl9hdmkodXJsLCBkZXN0aW5vLCBjb29raWVzLCBjb2xhKToKICAgICIiIlZp
:::ZGVvIEFWSSBwYXJhIGVsIHJlcHJvZHVjdG9yIHNoZWlqdSAxLjgiIDEyOHgxNjAu
:::IiIiCiAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAgICBjb2xhLnB1dCgo
:::J2xvZycsIG0sIHQpKQoKICAgIGNhcnBldGEgPSBkZXN0aW5vIC8gJ0FWSScKICAg
:::IHRtcCA9IGNhcnBldGEgLyAnX3RtcCcKICAgIHNodXRpbC5ybXRyZWUodG1wLCBp
:::Z25vcmVfZXJyb3JzPVRydWUpCiAgICB0bXAubWtkaXIocGFyZW50cz1UcnVlLCBl
:::eGlzdF9vaz1UcnVlKQogICAgbyA9IG9wdHNfYmFzZSh0bXAsIGNvb2tpZXMsIGNv
:::bGEpCiAgICAjIFBhcmEgdW5hIHBhbnRhbGxhIGRlIDEyOHgxNjAgYmFzdGEgY29u
:::IDQ4MHA6IGFob3JyYSBtdWNoYSBkZXNjYXJnYS4KICAgIG9bJ2Zvcm1hdCddID0g
:::KCdiZXN0W2hlaWdodDw9NDgwXVtleHQ9bXA0XS9iZXN0W2hlaWdodDw9NDgwXS8n
:::CiAgICAgICAgICAgICAgICAgICAnYnYqW2hlaWdodDw9NDgwXStiYS9iJykKICAg
:::IG9bJ21lcmdlX291dHB1dF9mb3JtYXQnXSA9ICdtcDQnCiAgICB3aXRoIFlUX0RM
:::UC5Zb3V0dWJlREwobykgYXMgeWRsOgogICAgICAgIGluZm8gPSB5ZGwuZXh0cmFj
:::dF9pbmZvKHVybCwgZG93bmxvYWQ9VHJ1ZSkKICAgIG9yaWdlbiA9IGFyY2hpdm9f
:::ZmluYWwoaW5mbywgdG1wLCAnbXA0JykKICAgIGlmIG5vdCBvcmlnZW46CiAgICAg
:::ICAgb3JpZ2VuID0gKGFyY2hpdm9fZmluYWwoaW5mbywgdG1wLCAnbWt2JykKICAg
:::ICAgICAgICAgICAgICAgb3IgYXJjaGl2b19maW5hbChpbmZvLCB0bXAsICd3ZWJt
:::JykpCiAgICBpZiBub3Qgb3JpZ2VuOgogICAgICAgIHJhaXNlIFJ1bnRpbWVFcnJv
:::cignTm8gc2UgZW5jb250csOzIGVsIHZpZGVvIGRlc2NhcmdhZG8uJykKICAgIGF2
:::aSA9IGNhcnBldGEgLyAobGltcGlhcl9ub21icmUoaW5mby5nZXQoJ3RpdGxlJykg
:::b3IgJ3ZpZGVvJykgKyAnLmF2aScpCiAgICBiYXNlID0gW3N0cihGRk1QRUcpLCAn
:::LXknLCAnLWknLCBzdHIob3JpZ2VuKSwgJy1yJywgJzE2JywKICAgICAgICAgICAg
:::Jy1hY29kZWMnLCAncGNtX3MxNmxlJywgJy1hYycsICcyJywgJy1hcicsICcyMjA1
:::MCcsCiAgICAgICAgICAgICctcGl4X2ZtdCcsICd5dXZqNDIwcCcsICctYzp2Jywg
:::J21qcGVnJywgJy1xOnYnLCAnMiddCiAgICBvayA9IGNvbnZlcnRpcl9mZm1wZWco
:::YmFzZSArIFsnLXZmJywgVkZfU0hFSUpVLCBzdHIoYXZpKV0sCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgJ0NvbnZpcnRpZW5kbyBhIEFWSSAxMjh4MTYwIChzaGVp
:::anUgMS44IiknLCBjb2xhKQogICAgaWYgbm90IG9rOgogICAgICAgIGxvZygnVmlk
:::ZW8gY29uIHByb3BvcmNpw7NuIG5vIGVzdMOhbmRhcjsgJwogICAgICAgICAgICAn
:::cmVpbnRlbnRhbmRvIGVuIG1vZG8gY29tcGF0aWJsZS4uLicsICdhdmlzbycpCiAg
:::ICAgICAgb2sgPSBjb252ZXJ0aXJfZmZtcGVnKGJhc2UgKyBbJy12ZicsIFZGX1NF
:::R1VSTywgc3RyKGF2aSldLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAn
:::UmVjb252aXJ0aWVuZG8gYSBBVkkgMTI4eDE2MCcsIGNvbGEpCiAgICBpZiBub3Qg
:::b2s6CiAgICAgICAgcmFpc2UgUnVudGltZUVycm9yKCdGRm1wZWcgbm8gcHVkbyBj
:::cmVhciBlbCBhcmNoaXZvIEFWSS4nKQogICAgc2h1dGlsLnJtdHJlZSh0bXAsIGln
:::bm9yZV9lcnJvcnM9VHJ1ZSkKICAgIHJldHVybiBpbmZvLCBhdmkKCgojIC0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0gZXN0aW1hY2nDs24KS0JQU19FU1RJTUFET1MgPSB7CiAgICAn
:::QUFDJzogMTI4LCAgICAgIyB0ZWNobyBkZWwgZm9ybWF0bwogICAgJ1dNQSc6IDEy
:::OCwKICAgICdXQVYnOiAxNDExLCAgICAjIFBDTSA0NC4xIGtIeiDCtyAxNiBiaXQg
:::wrcgZXN0w6lyZW8KICAgICdGTEFDJzogOTUwLCAgICAjIHTDrXBpY28gZGUgbcO6
:::c2ljYSBwcm9jZWRlbnRlIGRlIFlvdVR1YmUKICAgICdBVkknOiAxNDkwLCAgICAj
:::IH43ODQga2JwcyBNSlBFRyAxNmZwcyArIDcwNiBrYnBzIFBDTSAyMjA1MCBlc3TD
:::qXJlbwp9CgoKZGVmIGVzdGltYXJfYnl0ZXMoZHVyYWNpb25fcywgZm9ybWF0bywg
:::Y2FsaWRhZCwgZW1iZWJlcik6CiAgICAiIiJFc3RpbWEgZWwgdGFtYcOxbyBmaW5h
:::bCBlbiBieXRlcyAoY8OhbGN1bG8gcHVybywgdGVzdGVhYmxlKS4iIiIKICAgIGlm
:::IGZvcm1hdG8gPT0gJ01QMyc6CiAgICAgICAga2JwcyA9IGludChyZS5zdWIocidb
:::XjAtOV0nLCAnJywgc3RyKGNhbGlkYWQpKSBvciAzMjApCiAgICBlbHNlOgogICAg
:::ICAgIGticHMgPSBLQlBTX0VTVElNQURPUy5nZXQoZm9ybWF0bywgMTI4KQogICAg
:::ZXh0cmEgPSAxMjBfMDAwIGlmIChlbWJlYmVyIGFuZCBmb3JtYXRvIGluICgnQUFD
:::JywgJ01QMycsICdGTEFDJykpIGVsc2UgMAogICAgcmV0dXJuIGR1cmFjaW9uX3Mg
:::KiBrYnBzICogMTAwMCAvIDggKyBleHRyYQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBj
:::YWxpZGFkCmRlZiBjbGFzZV9jYWxpZGFkKGV4dCwga2Jwcyk6CiAgICAiIiJDbGFz
:::aWZpY2EgdW4gYXJjaGl2by4gRGV2dWVsdmUgKHRleHRvLCBuaXZlbCkgY29uIG5p
:::dmVsIDA9b2sgMT1tZWRpYSAyPWJhamEuIiIiCiAgICBpZiBleHQgPT0gJy5tcDMn
:::OgogICAgICAgIGlmIGticHMgPj0gMzE1OgogICAgICAgICAgICByZXR1cm4gJzMy
:::MCBrYnBzJywgMAogICAgICAgIGlmIGticHMgPj0gMjUwOgogICAgICAgICAgICBy
:::ZXR1cm4gJzI1NiBrYnBzJywgMAogICAgICAgIGlmIGticHMgPj0gMTg1OgogICAg
:::ICAgICAgICByZXR1cm4gJzE5MiBrYnBzJywgMAogICAgICAgIGlmIGticHMgPj0g
:::MTIwOgogICAgICAgICAgICByZXR1cm4gJzEyOCBrYnBzJywgMQogICAgICAgIHJl
:::dHVybiBmJ3trYnBzfSBrYnBzIChiYWphKScsIDIKICAgIGlmIGV4dCA9PSAnLm00
:::YSc6CiAgICAgICAgaWYga2JwcyA+PSAxMTU6CiAgICAgICAgICAgIHJldHVybiAn
:::RXhjZWxlbnRlIChBQUMg4omkMTI4ayknLCAwCiAgICAgICAgaWYga2JwcyA+PSA4
:::MDoKICAgICAgICAgICAgcmV0dXJuICdCdWVuYScsIDEKICAgICAgICByZXR1cm4g
:::Zid7a2Jwc30ga2JwcyAoYmFqYSknLCAyCiAgICBpZiBleHQgPT0gJy53bWEnOgog
:::ICAgICAgIGlmIGticHMgPj0gMTE1OgogICAgICAgICAgICByZXR1cm4gJzEyOCBr
:::YnBzJywgMAogICAgICAgIGlmIGticHMgPj0gOTA6CiAgICAgICAgICAgIHJldHVy
:::biAnQWNlcHRhYmxlJywgMQogICAgICAgIHJldHVybiBmJ3trYnBzfSBrYnBzIChi
:::YWphKScsIDIKICAgIGlmIGV4dCBpbiAoJy5mbGFjJywgJy53YXYnKToKICAgICAg
:::ICByZXR1cm4gJ1NpbiBww6lyZGlkYScsIDAKICAgIGlmIGV4dCA9PSAnLmF2aSc6
:::CiAgICAgICAgaWYga2JwcyA+PSAxMjAwOgogICAgICAgICAgICByZXR1cm4gZid7
:::a2Jwc30ga2JwcyAoTUpQRUcrUENNIDEyOHgxNjApJywgMAogICAgICAgIHJldHVy
:::biBmJ3trYnBzfSBrYnBzIChhbGdvIGJham8pJywgMQogICAgcmV0dXJuIGYne2ti
:::cHN9IGticHMnLCAxCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIHRlbWFzClRFTUFTID0g
:::ewogICAgJ09zY3Vybyc6IGRpY3QoCiAgICAgICAgZm9uZG89JyMxZTFmMjInLCBj
:::YW1wbz0nIzJhMmQzMScsIGNhbXBvX2JvcmRlPScjM2EzZTQ0JywKICAgICAgICB0
:::ZXh0bz0nI2Q4ZGFkYycsIHRleHRvMj0nIzlhOWZhNCcsCiAgICAgICAgYm90b249
:::JyMzYTNkNDInLCBib3Rvbl9hY3Q9JyM0YTRlNTUnLCBib3Rvbl90eHQ9JyNlOGVh
:::ZWMnLAogICAgICAgIGxvZz0nIzE0MTUxOCcsIGxvZ190eHQ9JyNjZmQzZDcnLCBh
:::Y2VudG89JyM0ZjljZjknLAogICAgICAgIG9rPScjN2VjOTdmJywgZXJyb3I9JyNl
:::NTczNzMnLCBhdmlzbz0nI2Q4YjY0YScsIHRyb3VnaD0nIzI2MjgyYycsCiAgICAg
:::ICAgcGxhY2Vob2xkZXI9JyM3NzdjODInKSwKICAgICdDbGFybyc6IGRpY3QoCiAg
:::ICAgICAgZm9uZG89JyNmMmYzZjUnLCBjYW1wbz0nI2ZmZmZmZicsIGNhbXBvX2Jv
:::cmRlPScjYzRjOGNkJywKICAgICAgICB0ZXh0bz0nIzI0MjcyYScsIHRleHRvMj0n
:::IzZhNzA3NicsCiAgICAgICAgYm90b249JyNlM2U1ZTgnLCBib3Rvbl9hY3Q9JyNk
:::MmQ1ZGEnLCBib3Rvbl90eHQ9JyMyNDI3MmEnLAogICAgICAgIGxvZz0nI2ZmZmZm
:::ZicsIGxvZ190eHQ9JyMyYjJlMzEnLCBhY2VudG89JyMxYTY2ZDYnLAogICAgICAg
:::IG9rPScjMWU3ZTM0JywgZXJyb3I9JyNjNjI4MjgnLCBhdmlzbz0nIzlhNjcwMCcs
:::IHRyb3VnaD0nI2RmZTFlNCcsCiAgICAgICAgcGxhY2Vob2xkZXI9JyM5YWEwYTYn
:::KSwKfQoKTkFWRUdBRE9SRVMgPSBbJyhuaW5ndW5vKScsICdicmF2ZScsICdjaHJv
:::bWUnLCAnY2hyb21pdW0nLCAnZWRnZScsICdmaXJlZm94JywKICAgICAgICAgICAg
:::ICAgJ29wZXJhJywgJ29wZXJhX2d4JywgJ3NhZmFyaScsICd2aXZhbGRpJywgJ3do
:::YWxlJ10KClBMQUNFSE9MREVSX1VSTCA9ICdodHRwczovL3d3dy55b3V0dWJlLmNv
:::bS93YXRjaD92PS4uLicKCkZVRU5URV9VSSA9ICgnU2Vnb2UgVUknLCA5KQpGVUVO
:::VEVfQlROID0gKCdTZWdvZSBVSScsIDEwKQpGVUVOVEVfQlROX0cgPSAoJ1NlZ29l
:::IFVJJywgMTEpCkZVRU5URV9MT0cgPSAoJ0NvbnNvbGFzJywgMTApCgoKaWYgVEtf
:::T0s6CgogICAgY2xhc3MgQXBwKHRrLlRrKToKICAgICAgICAiIiJWZW50YW5hIHBy
:::aW5jaXBhbCAoZGlzZcOxbyBlc3Blam8gZGVsIG1vY2t1cDogZ3J1cG9zIG9zY3Vy
:::b3MpLiIiIgoKICAgICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLSBjb25zdHJ1Y2Npw7NuCiAgICAgICAgZGVmIF9f
:::aW5pdF9fKHNlbGYpOgogICAgICAgICAgICBpZiBnZXRhdHRyKHN5cywgJ2Zyb3pl
:::bicsIEZhbHNlKToKICAgICAgICAgICAgICAgIHBhc3MKICAgICAgICAgICAgc3Vw
:::ZXIoKS5fX2luaXRfXygpCiAgICAgICAgICAgIHNlbGYudGl0bGUoJ011c2lrQUxB
:::TicpCiAgICAgICAgICAgIHNlbGYuZ2VvbWV0cnkoJzg2MHg4NDAnKQogICAgICAg
:::ICAgICBzZWxmLm1pbnNpemUoNzAwLCA2NjApCiAgICAgICAgICAgIHNlbGYuY29s
:::YSA9IHF1ZXVlLlF1ZXVlKCkKICAgICAgICAgICAgc2VsZi5fb2N1cGFkbyA9IEZh
:::bHNlCiAgICAgICAgICAgIHNlbGYuX2VuX3BsYWNlaG9sZGVyID0gVHJ1ZQogICAg
:::ICAgICAgICBzZWxmLl90ZW1hX2FjdHVhbCA9IEFKVVNURVMuZ2V0KCd0ZW1hJywg
:::J09zY3VybycpCiAgICAgICAgICAgIGlmIHNlbGYuX3RlbWFfYWN0dWFsIG5vdCBp
:::biBURU1BUzoKICAgICAgICAgICAgICAgIHNlbGYuX3RlbWFfYWN0dWFsID0gJ09z
:::Y3VybycKCiAgICAgICAgICAgIHNlbGYuX2VzdGlsbyA9IHR0ay5TdHlsZShzZWxm
:::KQogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBzZWxmLl9lc3RpbG8u
:::dGhlbWVfdXNlKCdjbGFtJykKICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoK
:::ICAgICAgICAgICAgICAgIHBhc3MKCiAgICAgICAgICAgIHNlbGYuX2NvbnN0cnVp
:::cigpCiAgICAgICAgICAgIHNlbGYuX2FwbGljYXJfdGVtYSgpCiAgICAgICAgICAg
:::IHNlbGYuX2NvbmVjdGFyX2V2ZW50b3MoKQogICAgICAgICAgICBSRUdJU1RSTy5s
:::b2cgPSBsYW1iZGEgbSwgdD0nYXZpc28nOiBzZWxmLmNvbGEucHV0KCgnbG9nJywg
:::bSwgdCkpCiAgICAgICAgICAgIHNlbGYuYWZ0ZXIoODAsIHNlbGYuX2JvbWJlYXJf
:::Y29sYSkKICAgICAgICAgICAgc2VsZi5hZnRlcigxNTAsIHNlbGYuX2FycmFucXVl
:::KQoKICAgICAgICBkZWYgX2NvbnN0cnVpcihzZWxmKToKICAgICAgICAgICAgc2Vs
:::Zi5fd2cgPSB7fSAgICAgICAgICMgcmVmZXJlbmNpYXMgcGFyYSBlbCB0ZW1hCiAg
:::ICAgICAgICAgIHNlbGYuX2J0bnMgPSBbXSAgICAgICAjIGJvdG9uZXMgcGxhbm9z
:::IChwYXJhIGhvdmVyL3RlbWEpCiAgICAgICAgICAgIG1hcmNvID0gdGsuRnJhbWUo
:::c2VsZikKICAgICAgICAgICAgbWFyY28ucGFjayhmaWxsPSdib3RoJywgZXhwYW5k
:::PVRydWUsIHBhZHg9MTAsIHBhZHk9OCkKICAgICAgICAgICAgc2VsZi5fd2dbJ21h
:::cmNvJ10gPSBtYXJjbwogICAgICAgICAgICBtYXJjby5jb2x1bW5jb25maWd1cmUo
:::MCwgd2VpZ2h0PTEpCgogICAgICAgICAgICAjIC0tLSBmaWxhIFRlbWEgLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAg
:::ICAgICAgIGYwID0gdGsuRnJhbWUobWFyY28pCiAgICAgICAgICAgIGYwLmdyaWQo
:::cm93PTAsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgcGFkeT0oMCwgNikpCiAgICAg
:::ICAgICAgIHNlbGYuX3dnWydmMCddID0gZjAKICAgICAgICAgICAgc2VsZi5fd2db
:::J2xibF90ZW1hJ10gPSB0ay5MYWJlbChmMCwgdGV4dD0nVGVtYTonLCBmb250PUZV
:::RU5URV9VSSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF90ZW1hJ10ucGFjayhz
:::aWRlPSdsZWZ0JykKICAgICAgICAgICAgc2VsZi5jbWJfdGVtYSA9IHR0ay5Db21i
:::b2JveCgKICAgICAgICAgICAgICAgIGYwLCB2YWx1ZXM9bGlzdChURU1BUyksIHN0
:::YXRlPSdyZWFkb25seScsIHdpZHRoPTksCiAgICAgICAgICAgICAgICBmb250PUZV
:::RU5URV9VSSwgc3R5bGU9J2d4LlRDb21ib2JveCcpCiAgICAgICAgICAgIHNlbGYu
:::Y21iX3RlbWEuc2V0KHNlbGYuX3RlbWFfYWN0dWFsKQogICAgICAgICAgICBzZWxm
:::LmNtYl90ZW1hLnBhY2soc2lkZT0nbGVmdCcsIHBhZHg9KDgsIDApLCBpcGFkeT0y
:::KQoKICAgICAgICAgICAgIyAtLS0gZ3J1cG86IFVSTCBkZSBZb3VUdWJlIC0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAgICAgICBndSA9
:::IHRrLkxhYmVsRnJhbWUobWFyY28sIHRleHQ9J1VSTCBkZSBZb3VUdWJlJywgZm9u
:::dD1GVUVOVEVfVUksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWxp
:::ZWY9J3NvbGlkJywgYmQ9MSkKICAgICAgICAgICAgZ3UuZ3JpZChyb3c9MSwgY29s
:::dW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYuX3dn
:::WydndSddID0gZ3UKICAgICAgICAgICAgZ3UuY29sdW1uY29uZmlndXJlKDAsIHdl
:::aWdodD0xKQogICAgICAgICAgICBzZWxmLmVudF91cmwgPSB0ay5FbnRyeShndSwg
:::Zm9udD1GVUVOVEVfVUksIHJlbGllZj0nZmxhdCcsCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgIGhpZ2hsaWdodHRoaWNrbmVzcz0xKQogICAgICAg
:::ICAgICBzZWxmLmVudF91cmwuZ3JpZChyb3c9MCwgY29sdW1uPTAsIHN0aWNreT0n
:::ZXcnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4PTgsIHBhZHk9
:::OCwgaXBhZHk9NSkKICAgICAgICAgICAgc2VsZi5fcG9uZXJfcGxhY2Vob2xkZXIo
:::KQogICAgICAgICAgICBzZWxmLmJ0bl94ID0gc2VsZi5fYm90b24oZ3UsICdYJywg
:::c2VsZi5fbGltcGlhcl91cmwsIHdpZHRoPTMpCiAgICAgICAgICAgIHNlbGYuYnRu
:::X3guZ3JpZChyb3c9MCwgY29sdW1uPTEsIHN0aWNreT0nZScsIHBhZHg9KDAsIDgp
:::LCBpcGFkeT0zKQoKICAgICAgICAgICAgIyAtLS0gZ3J1cG86IEZvcm1hdG8geSBj
:::YWxpZGFkIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAg
:::ICAgICBnZiA9IHRrLkxhYmVsRnJhbWUobWFyY28sIHRleHQ9J0Zvcm1hdG8geSBj
:::YWxpZGFkJywgZm9udD1GVUVOVEVfVUksCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICByZWxpZWY9J3NvbGlkJywgYmQ9MSkKICAgICAgICAgICAgZ2YuZ3Jp
:::ZChyb3c9MiwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PTUpCiAgICAgICAg
:::ICAgIHNlbGYuX3dnWydnZiddID0gZ2YKICAgICAgICAgICAgZ2YuY29sdW1uY29u
:::ZmlndXJlKDEsIHdlaWdodD0xKQogICAgICAgICAgICBzZWxmLl93Z1snbGJsX2Zt
:::dCddID0gdGsuTGFiZWwoZ2YsIHRleHQ9J0Zvcm1hdG86JywgZm9udD1GVUVOVEVf
:::VUkpCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfZm10J10uZ3JpZChyb3c9MCwg
:::Y29sdW1uPTAsIHN0aWNreT0ndycsIHBhZHg9OCwgcGFkeT01KQogICAgICAgICAg
:::ICBzZWxmLmNtYl9mb3JtYXRvID0gdHRrLkNvbWJvYm94KAogICAgICAgICAgICAg
:::ICAgZ2YsIHZhbHVlcz1bZlsndGV4dG8nXSBmb3IgZiBpbiBGT1JNQVRPUy52YWx1
:::ZXMoKV0sCiAgICAgICAgICAgICAgICBzdGF0ZT0ncmVhZG9ubHknLCBmb250PUZV
:::RU5URV9VSSwgc3R5bGU9J2d4LlRDb21ib2JveCcpCiAgICAgICAgICAgIHNlbGYu
:::Y21iX2Zvcm1hdG8uZ3JpZChyb3c9MCwgY29sdW1uPTEsIHN0aWNreT0nZXcnLAog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFkeD04LCBwYWR5PTUs
:::IGlwYWR5PTIpCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfY2FsJ10gPSB0ay5M
:::YWJlbChnZiwgdGV4dD0nQ2FsaWRhZDonLCBmb250PUZVRU5URV9VSSkKICAgICAg
:::ICAgICAgc2VsZi5fd2dbJ2xibF9jYWwnXS5ncmlkKHJvdz0xLCBjb2x1bW49MCwg
:::c3RpY2t5PSd3JywgcGFkeD04LCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYuY21i
:::X2NhbGlkYWQgPSB0dGsuQ29tYm9ib3goCiAgICAgICAgICAgICAgICBnZiwgc3Rh
:::dGU9J3JlYWRvbmx5JywgZm9udD1GVUVOVEVfVUksIHN0eWxlPSdneC5UQ29tYm9i
:::b3gnKQogICAgICAgICAgICBzZWxmLmNtYl9jYWxpZGFkLmdyaWQocm93PTEsIGNv
:::bHVtbj0xLCBzdGlja3k9J2V3JywKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgIHBhZHg9OCwgcGFkeT01LCBpcGFkeT0yKQogICAgICAgICAgICBzZWxm
:::Ll93Z1snbGJsX2NhciddID0gdGsuTGFiZWwoZ2YsIHRleHQ9J0NhcnBldGE6Jywg
:::Zm9udD1GVUVOVEVfVUkpCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfY2FyJ10u
:::Z3JpZChyb3c9MiwgY29sdW1uPTAsIHN0aWNreT0ndycsIHBhZHg9OCwgcGFkeT01
:::KQogICAgICAgICAgICBmYyA9IHRrLkZyYW1lKGdmKQogICAgICAgICAgICBmYy5n
:::cmlkKHJvdz0yLCBjb2x1bW49MSwgc3RpY2t5PSdldycsIHBhZHg9OCwgcGFkeT01
:::KQogICAgICAgICAgICBzZWxmLl93Z1snZmMnXSA9IGZjCiAgICAgICAgICAgIGZj
:::LmNvbHVtbmNvbmZpZ3VyZSgwLCB3ZWlnaHQ9MSkKICAgICAgICAgICAgc2VsZi5l
:::bnRfY2FycGV0YSA9IHRrLkVudHJ5KGZjLCBmb250PUZVRU5URV9VSSwgcmVsaWVm
:::PSdmbGF0JywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::IGhpZ2hsaWdodHRoaWNrbmVzcz0xKQogICAgICAgICAgICBzZWxmLmVudF9jYXJw
:::ZXRhLmdyaWQocm93PTAsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgaXBhZHk9NCkK
:::ICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5pbnNlcnQoMCwgQUpVU1RFU1sn
:::ZGVzdGlubyddKQogICAgICAgICAgICBzZWxmLmJ0bl9jYW1iaWFyID0gc2VsZi5f
:::Ym90b24oZmMsICdDYW1iaWFyLi4uJywgc2VsZi5fY2FtYmlhcl9jYXJwZXRhKQog
:::ICAgICAgICAgICBzZWxmLmJ0bl9jYW1iaWFyLmdyaWQocm93PTAsIGNvbHVtbj0x
:::LCBwYWR4PSg4LCAwKSwgaXBhZHk9MykKICAgICAgICAgICAgc2VsZi5idG5fYWJy
:::aXIgPSBzZWxmLl9ib3RvbihmYywgJ0FicmlyJywgc2VsZi5fYWJyaXJfZGVzdGlu
:::bywgd2lkdGg9NSkKICAgICAgICAgICAgc2VsZi5idG5fYWJyaXIuZ3JpZChyb3c9
:::MCwgY29sdW1uPTIsIHBhZHg9KDYsIDApLCBpcGFkeT0zKQoKICAgICAgICAgICAg
:::c2VsZi52YXJfZW1iZWJlciA9IHRrLkJvb2xlYW5WYXIodmFsdWU9Ym9vbChBSlVT
:::VEVTLmdldCgnZW1iZWJlcicsIFRydWUpKSkKICAgICAgICAgICAgc2VsZi5jaGtf
:::ZW1iZWJlciA9IHRrLkNoZWNrYnV0dG9uKAogICAgICAgICAgICAgICAgZ2YsIHRl
:::eHQ9J0VtYmViZXIgY2Fyw6F0dWxhLCBhcnRpc3RhIHkgw6FsYnVtJywKICAgICAg
:::ICAgICAgICAgIHZhcmlhYmxlPXNlbGYudmFyX2VtYmViZXIsIGZvbnQ9RlVFTlRF
:::X1VJLCBhbmNob3I9J3cnLAogICAgICAgICAgICAgICAgcmVsaWVmPSdmbGF0Jywg
:::aGlnaGxpZ2h0dGhpY2tuZXNzPTAsIGJkPTApCiAgICAgICAgICAgIHNlbGYuY2hr
:::X2VtYmViZXIuZ3JpZChyb3c9MywgY29sdW1uPTAsIGNvbHVtbnNwYW49MiwKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0aWNreT0nZXcnLCBwYWR4
:::PTgsIHBhZHk9KDIsIDYpKQoKICAgICAgICAgICAgIyAtLS0gZ3J1cG86IGNvb2tp
:::ZXMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQog
:::ICAgICAgICAgICBnYyA9IHRrLkxhYmVsRnJhbWUoCiAgICAgICAgICAgICAgICBt
:::YXJjbywgdGV4dD0nTmF2ZWdhZG9yIHBhcmEgY29va2llcyAoc29sbyBzaSBlcyBu
:::ZWNlc2FyaW8pJywKICAgICAgICAgICAgICAgIGZvbnQ9RlVFTlRFX1VJLCByZWxp
:::ZWY9J3NvbGlkJywgYmQ9MSkKICAgICAgICAgICAgZ2MuZ3JpZChyb3c9MywgY29s
:::dW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYuX3dn
:::WydnYyddID0gZ2MKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF9uYXYnXSA9IHRr
:::LkxhYmVsKGdjLCB0ZXh0PSdOYXZlZ2Fkb3I6JywKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgZm9udD1GVUVOVEVfVUkpCiAgICAgICAg
:::ICAgIHNlbGYuX3dnWydsYmxfbmF2J10ucGFjayhzaWRlPSdsZWZ0JywgcGFkeD04
:::LCBwYWR5PTgpCiAgICAgICAgICAgIHNlbGYuY21iX25hdmVnYWRvciA9IHR0ay5D
:::b21ib2JveCgKICAgICAgICAgICAgICAgIGdjLCB2YWx1ZXM9TkFWRUdBRE9SRVMs
:::IHN0YXRlPSdyZWFkb25seScsIHdpZHRoPTEyLAogICAgICAgICAgICAgICAgZm9u
:::dD1GVUVOVEVfVUksIHN0eWxlPSdneC5UQ29tYm9ib3gnKQogICAgICAgICAgICBu
:::YXYgPSBBSlVTVEVTLmdldCgnbmF2ZWdhZG9yJywgJyhuaW5ndW5vKScpCiAgICAg
:::ICAgICAgIGlmIG5hdiBub3QgaW4gTkFWRUdBRE9SRVM6CiAgICAgICAgICAgICAg
:::ICBuYXYgPSAnKG5pbmd1bm8pJwogICAgICAgICAgICBzZWxmLmNtYl9uYXZlZ2Fk
:::b3Iuc2V0KG5hdikKICAgICAgICAgICAgc2VsZi5jbWJfbmF2ZWdhZG9yLnBhY2so
:::c2lkZT0nbGVmdCcsIHBhZHg9KDgsIDApLCBpcGFkeT0yKQoKICAgICAgICAgICAg
:::IyAtLS0gZ3J1cG86IGVzdGltYWNpw7NuIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0KICAgICAgICAgICAgZ2UgPSB0ay5MYWJlbEZyYW1l
:::KG1hcmNvLCB0ZXh0PSdFc3RpbWFjacOzbicsIGZvbnQ9RlVFTlRFX1VJLAogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVsaWVmPSdzb2xpZCcsIGJkPTEp
:::CiAgICAgICAgICAgIGdlLmdyaWQocm93PTQsIGNvbHVtbj0wLCBzdGlja3k9J2V3
:::JywgcGFkeT01KQogICAgICAgICAgICBzZWxmLl93Z1snZ2UnXSA9IGdlCiAgICAg
:::ICAgICAgIGdlLmNvbHVtbmNvbmZpZ3VyZSgwLCB3ZWlnaHQ9MSkKICAgICAgICAg
:::ICAgc2VsZi5sYmxfZXN0aW1hY2lvbiA9IHRrLkxhYmVsKAogICAgICAgICAgICAg
:::ICAgZ2UsIHRleHQ9J0ludHJvZHVjZSB1bmEgVVJMIHkgcHVsc2EgRXN0aW1hci4n
:::LAogICAgICAgICAgICAgICAgZm9udD1GVUVOVEVfVUksIGFuY2hvcj0ndycpCiAg
:::ICAgICAgICAgIHNlbGYubGJsX2VzdGltYWNpb24uZ3JpZChyb3c9MCwgY29sdW1u
:::PTAsIHN0aWNreT0nZXcnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgcGFkeD04LCBwYWR5PTYpCiAgICAgICAgICAgIHNlbGYuYnRuX2VzdGlt
:::YXIgPSBzZWxmLl9ib3RvbihnZSwgJ0VzdGltYXIgdGFtYW5vJywKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuX2FjY2lvbl9l
:::c3RpbWFyKQogICAgICAgICAgICBzZWxmLmJ0bl9lc3RpbWFyLmdyaWQocm93PTAs
:::IGNvbHVtbj0xLCBzdGlja3k9J2UnLAogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgcGFkeD04LCBpcGFkeT0zKQoKICAgICAgICAgICAgIyAtLS0gYm90
:::b25lcyBncmFuZGVzIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLQogICAgICAgICAgICBzZWxmLmJ0bl9kZXNjYXJnYXIgPSBzZWxmLl9i
:::b3RvbihtYXJjbywgJ0Rlc2NhcmdhciB5IGNvbnZlcnRpcicsCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuX2FjY2lvbl9k
:::ZXNjYXJnYXIsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgIGZ1ZW50ZT1GVUVOVEVfQlROX0csIGFsdG89MikKICAgICAgICAgICAg
:::c2VsZi5idG5fZGVzY2FyZ2FyLmdyaWQocm93PTUsIGNvbHVtbj0wLCBzdGlja3k9
:::J2V3JywgcGFkeT0oNywgNCkpCiAgICAgICAgICAgIHNlbGYuYnRuX2NvbXByb2Jh
:::ciA9IHNlbGYuX2JvdG9uKAogICAgICAgICAgICAgICAgbWFyY28sICdDb21wcm9i
:::YXIgY2FsaWRhZCBkZSBsYSBjYXJwZXRhJywKICAgICAgICAgICAgICAgIHNlbGYu
:::X2FjY2lvbl9jb21wcm9iYXIsIGZ1ZW50ZT1GVUVOVEVfQlROKQogICAgICAgICAg
:::ICBzZWxmLmJ0bl9jb21wcm9iYXIuZ3JpZChyb3c9NiwgY29sdW1uPTAsIHN0aWNr
:::eT0nZXcnLCBwYWR5PTMpCgogICAgICAgICAgICAjIC0tLSBlc3RhZG8gKyBiYXJy
:::YSBkZSBwcm9ncmVzbyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQog
:::ICAgICAgICAgICBzZWxmLmxibF9lc3RhZG8gPSB0ay5MYWJlbChtYXJjbywgdGV4
:::dD0nJywgZm9udD1GVUVOVEVfVUksCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIGFuY2hvcj0ndycpCiAgICAgICAgICAgIHNlbGYubGJsX2Vz
:::dGFkby5ncmlkKHJvdz03LCBjb2x1bW49MCwgc3RpY2t5PSdldycsIHBhZHk9KDQs
:::IDApKQogICAgICAgICAgICBzZWxmLmJhcnJhID0gdHRrLlByb2dyZXNzYmFyKAog
:::ICAgICAgICAgICAgICAgbWFyY28sIG1heGltdW09MTAwLCBzdHlsZT0nZ3guSG9y
:::aXpvbnRhbC5UUHJvZ3Jlc3NiYXInKQogICAgICAgICAgICBzZWxmLmJhcnJhLmdy
:::aWQocm93PTgsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgcGFkeT0oMiwgNCkpCgog
:::ICAgICAgICAgICAjIC0tLSByZWdpc3RybyAobG9nKSAtLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAgICAgICBzZWxmLnR4
:::dF9sb2cgPSBTY3JvbGxlZFRleHQobWFyY28sIGZvbnQ9RlVFTlRFX0xPRywgaGVp
:::Z2h0PTEyLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::cmVsaWVmPSdmbGF0JywgYmQ9MCwgd3JhcD0nd29yZCcsCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBzdGF0ZT0nZGlzYWJsZWQnKQogICAg
:::ICAgICAgICBzZWxmLnR4dF9sb2cuZ3JpZChyb3c9OSwgY29sdW1uPTAsIHN0aWNr
:::eT0nbnNldycpCiAgICAgICAgICAgIG1hcmNvLnJvd2NvbmZpZ3VyZSg5LCB3ZWln
:::aHQ9MSkKICAgICAgICAgICAgZm9yIHRhZywgY29uZiBpbiAoCiAgICAgICAgICAg
:::ICAgICAgICAgKCdpbmZvJywge30pLAogICAgICAgICAgICAgICAgICAgICgnZ3Jp
:::cycsIHt9KSwKICAgICAgICAgICAgICAgICAgICAoJ3RpdHVsbycsIHt9KSwKICAg
:::ICAgICAgICAgICAgICAgICAoJ29rJywge30pLAogICAgICAgICAgICAgICAgICAg
:::ICgnYXZpc28nLCB7fSksCiAgICAgICAgICAgICAgICAgICAgKCdlcnJvcicsIHt9
:::KSk6CiAgICAgICAgICAgICAgICBzZWxmLnR4dF9sb2cudGFnX2NvbmZpZ3VyZSh0
:::YWcsIGNvbmYpCgogICAgICAgICAgICAjIHNpbmNyb25pemFyIHZhbG9yZXMgZ3Vh
:::cmRhZG9zCiAgICAgICAgICAgIGZtdCA9IEFKVVNURVMuZ2V0KCdmb3JtYXRvJywg
:::J0FBQycpCiAgICAgICAgICAgIGlmIGZtdCBub3QgaW4gRk9STUFUT1M6CiAgICAg
:::ICAgICAgICAgICBmbXQgPSAnQUFDJwogICAgICAgICAgICBzZWxmLmNtYl9mb3Jt
:::YXRvLnNldChGT1JNQVRPU1tmbXRdWyd0ZXh0byddKQogICAgICAgICAgICBzZWxm
:::Ll9yZWNhcmdhcl9jYWxpZGFkZXMoZm10LCBBSlVTVEVTLmdldCgnY2FsaWRhZCcp
:::KQoKICAgICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLSBoZWxwZXJzIHdpZGdldHMKICAgICAgICBkZWYgX2JvdG9u
:::KHNlbGYsIHBhZHJlLCB0ZXh0bywgY21kLCB3aWR0aD1Ob25lLCBmdWVudGU9RlVF
:::TlRFX0JUTiwKICAgICAgICAgICAgICAgICAgIGFsdG89MSk6CiAgICAgICAgICAg
:::IGIgPSB0ay5CdXR0b24ocGFkcmUsIHRleHQ9dGV4dG8sIGNvbW1hbmQ9Y21kLCBm
:::b250PWZ1ZW50ZSwKICAgICAgICAgICAgICAgICAgICAgICAgICByZWxpZWY9J2Zs
:::YXQnLCBiZD0wLCBjdXJzb3I9J2hhbmQyJywgaGVpZ2h0PWFsdG8sCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgYWN0aXZlZm9yZWdyb3VuZD0nI2ZmZmZmZicsIHRh
:::a2Vmb2N1cz0wKQogICAgICAgICAgICBpZiB3aWR0aDoKICAgICAgICAgICAgICAg
:::IGIuY29uZmlndXJlKHdpZHRoPXdpZHRoKQogICAgICAgICAgICBiLmJpbmQoJzxF
:::bnRlcj4nLCBsYW1iZGEgZSwgdz1iOiB3LmNvbmZpZ3VyZSgKICAgICAgICAgICAg
:::ICAgIGJnPVRFTUFTW3NlbGYuX3RlbWFfYWN0dWFsXVsnYm90b25fYWN0J10pKQog
:::ICAgICAgICAgICBiLmJpbmQoJzxMZWF2ZT4nLCBsYW1iZGEgZSwgdz1iOiB3LmNv
:::bmZpZ3VyZSgKICAgICAgICAgICAgICAgIGJnPVRFTUFTW3NlbGYuX3RlbWFfYWN0
:::dWFsXVsnYm90b24nXSkpCiAgICAgICAgICAgIHNlbGYuX2J0bnMuYXBwZW5kKGIp
:::CiAgICAgICAgICAgIHJldHVybiBiCgogICAgICAgIGRlZiBfcG9uZXJfcGxhY2Vo
:::b2xkZXIoc2VsZik6CiAgICAgICAgICAgIGlmIG5vdCBzZWxmLmVudF91cmwuZ2V0
:::KCk6CiAgICAgICAgICAgICAgICBzZWxmLl9lbl9wbGFjZWhvbGRlciA9IFRydWUK
:::ICAgICAgICAgICAgICAgIHNlbGYuZW50X3VybC5pbnNlcnQoMCwgUExBQ0VIT0xE
:::RVJfVVJMKQoKICAgICAgICBkZWYgX2xpbXBpYXJfdXJsKHNlbGYpOgogICAgICAg
:::ICAgICBzZWxmLmVudF91cmwuZGVsZXRlKDAsICdlbmQnKQogICAgICAgICAgICBz
:::ZWxmLmVudF91cmwuZm9jdXNfc2V0KCkKCiAgICAgICAgIyAtLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gdGVtYQogICAgICAg
:::IGRlZiBfYXBsaWNhcl90ZW1hKHNlbGYpOgogICAgICAgICAgICB0ID0gVEVNQVNb
:::c2VsZi5fdGVtYV9hY3R1YWxdCiAgICAgICAgICAgIHcgPSBzZWxmLl93ZwogICAg
:::ICAgICAgICBzZWxmLmNvbmZpZ3VyZShiZz10Wydmb25kbyddKQogICAgICAgICAg
:::ICBmb3Igbm9tYnJlIGluICgnbWFyY28nLCAnZjAnLCAnZ3UnLCAnZ2YnLCAnZmMn
:::LCAnZ2MnLCAnZ2UnKToKICAgICAgICAgICAgICAgIHdbbm9tYnJlXS5jb25maWd1
:::cmUoYmc9dFsnZm9uZG8nXSkKICAgICAgICAgICAgZm9yIGxmIGluICh3WydndSdd
:::LCB3WydnZiddLCB3WydnYyddLCB3WydnZSddKToKICAgICAgICAgICAgICAgIGxm
:::LmNvbmZpZ3VyZShiZz10Wydmb25kbyddLCBmZz10Wyd0ZXh0bzInXSkKICAgICAg
:::ICAgICAgZm9yIG5vbWJyZSBpbiAoJ2xibF90ZW1hJywgJ2xibF9mbXQnLCAnbGJs
:::X2NhbCcsICdsYmxfY2FyJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2xi
:::bF9uYXYnKToKICAgICAgICAgICAgICAgIHdbbm9tYnJlXS5jb25maWd1cmUoYmc9
:::dFsnZm9uZG8nXSwgZmc9dFsndGV4dG8nXSkKICAgICAgICAgICAgc2VsZi5sYmxf
:::ZXN0aW1hY2lvbi5jb25maWd1cmUoYmc9dFsnZm9uZG8nXSwgZmc9dFsndGV4dG8n
:::XSkKICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmNvbmZpZ3VyZShiZz10Wydm
:::b25kbyddLCBmZz10Wyd0ZXh0bzInXSkKICAgICAgICAgICAgc2VsZi5lbnRfdXJs
:::LmNvbmZpZ3VyZSgKICAgICAgICAgICAgICAgIGJnPXRbJ2NhbXBvJ10sIGZnPXRb
:::J3RleHRvJ10sIGluc2VydGJhY2tncm91bmQ9dFsndGV4dG8nXSwKICAgICAgICAg
:::ICAgICAgIGhpZ2hsaWdodGJhY2tncm91bmQ9dFsnY2FtcG9fYm9yZGUnXSwKICAg
:::ICAgICAgICAgICAgIGhpZ2hsaWdodGNvbG9yPXRbJ2FjZW50byddLAogICAgICAg
:::ICAgICAgICAgZGlzYWJsZWRiYWNrZ3JvdW5kPXRbJ2NhbXBvJ10sIGRpc2FibGVk
:::Zm9yZWdyb3VuZD10Wyd0ZXh0bzInXSkKICAgICAgICAgICAgc2VsZi5lbnRfY2Fy
:::cGV0YS5jb25maWd1cmUoCiAgICAgICAgICAgICAgICBiZz10WydjYW1wbyddLCBm
:::Zz10Wyd0ZXh0byddLCBpbnNlcnRiYWNrZ3JvdW5kPXRbJ3RleHRvJ10sCiAgICAg
:::ICAgICAgICAgICBoaWdobGlnaHRiYWNrZ3JvdW5kPXRbJ2NhbXBvX2JvcmRlJ10s
:::CiAgICAgICAgICAgICAgICBoaWdobGlnaHRjb2xvcj10WydhY2VudG8nXSkKICAg
:::ICAgICAgICAgc2VsZi5jaGtfZW1iZWJlci5jb25maWd1cmUoCiAgICAgICAgICAg
:::ICAgICBiZz10Wydmb25kbyddLCBmZz10Wyd0ZXh0byddLCBhY3RpdmViYWNrZ3Jv
:::dW5kPXRbJ2ZvbmRvJ10sCiAgICAgICAgICAgICAgICBhY3RpdmVmb3JlZ3JvdW5k
:::PXRbJ3RleHRvJ10sIHNlbGVjdGNvbG9yPXRbJ2NhbXBvJ10pCiAgICAgICAgICAg
:::IGZvciBiIGluIHNlbGYuX2J0bnM6CiAgICAgICAgICAgICAgICBiLmNvbmZpZ3Vy
:::ZShiZz10Wydib3RvbiddLCBmZz10Wydib3Rvbl90eHQnXSwKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgIGFjdGl2ZWJhY2tncm91bmQ9dFsnYm90b25fYWN0J10s
:::CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBhY3RpdmVmb3JlZ3JvdW5kPXRb
:::J2JvdG9uX3R4dCddKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuY29uZmlndXJl
:::KGJnPXRbJ2xvZyddLCBmZz10Wydsb2dfdHh0J10sCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgaW5zZXJ0YmFja2dyb3VuZD10Wydsb2dfdHh0J10p
:::CiAgICAgICAgICAgIHNlbGYudHh0X2xvZy50YWdfY29uZmlndXJlKCdpbmZvJywg
:::Zm9yZWdyb3VuZD10Wydsb2dfdHh0J10pCiAgICAgICAgICAgIHNlbGYudHh0X2xv
:::Zy50YWdfY29uZmlndXJlKCdncmlzJywgZm9yZWdyb3VuZD10Wyd0ZXh0bzInXSkK
:::ICAgICAgICAgICAgc2VsZi50eHRfbG9nLnRhZ19jb25maWd1cmUoJ3RpdHVsbycs
:::IGZvcmVncm91bmQ9dFsndGV4dG8nXSwKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgZm9udD0oJ0NvbnNvbGFzJywgMTAsICdib2xkJykpCiAg
:::ICAgICAgICAgIHNlbGYudHh0X2xvZy50YWdfY29uZmlndXJlKCdvaycsIGZvcmVn
:::cm91bmQ9dFsnb2snXSkKICAgICAgICAgICAgc2VsZi50eHRfbG9nLnRhZ19jb25m
:::aWd1cmUoJ2F2aXNvJywgZm9yZWdyb3VuZD10WydhdmlzbyddKQogICAgICAgICAg
:::ICBzZWxmLnR4dF9sb2cudGFnX2NvbmZpZ3VyZSgnZXJyb3InLCBmb3JlZ3JvdW5k
:::PXRbJ2Vycm9yJ10pCiAgICAgICAgICAgIGVzdCA9IHNlbGYuX2VzdGlsbwogICAg
:::ICAgICAgICBlc3QuY29uZmlndXJlKCdneC5UQ29tYm9ib3gnLAogICAgICAgICAg
:::ICAgICAgICAgICAgICAgIGZpZWxkYmFja2dyb3VuZD10WydjYW1wbyddLCBiYWNr
:::Z3JvdW5kPXRbJ2JvdG9uJ10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgZm9y
:::ZWdyb3VuZD10Wyd0ZXh0byddLCBhcnJvd2NvbG9yPXRbJ3RleHRvJ10sCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgYm9yZGVyY29sb3I9dFsnY2FtcG9fYm9yZGUn
:::XSwKICAgICAgICAgICAgICAgICAgICAgICAgICBsaWdodGNvbG9yPXRbJ2NhbXBv
:::X2JvcmRlJ10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgZGFya2NvbG9yPXRb
:::J2NhbXBvX2JvcmRlJ10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgaW5zZXJ0
:::Y29sb3I9dFsndGV4dG8nXSkKICAgICAgICAgICAgZXN0Lm1hcCgnZ3guVENvbWJv
:::Ym94JywKICAgICAgICAgICAgICAgICAgICBmaWVsZGJhY2tncm91bmQ9WygncmVh
:::ZG9ubHknLCB0WydjYW1wbyddKV0sCiAgICAgICAgICAgICAgICAgICAgZm9yZWdy
:::b3VuZD1bKCdyZWFkb25seScsIHRbJ3RleHRvJ10pXSkKICAgICAgICAgICAgZXN0
:::LmNvbmZpZ3VyZSgnZ3guSG9yaXpvbnRhbC5UUHJvZ3Jlc3NiYXInLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgIHRyb3VnaGNvbG9yPXRbJ3Ryb3VnaCddLCBiYWNr
:::Z3JvdW5kPXRbJ2FjZW50byddLAogICAgICAgICAgICAgICAgICAgICAgICAgIGJv
:::cmRlcmNvbG9yPXRbJ2ZvbmRvJ10sIGxpZ2h0Y29sb3I9dFsnYWNlbnRvJ10sCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgZGFya2NvbG9yPXRbJ2FjZW50byddKQog
:::ICAgICAgICAgICBzZWxmLm9wdGlvbl9hZGQoJypUQ29tYm9ib3gqTGlzdGJveC5i
:::YWNrZ3JvdW5kJywgdFsnY2FtcG8nXSkKICAgICAgICAgICAgc2VsZi5vcHRpb25f
:::YWRkKCcqVENvbWJvYm94Kkxpc3Rib3guZm9yZWdyb3VuZCcsIHRbJ3RleHRvJ10p
:::CiAgICAgICAgICAgIHNlbGYub3B0aW9uX2FkZCgnKlRDb21ib2JveCpMaXN0Ym94
:::LnNlbGVjdEJhY2tncm91bmQnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::dFsnYm90b25fYWN0J10pCiAgICAgICAgICAgIHNlbGYub3B0aW9uX2FkZCgnKlRD
:::b21ib2JveCpMaXN0Ym94LnNlbGVjdEZvcmVncm91bmQnLAogICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgdFsnYm90b25fdHh0J10pCiAgICAgICAgICAgIHNlbGYu
:::X3JlZnJlc2Nhcl9wbGFjZWhvbGRlcigpCgogICAgICAgIGRlZiBfcmVmcmVzY2Fy
:::X3BsYWNlaG9sZGVyKHNlbGYpOgogICAgICAgICAgICB0ID0gVEVNQVNbc2VsZi5f
:::dGVtYV9hY3R1YWxdCiAgICAgICAgICAgIGlmIHNlbGYuX2VuX3BsYWNlaG9sZGVy
:::OgogICAgICAgICAgICAgICAgc2VsZi5lbnRfdXJsLmNvbmZpZ3VyZShmZz10Wydw
:::bGFjZWhvbGRlciddKQogICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAg
:::c2VsZi5lbnRfdXJsLmNvbmZpZ3VyZShmZz10Wyd0ZXh0byddKQoKICAgICAgICAj
:::IC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LSBldmVudG9zCiAgICAgICAgZGVmIF9jb25lY3Rhcl9ldmVudG9zKHNlbGYpOgog
:::ICAgICAgICAgICBzZWxmLmNtYl90ZW1hLmJpbmQoJzw8Q29tYm9ib3hTZWxlY3Rl
:::ZD4+Jywgc2VsZi5fb25fdGVtYSkKICAgICAgICAgICAgc2VsZi5jbWJfZm9ybWF0
:::by5iaW5kKCc8PENvbWJvYm94U2VsZWN0ZWQ+PicsIHNlbGYuX29uX2Zvcm1hdG8p
:::CiAgICAgICAgICAgIHNlbGYuY21iX2NhbGlkYWQuYmluZCgnPDxDb21ib2JveFNl
:::bGVjdGVkPj4nLCBsYW1iZGEgZTogc2VsZi5fZ3VhcmRhcigpKQogICAgICAgICAg
:::ICBzZWxmLmNtYl9uYXZlZ2Fkb3IuYmluZCgnPDxDb21ib2JveFNlbGVjdGVkPj4n
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBsYW1iZGEgZTog
:::c2VsZi5fZ3VhcmRhcigpKQogICAgICAgICAgICBzZWxmLmNoa19lbWJlYmVyLmNv
:::bmZpZ3VyZShjb21tYW5kPXNlbGYuX2d1YXJkYXIpCiAgICAgICAgICAgIHNlbGYu
:::ZW50X3VybC5iaW5kKCc8Rm9jdXNJbj4nLCBzZWxmLl9vbl9mb2N1c191cmxfaW4p
:::CiAgICAgICAgICAgIHNlbGYuZW50X3VybC5iaW5kKCc8Rm9jdXNPdXQ+Jywgc2Vs
:::Zi5fb25fZm9jdXNfdXJsX291dCkKICAgICAgICAgICAgc2VsZi5lbnRfdXJsLmJp
:::bmQoJzxSZXR1cm4+JywgbGFtYmRhIGU6IHNlbGYuX2FjY2lvbl9kZXNjYXJnYXIo
:::KSkKICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5iaW5kKCc8Rm9jdXNPdXQ+
:::Jywgc2VsZi5fb25fY2FycGV0YV9lc2NyaXRhKQogICAgICAgICAgICBzZWxmLnBy
:::b3RvY29sKCdXTV9ERUxFVEVfV0lORE9XJywgc2VsZi5fYWxfY2VycmFyKQogICAg
:::ICAgICAgICBzZWxmLmJpbmQoJzxDb250cm9sLXU+JywgbGFtYmRhIGU6IHNlbGYu
:::X2FjY2lvbl9hY3R1YWxpemFyKCkpCiAgICAgICAgICAgIHNlbGYuYmluZCgnPENv
:::bnRyb2wtbD4nLCBsYW1iZGEgZTogc2VsZi5fbGltcGlhcl9sb2coKSkKICAgICAg
:::ICAgICAgc2VsZi5iaW5kKCc8Q29udHJvbC1VPicsIGxhbWJkYSBlOiBzZWxmLl9h
:::Y2Npb25fYWN0dWFsaXphcigpKQoKICAgICAgICBkZWYgX29uX2ZvY3VzX3VybF9p
:::bihzZWxmLCBfZT1Ob25lKToKICAgICAgICAgICAgaWYgc2VsZi5fZW5fcGxhY2Vo
:::b2xkZXI6CiAgICAgICAgICAgICAgICBzZWxmLmVudF91cmwuZGVsZXRlKDAsICdl
:::bmQnKQogICAgICAgICAgICAgICAgc2VsZi5fZW5fcGxhY2Vob2xkZXIgPSBGYWxz
:::ZQogICAgICAgICAgICAgICAgc2VsZi5fcmVmcmVzY2FyX3BsYWNlaG9sZGVyKCkK
:::CiAgICAgICAgZGVmIF9vbl9mb2N1c191cmxfb3V0KHNlbGYsIF9lPU5vbmUpOgog
:::ICAgICAgICAgICBpZiBub3Qgc2VsZi5lbnRfdXJsLmdldCgpOgogICAgICAgICAg
:::ICAgICAgc2VsZi5fZW5fcGxhY2Vob2xkZXIgPSBUcnVlCiAgICAgICAgICAgICAg
:::ICBzZWxmLl9wb25lcl9wbGFjZWhvbGRlcigpCiAgICAgICAgICAgICAgICBzZWxm
:::Ll9yZWZyZXNjYXJfcGxhY2Vob2xkZXIoKQoKICAgICAgICBkZWYgX29uX3RlbWEo
:::c2VsZiwgX2U9Tm9uZSk6CiAgICAgICAgICAgIHNlbGYuX3RlbWFfYWN0dWFsID0g
:::c2VsZi5jbWJfdGVtYS5nZXQoKQogICAgICAgICAgICBBSlVTVEVTWyd0ZW1hJ10g
:::PSBzZWxmLl90ZW1hX2FjdHVhbAogICAgICAgICAgICBndWFyZGFyX2FqdXN0ZXMo
:::KQogICAgICAgICAgICBzZWxmLl9hcGxpY2FyX3RlbWEoKQoKICAgICAgICBkZWYg
:::X29uX2Zvcm1hdG8oc2VsZiwgX2U9Tm9uZSk6CiAgICAgICAgICAgIGZtdCA9IHNl
:::bGYuX2ZtdF9hY3R1YWwoKQogICAgICAgICAgICBzZWxmLl9yZWNhcmdhcl9jYWxp
:::ZGFkZXMoZm10KQogICAgICAgICAgICBzZWxmLl9ndWFyZGFyKCkKICAgICAgICAg
:::ICAgc2VsZi5sYmxfZXN0aW1hY2lvbi5jb25maWd1cmUoCiAgICAgICAgICAgICAg
:::ICB0ZXh0PSdJbnRyb2R1Y2UgdW5hIFVSTCB5IHB1bHNhIEVzdGltYXIuJywKICAg
:::ICAgICAgICAgICAgIGZnPVRFTUFTW3NlbGYuX3RlbWFfYWN0dWFsXVsndGV4dG8n
:::XSkKCiAgICAgICAgZGVmIF9mbXRfYWN0dWFsKHNlbGYpOgogICAgICAgICAgICB0
:::ZXh0byA9IHNlbGYuY21iX2Zvcm1hdG8uZ2V0KCkKICAgICAgICAgICAgZm9yIGNs
:::YXZlLCBmIGluIEZPUk1BVE9TLml0ZW1zKCk6CiAgICAgICAgICAgICAgICBpZiBm
:::Wyd0ZXh0byddID09IHRleHRvOgogICAgICAgICAgICAgICAgICAgIHJldHVybiBj
:::bGF2ZQogICAgICAgICAgICByZXR1cm4gJ0FBQycKCiAgICAgICAgZGVmIF9yZWNh
:::cmdhcl9jYWxpZGFkZXMoc2VsZiwgY2xhdmVfZm10LCBjYWxpZGFkX3ByZXZpYT1O
:::b25lKToKICAgICAgICAgICAgZiA9IEZPUk1BVE9TW2NsYXZlX2ZtdF0KICAgICAg
:::ICAgICAgc2VsZi5jbWJfY2FsaWRhZFsndmFsdWVzJ10gPSBmWydjYWxpZGFkZXMn
:::XQogICAgICAgICAgICBpZiBjYWxpZGFkX3ByZXZpYSBhbmQgY2FsaWRhZF9wcmV2
:::aWEgaW4gZlsnY2FsaWRhZGVzJ106CiAgICAgICAgICAgICAgICBzZWxmLmNtYl9j
:::YWxpZGFkLnNldChjYWxpZGFkX3ByZXZpYSkKICAgICAgICAgICAgZWxzZToKICAg
:::ICAgICAgICAgICAgIHNlbGYuY21iX2NhbGlkYWQuc2V0KGZbJ2RlZmVjdG8nXSkK
:::ICAgICAgICAgICAgQUpVU1RFU1snZm9ybWF0byddID0gY2xhdmVfZm10CiAgICAg
:::ICAgICAgIEFKVVNURVNbJ2NhbGlkYWQnXSA9IHNlbGYuY21iX2NhbGlkYWQuZ2V0
:::KCkKCiAgICAgICAgZGVmIF9ndWFyZGFyKHNlbGYpOgogICAgICAgICAgICBBSlVT
:::VEVTWydmb3JtYXRvJ10gPSBzZWxmLl9mbXRfYWN0dWFsKCkKICAgICAgICAgICAg
:::QUpVU1RFU1snY2FsaWRhZCddID0gc2VsZi5jbWJfY2FsaWRhZC5nZXQoKQogICAg
:::ICAgICAgICBBSlVTVEVTWydlbWJlYmVyJ10gPSBib29sKHNlbGYudmFyX2VtYmVi
:::ZXIuZ2V0KCkpCiAgICAgICAgICAgIEFKVVNURVNbJ25hdmVnYWRvciddID0gc2Vs
:::Zi5jbWJfbmF2ZWdhZG9yLmdldCgpCiAgICAgICAgICAgIEFKVVNURVNbJ2Rlc3Rp
:::bm8nXSA9IHNlbGYuZW50X2NhcnBldGEuZ2V0KCkuc3RyaXAoKQogICAgICAgICAg
:::ICBndWFyZGFyX2FqdXN0ZXMoKQoKICAgICAgICBkZWYgX29uX2NhcnBldGFfZXNj
:::cml0YShzZWxmLCBfZT1Ob25lKToKICAgICAgICAgICAgcCA9IFBhdGgob3MucGF0
:::aC5leHBhbmR2YXJzKAogICAgICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5n
:::ZXQoKS5zdHJpcCgpLnN0cmlwKCciJykpKQogICAgICAgICAgICB0cnk6CiAgICAg
:::ICAgICAgICAgICBwLm1rZGlyKHBhcmVudHM9VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkK
:::ICAgICAgICAgICAgICAgIEFKVVNURVNbJ2Rlc3Rpbm8nXSA9IHN0cihwKQogICAg
:::ICAgICAgICAgICAgZ3VhcmRhcl9hanVzdGVzKCkKICAgICAgICAgICAgZXhjZXB0
:::IE9TRXJyb3IgYXMgZToKICAgICAgICAgICAgICAgIHNlbGYuX2xvZyhmJ05vIHNl
:::IHB1ZG8gdXNhciBlc2EgY2FycGV0YToge2V9JywgJ2Vycm9yJykKCiAgICAgICAg
:::ZGVmIF9jYW1iaWFyX2NhcnBldGEoc2VsZik6CiAgICAgICAgICAgIGFjdHVhbCA9
:::IHNlbGYuZW50X2NhcnBldGEuZ2V0KCkuc3RyaXAoKSBvciBBSlVTVEVTWydkZXN0
:::aW5vJ10KICAgICAgICAgICAgbnVldmEgPSBmaWxlZGlhbG9nLmFza2RpcmVjdG9y
:::eSgKICAgICAgICAgICAgICAgIHRpdGxlPSdFbGlnZSBsYSBjYXJwZXRhIGRvbmRl
:::IGd1YXJkYXIgbGFzIGRlc2NhcmdhcycsCiAgICAgICAgICAgICAgICBpbml0aWFs
:::ZGlyPWFjdHVhbCBpZiBvcy5wYXRoLmlzZGlyKGFjdHVhbCkgZWxzZSBzdHIoUGF0
:::aC5ob21lKCkpKQogICAgICAgICAgICBpZiBub3QgbnVldmE6CiAgICAgICAgICAg
:::ICAgICByZXR1cm4KICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgUGF0
:::aChudWV2YSkubWtkaXIocGFyZW50cz1UcnVlLCBleGlzdF9vaz1UcnVlKQogICAg
:::ICAgICAgICBleGNlcHQgT1NFcnJvciBhcyBlOgogICAgICAgICAgICAgICAgbWVz
:::c2FnZWJveC5zaG93ZXJyb3IoJ0NhcnBldGEgbm8gdsOhbGlkYScsIHN0cihlKSkK
:::ICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICBzZWxmLmVudF9jYXJw
:::ZXRhLmRlbGV0ZSgwLCAnZW5kJykKICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0
:::YS5pbnNlcnQoMCwgbnVldmEpCiAgICAgICAgICAgIEFKVVNURVNbJ2Rlc3Rpbm8n
:::XSA9IG51ZXZhCiAgICAgICAgICAgIGd1YXJkYXJfYWp1c3RlcygpCiAgICAgICAg
:::ICAgIHNlbGYuX2xvZygnQ2FycGV0YSBkZSBndWFyZGFkbzogJyArIG51ZXZhLCAn
:::Z3JpcycpCgogICAgICAgIGRlZiBfYWJyaXJfZGVzdGlubyhzZWxmKToKICAgICAg
:::ICAgICAgcCA9IFBhdGgob3MucGF0aC5leHBhbmR2YXJzKAogICAgICAgICAgICAg
:::ICAgc2VsZi5lbnRfY2FycGV0YS5nZXQoKS5zdHJpcCgpLnN0cmlwKCciJykpKQog
:::ICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBwLm1rZGlyKHBhcmVudHM9
:::VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgICAgICAgICAgZXhjZXB0IE9TRXJyb3I6
:::CiAgICAgICAgICAgICAgICBwYXNzCiAgICAgICAgICAgIGFicmlyX2NhcnBldGEo
:::cCkKCiAgICAgICAgZGVmIF9hbF9jZXJyYXIoc2VsZik6CiAgICAgICAgICAgIGlm
:::IHNlbGYuX29jdXBhZG8gYW5kIG5vdCBtZXNzYWdlYm94LmFza29rY2FuY2VsKAog
:::ICAgICAgICAgICAgICAgICAgICdTYWxpcicsICdIYXkgdW5hIHRhcmVhIGVuIGN1
:::cnNvLiAnCiAgICAgICAgICAgICAgICAgICAgJ8K/U2VndXJvIHF1ZSBxdWllcmVz
:::IHNhbGlyPycpOgogICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgIHNl
:::bGYuZGVzdHJveSgpCgogICAgICAgICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIHJlZ2lzdHJvIChsb2cpCiAgICAgICAg
:::ZGVmIF9sb2coc2VsZiwgbXNnLCB0YWc9J2luZm8nKToKICAgICAgICAgICAgc2Vs
:::Zi50eHRfbG9nLmNvbmZpZ3VyZShzdGF0ZT0nbm9ybWFsJykKICAgICAgICAgICAg
:::bl9saW5lYXMgPSBpbnQoc2VsZi50eHRfbG9nLmluZGV4KCdlbmQtMWMnKS5zcGxp
:::dCgnLicpWzBdKQogICAgICAgICAgICBpZiBuX2xpbmVhcyA+IDkwMDoKICAgICAg
:::ICAgICAgICAgIHNlbGYudHh0X2xvZy5kZWxldGUoJzEuMCcsICcyMDAuMCcpCiAg
:::ICAgICAgICAgIHNlbGYudHh0X2xvZy5pbnNlcnQoJ2VuZCcsIHN0cihtc2cpICsg
:::J1xuJywgdGFnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuc2VlKCdlbmQnKQog
:::ICAgICAgICAgICBzZWxmLnR4dF9sb2cuY29uZmlndXJlKHN0YXRlPSdkaXNhYmxl
:::ZCcpCgogICAgICAgIGRlZiBfbGltcGlhcl9sb2coc2VsZik6CiAgICAgICAgICAg
:::IHNlbGYudHh0X2xvZy5jb25maWd1cmUoc3RhdGU9J25vcm1hbCcpCiAgICAgICAg
:::ICAgIHNlbGYudHh0X2xvZy5kZWxldGUoJzEuMCcsICdlbmQnKQogICAgICAgICAg
:::ICBzZWxmLnR4dF9sb2cuY29uZmlndXJlKHN0YXRlPSdkaXNhYmxlZCcpCgogICAg
:::ICAgIGRlZiBfYm9tYmVhcl9jb2xhKHNlbGYpOgogICAgICAgICAgICB0cnk6CiAg
:::ICAgICAgICAgICAgICB3aGlsZSBUcnVlOgogICAgICAgICAgICAgICAgICAgIGV2
:::ID0gc2VsZi5jb2xhLmdldF9ub3dhaXQoKQogICAgICAgICAgICAgICAgICAgIHRp
:::cG8gPSBldlswXQogICAgICAgICAgICAgICAgICAgIGlmIHRpcG8gPT0gJ2xvZyc6
:::CiAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuX2xvZyhldlsxXSwgZXZbMl0p
:::CiAgICAgICAgICAgICAgICAgICAgZWxpZiB0aXBvID09ICdwcm9nJzoKICAgICAg
:::ICAgICAgICAgICAgICAgICAgcGN0LCB0ZXh0byA9IGV2WzFdLCBldlsyXQogICAg
:::ICAgICAgICAgICAgICAgICAgICBpZiBwY3QgaXMgTm9uZToKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgIHNlbGYuYmFycmEuc3RvcCgpCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICBzZWxmLmJhcnJhLmNvbmZpZ3VyZShtb2RlPSdpbmRldGVy
:::bWluYXRlJykKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYmFycmEu
:::c3RhcnQoNjApCiAgICAgICAgICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICBzZWxmLmJhcnJhLnN0b3AoKQogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgc2VsZi5iYXJyYS5jb25maWd1cmUobW9kZT0nZGV0
:::ZXJtaW5hdGUnKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5iYXJy
:::YS5jb25maWd1cmUodmFsdWU9bWF4KDAsIG1pbigxMDAsIHBjdCkpKQogICAgICAg
:::ICAgICAgICAgICAgICAgICBzZWxmLmxibF9lc3RhZG8uY29uZmlndXJlKHRleHQ9
:::dGV4dG8pCiAgICAgICAgICAgICAgICAgICAgZWxpZiB0aXBvID09ICdlc3RpbWFj
:::aW9uJzoKICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5sYmxfZXN0aW1hY2lv
:::bi5jb25maWd1cmUoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0ZXh0PWV2
:::WzFdLCBmZz1URU1BU1tzZWxmLl90ZW1hX2FjdHVhbF1bJ2FjZW50byddKQogICAg
:::ICAgICAgICAgICAgICAgIGVsaWYgdGlwbyA9PSAnZmluJzoKICAgICAgICAgICAg
:::ICAgICAgICAgICAgc2VsZi5fZmluX3RhcmVhKGV2WzFdLCBldlsyXSwgZXZbM10g
:::aWYgbGVuKGV2KSA+IDMgZWxzZSAnJykKICAgICAgICAgICAgZXhjZXB0IHF1ZXVl
:::LkVtcHR5OgogICAgICAgICAgICAgICAgcGFzcwogICAgICAgICAgICBzZWxmLmFm
:::dGVyKDgwLCBzZWxmLl9ib21iZWFyX2NvbGEpCgogICAgICAgICMgLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIHRhcmVhcwog
:::ICAgICAgIGRlZiBfaGFiaWxpdGFyX2FjY2lvbmVzKHNlbGYsIG9uKToKICAgICAg
:::ICAgICAgZXN0YWRvID0gJ25vcm1hbCcgaWYgb24gZWxzZSAnZGlzYWJsZWQnCiAg
:::ICAgICAgICAgIGZvciBiIGluIChzZWxmLmJ0bl9kZXNjYXJnYXIsIHNlbGYuYnRu
:::X2NvbXByb2JhciwKICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYnRuX2VzdGlt
:::YXIsIHNlbGYuYnRuX2NhbWJpYXIsIHNlbGYuYnRuX2FicmlyLAogICAgICAgICAg
:::ICAgICAgICAgICAgc2VsZi5idG5feCk6CiAgICAgICAgICAgICAgICBiLmNvbmZp
:::Z3VyZShzdGF0ZT1lc3RhZG8sIGN1cnNvcj0naGFuZDInIGlmIG9uIGVsc2UgJ2Fy
:::cm93JykKCiAgICAgICAgZGVmIF9pbmljaWFyKHNlbGYsIG9iamV0aXZvLCBjZmcs
:::IHRleHRvKToKICAgICAgICAgICAgaWYgc2VsZi5fb2N1cGFkbzoKICAgICAgICAg
:::ICAgICAgIHNlbGYuX2xvZygnWWEgaGF5IHVuYSB0YXJlYSBlbiBjdXJzbzsgZXNw
:::ZXJhIGEgcXVlIHRlcm1pbmUuJywKICAgICAgICAgICAgICAgICAgICAgICAgICAn
:::YXZpc28nKQogICAgICAgICAgICAgICAgcmV0dXJuIEZhbHNlCiAgICAgICAgICAg
:::IHNlbGYuX29jdXBhZG8gPSBUcnVlCiAgICAgICAgICAgIHNlbGYuX2hhYmlsaXRh
:::cl9hY2Npb25lcyhGYWxzZSkKICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmNv
:::bmZpZ3VyZSh0ZXh0PXRleHRvKQogICAgICAgICAgICB0aHJlYWRpbmcuVGhyZWFk
:::KHRhcmdldD1vYmpldGl2bywgYXJncz0oY2ZnLCksIGRhZW1vbj1UcnVlKS5zdGFy
:::dCgpCiAgICAgICAgICAgIHJldHVybiBUcnVlCgogICAgICAgIGRlZiBfZmluX3Rh
:::cmVhKHNlbGYsIHRpcG8sIG9rLCBtZW5zYWplPScnKToKICAgICAgICAgICAgc2Vs
:::Zi5fb2N1cGFkbyA9IEZhbHNlCiAgICAgICAgICAgIHNlbGYuX2hhYmlsaXRhcl9h
:::Y2Npb25lcyhUcnVlKQogICAgICAgICAgICBzZWxmLmJhcnJhLnN0b3AoKQogICAg
:::ICAgICAgICBzZWxmLmJhcnJhLmNvbmZpZ3VyZShtb2RlPSdkZXRlcm1pbmF0ZScp
:::CiAgICAgICAgICAgIHNlbGYuYmFycmEuY29uZmlndXJlKHZhbHVlPTApCiAgICAg
:::ICAgICAgIGlmIHRpcG8gPT0gJ2Rlc2NhcmdhJyBhbmQgb2s6CiAgICAgICAgICAg
:::ICAgICBzZWxmLmxibF9lc3RhZG8uY29uZmlndXJlKHRleHQ9J0xpc3RvLicpCiAg
:::ICAgICAgICAgIGVsaWYgbm90IG9rOgogICAgICAgICAgICAgICAgc2VsZi5sYmxf
:::ZXN0YWRvLmNvbmZpZ3VyZSh0ZXh0PSdUZXJtaW5hZG8gY29uIGVycm9yZXMuJykK
:::ICAgICAgICAgICAgICAgIGlmIHRpcG8gPT0gJ2Rlc2NhcmdhJzoKICAgICAgICAg
:::ICAgICAgICAgICBtZXNzYWdlYm94LnNob3dlcnJvcigKICAgICAgICAgICAgICAg
:::ICAgICAgICAgJ0Vycm9yJywgbWVuc2FqZSBvciAnTm8gc2UgcHVkbyBjb21wbGV0
:::YXIgbGEgdGFyZWEuICcKICAgICAgICAgICAgICAgICAgICAgICAgJ1JldmlzYSBl
:::bCByZWdpc3RybyBwYXJhIG3DoXMgZGV0YWxsZXMuJykKCiAgICAgICAgZGVmIF91
:::cmxfdmFsaWRhKHNlbGYpOgogICAgICAgICAgICBpZiBzZWxmLl9lbl9wbGFjZWhv
:::bGRlcjoKICAgICAgICAgICAgICAgIHNlbGYuX2xvZygnUHJpbWVybyBwZWdhIGxh
:::IFVSTCBkZWwgdmlkZW8gZGUgWW91VHViZS4nLCAnYXZpc28nKQogICAgICAgICAg
:::ICAgICAgcmV0dXJuIE5vbmUKICAgICAgICAgICAgdSA9IHNlbGYuZW50X3VybC5n
:::ZXQoKS5zdHJpcCgpLnN0cmlwKCciJykuc3RyaXAoIiciKQogICAgICAgICAgICBp
:::ZiBub3QgdToKICAgICAgICAgICAgICAgIHNlbGYuX2xvZygnTGEgVVJMIGVzdMOh
:::IHZhY8OtYS4nLCAnYXZpc28nKQogICAgICAgICAgICAgICAgcmV0dXJuIE5vbmUK
:::ICAgICAgICAgICAgaWYgbm90IHJlLm1hdGNoKHInXmh0dHBzPzovLycsIHUsIHJl
:::LkkpOgogICAgICAgICAgICAgICAgaWYgcmUubWF0Y2gocided3d3XC4nLCB1LCBy
:::ZS5JKToKICAgICAgICAgICAgICAgICAgICB1ID0gJ2h0dHBzOi8vJyArIHUKICAg
:::ICAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICAgICAgc2VsZi5fbG9n
:::KCdFc28gbm8gcGFyZWNlIHVuYSBVUkwgKGRlYmUgZW1wZXphciBwb3IgJwogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAnaHR0cDovLyBvIGh0dHBzOi8vKScs
:::ICdlcnJvcicpCiAgICAgICAgICAgICAgICAgICAgcmV0dXJuIE5vbmUKICAgICAg
:::ICAgICAgdSwgY2FtYmlvID0gc2luX3BsYXlsaXN0KHUpCiAgICAgICAgICAgIGlm
:::IGNhbWJpbzoKICAgICAgICAgICAgICAgIHNlbGYuX2xvZygnKHNlIGlnbm9yYXLD
:::oSBsYSBsaXN0YSBkZSByZXByb2R1Y2Npw7NuOiAnCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgJ21vZG8gc29sbyB2aWRlbyknLCAnZ3JpcycpCiAgICAgICAgICAg
:::IHJldHVybiB1CgogICAgICAgIGRlZiBfYWNjaW9uX2VzdGltYXIoc2VsZik6CiAg
:::ICAgICAgICAgIHVybCA9IHNlbGYuX3VybF92YWxpZGEoKQogICAgICAgICAgICBp
:::ZiBub3QgdXJsOgogICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgIHNl
:::bGYuX2d1YXJkYXIoKQogICAgICAgICAgICBjZmcgPSB7J3VybCc6IHVybH0KICAg
:::ICAgICAgICAgc2VsZi5faW5pY2lhcihzZWxmLl9oaWxvX2VzdGltYXIsIGNmZywg
:::J0VzdGltYW5kbyB0YW1hw7FvLi4uJykKICAgICAgICAgICAgc2VsZi5sYmxfZXN0
:::aW1hY2lvbi5jb25maWd1cmUoCiAgICAgICAgICAgICAgICB0ZXh0PSdDYWxjdWxh
:::bmRvLi4uJywgZmc9VEVNQVNbc2VsZi5fdGVtYV9hY3R1YWxdWyd0ZXh0bzInXSkK
:::CiAgICAgICAgZGVmIF9hY2Npb25fZGVzY2FyZ2FyKHNlbGYpOgogICAgICAgICAg
:::ICB1cmwgPSBzZWxmLl91cmxfdmFsaWRhKCkKICAgICAgICAgICAgaWYgbm90IHVy
:::bDoKICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICBzZWxmLl9ndWFy
:::ZGFyKCkKICAgICAgICAgICAgY2ZnID0geyd1cmwnOiB1cmx9CiAgICAgICAgICAg
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
:::dCc6IDMwLCAnbG9nZ2VyJzogUkVHSVNUUk99CiAgICAgICAgICAgICAgICBuYXYg
:::PSBBSlVTVEVTLmdldCgnbmF2ZWdhZG9yJywgJyhuaW5ndW5vKScpCiAgICAgICAg
:::ICAgICAgICBpZiBuYXYgIT0gJyhuaW5ndW5vKSc6CiAgICAgICAgICAgICAgICAg
:::ICAgb1snY29va2llc2Zyb21icm93c2VyJ10gPSAobmF2LCkKICAgICAgICAgICAg
:::ICAgIHdpdGggWVRfRExQLllvdXR1YmVETChvKSBhcyB5ZGw6CiAgICAgICAgICAg
:::ICAgICAgICAgaW5mbyA9IHlkbC5leHRyYWN0X2luZm8oY2ZnWyd1cmwnXSwgZG93
:::bmxvYWQ9RmFsc2UpCiAgICAgICAgICAgICAgICBkdXIgPSBpbmZvLmdldCgnZHVy
:::YXRpb24nKQogICAgICAgICAgICAgICAgaWYgbm90IGR1cjoKICAgICAgICAgICAg
:::ICAgICAgICBsb2coJ05vIHNlIHB1ZG8gb2J0ZW5lciBsYSBkdXJhY2nDs24gZGVs
:::IHZpZGVvLicsICdlcnJvcicpCiAgICAgICAgICAgICAgICAgICAgY29sYS5wdXQo
:::KCdlc3RpbWFjaW9uJywgJ1NpbiBkYXRvcyBwYXJhIGVzdGltYXInKSkKICAgICAg
:::ICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgICAgIGNsYXZlID0gc2Vs
:::Zi5fZm10X2FjdHVhbF9zb2xvKEFKVVNURVMuZ2V0KCdmb3JtYXRvJywgJ0FBQycp
:::KQogICAgICAgICAgICAgICAgdGFtID0gZXN0aW1hcl9ieXRlcyhkdXIsIGNsYXZl
:::LCBBSlVTVEVTLmdldCgnY2FsaWRhZCcpLAogICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICBib29sKEFKVVNURVMuZ2V0KCdlbWJlYmVyJywgVHJ1ZSkp
:::KQogICAgICAgICAgICAgICAgdGl0dWxvID0gc3RyKGluZm8uZ2V0KCd0aXRsZScp
:::IG9yICcnKVs6NzBdCiAgICAgICAgICAgICAgICBpZiB0aXR1bG86CiAgICAgICAg
:::ICAgICAgICAgICAgbG9nKCfimaogJyArIHRpdHVsbywgJ3RpdHVsbycpCiAgICAg
:::ICAgICAgICAgICB0ZXh0byA9IChmJ357dGFtIC8gMTA0ODU3NjouMWZ9IE1CIMK3
:::ICcKICAgICAgICAgICAgICAgICAgICAgICAgIGYnZHVyYWNpw7NuIHtmbXRfdGll
:::bShkdXIpfSDCtyAnCiAgICAgICAgICAgICAgICAgICAgICAgICBmJ3tjbGF2ZX0g
:::e0FKVVNURVMuZ2V0KCJjYWxpZGFkIiwgIiIpfScucnN0cmlwKCkpCiAgICAgICAg
:::ICAgICAgICBjb2xhLnB1dCgoJ2VzdGltYWNpb24nLCB0ZXh0bykpCiAgICAgICAg
:::ICAgICAgICBsb2coJ0VzdGltYWNpw7NuOiAnICsgdGV4dG8sICdvaycpCiAgICAg
:::ICAgICAgICAgICBsb2coJ0VsIHRhbWHDsW8gcmVhbCBwdWVkZSB2YXJpYXIgYWxn
:::byBzZWfDum4gbGEgZnVlbnRlLicsCiAgICAgICAgICAgICAgICAgICAgJ2dyaXMn
:::KQogICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uIGFzIGU6CiAgICAgICAgICAg
:::ICAgICBsb2coZidObyBzZSBwdWRvIGVzdGltYXI6IHtzZWxmLl9tc2dfZXJyb3Io
:::ZSl9JywgJ2Vycm9yJykKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZXN0aW1h
:::Y2lvbicsICdObyBzZSBwdWRvIGVzdGltYXInKSkKICAgICAgICAgICAgZmluYWxs
:::eToKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2VzdGltYWNpb24n
:::LCBUcnVlLCAnJykpCgogICAgICAgIGRlZiBfZm10X2FjdHVhbF9zb2xvKHNlbGYs
:::IGNsYXZlKToKICAgICAgICAgICAgcmV0dXJuIGNsYXZlIGlmIGNsYXZlIGluIEZP
:::Uk1BVE9TIGVsc2UgJ0FBQycKCiAgICAgICAgZGVmIF9oaWxvX2Rlc2Nhcmdhcihz
:::ZWxmLCBjZmcpOgogICAgICAgICAgICBjb2xhID0gc2VsZi5jb2xhCgogICAgICAg
:::ICAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAgICAgICAgICAgIGNvbGEu
:::cHV0KCgnbG9nJywgbSwgdCkpCgogICAgICAgICAgICB1cmwgPSBjZmdbJ3VybCdd
:::CiAgICAgICAgICAgIGNsYXZlID0gc2VsZi5fZm10X2FjdHVhbF9zb2xvKEFKVVNU
:::RVMuZ2V0KCdmb3JtYXRvJywgJ0FBQycpKQogICAgICAgICAgICBjYWxpZGFkID0g
:::QUpVU1RFUy5nZXQoJ2NhbGlkYWQnLCAnMTI4aycpCiAgICAgICAgICAgIGVtYmVi
:::ZXIgPSBib29sKEFKVVNURVMuZ2V0KCdlbWJlYmVyJywgVHJ1ZSkpCiAgICAgICAg
:::ICAgIG5hdiA9IEFKVVNURVMuZ2V0KCduYXZlZ2Fkb3InLCAnKG5pbmd1bm8pJykK
:::ICAgICAgICAgICAgZGVzdGlubyA9IFBhdGgob3MucGF0aC5leHBhbmR2YXJzKAog
:::ICAgICAgICAgICAgICAgc3RyKEFKVVNURVMuZ2V0KCdkZXN0aW5vJywgX2Rlc3Rp
:::bm9fcG9yX2RlZmVjdG8oKSkpKSkKICAgICAgICAgICAgdHJ5OgogICAgICAgICAg
:::ICAgICAgZGVzdGluby5ta2RpcihwYXJlbnRzPVRydWUsIGV4aXN0X29rPVRydWUp
:::CiAgICAgICAgICAgICAgICBjYWxpZGFkX2FyZyA9IHsnQUFDJzogJzEyOCcsICdG
:::TEFDJzogJzAnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ1dBVic6
:::ICcwJ30uZ2V0KGNsYXZlKSBvciBcCiAgICAgICAgICAgICAgICAgICAgcmUuc3Vi
:::KHInW14wLTldJywgJycsIGNhbGlkYWQpIG9yICczMjAnCiAgICAgICAgICAgICAg
:::ICBpZiBjbGF2ZSA9PSAnV01BJzoKICAgICAgICAgICAgICAgICAgICBpbmZvLCBh
:::cmNoaXZvID0gZGVzY2FyZ2FyX3dtYSh1cmwsIGRlc3Rpbm8sIGVtYmViZXIsCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::bmF2LCBjb2xhKQogICAgICAgICAgICAgICAgZWxpZiBjbGF2ZSA9PSAnQVZJJzoK
:::ICAgICAgICAgICAgICAgICAgICBpbmZvLCBhcmNoaXZvID0gZGVzY2FyZ2FyX2F2
:::aSh1cmwsIGRlc3Rpbm8sIG5hdiwgY29sYSkKICAgICAgICAgICAgICAgIGVsc2U6
:::CiAgICAgICAgICAgICAgICAgICAgaW5mbywgYXJjaGl2byA9IGRlc2Nhcmdhcl9h
:::dWRpbyh1cmwsIGNsYXZlLCBjYWxpZGFkX2FyZywKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRlc3Rpbm8sIGVtYmVi
:::ZXIsIG5hdiwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
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
:::ICAgICAgICAgIHNlbGYuX2xvZyhmJ011c2lrQUxBTiB2e0FQUF9WfSDigJQgJwog
:::ICAgICAgICAgICAgICAgICAgICAgJ1lvdVR1YmUgRG93bmxvYWRlcicsICd0aXR1
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
