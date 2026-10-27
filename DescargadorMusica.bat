@echo off
rem ================================================================
rem  MUSIKALAN - instalador y lanzador todo-en-uno (antes Descargador de Musica)
rem  ----------------------------------------------------------------
rem  Este unico archivo .bat:
rem    [1] Comprueba si hay una version mas reciente en GitHub; si la hay,
rem        se descarga y se reemplaza a si mismo (conservando Python,
rem        FFmpeg, yt-dlp/mutagen y tus ajustes) y se reinicia solo
rem    [2] Restaura la aplicacion (script Python embebido en base64)
rem    [3] Comprueba Python 3.9+ con Tkinter; si falta, descarga un
rem        Python portatil COMPLETO dentro de la carpeta de datos
rem        %APPDATA%\MusikALAN\runtime (sin permisos de administrador;
rem        incluye la interfaz grafica)
rem    [4] Instala yt-dlp y mutagen con pip si no estan
rem    [5] Comprueba FFmpeg ; si falta, lo descarga de los espejos
rem        rapidos de GitHub (GyanD / BtbN) y de gyan.dev de reserva
rem    [6] Abre la ventana de descargas (YouTube Downloader)
rem  Requisitos: Windows 10 1803 o superior. Internet solo la primera vez.
rem  Desde la v2.4 todo se instala en %APPDATA%\MusikALAN aunque el .bat
rem  este en Descargas; una instalacion vieja junto al .bat se mueve sola.
rem  Desde la v2.10 el .bat se auto-actualiza solo al arrancar.
rem  Desde la v2.11 la aplicacion se restaura del instalador en CADA
rem  arranque, asi que basta con abrir un .bat nuevo para tener la app
rem  nueva (se conserva todo: Python, FFmpeg, yt-dlp y tus ajustes).
rem  Parametros opcionales:
rem     --reinstalar   fuerza a re-extraer descargador.py (ya no hace falta)
rem     --sin-buscar   se salta la comprobacion de actualizaciones
rem  NOTA: este archivo debe ser ASCII puro y CRLF (no tocar a mano).
rem ================================================================
setlocal EnableExtensions
title MusikALAN v2.14
rem  Marca de version: la busca este mismo archivo con findstr para
rem  compararse con la ultima release publicada en GitHub.
rem  NO cambiar el formato de la linea siguiente.
rem VERSION-BUSCABLE: 2.14
cd /d "%~dp0"
set "SELF=%~f0"
set "V_LOCAL=0"
for /f "tokens=3" %%V in ('findstr /b /c:"rem VERSION-BUSCABLE:" "%~f0"') do set "V_LOCAL=%%V"

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
echo    %C_TIT%MusikALAN v2.14%C_FIN% - preparando el entorno
echo    Instalador portable: no pide permisos de administrador.
echo    Si falta algo (Python, yt-dlp, FFmpeg) se descarga e instala aqui.
echo   %C_GRI%--------------------------------------------------------------------%C_FIN%
echo    Sistema : Windows 10 o superior, %ARCH%
echo    Datos   : %APPDIR%
echo    Musica  : las canciones se guardan en tu carpeta de Musica
echo.

rem --- [1/6] comprobar si hay una version mas reciente en GitHub ---
rem  Si la hay, este archivo se reemplaza a si mismo conservando todo
rem  lo pesado (Python, FFmpeg, yt-dlp/mutagen) y se reinicia solo.
rem  Cualquier fallo aqui se ignora y se sigue con la version actual.
if /i "%~1"=="--sin-buscar" goto seguir_instalacion
echo  %C_INFO%[1/6]%C_FIN% %C_TIT%Buscando actualizaciones%C_FIN%...
call :comprobar_actualizacion
if "%UPD%"=="2" echo    %C_GRI%(ahora mismo no se pudo comprobar; se continua igual)%C_FIN%
if "%UPD%"=="0" echo    %C_OK%OK%C_FIN% tienes la version mas reciente (v%V_LOCAL%).
if "%UPD%"=="1" goto hay_actualizacion

:seguir_instalacion
rem --- migracion: si hay una instalacion antigua junto al .bat, se
rem     mueve a la carpeta de datos para no descargarla otra vez ---
if not exist "%SCRIPT%" if exist "%~dp0descargador.py" move /y "%~dp0descargador.py" "%SCRIPT%" >nul 2>nul
if not exist "%APPDIR%ajustes.json" if exist "%~dp0ajustes.json" move /y "%~dp0ajustes.json" "%APPDIR%ajustes.json" >nul 2>nul
if not exist "%RUNTIME%\python\python.exe" if exist "%~dp0runtime" call :migrar_carpeta "%~dp0runtime" "%RUNTIME%" "%RUNTIME%\python\python.exe"
if not exist "%FFDIR%\bin\ffmpeg.exe" if exist "%~dp0ffmpeg" call :migrar_carpeta "%~dp0ffmpeg" "%FFDIR%" "%FFDIR%\bin\ffmpeg.exe"
if exist "%~dp0_instalacion_tmp" rmdir /s /q "%~dp0_instalacion_tmp" 2>nul

