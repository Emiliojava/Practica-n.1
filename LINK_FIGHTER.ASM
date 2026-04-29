;====================================================================
; LINK_FIGHTER.ASM - Animacion de Link estilo Street Fighter
; Ensamblador: TASM (Turbo Assembler)
; Modo: VGA 13h (320x200, 256 colores)
;
; Descripcion:
;   Dibuja y anima un personaje de Link (The Legend of Zelda)
;   en estilo Street Fighter con pose de pelea, ataque de espada,
;   patada, y movimiento lateral sobre un escenario tipo arena.
;
; Controles:
;   Flecha Izq/Der  - Mover a Link
;   Z               - Ataque de espada
;   X               - Patada
;   Esc             - Salir del programa
;
; Compilacion:
;   TASM LINK_FIGHTER.ASM
;   TLINK LINK_FIGHTER.OBJ
;   LINK_FIGHTER.EXE
;====================================================================

.MODEL SMALL
.STACK 512

;--------------------------------------------------------------------
; Constantes globales
;--------------------------------------------------------------------
VGA_SEG     EQU 0A000h
SCREEN_W    EQU 320
SCREEN_H    EQU 200
FLOOR_Y     EQU 158
NUM_COLORS  EQU 21

; Indices de colores en la paleta personalizada
C_BG        EQU 0
C_DGREEN    EQU 1
C_GREEN     EQU 2
C_LGREEN    EQU 3
C_SKIN      EQU 4
C_DSKIN     EQU 5
C_BROWN     EQU 6
C_DBROWN    EQU 7
C_YELLOW    EQU 8
C_WHITE     EQU 9
C_BLUE      EQU 10
C_DBLUE     EQU 11
C_RED       EQU 12
C_SILVER    EQU 13
C_DGRAY     EQU 14
C_FLOOR1    EQU 15
C_FLOOR2    EQU 16
C_SKY       EQU 17
C_HPGREEN   EQU 18
C_HPBG      EQU 19
C_ORANGE    EQU 20

