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

%}

/* OPCIONES */
%option noyywrap

/* ESTADOS */
%x COMMENT
%x BLOCK
%x VALUE

/* PATRONES */
WS              [ \t\r\n]+

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
    
    if (argc > 1) fclose(yyin);
    return 0;
}