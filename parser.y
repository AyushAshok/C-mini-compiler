%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int yylineno;
void yyerror(const char *s);
void check_syntax();
int syntax_error = 0;

/* Symbol table structure */
typedef struct {
    char name[50];       // Variable name
    char type[10];       // Data type (int, float, etc.)
    int declared_at;     // Line number where declared
    int redeclared_at[100];  // Array to store redeclaration lines
    int redeclaration_count;
    int used_at[100];    // Line numbers where used
    int use_count;       // Number of times used
    int storage_size;    // Memory required
} Symbol;


Symbol symbolTable[100];
int symbolCount = 0;

/* Function to insert into symbol table */
void insertSymbol(const char *name, const char *type) {
    for (int i = 0; i < symbolCount; i++) {
        if (strcmp(symbolTable[i].name, name) == 0) {
            if (symbolTable[i].redeclaration_count < 100) {
                symbolTable[i].redeclared_at[symbolTable[i].redeclaration_count] = yylineno;
                symbolTable[i].redeclaration_count++;
            }
            return;
        }
    }
    strcpy(symbolTable[symbolCount].name, name);
    strcpy(symbolTable[symbolCount].type, type);
    symbolTable[symbolCount].declared_at = yylineno;
    symbolTable[symbolCount].use_count = 0;

    // Assign storage size based on type
    if (strcmp(type, "int") == 0) symbolTable[symbolCount].storage_size = sizeof(int);
    else if (strcmp(type, "float") == 0) symbolTable[symbolCount].storage_size = sizeof(float);
    else if (strcmp(type, "double") == 0) symbolTable[symbolCount].storage_size = sizeof(double);
    else if (strcmp(type, "char") == 0) symbolTable[symbolCount].storage_size = sizeof(char);
    else symbolTable[symbolCount].storage_size = 0; // Unknown

    symbolCount++;
}

void trackUsage(const char *name) {
    for (int i = 0; i < symbolCount; i++) {
        if (strcmp(symbolTable[i].name, name) == 0) {
            if (symbolTable[i].use_count < 100) {
                symbolTable[i].used_at[symbolTable[i].use_count] = yylineno;
                symbolTable[i].use_count++;
            }
            return;
        }
    }
}


/* Function to display the symbol table */
void displaySymbolTable() {
    printf("\nExtended Symbol Table:\n");
    printf("-------------------------------------------------------------------------------------------\n");
    printf("Name\t\tType\t\tDeclared At\tRedeclared At\tStorage\t\tUsed At\n");
    printf("-------------------------------------------------------------------------------------------\n");
    for (int i = 0; i < symbolCount; i++) {
        printf("%s\t\t%s\t\t%d\t\t", 
            symbolTable[i].name, 
            symbolTable[i].type, 
            symbolTable[i].declared_at);
        
        // Print redeclarations
        if (symbolTable[i].redeclaration_count > 0) {
            for (int r = 0; r < symbolTable[i].redeclaration_count; r++) {
                printf("%d ", symbolTable[i].redeclared_at[r]);
            }
        } else {
            printf("-");
        }
        
        printf("\t\t%d\t\t", symbolTable[i].storage_size);

        for (int j = 0; j < symbolTable[i].use_count; j++) {
            printf("%d ", symbolTable[i].used_at[j]);
        }
        printf("\n");
    }
    printf("-------------------------------------------------------------------------------------------\n");
}

%}

/* Define value types */
%union {
    int ival;
    float fval;
    char *str;
    char cval;
}

/* Token definitions */
%token INT FLOAT DOUBLE CHAR VOID IF ELSE RETURN FOR WHILE AND OR ASSIGN ADD SUB MUL DIV DO
%token LT GT LE GE EQ NE
%token SEMICOLON COLON COMMA LPAREN RPAREN LBRACE RBRACE LSQBRACE RSQBRACE
%token MAIN INCREMENT DECREMENT
%token <ival> NUMBER
%token <fval> FLOAT_NUM
%token <cval> CHAR_LITERAL
%token <str> ID

/* Declare types for nonterminals */
%type <str> type
%type <str> var_list
%type <str> array_declaration

/* Operator precedence */
%left OR
%left AND
%left EQ NE
%left LT GT LE GE
%left ADD SUB
%left MUL DIV
%right ASSIGN
%right INCREMENT DECREMENT

