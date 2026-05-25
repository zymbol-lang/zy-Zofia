# Hoja de Ruta — Zofía

## Principio de construcción

Cada fase produce módulos Zymbol funcionales y ejemplos ejecutables.
Una fase no comienza hasta que la anterior pasa todos sus ejemplos.
Los documentos de diseño se aprueban antes de escribir una sola línea de código.

Zofía es el segundo ciclo de retroalimentación Zymbol (el primero fue Serpiente v0.0.5).
Los GAPs e IDEAs descubiertos se documentan en `HALLAZGOS.md` y alimentan el roadmap
de Zymbol v0.0.6.

---

## Prerequisitos de Zymbol por fase

> **Actualización v0.0.6 (2026-05-24):** todos los GAPs identificados en la Fase 0
> fueron resueltos durante el análisis empírico. No se requiere ningún módulo de
> workaround matemático — `std/math` y `std/random` cubren el 100% de las necesidades.

| Fase | Prerequisitos Zymbol | GAPs | Estado |
|------|----------------------|------|--------|
| Fase 1 — tensor | listas, aritmética, loops, `$~` profundo | — | ✅ Zymbol v0.0.6 listo |
| Fase 2 — grad | todo lo anterior + `$~` en named tuples | — | ✅ Zymbol v0.0.6 listo |
| Fase 3 — activacion | todo lo anterior + `mat::tanh`, `mat::sigmoid` | — | ✅ Zymbol v0.0.6 listo |
| Fase 4 — atencion | todo lo anterior + `mat::sqrt`, `mat::exp` | — | ✅ Zymbol v0.0.6 listo |
| Fase 5 — transformador | todo lo anterior + `mat::sin`, `mat::cos`, `mat.PI`, `std/random` | — | ✅ Zymbol v0.0.6 listo |

**Todas las fases pueden implementarse con `<# std/math => mat` directamente.**
El módulo de workaround `modulos/matematica.zy` ya no es necesario.

---

## Fase 0 — Diseño y análisis de brechas ✅ COMPLETO

**Objetivo:** documentar todos los conceptos antes de codificar e identificar
empíricamente qué capacidades de Zymbol son necesarias para Zofia.

### Documentos de diseño

| Documento | Estado |
|-----------|--------|
| `docs/00_fundamentos_matematicos.md` | ✅ Completo |
| `docs/01_tensores.md` | ✅ Completo |
| `docs/02_gradientes_y_optimizacion.md` | ✅ Completo |
| `docs/03_redes_neuronales.md` | ✅ Completo |
| `docs/04_mecanismo_de_atencion.md` | ✅ Completo |
| `docs/05_arquitectura_transformer.md` | ✅ Completo |
| `DISEÑO_API.md` | ✅ Completo |
| `ANALISIS_FASE0.md` | ✅ Completo — análisis empírico de 5 gaps, todos resueltos |
| `EVALUACION_MATEMATICA.md` | ✅ Actualizado a v0.0.6 — cobertura 100% |
| `HALLAZGOS.md` | ✅ Actualizado — GAP-Z001 a Z009 todos resueltos |

### Tests de validación (`tests/`)

Seis pares de archivos `.zy` / `.expected` que verifican empíricamente las
capacidades de Zymbol necesarias para Zofia. Todos en verde con Zymbol v0.0.6.

| Test | Qué verifica | Estado |
|------|-------------|--------|
| `tensor_basico.zy` | Creación de matrices, acceso `m[i>j]`, deep update `m[i>j]$~ val` | ✅ PASS |
| `tensor_ops.zy` | `sumar_vec`, `restar_vec`, `escalar_vec`, `dot` con `$>` / `$<` | ✅ PASS |
| `matmul.zy` | Multiplicación matricial general `[2×2] × [2×2]` | ✅ PASS |
| `activacion.zy` | `relu`, `mat::tanh`, `mat::sigmoid` nativos de `std/math` | ✅ PASS |
| `perdida_mse.zy` | MSE y gradiente de pérdida con funciones aritméticas mixtas | ✅ PASS |
| `forward_pass.zy` | Forward pass de 2 capas con `proyectar` + activaciones HOF | ✅ PASS |

### Gaps del lenguaje identificados y resueltos

| Gap | Descripción | Estado |
|-----|-------------|--------|
| G1 (GAP-Z006) | `arr[i>j]$~ val` — deep update canónico | ✅ Resuelto v0.0.6 |
| G2 (GAP-Z007) | `$~` en tuplas nombradas por posición y nombre | ✅ Resuelto v0.0.6 |
| G3 (GAP-Z001) | `tanh`, `sigmoid`, `tan`, `asin`/`acos`/`atan`, `sinh`/`cosh` en `std/math` | ✅ Resuelto v0.0.6 |
| G4 (GAP-Z008) | Inferencia numérica monomorfa — funciones aritméticas bloqueaban Float | ✅ Resuelto v0.0.6 |
| G7 (GAP-Z009) | Funciones nombradas como HOF perdían aliases de módulo | ✅ Resuelto v0.0.6 |

**La Fase 1 puede comenzar.**

---

## Fase 1 — Módulo Tensor (`modulos/tensor.zy`)

**Qué se construye:** representación y operaciones sobre tensores N-dimensionales
implementados como listas anidadas en Zymbol.

