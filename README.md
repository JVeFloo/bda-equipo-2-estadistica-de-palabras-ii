# Equipo 2 — Estadística de palabras II

Ejemplos de MapReduce: **`wordstandarddeviation`** y **`multifilewc`**

| | |
|---|---|
| **Materia** | Manejo Masivo de Datos (Big Data) |
| **Profesor** | José Javier Moya Moya |
| **Actividad** | EP.02.02 — Exposiciones por equipos: Ejemplos de MapReduce |
| **Integrantes** | Jeshua Vera Flores · Andrea Isabel Vega Martínez |

> **Cómo leer este README**
> Cada bloque de comandos está marcado así:
> 💻 = se escribe en la terminal de **tu computadora**
> 🐳 = se escribe **dentro del contenedor** `hadoop` (el prompt dice `hadoop@hadoop`)

---

## 1. ¿Qué hace cada ejemplo?

### 1.1 `wordstandarddeviation`

Calcula la **desviación estándar de la longitud de las palabras** de un texto.

En cristiano: cuenta cuántas letras tiene cada palabra y luego dice **qué tan parejas o
qué tan dispares son esas longitudes**.

- Desviación **chica** → casi todas las palabras miden lo mismo.
- Desviación **grande** → hay palabras muy cortas mezcladas con palabras muy largas.

**Caso de uso real:** medir la *legibilidad* de un texto. Las editoriales, los
periódicos y las apps educativas usan la longitud promedio de palabra y su dispersión
como una de las señales para clasificar un texto como "fácil" o "difícil" (es parte de
índices como Flesch o Fernández-Huerta). Si tienes 50 millones de artículos y quieres
clasificarlos por dificultad, no los puedes procesar en una sola computadora: ahí entra
MapReduce.

Otro caso: detectar *spam* o texto generado automáticamente. Un texto con una
distribución de longitudes rarísima suele ser basura generada por un bot.

### 1.2 `multifilewc`

Es **un contador de palabras exactamente igual que `wordcount`**... pero por dentro lee
los archivos de otra manera.

El truco no está en el Map ni en el Reduce (son los mismos que `wordcount`). Está en el
**InputFormat**, que es la parte de Hadoop que decide *cómo se parte la entrada en
pedacitos de trabajo* (los *splits*).

- `wordcount` usa `TextInputFormat` → **mínimo un split por archivo**.
- `multifilewc` usa `CombineFileInputFormat` → **mete varios archivos chicos en un solo split**.

**Analogía:** tienes que mandar 60 hojas por paquetería.
`wordcount` manda **60 sobres**, uno por hoja: pagas 60 veces el envío.
`multifilewc` mete las 60 hojas en **una sola caja**: un solo envío.
Las hojas son las mismas, el costo no.

**Caso de uso real:** esto resuelve el famoso **"problema de los archivos pequeños"** de
Hadoop. Pasa todo el tiempo con logs (un archivo por hora por servidor), con datos de
sensores IoT (un archivo por lectura) o con exportaciones de APIs. Si tienes 100 000
archivos de 5 KB, `wordcount` levantaría 100 000 tareas map; cada una tarda segundos
nomás en arrancar su JVM, así que el trabajo se tarda horas en algo que debería tomar
minutos. `multifilewc` demuestra la solución.

---

## 2. Requisitos

- El contenedor de la práctica **Hadoop Standalone en contenedor Debian**, con
  **Hadoop 3.3.6** funcionando y el usuario `hadoop` creado.
- Docker instalado en tu computadora.
- Nada más. **No se necesita HDFS ni YARN**: en modo *standalone* Hadoop trabaja
  directamente sobre el sistema de archivos del contenedor, por eso las rutas son
  rutas normales de Linux (`/tmp/equipo2/...`) y no rutas de HDFS.

Verifica que el contenedor exista:

💻
```bash
docker ps -a
```

En la columna `STATUS` debe aparecer `Up` (prendido) o `Exited` (apagado). Si está
apagado, enciéndelo:

💻
```bash
docker start -ai hadoop
```

---

## 3. Estructura del repositorio

