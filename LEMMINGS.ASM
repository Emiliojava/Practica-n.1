; =====================================================================
;   LEMMINGS.ASM — Escena animada estilo Lemmings (TASM / .COM)
;   Compilar:  TASM LEMMINGS.ASM
;              TLINK /t LEMMINGS.OBJ
;   Ejecutar:  LEMMINGS.COM
; =====================================================================
                .MODEL  TINY
                .186
                LOCALS  @@
                .CODE
                ORG     100h

; ---------------------------------------------------------------------
;   Constantes
; ---------------------------------------------------------------------
VIDEO_SEG       equ     0A000h
SCR_W           equ     320
SCR_H           equ     200
GROUND_Y        equ     130                     ; linea del suelo
PANEL_Y         equ     168                     ; altura del panel inferior

; Indices dentro de nuestra paleta personalizada (ver "palette:")
C_BLACK         equ     0
C_SKY1          equ     1                       ; banda superior
C_SKY2          equ     2
C_SKY3          equ     3
C_SKY4          equ     4                       ; banda inferior (horizonte)
C_CLOUD         equ     5
C_CLOUD_S       equ     6
C_GRASS_L       equ     7
C_GRASS_D       equ     8
C_DIRT_L        equ     9
C_DIRT_D        equ     10
C_PLAT          equ     11
C_PLAT_L        equ     12
C_PLAT_D        equ     13
C_UMBR          equ     14
C_UMBR_L        equ     15
C_CHUTE         equ     16
C_SKIN          equ     17
C_HAIR          equ     18
C_BODY          equ     19
C_PANEL         equ     20
C_PANEL_B       equ     21
C_TXT_Y         equ     22
C_TXT_R         equ     23
C_SIGN          equ     24
C_SIGN_Y        equ     25
C_WHITE         equ     26

LEM_N           equ     6                       ; numero de lemmings animados
LEM_REC         equ     4                       ; bytes por registro

; ---------------------------------------------------------------------
;   Punto de entrada
; ---------------------------------------------------------------------
                jmp     start

; ---------------------------------------------------------------------
;   Paleta personalizada (27 colores x 3 bytes  R,G,B  en 0..63)
; ---------------------------------------------------------------------
palette:
                db    0, 0, 0                   ; 0  negro
                db    4, 8,28                   ; 1  cielo muy oscuro
                db   10,18,40                   ; 2  cielo oscuro
                db   22,32,52                   ; 3  cielo medio
                db   36,46,58                   ; 4  cielo claro (horizonte)
                db   60,60,60                   ; 5  nube (blanco)
                db   42,44,52                   ; 6  nube (sombra)
                db   16,48,14                   ; 7  pasto claro
                db    8,28,10                   ; 8  pasto oscuro
                db   48,34,14                   ; 9  tierra clara
                db   28,18, 6                   ; 10 tierra oscura
                db   34,34,36                   ; 11 plataforma gris
                db   46,46,48                   ; 12 plataforma luz
                db   18,18,22                   ; 13 plataforma sombra
                db   56,12,12                   ; 14 rojo sombrilla
                db   63,44,44                   ; 15 rojo claro
                db   58,34,12                   ; 16 paracaidas
                db   56,40,32                   ; 17 piel
                db   16,52,24                   ; 18 pelo verde
                db   20,20,56                   ; 19 cuerpo azul
                db   40,36,24                   ; 20 panel
                db   22,18,10                   ; 21 panel borde
                db   63,60,20                   ; 22 texto amarillo
                db   58,24,24                   ; 23 texto rojo
                db   40,24, 8                   ; 24 madera cartel
                db   63,52, 0                   ; 25 amarillo cartel
                db   63,63,63                   ; 26 blanco
palette_end:

; ---------------------------------------------------------------------
;   Estado de los 6 lemmings caminantes
;       +0..1 : x (word)
;       +2    : direccion  (1 = derecha, 0FFh = izquierda)
;       +3    : padding
; ---------------------------------------------------------------------
lem_positions:
                dw  110
                db    1, 0
                dw  135
                db    1, 0
                dw  160
                db  0FFh, 0
                dw  262
                db    1, 0
                dw  290
                db  0FFh, 0
                dw  312
                db  0FFh, 0

