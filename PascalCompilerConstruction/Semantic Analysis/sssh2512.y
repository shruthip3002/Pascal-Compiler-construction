%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

// Define AST node structure
typedef struct ASTNode {
    char* token;
    char* type;
    char* value;
    struct ASTNode** children;
    int num_children;
} ASTNode;

// Function to create AST nodes
ASTNode* create_node(char* token, char* type, char* value, int num_children) {
    ASTNode* node = (ASTNode*)malloc(sizeof(ASTNode));
    if (node == NULL) {
        // Handle memory allocation failure
        fprintf(stderr, "Memory allocation failed\n");
        exit(EXIT_FAILURE);
    }
    node->token = strdup(token);
    node->type = strdup(type);
    node->value = strdup(value);
    if (node->token == NULL || node->type == NULL || node->value == NULL) {
        // Handle strdup failure
        fprintf(stderr, "Memory allocation failed\n");
        free(node); // Free allocated node
        exit(EXIT_FAILURE);
    }
    node->num_children = num_children;
    node->children = (ASTNode**)malloc(num_children * sizeof(ASTNode*));
    if (node->children == NULL) {
        // Handle memory allocation failure
        fprintf(stderr, "Memory allocation failed\n");
        free(node->token);
        free(node->type);
        free(node->value);
        free(node);
        exit(EXIT_FAILURE);
    }
    return node;
}

// Function to free AST nodes
void free_node(ASTNode* node) {
    if (node == NULL) {
        return;
    }
    free(node->token);
    free(node->type);
    free(node->value);
    for (int i = 0; i < node->num_children; i++) {
        free_node(node->children[i]);
    }
    free(node->children);
    free(node);
}


// Define structure for symbol table entry
typedef struct {
    int line;
    char name[1000];
    char type[100]; 
    char value[100]; 
    int dec;
} SymbolEntry;

// Define structure for Identifier
typedef struct{
    int line;
    char name[1000];
    int ye;
    ASTNode* node_identifier;
} Identifier;

int flag = 0;

struct ASTNode *head;
Identifier Identifiers[1000];
int var_count = 0;

// Global symbol table
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
    entry.dec = 0;
    symbolTable[symbolTableSize++] = entry;
}

int isDeclared(char *name) {
    for (int i = 0; i < symbolTableSize; i++) {
        if (strcmp(symbolTable[i].name, name) == 0) {
            return 1; // Identifier found in symbol table
        }
    }
    return 0; // Identifier not found
}

void printUndeclaredError(char *name) {
    printf("undeclared variable: %s\n", name);
}

void print_tree2(FILE *fp, ASTNode *root) {
    if (!root) {
        fprintf(fp, "()");
        return;
    }
    fprintf(fp, "( %s ", root->token);
    for (int i = 0; i < root->num_children; ++i) {
        print_tree2(fp, root->children[i]);
    }
    fprintf(fp, ")");
}
void print_tree() {
    FILE *fp = fopen("syntaxtree.txt", "w");
    print_tree2(fp, head);
}

// Function to change an identifier's dec field to 1
void setIdentifierDec(const char* name) {
    for (int i = 0; i < symbolTableSize; i++) {
        if (strcmp(symbolTable[i].name, name) == 0) {
            symbolTable[i].dec = 1;
            return; // Exit the loop after updating the dec field
        }
    }
}

// Function to output an identifier's dec field
int getIdentifierDec(const char* name) {
    for (int i = 0; i < symbolTableSize; i++) {
        if (strcmp(symbolTable[i].name, name) == 0) {
            return symbolTable[i].dec; // Return the dec field value
        }
    }
    return -1; // Return -1 if the identifier is not found
}



void assignTypeToSubtree(ASTNode *node, const char *type) {
    // Base case: If the node has no children, assign the type and return
    if (node->num_children == 0) {
        if (node->type != NULL) {
            free(node->type); // Free previously allocated memory, if any
        }
        node->type = strdup(type);
        return;
    }

    // Assign type to the current node
    if (node->type != NULL) {
        free(node->type); // Free previously allocated memory, if any
    }
    node->type = strdup(type);

    // Recursively assign type to all children nodes
    for (int i = 0; i < node->num_children; i++) {
        assignTypeToSubtree(node->children[i], type);
    }
}


int caseInsensitiveCompare(const char* str1, const char* str2) {
    while (*str1 && *str2) {
        if (tolower((unsigned char)*str1) != tolower((unsigned char)*str2)) {
            return 0; // Not equal
        }
        str1++;
        str2++;
    }
    return (*str1 == '\0' && *str2 == '\0'); // Check if both strings are at the end
}

char* lastWord(const char* str) {
    // Find the last space character in the string
    const char* space = strrchr(str, ' ');

    // If space is found, return a pointer to the next character after space
    if (space != NULL) {
        return strdup(space + 1);
    } else {
        // If no space found, return the entire string
        return strdup(str);
    }
}


void printSymbolTable() {
    printf("Symbol Table:\n");
    printf("--------------------------------------------------\n");
    printf("| Line |   Name   |   Type   |   Value   |\n");
    printf("--------------------------------------------------\n");

    for (int i = 0; i < symbolTableSize; i++) {
        printf("| %-5d| %-9s| %-9s| %-11s|\n",
               symbolTable[i].line,
               symbolTable[i].name,
               symbolTable[i].type,
               symbolTable[i].value);
    }

    printf("--------------------------------------------------\n");
}


char* getTypeFromSymbolTable(const char* name) {
    for (int i = 0; i < symbolTableSize; i++) {
        if (strcmp(symbolTable[i].name, name) == 0) {
            char* type = strdup(symbolTable[i].type); // Make a copy of the type string
            char* lastSpace = strrchr(type, ' '); // Find the last space in the string
            if (lastSpace != NULL) {
                // If space found, return the next character after space
                return strdup(lastSpace + 1);
            } else {
                // If no space found, return the entire string
                return strdup(type);
            }
        }
    }
    return NULL; // Return NULL if name not found in symbol table
}





%}

%union {
    struct {
        int line;
        char name[1000];
        struct ASTNode* node;
        int itsint;
        int itschar;
        int itsbool;
        int itsreal;
    } obj;
}



