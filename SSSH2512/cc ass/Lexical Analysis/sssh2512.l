%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

extern FILE* yyin; 

#define KEYWORD 1
#define IDENTIFIER_H 2
#define OPERATOR 3
#define NUMBER_H 4
#define PUNCTUATOR_H 5
#define COMMENT_H 6
#define STRING_LITERAL_H 7
#define REAL_H 8
#define CHAR_H 9


void printToken(int line_number, int token, char* lexeme) {
    char* tokenStrings[] = {
        "Invalid Token",
        "Keyword",
        "Identifier",
        "Operator",
        "Number",
        "Punctuator",
        "Comment",
        "String",
        "Real",
        "Char"
    };

    printf("%d  %s  %s\n", line_number, lexeme, tokenStrings[token]);
}

extern int yylineno;
extern char* yytext;

%}

%option noyywrap

/* Regular Definitions section */
DIGIT       [0-9]
LETTER      [a-zA-Z]
UNDERSCORE  _
ID          {LETTER}({LETTER}|{DIGIT}|{UNDERSCORE})*

%%

"//"(.*)    { printToken(yylineno, COMMENT_H, yytext);}
"program"   { printToken(yylineno, KEYWORD, yytext); }
"integer"   { printToken(yylineno, KEYWORD, yytext); }
"real"      { printToken(yylineno, KEYWORD, yytext); }
"boolean"   { printToken(yylineno, KEYWORD, yytext); }
"char"      { printToken(yylineno, KEYWORD, yytext); }
"var"       { printToken(yylineno, KEYWORD, yytext); }
"to"        { printToken(yylineno, KEYWORD, yytext); }
"downto"    { printToken(yylineno, KEYWORD, yytext); }
"if"        { printToken(yylineno, KEYWORD, yytext); }
"else"      { printToken(yylineno, KEYWORD, yytext); }
"while"     { printToken(yylineno, KEYWORD, yytext); }
"for"       { printToken(yylineno, KEYWORD, yytext); }
"do"        { printToken(yylineno, KEYWORD, yytext); }
"array"     { printToken(yylineno, KEYWORD, yytext); }
"and"       { printToken(yylineno, KEYWORD, yytext); }
"or"        { printToken(yylineno, KEYWORD, yytext); }
"not"       { printToken(yylineno, KEYWORD, yytext); }
"begin"     { printToken(yylineno, KEYWORD, yytext); }
"end"       { printToken(yylineno, KEYWORD, yytext); }
"read"      { printToken(yylineno, KEYWORD, yytext); }
"write"     { printToken(yylineno, KEYWORD, yytext); }
"writeln"    { printToken(yylineno, KEYWORD, yytext); }
"then"     { printToken(yylineno, KEYWORD, yytext); }
"of"     { printToken(yylineno, KEYWORD, yytext); }

"("         { printToken(yylineno, PUNCTUATOR_H, yytext); }
")"         { printToken(yylineno, PUNCTUATOR_H, yytext); }
":"         { printToken(yylineno, PUNCTUATOR_H, yytext); }
","         { printToken(yylineno, PUNCTUATOR_H, yytext); }
"\;"         { printToken(yylineno, PUNCTUATOR_H, yytext); }
".."         { printToken(yylineno, PUNCTUATOR_H, ".");
               printToken(yylineno, PUNCTUATOR_H, ".");}               
"."         { printToken(yylineno, PUNCTUATOR_H, yytext); }
"["         { printToken(yylineno, PUNCTUATOR_H, yytext); }
"]"         { printToken(yylineno, PUNCTUATOR_H, yytext); }
"'"         { printToken(yylineno, PUNCTUATOR_H, yytext); }
"\""        { printToken(yylineno, PUNCTUATOR_H, yytext); }
"\""([^"\n]|\\.)*"\"" { 
       printToken(yylineno, PUNCTUATOR_H, "\"");
       char* content = strdup(yytext + 1); 
       content[strlen(content) - 1] = '\0'; 
       printToken(yylineno, STRING_LITERAL_H, content); 
       free(content); 
       printToken(yylineno, PUNCTUATOR_H, "\"");
}

"+"         { printToken(yylineno, OPERATOR, yytext); }
"-"         { printToken(yylineno, OPERATOR, yytext); }
"*"         { printToken(yylineno, OPERATOR, yytext); }
"/"         { printToken(yylineno, OPERATOR, yytext); }
"%"         { printToken(yylineno, OPERATOR, yytext); }
"="         { printToken(yylineno, OPERATOR, yytext); }
"<>"        { printToken(yylineno, OPERATOR, yytext); }
"<"         { printToken(yylineno, OPERATOR, yytext); }
">"         { printToken(yylineno, OPERATOR, yytext); }
"<="        { printToken(yylineno, OPERATOR, yytext); }
">="        { printToken(yylineno, OPERATOR, yytext); }
":="        { printToken(yylineno, OPERATOR, yytext); }

{ID}        {
    char lowercaseText[1000];
    strcpy(lowercaseText, yytext);
    for (int i = 0; lowercaseText[i]; i++) {
        lowercaseText[i] = tolower(lowercaseText[i]);
    }
        if (strcmp(lowercaseText, "program") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "integer") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "real") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "boolean") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "char") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "var") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "to") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "downto") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "if") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "else") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "while") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "for") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "do") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "array") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "and") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "or") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "not") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "begin") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "end") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "read") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "write") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        }else if (strcmp(lowercaseText, "writeln") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "then") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else if (strcmp(lowercaseText, "of") == 0) {
            printToken(yylineno, KEYWORD, yytext);
        } else {
            printToken(yylineno, IDENTIFIER_H, yytext);
        }
}

[0-9]+      { printToken(yylineno, NUMBER_H, yytext); }

[0-9]*\.[0-9]+([eE][-+]?[0-9]+)? {
    printToken(yylineno, REAL_H, yytext);
}

[0-9]+([eE][-+]?[0-9]+)   {
    printToken(yylineno, REAL_H, yytext);
}

'.'            { 
    printToken(yylineno, PUNCTUATOR_H, "'");
    char* content = strdup(yytext + 1); 
    content[strlen(content) - 1] = '\0'; 
    printToken(yylineno, CHAR_H, content);
    printToken(yylineno, PUNCTUATOR_H, "'");
}

\n          {yylineno++; }

[ \t]+      ; /* Skip whitespace */

.           { printf("%d  Invalid token: %s\n", yylineno, yytext); }

%%

int main(int argc, char** argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    FILE* inputFile = fopen(argv[1], "r");
    if (!inputFile) {
        perror("Error opening input file");
        return 1;
    }

    yyin = inputFile;
    yylex();
    fclose(inputFile);
    return 0;
}
