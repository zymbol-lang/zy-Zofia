# Decoder y Generación de Texto

> Documento 08 — Prerequisito: 06_retropropagacion_encoder.md, 07_clasificador_sentimiento.md
> Este documento responde: ¿cómo genera texto un transformer? ¿Qué agrega el decoder
> al encoder que ya construimos?

---

## El transformer completo

Zofía v1 construyó solo el encoder. El transformer original de Vaswani (2017)
tiene dos partes simétricas:

```
CODIFICADOR                       DECODIFICADOR
(entiende la entrada)             (genera la salida)

Texto fuente (español)            Texto generado hasta ahora
      ↓                                   ↓
[Embed + PE]                      [Embed + PE]
      ↓                                   ↓
[Bloque Codificador × N]          [Auto-atención enmascarada]
      ↓                                   ↓
  Representación              [Atención cruzada ← representación]
  contextual ──────────────────────────────┘
                                           ↓
                                    [FAD + Norma]
                                           ↓
                                    [Capa lineal → vocab]
                                           ↓
                                    Siguiente token
```

La diferencia clave: el decoder tiene **tres sub-capas** en lugar de dos,
y la del medio es nueva — la **atención cruzada**.

---

## La atención cruzada (cross-attention)

En el encoder, la auto-atención hace que cada token atienda a todos los demás
tokens de la **misma** secuencia.

En el decoder, la atención cruzada hace que cada token generado atienda a
todos los tokens de la secuencia del **encoder** (el texto fuente):

```
// Auto-atención del decoder (enmascarada):
Q_dec = x_dec · W_Q         -- consultas: del token actual
K_dec = x_dec · W_K         -- claves: de la secuencia generada hasta ahora
V_dec = x_dec · W_V
salida_1 = atencion_enmascarada(Q_dec, K_dec, V_dec, mascara_causal)

// Atención cruzada:
Q_cruzada = salida_1 · W_Q_cruzada    -- consultas: del decoder
K_cruzada = enc_salida · W_K_cruzada  -- claves: del encoder (texto fuente)
V_cruzada = enc_salida · W_V_cruzada  -- valores: del encoder
salida_2  = atencion_producto_punto(Q_cruzada, K_cruzada, V_cruzada)
```

La pregunta que responde la atención cruzada: "para generar el siguiente token
en español, ¿en qué parte del texto de entrada en español debo fijarme?"

---

## Generación autoregresiva

La generación de texto no sucede de golpe — se genera **un token a la vez**:

```
Entrada del encoder:  "el gato duerme"

Paso 1: decoder recibe [CLS] → genera "the"
Paso 2: decoder recibe [CLS, "the"] → genera "cat"
Paso 3: decoder recibe [CLS, "the", "cat"] → genera "sleeps"
Paso 4: decoder recibe [CLS, "the", "cat", "sleeps"] → genera [EOS]
```

En cada paso, el decoder ve todos los tokens que ya generó (gracias a la
auto-atención enmascarada) y consulta al encoder (gracias a la atención cruzada).

La máscara causal garantiza que al generar el token en posición `t`, el decoder
no pueda "ver" los tokens en posiciones `t+1, t+2, ...` — esto hace posible
el entrenamiento paralelo.

---

## Selección del siguiente token: temperatura y muestreo

Dado los logits del último token, ¿cómo elegir el siguiente?

### Greedy (codicioso)
```
siguiente_token = argmax(logits)
```
Siempre elige el token más probable. Determinístico pero repetitivo.

### Temperatura
```
logits_escalados = logits / temperatura
probs = softmax(logits_escalados)
siguiente_token = muestreo_categorico(probs)
```
- `temperatura = 1.0` → distribución original
- `temperatura < 1.0` → más determinístico (sharper)
- `temperatura > 1.0` → más aleatorio (flatter)

### Top-k
```
// Conservar solo los k tokens más probables, renormalizar
top_k_logits = top_k(logits, k=10)
probs = softmax(top_k_logits)
```

Zofía implementa greedy y temperatura. Top-k es una mejora opcional.

