# Diapositivas — Equipo 2

Presentación hecha con [Reveal.js](https://revealjs.com/) 5.1.0. 17 diapositivas,
pensadas para unos 10 minutos.

## Verlas

| Archivo | Para qué |
|---|---|
| `index.html` | Versión normal. Carga Reveal.js y las tipografías desde internet. |
| `index-offline.html` | Versión que no necesita internet. Usa los archivos de `vendor/`. |
| `../presentacion.pdf` | Exportación en PDF, por si falla todo lo demás el día de la exposición. |

Ábrelas con doble clic, o desde la terminal:

```bash
xdg-open index-offline.html
```

## Cómo se maneja

| Tecla | Qué hace |
|---|---|
| `→` `←` o barra espaciadora | Avanzar y retroceder |
| `Esc` | Vista de rejilla con todas las diapositivas |
| `S` | Abre la ventana del presentador, con notas y cronómetro |
| `F` | Pantalla completa |
| `B` | Pantalla en negro (útil al cambiar a la terminal para la demo) |

Las diapositivas no tienen flechas de navegación en pantalla, a propósito: estorbaban
con el margen perforado del papel. Se avanza con el teclado o con un apuntador.

## Volver a generar la versión sin internet

Solo hay que correrlo una vez, teniendo internet. Descarga Reveal.js y las tipografías
IBM Plex a `vendor/` y vuelve a crear `index-offline.html`:

```bash
./preparar_offline.sh
```

Córrelo otra vez cada que edites `index.html`, para que los cambios pasen a la versión
sin internet.

## Volver a exportar el PDF

1. Abre `index-offline.html?print-pdf` en Chrome o Chromium.
2. `Ctrl + P`.
3. Destino: **Guardar como PDF**. Orientación: **Horizontal**. Márgenes: **Ninguno**.
   Y activa **Gráficos de fondo**, o las bandas verdes salen en blanco.
4. Guárdalo como `presentacion.pdf` en la raíz del repositorio.

Las diapositivas que se revelan por partes ya están configuradas para salir en **una
sola página** con todo visible (`pdfSeparateFragments: false`).

## Cómo está armado

Todo vive en `index.html`: un solo archivo con el tema escrito a mano en el `<style>`
de arriba y las 17 diapositivas abajo, una por cada `<section>`. No hay build ni
dependencias que instalar.

El tema imita el **papel continuo de impresora de línea**, que es donde salían los
resultados del procesamiento por lotes en los mainframes. Las bandas verdes aparecen
solo donde hay resultados tabulados, nunca de adorno, y el rojo se usa únicamente para
anotaciones.

Dos detalles por si editas el archivo:

- Reveal fija `display` por JavaScript en cada diapositiva, así que el flexbox del
  diseño solo funciona gracias a la opción `display: 'flex'` de `Reveal.initialize`.
- Reveal 5 no define `display: block` para `pre code`; eso normalmente lo trae el tema
  de resaltado de sintaxis, que aquí no se carga para conservar la paleta del papel.
  Por eso está puesto a mano en el CSS.