;--------------------------------------------------------------------
; Segmento de datos
;--------------------------------------------------------------------
.DATA

    ;================================================================
    ; Paleta personalizada (R, G, B - valores 0..63 para VGA DAC)
    ;================================================================
    PALETA  DB  0, 0, 0        ; 0:  Negro (fondo/transparente)
            DB  2,20, 2        ; 1:  Verde oscuro
            DB  8,35, 6        ; 2:  Verde (tunica)
            DB 16,45,12        ; 3:  Verde claro
            DB 56,44,30        ; 4:  Piel
            DB 44,32,20        ; 5:  Piel sombra
            DB 36,18, 4        ; 6:  Cafe
            DB 22,10, 2        ; 7:  Cafe oscuro
            DB 58,50,10        ; 8:  Rubio/amarillo
            DB 63,63,58        ; 9:  Blanco
            DB 10,20,50        ; 10: Azul
            DB  4,10,35        ; 11: Azul oscuro
            DB 50, 6, 6        ; 12: Rojo
            DB 50,50,55        ; 13: Plateado
            DB 30,30,35        ; 14: Gris oscuro
            DB 42,30,14        ; 15: Piso claro
            DB 34,22, 8        ; 16: Piso oscuro
            DB  8, 8,22        ; 17: Cielo/escenario
            DB 12,52,12        ; 18: Barra HP verde
            DB 22,10,10        ; 19: Fondo barra HP
            DB 52,34, 6        ; 20: Naranja/dorado

    ;================================================================
    ; Estado del jugador
    ;================================================================
    PLAYER_X    DW 140          ; Posicion X del personaje
    PLAYER_Y    DW 113          ; Posicion Y (esquina sup. del sprite)
    PLAYER_DIR  DB 1            ; 1=derecha, 0=izquierda
    PLAYER_HP   DB 100          ; Puntos de vida
    OLD_PX      DW 140          ; Posicion anterior X (para limpiar)
    OLD_PY      DW 113          ; Posicion anterior Y

    ;================================================================
    ; Variables de animacion
    ;================================================================
    ANIM_STATE  DB 0            ; 0=idle, 1=espada, 2=patada
    ANIM_FRAME  DB 0            ; Frame actual del idle (0 o 1)
    ANIM_TIMER  DW 0            ; Contador de frames
    ATTACK_TMR  DB 0            ; Duracion del ataque actual
    EXIT_FLAG   DB 0            ; Bandera de salida

    ;================================================================
    ; Variables temporales para dibujo de rectangulos
    ;================================================================
    DRAW_X      DW 0
    DRAW_Y      DW 0
    DRAW_W      DW 0
    DRAW_H      DW 0
    DRAW_COL    DB 0

    ;================================================================
    ; Puntero al frame de sprite actual
    ;================================================================
    FRAME_PTR   DW 0

    ;================================================================
    ; Cadenas de texto para la interfaz
    ;================================================================
    STR_LINK    DB 'LINK', 0
    STR_ROUND   DB '- ROUND 1 -', 0
    STR_FIGHT   DB 'FIGHT!', 0
    STR_CTRL    DB 'Z=ESPADA X=PATADA', 0
    STR_ESC     DB 'ESC=SALIR', 0
    STR_HYRULE  DB 'HYRULE ARENA', 0
    STR_KO      DB 'K.O.', 0

    ;================================================================
    ; DATOS DE SPRITES
    ; Formato por parte: DB dx, dy, ancho, alto, color
    ; Cada frame termina con FFh
    ; El sprite se dibuja en PLAYER_X+dx, PLAYER_Y+dy
    ; Tamano aprox: 26 ancho x 45 alto pixeles
    ;================================================================

    ;--- Frame IDLE 1: Pose de pelea normal ---
    FR_IDLE1:
        ; --- Sombrero ---
        DB  5, 0,12, 5, C_GREEN        ; cuerpo del sombrero
        DB  8, 1, 4, 3, C_LGREEN       ; brillo/detalle
        ; --- Cabello ---
        DB  4, 4,14, 4, C_YELLOW       ; cabello rubio
        ; --- Rostro ---
        DB  6, 7,10, 8, C_SKIN         ; cara
        DB 13, 9, 2, 2, C_BLUE         ; ojo
        DB  4, 8, 3, 3, C_SKIN         ; oreja
        ; --- Cuello ---
        DB  9,15, 5, 2, C_SKIN
        ; --- Tunica ---
        DB  5,17,12,11, C_GREEN        ; cuerpo tunica
        DB  6,26,10, 2, C_BROWN        ; cinturon
        DB  4,28,14, 4, C_GREEN        ; falda de tunica
        ; --- Brazos ---
        DB  2,18, 3, 8, C_SKIN         ; brazo izq (espada)
        DB 17,18, 3, 8, C_SKIN         ; brazo der (escudo)
        ; --- Espada (vertical, detras) ---
        DB  0, 4, 2,22, C_SILVER       ; hoja de espada
        DB  0, 3, 4, 2, C_DGRAY        ; punta espada
        DB  1,26, 5, 2, C_BROWN        ; guardia de espada
        ; --- Escudo (al frente) ---
        DB 19,17, 6,10, C_BLUE         ; cuerpo del escudo
        DB 19,17, 1,10, C_DBLUE        ; borde izquierdo
        DB 21,20, 3, 4, C_RED          ; emblema Hylian
        DB 22,21, 1, 2, C_YELLOW       ; detalle dorado
        ; --- Piernas ---
        DB  6,32, 4, 8, C_SKIN         ; pierna izquierda
        DB 12,32, 4, 8, C_SKIN         ; pierna derecha
        ; --- Botas ---
        DB  5,40, 5, 5, C_BROWN        ; bota izquierda
        DB 11,40, 5, 5, C_BROWN        ; bota derecha
        DB 0FFh                         ; fin del frame

    ;--- Frame IDLE 2: Respiracion (cabeza sube 1px) ---
    FR_IDLE2:
        ; --- Sombrero (y-1) ---
        DB  5, 0,12, 4, C_GREEN
        DB  8, 0, 4, 3, C_LGREEN
        ; --- Cabello (y-1) ---
        DB  4, 3,14, 4, C_YELLOW
        ; --- Rostro (y-1) ---
        DB  6, 6,10, 8, C_SKIN
        DB 13, 8, 2, 2, C_BLUE
        DB  4, 7, 3, 3, C_SKIN
        ; --- Cuello (se estira) ---
        DB  9,14, 5, 3, C_SKIN
        ; --- Tunica (igual) ---
        DB  5,17,12,11, C_GREEN
        DB  6,26,10, 2, C_BROWN
        DB  4,28,14, 4, C_GREEN
        ; --- Brazos (ligeramente arriba) ---
        DB  2,17, 3, 9, C_SKIN
        DB 17,17, 3, 9, C_SKIN
        ; --- Espada ---
        DB  0, 3, 2,22, C_SILVER
        DB  0, 2, 4, 2, C_DGRAY
        DB  1,25, 5, 2, C_BROWN
        ; --- Escudo ---
        DB 19,16, 6,11, C_BLUE
        DB 19,16, 1,11, C_DBLUE
        DB 21,19, 3, 4, C_RED
        DB 22,20, 1, 2, C_YELLOW
        ; --- Piernas ---
        DB  6,32, 4, 8, C_SKIN
        DB 12,32, 4, 8, C_SKIN
        ; --- Botas ---
        DB  5,40, 5, 5, C_BROWN
        DB 11,40, 5, 5, C_BROWN
        DB 0FFh

    ;--- Frame ATAQUE: Estocada de espada hacia adelante ---
    FR_ATTACK:
        ; --- Sombrero (cuerpo inclinado +2 adelante) ---
        DB  7, 0,12, 5, C_GREEN
        DB 10, 1, 4, 3, C_LGREEN
        ; --- Cabello ---
        DB  6, 4,14, 4, C_YELLOW
        ; --- Rostro ---
        DB  8, 7,10, 8, C_SKIN
        DB 15, 9, 2, 2, C_BLUE
        DB  6, 8, 3, 3, C_SKIN
        ; --- Cuello ---
        DB 11,15, 5, 2, C_SKIN
        ; --- Tunica (inclinada adelante) ---
        DB  7,17,12,11, C_GREEN
        DB  8,26,10, 2, C_BROWN
        DB  6,28,14, 4, C_GREEN
        ; --- Brazo izq extendido con espada ---
        DB 17,15, 4, 4, C_SKIN         ; hombro
        DB 21,14, 8, 3, C_SKIN         ; antebrazo extendido
        ; --- Espada horizontal (estocada!) ---
        DB 28,12,14, 2, C_SILVER       ; hoja horizontal
        DB 27,11, 2, 4, C_DGRAY        ; punta
        DB 19,16, 4, 2, C_BROWN        ; guardia
        ; --- Brazo der atras con escudo ---
        DB  4,18, 3, 8, C_SKIN
        ; --- Escudo en la espalda ---
        DB  1,17, 5, 9, C_BLUE
        DB  1,17, 1, 9, C_DBLUE
        DB  3,20, 2, 3, C_RED
        ; --- Piernas (ligeramente adelante) ---
        DB  8,32, 4, 8, C_SKIN
        DB 14,32, 4, 8, C_SKIN
        ; --- Botas ---
        DB  7,40, 5, 5, C_BROWN
        DB 13,40, 5, 5, C_BROWN
        DB 0FFh

    ;--- Frame PATADA: Pierna derecha extendida ---
    FR_KICK:
        ; --- Sombrero (cuerpo inclinado -2 atras) ---
        DB  3, 1,12, 5, C_GREEN
        DB  6, 2, 4, 3, C_LGREEN
        ; --- Cabello ---
        DB  2, 5,14, 4, C_YELLOW
        ; --- Rostro ---
        DB  4, 8,10, 8, C_SKIN
        DB 11,10, 2, 2, C_BLUE
        DB  2, 9, 3, 3, C_SKIN
        ; --- Cuello ---
        DB  7,16, 5, 2, C_SKIN
        ; --- Tunica (inclinada atras) ---
        DB  3,18,12,10, C_GREEN
        DB  4,26,10, 2, C_BROWN
        DB  2,28,14, 4, C_GREEN
        ; --- Brazos ---
        DB  0,19, 3, 8, C_SKIN         ; brazo izq
        DB 15,19, 3, 7, C_SKIN         ; brazo der
        ; --- Espada (vertical detras) ---
        DB  0, 6, 2,18, C_SILVER
        DB  0, 5, 3, 2, C_DGRAY
        DB  0,24, 4, 2, C_BROWN
        ; --- Escudo ---
        DB 17,18, 5, 8, C_BLUE
        DB 17,18, 1, 8, C_DBLUE
        DB 19,20, 2, 3, C_RED
        ; --- Pierna izq (soporte, mas larga) ---
        DB  5,32, 4,10, C_SKIN
        ; --- Pierna der (PATADA extendida!) ---
        DB 10,28, 4, 4, C_SKIN         ; muslo angulado
        DB 14,29,10, 3, C_SKIN         ; pierna extendida
        DB 23,28, 5, 4, C_BROWN        ; bota de patada
        ; --- Bota izq (soporte en piso) ---
        DB  4,42, 5, 3, C_BROWN
        DB 0FFh

    ;================================================================
    ; Tabla de punteros a frames idle
    ;================================================================
    IDLE_FRAMES  DW OFFSET FR_IDLE1
                 DW OFFSET FR_IDLE2
    ATTACK_FRAME DW OFFSET FR_ATTACK
    KICK_FRAME   DW OFFSET FR_KICK

