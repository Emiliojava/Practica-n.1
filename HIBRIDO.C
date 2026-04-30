/*====================================================================
 * HIBRIDO.C - Programa Hibrido: Turbo C + Ensamblador en linea
 * Compilador: Turbo C / Turbo C++
 *
 * Descripcion:
 *   Limpia la pantalla usando ensamblador en linea (INT 10h)
 *   y luego muestra un mensaje de bienvenida usando C (printf).
 *
 * Compilacion (Turbo C):
 *   TCC HIBRIDO.C
 *
 * Ejecucion:
 *   HIBRIDO.EXE
 *====================================================================*/

#include <stdio.h>

/*--------------------------------------------------------------------
 * limpiar_pantalla()
 *
 * Usa INT 10h, funcion 06h (scroll up) para limpiar toda la
 * pantalla en modo texto 80x25.
 *
 * Registros:
 *   AH = 06h  -> Funcion: Scroll Up
 *   AL = 00h  -> Lineas a desplazar (0 = limpiar ventana completa)
 *   BH = 07h  -> Atributo: fondo negro, texto blanco
 *   CH = 00h  -> Fila superior izquierda
 *   CL = 00h  -> Columna superior izquierda
 *   DH = 18h  -> Fila inferior derecha  (24 = 18h)
 *   DL = 4Fh  -> Columna inferior derecha (79 = 4Fh)
 *--------------------------------------------------------------------*/
void limpiar_pantalla(void)
{
    asm {
        mov ah, 06h     /* Funcion: Scroll Up                     */
        mov al, 00h     /* Limpiar ventana completa                */
        mov bh, 07h     /* Atributo: blanco sobre negro            */
        mov ch, 00h     /* Esquina superior izquierda: fila 0      */
        mov cl, 00h     /* Esquina superior izquierda: columna 0   */
        mov dh, 18h     /* Esquina inferior derecha: fila 24       */
        mov dl, 4Fh     /* Esquina inferior derecha: columna 79    */
        int 10h         /* Llamada a la BIOS de video              */
    }
}

/*--------------------------------------------------------------------
 * posicionar_cursor()
 *
 * Usa INT 10h, funcion 02h para colocar el cursor en la posicion
 * (fila, columna) indicada.
 *
 * Registros:
 *   AH = 02h  -> Funcion: Posicionar Cursor
 *   BH = 00h  -> Pagina de video 0
 *   DH = fila
 *   DL = columna
 *--------------------------------------------------------------------*/
void posicionar_cursor(unsigned char fila, unsigned char columna)
{
    asm {
        mov ah, 02h     /* Funcion: Posicionar Cursor              */
        mov bh, 00h     /* Pagina de video 0                       */
        mov dh, fila    /* Fila destino                            */
        mov dl, columna /* Columna destino                         */
        int 10h         /* Llamada a la BIOS de video              */
    }
}

/*--------------------------------------------------------------------
 * main()
 *
 * 1. Limpia la pantalla con ensamblador (INT 10h).
 * 2. Posiciona el cursor en el centro con ensamblador (INT 10h).
 * 3. Muestra mensajes en C usando printf.
 *--------------------------------------------------------------------*/
int main(void)
{
    /* Paso 1: Limpiar pantalla usando ensamblador en linea */
    limpiar_pantalla();

    /* Paso 2: Posicionar cursor en fila 10, columna 20 */
    posicionar_cursor(10, 20);

    /* Paso 3: Mostrar mensajes usando C */
    printf("==========================================\n");
    printf("          PROGRAMA HIBRIDO               \n");
    printf("      Turbo C + Ensamblador (ASM)        \n");
    printf("==========================================\n");
    printf("\n");
    printf("   La pantalla fue limpiada usando        \n");
    printf("   ensamblador en linea (INT 10h).        \n");
    printf("\n");
    printf("   Este mensaje se muestra con printf()   \n");
    printf("   de la biblioteca estandar de C.        \n");
    printf("\n");
    printf("==========================================\n");
    printf("   Presione cualquier tecla para salir...\n");
    printf("==========================================\n");

    /* Paso 4: Esperar tecla usando ensamblador (INT 16h) */
    asm {
        mov ah, 00h     /* Funcion: Esperar tecla                  */
        int 16h         /* Llamada a la BIOS de teclado            */
    }

    /* Paso 5: Limpiar pantalla antes de salir */
    limpiar_pantalla();
    posicionar_cursor(0, 0);

    return 0;
}
