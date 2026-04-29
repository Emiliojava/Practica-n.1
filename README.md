# Ventana de Inicio de Sesion - TASM

Programa en lenguaje ensamblador (Turbo Assembler) que muestra una ventana de inicio de sesion en modo texto DOS (80x25).

## Caracteristicas

- Ventana con marco doble centrada en pantalla
- Titulo "INICIO DE SESION" en la parte superior
- Campo de **Usuario** (maximo 20 caracteres)
- Campo de **Contrasena** (maximo 20 caracteres, se muestra con asteriscos `*`)
- Soporte para tecla `Backspace` para corregir entrada
- Tecla `Esc` para salir en cualquier momento
- Tecla `Enter` para confirmar cada campo
- Mensaje de bienvenida al completar ambos campos

## Requisitos

- **TASM** (Turbo Assembler) y **TLINK** (Turbo Linker)
- Sistema operativo DOS o emulador como **DOSBox**

## Compilacion y Ejecucion

```bash
# Ensamblar
TASM LOGIN.ASM

# Enlazar
TLINK LOGIN.OBJ

# Ejecutar
LOGIN.EXE
```

## Controles

| Tecla     | Accion                          |
|-----------|---------------------------------|
| Letras    | Escribir en el campo activo     |
| Backspace | Borrar ultimo caracter          |
| Enter     | Confirmar campo / continuar     |
| Esc       | Salir del programa              |