;--------------------------------------------------------------------
; Segmento de codigo
;--------------------------------------------------------------------
.CODE

INICIO:
    MOV AX, @DATA
    MOV DS, AX

    ; Asegurar bandera de direccion limpia (para REP/LODS)
    CLD

    ;--- Establecer modo VGA 13h (320x200, 256 colores) ---
    MOV AX, 0013h
    INT 10h

    ;--- Configurar paleta personalizada ---
    CALL SETUP_PALETA

    ;--- Inicializar puntero de frame ---
    MOV AX, OFFSET FR_IDLE1
    MOV WORD PTR [FRAME_PTR], AX

    ;--- Dibujar escenario de fondo ---
    CALL DIBUJAR_ESCENARIO

    ;--- Mostrar intro "ROUND 1 - FIGHT!" ---
    CALL MOSTRAR_INTRO

    ;--- Dibujar interfaz (barra HP, nombre, controles) ---
    CALL DIBUJAR_UI

;====================================================================
; BUCLE PRINCIPAL DEL JUEGO
;====================================================================
BUCLE_PRINCIPAL:
    ;--- Incrementar temporizador global ---
    INC WORD PTR [ANIM_TIMER]

    ;--- Verificar teclado (sin bloquear) ---
    MOV AH, 01h
    INT 16h
    JZ SIN_TECLA

    ;--- Leer la tecla del buffer ---
    MOV AH, 00h
    INT 16h

    ;--- Procesar la tecla presionada ---
    CMP AH, 01h                ; Esc = salir
    JE SALIR_JUEGO
    CMP AH, 4Bh                ; Flecha izquierda
    JE MOVER_IZQ
    CMP AH, 4Dh                ; Flecha derecha
    JE MOVER_DER
    CMP AL, 'z'                ; Z = ataque espada
    JE HACER_ATAQUE
    CMP AL, 'Z'
    JE HACER_ATAQUE
    CMP AL, 'x'                ; X = patada
    JE HACER_PATADA
    CMP AL, 'X'
    JE HACER_PATADA
    JMP SIN_TECLA

MOVER_IZQ:
    CMP WORD PTR [PLAYER_X], 8
    JLE SIN_TECLA
    SUB WORD PTR [PLAYER_X], 3
    MOV BYTE PTR [PLAYER_DIR], 0
    JMP SIN_TECLA

MOVER_DER:
    CMP WORD PTR [PLAYER_X], 275
    JGE SIN_TECLA
    ADD WORD PTR [PLAYER_X], 3
    MOV BYTE PTR [PLAYER_DIR], 1
    JMP SIN_TECLA

HACER_ATAQUE:
    CMP BYTE PTR [ANIM_STATE], 0   ; Solo atacar desde idle
    JNE SIN_TECLA
    MOV BYTE PTR [ANIM_STATE], 1
    MOV BYTE PTR [ATTACK_TMR], 0
    JMP SIN_TECLA

