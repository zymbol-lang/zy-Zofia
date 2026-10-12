# Zofía — Inteligencia Artificial desde Cero en Zymbol

> Caso de estudio educativo · Escrito completamente en español · Para hispanohablantes  
> Proyecto driver de **Zymbol v0.0.6** — requiere intérprete `>= v0.0.6`  
> Sitio web: **[zymbol-lang.org/zofia](https://zymbol-lang.org/zofia)**

---

## ¿Qué es Zofía?

Zofía es la implementación desde cero de los bloques fundamentales de la
inteligencia artificial moderna, escrita completamente en **Zymbol** y
documentada en español para estudiantes y desarrolladores hispanohablantes.

No es un wrapper de PyTorch ni TensorFlow. Es la construcción manual, pieza
a pieza, de las mismas herramientas matemáticas que usan esos sistemas — para
que quien las construya entienda exactamente qué hace cada línea y por qué.

El nombre viene de Zofía Kowalewska — matemática del siglo XIX que dedicó su
vida a demostrar que las matemáticas pertenecen a todos, sin importar el origen.

---

## ¿Por qué construirlo desde cero?

Usar PyTorch o TensorFlow para aprender inteligencia artificial es como
aprender a cocinar en un restaurante con todo preparado. Funciona para
producir platos, pero no enseña a entender los ingredientes.

Construir las herramientas desde cero obliga a responder las preguntas que
las bibliotecas esconden:

- ¿Por qué un tensor? ¿Qué forma tiene y por qué importa?
- ¿Cómo sabe una red neuronal en qué dirección mejorar?
- ¿Qué significa exactamente "prestar atención" en un transformer?
- ¿Por qué dividimos por √dₖ en el mecanismo de atención?
- ¿Cómo aprende el encoder? ¿Cómo fluyen los gradientes hacia atrás?
- ¿Cómo genera texto un decoder, token a token?

Zofía responde cada una de esas preguntas con código que puedes leer,
modificar y entender completamente.

---

## ¿Para quién es?

- Desarrolladores hispanohablantes que quieren aprender IA desde las bases
- Estudiantes de ingeniería o matemáticas que prefieren aprender con código
- Personas que conocen los conceptos de IA "a 10.000 metros de altura"
  y quieren bajar al terreno
- Cualquiera que prefiera leer código en español

No se requieren conocimientos previos de IA. Se requiere saber programar y
tener disposición para trabajar con matemáticas básicas (álgebra, funciones).

---

## El camino de aprendizaje

```
Fundamentos matemáticos
        │
        ▼
    Tensores              ← representar datos en N dimensiones
        │
        ▼
 Gradientes y             ← cómo aprende una red
  optimización
        │
        ▼
  Redes neuronales        ← combinar lo anterior en una red real
        │
        ▼
Mecanismo de              ← el corazón del transformer
  atención
        │
        ▼
 Encoder Transformer      ← el modelo que cambió la IA moderna
        │
        ▼
 Retropropagación         ← cómo aprende el encoder
  en el encoder
        │
        ▼
 Clasificador de          ← aplicación real: análisis de sentimiento
  sentimiento
        │
        ▼
 Decoder y generación     ← transformer completo, generación de texto
```

Cada paso construye sobre el anterior. No hay saltos.

---

## Estructura del proyecto

```
Zofia/
  README.md              — Este archivo
  HOJA_DE_RUTA.md        — Fases de implementación con estado actual
  DISEÑO_API.md          — Contratos de todos los módulos Zymbol
  ROADMAP_IA.md          — Camino hacia inferencia de LLMs reales (Gemma, DeepSeek)
  HALLAZGOS.md           — BUGs, GAPs e IDEAs descubiertas durante la construcción
  docs/
    00_fundamentos_matematicos.md    — Álgebra lineal y cálculo esencial
    01_tensores.md                   — Qué es un tensor y por qué existe
    02_gradientes_y_optimizacion.md  — Cómo aprende un modelo
    03_redes_neuronales.md           — De la neurona al perceptrón multicapa
    04_mecanismo_de_atencion.md      — Scaled dot-product y multi-head attention
    05_arquitectura_transformer.md   — El encoder completo
    06_retropropagacion_encoder.md   — Gradientes a través del transformer
    07_clasificador_sentimiento.md   — Tarea real: clasificación de texto
    08_decoder_generacion.md         — Decoder, atención cruzada, generación
  modulos/
    tensor.zy            — FASE 1: operaciones tensoriales
    grad.zy              — FASE 2: variables con gradiente, SGD
    activacion.zy        — FASE 3: relu, sigmoid, tanh, softmax
    perdida.zy           — FASE 3: MSE, BCE, entropía cruzada
    atencion.zy          — FASE 4: scaled dot-product + multi-head attention
    transformador.zy     — FASE 5: encoder completo con PE y layer norm
    go9_datos.zy         — ESTUDIO GO: lectura del kifu v1 y partición por partida
  ejemplos/
    01_tensor_basico.zy
    02_producto_matricial.zy
    03_descenso_gradiente.zy
    04_red_simple.zy           — XOR con tanh+sigmoid, converge en <100 épocas
    05_atencion_simple.zy      — atención sobre 4 tokens, sumas = 1 por fila
    06_transformer_encoder.zy  — encoder 5 tokens × dim=4, 2 capas, 2 cabezas
    go9_exportar.zy            — exporta posiciones 9×9 de zy-GO a JSONL
  tests/
    un .zy y su .expected por módulo; los corre ZyQuality
  datos/
    go9/                 — dataset derivado del exportador, no se versiona
```

Lo que **aún no existe** y las fases 6–8 traerán: `modulos/grad_encoder.zy`,
`tokenizador.zy`, `embeddings.zy`, `clasificador.zy`, `checkpoint.zy`,
`decoder.zy`; `ejemplos/07_entrenar_encoder.zy`, `08_sentimiento.zy`,
`09_traducir.zy`; `datos/sentimiento.txt`, `datos/traduccion.txt`; y
`modelos/` para los pesos entrenados. `docs/06`–`08` describen esas fases
antes de construirlas, que es el orden que pide HOJA_DE_RUTA.md.

---

## Estado actual

| Fase | Módulo(s) | Ejemplo | Estado |
|------|-----------|---------|--------|
| 0 — Diseño | docs/ + HALLAZGOS.md | — | ✅ Completo |
| 1 — Tensor | `tensor.zy` | `01`, `02` | ✅ Completo |
| 2 — Gradiente | `grad.zy` | `03` | ✅ Completo |
| 3 — Activaciones + Pérdida | `activacion.zy`, `perdida.zy` | `04` | ✅ Completo |
| 4 — Atención | `atencion.zy` | `05` | ✅ Completo |
| 5 — Encoder transformer | `transformador.zy` | `06` | ✅ Completo |
| Estudio GO 9×9 — Datos | `go9_datos.zy` | `go9_exportar` | ✅ Exportador reproducible |
| 6 — Retropropagación | `grad_encoder.zy`, `checkpoint.zy` | `07` | 🔲 Pendiente |
| 7 — Clasificador | `tokenizador.zy`, `embeddings.zy`, `clasificador.zy` | `08` | 🔲 Pendiente |
| 8 — Decoder | `decoder.zy` | `09` | 🔲 Pendiente |

**Logros verificados (Fases 1–5):**
- Red XOR aprende en < 100 épocas (criterio era < 1000)
- Pesos de atención suman exactamente 1 por fila (propiedad del softmax)
- Encoder preserva dimensiones: 5 tokens × dim=4 entra y sale igual
- Máscara causal bloquea posiciones futuras correctamente

## Estudio GO 9×9

`ejemplos/go9_exportar.zy` transforma los kifu de `GO/games/` en JSONL para una
tarea de siguiente jugada — contrato **zofia-go9-v2**. Cada fila guarda el
tablero **antes** de la jugada, el color, el punto prohibido por ko, el objetivo
1–81 (82 = `pass`) y una partición `train`/`valid`/`test` determinista por
partida.

```bash
zymbol run --vm Zofia/ejemplos/go9_exportar.zy
# 361 partidas · 39.155 ejemplos · train 31.969 · valid 3.750 · test 3.436
```

Tres cosas que el contrato afirma, y una que no:

- **Las capturas se reconstruyen con el motor de GO.** El `caps` del kifu dice
  cuántas piedras salieron, nunca cuáles: escribir las coordenadas sobre un
  arreglo plano deja las piedras capturadas en el tablero e inventa posiciones
  que nadie jugó. Ver IDEA-Z010 en HALLAZGOS.md.
- **El ko va en cada fila.** No se deduce del tablero, y sin él hay 491
  posiciones donde una jugada aparentemente legal estaba prohibida.
- **Una partida se exporta entera o no se exporta.** Si una jugada no se puede
  reproducir, todo lo que la sigue sería una posición falsa; la partida se
  descarta y el contador lo dice.
- **Lo que no afirma:** el corpus son partidas de la IA heurística de zy-GO
  contra sí misma. Un modelo entrenado aquí imita esa heurística, no aprende
  go, y Zofía sigue sin tener un LLM.

`Zofia/datos/go9/movimientos.jsonl` es derivado y no se versiona. Tampoco se
versiona su materia prima: `GO/games/` está en el `.gitignore` de zy-GO, así que
reproducir el dataset exige generar antes las partidas con `zymbol run 棋戦.zy`
desde `GO/`. El siguiente paso es una cabeza clasificadora de 82 clases
entrenable sobre este contrato.

---

## Convenciones del proyecto

| Aspecto | Convención |
|---------|------------|
| Código Zymbol | Todo en español: variables, funciones, comentarios |
| Referencias técnicas | Término en inglés entre paréntesis al introducirlo |
| Fórmulas matemáticas | Notación estándar con explicación en español |
| Citas | Apellido, año, título en inglés (fuente original) |
| Nombres de archivos | snake_case en español |

---

## Versión de Zymbol

Zofía v1 (Fases 1–5) requiere **Zymbol v0.0.6** o superior.

| Característica v0.0.6 | Dónde se usa |
|-----------------------|--------------|
| `std/math` | `activacion.zy`, `atencion.zy`, `transformador.zy` |
| `std/random` | `04_red_simple.zy` — inicialización de pesos |
| `arr[i>j]$~ val` (deep update) | `tensor.zy` |
| `$~` en tuplas nombradas | `grad.zy` |
| Inferencia numérica polimórfica | Todos los módulos |
| `#.N\|x\|` formato decimal | Todos los ejemplos |

Zofía v2 (Fases 6–8) se beneficiará de **Zymbol v0.0.7** (`std/io` nativo
para reemplazar los BashExec de `lib/file.zy` y `lib/json.zy`).

El camino hacia inferencia de modelos pre-entrenados está en **[ROADMAP_IA.md](ROADMAP_IA.md)**.

---

## Referencias principales

- Vaswani et al. (2017) — *Attention Is All You Need*
- Goodfellow, Bengio, Courville (2016) — *Deep Learning*
- Nielsen (2015) — *Neural Networks and Deep Learning* (libro libre en línea)
- Ruder (2016) — *An Overview of Gradient Descent Optimization Algorithms*
- Ba et al. (2016) — *Layer Normalization*

---

Repositorio del intérprete: [github.com/zymbol-lang/interpreter](https://github.com/zymbol-lang/interpreter)  
Sitio web: [zymbol-lang.org](https://zymbol-lang.org)
