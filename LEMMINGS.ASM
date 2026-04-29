; =====================================================================
;   LEMMINGS.ASM  -  Escena animada estilo Lemmings  (TASM / .COM)
;
;   Compilar:   TASM LEMMINGS.ASM
;               TLINK /t LEMMINGS.OBJ
;   Ejecutar:   LEMMINGS.COM   (en DOSBox u otro entorno DOS)
; =====================================================================
                .MODEL  TINY
                .186
                .CODE
                ORG     100h

; ---------------------------------------------------------------------
;   Constantes
; ---------------------------------------------------------------------
VIDEO_SEG       EQU     0A000h
SCR_W           EQU     320
SCR_H           EQU     200
GROUND_Y        EQU     130
PANEL_Y         EQU     168

C_BLACK         EQU     0
C_SKY1          EQU     1
C_SKY2          EQU     2
C_SKY3          EQU     3
C_SKY4          EQU     4
C_CLOUD         EQU     5
C_CLOUD_S       EQU     6
C_GRASS_L       EQU     7
C_GRASS_D       EQU     8
C_DIRT_L        EQU     9
C_DIRT_D        EQU     10
C_PLAT          EQU     11
C_PLAT_L        EQU     12
C_PLAT_D        EQU     13
C_UMBR          EQU     14
C_UMBR_L        EQU     15
C_CHUTE         EQU     16
C_SKIN          EQU     17
C_HAIR          EQU     18
C_BODY          EQU     19
C_PANEL         EQU     20
C_PANEL_B       EQU     21
C_TXT_Y         EQU     22
C_TXT_R         EQU     23
C_SIGN          EQU     24
C_SIGN_Y        EQU     25
C_WHITE         EQU     26

LEM_N           EQU     6
LEM_REC         EQU     4

; ---------------------------------------------------------------------
;   Punto de entrada (.COM => CS=DS=ES=SS, IP=100h)
; ---------------------------------------------------------------------
                jmp     start

; ---------------------------------------------------------------------
;   Paleta  (27 colores x 3 bytes  R,G,B  rango 0..63)
; ---------------------------------------------------------------------
palette         DB    0, 0, 0
                DB    4, 8,28
                DB   10,18,40
                DB   22,32,52
                DB   36,46,58
                DB   60,60,60
                DB   42,44,52
                DB   16,48,14
                DB    8,28,10
                DB   48,34,14
                DB   28,18, 6
                DB   34,34,36
                DB   46,46,48
                DB   18,18,22
                DB   56,12,12
                DB   63,44,44
                DB   58,34,12
                DB   56,40,32
                DB   16,52,24
                DB   20,20,56
                DB   40,36,24
                DB   22,18,10
                DB   63,60,20
                DB   58,24,24
                DB   40,24, 8
                DB   63,52, 0
                DB   63,63,63
palette_end     LABEL BYTE

; ---------------------------------------------------------------------
;   Tabla de lemmings: +0 = X (word), +2 = dir (byte 1/-1), +3 = pad
; ---------------------------------------------------------------------
lem_positions   DW  110
                DB    1, 0
                DW  135
                DB    1, 0
                DW  160
                DB  0FFh, 0
                DW  262
                DB    1, 0
                DW  290
                DB  0FFh, 0
                DW  312
                DB  0FFh, 0

frame_counter   DW  0

pstr_ptr        DW  0
pstr_row        DB  0
pstr_col        DB  0
pstr_color      DB  0

str_out         DB 'OUT 15', 0
str_in          DB 'IN 60', 0
str_time        DB 'TIME 4-00', 0
str_name        DB 'JUMPER', 0
str_skill       DB '15', 0

; =====================================================================
;   MAIN
; =====================================================================
start:
                mov     ax, 0013h
                int     10h
                cld

                call    load_palette

                mov     ax, VIDEO_SEG
                mov     es, ax

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

main_loop:
                mov     ah, 1
                int     16h
                jz      ml_nokey
                mov     ah, 0
                int     16h
                cmp     al, 27
                je      ml_quit
ml_nokey:
                call    redraw_walk_strip
                call    move_lemmings
                call    draw_lemmings
                call    delay_ticks
                inc     word ptr [frame_counter]
                jmp     main_loop

ml_quit:
                mov     ax, 0003h
                int     10h
                mov     ax, 4C00h
                int     21h

; =====================================================================
;                           PRIMITIVAS
; =====================================================================

; --- load_palette ----------------------------------------------------
load_palette    PROC NEAR
                pusha
                mov     dx, 03C8h
                xor     al, al
                out     dx, al
                mov     dx, 03C9h
                mov     si, OFFSET palette
                mov     cx, palette_end - palette