HACER_PATADA:
    CMP BYTE PTR [ANIM_STATE], 0
    JNE SIN_TECLA
    MOV BYTE PTR [ANIM_STATE], 2
    MOV BYTE PTR [ATTACK_TMR], 0
    JMP SIN_TECLA

SIN_TECLA:
    ;--- Actualizar estado de animacion ---
    CALL ACTUALIZAR_ANIM

    ;--- Sincronizar con retrazo vertical (anti-flicker) ---
    CALL ESPERAR_RETRAZO

    ;--- Limpiar area del sprite anterior ---
    CALL LIMPIAR_SPRITE

    ;--- Dibujar sombra debajo de Link ---
    CALL DIBUJAR_SOMBRA

    ;--- Dibujar el sprite de Link ---
    CALL DIBUJAR_LINK

    ;--- Dibujar efectos de ataque (si aplica) ---
    CALL DIBUJAR_EFECTOS

    ;--- Refrescar interfaz ---
    CALL DIBUJAR_UI

    ;--- Repetir bucle ---
    JMP BUCLE_PRINCIPAL

SALIR_JUEGO:
    ;--- Restaurar modo de video texto 80x25 ---
    MOV AX, 0003h
    INT 10h

    ;--- Terminar programa y volver a DOS ---
    MOV AX, 4C00h
    INT 21h

;====================================================================
; PROCEDIMIENTOS
;====================================================================

;--------------------------------------------------------------------
; SETUP_PALETA - Configura los 21 colores de la paleta VGA
; Escribe directamente a los registros DAC del VGA
;--------------------------------------------------------------------
SETUP_PALETA PROC
    PUSH AX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV SI, OFFSET PALETA
    XOR AL, AL                  ; Empezar en indice de color 0
    MOV DX, 03C8h
    OUT DX, AL                  ; Enviar indice inicial al DAC
    MOV DX, 03C9h               ; Puerto de datos RGB
    MOV CX, NUM_COLORS * 3      ; Total de bytes a enviar

SP_ENVIAR:
    LODSB                       ; Cargar byte de PALETA
    OUT DX, AL                  ; Enviar al DAC
    LOOP SP_ENVIAR

    POP SI
    POP DX
    POP CX
    POP AX
    RET
SETUP_PALETA ENDP

;--------------------------------------------------------------------
; ESPERAR_RETRAZO - Espera el inicio del retrazo vertical VGA
; Esto sincroniza el dibujo con el monitor para evitar parpadeo
;--------------------------------------------------------------------
ESPERAR_RETRAZO PROC
    PUSH AX
    PUSH DX

    MOV DX, 03DAh              ; Registro de estado VGA

ER_FIN_RETRAZO:
    IN AL, DX
    TEST AL, 08h
    JNZ ER_FIN_RETRAZO          ; Esperar a que termine retrazo actual

ER_INICIO_RETRAZO:
    IN AL, DX
    TEST AL, 08h
    JZ ER_INICIO_RETRAZO        ; Esperar a que inicie nuevo retrazo

    POP DX
    POP AX
    RET
ESPERAR_RETRAZO ENDP

;--------------------------------------------------------------------
; FILL_RECT - Rellena un rectangulo solido en la memoria VGA
; Parametros en variables: DRAW_X, DRAW_Y, DRAW_W, DRAW_H, DRAW_COL
; Incluye clipping basico para no escribir fuera de pantalla
;--------------------------------------------------------------------
FILL_RECT PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH ES

    ;--- Validacion: posicion fuera de pantalla ---
    MOV AX, WORD PTR [DRAW_X]
    CMP AX, SCREEN_W
    JAE FILL_SALIR
    MOV AX, WORD PTR [DRAW_Y]
    CMP AX, SCREEN_H
    JAE FILL_SALIR
    MOV AX, WORD PTR [DRAW_W]
    CMP AX, 0
    JE FILL_SALIR
    MOV AX, WORD PTR [DRAW_H]
    CMP AX, 0
    JE FILL_SALIR

    ;--- Clipping horizontal ---
    MOV AX, WORD PTR [DRAW_X]
    ADD AX, WORD PTR [DRAW_W]
    CMP AX, SCREEN_W
    JBE FILL_CLIPX_OK
    MOV AX, SCREEN_W
    SUB AX, WORD PTR [DRAW_X]
    MOV WORD PTR [DRAW_W], AX
FILL_CLIPX_OK:

    ;--- Clipping vertical ---
    MOV AX, WORD PTR [DRAW_Y]
    ADD AX, WORD PTR [DRAW_H]
    CMP AX, SCREEN_H
    JBE FILL_CLIPY_OK
    MOV AX, SCREEN_H
    SUB AX, WORD PTR [DRAW_Y]
    MOV WORD PTR [DRAW_H], AX
FILL_CLIPY_OK:

    ;--- Preparar segmento VGA ---
    MOV AX, VGA_SEG
    MOV ES, AX

    ;--- Calcular offset inicial: y * 320 + x ---
    MOV AX, WORD PTR [DRAW_Y]
    MOV BX, AX
    SHL AX, 8                  ; AX = y * 256
    SHL BX, 6                  ; BX = y * 64
    ADD AX, BX                 ; AX = y * 320
    ADD AX, WORD PTR [DRAW_X]  ; AX = y * 320 + x
    MOV DI, AX                 ; ES:DI = inicio en VRAM

    MOV AL, BYTE PTR [DRAW_COL]
    MOV DX, WORD PTR [DRAW_H]  ; Contador de filas