frame_counter   dw  0

; Parametros para print_str (se rellenan antes de cada llamada)
pstr_ptr        dw  0
pstr_row        db  0
pstr_col        db  0
pstr_color      db  0

; Cadenas (terminadas en 0)
str_out         db 'OUT 15', 0
str_in          db 'IN 60', 0
str_time        db 'TIME 4-00', 0
str_name        db 'JUMPER', 0
str_skill       db '15', 0

; =====================================================================
;   MAIN
; =====================================================================
start:
                ; --- Cambiar a modo 13h ------------------------------
                mov     ax, 0013h
                int     10h

                ; --- Cargar paleta personalizada ---------------------
                call    load_palette

                ; --- ES -> bufer de video ----------------------------
                mov     ax, VIDEO_SEG
                mov     es, ax

                ; --- Dibujar la escena completa ----------------------
                call    draw_sky
                call    draw_clouds
                call    draw_ground
                call    draw_platforms
                call    draw_sign
                call    draw_umbrella
                call    draw_parachute
                call    draw_panel
                call    draw_panel_numbers
                call    draw_status_text

                ; ---------------------------------------------------------
                ;  Bucle principal : animar lemmings hasta pulsar ESC
                ; ---------------------------------------------------------
main_loop:
                ; Hay tecla disponible?
                mov     ah, 1
                int     16h
                jz      @@no_key
                mov     ah, 0
                int     16h
                cmp     al, 27                  ; ESC
                je      @@quit
@@no_key:
                call    redraw_walk_strip
                call    move_lemmings
                call    draw_lemmings
                call    delay_ticks
                inc     [frame_counter]
                jmp     main_loop

@@quit:
                ; Restaurar modo texto 80x25 y volver al DOS
                mov     ax, 0003h
                int     10h
                mov     ax, 4C00h
                int     21h

; =====================================================================
;                           PRIMITIVAS
; =====================================================================

; ---------------------------------------------------------------------
;   load_palette
;     Envia 'palette' a los registros DAC (indices 0..N).
; ---------------------------------------------------------------------
load_palette:
                pusha
                mov     dx, 03C8h               ; indice a programar
                xor     al, al
                out     dx, al
                mov     dx, 03C9h               ; datos R,G,B
                mov     si, offset palette
                mov     cx, (palette_end - palette)
@@pl:           lodsb
                out     dx, al
                loop    @@pl
                popa
                ret

; ---------------------------------------------------------------------
;   fill_rect
;     Entrada:  AX = x,   CX = y,   BX = ancho,  DX = alto
;               SI = color (se usa solo el byte bajo)
;     Rellena un rectangulo solido en el bufer de video (ES).
; ---------------------------------------------------------------------
fill_rect:
                pusha
                ; DI = y * 320 + x     (320 = 256 + 64)
                mov     di, cx
                shl     di, 8                   ; y * 256
                mov     bp, cx
                shl     bp, 6                   ; y * 64
                add     di, bp
                add     di, ax                  ; + x
                mov     ax, si                  ; AL = color
@@row:
                mov     cx, bx                  ; ancho de la fila
                push    di
                rep     stosb
                pop     di
                add     di, SCR_W               ; siguiente fila
                dec     dx
                jnz     @@row
                popa
                ret

; ---------------------------------------------------------------------
;   print_str
;     Dibuja una cadena ASCII (terminada en 0) usando la fuente 8x8 de
;     la BIOS (INT 10h / AH=13h).  Los parametros se pasan por memoria:
;       [pstr_ptr]    = offset de la cadena
;       [pstr_row]    = fila (texto, 0..24)
;       [pstr_col]    = columna (texto, 0..39)
;       [pstr_color]  = indice de color (0..255)
; ---------------------------------------------------------------------
print_str:
                pusha
                push    es

                ; Contar la longitud de la cadena
                mov     si, [pstr_ptr]
                xor     cx, cx
@@cnt:          lodsb
                or      al, al
                jz      @@done_cnt
                inc     cx
                jmp     @@cnt
