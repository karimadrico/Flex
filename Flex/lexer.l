%{
/*
 * PRÁCTICA 1 - FLEX (Segunda Convocatoria) Karima Drafli Rico
 */

#include <stdio.h>
#include <string.h>

/* CONTADORES GLOBALES */
static int mediaBlocks = 0;         
static int totalProperties = 0;     
static int importantCount = 0;      
static int measureCount = 0;        
static int colorCount = 0;          

%}

/* OPCIONES */
%option noyywrap

/* ESTADOS */
%x COMMENT
%x BLOCK
%x VALUE
%x DQSTR
%x SQSTR

/* PATRONES */
WS              [ \t\r\n]+
UNIT            (pt|mm|cm|pc|in|px|em|ex)

HEX3            #[0-9A-Fa-f]{3}
HEX6            #[0-9A-Fa-f]{6}
HEX8            #[0-9A-Fa-f]{8}

%%

    /* Comentarios CSS */
"/*"                    { BEGIN(COMMENT); }
<COMMENT>"*/"           { BEGIN(INITIAL); }
<COMMENT>.|\n           { }

    /* Detectar bloques @media */
<INITIAL>"@media"       { mediaBlocks++; }

    /* Ignorar espacios */
{WS}                    { }

    /* Detectar inicio de bloque */
<INITIAL>"{"            { BEGIN(BLOCK); }

    /* Ignorar otros caracteres en INITIAL */
<INITIAL>.              { }

    /* Dentro de bloque */
<BLOCK>{WS}             { }

<BLOCK>"}"              { BEGIN(INITIAL); }

<BLOCK>"/*"             { BEGIN(COMMENT); }

    /* Detectar propiedad */
<BLOCK>[a-zA-Z-]+{WS}*":"  { 
    totalProperties++;
    BEGIN(VALUE);
}

<BLOCK>.                { }

    /* Analizar valores */
<VALUE>{WS}             { }

    /* !important */
<VALUE>"!"{WS}*"important"  { importantCount++; }

    /* Unidades de medida */
<VALUE>[0-9]+\.?[0-9]*{UNIT}  { measureCount++; }

    /* Colores HEX (orden importante: más largo primero) */
<VALUE>{HEX8}           { colorCount++; }
<VALUE>{HEX6}           { colorCount++; }
<VALUE>{HEX3}           { colorCount++; }

    /* RGB y RGBA */
<VALUE>rgba?\([^)]*\)   { colorCount++; }

    /* Nombres de color */
<VALUE>black|gray|grey|silver|white|maroon|red|purple|fuchsia|green|lime|olive|yellow|navy|blue|teal|aqua|orange  { colorCount++; }

    /* Fin de valor */
<VALUE>";"              { BEGIN(BLOCK); }

    /* Comentarios en valores */
<VALUE>"/*"             { BEGIN(COMMENT); }

    /* Ignorar otros */
<VALUE>.                { }

    /* Cadenas entre comillas dobles */
<VALUE>"\""             { BEGIN(DQSTR); }
<DQSTR>"\\\\"           { }
<DQSTR>"\\\""           { }
<DQSTR>"\""             { BEGIN(VALUE); }
<DQSTR>.|\n             { }

    /* Cadenas entre comillas simples */
<VALUE>"\'"             { BEGIN(SQSTR); }
<SQSTR>"\\\\"           { }
<SQSTR>"\\\'"           { }
<SQSTR>"\'"             { BEGIN(VALUE); }
<SQSTR>.|\n             { }

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
    
    printf("1. Número de bloques @media: %d\n", mediaBlocks);
    printf("2. Número total de propiedades: %d\n", totalProperties);
    printf("4. Número de propiedades !important: %d\n", importantCount);
    printf("5. Número de valores con unidades de medida: %d\n", measureCount);
    printf("6. Número de especificaciones de color: %d\n", colorCount);
    
    if (argc > 1) fclose(yyin);
    return 0;
}