echo  %C_INFO%[2/6]%C_FIN% %C_TIT%Preparando la aplicacion%C_FIN% (script embebido)...
if "%~1"=="--reinstalar" if exist "%SCRIPT%" del /q "%SCRIPT%"
rem  Desde la v2.11 el script se restaura SIEMPRE del instalador, sin
rem  mirar si ya existia una copia en la carpeta de datos. Antes se
rem  saltaba este paso si descargador.py ya estaba, y por eso quien
rem  tenia una version antigua de la app seguia viendola aunque bajara
rem  o recibiera el instalador nuevo.
for /f "tokens=1 delims=:" %%a in ('findstr /b /c:":::" "%~f0"') do >>"%TMPDIR%\payload.b64" echo(%%a
certutil -f -decode "%TMPDIR%\payload.b64" "%SCRIPT%" >nul 2>nul
if errorlevel 1 goto err_payload
del /q "%TMPDIR%\payload.b64" >nul 2>nul
echo    %C_OK%OK%C_FIN% aplicacion restaurada, version v%V_LOCAL% (la misma que este instalador).
goto script_listo

:err_payload
echo    %C_ERR%ERROR%C_FIN% no se pudo extraer el script embebido.
echo    Si la aplicacion esta abierta, cierrala y vuelve a ejecutar
echo    este archivo. Si aun asi falla, vuelve a descargar el archivo
echo    DescargadorMusica.bat completo (se pudo cortar al copiarlo).
goto fin_error

:script_listo
echo  %C_INFO%[3/6]%C_FIN% %C_TIT%Buscando Python%C_FIN% con soporte de interfaz grafica...
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
echo  %C_INFO%[4/6]%C_FIN% %C_TIT%Verificando yt-dlp y mutagen%C_FIN%...
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

echo  %C_INFO%[5/6]%C_FIN% %C_TIT%Buscando FFmpeg%C_FIN%...
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

echo  %C_INFO%[6/6]%C_FIN% %C_TIT%Todo listo%C_FIN% - abriendo la aplicacion...
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
title MusikALAN v2.14 - YouTube a AAC/MP3/FLAC/WAV/WMA/AVI
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

:comprobar_actualizacion
rem  Consulta la ultima release publicada en GitHub (sin autenticar).
rem  Deja en UPD:   0 = estas al dia | 1 = hay version nueva (en V_NUEVA)
rem                 2 = no se pudo comprobar (sin internet, sin PowerShell...)
set "UPD=2"
set "V_NUEVA="
if not defined V_LOCAL exit /b 2
if not exist "%TMPDIR%" mkdir "%TMPDIR%" 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol='Tls12'; try{ $r=Invoke-RestMethod -Uri 'https://api.github.com/repos/CurifeosPP/MusikALAN/releases/latest' -TimeoutSec 8; $t=([string]$r.tag_name).TrimStart('v'); if($t -match '^[0-9]+(\.[0-9]+)?$'){ Set-Content -LiteralPath '%TMPDIR%\version_nueva.txt' -Value $t -Encoding Ascii; exit 0 } } catch { }; exit 2" >nul 2>nul
if errorlevel 1 exit /b 2
if exist "%TMPDIR%\version_nueva.txt" for /f "usebackq delims=" %%V in ("%TMPDIR%\version_nueva.txt") do set "V_NUEVA=%%V"
del /q "%TMPDIR%\version_nueva.txt" >nul 2>nul
if not defined V_NUEVA exit /b 2
call :comparar_versiones "%V_NUEVA%" "%V_LOCAL%"
set "UPD=%COMPARACION%"
exit /b 0

:hay_actualizacion
rem  Hay una version mas nueva publicada: descargarla, validarla y
rem  reemplazar este .bat conservando Python/FFmpeg/yt-dlp/ajustes.
echo    %C_INFO%Nueva version v%V_NUEVA%%C_FIN% disponible (tienes la v%V_LOCAL%).
echo    Descargando el instalador actualizado, un momento...
call :Descargar "https://github.com/CurifeosPP/MusikALAN/releases/latest/download/DescargadorMusica.bat" "%TMPDIR%\MusikALAN_nueva.bat"
if errorlevel 1 goto upd_err_desc
set "UPD_TAM="
for %%S in ("%TMPDIR%\MusikALAN_nueva.bat") do set "UPD_TAM=%%~zS"
if not defined UPD_TAM goto upd_err_validar
if %UPD_TAM% LSS 50000 goto upd_err_validar
findstr /b /c:":::" "%TMPDIR%\MusikALAN_nueva.bat" >nul 2>nul
if errorlevel 1 goto upd_err_validar
set "V_DESC="
for /f "tokens=3" %%V in ('findstr /b /c:"rem VERSION-BUSCABLE:" "%TMPDIR%\MusikALAN_nueva.bat"') do set "V_DESC=%%V"
if not defined V_DESC goto upd_err_validar
echo %V_DESC%| findstr /r "^[0-9][0-9.]*$" >nul 2>nul
if errorlevel 1 goto upd_err_validar
call :comparar_versiones "%V_DESC%" "%V_LOCAL%"
if "%COMPARACION%"=="0" goto upd_sin_cambio
rem  --- escribir el lanzador que hace el reemplazo al salir este .bat ---
rem  Borra el programa viejo (script) pero conserva runtime, ffmpeg,
rem  los paquetes pip y ajustes.json; el nuevo .bat, al arrancar, salta
rem  directo a abrir la ventana porque las dependencias ya estan.
> "%TMPDIR%\actualizar.cmd" (
    echo @echo off
    echo title MusikALAN - instalando v%V_DESC%
    echo ping -n 4 127.0.0.1 ^>nul
    echo del /q "%SCRIPT%" 2^>nul
    echo move /y "%TMPDIR%\MusikALAN_nueva.bat" "%SELF%" ^>nul
    echo if errorlevel 1 goto fallo_upd
    echo start "" "%SELF%"
    echo del /q "%%~f0" ^>nul 2^>nul
    echo exit /b 0
    echo :fallo_upd
    echo echo.
    echo echo  No se pudo reemplazar el archivo DescargadorMusica.bat
    echo echo  ^(algo lo tiene bloqueado^). El nuevo quedo en:
    echo echo    "%TMPDIR%\MusikALAN_nueva.bat"
    echo echo  Muevelo a mano encima del viejo y ejecutalo.
    echo pause
    echo exit /b 1
)
echo    %C_OK%OK%C_FIN% todo listo. El instalador se reinicia solo en unos segundos...
start "" cmd /c "%TMPDIR%\actualizar.cmd"
endlocal
exit /b 0

:upd_sin_cambio
del /q "%TMPDIR%\MusikALAN_nueva.bat" >nul 2>nul
goto seguir_instalacion

:upd_err_desc
del /q "%TMPDIR%\MusikALAN_nueva.bat" >nul 2>nul
echo    %C_GRI%(no se pudo descargar la actualizacion; se continua con la v%V_LOCAL%)%C_FIN%
goto seguir_instalacion

:upd_err_validar
del /q "%TMPDIR%\MusikALAN_nueva.bat" >nul 2>nul
echo    %C_GRI%(la descarga no paso la validacion; se continua con la v%V_LOCAL%)%C_FIN%
goto seguir_instalacion

:comparar_versiones
rem  Uso: call :comparar_versiones "candidata" "actual"
rem  Deja COMPARACION=1 si candidata es mas nueva que actual; 0 si no.
set "COMPARACION=0"
set "CV_A1=" & set "CV_A2=" & set "CV_A3=" & set "CV_B1=" & set "CV_B2=" & set "CV_B3="
for /f "tokens=1-3 delims=." %%A in ("%~1") do (set "CV_A1=%%A" & set "CV_A2=%%B" & set "CV_A3=%%C")
for /f "tokens=1-3 delims=." %%A in ("%~2") do (set "CV_B1=%%A" & set "CV_B2=%%B" & set "CV_B3=%%C")
if not defined CV_A1 goto cmp_fin
if not defined CV_B1 goto cmp_fin
if not defined CV_A2 set "CV_A2=0"
if not defined CV_B2 set "CV_B2=0"
if not defined CV_A3 set "CV_A3=0"
if not defined CV_B3 set "CV_B3=0"
if %CV_A1% GTR %CV_B1% (set "COMPARACION=1" & goto cmp_fin)
if %CV_A1% LSS %CV_B1% goto cmp_fin
if %CV_A2% GTR %CV_B2% (set "COMPARACION=1" & goto cmp_fin)
if %CV_A2% LSS %CV_B2% goto cmp_fin
if %CV_A3% GTR %CV_B3% set "COMPARACION=1"
:cmp_fin
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
:::UF9WID0gJzIuMTQnCkFQUF9ESVIgPSBQYXRoKF9fZmlsZV9fKS5yZXNvbHZlKCku
:::cGFyZW50ClJVVEFfQUpVU1RFUyA9IEFQUF9ESVIgLyAnYWp1c3Rlcy5qc29uJwpM
:::T0dfRVJST1JFUyA9IEFQUF9ESVIgLyAnZGVzY2FyZ2Fkb3JfZXJyb3Jlcy5sb2cn
:::CgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0gc2FsaWRhCiMgQWwgZWplY3V0YXJzZSBjb24g
:::cHl0aG9udy5leGUgKHNpbiBjb25zb2xhKSBzdGRvdXQvc3RkZXJyIHNvbiBOb25l
:::OgojIGN1YWxxdWllciBwcmludCBmYWxsYXJpYS4gTG9zIHJlZGlyaWdpbW9zIGEg
:::dW4gc2l0aW8gc2VndXJvLgp0cnk6CiAgICBpZiBzeXMuc3Rkb3V0IGlzIE5vbmU6
:::CiAgICAgICAgc3lzLnN0ZG91dCA9IG9wZW4ob3MuZGV2bnVsbCwgJ3cnLCBlbmNv
:::ZGluZz0ndXRmLTgnKQpleGNlcHQgRXhjZXB0aW9uOgogICAgcGFzcwp0cnk6CiAg
:::ICBpZiBzeXMuc3RkZXJyIGlzIE5vbmU6CiAgICAgICAgc3lzLnN0ZGVyciA9IG9w
:::ZW4oTE9HX0VSUk9SRVMsICdhJywgZW5jb2Rpbmc9J3V0Zi04JykKZXhjZXB0IEV4
:::Y2VwdGlvbjoKICAgIHBhc3MKCgpkZWYgX3JlY29uZmlndXJhcl9zYWxpZGEoKToK
:::ICAgICIiIkV2aXRhIGNyYXNoZXMgcG9yIGNhcmFjdGVyZXMgcmFyb3Mgc2kgbGEg
:::c2FsaWRhIHNlIHJlZGlyaWdlLiIiIgogICAgZm9yIHMgaW4gKHN5cy5zdGRvdXQs
:::IHN5cy5zdGRlcnIpOgogICAgICAgIHRyeToKICAgICAgICAgICAgaWYgcyBhbmQg
:::aGFzYXR0cihzLCAncmVjb25maWd1cmUnKToKICAgICAgICAgICAgICAgIHMucmVj
:::b25maWd1cmUoZXJyb3JzPSdyZXBsYWNlJykKICAgICAgICBleGNlcHQgRXhjZXB0
:::aW9uOgogICAgICAgICAgICBwYXNzCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIHRraW50
:::ZXIKdHJ5OgogICAgaW1wb3J0IHRraW50ZXIgYXMgdGsKICAgIGZyb20gdGtpbnRl
:::ciBpbXBvcnQgZmlsZWRpYWxvZywgbWVzc2FnZWJveCwgdHRrCiAgICBmcm9tIHRr
:::aW50ZXIuc2Nyb2xsZWR0ZXh0IGltcG9ydCBTY3JvbGxlZFRleHQKICAgIFRLX09L
:::ID0gVHJ1ZQpleGNlcHQgRXhjZXB0aW9uOgogICAgVEtfT0sgPSBGYWxzZQoKCiMg
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLSBhanVzdGVzCmRlZiBfY2FycGV0YV9tdXNpY2EoKToK
:::ICAgICIiIkNhcnBldGEgJ011c2ljYScgcmVhbCBkZWwgdXN1YXJpbyAoRk9MREVS
:::SURfTXVzaWMgZGUgV2luZG93cykuIiIiCiAgICBpZiBvcy5uYW1lID09ICdudCc6
:::CiAgICAgICAgdHJ5OgogICAgICAgICAgICBpbXBvcnQgY3R5cGVzCgogICAgICAg
:::ICAgICBjbGFzcyBfR1VJRChjdHlwZXMuU3RydWN0dXJlKToKICAgICAgICAgICAg
:::ICAgIF9maWVsZHNfID0gWygnRDEnLCBjdHlwZXMuY191bG9uZyksICgnRDInLCBj
:::dHlwZXMuY191c2hvcnQpLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgKCdE
:::MycsIGN0eXBlcy5jX3VzaG9ydCksCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAoJ0Q0JywgY3R5cGVzLmNfdWJ5dGUgKiA4KV0KCiAgICAgICAgICAgIG11c2lj
:::YSA9IF9HVUlEKDB4NEJEOEQ1NzEsIDB4NkQxOSwgMHg0OEQzLAogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAoY3R5cGVzLmNfdWJ5dGUgKiA4KSgweEJFLCAweDk3
:::LCAweDAzLCAweDM4LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAweDVGLCAweDdGLCAweEM1LCAweENFKSkKICAgICAgICAg
:::ICAgcHRyID0gY3R5cGVzLmNfd2NoYXJfcCgpCiAgICAgICAgICAgIGlmIGN0eXBl
:::cy53aW5kbGwuc2hlbGwzMi5TSEdldEtub3duRm9sZGVyUGF0aCgKICAgICAgICAg
:::ICAgICAgICAgICBjdHlwZXMuYnlyZWYobXVzaWNhKSwgMCwgTm9uZSwKICAgICAg
:::ICAgICAgICAgICAgICBjdHlwZXMuYnlyZWYocHRyKSkgPT0gMCBhbmQgcHRyLnZh
:::bHVlOgogICAgICAgICAgICAgICAgcnV0YSA9IHB0ci52YWx1ZQogICAgICAgICAg
:::ICAgICAgY3R5cGVzLndpbmRsbC5vbGUzMi5Db1Rhc2tNZW1GcmVlKHB0cikKICAg
:::ICAgICAgICAgICAgIHJldHVybiBydXRhCiAgICAgICAgZXhjZXB0IEV4Y2VwdGlv
:::bjoKICAgICAgICAgICAgcGFzcwogICAgcmV0dXJuIHN0cihQYXRoLmhvbWUoKSAv
:::ICdNdXNpYycpCgoKZGVmIF9kZXN0aW5vX2FwcGRhdGFfdmllam8oKToKICAgICIi
:::IkNhcnBldGEgZGVsIHByb2dyYW1hIChlcmEgZWwgZGVzdGlubyBwb3IgZGVmZWN0
:::byBlbiBsYSB2Mi4yKS4iIiIKICAgIGJhc2UgPSBvcy5lbnZpcm9uLmdldCgnQVBQ
:::REFUQScpIG9yIHN0cihQYXRoLmhvbWUoKSAvICdBcHBEYXRhJyAvICdSb2FtaW5n
:::JykKICAgIHJldHVybiBzdHIoUGF0aChiYXNlKSAvICdNdXNpa0FMQU4nKQoKCmRl
:::ZiBfZGVzdGlub19wb3JfZGVmZWN0bygpOgogICAgIiIiTG9zIGFyY2hpdm9zIHNl
:::IGd1YXJkYW4gZW4gbGEgY2FycGV0YSBNdXNpY2EgZGVsIHVzdWFyaW8uIiIiCiAg
:::ICByZXR1cm4gX2NhcnBldGFfbXVzaWNhKCkKCgpBSlVTVEVTX0RFRkVDVE8gPSB7
:::CiAgICAnZGVzdGlubyc6IF9kZXN0aW5vX3Bvcl9kZWZlY3RvKCksCiAgICAndGVt
:::YSc6ICdPc2N1cm8nLAogICAgJ2Zvcm1hdG8nOiAnQUFDJywKICAgICdjYWxpZGFk
:::JzogJzEyOGsnLAogICAgJ2VtYmViZXInOiBUcnVlLAogICAgJ2Nvb2tpZXMnOiAn
:::JywgICAgIyB2Mi45OiBuYXZlZ2Fkb3IgY3V5YXMgY29va2llcyB1c2FyIHNpIFlv
:::dVR1YmUgYmxvcXVlYQp9CgoKZGVmIGNhcmdhcl9hanVzdGVzKCk6CiAgICBhID0g
:::ZGljdChBSlVTVEVTX0RFRkVDVE8pCiAgICB0cnk6CiAgICAgICAgYS51cGRhdGUo
:::anNvbi5sb2FkcyhSVVRBX0FKVVNURVMucmVhZF90ZXh0KGVuY29kaW5nPSd1dGYt
:::OCcpKSkKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgcGFzcwogICAgYS5w
:::b3AoJ25hdmVnYWRvcicsIE5vbmUpICAjIHYyLjIgbyBhbnRlcmlvcjogbGEgc2Vj
:::Y2lvbiBkZSBjb29raWVzIHlhIG5vIGV4aXN0ZQogICAgIyBtaWdyYWNpb25lcyBk
:::ZWwgZGVzdGlubyBkZSBndWFyZGFkbzoKICAgICMgIMK3IHYyLjAvMi4xIHVzYWJh
:::IE11c2ljL1lURG93bmxvYWRlcgogICAgIyAgwrcgdjIuMiB1c2FiYSBsYSBjYXJw
:::ZXRhIGRlbCBwcm9ncmFtYSAoQXBwRGF0YVxSb2FtaW5nXE11c2lrQUxBTikKICAg
:::ICMgRGVzZGUgbGEgdjIuMyBlbCBkZXN0aW5vIHBvciBkZWZlY3RvIGVzIGxhIGNh
:::cnBldGEgTXVzaWNhIGRlbCB1c3VhcmlvLAogICAgIyBhc2kgcXVlIHNpIGVsIGFq
:::dXN0ZSBhcHVudGEgYSBjdWFscXVpZXJhIGRlIGxvcyBkb3MsIHNlIGFjdHVhbGl6
:::YS4KICAgIGRlc3Rpbm8gPSBzdHIoYS5nZXQoJ2Rlc3Rpbm8nKSBvciAnJykucmVw
:::bGFjZSgnXFwnLCAnLycpLnJzdHJpcCgnLycpLmxvd2VyKCkKICAgIGlmICd5dGRv
:::d25sb2FkZXInIGluIGRlc3Rpbm86CiAgICAgICAgYVsnZGVzdGlubyddID0gQUpV
:::U1RFU19ERUZFQ1RPWydkZXN0aW5vJ10KICAgIGVsc2U6CiAgICAgICAgdmllam8g
:::PSBfZGVzdGlub19hcHBkYXRhX3ZpZWpvKCkucmVwbGFjZSgnXFwnLCAnLycpLnJz
:::dHJpcCgnLycpLmxvd2VyKCkKICAgICAgICBpZiBkZXN0aW5vIGFuZCAoZGVzdGlu
:::byA9PSB2aWVqbwogICAgICAgICAgICAgICAgICAgICAgICBvciBkZXN0aW5vLnN0
:::YXJ0c3dpdGgodmllam8gKyAnLycpKToKICAgICAgICAgICAgYVsnZGVzdGlubydd
:::ID0gQUpVU1RFU19ERUZFQ1RPWydkZXN0aW5vJ10KICAgIHJldHVybiBhCgoKZGVm
:::IGd1YXJkYXJfYWp1c3RlcygpOgogICAgdHJ5OgogICAgICAgIFJVVEFfQUpVU1RF
:::Uy53cml0ZV90ZXh0KAogICAgICAgICAgICBqc29uLmR1bXBzKEFKVVNURVMsIGVu
:::c3VyZV9hc2NpaT1GYWxzZSwgaW5kZW50PTIpLAogICAgICAgICAgICBlbmNvZGlu
:::Zz0ndXRmLTgnKQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICBwYXNzCgoK
:::QUpVU1RFUyA9IGNhcmdhcl9hanVzdGVzKCkKCgojIC0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0g
:::dXRpbHMKZGVmIGZtdF90YW0obik6CiAgICBpZiBub3QgbjoKICAgICAgICByZXR1
:::cm4gJ+KAlCcKICAgIG4gPSBmbG9hdChuKQogICAgZm9yIHUgaW4gKCdCJywgJ0tp
:::QicsICdNaUInLCAnR2lCJyk6CiAgICAgICAgaWYgbiA8IDEwMjQgb3IgdSA9PSAn
:::R2lCJzoKICAgICAgICAgICAgcmV0dXJuIGYne2ludChuKX0ge3V9JyBpZiB1ID09
:::ICdCJyBlbHNlIGYne246LjFmfSB7dX0nCiAgICAgICAgbiAvPSAxMDI0CgoKZGVm
:::IGZtdF90aWVtKHMpOgogICAgaWYgcyBpcyBOb25lOgogICAgICAgIHJldHVybiAn
:::4oCUJwogICAgcyA9IGludChzKQogICAgaCwgciA9IGRpdm1vZChzLCAzNjAwKQog
:::ICAgbSwgeCA9IGRpdm1vZChyLCA2MCkKICAgIHJldHVybiBmJ3tofTp7bTowMmR9
:::Ont4OjAyZH0nIGlmIGggZWxzZSBmJ3ttOjAyZH06e3g6MDJkfScKCgpkZWYgbGlt
:::cGlhcl9ub21icmUodCk6CiAgICB0ID0gcmUuc3ViKHInWzw+OiIvXFx8PypceDAw
:::LVx4MWZdJywgJ18nLCBzdHIodCkpLnN0cmlwKCcgLicpCiAgICByZXR1cm4gdFs6
:::MTUwXSBvciAnc2luX3RpdHVsbycKCgpkZWYgc2luX3BsYXlsaXN0KHVybCk6CiAg
:::ICAiIiJRdWl0YSBlbCBwYXLDoW1ldHJvIGxpc3Q9IGRlIGxhIFVSTCAobW9kbyBz
:::b2xvIHZpZGVvKS4iIiIKICAgIHRyeToKICAgICAgICBwID0gdXJscGFyc2UodXJs
:::KQogICAgICAgIHEgPSBwYXJzZV9xcyhwLnF1ZXJ5KQogICAgICAgIGlmICdsaXN0
:::JyBpbiBxOgogICAgICAgICAgICBkZWwgcVsnbGlzdCddCiAgICAgICAgICAgIHJl
:::dHVybiB1cmx1bnBhcnNlKHAuX3JlcGxhY2UocXVlcnk9dXJsZW5jb2RlKHEsIGRv
:::c2VxPVRydWUpKSksIFRydWUKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAg
:::cGFzcwogICAgcmV0dXJuIHVybCwgRmFsc2UKCgpkZWYgZXNfdXJsX3BsYXlsaXN0
:::KHVybCk6CiAgICAiIiJUcnVlIHNpIGxhIFVSTCBwZXJ0ZW5lY2UgYSB1bmEgbGlz
:::dGEgZGUgcmVwcm9kdWNjacOzbiAobGxldmEgbGlzdD0pLiIiIgogICAgdHJ5Ogog
:::ICAgICAgIHJldHVybiAnbGlzdCcgaW4gcGFyc2VfcXModXJscGFyc2UodXJsKS5x
:::dWVyeSkKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgcmV0dXJuIEZhbHNl
:::CgoKZGVmIGVzX3NvbG9fbGlzdGEodXJsKToKICAgICIiIlRydWUgc2kgbGEgVVJM
:::IGVzIHVuYSBwbGF5bGlzdCBwdXJhLCBzaW4gdmlkZW8gaW5kaXZpZHVhbCAoc2lu
:::IHY9KS4iIiIKICAgIHRyeToKICAgICAgICBwID0gdXJscGFyc2UodXJsKQogICAg
:::ICAgIGlmICd2JyBpbiBwYXJzZV9xcyhwLnF1ZXJ5KSBvciAneW91dHUuYmUnIGlu
:::IChwLm5ldGxvYyBvciAnJyk6CiAgICAgICAgICAgIHJldHVybiBGYWxzZQogICAg
:::ICAgIHJldHVybiAocC5wYXRoIG9yICcnKS5yc3RyaXAoJy8nKS5lbmRzd2l0aCgn
:::L3BsYXlsaXN0JykKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgcmV0dXJu
:::IEZhbHNlCgoKZGVmIGFicmlyX2NhcnBldGEocnV0YSk6CiAgICB0cnk6CiAgICAg
:::ICAgaWYgb3MubmFtZSA9PSAnbnQnOgogICAgICAgICAgICBvcy5zdGFydGZpbGUo
:::c3RyKHJ1dGEpKSAgIyBub3FhOiBzb2xvIFdpbmRvd3MKICAgICAgICBlbHNlOgog
:::ICAgICAgICAgICBzdWJwcm9jZXNzLlBvcGVuKFsneGRnLW9wZW4nLCBzdHIocnV0
:::YSldKQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICBwYXNzCgoKIyAtLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tIGZmbXBlZwpkZWYgYnVzY2FyX2ZmbXBlZygpOgogICAgZXhl
:::ID0gc2h1dGlsLndoaWNoKCdmZm1wZWcnKQogICAgaWYgZXhlOgogICAgICAgIHJl
:::dHVybiBQYXRoKGV4ZSkKICAgIGNhbmRpZGF0b3MgPSBbCiAgICAgICAgQVBQX0RJ
:::UiAvICdmZm1wZWcnIC8gJ2JpbicgLyAnZmZtcGVnLmV4ZScsCiAgICAgICAgQVBQ
:::X0RJUiAvICdmZm1wZWcnIC8gJ2JpbicgLyAnZmZtcGVnJywKICAgICAgICBBUFBf
:::RElSIC8gJ3J1bnRpbWUnIC8gJ2ZmbXBlZy5leGUnLAogICAgXQogICAgZm9yIHAg
:::aW4gY2FuZGlkYXRvczoKICAgICAgICBpZiBwLmV4aXN0cygpOgogICAgICAgICAg
:::ICByZXR1cm4gcAogICAgcmV0dXJuIE5vbmUKCgpkZWYgYnVzY2FyX2ZmcHJvYmUo
:::ZmZtcGVnKToKICAgIGlmIGZmbXBlZyBpcyBOb25lOgogICAgICAgIHJldHVybiBz
:::aHV0aWwud2hpY2goJ2ZmcHJvYmUnKQogICAgcCA9IGZmbXBlZy53aXRoX25hbWUo
:::J2ZmcHJvYmUuZXhlJyBpZiBvcy5uYW1lID09ICdudCcgZWxzZSAnZmZwcm9iZScp
:::CiAgICBpZiBwLmV4aXN0cygpOgogICAgICAgIHJldHVybiBwCiAgICByZXR1cm4g
:::c2h1dGlsLndoaWNoKCdmZnByb2JlJykKCgpZVF9ETFAgPSBOb25lICAgIyBtw7Nk
:::dWxvIHl0X2RscDsgc2UgcmVsbGVuYSBlbiBjb21wcm9iYXJfZW50b3JubygpCkZG
:::TVBFRyA9IE5vbmUgICAjIHJ1dGEgZGUgZmZtcGVnCkZGUFJPQkUgPSBOb25lICAj
:::IHJ1dGEgZGUgZmZwcm9iZQoKCmRlZiBjb21wcm9iYXJfZW50b3JubygpOgogICAg
:::Z2xvYmFsIFlUX0RMUCwgRkZNUEVHLCBGRlBST0JFCiAgICB0cnk6CiAgICAgICAg
:::aW1wb3J0IHl0X2RscCBhcyBtb2QKICAgICAgICBZVF9ETFAgPSBtb2QKICAgIGV4
:::Y2VwdCBFeGNlcHRpb246CiAgICAgICAgcGFzcwogICAgRkZNUEVHID0gYnVzY2Fy
:::X2ZmbXBlZygpCiAgICBGRlBST0JFID0gYnVzY2FyX2ZmcHJvYmUoRkZNUEVHKQoK
:::CmNsYXNzIFJlZ2lzdHJvOgogICAgIiIiTG9nZ2VyIHBhcmEgeXQtZGxwOiByZWVu
:::dsOtYSBhdmlzb3MvZXJyb3JlcyBhbCByZWdpc3RybyBkZSBsYSBHVUkuIiIiCgog
:::ICAgZGVmIF9faW5pdF9fKHNlbGYpOgogICAgICAgIHNlbGYubG9nID0gTm9uZSAg
:::IyBsYSBHVUkgbG8gY29uZWN0YTogbG9nKG1lbnNhamUsIGV0aXF1ZXRhKQoKICAg
:::IGRlZiBkZWJ1ZyhzZWxmLCBtKToKICAgICAgICBwYXNzCgogICAgIyBBdmlzb3Mg
:::aW50ZXJub3MgZGUgeXQtZGxwIHF1ZSBzb2xvIG1ldGVuIHJ1aWRvIGVuIGVsIHJl
:::Z2lzdHJvLgogICAgIyB2Mi4xMzogWW91VHViZSBlbWl0ZSB0cmVzIGF2aXNvcyBJ
:::TkZPUk1BVElWT1MgZW4gY2FzaSB0b2RhcyBsYXMKICAgICMgZGVzY2FyZ2FzIChl
:::eHBlcmltZW50b3MgU0FCUiB5IGRlbCBQTyBUb2tlbikuIE5vIGltcGlkZW4gYmFq
:::YXIgbGEKICAgICMgY2FuY2lvbiAtLSBsb3MgZm9ybWF0b3MgZGUgYW5kcm9pZC9p
:::b3Mgc2lndWVuIGZ1bmNpb25hbmRvIC0tIHBlcm8KICAgICMgZXNjcml0b3MgZW4g
:::YW1hcmlsbG8gYXN1c3RhbjogcGFyZWNlIHF1ZSBhbGdvIHNhbGlvIG1hbCBjdWFu
:::ZG8gZW4KICAgICMgcmVhbGlkYWQgdG9kbyBmdWUgYmllbi4gU2UgcXVlZGFuIGZ1
:::ZXJhIGRlbCByZWdpc3RybzoKICAgIEFWSVNPU19SVUlET1NPUyA9ICgKICAgICAg
:::ICAnTm8gc3VwcG9ydGVkIEphdmFTY3JpcHQgcnVudGltZScsICdFSlMnLAogICAg
:::ICAgICMgIi4uLiBZb3VUdWJlIG1heSBoYXZlIGVuYWJsZWQgdGhlIFNBQlItb25s
:::eSBzdHJlYW1pbmcgZXhwZXJpbWVudC4uLiIKICAgICAgICAnU0FCUicsCiAgICAg
:::ICAgIyAiU29tZSBhbmRyb2lkL2lvcy90diBjbGllbnQgaHR0cHMgZm9ybWF0cyBo
:::YXZlIGJlZW4gc2tpcHBlZC4uLiIKICAgICAgICAnZm9ybWF0cyBoYXZlIGJlZW4g
:::c2tpcHBlZCcsCiAgICAgICAgIyAibXdlYiBjbGllbnQgaHR0cHMgZm9ybWF0cyBy
:::ZXF1aXJlIGEgR1ZTIFBPIFRva2VuLi4uIgogICAgICAgICdQTyBUb2tlbicsCiAg
:::ICApCgogICAgZGVmIHdhcm5pbmcoc2VsZiwgbSk6CiAgICAgICAgbSA9IHN0ciht
:::KS5zdHJpcCgpCiAgICAgICAgaWYgbm90IG0gb3IgYW55KHggaW4gbSBmb3IgeCBp
:::biBzZWxmLkFWSVNPU19SVUlET1NPUyk6CiAgICAgICAgICAgIHJldHVybgogICAg
:::ICAgIGlmIHNlbGYubG9nOgogICAgICAgICAgICBzZWxmLmxvZyhtLCAnYXZpc28n
:::KQoKICAgIGRlZiBlcnJvcihzZWxmLCBtKToKICAgICAgICBtID0gc3RyKG0pLnN0
:::cmlwKCkKICAgICAgICBpZiBtIGFuZCBzZWxmLmxvZzoKICAgICAgICAgICAgc2Vs
:::Zi5sb2cobSwgJ2Vycm9yJykKCgpSRUdJU1RSTyA9IFJlZ2lzdHJvKCkKCiMgdjIu
:::MTI6IGJpdHJhdGUgKGticHMpIGRlbCBhdWRpbyBxdWUgWW91VHViZSBlbnRyZWdv
:::IGVuIGxhIHVsdGltYQojIGRlc2NhcmdhIChsbyByZWxsZW5hIGVsIGhvb2sgZGUg
:::cHJvZ3Jlc28gYWwgdGVybWluYXIgZGUgYmFqYXIpLiBTaXJ2ZQojIHBhcmEgZGVj
:::aXIgZW4gZWwgbWVuc2FqZSBmaW5hbCBzaSBzZSBjb25zaWd1aW8gbGEgY2FsaWRh
:::ZCBwZWRpZGEgbyBzaQojIFlvdVR1YmUgc29sbyB0ZW5pYSB1bmEgZnVlbnRlIGFs
:::Z28gbWFzIGJhamEuCl9GVUVOVEUgPSB7J2Ficic6IE5vbmV9CgpOT01CUkVTX1BQ
:::ID0gewogICAgJ0ZGbXBlZ0V4dHJhY3RBdWRpbyc6ICdDb252aXJ0aWVuZG8gZWwg
:::YXVkaW8gY29uIEZGbXBlZycsCiAgICAnRXh0cmFjdEF1ZGlvJzogJ0NvbnZpcnRp
:::ZW5kbyBlbCBhdWRpbycsCiAgICAnRkZtcGVnVGh1bWJuYWlsc0NvbnZlcnRvcic6
:::ICdDb252aXJ0aWVuZG8gbGEgY2Fyw6F0dWxhIGEgSlBHJywKICAgICdUaHVtYm5h
:::aWxzQ29udmVydG9yJzogJ0NvbnZpcnRpZW5kbyBsYSBjYXLDoXR1bGEnLAogICAg
:::J0ZGbXBlZ01ldGFkYXRhJzogJ0VzY3JpYmllbmRvIGV0aXF1ZXRhcyAodMOtdHVs
:::by9hcnRpc3RhKScsCiAgICAnTWV0YWRhdGEnOiAnRXNjcmliaWVuZG8gZXRpcXVl
:::dGFzJywKICAgICdFbWJlZFRodW1ibmFpbCc6ICdJbmNydXN0YW5kbyBsYSBjYXLD
:::oXR1bGEnLAogICAgJ01vdmVGaWxlcyc6ICdPcmdhbml6YW5kbyBhcmNoaXZvcycs
:::CiAgICAnRkZtcGVnTWVyZ2VyJzogJ1VuaWVuZG8gcGlzdGFzIGRlIHZpZGVvIHkg
:::YXVkaW8nLAogICAgJ01lcmdlcic6ICdVbmllbmRvIHBpc3RhcycsCiAgICAnRkZt
:::cGVnVmlkZW9Db252ZXJ0b3InOiAnQ29udmlydGllbmRvIGVsIHZpZGVvJywKICAg
:::ICdWaWRlb0NvbnZlcnRvcic6ICdDb252aXJ0aWVuZG8gZWwgdmlkZW8nLAp9Cgoj
:::IC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0gZm9ybWF0b3MKRk9STUFUT1MgPSB7CiAgICAnQUFD
:::JzogZGljdCh0ZXh0bz0nQUFDICgubTRhKScsIGV4dD0nbTRhJywKICAgICAgICAg
:::ICAgICAgIGNhbGlkYWRlcz1bJzk2aycsICcxMjhrJ10sIGRlZmVjdG89JzEyOGsn
:::KSwKICAgICdNUDMnOiBkaWN0KHRleHRvPSdNUDMgKC5tcDMpJywgZXh0PSdtcDMn
:::LAogICAgICAgICAgICAgICAgY2FsaWRhZGVzPVsnOTZrJywgJzEyOGsnLCAnMTky
:::aycsICcyNTZrJywgJzMyMGsnXSwKICAgICAgICAgICAgICAgIGRlZmVjdG89JzMy
:::MGsnKSwKICAgICdGTEFDJzogZGljdCh0ZXh0bz0nRkxBQyAoLmZsYWMpJywgZXh0
:::PSdmbGFjJywKICAgICAgICAgICAgICAgICBjYWxpZGFkZXM9WydzaW4gcGVyZGlk
:::YSddLCBkZWZlY3RvPSdzaW4gcGVyZGlkYScpLAogICAgJ1dBVic6IGRpY3QodGV4
:::dG89J1dBViAoLndhdiknLCBleHQ9J3dhdicsCiAgICAgICAgICAgICAgICBjYWxp
:::ZGFkZXM9WydzaW4gcGVyZGlkYSddLCBkZWZlY3RvPSdzaW4gcGVyZGlkYScpLAog
:::ICAgJ1dNQSc6IGRpY3QodGV4dG89J1dNQSAoLndtYSknLCBleHQ9J3dtYScsCiAg
:::ICAgICAgICAgICAgICBjYWxpZGFkZXM9Wyc5NmsnLCAnMTI4ayddLCBkZWZlY3Rv
:::PScxMjhrJyksCiAgICAnQVZJJzogZGljdCh0ZXh0bz0nQVZJIC0gc2hlaWp1IDEu
:::OCIgKDEyOHgxNjApJywgZXh0PSdhdmknLAogICAgICAgICAgICAgICAgY2FsaWRh
:::ZGVzPVsnMTI4eDE2MCDCtyAxNiBmcHMnXSwgZGVmZWN0bz0nMTI4eDE2MCDCtyAx
:::NiBmcHMnKSwKfQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBwcm9ncmVzbwpkZWYgaG9v
:::a3NfZ3VpKGNvbGEpOgogICAgIiIiQ3JlYSBsb3MgaG9va3MgZGUgeXQtZGxwIHF1
:::ZSBwdWJsaWNhbiBldmVudG9zIGVuIGxhIGNvbGEgZGUgbGEgR1VJLiIiIgogICAg
:::ZXN0YWRvID0geyd0aXR1bG8nOiBGYWxzZSwgJ3BwX3VsdCc6IE5vbmV9CgogICAg
:::ZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBt
:::LCB0KSkKCiAgICBkZWYgcHJvZ3Jlc28oZCk6CiAgICAgICAgaWYgZFsnc3RhdHVz
:::J10gPT0gJ2Rvd25sb2FkaW5nJzoKICAgICAgICAgICAgaWYgbm90IGVzdGFkb1sn
:::dGl0dWxvJ106CiAgICAgICAgICAgICAgICBpbmZvID0gZC5nZXQoJ2luZm9fZGlj
:::dCcpIG9yIHt9CiAgICAgICAgICAgICAgICB0ID0gaW5mby5nZXQoJ3RpdGxlJykg
:::b3IgUGF0aChkLmdldCgnZmlsZW5hbWUnKSBvciAnJykuc3RlbQogICAgICAgICAg
:::ICAgICAgaWYgdDoKICAgICAgICAgICAgICAgICAgICBsb2coJ+KZqiAnICsgc3Ry
:::KHQpWzo5MF0sICd0aXR1bG8nKQogICAgICAgICAgICAgICAgICAgIGVzdGFkb1sn
:::dGl0dWxvJ10gPSBUcnVlCiAgICAgICAgICAgIHRvdGFsID0gZC5nZXQoJ3RvdGFs
:::X2J5dGVzJykgb3IgZC5nZXQoJ3RvdGFsX2J5dGVzX2VzdGltYXRlJykgb3IgMAog
:::ICAgICAgICAgICBkb25lID0gZC5nZXQoJ2Rvd25sb2FkZWRfYnl0ZXMnLCAwKQog
:::ICAgICAgICAgICB2ZWwgPSBkLmdldCgnc3BlZWQnKQogICAgICAgICAgICBldGEg
:::PSBkLmdldCgnZXRhJykKICAgICAgICAgICAgaWYgdG90YWw6CiAgICAgICAgICAg
:::ICAgICBwY3QgPSBkb25lIC8gdG90YWwgKiAxMDAKICAgICAgICAgICAgICAgIHRl
:::eHRvID0gZid7cGN0OjUuMWZ9JSDCtyB7Zm10X3RhbShkb25lKX0gLyB7Zm10X3Rh
:::bSh0b3RhbCl9JwogICAgICAgICAgICAgICAgaWYgdmVsOgogICAgICAgICAgICAg
:::ICAgICAgIHRleHRvICs9IGYnIMK3IHtmbXRfdGFtKHZlbCl9L3MnCiAgICAgICAg
:::ICAgICAgICBpZiBldGEgaXMgbm90IE5vbmU6CiAgICAgICAgICAgICAgICAgICAg
:::dGV4dG8gKz0gZicgwrcgcXVlZGFuIHtmbXRfdGllbShldGEpfScKICAgICAgICAg
:::ICAgICAgIGNvbGEucHV0KCgncHJvZycsIHBjdCwgdGV4dG8pKQogICAgICAgICAg
:::ICBlbHNlOgogICAgICAgICAgICAgICAgdiA9IGYne2ZtdF90YW0odmVsKX0vcycg
:::aWYgdmVsIGVsc2UgJycKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgncHJvZycs
:::IE5vbmUsIGYne2ZtdF90YW0oZG9uZSl9IMK3IHt2fScpKQogICAgICAgIGVsaWYg
:::ZFsnc3RhdHVzJ10gPT0gJ2ZpbmlzaGVkJzoKICAgICAgICAgICAgZXN0YWRvWydw
:::cF91bHQnXSA9IE5vbmUKICAgICAgICAgICAgIyB2Mi4xMjogcmVjb3JkYXIgbGEg
:::Y2FsaWRhZCBSRUFMIHF1ZSBZb3VUdWJlIGVudHJlZ28gKGVsCiAgICAgICAgICAg
:::ICMgZm9ybWF0byBlbGVnaWRvIHB1ZWRlIHNlciBtYXMgYmFqbyBxdWUgZWwgcGVk
:::aWRvKS4gU29sbyBzZQogICAgICAgICAgICAjIGFjZXB0YSBzaSB0cmFlIGJpdHJh
:::dGU6IGxhIG1pbmlhdHVyYSBubyBsbyB0cmFlIHkgbm8gZGViZQogICAgICAgICAg
:::ICAjIG1hY2hhY2FyIGVsIHZhbG9yLgogICAgICAgICAgICBpbmYgPSBkLmdldCgn
:::aW5mb19kaWN0Jykgb3Ige30KICAgICAgICAgICAgYWJyID0gaW5mLmdldCgnYWJy
:::Jykgb3IgaW5mLmdldCgndGJyJykKICAgICAgICAgICAgaWYgaXNpbnN0YW5jZShh
:::YnIsIChpbnQsIGZsb2F0KSkgYW5kIGFiciA+IDA6CiAgICAgICAgICAgICAgICBf
:::RlVFTlRFWydhYnInXSA9IGZsb2F0KGFicikKICAgICAgICAgICAgY29sYS5wdXQo
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
:::ICAgICAgICAgIyB2Mi4xMjogbG9zIHBhc29zIGludGVybm9zIHNvbG8gc2UgdmVu
:::IGVuIGxhIGJhcnJhIGRlCiAgICAgICAgICAgICMgcHJvZ3Jlc287IGVsIHJlZ2lz
:::dHJvIHNlIHF1ZWRhIGNvbiBsbyBpbXBvcnRhbnRlCiAgICAgICAgICAgIGNvbGEu
:::cHV0KCgncHJvZycsIE5vbmUsIHRleHRvKSkKCiAgICByZXR1cm4gcHJvZ3Jlc28s
:::IHBvc3Rwcm9jZXNvCgoKZGVmIHRleHRvX2NhbGlkYWQoY2xhdmUsIGNhbGlkYWRf
:::YXJnKToKICAgICIiIlN1ZmlqbyBkZWwgbWVuc2FqZSBmaW5hbDogwr9zZSBjb25z
:::aWd1aW8gbGEgY2FsaWRhZCBwZWRpZGE/CiAgICBDb21wYXJhIGVsIGJpdHJhdGUg
:::ZGVsIGZvcm1hdG8gcXVlIFlvdVR1YmUgZW50cmVnbyAoX0ZVRU5URSwgcXVlCiAg
:::ICByZWxsZW5hIGVsIGhvb2sgZGUgcHJvZ3Jlc28pIGNvbiBsYSBjYWxpZGFkIHNl
:::bGVjY2lvbmFkYS4gU29sbwogICAgYXBsaWNhIGEgbG9zIGZvcm1hdG9zIGNvbiBi
:::aXRyYXRlOiBGTEFDL1dBViBubyB0aWVuZW4gJ2NhbGlkYWQnCiAgICBxdWUgY29t
:::cGFyYXIgeSBlbCBBVkkgZXMgdmlkZW8uIFNpIG5vIHNlIHB1ZG8gc2FiZXIgbGEg
:::ZnVlbnRlLAogICAgbm8gc2UgYW5hZGUgbmFkYSAobWVqb3IgY2FsbGFyIHF1ZSBp
:::bnZlbnRhcikuIiIiCiAgICBlc3RhZG8sIGZ1ZW50ZSwgcGVkaWRhID0gX3ZlcmVk
:::aWN0b19jYWxpZGFkKGNsYXZlLCBjYWxpZGFkX2FyZykKICAgIGlmIGVzdGFkbyA9
:::PSAnYmFqYSc6CiAgICAgICAgcmV0dXJuICgnICDCtyAgY2FsaWRhZCBhbGdvIG3D
:::oXMgYmFqYTogWW91VHViZSBzb2xvIG9mcmVjw61hIH4nCiAgICAgICAgICAgICAg
:::ICBmJ3tpbnQocm91bmQoZnVlbnRlKSl9ayBkZSB7cGVkaWRhfWsnKQogICAgaWYg
:::ZXN0YWRvID09ICdvayc6CiAgICAgICAgcmV0dXJuIGYnICDCtyAge2NsYXZlfSB7
:::cGVkaWRhfWsgKGNhbGlkYWQgc2VsZWNjaW9uYWRhKScKICAgIHJldHVybiAnJwoK
:::CmRlZiBfdmVyZWRpY3RvX2NhbGlkYWQoY2xhdmUsIGNhbGlkYWRfYXJnKToKICAg
:::ICIiInYyLjE0OiBzZXBhcmEgZWwganVpY2lvIGRlbCB0ZXh0by4gRGV2dWVsdmUg
:::KGVzdGFkbywgZnVlbnRlLAogICAgcGVkaWRhKSBjb24gZXN0YWRvIGVuOgogICAg
:::ICAnb2snICAgLT4gbGEgZnVlbnRlIGVudHJlZ2FkYSBhbGNhbnphIChvIGNhc2kp
:::IGxhIGNhbGlkYWQgcGVkaWRhCiAgICAgICdiYWphJyAtPiBZb3VUdWJlIHNvbG8g
:::b2ZyZWNpbyB1bmEgZnVlbnRlIGNsYXJhbWVudGUgbWFzIGJhamEKICAgICAgJycg
:::ICAgIC0+IG5vIHNlIHB1ZWRlIGp1emdhciAoZm9ybWF0byBzaW4gYml0cmF0ZSBv
:::IGZhbHRhIGVsIGRhdG8pIiIiCiAgICBpZiBjbGF2ZSBub3QgaW4gKCdBQUMnLCAn
:::TVAzJywgJ1dNQScpOgogICAgICAgIHJldHVybiAnJywgTm9uZSwgMAogICAgdHJ5
:::OgogICAgICAgIHBlZGlkYSA9IGludChyZS5zdWIocidbXjAtOV0nLCAnJywgc3Ry
:::KGNhbGlkYWRfYXJnKSkpCiAgICBleGNlcHQgVmFsdWVFcnJvcjoKICAgICAgICBy
:::ZXR1cm4gJycsIE5vbmUsIDAKICAgIGlmIHBlZGlkYSA8PSAwOgogICAgICAgIHJl
:::dHVybiAnJywgTm9uZSwgMAogICAgZnVlbnRlID0gX0ZVRU5URS5nZXQoJ2Ficicp
:::CiAgICBpZiBub3QgZnVlbnRlOgogICAgICAgIHJldHVybiAnJywgTm9uZSwgcGVk
:::aWRhCiAgICBpZiBmdWVudGUgPCBwZWRpZGEgKiAwLjk6CiAgICAgICAgcmV0dXJu
:::ICdiYWphJywgZmxvYXQoZnVlbnRlKSwgcGVkaWRhCiAgICByZXR1cm4gJ29rJywg
:::ZmxvYXQoZnVlbnRlKSwgcGVkaWRhCgoKZGVmIF9yZWVtcGxhemFyX2FyY2hpdm8o
:::dmllam8sIG51ZXZvLCBmaW5hbCk6CiAgICAiIiJ2Mi4xNDogc3VzdGl0dXllIGxh
:::IGRlc2NhcmdhIHZpZWphIHBvciBsYSBkZWwgcmVpbnRlbnRvLiBOdW5jYQogICAg
:::bGV2YW50YTogc2kgYWxnbyBmYWxsYSBzZSBjb25zZXJ2YSBsYSB2aWVqYSAobm8g
:::c2UgcGllcmRlIG5hZGEpLgogICAgRGV2dWVsdmUgVHJ1ZSBzaSBlbCByZWVtcGxh
:::em8gc2FsaW8gKHVzYXIgJ2ZpbmFsJykuIiIiCiAgICB0cnk6CiAgICAgICAgaWYg
:::dmllam8uZXhpc3RzKCk6CiAgICAgICAgICAgIHZpZWpvLnVubGluaygpCiAgICAg
:::ICAgc2h1dGlsLm1vdmUoc3RyKG51ZXZvKSwgc3RyKGZpbmFsKSkKICAgICAgICBy
:::ZXR1cm4gVHJ1ZQogICAgZXhjZXB0IE9TRXJyb3I6CiAgICAgICAgdHJ5OgogICAg
:::ICAgICAgICBpZiBudWV2by5leGlzdHMoKToKICAgICAgICAgICAgICAgIG51ZXZv
:::LnVubGluaygpCiAgICAgICAgZXhjZXB0IE9TRXJyb3I6CiAgICAgICAgICAgIHBh
:::c3MKICAgICAgICByZXR1cm4gRmFsc2UKCgpkZWYgcmVpbnRlbnRvX2NhbGlkYWQo
:::c2VsZiwgdXJsLCBjbGF2ZSwgY2FsaWRhZF9hcmcsIGVtYmViZXIsIGRlc3Rpbm8s
:::CiAgICAgICAgICAgICAgICAgICAgICBhcmNoaXZvLCBjb2xhKToKICAgICIiInYy
:::LjE0OiBzaSBsYSBjYW5jaW9uIHF1ZWRvIGNvbiB1bmEgY2FsaWRhZCBtYXMgYmFq
:::YSBxdWUgbGEKICAgIHNlbGVjY2lvbmFkYSwgcHJlZ3VudGEgYWwgdXN1YXJpbyBx
:::dWUgaGFjZXI6CiAgICAgIC0gUmVpbnRlbnRhcjogYmFqYSBvdHJhIHZleiBwb3Ig
:::b3RyYXMgdmlhcyAoY29tYm8gYW5kcm9pZF92ci8KICAgICAgICBhbmRyb2lkL2lv
:::cywgcXVlIGEgdmVjZXMgdGllbmUgbWVqb3JlcyBmdWVudGVzKSBhIHVuYSBjYXJw
:::ZXRhCiAgICAgICAgdGVtcG9yYWwgeSBzZSBxdWVkYSBjb24gbGEgTUVKT1IgZGUg
:::bGFzIGRvcyBkZXNjYXJnYXMuIFNpIGVsCiAgICAgICAgcmVpbnRlbnRvIGZhbGxh
:::LCBsYSBwcmltZXJhIG5vIHNlIHRvY2EuCiAgICAgIC0gQ29uc2VydmFyOiBkZWph
:::IGxhIGRlc2NhcmdhIHRhbCBjdWFsLgogICAgRGV2dWVsdmUgbGEgcnV0YSBmaW5h
:::bCAobGEgbWlzbWEgbyBsYSBtZWpvcmFkYSkuIiIiCiAgICBkZWYgbG9nKG0sIHQ9
:::J2luZm8nKToKICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgIGVz
:::dGFkbywgZnVlbnRlMSwgcGVkaWRhID0gX3ZlcmVkaWN0b19jYWxpZGFkKGNsYXZl
:::LCBjYWxpZGFkX2FyZykKICAgIGlmIGVzdGFkbyAhPSAnYmFqYScgb3Igbm90IGFy
:::Y2hpdm86CiAgICAgICAgcmV0dXJuIGFyY2hpdm8KICAgIHJlc3AgPSBxdWV1ZS5R
:::dWV1ZSgpCiAgICBjb2xhLnB1dCgoJ3ByZWd1bnRhcicsICdNdXNpa0FMQU4g4oCU
:::IGNhbGlkYWQgbcOhcyBiYWphJywKICAgICAgICAgICAgICBmJ8Kre2FyY2hpdm8u
:::c3RlbVs6NjBdfcK7IHNlIGRlc2NhcmfDsyBjb24gdW5hIGZ1ZW50ZSBkZSAnCiAg
:::ICAgICAgICAgICAgZid+e2ludChyb3VuZChmdWVudGUxKSl9ayBlbiB2ZXogZGUg
:::bG9zIHtwZWRpZGF9ayAnCiAgICAgICAgICAgICAgJ3NlbGVjY2lvbmFkb3MuXG5c
:::bicKICAgICAgICAgICAgICAnwr9MbyBpbnRlbnRvIGRlIG51ZXZvIHBvciBzaSBh
:::aG9yYSBZb3VUdWJlIG9mcmVjZSBsYSAnCiAgICAgICAgICAgICAgJ2NhbGlkYWQg
:::c2VsZWNjaW9uYWRhP1xuXG4nCiAgICAgICAgICAgICAgJyAgU8ONICDihpIgIHJl
:::aW50ZW50YXIgeSBxdWVkYXJzZSBjb24gbGEgbWVqb3JcbicKICAgICAgICAgICAg
:::ICAnICBOTyAg4oaSICBjb25zZXJ2YXIgZXN0YSBkZXNjYXJnYScsIHJlc3ApKQog
:::ICAgdHJ5OgogICAgICAgIHF1aWVyZSA9IGJvb2wocmVzcC5nZXQodGltZW91dD02
:::MDApKQogICAgZXhjZXB0IHF1ZXVlLkVtcHR5OgogICAgICAgIHF1aWVyZSA9IEZh
:::bHNlCiAgICBpZiBub3QgcXVpZXJlOgogICAgICAgIGxvZygnU2UgY29uc2VydmEg
:::bGEgZGVzY2FyZ2EgY29uIGxhIGNhbGlkYWQgY29uc2VndWlkYS4nLCAnZ3Jpcycp
:::CiAgICAgICAgcmV0dXJuIGFyY2hpdm8KICAgIGxvZygn4oa7IFJlaW50ZW50YW5k
:::byBwb3Igb3RyYXMgdsOtYXMgcGFyYSBidXNjYXIgbGEgY2FsaWRhZCAnCiAgICAg
:::ICAgZidzZWxlY2Npb25hZGEgKHtwZWRpZGF9aykuLi4nLCAnaW5mbycpCiAgICB0
:::bXAgPSBkZXN0aW5vIC8gJy5tdXNpa2FsYW5fcmVpbnRlbnRvJwogICAgdHJ5Ogog
:::ICAgICAgIHRtcC5ta2RpcihwYXJlbnRzPVRydWUsIGV4aXN0X29rPVRydWUpCiAg
:::ICBleGNlcHQgT1NFcnJvciBhcyBlOgogICAgICAgIGxvZygnTm8gc2UgcHVkbyBj
:::cmVhciBsYSBjYXJwZXRhIHRlbXBvcmFsIGRlbCByZWludGVudG86ICcKICAgICAg
:::ICAgICAgKyBzdHIoZSksICdhdmlzbycpCiAgICAgICAgcmV0dXJuIGFyY2hpdm8K
:::ICAgIF9BTlRJX0JPVFsnY29tYm8nXSA9IDEgICAgIyBhbmRyb2lkX3ZyL2FuZHJv
:::aWQvaW9zOiBpbnZlbnRhcmlvIGRpc3RpbnRvCiAgICB0cnk6CiAgICAgICAgdHJ5
:::OgogICAgICAgICAgICBhcmNoaXZvMiA9IHNlbGYuX2Rlc2Nhcmdhcl91bmEodXJs
:::LCBjbGF2ZSwgY2FsaWRhZF9hcmcsCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICBlbWJlYmVyLCB0bXAsIGNvbGEpCiAgICAgICAgZXhj
:::ZXB0IEV4Y2VwdGlvbiBhcyBlOgogICAgICAgICAgICBpZiBfZXNfYmxvcXVlb19i
:::b3Qoc3RyKGUpKToKICAgICAgICAgICAgICAgIGxvZygnRWwgcmVpbnRlbnRvIGNo
:::b2PDsyBjb24gbGEgdmVyaWZpY2FjacOzbiBhbnRpLWJvdCBkZSAnCiAgICAgICAg
:::ICAgICAgICAgICAgJ1lvdVR1YmUuIFNlIGNvbnNlcnZhIGxhIGRlc2NhcmdhIGFu
:::dGVyaW9yLicsICdhdmlzbycpCiAgICAgICAgICAgICAgICBsb2coJ0NvbnNlam86
:::IGVuIMKrU2kgWW91VHViZSBibG9xdWVhOsK7IGVsaWdlIFVzYXIgJwogICAgICAg
:::ICAgICAgICAgICAgICdjb29raWVzIGRlIHR1IG5hdmVnYWRvciB5IHZ1ZWx2ZSBh
:::IGRlc2NhcmdhcjogY29uICcKICAgICAgICAgICAgICAgICAgICAndHUgc2VzacOz
:::biBhYmllcnRhIHN1ZWxlIGRhciBsYSBjYWxpZGFkIGJ1ZW5hLicsCiAgICAgICAg
:::ICAgICAgICAgICAgJ2dyaXMnKQogICAgICAgICAgICBlbHNlOgogICAgICAgICAg
:::ICAgICAgbG9nKCdFbCByZWludGVudG8gZmFsbMOzOiAnCiAgICAgICAgICAgICAg
:::ICAgICAgKyBzdHIoc2VsZi5fbXNnX2Vycm9yKGUpKVs6MTIwXSwgJ2F2aXNvJykK
:::ICAgICAgICAgICAgICAgIGxvZygnU2UgY29uc2VydmEgbGEgZGVzY2FyZ2EgYW50
:::ZXJpb3IuJywgJ2dyaXMnKQogICAgICAgICAgICByZXR1cm4gYXJjaGl2bwogICAg
:::ICAgIGlmIG5vdCAoYXJjaGl2bzIgYW5kIFBhdGgoYXJjaGl2bzIpLmV4aXN0cygp
:::KToKICAgICAgICAgICAgbG9nKCdFbCByZWludGVudG8gbm8gcHJvZHVqbyBhcmNo
:::aXZvOyBzZSBjb25zZXJ2YSBsYSAnCiAgICAgICAgICAgICAgICAnZGVzY2FyZ2Eg
:::YW50ZXJpb3IuJywgJ2F2aXNvJykKICAgICAgICAgICAgcmV0dXJuIGFyY2hpdm8K
:::ICAgICAgICBhcmNoaXZvMiA9IFBhdGgoYXJjaGl2bzIpCiAgICAgICAgZnVlbnRl
:::MiA9IF9GVUVOVEUuZ2V0KCdhYnInKSBvciAwLjAKICAgICAgICBmaW5hbCA9IGRl
:::c3Rpbm8gLyBhcmNoaXZvMi5uYW1lCiAgICAgICAgaWYgZnVlbnRlMiA+PSBwZWRp
:::ZGEgKiAwLjk6CiAgICAgICAgICAgIGlmIF9yZWVtcGxhemFyX2FyY2hpdm8oYXJj
:::aGl2bywgYXJjaGl2bzIsIGZpbmFsKToKICAgICAgICAgICAgICAgIGxvZyhmJ+Kc
:::lCDCoUFob3JhIHPDrSEgIHtmaW5hbC5uYW1lfScKICAgICAgICAgICAgICAgICAg
:::ICBmJ3t0ZXh0b19jYWxpZGFkKGNsYXZlLCBjYWxpZGFkX2FyZyl9JywgJ29rJykK
:::ICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgIGxvZygnTm8gc2UgcHVk
:::byByZWVtcGxhemFyIGVsIGFyY2hpdm87IHNlIGNvbnNlcnZhIGxhICcKICAgICAg
:::ICAgICAgICAgICAgICAnZGVzY2FyZ2EgYW50ZXJpb3IuJywgJ2F2aXNvJykKICAg
:::ICAgICAgICAgcmV0dXJuIGZpbmFsIGlmIGZpbmFsLmV4aXN0cygpIGVsc2UgYXJj
:::aGl2bwogICAgICAgIGlmIGZ1ZW50ZTIgPiBmdWVudGUxICogMS4wNToKICAgICAg
:::ICAgICAgaWYgX3JlZW1wbGF6YXJfYXJjaGl2byhhcmNoaXZvLCBhcmNoaXZvMiwg
:::ZmluYWwpOgogICAgICAgICAgICAgICAgbG9nKGYn4pyUIE1lam9yw7MgYSB+e2lu
:::dChyb3VuZChmdWVudGUyKSl9aywgcGVybyBZb3VUdWJlICcKICAgICAgICAgICAg
:::ICAgICAgICBmJ25vIHRpZW5lIHtwZWRpZGF9ayBhaG9yYTsgc2UgcXVlZMOzIGNv
:::biBsYSBtZWpvci4nLAogICAgICAgICAgICAgICAgICAgICdhdmlzbycpCiAgICAg
:::ICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICBsb2coJ05vIHNlIHB1ZG8gcmVl
:::bXBsYXphciBlbCBhcmNoaXZvOyBzZSBjb25zZXJ2YSBsYSAnCiAgICAgICAgICAg
:::ICAgICAgICAgJ2Rlc2NhcmdhIGFudGVyaW9yLicsICdhdmlzbycpCiAgICAgICAg
:::ICAgIHJldHVybiBmaW5hbCBpZiBmaW5hbC5leGlzdHMoKSBlbHNlIGFyY2hpdm8K
:::ICAgICAgICB0cnk6CiAgICAgICAgICAgIGFyY2hpdm8yLnVubGluaygpCiAgICAg
:::ICAgZXhjZXB0IE9TRXJyb3I6CiAgICAgICAgICAgIHBhc3MKICAgICAgICBsb2co
:::ZidZb3VUdWJlIHNpZ3VlIHNpbiBvZnJlY2VyIHtwZWRpZGF9azsgc2UgY29uc2Vy
:::dmEgbGEgJwogICAgICAgICAgICBmJ2Rlc2NhcmdhICh+e2ludChyb3VuZChmdWVu
:::dGUxKSl9aykuJywgJ2dyaXMnKQogICAgICAgIHJldHVybiBhcmNoaXZvCiAgICBm
:::aW5hbGx5OgogICAgICAgIF9BTlRJX0JPVFsnY29tYm8nXSA9IDAKICAgICAgICBz
:::aHV0aWwucm10cmVlKHRtcCwgaWdub3JlX2Vycm9ycz1UcnVlKQoKCiMgLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBhbnRpLWJsb3F1
:::ZW8gZGUgWW91VHViZSAodjIuOSkKIyBDdWFuZG8gWW91VHViZSBkZXNjb25mw61h
:::IGRlIHVuYSByZWQgKHdpZmkgY29tcGFydGlkbywgZGF0b3MgbcOzdmlsZXMsIFZQ
:::TgojIG8gbXVjaGFzIGRlc2NhcmdhcyBzZWd1aWRhcykgcmVzcG9uZGUgYSBsb3Mg
:::Y2xpZW50ZXMgd2ViIGNvbiAiU2lnbiBpbiB0bwojIGNvbmZpcm0geW91J3JlIG5v
:::dCBhIGJvdCIgbyBIVFRQIDQyOS4gRGVmZW5zYSBlbiBjYXBhczoKIyAgIDEpIFBv
:::ciBkZWZlY3RvIGxvcyBmb3JtYXRvcyBzZSBwaWRlbiBjb24gbG9zIGNsaWVudGVz
:::IGRlIGxhcyBBUFBTCiMgICAgICBtw7N2aWxlcyAoYW5kcm9pZC9pb3MvbXdlYiks
:::IHF1ZSBlbiBsYSBtYXlvcsOtYSBkZSBsYXMgcmVkZXMgbm8gcGFzYW4KIyAgICAg
:::IHBvciBlc2UgY2hlcXVlby4KIyAgIDIpIFNpIGF1biBhc8OtIFlvdVR1YmUgaW5z
:::aXN0ZSwgbGEgZGVzY2FyZ2Egc2UgcmVpbnRlbnRhIFVOQSB2ZXogc29sYQojICAg
:::ICAgY29uIGVsIGNvbWJvIDIgKGFuZHJvaWRfdnIvYW5kcm9pZC9pb3MsIHNpbiBj
:::bGllbnRlcyB3ZWIpIHRyYXMgdW5hCiMgICAgICBwZXF1ZcOxYSBwYXVzYSBwYXJh
:::IGRlamFyIGVuZnJpYXIgZWwgNDI5LgojICAgMykgw5psdGltYSBsw61uZWE6IGVs
:::IGRlc3BsZWdhYmxlICJTaSBZb3VUdWJlIGJsb3F1ZWE6IiBwZXJtaXRlIHVzYXIg
:::bGFzCiMgICAgICBDT09LSUVTIGRlbCBuYXZlZ2Fkb3IgZGVsIHVzdWFyaW8gKGNv
:::biBzZXNpw7NuIGFiaWVydGEgWW91VHViZSBubwojICAgICAgcGlkZSB2ZXJpZmlj
:::YWNpw7NuKS4gRXMgbGEgdsOtYSBvZmljaWFsIHJlY29tZW5kYWRhIHBvciB5dC1k
:::bHAuCkNPTUJPU19BTlRJX0JPVCA9ICgKICAgICgnYW5kcm9pZCcsICdpb3MnLCAn
:::bXdlYicpLAogICAgKCdhbmRyb2lkX3ZyJywgJ2FuZHJvaWQnLCAnaW9zJyksCikK
:::TkFWRUdBRE9SRVNfQ09PS0lFUyA9ICgnZmlyZWZveCcsICdjaHJvbWUnLCAnZWRn
:::ZScsICdicmF2ZScsICdvcGVyYScsCiAgICAgICAgICAgICAgICAgICAgICAgJ3Zp
:::dmFsZGknKQpfQU5USV9CT1QgPSB7J2NvbWJvJzogMH0gICAgICAjIGNvbWJvIGVu
:::IGN1cnNvIChkaWN0IG11dGFibGUgPSBnbG9iYWwpCgoKZGVmIF9hbnRpX2JvdChv
:::KToKICAgICIiIklueWVjdGEgZW4gbGFzIG9wY2lvbmVzIGRlIHl0LWRscCBsYSB2
:::w61hIGFudGktYmxvcXVlbyBlbiBjdXJzby4iIiIKICAgIG9bJ2V4dHJhY3Rvcl9h
:::cmdzJ10gPSB7J3lvdXR1YmUnOiB7J3BsYXllcl9jbGllbnQnOgogICAgICAgICAg
:::ICAgICAgICAgICAgICAgIGxpc3QoQ09NQk9TX0FOVElfQk9UW19BTlRJX0JPVFsn
:::Y29tYm8nXV0pfX0KICAgIG9bJ2ZvcmNlaXB2NCddID0gVHJ1ZQogICAgbmF2ZWdh
:::ZG9yID0gc3RyKEFKVVNURVMuZ2V0KCdjb29raWVzJywgJycpIG9yICcnKS5zdHJp
:::cCgpLmxvd2VyKCkKICAgIGlmIG5hdmVnYWRvciBpbiBOQVZFR0FET1JFU19DT09L
:::SUVTOgogICAgICAgIG9bJ2Nvb2tpZXNmcm9tYnJvd3NlciddID0gKG5hdmVnYWRv
:::ciwpCiAgICByZXR1cm4gbwoKCmRlZiBfZXNfYmxvcXVlb19ib3QodGV4dG8pOgog
:::ICAgIiIiVHJ1ZSBzaSBlbCBlcnJvciBkZSB5dC1kbHAgZXMgZWwgY2hlcXVlbyBh
:::bnRpLWJvdCBvIHVuIDQyOS4iIiIKICAgIHQgPSAodGV4dG8gb3IgJycpLmxvd2Vy
:::KCkKICAgIHJldHVybiAoJ25vdCBhIGJvdCcgaW4gdCBvciAnc2lnbiBpbiB0byBj
:::b25maXJtJyBpbiB0CiAgICAgICAgICAgIG9yICd0b28gbWFueSByZXF1ZXN0cycg
:::aW4gdCBvciAnaHR0cCBlcnJvciA0MjknIGluIHQKICAgICAgICAgICAgb3IgJyBl
:::cnJvciA0MjknIGluIHQpCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIG9wY2lvbmVzCmRl
:::ZiBvcHRzX2Jhc2UoY2FycGV0YSwgY29sYSk6CiAgICBwcm9ncmVzbywgcG9zdHBy
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
:::b10sCiAgICB9CiAgICBpZiBGRk1QRUc6CiAgICAgICAgb1snZmZtcGVnX2xvY2F0
:::aW9uJ10gPSBzdHIoRkZNUEVHLnBhcmVudCkKICAgIF9hbnRpX2JvdChvKQogICAg
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
:::ICAgcGFzcwoKCmRlZiBfbWluaWF0dXJhX2J5dGVzKGNhcnBldGEsIGFyY2hpdm8p
:::OgogICAgIiIiTGVlIGxvcyBieXRlcyBkZSBsYSBtaW5pYXR1cmEgcXVlIHl0LWRs
:::cCBkZWpvIGp1bnRvIGFsIGFyY2hpdm8gZmluYWwuIiIiCiAgICBpZiBub3QgYXJj
:::aGl2bzoKICAgICAgICByZXR1cm4gTm9uZQogICAgZm9yIGV4dCBpbiAoJy5qcGcn
:::LCAnLmpwZWcnLCAnLndlYnAnLCAnLnBuZycpOgogICAgICAgIHQgPSBhcmNoaXZv
:::LndpdGhfc3VmZml4KGV4dCkKICAgICAgICBpZiB0LmV4aXN0cygpOgogICAgICAg
:::ICAgICB0cnk6CiAgICAgICAgICAgICAgICByZXR1cm4gdC5yZWFkX2J5dGVzKCkK
:::ICAgICAgICAgICAgZXhjZXB0IE9TRXJyb3I6CiAgICAgICAgICAgICAgICBwYXNz
:::CiAgICByZXR1cm4gTm9uZQoKCmRlZiBfZXNfanBnKGRhdG9zKToKICAgIHJldHVy
:::biBib29sKGRhdG9zKSBhbmQgZGF0b3NbOjNdID09IGInXHhmZlx4ZDhceGZmJwoK
:::CmRlZiBfYV9qcGcoZGF0b3MpOgogICAgIiIiQ29udmllcnRlIGxvcyBieXRlcyBk
:::ZSB1bmEgaW1hZ2VuICh3ZWJwL3BuZy8uLi4pIGEgSlBFRyBjb24gRkZtcGVnLgoK
:::ICAgIExvcyByZXByb2R1Y3RvcmVzIGJhcmF0b3MgKHRpcG8gc2hlaWp1KSBzdWVs
:::ZW4gbGVlciBzb2xvIEpQRUc6IGxhCiAgICBtaW5pYXR1cmEgZGUgWW91VHViZSB2
:::aWVuZSBlbiBXZWJQIHkgRW1iZWRUaHVtYm5haWwgZGUgeXQtZGxwIGxhCiAgICBj
:::b252aWVydGUgYSBQTkcgKCJQTkcgaXMgcHJlZmVycmVkIHNpbmNlIEpQRUcgaXMg
:::bG9zc3kiKSwgYXNpIHF1ZQogICAgYXF1aSBub3MgYXNlZ3VyYW1vcyBub3NvdHJv
:::cyBkZSBxdWUgYWNhYmUgZW4gSlBFRy4iIiIKICAgIGlmIG5vdCBkYXRvcyBvciBu
:::b3QgRkZNUEVHOgogICAgICAgIHJldHVybiBOb25lCiAgICBiYXNlID0gUGF0aCh0
:::ZW1wZmlsZS5nZXR0ZW1wZGlyKCkpIC8gKCdtdXNpa2FsYW5fY2FyYXR1bGFfJWQn
:::ICUgb3MuZ2V0cGlkKCkpCiAgICBvcmlnZW4sIGRlc3Rpbm8gPSBiYXNlLndpdGhf
:::c3VmZml4KCcub3JpZycpLCBiYXNlLndpdGhfc3VmZml4KCcuanBnJykKICAgIHRy
:::eToKICAgICAgICBvcmlnZW4ud3JpdGVfYnl0ZXMoZGF0b3MpCiAgICAgICAgciA9
:::IHN1YnByb2Nlc3MucnVuKAogICAgICAgICAgICBbc3RyKEZGTVBFRyksICcteScs
:::ICctbG9nbGV2ZWwnLCAnZXJyb3InLCAnLWknLCBzdHIob3JpZ2VuKSwKICAgICAg
:::ICAgICAgICctcTp2JywgJzInLCBzdHIoZGVzdGlubyldLAogICAgICAgICAgICBz
:::dGRvdXQ9c3VicHJvY2Vzcy5ERVZOVUxMLCBzdGRlcnI9c3VicHJvY2Vzcy5ERVZO
:::VUxMKQogICAgICAgIGlmIHIucmV0dXJuY29kZSA9PSAwIGFuZCBkZXN0aW5vLmV4
:::aXN0cygpOgogICAgICAgICAgICBqcGcgPSBkZXN0aW5vLnJlYWRfYnl0ZXMoKQog
:::ICAgICAgICAgICBpZiBfZXNfanBnKGpwZyk6CiAgICAgICAgICAgICAgICByZXR1
:::cm4ganBnCiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHBhc3MKICAgIGZp
:::bmFsbHk6CiAgICAgICAgZm9yIGYgaW4gKG9yaWdlbiwgZGVzdGlubyk6CiAgICAg
:::ICAgICAgIHRyeToKICAgICAgICAgICAgICAgIGYudW5saW5rKCkKICAgICAgICAg
:::ICAgZXhjZXB0IE9TRXJyb3I6CiAgICAgICAgICAgICAgICBwYXNzCiAgICByZXR1
:::cm4gTm9uZQoKCmRlZiBfd21fcGljdHVyZShqcGcsIGRlc2NyaXBjaW9uPScnKToK
:::ICAgICIiIkVtcGFxdWV0YSB1bm9zIGJ5dGVzIEpQRUcgZW4gZWwgYXRyaWJ1dG8g
:::V00vUGljdHVyZSBkZWwgY29udGVuZWRvcgogICAgQVNGICh0aXBvIDMgPSBwb3J0
:::YWRhIGZyb250YWwpLCBjb21vIGhhY2lhIGVsIHNjcmlwdCBhbnRpZ3VvLiIiIgog
:::ICAgZGVmIHUxNihzKToKICAgICAgICByZXR1cm4gc3RyKHMpLmVuY29kZSgndXRm
:::LTE2LWxlJykgKyBiJ1x4MDBceDAwJwoKICAgIG1pbWUgPSB1MTYoJ2ltYWdlL2pw
:::ZWcnKQogICAgZGVzYyA9IHUxNihkZXNjcmlwY2lvbikKICAgIHJldHVybiAoYidc
:::eDAzJyArIGxlbihtaW1lKS50b19ieXRlcyg0LCAnbGl0dGxlJykgKyBtaW1lCiAg
:::ICAgICAgICAgICsgbGVuKGRlc2MpLnRvX2J5dGVzKDQsICdsaXR0bGUnKSArIGRl
:::c2MgKyBqcGcpCgoKZGVmIF9tb292X3ByaW1lcm8ocnV0YSk6CiAgICAiIiJUcnVl
:::IHNpIGVsIGF0b21vICdtb292JyBlc3RhIEFOVEVTIHF1ZSAnbWRhdCcgZW50cmUg
:::bGFzIGNhamFzCiAgICB0b3AtbGV2ZWwgZGVsIE1QNC9NNEEgKGVsIG9yZGVuICdm
:::YXN0c3RhcnQnIGRlIGlUdW5lcykuIFNvbG8gbGVlCiAgICBsYSBjYWJlY2VyYSAo
:::NCBNQikgY29uIHVuIHBhc2UgZGUgdGFtYW5vczogbm8gY2FyZ2EgZWwgYXJjaGl2
:::by4iIiIKICAgIHRyeToKICAgICAgICB3aXRoIG9wZW4ocnV0YSwgJ3JiJykgYXMg
:::Zmg6CiAgICAgICAgICAgIGNhYiA9IGZoLnJlYWQoNCA8PCAyMCkKICAgIGV4Y2Vw
:::dCBPU0Vycm9yOgogICAgICAgIHJldHVybiBGYWxzZQogICAgcG9zLCBmaW4gPSAw
:::LCBsZW4oY2FiKQogICAgd2hpbGUgcG9zICsgOCA8PSBmaW46CiAgICAgICAgdGlw
:::byA9IGNhYltwb3MgKyA0OnBvcyArIDhdCiAgICAgICAgaWYgdGlwbyBpbiAoYidt
:::b292JywgYidtZGF0Jyk6CiAgICAgICAgICAgIHJldHVybiB0aXBvID09IGInbW9v
:::dicKICAgICAgICBzaXplID0gaW50LmZyb21fYnl0ZXMoY2FiW3Bvczpwb3MgKyA0
:::XSwgJ2JpZycpCiAgICAgICAgaWYgc2l6ZSA9PSAxOiAgICAgICAgICAgICAgICAg
:::ICAgICAgIyBsYXJnZXNpemUgZGUgNjQgYml0cwogICAgICAgICAgICBpZiBwb3Mg
:::KyAxNiA+IGZpbjoKICAgICAgICAgICAgICAgIHJldHVybiBGYWxzZQogICAgICAg
:::ICAgICBzaXplID0gaW50LmZyb21fYnl0ZXMoY2FiW3BvcyArIDg6cG9zICsgMTZd
:::LCAnYmlnJykKICAgICAgICAgICAgaWYgc2l6ZSA8IDE2OgogICAgICAgICAgICAg
:::ICAgcmV0dXJuIEZhbHNlCiAgICAgICAgZWxpZiBzaXplIDwgODogICAgICAgICAg
:::ICAgICAgICAgICAgIyBjYWphIHJvdGEgbyBFT0YKICAgICAgICAgICAgcmV0dXJu
:::IEZhbHNlCiAgICAgICAgcG9zICs9IHNpemUKICAgIHJldHVybiBGYWxzZQoKCmRl
:::ZiBfbW9vdl9hbF9wcmluY2lwaW8ocCk6CiAgICAiIiJ2Mi44OiBkZWphIGVsIGF0
:::b21vIG1vb3YgKHF1ZSBsbGV2YSBsYXMgZXRpcXVldGFzKSBhbCBQUklOQ0lQSU8K
:::ICAgIGRlbCAubTRhLCBjb21vIGhhY2UgaVR1bmVzICgnZmFzdHN0YXJ0JykuCgog
:::ICAgRkZtcGVnIGVzY3JpYmUgZWwgTTRBIGNvbiBtb292IEFMIEZJTkFMLCBkZXRy
:::YXMgZGUgdG9kbyBlbCBhdWRpbwogICAgKG1kYXQpLiBFbCBNUDMgZGUgcmVmZXJl
:::bmNpYSBxdWUgZWwgcmVwcm9kdWN0b3IgZGVsIHVzdWFyaW8gc2kgbGVlCiAgICBs
:::bGV2YSBzdSBJRDN2MiBhbCBpbmljaW8gZGVsIGFyY2hpdm8sIHkgbG9zIHJlcHJv
:::ZHVjdG9yZXMgYmFyYXRvcwogICAgc3VlbGVuIGJ1c2NhciBsYXMgZXRpcXVldGFz
:::IGVzY2FuZWFuZG8gc29sbyBsYSBjYWJlY2VyYSBkZWwKICAgIGFyY2hpdm86IHBv
:::ciBlc28gbW9zdHJhYmFuICd1bmtub3duJyBhdW5xdWUgZWwgTTRBIGVzdHV2aWVy
:::YQogICAgcGVyZmVjdGFtZW50ZSBldGlxdWV0YWRvIChhdG9tcyBpbHN0IGVzdGFu
:::ZGFyLCB2ZXJpZmljYWRvIGVuCiAgICB2Mi43KS4gQ29uIC1tb3ZmbGFncyArZmFz
:::dHN0YXJ0IGVsIG1vb3YgZW50ZXJvICh5IGRlbnRybwogICAgbW9vdi51ZHRhLm1l
:::dGEuaWxzdCBjb24gdGl0dWxvL2FydGlzdGEvYWxidW0vY292cikgcGFzYSBkZWxh
:::bnRlCiAgICBkZWwgbWRhdCBTSU4gcmVjb2RpZmljYXIgbmFkYSAoLWMgY29weSku
:::IFNpIGFsZ28gZmFsbGEgc2UgZGV2dWVsdmUKICAgIEZhbHNlIHkgZWwgYXJjaGl2
:::byBxdWVkYSBjb21vIGVzdGFiYTogZXN0byBudW5jYSBkZWJlIHJvbXBlciBsYQog
:::ICAgZGVzY2FyZ2EgbmkgbGFzIGV0aXF1ZXRhcyB5YSBlc2NyaXRhcy4iIiIKICAg
:::IGlmIG5vdCBGRk1QRUcgb3IgX21vb3ZfcHJpbWVybyhwKToKICAgICAgICByZXR1
:::cm4gRmFsc2UKICAgIHRtcCA9IHAud2l0aF9uYW1lKHAuc3RlbSArICcuZmFzdHN0
:::YXJ0Lm00YScpCiAgICB0cnk6CiAgICAgICAgciA9IHN1YnByb2Nlc3MucnVuKAog
:::ICAgICAgICAgICBbc3RyKEZGTVBFRyksICcteScsICctbG9nbGV2ZWwnLCAnZXJy
:::b3InLCAnLWknLCBzdHIocCksCiAgICAgICAgICAgICAnLW1hcCcsICcwJywgJy1j
:::JywgJ2NvcHknLCAnLW1vdmZsYWdzJywgJytmYXN0c3RhcnQnLAogICAgICAgICAg
:::ICAgc3RyKHRtcCldLAogICAgICAgICAgICBzdGRvdXQ9c3VicHJvY2Vzcy5ERVZO
:::VUxMLCBzdGRlcnI9c3VicHJvY2Vzcy5ERVZOVUxMKQogICAgICAgIGlmIChyLnJl
:::dHVybmNvZGUgPT0gMCBhbmQgdG1wLmV4aXN0cygpCiAgICAgICAgICAgICAgICBh
:::bmQgX21vb3ZfcHJpbWVybyh0bXApCiAgICAgICAgICAgICAgICBhbmQgdG1wLnN0
:::YXQoKS5zdF9zaXplICogMTAwCiAgICAgICAgICAgICAgICA+PSBwLnN0YXQoKS5z
:::dF9zaXplICogOTApOgogICAgICAgICAgICBvcy5yZXBsYWNlKHRtcCwgcCkKICAg
:::ICAgICAgICAgcmV0dXJuIFRydWUKICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAg
:::ICAgcGFzcwogICAgZmluYWxseToKICAgICAgICB0cnk6CiAgICAgICAgICAgIHRt
:::cC51bmxpbmsoKQogICAgICAgIGV4Y2VwdCBPU0Vycm9yOgogICAgICAgICAgICBw
:::YXNzCiAgICByZXR1cm4gRmFsc2UKCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gZXRpcXVl
:::dGFzCmRlZiBfYXJ0aXN0YV9saW1waW8oaW5mbyk6CiAgICAiIiJOb21icmUgZGVs
:::IGFydGlzdGEgbGVnaWJsZSBwYXJhIHJlcHJvZHVjdG9yZXMuCgogICAgTG9zIGNh
:::bmFsZXMgYXV0b21hdGljb3MgZGUgbXVzaWNhIGRlIFlvdVR1YmUgc2UgbGxhbWFu
:::ICdYIC0gVG9waWMnOwogICAgZXNlIHN1ZmlqbyBzb2JyYSBjdWFuZG8gc2UgdmUg
:::ZW4gbGEgcGFudGFsbGEgZGUgdW4gcmVwcm9kdWN0b3IuIiIiCiAgICBhID0gKGlu
:::Zm8uZ2V0KCdhcnRpc3QnKSBvciBpbmZvLmdldCgnY3JlYXRvcicpCiAgICAgICAg
:::IG9yIGluZm8uZ2V0KCd1cGxvYWRlcicpIG9yIGluZm8uZ2V0KCdjaGFubmVsJykg
:::b3IgJycpCiAgICBhID0gc3RyKGEpLnN0cmlwKCkKICAgIGEgPSByZS5zdWIocidc
:::cyotXHMqVG9waWNccyokJywgJycsIGEsIGZsYWdzPXJlLkkpLnN0cmlwKCkKICAg
:::IHJldHVybiBhCgoKZGVmIF9hbGJ1bV9kZShpbmZvKToKICAgICIiIkFsYnVtIHBh
:::cmEgZWwgYXJjaGl2byBmaW5hbC4KCiAgICB5dC1kbHAgc29sbyBlc2NyaWJlIGFs
:::YnVtIHNpIGVsIHByb3BpbyB2aWRlbyBsbyB0cmFlIChjYXNpIG51bmNhKToKICAg
:::IHBvciBlc28gbG9zIHJlcHJvZHVjdG9yZXMgbW9zdHJhYmFuICdhbGJ1bSBkZXNj
:::b25vY2lkbycuIE9yZGVuIGRlCiAgICBwcmVmZXJlbmNpYTogYWxidW0gcmVhbCAt
:::PiBub21icmUgZGUgbGEgcGxheWxpc3QgLT4gYXJ0aXN0YS4iIiIKICAgIGZvciBj
:::bGF2ZSBpbiAoJ2FsYnVtJywgJ3BsYXlsaXN0X3RpdGxlJyk6CiAgICAgICAgdiA9
:::IHN0cihpbmZvLmdldChjbGF2ZSkgb3IgJycpLnN0cmlwKCkKICAgICAgICBpZiB2
:::OgogICAgICAgICAgICByZXR1cm4gdgogICAgcmV0dXJuIF9hcnRpc3RhX2xpbXBp
:::byhpbmZvKSBvciAnWW91VHViZScKCgpkZWYgYXBsaWNhcl90YWdzKGluZm8sIGFy
:::Y2hpdm8sIGxvZz1Ob25lLCBjYXJhdHVsYT1Ob25lKToKICAgICIiIkVzY3JpYmUg
:::Y29uIG11dGFnZW4gbGFzIGV0aXF1ZXRhcyBkZWwgYXJjaGl2byBmaW5hbC4KCiAg
:::ICBHYXJhbnRpemEgcXVlIFRPRE9TIGxvcyByZXByb2R1Y3RvcmVzIG11ZXN0cmVu
:::IGFydGlzdGEgeSBhbGJ1bSwKICAgIGF1bnF1ZSBGRm1wZWdNZXRhZGF0YSBkZSB5
:::dC1kbHAgbm8gbG9zIGhheWEgZXNjcml0by4gQ2FkYSBmb3JtYXRvCiAgICBjb24g
:::U1UgZm9ybWEgZXN0YW5kYXI6CiAgICAgIMK3IE1QMzogSUQzdjIuNCBjb24gdGV4
:::dG9zIFVURi0xNiAoZW5jb2Rpbmc9MSkgeSBBUElDKG1pbWUKICAgICAgICAnaW1h
:::Z2UvanBnJywgdGlwbyAzLCBkZXNjICdhdHRhY2hlZCBwaWN0dXJlJyksIGNhbGNh
:::ZG8gZGVsCiAgICAgICAgTVAzIGRlIHJlZmVyZW5jaWEgcXVlIGVsIHJlcHJvZHVj
:::dG9yIGRlbCB1c3VhcmlvIG11ZXN0cmEKICAgICAgICBiaWVuLiBFbCBwYXNlIGFu
:::dGlndW8gdXNhYmEgZW5jb2Rpbmc9MyAoVVRGLTgpIGRlbnRybyBkZSB1bgogICAg
:::ICAgIHRhZyB2Mi4zOiBmdWVyYSBkZSBlc3BlY2lmaWNhY2lvbiwgeSBsb3MgcmVw
:::cm9kdWN0b3JlcwogICAgICAgIGJhcmF0b3MgZGVzY2FydGFiYW4gbGEgZXRpcXVl
:::dGEgRU5URVJBIChuaSBhcnRpc3RhLCBuaQogICAgICAgIGFsYnVtLCBuaSBwb3J0
:::YWRhKS4KICAgICAgwrcgTTRBOiBhdG9tb3MgTVA0IGVzdGFuZGFyICjCqW5hbS/C
:::qUFSVC9hQVJUL8KpYWxiL8KpZGF5L8KpY210KSB5CiAgICAgICAgY292ciBlbiBK
:::UEVHLCBjb21vIGlUdW5lczsgYWRlbWFzICh2Mi44KSBlbCBhdG9tbyBtb292IHF1
:::ZWRhCiAgICAgICAgQUwgUFJJTkNJUElPIGRlbCBhcmNoaXZvIChmYXN0c3RhcnQp
:::OiBmZm1wZWcgbG8gZXNjcmliZSBhbAogICAgICAgIGZpbmFsIHkgbG9zIHJlcHJv
:::ZHVjdG9yZXMgYmFyYXRvcyBzb2xvIGVzY2FuZWFuIGxhIGNhYmVjZXJhLAogICAg
:::ICAgIHBvciBlc28gbW9zdHJhYmFuICd1bmtub3duJyBhdW5xdWUgbGFzIGV0aXF1
:::ZXRhcyBlc3R1dmllcmFuLgogICAgICDCtyBXQVY6IElEMyBkZW50cm8gZGVsIFJJ
:::RkYgKG11dGFnZW4ud2F2ZSksIGlndWFsIHF1ZSBlbCBNUDMsCiAgICAgICAgbWFz
:::IEFQSUMgY29uIGxhIGNhcmF0dWxhIChudWV2byBlbiB2Mi43KS4KICAgICAgwrcg
:::RkxBQzogVm9yYmlzIGNvbW1lbnRzICsgUGljdHVyZSBlbiBKUEVHLgogICAgICDC
:::tyBXTUE6IEFTRiBUaXRsZS9BdXRob3IvV00vQWxidW1UaXRsZS9XTS9BdXRob3JV
:::UkwgKyBXTS9QaWN0dXJlLgogICAgICDCtyBsYSBjYXJhdHVsYSBTSUVNUFJFIGFj
:::YWJhIGVuIEpQRUcgeSBzZSBlc2NyaWJlIEFRVUkgY29uCiAgICAgICAgbXV0YWdl
:::bjogZGVzZGUgdjIuNyBFbWJlZFRodW1ibmFpbCB5YSBubyB0b2NhIGxhIGNhcmF0
:::dWxhCiAgICAgICAgKHN1IG1ldG9kbyBjYW1iaWEgZW50cmUgdmVyc2lvbmVzIGRl
:::IHl0LWRscCB5IGFsZ3VuYQogICAgICAgIGNvbnZlcnNpb24gc3V5YSBkZWphYmEg
:::UE5HL1dlYlAgcXVlIGxvcyByZXByb2R1Y3RvcmVzCiAgICAgICAgYmFyYXRvcyBu
:::byBsZWVuKTsKICAgICAgwrcgZWwgY29tZW50YXJpbyBndWFyZGEgbGEgVVJMIGRl
:::bCB2aWRlbyAoY29tbyBlbCBzY3JpcHQgYW50aWd1bykuCiAgICBgY2FyYXR1bGFg
:::IHNvbiBsb3MgYnl0ZXMgZGUgbGEgbWluaWF0dXJhIGRlc2NhcmdhZGEgKG9wY2lv
:::bmFsKS4iIiIKICAgIHRyeToKICAgICAgICBwID0gUGF0aChhcmNoaXZvKQogICAg
:::ICAgIGlmIG5vdCBwLmV4aXN0cygpOgogICAgICAgICAgICByZXR1cm4KICAgICAg
:::ICBhcnRpc3RhID0gX2FydGlzdGFfbGltcGlvKGluZm8pCiAgICAgICAgYWxidW0g
:::PSBfYWxidW1fZGUoaW5mbykKICAgICAgICB0aXR1bG8gPSBzdHIoaW5mby5nZXQo
:::J3RyYWNrJykgb3IgaW5mby5nZXQoJ3RpdGxlJykgb3IgJycpLnN0cmlwKCkKICAg
:::ICAgICBmZWNoYSA9IHN0cihpbmZvLmdldCgncmVsZWFzZV95ZWFyJykgb3IgJycp
:::CiAgICAgICAgaWYgbm90IGZlY2hhOgogICAgICAgICAgICBmZWNoYSA9IHN0cihp
:::bmZvLmdldCgndXBsb2FkX2RhdGUnKSBvciAnJykKICAgICAgICAgICAgaWYgbGVu
:::KGZlY2hhKSA9PSA4IGFuZCBmZWNoYS5pc2RpZ2l0KCk6CiAgICAgICAgICAgICAg
:::ICBmZWNoYSA9IGZlY2hhWzo0XQogICAgICAgIHVybCA9IHN0cihpbmZvLmdldCgn
:::d2VicGFnZV91cmwnKSBvciAnJykuc3RyaXAoKQogICAgICAgIGlmIGNhcmF0dWxh
:::IGFuZCBub3QgX2VzX2pwZyhjYXJhdHVsYSk6CiAgICAgICAgICAgIGNhcmF0dWxh
:::ID0gX2FfanBnKGNhcmF0dWxhKQogICAgICAgIGV4dCA9IHAuc3VmZml4Lmxvd2Vy
:::KCkKICAgICAgICBpZiBleHQgPT0gJy5tNGEnOgogICAgICAgICAgICAjIHYyLjg6
:::IEFOVEVTIGRlIGV0aXF1ZXRhciwgbW9vdiAodGl0dWxvL2FydGlzdGEvYWxidW0v
:::Y292cikKICAgICAgICAgICAgIyBhbCBwcmluY2lwaW8gZGVsIGFyY2hpdm87IG11
:::dGFnZW4gY29uc2VydmEgZXNlIG9yZGVuLgogICAgICAgICAgICBpZiBfbW9vdl9h
:::bF9wcmluY2lwaW8ocCkgYW5kIGxvZzoKICAgICAgICAgICAgICAgIGxvZygnTTRB
:::IHJlb3JkZW5hZG86IGV0aXF1ZXRhcyBhbCBpbmljaW8gKGZhc3RzdGFydCwgJwog
:::ICAgICAgICAgICAgICAgICAgICdjb21vIGlUdW5lcyknLCAnZ3JpcycpCiAgICAg
:::ICAgICAgIGZyb20gbXV0YWdlbi5tcDQgaW1wb3J0IE1QNCwgTVA0Q292ZXIKICAg
:::ICAgICAgICAgbSA9IE1QNChzdHIocCkpCiAgICAgICAgICAgIGlmIHRpdHVsbzoK
:::ICAgICAgICAgICAgICAgIG1bJ1x4YTluYW0nXSA9IFt0aXR1bG9dCiAgICAgICAg
:::ICAgIGlmIGFydGlzdGE6CiAgICAgICAgICAgICAgICBtWydceGE5QVJUJ10gPSBb
:::YXJ0aXN0YV0KICAgICAgICAgICAgICAgIG1bJ2FBUlQnXSA9IFthcnRpc3RhXQog
:::ICAgICAgICAgICBpZiBhbGJ1bToKICAgICAgICAgICAgICAgIG1bJ1x4YTlhbGIn
:::XSA9IFthbGJ1bV0KICAgICAgICAgICAgaWYgZmVjaGE6CiAgICAgICAgICAgICAg
:::ICBtWydceGE5ZGF5J10gPSBbZmVjaGFdCiAgICAgICAgICAgIGlmIHVybDoKICAg
:::ICAgICAgICAgICAgIG1bJ1x4YTljbXQnXSA9IFt1cmxdCiAgICAgICAgICAgICMg
:::LS0gY2FyYXR1bGE6IGRlc2RlIHYyLjcgbGEgZXNjcmliZSBTSUVNUFJFIGVzdGUg
:::cGFzZSBjb24KICAgICAgICAgICAgIyAgICBtdXRhZ2VuIChFbWJlZFRodW1ibmFp
:::bCB5YSBubyBwYXJ0aWNpcGEpLiBBdG9tbwogICAgICAgICAgICAjICAgIGVzdGFu
:::ZGFyICdjb3ZyJyAoc2luIGVsIHByZWZpam8gKGMpKTsgZW4gbXV0YWdlbgogICAg
:::ICAgICAgICAjICAgIG1vZGVybm8gZXNjcmliaXIgJ1x4YTljb3ZyJyBsYW56YSBU
:::eXBlRXJyb3IuCiAgICAgICAgICAgIHZpZWphcyA9IG0uZ2V0KCdjb3ZyJykgb3Ig
:::bS5nZXQoJ1x4YTljb3ZyJykgb3IgW10KICAgICAgICAgICAgaWYgbm90IHZpZWph
:::czoKICAgICAgICAgICAgICAgIGlmIGNhcmF0dWxhOgogICAgICAgICAgICAgICAg
:::ICAgIG1bJ2NvdnInXSA9IFtNUDRDb3ZlcihjYXJhdHVsYSwgTVA0Q292ZXIuRk9S
:::TUFUX0pQRUcpXQogICAgICAgICAgICBlbGlmIGFsbChjLmltYWdlZm9ybWF0ICE9
:::IE1QNENvdmVyLkZPUk1BVF9KUEVHCiAgICAgICAgICAgICAgICAgICAgIGZvciBj
:::IGluIHZpZWphcyk6CiAgICAgICAgICAgICAgICBudWV2YSA9IF9hX2pwZyhieXRl
:::cyh2aWVqYXNbMF0pKSBvciBjYXJhdHVsYQogICAgICAgICAgICAgICAgaWYgbnVl
:::dmE6CiAgICAgICAgICAgICAgICAgICAgbVsnY292ciddID0gW01QNENvdmVyKG51
:::ZXZhLCBNUDRDb3Zlci5GT1JNQVRfSlBFRyldCiAgICAgICAgICAgICAgICAgICAg
:::bS5wb3AoJ1x4YTljb3ZyJywgTm9uZSkKICAgICAgICAgICAgZWxpZiBtLmdldCgn
:::XHhhOWNvdnInKToKICAgICAgICAgICAgICAgIG1bJ2NvdnInXSA9IHZpZWphcwog
:::ICAgICAgICAgICAgICAgbS5wb3AoJ1x4YTljb3ZyJywgTm9uZSkKICAgICAgICAg
:::ICAgbS5zYXZlKCkKICAgICAgICBlbGlmIGV4dCA9PSAnLm1wMyc6CiAgICAgICAg
:::ICAgICMgRm9ybWF0byBFWEFDVE8gZGVsIE1QMyBkZSByZWZlcmVuY2lhIChTbmFw
:::dHViZSwgZXNjcml0byBwb3IKICAgICAgICAgICAgIyBGRm1wZWcvTGF2ZikgcXVl
:::IGVsIHJlcHJvZHVjdG9yIGRlbCB1c3VhcmlvIFNJIG11ZXN0cmE6CiAgICAgICAg
:::ICAgICMgICBJRDN2Mi40LjAgKyBUSVQyL1RQRTEvVEFMQi9BUElDIGVuIGVuY29k
:::aW5nPTEgKFVURi0xNiBjb24KICAgICAgICAgICAgIyAgIEJPTSkgKyBBUElDKG1p
:::bWUgJ2ltYWdlL2pwZycsIHRpcG8gMyA9IENPVkVSX0ZST05ULCBkZXNjCiAgICAg
:::ICAgICAgICMgICAnYXR0YWNoZWQgcGljdHVyZScsIEpQRUcgcmVhbCkuIEVsIHBh
:::c2UgYW50ZXJpb3IgZXNjcmliaWEKICAgICAgICAgICAgIyAgIGVuY29kaW5nPTMg
:::KFVURi04KSBkZW50cm8gZGUgdW4gdGFnIHYyLjM6IGZ1ZXJhIGRlCiAgICAgICAg
:::ICAgICMgICBlc3BlY2lmaWNhY2lvbiwgeSBsb3MgcmVwcm9kdWN0b3JlcyBiYXJh
:::dG9zIGRlc2NhcnRhYmFuCiAgICAgICAgICAgICMgICBsYSBldGlxdWV0YSBlbnRl
:::cmEgKG5pIGFydGlzdGEsIG5pIGFsYnVtLCBuaSBwb3J0YWRhKS4KICAgICAgICAg
:::ICAgZnJvbSBtdXRhZ2VuLmlkMyBpbXBvcnQgKEFQSUMsIENPTU0sIElEMywgVEFM
:::QiwgVERSQywgVElUMiwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIFRMRU4sIFRQRTEsIFRQRTIpCiAgICAgICAgICAgIHRyeToKICAgICAgICAg
:::ICAgICAgIHRhZ3MgPSBJRDMoc3RyKHApKQogICAgICAgICAgICBleGNlcHQgRXhj
:::ZXB0aW9uOgogICAgICAgICAgICAgICAgdGFncyA9IElEMygpCiAgICAgICAgICAg
:::IGlmIHRpdHVsbzoKICAgICAgICAgICAgICAgIHRhZ3Muc2V0YWxsKCdUSVQyJywg
:::W1RJVDIoZW5jb2Rpbmc9MSwgdGV4dD1bdGl0dWxvXSldKQogICAgICAgICAgICBp
:::ZiBhcnRpc3RhOgogICAgICAgICAgICAgICAgdGFncy5zZXRhbGwoJ1RQRTEnLCBb
:::VFBFMShlbmNvZGluZz0xLCB0ZXh0PVthcnRpc3RhXSldKQogICAgICAgICAgICAg
:::ICAgdGFncy5zZXRhbGwoJ1RQRTInLCBbVFBFMihlbmNvZGluZz0xLCB0ZXh0PVth
:::cnRpc3RhXSldKQogICAgICAgICAgICBpZiBhbGJ1bToKICAgICAgICAgICAgICAg
:::IHRhZ3Muc2V0YWxsKCdUQUxCJywgW1RBTEIoZW5jb2Rpbmc9MSwgdGV4dD1bYWxi
:::dW1dKV0pCiAgICAgICAgICAgIGlmIGZlY2hhOgogICAgICAgICAgICAgICAgdGFn
:::cy5zZXRhbGwoJ1REUkMnLCBbVERSQyhlbmNvZGluZz0xLCB0ZXh0PVtmZWNoYV0p
:::XSkKICAgICAgICAgICAgZHVyID0gaW5mby5nZXQoJ2R1cmF0aW9uJykKICAgICAg
:::ICAgICAgaWYgZHVyOgogICAgICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAg
:::ICAgICAgIHRhZ3Muc2V0YWxsKCdUTEVOJywgW1RMRU4oZW5jb2Rpbmc9MCwgdGV4
:::dD1bCiAgICAgICAgICAgICAgICAgICAgICAgIHN0cihpbnQoZmxvYXQoZHVyKSAq
:::IDEwMDApKV0pXSkKICAgICAgICAgICAgICAgIGV4Y2VwdCAoVHlwZUVycm9yLCBW
:::YWx1ZUVycm9yKToKICAgICAgICAgICAgICAgICAgICBwYXNzCiAgICAgICAgICAg
:::IGlmIHVybDoKICAgICAgICAgICAgICAgIHRhZ3Muc2V0YWxsKCdDT01NJywgW0NP
:::TU0oZW5jb2Rpbmc9MSwgbGFuZz0nZW5nJywKICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgZGVzYz0nJywgdGV4dD1bdXJsXSldKQogICAg
:::ICAgICAgICAjIFBvcnRhZGE6IG1pc21hcyBjb25zdGFudGVzIGRlbCBhcmNoaXZv
:::IGRlIHJlZmVyZW5jaWEuCiAgICAgICAgICAgICMgQnl0ZXM6IGBjYXJhdHVsYWAg
:::bywgc2kgRW1iZWRUaHVtYm5haWwgeWEgaW5jcnVzdG8gYWxnbywKICAgICAgICAg
:::ICAgIyBsb3MgZGF0b3MgZGVsIEFQSUMgZXhpc3RlbnRlOyBzaWVtcHJlIGFjYWJh
:::bW9zIGVuIEpQRUcuCiAgICAgICAgICAgIGRhdG9zID0gY2FyYXR1bGEKICAgICAg
:::ICAgICAgaWYgbm90IGRhdG9zOgogICAgICAgICAgICAgICAgYXBpY3MgPSB0YWdz
:::LmdldGFsbCgnQVBJQycpCiAgICAgICAgICAgICAgICBpZiBhcGljczoKICAgICAg
:::ICAgICAgICAgICAgICBkYXRvcyA9IGFwaWNzWzBdLmRhdGEKICAgICAgICAgICAg
:::aWYgZGF0b3MgYW5kIG5vdCBfZXNfanBnKGRhdG9zKToKICAgICAgICAgICAgICAg
:::IGRhdG9zID0gX2FfanBnKGRhdG9zKQogICAgICAgICAgICBpZiBkYXRvczoKICAg
:::ICAgICAgICAgICAgIHRhZ3Muc2V0YWxsKCdBUElDJywgW0FQSUMoZW5jb2Rpbmc9
:::MSwgbWltZT0naW1hZ2UvanBnJywKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgdHlwZT0zLCBkZXNjPSdhdHRhY2hlZCBwaWN0dXJlJywK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YT1k
:::YXRvcyldKQogICAgICAgICAgICAjIHYyLjQgKyBVVEYtMTY6IGxhIG1pc21hIGNv
:::bWJpbmFjaW9uIGRlbCBhcmNoaXZvIGRlCiAgICAgICAgICAgICMgcmVmZXJlbmNp
:::YSAoSUQzdjIuNC4wIGVzY3JpdG8gcG9yIExhdmY2MC4zLjEwMCkuCiAgICAgICAg
:::ICAgIHRhZ3Muc2F2ZShzdHIocCksIHYyX3ZlcnNpb249NCkKICAgICAgICBlbGlm
:::IGV4dCA9PSAnLndhdic6CiAgICAgICAgICAgIGZyb20gbXV0YWdlbi5pZDMgaW1w
:::b3J0IChBUElDLCBDT01NLCBURFJDLCBUSVQyLCBUTEVOLCBUUEUxLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgVFBFMiwgVEFMQikKICAgICAg
:::ICAgICAgZnJvbSBtdXRhZ2VuLndhdmUgaW1wb3J0IFdBVkUKICAgICAgICAgICAg
:::dyA9IFdBVkUoc3RyKHApKQogICAgICAgICAgICBpZiB3LnRhZ3MgaXMgTm9uZToK
:::ICAgICAgICAgICAgICAgIHcuYWRkX3RhZ3MoKQogICAgICAgICAgICAjIGVuY29k
:::aW5nPTEgKFVURi0xNiksIG1pc21hIHJlZ2xhIHF1ZSBlbiBNUDM6IGxvcwogICAg
:::ICAgICAgICAjIHJlcHJvZHVjdG9yZXMgYmFyYXRvcyBubyBwYXJzZWFuIGZyYW1l
:::cyBVVEYtOC4KICAgICAgICAgICAgaWYgdGl0dWxvOgogICAgICAgICAgICAgICAg
:::dy50YWdzLnNldGFsbCgnVElUMicsIFtUSVQyKGVuY29kaW5nPTEsIHRleHQ9W3Rp
:::dHVsb10pXSkKICAgICAgICAgICAgaWYgYXJ0aXN0YToKICAgICAgICAgICAgICAg
:::IHcudGFncy5zZXRhbGwoJ1RQRTEnLCBbVFBFMShlbmNvZGluZz0xLCB0ZXh0PVth
:::cnRpc3RhXSldKQogICAgICAgICAgICAgICAgdy50YWdzLnNldGFsbCgnVFBFMics
:::IFtUUEUyKGVuY29kaW5nPTEsIHRleHQ9W2FydGlzdGFdKV0pCiAgICAgICAgICAg
:::IGlmIGFsYnVtOgogICAgICAgICAgICAgICAgdy50YWdzLnNldGFsbCgnVEFMQics
:::IFtUQUxCKGVuY29kaW5nPTEsIHRleHQ9W2FsYnVtXSldKQogICAgICAgICAgICBp
:::ZiBmZWNoYToKICAgICAgICAgICAgICAgIHcudGFncy5zZXRhbGwoJ1REUkMnLCBb
:::VERSQyhlbmNvZGluZz0xLCB0ZXh0PVtmZWNoYV0pXSkKICAgICAgICAgICAgZHVy
:::ID0gaW5mby5nZXQoJ2R1cmF0aW9uJykKICAgICAgICAgICAgaWYgZHVyOgogICAg
:::ICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgICAgIHcudGFncy5zZXRh
:::bGwoJ1RMRU4nLCBbVExFTihlbmNvZGluZz0wLCB0ZXh0PVsKICAgICAgICAgICAg
:::ICAgICAgICAgICAgc3RyKGludChmbG9hdChkdXIpICogMTAwMCkpXSldKQogICAg
:::ICAgICAgICAgICAgZXhjZXB0IChUeXBlRXJyb3IsIFZhbHVlRXJyb3IpOgogICAg
:::ICAgICAgICAgICAgICAgIHBhc3MKICAgICAgICAgICAgaWYgdXJsOgogICAgICAg
:::ICAgICAgICAgdy50YWdzLnNldGFsbCgnQ09NTScsIFtDT01NKGVuY29kaW5nPTEs
:::IGxhbmc9J2VuZycsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgZGVzYz0nJywgdGV4dD1bdXJsXSldKQogICAgICAgICAgICAjIHYy
:::Ljc6IGNhcmF0dWxhIGVuIGVsIElEMyBkZWwgV0FWIChtaXNtYXMgY29uc3RhbnRl
:::cyBxdWUKICAgICAgICAgICAgIyBlbCBNUDMgZGUgcmVmZXJlbmNpYSksIHBhcmEg
:::bG9zIHJlcHJvZHVjdG9yZXMgcXVlIGxlZW4KICAgICAgICAgICAgIyBlbCBjaHVu
:::ayAnaWQzICcgZGVudHJvIGRlbCBSSUZGLgogICAgICAgICAgICBkYXRvcyA9IGNh
:::cmF0dWxhCiAgICAgICAgICAgIGlmIG5vdCBkYXRvczoKICAgICAgICAgICAgICAg
:::IGFwaWNzID0gdy50YWdzLmdldGFsbCgnQVBJQycpCiAgICAgICAgICAgICAgICBp
:::ZiBhcGljczoKICAgICAgICAgICAgICAgICAgICBkYXRvcyA9IGFwaWNzWzBdLmRh
:::dGEKICAgICAgICAgICAgaWYgZGF0b3MgYW5kIG5vdCBfZXNfanBnKGRhdG9zKToK
:::ICAgICAgICAgICAgICAgIGRhdG9zID0gX2FfanBnKGRhdG9zKQogICAgICAgICAg
:::ICBpZiBkYXRvczoKICAgICAgICAgICAgICAgIHcudGFncy5zZXRhbGwoJ0FQSUMn
:::LCBbQVBJQyhlbmNvZGluZz0xLCBtaW1lPSdpbWFnZS9qcGcnLAogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHR5cGU9MywgZGVzYz0n
:::YXR0YWNoZWQgcGljdHVyZScsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgZGF0YT1kYXRvcyldKQogICAgICAgICAgICB3LnNhdmUo
:::KQogICAgICAgIGVsaWYgZXh0ID09ICcuZmxhYyc6CiAgICAgICAgICAgIGZyb20g
:::bXV0YWdlbi5mbGFjIGltcG9ydCBGTEFDLCBQaWN0dXJlCiAgICAgICAgICAgIGYg
:::PSBGTEFDKHN0cihwKSkKICAgICAgICAgICAgaWYgdGl0dWxvOgogICAgICAgICAg
:::ICAgICAgZlsndGl0bGUnXSA9IFt0aXR1bG9dCiAgICAgICAgICAgIGlmIGFydGlz
:::dGE6CiAgICAgICAgICAgICAgICBmWydhcnRpc3QnXSA9IFthcnRpc3RhXQogICAg
:::ICAgICAgICAgICAgZlsnYWxidW1hcnRpc3QnXSA9IFthcnRpc3RhXQogICAgICAg
:::ICAgICBpZiBhbGJ1bToKICAgICAgICAgICAgICAgIGZbJ2FsYnVtJ10gPSBbYWxi
:::dW1dCiAgICAgICAgICAgIGlmIGZlY2hhOgogICAgICAgICAgICAgICAgZlsnZGF0
:::ZSddID0gW2ZlY2hhXQogICAgICAgICAgICBpZiB1cmw6CiAgICAgICAgICAgICAg
:::ICBmWydjb21tZW50J10gPSBbdXJsXQogICAgICAgICAgICBpZiBub3QgZi5waWN0
:::dXJlczoKICAgICAgICAgICAgICAgIGlmIGNhcmF0dWxhOgogICAgICAgICAgICAg
:::ICAgICAgIHBpYyA9IFBpY3R1cmUoKQogICAgICAgICAgICAgICAgICAgIHBpYy5t
:::aW1lLCBwaWMudHlwZSwgcGljLmRlc2MgPSAnaW1hZ2UvanBlZycsIDMsICdDb3Zl
:::cicKICAgICAgICAgICAgICAgICAgICBwaWMuZGF0YSA9IGNhcmF0dWxhCiAgICAg
:::ICAgICAgICAgICAgICAgZi5hZGRfcGljdHVyZShwaWMpCiAgICAgICAgICAgIGVs
:::aWYgYWxsKHBpLm1pbWUgIT0gJ2ltYWdlL2pwZWcnIGZvciBwaSBpbiBmLnBpY3R1
:::cmVzKToKICAgICAgICAgICAgICAgIG51ZXZhID0gX2FfanBnKGYucGljdHVyZXNb
:::MF0uZGF0YSkgb3IgY2FyYXR1bGEKICAgICAgICAgICAgICAgIGlmIG51ZXZhOgog
:::ICAgICAgICAgICAgICAgICAgIGZvciB2aWVqYSBpbiBsaXN0KGYucGljdHVyZXMp
:::OgogICAgICAgICAgICAgICAgICAgICAgICBmLnJlbW92ZV9waWN0dXJlKHZpZWph
:::KQogICAgICAgICAgICAgICAgICAgIHBpYyA9IFBpY3R1cmUoKQogICAgICAgICAg
:::ICAgICAgICAgIHBpYy5taW1lLCBwaWMudHlwZSwgcGljLmRlc2MgPSAnaW1hZ2Uv
:::anBlZycsIDMsICdDb3ZlcicKICAgICAgICAgICAgICAgICAgICBwaWMuZGF0YSA9
:::IG51ZXZhCiAgICAgICAgICAgICAgICAgICAgZi5hZGRfcGljdHVyZShwaWMpCiAg
:::ICAgICAgICAgIGYuc2F2ZSgpCiAgICAgICAgZWxpZiBleHQgPT0gJy53bWEnOgog
:::ICAgICAgICAgICBmcm9tIG11dGFnZW4uYXNmIGltcG9ydCBBU0YsIEFTRkJ5dGVB
:::cnJheUF0dHJpYnV0ZQogICAgICAgICAgICBhID0gQVNGKHN0cihwKSkKICAgICAg
:::ICAgICAgaWYgdGl0dWxvOgogICAgICAgICAgICAgICAgYVsnVGl0bGUnXSA9IFt0
:::aXR1bG9dCiAgICAgICAgICAgIGlmIGFydGlzdGE6CiAgICAgICAgICAgICAgICBh
:::WydBdXRob3InXSA9IFthcnRpc3RhXQogICAgICAgICAgICAgICAgYVsnV00vQWxi
:::dW1BcnRpc3QnXSA9IFthcnRpc3RhXQogICAgICAgICAgICBpZiBhbGJ1bToKICAg
:::ICAgICAgICAgICAgIGFbJ1dNL0FsYnVtVGl0bGUnXSA9IFthbGJ1bV0KICAgICAg
:::ICAgICAgaWYgZmVjaGE6CiAgICAgICAgICAgICAgICBhWydXTS9ZZWFyJ10gPSBb
:::ZmVjaGFdCiAgICAgICAgICAgIGlmIHVybDoKICAgICAgICAgICAgICAgIGFbJ0Rl
:::c2NyaXB0aW9uJ10gPSBbdXJsXQogICAgICAgICAgICAgICAgYVsnV00vQXV0aG9y
:::VVJMJ10gPSBbdXJsXQogICAgICAgICAgICBpZiBjYXJhdHVsYToKICAgICAgICAg
:::ICAgICAgIGFbJ1dNL1BpY3R1cmUnXSA9IFtBU0ZCeXRlQXJyYXlBdHRyaWJ1dGUo
:::CiAgICAgICAgICAgICAgICAgICAgX3dtX3BpY3R1cmUoY2FyYXR1bGEsIHRpdHVs
:::byBvciAnQ292ZXInKSldCiAgICAgICAgICAgIGEuc2F2ZSgpCiAgICAgICAgZWxz
:::ZToKICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgaWYgbG9nOgogICAgICAgICAg
:::ICBleHRyYSA9ICcgwrcgY2Fyw6F0dWxhIEpQRUcnIGlmIGNhcmF0dWxhIGVsc2Ug
:::JycKICAgICAgICAgICAgbG9nKCdFdGlxdWV0YXMgZXNjcml0YXM6IGFydGlzdGEg
:::wqslc8K7IMK3IMOhbGJ1bSDCqyVzwrslcycKICAgICAgICAgICAgICAgICUgKGFy
:::dGlzdGEgb3IgJ+KAlCcsIGFsYnVtIG9yICfigJQnLCBleHRyYSksICdncmlzJykK
:::ICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZToKICAgICAgICAjIGxhcyBldGlxdWV0
:::YXMgbm8gc29uIGNyaXRpY2FzOiBudW5jYSBkZWJlbiByb21wZXIgbGEgZGVzY2Fy
:::Z2EKICAgICAgICBpZiBsb2c6CiAgICAgICAgICAgIGxvZygnTm8gc2UgcHVkaWVy
:::b24gZXNjcmliaXIgdG9kYXMgbGFzIGV0aXF1ZXRhczogJXMnICUgZSwKICAgICAg
:::ICAgICAgICAgICdhdmlzbycpCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGRlc2Nhcmdh
:::cwpkZWYgZGVzY2FyZ2FyX2F1ZGlvKHVybCwgbm9tYnJlX2ZtdCwgY2FsaWRhZCwg
:::ZGVzdGlubywgZW1iZWJlciwgY29sYSk6CiAgICAiIiJBQUMgKC5tNGEpIC8gTVAz
:::IC8gRkxBQyAvIFdBViB2w61hIHBvc3Rwcm9jZXNhZG9yZXMgZGUgeXQtZGxwLgoK
:::ICAgIHl0LWRscCBTT0xPIGJhamEsIGNvbnZpZXJ0ZSB5IGVzY3JpYmUgbG9zIG1l
:::dGFkYXRvcyBkZSB0ZXh0bwogICAgKEZGbXBlZ01ldGFkYXRhKS4gTGEgY2Fyw6F0
:::dWxhIE5PIGxhIGluY3J1c3RhIEVtYmVkVGh1bWJuYWlsOiBkZXNkZQogICAgdjIu
:::NyBsYSBlc2NyaWJlIGFwbGljYXJfdGFncyBjb24gbXV0YWdlbiAoY292ciBlbiBt
:::NGEsIEFQSUMgZW4KICAgIG1wMy93YXYsIFBpY3R1cmUgZW4gZmxhYyksIHNpZW1w
:::cmUgZW4gSlBFRyB5IGNvbiBsYSBlc3RydWN0dXJhCiAgICBleGFjdGEgcXVlIGxl
:::ZW4gbG9zIHJlcHJvZHVjdG9yZXMuIEFzw60gZWwgcmVzdWx0YWRvIG5vIGRlcGVu
:::ZGUgZGUKICAgIGxvcyBtw6l0b2RvcyBpbnRlcm5vcyBkZSBFbWJlZFRodW1ibmFp
:::bCwgcXVlIGNhbWJpYW4gZW50cmUKICAgIHZlcnNpb25lcyBkZSB5dC1kbHAgKGFu
:::dGVzIGNvbnZlcnTDrWEgbGEgcG9ydGFkYSBhIFBORywgeSBzdQogICAgbcOpdG9k
:::byBmZm1wZWcgYWRqdW50YSBsYSBpbWFnZW4gY29tbyBzdHJlYW0gZGUgdsOtZGVv
:::KS4iIiIKICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgogICAgICAgIGNvbGEucHV0
:::KCgnbG9nJywgbSwgdCkpCgogICAgZm10ID0gRk9STUFUT1Nbbm9tYnJlX2ZtdF0K
:::ICAgIGNhcnBldGEgPSBkZXN0aW5vICAgICAgICAgICMgdjIuMzogc2luIHN1YmNh
:::cnBldGFzIHBvciBmb3JtYXRvCiAgICBjYXJwZXRhLm1rZGlyKHBhcmVudHM9VHJ1
:::ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgIGNvZGVjID0gZm10WydleHQnXQogICAgY29u
:::X3BvcnRhZGEgPSBlbWJlYmVyIGFuZCBub21icmVfZm10IGluICgnQUFDJywgJ01Q
:::MycsICdGTEFDJywgJ1dBVicpCiAgICBjb25fdGFncyA9IGVtYmViZXIKICAgIHBw
:::cyA9IFtdCiAgICBpZiBjb25fcG9ydGFkYToKICAgICAgICBwcHMuYXBwZW5kKHsn
:::a2V5JzogJ0ZGbXBlZ1RodW1ibmFpbHNDb252ZXJ0b3InLCAnZm9ybWF0JzogJ2pw
:::ZycsCiAgICAgICAgICAgICAgICAgICAgJ3doZW4nOiAnYmVmb3JlX2RsJ30pCiAg
:::ICBwcHMuYXBwZW5kKHsna2V5JzogJ0ZGbXBlZ0V4dHJhY3RBdWRpbycsICdwcmVm
:::ZXJyZWRjb2RlYyc6IGNvZGVjLAogICAgICAgICAgICAgICAgJ3ByZWZlcnJlZHF1
:::YWxpdHknOiBjYWxpZGFkIG9yICcwJ30pCiAgICBpZiBjb25fdGFnczoKICAgICAg
:::ICBwcHMuYXBwZW5kKHsna2V5JzogJ0ZGbXBlZ01ldGFkYXRhJywgJ2FkZF9tZXRh
:::ZGF0YSc6IFRydWV9KQogICAgIyB2Mi43OiBTSU4gRW1iZWRUaHVtYm5haWwuIExh
:::IG1pbmlhdHVyYSAoZGVqYWRhIGVuIC5qcGcganVudG8gYWwKICAgICMgYXJjaGl2
:::byBwb3Igd3JpdGV0aHVtYm5haWwgKyBDb252ZXJ0b3IpIGxhIGluY3J1c3RhIGFw
:::bGljYXJfdGFncwogICAgIyBjb24gbXV0YWdlbjogZXN0cnVjdHVyYSBnYXJhbnRp
:::emFkYSBlbiB0b2RvcyBsb3MgZm9ybWF0b3MgeSBzaW4KICAgICMgZGVwZW5kZXIg
:::ZGUgbG9zIG3DqXRvZG9zIGludGVybm9zIGRlIHl0LWRscC4KICAgIG8gPSBvcHRz
:::X2Jhc2UoY2FycGV0YSwgY29sYSkKICAgIG9bJ2Zvcm1hdCddID0gJ2Jlc3RhdWRp
:::by9iZXN0JwogICAgb1sncG9zdHByb2Nlc3NvcnMnXSA9IHBwcwogICAgb1snd3Jp
:::dGV0aHVtYm5haWwnXSA9IGNvbl9wb3J0YWRhCiAgICB3aXRoIFlUX0RMUC5Zb3V0
:::dWJlREwobykgYXMgeWRsOgogICAgICAgIGluZm8gPSB5ZGwuZXh0cmFjdF9pbmZv
:::KHVybCwgZG93bmxvYWQ9VHJ1ZSkKICAgIGFyY2hpdm8gPSBhcmNoaXZvX2ZpbmFs
:::KGluZm8sIGNhcnBldGEsIGNvZGVjKQogICAgY2FyYXR1bGEgPSBfbWluaWF0dXJh
:::X2J5dGVzKGNhcnBldGEsIGFyY2hpdm8pCiAgICBpZiBhcmNoaXZvIGFuZCBjb25f
:::cG9ydGFkYToKICAgICAgICBsaW1waWFyX21pbmlhdHVyYXMoY2FycGV0YSwgYXJj
:::aGl2bykKICAgIGlmIGFyY2hpdm86CiAgICAgICAgYXBsaWNhcl90YWdzKGluZm8s
:::IGFyY2hpdm8sIGxvZywgY2FyYXR1bGEpCiAgICByZXR1cm4gaW5mbywgYXJjaGl2
:::bwoKCmRlZiBkZXNjYXJnYXJfd21hKHVybCwgY2FsaWRhZCwgZGVzdGlubywgZW1i
:::ZWJlciwgY29sYSk6CiAgICAiIiJXTUEgOTYvMTI4IGticHM6IHl0LWRscCBubyBz
:::b3BvcnRhIHdtYSwgYXPDrSBxdWUgc2UgYmFqYSBhIFdBViAoY29uCiAgICBldGlx
:::dWV0YXMpIHkgbHVlZ28gRkZtcGVnIHJlY29kaWZpY2EgYSB3bWF2MiBkZW50cm8g
:::ZGVsIC53bWEgZmluYWwuCiAgICBMYSBjYXLDoXR1bGEgKFdNL1BpY3R1cmUsIGVu
:::IEpQRUcpIHkgbGEgVVJMIChXTS9BdXRob3JVUkwpIHNlCiAgICBpbmNydXN0YW4g
:::Y29uIG11dGFnZW4sIGNvbW8gZW4gZWwgc2NyaXB0IGFudGlndW8uIiIiCiAgICBk
:::ZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0s
:::IHQpKQoKICAgIGNhcnBldGEgPSBkZXN0aW5vICAgICAgICAgICMgdjIuMzogc2lu
:::IHN1YmNhcnBldGFzIHBvciBmb3JtYXRvCiAgICB0bXAgPSBjYXJwZXRhIC8gJ190
:::bXAnCiAgICBzaHV0aWwucm10cmVlKHRtcCwgaWdub3JlX2Vycm9ycz1UcnVlKQog
:::ICAgdG1wLm1rZGlyKHBhcmVudHM9VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgIG8g
:::PSBvcHRzX2Jhc2UodG1wLCBjb2xhKQogICAgb1snZm9ybWF0J10gPSAnYmVzdGF1
:::ZGlvL2Jlc3QnCiAgICBwcHMgPSBbeydrZXknOiAnRkZtcGVnRXh0cmFjdEF1ZGlv
:::JywgJ3ByZWZlcnJlZGNvZGVjJzogJ3dhdicsCiAgICAgICAgICAgICdwcmVmZXJy
:::ZWRxdWFsaXR5JzogJzAnfV0KICAgIGlmIGVtYmViZXI6CiAgICAgICAgcHBzLmlu
:::c2VydCgwLCB7J2tleSc6ICdGRm1wZWdUaHVtYm5haWxzQ29udmVydG9yJywKICAg
:::ICAgICAgICAgICAgICAgICAgICAnZm9ybWF0JzogJ2pwZycsICd3aGVuJzogJ2Jl
:::Zm9yZV9kbCd9KQogICAgICAgIHBwcy5hcHBlbmQoeydrZXknOiAnRkZtcGVnTWV0
:::YWRhdGEnLCAnYWRkX21ldGFkYXRhJzogVHJ1ZX0pCiAgICBvWydwb3N0cHJvY2Vz
:::c29ycyddID0gcHBzCiAgICBvWyd3cml0ZXRodW1ibmFpbCddID0gZW1iZWJlcgog
:::ICAgd2l0aCBZVF9ETFAuWW91dHViZURMKG8pIGFzIHlkbDoKICAgICAgICBpbmZv
:::ID0geWRsLmV4dHJhY3RfaW5mbyh1cmwsIGRvd25sb2FkPVRydWUpCiAgICB3YXYg
:::PSBhcmNoaXZvX2ZpbmFsKGluZm8sIHRtcCwgJ3dhdicpCiAgICBpZiBub3Qgd2F2
:::OgogICAgICAgIHJhaXNlIFJ1bnRpbWVFcnJvcignTm8gc2UgZW5jb250csOzIGVs
:::IFdBViBpbnRlcm1lZGlvLicpCiAgICBtZXRhID0gW10KICAgIGlmIGVtYmViZXI6
:::CiAgICAgICAgYXJ0aXN0YSA9IChpbmZvLmdldCgnYXJ0aXN0Jykgb3IgaW5mby5n
:::ZXQoJ3VwbG9hZGVyJykKICAgICAgICAgICAgICAgICAgIG9yIGluZm8uZ2V0KCdj
:::aGFubmVsJykgb3IgJycpCiAgICAgICAgaWYgaW5mby5nZXQoJ3RpdGxlJyk6CiAg
:::ICAgICAgICAgIG1ldGEgKz0gWyctbWV0YWRhdGEnLCAndGl0bGU9JyArIHN0cihp
:::bmZvWyd0aXRsZSddKV0KICAgICAgICBpZiBhcnRpc3RhOgogICAgICAgICAgICBt
:::ZXRhICs9IFsnLW1ldGFkYXRhJywgJ2FydGlzdD0nICsgc3RyKGFydGlzdGEpXQog
:::ICAgd21hID0gY2FycGV0YSAvIChsaW1waWFyX25vbWJyZShpbmZvLmdldCgndGl0
:::bGUnKSBvciAnYXVkaW8nKSArICcud21hJykKICAgIGNtZCA9IFtzdHIoRkZNUEVH
:::KSwgJy15JywgJy1pJywgc3RyKHdhdiksICctdm4nLAogICAgICAgICAgICctYzph
:::JywgJ3dtYXYyJywgJy1iOmEnLCBmJ3tjYWxpZGFkfWsnXSArIG1ldGEgKyBbc3Ry
:::KHdtYSldCiAgICBvayA9IGNvbnZlcnRpcl9mZm1wZWcoCiAgICAgICAgY21kLCBm
:::J0NvbnZpcnRpZW5kbyBhIFdNQSAod21hdjIgwrcge2NhbGlkYWR9IGticHMpJywg
:::Y29sYSkKICAgIGlmIG5vdCBvazoKICAgICAgICByYWlzZSBSdW50aW1lRXJyb3Io
:::J0ZGbXBlZyBubyBwdWRvIGNyZWFyIGVsIGFyY2hpdm8gV01BLicpCiAgICBjYXJh
:::dHVsYSA9IE5vbmUKICAgIGlmIGVtYmViZXI6CiAgICAgICAganBncyA9IHNvcnRl
:::ZCh0bXAuZ2xvYignKi5qcGcnKSwKICAgICAgICAgICAgICAgICAgICAgIGtleT1s
:::YW1iZGEgcTogcS5zdGF0KCkuc3RfbXRpbWUsIHJldmVyc2U9VHJ1ZSkKICAgICAg
:::ICBpZiBqcGdzOgogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBjYXJh
:::dHVsYSA9IGpwZ3NbMF0ucmVhZF9ieXRlcygpCiAgICAgICAgICAgIGV4Y2VwdCBP
:::U0Vycm9yOgogICAgICAgICAgICAgICAgY2FyYXR1bGEgPSBOb25lCiAgICBhcGxp
:::Y2FyX3RhZ3MoaW5mbywgd21hLCBsb2csIGNhcmF0dWxhKQogICAgc2h1dGlsLnJt
:::dHJlZSh0bXAsIGlnbm9yZV9lcnJvcnM9VHJ1ZSkKICAgIHJldHVybiBpbmZvLCB3
:::bWEKCgpkZWYgbWV0YV9yaWZmX2luZm8oaW5mbyk6CiAgICAiIiJ2Mi43OiBhcmd1
:::bWVudG9zIC1tZXRhZGF0YSBwYXJhIGxvcyB0YWdzIFJJRkYgSU5GTyBkZWwgQVZJ
:::LgoKICAgIEZGbXBlZyBsb3MgbWFwZWEgYSBJTkFNICh0aXR1bG8pLCBJQVJUIChh
:::cnRpc3RhKSwgSVBSRCAoYWxidW0pLAogICAgSUNSRCAoZmVjaGEpIGUgSUNNVCAo
:::Y29tZW50YXJpbykgZGVudHJvIGRlbCBjaHVuayBMSVNUL0lORk8gZGVsCiAgICBS
:::SUZGLCBxdWUgZXMgZG9uZGUgbG9zIHJlcHJvZHVjdG9yZXMgYnVzY2FuIGxvcyBk
:::YXRvcyBkZSB1biBBVkkuIiIiCiAgICB0aXR1bG8gPSBzdHIoaW5mby5nZXQoJ3Ry
:::YWNrJykgb3IgaW5mby5nZXQoJ3RpdGxlJykgb3IgJycpLnN0cmlwKCkKICAgIGFy
:::dGlzdGEgPSBfYXJ0aXN0YV9saW1waW8oaW5mbykKICAgIGFsYnVtID0gX2FsYnVt
:::X2RlKGluZm8pCiAgICBmZWNoYSA9IHN0cihpbmZvLmdldCgncmVsZWFzZV95ZWFy
:::Jykgb3IgJycpCiAgICBpZiBub3QgZmVjaGE6CiAgICAgICAgZmVjaGEgPSBzdHIo
:::aW5mby5nZXQoJ3VwbG9hZF9kYXRlJykgb3IgJycpWzo0XQogICAgdXJsID0gc3Ry
:::KGluZm8uZ2V0KCd3ZWJwYWdlX3VybCcpIG9yICcnKS5zdHJpcCgpCiAgICBtZXRh
:::ID0gW10KICAgIGlmIHRpdHVsbzoKICAgICAgICBtZXRhICs9IFsnLW1ldGFkYXRh
:::JywgJ3RpdGxlPScgKyB0aXR1bG9dCiAgICBpZiBhcnRpc3RhOgogICAgICAgIG1l
:::dGEgKz0gWyctbWV0YWRhdGEnLCAnYXJ0aXN0PScgKyBhcnRpc3RhXQogICAgaWYg
:::YWxidW06CiAgICAgICAgbWV0YSArPSBbJy1tZXRhZGF0YScsICdhbGJ1bT0nICsg
:::YWxidW1dCiAgICBpZiBmZWNoYToKICAgICAgICBtZXRhICs9IFsnLW1ldGFkYXRh
:::JywgJ2RhdGU9JyArIGZlY2hhXQogICAgaWYgdXJsOgogICAgICAgIG1ldGEgKz0g
:::WyctbWV0YWRhdGEnLCAnY29tbWVudD0nICsgdXJsXQogICAgcmV0dXJuIG1ldGEK
:::CgojIFBhcsOhbWV0cm9zIG9maWNpYWxlcyBkZWwgcmVwbyBmZGQ0cy9wb3J0YWJs
:::ZV9tcDNfcGxheWVyX3ZpZGVvX2NvbnZlcnRlcl90b29scwojICh2aWRlbzJzaGVu
:::anUxOC5zaCk6IE1KUEVHIDE2IGZwcyArIFBDTSAyMjA1MCBIeiwgcm90YWRvcyBw
:::YXJhIGxhIHBhbnRhbGxhCiMgdmVydGljYWwgZGUgMTI4eDE2MCBkZWwgcmVwcm9k
:::dWN0b3Igc2hlaWp1IGRlIDEuOCBwdWxnYWRhcy4KVkZfU0hFSUpVID0gJ3NjYWxl
:::PS0yOjEyOCwgY3JvcD0xNjA6MTI4LCB0cmFuc3Bvc2U9MiwgdmZsaXAnCiMgVmFy
:::aWFudGUgYSBwcnVlYmEgZGUgYmFsYXMgcGFyYSB2aWRlb3MgY3VhZHJhZG9zL3Zl
:::cnRpY2FsZXMgKFNob3J0cyksCiMgZG9uZGUgZWwgcmVjb3J0ZSAxNjA6MTI4IG9y
:::aWdpbmFsIHNlcsOtYSBpbXBvc2libGU6ClZGX1NFR1VSTyA9ICgnc2NhbGU9MTYw
:::OjEyODpmb3JjZV9vcmlnaW5hbF9hc3BlY3RfcmF0aW89ZGVjcmVhc2UsJwogICAg
:::ICAgICAgICAgJ3BhZD0xNjA6MTI4Oihvdy1pdykvMjoob2gtaWgpLzIsdHJhbnNw
:::b3NlPTIsdmZsaXAnKQoKCmRlZiBkZXNjYXJnYXJfYXZpKHVybCwgZGVzdGlubywg
:::Y29sYSk6CiAgICAiIiJWaWRlbyBBVkkgcGFyYSBlbCByZXByb2R1Y3RvciBzaGVp
:::anUgMS44IiAxMjh4MTYwLiIiIgogICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAg
:::ICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICBjYXJwZXRhID0gZGVz
:::dGlubyAgICAgICAgICAjIHYyLjM6IHNpbiBzdWJjYXJwZXRhcyBwb3IgZm9ybWF0
:::bwogICAgdG1wID0gY2FycGV0YSAvICdfdG1wJwogICAgc2h1dGlsLnJtdHJlZSh0
:::bXAsIGlnbm9yZV9lcnJvcnM9VHJ1ZSkKICAgIHRtcC5ta2RpcihwYXJlbnRzPVRy
:::dWUsIGV4aXN0X29rPVRydWUpCiAgICBvID0gb3B0c19iYXNlKHRtcCwgY29sYSkK
:::ICAgICMgUGFyYSB1bmEgcGFudGFsbGEgZGUgMTI4eDE2MCBiYXN0YSBjb24gNDgw
:::cDogYWhvcnJhIG11Y2hhIGRlc2NhcmdhLgogICAgb1snZm9ybWF0J10gPSAoJ2Jl
:::c3RbaGVpZ2h0PD00ODBdW2V4dD1tcDRdL2Jlc3RbaGVpZ2h0PD00ODBdLycKICAg
:::ICAgICAgICAgICAgICAgICdidipbaGVpZ2h0PD00ODBdK2JhL2InKQogICAgb1sn
:::bWVyZ2Vfb3V0cHV0X2Zvcm1hdCddID0gJ21wNCcKICAgIHdpdGggWVRfRExQLllv
:::dXR1YmVETChvKSBhcyB5ZGw6CiAgICAgICAgaW5mbyA9IHlkbC5leHRyYWN0X2lu
:::Zm8odXJsLCBkb3dubG9hZD1UcnVlKQogICAgb3JpZ2VuID0gYXJjaGl2b19maW5h
:::bChpbmZvLCB0bXAsICdtcDQnKQogICAgaWYgbm90IG9yaWdlbjoKICAgICAgICBv
:::cmlnZW4gPSAoYXJjaGl2b19maW5hbChpbmZvLCB0bXAsICdta3YnKQogICAgICAg
:::ICAgICAgICAgICBvciBhcmNoaXZvX2ZpbmFsKGluZm8sIHRtcCwgJ3dlYm0nKSkK
:::ICAgIGlmIG5vdCBvcmlnZW46CiAgICAgICAgcmFpc2UgUnVudGltZUVycm9yKCdO
:::byBzZSBlbmNvbnRyw7MgZWwgdmlkZW8gZGVzY2FyZ2Fkby4nKQogICAgYXZpID0g
:::Y2FycGV0YSAvIChsaW1waWFyX25vbWJyZShpbmZvLmdldCgndGl0bGUnKSBvciAn
:::dmlkZW8nKSArICcuYXZpJykKICAgICMgdjIuNzogZXRpcXVldGFzIFJJRkYgSU5G
:::TyBkZW50cm8gZGVsIEFWSSAodmVyIG1ldGFfcmlmZl9pbmZvKQogICAgIyBwYXJh
:::IHF1ZSBlbCB2aWRlbyB0YW1iaWVuIG11ZXN0cmUgdGl0dWxvIHkgYXJ0aXN0YSBk
:::b25kZSBlbAogICAgIyByZXByb2R1Y3RvciBzZXBhIGxlZXJsYXMuCiAgICBtZXRh
:::ID0gbWV0YV9yaWZmX2luZm8oaW5mbykKICAgIGJhc2UgPSBbc3RyKEZGTVBFRyks
:::ICcteScsICctaScsIHN0cihvcmlnZW4pLCAnLXInLCAnMTYnLAogICAgICAgICAg
:::ICAnLWFjb2RlYycsICdwY21fczE2bGUnLCAnLWFjJywgJzInLCAnLWFyJywgJzIy
:::MDUwJywKICAgICAgICAgICAgJy1waXhfZm10JywgJ3l1dmo0MjBwJywgJy1jOnYn
:::LCAnbWpwZWcnLCAnLXE6dicsICcyJ10gKyBtZXRhCiAgICBvayA9IGNvbnZlcnRp
:::cl9mZm1wZWcoYmFzZSArIFsnLXZmJywgVkZfU0hFSUpVLCBzdHIoYXZpKV0sCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgJ0NvbnZpcnRpZW5kbyBhIEFWSSAxMjh4
:::MTYwIChzaGVpanUgMS44IiknLCBjb2xhKQogICAgaWYgbm90IG9rOgogICAgICAg
:::IGxvZygnVmlkZW8gY29uIHByb3BvcmNpw7NuIG5vIGVzdMOhbmRhcjsgJwogICAg
:::ICAgICAgICAncmVpbnRlbnRhbmRvIGVuIG1vZG8gY29tcGF0aWJsZS4uLicsICdh
:::dmlzbycpCiAgICAgICAgb2sgPSBjb252ZXJ0aXJfZmZtcGVnKGJhc2UgKyBbJy12
:::ZicsIFZGX1NFR1VSTywgc3RyKGF2aSldLAogICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAnUmVjb252aXJ0aWVuZG8gYSBBVkkgMTI4eDE2MCcsIGNvbGEpCiAg
:::ICBpZiBub3Qgb2s6CiAgICAgICAgcmFpc2UgUnVudGltZUVycm9yKCdGRm1wZWcg
:::bm8gcHVkbyBjcmVhciBlbCBhcmNoaXZvIEFWSS4nKQogICAgc2h1dGlsLnJtdHJl
:::ZSh0bXAsIGlnbm9yZV9lcnJvcnM9VHJ1ZSkKICAgIHJldHVybiBpbmZvLCBhdmkK
:::CgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0gZXN0aW1hY2nDs24KS0JQU19FU1RJTUFET1Mg
:::PSB7CiAgICAnQUFDJzogMTI4LCAgICAgIyB0ZWNobyBkZWwgZm9ybWF0bwogICAg
:::J1dNQSc6IDEyOCwKICAgICdXQVYnOiAxNDExLCAgICAjIFBDTSA0NC4xIGtIeiDC
:::tyAxNiBiaXQgwrcgZXN0w6lyZW8KICAgICdGTEFDJzogOTUwLCAgICAjIHTDrXBp
:::Y28gZGUgbcO6c2ljYSBwcm9jZWRlbnRlIGRlIFlvdVR1YmUKICAgICdBVkknOiAx
:::NDkwLCAgICAjIH43ODQga2JwcyBNSlBFRyAxNmZwcyArIDcwNiBrYnBzIFBDTSAy
:::MjA1MCBlc3TDqXJlbwp9CgoKZGVmIGVzdGltYXJfYnl0ZXMoZHVyYWNpb25fcywg
:::Zm9ybWF0bywgY2FsaWRhZCwgZW1iZWJlcik6CiAgICAiIiJFc3RpbWEgZWwgdGFt
:::YcOxbyBmaW5hbCBlbiBieXRlcyAoY8OhbGN1bG8gcHVybywgdGVzdGVhYmxlKS4i
:::IiIKICAgIGlmIGZvcm1hdG8gaW4gKCdNUDMnLCAnQUFDJywgJ1dNQScpOgogICAg
:::ICAgIGticHMgPSBpbnQocmUuc3ViKHInW14wLTldJywgJycsIHN0cihjYWxpZGFk
:::KSkgb3IgMCkKICAgICAgICBpZiBub3Qga2JwczoKICAgICAgICAgICAga2JwcyA9
:::IEtCUFNfRVNUSU1BRE9TLmdldChmb3JtYXRvLCAxMjgpCiAgICBlbHNlOgogICAg
:::ICAgIGticHMgPSBLQlBTX0VTVElNQURPUy5nZXQoZm9ybWF0bywgMTI4KQogICAg
:::ZXh0cmEgPSAxMjBfMDAwIGlmIChlbWJlYmVyIGFuZCBmb3JtYXRvIGluICgnQUFD
:::JywgJ01QMycsICdGTEFDJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgJ1dBVicpKSBlbHNlIDAKICAgIHJldHVybiBkdXJh
:::Y2lvbl9zICoga2JwcyAqIDEwMDAgLyA4ICsgZXh0cmEKCgojIC0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0gY2FsaWRhZApkZWYgY2xhc2VfY2FsaWRhZChleHQsIGticHMpOgogICAg
:::IiIiQ2xhc2lmaWNhIHVuIGFyY2hpdm8uIERldnVlbHZlICh0ZXh0bywgbml2ZWwp
:::IGNvbiBuaXZlbCAwPW9rIDE9bWVkaWEgMj1iYWphLiIiIgogICAgaWYgZXh0ID09
:::ICcubXAzJzoKICAgICAgICBpZiBrYnBzID49IDMxNToKICAgICAgICAgICAgcmV0
:::dXJuICczMjAga2JwcycsIDAKICAgICAgICBpZiBrYnBzID49IDI1MDoKICAgICAg
:::ICAgICAgcmV0dXJuICcyNTYga2JwcycsIDAKICAgICAgICBpZiBrYnBzID49IDE4
:::NToKICAgICAgICAgICAgcmV0dXJuICcxOTIga2JwcycsIDAKICAgICAgICBpZiBr
:::YnBzID49IDEyMDoKICAgICAgICAgICAgcmV0dXJuICcxMjgga2JwcycsIDEKICAg
:::ICAgICByZXR1cm4gZid7a2Jwc30ga2JwcyAoYmFqYSknLCAyCiAgICBpZiBleHQg
:::PT0gJy5tNGEnOgogICAgICAgIGlmIGticHMgPj0gMTE1OgogICAgICAgICAgICBy
:::ZXR1cm4gJ0V4Y2VsZW50ZSAoQUFDIOKJpDEyOGspJywgMAogICAgICAgIGlmIGti
:::cHMgPj0gODI6CiAgICAgICAgICAgIHJldHVybiAnOTYga2JwcycsIDEKICAgICAg
:::ICByZXR1cm4gZid7a2Jwc30ga2JwcyAoYmFqYSknLCAyCiAgICBpZiBleHQgPT0g
:::Jy53bWEnOgogICAgICAgIGlmIGticHMgPj0gMTE1OgogICAgICAgICAgICByZXR1
:::cm4gJzEyOCBrYnBzJywgMAogICAgICAgIGlmIGticHMgPj0gODg6CiAgICAgICAg
:::ICAgIHJldHVybiAnOTYga2JwcycsIDEKICAgICAgICByZXR1cm4gZid7a2Jwc30g
:::a2JwcyAoYmFqYSknLCAyCiAgICBpZiBleHQgaW4gKCcuZmxhYycsICcud2F2Jyk6
:::CiAgICAgICAgcmV0dXJuICdTaW4gcMOpcmRpZGEnLCAwCiAgICBpZiBleHQgPT0g
:::Jy5hdmknOgogICAgICAgIGlmIGticHMgPj0gMTIwMDoKICAgICAgICAgICAgcmV0
:::dXJuIGYne2ticHN9IGticHMgKE1KUEVHK1BDTSAxMjh4MTYwKScsIDAKICAgICAg
:::ICByZXR1cm4gZid7a2Jwc30ga2JwcyAoYWxnbyBiYWpvKScsIDEKICAgIHJldHVy
:::biBmJ3trYnBzfSBrYnBzJywgMQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSB0ZW1hcwpU
:::RU1BUyA9IHsKICAgICdPc2N1cm8nOiBkaWN0KAogICAgICAgIGZvbmRvPScjMWUx
:::ZjIyJywgY2FtcG89JyMyYTJkMzEnLCBjYW1wb19ib3JkZT0nIzNhM2U0NCcsCiAg
:::ICAgICAgdGV4dG89JyNkOGRhZGMnLCB0ZXh0bzI9JyM5YTlmYTQnLAogICAgICAg
:::IGJvdG9uPScjM2EzZDQyJywgYm90b25fYWN0PScjNGE0ZTU1JywgYm90b25fdHh0
:::PScjZThlYWVjJywKICAgICAgICBsb2c9JyMxNDE1MTgnLCBsb2dfdHh0PScjY2Zk
:::M2Q3JywgYWNlbnRvPScjNGY5Y2Y5JywKICAgICAgICBvaz0nIzdlYzk3ZicsIGVy
:::cm9yPScjZTU3MzczJywgYXZpc289JyNkOGI2NGEnLCB0cm91Z2g9JyMyNjI4MmMn
:::LAogICAgICAgIHBsYWNlaG9sZGVyPScjNzc3YzgyJyksCiAgICAnQ2xhcm8nOiBk
:::aWN0KAogICAgICAgIGZvbmRvPScjZjJmM2Y1JywgY2FtcG89JyNmZmZmZmYnLCBj
:::YW1wb19ib3JkZT0nI2M0YzhjZCcsCiAgICAgICAgdGV4dG89JyMyNDI3MmEnLCB0
:::ZXh0bzI9JyM2YTcwNzYnLAogICAgICAgIGJvdG9uPScjZTNlNWU4JywgYm90b25f
:::YWN0PScjZDJkNWRhJywgYm90b25fdHh0PScjMjQyNzJhJywKICAgICAgICBsb2c9
:::JyNmZmZmZmYnLCBsb2dfdHh0PScjMmIyZTMxJywgYWNlbnRvPScjMWE2NmQ2JywK
:::ICAgICAgICBvaz0nIzFlN2UzNCcsIGVycm9yPScjYzYyODI4JywgYXZpc289JyM5
:::YTY3MDAnLCB0cm91Z2g9JyNkZmUxZTQnLAogICAgICAgIHBsYWNlaG9sZGVyPScj
:::OWFhMGE2JyksCn0KClBMQUNFSE9MREVSX1VSTCA9ICdodHRwczovL3d3dy55b3V0
:::dWJlLmNvbS93YXRjaD92PS4uLicKCkZVRU5URV9VSSA9ICgnU2Vnb2UgVUknLCA5
:::KQpGVUVOVEVfQlROID0gKCdTZWdvZSBVSScsIDEwKQpGVUVOVEVfQlROX0cgPSAo
:::J1NlZ29lIFVJJywgMTEpCkZVRU5URV9MT0cgPSAoJ0NvbnNvbGFzJywgMTApCgoK
:::aWYgVEtfT0s6CgogICAgY2xhc3MgQXBwKHRrLlRrKToKICAgICAgICAiIiJWZW50
:::YW5hIHByaW5jaXBhbCAoZGlzZcOxbyBlc3Blam8gZGVsIG1vY2t1cDogZ3J1cG9z
:::IG9zY3Vyb3MpLiIiIgoKICAgICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBjb25zdHJ1Y2Npw7NuCiAgICAgICAg
:::ZGVmIF9faW5pdF9fKHNlbGYpOgogICAgICAgICAgICBpZiBnZXRhdHRyKHN5cywg
:::J2Zyb3plbicsIEZhbHNlKToKICAgICAgICAgICAgICAgIHBhc3MKICAgICAgICAg
:::ICAgc3VwZXIoKS5fX2luaXRfXygpCiAgICAgICAgICAgIHNlbGYudGl0bGUoJ011
:::c2lrQUxBTicpCiAgICAgICAgICAgIHNlbGYuZ2VvbWV0cnkoJzg2MHg4NDAnKQog
:::ICAgICAgICAgICBzZWxmLm1pbnNpemUoNzAwLCA2NjApCiAgICAgICAgICAgIHNl
:::bGYuY29sYSA9IHF1ZXVlLlF1ZXVlKCkKICAgICAgICAgICAgc2VsZi5fb2N1cGFk
:::byA9IEZhbHNlCiAgICAgICAgICAgIHNlbGYuX2VuX3BsYWNlaG9sZGVyID0gVHJ1
:::ZQogICAgICAgICAgICBzZWxmLl90ZW1hX2FjdHVhbCA9IEFKVVNURVMuZ2V0KCd0
:::ZW1hJywgJ09zY3VybycpCiAgICAgICAgICAgIGlmIHNlbGYuX3RlbWFfYWN0dWFs
:::IG5vdCBpbiBURU1BUzoKICAgICAgICAgICAgICAgIHNlbGYuX3RlbWFfYWN0dWFs
:::ID0gJ09zY3VybycKCiAgICAgICAgICAgIHNlbGYuX2VzdGlsbyA9IHR0ay5TdHls
:::ZShzZWxmKQogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBzZWxmLl9l
:::c3RpbG8udGhlbWVfdXNlKCdjbGFtJykKICAgICAgICAgICAgZXhjZXB0IEV4Y2Vw
:::dGlvbjoKICAgICAgICAgICAgICAgIHBhc3MKCiAgICAgICAgICAgIHNlbGYuX2Nv
:::bnN0cnVpcigpCiAgICAgICAgICAgIHNlbGYuX2FwbGljYXJfdGVtYSgpCiAgICAg
:::ICAgICAgIHNlbGYuX2NvbmVjdGFyX2V2ZW50b3MoKQogICAgICAgICAgICBSRUdJ
:::U1RSTy5sb2cgPSBsYW1iZGEgbSwgdD0nYXZpc28nOiBzZWxmLmNvbGEucHV0KCgn
:::bG9nJywgbSwgdCkpCiAgICAgICAgICAgIHNlbGYuYWZ0ZXIoODAsIHNlbGYuX2Jv
:::bWJlYXJfY29sYSkKICAgICAgICAgICAgc2VsZi5hZnRlcigxNTAsIHNlbGYuX2Fy
:::cmFucXVlKQoKICAgICAgICBkZWYgX2NvbnN0cnVpcihzZWxmKToKICAgICAgICAg
:::ICAgc2VsZi5fd2cgPSB7fSAgICAgICAgICMgcmVmZXJlbmNpYXMgcGFyYSBlbCB0
:::ZW1hCiAgICAgICAgICAgIHNlbGYuX2J0bnMgPSBbXSAgICAgICAjIGJvdG9uZXMg
:::cGxhbm9zIChwYXJhIGhvdmVyL3RlbWEpCiAgICAgICAgICAgIG1hcmNvID0gdGsu
:::RnJhbWUoc2VsZikKICAgICAgICAgICAgbWFyY28ucGFjayhmaWxsPSdib3RoJywg
:::ZXhwYW5kPVRydWUsIHBhZHg9MTAsIHBhZHk9OCkKICAgICAgICAgICAgc2VsZi5f
:::d2dbJ21hcmNvJ10gPSBtYXJjbwogICAgICAgICAgICBtYXJjby5jb2x1bW5jb25m
:::aWd1cmUoMCwgd2VpZ2h0PTEpCgogICAgICAgICAgICAjIC0tLSBmaWxhIFRlbWEg
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::CiAgICAgICAgICAgIGYwID0gdGsuRnJhbWUobWFyY28pCiAgICAgICAgICAgIGYw
:::LmdyaWQocm93PTAsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgcGFkeT0oMCwgNikp
:::CiAgICAgICAgICAgIHNlbGYuX3dnWydmMCddID0gZjAKICAgICAgICAgICAgc2Vs
:::Zi5fd2dbJ2xibF90ZW1hJ10gPSB0ay5MYWJlbChmMCwgdGV4dD0nVGVtYTonLCBm
:::b250PUZVRU5URV9VSSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF90ZW1hJ10u
:::cGFjayhzaWRlPSdsZWZ0JykKICAgICAgICAgICAgc2VsZi5jbWJfdGVtYSA9IHR0
:::ay5Db21ib2JveCgKICAgICAgICAgICAgICAgIGYwLCB2YWx1ZXM9bGlzdChURU1B
:::UyksIHN0YXRlPSdyZWFkb25seScsIHdpZHRoPTksCiAgICAgICAgICAgICAgICBm
:::b250PUZVRU5URV9VSSwgc3R5bGU9J2d4LlRDb21ib2JveCcpCiAgICAgICAgICAg
:::IHNlbGYuY21iX3RlbWEuc2V0KHNlbGYuX3RlbWFfYWN0dWFsKQogICAgICAgICAg
:::ICBzZWxmLmNtYl90ZW1hLnBhY2soc2lkZT0nbGVmdCcsIHBhZHg9KDgsIDApLCBp
:::cGFkeT0yKQoKICAgICAgICAgICAgIyAtLS0gZ3J1cG86IFVSTCBkZSBZb3VUdWJl
:::IC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAgICAg
:::ICBndSA9IHRrLkxhYmVsRnJhbWUobWFyY28sIHRleHQ9J1VSTCBkZSBZb3VUdWJl
:::JywgZm9udD1GVUVOVEVfVUksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICByZWxpZWY9J3NvbGlkJywgYmQ9MSkKICAgICAgICAgICAgZ3UuZ3JpZChyb3c9
:::MSwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PTUpCiAgICAgICAgICAgIHNl
:::bGYuX3dnWydndSddID0gZ3UKICAgICAgICAgICAgZ3UuY29sdW1uY29uZmlndXJl
:::KDAsIHdlaWdodD0xKQogICAgICAgICAgICBzZWxmLmVudF91cmwgPSB0ay5FbnRy
:::eShndSwgZm9udD1GVUVOVEVfVUksIHJlbGllZj0nZmxhdCcsCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgIGhpZ2hsaWdodHRoaWNrbmVzcz0xKQog
:::ICAgICAgICAgICBzZWxmLmVudF91cmwuZ3JpZChyb3c9MCwgY29sdW1uPTAsIHN0
:::aWNreT0nZXcnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4PTgs
:::IHBhZHk9OCwgaXBhZHk9NSkKICAgICAgICAgICAgc2VsZi5fcG9uZXJfcGxhY2Vo
:::b2xkZXIoKQogICAgICAgICAgICAjIHYyLjEyOiBib3RvbiBQZWdhciAocGVnYSBl
:::bCBlbmxhY2UgZGVsIHBvcnRhcGFwZWxlcykgKyBYCiAgICAgICAgICAgIHNlbGYu
:::YnRuX3BlZ2FyID0gc2VsZi5fYm90b24oZ3UsICdQZWdhcicsIHNlbGYuX3BlZ2Fy
:::X3VybCkKICAgICAgICAgICAgc2VsZi5idG5fcGVnYXIuZ3JpZChyb3c9MCwgY29s
:::dW1uPTEsIHN0aWNreT0nZScsIHBhZHg9KDAsIDQpLAogICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgIGlwYWR5PTMpCiAgICAgICAgICAgIHNlbGYuYnRuX3gg
:::PSBzZWxmLl9ib3RvbihndSwgJ1gnLCBzZWxmLl9saW1waWFyX3VybCwgd2lkdGg9
:::MykKICAgICAgICAgICAgc2VsZi5idG5feC5ncmlkKHJvdz0wLCBjb2x1bW49Miwg
:::c3RpY2t5PSdlJywgcGFkeD0oMCwgOCksIGlwYWR5PTMpCgogICAgICAgICAgICAj
:::IC0tLSBncnVwbzogRm9ybWF0byB5IGNhbGlkYWQgLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAgIGdmID0gdGsuTGFiZWxGcmFtZSht
:::YXJjbywgdGV4dD0nRm9ybWF0byB5IGNhbGlkYWQnLCBmb250PUZVRU5URV9VSSwK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHJlbGllZj0nc29saWQnLCBi
:::ZD0xKQogICAgICAgICAgICBnZi5ncmlkKHJvdz0yLCBjb2x1bW49MCwgc3RpY2t5
:::PSdldycsIHBhZHk9NSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2dmJ10gPSBnZgog
:::ICAgICAgICAgICBnZi5jb2x1bW5jb25maWd1cmUoMSwgd2VpZ2h0PTEpCiAgICAg
:::ICAgICAgIHNlbGYuX3dnWydsYmxfZm10J10gPSB0ay5MYWJlbChnZiwgdGV4dD0n
:::Rm9ybWF0bzonLCBmb250PUZVRU5URV9VSSkKICAgICAgICAgICAgc2VsZi5fd2db
:::J2xibF9mbXQnXS5ncmlkKHJvdz0wLCBjb2x1bW49MCwgc3RpY2t5PSd3JywgcGFk
:::eD04LCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYuY21iX2Zvcm1hdG8gPSB0dGsu
:::Q29tYm9ib3goCiAgICAgICAgICAgICAgICBnZiwgdmFsdWVzPVtmWyd0ZXh0bydd
:::IGZvciBmIGluIEZPUk1BVE9TLnZhbHVlcygpXSwKICAgICAgICAgICAgICAgIHN0
:::YXRlPSdyZWFkb25seScsIGZvbnQ9RlVFTlRFX1VJLCBzdHlsZT0nZ3guVENvbWJv
:::Ym94JykKICAgICAgICAgICAgc2VsZi5jbWJfZm9ybWF0by5ncmlkKHJvdz0wLCBj
:::b2x1bW49MSwgc3RpY2t5PSdldycsCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICBwYWR4PTgsIHBhZHk9NSwgaXBhZHk9MikKICAgICAgICAgICAgc2Vs
:::Zi5fd2dbJ2xibF9jYWwnXSA9IHRrLkxhYmVsKGdmLCB0ZXh0PSdDYWxpZGFkOics
:::IGZvbnQ9RlVFTlRFX1VJKQogICAgICAgICAgICBzZWxmLl93Z1snbGJsX2NhbCdd
:::LmdyaWQocm93PTEsIGNvbHVtbj0wLCBzdGlja3k9J3cnLCBwYWR4PTgsIHBhZHk9
:::NSkKICAgICAgICAgICAgc2VsZi5jbWJfY2FsaWRhZCA9IHR0ay5Db21ib2JveCgK
:::ICAgICAgICAgICAgICAgIGdmLCBzdGF0ZT0ncmVhZG9ubHknLCBmb250PUZVRU5U
:::RV9VSSwgc3R5bGU9J2d4LlRDb21ib2JveCcpCiAgICAgICAgICAgIHNlbGYuY21i
:::X2NhbGlkYWQuZ3JpZChyb3c9MSwgY29sdW1uPTEsIHN0aWNreT0nZXcnLAogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFkeD04LCBwYWR5PTUsIGlw
:::YWR5PTIpCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfY2FyJ10gPSB0ay5MYWJl
:::bChnZiwgdGV4dD0nQ2FycGV0YTonLCBmb250PUZVRU5URV9VSSkKICAgICAgICAg
:::ICAgc2VsZi5fd2dbJ2xibF9jYXInXS5ncmlkKHJvdz0yLCBjb2x1bW49MCwgc3Rp
:::Y2t5PSd3JywgcGFkeD04LCBwYWR5PTUpCiAgICAgICAgICAgIGZjID0gdGsuRnJh
:::bWUoZ2YpCiAgICAgICAgICAgIGZjLmdyaWQocm93PTIsIGNvbHVtbj0xLCBzdGlj
:::a3k9J2V3JywgcGFkeD04LCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYuX3dnWydm
:::YyddID0gZmMKICAgICAgICAgICAgZmMuY29sdW1uY29uZmlndXJlKDAsIHdlaWdo
:::dD0xKQogICAgICAgICAgICBzZWxmLmVudF9jYXJwZXRhID0gdGsuRW50cnkoZmMs
:::IGZvbnQ9RlVFTlRFX1VJLCByZWxpZWY9J2ZsYXQnLAogICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgaGlnaGxpZ2h0dGhpY2tuZXNzPTEpCiAg
:::ICAgICAgICAgIHNlbGYuZW50X2NhcnBldGEuZ3JpZChyb3c9MCwgY29sdW1uPTAs
:::IHN0aWNreT0nZXcnLCBpcGFkeT00KQogICAgICAgICAgICBzZWxmLmVudF9jYXJw
:::ZXRhLmluc2VydCgwLCBBSlVTVEVTWydkZXN0aW5vJ10pCiAgICAgICAgICAgIHNl
:::bGYuYnRuX2NhbWJpYXIgPSBzZWxmLl9ib3RvbihmYywgJ0NhbWJpYXIuLi4nLCBz
:::ZWxmLl9jYW1iaWFyX2NhcnBldGEpCiAgICAgICAgICAgIHNlbGYuYnRuX2NhbWJp
:::YXIuZ3JpZChyb3c9MCwgY29sdW1uPTEsIHBhZHg9KDgsIDApLCBpcGFkeT0zKQog
:::ICAgICAgICAgICBzZWxmLmJ0bl9hYnJpciA9IHNlbGYuX2JvdG9uKGZjLCAnQWJy
:::aXInLCBzZWxmLl9hYnJpcl9kZXN0aW5vLCB3aWR0aD01KQogICAgICAgICAgICBz
:::ZWxmLmJ0bl9hYnJpci5ncmlkKHJvdz0wLCBjb2x1bW49MiwgcGFkeD0oNiwgMCks
:::IGlwYWR5PTMpCgogICAgICAgICAgICBzZWxmLnZhcl9lbWJlYmVyID0gdGsuQm9v
:::bGVhblZhcih2YWx1ZT1ib29sKEFKVVNURVMuZ2V0KCdlbWJlYmVyJywgVHJ1ZSkp
:::KQogICAgICAgICAgICBzZWxmLmNoa19lbWJlYmVyID0gdGsuQ2hlY2tidXR0b24o
:::CiAgICAgICAgICAgICAgICBnZiwgdGV4dD0nRW1iZWJlciBjYXLDoXR1bGEsIGFy
:::dGlzdGEgeSDDoWxidW0nLAogICAgICAgICAgICAgICAgdmFyaWFibGU9c2VsZi52
:::YXJfZW1iZWJlciwgZm9udD1GVUVOVEVfVUksIGFuY2hvcj0ndycsCiAgICAgICAg
:::ICAgICAgICByZWxpZWY9J2ZsYXQnLCBoaWdobGlnaHR0aGlja25lc3M9MCwgYmQ9
:::MCkKICAgICAgICAgICAgc2VsZi5jaGtfZW1iZWJlci5ncmlkKHJvdz0zLCBjb2x1
:::bW49MCwgY29sdW1uc3Bhbj0yLAogICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgc3RpY2t5PSdldycsIHBhZHg9OCwgcGFkeT0oMiwgNikpCiAgICAgICAg
:::ICAgICMgdjIuOTogdsOtYSBhbnRpLWJsb3F1ZW8gKGNvb2tpZXMgZGVsIG5hdmVn
:::YWRvciBzaSBZb3VUdWJlCiAgICAgICAgICAgICMgcGlkZSB2ZXJpZmljYWNpw7Nu
:::KQogICAgICAgICAgICBzZWxmLl93Z1snbGJsX2Nvb2tpZXMnXSA9IHRrLkxhYmVs
:::KAogICAgICAgICAgICAgICAgZ2YsIHRleHQ9J1NpIFlvdVR1YmUgYmxvcXVlYTon
:::LCBmb250PUZVRU5URV9VSSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF9jb29r
:::aWVzJ10uZ3JpZChyb3c9NCwgY29sdW1uPTAsIHN0aWNreT0ndycsCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFkeD04LCBwYWR5PTUp
:::CiAgICAgICAgICAgIHNlbGYuY21iX2Nvb2tpZXMgPSB0dGsuQ29tYm9ib3goCiAg
:::ICAgICAgICAgICAgICBnZiwgdmFsdWVzPShbJ0F1dG9tw6F0aWNvIChyZWNvbWVu
:::ZGFkbyknXQogICAgICAgICAgICAgICAgICAgICAgICAgICAgKyBbJ1VzYXIgY29v
:::a2llcyBkZSAnICsgbi5jYXBpdGFsaXplKCkKICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgIGZvciBuIGluIE5BVkVHQURPUkVTX0NPT0tJRVNdKSwKICAgICAg
:::ICAgICAgICAgIHN0YXRlPSdyZWFkb25seScsIGZvbnQ9RlVFTlRFX1VJLCBzdHls
:::ZT0nZ3guVENvbWJvYm94JykKICAgICAgICAgICAgc2VsZi5jbWJfY29va2llcy5n
:::cmlkKHJvdz00LCBjb2x1bW49MSwgc3RpY2t5PSdldycsCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICBwYWR4PTgsIHBhZHk9NSwgaXBhZHk9MikKICAg
:::ICAgICAgICAgc2VsZi5jbWJfY29va2llcy5zZXQoJ0F1dG9tw6F0aWNvIChyZWNv
:::bWVuZGFkbyknKQoKICAgICAgICAgICAgIyAtLS0gZ3J1cG86IGVzdGltYWNpw7Nu
:::IC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KICAgICAg
:::ICAgICAgZ2UgPSB0ay5MYWJlbEZyYW1lKG1hcmNvLCB0ZXh0PSdFc3RpbWFjacOz
:::bicsIGZvbnQ9RlVFTlRFX1VJLAogICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgcmVsaWVmPSdzb2xpZCcsIGJkPTEpCiAgICAgICAgICAgIGdlLmdyaWQocm93
:::PTMsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgcGFkeT01KQogICAgICAgICAgICBz
:::ZWxmLl93Z1snZ2UnXSA9IGdlCiAgICAgICAgICAgIGdlLmNvbHVtbmNvbmZpZ3Vy
:::ZSgwLCB3ZWlnaHQ9MSkKICAgICAgICAgICAgc2VsZi5sYmxfZXN0aW1hY2lvbiA9
:::IHRrLkxhYmVsKAogICAgICAgICAgICAgICAgZ2UsIHRleHQ9J0ludHJvZHVjZSB1
:::bmEgVVJMIHkgcHVsc2EgRXN0aW1hci4nLAogICAgICAgICAgICAgICAgZm9udD1G
:::VUVOVEVfVUksIGFuY2hvcj0ndycpCiAgICAgICAgICAgIHNlbGYubGJsX2VzdGlt
:::YWNpb24uZ3JpZChyb3c9MCwgY29sdW1uPTAsIHN0aWNreT0nZXcnLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFkeD04LCBwYWR5PTYpCiAg
:::ICAgICAgICAgIHNlbGYuYnRuX2VzdGltYXIgPSBzZWxmLl9ib3RvbihnZSwgJ0Vz
:::dGltYXIgdGFtYW5vJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgIHNlbGYuX2FjY2lvbl9lc3RpbWFyKQogICAgICAgICAgICBzZWxm
:::LmJ0bl9lc3RpbWFyLmdyaWQocm93PTAsIGNvbHVtbj0xLCBzdGlja3k9J2UnLAog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcGFkeD04LCBpcGFkeT0z
:::KQoKICAgICAgICAgICAgIyAtLS0gYm90b25lcyBncmFuZGVzIC0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAgICAgICBzZWxm
:::LmJ0bl9kZXNjYXJnYXIgPSBzZWxmLl9ib3RvbihtYXJjbywgJ0Rlc2NhcmdhciB5
:::IGNvbnZlcnRpcicsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgIHNlbGYuX2FjY2lvbl9kZXNjYXJnYXIsCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGZ1ZW50ZT1GVUVOVEVfQlRO
:::X0csIGFsdG89MikKICAgICAgICAgICAgc2VsZi5idG5fZGVzY2FyZ2FyLmdyaWQo
:::cm93PTQsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgcGFkeT0oNywgNCkpCiAgICAg
:::ICAgICAgIHNlbGYuYnRuX2NvbXByb2JhciA9IHNlbGYuX2JvdG9uKAogICAgICAg
:::ICAgICAgICAgbWFyY28sICdDb21wcm9iYXIgY2FsaWRhZCBkZSBsYSBjYXJwZXRh
:::JywKICAgICAgICAgICAgICAgIHNlbGYuX2FjY2lvbl9jb21wcm9iYXIsIGZ1ZW50
:::ZT1GVUVOVEVfQlROKQogICAgICAgICAgICBzZWxmLmJ0bl9jb21wcm9iYXIuZ3Jp
:::ZChyb3c9NSwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PTMpCgogICAgICAg
:::ICAgICAjIC0tLSBlc3RhZG8gKyBiYXJyYSBkZSBwcm9ncmVzbyAtLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAgICAgICBzZWxmLmxibF9lc3Rh
:::ZG8gPSB0ay5MYWJlbChtYXJjbywgdGV4dD0nJywgZm9udD1GVUVOVEVfVUksCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGFuY2hvcj0ndycp
:::CiAgICAgICAgICAgIHNlbGYubGJsX2VzdGFkby5ncmlkKHJvdz02LCBjb2x1bW49
:::MCwgc3RpY2t5PSdldycsIHBhZHk9KDQsIDApKQogICAgICAgICAgICBzZWxmLmJh
:::cnJhID0gdHRrLlByb2dyZXNzYmFyKAogICAgICAgICAgICAgICAgbWFyY28sIG1h
:::eGltdW09MTAwLCBzdHlsZT0nZ3guSG9yaXpvbnRhbC5UUHJvZ3Jlc3NiYXInKQog
:::ICAgICAgICAgICBzZWxmLmJhcnJhLmdyaWQocm93PTcsIGNvbHVtbj0wLCBzdGlj
:::a3k9J2V3JywgcGFkeT0oMiwgNCkpCgogICAgICAgICAgICAjIC0tLSByZWdpc3Ry
:::byAobG9nKSAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLQogICAgICAgICAgICBzZWxmLnR4dF9sb2cgPSBTY3JvbGxlZFRleHQobWFy
:::Y28sIGZvbnQ9RlVFTlRFX0xPRywgaGVpZ2h0PTEyLAogICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgcmVsaWVmPSdmbGF0JywgYmQ9MCwgd3Jh
:::cD0nd29yZCcsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICBzdGF0ZT0nZGlzYWJsZWQnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuZ3Jp
:::ZChyb3c9OCwgY29sdW1uPTAsIHN0aWNreT0nbnNldycpCiAgICAgICAgICAgIG1h
:::cmNvLnJvd2NvbmZpZ3VyZSg4LCB3ZWlnaHQ9MSkKICAgICAgICAgICAgZm9yIHRh
:::ZywgY29uZiBpbiAoCiAgICAgICAgICAgICAgICAgICAgKCdpbmZvJywge30pLAog
:::ICAgICAgICAgICAgICAgICAgICgnZ3JpcycsIHt9KSwKICAgICAgICAgICAgICAg
:::ICAgICAoJ3RpdHVsbycsIHt9KSwKICAgICAgICAgICAgICAgICAgICAoJ29rJywg
:::e30pLAogICAgICAgICAgICAgICAgICAgICgnYXZpc28nLCB7fSksCiAgICAgICAg
:::ICAgICAgICAgICAgKCdlcnJvcicsIHt9KSk6CiAgICAgICAgICAgICAgICBzZWxm
:::LnR4dF9sb2cudGFnX2NvbmZpZ3VyZSh0YWcsIGNvbmYpCgogICAgICAgICAgICAj
:::IHNpbmNyb25pemFyIHZhbG9yZXMgZ3VhcmRhZG9zCiAgICAgICAgICAgIGZtdCA9
:::IEFKVVNURVMuZ2V0KCdmb3JtYXRvJywgJ0FBQycpCiAgICAgICAgICAgIGlmIGZt
:::dCBub3QgaW4gRk9STUFUT1M6CiAgICAgICAgICAgICAgICBmbXQgPSAnQUFDJwog
:::ICAgICAgICAgICBzZWxmLmNtYl9mb3JtYXRvLnNldChGT1JNQVRPU1tmbXRdWyd0
:::ZXh0byddKQogICAgICAgICAgICBzZWxmLl9yZWNhcmdhcl9jYWxpZGFkZXMoZm10
:::LCBBSlVTVEVTLmdldCgnY2FsaWRhZCcpKQogICAgICAgICAgICBjb29raWVzID0g
:::c3RyKEFKVVNURVMuZ2V0KCdjb29raWVzJywgJycpIG9yICcnKS5zdHJpcCgpLmxv
:::d2VyKCkKICAgICAgICAgICAgaWYgY29va2llcyBpbiBOQVZFR0FET1JFU19DT09L
:::SUVTOgogICAgICAgICAgICAgICAgc2VsZi5jbWJfY29va2llcy5zZXQoJ1VzYXIg
:::Y29va2llcyBkZSAnCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICArIGNvb2tpZXMuY2FwaXRhbGl6ZSgpKQogICAgICAgICAgICBlbHNlOgogICAg
:::ICAgICAgICAgICAgc2VsZi5jbWJfY29va2llcy5zZXQoJ0F1dG9tw6F0aWNvIChy
:::ZWNvbWVuZGFkbyknKQoKICAgICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBoZWxwZXJzIHdpZGdldHMKICAgICAg
:::ICBkZWYgX2JvdG9uKHNlbGYsIHBhZHJlLCB0ZXh0bywgY21kLCB3aWR0aD1Ob25l
:::LCBmdWVudGU9RlVFTlRFX0JUTiwKICAgICAgICAgICAgICAgICAgIGFsdG89MSk6
:::CiAgICAgICAgICAgIGIgPSB0ay5CdXR0b24ocGFkcmUsIHRleHQ9dGV4dG8sIGNv
:::bW1hbmQ9Y21kLCBmb250PWZ1ZW50ZSwKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICByZWxpZWY9J2ZsYXQnLCBiZD0wLCBjdXJzb3I9J2hhbmQyJywgaGVpZ2h0PWFs
:::dG8sCiAgICAgICAgICAgICAgICAgICAgICAgICAgYWN0aXZlZm9yZWdyb3VuZD0n
:::I2ZmZmZmZicsIHRha2Vmb2N1cz0wKQogICAgICAgICAgICBpZiB3aWR0aDoKICAg
:::ICAgICAgICAgICAgIGIuY29uZmlndXJlKHdpZHRoPXdpZHRoKQogICAgICAgICAg
:::ICBiLmJpbmQoJzxFbnRlcj4nLCBsYW1iZGEgZSwgdz1iOiB3LmNvbmZpZ3VyZSgK
:::ICAgICAgICAgICAgICAgIGJnPVRFTUFTW3NlbGYuX3RlbWFfYWN0dWFsXVsnYm90
:::b25fYWN0J10pKQogICAgICAgICAgICBiLmJpbmQoJzxMZWF2ZT4nLCBsYW1iZGEg
:::ZSwgdz1iOiB3LmNvbmZpZ3VyZSgKICAgICAgICAgICAgICAgIGJnPVRFTUFTW3Nl
:::bGYuX3RlbWFfYWN0dWFsXVsnYm90b24nXSkpCiAgICAgICAgICAgIHNlbGYuX2J0
:::bnMuYXBwZW5kKGIpCiAgICAgICAgICAgIHJldHVybiBiCgogICAgICAgIGRlZiBf
:::cG9uZXJfcGxhY2Vob2xkZXIoc2VsZik6CiAgICAgICAgICAgIGlmIG5vdCBzZWxm
:::LmVudF91cmwuZ2V0KCk6CiAgICAgICAgICAgICAgICBzZWxmLl9lbl9wbGFjZWhv
:::bGRlciA9IFRydWUKICAgICAgICAgICAgICAgIHNlbGYuZW50X3VybC5pbnNlcnQo
:::MCwgUExBQ0VIT0xERVJfVVJMKQoKICAgICAgICBkZWYgX2xpbXBpYXJfdXJsKHNl
:::bGYpOgogICAgICAgICAgICBzZWxmLmVudF91cmwuZGVsZXRlKDAsICdlbmQnKQog
:::ICAgICAgICAgICBzZWxmLmVudF91cmwuZm9jdXNfc2V0KCkKCiAgICAgICAgZGVm
:::IF9wZWdhcl91cmwoc2VsZik6CiAgICAgICAgICAgICIiInYyLjEyOiBwZWdhIGVu
:::IGVsIGNhbXBvIGxhIFVSTCBjb3BpYWRhIGFsIHBvcnRhcGFwZWxlcy4KICAgICAg
:::ICAgICAgU2kgZWwgcG9ydGFwYXBlbGVzIHRyYWUgdGV4dG8gY29uIHVuIGVubGFj
:::ZSBkZW50cm8gKHAuIGVqLgogICAgICAgICAgICAnbWlyYSBlc3RvIGh0dHBzOi8v
:::Li4uJyksIHNlIHF1ZWRhIHNvbG8gY29uIGVsIGVubGFjZS4iIiIKICAgICAgICAg
:::ICAgdHJ5OgogICAgICAgICAgICAgICAgdGV4dG8gPSAoc2VsZi5jbGlwYm9hcmRf
:::Z2V0KCkgb3IgJycpLnN0cmlwKCkKICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlv
:::bjoKICAgICAgICAgICAgICAgIHRleHRvID0gJycKICAgICAgICAgICAgaWYgbm90
:::IHRleHRvOgogICAgICAgICAgICAgICAgc2VsZi5fbG9nKCdFbCBwb3J0YXBhcGVs
:::ZXMgZXN0w6EgdmFjw61vIG8gbm8gdGllbmUgdGV4dG8uJywKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAnYXZpc28nKQogICAgICAgICAgICAgICAgcmV0dXJuCiAg
:::ICAgICAgICAgIG0gPSByZS5zZWFyY2gocidodHRwcz86Ly9bXlxzIlwnXSsnLCB0
:::ZXh0bywgcmUuSSkKICAgICAgICAgICAgaWYgbToKICAgICAgICAgICAgICAgIHRl
:::eHRvID0gbS5ncm91cCgwKQogICAgICAgICAgICBzZWxmLmVudF91cmwuZGVsZXRl
:::KDAsICdlbmQnKQogICAgICAgICAgICBzZWxmLmVudF91cmwuaW5zZXJ0KDAsIHRl
:::eHRvKQogICAgICAgICAgICBzZWxmLl9lbl9wbGFjZWhvbGRlciA9IEZhbHNlCiAg
:::ICAgICAgICAgIHNlbGYuX3JlZnJlc2Nhcl9wbGFjZWhvbGRlcigpCiAgICAgICAg
:::ICAgIHNlbGYuZW50X3VybC5mb2N1c19zZXQoKQoKICAgICAgICBkZWYgX3Jlc2V0
:::X3VybChzZWxmKToKICAgICAgICAgICAgIiIiRGVqYSBlbCBjYW1wbyBkZSBVUkwg
:::dmFjw61vIGNvbiBzdSBwbGFjZWhvbGRlciAodHJhcyB1biDDqXhpdG8pLiIiIgog
:::ICAgICAgICAgICBzZWxmLmVudF91cmwuZGVsZXRlKDAsICdlbmQnKQogICAgICAg
:::ICAgICBzZWxmLl9lbl9wbGFjZWhvbGRlciA9IFRydWUKICAgICAgICAgICAgc2Vs
:::Zi5fcG9uZXJfcGxhY2Vob2xkZXIoKQogICAgICAgICAgICBzZWxmLl9yZWZyZXNj
:::YXJfcGxhY2Vob2xkZXIoKQoKICAgICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSB0ZW1hCiAgICAgICAgZGVmIF9h
:::cGxpY2FyX3RlbWEoc2VsZik6CiAgICAgICAgICAgIHQgPSBURU1BU1tzZWxmLl90
:::ZW1hX2FjdHVhbF0KICAgICAgICAgICAgdyA9IHNlbGYuX3dnCiAgICAgICAgICAg
:::IHNlbGYuY29uZmlndXJlKGJnPXRbJ2ZvbmRvJ10pCiAgICAgICAgICAgIGZvciBu
:::b21icmUgaW4gKCdtYXJjbycsICdmMCcsICdndScsICdnZicsICdmYycsICdnZScp
:::OgogICAgICAgICAgICAgICAgd1tub21icmVdLmNvbmZpZ3VyZShiZz10Wydmb25k
:::byddKQogICAgICAgICAgICBmb3IgbGYgaW4gKHdbJ2d1J10sIHdbJ2dmJ10sIHdb
:::J2dlJ10pOgogICAgICAgICAgICAgICAgbGYuY29uZmlndXJlKGJnPXRbJ2ZvbmRv
:::J10sIGZnPXRbJ3RleHRvMiddKQogICAgICAgICAgICBmb3Igbm9tYnJlIGluICgn
:::bGJsX3RlbWEnLCAnbGJsX2ZtdCcsICdsYmxfY2FsJywgJ2xibF9jYXInKToKICAg
:::ICAgICAgICAgICAgIHdbbm9tYnJlXS5jb25maWd1cmUoYmc9dFsnZm9uZG8nXSwg
:::Zmc9dFsndGV4dG8nXSkKICAgICAgICAgICAgc2VsZi5sYmxfZXN0aW1hY2lvbi5j
:::b25maWd1cmUoYmc9dFsnZm9uZG8nXSwgZmc9dFsndGV4dG8nXSkKICAgICAgICAg
:::ICAgc2VsZi5sYmxfZXN0YWRvLmNvbmZpZ3VyZShiZz10Wydmb25kbyddLCBmZz10
:::Wyd0ZXh0bzInXSkKICAgICAgICAgICAgc2VsZi5lbnRfdXJsLmNvbmZpZ3VyZSgK
:::ICAgICAgICAgICAgICAgIGJnPXRbJ2NhbXBvJ10sIGZnPXRbJ3RleHRvJ10sIGlu
:::c2VydGJhY2tncm91bmQ9dFsndGV4dG8nXSwKICAgICAgICAgICAgICAgIGhpZ2hs
:::aWdodGJhY2tncm91bmQ9dFsnY2FtcG9fYm9yZGUnXSwKICAgICAgICAgICAgICAg
:::IGhpZ2hsaWdodGNvbG9yPXRbJ2FjZW50byddLAogICAgICAgICAgICAgICAgZGlz
:::YWJsZWRiYWNrZ3JvdW5kPXRbJ2NhbXBvJ10sIGRpc2FibGVkZm9yZWdyb3VuZD10
:::Wyd0ZXh0bzInXSkKICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5jb25maWd1
:::cmUoCiAgICAgICAgICAgICAgICBiZz10WydjYW1wbyddLCBmZz10Wyd0ZXh0bydd
:::LCBpbnNlcnRiYWNrZ3JvdW5kPXRbJ3RleHRvJ10sCiAgICAgICAgICAgICAgICBo
:::aWdobGlnaHRiYWNrZ3JvdW5kPXRbJ2NhbXBvX2JvcmRlJ10sCiAgICAgICAgICAg
:::ICAgICBoaWdobGlnaHRjb2xvcj10WydhY2VudG8nXSkKICAgICAgICAgICAgc2Vs
:::Zi5jaGtfZW1iZWJlci5jb25maWd1cmUoCiAgICAgICAgICAgICAgICBiZz10Wydm
:::b25kbyddLCBmZz10Wyd0ZXh0byddLCBhY3RpdmViYWNrZ3JvdW5kPXRbJ2ZvbmRv
:::J10sCiAgICAgICAgICAgICAgICBhY3RpdmVmb3JlZ3JvdW5kPXRbJ3RleHRvJ10s
:::IHNlbGVjdGNvbG9yPXRbJ2NhbXBvJ10pCiAgICAgICAgICAgIGZvciBiIGluIHNl
:::bGYuX2J0bnM6CiAgICAgICAgICAgICAgICBiLmNvbmZpZ3VyZShiZz10Wydib3Rv
:::biddLCBmZz10Wydib3Rvbl90eHQnXSwKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIGFjdGl2ZWJhY2tncm91bmQ9dFsnYm90b25fYWN0J10sCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICBhY3RpdmVmb3JlZ3JvdW5kPXRbJ2JvdG9uX3R4dCdd
:::KQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuY29uZmlndXJlKGJnPXRbJ2xvZydd
:::LCBmZz10Wydsb2dfdHh0J10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgaW5zZXJ0YmFja2dyb3VuZD10Wydsb2dfdHh0J10pCiAgICAgICAgICAg
:::IHNlbGYudHh0X2xvZy50YWdfY29uZmlndXJlKCdpbmZvJywgZm9yZWdyb3VuZD10
:::Wydsb2dfdHh0J10pCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy50YWdfY29uZmln
:::dXJlKCdncmlzJywgZm9yZWdyb3VuZD10Wyd0ZXh0bzInXSkKICAgICAgICAgICAg
:::c2VsZi50eHRfbG9nLnRhZ19jb25maWd1cmUoJ3RpdHVsbycsIGZvcmVncm91bmQ9
:::dFsndGV4dG8nXSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgZm9udD0oJ0NvbnNvbGFzJywgMTAsICdib2xkJykpCiAgICAgICAgICAgIHNl
:::bGYudHh0X2xvZy50YWdfY29uZmlndXJlKCdvaycsIGZvcmVncm91bmQ9dFsnb2sn
:::XSkKICAgICAgICAgICAgc2VsZi50eHRfbG9nLnRhZ19jb25maWd1cmUoJ2F2aXNv
:::JywgZm9yZWdyb3VuZD10WydhdmlzbyddKQogICAgICAgICAgICBzZWxmLnR4dF9s
:::b2cudGFnX2NvbmZpZ3VyZSgnZXJyb3InLCBmb3JlZ3JvdW5kPXRbJ2Vycm9yJ10p
:::CiAgICAgICAgICAgIGVzdCA9IHNlbGYuX2VzdGlsbwogICAgICAgICAgICBlc3Qu
:::Y29uZmlndXJlKCdneC5UQ29tYm9ib3gnLAogICAgICAgICAgICAgICAgICAgICAg
:::ICAgIGZpZWxkYmFja2dyb3VuZD10WydjYW1wbyddLCBiYWNrZ3JvdW5kPXRbJ2Jv
:::dG9uJ10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgZm9yZWdyb3VuZD10Wyd0
:::ZXh0byddLCBhcnJvd2NvbG9yPXRbJ3RleHRvJ10sCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgYm9yZGVyY29sb3I9dFsnY2FtcG9fYm9yZGUnXSwKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICBsaWdodGNvbG9yPXRbJ2NhbXBvX2JvcmRlJ10sCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgZGFya2NvbG9yPXRbJ2NhbXBvX2JvcmRl
:::J10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgaW5zZXJ0Y29sb3I9dFsndGV4
:::dG8nXSkKICAgICAgICAgICAgZXN0Lm1hcCgnZ3guVENvbWJvYm94JywKICAgICAg
:::ICAgICAgICAgICAgICBmaWVsZGJhY2tncm91bmQ9WygncmVhZG9ubHknLCB0Wydj
:::YW1wbyddKV0sCiAgICAgICAgICAgICAgICAgICAgZm9yZWdyb3VuZD1bKCdyZWFk
:::b25seScsIHRbJ3RleHRvJ10pXSkKICAgICAgICAgICAgZXN0LmNvbmZpZ3VyZSgn
:::Z3guSG9yaXpvbnRhbC5UUHJvZ3Jlc3NiYXInLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgIHRyb3VnaGNvbG9yPXRbJ3Ryb3VnaCddLCBiYWNrZ3JvdW5kPXRbJ2Fj
:::ZW50byddLAogICAgICAgICAgICAgICAgICAgICAgICAgIGJvcmRlcmNvbG9yPXRb
:::J2ZvbmRvJ10sIGxpZ2h0Y29sb3I9dFsnYWNlbnRvJ10sCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgZGFya2NvbG9yPXRbJ2FjZW50byddKQogICAgICAgICAgICBz
:::ZWxmLm9wdGlvbl9hZGQoJypUQ29tYm9ib3gqTGlzdGJveC5iYWNrZ3JvdW5kJywg
:::dFsnY2FtcG8nXSkKICAgICAgICAgICAgc2VsZi5vcHRpb25fYWRkKCcqVENvbWJv
:::Ym94Kkxpc3Rib3guZm9yZWdyb3VuZCcsIHRbJ3RleHRvJ10pCiAgICAgICAgICAg
:::IHNlbGYub3B0aW9uX2FkZCgnKlRDb21ib2JveCpMaXN0Ym94LnNlbGVjdEJhY2tn
:::cm91bmQnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgdFsnYm90b25fYWN0
:::J10pCiAgICAgICAgICAgIHNlbGYub3B0aW9uX2FkZCgnKlRDb21ib2JveCpMaXN0
:::Ym94LnNlbGVjdEZvcmVncm91bmQnLAogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgdFsnYm90b25fdHh0J10pCiAgICAgICAgICAgIHNlbGYuX3JlZnJlc2Nhcl9w
:::bGFjZWhvbGRlcigpCgogICAgICAgIGRlZiBfcmVmcmVzY2FyX3BsYWNlaG9sZGVy
:::KHNlbGYpOgogICAgICAgICAgICB0ID0gVEVNQVNbc2VsZi5fdGVtYV9hY3R1YWxd
:::CiAgICAgICAgICAgIGlmIHNlbGYuX2VuX3BsYWNlaG9sZGVyOgogICAgICAgICAg
:::ICAgICAgc2VsZi5lbnRfdXJsLmNvbmZpZ3VyZShmZz10WydwbGFjZWhvbGRlcidd
:::KQogICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgc2VsZi5lbnRfdXJs
:::LmNvbmZpZ3VyZShmZz10Wyd0ZXh0byddKQoKICAgICAgICAjIC0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBldmVudG9zCiAg
:::ICAgICAgZGVmIF9jb25lY3Rhcl9ldmVudG9zKHNlbGYpOgogICAgICAgICAgICBz
:::ZWxmLmNtYl90ZW1hLmJpbmQoJzw8Q29tYm9ib3hTZWxlY3RlZD4+Jywgc2VsZi5f
:::b25fdGVtYSkKICAgICAgICAgICAgc2VsZi5jbWJfZm9ybWF0by5iaW5kKCc8PENv
:::bWJvYm94U2VsZWN0ZWQ+PicsIHNlbGYuX29uX2Zvcm1hdG8pCiAgICAgICAgICAg
:::IHNlbGYuY21iX2NhbGlkYWQuYmluZCgnPDxDb21ib2JveFNlbGVjdGVkPj4nLCBs
:::YW1iZGEgZTogc2VsZi5fZ3VhcmRhcigpKQogICAgICAgICAgICBzZWxmLmNoa19l
:::bWJlYmVyLmNvbmZpZ3VyZShjb21tYW5kPXNlbGYuX2d1YXJkYXIpCiAgICAgICAg
:::ICAgIHNlbGYuZW50X3VybC5iaW5kKCc8Rm9jdXNJbj4nLCBzZWxmLl9vbl9mb2N1
:::c191cmxfaW4pCiAgICAgICAgICAgIHNlbGYuZW50X3VybC5iaW5kKCc8Rm9jdXNP
:::dXQ+Jywgc2VsZi5fb25fZm9jdXNfdXJsX291dCkKICAgICAgICAgICAgc2VsZi5l
:::bnRfdXJsLmJpbmQoJzxSZXR1cm4+JywgbGFtYmRhIGU6IHNlbGYuX2FjY2lvbl9k
:::ZXNjYXJnYXIoKSkKICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5iaW5kKCc8
:::Rm9jdXNPdXQ+Jywgc2VsZi5fb25fY2FycGV0YV9lc2NyaXRhKQogICAgICAgICAg
:::ICBzZWxmLnByb3RvY29sKCdXTV9ERUxFVEVfV0lORE9XJywgc2VsZi5fYWxfY2Vy
:::cmFyKQogICAgICAgICAgICBzZWxmLmJpbmQoJzxDb250cm9sLXU+JywgbGFtYmRh
:::IGU6IHNlbGYuX2FjY2lvbl9hY3R1YWxpemFyKCkpCiAgICAgICAgICAgIHNlbGYu
:::YmluZCgnPENvbnRyb2wtbD4nLCBsYW1iZGEgZTogc2VsZi5fbGltcGlhcl9sb2co
:::KSkKICAgICAgICAgICAgc2VsZi5iaW5kKCc8Q29udHJvbC1VPicsIGxhbWJkYSBl
:::OiBzZWxmLl9hY2Npb25fYWN0dWFsaXphcigpKQoKICAgICAgICBkZWYgX29uX2Zv
:::Y3VzX3VybF9pbihzZWxmLCBfZT1Ob25lKToKICAgICAgICAgICAgaWYgc2VsZi5f
:::ZW5fcGxhY2Vob2xkZXI6CiAgICAgICAgICAgICAgICBzZWxmLmVudF91cmwuZGVs
:::ZXRlKDAsICdlbmQnKQogICAgICAgICAgICAgICAgc2VsZi5fZW5fcGxhY2Vob2xk
:::ZXIgPSBGYWxzZQogICAgICAgICAgICAgICAgc2VsZi5fcmVmcmVzY2FyX3BsYWNl
:::aG9sZGVyKCkKCiAgICAgICAgZGVmIF9vbl9mb2N1c191cmxfb3V0KHNlbGYsIF9l
:::PU5vbmUpOgogICAgICAgICAgICBpZiBub3Qgc2VsZi5lbnRfdXJsLmdldCgpOgog
:::ICAgICAgICAgICAgICAgc2VsZi5fZW5fcGxhY2Vob2xkZXIgPSBUcnVlCiAgICAg
:::ICAgICAgICAgICBzZWxmLl9wb25lcl9wbGFjZWhvbGRlcigpCiAgICAgICAgICAg
:::ICAgICBzZWxmLl9yZWZyZXNjYXJfcGxhY2Vob2xkZXIoKQoKICAgICAgICBkZWYg
:::X29uX3RlbWEoc2VsZiwgX2U9Tm9uZSk6CiAgICAgICAgICAgIHNlbGYuX3RlbWFf
:::YWN0dWFsID0gc2VsZi5jbWJfdGVtYS5nZXQoKQogICAgICAgICAgICBBSlVTVEVT
:::Wyd0ZW1hJ10gPSBzZWxmLl90ZW1hX2FjdHVhbAogICAgICAgICAgICBndWFyZGFy
:::X2FqdXN0ZXMoKQogICAgICAgICAgICBzZWxmLl9hcGxpY2FyX3RlbWEoKQoKICAg
:::ICAgICBkZWYgX29uX2Zvcm1hdG8oc2VsZiwgX2U9Tm9uZSk6CiAgICAgICAgICAg
:::IGZtdCA9IHNlbGYuX2ZtdF9hY3R1YWwoKQogICAgICAgICAgICBzZWxmLl9yZWNh
:::cmdhcl9jYWxpZGFkZXMoZm10KQogICAgICAgICAgICBzZWxmLl9ndWFyZGFyKCkK
:::ICAgICAgICAgICAgc2VsZi5sYmxfZXN0aW1hY2lvbi5jb25maWd1cmUoCiAgICAg
:::ICAgICAgICAgICB0ZXh0PSdJbnRyb2R1Y2UgdW5hIFVSTCB5IHB1bHNhIEVzdGlt
:::YXIuJywKICAgICAgICAgICAgICAgIGZnPVRFTUFTW3NlbGYuX3RlbWFfYWN0dWFs
:::XVsndGV4dG8nXSkKCiAgICAgICAgZGVmIF9mbXRfYWN0dWFsKHNlbGYpOgogICAg
:::ICAgICAgICB0ZXh0byA9IHNlbGYuY21iX2Zvcm1hdG8uZ2V0KCkKICAgICAgICAg
:::ICAgZm9yIGNsYXZlLCBmIGluIEZPUk1BVE9TLml0ZW1zKCk6CiAgICAgICAgICAg
:::ICAgICBpZiBmWyd0ZXh0byddID09IHRleHRvOgogICAgICAgICAgICAgICAgICAg
:::IHJldHVybiBjbGF2ZQogICAgICAgICAgICByZXR1cm4gJ0FBQycKCiAgICAgICAg
:::ZGVmIF9yZWNhcmdhcl9jYWxpZGFkZXMoc2VsZiwgY2xhdmVfZm10LCBjYWxpZGFk
:::X3ByZXZpYT1Ob25lKToKICAgICAgICAgICAgZiA9IEZPUk1BVE9TW2NsYXZlX2Zt
:::dF0KICAgICAgICAgICAgc2VsZi5jbWJfY2FsaWRhZFsndmFsdWVzJ10gPSBmWydj
:::YWxpZGFkZXMnXQogICAgICAgICAgICBpZiBjYWxpZGFkX3ByZXZpYSBhbmQgY2Fs
:::aWRhZF9wcmV2aWEgaW4gZlsnY2FsaWRhZGVzJ106CiAgICAgICAgICAgICAgICBz
:::ZWxmLmNtYl9jYWxpZGFkLnNldChjYWxpZGFkX3ByZXZpYSkKICAgICAgICAgICAg
:::ZWxzZToKICAgICAgICAgICAgICAgIHNlbGYuY21iX2NhbGlkYWQuc2V0KGZbJ2Rl
:::ZmVjdG8nXSkKICAgICAgICAgICAgQUpVU1RFU1snZm9ybWF0byddID0gY2xhdmVf
:::Zm10CiAgICAgICAgICAgIEFKVVNURVNbJ2NhbGlkYWQnXSA9IHNlbGYuY21iX2Nh
:::bGlkYWQuZ2V0KCkKCiAgICAgICAgZGVmIF9ndWFyZGFyKHNlbGYpOgogICAgICAg
:::ICAgICBBSlVTVEVTWydmb3JtYXRvJ10gPSBzZWxmLl9mbXRfYWN0dWFsKCkKICAg
:::ICAgICAgICAgQUpVU1RFU1snY2FsaWRhZCddID0gc2VsZi5jbWJfY2FsaWRhZC5n
:::ZXQoKQogICAgICAgICAgICBBSlVTVEVTWydlbWJlYmVyJ10gPSBib29sKHNlbGYu
:::dmFyX2VtYmViZXIuZ2V0KCkpCiAgICAgICAgICAgIEFKVVNURVNbJ2Rlc3Rpbm8n
:::XSA9IHNlbGYuZW50X2NhcnBldGEuZ2V0KCkuc3RyaXAoKQogICAgICAgICAgICB2
:::YWwgPSBzZWxmLmNtYl9jb29raWVzLmdldCgpCiAgICAgICAgICAgIEFKVVNURVNb
:::J2Nvb2tpZXMnXSA9ICgnJyBpZiB2YWwuc3RhcnRzd2l0aCgnQXV0b23DoXRpY28n
:::KSBlbHNlCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICB2YWwucmVw
:::bGFjZSgnVXNhciBjb29raWVzIGRlICcsICcnKQogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgLnN0cmlwKCkubG93ZXIoKSkKICAgICAgICAgICAgZ3Vh
:::cmRhcl9hanVzdGVzKCkKCiAgICAgICAgZGVmIF9vbl9jYXJwZXRhX2VzY3JpdGEo
:::c2VsZiwgX2U9Tm9uZSk6CiAgICAgICAgICAgIHAgPSBQYXRoKG9zLnBhdGguZXhw
:::YW5kdmFycygKICAgICAgICAgICAgICAgIHNlbGYuZW50X2NhcnBldGEuZ2V0KCku
:::c3RyaXAoKS5zdHJpcCgnIicpKSkKICAgICAgICAgICAgdHJ5OgogICAgICAgICAg
:::ICAgICAgcC5ta2RpcihwYXJlbnRzPVRydWUsIGV4aXN0X29rPVRydWUpCiAgICAg
:::ICAgICAgICAgICBBSlVTVEVTWydkZXN0aW5vJ10gPSBzdHIocCkKICAgICAgICAg
:::ICAgICAgIGd1YXJkYXJfYWp1c3RlcygpCiAgICAgICAgICAgIGV4Y2VwdCBPU0Vy
:::cm9yIGFzIGU6CiAgICAgICAgICAgICAgICBzZWxmLl9sb2coZidObyBzZSBwdWRv
:::IHVzYXIgZXNhIGNhcnBldGE6IHtlfScsICdlcnJvcicpCgogICAgICAgIGRlZiBf
:::Y2FtYmlhcl9jYXJwZXRhKHNlbGYpOgogICAgICAgICAgICBhY3R1YWwgPSBzZWxm
:::LmVudF9jYXJwZXRhLmdldCgpLnN0cmlwKCkgb3IgQUpVU1RFU1snZGVzdGlubydd
:::CiAgICAgICAgICAgIG51ZXZhID0gZmlsZWRpYWxvZy5hc2tkaXJlY3RvcnkoCiAg
:::ICAgICAgICAgICAgICB0aXRsZT0nRWxpZ2UgbGEgY2FycGV0YSBkb25kZSBndWFy
:::ZGFyIGxhcyBkZXNjYXJnYXMnLAogICAgICAgICAgICAgICAgaW5pdGlhbGRpcj1h
:::Y3R1YWwgaWYgb3MucGF0aC5pc2RpcihhY3R1YWwpIGVsc2Ugc3RyKFBhdGguaG9t
:::ZSgpKSkKICAgICAgICAgICAgaWYgbm90IG51ZXZhOgogICAgICAgICAgICAgICAg
:::cmV0dXJuCiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIFBhdGgobnVl
:::dmEpLm1rZGlyKHBhcmVudHM9VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgICAgICAg
:::ICAgZXhjZXB0IE9TRXJyb3IgYXMgZToKICAgICAgICAgICAgICAgIG1lc3NhZ2Vi
:::b3guc2hvd2Vycm9yKCdDYXJwZXRhIG5vIHbDoWxpZGEnLCBzdHIoZSkpCiAgICAg
:::ICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5k
:::ZWxldGUoMCwgJ2VuZCcpCiAgICAgICAgICAgIHNlbGYuZW50X2NhcnBldGEuaW5z
:::ZXJ0KDAsIG51ZXZhKQogICAgICAgICAgICBBSlVTVEVTWydkZXN0aW5vJ10gPSBu
:::dWV2YQogICAgICAgICAgICBndWFyZGFyX2FqdXN0ZXMoKQogICAgICAgICAgICBz
:::ZWxmLl9sb2coJ0NhcnBldGEgZGUgZ3VhcmRhZG86ICcgKyBudWV2YSwgJ2dyaXMn
:::KQoKICAgICAgICBkZWYgX2FicmlyX2Rlc3Rpbm8oc2VsZik6CiAgICAgICAgICAg
:::IHAgPSBQYXRoKG9zLnBhdGguZXhwYW5kdmFycygKICAgICAgICAgICAgICAgIHNl
:::bGYuZW50X2NhcnBldGEuZ2V0KCkuc3RyaXAoKS5zdHJpcCgnIicpKSkKICAgICAg
:::ICAgICAgdHJ5OgogICAgICAgICAgICAgICAgcC5ta2RpcihwYXJlbnRzPVRydWUs
:::IGV4aXN0X29rPVRydWUpCiAgICAgICAgICAgIGV4Y2VwdCBPU0Vycm9yOgogICAg
:::ICAgICAgICAgICAgcGFzcwogICAgICAgICAgICBhYnJpcl9jYXJwZXRhKHApCgog
:::ICAgICAgIGRlZiBfYWxfY2VycmFyKHNlbGYpOgogICAgICAgICAgICBpZiBzZWxm
:::Ll9vY3VwYWRvIGFuZCBub3QgbWVzc2FnZWJveC5hc2tva2NhbmNlbCgKICAgICAg
:::ICAgICAgICAgICAgICAnU2FsaXInLCAnSGF5IHVuYSB0YXJlYSBlbiBjdXJzby4g
:::JwogICAgICAgICAgICAgICAgICAgICfCv1NlZ3VybyBxdWUgcXVpZXJlcyBzYWxp
:::cj8nKToKICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICBzZWxmLmRl
:::c3Ryb3koKQoKICAgICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLSByZWdpc3RybyAobG9nKQogICAgICAgIGRlZiBf
:::bG9nKHNlbGYsIG1zZywgdGFnPSdpbmZvJyk6CiAgICAgICAgICAgIHNlbGYudHh0
:::X2xvZy5jb25maWd1cmUoc3RhdGU9J25vcm1hbCcpCiAgICAgICAgICAgIG5fbGlu
:::ZWFzID0gaW50KHNlbGYudHh0X2xvZy5pbmRleCgnZW5kLTFjJykuc3BsaXQoJy4n
:::KVswXSkKICAgICAgICAgICAgaWYgbl9saW5lYXMgPiA5MDA6CiAgICAgICAgICAg
:::ICAgICBzZWxmLnR4dF9sb2cuZGVsZXRlKCcxLjAnLCAnMjAwLjAnKQogICAgICAg
:::ICAgICBzZWxmLnR4dF9sb2cuaW5zZXJ0KCdlbmQnLCBzdHIobXNnKSArICdcbics
:::IHRhZykKICAgICAgICAgICAgc2VsZi50eHRfbG9nLnNlZSgnZW5kJykKICAgICAg
:::ICAgICAgc2VsZi50eHRfbG9nLmNvbmZpZ3VyZShzdGF0ZT0nZGlzYWJsZWQnKQoK
:::ICAgICAgICBkZWYgX2xpbXBpYXJfbG9nKHNlbGYpOgogICAgICAgICAgICBzZWxm
:::LnR4dF9sb2cuY29uZmlndXJlKHN0YXRlPSdub3JtYWwnKQogICAgICAgICAgICBz
:::ZWxmLnR4dF9sb2cuZGVsZXRlKCcxLjAnLCAnZW5kJykKICAgICAgICAgICAgc2Vs
:::Zi50eHRfbG9nLmNvbmZpZ3VyZShzdGF0ZT0nZGlzYWJsZWQnKQoKICAgICAgICBk
:::ZWYgX2JvbWJlYXJfY29sYShzZWxmKToKICAgICAgICAgICAgdHJ5OgogICAgICAg
:::ICAgICAgICAgd2hpbGUgVHJ1ZToKICAgICAgICAgICAgICAgICAgICBldiA9IHNl
:::bGYuY29sYS5nZXRfbm93YWl0KCkKICAgICAgICAgICAgICAgICAgICB0aXBvID0g
:::ZXZbMF0KICAgICAgICAgICAgICAgICAgICBpZiB0aXBvID09ICdsb2cnOgogICAg
:::ICAgICAgICAgICAgICAgICAgICBzZWxmLl9sb2coZXZbMV0sIGV2WzJdKQogICAg
:::ICAgICAgICAgICAgICAgIGVsaWYgdGlwbyA9PSAncHJvZyc6CiAgICAgICAgICAg
:::ICAgICAgICAgICAgIHBjdCwgdGV4dG8gPSBldlsxXSwgZXZbMl0KICAgICAgICAg
:::ICAgICAgICAgICAgICAgaWYgcGN0IGlzIE5vbmU6CiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICBzZWxmLmJhcnJhLnN0b3AoKQogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgc2VsZi5iYXJyYS5jb25maWd1cmUobW9kZT0naW5kZXRlcm1pbmF0
:::ZScpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzZWxmLmJhcnJhLnN0YXJ0
:::KDYwKQogICAgICAgICAgICAgICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgc2VsZi5iYXJyYS5zdG9wKCkKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIHNlbGYuYmFycmEuY29uZmlndXJlKG1vZGU9J2RldGVybWlu
:::YXRlJykKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYmFycmEuY29u
:::ZmlndXJlKHZhbHVlPW1heCgwLCBtaW4oMTAwLCBwY3QpKSkKICAgICAgICAgICAg
:::ICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmNvbmZpZ3VyZSh0ZXh0PXRleHRv
:::KQogICAgICAgICAgICAgICAgICAgIGVsaWYgdGlwbyA9PSAnZXN0aW1hY2lvbic6
:::CiAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYubGJsX2VzdGltYWNpb24uY29u
:::ZmlndXJlKAogICAgICAgICAgICAgICAgICAgICAgICAgICAgdGV4dD1ldlsxXSwg
:::Zmc9VEVNQVNbc2VsZi5fdGVtYV9hY3R1YWxdWydhY2VudG8nXSkKICAgICAgICAg
:::ICAgICAgICAgICBlbGlmIHRpcG8gPT0gJ3ByZWd1bnRhcic6CiAgICAgICAgICAg
:::ICAgICAgICAgICAgICMgdjIuMTQ6IGVsIGhpbG8gZGUgZGVzY2FyZ2EgcGlkZSB1
:::bmEgZGVjaXNpb24gYWwKICAgICAgICAgICAgICAgICAgICAgICAgIyB1c3Vhcmlv
:::IChyZWludGVudGFyIGNvbiBjYWxpZGFkIG1hcyBiYWphKS4gTGEKICAgICAgICAg
:::ICAgICAgICAgICAgICAgIyByZXNwdWVzdGEgdmlhamEgcG9yIGxhIGNvbGEgcXVl
:::IHRyYWUgZWwgZXZlbnRvLgogICAgICAgICAgICAgICAgICAgICAgICBfLCB0aXR1
:::bG8sIHRleHRvLCByZXNwID0gZXYKICAgICAgICAgICAgICAgICAgICAgICAgdHJ5
:::OgogICAgICAgICAgICAgICAgICAgICAgICAgICAgciA9IG1lc3NhZ2Vib3guYXNr
:::eWVzbm8odGl0dWxvLCB0ZXh0bykKICAgICAgICAgICAgICAgICAgICAgICAgZXhj
:::ZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHIgPSBG
:::YWxzZQogICAgICAgICAgICAgICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICByZXNwLnB1dF9ub3dhaXQoYm9vbChyKSkKICAgICAgICAg
:::ICAgICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIHBhc3MKICAgICAgICAgICAgICAgICAgICBlbGlmIHRpcG8g
:::PT0gJ2Zpbic6CiAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuX2Zpbl90YXJl
:::YShldlsxXSwgZXZbMl0sIGV2WzNdIGlmIGxlbihldikgPiAzIGVsc2UgJycpCiAg
:::ICAgICAgICAgIGV4Y2VwdCBxdWV1ZS5FbXB0eToKICAgICAgICAgICAgICAgIHBh
:::c3MKICAgICAgICAgICAgc2VsZi5hZnRlcig4MCwgc2VsZi5fYm9tYmVhcl9jb2xh
:::KQoKICAgICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLSB0YXJlYXMKICAgICAgICBkZWYgX2hhYmlsaXRhcl9hY2Np
:::b25lcyhzZWxmLCBvbik6CiAgICAgICAgICAgIGVzdGFkbyA9ICdub3JtYWwnIGlm
:::IG9uIGVsc2UgJ2Rpc2FibGVkJwogICAgICAgICAgICBmb3IgYiBpbiAoc2VsZi5i
:::dG5fZGVzY2FyZ2FyLCBzZWxmLmJ0bl9jb21wcm9iYXIsCiAgICAgICAgICAgICAg
:::ICAgICAgICBzZWxmLmJ0bl9lc3RpbWFyLCBzZWxmLmJ0bl9jYW1iaWFyLCBzZWxm
:::LmJ0bl9hYnJpciwKICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYnRuX3BlZ2Fy
:::LCBzZWxmLmJ0bl94KToKICAgICAgICAgICAgICAgIGIuY29uZmlndXJlKHN0YXRl
:::PWVzdGFkbywgY3Vyc29yPSdoYW5kMicgaWYgb24gZWxzZSAnYXJyb3cnKQoKICAg
:::ICAgICBkZWYgX2luaWNpYXIoc2VsZiwgb2JqZXRpdm8sIGNmZywgdGV4dG8pOgog
:::ICAgICAgICAgICBpZiBzZWxmLl9vY3VwYWRvOgogICAgICAgICAgICAgICAgc2Vs
:::Zi5fbG9nKCdZYSBoYXkgdW5hIHRhcmVhIGVuIGN1cnNvOyBlc3BlcmEgYSBxdWUg
:::dGVybWluZS4nLAogICAgICAgICAgICAgICAgICAgICAgICAgICdhdmlzbycpCiAg
:::ICAgICAgICAgICAgICByZXR1cm4gRmFsc2UKICAgICAgICAgICAgc2VsZi5fb2N1
:::cGFkbyA9IFRydWUKICAgICAgICAgICAgc2VsZi5faGFiaWxpdGFyX2FjY2lvbmVz
:::KEZhbHNlKQogICAgICAgICAgICBzZWxmLmxibF9lc3RhZG8uY29uZmlndXJlKHRl
:::eHQ9dGV4dG8pCiAgICAgICAgICAgIHRocmVhZGluZy5UaHJlYWQodGFyZ2V0PW9i
:::amV0aXZvLCBhcmdzPShjZmcsKSwgZGFlbW9uPVRydWUpLnN0YXJ0KCkKICAgICAg
:::ICAgICAgcmV0dXJuIFRydWUKCiAgICAgICAgZGVmIF9maW5fdGFyZWEoc2VsZiwg
:::dGlwbywgb2ssIG1lbnNhamU9JycpOgogICAgICAgICAgICBzZWxmLl9vY3VwYWRv
:::ID0gRmFsc2UKICAgICAgICAgICAgc2VsZi5faGFiaWxpdGFyX2FjY2lvbmVzKFRy
:::dWUpCiAgICAgICAgICAgIHNlbGYuYmFycmEuc3RvcCgpCiAgICAgICAgICAgIHNl
:::bGYuYmFycmEuY29uZmlndXJlKG1vZGU9J2RldGVybWluYXRlJykKICAgICAgICAg
:::ICAgc2VsZi5iYXJyYS5jb25maWd1cmUodmFsdWU9MCkKICAgICAgICAgICAgaWYg
:::dGlwbyA9PSAnZGVzY2FyZ2EnIGFuZCBvazoKICAgICAgICAgICAgICAgIHNlbGYu
:::bGJsX2VzdGFkby5jb25maWd1cmUodGV4dD0nTGlzdG8uJykKICAgICAgICAgICAg
:::ICAgICMgTGEgZGVzY2FyZ2EgZnVlIGJpZW46IHNlIGxpbXBpYSBsYSBVUkwgcGFy
:::YSBsYSBzaWd1aWVudGUuCiAgICAgICAgICAgICAgICBzZWxmLl9yZXNldF91cmwo
:::KQogICAgICAgICAgICBlbGlmIG5vdCBvazoKICAgICAgICAgICAgICAgIHNlbGYu
:::bGJsX2VzdGFkby5jb25maWd1cmUodGV4dD0nVGVybWluYWRvIGNvbiBlcnJvcmVz
:::LicpCiAgICAgICAgICAgICAgICBpZiB0aXBvID09ICdkZXNjYXJnYSc6CiAgICAg
:::ICAgICAgICAgICAgICAgbWVzc2FnZWJveC5zaG93ZXJyb3IoCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICdFcnJvcicsIG1lbnNhamUgb3IgJ05vIHNlIHB1ZG8gY29t
:::cGxldGFyIGxhIHRhcmVhLiAnCiAgICAgICAgICAgICAgICAgICAgICAgICdSZXZp
:::c2EgZWwgcmVnaXN0cm8gcGFyYSBtw6FzIGRldGFsbGVzLicpCgogICAgICAgIGRl
:::ZiBfdXJsX3ZhbGlkYShzZWxmKToKICAgICAgICAgICAgaWYgc2VsZi5fZW5fcGxh
:::Y2Vob2xkZXI6CiAgICAgICAgICAgICAgICBzZWxmLl9sb2coJ1ByaW1lcm8gcGVn
:::YSBsYSBVUkwgZGVsIHZpZGVvIGRlIFlvdVR1YmUuJywgJ2F2aXNvJykKICAgICAg
:::ICAgICAgICAgIHJldHVybiBOb25lCiAgICAgICAgICAgIHUgPSBzZWxmLmVudF91
:::cmwuZ2V0KCkuc3RyaXAoKS5zdHJpcCgnIicpLnN0cmlwKCInIikKICAgICAgICAg
:::ICAgaWYgbm90IHU6CiAgICAgICAgICAgICAgICBzZWxmLl9sb2coJ0xhIFVSTCBl
:::c3TDoSB2YWPDrWEuJywgJ2F2aXNvJykKICAgICAgICAgICAgICAgIHJldHVybiBO
:::b25lCiAgICAgICAgICAgIGlmIG5vdCByZS5tYXRjaChyJ15odHRwcz86Ly8nLCB1
:::LCByZS5JKToKICAgICAgICAgICAgICAgIGlmIHJlLm1hdGNoKHInXnd3d1wuJywg
:::dSwgcmUuSSk6CiAgICAgICAgICAgICAgICAgICAgdSA9ICdodHRwczovLycgKyB1
:::CiAgICAgICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgIHNlbGYu
:::X2xvZygnRXNvIG5vIHBhcmVjZSB1bmEgVVJMIChkZWJlIGVtcGV6YXIgcG9yICcK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2h0dHA6Ly8gbyBodHRwczov
:::LyknLCAnZXJyb3InKQogICAgICAgICAgICAgICAgICAgIHJldHVybiBOb25lCiAg
:::ICAgICAgICAgICMgT0pPOiBhcXXDrSBOTyBzZSBxdWl0YSBsaXN0PTsgc2kgbGEg
:::VVJMIHRyYWUgdW5hIHBsYXlsaXN0LAogICAgICAgICAgICAjIF9hY2Npb25fZGVz
:::Y2FyZ2FyIHByZWd1bnRhcsOhIHF1w6kgaGFjZXIgY29uIGVsbGEuCiAgICAgICAg
:::ICAgIHJldHVybiB1CgogICAgICAgIGRlZiBfYWNjaW9uX2VzdGltYXIoc2VsZik6
:::CiAgICAgICAgICAgIHVybCA9IHNlbGYuX3VybF92YWxpZGEoKQogICAgICAgICAg
:::ICBpZiBub3QgdXJsOgogICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAg
:::IHNlbGYuX2d1YXJkYXIoKQogICAgICAgICAgICBjZmcgPSB7J3VybCc6IHVybH0K
:::ICAgICAgICAgICAgc2VsZi5faW5pY2lhcihzZWxmLl9oaWxvX2VzdGltYXIsIGNm
:::ZywgJ0VzdGltYW5kbyB0YW1hw7FvLi4uJykKICAgICAgICAgICAgc2VsZi5sYmxf
:::ZXN0aW1hY2lvbi5jb25maWd1cmUoCiAgICAgICAgICAgICAgICB0ZXh0PSdDYWxj
:::dWxhbmRvLi4uJywgZmc9VEVNQVNbc2VsZi5fdGVtYV9hY3R1YWxdWyd0ZXh0bzIn
:::XSkKCiAgICAgICAgZGVmIF9hY2Npb25fZGVzY2FyZ2FyKHNlbGYpOgogICAgICAg
:::ICAgICB1cmwgPSBzZWxmLl91cmxfdmFsaWRhKCkKICAgICAgICAgICAgaWYgbm90
:::IHVybDoKICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICBzZWxmLl9n
:::dWFyZGFyKCkKICAgICAgICAgICAgcGxheWxpc3QgPSBGYWxzZQogICAgICAgICAg
:::ICBpZiBlc191cmxfcGxheWxpc3QodXJsKToKICAgICAgICAgICAgICAgIHIgPSBt
:::ZXNzYWdlYm94LmFza3llc25vY2FuY2VsKAogICAgICAgICAgICAgICAgICAgICdN
:::dXNpa0FMQU4g4oCUIGxpc3RhIGRlIHJlcHJvZHVjY2nDs24nLAogICAgICAgICAg
:::ICAgICAgICAgICdFc3RhIFVSTCBwZXJ0ZW5lY2UgYSB1bmEgbGlzdGEgZGUgcmVw
:::cm9kdWNjacOzbi5cblxuJwogICAgICAgICAgICAgICAgICAgICcgIFPDjSAg4oaS
:::ICBkZXNjYXJnYXIgbGEgcGxheWxpc3QgY29tcGxldGFcbicKICAgICAgICAgICAg
:::ICAgICAgICAnICAgICAgICAgKHBhdXNhIGRlIDIgcyBlbnRyZSBjYW5jaW9uZXMp
:::XG4nCiAgICAgICAgICAgICAgICAgICAgJyAgTk8gIOKGkiAgZGVzY2FyZ2FyIHNv
:::bG8gZXN0YSBjYW5jacOzblxuJwogICAgICAgICAgICAgICAgICAgICcgIENhbmNl
:::bGFyICDihpIgIG5vIGRlc2NhcmdhciBuYWRhJykKICAgICAgICAgICAgICAgIGlm
:::IHIgaXMgTm9uZToKICAgICAgICAgICAgICAgICAgICBzZWxmLl9sb2coJ0Rlc2Nh
:::cmdhIGNhbmNlbGFkYS4nLCAnZ3JpcycpCiAgICAgICAgICAgICAgICAgICAgcmV0
:::dXJuCiAgICAgICAgICAgICAgICBpZiByOgogICAgICAgICAgICAgICAgICAgIHBs
:::YXlsaXN0ID0gVHJ1ZQogICAgICAgICAgICAgICAgZWxpZiBlc19zb2xvX2xpc3Rh
:::KHVybCk6CiAgICAgICAgICAgICAgICAgICAgIyBFcyB1bmEgcGxheWxpc3QgcHVy
:::YTogbm8gaGF5ICJ1bmEgY2FuY2nDs24iIGFow60KICAgICAgICAgICAgICAgICAg
:::ICBzZWxmLl9sb2coJ0VzYSBVUkwgZXMgdW5hIGxpc3RhIGNvbXBsZXRhOyBzZSBk
:::ZXNjYXJnYXLDoSAnCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICdlbnRl
:::cmEuJywgJ2F2aXNvJykKICAgICAgICAgICAgICAgICAgICBwbGF5bGlzdCA9IFRy
:::dWUKICAgICAgICAgICAgY2ZnID0geyd1cmwnOiB1cmwsICdwbGF5bGlzdCc6IHBs
:::YXlsaXN0fQogICAgICAgICAgICBzZWxmLl9pbmljaWFyKHNlbGYuX2hpbG9fZGVz
:::Y2FyZ2FyLCBjZmcsICdEZXNjYXJnYW5kby4uLicpCgogICAgICAgIGRlZiBfYWNj
:::aW9uX2NvbXByb2JhcihzZWxmKToKICAgICAgICAgICAgc2VsZi5fZ3VhcmRhcigp
:::CiAgICAgICAgICAgIHNlbGYuX2luaWNpYXIoc2VsZi5faGlsb19jb21wcm9iYXIs
:::IHt9LAogICAgICAgICAgICAgICAgICAgICAgICAgICdDb21wcm9iYW5kbyBsYSBj
:::YXJwZXRhLi4uJykKCiAgICAgICAgZGVmIF9hY2Npb25fYWN0dWFsaXphcihzZWxm
:::KToKICAgICAgICAgICAgaWYgbm90IFlUX0RMUDoKICAgICAgICAgICAgICAgIHNl
:::bGYuX2xvZygneXQtZGxwIG5vIGVzdMOhIGluc3RhbGFkbzsgZWplY3V0YSAnCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgJ0Rlc2NhcmdhZG9yTXVzaWNhLmJhdC4n
:::LCAnZXJyb3InKQogICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgIHNl
:::bGYuX2luaWNpYXIoc2VsZi5faGlsb19hY3R1YWxpemFyLCB7fSwgJ0FjdHVhbGl6
:::YW5kbyB5dC1kbHAuLi4nKQoKICAgICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBoaWxvcwogICAgICAgIGRlZiBf
:::aGlsb19lc3RpbWFyKHNlbGYsIGNmZyk6CiAgICAgICAgICAgIGNvbGEgPSBzZWxm
:::LmNvbGEKCiAgICAgICAgICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgogICAgICAg
:::ICAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICAgICAgICAgIHRy
:::eToKICAgICAgICAgICAgICAgIGlmIFlUX0RMUCBpcyBOb25lOgogICAgICAgICAg
:::ICAgICAgICAgIGxvZygneXQtZGxwIG5vIGVzdMOhIGluc3RhbGFkby4gRWplY3V0
:::YSAnCiAgICAgICAgICAgICAgICAgICAgICAgICdEZXNjYXJnYWRvck11c2ljYS5i
:::YXQgcGFyYSBpbnN0YWxhcmxvLicsICdlcnJvcicpCiAgICAgICAgICAgICAgICAg
:::ICAgY29sYS5wdXQoKCdlc3RpbWFjaW9uJywgJ3l0LWRscCBubyBkaXNwb25pYmxl
:::JykpCiAgICAgICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgICAgICBs
:::b2coJ09idGVuaWVuZG8gaW5mb3JtYWNpw7NuIGRlbCB2aWRlby4uLicsICdncmlz
:::JykKICAgICAgICAgICAgICAgIG8gPSB7J3F1aWV0JzogVHJ1ZSwgJ25vX3dhcm5p
:::bmdzJzogVHJ1ZSwgJ25vcGxheWxpc3QnOiBUcnVlLAogICAgICAgICAgICAgICAg
:::ICAgICAnc29ja2V0X3RpbWVvdXQnOiAzMCwgJ2xvZ2dlcic6IFJFR0lTVFJPfQog
:::ICAgICAgICAgICAgICAgX2FudGlfYm90KG8pCiAgICAgICAgICAgICAgICBpZiBl
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
:::Z2VyJzogUkVHSVNUUk99CiAgICAgICAgICAgIF9hbnRpX2JvdChvKQogICAgICAg
:::ICAgICB3aXRoIFlUX0RMUC5Zb3V0dWJlREwobykgYXMgeWRsOgogICAgICAgICAg
:::ICAgICAgaW5mbyA9IHlkbC5leHRyYWN0X2luZm8odXJsLCBkb3dubG9hZD1GYWxz
:::ZSkKICAgICAgICAgICAgZW50cmFkYXMgPSBsaXN0KGluZm8uZ2V0KCdlbnRyaWVz
:::Jykgb3IgW10pCiAgICAgICAgICAgIGlmIG5vdCBlbnRyYWRhczoKICAgICAgICAg
:::ICAgICAgIGxvZygnTm8gc2UgdmlvIG5pbmd1bmEgY2FuY2nDs24gZW4gbGEgbGlz
:::dGE7IHNlIGludGVudGEgJwogICAgICAgICAgICAgICAgICAgICdjb21vIHZpZGVv
:::IHN1ZWx0by4nLCAnYXZpc28nKQogICAgICAgICAgICAgICAgYXJjaGl2byA9IHNl
:::bGYuX2Rlc2Nhcmdhcl91bmEoc2luX3BsYXlsaXN0KHVybClbMF0sIGNsYXZlLAog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY2Fs
:::aWRhZF9hcmcsIGVtYmViZXIsIGRlc3Rpbm8sCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xhKQogICAgICAgICAgICAgICAg
:::cmV0dXJuICgxIGlmIGFyY2hpdm8gZWxzZSAwKSwgMQogICAgICAgICAgICB0aXR1
:::bG9fcGwgPSBzdHIoaW5mby5nZXQoJ3RpdGxlJykgb3IgJ2xpc3RhJylbOjcwXQog
:::ICAgICAgICAgICB0b3RhbCA9IGxlbihlbnRyYWRhcykKICAgICAgICAgICAgbG9n
:::KGYnUGxheWxpc3Qgwqt7dGl0dWxvX3BsfcK7IOKAlCB7dG90YWx9IHbDrWRlbyhz
:::KS4nLCAndGl0dWxvJykKICAgICAgICAgICAgb2thcyA9IDAKICAgICAgICAgICAg
:::ZmFsbG9zID0gW10KICAgICAgICAgICAgZm9yIGksIGUgaW4gZW51bWVyYXRlKGVu
:::dHJhZGFzKToKICAgICAgICAgICAgICAgIHUgPSBzdHIoZS5nZXQoJ3dlYnBhZ2Vf
:::dXJsJykgb3IgZS5nZXQoJ3VybCcpIG9yICcnKQogICAgICAgICAgICAgICAgaWYg
:::dSBhbmQgbm90IHUuc3RhcnRzd2l0aCgnaHR0cCcpOgogICAgICAgICAgICAgICAg
:::ICAgIHUgPSAnaHR0cHM6Ly93d3cueW91dHViZS5jb20vd2F0Y2g/dj0nICsgdQog
:::ICAgICAgICAgICAgICAgaWYgbm90IHUgYW5kIGUuZ2V0KCdpZCcpOgogICAgICAg
:::ICAgICAgICAgICAgIHUgPSAnaHR0cHM6Ly93d3cueW91dHViZS5jb20vd2F0Y2g/
:::dj0nICsgc3RyKGVbJ2lkJ10pCiAgICAgICAgICAgICAgICB0aXQgPSBzdHIoZS5n
:::ZXQoJ3RpdGxlJykgb3IgdSBvciAnPycpWzo3MF0KICAgICAgICAgICAgICAgIGlm
:::IGk6CiAgICAgICAgICAgICAgICAgICAgdGltZS5zbGVlcCgyKSAgICMgZGVzY2Fu
:::c28gZW50cmUgY2FuY2lvbmVzCiAgICAgICAgICAgICAgICBsb2coZidbe2kgKyAx
:::fS97dG90YWx9XSDimaoge3RpdH0nLCAndGl0dWxvJykKICAgICAgICAgICAgICAg
:::IHRyeToKICAgICAgICAgICAgICAgICAgICBhcmNoaXZvID0gc2VsZi5fZGVzY2Fy
:::Z2FyX3VuYSh1LCBjbGF2ZSwgY2FsaWRhZF9hcmcsCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZW1iZWJlciwgZGVzdGlu
:::bywgY29sYSkKICAgICAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZTI6
:::CiAgICAgICAgICAgICAgICAgICAgaWYgX2VzX2Jsb3F1ZW9fYm90KHN0cihlMikp
:::OgogICAgICAgICAgICAgICAgICAgICAgICAjIGJsb3F1ZW8gYW50aS1ib3Q6IGFi
:::b3J0YXIgcGFyYSBxdWUgZWwgcmVpbnRlbnRvCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICMgYXV0b23DoXRpY28gZGUgX2hpbG9fZGVzY2FyZ2FyIHNlIGVuY2FyZ3Vl
:::CiAgICAgICAgICAgICAgICAgICAgICAgIHJhaXNlCiAgICAgICAgICAgICAgICAg
:::ICAgYXJjaGl2byA9IE5vbmUKICAgICAgICAgICAgICAgICAgICBsb2coZifinJYg
:::W3tpICsgMX0ve3RvdGFsfV0gRmFsbMOzOiB7c2VsZi5fbXNnX2Vycm9yKGUyKX0n
:::LAogICAgICAgICAgICAgICAgICAgICAgICAnZXJyb3InKQogICAgICAgICAgICAg
:::ICAgaWYgYXJjaGl2byBhbmQgUGF0aChhcmNoaXZvKS5leGlzdHMoKToKICAgICAg
:::ICAgICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICAgICAgICAgIHRhbSA9
:::IGZtdF90YW0oUGF0aChhcmNoaXZvKS5zdGF0KCkuc3Rfc2l6ZSkKICAgICAgICAg
:::ICAgICAgICAgICBleGNlcHQgT1NFcnJvcjoKICAgICAgICAgICAgICAgICAgICAg
:::ICAgdGFtID0gJz8nCiAgICAgICAgICAgICAgICAgICAgbG9nKGYnICAg4pyUIHtQ
:::YXRoKGFyY2hpdm8pLm5hbWV9ICAoe3RhbX0pJwogICAgICAgICAgICAgICAgICAg
:::ICAgICBmJ3t0ZXh0b19jYWxpZGFkKGNsYXZlLCBjYWxpZGFkX2FyZyl9JywgJ29r
:::JykKICAgICAgICAgICAgICAgICAgICBva2FzICs9IDEKICAgICAgICAgICAgICAg
:::IGVsc2U6CiAgICAgICAgICAgICAgICAgICAgZmFsbG9zLmFwcGVuZCh0aXQpCiAg
:::ICAgICAgICAgIGxvZyhmJ1BsYXlsaXN0IHRlcm1pbmFkYToge29rYXN9IGRlIHt0
:::b3RhbH0gZGVzY2FyZ2FkYShzKS4nLAogICAgICAgICAgICAgICAgJ29rJyBpZiBu
:::b3QgZmFsbG9zIGVsc2UgJ2F2aXNvJykKICAgICAgICAgICAgaWYgZmFsbG9zOgog
:::ICAgICAgICAgICAgICAgbG9nKCdTaW4gZGVzY2FyZ2FyOiAnCiAgICAgICAgICAg
:::ICAgICAgICAgKyAnIMK3ICcuam9pbihmWzo0MF0gZm9yIGYgaW4gZmFsbG9zWzo4
:::XSkKICAgICAgICAgICAgICAgICAgICArICgnLi4uJyBpZiBsZW4oZmFsbG9zKSA+
:::IDggZWxzZSAnJyksICdncmlzJykKICAgICAgICAgICAgcmV0dXJuIG9rYXMsIHRv
:::dGFsCgogICAgICAgIGRlZiBfaGlsb19kZXNjYXJnYXIoc2VsZiwgY2ZnKToKICAg
:::ICAgICAgICAgY29sYSA9IHNlbGYuY29sYQoKICAgICAgICAgICAgZGVmIGxvZyht
:::LCB0PSdpbmZvJyk6CiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0s
:::IHQpKQoKICAgICAgICAgICAgdXJsID0gY2ZnWyd1cmwnXQogICAgICAgICAgICBj
:::bGF2ZSA9IHNlbGYuX2ZtdF9hY3R1YWxfc29sbyhBSlVTVEVTLmdldCgnZm9ybWF0
:::bycsICdBQUMnKSkKICAgICAgICAgICAgY2FsaWRhZCA9IEFKVVNURVMuZ2V0KCdj
:::YWxpZGFkJywgJzEyOGsnKQogICAgICAgICAgICBlbWJlYmVyID0gYm9vbChBSlVT
:::VEVTLmdldCgnZW1iZWJlcicsIFRydWUpKQogICAgICAgICAgICBkZXN0aW5vID0g
:::UGF0aChvcy5wYXRoLmV4cGFuZHZhcnMoCiAgICAgICAgICAgICAgICBzdHIoQUpV
:::U1RFUy5nZXQoJ2Rlc3Rpbm8nLCBfZGVzdGlub19wb3JfZGVmZWN0bygpKSkpKQog
:::ICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBpZiBZVF9ETFAgaXMgTm9u
:::ZToKICAgICAgICAgICAgICAgICAgICBsb2coJ3l0LWRscCBubyBlc3TDoSBpbnN0
:::YWxhZG8uIEVqZWN1dGEgJwogICAgICAgICAgICAgICAgICAgICAgICAnRGVzY2Fy
:::Z2Fkb3JNdXNpY2EuYmF0IHBhcmEgaW5zdGFsYXJsby4nLCAnZXJyb3InKQogICAg
:::ICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2Rlc2NhcmdhJywgRmFs
:::c2UsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICd5dC1kbHAgbm8gZXN0
:::w6EgaW5zdGFsYWRvLicpKQogICAgICAgICAgICAgICAgICAgIHJldHVybgogICAg
:::ICAgICAgICAgICAgZGVzdGluby5ta2RpcihwYXJlbnRzPVRydWUsIGV4aXN0X29r
:::PVRydWUpCiAgICAgICAgICAgICAgICBpZiBjbGF2ZSBpbiAoJ0ZMQUMnLCAnV0FW
:::Jyk6CiAgICAgICAgICAgICAgICAgICAgY2FsaWRhZF9hcmcgPSAnMCcKICAgICAg
:::ICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICAgICAgY2FsaWRhZF9hcmcg
:::PSAocmUuc3ViKHInW14wLTldJywgJycsIHN0cihjYWxpZGFkKSkKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBvciAoJzEyOCcgaWYgY2xhdmUgPT0g
:::J0FBQycgZWxzZSAnMzIwJykpCiAgICAgICAgICAgICAgICBpZiBjZmcuZ2V0KCdw
:::bGF5bGlzdCcpOgogICAgICAgICAgICAgICAgICAgIG9rYXMsIHRvdGFsID0gc2Vs
:::Zi5fZGVzY2FyZ2FyX3BsYXlsaXN0KAogICAgICAgICAgICAgICAgICAgICAgICB1
:::cmwsIGNsYXZlLCBjYWxpZGFkX2FyZywgZW1iZWJlciwgZGVzdGlubywgY29sYSkK
:::ICAgICAgICAgICAgICAgICAgICBpZiBva2FzIGFuZCBva2FzID09IHRvdGFsOgog
:::ICAgICAgICAgICAgICAgICAgICAgICBsb2coZidDYXJwZXRhOiB7ZGVzdGlub30n
:::LCAnZ3JpcycpCiAgICAgICAgICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmlu
:::JywgJ2Rlc2NhcmdhJywgVHJ1ZSwgJycpKQogICAgICAgICAgICAgICAgICAgIGVs
:::c2U6CiAgICAgICAgICAgICAgICAgICAgICAgIGNvbGEucHV0KCgKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICdmaW4nLCAnZGVzY2FyZ2EnLCBGYWxzZSwKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgIGYnU2UgZGVzY2FyZ2Fyb24ge29rYXN9
:::IGRlIHt0b3RhbH0gZGUgbGEgJwogICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::J3BsYXlsaXN0LiBMYSBVUkwgbm8gc2UgaGEgYm9ycmFkbyBwb3Igc2kgJwogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgJ3F1aWVyZXMgcmVpbnRlbnRhcmxvLicp
:::KQogICAgICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICAgICAgdXJs
:::X3VuaWNhID0gc2luX3BsYXlsaXN0KHVybClbMF0KICAgICAgICAgICAgICAgIGFy
:::Y2hpdm8gPSBzZWxmLl9kZXNjYXJnYXJfdW5hKHVybF91bmljYSwgY2xhdmUsCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjYWxp
:::ZGFkX2FyZywgZW1iZWJlciwgZGVzdGlubywKICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgIGNvbGEpCiAgICAgICAgICAgICAgICBp
:::ZiBhcmNoaXZvIGFuZCBQYXRoKGFyY2hpdm8pLmV4aXN0cygpOgogICAgICAgICAg
:::ICAgICAgICAgIGFyY2hpdm8gPSBQYXRoKGFyY2hpdm8pCiAgICAgICAgICAgICAg
:::ICAgICAgdHJ5OgogICAgICAgICAgICAgICAgICAgICAgICB0YW0gPSBmbXRfdGFt
:::KGFyY2hpdm8uc3RhdCgpLnN0X3NpemUpCiAgICAgICAgICAgICAgICAgICAgZXhj
:::ZXB0IE9TRXJyb3I6CiAgICAgICAgICAgICAgICAgICAgICAgIHRhbSA9ICc/Jwog
:::ICAgICAgICAgICAgICAgICAgIGxvZyhmJ+KclCDCoUxpc3RvISAge2FyY2hpdm8u
:::bmFtZX0gICh7dGFtfSknCiAgICAgICAgICAgICAgICAgICAgICAgIGYne3RleHRv
:::X2NhbGlkYWQoY2xhdmUsIGNhbGlkYWRfYXJnKX0nLCAnb2snKQogICAgICAgICAg
:::ICAgICAgICAgICMgdjIuMTQ6IHNpIHF1ZWRvIGNvbiBjYWxpZGFkIG1hcyBiYWph
:::IHF1ZSBsYSBwZWRpZGEsCiAgICAgICAgICAgICAgICAgICAgIyBwcmVndW50YXIg
:::c2kgc2UgcmVpbnRlbnRhIHBvciBvdHJhcyB2aWFzIChxdWVkYXJhCiAgICAgICAg
:::ICAgICAgICAgICAgIyBjb24gbGEgbWVqb3IgZGUgbGFzIGRvcykgbyBzZSBjb25z
:::ZXJ2YSBlc3RhLgogICAgICAgICAgICAgICAgICAgIGFyY2hpdm8gPSByZWludGVu
:::dG9fY2FsaWRhZCgKICAgICAgICAgICAgICAgICAgICAgICAgc2VsZiwgdXJsX3Vu
:::aWNhLCBjbGF2ZSwgY2FsaWRhZF9hcmcsIGVtYmViZXIsCiAgICAgICAgICAgICAg
:::ICAgICAgICAgIGRlc3Rpbm8sIGFyY2hpdm8sIGNvbGEpCiAgICAgICAgICAgICAg
:::ICAgICAgbG9nKGYnQ2FycGV0YToge2FyY2hpdm8ucGFyZW50fScsICdncmlzJykK
:::ICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdkZXNjYXJnYScs
:::IFRydWUsICcnKSkKICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAg
:::ICAgICAgbG9nKCdFbCBhcmNoaXZvIGZpbmFsIG5vIGFwYXJlY2nDsyBkb25kZSBz
:::ZSBlc3BlcmFiYS4nLAogICAgICAgICAgICAgICAgICAgICAgICAnZXJyb3InKQog
:::ICAgICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2Rlc2NhcmdhJywg
:::RmFsc2UsICcnKSkKICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBlOgog
:::ICAgICAgICAgICAgICAgbm9tYnJlX2V4YyA9IHR5cGUoZSkuX19uYW1lX18KICAg
:::ICAgICAgICAgICAgIGlmIG5vbWJyZV9leGMgPT0gJ0Rvd25sb2FkRXJyb3InOgog
:::ICAgICAgICAgICAgICAgICAgIGxpbmVhcyA9IFtsIGZvciBsIGluIHN0cihlKS5z
:::dHJpcCgpLnNwbGl0bGluZXMoKSBpZiBsLnN0cmlwKCldCiAgICAgICAgICAgICAg
:::ICAgICAgbXNnID0gbGluZWFzWzBdWzozMDBdIGlmIGxpbmVhcyBlbHNlICdlcnJv
:::ciBkZXNjb25vY2lkbycKICAgICAgICAgICAgICAgICAgICBpZiBfZXNfYmxvcXVl
:::b19ib3Qoc3RyKGUpKToKICAgICAgICAgICAgICAgICAgICAgICAgaWYgX0FOVElf
:::Qk9UWydjb21ibyddID09IDA6CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBs
:::b2coJ1lvdVR1YmUgZXN0w6EgcGlkaWVuZG8gdmVyaWZpY2FjacOzbiAnCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2FudGktYm90IHBhcmEgZXN0YSBy
:::ZWQuIFJlaW50ZW50YW5kbyBjb24gJwogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICd1bmEgdsOtYSBpbnRlcm5hIGFsdGVybmF0aXZhLi4uJywgJ2F2aXNv
:::JykKICAgICAgICAgICAgICAgICAgICAgICAgICAgIF9BTlRJX0JPVFsnY29tYm8n
:::XSA9IDEKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRyeToKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICB0aW1lLnNsZWVwKDMpICAgIyByZXNwaXJv
:::IHBhcmEgZWwgNDI5CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgc2Vs
:::Zi5faGlsb19kZXNjYXJnYXIoY2ZnKQogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgIHJldHVybgogICAgICAgICAgICAgICAgICAgICAgICAgICAgZmluYWxs
:::eToKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBfQU5USV9CT1RbJ2Nv
:::bWJvJ10gPSAwCiAgICAgICAgICAgICAgICAgICAgICAgIGxvZygn4pyWIFlvdVR1
:::YmUgc2lndWUgcGlkaWVuZG8gdmVyaWZpY2FjacOzbjogJwogICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgKyBtc2csICdlcnJvcicpCiAgICAgICAgICAgICAgICAg
:::ICAgICAgIGxvZygnU29sdWNpw7NuIGZpYWJsZTogZW4gwqtTaSBZb3VUdWJlIGJs
:::b3F1ZWE6wrsgJwogICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2VsaWdlIFVz
:::YXIgY29va2llcyBkZSBGaXJlZm94IChvIHR1ICcKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICduYXZlZ2Fkb3IpIHkgcmVpbnRlbnRhOiBjb24gdHUgc2VzacOz
:::biAnCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnYWJpZXJ0YSBZb3VUdWJl
:::IG5vIHZ1ZWx2ZSBhIHBlZGlyICcKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICd2ZXJpZmljYWNpw7NuLicsICdncmlzJykKICAgICAgICAgICAgICAgICAgICAg
:::ICAgbG9nKCdUYW1iacOpbiBzdWVsZW4gZnVuY2lvbmFyOiBlc3BlcmFyIHVub3Mg
:::JwogICAgICAgICAgICAgICAgICAgICAgICAgICAgJ21pbnV0b3MsIHB1bHNhciBD
:::dHJsK1UgKGFjdHVhbGl6YXIgeXQtZGxwKSAnCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAnbyBwcm9iYXIgY29uIG90cmEgcmVkIChlbCB3aWZpIGRlIGNhc2Ep
:::LicsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZ3JpcycpCiAgICAgICAg
:::ICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgICAgICAgICAgbG9nKCfi
:::nJYgTm8gc2UgcHVkbyBkZXNjYXJnYXI6ICcgKyBtc2csICdlcnJvcicpCiAgICAg
:::ICAgICAgICAgICAgICAgICAgIGxvZygnQ29uc2Vqb3M6IHJldmlzYSBsYSBVUkwg
:::eSB0dSBjb25leGnDs247IHNpICcKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICdZb3VUdWJlIGNhbWJpw7MgYWxnbywgcHVsc2EgQ3RybCtVICcKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICcoYWN0dWFsaXphciB5dC1kbHApIHkgcmVpbnRl
:::bnRhLicsICdncmlzJykKICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAg
:::ICAgICAgICAgbG9nKGYn4pyWIEVycm9yIGluZXNwZXJhZG8gKHtub21icmVfZXhj
:::fSk6IHtlfScsICdlcnJvcicpCiAgICAgICAgICAgICAgICAgICAgdGIgPSB0cmFj
:::ZWJhY2suZm9ybWF0X2V4YyhsaW1pdD0zKQogICAgICAgICAgICAgICAgICAgIHRy
:::eToKICAgICAgICAgICAgICAgICAgICAgICAgd2l0aCBvcGVuKExPR19FUlJPUkVT
:::LCAnYScsIGVuY29kaW5nPSd1dGYtOCcpIGFzIGZoOgogICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgZmgud3JpdGUodGIgKyAnXG4nKQogICAgICAgICAgICAgICAg
:::ICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgICAgICAgICAgICAgIHBh
:::c3MKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2Rlc2NhcmdhJywg
:::RmFsc2UsCiAgICAgICAgICAgICAgICAgICAgICAgICAgJ05vIHNlIHB1ZG8gY29t
:::cGxldGFyIGxhIGRlc2NhcmdhLiBSZXZpc2EgZWwgJwogICAgICAgICAgICAgICAg
:::ICAgICAgICAgICdyZWdpc3RybyBwYXJhIG3DoXMgZGV0YWxsZXMuJykpCgogICAg
:::ICAgIGRlZiBfaGlsb19jb21wcm9iYXIoc2VsZiwgY2ZnKToKICAgICAgICAgICAg
:::Y29sYSA9IHNlbGYuY29sYQoKICAgICAgICAgICAgZGVmIGxvZyhtLCB0PSdpbmZv
:::Jyk6CiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAg
:::ICAgICAgICAgY2FycGV0YSA9IFBhdGgob3MucGF0aC5leHBhbmR2YXJzKAogICAg
:::ICAgICAgICAgICAgc3RyKEFKVVNURVMuZ2V0KCdkZXN0aW5vJywgX2Rlc3Rpbm9f
:::cG9yX2RlZmVjdG8oKSkpKSkKICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAg
:::ICAgaWYgbm90IGNhcnBldGEuaXNfZGlyKCk6CiAgICAgICAgICAgICAgICAgICAg
:::bG9nKGYnTGEgY2FycGV0YSB0b2RhdsOtYSBubyBleGlzdGU6IHtjYXJwZXRhfScs
:::ICdhdmlzbycpCiAgICAgICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAn
:::Y29tcHJvYmFjaW9uJywgVHJ1ZSwgJycpKQogICAgICAgICAgICAgICAgICAgIHJl
:::dHVybgogICAgICAgICAgICAgICAgaWYgRkZQUk9CRSBpcyBOb25lOgogICAgICAg
:::ICAgICAgICAgICAgIGxvZygnZmZwcm9iZSBubyBlc3TDoSBkaXNwb25pYmxlICh2
:::aWVuZSBjb24gRkZtcGVnKS4gJwogICAgICAgICAgICAgICAgICAgICAgICAnRWpl
:::Y3V0YSBEZXNjYXJnYWRvck11c2ljYS5iYXQgcGFyYSBpbnN0YWxhcmxvLicsCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICdlcnJvcicpCiAgICAgICAgICAgICAgICAg
:::ICAgY29sYS5wdXQoKCdmaW4nLCAnY29tcHJvYmFjaW9uJywgVHJ1ZSwgJycpKQog
:::ICAgICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICAgICAgZXh0cyA9
:::ICgnLm00YScsICcubXAzJywgJy5mbGFjJywgJy53YXYnLCAnLndtYScsICcuYXZp
:::JykKICAgICAgICAgICAgICAgIGFyY2hpdm9zID0gW3AgZm9yIHAgaW4gc29ydGVk
:::KGNhcnBldGEucmdsb2IoJyonKSkKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::IGlmIHAuaXNfZmlsZSgpIGFuZCBwLnN1ZmZpeC5sb3dlcigpIGluIGV4dHMKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgIGFuZCAnX3RtcCcgbm90IGluIHAucGFy
:::dHNdCiAgICAgICAgICAgICAgICBsb2coZidDb21wcm9iYW5kbyB7bGVuKGFyY2hp
:::dm9zKX0gYXJjaGl2byhzKSBlbiAnCiAgICAgICAgICAgICAgICAgICAgZid7Y2Fy
:::cGV0YX0gLi4uJywgJ3RpdHVsbycpCiAgICAgICAgICAgICAgICBpZiBub3QgYXJj
:::aGl2b3M6CiAgICAgICAgICAgICAgICAgICAgbG9nKCdObyBoYXkgYXJjaGl2b3Mg
:::ZGUgYXVkaW8gbyB2aWRlbyB0b2RhdsOtYS4nLCAnZ3JpcycpCiAgICAgICAgICAg
:::ICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnY29tcHJvYmFjaW9uJywgVHJ1ZSwg
:::JycpKQogICAgICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICAgICAg
:::dG90YWwgPSAwCiAgICAgICAgICAgICAgICBiYWphcyA9IDAKICAgICAgICAgICAg
:::ICAgIGZvciBwIGluIGFyY2hpdm9zOgogICAgICAgICAgICAgICAgICAgIHRyeToK
:::ICAgICAgICAgICAgICAgICAgICAgICAgciA9IHN1YnByb2Nlc3MucnVuKAogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgW3N0cihGRlBST0JFKSwgJy12JywgJ2Vy
:::cm9yJywgJy1zaG93X2VudHJpZXMnLAogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICdmb3JtYXQ9Yml0X3JhdGUsZHVyYXRpb24sc2l6ZScsICctb2YnLCAnanNv
:::bicsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgc3RyKHApXSwKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgIHN0ZG91dD1zdWJwcm9jZXNzLlBJUEUsIHN0
:::ZGVycj1zdWJwcm9jZXNzLlBJUEUsCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICB0ZXh0PVRydWUsIGVuY29kaW5nPSd1dGYtOCcsIGVycm9ycz0ncmVwbGFjZScs
:::CiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0aW1lb3V0PTMwKQogICAgICAg
:::ICAgICAgICAgICAgICAgICBkYXRvcyA9IGpzb24ubG9hZHMoci5zdGRvdXQgb3Ig
:::J3t9JykuZ2V0KCdmb3JtYXQnLCB7fSkKICAgICAgICAgICAgICAgICAgICAgICAg
:::a2JwcyA9IGludChmbG9hdChkYXRvcy5nZXQoJ2JpdF9yYXRlJykgb3IgMCkgLyAx
:::MDAwKQogICAgICAgICAgICAgICAgICAgICAgICBkdXIgPSBmbG9hdChkYXRvcy5n
:::ZXQoJ2R1cmF0aW9uJykgb3IgMCkKICAgICAgICAgICAgICAgICAgICAgICAgdGFt
:::ID0gaW50KGZsb2F0KGRhdG9zLmdldCgnc2l6ZScpIG9yIDApKQogICAgICAgICAg
:::ICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgICAgICAgICAg
:::ICAgIGxvZyhmJ8K3IHtwLm5hbWVbOjYwXX0g4oCUIG5vIHNlIHB1ZG8gbGVlcics
:::ICdhdmlzbycpCiAgICAgICAgICAgICAgICAgICAgICAgIGNvbnRpbnVlCiAgICAg
:::ICAgICAgICAgICAgICAgdG90YWwgKz0gdGFtCiAgICAgICAgICAgICAgICAgICAg
:::dGV4dG8sIG5pdmVsID0gY2xhc2VfY2FsaWRhZChwLnN1ZmZpeC5sb3dlcigpLCBr
:::YnBzKQogICAgICAgICAgICAgICAgICAgIGlmIG5pdmVsID09IDI6CiAgICAgICAg
:::ICAgICAgICAgICAgICAgIGJhamFzICs9IDEKICAgICAgICAgICAgICAgICAgICB0
:::YWcgPSAoJ29rJyBpZiBuaXZlbCA9PSAwCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIGVsc2UgKCdhdmlzbycgaWYgbml2ZWwgPT0gMSBlbHNlICdlcnJvcicpKQog
:::ICAgICAgICAgICAgICAgICAgIGxvZyhmJ8K3IHtwLm5hbWVbOjU4XX0g4oCUIHt0
:::ZXh0b30gwrcge2ZtdF90aWVtKGR1cil9IMK3ICcKICAgICAgICAgICAgICAgICAg
:::ICAgICAgZid7Zm10X3RhbSh0YW0pfScsIHRhZykKICAgICAgICAgICAgICAgIGxv
:::ZyhmJ1Jlc3VsdGFkbzoge2xlbihhcmNoaXZvcyl9IGFyY2hpdm8ocykgwrcgJwog
:::ICAgICAgICAgICAgICAgICAgIGYne2ZtdF90YW0odG90YWwpfSBlbiB0b3RhbCDC
:::tyB7YmFqYXN9IGNvbiBjYWxpZGFkIGJhamEnLAogICAgICAgICAgICAgICAgICAg
:::ICd0aXR1bG8nKQogICAgICAgICAgICAgICAgaWYgYmFqYXM6CiAgICAgICAgICAg
:::ICAgICAgICAgbG9nKCdDb25zZWpvOiBsb3MgYXJjaGl2b3MgbWFyY2Fkb3MgZW4g
:::cm9qbyBzZSBwdWVkZW4gJwogICAgICAgICAgICAgICAgICAgICAgICAndm9sdmVy
:::IGEgZGVzY2FyZ2FyIGNvbiBtw6FzIGJpdHJhdGUuJywgJ2dyaXMnKQogICAgICAg
:::ICAgICBleGNlcHQgRXhjZXB0aW9uIGFzIGU6CiAgICAgICAgICAgICAgICBsb2co
:::ZidFcnJvciBhbCBjb21wcm9iYXIgbGEgY2FycGV0YToge2V9JywgJ2Vycm9yJykK
:::ICAgICAgICAgICAgZmluYWxseToKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgn
:::ZmluJywgJ2NvbXByb2JhY2lvbicsIFRydWUsICcnKSkKCiAgICAgICAgZGVmIF9o
:::aWxvX2FjdHVhbGl6YXIoc2VsZiwgY2ZnKToKICAgICAgICAgICAgY29sYSA9IHNl
:::bGYuY29sYQoKICAgICAgICAgICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAgICAg
:::ICAgICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgICAgICAgICAg
:::dHJ5OgogICAgICAgICAgICAgICAgbG9nKCdBY3R1YWxpemFuZG8geXQtZGxwIHkg
:::bXV0YWdlbi4uLicsICdncmlzJykKICAgICAgICAgICAgICAgIHAgPSBzdWJwcm9j
:::ZXNzLnJ1bigKICAgICAgICAgICAgICAgICAgICBbc3lzLmV4ZWN1dGFibGUsICct
:::bScsICdwaXAnLCAnaW5zdGFsbCcsICctLXVwZ3JhZGUnLAogICAgICAgICAgICAg
:::ICAgICAgICAnLS1uby13YXJuLXNjcmlwdC1sb2NhdGlvbicsICd5dC1kbHAnLCAn
:::bXV0YWdlbiddLAogICAgICAgICAgICAgICAgICAgIHN0ZG91dD1zdWJwcm9jZXNz
:::LlBJUEUsIHN0ZGVycj1zdWJwcm9jZXNzLlNURE9VVCwKICAgICAgICAgICAgICAg
:::ICAgICB0ZXh0PVRydWUsIGVuY29kaW5nPSd1dGYtOCcsIGVycm9ycz0ncmVwbGFj
:::ZScsIHRpbWVvdXQ9NjAwKQogICAgICAgICAgICAgICAgZm9yIGxuIGluIChwLnN0
:::ZG91dCBvciAnJykuc3RyaXAoKS5zcGxpdGxpbmVzKClbLTY6XToKICAgICAgICAg
:::ICAgICAgICAgICBsb2coJyAgICcgKyBsbls6MTYwXSwgJ2dyaXMnKQogICAgICAg
:::ICAgICAgICAgaWYgcC5yZXR1cm5jb2RlID09IDA6CiAgICAgICAgICAgICAgICAg
:::ICAgbG9nKCd5dC1kbHAgYWN0dWFsaXphZG8uIFJlaW5pY2lhIGxhIGFwbGljYWNp
:::w7NuIHBhcmEgJwogICAgICAgICAgICAgICAgICAgICAgICAndXNhciBsYSB2ZXJz
:::acOzbiBudWV2YS4nLCAnb2snKQogICAgICAgICAgICAgICAgZWxzZToKICAgICAg
:::ICAgICAgICAgICAgICBsb2coJ0xhIGFjdHVhbGl6YWNpw7NuIGZhbGzDsyAowr9z
:::aW4gaW50ZXJuZXQ/KS4nLCAnZXJyb3InKQogICAgICAgICAgICBleGNlcHQgRXhj
:::ZXB0aW9uIGFzIGU6CiAgICAgICAgICAgICAgICBsb2coZidObyBzZSBwdWRvIGVq
:::ZWN1dGFyIHBpcDoge2V9JywgJ2Vycm9yJykKICAgICAgICAgICAgZmluYWxseToK
:::ICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2FjdHVhbGl6YWNpb24n
:::LCBUcnVlLCAnJykpCgogICAgICAgIGRlZiBfbXNnX2Vycm9yKHNlbGYsIGUpOgog
:::ICAgICAgICAgICBsaW5lYXMgPSBbbCBmb3IgbCBpbiBzdHIoZSkuc3RyaXAoKS5z
:::cGxpdGxpbmVzKCkgaWYgbC5zdHJpcCgpXQogICAgICAgICAgICByZXR1cm4gKGxp
:::bmVhc1swXVs6MjUwXSBpZiBsaW5lYXMKICAgICAgICAgICAgICAgICAgICBlbHNl
:::IGYne3R5cGUoZSkuX19uYW1lX199OiBzaW4gZGV0YWxsZXMnKQoKICAgICAgICAj
:::IC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LSBhcnJhbnF1ZQogICAgICAgIGRlZiBfYXJyYW5xdWUoc2VsZik6CiAgICAgICAg
:::ICAgIHNlbGYuX2xvZyhmJ011c2lrQUxBTiB2e0FQUF9WfScsICd0aXR1bG8nKQog
:::ICAgICAgICAgICBzZWxmLl9sb2coJ0N0cmwrVTogYWN0dWFsaXphciB5dC1kbHAg
:::wrcgQ3RybCtMOiBsaW1waWFyIHJlZ2lzdHJvJywKICAgICAgICAgICAgICAgICAg
:::ICAgICdncmlzJykKICAgICAgICAgICAgdGhyZWFkaW5nLlRocmVhZCh0YXJnZXQ9
:::c2VsZi5faGlsb192ZXJzaW9uLCBkYWVtb249VHJ1ZSkuc3RhcnQoKQoKICAgICAg
:::ICBkZWYgX2hpbG9fdmVyc2lvbihzZWxmKToKICAgICAgICAgICAgY29sYSA9IHNl
:::bGYuY29sYQoKICAgICAgICAgICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAgICAg
:::ICAgICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgICAgICAgICAg
:::aWYgWVRfRExQIGlzIE5vbmU6CiAgICAgICAgICAgICAgICBsb2coJ3l0LWRscCBu
:::byBlc3TDoSBpbnN0YWxhZG8uIEVqZWN1dGEgJwogICAgICAgICAgICAgICAgICAg
:::ICdEZXNjYXJnYWRvck11c2ljYS5iYXQgcGFyYSBpbnN0YWxhcmxvLicsICdlcnJv
:::cicpCiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICd2ZXJzaW9uJywg
:::VHJ1ZSwgJycpKQogICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgIHRy
:::eToKICAgICAgICAgICAgICAgIGluc3RhbGFkYSA9IFlUX0RMUC52ZXJzaW9uLl9f
:::dmVyc2lvbl9fCiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAg
:::ICAgICAgICBpbnN0YWxhZGEgPSAnPycKICAgICAgICAgICAgdWx0aW1hID0gTm9u
:::ZQogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICB3aXRoIHVybG9wZW4o
:::J2h0dHBzOi8vcHlwaS5vcmcvcHlwaS95dC1kbHAvanNvbicsIHRpbWVvdXQ9MTIp
:::IGFzIHI6CiAgICAgICAgICAgICAgICAgICAgdWx0aW1hID0ganNvbi5sb2Fkcyhy
:::LnJlYWQoKS5kZWNvZGUoJ3V0Zi04JykpWydpbmZvJ11bJ3ZlcnNpb24nXQogICAg
:::ICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICAgICAgdWx0aW1h
:::ID0gTm9uZQogICAgICAgICAgICBpZiB1bHRpbWEgaXMgTm9uZToKICAgICAgICAg
:::ICAgICAgIGxvZyhmJ3l0LWRscDogdmVyc2nDs24ge2luc3RhbGFkYX0gJwogICAg
:::ICAgICAgICAgICAgICAgICcobm8gc2UgcHVkbyBjb21wcm9iYXIgc2kgaGF5IG5v
:::dmVkYWRlcykuJywgJ2dyaXMnKQogICAgICAgICAgICBlbGlmIHN0cih1bHRpbWEp
:::ID09IHN0cihpbnN0YWxhZGEpOgogICAgICAgICAgICAgICAgbG9nKGYneXQtZGxw
:::OiBlbiBsYSB1bHRpbWEgdmVyc2lvbiAoe2luc3RhbGFkYX0pLicsICdpbmZvJykK
:::ICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgIGxvZyhmJ3l0LWRscDog
:::aGF5IHZlcnNpb24gbnVldmEgKHt1bHRpbWF9KTsgaW5zdGFsYWRhOiAnCiAgICAg
:::ICAgICAgICAgICAgICAgZid7aW5zdGFsYWRhfS4gUHVsc2EgQ3RybCtVIHBhcmEg
:::YWN0dWFsaXphci4nLCAnYXZpc28nKQogICAgICAgICAgICBpZiBGRk1QRUcgaXMg
:::Tm9uZToKICAgICAgICAgICAgICAgIGxvZygnRkZtcGVnOiBOTyBFTkNPTlRSQURP
:::IOKAlCBlamVjdXRhIERlc2NhcmdhZG9yTXVzaWNhLmJhdCAnCiAgICAgICAgICAg
:::ICAgICAgICAgJ3BhcmEgaW5zdGFsYXJsby4nLCAnZXJyb3InKQogICAgICAgICAg
:::ICBlbHNlOgogICAgICAgICAgICAgICAgbG9nKGYnRkZtcGVnOiBPSyAoe0ZGTVBF
:::R30pJywgJ2dyaXMnKQogICAgICAgICAgICBsb2coJ0NhcnBldGEgZGUgZ3VhcmRh
:::ZG86ICcgKyBzdHIoQUpVU1RFUy5nZXQoJ2Rlc3Rpbm8nKSksICdncmlzJykKICAg
:::ICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAndmVyc2lvbicsIFRydWUsICcnKSkK
:::CgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0gbWFpbgpkZWYgbWFpbigpOgogICAgX3JlY29u
:::ZmlndXJhcl9zYWxpZGEoKQogICAgaWYgbm90IFRLX09LOgogICAgICAgIHByaW50
:::KCdFc3RhIGFwbGljYWNpw7NuIG5lY2VzaXRhIFRraW50ZXIgKGludGVyZmF6IGdy
:::w6FmaWNhKS4nKQogICAgICAgIHByaW50KCdFbCBQeXRob24gYWN0dWFsIG5vIGxv
:::IGluY2x1eWUuJykKICAgICAgICBwcmludCgnVnVlbHZlIGEgZWplY3V0YXIgRGVz
:::Y2FyZ2Fkb3JNdXNpY2EuYmF0IHBhcmEgaW5zdGFsYXIgZWwgJwogICAgICAgICAg
:::ICAgICdQeXRob24gYWRlY3VhZG8uJykKICAgICAgICByZXR1cm4gMQogICAgY29t
:::cHJvYmFyX2VudG9ybm8oKQogICAgYXBwID0gQXBwKCkKICAgIGFwcC5tYWlubG9v
:::cCgpCiAgICByZXR1cm4gMAoKCmlmIF9fbmFtZV9fID09ICdfX21haW5fXyc6CiAg
:::ICB0cnk6CiAgICAgICAgc3lzLmV4aXQobWFpbigpKQogICAgZXhjZXB0IFN5c3Rl
:::bUV4aXQ6CiAgICAgICAgcmFpc2UKICAgIGV4Y2VwdCBCYXNlRXhjZXB0aW9uOgog
:::ICAgICAgIHRyeToKICAgICAgICAgICAgd2l0aCBvcGVuKExPR19FUlJPUkVTLCAn
:::YScsIGVuY29kaW5nPSd1dGYtOCcpIGFzIGZoOgogICAgICAgICAgICAgICAgZmgu
:::d3JpdGUodHJhY2ViYWNrLmZvcm1hdF9leGMoKSArICdcbicpCiAgICAgICAgZXhj
:::ZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgcGFzcwogICAgICAgIHJhaXNlCg==
