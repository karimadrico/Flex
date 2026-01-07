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

IDENT           [a-zA-Z_-][a-zA-Z0-9_-]*

HEX3            #[0-9A-Fa-f]{3}
HEX6            #[0-9A-Fa-f]{6}
HEX8            #[0-9A-Fa-f]{8}

COLORNAME       (black|gray|grey|silver|white|maroon|red|purple|fuchsia|green|lime|olive|yellow|navy|blue|teal|aqua|orange)

%%

/*     COMENTARIOS */
"/*"                    { BEGIN(COMMENT); }
<COMMENT>"*/"           { BEGIN(INITIAL); }
<COMMENT>.|\n           { }

/*      @media BLOQUES */
<INITIAL>"@media"       { mediaBlocks++; }

/*         INICIAL */
<INITIAL>{WS}           { }

<INITIAL>"{"            { 
    BEGIN(BLOCK); 
}

<INITIAL>.              { }

/*       BLOQUE CSS */
<BLOCK>{WS}             { }

/* cierre de bloque */
<BLOCK>"}"              { 
    BEGIN(INITIAL); 
}

/* comentario dentro de bloque */
<BLOCK>"/*"             { BEGIN(COMMENT); }

/* PROPIEDADES 
   permite espacios al inicio e indentación */
<BLOCK>{WS}*{IDENT}{WS}*":"  { 
    totalProperties++;
    BEGIN(VALUE);
}

/* catch-all — SIEMPRE EL ÚLTIMO */
<BLOCK>.                { }

/*     VALORES */
<VALUE>{WS}             { }

/* cadenas dobles */
<VALUE>"\""             { BEGIN(DQSTR); }
<DQSTR>"\\\\"           { }
<DQSTR>"\\\""           { }
<DQSTR>"\""             { BEGIN(VALUE); }
<DQSTR>.|\n             { }

/* cadenas simples */
<VALUE>"\'"             { BEGIN(SQSTR); }
<SQSTR>"\\\\"           { }
<SQSTR>"\\\'"           { }
<SQSTR>"\'"             { BEGIN(VALUE); }
<SQSTR>.|\n             { }

/* !important */
<VALUE>"!"{WS}*"important"  { importantCount++; }

/* unidades */
<VALUE>[0-9]+\.?[0-9]*{UNIT}  { measureCount++; }

/* colores HEX */
<VALUE>{HEX8}           { colorCount++; }
<VALUE>{HEX6}           { colorCount++; }
<VALUE>{HEX3}           { colorCount++; }

/* rgb/rgba */
<VALUE>rgba?\([^)]*\)   { colorCount++; }

/* color por nombre */
<VALUE>{COLORNAME}({NONWORD}|$) {
    colorCount++;
}

/* fin de valor */
<VALUE>";"              { 
    BEGIN(BLOCK); 
}

/* comentarios dentro de valores */
<VALUE>"/*"             { BEGIN(COMMENT); }

/* resto del valor */
<VALUE>.                { }

%%

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