@@done_cnt:
                mov     bp, [pstr_ptr]
                mov     ax, ds
                mov     es, ax                  ; ES:BP -> cadena
                mov     ax, 1301h               ; escribe cadena y mueve cursor
                mov     bh, 0                   ; pagina 0
                mov     bl, [pstr_color]
                mov     dh, [pstr_row]
                mov     dl, [pstr_col]
                int     10h

                pop     es
                popa
                ret

; ---------------------------------------------------------------------
;   delay_ticks
;     Pequena pausa usando el contador de ticks del BIOS (~55 ms/tick).
; ---------------------------------------------------------------------
delay_ticks:
                push    ax
                push    bx
                push    cx
                push    dx
                mov     ah, 0
                int     1Ah                     ; CX:DX = numero de ticks
                mov     bx, dx
                add     bx, 2                   ; ~110 ms (9 fps aprox.)
@@w:            mov     ah, 0
                int     1Ah
                cmp     dx, bx
                jb      @@w
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret

; =====================================================================
;                        ELEMENTOS DE LA ESCENA
; =====================================================================

; ---------------------------------------------------------------------
;   draw_sky — degradado del cielo en 4 bandas
; ---------------------------------------------------------------------
draw_sky:
                ; Banda 1 (y 0..29)
                mov     ax, 0
                mov     cx, 0
                mov     bx, SCR_W
                mov     dx, 30
                mov     si, C_SKY1
                call    fill_rect
                ; Banda 2 (y 30..59)
                mov     ax, 0
                mov     cx, 30
                mov     bx, SCR_W
                mov     dx, 30
                mov     si, C_SKY2
                call    fill_rect
                ; Banda 3 (y 60..94)
                mov     ax, 0
                mov     cx, 60
                mov     bx, SCR_W
                mov     dx, 35
                mov     si, C_SKY3
                call    fill_rect
                ; Banda 4 (y 95..129) — horizonte
                mov     ax, 0
                mov     cx, 95
                mov     bx, SCR_W
                mov     dx, 35
                mov     si, C_SKY4
                call    fill_rect
                ret

; ---------------------------------------------------------------------
;   Variables temporales para la nube
; ---------------------------------------------------------------------
cld_x           dw  0
cld_y           dw  0

; ---------------------------------------------------------------------
;   draw_cloud —  AX = x izq,  CX = y superior
; ---------------------------------------------------------------------
draw_cloud:
                mov     [cld_x], ax
                mov     [cld_y], cx
                pusha
                ; Cuerpo principal (36 x 7)
                mov     ax, [cld_x]
                add     ax, 2
                mov     cx, [cld_y]
                mov     bx, 36
                mov     dx, 7
                mov     si, C_CLOUD
                call    fill_rect
                ; Sombra bajo el cuerpo (36 x 2)
                mov     ax, [cld_x]
                add     ax, 2
                mov     cx, [cld_y]
                add     cx, 7
                mov     bx, 36
                mov     dx, 2
                mov     si, C_CLOUD_S
                call    fill_rect
                ; Lobulo superior (22 x 4)
                mov     ax, [cld_x]
                add     ax, 8
                mov     cx, [cld_y]
                sub     cx, 3
                mov     bx, 22
                mov     dx, 4
                mov     si, C_CLOUD
                call    fill_rect
                ; Extensiones laterales
                mov     ax, [cld_x]
                mov     cx, [cld_y]
                add     cx, 2
                mov     bx, 4
                mov     dx, 4
                mov     si, C_CLOUD
                call    fill_rect

                mov     ax, [cld_x]
                add     ax, 36
                mov     cx, [cld_y]
                add     cx, 2
                mov     bx, 4
                mov     dx, 4
                mov     si, C_CLOUD
                call    fill_rect
                popa
                ret

; ---------------------------------------------------------------------
;   draw_clouds
; ---------------------------------------------------------------------
draw_clouds:
                mov     ax, 18
                mov     cx, 20
                call    draw_cloud
                mov     ax, 100
                mov     cx, 14
                call    draw_cloud
                mov     ax, 205
                mov     cx, 28
                call    draw_cloud
                mov     ax, 258
                mov     cx, 48
                call    draw_cloud
                mov     ax, 52
                mov     cx, 60
                call    draw_cloud
                mov     ax, 160
                mov     cx, 58
                call    draw_cloud
                ret

