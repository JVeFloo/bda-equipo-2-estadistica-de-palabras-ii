# Solución del mini ejercicio — Equipo 2

---

## Ejercicio 1

### a) Tabla

| palabra | letras | letras² |
|---|---|---|
| big | 3 | 9 |
| data | 4 | 16 |
| no | 2 | 4 |
| es | 2 | 4 |
| solo | 4 | 16 |
| mucho | 5 | 25 |
| dato | 4 | 16 |
| **TOTAL** | **`length` = 24** | **`square` = 90** |

`count` = **7**

### b) Media y desviación

```
media  = 24 / 7 = 3.4285714285714284

stddev = √( 90/7 − 3.4285714285714284² )
       = √( 12.857142857142858 − 11.755102040816327 )
       = √( 1.1020408163265306 )
       = 1.0497813183356486
```

### c) Salida de Hadoop

```
The standard deviation is: 1.0497813183356486
```

`part-r-00000`:

```
count	7
length	24
square	90
```

Los tres números coinciden con la tabla. ✔

---

## Ejercicio 2

**¿Por qué solo 3 líneas?**

Porque el Mapper emite **nada más tres claves distintas**, sin importar cuántas palabras
haya: `count`, `length` y `square`. Por cada palabra emite un par para cada una de esas
tres claves, pero siguen siendo las mismas tres claves.

El Reducer recibe una lista por clave y escribe **una línea por clave**. Tres claves,
tres líneas. Si el texto tiene mil millones de palabras, las listas que llegan al
Reducer son enormes, pero la salida sigue teniendo tres renglones.

> Compáralo con `wordcount`, donde la clave **es la palabra**: ahí la salida crece con
> el número de palabras distintas.

**¿En qué momento se calcula la raíz cuadrada?**

**No la calcula el Reducer.** El trabajo de MapReduce termina con las tres sumas
guardadas en `part-r-00000`. Después, ya terminado el job, el programa *driver* (el
método `readAndCalcStdDev` de la clase `WordStandardDeviation`) **vuelve a abrir ese
archivo**, lee los tres números, hace la división y la raíz cuadrada, e imprime
`The standard deviation is: ...` en pantalla.

La razón es de diseño: MapReduce solo sirve para operaciones que se pueden partir y
juntar (sumar, contar, máximo, mínimo). Una raíz cuadrada sobre un total global no se
puede repartir entre 1000 máquinas, pero tampoco hace falta: es una sola operación sobre
tres numeritos.

---

## Ejercicio 3

### a) Número de splits

```
/tmp/equipo2/ej3-wc.log:...   number of splits:30
/tmp/equipo2/ej3-mfwc.log:... number of splits:1
```

- `wordcount` usa `TextInputFormat`, que crea **al menos un split por archivo**:
  30 archivos → 30 splits → 30 tareas map.
- `multifilewc` usa `MyInputFormat`, que hereda de `CombineFileInputFormat`: **junta
  varios archivos en un solo split**. Como los 30 archivos son chiquitos y caben de
  sobra en un split, queda **1 split → 1 tarea map**.

### b) ¿Las salidas son iguales?

Sí, idénticas:

🐳
```bash
diff /tmp/equipo2/salida-ej3-wc/part-r-00000 \
     /tmp/equipo2/salida-ej3-mfwc/part-r-00000 && echo "IDENTICOS"
```

```
IDENTICOS
```

Tiene que ser así: el Mapper y el Reducer son los mismos. Lo único que cambió es **cómo
se repartió el trabajo**, no **qué se calculó**.

### c) 50 000 archivos de 2 KB

`wordcount` levantaría **50 000 tareas map** (una por archivo).

Es un problema aunque sean apenas 100 MB en total porque **el costo no está en los
datos, está en las tareas**:

1. Cada tarea map arranca su propia JVM. Levantarla y tirarla cuesta del orden de un
   segundo, y procesar 2 KB cuesta milisegundos. O sea que el 99 % del tiempo se va en
   *overhead*, no en trabajo útil.
2. El `ApplicationMaster` tiene que pedir, agendar y monitorear 50 000 contenedores.
3. En HDFS, cada archivo ocupa una entrada en la memoria del NameNode (unos 150 bytes),
   sin importar lo chico que sea. Millones de archivos chicos tumban al NameNode.

Esto es el **"problema de los archivos pequeños"** de Hadoop, y `CombineFileInputFormat`
—que es lo que demuestra `multifilewc`— es la solución clásica: si esos 50 000 archivos
se agrupan en splits de 128 MB, pasas de 50 000 tareas map a **1**.

---

## Ejercicio 4 (reto)

La propiedad es:

```
mapreduce.input.fileinputformat.split.maxsize
```

Se le pasa al comando con `-D` (gracias a que el ejemplo implementa `Tool` y usa
`ToolRunner`). Para splits de 64 MB:

🐳
```bash
hadoop jar $JAR multifilewc \
  -D mapreduce.input.fileinputformat.split.maxsize=67108864 \
  /tmp/equipo2/datos/muchos \
  /tmp/equipo2/salida-maxsize
```

(67 108 864 bytes = 64 MB.)

También se puede hacer por código, llamando a
`CombineFileInputFormat.setMaxInputSplitSize(job, 67108864L)`.

**La idea de fondo:** hay que buscar el punto medio.

- Splits **muy chicos** → demasiadas tareas → todo el tiempo se va en arrancar JVMs.
- Split **único y gigante** → una sola tarea map → se desperdicia todo el clúster.

Lo ideal es un split por cada bloque de HDFS (128 MB por defecto), para que cada tarea
tenga trabajo suficiente que justifique arrancarla, y a la vez haya tantas tareas como
núcleos disponibles en el clúster.

> Con nuestros 30 archivos de 4 KB no se alcanza a notar: aunque le pongas un
> `maxsize` de 64 MB, todo sigue cabiendo en un solo split. Para verlo de verdad habría
> que poner un `maxsize` ridículamente chico, por ejemplo `-D ...split.maxsize=4096`.
