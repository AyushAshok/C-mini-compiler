%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern YYSTYPE yylval;
%}

%option yylineno
%option noyywrap

%%

"#"([^\n]*)                              { /* ignore preprocessor directives */ }
"//".*                                   { /* ignore single-line comments */ }
"/*"([^*]|\*+[^*/])*\*+"/"             { /* ignore multi-line comments */ }

"main"        { return MAIN; }
"int"         { return INT; }
"float"       { return FLOAT; }
"double"      { return DOUBLE; }
"char"        { return CHAR; }
"void"        { return VOID; }
"if"          { return IF; }
"else"        { return ELSE; }
"return"      { return RETURN; }
"for"         { return FOR; }
"do"          { return DO; }
"while"       { return WHILE; }

"++"          { return INCREMENT; }
"--"          { return DECREMENT; }
"&&"          { return AND; }
"||"          { return OR; }
"="           { return ASSIGN; }
"+"           { return ADD; }
"-"           { return SUB; }
"*"           { return MUL; }
"/"           { return DIV; }
"<"           { return LT; }
">"           { return GT; }
"<="          { return LE; }
">="          { return GE; }
"=="          { return EQ; }
"!="          { return NE; }
":"           { return COLON; }
";"           { return SEMICOLON; }
","           { return COMMA; }
"("           { return LPAREN; }
")"           { return RPAREN; }
"{"           { return LBRACE; }
"}"           { return RBRACE; }
"["           { return LSQBRACE; }
"]"           { return RSQBRACE; }

[0-9]+        { 
    yylval.ival = atoi(yytext); 
    return NUMBER; 
}

[0-9]+(\.[0-9]*)?([eE][-+]?[0-9]+)? { 
    yylval.fval = atof(yytext); 
    return FLOAT_NUM; 
}

[A-Za-z_][A-Za-z0-9_]* { 
    yylval.str = strdup(yytext); 
    return ID; 
}

\'([^\n\'])\'  { yylval.cval = yytext[1];  return CHAR_LITERAL; }

[ \t\n]+      { /* skip whitespace */ }
.             { /* unrecognized token */ }

%%
