# Arquitectura Transformer

> Documento 05 — Prerequisito: todos los documentos anteriores (00 al 04)
> Este documento ensambla todos los bloques en el modelo completo.
> Referencia principal: Vaswani et al. (2017), "Attention Is All You Need"

---

## Visión general

El transformer original tiene dos partes:

```
ENCODER                          DECODER
(entiende la entrada)            (genera la salida)

Texto fuente                     Texto generado hasta ahora
     │                                    │
[Embedding + Posición]           [Embedding + Posición]
     │                                    │
[Bloque Encoder × N]             [Bloque Decoder × N]
     │                                    │
  Representación                       Salida
  contextual
```

**Zofía implementa solo el encoder.** El encoder es suficiente para:
- Clasificación de texto
- Extracción de características
- Entender los conceptos fundamentales del transformer

El decoder agrega complejidad (atención enmascarada cruzada) sin añadir
conceptos nuevos necesarios para el aprendizaje fundamental.

---

## El embedding: convertir tokens en vectores

Antes de procesar texto, cada token (palabra o subpalabra) debe convertirse
en un vector numérico — su **embedding**.

```
"El"       →  [0.12, -0.45, 0.78, ...]    -- 512 números
"banco"    →  [-0.33, 0.91, 0.05, ...]   -- 512 números
"deposita" →  [0.67, 0.23, -0.88, ...]   -- 512 números
```

Los embeddings se aprenden durante el entrenamiento. Palabras con significados
similares tienden a tener vectores similares (cercanos en el espacio de 512 dimensiones).

En Zofía, los embeddings son una **tabla de consulta** (lookup table):
una matriz de forma `[tamaño_vocabulario, dim_modelo]`. Dado el índice de un
token, su embedding es la fila correspondiente de esa matriz.

---

## Codificación posicional (positional encoding)

El mecanismo de atención no tiene noción de orden — "El banco" y "banco El"
producirían los mismos pesos de atención. Para que el modelo sepa la posición
de cada token, se suma un vector de posición al embedding.

La codificación posicional de Vaswani usa funciones seno y coseno:

```
PE(pos, 2i)   = sin(pos / 10000^(2i / dim_modelo))
PE(pos, 2i+1) = cos(pos / 10000^(2i / dim_modelo))
```

Donde:
- `pos` es la posición del token en la secuencia (0, 1, 2, ...)
- `i` es el índice de la dimensión (0, 1, 2, ..., dim_modelo/2 - 1)
- Las posiciones pares usan seno, las impares usan coseno

**¿Por qué funciona?**
Cada posición obtiene un "código" único en el espacio de alta dimensión.
Las posiciones cercanas tienen códigos similares. La red puede aprender a
extraer información posicional de estas señales.

**Ejemplo para dim_modelo=4:**
```
Posición 0: [sin(0/1), cos(0/1), sin(0/100), cos(0/100)]
           = [0.0, 1.0, 0.0, 1.0]

Posición 1: [sin(1/1), cos(1/1), sin(1/100), cos(1/100)]
           = [0.84, 0.54, 0.01, 1.0]

Posición 2: [sin(2/1), cos(2/1), sin(2/100), cos(2/100)]
           = [0.91, -0.42, 0.02, 1.0]
```

La entrada al encoder es: `embedding + codificacion_posicional`

---

## Normalización de capa (layer normalization)

Antes de describir el bloque encoder, necesitamos entender la normalización de capa.

La idea: normalizar los valores de cada vector de la secuencia para que tengan
media 0 y varianza 1. Esto estabiliza el entrenamiento.

```
LayerNorm(x) = γ × (x - μ) / √(σ² + ε) + β
```

Donde:
- `μ` = media de los elementos de x
- `σ²` = varianza de los elementos de x
- `ε` = número muy pequeño (10⁻⁶) para evitar división por cero
- `γ, β` = parámetros aprendibles (escala y desplazamiento)

