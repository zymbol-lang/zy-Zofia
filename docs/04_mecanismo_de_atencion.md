# Mecanismo de Atención

> Documento 04 — Prerequisito: 01_tensores.md, 03_redes_neuronales.md
> Este documento responde: ¿qué es exactamente "prestar atención" en un transformer?

---

## La intuición: leer con contexto

Cuando lees la oración:

> "El banco estaba lleno porque la gente quería sacar dinero"

¿Qué significa "banco"? Para saberlo, tu cerebro presta atención a otras palabras
de la oración: "dinero", "gente", "sacar". Esas palabras indican que es un banco
financiero, no un banco de plaza.

El mecanismo de atención hace exactamente eso: para cada posición en una secuencia,
calcula cuánta importancia darle a cada otra posición al construir su representación.

---

## Los tres actores: Consulta, Clave, Valor

La atención se modela con tres matrices derivadas de la entrada:

```
Q — Consulta (Query):  "¿qué estoy buscando?"
K — Clave   (Key):    "¿qué información ofrezco?"
V — Valor   (Value):  "¿qué información entrego si me consultan?"
```

La analogía con un buscador:
- Escribes una **consulta** (query): "banco financiero"
- El buscador compara tu consulta con las **claves** (keys) de cada documento
- Los documentos más relevantes (alta similitud consulta-clave) entregan sus **valores**

En la práctica, Q, K y V son proyecciones lineales de la misma entrada:

```
Q = entrada × W_Q    -- W_Q es una matriz de pesos aprendible
K = entrada × W_K
V = entrada × W_V
```

Los pesos W_Q, W_K, W_V se aprenden durante el entrenamiento. La red aprende
qué tipo de "preguntas", "claves" y "valores" son útiles para la tarea.

---

## Scaled Dot-Product Attention

La fórmula central (Vaswani et al., 2017, Ecuación 1):

```
Attention(Q, K, V) = softmax( Q × Kᵀ / √dₖ ) × V
```

Desglosemos cada parte:

### Paso 1: Puntuaciones de similitud — Q × Kᵀ

```
Q = [[q₁₁, q₁₂],    -- consultas: cada fila es una posición en la secuencia
     [q₂₁, q₂₂],
     [q₃₁, q₃₂]]

K = [[k₁₁, k₁₂],    -- claves: misma forma que Q
     [k₂₁, k₂₂],
     [k₃₁, k₃₂]]

Q × Kᵀ →  forma [3, 3]   -- puntuación de cada par (posición_i, posición_j)
```

El elemento `(i, j)` del resultado es el producto punto entre la consulta de
la posición `i` y la clave de la posición `j` — cuán similar es lo que busca
`i` con lo que ofrece `j`.

**Ejemplo con 3 tokens ["El", "banco", "deposita"]:**
```
                  El    banco  deposita
       El       [0.8,   0.3,    0.1]    -- "El" presta más atención a "El"
       banco    [0.1,   0.9,    0.4]    -- "banco" presta más atención a sí mismo
       deposita [0.2,   0.7,    0.6]    -- "deposita" presta más atención a "banco"
```

---

### Paso 2: Escalar por √dₖ

```
puntuaciones / √dₖ
```

`dₖ` es la dimensión de las claves (número de columnas de K).

**¿Por qué dividir por √dₖ?**
Cuando `dₖ` es grande, el producto punto tiende a producir valores muy grandes
(porque estamos sumando muchos términos). Valores grandes entran al softmax y
producen distribuciones muy "afiladas" — casi todo el peso en una posición y
cero en las demás. Eso hace que los gradientes desaparezcan y el entrenamiento
se estanque.

Dividir por `√dₖ` mantiene las puntuaciones en un rango donde el softmax
produce distribuciones suaves y los gradientes fluyen bien.

---

### Paso 3: Softmax — convertir en pesos de atención

```
pesos_atencion = softmax(puntuaciones / √dₖ)
```

Para cada fila (cada posición de la secuencia), el softmax convierte las
puntuaciones en probabilidades que suman 1:

```
antes:  [0.8, 0.3, 0.1]  -- puntuaciones crudas
después: [0.57, 0.29, 0.14]  -- pesos que suman 1
```

Estos pesos indican cuánta atención pone la posición `i` en cada posición `j`
al construir su nueva representación.

---

### Paso 4: Suma ponderada de valores — × V

```
salida = pesos_atencion × V
```

Para cada posición, se suman los vectores de valor ponderados por los pesos
de atención. El resultado es una nueva representación enriquecida con contexto:

```
salida[i] = Σⱼ pesos_atencion[i,j] × V[j]
```

La posición "banco" en el ejemplo: si da peso alto a "deposita" y "dinero",
su nuevo vector incorpora esa información → la representación de "banco" ahora
codifica que es financiero.