```
bda-equipo-2-estadistica-de-palabras-ii/
├── README.md                         ← esta guía
├── datos/
│   ├── mini.txt                      ← 16 palabras, para verificar a mano
│   ├── frase.txt                     ← 7 palabras, para el mini ejercicio
│   └── corpus/
│       ├── texto1.txt
│       ├── texto2.txt
│       └── texto3.txt
├── scripts/
│   ├── ejecutar.sh                   ← todos los comandos en orden
│   └── generar_muchos_archivos.sh    ← crea 60 archivos chicos para la demo
├── resultados/                       ← salidas esperadas (para comparar)
│   ├── stddev-mini_part-r-00000.txt
│   ├── stddev-corpus_part-r-00000.txt
│   ├── multifilewc-corpus_part-r-00000.txt
│   ├── multifilewc-muchos_part-r-00000.txt
│   └── capturas/
│       └── splits-60-vs-1.png        ← la evidencia de 60 splits vs 1
├── ejercicio/
│   ├── ejercicio.md                  ← mini ejercicio para los compañeros
│   └── solucion.md                   ← solución
├── presentacion/
│   ├── index.html                    ← las diapositivas (Reveal.js)
│   ├── index-offline.html            ← la misma versión, sin necesitar internet
│   ├── preparar_offline.sh           ← descarga Reveal.js y las tipografías
│   └── vendor/                       ← Reveal.js e IBM Plex, para el modo sin internet
└── presentacion.pdf                  ← las diapositivas en PDF
```

---

## 4. Paso a paso

### Paso 1 — Clonar este repositorio

💻
```bash
git clone https://github.com/JVeFloo/bda-equipo-2-estadistica-de-palabras-ii.git
cd bda-equipo-2-estadistica-de-palabras-ii
```

### Paso 2 — Copiar los datos y los scripts al contenedor

El contenedor **no ve** las carpetas de tu computadora, hay que pasarle los archivos con
`docker cp`. Primero creamos la carpeta de trabajo dentro del contenedor:

💻
```bash
docker exec -u root hadoop mkdir -p /tmp/equipo2
```

Ahora copiamos `datos/` y `scripts/`:

💻
```bash
docker cp datos    hadoop:/tmp/equipo2/
docker cp scripts  hadoop:/tmp/equipo2/
```

Los archivos copiados con `docker cp` quedan como propiedad de `root`, y nosotros
trabajamos como `hadoop`. Hay que cambiarles el dueño y dejar los scripts ejecutables:

💻
```bash
docker exec -u root hadoop chown -R hadoop:hadoop /tmp/equipo2
docker exec -u root hadoop chmod +x /tmp/equipo2/scripts/ejecutar.sh /tmp/equipo2/scripts/generar_muchos_archivos.sh
```

### Paso 3 — Entrar al contenedor como usuario `hadoop`

💻
```bash
docker exec -it -u hadoop hadoop bash
```

A partir de aquí tu prompt dice `hadoop@hadoop` y **ya estás dentro del contenedor**.
Comprueba que Hadoop responde:

🐳
```bash
hadoop version
```

Debe decir `Hadoop 3.3.6`.

Y guarda la ruta del jar de ejemplos en una variable, para no escribirla cada vez:

🐳
```bash
export JAR=$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar
ls -lh $JAR
```

> Si marca `No such file or directory`, tu `HADOOP_HOME` apunta a otro lado.
> Búscalo con: `find / -name 'hadoop-mapreduce-examples-*.jar' 2>/dev/null`

### Paso 4 — `wordstandarddeviation` sobre un texto chiquito

Empezamos con `mini.txt`, que tiene solo 16 palabras, para poder **verificar el
resultado a mano**.

🐳
```bash
cat /tmp/equipo2/datos/mini.txt
```

```
el dato es el nuevo petroleo
los datos crudos no sirven
hay que limpiar los datos
```

Ahora el trabajo de MapReduce. La sintaxis es
`hadoop jar <jar> <ejemplo> <entrada> <salida>`:

🐳
```bash
hadoop jar $JAR wordstandarddeviation \
  /tmp/equipo2/datos/mini.txt \
  /tmp/equipo2/salida-stddev-mini
```

**Resultado esperado.** Entre todos los mensajes del log, hasta abajo aparece:

```
The standard deviation is: 1.8666480653835098
```

Y el archivo de salida:

🐳
```bash
cat /tmp/equipo2/salida-stddev-mini/part-r-00000
```

```
count	16
length	66
square	328
```

Léelo así: hay **16 palabras**, entre todas suman **66 letras**, y la suma de los
**cuadrados** de sus longitudes es **328**. Con esos tres números se saca la desviación
(lo vemos en la sección 5).

### Paso 5 — `wordstandarddeviation` sobre una carpeta completa

Si le pasas una **carpeta** en lugar de un archivo, Hadoop procesa todos los archivos
que haya adentro:

🐳
```bash
hadoop jar $JAR wordstandarddeviation \
  /tmp/equipo2/datos/corpus \
  /tmp/equipo2/salida-stddev-corpus
```

