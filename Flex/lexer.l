%{
/* PRACTICA 1 - FLEX (Segunda Convocatoria Karima Drafli Rico) */

#include <stdio.h>
#include <ctype.h>
#include <string.h>

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
char maxSelector[512] = "";
char currentSelector[512] = "";
int selectorLen = 0;

/* prevState para comentarios */
int prevState = 0;

/* Aux para comentarios/valores */
int seenSemicolon = 0;

/* Reglas dentro/fuera de media */
int insideMedia = 0;
int mediaDepth = 0;
int rulesInsideMedia = 0;
int rulesOutsideMedia = 0;
%}

%option noyywrap

/* Estados exclusivos */
%x COMMENT
%x SELECTOR
%x BLOCK
%x VALUE
%x DQSTR
%x SQSTR

/* Patrones básicos - AQUÍ ANTES DEL %% */
WS      [ \t\r\n]+
UNIT    (pt|mm|cm|pc|in|px|em|ex)
IDENT   [a-zA-Z_-][a-zA-Z0-9_-]*
SEL     [a-zA-Z0-9_.#:\[\]()="'* >+~-]+

HEX3    \#[0-9A-Fa-f]{3}
HEX6    \#[0-9A-Fa-f]{6}
HEX8    \#[0-9A-Fa-f]{8}

%%

"/*"                { prevState = YY_START; BEGIN(COMMENT); }
<COMMENT>"*/"       { 
                                                BEGIN(prevState);
                                                if (prevState == VALUE && seenSemicolon) {
                                                        seenSemicolon = 0;
                                                        BEGIN(BLOCK);
                                                }
                                            }
<COMMENT>.|\n       { }

<INITIAL>{WS}+      { }
<INITIAL>[^\x20-\x7E]+    { /* ignorar bytes de control/no imprimibles */ }
<INITIAL>"@media"   { mediaBlocks++; insideMedia = 1; }

<INITIAL>{SEL}      {
    selectorLen = 0;
    if (yyleng < sizeof(currentSelector)) {
        memcpy(currentSelector, yytext, yyleng);
        selectorLen = yyleng;
    }
    BEGIN(SELECTOR);
}

<SELECTOR>{WS}+     {
    if (selectorLen < sizeof(currentSelector) - 1) {
        currentSelector[selectorLen++] = ' ';
    }
}
<SELECTOR>[^\x20-\x7E]+ { /* ignorar bytes no imprimibles en selector */ }

<SELECTOR>{SEL}     {
    if (selectorLen + yyleng < sizeof(currentSelector)) {
        memcpy(currentSelector + selectorLen, yytext, yyleng);
        selectorLen += yyleng;
    }
}

<SELECTOR>.        { /* consumir cualquier carácter suelto en SELECTOR */ }

<SELECTOR>"{"       {
    currentSelector[selectorLen] = '\0';
    colorsInCurrentRule = 0;
    propertiesInCurrentRule = 0;
    BEGIN(BLOCK);
}

<SELECTOR>"/*"      { prevState = YY_START; BEGIN(COMMENT); }

<INITIAL>"{"       { 
    currentSelector[0] = '\0';
    selectorLen = 0;
    colorsInCurrentRule=0; 
    propertiesInCurrentRule=0; 
    BEGIN(BLOCK); 
}
<INITIAL>.          { }

<BLOCK>{WS}+    { }
<BLOCK>"/*"     { prevState = YY_START; BEGIN(COMMENT); }

<BLOCK>[^\x20-\x7E]+    { /* ignorar bytes de control en bloque */ }

<BLOCK>"{"         {
    colorsInCurrentRule=0; 
    propertiesInCurrentRule=0;
}
<BLOCK>"}"      {
                    if(colorsInCurrentRule > maxColorsInRule) maxColorsInRule = colorsInCurrentRule;
                    if(propertiesInCurrentRule > maxPropertiesInRule) maxPropertiesInRule = propertiesInCurrentRule;
                    if(propertiesInCurrentRule > 0) {
                        if(insideMedia) rulesInsideMedia++; else rulesOutsideMedia++;
                    }
                    insideMedia = 0;
                    BEGIN(INITIAL);
                 }
<BLOCK>{IDENT}{WS}*":" { totalProperties++; propertiesInCurrentRule++; BEGIN(VALUE); }
<BLOCK>.        { }

<VALUE>{WS}+    { }
<VALUE>"/*"     { prevState = YY_START; BEGIN(COMMENT); }

<VALUE>[^\x20-\x7E]+    { /* ignorar bytes de control en value */ }

<VALUE>"\""     { BEGIN(DQSTR); }
<DQSTR>([^"\\\n]+|\\.)* { }
<DQSTR>"\""     { BEGIN(VALUE); }

<VALUE>"\'"     { BEGIN(SQSTR); }
<SQSTR>([^'\\\n]+|\\.)* { }
<SQSTR>"\'"     { BEGIN(VALUE); }

<VALUE>"!"{WS}*"important" { importantCount++; }
<VALUE>[0-9]+\.?[0-9]*{UNIT} { measureCount++; }

<VALUE>{HEX8} { colorCount++; colorsInCurrentRule++; }
<VALUE>{HEX6} { colorCount++; colorsInCurrentRule++; }
<VALUE>{HEX3} { colorCount++; colorsInCurrentRule++; }

<VALUE>rgba?\( { colorCount++; colorsInCurrentRule++; }

<VALUE>black/[ \t\r\n;,)\}]    { colorCount++; colorsInCurrentRule++; }
<VALUE>gray/[ \t\r\n;,)\}]     { colorCount++; colorsInCurrentRule++; }
<VALUE>grey/[ \t\r\n;,)\}]     { colorCount++; colorsInCurrentRule++; }
<VALUE>silver/[ \t\r\n;,)\}]   { colorCount++; colorsInCurrentRule++; }
<VALUE>white/[ \t\r\n;,)\}]    { colorCount++; colorsInCurrentRule++; }
<VALUE>maroon/[ \t\r\n;,)\}]   { colorCount++; colorsInCurrentRule++; }
<VALUE>red/[ \t\r\n;,)\}]      { colorCount++; colorsInCurrentRule++; }
<VALUE>purple/[ \t\r\n;,)\}]   { colorCount++; colorsInCurrentRule++; }
<VALUE>fuchsia/[ \t\r\n;,)\}]  { colorCount++; colorsInCurrentRule++; }
<VALUE>green/[ \t\r\n;,)\}]    { colorCount++; colorsInCurrentRule++; }
<VALUE>lime/[ \t\r\n;,)\}]     { colorCount++; colorsInCurrentRule++; }
<VALUE>olive/[ \t\r\n;,)\}]    { colorCount++; colorsInCurrentRule++; }
<VALUE>yellow/[ \t\r\n;,)\}]   { colorCount++; colorsInCurrentRule++; }
<VALUE>navy/[ \t\r\n;,)\}]     { colorCount++; colorsInCurrentRule++; }
<VALUE>blue/[ \t\r\n;,)\}]     { colorCount++; colorsInCurrentRule++; }
<VALUE>teal/[ \t\r\n;,)\}]     { colorCount++; colorsInCurrentRule++; }
<VALUE>aqua/[ \t\r\n;,)\}]     { colorCount++; colorsInCurrentRule++; }
<VALUE>orange/[ \t\r\n;,)\}]   { colorCount++; colorsInCurrentRule++; }

<VALUE>";"   { seenSemicolon = 1; BEGIN(BLOCK); }
<VALUE>.      { }

%%

int main(int argc, char **argv) {
    if(argc>1) yyin=fopen(argv[1],"r");
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
    return 0;
}
