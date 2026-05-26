# Roadmap — Zymbol hacia Inferencia de LLMs

> Este documento traza el camino desde Zofía (transformer educativo desde cero)
> hasta la carga y ejecución de modelos pre-entrenados reales (Gemma, DeepSeek).
> Cada fase de Zofía valida las capacidades de Zymbol necesarias para la siguiente
> versión del intérprete.

---

## El cuello de botella actual

Zymbol puede construir y entrenar un transformer completo (demostrado en Zofía).
El obstáculo para modelos reales es **uno solo**: los tensores son listas de listas
en el heap, con acceso O(n). Un modelo de 125M parámetros necesita millones de
accesos por segundo — imposible con la representación actual.

La solución no cambia el lenguaje visible. Cambia lo que hay debajo.

---

## v0.0.7 — Fundamentos de I/O

| Característica | Para qué sirve en IA |
|----------------|----------------------|
| `std/io`: leer/escribir archivos de texto | Cargar datasets, guardar pesos |
| `std/io`: leer archivos binarios (bytes) | Prerequisito para formatos de modelo |
| String: split, join, buscar, reemplazar | Tokenización, preprocesamiento |
| `std/http` básico: GET/POST | Llamar APIs de modelos (Gemini, DeepSeek) |

**Zofía beneficiada:** `lib/file.zy` y `lib/json.zy` dejarían de necesitar BashExec.

---

## v0.0.8 — Tipo Tensor nativo ← el cambio más importante

Un nuevo tipo primitivo `Value::Tensor` respaldado por `Vec<f32>` en Rust:

```zymbol
// La sintaxis es compatible con hoy — solo rinde 100× más
t = #ten([5, 4], 0.0)        // Vec<f32> plano, acceso O(1)
t[2>3]                       // índice calculado como i*cols + j
ten::matmul(A, B)            // BLAS nativo (faer o nalgebra)
```

| Operación | Hoy (listas) | v0.0.8 (Tensor nativo) |
|-----------|-------------|------------------------|
| matmul [64×64] | ~100ms | ~0.1ms |
| matmul [512×512] | inviable | ~5ms |
| matmul [4096×4096] | inviable | ~200ms |

Con esto un modelo GPT-2 small (125M parámetros) sería ejecutable.

`std/tensor` exportaría: `matmul`, `transpose`, `softmax`, `relu`, `layernorm`,
`add`, `mul_scalar`, `reshape`, `slice`, `cat`.

---

## v0.0.9 — Precisión numérica y formatos de modelo

| Característica | Detalle |
|----------------|---------|
| `##;` — tipo float16 | Modelos en f16/bf16 usan la mitad de memoria |
| `std/safetensors` | Lector del formato estándar de HuggingFace |
| `std/gguf` | Formato de llama.cpp — más común para distribución |
| Cuantización int8 | Reducir modelos de 16GB a 8GB en memoria |

```zymbol
<# std/safetensors => sf

pesos = sf::cargar("gemma-2b.safetensors")
W_q   = pesos["model.layers.0.self_attn.q_proj.weight"]
```

**Zofía beneficiada:** `09_traducir.zy` puede cargar pesos T5-small (60MB) reales.

---

## v0.1.0 — Tokenizador nativo

| Característica | Detalle |
|----------------|---------|
| `std/tokenizer` | BPE (Byte Pair Encoding) — algoritmo de GPT/Gemma/DeepSeek |
| Lectura de `tokenizer.json` | Formato estándar de HuggingFace |
| Encode/decode | `tok::encode("hola mundo")` → `[15339, 28459]` |
| Vocabularios hasta 256k tokens | Gemma usa 256k, DeepSeek 100k |

```zymbol
<# std/tokenizer => tok

modelo_tok = tok::cargar("tokenizer.json")
ids         = tok::encode(modelo_tok, "¿Qué es un transformer?")
texto       = tok::decode(modelo_tok, ids)
```

---

## v0.2.0 — Módulo `std/nn` con capas nativas

Las operaciones de red neuronal como instrucciones bytecode del VM:

```zymbol
<# std/nn => nn

// Instrucciones nativas — velocidad equivalente a C
salida = nn::atencion_producto_punto(Q, K, V, escala)
norma  = nn::layer_norm(x, gamma, beta, eps)
logits = nn::linear(x, peso, sesgo)
probs  = nn::softmax(logits)
```

---

## v1.0.0 — Inferencia de LLM completa

```zymbol
<# std/llm => llm

modelo = llm::cargar("deepseek-r1-7b.gguf")
tok    = llm::tokenizador(modelo)

chat = llm::sesion(modelo, (
    sistema:      "Eres un asistente útil en español.",
    temperatura:  0.7,
    max_tokens:   512
))

respuesta = llm::generar(chat, "¿Cómo funciona la atención multi-cabeza?")
>> respuesta ¶
```

---

## La cadena completa

```
Zofía v1 (Fases 1–5)
    ↓ identifica que el cuello de botella es el Tensor nativo
Zymbol v0.0.8 — Tensor nativo (100× más rápido)
    ↓
Zofía v2 (Fases 6–8) — reescribe módulos sobre std/tensor
    ↓ identifica que el siguiente límite es cargar pesos reales
Zymbol v0.0.9 — safetensors + f16
    ↓
Zofía v3 — carga GPT-2 small (125M parámetros) en Zymbol puro
    ↓
Zymbol v0.1.0 — tokenizador BPE nativo
    ↓
Zymbol v1.0.0 — std/llm completo
    ↓
Chat con DeepSeek o Gemma en Zymbol nativo
```

Zofía no es un prototipo descartable.
**Es el banco de pruebas que define qué necesita construir Zymbol a continuación.**

---

## Referencias

- Vaswani et al. (2017) — *Attention Is All You Need*
- Brown et al. (2020) — *Language Models are Few-Shot Learners* (GPT-3)
- Touvron et al. (2023) — *LLaMA: Open and Efficient Foundation Language Models*
- HuggingFace — *safetensors format specification*
- Gerganov (2023) — *llama.cpp / GGUF format*
