# Sistema de control de cortina motorizada

Trabajo práctico final de **Sistemas de Control I** — Facultad de Ciencias Exactas, Físicas y Naturales, Universidad Nacional de Córdoba (2026).

**Autores:** Barron Saez, Lautaro · Krede, Julián

## Descripción

Se modela y controla la **posición** de una cortina enrollable de lino (1,4 m × 1,2 m, 1,336 kg con contrapeso) accionada por un motor de corriente continua. El trabajo incluye:

1. Modelado matemático de cada bloque del sistema (motor, caja reductora, encoder, conversor y driver).
2. Análisis de la planta a lazo abierto: estabilidad, polos dominantes, respuesta temporal y error en estado estable.
3. Diseño analítico de un controlador **PD** por asignación de polos sobre un modelo simplificado.
4. Verificación del sistema controlado, primero en el modelo lineal y luego con **no linealidades** (saturación y zona muerta) en Scilab/Xcos.

### Hardware considerado

| Componente | Modelo | Función |
|---|---|---|
| Motor DC | Faulhaber 2250-BX4 (24 V) | Actuador |
| Caja reductora | Faulhaber 26A, 40:1 | Adaptar torque e inercia |
| Encoder incremental | Faulhaber IE3-1024 (1024 pulsos/rev) | Sensor de posición |
| Microcontrolador | Arduino Uno R3 | Comparador, controlador y generación de PWM |
| Driver de potencia | Puente H IBT-2 | Amplificar la señal de 0–5 V a 0–24 V |

## Resultados principales

**Planta a lazo abierto**

$$FT_{LA}(s) = \frac{1{,}028\cdot10^{6}}{s\,(s^2 + 2{,}36\cdot10^{4}\,s + 5{,}18\cdot10^{6})}$$

- Polos: $s = 0$, $s = -221{,}5$ (mecánico, dominante, $\tau_m \approx 4{,}5$ ms) y $s = -23381$ (eléctrico).
- Sistema **tipo 1** y **marginalmente estable**: hace falta realimentación para controlar la posición.

**Especificaciones de diseño**

- Tiempo de establecimiento $t_s \approx 8$ s (el mínimo teórico es 5 s).
- Sobrepasamiento nulo ($M_p = 0$), para no golpear los topes mecánicos.
- Error en estado estable nulo ante un escalón.

**Controlador PD**

$$C(s) = K_p + K_d\,s = 2{,}5 + 0{,}5\,s$$

No se usa acción integral: la planta ya es tipo 1 y así se evita el *windup* durante la saturación.

| Caso | $t_s$ | Sobrepasamiento | Error en estado estable |
|---|---|---|---|
| Modelo lineal | ≈ 8,5 s | 0 | 0 (llega a 80 rad, o sea 1,2 m) |
| Con saturación (±24 V) y zona muerta (±0,39 V) | ≈ 11 s | 0 | ≈ 3400 pulsos (≈ 0,76 cm) |

## Estructura del repositorio

```
.
├── modelado.m                  # Modelado, análisis y diseño del PD (Octave/MATLAB)
├── Simulaciones/               # Diagramas de Scilab/Xcos (formato .ssp)
│   ├── TP_Final_planta.ssp            # Planta a lazo abierto
│   ├── TP_Final_modelo_lineal.ssp     # Sistema controlado lineal
│   └── TP_Final_no_linealidades.ssp   # Sistema controlado con saturación y zona muerta
└── informe/                    # Informe en LaTeX
    ├── TPFinal.tex                    # Documento principal
    ├── TPFinal.pdf                    # Informe compilado
    ├── librerias.tex                  # Paquetes y configuración
    ├── portada.tex, introduccion.tex, def_del_problema.tex,
    │   analisis_del_sistema.tex, especificaciones.tex,
    │   diseño_del_controlador.tex, sistema_controlado.tex,
    │   conclusiones.tex, bibliografia.tex
    └── img/                           # Figuras y diagramas
```

## Cómo usarlo

### Script de modelado

El script está escrito para **GNU Octave** con el paquete `control`:

```bash
octave --eval "pkg install -forge control"   # solo la primera vez
octave modelado.m
```

Muestra la función de transferencia a lazo abierto y sus polos, calcula $K_p$ y $K_d$, y grafica la respuesta de la planta a 24 V y la respuesta del sistema controlado a un recorrido completo (521518 pulsos).

> Para correrlo en MATLAB hay que borrar la línea `pkg load control;` (requiere el Control System Toolbox).

### Simulaciones

Los archivos `.ssp` se abren con **Scilab 2026.0** (Xcos). Se generaron con esa versión, así que versiones anteriores podrían no abrirlos.

### Informe

Se compila con `pdflatex` desde la carpeta `informe/`. Hay que compilar dos veces para que se generen el índice y las referencias:

```bash
cd informe
pdflatex TPFinal.tex
pdflatex TPFinal.tex
```

O con `latexmk -pdf TPFinal.tex`.