FILL_FILA:
    CMP DX, 0
    JE FILL_SALIR

    PUSH DI                    ; Guardar inicio de fila
    MOV CX, WORD PTR [DRAW_W]  ; Ancho a llenar
    REP STOSB                  ; Llenar CX pixeles con AL
    POP DI                     ; Recuperar inicio de fila

    ADD DI, SCREEN_W           ; Avanzar a siguiente fila (320 bytes)
    DEC DX
    JMP FILL_FILA

FILL_SALIR:
    POP ES
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
FILL_RECT ENDP

;--------------------------------------------------------------------
; DIBUJAR_ESCENARIO - Dibuja el fondo completo del escenario
;--------------------------------------------------------------------
DIBUJAR_ESCENARIO PROC
    PUSH AX

    ;--- Cielo oscuro (parte superior) ---
    MOV WORD PTR [DRAW_X], 0
    MOV WORD PTR [DRAW_Y], 0
    MOV WORD PTR [DRAW_W], SCREEN_W
    MOV WORD PTR [DRAW_H], FLOOR_Y
    MOV BYTE PTR [DRAW_COL], C_SKY
    CALL FILL_RECT

    ;--- Linea del borde del escenario (naranja) ---
    MOV WORD PTR [DRAW_X], 0
    MOV WORD PTR [DRAW_Y], FLOOR_Y
    MOV WORD PTR [DRAW_W], SCREEN_W
    MOV WORD PTR [DRAW_H], 2
    MOV BYTE PTR [DRAW_COL], C_ORANGE
    CALL FILL_RECT

    ;--- Piso superior ---
    MOV WORD PTR [DRAW_X], 0
    MOV WORD PTR [DRAW_Y], FLOOR_Y + 2
    MOV WORD PTR [DRAW_W], SCREEN_W
    MOV WORD PTR [DRAW_H], 20
    MOV BYTE PTR [DRAW_COL], C_FLOOR1
    CALL FILL_RECT

    ;--- Linea decorativa horizontal ---
    MOV WORD PTR [DRAW_X], 0
    MOV WORD PTR [DRAW_Y], FLOOR_Y + 12
    MOV WORD PTR [DRAW_W], SCREEN_W
    MOV WORD PTR [DRAW_H], 1
    MOV BYTE PTR [DRAW_COL], C_DBROWN
    CALL FILL_RECT

    ;--- Piso inferior (mas oscuro) ---
    MOV WORD PTR [DRAW_X], 0
    MOV WORD PTR [DRAW_Y], FLOOR_Y + 22
    MOV WORD PTR [DRAW_W], SCREEN_W
    MOV WORD PTR [DRAW_H], 20
    MOV BYTE PTR [DRAW_COL], C_FLOOR2
    CALL FILL_RECT

    ;--- Detalles decorativos: pilares laterales ---
    ; Pilar izquierdo
    MOV WORD PTR [DRAW_X], 10
    MOV WORD PTR [DRAW_Y], 50
    MOV WORD PTR [DRAW_W], 8
    MOV WORD PTR [DRAW_H], FLOOR_Y - 50
    MOV BYTE PTR [DRAW_COL], C_DGRAY
    CALL FILL_RECT

    MOV WORD PTR [DRAW_X], 11
    MOV WORD PTR [DRAW_Y], 50
    MOV WORD PTR [DRAW_W], 6
    MOV WORD PTR [DRAW_H], FLOOR_Y - 50
    MOV BYTE PTR [DRAW_COL], C_SILVER
    CALL FILL_RECT

    ; Pilar derecho
    MOV WORD PTR [DRAW_X], 302
    MOV WORD PTR [DRAW_Y], 50
    MOV WORD PTR [DRAW_W], 8
    MOV WORD PTR [DRAW_H], FLOOR_Y - 50
    MOV BYTE PTR [DRAW_COL], C_DGRAY
    CALL FILL_RECT

    MOV WORD PTR [DRAW_X], 303
    MOV WORD PTR [DRAW_Y], 50
    MOV WORD PTR [DRAW_W], 6
    MOV WORD PTR [DRAW_H], FLOOR_Y - 50
    MOV BYTE PTR [DRAW_COL], C_SILVER
    CALL FILL_RECT

    ; Capiteles de pilares
    MOV WORD PTR [DRAW_X], 8
    MOV WORD PTR [DRAW_Y], 48
    MOV WORD PTR [DRAW_W], 12
    MOV WORD PTR [DRAW_H], 4
    MOV BYTE PTR [DRAW_COL], C_ORANGE
    CALL FILL_RECT

    MOV WORD PTR [DRAW_X], 300
    MOV WORD PTR [DRAW_Y], 48
    MOV WORD PTR [DRAW_W], 12
    MOV WORD PTR [DRAW_H], 4
    MOV BYTE PTR [DRAW_COL], C_ORANGE
    CALL FILL_RECT

    POP AX
    RET
DIBUJAR_ESCENARIO ENDP

