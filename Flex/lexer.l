%{
/* PRACTICA 1 - FLEX (Segunda Convocatoria Karima Drafli Rico) */

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>

/* Contadores globales */
int mediaBlocks = 0;
int totalProperties = 0;
int importantCount = 0;
int measureCount = 0;
int colorCount = 0;

/* Colores y propiedades por regla */
int colorsInCurrentRule = 0;
int maxColorsInRule = 0;
int propertiesInCurrentRule = 0;
int maxPropertiesInRule = 0;

/* Selector con más propiedades */
char *maxSelectorStr = NULL;
char *currentSelector = NULL;

/* prevState para comentarios */
int prevState = 0;

/* Reglas dentro/fuera de media */
int insideMedia = 0;
int mediaDepth = 0;

void print_stats() {
    printf("1. Número de bloques @media: %d\n", mediaBlocks);
    printf("2. Número total de propiedades: %d\n", totalProperties);
    printf("3. Selector con más propiedades: %s (%d)\n", maxSelectorStr ? maxSelectorStr : "", maxPropertiesInRule);
    printf("4. Número de propiedades !important: %d\n", importantCount);
    printf("5. Número de valores con unidades de medida: %d\n", measureCount);
    printf("6. Número de especificaciones de color: %d\n", colorCount);
    printf("7. Máximo número de colores en una regla: %d\n", maxColorsInRule);
}
%}

%option noyywrap

/* Estados exclusivos */
%x COMMENT
%x MEDIA_HDR
%x SELECTOR
%x SELECTOR_DQ
%x SELECTOR_SQ
%x BLOCK
%x VALUE
%x DQSTR
%x SQSTR

/* Patrones básicos */
WS      [ \t\r\n]+
UNIT    (pt|mm|cm|pc|in|px|em|ex)
IDENT   [a-zA-Z_-][a-zA-Z0-9_-]*
SEL     [a-zA-Z0-9_.#:\[\]()=*,>+~\-\^\$\|\\,]+

NONWORD [^A-Za-z0-9_-]
NONHEX  [^0-9A-Fa-f]
COLORNAME (black|gray|silver|white|maroon|red|purple|fuchsia|green|lime|olive|yellow|navy|blue|teal|aqua|orange)

HEX3    \#[0-9A-Fa-f]{3}
HEX6    \#[0-9A-Fa-f]{6}
HEX8    \#[0-9A-Fa-f]{8}

%%

<INITIAL,MEDIA_HDR,SELECTOR,BLOCK,VALUE>"/*"  { prevState = YY_START; BEGIN(COMMENT); }
<COMMENT>"*/"       { BEGIN(prevState); }
<COMMENT>.|\n       { }

<INITIAL>{WS}+      { }
<INITIAL>"@media"   { mediaBlocks++; BEGIN(MEDIA_HDR); }
<MEDIA_HDR>"{"      { insideMedia = 1; mediaDepth = 1; BEGIN(INITIAL); }
<MEDIA_HDR>.|\n     { }

<INITIAL>{SEL}      { yymore(); BEGIN(SELECTOR); }

<SELECTOR>"{"       {
    yyless(yyleng-1);
    if (currentSelector) free(currentSelector);
    currentSelector = strdup(yytext);
    colorsInCurrentRule = 0;
    propertiesInCurrentRule = 0;
    if (insideMedia) mediaDepth++;
    BEGIN(BLOCK);
}

<SELECTOR>{WS}+     { yymore(); }
<SELECTOR>{SEL}     { yymore(); }
<SELECTOR>"\""      { yymore(); BEGIN(SELECTOR_DQ); }
<SELECTOR>"'"       { yymore(); BEGIN(SELECTOR_SQ); }
<SELECTOR>.         { yymore(); }

<SELECTOR_DQ>([^"\\\n]+|\\.)* { yymore(); }
<SELECTOR_DQ>"\""             { yymore(); BEGIN(SELECTOR); }

<SELECTOR_SQ>([^'\\\n]+|\\.)* { yymore(); }
<SELECTOR_SQ>"'"               { yymore(); BEGIN(SELECTOR); }

<INITIAL>"{"        {
    if (currentSelector) free(currentSelector);
    currentSelector = NULL;
    colorsInCurrentRule = 0;
    propertiesInCurrentRule = 0;
    BEGIN(BLOCK);
}
<INITIAL>"}"        {
    if (insideMedia) {
        mediaDepth--;
        if (mediaDepth <= 0) { insideMedia = 0; mediaDepth = 0; }
    }
}
<INITIAL>.          { }

<BLOCK>{WS}+        { }
<BLOCK>"}"          {
    if (colorsInCurrentRule > maxColorsInRule) 
        maxColorsInRule = colorsInCurrentRule;
    if (propertiesInCurrentRule > maxPropertiesInRule) {
        maxPropertiesInRule = propertiesInCurrentRule;
        if (maxSelectorStr) free(maxSelectorStr);
        maxSelectorStr = currentSelector ? strdup(currentSelector) : NULL;
    }
    if (insideMedia) {
        mediaDepth--;
        if (mediaDepth <= 0) { insideMedia = 0; mediaDepth = 0; }
    }
    BEGIN(INITIAL);
}
<BLOCK>{IDENT}{WS}*":" { totalProperties++; propertiesInCurrentRule++; BEGIN(VALUE); }
<BLOCK>.            { }

<VALUE>{WS}+        { }

<VALUE>"\""         { BEGIN(DQSTR); }
<DQSTR>([^"\\\n]+|\\.)* { }
<DQSTR>"\""         { BEGIN(VALUE); }

<VALUE>"'"          { BEGIN(SQSTR); }
<SQSTR>([^'\\\n]+|\\.)* { }
<SQSTR>"'"          { BEGIN(VALUE); }

<VALUE>"!"({WS}*)"important" { importantCount++; }

<VALUE>([0-9]+(\.[0-9]+)?|\.[0-9]+){UNIT}[ \t\r\n;,\)!] {
    yyless(yyleng-1);
    measureCount++;
}

<VALUE>({HEX8}|{HEX6}|{HEX3})[ \t\r\n;,\)!] {
    yyless(yyleng-1);
    colorCount++;
    colorsInCurrentRule++;
}

<VALUE>rgb\({WS}*([0-9]+|[0-9]+%){WS}*,{WS}*([0-9]+|[0-9]+%){WS}*,{WS}*([0-9]+|[0-9]+%){WS}*\)[ \t\r\n;,\)!] {
    yyless(yyleng-1);
    colorCount++;
    colorsInCurrentRule++;
}

<VALUE>rgba\({WS}*([0-9]+|[0-9]+%){WS}*,{WS}*([0-9]+|[0-9]+%){WS}*,{WS}*([0-9]+|[0-9]+%){WS}*,{WS}*([0-9]+(\.[0-9]+)?|\.[0-9]+){WS}*\)[ \t\r\n;,\)!] {
    yyless(yyleng-1);
    colorCount++;
    colorsInCurrentRule++;
}

<VALUE>({COLORNAME})[ \t\r\n;,\)!] {
    yyless(yyleng-1);
    colorCount++;
    colorsInCurrentRule++;
}

<VALUE>";"          { BEGIN(BLOCK); }
<VALUE>.            { }

%%

int main(int argc, char **argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "Error al abrir archivo %s\n", argv[1]);
            return 1;
        }
    }
    yylex();
    print_stats();
    if (currentSelector) free(currentSelector);
    if (maxSelectorStr) free(maxSelectorStr);
    if (argc > 1 && yyin) fclose(yyin);
    return 0;
}
