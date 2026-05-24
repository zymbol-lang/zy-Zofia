# Tensores

> Documento 01 — Prerequisito: 00_fundamentos_matematicos.md

---

## ¿Qué es un tensor?

Un tensor es una generalización de escalar, vector y matriz a cualquier número
de dimensiones.

```
Escalar   →  un número            [dimensión 0]   ej: 3.14
Vector    →  lista de números     [dimensión 1]   ej: [1, 2, 3]
Matriz    →  tabla de números     [dimensión 2]   ej: [[1,2],[3,4]]
Tensor 3D →  cubo de números      [dimensión 3]   ej: [[[...]]]
Tensor ND →  N dimensiones        [dimensión N]
```

En código de IA, casi todo son tensores. Un lote de imágenes tiene 4 dimensiones:
`[lote, alto, ancho, canales_de_color]`. Una secuencia de texto tiene 3:
`[lote, longitud_secuencia, dim_embedding]`.

---

## La forma (shape)

La propiedad más importante de un tensor es su **forma**: cuántos elementos
tiene en cada dimensión.

```
escalar:  forma = []           -- ninguna dimensión
vector:   forma = [4]          -- 4 elementos
matriz:   forma = [3, 4]       -- 3 filas, 4 columnas
tensor3d: forma = [2, 3, 4]    -- 2 "planos" de matrices 3×4
```

El total de elementos es el producto de todos los números de la forma:
- `[3, 4]` → 3 × 4 = 12 elementos
- `[2, 3, 4]` → 2 × 3 × 4 = 24 elementos

**Verificar la forma es lo primero** cuando algo no funciona. El 90% de los
errores en implementaciones de IA son incompatibilidades de forma.

---

## Cómo Zofía representa tensores

Zymbol no tiene un tipo tensor nativo. En Zofía, un tensor es una lista de listas
de listas... anidadas exactamente tantas veces como dimensiones tenga.

```
-- Vector: lista plana
vec = [1.0, 2.0, 3.0]

-- Matriz 2×3: lista de listas
mat = [[1.0, 2.0, 3.0],
       [4.0, 5.0, 6.0]]

-- Tensor 3D de forma [2, 2, 3]
t3d = [[[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]],
       [[7.0, 8.0, 9.0], [10.0, 11.0, 12.0]]]
```

Esta representación es suficiente para implementar todos los conceptos de Zofía.

---

## Operaciones sobre tensores

### Acceso a elementos

Para acceder a un elemento, se navega dimensión por dimensión con índices.

```
mat = [[1.0, 2.0, 3.0],
       [4.0, 5.0, 6.0]]

mat[0]    -- primera fila: [1.0, 2.0, 3.0]
mat[1]    -- segunda fila: [4.0, 5.0, 6.0]
mat[0][2] -- tercer elemento de la primera fila: 3.0
```

En la API de Zofía: `elemento(mat, [0, 2])` devuelve `3.0`.

---

### Reformar (reshape)

Reorganiza los elementos en una forma diferente sin cambiarlos.

```
lista = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]   -- forma [6]

reformar(lista, [2, 3]) →
  [[1.0, 2.0, 3.0],
   [4.0, 5.0, 6.0]]

reformar(lista, [3, 2]) →
  [[1.0, 2.0],
   [3.0, 4.0],
   [5.0, 6.0]]
```

**Regla:** el producto de las dimensiones debe ser igual antes y después.
6 elementos = 2×3 = 3×2 = 6×1 = 1×6.

**Uso en transformers:** antes de multi-head attention, reformamos la entrada
para dividirla en múltiples cabezas de atención.

---

### Aplanar (flatten)

Caso especial de reformar: convierte cualquier tensor en una lista plana.

```
mat = [[1.0, 2.0], [3.0, 4.0]]
aplanar(mat) → [1.0, 2.0, 3.0, 4.0]
```

---

### Transponer (transpose)

