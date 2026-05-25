# Evaluación Matemática — Zofía vs Zymbol v0.0.6

Documento de contraste entre las operaciones matemáticas que Zofía requiere
y lo que Zymbol v0.0.6 provee de forma directa.

Fuentes de referencia:
- `Zofia/docs/00_fundamentos_matematicos.md` — necesidades del proyecto
- `interpreter/GUIDE.md` — referencia del lenguaje
- `Zofia/ANALISIS_FASE0.md` — análisis empírico de brechas (todos resueltos)

> **Actualización v0.0.6 (2026-05-24):** `std/math` implementado con 22 funciones
> nativas. Todos los GAPs matemáticos de v0.0.5 están cerrados. Ver Sección 4.

---

## Estado de cobertura (resumen ejecutivo)

| Categoría | Operaciones | ✅ Directo | ⚠️ Workaround | ❌ Ausente |
|-----------|-------------|-----------|---------------|-----------|
| Aritmética escalar | 6 | 6 | 0 | 0 |
| Estructuras (vector/matriz) | 5 | 5 | 0 | 0 |
| Operaciones lineales | 6 | 6 | 0 | 0 |
| Funciones matemáticas | 13 | 13 | 0 | 0 |
| Constantes (π, e) | 2 | 2 | 0 | 0 |
| Características de lenguaje | 9 | 9 | 0 | 0 |
| **Total** | **41** | **41 (100%)** | **0** | **0** |

---

## Sección 1 — Aritmética Escalar

Todo el álgebra escalar que `00_fundamentos_matematicos.md` describe funciona
directamente en Zymbol sin ninguna adaptación.

| Operación | Notación matemática | Zymbol v0.0.6 | Estado |
|-----------|---------------------|---------------|--------|
| Suma | `a + b` | `a + b` | ✅ |
| Resta | `a - b` | `a - b` | ✅ |
| Multiplicación | `a × b` | `a * b` | ✅ |
| División | `a / b` | `a / b` | ✅ |
| Módulo | `a mod b` | `a % b` | ✅ |
| Potencia | `aⁿ` | `a ^ n` | ✅ (`^` asociativo a la derecha) |

**Nota:** `^` invoca `f64::powf` cuando el exponente es flotante — `2.0 ^ 0.5 = 1.4142...`.
Para `eˣ` usar `mat::exp(x)` (más preciso que `mat.E ^ x` para x negativo grande).

---

## Sección 2 — Estructuras de Datos (Vector y Matriz)

| Concepto | Descripción | Zymbol v0.0.6 | Estado |
|----------|-------------|---------------|--------|
| Vector | Lista plana de escalares | `[1.0, 2.0, 3.0]` | ✅ |
| Matriz | Lista de vectores | `[[1.0, 2.0], [3.0, 4.0]]` | ✅ |
| Literal flotante | `3.14`, `1.5e10` | soportado directamente | ✅ |
| Indexación vector | `v[i]` | `v[i]` (1-based) | ✅ |
| Indexación matriz | `M[i][j]` | `M[i>j]` (navegación profunda canónica) | ✅ |

**Indexación 1-based:** `v[1]` es el primer elemento. `v[-1]` es el último.

---

## Sección 3 — Operaciones de Álgebra Lineal

| Operación | Fórmula | Zymbol v0.0.6 | Estado |
|-----------|---------|---------------|--------|
| Suma element-wise | `(a+b)ᵢ = aᵢ + bᵢ` | `sumar_vec(a, b)` con `$>` | ✅ |
| Multiplicación escalar | `(αv)ᵢ = α × vᵢ` | `v $> x -> x * alfa` | ✅ |
| Producto punto | `a·b = Σᵢ aᵢbᵢ` | loop explícito | ✅ |
| Multiplicación matricial | `(AB)ᵢⱼ = Σₖ AᵢₖBₖⱼ` | triple loop anidado | ✅ |
| Transposición | `Aᵀᵢⱼ = Aⱼᵢ` | doble loop anidado | ✅ |
| Suma de lista | `Σᵢ xᵢ` | `lista $< (acc x -> acc + x)` | ✅ |

### Actualización v0.0.6: update profundo canónico

La actualización de celdas de matrices ahora usa la sintaxis canónica `arr[i>j]$~ val`,
consistente con la lectura profunda `arr[i>j]`:

```zymbol
m = [[1.0, 2.0], [3.0, 4.0]]
m = m[1>2]$~ 99.0       // antes: m = m[1]$~ (m[1][2]$~ 99.0)
>> m[1>2]               // → 99
```

### Producto punto — implementación directa