%token <obj> PROGRAM VAR TO DOWNTO IF ELSE WHILE FOR DO ARRAY AND OR NOT BEGINI END READ WRITE THEN OF COMMENT INVALID_TOKEN
%token <obj> IDENTIFIER NUMBER REAL_L CHAR_L STRING_LITERAL
%token INTEGER REAL BOOLEAN CHAR
%token <obj> PLUS MINUS MUL DIVIDE MOD EQ NE LT GT LE GE ASSIGN 
%token OB CB OSB CSB COLON SEMICOLON COMMA DOT SINGLE DOUBLE DOUBLEDOT

%type <obj> program variable_declaration_block variable_declaration_list variable_declaration type program_body statement_or_block_list statement_or_block statement_block statement_block_else statement_list statement assignment_statement conditional_statement loop_statement read_statement write_statement write_argument_list expression array_expression arithmetic_expression boolean_expression relational_expression condition IDENTIFIER_LIST IDENTIFIER_LIST_WRITE NUMERIC ARRAY_DECLARATION direction

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
            // Construct AST node for the program
            $$.node = create_node("PROGRAM", "",  "", 2);
            $$.node ->children[0] = $4.node; // variable_declaration_block
            $$.node ->children[1] = $6.node; // program_body

            head = $$.node;
            print_tree(head);
            //printSymbolTable();
        }
        ;
variable_declaration_block : VAR variable_declaration_list {
    // Construct AST node for variable_declaration_block with declarations
        $$.node = create_node("variable_declaration_block", "", "", 1);
        $$.node ->children[0] = $2.node; // variable_declaration_list
}
| /* Empty */
{
    // Construct AST node for an empty variable_declaration_block
        $$.node = NULL;
}
;





variable_declaration_list : variable_declaration_list variable_declaration
{
    // Construct AST node for variable_declaration_list
    $$.node = create_node("variable_declaration_list", "", "", 2);
    $$.node ->children[0] = $1.node ; // variable_declaration_list
    $$.node ->children[1] = $2.node ; // variable_declaration
}
| variable_declaration
{
    // Construct AST node for single variable_declaration
    $$.node = create_node("variable_declaration_list", "","", 1);
    $$.node ->children[0] = $1.node; // variable_declaration
}
;

variable_declaration : IDENTIFIER_LIST COLON type SEMICOLON
{
    // Construct AST node for variable_declaration
    $$.node = create_node("variable_declaration", "","", 2);
    $$.node->children[0] = $1.node; // IDENTIFIER_LIST
    $$.node->children[1] = $3.node; // type
    // Perform semantic actions
    strcpy(current_type, $3.name);
    for(int i=0; i<var_count; i++){
        if(Identifiers[i].ye == 0){
            if(isDeclared(Identifiers[i].name) == 1){
                flag = 1;
                printf("multiple declarations of a variable: %s\n", Identifiers[i].name);
                Identifiers[i].ye = 2;
            }
            else{
                insertSymbol(Identifiers[i].line, Identifiers[i].name, current_type, "no");
                Identifiers[i].ye = 1;
            }
        }
    }
    strcpy($1.node->type, current_type);
    assignTypeToSubtree($1.node, current_type);
    //printSymbolTable();
}  
| IDENTIFIER_LIST COLON ARRAY_DECLARATION type SEMICOLON
{
    // Construct AST node for variable_declaration with ARRAY_DECLARATION
    $$.node = create_node("variable_declaration", "","", 3);
    $$.node->children[0] = $1.node; // IDENTIFIER_LIST
    $$.node->children[1] = $3.node; // ARRAY_DECLARATION
    $$.node->children[2] = $4.node; // type
    // Perform semantic actions
    strcpy(current_type, "Array of ");
    strcat(current_type, $4.name);
    for(int i=0; i<var_count; i++){
        if(Identifiers[i].ye == 0){
            if(isDeclared(Identifiers[i].name) == 1){
                flag = 1;
                printf("multiple declarations of a variable: %s\n", Identifiers[i].name);
                Identifiers[i].ye = 2;
            }
            else{
                insertSymbol(Identifiers[i].line, Identifiers[i].name, current_type, "no");
                Identifiers[i].ye = 1;
            }
        }
    }
    strcpy($1.node->type, current_type);
    assignTypeToSubtree($1.node, current_type);
    //printSymbolTable();
}
;


ARRAY_DECLARATION : ARRAY OSB NUMBER DOUBLEDOT NUMBER CSB OF
{
    // Construct AST node for ARRAY_DECLARATION
    $$.node = create_node("array_declaration", "","", 2);
    $$.node ->children[0] = create_node("NUMBER", "integer", $3.name, 1);
    ASTNode* identifier_node_580 = $$.node->children[0];
    identifier_node_580->children[0] = create_node($3.name, "", "", 0);
    
    $$.node ->children[1] = create_node("NUMBER", "integer", $5.name, 1);
    ASTNode* identifier_node_581 = $$.node->children[1];
    identifier_node_581->children[0] = create_node($5.name, "", "", 0); // Second number
}
;


IDENTIFIER_LIST : IDENTIFIER
{
    // Construct AST node for single identifier list
    $$.node = create_node("identifier_list", "","", 1);
    $$.node -> children[0] = create_node("IDENTIFIER", "", "", 1); // Single IDENTIFIER
    ASTNode* identifier_node_1 = $$.node->children[0];
    identifier_node_1->children[0] = create_node($1.name, "", "", 0);

    // Perform your functionality
    Identifiers[var_count].line = $1.line;
    strcpy(Identifiers[var_count].name, $1.name);
    Identifiers[var_count].ye = 0;
    ASTNode* identifier_node = $$.node->children[0];
    Identifiers[var_count].node_identifier = identifier_node;
    var_count++;
    
}
| IDENTIFIER_LIST COMMA IDENTIFIER
{
    // Construct AST node for identifier list with multiple identifiers
    $$.node = create_node("identifier_list", "","", 2);
    $$.node ->children[0] = $1.node; // Previous IDENTIFIER_LIST
    $$.node ->children[1] = create_node("IDENTIFIER", "", "", 1);
    ASTNode* identifier_node_2 = $$.node->children[1];
    identifier_node_2->children[0] = create_node($3.name, "", "", 0);// New IDENTIFIER

    // Perform your functionality
    Identifiers[var_count].line = $3.line;
    strcpy(Identifiers[var_count].name, $3.name);
    Identifiers[var_count].ye = 0;
    ASTNode* identifier_node = $$.node->children[1];
    Identifiers[var_count].node_identifier = identifier_node;
    var_count++;
}
;