%%

program: 
    main_function { printf("Program parsed correctly.\n"); displaySymbolTable(); };

main_function: 
    INT MAIN LPAREN RPAREN LBRACE statements RBRACE;

statements: 
    statement statements
    | /* empty */;

statement:
    declaration SEMICOLON
    | array_declaration SEMICOLON
    | assignment SEMICOLON
    | array_assignment SEMICOLON
    | if_statement
    | for_loop
    | while_loop
    | return_statement SEMICOLON
    | do_while_loop 
    | increment_decrement SEMICOLON;

declaration:
    type var_list { 
        char *vars = $2;
        char *token = strtok(strdup(vars), ",");
        while (token != NULL) {
            while (*token == ' ') token++;
            insertSymbol(token, $1);
            token = strtok(NULL, ",");
        }
    };

array_declaration:
    type ID dimensions { insertSymbol($2, $1); }
    | type ID dimensions ASSIGN LBRACE array_initializer RBRACE { insertSymbol($2, $1); };

dimensions:
    LSQBRACE NUMBER RSQBRACE
    | dimensions LSQBRACE NUMBER RSQBRACE;


array_initializer:
    expression
    | array_initializer COMMA expression
    | /* empty */;

type:
    INT { $$ = "int"; }
    | FLOAT { $$ = "float"; }
    | CHAR { $$ = "char"; }
    | DOUBLE { $$ = "double"; }
    | VOID { $$ = "void"; };

var_list:
    ID { 
        $$ = $1;
        // Insert symbol here since we have direct access to the ID
    }
    | ID ASSIGN expression { 
        $$ = $1;
        trackUsage($1);
    }
    | var_list COMMA ID { 
        // Need to handle both the previous variables and new one
        char temp[100];
        sprintf(temp, "%s,%s", $1, $3);
        $$ = strdup(temp);
    }
    | var_list COMMA ID ASSIGN expression { 
        char temp[100];
        sprintf(temp, "%s,%s", $1, $3);
        $$ = strdup(temp);
        trackUsage($3);
    };


assignment:
    ID ASSIGN expression { trackUsage($1); }
    | ID ASSIGN increment_decrement { trackUsage($1); };

array_assignment:
    array_access ASSIGN expression;

array_access:
    ID LSQBRACE expression RSQBRACE;

increment_decrement:
    INCREMENT ID
    | DECREMENT ID
    | ID INCREMENT
    | ID DECREMENT
    | INCREMENT array_access
    | DECREMENT array_access
    | array_access INCREMENT
    | array_access DECREMENT;

expression:
    expression OR expression
    | expression AND expression
    | expression EQ expression
    | expression NE expression
    | expression LT expression
    | expression GT expression
    | expression LE expression
    | expression GE expression
    | expression ADD expression
    | expression SUB expression
    | expression MUL expression
    | expression DIV expression
    | NUMBER
    | FLOAT_NUM
    | CHAR_LITERAL
    | ID { trackUsage($1); }
    | array_access
    | LPAREN expression RPAREN;


if_statement:
    IF LPAREN expression RPAREN LBRACE statements RBRACE
    | IF LPAREN expression RPAREN statement
    | IF LPAREN expression RPAREN LBRACE statements RBRACE if_else_statement;

if_else_statement:
    ELSE IF LPAREN expression RPAREN LBRACE statements RBRACE if_else_statement
    | ELSE LBRACE statements RBRACE;

for_loop:
    FOR LPAREN for_init SEMICOLON expression SEMICOLON increment_decrement RPAREN LBRACE statements RBRACE;

for_init:
    declaration
    | assignment;

while_loop:
    WHILE LPAREN expression RPAREN LBRACE statements RBRACE
    | WHILE LPAREN expression RPAREN statement;

do_while_loop:
    DO LBRACE statements RBRACE WHILE LPAREN expression RPAREN SEMICOLON;

return_statement:
    RETURN expression;

%%

void yyerror(const char *s) {
    syntax_error = 1;
    fprintf(stderr, "Parse error at line %d: %s\n", yylineno, s);
}

int main() {
    if (yyparse() != 0 && syntax_error) {
        printf("Parsing completed with errors.\n");
    } else {
        printf("Parsing completed successfully.\n");
    }
    return 0;
}
