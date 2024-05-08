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

typedef struct {
    int lineno;
    char *op;     // Operator
    char *arg1;  // First operand
    char *arg2;  // Second operand
    char *result; // Result variable
} Quadruple;

Quadruple quadList[1000]; // Array of quadruples
int quadIndex = 0;        // Index for the next quadruple

// Defining the structure for Identifier
typedef struct{
int line;
char name[1000];
int ye;
}Identifier;

Identifier Identifiers[1000];
int var_count = 0;
int currentline = 0;

//Global variable
SymbolEntry symbolTable[1000]; 
int symbolTableSize = 0; 

extern int yylex(); 
extern FILE* yyin; 
extern int yylineno; 
extern char* yytext;
char current_type[100];
// Function to create a new temporary variable
char* newTemp() {
    static int tempCount = 0;
    char tempName[20];
    sprintf(tempName, "t%d", tempCount++);
    return strdup(tempName);
}
int labelCount = 0;

char* newLabel() {
    char* label = malloc(20 * sizeof(char));
    sprintf(label, "L%d", labelCount++);
    return label;
}

char* newCond(char* str1, char* str2, char* str3) {
    if (!str1 || !str2 || !str3) {
        fprintf(stderr, "Null pointer received in newCond\n");
        return NULL;
    }

    // Calculate the length of the new string
    int length = strlen(str1) + strlen(str2) + strlen(str3) + 1; // +1 for the null-terminator

    // Allocate memory for the new string
    char* newStr = malloc(length * sizeof(char));
    if (!newStr) {
        fprintf(stderr, "Failed to allocate memory in newCond\n");
        return NULL;
    }

    // Concatenate the strings
    strcpy(newStr, str1);
    strcat(newStr, str2);
    strcat(newStr, str3);

    return newStr;
}
// Function to add a new quadruple to the list
void emit(int line, char* op, char* arg1, char* arg2, char* result) {
    Quadruple q;
    q.lineno = line;
    q.op = op ? strdup(op) : NULL;
    q.arg1 = arg1 ? strdup(arg1) : NULL;
    q.arg2 = arg2 ? strdup(arg2) : NULL;
    q.result = result ? strdup(result) : NULL;
    quadList[quadIndex++] = q;
}
void freeQuadList() {
    for (int i = 0; i < quadIndex; i++) {
        free(quadList[i].op);
        free(quadList[i].arg1);
        free(quadList[i].arg2);
        free(quadList[i].result);
    }
}

void printSymbolTable() {
    printf("Line\tName\t\tType\t\tValue\n");
    printf("-------------------------------------------------\n");
    for (int i = 0; i < symbolTableSize; i++) {
        printf("%d\t%s\t\t%s\t\t%s\n", 
               symbolTable[i].line, 
               symbolTable[i].name, 
               symbolTable[i].type, 
               symbolTable[i].value);
    }
}

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
        char* str; // Changed from char* str[1000];
    } obj;
}

%type <obj> arithmetic_expression boolean_expression relational_expression conditional_statement ARRAY_DECLARATION
%type <obj> variable_declaration assignment_statement loop_statement expression array_expression condition statement_block_else statement_block direction
%token <obj> PROGRAM VAR TO DOWNTO IF ELSE WHILE FOR DO ARRAY AND OR NOT BEGINI END READ WRITE THEN OF COMMENT
%token <obj> IDENTIFIER NUMBER REAL_L CHAR_L STRING_LITERAL INTEGER REAL BOOLEAN CHAR
%type <obj> type
%token <obj> PLUS MINUS MUL DIVIDE MOD EQ NE LT GT LE GE ASSIGN OB CB OSB CSB COLON SEMICOLON COMMA DOT SINGLE DOUBLE DOUBLEDOT

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
            //printf("valid input");
             printSymbolTable();
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

