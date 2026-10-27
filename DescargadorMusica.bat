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
rem  Parametros opcionales:
rem     --reinstalar   vuelve a extraer descargador.py
rem     --sin-buscar   se salta la comprobacion de actualizaciones
rem  NOTA: este archivo debe ser ASCII puro y CRLF (no tocar a mano).
rem ================================================================
setlocal EnableExtensions
title MusikALAN v2.10
rem  Marca de version: la busca este mismo archivo con findstr para
rem  compararse con la ultima release publicada en GitHub.
rem  NO cambiar el formato de la linea siguiente.
rem VERSION-BUSCABLE: 2.10
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
echo    %C_TIT%MusikALAN v2.10%C_FIN% - preparando el entorno
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
title MusikALAN v2.10 - YouTube a AAC/MP3/FLAC/WAV/WMA/AVI
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
:::UF9WID0gJzIuMTAnCkFQUF9ESVIgPSBQYXRoKF9fZmlsZV9fKS5yZXNvbHZlKCku
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
:::TyA9IFJlZ2lzdHJvKCkKCk5PTUJSRVNfUFAgPSB7CiAgICAnRkZtcGVnRXh0cmFj
:::dEF1ZGlvJzogJ0NvbnZpcnRpZW5kbyBlbCBhdWRpbyBjb24gRkZtcGVnJywKICAg
:::ICdGRm1wZWdUaHVtYm5haWxzQ29udmVydG9yJzogJ0NvbnZpcnRpZW5kbyBsYSBj
:::YXLDoXR1bGEgYSBKUEcnLAogICAgJ0ZGbXBlZ01ldGFkYXRhJzogJ0VzY3JpYmll
:::bmRvIGV0aXF1ZXRhcyAodMOtdHVsby9hcnRpc3RhKScsCiAgICAnRW1iZWRUaHVt
:::Ym5haWwnOiAnSW5jcnVzdGFuZG8gbGEgY2Fyw6F0dWxhJywKICAgICdNb3ZlRmls
:::ZXMnOiAnT3JnYW5pemFuZG8gYXJjaGl2b3MnLAogICAgJ0ZGbXBlZ01lcmdlcic6
:::ICdVbmllbmRvIHBpc3RhcyBkZSB2aWRlbyB5IGF1ZGlvJywKICAgICdGRm1wZWdW
:::aWRlb0NvbnZlcnRvcic6ICdDb252aXJ0aWVuZG8gZWwgdmlkZW8nLAp9CgojIC0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0gZm9ybWF0b3MKRk9STUFUT1MgPSB7CiAgICAnQUFDJzog
:::ZGljdCh0ZXh0bz0nQUFDICgubTRhKScsIGV4dD0nbTRhJywKICAgICAgICAgICAg
:::ICAgIGNhbGlkYWRlcz1bJzk2aycsICcxMjhrJ10sIGRlZmVjdG89JzEyOGsnKSwK
:::ICAgICdNUDMnOiBkaWN0KHRleHRvPSdNUDMgKC5tcDMpJywgZXh0PSdtcDMnLAog
:::ICAgICAgICAgICAgICAgY2FsaWRhZGVzPVsnOTZrJywgJzEyOGsnLCAnMTkyaycs
:::ICcyNTZrJywgJzMyMGsnXSwKICAgICAgICAgICAgICAgIGRlZmVjdG89JzMyMGsn
:::KSwKICAgICdGTEFDJzogZGljdCh0ZXh0bz0nRkxBQyAoLmZsYWMpJywgZXh0PSdm
:::bGFjJywKICAgICAgICAgICAgICAgICBjYWxpZGFkZXM9WydzaW4gcGVyZGlkYSdd
:::LCBkZWZlY3RvPSdzaW4gcGVyZGlkYScpLAogICAgJ1dBVic6IGRpY3QodGV4dG89
:::J1dBViAoLndhdiknLCBleHQ9J3dhdicsCiAgICAgICAgICAgICAgICBjYWxpZGFk
:::ZXM9WydzaW4gcGVyZGlkYSddLCBkZWZlY3RvPSdzaW4gcGVyZGlkYScpLAogICAg
:::J1dNQSc6IGRpY3QodGV4dG89J1dNQSAoLndtYSknLCBleHQ9J3dtYScsCiAgICAg
:::ICAgICAgICAgICBjYWxpZGFkZXM9Wyc5NmsnLCAnMTI4ayddLCBkZWZlY3RvPScx
:::MjhrJyksCiAgICAnQVZJJzogZGljdCh0ZXh0bz0nQVZJIC0gc2hlaWp1IDEuOCIg
:::KDEyOHgxNjApJywgZXh0PSdhdmknLAogICAgICAgICAgICAgICAgY2FsaWRhZGVz
:::PVsnMTI4eDE2MCDCtyAxNiBmcHMnXSwgZGVmZWN0bz0nMTI4eDE2MCDCtyAxNiBm
:::cHMnKSwKfQoKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSBwcm9ncmVzbwpkZWYgaG9va3Nf
:::Z3VpKGNvbGEpOgogICAgIiIiQ3JlYSBsb3MgaG9va3MgZGUgeXQtZGxwIHF1ZSBw
:::dWJsaWNhbiBldmVudG9zIGVuIGxhIGNvbGEgZGUgbGEgR1VJLiIiIgogICAgZXN0
:::YWRvID0geyd0aXR1bG8nOiBGYWxzZSwgJ3BwX3VsdCc6IE5vbmV9CgogICAgZGVm
:::IGxvZyhtLCB0PSdpbmZvJyk6CiAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0
:::KSkKCiAgICBkZWYgcHJvZ3Jlc28oZCk6CiAgICAgICAgaWYgZFsnc3RhdHVzJ10g
:::PT0gJ2Rvd25sb2FkaW5nJzoKICAgICAgICAgICAgaWYgbm90IGVzdGFkb1sndGl0
:::dWxvJ106CiAgICAgICAgICAgICAgICBpbmZvID0gZC5nZXQoJ2luZm9fZGljdCcp
:::IG9yIHt9CiAgICAgICAgICAgICAgICB0ID0gaW5mby5nZXQoJ3RpdGxlJykgb3Ig
:::UGF0aChkLmdldCgnZmlsZW5hbWUnKSBvciAnJykuc3RlbQogICAgICAgICAgICAg
:::ICAgaWYgdDoKICAgICAgICAgICAgICAgICAgICBsb2coJ+KZqiAnICsgc3RyKHQp
:::Wzo5MF0sICd0aXR1bG8nKQogICAgICAgICAgICAgICAgICAgIGVzdGFkb1sndGl0
:::dWxvJ10gPSBUcnVlCiAgICAgICAgICAgIHRvdGFsID0gZC5nZXQoJ3RvdGFsX2J5
:::dGVzJykgb3IgZC5nZXQoJ3RvdGFsX2J5dGVzX2VzdGltYXRlJykgb3IgMAogICAg
:::ICAgICAgICBkb25lID0gZC5nZXQoJ2Rvd25sb2FkZWRfYnl0ZXMnLCAwKQogICAg
:::ICAgICAgICB2ZWwgPSBkLmdldCgnc3BlZWQnKQogICAgICAgICAgICBldGEgPSBk
:::LmdldCgnZXRhJykKICAgICAgICAgICAgaWYgdG90YWw6CiAgICAgICAgICAgICAg
:::ICBwY3QgPSBkb25lIC8gdG90YWwgKiAxMDAKICAgICAgICAgICAgICAgIHRleHRv
:::ID0gZid7cGN0OjUuMWZ9JSDCtyB7Zm10X3RhbShkb25lKX0gLyB7Zm10X3RhbSh0
:::b3RhbCl9JwogICAgICAgICAgICAgICAgaWYgdmVsOgogICAgICAgICAgICAgICAg
:::ICAgIHRleHRvICs9IGYnIMK3IHtmbXRfdGFtKHZlbCl9L3MnCiAgICAgICAgICAg
:::ICAgICBpZiBldGEgaXMgbm90IE5vbmU6CiAgICAgICAgICAgICAgICAgICAgdGV4
:::dG8gKz0gZicgwrcgcXVlZGFuIHtmbXRfdGllbShldGEpfScKICAgICAgICAgICAg
:::ICAgIGNvbGEucHV0KCgncHJvZycsIHBjdCwgdGV4dG8pKQogICAgICAgICAgICBl
:::bHNlOgogICAgICAgICAgICAgICAgdiA9IGYne2ZtdF90YW0odmVsKX0vcycgaWYg
:::dmVsIGVsc2UgJycKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgncHJvZycsIE5v
:::bmUsIGYne2ZtdF90YW0oZG9uZSl9IMK3IHt2fScpKQogICAgICAgIGVsaWYgZFsn
:::c3RhdHVzJ10gPT0gJ2ZpbmlzaGVkJzoKICAgICAgICAgICAgZXN0YWRvWydwcF91
:::bHQnXSA9IE5vbmUKICAgICAgICAgICAgY29sYS5wdXQoKCdsb2cnLCAnRGVzY2Fy
:::Z2EgcmVjaWJpZGEuIFByb2Nlc2FuZG8uLi4nLCAnZ3JpcycpKQogICAgICAgICAg
:::ICBjb2xhLnB1dCgoJ3Byb2cnLCAwLCAnUHJvY2VzYW5kby4uLicpKQoKICAgIGRl
:::ZiBwb3N0cHJvY2VzbyhkKToKICAgICAgICBpZiBkWydzdGF0dXMnXSA9PSAnc3Rh
:::cnRlZCc6CiAgICAgICAgICAgIG5vbSA9IChkLmdldCgncG9zdHByb2Nlc3Nvcl9u
:::YW1lJykKICAgICAgICAgICAgICAgICAgIG9yIGQuZ2V0KCdwb3N0cHJvY2Vzc29y
:::Jykgb3IgJ1Bvc3Rwcm9jZXNvJykKICAgICAgICAgICAgaWYgbm9tID09IGVzdGFk
:::b1sncHBfdWx0J106CiAgICAgICAgICAgICAgICByZXR1cm4gICMgeXQtZGxwIGEg
:::dmVjZXMgYW51bmNpYSBlbCBtaXNtbyBwYXNvIGRvcyB2ZWNlcwogICAgICAgICAg
:::ICBlc3RhZG9bJ3BwX3VsdCddID0gbm9tCiAgICAgICAgICAgIHRleHRvID0gTk9N
:::QlJFU19QUC5nZXQobm9tLCBub20pICsgJy4uLicKICAgICAgICAgICAgY29sYS5w
:::dXQoKCdsb2cnLCAn4oaSICcgKyB0ZXh0bywgJ2dyaXMnKSkKICAgICAgICAgICAg
:::Y29sYS5wdXQoKCdwcm9nJywgTm9uZSwgdGV4dG8pKQoKICAgIHJldHVybiBwcm9n
:::cmVzbywgcG9zdHByb2Nlc28KCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0gYW50aS1ibG9xdWVvIGRlIFlvdVR1YmUgKHYyLjkp
:::CiMgQ3VhbmRvIFlvdVR1YmUgZGVzY29uZsOtYSBkZSB1bmEgcmVkICh3aWZpIGNv
:::bXBhcnRpZG8sIGRhdG9zIG3Ds3ZpbGVzLCBWUE4KIyBvIG11Y2hhcyBkZXNjYXJn
:::YXMgc2VndWlkYXMpIHJlc3BvbmRlIGEgbG9zIGNsaWVudGVzIHdlYiBjb24gIlNp
:::Z24gaW4gdG8KIyBjb25maXJtIHlvdSdyZSBub3QgYSBib3QiIG8gSFRUUCA0Mjku
:::IERlZmVuc2EgZW4gY2FwYXM6CiMgICAxKSBQb3IgZGVmZWN0byBsb3MgZm9ybWF0
:::b3Mgc2UgcGlkZW4gY29uIGxvcyBjbGllbnRlcyBkZSBsYXMgQVBQUwojICAgICAg
:::bcOzdmlsZXMgKGFuZHJvaWQvaW9zL213ZWIpLCBxdWUgZW4gbGEgbWF5b3LDrWEg
:::ZGUgbGFzIHJlZGVzIG5vIHBhc2FuCiMgICAgICBwb3IgZXNlIGNoZXF1ZW8uCiMg
:::ICAyKSBTaSBhdW4gYXPDrSBZb3VUdWJlIGluc2lzdGUsIGxhIGRlc2NhcmdhIHNl
:::IHJlaW50ZW50YSBVTkEgdmV6IHNvbGEKIyAgICAgIGNvbiBlbCBjb21ibyAyIChh
:::bmRyb2lkX3ZyL2FuZHJvaWQvaW9zLCBzaW4gY2xpZW50ZXMgd2ViKSB0cmFzIHVu
:::YQojICAgICAgcGVxdWXDsWEgcGF1c2EgcGFyYSBkZWphciBlbmZyaWFyIGVsIDQy
:::OS4KIyAgIDMpIMOabHRpbWEgbMOtbmVhOiBlbCBkZXNwbGVnYWJsZSAiU2kgWW91
:::VHViZSBibG9xdWVhOiIgcGVybWl0ZSB1c2FyIGxhcwojICAgICAgQ09PS0lFUyBk
:::ZWwgbmF2ZWdhZG9yIGRlbCB1c3VhcmlvIChjb24gc2VzacOzbiBhYmllcnRhIFlv
:::dVR1YmUgbm8KIyAgICAgIHBpZGUgdmVyaWZpY2FjacOzbikuIEVzIGxhIHbDrWEg
:::b2ZpY2lhbCByZWNvbWVuZGFkYSBwb3IgeXQtZGxwLgpDT01CT1NfQU5USV9CT1Qg
:::PSAoCiAgICAoJ2FuZHJvaWQnLCAnaW9zJywgJ213ZWInKSwKICAgICgnYW5kcm9p
:::ZF92cicsICdhbmRyb2lkJywgJ2lvcycpLAopCk5BVkVHQURPUkVTX0NPT0tJRVMg
:::PSAoJ2ZpcmVmb3gnLCAnY2hyb21lJywgJ2VkZ2UnLCAnYnJhdmUnLCAnb3BlcmEn
:::LAogICAgICAgICAgICAgICAgICAgICAgICd2aXZhbGRpJykKX0FOVElfQk9UID0g
:::eydjb21ibyc6IDB9ICAgICAgIyBjb21ibyBlbiBjdXJzbyAoZGljdCBtdXRhYmxl
:::ID0gZ2xvYmFsKQoKCmRlZiBfYW50aV9ib3Qobyk6CiAgICAiIiJJbnllY3RhIGVu
:::IGxhcyBvcGNpb25lcyBkZSB5dC1kbHAgbGEgdsOtYSBhbnRpLWJsb3F1ZW8gZW4g
:::Y3Vyc28uIiIiCiAgICBvWydleHRyYWN0b3JfYXJncyddID0geyd5b3V0dWJlJzog
:::eydwbGF5ZXJfY2xpZW50JzoKICAgICAgICAgICAgICAgICAgICAgICAgICBsaXN0
:::KENPTUJPU19BTlRJX0JPVFtfQU5USV9CT1RbJ2NvbWJvJ11dKX19CiAgICBvWydm
:::b3JjZWlwdjQnXSA9IFRydWUKICAgIG5hdmVnYWRvciA9IHN0cihBSlVTVEVTLmdl
:::dCgnY29va2llcycsICcnKSBvciAnJykuc3RyaXAoKS5sb3dlcigpCiAgICBpZiBu
:::YXZlZ2Fkb3IgaW4gTkFWRUdBRE9SRVNfQ09PS0lFUzoKICAgICAgICBvWydjb29r
:::aWVzZnJvbWJyb3dzZXInXSA9IChuYXZlZ2Fkb3IsKQogICAgcmV0dXJuIG8KCgpk
:::ZWYgX2VzX2Jsb3F1ZW9fYm90KHRleHRvKToKICAgICIiIlRydWUgc2kgZWwgZXJy
:::b3IgZGUgeXQtZGxwIGVzIGVsIGNoZXF1ZW8gYW50aS1ib3QgbyB1biA0MjkuIiIi
:::CiAgICB0ID0gKHRleHRvIG9yICcnKS5sb3dlcigpCiAgICByZXR1cm4gKCdub3Qg
:::YSBib3QnIGluIHQgb3IgJ3NpZ24gaW4gdG8gY29uZmlybScgaW4gdAogICAgICAg
:::ICAgICBvciAndG9vIG1hbnkgcmVxdWVzdHMnIGluIHQgb3IgJ2h0dHAgZXJyb3Ig
:::NDI5JyBpbiB0CiAgICAgICAgICAgIG9yICcgZXJyb3IgNDI5JyBpbiB0KQoKCiMg
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLSBvcGNpb25lcwpkZWYgb3B0c19iYXNlKGNhcnBldGEs
:::IGNvbGEpOgogICAgcHJvZ3Jlc28sIHBvc3Rwcm9jZXNvID0gaG9va3NfZ3VpKGNv
:::bGEpCiAgICBvID0gewogICAgICAgICdvdXR0bXBsJzogc3RyKGNhcnBldGEgLyAn
:::JSh0aXRsZSlzLiUoZXh0KXMnKSwKICAgICAgICAncXVpZXQnOiBUcnVlLAogICAg
:::ICAgICdub193YXJuaW5ncyc6IFRydWUsCiAgICAgICAgJ25vcHJvZ3Jlc3MnOiBU
:::cnVlLAogICAgICAgICdub3BsYXlsaXN0JzogVHJ1ZSwKICAgICAgICAnaWdub3Jl
:::ZXJyb3JzJzogRmFsc2UsCiAgICAgICAgJ3JldHJpZXMnOiAxMCwKICAgICAgICAn
:::ZnJhZ21lbnRfcmV0cmllcyc6IDEwLAogICAgICAgICdzb2NrZXRfdGltZW91dCc6
:::IDMwLAogICAgICAgICdjb25jdXJyZW50X2ZyYWdtZW50X2Rvd25sb2Fkcyc6IDQs
:::CiAgICAgICAgJ3dpbmRvd3NmaWxlbmFtZXMnOiBUcnVlLAogICAgICAgICdvdmVy
:::d3JpdGVzJzogRmFsc2UsCiAgICAgICAgJ2xvZ2dlcic6IFJFR0lTVFJPLAogICAg
:::ICAgICdwcm9ncmVzc19ob29rcyc6IFtwcm9ncmVzb10sCiAgICAgICAgJ3Bvc3Rw
:::cm9jZXNzb3JfaG9va3MnOiBbcG9zdHByb2Nlc29dLAogICAgfQogICAgaWYgRkZN
:::UEVHOgogICAgICAgIG9bJ2ZmbXBlZ19sb2NhdGlvbiddID0gc3RyKEZGTVBFRy5w
:::YXJlbnQpCiAgICBfYW50aV9ib3QobykKICAgIHJldHVybiBvCgoKZGVmIGNvbnZl
:::cnRpcl9mZm1wZWcoY21kLCBldGlxdWV0YSwgY29sYSk6CiAgICAiIiJFamVjdXRh
:::IEZGbXBlZyAobGlzdGEgZGUgYXJndW1lbnRvcywgc2luIHNoZWxsKSBjb24gbWFy
:::cXVlZS4iIiIKICAgIGNvbGEucHV0KCgncHJvZycsIE5vbmUsIGV0aXF1ZXRhKSkK
:::CiAgICBkZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAgICBjb2xhLnB1dCgoJ2xv
:::ZycsIG0sIHQpKQoKICAgIHRyeToKICAgICAgICBwID0gc3VicHJvY2Vzcy5ydW4o
:::Y21kLCBzdGRvdXQ9c3VicHJvY2Vzcy5QSVBFLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICBzdGRlcnI9c3VicHJvY2Vzcy5QSVBFLCB0ZXh0PVRydWUsCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgIGVuY29kaW5nPSd1dGYtOCcsIGVycm9ycz0n
:::cmVwbGFjZScpCiAgICBleGNlcHQgRmlsZU5vdEZvdW5kRXJyb3I6CiAgICAgICAg
:::cCA9IE5vbmUKICAgIGlmIHAgaXMgTm9uZSBvciBwLnJldHVybmNvZGUgIT0gMDoK
:::ICAgICAgICBsb2coJ+KcliBGRm1wZWcgZGV2b2x2acOzIHVuIGVycm9yOicsICdl
:::cnJvcicpCiAgICAgICAgaWYgcCBpcyBub3QgTm9uZToKICAgICAgICAgICAgZm9y
:::IGxuIGluIChwLnN0ZGVyciBvciAnJykuc3RyaXAoKS5zcGxpdGxpbmVzKClbLTQ6
:::XToKICAgICAgICAgICAgICAgIGxvZygnICAgJyArIGxuWzoxODBdLCAnZ3Jpcycp
:::CiAgICAgICAgY29sYS5wdXQoKCdwcm9nJywgMCwgJycpKQogICAgICAgIHJldHVy
:::biBGYWxzZQogICAgcmV0dXJuIFRydWUKCgpkZWYgYXJjaGl2b19maW5hbChpbmZv
:::LCBjYXJwZXRhLCBleHQpOgogICAgIiIiTG9jYWxpemEgZWwgYXJjaGl2byByZXN1
:::bHRhbnRlICh5dC1kbHAgbG8gcmVwb3J0YTsgZmFsbGJhY2s6IG3DoXMgbnVldm8p
:::LiIiIgogICAgdHJ5OgogICAgICAgIGZvciBkIGluIChpbmZvLmdldCgncmVxdWVz
:::dGVkX2Rvd25sb2FkcycpIG9yIFtdKToKICAgICAgICAgICAgZiA9IGQuZ2V0KCdm
:::aWxlcGF0aCcpCiAgICAgICAgICAgIGlmIGY6CiAgICAgICAgICAgICAgICByZXR1
:::cm4gUGF0aChmKQogICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICBwYXNzCiAg
:::ICBjYW5kID0gc29ydGVkKGNhcnBldGEuZ2xvYignKi4nICsgZXh0KSwKICAgICAg
:::ICAgICAgICAgICAga2V5PWxhbWJkYSBwOiBwLnN0YXQoKS5zdF9tdGltZSwgcmV2
:::ZXJzZT1UcnVlKQogICAgcmV0dXJuIGNhbmRbMF0gaWYgY2FuZCBlbHNlIE5vbmUK
:::CgpkZWYgbGltcGlhcl9taW5pYXR1cmFzKGNhcnBldGEsIGFyY2hpdm8pOgogICAg
:::IiIiQm9ycmEgbWluaWF0dXJhcyBzdWVsdGFzIHF1ZSBFbWJlZFRodW1ibmFpbCBk
:::ZWphcmEgc2luIGluY3J1c3Rhci4iIiIKICAgIGZvciBleHQgaW4gKCcud2VicCcs
:::ICcuanBnJywgJy5qcGVnJywgJy5wbmcnKToKICAgICAgICB0ID0gYXJjaGl2by53
:::aXRoX3N1ZmZpeChleHQpCiAgICAgICAgaWYgdC5leGlzdHMoKToKICAgICAgICAg
:::ICAgdHJ5OgogICAgICAgICAgICAgICAgdC51bmxpbmsoKQogICAgICAgICAgICBl
:::eGNlcHQgT1NFcnJvcjoKICAgICAgICAgICAgICAgIHBhc3MKCgpkZWYgX21pbmlh
:::dHVyYV9ieXRlcyhjYXJwZXRhLCBhcmNoaXZvKToKICAgICIiIkxlZSBsb3MgYnl0
:::ZXMgZGUgbGEgbWluaWF0dXJhIHF1ZSB5dC1kbHAgZGVqbyBqdW50byBhbCBhcmNo
:::aXZvIGZpbmFsLiIiIgogICAgaWYgbm90IGFyY2hpdm86CiAgICAgICAgcmV0dXJu
:::IE5vbmUKICAgIGZvciBleHQgaW4gKCcuanBnJywgJy5qcGVnJywgJy53ZWJwJywg
:::Jy5wbmcnKToKICAgICAgICB0ID0gYXJjaGl2by53aXRoX3N1ZmZpeChleHQpCiAg
:::ICAgICAgaWYgdC5leGlzdHMoKToKICAgICAgICAgICAgdHJ5OgogICAgICAgICAg
:::ICAgICAgcmV0dXJuIHQucmVhZF9ieXRlcygpCiAgICAgICAgICAgIGV4Y2VwdCBP
:::U0Vycm9yOgogICAgICAgICAgICAgICAgcGFzcwogICAgcmV0dXJuIE5vbmUKCgpk
:::ZWYgX2VzX2pwZyhkYXRvcyk6CiAgICByZXR1cm4gYm9vbChkYXRvcykgYW5kIGRh
:::dG9zWzozXSA9PSBiJ1x4ZmZceGQ4XHhmZicKCgpkZWYgX2FfanBnKGRhdG9zKToK
:::ICAgICIiIkNvbnZpZXJ0ZSBsb3MgYnl0ZXMgZGUgdW5hIGltYWdlbiAod2VicC9w
:::bmcvLi4uKSBhIEpQRUcgY29uIEZGbXBlZy4KCiAgICBMb3MgcmVwcm9kdWN0b3Jl
:::cyBiYXJhdG9zICh0aXBvIHNoZWlqdSkgc3VlbGVuIGxlZXIgc29sbyBKUEVHOiBs
:::YQogICAgbWluaWF0dXJhIGRlIFlvdVR1YmUgdmllbmUgZW4gV2ViUCB5IEVtYmVk
:::VGh1bWJuYWlsIGRlIHl0LWRscCBsYQogICAgY29udmllcnRlIGEgUE5HICgiUE5H
:::IGlzIHByZWZlcnJlZCBzaW5jZSBKUEVHIGlzIGxvc3N5IiksIGFzaSBxdWUKICAg
:::IGFxdWkgbm9zIGFzZWd1cmFtb3Mgbm9zb3Ryb3MgZGUgcXVlIGFjYWJlIGVuIEpQ
:::RUcuIiIiCiAgICBpZiBub3QgZGF0b3Mgb3Igbm90IEZGTVBFRzoKICAgICAgICBy
:::ZXR1cm4gTm9uZQogICAgYmFzZSA9IFBhdGgodGVtcGZpbGUuZ2V0dGVtcGRpcigp
:::KSAvICgnbXVzaWthbGFuX2NhcmF0dWxhXyVkJyAlIG9zLmdldHBpZCgpKQogICAg
:::b3JpZ2VuLCBkZXN0aW5vID0gYmFzZS53aXRoX3N1ZmZpeCgnLm9yaWcnKSwgYmFz
:::ZS53aXRoX3N1ZmZpeCgnLmpwZycpCiAgICB0cnk6CiAgICAgICAgb3JpZ2VuLndy
:::aXRlX2J5dGVzKGRhdG9zKQogICAgICAgIHIgPSBzdWJwcm9jZXNzLnJ1bigKICAg
:::ICAgICAgICAgW3N0cihGRk1QRUcpLCAnLXknLCAnLWxvZ2xldmVsJywgJ2Vycm9y
:::JywgJy1pJywgc3RyKG9yaWdlbiksCiAgICAgICAgICAgICAnLXE6dicsICcyJywg
:::c3RyKGRlc3Rpbm8pXSwKICAgICAgICAgICAgc3Rkb3V0PXN1YnByb2Nlc3MuREVW
:::TlVMTCwgc3RkZXJyPXN1YnByb2Nlc3MuREVWTlVMTCkKICAgICAgICBpZiByLnJl
:::dHVybmNvZGUgPT0gMCBhbmQgZGVzdGluby5leGlzdHMoKToKICAgICAgICAgICAg
:::anBnID0gZGVzdGluby5yZWFkX2J5dGVzKCkKICAgICAgICAgICAgaWYgX2VzX2pw
:::ZyhqcGcpOgogICAgICAgICAgICAgICAgcmV0dXJuIGpwZwogICAgZXhjZXB0IEV4
:::Y2VwdGlvbjoKICAgICAgICBwYXNzCiAgICBmaW5hbGx5OgogICAgICAgIGZvciBm
:::IGluIChvcmlnZW4sIGRlc3Rpbm8pOgogICAgICAgICAgICB0cnk6CiAgICAgICAg
:::ICAgICAgICBmLnVubGluaygpCiAgICAgICAgICAgIGV4Y2VwdCBPU0Vycm9yOgog
:::ICAgICAgICAgICAgICAgcGFzcwogICAgcmV0dXJuIE5vbmUKCgpkZWYgX3dtX3Bp
:::Y3R1cmUoanBnLCBkZXNjcmlwY2lvbj0nJyk6CiAgICAiIiJFbXBhcXVldGEgdW5v
:::cyBieXRlcyBKUEVHIGVuIGVsIGF0cmlidXRvIFdNL1BpY3R1cmUgZGVsIGNvbnRl
:::bmVkb3IKICAgIEFTRiAodGlwbyAzID0gcG9ydGFkYSBmcm9udGFsKSwgY29tbyBo
:::YWNpYSBlbCBzY3JpcHQgYW50aWd1by4iIiIKICAgIGRlZiB1MTYocyk6CiAgICAg
:::ICAgcmV0dXJuIHN0cihzKS5lbmNvZGUoJ3V0Zi0xNi1sZScpICsgYidceDAwXHgw
:::MCcKCiAgICBtaW1lID0gdTE2KCdpbWFnZS9qcGVnJykKICAgIGRlc2MgPSB1MTYo
:::ZGVzY3JpcGNpb24pCiAgICByZXR1cm4gKGInXHgwMycgKyBsZW4obWltZSkudG9f
:::Ynl0ZXMoNCwgJ2xpdHRsZScpICsgbWltZQogICAgICAgICAgICArIGxlbihkZXNj
:::KS50b19ieXRlcyg0LCAnbGl0dGxlJykgKyBkZXNjICsganBnKQoKCmRlZiBfbW9v
:::dl9wcmltZXJvKHJ1dGEpOgogICAgIiIiVHJ1ZSBzaSBlbCBhdG9tbyAnbW9vdicg
:::ZXN0YSBBTlRFUyBxdWUgJ21kYXQnIGVudHJlIGxhcyBjYWphcwogICAgdG9wLWxl
:::dmVsIGRlbCBNUDQvTTRBIChlbCBvcmRlbiAnZmFzdHN0YXJ0JyBkZSBpVHVuZXMp
:::LiBTb2xvIGxlZQogICAgbGEgY2FiZWNlcmEgKDQgTUIpIGNvbiB1biBwYXNlIGRl
:::IHRhbWFub3M6IG5vIGNhcmdhIGVsIGFyY2hpdm8uIiIiCiAgICB0cnk6CiAgICAg
:::ICAgd2l0aCBvcGVuKHJ1dGEsICdyYicpIGFzIGZoOgogICAgICAgICAgICBjYWIg
:::PSBmaC5yZWFkKDQgPDwgMjApCiAgICBleGNlcHQgT1NFcnJvcjoKICAgICAgICBy
:::ZXR1cm4gRmFsc2UKICAgIHBvcywgZmluID0gMCwgbGVuKGNhYikKICAgIHdoaWxl
:::IHBvcyArIDggPD0gZmluOgogICAgICAgIHRpcG8gPSBjYWJbcG9zICsgNDpwb3Mg
:::KyA4XQogICAgICAgIGlmIHRpcG8gaW4gKGInbW9vdicsIGInbWRhdCcpOgogICAg
:::ICAgICAgICByZXR1cm4gdGlwbyA9PSBiJ21vb3YnCiAgICAgICAgc2l6ZSA9IGlu
:::dC5mcm9tX2J5dGVzKGNhYltwb3M6cG9zICsgNF0sICdiaWcnKQogICAgICAgIGlm
:::IHNpemUgPT0gMTogICAgICAgICAgICAgICAgICAgICAgICMgbGFyZ2VzaXplIGRl
:::IDY0IGJpdHMKICAgICAgICAgICAgaWYgcG9zICsgMTYgPiBmaW46CiAgICAgICAg
:::ICAgICAgICByZXR1cm4gRmFsc2UKICAgICAgICAgICAgc2l6ZSA9IGludC5mcm9t
:::X2J5dGVzKGNhYltwb3MgKyA4OnBvcyArIDE2XSwgJ2JpZycpCiAgICAgICAgICAg
:::IGlmIHNpemUgPCAxNjoKICAgICAgICAgICAgICAgIHJldHVybiBGYWxzZQogICAg
:::ICAgIGVsaWYgc2l6ZSA8IDg6ICAgICAgICAgICAgICAgICAgICAgICMgY2FqYSBy
:::b3RhIG8gRU9GCiAgICAgICAgICAgIHJldHVybiBGYWxzZQogICAgICAgIHBvcyAr
:::PSBzaXplCiAgICByZXR1cm4gRmFsc2UKCgpkZWYgX21vb3ZfYWxfcHJpbmNpcGlv
:::KHApOgogICAgIiIidjIuODogZGVqYSBlbCBhdG9tbyBtb292IChxdWUgbGxldmEg
:::bGFzIGV0aXF1ZXRhcykgYWwgUFJJTkNJUElPCiAgICBkZWwgLm00YSwgY29tbyBo
:::YWNlIGlUdW5lcyAoJ2Zhc3RzdGFydCcpLgoKICAgIEZGbXBlZyBlc2NyaWJlIGVs
:::IE00QSBjb24gbW9vdiBBTCBGSU5BTCwgZGV0cmFzIGRlIHRvZG8gZWwgYXVkaW8K
:::ICAgIChtZGF0KS4gRWwgTVAzIGRlIHJlZmVyZW5jaWEgcXVlIGVsIHJlcHJvZHVj
:::dG9yIGRlbCB1c3VhcmlvIHNpIGxlZQogICAgbGxldmEgc3UgSUQzdjIgYWwgaW5p
:::Y2lvIGRlbCBhcmNoaXZvLCB5IGxvcyByZXByb2R1Y3RvcmVzIGJhcmF0b3MKICAg
:::IHN1ZWxlbiBidXNjYXIgbGFzIGV0aXF1ZXRhcyBlc2NhbmVhbmRvIHNvbG8gbGEg
:::Y2FiZWNlcmEgZGVsCiAgICBhcmNoaXZvOiBwb3IgZXNvIG1vc3RyYWJhbiAndW5r
:::bm93bicgYXVucXVlIGVsIE00QSBlc3R1dmllcmEKICAgIHBlcmZlY3RhbWVudGUg
:::ZXRpcXVldGFkbyAoYXRvbXMgaWxzdCBlc3RhbmRhciwgdmVyaWZpY2FkbyBlbgog
:::ICAgdjIuNykuIENvbiAtbW92ZmxhZ3MgK2Zhc3RzdGFydCBlbCBtb292IGVudGVy
:::byAoeSBkZW50cm8KICAgIG1vb3YudWR0YS5tZXRhLmlsc3QgY29uIHRpdHVsby9h
:::cnRpc3RhL2FsYnVtL2NvdnIpIHBhc2EgZGVsYW50ZQogICAgZGVsIG1kYXQgU0lO
:::IHJlY29kaWZpY2FyIG5hZGEgKC1jIGNvcHkpLiBTaSBhbGdvIGZhbGxhIHNlIGRl
:::dnVlbHZlCiAgICBGYWxzZSB5IGVsIGFyY2hpdm8gcXVlZGEgY29tbyBlc3RhYmE6
:::IGVzdG8gbnVuY2EgZGViZSByb21wZXIgbGEKICAgIGRlc2NhcmdhIG5pIGxhcyBl
:::dGlxdWV0YXMgeWEgZXNjcml0YXMuIiIiCiAgICBpZiBub3QgRkZNUEVHIG9yIF9t
:::b292X3ByaW1lcm8ocCk6CiAgICAgICAgcmV0dXJuIEZhbHNlCiAgICB0bXAgPSBw
:::LndpdGhfbmFtZShwLnN0ZW0gKyAnLmZhc3RzdGFydC5tNGEnKQogICAgdHJ5Ogog
:::ICAgICAgIHIgPSBzdWJwcm9jZXNzLnJ1bigKICAgICAgICAgICAgW3N0cihGRk1Q
:::RUcpLCAnLXknLCAnLWxvZ2xldmVsJywgJ2Vycm9yJywgJy1pJywgc3RyKHApLAog
:::ICAgICAgICAgICAgJy1tYXAnLCAnMCcsICctYycsICdjb3B5JywgJy1tb3ZmbGFn
:::cycsICcrZmFzdHN0YXJ0JywKICAgICAgICAgICAgIHN0cih0bXApXSwKICAgICAg
:::ICAgICAgc3Rkb3V0PXN1YnByb2Nlc3MuREVWTlVMTCwgc3RkZXJyPXN1YnByb2Nl
:::c3MuREVWTlVMTCkKICAgICAgICBpZiAoci5yZXR1cm5jb2RlID09IDAgYW5kIHRt
:::cC5leGlzdHMoKQogICAgICAgICAgICAgICAgYW5kIF9tb292X3ByaW1lcm8odG1w
:::KQogICAgICAgICAgICAgICAgYW5kIHRtcC5zdGF0KCkuc3Rfc2l6ZSAqIDEwMAog
:::ICAgICAgICAgICAgICAgPj0gcC5zdGF0KCkuc3Rfc2l6ZSAqIDkwKToKICAgICAg
:::ICAgICAgb3MucmVwbGFjZSh0bXAsIHApCiAgICAgICAgICAgIHJldHVybiBUcnVl
:::CiAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgIHBhc3MKICAgIGZpbmFsbHk6
:::CiAgICAgICAgdHJ5OgogICAgICAgICAgICB0bXAudW5saW5rKCkKICAgICAgICBl
:::eGNlcHQgT1NFcnJvcjoKICAgICAgICAgICAgcGFzcwogICAgcmV0dXJuIEZhbHNl
:::CgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tIGV0aXF1ZXRhcwpkZWYgX2FydGlzdGFfbGlt
:::cGlvKGluZm8pOgogICAgIiIiTm9tYnJlIGRlbCBhcnRpc3RhIGxlZ2libGUgcGFy
:::YSByZXByb2R1Y3RvcmVzLgoKICAgIExvcyBjYW5hbGVzIGF1dG9tYXRpY29zIGRl
:::IG11c2ljYSBkZSBZb3VUdWJlIHNlIGxsYW1hbiAnWCAtIFRvcGljJzsKICAgIGVz
:::ZSBzdWZpam8gc29icmEgY3VhbmRvIHNlIHZlIGVuIGxhIHBhbnRhbGxhIGRlIHVu
:::IHJlcHJvZHVjdG9yLiIiIgogICAgYSA9IChpbmZvLmdldCgnYXJ0aXN0Jykgb3Ig
:::aW5mby5nZXQoJ2NyZWF0b3InKQogICAgICAgICBvciBpbmZvLmdldCgndXBsb2Fk
:::ZXInKSBvciBpbmZvLmdldCgnY2hhbm5lbCcpIG9yICcnKQogICAgYSA9IHN0cihh
:::KS5zdHJpcCgpCiAgICBhID0gcmUuc3ViKHInXHMqLVxzKlRvcGljXHMqJCcsICcn
:::LCBhLCBmbGFncz1yZS5JKS5zdHJpcCgpCiAgICByZXR1cm4gYQoKCmRlZiBfYWxi
:::dW1fZGUoaW5mbyk6CiAgICAiIiJBbGJ1bSBwYXJhIGVsIGFyY2hpdm8gZmluYWwu
:::CgogICAgeXQtZGxwIHNvbG8gZXNjcmliZSBhbGJ1bSBzaSBlbCBwcm9waW8gdmlk
:::ZW8gbG8gdHJhZSAoY2FzaSBudW5jYSk6CiAgICBwb3IgZXNvIGxvcyByZXByb2R1
:::Y3RvcmVzIG1vc3RyYWJhbiAnYWxidW0gZGVzY29ub2NpZG8nLiBPcmRlbiBkZQog
:::ICAgcHJlZmVyZW5jaWE6IGFsYnVtIHJlYWwgLT4gbm9tYnJlIGRlIGxhIHBsYXls
:::aXN0IC0+IGFydGlzdGEuIiIiCiAgICBmb3IgY2xhdmUgaW4gKCdhbGJ1bScsICdw
:::bGF5bGlzdF90aXRsZScpOgogICAgICAgIHYgPSBzdHIoaW5mby5nZXQoY2xhdmUp
:::IG9yICcnKS5zdHJpcCgpCiAgICAgICAgaWYgdjoKICAgICAgICAgICAgcmV0dXJu
:::IHYKICAgIHJldHVybiBfYXJ0aXN0YV9saW1waW8oaW5mbykgb3IgJ1lvdVR1YmUn
:::CgoKZGVmIGFwbGljYXJfdGFncyhpbmZvLCBhcmNoaXZvLCBsb2c9Tm9uZSwgY2Fy
:::YXR1bGE9Tm9uZSk6CiAgICAiIiJFc2NyaWJlIGNvbiBtdXRhZ2VuIGxhcyBldGlx
:::dWV0YXMgZGVsIGFyY2hpdm8gZmluYWwuCgogICAgR2FyYW50aXphIHF1ZSBUT0RP
:::UyBsb3MgcmVwcm9kdWN0b3JlcyBtdWVzdHJlbiBhcnRpc3RhIHkgYWxidW0sCiAg
:::ICBhdW5xdWUgRkZtcGVnTWV0YWRhdGEgZGUgeXQtZGxwIG5vIGxvcyBoYXlhIGVz
:::Y3JpdG8uIENhZGEgZm9ybWF0bwogICAgY29uIFNVIGZvcm1hIGVzdGFuZGFyOgog
:::ICAgICDCtyBNUDM6IElEM3YyLjQgY29uIHRleHRvcyBVVEYtMTYgKGVuY29kaW5n
:::PTEpIHkgQVBJQyhtaW1lCiAgICAgICAgJ2ltYWdlL2pwZycsIHRpcG8gMywgZGVz
:::YyAnYXR0YWNoZWQgcGljdHVyZScpLCBjYWxjYWRvIGRlbAogICAgICAgIE1QMyBk
:::ZSByZWZlcmVuY2lhIHF1ZSBlbCByZXByb2R1Y3RvciBkZWwgdXN1YXJpbyBtdWVz
:::dHJhCiAgICAgICAgYmllbi4gRWwgcGFzZSBhbnRpZ3VvIHVzYWJhIGVuY29kaW5n
:::PTMgKFVURi04KSBkZW50cm8gZGUgdW4KICAgICAgICB0YWcgdjIuMzogZnVlcmEg
:::ZGUgZXNwZWNpZmljYWNpb24sIHkgbG9zIHJlcHJvZHVjdG9yZXMKICAgICAgICBi
:::YXJhdG9zIGRlc2NhcnRhYmFuIGxhIGV0aXF1ZXRhIEVOVEVSQSAobmkgYXJ0aXN0
:::YSwgbmkKICAgICAgICBhbGJ1bSwgbmkgcG9ydGFkYSkuCiAgICAgIMK3IE00QTog
:::YXRvbW9zIE1QNCBlc3RhbmRhciAowqluYW0vwqlBUlQvYUFSVC/CqWFsYi/CqWRh
:::eS/CqWNtdCkgeQogICAgICAgIGNvdnIgZW4gSlBFRywgY29tbyBpVHVuZXM7IGFk
:::ZW1hcyAodjIuOCkgZWwgYXRvbW8gbW9vdiBxdWVkYQogICAgICAgIEFMIFBSSU5D
:::SVBJTyBkZWwgYXJjaGl2byAoZmFzdHN0YXJ0KTogZmZtcGVnIGxvIGVzY3JpYmUg
:::YWwKICAgICAgICBmaW5hbCB5IGxvcyByZXByb2R1Y3RvcmVzIGJhcmF0b3Mgc29s
:::byBlc2NhbmVhbiBsYSBjYWJlY2VyYSwKICAgICAgICBwb3IgZXNvIG1vc3RyYWJh
:::biAndW5rbm93bicgYXVucXVlIGxhcyBldGlxdWV0YXMgZXN0dXZpZXJhbi4KICAg
:::ICAgwrcgV0FWOiBJRDMgZGVudHJvIGRlbCBSSUZGIChtdXRhZ2VuLndhdmUpLCBp
:::Z3VhbCBxdWUgZWwgTVAzLAogICAgICAgIG1hcyBBUElDIGNvbiBsYSBjYXJhdHVs
:::YSAobnVldm8gZW4gdjIuNykuCiAgICAgIMK3IEZMQUM6IFZvcmJpcyBjb21tZW50
:::cyArIFBpY3R1cmUgZW4gSlBFRy4KICAgICAgwrcgV01BOiBBU0YgVGl0bGUvQXV0
:::aG9yL1dNL0FsYnVtVGl0bGUvV00vQXV0aG9yVVJMICsgV00vUGljdHVyZS4KICAg
:::ICAgwrcgbGEgY2FyYXR1bGEgU0lFTVBSRSBhY2FiYSBlbiBKUEVHIHkgc2UgZXNj
:::cmliZSBBUVVJIGNvbgogICAgICAgIG11dGFnZW46IGRlc2RlIHYyLjcgRW1iZWRU
:::aHVtYm5haWwgeWEgbm8gdG9jYSBsYSBjYXJhdHVsYQogICAgICAgIChzdSBtZXRv
:::ZG8gY2FtYmlhIGVudHJlIHZlcnNpb25lcyBkZSB5dC1kbHAgeSBhbGd1bmEKICAg
:::ICAgICBjb252ZXJzaW9uIHN1eWEgZGVqYWJhIFBORy9XZWJQIHF1ZSBsb3MgcmVw
:::cm9kdWN0b3JlcwogICAgICAgIGJhcmF0b3Mgbm8gbGVlbik7CiAgICAgIMK3IGVs
:::IGNvbWVudGFyaW8gZ3VhcmRhIGxhIFVSTCBkZWwgdmlkZW8gKGNvbW8gZWwgc2Ny
:::aXB0IGFudGlndW8pLgogICAgYGNhcmF0dWxhYCBzb24gbG9zIGJ5dGVzIGRlIGxh
:::IG1pbmlhdHVyYSBkZXNjYXJnYWRhIChvcGNpb25hbCkuIiIiCiAgICB0cnk6CiAg
:::ICAgICAgcCA9IFBhdGgoYXJjaGl2bykKICAgICAgICBpZiBub3QgcC5leGlzdHMo
:::KToKICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgYXJ0aXN0YSA9IF9hcnRpc3Rh
:::X2xpbXBpbyhpbmZvKQogICAgICAgIGFsYnVtID0gX2FsYnVtX2RlKGluZm8pCiAg
:::ICAgICAgdGl0dWxvID0gc3RyKGluZm8uZ2V0KCd0cmFjaycpIG9yIGluZm8uZ2V0
:::KCd0aXRsZScpIG9yICcnKS5zdHJpcCgpCiAgICAgICAgZmVjaGEgPSBzdHIoaW5m
:::by5nZXQoJ3JlbGVhc2VfeWVhcicpIG9yICcnKQogICAgICAgIGlmIG5vdCBmZWNo
:::YToKICAgICAgICAgICAgZmVjaGEgPSBzdHIoaW5mby5nZXQoJ3VwbG9hZF9kYXRl
:::Jykgb3IgJycpCiAgICAgICAgICAgIGlmIGxlbihmZWNoYSkgPT0gOCBhbmQgZmVj
:::aGEuaXNkaWdpdCgpOgogICAgICAgICAgICAgICAgZmVjaGEgPSBmZWNoYVs6NF0K
:::ICAgICAgICB1cmwgPSBzdHIoaW5mby5nZXQoJ3dlYnBhZ2VfdXJsJykgb3IgJycp
:::LnN0cmlwKCkKICAgICAgICBpZiBjYXJhdHVsYSBhbmQgbm90IF9lc19qcGcoY2Fy
:::YXR1bGEpOgogICAgICAgICAgICBjYXJhdHVsYSA9IF9hX2pwZyhjYXJhdHVsYSkK
:::ICAgICAgICBleHQgPSBwLnN1ZmZpeC5sb3dlcigpCiAgICAgICAgaWYgZXh0ID09
:::ICcubTRhJzoKICAgICAgICAgICAgIyB2Mi44OiBBTlRFUyBkZSBldGlxdWV0YXIs
:::IG1vb3YgKHRpdHVsby9hcnRpc3RhL2FsYnVtL2NvdnIpCiAgICAgICAgICAgICMg
:::YWwgcHJpbmNpcGlvIGRlbCBhcmNoaXZvOyBtdXRhZ2VuIGNvbnNlcnZhIGVzZSBv
:::cmRlbi4KICAgICAgICAgICAgaWYgX21vb3ZfYWxfcHJpbmNpcGlvKHApIGFuZCBs
:::b2c6CiAgICAgICAgICAgICAgICBsb2coJ000QSByZW9yZGVuYWRvOiBldGlxdWV0
:::YXMgYWwgaW5pY2lvIChmYXN0c3RhcnQsICcKICAgICAgICAgICAgICAgICAgICAn
:::Y29tbyBpVHVuZXMpJywgJ2dyaXMnKQogICAgICAgICAgICBmcm9tIG11dGFnZW4u
:::bXA0IGltcG9ydCBNUDQsIE1QNENvdmVyCiAgICAgICAgICAgIG0gPSBNUDQoc3Ry
:::KHApKQogICAgICAgICAgICBpZiB0aXR1bG86CiAgICAgICAgICAgICAgICBtWydc
:::eGE5bmFtJ10gPSBbdGl0dWxvXQogICAgICAgICAgICBpZiBhcnRpc3RhOgogICAg
:::ICAgICAgICAgICAgbVsnXHhhOUFSVCddID0gW2FydGlzdGFdCiAgICAgICAgICAg
:::ICAgICBtWydhQVJUJ10gPSBbYXJ0aXN0YV0KICAgICAgICAgICAgaWYgYWxidW06
:::CiAgICAgICAgICAgICAgICBtWydceGE5YWxiJ10gPSBbYWxidW1dCiAgICAgICAg
:::ICAgIGlmIGZlY2hhOgogICAgICAgICAgICAgICAgbVsnXHhhOWRheSddID0gW2Zl
:::Y2hhXQogICAgICAgICAgICBpZiB1cmw6CiAgICAgICAgICAgICAgICBtWydceGE5
:::Y210J10gPSBbdXJsXQogICAgICAgICAgICAjIC0tIGNhcmF0dWxhOiBkZXNkZSB2
:::Mi43IGxhIGVzY3JpYmUgU0lFTVBSRSBlc3RlIHBhc2UgY29uCiAgICAgICAgICAg
:::ICMgICAgbXV0YWdlbiAoRW1iZWRUaHVtYm5haWwgeWEgbm8gcGFydGljaXBhKS4g
:::QXRvbW8KICAgICAgICAgICAgIyAgICBlc3RhbmRhciAnY292cicgKHNpbiBlbCBw
:::cmVmaWpvIChjKSk7IGVuIG11dGFnZW4KICAgICAgICAgICAgIyAgICBtb2Rlcm5v
:::IGVzY3JpYmlyICdceGE5Y292cicgbGFuemEgVHlwZUVycm9yLgogICAgICAgICAg
:::ICB2aWVqYXMgPSBtLmdldCgnY292cicpIG9yIG0uZ2V0KCdceGE5Y292cicpIG9y
:::IFtdCiAgICAgICAgICAgIGlmIG5vdCB2aWVqYXM6CiAgICAgICAgICAgICAgICBp
:::ZiBjYXJhdHVsYToKICAgICAgICAgICAgICAgICAgICBtWydjb3ZyJ10gPSBbTVA0
:::Q292ZXIoY2FyYXR1bGEsIE1QNENvdmVyLkZPUk1BVF9KUEVHKV0KICAgICAgICAg
:::ICAgZWxpZiBhbGwoYy5pbWFnZWZvcm1hdCAhPSBNUDRDb3Zlci5GT1JNQVRfSlBF
:::RwogICAgICAgICAgICAgICAgICAgICBmb3IgYyBpbiB2aWVqYXMpOgogICAgICAg
:::ICAgICAgICAgbnVldmEgPSBfYV9qcGcoYnl0ZXModmllamFzWzBdKSkgb3IgY2Fy
:::YXR1bGEKICAgICAgICAgICAgICAgIGlmIG51ZXZhOgogICAgICAgICAgICAgICAg
:::ICAgIG1bJ2NvdnInXSA9IFtNUDRDb3ZlcihudWV2YSwgTVA0Q292ZXIuRk9STUFU
:::X0pQRUcpXQogICAgICAgICAgICAgICAgICAgIG0ucG9wKCdceGE5Y292cicsIE5v
:::bmUpCiAgICAgICAgICAgIGVsaWYgbS5nZXQoJ1x4YTljb3ZyJyk6CiAgICAgICAg
:::ICAgICAgICBtWydjb3ZyJ10gPSB2aWVqYXMKICAgICAgICAgICAgICAgIG0ucG9w
:::KCdceGE5Y292cicsIE5vbmUpCiAgICAgICAgICAgIG0uc2F2ZSgpCiAgICAgICAg
:::ZWxpZiBleHQgPT0gJy5tcDMnOgogICAgICAgICAgICAjIEZvcm1hdG8gRVhBQ1RP
:::IGRlbCBNUDMgZGUgcmVmZXJlbmNpYSAoU25hcHR1YmUsIGVzY3JpdG8gcG9yCiAg
:::ICAgICAgICAgICMgRkZtcGVnL0xhdmYpIHF1ZSBlbCByZXByb2R1Y3RvciBkZWwg
:::dXN1YXJpbyBTSSBtdWVzdHJhOgogICAgICAgICAgICAjICAgSUQzdjIuNC4wICsg
:::VElUMi9UUEUxL1RBTEIvQVBJQyBlbiBlbmNvZGluZz0xIChVVEYtMTYgY29uCiAg
:::ICAgICAgICAgICMgICBCT00pICsgQVBJQyhtaW1lICdpbWFnZS9qcGcnLCB0aXBv
:::IDMgPSBDT1ZFUl9GUk9OVCwgZGVzYwogICAgICAgICAgICAjICAgJ2F0dGFjaGVk
:::IHBpY3R1cmUnLCBKUEVHIHJlYWwpLiBFbCBwYXNlIGFudGVyaW9yIGVzY3JpYmlh
:::CiAgICAgICAgICAgICMgICBlbmNvZGluZz0zIChVVEYtOCkgZGVudHJvIGRlIHVu
:::IHRhZyB2Mi4zOiBmdWVyYSBkZQogICAgICAgICAgICAjICAgZXNwZWNpZmljYWNp
:::b24sIHkgbG9zIHJlcHJvZHVjdG9yZXMgYmFyYXRvcyBkZXNjYXJ0YWJhbgogICAg
:::ICAgICAgICAjICAgbGEgZXRpcXVldGEgZW50ZXJhIChuaSBhcnRpc3RhLCBuaSBh
:::bGJ1bSwgbmkgcG9ydGFkYSkuCiAgICAgICAgICAgIGZyb20gbXV0YWdlbi5pZDMg
:::aW1wb3J0IChBUElDLCBDT01NLCBJRDMsIFRBTEIsIFREUkMsIFRJVDIsCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBUTEVOLCBUUEUxLCBUUEUy
:::KQogICAgICAgICAgICB0cnk6CiAgICAgICAgICAgICAgICB0YWdzID0gSUQzKHN0
:::cihwKSkKICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAg
:::ICAgIHRhZ3MgPSBJRDMoKQogICAgICAgICAgICBpZiB0aXR1bG86CiAgICAgICAg
:::ICAgICAgICB0YWdzLnNldGFsbCgnVElUMicsIFtUSVQyKGVuY29kaW5nPTEsIHRl
:::eHQ9W3RpdHVsb10pXSkKICAgICAgICAgICAgaWYgYXJ0aXN0YToKICAgICAgICAg
:::ICAgICAgIHRhZ3Muc2V0YWxsKCdUUEUxJywgW1RQRTEoZW5jb2Rpbmc9MSwgdGV4
:::dD1bYXJ0aXN0YV0pXSkKICAgICAgICAgICAgICAgIHRhZ3Muc2V0YWxsKCdUUEUy
:::JywgW1RQRTIoZW5jb2Rpbmc9MSwgdGV4dD1bYXJ0aXN0YV0pXSkKICAgICAgICAg
:::ICAgaWYgYWxidW06CiAgICAgICAgICAgICAgICB0YWdzLnNldGFsbCgnVEFMQics
:::IFtUQUxCKGVuY29kaW5nPTEsIHRleHQ9W2FsYnVtXSldKQogICAgICAgICAgICBp
:::ZiBmZWNoYToKICAgICAgICAgICAgICAgIHRhZ3Muc2V0YWxsKCdURFJDJywgW1RE
:::UkMoZW5jb2Rpbmc9MSwgdGV4dD1bZmVjaGFdKV0pCiAgICAgICAgICAgIGR1ciA9
:::IGluZm8uZ2V0KCdkdXJhdGlvbicpCiAgICAgICAgICAgIGlmIGR1cjoKICAgICAg
:::ICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgICAgICB0YWdzLnNldGFsbCgn
:::VExFTicsIFtUTEVOKGVuY29kaW5nPTAsIHRleHQ9WwogICAgICAgICAgICAgICAg
:::ICAgICAgICBzdHIoaW50KGZsb2F0KGR1cikgKiAxMDAwKSldKV0pCiAgICAgICAg
:::ICAgICAgICBleGNlcHQgKFR5cGVFcnJvciwgVmFsdWVFcnJvcik6CiAgICAgICAg
:::ICAgICAgICAgICAgcGFzcwogICAgICAgICAgICBpZiB1cmw6CiAgICAgICAgICAg
:::ICAgICB0YWdzLnNldGFsbCgnQ09NTScsIFtDT01NKGVuY29kaW5nPTEsIGxhbmc9
:::J2VuZycsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::IGRlc2M9JycsIHRleHQ9W3VybF0pXSkKICAgICAgICAgICAgIyBQb3J0YWRhOiBt
:::aXNtYXMgY29uc3RhbnRlcyBkZWwgYXJjaGl2byBkZSByZWZlcmVuY2lhLgogICAg
:::ICAgICAgICAjIEJ5dGVzOiBgY2FyYXR1bGFgIG8sIHNpIEVtYmVkVGh1bWJuYWls
:::IHlhIGluY3J1c3RvIGFsZ28sCiAgICAgICAgICAgICMgbG9zIGRhdG9zIGRlbCBB
:::UElDIGV4aXN0ZW50ZTsgc2llbXByZSBhY2FiYW1vcyBlbiBKUEVHLgogICAgICAg
:::ICAgICBkYXRvcyA9IGNhcmF0dWxhCiAgICAgICAgICAgIGlmIG5vdCBkYXRvczoK
:::ICAgICAgICAgICAgICAgIGFwaWNzID0gdGFncy5nZXRhbGwoJ0FQSUMnKQogICAg
:::ICAgICAgICAgICAgaWYgYXBpY3M6CiAgICAgICAgICAgICAgICAgICAgZGF0b3Mg
:::PSBhcGljc1swXS5kYXRhCiAgICAgICAgICAgIGlmIGRhdG9zIGFuZCBub3QgX2Vz
:::X2pwZyhkYXRvcyk6CiAgICAgICAgICAgICAgICBkYXRvcyA9IF9hX2pwZyhkYXRv
:::cykKICAgICAgICAgICAgaWYgZGF0b3M6CiAgICAgICAgICAgICAgICB0YWdzLnNl
:::dGFsbCgnQVBJQycsIFtBUElDKGVuY29kaW5nPTEsIG1pbWU9J2ltYWdlL2pwZycs
:::CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHR5cGU9
:::MywgZGVzYz0nYXR0YWNoZWQgcGljdHVyZScsCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgIGRhdGE9ZGF0b3MpXSkKICAgICAgICAgICAg
:::IyB2Mi40ICsgVVRGLTE2OiBsYSBtaXNtYSBjb21iaW5hY2lvbiBkZWwgYXJjaGl2
:::byBkZQogICAgICAgICAgICAjIHJlZmVyZW5jaWEgKElEM3YyLjQuMCBlc2NyaXRv
:::IHBvciBMYXZmNjAuMy4xMDApLgogICAgICAgICAgICB0YWdzLnNhdmUoc3RyKHAp
:::LCB2Ml92ZXJzaW9uPTQpCiAgICAgICAgZWxpZiBleHQgPT0gJy53YXYnOgogICAg
:::ICAgICAgICBmcm9tIG11dGFnZW4uaWQzIGltcG9ydCAoQVBJQywgQ09NTSwgVERS
:::QywgVElUMiwgVExFTiwgVFBFMSwKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgIFRQRTIsIFRBTEIpCiAgICAgICAgICAgIGZyb20gbXV0YWdlbi53
:::YXZlIGltcG9ydCBXQVZFCiAgICAgICAgICAgIHcgPSBXQVZFKHN0cihwKSkKICAg
:::ICAgICAgICAgaWYgdy50YWdzIGlzIE5vbmU6CiAgICAgICAgICAgICAgICB3LmFk
:::ZF90YWdzKCkKICAgICAgICAgICAgIyBlbmNvZGluZz0xIChVVEYtMTYpLCBtaXNt
:::YSByZWdsYSBxdWUgZW4gTVAzOiBsb3MKICAgICAgICAgICAgIyByZXByb2R1Y3Rv
:::cmVzIGJhcmF0b3Mgbm8gcGFyc2VhbiBmcmFtZXMgVVRGLTguCiAgICAgICAgICAg
:::IGlmIHRpdHVsbzoKICAgICAgICAgICAgICAgIHcudGFncy5zZXRhbGwoJ1RJVDIn
:::LCBbVElUMihlbmNvZGluZz0xLCB0ZXh0PVt0aXR1bG9dKV0pCiAgICAgICAgICAg
:::IGlmIGFydGlzdGE6CiAgICAgICAgICAgICAgICB3LnRhZ3Muc2V0YWxsKCdUUEUx
:::JywgW1RQRTEoZW5jb2Rpbmc9MSwgdGV4dD1bYXJ0aXN0YV0pXSkKICAgICAgICAg
:::ICAgICAgIHcudGFncy5zZXRhbGwoJ1RQRTInLCBbVFBFMihlbmNvZGluZz0xLCB0
:::ZXh0PVthcnRpc3RhXSldKQogICAgICAgICAgICBpZiBhbGJ1bToKICAgICAgICAg
:::ICAgICAgIHcudGFncy5zZXRhbGwoJ1RBTEInLCBbVEFMQihlbmNvZGluZz0xLCB0
:::ZXh0PVthbGJ1bV0pXSkKICAgICAgICAgICAgaWYgZmVjaGE6CiAgICAgICAgICAg
:::ICAgICB3LnRhZ3Muc2V0YWxsKCdURFJDJywgW1REUkMoZW5jb2Rpbmc9MSwgdGV4
:::dD1bZmVjaGFdKV0pCiAgICAgICAgICAgIGR1ciA9IGluZm8uZ2V0KCdkdXJhdGlv
:::bicpCiAgICAgICAgICAgIGlmIGR1cjoKICAgICAgICAgICAgICAgIHRyeToKICAg
:::ICAgICAgICAgICAgICAgICB3LnRhZ3Muc2V0YWxsKCdUTEVOJywgW1RMRU4oZW5j
:::b2Rpbmc9MCwgdGV4dD1bCiAgICAgICAgICAgICAgICAgICAgICAgIHN0cihpbnQo
:::ZmxvYXQoZHVyKSAqIDEwMDApKV0pXSkKICAgICAgICAgICAgICAgIGV4Y2VwdCAo
:::VHlwZUVycm9yLCBWYWx1ZUVycm9yKToKICAgICAgICAgICAgICAgICAgICBwYXNz
:::CiAgICAgICAgICAgIGlmIHVybDoKICAgICAgICAgICAgICAgIHcudGFncy5zZXRh
:::bGwoJ0NPTU0nLCBbQ09NTShlbmNvZGluZz0xLCBsYW5nPSdlbmcnLAogICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRlc2M9JycsIHRl
:::eHQ9W3VybF0pXSkKICAgICAgICAgICAgIyB2Mi43OiBjYXJhdHVsYSBlbiBlbCBJ
:::RDMgZGVsIFdBViAobWlzbWFzIGNvbnN0YW50ZXMgcXVlCiAgICAgICAgICAgICMg
:::ZWwgTVAzIGRlIHJlZmVyZW5jaWEpLCBwYXJhIGxvcyByZXByb2R1Y3RvcmVzIHF1
:::ZSBsZWVuCiAgICAgICAgICAgICMgZWwgY2h1bmsgJ2lkMyAnIGRlbnRybyBkZWwg
:::UklGRi4KICAgICAgICAgICAgZGF0b3MgPSBjYXJhdHVsYQogICAgICAgICAgICBp
:::ZiBub3QgZGF0b3M6CiAgICAgICAgICAgICAgICBhcGljcyA9IHcudGFncy5nZXRh
:::bGwoJ0FQSUMnKQogICAgICAgICAgICAgICAgaWYgYXBpY3M6CiAgICAgICAgICAg
:::ICAgICAgICAgZGF0b3MgPSBhcGljc1swXS5kYXRhCiAgICAgICAgICAgIGlmIGRh
:::dG9zIGFuZCBub3QgX2VzX2pwZyhkYXRvcyk6CiAgICAgICAgICAgICAgICBkYXRv
:::cyA9IF9hX2pwZyhkYXRvcykKICAgICAgICAgICAgaWYgZGF0b3M6CiAgICAgICAg
:::ICAgICAgICB3LnRhZ3Muc2V0YWxsKCdBUElDJywgW0FQSUMoZW5jb2Rpbmc9MSwg
:::bWltZT0naW1hZ2UvanBnJywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICB0eXBlPTMsIGRlc2M9J2F0dGFjaGVkIHBpY3R1cmUnLAog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGRhdGE9
:::ZGF0b3MpXSkKICAgICAgICAgICAgdy5zYXZlKCkKICAgICAgICBlbGlmIGV4dCA9
:::PSAnLmZsYWMnOgogICAgICAgICAgICBmcm9tIG11dGFnZW4uZmxhYyBpbXBvcnQg
:::RkxBQywgUGljdHVyZQogICAgICAgICAgICBmID0gRkxBQyhzdHIocCkpCiAgICAg
:::ICAgICAgIGlmIHRpdHVsbzoKICAgICAgICAgICAgICAgIGZbJ3RpdGxlJ10gPSBb
:::dGl0dWxvXQogICAgICAgICAgICBpZiBhcnRpc3RhOgogICAgICAgICAgICAgICAg
:::ZlsnYXJ0aXN0J10gPSBbYXJ0aXN0YV0KICAgICAgICAgICAgICAgIGZbJ2FsYnVt
:::YXJ0aXN0J10gPSBbYXJ0aXN0YV0KICAgICAgICAgICAgaWYgYWxidW06CiAgICAg
:::ICAgICAgICAgICBmWydhbGJ1bSddID0gW2FsYnVtXQogICAgICAgICAgICBpZiBm
:::ZWNoYToKICAgICAgICAgICAgICAgIGZbJ2RhdGUnXSA9IFtmZWNoYV0KICAgICAg
:::ICAgICAgaWYgdXJsOgogICAgICAgICAgICAgICAgZlsnY29tbWVudCddID0gW3Vy
:::bF0KICAgICAgICAgICAgaWYgbm90IGYucGljdHVyZXM6CiAgICAgICAgICAgICAg
:::ICBpZiBjYXJhdHVsYToKICAgICAgICAgICAgICAgICAgICBwaWMgPSBQaWN0dXJl
:::KCkKICAgICAgICAgICAgICAgICAgICBwaWMubWltZSwgcGljLnR5cGUsIHBpYy5k
:::ZXNjID0gJ2ltYWdlL2pwZWcnLCAzLCAnQ292ZXInCiAgICAgICAgICAgICAgICAg
:::ICAgcGljLmRhdGEgPSBjYXJhdHVsYQogICAgICAgICAgICAgICAgICAgIGYuYWRk
:::X3BpY3R1cmUocGljKQogICAgICAgICAgICBlbGlmIGFsbChwaS5taW1lICE9ICdp
:::bWFnZS9qcGVnJyBmb3IgcGkgaW4gZi5waWN0dXJlcyk6CiAgICAgICAgICAgICAg
:::ICBudWV2YSA9IF9hX2pwZyhmLnBpY3R1cmVzWzBdLmRhdGEpIG9yIGNhcmF0dWxh
:::CiAgICAgICAgICAgICAgICBpZiBudWV2YToKICAgICAgICAgICAgICAgICAgICBm
:::b3IgdmllamEgaW4gbGlzdChmLnBpY3R1cmVzKToKICAgICAgICAgICAgICAgICAg
:::ICAgICAgZi5yZW1vdmVfcGljdHVyZSh2aWVqYSkKICAgICAgICAgICAgICAgICAg
:::ICBwaWMgPSBQaWN0dXJlKCkKICAgICAgICAgICAgICAgICAgICBwaWMubWltZSwg
:::cGljLnR5cGUsIHBpYy5kZXNjID0gJ2ltYWdlL2pwZWcnLCAzLCAnQ292ZXInCiAg
:::ICAgICAgICAgICAgICAgICAgcGljLmRhdGEgPSBudWV2YQogICAgICAgICAgICAg
:::ICAgICAgIGYuYWRkX3BpY3R1cmUocGljKQogICAgICAgICAgICBmLnNhdmUoKQog
:::ICAgICAgIGVsaWYgZXh0ID09ICcud21hJzoKICAgICAgICAgICAgZnJvbSBtdXRh
:::Z2VuLmFzZiBpbXBvcnQgQVNGLCBBU0ZCeXRlQXJyYXlBdHRyaWJ1dGUKICAgICAg
:::ICAgICAgYSA9IEFTRihzdHIocCkpCiAgICAgICAgICAgIGlmIHRpdHVsbzoKICAg
:::ICAgICAgICAgICAgIGFbJ1RpdGxlJ10gPSBbdGl0dWxvXQogICAgICAgICAgICBp
:::ZiBhcnRpc3RhOgogICAgICAgICAgICAgICAgYVsnQXV0aG9yJ10gPSBbYXJ0aXN0
:::YV0KICAgICAgICAgICAgICAgIGFbJ1dNL0FsYnVtQXJ0aXN0J10gPSBbYXJ0aXN0
:::YV0KICAgICAgICAgICAgaWYgYWxidW06CiAgICAgICAgICAgICAgICBhWydXTS9B
:::bGJ1bVRpdGxlJ10gPSBbYWxidW1dCiAgICAgICAgICAgIGlmIGZlY2hhOgogICAg
:::ICAgICAgICAgICAgYVsnV00vWWVhciddID0gW2ZlY2hhXQogICAgICAgICAgICBp
:::ZiB1cmw6CiAgICAgICAgICAgICAgICBhWydEZXNjcmlwdGlvbiddID0gW3VybF0K
:::ICAgICAgICAgICAgICAgIGFbJ1dNL0F1dGhvclVSTCddID0gW3VybF0KICAgICAg
:::ICAgICAgaWYgY2FyYXR1bGE6CiAgICAgICAgICAgICAgICBhWydXTS9QaWN0dXJl
:::J10gPSBbQVNGQnl0ZUFycmF5QXR0cmlidXRlKAogICAgICAgICAgICAgICAgICAg
:::IF93bV9waWN0dXJlKGNhcmF0dWxhLCB0aXR1bG8gb3IgJ0NvdmVyJykpXQogICAg
:::ICAgICAgICBhLnNhdmUoKQogICAgICAgIGVsc2U6CiAgICAgICAgICAgIHJldHVy
:::bgogICAgICAgIGlmIGxvZzoKICAgICAgICAgICAgZXh0cmEgPSAnIMK3IGNhcsOh
:::dHVsYSBKUEVHJyBpZiBjYXJhdHVsYSBlbHNlICcnCiAgICAgICAgICAgIGxvZygn
:::RXRpcXVldGFzIGVzY3JpdGFzOiBhcnRpc3RhIMKrJXPCuyDCtyDDoWxidW0gwqsl
:::c8K7JXMnCiAgICAgICAgICAgICAgICAlIChhcnRpc3RhIG9yICfigJQnLCBhbGJ1
:::bSBvciAn4oCUJywgZXh0cmEpLCAnZ3JpcycpCiAgICBleGNlcHQgRXhjZXB0aW9u
:::IGFzIGU6CiAgICAgICAgIyBsYXMgZXRpcXVldGFzIG5vIHNvbiBjcml0aWNhczog
:::bnVuY2EgZGViZW4gcm9tcGVyIGxhIGRlc2NhcmdhCiAgICAgICAgaWYgbG9nOgog
:::ICAgICAgICAgICBsb2coJ05vIHNlIHB1ZGllcm9uIGVzY3JpYmlyIHRvZGFzIGxh
:::cyBldGlxdWV0YXM6ICVzJyAlIGUsCiAgICAgICAgICAgICAgICAnYXZpc28nKQoK
:::CiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLSBkZXNjYXJnYXMKZGVmIGRlc2Nhcmdhcl9hdWRp
:::byh1cmwsIG5vbWJyZV9mbXQsIGNhbGlkYWQsIGRlc3Rpbm8sIGVtYmViZXIsIGNv
:::bGEpOgogICAgIiIiQUFDICgubTRhKSAvIE1QMyAvIEZMQUMgLyBXQVYgdsOtYSBw
:::b3N0cHJvY2VzYWRvcmVzIGRlIHl0LWRscC4KCiAgICB5dC1kbHAgU09MTyBiYWph
:::LCBjb252aWVydGUgeSBlc2NyaWJlIGxvcyBtZXRhZGF0b3MgZGUgdGV4dG8KICAg
:::IChGRm1wZWdNZXRhZGF0YSkuIExhIGNhcsOhdHVsYSBOTyBsYSBpbmNydXN0YSBF
:::bWJlZFRodW1ibmFpbDogZGVzZGUKICAgIHYyLjcgbGEgZXNjcmliZSBhcGxpY2Fy
:::X3RhZ3MgY29uIG11dGFnZW4gKGNvdnIgZW4gbTRhLCBBUElDIGVuCiAgICBtcDMv
:::d2F2LCBQaWN0dXJlIGVuIGZsYWMpLCBzaWVtcHJlIGVuIEpQRUcgeSBjb24gbGEg
:::ZXN0cnVjdHVyYQogICAgZXhhY3RhIHF1ZSBsZWVuIGxvcyByZXByb2R1Y3RvcmVz
:::LiBBc8OtIGVsIHJlc3VsdGFkbyBubyBkZXBlbmRlIGRlCiAgICBsb3MgbcOpdG9k
:::b3MgaW50ZXJub3MgZGUgRW1iZWRUaHVtYm5haWwsIHF1ZSBjYW1iaWFuIGVudHJl
:::CiAgICB2ZXJzaW9uZXMgZGUgeXQtZGxwIChhbnRlcyBjb252ZXJ0w61hIGxhIHBv
:::cnRhZGEgYSBQTkcsIHkgc3UKICAgIG3DqXRvZG8gZmZtcGVnIGFkanVudGEgbGEg
:::aW1hZ2VuIGNvbW8gc3RyZWFtIGRlIHbDrWRlbykuIiIiCiAgICBkZWYgbG9nKG0s
:::IHQ9J2luZm8nKToKICAgICAgICBjb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQoKICAg
:::IGZtdCA9IEZPUk1BVE9TW25vbWJyZV9mbXRdCiAgICBjYXJwZXRhID0gZGVzdGlu
:::byAgICAgICAgICAjIHYyLjM6IHNpbiBzdWJjYXJwZXRhcyBwb3IgZm9ybWF0bwog
:::ICAgY2FycGV0YS5ta2RpcihwYXJlbnRzPVRydWUsIGV4aXN0X29rPVRydWUpCiAg
:::ICBjb2RlYyA9IGZtdFsnZXh0J10KICAgIGNvbl9wb3J0YWRhID0gZW1iZWJlciBh
:::bmQgbm9tYnJlX2ZtdCBpbiAoJ0FBQycsICdNUDMnLCAnRkxBQycsICdXQVYnKQog
:::ICAgY29uX3RhZ3MgPSBlbWJlYmVyCiAgICBwcHMgPSBbXQogICAgaWYgY29uX3Bv
:::cnRhZGE6CiAgICAgICAgcHBzLmFwcGVuZCh7J2tleSc6ICdGRm1wZWdUaHVtYm5h
:::aWxzQ29udmVydG9yJywgJ2Zvcm1hdCc6ICdqcGcnLAogICAgICAgICAgICAgICAg
:::ICAgICd3aGVuJzogJ2JlZm9yZV9kbCd9KQogICAgcHBzLmFwcGVuZCh7J2tleSc6
:::ICdGRm1wZWdFeHRyYWN0QXVkaW8nLCAncHJlZmVycmVkY29kZWMnOiBjb2RlYywK
:::ICAgICAgICAgICAgICAgICdwcmVmZXJyZWRxdWFsaXR5JzogY2FsaWRhZCBvciAn
:::MCd9KQogICAgaWYgY29uX3RhZ3M6CiAgICAgICAgcHBzLmFwcGVuZCh7J2tleSc6
:::ICdGRm1wZWdNZXRhZGF0YScsICdhZGRfbWV0YWRhdGEnOiBUcnVlfSkKICAgICMg
:::djIuNzogU0lOIEVtYmVkVGh1bWJuYWlsLiBMYSBtaW5pYXR1cmEgKGRlamFkYSBl
:::biAuanBnIGp1bnRvIGFsCiAgICAjIGFyY2hpdm8gcG9yIHdyaXRldGh1bWJuYWls
:::ICsgQ29udmVydG9yKSBsYSBpbmNydXN0YSBhcGxpY2FyX3RhZ3MKICAgICMgY29u
:::IG11dGFnZW46IGVzdHJ1Y3R1cmEgZ2FyYW50aXphZGEgZW4gdG9kb3MgbG9zIGZv
:::cm1hdG9zIHkgc2luCiAgICAjIGRlcGVuZGVyIGRlIGxvcyBtw6l0b2RvcyBpbnRl
:::cm5vcyBkZSB5dC1kbHAuCiAgICBvID0gb3B0c19iYXNlKGNhcnBldGEsIGNvbGEp
:::CiAgICBvWydmb3JtYXQnXSA9ICdiZXN0YXVkaW8vYmVzdCcKICAgIG9bJ3Bvc3Rw
:::cm9jZXNzb3JzJ10gPSBwcHMKICAgIG9bJ3dyaXRldGh1bWJuYWlsJ10gPSBjb25f
:::cG9ydGFkYQogICAgd2l0aCBZVF9ETFAuWW91dHViZURMKG8pIGFzIHlkbDoKICAg
:::ICAgICBpbmZvID0geWRsLmV4dHJhY3RfaW5mbyh1cmwsIGRvd25sb2FkPVRydWUp
:::CiAgICBhcmNoaXZvID0gYXJjaGl2b19maW5hbChpbmZvLCBjYXJwZXRhLCBjb2Rl
:::YykKICAgIGNhcmF0dWxhID0gX21pbmlhdHVyYV9ieXRlcyhjYXJwZXRhLCBhcmNo
:::aXZvKQogICAgaWYgYXJjaGl2byBhbmQgY29uX3BvcnRhZGE6CiAgICAgICAgbGlt
:::cGlhcl9taW5pYXR1cmFzKGNhcnBldGEsIGFyY2hpdm8pCiAgICBpZiBhcmNoaXZv
:::OgogICAgICAgIGFwbGljYXJfdGFncyhpbmZvLCBhcmNoaXZvLCBsb2csIGNhcmF0
:::dWxhKQogICAgcmV0dXJuIGluZm8sIGFyY2hpdm8KCgpkZWYgZGVzY2FyZ2FyX3dt
:::YSh1cmwsIGNhbGlkYWQsIGRlc3Rpbm8sIGVtYmViZXIsIGNvbGEpOgogICAgIiIi
:::V01BIDk2LzEyOCBrYnBzOiB5dC1kbHAgbm8gc29wb3J0YSB3bWEsIGFzw60gcXVl
:::IHNlIGJhamEgYSBXQVYgKGNvbgogICAgZXRpcXVldGFzKSB5IGx1ZWdvIEZGbXBl
:::ZyByZWNvZGlmaWNhIGEgd21hdjIgZGVudHJvIGRlbCAud21hIGZpbmFsLgogICAg
:::TGEgY2Fyw6F0dWxhIChXTS9QaWN0dXJlLCBlbiBKUEVHKSB5IGxhIFVSTCAoV00v
:::QXV0aG9yVVJMKSBzZQogICAgaW5jcnVzdGFuIGNvbiBtdXRhZ2VuLCBjb21vIGVu
:::IGVsIHNjcmlwdCBhbnRpZ3VvLiIiIgogICAgZGVmIGxvZyhtLCB0PSdpbmZvJyk6
:::CiAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICBjYXJwZXRhID0g
:::ZGVzdGlubyAgICAgICAgICAjIHYyLjM6IHNpbiBzdWJjYXJwZXRhcyBwb3IgZm9y
:::bWF0bwogICAgdG1wID0gY2FycGV0YSAvICdfdG1wJwogICAgc2h1dGlsLnJtdHJl
:::ZSh0bXAsIGlnbm9yZV9lcnJvcnM9VHJ1ZSkKICAgIHRtcC5ta2RpcihwYXJlbnRz
:::PVRydWUsIGV4aXN0X29rPVRydWUpCiAgICBvID0gb3B0c19iYXNlKHRtcCwgY29s
:::YSkKICAgIG9bJ2Zvcm1hdCddID0gJ2Jlc3RhdWRpby9iZXN0JwogICAgcHBzID0g
:::W3sna2V5JzogJ0ZGbXBlZ0V4dHJhY3RBdWRpbycsICdwcmVmZXJyZWRjb2RlYyc6
:::ICd3YXYnLAogICAgICAgICAgICAncHJlZmVycmVkcXVhbGl0eSc6ICcwJ31dCiAg
:::ICBpZiBlbWJlYmVyOgogICAgICAgIHBwcy5pbnNlcnQoMCwgeydrZXknOiAnRkZt
:::cGVnVGh1bWJuYWlsc0NvbnZlcnRvcicsCiAgICAgICAgICAgICAgICAgICAgICAg
:::J2Zvcm1hdCc6ICdqcGcnLCAnd2hlbic6ICdiZWZvcmVfZGwnfSkKICAgICAgICBw
:::cHMuYXBwZW5kKHsna2V5JzogJ0ZGbXBlZ01ldGFkYXRhJywgJ2FkZF9tZXRhZGF0
:::YSc6IFRydWV9KQogICAgb1sncG9zdHByb2Nlc3NvcnMnXSA9IHBwcwogICAgb1sn
:::d3JpdGV0aHVtYm5haWwnXSA9IGVtYmViZXIKICAgIHdpdGggWVRfRExQLllvdXR1
:::YmVETChvKSBhcyB5ZGw6CiAgICAgICAgaW5mbyA9IHlkbC5leHRyYWN0X2luZm8o
:::dXJsLCBkb3dubG9hZD1UcnVlKQogICAgd2F2ID0gYXJjaGl2b19maW5hbChpbmZv
:::LCB0bXAsICd3YXYnKQogICAgaWYgbm90IHdhdjoKICAgICAgICByYWlzZSBSdW50
:::aW1lRXJyb3IoJ05vIHNlIGVuY29udHLDsyBlbCBXQVYgaW50ZXJtZWRpby4nKQog
:::ICAgbWV0YSA9IFtdCiAgICBpZiBlbWJlYmVyOgogICAgICAgIGFydGlzdGEgPSAo
:::aW5mby5nZXQoJ2FydGlzdCcpIG9yIGluZm8uZ2V0KCd1cGxvYWRlcicpCiAgICAg
:::ICAgICAgICAgICAgICBvciBpbmZvLmdldCgnY2hhbm5lbCcpIG9yICcnKQogICAg
:::ICAgIGlmIGluZm8uZ2V0KCd0aXRsZScpOgogICAgICAgICAgICBtZXRhICs9IFsn
:::LW1ldGFkYXRhJywgJ3RpdGxlPScgKyBzdHIoaW5mb1sndGl0bGUnXSldCiAgICAg
:::ICAgaWYgYXJ0aXN0YToKICAgICAgICAgICAgbWV0YSArPSBbJy1tZXRhZGF0YScs
:::ICdhcnRpc3Q9JyArIHN0cihhcnRpc3RhKV0KICAgIHdtYSA9IGNhcnBldGEgLyAo
:::bGltcGlhcl9ub21icmUoaW5mby5nZXQoJ3RpdGxlJykgb3IgJ2F1ZGlvJykgKyAn
:::LndtYScpCiAgICBjbWQgPSBbc3RyKEZGTVBFRyksICcteScsICctaScsIHN0cih3
:::YXYpLCAnLXZuJywKICAgICAgICAgICAnLWM6YScsICd3bWF2MicsICctYjphJywg
:::Zid7Y2FsaWRhZH1rJ10gKyBtZXRhICsgW3N0cih3bWEpXQogICAgb2sgPSBjb252
:::ZXJ0aXJfZmZtcGVnKAogICAgICAgIGNtZCwgZidDb252aXJ0aWVuZG8gYSBXTUEg
:::KHdtYXYyIMK3IHtjYWxpZGFkfSBrYnBzKScsIGNvbGEpCiAgICBpZiBub3Qgb2s6
:::CiAgICAgICAgcmFpc2UgUnVudGltZUVycm9yKCdGRm1wZWcgbm8gcHVkbyBjcmVh
:::ciBlbCBhcmNoaXZvIFdNQS4nKQogICAgY2FyYXR1bGEgPSBOb25lCiAgICBpZiBl
:::bWJlYmVyOgogICAgICAgIGpwZ3MgPSBzb3J0ZWQodG1wLmdsb2IoJyouanBnJyks
:::CiAgICAgICAgICAgICAgICAgICAgICBrZXk9bGFtYmRhIHE6IHEuc3RhdCgpLnN0
:::X210aW1lLCByZXZlcnNlPVRydWUpCiAgICAgICAgaWYganBnczoKICAgICAgICAg
:::ICAgdHJ5OgogICAgICAgICAgICAgICAgY2FyYXR1bGEgPSBqcGdzWzBdLnJlYWRf
:::Ynl0ZXMoKQogICAgICAgICAgICBleGNlcHQgT1NFcnJvcjoKICAgICAgICAgICAg
:::ICAgIGNhcmF0dWxhID0gTm9uZQogICAgYXBsaWNhcl90YWdzKGluZm8sIHdtYSwg
:::bG9nLCBjYXJhdHVsYSkKICAgIHNodXRpbC5ybXRyZWUodG1wLCBpZ25vcmVfZXJy
:::b3JzPVRydWUpCiAgICByZXR1cm4gaW5mbywgd21hCgoKZGVmIG1ldGFfcmlmZl9p
:::bmZvKGluZm8pOgogICAgIiIidjIuNzogYXJndW1lbnRvcyAtbWV0YWRhdGEgcGFy
:::YSBsb3MgdGFncyBSSUZGIElORk8gZGVsIEFWSS4KCiAgICBGRm1wZWcgbG9zIG1h
:::cGVhIGEgSU5BTSAodGl0dWxvKSwgSUFSVCAoYXJ0aXN0YSksIElQUkQgKGFsYnVt
:::KSwKICAgIElDUkQgKGZlY2hhKSBlIElDTVQgKGNvbWVudGFyaW8pIGRlbnRybyBk
:::ZWwgY2h1bmsgTElTVC9JTkZPIGRlbAogICAgUklGRiwgcXVlIGVzIGRvbmRlIGxv
:::cyByZXByb2R1Y3RvcmVzIGJ1c2NhbiBsb3MgZGF0b3MgZGUgdW4gQVZJLiIiIgog
:::ICAgdGl0dWxvID0gc3RyKGluZm8uZ2V0KCd0cmFjaycpIG9yIGluZm8uZ2V0KCd0
:::aXRsZScpIG9yICcnKS5zdHJpcCgpCiAgICBhcnRpc3RhID0gX2FydGlzdGFfbGlt
:::cGlvKGluZm8pCiAgICBhbGJ1bSA9IF9hbGJ1bV9kZShpbmZvKQogICAgZmVjaGEg
:::PSBzdHIoaW5mby5nZXQoJ3JlbGVhc2VfeWVhcicpIG9yICcnKQogICAgaWYgbm90
:::IGZlY2hhOgogICAgICAgIGZlY2hhID0gc3RyKGluZm8uZ2V0KCd1cGxvYWRfZGF0
:::ZScpIG9yICcnKVs6NF0KICAgIHVybCA9IHN0cihpbmZvLmdldCgnd2VicGFnZV91
:::cmwnKSBvciAnJykuc3RyaXAoKQogICAgbWV0YSA9IFtdCiAgICBpZiB0aXR1bG86
:::CiAgICAgICAgbWV0YSArPSBbJy1tZXRhZGF0YScsICd0aXRsZT0nICsgdGl0dWxv
:::XQogICAgaWYgYXJ0aXN0YToKICAgICAgICBtZXRhICs9IFsnLW1ldGFkYXRhJywg
:::J2FydGlzdD0nICsgYXJ0aXN0YV0KICAgIGlmIGFsYnVtOgogICAgICAgIG1ldGEg
:::Kz0gWyctbWV0YWRhdGEnLCAnYWxidW09JyArIGFsYnVtXQogICAgaWYgZmVjaGE6
:::CiAgICAgICAgbWV0YSArPSBbJy1tZXRhZGF0YScsICdkYXRlPScgKyBmZWNoYV0K
:::ICAgIGlmIHVybDoKICAgICAgICBtZXRhICs9IFsnLW1ldGFkYXRhJywgJ2NvbW1l
:::bnQ9JyArIHVybF0KICAgIHJldHVybiBtZXRhCgoKIyBQYXLDoW1ldHJvcyBvZmlj
:::aWFsZXMgZGVsIHJlcG8gZmRkNHMvcG9ydGFibGVfbXAzX3BsYXllcl92aWRlb19j
:::b252ZXJ0ZXJfdG9vbHMKIyAodmlkZW8yc2hlbmp1MTguc2gpOiBNSlBFRyAxNiBm
:::cHMgKyBQQ00gMjIwNTAgSHosIHJvdGFkb3MgcGFyYSBsYSBwYW50YWxsYQojIHZl
:::cnRpY2FsIGRlIDEyOHgxNjAgZGVsIHJlcHJvZHVjdG9yIHNoZWlqdSBkZSAxLjgg
:::cHVsZ2FkYXMuClZGX1NIRUlKVSA9ICdzY2FsZT0tMjoxMjgsIGNyb3A9MTYwOjEy
:::OCwgdHJhbnNwb3NlPTIsIHZmbGlwJwojIFZhcmlhbnRlIGEgcHJ1ZWJhIGRlIGJh
:::bGFzIHBhcmEgdmlkZW9zIGN1YWRyYWRvcy92ZXJ0aWNhbGVzIChTaG9ydHMpLAoj
:::IGRvbmRlIGVsIHJlY29ydGUgMTYwOjEyOCBvcmlnaW5hbCBzZXLDrWEgaW1wb3Np
:::YmxlOgpWRl9TRUdVUk8gPSAoJ3NjYWxlPTE2MDoxMjg6Zm9yY2Vfb3JpZ2luYWxf
:::YXNwZWN0X3JhdGlvPWRlY3JlYXNlLCcKICAgICAgICAgICAgICdwYWQ9MTYwOjEy
:::ODoob3ctaXcpLzI6KG9oLWloKS8yLHRyYW5zcG9zZT0yLHZmbGlwJykKCgpkZWYg
:::ZGVzY2FyZ2FyX2F2aSh1cmwsIGRlc3Rpbm8sIGNvbGEpOgogICAgIiIiVmlkZW8g
:::QVZJIHBhcmEgZWwgcmVwcm9kdWN0b3Igc2hlaWp1IDEuOCIgMTI4eDE2MC4iIiIK
:::ICAgIGRlZiBsb2cobSwgdD0naW5mbycpOgogICAgICAgIGNvbGEucHV0KCgnbG9n
:::JywgbSwgdCkpCgogICAgY2FycGV0YSA9IGRlc3Rpbm8gICAgICAgICAgIyB2Mi4z
:::OiBzaW4gc3ViY2FycGV0YXMgcG9yIGZvcm1hdG8KICAgIHRtcCA9IGNhcnBldGEg
:::LyAnX3RtcCcKICAgIHNodXRpbC5ybXRyZWUodG1wLCBpZ25vcmVfZXJyb3JzPVRy
:::dWUpCiAgICB0bXAubWtkaXIocGFyZW50cz1UcnVlLCBleGlzdF9vaz1UcnVlKQog
:::ICAgbyA9IG9wdHNfYmFzZSh0bXAsIGNvbGEpCiAgICAjIFBhcmEgdW5hIHBhbnRh
:::bGxhIGRlIDEyOHgxNjAgYmFzdGEgY29uIDQ4MHA6IGFob3JyYSBtdWNoYSBkZXNj
:::YXJnYS4KICAgIG9bJ2Zvcm1hdCddID0gKCdiZXN0W2hlaWdodDw9NDgwXVtleHQ9
:::bXA0XS9iZXN0W2hlaWdodDw9NDgwXS8nCiAgICAgICAgICAgICAgICAgICAnYnYq
:::W2hlaWdodDw9NDgwXStiYS9iJykKICAgIG9bJ21lcmdlX291dHB1dF9mb3JtYXQn
:::XSA9ICdtcDQnCiAgICB3aXRoIFlUX0RMUC5Zb3V0dWJlREwobykgYXMgeWRsOgog
:::ICAgICAgIGluZm8gPSB5ZGwuZXh0cmFjdF9pbmZvKHVybCwgZG93bmxvYWQ9VHJ1
:::ZSkKICAgIG9yaWdlbiA9IGFyY2hpdm9fZmluYWwoaW5mbywgdG1wLCAnbXA0JykK
:::ICAgIGlmIG5vdCBvcmlnZW46CiAgICAgICAgb3JpZ2VuID0gKGFyY2hpdm9fZmlu
:::YWwoaW5mbywgdG1wLCAnbWt2JykKICAgICAgICAgICAgICAgICAgb3IgYXJjaGl2
:::b19maW5hbChpbmZvLCB0bXAsICd3ZWJtJykpCiAgICBpZiBub3Qgb3JpZ2VuOgog
:::ICAgICAgIHJhaXNlIFJ1bnRpbWVFcnJvcignTm8gc2UgZW5jb250csOzIGVsIHZp
:::ZGVvIGRlc2NhcmdhZG8uJykKICAgIGF2aSA9IGNhcnBldGEgLyAobGltcGlhcl9u
:::b21icmUoaW5mby5nZXQoJ3RpdGxlJykgb3IgJ3ZpZGVvJykgKyAnLmF2aScpCiAg
:::ICAjIHYyLjc6IGV0aXF1ZXRhcyBSSUZGIElORk8gZGVudHJvIGRlbCBBVkkgKHZl
:::ciBtZXRhX3JpZmZfaW5mbykKICAgICMgcGFyYSBxdWUgZWwgdmlkZW8gdGFtYmll
:::biBtdWVzdHJlIHRpdHVsbyB5IGFydGlzdGEgZG9uZGUgZWwKICAgICMgcmVwcm9k
:::dWN0b3Igc2VwYSBsZWVybGFzLgogICAgbWV0YSA9IG1ldGFfcmlmZl9pbmZvKGlu
:::Zm8pCiAgICBiYXNlID0gW3N0cihGRk1QRUcpLCAnLXknLCAnLWknLCBzdHIob3Jp
:::Z2VuKSwgJy1yJywgJzE2JywKICAgICAgICAgICAgJy1hY29kZWMnLCAncGNtX3Mx
:::NmxlJywgJy1hYycsICcyJywgJy1hcicsICcyMjA1MCcsCiAgICAgICAgICAgICct
:::cGl4X2ZtdCcsICd5dXZqNDIwcCcsICctYzp2JywgJ21qcGVnJywgJy1xOnYnLCAn
:::MiddICsgbWV0YQogICAgb2sgPSBjb252ZXJ0aXJfZmZtcGVnKGJhc2UgKyBbJy12
:::ZicsIFZGX1NIRUlKVSwgc3RyKGF2aSldLAogICAgICAgICAgICAgICAgICAgICAg
:::ICAgICdDb252aXJ0aWVuZG8gYSBBVkkgMTI4eDE2MCAoc2hlaWp1IDEuOCIpJywg
:::Y29sYSkKICAgIGlmIG5vdCBvazoKICAgICAgICBsb2coJ1ZpZGVvIGNvbiBwcm9w
:::b3JjacOzbiBubyBlc3TDoW5kYXI7ICcKICAgICAgICAgICAgJ3JlaW50ZW50YW5k
:::byBlbiBtb2RvIGNvbXBhdGlibGUuLi4nLCAnYXZpc28nKQogICAgICAgIG9rID0g
:::Y29udmVydGlyX2ZmbXBlZyhiYXNlICsgWyctdmYnLCBWRl9TRUdVUk8sIHN0cihh
:::dmkpXSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ1JlY29udmlydGll
:::bmRvIGEgQVZJIDEyOHgxNjAnLCBjb2xhKQogICAgaWYgbm90IG9rOgogICAgICAg
:::IHJhaXNlIFJ1bnRpbWVFcnJvcignRkZtcGVnIG5vIHB1ZG8gY3JlYXIgZWwgYXJj
:::aGl2byBBVkkuJykKICAgIHNodXRpbC5ybXRyZWUodG1wLCBpZ25vcmVfZXJyb3Jz
:::PVRydWUpCiAgICByZXR1cm4gaW5mbywgYXZpCgoKIyAtLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::IGVzdGltYWNpw7NuCktCUFNfRVNUSU1BRE9TID0gewogICAgJ0FBQyc6IDEyOCwg
:::ICAgICMgdGVjaG8gZGVsIGZvcm1hdG8KICAgICdXTUEnOiAxMjgsCiAgICAnV0FW
:::JzogMTQxMSwgICAgIyBQQ00gNDQuMSBrSHogwrcgMTYgYml0IMK3IGVzdMOpcmVv
:::CiAgICAnRkxBQyc6IDk1MCwgICAgIyB0w61waWNvIGRlIG3DunNpY2EgcHJvY2Vk
:::ZW50ZSBkZSBZb3VUdWJlCiAgICAnQVZJJzogMTQ5MCwgICAgIyB+Nzg0IGticHMg
:::TUpQRUcgMTZmcHMgKyA3MDYga2JwcyBQQ00gMjIwNTAgZXN0w6lyZW8KfQoKCmRl
:::ZiBlc3RpbWFyX2J5dGVzKGR1cmFjaW9uX3MsIGZvcm1hdG8sIGNhbGlkYWQsIGVt
:::YmViZXIpOgogICAgIiIiRXN0aW1hIGVsIHRhbWHDsW8gZmluYWwgZW4gYnl0ZXMg
:::KGPDoWxjdWxvIHB1cm8sIHRlc3RlYWJsZSkuIiIiCiAgICBpZiBmb3JtYXRvIGlu
:::ICgnTVAzJywgJ0FBQycsICdXTUEnKToKICAgICAgICBrYnBzID0gaW50KHJlLnN1
:::YihyJ1teMC05XScsICcnLCBzdHIoY2FsaWRhZCkpIG9yIDApCiAgICAgICAgaWYg
:::bm90IGticHM6CiAgICAgICAgICAgIGticHMgPSBLQlBTX0VTVElNQURPUy5nZXQo
:::Zm9ybWF0bywgMTI4KQogICAgZWxzZToKICAgICAgICBrYnBzID0gS0JQU19FU1RJ
:::TUFET1MuZ2V0KGZvcm1hdG8sIDEyOCkKICAgIGV4dHJhID0gMTIwXzAwMCBpZiAo
:::ZW1iZWJlciBhbmQgZm9ybWF0byBpbiAoJ0FBQycsICdNUDMnLCAnRkxBQycsCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICdX
:::QVYnKSkgZWxzZSAwCiAgICByZXR1cm4gZHVyYWNpb25fcyAqIGticHMgKiAxMDAw
:::IC8gOCArIGV4dHJhCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIGNhbGlkYWQKZGVmIGNs
:::YXNlX2NhbGlkYWQoZXh0LCBrYnBzKToKICAgICIiIkNsYXNpZmljYSB1biBhcmNo
:::aXZvLiBEZXZ1ZWx2ZSAodGV4dG8sIG5pdmVsKSBjb24gbml2ZWwgMD1vayAxPW1l
:::ZGlhIDI9YmFqYS4iIiIKICAgIGlmIGV4dCA9PSAnLm1wMyc6CiAgICAgICAgaWYg
:::a2JwcyA+PSAzMTU6CiAgICAgICAgICAgIHJldHVybiAnMzIwIGticHMnLCAwCiAg
:::ICAgICAgaWYga2JwcyA+PSAyNTA6CiAgICAgICAgICAgIHJldHVybiAnMjU2IGti
:::cHMnLCAwCiAgICAgICAgaWYga2JwcyA+PSAxODU6CiAgICAgICAgICAgIHJldHVy
:::biAnMTkyIGticHMnLCAwCiAgICAgICAgaWYga2JwcyA+PSAxMjA6CiAgICAgICAg
:::ICAgIHJldHVybiAnMTI4IGticHMnLCAxCiAgICAgICAgcmV0dXJuIGYne2ticHN9
:::IGticHMgKGJhamEpJywgMgogICAgaWYgZXh0ID09ICcubTRhJzoKICAgICAgICBp
:::ZiBrYnBzID49IDExNToKICAgICAgICAgICAgcmV0dXJuICdFeGNlbGVudGUgKEFB
:::QyDiiaQxMjhrKScsIDAKICAgICAgICBpZiBrYnBzID49IDgyOgogICAgICAgICAg
:::ICByZXR1cm4gJzk2IGticHMnLCAxCiAgICAgICAgcmV0dXJuIGYne2ticHN9IGti
:::cHMgKGJhamEpJywgMgogICAgaWYgZXh0ID09ICcud21hJzoKICAgICAgICBpZiBr
:::YnBzID49IDExNToKICAgICAgICAgICAgcmV0dXJuICcxMjgga2JwcycsIDAKICAg
:::ICAgICBpZiBrYnBzID49IDg4OgogICAgICAgICAgICByZXR1cm4gJzk2IGticHMn
:::LCAxCiAgICAgICAgcmV0dXJuIGYne2ticHN9IGticHMgKGJhamEpJywgMgogICAg
:::aWYgZXh0IGluICgnLmZsYWMnLCAnLndhdicpOgogICAgICAgIHJldHVybiAnU2lu
:::IHDDqXJkaWRhJywgMAogICAgaWYgZXh0ID09ICcuYXZpJzoKICAgICAgICBpZiBr
:::YnBzID49IDEyMDA6CiAgICAgICAgICAgIHJldHVybiBmJ3trYnBzfSBrYnBzIChN
:::SlBFRytQQ00gMTI4eDE2MCknLCAwCiAgICAgICAgcmV0dXJuIGYne2ticHN9IGti
:::cHMgKGFsZ28gYmFqbyknLCAxCiAgICByZXR1cm4gZid7a2Jwc30ga2JwcycsIDEK
:::CgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0gdGVtYXMKVEVNQVMgPSB7CiAgICAnT3NjdXJv
:::JzogZGljdCgKICAgICAgICBmb25kbz0nIzFlMWYyMicsIGNhbXBvPScjMmEyZDMx
:::JywgY2FtcG9fYm9yZGU9JyMzYTNlNDQnLAogICAgICAgIHRleHRvPScjZDhkYWRj
:::JywgdGV4dG8yPScjOWE5ZmE0JywKICAgICAgICBib3Rvbj0nIzNhM2Q0MicsIGJv
:::dG9uX2FjdD0nIzRhNGU1NScsIGJvdG9uX3R4dD0nI2U4ZWFlYycsCiAgICAgICAg
:::bG9nPScjMTQxNTE4JywgbG9nX3R4dD0nI2NmZDNkNycsIGFjZW50bz0nIzRmOWNm
:::OScsCiAgICAgICAgb2s9JyM3ZWM5N2YnLCBlcnJvcj0nI2U1NzM3MycsIGF2aXNv
:::PScjZDhiNjRhJywgdHJvdWdoPScjMjYyODJjJywKICAgICAgICBwbGFjZWhvbGRl
:::cj0nIzc3N2M4MicpLAogICAgJ0NsYXJvJzogZGljdCgKICAgICAgICBmb25kbz0n
:::I2YyZjNmNScsIGNhbXBvPScjZmZmZmZmJywgY2FtcG9fYm9yZGU9JyNjNGM4Y2Qn
:::LAogICAgICAgIHRleHRvPScjMjQyNzJhJywgdGV4dG8yPScjNmE3MDc2JywKICAg
:::ICAgICBib3Rvbj0nI2UzZTVlOCcsIGJvdG9uX2FjdD0nI2QyZDVkYScsIGJvdG9u
:::X3R4dD0nIzI0MjcyYScsCiAgICAgICAgbG9nPScjZmZmZmZmJywgbG9nX3R4dD0n
:::IzJiMmUzMScsIGFjZW50bz0nIzFhNjZkNicsCiAgICAgICAgb2s9JyMxZTdlMzQn
:::LCBlcnJvcj0nI2M2MjgyOCcsIGF2aXNvPScjOWE2NzAwJywgdHJvdWdoPScjZGZl
:::MWU0JywKICAgICAgICBwbGFjZWhvbGRlcj0nIzlhYTBhNicpLAp9CgpQTEFDRUhP
:::TERFUl9VUkwgPSAnaHR0cHM6Ly93d3cueW91dHViZS5jb20vd2F0Y2g/dj0uLi4n
:::CgpGVUVOVEVfVUkgPSAoJ1NlZ29lIFVJJywgOSkKRlVFTlRFX0JUTiA9ICgnU2Vn
:::b2UgVUknLCAxMCkKRlVFTlRFX0JUTl9HID0gKCdTZWdvZSBVSScsIDExKQpGVUVO
:::VEVfTE9HID0gKCdDb25zb2xhcycsIDEwKQoKCmlmIFRLX09LOgoKICAgIGNsYXNz
:::IEFwcCh0ay5Uayk6CiAgICAgICAgIiIiVmVudGFuYSBwcmluY2lwYWwgKGRpc2XD
:::sW8gZXNwZWpvIGRlbCBtb2NrdXA6IGdydXBvcyBvc2N1cm9zKS4iIiIKCiAgICAg
:::ICAgIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0gY29uc3RydWNjacOzbgogICAgICAgIGRlZiBfX2luaXRfXyhzZWxmKToK
:::ICAgICAgICAgICAgaWYgZ2V0YXR0cihzeXMsICdmcm96ZW4nLCBGYWxzZSk6CiAg
:::ICAgICAgICAgICAgICBwYXNzCiAgICAgICAgICAgIHN1cGVyKCkuX19pbml0X18o
:::KQogICAgICAgICAgICBzZWxmLnRpdGxlKCdNdXNpa0FMQU4nKQogICAgICAgICAg
:::ICBzZWxmLmdlb21ldHJ5KCc4NjB4ODQwJykKICAgICAgICAgICAgc2VsZi5taW5z
:::aXplKDcwMCwgNjYwKQogICAgICAgICAgICBzZWxmLmNvbGEgPSBxdWV1ZS5RdWV1
:::ZSgpCiAgICAgICAgICAgIHNlbGYuX29jdXBhZG8gPSBGYWxzZQogICAgICAgICAg
:::ICBzZWxmLl9lbl9wbGFjZWhvbGRlciA9IFRydWUKICAgICAgICAgICAgc2VsZi5f
:::dGVtYV9hY3R1YWwgPSBBSlVTVEVTLmdldCgndGVtYScsICdPc2N1cm8nKQogICAg
:::ICAgICAgICBpZiBzZWxmLl90ZW1hX2FjdHVhbCBub3QgaW4gVEVNQVM6CiAgICAg
:::ICAgICAgICAgICBzZWxmLl90ZW1hX2FjdHVhbCA9ICdPc2N1cm8nCgogICAgICAg
:::ICAgICBzZWxmLl9lc3RpbG8gPSB0dGsuU3R5bGUoc2VsZikKICAgICAgICAgICAg
:::dHJ5OgogICAgICAgICAgICAgICAgc2VsZi5fZXN0aWxvLnRoZW1lX3VzZSgnY2xh
:::bScpCiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgICAg
:::ICBwYXNzCgogICAgICAgICAgICBzZWxmLl9jb25zdHJ1aXIoKQogICAgICAgICAg
:::ICBzZWxmLl9hcGxpY2FyX3RlbWEoKQogICAgICAgICAgICBzZWxmLl9jb25lY3Rh
:::cl9ldmVudG9zKCkKICAgICAgICAgICAgUkVHSVNUUk8ubG9nID0gbGFtYmRhIG0s
:::IHQ9J2F2aXNvJzogc2VsZi5jb2xhLnB1dCgoJ2xvZycsIG0sIHQpKQogICAgICAg
:::ICAgICBzZWxmLmFmdGVyKDgwLCBzZWxmLl9ib21iZWFyX2NvbGEpCiAgICAgICAg
:::ICAgIHNlbGYuYWZ0ZXIoMTUwLCBzZWxmLl9hcnJhbnF1ZSkKCiAgICAgICAgZGVm
:::IF9jb25zdHJ1aXIoc2VsZik6CiAgICAgICAgICAgIHNlbGYuX3dnID0ge30gICAg
:::ICAgICAjIHJlZmVyZW5jaWFzIHBhcmEgZWwgdGVtYQogICAgICAgICAgICBzZWxm
:::Ll9idG5zID0gW10gICAgICAgIyBib3RvbmVzIHBsYW5vcyAocGFyYSBob3Zlci90
:::ZW1hKQogICAgICAgICAgICBtYXJjbyA9IHRrLkZyYW1lKHNlbGYpCiAgICAgICAg
:::ICAgIG1hcmNvLnBhY2soZmlsbD0nYm90aCcsIGV4cGFuZD1UcnVlLCBwYWR4PTEw
:::LCBwYWR5PTgpCiAgICAgICAgICAgIHNlbGYuX3dnWydtYXJjbyddID0gbWFyY28K
:::ICAgICAgICAgICAgbWFyY28uY29sdW1uY29uZmlndXJlKDAsIHdlaWdodD0xKQoK
:::ICAgICAgICAgICAgIyAtLS0gZmlsYSBUZW1hIC0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICAgICAgICAgICBmMCA9IHRr
:::LkZyYW1lKG1hcmNvKQogICAgICAgICAgICBmMC5ncmlkKHJvdz0wLCBjb2x1bW49
:::MCwgc3RpY2t5PSdldycsIHBhZHk9KDAsIDYpKQogICAgICAgICAgICBzZWxmLl93
:::Z1snZjAnXSA9IGYwCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfdGVtYSddID0g
:::dGsuTGFiZWwoZjAsIHRleHQ9J1RlbWE6JywgZm9udD1GVUVOVEVfVUkpCiAgICAg
:::ICAgICAgIHNlbGYuX3dnWydsYmxfdGVtYSddLnBhY2soc2lkZT0nbGVmdCcpCiAg
:::ICAgICAgICAgIHNlbGYuY21iX3RlbWEgPSB0dGsuQ29tYm9ib3goCiAgICAgICAg
:::ICAgICAgICBmMCwgdmFsdWVzPWxpc3QoVEVNQVMpLCBzdGF0ZT0ncmVhZG9ubHkn
:::LCB3aWR0aD05LAogICAgICAgICAgICAgICAgZm9udD1GVUVOVEVfVUksIHN0eWxl
:::PSdneC5UQ29tYm9ib3gnKQogICAgICAgICAgICBzZWxmLmNtYl90ZW1hLnNldChz
:::ZWxmLl90ZW1hX2FjdHVhbCkKICAgICAgICAgICAgc2VsZi5jbWJfdGVtYS5wYWNr
:::KHNpZGU9J2xlZnQnLCBwYWR4PSg4LCAwKSwgaXBhZHk9MikKCiAgICAgICAgICAg
:::ICMgLS0tIGdydXBvOiBVUkwgZGUgWW91VHViZSAtLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0KICAgICAgICAgICAgZ3UgPSB0ay5MYWJlbEZyYW1l
:::KG1hcmNvLCB0ZXh0PSdVUkwgZGUgWW91VHViZScsIGZvbnQ9RlVFTlRFX1VJLAog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVsaWVmPSdzb2xpZCcsIGJk
:::PTEpCiAgICAgICAgICAgIGd1LmdyaWQocm93PTEsIGNvbHVtbj0wLCBzdGlja3k9
:::J2V3JywgcGFkeT01KQogICAgICAgICAgICBzZWxmLl93Z1snZ3UnXSA9IGd1CiAg
:::ICAgICAgICAgIGd1LmNvbHVtbmNvbmZpZ3VyZSgwLCB3ZWlnaHQ9MSkKICAgICAg
:::ICAgICAgc2VsZi5lbnRfdXJsID0gdGsuRW50cnkoZ3UsIGZvbnQ9RlVFTlRFX1VJ
:::LCByZWxpZWY9J2ZsYXQnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICBoaWdobGlnaHR0aGlja25lc3M9MSkKICAgICAgICAgICAgc2VsZi5lbnRf
:::dXJsLmdyaWQocm93PTAsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgcGFkeD04LCBwYWR5PTgsIGlwYWR5PTUpCiAg
:::ICAgICAgICAgIHNlbGYuX3BvbmVyX3BsYWNlaG9sZGVyKCkKICAgICAgICAgICAg
:::c2VsZi5idG5feCA9IHNlbGYuX2JvdG9uKGd1LCAnWCcsIHNlbGYuX2xpbXBpYXJf
:::dXJsLCB3aWR0aD0zKQogICAgICAgICAgICBzZWxmLmJ0bl94LmdyaWQocm93PTAs
:::IGNvbHVtbj0xLCBzdGlja3k9J2UnLCBwYWR4PSgwLCA4KSwgaXBhZHk9MykKCiAg
:::ICAgICAgICAgICMgLS0tIGdydXBvOiBGb3JtYXRvIHkgY2FsaWRhZCAtLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KICAgICAgICAgICAgZ2YgPSB0ay5M
:::YWJlbEZyYW1lKG1hcmNvLCB0ZXh0PSdGb3JtYXRvIHkgY2FsaWRhZCcsIGZvbnQ9
:::RlVFTlRFX1VJLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgcmVsaWVm
:::PSdzb2xpZCcsIGJkPTEpCiAgICAgICAgICAgIGdmLmdyaWQocm93PTIsIGNvbHVt
:::bj0wLCBzdGlja3k9J2V3JywgcGFkeT01KQogICAgICAgICAgICBzZWxmLl93Z1sn
:::Z2YnXSA9IGdmCiAgICAgICAgICAgIGdmLmNvbHVtbmNvbmZpZ3VyZSgxLCB3ZWln
:::aHQ9MSkKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF9mbXQnXSA9IHRrLkxhYmVs
:::KGdmLCB0ZXh0PSdGb3JtYXRvOicsIGZvbnQ9RlVFTlRFX1VJKQogICAgICAgICAg
:::ICBzZWxmLl93Z1snbGJsX2ZtdCddLmdyaWQocm93PTAsIGNvbHVtbj0wLCBzdGlj
:::a3k9J3cnLCBwYWR4PTgsIHBhZHk9NSkKICAgICAgICAgICAgc2VsZi5jbWJfZm9y
:::bWF0byA9IHR0ay5Db21ib2JveCgKICAgICAgICAgICAgICAgIGdmLCB2YWx1ZXM9
:::W2ZbJ3RleHRvJ10gZm9yIGYgaW4gRk9STUFUT1MudmFsdWVzKCldLAogICAgICAg
:::ICAgICAgICAgc3RhdGU9J3JlYWRvbmx5JywgZm9udD1GVUVOVEVfVUksIHN0eWxl
:::PSdneC5UQ29tYm9ib3gnKQogICAgICAgICAgICBzZWxmLmNtYl9mb3JtYXRvLmdy
:::aWQocm93PTAsIGNvbHVtbj0xLCBzdGlja3k9J2V3JywKICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgIHBhZHg9OCwgcGFkeT01LCBpcGFkeT0yKQogICAg
:::ICAgICAgICBzZWxmLl93Z1snbGJsX2NhbCddID0gdGsuTGFiZWwoZ2YsIHRleHQ9
:::J0NhbGlkYWQ6JywgZm9udD1GVUVOVEVfVUkpCiAgICAgICAgICAgIHNlbGYuX3dn
:::WydsYmxfY2FsJ10uZ3JpZChyb3c9MSwgY29sdW1uPTAsIHN0aWNreT0ndycsIHBh
:::ZHg9OCwgcGFkeT01KQogICAgICAgICAgICBzZWxmLmNtYl9jYWxpZGFkID0gdHRr
:::LkNvbWJvYm94KAogICAgICAgICAgICAgICAgZ2YsIHN0YXRlPSdyZWFkb25seScs
:::IGZvbnQ9RlVFTlRFX1VJLCBzdHlsZT0nZ3guVENvbWJvYm94JykKICAgICAgICAg
:::ICAgc2VsZi5jbWJfY2FsaWRhZC5ncmlkKHJvdz0xLCBjb2x1bW49MSwgc3RpY2t5
:::PSdldycsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4PTgs
:::IHBhZHk9NSwgaXBhZHk9MikKICAgICAgICAgICAgc2VsZi5fd2dbJ2xibF9jYXIn
:::XSA9IHRrLkxhYmVsKGdmLCB0ZXh0PSdDYXJwZXRhOicsIGZvbnQ9RlVFTlRFX1VJ
:::KQogICAgICAgICAgICBzZWxmLl93Z1snbGJsX2NhciddLmdyaWQocm93PTIsIGNv
:::bHVtbj0wLCBzdGlja3k9J3cnLCBwYWR4PTgsIHBhZHk9NSkKICAgICAgICAgICAg
:::ZmMgPSB0ay5GcmFtZShnZikKICAgICAgICAgICAgZmMuZ3JpZChyb3c9MiwgY29s
:::dW1uPTEsIHN0aWNreT0nZXcnLCBwYWR4PTgsIHBhZHk9NSkKICAgICAgICAgICAg
:::c2VsZi5fd2dbJ2ZjJ10gPSBmYwogICAgICAgICAgICBmYy5jb2x1bW5jb25maWd1
:::cmUoMCwgd2VpZ2h0PTEpCiAgICAgICAgICAgIHNlbGYuZW50X2NhcnBldGEgPSB0
:::ay5FbnRyeShmYywgZm9udD1GVUVOVEVfVUksIHJlbGllZj0nZmxhdCcsCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBoaWdobGlnaHR0aGlj
:::a25lc3M9MSkKICAgICAgICAgICAgc2VsZi5lbnRfY2FycGV0YS5ncmlkKHJvdz0w
:::LCBjb2x1bW49MCwgc3RpY2t5PSdldycsIGlwYWR5PTQpCiAgICAgICAgICAgIHNl
:::bGYuZW50X2NhcnBldGEuaW5zZXJ0KDAsIEFKVVNURVNbJ2Rlc3Rpbm8nXSkKICAg
:::ICAgICAgICAgc2VsZi5idG5fY2FtYmlhciA9IHNlbGYuX2JvdG9uKGZjLCAnQ2Ft
:::Ymlhci4uLicsIHNlbGYuX2NhbWJpYXJfY2FycGV0YSkKICAgICAgICAgICAgc2Vs
:::Zi5idG5fY2FtYmlhci5ncmlkKHJvdz0wLCBjb2x1bW49MSwgcGFkeD0oOCwgMCks
:::IGlwYWR5PTMpCiAgICAgICAgICAgIHNlbGYuYnRuX2FicmlyID0gc2VsZi5fYm90
:::b24oZmMsICdBYnJpcicsIHNlbGYuX2FicmlyX2Rlc3Rpbm8sIHdpZHRoPTUpCiAg
:::ICAgICAgICAgIHNlbGYuYnRuX2FicmlyLmdyaWQocm93PTAsIGNvbHVtbj0yLCBw
:::YWR4PSg2LCAwKSwgaXBhZHk9MykKCiAgICAgICAgICAgIHNlbGYudmFyX2VtYmVi
:::ZXIgPSB0ay5Cb29sZWFuVmFyKHZhbHVlPWJvb2woQUpVU1RFUy5nZXQoJ2VtYmVi
:::ZXInLCBUcnVlKSkpCiAgICAgICAgICAgIHNlbGYuY2hrX2VtYmViZXIgPSB0ay5D
:::aGVja2J1dHRvbigKICAgICAgICAgICAgICAgIGdmLCB0ZXh0PSdFbWJlYmVyIGNh
:::csOhdHVsYSwgYXJ0aXN0YSB5IMOhbGJ1bScsCiAgICAgICAgICAgICAgICB2YXJp
:::YWJsZT1zZWxmLnZhcl9lbWJlYmVyLCBmb250PUZVRU5URV9VSSwgYW5jaG9yPSd3
:::JywKICAgICAgICAgICAgICAgIHJlbGllZj0nZmxhdCcsIGhpZ2hsaWdodHRoaWNr
:::bmVzcz0wLCBiZD0wKQogICAgICAgICAgICBzZWxmLmNoa19lbWJlYmVyLmdyaWQo
:::cm93PTMsIGNvbHVtbj0wLCBjb2x1bW5zcGFuPTIsCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICBzdGlja3k9J2V3JywgcGFkeD04LCBwYWR5PSgyLCA2
:::KSkKICAgICAgICAgICAgIyB2Mi45OiB2w61hIGFudGktYmxvcXVlbyAoY29va2ll
:::cyBkZWwgbmF2ZWdhZG9yIHNpIFlvdVR1YmUKICAgICAgICAgICAgIyBwaWRlIHZl
:::cmlmaWNhY2nDs24pCiAgICAgICAgICAgIHNlbGYuX3dnWydsYmxfY29va2llcydd
:::ID0gdGsuTGFiZWwoCiAgICAgICAgICAgICAgICBnZiwgdGV4dD0nU2kgWW91VHVi
:::ZSBibG9xdWVhOicsIGZvbnQ9RlVFTlRFX1VJKQogICAgICAgICAgICBzZWxmLl93
:::Z1snbGJsX2Nvb2tpZXMnXS5ncmlkKHJvdz00LCBjb2x1bW49MCwgc3RpY2t5PSd3
:::JywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4
:::PTgsIHBhZHk9NSkKICAgICAgICAgICAgc2VsZi5jbWJfY29va2llcyA9IHR0ay5D
:::b21ib2JveCgKICAgICAgICAgICAgICAgIGdmLCB2YWx1ZXM9KFsnQXV0b23DoXRp
:::Y28gKHJlY29tZW5kYWRvKSddCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAr
:::IFsnVXNhciBjb29raWVzIGRlICcgKyBuLmNhcGl0YWxpemUoKQogICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgZm9yIG4gaW4gTkFWRUdBRE9SRVNfQ09PS0lF
:::U10pLAogICAgICAgICAgICAgICAgc3RhdGU9J3JlYWRvbmx5JywgZm9udD1GVUVO
:::VEVfVUksIHN0eWxlPSdneC5UQ29tYm9ib3gnKQogICAgICAgICAgICBzZWxmLmNt
:::Yl9jb29raWVzLmdyaWQocm93PTQsIGNvbHVtbj0xLCBzdGlja3k9J2V3JywKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHBhZHg9OCwgcGFkeT01LCBp
:::cGFkeT0yKQogICAgICAgICAgICBzZWxmLmNtYl9jb29raWVzLnNldCgnQXV0b23D
:::oXRpY28gKHJlY29tZW5kYWRvKScpCgogICAgICAgICAgICAjIC0tLSBncnVwbzog
:::ZXN0aW1hY2nDs24gLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLQogICAgICAgICAgICBnZSA9IHRrLkxhYmVsRnJhbWUobWFyY28sIHRleHQ9
:::J0VzdGltYWNpw7NuJywgZm9udD1GVUVOVEVfVUksCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICByZWxpZWY9J3NvbGlkJywgYmQ9MSkKICAgICAgICAgICAg
:::Z2UuZ3JpZChyb3c9MywgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PTUpCiAg
:::ICAgICAgICAgIHNlbGYuX3dnWydnZSddID0gZ2UKICAgICAgICAgICAgZ2UuY29s
:::dW1uY29uZmlndXJlKDAsIHdlaWdodD0xKQogICAgICAgICAgICBzZWxmLmxibF9l
:::c3RpbWFjaW9uID0gdGsuTGFiZWwoCiAgICAgICAgICAgICAgICBnZSwgdGV4dD0n
:::SW50cm9kdWNlIHVuYSBVUkwgeSBwdWxzYSBFc3RpbWFyLicsCiAgICAgICAgICAg
:::ICAgICBmb250PUZVRU5URV9VSSwgYW5jaG9yPSd3JykKICAgICAgICAgICAgc2Vs
:::Zi5sYmxfZXN0aW1hY2lvbi5ncmlkKHJvdz0wLCBjb2x1bW49MCwgc3RpY2t5PSdl
:::dycsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4PTgs
:::IHBhZHk9NikKICAgICAgICAgICAgc2VsZi5idG5fZXN0aW1hciA9IHNlbGYuX2Jv
:::dG9uKGdlLCAnRXN0aW1hciB0YW1hbm8nLAogICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgc2VsZi5fYWNjaW9uX2VzdGltYXIpCiAgICAg
:::ICAgICAgIHNlbGYuYnRuX2VzdGltYXIuZ3JpZChyb3c9MCwgY29sdW1uPTEsIHN0
:::aWNreT0nZScsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBwYWR4
:::PTgsIGlwYWR5PTMpCgogICAgICAgICAgICAjIC0tLSBib3RvbmVzIGdyYW5kZXMg
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAg
:::ICAgICAgIHNlbGYuYnRuX2Rlc2NhcmdhciA9IHNlbGYuX2JvdG9uKG1hcmNvLCAn
:::RGVzY2FyZ2FyIHkgY29udmVydGlyJywKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgc2VsZi5fYWNjaW9uX2Rlc2NhcmdhciwKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgZnVlbnRl
:::PUZVRU5URV9CVE5fRywgYWx0bz0yKQogICAgICAgICAgICBzZWxmLmJ0bl9kZXNj
:::YXJnYXIuZ3JpZChyb3c9NCwgY29sdW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PSg3
:::LCA0KSkKICAgICAgICAgICAgc2VsZi5idG5fY29tcHJvYmFyID0gc2VsZi5fYm90
:::b24oCiAgICAgICAgICAgICAgICBtYXJjbywgJ0NvbXByb2JhciBjYWxpZGFkIGRl
:::IGxhIGNhcnBldGEnLAogICAgICAgICAgICAgICAgc2VsZi5fYWNjaW9uX2NvbXBy
:::b2JhciwgZnVlbnRlPUZVRU5URV9CVE4pCiAgICAgICAgICAgIHNlbGYuYnRuX2Nv
:::bXByb2Jhci5ncmlkKHJvdz01LCBjb2x1bW49MCwgc3RpY2t5PSdldycsIHBhZHk9
:::MykKCiAgICAgICAgICAgICMgLS0tIGVzdGFkbyArIGJhcnJhIGRlIHByb2dyZXNv
:::IC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAgIHNl
:::bGYubGJsX2VzdGFkbyA9IHRrLkxhYmVsKG1hcmNvLCB0ZXh0PScnLCBmb250PUZV
:::RU5URV9VSSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::YW5jaG9yPSd3JykKICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmdyaWQocm93
:::PTYsIGNvbHVtbj0wLCBzdGlja3k9J2V3JywgcGFkeT0oNCwgMCkpCiAgICAgICAg
:::ICAgIHNlbGYuYmFycmEgPSB0dGsuUHJvZ3Jlc3NiYXIoCiAgICAgICAgICAgICAg
:::ICBtYXJjbywgbWF4aW11bT0xMDAsIHN0eWxlPSdneC5Ib3Jpem9udGFsLlRQcm9n
:::cmVzc2JhcicpCiAgICAgICAgICAgIHNlbGYuYmFycmEuZ3JpZChyb3c9NywgY29s
:::dW1uPTAsIHN0aWNreT0nZXcnLCBwYWR5PSgyLCA0KSkKCiAgICAgICAgICAgICMg
:::LS0tIHJlZ2lzdHJvIChsb2cpIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tCiAgICAgICAgICAgIHNlbGYudHh0X2xvZyA9IFNjcm9s
:::bGVkVGV4dChtYXJjbywgZm9udD1GVUVOVEVfTE9HLCBoZWlnaHQ9MTIsCiAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICByZWxpZWY9J2ZsYXQn
:::LCBiZD0wLCB3cmFwPSd3b3JkJywKICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgIHN0YXRlPSdkaXNhYmxlZCcpCiAgICAgICAgICAgIHNlbGYu
:::dHh0X2xvZy5ncmlkKHJvdz04LCBjb2x1bW49MCwgc3RpY2t5PSduc2V3JykKICAg
:::ICAgICAgICAgbWFyY28ucm93Y29uZmlndXJlKDgsIHdlaWdodD0xKQogICAgICAg
:::ICAgICBmb3IgdGFnLCBjb25mIGluICgKICAgICAgICAgICAgICAgICAgICAoJ2lu
:::Zm8nLCB7fSksCiAgICAgICAgICAgICAgICAgICAgKCdncmlzJywge30pLAogICAg
:::ICAgICAgICAgICAgICAgICgndGl0dWxvJywge30pLAogICAgICAgICAgICAgICAg
:::ICAgICgnb2snLCB7fSksCiAgICAgICAgICAgICAgICAgICAgKCdhdmlzbycsIHt9
:::KSwKICAgICAgICAgICAgICAgICAgICAoJ2Vycm9yJywge30pKToKICAgICAgICAg
:::ICAgICAgIHNlbGYudHh0X2xvZy50YWdfY29uZmlndXJlKHRhZywgY29uZikKCiAg
:::ICAgICAgICAgICMgc2luY3Jvbml6YXIgdmFsb3JlcyBndWFyZGFkb3MKICAgICAg
:::ICAgICAgZm10ID0gQUpVU1RFUy5nZXQoJ2Zvcm1hdG8nLCAnQUFDJykKICAgICAg
:::ICAgICAgaWYgZm10IG5vdCBpbiBGT1JNQVRPUzoKICAgICAgICAgICAgICAgIGZt
:::dCA9ICdBQUMnCiAgICAgICAgICAgIHNlbGYuY21iX2Zvcm1hdG8uc2V0KEZPUk1B
:::VE9TW2ZtdF1bJ3RleHRvJ10pCiAgICAgICAgICAgIHNlbGYuX3JlY2FyZ2FyX2Nh
:::bGlkYWRlcyhmbXQsIEFKVVNURVMuZ2V0KCdjYWxpZGFkJykpCiAgICAgICAgICAg
:::IGNvb2tpZXMgPSBzdHIoQUpVU1RFUy5nZXQoJ2Nvb2tpZXMnLCAnJykgb3IgJycp
:::LnN0cmlwKCkubG93ZXIoKQogICAgICAgICAgICBpZiBjb29raWVzIGluIE5BVkVH
:::QURPUkVTX0NPT0tJRVM6CiAgICAgICAgICAgICAgICBzZWxmLmNtYl9jb29raWVz
:::LnNldCgnVXNhciBjb29raWVzIGRlICcKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICsgY29va2llcy5jYXBpdGFsaXplKCkpCiAgICAgICAgICAg
:::IGVsc2U6CiAgICAgICAgICAgICAgICBzZWxmLmNtYl9jb29raWVzLnNldCgnQXV0
:::b23DoXRpY28gKHJlY29tZW5kYWRvKScpCgogICAgICAgICMgLS0tLS0tLS0tLS0t
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
:::aXAoKQogICAgICAgICAgICB2YWwgPSBzZWxmLmNtYl9jb29raWVzLmdldCgpCiAg
:::ICAgICAgICAgIEFKVVNURVNbJ2Nvb2tpZXMnXSA9ICgnJyBpZiB2YWwuc3RhcnRz
:::d2l0aCgnQXV0b23DoXRpY28nKSBlbHNlCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICB2YWwucmVwbGFjZSgnVXNhciBjb29raWVzIGRlICcsICcnKQog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgLnN0cmlwKCkubG93ZXIo
:::KSkKICAgICAgICAgICAgZ3VhcmRhcl9hanVzdGVzKCkKCiAgICAgICAgZGVmIF9v
:::bl9jYXJwZXRhX2VzY3JpdGEoc2VsZiwgX2U9Tm9uZSk6CiAgICAgICAgICAgIHAg
:::PSBQYXRoKG9zLnBhdGguZXhwYW5kdmFycygKICAgICAgICAgICAgICAgIHNlbGYu
:::ZW50X2NhcnBldGEuZ2V0KCkuc3RyaXAoKS5zdHJpcCgnIicpKSkKICAgICAgICAg
:::ICAgdHJ5OgogICAgICAgICAgICAgICAgcC5ta2RpcihwYXJlbnRzPVRydWUsIGV4
:::aXN0X29rPVRydWUpCiAgICAgICAgICAgICAgICBBSlVTVEVTWydkZXN0aW5vJ10g
:::PSBzdHIocCkKICAgICAgICAgICAgICAgIGd1YXJkYXJfYWp1c3RlcygpCiAgICAg
:::ICAgICAgIGV4Y2VwdCBPU0Vycm9yIGFzIGU6CiAgICAgICAgICAgICAgICBzZWxm
:::Ll9sb2coZidObyBzZSBwdWRvIHVzYXIgZXNhIGNhcnBldGE6IHtlfScsICdlcnJv
:::cicpCgogICAgICAgIGRlZiBfY2FtYmlhcl9jYXJwZXRhKHNlbGYpOgogICAgICAg
:::ICAgICBhY3R1YWwgPSBzZWxmLmVudF9jYXJwZXRhLmdldCgpLnN0cmlwKCkgb3Ig
:::QUpVU1RFU1snZGVzdGlubyddCiAgICAgICAgICAgIG51ZXZhID0gZmlsZWRpYWxv
:::Zy5hc2tkaXJlY3RvcnkoCiAgICAgICAgICAgICAgICB0aXRsZT0nRWxpZ2UgbGEg
:::Y2FycGV0YSBkb25kZSBndWFyZGFyIGxhcyBkZXNjYXJnYXMnLAogICAgICAgICAg
:::ICAgICAgaW5pdGlhbGRpcj1hY3R1YWwgaWYgb3MucGF0aC5pc2RpcihhY3R1YWwp
:::IGVsc2Ugc3RyKFBhdGguaG9tZSgpKSkKICAgICAgICAgICAgaWYgbm90IG51ZXZh
:::OgogICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAgIHRyeToKICAgICAg
:::ICAgICAgICAgIFBhdGgobnVldmEpLm1rZGlyKHBhcmVudHM9VHJ1ZSwgZXhpc3Rf
:::b2s9VHJ1ZSkKICAgICAgICAgICAgZXhjZXB0IE9TRXJyb3IgYXMgZToKICAgICAg
:::ICAgICAgICAgIG1lc3NhZ2Vib3guc2hvd2Vycm9yKCdDYXJwZXRhIG5vIHbDoWxp
:::ZGEnLCBzdHIoZSkpCiAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAg
:::c2VsZi5lbnRfY2FycGV0YS5kZWxldGUoMCwgJ2VuZCcpCiAgICAgICAgICAgIHNl
:::bGYuZW50X2NhcnBldGEuaW5zZXJ0KDAsIG51ZXZhKQogICAgICAgICAgICBBSlVT
:::VEVTWydkZXN0aW5vJ10gPSBudWV2YQogICAgICAgICAgICBndWFyZGFyX2FqdXN0
:::ZXMoKQogICAgICAgICAgICBzZWxmLl9sb2coJ0NhcnBldGEgZGUgZ3VhcmRhZG86
:::ICcgKyBudWV2YSwgJ2dyaXMnKQoKICAgICAgICBkZWYgX2FicmlyX2Rlc3Rpbm8o
:::c2VsZik6CiAgICAgICAgICAgIHAgPSBQYXRoKG9zLnBhdGguZXhwYW5kdmFycygK
:::ICAgICAgICAgICAgICAgIHNlbGYuZW50X2NhcnBldGEuZ2V0KCkuc3RyaXAoKS5z
:::dHJpcCgnIicpKSkKICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgcC5t
:::a2RpcihwYXJlbnRzPVRydWUsIGV4aXN0X29rPVRydWUpCiAgICAgICAgICAgIGV4
:::Y2VwdCBPU0Vycm9yOgogICAgICAgICAgICAgICAgcGFzcwogICAgICAgICAgICBh
:::YnJpcl9jYXJwZXRhKHApCgogICAgICAgIGRlZiBfYWxfY2VycmFyKHNlbGYpOgog
:::ICAgICAgICAgICBpZiBzZWxmLl9vY3VwYWRvIGFuZCBub3QgbWVzc2FnZWJveC5h
:::c2tva2NhbmNlbCgKICAgICAgICAgICAgICAgICAgICAnU2FsaXInLCAnSGF5IHVu
:::YSB0YXJlYSBlbiBjdXJzby4gJwogICAgICAgICAgICAgICAgICAgICfCv1NlZ3Vy
:::byBxdWUgcXVpZXJlcyBzYWxpcj8nKToKICAgICAgICAgICAgICAgIHJldHVybgog
:::ICAgICAgICAgICBzZWxmLmRlc3Ryb3koKQoKICAgICAgICAjIC0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSByZWdpc3RybyAo
:::bG9nKQogICAgICAgIGRlZiBfbG9nKHNlbGYsIG1zZywgdGFnPSdpbmZvJyk6CiAg
:::ICAgICAgICAgIHNlbGYudHh0X2xvZy5jb25maWd1cmUoc3RhdGU9J25vcm1hbCcp
:::CiAgICAgICAgICAgIG5fbGluZWFzID0gaW50KHNlbGYudHh0X2xvZy5pbmRleCgn
:::ZW5kLTFjJykuc3BsaXQoJy4nKVswXSkKICAgICAgICAgICAgaWYgbl9saW5lYXMg
:::PiA5MDA6CiAgICAgICAgICAgICAgICBzZWxmLnR4dF9sb2cuZGVsZXRlKCcxLjAn
:::LCAnMjAwLjAnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuaW5zZXJ0KCdlbmQn
:::LCBzdHIobXNnKSArICdcbicsIHRhZykKICAgICAgICAgICAgc2VsZi50eHRfbG9n
:::LnNlZSgnZW5kJykKICAgICAgICAgICAgc2VsZi50eHRfbG9nLmNvbmZpZ3VyZShz
:::dGF0ZT0nZGlzYWJsZWQnKQoKICAgICAgICBkZWYgX2xpbXBpYXJfbG9nKHNlbGYp
:::OgogICAgICAgICAgICBzZWxmLnR4dF9sb2cuY29uZmlndXJlKHN0YXRlPSdub3Jt
:::YWwnKQogICAgICAgICAgICBzZWxmLnR4dF9sb2cuZGVsZXRlKCcxLjAnLCAnZW5k
:::JykKICAgICAgICAgICAgc2VsZi50eHRfbG9nLmNvbmZpZ3VyZShzdGF0ZT0nZGlz
:::YWJsZWQnKQoKICAgICAgICBkZWYgX2JvbWJlYXJfY29sYShzZWxmKToKICAgICAg
:::ICAgICAgdHJ5OgogICAgICAgICAgICAgICAgd2hpbGUgVHJ1ZToKICAgICAgICAg
:::ICAgICAgICAgICBldiA9IHNlbGYuY29sYS5nZXRfbm93YWl0KCkKICAgICAgICAg
:::ICAgICAgICAgICB0aXBvID0gZXZbMF0KICAgICAgICAgICAgICAgICAgICBpZiB0
:::aXBvID09ICdsb2cnOgogICAgICAgICAgICAgICAgICAgICAgICBzZWxmLl9sb2co
:::ZXZbMV0sIGV2WzJdKQogICAgICAgICAgICAgICAgICAgIGVsaWYgdGlwbyA9PSAn
:::cHJvZyc6CiAgICAgICAgICAgICAgICAgICAgICAgIHBjdCwgdGV4dG8gPSBldlsx
:::XSwgZXZbMl0KICAgICAgICAgICAgICAgICAgICAgICAgaWYgcGN0IGlzIE5vbmU6
:::CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzZWxmLmJhcnJhLnN0b3AoKQog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5iYXJyYS5jb25maWd1cmUo
:::bW9kZT0naW5kZXRlcm1pbmF0ZScpCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICBzZWxmLmJhcnJhLnN0YXJ0KDYwKQogICAgICAgICAgICAgICAgICAgICAgICBl
:::bHNlOgogICAgICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5iYXJyYS5zdG9w
:::KCkKICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYmFycmEuY29uZmln
:::dXJlKG1vZGU9J2RldGVybWluYXRlJykKICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIHNlbGYuYmFycmEuY29uZmlndXJlKHZhbHVlPW1heCgwLCBtaW4oMTAwLCBw
:::Y3QpKSkKICAgICAgICAgICAgICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmNv
:::bmZpZ3VyZSh0ZXh0PXRleHRvKQogICAgICAgICAgICAgICAgICAgIGVsaWYgdGlw
:::byA9PSAnZXN0aW1hY2lvbic6CiAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYu
:::bGJsX2VzdGltYWNpb24uY29uZmlndXJlKAogICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgdGV4dD1ldlsxXSwgZmc9VEVNQVNbc2VsZi5fdGVtYV9hY3R1YWxdWydh
:::Y2VudG8nXSkKICAgICAgICAgICAgICAgICAgICBlbGlmIHRpcG8gPT0gJ2Zpbic6
:::CiAgICAgICAgICAgICAgICAgICAgICAgIHNlbGYuX2Zpbl90YXJlYShldlsxXSwg
:::ZXZbMl0sIGV2WzNdIGlmIGxlbihldikgPiAzIGVsc2UgJycpCiAgICAgICAgICAg
:::IGV4Y2VwdCBxdWV1ZS5FbXB0eToKICAgICAgICAgICAgICAgIHBhc3MKICAgICAg
:::ICAgICAgc2VsZi5hZnRlcig4MCwgc2VsZi5fYm9tYmVhcl9jb2xhKQoKICAgICAg
:::ICAjIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLSB0YXJlYXMKICAgICAgICBkZWYgX2hhYmlsaXRhcl9hY2Npb25lcyhzZWxm
:::LCBvbik6CiAgICAgICAgICAgIGVzdGFkbyA9ICdub3JtYWwnIGlmIG9uIGVsc2Ug
:::J2Rpc2FibGVkJwogICAgICAgICAgICBmb3IgYiBpbiAoc2VsZi5idG5fZGVzY2Fy
:::Z2FyLCBzZWxmLmJ0bl9jb21wcm9iYXIsCiAgICAgICAgICAgICAgICAgICAgICBz
:::ZWxmLmJ0bl9lc3RpbWFyLCBzZWxmLmJ0bl9jYW1iaWFyLCBzZWxmLmJ0bl9hYnJp
:::ciwKICAgICAgICAgICAgICAgICAgICAgIHNlbGYuYnRuX3gpOgogICAgICAgICAg
:::ICAgICAgYi5jb25maWd1cmUoc3RhdGU9ZXN0YWRvLCBjdXJzb3I9J2hhbmQyJyBp
:::ZiBvbiBlbHNlICdhcnJvdycpCgogICAgICAgIGRlZiBfaW5pY2lhcihzZWxmLCBv
:::YmpldGl2bywgY2ZnLCB0ZXh0byk6CiAgICAgICAgICAgIGlmIHNlbGYuX29jdXBh
:::ZG86CiAgICAgICAgICAgICAgICBzZWxmLl9sb2coJ1lhIGhheSB1bmEgdGFyZWEg
:::ZW4gY3Vyc287IGVzcGVyYSBhIHF1ZSB0ZXJtaW5lLicsCiAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgJ2F2aXNvJykKICAgICAgICAgICAgICAgIHJldHVybiBGYWxz
:::ZQogICAgICAgICAgICBzZWxmLl9vY3VwYWRvID0gVHJ1ZQogICAgICAgICAgICBz
:::ZWxmLl9oYWJpbGl0YXJfYWNjaW9uZXMoRmFsc2UpCiAgICAgICAgICAgIHNlbGYu
:::bGJsX2VzdGFkby5jb25maWd1cmUodGV4dD10ZXh0bykKICAgICAgICAgICAgdGhy
:::ZWFkaW5nLlRocmVhZCh0YXJnZXQ9b2JqZXRpdm8sIGFyZ3M9KGNmZywpLCBkYWVt
:::b249VHJ1ZSkuc3RhcnQoKQogICAgICAgICAgICByZXR1cm4gVHJ1ZQoKICAgICAg
:::ICBkZWYgX2Zpbl90YXJlYShzZWxmLCB0aXBvLCBvaywgbWVuc2FqZT0nJyk6CiAg
:::ICAgICAgICAgIHNlbGYuX29jdXBhZG8gPSBGYWxzZQogICAgICAgICAgICBzZWxm
:::Ll9oYWJpbGl0YXJfYWNjaW9uZXMoVHJ1ZSkKICAgICAgICAgICAgc2VsZi5iYXJy
:::YS5zdG9wKCkKICAgICAgICAgICAgc2VsZi5iYXJyYS5jb25maWd1cmUobW9kZT0n
:::ZGV0ZXJtaW5hdGUnKQogICAgICAgICAgICBzZWxmLmJhcnJhLmNvbmZpZ3VyZSh2
:::YWx1ZT0wKQogICAgICAgICAgICBpZiB0aXBvID09ICdkZXNjYXJnYScgYW5kIG9r
:::OgogICAgICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmNvbmZpZ3VyZSh0ZXh0
:::PSdMaXN0by4nKQogICAgICAgICAgICAgICAgIyBMYSBkZXNjYXJnYSBmdWUgYmll
:::bjogc2UgbGltcGlhIGxhIFVSTCBwYXJhIGxhIHNpZ3VpZW50ZS4KICAgICAgICAg
:::ICAgICAgIHNlbGYuX3Jlc2V0X3VybCgpCiAgICAgICAgICAgIGVsaWYgbm90IG9r
:::OgogICAgICAgICAgICAgICAgc2VsZi5sYmxfZXN0YWRvLmNvbmZpZ3VyZSh0ZXh0
:::PSdUZXJtaW5hZG8gY29uIGVycm9yZXMuJykKICAgICAgICAgICAgICAgIGlmIHRp
:::cG8gPT0gJ2Rlc2NhcmdhJzoKICAgICAgICAgICAgICAgICAgICBtZXNzYWdlYm94
:::LnNob3dlcnJvcigKICAgICAgICAgICAgICAgICAgICAgICAgJ0Vycm9yJywgbWVu
:::c2FqZSBvciAnTm8gc2UgcHVkbyBjb21wbGV0YXIgbGEgdGFyZWEuICcKICAgICAg
:::ICAgICAgICAgICAgICAgICAgJ1JldmlzYSBlbCByZWdpc3RybyBwYXJhIG3DoXMg
:::ZGV0YWxsZXMuJykKCiAgICAgICAgZGVmIF91cmxfdmFsaWRhKHNlbGYpOgogICAg
:::ICAgICAgICBpZiBzZWxmLl9lbl9wbGFjZWhvbGRlcjoKICAgICAgICAgICAgICAg
:::IHNlbGYuX2xvZygnUHJpbWVybyBwZWdhIGxhIFVSTCBkZWwgdmlkZW8gZGUgWW91
:::VHViZS4nLCAnYXZpc28nKQogICAgICAgICAgICAgICAgcmV0dXJuIE5vbmUKICAg
:::ICAgICAgICAgdSA9IHNlbGYuZW50X3VybC5nZXQoKS5zdHJpcCgpLnN0cmlwKCci
:::Jykuc3RyaXAoIiciKQogICAgICAgICAgICBpZiBub3QgdToKICAgICAgICAgICAg
:::ICAgIHNlbGYuX2xvZygnTGEgVVJMIGVzdMOhIHZhY8OtYS4nLCAnYXZpc28nKQog
:::ICAgICAgICAgICAgICAgcmV0dXJuIE5vbmUKICAgICAgICAgICAgaWYgbm90IHJl
:::Lm1hdGNoKHInXmh0dHBzPzovLycsIHUsIHJlLkkpOgogICAgICAgICAgICAgICAg
:::aWYgcmUubWF0Y2gocided3d3XC4nLCB1LCByZS5JKToKICAgICAgICAgICAgICAg
:::ICAgICB1ID0gJ2h0dHBzOi8vJyArIHUKICAgICAgICAgICAgICAgIGVsc2U6CiAg
:::ICAgICAgICAgICAgICAgICAgc2VsZi5fbG9nKCdFc28gbm8gcGFyZWNlIHVuYSBV
:::UkwgKGRlYmUgZW1wZXphciBwb3IgJwogICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAnaHR0cDovLyBvIGh0dHBzOi8vKScsICdlcnJvcicpCiAgICAgICAgICAg
:::ICAgICAgICAgcmV0dXJuIE5vbmUKICAgICAgICAgICAgIyBPSk86IGFxdcOtIE5P
:::IHNlIHF1aXRhIGxpc3Q9OyBzaSBsYSBVUkwgdHJhZSB1bmEgcGxheWxpc3QsCiAg
:::ICAgICAgICAgICMgX2FjY2lvbl9kZXNjYXJnYXIgcHJlZ3VudGFyw6EgcXXDqSBo
:::YWNlciBjb24gZWxsYS4KICAgICAgICAgICAgcmV0dXJuIHUKCiAgICAgICAgZGVm
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
:::dXJuCiAgICAgICAgICAgIHNlbGYuX2d1YXJkYXIoKQogICAgICAgICAgICBwbGF5
:::bGlzdCA9IEZhbHNlCiAgICAgICAgICAgIGlmIGVzX3VybF9wbGF5bGlzdCh1cmwp
:::OgogICAgICAgICAgICAgICAgciA9IG1lc3NhZ2Vib3guYXNreWVzbm9jYW5jZWwo
:::CiAgICAgICAgICAgICAgICAgICAgJ011c2lrQUxBTiDigJQgbGlzdGEgZGUgcmVw
:::cm9kdWNjacOzbicsCiAgICAgICAgICAgICAgICAgICAgJ0VzdGEgVVJMIHBlcnRl
:::bmVjZSBhIHVuYSBsaXN0YSBkZSByZXByb2R1Y2Npw7NuLlxuXG4nCiAgICAgICAg
:::ICAgICAgICAgICAgJyAgU8ONICDihpIgIGRlc2NhcmdhciBsYSBwbGF5bGlzdCBj
:::b21wbGV0YVxuJwogICAgICAgICAgICAgICAgICAgICcgICAgICAgICAocGF1c2Eg
:::ZGUgMiBzIGVudHJlIGNhbmNpb25lcylcbicKICAgICAgICAgICAgICAgICAgICAn
:::ICBOTyAg4oaSICBkZXNjYXJnYXIgc29sbyBlc3RhIGNhbmNpw7NuXG4nCiAgICAg
:::ICAgICAgICAgICAgICAgJyAgQ2FuY2VsYXIgIOKGkiAgbm8gZGVzY2FyZ2FyIG5h
:::ZGEnKQogICAgICAgICAgICAgICAgaWYgciBpcyBOb25lOgogICAgICAgICAgICAg
:::ICAgICAgIHNlbGYuX2xvZygnRGVzY2FyZ2EgY2FuY2VsYWRhLicsICdncmlzJykK
:::ICAgICAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgICAgIGlmIHI6
:::CiAgICAgICAgICAgICAgICAgICAgcGxheWxpc3QgPSBUcnVlCiAgICAgICAgICAg
:::ICAgICBlbGlmIGVzX3NvbG9fbGlzdGEodXJsKToKICAgICAgICAgICAgICAgICAg
:::ICAjIEVzIHVuYSBwbGF5bGlzdCBwdXJhOiBubyBoYXkgInVuYSBjYW5jacOzbiIg
:::YWjDrQogICAgICAgICAgICAgICAgICAgIHNlbGYuX2xvZygnRXNhIFVSTCBlcyB1
:::bmEgbGlzdGEgY29tcGxldGE7IHNlIGRlc2NhcmdhcsOhICcKICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgJ2VudGVyYS4nLCAnYXZpc28nKQogICAgICAgICAg
:::ICAgICAgICAgIHBsYXlsaXN0ID0gVHJ1ZQogICAgICAgICAgICBjZmcgPSB7J3Vy
:::bCc6IHVybCwgJ3BsYXlsaXN0JzogcGxheWxpc3R9CiAgICAgICAgICAgIHNlbGYu
:::X2luaWNpYXIoc2VsZi5faGlsb19kZXNjYXJnYXIsIGNmZywgJ0Rlc2NhcmdhbmRv
:::Li4uJykKCiAgICAgICAgZGVmIF9hY2Npb25fY29tcHJvYmFyKHNlbGYpOgogICAg
:::ICAgICAgICBzZWxmLl9ndWFyZGFyKCkKICAgICAgICAgICAgc2VsZi5faW5pY2lh
:::cihzZWxmLl9oaWxvX2NvbXByb2Jhciwge30sCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgJ0NvbXByb2JhbmRvIGxhIGNhcnBldGEuLi4nKQoKICAgICAgICBkZWYg
:::X2FjY2lvbl9hY3R1YWxpemFyKHNlbGYpOgogICAgICAgICAgICBpZiBub3QgWVRf
:::RExQOgogICAgICAgICAgICAgICAgc2VsZi5fbG9nKCd5dC1kbHAgbm8gZXN0w6Eg
:::aW5zdGFsYWRvOyBlamVjdXRhICcKICAgICAgICAgICAgICAgICAgICAgICAgICAn
:::RGVzY2FyZ2Fkb3JNdXNpY2EuYmF0LicsICdlcnJvcicpCiAgICAgICAgICAgICAg
:::ICByZXR1cm4KICAgICAgICAgICAgc2VsZi5faW5pY2lhcihzZWxmLl9oaWxvX2Fj
:::dHVhbGl6YXIsIHt9LCAnQWN0dWFsaXphbmRvIHl0LWRscC4uLicpCgogICAgICAg
:::ICMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tIGhpbG9zCiAgICAgICAgZGVmIF9oaWxvX2VzdGltYXIoc2VsZiwgY2ZnKToK
:::ICAgICAgICAgICAgY29sYSA9IHNlbGYuY29sYQoKICAgICAgICAgICAgZGVmIGxv
:::ZyhtLCB0PSdpbmZvJyk6CiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2xvZycs
:::IG0sIHQpKQoKICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgaWYgWVRf
:::RExQIGlzIE5vbmU6CiAgICAgICAgICAgICAgICAgICAgbG9nKCd5dC1kbHAgbm8g
:::ZXN0w6EgaW5zdGFsYWRvLiBFamVjdXRhICcKICAgICAgICAgICAgICAgICAgICAg
:::ICAgJ0Rlc2NhcmdhZG9yTXVzaWNhLmJhdCBwYXJhIGluc3RhbGFybG8uJywgJ2Vy
:::cm9yJykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2VzdGltYWNpb24n
:::LCAneXQtZGxwIG5vIGRpc3BvbmlibGUnKSkKICAgICAgICAgICAgICAgICAgICBy
:::ZXR1cm4KICAgICAgICAgICAgICAgIGxvZygnT2J0ZW5pZW5kbyBpbmZvcm1hY2nD
:::s24gZGVsIHZpZGVvLi4uJywgJ2dyaXMnKQogICAgICAgICAgICAgICAgbyA9IHsn
:::cXVpZXQnOiBUcnVlLCAnbm9fd2FybmluZ3MnOiBUcnVlLCAnbm9wbGF5bGlzdCc6
:::IFRydWUsCiAgICAgICAgICAgICAgICAgICAgICdzb2NrZXRfdGltZW91dCc6IDMw
:::LCAnbG9nZ2VyJzogUkVHSVNUUk99CiAgICAgICAgICAgICAgICBfYW50aV9ib3Qo
:::bykKICAgICAgICAgICAgICAgIGlmIGVzX3VybF9wbGF5bGlzdChjZmdbJ3VybCdd
:::KToKICAgICAgICAgICAgICAgICAgICBsb2coJyhsYSBVUkwgY29udGllbmUgdW5h
:::IHBsYXlsaXN0OiBsYSBlc3RpbWFjacOzbiBlcyAnCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICdzb2xvIGRlbCB2aWRlbyBwZWdhZG8pJywgJ2dyaXMnKQogICAgICAg
:::ICAgICAgICAgd2l0aCBZVF9ETFAuWW91dHViZURMKG8pIGFzIHlkbDoKICAgICAg
:::ICAgICAgICAgICAgICBpbmZvID0geWRsLmV4dHJhY3RfaW5mbyhjZmdbJ3VybCdd
:::LCBkb3dubG9hZD1GYWxzZSkKICAgICAgICAgICAgICAgIGR1ciA9IGluZm8uZ2V0
:::KCdkdXJhdGlvbicpCiAgICAgICAgICAgICAgICBpZiBub3QgZHVyOgogICAgICAg
:::ICAgICAgICAgICAgIGxvZygnTm8gc2UgcHVkbyBvYnRlbmVyIGxhIGR1cmFjacOz
:::biBkZWwgdmlkZW8uJywgJ2Vycm9yJykKICAgICAgICAgICAgICAgICAgICBjb2xh
:::LnB1dCgoJ2VzdGltYWNpb24nLCAnU2luIGRhdG9zIHBhcmEgZXN0aW1hcicpKQog
:::ICAgICAgICAgICAgICAgICAgIHJldHVybgogICAgICAgICAgICAgICAgY2xhdmUg
:::PSBzZWxmLl9mbXRfYWN0dWFsX3NvbG8oQUpVU1RFUy5nZXQoJ2Zvcm1hdG8nLCAn
:::QUFDJykpCiAgICAgICAgICAgICAgICB0YW0gPSBlc3RpbWFyX2J5dGVzKGR1ciwg
:::Y2xhdmUsIEFKVVNURVMuZ2V0KCdjYWxpZGFkJyksCiAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgIGJvb2woQUpVU1RFUy5nZXQoJ2VtYmViZXInLCBU
:::cnVlKSkpCiAgICAgICAgICAgICAgICB0aXR1bG8gPSBzdHIoaW5mby5nZXQoJ3Rp
:::dGxlJykgb3IgJycpWzo3MF0KICAgICAgICAgICAgICAgIGlmIHRpdHVsbzoKICAg
:::ICAgICAgICAgICAgICAgICBsb2coJ+KZqiAnICsgdGl0dWxvLCAndGl0dWxvJykK
:::ICAgICAgICAgICAgICAgIHRleHRvID0gKGYnfnt0YW0gLyAxMDQ4NTc2Oi4xZn0g
:::TUIgwrcgJwogICAgICAgICAgICAgICAgICAgICAgICAgZidkdXJhY2nDs24ge2Zt
:::dF90aWVtKGR1cil9IMK3ICcKICAgICAgICAgICAgICAgICAgICAgICAgIGYne2Ns
:::YXZlfSB7QUpVU1RFUy5nZXQoImNhbGlkYWQiLCAiIil9Jy5yc3RyaXAoKSkKICAg
:::ICAgICAgICAgICAgIGNvbGEucHV0KCgnZXN0aW1hY2lvbicsIHRleHRvKSkKICAg
:::ICAgICAgICAgICAgIGxvZygnRXN0aW1hY2nDs246ICcgKyB0ZXh0bywgJ29rJykK
:::ICAgICAgICAgICAgICAgIGxvZygnRWwgdGFtYcOxbyByZWFsIHB1ZWRlIHZhcmlh
:::ciBhbGdvIHNlZ8O6biBsYSBmdWVudGUuJywKICAgICAgICAgICAgICAgICAgICAn
:::Z3JpcycpCiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb24gYXMgZToKICAgICAg
:::ICAgICAgICAgIGxvZyhmJ05vIHNlIHB1ZG8gZXN0aW1hcjoge3NlbGYuX21zZ19l
:::cnJvcihlKX0nLCAnZXJyb3InKQogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdl
:::c3RpbWFjaW9uJywgJ05vIHNlIHB1ZG8gZXN0aW1hcicpKQogICAgICAgICAgICBm
:::aW5hbGx5OgogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnZXN0aW1h
:::Y2lvbicsIFRydWUsICcnKSkKCiAgICAgICAgZGVmIF9mbXRfYWN0dWFsX3NvbG8o
:::c2VsZiwgY2xhdmUpOgogICAgICAgICAgICByZXR1cm4gY2xhdmUgaWYgY2xhdmUg
:::aW4gRk9STUFUT1MgZWxzZSAnQUFDJwoKICAgICAgICBkZWYgX2Rlc2Nhcmdhcl91
:::bmEoc2VsZiwgdXJsLCBjbGF2ZSwgY2FsaWRhZF9hcmcsIGVtYmViZXIsIGRlc3Rp
:::bm8sCiAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbGEpOgogICAgICAgICAg
:::ICAiIiJEZXNjYXJnYSB5IGNvbnZpZXJ0ZSBVTkEgVVJMLiBEZXZ1ZWx2ZSBlbCBQ
:::YXRoIGZpbmFsIG8gTm9uZS4iIiIKICAgICAgICAgICAgaWYgY2xhdmUgPT0gJ1dN
:::QSc6CiAgICAgICAgICAgICAgICByZXR1cm4gZGVzY2FyZ2FyX3dtYSh1cmwsIGNh
:::bGlkYWRfYXJnLCBkZXN0aW5vLCBlbWJlYmVyLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgY29sYSlbMV0KICAgICAgICAgICAgaWYgY2xhdmUg
:::PT0gJ0FWSSc6CiAgICAgICAgICAgICAgICByZXR1cm4gZGVzY2FyZ2FyX2F2aSh1
:::cmwsIGRlc3Rpbm8sIGNvbGEpWzFdCiAgICAgICAgICAgIHJldHVybiBkZXNjYXJn
:::YXJfYXVkaW8odXJsLCBjbGF2ZSwgY2FsaWRhZF9hcmcsIGRlc3Rpbm8sIGVtYmVi
:::ZXIsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgY29sYSlbMV0K
:::CiAgICAgICAgZGVmIF9kZXNjYXJnYXJfcGxheWxpc3Qoc2VsZiwgdXJsLCBjbGF2
:::ZSwgY2FsaWRhZF9hcmcsIGVtYmViZXIsCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgZGVzdGlubywgY29sYSk6CiAgICAgICAgICAgICIiIkJhamEgdW5h
:::IGxpc3RhIGVudGVyYSwgY29uIDIgcyBkZSBkZXNjYW5zbyBlbnRyZSBjYW5jaW9u
:::ZXMKICAgICAgICAgICAgcGFyYSBubyBzYXR1cmFyIGEgWW91VHViZS4gRGV2dWVs
:::dmUgKGRlc2NhcmdhZGFzLCB0b3RhbCkuIiIiCiAgICAgICAgICAgIGRlZiBsb2co
:::bSwgdD0naW5mbycpOgogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBt
:::LCB0KSkKCiAgICAgICAgICAgIGxvZygnTGV5ZW5kbyBsYSBsaXN0YSBkZSByZXBy
:::b2R1Y2Npw7NuLi4uJywgJ2dyaXMnKQogICAgICAgICAgICBvID0geydxdWlldCc6
:::IFRydWUsICdub193YXJuaW5ncyc6IFRydWUsCiAgICAgICAgICAgICAgICAgJ2V4
:::dHJhY3RfZmxhdCc6ICdpbl9wbGF5bGlzdCcsICdzb2NrZXRfdGltZW91dCc6IDMw
:::LAogICAgICAgICAgICAgICAgICdsb2dnZXInOiBSRUdJU1RST30KICAgICAgICAg
:::ICAgX2FudGlfYm90KG8pCiAgICAgICAgICAgIHdpdGggWVRfRExQLllvdXR1YmVE
:::TChvKSBhcyB5ZGw6CiAgICAgICAgICAgICAgICBpbmZvID0geWRsLmV4dHJhY3Rf
:::aW5mbyh1cmwsIGRvd25sb2FkPUZhbHNlKQogICAgICAgICAgICBlbnRyYWRhcyA9
:::IGxpc3QoaW5mby5nZXQoJ2VudHJpZXMnKSBvciBbXSkKICAgICAgICAgICAgaWYg
:::bm90IGVudHJhZGFzOgogICAgICAgICAgICAgICAgbG9nKCdObyBzZSB2aW8gbmlu
:::Z3VuYSBjYW5jacOzbiBlbiBsYSBsaXN0YTsgc2UgaW50ZW50YSAnCiAgICAgICAg
:::ICAgICAgICAgICAgJ2NvbW8gdmlkZW8gc3VlbHRvLicsICdhdmlzbycpCiAgICAg
:::ICAgICAgICAgICBhcmNoaXZvID0gc2VsZi5fZGVzY2FyZ2FyX3VuYShzaW5fcGxh
:::eWxpc3QodXJsKVswXSwgY2xhdmUsCiAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgICBjYWxpZGFkX2FyZywgZW1iZWJlciwgZGVzdGlu
:::bywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::IGNvbGEpCiAgICAgICAgICAgICAgICByZXR1cm4gKDEgaWYgYXJjaGl2byBlbHNl
:::IDApLCAxCiAgICAgICAgICAgIHRpdHVsb19wbCA9IHN0cihpbmZvLmdldCgndGl0
:::bGUnKSBvciAnbGlzdGEnKVs6NzBdCiAgICAgICAgICAgIHRvdGFsID0gbGVuKGVu
:::dHJhZGFzKQogICAgICAgICAgICBsb2coZidQbGF5bGlzdCDCq3t0aXR1bG9fcGx9
:::wrsg4oCUIHt0b3RhbH0gdsOtZGVvKHMpLicsICd0aXR1bG8nKQogICAgICAgICAg
:::ICBva2FzID0gMAogICAgICAgICAgICBmYWxsb3MgPSBbXQogICAgICAgICAgICBm
:::b3IgaSwgZSBpbiBlbnVtZXJhdGUoZW50cmFkYXMpOgogICAgICAgICAgICAgICAg
:::dSA9IHN0cihlLmdldCgnd2VicGFnZV91cmwnKSBvciBlLmdldCgndXJsJykgb3Ig
:::JycpCiAgICAgICAgICAgICAgICBpZiB1IGFuZCBub3QgdS5zdGFydHN3aXRoKCdo
:::dHRwJyk6CiAgICAgICAgICAgICAgICAgICAgdSA9ICdodHRwczovL3d3dy55b3V0
:::dWJlLmNvbS93YXRjaD92PScgKyB1CiAgICAgICAgICAgICAgICBpZiBub3QgdSBh
:::bmQgZS5nZXQoJ2lkJyk6CiAgICAgICAgICAgICAgICAgICAgdSA9ICdodHRwczov
:::L3d3dy55b3V0dWJlLmNvbS93YXRjaD92PScgKyBzdHIoZVsnaWQnXSkKICAgICAg
:::ICAgICAgICAgIHRpdCA9IHN0cihlLmdldCgndGl0bGUnKSBvciB1IG9yICc/Jylb
:::OjcwXQogICAgICAgICAgICAgICAgaWYgaToKICAgICAgICAgICAgICAgICAgICB0
:::aW1lLnNsZWVwKDIpICAgIyBkZXNjYW5zbyBlbnRyZSBjYW5jaW9uZXMKICAgICAg
:::ICAgICAgICAgIGxvZyhmJ1t7aSArIDF9L3t0b3RhbH1dIOKZqiB7dGl0fScsICd0
:::aXR1bG8nKQogICAgICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgICAg
:::IGFyY2hpdm8gPSBzZWxmLl9kZXNjYXJnYXJfdW5hKHUsIGNsYXZlLCBjYWxpZGFk
:::X2FyZywKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICBlbWJlYmVyLCBkZXN0aW5vLCBjb2xhKQogICAgICAgICAgICAgICAg
:::ZXhjZXB0IEV4Y2VwdGlvbiBhcyBlMjoKICAgICAgICAgICAgICAgICAgICBpZiBf
:::ZXNfYmxvcXVlb19ib3Qoc3RyKGUyKSk6CiAgICAgICAgICAgICAgICAgICAgICAg
:::ICMgYmxvcXVlbyBhbnRpLWJvdDogYWJvcnRhciBwYXJhIHF1ZSBlbCByZWludGVu
:::dG8KICAgICAgICAgICAgICAgICAgICAgICAgIyBhdXRvbcOhdGljbyBkZSBfaGls
:::b19kZXNjYXJnYXIgc2UgZW5jYXJndWUKICAgICAgICAgICAgICAgICAgICAgICAg
:::cmFpc2UKICAgICAgICAgICAgICAgICAgICBhcmNoaXZvID0gTm9uZQogICAgICAg
:::ICAgICAgICAgICAgIGxvZyhmJ+KcliBbe2kgKyAxfS97dG90YWx9XSBGYWxsw7M6
:::IHtzZWxmLl9tc2dfZXJyb3IoZTIpfScsCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICdlcnJvcicpCiAgICAgICAgICAgICAgICBpZiBhcmNoaXZvIGFuZCBQYXRoKGFy
:::Y2hpdm8pLmV4aXN0cygpOgogICAgICAgICAgICAgICAgICAgIHRyeToKICAgICAg
:::ICAgICAgICAgICAgICAgICAgdGFtID0gZm10X3RhbShQYXRoKGFyY2hpdm8pLnN0
:::YXQoKS5zdF9zaXplKQogICAgICAgICAgICAgICAgICAgIGV4Y2VwdCBPU0Vycm9y
:::OgogICAgICAgICAgICAgICAgICAgICAgICB0YW0gPSAnPycKICAgICAgICAgICAg
:::ICAgICAgICBsb2coZicgICDinJQge1BhdGgoYXJjaGl2bykubmFtZX0gICh7dGFt
:::fSknLCAnb2snKQogICAgICAgICAgICAgICAgICAgIG9rYXMgKz0gMQogICAgICAg
:::ICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgICAgICBmYWxsb3MuYXBwZW5k
:::KHRpdCkKICAgICAgICAgICAgbG9nKGYnUGxheWxpc3QgdGVybWluYWRhOiB7b2th
:::c30gZGUge3RvdGFsfSBkZXNjYXJnYWRhKHMpLicsCiAgICAgICAgICAgICAgICAn
:::b2snIGlmIG5vdCBmYWxsb3MgZWxzZSAnYXZpc28nKQogICAgICAgICAgICBpZiBm
:::YWxsb3M6CiAgICAgICAgICAgICAgICBsb2coJ1NpbiBkZXNjYXJnYXI6ICcKICAg
:::ICAgICAgICAgICAgICAgICArICcgwrcgJy5qb2luKGZbOjQwXSBmb3IgZiBpbiBm
:::YWxsb3NbOjhdKQogICAgICAgICAgICAgICAgICAgICsgKCcuLi4nIGlmIGxlbihm
:::YWxsb3MpID4gOCBlbHNlICcnKSwgJ2dyaXMnKQogICAgICAgICAgICByZXR1cm4g
:::b2thcywgdG90YWwKCiAgICAgICAgZGVmIF9oaWxvX2Rlc2NhcmdhcihzZWxmLCBj
:::ZmcpOgogICAgICAgICAgICBjb2xhID0gc2VsZi5jb2xhCgogICAgICAgICAgICBk
:::ZWYgbG9nKG0sIHQ9J2luZm8nKToKICAgICAgICAgICAgICAgIGNvbGEucHV0KCgn
:::bG9nJywgbSwgdCkpCgogICAgICAgICAgICB1cmwgPSBjZmdbJ3VybCddCiAgICAg
:::ICAgICAgIGNsYXZlID0gc2VsZi5fZm10X2FjdHVhbF9zb2xvKEFKVVNURVMuZ2V0
:::KCdmb3JtYXRvJywgJ0FBQycpKQogICAgICAgICAgICBjYWxpZGFkID0gQUpVU1RF
:::Uy5nZXQoJ2NhbGlkYWQnLCAnMTI4aycpCiAgICAgICAgICAgIGVtYmViZXIgPSBi
:::b29sKEFKVVNURVMuZ2V0KCdlbWJlYmVyJywgVHJ1ZSkpCiAgICAgICAgICAgIGRl
:::c3Rpbm8gPSBQYXRoKG9zLnBhdGguZXhwYW5kdmFycygKICAgICAgICAgICAgICAg
:::IHN0cihBSlVTVEVTLmdldCgnZGVzdGlubycsIF9kZXN0aW5vX3Bvcl9kZWZlY3Rv
:::KCkpKSkpCiAgICAgICAgICAgIHRyeToKICAgICAgICAgICAgICAgIGlmIFlUX0RM
:::UCBpcyBOb25lOgogICAgICAgICAgICAgICAgICAgIGxvZygneXQtZGxwIG5vIGVz
:::dMOhIGluc3RhbGFkby4gRWplY3V0YSAnCiAgICAgICAgICAgICAgICAgICAgICAg
:::ICdEZXNjYXJnYWRvck11c2ljYS5iYXQgcGFyYSBpbnN0YWxhcmxvLicsICdlcnJv
:::cicpCiAgICAgICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnZGVzY2Fy
:::Z2EnLCBGYWxzZSwKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgJ3l0LWRs
:::cCBubyBlc3TDoSBpbnN0YWxhZG8uJykpCiAgICAgICAgICAgICAgICAgICAgcmV0
:::dXJuCiAgICAgICAgICAgICAgICBkZXN0aW5vLm1rZGlyKHBhcmVudHM9VHJ1ZSwg
:::ZXhpc3Rfb2s9VHJ1ZSkKICAgICAgICAgICAgICAgIGlmIGNsYXZlIGluICgnRkxB
:::QycsICdXQVYnKToKICAgICAgICAgICAgICAgICAgICBjYWxpZGFkX2FyZyA9ICcw
:::JwogICAgICAgICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgICAgICBjYWxp
:::ZGFkX2FyZyA9IChyZS5zdWIocidbXjAtOV0nLCAnJywgc3RyKGNhbGlkYWQpKQog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9yICgnMTI4JyBpZiBj
:::bGF2ZSA9PSAnQUFDJyBlbHNlICczMjAnKSkKICAgICAgICAgICAgICAgIGlmIGNm
:::Zy5nZXQoJ3BsYXlsaXN0Jyk6CiAgICAgICAgICAgICAgICAgICAgb2thcywgdG90
:::YWwgPSBzZWxmLl9kZXNjYXJnYXJfcGxheWxpc3QoCiAgICAgICAgICAgICAgICAg
:::ICAgICAgIHVybCwgY2xhdmUsIGNhbGlkYWRfYXJnLCBlbWJlYmVyLCBkZXN0aW5v
:::LCBjb2xhKQogICAgICAgICAgICAgICAgICAgIGlmIG9rYXMgYW5kIG9rYXMgPT0g
:::dG90YWw6CiAgICAgICAgICAgICAgICAgICAgICAgIGxvZyhmJ0NhcnBldGE6IHtk
:::ZXN0aW5vfScsICdncmlzJykKICAgICAgICAgICAgICAgICAgICAgICAgY29sYS5w
:::dXQoKCdmaW4nLCAnZGVzY2FyZ2EnLCBUcnVlLCAnJykpCiAgICAgICAgICAgICAg
:::ICAgICAgZWxzZToKICAgICAgICAgICAgICAgICAgICAgICAgY29sYS5wdXQoKAog
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2ZpbicsICdkZXNjYXJnYScsIEZh
:::bHNlLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgZidTZSBkZXNjYXJnYXJv
:::biB7b2thc30gZGUge3RvdGFsfSBkZSBsYSAnCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAncGxheWxpc3QuIExhIFVSTCBubyBzZSBoYSBib3JyYWRvIHBvciBz
:::aSAnCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAncXVpZXJlcyByZWludGVu
:::dGFybG8uJykpCiAgICAgICAgICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgICAg
:::ICAgICBhcmNoaXZvID0gc2VsZi5fZGVzY2FyZ2FyX3VuYShzaW5fcGxheWxpc3Qo
:::dXJsKVswXSwgY2xhdmUsCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICBjYWxpZGFkX2FyZywgZW1iZWJlciwgZGVzdGlubywKICAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGNvbGEp
:::CiAgICAgICAgICAgICAgICBpZiBhcmNoaXZvIGFuZCBQYXRoKGFyY2hpdm8pLmV4
:::aXN0cygpOgogICAgICAgICAgICAgICAgICAgIGFyY2hpdm8gPSBQYXRoKGFyY2hp
:::dm8pCiAgICAgICAgICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgICAg
:::ICAgICB0YW0gPSBmbXRfdGFtKGFyY2hpdm8uc3RhdCgpLnN0X3NpemUpCiAgICAg
:::ICAgICAgICAgICAgICAgZXhjZXB0IE9TRXJyb3I6CiAgICAgICAgICAgICAgICAg
:::ICAgICAgIHRhbSA9ICc/JwogICAgICAgICAgICAgICAgICAgIGxvZyhmJ+KclCDC
:::oUxpc3RvISAge2FyY2hpdm8ubmFtZX0gICh7dGFtfSknLCAnb2snKQogICAgICAg
:::ICAgICAgICAgICAgIGxvZyhmJ0NhcnBldGE6IHthcmNoaXZvLnBhcmVudH0nLCAn
:::Z3JpcycpCiAgICAgICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAnZGVz
:::Y2FyZ2EnLCBUcnVlLCAnJykpCiAgICAgICAgICAgICAgICBlbHNlOgogICAgICAg
:::ICAgICAgICAgICAgIGxvZygnRWwgYXJjaGl2byBmaW5hbCBubyBhcGFyZWNpw7Mg
:::ZG9uZGUgc2UgZXNwZXJhYmEuJywKICAgICAgICAgICAgICAgICAgICAgICAgJ2Vy
:::cm9yJykKICAgICAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdkZXNj
:::YXJnYScsIEZhbHNlLCAnJykpCiAgICAgICAgICAgIGV4Y2VwdCBFeGNlcHRpb24g
:::YXMgZToKICAgICAgICAgICAgICAgIG5vbWJyZV9leGMgPSB0eXBlKGUpLl9fbmFt
:::ZV9fCiAgICAgICAgICAgICAgICBpZiBub21icmVfZXhjID09ICdEb3dubG9hZEVy
:::cm9yJzoKICAgICAgICAgICAgICAgICAgICBsaW5lYXMgPSBbbCBmb3IgbCBpbiBz
:::dHIoZSkuc3RyaXAoKS5zcGxpdGxpbmVzKCkgaWYgbC5zdHJpcCgpXQogICAgICAg
:::ICAgICAgICAgICAgIG1zZyA9IGxpbmVhc1swXVs6MzAwXSBpZiBsaW5lYXMgZWxz
:::ZSAnZXJyb3IgZGVzY29ub2NpZG8nCiAgICAgICAgICAgICAgICAgICAgaWYgX2Vz
:::X2Jsb3F1ZW9fYm90KHN0cihlKSk6CiAgICAgICAgICAgICAgICAgICAgICAgIGlm
:::IF9BTlRJX0JPVFsnY29tYm8nXSA9PSAwOgogICAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgbG9nKCdZb3VUdWJlIGVzdMOhIHBpZGllbmRvIHZlcmlmaWNhY2nDs24g
:::JwogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICdhbnRpLWJvdCBwYXJh
:::IGVzdGEgcmVkLiBSZWludGVudGFuZG8gY29uICcKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAndW5hIHbDrWEgaW50ZXJuYSBhbHRlcm5hdGl2YS4uLics
:::ICdhdmlzbycpCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBfQU5USV9CT1Rb
:::J2NvbWJvJ10gPSAxCiAgICAgICAgICAgICAgICAgICAgICAgICAgICB0cnk6CiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgdGltZS5zbGVlcCgzKSAgICMg
:::cmVzcGlybyBwYXJhIGVsIDQyOQogICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::ICAgIHNlbGYuX2hpbG9fZGVzY2FyZ2FyKGNmZykKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgICAgICAgICAgICAgICAg
:::IGZpbmFsbHk6CiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgX0FOVElf
:::Qk9UWydjb21ibyddID0gMAogICAgICAgICAgICAgICAgICAgICAgICBsb2coJ+Kc
:::liBZb3VUdWJlIHNpZ3VlIHBpZGllbmRvIHZlcmlmaWNhY2nDs246ICcKICAgICAg
:::ICAgICAgICAgICAgICAgICAgICAgICsgbXNnLCAnZXJyb3InKQogICAgICAgICAg
:::ICAgICAgICAgICAgICBsb2coJ1NvbHVjacOzbiBmaWFibGU6IGVuIMKrU2kgWW91
:::VHViZSBibG9xdWVhOsK7ICcKICAgICAgICAgICAgICAgICAgICAgICAgICAgICdl
:::bGlnZSBVc2FyIGNvb2tpZXMgZGUgRmlyZWZveCAobyB0dSAnCiAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAnbmF2ZWdhZG9yKSB5IHJlaW50ZW50YTogY29uIHR1
:::IHNlc2nDs24gJwogICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2FiaWVydGEg
:::WW91VHViZSBubyB2dWVsdmUgYSBwZWRpciAnCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAndmVyaWZpY2FjacOzbi4nLCAnZ3JpcycpCiAgICAgICAgICAgICAg
:::ICAgICAgICAgIGxvZygnVGFtYmnDqW4gc3VlbGVuIGZ1bmNpb25hcjogZXNwZXJh
:::ciB1bm9zICcKICAgICAgICAgICAgICAgICAgICAgICAgICAgICdtaW51dG9zLCBw
:::dWxzYXIgQ3RybCtVIChhY3R1YWxpemFyIHl0LWRscCkgJwogICAgICAgICAgICAg
:::ICAgICAgICAgICAgICAgJ28gcHJvYmFyIGNvbiBvdHJhIHJlZCAoZWwgd2lmaSBk
:::ZSBjYXNhKS4nLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgJ2dyaXMnKQog
:::ICAgICAgICAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICAgICAgICAg
:::IGxvZygn4pyWIE5vIHNlIHB1ZG8gZGVzY2FyZ2FyOiAnICsgbXNnLCAnZXJyb3In
:::KQogICAgICAgICAgICAgICAgICAgICAgICBsb2coJ0NvbnNlam9zOiByZXZpc2Eg
:::bGEgVVJMIHkgdHUgY29uZXhpw7NuOyBzaSAnCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAnWW91VHViZSBjYW1iacOzIGFsZ28sIHB1bHNhIEN0cmwrVSAnCiAg
:::ICAgICAgICAgICAgICAgICAgICAgICAgICAnKGFjdHVhbGl6YXIgeXQtZGxwKSB5
:::IHJlaW50ZW50YS4nLCAnZ3JpcycpCiAgICAgICAgICAgICAgICBlbHNlOgogICAg
:::ICAgICAgICAgICAgICAgIGxvZyhmJ+KcliBFcnJvciBpbmVzcGVyYWRvICh7bm9t
:::YnJlX2V4Y30pOiB7ZX0nLCAnZXJyb3InKQogICAgICAgICAgICAgICAgICAgIHRi
:::ID0gdHJhY2ViYWNrLmZvcm1hdF9leGMobGltaXQ9MykKICAgICAgICAgICAgICAg
:::ICAgICB0cnk6CiAgICAgICAgICAgICAgICAgICAgICAgIHdpdGggb3BlbihMT0df
:::RVJST1JFUywgJ2EnLCBlbmNvZGluZz0ndXRmLTgnKSBhcyBmaDoKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAgIGZoLndyaXRlKHRiICsgJ1xuJykKICAgICAgICAg
:::ICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICAgICAgICAg
:::ICAgICBwYXNzCiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdkZXNj
:::YXJnYScsIEZhbHNlLAogICAgICAgICAgICAgICAgICAgICAgICAgICdObyBzZSBw
:::dWRvIGNvbXBsZXRhciBsYSBkZXNjYXJnYS4gUmV2aXNhIGVsICcKICAgICAgICAg
:::ICAgICAgICAgICAgICAgICAncmVnaXN0cm8gcGFyYSBtw6FzIGRldGFsbGVzLicp
:::KQoKICAgICAgICBkZWYgX2hpbG9fY29tcHJvYmFyKHNlbGYsIGNmZyk6CiAgICAg
:::ICAgICAgIGNvbGEgPSBzZWxmLmNvbGEKCiAgICAgICAgICAgIGRlZiBsb2cobSwg
:::dD0naW5mbycpOgogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0
:::KSkKCiAgICAgICAgICAgIGNhcnBldGEgPSBQYXRoKG9zLnBhdGguZXhwYW5kdmFy
:::cygKICAgICAgICAgICAgICAgIHN0cihBSlVTVEVTLmdldCgnZGVzdGlubycsIF9k
:::ZXN0aW5vX3Bvcl9kZWZlY3RvKCkpKSkpCiAgICAgICAgICAgIHRyeToKICAgICAg
:::ICAgICAgICAgIGlmIG5vdCBjYXJwZXRhLmlzX2RpcigpOgogICAgICAgICAgICAg
:::ICAgICAgIGxvZyhmJ0xhIGNhcnBldGEgdG9kYXbDrWEgbm8gZXhpc3RlOiB7Y2Fy
:::cGV0YX0nLCAnYXZpc28nKQogICAgICAgICAgICAgICAgICAgIGNvbGEucHV0KCgn
:::ZmluJywgJ2NvbXByb2JhY2lvbicsIFRydWUsICcnKSkKICAgICAgICAgICAgICAg
:::ICAgICByZXR1cm4KICAgICAgICAgICAgICAgIGlmIEZGUFJPQkUgaXMgTm9uZToK
:::ICAgICAgICAgICAgICAgICAgICBsb2coJ2ZmcHJvYmUgbm8gZXN0w6EgZGlzcG9u
:::aWJsZSAodmllbmUgY29uIEZGbXBlZykuICcKICAgICAgICAgICAgICAgICAgICAg
:::ICAgJ0VqZWN1dGEgRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0IHBhcmEgaW5zdGFsYXJs
:::by4nLAogICAgICAgICAgICAgICAgICAgICAgICAnZXJyb3InKQogICAgICAgICAg
:::ICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2NvbXByb2JhY2lvbicsIFRydWUs
:::ICcnKSkKICAgICAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAgICAgICAg
:::IGV4dHMgPSAoJy5tNGEnLCAnLm1wMycsICcuZmxhYycsICcud2F2JywgJy53bWEn
:::LCAnLmF2aScpCiAgICAgICAgICAgICAgICBhcmNoaXZvcyA9IFtwIGZvciBwIGlu
:::IHNvcnRlZChjYXJwZXRhLnJnbG9iKCcqJykpCiAgICAgICAgICAgICAgICAgICAg
:::ICAgICAgICBpZiBwLmlzX2ZpbGUoKSBhbmQgcC5zdWZmaXgubG93ZXIoKSBpbiBl
:::eHRzCiAgICAgICAgICAgICAgICAgICAgICAgICAgICBhbmQgJ190bXAnIG5vdCBp
:::biBwLnBhcnRzXQogICAgICAgICAgICAgICAgbG9nKGYnQ29tcHJvYmFuZG8ge2xl
:::bihhcmNoaXZvcyl9IGFyY2hpdm8ocykgZW4gJwogICAgICAgICAgICAgICAgICAg
:::IGYne2NhcnBldGF9IC4uLicsICd0aXR1bG8nKQogICAgICAgICAgICAgICAgaWYg
:::bm90IGFyY2hpdm9zOgogICAgICAgICAgICAgICAgICAgIGxvZygnTm8gaGF5IGFy
:::Y2hpdm9zIGRlIGF1ZGlvIG8gdmlkZW8gdG9kYXbDrWEuJywgJ2dyaXMnKQogICAg
:::ICAgICAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ2NvbXByb2JhY2lvbics
:::IFRydWUsICcnKSkKICAgICAgICAgICAgICAgICAgICByZXR1cm4KICAgICAgICAg
:::ICAgICAgIHRvdGFsID0gMAogICAgICAgICAgICAgICAgYmFqYXMgPSAwCiAgICAg
:::ICAgICAgICAgICBmb3IgcCBpbiBhcmNoaXZvczoKICAgICAgICAgICAgICAgICAg
:::ICB0cnk6CiAgICAgICAgICAgICAgICAgICAgICAgIHIgPSBzdWJwcm9jZXNzLnJ1
:::bigKICAgICAgICAgICAgICAgICAgICAgICAgICAgIFtzdHIoRkZQUk9CRSksICct
:::dicsICdlcnJvcicsICctc2hvd19lbnRyaWVzJywKICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgICAnZm9ybWF0PWJpdF9yYXRlLGR1cmF0aW9uLHNpemUnLCAnLW9m
:::JywgJ2pzb24nLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgIHN0cihwKV0s
:::CiAgICAgICAgICAgICAgICAgICAgICAgICAgICBzdGRvdXQ9c3VicHJvY2Vzcy5Q
:::SVBFLCBzdGRlcnI9c3VicHJvY2Vzcy5QSVBFLAogICAgICAgICAgICAgICAgICAg
:::ICAgICAgICAgdGV4dD1UcnVlLCBlbmNvZGluZz0ndXRmLTgnLCBlcnJvcnM9J3Jl
:::cGxhY2UnLAogICAgICAgICAgICAgICAgICAgICAgICAgICAgdGltZW91dD0zMCkK
:::ICAgICAgICAgICAgICAgICAgICAgICAgZGF0b3MgPSBqc29uLmxvYWRzKHIuc3Rk
:::b3V0IG9yICd7fScpLmdldCgnZm9ybWF0Jywge30pCiAgICAgICAgICAgICAgICAg
:::ICAgICAgIGticHMgPSBpbnQoZmxvYXQoZGF0b3MuZ2V0KCdiaXRfcmF0ZScpIG9y
:::IDApIC8gMTAwMCkKICAgICAgICAgICAgICAgICAgICAgICAgZHVyID0gZmxvYXQo
:::ZGF0b3MuZ2V0KCdkdXJhdGlvbicpIG9yIDApCiAgICAgICAgICAgICAgICAgICAg
:::ICAgIHRhbSA9IGludChmbG9hdChkYXRvcy5nZXQoJ3NpemUnKSBvciAwKSkKICAg
:::ICAgICAgICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgogICAgICAgICAgICAg
:::ICAgICAgICAgICBsb2coZifCtyB7cC5uYW1lWzo2MF19IOKAlCBubyBzZSBwdWRv
:::IGxlZXInLCAnYXZpc28nKQogICAgICAgICAgICAgICAgICAgICAgICBjb250aW51
:::ZQogICAgICAgICAgICAgICAgICAgIHRvdGFsICs9IHRhbQogICAgICAgICAgICAg
:::ICAgICAgIHRleHRvLCBuaXZlbCA9IGNsYXNlX2NhbGlkYWQocC5zdWZmaXgubG93
:::ZXIoKSwga2JwcykKICAgICAgICAgICAgICAgICAgICBpZiBuaXZlbCA9PSAyOgog
:::ICAgICAgICAgICAgICAgICAgICAgICBiYWphcyArPSAxCiAgICAgICAgICAgICAg
:::ICAgICAgdGFnID0gKCdvaycgaWYgbml2ZWwgPT0gMAogICAgICAgICAgICAgICAg
:::ICAgICAgICAgICBlbHNlICgnYXZpc28nIGlmIG5pdmVsID09IDEgZWxzZSAnZXJy
:::b3InKSkKICAgICAgICAgICAgICAgICAgICBsb2coZifCtyB7cC5uYW1lWzo1OF19
:::IOKAlCB7dGV4dG99IMK3IHtmbXRfdGllbShkdXIpfSDCtyAnCiAgICAgICAgICAg
:::ICAgICAgICAgICAgIGYne2ZtdF90YW0odGFtKX0nLCB0YWcpCiAgICAgICAgICAg
:::ICAgICBsb2coZidSZXN1bHRhZG86IHtsZW4oYXJjaGl2b3MpfSBhcmNoaXZvKHMp
:::IMK3ICcKICAgICAgICAgICAgICAgICAgICBmJ3tmbXRfdGFtKHRvdGFsKX0gZW4g
:::dG90YWwgwrcge2JhamFzfSBjb24gY2FsaWRhZCBiYWphJywKICAgICAgICAgICAg
:::ICAgICAgICAndGl0dWxvJykKICAgICAgICAgICAgICAgIGlmIGJhamFzOgogICAg
:::ICAgICAgICAgICAgICAgIGxvZygnQ29uc2VqbzogbG9zIGFyY2hpdm9zIG1hcmNh
:::ZG9zIGVuIHJvam8gc2UgcHVlZGVuICcKICAgICAgICAgICAgICAgICAgICAgICAg
:::J3ZvbHZlciBhIGRlc2NhcmdhciBjb24gbcOhcyBiaXRyYXRlLicsICdncmlzJykK
:::ICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbiBhcyBlOgogICAgICAgICAgICAg
:::ICAgbG9nKGYnRXJyb3IgYWwgY29tcHJvYmFyIGxhIGNhcnBldGE6IHtlfScsICdl
:::cnJvcicpCiAgICAgICAgICAgIGZpbmFsbHk6CiAgICAgICAgICAgICAgICBjb2xh
:::LnB1dCgoJ2ZpbicsICdjb21wcm9iYWNpb24nLCBUcnVlLCAnJykpCgogICAgICAg
:::IGRlZiBfaGlsb19hY3R1YWxpemFyKHNlbGYsIGNmZyk6CiAgICAgICAgICAgIGNv
:::bGEgPSBzZWxmLmNvbGEKCiAgICAgICAgICAgIGRlZiBsb2cobSwgdD0naW5mbycp
:::OgogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICAg
:::ICAgICAgIHRyeToKICAgICAgICAgICAgICAgIGxvZygnQWN0dWFsaXphbmRvIHl0
:::LWRscCB5IG11dGFnZW4uLi4nLCAnZ3JpcycpCiAgICAgICAgICAgICAgICBwID0g
:::c3VicHJvY2Vzcy5ydW4oCiAgICAgICAgICAgICAgICAgICAgW3N5cy5leGVjdXRh
:::YmxlLCAnLW0nLCAncGlwJywgJ2luc3RhbGwnLCAnLS11cGdyYWRlJywKICAgICAg
:::ICAgICAgICAgICAgICAgJy0tbm8td2Fybi1zY3JpcHQtbG9jYXRpb24nLCAneXQt
:::ZGxwJywgJ211dGFnZW4nXSwKICAgICAgICAgICAgICAgICAgICBzdGRvdXQ9c3Vi
:::cHJvY2Vzcy5QSVBFLCBzdGRlcnI9c3VicHJvY2Vzcy5TVERPVVQsCiAgICAgICAg
:::ICAgICAgICAgICAgdGV4dD1UcnVlLCBlbmNvZGluZz0ndXRmLTgnLCBlcnJvcnM9
:::J3JlcGxhY2UnLCB0aW1lb3V0PTYwMCkKICAgICAgICAgICAgICAgIGZvciBsbiBp
:::biAocC5zdGRvdXQgb3IgJycpLnN0cmlwKCkuc3BsaXRsaW5lcygpWy02Ol06CiAg
:::ICAgICAgICAgICAgICAgICAgbG9nKCcgICAnICsgbG5bOjE2MF0sICdncmlzJykK
:::ICAgICAgICAgICAgICAgIGlmIHAucmV0dXJuY29kZSA9PSAwOgogICAgICAgICAg
:::ICAgICAgICAgIGxvZygneXQtZGxwIGFjdHVhbGl6YWRvLiBSZWluaWNpYSBsYSBh
:::cGxpY2FjacOzbiBwYXJhICcKICAgICAgICAgICAgICAgICAgICAgICAgJ3VzYXIg
:::bGEgdmVyc2nDs24gbnVldmEuJywgJ29rJykKICAgICAgICAgICAgICAgIGVsc2U6
:::CiAgICAgICAgICAgICAgICAgICAgbG9nKCdMYSBhY3R1YWxpemFjacOzbiBmYWxs
:::w7MgKMK/c2luIGludGVybmV0PykuJywgJ2Vycm9yJykKICAgICAgICAgICAgZXhj
:::ZXB0IEV4Y2VwdGlvbiBhcyBlOgogICAgICAgICAgICAgICAgbG9nKGYnTm8gc2Ug
:::cHVkbyBlamVjdXRhciBwaXA6IHtlfScsICdlcnJvcicpCiAgICAgICAgICAgIGZp
:::bmFsbHk6CiAgICAgICAgICAgICAgICBjb2xhLnB1dCgoJ2ZpbicsICdhY3R1YWxp
:::emFjaW9uJywgVHJ1ZSwgJycpKQoKICAgICAgICBkZWYgX21zZ19lcnJvcihzZWxm
:::LCBlKToKICAgICAgICAgICAgbGluZWFzID0gW2wgZm9yIGwgaW4gc3RyKGUpLnN0
:::cmlwKCkuc3BsaXRsaW5lcygpIGlmIGwuc3RyaXAoKV0KICAgICAgICAgICAgcmV0
:::dXJuIChsaW5lYXNbMF1bOjI1MF0gaWYgbGluZWFzCiAgICAgICAgICAgICAgICAg
:::ICAgZWxzZSBmJ3t0eXBlKGUpLl9fbmFtZV9ffTogc2luIGRldGFsbGVzJykKCiAg
:::ICAgICAgIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0gYXJyYW5xdWUKICAgICAgICBkZWYgX2FycmFucXVlKHNlbGYpOgog
:::ICAgICAgICAgICBzZWxmLl9sb2coZidNdXNpa0FMQU4gdntBUFBfVn0nLCAndGl0
:::dWxvJykKICAgICAgICAgICAgc2VsZi5fbG9nKCdDdHJsK1U6IGFjdHVhbGl6YXIg
:::eXQtZGxwIMK3IEN0cmwrTDogbGltcGlhciByZWdpc3RybycsCiAgICAgICAgICAg
:::ICAgICAgICAgICAnZ3JpcycpCiAgICAgICAgICAgIHRocmVhZGluZy5UaHJlYWQo
:::dGFyZ2V0PXNlbGYuX2hpbG9fdmVyc2lvbiwgZGFlbW9uPVRydWUpLnN0YXJ0KCkK
:::CiAgICAgICAgZGVmIF9oaWxvX3ZlcnNpb24oc2VsZik6CiAgICAgICAgICAgIGNv
:::bGEgPSBzZWxmLmNvbGEKCiAgICAgICAgICAgIGRlZiBsb2cobSwgdD0naW5mbycp
:::OgogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdsb2cnLCBtLCB0KSkKCiAgICAg
:::ICAgICAgIGlmIFlUX0RMUCBpcyBOb25lOgogICAgICAgICAgICAgICAgbG9nKCd5
:::dC1kbHAgbm8gZXN0w6EgaW5zdGFsYWRvLiBFamVjdXRhICcKICAgICAgICAgICAg
:::ICAgICAgICAnRGVzY2FyZ2Fkb3JNdXNpY2EuYmF0IHBhcmEgaW5zdGFsYXJsby4n
:::LCAnZXJyb3InKQogICAgICAgICAgICAgICAgY29sYS5wdXQoKCdmaW4nLCAndmVy
:::c2lvbicsIFRydWUsICcnKSkKICAgICAgICAgICAgICAgIHJldHVybgogICAgICAg
:::ICAgICB0cnk6CiAgICAgICAgICAgICAgICBpbnN0YWxhZGEgPSBZVF9ETFAudmVy
:::c2lvbi5fX3ZlcnNpb25fXwogICAgICAgICAgICBleGNlcHQgRXhjZXB0aW9uOgog
:::ICAgICAgICAgICAgICAgaW5zdGFsYWRhID0gJz8nCiAgICAgICAgICAgIHVsdGlt
:::YSA9IE5vbmUKICAgICAgICAgICAgdHJ5OgogICAgICAgICAgICAgICAgd2l0aCB1
:::cmxvcGVuKCdodHRwczovL3B5cGkub3JnL3B5cGkveXQtZGxwL2pzb24nLCB0aW1l
:::b3V0PTEyKSBhcyByOgogICAgICAgICAgICAgICAgICAgIHVsdGltYSA9IGpzb24u
:::bG9hZHMoci5yZWFkKCkuZGVjb2RlKCd1dGYtOCcpKVsnaW5mbyddWyd2ZXJzaW9u
:::J10KICAgICAgICAgICAgZXhjZXB0IEV4Y2VwdGlvbjoKICAgICAgICAgICAgICAg
:::IHVsdGltYSA9IE5vbmUKICAgICAgICAgICAgaWYgdWx0aW1hIGlzIE5vbmU6CiAg
:::ICAgICAgICAgICAgICBsb2coZid5dC1kbHA6IHZlcnNpw7NuIHtpbnN0YWxhZGF9
:::ICcKICAgICAgICAgICAgICAgICAgICAnKG5vIHNlIHB1ZG8gY29tcHJvYmFyIHNp
:::IGhheSBub3ZlZGFkZXMpLicsICdncmlzJykKICAgICAgICAgICAgZWxpZiBzdHIo
:::dWx0aW1hKSA9PSBzdHIoaW5zdGFsYWRhKToKICAgICAgICAgICAgICAgIGxvZyhm
:::J3l0LWRscDogZW4gbGEgdWx0aW1hIHZlcnNpb24gKHtpbnN0YWxhZGF9KS4nLCAn
:::aW5mbycpCiAgICAgICAgICAgIGVsc2U6CiAgICAgICAgICAgICAgICBsb2coZid5
:::dC1kbHA6IGhheSB2ZXJzaW9uIG51ZXZhICh7dWx0aW1hfSk7IGluc3RhbGFkYTog
:::JwogICAgICAgICAgICAgICAgICAgIGYne2luc3RhbGFkYX0uIFB1bHNhIEN0cmwr
:::VSBwYXJhIGFjdHVhbGl6YXIuJywgJ2F2aXNvJykKICAgICAgICAgICAgaWYgRkZN
:::UEVHIGlzIE5vbmU6CiAgICAgICAgICAgICAgICBsb2coJ0ZGbXBlZzogTk8gRU5D
:::T05UUkFETyDigJQgZWplY3V0YSBEZXNjYXJnYWRvck11c2ljYS5iYXQgJwogICAg
:::ICAgICAgICAgICAgICAgICdwYXJhIGluc3RhbGFybG8uJywgJ2Vycm9yJykKICAg
:::ICAgICAgICAgZWxzZToKICAgICAgICAgICAgICAgIGxvZyhmJ0ZGbXBlZzogT0sg
:::KHtGRk1QRUd9KScsICdncmlzJykKICAgICAgICAgICAgbG9nKCdDYXJwZXRhIGRl
:::IGd1YXJkYWRvOiAnICsgc3RyKEFKVVNURVMuZ2V0KCdkZXN0aW5vJykpLCAnZ3Jp
:::cycpCiAgICAgICAgICAgIGNvbGEucHV0KCgnZmluJywgJ3ZlcnNpb24nLCBUcnVl
:::LCAnJykpCgoKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:::LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIG1haW4KZGVmIG1haW4oKToKICAg
:::IF9yZWNvbmZpZ3VyYXJfc2FsaWRhKCkKICAgIGlmIG5vdCBUS19PSzoKICAgICAg
:::ICBwcmludCgnRXN0YSBhcGxpY2FjacOzbiBuZWNlc2l0YSBUa2ludGVyIChpbnRl
:::cmZheiBncsOhZmljYSkuJykKICAgICAgICBwcmludCgnRWwgUHl0aG9uIGFjdHVh
:::bCBubyBsbyBpbmNsdXllLicpCiAgICAgICAgcHJpbnQoJ1Z1ZWx2ZSBhIGVqZWN1
:::dGFyIERlc2NhcmdhZG9yTXVzaWNhLmJhdCBwYXJhIGluc3RhbGFyIGVsICcKICAg
:::ICAgICAgICAgICAnUHl0aG9uIGFkZWN1YWRvLicpCiAgICAgICAgcmV0dXJuIDEK
:::ICAgIGNvbXByb2Jhcl9lbnRvcm5vKCkKICAgIGFwcCA9IEFwcCgpCiAgICBhcHAu
:::bWFpbmxvb3AoKQogICAgcmV0dXJuIDAKCgppZiBfX25hbWVfXyA9PSAnX19tYWlu
:::X18nOgogICAgdHJ5OgogICAgICAgIHN5cy5leGl0KG1haW4oKSkKICAgIGV4Y2Vw
:::dCBTeXN0ZW1FeGl0OgogICAgICAgIHJhaXNlCiAgICBleGNlcHQgQmFzZUV4Y2Vw
:::dGlvbjoKICAgICAgICB0cnk6CiAgICAgICAgICAgIHdpdGggb3BlbihMT0dfRVJS
:::T1JFUywgJ2EnLCBlbmNvZGluZz0ndXRmLTgnKSBhcyBmaDoKICAgICAgICAgICAg
:::ICAgIGZoLndyaXRlKHRyYWNlYmFjay5mb3JtYXRfZXhjKCkgKyAnXG4nKQogICAg
:::ICAgIGV4Y2VwdCBFeGNlcHRpb246CiAgICAgICAgICAgIHBhc3MKICAgICAgICBy
:::YWlzZQo=
