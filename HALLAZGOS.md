# HALLAZGOS · Zofía

> Registro vivo de BUGs, GAPs, ERRORs e IDEAs descubiertos durante la construcción de Zofía.
> Zofía es el primer proyecto de computación científica en Zymbol — construir tensores,
> gradientes y un transformer desde cero expone los límites del lenguaje en el dominio numérico
> de la misma forma que Serpiente los expuso en el dominio TUI.
>
> Este documento alimenta directamente el roadmap de Zymbol v0.0.6 y versiones futuras.
> Los ítems marcados `anticipado` se identificaron en la Fase 0 (diseño), antes de escribir código.

---

## Vínculo con Zymbol v0.0.6

Los GAPs e IDEAs de este documento están formalmente incorporados en
`interpreter/ROADMAP.md` — sección **v0.0.6 Roadmap**.

El ciclo de retroalimentación es:

```
Zofía construye algo real
        │
        ▼
HALLAZGOS.md documenta qué falta
        │
        ▼
interpreter/ROADMAP.md lo incorpora en v0.0.6
        │
        ▼
Zymbol mejora → Zofía desbloquea la siguiente fase
```

Zofía no puede avanzar más allá de la Fase 2 hasta que `std/math` llegue al
lenguaje. Esa dependencia hace que Zofía sea el driver de v0.0.6, no un
proyecto secundario.

---

## Antecedente: lecciones de Serpiente

`serpiente/HALLAZGOS_ES.md` fue el primer ciclo de retroalimentación entre un proyecto
real en Zymbol y el lenguaje. Impulsó las siguientes mejoras en v0.0.5:

| Item Serpiente | Mejora producida en Zymbol |
|----------------|---------------------------|
| GAP-001 | Operador `$*` de repetición de string |
| GAP-003 | `TuiGuard` con `Drop` en el VM — cleanup garantizado |
| GAP-005 | `>>~` con slots sparse y atributos Bold/Italic/Underline |
| GAP-006 | LSP reconoce `<<|` como definición de variable |
| BUG-001 | `parse_output_items` delimitado por línea fuente |
| BUG-005 | Igualdad de tuplas `==` funcional en el VM |

Zofía es el segundo ciclo. El dominio cambia (computación numérica en lugar de TUI)
pero la metodología es la misma: construir algo real, documentar lo que falta,
mejorar el lenguaje.

---

## Cómo leer este documento

| Campo | Significado |
|-------|-------------|
| **ID** | Identificador único. Formato: `TIPO-NNN` |
| **Módulo** | Archivo `.zy` donde se encontró o se anticipa el problema |
| **Contexto** | Construcción o capacidad de Zymbol involucrada |
| **Descripción** | Qué falla, qué falta o qué se propone |
| **Workaround** | Solución temporal utilizada en Zofía |
| **Propuesta** | Cómo debería resolverse en el lenguaje |
| **Fase** | Fase de Zofía donde el GAP bloquea por primera vez |
| **Estado** | `anticipado` · `abierto` · `workaround` · `propuesto` · `resuelto vX.X.X` · `descartado` · `excluido` |

---

## BUG — Comportamiento incorrecto en funcionalidad existente

Funcionalidades que Zymbol declara soportar pero que fallan en condiciones
específicas encontradas durante la construcción de Zofía.

| ID | Módulo | Contexto | Estado |
|----|--------|----------|--------|
| — | — | *Se pobla durante la implementación* | — |

---

## GAP — Capacidad ausente en el lenguaje

Construcciones o comportamientos que se necesitan para completar Zofía
pero que Zymbol aún no implementa.

