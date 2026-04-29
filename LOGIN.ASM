;====================================================================
; LOGIN.ASM - Ventana de Inicio de Sesion
; Ensamblador: TASM (Turbo Assembler)
; Modo: Texto 80x25 (DOS)
;
; Descripcion:
;   Dibuja una ventana centrada con titulo, campo de usuario
;   (max 20 caracteres) y campo de contrasena (max 20 caracteres).
;   La contrasena se muestra con asteriscos (*).
;====================================================================

.MODEL SMALL
.STACK 256

;--------------------------------------------------------------------
; Segmento de datos
;--------------------------------------------------------------------
.DATA

    ; --- Colores ---
    COLOR_FONDO     EQU 1Fh    ; Fondo azul, texto blanco brillante
    COLOR_BORDE     EQU 1Eh    ; Fondo azul, texto amarillo
    COLOR_TITULO    EQU 1Eh    ; Fondo azul, texto amarillo
    COLOR_CAMPO     EQU 70h    ; Fondo gris, texto negro
    COLOR_PANTALLA  EQU 17h    ; Fondo azul, texto blanco

    ; --- Dimensiones de la ventana ---
    VENTANA_FILA1   EQU 5      ; Fila superior
    VENTANA_FILA2   EQU 19     ; Fila inferior
    VENTANA_COL1    EQU 20     ; Columna izquierda
    VENTANA_COL2    EQU 59     ; Columna derecha

    ; --- Mensajes ---
    TITULO          DB 'INICIO DE SESION', 0
    MSG_USUARIO     DB 'Usuario:', 0
    MSG_CONTRASENA  DB 'Contrasena:', 0
    MSG_PRESIONE    DB 'Enter para aceptar | Esc para salir', 0
    MSG_BIENVENIDA  DB 'Bienvenido, ', 0
    MSG_ERROR       DB 'Campos vacios. Intente de nuevo.', 0
    MSG_SALIR       DB 'Saliendo del programa...', 0

    ; --- Buffers de entrada ---
    MAX_CHARS       EQU 20
    BUFFER_USR      DB 21 DUP(0)    ; Buffer usuario (20 + null)
    BUFFER_PWD      DB 21 DUP(0)    ; Buffer contrasena (20 + null)
    LEN_USR         DB 0            ; Longitud actual usuario
    LEN_PWD         DB 0            ; Longitud actual contrasena

    ; --- Caracteres para el marco ---
    ESQUINA_SUP_IZQ DB 0C9h    ; +
    ESQUINA_SUP_DER DB 0BBh    ; +
    ESQUINA_INF_IZQ DB 0C8h    ; +
    ESQUINA_INF_DER DB 0BCh    ; +
    LINEA_HOR       DB 0CDh    ; =
    LINEA_VER       DB 0BAh    ; |
    LINEA_HOR_S     DB 0C4h    ; -  (linea simple)

;--------------------------------------------------------------------
; Segmento de codigo
;--------------------------------------------------------------------
.CODE

INICIO:
    MOV AX, @DATA
    MOV DS, AX
    MOV ES, AX

    ; --- Establecer modo de video texto 80x25 ---
    MOV AX, 0003h
    INT 10h

    ; --- Ocultar cursor ---
    MOV AH, 01h
    MOV CX, 2607h
    INT 10h

    ; --- Limpiar pantalla con color de fondo ---
    CALL LIMPIAR_PANTALLA

    ; --- Dibujar la ventana ---
    CALL DIBUJAR_VENTANA

    ; --- Mostrar titulo ---
    CALL MOSTRAR_TITULO

    ; --- Mostrar etiquetas ---
    CALL MOSTRAR_ETIQUETAS

    ; --- Mostrar campos de entrada ---
    CALL DIBUJAR_CAMPOS

    ; --- Mostrar instrucciones ---
    CALL MOSTRAR_INSTRUCCIONES

    ; --- Leer usuario ---
    CALL LEER_USUARIO

    ; --- Leer contrasena ---
    CALL LEER_CONTRASENA

    ; --- Mostrar mensaje de bienvenida ---
    CALL MOSTRAR_BIENVENIDA

    ; --- Esperar tecla para salir ---
    MOV AH, 00h
    INT 16h

    ; --- Restaurar cursor ---
    MOV AH, 01h
    MOV CX, 0607h
    INT 10h

    ; --- Restaurar modo de video ---
    MOV AX, 0003h
    INT 10h

    ; --- Terminar programa ---
    MOV AX, 4C00h
    INT 21h