**Resultado esperado:**

```
The standard deviation is: 2.3012397785607734
```

🐳
```bash
cat /tmp/equipo2/salida-stddev-corpus/part-r-00000
```

```
count	116
length	513
square	2883
```

### Paso 6 — `multifilewc` sobre la misma carpeta

🐳
```bash
hadoop jar $JAR multifilewc \
  /tmp/equipo2/datos/corpus \
  /tmp/equipo2/salida-multifilewc-corpus
```

**Resultado esperado:** 74 palabras distintas. Las primeras líneas:

🐳
```bash
head -10 /tmp/equipo2/salida-multifilewc-corpus/part-r-00000
```

```
alcanza	1
antes	1
bueno	1
casi	1
chica	1
clave	2
computadoras	1
con	1
conjunto	1
cortas	1
```

Hasta aquí se ve idéntico a `wordcount`. **Y lo es**: esa es justo la gracia. La
diferencia se nota en el siguiente paso.

### Paso 7 — La demo importante: `wordcount` vs `multifilewc`

Generamos 60 archivos chicos (20 copias de cada texto del corpus, así el resultado es
siempre el mismo y se puede verificar):

🐳
```bash
/tmp/equipo2/scripts/generar_muchos_archivos.sh 60
```

Corremos los dos ejemplos sobre esos 60 archivos, guardando el log:

🐳
```bash
hadoop jar $JAR wordcount \
  /tmp/equipo2/datos/muchos \
  /tmp/equipo2/salida-wordcount-muchos 2>&1 | tee /tmp/equipo2/wc.log
```

🐳
```bash
hadoop jar $JAR multifilewc \
  /tmp/equipo2/datos/muchos \
  /tmp/equipo2/salida-multifilewc-muchos 2>&1 | tee /tmp/equipo2/mfwc.log
```

Y ahora **la línea que hay que enseñar en la exposición**: cuántos *splits* (= cuántas
tareas map) generó cada uno.

🐳
```bash
grep 'number of splits' /tmp/equipo2/wc.log /tmp/equipo2/mfwc.log
```

**Resultado esperado:**

```
/tmp/equipo2/wc.log:...  number of splits:60
/tmp/equipo2/mfwc.log:...  number of splits:1
```

**60 tareas map contra 1 tarea map**, para procesar exactamente los mismos datos.
Y las dos salidas son idénticas:

🐳
```bash
diff /tmp/equipo2/salida-wordcount-muchos/part-r-00000 \
     /tmp/equipo2/salida-multifilewc-muchos/part-r-00000 && echo "IDENTICOS"
```

```
IDENTICOS
```

> Mismo resultado, 60 veces menos tareas. Eso es `multifilewc`.

### Paso 8 — Copiar los resultados a tu computadora

Abre **otra terminal** (esta sí en tu computadora) y copia las salidas al repositorio:

💻
```bash
docker cp hadoop:/tmp/equipo2/salida-stddev-mini/part-r-00000           resultados/stddev-mini_part-r-00000.txt
docker cp hadoop:/tmp/equipo2/salida-stddev-corpus/part-r-00000         resultados/stddev-corpus_part-r-00000.txt
docker cp hadoop:/tmp/equipo2/salida-multifilewc-corpus/part-r-00000    resultados/multifilewc-corpus_part-r-00000.txt
docker cp hadoop:/tmp/equipo2/salida-multifilewc-muchos/part-r-00000    resultados/multifilewc-muchos_part-r-00000.txt
```

### Atajo: correr todo de un jalón

El script `ejecutar.sh` hace los pasos 4 al 7 completos y al final imprime el resumen de
splits:

🐳
```bash
/tmp/equipo2/scripts/ejecutar.sh
```

---

## 5. Cómo funcionan por dentro (Map y Reduce)

### 5.1 `wordstandarddeviation`

Lo primero que sorprende: **el trabajo de MapReduce no calcula la desviación estándar**.
Solo calcula **tres sumas**. La desviación se saca al final, con una división y una raíz
cuadrada, ya fuera de MapReduce.

¿Por qué? Porque una suma es *distribuible*: puedes sumar por partes en 1000 máquinas y
luego sumar los resultados parciales. Una raíz cuadrada no.

**El Mapper** recibe una línea de texto y, por **cada palabra**, emite **tres** pares
clave-valor:

| clave | valor |
|---|---|
| `length` | cuántas letras tiene la palabra |
| `square` | esas letras **al cuadrado** |
| `count` | `1` |

