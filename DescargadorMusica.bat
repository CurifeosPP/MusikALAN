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
title MusikALAN v2.12
rem  Marca de version: la busca este mismo archivo con findstr para
rem  compararse con la ultima release publicada en GitHub.
rem  NO cambiar el formato de la linea siguiente.
rem VERSION-BUSCABLE: 2.12
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
echo    %C_TIT%MusikALAN v2.12%C_FIN% - preparando el entorno
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
title MusikALAN v2.12 - YouTube a AAC/MP3/FLAC/WAV/WMA/AVI
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
:::UF9WID0gJzIuMTInCkFQUF9ESVIgPSBQYXRoKF9fZmlsZV9fKS5yZXNvbHZlKCku
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
:::Z2lzdHJvOgogICAgQVZJU09TX1JVSURPU09TID0gKCdObyBzdXBwb3J0ZWQgSmF2
:::YVNjcmlwdCBydW50aW1lJywgJ0VKUycpCgogICAgZGVmIHdhcm5pbmcoc2VsZiwg
:::bSk6CiAgICAgICAgbSA9IHN0cihtKS5zdHJpcCgpCiAgICAgICAgaWYgbm90IG0g
:::b3IgYW55KHggaW4gbSBmb3IgeCBpbiBzZWxmLkFWSVNPU19SVUlET1NPUyk6CiAg
:::ICAgICAgICAgIHJldHVybgogICAgICAgIGlmIHNlbGYubG9nOgogICAgICAgICAg
:::ICBzZWxmLmxvZyhtLCAnYXZpc28nKQoKICAgIGRlZiBlcnJvcihzZWxmLCBtKToK
:::ICAgICAgICBtID0gc3RyKG0pLnN0cmlwKCkKICAgICAgICBpZiBtIGFuZCBzZWxm
:::LmxvZzoKICAgICAgICAgICAgc2VsZi5sb2cobSwgJ2Vycm9yJykKCgpSRUdJU1RS
:::TyA9IFJlZ2lzdHJvKCkKCiMgdjIuMTI6IGJpdHJhdGUgKGticHMpIGRlbCBhdWRp
:::byBxdWUgWW91VHViZSBlbnRyZWdvIGVuIGxhIHVsdGltYQojIGRlc2NhcmdhIChs
:::byByZWxsZW5hIGVsIGhvb2sgZGUgcHJvZ3Jlc28gYWwgdGVybWluYXIgZGUgYmFq
:::YXIpLiBTaXJ2ZQojIHBhcmEgZGVjaXIgZW4gZWwgbWVuc2FqZSBmaW5hbCBzaSBz
:::ZSBjb25zaWd1aW8gbGEgY2FsaWRhZCBwZWRpZGEgbyBzaQojIFlvdVR1YmUgc29s
:::byB0ZW5pYSB1bmEgZnVlbnRlIGFsZ28gbWFzIGJhamEuCl9GVUVOVEUgPSB7J2Fi
:::cic6IE5vbmV9CgpOT01CUkVTX1BQID0gewogICAgJ0ZGbXBlZ0V4dHJhY3RBdWRp
:::byc6ICdDb252aXJ0aWVuZG8gZWwgYXVkaW8gY29uIEZGbXBlZycsCiAgICAnRXh0
:::cmFjdEF1ZGlvJzogJ0NvbnZpcnRpZW5kbyBlbCBhdWRpbycsCiAgICAnRkZtcGVn
:::VGh1bWJuYWlsc0NvbnZlcnRvcic6ICdDb252aXJ0aWVuZG8gbGEgY2Fyw6F0dWxh
:::IGEgSlBHJywKICAgICdUaHVtYm5haWxzQ29udmVydG9yJzogJ0NvbnZpcnRpZW5k
:::byBsYSBjYXLDoXR1bGEnLAogICAgJ0ZGbXBlZ01ldGFkYXRhJzogJ0VzY3JpYmll
:::bmRvIGV0aXF1ZXRhcyAodMOtdHVsby9hcnRpc3RhKScsCiAgICAnTWV0YWRhdGEn
:::OiAnRXNjcmliaWVuZG8gZXRpcXVldGFzJywKICAgICdFbWJlZFRodW1ibmFpbCc6
:::ICdJbmNydXN0YW5kbyBsYSBjYXLDoXR1bGEnLAogICAgJ01vdmVGaWxlcyc6ICdP
:::cmdhbml6YW5kbyBhcmNoaXZvcycsCiAgICAnRkZtcGVnTWVyZ2VyJzogJ1VuaWVu
:::ZG8gcGlzdGFzIGRlIHZpZGVvIHkgYXVkaW8nLAogICAgJ01lcmdlcic6ICdVbmll
:::bmRvIHBpc3RhcycsCiAgICAnRkZtcGVnVmlkZW9Db252ZXJ0b3InOiAnQ29udmly
:::dGllbmRvIGVsIHZpZGVvJywKICAgICdWaWRlb0NvbnZlcnRvcic6ICdDb252aXJ0
:::aWVuZG8gZWwgdmlkZW8nLAp9CgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gZm9ybWF0b3MK
:::Rk9STUFUT1MgPSB7CiAgICAnQUFDJzogZGljdCh0ZXh0bz0nQUFDICgubTRhKScs
:::IGV4dD0nbTRhJywKICAgICAgICAgICAgICAgIGNhbGlkYWRlcz1bJzk2aycsICcx
:::MjhrJ10sIGRlZmVjdG89JzEyOGsnKSwKICAgICdNUDMnOiBkaWN0KHRleHRvPSdN
:::UDMgKC5tcDMpJywgZXh0PSdtcDMnLAogICAgICAgICAgICAgICAgY2FsaWRhZGVz
:::PVsnOTZrJywgJzEyOGsnLCAnMTkyaycsICcyNTZrJywgJzMyMGsnXSwKICAgICAg
:::ICAgICAgICAgIGRlZmVjdG89JzMyMGsnKSwKICAgICdGTEFDJzogZGljdCh0ZXh0
:::bz0nRkxBQyAoLmZsYWMpJywgZXh0PSdmbGFjJywKICAgICAgICAgICAgICAgICBj
:::YWxpZGFkZXM9WydzaW4gcGVyZGlkYSddLCBkZWZlY3RvPSdzaW4gcGVyZGlkYScp
:::LAogICAgJ1dBVic6IGRpY3QodGV4dG89J1dBViAoLndhdiknLCBleHQ9J3dhdics
:::CiAgICAgICAgICAgICAgICBjYWxpZGFkZXM9WydzaW4gcGVyZGlkYSddLCBkZWZl
:::Y3RvPSdzaW4gcGVyZGlkYScpLAogICAgJ1dNQSc6IGRpY3QodGV4dG89J1dNQSAo
:::LndtYSknLCBleHQ9J3dtYScsCiAgICAgICAgICAgICAgICBjYWxpZGFkZXM9Wyc5
:::NmsnLCAnMTI4ayddLCBkZWZlY3RvPScxMjhrJyksCiAgICAnQVZJJzogZGljdCh0
:::ZXh0bz0nQVZJIC0gc2hlaWp1IDEuOCIgKDEyOHgxNjApJywgZXh0PSdhdmknLAog
:::ICAgICAgICAgICAgICAgY2FsaWRhZGVzPVsnMTI4eDE2MCDCtyAxNiBmcHMnXSwg
:::ZGVmZWN0bz0nMTI4eDE2MCDCtyAxNiBmcHMnKSwKfQoKCiMgLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLSBwcm9ncmVzbwpkZWYgaG9va3NfZ3VpKGNvbGEpOgogICAgIiIiQ3JlYSBs
:::b3MgaG9va3MgZGUgeXQtZGxwIHF1ZSBwdWJsaWNhbiBldmVudG9zIGVuIGxhIGNv
:::bGEgZGUgbGEgR1VJLiIiIgogICAgZXN0YWRvID0geyd0aXR1bG8nOiBGYWxzZSwg
:::J3BwX3VsdCc6IE5vbmV9CgogICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6CiAgICAg
:::ICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICBkZWYgcHJvZ3Jlc28oZCk6
:::CiAgICAgICAgaWYgZFsnc3RhdHVzJ10gPT0gJ2Rvd25sb2FkaW5nJzoKICAgICAg
:::ICAgICAgaWYgbm90IGVzdGFkb1sndGl0dWxvJ106CiAgICAgICAgICAgICAgICBp
:::bmZvID0gZC5nZXQoJ2luZm9fZGljdCcpIG9yIHt9CiAgICAgICAgICAgICAgICB0
:::ID0gaW5mby5nZXQoJ3RpdGxlJykgb3IgUGF0aChkLmdldCgnZmlsZW5hbWUnKSBv
:::ciAnJykuc3RlbQogICAgICAgICAgICAgICAgaWYgdDoKICAgICAgICAgICAgICAg
:::ICAgICBsb2coJ+KZqiAnICsgc3RyKHQpWzo5MF0sICd0aXR1bG8nKQogICAgICAg
:::ICAgICAgICAgICAgIGVzdGFkb1sndGl0dWxvJ10gPSBUcnVlCiAgICAgICAgICAg
:::IHRvdGFsID0gZC5nZXQoJ3RvdGFsX2J5dGVzJykgb3IgZC5nZXQoJ3RvdGFsX2J5
:::dGVzX2VzdGltYXRlJykgb3IgMAogICAgICAgICAgICBkb25lID0gZC5nZXQoJ2Rv
:::d25sb2FkZWRfYnl0ZXMnLCAwKQogICAgICAgICAgICB2ZWwgPSBkLmdldCgnc3Bl
:::ZWQnKQogICAgICAgICAgICBldGEgPSBkLmdldCgnZXRhJykKICAgICAgICAgICAg
:::aWYgdG90YWw6CiAgICAgICAgICAgICAgICBwY3QgPSBkb25lIC8gdG90YWwgKiAx
:::MDAKICAgICAgICAgICAgICAgIHRleHRvID0gZid7cGN0OjUuMWZ9JSDCtyB7Zm10
:::X3RhbShkb25lKX0gLyB7Zm10X3RhbSh0b3RhbCl9JwogICAgICAgICAgICAgICAg
:::aWYgdmVsOgogICAgICAgICAgICAgICAgICAgIHRleHRvICs9IGYnIMK3IHtmbXRf
:::dGFtKHZlbCl9L3MnCiAgICAgICAgICAgICAgICBpZiBldGEgaXMgbm90IE5vbmU6
:::CiAgICAgICAgICAgICAgICAgICAgdGV4dG8gKz0gZicgwrcgcXVlZGFuIHtmbXRf
:::dGllbShldGEpfScKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgncHJvZycsIHBj
:::dCwgdGV4dG8pKQogICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgdiA9
:::IGYne2ZtdF90YW0odmVsKX0vcycgaWYgdmVsIGVsc2UgJycKICAgICAgICAgICAg
:::ICAgIGNvbGEucHV0KCgncHJvZycsIE5vbmUsIGYne2ZtdF90YW0oZG9uZSl9IMK3
:::IHt2fScpKQogICAgICAgIGVsaWYgZFsnc3RhdHVzJ10gPT0gJ2ZpbmlzaGVkJzoK
:::ICAgICAgICAgICAgZXN0YWRvWydwcF91bHQnXSA9IE5vbmUKICAgICAgICAgICAg
:::IyB2Mi4xMjogcmVjb3JkYXIgbGEgY2FsaWRhZCBSRUFMIHF1ZSBZb3VUdWJlIGVu
:::dHJlZ28gKGVsCiAgICAgICAgICAgICMgZm9ybWF0byBlbGVnaWRvIHB1ZWRlIHNl
:::ciBtYXMgYmFqbyBxdWUgZWwgcGVkaWRvKS4gU29sbyBzZQogICAgICAgICAgICAj
:::IGFjZXB0YSBzaSB0cmFlIGJpdHJhdGU6IGxhIG1pbmlhdHVyYSBubyBsbyB0cmFl
:::IHkgbm8gZGViZQogICAgICAgICAgICAjIG1hY2hhY2FyIGVsIHZhbG9yLgogICAg
:::ICAgICAgICBpbmYgPSBkLmdldCgnaW5mb19kaWN0Jykgb3Ige30KICAgICAgICAg
:::ICAgYWJyID0gaW5mLmdldCgnYWJyJykgb3IgaW5mLmdldCgndGJyJykKICAgICAg
:::ICAgICAgaWYgaXNpbnN0YW5jZShhYnIsIChpbnQsIGZsb2F0KSkgYW5kIGFiciA+
:::IDA6CiAgICAgICAgICAgICAgICBfRlVFTlRFWydhYnInXSA9IGZsb2F0KGFicikK
:::ICAgICAgICAgICAgY29sYS5wdXQoKCdsb2cnLCAnRGVzY2FyZ2EgcmVjaWJpZGEu
:::IFByb2Nlc2FuZG8uLi4nLCAnZ3JpcycpKQogICAgICAgICAgICBjb2xhLnB1dCgo
:::J3Byb2cnLCAwLCAnUHJvY2VzYW5kby4uLicpKQoKICAgIGRlZiBwb3N0cHJvY2Vz
:::byhkKToKICAgICAgICBpZiBkWydzdGF0dXMnXSA9PSAnc3RhcnRlZCc6CiAgICAg
:::ICAgICAgIG5vbSA9IChkLmdldCgncG9zdHByb2Nlc3Nvcl9uYW1lJykKICAgICAg
:::ICAgICAgICAgICAgIG9yIGQuZ2V0KCdwb3N0cHJvY2Vzc29yJykgb3IgJ1Bvc3Rw
:::cm9jZXNvJykKICAgICAgICAgICAgaWYgbm9tID09IGVzdGFkb1sncHBfdWx0J106
:::CiAgICAgICAgICAgICAgICByZXR1cm4gICMgeXQtZGxwIGEgdmVjZXMgYW51bmNp
:::YSBlbCBtaXNtbyBwYXNvIGRvcyB2ZWNlcwogICAgICAgICAgICBlc3RhZG9bJ3Bw
:::X3VsdCddID0gbm9tCiAgICAgICAgICAgIHRleHRvID0gTk9NQlJFU19QUC5nZXQo
:::bm9tLCBub20pICsgJy4uLicKICAgICAgICAgICAgIyB2Mi4xMjogbG9zIHBhc29z
:::IGludGVybm9zIHNvbG8gc2UgdmVuIGVuIGxhIGJhcnJhIGRlCiAgICAgICAgICAg
:::ICMgcHJvZ3Jlc287IGVsIHJlZ2lzdHJvIHNlIHF1ZWRhIGNvbiBsbyBpbXBvcnRh
:::bnRlCiAgICAgICAgICAgIGNvbGEucHV0KCgncHJvZycsIE5vbmUsIHRleHRvKSkK
:::CiAgICByZXR1cm4gcHJvZ3Jlc28sIHBvc3Rwcm9jZXNvCgoKZGVmIHRleHRvX2Nh
:::bGlkYWQoY2xhdmUsIGNhbGlkYWRfYXJnKToKICAgICIiIlN1ZmlqbyBkZWwgbWVu
:::c2FqZSBmaW5hbDogwr9zZSBjb25zaWd1aW8gbGEgY2FsaWRhZCBwZWRpZGE/CiAg
:::ICBDb21wYXJhIGVsIGJpdHJhdGUgZGVsIGZvcm1hdG8gcXVlIFlvdVR1YmUgZW50
:::cmVnbyAoX0ZVRU5URSwgcXVlCiAgICByZWxsZW5hIGVsIGhvb2sgZGUgcHJvZ3Jl
:::c28pIGNvbiBsYSBjYWxpZGFkIHNlbGVjY2lvbmFkYS4gU29sbwogICAgYXBsaWNh
:::IGEgbG9zIGZvcm1hdG9zIGNvbiBiaXRyYXRlOiBGTEFDL1dBViBubyB0aWVuZW4g
:::J2NhbGlkYWQnCiAgICBxdWUgY29tcGFyYXIgeSBlbCBBVkkgZXMgdmlkZW8uIFNp
:::IG5vIHNlIHB1ZG8gc2FiZXIgbGEgZnVlbnRlLAogICAgbm8gc2UgYW5hZGUgbmFk
:::YSAobWVqb3IgY2FsbGFyIHF1ZSBpbnZlbnRhcikuIiIiCiAgICBpZiBjbGF2ZSBu
:::b3QgaW4gKCdBQUMnLCAnTVAzJywgJ1dNQScpOgogICAgICAgIHJldHVybiAnJwog
:::ICAgdHJ5OgogICAgICAgIHBlZGlkYSA9IGludChyZS5zdWIocidbXjAtOV0nLCAn
:::Jywgc3RyKGNhbGlkYWRfYXJnKSkpCiAgICBleGNlcHQgVmFsdWVFcnJvcjoKICAg
:::ICAgICByZXR1cm4gJycKICAgIGlmIHBlZGlkYSA8PSAwOgogICAgICAgIHJldHVy
:::biAnJwogICAgZnVlbnRlID0gX0ZVRU5URS5nZXQoJ2FicicpCiAgICBpZiBub3Qg
:::ZnVlbnRlOgogICAgICAgIHJldHVybiAnJyAgICAgICAgICAjIG5vIHNlIHB1ZG8g
:::c2FiZXI6IG1lam9yIGNhbGxhciBxdWUgaW52ZW50YXIKICAgIGlmIGZ1ZW50ZSA8
:::IHBlZGlkYSAqIDAuOToKICAgICAgICByZXR1cm4gKCcgIMK3ICBjYWxpZGFkIGFs
:::Z28gbcOhcyBiYWphOiBZb3VUdWJlIHNvbG8gb2ZyZWPDrWEgficKICAgICAgICAg
:::ICAgICAgIGYne2ludChyb3VuZChmdWVudGUpKX1rIGRlIHtwZWRpZGF9aycpCiAg
:::ICByZXR1cm4gZicgIMK3ICB7Y2xhdmV9IHtwZWRpZGF9ayAoY2FsaWRhZCBzZWxl
:::Y2Npb25hZGEpJwoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLSBhbnRpLWJsb3F1ZW8gZGUgWW91VHViZSAodjIuOSkKIyBDdWFu
:::ZG8gWW91VHViZSBkZXNjb25mw61hIGRlIHVuYSByZWQgKHdpZmkgY29tcGFydGlk
:::bywgZGF0b3MgbcOzdmlsZXMsIFZQTgojIG8gbXVjaGFzIGRlc2NhcmdhcyBzZWd1
:::aWRhcykgcmVzcG9uZGUgYSBsb3MgY2xpZW50ZXMgd2ViIGNvbiAiU2lnbiBpbiB0
:::bwojIGNvbmZpcm0geW91J3JlIG5vdCBhIGJvdCIgbyBIVFRQIDQyOS4gRGVmZW5z
:::YSBlbiBjYXBhczoKIyAgIDEpIFBvciBkZWZlY3RvIGxvcyBmb3JtYXRvcyBzZSBw
:::aWRlbiBjb24gbG9zIGNsaWVudGVzIGRlIGxhcyBBUFBTCiMgICAgICBtw7N2aWxl
:::cyAoYW5kcm9pZC9pb3MvbXdlYiksIHF1ZSBlbiBsYSBtYXlvcsOtYSBkZSBsYXMg
:::cmVkZXMgbm8gcGFzYW4KIyAgICAgIHBvciBlc2UgY2hlcXVlby4KIyAgIDIpIFNp
:::IGF1biBhc8OtIFlvdVR1YmUgaW5zaXN0ZSwgbGEgZGVzY2FyZ2Egc2UgcmVpbnRl
:::bnRhIFVOQSB2ZXogc29sYQojICAgICAgY29uIGVsIGNvbWJvIDIgKGFuZHJvaWRf
:::dnIvYW5kcm9pZC9pb3MsIHNpbiBjbGllbnRlcyB3ZWIpIHRyYXMgdW5hCiMgICAg
:::ICBwZXF1ZcOxYSBwYXVzYSBwYXJhIGRlamFyIGVuZnJpYXIgZWwgNDI5LgojICAg
:::Mykgw5psdGltYSBsw61uZWE6IGVsIGRlc3BsZWdhYmxlICJTaSBZb3VUdWJlIGJs
:::b3F1ZWE6IiBwZXJtaXRlIHVzYXIgbGFzCiMgICAgICBDT09LSUVTIGRlbCBuYXZl
:::Z2Fkb3IgZGVsIHVzdWFyaW8gKGNvbiBzZXNpw7NuIGFiaWVydGEgWW91VHViZSBu
:::bwojICAgICAgcGlkZSB2ZXJpZmljYWNpw7NuKS4gRXMgbGEgdsOtYSBvZmljaWFs
:::IHJlY29tZW5kYWRhIHBvciB5dC1kbHAuCkNPTUJPU19BTlRJX0JPVCA9ICgKICAg
:::ICgnYW5kcm9pZCcsICdpb3MnLCAnbXdlYicpLAogICAgKCdhbmRyb2lkX3ZyJywg
:::J2FuZHJvaWQnLCAnaW9zJyksCikKTkFWRUdBRE9SRVNfQ09PS0lFUyA9ICgnZmly
:::ZWZveCcsICdjaHJvbWUnLCAnZWRnZScsICdicmF2ZScsICdvcGVyYScsCiAgICAg
:::ICAgICAgICAgICAgICAgICAgJ3ZpdmFsZGknKQpfQU5USV9CT1QgPSB7J2NvbWJv
:::JzogMH0gICAgICAjIGNvbWJvIGVuIGN1cnNvIChkaWN0IG11dGFibGUgPSBnbG9i
:::YWwpCgoKZGVmIF9hbnRpX2JvdChvKToKICAgICIiIklueWVjdGEgZW4gbGFzIG9w
:::Y2lvbmVzIGRlIHl0LWRscCBsYSB2w61hIGFudGktYmxvcXVlbyBlbiBjdXJzby4i
:::IiIKICAgIG9bJ2V4dHJhY3Rvcl9hcmdzJ10gPSB7J3lvdXR1YmUnOiB7J3BsYXll
:::cl9jbGllbnQnOgogICAgICAgICAgICAgICAgICAgICAgICAgIGxpc3QoQ09NQk9T
:::X0FOVElfQk9UW19BTlRJX0JPVFsnY29tYm8nXV0pfX0KICAgIG9bJ2ZvcmNlaXB2
:::NCddID0gVHJ1ZQogICAgbmF2ZWdhZG9yID0gc3RyKEFKVVNURVMuZ2V0KCdjb29r
:::aWVzJywgJycpIG9yICcnKS5zdHJpcCgpLmxvd2VyKCkKICAgIGlmIG5hdmVnYWRv
:::ciBpbiBOQVZFR0FET1JFU19DT09LSUVTOgogICAgICAgIG9bJ2Nvb2tpZXNmcm9t
:::YnJvd3NlciddID0gKG5hdmVnYWRvciwpCiAgICByZXR1cm4gbwoKCmRlZiBfZXNf
:::YmxvcXVlb19ib3QodGV4dG8pOgogICAgIiIiVHJ1ZSBzaSBlbCBlcnJvciBkZSB5
:::dC1kbHAgZXMgZWwgY2hlcXVlbyBhbnRpLWJvdCBvIHVuIDQyOS4iIiIKICAgIHQg
:::PSAodGV4dG8gb3IgJycpLmxvd2VyKCkKICAgIHJldHVybiAoJ25vdCBhIGJvdCcg
:::aW4gdCBvciAnc2lnbiBpbiB0byBjb25maXJtJyBpbiB0CiAgICAgICAgICAgIG9y
:::ICd0b28gbWFueSByZXF1ZXN0cycgaW4gdCBvciAnaHR0cCBlcnJvciA0MjknIGlu
:::IHQKICAgICAgICAgICAgb3IgJyBlcnJvciA0MjknIGluIHQpCgoKIyAtLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tIG9wY2lvbmVzCmRlZiBvcHRzX2Jhc2UoY2FycGV0YSwgY29sYSk6
:::CiAgICBwcm9ncmVzbywgcG9zdHByb2Nlc28gPSBob29rc19ndWkoY29sYSkKICAg
:::IG8gPSB7CiAgICAgICAgJ291dHRtcGwnOiBzdHIoY2FycGV0YSAvICclKHRpdGxl
:::KXMuJShleHQpcycpLAogICAgICAgICdxdWlldCc6IFRydWUsCiAgICAgICAgJ25v
:::X3dhcm5pbmdzJzogVHJ1ZSwKICAgICAgICAnbm9wcm9ncmVzcyc6IFRydWUsCiAg
:::ICAgICAgJ25vcGxheWxpc3QnOiBUcnVlLAogICAgICAgICdpZ25vcmVlcnJvcnMn
:::OiBGYWxzZSwKICAgICAgICAncmV0cmllcyc6IDEwLAogICAgICAgICdmcmFnbWVu
:::dF9yZXRyaWVzJzogMTAsCiAgICAgICAgJ3NvY2tldF90aW1lb3V0JzogMzAsCiAg
:::ICAgICAgJ2NvbmN1cnJlbnRfZnJhZ21lbnRfZG93bmxvYWRzJzogNCwKICAgICAg
:::ICAnd2luZG93c2ZpbGVuYW1lcyc6IFRydWUsCiAgICAgICAgJ292ZXJ3cml0ZXMn
:::OiBGYWxzZSwKICAgICAgICAnbG9nZ2VyJzogUkVHSVNUUk8sCiAgICAgICAgJ3By
:::b2dyZXNzX2hvb2tzJzogW3Byb2dyZXNvXSwKICAgICAgICAncG9zdHByb2Nlc3Nv
:::cl9ob29rcyc6IFtwb3N0cHJvY2Vzb10sCiAgICB9CiAgICBpZiBGRk1QRUc6CiAg
:::ICAgICAgb1snZmZtcGVnX2xvY2F0aW9uJ10gPSBzdHIoRkZNUEVHLnBhcmVudCkK
:::ICAgIF9hbnRpX2JvdChvKQogICAgcmV0dXJuIG8KCgpkZWYgY29udmVydGlyX2Zm
:::bXBlZyhjbWQsIGV0aXF1ZXRhLCBjb2xhKToKICAgICIiIkVqZWN1dGEgRkZtcGVn
:::IChsaXN0YSBkZSBhcmd1bWVudG9zLCBzaW4gc2hlbGwpIGNvbiBtYXJxdWVlLiIi
:::IgogICAgY29sYS5wdXQoKCdwcm9nJywgTm9uZSwgZXRpcXVldGEpKQoKICAgIGRl
:::ZiBsb2cobSwgdD0naW5mbycpOgogICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwg
:::dCkpCgogICAgdHJ5OgogICAgICAgIHAgPSBzdWJwcm9jZXNzLnJ1bihjbWQsIHN0
:::ZG91dD1zdWJwcm9jZXNzLlBJUEUsCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::IHN0ZGVycj1zdWJwcm9jZXNzLlBJUEUsIHRleHQ9VHJ1ZSwKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgZW5jb2Rpbmc9J3V0Zi04JywgZXJyb3JzPSdyZXBsYWNl
:::JykKICAgIGV4Y2VwdCBGaWxlTm90Rm91bmRFcnJvcjoKICAgICAgICBwID0gTm9u
:::ZQogICAgaWYgcCBpcyBOb25lIG9yIHAucmV0dXJuY29kZSAhPSAwOgogICAgICAg
:::IGxvZygn4pyWIEZGbXBlZyBkZXZvbHZpw7MgdW4gZXJyb3I6JywgJ2Vycm9yJykK
:::ICAgICAgICBpZiBwIGlzIG5vdCBOb25lOgogICAgICAgICAgICBmb3IgbG4gaW4g
:::KHAuc3RkZXJyIG9yICcnKS5zdHJpcCgpLnNwbGl0bGluZXMoKVstNDpdOgogICAg
:::ICAgICAgICAgICAgbG9nKCcgICAnICsgbG5bOjE4MF0sICdncmlzJykKICAgICAg
:::ICBjb2xhLnB1dCgoJ3Byb2cnLCAwLCAnJykpCiAgICAgICAgcmV0dXJuIEZhbHNl
:::CiAgICByZXR1cm4gVHJ1ZQoKCmRlZiBhcmNoaXZvX2ZpbmFsKGluZm8sIGNhcnBl
:::dGEsIGV4dCk6CiAgICAiIiJMb2NhbGl6YSBlbCBhcmNoaXZvIHJlc3VsdGFudGUg
:::KHl0LWRscCBsbyByZXBvcnRhOyBmYWxsYmFjazogbcOhcyBudWV2bykuIiIiCiAg
:::ICB0cnk6CiAgICAgICAgZm9yIGQgaW4gKGluZm8uZ2V0KCdyZXF1ZXN0ZWRfZG93
:::bmxvYWRzJykgb3IgW10pOgogICAgICAgICAgICBmID0gZC5nZXQoJ2ZpbGVwYXRo
:::JykKICAgICAgICAgICAgaWYgZjoKICAgICAgICAgICAgICAgIHJldHVybiBQYXRo
:::KGYpCiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHBhc3MKICAgIGNhbmQg
:::PSBzb3J0ZWQoY2FycGV0YS5nbG9iKCcqLicgKyBleHQpLAogICAgICAgICAgICAg
:::ICAgICBrZXk9bGFtYmRhIHA6IHAuc3RhdCgpLnN0X210aW1lLCByZXZlcnNlPVRy
:::dWUpCiAgICByZXR1cm4gY2FuZFswXSBpZiBjYW5kIGVsc2UgTm9uZQoKCmRlZiBs
:::aW1waWFyX21pbmlhdHVyYXMoY2FycGV0YSwgYXJjaGl2byk6CiAgICAiIiJCb3Jy
:::YSBtaW5pYXR1cmFzIHN1ZWx0YXMgcXVlIEVtYmVkVGh1bWJuYWlsIGRlamFyYSBz
:::aW4gaW5jcnVzdGFyLiIiIgogICAgZm9yIGV4dCBpbiAoJy53ZWJwJywgJy5qcGcn
:::LCAnLmpwZWcnLCAnLnBuZycpOgogICAgICAgIHQgPSBhcmNoaXZvLndpdGhfc3Vm
:::Zml4KGV4dCkKICAgICAgICBpZiB0LmV4aXN0cygpOgogICAgICAgICAgICB0cnk6
:::CiAgICAgICAgICAgICAgICB0LnVubGluaygpCiAgICAgICAgICAgIGV4Y2VwdCBP
:::U0Vycm9yOgogICAgICAgICAgICAgICAgcGFzcwoKCmRlZiBfbWluaWF0dXJhX2J5
:::dGVzKGNhcnBldGEsIGFyY2hpdm8pOgogICAgIiIiTGVlIGxvcyBieXRlcyBkZSBs
:::YSBtaW5pYXR1cmEgcXVlIHl0LWRscCBkZWpvIGp1bnRvIGFsIGFyY2hpdm8gZmlu
:::YWwuIiIiCiAgICBpZiBub3QgYXJjaGl2bzoKICAgICAgICByZXR1cm4gTm9uZQog
:::ICAgZm9yIGV4dCBpbiAoJy5qcGcnLCAnLmpwZWcnLCAnLndlYnAnLCAnLnBuZycp
:::OgogICAgICAgIHQgPSBhcmNoaXZvLndpdGhfc3VmZml4KGV4dCkKICAgICAgICBp
:::ZiB0LmV4aXN0cygpOgogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBy
:::ZXR1cm4gdC5yZWFkX2J5dGVzKCkKICAgICAgICAgICAgZXhjZXB0IE9TRXJyb3I6
:::CiAgICAgICAgICAgICAgICBwYXNzCiAgICByZXR1cm4gTm9uZQoKCmRlZiBfZXNf
:::anBnKGRhdG9zKToKICAgIHJldHVybiBib29sKGRhdG9zKSBhbmQgZGF0b3NbOjNd
:::ID09IGInXHhmZlx4ZDhceGZmJwoKCmRlZiBfYV9qcGcoZGF0b3MpOgogICAgIiIi
:::Q29udmllcnRlIGxvcyBieXRlcyBkZSB1bmEgaW1hZ2VuICh3ZWJwL3BuZy8uLi4p
:::IGEgSlBFRyBjb24gRkZtcGVnLgoKICAgIExvcyByZXByb2R1Y3RvcmVzIGJhcmF0
:::b3MgKHRpcG8gc2hlaWp1KSBzdWVsZW4gbGVlciBzb2xvIEpQRUc6IGxhCiAgICBt
:::aW5pYXR1cmEgZGUgWW91VHViZSB2aWVuZSBlbiBXZWJQIHkgRW1iZWRUaHVtYm5h
:::aWwgZGUgeXQtZGxwIGxhCiAgICBjb252aWVydGUgYSBQTkcgKCJQTkcgaXMgcHJl
:::ZmVycmVkIHNpbmNlIEpQRUcgaXMgbG9zc3kiKSwgYXNpIHF1ZQogICAgYXF1aSBu
:::b3MgYXNlZ3VyYW1vcyBub3NvdHJvcyBkZSBxdWUgYWNhYmUgZW4gSlBFRy4iIiIK
:::ICAgIGlmIG5vdCBkYXRvcyBvciBub3QgRkZNUEVHOgogICAgICAgIHJldHVybiBO
:::b25lCiAgICBiYXNlID0gUGF0aCh0ZW1wZmlsZS5nZXR0ZW1wZGlyKCkpIC8gKCdt
:::dXNpa2FsYW5fY2FyYXR1bGFfJWQnICUgb3MuZ2V0cGlkKCkpCiAgICBvcmlnZW4s
:::IGRlc3Rpbm8gPSBiYXNlLndpdGhfc3VmZml4KCcub3JpZycpLCBiYXNlLndpdGhf
:::c3VmZml4KCcuanBnJykKICAgIHRyeToKICAgICAgICBvcmlnZW4ud3JpdGVfYnl0
:::ZXMoZGF0b3MpCiAgICAgICAgciA9IHN1YnByb2Nlc3MucnVuKAogICAgICAgICAg
:::ICBbc3RyKEZGTVBFRyksICcteScsICctbG9nbGV2ZWwnLCAnZXJyb3InLCAnLWkn
:::LCBzdHIob3JpZ2VuKSwKICAgICAgICAgICAgICctcTp2JywgJzInLCBzdHIoZGVz
:::dGlubyldLAogICAgICAgICAgICBzdGRvdXQ9c3VicHJvY2Vzcy5ERVZOVUxMLCBz
:::dGRlcnI9c3VicHJvY2Vzcy5ERVZOVUxMKQogICAgICAgIGlmIHIucmV0dXJuY29k
:::ZSA9PSAwIGFuZCBkZXN0aW5vLmV4aXN0cygpOgogICAgICAgICAgICBqcGcgPSBk
:::ZXN0aW5vLnJlYWRfYnl0ZXMoKQogICAgICAgICAgICBpZiBfZXNfanBnKGpwZyk6
:::CiAgICAgICAgICAgICAgICByZXR1cm4ganBnCiAgICBleGNlcHQgRXhjZXB0aW9u
:::OgogICAgICAgIHBhc3MKICAgIGZpbmFsbHk6CiAgICAgICAgZm9yIGYgaW4gKG9y
:::aWdlbiwgZGVzdGlubyk6CiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAg
:::IGYudW5saW5rKCkKICAgICAgICAgICAgZXhjZXB0IE9TRXJyb3I6CiAgICAgICAg
:::ICAgICAgICBwYXNzCiAgICByZXR1cm4gTm9uZQoKCmRlZiBfd21fcGljdHVyZShq
:::cGcsIGRlc2NyaXBjaW9uPScnKToKICAgICIiIkVtcGFxdWV0YSB1bm9zIGJ5dGVz
:::IEpQRUcgZW4gZWwgYXRyaWJ1dG8gV00vUGljdHVyZSBkZWwgY29udGVuZWRvcgog
:::ICAgQVNGICh0aXBvIDMgPSBwb3J0YWRhIGZyb250YWwpLCBjb21vIGhhY2lhIGVs
:::IHNjcmlwdCBhbnRpZ3VvLiIiIgogICAgZGVmIHUxNihzKToKICAgICAgICByZXR1
:::cm4gc3RyKHMpLmVuY29kZSgndXRmLTE2LWxlJykgKyBiJ1x4MDBceDAwJwoKICAg
:::IG1pbWUgPSB1MTYoJ2ltYWdlL2pwZWcnKQogICAgZGVzYyA9IHUxNihkZXNjcmlw
:::Y2lvbikKICAgIHJldHVybiAoYidceDAzJyArIGxlbihtaW1lKS50b19ieXRlcyg0
:::LCAnbGl0dGxlJykgKyBtaW1lCiAgICAgICAgICAgICsgbGVuKGRlc2MpLnRvX2J5
:::dGVzKDQsICdsaXR0bGUnKSArIGRlc2MgKyBqcGcpCgoKZGVmIF9tb292X3ByaW1l
:::cm8ocnV0YSk6CiAgICAiIiJUcnVlIHNpIGVsIGF0b21vICdtb292JyBlc3RhIEFO
:::VEVTIHF1ZSAnbWRhdCcgZW50cmUgbGFzIGNhamFzCiAgICB0b3AtbGV2ZWwgZGVs
:::IE1QNC9NNEEgKGVsIG9yZGVuICdmYXN0c3RhcnQnIGRlIGlUdW5lcykuIFNvbG8g
:::bGVlCiAgICBsYSBjYWJlY2VyYSAoNCBNQikgY29uIHVuIHBhc2UgZGUgdGFtYW5v
:::czogbm8gY2FyZ2EgZWwgYXJjaGl2by4iIiIKICAgIHRyeToKICAgICAgICB3aXRo
:::IG9wZW4ocnV0YSwgJ3JiJykgYXMgZmg6CiAgICAgICAgICAgIGNhYiA9IGZoLnJl
:::YWQoNCA8PCAyMCkKICAgIGV4Y2VwdCBPU0Vycm9yOgogICAgICAgIHJldHVybiBG
:::YWxzZQogICAgcG9zLCBmaW4gPSAwLCBsZW4oY2FiKQogICAgd2hpbGUgcG9zICsg
:::OCA8PSBmaW46CiAgICAgICAgdGlwbyA9IGNhYltwb3MgKyA0OnBvcyArIDhdCiAg
:::ICAgICAgaWYgdGlwbyBpbiAoYidtb292JywgYidtZGF0Jyk6CiAgICAgICAgICAg
:::IHJldHVybiB0aXBvID09IGInbW9vdicKICAgICAgICBzaXplID0gaW50LmZyb21f
:::Ynl0ZXMoY2FiW3Bvczpwb3MgKyA0XSwgJ2JpZycpCiAgICAgICAgaWYgc2l6ZSA9
:::PSAxOiAgICAgICAgICAgICAgICAgICAgICAgIyBsYXJnZXNpemUgZGUgNjQgYml0
:::cwogICAgICAgICAgICBpZiBwb3MgKyAxNiA+IGZpbjoKICAgICAgICAgICAgICAg
:::IHJldHVybiBGYWxzZQogICAgICAgICAgICBzaXplID0gaW50LmZyb21fYnl0ZXMo
:::Y2FiW3BvcyArIDg6cG9zICsgMTZdLCAnYmlnJykKICAgICAgICAgICAgaWYgc2l6
:::ZSA8IDE2OgogICAgICAgICAgICAgICAgcmV0dXJuIEZhbHNlCiAgICAgICAgZWxp
:::ZiBzaXplIDwgODogICAgICAgICAgICAgICAgICAgICAgIyBjYWphIHJvdGEgbyBF
:::T0YKICAgICAgICAgICAgcmV0dXJuIEZhbHNlCiAgICAgICAgcG9zICs9IHNpemUK
:::ICAgIHJldHVybiBGYWxzZQoKCmRlZiBfbW9vdl9hbF9wcmluY2lwaW8ocCk6CiAg
:::ICAiIiJ2Mi44OiBkZWphIGVsIGF0b21vIG1vb3YgKHF1ZSBsbGV2YSBsYXMgZXRp
:::cXVldGFzKSBhbCBQUklOQ0lQSU8KICAgIGRlbCAubTRhLCBjb21vIGhhY2UgaVR1
:::bmVzICgnZmFzdHN0YXJ0JykuCgogICAgRkZtcGVnIGVzY3JpYmUgZWwgTTRBIGNv
:::biBtb292IEFMIEZJTkFMLCBkZXRyYXMgZGUgdG9kbyBlbCBhdWRpbwogICAgKG1k
:::YXQpLiBFbCBNUDMgZGUgcmVmZXJlbmNpYSBxdWUgZWwgcmVwcm9kdWN0b3IgZGVs
:::IHVzdWFyaW8gc2kgbGVlCiAgICBsbGV2YSBzdSBJRDN2MiBhbCBpbmljaW8gZGVs
:::IGFyY2hpdm8sIHkgbG9zIHJlcHJvZHVjdG9yZXMgYmFyYXRvcwogICAgc3VlbGVu
:::IGJ1c2NhciBsYXMgZXRpcXVldGFzIGVzY2FuZWFuZG8gc29sbyBsYSBjYWJlY2Vy
:::YSBkZWwKICAgIGFyY2hpdm86IHBvciBlc28gbW9zdHJhYmFuICd1bmtub3duJyBh
:::dW5xdWUgZWwgTTRBIGVzdHV2aWVyYQogICAgcGVyZmVjdGFtZW50ZSBldGlxdWV0
:::YWRvIChhdG9tcyBpbHN0IGVzdGFuZGFyLCB2ZXJpZmljYWRvIGVuCiAgICB2Mi43
:::KS4gQ29uIC1tb3ZmbGFncyArZmFzdHN0YXJ0IGVsIG1vb3YgZW50ZXJvICh5IGRl
:::bnRybwogICAgbW9vdi51ZHRhLm1ldGEuaWxzdCBjb24gdGl0dWxvL2FydGlzdGEv
:::YWxidW0vY292cikgcGFzYSBkZWxhbnRlCiAgICBkZWwgbWRhdCBTSU4gcmVjb2Rp
:::ZmljYXIgbmFkYSAoLWMgY29weSkuIFNpIGFsZ28gZmFsbGEgc2UgZGV2dWVsdmUK
:::ICAgIEZhbHNlIHkgZWwgYXJjaGl2byBxdWVkYSBjb21vIGVzdGFiYTogZXN0byBu
:::dW5jYSBkZWJlIHJvbXBlciBsYQogICAgZGVzY2FyZ2EgbmkgbGFzIGV0aXF1ZXRh
:::cyB5YSBlc2NyaXRhcy4iIiIKICAgIGlmIG5vdCBGRk1QRUcgb3IgX21vb3ZfcHJp
:::bWVybyhwKToKICAgICAgICByZXR1cm4gRmFsc2UKICAgIHRtcCA9IHAud2l0aF9u
:::YW1lKHAuc3RlbSArICcuZmFzdHN0YXJ0Lm00YScpCiAgICB0cnk6CiAgICAgICAg
:::ciA9IHN1YnByb2Nlc3MucnVuKAogICAgICAgICAgICBbc3RyKEZGTVBFRyksICct
:::eScsICctbG9nbGV2ZWwnLCAnZXJyb3InLCAnLWknLCBzdHIocCksCiAgICAgICAg
:::ICAgICAnLW1hcCcsICcwJywgJy1jJywgJ2NvcHknLCAnLW1vdmZsYWdzJywgJytm
:::YXN0c3RhcnQnLAogICAgICAgICAgICAgc3RyKHRtcCldLAogICAgICAgICAgICBz
:::dGRvdXQ9c3VicHJvY2Vzcy5ERVZOVUxMLCBzdGRlcnI9c3VicHJvY2Vzcy5ERVZO
:::VUxMKQogICAgICAgIGlmIChyLnJldHVybmNvZGUgPT0gMCBhbmQgdG1wLmV4aXN0
:::cygpCiAgICAgICAgICAgICAgICBhbmQgX21vb3ZfcHJpbWVybyh0bXApCiAgICAg
:::ICAgICAgICAgICBhbmQgdG1wLnN0YXQoKS5zdF9zaXplICogMTAwCiAgICAgICAg
:::ICAgICAgICA+PSBwLnN0YXQoKS5zdF9zaXplICogOTApOgogICAgICAgICAgICBv
:::cy5yZXBsYWNlKHRtcCwgcCkKICAgICAgICAgICAgcmV0dXJuIFRydWUKICAgIGV4
:::Y2VwdCBFeGNlcHRpb246CiAgICAgICAgcGFzcwogICAgZmluYWxseToKICAgICAg
:::ICB0cnk6CiAgICAgICAgICAgIHRtcC51bmxpbmsoKQogICAgICAgIGV4Y2VwdCBP
:::U0Vycm9yOgogICAgICAgICAgICBwYXNzCiAgICByZXR1cm4gRmFsc2UKCgojIC0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0gZXRpcXVldGFzCmRlZiBfYXJ0aXN0YV9saW1waW8oaW5m
:::byk6CiAgICAiIiJOb21icmUgZGVsIGFydGlzdGEgbGVnaWJsZSBwYXJhIHJlcHJv
:::ZHVjdG9yZXMuCgogICAgTG9zIGNhbmFsZXMgYXV0b21hdGljb3MgZGUgbXVzaWNh
:::IGRlIFlvdVR1YmUgc2UgbGxhbWFuICdYIC0gVG9waWMnOwogICAgZXNlIHN1Zmlq
:::byBzb2JyYSBjdWFuZG8gc2UgdmUgZW4gbGEgcGFudGFsbGEgZGUgdW4gcmVwcm9k
:::dWN0b3IuIiIiCiAgICBhID0gKGluZm8uZ2V0KCdhcnRpc3QnKSBvciBpbmZvLmdl
:::dCgnY3JlYXRvcicpCiAgICAgICAgIG9yIGluZm8uZ2V0KCd1cGxvYWRlcicpIG9y
:::IGluZm8uZ2V0KCdjaGFubmVsJykgb3IgJycpCiAgICBhID0gc3RyKGEpLnN0cmlw
:::KCkKICAgIGEgPSByZS5zdWIocidccyotXHMqVG9waWNccyokJywgJycsIGEsIGZs
:::YWdzPXJlLkkpLnN0cmlwKCkKICAgIHJldHVybiBhCgoKZGVmIF9hbGJ1bV9kZShp
:::bmZvKToKICAgICIiIkFsYnVtIHBhcmEgZWwgYXJjaGl2byBmaW5hbC4KCiAgICB5
:::dC1kbHAgc29sbyBlc2NyaWJlIGFsYnVtIHNpIGVsIHByb3BpbyB2aWRlbyBsbyB0
:::cmFlIChjYXNpIG51bmNhKToKICAgIHBvciBlc28gbG9zIHJlcHJvZHVjdG9yZXMg
:::bW9zdHJhYmFuICdhbGJ1bSBkZXNjb25vY2lkbycuIE9yZGVuIGRlCiAgICBwcmVm
:::ZXJlbmNpYTogYWxidW0gcmVhbCAtPiBub21icmUgZGUgbGEgcGxheWxpc3QgLT4g
:::YXJ0aXN0YS4iIiIKICAgIGZvciBjbGF2ZSBpbiAoJ2FsYnVtJywgJ3BsYXlsaXN0
:::X3RpdGxlJyk6CiAgICAgICAgdiA9IHN0cihpbmZvLmdldChjbGF2ZSkgb3IgJycp
:::LnN0cmlwKCkKICAgICAgICBpZiB2OgogICAgICAgICAgICByZXR1cm4gdgogICAg
:::cmV0dXJuIF9hcnRpc3RhX2xpbXBpbyhpbmZvKSBvciAnWW91VHViZScKCgpkZWYg
:::YXBsaWNhcl90YWdzKGluZm8sIGFyY2hpdm8sIGxvZz1Ob25lLCBjYXJhdHVsYT1O
:::b25lKToKICAgICIiIkVzY3JpYmUgY29uIG11dGFnZW4gbGFzIGV0aXF1ZXRhcyBk
:::ZWwgYXJjaGl2byBmaW5hbC4KCiAgICBHYXJhbnRpemEgcXVlIFRPRE9TIGxvcyBy
:::ZXByb2R1Y3RvcmVzIG11ZXN0cmVuIGFydGlzdGEgeSBhbGJ1bSwKICAgIGF1bnF1
:::ZSBGRm1wZWdNZXRhZGF0YSBkZSB5dC1kbHAgbm8gbG9zIGhheWEgZXNjcml0by4g
:::Q2FkYSBmb3JtYXRvCiAgICBjb24gU1UgZm9ybWEgZXN0YW5kYXI6CiAgICAgIMK3
:::IE1QMzogSUQzdjIuNCBjb24gdGV4dG9zIFVURi0xNiAoZW5jb2Rpbmc9MSkgeSBB
:::UElDKG1pbWUKICAgICAgICAnaW1hZ2UvanBnJywgdGlwbyAzLCBkZXNjICdhdHRh
:::Y2hlZCBwaWN0dXJlJyksIGNhbGNhZG8gZGVsCiAgICAgICAgTVAzIGRlIHJlZmVy
:::ZW5jaWEgcXVlIGVsIHJlcHJvZHVjdG9yIGRlbCB1c3VhcmlvIG11ZXN0cmEKICAg
:::ICAgICBiaWVuLiBFbCBwYXNlIGFudGlndW8gdXNhYmEgZW5jb2Rpbmc9MyAoVVRG
:::LTgpIGRlbnRybyBkZSB1bgogICAgICAgIHRhZyB2Mi4zOiBmdWVyYSBkZSBlc3Bl
:::Y2lmaWNhY2lvbiwgeSBsb3MgcmVwcm9kdWN0b3JlcwogICAgICAgIGJhcmF0b3Mg
:::ZGVzY2FydGFiYW4gbGEgZXRpcXVldGEgRU5URVJBIChuaSBhcnRpc3RhLCBuaQog
:::ICAgICAgIGFsYnVtLCBuaSBwb3J0YWRhKS4KICAgICAgwrcgTTRBOiBhdG9tb3Mg
:::TVA0IGVzdGFuZGFyICjCqW5hbS/CqUFSVC9hQVJUL8KpYWxiL8KpZGF5L8KpY210
:::KSB5CiAgICAgICAgY292ciBlbiBKUEVHLCBjb21vIGlUdW5lczsgYWRlbWFzICh2
:::Mi44KSBlbCBhdG9tbyBtb292IHF1ZWRhCiAgICAgICAgQUwgUFJJTkNJUElPIGRl
:::bCBhcmNoaXZvIChmYXN0c3RhcnQpOiBmZm1wZWcgbG8gZXNjcmliZSBhbAogICAg
:::ICAgIGZpbmFsIHkgbG9zIHJlcHJvZHVjdG9yZXMgYmFyYXRvcyBzb2xvIGVzY2Fu
:::ZWFuIGxhIGNhYmVjZXJhLAogICAgICAgIHBvciBlc28gbW9zdHJhYmFuICd1bmtu
:::b3duJyBhdW5xdWUgbGFzIGV0aXF1ZXRhcyBlc3R1dmllcmFuLgogICAgICDCtyBX
:::QVY6IElEMyBkZW50cm8gZGVsIFJJRkYgKG11dGFnZW4ud2F2ZSksIGlndWFsIHF1
:::ZSBlbCBNUDMsCiAgICAgICAgbWFzIEFQSUMgY29uIGxhIGNhcmF0dWxhIChudWV2
:::byBlbiB2Mi43KS4KICAgICAgwrcgRkxBQzogVm9yYmlzIGNvbW1lbnRzICsgUGlj
:::dHVyZSBlbiBKUEVHLgogICAgICDCtyBXTUE6IEFTRiBUaXRsZS9BdXRob3IvV00v
:::QWxidW1UaXRsZS9XTS9BdXRob3JVUkwgKyBXTS9QaWN0dXJlLgogICAgICDCtyBs
:::YSBjYXJhdHVsYSBTSUVNUFJFIGFjYWJhIGVuIEpQRUcgeSBzZSBlc2NyaWJlIEFR
:::VUkgY29uCiAgICAgICAgbXV0YWdlbjogZGVzZGUgdjIuNyBFbWJlZFRodW1ibmFp
:::bCB5YSBubyB0b2NhIGxhIGNhcmF0dWxhCiAgICAgICAgKHN1IG1ldG9kbyBjYW1i
:::aWEgZW50cmUgdmVyc2lvbmVzIGRlIHl0LWRscCB5IGFsZ3VuYQogICAgICAgIGNv
:::bnZlcnNpb24gc3V5YSBkZWphYmEgUE5HL1dlYlAgcXVlIGxvcyByZXByb2R1Y3Rv
:::cmVzCiAgICAgICAgYmFyYXRvcyBubyBsZWVuKTsKICAgICAgwrcgZWwgY29tZW50
:::YXJpbyBndWFyZGEgbGEgVVJMIGRlbCB2aWRlbyAoY29tbyBlbCBzY3JpcHQgYW50
:::aWd1bykuCiAgICBgY2FyYXR1bGFgIHNvbiBsb3MgYnl0ZXMgZGUgbGEgbWluaWF0
:::dXJhIGRlc2NhcmdhZGEgKG9wY2lvbmFsKS4iIiIKICAgIHRyeToKICAgICAgICBw
:::ID0gUGF0aChhcmNoaXZvKQogICAgICAgIGlmIG5vdCBwLmV4aXN0cygpOgogICAg
:::ICAgICAgICByZXR1cm4KICAgICAgICBhcnRpc3RhID0gX2FydGlzdGFfbGltcGlv
:::KGluZm8pCiAgICAgICAgYWxidW0gPSBfYWxidW1fZGUoaW5mbykKICAgICAgICB0
:::aXR1bG8gPSBzdHIoaW5mby5nZXQoJ3RyYWNrJykgb3IgaW5mby5nZXQoJ3RpdGxl
:::Jykgb3IgJycpLnN0cmlwKCkKICAgICAgICBmZWNoYSA9IHN0cihpbmZvLmdldCgn
:::cmVsZWFzZV95ZWFyJykgb3IgJycpCiAgICAgICAgaWYgbm90IGZlY2hhOgogICAg
:::ICAgICAgICBmZWNoYSA9IHN0cihpbmZvLmdldCgndXBsb2FkX2RhdGUnKSBvciAn
:::JykKICAgICAgICAgICAgaWYgbGVuKGZlY2hhKSA9PSA4IGFuZCBmZWNoYS5pc2Rp
:::Z2l0KCk6CiAgICAgICAgICAgICAgICBmZWNoYSA9IGZlY2hhWzo0XQogICAgICAg
:::IHVybCA9IHN0cihpbmZvLmdldCgnd2VicGFnZV91cmwnKSBvciAnJykuc3RyaXAo
:::KQogICAgICAgIGlmIGNhcmF0dWxhIGFuZCBub3QgX2VzX2pwZyhjYXJhdHVsYSk6
:::CiAgICAgICAgICAgIGNhcmF0dWxhID0gX2FfanBnKGNhcmF0dWxhKQogICAgICAg
:::IGV4dCA9IHAuc3VmZml4Lmxvd2VyKCkKICAgICAgICBpZiBleHQgPT0gJy5tNGEn
:::OgogICAgICAgICAgICAjIHYyLjg6IEFOVEVTIGRlIGV0aXF1ZXRhciwgbW9vdiAo
:::dGl0dWxvL2FydGlzdGEvYWxidW0vY292cikKICAgICAgICAgICAgIyBhbCBwcmlu
:::Y2lwaW8gZGVsIGFyY2hpdm87IG11dGFnZW4gY29uc2VydmEgZXNlIG9yZGVuLgog
:::ICAgICAgICAgICBpZiBfbW9vdl9hbF9wcmluY2lwaW8ocCkgYW5kIGxvZzoKICAg
:::ICAgICAgICAgICAgIGxvZygnTTRBIHJlb3JkZW5hZG86IGV0aXF1ZXRhcyBhbCBp
:::bmljaW8gKGZhc3RzdGFydCwgJwogICAgICAgICAgICAgICAgICAgICdjb21vIGlU
:::dW5lcyknLCAnZ3JpcycpCiAgICAgICAgICAgIGZyb20gbXV0YWdlbi5tcDQgaW1w
:::b3J0IE1QNCwgTVA0Q292ZXIKICAgICAgICAgICAgbSA9IE1QNChzdHIocCkpCiAg
:::ICAgICAgICAgIGlmIHRpdHVsbzoKICAgICAgICAgICAgICAgIG1bJ1x4YTluYW0n
:::XSA9IFt0aXR1bG9dCiAgICAgICAgICAgIGlmIGFydGlzdGE6CiAgICAgICAgICAg
:::ICAgICBtWydceGE5QVJUJ10gPSBbYXJ0aXN0YV0KICAgICAgICAgICAgICAgIG1b
:::J2FBUlQnXSA9IFthcnRpc3RhXQogICAgICAgICAgICBpZiBhbGJ1bToKICAgICAg
:::ICAgICAgICAgIG1bJ1x4YTlhbGInXSA9IFthbGJ1bV0KICAgICAgICAgICAgaWYg
:::ZmVjaGE6CiAgICAgICAgICAgICAgICBtWydceGE5ZGF5J10gPSBbZmVjaGFdCiAg
:::ICAgICAgICAgIGlmIHVybDoKICAgICAgICAgICAgICAgIG1bJ1x4YTljbXQnXSA9
:::IFt1cmxdCiAgICAgICAgICAgICMgLS0gY2FyYXR1bGE6IGRlc2RlIHYyLjcgbGEg
:::ZXNjcmliZSBTSUVNUFJFIGVzdGUgcGFzZSBjb24KICAgICAgICAgICAgIyAgICBt
:::dXRhZ2VuIChFbWJlZFRodW1ibmFpbCB5YSBubyBwYXJ0aWNpcGEpLiBBdG9tbwog
:::ICAgICAgICAgICAjICAgIGVzdGFuZGFyICdjb3ZyJyAoc2luIGVsIHByZWZpam8g
:::KGMpKTsgZW4gbXV0YWdlbgogICAgICAgICAgICAjICAgIG1vZGVybm8gZXNjcmli
:::aXIgJ1x4YTljb3ZyJyBsYW56YSBUeXBlRXJyb3IuCiAgICAgICAgICAgIHZpZWph
:::cyA9IG0uZ2V0KCdjb3ZyJykgb3IgbS5nZXQoJ1x4YTljb3ZyJykgb3IgW10KICAg
:::ICAgICAgICAgaWYgbm90IHZpZWphczoKICAgICAgICAgICAgICAgIGlmIGNhcmF0
:::dWxhOgogICAgICAgICAgICAgICAgICAgIG1bJ2NvdnInXSA9IFtNUDRDb3Zlcihj
:::YXJhdHVsYSwgTVA0Q292ZXIuRk9STUFUX0pQRUcpXQogICAgICAgICAgICBlbGlm
:::IGFsbChjLmltYWdlZm9ybWF0ICE9IE1QNENvdmVyLkZPUk1BVF9KUEVHCiAgICAg
:::ICAgICAgICAgICAgICAgIGZvciBjIGluIHZpZWphcyk6CiAgICAgICAgICAgICAg
:::ICBudWV2YSA9IF9hX2pwZyhieXRlcyh2aWVqYXNbMF0pKSBvciBjYXJhdHVsYQog
:::ICAgICAgICAgICAgICAgaWYgbnVldmE6CiAgICAgICAgICAgICAgICAgICAgbVsn
:::Y292ciddID0gW01QNENvdmVyKG51ZXZhLCBNUDRDb3Zlci5GT1JNQVRfSlBFRyld
:::CiAgICAgICAgICAgICAgICAgICAgbS5wb3AoJ1x4YTljb3ZyJywgTm9uZSkKICAg
:::ICAgICAgICAgZWxpZiBtLmdldCgnXHhhOWNvdnInKToKICAgICAgICAgICAgICAg
:::IG1bJ2NvdnInXSA9IHZpZWphcwogICAgICAgICAgICAgICAgbS5wb3AoJ1x4YTlj
:::b3ZyJywgTm9uZSkKICAgICAgICAgICAgbS5zYXZlKCkKICAgICAgICBlbGlmIGV4
:::dCA9PSAnLm1wMyc6CiAgICAgICAgICAgICMgRm9ybWF0byBFWEFDVE8gZGVsIE1Q
:::MyBkZSByZWZlcmVuY2lhIChTbmFwdHViZSwgZXNjcml0byBwb3IKICAgICAgICAg
:::ICAgIyBGRm1wZWcvTGF2ZikgcXVlIGVsIHJlcHJvZHVjdG9yIGRlbCB1c3Vhcmlv
:::IFNJIG11ZXN0cmE6CiAgICAgICAgICAgICMgICBJRDN2Mi40LjAgKyBUSVQyL1RQ
:::RTEvVEFMQi9BUElDIGVuIGVuY29kaW5nPTEgKFVURi0xNiBjb24KICAgICAgICAg
:::ICAgIyAgIEJPTSkgKyBBUElDKG1pbWUgJ2ltYWdlL2pwZycsIHRpcG8gMyA9IENP
:::VkVSX0ZST05ULCBkZXNjCiAgICAgICAgICAgICMgICAnYXR0YWNoZWQgcGljdHVy
:::ZScsIEpQRUcgcmVhbCkuIEVsIHBhc2UgYW50ZXJpb3IgZXNjcmliaWEKICAgICAg
:::ICAgICAgIyAgIGVuY29kaW5nPTMgKFVURi04KSBkZW50cm8gZGUgdW4gdGFnIHYy
:::LjM6IGZ1ZXJhIGRlCiAgICAgICAgICAgICMgICBlc3BlY2lmaWNhY2lvbiwgeSBs
:::b3MgcmVwcm9kdWN0b3JlcyBiYXJhdG9zIGRlc2NhcnRhYmFuCiAgICAgICAgICAg
:::ICMgICBsYSBldGlxdWV0YSBlbnRlcmEgKG5pIGFydGlzdGEsIG5pIGFsYnVtLCBu
:::aSBwb3J0YWRhKS4KICAgICAgICAgICAgZnJvbSBtdXRhZ2VuLmlkMyBpbXBvcnQg
:::KEFQSUMsIENPTU0sIElEMywgVEFMQiwgVERSQywgVElUMiwKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgIFRMRU4sIFRQRTEsIFRQRTIpCiAgICAg
:::ICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHRhZ3MgPSBJRDMoc3RyKHApKQog
:::ICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICAgICAgdGFn
:::cyA9IElEMygpCiAgICAgICAgICAgIGlmIHRpdHVsbzoKICAgICAgICAgICAgICAg
:::IHRhZ3Muc2V0YWxsKCdUSVQyJywgW1RJVDIoZW5jb2Rpbmc9MSwgdGV4dD1bdGl0
:::dWxvXSldKQogICAgICAgICAgICBpZiBhcnRpc3RhOgogICAgICAgICAgICAgICAg
:::dGFncy5zZXRhbGwoJ1RQRTEnLCBbVFBFMShlbmNvZGluZz0xLCB0ZXh0PVthcnRp
:::c3RhXSldKQogICAgICAgICAgICAgICAgdGFncy5zZXRhbGwoJ1RQRTInLCBbVFBF
:::MihlbmNvZGluZz0xLCB0ZXh0PVthcnRpc3RhXSldKQogICAgICAgICAgICBpZiBh
:::bGJ1bToKICAgICAgICAgICAgICAgIHRhZ3Muc2V0YWxsKCdUQUxCJywgW1RBTEIo
:::ZW5jb2Rpbmc9MSwgdGV4dD1bYWxidW1dKV0pCiAgICAgICAgICAgIGlmIGZlY2hh
:::OgogICAgICAgICAgICAgICAgdGFncy5zZXRhbGwoJ1REUkMnLCBbVERSQyhlbmNv
:::ZGluZz0xLCB0ZXh0PVtmZWNoYV0pXSkKICAgICAgICAgICAgZHVyID0gaW5mby5n
:::ZXQoJ2R1cmF0aW9uJykKICAgICAgICAgICAgaWYgZHVyOgogICAgICAgICAgICAg
:::ICAgdHJ5OgogICAgICAgICAgICAgICAgICAgIHRhZ3Muc2V0YWxsKCdUTEVOJywg
:::W1RMRU4oZW5jb2Rpbmc9MCwgdGV4dD1bCiAgICAgICAgICAgICAgICAgICAgICAg
:::IHN0cihpbnQoZmxvYXQoZHVyKSAqIDEwMDApKV0pXSkKICAgICAgICAgICAgICAg
:::IGV4Y2VwdCAoVHlwZUVycm9yLCBWYWx1ZUVycm9yKToKICAgICAgICAgICAgICAg
:::ICAgICBwYXNzCiAgICAgICAgICAgIGlmIHVybDoKICAgICAgICAgICAgICAgIHRh
:::Z3Muc2V0YWxsKCdDT01NJywgW0NPTU0oZW5jb2Rpbmc9MSwgbGFuZz0nZW5nJywK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGVzYz0n
:::JywgdGV4dD1bdXJsXSldKQogICAgICAgICAgICAjIFBvcnRhZGE6IG1pc21hcyBj
:::b25zdGFudGVzIGRlbCBhcmNoaXZvIGRlIHJlZmVyZW5jaWEuCiAgICAgICAgICAg
:::ICMgQnl0ZXM6IGBjYXJhdHVsYWAgbywgc2kgRW1iZWRUaHVtYm5haWwgeWEgaW5j
:::cnVzdG8gYWxnbywKICAgICAgICAgICAgIyBsb3MgZGF0b3MgZGVsIEFQSUMgZXhp
:::c3RlbnRlOyBzaWVtcHJlIGFjYWJhbW9zIGVuIEpQRUcuCiAgICAgICAgICAgIGRh
:::dG9zID0gY2FyYXR1bGEKICAgICAgICAgICAgaWYgbm90IGRhdG9zOgogICAgICAg
:::ICAgICAgICAgYXBpY3MgPSB0YWdzLmdldGFsbCgnQVBJQycpCiAgICAgICAgICAg
:::ICAgICBpZiBhcGljczoKICAgICAgICAgICAgICAgICAgICBkYXRvcyA9IGFwaWNz
:::WzBdLmRhdGEKICAgICAgICAgICAgaWYgZGF0b3MgYW5kIG5vdCBfZXNfanBnKGRh
:::dG9zKToKICAgICAgICAgICAgICAgIGRhdG9zID0gX2FfanBnKGRhdG9zKQogICAg
:::ICAgICAgICBpZiBkYXRvczoKICAgICAgICAgICAgICAgIHRhZ3Muc2V0YWxsKCdB
:::UElDJywgW0FQSUMoZW5jb2Rpbmc9MSwgbWltZT0naW1hZ2UvanBnJywKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZT0zLCBkZXNj
:::PSdhdHRhY2hlZCBwaWN0dXJlJywKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgZGF0YT1kYXRvcyldKQogICAgICAgICAgICAjIHYyLjQg
:::KyBVVEYtMTY6IGxhIG1pc21hIGNvbWJpbmFjaW9uIGRlbCBhcmNoaXZvIGRlCiAg
:::ICAgICAgICAgICMgcmVmZXJlbmNpYSAoSUQzdjIuNC4wIGVzY3JpdG8gcG9yIExh
:::dmY2MC4zLjEwMCkuCiAgICAgICAgICAgIHRhZ3Muc2F2ZShzdHIocCksIHYyX3Zl
:::cnNpb249NCkKICAgICAgICBlbGlmIGV4dCA9PSAnLndhdic6CiAgICAgICAgICAg
:::IGZyb20gbXV0YWdlbi5pZDMgaW1wb3J0IChBUElDLCBDT01NLCBURFJDLCBUSVQy
:::LCBUTEVOLCBUUEUxLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgVFBFMiwgVEFMQikKICAgICAgICAgICAgZnJvbSBtdXRhZ2VuLndhdmUgaW1w
:::b3J0IFdBVkUKICAgICAgICAgICAgdyA9IFdBVkUoc3RyKHApKQogICAgICAgICAg
:::ICBpZiB3LnRhZ3MgaXMgTm9uZToKICAgICAgICAgICAgICAgIHcuYWRkX3RhZ3Mo
:::KQogICAgICAgICAgICAjIGVuY29kaW5nPTEgKFVURi0xNiksIG1pc21hIHJlZ2xh
:::IHF1ZSBlbiBNUDM6IGxvcwogICAgICAgICAgICAjIHJlcHJvZHVjdG9yZXMgYmFy
:::YXRvcyBubyBwYXJzZWFuIGZyYW1lcyBVVEYtOC4KICAgICAgICAgICAgaWYgdGl0
:::dWxvOgogICAgICAgICAgICAgICAgdy50YWdzLnNldGFsbCgnVElUMicsIFtUSVQy
:::KGVuY29kaW5nPTEsIHRleHQ9W3RpdHVsb10pXSkKICAgICAgICAgICAgaWYgYXJ0
:::aXN0YToKICAgICAgICAgICAgICAgIHcudGFncy5zZXRhbGwoJ1RQRTEnLCBbVFBF
:::MShlbmNvZGluZz0xLCB0ZXh0PVthcnRpc3RhXSldKQogICAgICAgICAgICAgICAg
:::dy50YWdzLnNldGFsbCgnVFBFMicsIFtUUEUyKGVuY29kaW5nPTEsIHRleHQ9W2Fy
:::dGlzdGFdKV0pCiAgICAgICAgICAgIGlmIGFsYnVtOgogICAgICAgICAgICAgICAg
:::dy50YWdzLnNldGFsbCgnVEFMQicsIFtUQUxCKGVuY29kaW5nPTEsIHRleHQ9W2Fs
:::YnVtXSldKQogICAgICAgICAgICBpZiBmZWNoYToKICAgICAgICAgICAgICAgIHcu
:::dGFncy5zZXRhbGwoJ1REUkMnLCBbVERSQyhlbmNvZGluZz0xLCB0ZXh0PVtmZWNo
:::YV0pXSkKICAgICAgICAgICAgZHVyID0gaW5mby5nZXQoJ2R1cmF0aW9uJykKICAg
:::ICAgICAgICAgaWYgZHVyOgogICAgICAgICAgICAgICAgdHJ5OgogICAgICAgICAg
:::ICAgICAgICAgIHcudGFncy5zZXRhbGwoJ1RMRU4nLCBbVExFTihlbmNvZGluZz0w
:::LCB0ZXh0PVsKICAgICAgICAgICAgICAgICAgICAgICAgc3RyKGludChmbG9hdChk
:::dXIpICogMTAwMCkpXSldKQogICAgICAgICAgICAgICAgZXhjZXB0IChUeXBlRXJy
:::b3IsIFZhbHVlRXJyb3IpOgogICAgICAgICAgICAgICAgICAgIHBhc3MKICAgICAg
:::ICAgICAgaWYgdXJsOgogICAgICAgICAgICAgICAgdy50YWdzLnNldGFsbCgnQ09N
:::TScsIFtDT01NKGVuY29kaW5nPTEsIGxhbmc9J2VuZycsCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGVzYz0nJywgdGV4dD1bdXJs
:::XSldKQogICAgICAgICAgICAjIHYyLjc6IGNhcmF0dWxhIGVuIGVsIElEMyBkZWwg
:::V0FWIChtaXNtYXMgY29uc3RhbnRlcyBxdWUKICAgICAgICAgICAgIyBlbCBNUDMg
:::ZGUgcmVmZXJlbmNpYSksIHBhcmEgbG9zIHJlcHJvZHVjdG9yZXMgcXVlIGxlZW4K
:::ICAgICAgICAgICAgIyBlbCBjaHVuayAnaWQzICcgZGVudHJvIGRlbCBSSUZGLgog
:::ICAgICAgICAgICBkYXRvcyA9IGNhcmF0dWxhCiAgICAgICAgICAgIGlmIG5vdCBk
:::YXRvczoKICAgICAgICAgICAgICAgIGFwaWNzID0gdy50YWdzLmdldGFsbCgnQVBJ
:::QycpCiAgICAgICAgICAgICAgICBpZiBhcGljczoKICAgICAgICAgICAgICAgICAg
:::ICBkYXRvcyA9IGFwaWNzWzBdLmRhdGEKICAgICAgICAgICAgaWYgZGF0b3MgYW5k
:::IG5vdCBfZXNfanBnKGRhdG9zKToKICAgICAgICAgICAgICAgIGRhdG9zID0gX2Ff
:::anBnKGRhdG9zKQogICAgICAgICAgICBpZiBkYXRvczoKICAgICAgICAgICAgICAg
:::IHcudGFncy5zZXRhbGwoJ0FQSUMnLCBbQVBJQyhlbmNvZGluZz0xLCBtaW1lPSdp
:::bWFnZS9qcGcnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgIHR5cGU9MywgZGVzYz0nYXR0YWNoZWQgcGljdHVyZScsCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZGF0YT1kYXRvcyld
:::KQogICAgICAgICAgICB3LnNhdmUoKQogICAgICAgIGVsaWYgZXh0ID09ICcuZmxh
:::Yyc6CiAgICAgICAgICAgIGZyb20gbXV0YWdlbi5mbGFjIGltcG9ydCBGTEFDLCBQ
:::aWN0dXJlCiAgICAgICAgICAgIGYgPSBGTEFDKHN0cihwKSkKICAgICAgICAgICAg
:::aWYgdGl0dWxvOgogICAgICAgICAgICAgICAgZlsndGl0bGUnXSA9IFt0aXR1bG9d
:::CiAgICAgICAgICAgIGlmIGFydGlzdGE6CiAgICAgICAgICAgICAgICBmWydhcnRp
:::c3QnXSA9IFthcnRpc3RhXQogICAgICAgICAgICAgICAgZlsnYWxidW1hcnRpc3Qn
:::XSA9IFthcnRpc3RhXQogICAgICAgICAgICBpZiBhbGJ1bToKICAgICAgICAgICAg
:::ICAgIGZbJ2FsYnVtJ10gPSBbYWxidW1dCiAgICAgICAgICAgIGlmIGZlY2hhOgog
:::ICAgICAgICAgICAgICAgZlsnZGF0ZSddID0gW2ZlY2hhXQogICAgICAgICAgICBp
:::ZiB1cmw6CiAgICAgICAgICAgICAgICBmWydjb21tZW50J10gPSBbdXJsXQogICAg
:::ICAgICAgICBpZiBub3QgZi5waWN0dXJlczoKICAgICAgICAgICAgICAgIGlmIGNh
:::cmF0dWxhOgogICAgICAgICAgICAgICAgICAgIHBpYyA9IFBpY3R1cmUoKQogICAg
:::ICAgICAgICAgICAgICAgIHBpYy5taW1lLCBwaWMudHlwZSwgcGljLmRlc2MgPSAn
:::aW1hZ2UvanBlZycsIDMsICdDb3ZlcicKICAgICAgICAgICAgICAgICAgICBwaWMu
:::ZGF0YSA9IGNhcmF0dWxhCiAgICAgICAgICAgICAgICAgICAgZi5hZGRfcGljdHVy
:::ZShwaWMpCiAgICAgICAgICAgIGVsaWYgYWxsKHBpLm1pbWUgIT0gJ2ltYWdlL2pw
:::ZWcnIGZvciBwaSBpbiBmLnBpY3R1cmVzKToKICAgICAgICAgICAgICAgIG51ZXZh
:::ID0gX2FfanBnKGYucGljdHVyZXNbMF0uZGF0YSkgb3IgY2FyYXR1bGEKICAgICAg
:::ICAgICAgICAgIGlmIG51ZXZhOgogICAgICAgICAgICAgICAgICAgIGZvciB2aWVq
:::YSBpbiBsaXN0KGYucGljdHVyZXMpOgogICAgICAgICAgICAgICAgICAgICAgICBm
:::LnJlbW92ZV9waWN0dXJlKHZpZWphKQogICAgICAgICAgICAgICAgICAgIHBpYyA9
:::IFBpY3R1cmUoKQogICAgICAgICAgICAgICAgICAgIHBpYy5taW1lLCBwaWMudHlw
:::ZSwgcGljLmRlc2MgPSAnaW1hZ2UvanBlZycsIDMsICdDb3ZlcicKICAgICAgICAg
:::ICAgICAgICAgICBwaWMuZGF0YSA9IG51ZXZhCiAgICAgICAgICAgICAgICAgICAg
:::Zi5hZGRfcGljdHVyZShwaWMpCiAgICAgICAgICAgIGYuc2F2ZSgpCiAgICAgICAg
:::ZWxpZiBleHQgPT0gJy53bWEnOgogICAgICAgICAgICBmcm9tIG11dGFnZW4uYXNm
:::IGltcG9ydCBBU0YsIEFTRkJ5dGVBcnJheUF0dHJpYnV0ZQogICAgICAgICAgICBh
:::ID0gQVNGKHN0cihwKSkKICAgICAgICAgICAgaWYgdGl0dWxvOgogICAgICAgICAg
:::ICAgICAgYVsnVGl0bGUnXSA9IFt0aXR1bG9dCiAgICAgICAgICAgIGlmIGFydGlz
:::dGE6CiAgICAgICAgICAgICAgICBhWydBdXRob3InXSA9IFthcnRpc3RhXQogICAg
:::ICAgICAgICAgICAgYVsnV00vQWxidW1BcnRpc3QnXSA9IFthcnRpc3RhXQogICAg
:::ICAgICAgICBpZiBhbGJ1bToKICAgICAgICAgICAgICAgIGFbJ1dNL0FsYnVtVGl0
:::bGUnXSA9IFthbGJ1bV0KICAgICAgICAgICAgaWYgZmVjaGE6CiAgICAgICAgICAg
:::ICAgICBhWydXTS9ZZWFyJ10gPSBbZmVjaGFdCiAgICAgICAgICAgIGlmIHVybDoK
:::ICAgICAgICAgICAgICAgIGFbJ0Rlc2NyaXB0aW9uJ10gPSBbdXJsXQogICAgICAg
:::ICAgICAgICAgYVsnV00vQXV0aG9yVVJMJ10gPSBbdXJsXQogICAgICAgICAgICBp
:::ZiBjYXJhdHVsYToKICAgICAgICAgICAgICAgIGFbJ1dNL1BpY3R1cmUnXSA9IFtB
:::U0ZCeXRlQXJyYXlBdHRyaWJ1dGUoCiAgICAgICAgICAgICAgICAgICAgX3dtX3Bp
:::Y3R1cmUoY2FyYXR1bGEsIHRpdHVsbyBvciAnQ292ZXInKSldCiAgICAgICAgICAg
:::IGEuc2F2ZSgpCiAgICAgICAgZWxzZToKICAgICAgICAgICAgcmV0dXJuCiAgICAg
:::ICAgaWYgbG9nOgogICAgICAgICAgICBleHRyYSA9ICcgwrcgY2Fyw6F0dWxhIEpQ
:::RUcnIGlmIGNhcmF0dWxhIGVsc2UgJycKICAgICAgICAgICAgbG9nKCdFdGlxdWV0
:::YXMgZXNjcml0YXM6IGFydGlzdGEgwqslc8K7IMK3IMOhbGJ1bSDCqyVzwrslcycK
:::ICAgICAgICAgICAgICAgICUgKGFydGlzdGEgb3IgJ+KAlCcsIGFsYnVtIG9yICfi
:::gJQnLCBleHRyYSksICdncmlzJykKICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZToK
:::ICAgICAgICAjIGxhcyBldGlxdWV0YXMgbm8gc29uIGNyaXRpY2FzOiBudW5jYSBk
:::ZWJlbiByb21wZXIgbGEgZGVzY2FyZ2EKICAgICAgICBpZiBsb2c6CiAgICAgICAg
:::ICAgIGxvZygnTm8gc2UgcHVkaWVyb24gZXNjcmliaXIgdG9kYXMgbGFzIGV0aXF1
:::ZXRhczogJXMnICUgZSwKICAgICAgICAgICAgICAgICdhdmlzbycpCgoKIyAtLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tIGRlc2NhcmdhcwpkZWYgZGVzY2FyZ2FyX2F1ZGlvKHVybCwg
:::bm9tYnJlX2ZtdCwgY2FsaWRhZCwgZGVzdGlubywgZW1iZWJlciwgY29sYSk6CiAg
:::ICAiIiJBQUMgKC5tNGEpIC8gTVAzIC8gRkxBQyAvIFdBViB2w61hIHBvc3Rwcm9j
:::ZXNhZG9yZXMgZGUgeXQtZGxwLgoKICAgIHl0LWRscCBTT0xPIGJhamEsIGNvbnZp
:::ZXJ0ZSB5IGVzY3JpYmUgbG9zIG1ldGFkYXRvcyBkZSB0ZXh0bwogICAgKEZGbXBl
:::Z01ldGFkYXRhKS4gTGEgY2Fyw6F0dWxhIE5PIGxhIGluY3J1c3RhIEVtYmVkVGh1
:::bWJuYWlsOiBkZXNkZQogICAgdjIuNyBsYSBlc2NyaWJlIGFwbGljYXJfdGFncyBj
:::b24gbXV0YWdlbiAoY292ciBlbiBtNGEsIEFQSUMgZW4KICAgIG1wMy93YXYsIFBp
:::Y3R1cmUgZW4gZmxhYyksIHNpZW1wcmUgZW4gSlBFRyB5IGNvbiBsYSBlc3RydWN0
:::dXJhCiAgICBleGFjdGEgcXVlIGxlZW4gbG9zIHJlcHJvZHVjdG9yZXMuIEFzw60g
:::ZWwgcmVzdWx0YWRvIG5vIGRlcGVuZGUgZGUKICAgIGxvcyBtw6l0b2RvcyBpbnRl
:::cm5vcyBkZSBFbWJlZFRodW1ibmFpbCwgcXVlIGNhbWJpYW4gZW50cmUKICAgIHZl
:::cnNpb25lcyBkZSB5dC1kbHAgKGFudGVzIGNvbnZlcnTDrWEgbGEgcG9ydGFkYSBh
:::IFBORywgeSBzdQogICAgbcOpdG9kbyBmZm1wZWcgYWRqdW50YSBsYSBpbWFnZW4g
:::Y29tbyBzdHJlYW0gZGUgdsOtZGVvKS4iIiIKICAgIGRlZiBsb2cobSwgdD0naW5m
:::bycpOgogICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgZm10ID0g
:::Rk9STUFUT1Nbbm9tYnJlX2ZtdF0KICAgIGNhcnBldGEgPSBkZXN0aW5vICAgICAg
:::ICAgICMgdjIuMzogc2luIHN1YmNhcnBldGFzIHBvciBmb3JtYXRvCiAgICBjYXJw
:::ZXRhLm1rZGlyKHBhcmVudHM9VHJ1ZSwgZXhpc3Rfb2s9VHJ1ZSkKICAgIGNvZGVj
:::ID0gZm10WydleHQnXQogICAgY29uX3BvcnRhZGEgPSBlbWJlYmVyIGFuZCBub21i
:::cmVfZm10IGluICgnQUFDJywgJ01QMycsICdGTEFDJywgJ1dBVicpCiAgICBjb25f
:::dGFncyA9IGVtYmViZXIKICAgIHBwcyA9IFtdCiAgICBpZiBjb25fcG9ydGFkYToK
:::ICAgICAgICBwcHMuYXBwZW5kKHsna2V5JzogJ0ZGbXBlZ1RodW1ibmFpbHNDb252
:::ZXJ0b3InLCAnZm9ybWF0JzogJ2pwZycsCiAgICAgICAgICAgICAgICAgICAgJ3do
:::ZW4nOiAnYmVmb3JlX2RsJ30pCiAgICBwcHMuYXBwZW5kKHsna2V5JzogJ0ZGbXBl
:::Z0V4dHJhY3RBdWRpbycsICdwcmVmZXJyZWRjb2RlYyc6IGNvZGVjLAogICAgICAg
:::ICAgICAgICAgJ3ByZWZlcnJlZHF1YWxpdHknOiBjYWxpZGFkIG9yICcwJ30pCiAg
:::ICBpZiBjb25fdGFnczoKICAgICAgICBwcHMuYXBwZW5kKHsna2V5JzogJ0ZGbXBl
:::Z01ldGFkYXRhJywgJ2FkZF9tZXRhZGF0YSc6IFRydWV9KQogICAgIyB2Mi43OiBT
:::SU4gRW1iZWRUaHVtYm5haWwuIExhIG1pbmlhdHVyYSAoZGVqYWRhIGVuIC5qcGcg
:::anVudG8gYWwKICAgICMgYXJjaGl2byBwb3Igd3JpdGV0aHVtYm5haWwgKyBDb252
:::ZXJ0b3IpIGxhIGluY3J1c3RhIGFwbGljYXJfdGFncwogICAgIyBjb24gbXV0YWdl
:::bjogZXN0cnVjdHVyYSBnYXJhbnRpemFkYSBlbiB0b2RvcyBsb3MgZm9ybWF0b3Mg
:::eSBzaW4KICAgICMgZGVwZW5kZXIgZGUgbG9zIG3DqXRvZG9zIGludGVybm9zIGRl
:::IHl0LWRscC4KICAgIG8gPSBvcHRzX2Jhc2UoY2FycGV0YSwgY29sYSkKICAgIG9b
:::J2Zvcm1hdCddID0gJ2Jlc3RhdWRpby9iZXN0JwogICAgb1sncG9zdHByb2Nlc3Nv
:::cnMnXSA9IHBwcwogICAgb1snd3JpdGV0aHVtYm5haWwnXSA9IGNvbl9wb3J0YWRh
:::CiAgICB3aXRoIFlUX0RMUC5Zb3V0dWJlREwobykgYXMgeWRsOgogICAgICAgIGlu
:::Zm8gPSB5ZGwuZXh0cmFjdF9pbmZvKHVybCwgZG93bmxvYWQ9VHJ1ZSkKICAgIGFy
:::Y2hpdm8gPSBhcmNoaXZvX2ZpbmFsKGluZm8sIGNhcnBldGEsIGNvZGVjKQogICAg
:::Y2FyYXR1bGEgPSBfbWluaWF0dXJhX2J5dGVzKGNhcnBldGEsIGFyY2hpdm8pCiAg
:::ICBpZiBhcmNoaXZvIGFuZCBjb25fcG9ydGFkYToKICAgICAgICBsaW1waWFyX21p
:::bmlhdHVyYXMoY2FycGV0YSwgYXJjaGl2bykKICAgIGlmIGFyY2hpdm86CiAgICAg
:::ICAgYXBsaWNhcl90YWdzKGluZm8sIGFyY2hpdm8sIGxvZywgY2FyYXR1bGEpCiAg
:::ICByZXR1cm4gaW5mbywgYXJjaGl2bwoKCmRlZiBkZXNjYXJnYXJfd21hKHVybCwg
:::Y2FsaWRhZCwgZGVzdGlubywgZW1iZWJlciwgY29sYSk6CiAgICAiIiJXTUEgOTYv
:::MTI4IGticHM6IHl0LWRscCBubyBzb3BvcnRhIHdtYSwgYXPDrSBxdWUgc2UgYmFq
:::YSBhIFdBViAoY29uCiAgICBldGlxdWV0YXMpIHkgbHVlZ28gRkZtcGVnIHJlY29k
:::aWZpY2EgYSB3bWF2MiBkZW50cm8gZGVsIC53bWEgZmluYWwuCiAgICBMYSBjYXLD
:::oXR1bGEgKFdNL1BpY3R1cmUsIGVuIEpQRUcpIHkgbGEgVVJMIChXTS9BdXRob3JV
:::UkwpIHNlCiAgICBpbmNydXN0YW4gY29uIG11dGFnZW4sIGNvbW8gZW4gZWwgc2Ny
:::aXB0IGFudGlndW8uIiIiCiAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAg
:::ICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAgIGNhcnBldGEgPSBkZXN0aW5v
:::ICAgICAgICAgICMgdjIuMzogc2luIHN1YmNhcnBldGFzIHBvciBmb3JtYXRvCiAg
:::ICB0bXAgPSBjYXJwZXRhIC8gJ190bXAnCiAgICBzaHV0aWwucm10cmVlKHRtcCwg
:::aWdub3JlX2Vycm9ycz1UcnVlKQogICAgdG1wLm1rZGlyKHBhcmVudHM9VHJ1ZSwg
:::ZXhpc3Rfb2s9VHJ1ZSkKICAgIG8gPSBvcHRzX2Jhc2UodG1wLCBjb2xhKQogICAg
:::b1snZm9ybWF0J10gPSAnYmVzdGF1ZGlvL2Jlc3QnCiAgICBwcHMgPSBbeydrZXkn
:::OiAnRkZtcGVnRXh0cmFjdEF1ZGlvJywgJ3ByZWZlcnJlZGNvZGVjJzogJ3dhdics
:::CiAgICAgICAgICAgICdwcmVmZXJyZWRxdWFsaXR5JzogJzAnfV0KICAgIGlmIGVt
:::YmViZXI6CiAgICAgICAgcHBzLmluc2VydCgwLCB7J2tleSc6ICdGRm1wZWdUaHVt
:::Ym5haWxzQ29udmVydG9yJywKICAgICAgICAgICAgICAgICAgICAgICAnZm9ybWF0
:::JzogJ2pwZycsICd3aGVuJzogJ2JlZm9yZV9kbCd9KQogICAgICAgIHBwcy5hcHBl
:::bmQoeydrZXknOiAnRkZtcGVnTWV0YWRhdGEnLCAnYWRkX21ldGFkYXRhJzogVHJ1
:::ZX0pCiAgICBvWydwb3N0cHJvY2Vzc29ycyddID0gcHBzCiAgICBvWyd3cml0ZXRo
:::dW1ibmFpbCddID0gZW1iZWJlcgogICAgd2l0aCBZVF9ETFAuWW91dHViZURMKG8p
:::IGFzIHlkbDoKICAgICAgICBpbmZvID0geWRsLmV4dHJhY3RfaW5mbyh1cmwsIGRv
:::d25sb2FkPVRydWUpCiAgICB3YXYgPSBhcmNoaXZvX2ZpbmFsKGluZm8sIHRtcCwg
:::J3dhdicpCiAgICBpZiBub3Qgd2F2OgogICAgICAgIHJhaXNlIFJ1bnRpbWVFcnJv
:::cignTm8gc2UgZW5jb250csOzIGVsIFdBViBpbnRlcm1lZGlvLicpCiAgICBtZXRh
:::ID0gW10KICAgIGlmIGVtYmViZXI6CiAgICAgICAgYXJ0aXN0YSA9IChpbmZvLmdl
:::dCgnYXJ0aXN0Jykgb3IgaW5mby5nZXQoJ3VwbG9hZGVyJykKICAgICAgICAgICAg
:::ICAgICAgIG9yIGluZm8uZ2V0KCdjaGFubmVsJykgb3IgJycpCiAgICAgICAgaWYg
:::aW5mby5nZXQoJ3RpdGxlJyk6CiAgICAgICAgICAgIG1ldGEgKz0gWyctbWV0YWRh
:::dGEnLCAndGl0bGU9JyArIHN0cihpbmZvWyd0aXRsZSddKV0KICAgICAgICBpZiBh
:::cnRpc3RhOgogICAgICAgICAgICBtZXRhICs9IFsnLW1ldGFkYXRhJywgJ2FydGlz
:::dD0nICsgc3RyKGFydGlzdGEpXQogICAgd21hID0gY2FycGV0YSAvIChsaW1waWFy
:::X25vbWJyZShpbmZvLmdldCgndGl0bGUnKSBvciAnYXVkaW8nKSArICcud21hJykK
:::ICAgIGNtZCA9IFtzdHIoRkZNUEVHKSwgJy15JywgJy1pJywgc3RyKHdhdiksICct
:::dm4nLAogICAgICAgICAgICctYzphJywgJ3dtYXYyJywgJy1iOmEnLCBmJ3tjYWxp
:::ZGFkfWsnXSArIG1ldGEgKyBbc3RyKHdtYSldCiAgICBvayA9IGNvbnZlcnRpcl9m
:::Zm1wZWcoCiAgICAgICAgY21kLCBmJ0NvbnZpcnRpZW5kbyBhIFdNQSAod21hdjIg
:::wrcge2NhbGlkYWR9IGticHMpJywgY29sYSkKICAgIGlmIG5vdCBvazoKICAgICAg
:::ICByYWlzZSBSdW50aW1lRXJyb3IoJ0ZGbXBlZyBubyBwdWRvIGNyZWFyIGVsIGFy
:::Y2hpdm8gV01BLicpCiAgICBjYXJhdHVsYSA9IE5vbmUKICAgIGlmIGVtYmViZXI6
:::CiAgICAgICAganBncyA9IHNvcnRlZCh0bXAuZ2xvYignKi5qcGcnKSwKICAgICAg
:::ICAgICAgICAgICAgICAgIGtleT1sYW1iZGEgcTogcS5zdGF0KCkuc3RfbXRpbWUs
:::IHJldmVyc2U9VHJ1ZSkKICAgICAgICBpZiBqcGdzOgogICAgICAgICAgICB0cnk6
:::CiAgICAgICAgICAgICAgICBjYXJhdHVsYSA9IGpwZ3NbMF0ucmVhZF9ieXRlcygp
:::CiAgICAgICAgICAgIGV4Y2VwdCBPU0Vycm9yOgogICAgICAgICAgICAgICAgY2Fy
:::YXR1bGEgPSBOb25lCiAgICBhcGxpY2FyX3RhZ3MoaW5mbywgd21hLCBsb2csIGNh
:::cmF0dWxhKQogICAgc2h1dGlsLnJtdHJlZSh0bXAsIGlnbm9yZV9lcnJvcnM9VHJ1
:::ZSkKICAgIHJldHVybiBpbmZvLCB3bWEKCgpkZWYgbWV0YV9yaWZmX2luZm8oaW5m
:::byk6CiAgICAiIiJ2Mi43OiBhcmd1bWVudG9zIC1tZXRhZGF0YSBwYXJhIGxvcyB0
:::YWdzIFJJRkYgSU5GTyBkZWwgQVZJLgoKICAgIEZGbXBlZyBsb3MgbWFwZWEgYSBJ
:::TkFNICh0aXR1bG8pLCBJQVJUIChhcnRpc3RhKSwgSVBSRCAoYWxidW0pLAogICAg
:::SUNSRCAoZmVjaGEpIGUgSUNNVCAoY29tZW50YXJpbykgZGVudHJvIGRlbCBjaHVu
:::ayBMSVNUL0lORk8gZGVsCiAgICBSSUZGLCBxdWUgZXMgZG9uZGUgbG9zIHJlcHJv
:::ZHVjdG9yZXMgYnVzY2FuIGxvcyBkYXRvcyBkZSB1biBBVkkuIiIiCiAgICB0aXR1
:::bG8gPSBzdHIoaW5mby5nZXQoJ3RyYWNrJykgb3IgaW5mby5nZXQoJ3RpdGxlJykg
:::b3IgJycpLnN0cmlwKCkKICAgIGFydGlzdGEgPSBfYXJ0aXN0YV9saW1waW8oaW5m
:::bykKICAgIGFsYnVtID0gX2FsYnVtX2RlKGluZm8pCiAgICBmZWNoYSA9IHN0cihp
:::bmZvLmdldCgncmVsZWFzZV95ZWFyJykgb3IgJycpCiAgICBpZiBub3QgZmVjaGE6
:::CiAgICAgICAgZmVjaGEgPSBzdHIoaW5mby5nZXQoJ3VwbG9hZF9kYXRlJykgb3Ig
:::JycpWzo0XQogICAgdXJsID0gc3RyKGluZm8uZ2V0KCd3ZWJwYWdlX3VybCcpIG9y
:::ICcnKS5zdHJpcCgpCiAgICBtZXRhID0gW10KICAgIGlmIHRpdHVsbzoKICAgICAg
:::ICBtZXRhICs9IFsnLW1ldGFkYXRhJywgJ3RpdGxlPScgKyB0aXR1bG9dCiAgICBp
:::ZiBhcnRpc3RhOgogICAgICAgIG1ldGEgKz0gWyctbWV0YWRhdGEnLCAnYXJ0aXN0
:::PScgKyBhcnRpc3RhXQogICAgaWYgYWxidW06CiAgICAgICAgbWV0YSArPSBbJy1t
:::ZXRhZGF0YScsICdhbGJ1bT0nICsgYWxidW1dCiAgICBpZiBmZWNoYToKICAgICAg
:::ICBtZXRhICs9IFsnLW1ldGFkYXRhJywgJ2RhdGU9JyArIGZlY2hhXQogICAgaWYg
:::dXJsOgogICAgICAgIG1ldGEgKz0gWyctbWV0YWRhdGEnLCAnY29tbWVudD0nICsg
:::dXJsXQogICAgcmV0dXJuIG1ldGEKCgojIFBhcsOhbWV0cm9zIG9maWNpYWxlcyBk
:::ZWwgcmVwbyBmZGQ0cy9wb3J0YWJsZV9tcDNfcGxheWVyX3ZpZGVvX2NvbnZlcnRl
:::cl90b29scwojICh2aWRlbzJzaGVuanUxOC5zaCk6IE1KUEVHIDE2IGZwcyArIFBD
:::TSAyMjA1MCBIeiwgcm90YWRvcyBwYXJhIGxhIHBhbnRhbGxhCiMgdmVydGljYWwg
:::ZGUgMTI4eDE2MCBkZWwgcmVwcm9kdWN0b3Igc2hlaWp1IGRlIDEuOCBwdWxnYWRh
:::cy4KVkZfU0hFSUpVID0gJ3NjYWxlPS0yOjEyOCwgY3JvcD0xNjA6MTI4LCB0cmFu
:::c3Bvc2U9MiwgdmZsaXAnCiMgVmFyaWFudGUgYSBwcnVlYmEgZGUgYmFsYXMgcGFy
:::YSB2aWRlb3MgY3VhZHJhZG9zL3ZlcnRpY2FsZXMgKFNob3J0cyksCiMgZG9uZGUg
:::ZWwgcmVjb3J0ZSAxNjA6MTI4IG9yaWdpbmFsIHNlcsOtYSBpbXBvc2libGU6ClZG
:::X1NFR1VSTyA9ICgnc2NhbGU9MTYwOjEyODpmb3JjZV9vcmlnaW5hbF9hc3BlY3Rf
:::cmF0aW89ZGVjcmVhc2UsJwogICAgICAgICAgICAgJ3BhZD0xNjA6MTI4Oihvdy1p
:::dykvMjoob2gtaWgpLzIsdHJhbnNwb3NlPTIsdmZsaXAnKQoKCmRlZiBkZXNjYXJn
:::YXJfYXZpKHVybCwgZGVzdGlubywgY29sYSk6CiAgICAiIiJWaWRlbyBBVkkgcGFy
:::YSBlbCByZXByb2R1Y3RvciBzaGVpanUgMS44IiAxMjh4MTYwLiIiIgogICAgZGVm
:::IGxvZyhtLCB0PSdpbmZvJyk6CiAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0
:::KSkKCiAgICBjYXJwZXRhID0gZGVzdGlubyAgICAgICAgICAjIHYyLjM6IHNpbiBz
:::dWJjYXJwZXRhcyBwb3IgZm9ybWF0bwogICAgdG1wID0gY2FycGV0YSAvICdfdG1w
:::JwogICAgc2h1dGlsLnJtdHJlZSh0bXAsIGlnbm9yZV9lcnJvcnM9VHJ1ZSkKICAg
:::IHRtcC5ta2RpcihwYXJlbnRzPVRydWUsIGV4aXN0X29rPVRydWUpCiAgICBvID0g
:::b3B0c19iYXNlKHRtcCwgY29sYSkKICAgICMgUGFyYSB1bmEgcGFudGFsbGEgZGUg
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
:::bmZvLmdldCgndGl0bGUnKSBvciAndmlkZW8nKSArICcuYXZpJykKICAgICMgdjIu
:::NzogZXRpcXVldGFzIFJJRkYgSU5GTyBkZW50cm8gZGVsIEFWSSAodmVyIG1ldGFf
:::cmlmZl9pbmZvKQogICAgIyBwYXJhIHF1ZSBlbCB2aWRlbyB0YW1iaWVuIG11ZXN0
:::cmUgdGl0dWxvIHkgYXJ0aXN0YSBkb25kZSBlbAogICAgIyByZXByb2R1Y3RvciBz
:::ZXBhIGxlZXJsYXMuCiAgICBtZXRhID0gbWV0YV9yaWZmX2luZm8oaW5mbykKICAg
:::IGJhc2UgPSBbc3RyKEZGTVBFRyksICcteScsICctaScsIHN0cihvcmlnZW4pLCAn
:::LXInLCAnMTYnLAogICAgICAgICAgICAnLWFjb2RlYycsICdwY21fczE2bGUnLCAn
:::LWFjJywgJzInLCAnLWFyJywgJzIyMDUwJywKICAgICAgICAgICAgJy1waXhfZm10
:::JywgJ3l1dmo0MjBwJywgJy1jOnYnLCAnbWpwZWcnLCAnLXE6dicsICcyJ10gKyBt
:::ZXRhCiAgICBvayA9IGNvbnZlcnRpcl9mZm1wZWcoYmFzZSArIFsnLXZmJywgVkZf
:::U0hFSUpVLCBzdHIoYXZpKV0sCiAgICAgICAgICAgICAgICAgICAgICAgICAgJ0Nv
:::bnZpcnRpZW5kbyBhIEFWSSAxMjh4MTYwIChzaGVpanUgMS44IiknLCBjb2xhKQog
:::ICAgaWYgbm90IG9rOgogICAgICAgIGxvZygnVmlkZW8gY29uIHByb3BvcmNpw7Nu
:::IG5vIGVzdMOhbmRhcjsgJwogICAgICAgICAgICAncmVpbnRlbnRhbmRvIGVuIG1v
:::ZG8gY29tcGF0aWJsZS4uLicsICdhdmlzbycpCiAgICAgICAgb2sgPSBjb252ZXJ0
:::aXJfZmZtcGVnKGJhc2UgKyBbJy12ZicsIFZGX1NFR1VSTywgc3RyKGF2aSldLAog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAnUmVjb252aXJ0aWVuZG8gYSBB
:::VkkgMTI4eDE2MCcsIGNvbGEpCiAgICBpZiBub3Qgb2s6CiAgICAgICAgcmFpc2Ug
:::UnVudGltZUVycm9yKCdGRm1wZWcgbm8gcHVkbyBjcmVhciBlbCBhcmNoaXZvIEFW
:::SS4nKQogICAgc2h1dGlsLnJtdHJlZSh0bXAsIGlnbm9yZV9lcnJvcnM9VHJ1ZSkK
:::ICAgIHJldHVybiBpbmZvLCBhdmkKCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gZXN0aW1h
:::Y2nDs24KS0JQU19FU1RJTUFET1MgPSB7CiAgICAnQUFDJzogMTI4LCAgICAgIyB0
:::ZWNobyBkZWwgZm9ybWF0bwogICAgJ1dNQSc6IDEyOCwKICAgICdXQVYnOiAxNDEx
:::LCAgICAjIFBDTSA0NC4xIGtIeiDCtyAxNiBiaXQgwrcgZXN0w6lyZW8KICAgICdG
:::TEFDJzogOTUwLCAgICAjIHTDrXBpY28gZGUgbcO6c2ljYSBwcm9jZWRlbnRlIGRl
:::IFlvdVR1YmUKICAgICdBVkknOiAxNDkwLCAgICAjIH43ODQga2JwcyBNSlBFRyAx
:::NmZwcyArIDcwNiBrYnBzIFBDTSAyMjA1MCBlc3TDqXJlbwp9CgoKZGVmIGVzdGlt
:::YXJfYnl0ZXMoZHVyYWNpb25fcywgZm9ybWF0bywgY2FsaWRhZCwgZW1iZWJlcik6
:::CiAgICAiIiJFc3RpbWEgZWwgdGFtYcOxbyBmaW5hbCBlbiBieXRlcyAoY8OhbGN1
:::bG8gcHVybywgdGVzdGVhYmxlKS4iIiIKICAgIGlmIGZvcm1hdG8gaW4gKCdNUDMn
:::LCAnQUFDJywgJ1dNQScpOgogICAgICAgIGticHMgPSBpbnQocmUuc3ViKHInW14w
:::LTldJywgJycsIHN0cihjYWxpZGFkKSkgb3IgMCkKICAgICAgICBpZiBub3Qga2Jw
:::czoKICAgICAgICAgICAga2JwcyA9IEtCUFNfRVNUSU1BRE9TLmdldChmb3JtYXRv
:::LCAxMjgpCiAgICBlbHNlOgogICAgICAgIGticHMgPSBLQlBTX0VTVElNQURPUy5n
:::ZXQoZm9ybWF0bywgMTI4KQogICAgZXh0cmEgPSAxMjBfMDAwIGlmIChlbWJlYmVy
:::IGFuZCBmb3JtYXRvIGluICgnQUFDJywgJ01QMycsICdGTEFDJywKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ1dBVicpKSBl
:::bHNlIDAKICAgIHJldHVybiBkdXJhY2lvbl9zICoga2JwcyAqIDEwMDAgLyA4ICsg
:::ZXh0cmEKCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0gY2FsaWRhZApkZWYgY2xhc2VfY2Fs
:::aWRhZChleHQsIGticHMpOgogICAgIiIiQ2xhc2lmaWNhIHVuIGFyY2hpdm8uIERl
:::dnVlbHZlICh0ZXh0bywgbml2ZWwpIGNvbiBuaXZlbCAwPW9rIDE9bWVkaWEgMj1i
:::YWphLiIiIgogICAgaWYgZXh0ID09ICcubXAzJzoKICAgICAgICBpZiBrYnBzID49
:::IDMxNToKICAgICAgICAgICAgcmV0dXJuICczMjAga2JwcycsIDAKICAgICAgICBp
:::ZiBrYnBzID49IDI1MDoKICAgICAgICAgICAgcmV0dXJuICcyNTYga2JwcycsIDAK
:::ICAgICAgICBpZiBrYnBzID49IDE4NToKICAgICAgICAgICAgcmV0dXJuICcxOTIg
:::a2JwcycsIDAKICAgICAgICBpZiBrYnBzID49IDEyMDoKICAgICAgICAgICAgcmV0
:::dXJuICcxMjgga2JwcycsIDEKICAgICAgICByZXR1cm4gZid7a2Jwc30ga2JwcyAo
:::YmFqYSknLCAyCiAgICBpZiBleHQgPT0gJy5tNGEnOgogICAgICAgIGlmIGticHMg
:::Pj0gMTE1OgogICAgICAgICAgICByZXR1cm4gJ0V4Y2VsZW50ZSAoQUFDIOKJpDEy
:::OGspJywgMAogICAgICAgIGlmIGticHMgPj0gODI6CiAgICAgICAgICAgIHJldHVy
:::biAnOTYga2JwcycsIDEKICAgICAgICByZXR1cm4gZid7a2Jwc30ga2JwcyAoYmFq
:::YSknLCAyCiAgICBpZiBleHQgPT0gJy53bWEnOgogICAgICAgIGlmIGticHMgPj0g
:::MTE1OgogICAgICAgICAgICByZXR1cm4gJzEyOCBrYnBzJywgMAogICAgICAgIGlm
:::IGticHMgPj0gODg6CiAgICAgICAgICAgIHJldHVybiAnOTYga2JwcycsIDEKICAg
:::ICAgICByZXR1cm4gZid7a2Jwc30ga2JwcyAoYmFqYSknLCAyCiAgICBpZiBleHQg
:::aW4gKCcuZmxhYycsICcud2F2Jyk6CiAgICAgICAgcmV0dXJuICdTaW4gcMOpcmRp
:::ZGEnLCAwCiAgICBpZiBleHQgPT0gJy5hdmknOgogICAgICAgIGlmIGticHMgPj0g
:::MTIwMDoKICAgICAgICAgICAgcmV0dXJuIGYne2ticHN9IGticHMgKE1KUEVHK1BD
:::TSAxMjh4MTYwKScsIDAKICAgICAgICByZXR1cm4gZid7a2Jwc30ga2JwcyAoYWxn
:::byBiYWpvKScsIDEKICAgIHJldHVybiBmJ3trYnBzfSBrYnBzJywgMQoKCiMgLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLSB0ZW1hcwpURU1BUyA9IHsKICAgICdPc2N1cm8nOiBkaWN0
:::KAogICAgICAgIGZvbmRvPScjMWUxZjIyJywgY2FtcG89JyMyYTJkMzEnLCBjYW1w
:::b19ib3JkZT0nIzNhM2U0NCcsCiAgICAgICAgdGV4dG89JyNkOGRhZGMnLCB0ZXh0
:::bzI9JyM5YTlmYTQnLAogICAgICAgIGJvdG9uPScjM2EzZDQyJywgYm90b25fYWN0
:::PScjNGE0ZTU1JywgYm90b25fdHh0PScjZThlYWVjJywKICAgICAgICBsb2c9JyMx
:::NDE1MTgnLCBsb2dfdHh0PScjY2ZkM2Q3JywgYWNlbnRvPScjNGY5Y2Y5JywKICAg
:::ICAgICBvaz0nIzdlYzk3ZicsIGVycm9yPScjZTU3MzczJywgYXZpc289JyNkOGI2
:::NGEnLCB0cm91Z2g9JyMyNjI4MmMnLAogICAgICAgIHBsYWNlaG9sZGVyPScjNzc3
:::YzgyJyksCiAgICAnQ2xhcm8nOiBkaWN0KAogICAgICAgIGZvbmRvPScjZjJmM2Y1
:::JywgY2FtcG89JyNmZmZmZmYnLCBjYW1wb19ib3JkZT0nI2M0YzhjZCcsCiAgICAg
:::ICAgdGV4dG89JyMyNDI3MmEnLCB0ZXh0bzI9JyM2YTcwNzYnLAogICAgICAgIGJv
:::dG9uPScjZTNlNWU4JywgYm90b25fYWN0PScjZDJkNWRhJywgYm90b25fdHh0PScj
:::MjQyNzJhJywKICAgICAgICBsb2c9JyNmZmZmZmYnLCBsb2dfdHh0PScjMmIyZTMx
:::JywgYWNlbnRvPScjMWE2NmQ2JywKICAgICAgICBvaz0nIzFlN2UzNCcsIGVycm9y
:::PScjYzYyODI4JywgYXZpc289JyM5YTY3MDAnLCB0cm91Z2g9JyNkZmUxZTQnLAog
:::ICAgICAgIHBsYWNlaG9sZGVyPScjOWFhMGE2JyksCn0KClBMQUNFSE9MREVSX1VS
:::TCA9ICdodHRwczovL3d3dy55b3V0dWJlLmNvbS93YXRjaD92PS4uLicKCkZVRU5U
:::RV9VSSA9ICgnU2Vnb2UgVUknLCA5KQpGVUVOVEVfQlROID0gKCdTZWdvZSBVSScs
:::IDEwKQpGVUVOVEVfQlROX0cgPSAoJ1NlZ29lIFVJJywgMTEpCkZVRU5URV9MT0cg
:::PSAoJ0NvbnNvbGFzJywgMTApCgoKaWYgVEtfT0s6CgogICAgY2xhc3MgQXBwKHRr
:::LlRrKToKICAgICAgICAiIiJWZW50YW5hIHByaW5jaXBhbCAoZGlzZcOxbyBlc3Bl
:::am8gZGVsIG1vY2t1cDogZ3J1cG9zIG9zY3Vyb3MpLiIiIgoKICAgICAgICAjIC0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBj
:::b25zdHJ1Y2Npw7NuCiAgICAgICAgZGVmIF9faW5pdF9fKHNlbGYpOgogICAgICAg
:::ICAgICBpZiBnZXRhdHRyKHN5cywgJ2Zyb3plbicsIEZhbHNlKToKICAgICAgICAg
:::ICAgICAgIHBhc3MKICAgICAgICAgICAgc3VwZXIoKS5fX2luaXRfXygpCiAgICAg
:::ICAgICAgIHNlbGYudGl0bGUoJ011c2lrQUxBTicpCiAgICAgICAgICAgIHNlbGYu
:::Z2VvbWV0cnkoJzg2MHg4NDAnKQogICAgICAgICAgICBzZWxmLm1pbnNpemUoNzAw
:::LCA2NjApCiAgICAgICAgICAgIHNlbGYuY29sYSA9IHF1ZXVlLlF1ZXVlKCkKICAg
:::ICAgICAgICAgc2VsZi5fb2N1cGFkbyA9IEZhbHNlCiAgICAgICAgICAgIHNlbGYu
:::X2VuX3BsYWNlaG9sZGVyID0gVHJ1ZQogICAgICAgICAgICBzZWxmLl90ZW1hX2Fj
:::dHVhbCA9IEFKVVNURVMuZ2V0KCd0ZW1hJywgJ09zY3VybycpCiAgICAgICAgICAg
:::IGlmIHNlbGYuX3RlbWFfYWN0dWFsIG5vdCBpbiBURU1BUzoKICAgICAgICAgICAg
:::ICAgIHNlbGYuX3RlbWFfYWN0dWFsID0gJ09zY3VybycKCiAgICAgICAgICAgIHNl
:::bGYuX2VzdGlsbyA9IHR0ay5TdHlsZShzZWxmKQogICAgICAgICAgICB0cnk6CiAg
:::ICAgICAgICAgICAgICBzZWxmLl9lc3RpbG8udGhlbWVfdXNlKCdjbGFtJykKICAg
:::ICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgICAgIHBhc3MK
:::CiAgICAgICAgICAgIHNlbGYuX2NvbnN0cnVpcigpCiAgICAgICAgICAgIHNlbGYu
:::X2FwbGljYXJfdGVtYSgpCiAgICAgICAgICAgIHNlbGYuX2NvbmVjdGFyX2V2ZW50
:::b3MoKQogICAgICAgICAgICBSRUdJU1RSTy5sb2cgPSBsYW1iZGEgbSwgdD0nYXZp
:::c28nOiBzZWxmLmNvbGEucHV0KCgnbG9nJywgbSwgdCkpCiAgICAgICAgICAgIHNl
:::bGYuYWZ0ZXIoODAsIHNlbGYuX2JvbWJlYXJfY29sYSkKICAgICAgICAgICAgc2Vs
:::Zi5hZnRlcigxNTAsIHNlbGYuX2FycmFucXVlKQoKICAgICAgICBkZWYgX2NvbnN0
:::cnVpcihzZWxmKToKICAgICAgICAgICAgc2VsZi5fd2cgPSB7fSAgICAgICAgICMg
:::cmVmZXJlbmNpYXMgcGFyYSBlbCB0ZW1hCiAgICAgICAgICAgIHNlbGYuX2J0bnMg
:::PSBbXSAgICAgICAjIGJvdG9uZXMgcGxhbm9zIChwYXJhIGhvdmVyL3RlbWEpCiAg
:::ICAgICAgICAgIG1hcmNvID0gdGsuRnJhbWUoc2VsZikKICAgICAgICAgICAgbWFy
:::Y28ucGFjayhmaWxsPSdib3RoJywgZXhwYW5kPVRydWUsIHBhZHg9MTAsIHBhZHk9
:::OCkKICAgICAgICAgICAgc2VsZi5fd2dbJ21hcmNvJ10gPSBtYXJjbwogICAgICAg
:::ICAgICBtYXJjby5jb2x1bW5jb25maWd1cmUoMCwgd2VpZ2h0PTEpCgogICAgICAg
:::ICAgICAjIC0tLSBmaWxhIFRlbWEgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAgIGYwID0gdGsuRnJhbWUo
:::bWFyY28pCiAgICAgICAgICAgIGYwLmdyaWQocm93PTAsIGNvbHVtbj0wLCBzdGlj
:::a3k9J2V3JywgcGFkeT0oMCwgNikpCiAgICAgICAgICAgIHNlbGYuX3dnWydmMCdd
:::ID0gZjAKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF90ZW1hJ10gPSB0ay5MYWJl
:::bChmMCwgdGV4dD0nVGVtYTonLCBmb250PUZVRU5URV9VSSkKICAgICAgICAgICAg
:::c2VsZi5fd2dbJ2xibF90ZW1hJ10ucGFjayhzaWRlPSdsZWZ0JykKICAgICAgICAg
:::ICAgc2VsZi5jbWJfdGVtYSA9IHR0ay5Db21ib2JveCgKICAgICAgICAgICAgICAg
:::IGYwLCB2YWx1ZXM9bGlzdChURU1BUyksIHN0YXRlPSdyZWFkb25seScsIHdpZHRo
:::PTksCiAgICAgICAgICAgICAgICBmb250PUZVRU5URV9VSSwgc3R5bGU9J2d4LlRD
:::b21ib2JveCcpCiAgICAgICAgICAgIHNlbGYuY21iX3RlbWEuc2V0KHNlbGYuX3Rl
:::bWFfYWN0dWFsKQogICAgICAgICAgICBzZWxmLmNtYl90ZW1hLnBhY2soc2lkZT0n
:::bGVmdCcsIHBhZHg9KDgsIDApLCBpcGFkeT0yKQoKICAgICAgICAgICAgIyAtLS0g
:::Z3J1cG86IFVSTCBkZSBZb3VUdWJlIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLQogICAgICAgICAgICBndSA9IHRrLkxhYmVsRnJhbWUobWFyY28s
:::IHRleHQ9J1VSTCBkZSBZb3VUdWJlJywgZm9udD1GVUVOVEVfVUksCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICByZWxpZWY9J3NvbGlkJywgYmQ9MSkKICAg
:::ICAgICAgICAgZ3UuZ3JpZChyb3c9MSwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBw
:::YWR5PTUpCiAgICAgICAgICAgIHNlbGYuX3dnWydndSddID0gZ3UKICAgICAgICAg
:::ICAgZ3UuY29sdW1uY29uZmlndXJlKDAsIHdlaWdodD0xKQogICAgICAgICAgICBz
:::ZWxmLmVudF91cmwgPSB0ay5FbnRyeShndSwgZm9udD1GVUVOVEVfVUksIHJlbGll
:::Zj0nZmxhdCcsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGhp
:::Z2hsaWdodHRoaWNrbmVzcz0xKQogICAgICAgICAgICBzZWxmLmVudF91cmwuZ3Jp
:::ZChyb3c9MCwgY29sdW1uPTAsIHN0aWNreT0nZXcnLAogICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICBwYWR4PTgsIHBhZHk9OCwgaXBhZHk9NSkKICAgICAgICAg
:::ICAgc2VsZi5fcG9uZXJfcGxhY2Vob2xkZXIoKQogICAgICAgICAgICAjIHYyLjEy
:::OiBib3RvbiBQZWdhciAocGVnYSBlbCBlbmxhY2UgZGVsIHBvcnRhcGFwZWxlcykg
:::KyBYCiAgICAgICAgICAgIHNlbGYuYnRuX3BlZ2FyID0gc2VsZi5fYm90b24oZ3Us
:::ICdQZWdhcicsIHNlbGYuX3BlZ2FyX3VybCkKICAgICAgICAgICAgc2VsZi5idG5f
:::cGVnYXIuZ3JpZChyb3c9MCwgY29sdW1uPTEsIHN0aWNreT0nZScsIHBhZHg9KDAs
:::IDQpLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGlwYWR5PTMpCiAg
:::ICAgICAgICAgIHNlbGYuYnRuX3ggPSBzZWxmLl9ib3RvbihndSwgJ1gnLCBzZWxm
:::Ll9saW1waWFyX3VybCwgd2lkdGg9MykKICAgICAgICAgICAgc2VsZi5idG5feC5n
:::cmlkKHJvdz0wLCBjb2x1bW49Miwgc3RpY2t5PSdlJywgcGFkeD0oMCwgOCksIGlw
:::YWR5PTMpCgogICAgICAgICAgICAjIC0tLSBncnVwbzogRm9ybWF0byB5IGNhbGlk
:::YWQgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAg
:::IGdmID0gdGsuTGFiZWxGcmFtZShtYXJjbywgdGV4dD0nRm9ybWF0byB5IGNhbGlk
:::YWQnLCBmb250PUZVRU5URV9VSSwKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIHJlbGllZj0nc29saWQnLCBiZD0xKQogICAgICAgICAgICBnZi5ncmlkKHJv
:::dz0yLCBjb2x1bW49MCwgc3RpY2t5PSdldycsIHBhZHk9NSkKICAgICAgICAgICAg
:::c2VsZi5fd2dbJ2dmJ10gPSBnZgogICAgICAgICAgICBnZi5jb2x1bW5jb25maWd1
:::cmUoMSwgd2VpZ2h0PTEpCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfZm10J10g
:::PSB0ay5MYWJlbChnZiwgdGV4dD0nRm9ybWF0bzonLCBmb250PUZVRU5URV9VSSkK
:::ICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF9mbXQnXS5ncmlkKHJvdz0wLCBjb2x1
:::bW49MCwgc3RpY2t5PSd3JywgcGFkeD04LCBwYWR5PTUpCiAgICAgICAgICAgIHNl
:::bGYuY21iX2Zvcm1hdG8gPSB0dGsuQ29tYm9ib3goCiAgICAgICAgICAgICAgICBn
:::ZiwgdmFsdWVzPVtmWyd0ZXh0byddIGZvciBmIGluIEZPUk1BVE9TLnZhbHVlcygp
:::XSwKICAgICAgICAgICAgICAgIHN0YXRlPSdyZWFkb25seScsIGZvbnQ9RlVFTlRF
:::X1VJLCBzdHlsZT0nZ3guVENvbWJvYm94JykKICAgICAgICAgICAgc2VsZi5jbWJf
:::Zm9ybWF0by5ncmlkKHJvdz0wLCBjb2x1bW49MSwgc3RpY2t5PSdldycsCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4PTgsIHBhZHk9NSwgaXBh
:::ZHk9MikKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF9jYWwnXSA9IHRrLkxhYmVs
:::KGdmLCB0ZXh0PSdDYWxpZGFkOicsIGZvbnQ9RlVFTlRFX1VJKQogICAgICAgICAg
:::ICBzZWxmLl93Z1snbGJsX2NhbCddLmdyaWQocm93PTEsIGNvbHVtbj0wLCBzdGlj
:::a3k9J3cnLCBwYWR4PTgsIHBhZHk9NSkKICAgICAgICAgICAgc2VsZi5jbWJfY2Fs
:::aWRhZCA9IHR0ay5Db21ib2JveCgKICAgICAgICAgICAgICAgIGdmLCBzdGF0ZT0n
:::cmVhZG9ubHknLCBmb250PUZVRU5URV9VSSwgc3R5bGU9J2d4LlRDb21ib2JveCcp
:::CiAgICAgICAgICAgIHNlbGYuY21iX2NhbGlkYWQuZ3JpZChyb3c9MSwgY29sdW1u
:::PTEsIHN0aWNreT0nZXcnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgcGFkeD04LCBwYWR5PTUsIGlwYWR5PTIpCiAgICAgICAgICAgIHNlbGYuX3dn
:::WydsYmxfY2FyJ10gPSB0ay5MYWJlbChnZiwgdGV4dD0nQ2FycGV0YTonLCBmb250
:::PUZVRU5URV9VSSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF9jYXInXS5ncmlk
:::KHJvdz0yLCBjb2x1bW49MCwgc3RpY2t5PSd3JywgcGFkeD04LCBwYWR5PTUpCiAg
:::ICAgICAgICAgIGZjID0gdGsuRnJhbWUoZ2YpCiAgICAgICAgICAgIGZjLmdyaWQo
:::cm93PTIsIGNvbHVtbj0xLCBzdGlja3k9J2V3JywgcGFkeD04LCBwYWR5PTUpCiAg
:::ICAgICAgICAgIHNlbGYuX3dnWydmYyddID0gZmMKICAgICAgICAgICAgZmMuY29s
:::dW1uY29uZmlndXJlKDAsIHdlaWdodD0xKQogICAgICAgICAgICBzZWxmLmVudF9j
:::YXJwZXRhID0gdGsuRW50cnkoZmMsIGZvbnQ9RlVFTlRFX1VJLCByZWxpZWY9J2Zs
:::YXQnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgaGln
:::aGxpZ2h0dGhpY2tuZXNzPTEpCiAgICAgICAgICAgIHNlbGYuZW50X2NhcnBldGEu
:::Z3JpZChyb3c9MCwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBpcGFkeT00KQogICAg
:::ICAgICAgICBzZWxmLmVudF9jYXJwZXRhLmluc2VydCgwLCBBSlVTVEVTWydkZXN0
:::aW5vJ10pCiAgICAgICAgICAgIHNlbGYuYnRuX2NhbWJpYXIgPSBzZWxmLl9ib3Rv
:::bihmYywgJ0NhbWJpYXIuLi4nLCBzZWxmLl9jYW1iaWFyX2NhcnBldGEpCiAgICAg
:::ICAgICAgIHNlbGYuYnRuX2NhbWJpYXIuZ3JpZChyb3c9MCwgY29sdW1uPTEsIHBh
:::ZHg9KDgsIDApLCBpcGFkeT0zKQogICAgICAgICAgICBzZWxmLmJ0bl9hYnJpciA9
:::IHNlbGYuX2JvdG9uKGZjLCAnQWJyaXInLCBzZWxmLl9hYnJpcl9kZXN0aW5vLCB3
:::aWR0aD01KQogICAgICAgICAgICBzZWxmLmJ0bl9hYnJpci5ncmlkKHJvdz0wLCBj
:::b2x1bW49MiwgcGFkeD0oNiwgMCksIGlwYWR5PTMpCgogICAgICAgICAgICBzZWxm
:::LnZhcl9lbWJlYmVyID0gdGsuQm9vbGVhblZhcih2YWx1ZT1ib29sKEFKVVNURVMu
:::Z2V0KCdlbWJlYmVyJywgVHJ1ZSkpKQogICAgICAgICAgICBzZWxmLmNoa19lbWJl
:::YmVyID0gdGsuQ2hlY2tidXR0b24oCiAgICAgICAgICAgICAgICBnZiwgdGV4dD0n
:::RW1iZWJlciBjYXLDoXR1bGEsIGFydGlzdGEgeSDDoWxidW0nLAogICAgICAgICAg
:::ICAgICAgdmFyaWFibGU9c2VsZi52YXJfZW1iZWJlciwgZm9udD1GVUVOVEVfVUks
:::IGFuY2hvcj0ndycsCiAgICAgICAgICAgICAgICByZWxpZWY9J2ZsYXQnLCBoaWdo
:::bGlnaHR0aGlja25lc3M9MCwgYmQ9MCkKICAgICAgICAgICAgc2VsZi5jaGtfZW1i
:::ZWJlci5ncmlkKHJvdz0zLCBjb2x1bW49MCwgY29sdW1uc3Bhbj0yLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgc3RpY2t5PSdldycsIHBhZHg9OCwg
:::cGFkeT0oMiwgNikpCiAgICAgICAgICAgICMgdjIuOTogdsOtYSBhbnRpLWJsb3F1
:::ZW8gKGNvb2tpZXMgZGVsIG5hdmVnYWRvciBzaSBZb3VUdWJlCiAgICAgICAgICAg
:::ICMgcGlkZSB2ZXJpZmljYWNpw7NuKQogICAgICAgICAgICBzZWxmLl93Z1snbGJs
:::X2Nvb2tpZXMnXSA9IHRrLkxhYmVsKAogICAgICAgICAgICAgICAgZ2YsIHRleHQ9
:::J1NpIFlvdVR1YmUgYmxvcXVlYTonLCBmb250PUZVRU5URV9VSSkKICAgICAgICAg
:::ICAgc2VsZi5fd2dbJ2xibF9jb29raWVzJ10uZ3JpZChyb3c9NCwgY29sdW1uPTAs
:::IHN0aWNreT0ndycsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgcGFkeD04LCBwYWR5PTUpCiAgICAgICAgICAgIHNlbGYuY21iX2Nvb2tp
:::ZXMgPSB0dGsuQ29tYm9ib3goCiAgICAgICAgICAgICAgICBnZiwgdmFsdWVzPShb
:::J0F1dG9tw6F0aWNvIChyZWNvbWVuZGFkbyknXQogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgKyBbJ1VzYXIgY29va2llcyBkZSAnICsgbi5jYXBpdGFsaXplKCkK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGZvciBuIGluIE5BVkVHQURP
:::UkVTX0NPT0tJRVNdKSwKICAgICAgICAgICAgICAgIHN0YXRlPSdyZWFkb25seScs
:::IGZvbnQ9RlVFTlRFX1VJLCBzdHlsZT0nZ3guVENvbWJvYm94JykKICAgICAgICAg
:::ICAgc2VsZi5jbWJfY29va2llcy5ncmlkKHJvdz00LCBjb2x1bW49MSwgc3RpY2t5
:::PSdldycsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4PTgs
:::IHBhZHk9NSwgaXBhZHk9MikKICAgICAgICAgICAgc2VsZi5jbWJfY29va2llcy5z
:::ZXQoJ0F1dG9tw6F0aWNvIChyZWNvbWVuZGFkbyknKQoKICAgICAgICAgICAgIyAt
:::LS0gZ3J1cG86IGVzdGltYWNpw7NuIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0KICAgICAgICAgICAgZ2UgPSB0ay5MYWJlbEZyYW1lKG1h
:::cmNvLCB0ZXh0PSdFc3RpbWFjacOzbicsIGZvbnQ9RlVFTlRFX1VJLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgcmVsaWVmPSdzb2xpZCcsIGJkPTEpCiAg
:::ICAgICAgICAgIGdlLmdyaWQocm93PTMsIGNvbHVtbj0wLCBzdGlja3k9J2V3Jywg
:::cGFkeT01KQogICAgICAgICAgICBzZWxmLl93Z1snZ2UnXSA9IGdlCiAgICAgICAg
:::ICAgIGdlLmNvbHVtbmNvbmZpZ3VyZSgwLCB3ZWlnaHQ9MSkKICAgICAgICAgICAg
:::c2VsZi5sYmxfZXN0aW1hY2lvbiA9IHRrLkxhYmVsKAogICAgICAgICAgICAgICAg
:::Z2UsIHRleHQ9J0ludHJvZHVjZSB1bmEgVVJMIHkgcHVsc2EgRXN0aW1hci4nLAog
:::ICAgICAgICAgICAgICAgZm9udD1GVUVOVEVfVUksIGFuY2hvcj0ndycpCiAgICAg
:::ICAgICAgIHNlbGYubGJsX2VzdGltYWNpb24uZ3JpZChyb3c9MCwgY29sdW1uPTAs
:::IHN0aWNreT0nZXcnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgcGFkeD04LCBwYWR5PTYpCiAgICAgICAgICAgIHNlbGYuYnRuX2VzdGltYXIg
:::PSBzZWxmLl9ib3RvbihnZSwgJ0VzdGltYXIgdGFtYW5vJywKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuX2FjY2lvbl9lc3Rp
:::bWFyKQogICAgICAgICAgICBzZWxmLmJ0bl9lc3RpbWFyLmdyaWQocm93PTAsIGNv
:::bHVtbj0xLCBzdGlja3k9J2UnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgcGFkeD04LCBpcGFkeT0zKQoKICAgICAgICAgICAgIyAtLS0gYm90b25l
:::cyBncmFuZGVzIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLQogICAgICAgICAgICBzZWxmLmJ0bl9kZXNjYXJnYXIgPSBzZWxmLl9ib3Rv
:::bihtYXJjbywgJ0Rlc2NhcmdhciB5IGNvbnZlcnRpcicsCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuX2FjY2lvbl9kZXNj
:::YXJnYXIsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIGZ1ZW50ZT1GVUVOVEVfQlROX0csIGFsdG89MikKICAgICAgICAgICAgc2Vs
:::Zi5idG5fZGVzY2FyZ2FyLmdyaWQocm93PTQsIGNvbHVtbj0wLCBzdGlja3k9J2V3
:::JywgcGFkeT0oNywgNCkpCiAgICAgICAgICAgIHNlbGYuYnRuX2NvbXByb2JhciA9
:::IHNlbGYuX2JvdG9uKAogICAgICAgICAgICAgICAgbWFyY28sICdDb21wcm9iYXIg
:::Y2FsaWRhZCBkZSBsYSBjYXJwZXRhJywKICAgICAgICAgICAgICAgIHNlbGYuX2Fj
:::Y2lvbl9jb21wcm9iYXIsIGZ1ZW50ZT1GVUVOVEVfQlROKQogICAgICAgICAgICBz
:::ZWxmLmJ0bl9jb21wcm9iYXIuZ3JpZChyb3c9NSwgY29sdW1uPTAsIHN0aWNreT0n
:::ZXcnLCBwYWR5PTMpCgogICAgICAgICAgICAjIC0tLSBlc3RhZG8gKyBiYXJyYSBk
:::ZSBwcm9ncmVzbyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAg
:::ICAgICAgICBzZWxmLmxibF9lc3RhZG8gPSB0ay5MYWJlbChtYXJjbywgdGV4dD0n
:::JywgZm9udD1GVUVOVEVfVUksCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgIGFuY2hvcj0ndycpCiAgICAgICAgICAgIHNlbGYubGJsX2VzdGFk
:::by5ncmlkKHJvdz02LCBjb2x1bW49MCwgc3RpY2t5PSdldycsIHBhZHk9KDQsIDAp
:::KQogICAgICAgICAgICBzZWxmLmJhcnJhID0gdHRrLlByb2dyZXNzYmFyKAogICAg
:::ICAgICAgICAgICAgbWFyY28sIG1heGltdW09MTAwLCBzdHlsZT0nZ3guSG9yaXpv
:::bnRhbC5UUHJvZ3Jlc3NiYXInKQogICAgICAgICAgICBzZWxmLmJhcnJhLmdyaWQo
:::cm93PTcsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgcGFkeT0oMiwgNCkpCgogICAg
:::ICAgICAgICAjIC0tLSByZWdpc3RybyAobG9nKSAtLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAgICAgICBzZWxmLnR4dF9s
:::b2cgPSBTY3JvbGxlZFRleHQobWFyY28sIGZvbnQ9RlVFTlRFX0xPRywgaGVpZ2h0
:::PTEyLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVs
:::aWVmPSdmbGF0JywgYmQ9MCwgd3JhcD0nd29yZCcsCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICBzdGF0ZT0nZGlzYWJsZWQnKQogICAgICAg
:::ICAgICBzZWxmLnR4dF9sb2cuZ3JpZChyb3c9OCwgY29sdW1uPTAsIHN0aWNreT0n
:::bnNldycpCiAgICAgICAgICAgIG1hcmNvLnJvd2NvbmZpZ3VyZSg4LCB3ZWlnaHQ9
:::MSkKICAgICAgICAgICAgZm9yIHRhZywgY29uZiBpbiAoCiAgICAgICAgICAgICAg
:::ICAgICAgKCdpbmZvJywge30pLAogICAgICAgICAgICAgICAgICAgICgnZ3Jpcycs
:::IHt9KSwKICAgICAgICAgICAgICAgICAgICAoJ3RpdHVsbycsIHt9KSwKICAgICAg
:::ICAgICAgICAgICAgICAoJ29rJywge30pLAogICAgICAgICAgICAgICAgICAgICgn
:::YXZpc28nLCB7fSksCiAgICAgICAgICAgICAgICAgICAgKCdlcnJvcicsIHt9KSk6
:::CiAgICAgICAgICAgICAgICBzZWxmLnR4dF9sb2cudGFnX2NvbmZpZ3VyZSh0YWcs
:::IGNvbmYpCgogICAgICAgICAgICAjIHNpbmNyb25pemFyIHZhbG9yZXMgZ3VhcmRh
:::ZG9zCiAgICAgICAgICAgIGZtdCA9IEFKVVNURVMuZ2V0KCdmb3JtYXRvJywgJ0FB
:::QycpCiAgICAgICAgICAgIGlmIGZtdCBub3QgaW4gRk9STUFUT1M6CiAgICAgICAg
:::ICAgICAgICBmbXQgPSAnQUFDJwogICAgICAgICAgICBzZWxmLmNtYl9mb3JtYXRv
:::LnNldChGT1JNQVRPU1tmbXRdWyd0ZXh0byddKQogICAgICAgICAgICBzZWxmLl9y
:::ZWNhcmdhcl9jYWxpZGFkZXMoZm10LCBBSlVTVEVTLmdldCgnY2FsaWRhZCcpKQog
:::ICAgICAgICAgICBjb29raWVzID0gc3RyKEFKVVNURVMuZ2V0KCdjb29raWVzJywg
:::JycpIG9yICcnKS5zdHJpcCgpLmxvd2VyKCkKICAgICAgICAgICAgaWYgY29va2ll
:::cyBpbiBOQVZFR0FET1JFU19DT09LSUVTOgogICAgICAgICAgICAgICAgc2VsZi5j
:::bWJfY29va2llcy5zZXQoJ1VzYXIgY29va2llcyBkZSAnCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICArIGNvb2tpZXMuY2FwaXRhbGl6ZSgpKQog
:::ICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgc2VsZi5jbWJfY29va2ll
:::cy5zZXQoJ0F1dG9tw6F0aWNvIChyZWNvbWVuZGFkbyknKQoKICAgICAgICAjIC0t
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
:::dXNfc2V0KCkKCiAgICAgICAgZGVmIF9wZWdhcl91cmwoc2VsZik6CiAgICAgICAg
:::ICAgICIiInYyLjEyOiBwZWdhIGVuIGVsIGNhbXBvIGxhIFVSTCBjb3BpYWRhIGFs
:::IHBvcnRhcGFwZWxlcy4KICAgICAgICAgICAgU2kgZWwgcG9ydGFwYXBlbGVzIHRy
:::YWUgdGV4dG8gY29uIHVuIGVubGFjZSBkZW50cm8gKHAuIGVqLgogICAgICAgICAg
:::ICAnbWlyYSBlc3RvIGh0dHBzOi8vLi4uJyksIHNlIHF1ZWRhIHNvbG8gY29uIGVs
:::IGVubGFjZS4iIiIKICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgdGV4
:::dG8gPSAoc2VsZi5jbGlwYm9hcmRfZ2V0KCkgb3IgJycpLnN0cmlwKCkKICAgICAg
:::ICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgICAgIHRleHRvID0g
:::JycKICAgICAgICAgICAgaWYgbm90IHRleHRvOgogICAgICAgICAgICAgICAgc2Vs
:::Zi5fbG9nKCdFbCBwb3J0YXBhcGVsZXMgZXN0w6EgdmFjw61vIG8gbm8gdGllbmUg
:::dGV4dG8uJywKICAgICAgICAgICAgICAgICAgICAgICAgICAnYXZpc28nKQogICAg
:::ICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgIG0gPSByZS5zZWFyY2gocido
:::dHRwcz86Ly9bXlxzIlwnXSsnLCB0ZXh0bywgcmUuSSkKICAgICAgICAgICAgaWYg
:::bToKICAgICAgICAgICAgICAgIHRleHRvID0gbS5ncm91cCgwKQogICAgICAgICAg
:::ICBzZWxmLmVudF91cmwuZGVsZXRlKDAsICdlbmQnKQogICAgICAgICAgICBzZWxm
:::LmVudF91cmwuaW5zZXJ0KDAsIHRleHRvKQogICAgICAgICAgICBzZWxmLl9lbl9w
:::bGFjZWhvbGRlciA9IEZhbHNlCiAgICAgICAgICAgIHNlbGYuX3JlZnJlc2Nhcl9w
:::bGFjZWhvbGRlcigpCiAgICAgICAgICAgIHNlbGYuZW50X3VybC5mb2N1c19zZXQo
:::KQoKICAgICAgICBkZWYgX3Jlc2V0X3VybChzZWxmKToKICAgICAgICAgICAgIiIi
:::RGVqYSBlbCBjYW1wbyBkZSBVUkwgdmFjw61vIGNvbiBzdSBwbGFjZWhvbGRlciAo
:::dHJhcyB1biDDqXhpdG8pLiIiIgogICAgICAgICAgICBzZWxmLmVudF91cmwuZGVs
:::ZXRlKDAsICdlbmQnKQogICAgICAgICAgICBzZWxmLl9lbl9wbGFjZWhvbGRlciA9
:::IFRydWUKICAgICAgICAgICAgc2VsZi5fcG9uZXJfcGxhY2Vob2xkZXIoKQogICAg
:::ICAgICAgICBzZWxmLl9yZWZyZXNjYXJfcGxhY2Vob2xkZXIoKQoKICAgICAgICAj
:::IC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LSB0ZW1hCiAgICAgICAgZGVmIF9hcGxpY2FyX3RlbWEoc2VsZik6CiAgICAgICAg
:::ICAgIHQgPSBURU1BU1tzZWxmLl90ZW1hX2FjdHVhbF0KICAgICAgICAgICAgdyA9
:::IHNlbGYuX3dnCiAgICAgICAgICAgIHNlbGYuY29uZmlndXJlKGJnPXRbJ2ZvbmRv
:::J10pCiAgICAgICAgICAgIGZvciBub21icmUgaW4gKCdtYXJjbycsICdmMCcsICdn
:::dScsICdnZicsICdmYycsICdnZScpOgogICAgICAgICAgICAgICAgd1tub21icmVd
:::LmNvbmZpZ3VyZShiZz10Wydmb25kbyddKQogICAgICAgICAgICBmb3IgbGYgaW4g
:::KHdbJ2d1J10sIHdbJ2dmJ10sIHdbJ2dlJ10pOgogICAgICAgICAgICAgICAgbGYu
:::Y29uZmlndXJlKGJnPXRbJ2ZvbmRvJ10sIGZnPXRbJ3RleHRvMiddKQogICAgICAg
:::ICAgICBmb3Igbm9tYnJlIGluICgnbGJsX3RlbWEnLCAnbGJsX2ZtdCcsICdsYmxf
:::Y2FsJywgJ2xibF9jYXInKToKICAgICAgICAgICAgICAgIHdbbm9tYnJlXS5jb25m
:::aWd1cmUoYmc9dFsnZm9uZG8nXSwgZmc9dFsndGV4dG8nXSkKICAgICAgICAgICAg
:::c2VsZi5sYmxfZXN0aW1hY2lvbi5jb25maWd1cmUoYmc9dFsnZm9uZG8nXSwgZmc9
:::dFsndGV4dG8nXSkKICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmNvbmZpZ3Vy
:::ZShiZz10Wydmb25kbyddLCBmZz10Wyd0ZXh0bzInXSkKICAgICAgICAgICAgc2Vs
:::Zi5lbnRfdXJsLmNvbmZpZ3VyZSgKICAgICAgICAgICAgICAgIGJnPXRbJ2NhbXBv
:::J10sIGZnPXRbJ3RleHRvJ10sIGluc2VydGJhY2tncm91bmQ9dFsndGV4dG8nXSwK
:::ICAgICAgICAgICAgICAgIGhpZ2hsaWdodGJhY2tncm91bmQ9dFsnY2FtcG9fYm9y
:::ZGUnXSwKICAgICAgICAgICAgICAgIGhpZ2hsaWdodGNvbG9yPXRbJ2FjZW50bydd
:::LAogICAgICAgICAgICAgICAgZGlzYWJsZWRiYWNrZ3JvdW5kPXRbJ2NhbXBvJ10s
:::IGRpc2FibGVkZm9yZWdyb3VuZD10Wyd0ZXh0bzInXSkKICAgICAgICAgICAgc2Vs
:::Zi5lbnRfY2FycGV0YS5jb25maWd1cmUoCiAgICAgICAgICAgICAgICBiZz10Wydj
:::YW1wbyddLCBmZz10Wyd0ZXh0byddLCBpbnNlcnRiYWNrZ3JvdW5kPXRbJ3RleHRv
:::J10sCiAgICAgICAgICAgICAgICBoaWdobGlnaHRiYWNrZ3JvdW5kPXRbJ2NhbXBv
:::X2JvcmRlJ10sCiAgICAgICAgICAgICAgICBoaWdobGlnaHRjb2xvcj10WydhY2Vu
:::dG8nXSkKICAgICAgICAgICAgc2VsZi5jaGtfZW1iZWJlci5jb25maWd1cmUoCiAg
:::ICAgICAgICAgICAgICBiZz10Wydmb25kbyddLCBmZz10Wyd0ZXh0byddLCBhY3Rp
:::dmViYWNrZ3JvdW5kPXRbJ2ZvbmRvJ10sCiAgICAgICAgICAgICAgICBhY3RpdmVm
:::b3JlZ3JvdW5kPXRbJ3RleHRvJ10sIHNlbGVjdGNvbG9yPXRbJ2NhbXBvJ10pCiAg
:::ICAgICAgICAgIGZvciBiIGluIHNlbGYuX2J0bnM6CiAgICAgICAgICAgICAgICBi
:::LmNvbmZpZ3VyZShiZz10Wydib3RvbiddLCBmZz10Wydib3Rvbl90eHQnXSwKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgIGFjdGl2ZWJhY2tncm91bmQ9dFsnYm90
:::b25fYWN0J10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBhY3RpdmVmb3Jl
:::Z3JvdW5kPXRbJ2JvdG9uX3R4dCddKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cu
:::Y29uZmlndXJlKGJnPXRbJ2xvZyddLCBmZz10Wydsb2dfdHh0J10sCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgaW5zZXJ0YmFja2dyb3VuZD10Wyds
:::b2dfdHh0J10pCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy50YWdfY29uZmlndXJl
:::KCdpbmZvJywgZm9yZWdyb3VuZD10Wydsb2dfdHh0J10pCiAgICAgICAgICAgIHNl
:::bGYudHh0X2xvZy50YWdfY29uZmlndXJlKCdncmlzJywgZm9yZWdyb3VuZD10Wyd0
:::ZXh0bzInXSkKICAgICAgICAgICAgc2VsZi50eHRfbG9nLnRhZ19jb25maWd1cmUo
:::J3RpdHVsbycsIGZvcmVncm91bmQ9dFsndGV4dG8nXSwKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgZm9udD0oJ0NvbnNvbGFzJywgMTAsICdi
:::b2xkJykpCiAgICAgICAgICAgIHNlbGYudHh0X2xvZy50YWdfY29uZmlndXJlKCdv
:::aycsIGZvcmVncm91bmQ9dFsnb2snXSkKICAgICAgICAgICAgc2VsZi50eHRfbG9n
:::LnRhZ19jb25maWd1cmUoJ2F2aXNvJywgZm9yZWdyb3VuZD10WydhdmlzbyddKQog
:::ICAgICAgICAgICBzZWxmLnR4dF9sb2cudGFnX2NvbmZpZ3VyZSgnZXJyb3InLCBm
:::b3JlZ3JvdW5kPXRbJ2Vycm9yJ10pCiAgICAgICAgICAgIGVzdCA9IHNlbGYuX2Vz
:::dGlsbwogICAgICAgICAgICBlc3QuY29uZmlndXJlKCdneC5UQ29tYm9ib3gnLAog
:::ICAgICAgICAgICAgICAgICAgICAgICAgIGZpZWxkYmFja2dyb3VuZD10WydjYW1w
:::byddLCBiYWNrZ3JvdW5kPXRbJ2JvdG9uJ10sCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgZm9yZWdyb3VuZD10Wyd0ZXh0byddLCBhcnJvd2NvbG9yPXRbJ3RleHRv
:::J10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgYm9yZGVyY29sb3I9dFsnY2Ft
:::cG9fYm9yZGUnXSwKICAgICAgICAgICAgICAgICAgICAgICAgICBsaWdodGNvbG9y
:::PXRbJ2NhbXBvX2JvcmRlJ10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgZGFy
:::a2NvbG9yPXRbJ2NhbXBvX2JvcmRlJ10sCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgaW5zZXJ0Y29sb3I9dFsndGV4dG8nXSkKICAgICAgICAgICAgZXN0Lm1hcCgn
:::Z3guVENvbWJvYm94JywKICAgICAgICAgICAgICAgICAgICBmaWVsZGJhY2tncm91
:::bmQ9WygncmVhZG9ubHknLCB0WydjYW1wbyddKV0sCiAgICAgICAgICAgICAgICAg
:::ICAgZm9yZWdyb3VuZD1bKCdyZWFkb25seScsIHRbJ3RleHRvJ10pXSkKICAgICAg
:::ICAgICAgZXN0LmNvbmZpZ3VyZSgnZ3guSG9yaXpvbnRhbC5UUHJvZ3Jlc3NiYXIn
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgIHRyb3VnaGNvbG9yPXRbJ3Ryb3Vn
:::aCddLCBiYWNrZ3JvdW5kPXRbJ2FjZW50byddLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgIGJvcmRlcmNvbG9yPXRbJ2ZvbmRvJ10sIGxpZ2h0Y29sb3I9dFsnYWNl
:::bnRvJ10sCiAgICAgICAgICAgICAgICAgICAgICAgICAgZGFya2NvbG9yPXRbJ2Fj
:::ZW50byddKQogICAgICAgICAgICBzZWxmLm9wdGlvbl9hZGQoJypUQ29tYm9ib3gq
:::TGlzdGJveC5iYWNrZ3JvdW5kJywgdFsnY2FtcG8nXSkKICAgICAgICAgICAgc2Vs
:::Zi5vcHRpb25fYWRkKCcqVENvbWJvYm94Kkxpc3Rib3guZm9yZWdyb3VuZCcsIHRb
:::J3RleHRvJ10pCiAgICAgICAgICAgIHNlbGYub3B0aW9uX2FkZCgnKlRDb21ib2Jv
:::eCpMaXN0Ym94LnNlbGVjdEJhY2tncm91bmQnLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgdFsnYm90b25fYWN0J10pCiAgICAgICAgICAgIHNlbGYub3B0aW9u
:::X2FkZCgnKlRDb21ib2JveCpMaXN0Ym94LnNlbGVjdEZvcmVncm91bmQnLAogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgdFsnYm90b25fdHh0J10pCiAgICAgICAg
:::ICAgIHNlbGYuX3JlZnJlc2Nhcl9wbGFjZWhvbGRlcigpCgogICAgICAgIGRlZiBf
:::cmVmcmVzY2FyX3BsYWNlaG9sZGVyKHNlbGYpOgogICAgICAgICAgICB0ID0gVEVN
:::QVNbc2VsZi5fdGVtYV9hY3R1YWxdCiAgICAgICAgICAgIGlmIHNlbGYuX2VuX3Bs
:::YWNlaG9sZGVyOgogICAgICAgICAgICAgICAgc2VsZi5lbnRfdXJsLmNvbmZpZ3Vy
:::ZShmZz10WydwbGFjZWhvbGRlciddKQogICAgICAgICAgICBlbHNlOgogICAgICAg
:::ICAgICAgICAgc2VsZi5lbnRfdXJsLmNvbmZpZ3VyZShmZz10Wyd0ZXh0byddKQoK
:::ICAgICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLSBldmVudG9zCiAgICAgICAgZGVmIF9jb25lY3Rhcl9ldmVudG9z
:::KHNlbGYpOgogICAgICAgICAgICBzZWxmLmNtYl90ZW1hLmJpbmQoJzw8Q29tYm9i
:::b3hTZWxlY3RlZD4+Jywgc2VsZi5fb25fdGVtYSkKICAgICAgICAgICAgc2VsZi5j
:::bWJfZm9ybWF0by5iaW5kKCc8PENvbWJvYm94U2VsZWN0ZWQ+PicsIHNlbGYuX29u
:::X2Zvcm1hdG8pCiAgICAgICAgICAgIHNlbGYuY21iX2NhbGlkYWQuYmluZCgnPDxD
:::b21ib2JveFNlbGVjdGVkPj4nLCBsYW1iZGEgZTogc2VsZi5fZ3VhcmRhcigpKQog
:::ICAgICAgICAgICBzZWxmLmNoa19lbWJlYmVyLmNvbmZpZ3VyZShjb21tYW5kPXNl
:::bGYuX2d1YXJkYXIpCiAgICAgICAgICAgIHNlbGYuZW50X3VybC5iaW5kKCc8Rm9j
:::dXNJbj4nLCBzZWxmLl9vbl9mb2N1c191cmxfaW4pCiAgICAgICAgICAgIHNlbGYu
:::ZW50X3VybC5iaW5kKCc8Rm9jdXNPdXQ+Jywgc2VsZi5fb25fZm9jdXNfdXJsX291
:::dCkKICAgICAgICAgICAgc2VsZi5lbnRfdXJsLmJpbmQoJzxSZXR1cm4+JywgbGFt
:::YmRhIGU6IHNlbGYuX2FjY2lvbl9kZXNjYXJnYXIoKSkKICAgICAgICAgICAgc2Vs
:::Zi5lbnRfY2FycGV0YS5iaW5kKCc8Rm9jdXNPdXQ+Jywgc2VsZi5fb25fY2FycGV0
:::YV9lc2NyaXRhKQogICAgICAgICAgICBzZWxmLnByb3RvY29sKCdXTV9ERUxFVEVf
:::V0lORE9XJywgc2VsZi5fYWxfY2VycmFyKQogICAgICAgICAgICBzZWxmLmJpbmQo
:::JzxDb250cm9sLXU+JywgbGFtYmRhIGU6IHNlbGYuX2FjY2lvbl9hY3R1YWxpemFy
:::KCkpCiAgICAgICAgICAgIHNlbGYuYmluZCgnPENvbnRyb2wtbD4nLCBsYW1iZGEg
:::ZTogc2VsZi5fbGltcGlhcl9sb2coKSkKICAgICAgICAgICAgc2VsZi5iaW5kKCc8
:::Q29udHJvbC1VPicsIGxhbWJkYSBlOiBzZWxmLl9hY2Npb25fYWN0dWFsaXphcigp
:::KQoKICAgICAgICBkZWYgX29uX2ZvY3VzX3VybF9pbihzZWxmLCBfZT1Ob25lKToK
:::ICAgICAgICAgICAgaWYgc2VsZi5fZW5fcGxhY2Vob2xkZXI6CiAgICAgICAgICAg
:::ICAgICBzZWxmLmVudF91cmwuZGVsZXRlKDAsICdlbmQnKQogICAgICAgICAgICAg
:::ICAgc2VsZi5fZW5fcGxhY2Vob2xkZXIgPSBGYWxzZQogICAgICAgICAgICAgICAg
:::c2VsZi5fcmVmcmVzY2FyX3BsYWNlaG9sZGVyKCkKCiAgICAgICAgZGVmIF9vbl9m
:::b2N1c191cmxfb3V0KHNlbGYsIF9lPU5vbmUpOgogICAgICAgICAgICBpZiBub3Qg
:::c2VsZi5lbnRfdXJsLmdldCgpOgogICAgICAgICAgICAgICAgc2VsZi5fZW5fcGxh
:::Y2Vob2xkZXIgPSBUcnVlCiAgICAgICAgICAgICAgICBzZWxmLl9wb25lcl9wbGFj
:::ZWhvbGRlcigpCiAgICAgICAgICAgICAgICBzZWxmLl9yZWZyZXNjYXJfcGxhY2Vo
:::b2xkZXIoKQoKICAgICAgICBkZWYgX29uX3RlbWEoc2VsZiwgX2U9Tm9uZSk6CiAg
:::ICAgICAgICAgIHNlbGYuX3RlbWFfYWN0dWFsID0gc2VsZi5jbWJfdGVtYS5nZXQo
:::KQogICAgICAgICAgICBBSlVTVEVTWyd0ZW1hJ10gPSBzZWxmLl90ZW1hX2FjdHVh
:::bAogICAgICAgICAgICBndWFyZGFyX2FqdXN0ZXMoKQogICAgICAgICAgICBzZWxm
:::Ll9hcGxpY2FyX3RlbWEoKQoKICAgICAgICBkZWYgX29uX2Zvcm1hdG8oc2VsZiwg
:::X2U9Tm9uZSk6CiAgICAgICAgICAgIGZtdCA9IHNlbGYuX2ZtdF9hY3R1YWwoKQog
:::ICAgICAgICAgICBzZWxmLl9yZWNhcmdhcl9jYWxpZGFkZXMoZm10KQogICAgICAg
:::ICAgICBzZWxmLl9ndWFyZGFyKCkKICAgICAgICAgICAgc2VsZi5sYmxfZXN0aW1h
:::Y2lvbi5jb25maWd1cmUoCiAgICAgICAgICAgICAgICB0ZXh0PSdJbnRyb2R1Y2Ug
:::dW5hIFVSTCB5IHB1bHNhIEVzdGltYXIuJywKICAgICAgICAgICAgICAgIGZnPVRF
:::TUFTW3NlbGYuX3RlbWFfYWN0dWFsXVsndGV4dG8nXSkKCiAgICAgICAgZGVmIF9m
:::bXRfYWN0dWFsKHNlbGYpOgogICAgICAgICAgICB0ZXh0byA9IHNlbGYuY21iX2Zv
:::cm1hdG8uZ2V0KCkKICAgICAgICAgICAgZm9yIGNsYXZlLCBmIGluIEZPUk1BVE9T
:::Lml0ZW1zKCk6CiAgICAgICAgICAgICAgICBpZiBmWyd0ZXh0byddID09IHRleHRv
:::OgogICAgICAgICAgICAgICAgICAgIHJldHVybiBjbGF2ZQogICAgICAgICAgICBy
:::ZXR1cm4gJ0FBQycKCiAgICAgICAgZGVmIF9yZWNhcmdhcl9jYWxpZGFkZXMoc2Vs
:::ZiwgY2xhdmVfZm10LCBjYWxpZGFkX3ByZXZpYT1Ob25lKToKICAgICAgICAgICAg
:::ZiA9IEZPUk1BVE9TW2NsYXZlX2ZtdF0KICAgICAgICAgICAgc2VsZi5jbWJfY2Fs
:::aWRhZFsndmFsdWVzJ10gPSBmWydjYWxpZGFkZXMnXQogICAgICAgICAgICBpZiBj
:::YWxpZGFkX3ByZXZpYSBhbmQgY2FsaWRhZF9wcmV2aWEgaW4gZlsnY2FsaWRhZGVz
:::J106CiAgICAgICAgICAgICAgICBzZWxmLmNtYl9jYWxpZGFkLnNldChjYWxpZGFk
:::X3ByZXZpYSkKICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgIHNlbGYu
:::Y21iX2NhbGlkYWQuc2V0KGZbJ2RlZmVjdG8nXSkKICAgICAgICAgICAgQUpVU1RF
:::U1snZm9ybWF0byddID0gY2xhdmVfZm10CiAgICAgICAgICAgIEFKVVNURVNbJ2Nh
:::bGlkYWQnXSA9IHNlbGYuY21iX2NhbGlkYWQuZ2V0KCkKCiAgICAgICAgZGVmIF9n
:::dWFyZGFyKHNlbGYpOgogICAgICAgICAgICBBSlVTVEVTWydmb3JtYXRvJ10gPSBz
:::ZWxmLl9mbXRfYWN0dWFsKCkKICAgICAgICAgICAgQUpVU1RFU1snY2FsaWRhZCdd
:::ID0gc2VsZi5jbWJfY2FsaWRhZC5nZXQoKQogICAgICAgICAgICBBSlVTVEVTWydl
:::bWJlYmVyJ10gPSBib29sKHNlbGYudmFyX2VtYmViZXIuZ2V0KCkpCiAgICAgICAg
:::ICAgIEFKVVNURVNbJ2Rlc3Rpbm8nXSA9IHNlbGYuZW50X2NhcnBldGEuZ2V0KCku
:::c3RyaXAoKQogICAgICAgICAgICB2YWwgPSBzZWxmLmNtYl9jb29raWVzLmdldCgp
:::CiAgICAgICAgICAgIEFKVVNURVNbJ2Nvb2tpZXMnXSA9ICgnJyBpZiB2YWwuc3Rh
:::cnRzd2l0aCgnQXV0b23DoXRpY28nKSBlbHNlCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICB2YWwucmVwbGFjZSgnVXNhciBjb29raWVzIGRlICcsICcn
:::KQogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLnN0cmlwKCkubG93
:::ZXIoKSkKICAgICAgICAgICAgZ3VhcmRhcl9hanVzdGVzKCkKCiAgICAgICAgZGVm
:::IF9vbl9jYXJwZXRhX2VzY3JpdGEoc2VsZiwgX2U9Tm9uZSk6CiAgICAgICAgICAg
:::IHAgPSBQYXRoKG9zLnBhdGguZXhwYW5kdmFycygKICAgICAgICAgICAgICAgIHNl
:::bGYuZW50X2NhcnBldGEuZ2V0KCkuc3RyaXAoKS5zdHJpcCgnIicpKSkKICAgICAg
:::ICAgICAgdHJ5OgogICAgICAgICAgICAgICAgcC5ta2RpcihwYXJlbnRzPVRydWUs
:::IGV4aXN0X29rPVRydWUpCiAgICAgICAgICAgICAgICBBSlVTVEVTWydkZXN0aW5v
:::J10gPSBzdHIocCkKICAgICAgICAgICAgICAgIGd1YXJkYXJfYWp1c3RlcygpCiAg
:::ICAgICAgICAgIGV4Y2VwdCBPU0Vycm9yIGFzIGU6CiAgICAgICAgICAgICAgICBz
:::ZWxmLl9sb2coZidObyBzZSBwdWRvIHVzYXIgZXNhIGNhcnBldGE6IHtlfScsICdl
:::cnJvcicpCgogICAgICAgIGRlZiBfY2FtYmlhcl9jYXJwZXRhKHNlbGYpOgogICAg
:::ICAgICAgICBhY3R1YWwgPSBzZWxmLmVudF9jYXJwZXRhLmdldCgpLnN0cmlwKCkg
:::b3IgQUpVU1RFU1snZGVzdGlubyddCiAgICAgICAgICAgIG51ZXZhID0gZmlsZWRp
:::YWxvZy5hc2tkaXJlY3RvcnkoCiAgICAgICAgICAgICAgICB0aXRsZT0nRWxpZ2Ug
:::bGEgY2FycGV0YSBkb25kZSBndWFyZGFyIGxhcyBkZXNjYXJnYXMnLAogICAgICAg
:::ICAgICAgICAgaW5pdGlhbGRpcj1hY3R1YWwgaWYgb3MucGF0aC5pc2RpcihhY3R1
:::YWwpIGVsc2Ugc3RyKFBhdGguaG9tZSgpKSkKICAgICAgICAgICAgaWYgbm90IG51
:::ZXZhOgogICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgIHRyeToKICAg
:::ICAgICAgICAgICAgIFBhdGgobnVldmEpLm1rZGlyKHBhcmVudHM9VHJ1ZSwgZXhp
:::c3Rfb2s9VHJ1ZSkKICAgICAgICAgICAgZXhjZXB0IE9TRXJyb3IgYXMgZToKICAg
:::ICAgICAgICAgICAgIG1lc3NhZ2Vib3guc2hvd2Vycm9yKCdDYXJwZXRhIG5vIHbD
:::oWxpZGEnLCBzdHIoZSkpCiAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAg
:::ICAgc2VsZi5lbnRfY2FycGV0YS5kZWxldGUoMCwgJ2VuZCcpCiAgICAgICAgICAg
:::IHNlbGYuZW50X2NhcnBldGEuaW5zZXJ0KDAsIG51ZXZhKQogICAgICAgICAgICBB
:::SlVTVEVTWydkZXN0aW5vJ10gPSBudWV2YQogICAgICAgICAgICBndWFyZGFyX2Fq
:::dXN0ZXMoKQogICAgICAgICAgICBzZWxmLl9sb2coJ0NhcnBldGEgZGUgZ3VhcmRh
:::ZG86ICcgKyBudWV2YSwgJ2dyaXMnKQoKICAgICAgICBkZWYgX2FicmlyX2Rlc3Rp
:::bm8oc2VsZik6CiAgICAgICAgICAgIHAgPSBQYXRoKG9zLnBhdGguZXhwYW5kdmFy
:::cygKICAgICAgICAgICAgICAgIHNlbGYuZW50X2NhcnBldGEuZ2V0KCkuc3RyaXAo
:::KS5zdHJpcCgnIicpKSkKICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAg
:::cC5ta2RpcihwYXJlbnRzPVRydWUsIGV4aXN0X29rPVRydWUpCiAgICAgICAgICAg
:::IGV4Y2VwdCBPU0Vycm9yOgogICAgICAgICAgICAgICAgcGFzcwogICAgICAgICAg
:::ICBhYnJpcl9jYXJwZXRhKHApCgogICAgICAgIGRlZiBfYWxfY2VycmFyKHNlbGYp
:::OgogICAgICAgICAgICBpZiBzZWxmLl9vY3VwYWRvIGFuZCBub3QgbWVzc2FnZWJv
:::eC5hc2tva2NhbmNlbCgKICAgICAgICAgICAgICAgICAgICAnU2FsaXInLCAnSGF5
:::IHVuYSB0YXJlYSBlbiBjdXJzby4gJwogICAgICAgICAgICAgICAgICAgICfCv1Nl
:::Z3VybyBxdWUgcXVpZXJlcyBzYWxpcj8nKToKICAgICAgICAgICAgICAgIHJldHVy
:::bgogICAgICAgICAgICBzZWxmLmRlc3Ryb3koKQoKICAgICAgICAjIC0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSByZWdpc3Ry
:::byAobG9nKQogICAgICAgIGRlZiBfbG9nKHNlbGYsIG1zZywgdGFnPSdpbmZvJyk6
:::CiAgICAgICAgICAgIHNlbGYudHh0X2xvZy5jb25maWd1cmUoc3RhdGU9J25vcm1h
:::bCcpCiAgICAgICAgICAgIG5fbGluZWFzID0gaW50KHNlbGYudHh0X2xvZy5pbmRl
:::eCgnZW5kLTFjJykuc3BsaXQoJy4nKVswXSkKICAgICAgICAgICAgaWYgbl9saW5l
:::YXMgPiA5MDA6CiAgICAgICAgICAgICAgICBzZWxmLnR4dF9sb2cuZGVsZXRlKCcx
:::LjAnLCAnMjAwLjAnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuaW5zZXJ0KCdl
:::bmQnLCBzdHIobXNnKSArICdcbicsIHRhZykKICAgICAgICAgICAgc2VsZi50eHRf
:::bG9nLnNlZSgnZW5kJykKICAgICAgICAgICAgc2VsZi50eHRfbG9nLmNvbmZpZ3Vy
:::ZShzdGF0ZT0nZGlzYWJsZWQnKQoKICAgICAgICBkZWYgX2xpbXBpYXJfbG9nKHNl
:::bGYpOgogICAgICAgICAgICBzZWxmLnR4dF9sb2cuY29uZmlndXJlKHN0YXRlPSdu
:::b3JtYWwnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuZGVsZXRlKCcxLjAnLCAn
:::ZW5kJykKICAgICAgICAgICAgc2VsZi50eHRfbG9nLmNvbmZpZ3VyZShzdGF0ZT0n
:::ZGlzYWJsZWQnKQoKICAgICAgICBkZWYgX2JvbWJlYXJfY29sYShzZWxmKToKICAg
:::ICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgd2hpbGUgVHJ1ZToKICAgICAg
:::ICAgICAgICAgICAgICBldiA9IHNlbGYuY29sYS5nZXRfbm93YWl0KCkKICAgICAg
:::ICAgICAgICAgICAgICB0aXBvID0gZXZbMF0KICAgICAgICAgICAgICAgICAgICBp
:::ZiB0aXBvID09ICdsb2cnOgogICAgICAgICAgICAgICAgICAgICAgICBzZWxmLl9s
:::b2coZXZbMV0sIGV2WzJdKQogICAgICAgICAgICAgICAgICAgIGVsaWYgdGlwbyA9
:::PSAncHJvZyc6CiAgICAgICAgICAgICAgICAgICAgICAgIHBjdCwgdGV4dG8gPSBl
:::dlsxXSwgZXZbMl0KICAgICAgICAgICAgICAgICAgICAgICAgaWYgcGN0IGlzIE5v
:::bmU6CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzZWxmLmJhcnJhLnN0b3Ao
:::KQogICAgICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5iYXJyYS5jb25maWd1
:::cmUobW9kZT0naW5kZXRlcm1pbmF0ZScpCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICBzZWxmLmJhcnJhLnN0YXJ0KDYwKQogICAgICAgICAgICAgICAgICAgICAg
:::ICBlbHNlOgogICAgICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5iYXJyYS5z
:::dG9wKCkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYmFycmEuY29u
:::ZmlndXJlKG1vZGU9J2RldGVybWluYXRlJykKICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgIHNlbGYuYmFycmEuY29uZmlndXJlKHZhbHVlPW1heCgwLCBtaW4oMTAw
:::LCBwY3QpKSkKICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRv
:::LmNvbmZpZ3VyZSh0ZXh0PXRleHRvKQogICAgICAgICAgICAgICAgICAgIGVsaWYg
:::dGlwbyA9PSAnZXN0aW1hY2lvbic6CiAgICAgICAgICAgICAgICAgICAgICAgIHNl
:::bGYubGJsX2VzdGltYWNpb24uY29uZmlndXJlKAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgdGV4dD1ldlsxXSwgZmc9VEVNQVNbc2VsZi5fdGVtYV9hY3R1YWxd
:::WydhY2VudG8nXSkKICAgICAgICAgICAgICAgICAgICBlbGlmIHRpcG8gPT0gJ2Zp
:::bic6CiAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuX2Zpbl90YXJlYShldlsx
:::XSwgZXZbMl0sIGV2WzNdIGlmIGxlbihldikgPiAzIGVsc2UgJycpCiAgICAgICAg
:::ICAgIGV4Y2VwdCBxdWV1ZS5FbXB0eToKICAgICAgICAgICAgICAgIHBhc3MKICAg
:::ICAgICAgICAgc2VsZi5hZnRlcig4MCwgc2VsZi5fYm9tYmVhcl9jb2xhKQoKICAg
:::ICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLSB0YXJlYXMKICAgICAgICBkZWYgX2hhYmlsaXRhcl9hY2Npb25lcyhz
:::ZWxmLCBvbik6CiAgICAgICAgICAgIGVzdGFkbyA9ICdub3JtYWwnIGlmIG9uIGVs
:::c2UgJ2Rpc2FibGVkJwogICAgICAgICAgICBmb3IgYiBpbiAoc2VsZi5idG5fZGVz
:::Y2FyZ2FyLCBzZWxmLmJ0bl9jb21wcm9iYXIsCiAgICAgICAgICAgICAgICAgICAg
:::ICBzZWxmLmJ0bl9lc3RpbWFyLCBzZWxmLmJ0bl9jYW1iaWFyLCBzZWxmLmJ0bl9h
:::YnJpciwKICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYnRuX3BlZ2FyLCBzZWxm
:::LmJ0bl94KToKICAgICAgICAgICAgICAgIGIuY29uZmlndXJlKHN0YXRlPWVzdGFk
:::bywgY3Vyc29yPSdoYW5kMicgaWYgb24gZWxzZSAnYXJyb3cnKQoKICAgICAgICBk
:::ZWYgX2luaWNpYXIoc2VsZiwgb2JqZXRpdm8sIGNmZywgdGV4dG8pOgogICAgICAg
:::ICAgICBpZiBzZWxmLl9vY3VwYWRvOgogICAgICAgICAgICAgICAgc2VsZi5fbG9n
:::KCdZYSBoYXkgdW5hIHRhcmVhIGVuIGN1cnNvOyBlc3BlcmEgYSBxdWUgdGVybWlu
:::ZS4nLAogICAgICAgICAgICAgICAgICAgICAgICAgICdhdmlzbycpCiAgICAgICAg
:::ICAgICAgICByZXR1cm4gRmFsc2UKICAgICAgICAgICAgc2VsZi5fb2N1cGFkbyA9
:::IFRydWUKICAgICAgICAgICAgc2VsZi5faGFiaWxpdGFyX2FjY2lvbmVzKEZhbHNl
:::KQogICAgICAgICAgICBzZWxmLmxibF9lc3RhZG8uY29uZmlndXJlKHRleHQ9dGV4
:::dG8pCiAgICAgICAgICAgIHRocmVhZGluZy5UaHJlYWQodGFyZ2V0PW9iamV0aXZv
:::LCBhcmdzPShjZmcsKSwgZGFlbW9uPVRydWUpLnN0YXJ0KCkKICAgICAgICAgICAg
:::cmV0dXJuIFRydWUKCiAgICAgICAgZGVmIF9maW5fdGFyZWEoc2VsZiwgdGlwbywg
:::b2ssIG1lbnNhamU9JycpOgogICAgICAgICAgICBzZWxmLl9vY3VwYWRvID0gRmFs
:::c2UKICAgICAgICAgICAgc2VsZi5faGFiaWxpdGFyX2FjY2lvbmVzKFRydWUpCiAg
:::ICAgICAgICAgIHNlbGYuYmFycmEuc3RvcCgpCiAgICAgICAgICAgIHNlbGYuYmFy
:::cmEuY29uZmlndXJlKG1vZGU9J2RldGVybWluYXRlJykKICAgICAgICAgICAgc2Vs
:::Zi5iYXJyYS5jb25maWd1cmUodmFsdWU9MCkKICAgICAgICAgICAgaWYgdGlwbyA9
:::PSAnZGVzY2FyZ2EnIGFuZCBvazoKICAgICAgICAgICAgICAgIHNlbGYubGJsX2Vz
:::dGFkby5jb25maWd1cmUodGV4dD0nTGlzdG8uJykKICAgICAgICAgICAgICAgICMg
:::TGEgZGVzY2FyZ2EgZnVlIGJpZW46IHNlIGxpbXBpYSBsYSBVUkwgcGFyYSBsYSBz
:::aWd1aWVudGUuCiAgICAgICAgICAgICAgICBzZWxmLl9yZXNldF91cmwoKQogICAg
:::ICAgICAgICBlbGlmIG5vdCBvazoKICAgICAgICAgICAgICAgIHNlbGYubGJsX2Vz
:::dGFkby5jb25maWd1cmUodGV4dD0nVGVybWluYWRvIGNvbiBlcnJvcmVzLicpCiAg
:::ICAgICAgICAgICAgICBpZiB0aXBvID09ICdkZXNjYXJnYSc6CiAgICAgICAgICAg
:::ICAgICAgICAgbWVzc2FnZWJveC5zaG93ZXJyb3IoCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICdFcnJvcicsIG1lbnNhamUgb3IgJ05vIHNlIHB1ZG8gY29tcGxldGFy
:::IGxhIHRhcmVhLiAnCiAgICAgICAgICAgICAgICAgICAgICAgICdSZXZpc2EgZWwg
:::cmVnaXN0cm8gcGFyYSBtw6FzIGRldGFsbGVzLicpCgogICAgICAgIGRlZiBfdXJs
:::X3ZhbGlkYShzZWxmKToKICAgICAgICAgICAgaWYgc2VsZi5fZW5fcGxhY2Vob2xk
:::ZXI6CiAgICAgICAgICAgICAgICBzZWxmLl9sb2coJ1ByaW1lcm8gcGVnYSBsYSBV
:::UkwgZGVsIHZpZGVvIGRlIFlvdVR1YmUuJywgJ2F2aXNvJykKICAgICAgICAgICAg
:::ICAgIHJldHVybiBOb25lCiAgICAgICAgICAgIHUgPSBzZWxmLmVudF91cmwuZ2V0
:::KCkuc3RyaXAoKS5zdHJpcCgnIicpLnN0cmlwKCInIikKICAgICAgICAgICAgaWYg
:::bm90IHU6CiAgICAgICAgICAgICAgICBzZWxmLl9sb2coJ0xhIFVSTCBlc3TDoSB2
:::YWPDrWEuJywgJ2F2aXNvJykKICAgICAgICAgICAgICAgIHJldHVybiBOb25lCiAg
:::ICAgICAgICAgIGlmIG5vdCByZS5tYXRjaChyJ15odHRwcz86Ly8nLCB1LCByZS5J
:::KToKICAgICAgICAgICAgICAgIGlmIHJlLm1hdGNoKHInXnd3d1wuJywgdSwgcmUu
:::SSk6CiAgICAgICAgICAgICAgICAgICAgdSA9ICdodHRwczovLycgKyB1CiAgICAg
:::ICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgIHNlbGYuX2xvZygn
:::RXNvIG5vIHBhcmVjZSB1bmEgVVJMIChkZWJlIGVtcGV6YXIgcG9yICcKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgJ2h0dHA6Ly8gbyBodHRwczovLyknLCAn
:::ZXJyb3InKQogICAgICAgICAgICAgICAgICAgIHJldHVybiBOb25lCiAgICAgICAg
:::ICAgICMgT0pPOiBhcXXDrSBOTyBzZSBxdWl0YSBsaXN0PTsgc2kgbGEgVVJMIHRy
:::YWUgdW5hIHBsYXlsaXN0LAogICAgICAgICAgICAjIF9hY2Npb25fZGVzY2FyZ2Fy
:::IHByZWd1bnRhcsOhIHF1w6kgaGFjZXIgY29uIGVsbGEuCiAgICAgICAgICAgIHJl
:::dHVybiB1CgogICAgICAgIGRlZiBfYWNjaW9uX2VzdGltYXIoc2VsZik6CiAgICAg
:::ICAgICAgIHVybCA9IHNlbGYuX3VybF92YWxpZGEoKQogICAgICAgICAgICBpZiBu
:::b3QgdXJsOgogICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgIHNlbGYu
:::X2d1YXJkYXIoKQogICAgICAgICAgICBjZmcgPSB7J3VybCc6IHVybH0KICAgICAg
:::ICAgICAgc2VsZi5faW5pY2lhcihzZWxmLl9oaWxvX2VzdGltYXIsIGNmZywgJ0Vz
:::dGltYW5kbyB0YW1hw7FvLi4uJykKICAgICAgICAgICAgc2VsZi5sYmxfZXN0aW1h
:::Y2lvbi5jb25maWd1cmUoCiAgICAgICAgICAgICAgICB0ZXh0PSdDYWxjdWxhbmRv
:::Li4uJywgZmc9VEVNQVNbc2VsZi5fdGVtYV9hY3R1YWxdWyd0ZXh0bzInXSkKCiAg
:::ICAgICAgZGVmIF9hY2Npb25fZGVzY2FyZ2FyKHNlbGYpOgogICAgICAgICAgICB1
:::cmwgPSBzZWxmLl91cmxfdmFsaWRhKCkKICAgICAgICAgICAgaWYgbm90IHVybDoK
:::ICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICBzZWxmLl9ndWFyZGFy
:::KCkKICAgICAgICAgICAgcGxheWxpc3QgPSBGYWxzZQogICAgICAgICAgICBpZiBl
:::c191cmxfcGxheWxpc3QodXJsKToKICAgICAgICAgICAgICAgIHIgPSBtZXNzYWdl
:::Ym94LmFza3llc25vY2FuY2VsKAogICAgICAgICAgICAgICAgICAgICdNdXNpa0FM
:::QU4g4oCUIGxpc3RhIGRlIHJlcHJvZHVjY2nDs24nLAogICAgICAgICAgICAgICAg
:::ICAgICdFc3RhIFVSTCBwZXJ0ZW5lY2UgYSB1bmEgbGlzdGEgZGUgcmVwcm9kdWNj
:::acOzbi5cblxuJwogICAgICAgICAgICAgICAgICAgICcgIFPDjSAg4oaSICBkZXNj
:::YXJnYXIgbGEgcGxheWxpc3QgY29tcGxldGFcbicKICAgICAgICAgICAgICAgICAg
:::ICAnICAgICAgICAgKHBhdXNhIGRlIDIgcyBlbnRyZSBjYW5jaW9uZXMpXG4nCiAg
:::ICAgICAgICAgICAgICAgICAgJyAgTk8gIOKGkiAgZGVzY2FyZ2FyIHNvbG8gZXN0
:::YSBjYW5jacOzblxuJwogICAgICAgICAgICAgICAgICAgICcgIENhbmNlbGFyICDi
:::hpIgIG5vIGRlc2NhcmdhciBuYWRhJykKICAgICAgICAgICAgICAgIGlmIHIgaXMg
:::Tm9uZToKICAgICAgICAgICAgICAgICAgICBzZWxmLl9sb2coJ0Rlc2NhcmdhIGNh
:::bmNlbGFkYS4nLCAnZ3JpcycpCiAgICAgICAgICAgICAgICAgICAgcmV0dXJuCiAg
:::ICAgICAgICAgICAgICBpZiByOgogICAgICAgICAgICAgICAgICAgIHBsYXlsaXN0
:::ID0gVHJ1ZQogICAgICAgICAgICAgICAgZWxpZiBlc19zb2xvX2xpc3RhKHVybCk6
:::CiAgICAgICAgICAgICAgICAgICAgIyBFcyB1bmEgcGxheWxpc3QgcHVyYTogbm8g
:::aGF5ICJ1bmEgY2FuY2nDs24iIGFow60KICAgICAgICAgICAgICAgICAgICBzZWxm
:::Ll9sb2coJ0VzYSBVUkwgZXMgdW5hIGxpc3RhIGNvbXBsZXRhOyBzZSBkZXNjYXJn
:::YXLDoSAnCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICdlbnRlcmEuJywg
:::J2F2aXNvJykKICAgICAgICAgICAgICAgICAgICBwbGF5bGlzdCA9IFRydWUKICAg
:::ICAgICAgICAgY2ZnID0geyd1cmwnOiB1cmwsICdwbGF5bGlzdCc6IHBsYXlsaXN0
:::fQogICAgICAgICAgICBzZWxmLl9pbmljaWFyKHNlbGYuX2hpbG9fZGVzY2FyZ2Fy
:::LCBjZmcsICdEZXNjYXJnYW5kby4uLicpCgogICAgICAgIGRlZiBfYWNjaW9uX2Nv
:::bXByb2JhcihzZWxmKToKICAgICAgICAgICAgc2VsZi5fZ3VhcmRhcigpCiAgICAg
:::ICAgICAgIHNlbGYuX2luaWNpYXIoc2VsZi5faGlsb19jb21wcm9iYXIsIHt9LAog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICdDb21wcm9iYW5kbyBsYSBjYXJwZXRh
:::Li4uJykKCiAgICAgICAgZGVmIF9hY2Npb25fYWN0dWFsaXphcihzZWxmKToKICAg
:::ICAgICAgICAgaWYgbm90IFlUX0RMUDoKICAgICAgICAgICAgICAgIHNlbGYuX2xv
:::ZygneXQtZGxwIG5vIGVzdMOhIGluc3RhbGFkbzsgZWplY3V0YSAnCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgJ0Rlc2NhcmdhZG9yTXVzaWNhLmJhdC4nLCAnZXJy
:::b3InKQogICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgIHNlbGYuX2lu
:::aWNpYXIoc2VsZi5faGlsb19hY3R1YWxpemFyLCB7fSwgJ0FjdHVhbGl6YW5kbyB5
:::dC1kbHAuLi4nKQoKICAgICAgICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBoaWxvcwogICAgICAgIGRlZiBfaGlsb19l
:::c3RpbWFyKHNlbGYsIGNmZyk6CiAgICAgICAgICAgIGNvbGEgPSBzZWxmLmNvbGEK
:::CiAgICAgICAgICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgogICAgICAgICAgICAg
:::ICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICAgICAgICAgIHRyeToKICAg
:::ICAgICAgICAgICAgIGlmIFlUX0RMUCBpcyBOb25lOgogICAgICAgICAgICAgICAg
:::ICAgIGxvZygneXQtZGxwIG5vIGVzdMOhIGluc3RhbGFkby4gRWplY3V0YSAnCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICdEZXNjYXJnYWRvck11c2ljYS5iYXQgcGFy
:::YSBpbnN0YWxhcmxvLicsICdlcnJvcicpCiAgICAgICAgICAgICAgICAgICAgY29s
:::YS5wdXQoKCdlc3RpbWFjaW9uJywgJ3l0LWRscCBubyBkaXNwb25pYmxlJykpCiAg
:::ICAgICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgICAgICBsb2coJ09i
:::dGVuaWVuZG8gaW5mb3JtYWNpw7NuIGRlbCB2aWRlby4uLicsICdncmlzJykKICAg
:::ICAgICAgICAgICAgIG8gPSB7J3F1aWV0JzogVHJ1ZSwgJ25vX3dhcm5pbmdzJzog
:::VHJ1ZSwgJ25vcGxheWxpc3QnOiBUcnVlLAogICAgICAgICAgICAgICAgICAgICAn
:::c29ja2V0X3RpbWVvdXQnOiAzMCwgJ2xvZ2dlcic6IFJFR0lTVFJPfQogICAgICAg
:::ICAgICAgICAgX2FudGlfYm90KG8pCiAgICAgICAgICAgICAgICBpZiBlc191cmxf
:::cGxheWxpc3QoY2ZnWyd1cmwnXSk6CiAgICAgICAgICAgICAgICAgICAgbG9nKCco
:::bGEgVVJMIGNvbnRpZW5lIHVuYSBwbGF5bGlzdDogbGEgZXN0aW1hY2nDs24gZXMg
:::JwogICAgICAgICAgICAgICAgICAgICAgICAnc29sbyBkZWwgdmlkZW8gcGVnYWRv
:::KScsICdncmlzJykKICAgICAgICAgICAgICAgIHdpdGggWVRfRExQLllvdXR1YmVE
:::TChvKSBhcyB5ZGw6CiAgICAgICAgICAgICAgICAgICAgaW5mbyA9IHlkbC5leHRy
:::YWN0X2luZm8oY2ZnWyd1cmwnXSwgZG93bmxvYWQ9RmFsc2UpCiAgICAgICAgICAg
:::ICAgICBkdXIgPSBpbmZvLmdldCgnZHVyYXRpb24nKQogICAgICAgICAgICAgICAg
:::aWYgbm90IGR1cjoKICAgICAgICAgICAgICAgICAgICBsb2coJ05vIHNlIHB1ZG8g
:::b2J0ZW5lciBsYSBkdXJhY2nDs24gZGVsIHZpZGVvLicsICdlcnJvcicpCiAgICAg
:::ICAgICAgICAgICAgICAgY29sYS5wdXQoKCdlc3RpbWFjaW9uJywgJ1NpbiBkYXRv
:::cyBwYXJhIGVzdGltYXInKSkKICAgICAgICAgICAgICAgICAgICByZXR1cm4KICAg
:::ICAgICAgICAgICAgIGNsYXZlID0gc2VsZi5fZm10X2FjdHVhbF9zb2xvKEFKVVNU
:::RVMuZ2V0KCdmb3JtYXRvJywgJ0FBQycpKQogICAgICAgICAgICAgICAgdGFtID0g
:::ZXN0aW1hcl9ieXRlcyhkdXIsIGNsYXZlLCBBSlVTVEVTLmdldCgnY2FsaWRhZCcp
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBib29sKEFKVVNU
:::RVMuZ2V0KCdlbWJlYmVyJywgVHJ1ZSkpKQogICAgICAgICAgICAgICAgdGl0dWxv
:::ID0gc3RyKGluZm8uZ2V0KCd0aXRsZScpIG9yICcnKVs6NzBdCiAgICAgICAgICAg
:::ICAgICBpZiB0aXR1bG86CiAgICAgICAgICAgICAgICAgICAgbG9nKCfimaogJyAr
:::IHRpdHVsbywgJ3RpdHVsbycpCiAgICAgICAgICAgICAgICB0ZXh0byA9IChmJ357
:::dGFtIC8gMTA0ODU3NjouMWZ9IE1CIMK3ICcKICAgICAgICAgICAgICAgICAgICAg
:::ICAgIGYnZHVyYWNpw7NuIHtmbXRfdGllbShkdXIpfSDCtyAnCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICBmJ3tjbGF2ZX0ge0FKVVNURVMuZ2V0KCJjYWxpZGFkIiwg
:::IiIpfScucnN0cmlwKCkpCiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2VzdGlt
:::YWNpb24nLCB0ZXh0bykpCiAgICAgICAgICAgICAgICBsb2coJ0VzdGltYWNpw7Nu
:::OiAnICsgdGV4dG8sICdvaycpCiAgICAgICAgICAgICAgICBsb2coJ0VsIHRhbWHD
:::sW8gcmVhbCBwdWVkZSB2YXJpYXIgYWxnbyBzZWfDum4gbGEgZnVlbnRlLicsCiAg
:::ICAgICAgICAgICAgICAgICAgJ2dyaXMnKQogICAgICAgICAgICBleGNlcHQgRXhj
:::ZXB0aW9uIGFzIGU6CiAgICAgICAgICAgICAgICBsb2coZidObyBzZSBwdWRvIGVz
:::dGltYXI6IHtzZWxmLl9tc2dfZXJyb3IoZSl9JywgJ2Vycm9yJykKICAgICAgICAg
:::ICAgICAgIGNvbGEucHV0KCgnZXN0aW1hY2lvbicsICdObyBzZSBwdWRvIGVzdGlt
:::YXInKSkKICAgICAgICAgICAgZmluYWxseToKICAgICAgICAgICAgICAgIGNvbGEu
:::cHV0KCgnZmluJywgJ2VzdGltYWNpb24nLCBUcnVlLCAnJykpCgogICAgICAgIGRl
:::ZiBfZm10X2FjdHVhbF9zb2xvKHNlbGYsIGNsYXZlKToKICAgICAgICAgICAgcmV0
:::dXJuIGNsYXZlIGlmIGNsYXZlIGluIEZPUk1BVE9TIGVsc2UgJ0FBQycKCiAgICAg
:::ICAgZGVmIF9kZXNjYXJnYXJfdW5hKHNlbGYsIHVybCwgY2xhdmUsIGNhbGlkYWRf
:::YXJnLCBlbWJlYmVyLCBkZXN0aW5vLAogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICBjb2xhKToKICAgICAgICAgICAgIiIiRGVzY2FyZ2EgeSBjb252aWVydGUgVU5B
:::IFVSTC4gRGV2dWVsdmUgZWwgUGF0aCBmaW5hbCBvIE5vbmUuIiIiCiAgICAgICAg
:::ICAgIGlmIGNsYXZlID09ICdXTUEnOgogICAgICAgICAgICAgICAgcmV0dXJuIGRl
:::c2Nhcmdhcl93bWEodXJsLCBjYWxpZGFkX2FyZywgZGVzdGlubywgZW1iZWJlciwK
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbGEpWzFdCiAg
:::ICAgICAgICAgIGlmIGNsYXZlID09ICdBVkknOgogICAgICAgICAgICAgICAgcmV0
:::dXJuIGRlc2Nhcmdhcl9hdmkodXJsLCBkZXN0aW5vLCBjb2xhKVsxXQogICAgICAg
:::ICAgICByZXR1cm4gZGVzY2FyZ2FyX2F1ZGlvKHVybCwgY2xhdmUsIGNhbGlkYWRf
:::YXJnLCBkZXN0aW5vLCBlbWJlYmVyLAogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgIGNvbGEpWzFdCgogICAgICAgIGRlZiBfZGVzY2FyZ2FyX3BsYXls
:::aXN0KHNlbGYsIHVybCwgY2xhdmUsIGNhbGlkYWRfYXJnLCBlbWJlYmVyLAogICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRlc3Rpbm8sIGNvbGEpOgogICAg
:::ICAgICAgICAiIiJCYWphIHVuYSBsaXN0YSBlbnRlcmEsIGNvbiAyIHMgZGUgZGVz
:::Y2Fuc28gZW50cmUgY2FuY2lvbmVzCiAgICAgICAgICAgIHBhcmEgbm8gc2F0dXJh
:::ciBhIFlvdVR1YmUuIERldnVlbHZlIChkZXNjYXJnYWRhcywgdG90YWwpLiIiIgog
:::ICAgICAgICAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAgICAgICAgICAg
:::IGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAgICAgICAgICBsb2coJ0xleWVu
:::ZG8gbGEgbGlzdGEgZGUgcmVwcm9kdWNjacOzbi4uLicsICdncmlzJykKICAgICAg
:::ICAgICAgbyA9IHsncXVpZXQnOiBUcnVlLCAnbm9fd2FybmluZ3MnOiBUcnVlLAog
:::ICAgICAgICAgICAgICAgICdleHRyYWN0X2ZsYXQnOiAnaW5fcGxheWxpc3QnLCAn
:::c29ja2V0X3RpbWVvdXQnOiAzMCwKICAgICAgICAgICAgICAgICAnbG9nZ2VyJzog
:::UkVHSVNUUk99CiAgICAgICAgICAgIF9hbnRpX2JvdChvKQogICAgICAgICAgICB3
:::aXRoIFlUX0RMUC5Zb3V0dWJlREwobykgYXMgeWRsOgogICAgICAgICAgICAgICAg
:::aW5mbyA9IHlkbC5leHRyYWN0X2luZm8odXJsLCBkb3dubG9hZD1GYWxzZSkKICAg
:::ICAgICAgICAgZW50cmFkYXMgPSBsaXN0KGluZm8uZ2V0KCdlbnRyaWVzJykgb3Ig
:::W10pCiAgICAgICAgICAgIGlmIG5vdCBlbnRyYWRhczoKICAgICAgICAgICAgICAg
:::IGxvZygnTm8gc2UgdmlvIG5pbmd1bmEgY2FuY2nDs24gZW4gbGEgbGlzdGE7IHNl
:::IGludGVudGEgJwogICAgICAgICAgICAgICAgICAgICdjb21vIHZpZGVvIHN1ZWx0
:::by4nLCAnYXZpc28nKQogICAgICAgICAgICAgICAgYXJjaGl2byA9IHNlbGYuX2Rl
:::c2Nhcmdhcl91bmEoc2luX3BsYXlsaXN0KHVybClbMF0sIGNsYXZlLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY2FsaWRhZF9h
:::cmcsIGVtYmViZXIsIGRlc3Rpbm8sCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICBjb2xhKQogICAgICAgICAgICAgICAgcmV0dXJu
:::ICgxIGlmIGFyY2hpdm8gZWxzZSAwKSwgMQogICAgICAgICAgICB0aXR1bG9fcGwg
:::PSBzdHIoaW5mby5nZXQoJ3RpdGxlJykgb3IgJ2xpc3RhJylbOjcwXQogICAgICAg
:::ICAgICB0b3RhbCA9IGxlbihlbnRyYWRhcykKICAgICAgICAgICAgbG9nKGYnUGxh
:::eWxpc3Qgwqt7dGl0dWxvX3BsfcK7IOKAlCB7dG90YWx9IHbDrWRlbyhzKS4nLCAn
:::dGl0dWxvJykKICAgICAgICAgICAgb2thcyA9IDAKICAgICAgICAgICAgZmFsbG9z
:::ID0gW10KICAgICAgICAgICAgZm9yIGksIGUgaW4gZW51bWVyYXRlKGVudHJhZGFz
:::KToKICAgICAgICAgICAgICAgIHUgPSBzdHIoZS5nZXQoJ3dlYnBhZ2VfdXJsJykg
:::b3IgZS5nZXQoJ3VybCcpIG9yICcnKQogICAgICAgICAgICAgICAgaWYgdSBhbmQg
:::bm90IHUuc3RhcnRzd2l0aCgnaHR0cCcpOgogICAgICAgICAgICAgICAgICAgIHUg
:::PSAnaHR0cHM6Ly93d3cueW91dHViZS5jb20vd2F0Y2g/dj0nICsgdQogICAgICAg
:::ICAgICAgICAgaWYgbm90IHUgYW5kIGUuZ2V0KCdpZCcpOgogICAgICAgICAgICAg
:::ICAgICAgIHUgPSAnaHR0cHM6Ly93d3cueW91dHViZS5jb20vd2F0Y2g/dj0nICsg
:::c3RyKGVbJ2lkJ10pCiAgICAgICAgICAgICAgICB0aXQgPSBzdHIoZS5nZXQoJ3Rp
:::dGxlJykgb3IgdSBvciAnPycpWzo3MF0KICAgICAgICAgICAgICAgIGlmIGk6CiAg
:::ICAgICAgICAgICAgICAgICAgdGltZS5zbGVlcCgyKSAgICMgZGVzY2Fuc28gZW50
:::cmUgY2FuY2lvbmVzCiAgICAgICAgICAgICAgICBsb2coZidbe2kgKyAxfS97dG90
:::YWx9XSDimaoge3RpdH0nLCAndGl0dWxvJykKICAgICAgICAgICAgICAgIHRyeToK
:::ICAgICAgICAgICAgICAgICAgICBhcmNoaXZvID0gc2VsZi5fZGVzY2FyZ2FyX3Vu
:::YSh1LCBjbGF2ZSwgY2FsaWRhZF9hcmcsCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgZW1iZWJlciwgZGVzdGlubywgY29s
:::YSkKICAgICAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZTI6CiAgICAg
:::ICAgICAgICAgICAgICAgaWYgX2VzX2Jsb3F1ZW9fYm90KHN0cihlMikpOgogICAg
:::ICAgICAgICAgICAgICAgICAgICAjIGJsb3F1ZW8gYW50aS1ib3Q6IGFib3J0YXIg
:::cGFyYSBxdWUgZWwgcmVpbnRlbnRvCiAgICAgICAgICAgICAgICAgICAgICAgICMg
:::YXV0b23DoXRpY28gZGUgX2hpbG9fZGVzY2FyZ2FyIHNlIGVuY2FyZ3VlCiAgICAg
:::ICAgICAgICAgICAgICAgICAgIHJhaXNlCiAgICAgICAgICAgICAgICAgICAgYXJj
:::aGl2byA9IE5vbmUKICAgICAgICAgICAgICAgICAgICBsb2coZifinJYgW3tpICsg
:::MX0ve3RvdGFsfV0gRmFsbMOzOiB7c2VsZi5fbXNnX2Vycm9yKGUyKX0nLAogICAg
:::ICAgICAgICAgICAgICAgICAgICAnZXJyb3InKQogICAgICAgICAgICAgICAgaWYg
:::YXJjaGl2byBhbmQgUGF0aChhcmNoaXZvKS5leGlzdHMoKToKICAgICAgICAgICAg
:::ICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICAgICAgICAgIHRhbSA9IGZtdF90
:::YW0oUGF0aChhcmNoaXZvKS5zdGF0KCkuc3Rfc2l6ZSkKICAgICAgICAgICAgICAg
:::ICAgICBleGNlcHQgT1NFcnJvcjoKICAgICAgICAgICAgICAgICAgICAgICAgdGFt
:::ID0gJz8nCiAgICAgICAgICAgICAgICAgICAgbG9nKGYnICAg4pyUIHtQYXRoKGFy
:::Y2hpdm8pLm5hbWV9ICAoe3RhbX0pJwogICAgICAgICAgICAgICAgICAgICAgICBm
:::J3t0ZXh0b19jYWxpZGFkKGNsYXZlLCBjYWxpZGFkX2FyZyl9JywgJ29rJykKICAg
:::ICAgICAgICAgICAgICAgICBva2FzICs9IDEKICAgICAgICAgICAgICAgIGVsc2U6
:::CiAgICAgICAgICAgICAgICAgICAgZmFsbG9zLmFwcGVuZCh0aXQpCiAgICAgICAg
:::ICAgIGxvZyhmJ1BsYXlsaXN0IHRlcm1pbmFkYToge29rYXN9IGRlIHt0b3RhbH0g
:::ZGVzY2FyZ2FkYShzKS4nLAogICAgICAgICAgICAgICAgJ29rJyBpZiBub3QgZmFs
:::bG9zIGVsc2UgJ2F2aXNvJykKICAgICAgICAgICAgaWYgZmFsbG9zOgogICAgICAg
:::ICAgICAgICAgbG9nKCdTaW4gZGVzY2FyZ2FyOiAnCiAgICAgICAgICAgICAgICAg
:::ICAgKyAnIMK3ICcuam9pbihmWzo0MF0gZm9yIGYgaW4gZmFsbG9zWzo4XSkKICAg
:::ICAgICAgICAgICAgICAgICArICgnLi4uJyBpZiBsZW4oZmFsbG9zKSA+IDggZWxz
:::ZSAnJyksICdncmlzJykKICAgICAgICAgICAgcmV0dXJuIG9rYXMsIHRvdGFsCgog
:::ICAgICAgIGRlZiBfaGlsb19kZXNjYXJnYXIoc2VsZiwgY2ZnKToKICAgICAgICAg
:::ICAgY29sYSA9IHNlbGYuY29sYQoKICAgICAgICAgICAgZGVmIGxvZyhtLCB0PSdp
:::bmZvJyk6CiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoK
:::ICAgICAgICAgICAgdXJsID0gY2ZnWyd1cmwnXQogICAgICAgICAgICBjbGF2ZSA9
:::IHNlbGYuX2ZtdF9hY3R1YWxfc29sbyhBSlVTVEVTLmdldCgnZm9ybWF0bycsICdB
:::QUMnKSkKICAgICAgICAgICAgY2FsaWRhZCA9IEFKVVNURVMuZ2V0KCdjYWxpZGFk
:::JywgJzEyOGsnKQogICAgICAgICAgICBlbWJlYmVyID0gYm9vbChBSlVTVEVTLmdl
:::dCgnZW1iZWJlcicsIFRydWUpKQogICAgICAgICAgICBkZXN0aW5vID0gUGF0aChv
:::cy5wYXRoLmV4cGFuZHZhcnMoCiAgICAgICAgICAgICAgICBzdHIoQUpVU1RFUy5n
:::ZXQoJ2Rlc3Rpbm8nLCBfZGVzdGlub19wb3JfZGVmZWN0bygpKSkpKQogICAgICAg
:::ICAgICB0cnk6CiAgICAgICAgICAgICAgICBpZiBZVF9ETFAgaXMgTm9uZToKICAg
:::ICAgICAgICAgICAgICAgICBsb2coJ3l0LWRscCBubyBlc3TDoSBpbnN0YWxhZG8u
:::IEVqZWN1dGEgJwogICAgICAgICAgICAgICAgICAgICAgICAnRGVzY2FyZ2Fkb3JN
:::dXNpY2EuYmF0IHBhcmEgaW5zdGFsYXJsby4nLCAnZXJyb3InKQogICAgICAgICAg
:::ICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2Rlc2NhcmdhJywgRmFsc2UsCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICd5dC1kbHAgbm8gZXN0w6EgaW5z
:::dGFsYWRvLicpKQogICAgICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAg
:::ICAgICAgZGVzdGluby5ta2RpcihwYXJlbnRzPVRydWUsIGV4aXN0X29rPVRydWUp
:::CiAgICAgICAgICAgICAgICBpZiBjbGF2ZSBpbiAoJ0ZMQUMnLCAnV0FWJyk6CiAg
:::ICAgICAgICAgICAgICAgICAgY2FsaWRhZF9hcmcgPSAnMCcKICAgICAgICAgICAg
:::ICAgIGVsc2U6CiAgICAgICAgICAgICAgICAgICAgY2FsaWRhZF9hcmcgPSAocmUu
:::c3ViKHInW14wLTldJywgJycsIHN0cihjYWxpZGFkKSkKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICBvciAoJzEyOCcgaWYgY2xhdmUgPT0gJ0FBQycg
:::ZWxzZSAnMzIwJykpCiAgICAgICAgICAgICAgICBpZiBjZmcuZ2V0KCdwbGF5bGlz
:::dCcpOgogICAgICAgICAgICAgICAgICAgIG9rYXMsIHRvdGFsID0gc2VsZi5fZGVz
:::Y2FyZ2FyX3BsYXlsaXN0KAogICAgICAgICAgICAgICAgICAgICAgICB1cmwsIGNs
:::YXZlLCBjYWxpZGFkX2FyZywgZW1iZWJlciwgZGVzdGlubywgY29sYSkKICAgICAg
:::ICAgICAgICAgICAgICBpZiBva2FzIGFuZCBva2FzID09IHRvdGFsOgogICAgICAg
:::ICAgICAgICAgICAgICAgICBsb2coZidDYXJwZXRhOiB7ZGVzdGlub30nLCAnZ3Jp
:::cycpCiAgICAgICAgICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2Rl
:::c2NhcmdhJywgVHJ1ZSwgJycpKQogICAgICAgICAgICAgICAgICAgIGVsc2U6CiAg
:::ICAgICAgICAgICAgICAgICAgICAgIGNvbGEucHV0KCgKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICdmaW4nLCAnZGVzY2FyZ2EnLCBGYWxzZSwKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgIGYnU2UgZGVzY2FyZ2Fyb24ge29rYXN9IGRlIHt0
:::b3RhbH0gZGUgbGEgJwogICAgICAgICAgICAgICAgICAgICAgICAgICAgJ3BsYXls
:::aXN0LiBMYSBVUkwgbm8gc2UgaGEgYm9ycmFkbyBwb3Igc2kgJwogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgJ3F1aWVyZXMgcmVpbnRlbnRhcmxvLicpKQogICAg
:::ICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICAgICAgYXJjaGl2byA9
:::IHNlbGYuX2Rlc2Nhcmdhcl91bmEoc2luX3BsYXlsaXN0KHVybClbMF0sIGNsYXZl
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::Y2FsaWRhZF9hcmcsIGVtYmViZXIsIGRlc3Rpbm8sCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICBjb2xhKQogICAgICAgICAgICAg
:::ICAgaWYgYXJjaGl2byBhbmQgUGF0aChhcmNoaXZvKS5leGlzdHMoKToKICAgICAg
:::ICAgICAgICAgICAgICBhcmNoaXZvID0gUGF0aChhcmNoaXZvKQogICAgICAgICAg
:::ICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgICAgICAgICAgdGFtID0gZm10
:::X3RhbShhcmNoaXZvLnN0YXQoKS5zdF9zaXplKQogICAgICAgICAgICAgICAgICAg
:::IGV4Y2VwdCBPU0Vycm9yOgogICAgICAgICAgICAgICAgICAgICAgICB0YW0gPSAn
:::PycKICAgICAgICAgICAgICAgICAgICBsb2coZifinJQgwqFMaXN0byEgIHthcmNo
:::aXZvLm5hbWV9ICAoe3RhbX0pJwogICAgICAgICAgICAgICAgICAgICAgICBmJ3t0
:::ZXh0b19jYWxpZGFkKGNsYXZlLCBjYWxpZGFkX2FyZyl9JywgJ29rJykKICAgICAg
:::ICAgICAgICAgICAgICBsb2coZidDYXJwZXRhOiB7YXJjaGl2by5wYXJlbnR9Jywg
:::J2dyaXMnKQogICAgICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2Rl
:::c2NhcmdhJywgVHJ1ZSwgJycpKQogICAgICAgICAgICAgICAgZWxzZToKICAgICAg
:::ICAgICAgICAgICAgICBsb2coJ0VsIGFyY2hpdm8gZmluYWwgbm8gYXBhcmVjacOz
:::IGRvbmRlIHNlIGVzcGVyYWJhLicsCiAgICAgICAgICAgICAgICAgICAgICAgICdl
:::cnJvcicpCiAgICAgICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnZGVz
:::Y2FyZ2EnLCBGYWxzZSwgJycpKQogICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9u
:::IGFzIGU6CiAgICAgICAgICAgICAgICBub21icmVfZXhjID0gdHlwZShlKS5fX25h
:::bWVfXwogICAgICAgICAgICAgICAgaWYgbm9tYnJlX2V4YyA9PSAnRG93bmxvYWRF
:::cnJvcic6CiAgICAgICAgICAgICAgICAgICAgbGluZWFzID0gW2wgZm9yIGwgaW4g
:::c3RyKGUpLnN0cmlwKCkuc3BsaXRsaW5lcygpIGlmIGwuc3RyaXAoKV0KICAgICAg
:::ICAgICAgICAgICAgICBtc2cgPSBsaW5lYXNbMF1bOjMwMF0gaWYgbGluZWFzIGVs
:::c2UgJ2Vycm9yIGRlc2Nvbm9jaWRvJwogICAgICAgICAgICAgICAgICAgIGlmIF9l
:::c19ibG9xdWVvX2JvdChzdHIoZSkpOgogICAgICAgICAgICAgICAgICAgICAgICBp
:::ZiBfQU5USV9CT1RbJ2NvbWJvJ10gPT0gMDoKICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgIGxvZygnWW91VHViZSBlc3TDoSBwaWRpZW5kbyB2ZXJpZmljYWNpw7Nu
:::ICcKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAnYW50aS1ib3QgcGFy
:::YSBlc3RhIHJlZC4gUmVpbnRlbnRhbmRvIGNvbiAnCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgJ3VuYSB2w61hIGludGVybmEgYWx0ZXJuYXRpdmEuLi4n
:::LCAnYXZpc28nKQogICAgICAgICAgICAgICAgICAgICAgICAgICAgX0FOVElfQk9U
:::Wydjb21ibyddID0gMQogICAgICAgICAgICAgICAgICAgICAgICAgICAgdHJ5Ogog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRpbWUuc2xlZXAoMykgICAj
:::IHJlc3Bpcm8gcGFyYSBlbCA0MjkKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICBzZWxmLl9oaWxvX2Rlc2NhcmdhcihjZmcpCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICBmaW5hbGx5OgogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIF9BTlRJ
:::X0JPVFsnY29tYm8nXSA9IDAKICAgICAgICAgICAgICAgICAgICAgICAgbG9nKCfi
:::nJYgWW91VHViZSBzaWd1ZSBwaWRpZW5kbyB2ZXJpZmljYWNpw7NuOiAnCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICArIG1zZywgJ2Vycm9yJykKICAgICAgICAg
:::ICAgICAgICAgICAgICAgbG9nKCdTb2x1Y2nDs24gZmlhYmxlOiBlbiDCq1NpIFlv
:::dVR1YmUgYmxvcXVlYTrCuyAnCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAn
:::ZWxpZ2UgVXNhciBjb29raWVzIGRlIEZpcmVmb3ggKG8gdHUgJwogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgJ25hdmVnYWRvcikgeSByZWludGVudGE6IGNvbiB0
:::dSBzZXNpw7NuICcKICAgICAgICAgICAgICAgICAgICAgICAgICAgICdhYmllcnRh
:::IFlvdVR1YmUgbm8gdnVlbHZlIGEgcGVkaXIgJwogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgJ3ZlcmlmaWNhY2nDs24uJywgJ2dyaXMnKQogICAgICAgICAgICAg
:::ICAgICAgICAgICBsb2coJ1RhbWJpw6luIHN1ZWxlbiBmdW5jaW9uYXI6IGVzcGVy
:::YXIgdW5vcyAnCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAnbWludXRvcywg
:::cHVsc2FyIEN0cmwrVSAoYWN0dWFsaXphciB5dC1kbHApICcKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICdvIHByb2JhciBjb24gb3RyYSByZWQgKGVsIHdpZmkg
:::ZGUgY2FzYSkuJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICdncmlzJykK
:::ICAgICAgICAgICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgICAgICAg
:::ICBsb2coJ+KcliBObyBzZSBwdWRvIGRlc2NhcmdhcjogJyArIG1zZywgJ2Vycm9y
:::JykKICAgICAgICAgICAgICAgICAgICAgICAgbG9nKCdDb25zZWpvczogcmV2aXNh
:::IGxhIFVSTCB5IHR1IGNvbmV4acOzbjsgc2kgJwogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgJ1lvdVR1YmUgY2FtYmnDsyBhbGdvLCBwdWxzYSBDdHJsK1UgJwog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgJyhhY3R1YWxpemFyIHl0LWRscCkg
:::eSByZWludGVudGEuJywgJ2dyaXMnKQogICAgICAgICAgICAgICAgZWxzZToKICAg
:::ICAgICAgICAgICAgICAgICBsb2coZifinJYgRXJyb3IgaW5lc3BlcmFkbyAoe25v
:::bWJyZV9leGN9KToge2V9JywgJ2Vycm9yJykKICAgICAgICAgICAgICAgICAgICB0
:::YiA9IHRyYWNlYmFjay5mb3JtYXRfZXhjKGxpbWl0PTMpCiAgICAgICAgICAgICAg
:::ICAgICAgdHJ5OgogICAgICAgICAgICAgICAgICAgICAgICB3aXRoIG9wZW4oTE9H
:::X0VSUk9SRVMsICdhJywgZW5jb2Rpbmc9J3V0Zi04JykgYXMgZmg6CiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICBmaC53cml0ZSh0YiArICdcbicpCiAgICAgICAg
:::ICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgICAgICAg
:::ICAgICAgcGFzcwogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnZGVz
:::Y2FyZ2EnLCBGYWxzZSwKICAgICAgICAgICAgICAgICAgICAgICAgICAnTm8gc2Ug
:::cHVkbyBjb21wbGV0YXIgbGEgZGVzY2FyZ2EuIFJldmlzYSBlbCAnCiAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgJ3JlZ2lzdHJvIHBhcmEgbcOhcyBkZXRhbGxlcy4n
:::KSkKCiAgICAgICAgZGVmIF9oaWxvX2NvbXByb2JhcihzZWxmLCBjZmcpOgogICAg
:::ICAgICAgICBjb2xhID0gc2VsZi5jb2xhCgogICAgICAgICAgICBkZWYgbG9nKG0s
:::IHQ9J2luZm8nKToKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwg
:::dCkpCgogICAgICAgICAgICBjYXJwZXRhID0gUGF0aChvcy5wYXRoLmV4cGFuZHZh
:::cnMoCiAgICAgICAgICAgICAgICBzdHIoQUpVU1RFUy5nZXQoJ2Rlc3Rpbm8nLCBf
:::ZGVzdGlub19wb3JfZGVmZWN0bygpKSkpKQogICAgICAgICAgICB0cnk6CiAgICAg
:::ICAgICAgICAgICBpZiBub3QgY2FycGV0YS5pc19kaXIoKToKICAgICAgICAgICAg
:::ICAgICAgICBsb2coZidMYSBjYXJwZXRhIHRvZGF2w61hIG5vIGV4aXN0ZToge2Nh
:::cnBldGF9JywgJ2F2aXNvJykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgo
:::J2ZpbicsICdjb21wcm9iYWNpb24nLCBUcnVlLCAnJykpCiAgICAgICAgICAgICAg
:::ICAgICAgcmV0dXJuCiAgICAgICAgICAgICAgICBpZiBGRlBST0JFIGlzIE5vbmU6
:::CiAgICAgICAgICAgICAgICAgICAgbG9nKCdmZnByb2JlIG5vIGVzdMOhIGRpc3Bv
:::bmlibGUgKHZpZW5lIGNvbiBGRm1wZWcpLiAnCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICdFamVjdXRhIERlc2NhcmdhZG9yTXVzaWNhLmJhdCBwYXJhIGluc3RhbGFy
:::bG8uJywKICAgICAgICAgICAgICAgICAgICAgICAgJ2Vycm9yJykKICAgICAgICAg
:::ICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdjb21wcm9iYWNpb24nLCBUcnVl
:::LCAnJykpCiAgICAgICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgICAg
:::ICBleHRzID0gKCcubTRhJywgJy5tcDMnLCAnLmZsYWMnLCAnLndhdicsICcud21h
:::JywgJy5hdmknKQogICAgICAgICAgICAgICAgYXJjaGl2b3MgPSBbcCBmb3IgcCBp
:::biBzb3J0ZWQoY2FycGV0YS5yZ2xvYignKicpKQogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgaWYgcC5pc19maWxlKCkgYW5kIHAuc3VmZml4Lmxvd2VyKCkgaW4g
:::ZXh0cwogICAgICAgICAgICAgICAgICAgICAgICAgICAgYW5kICdfdG1wJyBub3Qg
:::aW4gcC5wYXJ0c10KICAgICAgICAgICAgICAgIGxvZyhmJ0NvbXByb2JhbmRvIHts
:::ZW4oYXJjaGl2b3MpfSBhcmNoaXZvKHMpIGVuICcKICAgICAgICAgICAgICAgICAg
:::ICBmJ3tjYXJwZXRhfSAuLi4nLCAndGl0dWxvJykKICAgICAgICAgICAgICAgIGlm
:::IG5vdCBhcmNoaXZvczoKICAgICAgICAgICAgICAgICAgICBsb2coJ05vIGhheSBh
:::cmNoaXZvcyBkZSBhdWRpbyBvIHZpZGVvIHRvZGF2w61hLicsICdncmlzJykKICAg
:::ICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdjb21wcm9iYWNpb24n
:::LCBUcnVlLCAnJykpCiAgICAgICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAg
:::ICAgICAgICB0b3RhbCA9IDAKICAgICAgICAgICAgICAgIGJhamFzID0gMAogICAg
:::ICAgICAgICAgICAgZm9yIHAgaW4gYXJjaGl2b3M6CiAgICAgICAgICAgICAgICAg
:::ICAgdHJ5OgogICAgICAgICAgICAgICAgICAgICAgICByID0gc3VicHJvY2Vzcy5y
:::dW4oCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBbc3RyKEZGUFJPQkUpLCAn
:::LXYnLCAnZXJyb3InLCAnLXNob3dfZW50cmllcycsCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgJ2Zvcm1hdD1iaXRfcmF0ZSxkdXJhdGlvbixzaXplJywgJy1v
:::ZicsICdqc29uJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICBzdHIocCld
:::LAogICAgICAgICAgICAgICAgICAgICAgICAgICAgc3Rkb3V0PXN1YnByb2Nlc3Mu
:::UElQRSwgc3RkZXJyPXN1YnByb2Nlc3MuUElQRSwKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgIHRleHQ9VHJ1ZSwgZW5jb2Rpbmc9J3V0Zi04JywgZXJyb3JzPSdy
:::ZXBsYWNlJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHRpbWVvdXQ9MzAp
:::CiAgICAgICAgICAgICAgICAgICAgICAgIGRhdG9zID0ganNvbi5sb2FkcyhyLnN0
:::ZG91dCBvciAne30nKS5nZXQoJ2Zvcm1hdCcsIHt9KQogICAgICAgICAgICAgICAg
:::ICAgICAgICBrYnBzID0gaW50KGZsb2F0KGRhdG9zLmdldCgnYml0X3JhdGUnKSBv
:::ciAwKSAvIDEwMDApCiAgICAgICAgICAgICAgICAgICAgICAgIGR1ciA9IGZsb2F0
:::KGRhdG9zLmdldCgnZHVyYXRpb24nKSBvciAwKQogICAgICAgICAgICAgICAgICAg
:::ICAgICB0YW0gPSBpbnQoZmxvYXQoZGF0b3MuZ2V0KCdzaXplJykgb3IgMCkpCiAg
:::ICAgICAgICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAg
:::ICAgICAgICAgICAgbG9nKGYnwrcge3AubmFtZVs6NjBdfSDigJQgbm8gc2UgcHVk
:::byBsZWVyJywgJ2F2aXNvJykKICAgICAgICAgICAgICAgICAgICAgICAgY29udGlu
:::dWUKICAgICAgICAgICAgICAgICAgICB0b3RhbCArPSB0YW0KICAgICAgICAgICAg
:::ICAgICAgICB0ZXh0bywgbml2ZWwgPSBjbGFzZV9jYWxpZGFkKHAuc3VmZml4Lmxv
:::d2VyKCksIGticHMpCiAgICAgICAgICAgICAgICAgICAgaWYgbml2ZWwgPT0gMjoK
:::ICAgICAgICAgICAgICAgICAgICAgICAgYmFqYXMgKz0gMQogICAgICAgICAgICAg
:::ICAgICAgIHRhZyA9ICgnb2snIGlmIG5pdmVsID09IDAKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgZWxzZSAoJ2F2aXNvJyBpZiBuaXZlbCA9PSAxIGVsc2UgJ2Vy
:::cm9yJykpCiAgICAgICAgICAgICAgICAgICAgbG9nKGYnwrcge3AubmFtZVs6NThd
:::fSDigJQge3RleHRvfSDCtyB7Zm10X3RpZW0oZHVyKX0gwrcgJwogICAgICAgICAg
:::ICAgICAgICAgICAgICBmJ3tmbXRfdGFtKHRhbSl9JywgdGFnKQogICAgICAgICAg
:::ICAgICAgbG9nKGYnUmVzdWx0YWRvOiB7bGVuKGFyY2hpdm9zKX0gYXJjaGl2byhz
:::KSDCtyAnCiAgICAgICAgICAgICAgICAgICAgZid7Zm10X3RhbSh0b3RhbCl9IGVu
:::IHRvdGFsIMK3IHtiYWphc30gY29uIGNhbGlkYWQgYmFqYScsCiAgICAgICAgICAg
:::ICAgICAgICAgJ3RpdHVsbycpCiAgICAgICAgICAgICAgICBpZiBiYWphczoKICAg
:::ICAgICAgICAgICAgICAgICBsb2coJ0NvbnNlam86IGxvcyBhcmNoaXZvcyBtYXJj
:::YWRvcyBlbiByb2pvIHNlIHB1ZWRlbiAnCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICd2b2x2ZXIgYSBkZXNjYXJnYXIgY29uIG3DoXMgYml0cmF0ZS4nLCAnZ3Jpcycp
:::CiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZToKICAgICAgICAgICAg
:::ICAgIGxvZyhmJ0Vycm9yIGFsIGNvbXByb2JhciBsYSBjYXJwZXRhOiB7ZX0nLCAn
:::ZXJyb3InKQogICAgICAgICAgICBmaW5hbGx5OgogICAgICAgICAgICAgICAgY29s
:::YS5wdXQoKCdmaW4nLCAnY29tcHJvYmFjaW9uJywgVHJ1ZSwgJycpKQoKICAgICAg
:::ICBkZWYgX2hpbG9fYWN0dWFsaXphcihzZWxmLCBjZmcpOgogICAgICAgICAgICBj
:::b2xhID0gc2VsZi5jb2xhCgogICAgICAgICAgICBkZWYgbG9nKG0sIHQ9J2luZm8n
:::KToKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAg
:::ICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICBsb2coJ0FjdHVhbGl6YW5kbyB5
:::dC1kbHAgeSBtdXRhZ2VuLi4uJywgJ2dyaXMnKQogICAgICAgICAgICAgICAgcCA9
:::IHN1YnByb2Nlc3MucnVuKAogICAgICAgICAgICAgICAgICAgIFtzeXMuZXhlY3V0
:::YWJsZSwgJy1tJywgJ3BpcCcsICdpbnN0YWxsJywgJy0tdXBncmFkZScsCiAgICAg
:::ICAgICAgICAgICAgICAgICctLW5vLXdhcm4tc2NyaXB0LWxvY2F0aW9uJywgJ3l0
:::LWRscCcsICdtdXRhZ2VuJ10sCiAgICAgICAgICAgICAgICAgICAgc3Rkb3V0PXN1
:::YnByb2Nlc3MuUElQRSwgc3RkZXJyPXN1YnByb2Nlc3MuU1RET1VULAogICAgICAg
:::ICAgICAgICAgICAgIHRleHQ9VHJ1ZSwgZW5jb2Rpbmc9J3V0Zi04JywgZXJyb3Jz
:::PSdyZXBsYWNlJywgdGltZW91dD02MDApCiAgICAgICAgICAgICAgICBmb3IgbG4g
:::aW4gKHAuc3Rkb3V0IG9yICcnKS5zdHJpcCgpLnNwbGl0bGluZXMoKVstNjpdOgog
:::ICAgICAgICAgICAgICAgICAgIGxvZygnICAgJyArIGxuWzoxNjBdLCAnZ3Jpcycp
:::CiAgICAgICAgICAgICAgICBpZiBwLnJldHVybmNvZGUgPT0gMDoKICAgICAgICAg
:::ICAgICAgICAgICBsb2coJ3l0LWRscCBhY3R1YWxpemFkby4gUmVpbmljaWEgbGEg
:::YXBsaWNhY2nDs24gcGFyYSAnCiAgICAgICAgICAgICAgICAgICAgICAgICd1c2Fy
:::IGxhIHZlcnNpw7NuIG51ZXZhLicsICdvaycpCiAgICAgICAgICAgICAgICBlbHNl
:::OgogICAgICAgICAgICAgICAgICAgIGxvZygnTGEgYWN0dWFsaXphY2nDs24gZmFs
:::bMOzICjCv3NpbiBpbnRlcm5ldD8pLicsICdlcnJvcicpCiAgICAgICAgICAgIGV4
:::Y2VwdCBFeGNlcHRpb24gYXMgZToKICAgICAgICAgICAgICAgIGxvZyhmJ05vIHNl
:::IHB1ZG8gZWplY3V0YXIgcGlwOiB7ZX0nLCAnZXJyb3InKQogICAgICAgICAgICBm
:::aW5hbGx5OgogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnYWN0dWFs
:::aXphY2lvbicsIFRydWUsICcnKSkKCiAgICAgICAgZGVmIF9tc2dfZXJyb3Ioc2Vs
:::ZiwgZSk6CiAgICAgICAgICAgIGxpbmVhcyA9IFtsIGZvciBsIGluIHN0cihlKS5z
:::dHJpcCgpLnNwbGl0bGluZXMoKSBpZiBsLnN0cmlwKCldCiAgICAgICAgICAgIHJl
:::dHVybiAobGluZWFzWzBdWzoyNTBdIGlmIGxpbmVhcwogICAgICAgICAgICAgICAg
:::ICAgIGVsc2UgZid7dHlwZShlKS5fX25hbWVfX306IHNpbiBkZXRhbGxlcycpCgog
:::ICAgICAgICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tIGFycmFucXVlCiAgICAgICAgZGVmIF9hcnJhbnF1ZShzZWxmKToK
:::ICAgICAgICAgICAgc2VsZi5fbG9nKGYnTXVzaWtBTEFOIHZ7QVBQX1Z9JywgJ3Rp
:::dHVsbycpCiAgICAgICAgICAgIHNlbGYuX2xvZygnQ3RybCtVOiBhY3R1YWxpemFy
:::IHl0LWRscCDCtyBDdHJsK0w6IGxpbXBpYXIgcmVnaXN0cm8nLAogICAgICAgICAg
:::ICAgICAgICAgICAgJ2dyaXMnKQogICAgICAgICAgICB0aHJlYWRpbmcuVGhyZWFk
:::KHRhcmdldD1zZWxmLl9oaWxvX3ZlcnNpb24sIGRhZW1vbj1UcnVlKS5zdGFydCgp
:::CgogICAgICAgIGRlZiBfaGlsb192ZXJzaW9uKHNlbGYpOgogICAgICAgICAgICBj
:::b2xhID0gc2VsZi5jb2xhCgogICAgICAgICAgICBkZWYgbG9nKG0sIHQ9J2luZm8n
:::KToKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnbG9nJywgbSwgdCkpCgogICAg
:::ICAgICAgICBpZiBZVF9ETFAgaXMgTm9uZToKICAgICAgICAgICAgICAgIGxvZygn
:::eXQtZGxwIG5vIGVzdMOhIGluc3RhbGFkby4gRWplY3V0YSAnCiAgICAgICAgICAg
:::ICAgICAgICAgJ0Rlc2NhcmdhZG9yTXVzaWNhLmJhdCBwYXJhIGluc3RhbGFybG8u
:::JywgJ2Vycm9yJykKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ3Zl
:::cnNpb24nLCBUcnVlLCAnJykpCiAgICAgICAgICAgICAgICByZXR1cm4KICAgICAg
:::ICAgICAgdHJ5OgogICAgICAgICAgICAgICAgaW5zdGFsYWRhID0gWVRfRExQLnZl
:::cnNpb24uX192ZXJzaW9uX18KICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoK
:::ICAgICAgICAgICAgICAgIGluc3RhbGFkYSA9ICc/JwogICAgICAgICAgICB1bHRp
:::bWEgPSBOb25lCiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIHdpdGgg
:::dXJsb3BlbignaHR0cHM6Ly9weXBpLm9yZy9weXBpL3l0LWRscC9qc29uJywgdGlt
:::ZW91dD0xMikgYXMgcjoKICAgICAgICAgICAgICAgICAgICB1bHRpbWEgPSBqc29u
:::LmxvYWRzKHIucmVhZCgpLmRlY29kZSgndXRmLTgnKSlbJ2luZm8nXVsndmVyc2lv
:::biddCiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgICAg
:::ICB1bHRpbWEgPSBOb25lCiAgICAgICAgICAgIGlmIHVsdGltYSBpcyBOb25lOgog
:::ICAgICAgICAgICAgICAgbG9nKGYneXQtZGxwOiB2ZXJzacOzbiB7aW5zdGFsYWRh
:::fSAnCiAgICAgICAgICAgICAgICAgICAgJyhubyBzZSBwdWRvIGNvbXByb2JhciBz
:::aSBoYXkgbm92ZWRhZGVzKS4nLCAnZ3JpcycpCiAgICAgICAgICAgIGVsaWYgc3Ry
:::KHVsdGltYSkgPT0gc3RyKGluc3RhbGFkYSk6CiAgICAgICAgICAgICAgICBsb2co
:::Zid5dC1kbHA6IGVuIGxhIHVsdGltYSB2ZXJzaW9uICh7aW5zdGFsYWRhfSkuJywg
:::J2luZm8nKQogICAgICAgICAgICBlbHNlOgogICAgICAgICAgICAgICAgbG9nKGYn
:::eXQtZGxwOiBoYXkgdmVyc2lvbiBudWV2YSAoe3VsdGltYX0pOyBpbnN0YWxhZGE6
:::ICcKICAgICAgICAgICAgICAgICAgICBmJ3tpbnN0YWxhZGF9LiBQdWxzYSBDdHJs
:::K1UgcGFyYSBhY3R1YWxpemFyLicsICdhdmlzbycpCiAgICAgICAgICAgIGlmIEZG
:::TVBFRyBpcyBOb25lOgogICAgICAgICAgICAgICAgbG9nKCdGRm1wZWc6IE5PIEVO
:::Q09OVFJBRE8g4oCUIGVqZWN1dGEgRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0ICcKICAg
:::ICAgICAgICAgICAgICAgICAncGFyYSBpbnN0YWxhcmxvLicsICdlcnJvcicpCiAg
:::ICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICBsb2coZidGRm1wZWc6IE9L
:::ICh7RkZNUEVHfSknLCAnZ3JpcycpCiAgICAgICAgICAgIGxvZygnQ2FycGV0YSBk
:::ZSBndWFyZGFkbzogJyArIHN0cihBSlVTVEVTLmdldCgnZGVzdGlubycpKSwgJ2dy
:::aXMnKQogICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICd2ZXJzaW9uJywgVHJ1
:::ZSwgJycpKQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBtYWluCmRlZiBtYWluKCk6CiAg
:::ICBfcmVjb25maWd1cmFyX3NhbGlkYSgpCiAgICBpZiBub3QgVEtfT0s6CiAgICAg
:::ICAgcHJpbnQoJ0VzdGEgYXBsaWNhY2nDs24gbmVjZXNpdGEgVGtpbnRlciAoaW50
:::ZXJmYXogZ3LDoWZpY2EpLicpCiAgICAgICAgcHJpbnQoJ0VsIFB5dGhvbiBhY3R1
:::YWwgbm8gbG8gaW5jbHV5ZS4nKQogICAgICAgIHByaW50KCdWdWVsdmUgYSBlamVj
:::dXRhciBEZXNjYXJnYWRvck11c2ljYS5iYXQgcGFyYSBpbnN0YWxhciBlbCAnCiAg
:::ICAgICAgICAgICAgJ1B5dGhvbiBhZGVjdWFkby4nKQogICAgICAgIHJldHVybiAx
:::CiAgICBjb21wcm9iYXJfZW50b3JubygpCiAgICBhcHAgPSBBcHAoKQogICAgYXBw
:::Lm1haW5sb29wKCkKICAgIHJldHVybiAwCgoKaWYgX19uYW1lX18gPT0gJ19fbWFp
:::bl9fJzoKICAgIHRyeToKICAgICAgICBzeXMuZXhpdChtYWluKCkpCiAgICBleGNl
:::cHQgU3lzdGVtRXhpdDoKICAgICAgICByYWlzZQogICAgZXhjZXB0IEJhc2VFeGNl
:::cHRpb246CiAgICAgICAgdHJ5OgogICAgICAgICAgICB3aXRoIG9wZW4oTE9HX0VS
:::Uk9SRVMsICdhJywgZW5jb2Rpbmc9J3V0Zi04JykgYXMgZmg6CiAgICAgICAgICAg
:::ICAgICBmaC53cml0ZSh0cmFjZWJhY2suZm9ybWF0X2V4YygpICsgJ1xuJykKICAg
:::ICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICBwYXNzCiAgICAgICAg
:::cmFpc2UK
