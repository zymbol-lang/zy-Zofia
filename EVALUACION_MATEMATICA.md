# Evaluación Matemática — Zofía vs Zymbol v0.0.5

Documento de contraste entre las operaciones matemáticas que Zofía requiere
y lo que Zymbol v0.0.5 provee de forma directa.

Fuentes de referencia:
- `Zofía/docs/00_fundamentos_matematicos.md` — necesidades del proyecto
- `interpreter/zymbol-lang.ebnf` v3.0.0 — gramática oficial (Sprint v0.0.5)
- `interpreter/GUIDE.md` — referencia del lenguaje
- `Zofía/HALLAZGOS.md` — GAPs pre-identificados durante diseño

---

## Estado de cobertura (resumen ejecutivo)

| Categoría | Operaciones | ✅ Directo | ⚠️ Workaround | ❌ Ausente |
|-----------|-------------|-----------|---------------|-----------|
| Aritmética escalar | 6 | 6 | 0 | 0 |
| Estructuras (vector/matriz) | 5 | 5 | 0 | 0 |
| Operaciones lineales | 6 | 4 | 2 | 0 |
| Funciones matemáticas | 9 | 1 | 0 | 8 |
| Constantes (π, e) | 2 | 0 | 2 | 0 |
| Características de lenguaje | 8 | 8 | 0 | 0 |
| **Total** | **36** | **24 (67%)** | **4 (11%)** | **8 (22%)** |

---

## Sección 1 — Aritmética Escalar

Todo el álgebra escalar que `00_fundamentos_matematicos.md` describe funciona
directamente en Zymbol sin ninguna adaptación.

| Operación | Notación matemática | Zymbol v0.0.5 | Estado |
|-----------|---------------------|---------------|--------|
| Suma | `a + b` | `a + b` | ✅ |
| Resta | `a - b` | `a - b` | ✅ |
| Multiplicación | `a × b` | `a * b` | ✅ |
| División | `a / b` | `a / b` | ✅ |
| Módulo | `a mod b` | `a % b` | ✅ |
| Potencia (exponente entero) | `aⁿ` | `a ^ n` | ✅ (`^` asociativo a la derecha) |

**Nota:** `^` en Zymbol soporta exponentes enteros y flotantes cuando la base
es positiva. `2.0 ^ 0.5` devuelve `1.4142...` porque internamente usa `f64::powf`.
Sin embargo, para la fórmula `eˣ = e ^ x` con `e` exacta, ver Sección 3.

---

## Sección 2 — Estructuras de Datos (Vector y Matriz)

| Concepto | Descripción | Zymbol v0.0.5 | Estado |
|----------|-------------|---------------|--------|
| Vector | Lista plana de escalares | `[1.0, 2.0, 3.0]` | ✅ array literal |
| Matriz | Lista de vectores | `[[1.0, 2.0], [3.0, 4.0]]` | ✅ listas anidadas |
| Literal flotante | `3.14`, `1.5e10` | `3.14` — soportado por EBNF `float_literal` | ✅ |
| Indexación vector | `v[i]` | `v[i]` (1-based) | ✅ |
| Indexación matriz | `M[i][j]` | `M[i>j]` (navegación profunda) | ✅ |

**Nota sobre indexación:** Zymbol usa índices 1-based. Un vector `[1.0, 2.0, 3.0]`
tiene `v[1]=1.0`, `v[2]=2.0`, `v[3]=3.0`. El código de Zofía debe asumir
siempre índices desde 1.

---

## Sección 3 — Operaciones de Álgebra Lineal

| Operación | Fórmula | Zymbol v0.0.5 | Estado | Notas |
|-----------|---------|---------------|--------|-------|
| Suma de vectores (element-wise) | `(a+b)ᵢ = aᵢ + bᵢ` | Loop `@ i : 1..n { res[i] = a[i] + b[i] }` | ✅ verboso | Sin operador vectorial nativo |
| Multiplicación escalar | `(αv)ᵢ = α × vᵢ` | `v $> (x -> x * alfa)` | ✅ `$>` HOF | Conciso con lambda |
| Producto punto | `a·b = Σᵢ aᵢbᵢ` | `[1..n] $< (acc i -> acc + a[i] * b[i])` o loop | ⚠️ sin índice en `$<` | Ver implementación debajo |
| Multiplicación matricial | `(AB)ᵢⱼ = Σₖ AᵢₖBₖⱼ` | Triple loop anidado | ✅ expresable | Alta verbosidad |
| Transposición | `Aᵀᵢⱼ = Aⱼᵢ` | Doble loop anidado | ✅ expresable | Alta verbosidad |
| Suma de lista | `Σᵢ xᵢ` | `lista $< (acc x -> acc + x)` | ✅ `$<` reduce | Idiomático en Zymbol |