```zymbol
producto_punto(a, b) {
    _n = a$#
    suma = 0.0
    @ i:1.._n { suma = suma + a[i] * b[i] }
    <~ suma
}
```

---

## Sección 4 — Funciones Matemáticas Elementales

### Estado v0.0.6: todas disponibles en `std/math`

```zymbol
<# std/math => mat
```

| Función | Necesaria para | Estado v0.0.5 | Estado v0.0.6 |
|---------|---------------|---------------|---------------|
| `mat::sqrt(x)` | norma L₂, atención escalada `√dₖ` | ❌ workaround Newton | ✅ nativa |
| `mat::abs(x)` | ReLU, clipeo de gradiente | ❌ condicional inline | ✅ nativa |
| `mat::max(a, b)` | ReLU: `max(0, x)` | ❌ condicional inline | ✅ nativa |
| `mat::min(a, b)` | clipeo, clamp | ❌ condicional inline | ✅ nativa |
| `mat::exp(x)` | sigmoide, softmax | ❌ Taylor 30 términos | ✅ nativa |
| `mat::ln(x)` | entropía cruzada | ❌ identidad arctanh | ✅ nativa |
| `mat::sin(x)` | codificación posicional | ❌ Taylor 15 términos | ✅ nativa |
| `mat::cos(x)` | codificación posicional | ❌ Taylor 15 términos | ✅ nativa |
| `mat::tan(x)` | cálculos angulares | ❌ ausente | ✅ nativa |
| `mat::tanh(x)` | activación tanh | ❌ ausente | ✅ nativa |
| `mat::sigmoid(x)` | activación sigmoide | ❌ ausente | ✅ nativa |
| `mat::atan(x)` | codificación posicional | ❌ ausente | ✅ nativa |
| `mat::atan2(y, x)` | ángulos con cuadrante | ❌ ausente | ✅ nativa |
| `mat::asin(x)` | dominio [-1,1] | ❌ ausente | ✅ nativa |
| `mat::acos(x)` | dominio [-1,1] | ❌ ausente | ✅ nativa |
| `mat::sinh(x)` | hiperbólica | ❌ ausente | ✅ nativa |
| `mat::cosh(x)` | hiperbólica | ❌ ausente | ✅ nativa |
| `mat::pow(b, e)` | potencias flotantes | ❌ usaba `^` | ✅ nativa |
| `mat::floor(x)` | discretización | ❌ ausente | ✅ nativa |
| `mat::ceil(x)` | discretización | ❌ ausente | ✅ nativa |
| `mat::round(x)` | redondeo | ❌ ausente | ✅ nativa |
| `mat::log(x)` / `mat::log(x, b)` | logaritmo base b | ❌ ausente | ✅ nativa |

### Uso en Zofia

```zymbol
<# std/math => mat

// Activaciones
a1 = z1 $> v -> mat::tanh(v)
a2 = z2 $> v -> mat::sigmoid(v)

// Atención escalada
escala = mat::sqrt(##.(dim_clave))
puntos = puntos $> p -> p / escala

// Codificación posicional
pe = mat::sin(pos / mat::pow(10000.0, 2.0 * i / d_modelo))
```

---

## Sección 5 — Constantes Matemáticas

| Constante | Valor | Necesaria para | Estado v0.0.5 | Estado v0.0.6 |
|-----------|-------|---------------|---------------|---------------|
| π (pi) | `3.141592653589793` | codificación posicional | ⚠️ `:= PI 3.14...` | ✅ `mat.PI` |
| e (euler) | `2.718281828459045` | `exp` como constante | ⚠️ `:= E 2.71...` | ✅ `mat.E` |

```zymbol
<# std/math => mat
>> mat.PI   // → 3.141592653589793
>> mat.E    // → 2.718281828459045
```

---

## Sección 6 — Características de Lenguaje para IA

| Característica | Uso en Zofía | Estado |
|----------------|-------------|--------|
| Funciones de primera clase como HOF | pasar activaciones como argumento | ✅ |
| HOF map `$>` | operaciones element-wise en tensores | ✅ |
| HOF reduce `$<` | suma, producto, norma | ✅ |
| HOF filter `$|` | máscaras en atención | ✅ |
| Tuplas nombradas + `$~` por campo | config del modelo, actualizar gradientes | ✅ |
| Parámetros de salida `<~` | write-back de gradientes | ✅ |
| Módulos `<#` | separar tensor/activacion/perdida | ✅ |
| Formateo de decimales `#.N\|x\|` | mostrar pesos/pérdidas legibles | ✅ |
| Funciones nombradas como HOF con módulo | `aplicar(tanh_fn, v)` | ✅ (G7 resuelto) |

### Actualización v0.0.6: funciones nombradas como HOF