**El Reducer** hace lo más simple del mundo: **suma todos los valores de cada clave**.
El mismo reducer se usa también como *combiner*, o sea que va pre-sumando dentro de
cada tarea map para mandar menos datos por la red. Esto se comprueba en los contadores
del log: al correr `mini.txt` sale `Map output records=48` (16 palabras × 3 pares) pero
`Combine output records=3`, así que al Reducer solo le llegan 3 registros
(`Reduce input records=3`) en vez de 48.

Como solo hay 3 claves posibles, la salida siempre tiene **3 líneas**, sin importar si
el texto trae 16 palabras o 16 mil millones.

```
ENTRADA (una línea):   "el dato es el"
         │
         ▼
   ┌───────────┐
   │    MAP    │   por cada palabra, 3 pares
   └───────────┘
         │
   "el"   (2 letras) → (length, 2)  (square,  4)  (count, 1)
   "dato" (4 letras) → (length, 4)  (square, 16)  (count, 1)
   "es"   (2 letras) → (length, 2)  (square,  4)  (count, 1)
   "el"   (2 letras) → (length, 2)  (square,  4)  (count, 1)
         │
         ▼
   SHUFFLE  (Hadoop agrupa por clave)
   count  → [1, 1, 1, 1]
   length → [2, 4, 2, 2]
   square → [4,16, 4, 4]
         │
         ▼
   ┌───────────┐
   │  REDUCE   │   suma los valores de cada clave
   └───────────┘
         │
         ▼
   part-r-00000:
   count    16        ← (con el archivo mini.txt completo)
   length   66
   square   328
         │
         ▼
   FUERA de MapReduce, el programa lee ese archivo y calcula:

       media  = length / count         = 66 / 16 = 4.125
       stddev = √( square/count − media² )
              = √( 328/16 − 4.125² )
              = √( 20.5 − 17.015625 )
              = √ 3.484375
              = 1.8666480653835098
```

La fórmula sale de la identidad de estadística **Var(X) = E[X²] − (E[X])²**. Por eso
basta con guardar la suma de longitudes y la suma de longitudes al cuadrado: con esos
dos números (más el conteo) se reconstruye la varianza sin volver a leer el texto.

> Ojo: es la desviación estándar **poblacional** (divide entre `n`, no entre `n−1`).

### 5.2 `multifilewc`

El Map y el Reduce son **los mismos que `wordcount`**:

```
ENTRADA:   "la fase map y la fase reduce"
         │
         ▼
   ┌───────────┐
   │    MAP    │   cada palabra → (palabra, 1)
   └───────────┘
         │
   (la,1) (fase,1) (map,1) (y,1) (la,1) (fase,1) (reduce,1)
         │
         ▼
   SHUFFLE
   fase   → [1,1]
   la     → [1,1]
   map    → [1]
   reduce → [1]
   y      → [1]
         │
         ▼
   ┌───────────┐
   │  REDUCE   │   IntSumReducer: suma
   └───────────┘
         │
         ▼
   fase 2 │ la 2 │ map 1 │ reduce 1 │ y 1
```

Lo que cambia es **lo que pasa ANTES del Map**: cómo se arma el *split*.

```
   wordcount                            multifilewc
   (TextInputFormat)                    (CombineFileInputFormat)

 parte_001.txt → split 1 → map 1      parte_001.txt ─┐
 parte_002.txt → split 2 → map 2      parte_002.txt ─┤
 parte_003.txt → split 3 → map 3      parte_003.txt ─┼─→ UN split → map 1
      ...            ...                   ...      ─┤
 parte_060.txt → split 60 → map 60    parte_060.txt ─┘

 60 tareas map para 240 KB            1 tarea map para los mismos 240 KB
```

Dos detalles finos que se notan al leer el código del ejemplo:

1. La clave que recibe el Mapper **no** es el desplazamiento en bytes como en
   `wordcount`: es un objeto `WordOffset` que guarda **nombre de archivo + posición**.
   Como el split ahora mezcla varios archivos, hay que saber de cuál venía cada línea.
2. `CombineFileInputFormat` **respeta la localidad de los datos**: agrupa de preferencia
   archivos que viven en el mismo nodo del clúster, para no mover datos por la red. En
   modo standalone esto no se aprecia porque todo está en la misma máquina.

---

## 6. Resumen de resultados esperados

| Comando | Entrada | Salida clave |
|---|---|---|
| `wordstandarddeviation` | `datos/mini.txt` (16 palabras) | `count 16`, `length 66`, `square 328` → **σ = 1.8666480653835098** |
| `wordstandarddeviation` | `datos/corpus/` (116 palabras) | `count 116`, `length 513`, `square 2883` → **σ = 2.3012397785607734** |
| `multifilewc` | `datos/corpus/` | 74 palabras distintas |
| `wordcount` | `datos/muchos/` (60 archivos) | **number of splits: 60** |
| `multifilewc` | `datos/muchos/` (60 archivos) | **number of splits: 1** (misma salida) |

