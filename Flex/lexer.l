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
int rulesInsideMedia = 0;
int rulesOutsideMedia = 0;
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
SEL     [a-zA-Z0-9_.#:\[\]()="'*,>+~\-\^\$\|\\]+

NONWORD [^A-Za-z0-9_-]
COLORNAME (black|gray|silver|white|maroon|red|purple|fuchsia|green|lime|olive|yellow|navy|blue|teal|aqua|orange)

HEX3    \#[0-9A-Fa-f]{3}
HEX6    \#[0-9A-Fa-f]{6}
HEX8    \#[0-9A-Fa-f]{8}

%%

<INITIAL,MEDIA_HDR,SELECTOR,BLOCK,VALUE>"/*"  { prevState = YY_START; BEGIN(COMMENT); }
<COMMENT>"*/"       { 
                                                BEGIN(prevState);
                                            }
<COMMENT>.|\n       { }

<INITIAL>{WS}+      { }
<INITIAL>"@media"   { mediaBlocks++; BEGIN(MEDIA_HDR); }
<MEDIA_HDR>"{"      { insideMedia = 1; mediaDepth = 1; BEGIN(INITIAL); }
<MEDIA_HDR>.|\n      { }

<INITIAL>{SEL}      { yymore(); BEGIN(SELECTOR); }

<SELECTOR>"{"     {
                    /* quitar '{' del lexema actual */
                    yyless(yyleng-1);
                    if (currentSelector) { free(currentSelector); currentSelector = NULL; }
                    currentSelector = strdup(yytext);
                    colorsInCurrentRule = 0;
                    propertiesInCurrentRule = 0;
                    if (insideMedia) mediaDepth++;
                    BEGIN(BLOCK);
                }

<SELECTOR>{WS}+     { /* ignorar espacios en selector para evitar trims */ }
<SELECTOR>{SEL}     { yymore(); }
<SELECTOR>"\""    { yymore(); BEGIN(SELECTOR_DQ); }
<SELECTOR>"'"      { yymore(); BEGIN(SELECTOR_SQ); }
<SELECTOR>.         { yymore(); }

<SELECTOR_DQ>([^"\\\n]+|\\.)* { yymore(); }
<SELECTOR_DQ>"\""             { yymore(); BEGIN(SELECTOR); }

<SELECTOR_SQ>([^'\\\n]+|\\.)* { yymore(); }
<SELECTOR_SQ>"'"               { yymore(); BEGIN(SELECTOR); }

<INITIAL>"{"       { 
    /* inicio de bloque: selector ya gestionado por yymore/yyless */
    colorsInCurrentRule=0; 
    propertiesInCurrentRule=0; 
    BEGIN(BLOCK); 
}
<INITIAL>"}"       {
    if (insideMedia) {
        mediaDepth--;
        if (mediaDepth <= 0) { insideMedia = 0; mediaDepth = 0; }
    }
}
<INITIAL>.          { }

<BLOCK>{WS}+    { }
<BLOCK>"}"      {
                    if(colorsInCurrentRule > maxColorsInRule) maxColorsInRule = colorsInCurrentRule;
                    if(propertiesInCurrentRule > maxPropertiesInRule) {
                        maxPropertiesInRule = propertiesInCurrentRule;
                        if (maxSelectorStr) { free(maxSelectorStr); maxSelectorStr = NULL; }
                        if (currentSelector) maxSelectorStr = strdup(currentSelector);
                    }
                    if(propertiesInCurrentRule > 0) {
                        if(insideMedia) rulesInsideMedia++; else rulesOutsideMedia++;
                    }
                    if (insideMedia) {
                        mediaDepth--;
                        if (mediaDepth <= 0) { insideMedia = 0; mediaDepth = 0; }
                    }
                    BEGIN(INITIAL);
                 }
<BLOCK>{IDENT}{WS}*":" { totalProperties++; propertiesInCurrentRule++; BEGIN(VALUE); }
<BLOCK>.        { }

<VALUE>{WS}+    { }


<VALUE>"\""     { BEGIN(DQSTR); }
<DQSTR>([^"\\\n]+|\\.)* { }
<DQSTR>"\""     { BEGIN(VALUE); }

<VALUE>"\'"     { BEGIN(SQSTR); }
<SQSTR>([^'\\\n]+|\\.)* { }
<SQSTR>"\'"     { BEGIN(VALUE); }

<VALUE>"!"{WS}*"important" { importantCount++; }
<VALUE>([0-9]+(\.[0-9]+)?|\.[0-9]+){UNIT} { measureCount++; }

<VALUE>{HEX8} { colorCount++; colorsInCurrentRule++; }
<VALUE>{HEX6} { colorCount++; colorsInCurrentRule++; }
<VALUE>{HEX3} { colorCount++; colorsInCurrentRule++; }

<VALUE>rgba?\( { colorCount++; colorsInCurrentRule++; }

<VALUE>{COLORNAME}({NONWORD}|$) {
    if (yyleng > 0) {
        unsigned char c = (unsigned char)yytext[yyleng-1];
        if (!isalnum(c) && c != '_' && c != '-') yyless(yyleng-1);
    }
    colorCount++; colorsInCurrentRule++;
}

<VALUE>";"   { BEGIN(BLOCK); }
<VALUE>.      { }

%%

int main(int argc, char **argv) {
    if(argc>1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "Error al abrir archivo %s\n", argv[1]);
            return 1;
        }
    }
    yylex();
    printf("1. Número de bloques @media: %d\n", mediaBlocks);
    printf("2. Número total de propiedades: %d\n", totalProperties);
    if (maxSelectorStr) printf("3. Selector con más propiedades: %s (%d)\n", maxSelectorStr, maxPropertiesInRule);
    else printf("3. Máximo número de propiedades en una regla: %d\n", maxPropertiesInRule);
    printf("4. Número de propiedades !important: %d\n", importantCount);
    printf("5. Número de valores con unidades de medida: %d\n", measureCount);
    printf("6. Número de especificaciones de color: %d\n", colorCount);
    printf("7. Máximo número de colores en una regla: %d\n", maxColorsInRule);
    printf("8. Reglas dentro de @media: %d\n", rulesInsideMedia);
    printf("9. Reglas fuera de @media: %d\n", rulesOutsideMedia);

    if (currentSelector) { free(currentSelector); currentSelector = NULL; }
    if (maxSelectorStr) { free(maxSelectorStr); maxSelectorStr = NULL; }
    if (argc>1 && yyin) fclose(yyin);
    return 0;
}