lp_loop:        lodsb
                out     dx, al
                loop    lp_loop
                popa
                ret
load_palette    ENDP

; --- fill_rect -------------------------------------------------------
;   AX=x  CX=y  BX=ancho  DX=alto  SI=color (byte bajo)
fill_rect       PROC NEAR
                pusha
                mov     di, cx
                shl     di, 8
                mov     bp, cx
                shl     bp, 6
                add     di, bp
                add     di, ax
                mov     ax, si
fr_row:         mov     cx, bx
                push    di
                rep     stosb
                pop     di
                add     di, SCR_W
                dec     dx
                jnz     fr_row
                popa
                ret
fill_rect       ENDP

; --- print_str -------------------------------------------------------
print_str       PROC NEAR
                pusha
                push    es
                mov     si, [pstr_ptr]
                xor     cx, cx
ps_cnt:         lodsb
                or      al, al
                jz      ps_dcnt
                inc     cx
                jmp     ps_cnt
ps_dcnt:        mov     bp, [pstr_ptr]
                mov     ax, ds
                mov     es, ax
                mov     ax, 1301h
                mov     bh, 0
                mov     bl, [pstr_color]
                mov     dh, [pstr_row]
                mov     dl, [pstr_col]
                int     10h
                pop     es
                popa
                ret
print_str       ENDP

; --- delay_ticks -----------------------------------------------------
delay_ticks     PROC NEAR
                push    ax
                push    bx
                push    cx
                push    dx
                push    si
                mov     ah, 0
                int     1Ah
                mov     bx, dx
                mov     si, cx
                add     bx, 2
                adc     si, 0
dt_wait:        mov     ah, 0
                int     1Ah
                cmp     cx, si
                jb      dt_wait
                ja      dt_done
                cmp     dx, bx
                jb      dt_wait
dt_done:        pop     si
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret
delay_ticks     ENDP

; =====================================================================
;                     ELEMENTOS DE LA ESCENA
; =====================================================================

; --- draw_sky --------------------------------------------------------
draw_sky        PROC NEAR
                mov     ax, 0
                mov     cx, 0
                mov     bx, SCR_W
                mov     dx, 30
                mov     si, C_SKY1
                call    fill_rect
                mov     ax, 0
                mov     cx, 30
                mov     bx, SCR_W
                mov     dx, 30
                mov     si, C_SKY2
                call    fill_rect
                mov     ax, 0
                mov     cx, 60
                mov     bx, SCR_W
                mov     dx, 35
                mov     si, C_SKY3
                call    fill_rect
                mov     ax, 0
                mov     cx, 95
                mov     bx, SCR_W
                mov     dx, 35
                mov     si, C_SKY4
                call    fill_rect
                ret
draw_sky        ENDP

; --- Variables de nube -----------------------------------------------
cld_x           DW  0
cld_y           DW  0

; --- draw_cloud ------------------------------------------------------
draw_cloud      PROC NEAR
                mov     [cld_x], ax
                mov     [cld_y], cx
                pusha
                mov     ax, [cld_x]
                add     ax, 2
                mov     cx, [cld_y]
                mov     bx, 36
                mov     dx, 7
                mov     si, C_CLOUD
                call    fill_rect
                mov     ax, [cld_x]
                add     ax, 2
                mov     cx, [cld_y]
                add     cx, 7
                mov     bx, 36
                mov     dx, 2
                mov     si, C_CLOUD_S
                call    fill_rect
                mov     ax, [cld_x]
                add     ax, 8
                mov     cx, [cld_y]
                sub     cx, 3
                mov     bx, 22
                mov     dx, 4
                mov     si, C_CLOUD
                call    fill_rect
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
draw_cloud      ENDP

; --- draw_clouds -----------------------------------------------------
draw_clouds     PROC NEAR
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
draw_clouds     ENDP

; --- draw_ground -----------------------------------------------------
draw_ground     PROC NEAR
                mov     ax, 0
                mov     cx, GROUND_Y
                mov     bx, SCR_W
                mov     dx, 4
                mov     si, C_GRASS_L
                call    fill_rect
                mov     ax, 0
                mov     cx, GROUND_Y + 4
                mov     bx, SCR_W
                mov     dx, 2
                mov     si, C_GRASS_D
                call    fill_rect
                mov     ax, 0
                mov     cx, GROUND_Y + 6
                mov     bx, SCR_W
                mov     dx, 12
                mov     si, C_DIRT_L
                call    fill_rect
                mov     ax, 0
                mov     cx, GROUND_Y + 18
                mov     bx, SCR_W
                mov     dx, PANEL_Y - (GROUND_Y + 18)
                mov     si, C_DIRT_D
                call    fill_rect
                ret
