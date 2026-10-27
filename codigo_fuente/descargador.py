#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
MusikALAN — interfaz grafica (Tkinter) para yt-dlp + FFmpeg
=======================================================================
App de escritorio para descargar musica y videos de YouTube en formatos
aptos para reproductores portatiles antiguos (tipo "sheiju" MP3 de 1.8"
pulgadas y pantalla 128x160):

  · AAC  (.m4a)  96 / 128 kbps
  · MP3  (.mp3)  96 / 128 / 192 / 256 / 320 kbps (desplegable "Calidad")
  · FLAC (.flac) sin perdida
  · WAV  (.wav)  sin perdida (archivos grandes)
  · WMA  (.wma)  96 / 128 kbps (codificador wmav2 de FFmpeg, con caratula
                 y URL incrustadas via mutagen: WM/Picture + WM/AuthorURL)
  · AVI  (.avi)  video recodificado para el reproductor sheiju 1.8"
                 128x160, con los parametros oficiales del repositorio
                 github.com/fdd4s/portable_mp3_player_video_converter_tools
                 (script video2shenju18.sh)

La instalacion de Python, yt-dlp y FFmpeg la hace automaticamente el
archivo DescargadorMusica.bat; este script es la ventana que se usa a
diario (tema oscuro/claro, estimacion de tamano y comprobador de
calidad de la carpeta). La carpeta de guardado por defecto es la
carpeta Musica de Windows, y los archivos van directos a ella, sin
subcarpetas por formato. Tras cada descarga se escriben las etiquetas
del archivo (artista sin el sufijo " - Topic", album, titulo, ano, URL)
en el MISMO formato binario que usa FFmpeg en los MP3 que los
reproductores baratos SI leen (ID3v2.4 + textos UTF-16 con BOM,
verificado contra un MP3 real descargado con Snaptube), y la caratula
SIEMPRE se incrusta en JPEG: la miniatura de YouTube viene en WebP y
muchos reproductores solo leen JPEG (igual que --convert-thumbnails
jpg del comando antiguo, que es lo que si funcionaba).

