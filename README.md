# Zofía — Inteligencia Artificial desde Cero en Zymbol

> Caso de estudio educativo · Escrito completamente en español · Para hispanohablantes  
> Proyecto driver de **Zymbol v0.0.6** — requiere intérprete `>= v0.0.6`

---

## ¿Qué es Zofía?

Zofía es la implementación desde cero de los bloques fundamentales de la
inteligencia artificial moderna, escrita completamente en **Zymbol** y
documentada en español para estudiantes y desarrolladores hispanohablantes.

No es un wrapper de PyTorch ni TensorFlow. Es la construcción manual, pieza
a pieza, de las mismas herramientas matemáticas que usan esos sistemas — para
que quien las construya entienda exactamente qué hace cada línea y por qué.

El nombre viene de Zofía Kowalewska — matemática del siglo XIX que dedicó su
vida a demostrar que las matemáticas pertenecen a todos, sin importar el origen.

---

## ¿Por qué construirlo desde cero?

Usar PyTorch o TensorFlow para aprender inteligencia artificial es como
aprender a cocinar en un restaurante con todo preparado. Funciona para
producir platos, pero no enseña a entender los ingredientes.

Construir las herramientas desde cero obliga a responder las preguntas que
las bibliotecas esconden:

- ¿Por qué un tensor? ¿Qué forma tiene y por qué importa?
- ¿Cómo sabe una red neuronal en qué dirección mejorar?
- ¿Qué significa exactamente "prestar atención" en un transformer?
- ¿Por qué dividimos por √dₖ en el mecanismo de atención?

Zofía responde cada una de esas preguntas con código que puedes leer,
modificar y entender completamente.

---

## ¿Para quién es?

- Desarrolladores hispanohablantes que quieren aprender IA desde las bases
- Estudiantes de ingeniería o matemáticas que prefieren aprender con código
- Personas que conocen los conceptos de IA "a 10.000 metros de altura"
  y quieren bajar al terreno
- Cualquiera que prefiera leer código en español

No se requieren conocimientos previos de IA. Se requiere saber programar y
tener disposición para trabajar con matemáticas básicas (álgebra, funciones).

---

## El camino de aprendizaje

```
Fundamentos matemáticos
        │
        ▼
    Tensores          ← representar datos en N dimensiones
        │
        ▼
 Gradientes y         ← cómo aprende una red
  optimización
        │
        ▼
  Redes neuronales    ← combinar lo anterior en una red real
        │
        ▼
Mecanismo de          ← el corazón del transformer
  atención
        │
        ▼
 Arquitectura         ← el modelo que cambió la IA moderna
 Transformer
```

Cada paso construye sobre el anterior. No hay saltos.

---

## Estructura del proyecto

```
Zofía/
  README.md              # Este archivo
  HOJA_DE_RUTA.md        # Fases de implementación
  DISEÑO_API.md          # Contratos de todos los módulos Zymbol
  docs/
    00_fundamentos_matematicos.md    # Álgebra lineal y cálculo esencial
    01_tensores.md                   # Qué es un tensor y por qué existe
    02_gradientes_y_optimizacion.md  # Cómo aprende un modelo
    03_redes_neuronales.md           # De la neurona al perceptrón multicapa
    04_mecanismo_de_atencion.md      # Scaled dot-product y multi-head attention
    05_arquitectura_transformer.md   # El modelo completo
  modulos/
    tensor.zy         # FASE 1: operaciones tensoriales
    grad.zy           # FASE 2: autodiferenciación
    activacion.zy     # FASE 3: funciones de activación
    perdida.zy        # FASE 3: funciones de pérdida
    atencion.zy       # FASE 4: mecanismo de atención
    transformador.zy  # FASE 5: arquitectura completa
  ejemplos/
    01_tensor_basico.zy
    02_producto_matricial.zy
    03_descenso_gradiente.zy
    04_red_simple.zy
    05_atencion_simple.zy
    06_transformer_encoder.zy
```

---

## Convenciones del proyecto

| Aspecto | Convención |
|---------|------------|
| Código Zymbol | Todo en español: variables, funciones, comentarios |
| Referencias técnicas | Término en inglés entre paréntesis al introducirlo |
| Fórmulas matemáticas | Notación estándar con explicación en español |
| Citas | Apellido, año, título en inglés (fuente original) |
| Nombres de archivos | snake_case en español |

---

## Referencias principales

- Vaswani et al. (2017) — *Attention Is All You Need*
- Goodfellow, Bengio, Courville (2016) — *Deep Learning*
- Nielsen (2015) — *Neural Networks and Deep Learning* (libro libre en línea)
- Ruder (2016) — *An Overview of Gradient Descent Optimization Algorithms*

---

## Estado

> **Fase actual:** Diseño completo — sin código implementado  
> El código Zymbol se escribe después de aprobar todos los documentos de diseño.

---

## Versión de Zymbol

Zofía requiere **Zymbol v0.0.6** o superior. Las siguientes características de v0.0.6
son necesarias para la implementación:

| Característica | Para qué se usa en Zofía |
|----------------|--------------------------|
| Global `:=` scope | Constantes matemáticas (`PI`, `E`) visibles en todas las funciones |
| `#.###\|x\|` formatting | Salida legible de tensores (4 decimales) |
| `^` float exponents | `sqrt(x) = x^0.5`, `exp(x) = E^x` sin módulo externo |
| `std/matematica` (propuesto) | `sin`, `cos`, `ln` para encoding posicional y activaciones |

Repositorio del intérprete: [zymbol-lang/interpreter](https://github.com/zymbol-lang/interpreter)