array_expression : IDENTIFIER OSB NUMBER CSB{
                 char* result = newTemp();
                  emit($1.line, "+", $1.name, $3.name,result);
                  char* result2 = newTemp();
                  emit($1.line,":=", result, "", result2);
                  char* result3 = newTemp();
                  //result2 = strcat(result2, "]");
                  //result2 = strcat("[", result2);
                  emit($1.line,":=", "*", result2, result3);
                  currentline= $1.line;
                  $$.str = strdup(result3);
                 }
                 | IDENTIFIER OSB IDENTIFIER CSB{
                 char* result = newTemp();
                  emit($1.line,"+", $1.name, $3.name,result);
                  char* result2 = newTemp();
                  emit($1.line,":=", result, "", result2);
                  char* result3 = newTemp();
                  //result2 = strcat(result2, "]");
                  //result2 = strcat("[", result2);
                  emit($1.line,":=", "*", result2, result3);
                  $$.str = strdup(result3);
                  currentline= $1.line;
                 }
                 | IDENTIFIER OSB array_expression CSB{
                 char* result = newTemp();
                  emit($1.line,"+", $1.name, $3.str,result);
                  char* result2 = newTemp();
                  emit($1.line,":=", result, "", result2);
                  char* result3 = newTemp();
                  //result2 = strcat(result2, "]");
                  //result2 = strcat("[", result2);
                  emit($1.line,":=", "*", result2, result3);
                  $$.str = strdup(result3);
                  currentline= $1.line;
                 }
                ;
arithmetic_expression : IDENTIFIER { $$.str = strdup($1.name); }
                      | NUMERIC  {
                            // Direct usage of numeric values in expressions, possibly convert to string if not already
                            $$.str = strdup(yytext);  // Assuming yytext holds the numeric value as string
                        }
                      |array_expression  {
                            // Assuming array_expression handling computes an address or fetches a value
                            $$.str = $1.str;  // $1 should be the result of the array access, possibly a temporary variable
                        }
                      | arithmetic_expression PLUS arithmetic_expression  {
                            char* result = newTemp();
                            emit($2.line,"+", $1.str, $3.str, result);
                            $$.str = result;
                            currentline= $2.line;
                        }
                      | arithmetic_expression MINUS arithmetic_expression {
                            char* result = newTemp();
                            emit($2.line,"-", $1.str, $3.str, result);
                            $$.str = result;
                            currentline= $2.line;
                        }
                      | arithmetic_expression MUL arithmetic_expression {
                            char* result = newTemp();
                            emit($2.line,"*", $1.str, $3.str, result);
                            $$.str = result;
                            currentline= $2.line;
                        }
                      | arithmetic_expression DIVIDE arithmetic_expression {
                            char* result = newTemp();
                            emit($2.line,"/", $1.str, $3.str, result);
                            $$.str = result;
                            currentline= $2.line;
                        }
                      | arithmetic_expression MOD arithmetic_expression {
                            char* result = newTemp();
                            emit($2.line,"%", $1.str, $3.str, result);
                            $$.str = result;
                            currentline= $2.line;
                        }
                      | OB arithmetic_expression CB{
                          $$.str = $2.str;
                      }
                      ;

boolean_expression:
      relational_expression
      {
          $$.str = $1.str; // Pass the result directly up if it's a relational result
      }
    | IDENTIFIER
      {
          $$.str = strdup($1.str); // Direct use of the identifier in a boolean context
      }
    | boolean_expression AND boolean_expression
      {
          char* result = newTemp();
          emit($2.line,"and", $1.str, $3.str, result);
          $$.str = result;
          currentline= $2.line;
      }
    | boolean_expression OR boolean_expression
      {
          char* result = newTemp();
          emit($2.line,"or", $1.str, $3.str, result);
          $$.str = result;
          currentline= $2.line;
      }
    | NOT boolean_expression %prec NOT
      {
          char* result = newTemp();
          emit($1.line,"not", $2.str, "", result);
          $$.str = result;
          currentline= $2.line;
      }
    ;


