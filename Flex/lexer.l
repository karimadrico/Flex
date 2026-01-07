%{
/*
 * PRÁCTICA 1 - FLEX (Segunda Convocatoria) Karima Drafli Rico
 */

#include <stdio.h>
#include <ctype.h>

static int mediaBlocks = 0;
static int totalProperties = 0;
static int importantCount = 0;
static int measureCount = 0;
static int colorCount = 0;

/* colores por regla */
static int colorsInCurrentRule = 0;
static int maxColorsInRule = 0;

/* propiedades por regla */
static int propertiesInCurrentRule = 0;
static int maxPropertiesInRule = 0;

/* reglas dentro / fuera de media */
static int insideMedia = 0;
static int rulesInsideMedia = 0;
static int rulesOutsideMedia = 0;

%}

%option noyywrap

%x COMMENT
%x BLOCK
%x VALUE
%x DQSTR
%x SQSTR

WS              [ \t\r\n]+
UNIT            (pt|mm|cm|pc|in|px|em|ex)
IDENT           [a-zA-Z_-][a-zA-Z0-9_-]*

HEX3            #[0-9A-Fa-f]{3}
HEX6            #[0-9A-Fa-f]{6}
HEX8            #[0-9A-Fa-f]{8}

COLORNAME       (black|gray|grey|silver|white|maroon|red|purple|fuchsia|green|lime|olive|yellow|navy|blue|teal|aqua|orange)

%%

/* Comentarios */
"/*"                    { BEGIN(COMMENT); }
<COMMENT>"*/"           { BEGIN(INITIAL); }
<COMMENT>.|\n           { }

/* Media queries */
<INITIAL>"@media"       { mediaBlocks++; insideMedia = 1; }

/* Inicial y bloques */
<INITIAL>{WS}+           { }
<INITIAL>"{"            { colorsInCurrentRule = 0; propertiesInCurrentRule = 0; BEGIN(BLOCK); }
<INITIAL>.              { }

<BLOCK>{WS}+             { }
<BLOCK>"/*"              { BEGIN(COMMENT); }

/* Propiedad dentro de bloque */
<BLOCK>{IDENT}{WS}*":"   { totalProperties++; propertiesInCurrentRule++; BEGIN(VALUE); }

/* Fin de bloque */
<BLOCK>"}"              {
    if (colorsInCurrentRule > maxColorsInRule) maxColorsInRule = colorsInCurrentRule;
    if (propertiesInCurrentRule > maxPropertiesInRule) maxPropertiesInRule = propertiesInCurrentRule;
    if (insideMedia) rulesInsideMedia++; else rulesOutsideMedia++;
    insideMedia = 0;
    BEGIN(INITIAL);
}

<BLOCK>.                { }

/* VALUE */
<VALUE>{WS}+            { }
<VALUE>"/*"             { BEGIN(COMMENT); }

/* Cadenas dobles */
<VALUE>"\""             { BEGIN(DQSTR); }
<DQSTR>[^"]+            { }
<DQSTR>"\""             { BEGIN(VALUE); }

/* Cadenas simples */
<VALUE>"\'"             { BEGIN(SQSTR); }
<SQSTR>[^']+            { }
<SQSTR>"\'"             { BEGIN(VALUE); }

/* Propiedades !important */
<VALUE>"!"{WS}*"important"  { importantCount++; }

/* Valores con unidades */
<VALUE>[0-9]+\.?[0-9]*{UNIT}  { measureCount++; }

/* Colores HEX */
<VALUE>{HEX8}           { colorCount++; colorsInCurrentRule++; }
<VALUE>{HEX6}           { colorCount++; colorsInCurrentRule++; }
<VALUE>{HEX3}           { colorCount++; colorsInCurrentRule++; }

/* Colores rgb / rgba */
<VALUE>rgb(a)?\([^)]*\)   { colorCount++; colorsInCurrentRule++; }

/* Nombres de color */
<VALUE>{COLORNAME}       { colorCount++; colorsInCurrentRule++; }

/* Fin de propiedad */
<VALUE>";"              { BEGIN(BLOCK); }

/* Regla genérica */
<VALUE>.                 { }

%%

int main(int argc, char **argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) return 1;
    }
    yylex();
    printf("1. Número de bloques @media: %d\n", mediaBlocks);
    printf("2. Número total de propiedades: %d\n", totalProperties);
    printf("3. Máximo número de propiedades en una regla: %d\n", maxPropertiesInRule);
    printf("4. Número de propiedades !important: %d\n", importantCount);
    printf("5. Número de valores con unidades de medida: %d\n", measureCount);
    printf("6. Número de especificaciones de color: %d\n", colorCount);
    printf("7. Máximo número de colores en una regla: %d\n", maxColorsInRule);
    printf("8. Reglas dentro de @media: %d\n", rulesInsideMedia);
    printf("9. Reglas fuera de @media: %d\n", rulesOutsideMedia);
    if (argc > 1) fclose(yyin);
    return 0;
}