; ---------------------------------------------------------------------
;   draw_ground — cesped + tierra hasta el panel
; ---------------------------------------------------------------------
draw_ground:
                ; Pasto claro (y 130..133)
                mov     ax, 0
                mov     cx, GROUND_Y
                mov     bx, SCR_W
                mov     dx, 4
                mov     si, C_GRASS_L
                call    fill_rect
                ; Franja de pasto oscuro (y 134..135)
                mov     ax, 0
                mov     cx, GROUND_Y + 4
                mov     bx, SCR_W
                mov     dx, 2
                mov     si, C_GRASS_D
                call    fill_rect
                ; Tierra clara (y 136..147)
                mov     ax, 0
                mov     cx, GROUND_Y + 6
                mov     bx, SCR_W
                mov     dx, 12
                mov     si, C_DIRT_L
                call    fill_rect
                ; Tierra oscura hasta la base del panel (y 148..167)
                mov     ax, 0
                mov     cx, GROUND_Y + 18
                mov     bx, SCR_W
                mov     dx, PANEL_Y - (GROUND_Y + 18)
                mov     si, C_DIRT_D
                call    fill_rect
                ret

; ---------------------------------------------------------------------
;   draw_platforms — dos plataformas grises con pilares
; ---------------------------------------------------------------------
draw_platforms:
                ; --- Plataforma izquierda -----------------------------
                ; Pilar 1
                mov     ax, 45
                mov     cx, 110
                mov     bx, 10
                mov     dx, 20
                mov     si, C_PLAT
                call    fill_rect
                ; Pilar 2
                mov     ax, 80
                mov     cx, 110
                mov     bx, 10
                mov     dx, 20
                mov     si, C_PLAT
                call    fill_rect
                ; Tapa clara
                mov     ax, 40
                mov     cx, 103
                mov     bx, 60
                mov     dx, 5
                mov     si, C_PLAT_L
                call    fill_rect
                ; Base oscura
                mov     ax, 40
                mov     cx, 108
                mov     bx, 60
                mov     dx, 2
                mov     si, C_PLAT_D
                call    fill_rect

                ; --- Plataforma derecha -------------------------------
                mov     ax, 200
                mov     cx, 110
                mov     bx, 10
                mov     dx, 20
                mov     si, C_PLAT
                call    fill_rect
                mov     ax, 240
                mov     cx, 110
                mov     bx, 10
                mov     dx, 20
                mov     si, C_PLAT
                call    fill_rect
                mov     ax, 195
                mov     cx, 103
                mov     bx, 60
                mov     dx, 5
                mov     si, C_PLAT_L
                call    fill_rect
                mov     ax, 195
                mov     cx, 108
                mov     bx, 60
                mov     dx, 2
                mov     si, C_PLAT_D
                call    fill_rect
                ret

; ---------------------------------------------------------------------
;   draw_sign — el embudo rojo a la izquierda (la "trampa")
; ---------------------------------------------------------------------
draw_sign:
                ; Cuerpo superior
                mov     ax, 12
                mov     cx, 95
                mov     bx, 24
                mov     dx, 10
                mov     si, C_UMBR
                call    fill_rect
                ; Franja clara
                mov     ax, 12
                mov     cx, 95
                mov     bx, 24
                mov     dx, 2
                mov     si, C_UMBR_L
                call    fill_rect
                ; Pico 1
                mov     ax, 16
                mov     cx, 105
                mov     bx, 16
                mov     dx, 3
                mov     si, C_UMBR
                call    fill_rect
                ; Pico 2
                mov     ax, 19
                mov     cx, 108
                mov     bx, 10
                mov     dx, 3
                mov     si, C_UMBR
                call    fill_rect
                ; Boca negra
                mov     ax, 22
                mov     cx, 111
                mov     bx, 4
                mov     dx, 4
                mov     si, C_BLACK
                call    fill_rect
                ret

