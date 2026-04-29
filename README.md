# Programas en TASM (Turbo Assembler)

Coleccion de programas en lenguaje ensamblador (Turbo Assembler) para DOS.

## Requisitos

- **TASM** (Turbo Assembler) y **TLINK** (Turbo Linker)
- Sistema operativo DOS o emulador como **DOSBox**

---

## 1. LOGIN.ASM - Ventana de Inicio de Sesion

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

## 2. LINK.ASM - Animacion de Link (Pixel Art)

Programa que muestra una imagen de Link (The Legend of Zelda) en pixel art con un efecto de animacion de onda sinusoidal en modo VGA 13h (320x200, 256 colores).

### Caracteristicas

- Sprite de Link de 40x48 pixeles, escalado a 120x144 en pantalla
- Paleta de 16 colores optimizada desde la imagen original
- Efecto de onda sinusoidal que desplaza horizontalmente cada fila del sprite
- Animacion fluida sincronizada con el retrace vertical del monitor
- Presionar cualquier tecla para salir

### Compilacion y Ejecucion

```bash
TASM LINK.ASM
TLINK LINK.OBJ
LINK.EXE
```

### Controles

| Tecla         | Accion              |
|---------------|---------------------|
| Cualquier tecla | Salir del programa |