### Producto punto — implementación directa en Zymbol

```zymbol
// Dot product via indexed loop (clearest form)
producto_punto(a, b) {
    suma = 0.0
    n = a$#
    @ i : 1..n {
        suma += a[i] * b[i]
    }
    <~ suma
}
```

O vía `$<` si los vectores se pueden comprimir en pares primero:
```zymbol
// Via zip-reduce (requires zip helper)
pares = [1..n] $> (i -> a[i] * b[i])
<~ pares $< (acc x -> acc + x)
```

### Límite actual: `$<` no provee índice implícito

El operador reduce `$<` recibe `(acumulador, elemento)` pero no el índice.
Para operaciones que necesitan posición (ej: convolución, atención por posición),
se requiere un loop explícito. Este es un límite de diseño, no un GAP de funciones.

---

## Sección 4 — Funciones Matemáticas Elementales

Esta sección identifica las **8 brechas reales** de Zymbol para IA.

| Función | Necesaria para | EBNF/GUIDE v0.0.5 | Estado | Workaround en Zofía |
|---------|---------------|-------------------|--------|---------------------|
| `sqrt(x)` | norma L₂, atención escalada `√dₖ` | ❌ sin función nativa | ❌ | Newton-Raphson (20 iter.) |
| `abs(x)` | valor absoluto, clipeo de gradiente | ❌ sin función nativa | ❌ | `? x >= 0 { x } _ { -x }` |
| `max(a, b)` | ReLU: `max(0, x)` | ❌ sin función nativa | ❌ | `? a >= b { a } _ { b }` |
| `min(a, b)` | clipeo, clamp | ❌ sin función nativa | ❌ | `? a <= b { a } _ { b }` |
| `exp(x)` | sigmoide `σ(x) = 1/(1+e⁻ˣ)`, softmax | ❌ sin función nativa | ❌ | Serie de Taylor, 30 términos |
| `ln(x)` | entropía cruzada `-Σ yᵢ log(pᵢ)` | ❌ sin función nativa | ❌ | Identidad arctanh, serie |
| `sin(x)` | codificación posicional `PE(pos, 2i)` | ❌ sin función nativa | ❌ | Serie de Taylor, 15 términos |
| `cos(x)` | codificación posicional `PE(pos, 2i+1)` | ❌ sin función nativa | ❌ | Serie de Taylor, 15 términos |

### Gravedad por fase de Zofía

```
Fase 1 — tensor:        sin brechas   (solo aritmética + listas)
Fase 2 — grad:          sin brechas   (solo derivadas + loops)
Fase 3 — activacion:    GAP exp, ln   (sigmoide, softmax, cross-entropy)
Fase 4 — atencion:      GAP sqrt      (atención escalada)
Fase 5 — transformador: GAP sin, cos  (codificación posicional)
```

Las fases 1 y 2 son completamente implementables sin workarounds.
Las fases 3–5 requieren el módulo `matematica.zy`.

### Por qué `^` no reemplaza `exp`

`x ^ n` en Zymbol invoca `f64::powf(x, n)` cuando el exponente es flotante.
Esto significa `2.718 ^ 3.0` funciona. Sin embargo:

1. Requiere conocer `e` con alta precisión como constante — `:= E 2.71828...`
2. Para `eˣ` con `x` negativo y grande, la pérdida de precisión es mayor
   que con la función nativa `exp(x)` del hardware.
3. En softmax se calcula `eˣ` para varios valores simultáneamente: tener
   `exp` como función simplifica el código de Zofía significativamente.

Conclusión: `^` es suficiente para potencias enteras exactas (ej: `x^2`),
pero `exp(x)` sigue siendo necesario como función separada.

---

## Sección 5 — Constantes Matemáticas

| Constante | Valor | Necesaria para | Zymbol v0.0.5 | Estado |
|-----------|-------|---------------|---------------|--------|
| π (pi) | `3.14159265358979` | codificación posicional, normalización angular | `:= PI 3.14159265358979323846` | ⚠️ workaround trivial |
| e (euler) | `2.71828182845904` | `exp` via `E ^ x`, documentación | `:= E 2.71828182845904523536` | ⚠️ workaround trivial |

Las constantes como módulo `std/matematica` son convenientes pero no urgentes.
El workaround con `:=` funciona perfectamente y es idiomático en Zymbol.

---

## Sección 6 — Características de Lenguaje para IA