; ---------------------------------------------------------------------
;   draw_umbrella — sombrilla roja/blanca con poste
; ---------------------------------------------------------------------
draw_umbrella:
                ; Poste
                mov     ax, 178
                mov     cx, 100
                mov     bx, 2
                mov     dx, 30
                mov     si, C_PLAT_D
                call    fill_rect
                ; Domo (anillos concentricos, cada uno mas estrecho)
                mov     ax, 160
                mov     cx, 100
                mov     bx, 40
                mov     dx, 3
                mov     si, C_UMBR
                call    fill_rect
                mov     ax, 164
                mov     cx, 97
                mov     bx, 32
                mov     dx, 3
                mov     si, C_UMBR_L
                call    fill_rect
                mov     ax, 170
                mov     cx, 94
                mov     bx, 20
                mov     dx, 3
                mov     si, C_UMBR
                call    fill_rect
                mov     ax, 175
                mov     cx, 91
                mov     bx, 10
                mov     dx, 3
                mov     si, C_UMBR_L
                call    fill_rect
                ; Punta
                mov     ax, 178
                mov     cx, 88
                mov     bx, 4
                mov     dx, 3
                mov     si, C_UMBR
                call    fill_rect
                ret

; ---------------------------------------------------------------------
;   draw_parachute — paracaidas naranja con un lemming colgando
; ---------------------------------------------------------------------
draw_parachute:
                ; Cupula
                mov     ax, 70
                mov     cx, 35
                mov     bx, 30
                mov     dx, 4
                mov     si, C_CHUTE
                call    fill_rect
                mov     ax, 74
                mov     cx, 31
                mov     bx, 22
                mov     dx, 4
                mov     si, C_CHUTE
                call    fill_rect
                mov     ax, 79
                mov     cx, 27
                mov     bx, 12
                mov     dx, 4
                mov     si, C_CHUTE
                call    fill_rect
                ; Cuerdas
                mov     ax, 73
                mov     cx, 39
                mov     bx, 1
                mov     dx, 10
                mov     si, C_BLACK
                call    fill_rect
                mov     ax, 96
                mov     cx, 39
                mov     bx, 1
                mov     dx, 10
                mov     si, C_BLACK
                call    fill_rect
                ; Lemming colgando
                mov     ax, 82
                mov     cx, 57
                call    draw_lemming
                ret

; ---------------------------------------------------------------------
;   draw_lemming
;     Dibuja un lemming con piernas "juntas" (postura estatica).
;     Entrada:  AX = x izquierdo (4 px de ancho),
;               CX = y de los pies.
; ---------------------------------------------------------------------
lem_px          dw 0
lem_py          dw 0

draw_lemming:
                mov     [lem_px], ax
                mov     [lem_py], cx
                pusha
                ; Pelo (2 x 2)
                mov     ax, [lem_px]
                inc     ax
                mov     cx, [lem_py]
                sub     cx, 8
                mov     bx, 2
                mov     dx, 2
                mov     si, C_HAIR
                call    fill_rect
                ; Cara (2 x 2)
                mov     ax, [lem_px]
                inc     ax
                mov     cx, [lem_py]
                sub     cx, 6
                mov     bx, 2
                mov     dx, 2
                mov     si, C_SKIN
                call    fill_rect
                ; Cuerpo (2 x 2)
                mov     ax, [lem_px]
                inc     ax
                mov     cx, [lem_py]
                sub     cx, 4
                mov     bx, 2
                mov     dx, 2
                mov     si, C_BODY
                call    fill_rect
                ; Pierna izquierda (1 x 2)
                mov     ax, [lem_px]
                mov     cx, [lem_py]
                sub     cx, 2
                mov     bx, 1
                mov     dx, 2
                mov     si, C_BODY
                call    fill_rect
                ; Pierna derecha (1 x 2)
                mov     ax, [lem_px]
                add     ax, 3
                mov     cx, [lem_py]
                sub     cx, 2
                mov     bx, 1
                mov     dx, 2
                mov     si, C_BODY
                call    fill_rect
                popa
                ret