Para matrices 2D: intercambia filas por columnas.

```
A = [[1, 2, 3],    -- forma [2, 3]
     [4, 5, 6]]

Aᵀ = [[1, 4],     -- forma [3, 2]
      [2, 5],
      [3, 6]]
```

**Uso en atención:** Q × Kᵀ calcula puntuaciones de similitud entre
cada par de posiciones en una secuencia.

---

### Producto matricial (matmul)

Multiplicación de matrices. La operación más frecuente en redes neuronales.

```
A = [[1, 2],   -- [2×2]
     [3, 4]]

B = [[5, 6],   -- [2×2]
     [7, 8]]

AB = [[1×5+2×7, 1×6+2×8],   = [[19, 22],
      [3×5+4×7, 3×6+4×8]]      [43, 50]]
```

**Regla de compatibilidad:** la segunda dimensión de A debe igualar la primera
de B. `[m×k] × [k×n] → [m×n]`.

**Ejemplo de transformers:**
```
-- Entrada: 5 tokens, cada uno con embedding de dim 8
entrada = [5, 8]

-- Pesos de proyección: de dim 8 a dim 4
pesos = [8, 4]

-- Salida: 5 tokens, cada uno proyectado a dim 4
salida = producto_matricial(entrada, pesos)  -- forma: [5, 4]
```

---

## Por qué los tensores son la unidad de trabajo en IA

### Razón 1: representan datos naturalmente

Una oración de texto puede ser una matriz `[longitud, dim_embedding]` donde
cada fila es el vector numérico de un token. Una imagen RGB es un tensor 3D
`[alto, ancho, 3]` donde la tercera dimensión son los canales rojo/verde/azul.

### Razón 2: el hardware está diseñado para ellos

Las GPUs son procesadores masivamente paralelos optimizados para
multiplicaciones de matrices. Al representar datos como tensores,
el hardware puede procesar miles de elementos simultáneamente.

Zofía no corre en GPU (es educativo), pero la estructura matemática es la misma.

### Razón 3: el código queda limpio y expresivo

Con tensores, una capa de red neuronal completa se describe en una línea:

```
salida = activar(producto_matricial(entrada, pesos) + sesgo)
```

Sin tensores, necesitarías bucles anidados sobre cada elemento.

---

## Anatomía de un tensor en el contexto de un transformer

Al procesar la oración "El perro corre" en un transformer, los tensores serían:

```
Tokens:  ["El", "perro", "corre"]         -- 3 tokens
                ↓
Embeddings: forma [3, 512]                -- cada token → vector de 512 números
                ↓
+ Posición: forma [3, 512]                -- sumamos codificación posicional
                ↓
Atención: Q, K, V de forma [3, 512]       -- tres proyecciones de la entrada
                ↓
Puntuaciones: Q × Kᵀ → forma [3, 3]      -- similitud entre cada par de tokens
                ↓
Pesos de atención: softmax([3,3]) → [3,3] -- suma 1 por fila
                ↓
Salida: pesos × V → forma [3, 512]        -- representación enriquecida
```

Cada flecha es una operación tensorial. El módulo `tensor.zy` implementa
todas las primitivas necesarias para ejecutar estas transformaciones.

---

## Errores comunes de forma

Estos errores aparecerán durante la implementación. Conviene conocerlos:

| Error | Causa | Solución |
|-------|-------|----------|
| `producto_matricial([3,4], [3,4])` | k no coincide | Usar `[3,4] × [4,N]` |
| `sumar([3,4], [4,3])` | formas distintas | Verificar formas antes |
| `transponer([2,3,4])` | ¿qué dimensiones se intercambian? | Especificar ejes |
| Resultado con forma inesperada | Error de diseño de la red | Imprimir formas en cada paso |

**Práctica recomendada:** llamar `imprimir(forma_de(t))` después de cada
operación durante el desarrollo para confirmar que las formas son las esperadas.
