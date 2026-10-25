#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Descargador de Musica — interfaz grafica (Tkinter) para yt-dlp + FFmpeg
=======================================================================
App de escritorio para descargar musica y videos de YouTube en formatos
aptos para reproductores portatiles antiguos (tipo "sheiju" MP3 de 1.8"
pulgadas y pantalla 128x160):

  · AAC  (.m4a)  maximo 128 kbps
  · MP3  (.mp3)  128 / 192 / 256 / 320 kbps (desplegable "Calidad")
  · FLAC (.flac) sin perdida
  · WAV  (.wav)  sin perdida (archivos grandes)
  · WMA  (.wma)  128 kbps (codificador wmav2 de FFmpeg; el contenedor
                 ASF no admite caratula incrustada)
  · AVI  (.avi)  video recodificado para el reproductor sheiju 1.8"
                 128x160, con los parametros oficiales del repositorio
                 github.com/fdd4s/portable_mp3_player_video_converter_tools
                 (script video2shenju18.sh)

La instalacion de Python, yt-dlp y FFmpeg la hace automaticamente el
archivo DescargadorMusica.bat; este script es la ventana que se usa a
diario (tema oscuro/claro, cookies del navegador, estimacion de tamano
y comprobador de calidad de la carpeta).

Uso:  python descargador.py   (o doble clic en DescargadorMusica.bat)
Solo descarga videos individuales: si la URL trae lista de reproduccion,
se ignora la lista y se baja unicamente el video pegado.
"""

import json
import os
import queue
import re
import shutil
import subprocess
import sys
import threading
import traceback
from pathlib import Path
from urllib.parse import parse_qs, urlencode, urlparse, urlunparse
from urllib.request import urlopen

APP_V = '2.1'
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
def _destino_por_defecto():
    return str(Path.home() / 'Music' / 'YTDownloader')


AJUSTES_DEFECTO = {
    'destino': _destino_por_defecto(),
    'tema': 'Oscuro',
    'formato': 'AAC',
    'calidad': '128k',
    'embeber': True,
    'navegador': '(ninguno)',
}


def cargar_ajustes():
    a = dict(AJUSTES_DEFECTO)
    try:
        a.update(json.loads(RUTA_AJUSTES.read_text(encoding='utf-8')))
    except Exception:
        pass
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

    def warning(self, m):
        m = str(m).strip()
        if m and self.log:
            self.log(m, 'aviso')

    def error(self, m):
        m = str(m).strip()
        if m and self.log:
            self.log(m, 'error')


REGISTRO = Registro()

NOMBRES_PP = {
    'FFmpegExtractAudio': 'Convirtiendo el audio con FFmpeg',
    'FFmpegMetadata': 'Escribiendo etiquetas (título/artista)',
    'EmbedThumbnail': 'Incrustando la carátula',
    'MoveFiles': 'Organizando archivos',
    'FFmpegMerger': 'Uniendo pistas de video y audio',
    'FFmpegVideoConvertor': 'Convirtiendo el video',
}

# ---------------------------------------------------------------- formatos
FORMATOS = {
    'AAC': dict(texto='AAC (.m4a)', carpeta='AAC', ext='m4a',
                calidades=['128k'], defecto='128k'),
    'MP3': dict(texto='MP3 (.mp3)', carpeta='MP3', ext='mp3',
                calidades=['128k', '192k', '256k', '320k'], defecto='320k'),
    'FLAC': dict(texto='FLAC (.flac)', carpeta='FLAC', ext='flac',
                 calidades=['sin perdida'], defecto='sin perdida'),
    'WAV': dict(texto='WAV (.wav)', carpeta='WAV', ext='wav',
                calidades=['sin perdida'], defecto='sin perdida'),
    'WMA': dict(texto='WMA (.wma)', carpeta='WMA', ext='wma',
                calidades=['128k'], defecto='128k'),
    'AVI': dict(texto='AVI - sheiju 1.8" (128x160)', carpeta='AVI', ext='avi',
                calidades=['128x160 · 16 fps'], defecto='128x160 · 16 fps'),
}


# ---------------------------------------------------------------- progreso
def hooks_gui(cola):
    """Crea los hooks de yt-dlp que publican eventos en la cola de la GUI."""
    estado = {'titulo': False}

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
            cola.put(('log', 'Descarga recibida. Procesando...', 'gris'))
            cola.put(('prog', 0, 'Procesando...'))

    def postproceso(d):
        if d['status'] == 'started':
            nom = (d.get('postprocessor_name')
                   or d.get('postprocessor') or 'Postproceso')
            texto = NOMBRES_PP.get(nom, nom) + '...'
            cola.put(('log', '→ ' + texto, 'gris'))
            cola.put(('prog', None, texto))

    return progreso, postproceso


# ---------------------------------------------------------------- opciones
def opts_base(carpeta, cookies, cola):
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
    if cookies and cookies != '(ninguno)':
        o['cookiesfrombrowser'] = (cookies,)
    if FFMPEG:
        o['ffmpeg_location'] = str(FFMPEG.parent)
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


# ---------------------------------------------------------------- descargas
def descargar_audio(url, nombre_fmt, calidad, destino, embeber, cookies, cola):
    """AAC (.m4a) / MP3 / FLAC / WAV vía postprocesadores de yt-dlp."""
    def log(m, t='info'):
        cola.put(('log', m, t))

    fmt = FORMATOS[nombre_fmt]
    carpeta = destino / fmt['carpeta']
    carpeta.mkdir(parents=True, exist_ok=True)
    codec = fmt['ext']
    con_portada = embeber and nombre_fmt in ('AAC', 'MP3', 'FLAC')
    con_tags = embeber
    pps = [{'key': 'FFmpegExtractAudio', 'preferredcodec': codec,
            'preferredquality': calidad or '0'}]
    if con_tags:
        pps.append({'key': 'FFmpegMetadata', 'add_metadata': True})
    if con_portada:
        pps.append({'key': 'EmbedThumbnail',
                    'already_have_thumbnail': False})
    o = opts_base(carpeta, cookies, cola)
    o['format'] = 'bestaudio/best'
    o['postprocessors'] = pps
    o['writethumbnail'] = con_portada
    with YT_DLP.YoutubeDL(o) as ydl:
        info = ydl.extract_info(url, download=True)
    archivo = archivo_final(info, carpeta, codec)
    if archivo and con_portada:
        limpiar_miniaturas(carpeta, archivo)
    return info, archivo


def descargar_wma(url, destino, embeber, cookies, cola):
    """WMA 128 kbps: yt-dlp no soporta wma, así que se baja a WAV (con
    etiquetas) y luego FFmpeg recodifica a wmav2 dentro del .wma final.
    (El contenedor ASF de ffmpeg no soporta carátula incrustada.)"""
    def log(m, t='info'):
        cola.put(('log', m, t))

    carpeta = destino / 'WMA'
    tmp = carpeta / '_tmp'
    shutil.rmtree(tmp, ignore_errors=True)
    tmp.mkdir(parents=True, exist_ok=True)
    o = opts_base(tmp, cookies, cola)
    o['format'] = 'bestaudio/best'
    pps = [{'key': 'FFmpegExtractAudio', 'preferredcodec': 'wav',
            'preferredquality': '0'}]
    if embeber:
        pps.append({'key': 'FFmpegMetadata', 'add_metadata': True})
    o['postprocessors'] = pps
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
        meta += ['-metadata', 'album=YouTube']
    wma = carpeta / (limpiar_nombre(info.get('title') or 'audio') + '.wma')
    cmd = [str(FFMPEG), '-y', '-i', str(wav), '-vn',
           '-c:a', 'wmav2', '-b:a', '128k'] + meta + [str(wma)]
    ok = convertir_ffmpeg(cmd, 'Convirtiendo a WMA (wmav2 · 128 kbps)', cola)
    if not ok:
        raise RuntimeError('FFmpeg no pudo crear el archivo WMA.')
    shutil.rmtree(tmp, ignore_errors=True)
    return info, wma


# Parámetros oficiales del repo fdd4s/portable_mp3_player_video_converter_tools
# (video2shenju18.sh): MJPEG 16 fps + PCM 22050 Hz, rotados para la pantalla
# vertical de 128x160 del reproductor sheiju de 1.8 pulgadas.
VF_SHEIJU = 'scale=-2:128, crop=160:128, transpose=2, vflip'
# Variante a prueba de balas para videos cuadrados/verticales (Shorts),
# donde el recorte 160:128 original sería imposible:
VF_SEGURO = ('scale=160:128:force_original_aspect_ratio=decrease,'
             'pad=160:128:(ow-iw)/2:(oh-ih)/2,transpose=2,vflip')


def descargar_avi(url, destino, cookies, cola):
    """Video AVI para el reproductor sheiju 1.8" 128x160."""
    def log(m, t='info'):
        cola.put(('log', m, t))

    carpeta = destino / 'AVI'
    tmp = carpeta / '_tmp'
    shutil.rmtree(tmp, ignore_errors=True)
    tmp.mkdir(parents=True, exist_ok=True)
    o = opts_base(tmp, cookies, cola)
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
    base = [str(FFMPEG), '-y', '-i', str(origen), '-r', '16',
            '-acodec', 'pcm_s16le', '-ac', '2', '-ar', '22050',
            '-pix_fmt', 'yuvj420p', '-c:v', 'mjpeg', '-q:v', '2']
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
    if formato == 'MP3':
        kbps = int(re.sub(r'[^0-9]', '', str(calidad)) or 320)
    else:
        kbps = KBPS_ESTIMADOS.get(formato, 128)
    extra = 120_000 if (embeber and formato in ('AAC', 'MP3', 'FLAC')) else 0
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
        if kbps >= 80:
            return 'Buena', 1
        return f'{kbps} kbps (baja)', 2
    if ext == '.wma':
        if kbps >= 115:
            return '128 kbps', 0
        if kbps >= 90:
            return 'Aceptable', 1
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

