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
#include <string.h>
#include <stdlib.h>

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
/* Almacena el selector completo para identificar la regla con más propiedades */
char *maxSelectorStr = NULL;   /* Selector de la regla con más propiedades */
char *currentSelector = NULL;  /* Selector de la regla que se está procesando */

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

%option noyywrap  /* No requiere función yywrap() para múltiples archivos */

/* ------------------------- ESTADOS EXCLUSIVOS ------------------------- */
/* Estados para manejar diferentes contextos del análisis léxico */
%x COMMENT      /* Estado para ignorar comentarios /* ... */ */
%x MEDIA_HDR    /* Estado para procesar la cabecera de @media */
%x SELECTOR     /* Estado para acumular el selector completo */
%x SELECTOR_DQ  /* Estado dentro de comillas dobles en selector */
%x SELECTOR_SQ  /* Estado dentro de comillas simples en selector */
%x BLOCK        /* Estado dentro de un bloque de propiedades { ... } */
%x VALUE        /* Estado procesando el valor de una propiedad */
%x DQSTR        /* Estado dentro de cadena entre comillas dobles en valor */
%x SQSTR        /* Estado dentro de cadena entre comillas simples en valor */

/* ------------------------- DEFINICIONES DE PATRONES ------------------------- */
/* Espacios en blanco: espacios, tabs, retornos de carro, saltos de línea */
WS      [ \t\r\n]+

/* Unidades de medida CSS permitidas según el enunciado */
UNIT    (pt|mm|cm|pc|in|px|em|ex)

/* Identificador: empieza con letra/guion, seguido de letras/números/guiones */
IDENT   [a-zA-Z_-][a-zA-Z0-9_-]*