IDENTIFIER_LIST_WRITE : IDENTIFIER
{
    // Construct AST node for single identifier
    $$.node = create_node("identifier_list_write", "","", 1);
    $$.node->children[0] = create_node("IDENTIFIER", "", "", 1);
    ASTNode* identifier_node_3 = $$.node->children[0];
    identifier_node_3->children[0] = create_node($1.name, "", "", 0);// Single IDENTIFIER

    // Perform your functionality
    if (!isDeclared($1.name)) {
        flag = 1;
        printUndeclaredError($1.name);
    }
    else if(getIdentifierDec($1.name)!=1){
        printf("variable: %s used before initializing\n", $1.name);
    }
}
| array_expression
{
    // Construct AST node for array_expression
    $$.node = create_node("identifier_list_write", "", "", 1);
    $$.node->children[0] = $1.node; // array_expression
}
| IDENTIFIER_LIST_WRITE COMMA IDENTIFIER
{
    // Construct AST node for identifier list with multiple identifiers
    $$.node = create_node("identifier_list_write", "", "", 2);
    $$.node->children[0] = $1.node; // Previous IDENTIFIER_LIST_WRITE
    $$.node->children[1] = create_node("IDENTIFIER", "", "", 1);
    ASTNode* identifier_node_4 = $$.node->children[1];
    identifier_node_4->children[1] = create_node($3.name, "", "", 0);

    // Perform your functionality
    if (!isDeclared($3.name)) {
        flag = 1;
        printUndeclaredError($3.name);
    }else if(getIdentifierDec($3.name)!=1){
        printf("variable: %s used before initializing\n", $3.name);
    }
}
| IDENTIFIER_LIST_WRITE COMMA array_expression
{
    // Construct AST node for identifier list with array_expression
    $$.node = create_node("identifier_list_write", "", "", 2);
    $$.node->children[0] = $1.node; // Previous IDENTIFIER_LIST_WRITE
    $$.node->children[1] = $3.node; // array_expression
}
;



type : INTEGER
{
    // Construct AST node for type INTEGER
    $$.node = create_node("INTEGER", "integer", "", 0);
}
| REAL
{
    $$.node = create_node("REAL", "real", "", 0);
}
| BOOLEAN
{
    $$.node = create_node("BOOLEAN", "boolean", "", 0);
}
| CHAR
{
    $$.node = create_node("CHAR", "char", "", 0);
}
;

NUMERIC: NUMBER
{
    // Construct AST node for NUMERIC NUMBER
    $$.node = create_node("NUMBER", "integer", $1.name, 1);
    ASTNode* identifier_node_589 = $$.node;
    identifier_node_589->children[0] = create_node($1.name, "", "", 0);
    $1.itsint = 1;
    $1.itschar=0;
    $1.itsreal=0;
    $1.itsbool=0;
    $$.itsint = $1.itsint;
    $$.itschar = $1.itschar;
    $$.itsreal = $1.itsreal;
    $$.itsbool = $1.itsbool;
    
}
| REAL_L
{
    $$.node = create_node("REAL", "real", $1.name, 1);
    ASTNode* identifier_node_521 = $$.node;
    identifier_node_521->children[0] = create_node($1.name, "", "", 0);
    $1.itsint = 0;
    $1.itschar=0;
    $1.itsreal=1;
    $1.itsbool=0;
    $$.itsint = $1.itsint;
    $$.itschar = $1.itschar;
    $$.itsreal = $1.itsreal;
    $$.itsbool = $1.itsbool;
}
| CHAR_L
{
    $$.node = create_node("CHARACTER", "char", $1.name, 1);
    ASTNode* identifier_node_533 = $$.node;
    identifier_node_533->children[0] = create_node($1.name, "", "", 0);
    $1.itsint = 0;
    $1.itschar=1;
    $1.itsreal=0;
    $1.itsbool=0;
    $$.itsint = $1.itsint;
    $$.itschar = $1.itschar;
    $$.itsreal = $1.itsreal;
    $$.itsbool = $1.itsbool;
}
;

        
program_body : statement_or_block_list
{
    // Construct AST node for program_body
    $$.node = create_node("program_body", "","", 1);
    $$.node->children[0] = $1.node; // statement_or_block_list
}
| /* Empty */
{
    // Construct AST node for empty program_body
    $$.node = NULL;
}
;

statement_or_block_list : statement_or_block_list statement_or_block
{
    // Construct AST node for statement_or_block_list with additional statement_or_block
    $$.node = create_node("statement_or_block_list", "","", 2);
    $$.node->children[0] = $1.node; // statement_or_block_list
    $$.node->children[1] = $2.node; // statement_or_block
}
| statement_or_block
{
    // Construct AST node for statement_or_block_list with single statement_or_block
    $$.node = create_node("statement_or_block_list", "","", 1);
    $$.node->children[0] = $1.node; // statement_or_block
}
;

statement_or_block : statement
{
    // Construct AST node for statement_or_block with single statement
    $$.node = create_node("statement_or_block", "", "", 1);
    $$.node->children[0] = $1.node; // statement
}
| statement_block
{
    // Construct AST node for statement_or_block with statement block
    $$.node = $1.node; // statement_block
}
;

statement_block : BEGINI statement_list END SEMICOLON
{
    // Construct AST node for statement_block
    $$.node = create_node("statement_block", "", "", 1);
    $$.node->children[0] = $2.node; // statement_list
}
;

statement_block_else : BEGINI statement_list END
{
    // Construct AST node for statement_block_else
    $$.node = create_node("statement_block_else", "", "", 1);
    $$.node->children[0] = $2.node; // statement_list
}
;

