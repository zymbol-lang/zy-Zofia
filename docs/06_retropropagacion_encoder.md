# Retropropagación en el Encoder Transformer

> Documento 06 — Prerequisito: todos los documentos anteriores (00 al 05)
> Este documento responde: ¿cómo aprende el encoder? ¿cómo fluyen los gradientes
> a través de la atención, la normalización y la red feed-forward?

---

## El problema: el encoder no aprende

Zofía v1 construyó un encoder completamente funcional para el pase hacia adelante.
Sin embargo, sus pesos son fijos — los pasamos manualmente o los inicializamos con
la identidad. Un encoder útil necesita **aprender** sus pesos desde datos.

Para aprender, necesitamos:
1. Una función de pérdida que mida qué tan mal está haciendo el encoder
2. Los gradientes de esa pérdida respecto a **cada peso** del encoder
3. Un paso de descenso de gradiente que actualice los pesos en la dirección correcta

Eso es retropropagación — ya lo hicimos para XOR en la Fase 3. Ahora lo aplicamos
a la arquitectura completa del transformer.

---

## La regla de la cadena en el encoder

El encoder es una composición de operaciones:

```
entrada → [Norma+Atención+Residual] → [Norma+FAD+Residual] → salida
```

Por la regla de la cadena, si tenemos `∂L/∂salida`, podemos calcular:

```
∂L/∂norma2_in  = grad_layernorm(∂L/∂salida)
∂L/∂ff_in      = grad a través de la conexión residual
∂L/∂pesos_ff   = grad_ffd(∂L/∂ff_in)
∂L/∂norma1_in  = grad_layernorm(∂L/∂norma2_in)
∂L/∂aten_in    = grad a través de la conexión residual
∂L/∂pesos_qkvo = grad_atencion(∂L/∂aten_in)
```

Cada bloque tiene su función backward correspondiente.

---

## Gradiente de la capa lineal (ya conocido)

De la Fase 3 (XOR), el backward de una capa lineal `Y = X·W + b` es:

```
∂L/∂W = Xᵀ · ∂L/∂Y         -- forma igual que W
∂L/∂b = Σ filas de ∂L/∂Y   -- suma sobre la secuencia
∂L/∂X = ∂L/∂Y · Wᵀ         -- para propagar hacia atrás
```

Todos los pesos del encoder (Q, K, V, O, FF1, FF2) usan esta misma fórmula.

---

## Gradiente de la normalización de capa

Para `y = γ × (x − μ) / √(σ² + ε) + β`, dado `∂L/∂y`:

```
∂L/∂γ = Σᵢ ∂L/∂yᵢ × x̂ᵢ        -- x̂ = (x − μ) / √(σ² + ε)
∂L/∂β = Σᵢ ∂L/∂yᵢ               -- suma directa

// Gradiente respecto a x (más complejo — involucra la media y la varianza):
∂L/∂x = (γ/√(σ²+ε)) × (∂L/∂y − mean(∂L/∂y) − x̂ × mean(∂L/∂y × x̂))
```

La clave: el gradiente de x depende de **todos los elementos** del vector x (no
solo del elemento correspondiente) porque la media y varianza acoplan todo.

---

## Gradiente del softmax

Para `y = softmax(x)`, dado `∂L/∂y`:

```
∂L/∂xᵢ = yᵢ × (∂L/∂yᵢ − Σⱼ ∂L/∂yⱼ × yⱼ)

// En forma matricial (más eficiente):
∂L/∂x = y × (∂L/∂y − dot(∂L/∂y, y))
```

Esto se aplica fila a fila en la matriz de pesos de atención.

---

## Gradiente de la atención producto punto escalada

Para `Y = softmax(QKᵀ/√dₖ) × V`, el backward recibe `∂L/∂Y` y devuelve
los gradientes respecto a Q, K y V:

```
// Paso 1: gradiente respecto a V
∂L/∂V = Pᵀ × ∂L/∂Y          -- P = softmax(QKᵀ/√dₖ) (guardado en cache)

// Paso 2: gradiente respecto a P (los pesos de atención)
∂L/∂P = ∂L/∂Y × Vᵀ

// Paso 3: gradiente a través del softmax
∂L/∂puntos = grad_softmax(∂L/∂P, P)   -- fila a fila

// Paso 4: gradiente escalado
∂L/∂puntos_escalados = ∂L/∂puntos / √dₖ

// Paso 5: gradientes respecto a Q y K
∂L/∂Q = ∂L/∂puntos_escalados × K
∂L/∂K = ∂L/∂puntos_escalados × Q  // nota: transponer correctamente
```

---

## El cache del pase hacia adelante

Para calcular todos estos gradientes, el pase hacia adelante debe **guardar
los valores intermedios** que el backward necesita:

```zymbol
// El cache de un bloque codificador contiene:
cache = (
    x_entrada:    x,          // entrada al bloque (para residual)
    x_norm1:      norm_1_in,  // entrada a la normalización 1
    Q_full:       Q_full,     // proyecciones completas
    K_full:       K_full,
    V_full:       V_full,
    P_atencion:   P,          // pesos softmax (para grad_softmax)
    aten_sal:     aten_sal,   // salida de atención (para residual)
    x_norm2:      norm_2_in,  // entrada a la normalización 2
    h_ff:         h_ff,       // activaciones ocultas de la FAD (para grad ReLU)
    config:       config      // pesos del bloque
)
```

---

## Conexiones residuales en el backward

La conexión residual `y = x + sublayer(x)` tiene un backward trivial:

```
∂L/∂x      += ∂L/∂y    -- gradiente pasa sin cambios por la rama residual
∂L/∂sublayer = ∂L/∂y   -- también pasa sin cambios a la sublayer
```

Esto es exactamente por qué las residuales ayudan al entrenamiento: los
gradientes fluyen directamente sin multiplicarse por nada.

---

## Lo que implementa `grad_encoder.zy`

```
_grad_lineal(dY, X, W)         → (dX, dW, db)
_grad_softmax_filas(dY, P)     → dX
_grad_layernorm_vec(dY, vec, gamma, beta, eps) → (dvec, dgamma, dbeta)
_grad_layernorm(dY, x, gamma, beta)            → (dx, dgamma, dbeta)
_grad_atencion_pp(dY, Q, K, V, P, escala)     → (dQ, dK, dV)
_grad_mha(dY, cache_mha)       → (dQ_in, dK_in, dV_in, dW_q, dW_k, dW_v, dW_o)
_grad_fad(dY, cache_fad)       → (dX, dW1, db1, dW2, db2)
grad_bloque(dY, cache_bloque)  → (dx, grads_pesos)
```

**Ejemplo:** `07_entrenar_encoder.zy` — encoder de dim=4, 2 cabezas, 2 capas.
Tarea: predecir la suma de tokens de una secuencia (regresión simple).
La pérdida ECM disminuye en cada época — criterio verificado en 20 épocas.

---

## Persistencia de pesos

Al terminar el entrenamiento, los pesos se serializan a JSON usando
`lib/file.zy` y `lib/json.zy` (de ZeethyCLI):

```zymbol
// Guardar checkpoint
ckpt = serializar_config(config_entrenado)
file::write("modelos/encoder_entrenado.json", ckpt)

// Cargar en la siguiente sesión
ckpt_str = file::read("modelos/encoder_entrenado.json")
config    = deserializar_config(ckpt_str)
```