/* Selector: caracteres permitidos en selectores CSS: clases, IDs, atributos, etc. */
SEL     [a-zA-Z0-9_.#:\[\]()=*,>+~\-\^\$\|\\,]+

/* Patrones auxiliares (no usados directamente pero útiles) */
NONWORD [^A-Za-z0-9_-]
NONHEX  [^0-9A-Fa-f]

/* Nombres de color permitidos */
COLORNAME (black|gray|silver|white|maroon|red|purple|fuchsia|green|lime|olive|yellow|navy|blue|teal|aqua|orange)

/* Colores hexadecimales: 3, 6 u 8 dígitos hexadecimales */
HEX3    \#[0-9A-Fa-f]{3}   /* Formato corto: #F0A */
HEX6    \#[0-9A-Fa-f]{6}   /* Formato estándar: #F0AA9B */
HEX8    \#[0-9A-Fa-f]{8}   /* Formato con alpha: #0000ffcc */

%%

/* ------------------------- REGLAS PARA COMENTARIOS ------------------------- */
/* Los comentarios /* ... */ se ignoran en todos los estados */
/* Guardamos el estado anterior para volver después del comentario */
<INITIAL,MEDIA_HDR,SELECTOR,BLOCK,VALUE>"/*"  { 
    prevState = YY_START;  /* Guardar estado actual */
    BEGIN(COMMENT);        /* Cambiar a estado de comentario */
}
<COMMENT>"*/"       { BEGIN(prevState); }  /* Volver al estado anterior */
<COMMENT>.|\n       { }  /* Ignorar todo dentro del comentario */

/* ------------------------- REGLAS EN ESTADO INITIAL ------------------------- */
/* Estado inicial: buscando selectores o bloques @media */
<INITIAL>{WS}+      { }  /* Ignorar espacios en blanco */

/* Detectar inicio de bloque @media */
<INITIAL>"@media"   { 
    mediaBlocks++;        /* Incrementar contador de bloques @media */
    BEGIN(MEDIA_HDR);     /* Cambiar a estado de cabecera @media */
}

/* ------------------------- REGLAS EN ESTADO MEDIA_HDR ------------------------- */
/* Procesando la cabecera de @media hasta encontrar el { */
<MEDIA_HDR>"{"      { 
    insideMedia = 1;      /* Marcar que estamos dentro de @media */
    mediaDepth = 1;       /* Inicializar profundidad de anidamiento */
    BEGIN(INITIAL);        /* Volver a INITIAL para buscar selectores */
}
<MEDIA_HDR>.|\n     { }  /* Ignorar todo en la cabecera hasta el { */

/* ------------------------- DETECCIÓN DE SELECTORES ------------------------- */
/* Cuando encontramos caracteres de selector, empezamos a acumularlo */
<INITIAL>{SEL}      { 
    yymore();        /* Acumular más texto para el selector completo */
    BEGIN(SELECTOR); /* Cambiar a estado SELECTOR */
}

/* ------------------------- REGLAS EN ESTADO SELECTOR ------------------------- */
/* Acumulando el selector completo hasta encontrar el { */
<SELECTOR>"{"       {
    /* Retroceder un carácter para que el { sea procesado por otra regla */
    yyless(yyleng-1);
    /* Guardar el selector completo de la regla actual */
    if (currentSelector) free(currentSelector);
    currentSelector = strdup(yytext);
    /* Reiniciar contadores para esta nueva regla */
    colorsInCurrentRule = 0;
    propertiesInCurrentRule = 0;
    /* Si estamos dentro de @media, incrementar profundidad */
    if (insideMedia) mediaDepth++;
    BEGIN(BLOCK);  /* Cambiar a estado BLOCK para procesar propiedades */
}

/* Continuar acumulando el selector: espacios, más caracteres, comillas */
<SELECTOR>{WS}+     { yymore(); }  /* Espacios dentro del selector */
<SELECTOR>{SEL}     { yymore(); }  /* Más caracteres del selector */
<SELECTOR>"\""      { 
    yymore(); 
    BEGIN(SELECTOR_DQ);  /* Entrar en cadena entre comillas dobles */
}
<SELECTOR>"'"       { 
    yymore(); 
    BEGIN(SELECTOR_SQ);  /* Entrar en cadena entre comillas simples */
}
<SELECTOR>.         { yymore(); }  /* Cualquier otro carácter del selector */

/* ------------------------- REGLAS PARA CADENAS EN SELECTORES ------------------------- */
/* Manejo de cadenas entre comillas dentro de selectores (atributos CSS) */
<SELECTOR_DQ>([^"\\\n]+|\\.)* { yymore(); }  /* Contenido de la cadena */
<SELECTOR_DQ>"\""             { 
    yymore(); 
    BEGIN(SELECTOR);  /* Volver a SELECTOR al cerrar comillas */
}

<SELECTOR_SQ>([^'\\\n]+|\\.)* { yymore(); }  /* Contenido de la cadena */
<SELECTOR_SQ>"'"               { 
    yymore(); 
    BEGIN(SELECTOR);  /* Volver a SELECTOR al cerrar comillas */
}

/* ------------------------- BLOQUES SIN SELECTOR ------------------------- */
/* Bloque que aparece sin selector previo (puede ocurrir en algunos casos) */
<INITIAL>"{"        {
    if (currentSelector) free(currentSelector);
    currentSelector = NULL;  /* No hay selector para este bloque */
    colorsInCurrentRule = 0;
    propertiesInCurrentRule = 0;
    BEGIN(BLOCK);
}

/* Cierre de bloque en INITIAL (puede cerrar bloques @media) */
<INITIAL>"}"        {
    if (insideMedia) {
        mediaDepth--;
        if (mediaDepth <= 0) { 
            insideMedia = 0;   /* Salimos completamente de @media */
            mediaDepth = 0; 
        }
    }
}
<INITIAL>.          { }  /* Ignorar cualquier otro carácter en INITIAL */

/* ------------------------- REGLAS EN ESTADO BLOCK ------------------------- */
/* Dentro de un bloque de propiedades { propiedad: valor; } */
<BLOCK>{WS}+        { }  /* Ignorar espacios en blanco */

/* Cierre del bloque de propiedades */
<BLOCK>"}"          {
    /* Actualizar máximo de colores si la regla actual tiene más */
    if (colorsInCurrentRule > maxColorsInRule) 
        maxColorsInRule = colorsInCurrentRule;
    
    /* Actualizar selector con más propiedades si corresponde */
    if (propertiesInCurrentRule > maxPropertiesInRule) {
        maxPropertiesInRule = propertiesInCurrentRule;
        if (maxSelectorStr) free(maxSelectorStr);
        maxSelectorStr = currentSelector ? strdup(currentSelector) : NULL;
    }
    
    /* Manejar cierre de bloques @media anidados */
    if (insideMedia) {
        mediaDepth--;
        if (mediaDepth <= 0) { 
            insideMedia = 0;   /* Salimos completamente de @media */
            mediaDepth = 0; 
        }
    }
    BEGIN(INITIAL);  /* Volver a INITIAL para buscar siguiente regla */
}

/* Detectar inicio de una propiedad: identificador seguido de : */
<BLOCK>{IDENT}{WS}*":" { 
    totalProperties++;           /* Incrementar contador global */
    propertiesInCurrentRule++;   /* Incrementar contador de la regla actual */
    BEGIN(VALUE);                /* Cambiar a estado VALUE para procesar el valor */
}
<BLOCK>.            { }  /* Ignorar otros caracteres en el bloque */

/* ------------------------- REGLAS EN ESTADO VALUE ------------------------- */
/* Procesando el valor de una propiedad CSS */
<VALUE>{WS}+        { }  /* Ignorar espacios en blanco en valores */

/* ------------------------- MANEJO DE CADENAS EN VALORES ------------------------- */
/* Las cadenas entre comillas en valores se ignoran según el enunciado */
<VALUE>"\""         { BEGIN(DQSTR); }  /* Inicio de cadena con comillas dobles */
<DQSTR>([^"\\\n]+|\\.)* { }  /* Contenido de la cadena (ignorado) */
<DQSTR>"\""         { BEGIN(VALUE); }  /* Fin de cadena, volver a VALUE */

<VALUE>"'"          { BEGIN(SQSTR); }  /* Inicio de cadena con comillas simples */
<SQSTR>([^'\\\n]+|\\.)* { }  /* Contenido de la cadena (ignorado) */
<SQSTR>"'"          { BEGIN(VALUE); }  /* Fin de cadena, volver a VALUE */

/* ------------------------- DETECCIÓN DE !important ------------------------- */
/* Detecta !important incluso con espacios entre ! y important */
<VALUE>"!"({WS}*)"important" { 
    importantCount++;  /* Incrementar contador de propiedades !important */
}

/* ------------------------- DETECCIÓN DE UNIDADES DE MEDIDA ------------------------- */
/* Número (entero o decimal) seguido de unidad de medida y delimitador */
<VALUE>([0-9]+(\.[0-9]+)?|\.[0-9]+){UNIT}[ \t\r\n;,\)!] {
    yyless(yyleng-1);  /* Retroceder delimitador para procesarlo después */
    measureCount++;     /* Incrementar contador de medidas */
}

/* ------------------------- DETECCIÓN DE COLORES HEX ------------------------- */
/* Colores hexadecimales: #RGB, #RRGGBB o #RRGGBBAA */
<VALUE>({HEX8}|{HEX6}|{HEX3})[ \t\r\n;,\)!] {
    yyless(yyleng-1);  /* Retroceder delimitador */
    colorCount++;       /* Incrementar contador global de colores */
    colorsInCurrentRule++;  /* Incrementar contador de colores en regla actual */
}

/* ------------------------- DETECCIÓN DE COLORES RGB ------------------------- */
/* Formato: rgb(num, num, num) o rgb(num%, num%, num%) */
/* Permite espacios flexibles alrededor de comas y valores */
<VALUE>rgb\({WS}*([0-9]+|[0-9]+%){WS}*,{WS}*([0-9]+|[0-9]+%){WS}*,{WS}*([0-9]+|[0-9]+%){WS}*\)[ \t\r\n;,\)!] {
    yyless(yyleng-1);  /* Retroceder delimitador */
    colorCount++;
    colorsInCurrentRule++;
}

/* ------------------------- DETECCIÓN DE COLORES RGBA ------------------------- */
/* Formato: rgba(num, num, num, alpha) o rgba(num%, num%, num%, alpha) */
/* El componente alpha puede ser decimal (0.5) o empezar con punto (.9) */
<VALUE>rgba\({WS}*([0-9]+|[0-9]+%){WS}*,{WS}*([0-9]+|[0-9]+%){WS}*,{WS}*([0-9]+|[0-9]+%){WS}*,{WS}*([0-9]+(\.[0-9]+)?|\.[0-9]+){WS}*\)[ \t\r\n;,\)!] {
    yyless(yyleng-1);  /* Retroceder delimitador */
    colorCount++;
    colorsInCurrentRule++;
}

/* ------------------------- DETECCIÓN DE NOMBRES DE COLOR ------------------------- */
/* Nombres de color predefinidos según el enunciado */
<VALUE>({COLORNAME})[ \t\r\n;,\)!] {
    yyless(yyleng-1);  /* Retroceder delimitador */
    colorCount++;
    colorsInCurrentRule++;
}

/* ------------------------- FIN DE VALOR ------------------------- */
<VALUE>";"          { BEGIN(BLOCK); }  /* Punto y coma termina el valor, volver a BLOCK */
<VALUE>.            { }  /* Ignorar otros caracteres en el valor */

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
    
    /* Liberar memoria asignada dinámicamente */
    if (currentSelector) free(currentSelector);
    if (maxSelectorStr) free(maxSelectorStr);
    
    /* Cerrar archivo si se abrió uno */
    if (argc > 1 && yyin) fclose(yyin);
    
    return 0;
}
