# Gradientes y Optimización

> Documento 02 — Prerequisito: 00_fundamentos_matematicos.md, 01_tensores.md
> Este documento responde: ¿cómo aprende una red neuronal?

---

## El problema central

Una red neuronal tiene miles o millones de pesos (números). Al inicio se
inicializan al azar, así que la red produce respuestas incorrectas. El
**aprendizaje** es el proceso de ajustar esos pesos hasta que las respuestas
sean correctas.

¿Pero cómo saber en qué dirección ajustar cada peso? Eso responde el gradiente.

---

## La función de pérdida (loss function)

Necesitamos una forma de medir qué tan equivocada está la red. Eso es la función
de pérdida: un número que dice cuán mal está funcionando el modelo.

```
pérdida alta   →  el modelo está muy equivocado
pérdida baja   →  el modelo está acertando
pérdida = 0    →  predicción perfecta (raramente ocurre)
```

Queremos minimizar la pérdida. El aprendizaje = minimización de la pérdida.

### Error Cuadrático Medio — MSE (mean squared error)

Para problemas donde la salida es un número (regresión):

```
pérdida = (1/n) × Σᵢ (predicciónᵢ - objetivoᵢ)²
```

El cuadrado sirve para dos cosas:
1. Hace todos los errores positivos (un error de -3 y uno de +3 son igualmente malos)
2. Penaliza más los errores grandes (un error de 6 pesa el cuádruple que uno de 3)

**Ejemplo:**
```
predicciones = [2.5, 3.0, 1.0]
objetivos    = [3.0, 3.0, 0.5]

errores_al_cuadrado = [(2.5-3.0)², (3.0-3.0)², (1.0-0.5)²]
                    = [0.25, 0.0, 0.25]

MSE = (0.25 + 0.0 + 0.25) / 3 = 0.167
```

### Entropía cruzada (cross entropy)

Para problemas donde la salida es una categoría (clasificación):

```
pérdida = -Σᵢ objetivoᵢ × log(predicciónᵢ)
```

Castiga fuertemente las predicciones muy equivocadas (log de un número muy
pequeño es muy negativo → pérdida muy alta).

---

## El gradiente como brújula

El gradiente de la pérdida respecto a un peso *w* dice:
**"si aumentas *w* un poco, la pérdida aumenta en esta proporción"**.

```
∂L/∂w = 2.5   →  si aumentas w, la pérdida sube (w está siendo demasiado grande)
∂L/∂w = -1.3  →  si aumentas w, la pérdida baja (w debería ser más grande)
∂L/∂w = 0.0   →  w está en un punto donde la pérdida no cambia (mínimo local)
```

Para minimizar la pérdida, movemos cada peso en la **dirección opuesta** al gradiente:

```
w ← w - α × ∂L/∂w
```

- Si ∂L/∂w es positivo: restamos, haciendo *w* más pequeño
- Si ∂L/∂w es negativo: restamos un negativo, haciendo *w* más grande
- `α` (alfa) es la tasa de aprendizaje (learning rate) — controla el tamaño del paso

---

## Descenso de gradiente (gradient descent)

Visualización en 1D: imagina una función que parece una montaña.
Queremos llegar al valle (mínimo).

```
pérdida
  │        *
  │      *   *
  │    *       *
  │  *           *
  │*               *
  └──────────────── peso w
              ↑
           queremos llegar aquí
```

El gradiente nos dice si la función sube o baja. Si es positivo (subimos a la
derecha), movemos *w* hacia la izquierda (restamos). Así avanzamos hacia el valle.

### Tipos de descenso de gradiente

**Descenso de gradiente por lote completo (batch gradient descent):**
Calcula el gradiente usando todos los ejemplos de entrenamiento. Preciso pero lento.

**Descenso de gradiente estocástico — SGD (stochastic gradient descent):**
Calcula el gradiente usando un solo ejemplo a la vez. Rápido pero ruidoso.

**Mini-batch:**
Término medio: usa un subconjunto (lote de 32, 64, 128 ejemplos). Es el más usado.

Zofía implementa SGD básico por claridad. Los conceptos son los mismos.

---

## Retropropagación (backpropagation)

El problema: una red tiene muchas capas. La pérdida depende de la última capa,
que depende de la anterior, que depende de la anterior... ¿Cómo calculamos el
gradiente de la pérdida respecto a cada peso en cada capa?

