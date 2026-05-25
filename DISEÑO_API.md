# Diseño de API — Módulos Zofía

Documento de contratos para todos los módulos Zymbol de Zofía.
Aprobado en Fase 0 y actualizado durante la implementación para reflejar
la API real de cada módulo.

Convención de tipos en este documento:
- `escalar` — un número (entero o decimal)
- `vector` — lista plana de escalares, ej. [1.0, 2.0, 3.0]
- `matriz` — lista de listas (2D), ej. [[1,2],[3,4]]
- `tensor` — lista anidada de N dimensiones
- `forma` — lista de enteros que describe dimensiones, ej. [3, 4] = matriz 3×4
- `config` — tupla nombrada con parámetros del modelo
- `bool` — valor booleano Zymbol (#1 verdadero, #0 falso)

> **Nota sobre matemáticas:** Zofía usa `<# std/math => _mat` directamente.
> El módulo de workaround `matematica.zy` no fue necesario — `std/math` y
> `std/random` cubren el 100% de los requisitos numéricos desde v0.0.6.

---

## Módulo: tensor

```
# Fuente: álgebra lineal estándar

crear(forma, valor_inicial) → tensor
  -- Crea un tensor lleno de valor_inicial con la forma dada.
  -- ej: crear([2, 3], 0.0) → [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]

crear_desde_lista(lista_plana, forma) → tensor
  -- Convierte una lista plana en un tensor con la forma dada.
  -- Precondición: largo(lista_plana) == producto de todos los elementos de forma.

forma_de(tensor) → forma
  -- Devuelve la forma del tensor como lista de enteros.
  -- ej: forma_de([[1,2],[3,4]]) → [2, 2]

elemento(tensor, indices) → escalar
  -- Accede a un elemento por lista de índices 1-based.
  -- ej: elemento(t, [1, 2]) == t[1][2]

sumar(a, b) → tensor
  -- Suma elemento a elemento — recursivo para cualquier profundidad.
  -- Precondición: a y b tienen la misma forma.

restar(a, b) → tensor
  -- Resta elemento a elemento — misma profundidad que sumar.

multiplicar_escalar(tensor, escalar) → tensor
  -- Multiplica cada elemento por el escalar.

producto_punto(vec_a, vec_b) → escalar
  -- Producto punto de dos vectores de la misma longitud.
  -- Fórmula: Σᵢ aᵢ × bᵢ

producto_matricial(mat_a, mat_b) → matriz
  -- Multiplicación de matrices. Columnas de mat_a deben = filas de mat_b.
  -- Fórmula: (AB)ᵢⱼ = Σₖ Aᵢₖ × Bₖⱼ

transponer(matriz) → matriz
  -- Intercambia filas por columnas.
  -- Fórmula: Aᵀᵢⱼ = Aⱼᵢ

aplanar(tensor) → vector
  -- Convierte tensor de cualquier forma en lista plana.

reformar(tensor, nueva_forma) → tensor
  -- Reorganiza los elementos en una nueva forma. El total de elementos no cambia.

imprimir(tensor) → ninguno
  -- Muestra el tensor con cabecera de forma: "Tensor [2×3]: ..."
```

---

## Módulo: grad

```
# Fuente: Ruder (2016), An Overview of Gradient Descent Optimization Algorithms
#         Baydin et al. (2018), Automatic Differentiation in Machine Learning

variable(valor, nombre) → variable_con_grad
  -- Crea una variable escalar con acumulador de gradiente.
  -- La variable_con_grad es una tupla nombrada: (valor: v, grad: 0.0, nombre: n)

gradiente_de(v) → escalar
  -- Devuelve el gradiente acumulado actual de v.

asignar_grad(v, g) → variable_con_grad
  -- Devuelve la variable con el gradiente establecido a g.

reiniciar_grad(v) → variable_con_grad
  -- Devuelve la variable con el gradiente a cero.

paso_gradiente(v, tasa) → variable_con_grad
  -- Un paso SGD: w ← w − α × grad, luego pone grad a cero.
  -- Devuelve la variable actualizada (inmutabilidad funcional).

reiniciar_gradientes(vars) → lista de variable_con_grad
  -- Aplica reiniciar_grad a cada elemento de la lista.

paso_gradiente_lista(vars, tasa) → lista de variable_con_grad
  -- Aplica paso_gradiente a cada elemento de la lista.

mse(y_pred, y_real) → escalar
  -- Error cuadrático medio: (1/n) × Σ(ŷᵢ − yᵢ)²

gradiente_mse(y_pred, y_real) → vector
  -- Gradiente del ECM respecto a las predicciones: (2/n) × (ŷᵢ − yᵢ)

imprimir_var(v) → ninguno
  -- Muestra: "nombre: valor (grad: gradiente)"
```

---

## Módulo: activacion

```
# Fuente: Goodfellow et al. (2016), Deep Learning, Cap. 6
#         Nair & Hinton (2010), Rectified Linear Units Improve RBMs
#         Bridle (1990), Probabilistic Interpretation of Feedforward Networks

relu(x) → escalar
  -- Unidad lineal rectificada: max(0, x)

relu_gradiente(x) → escalar
  -- ∂ReLU/∂x: 1 si x > 0, 0 en caso contrario.

relu_vec(v) → vector
  -- Aplica relu elemento a elemento sobre un vector.

relu_grad_vec(v) → vector
  -- Aplica relu_gradiente elemento a elemento.

sigmoide(x) → escalar
  -- σ(x) = 1 / (1 + e^−x) — mapea cualquier real a (0, 1).
  -- Delegado a _mat::sigmoid (std/math).

sigmoide_vec(v) → vector
  -- Aplica sigmoide elemento a elemento.

tangente_hiperbolica(x) → escalar
  -- tanh(x) — mapea cualquier real a (−1, 1); centrada en cero.
  -- Delegado a _mat::tanh (std/math).

tangente_hiperbolica_vec(v) → vector
  -- Aplica tanh elemento a elemento.

tanh_grad_vec(a_vec) → vector
  -- ∂tanh/∂z usando las salidas ya cacheadas: 1 − a²
  -- Recibe el vector de salidas tanh (no de entradas); evita recomputar.

softmax(v) → vector
  -- softmax(v)ᵢ = e^vᵢ / Σⱼ e^vⱼ — convierte puntuaciones en probabilidades que suman 1.
  -- Opera siempre sobre un vector completo (no elemento a elemento).
```

---

## Módulo: perdida

```
# Fuente: Goodfellow et al. (2016), Deep Learning, Cap. 5

_ln_seguro(x) → escalar  [privada]
  -- Logaritmo numéricamente estable: recorta en ε = 1e-7 para evitar log(0).

mse(y_pred, y_real) → escalar
  -- Error cuadrático medio: (1/n) × Σᵢ (ŷᵢ − yᵢ)²
  -- Uso: regresión.

bce_escalar(yhat, y) → escalar
  -- Entropía cruzada binaria para un único par (predicción, objetivo).
  -- Fórmula: −[y·log(ŷ) + (1−y)·log(1−ŷ)]
  -- Uso: clasificación binaria, entrada de entrenamiento por ejemplo.

entropia_cruzada_binaria(y_hat, y) → escalar
  -- BCE promediada sobre un vector: (1/n) × Σᵢ BCE(ŷᵢ, yᵢ)
  -- Uso: pérdida por lote en clasificación binaria.

entropia_cruzada(y_hat, y) → escalar
  -- Entropía cruzada multiclase: −Σᵢ yᵢ·log(ŷᵢ)
  -- Uso: clasificación multiclase; y_hat debe ser salida de softmax.
```

---

## Módulo: atencion

```
# Fuente: Vaswani et al. (2017), "Attention Is All You Need"

_softmax_filas(M) → matriz  [privada]
  -- Aplica softmax fila a fila sobre una matriz.

_extraer_cols(M, inicio, fin) → matriz  [privada]
  -- Extrae columnas [inicio..fin] (base 1, inclusive) de cada fila.

_concat_cols(A, B) → matriz  [privada]
  -- Concatena las columnas de B a la derecha de las de A, fila a fila.

proyectar(entrada, pesos, sesgo) → matriz
  -- Proyección lineal afín: entrada × pesos + sesgo
  -- El sesgo se difunde sobre cada fila del resultado.
  -- entrada: [seq, d_in]  pesos: [d_in, d_out]  sesgo: [d_out]
  -- salida:  [seq, d_out]

atencion_producto_punto(Q, K, V) → matriz
  -- Atención(Q,K,V) = softmax(Q·Kᵀ / √dₖ) · V
  -- Fuente: Vaswani et al. (2017), Ecuación 1
  -- Q, K: [seq, dk]   V: [seq, dv]   salida: [seq, dv]

atencion_enmascarada(Q, K, V, mascara) → matriz
  -- Igual que atencion_producto_punto pero aplica máscara causal antes del softmax.
  -- mascara: matriz de booleanos — #1 = posición válida, #0 = bloquear (−1e9).
  -- Uso: decodificador (bloquear posiciones futuras).

atencion_multiencabezado(Q, K, V, config) → matriz
  -- MultiCabeza(Q,K,V) = Concat(cabeza₁,…,cabezaₕ) × W_O
  -- Fuente: Vaswani et al. (2017), Sección 3.2.2
  -- config: tupla nombrada con campos:
  --   num_cabezas: ###   dim_modelo: ###
  --   pesos_q: [dm, dm]  pesos_k: [dm, dm]  pesos_v: [dm, dm]  pesos_o: [dm, dm]
  -- Cada cabeza trabaja con dim_cab = dim_modelo / num_cabezas columnas.
  -- salida: [seq, dim_modelo]
```

---

## Módulo: transformador

```
# Fuente: Vaswani et al. (2017), "Attention Is All You Need"
# Implementación: solo codificador (sin decodificador)

codificacion_posicional(pos, dim_modelo) → vector
  -- Codificación posicional sinusoidal para la posición pos (base 1).
  -- Fórmula par:   PE(pos, 2i)   = sin(pos / 10000^(2i/dim_modelo))
  -- Fórmula impar: PE(pos, 2i+1) = cos(pos / 10000^(2i/dim_modelo))
  -- salida: [dim_modelo]

normalizar_capa(x, gamma, beta) → matriz
  -- Normalización de capa fila a fila.
  -- Fórmula por fila: γ × (x − μ) / √(σ² + ε) + β   con ε = 1e-6
  -- gamma, beta: vectores aprendibles de longitud dim_modelo
  -- x: [seq, dim_modelo]   salida: [seq, dim_modelo]

capa_feed_adelante(x, pesos_1, sesgo_1, pesos_2, sesgo_2) → matriz
  -- Red de alimentación directa: ReLU(x·W₁ + b₁)·W₂ + b₂
  -- Fuente: Vaswani et al. (2017), Sección 3.3
  -- pesos_1: [dm, dim_ff]   pesos_2: [dim_ff, dm]   (dim_ff = 2 × dm en Zofía)
  -- Procesamiento fila a fila mediante _proyectar_fila interna.
  -- x: [seq, dm]   salida: [seq, dm]

bloque_codificador(x, config) → matriz
  -- Un bloque completo del codificador con conexiones residuales.
  -- Pasos:
  --   1. aten_sal = atencion_multiencabezado(x, x, x, config)  [auto-atención]
  --   2. norm_1   = normalizar_capa(x + aten_sal, γ₁, β₁)
  --   3. ff_sal   = capa_feed_adelante(norm_1, W1, b1, W2, b2)
  --   4. norm_2   = normalizar_capa(norm_1 + ff_sal, γ₂, β₂)
  -- config: tupla nombrada con todos los pesos y parámetros del bloque:
  --   num_cabezas, dim_modelo, pesos_q, pesos_k, pesos_v, pesos_o,
  --   gamma_1, beta_1, pesos_ff1, sesgo_ff1, pesos_ff2, sesgo_ff2, gamma_2, beta_2
  -- x: [seq, dm]   salida: [seq, dm]  ← preserva dimensiones

codificador(secuencia, configs) → matriz
  -- Pasa la secuencia por N bloques codificadores apilados.
  -- configs: lista de tuplas de configuración (una por capa)
  -- Itera: x = bloque_codificador(x, cfg) para cada cfg en configs
  -- secuencia: [seq, dm]   salida: [seq, dm]  ← preserva dimensiones
```

---

## Notas de implementación para todas las fases

**Representación de tensor en Zymbol:**
Un tensor se representa como listas anidadas. Una matriz 2×3 es:
```
[[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]
```
No existe un tipo nativo `tensor` — es una convención sobre listas de Zymbol.

**Funciones matemáticas (std/math):**
Todos los módulos usan `<# std/math => _mat` (o alias similar).
Las funciones disponibles son: `sqrt exp ln log pow sin cos tan tanh sinh cosh
sigmoid abs max min floor ceil round`. También exporta constantes `PI` y `E`.

**Números aleatorios (std/random):**
El módulo `std/random` (xoshiro256++, semilla automática desde SystemTime) provee:
```
rng::entero(min, max)  -- Int en [min, max]
rng::rango(n)          -- Int en [0, n-1]
rng::peso_f64()        -- Float en [-0.1, 0.1] para inicialización de pesos
```
La red XOR (04_red_simple.zy) usa `rng::peso_f64() * 10.0` para pesos en [−1, 1].

**Inmutabilidad funcional:**
Las tuplas nombradas (incluyendo `variable_con_grad`) son inmutables.
Las operaciones `$~` devuelven una nueva tupla; el llamador reasigna la variable.

**Precisión numérica:**
Los flotantes de Zymbol son `f64` (IEEE 754, doble precisión). Suficientes para
aprendizaje educativo. No se busca precisión de producción sino claridad de concepto.

**Funciones privadas:**
Los nombres con prefijo `_` (como `_softmax_filas`, `_proyectar_fila`) son
auxiliares internas no exportadas por el módulo (`#>` no las incluye).
