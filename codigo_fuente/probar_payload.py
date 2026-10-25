#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Verifica el payload del BAT generado.

Simula EXACTAMENTE la extraccion del .bat:
    for /f "tokens=1 delims=:" %%a in ('findstr /b /c:":::" "%~f0"')
        do >>payload.b64 echo(%%a
    certutil -f -decode payload.b64 descargador.py

- findstr /b "/c:":::""  -> lineas que empiezan por ":::"
- for /f delims=:        -> descarta los ":" iniciales, token 1 = resto
- certutil               -> decodifica las lineas base64 concatenadas

Uso:  python probar_payload.py DescargadorMusica.bat descargador.py
"""
import base64
import re
import sys
from pathlib import Path

RE_B64 = re.compile(r'^[A-Za-z0-9+/]+={0,2}$')


def main(ruta_bat, ruta_py):
    bat = Path(ruta_bat).read_bytes().decode('ascii')
    original = Path(ruta_py).read_bytes()

    lineas = [ln for ln in bat.splitlines() if ln.startswith(':::')]
    if not lineas:
        print('FALLO: el BAT no contiene payload')
        return 1

    tokens = [ln.lstrip(':') for ln in lineas]   # como for /f delims=:
    for t in tokens:
        if not RE_B64.fullmatch(t):
            print(f'FALLO: token base64 invalido: {t[:50]}...')
            return 1

    reconstruido = base64.b64decode(''.join(tokens))
    if reconstruido != original:
        print(f'FALLO: el payload decodificado difiere '
              f'({len(reconstruido)} vs {len(original)} bytes)')
        return 1

    print(f'OK: payload intacto ({len(lineas)} lineas, '
          f'{len(reconstruido)} bytes, sha256 coincide por comparacion directa)')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1], sys.argv[2]))
