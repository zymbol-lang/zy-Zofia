# Redes Neuronales

> Documento 03 — Prerequisito: 02_gradientes_y_optimizacion.md
> Este documento responde: ¿cómo combinamos los bloques anteriores en una red real?

---

## De la neurona biológica a la artificial

Una neurona biológica recibe señales de muchas otras neuronas, las suma, y si
la suma supera un umbral, dispara una señal de salida.

Una neurona artificial hace algo análogo:

```
entradas × pesos → suma → función de activación → salida
```

```
x₁ ──(w₁)──┐
x₂ ──(w₂)──┼── suma (Σ xᵢwᵢ + b) ── activación ── salida y
x₃ ──(w₃)──┘
```

Donde:
- `x₁, x₂, x₃` son los valores de entrada
- `w₁, w₂, w₃` son los pesos (lo que la red aprende)
- `b` es el sesgo (bias) — un valor que desplaza la suma
- La función de activación decide si y cómo la neurona "se activa"

**Fórmula de una neurona:**
```
y = activacion(w₁x₁ + w₂x₂ + w₃x₃ + b)
  = activacion(Σᵢ wᵢxᵢ + b)
  = activacion(W · x + b)      -- en notación vectorial
```

---

## Funciones de activación

Sin función de activación, una red de múltiples capas sería equivalente a una
sola capa (el producto de matrices lineales es otra matriz lineal). Las
funciones de activación introducen no-linealidad, permitiendo a la red aprender
patrones complejos.

### ReLU — Rectified Linear Unit

```
ReLU(x) = max(0, x)

ReLU(-3) = 0
ReLU(0)  = 0
ReLU(2)  = 2
ReLU(7)  = 7
```

**Gráfica:**
```
salida
  │          /
  │         /
  │        /
  │_______/
  └──────────── entrada
       0
```

**Ventajas:** simple, funciona bien en práctica, no satura para valores positivos.
**Desventaja:** "neuronas muertas" — si x siempre es negativo, el gradiente es 0
y la neurona nunca aprende.

ReLU es la función de activación más usada en redes modernas, incluyendo
la capa feed-forward dentro de cada bloque transformer.

---

### Sigmoide (sigmoid)

```
σ(x) = 1 / (1 + e^(-x))

σ(-5) ≈ 0.007   (casi 0)
σ(0)  = 0.5
σ(5)  ≈ 0.993   (casi 1)
```

Aplana cualquier número real al rango (0, 1). Útil para probabilidades binarias.

**Problema:** cuando |x| es grande, el gradiente es casi 0 — la red aprende
muy lento. Se llama el problema del "gradiente que desaparece" (vanishing gradient).
Por eso no se usa en capas profundas, pero sí en la salida de clasificación binaria.

---

### Softmax

```
softmax(x)ᵢ = e^xᵢ / Σⱼ e^xⱼ
```

Convierte un vector de puntuaciones en probabilidades que suman exactamente 1.

**Ejemplo:**
```
puntuaciones = [2.0, 1.0, 0.1]

e^2.0 = 7.39
e^1.0 = 2.72
e^0.1 = 1.11

suma = 7.39 + 2.72 + 1.11 = 11.22

softmax = [7.39/11.22, 2.72/11.22, 1.11/11.22]
        = [0.659, 0.242, 0.099]        -- suman 1.0 ✓
```

**Uso:** salida de clasificación multiclase. También es el corazón del mecanismo
de atención (convierte puntuaciones de similitud en pesos que suman 1).

---

## De una neurona a una capa

Una capa es un conjunto de neuronas que procesan la misma entrada en paralelo.
Si tenemos 4 entradas y queremos 3 neuronas en la capa, los pesos forman
una matriz 4×3:

```
entrada:  x = [x₁, x₂, x₃, x₄]         -- vector de 4 elementos
pesos:    W = matriz [4, 3]               -- 4 entradas × 3 neuronas
sesgos:   b = [b₁, b₂, b₃]             -- un sesgo por neurona

salida = activacion(x × W + b)           -- vector de 3 elementos
```

