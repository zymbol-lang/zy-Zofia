# Análisis Fase 0 — Brechas del lenguaje Zymbol para Zofia

> **Objetivo:** identificar qué mejoras directas al intérprete/parser de Zymbol son
> necesarias antes de implementar los módulos de Zofia, eliminando todo workaround
> de la implementación final.
>
> Metodología: pruebas empíricas exhaustivas contra `zymbol run` v0.0.6.  
> Análisis inicial: 2026-05-24. Implementación completada: 2026-05-24.

---

## Resumen ejecutivo

| # | Brecha | Estado | Prioridad |
|---|--------|--------|-----------|
| G1 | `arr[i>j]$~ val` — actualización profunda canónica | ✅ Implementado | P1 |
| G2 | `$~` no soporta tuplas nombradas | ✅ Implementado | P1 |
| G3 | `tanh`, `tan`, `sigmoid` y otras ausentes de `std/math` | ✅ Implementado | P1 |
| G4 | Inferencia de tipo bloquea funciones numéricas mixtas | ✅ Implementado | P2 |
| G7 | Funciones nombradas pierden alias de módulo al pasarse como HOF | ✅ Implementado | P2 |

**Todos los gaps están resueltos. La Fase 1 puede comenzar.**

---

## Mecanismos que funcionan por diseño

### División con Float

```zymbol
>> 8 / 3 ¶     // → 2   (ambos Int: división entera, por diseño)
>> 8.0 / 3 ¶   // → 2.666...  ✅
>> 8 / 3.0 ¶   // → 2.666...  ✅
```

Para dimensiones como `dim_modelo / num_cabezas`, declarar `dim_modelo := 256.0`.

### Display de Float

```zymbol
>> 1.0 ¶          // → 1     (sin .0 — por diseño)
>> #.4|0.33333| ¶ // → 0.3333  ✅
```

`1.0` se muestra como `1` — es intencional. Usar `#.N|x|` en funciones de impresión de Zofia.

---

## G1 — Actualización profunda canónica `arr[i>j]$~ val`

**Estado: ✅ Implementado**

`arr[i>j]` es la sintaxis canónica de acceso profundo en Zymbol (la forma `arr[i][j]` está
deprecada para lectura). El operador `$~` ahora acepta la misma sintaxis para escritura,
siendo coherente con la filosofía del lenguaje.

### Sintaxis

```zymbol
// Actualización de un elemento en una matriz 2D
m = [[1, 2, 3], [4, 5, 6]]
m = m[1>2]$~ 99
>> m       // → [[1, 99, 3], [4, 5, 6]]  ✅
>> m[1>2]  // → 99  ✅

// 3 niveles de profundidad
t = [[[1, 2], [3, 4]], [[5, 6], [7, 8]]]
t = t[2>1>2]$~ 99
>> t[2>1>2]  // → 99  ✅

// El original no se modifica (inmutabilidad funcional)
```

### Implementación

- Parser: `parse_collection_update` acepta `Expr::DeepIndex` además de `Expr::Index`
- Intérprete: `eval_collection_update` detecta `DeepIndex` y llama a `deep_update_value`
- `deep_update_value`: función recursiva pura — evalúa índices, desciende, reconstruye de adentro hacia afuera
- Soporta `Array`, `Tuple` posicional y `NamedTuple` en cualquier nivel del path

---

## G2 — `$~` no soportaba tuplas nombradas

**Estado: ✅ Implementado**

### Sintaxis

```zymbol
p = (x: 1, y: 2, z: 3)

// Por índice posicional (1-based)
p2 = p[2]$~ 99
>> p2.y  // → 99  ✅

// Por nombre de campo (string)
p3 = p["z"]$~ 42
>> p3.z  // → 42  ✅

// Índice negativo
p4 = p[-1]$~ 77
>> p4.z  // → 77  ✅

// Deep update en named tuple anidado
a = (val: 10, meta: (ok: #1, code: 0))
a2 = a["meta"]$~ (a.meta["code"]$~ 200)
>> a2.meta.code  // → 200  ✅

// El original no se modifica
>> p.y  // → 2  ✅
```