draw_ground     ENDP

; --- draw_platforms --------------------------------------------------
draw_platforms  PROC NEAR
                mov     ax, 45
                mov     cx, 110
                mov     bx, 10
                mov     dx, 20
                mov     si, C_PLAT
                call    fill_rect
                mov     ax, 80
                mov     cx, 110
                mov     bx, 10
                mov     dx, 20
                mov     si, C_PLAT
                call    fill_rect
                mov     ax, 40
                mov     cx, 103
                mov     bx, 60
                mov     dx, 5
                mov     si, C_PLAT_L
                call    fill_rect
                mov     ax, 40
                mov     cx, 108
                mov     bx, 60
                mov     dx, 2
                mov     si, C_PLAT_D
                call    fill_rect
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
draw_platforms  ENDP

; --- draw_sign -------------------------------------------------------
draw_sign       PROC NEAR
                mov     ax, 12
                mov     cx, 95
                mov     bx, 24
                mov     dx, 10
                mov     si, C_UMBR
                call    fill_rect
                mov     ax, 12
                mov     cx, 95
                mov     bx, 24
                mov     dx, 2
                mov     si, C_UMBR_L
                call    fill_rect
                mov     ax, 16
                mov     cx, 105
                mov     bx, 16
                mov     dx, 3
                mov     si, C_UMBR
                call    fill_rect
                mov     ax, 19
                mov     cx, 108
                mov     bx, 10
                mov     dx, 3
                mov     si, C_UMBR
                call    fill_rect
                mov     ax, 22
                mov     cx, 111
                mov     bx, 4
                mov     dx, 4
                mov     si, C_BLACK
                call    fill_rect
                ret
draw_sign       ENDP

; --- draw_umbrella ---------------------------------------------------
draw_umbrella   PROC NEAR
                mov     ax, 178
                mov     cx, 100
                mov     bx, 2
                mov     dx, 30
                mov     si, C_PLAT_D
                call    fill_rect
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
                mov     ax, 178
                mov     cx, 88
                mov     bx, 4
                mov     dx, 3
                mov     si, C_UMBR
                call    fill_rect
                ret
draw_umbrella   ENDP

; --- draw_parachute --------------------------------------------------
draw_parachute  PROC NEAR
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
                mov     ax, 82
                mov     cx, 57
                call    draw_lemming
                ret
draw_parachute  ENDP

; --- Variables de lemming --------------------------------------------
lem_px          DW 0
lem_py          DW 0

; --- draw_lemming (estatico) -----------------------------------------
draw_lemming    PROC NEAR
                mov     [lem_px], ax
                mov     [lem_py], cx
                pusha
                mov     ax, [lem_px]
                inc     ax
                mov     cx, [lem_py]
                sub     cx, 8
                mov     bx, 2
                mov     dx, 2
                mov     si, C_HAIR
                call    fill_rect
                mov     ax, [lem_px]
                inc     ax
                mov     cx, [lem_py]
                sub     cx, 6
                mov     bx, 2
                mov     dx, 2
                mov     si, C_SKIN
                call    fill_rect
                mov     ax, [lem_px]
                inc     ax
                mov     cx, [lem_py]
                sub     cx, 4
                mov     bx, 2
                mov     dx, 2
                mov     si, C_BODY
                call    fill_rect
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
                popa
                ret
draw_lemming    ENDP

; --- draw_lemming_anim (piernas alternan) ----------------------------
draw_lemming_anim PROC NEAR
                mov     [lem_px], ax
                mov     [lem_py], cx
                pusha
                mov     ax, [lem_px]
                inc     ax
                mov     cx, [lem_py]
                sub     cx, 8
                mov     bx, 2
                mov     dx, 2
                mov     si, C_HAIR
                call    fill_rect
                mov     ax, [lem_px]
                inc     ax
                mov     cx, [lem_py]
                sub     cx, 6
                mov     bx, 2
                mov     dx, 2
                mov     si, C_SKIN
                call    fill_rect
                mov     ax, [lem_px]
                inc     ax
                mov     cx, [lem_py]
                sub     cx, 4
                mov     bx, 2
                mov     dx, 2
                mov     si, C_BODY
                call    fill_rect

                mov     ax, [frame_counter]
                and     ax, 1
                jnz     la_tight

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
                jmp     la_done

la_tight:       mov     ax, [lem_px]
                inc     ax
                mov     cx, [lem_py]
                sub     cx, 2
                mov     bx, 2
                mov     dx, 2
                mov     si, C_BODY
                call    fill_rect
la_done:        popa
                ret
