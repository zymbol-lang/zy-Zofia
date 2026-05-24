# Fundamentos Matemáticos

> Prerequisito para todo lo que sigue en Zofía.
> Si ya conoces álgebra lineal y derivadas, puedes saltar al documento 01.

---

## ¿Por qué matemáticas?

La inteligencia artificial no es magia. Es álgebra lineal + cálculo aplicados
repetidamente sobre muchos números. Entender esas dos áreas permite entender
cualquier modelo de IA, no solo memorizar cómo usarlo.

Este documento cubre exactamente lo que Zofía necesita y nada más.

---

## Parte 1: Escalares, Vectores y Matrices

### Escalar
Un número solo. Sin más contexto.
```
temperatura = 36.5
precio = 1200.0
```
En matemáticas se escribe con minúscula: *a*, *b*, *x*.

---

### Vector
Una lista ordenada de escalares. Representa una dirección y magnitud en el espacio,
o simplemente un conjunto de características de algo.

```
-- Vector de 3 elementos (columna)
v = [1.0, 2.0, 3.0]
```

En matemáticas se escribe con letra negrita minúscula: **v**.
La posición de cada elemento importa: v₁=1.0, v₂=2.0, v₃=3.0.

**Ejemplo real:** el vector de características de un token de texto podría ser
`[0.12, -0.45, 0.87, ...]` con 512 valores.

---

### Matriz
Una tabla rectangular de escalares organizada en filas y columnas.

```
-- Matriz 2×3 (2 filas, 3 columnas)
M = [[1.0, 2.0, 3.0],
     [4.0, 5.0, 6.0]]
```

En matemáticas se escribe con mayúscula: *A*, *M*, *W* (de weights = pesos).
El elemento en fila *i*, columna *j* se escribe Mᵢⱼ: M₁₂ = 2.0.

**Dimensiones:** se escriben como filas × columnas. M es una matriz 2×3.

---

## Parte 2: Operaciones Esenciales

### Suma de vectores (element-wise addition)
Se suma posición por posición. Ambos vectores deben tener la misma longitud.

```
a = [1.0, 2.0, 3.0]
b = [4.0, 5.0, 6.0]

a + b = [1+4, 2+5, 3+6] = [5.0, 7.0, 9.0]
```

Lo mismo aplica para matrices: se suman elemento a elemento.

---

### Multiplicación escalar (scalar multiplication)
Multiplicar cada elemento de un vector o matriz por un número.

```
2.0 × [1.0, 2.0, 3.0] = [2.0, 4.0, 6.0]
```

En redes neuronales, la "tasa de aprendizaje" es un escalar que multiplica
el gradiente para decidir qué tan grande es el paso de ajuste.

---

### Producto punto (dot product)
Multiplica posición a posición y suma todo. El resultado es un solo número.

```
a = [1.0, 2.0, 3.0]
b = [4.0, 5.0, 6.0]

a · b = (1×4) + (2×5) + (3×6) = 4 + 10 + 18 = 32.0
```

**Fórmula general:** a · b = Σᵢ aᵢ × bᵢ

**Por qué importa:** el producto punto mide cuán similares son dos vectores.
Si da un número grande positivo, apuntan en la misma dirección.
Si da cero, son perpendiculares (ortogonales, sin relación).
Este es el corazón del mecanismo de atención.

---

### Multiplicación de matrices (matrix multiplication)
Combina dos matrices produciendo una nueva. Es la operación más usada en redes neuronales.

Para multiplicar A (m×k) por B (k×n), el número de columnas de A
debe ser igual al número de filas de B. El resultado es una matriz m×n.

```
A = [[1, 2],    -- 2×2
     [3, 4]]

B = [[5, 6],    -- 2×2
     [7, 8]]

AB = [[(1×5 + 2×7), (1×6 + 2×8)],
      [(3×5 + 4×7), (3×6 + 4×8)]]

   = [[19, 22],
      [43, 50]]
```

**Fórmula general:** (AB)ᵢⱼ = Σₖ Aᵢₖ × Bₖⱼ

**Visualización:** la fila *i* de A hace producto punto con la columna *j* de B.

**Por qué importa:** en una capa de red neuronal, los pesos son una matriz W,
la entrada es un vector x, y la salida es W×x. Una red neuronal es esencialmente
multiplicaciones de matrices apiladas.

---

### Transposición (transpose)
Intercambia filas por columnas. Una matriz m×n se convierte en n×m.

```
A = [[1, 2, 3],    -- 2×3
     [4, 5, 6]]

Aᵀ = [[1, 4],     -- 3×2
      [2, 5],
      [3, 6]]
```

**Fórmula:** Aᵀᵢⱼ = Aⱼᵢ

**Uso en atención:** la fórmula de atención usa Q × Kᵀ — multiplicar queries
por claves transpuestas para obtener puntuaciones de similitud.

---

## Parte 3: Funciones y Derivadas