statement_list : statement_list statement
{
    // Construct AST node for statement_list with additional statement
    $$.node = create_node("statement_list", "", "", 2);
    $$.node->children[0] = $1.node; // statement_list
    $$.node->children[1] = $2.node; // statement
}
| statement
{
    // Construct AST node for statement_list with single statement
    $$.node = create_node("statement_list", "", "", 1);
    $$.node->children[0] = $1.node; // statement
}
;

statement : assignment_statement
{
    // Construct AST node for assignment_statement
    $$.node = create_node("statement", "", "", 1);
    $$.node->children[0] = $1.node; // assignment_statement
}
| conditional_statement
{
    // Construct AST node for conditional_statement
    $$.node = create_node("statement", "", "", 1);
    $$.node->children[0] = $1.node;  // conditional_statement
}
| loop_statement
{
    // Construct AST node for loop_statement
    $$.node = create_node("statement", "", "", 1);
    $$.node->children[0] = $1.node;  // loop_statement
}
| read_statement
{
    // Construct AST node for read_statement
    $$.node = create_node("statement", "", "", 1);
    $$.node->children[0] = $1.node;  // read_statement
}
| write_statement
{
    // Construct AST node for write_statement
    $$.node = create_node("statement", "", "", 1);
    $$.node->children[0] = $1.node;  // write_statement
}
;

expression : arithmetic_expression
{
    // Construct AST node for expression
    $$.node = create_node("expression", "", "", 1);
    $$.node->children[0] = $1.node;  // arithmetic_expression
    $$.itsint = $1.itsint;
    $$.itschar = $1.itschar;
    $$.itsreal = $1.itsreal;
    $$.itsbool = $1.itsbool;

}
;


array_expression : IDENTIFIER OSB NUMBER CSB
{
    // Construct AST node for array_expression with constant number index
    $$.node = create_node("array_expression", "", "", 2);
    $$.node->children[0] = create_node("IDENTIFIER", "","", 1);// Array identifier
    ASTNode* identifier_node_5 = $$.node->children[0];
    identifier_node_5->children[0] = create_node($1.name, "", "", 0);
    $$.node->children[1] = create_node("NUMBER", "integer", $3.name, 1); // Constant number index
    ASTNode* identifier_node_54 = $$.node->children[1];
    identifier_node_54->children[0] = create_node($3.name, "", "", 0);

    // Check if array identifier is declared
    if (!isDeclared($1.name)) {
        flag = 1;
        printUndeclaredError($1.name);
    }
    else{
        char* typer = getTypeFromSymbolTable($1.name);
        char* h = strdup(typer);
        if (caseInsensitiveCompare("integer", h)) {
    $1.itsint = 1;
    $1.itsbool = 0;
    $1.itschar = 0;
    $1.itsreal = 0;
} else if (caseInsensitiveCompare("boolean", h)) {
    $1.itsint = 0;
    $1.itsbool = 1;
    $1.itschar = 0;
    $1.itsreal = 0;
} else if (caseInsensitiveCompare("char", h)) {
    $1.itsint = 0;
    $1.itsbool = 0;
    $1.itschar = 1;
    $1.itsreal = 0;
} else if (caseInsensitiveCompare("real", h)) {
    $1.itsint = 0;
    $1.itsbool = 0;
    $1.itschar = 0;
    $1.itsreal = 1;
}
else{
    $1.itsint=0;
    $1.itschar=0;
    $1.itsreal=0;
    $1.itsbool=0;
}
    $$.itsint = $1.itsint;
    $$.itsbool = $1.itsbool;
    $$.itschar = $1.itschar;
    $$.itsreal = $1.itsreal;
    strcpy($$.name , $1.name);
    }
}
|IDENTIFIER OSB IDENTIFIER CSB
{
    // Construct AST node for array_expression with identifier index
    $$.node = create_node("array_expression", "", "", 2);
    $$.node->children[0] = create_node("IDENTIFIER", "", "", 1);
    ASTNode* identifier_node_7 = $$.node->children[0];
    identifier_node_7->children[0] = create_node($1.name, "", "", 0);// Array identifier
    $$.node->children[1] = create_node("IDENTIFIER_INDEX", "","", 1);
    ASTNode* identifier_node_8 = $$.node->children[1];
    identifier_node_8->children[0] = create_node($3.name, "", "", 0);// Identifier index

    // Check if array identifier and index identifier are declared
    if (!isDeclared($1.name)) {
        flag = 1;
        printUndeclaredError($1.name);
    }
    else{
        char* typer = getTypeFromSymbolTable($1.name);
        char* h = strdup(typer);
        if (caseInsensitiveCompare("integer", h)) {
    $1.itsint = 1;
    $1.itsbool = 0;
    $1.itschar = 0;
    $1.itsreal = 0;
} else if (caseInsensitiveCompare("boolean", h)) {
    $1.itsint = 0;
    $1.itsbool = 1;
    $1.itschar = 0;
    $1.itsreal = 0;
} else if (caseInsensitiveCompare("char", h)) {
    $1.itsint = 0;
    $1.itsbool = 0;
    $1.itschar = 1;
    $1.itsreal = 0;
} else if (caseInsensitiveCompare("real", h)) {
    $1.itsint = 0;
    $1.itsbool = 0;
    $1.itschar = 0;
    $1.itsreal = 1;
}else{
    $1.itsint=0;
    $1.itschar=0;
    $1.itsreal=0;
    $1.itsbool=0;
}
    $$.itsint = $1.itsint;
    $$.itsbool = $1.itsbool;
    $$.itschar = $1.itschar;
    $$.itsreal = $1.itsreal;
    strcpy($$.name , $1.name);
    
    if (!isDeclared($3.name)) {
        flag = 1;
        printUndeclaredError($3.name);
    }
    else if(getIdentifierDec($3.name)!= 1){
         printf("variable: %s used before initializing\n", $3.name);
    }
  }  
}
| IDENTIFIER OSB array_expression CSB
{
    // Construct AST node for array_expression with nested array_expression index
    $$.node = create_node("array_expression", "", "", 2);
    $$.node->children[0] = create_node("IDENTIFIER", "", "", 1); // Array identifier
    ASTNode* identifier_node_9 = $$.node->children[0];
    identifier_node_9->children[0] = create_node($1.name, "", "", 0);
    $$.node->children[1] = $3.node; // Nested array_expression

    // Check if array identifier is declared
    if (!isDeclared($1.name)) {
        flag = 1;
        printUndeclaredError($1.name);
    }
    else{
    char* typer = getTypeFromSymbolTable($1.name);
            char* h = strdup(typer);
            if (caseInsensitiveCompare("integer", h)) {
        $1.itsint = 1;
        $1.itsbool = 0;
        $1.itschar = 0;
        $1.itsreal = 0;
    } else if (caseInsensitiveCompare("boolean", h)) {
        $1.itsint = 0;
        $1.itsbool = 1;
        $1.itschar = 0;
        $1.itsreal = 0;
    } else if (caseInsensitiveCompare("char", h)) {
        $1.itsint = 0;
        $1.itsbool = 0;
        $1.itschar = 1;
        $1.itsreal = 0;
    } else if (caseInsensitiveCompare("real", h)) {
        $1.itsint = 0;
        $1.itsbool = 0;
        $1.itschar = 0;
        $1.itsreal = 1;
    }else{
    $1.itsint=0;
    $1.itschar=0;
    $1.itsreal=0;
    $1.itsbool=0;
}
        $$.itsint = $1.itsint;
        $$.itsbool = $1.itsbool;
        $$.itschar = $1.itschar;
        $$.itsreal = $1.itsreal;
        strcpy($$.name , $1.name);
    }
}
;