**Funciones a implementar:**

```
crear             -- (forma, valor_inicial) → tensor
forma_de          -- (tensor) → lista de enteros
elemento          -- (tensor, indices) → número
sumar             -- (a, b) → tensor  [elemento a elemento]
restar            -- (a, b) → tensor
multiplicar_escalar -- (tensor, escalar) → tensor
producto_punto    -- (vec_a, vec_b) → escalar
producto_matricial -- (mat_a, mat_b) → matriz
transponer        -- (matriz) → matriz
aplanar           -- (tensor) → lista
reformar          -- (tensor, nueva_forma) → tensor
imprimir          -- (tensor) → ninguno
```

**Ejemplos al completar:**
- `01_tensor_basico.zy` — crear tensores, acceder elementos, imprimir forma
- `02_producto_matricial.zy` — multiplicar matrices, verificar dimensiones

**Criterio de aceptación:** los 6 ejemplos de álgebra lineal de
`docs/00_fundamentos_matematicos.md` corren sin errores.

---

## Fase 2 — Módulo Gradiente (`modulos/grad.zy`)

**Qué se construye:** sistema de variables con seguimiento de gradiente
y retropropagación manual por regla de la cadena.

**Funciones a implementar:**

```
variable          -- (valor, nombre) → variable_con_grad
hacia_adelante    -- (expresion) → valor
retropropagar     -- (variable_perdida) → ninguno   [backpropagation]
gradiente_de      -- (variable) → tensor
paso_gradiente    -- (variables, tasa) → ninguno    [gradient step]
mse               -- (prediccion, objetivo) → escalar [mean squared error]
```

**Ejemplos al completar:**
- `03_descenso_gradiente.zy` — encontrar el mínimo de f(x) = x² con gradiente

**Criterio de aceptación:** converger al mínimo de una función cuadrática
en menos de 100 pasos con tasa de aprendizaje 0.1.

---

## Fase 3 — Activaciones y Pérdida

**Módulo `modulos/activacion.zy`:**

```
relu              -- (x) → número o tensor
sigmoide          -- (x) → número o tensor    [sigmoid]
softmax           -- (vector) → vector de probabilidades
tangente_hiperbolica -- (x) → número          [tanh]
```

**Módulo `modulos/perdida.zy`:**

```
mse               -- (prediccion, objetivo) → escalar
entropia_cruzada  -- (prediccion, objetivo) → escalar  [cross entropy]
entropia_cruzada_binaria -- (prediccion, objetivo) → escalar
```

**Ejemplos al completar:**
- `04_red_simple.zy` — red de 2 capas que aprende XOR (el problema clásico)

**Criterio de aceptación:** la red aprende XOR en menos de 1000 épocas.

---

## Fase 4 — Mecanismo de Atención (`modulos/atencion.zy`)

**Qué se construye:** scaled dot-product attention y multi-head attention
como se describe en Vaswani et al. (2017).

**Funciones a implementar:**

```
atencion_producto_punto  -- (consulta, clave, valor) → tensor
                         -- [scaled dot-product attention]
atencion_enmascarada     -- (consulta, clave, valor, mascara) → tensor
proyectar                -- (x, pesos) → tensor        [linear projection]
atencion_multiencabezado -- (consulta, clave, valor, config) → tensor
                         -- [multi-head attention]
```

**Ejemplos al completar:**
- `05_atencion_simple.zy` — calcular atención sobre una secuencia de 4 tokens

**Criterio de aceptación:** las puntuaciones de atención suman 1 por fila
(propiedad del softmax).

---

## Fase 5 — Arquitectura Transformer (`modulos/transformador.zy`)

**Qué se construye:** un encoder transformer completo con positional encoding,
multi-head attention, feed-forward network y layer normalization.

**Funciones a implementar:**

```
codificacion_posicional  -- (posicion, dim_modelo) → vector
                         -- [positional encoding]
normalizar_capa          -- (x, gamma, beta) → tensor   [layer normalization]
capa_feed_adelante       -- (x, pesos_1, sesgo_1, pesos_2, sesgo_2) → tensor
                         -- [feed-forward network]
bloque_codificador       -- (x, config) → tensor       [encoder block]
codificador              -- (secuencia, config) → tensor [full encoder]
```

**Ejemplos al completar:**
- `06_transformer_encoder.zy` — pasar una secuencia de 5 tokens por un encoder
  de 2 capas y 2 cabezas de atención

**Criterio de aceptación:** la salida tiene la misma forma que la entrada
(el encoder preserva las dimensiones).

---

## Criterio global de completitud

El proyecto Zofía se considera completo cuando:

1. Los 6 documentos de `docs/` explican cada concepto con intuición + matemática + código
2. Los 6 módulos Zymbol pasan todos sus ejemplos
3. El ejemplo `06_transformer_encoder.zy` corre de extremo a extremo
4. Cada función tiene comentario con referencia a su fuente matemática

---

## Lo que Zofía no hace (deliberadamente)

- No implementa entrenamiento distribuido
- No implementa GPU / aceleración hardware
- No implementa el decoder del transformer (solo encoder)
- No compite en velocidad con PyTorch — compite en claridad

La versión 2 de Zofía puede extender cualquiera de estos puntos.