### ¿Qué es una función?
Una máquina que recibe un número y produce otro.

```
f(x) = x²          -- toma x, devuelve x al cuadrado
f(3) = 9
f(-2) = 4
```

En redes neuronales, la función de pérdida (loss function) toma los pesos
del modelo y devuelve qué tan equivocado está el modelo.

---

### Derivada (derivative)
Mide qué tan rápido cambia la salida de una función cuando cambia levemente su entrada.

```
f(x) = x²
f'(x) = 2x         -- la derivada de x² es 2x
```

**Interpretación:** si x=3, la derivada es 6. Esto significa que si aumentamos
x un poquito, la salida aumenta aproximadamente 6 veces ese poquito.

**Si la derivada es positiva:** la función crece cuando x aumenta.
**Si la derivada es negativa:** la función decrece cuando x aumenta.
**Si la derivada es cero:** estamos en un mínimo o máximo local.

**Fórmula formal:** f'(x) = lím(h→0) [f(x+h) - f(x)] / h

---

### Gradiente (gradient)
La derivada de una función con múltiples entradas. En lugar de un número,
el gradiente es un vector — una derivada parcial por cada variable de entrada.

```
f(x, y) = x² + y²
∂f/∂x = 2x         -- derivada parcial respecto a x
∂f/∂y = 2y         -- derivada parcial respecto a y

∇f = (2x, 2y)      -- el gradiente es el vector de todas las parciales
```

**Interpretación:** el gradiente apunta en la dirección de mayor crecimiento
de la función. El gradiente negativo apunta hacia el mínimo — esa es la
dirección que nos interesa para entrenar un modelo.

---

### Regla de la cadena (chain rule)
Si una función depende de otra, la derivada se multiplica.

```
y = g(x)
z = f(y) = f(g(x))

∂z/∂x = ∂z/∂y × ∂y/∂x
```

**Ejemplo:**
```
y = x²
z = y³ = (x²)³ = x⁶

∂z/∂y = 3y²
∂y/∂x = 2x

∂z/∂x = 3y² × 2x = 3(x²)² × 2x = 6x⁵   ✓ (coincide con derivar x⁶ directamente)
```

**Por qué importa en IA:** en una red neuronal, la pérdida L depende de la
salida, que depende de las activaciones, que dependen de los pesos. Para saber
cómo ajustar cada peso, aplicamos la regla de la cadena hacia atrás a través
de todas las capas. Este proceso se llama retropropagación (backpropagation).

---

## Parte 4: La idea central del aprendizaje

Una red neuronal aprende haciendo esto repetidamente:

```
1. Tomar un ejemplo del conjunto de datos
2. Calcular la predicción con los pesos actuales       [hacia adelante / forward]
3. Medir qué tan equivocada está la predicción         [función de pérdida / loss]
4. Calcular el gradiente de la pérdida respecto a cada peso  [backpropagation]
5. Ajustar cada peso en la dirección opuesta al gradiente    [gradient descent]
6. Repetir miles de veces
```

El paso 5 usa esta fórmula:

```
w ← w - α × ∂L/∂w
```

Donde:
- `w` es un peso del modelo
- `α` (alfa) es la tasa de aprendizaje (learning rate) — qué tan grande es el paso
- `∂L/∂w` es el gradiente — en qué dirección sube la pérdida

Como restamos el gradiente, vamos en la dirección opuesta a la subida, es decir,
hacia donde la pérdida baja. Esto es el descenso de gradiente (gradient descent).

---

## Resumen de notación

| Símbolo | Nombre | Ejemplo |
|---------|--------|---------|
| *a*, *b* | Escalar | 3.14 |
| **v** | Vector | [1, 2, 3] |
| *A*, *W* | Matriz | [[1,2],[3,4]] |
| Aᵀ | Transpuesta | Intercambia filas/columnas |
| a · b | Producto punto | Σᵢ aᵢbᵢ |
| AB | Producto matricial | Σₖ AᵢₖBₖⱼ |
| f'(x) | Derivada | Velocidad de cambio |
| ∂f/∂x | Derivada parcial | Derivada respecto a x solamente |
| ∇f | Gradiente | Vector de todas las parciales |
| α | Tasa de aprendizaje | Controla tamaño del paso |
| L | Pérdida (loss) | Qué tan equivocado está el modelo |

---

## Ejercicios de verificación

Antes de avanzar al documento 01, verificar que puedes responder:

1. ¿Cuánto da [2, 3] · [4, -1]?
2. ¿Qué forma tiene el resultado de multiplicar una matriz 3×4 por una 4×2?
3. ¿La derivada de f(x) = 3x² - 2x + 1 es...?
4. Si el gradiente de la pérdida respecto a un peso es 0.5 y la tasa de
   aprendizaje es 0.1, ¿cuánto cambia el peso?

Respuestas: 1) 5.0  2) 3×2  3) 6x - 2  4) se resta 0.05 (w ← w - 0.1×0.5)