Desde la v2.7 TODOS los formatos llevan las etiquetas en su forma
estandar y verificada: ID3v2.4 + UTF-16 en .mp3, atomos MP4 (©nam,
©ART, ©alb, covr...) en .m4a como iTunes, ID3 dentro del RIFF en
.wav, Vorbis + Picture en .flac, ASF (Title/Author/WM/*) en .wma y
RIFF INFO (INAM/IART/IPRD) en .avi. La caratula se escribe SIEMPRE
con mutagen, nunca via EmbedThumbnail de yt-dlp: sus metodos
internos cambian entre versiones y fueron la fuente de portadas
PNG/mal convertidas que hacian que los reproductores baratos
descartaran tambien artista y album.

Uso:  python descargador.py   (o doble clic en DescargadorMusica.bat)
Si la URL pertenece a una lista de reproduccion, el programa pregunta
si bajar solo la cancion pegada o la playlist completa (con una pausa
de 2 s entre canciones para no saturar a YouTube).
"""

import json
import os
import queue
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time
import traceback
from pathlib import Path
from urllib.parse import parse_qs, urlencode, urlparse, urlunparse
from urllib.request import urlopen

APP_V = '2.10'
APP_DIR = Path(__file__).resolve().parent
RUTA_AJUSTES = APP_DIR / 'ajustes.json'
LOG_ERRORES = APP_DIR / 'descargador_errores.log'

# ---------------------------------------------------------------- salida
# Al ejecutarse con pythonw.exe (sin consola) stdout/stderr son None:
# cualquier print fallaria. Los redirigimos a un sitio seguro.
try:
    if sys.stdout is None:
        sys.stdout = open(os.devnull, 'w', encoding='utf-8')
except Exception:
    pass
try:
    if sys.stderr is None:
        sys.stderr = open(LOG_ERRORES, 'a', encoding='utf-8')
except Exception:
    pass


def _reconfigurar_salida():
    """Evita crashes por caracteres raros si la salida se redirige."""
    for s in (sys.stdout, sys.stderr):
        try:
            if s and hasattr(s, 'reconfigure'):
                s.reconfigure(errors='replace')
        except Exception:
            pass


# ---------------------------------------------------------------- tkinter
try:
    import tkinter as tk
    from tkinter import filedialog, messagebox, ttk
    from tkinter.scrolledtext import ScrolledText
    TK_OK = True
except Exception:
    TK_OK = False


# ---------------------------------------------------------------- ajustes
def _carpeta_musica():
    """Carpeta 'Musica' real del usuario (FOLDERID_Music de Windows)."""
    if os.name == 'nt':
        try:
            import ctypes

            class _GUID(ctypes.Structure):
                _fields_ = [('D1', ctypes.c_ulong), ('D2', ctypes.c_ushort),
                            ('D3', ctypes.c_ushort),
                            ('D4', ctypes.c_ubyte * 8)]

            musica = _GUID(0x4BD8D571, 0x6D19, 0x48D3,
                           (ctypes.c_ubyte * 8)(0xBE, 0x97, 0x03, 0x38,
                                                0x5F, 0x7F, 0xC5, 0xCE))
            ptr = ctypes.c_wchar_p()
            if ctypes.windll.shell32.SHGetKnownFolderPath(
                    ctypes.byref(musica), 0, None,
                    ctypes.byref(ptr)) == 0 and ptr.value:
                ruta = ptr.value
                ctypes.windll.ole32.CoTaskMemFree(ptr)
                return ruta
        except Exception:
            pass
    return str(Path.home() / 'Music')


def _destino_appdata_viejo():
    """Carpeta del programa (era el destino por defecto en la v2.2)."""
    base = os.environ.get('APPDATA') or str(Path.home() / 'AppData' / 'Roaming')
    return str(Path(base) / 'MusikALAN')


def _destino_por_defecto():
    """Los archivos se guardan en la carpeta Musica del usuario."""
    return _carpeta_musica()


AJUSTES_DEFECTO = {
    'destino': _destino_por_defecto(),
    'tema': 'Oscuro',
    'formato': 'AAC',
    'calidad': '128k',
    'embeber': True,
    'cookies': '',    # v2.9: navegador cuyas cookies usar si YouTube bloquea
}


def cargar_ajustes():
    a = dict(AJUSTES_DEFECTO)
    try:
        a.update(json.loads(RUTA_AJUSTES.read_text(encoding='utf-8')))
    except Exception:
        pass
    a.pop('navegador', None)  # v2.2 o anterior: la seccion de cookies ya no existe
    # migraciones del destino de guardado:
    #  · v2.0/2.1 usaba Music/YTDownloader
    #  · v2.2 usaba la carpeta del programa (AppData\Roaming\MusikALAN)
    # Desde la v2.3 el destino por defecto es la carpeta Musica del usuario,
    # asi que si el ajuste apunta a cualquiera de los dos, se actualiza.
    destino = str(a.get('destino') or '').replace('\\', '/').rstrip('/').lower()
    if 'ytdownloader' in destino:
        a['destino'] = AJUSTES_DEFECTO['destino']
    else:
        viejo = _destino_appdata_viejo().replace('\\', '/').rstrip('/').lower()
        if destino and (destino == viejo
                        or destino.startswith(viejo + '/')):
            a['destino'] = AJUSTES_DEFECTO['destino']
    return a


def guardar_ajustes():
    try:
        RUTA_AJUSTES.write_text(
            json.dumps(AJUSTES, ensure_ascii=False, indent=2),
            encoding='utf-8')
    except Exception:
        pass


AJUSTES = cargar_ajustes()


# ---------------------------------------------------------------- utils
def fmt_tam(n):
    if not n:
        return '—'
    n = float(n)
    for u in ('B', 'KiB', 'MiB', 'GiB'):
        if n < 1024 or u == 'GiB':
            return f'{int(n)} {u}' if u == 'B' else f'{n:.1f} {u}'
        n /= 1024


def fmt_tiem(s):
    if s is None:
        return '—'
    s = int(s)
    h, r = divmod(s, 3600)
    m, x = divmod(r, 60)
    return f'{h}:{m:02d}:{x:02d}' if h else f'{m:02d}:{x:02d}'


def limpiar_nombre(t):
    t = re.sub(r'[<>:"/\\|?*\x00-\x1f]', '_', str(t)).strip(' .')
    return t[:150] or 'sin_titulo'


def sin_playlist(url):
    """Quita el parámetro list= de la URL (modo solo video)."""
    try:
        p = urlparse(url)
        q = parse_qs(p.query)
        if 'list' in q:
            del q['list']
            return urlunparse(p._replace(query=urlencode(q, doseq=True))), True
    except Exception:
        pass
    return url, False


def es_url_playlist(url):
    """True si la URL pertenece a una lista de reproducción (lleva list=)."""
    try:
        return 'list' in parse_qs(urlparse(url).query)
    except Exception:
        return False


def es_solo_lista(url):
    """True si la URL es una playlist pura, sin video individual (sin v=)."""
    try:
        p = urlparse(url)
        if 'v' in parse_qs(p.query) or 'youtu.be' in (p.netloc or ''):
            return False
        return (p.path or '').rstrip('/').endswith('/playlist')
    except Exception:
        return False


def abrir_carpeta(ruta):
    try:
        if os.name == 'nt':
            os.startfile(str(ruta))  # noqa: solo Windows
        else:
            subprocess.Popen(['xdg-open', str(ruta)])
    except Exception:
        pass


# ---------------------------------------------------------------- ffmpeg
def buscar_ffmpeg():
    exe = shutil.which('ffmpeg')
    if exe:
        return Path(exe)
    candidatos = [
        APP_DIR / 'ffmpeg' / 'bin' / 'ffmpeg.exe',
        APP_DIR / 'ffmpeg' / 'bin' / 'ffmpeg',
        APP_DIR / 'runtime' / 'ffmpeg.exe',
    ]
    for p in candidatos:
        if p.exists():
            return p
    return None


def buscar_ffprobe(ffmpeg):
    if ffmpeg is None:
        return shutil.which('ffprobe')
    p = ffmpeg.with_name('ffprobe.exe' if os.name == 'nt' else 'ffprobe')
    if p.exists():
        return p
    return shutil.which('ffprobe')


YT_DLP = None   # módulo yt_dlp; se rellena en comprobar_entorno()
FFMPEG = None   # ruta de ffmpeg
FFPROBE = None  # ruta de ffprobe


def comprobar_entorno():
    global YT_DLP, FFMPEG, FFPROBE
    try:
        import yt_dlp as mod
        YT_DLP = mod
    except Exception:
        pass
    FFMPEG = buscar_ffmpeg()
    FFPROBE = buscar_ffprobe(FFMPEG)


class Registro:
    """Logger para yt-dlp: reenvía avisos/errores al registro de la GUI."""

    def __init__(self):
        self.log = None  # la GUI lo conecta: log(mensaje, etiqueta)

    def debug(self, m):
        pass

    # Avisos internos de yt-dlp que solo meten ruido en el registro:
    AVISOS_RUIDOSOS = ('No supported JavaScript runtime', 'EJS')

    def warning(self, m):
        m = str(m).strip()
        if not m or any(x in m for x in self.AVISOS_RUIDOSOS):
            return
        if self.log:
            self.log(m, 'aviso')

    def error(self, m):
        m = str(m).strip()
        if m and self.log:
            self.log(m, 'error')


REGISTRO = Registro()

NOMBRES_PP = {
    'FFmpegExtractAudio': 'Convirtiendo el audio con FFmpeg',
    'FFmpegThumbnailsConvertor': 'Convirtiendo la carátula a JPG',
    'FFmpegMetadata': 'Escribiendo etiquetas (título/artista)',
    'EmbedThumbnail': 'Incrustando la carátula',
    'MoveFiles': 'Organizando archivos',
    'FFmpegMerger': 'Uniendo pistas de video y audio',
    'FFmpegVideoConvertor': 'Convirtiendo el video',
}

# ---------------------------------------------------------------- formatos
FORMATOS = {
    'AAC': dict(texto='AAC (.m4a)', ext='m4a',
                calidades=['96k', '128k'], defecto='128k'),
    'MP3': dict(texto='MP3 (.mp3)', ext='mp3',
                calidades=['96k', '128k', '192k', '256k', '320k'],
                defecto='320k'),
    'FLAC': dict(texto='FLAC (.flac)', ext='flac',
                 calidades=['sin perdida'], defecto='sin perdida'),
    'WAV': dict(texto='WAV (.wav)', ext='wav',
                calidades=['sin perdida'], defecto='sin perdida'),
    'WMA': dict(texto='WMA (.wma)', ext='wma',
                calidades=['96k', '128k'], defecto='128k'),
    'AVI': dict(texto='AVI - sheiju 1.8" (128x160)', ext='avi',
                calidades=['128x160 · 16 fps'], defecto='128x160 · 16 fps'),
}


# ---------------------------------------------------------------- progreso
def hooks_gui(cola):
    """Crea los hooks de yt-dlp que publican eventos en la cola de la GUI."""
    estado = {'titulo': False, 'pp_ult': None}

    def log(m, t='info'):
        cola.put(('log', m, t))

    def progreso(d):
        if d['status'] == 'downloading':
            if not estado['titulo']:
                info = d.get('info_dict') or {}
                t = info.get('title') or Path(d.get('filename') or '').stem
                if t:
                    log('♪ ' + str(t)[:90], 'titulo')
                    estado['titulo'] = True
            total = d.get('total_bytes') or d.get('total_bytes_estimate') or 0
            done = d.get('downloaded_bytes', 0)
            vel = d.get('speed')
            eta = d.get('eta')
            if total:
                pct = done / total * 100
                texto = f'{pct:5.1f}% · {fmt_tam(done)} / {fmt_tam(total)}'
                if vel:
                    texto += f' · {fmt_tam(vel)}/s'
                if eta is not None:
                    texto += f' · quedan {fmt_tiem(eta)}'
                cola.put(('prog', pct, texto))
            else:
                v = f'{fmt_tam(vel)}/s' if vel else ''
                cola.put(('prog', None, f'{fmt_tam(done)} · {v}'))
        elif d['status'] == 'finished':
            estado['pp_ult'] = None
            cola.put(('log', 'Descarga recibida. Procesando...', 'gris'))
            cola.put(('prog', 0, 'Procesando...'))

    def postproceso(d):
        if d['status'] == 'started':
            nom = (d.get('postprocessor_name')
                   or d.get('postprocessor') or 'Postproceso')
            if nom == estado['pp_ult']:
                return  # yt-dlp a veces anuncia el mismo paso dos veces
            estado['pp_ult'] = nom
            texto = NOMBRES_PP.get(nom, nom) + '...'
            cola.put(('log', '→ ' + texto, 'gris'))
            cola.put(('prog', None, texto))

    return progreso, postproceso


# ------------------------------------------- anti-bloqueo de YouTube (v2.9)
# Cuando YouTube desconfía de una red (wifi compartido, datos móviles, VPN
# o muchas descargas seguidas) responde a los clientes web con "Sign in to
# confirm you're not a bot" o HTTP 429. Defensa en capas:
#   1) Por defecto los formatos se piden con los clientes de las APPS
#      móviles (android/ios/mweb), que en la mayoría de las redes no pasan
#      por ese chequeo.
#   2) Si aun así YouTube insiste, la descarga se reintenta UNA vez sola
#      con el combo 2 (android_vr/android/ios, sin clientes web) tras una
#      pequeña pausa para dejar enfriar el 429.
#   3) Última línea: el desplegable "Si YouTube bloquea:" permite usar las
#      COOKIES del navegador del usuario (con sesión abierta YouTube no
#      pide verificación). Es la vía oficial recomendada por yt-dlp.
COMBOS_ANTI_BOT = (
    ('android', 'ios', 'mweb'),
    ('android_vr', 'android', 'ios'),
)
NAVEGADORES_COOKIES = ('firefox', 'chrome', 'edge', 'brave', 'opera',
                       'vivaldi')
_ANTI_BOT = {'combo': 0}      # combo en curso (dict mutable = global)


def _anti_bot(o):
    """Inyecta en las opciones de yt-dlp la vía anti-bloqueo en curso."""
    o['extractor_args'] = {'youtube': {'player_client':
                          list(COMBOS_ANTI_BOT[_ANTI_BOT['combo']])}}
    o['forceipv4'] = True
    navegador = str(AJUSTES.get('cookies', '') or '').strip().lower()
    if navegador in NAVEGADORES_COOKIES:
        o['cookiesfrombrowser'] = (navegador,)
    return o


def _es_bloqueo_bot(texto):
    """True si el error de yt-dlp es el chequeo anti-bot o un 429."""
    t = (texto or '').lower()
    return ('not a bot' in t or 'sign in to confirm' in t
            or 'too many requests' in t or 'http error 429' in t
            or ' error 429' in t)


# ---------------------------------------------------------------- opciones
def opts_base(carpeta, cola):
    progreso, postproceso = hooks_gui(cola)
    o = {
        'outtmpl': str(carpeta / '%(title)s.%(ext)s'),
        'quiet': True,
        'no_warnings': True,
        'noprogress': True,
        'noplaylist': True,
        'ignoreerrors': False,
        'retries': 10,
        'fragment_retries': 10,
        'socket_timeout': 30,
        'concurrent_fragment_downloads': 4,
        'windowsfilenames': True,
        'overwrites': False,
        'logger': REGISTRO,
        'progress_hooks': [progreso],
        'postprocessor_hooks': [postproceso],
    }
    if FFMPEG:
        o['ffmpeg_location'] = str(FFMPEG.parent)
    _anti_bot(o)
    return o


def convertir_ffmpeg(cmd, etiqueta, cola):
    """Ejecuta FFmpeg (lista de argumentos, sin shell) con marquee."""
    cola.put(('prog', None, etiqueta))

    def log(m, t='info'):
        cola.put(('log', m, t))

    try:
        p = subprocess.run(cmd, stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, text=True,
                           encoding='utf-8', errors='replace')
    except FileNotFoundError:
        p = None
    if p is None or p.returncode != 0:
        log('✖ FFmpeg devolvió un error:', 'error')
        if p is not None:
            for ln in (p.stderr or '').strip().splitlines()[-4:]:
                log('   ' + ln[:180], 'gris')
        cola.put(('prog', 0, ''))
        return False
    return True


def archivo_final(info, carpeta, ext):
    """Localiza el archivo resultante (yt-dlp lo reporta; fallback: más nuevo)."""
    try:
        for d in (info.get('requested_downloads') or []):
            f = d.get('filepath')
            if f:
                return Path(f)
    except Exception:
        pass
    cand = sorted(carpeta.glob('*.' + ext),
                  key=lambda p: p.stat().st_mtime, reverse=True)
    return cand[0] if cand else None


def limpiar_miniaturas(carpeta, archivo):
    """Borra miniaturas sueltas que EmbedThumbnail dejara sin incrustar."""
    for ext in ('.webp', '.jpg', '.jpeg', '.png'):
        t = archivo.with_suffix(ext)
        if t.exists():
            try:
                t.unlink()
            except OSError:
                pass


def _miniatura_bytes(carpeta, archivo):
    """Lee los bytes de la miniatura que yt-dlp dejo junto al archivo final."""
    if not archivo:
        return None
    for ext in ('.jpg', '.jpeg', '.webp', '.png'):
        t = archivo.with_suffix(ext)
        if t.exists():
            try:
                return t.read_bytes()
            except OSError:
                pass
    return None


def _es_jpg(datos):
    return bool(datos) and datos[:3] == b'\xff\xd8\xff'


def _a_jpg(datos):
    """Convierte los bytes de una imagen (webp/png/...) a JPEG con FFmpeg.

    Los reproductores baratos (tipo sheiju) suelen leer solo JPEG: la
    miniatura de YouTube viene en WebP y EmbedThumbnail de yt-dlp la
    convierte a PNG ("PNG is preferred since JPEG is lossy"), asi que
    aqui nos aseguramos nosotros de que acabe en JPEG."""
    if not datos or not FFMPEG:
        return None
    base = Path(tempfile.gettempdir()) / ('musikalan_caratula_%d' % os.getpid())
    origen, destino = base.with_suffix('.orig'), base.with_suffix('.jpg')
    try:
        origen.write_bytes(datos)
        r = subprocess.run(
            [str(FFMPEG), '-y', '-loglevel', 'error', '-i', str(origen),
             '-q:v', '2', str(destino)],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if r.returncode == 0 and destino.exists():
            jpg = destino.read_bytes()
            if _es_jpg(jpg):
                return jpg
    except Exception:
        pass
    finally:
        for f in (origen, destino):
            try:
                f.unlink()
            except OSError:
                pass
    return None


def _wm_picture(jpg, descripcion=''):
    """Empaqueta unos bytes JPEG en el atributo WM/Picture del contenedor
    ASF (tipo 3 = portada frontal), como hacia el script antiguo."""
    def u16(s):
        return str(s).encode('utf-16-le') + b'\x00\x00'

    mime = u16('image/jpeg')
    desc = u16(descripcion)
    return (b'\x03' + len(mime).to_bytes(4, 'little') + mime
            + len(desc).to_bytes(4, 'little') + desc + jpg)


def _moov_primero(ruta):
    """True si el atomo 'moov' esta ANTES que 'mdat' entre las cajas
    top-level del MP4/M4A (el orden 'faststart' de iTunes). Solo lee
    la cabecera (4 MB) con un pase de tamanos: no carga el archivo."""
    try:
        with open(ruta, 'rb') as fh:
            cab = fh.read(4 << 20)
    except OSError:
        return False
    pos, fin = 0, len(cab)
    while pos + 8 <= fin:
        tipo = cab[pos + 4:pos + 8]
        if tipo in (b'moov', b'mdat'):
            return tipo == b'moov'
        size = int.from_bytes(cab[pos:pos + 4], 'big')
        if size == 1:                       # largesize de 64 bits
            if pos + 16 > fin:
                return False
            size = int.from_bytes(cab[pos + 8:pos + 16], 'big')
            if size < 16:
                return False
        elif size < 8:                      # caja rota o EOF
            return False
        pos += size
    return False


def _moov_al_principio(p):
    """v2.8: deja el atomo moov (que lleva las etiquetas) al PRINCIPIO
    del .m4a, como hace iTunes ('faststart').

    FFmpeg escribe el M4A con moov AL FINAL, detras de todo el audio
    (mdat). El MP3 de referencia que el reproductor del usuario si lee
    lleva su ID3v2 al inicio del archivo, y los reproductores baratos
    suelen buscar las etiquetas escaneando solo la cabecera del
    archivo: por eso mostraban 'unknown' aunque el M4A estuviera
    perfectamente etiquetado (atoms ilst estandar, verificado en
    v2.7). Con -movflags +faststart el moov entero (y dentro
    moov.udta.meta.ilst con titulo/artista/album/covr) pasa delante
    del mdat SIN recodificar nada (-c copy). Si algo falla se devuelve
    False y el archivo queda como estaba: esto nunca debe romper la
    descarga ni las etiquetas ya escritas."""
    if not FFMPEG or _moov_primero(p):
        return False
    tmp = p.with_name(p.stem + '.faststart.m4a')
    try:
        r = subprocess.run(
            [str(FFMPEG), '-y', '-loglevel', 'error', '-i', str(p),
             '-map', '0', '-c', 'copy', '-movflags', '+faststart',
             str(tmp)],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if (r.returncode == 0 and tmp.exists()
                and _moov_primero(tmp)
                and tmp.stat().st_size * 100
                >= p.stat().st_size * 90):
            os.replace(tmp, p)
            return True
    except Exception:
        pass
    finally:
        try:
            tmp.unlink()
        except OSError:
            pass
    return False


# ---------------------------------------------------------------- etiquetas
def _artista_limpio(info):
    """Nombre del artista legible para reproductores.

    Los canales automaticos de musica de YouTube se llaman 'X - Topic';
    ese sufijo sobra cuando se ve en la pantalla de un reproductor."""
    a = (info.get('artist') or info.get('creator')
         or info.get('uploader') or info.get('channel') or '')
    a = str(a).strip()
    a = re.sub(r'\s*-\s*Topic\s*$', '', a, flags=re.I).strip()
    return a


def _album_de(info):
    """Album para el archivo final.

    yt-dlp solo escribe album si el propio video lo trae (casi nunca):
    por eso los reproductores mostraban 'album desconocido'. Orden de
    preferencia: album real -> nombre de la playlist -> artista."""
    for clave in ('album', 'playlist_title'):
        v = str(info.get(clave) or '').strip()
        if v:
            return v
    return _artista_limpio(info) or 'YouTube'


def aplicar_tags(info, archivo, log=None, caratula=None):
    """Escribe con mutagen las etiquetas del archivo final.

    Garantiza que TODOS los reproductores muestren artista y album,
    aunque FFmpegMetadata de yt-dlp no los haya escrito. Cada formato
    con SU forma estandar:
      · MP3: ID3v2.4 con textos UTF-16 (encoding=1) y APIC(mime
        'image/jpg', tipo 3, desc 'attached picture'), calcado del
        MP3 de referencia que el reproductor del usuario muestra
        bien. El pase antiguo usaba encoding=3 (UTF-8) dentro de un
        tag v2.3: fuera de especificacion, y los reproductores
        baratos descartaban la etiqueta ENTERA (ni artista, ni
        album, ni portada).
      · M4A: atomos MP4 estandar (©nam/©ART/aART/©alb/©day/©cmt) y
        covr en JPEG, como iTunes; ademas (v2.8) el atomo moov queda
        AL PRINCIPIO del archivo (faststart): ffmpeg lo escribe al
        final y los reproductores baratos solo escanean la cabecera,
        por eso mostraban 'unknown' aunque las etiquetas estuvieran.
      · WAV: ID3 dentro del RIFF (mutagen.wave), igual que el MP3,
        mas APIC con la caratula (nuevo en v2.7).
      · FLAC: Vorbis comments + Picture en JPEG.
      · WMA: ASF Title/Author/WM/AlbumTitle/WM/AuthorURL + WM/Picture.
      · la caratula SIEMPRE acaba en JPEG y se escribe AQUI con
        mutagen: desde v2.7 EmbedThumbnail ya no toca la caratula
        (su metodo cambia entre versiones de yt-dlp y alguna
        conversion suya dejaba PNG/WebP que los reproductores
        baratos no leen);
      · el comentario guarda la URL del video (como el script antiguo).
    `caratula` son los bytes de la miniatura descargada (opcional)."""
    try:
        p = Path(archivo)
        if not p.exists():
            return
        artista = _artista_limpio(info)
        album = _album_de(info)
        titulo = str(info.get('track') or info.get('title') or '').strip()
        fecha = str(info.get('release_year') or '')
        if not fecha:
            fecha = str(info.get('upload_date') or '')
            if len(fecha) == 8 and fecha.isdigit():
                fecha = fecha[:4]
        url = str(info.get('webpage_url') or '').strip()
        if caratula and not _es_jpg(caratula):
            caratula = _a_jpg(caratula)
        ext = p.suffix.lower()
        if ext == '.m4a':
            # v2.8: ANTES de etiquetar, moov (titulo/artista/album/covr)
            # al principio del archivo; mutagen conserva ese orden.
            if _moov_al_principio(p) and log:
                log('M4A reordenado: etiquetas al inicio (faststart, '
                    'como iTunes)', 'gris')
            from mutagen.mp4 import MP4, MP4Cover
            m = MP4(str(p))
            if titulo:
                m['\xa9nam'] = [titulo]
            if artista:
                m['\xa9ART'] = [artista]
                m['aART'] = [artista]
            if album:
                m['\xa9alb'] = [album]
            if fecha:
                m['\xa9day'] = [fecha]
            if url:
                m['\xa9cmt'] = [url]
            # -- caratula: desde v2.7 la escribe SIEMPRE este pase con
            #    mutagen (EmbedThumbnail ya no participa). Atomo
            #    estandar 'covr' (sin el prefijo (c)); en mutagen
            #    moderno escribir '\xa9covr' lanza TypeError.
            viejas = m.get('covr') or m.get('\xa9covr') or []
            if not viejas:
                if caratula:
                    m['covr'] = [MP4Cover(caratula, MP4Cover.FORMAT_JPEG)]
            elif all(c.imageformat != MP4Cover.FORMAT_JPEG
                     for c in viejas):
                nueva = _a_jpg(bytes(viejas[0])) or caratula
                if nueva:
                    m['covr'] = [MP4Cover(nueva, MP4Cover.FORMAT_JPEG)]
                    m.pop('\xa9covr', None)
            elif m.get('\xa9covr'):
                m['covr'] = viejas
                m.pop('\xa9covr', None)
            m.save()
        elif ext == '.mp3':
            # Formato EXACTO del MP3 de referencia (Snaptube, escrito por
            # FFmpeg/Lavf) que el reproductor del usuario SI muestra:
            #   ID3v2.4.0 + TIT2/TPE1/TALB/APIC en encoding=1 (UTF-16 con
            #   BOM) + APIC(mime 'image/jpg', tipo 3 = COVER_FRONT, desc
            #   'attached picture', JPEG real). El pase anterior escribia
            #   encoding=3 (UTF-8) dentro de un tag v2.3: fuera de
            #   especificacion, y los reproductores baratos descartaban
            #   la etiqueta entera (ni artista, ni album, ni portada).
            from mutagen.id3 import (APIC, COMM, ID3, TALB, TDRC, TIT2,
                                     TLEN, TPE1, TPE2)
            try:
                tags = ID3(str(p))
            except Exception:
                tags = ID3()
            if titulo:
                tags.setall('TIT2', [TIT2(encoding=1, text=[titulo])])
            if artista:
                tags.setall('TPE1', [TPE1(encoding=1, text=[artista])])
                tags.setall('TPE2', [TPE2(encoding=1, text=[artista])])
            if album:
                tags.setall('TALB', [TALB(encoding=1, text=[album])])
            if fecha:
                tags.setall('TDRC', [TDRC(encoding=1, text=[fecha])])
            dur = info.get('duration')
            if dur:
                try:
                    tags.setall('TLEN', [TLEN(encoding=0, text=[
                        str(int(float(dur) * 1000))])])
                except (TypeError, ValueError):
                    pass
            if url:
                tags.setall('COMM', [COMM(encoding=1, lang='eng',
                                          desc='', text=[url])])
            # Portada: mismas constantes del archivo de referencia.
            # Bytes: `caratula` o, si EmbedThumbnail ya incrusto algo,
            # los datos del APIC existente; siempre acabamos en JPEG.
            datos = caratula
            if not datos:
                apics = tags.getall('APIC')
                if apics:
                    datos = apics[0].data
            if datos and not _es_jpg(datos):
                datos = _a_jpg(datos)
            if datos:
                tags.setall('APIC', [APIC(encoding=1, mime='image/jpg',
                                          type=3, desc='attached picture',
                                          data=datos)])
            # v2.4 + UTF-16: la misma combinacion del archivo de
            # referencia (ID3v2.4.0 escrito por Lavf60.3.100).
            tags.save(str(p), v2_version=4)
        elif ext == '.wav':
            from mutagen.id3 import (APIC, COMM, TDRC, TIT2, TLEN, TPE1,
                                     TPE2, TALB)
            from mutagen.wave import WAVE
            w = WAVE(str(p))
            if w.tags is None:
                w.add_tags()
            # encoding=1 (UTF-16), misma regla que en MP3: los
            # reproductores baratos no parsean frames UTF-8.
            if titulo:
                w.tags.setall('TIT2', [TIT2(encoding=1, text=[titulo])])
            if artista:
                w.tags.setall('TPE1', [TPE1(encoding=1, text=[artista])])
                w.tags.setall('TPE2', [TPE2(encoding=1, text=[artista])])
            if album:
                w.tags.setall('TALB', [TALB(encoding=1, text=[album])])
            if fecha:
                w.tags.setall('TDRC', [TDRC(encoding=1, text=[fecha])])
            dur = info.get('duration')
            if dur:
                try:
                    w.tags.setall('TLEN', [TLEN(encoding=0, text=[
                        str(int(float(dur) * 1000))])])
                except (TypeError, ValueError):
                    pass
            if url:
                w.tags.setall('COMM', [COMM(encoding=1, lang='eng',
                                            desc='', text=[url])])
            # v2.7: caratula en el ID3 del WAV (mismas constantes que
            # el MP3 de referencia), para los reproductores que leen
            # el chunk 'id3 ' dentro del RIFF.
            datos = caratula
            if not datos:
                apics = w.tags.getall('APIC')
                if apics:
                    datos = apics[0].data
            if datos and not _es_jpg(datos):
                datos = _a_jpg(datos)
            if datos:
                w.tags.setall('APIC', [APIC(encoding=1, mime='image/jpg',
                                            type=3, desc='attached picture',
                                            data=datos)])
            w.save()
        elif ext == '.flac':
            from mutagen.flac import FLAC, Picture
            f = FLAC(str(p))
            if titulo:
                f['title'] = [titulo]
            if artista:
                f['artist'] = [artista]
                f['albumartist'] = [artista]
            if album:
                f['album'] = [album]
            if fecha:
                f['date'] = [fecha]
            if url:
                f['comment'] = [url]
            if not f.pictures:
                if caratula:
                    pic = Picture()
                    pic.mime, pic.type, pic.desc = 'image/jpeg', 3, 'Cover'
                    pic.data = caratula
                    f.add_picture(pic)
            elif all(pi.mime != 'image/jpeg' for pi in f.pictures):
                nueva = _a_jpg(f.pictures[0].data) or caratula
                if nueva:
                    for vieja in list(f.pictures):
                        f.remove_picture(vieja)
                    pic = Picture()
                    pic.mime, pic.type, pic.desc = 'image/jpeg', 3, 'Cover'
                    pic.data = nueva
                    f.add_picture(pic)
            f.save()
        elif ext == '.wma':
            from mutagen.asf import ASF, ASFByteArrayAttribute
            a = ASF(str(p))
            if titulo:
                a['Title'] = [titulo]
            if artista:
                a['Author'] = [artista]
                a['WM/AlbumArtist'] = [artista]
            if album:
                a['WM/AlbumTitle'] = [album]
            if fecha:
                a['WM/Year'] = [fecha]
            if url:
                a['Description'] = [url]
                a['WM/AuthorURL'] = [url]
            if caratula:
                a['WM/Picture'] = [ASFByteArrayAttribute(
                    _wm_picture(caratula, titulo or 'Cover'))]
            a.save()
        else:
            return
        if log:
            extra = ' · carátula JPEG' if caratula else ''
            log('Etiquetas escritas: artista «%s» · álbum «%s»%s'
                % (artista or '—', album or '—', extra), 'gris')
    except Exception as e:
        # las etiquetas no son criticas: nunca deben romper la descarga
        if log:
            log('No se pudieron escribir todas las etiquetas: %s' % e,
                'aviso')


# ---------------------------------------------------------------- descargas
def descargar_audio(url, nombre_fmt, calidad, destino, embeber, cola):
    """AAC (.m4a) / MP3 / FLAC / WAV vía postprocesadores de yt-dlp.

    yt-dlp SOLO baja, convierte y escribe los metadatos de texto
    (FFmpegMetadata). La carátula NO la incrusta EmbedThumbnail: desde
    v2.7 la escribe aplicar_tags con mutagen (covr en m4a, APIC en
    mp3/wav, Picture en flac), siempre en JPEG y con la estructura
    exacta que leen los reproductores. Así el resultado no depende de
    los métodos internos de EmbedThumbnail, que cambian entre
    versiones de yt-dlp (antes convertía la portada a PNG, y su
    método ffmpeg adjunta la imagen como stream de vídeo)."""
    def log(m, t='info'):
        cola.put(('log', m, t))

    fmt = FORMATOS[nombre_fmt]
    carpeta = destino          # v2.3: sin subcarpetas por formato
    carpeta.mkdir(parents=True, exist_ok=True)
    codec = fmt['ext']
    con_portada = embeber and nombre_fmt in ('AAC', 'MP3', 'FLAC', 'WAV')
    con_tags = embeber
    pps = []
    if con_portada:
        pps.append({'key': 'FFmpegThumbnailsConvertor', 'format': 'jpg',
                    'when': 'before_dl'})
    pps.append({'key': 'FFmpegExtractAudio', 'preferredcodec': codec,
                'preferredquality': calidad or '0'})
    if con_tags:
        pps.append({'key': 'FFmpegMetadata', 'add_metadata': True})
    # v2.7: SIN EmbedThumbnail. La miniatura (dejada en .jpg junto al
    # archivo por writethumbnail + Convertor) la incrusta aplicar_tags
    # con mutagen: estructura garantizada en todos los formatos y sin
    # depender de los métodos internos de yt-dlp.
    o = opts_base(carpeta, cola)
    o['format'] = 'bestaudio/best'
    o['postprocessors'] = pps
    o['writethumbnail'] = con_portada
    with YT_DLP.YoutubeDL(o) as ydl:
        info = ydl.extract_info(url, download=True)
    archivo = archivo_final(info, carpeta, codec)
    caratula = _miniatura_bytes(carpeta, archivo)
    if archivo and con_portada:
        limpiar_miniaturas(carpeta, archivo)
    if archivo:
        aplicar_tags(info, archivo, log, caratula)
    return info, archivo


def descargar_wma(url, calidad, destino, embeber, cola):
    """WMA 96/128 kbps: yt-dlp no soporta wma, así que se baja a WAV (con
    etiquetas) y luego FFmpeg recodifica a wmav2 dentro del .wma final.
    La carátula (WM/Picture, en JPEG) y la URL (WM/AuthorURL) se
    incrustan con mutagen, como en el script antiguo."""
    def log(m, t='info'):
        cola.put(('log', m, t))

    carpeta = destino          # v2.3: sin subcarpetas por formato
    tmp = carpeta / '_tmp'
    shutil.rmtree(tmp, ignore_errors=True)
    tmp.mkdir(parents=True, exist_ok=True)
    o = opts_base(tmp, cola)
    o['format'] = 'bestaudio/best'
    pps = [{'key': 'FFmpegExtractAudio', 'preferredcodec': 'wav',
            'preferredquality': '0'}]
    if embeber:
        pps.insert(0, {'key': 'FFmpegThumbnailsConvertor',
                       'format': 'jpg', 'when': 'before_dl'})
        pps.append({'key': 'FFmpegMetadata', 'add_metadata': True})
    o['postprocessors'] = pps
    o['writethumbnail'] = embeber
    with YT_DLP.YoutubeDL(o) as ydl:
        info = ydl.extract_info(url, download=True)
    wav = archivo_final(info, tmp, 'wav')
    if not wav:
        raise RuntimeError('No se encontró el WAV intermedio.')
    meta = []
    if embeber:
        artista = (info.get('artist') or info.get('uploader')
                   or info.get('channel') or '')
        if info.get('title'):
            meta += ['-metadata', 'title=' + str(info['title'])]
        if artista:
            meta += ['-metadata', 'artist=' + str(artista)]
    wma = carpeta / (limpiar_nombre(info.get('title') or 'audio') + '.wma')
    cmd = [str(FFMPEG), '-y', '-i', str(wav), '-vn',
           '-c:a', 'wmav2', '-b:a', f'{calidad}k'] + meta + [str(wma)]
    ok = convertir_ffmpeg(
        cmd, f'Convirtiendo a WMA (wmav2 · {calidad} kbps)', cola)
    if not ok:
        raise RuntimeError('FFmpeg no pudo crear el archivo WMA.')
    caratula = None
    if embeber:
        jpgs = sorted(tmp.glob('*.jpg'),
                      key=lambda q: q.stat().st_mtime, reverse=True)
        if jpgs:
            try:
                caratula = jpgs[0].read_bytes()
            except OSError:
                caratula = None
    aplicar_tags(info, wma, log, caratula)
    shutil.rmtree(tmp, ignore_errors=True)
    return info, wma


def meta_riff_info(info):
    """v2.7: argumentos -metadata para los tags RIFF INFO del AVI.

    FFmpeg los mapea a INAM (titulo), IART (artista), IPRD (album),
    ICRD (fecha) e ICMT (comentario) dentro del chunk LIST/INFO del
    RIFF, que es donde los reproductores buscan los datos de un AVI."""
    titulo = str(info.get('track') or info.get('title') or '').strip()
    artista = _artista_limpio(info)
    album = _album_de(info)
    fecha = str(info.get('release_year') or '')
    if not fecha:
        fecha = str(info.get('upload_date') or '')[:4]
    url = str(info.get('webpage_url') or '').strip()
    meta = []
    if titulo:
        meta += ['-metadata', 'title=' + titulo]
    if artista:
        meta += ['-metadata', 'artist=' + artista]
    if album:
        meta += ['-metadata', 'album=' + album]
    if fecha:
        meta += ['-metadata', 'date=' + fecha]
    if url:
        meta += ['-metadata', 'comment=' + url]
    return meta


# Parámetros oficiales del repo fdd4s/portable_mp3_player_video_converter_tools
# (video2shenju18.sh): MJPEG 16 fps + PCM 22050 Hz, rotados para la pantalla
# vertical de 128x160 del reproductor sheiju de 1.8 pulgadas.
VF_SHEIJU = 'scale=-2:128, crop=160:128, transpose=2, vflip'
# Variante a prueba de balas para videos cuadrados/verticales (Shorts),
# donde el recorte 160:128 original sería imposible:
VF_SEGURO = ('scale=160:128:force_original_aspect_ratio=decrease,'
             'pad=160:128:(ow-iw)/2:(oh-ih)/2,transpose=2,vflip')


def descargar_avi(url, destino, cola):
    """Video AVI para el reproductor sheiju 1.8" 128x160."""
    def log(m, t='info'):
        cola.put(('log', m, t))

    carpeta = destino          # v2.3: sin subcarpetas por formato
    tmp = carpeta / '_tmp'
    shutil.rmtree(tmp, ignore_errors=True)
    tmp.mkdir(parents=True, exist_ok=True)
    o = opts_base(tmp, cola)
    # Para una pantalla de 128x160 basta con 480p: ahorra mucha descarga.
    o['format'] = ('best[height<=480][ext=mp4]/best[height<=480]/'
                   'bv*[height<=480]+ba/b')
    o['merge_output_format'] = 'mp4'
    with YT_DLP.YoutubeDL(o) as ydl:
        info = ydl.extract_info(url, download=True)
    origen = archivo_final(info, tmp, 'mp4')
    if not origen:
        origen = (archivo_final(info, tmp, 'mkv')
                  or archivo_final(info, tmp, 'webm'))
    if not origen:
        raise RuntimeError('No se encontró el video descargado.')
    avi = carpeta / (limpiar_nombre(info.get('title') or 'video') + '.avi')
    # v2.7: etiquetas RIFF INFO dentro del AVI (ver meta_riff_info)
    # para que el video tambien muestre titulo y artista donde el
    # reproductor sepa leerlas.
    meta = meta_riff_info(info)
    base = [str(FFMPEG), '-y', '-i', str(origen), '-r', '16',
            '-acodec', 'pcm_s16le', '-ac', '2', '-ar', '22050',
            '-pix_fmt', 'yuvj420p', '-c:v', 'mjpeg', '-q:v', '2'] + meta
    ok = convertir_ffmpeg(base + ['-vf', VF_SHEIJU, str(avi)],
                          'Convirtiendo a AVI 128x160 (sheiju 1.8")', cola)
    if not ok:
        log('Video con proporción no estándar; '
            'reintentando en modo compatible...', 'aviso')
        ok = convertir_ffmpeg(base + ['-vf', VF_SEGURO, str(avi)],
                              'Reconvirtiendo a AVI 128x160', cola)
    if not ok:
        raise RuntimeError('FFmpeg no pudo crear el archivo AVI.')
    shutil.rmtree(tmp, ignore_errors=True)
    return info, avi


# ---------------------------------------------------------------- estimación
KBPS_ESTIMADOS = {
    'AAC': 128,     # techo del formato
    'WMA': 128,
    'WAV': 1411,    # PCM 44.1 kHz · 16 bit · estéreo
    'FLAC': 950,    # típico de música procedente de YouTube
    'AVI': 1490,    # ~784 kbps MJPEG 16fps + 706 kbps PCM 22050 estéreo
}


def estimar_bytes(duracion_s, formato, calidad, embeber):
    """Estima el tamaño final en bytes (cálculo puro, testeable)."""
    if formato in ('MP3', 'AAC', 'WMA'):
        kbps = int(re.sub(r'[^0-9]', '', str(calidad)) or 0)
        if not kbps:
            kbps = KBPS_ESTIMADOS.get(formato, 128)
    else:
        kbps = KBPS_ESTIMADOS.get(formato, 128)
    extra = 120_000 if (embeber and formato in ('AAC', 'MP3', 'FLAC',
                                                'WAV')) else 0
    return duracion_s * kbps * 1000 / 8 + extra


# ---------------------------------------------------------------- calidad
def clase_calidad(ext, kbps):
    """Clasifica un archivo. Devuelve (texto, nivel) con nivel 0=ok 1=media 2=baja."""
    if ext == '.mp3':
        if kbps >= 315:
            return '320 kbps', 0
        if kbps >= 250:
            return '256 kbps', 0
        if kbps >= 185:
            return '192 kbps', 0
        if kbps >= 120:
            return '128 kbps', 1
        return f'{kbps} kbps (baja)', 2
    if ext == '.m4a':
        if kbps >= 115:
            return 'Excelente (AAC ≤128k)', 0
        if kbps >= 82:
            return '96 kbps', 1
        return f'{kbps} kbps (baja)', 2
    if ext == '.wma':
        if kbps >= 115:
            return '128 kbps', 0
        if kbps >= 88:
            return '96 kbps', 1
        return f'{kbps} kbps (baja)', 2
    if ext in ('.flac', '.wav'):
        return 'Sin pérdida', 0
    if ext == '.avi':
        if kbps >= 1200:
            return f'{kbps} kbps (MJPEG+PCM 128x160)', 0
        return f'{kbps} kbps (algo bajo)', 1
    return f'{kbps} kbps', 1


# ---------------------------------------------------------------- temas
TEMAS = {
    'Oscuro': dict(
        fondo='#1e1f22', campo='#2a2d31', campo_borde='#3a3e44',
        texto='#d8dadc', texto2='#9a9fa4',
        boton='#3a3d42', boton_act='#4a4e55', boton_txt='#e8eaec',
        log='#141518', log_txt='#cfd3d7', acento='#4f9cf9',
        ok='#7ec97f', error='#e57373', aviso='#d8b64a', trough='#26282c',
        placeholder='#777c82'),
    'Claro': dict(
        fondo='#f2f3f5', campo='#ffffff', campo_borde='#c4c8cd',
        texto='#24272a', texto2='#6a7076',
        boton='#e3e5e8', boton_act='#d2d5da', boton_txt='#24272a',
        log='#ffffff', log_txt='#2b2e31', acento='#1a66d6',
        ok='#1e7e34', error='#c62828', aviso='#9a6700', trough='#dfe1e4',
        placeholder='#9aa0a6'),
}

PLACEHOLDER_URL = 'https://www.youtube.com/watch?v=...'

FUENTE_UI = ('Segoe UI', 9)
FUENTE_BTN = ('Segoe UI', 10)
FUENTE_BTN_G = ('Segoe UI', 11)
FUENTE_LOG = ('Consolas', 10)


if TK_OK:

    class App(tk.Tk):
        """Ventana principal (diseño espejo del mockup: grupos oscuros)."""

        # ------------------------------------------------ construcción
        def __init__(self):
            if getattr(sys, 'frozen', False):
                pass
            super().__init__()
            self.title('MusikALAN')
            self.geometry('860x840')
            self.minsize(700, 660)
            self.cola = queue.Queue()
            self._ocupado = False
            self._en_placeholder = True
            self._tema_actual = AJUSTES.get('tema', 'Oscuro')
            if self._tema_actual not in TEMAS:
                self._tema_actual = 'Oscuro'

            self._estilo = ttk.Style(self)
            try:
                self._estilo.theme_use('clam')
            except Exception:
                pass

            self._construir()
            self._aplicar_tema()
            self._conectar_eventos()
            REGISTRO.log = lambda m, t='aviso': self.cola.put(('log', m, t))
            self.after(80, self._bombear_cola)
            self.after(150, self._arranque)

        def _construir(self):
            self._wg = {}         # referencias para el tema
            self._btns = []       # botones planos (para hover/tema)
            marco = tk.Frame(self)
            marco.pack(fill='both', expand=True, padx=10, pady=8)
            self._wg['marco'] = marco
            marco.columnconfigure(0, weight=1)

            # --- fila Tema ------------------------------------------------
            f0 = tk.Frame(marco)
            f0.grid(row=0, column=0, sticky='ew', pady=(0, 6))
            self._wg['f0'] = f0
            self._wg['lbl_tema'] = tk.Label(f0, text='Tema:', font=FUENTE_UI)
            self._wg['lbl_tema'].pack(side='left')
            self.cmb_tema = ttk.Combobox(
                f0, values=list(TEMAS), state='readonly', width=9,
                font=FUENTE_UI, style='gx.TCombobox')
            self.cmb_tema.set(self._tema_actual)
            self.cmb_tema.pack(side='left', padx=(8, 0), ipady=2)

            # --- grupo: URL de YouTube ------------------------------------
            gu = tk.LabelFrame(marco, text='URL de YouTube', font=FUENTE_UI,
                               relief='solid', bd=1)
            gu.grid(row=1, column=0, sticky='ew', pady=5)
            self._wg['gu'] = gu
            gu.columnconfigure(0, weight=1)
            self.ent_url = tk.Entry(gu, font=FUENTE_UI, relief='flat',
                                    highlightthickness=1)
            self.ent_url.grid(row=0, column=0, sticky='ew',
                              padx=8, pady=8, ipady=5)
            self._poner_placeholder()
            self.btn_x = self._boton(gu, 'X', self._limpiar_url, width=3)
            self.btn_x.grid(row=0, column=1, sticky='e', padx=(0, 8), ipady=3)

            # --- grupo: Formato y calidad ---------------------------------
            gf = tk.LabelFrame(marco, text='Formato y calidad', font=FUENTE_UI,
                               relief='solid', bd=1)
            gf.grid(row=2, column=0, sticky='ew', pady=5)
            self._wg['gf'] = gf
            gf.columnconfigure(1, weight=1)
            self._wg['lbl_fmt'] = tk.Label(gf, text='Formato:', font=FUENTE_UI)
            self._wg['lbl_fmt'].grid(row=0, column=0, sticky='w', padx=8, pady=5)
            self.cmb_formato = ttk.Combobox(
                gf, values=[f['texto'] for f in FORMATOS.values()],
                state='readonly', font=FUENTE_UI, style='gx.TCombobox')
            self.cmb_formato.grid(row=0, column=1, sticky='ew',
                                  padx=8, pady=5, ipady=2)
            self._wg['lbl_cal'] = tk.Label(gf, text='Calidad:', font=FUENTE_UI)
            self._wg['lbl_cal'].grid(row=1, column=0, sticky='w', padx=8, pady=5)
            self.cmb_calidad = ttk.Combobox(
                gf, state='readonly', font=FUENTE_UI, style='gx.TCombobox')
            self.cmb_calidad.grid(row=1, column=1, sticky='ew',
                                  padx=8, pady=5, ipady=2)
            self._wg['lbl_car'] = tk.Label(gf, text='Carpeta:', font=FUENTE_UI)
            self._wg['lbl_car'].grid(row=2, column=0, sticky='w', padx=8, pady=5)
            fc = tk.Frame(gf)
            fc.grid(row=2, column=1, sticky='ew', padx=8, pady=5)
            self._wg['fc'] = fc
            fc.columnconfigure(0, weight=1)
            self.ent_carpeta = tk.Entry(fc, font=FUENTE_UI, relief='flat',
                                        highlightthickness=1)
            self.ent_carpeta.grid(row=0, column=0, sticky='ew', ipady=4)
            self.ent_carpeta.insert(0, AJUSTES['destino'])
            self.btn_cambiar = self._boton(fc, 'Cambiar...', self._cambiar_carpeta)
            self.btn_cambiar.grid(row=0, column=1, padx=(8, 0), ipady=3)
            self.btn_abrir = self._boton(fc, 'Abrir', self._abrir_destino, width=5)
            self.btn_abrir.grid(row=0, column=2, padx=(6, 0), ipady=3)

            self.var_embeber = tk.BooleanVar(value=bool(AJUSTES.get('embeber', True)))
            self.chk_embeber = tk.Checkbutton(
                gf, text='Embeber carátula, artista y álbum',
                variable=self.var_embeber, font=FUENTE_UI, anchor='w',
                relief='flat', highlightthickness=0, bd=0)
            self.chk_embeber.grid(row=3, column=0, columnspan=2,
                                  sticky='ew', padx=8, pady=(2, 6))
            # v2.9: vía anti-bloqueo (cookies del navegador si YouTube
            # pide verificación)
            self._wg['lbl_cookies'] = tk.Label(
                gf, text='Si YouTube bloquea:', font=FUENTE_UI)
            self._wg['lbl_cookies'].grid(row=4, column=0, sticky='w',
                                         padx=8, pady=5)
            self.cmb_cookies = ttk.Combobox(
                gf, values=(['Automático (recomendado)']
                            + ['Usar cookies de ' + n.capitalize()
                               for n in NAVEGADORES_COOKIES]),
                state='readonly', font=FUENTE_UI, style='gx.TCombobox')
            self.cmb_cookies.grid(row=4, column=1, sticky='ew',
                                  padx=8, pady=5, ipady=2)
            self.cmb_cookies.set('Automático (recomendado)')

            # --- grupo: estimación ----------------------------------------
            ge = tk.LabelFrame(marco, text='Estimación', font=FUENTE_UI,
                               relief='solid', bd=1)
            ge.grid(row=3, column=0, sticky='ew', pady=5)
            self._wg['ge'] = ge
            ge.columnconfigure(0, weight=1)
            self.lbl_estimacion = tk.Label(
                ge, text='Introduce una URL y pulsa Estimar.',
                font=FUENTE_UI, anchor='w')
            self.lbl_estimacion.grid(row=0, column=0, sticky='ew',
                                     padx=8, pady=6)
            self.btn_estimar = self._boton(ge, 'Estimar tamano',
                                           self._accion_estimar)
            self.btn_estimar.grid(row=0, column=1, sticky='e',
                                  padx=8, ipady=3)

            # --- botones grandes ------------------------------------------
            self.btn_descargar = self._boton(marco, 'Descargar y convertir',
                                             self._accion_descargar,
                                             fuente=FUENTE_BTN_G, alto=2)
            self.btn_descargar.grid(row=4, column=0, sticky='ew', pady=(7, 4))
            self.btn_comprobar = self._boton(
                marco, 'Comprobar calidad de la carpeta',
                self._accion_comprobar, fuente=FUENTE_BTN)
            self.btn_comprobar.grid(row=5, column=0, sticky='ew', pady=3)

            # --- estado + barra de progreso --------------------------------
            self.lbl_estado = tk.Label(marco, text='', font=FUENTE_UI,
                                       anchor='w')
            self.lbl_estado.grid(row=6, column=0, sticky='ew', pady=(4, 0))
            self.barra = ttk.Progressbar(
                marco, maximum=100, style='gx.Horizontal.TProgressbar')
            self.barra.grid(row=7, column=0, sticky='ew', pady=(2, 4))

            # --- registro (log) --------------------------------------------
            self.txt_log = ScrolledText(marco, font=FUENTE_LOG, height=12,
                                        relief='flat', bd=0, wrap='word',
                                        state='disabled')
            self.txt_log.grid(row=8, column=0, sticky='nsew')
            marco.rowconfigure(8, weight=1)
            for tag, conf in (
                    ('info', {}),
                    ('gris', {}),
                    ('titulo', {}),
                    ('ok', {}),
                    ('aviso', {}),
                    ('error', {})):
                self.txt_log.tag_configure(tag, conf)

            # sincronizar valores guardados
            fmt = AJUSTES.get('formato', 'AAC')
            if fmt not in FORMATOS:
                fmt = 'AAC'
            self.cmb_formato.set(FORMATOS[fmt]['texto'])
            self._recargar_calidades(fmt, AJUSTES.get('calidad'))
            cookies = str(AJUSTES.get('cookies', '') or '').strip().lower()
            if cookies in NAVEGADORES_COOKIES:
                self.cmb_cookies.set('Usar cookies de '
                                     + cookies.capitalize())
            else:
                self.cmb_cookies.set('Automático (recomendado)')

        # ------------------------------------------------ helpers widgets
        def _boton(self, padre, texto, cmd, width=None, fuente=FUENTE_BTN,
                   alto=1):
            b = tk.Button(padre, text=texto, command=cmd, font=fuente,
                          relief='flat', bd=0, cursor='hand2', height=alto,
                          activeforeground='#ffffff', takefocus=0)
            if width:
                b.configure(width=width)
            b.bind('<Enter>', lambda e, w=b: w.configure(
                bg=TEMAS[self._tema_actual]['boton_act']))
            b.bind('<Leave>', lambda e, w=b: w.configure(
                bg=TEMAS[self._tema_actual]['boton']))
            self._btns.append(b)
            return b

        def _poner_placeholder(self):
            if not self.ent_url.get():
                self._en_placeholder = True
                self.ent_url.insert(0, PLACEHOLDER_URL)

        def _limpiar_url(self):
            self.ent_url.delete(0, 'end')
            self.ent_url.focus_set()

        def _reset_url(self):
            """Deja el campo de URL vacío con su placeholder (tras un éxito)."""
            self.ent_url.delete(0, 'end')
            self._en_placeholder = True
            self._poner_placeholder()
            self._refrescar_placeholder()

        # ------------------------------------------------ tema
        def _aplicar_tema(self):
            t = TEMAS[self._tema_actual]
            w = self._wg
            self.configure(bg=t['fondo'])
            for nombre in ('marco', 'f0', 'gu', 'gf', 'fc', 'ge'):
                w[nombre].configure(bg=t['fondo'])
            for lf in (w['gu'], w['gf'], w['ge']):
                lf.configure(bg=t['fondo'], fg=t['texto2'])
            for nombre in ('lbl_tema', 'lbl_fmt', 'lbl_cal', 'lbl_car'):
                w[nombre].configure(bg=t['fondo'], fg=t['texto'])
            self.lbl_estimacion.configure(bg=t['fondo'], fg=t['texto'])
            self.lbl_estado.configure(bg=t['fondo'], fg=t['texto2'])
            self.ent_url.configure(
                bg=t['campo'], fg=t['texto'], insertbackground=t['texto'],
                highlightbackground=t['campo_borde'],
                highlightcolor=t['acento'],
                disabledbackground=t['campo'], disabledforeground=t['texto2'])
            self.ent_carpeta.configure(
                bg=t['campo'], fg=t['texto'], insertbackground=t['texto'],
                highlightbackground=t['campo_borde'],
                highlightcolor=t['acento'])
            self.chk_embeber.configure(
                bg=t['fondo'], fg=t['texto'], activebackground=t['fondo'],
                activeforeground=t['texto'], selectcolor=t['campo'])
            for b in self._btns:
                b.configure(bg=t['boton'], fg=t['boton_txt'],
                            activebackground=t['boton_act'],
                            activeforeground=t['boton_txt'])
            self.txt_log.configure(bg=t['log'], fg=t['log_txt'],
                                   insertbackground=t['log_txt'])
            self.txt_log.tag_configure('info', foreground=t['log_txt'])
            self.txt_log.tag_configure('gris', foreground=t['texto2'])
            self.txt_log.tag_configure('titulo', foreground=t['texto'],
                                       font=('Consolas', 10, 'bold'))
            self.txt_log.tag_configure('ok', foreground=t['ok'])
            self.txt_log.tag_configure('aviso', foreground=t['aviso'])
            self.txt_log.tag_configure('error', foreground=t['error'])
            est = self._estilo
            est.configure('gx.TCombobox',
                          fieldbackground=t['campo'], background=t['boton'],
                          foreground=t['texto'], arrowcolor=t['texto'],
                          bordercolor=t['campo_borde'],
                          lightcolor=t['campo_borde'],
                          darkcolor=t['campo_borde'],
                          insertcolor=t['texto'])
            est.map('gx.TCombobox',
                    fieldbackground=[('readonly', t['campo'])],
                    foreground=[('readonly', t['texto'])])
            est.configure('gx.Horizontal.TProgressbar',
                          troughcolor=t['trough'], background=t['acento'],
                          bordercolor=t['fondo'], lightcolor=t['acento'],
                          darkcolor=t['acento'])
            self.option_add('*TCombobox*Listbox.background', t['campo'])
            self.option_add('*TCombobox*Listbox.foreground', t['texto'])
            self.option_add('*TCombobox*Listbox.selectBackground',
                            t['boton_act'])
            self.option_add('*TCombobox*Listbox.selectForeground',
                            t['boton_txt'])
            self._refrescar_placeholder()

        def _refrescar_placeholder(self):
            t = TEMAS[self._tema_actual]
            if self._en_placeholder:
                self.ent_url.configure(fg=t['placeholder'])
            else:
                self.ent_url.configure(fg=t['texto'])

        # ------------------------------------------------ eventos
        def _conectar_eventos(self):
            self.cmb_tema.bind('<<ComboboxSelected>>', self._on_tema)
            self.cmb_formato.bind('<<ComboboxSelected>>', self._on_formato)
            self.cmb_calidad.bind('<<ComboboxSelected>>', lambda e: self._guardar())
            self.chk_embeber.configure(command=self._guardar)
            self.ent_url.bind('<FocusIn>', self._on_focus_url_in)
            self.ent_url.bind('<FocusOut>', self._on_focus_url_out)
            self.ent_url.bind('<Return>', lambda e: self._accion_descargar())
            self.ent_carpeta.bind('<FocusOut>', self._on_carpeta_escrita)
            self.protocol('WM_DELETE_WINDOW', self._al_cerrar)
            self.bind('<Control-u>', lambda e: self._accion_actualizar())
            self.bind('<Control-l>', lambda e: self._limpiar_log())
            self.bind('<Control-U>', lambda e: self._accion_actualizar())

        def _on_focus_url_in(self, _e=None):
            if self._en_placeholder:
                self.ent_url.delete(0, 'end')
                self._en_placeholder = False
                self._refrescar_placeholder()

        def _on_focus_url_out(self, _e=None):
            if not self.ent_url.get():
                self._en_placeholder = True
                self._poner_placeholder()
                self._refrescar_placeholder()

        def _on_tema(self, _e=None):
            self._tema_actual = self.cmb_tema.get()
            AJUSTES['tema'] = self._tema_actual
            guardar_ajustes()
            self._aplicar_tema()

        def _on_formato(self, _e=None):
            fmt = self._fmt_actual()
            self._recargar_calidades(fmt)
            self._guardar()
            self.lbl_estimacion.configure(
                text='Introduce una URL y pulsa Estimar.',
                fg=TEMAS[self._tema_actual]['texto'])

        def _fmt_actual(self):
            texto = self.cmb_formato.get()
            for clave, f in FORMATOS.items():
                if f['texto'] == texto:
                    return clave
            return 'AAC'

        def _recargar_calidades(self, clave_fmt, calidad_previa=None):
            f = FORMATOS[clave_fmt]
            self.cmb_calidad['values'] = f['calidades']
            if calidad_previa and calidad_previa in f['calidades']:
                self.cmb_calidad.set(calidad_previa)
            else:
                self.cmb_calidad.set(f['defecto'])
            AJUSTES['formato'] = clave_fmt
            AJUSTES['calidad'] = self.cmb_calidad.get()

        def _guardar(self):
            AJUSTES['formato'] = self._fmt_actual()
            AJUSTES['calidad'] = self.cmb_calidad.get()
            AJUSTES['embeber'] = bool(self.var_embeber.get())
            AJUSTES['destino'] = self.ent_carpeta.get().strip()
            val = self.cmb_cookies.get()
            AJUSTES['cookies'] = ('' if val.startswith('Automático') else
                                  val.replace('Usar cookies de ', '')
                                  .strip().lower())
            guardar_ajustes()

        def _on_carpeta_escrita(self, _e=None):
            p = Path(os.path.expandvars(
                self.ent_carpeta.get().strip().strip('"')))
            try:
                p.mkdir(parents=True, exist_ok=True)
                AJUSTES['destino'] = str(p)
                guardar_ajustes()
            except OSError as e:
                self._log(f'No se pudo usar esa carpeta: {e}', 'error')

        def _cambiar_carpeta(self):
            actual = self.ent_carpeta.get().strip() or AJUSTES['destino']
            nueva = filedialog.askdirectory(
                title='Elige la carpeta donde guardar las descargas',
                initialdir=actual if os.path.isdir(actual) else str(Path.home()))
            if not nueva:
                return
            try:
                Path(nueva).mkdir(parents=True, exist_ok=True)
            except OSError as e:
                messagebox.showerror('Carpeta no válida', str(e))
                return
            self.ent_carpeta.delete(0, 'end')
            self.ent_carpeta.insert(0, nueva)
            AJUSTES['destino'] = nueva
            guardar_ajustes()
            self._log('Carpeta de guardado: ' + nueva, 'gris')

        def _abrir_destino(self):
            p = Path(os.path.expandvars(
                self.ent_carpeta.get().strip().strip('"')))
            try:
                p.mkdir(parents=True, exist_ok=True)
            except OSError:
                pass
            abrir_carpeta(p)

        def _al_cerrar(self):
            if self._ocupado and not messagebox.askokcancel(
                    'Salir', 'Hay una tarea en curso. '
                    '¿Seguro que quieres salir?'):
                return
            self.destroy()

        # ------------------------------------------------ registro (log)
        def _log(self, msg, tag='info'):
            self.txt_log.configure(state='normal')
            n_lineas = int(self.txt_log.index('end-1c').split('.')[0])
            if n_lineas > 900:
                self.txt_log.delete('1.0', '200.0')
            self.txt_log.insert('end', str(msg) + '\n', tag)
            self.txt_log.see('end')
            self.txt_log.configure(state='disabled')

        def _limpiar_log(self):
            self.txt_log.configure(state='normal')
            self.txt_log.delete('1.0', 'end')
            self.txt_log.configure(state='disabled')

        def _bombear_cola(self):
            try:
                while True:
                    ev = self.cola.get_nowait()
                    tipo = ev[0]
                    if tipo == 'log':
                        self._log(ev[1], ev[2])
                    elif tipo == 'prog':
                        pct, texto = ev[1], ev[2]
                        if pct is None:
                            self.barra.stop()
                            self.barra.configure(mode='indeterminate')
                            self.barra.start(60)
                        else:
                            self.barra.stop()
                            self.barra.configure(mode='determinate')
                            self.barra.configure(value=max(0, min(100, pct)))
                        self.lbl_estado.configure(text=texto)
                    elif tipo == 'estimacion':
                        self.lbl_estimacion.configure(
                            text=ev[1], fg=TEMAS[self._tema_actual]['acento'])
                    elif tipo == 'fin':
                        self._fin_tarea(ev[1], ev[2], ev[3] if len(ev) > 3 else '')
            except queue.Empty:
                pass
            self.after(80, self._bombear_cola)

        # ------------------------------------------------ tareas
        def _habilitar_acciones(self, on):
            estado = 'normal' if on else 'disabled'
            for b in (self.btn_descargar, self.btn_comprobar,
                      self.btn_estimar, self.btn_cambiar, self.btn_abrir,
                      self.btn_x):
                b.configure(state=estado, cursor='hand2' if on else 'arrow')

        def _iniciar(self, objetivo, cfg, texto):
            if self._ocupado:
                self._log('Ya hay una tarea en curso; espera a que termine.',
                          'aviso')
                return False
            self._ocupado = True
            self._habilitar_acciones(False)
            self.lbl_estado.configure(text=texto)
            threading.Thread(target=objetivo, args=(cfg,), daemon=True).start()
            return True

        def _fin_tarea(self, tipo, ok, mensaje=''):
            self._ocupado = False
            self._habilitar_acciones(True)
            self.barra.stop()
            self.barra.configure(mode='determinate')
            self.barra.configure(value=0)
            if tipo == 'descarga' and ok:
                self.lbl_estado.configure(text='Listo.')
                # La descarga fue bien: se limpia la URL para la siguiente.
                self._reset_url()
            elif not ok:
                self.lbl_estado.configure(text='Terminado con errores.')
                if tipo == 'descarga':
                    messagebox.showerror(
                        'Error', mensaje or 'No se pudo completar la tarea. '
                        'Revisa el registro para más detalles.')

        def _url_valida(self):
            if self._en_placeholder:
                self._log('Primero pega la URL del video de YouTube.', 'aviso')
                return None
            u = self.ent_url.get().strip().strip('"').strip("'")
            if not u:
                self._log('La URL está vacía.', 'aviso')
                return None
            if not re.match(r'^https?://', u, re.I):
                if re.match(r'^www\.', u, re.I):
                    u = 'https://' + u
                else:
                    self._log('Eso no parece una URL (debe empezar por '
                              'http:// o https://)', 'error')
                    return None
            # OJO: aquí NO se quita list=; si la URL trae una playlist,
            # _accion_descargar preguntará qué hacer con ella.
            return u

        def _accion_estimar(self):
            url = self._url_valida()
            if not url:
                return
            self._guardar()
            cfg = {'url': url}
            self._iniciar(self._hilo_estimar, cfg, 'Estimando tamaño...')
            self.lbl_estimacion.configure(
                text='Calculando...', fg=TEMAS[self._tema_actual]['texto2'])

        def _accion_descargar(self):
            url = self._url_valida()
            if not url:
                return
            self._guardar()
            playlist = False
            if es_url_playlist(url):
                r = messagebox.askyesnocancel(
                    'MusikALAN — lista de reproducción',
                    'Esta URL pertenece a una lista de reproducción.\n\n'
                    '  SÍ  →  descargar la playlist completa\n'
                    '         (pausa de 2 s entre canciones)\n'
                    '  NO  →  descargar solo esta canción\n'
                    '  Cancelar  →  no descargar nada')
                if r is None:
                    self._log('Descarga cancelada.', 'gris')
                    return
                if r:
                    playlist = True
                elif es_solo_lista(url):
                    # Es una playlist pura: no hay "una canción" ahí
                    self._log('Esa URL es una lista completa; se descargará '
                              'entera.', 'aviso')
                    playlist = True
            cfg = {'url': url, 'playlist': playlist}
            self._iniciar(self._hilo_descargar, cfg, 'Descargando...')

        def _accion_comprobar(self):
            self._guardar()
            self._iniciar(self._hilo_comprobar, {},
                          'Comprobando la carpeta...')

        def _accion_actualizar(self):
            if not YT_DLP:
                self._log('yt-dlp no está instalado; ejecuta '
                          'DescargadorMusica.bat.', 'error')
                return
            self._iniciar(self._hilo_actualizar, {}, 'Actualizando yt-dlp...')

        # ------------------------------------------------ hilos
        def _hilo_estimar(self, cfg):
            cola = self.cola

            def log(m, t='info'):
                cola.put(('log', m, t))

            try:
                if YT_DLP is None:
                    log('yt-dlp no está instalado. Ejecuta '
                        'DescargadorMusica.bat para instalarlo.', 'error')
                    cola.put(('estimacion', 'yt-dlp no disponible'))
                    return
                log('Obteniendo información del video...', 'gris')
                o = {'quiet': True, 'no_warnings': True, 'noplaylist': True,
                     'socket_timeout': 30, 'logger': REGISTRO}
                _anti_bot(o)
                if es_url_playlist(cfg['url']):
                    log('(la URL contiene una playlist: la estimación es '
                        'solo del video pegado)', 'gris')
                with YT_DLP.YoutubeDL(o) as ydl:
                    info = ydl.extract_info(cfg['url'], download=False)
                dur = info.get('duration')
                if not dur:
                    log('No se pudo obtener la duración del video.', 'error')
                    cola.put(('estimacion', 'Sin datos para estimar'))
                    return
                clave = self._fmt_actual_solo(AJUSTES.get('formato', 'AAC'))
                tam = estimar_bytes(dur, clave, AJUSTES.get('calidad'),
                                    bool(AJUSTES.get('embeber', True)))
                titulo = str(info.get('title') or '')[:70]
                if titulo:
                    log('♪ ' + titulo, 'titulo')
                texto = (f'~{tam / 1048576:.1f} MB · '
                         f'duración {fmt_tiem(dur)} · '
                         f'{clave} {AJUSTES.get("calidad", "")}'.rstrip())
                cola.put(('estimacion', texto))
                log('Estimación: ' + texto, 'ok')
                log('El tamaño real puede variar algo según la fuente.',
                    'gris')
            except Exception as e:
                log(f'No se pudo estimar: {self._msg_error(e)}', 'error')
                cola.put(('estimacion', 'No se pudo estimar'))
            finally:
                cola.put(('fin', 'estimacion', True, ''))

        def _fmt_actual_solo(self, clave):
            return clave if clave in FORMATOS else 'AAC'

        def _descargar_una(self, url, clave, calidad_arg, embeber, destino,
                           cola):
            """Descarga y convierte UNA URL. Devuelve el Path final o None."""
            if clave == 'WMA':
                return descargar_wma(url, calidad_arg, destino, embeber,
                                     cola)[1]
            if clave == 'AVI':
                return descargar_avi(url, destino, cola)[1]
            return descargar_audio(url, clave, calidad_arg, destino, embeber,
                                   cola)[1]

        def _descargar_playlist(self, url, clave, calidad_arg, embeber,
                                destino, cola):
            """Baja una lista entera, con 2 s de descanso entre canciones
            para no saturar a YouTube. Devuelve (descargadas, total)."""
            def log(m, t='info'):
                cola.put(('log', m, t))

            log('Leyendo la lista de reproducción...', 'gris')
            o = {'quiet': True, 'no_warnings': True,
                 'extract_flat': 'in_playlist', 'socket_timeout': 30,
                 'logger': REGISTRO}
            _anti_bot(o)
            with YT_DLP.YoutubeDL(o) as ydl:
                info = ydl.extract_info(url, download=False)
            entradas = list(info.get('entries') or [])
            if not entradas:
                log('No se vio ninguna canción en la lista; se intenta '
                    'como video suelto.', 'aviso')
                archivo = self._descargar_una(sin_playlist(url)[0], clave,
                                              calidad_arg, embeber, destino,
                                              cola)
                return (1 if archivo else 0), 1
            titulo_pl = str(info.get('title') or 'lista')[:70]
            total = len(entradas)
            log(f'Playlist «{titulo_pl}» — {total} vídeo(s).', 'titulo')
            okas = 0
            fallos = []
            for i, e in enumerate(entradas):
                u = str(e.get('webpage_url') or e.get('url') or '')
                if u and not u.startswith('http'):
                    u = 'https://www.youtube.com/watch?v=' + u
                if not u and e.get('id'):
                    u = 'https://www.youtube.com/watch?v=' + str(e['id'])
                tit = str(e.get('title') or u or '?')[:70]
                if i:
                    time.sleep(2)   # descanso entre canciones
                log(f'[{i + 1}/{total}] ♪ {tit}', 'titulo')
                try:
                    archivo = self._descargar_una(u, clave, calidad_arg,
                                                  embeber, destino, cola)
                except Exception as e2:
                    if _es_bloqueo_bot(str(e2)):
                        # bloqueo anti-bot: abortar para que el reintento
                        # automático de _hilo_descargar se encargue
                        raise
                    archivo = None
                    log(f'✖ [{i + 1}/{total}] Falló: {self._msg_error(e2)}',
                        'error')
                if archivo and Path(archivo).exists():
                    try:
                        tam = fmt_tam(Path(archivo).stat().st_size)
                    except OSError:
                        tam = '?'
                    log(f'   ✔ {Path(archivo).name}  ({tam})', 'ok')
                    okas += 1
                else:
                    fallos.append(tit)
            log(f'Playlist terminada: {okas} de {total} descargada(s).',
                'ok' if not fallos else 'aviso')
            if fallos:
                log('Sin descargar: '
                    + ' · '.join(f[:40] for f in fallos[:8])
                    + ('...' if len(fallos) > 8 else ''), 'gris')
            return okas, total

        def _hilo_descargar(self, cfg):
            cola = self.cola

            def log(m, t='info'):
                cola.put(('log', m, t))

            url = cfg['url']
            clave = self._fmt_actual_solo(AJUSTES.get('formato', 'AAC'))
            calidad = AJUSTES.get('calidad', '128k')
            embeber = bool(AJUSTES.get('embeber', True))
            destino = Path(os.path.expandvars(
                str(AJUSTES.get('destino', _destino_por_defecto()))))
            try:
                if YT_DLP is None:
                    log('yt-dlp no está instalado. Ejecuta '
                        'DescargadorMusica.bat para instalarlo.', 'error')
                    cola.put(('fin', 'descarga', False,
                              'yt-dlp no está instalado.'))
                    return
                destino.mkdir(parents=True, exist_ok=True)
                if clave in ('FLAC', 'WAV'):
                    calidad_arg = '0'
                else:
                    calidad_arg = (re.sub(r'[^0-9]', '', str(calidad))
                                   or ('128' if clave == 'AAC' else '320'))
                if cfg.get('playlist'):
                    okas, total = self._descargar_playlist(
                        url, clave, calidad_arg, embeber, destino, cola)
                    if okas and okas == total:
                        log(f'Carpeta: {destino}', 'gris')
                        cola.put(('fin', 'descarga', True, ''))
                    else:
                        cola.put((
                            'fin', 'descarga', False,
                            f'Se descargaron {okas} de {total} de la '
                            'playlist. La URL no se ha borrado por si '
                            'quieres reintentarlo.'))
                    return
                archivo = self._descargar_una(sin_playlist(url)[0], clave,
                                              calidad_arg, embeber, destino,
                                              cola)
                if archivo and Path(archivo).exists():
                    archivo = Path(archivo)
                    try:
                        tam = fmt_tam(archivo.stat().st_size)
                    except OSError:
                        tam = '?'
                    log(f'✔ ¡Listo!  {archivo.name}  ({tam})', 'ok')
                    log(f'Carpeta: {archivo.parent}', 'gris')
                    cola.put(('fin', 'descarga', True, ''))
                else:
                    log('El archivo final no apareció donde se esperaba.',
                        'error')
                    cola.put(('fin', 'descarga', False, ''))
            except Exception as e:
                nombre_exc = type(e).__name__
                if nombre_exc == 'DownloadError':
                    lineas = [l for l in str(e).strip().splitlines() if l.strip()]
                    msg = lineas[0][:300] if lineas else 'error desconocido'
                    if _es_bloqueo_bot(str(e)):
                        if _ANTI_BOT['combo'] == 0:
                            log('YouTube está pidiendo verificación '
                                'anti-bot para esta red. Reintentando con '
                                'una vía interna alternativa...', 'aviso')
                            _ANTI_BOT['combo'] = 1
                            try:
                                time.sleep(3)   # respiro para el 429
                                self._hilo_descargar(cfg)
                                return
                            finally:
                                _ANTI_BOT['combo'] = 0
                        log('✖ YouTube sigue pidiendo verificación: '
                            + msg, 'error')
                        log('Solución fiable: en «Si YouTube bloquea:» '
                            'elige Usar cookies de Firefox (o tu '
                            'navegador) y reintenta: con tu sesión '
                            'abierta YouTube no vuelve a pedir '
                            'verificación.', 'gris')
                        log('También suelen funcionar: esperar unos '
                            'minutos, pulsar Ctrl+U (actualizar yt-dlp) '
                            'o probar con otra red (el wifi de casa).',
                            'gris')
                    else:
                        log('✖ No se pudo descargar: ' + msg, 'error')
                        log('Consejos: revisa la URL y tu conexión; si '
                            'YouTube cambió algo, pulsa Ctrl+U '
                            '(actualizar yt-dlp) y reintenta.', 'gris')
                else:
                    log(f'✖ Error inesperado ({nombre_exc}): {e}', 'error')
                    tb = traceback.format_exc(limit=3)
                    try:
                        with open(LOG_ERRORES, 'a', encoding='utf-8') as fh:
                            fh.write(tb + '\n')
                    except Exception:
                        pass
                cola.put(('fin', 'descarga', False,
                          'No se pudo completar la descarga. Revisa el '
                          'registro para más detalles.'))

        def _hilo_comprobar(self, cfg):
            cola = self.cola

            def log(m, t='info'):
                cola.put(('log', m, t))

            carpeta = Path(os.path.expandvars(
                str(AJUSTES.get('destino', _destino_por_defecto()))))
            try:
                if not carpeta.is_dir():
                    log(f'La carpeta todavía no existe: {carpeta}', 'aviso')
                    cola.put(('fin', 'comprobacion', True, ''))
                    return
                if FFPROBE is None:
                    log('ffprobe no está disponible (viene con FFmpeg). '
                        'Ejecuta DescargadorMusica.bat para instalarlo.',
                        'error')
                    cola.put(('fin', 'comprobacion', True, ''))
                    return
                exts = ('.m4a', '.mp3', '.flac', '.wav', '.wma', '.avi')
                archivos = [p for p in sorted(carpeta.rglob('*'))
                            if p.is_file() and p.suffix.lower() in exts
                            and '_tmp' not in p.parts]
                log(f'Comprobando {len(archivos)} archivo(s) en '
                    f'{carpeta} ...', 'titulo')
                if not archivos:
                    log('No hay archivos de audio o video todavía.', 'gris')
                    cola.put(('fin', 'comprobacion', True, ''))
                    return
                total = 0
                bajas = 0
                for p in archivos:
                    try:
                        r = subprocess.run(
                            [str(FFPROBE), '-v', 'error', '-show_entries',
                             'format=bit_rate,duration,size', '-of', 'json',
                             str(p)],
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            text=True, encoding='utf-8', errors='replace',
                            timeout=30)
                        datos = json.loads(r.stdout or '{}').get('format', {})
                        kbps = int(float(datos.get('bit_rate') or 0) / 1000)
                        dur = float(datos.get('duration') or 0)
                        tam = int(float(datos.get('size') or 0))
                    except Exception:
                        log(f'· {p.name[:60]} — no se pudo leer', 'aviso')
                        continue
                    total += tam
                    texto, nivel = clase_calidad(p.suffix.lower(), kbps)
                    if nivel == 2:
                        bajas += 1
                    tag = ('ok' if nivel == 0
                           else ('aviso' if nivel == 1 else 'error'))
                    log(f'· {p.name[:58]} — {texto} · {fmt_tiem(dur)} · '
                        f'{fmt_tam(tam)}', tag)
                log(f'Resultado: {len(archivos)} archivo(s) · '
                    f'{fmt_tam(total)} en total · {bajas} con calidad baja',
                    'titulo')
                if bajas:
                    log('Consejo: los archivos marcados en rojo se pueden '
                        'volver a descargar con más bitrate.', 'gris')
            except Exception as e:
                log(f'Error al comprobar la carpeta: {e}', 'error')
            finally:
                cola.put(('fin', 'comprobacion', True, ''))

        def _hilo_actualizar(self, cfg):
            cola = self.cola

            def log(m, t='info'):
                cola.put(('log', m, t))

            try:
                log('Actualizando yt-dlp y mutagen...', 'gris')
                p = subprocess.run(
                    [sys.executable, '-m', 'pip', 'install', '--upgrade',
                     '--no-warn-script-location', 'yt-dlp', 'mutagen'],
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                    text=True, encoding='utf-8', errors='replace', timeout=600)
                for ln in (p.stdout or '').strip().splitlines()[-6:]:
                    log('   ' + ln[:160], 'gris')
                if p.returncode == 0:
                    log('yt-dlp actualizado. Reinicia la aplicación para '
                        'usar la versión nueva.', 'ok')
                else:
                    log('La actualización falló (¿sin internet?).', 'error')
            except Exception as e:
                log(f'No se pudo ejecutar pip: {e}', 'error')
            finally:
                cola.put(('fin', 'actualizacion', True, ''))

        def _msg_error(self, e):
            lineas = [l for l in str(e).strip().splitlines() if l.strip()]
            return (lineas[0][:250] if lineas
                    else f'{type(e).__name__}: sin detalles')

        # ------------------------------------------------ arranque
        def _arranque(self):
            self._log(f'MusikALAN v{APP_V}', 'titulo')
            self._log('Ctrl+U: actualizar yt-dlp · Ctrl+L: limpiar registro',
                      'gris')
            threading.Thread(target=self._hilo_version, daemon=True).start()

        def _hilo_version(self):
            cola = self.cola

            def log(m, t='info'):
                cola.put(('log', m, t))

            if YT_DLP is None:
                log('yt-dlp no está instalado. Ejecuta '
                    'DescargadorMusica.bat para instalarlo.', 'error')
                cola.put(('fin', 'version', True, ''))
                return
            try:
                instalada = YT_DLP.version.__version__
            except Exception:
                instalada = '?'
            ultima = None
            try:
                with urlopen('https://pypi.org/pypi/yt-dlp/json', timeout=12) as r:
                    ultima = json.loads(r.read().decode('utf-8'))['info']['version']
            except Exception:
                ultima = None
            if ultima is None:
                log(f'yt-dlp: versión {instalada} '
                    '(no se pudo comprobar si hay novedades).', 'gris')
            elif str(ultima) == str(instalada):
                log(f'yt-dlp: en la ultima version ({instalada}).', 'info')
            else:
                log(f'yt-dlp: hay version nueva ({ultima}); instalada: '
                    f'{instalada}. Pulsa Ctrl+U para actualizar.', 'aviso')
            if FFMPEG is None:
                log('FFmpeg: NO ENCONTRADO — ejecuta DescargadorMusica.bat '
                    'para instalarlo.', 'error')
            else:
                log(f'FFmpeg: OK ({FFMPEG})', 'gris')
            log('Carpeta de guardado: ' + str(AJUSTES.get('destino')), 'gris')
            cola.put(('fin', 'version', True, ''))


# ---------------------------------------------------------------- main
def main():
    _reconfigurar_salida()
    if not TK_OK:
        print('Esta aplicación necesita Tkinter (interfaz gráfica).')
        print('El Python actual no lo incluye.')
        print('Vuelve a ejecutar DescargadorMusica.bat para instalar el '
              'Python adecuado.')
        return 1
    comprobar_entorno()
    app = App()
    app.mainloop()
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except SystemExit:
        raise
    except BaseException:
        try:
            with open(LOG_ERRORES, 'a', encoding='utf-8') as fh:
                fh.write(traceback.format_exc() + '\n')
        except Exception:
            pass
        raise