;--------------------------------------------------------------------
; DIBUJAR_UI - Dibuja la interfaz de usuario (barra HP, textos)
;--------------------------------------------------------------------
DIBUJAR_UI PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ;--- Fondo de barra HP ---
    MOV WORD PTR [DRAW_X], 8
    MOV WORD PTR [DRAW_Y], 16
    MOV WORD PTR [DRAW_W], 104
    MOV WORD PTR [DRAW_H], 8
    MOV BYTE PTR [DRAW_COL], C_HPBG
    CALL FILL_RECT

    ;--- Barra HP verde (ancho proporcional a HP) ---
    MOV AL, BYTE PTR [PLAYER_HP]
    XOR AH, AH
    MOV WORD PTR [DRAW_X], 10
    MOV WORD PTR [DRAW_Y], 17
    MOV WORD PTR [DRAW_W], AX
    MOV WORD PTR [DRAW_H], 6
    MOV BYTE PTR [DRAW_COL], C_HPGREEN
    CALL FILL_RECT

    ;--- Borde de barra HP (superior) ---
    MOV WORD PTR [DRAW_X], 8
    MOV WORD PTR [DRAW_Y], 15
    MOV WORD PTR [DRAW_W], 104
    MOV WORD PTR [DRAW_H], 1
    MOV BYTE PTR [DRAW_COL], C_WHITE
    CALL FILL_RECT

    ;--- Borde de barra HP (inferior) ---
    MOV WORD PTR [DRAW_X], 8
    MOV WORD PTR [DRAW_Y], 24
    MOV WORD PTR [DRAW_W], 104
    MOV WORD PTR [DRAW_H], 1
    MOV BYTE PTR [DRAW_COL], C_WHITE
    CALL FILL_RECT

    ;--- Nombre "LINK" (arriba izquierda) ---
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 0
    MOV DL, 1
    INT 10h
    MOV SI, OFFSET STR_LINK
    MOV BL, C_YELLOW
    CALL ESCRIBIR_CADENA

    ;--- "HYRULE ARENA" (centrado arriba) ---
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 0
    MOV DL, 14
    INT 10h
    MOV SI, OFFSET STR_HYRULE
    MOV BL, C_WHITE
    CALL ESCRIBIR_CADENA

    ;--- Controles (abajo izquierda) ---
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 24
    MOV DL, 1
    INT 10h
    MOV SI, OFFSET STR_CTRL
    MOV BL, C_ORANGE
    CALL ESCRIBIR_CADENA

    ;--- ESC=SALIR (abajo derecha) ---
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 24
    MOV DL, 30
    INT 10h
    MOV SI, OFFSET STR_ESC
    MOV BL, C_RED
    CALL ESCRIBIR_CADENA

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DIBUJAR_UI ENDP

;--------------------------------------------------------------------
; ESCRIBIR_CADENA - Escribe una cadena terminada en 0 usando BIOS
; Entrada: SI = puntero a cadena, BL = color
;--------------------------------------------------------------------
ESCRIBIR_CADENA PROC
    PUSH AX
    PUSH BX
    PUSH SI

    MOV BH, 0                  ; Pagina de video 0

EC_SIGUIENTE:
    LODSB                       ; Cargar siguiente caracter
    CMP AL, 0
    JE EC_FIN
    MOV AH, 0Eh                ; Funcion teletype
    INT 10h
    JMP EC_SIGUIENTE

EC_FIN:
    POP SI
    POP BX
    POP AX
    RET
ESCRIBIR_CADENA ENDP

;--------------------------------------------------------------------
; MOSTRAR_INTRO - Muestra la secuencia "ROUND 1" y "FIGHT!"
;--------------------------------------------------------------------
MOSTRAR_INTRO PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ;--- Mostrar "- ROUND 1 -" ---
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 10                 ; Fila 10 (centrado vertical)
    MOV DL, 14                 ; Columna 14 (centrado horizontal)
    INT 10h
    MOV SI, OFFSET STR_ROUND
    MOV BL, C_WHITE
    CALL ESCRIBIR_CADENA

    ;--- Pausa dramatica (30 frames = ~0.5 seg) ---
    MOV CX, 30
MI_PAUSA1:
    CALL ESPERAR_RETRAZO
    LOOP MI_PAUSA1

    ;--- Mostrar "FIGHT!" ---
    MOV AH, 02h
    MOV BH, 0
    MOV DH, 12
    MOV DL, 17
    INT 10h
    MOV SI, OFFSET STR_FIGHT
    MOV BL, C_RED
    CALL ESCRIBIR_CADENA

    ;--- Pausa para leer (60 frames = ~1 seg) ---
    MOV CX, 60
MI_PAUSA2:
    CALL ESPERAR_RETRAZO
    LOOP MI_PAUSA2

    ;--- Borrar texto de intro (redibujar cielo encima) ---
    MOV WORD PTR [DRAW_X], 80
    MOV WORD PTR [DRAW_Y], 72
    MOV WORD PTR [DRAW_W], 170
    MOV WORD PTR [DRAW_H], 40
    MOV BYTE PTR [DRAW_COL], C_SKY
    CALL FILL_RECT

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
MOSTRAR_INTRO ENDP

;--------------------------------------------------------------------
; ACTUALIZAR_ANIM - Actualiza el estado y frame de la animacion
;--------------------------------------------------------------------
ACTUALIZAR_ANIM PROC
    PUSH AX
    PUSH BX

    MOV AL, BYTE PTR [ANIM_STATE]
    CMP AL, 0
    JE AA_IDLE
    CMP AL, 1
    JE AA_ATAQUE
    CMP AL, 2
    JE AA_PATADA
    JMP AA_FIN

AA_IDLE:
    ;--- Alternar frame idle cada 16 retrazos (efecto respiracion) ---
    MOV AX, WORD PTR [ANIM_TIMER]
    AND AX, 0Fh                ; Modulo 16
    CMP AX, 0
    JNE AA_IDLE_NOSWITCH
    XOR BYTE PTR [ANIM_FRAME], 1   ; Alternar 0/1
AA_IDLE_NOSWITCH:

    ;--- Seleccionar frame idle correspondiente ---
    MOV AL, BYTE PTR [ANIM_FRAME]
    AND AL, 1
    XOR AH, AH
    SHL AX, 1                  ; Multiplicar por 2 (tamano de WORD)
    MOV BX, AX
    MOV AX, WORD PTR [IDLE_FRAMES + BX]
    MOV WORD PTR [FRAME_PTR], AX
    JMP AA_FIN

