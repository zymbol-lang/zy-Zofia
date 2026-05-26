# Clasificador de Sentimiento con el Encoder

> Documento 07 — Prerequisito: 06_retropropagacion_encoder.md
> Este documento responde: ¿cómo se usa un encoder transformer para clasificar texto?
> ¿Qué es una "cabeza de tarea" y cómo se entrena?

---

## Del encoder al clasificador

El encoder transformer transforma una secuencia de vectores en otra secuencia
de vectores enriquecidos con contexto. Pero para clasificar texto (positivo/negativo,
spam/no-spam, etc.), necesitamos un **único número** como salida.

La solución estándar es agregar una **cabeza de clasificación** encima del encoder:

```
Texto de entrada
      ↓
[Tokenización]        -- texto → secuencia de índices
      ↓
[Tabla de embeddings] -- índices → vectores de dim_modelo
      ↓
[+ Codificación posicional]
      ↓
[Encoder (N bloques)] -- contextualiza cada token
      ↓
[Token [CLS] → x[1]] -- tomar solo el primer vector de salida
      ↓
[Capa lineal + softmax] -- proyectar a num_clases probabilidades
      ↓
Clase (positivo / negativo)
```

El token `[CLS]` (Classification) es un token especial al inicio de cada
secuencia cuyo vector de salida aprende a resumir el significado global del texto.
BERT popularizó este patrón — Zofía lo usa en su forma más simple.

---

## El dataset: oraciones en español

El dataset tiene 24 oraciones cortas etiquetadas manualmente, almacenadas en
`datos/sentimiento.txt` con el formato `oración|etiqueta`:

```
// Ejemplos positivos (etiqueta 1):
Me encanta esta película, es increíble|1
El servicio fue excelente y muy amable|1
Qué día tan hermoso y lleno de alegría|1

// Ejemplos negativos (etiqueta 0):
El producto llegó roto y tardó demasiado|0
Terrible experiencia, no lo recomiendo|0
Qué decepción tan grande, esperaba más|0
```

El dataset es pequeño a propósito — Zofía no busca precisión de producción
sino demostrar el flujo completo de entrenamiento.

---

## Tokenización a nivel de palabra

Para convertir texto en números, usamos tokenización a nivel de palabra:

```
"Me encanta esta película" → ["Me", "encanta", "esta", "película"]
                           → [3, 7, 12, 45]   -- índices en el vocabulario
```

El vocabulario se construye desde el dataset completo. Las palabras desconocidas
en producción reciben el índice especial `[UNK]`.

```zymbol
// Construir vocabulario desde el dataset
vocab = tok::construir_vocab(oraciones)

// Convertir oración a índices (con [CLS] al inicio)
ids = tok::encode(vocab, "[CLS] " + oracion)

// Convertir índices a embeddings (lookup en tabla)
embeds = emb::lookup(tabla_embeddings, ids)
```

---

## La cabeza de clasificación

Es simplemente una capa lineal que proyecta el vector del token `[CLS]` a
`num_clases` logits, seguida de softmax:

```
logits = x_cls · W_cls + b_cls      -- [1, num_clases]
probs  = softmax(logits)            -- probabilidades que suman 1
clase  = argmax(probs)              -- 0 (negativo) o 1 (positivo)
```

La pérdida es entropía cruzada entre `probs` y la etiqueta correcta — ya
implementada en `modulos/perdida.zy`.

---

## Estrategia de entrenamiento en dos fases

### Fase 7a — Cabeza de clasificación sola (pesos del encoder congelados)
Se entrena solo `W_cls` y `b_cls`. El encoder actúa como extractor de
características fijo. Esto converge rápido y establece una línea base.

```
Ventaja: simple, rápido, no necesita grad_encoder.zy
Límite:  el encoder no se adapta a la tarea de sentimiento
```

### Fase 7b — Fine-tuning conjunto (todos los pesos)
Se activan los gradientes del encoder y se entrena todo junto con una tasa
de aprendizaje más pequeña. El encoder aprende representaciones específicas
para sentimiento.

```
Ventaja: mejor rendimiento, el encoder se especializa
Límite:  más complejo, necesita grad_encoder.zy completo
```

Zofía implementa la Fase 7a primero. La Fase 7b es el paso natural siguiente.

---

## Métricas de evaluación

```
exactitud = predicciones_correctas / total_ejemplos

// Matriz de confusión (para un clasificador binario):
             Predicho 0   Predicho 1
Real 0     [  VN        FP  ]    -- Verdadero Negativo / Falso Positivo
Real 1     [  FN        VP  ]    -- Falso Negativo / Verdadero Positivo

precision = VP / (VP + FP)   -- de los que digo positivo, ¿cuántos lo son?
recobrado = VP / (VP + FN)   -- de los positivos reales, ¿cuántos encontré?
```

---

## Lo que implementa `clasificador.zy`

```
// Tokenizador de nivel de palabra
modulos/tokenizador.zy:
  construir_vocab(oraciones)        → vocab (lista de palabras únicas)
  encode(vocab, texto)              → lista de índices
  decode(vocab, ids)                → texto reconstruido

// Tabla de embeddings (lookup)
modulos/embeddings.zy:
  crear_tabla(tam_vocab, dim)       → tabla aleatoria [tam_vocab × dim]
  lookup(tabla, ids)                → matriz [len(ids) × dim]
  grad_lookup(dY, ids, tam_vocab)   → grad respecto a la tabla

// Cabeza de clasificación
modulos/clasificador.zy:
  cabeza_clasificacion(x_cls, W, b) → logits
  predecir(logits)                  → clase (0 o 1)
  exactitud(preds, ys)              → escalar en [0, 1]
```

**Ejemplo:** `08_sentimiento.zy` — entrena clasificador sobre 24 oraciones.
Criterio de aceptación: exactitud ≥ 80% en el conjunto de entrenamiento.
Al terminar, guarda el modelo en `modelos/sentimiento.json`.

---

## Conexión con el roadmap de Zymbol

Este ejemplo es el primero en Zofía que usa **todas las capas del stack**:

```
std/random     → inicialización de pesos
std/math       → funciones de activación
modulos/       → todas las Fases 1–7
lib/file.zy    → leer datos, guardar modelo
lib/json.zy    → serializar pesos como JSON
```

Y es el punto de validación antes de añadir el decoder: si el encoder
aprendió representaciones útiles para clasificar sentimiento, el mismo
encoder debería funcionar bien como parte del codificador en un
transformer de traducción (Fase 8).
