%{
/*
 * PRÁCTICA 1 - FLEX (Segunda Convocatoria)
 * Karima Drafli Rico
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

/* DEFINICIONES REGULARES */
WS              [ \t\r\n]+
UNIT            (pt|mm|cm|pc|in|px|em|ex)
NONWORD         [^A-Za-z0-9_-]

HEX3            #[0-9A-Fa-f]{3}
HEX6            #[0-9A-Fa-f]{6}
HEX8            #[0-9A-Fa-f]{8}

COLORNAME       (black|gray|grey|silver|white|maroon|red|purple|fuchsia|green|lime|olive|yellow|navy|blue|teal|aqua|orange)

%%

/* ===================== */
/* COMENTARIOS CSS */
"/*"                    { BEGIN(COMMENT); }
<COMMENT>"*/"           { BEGIN(INITIAL); }
<COMMENT>.|\n           { }

/* ===================== */
/* ESTADO INICIAL */

<INITIAL>"@media"       { mediaBlocks++; }

<INITIAL>{WS}           { }

<INITIAL>"{"            { BEGIN(BLOCK); }

<INITIAL>.              { }   /* Evita ECHO */

/* ===================== */
/* DENTRO DE BLOQUE */

<BLOCK>{WS}             { }

<BLOCK>"}"              { BEGIN(INITIAL); }

<BLOCK>"/*"             { BEGIN(COMMENT); }

/* Detectar propiedad */
<BLOCK>[a-zA-Z-]+{WS}*":" {
    totalProperties++;
    BEGIN(VALUE);
}

/* Catch-all */
<BLOCK>.                { }

/* ===================== */
/* VALORES DE PROPIEDADES */

<VALUE>{WS}             { }

/* Cadenas con comillas dobles */
<VALUE>"\""             { BEGIN(DQSTR); }
<DQSTR>"\\\\"           { }
<DQSTR>"\\\""           { }
<DQSTR>"\""             { BEGIN(VALUE); }
<DQSTR>.|\n             { }

/* Cadenas con comillas simples */
<VALUE>"\'"             { BEGIN(SQSTR); }
<SQSTR>"\\\\"           { }
<SQSTR>"\\\'"           { }
<SQSTR>"\'"             { BEGIN(VALUE); }
<SQSTR>.|\n             { }

/* !important */
<VALUE>"!"{WS}*"important" {
    importantCount++;
}

/* Unidades de medida */
<VALUE>[0-9]+\.?[0-9]*{UNIT} {
    measureCount++;
}

/* Colores HEX */
<VALUE>{HEX8}           { colorCount++; }
<VALUE>{HEX6}           { colorCount++; }
<VALUE>{HEX3}           { colorCount++; }

/* RGB / RGBA */
<VALUE>rgba?\([^)]*\)   { colorCount++; }

/* Nombres de color */
<VALUE>{COLORNAME}({NONWORD}|$) {
    if (isalnum((unsigned char)yytext[yyleng-1]) ||
        yytext[yyleng-1] == '_' ||
        yytext[yyleng-1] == '-') {
        yyless(yyleng - 1);
    }
    colorCount++;
}

/* Fin de declaración — ANTES del catch-all */
<VALUE>";"              { BEGIN(BLOCK); }

/* Comentarios dentro de valores */
<VALUE>"/*"             { BEGIN(COMMENT); }

/* Catch-all FINAL */
<VALUE>.                { }

%%

/* ===================== */
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

    if (yyin && argc > 1) fclose(yyin);
    return 0;
}