arithmetic_expression : IDENTIFIER
{
    // Construct AST node for arithmetic_expression with identifier
    $$.node = create_node("arithmetic_expression", "", "", 1);
    $$.node->children[0] = create_node("IDENTIFIER", "", "", 1); // Identifier node
    ASTNode* identifier_node_10 = $$.node->children[0];
    identifier_node_10->children[0] = create_node($1.name, "", "", 0);
    //printf("%s", $1.name);
    // Check if identifier is declared
    if (!isDeclared($1.name)) {
        flag = 1;
        printUndeclaredError($1.name);
    }
    else{
        if(getIdentifierDec($1.name)!=1){
            printf("variable: %s used before initializing\n", $1.name);
        }
        char* typer = getTypeFromSymbolTable($1.name);
        char* h = strdup(typer);
        if (caseInsensitiveCompare("integer", h)) {
    $1.itsint = 1;
    $1.itsbool = 0;
    $1.itschar = 0;
    $1.itsreal = 0;
} else if (caseInsensitiveCompare("boolean", h)) {
    $1.itsint = 0;
    $1.itsbool = 1;
    $1.itschar = 0;
    $1.itsreal = 0;
} else if (caseInsensitiveCompare("char", h)) {
    $1.itsint = 0;
    $1.itsbool = 0;
    $1.itschar = 1;
    $1.itsreal = 0;
} else if (caseInsensitiveCompare("real", h)) {
    $1.itsint = 0;
    $1.itsbool = 0;
    $1.itschar = 0;
    $1.itsreal = 1;
}
    $$.itsint = $1.itsint;
    $$.itsbool = $1.itsbool;
    $$.itschar = $1.itschar;
    $$.itsreal = $1.itsreal;
        
    }
}
| NUMERIC
{
    // Construct AST node for arithmetic_expression with numeric value
    $$.node = create_node("arithmetic_expression", "", "", 1);
    $$.node->children[0] = $1.node; // Numeric value node
    $$.itsint = $1.itsint;
    $$.itsbool = $1.itsbool;
    $$.itschar = $1.itschar;
    $$.itsreal = $1.itsreal;
 
}
| array_expression
{
    // Construct AST node for arithmetic_expression with array expression
    $$.node = create_node("arithmetic_expression", "", "", 2);
    $$.node->children[0] = $1.node; // Array expression node
    $$.itsint = $1.itsint;
    $$.itsbool = $1.itsbool;
    $$.itschar = $1.itschar;
    $$.itsreal = $1.itsreal;
   
}
| arithmetic_expression PLUS arithmetic_expression
{
    $$.node = create_node("arithmetic_expression", "", "", 3);
    $$.node->children[0] = $1.node; // Left operand
    $$.node->children[1] = create_node("+", "", "", 0);
    $$.node->children[2] = $3.node; // Right operand
    if ($1.itsreal || $3.itsreal) {
    // If either operand is real, set itsreal flag to 1
    $$.itsint = 0;
    $$.itsbool = 0;
    $$.itschar = 0;
    $$.itsreal = 1;
} else {
    $$.itsint = $1.itsint;
    $$.itsbool = $1.itsbool;
    $$.itschar = $1.itschar;
    $$.itsreal = $1.itsreal;
}
    if($1.itsint!= $3.itsint || $1.itsreal!= $3.itsreal || $1.itsbool!= $3.itsbool || $1.itschar!= $3.itschar){
    if(!(($1.itsreal==1  &&   $3.itsint==1) || ($1.itsint==1 && $3.itsreal==1))){
          char* type;
          if ($3.itsint == 1) {
              type = strdup("integer");
          } else if ($3.itsreal == 1) {
              type = strdup("real");
          } else if ($3.itsbool == 1) {
              type = strdup("boolean");
          } else if ($3.itschar == 1) {
              type = strdup("char");
          }
          char* type2;
          if ($1.itsint == 1) {
              type2 = strdup("integer");
          } else if ($1.itsreal == 1) {
              type2 = strdup("real");
          } else if ($1.itsbool == 1) {
              type2 = strdup("boolean");
          } else if ($1.itschar == 1) {
              type2 = strdup("char");
          }

          printf("a %s type is added to a %s type\n", type, type2);
}
}
}
| arithmetic_expression MINUS arithmetic_expression
{
    $$.node = create_node("arithmetic_expression", "", "", 3);
    $$.node->children[0] = $1.node; // Left operand
    $$.node->children[1] = create_node("-", "", "", 0);
    $$.node->children[2] = $3.node; // Right operand
    $$.itsint = $1.itsint;
    $$.itsbool = $1.itsbool;
    $$.itschar = $1.itschar;
    $$.itsreal = $1.itsreal;
    if ($1.itsreal || $3.itsreal) {
        // If either operand is real, set itsreal flag to 1
        $$.itsint = 0;
        $$.itsbool = 0;
        $$.itschar = 0;
        $$.itsreal = 1;
    } else {
        $$.itsint = $1.itsint;
        $$.itsbool = $1.itsbool;
        $$.itschar = $1.itschar;
        $$.itsreal = $1.itsreal;
    }
    if($1.itsint!= $3.itsint || $1.itsreal!= $3.itsreal || $1.itsbool!= $3.itsbool || $1.itschar!= $3.itschar){
    if(!(($1.itsreal==1  &&   $3.itsint==1) || ($1.itsint==1 && $3.itsreal==1))){
          char* type;
          if ($3.itsint == 1) {
              type = strdup("integer");
          } else if ($3.itsreal == 1) {
              type = strdup("real");
          } else if ($3.itsbool == 1) {
              type = strdup("boolean");
          } else if ($3.itschar == 1) {
              type = strdup("char");
          }
          char* type2;
          if ($1.itsint == 1) {
              type2 = strdup("integer");
          } else if ($1.itsreal == 1) {
              type2 = strdup("real");
          } else if ($1.itsbool == 1) {
              type2 = strdup("boolean");
          } else if ($1.itschar == 1) {
              type2 = strdup("char");
          }

          printf("a %s type is subtracted from a %s type\n", type, type2);
}
}
}
| arithmetic_expression MUL arithmetic_expression
{
    $$.node = create_node("arithmetic_expression", "", "", 3);
    $$.node->children[0] = $1.node; // Left operand
    $$.node->children[1] = create_node("*", "", "", 0);
    $$.node->children[2] = $3.node; // Right operand
    if ($1.itsreal || $3.itsreal) {
        // If either operand is real, set itsreal flag to 1
        $$.itsint = 0;
        $$.itsbool = 0;
        $$.itschar = 0;
        $$.itsreal = 1;
    } else {
        $$.itsint = $1.itsint;
        $$.itsbool = $1.itsbool;
        $$.itschar = $1.itschar;
        $$.itsreal = $1.itsreal;
    }
    if($1.itsint!= $3.itsint || $1.itsreal!= $3.itsreal || $1.itsbool!= $3.itsbool || $1.itschar!= $3.itschar){
    if(!(($1.itsreal==1  &&   $3.itsint==1) || ($1.itsint==1 && $3.itsreal==1))){
          char* type;
          if ($3.itsint == 1) {
              type = strdup("integer");
          } else if ($3.itsreal == 1) {
              type = strdup("real");
          } else if ($3.itsbool == 1) {
              type = strdup("boolean");
          } else if ($3.itschar == 1) {
              type = strdup("char");
          }
          char* type2;
          if ($1.itsint == 1) {
              type2 = strdup("integer");
          } else if ($1.itsreal == 1) {
              type2 = strdup("real");
          } else if ($1.itsbool == 1) {
              type2 = strdup("boolean");
          } else if ($1.itschar == 1) {
              type2 = strdup("char");
          }

          printf("a %s type is multiplied by a %s type\n", type, type2);
}
}
}
| arithmetic_expression DIVIDE arithmetic_expression
{
    $$.node = create_node("arithmetic_expression", "", "", 3);
    $$.node->children[0] = $1.node; // Left operand
    $$.node->children[1] = create_node("/", "", "", 0);
    $$.node->children[2] = $3.node; // Right operand
    if ($1.itsreal || $3.itsreal) {
        // If either operand is real, set itsreal flag to 1
        $$.itsint = 0;
        $$.itsbool = 0;
        $$.itschar = 0;
        $$.itsreal = 1;
    } else {
        $$.itsint = $1.itsint;
        $$.itsbool = $1.itsbool;
        $$.itschar = $1.itschar;
        $$.itsreal = $1.itsreal;
    }
    if($1.itsint!= $3.itsint || $1.itsreal!= $3.itsreal || $1.itsbool!= $3.itsbool || $1.itschar!= $3.itschar){
    if(!(($1.itsreal==1  &&   $3.itsint==1) || ($1.itsint==1 && $3.itsreal==1))){
          char* type;
          if ($3.itsint == 1) {
              type = strdup("integer");
          } else if ($3.itsreal == 1) {
              type = strdup("real");
          } else if ($3.itsbool == 1) {
              type = strdup("boolean");
          } else if ($3.itschar == 1) {
              type = strdup("char");
          }
          char* type2;
          if ($1.itsint == 1) {
              type2 = strdup("integer");
          } else if ($1.itsreal == 1) {
              type2 = strdup("real");
          } else if ($1.itsbool == 1) {
              type2 = strdup("boolean");
          } else if ($1.itschar == 1) {
              type2 = strdup("char");
          }

          printf("a %s type is divided by a %s type\n", type, type2);
        }  
      }  
}
| arithmetic_expression MOD arithmetic_expression
{
    $$.node = create_node("arithmetic_expression", "", "", 3);
    $$.node->children[0] = $1.node; // Left operand
    $$.node->children[1] = create_node("%", "", "", 0);
    $$.node->children[2] = $3.node; // Right operand
    if ($1.itsreal || $3.itsreal) {
        // If either operand is real, set itsreal flag to 1
        $$.itsint = 0;
        $$.itsbool = 0;
        $$.itschar = 0;
        $$.itsreal = 1;
    } else {
        $$.itsint = $1.itsint;
        $$.itsbool = $1.itsbool;
        $$.itschar = $1.itschar;
        $$.itsreal = $1.itsreal;
    }
    if($1.itsint!= $3.itsint || $1.itsreal!= $3.itsreal || $1.itsbool!= $3.itsbool || $1.itschar!= $3.itschar){
    if(!(($1.itsreal==1  &&   $3.itsint==1))){
          char* type;
          if ($3.itsint == 1) {
              type = strdup("integer");
          } else if ($3.itsreal == 1) {
              type = strdup("real");
          } else if ($3.itsbool == 1) {
              type = strdup("boolean");
          } else if ($3.itschar == 1) {
              type = strdup("char");
          }
          char* type2;
          if ($1.itsint == 1) {
              type2 = strdup("integer");
          } else if ($1.itsreal == 1) {
              type2 = strdup("real");
          } else if ($1.itsbool == 1) {
              type2 = strdup("boolean");
          } else if ($1.itschar == 1) {
              type2 = strdup("char");
          }

          printf("a %s type is divided by a %s variable to get remainder\n", type, type2);
}
}
else if($1.itsreal==1 || $3.itsreal==1){
      printf("usage of modulus operator with real values is not permitted");
}

}
| OB arithmetic_expression CB
{
    $$.node = $2.node;
        $$.itsint = $2.itsint;
        $$.itsbool = $2.itsbool;
        $$.itschar = $2.itschar;
        $$.itsreal = $2.itsreal;
}
;


