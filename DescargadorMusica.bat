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
title MusikALAN v2.15
rem  Marca de version: la busca este mismo archivo con findstr para
rem  compararse con la ultima release publicada en GitHub.
rem  NO cambiar el formato de la linea siguiente.
rem VERSION-BUSCABLE: 2.15
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
echo    %C_TIT%MusikALAN v2.15%C_FIN% - preparando el entorno
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
title MusikALAN v2.15 - YouTube a AAC/MP3/FLAC/WAV/WMA/AVI
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
:::UF9WID0gJzIuMTUnCkFQUF9ESVIgPSBQYXRoKF9fZmlsZV9fKS5yZXNvbHZlKCku
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
:::w61hIGFudGktYmxvcXVlbyBlbiBjdXJzby4iIiIKICAgIGNvbWJvID0gX0FOVElf
:::Qk9UWydjb21ibyddCiAgICBpZiBjb21ibyA+PSAwOgogICAgICAgIG9bJ2V4dHJh
:::Y3Rvcl9hcmdzJ10gPSB7J3lvdXR1YmUnOiB7J3BsYXllcl9jbGllbnQnOgogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBsaXN0KENPTUJPU19BTlRJX0JPVFtj
:::b21ib10pfX0KICAgICAgICBvWydmb3JjZWlwdjQnXSA9IFRydWUKICAgICMgdjIu
:::MTU6IGNvbWJvIC0xID0gdsOtYSBjbMOhc2ljYSBkZSBsYSB2Mi44OiBjbGllbnRl
:::cyBwb3IgZGVmZWN0byBkZQogICAgIyB5dC1kbHAsIHNpbiBmb3J6YXIgY2xpZW50
:::ZXMgbcOzdmlsZXMgbmkgSVB2NCAobGFzIGNvb2tpZXMsIHNpIGVsCiAgICAjIHVz
:::dWFyaW8gbGFzIGVsaWdpw7MsIHNlIHNpZ3VlbiB1c2FuZG86IHNvbiBkZWNpc2nD
:::s24gZXhwbMOtY2l0YSBzdXlhKS4KICAgIG5hdmVnYWRvciA9IHN0cihBSlVTVEVT
:::LmdldCgnY29va2llcycsICcnKSBvciAnJykuc3RyaXAoKS5sb3dlcigpCiAgICBp
:::ZiBuYXZlZ2Fkb3IgaW4gTkFWRUdBRE9SRVNfQ09PS0lFUzoKICAgICAgICBvWydj
:::b29raWVzZnJvbWJyb3dzZXInXSA9IChuYXZlZ2Fkb3IsKQogICAgcmV0dXJuIG8K
:::CgpkZWYgX2VzX2Jsb3F1ZW9fYm90KHRleHRvKToKICAgICIiIlRydWUgc2kgZWwg
:::ZXJyb3IgZGUgeXQtZGxwIGVzIGVsIGNoZXF1ZW8gYW50aS1ib3QgbyB1biA0Mjku
:::IiIiCiAgICB0ID0gKHRleHRvIG9yICcnKS5sb3dlcigpCiAgICByZXR1cm4gKCdu
:::b3QgYSBib3QnIGluIHQgb3IgJ3NpZ24gaW4gdG8gY29uZmlybScgaW4gdAogICAg
:::ICAgICAgICBvciAndG9vIG1hbnkgcmVxdWVzdHMnIGluIHQgb3IgJ2h0dHAgZXJy
:::b3IgNDI5JyBpbiB0CiAgICAgICAgICAgIG9yICcgZXJyb3IgNDI5JyBpbiB0KQoK
:::CmRlZiBfZXNfcmVzdHJpY2Npb25fZWRhZCh0ZXh0byk6CiAgICAiIiJ2Mi4xNTog
:::VHJ1ZSBzaSBlbCBlcnJvciBpbmRpY2EgcXVlIGVsIHZpZGVvIHRpZW5lIHJlc3Ry
:::aWNjacOzbiBkZQogICAgZWRhZC4gRWwgbWVuc2FqZSBkZSBZb3VUdWJlIGVzIHBh
:::cmVjaWRvIGFsIGRlbCBjaGVxdWVvIGFudGktYm90CiAgICAoJ1NpZ24gaW4gdG8g
:::Y29uZmlybSB5b3VyIGFnZScpLCBwZXJvIGxhIHNvbHVjacOzbiBlcyBkaXN0aW50
:::YToKICAgIHJlaW50ZW50YXIgcG9yIG90cmFzIHbDrWFzIE5PIHNpcnZlIChuaW5n
:::dW5hIHbDrWEgYW7Ds25pbWEgcGFzYSBlbAogICAgY29udHJvbCBkZSBlZGFkKTsg
:::aGF5IHF1ZSB1c2FyIGNvb2tpZXMgY29uIHNlc2nDs24gYWJpZXJ0YSBvLCBjb21v
:::CiAgICBwaWRlIGxhIGFwcCwgYnVzY2FyIG90cmEgdmVyc2nDs24gZGVsIHZpZGVv
:::IHNpbiBsYSByZXN0cmljY2nDs24uIiIiCiAgICB0ID0gKHRleHRvIG9yICcnKS5s
:::b3dlcigpCiAgICByZXR1cm4gKCdjb25maXJtIHlvdXIgYWdlJyBpbiB0IG9yICdh
:::Z2UtcmVzdHJpY3RlZCcgaW4gdAogICAgICAgICAgICBvciAnYWdlIHJlc3RyaWN0
:::ZWQnIGluIHQKICAgICAgICAgICAgb3IgJ2luYXBwcm9wcmlhdGUgZm9yIHNvbWUg
:::dXNlcnMnIGluIHQpCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tIGVzY2FsZXJhIGRlIHJlaW50ZW50b3MKIyB2Mi4x
:::NTogc2kgdW5hIGRlc2NhcmdhIHN1ZWx0YSBmYWxsYSwgc2UgcHJ1ZWJhIGF1dG9t
:::w6F0aWNhbWVudGUgcG9yCiMgdmFyaWFzIHbDrWFzIChzaWVtcHJlIHBpZGllbmRv
:::IGxhIGNhbGlkYWQgc2VsZWNjaW9uYWRhKSBhbnRlcyBkZSBkYXIgZWwKIyBmYWxs
:::byBwb3IgZGVmaW5pdGl2bzoKIyAgIDEpIGxhIHbDrWEgY2zDoXNpY2EgZGUgbGEg
:::djIuODogY2xpZW50ZXMgcG9yIGRlZmVjdG8gZGUgeXQtZGxwCiMgICAyKSBsb3Mg
:::Y2xpZW50ZXMgbcOzdmlsZXMgZGUgbGEgdjIuOTogYW5kcm9pZC9pb3MvbXdlYgoj
:::ICAgMykgbGEgdsOtYSBzaW4gY2xpZW50ZXMgd2ViIGRlIGxhIHYyLjk6IGFuZHJv
:::aWRfdnIvYW5kcm9pZC9pb3MKIyBTaSBZb3VUdWJlIHBpZGUgY29uZmlybWFjacOz
:::biAoYm90LzQyOSkgc2UgcGFzYSBhIGxhIHbDrWEgc2lndWllbnRlLiBTaQojIGVs
:::IHZpZGVvIHRpZW5lIHJlc3RyaWNjacOzbiBkZSBlZGFkLCBsYSBlc2NhbGVyYSBz
:::ZSBjb3J0YTogbmluZ3VuYSB2w61hCiMgYW7Ds25pbWEgbGEgcGFzYS4KRVNDQUxF
:::UkFfVklBUyA9ICgKICAgICgtMSwgJ2xhIHbDrWEgY2zDoXNpY2EgKGNvbW8gbGEg
:::djIuOCknKSwKICAgICgwLCAnbG9zIGNsaWVudGVzIG3Ds3ZpbGVzIChhbmRyb2lk
:::L2lvcyknKSwKICAgICgxLCAnbGEgdsOtYSBpbnRlcm5hIGFsdGVybmF0aXZhIChh
:::bmRyb2lkX3ZyKScpLAopCgoKZGVmIGRlc2NhcmdhX2Nvbl9lc2NhbGVyYShzZWxm
:::LCB1cmwsIGNsYXZlLCBjYWxpZGFkX2FyZywgZW1iZWJlciwgZGVzdGlubywKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICBjb2xhKToKICAgICIiInYyLjE1OiBpbnRl
:::bnRhIGxhIGRlc2NhcmdhIHBvciBsYXMgdsOtYXMgZGUgRVNDQUxFUkFfVklBUyBl
:::biBvcmRlbgogICAgaGFzdGEgcXVlIHVuYSBzYWxnYSwgc2llbXByZSBwaWRpZW5k
:::byBsYSBjYWxpZGFkIHNlbGVjY2lvbmFkYS4KICAgIERldnVlbHZlIChhcmNoaXZv
:::fE5vbmUsIGNsYXNlfE5vbmUsIG1lbnNhamUpIGRvbmRlIGNsYXNlIE5vbmUgPQog
:::ICAgw6l4aXRvLCAnZWRhZCcgPSByZXN0cmljY2nDs24gZGUgZWRhZCwgJ2JvdCcg
:::PSBZb3VUdWJlIHBpZGnDswogICAgdmVyaWZpY2FjacOzbiBwb3IgdG9kYXMgbGFz
:::IHbDrWFzLCAnb3RybycgPSBmYWxsbyBub3JtYWwuIiIiCiAgICBkZWYgbG9nKG0s
:::IHQ9J2luZm8nKToKICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAg
:::IHVsdGltbyA9ICcnCiAgICB0cnk6CiAgICAgICAgZm9yIGksIChtb2RvLCBub21i
:::cmUpIGluIGVudW1lcmF0ZShFU0NBTEVSQV9WSUFTKToKICAgICAgICAgICAgaWYg
:::aToKICAgICAgICAgICAgICAgIHRpbWUuc2xlZXAoMykgICAjIHJlc3Bpcm8gZW50
:::cmUgdsOtYXMgKGRlamFyIGVuZnJpYXIgZWwgNDI5KQogICAgICAgICAgICBfQU5U
:::SV9CT1RbJ2NvbWJvJ10gPSBtb2RvCiAgICAgICAgICAgIHNpZ3VpZW50ZSA9IChF
:::U0NBTEVSQV9WSUFTW2kgKyAxXVsxXQogICAgICAgICAgICAgICAgICAgICAgICAg
:::aWYgaSArIDEgPCBsZW4oRVNDQUxFUkFfVklBUykgZWxzZSBOb25lKQogICAgICAg
:::ICAgICB0cnk6CiAgICAgICAgICAgICAgICBhcmNoaXZvID0gc2VsZi5fZGVzY2Fy
:::Z2FyX3VuYSh1cmwsIGNsYXZlLCBjYWxpZGFkX2FyZywKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGVtYmViZXIsIGRlc3Rpbm8s
:::IGNvbGEpCiAgICAgICAgICAgICAgICBpZiBhcmNoaXZvIGFuZCBQYXRoKGFyY2hp
:::dm8pLmV4aXN0cygpOgogICAgICAgICAgICAgICAgICAgIHJldHVybiBhcmNoaXZv
:::LCBOb25lLCAnJwogICAgICAgICAgICAgICAgdWx0aW1vID0gJ2VsIGFyY2hpdm8g
:::ZmluYWwgbm8gYXBhcmVjacOzIGRvbmRlIHNlIGVzcGVyYWJhJwogICAgICAgICAg
:::ICBleGNlcHQgRXhjZXB0aW9uIGFzIGU6CiAgICAgICAgICAgICAgICB1bHRpbW8g
:::PSBzdHIoZSkuc3RyaXAoKSBvciB0eXBlKGUpLl9fbmFtZV9fCiAgICAgICAgICAg
:::ICAgICBpZiBfZXNfcmVzdHJpY2Npb25fZWRhZCh1bHRpbW8pOgogICAgICAgICAg
:::ICAgICAgICAgIHJldHVybiBOb25lLCAnZWRhZCcsIHVsdGltbwogICAgICAgICAg
:::ICAgICAgaWYgc2lndWllbnRlOgogICAgICAgICAgICAgICAgICAgIG1vdGl2byA9
:::ICgnWW91VHViZSBwaWRpw7MgY29uZmlybWFjacOzbicKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgaWYgX2VzX2Jsb3F1ZW9fYm90KHVsdGltbykKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgZWxzZSAnRmFsbMOzIHBvciAnICsgbm9t
:::YnJlKQogICAgICAgICAgICAgICAgICAgIGxvZyhtb3Rpdm8gKyAnOyBwcm9iYW5k
:::byBwb3IgJyArIHNpZ3VpZW50ZSArICcuLi4nLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAnYXZpc28nKQogICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAg
:::aWYgc2lndWllbnRlOgogICAgICAgICAgICAgICAgICAgIGxvZygnTm8gc2FsacOz
:::IHBvciAnICsgbm9tYnJlICsgJzsgcHJvYmFuZG8gcG9yICcKICAgICAgICAgICAg
:::ICAgICAgICAgICAgKyBzaWd1aWVudGUgKyAnLi4uJywgJ2F2aXNvJykKICAgICAg
:::ICByZXR1cm4gTm9uZSwgKCdib3QnIGlmIF9lc19ibG9xdWVvX2JvdCh1bHRpbW8p
:::IGVsc2UgJ290cm8nKSwgdWx0aW1vCiAgICBmaW5hbGx5OgogICAgICAgIF9BTlRJ
:::X0JPVFsnY29tYm8nXSA9IDAKCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gb3BjaW9uZXMK
:::ZGVmIG9wdHNfYmFzZShjYXJwZXRhLCBjb2xhKToKICAgIHByb2dyZXNvLCBwb3N0
:::cHJvY2VzbyA9IGhvb2tzX2d1aShjb2xhKQogICAgbyA9IHsKICAgICAgICAnb3V0
:::dG1wbCc6IHN0cihjYXJwZXRhIC8gJyUodGl0bGUpcy4lKGV4dClzJyksCiAgICAg
:::ICAgJ3F1aWV0JzogVHJ1ZSwKICAgICAgICAnbm9fd2FybmluZ3MnOiBUcnVlLAog
:::ICAgICAgICdub3Byb2dyZXNzJzogVHJ1ZSwKICAgICAgICAnbm9wbGF5bGlzdCc6
:::IFRydWUsCiAgICAgICAgJ2lnbm9yZWVycm9ycyc6IEZhbHNlLAogICAgICAgICdy
:::ZXRyaWVzJzogMTAsCiAgICAgICAgJ2ZyYWdtZW50X3JldHJpZXMnOiAxMCwKICAg
:::ICAgICAnc29ja2V0X3RpbWVvdXQnOiAzMCwKICAgICAgICAnY29uY3VycmVudF9m
:::cmFnbWVudF9kb3dubG9hZHMnOiA0LAogICAgICAgICd3aW5kb3dzZmlsZW5hbWVz
:::JzogVHJ1ZSwKICAgICAgICAnb3ZlcndyaXRlcyc6IEZhbHNlLAogICAgICAgICds
:::b2dnZXInOiBSRUdJU1RSTywKICAgICAgICAncHJvZ3Jlc3NfaG9va3MnOiBbcHJv
:::Z3Jlc29dLAogICAgICAgICdwb3N0cHJvY2Vzc29yX2hvb2tzJzogW3Bvc3Rwcm9j
:::ZXNvXSwKICAgIH0KICAgIGlmIEZGTVBFRzoKICAgICAgICBvWydmZm1wZWdfbG9j
:::YXRpb24nXSA9IHN0cihGRk1QRUcucGFyZW50KQogICAgX2FudGlfYm90KG8pCiAg
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
:::ZWhvbGRlcigpCiAgICAgICAgICAgICMgdjIuMTI6IGJvdG9uIFBlZ2FyIChwZWdh
:::IGVsIGVubGFjZSBkZWwgcG9ydGFwYXBlbGVzKSArIFgKICAgICAgICAgICAgc2Vs
:::Zi5idG5fcGVnYXIgPSBzZWxmLl9ib3RvbihndSwgJ1BlZ2FyJywgc2VsZi5fcGVn
:::YXJfdXJsKQogICAgICAgICAgICBzZWxmLmJ0bl9wZWdhci5ncmlkKHJvdz0wLCBj
:::b2x1bW49MSwgc3RpY2t5PSdlJywgcGFkeD0oMCwgNCksCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgaXBhZHk9MykKICAgICAgICAgICAgc2VsZi5idG5f
:::eCA9IHNlbGYuX2JvdG9uKGd1LCAnWCcsIHNlbGYuX2xpbXBpYXJfdXJsLCB3aWR0
:::aD0zKQogICAgICAgICAgICBzZWxmLmJ0bl94LmdyaWQocm93PTAsIGNvbHVtbj0y
:::LCBzdGlja3k9J2UnLCBwYWR4PSgwLCA4KSwgaXBhZHk9MykKCiAgICAgICAgICAg
:::ICMgLS0tIGdydXBvOiBGb3JtYXRvIHkgY2FsaWRhZCAtLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0KICAgICAgICAgICAgZ2YgPSB0ay5MYWJlbEZyYW1l
:::KG1hcmNvLCB0ZXh0PSdGb3JtYXRvIHkgY2FsaWRhZCcsIGZvbnQ9RlVFTlRFX1VJ
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVsaWVmPSdzb2xpZCcs
:::IGJkPTEpCiAgICAgICAgICAgIGdmLmdyaWQocm93PTIsIGNvbHVtbj0wLCBzdGlj
:::a3k9J2V3JywgcGFkeT01KQogICAgICAgICAgICBzZWxmLl93Z1snZ2YnXSA9IGdm
:::CiAgICAgICAgICAgIGdmLmNvbHVtbmNvbmZpZ3VyZSgxLCB3ZWlnaHQ9MSkKICAg
:::ICAgICAgICAgc2VsZi5fd2dbJ2xibF9mbXQnXSA9IHRrLkxhYmVsKGdmLCB0ZXh0
:::PSdGb3JtYXRvOicsIGZvbnQ9RlVFTlRFX1VJKQogICAgICAgICAgICBzZWxmLl93
:::Z1snbGJsX2ZtdCddLmdyaWQocm93PTAsIGNvbHVtbj0wLCBzdGlja3k9J3cnLCBw
:::YWR4PTgsIHBhZHk9NSkKICAgICAgICAgICAgc2VsZi5jbWJfZm9ybWF0byA9IHR0
:::ay5Db21ib2JveCgKICAgICAgICAgICAgICAgIGdmLCB2YWx1ZXM9W2ZbJ3RleHRv
:::J10gZm9yIGYgaW4gRk9STUFUT1MudmFsdWVzKCldLAogICAgICAgICAgICAgICAg
:::c3RhdGU9J3JlYWRvbmx5JywgZm9udD1GVUVOVEVfVUksIHN0eWxlPSdneC5UQ29t
:::Ym9ib3gnKQogICAgICAgICAgICBzZWxmLmNtYl9mb3JtYXRvLmdyaWQocm93PTAs
:::IGNvbHVtbj0xLCBzdGlja3k9J2V3JywKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgIHBhZHg9OCwgcGFkeT01LCBpcGFkeT0yKQogICAgICAgICAgICBz
:::ZWxmLl93Z1snbGJsX2NhbCddID0gdGsuTGFiZWwoZ2YsIHRleHQ9J0NhbGlkYWQ6
:::JywgZm9udD1GVUVOVEVfVUkpCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfY2Fs
:::J10uZ3JpZChyb3c9MSwgY29sdW1uPTAsIHN0aWNreT0ndycsIHBhZHg9OCwgcGFk
:::eT01KQogICAgICAgICAgICBzZWxmLmNtYl9jYWxpZGFkID0gdHRrLkNvbWJvYm94
:::KAogICAgICAgICAgICAgICAgZ2YsIHN0YXRlPSdyZWFkb25seScsIGZvbnQ9RlVF
:::TlRFX1VJLCBzdHlsZT0nZ3guVENvbWJvYm94JykKICAgICAgICAgICAgc2VsZi5j
:::bWJfY2FsaWRhZC5ncmlkKHJvdz0xLCBjb2x1bW49MSwgc3RpY2t5PSdldycsCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4PTgsIHBhZHk9NSwg
:::aXBhZHk9MikKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF9jYXInXSA9IHRrLkxh
:::YmVsKGdmLCB0ZXh0PSdDYXJwZXRhOicsIGZvbnQ9RlVFTlRFX1VJKQogICAgICAg
:::ICAgICBzZWxmLl93Z1snbGJsX2NhciddLmdyaWQocm93PTIsIGNvbHVtbj0wLCBz
:::dGlja3k9J3cnLCBwYWR4PTgsIHBhZHk9NSkKICAgICAgICAgICAgZmMgPSB0ay5G
:::cmFtZShnZikKICAgICAgICAgICAgZmMuZ3JpZChyb3c9MiwgY29sdW1uPTEsIHN0
:::aWNreT0nZXcnLCBwYWR4PTgsIHBhZHk9NSkKICAgICAgICAgICAgc2VsZi5fd2db
:::J2ZjJ10gPSBmYwogICAgICAgICAgICBmYy5jb2x1bW5jb25maWd1cmUoMCwgd2Vp
:::Z2h0PTEpCiAgICAgICAgICAgIHNlbGYuZW50X2NhcnBldGEgPSB0ay5FbnRyeShm
:::YywgZm9udD1GVUVOVEVfVUksIHJlbGllZj0nZmxhdCcsCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBoaWdobGlnaHR0aGlja25lc3M9MSkK
:::ICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5ncmlkKHJvdz0wLCBjb2x1bW49
:::MCwgc3RpY2t5PSdldycsIGlwYWR5PTQpCiAgICAgICAgICAgIHNlbGYuZW50X2Nh
:::cnBldGEuaW5zZXJ0KDAsIEFKVVNURVNbJ2Rlc3Rpbm8nXSkKICAgICAgICAgICAg
:::c2VsZi5idG5fY2FtYmlhciA9IHNlbGYuX2JvdG9uKGZjLCAnQ2FtYmlhci4uLics
:::IHNlbGYuX2NhbWJpYXJfY2FycGV0YSkKICAgICAgICAgICAgc2VsZi5idG5fY2Ft
:::Ymlhci5ncmlkKHJvdz0wLCBjb2x1bW49MSwgcGFkeD0oOCwgMCksIGlwYWR5PTMp
:::CiAgICAgICAgICAgIHNlbGYuYnRuX2FicmlyID0gc2VsZi5fYm90b24oZmMsICdB
:::YnJpcicsIHNlbGYuX2FicmlyX2Rlc3Rpbm8sIHdpZHRoPTUpCiAgICAgICAgICAg
:::IHNlbGYuYnRuX2FicmlyLmdyaWQocm93PTAsIGNvbHVtbj0yLCBwYWR4PSg2LCAw
:::KSwgaXBhZHk9MykKCiAgICAgICAgICAgIHNlbGYudmFyX2VtYmViZXIgPSB0ay5C
:::b29sZWFuVmFyKHZhbHVlPWJvb2woQUpVU1RFUy5nZXQoJ2VtYmViZXInLCBUcnVl
:::KSkpCiAgICAgICAgICAgIHNlbGYuY2hrX2VtYmViZXIgPSB0ay5DaGVja2J1dHRv
:::bigKICAgICAgICAgICAgICAgIGdmLCB0ZXh0PSdFbWJlYmVyIGNhcsOhdHVsYSwg
:::YXJ0aXN0YSB5IMOhbGJ1bScsCiAgICAgICAgICAgICAgICB2YXJpYWJsZT1zZWxm
:::LnZhcl9lbWJlYmVyLCBmb250PUZVRU5URV9VSSwgYW5jaG9yPSd3JywKICAgICAg
:::ICAgICAgICAgIHJlbGllZj0nZmxhdCcsIGhpZ2hsaWdodHRoaWNrbmVzcz0wLCBi
:::ZD0wKQogICAgICAgICAgICBzZWxmLmNoa19lbWJlYmVyLmdyaWQocm93PTMsIGNv
:::bHVtbj0wLCBjb2x1bW5zcGFuPTIsCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICBzdGlja3k9J2V3JywgcGFkeD04LCBwYWR5PSgyLCA2KSkKICAgICAg
:::ICAgICAgIyB2Mi45OiB2w61hIGFudGktYmxvcXVlbyAoY29va2llcyBkZWwgbmF2
:::ZWdhZG9yIHNpIFlvdVR1YmUKICAgICAgICAgICAgIyBwaWRlIHZlcmlmaWNhY2nD
:::s24pCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfY29va2llcyddID0gdGsuTGFi
:::ZWwoCiAgICAgICAgICAgICAgICBnZiwgdGV4dD0nU2kgWW91VHViZSBibG9xdWVh
:::OicsIGZvbnQ9RlVFTlRFX1VJKQogICAgICAgICAgICBzZWxmLl93Z1snbGJsX2Nv
:::b2tpZXMnXS5ncmlkKHJvdz00LCBjb2x1bW49MCwgc3RpY2t5PSd3JywKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4PTgsIHBhZHk9
:::NSkKICAgICAgICAgICAgc2VsZi5jbWJfY29va2llcyA9IHR0ay5Db21ib2JveCgK
:::ICAgICAgICAgICAgICAgIGdmLCB2YWx1ZXM9KFsnQXV0b23DoXRpY28gKHJlY29t
:::ZW5kYWRvKSddCiAgICAgICAgICAgICAgICAgICAgICAgICAgICArIFsnVXNhciBj
:::b29raWVzIGRlICcgKyBuLmNhcGl0YWxpemUoKQogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgZm9yIG4gaW4gTkFWRUdBRE9SRVNfQ09PS0lFU10pLAogICAg
:::ICAgICAgICAgICAgc3RhdGU9J3JlYWRvbmx5JywgZm9udD1GVUVOVEVfVUksIHN0
:::eWxlPSdneC5UQ29tYm9ib3gnKQogICAgICAgICAgICBzZWxmLmNtYl9jb29raWVz
:::LmdyaWQocm93PTQsIGNvbHVtbj0xLCBzdGlja3k9J2V3JywKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgIHBhZHg9OCwgcGFkeT01LCBpcGFkeT0yKQog
:::ICAgICAgICAgICBzZWxmLmNtYl9jb29raWVzLnNldCgnQXV0b23DoXRpY28gKHJl
:::Y29tZW5kYWRvKScpCgogICAgICAgICAgICAjIC0tLSBncnVwbzogZXN0aW1hY2nD
:::s24gLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAg
:::ICAgICAgICBnZSA9IHRrLkxhYmVsRnJhbWUobWFyY28sIHRleHQ9J0VzdGltYWNp
:::w7NuJywgZm9udD1GVUVOVEVfVUksCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICByZWxpZWY9J3NvbGlkJywgYmQ9MSkKICAgICAgICAgICAgZ2UuZ3JpZChy
:::b3c9MywgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PTUpCiAgICAgICAgICAg
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
:::ZChyb3c9NCwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PSg3LCA0KSkKICAg
:::ICAgICAgICAgc2VsZi5idG5fY29tcHJvYmFyID0gc2VsZi5fYm90b24oCiAgICAg
:::ICAgICAgICAgICBtYXJjbywgJ0NvbXByb2JhciBjYWxpZGFkIGRlIGxhIGNhcnBl
:::dGEnLAogICAgICAgICAgICAgICAgc2VsZi5fYWNjaW9uX2NvbXByb2JhciwgZnVl
:::bnRlPUZVRU5URV9CVE4pCiAgICAgICAgICAgIHNlbGYuYnRuX2NvbXByb2Jhci5n
:::cmlkKHJvdz01LCBjb2x1bW49MCwgc3RpY2t5PSdldycsIHBhZHk9MykKCiAgICAg
:::ICAgICAgICMgLS0tIGVzdGFkbyArIGJhcnJhIGRlIHByb2dyZXNvIC0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAgIHNlbGYubGJsX2Vz
:::dGFkbyA9IHRrLkxhYmVsKG1hcmNvLCB0ZXh0PScnLCBmb250PUZVRU5URV9VSSwK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgYW5jaG9yPSd3
:::JykKICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmdyaWQocm93PTYsIGNvbHVt
:::bj0wLCBzdGlja3k9J2V3JywgcGFkeT0oNCwgMCkpCiAgICAgICAgICAgIHNlbGYu
:::YmFycmEgPSB0dGsuUHJvZ3Jlc3NiYXIoCiAgICAgICAgICAgICAgICBtYXJjbywg
:::bWF4aW11bT0xMDAsIHN0eWxlPSdneC5Ib3Jpem9udGFsLlRQcm9ncmVzc2Jhcicp
:::CiAgICAgICAgICAgIHNlbGYuYmFycmEuZ3JpZChyb3c9NywgY29sdW1uPTAsIHN0
:::aWNreT0nZXcnLCBwYWR5PSgyLCA0KSkKCiAgICAgICAgICAgICMgLS0tIHJlZ2lz
:::dHJvIChsb2cpIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tCiAgICAgICAgICAgIHNlbGYudHh0X2xvZyA9IFNjcm9sbGVkVGV4dCht
:::YXJjbywgZm9udD1GVUVOVEVfTE9HLCBoZWlnaHQ9MTIsCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICByZWxpZWY9J2ZsYXQnLCBiZD0wLCB3
:::cmFwPSd3b3JkJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIHN0YXRlPSdkaXNhYmxlZCcpCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5n
:::cmlkKHJvdz04LCBjb2x1bW49MCwgc3RpY2t5PSduc2V3JykKICAgICAgICAgICAg
:::bWFyY28ucm93Y29uZmlndXJlKDgsIHdlaWdodD0xKQogICAgICAgICAgICBmb3Ig
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
:::bXQsIEFKVVNURVMuZ2V0KCdjYWxpZGFkJykpCiAgICAgICAgICAgIGNvb2tpZXMg
:::PSBzdHIoQUpVU1RFUy5nZXQoJ2Nvb2tpZXMnLCAnJykgb3IgJycpLnN0cmlwKCku
:::bG93ZXIoKQogICAgICAgICAgICBpZiBjb29raWVzIGluIE5BVkVHQURPUkVTX0NP
:::T0tJRVM6CiAgICAgICAgICAgICAgICBzZWxmLmNtYl9jb29raWVzLnNldCgnVXNh
:::ciBjb29raWVzIGRlICcKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICsgY29va2llcy5jYXBpdGFsaXplKCkpCiAgICAgICAgICAgIGVsc2U6CiAg
:::ICAgICAgICAgICAgICBzZWxmLmNtYl9jb29raWVzLnNldCgnQXV0b23DoXRpY28g
:::KHJlY29tZW5kYWRvKScpCgogICAgICAgICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0t
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
:::ZWYgX3BlZ2FyX3VybChzZWxmKToKICAgICAgICAgICAgIiIidjIuMTI6IHBlZ2Eg
:::ZW4gZWwgY2FtcG8gbGEgVVJMIGNvcGlhZGEgYWwgcG9ydGFwYXBlbGVzLgogICAg
:::ICAgICAgICBTaSBlbCBwb3J0YXBhcGVsZXMgdHJhZSB0ZXh0byBjb24gdW4gZW5s
:::YWNlIGRlbnRybyAocC4gZWouCiAgICAgICAgICAgICdtaXJhIGVzdG8gaHR0cHM6
:::Ly8uLi4nKSwgc2UgcXVlZGEgc29sbyBjb24gZWwgZW5sYWNlLiIiIgogICAgICAg
:::ICAgICB0cnk6CiAgICAgICAgICAgICAgICB0ZXh0byA9IChzZWxmLmNsaXBib2Fy
:::ZF9nZXQoKSBvciAnJykuc3RyaXAoKQogICAgICAgICAgICBleGNlcHQgRXhjZXB0
:::aW9uOgogICAgICAgICAgICAgICAgdGV4dG8gPSAnJwogICAgICAgICAgICBpZiBu
:::b3QgdGV4dG86CiAgICAgICAgICAgICAgICBzZWxmLl9sb2coJ0VsIHBvcnRhcGFw
:::ZWxlcyBlc3TDoSB2YWPDrW8gbyBubyB0aWVuZSB0ZXh0by4nLAogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICdhdmlzbycpCiAgICAgICAgICAgICAgICByZXR1cm4K
:::ICAgICAgICAgICAgbSA9IHJlLnNlYXJjaChyJ2h0dHBzPzovL1teXHMiXCddKycs
:::IHRleHRvLCByZS5JKQogICAgICAgICAgICBpZiBtOgogICAgICAgICAgICAgICAg
:::dGV4dG8gPSBtLmdyb3VwKDApCiAgICAgICAgICAgIHNlbGYuZW50X3VybC5kZWxl
:::dGUoMCwgJ2VuZCcpCiAgICAgICAgICAgIHNlbGYuZW50X3VybC5pbnNlcnQoMCwg
:::dGV4dG8pCiAgICAgICAgICAgIHNlbGYuX2VuX3BsYWNlaG9sZGVyID0gRmFsc2UK
:::ICAgICAgICAgICAgc2VsZi5fcmVmcmVzY2FyX3BsYWNlaG9sZGVyKCkKICAgICAg
:::ICAgICAgc2VsZi5lbnRfdXJsLmZvY3VzX3NldCgpCgogICAgICAgIGRlZiBfcmVz
:::ZXRfdXJsKHNlbGYpOgogICAgICAgICAgICAiIiJEZWphIGVsIGNhbXBvIGRlIFVS
:::TCB2YWPDrW8gY29uIHN1IHBsYWNlaG9sZGVyICh0cmFzIHVuIMOpeGl0bykuIiIi
:::CiAgICAgICAgICAgIHNlbGYuZW50X3VybC5kZWxldGUoMCwgJ2VuZCcpCiAgICAg
:::ICAgICAgIHNlbGYuX2VuX3BsYWNlaG9sZGVyID0gVHJ1ZQogICAgICAgICAgICBz
:::ZWxmLl9wb25lcl9wbGFjZWhvbGRlcigpCiAgICAgICAgICAgIHNlbGYuX3JlZnJl
:::c2Nhcl9wbGFjZWhvbGRlcigpCgogICAgICAgICMgLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIHRlbWEKICAgICAgICBkZWYg
:::X2FwbGljYXJfdGVtYShzZWxmKToKICAgICAgICAgICAgdCA9IFRFTUFTW3NlbGYu
:::X3RlbWFfYWN0dWFsXQogICAgICAgICAgICB3ID0gc2VsZi5fd2cKICAgICAgICAg
:::ICAgc2VsZi5jb25maWd1cmUoYmc9dFsnZm9uZG8nXSkKICAgICAgICAgICAgZm9y
:::IG5vbWJyZSBpbiAoJ21hcmNvJywgJ2YwJywgJ2d1JywgJ2dmJywgJ2ZjJywgJ2dl
:::Jyk6CiAgICAgICAgICAgICAgICB3W25vbWJyZV0uY29uZmlndXJlKGJnPXRbJ2Zv
:::bmRvJ10pCiAgICAgICAgICAgIGZvciBsZiBpbiAod1snZ3UnXSwgd1snZ2YnXSwg
:::d1snZ2UnXSk6CiAgICAgICAgICAgICAgICBsZi5jb25maWd1cmUoYmc9dFsnZm9u
:::ZG8nXSwgZmc9dFsndGV4dG8yJ10pCiAgICAgICAgICAgIGZvciBub21icmUgaW4g
:::KCdsYmxfdGVtYScsICdsYmxfZm10JywgJ2xibF9jYWwnLCAnbGJsX2NhcicpOgog
:::ICAgICAgICAgICAgICAgd1tub21icmVdLmNvbmZpZ3VyZShiZz10Wydmb25kbydd
:::LCBmZz10Wyd0ZXh0byddKQogICAgICAgICAgICBzZWxmLmxibF9lc3RpbWFjaW9u
:::LmNvbmZpZ3VyZShiZz10Wydmb25kbyddLCBmZz10Wyd0ZXh0byddKQogICAgICAg
:::ICAgICBzZWxmLmxibF9lc3RhZG8uY29uZmlndXJlKGJnPXRbJ2ZvbmRvJ10sIGZn
:::PXRbJ3RleHRvMiddKQogICAgICAgICAgICBzZWxmLmVudF91cmwuY29uZmlndXJl
:::KAogICAgICAgICAgICAgICAgYmc9dFsnY2FtcG8nXSwgZmc9dFsndGV4dG8nXSwg
:::aW5zZXJ0YmFja2dyb3VuZD10Wyd0ZXh0byddLAogICAgICAgICAgICAgICAgaGln
:::aGxpZ2h0YmFja2dyb3VuZD10WydjYW1wb19ib3JkZSddLAogICAgICAgICAgICAg
:::ICAgaGlnaGxpZ2h0Y29sb3I9dFsnYWNlbnRvJ10sCiAgICAgICAgICAgICAgICBk
:::aXNhYmxlZGJhY2tncm91bmQ9dFsnY2FtcG8nXSwgZGlzYWJsZWRmb3JlZ3JvdW5k
:::PXRbJ3RleHRvMiddKQogICAgICAgICAgICBzZWxmLmVudF9jYXJwZXRhLmNvbmZp
:::Z3VyZSgKICAgICAgICAgICAgICAgIGJnPXRbJ2NhbXBvJ10sIGZnPXRbJ3RleHRv
:::J10sIGluc2VydGJhY2tncm91bmQ9dFsndGV4dG8nXSwKICAgICAgICAgICAgICAg
:::IGhpZ2hsaWdodGJhY2tncm91bmQ9dFsnY2FtcG9fYm9yZGUnXSwKICAgICAgICAg
:::ICAgICAgIGhpZ2hsaWdodGNvbG9yPXRbJ2FjZW50byddKQogICAgICAgICAgICBz
:::ZWxmLmNoa19lbWJlYmVyLmNvbmZpZ3VyZSgKICAgICAgICAgICAgICAgIGJnPXRb
:::J2ZvbmRvJ10sIGZnPXRbJ3RleHRvJ10sIGFjdGl2ZWJhY2tncm91bmQ9dFsnZm9u
:::ZG8nXSwKICAgICAgICAgICAgICAgIGFjdGl2ZWZvcmVncm91bmQ9dFsndGV4dG8n
:::XSwgc2VsZWN0Y29sb3I9dFsnY2FtcG8nXSkKICAgICAgICAgICAgZm9yIGIgaW4g
:::c2VsZi5fYnRuczoKICAgICAgICAgICAgICAgIGIuY29uZmlndXJlKGJnPXRbJ2Jv
:::dG9uJ10sIGZnPXRbJ2JvdG9uX3R4dCddLAogICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgYWN0aXZlYmFja2dyb3VuZD10Wydib3Rvbl9hY3QnXSwKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgIGFjdGl2ZWZvcmVncm91bmQ9dFsnYm90b25fdHh0
:::J10pCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5jb25maWd1cmUoYmc9dFsnbG9n
:::J10sIGZnPXRbJ2xvZ190eHQnXSwKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICBpbnNlcnRiYWNrZ3JvdW5kPXRbJ2xvZ190eHQnXSkKICAgICAgICAg
:::ICAgc2VsZi50eHRfbG9nLnRhZ19jb25maWd1cmUoJ2luZm8nLCBmb3JlZ3JvdW5k
:::PXRbJ2xvZ190eHQnXSkKICAgICAgICAgICAgc2VsZi50eHRfbG9nLnRhZ19jb25m
:::aWd1cmUoJ2dyaXMnLCBmb3JlZ3JvdW5kPXRbJ3RleHRvMiddKQogICAgICAgICAg
:::ICBzZWxmLnR4dF9sb2cudGFnX2NvbmZpZ3VyZSgndGl0dWxvJywgZm9yZWdyb3Vu
:::ZD10Wyd0ZXh0byddLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICBmb250PSgnQ29uc29sYXMnLCAxMCwgJ2JvbGQnKSkKICAgICAgICAgICAg
:::c2VsZi50eHRfbG9nLnRhZ19jb25maWd1cmUoJ29rJywgZm9yZWdyb3VuZD10Wydv
:::ayddKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cudGFnX2NvbmZpZ3VyZSgnYXZp
:::c28nLCBmb3JlZ3JvdW5kPXRbJ2F2aXNvJ10pCiAgICAgICAgICAgIHNlbGYudHh0
:::X2xvZy50YWdfY29uZmlndXJlKCdlcnJvcicsIGZvcmVncm91bmQ9dFsnZXJyb3In
:::XSkKICAgICAgICAgICAgZXN0ID0gc2VsZi5fZXN0aWxvCiAgICAgICAgICAgIGVz
:::dC5jb25maWd1cmUoJ2d4LlRDb21ib2JveCcsCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgZmllbGRiYWNrZ3JvdW5kPXRbJ2NhbXBvJ10sIGJhY2tncm91bmQ9dFsn
:::Ym90b24nXSwKICAgICAgICAgICAgICAgICAgICAgICAgICBmb3JlZ3JvdW5kPXRb
:::J3RleHRvJ10sIGFycm93Y29sb3I9dFsndGV4dG8nXSwKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICBib3JkZXJjb2xvcj10WydjYW1wb19ib3JkZSddLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgIGxpZ2h0Y29sb3I9dFsnY2FtcG9fYm9yZGUnXSwK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICBkYXJrY29sb3I9dFsnY2FtcG9fYm9y
:::ZGUnXSwKICAgICAgICAgICAgICAgICAgICAgICAgICBpbnNlcnRjb2xvcj10Wyd0
:::ZXh0byddKQogICAgICAgICAgICBlc3QubWFwKCdneC5UQ29tYm9ib3gnLAogICAg
:::ICAgICAgICAgICAgICAgIGZpZWxkYmFja2dyb3VuZD1bKCdyZWFkb25seScsIHRb
:::J2NhbXBvJ10pXSwKICAgICAgICAgICAgICAgICAgICBmb3JlZ3JvdW5kPVsoJ3Jl
:::YWRvbmx5JywgdFsndGV4dG8nXSldKQogICAgICAgICAgICBlc3QuY29uZmlndXJl
:::KCdneC5Ib3Jpem9udGFsLlRQcm9ncmVzc2JhcicsCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgdHJvdWdoY29sb3I9dFsndHJvdWdoJ10sIGJhY2tncm91bmQ9dFsn
:::YWNlbnRvJ10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgYm9yZGVyY29sb3I9
:::dFsnZm9uZG8nXSwgbGlnaHRjb2xvcj10WydhY2VudG8nXSwKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICBkYXJrY29sb3I9dFsnYWNlbnRvJ10pCiAgICAgICAgICAg
:::IHNlbGYub3B0aW9uX2FkZCgnKlRDb21ib2JveCpMaXN0Ym94LmJhY2tncm91bmQn
:::LCB0WydjYW1wbyddKQogICAgICAgICAgICBzZWxmLm9wdGlvbl9hZGQoJypUQ29t
:::Ym9ib3gqTGlzdGJveC5mb3JlZ3JvdW5kJywgdFsndGV4dG8nXSkKICAgICAgICAg
:::ICAgc2VsZi5vcHRpb25fYWRkKCcqVENvbWJvYm94Kkxpc3Rib3guc2VsZWN0QmFj
:::a2dyb3VuZCcsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0Wydib3Rvbl9h
:::Y3QnXSkKICAgICAgICAgICAgc2VsZi5vcHRpb25fYWRkKCcqVENvbWJvYm94Kkxp
:::c3Rib3guc2VsZWN0Rm9yZWdyb3VuZCcsCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICB0Wydib3Rvbl90eHQnXSkKICAgICAgICAgICAgc2VsZi5fcmVmcmVzY2Fy
:::X3BsYWNlaG9sZGVyKCkKCiAgICAgICAgZGVmIF9yZWZyZXNjYXJfcGxhY2Vob2xk
:::ZXIoc2VsZik6CiAgICAgICAgICAgIHQgPSBURU1BU1tzZWxmLl90ZW1hX2FjdHVh
:::bF0KICAgICAgICAgICAgaWYgc2VsZi5fZW5fcGxhY2Vob2xkZXI6CiAgICAgICAg
:::ICAgICAgICBzZWxmLmVudF91cmwuY29uZmlndXJlKGZnPXRbJ3BsYWNlaG9sZGVy
:::J10pCiAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICBzZWxmLmVudF91
:::cmwuY29uZmlndXJlKGZnPXRbJ3RleHRvJ10pCgogICAgICAgICMgLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGV2ZW50b3MK
:::ICAgICAgICBkZWYgX2NvbmVjdGFyX2V2ZW50b3Moc2VsZik6CiAgICAgICAgICAg
:::IHNlbGYuY21iX3RlbWEuYmluZCgnPDxDb21ib2JveFNlbGVjdGVkPj4nLCBzZWxm
:::Ll9vbl90ZW1hKQogICAgICAgICAgICBzZWxmLmNtYl9mb3JtYXRvLmJpbmQoJzw8
:::Q29tYm9ib3hTZWxlY3RlZD4+Jywgc2VsZi5fb25fZm9ybWF0bykKICAgICAgICAg
:::ICAgc2VsZi5jbWJfY2FsaWRhZC5iaW5kKCc8PENvbWJvYm94U2VsZWN0ZWQ+Pics
:::IGxhbWJkYSBlOiBzZWxmLl9ndWFyZGFyKCkpCiAgICAgICAgICAgIHNlbGYuY2hr
:::X2VtYmViZXIuY29uZmlndXJlKGNvbW1hbmQ9c2VsZi5fZ3VhcmRhcikKICAgICAg
:::ICAgICAgc2VsZi5lbnRfdXJsLmJpbmQoJzxGb2N1c0luPicsIHNlbGYuX29uX2Zv
:::Y3VzX3VybF9pbikKICAgICAgICAgICAgc2VsZi5lbnRfdXJsLmJpbmQoJzxGb2N1
:::c091dD4nLCBzZWxmLl9vbl9mb2N1c191cmxfb3V0KQogICAgICAgICAgICBzZWxm
:::LmVudF91cmwuYmluZCgnPFJldHVybj4nLCBsYW1iZGEgZTogc2VsZi5fYWNjaW9u
:::X2Rlc2NhcmdhcigpKQogICAgICAgICAgICBzZWxmLmVudF9jYXJwZXRhLmJpbmQo
:::JzxGb2N1c091dD4nLCBzZWxmLl9vbl9jYXJwZXRhX2VzY3JpdGEpCiAgICAgICAg
:::ICAgIHNlbGYucHJvdG9jb2woJ1dNX0RFTEVURV9XSU5ET1cnLCBzZWxmLl9hbF9j
:::ZXJyYXIpCiAgICAgICAgICAgIHNlbGYuYmluZCgnPENvbnRyb2wtdT4nLCBsYW1i
:::ZGEgZTogc2VsZi5fYWNjaW9uX2FjdHVhbGl6YXIoKSkKICAgICAgICAgICAgc2Vs
:::Zi5iaW5kKCc8Q29udHJvbC1sPicsIGxhbWJkYSBlOiBzZWxmLl9saW1waWFyX2xv
:::ZygpKQogICAgICAgICAgICBzZWxmLmJpbmQoJzxDb250cm9sLVU+JywgbGFtYmRh
:::IGU6IHNlbGYuX2FjY2lvbl9hY3R1YWxpemFyKCkpCgogICAgICAgIGRlZiBfb25f
:::Zm9jdXNfdXJsX2luKHNlbGYsIF9lPU5vbmUpOgogICAgICAgICAgICBpZiBzZWxm
:::Ll9lbl9wbGFjZWhvbGRlcjoKICAgICAgICAgICAgICAgIHNlbGYuZW50X3VybC5k
:::ZWxldGUoMCwgJ2VuZCcpCiAgICAgICAgICAgICAgICBzZWxmLl9lbl9wbGFjZWhv
:::bGRlciA9IEZhbHNlCiAgICAgICAgICAgICAgICBzZWxmLl9yZWZyZXNjYXJfcGxh
:::Y2Vob2xkZXIoKQoKICAgICAgICBkZWYgX29uX2ZvY3VzX3VybF9vdXQoc2VsZiwg
:::X2U9Tm9uZSk6CiAgICAgICAgICAgIGlmIG5vdCBzZWxmLmVudF91cmwuZ2V0KCk6
:::CiAgICAgICAgICAgICAgICBzZWxmLl9lbl9wbGFjZWhvbGRlciA9IFRydWUKICAg
:::ICAgICAgICAgICAgIHNlbGYuX3BvbmVyX3BsYWNlaG9sZGVyKCkKICAgICAgICAg
:::ICAgICAgIHNlbGYuX3JlZnJlc2Nhcl9wbGFjZWhvbGRlcigpCgogICAgICAgIGRl
:::ZiBfb25fdGVtYShzZWxmLCBfZT1Ob25lKToKICAgICAgICAgICAgc2VsZi5fdGVt
:::YV9hY3R1YWwgPSBzZWxmLmNtYl90ZW1hLmdldCgpCiAgICAgICAgICAgIEFKVVNU
:::RVNbJ3RlbWEnXSA9IHNlbGYuX3RlbWFfYWN0dWFsCiAgICAgICAgICAgIGd1YXJk
:::YXJfYWp1c3RlcygpCiAgICAgICAgICAgIHNlbGYuX2FwbGljYXJfdGVtYSgpCgog
:::ICAgICAgIGRlZiBfb25fZm9ybWF0byhzZWxmLCBfZT1Ob25lKToKICAgICAgICAg
:::ICAgZm10ID0gc2VsZi5fZm10X2FjdHVhbCgpCiAgICAgICAgICAgIHNlbGYuX3Jl
:::Y2FyZ2FyX2NhbGlkYWRlcyhmbXQpCiAgICAgICAgICAgIHNlbGYuX2d1YXJkYXIo
:::KQogICAgICAgICAgICBzZWxmLmxibF9lc3RpbWFjaW9uLmNvbmZpZ3VyZSgKICAg
:::ICAgICAgICAgICAgIHRleHQ9J0ludHJvZHVjZSB1bmEgVVJMIHkgcHVsc2EgRXN0
:::aW1hci4nLAogICAgICAgICAgICAgICAgZmc9VEVNQVNbc2VsZi5fdGVtYV9hY3R1
:::YWxdWyd0ZXh0byddKQoKICAgICAgICBkZWYgX2ZtdF9hY3R1YWwoc2VsZik6CiAg
:::ICAgICAgICAgIHRleHRvID0gc2VsZi5jbWJfZm9ybWF0by5nZXQoKQogICAgICAg
:::ICAgICBmb3IgY2xhdmUsIGYgaW4gRk9STUFUT1MuaXRlbXMoKToKICAgICAgICAg
:::ICAgICAgIGlmIGZbJ3RleHRvJ10gPT0gdGV4dG86CiAgICAgICAgICAgICAgICAg
:::ICAgcmV0dXJuIGNsYXZlCiAgICAgICAgICAgIHJldHVybiAnQUFDJwoKICAgICAg
:::ICBkZWYgX3JlY2FyZ2FyX2NhbGlkYWRlcyhzZWxmLCBjbGF2ZV9mbXQsIGNhbGlk
:::YWRfcHJldmlhPU5vbmUpOgogICAgICAgICAgICBmID0gRk9STUFUT1NbY2xhdmVf
:::Zm10XQogICAgICAgICAgICBzZWxmLmNtYl9jYWxpZGFkWyd2YWx1ZXMnXSA9IGZb
:::J2NhbGlkYWRlcyddCiAgICAgICAgICAgIGlmIGNhbGlkYWRfcHJldmlhIGFuZCBj
:::YWxpZGFkX3ByZXZpYSBpbiBmWydjYWxpZGFkZXMnXToKICAgICAgICAgICAgICAg
:::IHNlbGYuY21iX2NhbGlkYWQuc2V0KGNhbGlkYWRfcHJldmlhKQogICAgICAgICAg
:::ICBlbHNlOgogICAgICAgICAgICAgICAgc2VsZi5jbWJfY2FsaWRhZC5zZXQoZlsn
:::ZGVmZWN0byddKQogICAgICAgICAgICBBSlVTVEVTWydmb3JtYXRvJ10gPSBjbGF2
:::ZV9mbXQKICAgICAgICAgICAgQUpVU1RFU1snY2FsaWRhZCddID0gc2VsZi5jbWJf
:::Y2FsaWRhZC5nZXQoKQoKICAgICAgICBkZWYgX2d1YXJkYXIoc2VsZik6CiAgICAg
:::ICAgICAgIEFKVVNURVNbJ2Zvcm1hdG8nXSA9IHNlbGYuX2ZtdF9hY3R1YWwoKQog
:::ICAgICAgICAgICBBSlVTVEVTWydjYWxpZGFkJ10gPSBzZWxmLmNtYl9jYWxpZGFk
:::LmdldCgpCiAgICAgICAgICAgIEFKVVNURVNbJ2VtYmViZXInXSA9IGJvb2woc2Vs
:::Zi52YXJfZW1iZWJlci5nZXQoKSkKICAgICAgICAgICAgQUpVU1RFU1snZGVzdGlu
:::byddID0gc2VsZi5lbnRfY2FycGV0YS5nZXQoKS5zdHJpcCgpCiAgICAgICAgICAg
:::IHZhbCA9IHNlbGYuY21iX2Nvb2tpZXMuZ2V0KCkKICAgICAgICAgICAgQUpVU1RF
:::U1snY29va2llcyddID0gKCcnIGlmIHZhbC5zdGFydHN3aXRoKCdBdXRvbcOhdGlj
:::bycpIGVsc2UKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHZhbC5y
:::ZXBsYWNlKCdVc2FyIGNvb2tpZXMgZGUgJywgJycpCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAuc3RyaXAoKS5sb3dlcigpKQogICAgICAgICAgICBn
:::dWFyZGFyX2FqdXN0ZXMoKQoKICAgICAgICBkZWYgX29uX2NhcnBldGFfZXNjcml0
:::YShzZWxmLCBfZT1Ob25lKToKICAgICAgICAgICAgcCA9IFBhdGgob3MucGF0aC5l
:::eHBhbmR2YXJzKAogICAgICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5nZXQo
:::KS5zdHJpcCgpLnN0cmlwKCciJykpKQogICAgICAgICAgICB0cnk6CiAgICAgICAg
:::ICAgICAgICBwLm1rZGlyKHBhcmVudHM9VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAg
:::ICAgICAgICAgICAgIEFKVVNURVNbJ2Rlc3Rpbm8nXSA9IHN0cihwKQogICAgICAg
:::ICAgICAgICAgZ3VhcmRhcl9hanVzdGVzKCkKICAgICAgICAgICAgZXhjZXB0IE9T
:::RXJyb3IgYXMgZToKICAgICAgICAgICAgICAgIHNlbGYuX2xvZyhmJ05vIHNlIHB1
:::ZG8gdXNhciBlc2EgY2FycGV0YToge2V9JywgJ2Vycm9yJykKCiAgICAgICAgZGVm
:::IF9jYW1iaWFyX2NhcnBldGEoc2VsZik6CiAgICAgICAgICAgIGFjdHVhbCA9IHNl
:::bGYuZW50X2NhcnBldGEuZ2V0KCkuc3RyaXAoKSBvciBBSlVTVEVTWydkZXN0aW5v
:::J10KICAgICAgICAgICAgbnVldmEgPSBmaWxlZGlhbG9nLmFza2RpcmVjdG9yeSgK
:::ICAgICAgICAgICAgICAgIHRpdGxlPSdFbGlnZSBsYSBjYXJwZXRhIGRvbmRlIGd1
:::YXJkYXIgbGFzIGRlc2NhcmdhcycsCiAgICAgICAgICAgICAgICBpbml0aWFsZGly
:::PWFjdHVhbCBpZiBvcy5wYXRoLmlzZGlyKGFjdHVhbCkgZWxzZSBzdHIoUGF0aC5o
:::b21lKCkpKQogICAgICAgICAgICBpZiBub3QgbnVldmE6CiAgICAgICAgICAgICAg
:::ICByZXR1cm4KICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgUGF0aChu
:::dWV2YSkubWtkaXIocGFyZW50cz1UcnVlLCBleGlzdF9vaz1UcnVlKQogICAgICAg
:::ICAgICBleGNlcHQgT1NFcnJvciBhcyBlOgogICAgICAgICAgICAgICAgbWVzc2Fn
:::ZWJveC5zaG93ZXJyb3IoJ0NhcnBldGEgbm8gdsOhbGlkYScsIHN0cihlKSkKICAg
:::ICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICBzZWxmLmVudF9jYXJwZXRh
:::LmRlbGV0ZSgwLCAnZW5kJykKICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5p
:::bnNlcnQoMCwgbnVldmEpCiAgICAgICAgICAgIEFKVVNURVNbJ2Rlc3Rpbm8nXSA9
:::IG51ZXZhCiAgICAgICAgICAgIGd1YXJkYXJfYWp1c3RlcygpCiAgICAgICAgICAg
:::IHNlbGYuX2xvZygnQ2FycGV0YSBkZSBndWFyZGFkbzogJyArIG51ZXZhLCAnZ3Jp
:::cycpCgogICAgICAgIGRlZiBfYWJyaXJfZGVzdGlubyhzZWxmKToKICAgICAgICAg
:::ICAgcCA9IFBhdGgob3MucGF0aC5leHBhbmR2YXJzKAogICAgICAgICAgICAgICAg
:::c2VsZi5lbnRfY2FycGV0YS5nZXQoKS5zdHJpcCgpLnN0cmlwKCciJykpKQogICAg
:::ICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBwLm1rZGlyKHBhcmVudHM9VHJ1
:::ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgICAgICAgICAgZXhjZXB0IE9TRXJyb3I6CiAg
:::ICAgICAgICAgICAgICBwYXNzCiAgICAgICAgICAgIGFicmlyX2NhcnBldGEocCkK
:::CiAgICAgICAgZGVmIF9hbF9jZXJyYXIoc2VsZik6CiAgICAgICAgICAgIGlmIHNl
:::bGYuX29jdXBhZG8gYW5kIG5vdCBtZXNzYWdlYm94LmFza29rY2FuY2VsKAogICAg
:::ICAgICAgICAgICAgICAgICdTYWxpcicsICdIYXkgdW5hIHRhcmVhIGVuIGN1cnNv
:::LiAnCiAgICAgICAgICAgICAgICAgICAgJ8K/U2VndXJvIHF1ZSBxdWllcmVzIHNh
:::bGlyPycpOgogICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgIHNlbGYu
:::ZGVzdHJveSgpCgogICAgICAgICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tIHJlZ2lzdHJvIChsb2cpCiAgICAgICAgZGVm
:::IF9sb2coc2VsZiwgbXNnLCB0YWc9J2luZm8nKToKICAgICAgICAgICAgc2VsZi50
:::eHRfbG9nLmNvbmZpZ3VyZShzdGF0ZT0nbm9ybWFsJykKICAgICAgICAgICAgbl9s
:::aW5lYXMgPSBpbnQoc2VsZi50eHRfbG9nLmluZGV4KCdlbmQtMWMnKS5zcGxpdCgn
:::LicpWzBdKQogICAgICAgICAgICBpZiBuX2xpbmVhcyA+IDkwMDoKICAgICAgICAg
:::ICAgICAgIHNlbGYudHh0X2xvZy5kZWxldGUoJzEuMCcsICcyMDAuMCcpCiAgICAg
:::ICAgICAgIHNlbGYudHh0X2xvZy5pbnNlcnQoJ2VuZCcsIHN0cihtc2cpICsgJ1xu
:::JywgdGFnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuc2VlKCdlbmQnKQogICAg
:::ICAgICAgICBzZWxmLnR4dF9sb2cuY29uZmlndXJlKHN0YXRlPSdkaXNhYmxlZCcp
:::CgogICAgICAgIGRlZiBfbGltcGlhcl9sb2coc2VsZik6CiAgICAgICAgICAgIHNl
:::bGYudHh0X2xvZy5jb25maWd1cmUoc3RhdGU9J25vcm1hbCcpCiAgICAgICAgICAg
:::IHNlbGYudHh0X2xvZy5kZWxldGUoJzEuMCcsICdlbmQnKQogICAgICAgICAgICBz
:::ZWxmLnR4dF9sb2cuY29uZmlndXJlKHN0YXRlPSdkaXNhYmxlZCcpCgogICAgICAg
:::IGRlZiBfYm9tYmVhcl9jb2xhKHNlbGYpOgogICAgICAgICAgICB0cnk6CiAgICAg
:::ICAgICAgICAgICB3aGlsZSBUcnVlOgogICAgICAgICAgICAgICAgICAgIGV2ID0g
:::c2VsZi5jb2xhLmdldF9ub3dhaXQoKQogICAgICAgICAgICAgICAgICAgIHRpcG8g
:::PSBldlswXQogICAgICAgICAgICAgICAgICAgIGlmIHRpcG8gPT0gJ2xvZyc6CiAg
:::ICAgICAgICAgICAgICAgICAgICAgIHNlbGYuX2xvZyhldlsxXSwgZXZbMl0pCiAg
:::ICAgICAgICAgICAgICAgICAgZWxpZiB0aXBvID09ICdwcm9nJzoKICAgICAgICAg
:::ICAgICAgICAgICAgICAgcGN0LCB0ZXh0byA9IGV2WzFdLCBldlsyXQogICAgICAg
:::ICAgICAgICAgICAgICAgICBpZiBwY3QgaXMgTm9uZToKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIHNlbGYuYmFycmEuc3RvcCgpCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICBzZWxmLmJhcnJhLmNvbmZpZ3VyZShtb2RlPSdpbmRldGVybWlu
:::YXRlJykKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYmFycmEuc3Rh
:::cnQoNjApCiAgICAgICAgICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICBzZWxmLmJhcnJhLnN0b3AoKQogICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgc2VsZi5iYXJyYS5jb25maWd1cmUobW9kZT0nZGV0ZXJt
:::aW5hdGUnKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5iYXJyYS5j
:::b25maWd1cmUodmFsdWU9bWF4KDAsIG1pbigxMDAsIHBjdCkpKQogICAgICAgICAg
:::ICAgICAgICAgICAgICBzZWxmLmxibF9lc3RhZG8uY29uZmlndXJlKHRleHQ9dGV4
:::dG8pCiAgICAgICAgICAgICAgICAgICAgZWxpZiB0aXBvID09ICdlc3RpbWFjaW9u
:::JzoKICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5sYmxfZXN0aW1hY2lvbi5j
:::b25maWd1cmUoCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0ZXh0PWV2WzFd
:::LCBmZz1URU1BU1tzZWxmLl90ZW1hX2FjdHVhbF1bJ2FjZW50byddKQogICAgICAg
:::ICAgICAgICAgICAgIGVsaWYgdGlwbyA9PSAncHJlZ3VudGFyJzoKICAgICAgICAg
:::ICAgICAgICAgICAgICAgIyB2Mi4xNDogZWwgaGlsbyBkZSBkZXNjYXJnYSBwaWRl
:::IHVuYSBkZWNpc2lvbiBhbAogICAgICAgICAgICAgICAgICAgICAgICAjIHVzdWFy
:::aW8gKHJlaW50ZW50YXIgY29uIGNhbGlkYWQgbWFzIGJhamEpLiBMYQogICAgICAg
:::ICAgICAgICAgICAgICAgICAjIHJlc3B1ZXN0YSB2aWFqYSBwb3IgbGEgY29sYSBx
:::dWUgdHJhZSBlbCBldmVudG8uCiAgICAgICAgICAgICAgICAgICAgICAgIF8sIHRp
:::dHVsbywgdGV4dG8sIHJlc3AgPSBldgogICAgICAgICAgICAgICAgICAgICAgICB0
:::cnk6CiAgICAgICAgICAgICAgICAgICAgICAgICAgICByID0gbWVzc2FnZWJveC5h
:::c2t5ZXNubyh0aXR1bG8sIHRleHRvKQogICAgICAgICAgICAgICAgICAgICAgICBl
:::eGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICAgICAgICAgICAgICAgICAgciA9
:::IEZhbHNlCiAgICAgICAgICAgICAgICAgICAgICAgIHRyeToKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgIHJlc3AucHV0X25vd2FpdChib29sKHIpKQogICAgICAg
:::ICAgICAgICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgcGFzcwogICAgICAgICAgICAgICAgICAgIGVsaWYgdGlw
:::byA9PSAnZmluJzoKICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5fZmluX3Rh
:::cmVhKGV2WzFdLCBldlsyXSwgZXZbM10gaWYgbGVuKGV2KSA+IDMgZWxzZSAnJykK
:::ICAgICAgICAgICAgZXhjZXB0IHF1ZXVlLkVtcHR5OgogICAgICAgICAgICAgICAg
:::cGFzcwogICAgICAgICAgICBzZWxmLmFmdGVyKDgwLCBzZWxmLl9ib21iZWFyX2Nv
:::bGEpCgogICAgICAgICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tIHRhcmVhcwogICAgICAgIGRlZiBfaGFiaWxpdGFyX2Fj
:::Y2lvbmVzKHNlbGYsIG9uKToKICAgICAgICAgICAgZXN0YWRvID0gJ25vcm1hbCcg
:::aWYgb24gZWxzZSAnZGlzYWJsZWQnCiAgICAgICAgICAgIGZvciBiIGluIChzZWxm
:::LmJ0bl9kZXNjYXJnYXIsIHNlbGYuYnRuX2NvbXByb2JhciwKICAgICAgICAgICAg
:::ICAgICAgICAgIHNlbGYuYnRuX2VzdGltYXIsIHNlbGYuYnRuX2NhbWJpYXIsIHNl
:::bGYuYnRuX2FicmlyLAogICAgICAgICAgICAgICAgICAgICAgc2VsZi5idG5fcGVn
:::YXIsIHNlbGYuYnRuX3gpOgogICAgICAgICAgICAgICAgYi5jb25maWd1cmUoc3Rh
:::dGU9ZXN0YWRvLCBjdXJzb3I9J2hhbmQyJyBpZiBvbiBlbHNlICdhcnJvdycpCgog
:::ICAgICAgIGRlZiBfaW5pY2lhcihzZWxmLCBvYmpldGl2bywgY2ZnLCB0ZXh0byk6
:::CiAgICAgICAgICAgIGlmIHNlbGYuX29jdXBhZG86CiAgICAgICAgICAgICAgICBz
:::ZWxmLl9sb2coJ1lhIGhheSB1bmEgdGFyZWEgZW4gY3Vyc287IGVzcGVyYSBhIHF1
:::ZSB0ZXJtaW5lLicsCiAgICAgICAgICAgICAgICAgICAgICAgICAgJ2F2aXNvJykK
:::ICAgICAgICAgICAgICAgIHJldHVybiBGYWxzZQogICAgICAgICAgICBzZWxmLl9v
:::Y3VwYWRvID0gVHJ1ZQogICAgICAgICAgICBzZWxmLl9oYWJpbGl0YXJfYWNjaW9u
:::ZXMoRmFsc2UpCiAgICAgICAgICAgIHNlbGYubGJsX2VzdGFkby5jb25maWd1cmUo
:::dGV4dD10ZXh0bykKICAgICAgICAgICAgdGhyZWFkaW5nLlRocmVhZCh0YXJnZXQ9
:::b2JqZXRpdm8sIGFyZ3M9KGNmZywpLCBkYWVtb249VHJ1ZSkuc3RhcnQoKQogICAg
:::ICAgICAgICByZXR1cm4gVHJ1ZQoKICAgICAgICBkZWYgX2Zpbl90YXJlYShzZWxm
:::LCB0aXBvLCBvaywgbWVuc2FqZT0nJyk6CiAgICAgICAgICAgIHNlbGYuX29jdXBh
:::ZG8gPSBGYWxzZQogICAgICAgICAgICBzZWxmLl9oYWJpbGl0YXJfYWNjaW9uZXMo
:::VHJ1ZSkKICAgICAgICAgICAgc2VsZi5iYXJyYS5zdG9wKCkKICAgICAgICAgICAg
:::c2VsZi5iYXJyYS5jb25maWd1cmUobW9kZT0nZGV0ZXJtaW5hdGUnKQogICAgICAg
:::ICAgICBzZWxmLmJhcnJhLmNvbmZpZ3VyZSh2YWx1ZT0wKQogICAgICAgICAgICBp
:::ZiB0aXBvID09ICdkZXNjYXJnYScgYW5kIG9rOgogICAgICAgICAgICAgICAgc2Vs
:::Zi5sYmxfZXN0YWRvLmNvbmZpZ3VyZSh0ZXh0PSdMaXN0by4nKQogICAgICAgICAg
:::ICAgICAgIyBMYSBkZXNjYXJnYSBmdWUgYmllbjogc2UgbGltcGlhIGxhIFVSTCBw
:::YXJhIGxhIHNpZ3VpZW50ZS4KICAgICAgICAgICAgICAgIHNlbGYuX3Jlc2V0X3Vy
:::bCgpCiAgICAgICAgICAgIGVsaWYgbm90IG9rOgogICAgICAgICAgICAgICAgc2Vs
:::Zi5sYmxfZXN0YWRvLmNvbmZpZ3VyZSh0ZXh0PSdUZXJtaW5hZG8gY29uIGVycm9y
:::ZXMuJykKICAgICAgICAgICAgICAgIGlmIHRpcG8gPT0gJ2Rlc2NhcmdhJzoKICAg
:::ICAgICAgICAgICAgICAgICBtZXNzYWdlYm94LnNob3dlcnJvcigKICAgICAgICAg
:::ICAgICAgICAgICAgICAgJ0Vycm9yJywgbWVuc2FqZSBvciAnTm8gc2UgcHVkbyBj
:::b21wbGV0YXIgbGEgdGFyZWEuICcKICAgICAgICAgICAgICAgICAgICAgICAgJ1Jl
:::dmlzYSBlbCByZWdpc3RybyBwYXJhIG3DoXMgZGV0YWxsZXMuJykKCiAgICAgICAg
:::ZGVmIF91cmxfdmFsaWRhKHNlbGYpOgogICAgICAgICAgICBpZiBzZWxmLl9lbl9w
:::bGFjZWhvbGRlcjoKICAgICAgICAgICAgICAgIHNlbGYuX2xvZygnUHJpbWVybyBw
:::ZWdhIGxhIFVSTCBkZWwgdmlkZW8gZGUgWW91VHViZS4nLCAnYXZpc28nKQogICAg
:::ICAgICAgICAgICAgcmV0dXJuIE5vbmUKICAgICAgICAgICAgdSA9IHNlbGYuZW50
:::X3VybC5nZXQoKS5zdHJpcCgpLnN0cmlwKCciJykuc3RyaXAoIiciKQogICAgICAg
:::ICAgICBpZiBub3QgdToKICAgICAgICAgICAgICAgIHNlbGYuX2xvZygnTGEgVVJM
:::IGVzdMOhIHZhY8OtYS4nLCAnYXZpc28nKQogICAgICAgICAgICAgICAgcmV0dXJu
:::IE5vbmUKICAgICAgICAgICAgaWYgbm90IHJlLm1hdGNoKHInXmh0dHBzPzovLycs
:::IHUsIHJlLkkpOgogICAgICAgICAgICAgICAgaWYgcmUubWF0Y2gocided3d3XC4n
:::LCB1LCByZS5JKToKICAgICAgICAgICAgICAgICAgICB1ID0gJ2h0dHBzOi8vJyAr
:::IHUKICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICAgICAgc2Vs
:::Zi5fbG9nKCdFc28gbm8gcGFyZWNlIHVuYSBVUkwgKGRlYmUgZW1wZXphciBwb3Ig
:::JwogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAnaHR0cDovLyBvIGh0dHBz
:::Oi8vKScsICdlcnJvcicpCiAgICAgICAgICAgICAgICAgICAgcmV0dXJuIE5vbmUK
:::ICAgICAgICAgICAgIyBPSk86IGFxdcOtIE5PIHNlIHF1aXRhIGxpc3Q9OyBzaSBs
:::YSBVUkwgdHJhZSB1bmEgcGxheWxpc3QsCiAgICAgICAgICAgICMgX2FjY2lvbl9k
:::ZXNjYXJnYXIgcHJlZ3VudGFyw6EgcXXDqSBoYWNlciBjb24gZWxsYS4KICAgICAg
:::ICAgICAgcmV0dXJuIHUKCiAgICAgICAgZGVmIF9hY2Npb25fZXN0aW1hcihzZWxm
:::KToKICAgICAgICAgICAgdXJsID0gc2VsZi5fdXJsX3ZhbGlkYSgpCiAgICAgICAg
:::ICAgIGlmIG5vdCB1cmw6CiAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAg
:::ICAgc2VsZi5fZ3VhcmRhcigpCiAgICAgICAgICAgIGNmZyA9IHsndXJsJzogdXJs
:::fQogICAgICAgICAgICBzZWxmLl9pbmljaWFyKHNlbGYuX2hpbG9fZXN0aW1hciwg
:::Y2ZnLCAnRXN0aW1hbmRvIHRhbWHDsW8uLi4nKQogICAgICAgICAgICBzZWxmLmxi
:::bF9lc3RpbWFjaW9uLmNvbmZpZ3VyZSgKICAgICAgICAgICAgICAgIHRleHQ9J0Nh
:::bGN1bGFuZG8uLi4nLCBmZz1URU1BU1tzZWxmLl90ZW1hX2FjdHVhbF1bJ3RleHRv
:::MiddKQoKICAgICAgICBkZWYgX2FjY2lvbl9kZXNjYXJnYXIoc2VsZik6CiAgICAg
:::ICAgICAgIHVybCA9IHNlbGYuX3VybF92YWxpZGEoKQogICAgICAgICAgICBpZiBu
:::b3QgdXJsOgogICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgIHNlbGYu
:::X2d1YXJkYXIoKQogICAgICAgICAgICBwbGF5bGlzdCA9IEZhbHNlCiAgICAgICAg
:::ICAgIGlmIGVzX3VybF9wbGF5bGlzdCh1cmwpOgogICAgICAgICAgICAgICAgciA9
:::IG1lc3NhZ2Vib3guYXNreWVzbm9jYW5jZWwoCiAgICAgICAgICAgICAgICAgICAg
:::J011c2lrQUxBTiDigJQgbGlzdGEgZGUgcmVwcm9kdWNjacOzbicsCiAgICAgICAg
:::ICAgICAgICAgICAgJ0VzdGEgVVJMIHBlcnRlbmVjZSBhIHVuYSBsaXN0YSBkZSBy
:::ZXByb2R1Y2Npw7NuLlxuXG4nCiAgICAgICAgICAgICAgICAgICAgJyAgU8ONICDi
:::hpIgIGRlc2NhcmdhciBsYSBwbGF5bGlzdCBjb21wbGV0YVxuJwogICAgICAgICAg
:::ICAgICAgICAgICcgICAgICAgICAocGF1c2EgZGUgMiBzIGVudHJlIGNhbmNpb25l
:::cylcbicKICAgICAgICAgICAgICAgICAgICAnICBOTyAg4oaSICBkZXNjYXJnYXIg
:::c29sbyBlc3RhIGNhbmNpw7NuXG4nCiAgICAgICAgICAgICAgICAgICAgJyAgQ2Fu
:::Y2VsYXIgIOKGkiAgbm8gZGVzY2FyZ2FyIG5hZGEnKQogICAgICAgICAgICAgICAg
:::aWYgciBpcyBOb25lOgogICAgICAgICAgICAgICAgICAgIHNlbGYuX2xvZygnRGVz
:::Y2FyZ2EgY2FuY2VsYWRhLicsICdncmlzJykKICAgICAgICAgICAgICAgICAgICBy
:::ZXR1cm4KICAgICAgICAgICAgICAgIGlmIHI6CiAgICAgICAgICAgICAgICAgICAg
:::cGxheWxpc3QgPSBUcnVlCiAgICAgICAgICAgICAgICBlbGlmIGVzX3NvbG9fbGlz
:::dGEodXJsKToKICAgICAgICAgICAgICAgICAgICAjIEVzIHVuYSBwbGF5bGlzdCBw
:::dXJhOiBubyBoYXkgInVuYSBjYW5jacOzbiIgYWjDrQogICAgICAgICAgICAgICAg
:::ICAgIHNlbGYuX2xvZygnRXNhIFVSTCBlcyB1bmEgbGlzdGEgY29tcGxldGE7IHNl
:::IGRlc2NhcmdhcsOhICcKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2Vu
:::dGVyYS4nLCAnYXZpc28nKQogICAgICAgICAgICAgICAgICAgIHBsYXlsaXN0ID0g
:::VHJ1ZQogICAgICAgICAgICBjZmcgPSB7J3VybCc6IHVybCwgJ3BsYXlsaXN0Jzog
:::cGxheWxpc3R9CiAgICAgICAgICAgIHNlbGYuX2luaWNpYXIoc2VsZi5faGlsb19k
:::ZXNjYXJnYXIsIGNmZywgJ0Rlc2NhcmdhbmRvLi4uJykKCiAgICAgICAgZGVmIF9h
:::Y2Npb25fY29tcHJvYmFyKHNlbGYpOgogICAgICAgICAgICBzZWxmLl9ndWFyZGFy
:::KCkKICAgICAgICAgICAgc2VsZi5faW5pY2lhcihzZWxmLl9oaWxvX2NvbXByb2Jh
:::ciwge30sCiAgICAgICAgICAgICAgICAgICAgICAgICAgJ0NvbXByb2JhbmRvIGxh
:::IGNhcnBldGEuLi4nKQoKICAgICAgICBkZWYgX2FjY2lvbl9hY3R1YWxpemFyKHNl
:::bGYpOgogICAgICAgICAgICBpZiBub3QgWVRfRExQOgogICAgICAgICAgICAgICAg
:::c2VsZi5fbG9nKCd5dC1kbHAgbm8gZXN0w6EgaW5zdGFsYWRvOyBlamVjdXRhICcK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAnRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0
:::LicsICdlcnJvcicpCiAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAg
:::c2VsZi5faW5pY2lhcihzZWxmLl9oaWxvX2FjdHVhbGl6YXIsIHt9LCAnQWN0dWFs
:::aXphbmRvIHl0LWRscC4uLicpCgogICAgICAgICMgLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGhpbG9zCiAgICAgICAgZGVm
:::IF9oaWxvX2VzdGltYXIoc2VsZiwgY2ZnKToKICAgICAgICAgICAgY29sYSA9IHNl
:::bGYuY29sYQoKICAgICAgICAgICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAgICAg
:::ICAgICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgICAgICAgICAg
:::dHJ5OgogICAgICAgICAgICAgICAgaWYgWVRfRExQIGlzIE5vbmU6CiAgICAgICAg
:::ICAgICAgICAgICAgbG9nKCd5dC1kbHAgbm8gZXN0w6EgaW5zdGFsYWRvLiBFamVj
:::dXRhICcKICAgICAgICAgICAgICAgICAgICAgICAgJ0Rlc2NhcmdhZG9yTXVzaWNh
:::LmJhdCBwYXJhIGluc3RhbGFybG8uJywgJ2Vycm9yJykKICAgICAgICAgICAgICAg
:::ICAgICBjb2xhLnB1dCgoJ2VzdGltYWNpb24nLCAneXQtZGxwIG5vIGRpc3Bvbmli
:::bGUnKSkKICAgICAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgICAg
:::IGxvZygnT2J0ZW5pZW5kbyBpbmZvcm1hY2nDs24gZGVsIHZpZGVvLi4uJywgJ2dy
:::aXMnKQogICAgICAgICAgICAgICAgbyA9IHsncXVpZXQnOiBUcnVlLCAnbm9fd2Fy
:::bmluZ3MnOiBUcnVlLCAnbm9wbGF5bGlzdCc6IFRydWUsCiAgICAgICAgICAgICAg
:::ICAgICAgICdzb2NrZXRfdGltZW91dCc6IDMwLCAnbG9nZ2VyJzogUkVHSVNUUk99
:::CiAgICAgICAgICAgICAgICBfYW50aV9ib3QobykKICAgICAgICAgICAgICAgIGlm
:::IGVzX3VybF9wbGF5bGlzdChjZmdbJ3VybCddKToKICAgICAgICAgICAgICAgICAg
:::ICBsb2coJyhsYSBVUkwgY29udGllbmUgdW5hIHBsYXlsaXN0OiBsYSBlc3RpbWFj
:::acOzbiBlcyAnCiAgICAgICAgICAgICAgICAgICAgICAgICdzb2xvIGRlbCB2aWRl
:::byBwZWdhZG8pJywgJ2dyaXMnKQogICAgICAgICAgICAgICAgd2l0aCBZVF9ETFAu
:::WW91dHViZURMKG8pIGFzIHlkbDoKICAgICAgICAgICAgICAgICAgICBpbmZvID0g
:::eWRsLmV4dHJhY3RfaW5mbyhjZmdbJ3VybCddLCBkb3dubG9hZD1GYWxzZSkKICAg
:::ICAgICAgICAgICAgIGR1ciA9IGluZm8uZ2V0KCdkdXJhdGlvbicpCiAgICAgICAg
:::ICAgICAgICBpZiBub3QgZHVyOgogICAgICAgICAgICAgICAgICAgIGxvZygnTm8g
:::c2UgcHVkbyBvYnRlbmVyIGxhIGR1cmFjacOzbiBkZWwgdmlkZW8uJywgJ2Vycm9y
:::JykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2VzdGltYWNpb24nLCAn
:::U2luIGRhdG9zIHBhcmEgZXN0aW1hcicpKQogICAgICAgICAgICAgICAgICAgIHJl
:::dHVybgogICAgICAgICAgICAgICAgY2xhdmUgPSBzZWxmLl9mbXRfYWN0dWFsX3Nv
:::bG8oQUpVU1RFUy5nZXQoJ2Zvcm1hdG8nLCAnQUFDJykpCiAgICAgICAgICAgICAg
:::ICB0YW0gPSBlc3RpbWFyX2J5dGVzKGR1ciwgY2xhdmUsIEFKVVNURVMuZ2V0KCdj
:::YWxpZGFkJyksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGJv
:::b2woQUpVU1RFUy5nZXQoJ2VtYmViZXInLCBUcnVlKSkpCiAgICAgICAgICAgICAg
:::ICB0aXR1bG8gPSBzdHIoaW5mby5nZXQoJ3RpdGxlJykgb3IgJycpWzo3MF0KICAg
:::ICAgICAgICAgICAgIGlmIHRpdHVsbzoKICAgICAgICAgICAgICAgICAgICBsb2co
:::J+KZqiAnICsgdGl0dWxvLCAndGl0dWxvJykKICAgICAgICAgICAgICAgIHRleHRv
:::ID0gKGYnfnt0YW0gLyAxMDQ4NTc2Oi4xZn0gTUIgwrcgJwogICAgICAgICAgICAg
:::ICAgICAgICAgICAgZidkdXJhY2nDs24ge2ZtdF90aWVtKGR1cil9IMK3ICcKICAg
:::ICAgICAgICAgICAgICAgICAgICAgIGYne2NsYXZlfSB7QUpVU1RFUy5nZXQoImNh
:::bGlkYWQiLCAiIil9Jy5yc3RyaXAoKSkKICAgICAgICAgICAgICAgIGNvbGEucHV0
:::KCgnZXN0aW1hY2lvbicsIHRleHRvKSkKICAgICAgICAgICAgICAgIGxvZygnRXN0
:::aW1hY2nDs246ICcgKyB0ZXh0bywgJ29rJykKICAgICAgICAgICAgICAgIGxvZygn
:::RWwgdGFtYcOxbyByZWFsIHB1ZWRlIHZhcmlhciBhbGdvIHNlZ8O6biBsYSBmdWVu
:::dGUuJywKICAgICAgICAgICAgICAgICAgICAnZ3JpcycpCiAgICAgICAgICAgIGV4
:::Y2VwdCBFeGNlcHRpb24gYXMgZToKICAgICAgICAgICAgICAgIGxvZyhmJ05vIHNl
:::IHB1ZG8gZXN0aW1hcjoge3NlbGYuX21zZ19lcnJvcihlKX0nLCAnZXJyb3InKQog
:::ICAgICAgICAgICAgICAgY29sYS5wdXQoKCdlc3RpbWFjaW9uJywgJ05vIHNlIHB1
:::ZG8gZXN0aW1hcicpKQogICAgICAgICAgICBmaW5hbGx5OgogICAgICAgICAgICAg
:::ICAgY29sYS5wdXQoKCdmaW4nLCAnZXN0aW1hY2lvbicsIFRydWUsICcnKSkKCiAg
:::ICAgICAgZGVmIF9mbXRfYWN0dWFsX3NvbG8oc2VsZiwgY2xhdmUpOgogICAgICAg
:::ICAgICByZXR1cm4gY2xhdmUgaWYgY2xhdmUgaW4gRk9STUFUT1MgZWxzZSAnQUFD
:::JwoKICAgICAgICBkZWYgX2Rlc2Nhcmdhcl91bmEoc2VsZiwgdXJsLCBjbGF2ZSwg
:::Y2FsaWRhZF9hcmcsIGVtYmViZXIsIGRlc3Rpbm8sCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgIGNvbGEpOgogICAgICAgICAgICAiIiJEZXNjYXJnYSB5IGNvbnZp
:::ZXJ0ZSBVTkEgVVJMLiBEZXZ1ZWx2ZSBlbCBQYXRoIGZpbmFsIG8gTm9uZS4iIiIK
:::ICAgICAgICAgICAgaWYgY2xhdmUgPT0gJ1dNQSc6CiAgICAgICAgICAgICAgICBy
:::ZXR1cm4gZGVzY2FyZ2FyX3dtYSh1cmwsIGNhbGlkYWRfYXJnLCBkZXN0aW5vLCBl
:::bWJlYmVyLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29s
:::YSlbMV0KICAgICAgICAgICAgaWYgY2xhdmUgPT0gJ0FWSSc6CiAgICAgICAgICAg
:::ICAgICByZXR1cm4gZGVzY2FyZ2FyX2F2aSh1cmwsIGRlc3Rpbm8sIGNvbGEpWzFd
:::CiAgICAgICAgICAgIHJldHVybiBkZXNjYXJnYXJfYXVkaW8odXJsLCBjbGF2ZSwg
:::Y2FsaWRhZF9hcmcsIGRlc3Rpbm8sIGVtYmViZXIsCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgY29sYSlbMV0KCiAgICAgICAgZGVmIF9kZXNjYXJn
:::YXJfcGxheWxpc3Qoc2VsZiwgdXJsLCBjbGF2ZSwgY2FsaWRhZF9hcmcsIGVtYmVi
:::ZXIsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGVzdGlubywgY29s
:::YSk6CiAgICAgICAgICAgICIiIkJhamEgdW5hIGxpc3RhIGVudGVyYSwgY29uIDIg
:::cyBkZSBkZXNjYW5zbyBlbnRyZSBjYW5jaW9uZXMKICAgICAgICAgICAgcGFyYSBu
:::byBzYXR1cmFyIGEgWW91VHViZS4gRGV2dWVsdmUgKGRlc2NhcmdhZGFzLCB0b3Rh
:::bCkuIiIiCiAgICAgICAgICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgogICAgICAg
:::ICAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICAgICAgICAgIGxv
:::ZygnTGV5ZW5kbyBsYSBsaXN0YSBkZSByZXByb2R1Y2Npw7NuLi4uJywgJ2dyaXMn
:::KQogICAgICAgICAgICBvID0geydxdWlldCc6IFRydWUsICdub193YXJuaW5ncyc6
:::IFRydWUsCiAgICAgICAgICAgICAgICAgJ2V4dHJhY3RfZmxhdCc6ICdpbl9wbGF5
:::bGlzdCcsICdzb2NrZXRfdGltZW91dCc6IDMwLAogICAgICAgICAgICAgICAgICds
:::b2dnZXInOiBSRUdJU1RST30KICAgICAgICAgICAgX2FudGlfYm90KG8pCiAgICAg
:::ICAgICAgIHdpdGggWVRfRExQLllvdXR1YmVETChvKSBhcyB5ZGw6CiAgICAgICAg
:::ICAgICAgICBpbmZvID0geWRsLmV4dHJhY3RfaW5mbyh1cmwsIGRvd25sb2FkPUZh
:::bHNlKQogICAgICAgICAgICBlbnRyYWRhcyA9IGxpc3QoaW5mby5nZXQoJ2VudHJp
:::ZXMnKSBvciBbXSkKICAgICAgICAgICAgaWYgbm90IGVudHJhZGFzOgogICAgICAg
:::ICAgICAgICAgbG9nKCdObyBzZSB2aW8gbmluZ3VuYSBjYW5jacOzbiBlbiBsYSBs
:::aXN0YTsgc2UgaW50ZW50YSAnCiAgICAgICAgICAgICAgICAgICAgJ2NvbW8gdmlk
:::ZW8gc3VlbHRvLicsICdhdmlzbycpCiAgICAgICAgICAgICAgICBhcmNoaXZvID0g
:::c2VsZi5fZGVzY2FyZ2FyX3VuYShzaW5fcGxheWxpc3QodXJsKVswXSwgY2xhdmUs
:::CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBj
:::YWxpZGFkX2FyZywgZW1iZWJlciwgZGVzdGlubywKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbGEpCiAgICAgICAgICAgICAg
:::ICByZXR1cm4gKDEgaWYgYXJjaGl2byBlbHNlIDApLCAxCiAgICAgICAgICAgIHRp
:::dHVsb19wbCA9IHN0cihpbmZvLmdldCgndGl0bGUnKSBvciAnbGlzdGEnKVs6NzBd
:::CiAgICAgICAgICAgIHRvdGFsID0gbGVuKGVudHJhZGFzKQogICAgICAgICAgICBs
:::b2coZidQbGF5bGlzdCDCq3t0aXR1bG9fcGx9wrsg4oCUIHt0b3RhbH0gdsOtZGVv
:::KHMpLicsICd0aXR1bG8nKQogICAgICAgICAgICBva2FzID0gMAogICAgICAgICAg
:::ICBmYWxsb3MgPSBbXQogICAgICAgICAgICBmb3IgaSwgZSBpbiBlbnVtZXJhdGUo
:::ZW50cmFkYXMpOgogICAgICAgICAgICAgICAgdSA9IHN0cihlLmdldCgnd2VicGFn
:::ZV91cmwnKSBvciBlLmdldCgndXJsJykgb3IgJycpCiAgICAgICAgICAgICAgICBp
:::ZiB1IGFuZCBub3QgdS5zdGFydHN3aXRoKCdodHRwJyk6CiAgICAgICAgICAgICAg
:::ICAgICAgdSA9ICdodHRwczovL3d3dy55b3V0dWJlLmNvbS93YXRjaD92PScgKyB1
:::CiAgICAgICAgICAgICAgICBpZiBub3QgdSBhbmQgZS5nZXQoJ2lkJyk6CiAgICAg
:::ICAgICAgICAgICAgICAgdSA9ICdodHRwczovL3d3dy55b3V0dWJlLmNvbS93YXRj
:::aD92PScgKyBzdHIoZVsnaWQnXSkKICAgICAgICAgICAgICAgIHRpdCA9IHN0cihl
:::LmdldCgndGl0bGUnKSBvciB1IG9yICc/JylbOjcwXQogICAgICAgICAgICAgICAg
:::aWYgaToKICAgICAgICAgICAgICAgICAgICB0aW1lLnNsZWVwKDIpICAgIyBkZXNj
:::YW5zbyBlbnRyZSBjYW5jaW9uZXMKICAgICAgICAgICAgICAgIGxvZyhmJ1t7aSAr
:::IDF9L3t0b3RhbH1dIOKZqiB7dGl0fScsICd0aXR1bG8nKQogICAgICAgICAgICAg
:::ICAgdHJ5OgogICAgICAgICAgICAgICAgICAgIGFyY2hpdm8gPSBzZWxmLl9kZXNj
:::YXJnYXJfdW5hKHUsIGNsYXZlLCBjYWxpZGFkX2FyZywKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBlbWJlYmVyLCBkZXN0
:::aW5vLCBjb2xhKQogICAgICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBl
:::MjoKICAgICAgICAgICAgICAgICAgICBpZiBfZXNfcmVzdHJpY2Npb25fZWRhZChz
:::dHIoZTIpKToKICAgICAgICAgICAgICAgICAgICAgICAgIyB2Mi4xNTogdmlkZW8g
:::cmVzdHJpbmdpZG8gcG9yIGVkYWQ6IG5pbmd1bmEgdsOtYQogICAgICAgICAgICAg
:::ICAgICAgICAgICAjIHNpcnZlIHNpbiBzZXNpw7NuIGFiaWVydGEuIFNlIHNhbHRh
:::IGNvbiBhdmlzbwogICAgICAgICAgICAgICAgICAgICAgICAjIGNsYXJvIHkgbGEg
:::bGlzdGEgc2lndWUgY29uIGxhcyBkZW3DoXMgY2FuY2lvbmVzLgogICAgICAgICAg
:::ICAgICAgICAgICAgICBsb2coZifinJYgW3tpICsgMX0ve3RvdGFsfV0ge3RpdH06
:::IHRpZW5lICcKICAgICAgICAgICAgICAgICAgICAgICAgICAgICdSRVNUUklDQ0nD
:::k04gREUgRURBRDsgWW91VHViZSBubyBkZWphICcKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICdiYWphcmxhIHNpbiBzZXNpw7NuIGFiaWVydGEuIEJ1c2NhIG90
:::cmEgJwogICAgICAgICAgICAgICAgICAgICAgICAgICAgJ3ZlcnNpw7NuIHNpbiBs
:::YSByZXN0cmljY2nDs24uJywgJ2Vycm9yJykKICAgICAgICAgICAgICAgICAgICAg
:::ICAgZmFsbG9zLmFwcGVuZCh0aXQgKyAnIChyZXN0cmljY2nDs24gZGUgZWRhZCkn
:::KQogICAgICAgICAgICAgICAgICAgICAgICBjb250aW51ZQogICAgICAgICAgICAg
:::ICAgICAgIGlmIF9lc19ibG9xdWVvX2JvdChzdHIoZTIpKToKICAgICAgICAgICAg
:::ICAgICAgICAgICAgIyBibG9xdWVvIGFudGktYm90OiBhYm9ydGFyIHBhcmEgcXVl
:::IGVsIHJlaW50ZW50bwogICAgICAgICAgICAgICAgICAgICAgICAjIGF1dG9tw6F0
:::aWNvIGRlIF9oaWxvX2Rlc2NhcmdhciBzZSBlbmNhcmd1ZQogICAgICAgICAgICAg
:::ICAgICAgICAgICByYWlzZQogICAgICAgICAgICAgICAgICAgIGFyY2hpdm8gPSBO
:::b25lCiAgICAgICAgICAgICAgICAgICAgbG9nKGYn4pyWIFt7aSArIDF9L3t0b3Rh
:::bH1dIEZhbGzDszoge3NlbGYuX21zZ19lcnJvcihlMil9JywKICAgICAgICAgICAg
:::ICAgICAgICAgICAgJ2Vycm9yJykKICAgICAgICAgICAgICAgIGlmIGFyY2hpdm8g
:::YW5kIFBhdGgoYXJjaGl2bykuZXhpc3RzKCk6CiAgICAgICAgICAgICAgICAgICAg
:::dHJ5OgogICAgICAgICAgICAgICAgICAgICAgICB0YW0gPSBmbXRfdGFtKFBhdGgo
:::YXJjaGl2bykuc3RhdCgpLnN0X3NpemUpCiAgICAgICAgICAgICAgICAgICAgZXhj
:::ZXB0IE9TRXJyb3I6CiAgICAgICAgICAgICAgICAgICAgICAgIHRhbSA9ICc/Jwog
:::ICAgICAgICAgICAgICAgICAgIGxvZyhmJyAgIOKclCB7UGF0aChhcmNoaXZvKS5u
:::YW1lfSAgKHt0YW19KScKICAgICAgICAgICAgICAgICAgICAgICAgZid7dGV4dG9f
:::Y2FsaWRhZChjbGF2ZSwgY2FsaWRhZF9hcmcpfScsICdvaycpCiAgICAgICAgICAg
:::ICAgICAgICAgb2thcyArPSAxCiAgICAgICAgICAgICAgICBlbHNlOgogICAgICAg
:::ICAgICAgICAgICAgIGZhbGxvcy5hcHBlbmQodGl0KQogICAgICAgICAgICBsb2co
:::ZidQbGF5bGlzdCB0ZXJtaW5hZGE6IHtva2FzfSBkZSB7dG90YWx9IGRlc2Nhcmdh
:::ZGEocykuJywKICAgICAgICAgICAgICAgICdvaycgaWYgbm90IGZhbGxvcyBlbHNl
:::ICdhdmlzbycpCiAgICAgICAgICAgIGlmIGZhbGxvczoKICAgICAgICAgICAgICAg
:::IGxvZygnU2luIGRlc2NhcmdhcjogJwogICAgICAgICAgICAgICAgICAgICsgJyDC
:::tyAnLmpvaW4oZls6NDBdIGZvciBmIGluIGZhbGxvc1s6OF0pCiAgICAgICAgICAg
:::ICAgICAgICAgKyAoJy4uLicgaWYgbGVuKGZhbGxvcykgPiA4IGVsc2UgJycpLCAn
:::Z3JpcycpCiAgICAgICAgICAgIHJldHVybiBva2FzLCB0b3RhbAoKICAgICAgICBk
:::ZWYgX2hpbG9fZGVzY2FyZ2FyKHNlbGYsIGNmZyk6CiAgICAgICAgICAgIGNvbGEg
:::PSBzZWxmLmNvbGEKCiAgICAgICAgICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgog
:::ICAgICAgICAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICAgICAg
:::ICAgIHVybCA9IGNmZ1sndXJsJ10KICAgICAgICAgICAgY2xhdmUgPSBzZWxmLl9m
:::bXRfYWN0dWFsX3NvbG8oQUpVU1RFUy5nZXQoJ2Zvcm1hdG8nLCAnQUFDJykpCiAg
:::ICAgICAgICAgIGNhbGlkYWQgPSBBSlVTVEVTLmdldCgnY2FsaWRhZCcsICcxMjhr
:::JykKICAgICAgICAgICAgZW1iZWJlciA9IGJvb2woQUpVU1RFUy5nZXQoJ2VtYmVi
:::ZXInLCBUcnVlKSkKICAgICAgICAgICAgZGVzdGlubyA9IFBhdGgob3MucGF0aC5l
:::eHBhbmR2YXJzKAogICAgICAgICAgICAgICAgc3RyKEFKVVNURVMuZ2V0KCdkZXN0
:::aW5vJywgX2Rlc3Rpbm9fcG9yX2RlZmVjdG8oKSkpKSkKICAgICAgICAgICAgdHJ5
:::OgogICAgICAgICAgICAgICAgaWYgWVRfRExQIGlzIE5vbmU6CiAgICAgICAgICAg
:::ICAgICAgICAgbG9nKCd5dC1kbHAgbm8gZXN0w6EgaW5zdGFsYWRvLiBFamVjdXRh
:::ICcKICAgICAgICAgICAgICAgICAgICAgICAgJ0Rlc2NhcmdhZG9yTXVzaWNhLmJh
:::dCBwYXJhIGluc3RhbGFybG8uJywgJ2Vycm9yJykKICAgICAgICAgICAgICAgICAg
:::ICBjb2xhLnB1dCgoJ2ZpbicsICdkZXNjYXJnYScsIEZhbHNlLAogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAneXQtZGxwIG5vIGVzdMOhIGluc3RhbGFkby4n
:::KSkKICAgICAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgICAgIGRl
:::c3Rpbm8ubWtkaXIocGFyZW50cz1UcnVlLCBleGlzdF9vaz1UcnVlKQogICAgICAg
:::ICAgICAgICAgaWYgY2xhdmUgaW4gKCdGTEFDJywgJ1dBVicpOgogICAgICAgICAg
:::ICAgICAgICAgIGNhbGlkYWRfYXJnID0gJzAnCiAgICAgICAgICAgICAgICBlbHNl
:::OgogICAgICAgICAgICAgICAgICAgIGNhbGlkYWRfYXJnID0gKHJlLnN1YihyJ1te
:::MC05XScsICcnLCBzdHIoY2FsaWRhZCkpCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgb3IgKCcxMjgnIGlmIGNsYXZlID09ICdBQUMnIGVsc2UgJzMy
:::MCcpKQogICAgICAgICAgICAgICAgaWYgY2ZnLmdldCgncGxheWxpc3QnKToKICAg
:::ICAgICAgICAgICAgICAgICBva2FzLCB0b3RhbCA9IHNlbGYuX2Rlc2Nhcmdhcl9w
:::bGF5bGlzdCgKICAgICAgICAgICAgICAgICAgICAgICAgdXJsLCBjbGF2ZSwgY2Fs
:::aWRhZF9hcmcsIGVtYmViZXIsIGRlc3Rpbm8sIGNvbGEpCiAgICAgICAgICAgICAg
:::ICAgICAgaWYgb2thcyBhbmQgb2thcyA9PSB0b3RhbDoKICAgICAgICAgICAgICAg
:::ICAgICAgICAgbG9nKGYnQ2FycGV0YToge2Rlc3Rpbm99JywgJ2dyaXMnKQogICAg
:::ICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdkZXNjYXJnYScs
:::IFRydWUsICcnKSkKICAgICAgICAgICAgICAgICAgICBlbHNlOgogICAgICAgICAg
:::ICAgICAgICAgICAgICBjb2xhLnB1dCgoCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAnZmluJywgJ2Rlc2NhcmdhJywgRmFsc2UsCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICBmJ1NlIGRlc2Nhcmdhcm9uIHtva2FzfSBkZSB7dG90YWx9IGRl
:::IGxhICcKICAgICAgICAgICAgICAgICAgICAgICAgICAgICdwbGF5bGlzdC4gTGEg
:::VVJMIG5vIHNlIGhhIGJvcnJhZG8gcG9yIHNpICcKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICdxdWllcmVzIHJlaW50ZW50YXJsby4nKSkKICAgICAgICAgICAg
:::ICAgICAgICByZXR1cm4KICAgICAgICAgICAgICAgIHVybF91bmljYSA9IHNpbl9w
:::bGF5bGlzdCh1cmwpWzBdCiAgICAgICAgICAgICAgICAjIHYyLjE1OiBlc2NhbGVy
:::YSBhdXRvbcOhdGljYSBkZSByZWludGVudG9zOiBwcmltZXJvIGxhCiAgICAgICAg
:::ICAgICAgICAjIHbDrWEgY2zDoXNpY2EgZGUgbGEgdjIuODsgc2kgWW91VHViZSBw
:::aWRlIGNvbmZpcm1hY2nDs24sCiAgICAgICAgICAgICAgICAjIGxhcyB2w61hcyBt
:::w7N2aWxlcyBkZSBsYSB2Mi45LiBMYSByZXN0cmljY2nDs24gZGUgZWRhZCBzZQog
:::ICAgICAgICAgICAgICAgIyBkZXRlY3RhIGFwYXJ0ZSAocmVpbnRlbnRhciBubyBz
:::aXJ2ZSkgY29uIHN1IGF2aXNvLgogICAgICAgICAgICAgICAgYXJjaGl2bywgY2xh
:::c2UsIG1zZ19lcnIgPSBkZXNjYXJnYV9jb25fZXNjYWxlcmEoCiAgICAgICAgICAg
:::ICAgICAgICAgc2VsZiwgdXJsX3VuaWNhLCBjbGF2ZSwgY2FsaWRhZF9hcmcsIGVt
:::YmViZXIsIGRlc3Rpbm8sCiAgICAgICAgICAgICAgICAgICAgY29sYSkKICAgICAg
:::ICAgICAgICAgIGlmIGFyY2hpdm8gYW5kIFBhdGgoYXJjaGl2bykuZXhpc3RzKCk6
:::CiAgICAgICAgICAgICAgICAgICAgYXJjaGl2byA9IFBhdGgoYXJjaGl2bykKICAg
:::ICAgICAgICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICAgICAgICAgIHRh
:::bSA9IGZtdF90YW0oYXJjaGl2by5zdGF0KCkuc3Rfc2l6ZSkKICAgICAgICAgICAg
:::ICAgICAgICBleGNlcHQgT1NFcnJvcjoKICAgICAgICAgICAgICAgICAgICAgICAg
:::dGFtID0gJz8nCiAgICAgICAgICAgICAgICAgICAgbG9nKGYn4pyUIMKhTGlzdG8h
:::ICB7YXJjaGl2by5uYW1lfSAgKHt0YW19KScKICAgICAgICAgICAgICAgICAgICAg
:::ICAgZid7dGV4dG9fY2FsaWRhZChjbGF2ZSwgY2FsaWRhZF9hcmcpfScsICdvaycp
:::CiAgICAgICAgICAgICAgICAgICAgIyB2Mi4xNDogc2kgcXVlZG8gY29uIGNhbGlk
:::YWQgbWFzIGJhamEgcXVlIGxhIHBlZGlkYSwKICAgICAgICAgICAgICAgICAgICAj
:::IHByZWd1bnRhciBzaSBzZSByZWludGVudGEgcG9yIG90cmFzIHZpYXMgKHF1ZWRh
:::cmEKICAgICAgICAgICAgICAgICAgICAjIGNvbiBsYSBtZWpvciBkZSBsYXMgZG9z
:::KSBvIHNlIGNvbnNlcnZhIGVzdGEuCiAgICAgICAgICAgICAgICAgICAgYXJjaGl2
:::byA9IHJlaW50ZW50b19jYWxpZGFkKAogICAgICAgICAgICAgICAgICAgICAgICBz
:::ZWxmLCB1cmxfdW5pY2EsIGNsYXZlLCBjYWxpZGFkX2FyZywgZW1iZWJlciwKICAg
:::ICAgICAgICAgICAgICAgICAgICAgZGVzdGlubywgYXJjaGl2bywgY29sYSkKICAg
:::ICAgICAgICAgICAgICAgICBsb2coZidDYXJwZXRhOiB7YXJjaGl2by5wYXJlbnR9
:::JywgJ2dyaXMnKQogICAgICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywg
:::J2Rlc2NhcmdhJywgVHJ1ZSwgJycpKQogICAgICAgICAgICAgICAgZWxpZiBjbGFz
:::ZSA9PSAnZWRhZCc6CiAgICAgICAgICAgICAgICAgICAgbG9nKCfinJYgTm8gc2Ug
:::cHVlZGUgZGVzY2FyZ2FyOiBlbCB2aWRlbyB0aWVuZSAnCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICdSRVNUUklDQ0nDk04gREUgRURBRC4gTm8gZXMgdW4gZmFsbG8g
:::ZGUgbGEgJwogICAgICAgICAgICAgICAgICAgICAgICAnYXBwOiBZb3VUdWJlIG5v
:::IGRlamEgYmFqYXIgZXNlIHZpZGVvIHNpbiB1bmEgJwogICAgICAgICAgICAgICAg
:::ICAgICAgICAnc2VzacOzbiBhYmllcnRhLicsICdlcnJvcicpCiAgICAgICAgICAg
:::ICAgICAgICAgbG9nKCdRdcOpIGhhY2VyOiBidXNjYSBvdHJhIHZlcnNpw7NuIGRl
:::IGxhIGNhbmNpw7NuICcKICAgICAgICAgICAgICAgICAgICAgICAgJ3NpbiByZXN0
:::cmljY2nDs24gZGUgZWRhZCAobHlyaWMgdmlkZW8sIHJhZGlvICcKICAgICAgICAg
:::ICAgICAgICAgICAgICAgJ2VkaXQsIG90cm8gY2FuYWwpIHkgZGVzY2FyZ2EgZXNh
:::LicsICdncmlzJykKICAgICAgICAgICAgICAgICAgICBsb2coJ1NpIHRpZW5lcyBz
:::ZXNpw7NuIGFiaWVydGEgZW4gdHUgbmF2ZWdhZG9yLCAnCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICdlbGlnZSDCq1VzYXIgY29va2llcyBkZSAuLi7CuyBlbiDCq1Np
:::IFlvdVR1YmUgJwogICAgICAgICAgICAgICAgICAgICAgICAnYmxvcXVlYTrCuyB5
:::IHZ1ZWx2ZSBhIGludGVudGFybG86IGNvbiB0dSBzZXNpw7NuICcKICAgICAgICAg
:::ICAgICAgICAgICAgICAgJ2FiaWVydGEgWW91VHViZSBzdWVsZSBkZWphciBkZXNj
:::YXJnYXJsby4nLAogICAgICAgICAgICAgICAgICAgICAgICAnZ3JpcycpCiAgICAg
:::ICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnZGVzY2FyZ2EnLCBGYWxz
:::ZSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ0VsIHZpZGVvIHRpZW5l
:::IHJlc3RyaWNjacOzbiBkZSBlZGFkOiBubyBzZSAnCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICdwdWVkZSBkZXNjYXJnYXIuIEJ1c2NhIG90cm8gdmlkZW8g
:::c2luIGxhICcKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ3Jlc3RyaWNj
:::acOzbi4nKSkKICAgICAgICAgICAgICAgIGVsaWYgY2xhc2UgPT0gJ2JvdCc6CiAg
:::ICAgICAgICAgICAgICAgICAgbG9nKCfinJYgWW91VHViZSBwaWRpw7MgdmVyaWZp
:::Y2FjacOzbiBwb3IgdG9kYXMgbGFzICcKICAgICAgICAgICAgICAgICAgICAgICAg
:::J3bDrWFzOiAnICsgKG1zZ19lcnIgb3IgJycpWzoyNTBdLCAnZXJyb3InKQogICAg
:::ICAgICAgICAgICAgICAgIGxvZygnU29sdWNpw7NuIGZpYWJsZTogZW4gwqtTaSBZ
:::b3VUdWJlIGJsb3F1ZWE6wrsgJwogICAgICAgICAgICAgICAgICAgICAgICAnZWxp
:::Z2UgVXNhciBjb29raWVzIGRlIEZpcmVmb3ggKG8gdHUgbmF2ZWdhZG9yKSAnCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICd5IHJlaW50ZW50YTogY29uIHR1IHNlc2nD
:::s24gYWJpZXJ0YSBZb3VUdWJlIG5vICcKICAgICAgICAgICAgICAgICAgICAgICAg
:::J3Z1ZWx2ZSBhIHBlZGlyIHZlcmlmaWNhY2nDs24uJywgJ2dyaXMnKQogICAgICAg
:::ICAgICAgICAgICAgIGxvZygnVGFtYmnDqW4gc3VlbGVuIGZ1bmNpb25hcjogZXNw
:::ZXJhciB1bm9zICcKICAgICAgICAgICAgICAgICAgICAgICAgJ21pbnV0b3MsIHB1
:::bHNhciBDdHJsK1UgKGFjdHVhbGl6YXIgeXQtZGxwKSBvICcKICAgICAgICAgICAg
:::ICAgICAgICAgICAgJ3Byb2JhciBjb24gb3RyYSByZWQgKGVsIHdpZmkgZGUgY2Fz
:::YSkuJywgJ2dyaXMnKQogICAgICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmlu
:::JywgJ2Rlc2NhcmdhJywgRmFsc2UsCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICdObyBzZSBwdWRvIGNvbXBsZXRhciBsYSBkZXNjYXJnYSAnCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICcodmVyaWZpY2FjacOzbiBkZSBZb3VUdWJl
:::KS4gUmV2aXNhIGVsICcKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ3Jl
:::Z2lzdHJvLicpKQogICAgICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAg
:::ICAgICBsb2coJ+KcliBObyBzZSBwdWRvIGRlc2NhcmdhcjogJyArIChtc2dfZXJy
:::IG9yICcnKQogICAgICAgICAgICAgICAgICAgICAgICBbOjI1MF0sICdlcnJvcicp
:::CiAgICAgICAgICAgICAgICAgICAgbG9nKCdTZSBwcm9iw7MgYXV0b23DoXRpY2Ft
:::ZW50ZSBwb3IgdG9kYXMgbGFzIHbDrWFzICcKICAgICAgICAgICAgICAgICAgICAg
:::ICAgJ2ludGVybmFzLiBDb25zZWpvczogcmV2aXNhIGxhIFVSTCB5IHR1ICcKICAg
:::ICAgICAgICAgICAgICAgICAgICAgJ2NvbmV4acOzbjsgc2kgWW91VHViZSBjYW1i
:::acOzIGFsZ28sIHB1bHNhIEN0cmwrVSAnCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICcoYWN0dWFsaXphciB5dC1kbHApIHkgcmVpbnRlbnRhLicsICdncmlzJykKICAg
:::ICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdkZXNjYXJnYScsIEZh
:::bHNlLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAnTm8gc2UgcHVkbyBj
:::b21wbGV0YXIgbGEgZGVzY2FyZ2EuIFJldmlzYSAnCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICdlbCByZWdpc3RybyBwYXJhIG3DoXMgZGV0YWxsZXMuJykp
:::CiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZToKICAgICAgICAgICAg
:::ICAgIG5vbWJyZV9leGMgPSB0eXBlKGUpLl9fbmFtZV9fCiAgICAgICAgICAgICAg
:::ICBpZiBub21icmVfZXhjID09ICdEb3dubG9hZEVycm9yJzoKICAgICAgICAgICAg
:::ICAgICAgICBsaW5lYXMgPSBbbCBmb3IgbCBpbiBzdHIoZSkuc3RyaXAoKS5zcGxp
:::dGxpbmVzKCkgaWYgbC5zdHJpcCgpXQogICAgICAgICAgICAgICAgICAgIG1zZyA9
:::IGxpbmVhc1swXVs6MzAwXSBpZiBsaW5lYXMgZWxzZSAnZXJyb3IgZGVzY29ub2Np
:::ZG8nCiAgICAgICAgICAgICAgICAgICAgaWYgX2VzX2Jsb3F1ZW9fYm90KHN0cihl
:::KSk6CiAgICAgICAgICAgICAgICAgICAgICAgIGlmIF9BTlRJX0JPVFsnY29tYm8n
:::XSA9PSAwOgogICAgICAgICAgICAgICAgICAgICAgICAgICAgbG9nKCdZb3VUdWJl
:::IGVzdMOhIHBpZGllbmRvIHZlcmlmaWNhY2nDs24gJwogICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICdhbnRpLWJvdCBwYXJhIGVzdGEgcmVkLiBSZWludGVu
:::dGFuZG8gY29uICcKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAndW5h
:::IHbDrWEgaW50ZXJuYSBhbHRlcm5hdGl2YS4uLicsICdhdmlzbycpCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICBfQU5USV9CT1RbJ2NvbWJvJ10gPSAxCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgdGltZS5zbGVlcCgzKSAgICMgcmVzcGlybyBwYXJhIGVsIDQy
:::OQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuX2hpbG9fZGVz
:::Y2FyZ2FyKGNmZykKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZXR1
:::cm4KICAgICAgICAgICAgICAgICAgICAgICAgICAgIGZpbmFsbHk6CiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgX0FOVElfQk9UWydjb21ibyddID0gMAog
:::ICAgICAgICAgICAgICAgICAgICAgICBsb2coJ+KcliBZb3VUdWJlIHNpZ3VlIHBp
:::ZGllbmRvIHZlcmlmaWNhY2nDs246ICcKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICsgbXNnLCAnZXJyb3InKQogICAgICAgICAgICAgICAgICAgICAgICBsb2co
:::J1NvbHVjacOzbiBmaWFibGU6IGVuIMKrU2kgWW91VHViZSBibG9xdWVhOsK7ICcK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICdlbGlnZSBVc2FyIGNvb2tpZXMg
:::ZGUgRmlyZWZveCAobyB0dSAnCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAn
:::bmF2ZWdhZG9yKSB5IHJlaW50ZW50YTogY29uIHR1IHNlc2nDs24gJwogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgJ2FiaWVydGEgWW91VHViZSBubyB2dWVsdmUg
:::YSBwZWRpciAnCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAndmVyaWZpY2Fj
:::acOzbi4nLCAnZ3JpcycpCiAgICAgICAgICAgICAgICAgICAgICAgIGxvZygnVGFt
:::YmnDqW4gc3VlbGVuIGZ1bmNpb25hcjogZXNwZXJhciB1bm9zICcKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICdtaW51dG9zLCBwdWxzYXIgQ3RybCtVIChhY3R1
:::YWxpemFyIHl0LWRscCkgJwogICAgICAgICAgICAgICAgICAgICAgICAgICAgJ28g
:::cHJvYmFyIGNvbiBvdHJhIHJlZCAoZWwgd2lmaSBkZSBjYXNhKS4nLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgJ2dyaXMnKQogICAgICAgICAgICAgICAgICAg
:::IGVsc2U6CiAgICAgICAgICAgICAgICAgICAgICAgIGxvZygn4pyWIE5vIHNlIHB1
:::ZG8gZGVzY2FyZ2FyOiAnICsgbXNnLCAnZXJyb3InKQogICAgICAgICAgICAgICAg
:::ICAgICAgICBsb2coJ0NvbnNlam9zOiByZXZpc2EgbGEgVVJMIHkgdHUgY29uZXhp
:::w7NuOyBzaSAnCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnWW91VHViZSBj
:::YW1iacOzIGFsZ28sIHB1bHNhIEN0cmwrVSAnCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAnKGFjdHVhbGl6YXIgeXQtZGxwKSB5IHJlaW50ZW50YS4nLCAnZ3Jp
:::cycpCiAgICAgICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgIGxv
:::ZyhmJ+KcliBFcnJvciBpbmVzcGVyYWRvICh7bm9tYnJlX2V4Y30pOiB7ZX0nLCAn
:::ZXJyb3InKQogICAgICAgICAgICAgICAgICAgIHRiID0gdHJhY2ViYWNrLmZvcm1h
:::dF9leGMobGltaXQ9MykKICAgICAgICAgICAgICAgICAgICB0cnk6CiAgICAgICAg
:::ICAgICAgICAgICAgICAgIHdpdGggb3BlbihMT0dfRVJST1JFUywgJ2EnLCBlbmNv
:::ZGluZz0ndXRmLTgnKSBhcyBmaDoKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::IGZoLndyaXRlKHRiICsgJ1xuJykKICAgICAgICAgICAgICAgICAgICBleGNlcHQg
:::RXhjZXB0aW9uOgogICAgICAgICAgICAgICAgICAgICAgICBwYXNzCiAgICAgICAg
:::ICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdkZXNjYXJnYScsIEZhbHNlLAogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICdObyBzZSBwdWRvIGNvbXBsZXRhciBsYSBk
:::ZXNjYXJnYS4gUmV2aXNhIGVsICcKICAgICAgICAgICAgICAgICAgICAgICAgICAn
:::cmVnaXN0cm8gcGFyYSBtw6FzIGRldGFsbGVzLicpKQoKICAgICAgICBkZWYgX2hp
:::bG9fY29tcHJvYmFyKHNlbGYsIGNmZyk6CiAgICAgICAgICAgIGNvbGEgPSBzZWxm
:::LmNvbGEKCiAgICAgICAgICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgogICAgICAg
:::ICAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICAgICAgICAgIGNh
:::cnBldGEgPSBQYXRoKG9zLnBhdGguZXhwYW5kdmFycygKICAgICAgICAgICAgICAg
:::IHN0cihBSlVTVEVTLmdldCgnZGVzdGlubycsIF9kZXN0aW5vX3Bvcl9kZWZlY3Rv
:::KCkpKSkpCiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIGlmIG5vdCBj
:::YXJwZXRhLmlzX2RpcigpOgogICAgICAgICAgICAgICAgICAgIGxvZyhmJ0xhIGNh
:::cnBldGEgdG9kYXbDrWEgbm8gZXhpc3RlOiB7Y2FycGV0YX0nLCAnYXZpc28nKQog
:::ICAgICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2NvbXByb2JhY2lv
:::bicsIFRydWUsICcnKSkKICAgICAgICAgICAgICAgICAgICByZXR1cm4KICAgICAg
:::ICAgICAgICAgIGlmIEZGUFJPQkUgaXMgTm9uZToKICAgICAgICAgICAgICAgICAg
:::ICBsb2coJ2ZmcHJvYmUgbm8gZXN0w6EgZGlzcG9uaWJsZSAodmllbmUgY29uIEZG
:::bXBlZykuICcKICAgICAgICAgICAgICAgICAgICAgICAgJ0VqZWN1dGEgRGVzY2Fy
:::Z2Fkb3JNdXNpY2EuYmF0IHBhcmEgaW5zdGFsYXJsby4nLAogICAgICAgICAgICAg
:::ICAgICAgICAgICAnZXJyb3InKQogICAgICAgICAgICAgICAgICAgIGNvbGEucHV0
:::KCgnZmluJywgJ2NvbXByb2JhY2lvbicsIFRydWUsICcnKSkKICAgICAgICAgICAg
:::ICAgICAgICByZXR1cm4KICAgICAgICAgICAgICAgIGV4dHMgPSAoJy5tNGEnLCAn
:::Lm1wMycsICcuZmxhYycsICcud2F2JywgJy53bWEnLCAnLmF2aScpCiAgICAgICAg
:::ICAgICAgICBhcmNoaXZvcyA9IFtwIGZvciBwIGluIHNvcnRlZChjYXJwZXRhLnJn
:::bG9iKCcqJykpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBpZiBwLmlzX2Zp
:::bGUoKSBhbmQgcC5zdWZmaXgubG93ZXIoKSBpbiBleHRzCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICBhbmQgJ190bXAnIG5vdCBpbiBwLnBhcnRzXQogICAgICAg
:::ICAgICAgICAgbG9nKGYnQ29tcHJvYmFuZG8ge2xlbihhcmNoaXZvcyl9IGFyY2hp
:::dm8ocykgZW4gJwogICAgICAgICAgICAgICAgICAgIGYne2NhcnBldGF9IC4uLics
:::ICd0aXR1bG8nKQogICAgICAgICAgICAgICAgaWYgbm90IGFyY2hpdm9zOgogICAg
:::ICAgICAgICAgICAgICAgIGxvZygnTm8gaGF5IGFyY2hpdm9zIGRlIGF1ZGlvIG8g
:::dmlkZW8gdG9kYXbDrWEuJywgJ2dyaXMnKQogICAgICAgICAgICAgICAgICAgIGNv
:::bGEucHV0KCgnZmluJywgJ2NvbXByb2JhY2lvbicsIFRydWUsICcnKSkKICAgICAg
:::ICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgICAgIHRvdGFsID0gMAog
:::ICAgICAgICAgICAgICAgYmFqYXMgPSAwCiAgICAgICAgICAgICAgICBmb3IgcCBp
:::biBhcmNoaXZvczoKICAgICAgICAgICAgICAgICAgICB0cnk6CiAgICAgICAgICAg
:::ICAgICAgICAgICAgIHIgPSBzdWJwcm9jZXNzLnJ1bigKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIFtzdHIoRkZQUk9CRSksICctdicsICdlcnJvcicsICctc2hv
:::d19lbnRyaWVzJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAnZm9ybWF0
:::PWJpdF9yYXRlLGR1cmF0aW9uLHNpemUnLCAnLW9mJywgJ2pzb24nLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgIHN0cihwKV0sCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICBzdGRvdXQ9c3VicHJvY2Vzcy5QSVBFLCBzdGRlcnI9c3VicHJv
:::Y2Vzcy5QSVBFLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgdGV4dD1UcnVl
:::LCBlbmNvZGluZz0ndXRmLTgnLCBlcnJvcnM9J3JlcGxhY2UnLAogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgdGltZW91dD0zMCkKICAgICAgICAgICAgICAgICAg
:::ICAgICAgZGF0b3MgPSBqc29uLmxvYWRzKHIuc3Rkb3V0IG9yICd7fScpLmdldCgn
:::Zm9ybWF0Jywge30pCiAgICAgICAgICAgICAgICAgICAgICAgIGticHMgPSBpbnQo
:::ZmxvYXQoZGF0b3MuZ2V0KCdiaXRfcmF0ZScpIG9yIDApIC8gMTAwMCkKICAgICAg
:::ICAgICAgICAgICAgICAgICAgZHVyID0gZmxvYXQoZGF0b3MuZ2V0KCdkdXJhdGlv
:::bicpIG9yIDApCiAgICAgICAgICAgICAgICAgICAgICAgIHRhbSA9IGludChmbG9h
:::dChkYXRvcy5nZXQoJ3NpemUnKSBvciAwKSkKICAgICAgICAgICAgICAgICAgICBl
:::eGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICAgICAgICAgICAgICBsb2coZifC
:::tyB7cC5uYW1lWzo2MF19IOKAlCBubyBzZSBwdWRvIGxlZXInLCAnYXZpc28nKQog
:::ICAgICAgICAgICAgICAgICAgICAgICBjb250aW51ZQogICAgICAgICAgICAgICAg
:::ICAgIHRvdGFsICs9IHRhbQogICAgICAgICAgICAgICAgICAgIHRleHRvLCBuaXZl
:::bCA9IGNsYXNlX2NhbGlkYWQocC5zdWZmaXgubG93ZXIoKSwga2JwcykKICAgICAg
:::ICAgICAgICAgICAgICBpZiBuaXZlbCA9PSAyOgogICAgICAgICAgICAgICAgICAg
:::ICAgICBiYWphcyArPSAxCiAgICAgICAgICAgICAgICAgICAgdGFnID0gKCdvaycg
:::aWYgbml2ZWwgPT0gMAogICAgICAgICAgICAgICAgICAgICAgICAgICBlbHNlICgn
:::YXZpc28nIGlmIG5pdmVsID09IDEgZWxzZSAnZXJyb3InKSkKICAgICAgICAgICAg
:::ICAgICAgICBsb2coZifCtyB7cC5uYW1lWzo1OF19IOKAlCB7dGV4dG99IMK3IHtm
:::bXRfdGllbShkdXIpfSDCtyAnCiAgICAgICAgICAgICAgICAgICAgICAgIGYne2Zt
:::dF90YW0odGFtKX0nLCB0YWcpCiAgICAgICAgICAgICAgICBsb2coZidSZXN1bHRh
:::ZG86IHtsZW4oYXJjaGl2b3MpfSBhcmNoaXZvKHMpIMK3ICcKICAgICAgICAgICAg
:::ICAgICAgICBmJ3tmbXRfdGFtKHRvdGFsKX0gZW4gdG90YWwgwrcge2JhamFzfSBj
:::b24gY2FsaWRhZCBiYWphJywKICAgICAgICAgICAgICAgICAgICAndGl0dWxvJykK
:::ICAgICAgICAgICAgICAgIGlmIGJhamFzOgogICAgICAgICAgICAgICAgICAgIGxv
:::ZygnQ29uc2VqbzogbG9zIGFyY2hpdm9zIG1hcmNhZG9zIGVuIHJvam8gc2UgcHVl
:::ZGVuICcKICAgICAgICAgICAgICAgICAgICAgICAgJ3ZvbHZlciBhIGRlc2Nhcmdh
:::ciBjb24gbcOhcyBiaXRyYXRlLicsICdncmlzJykKICAgICAgICAgICAgZXhjZXB0
:::IEV4Y2VwdGlvbiBhcyBlOgogICAgICAgICAgICAgICAgbG9nKGYnRXJyb3IgYWwg
:::Y29tcHJvYmFyIGxhIGNhcnBldGE6IHtlfScsICdlcnJvcicpCiAgICAgICAgICAg
:::IGZpbmFsbHk6CiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdjb21w
:::cm9iYWNpb24nLCBUcnVlLCAnJykpCgogICAgICAgIGRlZiBfaGlsb19hY3R1YWxp
:::emFyKHNlbGYsIGNmZyk6CiAgICAgICAgICAgIGNvbGEgPSBzZWxmLmNvbGEKCiAg
:::ICAgICAgICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgogICAgICAgICAgICAgICAg
:::Y29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICAgICAgICAgIHRyeToKICAgICAg
:::ICAgICAgICAgIGxvZygnQWN0dWFsaXphbmRvIHl0LWRscCB5IG11dGFnZW4uLi4n
:::LCAnZ3JpcycpCiAgICAgICAgICAgICAgICBwID0gc3VicHJvY2Vzcy5ydW4oCiAg
:::ICAgICAgICAgICAgICAgICAgW3N5cy5leGVjdXRhYmxlLCAnLW0nLCAncGlwJywg
:::J2luc3RhbGwnLCAnLS11cGdyYWRlJywKICAgICAgICAgICAgICAgICAgICAgJy0t
:::bm8td2Fybi1zY3JpcHQtbG9jYXRpb24nLCAneXQtZGxwJywgJ211dGFnZW4nXSwK
:::ICAgICAgICAgICAgICAgICAgICBzdGRvdXQ9c3VicHJvY2Vzcy5QSVBFLCBzdGRl
:::cnI9c3VicHJvY2Vzcy5TVERPVVQsCiAgICAgICAgICAgICAgICAgICAgdGV4dD1U
:::cnVlLCBlbmNvZGluZz0ndXRmLTgnLCBlcnJvcnM9J3JlcGxhY2UnLCB0aW1lb3V0
:::PTYwMCkKICAgICAgICAgICAgICAgIGZvciBsbiBpbiAocC5zdGRvdXQgb3IgJycp
:::LnN0cmlwKCkuc3BsaXRsaW5lcygpWy02Ol06CiAgICAgICAgICAgICAgICAgICAg
:::bG9nKCcgICAnICsgbG5bOjE2MF0sICdncmlzJykKICAgICAgICAgICAgICAgIGlm
:::IHAucmV0dXJuY29kZSA9PSAwOgogICAgICAgICAgICAgICAgICAgIGxvZygneXQt
:::ZGxwIGFjdHVhbGl6YWRvLiBSZWluaWNpYSBsYSBhcGxpY2FjacOzbiBwYXJhICcK
:::ICAgICAgICAgICAgICAgICAgICAgICAgJ3VzYXIgbGEgdmVyc2nDs24gbnVldmEu
:::JywgJ29rJykKICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICAg
:::ICAgbG9nKCdMYSBhY3R1YWxpemFjacOzbiBmYWxsw7MgKMK/c2luIGludGVybmV0
:::PykuJywgJ2Vycm9yJykKICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBl
:::OgogICAgICAgICAgICAgICAgbG9nKGYnTm8gc2UgcHVkbyBlamVjdXRhciBwaXA6
:::IHtlfScsICdlcnJvcicpCiAgICAgICAgICAgIGZpbmFsbHk6CiAgICAgICAgICAg
:::ICAgICBjb2xhLnB1dCgoJ2ZpbicsICdhY3R1YWxpemFjaW9uJywgVHJ1ZSwgJycp
:::KQoKICAgICAgICBkZWYgX21zZ19lcnJvcihzZWxmLCBlKToKICAgICAgICAgICAg
:::bGluZWFzID0gW2wgZm9yIGwgaW4gc3RyKGUpLnN0cmlwKCkuc3BsaXRsaW5lcygp
:::IGlmIGwuc3RyaXAoKV0KICAgICAgICAgICAgcmV0dXJuIChsaW5lYXNbMF1bOjI1
:::MF0gaWYgbGluZWFzCiAgICAgICAgICAgICAgICAgICAgZWxzZSBmJ3t0eXBlKGUp
:::Ll9fbmFtZV9ffTogc2luIGRldGFsbGVzJykKCiAgICAgICAgIyAtLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gYXJyYW5xdWUK
:::ICAgICAgICBkZWYgX2FycmFucXVlKHNlbGYpOgogICAgICAgICAgICBzZWxmLl9s
:::b2coZidNdXNpa0FMQU4gdntBUFBfVn0nLCAndGl0dWxvJykKICAgICAgICAgICAg
:::c2VsZi5fbG9nKCdDdHJsK1U6IGFjdHVhbGl6YXIgeXQtZGxwIMK3IEN0cmwrTDog
:::bGltcGlhciByZWdpc3RybycsCiAgICAgICAgICAgICAgICAgICAgICAnZ3Jpcycp
:::CiAgICAgICAgICAgIHRocmVhZGluZy5UaHJlYWQodGFyZ2V0PXNlbGYuX2hpbG9f
:::dmVyc2lvbiwgZGFlbW9uPVRydWUpLnN0YXJ0KCkKCiAgICAgICAgZGVmIF9oaWxv
:::X3ZlcnNpb24oc2VsZik6CiAgICAgICAgICAgIGNvbGEgPSBzZWxmLmNvbGEKCiAg
:::ICAgICAgICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgogICAgICAgICAgICAgICAg
:::Y29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICAgICAgICAgIGlmIFlUX0RMUCBp
:::cyBOb25lOgogICAgICAgICAgICAgICAgbG9nKCd5dC1kbHAgbm8gZXN0w6EgaW5z
:::dGFsYWRvLiBFamVjdXRhICcKICAgICAgICAgICAgICAgICAgICAnRGVzY2FyZ2Fk
:::b3JNdXNpY2EuYmF0IHBhcmEgaW5zdGFsYXJsby4nLCAnZXJyb3InKQogICAgICAg
:::ICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAndmVyc2lvbicsIFRydWUsICcnKSkK
:::ICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICB0cnk6CiAgICAgICAg
:::ICAgICAgICBpbnN0YWxhZGEgPSBZVF9ETFAudmVyc2lvbi5fX3ZlcnNpb25fXwog
:::ICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICAgICAgaW5z
:::dGFsYWRhID0gJz8nCiAgICAgICAgICAgIHVsdGltYSA9IE5vbmUKICAgICAgICAg
:::ICAgdHJ5OgogICAgICAgICAgICAgICAgd2l0aCB1cmxvcGVuKCdodHRwczovL3B5
:::cGkub3JnL3B5cGkveXQtZGxwL2pzb24nLCB0aW1lb3V0PTEyKSBhcyByOgogICAg
:::ICAgICAgICAgICAgICAgIHVsdGltYSA9IGpzb24ubG9hZHMoci5yZWFkKCkuZGVj
:::b2RlKCd1dGYtOCcpKVsnaW5mbyddWyd2ZXJzaW9uJ10KICAgICAgICAgICAgZXhj
:::ZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgICAgIHVsdGltYSA9IE5vbmUKICAg
:::ICAgICAgICAgaWYgdWx0aW1hIGlzIE5vbmU6CiAgICAgICAgICAgICAgICBsb2co
:::Zid5dC1kbHA6IHZlcnNpw7NuIHtpbnN0YWxhZGF9ICcKICAgICAgICAgICAgICAg
:::ICAgICAnKG5vIHNlIHB1ZG8gY29tcHJvYmFyIHNpIGhheSBub3ZlZGFkZXMpLics
:::ICdncmlzJykKICAgICAgICAgICAgZWxpZiBzdHIodWx0aW1hKSA9PSBzdHIoaW5z
:::dGFsYWRhKToKICAgICAgICAgICAgICAgIGxvZyhmJ3l0LWRscDogZW4gbGEgdWx0
:::aW1hIHZlcnNpb24gKHtpbnN0YWxhZGF9KS4nLCAnaW5mbycpCiAgICAgICAgICAg
:::IGVsc2U6CiAgICAgICAgICAgICAgICBsb2coZid5dC1kbHA6IGhheSB2ZXJzaW9u
:::IG51ZXZhICh7dWx0aW1hfSk7IGluc3RhbGFkYTogJwogICAgICAgICAgICAgICAg
:::ICAgIGYne2luc3RhbGFkYX0uIFB1bHNhIEN0cmwrVSBwYXJhIGFjdHVhbGl6YXIu
:::JywgJ2F2aXNvJykKICAgICAgICAgICAgaWYgRkZNUEVHIGlzIE5vbmU6CiAgICAg
:::ICAgICAgICAgICBsb2coJ0ZGbXBlZzogTk8gRU5DT05UUkFETyDigJQgZWplY3V0
:::YSBEZXNjYXJnYWRvck11c2ljYS5iYXQgJwogICAgICAgICAgICAgICAgICAgICdw
:::YXJhIGluc3RhbGFybG8uJywgJ2Vycm9yJykKICAgICAgICAgICAgZWxzZToKICAg
:::ICAgICAgICAgICAgIGxvZyhmJ0ZGbXBlZzogT0sgKHtGRk1QRUd9KScsICdncmlz
:::JykKICAgICAgICAgICAgbG9nKCdDYXJwZXRhIGRlIGd1YXJkYWRvOiAnICsgc3Ry
:::KEFKVVNURVMuZ2V0KCdkZXN0aW5vJykpLCAnZ3JpcycpCiAgICAgICAgICAgIGNv
:::bGEucHV0KCgnZmluJywgJ3ZlcnNpb24nLCBUcnVlLCAnJykpCgoKIyAtLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tIG1haW4KZGVmIG1haW4oKToKICAgIF9yZWNvbmZpZ3VyYXJfc2Fs
:::aWRhKCkKICAgIGlmIG5vdCBUS19PSzoKICAgICAgICBwcmludCgnRXN0YSBhcGxp
:::Y2FjacOzbiBuZWNlc2l0YSBUa2ludGVyIChpbnRlcmZheiBncsOhZmljYSkuJykK
:::ICAgICAgICBwcmludCgnRWwgUHl0aG9uIGFjdHVhbCBubyBsbyBpbmNsdXllLicp
:::CiAgICAgICAgcHJpbnQoJ1Z1ZWx2ZSBhIGVqZWN1dGFyIERlc2NhcmdhZG9yTXVz
:::aWNhLmJhdCBwYXJhIGluc3RhbGFyIGVsICcKICAgICAgICAgICAgICAnUHl0aG9u
:::IGFkZWN1YWRvLicpCiAgICAgICAgcmV0dXJuIDEKICAgIGNvbXByb2Jhcl9lbnRv
:::cm5vKCkKICAgIGFwcCA9IEFwcCgpCiAgICBhcHAubWFpbmxvb3AoKQogICAgcmV0
:::dXJuIDAKCgppZiBfX25hbWVfXyA9PSAnX19tYWluX18nOgogICAgdHJ5OgogICAg
:::ICAgIHN5cy5leGl0KG1haW4oKSkKICAgIGV4Y2VwdCBTeXN0ZW1FeGl0OgogICAg
:::ICAgIHJhaXNlCiAgICBleGNlcHQgQmFzZUV4Y2VwdGlvbjoKICAgICAgICB0cnk6
:::CiAgICAgICAgICAgIHdpdGggb3BlbihMT0dfRVJST1JFUywgJ2EnLCBlbmNvZGlu
:::Zz0ndXRmLTgnKSBhcyBmaDoKICAgICAgICAgICAgICAgIGZoLndyaXRlKHRyYWNl
:::YmFjay5mb3JtYXRfZXhjKCkgKyAnXG4nKQogICAgICAgIGV4Y2VwdCBFeGNlcHRp
:::b246CiAgICAgICAgICAgIHBhc3MKICAgICAgICByYWlzZQo=
