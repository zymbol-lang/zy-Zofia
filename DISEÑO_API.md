# Diseño de API — Módulos Zofía

Documento de contratos para todos los módulos Zymbol de Zofía.
Se aprueba antes de escribir código de implementación.

Convención de tipos en este documento:
- `escalar` — un número (entero o decimal)
- `vector` — lista plana de escalares, ej. [1.0, 2.0, 3.0]
- `matriz` — lista de listas (2D), ej. [[1,2],[3,4]]
- `tensor` — lista anidada de N dimensiones
- `forma` — lista de enteros que describe dimensiones, ej. [3, 4] = matriz 3×4
- `config` — tupla nombrada con parámetros del modelo

---

## Módulo: matematica  ← fundacional, requerido por Fases 3–5

```
# Workaround para GAP-Z001 (sin funciones matemáticas nativas en Zymbol)
# Implementaciones en Zymbol puro usando métodos numéricos clásicos.
# (Numeric methods: Newton-Raphson, Taylor series)
# Cuando std/matematica exista en Zymbol, este módulo se reemplaza con:
#   <# std/matematica <= mat

PI := 3.14159265358979323846
E  := 2.71828182845904523536

raiz_cuadrada(x) → escalar
  -- Método de Newton-Raphson, 20 iteraciones.
  -- (sqrt — Newton's method convergence: ~O(log(1/ε)))
  -- Precondición: x >= 0

exponencial(x) → escalar
  -- Serie de Taylor truncada a 30 términos.
  -- (exp — Taylor series: e^x = Σ xⁿ/n!)
  -- Preciso para |x| < 100

logaritmo_natural(x) → escalar
  -- Via identidad: ln(x) = 2 × arctanh((x-1)/(x+1))
  -- (natural log — series-based approximation)
  -- Precondición: x > 0

potencia(base, exp) → escalar
  -- Fórmula: e^(exp × ln(base))
  -- (pow — via exp and log)
  -- Para enteros usa multiplicación directa (más preciso)

seno(x) → escalar
  -- Serie de Taylor: sin(x) = x - x³/3! + x⁵/5! - ...
  -- (sin — Taylor series, 15 términos)
  -- Normaliza x al rango [-π, π] antes de la serie

coseno(x) → escalar
  -- Serie de Taylor: cos(x) = 1 - x²/2! + x⁴/4! - ...
  -- (cos — Taylor series, 15 términos)

valor_absoluto(x) → escalar
  -- Devuelve x si x >= 0, -x si x < 0.
  -- (abs)

maxn(a, b) → escalar
  -- Devuelve el mayor de a y b.
  -- (max for scalars — distinto del operador $# de listas)

minn(a, b) → escalar
  -- Devuelve el menor de a y b.

formatear(x, decimales) → escalar
  -- Trunca x a N decimales para visualización.
  -- (float formatting workaround — GAP-Z004)

-- Aleatoriedad (reusado de serpiente/logica.zy)
-- (LCG: Linear Congruential Generator — Numerical Recipes constants)
lcg_paso(semilla) → entero
  -- Avanza la semilla LCG un paso: (semilla × 1664525 + 1013904223) % 2³²

aleatorio_rango(semilla, min, max) → (valor, semilla_sig)
  -- Entero aleatorio en [min, max], devuelve nuevo estado de semilla.

peso_aleatorio(semilla) → (valor, semilla_sig)
  -- Decimal en [-0.1, 0.1], para inicialización de pesos de red.
```

---

## Módulo: tensor

```
# Fuente: álgebra lineal estándar
# (Source: standard linear algebra)

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
  -- Accede a un elemento por lista de índices.
  -- ej: elemento(t, [1, 2]) == t[1][2]

sumar(a, b) → tensor
  -- Suma elemento a elemento. Ambos tensores deben tener la misma forma.
  -- (element-wise addition)

restar(a, b) → tensor
  -- Resta elemento a elemento.

multiplicar_escalar(tensor, escalar) → tensor
  -- Multiplica cada elemento por el escalar.
  -- (scalar multiplication)

producto_punto(vec_a, vec_b) → escalar
  -- Producto punto de dos vectores de la misma longitud.
  -- Fórmula: Σᵢ aᵢ × bᵢ
  -- (dot product)

producto_matricial(mat_a, mat_b) → matriz
  -- Multiplicación de matrices. Columnas de mat_a deben = filas de mat_b.
  -- Fórmula: (AB)ᵢⱼ = Σₖ Aᵢₖ × Bₖⱼ
  -- (matrix multiplication / matmul)

transponer(matriz) → matriz
  -- Intercambia filas por columnas.
  -- Fórmula: Aᵀᵢⱼ = Aⱼᵢ
  -- (transpose)

aplanar(tensor) → vector
  -- Convierte tensor de cualquier forma en lista plana.
  -- (flatten)

reformar(tensor, nueva_forma) → tensor
  -- Reorganiza los elementos en una nueva forma. El total de elementos no cambia.
  -- (reshape)

imprimir(tensor) → ninguno
  -- Muestra el tensor con forma legible: "Tensor [2×3]: ..."
```