---

## El bloque decodificador

```zymbol
bloque_decoder(x_dec, enc_salida, config_dec) {
    // Sub-capa 1: auto-atención enmascarada
    aten_1  = _atn::atencion_enmascarada(x_dec, x_dec, x_dec, mascara_causal)
    norm_1  = normalizar_capa(_ten::sumar(x_dec, aten_1), config_dec.gamma_1, config_dec.beta_1)

    // Sub-capa 2: atención cruzada (consulta al encoder)
    aten_2  = _atn::atencion_producto_punto(norm_1, enc_salida, enc_salida)
    norm_2  = normalizar_capa(_ten::sumar(norm_1, aten_2), config_dec.gamma_2, config_dec.beta_2)

    // Sub-capa 3: red feed-forward
    ff_sal  = capa_feed_adelante(norm_2, config_dec.pesos_ff1, config_dec.sesgo_ff1,
                                          config_dec.pesos_ff2, config_dec.sesgo_ff2)
    <~ normalizar_capa(_ten::sumar(norm_2, ff_sal), config_dec.gamma_3, config_dec.beta_3)
}
```

La atención cruzada aquí usa `norm_1` como Q (consulta del decoder) y
`enc_salida` como K y V (claves y valores del encoder). Es exactamente
la misma función `atencion_producto_punto` ya implementada — solo cambian
de dónde vienen Q, K y V.

---

## El tokenizador y el vocabulario

Para generación de texto necesitamos:
1. Convertir texto → índices (encode)
2. Convertir índices → texto (decode)
3. Una tabla de embeddings (índice → vector de dim_modelo)

```zymbol
// modulos/tokenizador.zy
construir_vocab(corpus)       → vocab
encode(vocab, texto)          → lista de índices
decode(vocab, ids)            → texto

// Con tokens especiales:
[CLS]  = 0   -- inicio de secuencia (clasificador)
[EOS]  = 1   -- fin de secuencia
[PAD]  = 2   -- relleno para lotes de longitud uniforme
[UNK]  = 3   -- palabra desconocida
```

Zofía usa tokenización a nivel de palabra — un índice por palabra.
Para el dataset de traducción (10 pares cortos), el vocabulario tiene
~50 palabras únicas. Suficiente para demostrar el concepto.

---

## Lo que implementa `decoder.zy`

```
// modulos/decoder.zy
_mascara_causal(n) → matriz [n×n] triangular inferior de booleanos
bloque_decoder(x_dec, enc_salida, config_dec) → matriz
decoder(secuencia, enc_salida, configs_dec)   → matriz
proyectar_vocab(x, pesos_vocab)               → logits [seq × tam_vocab]
generar(encoder_salida, max_tokens, config_dec, vocab, temperatura) → texto
```

**Ejemplo:** `09_traducir.zy` — 10 pares de frases muy cortas (5–8 palabras),
entrenamiento de traducción español → inglés simplificado.

Criterio de aceptación: el modelo genera la secuencia correcta (o muy cercana)
en al menos 7 de 10 pares después de entrenamiento.

---

## Conexión con la Fase 9: hacia pesos pre-entrenados

El transformer completo (encoder + decoder) de Zofía es arquitectónicamente
idéntico al de modelos como T5 (Google) o BART (Meta), solo que en miniatura.

La brecha hasta usar pesos reales requiere tres capacidades de Zymbol
que aún no existen:

| Capacidad | Versión Zymbol | Qué desbloquea |
|-----------|----------------|----------------|
| Tipo Tensor nativo (Vec<f32>) | v0.0.8 | Velocidad 100× — modelos de 125M parámetros |
| Lectura de safetensors | v0.0.9 | Cargar pesos de HuggingFace directamente |
| Tokenizador BPE nativo | v0.1.0 | Vocabularios de 30k–256k tokens |

Cuando esas tres capacidades existan, `09_traducir.zy` se convierte en
`10_gemma_chat.zy` — la misma arquitectura, pesos reales, vocabulario real.

Zofía es el mapa. El roadmap de Zymbol es el camino.
