#!/usr/bin/env bash
# ==========================================================================
#  generar_muchos_archivos.sh
#  Crea muchos archivos chicos a partir de datos/corpus/ para demostrar
#  el "problema de los archivos pequenios" que resuelve multifilewc.
#
#  Se ejecuta DENTRO del contenedor, como usuario hadoop.
#  Uso:  ./generar_muchos_archivos.sh [cantidad]     (por defecto 60)
# ==========================================================================
set -euo pipefail

BASE=/tmp/equipo2
CANTIDAD=${1:-60}

if [ ! -d "$BASE/datos/corpus" ]; then
  echo "ERROR: no existe $BASE/datos/corpus"
  echo "Primero copia los datos al contenedor con 'docker cp'."
  exit 1
fi

rm -rf "$BASE/datos/muchos"
mkdir -p "$BASE/datos/muchos"

# Copia ciclicamente texto1, texto2, texto3 para que el resultado
# sea siempre el mismo y se pueda verificar: cada texto aparece
# CANTIDAD/3 veces.
i=1
while [ "$i" -le "$CANTIDAD" ]; do
  n=$(( (i - 1) % 3 + 1 ))
  cp "$BASE/datos/corpus/texto${n}.txt" \
     "$BASE/datos/muchos/parte_$(printf '%03d' "$i").txt"
  i=$(( i + 1 ))
done

echo "Listos $CANTIDAD archivos en $BASE/datos/muchos"
du -sh "$BASE/datos/muchos"
