%{
/*
 * PRÁCTICA 1 - FLEX (Segunda Convocatoria) Karima Drafli Rico
 */

#include <stdio.h>
#include <ctype.h>

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
NONWORD         [^A-Za-z0-9_-]

HEX3            #[0-9A-Fa-f]{3}
HEX6            #[0-9A-Fa-f]{6}
HEX8            #[0-9A-Fa-f]{8}

COLORNAME       (black|gray|grey|silver|white|maroon|red|purple|fuchsia|green|lime|olive|yellow|navy|blue|teal|aqua|orange)

%%

    /* Comentarios CSS */
"/*"                    { BEGIN(COMMENT); }
<COMMENT>"*/"           { BEGIN(INITIAL); }
<COMMENT>.|\n           { }

    /* Detectar bloques @media */
<INITIAL>"@media"       { mediaBlocks++; }

    /* Ignorar espacios en estado inicial */
<INITIAL>{WS}           { }

    /* Detectar inicio de bloque */
<INITIAL>"{"            { BEGIN(BLOCK); }

    /* Ignorar otros caracteres */
<INITIAL>.              { }

    /* Dentro de bloque: orden específico a genérico */
<BLOCK>{WS}             { }

<BLOCK>"}"              { BEGIN(INITIAL); }

<BLOCK>"/*"             { BEGIN(COMMENT); }

    /* Detectar propiedad */
<BLOCK>[a-zA-Z-]+{WS}*":"  { 
    totalProperties++;
    BEGIN(VALUE);
}

    /* Catch-all necesario */
<BLOCK>.                { }

    /* Analizar valores de propiedades */
<VALUE>{WS}             { }

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

    /* Declaración !important */
<VALUE>"!"{WS}*"important"  { importantCount++; }

    /* Unidades de medida */
<VALUE>[0-9]+\.?[0-9]*{UNIT}  { measureCount++; }

    /* Colores hexadecimales */
<VALUE>{HEX8}           { colorCount++; }
<VALUE>{HEX6}           { colorCount++; }
<VALUE>{HEX3}           { colorCount++; }

    /* Funciones RGB y RGBA */
<VALUE>rgba?\([^)]*\)   { colorCount++; }

    /* Nombres de color con lookhead */
<VALUE>{COLORNAME}({NONWORD}|$) {
    if (yyleng > 0) {
        unsigned char c = (unsigned char)yytext[yyleng-1];
        if (isalnum(c) || c == '_' || c == '-') {
            yyless(yyleng - 1);
        }
    }
    colorCount++;
}

    /* Fin de valor: ANTES del catch-all */
<VALUE>";"              { BEGIN(BLOCK); }

    /* Comentarios dentro de valores */
<VALUE>"/*"             { BEGIN(COMMENT); }

    /* Catch-all para VALUE */
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
    
    printf("1. Número de bloques @media: %d\n", mediaBlocks);
    printf("2. Número total de propiedades: %d\n", totalProperties);
    printf("4. Número de propiedades !important: %d\n", importantCount);
    printf("5. Número de valores con unidades de medida: %d\n", measureCount);
    printf("6. Número de especificaciones de color: %d\n", colorCount);
    
    if (argc > 1) fclose(yyin);
    return 0;
}
