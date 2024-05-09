%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Defining the structure for Symbol table
typedef struct {
    int line;
    char name[1000];
    char type[100]; 
    char value[100]; 
} SymbolEntry;

// Defining the structure for Identifier
typedef struct{
int line;
char name[1000];
int ye;
}Identifier;

Identifier Identifiers[1000];
int var_count = 0;

//Global variable
SymbolEntry symbolTable[1000]; 
int symbolTableSize = 0; 

extern int yylex(); 
extern FILE* yyin; 
extern int yylineno; 
extern char* yytext;
char current_type[100];

void yyerror(const char *s); 

void insertSymbol(int line, char *name, char *type, char *value) {
    SymbolEntry entry;
    entry.line = line; 
    strcpy(entry.name, name);
    strcpy(entry.type, type);
    strcpy(entry.value, value);
    symbolTable[symbolTableSize++] = entry;
}

%}

%union {
    struct {
        int line;
        char name[1000];
    } obj;
}

%token PROGRAM VAR TO DOWNTO IF ELSE WHILE FOR DO ARRAY AND OR NOT BEGINI END READ WRITE THEN OF COMMENT
%token <obj> IDENTIFIER NUMBER REAL_L CHAR_L STRING_LITERAL INTEGER REAL BOOLEAN CHAR
%type <obj> type
%token PLUS MINUS MUL DIVIDE MOD EQ NE LT GT LE GE ASSIGN OB CB OSB CSB COLON SEMICOLON COMMA DOT SINGLE DOUBLE DOUBLEDOT

%left ASSIGN
%left OR
%left AND
%left EQ NE
%left LT GT LE GE
%left PLUS MINUS
%left MUL DIVIDE MOD
%right NOT


%%

program : PROGRAM IDENTIFIER SEMICOLON variable_declaration_block BEGINI program_body END DOT
        {
            printf("valid input");
        }
        ;

variable_declaration_block : VAR variable_declaration_list 
                            | /* Empty */
                            ;

variable_declaration_list : variable_declaration_list variable_declaration
                            | variable_declaration
                            ;

variable_declaration : IDENTIFIER_LIST COLON type SEMICOLON
                      {
                          strcpy(current_type, $3.name);
                          for(int i=0; i<var_count; i++){
                          if(Identifiers[i].ye == 0){
                          insertSymbol(Identifiers[i].line, Identifiers[i].name, current_type, "");
                          Identifiers[i].ye = 1;
                          }
                          }
                      }
                      | IDENTIFIER_LIST COLON ARRAY_DECLARATION type SEMICOLON
                      {
                          strcpy(current_type, "Array of ");
                          strcat(current_type, $4.name);
                          for(int i=0; i<var_count; i++){
                          if(Identifiers[i].ye == 0){
                          insertSymbol(Identifiers[i].line, Identifiers[i].name, current_type, "");
                          Identifiers[i].ye = 1;
                          }
                          }
                      }
                      ;


ARRAY_DECLARATION : ARRAY OSB NUMBER DOUBLEDOT NUMBER CSB OF
                  ;

IDENTIFIER_LIST : IDENTIFIER
                {
                    Identifiers[var_count].line = $1.line;
                    strcpy(Identifiers[var_count].name, $1.name);
                    Identifiers[var_count].ye = 0;
                    var_count++;
                }
                | IDENTIFIER_LIST COMMA IDENTIFIER
                {
                    Identifiers[var_count].line = $3.line;
                    strcpy(Identifiers[var_count].name, $3.name);
                    Identifiers[var_count].ye = 0;
                    var_count++;
                }
                ;

IDENTIFIER_LIST_WRITE : IDENTIFIER
                |array_expression
                | IDENTIFIER_LIST_WRITE COMMA IDENTIFIER
                | IDENTIFIER_LIST_WRITE COMMA array_expression
                ;

type : INTEGER
    | REAL
    | BOOLEAN
    | CHAR
    ;
    
NUMERIC: NUMBER
        | REAL_L
        | CHAR_L
        ;
        
program_body : statement_or_block_list
            | /* Empty */
            ;

statement_or_block_list : statement_or_block_list statement_or_block
                        | statement_or_block
                        ;

statement_or_block : statement
                    | statement_block
                    ;

statement_block : BEGINI statement_list END SEMICOLON
                ;
statement_block_else: BEGINI statement_list END                

statement_list : statement_list statement
                | statement
                ;

statement : assignment_statement
            | conditional_statement
            | loop_statement
            | read_statement
            | write_statement
            ;

expression : arithmetic_expression
            ;

array_expression : IDENTIFIER OSB NUMBER CSB
                 | IDENTIFIER OSB IDENTIFIER CSB
                 | IDENTIFIER OSB array_expression CSB
                ;
arithmetic_expression : IDENTIFIER
                      | NUMERIC
                      |array_expression
                      | arithmetic_expression PLUS arithmetic_expression
                      | arithmetic_expression MINUS arithmetic_expression
                      | arithmetic_expression MUL arithmetic_expression
                      | arithmetic_expression DIVIDE arithmetic_expression
                      | arithmetic_expression MOD arithmetic_expression
                      | OB arithmetic_expression CB
                      ;

boolean_expression : relational_expression
                    | IDENTIFIER
                    | boolean_expression AND boolean_expression
                    | boolean_expression OR boolean_expression
                    | NOT boolean_expression %prec NOT
                    ;

relational_expression : arithmetic_expression EQ arithmetic_expression
                        | arithmetic_expression NE arithmetic_expression
                        | arithmetic_expression LT arithmetic_expression
                        | arithmetic_expression GT arithmetic_expression
                        | arithmetic_expression LE arithmetic_expression
                        | arithmetic_expression GE arithmetic_expression
                        | OB relational_expression CB
                        ;


condition : boolean_expression
          ;
          
conditional_statement : IF condition THEN statement_block
                        | IF condition THEN statement_block_else ELSE statement_block
                        ;

assignment_statement : IDENTIFIER ASSIGN expression SEMICOLON
                      |array_expression ASSIGN expression SEMICOLON
;


loop_statement : WHILE condition DO statement_block
                | FOR IDENTIFIER ASSIGN expression direction expression DO statement_block
                ;

direction : TO
            | DOWNTO
            ;

read_statement : READ OB IDENTIFIER CB SEMICOLON
                |READ OB array_expression CB SEMICOLON
                ;

write_statement : WRITE OB write_argument_list CB SEMICOLON
                ;

write_argument_list : STRING_LITERAL
                    | IDENTIFIER_LIST_WRITE
                    ;

%%

void yyerror(const char *s) {
    printf("syntax error");
    exit(0);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    FILE *input_file = fopen(argv[1], "r");
    if (input_file == NULL) {
        perror("Error opening file");
        return 1;
    }

    yyin = input_file;

    yyparse(); 
    
    fclose(input_file); 

    /*printf("Symbol Table:\n");
    printf("Line\t\tName\t\tType\t\tValue\n");
    for (int i = 0; i < symbolTableSize; ++i) {
        printf("%d\t\t%s\t\t%s\t\t%s\n", symbolTable[i].line, symbolTable[i].name, symbolTable[i].type, symbolTable[i].value);
    }*/

    return 0;
}
