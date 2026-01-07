%{
/* PRACTICA 1 - FLEX (Segunda Convocatoria Karima Drafli Rico) */
/* SECCION DEFINICIONES */
/* INICIALIZAMOS VARIABLES GLOBALES */

int mediaBlocks = 0;
int totalProperties = 0;
int importantCount = 0;
int measureCount = 0;
int colorCount = 0;

int colorsInCurrentRule = 0;
int maxColorsInRule = 0;
int propertiesInCurrentRule = 0;
int maxPropertiesInRule = 0;

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

WS      [ \t\r\n]+
UNIT    (pt|mm|cm|pc|in|px|em|ex)
IDENT   [a-zA-Z_-][a-zA-Z0-9_-]*

HEX3        \#[0-9A-Fa-f]{3}
HEX6        \#[0-9A-Fa-f]{6}
HEX8        \#[0-9A-Fa-f]{8}

COLORNAME   (black|gray|grey|silver|white|maroon|red|purple|fuchsia|green|lime|olive|yellow|navy|blue|teal|aqua|orange)
RGBFN       rgb\([0-9% ,\.]*\)
RGBAFN      rgba\([0-9% ,\.]*,[0-9\.]*\)

%%

"/*"            { BEGIN(COMMENT); }
<COMMENT>"*/"   { BEGIN(INITIAL); }
<COMMENT>.|\n   { }

<INITIAL>{WS}+  { }
<INITIAL>"@media" { mediaBlocks++; insideMedia = 1; }
<INITIAL>"{"       { 
    colorsInCurrentRule=0; 
    propertiesInCurrentRule=0; 
    BEGIN(BLOCK); 
}
<INITIAL>.      { }

<BLOCK>{WS}+    { }
<BLOCK>"/*"     { BEGIN(COMMENT); }
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
<VALUE>"/*"     { BEGIN(COMMENT); }

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

<VALUE>{RGBFN} { colorCount++; colorsInCurrentRule++; }
<VALUE>{RGBAFN} { colorCount++; colorsInCurrentRule++; }

<VALUE>{COLORNAME} { colorCount++; colorsInCurrentRule++; }
<VALUE>";"   { BEGIN(BLOCK); }
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