| Característica | Uso en Zofía | Zymbol v0.0.5 | Estado | Notas |
|----------------|-------------|---------------|--------|-------|
| Funciones de primera clase | pasar activaciones como argumento | `(x -> expr)` lambda, funciones nombradas | ✅ | Idiomático |
| HOF map `$>` | operaciones element-wise en tensores | `lista $> (x -> f(x))` | ✅ | Core de Zofía |
| HOF reduce `$<` | suma, producto, norma | `lista $< (acc x -> acc + x)` | ✅ | |
| HOF filter `$|` | máscaras en atención | `lista $| (x -> x > 0)` | ✅ | |
| Tuplas nombradas | config del modelo, pesos por capa | `(dim: 8, cabezas: 2)` | ✅ | |
| Parámetros mutables `<~` | write-back de gradientes | `pesos<~` en `param_list` | ✅ | Clave para backprop |
| Módulos `<#` | separar tensor/activacion/perdida | `<# modulos/tensor => ten` | ✅ | Arquitectura de Zofía |
| Formateo de decimales | mostrar pesos/pérdidas legibles | `#.4\|x\|` redondea · `#!4\|x\|` trunca | ✅ | Ver nota debajo |

### Formateo de flotantes — VERIFICADO ✅ (GAP-Z004 cerrado)

Existen dos operadores distintos, ambos confirmados en v0.0.5:

| Operador | Comportamiento | Ejemplo con `pi = 3.14159...` |
|----------|---------------|-------------------------------|
| `#.4\|x\|` | Redondea a 4 decimales | `3.1416` |
| `#!4\|x\|` | Trunca a 4 decimales | `3.1415` |

**Para Zofía usar `#.###|x|`** — redondear es más apropiado para mostrar
pérdidas y pesos con precisión representativa.

```zymbol
perdida = 0.38472918
>> #.4|perdida|      // muestra: 0.3847
>> #.6|perdida|      // muestra: 0.384729
```

**Verificación de tipo con `#?`:** devuelve una tupla `(tipo, tamaño, valor)`:
```zymbol
x = 3.14
x#?   // → (##., 16, 3.14)    decimal confirmado

n = 42
n#?   // → (###, 2, 42)       entero confirmado

s = "hola"
s#?   // → (##", 4, hola)     texto confirmado
```

El tipo simbólico en la posición 1 de la tupla es `##.`, `###` o `##"` —
los mismos símbolos del lenguaje. GAP-Z004 queda cerrado.

---

## Sección 7 — Tabla de Brechas (GAP Consolidado)

| ID | Descripción | Funciones afectadas | Impacto en Zofía | Prioridad |
|----|-------------|---------------------|-----------------|-----------|
| GAP-Z001 | Sin funciones matemáticas nativas | `exp`, `ln`, `sqrt`, `sin`, `cos` | Fases 3–5 | 🔴 Alta |
| GAP-Z001b | Sin `abs`, `max`, `min` | activación ReLU, clipeo | Fase 3 | 🟡 Media |
| GAP-Z002 | Sin constantes `π`, `e` nativas | codificación posicional | Fase 5 | 🟢 Baja (`:=` suficiente) |
| GAP-Z003 | Sin generador aleatorio nativo | inicialización de pesos | Fase 2 | 🟡 Media (LCG como workaround) |
| ~~GAP-Z004~~ | ~~Formateo de flotantes~~ | ~~visualización de tensores~~ | ~~Todas las fases~~ | ✅ Cerrado — `#.4\|x\|` redondea, `#!4\|x\|` trunca |

---

## Sección 8 — Propuestas Concretas para v0.0.6

### Propuesta 1: Módulo `std/matematica` (Rust wraps)

La solución de mayor impacto y menor costo. No requiere cambios de gramática —
usa la sintaxis de módulos existente. Se implementa en Rust como un módulo
built-in que expone wrappers de `f64`.

**API propuesta (agnóstica de idioma, en español siguiendo Zofía):**

```
<# std/matematica => mat

mat::raiz(x)       -- f64::sqrt(x)
mat::abs(x)        -- f64::abs(x)
mat::maxn(a, b)    -- f64::max(a, b)
mat::minn(a, b)    -- f64::min(a, b)
mat::exp(x)        -- f64::exp(x)
mat::ln(x)         -- f64::ln(x)
mat::seno(x)       -- f64::sin(x)
mat::coseno(x)     -- f64::cos(x)
mat::potencia(b,e) -- f64::powf(b, e)  (para exp flotante)
mat::PI            -- std::f64::consts::PI
mat::E             -- std::f64::consts::E
```

Impacto: elimina los 8 GAPs de la Sección 4 con una sola adición de stdlib.

**Naming principle:** nombres en español (Zofía target audience), pero cortos.
`mat::raiz` no es `mat::raiz_cuadrada` — el contexto del módulo da el resto.

### Propuesta 2: Operador `$@` — map en contexto (IDEA-Z003)

Actualmente `$>` crea una nueva lista. Para operaciones in-place sobre tensores
grandes (ej: aplicar activación a una capa completa), un operador de map
que modifica en lugar sería más eficiente.

**Adición al EBNF:**
```ebnf
(* En collection_postfix, agregar: *)
| "$@" , hof_callable    (* map in-place: arr$@ (x -> x * 2.0) *)
```