draw_lemming_anim ENDP

; --- draw_lemmings ---------------------------------------------------
draw_lemmings   PROC NEAR
                mov     di, OFFSET lem_positions
                mov     cx, LEM_N
dl_loop:        push    cx
                push    di
                mov     ax, [di]
                mov     cx, GROUND_Y
                call    draw_lemming_anim
                pop     di
                pop     cx
                add     di, LEM_REC
                loop    dl_loop
                ret
draw_lemmings   ENDP

; --- move_lemmings ---------------------------------------------------
move_lemmings   PROC NEAR
                mov     di, OFFSET lem_positions
                mov     cx, LEM_N
mv_loop:        mov     ax, [di]
                mov     dl, [di + 2]
                cmp     dl, 1
                je      mv_right
                cmp     ax, 6
                ja      mv_dec
                mov     byte ptr [di + 2], 1
                jmp     mv_nxt
mv_dec:         dec     ax
                mov     [di], ax
                jmp     mv_nxt
mv_right:       cmp     ax, 310
                jb      mv_inc
                mov     byte ptr [di + 2], 0FFh
                jmp     mv_nxt
mv_inc:         inc     ax
                mov     [di], ax
mv_nxt:         add     di, LEM_REC
                loop    mv_loop
                ret
move_lemmings   ENDP

; --- redraw_walk_strip -----------------------------------------------
redraw_walk_strip PROC NEAR
                mov     ax, 0
                mov     cx, GROUND_Y - 8
                mov     bx, SCR_W
                mov     dx, 8
                mov     si, C_SKY4
                call    fill_rect
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
                mov     ax, 178
                mov     cx, GROUND_Y - 8
                mov     bx, 2
                mov     dx, 8
                mov     si, C_PLAT_D
                call    fill_rect
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
redraw_walk_strip ENDP

; --- draw_panel ------------------------------------------------------
draw_panel      PROC NEAR
                mov     ax, 0
                mov     cx, PANEL_Y
                mov     bx, SCR_W
                mov     dx, SCR_H - PANEL_Y
                mov     si, C_PANEL
                call    fill_rect
                mov     ax, 0
                mov     cx, PANEL_Y
                mov     bx, SCR_W
                mov     dx, 1
                mov     si, C_PANEL_B
                call    fill_rect

                xor     bp, bp
dp_btn:         mov     ax, bp
                mov     bx, 26
                mul     bx
                add     ax, 4
                push    ax
                mov     cx, PANEL_Y + 4
                mov     bx, 24
                mov     dx, 20
                mov     si, C_PANEL_B
                call    fill_rect
                pop     ax
                inc     ax
                push    ax
                mov     cx, PANEL_Y + 5
                mov     bx, 22
                mov     dx, 18
                mov     si, C_PLAT
                call    fill_rect
                pop     ax
                add     ax, 8
                mov     cx, PANEL_Y + 8
                mov     bx, 8
                mov     dx, 6
                mov     si, C_PLAT_L
                call    fill_rect
                inc     bp
                cmp     bp, 12
                jb      dp_btn
                ret
draw_panel      ENDP

; --- draw_panel_numbers ----------------------------------------------
draw_panel_numbers PROC NEAR
                xor     bp, bp
dn_loop:        mov     ax, bp
                mov     bx, 26
                mul     bx
                add     ax, 5
                mov     bl, 8
                div     bl
                mov     [pstr_col], al
                mov     byte ptr [pstr_row], 20
                mov     byte ptr [pstr_color], C_TXT_Y
                mov     word ptr [pstr_ptr], OFFSET str_skill
                call    print_str
                inc     bp
                cmp     bp, 12
                jb      dn_loop
                ret
draw_panel_numbers ENDP

; --- draw_status_text ------------------------------------------------
draw_status_text PROC NEAR
                mov     byte ptr [pstr_row], 21
                mov     byte ptr [pstr_col], 1
                mov     byte ptr [pstr_color], C_TXT_Y
                mov     word ptr [pstr_ptr], OFFSET str_out
                call    print_str
                mov     byte ptr [pstr_col], 14
                mov     word ptr [pstr_ptr], OFFSET str_in
                call    print_str
                mov     byte ptr [pstr_col], 28
                mov     byte ptr [pstr_color], C_TXT_R
                mov     word ptr [pstr_ptr], OFFSET str_time
                call    print_str
                mov     byte ptr [pstr_row], 24
                mov     byte ptr [pstr_col], 17
                mov     byte ptr [pstr_color], C_WHITE
                mov     word ptr [pstr_ptr], OFFSET str_name
                call    print_str
                ret
draw_status_text ENDP

                END     start