;====================================================================
; PROCEDIMIENTOS
;====================================================================

;--------------------------------------------------------------------
; LIMPIAR_PANTALLA - Llena la pantalla con color de fondo
;--------------------------------------------------------------------
LIMPIAR_PANTALLA PROC
    MOV AX, 0600h          ; Scroll up, limpiar ventana
    MOV BH, COLOR_PANTALLA  ; Atributo
    MOV CX, 0000h          ; Esquina sup izq (0,0)
    MOV DX, 184Fh          ; Esquina inf der (24,79)
    INT 10h
    RET
LIMPIAR_PANTALLA ENDP

;--------------------------------------------------------------------
; DIBUJAR_VENTANA - Dibuja el marco de la ventana
;--------------------------------------------------------------------
DIBUJAR_VENTANA PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; --- Limpiar area de la ventana ---
    MOV AX, 0600h
    MOV BH, COLOR_FONDO
    MOV CH, VENTANA_FILA1
    MOV CL, VENTANA_COL1
    MOV DH, VENTANA_FILA2
    MOV DL, VENTANA_COL2
    INT 10h

    ; --- Esquina superior izquierda ---
    MOV DH, VENTANA_FILA1
    MOV DL, VENTANA_COL1
    MOV BL, COLOR_BORDE
    MOV AL, ESQUINA_SUP_IZQ
    CALL ESCRIBIR_CHAR_POS

    ; --- Linea horizontal superior ---
    MOV CX, VENTANA_COL2 - VENTANA_COL1 - 1
    MOV DL, VENTANA_COL1 + 1
LINEA_SUP:
    MOV AL, LINEA_HOR
    CALL ESCRIBIR_CHAR_POS
    INC DL
    LOOP LINEA_SUP

    ; --- Esquina superior derecha ---
    MOV DL, VENTANA_COL2
    MOV AL, ESQUINA_SUP_DER
    CALL ESCRIBIR_CHAR_POS

    ; --- Lineas verticales izquierda y derecha ---
    MOV CX, VENTANA_FILA2 - VENTANA_FILA1 - 1
    MOV DH, VENTANA_FILA1 + 1
LINEAS_VERT:
    MOV DL, VENTANA_COL1
    MOV AL, LINEA_VER
    CALL ESCRIBIR_CHAR_POS
    MOV DL, VENTANA_COL2
    CALL ESCRIBIR_CHAR_POS
    INC DH
    LOOP LINEAS_VERT

    ; --- Esquina inferior izquierda ---
    MOV DH, VENTANA_FILA2
    MOV DL, VENTANA_COL1
    MOV AL, ESQUINA_INF_IZQ
    CALL ESCRIBIR_CHAR_POS

    ; --- Linea horizontal inferior ---
    MOV CX, VENTANA_COL2 - VENTANA_COL1 - 1
    MOV DL, VENTANA_COL1 + 1
LINEA_INF:
    MOV AL, LINEA_HOR
    CALL ESCRIBIR_CHAR_POS
    INC DL
    LOOP LINEA_INF

    ; --- Esquina inferior derecha ---
    MOV DL, VENTANA_COL2
    MOV AL, ESQUINA_INF_DER
    CALL ESCRIBIR_CHAR_POS

    POP DX
    POP CX
    POP BX
    POP AX
    RET
DIBUJAR_VENTANA ENDP

;--------------------------------------------------------------------
; ESCRIBIR_CHAR_POS - Escribe un caracter en posicion (DH,DL)
;   Entrada: DH=fila, DL=columna, AL=caracter, BL=atributo
;--------------------------------------------------------------------
ESCRIBIR_CHAR_POS PROC
    PUSH AX
    PUSH BX
    PUSH CX

    PUSH AX                 ; Guardar caracter
    MOV AH, 02h             ; Posicionar cursor
    MOV BH, 00h             ; Pagina 0
    INT 10h

    POP AX                  ; Recuperar caracter
    MOV AH, 09h             ; Escribir caracter con atributo
    MOV BH, 00h             ; Pagina 0
    MOV CX, 1               ; Repetir 1 vez
    INT 10h

    POP CX
    POP BX
    POP AX
    RET