; ---------------------------------------------------------------------
;   draw_lemming_anim
;     Dibuja un lemming cuya postura depende de [frame_counter].
;     La unica parte que cambia son las piernas (abiertas o juntas);
;     pelo / cara / cuerpo se dibujan en su posicion fija.
; ---------------------------------------------------------------------
draw_lemming_anim:
                mov     [lem_px], ax
                mov     [lem_py], cx
                pusha
                ; Pelo
                mov     ax, [lem_px]
                inc     ax
                mov     cx, [lem_py]
                sub     cx, 8
                mov     bx, 2
                mov     dx, 2
                mov     si, C_HAIR
                call    fill_rect
                ; Cara
                mov     ax, [lem_px]
                inc     ax
                mov     cx, [lem_py]
                sub     cx, 6
                mov     bx, 2
                mov     dx, 2
                mov     si, C_SKIN
                call    fill_rect
                ; Cuerpo
                mov     ax, [lem_px]
                inc     ax
                mov     cx, [lem_py]
                sub     cx, 4
                mov     bx, 2
                mov     dx, 2
                mov     si, C_BODY
                call    fill_rect

                ; Piernas — alternan segun el bit 0 del contador
                mov     ax, [frame_counter]
                and     ax, 1
                jnz     @@legs_tight

                ; Postura "abierta" : pies en los extremos
                mov     ax, [lem_px]
                mov     cx, [lem_py]
                sub     cx, 2
                mov     bx, 1
                mov     dx, 2
                mov     si, C_BODY
                call    fill_rect

                mov     ax, [lem_px]
                add     ax, 3
                mov     cx, [lem_py]
                sub     cx, 2
                mov     bx, 1
                mov     dx, 2
                mov     si, C_BODY
                call    fill_rect
                jmp     @@done_legs

@@legs_tight:
                ; Postura "junta" : un solo bloque 2 px
                mov     ax, [lem_px]
                inc     ax
                mov     cx, [lem_py]
                sub     cx, 2
                mov     bx, 2
                mov     dx, 2
                mov     si, C_BODY
                call    fill_rect
@@done_legs:
                popa
                ret

; ---------------------------------------------------------------------
;   draw_lemmings — recorre la tabla lem_positions
; ---------------------------------------------------------------------
draw_lemmings:
                mov     di, offset lem_positions
                mov     cx, LEM_N
@@dl:
                push    cx
                push    di
                mov     ax, [di]                ; x
                mov     cx, GROUND_Y            ; pies = linea de suelo
                call    draw_lemming_anim
                pop     di
                pop     cx
                add     di, LEM_REC
                loop    @@dl
                ret

; ---------------------------------------------------------------------
;   move_lemmings — actualiza las X y rebota en los bordes
; ---------------------------------------------------------------------
move_lemmings:
                mov     di, offset lem_positions
                mov     cx, LEM_N
@@ml:
                mov     ax, [di]
                mov     dl, [di + 2]
                cmp     dl, 1
                je      @@right

                ; Caminando a la izquierda
                cmp     ax, 6
                ja      @@dec
                mov     byte ptr [di + 2], 1
                jmp     @@nxt
@@dec:          dec     ax
                mov     [di], ax
                jmp     @@nxt
@@right:
                cmp     ax, 310
                jb      @@inc
                mov     byte ptr [di + 2], 0FFh
                jmp     @@nxt
@@inc:          inc     ax
                mov     [di], ax
@@nxt:
                add     di, LEM_REC
                loop    @@ml
                ret

