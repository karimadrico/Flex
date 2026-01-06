%{
/*
 * PRÁCTICA 1 - FLEX (Segunda Convocatoria) Karima Drafli Rico
 */

#include <stdio.h>
#include <string.h>

/* CONTADORES GLOBALES */
static int mediaBlocks = 0;         // Bloques @media
static int totalProperties = 0;     // Total de propiedades
static int importantCount = 0;      // Propiedades !important
static int measureCount = 0;        // Valores con unidades de medida

%}

/* OPCIONES */
%option noyywrap

/* ESTADOS */
%x COMMENT
%x BLOCK
%x VALUE

/* PATRONES */
WS              [ \t\r\n]+
UNIT            (pt|mm|cm|pc|in|px|em|ex)

%%

    /* Comentarios CSS */
"/*"                    { BEGIN(COMMENT); }
<COMMENT>"*/"           { BEGIN(INITIAL); }
<COMMENT>.|\n           { }

    /* Detectar bloques @media (estadística 1) */
<INITIAL>"@media"       { mediaBlocks++; }

    /* Ignorar espacios */
{WS}                    { }

    /* Detectar inicio de bloque */
<INITIAL>"{"            { BEGIN(BLOCK); }

    /* Ignorar otros caracteres en INITIAL */
<INITIAL>.              { }

    /* Dentro de bloque: detectar propiedades */
<BLOCK>{WS}             { }

<BLOCK>"}"              { BEGIN(INITIAL); }

<BLOCK>"/*"             { BEGIN(COMMENT); }

    /* Detectar propiedad: palabra seguida de : */
<BLOCK>[a-zA-Z-]+{WS}*":"  { 
    totalProperties++;
    BEGIN(VALUE);       // Pasar a analizar el valor
}

<BLOCK>.                { }

    /* Analizar valores de propiedades */
<VALUE>{WS}             { }

    /* Detectar !important (estadística 4) */
<VALUE>"!"{WS}*"important"  { importantCount++; }

    /* Detectar unidades de medida (estadística 5) */
<VALUE>[0-9]+\.?[0-9]*{UNIT}  { measureCount++; }

    /* Fin de valor con punto y coma */
<VALUE>";"              { BEGIN(BLOCK); }

    /* Comentarios dentro de valores */
<VALUE>"/*"             { BEGIN(COMMENT); }

    /* Ignorar otros caracteres en valores */
<VALUE>.                { }

%%

/* MAIN */
int main(int argc, char **argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "Error al abrir archivo\n");
            return 1;
        }
    }
    
    yylex();
    
    /* Mostrar resultados */
    printf("1. Número de bloques @media: %d\n", mediaBlocks);
    printf("2. Número total de propiedades: %d\n", totalProperties);
    printf("4. Número de propiedades !important: %d\n", importantCount);
    printf("5. Número de valores con unidades de medida: %d\n", measureCount);
    
    if (argc > 1) fclose(yyin);
    return 0;
}