ESCRIBIR_CHAR_POS ENDP

;--------------------------------------------------------------------
; MOSTRAR_TITULO - Muestra el titulo centrado en la ventana
;--------------------------------------------------------------------
MOSTRAR_TITULO PROC
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI

    ; --- Linea separadora debajo del titulo ---
    MOV DH, VENTANA_FILA1 + 2
    MOV DL, VENTANA_COL1 + 1
    MOV BL, COLOR_BORDE
    MOV CX, VENTANA_COL2 - VENTANA_COL1 - 1
LINEA_TITULO:
    MOV AL, LINEA_HOR_S
    CALL ESCRIBIR_CHAR_POS
    INC DL
    LOOP LINEA_TITULO

    ; --- Escribir titulo centrado ---
    LEA SI, TITULO
    ; Calcular longitud del titulo
    PUSH SI
    XOR CX, CX
CONTAR_TITULO:
    LODSB
    CMP AL, 0
    JE FIN_CONTAR
    INC CX
    JMP CONTAR_TITULO
FIN_CONTAR:
    POP SI

    ; Calcular posicion centrada
    MOV AX, VENTANA_COL2 - VENTANA_COL1 - 1
    SUB AX, CX
    SHR AX, 1
    ADD AL, VENTANA_COL1 + 1
    MOV DL, AL
    MOV DH, VENTANA_FILA1 + 1
    MOV BL, COLOR_TITULO

ESCRIBIR_TITULO:
    LODSB
    CMP AL, 0
    JE FIN_TITULO
    CALL ESCRIBIR_CHAR_POS
    INC DL
    JMP ESCRIBIR_TITULO

FIN_TITULO:
    POP SI
    POP DX
    POP BX
    POP AX
    RET
MOSTRAR_TITULO ENDP

;--------------------------------------------------------------------
; MOSTRAR_ETIQUETAS - Muestra las etiquetas Usuario y Contrasena
;--------------------------------------------------------------------
MOSTRAR_ETIQUETAS PROC
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI

    ; --- Etiqueta "Usuario:" ---
    MOV DH, VENTANA_FILA1 + 4
    MOV DL, VENTANA_COL1 + 3
    MOV BL, COLOR_FONDO
    LEA SI, MSG_USUARIO
ESCRIBIR_USR_LABEL:
    LODSB
    CMP AL, 0
    JE FIN_USR_LABEL
    CALL ESCRIBIR_CHAR_POS
    INC DL
    JMP ESCRIBIR_USR_LABEL
FIN_USR_LABEL:

    ; --- Etiqueta "Contrasena:" ---
    MOV DH, VENTANA_FILA1 + 8
    MOV DL, VENTANA_COL1 + 3
    LEA SI, MSG_CONTRASENA
ESCRIBIR_PWD_LABEL:
    LODSB
    CMP AL, 0
    JE FIN_PWD_LABEL
    CALL ESCRIBIR_CHAR_POS
    INC DL
    JMP ESCRIBIR_PWD_LABEL
FIN_PWD_LABEL:

    POP SI
    POP DX
    POP BX
    POP AX
    RET
MOSTRAR_ETIQUETAS ENDP

;--------------------------------------------------------------------
; DIBUJAR_CAMPOS - Dibuja los campos de entrada
;--------------------------------------------------------------------
DIBUJAR_CAMPOS PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; --- Campo de usuario ---
    MOV DH, VENTANA_FILA1 + 5
    MOV DL, VENTANA_COL1 + 3
    MOV BL, COLOR_CAMPO
    MOV CX, 22                ; 20 chars + 2 bordes
    MOV AL, ' '
CAMPO_USR:
    CALL ESCRIBIR_CHAR_POS
    INC DL
    LOOP CAMPO_USR

    ; --- Campo de contrasena ---
    MOV DH, VENTANA_FILA1 + 9
    MOV DL, VENTANA_COL1 + 3
    MOV BL, COLOR_CAMPO
    MOV CX, 22
    MOV AL, ' '
CAMPO_PWD:
    CALL ESCRIBIR_CHAR_POS
    INC DL
    LOOP CAMPO_PWD

    POP DX
    POP CX
    POP BX
    POP AX
    RET
DIBUJAR_CAMPOS ENDP