AA_ATAQUE:
    ;--- Mostrar frame de ataque por 15 retrazos ---
    MOV AX, WORD PTR [ATTACK_FRAME]
    MOV WORD PTR [FRAME_PTR], AX
    INC BYTE PTR [ATTACK_TMR]
    CMP BYTE PTR [ATTACK_TMR], 15
    JB AA_FIN
    MOV BYTE PTR [ANIM_STATE], 0   ; Volver a idle
    MOV BYTE PTR [ATTACK_TMR], 0
    JMP AA_FIN

AA_PATADA:
    ;--- Mostrar frame de patada por 15 retrazos ---
    MOV AX, WORD PTR [KICK_FRAME]
    MOV WORD PTR [FRAME_PTR], AX
    INC BYTE PTR [ATTACK_TMR]
    CMP BYTE PTR [ATTACK_TMR], 15
    JB AA_FIN
    MOV BYTE PTR [ANIM_STATE], 0
    MOV BYTE PTR [ATTACK_TMR], 0

AA_FIN:
    POP BX
    POP AX
    RET
ACTUALIZAR_ANIM ENDP

;--------------------------------------------------------------------
; LIMPIAR_SPRITE - Limpia el area donde estaba el sprite anterior
; Redibuja el fondo (cielo + piso) en esa zona
;--------------------------------------------------------------------
LIMPIAR_SPRITE PROC
    PUSH AX

    ;--- Borrar area del sprite anterior con color de cielo ---
    MOV AX, WORD PTR [OLD_PX]
    MOV WORD PTR [DRAW_X], AX
    MOV AX, WORD PTR [OLD_PY]
    MOV WORD PTR [DRAW_Y], AX
    MOV WORD PTR [DRAW_W], 48  ; Ancho suficiente para todos los frames
    MOV WORD PTR [DRAW_H], 48  ; Alto del sprite + margen
    MOV BYTE PTR [DRAW_COL], C_SKY
    CALL FILL_RECT

    ;--- Redibujar la linea del piso (puede ser sobreescrita) ---
    CALL REDIBUJAR_PISO_LOCAL

    ;--- Guardar posicion actual como la antigua ---
    MOV AX, WORD PTR [PLAYER_X]
    MOV WORD PTR [OLD_PX], AX
    MOV AX, WORD PTR [PLAYER_Y]
    MOV WORD PTR [OLD_PY], AX

    POP AX
    RET
LIMPIAR_SPRITE ENDP

;--------------------------------------------------------------------
; REDIBUJAR_PISO_LOCAL - Redibuja el piso del escenario
;--------------------------------------------------------------------
REDIBUJAR_PISO_LOCAL PROC
    PUSH AX

    ;--- Linea naranja del borde ---
    MOV WORD PTR [DRAW_X], 0
    MOV WORD PTR [DRAW_Y], FLOOR_Y
    MOV WORD PTR [DRAW_W], SCREEN_W
    MOV WORD PTR [DRAW_H], 2
    MOV BYTE PTR [DRAW_COL], C_ORANGE
    CALL FILL_RECT

    ;--- Piso superior ---
    MOV WORD PTR [DRAW_X], 0
    MOV WORD PTR [DRAW_Y], FLOOR_Y + 2
    MOV WORD PTR [DRAW_W], SCREEN_W
    MOV WORD PTR [DRAW_H], 10
    MOV BYTE PTR [DRAW_COL], C_FLOOR1
    CALL FILL_RECT

    ;--- Linea decorativa ---
    MOV WORD PTR [DRAW_X], 0
    MOV WORD PTR [DRAW_Y], FLOOR_Y + 12
    MOV WORD PTR [DRAW_W], SCREEN_W
    MOV WORD PTR [DRAW_H], 1
    MOV BYTE PTR [DRAW_COL], C_DBROWN
    CALL FILL_RECT

    ;--- Piso medio ---
    MOV WORD PTR [DRAW_X], 0
    MOV WORD PTR [DRAW_Y], FLOOR_Y + 13
    MOV WORD PTR [DRAW_W], SCREEN_W
    MOV WORD PTR [DRAW_H], 9
    MOV BYTE PTR [DRAW_COL], C_FLOOR1
    CALL FILL_RECT

    ;--- Piso inferior ---
    MOV WORD PTR [DRAW_X], 0
    MOV WORD PTR [DRAW_Y], FLOOR_Y + 22
    MOV WORD PTR [DRAW_W], SCREEN_W
    MOV WORD PTR [DRAW_H], 20
    MOV BYTE PTR [DRAW_COL], C_FLOOR2
    CALL FILL_RECT

    POP AX
    RET
REDIBUJAR_PISO_LOCAL ENDP

;--------------------------------------------------------------------
; DIBUJAR_SOMBRA - Dibuja una sombra oscura debajo de Link
;--------------------------------------------------------------------
DIBUJAR_SOMBRA PROC
    PUSH AX

    MOV AX, WORD PTR [PLAYER_X]
    ADD AX, 3
    MOV WORD PTR [DRAW_X], AX
    MOV WORD PTR [DRAW_Y], FLOOR_Y + 2
    MOV WORD PTR [DRAW_W], 20
    MOV WORD PTR [DRAW_H], 3
    MOV BYTE PTR [DRAW_COL], C_DBROWN
    CALL FILL_RECT

    POP AX
    RET
DIBUJAR_SOMBRA ENDP

