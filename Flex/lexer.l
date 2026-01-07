%{
/*
 * PRÁCTICA 1 - FLEX (Segunda Convocatoria) Karima Drafli Rico
 */

/* Contadores globales */
int mediaBlocks = 0;
int totalProperties = 0;
int importantCount = 0;
int measureCount = 0;
int colorCount = 0;

/* Contadores por regla */
int propertiesInCurrentRule = 0;
int maxPropertiesInRule = 0;
int colorsInCurrentRule = 0;
int maxColorsInRule = 0;

/* Selectores */
char currentSelector[1024];
char maxSelector[1024];

/* Reglas dentro/fuera de media */
int insideMedia = 0;
int rulesInsideMedia = 0;
int rulesOutsideMedia = 0;

%}

%option noyywrap

%x COMMENT
%x BLOCK
%x VALUE
%x DQSTR
%x SQSTR

/* Patrones */
WS              [ \t\r\n]+
UNIT            (pt|mm|cm|pc|in|px|em|ex)
IDENT           [a-zA-Z_-][a-zA-Z0-9_-]*

HEX3            \#[0-9A-Fa-f]{3}
HEX6            \#[0-9A-Fa-f]{6}
HEX8            \#[0-9A-Fa-f]{8}

COLORNAME       (black|gray|grey|silver|white|maroon|red|purple|fuchsia|green|lime|olive|yellow|navy|blue|teal|aqua|orange)
RGBFN           rgb\([0-9%,. ]*\)
RGBAFN          rgba\([0-9%,. ]*(,[0-9.]+)?\)

%%

/* ------------------ COMENTARIOS ------------------ */
"/*"                { BEGIN(COMMENT); }
<COMMENT>"*/"       { BEGIN(INITIAL); }
<COMMENT>.|\n       { }

/* ------------------ INICIAL ------------------ */
<INITIAL>{WS}+      { }
<INITIAL>"@media"   { mediaBlocks++; insideMedia = 1; }
<INITIAL>"{"       { propertiesInCurrentRule = 0; colorsInCurrentRule = 0; BEGIN(BLOCK); }
<INITIAL>[^{}]+     { 
                        int len = yyleng < sizeof(currentSelector)-1 ? yyleng : sizeof(currentSelector)-1;
                        strncpy(currentSelector, yytext, len);
                        currentSelector[len] = '\0';
                     }

/* ------------------ BLOQUE ------------------ */
<BLOCK>{WS}+        { }
<BLOCK>"/*"          { BEGIN(COMMENT); }
<BLOCK>"}"          { 
                        if(propertiesInCurrentRule > maxPropertiesInRule) {
                            maxPropertiesInRule = propertiesInCurrentRule;
                            strncpy(maxSelector, currentSelector, sizeof(maxSelector)-1);
                            maxSelector[sizeof(maxSelector)-1] = '\0';
                        }
                        if(colorsInCurrentRule > maxColorsInRule) maxColorsInRule = colorsInCurrentRule;
                        if(insideMedia) rulesInsideMedia++; else rulesOutsideMedia++;
                        insideMedia = 0;
                        BEGIN(INITIAL);
                     }
/* Propiedad: nombre: */
<BLOCK>{IDENT}{WS}*":" { totalProperties++; propertiesInCurrentRule++; BEGIN(VALUE); }
<BLOCK>.             { }

/* ------------------ VALOR ------------------ */
<VALUE>{WS}+         { }
<VALUE>"/*"           { BEGIN(COMMENT); }

/* Cadenas dobles y simples */
<VALUE>"\""           { BEGIN(DQSTR); }
<DQSTR>[^"]+          { }
<DQSTR>"\""           { BEGIN(VALUE); }

<VALUE>"\'"           { BEGIN(SQSTR); }
<SQSTR>[^']+          { }
<SQSTR>"\'"           { BEGIN(VALUE); }

/* Propiedades !important */
<VALUE>"!"{WS}*"important" { importantCount++; }

/* Valores con unidades */
<VALUE>[0-9]+\.?[0-9]*{UNIT} { measureCount++; }

/* Colores HEX */
<VALUE>{HEX8}        { colorCount++; colorsInCurrentRule++; }
<VALUE>{HEX6}        { colorCount++; colorsInCurrentRule++; }
<VALUE>{HEX3}        { colorCount++; colorsInCurrentRule++; }

/* Colores RGB/RGBA */
<VALUE>{RGBFN}       { colorCount++; colorsInCurrentRule++; }
<VALUE>{RGBAFN}      { colorCount++; colorsInCurrentRule++; }

/* Colores por nombre */
<VALUE>{COLORNAME}   { colorCount++; colorsInCurrentRule++; }

/* Fin de propiedad */
<VALUE>";"           { BEGIN(BLOCK); }

<VALUE>.              { }

%%

/* ------------------ IMPRESIÓN DE RESULTADOS ------------------ */
int yywrap(void) { 
    printf("1. Número de bloques @media: %d\n", mediaBlocks);
    printf("2. Número total de propiedades: %d\n", totalProperties);
    printf("3. Selector con máximo número de propiedades: %s (%d)\n", maxSelector, maxPropertiesInRule);
    printf("4. Número de propiedades !important: %d\n", importantCount);
    printf("5. Número de valores con unidades de medida: %d\n", measureCount);
    printf("6. Número de especificaciones de color: %d\n", colorCount);
    printf("7. Máximo número de colores en una regla: %d\n", maxColorsInRule);
    printf("8. Reglas dentro de @media: %d\n", rulesInsideMedia);
    printf("9. Reglas fuera de @media: %d\n", rulesOutsideMedia);
    return 1;
}