**Diferencia con Batch Normalization:**
Batch normalization normaliza a través del lote (entre ejemplos).
Layer normalization normaliza dentro de un solo ejemplo (entre dimensiones).
Para secuencias de longitud variable, layer norm funciona mejor.

---

## El bloque encoder

Un bloque encoder es la unidad que se repite N veces:

```
entrada x
    │
    ├──────────────────────┐
    │                      │
[Multi-Head Attention]     │  (conexión residual)
    │                      │
    └──────────────────────┤
                           │
                        [ + ]  ← suma residual
                           │
                   [Layer Norm]
                           │
    ┌──────────────────────┤
    │                      │
[Feed-Forward Network]     │  (conexión residual)
    │                      │
    └──────────────────────┤
                           │
                        [ + ]  ← suma residual
                           │
                   [Layer Norm]
                           │
                        salida x'
```

### Conexiones residuales (residual connections)

Cada sublayer suma su entrada a su propia salida:

```
salida = LayerNorm(x + Sublayer(x))
```

**¿Por qué?** Permiten que los gradientes fluyan directamente a través de capas
profundas sin desvanecerse. He et al. (2016, ResNet) demostraron que estas
conexiones permiten entrenar redes mucho más profundas.

Sin residuales, el gradiente se multiplicaría repetidamente por números pequeños
al retropropagar por 12 capas → se volvería casi cero → los pesos de las primeras
capas no aprenderían.

---

### La capa feed-forward (FFN)

La red feed-forward dentro de cada bloque encoder:

```
FFN(x) = ReLU(x × W₁ + b₁) × W₂ + b₂
```

- `W₁`: expansión de `dim_modelo` a `dim_ff` (típicamente `dim_ff = 4 × dim_modelo`)
- `W₂`: contracción de `dim_ff` de vuelta a `dim_modelo`

**¿Para qué sirve?**
La atención combina información entre posiciones (relaciones entre tokens).
La FFN procesa cada posición de forma independiente con más capacidad expresiva.
Son roles complementarios: la atención integra contexto, la FFN lo transforma.

---

## Apilando N bloques

El encoder completo aplica el mismo bloque N veces en secuencia:

```
x₀ = embedding + codificacion_posicional
x₁ = bloque_encoder(x₀)
x₂ = bloque_encoder(x₁)
...
xₙ = bloque_encoder(x_{N-1})
```

En el paper original: N=6, dim_modelo=512, num_cabezas=8, dim_ff=2048.

Cada capa puede capturar patrones de diferente nivel de abstracción:
- Capas tempranas: relaciones locales y sintácticas
- Capas profundas: relaciones semánticas y de largo alcance

---

## Resumen de hiperparámetros del encoder

| Hiperparámetro | Símbolo | Original | Zofía (mínimo) |
|----------------|---------|----------|-----------------|
| Dimensión del modelo | dim_modelo | 512 | 4 |
| Número de cabezas | num_cabezas | 8 | 2 |
| Capas del encoder | num_capas | 6 | 2 |
| Dimensión feed-forward | dim_ff | 2048 | 8 |
| Longitud máx. secuencia | max_seq | 512 | 5 |

Zofía usa valores mínimos para que los ejemplos sean ejecutables sin hardware
especializado y los tensores sean inspeccionables visualmente. El ejemplo
`06_transformer_encoder.zy` usa exactamente estos valores mínimos.

---

## Flujo completo con una oración

Procesando ["El", "banco", "deposita", "allí", "dinero"] con dim_modelo=4, 2 cabezas, 2 capas
(valores del ejemplo `06_transformer_encoder.zy`):

