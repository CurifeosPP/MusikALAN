@echo off
rem ================================================================
rem  DESCARGADOR DE MUSICA - instalador y lanzador todo-en-uno
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
title Descargador de Musica v2.1
cd /d "%~dp0"

set "APPDIR=%~dp0"
set "RUNTIME=%APPDIR%runtime"
set "FFDIR=%APPDIR%ffmpeg"
set "SCRIPT=%APPDIR%descargador.py"
set "TMPDIR=%APPDIR%_instalacion_tmp"
set "PYEXE="
set "PYARGS="

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
echo  %C_TIT% ___  ___ ___  ___   _   ___  ___   _   ___   ___  ___%C_FIN%
echo  %C_TIT%^|   \^| __/ __^|/ __^| /_\ ^| _ \/ __^| /_\ ^|   \ / _ \^| _ \%C_FIN%
echo  %C_TIT%^| ^|) ^| _^|\__ \ (__ / _ \^|   / (_ ^|/ _ \^| ^|) ^| (_) ^|   /%C_FIN%
echo  %C_TIT%^|___/^|___^|___/\___/_/ \_\_^|_\\___/_/ \_\___/ \___/^|_^|_\%C_FIN%
echo.
echo   %C_GRI%--------------------------------------------------------------------%C_FIN%
echo    %C_TIT%Descargador de Musica v2.1%C_FIN% - preparando el entorno
echo    Instalador portable: no pide permisos de administrador.
echo    Si falta algo (Python, yt-dlp, FFmpeg) se descarga e instala aqui.
echo   %C_GRI%--------------------------------------------------------------------%C_FIN%
echo    Sistema : Windows 10 o superior, %ARCH%
echo    Carpeta : %APPDIR%
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
echo    %C_OK%OK%C_FIN% Python portatil propio (carpeta runtime).
goto py_listo

:py_sys_py
set "PYEXE=py"
set "PYARGS=-3"
echo    %C_OK%OK%C_FIN% Python del sistema encontrado (py launcher).
goto py_listo

:py_sys_plain
set "PYEXE=python"
set "PYARGS="
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
echo   Las descargas quedan en tu carpeta Musica\YTDownloader (cambiable).
echo   Puedes cerrar esta consola cuando quieras; la ventana es independiente.
echo   %C_GRI%--------------------------------------------------------------------%C_FIN%
echo.
title Descargador de Musica v2.1 - YouTube a AAC/MP3/FLAC/WAV/WMA/AVI
if exist "%RUNTIME%\python\pythonw.exe" goto lanzar_gui
echo    La ventana de descargas se abre a continuacion.
echo    Puedes dejar esta consola abierta o cerrarla.
"%PYEXE%" %PYARGS% "%SCRIPT%"
if errorlevel 1 goto fin_error_run
endlocal
exit /b 0

:lanzar_gui
start "" "%RUNTIME%\python\pythonw.exe" "%SCRIPT%"
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
:::IiIKRGVzY2FyZ2Fkb3IgZGUgTXVzaWNhIOKAlCBpbnRlcmZheiBncmFmaWNhIChU
:::a2ludGVyKSBwYXJhIHl0LWRscCArIEZGbXBlZwo9PT09PT09PT09PT09PT09PT09
:::PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
:::PT09PQpBcHAgZGUgZXNjcml0b3JpbyBwYXJhIGRlc2NhcmdhciBtdXNpY2EgeSB2
:::aWRlb3MgZGUgWW91VHViZSBlbiBmb3JtYXRvcwphcHRvcyBwYXJhIHJlcHJvZHVj
:::dG9yZXMgcG9ydGF0aWxlcyBhbnRpZ3VvcyAodGlwbyAic2hlaWp1IiBNUDMgZGUg
:::MS44IgpwdWxnYWRhcyB5IHBhbnRhbGxhIDEyOHgxNjApOgoKICDCtyBBQUMgICgu
:::bTRhKSAgbWF4aW1vIDEyOCBrYnBzCiAgwrcgTVAzICAoLm1wMykgIDEyOCAvIDE5
:::MiAvIDI1NiAvIDMyMCBrYnBzIChkZXNwbGVnYWJsZSAiQ2FsaWRhZCIpCiAgwrcg
:::RkxBQyAoLmZsYWMpIHNpbiBwZXJkaWRhCiAgwrcgV0FWICAoLndhdikgIHNpbiBw
:::ZXJkaWRhIChhcmNoaXZvcyBncmFuZGVzKQogIMK3IFdNQSAgKC53bWEpICAxMjgg
:::a2JwcyAoY29kaWZpY2Fkb3Igd21hdjIgZGUgRkZtcGVnOyBlbCBjb250ZW5lZG9y
:::CiAgICAgICAgICAgICAgICAgQVNGIG5vIGFkbWl0ZSBjYXJhdHVsYSBpbmNydXN0
:::YWRhKQogIMK3IEFWSSAgKC5hdmkpICB2aWRlbyByZWNvZGlmaWNhZG8gcGFyYSBl
:::bCByZXByb2R1Y3RvciBzaGVpanUgMS44IgogICAgICAgICAgICAgICAgIDEyOHgx
:::NjAsIGNvbiBsb3MgcGFyYW1ldHJvcyBvZmljaWFsZXMgZGVsIHJlcG9zaXRvcmlv
:::CiAgICAgICAgICAgICAgICAgZ2l0aHViLmNvbS9mZGQ0cy9wb3J0YWJsZV9tcDNf
:::cGxheWVyX3ZpZGVvX2NvbnZlcnRlcl90b29scwogICAgICAgICAgICAgICAgIChz
:::Y3JpcHQgdmlkZW8yc2hlbmp1MTguc2gpCgpMYSBpbnN0YWxhY2lvbiBkZSBQeXRo
:::b24sIHl0LWRscCB5IEZGbXBlZyBsYSBoYWNlIGF1dG9tYXRpY2FtZW50ZSBlbAph
:::cmNoaXZvIERlc2NhcmdhZG9yTXVzaWNhLmJhdDsgZXN0ZSBzY3JpcHQgZXMgbGEg
:::dmVudGFuYSBxdWUgc2UgdXNhIGEKZGlhcmlvICh0ZW1hIG9zY3Vyby9jbGFybywg
:::Y29va2llcyBkZWwgbmF2ZWdhZG9yLCBlc3RpbWFjaW9uIGRlIHRhbWFubwp5IGNv
:::bXByb2JhZG9yIGRlIGNhbGlkYWQgZGUgbGEgY2FycGV0YSkuCgpVc286ICBweXRo
:::b24gZGVzY2FyZ2Fkb3IucHkgICAobyBkb2JsZSBjbGljIGVuIERlc2NhcmdhZG9y
:::TXVzaWNhLmJhdCkKU29sbyBkZXNjYXJnYSB2aWRlb3MgaW5kaXZpZHVhbGVzOiBz
:::aSBsYSBVUkwgdHJhZSBsaXN0YSBkZSByZXByb2R1Y2Npb24sCnNlIGlnbm9yYSBs
:::YSBsaXN0YSB5IHNlIGJhamEgdW5pY2FtZW50ZSBlbCB2aWRlbyBwZWdhZG8uCiIi
:::IgoKaW1wb3J0IGpzb24KaW1wb3J0IG9zCmltcG9ydCBxdWV1ZQppbXBvcnQgcmUK
:::aW1wb3J0IHNodXRpbAppbXBvcnQgc3VicHJvY2VzcwppbXBvcnQgc3lzCmltcG9y
:::dCB0aHJlYWRpbmcKaW1wb3J0IHRyYWNlYmFjawpmcm9tIHBhdGhsaWIgaW1wb3J0
:::IFBhdGgKZnJvbSB1cmxsaWIucGFyc2UgaW1wb3J0IHBhcnNlX3FzLCB1cmxlbmNv
:::ZGUsIHVybHBhcnNlLCB1cmx1bnBhcnNlCmZyb20gdXJsbGliLnJlcXVlc3QgaW1w
:::b3J0IHVybG9wZW4KCkFQUF9WID0gJzIuMScKQVBQX0RJUiA9IFBhdGgoX19maWxl
:::X18pLnJlc29sdmUoKS5wYXJlbnQKUlVUQV9BSlVTVEVTID0gQVBQX0RJUiAvICdh
:::anVzdGVzLmpzb24nCkxPR19FUlJPUkVTID0gQVBQX0RJUiAvICdkZXNjYXJnYWRv
:::cl9lcnJvcmVzLmxvZycKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBzYWxpZGEKIyBBbCBl
:::amVjdXRhcnNlIGNvbiBweXRob253LmV4ZSAoc2luIGNvbnNvbGEpIHN0ZG91dC9z
:::dGRlcnIgc29uIE5vbmU6CiMgY3VhbHF1aWVyIHByaW50IGZhbGxhcmlhLiBMb3Mg
:::cmVkaXJpZ2ltb3MgYSB1biBzaXRpbyBzZWd1cm8uCnRyeToKICAgIGlmIHN5cy5z
:::dGRvdXQgaXMgTm9uZToKICAgICAgICBzeXMuc3Rkb3V0ID0gb3Blbihvcy5kZXZu
:::dWxsLCAndycsIGVuY29kaW5nPSd1dGYtOCcpCmV4Y2VwdCBFeGNlcHRpb246CiAg
:::ICBwYXNzCnRyeToKICAgIGlmIHN5cy5zdGRlcnIgaXMgTm9uZToKICAgICAgICBz
:::eXMuc3RkZXJyID0gb3BlbihMT0dfRVJST1JFUywgJ2EnLCBlbmNvZGluZz0ndXRm
:::LTgnKQpleGNlcHQgRXhjZXB0aW9uOgogICAgcGFzcwoKCmRlZiBfcmVjb25maWd1
:::cmFyX3NhbGlkYSgpOgogICAgIiIiRXZpdGEgY3Jhc2hlcyBwb3IgY2FyYWN0ZXJl
:::cyByYXJvcyBzaSBsYSBzYWxpZGEgc2UgcmVkaXJpZ2UuIiIiCiAgICBmb3IgcyBp
:::biAoc3lzLnN0ZG91dCwgc3lzLnN0ZGVycik6CiAgICAgICAgdHJ5OgogICAgICAg
:::ICAgICBpZiBzIGFuZCBoYXNhdHRyKHMsICdyZWNvbmZpZ3VyZScpOgogICAgICAg
:::ICAgICAgICAgcy5yZWNvbmZpZ3VyZShlcnJvcnM9J3JlcGxhY2UnKQogICAgICAg
:::IGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgIHBhc3MKCgojIC0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0gdGtpbnRlcgp0cnk6CiAgICBpbXBvcnQgdGtpbnRlciBhcyB0awog
:::ICAgZnJvbSB0a2ludGVyIGltcG9ydCBmaWxlZGlhbG9nLCBtZXNzYWdlYm94LCB0
:::dGsKICAgIGZyb20gdGtpbnRlci5zY3JvbGxlZHRleHQgaW1wb3J0IFNjcm9sbGVk
:::VGV4dAogICAgVEtfT0sgPSBUcnVlCmV4Y2VwdCBFeGNlcHRpb246CiAgICBUS19P
:::SyA9IEZhbHNlCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGFqdXN0ZXMKZGVmIF9kZXN0
:::aW5vX3Bvcl9kZWZlY3RvKCk6CiAgICByZXR1cm4gc3RyKFBhdGguaG9tZSgpIC8g
:::J011c2ljJyAvICdZVERvd25sb2FkZXInKQoKCkFKVVNURVNfREVGRUNUTyA9IHsK
:::ICAgICdkZXN0aW5vJzogX2Rlc3Rpbm9fcG9yX2RlZmVjdG8oKSwKICAgICd0ZW1h
:::JzogJ09zY3VybycsCiAgICAnZm9ybWF0byc6ICdBQUMnLAogICAgJ2NhbGlkYWQn
:::OiAnMTI4aycsCiAgICAnZW1iZWJlcic6IFRydWUsCiAgICAnbmF2ZWdhZG9yJzog
:::JyhuaW5ndW5vKScsCn0KCgpkZWYgY2FyZ2FyX2FqdXN0ZXMoKToKICAgIGEgPSBk
:::aWN0KEFKVVNURVNfREVGRUNUTykKICAgIHRyeToKICAgICAgICBhLnVwZGF0ZShq
:::c29uLmxvYWRzKFJVVEFfQUpVU1RFUy5yZWFkX3RleHQoZW5jb2Rpbmc9J3V0Zi04
:::JykpKQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICBwYXNzCiAgICByZXR1
:::cm4gYQoKCmRlZiBndWFyZGFyX2FqdXN0ZXMoKToKICAgIHRyeToKICAgICAgICBS
:::VVRBX0FKVVNURVMud3JpdGVfdGV4dCgKICAgICAgICAgICAganNvbi5kdW1wcyhB
:::SlVTVEVTLCBlbnN1cmVfYXNjaWk9RmFsc2UsIGluZGVudD0yKSwKICAgICAgICAg
:::ICAgZW5jb2Rpbmc9J3V0Zi04JykKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAg
:::ICAgcGFzcwoKCkFKVVNURVMgPSBjYXJnYXJfYWp1c3RlcygpCgoKIyAtLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tIHV0aWxzCmRlZiBmbXRfdGFtKG4pOgogICAgaWYgbm90IG46CiAg
:::ICAgICAgcmV0dXJuICfigJQnCiAgICBuID0gZmxvYXQobikKICAgIGZvciB1IGlu
:::ICgnQicsICdLaUInLCAnTWlCJywgJ0dpQicpOgogICAgICAgIGlmIG4gPCAxMDI0
:::IG9yIHUgPT0gJ0dpQic6CiAgICAgICAgICAgIHJldHVybiBmJ3tpbnQobil9IHt1
:::fScgaWYgdSA9PSAnQicgZWxzZSBmJ3tuOi4xZn0ge3V9JwogICAgICAgIG4gLz0g
:::MTAyNAoKCmRlZiBmbXRfdGllbShzKToKICAgIGlmIHMgaXMgTm9uZToKICAgICAg
:::ICByZXR1cm4gJ+KAlCcKICAgIHMgPSBpbnQocykKICAgIGgsIHIgPSBkaXZtb2Qo
:::cywgMzYwMCkKICAgIG0sIHggPSBkaXZtb2QociwgNjApCiAgICByZXR1cm4gZid7
:::aH06e206MDJkfTp7eDowMmR9JyBpZiBoIGVsc2UgZid7bTowMmR9Ont4OjAyZH0n
:::CgoKZGVmIGxpbXBpYXJfbm9tYnJlKHQpOgogICAgdCA9IHJlLnN1YihyJ1s8Pjoi
:::L1xcfD8qXHgwMC1ceDFmXScsICdfJywgc3RyKHQpKS5zdHJpcCgnIC4nKQogICAg
:::cmV0dXJuIHRbOjE1MF0gb3IgJ3Npbl90aXR1bG8nCgoKZGVmIHNpbl9wbGF5bGlz
:::dCh1cmwpOgogICAgIiIiUXVpdGEgZWwgcGFyw6FtZXRybyBsaXN0PSBkZSBsYSBV
:::UkwgKG1vZG8gc29sbyB2aWRlbykuIiIiCiAgICB0cnk6CiAgICAgICAgcCA9IHVy
:::bHBhcnNlKHVybCkKICAgICAgICBxID0gcGFyc2VfcXMocC5xdWVyeSkKICAgICAg
:::ICBpZiAnbGlzdCcgaW4gcToKICAgICAgICAgICAgZGVsIHFbJ2xpc3QnXQogICAg
:::ICAgICAgICByZXR1cm4gdXJsdW5wYXJzZShwLl9yZXBsYWNlKHF1ZXJ5PXVybGVu
:::Y29kZShxLCBkb3NlcT1UcnVlKSkpLCBUcnVlCiAgICBleGNlcHQgRXhjZXB0aW9u
:::OgogICAgICAgIHBhc3MKICAgIHJldHVybiB1cmwsIEZhbHNlCgoKZGVmIGFicmly
:::X2NhcnBldGEocnV0YSk6CiAgICB0cnk6CiAgICAgICAgaWYgb3MubmFtZSA9PSAn
:::bnQnOgogICAgICAgICAgICBvcy5zdGFydGZpbGUoc3RyKHJ1dGEpKSAgIyBub3Fh
:::OiBzb2xvIFdpbmRvd3MKICAgICAgICBlbHNlOgogICAgICAgICAgICBzdWJwcm9j
:::ZXNzLlBvcGVuKFsneGRnLW9wZW4nLCBzdHIocnV0YSldKQogICAgZXhjZXB0IEV4
:::Y2VwdGlvbjoKICAgICAgICBwYXNzCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGZmbXBl
:::ZwpkZWYgYnVzY2FyX2ZmbXBlZygpOgogICAgZXhlID0gc2h1dGlsLndoaWNoKCdm
:::Zm1wZWcnKQogICAgaWYgZXhlOgogICAgICAgIHJldHVybiBQYXRoKGV4ZSkKICAg
:::IGNhbmRpZGF0b3MgPSBbCiAgICAgICAgQVBQX0RJUiAvICdmZm1wZWcnIC8gJ2Jp
:::bicgLyAnZmZtcGVnLmV4ZScsCiAgICAgICAgQVBQX0RJUiAvICdmZm1wZWcnIC8g
:::J2JpbicgLyAnZmZtcGVnJywKICAgICAgICBBUFBfRElSIC8gJ3J1bnRpbWUnIC8g
:::J2ZmbXBlZy5leGUnLAogICAgXQogICAgZm9yIHAgaW4gY2FuZGlkYXRvczoKICAg
:::ICAgICBpZiBwLmV4aXN0cygpOgogICAgICAgICAgICByZXR1cm4gcAogICAgcmV0
:::dXJuIE5vbmUKCgpkZWYgYnVzY2FyX2ZmcHJvYmUoZmZtcGVnKToKICAgIGlmIGZm
:::bXBlZyBpcyBOb25lOgogICAgICAgIHJldHVybiBzaHV0aWwud2hpY2goJ2ZmcHJv
:::YmUnKQogICAgcCA9IGZmbXBlZy53aXRoX25hbWUoJ2ZmcHJvYmUuZXhlJyBpZiBv
:::cy5uYW1lID09ICdudCcgZWxzZSAnZmZwcm9iZScpCiAgICBpZiBwLmV4aXN0cygp
:::OgogICAgICAgIHJldHVybiBwCiAgICByZXR1cm4gc2h1dGlsLndoaWNoKCdmZnBy
:::b2JlJykKCgpZVF9ETFAgPSBOb25lICAgIyBtw7NkdWxvIHl0X2RscDsgc2UgcmVs
:::bGVuYSBlbiBjb21wcm9iYXJfZW50b3JubygpCkZGTVBFRyA9IE5vbmUgICAjIHJ1
:::dGEgZGUgZmZtcGVnCkZGUFJPQkUgPSBOb25lICAjIHJ1dGEgZGUgZmZwcm9iZQoK
:::CmRlZiBjb21wcm9iYXJfZW50b3JubygpOgogICAgZ2xvYmFsIFlUX0RMUCwgRkZN
:::UEVHLCBGRlBST0JFCiAgICB0cnk6CiAgICAgICAgaW1wb3J0IHl0X2RscCBhcyBt
:::b2QKICAgICAgICBZVF9ETFAgPSBtb2QKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAg
:::ICAgICAgcGFzcwogICAgRkZNUEVHID0gYnVzY2FyX2ZmbXBlZygpCiAgICBGRlBS
:::T0JFID0gYnVzY2FyX2ZmcHJvYmUoRkZNUEVHKQoKCmNsYXNzIFJlZ2lzdHJvOgog
:::ICAgIiIiTG9nZ2VyIHBhcmEgeXQtZGxwOiByZWVudsOtYSBhdmlzb3MvZXJyb3Jl
:::cyBhbCByZWdpc3RybyBkZSBsYSBHVUkuIiIiCgogICAgZGVmIF9faW5pdF9fKHNl
:::bGYpOgogICAgICAgIHNlbGYubG9nID0gTm9uZSAgIyBsYSBHVUkgbG8gY29uZWN0
:::YTogbG9nKG1lbnNhamUsIGV0aXF1ZXRhKQoKICAgIGRlZiBkZWJ1ZyhzZWxmLCBt
:::KToKICAgICAgICBwYXNzCgogICAgZGVmIHdhcm5pbmcoc2VsZiwgbSk6CiAgICAg
:::ICAgbSA9IHN0cihtKS5zdHJpcCgpCiAgICAgICAgaWYgbSBhbmQgc2VsZi5sb2c6
:::CiAgICAgICAgICAgIHNlbGYubG9nKG0sICdhdmlzbycpCgogICAgZGVmIGVycm9y
:::KHNlbGYsIG0pOgogICAgICAgIG0gPSBzdHIobSkuc3RyaXAoKQogICAgICAgIGlm
:::IG0gYW5kIHNlbGYubG9nOgogICAgICAgICAgICBzZWxmLmxvZyhtLCAnZXJyb3In
:::KQoKClJFR0lTVFJPID0gUmVnaXN0cm8oKQoKTk9NQlJFU19QUCA9IHsKICAgICdG
:::Rm1wZWdFeHRyYWN0QXVkaW8nOiAnQ29udmlydGllbmRvIGVsIGF1ZGlvIGNvbiBG
:::Rm1wZWcnLAogICAgJ0ZGbXBlZ01ldGFkYXRhJzogJ0VzY3JpYmllbmRvIGV0aXF1
:::ZXRhcyAodMOtdHVsby9hcnRpc3RhKScsCiAgICAnRW1iZWRUaHVtYm5haWwnOiAn
:::SW5jcnVzdGFuZG8gbGEgY2Fyw6F0dWxhJywKICAgICdNb3ZlRmlsZXMnOiAnT3Jn
:::YW5pemFuZG8gYXJjaGl2b3MnLAogICAgJ0ZGbXBlZ01lcmdlcic6ICdVbmllbmRv
:::IHBpc3RhcyBkZSB2aWRlbyB5IGF1ZGlvJywKICAgICdGRm1wZWdWaWRlb0NvbnZl
:::cnRvcic6ICdDb252aXJ0aWVuZG8gZWwgdmlkZW8nLAp9CgojIC0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0gZm9ybWF0b3MKRk9STUFUT1MgPSB7CiAgICAnQUFDJzogZGljdCh0ZXh0
:::bz0nQUFDICgubTRhKScsIGNhcnBldGE9J0FBQycsIGV4dD0nbTRhJywKICAgICAg
:::ICAgICAgICAgIGNhbGlkYWRlcz1bJzEyOGsnXSwgZGVmZWN0bz0nMTI4aycpLAog
:::ICAgJ01QMyc6IGRpY3QodGV4dG89J01QMyAoLm1wMyknLCBjYXJwZXRhPSdNUDMn
:::LCBleHQ9J21wMycsCiAgICAgICAgICAgICAgICBjYWxpZGFkZXM9WycxMjhrJywg
:::JzE5MmsnLCAnMjU2aycsICczMjBrJ10sIGRlZmVjdG89JzMyMGsnKSwKICAgICdG
:::TEFDJzogZGljdCh0ZXh0bz0nRkxBQyAoLmZsYWMpJywgY2FycGV0YT0nRkxBQycs
:::IGV4dD0nZmxhYycsCiAgICAgICAgICAgICAgICAgY2FsaWRhZGVzPVsnc2luIHBl
:::cmRpZGEnXSwgZGVmZWN0bz0nc2luIHBlcmRpZGEnKSwKICAgICdXQVYnOiBkaWN0
:::KHRleHRvPSdXQVYgKC53YXYpJywgY2FycGV0YT0nV0FWJywgZXh0PSd3YXYnLAog
:::ICAgICAgICAgICAgICAgY2FsaWRhZGVzPVsnc2luIHBlcmRpZGEnXSwgZGVmZWN0
:::bz0nc2luIHBlcmRpZGEnKSwKICAgICdXTUEnOiBkaWN0KHRleHRvPSdXTUEgKC53
:::bWEpJywgY2FycGV0YT0nV01BJywgZXh0PSd3bWEnLAogICAgICAgICAgICAgICAg
:::Y2FsaWRhZGVzPVsnMTI4ayddLCBkZWZlY3RvPScxMjhrJyksCiAgICAnQVZJJzog
:::ZGljdCh0ZXh0bz0nQVZJIC0gc2hlaWp1IDEuOCIgKDEyOHgxNjApJywgY2FycGV0
:::YT0nQVZJJywgZXh0PSdhdmknLAogICAgICAgICAgICAgICAgY2FsaWRhZGVzPVsn
:::MTI4eDE2MCDCtyAxNiBmcHMnXSwgZGVmZWN0bz0nMTI4eDE2MCDCtyAxNiBmcHMn
:::KSwKfQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBwcm9ncmVzbwpkZWYgaG9va3NfZ3Vp
:::KGNvbGEpOgogICAgIiIiQ3JlYSBsb3MgaG9va3MgZGUgeXQtZGxwIHF1ZSBwdWJs
:::aWNhbiBldmVudG9zIGVuIGxhIGNvbGEgZGUgbGEgR1VJLiIiIgogICAgZXN0YWRv
:::ID0geyd0aXR1bG8nOiBGYWxzZX0KCiAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToK
:::ICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgIGRlZiBwcm9ncmVz
:::byhkKToKICAgICAgICBpZiBkWydzdGF0dXMnXSA9PSAnZG93bmxvYWRpbmcnOgog
:::ICAgICAgICAgICBpZiBub3QgZXN0YWRvWyd0aXR1bG8nXToKICAgICAgICAgICAg
:::ICAgIGluZm8gPSBkLmdldCgnaW5mb19kaWN0Jykgb3Ige30KICAgICAgICAgICAg
:::ICAgIHQgPSBpbmZvLmdldCgndGl0bGUnKSBvciBQYXRoKGQuZ2V0KCdmaWxlbmFt
:::ZScpIG9yICcnKS5zdGVtCiAgICAgICAgICAgICAgICBpZiB0OgogICAgICAgICAg
:::ICAgICAgICAgIGxvZygn4pmqICcgKyBzdHIodClbOjkwXSwgJ3RpdHVsbycpCiAg
:::ICAgICAgICAgICAgICAgICAgZXN0YWRvWyd0aXR1bG8nXSA9IFRydWUKICAgICAg
:::ICAgICAgdG90YWwgPSBkLmdldCgndG90YWxfYnl0ZXMnKSBvciBkLmdldCgndG90
:::YWxfYnl0ZXNfZXN0aW1hdGUnKSBvciAwCiAgICAgICAgICAgIGRvbmUgPSBkLmdl
:::dCgnZG93bmxvYWRlZF9ieXRlcycsIDApCiAgICAgICAgICAgIHZlbCA9IGQuZ2V0
:::KCdzcGVlZCcpCiAgICAgICAgICAgIGV0YSA9IGQuZ2V0KCdldGEnKQogICAgICAg
:::ICAgICBpZiB0b3RhbDoKICAgICAgICAgICAgICAgIHBjdCA9IGRvbmUgLyB0b3Rh
:::bCAqIDEwMAogICAgICAgICAgICAgICAgdGV4dG8gPSBmJ3twY3Q6NS4xZn0lIMK3
:::IHtmbXRfdGFtKGRvbmUpfSAvIHtmbXRfdGFtKHRvdGFsKX0nCiAgICAgICAgICAg
:::ICAgICBpZiB2ZWw6CiAgICAgICAgICAgICAgICAgICAgdGV4dG8gKz0gZicgwrcg
:::e2ZtdF90YW0odmVsKX0vcycKICAgICAgICAgICAgICAgIGlmIGV0YSBpcyBub3Qg
:::Tm9uZToKICAgICAgICAgICAgICAgICAgICB0ZXh0byArPSBmJyDCtyBxdWVkYW4g
:::e2ZtdF90aWVtKGV0YSl9JwogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdwcm9n
:::JywgcGN0LCB0ZXh0bykpCiAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAg
:::ICB2ID0gZid7Zm10X3RhbSh2ZWwpfS9zJyBpZiB2ZWwgZWxzZSAnJwogICAgICAg
:::ICAgICAgICAgY29sYS5wdXQoKCdwcm9nJywgTm9uZSwgZid7Zm10X3RhbShkb25l
:::KX0gwrcge3Z9JykpCiAgICAgICAgZWxpZiBkWydzdGF0dXMnXSA9PSAnZmluaXNo
:::ZWQnOgogICAgICAgICAgICBjb2xhLnB1dCgoJ2xvZycsICdEZXNjYXJnYSByZWNp
:::YmlkYS4gUHJvY2VzYW5kby4uLicsICdncmlzJykpCiAgICAgICAgICAgIGNvbGEu
:::cHV0KCgncHJvZycsIDAsICdQcm9jZXNhbmRvLi4uJykpCgogICAgZGVmIHBvc3Rw
:::cm9jZXNvKGQpOgogICAgICAgIGlmIGRbJ3N0YXR1cyddID09ICdzdGFydGVkJzoK
:::ICAgICAgICAgICAgbm9tID0gKGQuZ2V0KCdwb3N0cHJvY2Vzc29yX25hbWUnKQog
:::ICAgICAgICAgICAgICAgICAgb3IgZC5nZXQoJ3Bvc3Rwcm9jZXNzb3InKSBvciAn
:::UG9zdHByb2Nlc28nKQogICAgICAgICAgICB0ZXh0byA9IE5PTUJSRVNfUFAuZ2V0
:::KG5vbSwgbm9tKSArICcuLi4nCiAgICAgICAgICAgIGNvbGEucHV0KCgnbG9nJywg
:::J+KGkiAnICsgdGV4dG8sICdncmlzJykpCiAgICAgICAgICAgIGNvbGEucHV0KCgn
:::cHJvZycsIE5vbmUsIHRleHRvKSkKCiAgICByZXR1cm4gcHJvZ3Jlc28sIHBvc3Rw
:::cm9jZXNvCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIG9wY2lvbmVzCmRlZiBvcHRzX2Jh
:::c2UoY2FycGV0YSwgY29va2llcywgY29sYSk6CiAgICBwcm9ncmVzbywgcG9zdHBy
:::b2Nlc28gPSBob29rc19ndWkoY29sYSkKICAgIG8gPSB7CiAgICAgICAgJ291dHRt
:::cGwnOiBzdHIoY2FycGV0YSAvICclKHRpdGxlKXMuJShleHQpcycpLAogICAgICAg
:::ICdxdWlldCc6IFRydWUsCiAgICAgICAgJ25vX3dhcm5pbmdzJzogVHJ1ZSwKICAg
:::ICAgICAnbm9wcm9ncmVzcyc6IFRydWUsCiAgICAgICAgJ25vcGxheWxpc3QnOiBU
:::cnVlLAogICAgICAgICdpZ25vcmVlcnJvcnMnOiBGYWxzZSwKICAgICAgICAncmV0
:::cmllcyc6IDEwLAogICAgICAgICdmcmFnbWVudF9yZXRyaWVzJzogMTAsCiAgICAg
:::ICAgJ3NvY2tldF90aW1lb3V0JzogMzAsCiAgICAgICAgJ2NvbmN1cnJlbnRfZnJh
:::Z21lbnRfZG93bmxvYWRzJzogNCwKICAgICAgICAnd2luZG93c2ZpbGVuYW1lcyc6
:::IFRydWUsCiAgICAgICAgJ292ZXJ3cml0ZXMnOiBGYWxzZSwKICAgICAgICAnbG9n
:::Z2VyJzogUkVHSVNUUk8sCiAgICAgICAgJ3Byb2dyZXNzX2hvb2tzJzogW3Byb2dy
:::ZXNvXSwKICAgICAgICAncG9zdHByb2Nlc3Nvcl9ob29rcyc6IFtwb3N0cHJvY2Vz
:::b10sCiAgICB9CiAgICBpZiBjb29raWVzIGFuZCBjb29raWVzICE9ICcobmluZ3Vu
:::byknOgogICAgICAgIG9bJ2Nvb2tpZXNmcm9tYnJvd3NlciddID0gKGNvb2tpZXMs
:::KQogICAgaWYgRkZNUEVHOgogICAgICAgIG9bJ2ZmbXBlZ19sb2NhdGlvbiddID0g
:::c3RyKEZGTVBFRy5wYXJlbnQpCiAgICByZXR1cm4gbwoKCmRlZiBjb252ZXJ0aXJf
:::ZmZtcGVnKGNtZCwgZXRpcXVldGEsIGNvbGEpOgogICAgIiIiRWplY3V0YSBGRm1w
:::ZWcgKGxpc3RhIGRlIGFyZ3VtZW50b3MsIHNpbiBzaGVsbCkgY29uIG1hcnF1ZWUu
:::IiIiCiAgICBjb2xhLnB1dCgoJ3Byb2cnLCBOb25lLCBldGlxdWV0YSkpCgogICAg
:::ZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBt
:::LCB0KSkKCiAgICB0cnk6CiAgICAgICAgcCA9IHN1YnByb2Nlc3MucnVuKGNtZCwg
:::c3Rkb3V0PXN1YnByb2Nlc3MuUElQRSwKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgc3RkZXJyPXN1YnByb2Nlc3MuUElQRSwgdGV4dD1UcnVlLAogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICBlbmNvZGluZz0ndXRmLTgnLCBlcnJvcnM9J3JlcGxh
:::Y2UnKQogICAgZXhjZXB0IEZpbGVOb3RGb3VuZEVycm9yOgogICAgICAgIHAgPSBO
:::b25lCiAgICBpZiBwIGlzIE5vbmUgb3IgcC5yZXR1cm5jb2RlICE9IDA6CiAgICAg
:::ICAgbG9nKCfinJYgRkZtcGVnIGRldm9sdmnDsyB1biBlcnJvcjonLCAnZXJyb3In
:::KQogICAgICAgIGlmIHAgaXMgbm90IE5vbmU6CiAgICAgICAgICAgIGZvciBsbiBp
:::biAocC5zdGRlcnIgb3IgJycpLnN0cmlwKCkuc3BsaXRsaW5lcygpWy00Ol06CiAg
:::ICAgICAgICAgICAgICBsb2coJyAgICcgKyBsbls6MTgwXSwgJ2dyaXMnKQogICAg
:::ICAgIGNvbGEucHV0KCgncHJvZycsIDAsICcnKSkKICAgICAgICByZXR1cm4gRmFs
:::c2UKICAgIHJldHVybiBUcnVlCgoKZGVmIGFyY2hpdm9fZmluYWwoaW5mbywgY2Fy
:::cGV0YSwgZXh0KToKICAgICIiIkxvY2FsaXphIGVsIGFyY2hpdm8gcmVzdWx0YW50
:::ZSAoeXQtZGxwIGxvIHJlcG9ydGE7IGZhbGxiYWNrOiBtw6FzIG51ZXZvKS4iIiIK
:::ICAgIHRyeToKICAgICAgICBmb3IgZCBpbiAoaW5mby5nZXQoJ3JlcXVlc3RlZF9k
:::b3dubG9hZHMnKSBvciBbXSk6CiAgICAgICAgICAgIGYgPSBkLmdldCgnZmlsZXBh
:::dGgnKQogICAgICAgICAgICBpZiBmOgogICAgICAgICAgICAgICAgcmV0dXJuIFBh
:::dGgoZikKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgcGFzcwogICAgY2Fu
:::ZCA9IHNvcnRlZChjYXJwZXRhLmdsb2IoJyouJyArIGV4dCksCiAgICAgICAgICAg
:::ICAgICAgIGtleT1sYW1iZGEgcDogcC5zdGF0KCkuc3RfbXRpbWUsIHJldmVyc2U9
:::VHJ1ZSkKICAgIHJldHVybiBjYW5kWzBdIGlmIGNhbmQgZWxzZSBOb25lCgoKZGVm
:::IGxpbXBpYXJfbWluaWF0dXJhcyhjYXJwZXRhLCBhcmNoaXZvKToKICAgICIiIkJv
:::cnJhIG1pbmlhdHVyYXMgc3VlbHRhcyBxdWUgRW1iZWRUaHVtYm5haWwgZGVqYXJh
:::IHNpbiBpbmNydXN0YXIuIiIiCiAgICBmb3IgZXh0IGluICgnLndlYnAnLCAnLmpw
:::ZycsICcuanBlZycsICcucG5nJyk6CiAgICAgICAgdCA9IGFyY2hpdm8ud2l0aF9z
:::dWZmaXgoZXh0KQogICAgICAgIGlmIHQuZXhpc3RzKCk6CiAgICAgICAgICAgIHRy
:::eToKICAgICAgICAgICAgICAgIHQudW5saW5rKCkKICAgICAgICAgICAgZXhjZXB0
:::IE9TRXJyb3I6CiAgICAgICAgICAgICAgICBwYXNzCgoKIyAtLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tIGRlc2NhcmdhcwpkZWYgZGVzY2FyZ2FyX2F1ZGlvKHVybCwgbm9tYnJlX2Zt
:::dCwgY2FsaWRhZCwgZGVzdGlubywgZW1iZWJlciwgY29va2llcywgY29sYSk6CiAg
:::ICAiIiJBQUMgKC5tNGEpIC8gTVAzIC8gRkxBQyAvIFdBViB2w61hIHBvc3Rwcm9j
:::ZXNhZG9yZXMgZGUgeXQtZGxwLiIiIgogICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6
:::CiAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICBmbXQgPSBGT1JN
:::QVRPU1tub21icmVfZm10XQogICAgY2FycGV0YSA9IGRlc3Rpbm8gLyBmbXRbJ2Nh
:::cnBldGEnXQogICAgY2FycGV0YS5ta2RpcihwYXJlbnRzPVRydWUsIGV4aXN0X29r
:::PVRydWUpCiAgICBjb2RlYyA9IGZtdFsnZXh0J10KICAgIGNvbl9wb3J0YWRhID0g
:::ZW1iZWJlciBhbmQgbm9tYnJlX2ZtdCBpbiAoJ0FBQycsICdNUDMnLCAnRkxBQycp
:::CiAgICBjb25fdGFncyA9IGVtYmViZXIKICAgIHBwcyA9IFt7J2tleSc6ICdGRm1w
:::ZWdFeHRyYWN0QXVkaW8nLCAncHJlZmVycmVkY29kZWMnOiBjb2RlYywKICAgICAg
:::ICAgICAgJ3ByZWZlcnJlZHF1YWxpdHknOiBjYWxpZGFkIG9yICcwJ31dCiAgICBp
:::ZiBjb25fdGFnczoKICAgICAgICBwcHMuYXBwZW5kKHsna2V5JzogJ0ZGbXBlZ01l
:::dGFkYXRhJywgJ2FkZF9tZXRhZGF0YSc6IFRydWV9KQogICAgaWYgY29uX3BvcnRh
:::ZGE6CiAgICAgICAgcHBzLmFwcGVuZCh7J2tleSc6ICdFbWJlZFRodW1ibmFpbCcs
:::CiAgICAgICAgICAgICAgICAgICAgJ2FscmVhZHlfaGF2ZV90aHVtYm5haWwnOiBG
:::YWxzZX0pCiAgICBvID0gb3B0c19iYXNlKGNhcnBldGEsIGNvb2tpZXMsIGNvbGEp
:::CiAgICBvWydmb3JtYXQnXSA9ICdiZXN0YXVkaW8vYmVzdCcKICAgIG9bJ3Bvc3Rw
:::cm9jZXNzb3JzJ10gPSBwcHMKICAgIG9bJ3dyaXRldGh1bWJuYWlsJ10gPSBjb25f
:::cG9ydGFkYQogICAgd2l0aCBZVF9ETFAuWW91dHViZURMKG8pIGFzIHlkbDoKICAg
:::ICAgICBpbmZvID0geWRsLmV4dHJhY3RfaW5mbyh1cmwsIGRvd25sb2FkPVRydWUp
:::CiAgICBhcmNoaXZvID0gYXJjaGl2b19maW5hbChpbmZvLCBjYXJwZXRhLCBjb2Rl
:::YykKICAgIGlmIGFyY2hpdm8gYW5kIGNvbl9wb3J0YWRhOgogICAgICAgIGxpbXBp
:::YXJfbWluaWF0dXJhcyhjYXJwZXRhLCBhcmNoaXZvKQogICAgcmV0dXJuIGluZm8s
:::IGFyY2hpdm8KCgpkZWYgZGVzY2FyZ2FyX3dtYSh1cmwsIGRlc3Rpbm8sIGVtYmVi
:::ZXIsIGNvb2tpZXMsIGNvbGEpOgogICAgIiIiV01BIDEyOCBrYnBzOiB5dC1kbHAg
:::bm8gc29wb3J0YSB3bWEsIGFzw60gcXVlIHNlIGJhamEgYSBXQVYgKGNvbgogICAg
:::ZXRpcXVldGFzKSB5IGx1ZWdvIEZGbXBlZyByZWNvZGlmaWNhIGEgd21hdjIgZGVu
:::dHJvIGRlbCAud21hIGZpbmFsLgogICAgKEVsIGNvbnRlbmVkb3IgQVNGIGRlIGZm
:::bXBlZyBubyBzb3BvcnRhIGNhcsOhdHVsYSBpbmNydXN0YWRhLikiIiIKICAgIGRl
:::ZiBsb2cobSwgdD0naW5mbycpOgogICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwg
:::dCkpCgogICAgY2FycGV0YSA9IGRlc3Rpbm8gLyAnV01BJwogICAgdG1wID0gY2Fy
:::cGV0YSAvICdfdG1wJwogICAgc2h1dGlsLnJtdHJlZSh0bXAsIGlnbm9yZV9lcnJv
:::cnM9VHJ1ZSkKICAgIHRtcC5ta2RpcihwYXJlbnRzPVRydWUsIGV4aXN0X29rPVRy
:::dWUpCiAgICBvID0gb3B0c19iYXNlKHRtcCwgY29va2llcywgY29sYSkKICAgIG9b
:::J2Zvcm1hdCddID0gJ2Jlc3RhdWRpby9iZXN0JwogICAgcHBzID0gW3sna2V5Jzog
:::J0ZGbXBlZ0V4dHJhY3RBdWRpbycsICdwcmVmZXJyZWRjb2RlYyc6ICd3YXYnLAog
:::ICAgICAgICAgICAncHJlZmVycmVkcXVhbGl0eSc6ICcwJ31dCiAgICBpZiBlbWJl
:::YmVyOgogICAgICAgIHBwcy5hcHBlbmQoeydrZXknOiAnRkZtcGVnTWV0YWRhdGEn
:::LCAnYWRkX21ldGFkYXRhJzogVHJ1ZX0pCiAgICBvWydwb3N0cHJvY2Vzc29ycydd
:::ID0gcHBzCiAgICB3aXRoIFlUX0RMUC5Zb3V0dWJlREwobykgYXMgeWRsOgogICAg
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
:::aXN0YSldCiAgICAgICAgbWV0YSArPSBbJy1tZXRhZGF0YScsICdhbGJ1bT1Zb3VU
:::dWJlJ10KICAgIHdtYSA9IGNhcnBldGEgLyAobGltcGlhcl9ub21icmUoaW5mby5n
:::ZXQoJ3RpdGxlJykgb3IgJ2F1ZGlvJykgKyAnLndtYScpCiAgICBjbWQgPSBbc3Ry
:::KEZGTVBFRyksICcteScsICctaScsIHN0cih3YXYpLCAnLXZuJywKICAgICAgICAg
:::ICAnLWM6YScsICd3bWF2MicsICctYjphJywgJzEyOGsnXSArIG1ldGEgKyBbc3Ry
:::KHdtYSldCiAgICBvayA9IGNvbnZlcnRpcl9mZm1wZWcoY21kLCAnQ29udmlydGll
:::bmRvIGEgV01BICh3bWF2MiDCtyAxMjgga2JwcyknLCBjb2xhKQogICAgaWYgbm90
:::IG9rOgogICAgICAgIHJhaXNlIFJ1bnRpbWVFcnJvcignRkZtcGVnIG5vIHB1ZG8g
:::Y3JlYXIgZWwgYXJjaGl2byBXTUEuJykKICAgIHNodXRpbC5ybXRyZWUodG1wLCBp
:::Z25vcmVfZXJyb3JzPVRydWUpCiAgICByZXR1cm4gaW5mbywgd21hCgoKIyBQYXLD
:::oW1ldHJvcyBvZmljaWFsZXMgZGVsIHJlcG8gZmRkNHMvcG9ydGFibGVfbXAzX3Bs
:::YXllcl92aWRlb19jb252ZXJ0ZXJfdG9vbHMKIyAodmlkZW8yc2hlbmp1MTguc2gp
:::OiBNSlBFRyAxNiBmcHMgKyBQQ00gMjIwNTAgSHosIHJvdGFkb3MgcGFyYSBsYSBw
:::YW50YWxsYQojIHZlcnRpY2FsIGRlIDEyOHgxNjAgZGVsIHJlcHJvZHVjdG9yIHNo
:::ZWlqdSBkZSAxLjggcHVsZ2FkYXMuClZGX1NIRUlKVSA9ICdzY2FsZT0tMjoxMjgs
:::IGNyb3A9MTYwOjEyOCwgdHJhbnNwb3NlPTIsIHZmbGlwJwojIFZhcmlhbnRlIGEg
:::cHJ1ZWJhIGRlIGJhbGFzIHBhcmEgdmlkZW9zIGN1YWRyYWRvcy92ZXJ0aWNhbGVz
:::IChTaG9ydHMpLAojIGRvbmRlIGVsIHJlY29ydGUgMTYwOjEyOCBvcmlnaW5hbCBz
:::ZXLDrWEgaW1wb3NpYmxlOgpWRl9TRUdVUk8gPSAoJ3NjYWxlPTE2MDoxMjg6Zm9y
:::Y2Vfb3JpZ2luYWxfYXNwZWN0X3JhdGlvPWRlY3JlYXNlLCcKICAgICAgICAgICAg
:::ICdwYWQ9MTYwOjEyODoob3ctaXcpLzI6KG9oLWloKS8yLHRyYW5zcG9zZT0yLHZm
:::bGlwJykKCgpkZWYgZGVzY2FyZ2FyX2F2aSh1cmwsIGRlc3Rpbm8sIGNvb2tpZXMs
:::IGNvbGEpOgogICAgIiIiVmlkZW8gQVZJIHBhcmEgZWwgcmVwcm9kdWN0b3Igc2hl
:::aWp1IDEuOCIgMTI4eDE2MC4iIiIKICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgog
:::ICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgY2FycGV0YSA9IGRl
:::c3Rpbm8gLyAnQVZJJwogICAgdG1wID0gY2FycGV0YSAvICdfdG1wJwogICAgc2h1
:::dGlsLnJtdHJlZSh0bXAsIGlnbm9yZV9lcnJvcnM9VHJ1ZSkKICAgIHRtcC5ta2Rp
:::cihwYXJlbnRzPVRydWUsIGV4aXN0X29rPVRydWUpCiAgICBvID0gb3B0c19iYXNl
:::KHRtcCwgY29va2llcywgY29sYSkKICAgICMgUGFyYSB1bmEgcGFudGFsbGEgZGUg
:::MTI4eDE2MCBiYXN0YSBjb24gNDgwcDogYWhvcnJhIG11Y2hhIGRlc2NhcmdhLgog
:::ICAgb1snZm9ybWF0J10gPSAoJ2Jlc3RbaGVpZ2h0PD00ODBdW2V4dD1tcDRdL2Jl
:::c3RbaGVpZ2h0PD00ODBdLycKICAgICAgICAgICAgICAgICAgICdidipbaGVpZ2h0
:::PD00ODBdK2JhL2InKQogICAgb1snbWVyZ2Vfb3V0cHV0X2Zvcm1hdCddID0gJ21w
:::NCcKICAgIHdpdGggWVRfRExQLllvdXR1YmVETChvKSBhcyB5ZGw6CiAgICAgICAg
:::aW5mbyA9IHlkbC5leHRyYWN0X2luZm8odXJsLCBkb3dubG9hZD1UcnVlKQogICAg
:::b3JpZ2VuID0gYXJjaGl2b19maW5hbChpbmZvLCB0bXAsICdtcDQnKQogICAgaWYg
:::bm90IG9yaWdlbjoKICAgICAgICBvcmlnZW4gPSAoYXJjaGl2b19maW5hbChpbmZv
:::LCB0bXAsICdta3YnKQogICAgICAgICAgICAgICAgICBvciBhcmNoaXZvX2ZpbmFs
:::KGluZm8sIHRtcCwgJ3dlYm0nKSkKICAgIGlmIG5vdCBvcmlnZW46CiAgICAgICAg
:::cmFpc2UgUnVudGltZUVycm9yKCdObyBzZSBlbmNvbnRyw7MgZWwgdmlkZW8gZGVz
:::Y2FyZ2Fkby4nKQogICAgYXZpID0gY2FycGV0YSAvIChsaW1waWFyX25vbWJyZShp
:::bmZvLmdldCgndGl0bGUnKSBvciAndmlkZW8nKSArICcuYXZpJykKICAgIGJhc2Ug
:::PSBbc3RyKEZGTVBFRyksICcteScsICctaScsIHN0cihvcmlnZW4pLCAnLXInLCAn
:::MTYnLAogICAgICAgICAgICAnLWFjb2RlYycsICdwY21fczE2bGUnLCAnLWFjJywg
:::JzInLCAnLWFyJywgJzIyMDUwJywKICAgICAgICAgICAgJy1waXhfZm10JywgJ3l1
:::dmo0MjBwJywgJy1jOnYnLCAnbWpwZWcnLCAnLXE6dicsICcyJ10KICAgIG9rID0g
:::Y29udmVydGlyX2ZmbXBlZyhiYXNlICsgWyctdmYnLCBWRl9TSEVJSlUsIHN0cihh
:::dmkpXSwKICAgICAgICAgICAgICAgICAgICAgICAgICAnQ29udmlydGllbmRvIGEg
:::QVZJIDEyOHgxNjAgKHNoZWlqdSAxLjgiKScsIGNvbGEpCiAgICBpZiBub3Qgb2s6
:::CiAgICAgICAgbG9nKCdWaWRlbyBjb24gcHJvcG9yY2nDs24gbm8gZXN0w6FuZGFy
:::OyAnCiAgICAgICAgICAgICdyZWludGVudGFuZG8gZW4gbW9kbyBjb21wYXRpYmxl
:::Li4uJywgJ2F2aXNvJykKICAgICAgICBvayA9IGNvbnZlcnRpcl9mZm1wZWcoYmFz
:::ZSArIFsnLXZmJywgVkZfU0VHVVJPLCBzdHIoYXZpKV0sCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICdSZWNvbnZpcnRpZW5kbyBhIEFWSSAxMjh4MTYwJywg
:::Y29sYSkKICAgIGlmIG5vdCBvazoKICAgICAgICByYWlzZSBSdW50aW1lRXJyb3Io
:::J0ZGbXBlZyBubyBwdWRvIGNyZWFyIGVsIGFyY2hpdm8gQVZJLicpCiAgICBzaHV0
:::aWwucm10cmVlKHRtcCwgaWdub3JlX2Vycm9ycz1UcnVlKQogICAgcmV0dXJuIGlu
:::Zm8sIGF2aQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBlc3RpbWFjacOzbgpLQlBTX0VT
:::VElNQURPUyA9IHsKICAgICdBQUMnOiAxMjgsICAgICAjIHRlY2hvIGRlbCBmb3Jt
:::YXRvCiAgICAnV01BJzogMTI4LAogICAgJ1dBVic6IDE0MTEsICAgICMgUENNIDQ0
:::LjEga0h6IMK3IDE2IGJpdCDCtyBlc3TDqXJlbwogICAgJ0ZMQUMnOiA5NTAsICAg
:::ICMgdMOtcGljbyBkZSBtw7pzaWNhIHByb2NlZGVudGUgZGUgWW91VHViZQogICAg
:::J0FWSSc6IDE0OTAsICAgICMgfjc4NCBrYnBzIE1KUEVHIDE2ZnBzICsgNzA2IGti
:::cHMgUENNIDIyMDUwIGVzdMOpcmVvCn0KCgpkZWYgZXN0aW1hcl9ieXRlcyhkdXJh
:::Y2lvbl9zLCBmb3JtYXRvLCBjYWxpZGFkLCBlbWJlYmVyKToKICAgICIiIkVzdGlt
:::YSBlbCB0YW1hw7FvIGZpbmFsIGVuIGJ5dGVzIChjw6FsY3VsbyBwdXJvLCB0ZXN0
:::ZWFibGUpLiIiIgogICAgaWYgZm9ybWF0byA9PSAnTVAzJzoKICAgICAgICBrYnBz
:::ID0gaW50KHJlLnN1YihyJ1teMC05XScsICcnLCBzdHIoY2FsaWRhZCkpIG9yIDMy
:::MCkKICAgIGVsc2U6CiAgICAgICAga2JwcyA9IEtCUFNfRVNUSU1BRE9TLmdldChm
:::b3JtYXRvLCAxMjgpCiAgICBleHRyYSA9IDEyMF8wMDAgaWYgKGVtYmViZXIgYW5k
:::IGZvcm1hdG8gaW4gKCdBQUMnLCAnTVAzJywgJ0ZMQUMnKSkgZWxzZSAwCiAgICBy
:::ZXR1cm4gZHVyYWNpb25fcyAqIGticHMgKiAxMDAwIC8gOCArIGV4dHJhCgoKIyAt
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tIGNhbGlkYWQKZGVmIGNsYXNlX2NhbGlkYWQoZXh0LCBr
:::YnBzKToKICAgICIiIkNsYXNpZmljYSB1biBhcmNoaXZvLiBEZXZ1ZWx2ZSAodGV4
:::dG8sIG5pdmVsKSBjb24gbml2ZWwgMD1vayAxPW1lZGlhIDI9YmFqYS4iIiIKICAg
:::IGlmIGV4dCA9PSAnLm1wMyc6CiAgICAgICAgaWYga2JwcyA+PSAzMTU6CiAgICAg
:::ICAgICAgIHJldHVybiAnMzIwIGticHMnLCAwCiAgICAgICAgaWYga2JwcyA+PSAy
:::NTA6CiAgICAgICAgICAgIHJldHVybiAnMjU2IGticHMnLCAwCiAgICAgICAgaWYg
:::a2JwcyA+PSAxODU6CiAgICAgICAgICAgIHJldHVybiAnMTkyIGticHMnLCAwCiAg
:::ICAgICAgaWYga2JwcyA+PSAxMjA6CiAgICAgICAgICAgIHJldHVybiAnMTI4IGti
:::cHMnLCAxCiAgICAgICAgcmV0dXJuIGYne2ticHN9IGticHMgKGJhamEpJywgMgog
:::ICAgaWYgZXh0ID09ICcubTRhJzoKICAgICAgICBpZiBrYnBzID49IDExNToKICAg
:::ICAgICAgICAgcmV0dXJuICdFeGNlbGVudGUgKEFBQyDiiaQxMjhrKScsIDAKICAg
:::ICAgICBpZiBrYnBzID49IDgwOgogICAgICAgICAgICByZXR1cm4gJ0J1ZW5hJywg
:::MQogICAgICAgIHJldHVybiBmJ3trYnBzfSBrYnBzIChiYWphKScsIDIKICAgIGlm
:::IGV4dCA9PSAnLndtYSc6CiAgICAgICAgaWYga2JwcyA+PSAxMTU6CiAgICAgICAg
:::ICAgIHJldHVybiAnMTI4IGticHMnLCAwCiAgICAgICAgaWYga2JwcyA+PSA5MDoK
:::ICAgICAgICAgICAgcmV0dXJuICdBY2VwdGFibGUnLCAxCiAgICAgICAgcmV0dXJu
:::IGYne2ticHN9IGticHMgKGJhamEpJywgMgogICAgaWYgZXh0IGluICgnLmZsYWMn
:::LCAnLndhdicpOgogICAgICAgIHJldHVybiAnU2luIHDDqXJkaWRhJywgMAogICAg
:::aWYgZXh0ID09ICcuYXZpJzoKICAgICAgICBpZiBrYnBzID49IDEyMDA6CiAgICAg
:::ICAgICAgIHJldHVybiBmJ3trYnBzfSBrYnBzIChNSlBFRytQQ00gMTI4eDE2MCkn
:::LCAwCiAgICAgICAgcmV0dXJuIGYne2ticHN9IGticHMgKGFsZ28gYmFqbyknLCAx
:::CiAgICByZXR1cm4gZid7a2Jwc30ga2JwcycsIDEKCgojIC0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0gdGVtYXMKVEVNQVMgPSB7CiAgICAnT3NjdXJvJzogZGljdCgKICAgICAgICBm
:::b25kbz0nIzFlMWYyMicsIGNhbXBvPScjMmEyZDMxJywgY2FtcG9fYm9yZGU9JyMz
:::YTNlNDQnLAogICAgICAgIHRleHRvPScjZDhkYWRjJywgdGV4dG8yPScjOWE5ZmE0
:::JywKICAgICAgICBib3Rvbj0nIzNhM2Q0MicsIGJvdG9uX2FjdD0nIzRhNGU1NScs
:::IGJvdG9uX3R4dD0nI2U4ZWFlYycsCiAgICAgICAgbG9nPScjMTQxNTE4JywgbG9n
:::X3R4dD0nI2NmZDNkNycsIGFjZW50bz0nIzRmOWNmOScsCiAgICAgICAgb2s9JyM3
:::ZWM5N2YnLCBlcnJvcj0nI2U1NzM3MycsIGF2aXNvPScjZDhiNjRhJywgdHJvdWdo
:::PScjMjYyODJjJywKICAgICAgICBwbGFjZWhvbGRlcj0nIzc3N2M4MicpLAogICAg
:::J0NsYXJvJzogZGljdCgKICAgICAgICBmb25kbz0nI2YyZjNmNScsIGNhbXBvPScj
:::ZmZmZmZmJywgY2FtcG9fYm9yZGU9JyNjNGM4Y2QnLAogICAgICAgIHRleHRvPScj
:::MjQyNzJhJywgdGV4dG8yPScjNmE3MDc2JywKICAgICAgICBib3Rvbj0nI2UzZTVl
:::OCcsIGJvdG9uX2FjdD0nI2QyZDVkYScsIGJvdG9uX3R4dD0nIzI0MjcyYScsCiAg
:::ICAgICAgbG9nPScjZmZmZmZmJywgbG9nX3R4dD0nIzJiMmUzMScsIGFjZW50bz0n
:::IzFhNjZkNicsCiAgICAgICAgb2s9JyMxZTdlMzQnLCBlcnJvcj0nI2M2MjgyOCcs
:::IGF2aXNvPScjOWE2NzAwJywgdHJvdWdoPScjZGZlMWU0JywKICAgICAgICBwbGFj
:::ZWhvbGRlcj0nIzlhYTBhNicpLAp9CgpOQVZFR0FET1JFUyA9IFsnKG5pbmd1bm8p
:::JywgJ2JyYXZlJywgJ2Nocm9tZScsICdjaHJvbWl1bScsICdlZGdlJywgJ2ZpcmVm
:::b3gnLAogICAgICAgICAgICAgICAnb3BlcmEnLCAnb3BlcmFfZ3gnLCAnc2FmYXJp
:::JywgJ3ZpdmFsZGknLCAnd2hhbGUnXQoKUExBQ0VIT0xERVJfVVJMID0gJ2h0dHBz
:::Oi8vd3d3LnlvdXR1YmUuY29tL3dhdGNoP3Y9Li4uJwoKRlVFTlRFX1VJID0gKCdT
:::ZWdvZSBVSScsIDkpCkZVRU5URV9CVE4gPSAoJ1NlZ29lIFVJJywgMTApCkZVRU5U
:::RV9CVE5fRyA9ICgnU2Vnb2UgVUknLCAxMSkKRlVFTlRFX0xPRyA9ICgnQ29uc29s
:::YXMnLCAxMCkKCgppZiBUS19PSzoKCiAgICBjbGFzcyBBcHAodGsuVGspOgogICAg
:::ICAgICIiIlZlbnRhbmEgcHJpbmNpcGFsIChkaXNlw7FvIGVzcGVqbyBkZWwgbW9j
:::a3VwOiBncnVwb3Mgb3NjdXJvcykuIiIiCgogICAgICAgICMgLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGNvbnN0cnVjY2nD
:::s24KICAgICAgICBkZWYgX19pbml0X18oc2VsZik6CiAgICAgICAgICAgIGlmIGdl
:::dGF0dHIoc3lzLCAnZnJvemVuJywgRmFsc2UpOgogICAgICAgICAgICAgICAgcGFz
:::cwogICAgICAgICAgICBzdXBlcigpLl9faW5pdF9fKCkKICAgICAgICAgICAgc2Vs
:::Zi50aXRsZSgnWW91VHViZSBEb3dubG9hZGVyJykKICAgICAgICAgICAgc2VsZi5n
:::ZW9tZXRyeSgnODYweDg0MCcpCiAgICAgICAgICAgIHNlbGYubWluc2l6ZSg3MDAs
:::IDY2MCkKICAgICAgICAgICAgc2VsZi5jb2xhID0gcXVldWUuUXVldWUoKQogICAg
:::ICAgICAgICBzZWxmLl9vY3VwYWRvID0gRmFsc2UKICAgICAgICAgICAgc2VsZi5f
:::ZW5fcGxhY2Vob2xkZXIgPSBUcnVlCiAgICAgICAgICAgIHNlbGYuX3RlbWFfYWN0
:::dWFsID0gQUpVU1RFUy5nZXQoJ3RlbWEnLCAnT3NjdXJvJykKICAgICAgICAgICAg
:::aWYgc2VsZi5fdGVtYV9hY3R1YWwgbm90IGluIFRFTUFTOgogICAgICAgICAgICAg
:::ICAgc2VsZi5fdGVtYV9hY3R1YWwgPSAnT3NjdXJvJwoKICAgICAgICAgICAgc2Vs
:::Zi5fZXN0aWxvID0gdHRrLlN0eWxlKHNlbGYpCiAgICAgICAgICAgIHRyeToKICAg
:::ICAgICAgICAgICAgIHNlbGYuX2VzdGlsby50aGVtZV91c2UoJ2NsYW0nKQogICAg
:::ICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICAgICAgcGFzcwoK
:::ICAgICAgICAgICAgc2VsZi5fY29uc3RydWlyKCkKICAgICAgICAgICAgc2VsZi5f
:::YXBsaWNhcl90ZW1hKCkKICAgICAgICAgICAgc2VsZi5fY29uZWN0YXJfZXZlbnRv
:::cygpCiAgICAgICAgICAgIFJFR0lTVFJPLmxvZyA9IGxhbWJkYSBtLCB0PSdhdmlz
:::byc6IHNlbGYuY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKICAgICAgICAgICAgc2Vs
:::Zi5hZnRlcig4MCwgc2VsZi5fYm9tYmVhcl9jb2xhKQogICAgICAgICAgICBzZWxm
:::LmFmdGVyKDE1MCwgc2VsZi5fYXJyYW5xdWUpCgogICAgICAgIGRlZiBfY29uc3Ry
:::dWlyKHNlbGYpOgogICAgICAgICAgICBzZWxmLl93ZyA9IHt9ICAgICAgICAgIyBy
:::ZWZlcmVuY2lhcyBwYXJhIGVsIHRlbWEKICAgICAgICAgICAgc2VsZi5fYnRucyA9
:::IFtdICAgICAgICMgYm90b25lcyBwbGFub3MgKHBhcmEgaG92ZXIvdGVtYSkKICAg
:::ICAgICAgICAgbWFyY28gPSB0ay5GcmFtZShzZWxmKQogICAgICAgICAgICBtYXJj
:::by5wYWNrKGZpbGw9J2JvdGgnLCBleHBhbmQ9VHJ1ZSwgcGFkeD0xMCwgcGFkeT04
:::KQogICAgICAgICAgICBzZWxmLl93Z1snbWFyY28nXSA9IG1hcmNvCiAgICAgICAg
:::ICAgIG1hcmNvLmNvbHVtbmNvbmZpZ3VyZSgwLCB3ZWlnaHQ9MSkKCiAgICAgICAg
:::ICAgICMgLS0tIGZpbGEgVGVtYSAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0KICAgICAgICAgICAgZjAgPSB0ay5GcmFtZSht
:::YXJjbykKICAgICAgICAgICAgZjAuZ3JpZChyb3c9MCwgY29sdW1uPTAsIHN0aWNr
:::eT0nZXcnLCBwYWR5PSgwLCA2KSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2YwJ10g
:::PSBmMAogICAgICAgICAgICBzZWxmLl93Z1snbGJsX3RlbWEnXSA9IHRrLkxhYmVs
:::KGYwLCB0ZXh0PSdUZW1hOicsIGZvbnQ9RlVFTlRFX1VJKQogICAgICAgICAgICBz
:::ZWxmLl93Z1snbGJsX3RlbWEnXS5wYWNrKHNpZGU9J2xlZnQnKQogICAgICAgICAg
:::ICBzZWxmLmNtYl90ZW1hID0gdHRrLkNvbWJvYm94KAogICAgICAgICAgICAgICAg
:::ZjAsIHZhbHVlcz1saXN0KFRFTUFTKSwgc3RhdGU9J3JlYWRvbmx5Jywgd2lkdGg9
:::OSwKICAgICAgICAgICAgICAgIGZvbnQ9RlVFTlRFX1VJLCBzdHlsZT0nZ3guVENv
:::bWJvYm94JykKICAgICAgICAgICAgc2VsZi5jbWJfdGVtYS5zZXQoc2VsZi5fdGVt
:::YV9hY3R1YWwpCiAgICAgICAgICAgIHNlbGYuY21iX3RlbWEucGFjayhzaWRlPSds
:::ZWZ0JywgcGFkeD0oOCwgMCksIGlwYWR5PTIpCgogICAgICAgICAgICAjIC0tLSBn
:::cnVwbzogVVJMIGRlIFlvdVR1YmUgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tCiAgICAgICAgICAgIGd1ID0gdGsuTGFiZWxGcmFtZShtYXJjbywg
:::dGV4dD0nVVJMIGRlIFlvdVR1YmUnLCBmb250PUZVRU5URV9VSSwKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgIHJlbGllZj0nc29saWQnLCBiZD0xKQogICAg
:::ICAgICAgICBndS5ncmlkKHJvdz0xLCBjb2x1bW49MCwgc3RpY2t5PSdldycsIHBh
:::ZHk9NSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2d1J10gPSBndQogICAgICAgICAg
:::ICBndS5jb2x1bW5jb25maWd1cmUoMCwgd2VpZ2h0PTEpCiAgICAgICAgICAgIHNl
:::bGYuZW50X3VybCA9IHRrLkVudHJ5KGd1LCBmb250PUZVRU5URV9VSSwgcmVsaWVm
:::PSdmbGF0JywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgaGln
:::aGxpZ2h0dGhpY2tuZXNzPTEpCiAgICAgICAgICAgIHNlbGYuZW50X3VybC5ncmlk
:::KHJvdz0wLCBjb2x1bW49MCwgc3RpY2t5PSdldycsCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIHBhZHg9OCwgcGFkeT04LCBpcGFkeT01KQogICAgICAgICAg
:::ICBzZWxmLl9wb25lcl9wbGFjZWhvbGRlcigpCiAgICAgICAgICAgIHNlbGYuYnRu
:::X3ggPSBzZWxmLl9ib3RvbihndSwgJ1gnLCBzZWxmLl9saW1waWFyX3VybCwgd2lk
:::dGg9MykKICAgICAgICAgICAgc2VsZi5idG5feC5ncmlkKHJvdz0wLCBjb2x1bW49
:::MSwgc3RpY2t5PSdlJywgcGFkeD0oMCwgOCksIGlwYWR5PTMpCgogICAgICAgICAg
:::ICAjIC0tLSBncnVwbzogRm9ybWF0byB5IGNhbGlkYWQgLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAgIGdmID0gdGsuTGFiZWxGcmFt
:::ZShtYXJjbywgdGV4dD0nRm9ybWF0byB5IGNhbGlkYWQnLCBmb250PUZVRU5URV9V
:::SSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlbGllZj0nc29saWQn
:::LCBiZD0xKQogICAgICAgICAgICBnZi5ncmlkKHJvdz0yLCBjb2x1bW49MCwgc3Rp
:::Y2t5PSdldycsIHBhZHk9NSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2dmJ10gPSBn
:::ZgogICAgICAgICAgICBnZi5jb2x1bW5jb25maWd1cmUoMSwgd2VpZ2h0PTEpCiAg
:::ICAgICAgICAgIHNlbGYuX3dnWydsYmxfZm10J10gPSB0ay5MYWJlbChnZiwgdGV4
:::dD0nRm9ybWF0bzonLCBmb250PUZVRU5URV9VSSkKICAgICAgICAgICAgc2VsZi5f
:::d2dbJ2xibF9mbXQnXS5ncmlkKHJvdz0wLCBjb2x1bW49MCwgc3RpY2t5PSd3Jywg
:::cGFkeD04LCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYuY21iX2Zvcm1hdG8gPSB0
:::dGsuQ29tYm9ib3goCiAgICAgICAgICAgICAgICBnZiwgdmFsdWVzPVtmWyd0ZXh0
:::byddIGZvciBmIGluIEZPUk1BVE9TLnZhbHVlcygpXSwKICAgICAgICAgICAgICAg
:::IHN0YXRlPSdyZWFkb25seScsIGZvbnQ9RlVFTlRFX1VJLCBzdHlsZT0nZ3guVENv
:::bWJvYm94JykKICAgICAgICAgICAgc2VsZi5jbWJfZm9ybWF0by5ncmlkKHJvdz0w
:::LCBjb2x1bW49MSwgc3RpY2t5PSdldycsCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICBwYWR4PTgsIHBhZHk9NSwgaXBhZHk9MikKICAgICAgICAgICAg
:::c2VsZi5fd2dbJ2xibF9jYWwnXSA9IHRrLkxhYmVsKGdmLCB0ZXh0PSdDYWxpZGFk
:::OicsIGZvbnQ9RlVFTlRFX1VJKQogICAgICAgICAgICBzZWxmLl93Z1snbGJsX2Nh
:::bCddLmdyaWQocm93PTEsIGNvbHVtbj0wLCBzdGlja3k9J3cnLCBwYWR4PTgsIHBh
:::ZHk9NSkKICAgICAgICAgICAgc2VsZi5jbWJfY2FsaWRhZCA9IHR0ay5Db21ib2Jv
:::eCgKICAgICAgICAgICAgICAgIGdmLCBzdGF0ZT0ncmVhZG9ubHknLCBmb250PUZV
:::RU5URV9VSSwgc3R5bGU9J2d4LlRDb21ib2JveCcpCiAgICAgICAgICAgIHNlbGYu
:::Y21iX2NhbGlkYWQuZ3JpZChyb3c9MSwgY29sdW1uPTEsIHN0aWNreT0nZXcnLAog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFkeD04LCBwYWR5PTUs
:::IGlwYWR5PTIpCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfY2FyJ10gPSB0ay5M
:::YWJlbChnZiwgdGV4dD0nQ2FycGV0YTonLCBmb250PUZVRU5URV9VSSkKICAgICAg
:::ICAgICAgc2VsZi5fd2dbJ2xibF9jYXInXS5ncmlkKHJvdz0yLCBjb2x1bW49MCwg
:::c3RpY2t5PSd3JywgcGFkeD04LCBwYWR5PTUpCiAgICAgICAgICAgIGZjID0gdGsu
:::RnJhbWUoZ2YpCiAgICAgICAgICAgIGZjLmdyaWQocm93PTIsIGNvbHVtbj0xLCBz
:::dGlja3k9J2V3JywgcGFkeD04LCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYuX3dn
:::WydmYyddID0gZmMKICAgICAgICAgICAgZmMuY29sdW1uY29uZmlndXJlKDAsIHdl
:::aWdodD0xKQogICAgICAgICAgICBzZWxmLmVudF9jYXJwZXRhID0gdGsuRW50cnko
:::ZmMsIGZvbnQ9RlVFTlRFX1VJLCByZWxpZWY9J2ZsYXQnLAogICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgaGlnaGxpZ2h0dGhpY2tuZXNzPTEp
:::CiAgICAgICAgICAgIHNlbGYuZW50X2NhcnBldGEuZ3JpZChyb3c9MCwgY29sdW1u
:::PTAsIHN0aWNreT0nZXcnLCBpcGFkeT00KQogICAgICAgICAgICBzZWxmLmVudF9j
:::YXJwZXRhLmluc2VydCgwLCBBSlVTVEVTWydkZXN0aW5vJ10pCiAgICAgICAgICAg
:::IHNlbGYuYnRuX2NhbWJpYXIgPSBzZWxmLl9ib3RvbihmYywgJ0NhbWJpYXIuLi4n
:::LCBzZWxmLl9jYW1iaWFyX2NhcnBldGEpCiAgICAgICAgICAgIHNlbGYuYnRuX2Nh
:::bWJpYXIuZ3JpZChyb3c9MCwgY29sdW1uPTEsIHBhZHg9KDgsIDApLCBpcGFkeT0z
:::KQogICAgICAgICAgICBzZWxmLmJ0bl9hYnJpciA9IHNlbGYuX2JvdG9uKGZjLCAn
:::QWJyaXInLCBzZWxmLl9hYnJpcl9kZXN0aW5vLCB3aWR0aD01KQogICAgICAgICAg
:::ICBzZWxmLmJ0bl9hYnJpci5ncmlkKHJvdz0wLCBjb2x1bW49MiwgcGFkeD0oNiwg
:::MCksIGlwYWR5PTMpCgogICAgICAgICAgICBzZWxmLnZhcl9lbWJlYmVyID0gdGsu
:::Qm9vbGVhblZhcih2YWx1ZT1ib29sKEFKVVNURVMuZ2V0KCdlbWJlYmVyJywgVHJ1
:::ZSkpKQogICAgICAgICAgICBzZWxmLmNoa19lbWJlYmVyID0gdGsuQ2hlY2tidXR0
:::b24oCiAgICAgICAgICAgICAgICBnZiwgdGV4dD0nRW1iZWJlciBjYXLDoXR1bGEs
:::IGFydGlzdGEgeSDDoWxidW0nLAogICAgICAgICAgICAgICAgdmFyaWFibGU9c2Vs
:::Zi52YXJfZW1iZWJlciwgZm9udD1GVUVOVEVfVUksIGFuY2hvcj0ndycsCiAgICAg
:::ICAgICAgICAgICByZWxpZWY9J2ZsYXQnLCBoaWdobGlnaHR0aGlja25lc3M9MCwg
:::YmQ9MCkKICAgICAgICAgICAgc2VsZi5jaGtfZW1iZWJlci5ncmlkKHJvdz0zLCBj
:::b2x1bW49MCwgY29sdW1uc3Bhbj0yLAogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgc3RpY2t5PSdldycsIHBhZHg9OCwgcGFkeT0oMiwgNikpCgogICAg
:::ICAgICAgICAjIC0tLSBncnVwbzogY29va2llcyAtLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAgIGdjID0gdGsuTGFi
:::ZWxGcmFtZSgKICAgICAgICAgICAgICAgIG1hcmNvLCB0ZXh0PSdOYXZlZ2Fkb3Ig
:::cGFyYSBjb29raWVzIChzb2xvIHNpIGVzIG5lY2VzYXJpbyknLAogICAgICAgICAg
:::ICAgICAgZm9udD1GVUVOVEVfVUksIHJlbGllZj0nc29saWQnLCBiZD0xKQogICAg
:::ICAgICAgICBnYy5ncmlkKHJvdz0zLCBjb2x1bW49MCwgc3RpY2t5PSdldycsIHBh
:::ZHk9NSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2djJ10gPSBnYwogICAgICAgICAg
:::ICBzZWxmLl93Z1snbGJsX25hdiddID0gdGsuTGFiZWwoZ2MsIHRleHQ9J05hdmVn
:::YWRvcjonLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICBmb250PUZVRU5URV9VSSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF9uYXYn
:::XS5wYWNrKHNpZGU9J2xlZnQnLCBwYWR4PTgsIHBhZHk9OCkKICAgICAgICAgICAg
:::c2VsZi5jbWJfbmF2ZWdhZG9yID0gdHRrLkNvbWJvYm94KAogICAgICAgICAgICAg
:::ICAgZ2MsIHZhbHVlcz1OQVZFR0FET1JFUywgc3RhdGU9J3JlYWRvbmx5Jywgd2lk
:::dGg9MTIsCiAgICAgICAgICAgICAgICBmb250PUZVRU5URV9VSSwgc3R5bGU9J2d4
:::LlRDb21ib2JveCcpCiAgICAgICAgICAgIG5hdiA9IEFKVVNURVMuZ2V0KCduYXZl
:::Z2Fkb3InLCAnKG5pbmd1bm8pJykKICAgICAgICAgICAgaWYgbmF2IG5vdCBpbiBO
:::QVZFR0FET1JFUzoKICAgICAgICAgICAgICAgIG5hdiA9ICcobmluZ3VubyknCiAg
:::ICAgICAgICAgIHNlbGYuY21iX25hdmVnYWRvci5zZXQobmF2KQogICAgICAgICAg
:::ICBzZWxmLmNtYl9uYXZlZ2Fkb3IucGFjayhzaWRlPSdsZWZ0JywgcGFkeD0oOCwg
:::MCksIGlwYWR5PTIpCgogICAgICAgICAgICAjIC0tLSBncnVwbzogZXN0aW1hY2nD
:::s24gLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAg
:::ICAgICAgICBnZSA9IHRrLkxhYmVsRnJhbWUobWFyY28sIHRleHQ9J0VzdGltYWNp
:::w7NuJywgZm9udD1GVUVOVEVfVUksCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICByZWxpZWY9J3NvbGlkJywgYmQ9MSkKICAgICAgICAgICAgZ2UuZ3JpZChy
:::b3c9NCwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PTUpCiAgICAgICAgICAg
:::IHNlbGYuX3dnWydnZSddID0gZ2UKICAgICAgICAgICAgZ2UuY29sdW1uY29uZmln
:::dXJlKDAsIHdlaWdodD0xKQogICAgICAgICAgICBzZWxmLmxibF9lc3RpbWFjaW9u
:::ID0gdGsuTGFiZWwoCiAgICAgICAgICAgICAgICBnZSwgdGV4dD0nSW50cm9kdWNl
:::IHVuYSBVUkwgeSBwdWxzYSBFc3RpbWFyLicsCiAgICAgICAgICAgICAgICBmb250
:::PUZVRU5URV9VSSwgYW5jaG9yPSd3JykKICAgICAgICAgICAgc2VsZi5sYmxfZXN0
:::aW1hY2lvbi5ncmlkKHJvdz0wLCBjb2x1bW49MCwgc3RpY2t5PSdldycsCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4PTgsIHBhZHk9NikK
:::ICAgICAgICAgICAgc2VsZi5idG5fZXN0aW1hciA9IHNlbGYuX2JvdG9uKGdlLCAn
:::RXN0aW1hciB0YW1hbm8nLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgc2VsZi5fYWNjaW9uX2VzdGltYXIpCiAgICAgICAgICAgIHNl
:::bGYuYnRuX2VzdGltYXIuZ3JpZChyb3c9MCwgY29sdW1uPTEsIHN0aWNreT0nZScs
:::CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4PTgsIGlwYWR5
:::PTMpCgogICAgICAgICAgICAjIC0tLSBib3RvbmVzIGdyYW5kZXMgLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAgIHNl
:::bGYuYnRuX2Rlc2NhcmdhciA9IHNlbGYuX2JvdG9uKG1hcmNvLCAnRGVzY2FyZ2Fy
:::IHkgY29udmVydGlyJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgc2VsZi5fYWNjaW9uX2Rlc2NhcmdhciwKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZnVlbnRlPUZVRU5URV9C
:::VE5fRywgYWx0bz0yKQogICAgICAgICAgICBzZWxmLmJ0bl9kZXNjYXJnYXIuZ3Jp
:::ZChyb3c9NSwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PSg3LCA0KSkKICAg
:::ICAgICAgICAgc2VsZi5idG5fY29tcHJvYmFyID0gc2VsZi5fYm90b24oCiAgICAg
:::ICAgICAgICAgICBtYXJjbywgJ0NvbXByb2JhciBjYWxpZGFkIGRlIGxhIGNhcnBl
:::dGEnLAogICAgICAgICAgICAgICAgc2VsZi5fYWNjaW9uX2NvbXByb2JhciwgZnVl
:::bnRlPUZVRU5URV9CVE4pCiAgICAgICAgICAgIHNlbGYuYnRuX2NvbXByb2Jhci5n
:::cmlkKHJvdz02LCBjb2x1bW49MCwgc3RpY2t5PSdldycsIHBhZHk9MykKCiAgICAg
:::ICAgICAgICMgLS0tIGVzdGFkbyArIGJhcnJhIGRlIHByb2dyZXNvIC0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAgIHNlbGYubGJsX2Vz
:::dGFkbyA9IHRrLkxhYmVsKG1hcmNvLCB0ZXh0PScnLCBmb250PUZVRU5URV9VSSwK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYW5jaG9yPSd3
:::JykKICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmdyaWQocm93PTcsIGNvbHVt
:::bj0wLCBzdGlja3k9J2V3JywgcGFkeT0oNCwgMCkpCiAgICAgICAgICAgIHNlbGYu
:::YmFycmEgPSB0dGsuUHJvZ3Jlc3NiYXIoCiAgICAgICAgICAgICAgICBtYXJjbywg
:::bWF4aW11bT0xMDAsIHN0eWxlPSdneC5Ib3Jpem9udGFsLlRQcm9ncmVzc2Jhcicp
:::CiAgICAgICAgICAgIHNlbGYuYmFycmEuZ3JpZChyb3c9OCwgY29sdW1uPTAsIHN0
:::aWNreT0nZXcnLCBwYWR5PSgyLCA0KSkKCiAgICAgICAgICAgICMgLS0tIHJlZ2lz
:::dHJvIChsb2cpIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tCiAgICAgICAgICAgIHNlbGYudHh0X2xvZyA9IFNjcm9sbGVkVGV4dCht
:::YXJjbywgZm9udD1GVUVOVEVfTE9HLCBoZWlnaHQ9MTIsCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICByZWxpZWY9J2ZsYXQnLCBiZD0wLCB3
:::cmFwPSd3b3JkJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIHN0YXRlPSdkaXNhYmxlZCcpCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5n
:::cmlkKHJvdz05LCBjb2x1bW49MCwgc3RpY2t5PSduc2V3JykKICAgICAgICAgICAg
:::bWFyY28ucm93Y29uZmlndXJlKDksIHdlaWdodD0xKQogICAgICAgICAgICBmb3Ig
:::dGFnLCBjb25mIGluICgKICAgICAgICAgICAgICAgICAgICAoJ2luZm8nLCB7fSks
:::CiAgICAgICAgICAgICAgICAgICAgKCdncmlzJywge30pLAogICAgICAgICAgICAg
:::ICAgICAgICgndGl0dWxvJywge30pLAogICAgICAgICAgICAgICAgICAgICgnb2sn
:::LCB7fSksCiAgICAgICAgICAgICAgICAgICAgKCdhdmlzbycsIHt9KSwKICAgICAg
:::ICAgICAgICAgICAgICAoJ2Vycm9yJywge30pKToKICAgICAgICAgICAgICAgIHNl
:::bGYudHh0X2xvZy50YWdfY29uZmlndXJlKHRhZywgY29uZikKCiAgICAgICAgICAg
:::ICMgc2luY3Jvbml6YXIgdmFsb3JlcyBndWFyZGFkb3MKICAgICAgICAgICAgZm10
:::ID0gQUpVU1RFUy5nZXQoJ2Zvcm1hdG8nLCAnQUFDJykKICAgICAgICAgICAgaWYg
:::Zm10IG5vdCBpbiBGT1JNQVRPUzoKICAgICAgICAgICAgICAgIGZtdCA9ICdBQUMn
:::CiAgICAgICAgICAgIHNlbGYuY21iX2Zvcm1hdG8uc2V0KEZPUk1BVE9TW2ZtdF1b
:::J3RleHRvJ10pCiAgICAgICAgICAgIHNlbGYuX3JlY2FyZ2FyX2NhbGlkYWRlcyhm
:::bXQsIEFKVVNURVMuZ2V0KCdjYWxpZGFkJykpCgogICAgICAgICMgLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGhlbHBlcnMg
:::d2lkZ2V0cwogICAgICAgIGRlZiBfYm90b24oc2VsZiwgcGFkcmUsIHRleHRvLCBj
:::bWQsIHdpZHRoPU5vbmUsIGZ1ZW50ZT1GVUVOVEVfQlROLAogICAgICAgICAgICAg
:::ICAgICAgYWx0bz0xKToKICAgICAgICAgICAgYiA9IHRrLkJ1dHRvbihwYWRyZSwg
:::dGV4dD10ZXh0bywgY29tbWFuZD1jbWQsIGZvbnQ9ZnVlbnRlLAogICAgICAgICAg
:::ICAgICAgICAgICAgICAgIHJlbGllZj0nZmxhdCcsIGJkPTAsIGN1cnNvcj0naGFu
:::ZDInLCBoZWlnaHQ9YWx0bywKICAgICAgICAgICAgICAgICAgICAgICAgICBhY3Rp
:::dmVmb3JlZ3JvdW5kPScjZmZmZmZmJywgdGFrZWZvY3VzPTApCiAgICAgICAgICAg
:::IGlmIHdpZHRoOgogICAgICAgICAgICAgICAgYi5jb25maWd1cmUod2lkdGg9d2lk
:::dGgpCiAgICAgICAgICAgIGIuYmluZCgnPEVudGVyPicsIGxhbWJkYSBlLCB3PWI6
:::IHcuY29uZmlndXJlKAogICAgICAgICAgICAgICAgYmc9VEVNQVNbc2VsZi5fdGVt
:::YV9hY3R1YWxdWydib3Rvbl9hY3QnXSkpCiAgICAgICAgICAgIGIuYmluZCgnPExl
:::YXZlPicsIGxhbWJkYSBlLCB3PWI6IHcuY29uZmlndXJlKAogICAgICAgICAgICAg
:::ICAgYmc9VEVNQVNbc2VsZi5fdGVtYV9hY3R1YWxdWydib3RvbiddKSkKICAgICAg
:::ICAgICAgc2VsZi5fYnRucy5hcHBlbmQoYikKICAgICAgICAgICAgcmV0dXJuIGIK
:::CiAgICAgICAgZGVmIF9wb25lcl9wbGFjZWhvbGRlcihzZWxmKToKICAgICAgICAg
:::ICAgaWYgbm90IHNlbGYuZW50X3VybC5nZXQoKToKICAgICAgICAgICAgICAgIHNl
:::bGYuX2VuX3BsYWNlaG9sZGVyID0gVHJ1ZQogICAgICAgICAgICAgICAgc2VsZi5l
:::bnRfdXJsLmluc2VydCgwLCBQTEFDRUhPTERFUl9VUkwpCgogICAgICAgIGRlZiBf
:::bGltcGlhcl91cmwoc2VsZik6CiAgICAgICAgICAgIHNlbGYuZW50X3VybC5kZWxl
:::dGUoMCwgJ2VuZCcpCiAgICAgICAgICAgIHNlbGYuZW50X3VybC5mb2N1c19zZXQo
:::KQoKICAgICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLSB0ZW1hCiAgICAgICAgZGVmIF9hcGxpY2FyX3RlbWEoc2Vs
:::Zik6CiAgICAgICAgICAgIHQgPSBURU1BU1tzZWxmLl90ZW1hX2FjdHVhbF0KICAg
:::ICAgICAgICAgdyA9IHNlbGYuX3dnCiAgICAgICAgICAgIHNlbGYuY29uZmlndXJl
:::KGJnPXRbJ2ZvbmRvJ10pCiAgICAgICAgICAgIGZvciBub21icmUgaW4gKCdtYXJj
:::bycsICdmMCcsICdndScsICdnZicsICdmYycsICdnYycsICdnZScpOgogICAgICAg
:::ICAgICAgICAgd1tub21icmVdLmNvbmZpZ3VyZShiZz10Wydmb25kbyddKQogICAg
:::ICAgICAgICBmb3IgbGYgaW4gKHdbJ2d1J10sIHdbJ2dmJ10sIHdbJ2djJ10sIHdb
:::J2dlJ10pOgogICAgICAgICAgICAgICAgbGYuY29uZmlndXJlKGJnPXRbJ2ZvbmRv
:::J10sIGZnPXRbJ3RleHRvMiddKQogICAgICAgICAgICBmb3Igbm9tYnJlIGluICgn
:::bGJsX3RlbWEnLCAnbGJsX2ZtdCcsICdsYmxfY2FsJywgJ2xibF9jYXInLAogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAnbGJsX25hdicpOgogICAgICAgICAgICAg
:::ICAgd1tub21icmVdLmNvbmZpZ3VyZShiZz10Wydmb25kbyddLCBmZz10Wyd0ZXh0
:::byddKQogICAgICAgICAgICBzZWxmLmxibF9lc3RpbWFjaW9uLmNvbmZpZ3VyZShi
:::Zz10Wydmb25kbyddLCBmZz10Wyd0ZXh0byddKQogICAgICAgICAgICBzZWxmLmxi
:::bF9lc3RhZG8uY29uZmlndXJlKGJnPXRbJ2ZvbmRvJ10sIGZnPXRbJ3RleHRvMidd
:::KQogICAgICAgICAgICBzZWxmLmVudF91cmwuY29uZmlndXJlKAogICAgICAgICAg
:::ICAgICAgYmc9dFsnY2FtcG8nXSwgZmc9dFsndGV4dG8nXSwgaW5zZXJ0YmFja2dy
:::b3VuZD10Wyd0ZXh0byddLAogICAgICAgICAgICAgICAgaGlnaGxpZ2h0YmFja2dy
:::b3VuZD10WydjYW1wb19ib3JkZSddLAogICAgICAgICAgICAgICAgaGlnaGxpZ2h0
:::Y29sb3I9dFsnYWNlbnRvJ10sCiAgICAgICAgICAgICAgICBkaXNhYmxlZGJhY2tn
:::cm91bmQ9dFsnY2FtcG8nXSwgZGlzYWJsZWRmb3JlZ3JvdW5kPXRbJ3RleHRvMidd
:::KQogICAgICAgICAgICBzZWxmLmVudF9jYXJwZXRhLmNvbmZpZ3VyZSgKICAgICAg
:::ICAgICAgICAgIGJnPXRbJ2NhbXBvJ10sIGZnPXRbJ3RleHRvJ10sIGluc2VydGJh
:::Y2tncm91bmQ9dFsndGV4dG8nXSwKICAgICAgICAgICAgICAgIGhpZ2hsaWdodGJh
:::Y2tncm91bmQ9dFsnY2FtcG9fYm9yZGUnXSwKICAgICAgICAgICAgICAgIGhpZ2hs
:::aWdodGNvbG9yPXRbJ2FjZW50byddKQogICAgICAgICAgICBzZWxmLmNoa19lbWJl
:::YmVyLmNvbmZpZ3VyZSgKICAgICAgICAgICAgICAgIGJnPXRbJ2ZvbmRvJ10sIGZn
:::PXRbJ3RleHRvJ10sIGFjdGl2ZWJhY2tncm91bmQ9dFsnZm9uZG8nXSwKICAgICAg
:::ICAgICAgICAgIGFjdGl2ZWZvcmVncm91bmQ9dFsndGV4dG8nXSwgc2VsZWN0Y29s
:::b3I9dFsnY2FtcG8nXSkKICAgICAgICAgICAgZm9yIGIgaW4gc2VsZi5fYnRuczoK
:::ICAgICAgICAgICAgICAgIGIuY29uZmlndXJlKGJnPXRbJ2JvdG9uJ10sIGZnPXRb
:::J2JvdG9uX3R4dCddLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgYWN0aXZl
:::YmFja2dyb3VuZD10Wydib3Rvbl9hY3QnXSwKICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgIGFjdGl2ZWZvcmVncm91bmQ9dFsnYm90b25fdHh0J10pCiAgICAgICAg
:::ICAgIHNlbGYudHh0X2xvZy5jb25maWd1cmUoYmc9dFsnbG9nJ10sIGZnPXRbJ2xv
:::Z190eHQnXSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBpbnNl
:::cnRiYWNrZ3JvdW5kPXRbJ2xvZ190eHQnXSkKICAgICAgICAgICAgc2VsZi50eHRf
:::bG9nLnRhZ19jb25maWd1cmUoJ2luZm8nLCBmb3JlZ3JvdW5kPXRbJ2xvZ190eHQn
:::XSkKICAgICAgICAgICAgc2VsZi50eHRfbG9nLnRhZ19jb25maWd1cmUoJ2dyaXMn
:::LCBmb3JlZ3JvdW5kPXRbJ3RleHRvMiddKQogICAgICAgICAgICBzZWxmLnR4dF9s
:::b2cudGFnX2NvbmZpZ3VyZSgndGl0dWxvJywgZm9yZWdyb3VuZD10Wyd0ZXh0bydd
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBmb250PSgn
:::Q29uc29sYXMnLCAxMCwgJ2JvbGQnKSkKICAgICAgICAgICAgc2VsZi50eHRfbG9n
:::LnRhZ19jb25maWd1cmUoJ29rJywgZm9yZWdyb3VuZD10WydvayddKQogICAgICAg
:::ICAgICBzZWxmLnR4dF9sb2cudGFnX2NvbmZpZ3VyZSgnYXZpc28nLCBmb3JlZ3Jv
:::dW5kPXRbJ2F2aXNvJ10pCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy50YWdfY29u
:::ZmlndXJlKCdlcnJvcicsIGZvcmVncm91bmQ9dFsnZXJyb3InXSkKICAgICAgICAg
:::ICAgZXN0ID0gc2VsZi5fZXN0aWxvCiAgICAgICAgICAgIGVzdC5jb25maWd1cmUo
:::J2d4LlRDb21ib2JveCcsCiAgICAgICAgICAgICAgICAgICAgICAgICAgZmllbGRi
:::YWNrZ3JvdW5kPXRbJ2NhbXBvJ10sIGJhY2tncm91bmQ9dFsnYm90b24nXSwKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICBmb3JlZ3JvdW5kPXRbJ3RleHRvJ10sIGFy
:::cm93Y29sb3I9dFsndGV4dG8nXSwKICAgICAgICAgICAgICAgICAgICAgICAgICBi
:::b3JkZXJjb2xvcj10WydjYW1wb19ib3JkZSddLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgIGxpZ2h0Y29sb3I9dFsnY2FtcG9fYm9yZGUnXSwKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICBkYXJrY29sb3I9dFsnY2FtcG9fYm9yZGUnXSwKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICBpbnNlcnRjb2xvcj10Wyd0ZXh0byddKQogICAg
:::ICAgICAgICBlc3QubWFwKCdneC5UQ29tYm9ib3gnLAogICAgICAgICAgICAgICAg
:::ICAgIGZpZWxkYmFja2dyb3VuZD1bKCdyZWFkb25seScsIHRbJ2NhbXBvJ10pXSwK
:::ICAgICAgICAgICAgICAgICAgICBmb3JlZ3JvdW5kPVsoJ3JlYWRvbmx5JywgdFsn
:::dGV4dG8nXSldKQogICAgICAgICAgICBlc3QuY29uZmlndXJlKCdneC5Ib3Jpem9u
:::dGFsLlRQcm9ncmVzc2JhcicsCiAgICAgICAgICAgICAgICAgICAgICAgICAgdHJv
:::dWdoY29sb3I9dFsndHJvdWdoJ10sIGJhY2tncm91bmQ9dFsnYWNlbnRvJ10sCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgYm9yZGVyY29sb3I9dFsnZm9uZG8nXSwg
:::bGlnaHRjb2xvcj10WydhY2VudG8nXSwKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICBkYXJrY29sb3I9dFsnYWNlbnRvJ10pCiAgICAgICAgICAgIHNlbGYub3B0aW9u
:::X2FkZCgnKlRDb21ib2JveCpMaXN0Ym94LmJhY2tncm91bmQnLCB0WydjYW1wbydd
:::KQogICAgICAgICAgICBzZWxmLm9wdGlvbl9hZGQoJypUQ29tYm9ib3gqTGlzdGJv
:::eC5mb3JlZ3JvdW5kJywgdFsndGV4dG8nXSkKICAgICAgICAgICAgc2VsZi5vcHRp
:::b25fYWRkKCcqVENvbWJvYm94Kkxpc3Rib3guc2VsZWN0QmFja2dyb3VuZCcsCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICB0Wydib3Rvbl9hY3QnXSkKICAgICAg
:::ICAgICAgc2VsZi5vcHRpb25fYWRkKCcqVENvbWJvYm94Kkxpc3Rib3guc2VsZWN0
:::Rm9yZWdyb3VuZCcsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0Wydib3Rv
:::bl90eHQnXSkKICAgICAgICAgICAgc2VsZi5fcmVmcmVzY2FyX3BsYWNlaG9sZGVy
:::KCkKCiAgICAgICAgZGVmIF9yZWZyZXNjYXJfcGxhY2Vob2xkZXIoc2VsZik6CiAg
:::ICAgICAgICAgIHQgPSBURU1BU1tzZWxmLl90ZW1hX2FjdHVhbF0KICAgICAgICAg
:::ICAgaWYgc2VsZi5fZW5fcGxhY2Vob2xkZXI6CiAgICAgICAgICAgICAgICBzZWxm
:::LmVudF91cmwuY29uZmlndXJlKGZnPXRbJ3BsYWNlaG9sZGVyJ10pCiAgICAgICAg
:::ICAgIGVsc2U6CiAgICAgICAgICAgICAgICBzZWxmLmVudF91cmwuY29uZmlndXJl
:::KGZnPXRbJ3RleHRvJ10pCgogICAgICAgICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGV2ZW50b3MKICAgICAgICBkZWYg
:::X2NvbmVjdGFyX2V2ZW50b3Moc2VsZik6CiAgICAgICAgICAgIHNlbGYuY21iX3Rl
:::bWEuYmluZCgnPDxDb21ib2JveFNlbGVjdGVkPj4nLCBzZWxmLl9vbl90ZW1hKQog
:::ICAgICAgICAgICBzZWxmLmNtYl9mb3JtYXRvLmJpbmQoJzw8Q29tYm9ib3hTZWxl
:::Y3RlZD4+Jywgc2VsZi5fb25fZm9ybWF0bykKICAgICAgICAgICAgc2VsZi5jbWJf
:::Y2FsaWRhZC5iaW5kKCc8PENvbWJvYm94U2VsZWN0ZWQ+PicsIGxhbWJkYSBlOiBz
:::ZWxmLl9ndWFyZGFyKCkpCiAgICAgICAgICAgIHNlbGYuY21iX25hdmVnYWRvci5i
:::aW5kKCc8PENvbWJvYm94U2VsZWN0ZWQ+PicsCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgIGxhbWJkYSBlOiBzZWxmLl9ndWFyZGFyKCkpCiAgICAg
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
:::QUpVU1RFU1snbmF2ZWdhZG9yJ10gPSBzZWxmLmNtYl9uYXZlZ2Fkb3IuZ2V0KCkK
:::ICAgICAgICAgICAgQUpVU1RFU1snZGVzdGlubyddID0gc2VsZi5lbnRfY2FycGV0
:::YS5nZXQoKS5zdHJpcCgpCiAgICAgICAgICAgIGd1YXJkYXJfYWp1c3RlcygpCgog
:::ICAgICAgIGRlZiBfb25fY2FycGV0YV9lc2NyaXRhKHNlbGYsIF9lPU5vbmUpOgog
:::ICAgICAgICAgICBwID0gUGF0aChvcy5wYXRoLmV4cGFuZHZhcnMoCiAgICAgICAg
:::ICAgICAgICBzZWxmLmVudF9jYXJwZXRhLmdldCgpLnN0cmlwKCkuc3RyaXAoJyIn
:::KSkpCiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHAubWtkaXIocGFy
:::ZW50cz1UcnVlLCBleGlzdF9vaz1UcnVlKQogICAgICAgICAgICAgICAgQUpVU1RF
:::U1snZGVzdGlubyddID0gc3RyKHApCiAgICAgICAgICAgICAgICBndWFyZGFyX2Fq
:::dXN0ZXMoKQogICAgICAgICAgICBleGNlcHQgT1NFcnJvciBhcyBlOgogICAgICAg
:::ICAgICAgICAgc2VsZi5fbG9nKGYnTm8gc2UgcHVkbyB1c2FyIGVzYSBjYXJwZXRh
:::OiB7ZX0nLCAnZXJyb3InKQoKICAgICAgICBkZWYgX2NhbWJpYXJfY2FycGV0YShz
:::ZWxmKToKICAgICAgICAgICAgYWN0dWFsID0gc2VsZi5lbnRfY2FycGV0YS5nZXQo
:::KS5zdHJpcCgpIG9yIEFKVVNURVNbJ2Rlc3Rpbm8nXQogICAgICAgICAgICBudWV2
:::YSA9IGZpbGVkaWFsb2cuYXNrZGlyZWN0b3J5KAogICAgICAgICAgICAgICAgdGl0
:::bGU9J0VsaWdlIGxhIGNhcnBldGEgZG9uZGUgZ3VhcmRhciBsYXMgZGVzY2FyZ2Fz
:::JywKICAgICAgICAgICAgICAgIGluaXRpYWxkaXI9YWN0dWFsIGlmIG9zLnBhdGgu
:::aXNkaXIoYWN0dWFsKSBlbHNlIHN0cihQYXRoLmhvbWUoKSkpCiAgICAgICAgICAg
:::IGlmIG5vdCBudWV2YToKICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAg
:::ICB0cnk6CiAgICAgICAgICAgICAgICBQYXRoKG51ZXZhKS5ta2RpcihwYXJlbnRz
:::PVRydWUsIGV4aXN0X29rPVRydWUpCiAgICAgICAgICAgIGV4Y2VwdCBPU0Vycm9y
:::IGFzIGU6CiAgICAgICAgICAgICAgICBtZXNzYWdlYm94LnNob3dlcnJvcignQ2Fy
:::cGV0YSBubyB2w6FsaWRhJywgc3RyKGUpKQogICAgICAgICAgICAgICAgcmV0dXJu
:::CiAgICAgICAgICAgIHNlbGYuZW50X2NhcnBldGEuZGVsZXRlKDAsICdlbmQnKQog
:::ICAgICAgICAgICBzZWxmLmVudF9jYXJwZXRhLmluc2VydCgwLCBudWV2YSkKICAg
:::ICAgICAgICAgQUpVU1RFU1snZGVzdGlubyddID0gbnVldmEKICAgICAgICAgICAg
:::Z3VhcmRhcl9hanVzdGVzKCkKICAgICAgICAgICAgc2VsZi5fbG9nKCdDYXJwZXRh
:::IGRlIGd1YXJkYWRvOiAnICsgbnVldmEsICdncmlzJykKCiAgICAgICAgZGVmIF9h
:::YnJpcl9kZXN0aW5vKHNlbGYpOgogICAgICAgICAgICBwID0gUGF0aChvcy5wYXRo
:::LmV4cGFuZHZhcnMoCiAgICAgICAgICAgICAgICBzZWxmLmVudF9jYXJwZXRhLmdl
:::dCgpLnN0cmlwKCkuc3RyaXAoJyInKSkpCiAgICAgICAgICAgIHRyeToKICAgICAg
:::ICAgICAgICAgIHAubWtkaXIocGFyZW50cz1UcnVlLCBleGlzdF9vaz1UcnVlKQog
:::ICAgICAgICAgICBleGNlcHQgT1NFcnJvcjoKICAgICAgICAgICAgICAgIHBhc3MK
:::ICAgICAgICAgICAgYWJyaXJfY2FycGV0YShwKQoKICAgICAgICBkZWYgX2FsX2Nl
:::cnJhcihzZWxmKToKICAgICAgICAgICAgaWYgc2VsZi5fb2N1cGFkbyBhbmQgbm90
:::IG1lc3NhZ2Vib3guYXNrb2tjYW5jZWwoCiAgICAgICAgICAgICAgICAgICAgJ1Nh
:::bGlyJywgJ0hheSB1bmEgdGFyZWEgZW4gY3Vyc28uICcKICAgICAgICAgICAgICAg
:::ICAgICAnwr9TZWd1cm8gcXVlIHF1aWVyZXMgc2FsaXI/Jyk6CiAgICAgICAgICAg
:::ICAgICByZXR1cm4KICAgICAgICAgICAgc2VsZi5kZXN0cm95KCkKCiAgICAgICAg
:::IyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0gcmVnaXN0cm8gKGxvZykKICAgICAgICBkZWYgX2xvZyhzZWxmLCBtc2csIHRh
:::Zz0naW5mbycpOgogICAgICAgICAgICBzZWxmLnR4dF9sb2cuY29uZmlndXJlKHN0
:::YXRlPSdub3JtYWwnKQogICAgICAgICAgICBuX2xpbmVhcyA9IGludChzZWxmLnR4
:::dF9sb2cuaW5kZXgoJ2VuZC0xYycpLnNwbGl0KCcuJylbMF0pCiAgICAgICAgICAg
:::IGlmIG5fbGluZWFzID4gOTAwOgogICAgICAgICAgICAgICAgc2VsZi50eHRfbG9n
:::LmRlbGV0ZSgnMS4wJywgJzIwMC4wJykKICAgICAgICAgICAgc2VsZi50eHRfbG9n
:::Lmluc2VydCgnZW5kJywgc3RyKG1zZykgKyAnXG4nLCB0YWcpCiAgICAgICAgICAg
:::IHNlbGYudHh0X2xvZy5zZWUoJ2VuZCcpCiAgICAgICAgICAgIHNlbGYudHh0X2xv
:::Zy5jb25maWd1cmUoc3RhdGU9J2Rpc2FibGVkJykKCiAgICAgICAgZGVmIF9saW1w
:::aWFyX2xvZyhzZWxmKToKICAgICAgICAgICAgc2VsZi50eHRfbG9nLmNvbmZpZ3Vy
:::ZShzdGF0ZT0nbm9ybWFsJykKICAgICAgICAgICAgc2VsZi50eHRfbG9nLmRlbGV0
:::ZSgnMS4wJywgJ2VuZCcpCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5jb25maWd1
:::cmUoc3RhdGU9J2Rpc2FibGVkJykKCiAgICAgICAgZGVmIF9ib21iZWFyX2NvbGEo
:::c2VsZik6CiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHdoaWxlIFRy
:::dWU6CiAgICAgICAgICAgICAgICAgICAgZXYgPSBzZWxmLmNvbGEuZ2V0X25vd2Fp
:::dCgpCiAgICAgICAgICAgICAgICAgICAgdGlwbyA9IGV2WzBdCiAgICAgICAgICAg
:::ICAgICAgICAgaWYgdGlwbyA9PSAnbG9nJzoKICAgICAgICAgICAgICAgICAgICAg
:::ICAgc2VsZi5fbG9nKGV2WzFdLCBldlsyXSkKICAgICAgICAgICAgICAgICAgICBl
:::bGlmIHRpcG8gPT0gJ3Byb2cnOgogICAgICAgICAgICAgICAgICAgICAgICBwY3Qs
:::IHRleHRvID0gZXZbMV0sIGV2WzJdCiAgICAgICAgICAgICAgICAgICAgICAgIGlm
:::IHBjdCBpcyBOb25lOgogICAgICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5i
:::YXJyYS5zdG9wKCkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYmFy
:::cmEuY29uZmlndXJlKG1vZGU9J2luZGV0ZXJtaW5hdGUnKQogICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgc2VsZi5iYXJyYS5zdGFydCg2MCkKICAgICAgICAgICAg
:::ICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNl
:::bGYuYmFycmEuc3RvcCgpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzZWxm
:::LmJhcnJhLmNvbmZpZ3VyZShtb2RlPSdkZXRlcm1pbmF0ZScpCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICBzZWxmLmJhcnJhLmNvbmZpZ3VyZSh2YWx1ZT1tYXgo
:::MCwgbWluKDEwMCwgcGN0KSkpCiAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYu
:::bGJsX2VzdGFkby5jb25maWd1cmUodGV4dD10ZXh0bykKICAgICAgICAgICAgICAg
:::ICAgICBlbGlmIHRpcG8gPT0gJ2VzdGltYWNpb24nOgogICAgICAgICAgICAgICAg
:::ICAgICAgICBzZWxmLmxibF9lc3RpbWFjaW9uLmNvbmZpZ3VyZSgKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgIHRleHQ9ZXZbMV0sIGZnPVRFTUFTW3NlbGYuX3Rl
:::bWFfYWN0dWFsXVsnYWNlbnRvJ10pCiAgICAgICAgICAgICAgICAgICAgZWxpZiB0
:::aXBvID09ICdmaW4nOgogICAgICAgICAgICAgICAgICAgICAgICBzZWxmLl9maW5f
:::dGFyZWEoZXZbMV0sIGV2WzJdLCBldlszXSBpZiBsZW4oZXYpID4gMyBlbHNlICcn
:::KQogICAgICAgICAgICBleGNlcHQgcXVldWUuRW1wdHk6CiAgICAgICAgICAgICAg
:::ICBwYXNzCiAgICAgICAgICAgIHNlbGYuYWZ0ZXIoODAsIHNlbGYuX2JvbWJlYXJf
:::Y29sYSkKCiAgICAgICAgIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0gdGFyZWFzCiAgICAgICAgZGVmIF9oYWJpbGl0YXJf
:::YWNjaW9uZXMoc2VsZiwgb24pOgogICAgICAgICAgICBlc3RhZG8gPSAnbm9ybWFs
:::JyBpZiBvbiBlbHNlICdkaXNhYmxlZCcKICAgICAgICAgICAgZm9yIGIgaW4gKHNl
:::bGYuYnRuX2Rlc2Nhcmdhciwgc2VsZi5idG5fY29tcHJvYmFyLAogICAgICAgICAg
:::ICAgICAgICAgICAgc2VsZi5idG5fZXN0aW1hciwgc2VsZi5idG5fY2FtYmlhciwg
:::c2VsZi5idG5fYWJyaXIsCiAgICAgICAgICAgICAgICAgICAgICBzZWxmLmJ0bl94
:::KToKICAgICAgICAgICAgICAgIGIuY29uZmlndXJlKHN0YXRlPWVzdGFkbywgY3Vy
:::c29yPSdoYW5kMicgaWYgb24gZWxzZSAnYXJyb3cnKQoKICAgICAgICBkZWYgX2lu
:::aWNpYXIoc2VsZiwgb2JqZXRpdm8sIGNmZywgdGV4dG8pOgogICAgICAgICAgICBp
:::ZiBzZWxmLl9vY3VwYWRvOgogICAgICAgICAgICAgICAgc2VsZi5fbG9nKCdZYSBo
:::YXkgdW5hIHRhcmVhIGVuIGN1cnNvOyBlc3BlcmEgYSBxdWUgdGVybWluZS4nLAog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICdhdmlzbycpCiAgICAgICAgICAgICAg
:::ICByZXR1cm4gRmFsc2UKICAgICAgICAgICAgc2VsZi5fb2N1cGFkbyA9IFRydWUK
:::ICAgICAgICAgICAgc2VsZi5faGFiaWxpdGFyX2FjY2lvbmVzKEZhbHNlKQogICAg
:::ICAgICAgICBzZWxmLmxibF9lc3RhZG8uY29uZmlndXJlKHRleHQ9dGV4dG8pCiAg
:::ICAgICAgICAgIHRocmVhZGluZy5UaHJlYWQodGFyZ2V0PW9iamV0aXZvLCBhcmdz
:::PShjZmcsKSwgZGFlbW9uPVRydWUpLnN0YXJ0KCkKICAgICAgICAgICAgcmV0dXJu
:::IFRydWUKCiAgICAgICAgZGVmIF9maW5fdGFyZWEoc2VsZiwgdGlwbywgb2ssIG1l
:::bnNhamU9JycpOgogICAgICAgICAgICBzZWxmLl9vY3VwYWRvID0gRmFsc2UKICAg
:::ICAgICAgICAgc2VsZi5faGFiaWxpdGFyX2FjY2lvbmVzKFRydWUpCiAgICAgICAg
:::ICAgIHNlbGYuYmFycmEuc3RvcCgpCiAgICAgICAgICAgIHNlbGYuYmFycmEuY29u
:::ZmlndXJlKG1vZGU9J2RldGVybWluYXRlJykKICAgICAgICAgICAgc2VsZi5iYXJy
:::YS5jb25maWd1cmUodmFsdWU9MCkKICAgICAgICAgICAgaWYgdGlwbyA9PSAnZGVz
:::Y2FyZ2EnIGFuZCBvazoKICAgICAgICAgICAgICAgIHNlbGYubGJsX2VzdGFkby5j
:::b25maWd1cmUodGV4dD0nTGlzdG8uJykKICAgICAgICAgICAgZWxpZiBub3Qgb2s6
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
:::ICAgICAgICByZXR1cm4gTm9uZQogICAgICAgICAgICB1LCBjYW1iaW8gPSBzaW5f
:::cGxheWxpc3QodSkKICAgICAgICAgICAgaWYgY2FtYmlvOgogICAgICAgICAgICAg
:::ICAgc2VsZi5fbG9nKCcoc2UgaWdub3JhcsOhIGxhIGxpc3RhIGRlIHJlcHJvZHVj
:::Y2nDs246ICcKICAgICAgICAgICAgICAgICAgICAgICAgICAnbW9kbyBzb2xvIHZp
:::ZGVvKScsICdncmlzJykKICAgICAgICAgICAgcmV0dXJuIHUKCiAgICAgICAgZGVm
:::IF9hY2Npb25fZXN0aW1hcihzZWxmKToKICAgICAgICAgICAgdXJsID0gc2VsZi5f
:::dXJsX3ZhbGlkYSgpCiAgICAgICAgICAgIGlmIG5vdCB1cmw6CiAgICAgICAgICAg
:::ICAgICByZXR1cm4KICAgICAgICAgICAgc2VsZi5fZ3VhcmRhcigpCiAgICAgICAg
:::ICAgIGNmZyA9IHsndXJsJzogdXJsfQogICAgICAgICAgICBzZWxmLl9pbmljaWFy
:::KHNlbGYuX2hpbG9fZXN0aW1hciwgY2ZnLCAnRXN0aW1hbmRvIHRhbWHDsW8uLi4n
:::KQogICAgICAgICAgICBzZWxmLmxibF9lc3RpbWFjaW9uLmNvbmZpZ3VyZSgKICAg
:::ICAgICAgICAgICAgIHRleHQ9J0NhbGN1bGFuZG8uLi4nLCBmZz1URU1BU1tzZWxm
:::Ll90ZW1hX2FjdHVhbF1bJ3RleHRvMiddKQoKICAgICAgICBkZWYgX2FjY2lvbl9k
:::ZXNjYXJnYXIoc2VsZik6CiAgICAgICAgICAgIHVybCA9IHNlbGYuX3VybF92YWxp
:::ZGEoKQogICAgICAgICAgICBpZiBub3QgdXJsOgogICAgICAgICAgICAgICAgcmV0
:::dXJuCiAgICAgICAgICAgIHNlbGYuX2d1YXJkYXIoKQogICAgICAgICAgICBjZmcg
:::PSB7J3VybCc6IHVybH0KICAgICAgICAgICAgc2VsZi5faW5pY2lhcihzZWxmLl9o
:::aWxvX2Rlc2NhcmdhciwgY2ZnLCAnRGVzY2FyZ2FuZG8uLi4nKQoKICAgICAgICBk
:::ZWYgX2FjY2lvbl9jb21wcm9iYXIoc2VsZik6CiAgICAgICAgICAgIHNlbGYuX2d1
:::YXJkYXIoKQogICAgICAgICAgICBzZWxmLl9pbmljaWFyKHNlbGYuX2hpbG9fY29t
:::cHJvYmFyLCB7fSwKICAgICAgICAgICAgICAgICAgICAgICAgICAnQ29tcHJvYmFu
:::ZG8gbGEgY2FycGV0YS4uLicpCgogICAgICAgIGRlZiBfYWNjaW9uX2FjdHVhbGl6
:::YXIoc2VsZik6CiAgICAgICAgICAgIGlmIG5vdCBZVF9ETFA6CiAgICAgICAgICAg
:::ICAgICBzZWxmLl9sb2coJ3l0LWRscCBubyBlc3TDoSBpbnN0YWxhZG87IGVqZWN1
:::dGEgJwogICAgICAgICAgICAgICAgICAgICAgICAgICdEZXNjYXJnYWRvck11c2lj
:::YS5iYXQuJywgJ2Vycm9yJykKICAgICAgICAgICAgICAgIHJldHVybgogICAgICAg
:::ICAgICBzZWxmLl9pbmljaWFyKHNlbGYuX2hpbG9fYWN0dWFsaXphciwge30sICdB
:::Y3R1YWxpemFuZG8geXQtZGxwLi4uJykKCiAgICAgICAgIyAtLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gaGlsb3MKICAgICAg
:::ICBkZWYgX2hpbG9fZXN0aW1hcihzZWxmLCBjZmcpOgogICAgICAgICAgICBjb2xh
:::ID0gc2VsZi5jb2xhCgogICAgICAgICAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToK
:::ICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgICAg
:::ICAgICB0cnk6CiAgICAgICAgICAgICAgICBpZiBZVF9ETFAgaXMgTm9uZToKICAg
:::ICAgICAgICAgICAgICAgICBsb2coJ3l0LWRscCBubyBlc3TDoSBpbnN0YWxhZG8u
:::IEVqZWN1dGEgJwogICAgICAgICAgICAgICAgICAgICAgICAnRGVzY2FyZ2Fkb3JN
:::dXNpY2EuYmF0IHBhcmEgaW5zdGFsYXJsby4nLCAnZXJyb3InKQogICAgICAgICAg
:::ICAgICAgICAgIGNvbGEucHV0KCgnZXN0aW1hY2lvbicsICd5dC1kbHAgbm8gZGlz
:::cG9uaWJsZScpKQogICAgICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAg
:::ICAgICAgbG9nKCdPYnRlbmllbmRvIGluZm9ybWFjacOzbiBkZWwgdmlkZW8uLi4n
:::LCAnZ3JpcycpCiAgICAgICAgICAgICAgICBvID0geydxdWlldCc6IFRydWUsICdu
:::b193YXJuaW5ncyc6IFRydWUsICdub3BsYXlsaXN0JzogVHJ1ZSwKICAgICAgICAg
:::ICAgICAgICAgICAgJ3NvY2tldF90aW1lb3V0JzogMzAsICdsb2dnZXInOiBSRUdJ
:::U1RST30KICAgICAgICAgICAgICAgIG5hdiA9IEFKVVNURVMuZ2V0KCduYXZlZ2Fk
:::b3InLCAnKG5pbmd1bm8pJykKICAgICAgICAgICAgICAgIGlmIG5hdiAhPSAnKG5p
:::bmd1bm8pJzoKICAgICAgICAgICAgICAgICAgICBvWydjb29raWVzZnJvbWJyb3dz
:::ZXInXSA9IChuYXYsKQogICAgICAgICAgICAgICAgd2l0aCBZVF9ETFAuWW91dHVi
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
:::ICAgICBkZWYgX2hpbG9fZGVzY2FyZ2FyKHNlbGYsIGNmZyk6CiAgICAgICAgICAg
:::IGNvbGEgPSBzZWxmLmNvbGEKCiAgICAgICAgICAgIGRlZiBsb2cobSwgdD0naW5m
:::bycpOgogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAg
:::ICAgICAgICAgIHVybCA9IGNmZ1sndXJsJ10KICAgICAgICAgICAgY2xhdmUgPSBz
:::ZWxmLl9mbXRfYWN0dWFsX3NvbG8oQUpVU1RFUy5nZXQoJ2Zvcm1hdG8nLCAnQUFD
:::JykpCiAgICAgICAgICAgIGNhbGlkYWQgPSBBSlVTVEVTLmdldCgnY2FsaWRhZCcs
:::ICcxMjhrJykKICAgICAgICAgICAgZW1iZWJlciA9IGJvb2woQUpVU1RFUy5nZXQo
:::J2VtYmViZXInLCBUcnVlKSkKICAgICAgICAgICAgbmF2ID0gQUpVU1RFUy5nZXQo
:::J25hdmVnYWRvcicsICcobmluZ3VubyknKQogICAgICAgICAgICBkZXN0aW5vID0g
:::UGF0aChvcy5wYXRoLmV4cGFuZHZhcnMoCiAgICAgICAgICAgICAgICBzdHIoQUpV
:::U1RFUy5nZXQoJ2Rlc3Rpbm8nLCBfZGVzdGlub19wb3JfZGVmZWN0bygpKSkpKQog
:::ICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBkZXN0aW5vLm1rZGlyKHBh
:::cmVudHM9VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgICAgICAgICAgICAgIGNhbGlk
:::YWRfYXJnID0geydBQUMnOiAnMTI4JywgJ0ZMQUMnOiAnMCcsCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAnV0FWJzogJzAnfS5nZXQoY2xhdmUpIG9yIFwK
:::ICAgICAgICAgICAgICAgICAgICByZS5zdWIocidbXjAtOV0nLCAnJywgY2FsaWRh
:::ZCkgb3IgJzMyMCcKICAgICAgICAgICAgICAgIGlmIGNsYXZlID09ICdXTUEnOgog
:::ICAgICAgICAgICAgICAgICAgIGluZm8sIGFyY2hpdm8gPSBkZXNjYXJnYXJfd21h
:::KHVybCwgZGVzdGlubywgZW1iZWJlciwKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBuYXYsIGNvbGEpCiAgICAgICAgICAg
:::ICAgICBlbGlmIGNsYXZlID09ICdBVkknOgogICAgICAgICAgICAgICAgICAgIGlu
:::Zm8sIGFyY2hpdm8gPSBkZXNjYXJnYXJfYXZpKHVybCwgZGVzdGlubywgbmF2LCBj
:::b2xhKQogICAgICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgICAgICBp
:::bmZvLCBhcmNoaXZvID0gZGVzY2FyZ2FyX2F1ZGlvKHVybCwgY2xhdmUsIGNhbGlk
:::YWRfYXJnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgZGVzdGlubywgZW1iZWJlciwgbmF2LAogICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sYSkKICAg
:::ICAgICAgICAgICAgIGlmIGFyY2hpdm8gYW5kIFBhdGgoYXJjaGl2bykuZXhpc3Rz
:::KCk6CiAgICAgICAgICAgICAgICAgICAgYXJjaGl2byA9IFBhdGgoYXJjaGl2bykK
:::ICAgICAgICAgICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICAgICAgICAg
:::IHRhbSA9IGZtdF90YW0oYXJjaGl2by5zdGF0KCkuc3Rfc2l6ZSkKICAgICAgICAg
:::ICAgICAgICAgICBleGNlcHQgT1NFcnJvcjoKICAgICAgICAgICAgICAgICAgICAg
:::ICAgdGFtID0gJz8nCiAgICAgICAgICAgICAgICAgICAgbG9nKGYn4pyUIMKhTGlz
:::dG8hICB7YXJjaGl2by5uYW1lfSAgKHt0YW19KScsICdvaycpCiAgICAgICAgICAg
:::ICAgICAgICAgbG9nKGYnQ2FycGV0YToge2FyY2hpdm8ucGFyZW50fScsICdncmlz
:::JykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdkZXNjYXJn
:::YScsIFRydWUsICcnKSkKICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAg
:::ICAgICAgICAgbG9nKCdFbCBhcmNoaXZvIGZpbmFsIG5vIGFwYXJlY2nDsyBkb25k
:::ZSBzZSBlc3BlcmFiYS4nLAogICAgICAgICAgICAgICAgICAgICAgICAnZXJyb3In
:::KQogICAgICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2Rlc2Nhcmdh
:::JywgRmFsc2UsICcnKSkKICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBl
:::OgogICAgICAgICAgICAgICAgbm9tYnJlX2V4YyA9IHR5cGUoZSkuX19uYW1lX18K
:::ICAgICAgICAgICAgICAgIGlmIG5vbWJyZV9leGMgPT0gJ0Rvd25sb2FkRXJyb3In
:::OgogICAgICAgICAgICAgICAgICAgIGxpbmVhcyA9IFtsIGZvciBsIGluIHN0cihl
:::KS5zdHJpcCgpLnNwbGl0bGluZXMoKSBpZiBsLnN0cmlwKCldCiAgICAgICAgICAg
:::ICAgICAgICAgbXNnID0gbGluZWFzWzBdWzozMDBdIGlmIGxpbmVhcyBlbHNlICdl
:::cnJvciBkZXNjb25vY2lkbycKICAgICAgICAgICAgICAgICAgICBsb2coJ+KcliBO
:::byBzZSBwdWRvIGRlc2NhcmdhcjogJyArIG1zZywgJ2Vycm9yJykKICAgICAgICAg
:::ICAgICAgICAgICBsb2coJ0NvbnNlam9zOiByZXZpc2EgbGEgVVJMIHkgdHUgY29u
:::ZXhpw7NuOyBzaSBZb3VUdWJlICcKICAgICAgICAgICAgICAgICAgICAgICAgJ2Nh
:::bWJpw7MgYWxnbywgcHVsc2EgQ3RybCtVIChhY3R1YWxpemFyIHl0LWRscCkgeSAn
:::CiAgICAgICAgICAgICAgICAgICAgICAgICdyZWludGVudGEuJywgJ2dyaXMnKQog
:::ICAgICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgICAgICBsb2coZifi
:::nJYgRXJyb3IgaW5lc3BlcmFkbyAoe25vbWJyZV9leGN9KToge2V9JywgJ2Vycm9y
:::JykKICAgICAgICAgICAgICAgICAgICB0YiA9IHRyYWNlYmFjay5mb3JtYXRfZXhj
:::KGxpbWl0PTMpCiAgICAgICAgICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAg
:::ICAgICAgICAgICB3aXRoIG9wZW4oTE9HX0VSUk9SRVMsICdhJywgZW5jb2Rpbmc9
:::J3V0Zi04JykgYXMgZmg6CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBmaC53
:::cml0ZSh0YiArICdcbicpCiAgICAgICAgICAgICAgICAgICAgZXhjZXB0IEV4Y2Vw
:::dGlvbjoKICAgICAgICAgICAgICAgICAgICAgICAgcGFzcwogICAgICAgICAgICAg
:::ICAgY29sYS5wdXQoKCdmaW4nLCAnZGVzY2FyZ2EnLCBGYWxzZSwKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAnTm8gc2UgcHVkbyBjb21wbGV0YXIgbGEgZGVzY2Fy
:::Z2EuIFJldmlzYSBlbCAnCiAgICAgICAgICAgICAgICAgICAgICAgICAgJ3JlZ2lz
:::dHJvIHBhcmEgbcOhcyBkZXRhbGxlcy4nKSkKCiAgICAgICAgZGVmIF9oaWxvX2Nv
:::bXByb2JhcihzZWxmLCBjZmcpOgogICAgICAgICAgICBjb2xhID0gc2VsZi5jb2xh
:::CgogICAgICAgICAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAgICAgICAg
:::ICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgICAgICAgICBjYXJwZXRh
:::ID0gUGF0aChvcy5wYXRoLmV4cGFuZHZhcnMoCiAgICAgICAgICAgICAgICBzdHIo
:::QUpVU1RFUy5nZXQoJ2Rlc3Rpbm8nLCBfZGVzdGlub19wb3JfZGVmZWN0bygpKSkp
:::KQogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBpZiBub3QgY2FycGV0
:::YS5pc19kaXIoKToKICAgICAgICAgICAgICAgICAgICBsb2coZidMYSBjYXJwZXRh
:::IHRvZGF2w61hIG5vIGV4aXN0ZToge2NhcnBldGF9JywgJ2F2aXNvJykKICAgICAg
:::ICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdjb21wcm9iYWNpb24nLCBU
:::cnVlLCAnJykpCiAgICAgICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAg
:::ICAgICBpZiBGRlBST0JFIGlzIE5vbmU6CiAgICAgICAgICAgICAgICAgICAgbG9n
:::KCdmZnByb2JlIG5vIGVzdMOhIGRpc3BvbmlibGUgKHZpZW5lIGNvbiBGRm1wZWcp
:::LiAnCiAgICAgICAgICAgICAgICAgICAgICAgICdFamVjdXRhIERlc2NhcmdhZG9y
:::TXVzaWNhLmJhdCBwYXJhIGluc3RhbGFybG8uJywKICAgICAgICAgICAgICAgICAg
:::ICAgICAgJ2Vycm9yJykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2Zp
:::bicsICdjb21wcm9iYWNpb24nLCBUcnVlLCAnJykpCiAgICAgICAgICAgICAgICAg
:::ICAgcmV0dXJuCiAgICAgICAgICAgICAgICBleHRzID0gKCcubTRhJywgJy5tcDMn
:::LCAnLmZsYWMnLCAnLndhdicsICcud21hJywgJy5hdmknKQogICAgICAgICAgICAg
:::ICAgYXJjaGl2b3MgPSBbcCBmb3IgcCBpbiBzb3J0ZWQoY2FycGV0YS5yZ2xvYign
:::KicpKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgaWYgcC5pc19maWxlKCkg
:::YW5kIHAuc3VmZml4Lmxvd2VyKCkgaW4gZXh0cwogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgYW5kICdfdG1wJyBub3QgaW4gcC5wYXJ0c10KICAgICAgICAgICAg
:::ICAgIGxvZyhmJ0NvbXByb2JhbmRvIHtsZW4oYXJjaGl2b3MpfSBhcmNoaXZvKHMp
:::IGVuICcKICAgICAgICAgICAgICAgICAgICBmJ3tjYXJwZXRhfSAuLi4nLCAndGl0
:::dWxvJykKICAgICAgICAgICAgICAgIGlmIG5vdCBhcmNoaXZvczoKICAgICAgICAg
:::ICAgICAgICAgICBsb2coJ05vIGhheSBhcmNoaXZvcyBkZSBhdWRpbyBvIHZpZGVv
:::IHRvZGF2w61hLicsICdncmlzJykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1
:::dCgoJ2ZpbicsICdjb21wcm9iYWNpb24nLCBUcnVlLCAnJykpCiAgICAgICAgICAg
:::ICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgICAgICB0b3RhbCA9IDAKICAgICAg
:::ICAgICAgICAgIGJhamFzID0gMAogICAgICAgICAgICAgICAgZm9yIHAgaW4gYXJj
:::aGl2b3M6CiAgICAgICAgICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAg
:::ICAgICAgICByID0gc3VicHJvY2Vzcy5ydW4oCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICBbc3RyKEZGUFJPQkUpLCAnLXYnLCAnZXJyb3InLCAnLXNob3dfZW50
:::cmllcycsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2Zvcm1hdD1iaXRf
:::cmF0ZSxkdXJhdGlvbixzaXplJywgJy1vZicsICdqc29uJywKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICBzdHIocCldLAogICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgc3Rkb3V0PXN1YnByb2Nlc3MuUElQRSwgc3RkZXJyPXN1YnByb2Nlc3Mu
:::UElQRSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRleHQ9VHJ1ZSwgZW5j
:::b2Rpbmc9J3V0Zi04JywgZXJyb3JzPSdyZXBsYWNlJywKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIHRpbWVvdXQ9MzApCiAgICAgICAgICAgICAgICAgICAgICAg
:::IGRhdG9zID0ganNvbi5sb2FkcyhyLnN0ZG91dCBvciAne30nKS5nZXQoJ2Zvcm1h
:::dCcsIHt9KQogICAgICAgICAgICAgICAgICAgICAgICBrYnBzID0gaW50KGZsb2F0
:::KGRhdG9zLmdldCgnYml0X3JhdGUnKSBvciAwKSAvIDEwMDApCiAgICAgICAgICAg
:::ICAgICAgICAgICAgIGR1ciA9IGZsb2F0KGRhdG9zLmdldCgnZHVyYXRpb24nKSBv
:::ciAwKQogICAgICAgICAgICAgICAgICAgICAgICB0YW0gPSBpbnQoZmxvYXQoZGF0
:::b3MuZ2V0KCdzaXplJykgb3IgMCkpCiAgICAgICAgICAgICAgICAgICAgZXhjZXB0
:::IEV4Y2VwdGlvbjoKICAgICAgICAgICAgICAgICAgICAgICAgbG9nKGYnwrcge3Au
:::bmFtZVs6NjBdfSDigJQgbm8gc2UgcHVkbyBsZWVyJywgJ2F2aXNvJykKICAgICAg
:::ICAgICAgICAgICAgICAgICAgY29udGludWUKICAgICAgICAgICAgICAgICAgICB0
:::b3RhbCArPSB0YW0KICAgICAgICAgICAgICAgICAgICB0ZXh0bywgbml2ZWwgPSBj
:::bGFzZV9jYWxpZGFkKHAuc3VmZml4Lmxvd2VyKCksIGticHMpCiAgICAgICAgICAg
:::ICAgICAgICAgaWYgbml2ZWwgPT0gMjoKICAgICAgICAgICAgICAgICAgICAgICAg
:::YmFqYXMgKz0gMQogICAgICAgICAgICAgICAgICAgIHRhZyA9ICgnb2snIGlmIG5p
:::dmVsID09IDAKICAgICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSAoJ2F2aXNv
:::JyBpZiBuaXZlbCA9PSAxIGVsc2UgJ2Vycm9yJykpCiAgICAgICAgICAgICAgICAg
:::ICAgbG9nKGYnwrcge3AubmFtZVs6NThdfSDigJQge3RleHRvfSDCtyB7Zm10X3Rp
:::ZW0oZHVyKX0gwrcgJwogICAgICAgICAgICAgICAgICAgICAgICBmJ3tmbXRfdGFt
:::KHRhbSl9JywgdGFnKQogICAgICAgICAgICAgICAgbG9nKGYnUmVzdWx0YWRvOiB7
:::bGVuKGFyY2hpdm9zKX0gYXJjaGl2byhzKSDCtyAnCiAgICAgICAgICAgICAgICAg
:::ICAgZid7Zm10X3RhbSh0b3RhbCl9IGVuIHRvdGFsIMK3IHtiYWphc30gY29uIGNh
:::bGlkYWQgYmFqYScsCiAgICAgICAgICAgICAgICAgICAgJ3RpdHVsbycpCiAgICAg
:::ICAgICAgICAgICBpZiBiYWphczoKICAgICAgICAgICAgICAgICAgICBsb2coJ0Nv
:::bnNlam86IGxvcyBhcmNoaXZvcyBtYXJjYWRvcyBlbiByb2pvIHNlIHB1ZWRlbiAn
:::CiAgICAgICAgICAgICAgICAgICAgICAgICd2b2x2ZXIgYSBkZXNjYXJnYXIgY29u
:::IG3DoXMgYml0cmF0ZS4nLCAnZ3JpcycpCiAgICAgICAgICAgIGV4Y2VwdCBFeGNl
:::cHRpb24gYXMgZToKICAgICAgICAgICAgICAgIGxvZyhmJ0Vycm9yIGFsIGNvbXBy
:::b2JhciBsYSBjYXJwZXRhOiB7ZX0nLCAnZXJyb3InKQogICAgICAgICAgICBmaW5h
:::bGx5OgogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnY29tcHJvYmFj
:::aW9uJywgVHJ1ZSwgJycpKQoKICAgICAgICBkZWYgX2hpbG9fYWN0dWFsaXphcihz
:::ZWxmLCBjZmcpOgogICAgICAgICAgICBjb2xhID0gc2VsZi5jb2xhCgogICAgICAg
:::ICAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAgICAgICAgICAgIGNvbGEu
:::cHV0KCgnbG9nJywgbSwgdCkpCgogICAgICAgICAgICB0cnk6CiAgICAgICAgICAg
:::ICAgICBsb2coJ0FjdHVhbGl6YW5kbyB5dC1kbHAgeSBtdXRhZ2VuLi4uJywgJ2dy
:::aXMnKQogICAgICAgICAgICAgICAgcCA9IHN1YnByb2Nlc3MucnVuKAogICAgICAg
:::ICAgICAgICAgICAgIFtzeXMuZXhlY3V0YWJsZSwgJy1tJywgJ3BpcCcsICdpbnN0
:::YWxsJywgJy0tdXBncmFkZScsCiAgICAgICAgICAgICAgICAgICAgICctLW5vLXdh
:::cm4tc2NyaXB0LWxvY2F0aW9uJywgJ3l0LWRscCcsICdtdXRhZ2VuJ10sCiAgICAg
:::ICAgICAgICAgICAgICAgc3Rkb3V0PXN1YnByb2Nlc3MuUElQRSwgc3RkZXJyPXN1
:::YnByb2Nlc3MuU1RET1VULAogICAgICAgICAgICAgICAgICAgIHRleHQ9VHJ1ZSwg
:::ZW5jb2Rpbmc9J3V0Zi04JywgZXJyb3JzPSdyZXBsYWNlJywgdGltZW91dD02MDAp
:::CiAgICAgICAgICAgICAgICBmb3IgbG4gaW4gKHAuc3Rkb3V0IG9yICcnKS5zdHJp
:::cCgpLnNwbGl0bGluZXMoKVstNjpdOgogICAgICAgICAgICAgICAgICAgIGxvZygn
:::ICAgJyArIGxuWzoxNjBdLCAnZ3JpcycpCiAgICAgICAgICAgICAgICBpZiBwLnJl
:::dHVybmNvZGUgPT0gMDoKICAgICAgICAgICAgICAgICAgICBsb2coJ3l0LWRscCBh
:::Y3R1YWxpemFkby4gUmVpbmljaWEgbGEgYXBsaWNhY2nDs24gcGFyYSAnCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICd1c2FyIGxhIHZlcnNpw7NuIG51ZXZhLicsICdv
:::aycpCiAgICAgICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgIGxv
:::ZygnTGEgYWN0dWFsaXphY2nDs24gZmFsbMOzICjCv3NpbiBpbnRlcm5ldD8pLics
:::ICdlcnJvcicpCiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZToKICAg
:::ICAgICAgICAgICAgIGxvZyhmJ05vIHNlIHB1ZG8gZWplY3V0YXIgcGlwOiB7ZX0n
:::LCAnZXJyb3InKQogICAgICAgICAgICBmaW5hbGx5OgogICAgICAgICAgICAgICAg
:::Y29sYS5wdXQoKCdmaW4nLCAnYWN0dWFsaXphY2lvbicsIFRydWUsICcnKSkKCiAg
:::ICAgICAgZGVmIF9tc2dfZXJyb3Ioc2VsZiwgZSk6CiAgICAgICAgICAgIGxpbmVh
:::cyA9IFtsIGZvciBsIGluIHN0cihlKS5zdHJpcCgpLnNwbGl0bGluZXMoKSBpZiBs
:::LnN0cmlwKCldCiAgICAgICAgICAgIHJldHVybiAobGluZWFzWzBdWzoyNTBdIGlm
:::IGxpbmVhcwogICAgICAgICAgICAgICAgICAgIGVsc2UgZid7dHlwZShlKS5fX25h
:::bWVfX306IHNpbiBkZXRhbGxlcycpCgogICAgICAgICMgLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGFycmFucXVlCiAgICAg
:::ICAgZGVmIF9hcnJhbnF1ZShzZWxmKToKICAgICAgICAgICAgc2VsZi5fbG9nKGYn
:::RGVzY2FyZ2Fkb3IgZGUgTXVzaWNhIHZ7QVBQX1Z9IOKAlCAnCiAgICAgICAgICAg
:::ICAgICAgICAgICAnWW91VHViZSBEb3dubG9hZGVyJywgJ3RpdHVsbycpCiAgICAg
:::ICAgICAgIHNlbGYuX2xvZygnQ3RybCtVOiBhY3R1YWxpemFyIHl0LWRscCDCtyBD
:::dHJsK0w6IGxpbXBpYXIgcmVnaXN0cm8nLAogICAgICAgICAgICAgICAgICAgICAg
:::J2dyaXMnKQogICAgICAgICAgICB0aHJlYWRpbmcuVGhyZWFkKHRhcmdldD1zZWxm
:::Ll9oaWxvX3ZlcnNpb24sIGRhZW1vbj1UcnVlKS5zdGFydCgpCgogICAgICAgIGRl
:::ZiBfaGlsb192ZXJzaW9uKHNlbGYpOgogICAgICAgICAgICBjb2xhID0gc2VsZi5j
:::b2xhCgogICAgICAgICAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAgICAg
:::ICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgICAgICAgICBpZiBZ
:::VF9ETFAgaXMgTm9uZToKICAgICAgICAgICAgICAgIGxvZygneXQtZGxwIG5vIGVz
:::dMOhIGluc3RhbGFkby4gRWplY3V0YSAnCiAgICAgICAgICAgICAgICAgICAgJ0Rl
:::c2NhcmdhZG9yTXVzaWNhLmJhdCBwYXJhIGluc3RhbGFybG8uJywgJ2Vycm9yJykK
:::ICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ3ZlcnNpb24nLCBUcnVl
:::LCAnJykpCiAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgdHJ5Ogog
:::ICAgICAgICAgICAgICAgaW5zdGFsYWRhID0gWVRfRExQLnZlcnNpb24uX192ZXJz
:::aW9uX18KICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAg
:::ICAgIGluc3RhbGFkYSA9ICc/JwogICAgICAgICAgICB1bHRpbWEgPSBOb25lCiAg
:::ICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHdpdGggdXJsb3BlbignaHR0
:::cHM6Ly9weXBpLm9yZy9weXBpL3l0LWRscC9qc29uJywgdGltZW91dD0xMikgYXMg
:::cjoKICAgICAgICAgICAgICAgICAgICB1bHRpbWEgPSBqc29uLmxvYWRzKHIucmVh
:::ZCgpLmRlY29kZSgndXRmLTgnKSlbJ2luZm8nXVsndmVyc2lvbiddCiAgICAgICAg
:::ICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgICAgICB1bHRpbWEgPSBO
:::b25lCiAgICAgICAgICAgIGlmIHVsdGltYSBpcyBOb25lOgogICAgICAgICAgICAg
:::ICAgbG9nKGYneXQtZGxwOiB2ZXJzacOzbiB7aW5zdGFsYWRhfSAnCiAgICAgICAg
:::ICAgICAgICAgICAgJyhubyBzZSBwdWRvIGNvbXByb2JhciBzaSBoYXkgbm92ZWRh
:::ZGVzKS4nLCAnZ3JpcycpCiAgICAgICAgICAgIGVsaWYgc3RyKHVsdGltYSkgPT0g
:::c3RyKGluc3RhbGFkYSk6CiAgICAgICAgICAgICAgICBsb2coZid5dC1kbHA6IGVu
:::IGxhIHVsdGltYSB2ZXJzaW9uICh7aW5zdGFsYWRhfSkuJywgJ2luZm8nKQogICAg
:::ICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgbG9nKGYneXQtZGxwOiBoYXkg
:::dmVyc2lvbiBudWV2YSAoe3VsdGltYX0pOyBpbnN0YWxhZGE6ICcKICAgICAgICAg
:::ICAgICAgICAgICBmJ3tpbnN0YWxhZGF9LiBQdWxzYSBDdHJsK1UgcGFyYSBhY3R1
:::YWxpemFyLicsICdhdmlzbycpCiAgICAgICAgICAgIGlmIEZGTVBFRyBpcyBOb25l
:::OgogICAgICAgICAgICAgICAgbG9nKCdGRm1wZWc6IE5PIEVOQ09OVFJBRE8g4oCU
:::IGVqZWN1dGEgRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0ICcKICAgICAgICAgICAgICAg
:::ICAgICAncGFyYSBpbnN0YWxhcmxvLicsICdlcnJvcicpCiAgICAgICAgICAgIGVs
:::c2U6CiAgICAgICAgICAgICAgICBsb2coZidGRm1wZWc6IE9LICh7RkZNUEVHfSkn
:::LCAnZ3JpcycpCiAgICAgICAgICAgIGxvZygnQ2FycGV0YSBkZSBndWFyZGFkbzog
:::JyArIHN0cihBSlVTVEVTLmdldCgnZGVzdGlubycpKSwgJ2dyaXMnKQogICAgICAg
:::ICAgICBjb2xhLnB1dCgoJ2ZpbicsICd2ZXJzaW9uJywgVHJ1ZSwgJycpKQoKCiMg
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLSBtYWluCmRlZiBtYWluKCk6CiAgICBfcmVjb25maWd1
:::cmFyX3NhbGlkYSgpCiAgICBpZiBub3QgVEtfT0s6CiAgICAgICAgcHJpbnQoJ0Vz
:::dGEgYXBsaWNhY2nDs24gbmVjZXNpdGEgVGtpbnRlciAoaW50ZXJmYXogZ3LDoWZp
:::Y2EpLicpCiAgICAgICAgcHJpbnQoJ0VsIFB5dGhvbiBhY3R1YWwgbm8gbG8gaW5j
:::bHV5ZS4nKQogICAgICAgIHByaW50KCdWdWVsdmUgYSBlamVjdXRhciBEZXNjYXJn
:::YWRvck11c2ljYS5iYXQgcGFyYSBpbnN0YWxhciBlbCAnCiAgICAgICAgICAgICAg
:::J1B5dGhvbiBhZGVjdWFkby4nKQogICAgICAgIHJldHVybiAxCiAgICBjb21wcm9i
:::YXJfZW50b3JubygpCiAgICBhcHAgPSBBcHAoKQogICAgYXBwLm1haW5sb29wKCkK
:::ICAgIHJldHVybiAwCgoKaWYgX19uYW1lX18gPT0gJ19fbWFpbl9fJzoKICAgIHRy
:::eToKICAgICAgICBzeXMuZXhpdChtYWluKCkpCiAgICBleGNlcHQgU3lzdGVtRXhp
:::dDoKICAgICAgICByYWlzZQogICAgZXhjZXB0IEJhc2VFeGNlcHRpb246CiAgICAg
:::ICAgdHJ5OgogICAgICAgICAgICB3aXRoIG9wZW4oTE9HX0VSUk9SRVMsICdhJywg
:::ZW5jb2Rpbmc9J3V0Zi04JykgYXMgZmg6CiAgICAgICAgICAgICAgICBmaC53cml0
:::ZSh0cmFjZWJhY2suZm9ybWF0X2V4YygpICsgJ1xuJykKICAgICAgICBleGNlcHQg
:::RXhjZXB0aW9uOgogICAgICAgICAgICBwYXNzCiAgICAgICAgcmFpc2UK