Las salidas completas están en la carpeta [`resultados/`](resultados/) para comparar, y
la captura de la comparación de splits en
[`resultados/capturas/splits-60-vs-1.png`](resultados/capturas/splits-60-vs-1.png).
Estos valores están verificados: son la salida real de Hadoop 3.3.6 corriendo en el
contenedor, no un cálculo aparte.

---

## 7. Errores comunes (nos pasaron a nosotros)

**1. `FileAlreadyExistsException: Output directory ... already exists`**

Hadoop **se niega** a escribir sobre una carpeta de salida que ya existe, para no borrar
resultados por accidente. Es el error número uno. Solución: borra la carpeta o usa otro
nombre.

🐳
```bash
rm -rf /tmp/equipo2/salida-stddev-mini
```

**2. `chmod: cannot access '/tmp/equipo2/scripts/*.sh': No such file or directory`**

El comodín `*` no funciona a través de `docker exec`, porque `docker exec` no abre una
shell: ejecuta el comando directo, así que nadie expande el `*`. O nombras los dos
archivos completos:

💻
```bash
docker exec -u root hadoop chmod +x /tmp/equipo2/scripts/ejecutar.sh /tmp/equipo2/scripts/generar_muchos_archivos.sh
```

o metes el comando dentro de una shell del contenedor, que ahí sí lo expande:

💻
```bash
docker exec -u root hadoop bash -c 'chmod +x /tmp/equipo2/scripts/*.sh'
```

**3. `Permission denied` al leer los datos**

Los archivos copiados con `docker cp` quedan como `root` y nosotros corremos como
`hadoop`. Desde tu computadora:

💻
```bash
docker exec -u root hadoop chown -R hadoop:hadoop /tmp/equipo2
```

**4. `Input path does not exist: file:/...`**

O se te olvidó el `docker cp`, o escribiste una ruta relativa. Usa **siempre rutas
absolutas** (`/tmp/equipo2/datos/...`). Verifica con `ls /tmp/equipo2/datos`.

**5. `docker: command not found` dentro del contenedor**

Te confundiste de terminal. Si tu prompt dice `hadoop@hadoop` o `root@hadoop`, estás
**dentro** del contenedor: ahí no hay Docker. Abre otra terminal en tu computadora.

**6. `hadoop: command not found`, o `$JAR` vacío**

Entraste como `root` en vez de como `hadoop`. Cámbiate de usuario:

🐳
```bash
su - hadoop
```

**7. La cuenta a mano no coincide con la de Hadoop**

Hadoop separa las palabras con `StringTokenizer`, que corta **solo** por espacios,
tabuladores y saltos de línea. O sea que **la puntuación se queda pegada a la palabra**:
`datos.` cuenta como **6 letras**, no 5. Por eso los archivos de `datos/` no tienen
comas ni puntos: para que los números cuadren al verificarlos a mano.

**8. `number of splits:1` también en `wordcount`**

Te faltó generar los 60 archivos; estás corriendo sobre un solo archivo. Corre primero
`generar_muchos_archivos.sh`.

---

## 8. Mini ejercicio

Está en [`ejercicio/ejercicio.md`](ejercicio/ejercicio.md), con la solución en
[`ejercicio/solucion.md`](ejercicio/solucion.md).

---

## 9. Las diapositivas

La exposición está en [`presentacion/index.html`](presentacion/index.html), hecha con
Reveal.js. Se abre con doble clic y se avanza con las flechas; `S` abre las notas del
presentador y `B` pone la pantalla en negro para cambiar a la terminal durante la demo.

Si el salón no tiene internet, usa [`presentacion/index-offline.html`](presentacion/index-offline.html),
o de plano el [`presentacion.pdf`](presentacion.pdf). Los detalles están en
[`presentacion/README.md`](presentacion/README.md).

---

## 10. Referencias

- Código fuente de los ejemplos: `org.apache.hadoop.examples.WordStandardDeviation` y
  `org.apache.hadoop.examples.MultiFileWordCount` (paquete
  `hadoop-mapreduce-examples-3.3.6`).
- Documentación de Apache Hadoop 3.3.6: <https://hadoop.apache.org/docs/r3.3.6/>
- Práctica base de la materia: *Hadoop Standalone en contenedor Debian*.
