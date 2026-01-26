%{
/* 
 * PRACTICA 1 - FLEX Segunda Convocatoria 
 * Autor: Karima Drafli Rico
 * Analizador léxico para procesar archivos CSS y generar estadísticas, en mi código añado:
 * - Bloques @media
 * - Propiedades y selectores
 * - Especificaciones de color (HEX, rgb, rgba, nombres)
 * - Unidades de medida
 * - Propiedades !important
 */

#include <stdio.h>
#include <ctype.h>

/* ------------------------- CONTADORES GLOBALES ------------------------- */
/* Estadísticas acumuladas durante todo el procesamiento */
int mediaBlocks = 0;          /* Contador de bloques @media encontrados */
int totalProperties = 0;      /* Total de propiedades en todo el documento */
int importantCount = 0;      /* Propiedades declaradas con !important */
int measureCount = 0;         /* Valores con unidades de medida (px, em, etc.) */
int colorCount = 0;          /* Total de especificaciones de color encontradas */

/* ------------------------- CONTADORES POR REGLA ------------------------- */
/* Variables que se reinician al comenzar cada regla CSS */
int colorsInCurrentRule = 0;      /* Colores encontrados en la regla actual */
int maxColorsInRule = 0;           /* Máximo de colores en una sola regla */
int propertiesInCurrentRule = 0;  /* Propiedades en la regla actual */
int maxPropertiesInRule = 0;       /* Máximo de propiedades en una regla */

/* ------------------------- GESTIÓN DE SELECTORES ------------------------- */
/* Almacena el selector completo usando buffers estáticos (sin memoria dinámica) */
#define MAX_SELECTOR_LEN 2048
char currentSelector[MAX_SELECTOR_LEN] = "";  /* Selector de la regla actual */
char maxSelectorStr[MAX_SELECTOR_LEN] = "";    /* Selector de la regla con más propiedades */

/* ------------------------- GESTIÓN DE COMENTARIOS ------------------------- */
/* Guarda el estado anterior al entrar en un comentario para poder volver */
int prevState = 0;

/* ------------------------- GESTIÓN DE BLOQUES @MEDIA ------------------------- */
/* Controla si estamos dentro de un bloque @media y su anidamiento */
int insideMedia = 0;    /* Flag: 1 si estamos dentro de @media, 0 si no */
int mediaDepth = 0;     /* Profundidad de anidamiento de bloques @media */

/* 
 * Función que imprime todas las estadísticas calculadas
 * Se llama al finalizar el procesamiento del archivo
 */
/* Función auxiliar para copiar selector sin usar funciones de string que no podemos usar */
void copy_selector(char *dest, const char *src) {
    int i = 0;
    while (src[i] != '\0' && i < MAX_SELECTOR_LEN - 1) {
        dest[i] = src[i];
        i++;
    }
    dest[i] = '\0';
}

void print_stats() {
    printf("1. Número de bloques @media: %d\n", mediaBlocks);
    printf("2. Número total de propiedades: %d\n", totalProperties);
    printf("3. Selector con más propiedades: %s (%d)\n", maxSelectorStr[0] ? maxSelectorStr : "", maxPropertiesInRule);
    printf("4. Número de propiedades !important: %d\n", importantCount);
    printf("5. Número de valores con unidades de medida: %d\n", measureCount);
    printf("6. Número de especificaciones de color: %d\n", colorCount);
    printf("7. Máximo número de colores en una regla: %d\n", maxColorsInRule);
}
%}

%option noyywrap

%x COMMENT
%x MEDIA_HDR
%x SELECTOR
%x SELECTOR_DQ
%x SELECTOR_SQ
%x BLOCK
%x VALUE
%x DQSTR
%x SQSTR

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

<INITIAL,MEDIA_HDR,SELECTOR,BLOCK,VALUE>"/*"  { 
    prevState = YY_START;
    BEGIN(COMMENT);
}
<COMMENT>"*/"       { BEGIN(prevState); }
<COMMENT>.|\n       { }

