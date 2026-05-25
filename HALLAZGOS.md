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

Con `std/math` y `std/random` implementados en v0.0.6, Zofía puede avanzar a
las Fases 3–5 sin workarounds en Zymbol puro.

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
| [BUG-Z001](#bug-z001--vm-aritmética-int-falla-con-flotantes-de-arreglos) | todos los módulos | Aritmética `+`, `-`, `*`, `/` sobre elementos de arreglos Float en el VM | resuelto v0.0.6 |

---

### BUG-Z001 · VM: aritmética Int falla con flotantes de arreglos — RESUELTO en v0.0.6

- **Módulo:** `tensor.zy` (Fase 1); afecta todos los módulos que operan sobre arreglos Float
- **Síntoma:** `zymbol run --vm` lanza `type error: expected Int, got Float` al evaluar
  expresiones como `a[i] + b[i]` cuando el arreglo contiene Float.
- **Causa raíz (compilador):** `compile_index` en `zymbol-compiler` emite `ArrayGet` pero
  **nunca anota el tipo del registro resultado** → el registro queda `StaticType::Unknown`.
  `compile_binary` interpreta `Unknown || Unknown` como `is_float = false` y emite `AddInt`
  en lugar de `AddFloat`.
- **Causa raíz (VM):** La instrucción `AddInt` usaba el macro `ri!` que solo acepta
  `Value::Int`; lanzaba `TypeError` inmediatamente sobre un `Value::Float`.
- **Resolución:** Se añadió **dispatch dinámico** en el VM (`zymbol-vm/src/lib.rs`): cada
  instrucción `AddInt` / `SubInt` / `MulInt` / `DivInt` / `ModInt` / `PowInt` / `NegInt` y
  sus variantes `Imm` comprueban el tipo real del registro en ejecución. Si algún operando
  es `Float`, cae al path flotante usando `rf!` (que coerciona `Int→f64`); si ambos son
  `Int`, mantiene aritmética entera. Este comportamiento coincide con el tree-walker.
- **Impacto:** Sin este fix, **ningún módulo de Zofía podía ejecutarse con `--vm`**; toda
  la aritmética sobre tensores de `Float` fallaba.
- **Tests:** 438/438 PASS, 0 FAIL después del fix (sin regresiones).

---

## GAP — Capacidad ausente en el lenguaje

Construcciones o comportamientos que se necesitan para completar Zofía
pero que Zymbol aún no implementa.

| ID | Módulo | Capacidad ausente | Fase | Estado |
|----|--------|-------------------|------|--------|
| ~~[GAP-Z001](#gap-z001--sin-funciones-matemáticas-trascendentes)~~ | ~~`activacion.zy`, `atencion.zy`, `transformador.zy`~~ | ~~`exp`, `log`, `sqrt`, `sin`, `cos`, `pow`, `abs` nativas~~ | ~~3–5~~ | resuelto v0.0.6 |
| ~~[GAP-Z002](#gap-z002--sin-constantes-matemáticas)~~ | ~~todos los módulos~~ | ~~`π` y `e` como constantes nativas o de biblioteca~~ | ~~3~~ | resuelto v0.0.6 |
| ~~[GAP-Z003](#gap-z003--sin-generación-de-números-aleatorios-nativa)~~ | ~~`transformador.zy`~~ | ~~Inicialización aleatoria de pesos sin BashExec por llamada~~ | ~~5~~ | resuelto v0.0.6 |
| ~~GAP-Z004~~ | ~~`tensor.zy`, todos~~ | ~~`0.33333333...` — sin control de decimales al imprimir~~ | ~~1~~ | resuelto v0.0.5 |
| [GAP-Z005](#gap-z005--rendimiento-de-listas-anidadas-para-tensores) | `tensor.zy` | Acceso `lista[i][j]` es O(n) en listas de listas | 1 | anticipado |
| ~~[GAP-Z006](#gap-z006--actualización-profunda-canónica-arrij-val)~~ | ~~`tensor.zy`, `grad.zy`~~ | ~~`arr[i>j]$~ val` — deep update consistente con la lectura profunda~~ | ~~1~~ | resuelto v0.0.6 |
| ~~[GAP-Z007](#gap-z007--no-soporta-en-tuplas-nombradas)~~ | ~~`grad.zy`~~ | ~~`$~` no funciona sobre `Value::NamedTuple`~~ | ~~2~~ | resuelto v0.0.6 |
| ~~[GAP-Z008](#gap-z008--inferencia-de-tipo-monomorfa-bloquea-funciones-numéricas-mixtas)~~ | ~~todos~~ | ~~Parámetros aritméticos fijados como `Int`; llamadas Float fallan~~ | ~~1~~ | resuelto v0.0.6 |
| ~~[GAP-Z009](#gap-z009--funciones-nombradas-pierden-alias-de-módulo-al-pasarse-como-hof)~~ | ~~`activacion.zy`, `atencion.zy`~~ | ~~Función nombrada con `mat::fn` usada como HOF falla en runtime~~ | ~~3~~ | resuelto v0.0.6 |

---

### ~~GAP-Z001~~ · Sin funciones matemáticas trascendentes — RESUELTO en v0.0.6

- **Módulo:** `activacion.zy` (Fase 3), `atencion.zy` (Fase 4), `transformador.zy` (Fase 5)
- **Resolución:** Módulo `std/math` implementado en Rust nativo. Nombres en estándar
  internacional (mismo que C, Python, Rust). Para nombres en español, usar el patrón
  i18n de tres capas — ver adapter `modulos/matematica_std.zy` en Zofía.

  ```zymbol
  <# std/math => mat

  mat::sqrt(x)          -- raíz cuadrada
  mat::exp(x)           -- e^x
  mat::ln(x)            -- logaritmo natural
  mat::log(x)           -- logaritmo natural (alias de ln)
  mat::log(x, base)     -- logaritmo en base arbitraria
  mat::sin(x)           -- seno (radianes)
  mat::cos(x)           -- coseno (radianes)
  mat::pow(base, exp)   -- base^exp (Float)
  mat::abs(x)           -- valor absoluto (Int→Int, Float→Float)
  mat::max(a, b)        -- máximo de dos valores
  mat::min(a, b)        -- mínimo de dos valores
  mat::floor(x)         -- piso (entero inferior)
  mat::ceil(x)          -- techo (entero superior)
  mat::round(x)         -- redondeo al más cercano
  ```

  **Patrón i18n para Zofía** — `modulos/matematica_std.zy`:
  ```zymbol
  # matematica_std {
      <# std/math => _mat
      #> {
          _mat::sqrt  => raiz
          _mat::exp   => exp
          _mat::ln    => ln
          _mat::log   => log
          _mat::pow   => pot
          _mat::sin   => sen
          _mat::cos   => cos
          _mat::abs   => abs
          _mat::max   => max
          _mat::min   => min
          _mat::floor => piso
          _mat::ceil  => techo
          _mat::round => redondear
      }
  }
  ```

  Consumer en Zofía:
  ```zymbol
  <# ./modulos/matematica_std => mat

  sigmoide(x) { <~ 1.0 / (1.0 + mat::exp(-x)) }
  softmax(vec) {
      exps  = vec$> (v -> mat::exp(v))
      total = exps$< (0.0, (acc, v) -> acc + v)
      <~ exps$> (v -> v / total)
  }
  ```

- **Int → Float promoción:** todos los argumentos `###` son promovidos a `##.`
  automáticamente — `mat::sqrt(4)` devuelve `2.0`.
- **Estado:** resuelto v0.0.6 — `std/math` operativo, tests en `interpreter/tests/stdlib/`

---

### ~~GAP-Z002~~ · Sin constantes matemáticas — RESUELTO en v0.0.6

- **Módulo:** todos los módulos
- **Resolución:** `std/math` exporta `PI` y `E` como constantes del módulo.
  ```zymbol
  <# std/math => mat

  area = mat.PI * radio * radio
  base = mat.E
  ```
  - `mat.PI` = `3.141592653589793`
  - `mat.E`  = `2.718281828459045`
- **Estado:** resuelto v0.0.6 — acceso mediante `alias.CONSTANTE` verificado

---

### ~~GAP-Z003~~ · Sin generación de números aleatorios nativa — RESUELTO en v0.0.6

- **Módulo:** `transformador.zy` (inicialización de pesos)
- **Resolución:** Módulo `std/random` implementado con xoshiro256++ (estado
  thread-local, semilla automática desde `SystemTime`). Reemplaza el LCG manual
  y elimina la dependencia de BashExec.

  ```zymbol
  <# std/random => rnd

  rnd::entero(1, 6)    -- Int en [min, max]
  rnd::rango(10)       -- Int en [0, n-1]
  rnd::peso_f64()      -- Float en [-0.1, 0.1] para inicialización de pesos
  ```

  `peso_f64()` reemplaza directamente el patrón `peso_aleatorio(semilla)` del LCG
  de `modulos/matematica.zy`. No requiere pasar ni almacenar semilla.

- **Estado:** resuelto v0.0.6 — xoshiro256++, tests en `interpreter/tests/stdlib/`

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

### ~~GAP-Z006~~ · Actualización profunda canónica `arr[i>j]$~ val` — RESUELTO en v0.0.6

- **Módulo:** `tensor.zy`, `grad.zy`
- **Descripción:** `arr[i>j]` es la sintaxis canónica de lectura profunda en Zymbol
  (`arr[i][j]` está deprecado). Sin embargo, `$~` solo aceptaba `arr[i]` (un nivel),
  obligando a encadenar para deep updates: `m = m[i]$~ (m[i][j]$~ val)` — verboso
  e inconsistente con la sintaxis de lectura.
- **Resolución:** El parser acepta `Expr::DeepIndex` como target de `$~`. El intérprete
  evalúa todos los índices del path, desciende, y reconstruye de adentro hacia afuera.
  ```zymbol
  // Antes (forma encadenada — todavía válida):
  m = m[1]$~ (m[1][2]$~ 99.0)

  // Ahora (forma canónica — consistente con la lectura):
  m = m[1>2]$~ 99.0

  // Funciona a cualquier profundidad:
  t = t[2>1>2]$~ 99.0
  ```
  Soporta `Array`, `Tuple` posicional y `NamedTuple` en cualquier nivel del path.
- **Estado:** resuelto v0.0.6 — `parse_collection_update` + `deep_update_value` en `collection_ops.rs`

---

### ~~GAP-Z007~~ · `$~` no soporta tuplas nombradas — RESUELTO en v0.0.6

- **Módulo:** `grad.zy`
- **Descripción:** El operador de actualización funcional `$~` solo funcionaba con
  `Value::Array` y `Value::Tuple` posicional. Intentar actualizar un campo de una
  tupla nombrada producía `RuntimeError: cannot update NamedTuple`.
  ```zymbol
  // Falla en v0.0.5:
  g = (nombre: "w1", valor: 1.5, grad: 0.0)
  g2 = g[3]$~ 0.5     // ❌ RuntimeError
  g3 = g["grad"]$~ 0.5  // ❌ RuntimeError
  ```
- **Impacto:** El módulo `grad` representa cada parámetro entrenable como tupla
  nombrada. Sin este soporte, actualizar el campo `grad` requería reconstrucción
  completa en cada paso de retropropagación.
- **Resolución:** Nuevo arm `Value::NamedTuple` en `eval_collection_update`:
  - `t[i]$~ val` — actualización por posición (1-based, índices negativos soportados)
  - `t["campo"]$~ val` — actualización por nombre de campo
  ```zymbol
  g2 = g[3]$~ 0.5        // ✅ por posición
  g3 = g["grad"]$~ 0.5   // ✅ por nombre de campo
  ```
  El original nunca se muta (inmutabilidad funcional).
- **Estado:** resuelto v0.0.6 — `collection_ops.rs`, test en `tests/collections/named_tuple_update.zy`

---

### ~~GAP-Z008~~ · Inferencia de tipo monomorfa bloquea funciones numéricas mixtas — RESUELTO en v0.0.6

- **Módulo:** todos
- **Descripción:** El analizador semántico infería parámetros usados en aritmética
  pura como `Int` (default). Llamadas posteriores con `Float` fallaban en la fase
  semántica, antes de ejecutar.
  ```zymbol
  multiplicar(a, b) { <~ a * b }
  >> multiplicar(3.0, 4.0)  // ❌ "argument 1 has type Float, but function expects Int"
  ```
  Esto afectaba `escalar_vec`, funciones de activación con argumento flotante, y
  cualquier función matemática pura sin literales de tipo en el cuerpo.
- **Resolución:** `TypeConstraint::Numeric.to_type()` ahora devuelve `ZymbolType::Float`
  en lugar de `ZymbolType::Int`. Parámetros con evidencia de Int (comparación `n > 0`,
  indexación `arr[n]`) siguen siendo `Exact(Int)` vía unify: `Numeric + CompatibleWith(Int) = Exact(Int)`.
  ```zymbol
  multiplicar(a, b) { <~ a * b }
  >> multiplicar(3, 4)     // ✅ Int, Int
  >> multiplicar(3.0, 4.0) // ✅ Float, Float
  >> multiplicar(3, 4.0)   // ✅ Int, Float
  ```
- **Estado:** resuelto v0.0.6 — `zymbol-semantic/src/type_check.rs`, una línea

---

### ~~GAP-Z009~~ · Funciones nombradas pierden alias de módulo al pasarse como HOF — RESUELTO en v0.0.6

- **Módulo:** `activacion.zy`, `atencion.zy`
- **Descripción:** Una función nombrada que usa `mat::fn` internamente, al ser pasada
  como valor de primera clase a otra función, fallaba con `"undefined module alias: 'mat'"`.
  Las lambdas (`x -> mat::fn(x)`) no tenían este problema porque tomaban un fast path
  que no limpiaba `import_aliases`.
  ```zymbol
  <# std/math => mat

  sqrt_fn(x) { <~ mat::sqrt(x) }
  aplicar(f, lista) { <~ lista $> v -> f(v) }

  // Workaround necesario en v0.0.5:
  resultado = aplicar(x -> mat::sqrt(x), lista)   // ✅ lambda inline
  resultado = aplicar(sqrt_fn, lista)              // ❌ alias perdido
  ```
- **Causa raíz:** `take_call_state()` limpiaba `import_aliases`. Para lambdas
  intermedias dentro de HOFs, esto borraba el contexto antes de que la función
  nombrada pudiera usarlo. La solución via `saved.import_aliases` era insuficiente.
- **Resolución:** `FunctionValue` tiene nuevo campo `module_aliases: HashMap<String, PathBuf>`
  capturado en `func_def_to_value` (momento de definición). En `eval_lambda_call`,
  se restauran desde el snapshot de la función, no del caller.
  ```zymbol
  resultado = aplicar(sqrt_fn, lista)   // ✅ funciona en v0.0.6
  ```
- **Estado:** resuelto v0.0.6 — `functions_lambda.rs` + campo en `FunctionValue` (lib.rs)

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
| ~~[IDEA-Z001](#idea-z001--módulo-stdmath)~~ | stdlib | ~~`std/math`: sqrt, exp, ln, sin, cos, pow, abs en Rust~~ | 3–5 | resuelto v0.0.6 |
| [IDEA-Z002](#idea-z002--formato-de-punto-flotante-en-) | sintaxis | `>>` con control de decimales: `>> x :#4f` | 1 | propuesto |
| ~~[IDEA-Z003](#idea-z003--map-funcional-sobre-listas)~~ | operadores | ~~`lista $@ fn` — map funcional~~ | 1 | descartado |
| [IDEA-Z004](#idea-z004--input-tipado-con-restricciones) | sintaxis | `<< :###4` — restricción de tipo y longitud en el operador de lectura | cualquiera | propuesto |

---

### ~~IDEA-Z001~~ · Módulo `std/math` — RESUELTO en v0.0.6

- **Resolución:** Implementado como `std/math` con nombres estándar internacionales.
  Ver [GAP-Z001 resuelto](#gap-z001--sin-funciones-matemáticas-trascendentes--resuelto-en-v006)
  para la API completa y el patrón i18n.
- **Estado:** resuelto v0.0.6

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
  Alternativa como función en `std/math`: `mat::round(x * 1e4) / 1e4` o usar
  el operador existente `#.4|x|` (ya disponible en v0.0.5).
- **Impacto:** Mejora inmediata en la legibilidad de cualquier programa numérico.
- **Estado:** propuesto para Zymbol v0.0.7 — workaround: `#.4|x|` ya disponible

---

### ~~IDEA-Z003~~ · Map funcional sobre listas (`$@`) — DESCARTADO

- **Motivo del descarte:** El operador `$>` ya existe en Zymbol y hace exactamente
  lo que `$@` proponía:
  ```zymbol
  resultado = vec$> relu_escalar          -- referencia a función nombrada
  resultado = vec$> (v -> mat::exp(v))    -- lambda inline
  exps = vec$> (v -> mat::exp(v))         -- softmax step 1
  ```
  Añadir `$@` sería sintaxis duplicada sin beneficio. Los ejemplos de Zofía
  (`sigmoide`, `softmax`, `relu` elemento a elemento) funcionan con `$>`.
- **Estado:** descartado — redundante con `$>`

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
- **Estado:** propuesto para Zymbol v0.0.7

---

## Resumen de estado

| Categoría | Total | Anticipados | Abiertos | Workaround | Propuestos | Resueltos | Descartados |
|-----------|-------|-------------|----------|------------|------------|-----------|-------------|
| BUG | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| GAP | 9 | 1 | 0 | 0 | 0 | 8 | 0 |
| ERROR | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| IDEA | 4 | 0 | 0 | 0 | 2 | 1 | 1 |
| **Total** | **13** | **1** | **0** | **0** | **2** | **9** | **1** |

---

## Mapa de impacto en Zymbol v0.0.6

Los GAPs e IDEAs de Zofía, agrupados por área de cambio en el lenguaje:

| Área Zymbol | Items | Estado |
|-------------|-------|--------|
| `std/math` (nueva biblioteca) | GAP-Z001, GAP-Z002, IDEA-Z001 | ✅ resuelto v0.0.6 |
| `std/random` | GAP-Z003 | ✅ resuelto v0.0.6 |
| Formato numérico en `>>` | ~~GAP-Z004~~, IDEA-Z002 | `#.###\|x\|` cubre el caso; IDEA-Z002 → v0.0.7 |
| Operadores de colección | ~~IDEA-Z003~~ (`$@` map) | descartado — `$>` ya cubre |
| Input tipado | IDEA-Z004 | propuesto v0.0.7 |
| `$~` deep update canónico | GAP-Z006 | ✅ resuelto v0.0.6 — `arr[i>j]$~ val` |
| `$~` para tuplas nombradas | GAP-Z007 | ✅ resuelto v0.0.6 — por posición y por nombre |
| Inferencia numérica polimórfica | GAP-Z008 | ✅ resuelto v0.0.6 — `Numeric → Float` default |
| HOF aliases en funciones nombradas | GAP-Z009 | ✅ resuelto v0.0.6 — `module_aliases` en `FunctionValue` |
| Tipo `Tensor` nativo en VM | GAP-Z005 | largo plazo — no bloquea Zofía v1 |

---

## Historial de resoluciones

| ID | Título | Resuelto en | Cómo |
|----|--------|-------------|------|
| GAP-Z004 | Sin formato de punto flotante | v0.0.5 | `#.###\|x\|` redondea, `#!###\|x\|` trunca — verificado 2026-05-23 |
| GAP-Z001 | Sin funciones matemáticas trascendentes | v0.0.6 | `std/math`: `sqrt exp ln log pow sin cos tan tanh sinh cosh sigmoid asin acos atan atan2 abs max min floor ceil round` |
| GAP-Z002 | Sin constantes matemáticas | v0.0.6 | `std/math` exporta `PI` y `E`; acceso: `mat.PI`, `mat.E` |
| GAP-Z003 | Sin generación de números aleatorios nativa | v0.0.6 | `std/random`: xoshiro256++ thread-local; `entero rango peso_f64` |
| IDEA-Z001 | Módulo `std/math` | v0.0.6 | Implementado con nombres estándar internacionales + patrón i18n |
| IDEA-Z003 | Map funcional `$@` | — | Descartado — `$>` ya hace exactamente lo mismo |
| GAP-Z006 | Deep update canónico `arr[i>j]$~ val` | v0.0.6 | Parser acepta `DeepIndex` como target; `deep_update_value` recursiva en `collection_ops.rs` |
| GAP-Z007 | `$~` en tuplas nombradas | v0.0.6 | Nuevo arm `Value::NamedTuple` en `eval_collection_update`; soporta índice entero y nombre de campo |
| GAP-Z008 | Inferencia monomorfa bloquea funciones numéricas | v0.0.6 | `TypeConstraint::Numeric.to_type()` devuelve `Float` — `Int → Float` sigue siendo compatible |
| GAP-Z009 | HOF aliases en funciones nombradas | v0.0.6 | Campo `module_aliases` en `FunctionValue` capturado en definición; restaurado en `eval_lambda_call` |
