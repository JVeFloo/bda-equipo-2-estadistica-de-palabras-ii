#!/usr/bin/env bash
# ==========================================================================
#  ejecutar.sh  -  Equipo 2: Estadistica de palabras II
#  Ejemplos: wordstandarddeviation  y  multifilewc
#
#  Se ejecuta DENTRO del contenedor "hadoop", como usuario hadoop.
#  Antes de correrlo, los datos deben estar en /tmp/equipo2/datos
#  (ver el README, paso 2).
# ==========================================================================
set -euo pipefail

BASE=/tmp/equipo2
LOGS=$BASE/logs
mkdir -p "$LOGS"

# --- 1. Localizar el jar de ejemplos --------------------------------------
JAR="${HADOOP_HOME:-/opt/hadoop-3.3.6}/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar"
if [ ! -f "$JAR" ]; then
  JAR=$(find / -name 'hadoop-mapreduce-examples-*.jar' 2>/dev/null | head -n 1)
fi
if [ -z "$JAR" ] || [ ! -f "$JAR" ]; then
  echo "ERROR: no encontre el jar de ejemplos de Hadoop."
  echo "Revisa que HADOOP_HOME este definido:  echo \$HADOOP_HOME"
  exit 1
fi
echo "Usando el jar: $JAR"
echo

# --- 2. Verificar que los datos esten copiados ----------------------------
if [ ! -f "$BASE/datos/mini.txt" ]; then
  echo "ERROR: no existe $BASE/datos/mini.txt"
  echo "Copia la carpeta datos/ al contenedor (README, paso 2)."
  exit 1
fi

# Hadoop se niega a escribir sobre una carpeta de salida que ya existe.
rm -rf "$BASE"/salida-*

# ==========================================================================
#  PARTE A - wordstandarddeviation
# ==========================================================================
echo "=========================================================="
echo " A1) wordstandarddeviation sobre mini.txt (16 palabras)"
echo "=========================================================="
hadoop jar "$JAR" wordstandarddeviation \
  "$BASE/datos/mini.txt" \
  "$BASE/salida-stddev-mini" 2>&1 | tee "$LOGS/stddev-mini.log"

echo
echo "--- Contenido de part-r-00000 ---"
cat "$BASE/salida-stddev-mini/part-r-00000"
echo

echo "=========================================================="
echo " A2) wordstandarddeviation sobre corpus/ (3 archivos)"
echo "=========================================================="
hadoop jar "$JAR" wordstandarddeviation \
  "$BASE/datos/corpus" \
  "$BASE/salida-stddev-corpus" 2>&1 | tee "$LOGS/stddev-corpus.log"

echo
echo "--- Contenido de part-r-00000 ---"
cat "$BASE/salida-stddev-corpus/part-r-00000"
echo

# ==========================================================================
#  PARTE B - multifilewc
# ==========================================================================
echo "=========================================================="
echo " B1) multifilewc sobre corpus/ (3 archivos)"
echo "=========================================================="
hadoop jar "$JAR" multifilewc \
  "$BASE/datos/corpus" \
  "$BASE/salida-multifilewc-corpus" 2>&1 | tee "$LOGS/multifilewc-corpus.log"

echo
echo "--- Primeras 10 lineas de part-r-00000 ---"
head -10 "$BASE/salida-multifilewc-corpus/part-r-00000"
echo

echo "=========================================================="
echo " B2) Comparacion wordcount vs multifilewc con 60 archivos"
echo "=========================================================="
"$(dirname "$0")/generar_muchos_archivos.sh" 60

echo
echo "--- wordcount (TextInputFormat: un split por archivo) ---"
hadoop jar "$JAR" wordcount \
  "$BASE/datos/muchos" \
  "$BASE/salida-wordcount-muchos" 2>&1 | tee "$LOGS/wordcount-muchos.log"

echo
echo "--- multifilewc (CombineFileInputFormat: junta archivos) ---"
hadoop jar "$JAR" multifilewc \
  "$BASE/datos/muchos" \
  "$BASE/salida-multifilewc-muchos" 2>&1 | tee "$LOGS/multifilewc-muchos.log"

echo
echo "=========================================================="
echo " RESUMEN: numero de splits (= numero de tareas map)"
echo "=========================================================="
echo -n "wordcount   -> "; grep -o 'number of splits:[0-9]*' "$LOGS/wordcount-muchos.log"   | tail -1
echo -n "multifilewc -> "; grep -o 'number of splits:[0-9]*' "$LOGS/multifilewc-muchos.log" | tail -1
echo
echo "Los dos resultados deben ser identicos:"
diff -q "$BASE/salida-wordcount-muchos/part-r-00000" \
        "$BASE/salida-multifilewc-muchos/part-r-00000" \
  && echo "OK: wordcount y multifilewc dan exactamente la misma salida."

echo
echo "Listo. Las salidas estan en $BASE/salida-* y los logs en $LOGS"