;--------------------------------------------------------------------
; DIBUJAR_LINK - Dibuja el sprite de Link leyendo los datos del frame
; Recorre la tabla de partes del frame actual y dibuja cada rectangulo
;--------------------------------------------------------------------
DIBUJAR_LINK PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI

    MOV SI, WORD PTR [FRAME_PTR]
    CMP SI, 0
    JE DL_FIN

DL_PARTE:
    ;--- Leer dx (primer byte de la parte) ---
    MOV AL, BYTE PTR [SI]
    CMP AL, 0FFh                ; Marcador de fin?
    JE DL_FIN

    ;--- Calcular X absoluto = PLAYER_X + dx ---
    XOR AH, AH
    ADD AX, WORD PTR [PLAYER_X]
    MOV WORD PTR [DRAW_X], AX

    ;--- Calcular Y absoluto = PLAYER_Y + dy ---
    MOV AL, BYTE PTR [SI+1]
    XOR AH, AH
    ADD AX, WORD PTR [PLAYER_Y]
    MOV WORD PTR [DRAW_Y], AX

    ;--- Ancho ---
    MOV AL, BYTE PTR [SI+2]
    XOR AH, AH
    MOV WORD PTR [DRAW_W], AX

    ;--- Alto ---
    MOV AL, BYTE PTR [SI+3]
    XOR AH, AH
    MOV WORD PTR [DRAW_H], AX

    ;--- Color ---
    MOV AL, BYTE PTR [SI+4]
    MOV BYTE PTR [DRAW_COL], AL

    ;--- Dibujar este rectangulo ---
    CALL FILL_RECT

    ;--- Avanzar al siguiente bloque de 5 bytes ---
    ADD SI, 5
    JMP DL_PARTE

DL_FIN:
    POP SI
    POP CX
    POP BX
    POP AX
    RET
DIBUJAR_LINK ENDP

;--------------------------------------------------------------------
; DIBUJAR_EFECTOS - Dibuja efectos visuales de ataque
;--------------------------------------------------------------------
DIBUJAR_EFECTOS PROC
    PUSH AX

    ;--- Efecto de espada (slash blanco) ---
    CMP BYTE PTR [ANIM_STATE], 1
    JNE DE_NO_ESPADA

    ; Linea de slash superior
    MOV AX, WORD PTR [PLAYER_X]
    ADD AX, 30
    MOV WORD PTR [DRAW_X], AX
    MOV AX, WORD PTR [PLAYER_Y]
    ADD AX, 8
    MOV WORD PTR [DRAW_Y], AX
    MOV WORD PTR [DRAW_W], 14
    MOV WORD PTR [DRAW_H], 1
    MOV BYTE PTR [DRAW_COL], C_WHITE
    CALL FILL_RECT

    ; Linea de slash inferior
    MOV AX, WORD PTR [PLAYER_X]
    ADD AX, 34
    MOV WORD PTR [DRAW_X], AX
    MOV AX, WORD PTR [PLAYER_Y]
    ADD AX, 16
    MOV WORD PTR [DRAW_Y], AX
    MOV WORD PTR [DRAW_W], 10
    MOV WORD PTR [DRAW_H], 1
    MOV BYTE PTR [DRAW_COL], C_WHITE
    CALL FILL_RECT

    ; Destello en la punta
    MOV AX, WORD PTR [PLAYER_X]
    ADD AX, 42
    MOV WORD PTR [DRAW_X], AX
    MOV AX, WORD PTR [PLAYER_Y]
    ADD AX, 11
    MOV WORD PTR [DRAW_Y], AX
    MOV WORD PTR [DRAW_W], 3
    MOV WORD PTR [DRAW_H], 3
    MOV BYTE PTR [DRAW_COL], C_YELLOW
    CALL FILL_RECT

DE_NO_ESPADA:
    ;--- Efecto de patada (impacto amarillo) ---
    CMP BYTE PTR [ANIM_STATE], 2
    JNE DE_NO_PATADA

    MOV AX, WORD PTR [PLAYER_X]
    ADD AX, 27
    MOV WORD PTR [DRAW_X], AX
    MOV AX, WORD PTR [PLAYER_Y]
    ADD AX, 27
    MOV WORD PTR [DRAW_Y], AX
    MOV WORD PTR [DRAW_W], 4
    MOV WORD PTR [DRAW_H], 4
    MOV BYTE PTR [DRAW_COL], C_YELLOW
    CALL FILL_RECT

    ; Lineas de impacto
    MOV AX, WORD PTR [PLAYER_X]
    ADD AX, 29
    MOV WORD PTR [DRAW_X], AX
    MOV AX, WORD PTR [PLAYER_Y]
    ADD AX, 25
    MOV WORD PTR [DRAW_Y], AX
    MOV WORD PTR [DRAW_W], 1
    MOV WORD PTR [DRAW_H], 8
    MOV BYTE PTR [DRAW_COL], C_WHITE
    CALL FILL_RECT

    MOV AX, WORD PTR [PLAYER_X]
    ADD AX, 26
    MOV WORD PTR [DRAW_X], AX
    MOV AX, WORD PTR [PLAYER_Y]
    ADD AX, 28
    MOV WORD PTR [DRAW_Y], AX
    MOV WORD PTR [DRAW_W], 8
    MOV WORD PTR [DRAW_H], 1
    MOV BYTE PTR [DRAW_COL], C_WHITE
    CALL FILL_RECT

DE_NO_PATADA:
    POP AX
    RET
DIBUJAR_EFECTOS ENDP

;====================================================================
; Punto de entrada del programa
;====================================================================
END INICIO