**Caso de uso en Zofía:**
```zymbol
// Activar una capa completa sin crear lista temporal
capa $@ (x -> mat::maxn(0.0, x))   // ReLU in-place
```

Sin `$@`, el código actual requiere:
```zymbol
capa = capa $> (x -> mat::maxn(0.0, x))   // crea nueva lista
```

Para Zofía educativa, la diferencia de rendimiento no es crítica. `$@` es
conveniente pero no urgente para v0.0.6.

### Propuesta 3: Input tipado `<<` con restricciones (IDEA-Z004)

Para completar SPRE en Zymbol y para Zofía (hiperparámetros válidos):

**Forma propuesta (agnóstica de idioma):**
```
<< :###4 variable      -- entero de hasta 4 dígitos (0–9999)
<< :##.2 variable      -- decimal con hasta 2 decimales
<< :##.2+ variable     -- decimal positivo con hasta 2 decimales
<< :##" 50 variable    -- texto de hasta 50 caracteres
```

**Adición al EBNF:**
```ebnf
(* Extender input_stmt: *)
input_stmt =
    "<<" , [ prompt_string ] , ( identifier | "#|" , identifier , "|" )
  | "<<" , ":" , type_constraint , identifier
  ;

type_constraint =
    "###" , [ integer_literal ]          (* entero, máx ### dígitos *)
  | "##." , [ integer_literal ]          (* decimal, máx ### decimales *)
  | "##." , integer_literal , "+"        (* decimal positivo *)
  | "##\"" , integer_literal             (* texto, máx ### chars *)
  ;
```

Uso en Zofía:
```zymbol
<< "Tasa de aprendizaje (ej: 0.01): " :##.4 tasa
<< "Dimensión del modelo (ej: 8):   " :###2 dim
```

Si el usuario ingresa un valor inválido, el intérprete repite la solicitud
automáticamente hasta recibir un valor dentro del tipo especificado.

### ~~Propuesta 4: Verificar `#!4|x|`~~ — COMPLETADA ✅

Verificación ejecutada en v0.0.5. Resultados:

```
pi = 3.14159265358979

#!4|pi|  →  3.1415   (trunca)
#.4|pi|  →  3.1416   (redondea)
#!2|pi|  →  3.14
#.2|pi|  →  3.14
#!0|pi|  →  3
#.0|pi|  →  3

pi#?  →  (##., 16, 3.14159265358979)
```

GAP-Z004 cerrado. Eliminar de HALLAZGOS.md y ROADMAP. Usar `#.###|x|` en Zofía.

---

## Sección 9 — Mapa de Implementación

Para construir Zofía con lo que existe hoy (sin esperar v0.0.6):

```
Fase 1 — tensor        → implementar directamente (✅ sin GAPs)
Fase 2 — grad          → implementar directamente (✅ sin GAPs)
                          └── random seed via BashExec una sola vez
Fase 0 — matematica    → implementar workarounds en puro Zymbol:
                          ├── raiz_cuadrada:  Newton-Raphson, 20 iter.
                          ├── exponencial:    Taylor, 30 términos
                          ├── logaritmo:      arctanh identity
                          ├── seno/coseno:    Taylor, 15 términos
                          ├── abs/max/min:    condicionales inline
                          └── LCG:            reutilizar de serpiente/
Fase 3 — activacion    → depende de fase 0 (exp, ln para sigmoide, softmax)
Fase 4 — atencion      → depende de fase 0 (raiz para atención escalada)
Fase 5 — transformador → depende de fase 0 (seno, coseno para PE)
```

Cuando `std/matematica` esté disponible en v0.0.6, reemplazar `matematica.zy`
con una sola línea:
```zymbol
// Antes (Zofía v1 — workaround):
<# modulos/matematica => mat

// Después (Zofía v2 — std nativa):
<# std/matematica => mat
```

La API es idéntica. El resto del código de Zofía no cambia.

---

## Conclusión

Zymbol v0.0.5 cubre el 64% de las necesidades matemáticas de Zofía de forma directa.
El 22% restante (8 funciones: `exp`, `ln`, `sqrt`, `sin`, `cos`, `abs`, `max`, `min`)
se puede cubrir con implementaciones en Zymbol puro como módulo `matematica.zy`.

La adición de `std/matematica` en v0.0.6 eliminaría la totalidad de las brechas
con un cambio de una sola línea en cada módulo de Zofía. Es la mejora de mayor
retorno por esfuerzo identificada en esta evaluación.

---

*Evaluación preparada como parte del ciclo de feedback Zofía → Zymbol v0.0.6.*
*Ver `HALLAZGOS.md` para el registro vivo de GAPs. Ver `interpreter/ROADMAP.md`
para la planificación de v0.0.6.*