El producto matricial `x × W` calcula simultáneamente la suma ponderada para
las 3 neuronas. Una capa completa es un producto matricial más una función de
activación.

---

## De una capa a una red

Una red neuronal es capas apiladas donde la salida de una es la entrada de la siguiente.

```
entrada (4)
    │
[Capa 1: W₁ [4×8], ReLU]
    │
 (8 valores)
    │
[Capa 2: W₂ [8×3], Softmax]
    │
salida (3 probabilidades: clase A, B, C)
```

El número de neuronas en cada capa se llama "dimensión oculta" o "ancho" de la
capa. La elección de estas dimensiones es un hiperparámetro del modelo.

---

## El perceptrón multicapa — MLP (multilayer perceptron)

La arquitectura más básica: capas completamente conectadas (dense layers)
con funciones de activación.

```
HACIA ADELANTE (forward pass):

z1 = x × W1 + b1          -- [n_entrada × n_oculta]
a1 = relu(z1)             -- activación capa 1
z2 = a1 × W2 + b2         -- [n_oculta × n_salida]
y  = softmax(z2)          -- probabilidades finales
```

```
HACIA ATRÁS (backward pass):

dL/dz2 = y - objetivo                -- gradiente de la entropía cruzada + softmax
dL/dW2 = a1ᵀ × dL/dz2              -- regla de la cadena
dL/db2 = dL/dz2

dL/da1 = dL/dz2 × W2ᵀ              -- propagar hacia la capa anterior
dL/dz1 = dL/da1 × derivada_relu(z1) -- pasar por la derivada de ReLU
dL/dW1 = xᵀ × dL/dz1
dL/db1 = dL/dz1
```

```
ACTUALIZAR:
W1 ← W1 - α × dL/dW1
b1 ← b1 - α × dL/db1
W2 ← W2 - α × dL/dW2
b2 ← b2 - α × dL/db2
```

---

## El problema clásico: XOR

XOR es el problema que se usa para demostrar que una sola neurona es insuficiente
pero una red de dos capas puede resolverlo.

| x₁ | x₂ | XOR |
|----|----|-----|
|  0 |  0 |  0  |
|  0 |  1 |  1  |
|  1 |  0 |  1  |
|  1 |  1 |  0  |

Una sola neurona (línea recta en 2D) no puede separar estos casos. Una red con
una capa oculta sí puede, aprendiendo una representación intermedia.

El ejemplo `04_red_simple.zy` implementa exactamente este caso: una red de dos
capas que aprende XOR desde cero, mostrando la pérdida en cada época de entrenamiento.

---

## Épocas e iteraciones

```
época (epoch):     una pasada completa por todos los datos de entrenamiento
iteración:         una actualización de pesos (un lote / batch)
lote (batch):      subconjunto de datos usado en una iteración
```

Para datasets pequeños como XOR (4 ejemplos), una época = una iteración.
Para datasets reales, una época puede tener miles de iteraciones.

---

## Hiperparámetros vs parámetros

**Parámetros:** los aprende el modelo durante el entrenamiento.
- Pesos W, sesgos b

**Hiperparámetros:** los fija el diseñador antes de entrenar.
- Tasa de aprendizaje α
- Número de capas
- Dimensión de cada capa
- Número de épocas
- Tamaño del lote

La elección de hiperparámetros es parte del arte del diseño de redes neuronales.

---

## Conexión con el transformer

El transformer usa redes neuronales en dos lugares:

1. **Capa feed-forward** dentro de cada bloque encoder: es un MLP de dos capas
   (expansión con ReLU, luego proyección de vuelta).

2. **Proyecciones de Q, K, V**: cada una es una capa lineal (producto matricial
   sin activación) que transforma el embedding de entrada en los vectores de
   consulta, clave y valor.

Entender el MLP es entender la mitad de un bloque transformer.