; ---------------------------------------------------------------------
;   redraw_walk_strip
;     Repinta la franja por donde pasan los lemmings (y = 122..129).
;     Primero se rellena con cielo y despues se vuelven a dibujar los
;     pilares y el poste de la sombrilla que cruzan esa zona, asi
;     los lemmings borrados no dejan huecos en los elementos fijos.
; ---------------------------------------------------------------------
redraw_walk_strip:
                ; Limpiar toda la franja a color cielo
                mov     ax, 0
                mov     cx, GROUND_Y - 8
                mov     bx, SCR_W
                mov     dx, 8
                mov     si, C_SKY4
                call    fill_rect

                ; Pilares de la plataforma izquierda
                mov     ax, 45
                mov     cx, GROUND_Y - 8
                mov     bx, 10
                mov     dx, 8
                mov     si, C_PLAT
                call    fill_rect
                mov     ax, 80
                mov     cx, GROUND_Y - 8
                mov     bx, 10
                mov     dx, 8
                mov     si, C_PLAT
                call    fill_rect

                ; Poste de la sombrilla
                mov     ax, 178
                mov     cx, GROUND_Y - 8
                mov     bx, 2
                mov     dx, 8
                mov     si, C_PLAT_D
                call    fill_rect

                ; Pilares de la plataforma derecha
                mov     ax, 200
                mov     cx, GROUND_Y - 8
                mov     bx, 10
                mov     dx, 8
                mov     si, C_PLAT
                call    fill_rect
                mov     ax, 240
                mov     cx, GROUND_Y - 8
                mov     bx, 10
                mov     dx, 8
                mov     si, C_PLAT
                call    fill_rect
                ret

; ---------------------------------------------------------------------
;   draw_panel — fondo del panel inferior con 12 botones
; ---------------------------------------------------------------------
draw_panel:
                ; Fondo del panel
                mov     ax, 0
                mov     cx, PANEL_Y
                mov     bx, SCR_W
                mov     dx, SCR_H - PANEL_Y
                mov     si, C_PANEL
                call    fill_rect
                ; Linea superior (borde)
                mov     ax, 0
                mov     cx, PANEL_Y
                mov     bx, SCR_W
                mov     dx, 1
                mov     si, C_PANEL_B
                call    fill_rect

                ; 12 botones de habilidad (26 px de ancho, separados)
                xor     bp, bp
@@bt:
                ; x = bp * 26 + 4
                mov     ax, bp
                mov     bx, 26
                mul     bx
                add     ax, 4
                push    ax

                ; Marco del boton
                mov     cx, PANEL_Y + 4
                mov     bx, 24
                mov     dx, 20
                mov     si, C_PANEL_B
                call    fill_rect

                ; Interior del boton (1 px de borde)
                pop     ax
                inc     ax
                push    ax
                mov     cx, PANEL_Y + 5
                mov     bx, 22
                mov     dx, 18
                mov     si, C_PLAT
                call    fill_rect

                ; Pequeno simbolo: cuadrado mas claro en el centro
                pop     ax
                add     ax, 8
                mov     cx, PANEL_Y + 8
                mov     bx, 8
                mov     dx, 6
                mov     si, C_PLAT_L
                call    fill_rect

                inc     bp
                cmp     bp, 12
                jb      @@bt
                ret

; ---------------------------------------------------------------------
;   draw_panel_numbers — "15" encima de cada boton usando BIOS
; ---------------------------------------------------------------------
draw_panel_numbers:
                xor     bp, bp
@@nb:
                ; Columna de texto = (bp * 26 + 5) / 8
                mov     ax, bp
                mov     bx, 26
                mul     bx
                add     ax, 5
                mov     bl, 8
                div     bl                      ; AL = columna
                mov     [pstr_col], al
                mov     [pstr_row], 20
                mov     [pstr_color], C_TXT_Y
                mov     [pstr_ptr], offset str_skill
                call    print_str

                inc     bp
                cmp     bp, 12
                jb      @@nb
                ret

; ---------------------------------------------------------------------
;   draw_status_text
; ---------------------------------------------------------------------
draw_status_text:
                ; "OUT 15"
                mov     [pstr_row], 21
                mov     [pstr_col], 1
                mov     [pstr_color], C_TXT_Y
                mov     [pstr_ptr], offset str_out
                call    print_str

                ; "IN 60"
                mov     [pstr_col], 14
                mov     [pstr_ptr], offset str_in
                call    print_str

                ; "TIME 4-00"
                mov     [pstr_col], 28
                mov     [pstr_color], C_TXT_R
                mov     [pstr_ptr], offset str_time
                call    print_str

                ; "JUMPER" — rotulo de nivel
                mov     [pstr_row], 24
                mov     [pstr_col], 17
                mov     [pstr_color], C_WHITE
                mov     [pstr_ptr], offset str_name
                call    print_str
                ret

                END     start