NAVEGADORES = ['(ninguno)', 'brave', 'chrome', 'chromium', 'edge', 'firefox',
               'opera', 'opera_gx', 'safari', 'vivaldi', 'whale']

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
            self.title('YouTube Downloader')
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

            # --- grupo: cookies -------------------------------------------
            gc = tk.LabelFrame(
                marco, text='Navegador para cookies (solo si es necesario)',
                font=FUENTE_UI, relief='solid', bd=1)
            gc.grid(row=3, column=0, sticky='ew', pady=5)
            self._wg['gc'] = gc
            self._wg['lbl_nav'] = tk.Label(gc, text='Navegador:',
                                          font=FUENTE_UI)
            self._wg['lbl_nav'].pack(side='left', padx=8, pady=8)
            self.cmb_navegador = ttk.Combobox(
                gc, values=NAVEGADORES, state='readonly', width=12,
                font=FUENTE_UI, style='gx.TCombobox')
            nav = AJUSTES.get('navegador', '(ninguno)')
            if nav not in NAVEGADORES:
                nav = '(ninguno)'
            self.cmb_navegador.set(nav)
            self.cmb_navegador.pack(side='left', padx=(8, 0), ipady=2)

            # --- grupo: estimación ----------------------------------------
            ge = tk.LabelFrame(marco, text='Estimación', font=FUENTE_UI,
                               relief='solid', bd=1)
            ge.grid(row=4, column=0, sticky='ew', pady=5)
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
            self.btn_descargar.grid(row=5, column=0, sticky='ew', pady=(7, 4))
            self.btn_comprobar = self._boton(
                marco, 'Comprobar calidad de la carpeta',
                self._accion_comprobar, fuente=FUENTE_BTN)
            self.btn_comprobar.grid(row=6, column=0, sticky='ew', pady=3)

            # --- estado + barra de progreso --------------------------------
            self.lbl_estado = tk.Label(marco, text='', font=FUENTE_UI,
                                       anchor='w')
            self.lbl_estado.grid(row=7, column=0, sticky='ew', pady=(4, 0))
            self.barra = ttk.Progressbar(
                marco, maximum=100, style='gx.Horizontal.TProgressbar')
            self.barra.grid(row=8, column=0, sticky='ew', pady=(2, 4))

            # --- registro (log) --------------------------------------------
            self.txt_log = ScrolledText(marco, font=FUENTE_LOG, height=12,
                                        relief='flat', bd=0, wrap='word',
                                        state='disabled')
            self.txt_log.grid(row=9, column=0, sticky='nsew')
            marco.rowconfigure(9, weight=1)
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

        # ------------------------------------------------ tema
        def _aplicar_tema(self):
            t = TEMAS[self._tema_actual]
            w = self._wg
            self.configure(bg=t['fondo'])
            for nombre in ('marco', 'f0', 'gu', 'gf', 'fc', 'gc', 'ge'):
                w[nombre].configure(bg=t['fondo'])
            for lf in (w['gu'], w['gf'], w['gc'], w['ge']):
                lf.configure(bg=t['fondo'], fg=t['texto2'])
            for nombre in ('lbl_tema', 'lbl_fmt', 'lbl_cal', 'lbl_car',
                           'lbl_nav'):
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
            self.cmb_navegador.bind('<<ComboboxSelected>>',
                                    lambda e: self._guardar())
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
            AJUSTES['navegador'] = self.cmb_navegador.get()
            AJUSTES['destino'] = self.ent_carpeta.get().strip()
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
            u, cambio = sin_playlist(u)
            if cambio:
                self._log('(se ignorará la lista de reproducción: '
                          'modo solo video)', 'gris')
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
            cfg = {'url': url}
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
                nav = AJUSTES.get('navegador', '(ninguno)')
                if nav != '(ninguno)':
                    o['cookiesfrombrowser'] = (nav,)
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

        def _hilo_descargar(self, cfg):
            cola = self.cola

            def log(m, t='info'):
                cola.put(('log', m, t))

            url = cfg['url']
            clave = self._fmt_actual_solo(AJUSTES.get('formato', 'AAC'))
            calidad = AJUSTES.get('calidad', '128k')
            embeber = bool(AJUSTES.get('embeber', True))
            nav = AJUSTES.get('navegador', '(ninguno)')
            destino = Path(os.path.expandvars(
                str(AJUSTES.get('destino', _destino_por_defecto()))))
            try:
                destino.mkdir(parents=True, exist_ok=True)
                calidad_arg = {'AAC': '128', 'FLAC': '0',
                               'WAV': '0'}.get(clave) or \
                    re.sub(r'[^0-9]', '', calidad) or '320'
                if clave == 'WMA':
                    info, archivo = descargar_wma(url, destino, embeber,
                                                  nav, cola)
                elif clave == 'AVI':
                    info, archivo = descargar_avi(url, destino, nav, cola)
                else:
                    info, archivo = descargar_audio(url, clave, calidad_arg,
                                                    destino, embeber, nav,
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
                    log('✖ No se pudo descargar: ' + msg, 'error')
                    log('Consejos: revisa la URL y tu conexión; si YouTube '
                        'cambió algo, pulsa Ctrl+U (actualizar yt-dlp) y '
                        'reintenta.', 'gris')
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
            self._log(f'Descargador de Musica v{APP_V} — '
                      'YouTube Downloader', 'titulo')
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