;--------------------------------------------------------------------
; MOSTRAR_INSTRUCCIONES - Muestra texto de ayuda
;--------------------------------------------------------------------
MOSTRAR_INSTRUCCIONES PROC
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI

    MOV DH, VENTANA_FILA2 - 1
    MOV DL, VENTANA_COL1 + 2
    MOV BL, COLOR_BORDE
    LEA SI, MSG_PRESIONE
ESCRIBIR_INSTR:
    LODSB
    CMP AL, 0
    JE FIN_INSTR
    CALL ESCRIBIR_CHAR_POS
    INC DL
    JMP ESCRIBIR_INSTR
FIN_INSTR:

    POP SI
    POP DX
    POP BX
    POP AX
    RET
MOSTRAR_INSTRUCCIONES ENDP

;--------------------------------------------------------------------
; LEER_USUARIO - Lee el nombre de usuario (max 20 chars)
;--------------------------------------------------------------------
LEER_USUARIO PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI

    LEA DI, BUFFER_USR
    XOR CX, CX              ; Contador de caracteres = 0
    MOV BYTE PTR [LEN_USR], 0

    ; --- Mostrar cursor en el campo ---
    MOV AH, 01h
    PUSH CX
    MOV CX, 0607h
    INT 10h
    POP CX

    ; --- Posicionar cursor en el campo ---
    MOV DH, VENTANA_FILA1 + 5
    MOV DL, VENTANA_COL1 + 4
    MOV AH, 02h
    MOV BH, 0
    INT 10h

LEER_TECLA_USR:
    MOV AH, 00h
    INT 16h

    CMP AL, 0Dh             ; Enter?
    JE FIN_LEER_USR

    CMP AL, 1Bh             ; Escape?
    JE SALIR_PROGRAMA

    CMP AL, 08h             ; Backspace?
    JE BACKSPACE_USR

    CMP CX, MAX_CHARS       ; Limite alcanzado?
    JGE LEER_TECLA_USR      ; Ignorar si ya hay 20 chars

    ; --- Guardar caracter ---
    MOV [DI], AL
    INC DI
    INC CX

    ; --- Mostrar caracter en pantalla ---
    PUSH CX
    MOV AH, 09h
    MOV BH, 0
    MOV BL, COLOR_CAMPO
    MOV CX, 1
    INT 10h
    POP CX

    ; --- Avanzar cursor ---
    PUSH CX
    MOV AH, 03h
    MOV BH, 0
    INT 10h
    INC DL
    MOV AH, 02h
    INT 10h
    POP CX

    JMP LEER_TECLA_USR

BACKSPACE_USR:
    CMP CX, 0
    JE LEER_TECLA_USR       ; No hay nada que borrar

    DEC DI
    DEC CX
    MOV BYTE PTR [DI], 0

    ; --- Retroceder cursor ---
    PUSH CX
    MOV AH, 03h
    MOV BH, 0
    INT 10h
    DEC DL
    MOV AH, 02h
    INT 10h

    ; --- Borrar caracter en pantalla ---
    MOV AH, 09h
    MOV AL, ' '
    MOV BH, 0
    MOV BL, COLOR_CAMPO
    MOV CX, 1
    INT 10h
    POP CX

    JMP LEER_TECLA_USR

FIN_LEER_USR:
    MOV BYTE PTR [DI], 0    ; Terminar cadena con null
    MOV [LEN_USR], CL

    ; --- Ocultar cursor ---
    MOV AH, 01h
    MOV CX, 2607h
    INT 10h

    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET

SALIR_PROGRAMA:
    ; --- Restaurar cursor ---
    MOV AH, 01h
    MOV CX, 0607h
    INT 10h
    ; --- Restaurar modo video ---
    MOV AX, 0003h
    INT 10h
    ; --- Terminar ---
    MOV AX, 4C00h
    INT 21h
LEER_USUARIO ENDP

;--------------------------------------------------------------------
; LEER_CONTRASENA - Lee la contrasena (max 20 chars, muestra *)
;--------------------------------------------------------------------
LEER_CONTRASENA PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI

    LEA DI, BUFFER_PWD
    XOR CX, CX
    MOV BYTE PTR [LEN_PWD], 0

    ; --- Mostrar cursor ---
    MOV AH, 01h
    PUSH CX
    MOV CX, 0607h
    INT 10h
    POP CX

    ; --- Posicionar cursor en campo contrasena ---
    MOV DH, VENTANA_FILA1 + 9
    MOV DL, VENTANA_COL1 + 4
    MOV AH, 02h
    MOV BH, 0
    INT 10h

