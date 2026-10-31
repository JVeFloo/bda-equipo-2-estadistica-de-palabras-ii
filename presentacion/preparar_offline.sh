#!/usr/bin/env bash
# ==========================================================================
#  preparar_offline.sh
#  Descarga Reveal.js y las tipografias a vendor/ y genera
#  index-offline.html, que funciona sin internet.
#
#  Se ejecuta EN TU COMPUTADORA (no en el contenedor), una sola vez,
#  teniendo internet:   ./preparar_offline.sh
# ==========================================================================
set -euo pipefail
cd "$(dirname "$0")"

VERSION=5.1.0
CDN="https://cdnjs.cloudflare.com/ajax/libs/reveal.js/$VERSION"

echo "1/3  Descargando Reveal.js $VERSION..."
mkdir -p vendor/plugin/highlight vendor/plugin/notes vendor/fonts
curl -fsSL "$CDN/reveal.min.css"                    -o vendor/reveal.min.css
curl -fsSL "$CDN/reveal.min.js"                     -o vendor/reveal.min.js
curl -fsSL "$CDN/plugin/highlight/highlight.min.js" -o vendor/plugin/highlight/highlight.min.js
curl -fsSL "$CDN/plugin/notes/notes.min.js"         -o vendor/plugin/notes/notes.min.js

echo "2/3  Descargando las tipografias IBM Plex..."
# Si esto falla, las diapositivas igual funcionan: caen a las fuentes del sistema.
python3 - <<'PY' || echo "     (no se pudieron bajar las fuentes; se usaran las del sistema)"
import re, urllib.request, pathlib

URL = ("https://fonts.googleapis.com/css2?"
       "family=IBM+Plex+Mono:wght@400;600"
       "&family=IBM+Plex+Sans+Condensed:wght@600;700"
       "&family=IBM+Plex+Sans:wght@400;500;600&display=swap")

def traer(url):
    # Hay que mandar un User-Agent completo: con uno generico, Google Fonts
    # devuelve .ttf (pesado) en vez de .woff2.
    navegador = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
                 "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    pedido = urllib.request.Request(url, headers={"User-Agent": navegador})
    return urllib.request.urlopen(pedido, timeout=30).read()

css = traer(URL).decode("utf-8")
destino = pathlib.Path("vendor/fonts")
destino.mkdir(parents=True, exist_ok=True)

enlaces = sorted(set(re.findall(r"url\((https://[^)]+\.(?:woff2|woff|ttf))\)", css)))
for i, enlace in enumerate(enlaces):
    nombre = f"plex-{i:02d}" + enlace[enlace.rindex("."):]
    (destino / nombre).write_bytes(traer(enlace))
    css = css.replace(enlace, f"fonts/{nombre}")

pathlib.Path("vendor/fonts.css").write_text(css, encoding="utf-8")
guardados = len(list(destino.glob("plex-*")))
if guardados == 0:
    raise SystemExit("no se encontro ninguna fuente en el CSS")
print(f"     {guardados} archivos de fuente guardados")
PY

echo "3/3  Generando index-offline.html..."
python3 - <<'PY'
import pathlib, re

html = pathlib.Path("index.html").read_text(encoding="utf-8")
html = html.replace("https://cdnjs.cloudflare.com/ajax/libs/reveal.js/5.1.0/", "vendor/")

# Quita los <link> de Google Fonts
html = re.sub(r'\n<link rel="preconnect" href="https://fonts\.[^"]*"[^>]*>', "", html)
if pathlib.Path("vendor/fonts.css").exists():
    reemplazo = '\n<link rel="stylesheet" href="vendor/fonts.css">'
else:
    reemplazo = ""
html = re.sub(r'\n<link href="https://fonts\.googleapis\.com[^"]*" rel="stylesheet">',
              reemplazo, html)

pathlib.Path("index-offline.html").write_text(html, encoding="utf-8")
PY

echo
echo "Listo. Abre index-offline.html: ya no necesita internet."
