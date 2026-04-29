# Practicas TASM - Ensamblador x86

Coleccion de programas en lenguaje ensamblador (Turbo Assembler) para DOS.

## Requisitos

- **TASM** (Turbo Assembler) y **TLINK** (Turbo Linker)
- Sistema operativo DOS o emulador como **DOSBox**

---

## 1. Ventana de Inicio de Sesion (`LOGIN.ASM`)

Programa que muestra una ventana de inicio de sesion en modo texto DOS (80x25).

### Caracteristicas

- Ventana con marco doble centrada en pantalla
- Titulo "INICIO DE SESION" en la parte superior
- Campo de **Usuario** (maximo 20 caracteres)
- Campo de **Contrasena** (maximo 20 caracteres, se muestra con asteriscos `*`)
- Soporte para tecla `Backspace` para corregir entrada
- Tecla `Esc` para salir en cualquier momento
- Tecla `Enter` para confirmar cada campo
- Mensaje de bienvenida al completar ambos campos

### Compilacion y Ejecucion

```bash
TASM LOGIN.ASM
TLINK LOGIN.OBJ
LOGIN.EXE
```

### Controles

| Tecla     | Accion                          |
|-----------|---------------------------------|
| Letras    | Escribir en el campo activo     |
| Backspace | Borrar ultimo caracter          |
| Enter     | Confirmar campo / continuar     |
| Esc       | Salir del programa              |

---

## 2. Animacion de Link estilo Street Fighter (`LINK_FIGHTER.ASM`)

Animacion en modo grafico VGA 13h (320x200, 256 colores) de Link (The Legend of Zelda) con estilo de juego de pelea tipo Street Fighter. El personaje se muestra en un escenario tipo arena con barra de vida, efectos de ataque, y animacion de respiracion.

### Caracteristicas

- **Modo grafico VGA 13h** (320x200, 256 colores)
- **Paleta personalizada** de 21 colores optimizados para el personaje
- **Sprite de Link** compuesto por partes del cuerpo (sombrero, cabello, tunica, espada, escudo, botas)
- **4 frames de animacion:**
  - Idle 1 y 2 (animacion de respiracion automatica)
  - Ataque de espada (estocada horizontal con efecto de slash)
  - Patada (pierna extendida con efecto de impacto)
- **Escenario tipo arena** con cielo, piso de piedra, pilares decorativos y borde naranja
- **Interfaz estilo Street Fighter:** barra de HP, nombre "LINK", titulo "HYRULE ARENA"
- **Intro cinematica** con "ROUND 1" y "FIGHT!" antes de iniciar
- **Sombra dinamica** debajo del personaje
- **Efectos visuales** de slash blanco (espada) y destello amarillo (patada)
- **Sincronizacion con retrazo vertical** para animacion sin parpadeo

### Compilacion y Ejecucion

```bash
TASM LINK_FIGHTER.ASM
TLINK LINK_FIGHTER.OBJ
LINK_FIGHTER.EXE
```

### Controles

| Tecla         | Accion                              |
|---------------|-------------------------------------|
| Flecha Izq    | Mover a Link hacia la izquierda     |
| Flecha Der    | Mover a Link hacia la derecha       |
| Z             | Ataque de espada (estocada)         |
| X             | Patada                              |
| Esc           | Salir del programa                  |

### Detalles Tecnicos

- Usa escritura directa a la memoria de video VGA (`A000h:0000`)
- Sprites definidos como tablas de partes rectangulares (dx, dy, ancho, alto, color)
- Animacion basada en datos: cada frame es una lista de rectangulos coloreados
- Clipping de pantalla para evitar escrituras fuera de limites
- Calculo optimizado de offset: `y * 320 = y * 256 + y * 64` usando shifts
- Uso de `REP STOSB` para llenado rapido de rectangulos
