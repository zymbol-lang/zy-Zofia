# Tests de Zofia

Pruebas de validación para los módulos de Zofia.
Cada archivo `.zy` tiene un `.expected` correspondiente.

## Estructura

```
tests/
  tensor_basico.zy / .expected   — crear, acceder, imprimir tensores
  tensor_ops.zy / .expected      — suma, resta, multiplicación escalar, producto punto
  matmul.zy / .expected          — multiplicación matricial general n×n
  activacion.zy / .expected      — relu, tanh, sigmoid sobre escalares
  perdida_mse.zy / .expected     — MSE loss y gradiente MSE
  forward_pass.zy / .expected    — forward pass completo red 2 capas
```

## Ejecutar

```bash
cd /home/rakzo/github/zymbol-lang/interpreter
bash tests/scripts/run_zofia.sh
```

O individualmente:
```bash
cargo run --bin zymbol -- run ../Zofia/tests/tensor_basico.zy
```

## Estado

| Archivo | Estado | Depende de |
|---------|--------|------------|
| `tensor_basico.zy` | ✅ listo | — |
| `tensor_ops.zy` | ✅ listo | — |
| `matmul.zy` | ✅ listo | — |
| `activacion.zy` | ✅ listo (tanh/sigmoid locales) | — |
| `perdida_mse.zy` | ✅ listo | — |
| `forward_pass.zy` | ✅ listo (activación inline) | — |

### Brechas del lenguaje documentadas en ANALISIS_FASE0.md

| ID | Brecha | Bloquea |
|----|--------|---------|
| G1 | `m[i>j] = val` no soportado | tensor directo, atencion |
| G2 | `t.campo = val` no soportado | grad |
| G3 | `tanh`, `sigmoid` faltan en `std/math` | activacion (cubierto con impl local) |
| G4 | Inferencia de tipo bloquea polimorfismo numérico | robustez general |
| G7 | Alias de módulo no capturado en HOF | activacion genérica, atencion |
