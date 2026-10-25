#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Empaqueta descargador.py dentro de DescargadorMusica.bat
========================================================
Genera el instalador todo-en-uno: toma la plantilla del .bat (ASCII puro)
y le añade el script de la interfaz codificado en base64 (líneas de 64
caracteres, prefijo ":::"), que el .bat extrae con findstr + certutil.

Uso:
    python empaquetar.py                    # usa rutas por defecto
    python empaquetar.py descargador.py salida.bat

Rutas por defecto: descargador.py y plantilla_bat.txt en esta misma
carpeta; salida en la carpeta superior (../DescargadorMusica.bat).
"""
import base64
import re
import sys
from pathlib import Path

AQUI = Path(__file__).resolve().parent
RE_B64 = re.compile(r'^[A-Za-z0-9+/]+={0,2}$')


def empaquetar(ruta_py=None, ruta_plantilla=None, ruta_salida=None):
    ruta_py = Path(ruta_py or AQUI / 'descargador.py')
    ruta_plantilla = Path(ruta_plantilla or AQUI / 'plantilla_bat.txt')
    if ruta_salida is None:
        ruta_salida = (AQUI.parent / 'DescargadorMusica.bat')
        if not ruta_salida.parent.exists():
            ruta_salida = AQUI / 'DescargadorMusica.bat'
    ruta_salida = Path(ruta_salida)

    codigo = ruta_py.read_bytes()
    if not codigo:
        raise SystemExit(f'ERROR: {ruta_py} esta vacio')

    b64 = base64.b64encode(codigo).decode('ascii')
    lineas = [b64[i:i + 64] for i in range(0, len(b64), 64)]
    for l in lineas:
        if not RE_B64.fullmatch(l):
            raise SystemExit('ERROR: linea base64 con caracteres inesperados')

    # La plantilla debe ser ASCII puro (cmd no es UTF-8) y no contener
    # lineas ":::" que confundirian a la extraccion.
    plantilla = ruta_plantilla.read_text(encoding='ascii')
    for n, ln in enumerate(plantilla.splitlines(), 1):
        if ln.startswith(':::'):
            raise SystemExit(f'ERROR: la plantilla tiene ":::" en linea {n}')

    partes = [plantilla.replace('\r\n', '\n').rstrip('\n'), '']
    partes.append('rem ============ SCRIPT PYTHON EMBEBIDO (generado; no editar) ============')
    partes.extend(':::' + l for l in lineas)
    # Normaliza TODO a CRLF (cmd.exe es mas feliz con finales de linea DOS)
    bat = '\r\n'.join(partes) + '\r\n'
    bat = bat.replace('\r\n', '\n').replace('\n', '\r\n')

    ruta_salida.parent.mkdir(parents=True, exist_ok=True)
    ruta_salida.write_bytes(bat.encode('ascii'))
    return ruta_salida, len(lineas), len(bat.encode('ascii'))


if __name__ == '__main__':
    py = sys.argv[1] if len(sys.argv) > 1 else None
    out = sys.argv[2] if len(sys.argv) > 2 else None
    ruta, n_lineas, n_bytes = empaquetar(py, None, out)
    print(f'Generado: {ruta}')
    print(f'  Payload: {n_lineas} lineas base64, {n_bytes} bytes totales')
