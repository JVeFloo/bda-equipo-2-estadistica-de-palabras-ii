# Mini ejercicio — Equipo 2

**Tema:** `wordstandarddeviation` y `multifilewc`
**Tiempo estimado:** 10–15 minutos
**Requisito:** el contenedor `hadoop` de la práctica, encendido, y la carpeta
`/tmp/equipo2/datos` ya copiada (pasos 2 y 3 del README).

---

## Ejercicio 1 — Verifica a Hadoop con lápiz y papel

El archivo `datos/frase.txt` contiene una sola línea:

```
big data no es solo mucho dato
```

**a)** Sin correr nada, llena la tabla con la longitud de cada palabra:

| palabra | letras | letras² |
|---|---|---|
| big | | |
| data | | |
| no | | |
| es | | |
| solo | | |
| mucho | | |
| dato | | |
| **TOTAL** | `length` = ? | `square` = ? |

`count` = ?

**b)** Calcula la media y la desviación estándar:

```
media  = length / count
stddev = √( square/count − media² )
```

**c)** Ahora córrelo en Hadoop y comprueba que tus tres números
(`count`, `length`, `square`) sean exactamente los mismos:

🐳
```bash
hadoop jar $JAR wordstandarddeviation \
  /tmp/equipo2/datos/frase.txt \
  /tmp/equipo2/salida-ejercicio

cat /tmp/equipo2/salida-ejercicio/part-r-00000
```

---

## Ejercicio 2 — ¿Por qué solo 3 líneas?

El archivo `part-r-00000` de `wordstandarddeviation` tiene **3 líneas** cuando procesas
un archivo de 7 palabras, y también **3 líneas** cuando procesas uno de 116 palabras.

**Pregunta:** ¿por qué la salida no crece aunque el texto crezca? Explícalo diciendo
**qué claves emite el Mapper**.

**Pregunta de remate:** entonces, ¿en qué momento se calcula la raíz cuadrada? ¿La
calcula el Reducer?

---

## Ejercicio 3 — Cuenta las tareas map

Genera 30 archivos chicos:

🐳
```bash
/tmp/equipo2/scripts/generar_muchos_archivos.sh 30
```

Corre los dos ejemplos sobre esa carpeta, guardando el log:

🐳
```bash
rm -rf /tmp/equipo2/salida-ej3-*

hadoop jar $JAR wordcount \
  /tmp/equipo2/datos/muchos /tmp/equipo2/salida-ej3-wc 2>&1 | tee /tmp/equipo2/ej3-wc.log

hadoop jar $JAR multifilewc \
  /tmp/equipo2/datos/muchos /tmp/equipo2/salida-ej3-mfwc 2>&1 | tee /tmp/equipo2/ej3-mfwc.log
```

**a)** Busca en cada log la línea que dice `number of splits`:

🐳
```bash
grep 'number of splits' /tmp/equipo2/ej3-wc.log /tmp/equipo2/ej3-mfwc.log
```

¿Cuántos splits usó cada uno?

**b)** ¿Las dos salidas son iguales? Compruébalo con `diff`.

**c)** Si en vez de 30 archivos tuvieras **50 000 archivos de 2 KB** cada uno,
¿cuántas tareas map levantaría `wordcount`? ¿Y por qué eso es un problema aunque los
datos en total sean apenas 100 MB?

---

## Ejercicio 4 (reto opcional) — Rompe el empate

`multifilewc` juntó los 30 archivos en **un solo** split. Eso está bien con 30
archivos... pero con 50 000 sería un split gigante atendido por **una sola** tarea map,
y perderíamos el paralelismo.

**Pregunta:** ¿qué propiedad de configuración le pondrías a `CombineFileInputFormat`
para que haga splits de, digamos, 64 MB cada uno en vez de uno solo?

*Pista:* busca en la documentación de Hadoop la propiedad
`mapreduce.input.fileinputformat.split.maxsize`.