boolean_expression : relational_expression
{
    // Construct AST node for relational_expression
    $$.node  = create_node("boolean_expression", "", "", 1);
    $$.node->children[0] = $1.node; // relational_expression node
}
| IDENTIFIER
{
    // Construct AST node for identifier
    $$.node  = create_node("boolean_expression", "", "", 1);
    $$.node->children[0] = create_node("IDENTIFIER", "","", 1);// Identifier node
    ASTNode* identifier_node_11 = $$.node->children[0];
    identifier_node_11->children[0] = create_node($1.name, "", "", 0);

    // Check if identifier is declared
    if (!isDeclared($1.name)) {
        flag = 1;
        printUndeclaredError($1.name);
    }else if(getIdentifierDec($1.name)!=1){
        printf("variable: %s used before initializing\n", $1.name);
    }
}
| boolean_expression AND boolean_expression
{
    // Construct AST node for AND operator
    $$.node  = create_node("boolean_expression", "", "", 3);
    $$.node->children[0] = $1.node; // Left operand
    $$.node->children[1] = create_node("AND", "", "", 0);
    $$.node->children[2] = $3.node; // Right operand
}
| boolean_expression OR boolean_expression
{
    $$.node  = create_node("boolean_expression", "", "", 3);
    $$.node->children[0] = $1.node; // Left operand
    $$.node->children[1] = create_node("OR", "", "", 0);
    $$.node->children[2] = $3.node; // Right operand
}
| NOT boolean_expression %prec NOT
{
    $$.node = create_node("boolean_expression", "", "", 2);
    $$.node->children[0] = create_node("NOT", "", "", 0); // Operand
    $$.node->children[1] = $2.node; // Operand
}
;