relational_expression:
      arithmetic_expression EQ arithmetic_expression
      {
          char* result = newTemp();
          emit($2.line,"=", $1.str, $3.str, result);
          currentline= $2.line;
          $$.str = result;
      }
    | arithmetic_expression NE arithmetic_expression
      {
          char* result = newTemp();
          emit($2.line,"<>", $1.str, $3.str, result);
          currentline= $2.line;
          $$.str = result;
      }
    | arithmetic_expression LT arithmetic_expression
      {
          char* result = newTemp();
          emit($2.line,"<", $1.str, $3.str, result);
          currentline= $2.line;
          $$.str = result;
      }
    | arithmetic_expression GT arithmetic_expression
      {
          char* result = newTemp();
          emit($2.line,">", $1.str, $3.str, result);
          currentline= $2.line;
          $$.str = result;
      }
    | arithmetic_expression LE arithmetic_expression
      {
          char* result = newTemp();
          emit($2.line,"<=", $1.str, $3.str, result);
          currentline= $2.line;
          $$.str = result;
      }
    | arithmetic_expression GE arithmetic_expression
      {
          char* result = newTemp();
          emit($2.line,">=", $1.str, $3.str, result);
          currentline= $2.line;
          $$.str = result;
      }
    | OB relational_expression CB
      {
          $$.str = $2.str; // Simply propagate the value inside the parentheses
      }
    ;


condition : boolean_expression{
    $$.str = $1.str;
}
          ;
conditional_statement:
  IF condition THEN statement_block
  {
      char* labelEnd = newLabel();
      char* result2 = newTemp();
      emit($1.line, "not", $2.str, "", result2);
      emit($1.line,"IF", result2, "GOTO", labelEnd); // Emit conditional jump
      $$.str = $4.str;
      emit(currentline+1,"LABEL" , labelEnd, "", "");
  }
| IF condition THEN statement_block_else
  {
      char* labelElse = newLabel();
      char* result2 = newTemp();
      emit($1.line, "not", $2.str, "", result2);
      emit($1.line,"IF", result2, "GOTO", labelElse);
      emit(currentline+1,"LABEL" , labelElse, "", "");
  }ELSE statement_block{
      $$.str = $6.str;
  }
;



assignment_statement:
      IDENTIFIER ASSIGN expression SEMICOLON
      {
          emit($1.line,":=", $3.str, " ", $1.name); // Simple assignment
          currentline = $1.line;
      }
    | array_expression ASSIGN expression SEMICOLON
      {
          char* result = newTemp();
          emit($2.line,"array_store", $3.str, $1.str, result); // Assuming array store needs a temp
          currentline = $2.line;
      }
    ;



loop_statement:
      WHILE condition DO statement_block
      {
          char* startLabel = newLabel();
          char* endLabel = newLabel();
          char* result2 = newTemp();
          emit($1.line, "not", $2.str, "", result2);
          emit($1.line, "LABEL", startLabel, "", "");
          emit($1.line,"IF", result2, "GOTO", endLabel); // Conditional jump based on the loop condition
          $$.str = $4.str;
          emit(currentline+1, "GOTO", startLabel, "", "");
          emit(currentline+1,"LABEL" , endLabel, "", "");
      }
    | FOR IDENTIFIER ASSIGN expression direction expression DO statement_block
      {
          char* startLabel = newLabel();
          char* endLabel = newLabel();
          emit($1.line,":=", $4.str, "", $2.name); // Initialization
          
          //printf("%s:\n", startLabel);
          char* sign;
          if(strcmp("to", $5.str)==0){
              sign = strdup(">");
          }
          else{
              sign = strdup("<");
          }
          char* result = newTemp();
          emit($1.line, sign, $2.name, $6.str, result);
          emit($1.line,"LABEL" , startLabel, "", "");
          emit($1.line,"IF", result, "GOTO", endLabel); // Loop condition
          $$.str = $8.str;
          emit(currentline+1, "+", $2.name, "1", $2.name);
          emit(currentline+1, "GOTO", startLabel, "", "");
          emit(currentline+1,"LABEL" , endLabel, "", "");
      }
    ;


direction : TO{
      $$.str = strdup("to");
}
            | DOWNTO{
            $$.str = strdup("downto");
            }
            ;

read_statement:
    READ OB IDENTIFIER CB SEMICOLON
    | READ OB array_expression CB SEMICOLON
    ;

write_statement:
    WRITE OB write_argument_list CB SEMICOLON

    ;

write_argument_list:
      STRING_LITERAL
    | IDENTIFIER_LIST_WRITE
    ;
%%

void yyerror(const char *s) {
    printf("syntax error");
    exit(0);
}
int main(int argc, char *argv[]){

    char* filename;

    filename=argv[1];

    printf("\n");

    yyin=fopen(filename, "r");

    yyparse();

    return 0;

}