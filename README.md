# YouTube Downloader (Descargador de Música)

Aplicación de escritorio para Windows que descarga música y videos de YouTube
en formatos aptos para reproductores portátiles antiguos (tipo *sheiju* MP3 de
1.8" con pantalla 128x160). Todo-in-uno: un único `DescargadorMusica.bat`
instala lo que falte **sin permisos de administrador** y abre la ventana de
descargas.

![Interfaz](gui_v2_oscuro.png)

## Características

- Interfaz gráfica (Tkinter) con tema **Oscuro / Claro**
- Formatos: **AAC (.m4a) 128k** · **MP3 128/192/256/320k** · **FLAC** · **WAV** ·
  **WMA 128k** · **AVI (sheiju 1.8" 128x160, MJPEG 16 fps + PCM 22050 Hz)**
- Calidad seleccionable por formato en un desplegable
- Carpeta de destino configurable (se recuerda en `ajustes.json`)
- Casilla para embeber **carátula, artista y álbum** (vía yt-dlp + mutagen)
- **Cookies del navegador** (brave, chrome, firefox, edge, opera, etc.) para
  videos con restricción de edad/sesión
- **Estimación de tamaño** antes de descargar (por duración del video)
- **Comprobador de calidad de carpeta** con ffprobe: lista bitrate, duración y
  tamaño de cada archivo y marca los de bitrate bajo
- Barra de progreso con %, velocidad y tiempo restante + registro de actividad
- Solo videos individuales: si la URL trae `list=`, la lista se ignora
- Instalación 100% portable y sin admin: Python build standalone + yt-dlp +
  mutagen + FFmpeg (gyan.dev/BtbN) en carpetas locales
- Comprobación de versión de yt-dlp contra PyPI al arrancar y actualización
  integrada (Ctrl+U)

## Uso

1. Descarga `DescargadorMusica.bat` (el archivo ya lleva el código embebido en
   base64).
2. Doble clic. La primera vez descarga Python portátil (~42 MB), yt-dlp y
   FFmpeg (~90 MB) si no los tienes. Solo necesita internet esa primera vez.
3. Pega la URL, elige formato/calidad y pulsa **Descargar y convertir**.

Las descargas quedan en `Música\YTDownloader\<FORMATO>\` (carpeta cambiable).

## Formato AVI para reproductor sheiju 1.8"

El AVI usa los parámetros oficiales del repositorio
[fdd4s/portable_mp3_player_video_converter_tools](https://github.com/fdd4s/portable_mp3_player_video_converter_tools)
(script `video2shenju18.sh`):

```bash
ffmpeg -i entrada -vf "scale=-2:128, crop=160:128, transpose=2, vflip" \
       -r 16 -acodec pcm_s16le -ac 2 -ar 22050 -pix_fmt yuvj420p \
       -c:v mjpeg -q:v 2 salida.avi
```

Para videos cuadrados/verticales (Shorts) existe un modo compatible con
letterbox que se aplica automáticamente.

## Estructura del repositorio

```
├── DescargadorMusica.bat    ← entregable final (instalador + app)
├── LEEME.txt                ← manual de usuario
├── codigo_fuente/
│   ├── descargador.py       ← aplicación (Tkinter + yt-dlp + FFmpeg)
│   ├── plantilla_bat.txt    ← plantilla del instalador
│   ├── empaquetar.py        ← build: inserta descargador.py en el BAT
│   └── probar_payload.py    ← test: round-trip del payload base64
└── README.md
```

## Desarrollo

Editar la interfaz y regenerar el BAT único:

```bash
cd codigo_fuente
python empaquetar.py                 # genera ../DescargadorMusica.bat
python probar_payload.py ../DescargadorMusica.bat descargador.py
```

`empaquetar.py` codifica `descargador.py` en base64 (líneas de 64 columnas con
prefijo `:::`); el BAT lo extrae con `findstr` + `certutil -f -decode`, de modo
que el ejecutable final es un solo archivo compartible por WhatsApp/Drive/USB.

## Requisitos

- Windows 10 1803+ (32-bit, 64-bit o ARM64). No funciona en Windows 7.
- Internet solo la primera ejecución.

## Aviso

Descarga solo contenido cuyo uso te corresponda (tus propios videos, material
con licencia libre, etc.). Respeta los términos de servicio y los derechos de
autor de tu país.