relational_expression : arithmetic_expression EQ arithmetic_expression
{
    // Construct AST node for EQ (equal) relational expression
    $$.node = create_node("relational_expression", "","", 3);
    $$.node->children[0] = $1.node;
    $$.node->children[1] = create_node("=", "", "", 0);
    $$.node->children[2] = $3.node; // Right arithmetic expression
}
| arithmetic_expression NE arithmetic_expression
{
    $$.node = create_node("relational_expression", "","", 3);
    $$.node->children[0] = $1.node;
    $$.node->children[1] = create_node("<>", "", "", 0);
    $$.node->children[2] = $3.node; // Right arithmetic expression
}
| arithmetic_expression LT arithmetic_expression
{
    $$.node = create_node("relational_expression", "","", 3);
    $$.node->children[0] = $1.node;
    $$.node->children[1] = create_node("<", "", "", 0);
    $$.node->children[2] = $3.node; // Right arithmetic expression
}
| arithmetic_expression GT arithmetic_expression
{
    $$.node = create_node("relational_expression", "","", 3);
    $$.node->children[0] = $1.node;
    $$.node->children[1] = create_node(">", "", "", 0);
    $$.node->children[2] = $3.node; // Right arithmetic expression
}
| arithmetic_expression LE arithmetic_expression
{
    $$.node = create_node("relational_expression", "","", 3);
    $$.node->children[0] = $1.node;
    $$.node->children[1] = create_node("<=", "", "", 0);
    $$.node->children[2] = $3.node; // Right arithmetic expression
}
| arithmetic_expression GE arithmetic_expression
{
    $$.node = create_node("relational_expression", "","", 3);
    $$.node->children[0] = $1.node;
    $$.node->children[1] = create_node(">=", "", "", 0);
    $$.node->children[2] = $3.node; // Right arithmetic expression
}
| OB relational_expression CB
{
    $$.node = $2.node;
}
;

condition : boolean_expression
{
    // Construct AST node for condition
    $$.node = create_node("condition", "","", 1);
    $$.node->children[0] = $1.node; // boolean_expression node
}
;

conditional_statement : IF condition THEN statement_block
{
    // Construct AST node for conditional_statement without ELSE
    $$.node = create_node("conditional_statement", "","", 4);
    $$.node->children[0] = create_node("IF", "","", 0);
    $$.node->children[1] = $2.node; // condition node
    $$.node->children[2] = create_node("THEN", "","", 0);
    $$.node->children[3] = $4.node; // statement_block node
}
| IF condition THEN statement_block_else ELSE statement_block
{
    // Construct AST node for conditional_statement with ELSE
    $$.node = create_node("conditional_statement", "","", 6);
    $$.node->children[0] = create_node("IF", "","", 0);
    $$.node->children[1] = $2.node; // condition node
    $$.node->children[2] = create_node("THEN", "","", 0);
    $$.node->children[3] = $4.node; // statement_block_else node
    $$.node->children[4] = create_node("ELSE", "","", 0);
    $$.node->children[5] = $6.node;
}
;