| ID | Módulo | Capacidad ausente | Fase | Estado |
|----|--------|-------------------|------|--------|
| [GAP-Z001](#gap-z001--sin-funciones-matemáticas-trascendentes) | `activacion.zy`, `atencion.zy`, `transformador.zy` | `exp`, `log`, `sqrt`, `sin`, `cos`, `pow`, `abs` nativas | 3–5 | anticipado |
| [GAP-Z002](#gap-z002--sin-constantes-matemáticas) | todos los módulos | `π` y `e` como constantes nativas o de biblioteca | 3 | anticipado |
| [GAP-Z003](#gap-z003--sin-generación-de-números-aleatorios-nativa) | `transformador.zy` | Inicialización aleatoria de pesos sin BashExec por llamada | 5 | anticipado |
| ~~GAP-Z004~~ | ~~`tensor.zy`, todos~~ | ~~`0.33333333...` — sin control de decimales al imprimir~~ | ~~1~~ | resuelto v0.0.5 |
| [GAP-Z005](#gap-z005--rendimiento-de-listas-anidadas-para-tensores) | `tensor.zy` | Acceso `lista[i][j]` es O(n) en listas de listas | 1 | anticipado |

---

### GAP-Z001 · Sin funciones matemáticas trascendentes

- **Módulo:** `activacion.zy` (Fase 3), `atencion.zy` (Fase 4), `transformador.zy` (Fase 5)
- **Capacidad ausente:** Funciones matemáticas que Zymbol no provee de forma nativa:
  - `exp(x)` — exponencial natural `eˣ`; necesaria en `sigmoide`, `softmax`, `tanh`
  - `log(x)` — logaritmo natural; necesario en `entropia_cruzada`
  - `sqrt(x)` — raíz cuadrada; necesaria en `atencion_producto_punto` (`/ √dₖ`) y `normalizar_capa`
  - `sin(x)` y `cos(x)` — seno y coseno; necesarios en `codificacion_posicional`
  - `pow(base, exp)` — potencia; necesaria en `codificacion_posicional` (`10000^(2i/d)`)
  - `abs(x)` — valor absoluto; necesario en varias normalizaciones
- **Impacto por fase:**
  ```
  Fase 3: sigmoide = 1 / (1 + exp(-x))   -- necesita exp
          softmax: e^xᵢ / Σ e^xⱼ         -- necesita exp
          entropia_cruzada: log(pred)      -- necesita log

  Fase 4: atencion: QKᵀ / sqrt(dk)       -- necesita sqrt

  Fase 5: LayerNorm: (x-μ) / sqrt(σ²+ε)  -- necesita sqrt
          PE: sin(pos/10000^(2i/d))        -- necesita sin, cos, pow
  ```
- **Workaround elegido: implementación en Zymbol puro**
  En lugar de depender de BashExec (lento, requiere shell), Zofía implementará
  estas funciones en `modulos/matematica.zy` usando métodos numéricos clásicos:

  ```
  -- sqrt: método de Newton-Raphson (Newton's method)
  -- Converge en ~10 iteraciones para precisión float
  raiz_cuadrada(x):
      est = x / 2.0
      @ 10 veces:
          est = (est + x / est) / 2.0
      <~ est

  -- exp: serie de Taylor truncada a 20 términos (Taylor series)
  -- e^x = 1 + x + x²/2! + x³/3! + ...
  exponencial(x):
      suma = 1.0
      termino = 1.0
      @ n desde 1 hasta 20:
          termino = termino * x / n
          suma = suma + termino
      <~ suma

  -- sin: serie de Taylor (converge bien para |x| < 2π)
  -- sin(x) = x - x³/3! + x⁵/5! - ...

  -- log: via identidad log(x) = 2 * arctanh((x-1)/(x+1))
  --      o log(x) = log(a) + (x-a)/a para x cercano a a conocido
  ```

  **Ventaja educativa:** implementar estas funciones desde cero enseña más sobre
  análisis numérico que simplemente llamar `math.sqrt()`. Es coherente con la
  filosofía de Zofía.

- **Propuesta para Zymbol v0.0.6:**
  Módulo estándar `std/matematica` que exporte estas funciones implementadas
  en Rust (velocidad) con la misma API que la versión Zymbol puro:
  ```zymbol
  <# std/matematica <= mat

  y = mat::raiz_cuadrada(x)
  z = mat::exponencial(x)
  p = mat::potencia(base, exp)
  s = mat::seno(angulo)
  c = mat::coseno(angulo)
  v = mat::valor_absoluto(x)
  ```
- **Estado:** anticipado — workaround en `modulos/matematica.zy` planificado para Fase 3

---

### GAP-Z002 · Sin constantes matemáticas

- **Módulo:** todos los módulos
- **Capacidad ausente:** Las constantes `π` (pi ≈ 3.14159...) y `e` (euler ≈ 2.71828...)
  no existen como literales ni como parte del lenguaje o stdlib.
- **Uso en Zofía:**
  - `codificacion_posicional` usa `π` implícitamente a través de `sin`/`cos`
  - `exponencial` usa `e` como base
  - `tanh` se puede expresar en términos de `e`
- **Workaround:** Definir como constantes en `matematica.zy`:
  ```zymbol
  PI := 3.14159265358979323846
  E  := 2.71828182845904523536
  ```
  Esta es la solución definitiva — no requiere cambio en el lenguaje.
- **Propuesta para Zymbol (opcional):** Si se implementa `std/matematica`, incluir
  `mat::PI` y `mat::E` como constantes del módulo.
- **Estado:** anticipado — workaround trivial, no bloquea ninguna fase

---

### GAP-Z003 · Sin generación de números aleatorios nativa

- **Módulo:** `transformador.zy` (inicialización de pesos)
- **Capacidad ausente:** Igual que Serpiente GAP-002 (descartado en ese contexto).
  Zofía necesita inicializar los pesos de proyección W_Q, W_K, W_V, W_O, W₁, W₂
  con valores aleatorios pequeños al crear un `config_codificador`.
- **Diferencia con Serpiente:** En Serpiente, el BashExec por tick era el problema.
  En Zofía, la inicialización solo ocurre una vez al inicio — el costo de BashExec
  es aceptable. Pero la dependencia de shell sigue siendo frágil.
- **Workaround elegido:** El mismo LCG de `serpiente/logica.zy`, portado a
  `modulos/matematica.zy` como función reutilizable:
  ```zymbol
  -- Linear Congruential Generator (Numerical Recipes)
  -- (same constants as used in serpiente/logica.zy)
  lcg_paso(semilla):
      <~ (semilla * 1664525 + 1013904223) % 4294967296

  aleatorio_rango(semilla, min, max):
      sig = lcg_paso(semilla)
      val = min + (sig % (max - min + 1))
      <~ (val, sig)

  -- Para pesos: valores pequeños en [-0.1, 0.1]
  peso_aleatorio(semilla):
      [entero, sig] = aleatorio_rango(semilla, -100, 100)
      <~ (entero / 1000.0, sig)  -- rango [-0.1, 0.1]
  ```
  La semilla inicial se obtiene una sola vez con BashExec (`date +%N`).
- **Propuesta para Zymbol v0.0.6:** igual que Serpiente — función built-in
  `rand(min, max)` o módulo `std/aleatorio`.
- **Estado:** anticipado — workaround conocido reutilizado de Serpiente

---

### ~~GAP-Z004~~ · ~~Sin formato de punto flotante controlado~~ — RESUELTO en v0.0.5

- **Verificado:** 2026-05-23 contra `target/release/zymbol`
- **Resolución:** Zymbol v0.0.5 ya provee dos operadores de formato:

  | Operador | Comportamiento | Ejemplo (`pi = 3.14159...`) |
  |----------|---------------|------------------------------|
  | `#.4\|x\|` | Redondea a 4 decimales | `3.1416` |
  | `#!4\|x\|` | Trunca a 4 decimales | `3.1415` |

  Usar `#.###|x|` en Zofía — el redondeo es más representativo para pesos y pérdidas.
  `tensor.zy::imprimir` usará `#.4|elemento|` por cada escalar del tensor.

- **Operador de tipo `#?` también confirmado:**
  ```
  x = 3.14  →  x#?  →  (##., 16, 3.14)
  n = 42    →  n#?  →  (###, 2, 42)
  s = "hi"  →  s#?  →  (##", 2, hi)
  ```
- **Estado:** resuelto v0.0.5 — sin workaround necesario en Zofía

---

### GAP-Z005 · Rendimiento de listas anidadas para tensores

- **Módulo:** `tensor.zy`
- **Capacidad ausente:** No es un bug sino una limitación estructural. En Zymbol,
  los tensores son listas de listas. El acceso a `mat[i][j]` requiere dos lookups
  de lista. La multiplicación de dos matrices de forma `[m×k] × [k×n]` requiere
  `m × n × k` accesos individuales — para matrices `[8×8] × [8×8]`: 512 accesos.
- **Impacto real en Zofía:** Con `dim_modelo=8` (diseño mínimo), una pasada por el
  encoder completo implica aproximadamente:
  ```
  Proyecciones Q, K, V:  3 × matmul([5,8]×[8,8]) = 3 × 320 accesos = 960
  Atención (2 cabezas):  2 × matmul([5,4]×[4,5]) = 2 × 100 = 200
  Softmax × V:           2 × matmul([5,5]×[5,4]) = 2 × 100 = 200
  FFN (expand+contract): matmul([5,8]×[8,32]) + matmul([5,32]×[32,8]) = 1280+1280 = 2560
  LayerNorm × 2:         ~800 accesos de escalar
  Total (1 bloque):      ~5720 accesos por lista
  Total (2 bloques):     ~11440 accesos
  ```
  Esto es ejecutable en el tree-walker de Zymbol. Será lento (segundos, no milisegundos)
  pero funcional para propósitos educativos.
- **Mitigación por diseño:** Zofía ya usa dimensiones mínimas (`dim_modelo=8`,
  `num_cabezas=2`, `num_capas=2`, secuencias de 3–5 tokens). El diseño es deliberado.
- **Propuesta para Zymbol (largo plazo):** Tipo nativo `Tensor` con respaldo en
  `Vec<f64>` plano en Rust, acceso por índice O(1), operaciones de álgebra lineal
  como instrucciones nativas del VM.
- **Estado:** anticipado — mitigado por el diseño de dimensiones mínimas

---

## ERROR — Error de compilación o runtime no documentado

| ID | Módulo | Error producido | Estado |
|----|--------|-----------------|--------|
| — | — | *Se pobla durante la implementación* | — |

---

## IDEA — Propuestas de mejora al lenguaje

Mejoras inspiradas directamente en la experiencia de construir Zofía.

| ID | Área | Resumen | Fase que la inspira | Estado |
|----|------|---------|---------------------|--------|
| [IDEA-Z001](#idea-z001--módulo-stdmatematica) | stdlib | `std/matematica`: exp, log, sqrt, sin, cos, pow, abs en Rust | 3–5 | propuesto |
| [IDEA-Z002](#idea-z002--formato-de-punto-flotante-en-) | sintaxis | `>>` con control de decimales: `>> x :#4f` | 1 | propuesto |
| [IDEA-Z003](#idea-z003--map-funcional-sobre-listas) | operadores | Aplicar función a cada elemento de lista: `lista $@ fn` | 1 | propuesto |
| [IDEA-Z004](#idea-z004--input-tipado-con-restricciones) | sintaxis | `<< :###4` — restricción de tipo y longitud en el operador de lectura | cualquiera | propuesto |

---

### IDEA-Z001 · Módulo `std/matematica`

- **Área:** stdlib
- **Motivación:** Zofía necesita exp, log, sqrt, sin, cos, pow, abs para implementar
  las activaciones, la atención y el positional encoding. Actualmente se implementarán
  en Zymbol puro en `modulos/matematica.zy` — funcional pero más lento que una
  implementación nativa.
- **Propuesta:** Módulo estándar `std/matematica` implementado en Rust (como wrapper
  de `f64::sqrt()`, `f64::exp()`, etc.) con API en español:
  ```zymbol
  <# std/matematica <= mat

  mat::raiz_cuadrada(x)       -- sqrt
  mat::exponencial(x)         -- exp
  mat::logaritmo(x)           -- ln
  mat::logaritmo_base(x, b)   -- log_b(x)
  mat::potencia(base, exp)    -- base^exp
  mat::seno(x)                -- sin (radianes)
  mat::coseno(x)              -- cos (radianes)
  mat::valor_absoluto(x)      -- |x|
  mat::maxn(a, b)             -- max(a, b) para escalares
  mat::minn(a, b)             -- min(a, b) para escalares
  mat::PI                     -- 3.14159265...
  mat::E                      -- 2.71828182...
  ```
- **Impacto:** Cualquier programa Zymbol científico o financiero se beneficia.
  Elimina la necesidad de BashExec para cálculos numéricos.
- **Esfuerzo estimado:** Bajo — son wrappers de funciones de la biblioteca estándar
  de Rust, sin nueva semántica en el lenguaje.
- **Estado:** propuesto para Zymbol v0.0.6

---

### IDEA-Z002 · Formato de punto flotante en `>>`

- **Área:** sintaxis / output
- **Motivación:** `>> 0.333333333` satura la pantalla. Zofía imprimirá muchos tensores
  cuyos valores son resultados de divisiones. Se necesita control de precisión.
- **Propuesta:** Sintaxis de formato como modificador del operador `>>`:
  ```zymbol
  >> x :#4f ¶        -- 4 decimales: "0.3333"
  >> x :#2e ¶        -- notación científica 2 dec: "3.33e-01"
  >> x :#0f ¶        -- entero: "0"
  ```
  El `:#Nf` sería un token de formato, no un operador de aritmética.
  Alternativa como función en `std/matematica`: `mat::formatear(x, 4)` → string.
- **Impacto:** Mejora inmediata en la legibilidad de cualquier programa numérico.
- **Estado:** propuesto para Zymbol v0.0.6

---

### IDEA-Z003 · Map funcional sobre listas (`$@`)

- **Área:** operadores de colección
- **Motivación:** En `tensor.zy`, muchas operaciones aplican la misma función a cada
  elemento. Actualmente requieren un loop explícito:
  ```zymbol
  -- Aplicar ReLU a cada elemento de un vector
  resultado = []
  @ x en vec {
      resultado = resultado $+[1] relu_escalar(x)
  }
  ```
  Con un operador map:
  ```zymbol
  resultado = vec $@ relu_escalar    -- cada elemento pasa por relu_escalar
  ```
- **Coherencia con el lenguaje:** Zymbol usa `$` como prefijo de todos los operadores
  de colección (`$+`, `$-`, `$*`, `$?`, `$#`, etc.). `$@` sería el map funcional —
  `@` ya evoca "para cada" en el lenguaje (bucles).
- **Propuesta:** `coleccion $@ funcion` aplica `funcion(elemento)` a cada elemento
  y devuelve la lista resultante. Para funciones con argumentos adicionales:
  `coleccion $@ (fn, arg1, arg2)`.
- **Impacto:** Elimina boilerplate en `activacion.zy` (relu, sigmoide, tanh elemento
  a elemento), en `tensor.zy` (sumar_escalar, multiplicar_escalar) y en cualquier
  módulo que transforme colecciones.
- **Estado:** propuesto para Zymbol v0.0.6

---

### IDEA-Z004 · Input tipado con restricciones

- **Área:** sintaxis / input
- **Motivación:** Las demos interactivas de Zofía pedirán al usuario que ingrese
  parámetros del modelo: número de capas (1–6), dimensión (potencia de 2), tasa
  de aprendizaje (decimal positivo). Hoy toda validación se hace manualmente en
  el programa; debería ser responsabilidad del operador de lectura.
- **Propuesta:** Modificador de tipo en el operador `<<` usando la notación
  simbólica existente del lenguaje (sin letras, agnóstico al idioma):
  ```zymbol
  << :###2  "Capas (1-99): "       -- entero hasta 2 dígitos
  << :+###4 "Dimensión: "          -- entero positivo hasta 4 dígitos
  << :+##.4 "Tasa aprendizaje: "   -- decimal positivo, hasta 4 decimales
  << :##"30 "Etiqueta: "           -- texto hasta 30 caracteres
  ```
  El runtime rechaza caracteres inválidos en tiempo de ingreso (no en validación
  posterior). Si el usuario presiona Enter con valor vacío o inválido, repite el prompt.
- **Coherencia:** Usa `###` (entero), `##.` (decimal), `##"` (texto) — notación
  ya establecida en Zymbol para tipos. El `+` para positivo. El número final para
  longitud máxima. Sin letras de idioma.
- **Estado:** propuesto para Zymbol v0.0.6

---

## Resumen de estado

| Categoría | Total | Anticipados | Abiertos | Workaround | Propuestos | Resueltos |
|-----------|-------|-------------|----------|------------|------------|-----------|
| BUG | 0 | 0 | 0 | 0 | 0 | 0 |
| GAP | 5 | 4 | 0 | 0 | 0 | 1 |
| ERROR | 0 | 0 | 0 | 0 | 0 | 0 |
| IDEA | 4 | 0 | 0 | 0 | 4 | 0 |
| **Total** | **9** | **4** | **0** | **0** | **4** | **1** |

---

## Mapa de impacto en Zymbol v0.0.6

Los GAPs e IDEAs de Zofía, agrupados por área de cambio en el lenguaje:

| Área Zymbol | Items | Prioridad |
|-------------|-------|-----------|
| `std/matematica` (nueva biblioteca) | GAP-Z001, GAP-Z002, IDEA-Z001 | Alta — desbloquea Fases 3-5 |
| Formato numérico en `>>` | ~~GAP-Z004~~, IDEA-Z002 | Media — `#.###\|x\|` ya cubre el caso; IDEA-Z002 es mejora adicional |
| Operadores de colección | IDEA-Z003 (`$@` map) | Media — elimina boilerplate |
| Input tipado | IDEA-Z004 | Baja — solo demos interactivas |
| `std/aleatorio` | GAP-Z003 | Baja — LCG es workaround suficiente |
| Tipo `Tensor` nativo en VM | GAP-Z005 | Largo plazo — no bloquea Zofía v1 |

---

## Historial de resoluciones

| ID | Título | Resuelto en | Cómo |
|----|--------|-------------|------|
| GAP-Z004 | Sin formato de punto flotante | v0.0.5 | `#.###\|x\|` redondea, `#!###\|x\|` trunca — verificado 2026-05-23 |