Las funciones nombradas que usan `mat::fn` internamente ya pueden pasarse como
argumento a otras funciones — el contexto de módulo se captura en definición:

```zymbol
<# std/math => mat

mi_tanh(x) { <~ mat::tanh(x) }

aplicar_activacion(f, capa) { <~ capa $> v -> f(v) }

a1 = aplicar_activacion(mi_tanh, z1)   // ✅ funciona en v0.0.6
```

### Formateo de flotantes — verificado

| Operador | Comportamiento | Ejemplo `pi = 3.14159...` |
|----------|---------------|---------------------------|
| `#.4\|x\|` | Redondea a 4 decimales | `3.1416` |
| `#!4\|x\|` | Trunca a 4 decimales | `3.1415` |

Usar `#.N|x|` para mostrar pérdidas y pesos en Zofia.

---

## Sección 7 — Tabla de GAPs (estado final)

| ID | Descripción | Estado v0.0.5 | Estado v0.0.6 |
|----|-------------|---------------|---------------|
| GAP-Z001 | Sin funciones matemáticas nativas (`exp`, `ln`, `sqrt`, `sin`, `cos`) | 🔴 Alta | ✅ Cerrado — `std/math` |
| GAP-Z001b | Sin `abs`, `max`, `min` | 🟡 Media | ✅ Cerrado — `std/math` |
| GAP-Z002 | Sin constantes `π`, `e` nativas | 🟢 Baja | ✅ Cerrado — `mat.PI`, `mat.E` |
| GAP-Z003 | Sin generador aleatorio nativo | 🟡 Media | ✅ Cerrado — `std/random` |
| GAP-Z004 | Formateo de flotantes | ✅ Cerrado en v0.0.5 | ✅ |
| GAP-Z006 | `$~` deep update canónico `arr[i>j]$~ val` | — | ✅ Cerrado — consistente con lectura profunda |
| GAP-Z007 | `$~` no soporta tuplas nombradas | — | ✅ Cerrado — `t["campo"]$~ val` |
| GAP-Z008 | Inferencia monomorfa bloquea funciones numéricas mixtas | — | ✅ Cerrado — `Numeric → Float` |
| GAP-Z009 | Funciones nombradas pierden alias de módulo al ser HOF | — | ✅ Cerrado — `module_aliases` en `FunctionValue` |

---

## Sección 8 — Generador Aleatorio (`std/random`)

GAP-Z003: disponible en v0.0.6 como `std/random`.

```zymbol
<# std/random => rng

// Peso aleatorio en [-1, 1] (Xavier-style seed)
w = rng::peso_f64()          // Float en (-1.0, 1.0)

// Entero aleatorio en rango [a, b]
n = rng::entero(1, 10)       // Int en [1, 10]

// Array de Float aleatorios
pesos = rng::rango(8)        // [Float × 8] en (-1, 1)
```

Para inicialización de pesos en Zofia: `rng::peso_f64()` produce valores uniformes
en `(-1.0, 1.0)` adecuados para capas pequeñas. Para capas grandes considerar
escalar por `1/sqrt(n_entradas)` (inicialización Xavier).

---

## Sección 9 — Plan de implementación (actualizado)

Con Zymbol v0.0.6, Zofia puede implementarse sin ningún módulo de workaround matemático:

```
Fase 1 — tensor        → ✅ implementable directamente
Fase 2 — grad          → ✅ implementable directamente (std/random para pesos)
Fase 3 — activacion    → ✅ usa mat::tanh, mat::sigmoid directamente
Fase 4 — atencion      → ✅ usa mat::sqrt, mat::exp directamente
Fase 5 — transformador → ✅ usa mat::sin, mat::cos, mat.PI directamente
```

El módulo `matematica.zy` de workaround ya no es necesario. Importar directamente:

```zymbol
<# std/math => mat
```

---

## Conclusión

Zymbol v0.0.6 cubre el **100% de las necesidades matemáticas de Zofia** de forma
directa a través de `std/math`. Todos los GAPs identificados en v0.0.5 están cerrados:

- 22 funciones nativas en `std/math` (incluyendo hiperbólicas, trigonométricas inversas y sigmoid)
- Constantes `mat.PI` y `mat.E` disponibles como módulo
- `std/random` para inicialización de pesos
- Funciones nombradas como HOF sin pérdida de contexto de módulo
- `$~` funcional sobre tuplas nombradas por posición y por nombre de campo
- Inferencia numérica polimórfica (Int y Float intercambiables en funciones aritméticas)

*Evaluación actualizada a v0.0.6 — 2026-05-24.*
*Ver `ANALISIS_FASE0.md` para el detalle técnico de cada gap resuelto.*