LEER_TECLA_PWD:
    MOV AH, 00h
    INT 16h

    CMP AL, 0Dh             ; Enter?
    JE FIN_LEER_PWD

    CMP AL, 1Bh             ; Escape?
    JE SALIR_PROGRAMA2

    CMP AL, 08h             ; Backspace?
    JE BACKSPACE_PWD

    CMP CX, MAX_CHARS       ; Limite?
    JGE LEER_TECLA_PWD

    ; --- Guardar caracter real ---
    MOV [DI], AL
    INC DI
    INC CX

    ; --- Mostrar asterisco en pantalla ---
    PUSH CX
    MOV AH, 09h
    MOV AL, '*'
    MOV BH, 0
    MOV BL, COLOR_CAMPO
    MOV CX, 1
    INT 10h
    POP CX

    ; --- Avanzar cursor ---
    PUSH CX
    MOV AH, 03h
    MOV BH, 0
    INT 10h
    INC DL
    MOV AH, 02h
    INT 10h
    POP CX

    JMP LEER_TECLA_PWD

BACKSPACE_PWD:
    CMP CX, 0
    JE LEER_TECLA_PWD

    DEC DI
    DEC CX
    MOV BYTE PTR [DI], 0

    ; --- Retroceder cursor ---
    PUSH CX
    MOV AH, 03h
    MOV BH, 0
    INT 10h
    DEC DL
    MOV AH, 02h
    INT 10h

    ; --- Borrar asterisco ---
    MOV AH, 09h
    MOV AL, ' '
    MOV BH, 0
    MOV BL, COLOR_CAMPO
    MOV CX, 1
    INT 10h
    POP CX

    JMP LEER_TECLA_PWD

FIN_LEER_PWD:
    MOV BYTE PTR [DI], 0
    MOV [LEN_PWD], CL

    ; --- Ocultar cursor ---
    MOV AH, 01h
    MOV CX, 2607h
    INT 10h

    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET

SALIR_PROGRAMA2:
    MOV AH, 01h
    MOV CX, 0607h
    INT 10h
    MOV AX, 0003h
    INT 10h
    MOV AX, 4C00h
    INT 21h
LEER_CONTRASENA ENDP

;--------------------------------------------------------------------
; MOSTRAR_BIENVENIDA - Muestra mensaje de bienvenida con el usuario
;--------------------------------------------------------------------
MOSTRAR_BIENVENIDA PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; --- Limpiar area de mensaje ---
    MOV DH, VENTANA_FILA1 + 12
    MOV DL, VENTANA_COL1 + 3
    MOV BL, COLOR_TITULO

    ; --- Escribir "Bienvenido, " ---
    LEA SI, MSG_BIENVENIDA
ESCRIBIR_BIENVENIDA:
    LODSB
    CMP AL, 0
    JE ESCRIBIR_NOMBRE
    CALL ESCRIBIR_CHAR_POS
    INC DL
    JMP ESCRIBIR_BIENVENIDA

ESCRIBIR_NOMBRE:
    ; --- Escribir nombre del usuario ---
    LEA SI, BUFFER_USR
ESCRIBIR_NOM:
    LODSB
    CMP AL, 0
    JE FIN_BIENVENIDA
    CALL ESCRIBIR_CHAR_POS
    INC DL
    JMP ESCRIBIR_NOM

FIN_BIENVENIDA:
    ; --- Escribir signo de exclamacion ---
    MOV AL, '!'
    CALL ESCRIBIR_CHAR_POS

    ; --- Mensaje: presione tecla para salir ---
    MOV DH, VENTANA_FILA1 + 14
    MOV DL, VENTANA_COL1 + 3
    MOV BL, COLOR_FONDO
    LEA SI, MSG_SALIR
ESCRIBIR_SALIR_MSG:
    LODSB
    CMP AL, 0
    JE FIN_MSG_SALIR
    CALL ESCRIBIR_CHAR_POS
    INC DL
    JMP ESCRIBIR_SALIR_MSG
FIN_MSG_SALIR:

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
MOSTRAR_BIENVENIDA ENDP

END INICIO