### Implementación

- `eval_collection_update` en `collection_ops.rs`: nuevo arm `Value::NamedTuple`
- Acepta `Value::Int` (posicional, 1-based) y `Value::String` (por nombre de campo)
- Reconstruye el vector `Vec<(String, Value)>` con el campo actualizado
- Test: `tests/collections/named_tuple_update.zy` (marcado `@vm-skip`)

---

## G3 — Funciones matemáticas faltantes en `std/math`

**Estado: ✅ Implementado**

### Funciones añadidas

| Función | Descripción | Dominio |
|---------|-------------|---------|
| `mat::tanh(x)` | tangente hiperbólica | ℝ |
| `mat::sinh(x)` | seno hiperbólico | ℝ |
| `mat::cosh(x)` | coseno hiperbólico | ℝ |
| `mat::sigmoid(x)` | función logística `1/(1+e^-x)` | ℝ |
| `mat::tan(x)` | tangente | ℝ \ {π/2 + nπ} |
| `mat::atan(x)` | arctangente | ℝ |
| `mat::atan2(y, x)` | arctangente con cuadrante | ℝ² |
| `mat::asin(x)` | arco seno | [-1, 1] |
| `mat::acos(x)` | arco coseno | [-1, 1] |

### Uso

```zymbol
<# std/math => mat

>> mat::tanh(1)      // → 0.761594  ✅
>> mat::sigmoid(0)   // → 0.5       ✅
>> mat::sigmoid(2)   // → 0.880797  ✅
>> mat::tan(0)       // → 0         ✅
>> mat::atan2(1, 1)  // → 0.785398  (π/4)  ✅
```

### Implementación

- `stdlib/math.rs`: 9 funciones nativas (`fn math_tanh`, `math_sigmoid`, `math_tan`, …)
- Registradas en `register()` con aridad correcta (todas 1, `atan2` = 2)
- `asin`/`acos` validan dominio [-1, 1] con error descriptivo
- Adaptador español: `tests/stdlib/matematica_es.zy` actualizado (tanh → tanh, sigmoid → sigmoide, asin → arcsen, …)
- Tests golden: `stdlib_math_hyperbolic.zy/.expected`, `stdlib_math_trig_ext.zy/.expected`

---

## G4 — Inferencia de tipo monomorfa

**Estado: ✅ Implementado**

### Comportamiento corregido

```zymbol
multiplicar(a, b) { <~ a * b }

>> multiplicar(3, 4)     // ✅ → 12
>> multiplicar(3.0, 4.0) // ✅ → 12
>> multiplicar(3, 4.0)   // ✅ → 12
>> multiplicar(3.0, 4)   // ✅ → 12

x = 2.0
>> multiplicar(x, x)     // ✅ → 4

escalar_vec(v, s) { <~ v $> elem -> elem * s }
>> escalar_vec([1.0, 2.0], 2.0)  // ✅ → [2, 4]
>> escalar_vec([1.0, 2.0], 2)    // ✅ → [2, 4]
```

La inferencia sigue siendo precisa cuando hay evidencia de `Int` en el cuerpo:

```zymbol
siguiente(n) {
    ? (n > 0) { <~ n + 1 }  // n > 0 con literal 0 → CompatibleWith(Int)
    <~ 1
}
>> siguiente(5)    // ✅
>> siguiente(5.0)  // ❌ correcto — función claramente de dominio entero
```

### Implementación

**Causa raíz:** `TypeConstraint::Numeric.to_type()` devolvía `ZymbolType::Int` como
default cuando un parámetro solo tenía restricción aritmética (sin evidencia de tipo
específico en el cuerpo). Esto fijaba el parámetro como Int, rechazando llamadas Float.

**Fix:** `TypeConstraint::Numeric.to_type()` ahora devuelve `ZymbolType::Float`.