<INITIAL>{WS}+      { }
<INITIAL>"@media"   { 
    mediaBlocks++;
    BEGIN(MEDIA_HDR);
}

<MEDIA_HDR>"{"      { 
    insideMedia = 1;
    mediaDepth = 1;
    BEGIN(INITIAL);
}
<MEDIA_HDR>.|\n     { }

<INITIAL>{SEL}      { 
    yymore();
    BEGIN(SELECTOR);
}

<SELECTOR>"{"       {
    yyless(yyleng-1);
    copy_selector(currentSelector, yytext);
    colorsInCurrentRule = 0;
    propertiesInCurrentRule = 0;
    if (insideMedia) mediaDepth++;
    BEGIN(BLOCK);
}

<SELECTOR>{WS}+     { yymore(); }
<SELECTOR>{SEL}     { yymore(); }
<SELECTOR>"\""      { 
    yymore(); 
    BEGIN(SELECTOR_DQ);
}
<SELECTOR>"'"       { 
    yymore(); 
    BEGIN(SELECTOR_SQ);
}
<SELECTOR>.         { yymore(); }

<SELECTOR_DQ>([^"\\\n]+|\\.)* { yymore(); }
<SELECTOR_DQ>"\""             { 
    yymore(); 
    BEGIN(SELECTOR);
}

<SELECTOR_SQ>([^'\\\n]+|\\.)* { yymore(); }
<SELECTOR_SQ>"'"               { 
    yymore(); 
    BEGIN(SELECTOR);
}

<INITIAL>"{"        {
    currentSelector[0] = '\0';
    colorsInCurrentRule = 0;
    propertiesInCurrentRule = 0;
    BEGIN(BLOCK);
}

<INITIAL>"}"        {
    if (insideMedia) {
        mediaDepth--;
        if (mediaDepth <= 0) { 
            insideMedia = 0;
            mediaDepth = 0; 
        }
    }
}
<INITIAL>.          { }

<BLOCK>{WS}+        { }
<BLOCK>"}"          {
    if (colorsInCurrentRule > maxColorsInRule) 
        maxColorsInRule = colorsInCurrentRule;
    if (propertiesInCurrentRule > maxPropertiesInRule) {
        maxPropertiesInRule = propertiesInCurrentRule;
        copy_selector(maxSelectorStr, currentSelector);
    }
    if (insideMedia) {
        mediaDepth--;
        if (mediaDepth <= 0) { 
            insideMedia = 0;
            mediaDepth = 0; 
        }
    }
    BEGIN(INITIAL);
}

<BLOCK>{IDENT}{WS}*":" { 
    totalProperties++;
    propertiesInCurrentRule++;
    BEGIN(VALUE);
}
<BLOCK>.            { }

<VALUE>{WS}+        { }

<VALUE>"\""         { BEGIN(DQSTR); }
<DQSTR>([^"\\\n]+|\\.)* { }
<DQSTR>"\""         { BEGIN(VALUE); }

<VALUE>"'"          { BEGIN(SQSTR); }
<SQSTR>([^'\\\n]+|\\.)* { }
<SQSTR>"'"          { BEGIN(VALUE); }

<VALUE>"!"({WS}*)"important" { 
    importantCount++;
}

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

/* ------------------------- FUNCIÓN PRINCIPAL ------------------------- */
/*
 * Punto de entrada del programa.
 * - Si se proporciona un archivo como argumento, lo abre para lectura
 * - Si no, lee de la entrada estándar (stdin)
 * - Ejecuta el analizador léxico y muestra las estadísticas
 */
int main(int argc, char **argv) {
    /* Abrir archivo si se proporciona como argumento */
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "Error al abrir archivo %s\n", argv[1]);
            return 1;
        }
    }
    
    /* Ejecutar el analizador léxico sobre el archivo */
    yylex();
    
    /* Mostrar todas las estadísticas calculadas */
    print_stats();
    
    /* Cerrar archivo si se abrió uno */
    if (argc > 1 && yyin) fclose(yyin);
    
    return 0;
}