---

## Módulo: activacion

```
# Fuente: Goodfellow et al. (2016), Deep Learning, Cap. 6
# (Source: activation functions — standard ML reference)

relu(x) → escalar o tensor
  -- Rectified Linear Unit: max(0, x) aplicado elemento a elemento.
  -- Devuelve 0 si x < 0, x si x >= 0.

sigmoide(x) → escalar o tensor
  -- Fórmula: 1 / (1 + e^(-x))
  -- Aplana cualquier valor real al rango (0, 1).
  -- (sigmoid)

softmax(vector) → vector
  -- Convierte un vector de puntuaciones en probabilidades que suman 1.
  -- Fórmula: softmaxᵢ = e^xᵢ / Σⱼ e^xⱼ
  -- Siempre opera sobre un vector completo (no elemento a elemento).

tangente_hiperbolica(x) → escalar o tensor
  -- Fórmula: (e^x - e^(-x)) / (e^x + e^(-x))
  -- Rango de salida: (-1, 1).
  -- (tanh)

derivada_relu(x) → escalar o tensor
  -- Devuelve 1 si x > 0, 0 si x <= 0.
  -- Necesaria para retropropagación.

derivada_sigmoide(x) → escalar o tensor
  -- Fórmula: sigmoide(x) × (1 - sigmoide(x))
  -- Se calcula desde el valor de activación ya computado.
```

---

## Módulo: perdida

```
# Fuente: Goodfellow et al. (2016), Deep Learning, Cap. 5
# (Source: loss functions)

mse(prediccion, objetivo) → escalar
  -- Error cuadrático medio (mean squared error).
  -- Fórmula: (1/n) × Σᵢ (predicciónᵢ - objetivoᵢ)²
  -- Uso: regresión.

entropia_cruzada(prediccion, objetivo) → escalar
  -- Entropía cruzada categórica (categorical cross entropy).
  -- Fórmula: -Σᵢ objetivoᵢ × log(predicciónᵢ)
  -- Uso: clasificación multiclase. prediccion debe ser salida de softmax.

entropia_cruzada_binaria(prediccion, objetivo) → escalar
  -- Entropía cruzada binaria (binary cross entropy).
  -- Fórmula: -(objetivo × log(pred) + (1-objetivo) × log(1-pred))
  -- Uso: clasificación binaria. prediccion debe ser salida de sigmoide.

gradiente_mse(prediccion, objetivo) → vector
  -- Derivada de MSE respecto a prediccion.
  -- Fórmula: (2/n) × (prediccion - objetivo)
```

---

## Módulo: grad

```
# Fuente: Ruder (2016), An Overview of Gradient Descent Optimization Algorithms
# (Source: backpropagation, Rumelhart et al. 1986)

variable(valor, nombre) → variable_con_grad
  -- Crea una variable que rastrea gradientes durante retropropagación.
  -- La variable_con_grad es una tupla: (valor, gradiente, nombre)

paso_gradiente(variables, tasa) → ninguno
  -- Actualiza cada variable restando gradiente × tasa.
  -- Fórmula: w ← w - α × ∂L/∂w
  -- (gradient descent step, learning rate = tasa)

reiniciar_gradientes(variables) → ninguno
  -- Pone todos los gradientes a cero antes de un nuevo paso.
  -- (zero_grad — necesario porque los gradientes se acumulan)

retropropagar_mse(prediccion, objetivo, pesos_capas) → ninguno
  -- Calcula y asigna gradientes para cada peso via regla de la cadena.
  -- Modifica pesos_capas.gradiente en lugar.
  -- (backpropagation for MSE loss)
```