---

## La fórmula completa visualizada

```
    Q [seq, dk]    K [seq, dk]
         │               │
         └───────┬────────┘
                 │
          Q × Kᵀ [seq, seq]
                 │
          ÷ √dₖ  │
                 │
           softmax [seq, seq]   ← "pesos de atención"
                 │
                 │         V [seq, dv]
                 └──────────────┤
                                │
                         × V   [seq, dv]   ← salida
```

---

## Atención enmascarada (masked attention)

En el decoder del transformer (no en Zofía v1, pero importante conocerlo),
al generar una palabra en la posición `t`, no se puede "ver" las palabras
en posiciones `t+1, t+2, ...` (aún no existen).

Se aplica una máscara que pone `-∞` en las posiciones futuras antes del softmax:

```
puntuaciones_enmascaradas[i, j] = puntuacion[i, j]  si j ≤ i
                                  -∞                 si j > i
```

`softmax(-∞) = 0`, así que esas posiciones reciben peso cero → no se ven.

---

## Atención Multi-Cabeza (Multi-Head Attention)

El problema con una sola atención: solo captura un tipo de relación a la vez.
La solución: ejecutar la atención múltiples veces en paralelo, con proyecciones
diferentes → cada "cabeza" aprende a atender relaciones distintas.

```
Cabeza_i = Attention(Q × W_Qᵢ, K × W_Kᵢ, V × W_Vᵢ)

MultiHead(Q,K,V) = Concat(Cabeza₁, Cabeza₂, ..., Cabezaₕ) × W_O
```

Donde `h` es el número de cabezas y `W_O` es una proyección de salida que
combina lo que aprendió cada cabeza.

**Dimensiones en práctica:**
- Si `dim_modelo = 512` y `num_cabezas = 8`:
- Cada cabeza trabaja con `dₖ = dᵥ = 512/8 = 64`
- El costo computacional es el mismo que una atención de dimensión completa
  (las operaciones son más pequeñas pero hay 8 de ellas en paralelo)

**Analogía:** es como leer el mismo texto con 8 preguntas distintas en mente.
Una cabeza puede aprender relaciones sintácticas, otra semánticas, otra
correferencias, etc. La red decide qué aprende cada cabeza durante el entrenamiento.

---

## ¿Por qué la atención supera a las RNNs?

Antes del transformer, las redes recurrentes (RNN, LSTM) procesaban secuencias
token por token, manteniendo un "estado oculto" que debía comprimir todo el
contexto pasado en un vector fijo.

Problemas:
- El contexto lejano se "olvida" (la información de los primeros tokens se diluye)
- No se pueden paralelizar (el token 5 necesita el estado de los tokens 1-4)

La atención resuelve ambos:
- Acceso directo a cualquier posición, sin importar la distancia
- Todas las posiciones se procesan simultáneamente → paralelizable

Esta es la razón por la que "Attention Is All You Need" (Vaswani et al., 2017)
cambió el campo de la IA.

---

## Lo que implementa `atencion.zy`

El módulo está completamente implementado en Zymbol. Extracto del código real:

```zymbol
atencion_producto_punto(Q, K, V) {
    // Atención(Q,K,V) = softmax(Q·Kᵀ / √dₖ) · V
    // Fuente: Vaswani et al. (2017), Ecuación 1
    dk     = K[1]$#
    escala = 1.0 / _mat::sqrt(##.(dk))
    Kt     = _ten::transponer(K)
    puntos = _ten::multiplicar_escalar(_ten::producto_matricial(Q, Kt), escala)
    pesos  = _softmax_filas(puntos)
    <~ _ten::producto_matricial(pesos, V)
}

atencion_multiencabezado(Q, K, V, config) {
    // Divide Q/K/V en columnas, aplica atención por cabeza, concatena y proyecta
    dim_cab = config.dim_modelo / config.num_cabezas
    Q_full  = _ten::producto_matricial(Q, config.pesos_q)
    // ... (ver modulos/atencion.zy para el código completo)
    <~ _ten::producto_matricial(concat, config.pesos_o)
}
```

**Verificación del criterio (Fase 4):**
El ejemplo `05_atencion_simple.zy` ejecuta atención sobre una secuencia de
4 tokens con embeddings de dimensión 4 y 2 cabezas. Con V = identidad, las
filas de la salida son exactamente los pesos de atención — todas suman 1.0:

```
Suma fila 1: 1    Suma fila 2: 1    Suma fila 3: 1    Suma fila 4: 1
```

La máscara causal también se verifica: el token 1 solo se atiende a sí mismo
y su salida es exactamente `[1, 0, 0, 0]` = V[1] (primera fila de la identidad).