Con la **regla de la cadena**, aplicada hacia atrás desde la pérdida hasta
cada peso. Por eso se llama retropropagación: los gradientes se propagan
hacia atrás.

### Ejemplo con dos capas

```
entrada → [Capa 1, pesos W1] → activacion → [Capa 2, pesos W2] → pérdida L
```

Para actualizar W1 necesitamos ∂L/∂W1. Aplicando la cadena:

```
∂L/∂W1 = ∂L/∂activacion × ∂activacion/∂salida_capa1 × ∂salida_capa1/∂W1
```

Cada término se calcula de derecha a izquierda:
1. ∂L/∂salida_capa2 — qué tan sensible es L a la salida de la última capa
2. ∂salida_capa2/∂activacion — qué tan sensible es la capa 2 a su entrada
3. ∂activacion/∂salida_capa1 — cómo cambia la activación
4. ∂salida_capa1/∂W1 — cómo cambia la salida de capa 1 respecto a sus pesos

La clave: cada capa solo necesita saber el gradiente que viene de la capa
siguiente y su propio cálculo local. Esto hace el algoritmo modular.

---

## El grafo computacional (computational graph)

Para implementar retropropagación, se construye un grafo donde cada nodo
es una operación y cada arista lleva el valor calculado.

```
W1 ───┐
      ├── [producto_matricial] ── z1 ── [relu] ── a1 ──┐
x  ───┘                                                 ├── [producto_matricial] ── z2 ── [MSE] ── L
W2 ─────────────────────────────────────────────────────┘
                                                               y (objetivo)
```

**Hacia adelante (forward pass):** se calculan todos los valores de izquierda
a derecha.

**Hacia atrás (backward pass):** se calculan todos los gradientes de derecha
a izquierda usando la cadena.

En Zofía, no implementamos un grafo computacional completo (eso sería PyTorch).
En cambio, calculamos los gradientes manualmente para cada tipo de red,
para que el proceso sea visible y comprensible.

---

## La tasa de aprendizaje (learning rate)

La tasa de aprendizaje `α` controla qué tan grande es cada paso de ajuste.

```
α muy grande:  los pesos saltan demasiado, la pérdida oscila o diverge
α muy pequeña: el aprendizaje es correcto pero muy lento
α correcta:    la pérdida baja suavemente hasta converger
```

**Ejemplo de divergencia con α demasiado grande:**
```
pérdida
  │    *
  │         *
  │               *     ← en lugar de bajar, sube
  └───────────────── iteraciones
```

Valores típicos de α: entre 0.001 y 0.1. En Zofía usaremos 0.01 como punto
de partida.

---

## Inicialización de pesos

Los pesos iniciales deben ser pequeños y aleatorios. ¿Por qué?

**No cero:** si todos los pesos son 0, todos los gradientes son iguales y las
neuronas aprenden lo mismo. La red queda atascada (problema de simetría).

**No muy grandes:** valores grandes producen activaciones extremas → gradientes
extremos → inestabilidad.

**Aleatorios:** romper la simetría. Cada neurona aprende algo diferente.

Inicialización común: valores uniformes en el rango [-0.1, 0.1] o distribución
normal con media 0 y desviación estándar pequeña.

---

## Resumen del ciclo de aprendizaje

```
INICIO: pesos aleatorios pequeños

REPETIR hasta convergencia:
  1. Tomar un lote de ejemplos (entradas, objetivos)
  2. HACIA ADELANTE:
     - calcular predicciones pasando entradas por todas las capas
  3. PÉRDIDA:
     - calcular error entre predicciones y objetivos
  4. HACIA ATRÁS:
     - calcular ∂L/∂w para cada peso (regla de la cadena)
  5. ACTUALIZAR:
     - w ← w - α × ∂L/∂w para cada peso
  6. Registrar la pérdida para monitorear progreso
FIN
```

---

## Lo que implementa `grad.zy`

El módulo `grad.zy` encapsula los pasos 4 y 5 de ese ciclo. Proporciona:

- `variable(valor, nombre)` — crear pesos rastreables
- `retropropagar_mse(prediccion, objetivo, pesos)` — calcular gradientes
- `paso_gradiente(pesos, tasa)` — actualizar pesos
- `reiniciar_gradientes(pesos)` — limpiar antes de cada iteración

El ejemplo `03_descenso_gradiente.zy` mostrará el ciclo completo encontrando
el mínimo de f(x) = x² paso a paso, imprimiendo cada iteración para que sea
visible el proceso de convergencia.