---

## Módulo: atencion

```
# Fuente: Vaswani et al. (2017), "Attention Is All You Need"

atencion_producto_punto(consulta, clave, valor) → tensor
  -- Scaled dot-product attention.
  -- Fórmula: softmax(consulta × claveᵀ / √dim_clave) × valor
  -- consulta: matriz [seq, dim_k]
  -- clave:    matriz [seq, dim_k]
  -- valor:    matriz [seq, dim_v]
  -- salida:   matriz [seq, dim_v]
  -- (scaled dot-product attention)

atencion_enmascarada(consulta, clave, valor, mascara) → tensor
  -- Igual que atencion_producto_punto pero aplica máscara antes del softmax.
  -- La máscara es una matriz booleana: #1 = posición válida, #0 = ignorar.
  -- Uso: decoder (enmascarar posiciones futuras).
  -- (masked attention)

proyectar(entrada, pesos, sesgo) → tensor
  -- Proyección lineal: entrada × pesos + sesgo.
  -- (linear projection)

atencion_multiencabezado(consulta, clave, valor, config) → tensor
  -- Multi-head attention.
  -- config contiene: (num_cabezas, dim_modelo, pesos_q, pesos_k, pesos_v, pesos_o)
  -- 1. Divide en num_cabezas cabezas de dimensión dim_modelo/num_cabezas
  -- 2. Aplica atencion_producto_punto en cada cabeza por separado
  -- 3. Concatena las salidas y proyecta con pesos_o
  -- Fórmula: MultiHead(Q,K,V) = Concat(cabeza₁,...,cabezaₕ) × W^O
  -- (multi-head attention)
```

---

## Módulo: transformador

```
# Fuente: Vaswani et al. (2017), "Attention Is All You Need"
# Implementación: solo encoder (no decoder)

codificacion_posicional(posicion, dim_modelo) → vector
  -- Suma información de posición a un embedding.
  -- Fórmula par:  PE(pos, 2i)   = sin(pos / 10000^(2i/dim_modelo))
  -- Fórmula impar: PE(pos, 2i+1) = cos(pos / 10000^(2i/dim_modelo))
  -- (positional encoding — Vaswani et al. Ecuación 1)

normalizar_capa(x, gamma, beta) → tensor
  -- Layer normalization sobre el último eje.
  -- Fórmula: γ × (x - μ) / √(σ² + ε) + β
  -- μ = media de x, σ = desviación estándar, ε = 1e-6 (estabilidad numérica)
  -- (layer normalization — Ba et al. 2016)

capa_feed_adelante(x, pesos_1, sesgo_1, pesos_2, sesgo_2) → tensor
  -- Dos proyecciones lineales con ReLU en el medio.
  -- Fórmula: ReLU(x × W₁ + b₁) × W₂ + b₂
  -- dim interna es típicamente 4 × dim_modelo
  -- (position-wise feed-forward network)

bloque_codificador(x, config) → tensor
  -- Un bloque completo del encoder.
  -- Pasos:
  --   1. atención multiencabezado con conexión residual: x = x + MultiHead(x,x,x)
  --   2. normalización de capa
  --   3. feed-forward con conexión residual: x = x + FFN(x)
  --   4. normalización de capa
  -- (encoder block with residual connections — He et al. 2016)

codificador(secuencia_embeddings, config) → tensor
  -- Pasa la secuencia por codificacion_posicional y luego por
  -- config.num_capas bloques de codificador apilados.
  -- (full transformer encoder)

config_codificador(dim_modelo, num_cabezas, num_capas, dim_ff) → config
  -- Constructor del objeto de configuración.
  -- Inicializa todos los pesos con valores aleatorios pequeños.
  -- (model configuration + weight initialization)
```

---

## Notas de implementación para todas las fases

**Representación de tensor en Zymbol:**
Un tensor se representa como listas anidadas. Una matriz 2×3 es:
```
[[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]
```
No existe un tipo nativo `tensor` — es una convención sobre listas.

**Números aleatorios:**
Zymbol no tiene generador nativo. Los pesos iniciales usarán BashExec
con `python3 -c "import random; ..."` o una tabla de valores precomputados.

**Precisión numérica:**
Floats de Zymbol son suficientes para aprendizaje educativo. No se
busca precisión de producción sino claridad de concepto.