```
1. Tokens → embeddings manuales:
   → matriz [5, 4]   (5 tokens, embedding dim=4)

2. + Codificación posicional sinusoidal:
   → matriz [5, 4]   (misma forma, información de posición añadida)

3. CAPA 1 del codificador:
   a. Q = entrada × W_Q [4×4] → [5, 4]
      K = entrada × W_K [4×4] → [5, 4]
      V = entrada × W_V [4×4] → [5, 4]
   b. Atención multi-cabeza (2 cabezas de dim 2 cada una) → [5, 4]
   c. + residual → [5, 4]   + LayerNorm(γ₁, β₁) → [5, 4]
   d. FAD: [5,4] → [5,8] → [5,4]   (ReLU en la capa oculta)
   e. + residual → [5, 4]   + LayerNorm(γ₂, β₂) → [5, 4]

4. CAPA 2 del codificador:
   (igual que capa 1, con pesos distintos) → [5, 4]

5. Salida final: matriz [5, 4]
   → representación contextual de cada token
   → cada fila tiene la misma dimensión que la entrada: encoder preserva forma
```

**Verificación del criterio (Fase 5):**
```
Tokens entrada: 5   dim_modelo: 4
Tokens salida:  5   dim salida:  4
✓ Número de tokens preservado (5)
✓ Dimensión del modelo preservada (4)
```

---

## ¿Qué hace el modelo después del encoder?

El encoder produce una representación contextual de la secuencia. Para usarla
en una tarea concreta, se agrega una "cabeza de tarea" encima:

- **Clasificación:** tomar el vector del primer token → capa lineal → softmax
- **Etiquetado:** capa lineal sobre cada token → softmax
- **Generación:** pasar la representación al decoder

Zofía no implementa la cabeza de tarea (está fuera del alcance v1), pero el
encoder produce una salida lista para conectar a cualquiera de ellas.

---

## Lo que implementa `transformador.zy`

El módulo está completamente implementado en Zymbol. Estructura del código real:

```zymbol
codificacion_posicional(pos, dim_modelo) {
    // PE(pos, 2i) = sin(pos / 10000^(2i/dm)), PE(pos, 2i+1) = cos(...)
    pe = []
    @ i:1..dim_modelo {
        par     = (i - 1) / 2
        expo    = ##.(2 * par) / ##.(dim_modelo)
        divisor = _mat::pow(10000.0, expo)
        angulo  = ##.(pos) / divisor
        ? ((i % 2) == 1) { pe = pe$+ _mat::sin(angulo) }
        _ {                 pe = pe$+ _mat::cos(angulo) }
    }
    <~ pe
}

bloque_codificador(x, config) {
    // Sub-capa 1: auto-atención + residual + normalización
    aten_sal = _atn::atencion_multiencabezado(x, x, x, config)
    norm_1   = normalizar_capa(_ten::sumar(x, aten_sal), config.gamma_1, config.beta_1)
    // Sub-capa 2: FAD + residual + normalización
    ff_sal   = capa_feed_adelante(norm_1, config.pesos_ff1, config.sesgo_ff1,
                                  config.pesos_ff2, config.sesgo_ff2)
    <~ normalizar_capa(_ten::sumar(norm_1, ff_sal), config.gamma_2, config.beta_2)
}

codificador(secuencia, configs) {
    x = secuencia
    @ cfg:configs { x = bloque_codificador(x, cfg) }
    <~ x
}
```

**Nota de implementación — scope de funciones auxiliares:**
Las funciones auxiliares del ejemplo (`_ceros`, `_unos`, `_identidad`) reciben
las dimensiones como parámetros (`dm`, `nh`, `dff`) en lugar de leer variables
del script. Esto es necesario porque en Zymbol las funciones definidas dentro
de un script no tienen acceso a las variables mutables del scope exterior —
solo a constantes (`:=`) y a sus propios parámetros.

---

## El porqué del transformer como caso de estudio

El transformer es el caso de estudio perfecto para Zofía porque:

1. **Es la arquitectura dominante actual:** GPT, BERT, LLaMA, todos son transformers
2. **Está construido con bloques comprensibles:** álgebra lineal + softmax + residuales
3. **El paper original tiene 15 páginas:** accesible, no misterioso
4. **Escalar o reducir es trivial:** con N=2 capas y dim=8 se ven los mismos conceptos

El objetivo de Zofía no es entrenar un LLM. Es entender, desde adentro, por qué
el transformer funciona — para que al usar esos modelos grandes, no sean cajas negras.