- Parámetros con **solo** operaciones aritméticas (`a * b`, `a + b`) → infieren `Float`
- Llamadas con `Int` siguen funcionando: `Int → Float` ya era compatible en el checker
- Parámetros con evidencia de `Int` (comparación `n > 0`, indexación `arr[n]`) → siguen
  siendo `Exact(Int)` via unify: `Numeric + CompatibleWith(Int) = Exact(Int)`

Archivo: `zymbol-semantic/src/type_check.rs`, línea `TypeConstraint::Numeric.to_type()`.

---

## G7 — Funciones nombradas perdían alias de módulo al pasarse como HOF

**Estado: ✅ Implementado**

### Comportamiento corregido

```zymbol
<# std/math => mat

sqrt_fn(x) { <~ mat::sqrt(x) }

aplicar_lista(f, lista) {
    <~ lista $> x -> f(x)
}

resultado = aplicar_lista(sqrt_fn, [4.0, 9.0, 16.0])
>> resultado[1]  // → 2  ✅
>> resultado[2]  // → 3  ✅
>> resultado[3]  // → 4  ✅
```

### Causa raíz

`take_call_state()` guarda y limpia `import_aliases`. Para funciones nombradas usadas
como HOF, el contexto de aliases no se restauraba. Lambdas con body de expresión simple
tomaban un "fast path" que no llama `take_call_state`, por eso funcionaban.

### Implementación

- `FunctionValue` (lib.rs): nuevo campo `module_aliases: HashMap<String, PathBuf>`
- `func_def_to_value` (functions_lambda.rs): captura `self.import_aliases.clone()` en
  el momento de definición de la función nombrada
- `eval_lambda_call`: si `func.is_named_fn && !func.module_aliases.is_empty()`,
  restaura `self.import_aliases = func.module_aliases.clone()` después de `take_call_state()`
- Lambdas anónimas tienen `module_aliases: HashMap::new()` (no las necesitan)

---

## Capacidades disponibles para Zofia

| Capacidad | Sintaxis | Estado |
|-----------|----------|--------|
| Actualización profunda de matriz | `m = m[i>j]$~ val` | ✅ |
| `$~` en arrays | `a = a[i]$~ val` | ✅ |
| `$~` en tuplas posicionales | `t = t[i]$~ val` | ✅ |
| `$~` en tuplas nombradas por posición | `t = t[i]$~ val` | ✅ |
| `$~` en tuplas nombradas por campo | `t = t["campo"]$~ val` | ✅ |
| `$~` profundo en cualquier colección | `t[i>j>k]$~ val` | ✅ |
| Función nombrada como HOF con módulo | `aplicar(sqrt_fn, x)` | ✅ |
| Lambda como HOF con módulo | `f := x -> mat::fn(x)` | ✅ |
| `tanh`, `sigmoid`, hiperbólicas | `mat::tanh(x)`, `mat::sigmoid(x)` | ✅ |
| `tan`, `atan`, `atan2`, `asin`, `acos` | `mat::tan(x)`, `mat::atan2(y,x)` | ✅ |
| `sqrt`, `exp`, `ln`, `sin`, `cos`, `pow` | `std/math` v0.0.6 | ✅ |
| `PI`, `E` como constantes | `mat.PI`, `mat.E` | ✅ |
| Construcción dinámica de matrices | `$+` en bucles | ✅ |
| Lectura profunda | `m[i>j]` | ✅ |
| Map, filter, reduce | `$>`, `$|`, `$<` | ✅ |
| Parámetros de salida | `f(arr<~)` modifica caller | ✅ |

---

## Estado por módulo Zofia

| Módulo | Brechas originales | Estado |
|--------|--------------------|--------|
| `tensor` | — | ✅ Listo desde inicio |
| `activacion` | G3 (tanh/sigmoid), G4 (mixto Int/Float), G7 (HOF) | ✅ Desbloqueado |
| `perdida` | G4 (gradiente numérico) | ✅ Desbloqueado |
| `grad` | G2 ($~ en named tuple), G4 | ✅ Desbloqueado |
| `atencion` | G4, G7 (activación como parámetro) | ✅ Desbloqueado |
| `transformador` | G3 + G4 + G7 | ✅ Desbloqueado |