assignment_statement : IDENTIFIER ASSIGN expression SEMICOLON
{
    $$.node = create_node("assignment_statement", "","", 3);
    $$.node->children[0] = create_node("IDENTIFIER", "", "", 1);
    ASTNode* identifier_node_12 = $$.node->children[0];
    identifier_node_12->children[0] = create_node($1.name, "", "", 0);
    $$.node->children[1] = create_node(":=", "", "", 0);// Identifier node
    $$.node->children[2] = $3.node; // expression 
    // Check if identifier is declared
    if (!isDeclared($1.name)) {
        flag = 1;
        printUndeclaredError($1.name);
    }
    else{
    setIdentifierDec($1.name);
    char* typer = getTypeFromSymbolTable($1.name);
            char* h = strdup(typer);
            if (caseInsensitiveCompare("integer", h)) {
        $1.itsint = 1;
        $1.itsbool = 0;
        $1.itschar = 0;
        $1.itsreal = 0;
    } else if (caseInsensitiveCompare("boolean", h)) {
        $1.itsint = 0;
        $1.itsbool = 1;
        $1.itschar = 0;
        $1.itsreal = 0;
    } else if (caseInsensitiveCompare("char", h)) {
        $1.itsint = 0;
        $1.itsbool = 0;
        $1.itschar = 1;
        $1.itsreal = 0;
    } else if (caseInsensitiveCompare("real", h)) {
        $1.itsint = 0;
        $1.itsbool = 0;
        $1.itschar = 0;
        $1.itsreal = 1;
    }
    else{
        $1.itsint=0;
        $1.itschar=0;
        $1.itsreal=0;
        $1.itsbool=0;
    }
    if($1.itsint!= $3.itsint || $1.itsreal!= $3.itsreal || $1.itsbool!= $3.itsbool || $1.itschar!= $3.itschar){
        if(!($1.itsreal==1  &&   $3.itsint==1)){
              char* type;
              if ($3.itsint == 1) {
                  type = strdup("integer");
              } else if ($3.itsreal == 1) {
                  type = strdup("real");
              } else if ($3.itsbool == 1) {
                  type = strdup("boolean");
              } else if ($3.itschar == 1) {
                  type = strdup("char");
              }
              char* type2;
              if ($1.itsint == 1) {
                  type2 = strdup("integer");
              } else if ($1.itsreal == 1) {
                  type2 = strdup("real");
              } else if ($1.itsbool == 1) {
                  type2 = strdup("boolean");
              } else if ($1.itschar == 1) {
                  type2 = strdup("char");
              }
              
              printf("a %s value is assigned to a %s variable: %s\n", type, type2, $1.name);
        }
    }
  }  
}
| array_expression ASSIGN expression SEMICOLON
{
    $$.node = create_node("assignment_statement", "","", 3);
    $$.node->children[0] = $1.node; // array_expression node
    $$.node->children[1] = create_node(":=", "", "", 0);
    $$.node->children[2] = $3.node; // expression node
    if($1.itsint!= $3.itsint || $1.itsreal!= $3.itsreal || $1.itsbool!= $3.itsbool || $1.itschar!= $3.itschar){
    if(!($1.itsreal==1  &&   $3.itsint==1)){
          char* type;
          if ($3.itsint == 1) {
              type = strdup("integer");
          } else if ($3.itsreal == 1) {
              type = strdup("real");
          } else if ($3.itsbool == 1) {
              type = strdup("boolean");
          } else if ($3.itschar == 1) {
              type = strdup("char");
          }
          char* type2;
          if ($1.itsint == 1) {
              type2 = strdup("integer");
          } else if ($1.itsreal == 1) {
              type2 = strdup("real");
          } else if ($1.itsbool == 1) {
              type2 = strdup("boolean");
          } else if ($1.itschar == 1) {
              type2 = strdup("char");
          }
          printf("a %s value is assigned to a %s variable: %s\n", type, type2, $1.name);
        }
      }  
}
;

loop_statement : WHILE condition DO statement_block
{
    // Construct AST node for while loop statement
    $$.node = create_node("WHILE", "", "", 2);
    $$.node->children[0] = $2.node; // condition node
    $$.node->children[1] = $4.node; // statement_block node
}
| FOR IDENTIFIER {
      if (!isDeclared($2.name)) {
          flag = 1;
          printUndeclaredError($2.name);
      }
      else if(strcmp(getTypeFromSymbolTable($2.name), "integer")!=0   && strcmp(getTypeFromSymbolTable($2.name), "real")!=0 ){
          printf("%s type variable: %s is used in for\n",getTypeFromSymbolTable($2.name), $2.name);
          setIdentifierDec($2.name);
      }
      else{
          setIdentifierDec($2.name);
      }
}ASSIGN expression direction expression DO statement_block
{
    // Construct AST node for for loop statement
    $$.node = create_node("FOR", "","", 7);
    $$.node->children[0]  = create_node("IDENTIFIER", "", "", 1);
    ASTNode* identifier_node_13 = $$.node->children[0];
    identifier_node_13->children[0] = create_node($2.name, "", "", 0);
    $$.node->children[1] = create_node(":=", "", "", 0);
    $$.node->children[2] = $4.node;
    $$.node->children[3] = $5.node;
    $$.node->children[4] = $6.node;
    $$.node->children[5] = create_node("DO", "", "", 0);
    $$.node->children[6] = $8.node;
    
}
;

direction : TO
{
    // Construct AST node for direction TO
    $$.node = create_node("TO", "", "", 0);
}
| DOWNTO
{
    // Construct AST node for direction DOWNTO
    $$.node = create_node("DOWNTO", "", "", 0);
}
;

read_statement : READ OB IDENTIFIER CB SEMICOLON
{
    // Construct AST node for read statement
    $$.node = create_node("read_statement", "","", 1);
    $$.node->children[0] = create_node("IDENTIFIER", "","", 1);
    ASTNode* identifier_node_15 = $$.node->children[0];
    identifier_node_15->children[0] = create_node($3.name, "", "", 0);// Identifier node

    // Check if identifier is declared
    if (!isDeclared($3.name)) {
        flag = 1;
        printUndeclaredError($3.name);
    }

}
| READ OB array_expression CB SEMICOLON
{
    // Construct AST node for read statement with array expression
    $$.node = create_node("read_statement", "","", 1);
    $$.node->children[0] = $3.node; // array_expression node
}
;

write_statement : WRITE OB write_argument_list CB SEMICOLON
{
    // Construct AST node for write statement
    $$.node = create_node("write_statement", "", "", 1);
    $$.node->children[0] = $3.node; // write_argument_list node
}
;

write_argument_list : STRING_LITERAL
{
    // Construct AST node for string literal
    $$.node = create_node("write_argument_list", "", "", 1);
    $$.node->children[0] = create_node($1.name, "","", 0); // String literal node
}
| IDENTIFIER_LIST_WRITE
{
    // Pass along the IDENTIFIER_LIST_WRITE node
    $$.node = $1.node;
}
;

%%

void yyerror(const char *s) {
    printf("syntax error\n");
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
