%{
/*
 * PRÁCTICA 1 - FLEX (Segunda Convocatoria) Karima Drafli Rico
  */

#include <stdio.h>
#include <string.h>

/*------------------------------------------------------------------------------
 * CONTADORES GLOBALES
 *----------------------------------------------------------------------------*/
static int totalProperties = 0;     // Total de propiedades

%}

/*------------------------------------------------------------------------------
 * OPCIONES
 *------------------------------------------------------------------------------*/
%option noyywrap

/*------------------------------------------------------------------------------
 * ESTADOS
 *------------------------------------------------------------------------------*/
%x COMMENT

/*------------------------------------------------------------------------------
 * PATRONES
 *------------------------------------------------------------------------------*/
WS              [ \t\r\n]+

%%

/*------------------------------------------------------------------------------
 * REGLAS
 *------------------------------------------------------------------------------*/

/* Comentarios CSS */
"/*"                    { BEGIN(COMMENT); }
<COMMENT>"*/"           { BEGIN(INITIAL); }
<COMMENT>.|\n           { }

/* Ignorar espacios */
{WS}                    { }

/* Detectar propiedades simples: palabra seguida de : */
[a-zA-Z-]+{WS}*":"      { totalProperties++; }

/* Ignorar todo lo demás */
.                       { }

%%

/*------------------------------------------------------------------------------
 * MAIN
 *------------------------------------------------------------------------------*/
int main(int argc, char **argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "Error al abrir archivo\n");
            return 1;
        }
    }
    
    yylex();
    
    printf("Total propiedades: %d\n", totalProperties);
    
    if (argc > 1) fclose(yyin);
    return 0;
}