%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "y.tab.h"

extern FILE* yyin; 
int yyparse();

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

    //printf("%d  %s  %s\n", line_number, lexeme, tokenStrings[token]);
}

/* Extern declaration of yylineno */
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
"program"   { printToken(yylineno, KEYWORD, yytext); return PROGRAM; }
"integer"   { printToken(yylineno, KEYWORD, yytext); strcpy(yylval.obj.name,(yytext));
yylval.obj.line = yylineno;
return INTEGER; }
"real"      { printToken(yylineno, KEYWORD, yytext); strcpy(yylval.obj.name,(yytext));
yylval.obj.line = yylineno;
return REAL; }
"boolean"   { printToken(yylineno, KEYWORD, yytext); strcpy(yylval.obj.name,(yytext));
yylval.obj.line = yylineno;
return BOOLEAN; }
"char"      { printToken(yylineno, KEYWORD, yytext); strcpy(yylval.obj.name,(yytext));
yylval.obj.line = yylineno;
return CHAR; }
"var"       { printToken(yylineno, KEYWORD, yytext); return VAR; }
"to"        { printToken(yylineno, KEYWORD, yytext); return TO; }
"downto"    { printToken(yylineno, KEYWORD, yytext); return DOWNTO; }
"if"        { printToken(yylineno, KEYWORD, yytext); return IF; }
"else"      { printToken(yylineno, KEYWORD, yytext); return ELSE; }
"while"     { printToken(yylineno, KEYWORD, yytext); return WHILE; }
"for"       { printToken(yylineno, KEYWORD, yytext); return FOR; }
"do"        { printToken(yylineno, KEYWORD, yytext); return DO; }
"array"     { printToken(yylineno, KEYWORD, yytext); return ARRAY; }
"and"       { printToken(yylineno, KEYWORD, yytext); return AND; }
"or"        { printToken(yylineno, KEYWORD, yytext); return OR; }
"not"       { printToken(yylineno, KEYWORD, yytext); return NOT; }
"begin"     { printToken(yylineno, KEYWORD, yytext); return BEGINI; }
"end"       { printToken(yylineno, KEYWORD, yytext); return END; }
"read"      { printToken(yylineno, KEYWORD, yytext); return READ; }
"write"     { printToken(yylineno, KEYWORD, yytext); return WRITE; }
"writeln"     { printToken(yylineno, KEYWORD, yytext); return WRITE; }
"then"     { printToken(yylineno, KEYWORD, yytext); return THEN; }
"of"     { printToken(yylineno, KEYWORD, yytext); return OF; }

"("         { printToken(yylineno, PUNCTUATOR_H, yytext); return OB; }
")"         { printToken(yylineno, PUNCTUATOR_H, yytext); return CB; }
":"         { printToken(yylineno, PUNCTUATOR_H, yytext); return COLON; }
","         { printToken(yylineno, PUNCTUATOR_H, yytext); return COMMA; }
"\;"         { printToken(yylineno, PUNCTUATOR_H, yytext); return SEMICOLON;}
".."         { printToken(yylineno, PUNCTUATOR_H, yytext); return DOUBLEDOT;}
"."         { printToken(yylineno, PUNCTUATOR_H, yytext); return DOT; }
"["         { printToken(yylineno, PUNCTUATOR_H, yytext); return OSB; }
"]"         { printToken(yylineno, PUNCTUATOR_H, yytext); return CSB; }
"'"         { printToken(yylineno, PUNCTUATOR_H, yytext); return SINGLE; }
"\""        { printToken(yylineno, PUNCTUATOR_H, yytext); return DOUBLE;}
"\""([^"\n]|\\.)*"\"" { 
       printToken(yylineno, PUNCTUATOR_H, "\"");
       char* content = strdup(yytext + 1); 
       content[strlen(content) - 1] = '\0'; 
       printToken(yylineno, STRING_LITERAL_H, content); 
       strcpy(yylval.obj.name,(content));
       free(content); 
       printToken(yylineno, PUNCTUATOR_H, "\"");
       yylval.obj.line = yylineno;
       return STRING_LITERAL;
}

"+"         { printToken(yylineno, OPERATOR, yytext); return PLUS; }
"-"         { printToken(yylineno, OPERATOR, yytext); return MINUS; }
"*"         { printToken(yylineno, OPERATOR, yytext); return MUL; }
"/"         { printToken(yylineno, OPERATOR, yytext); return DIVIDE; }
"%"         { printToken(yylineno, OPERATOR, yytext); return MOD; }
"="         { printToken(yylineno, OPERATOR, yytext); return EQ; }
"<>"        { printToken(yylineno, OPERATOR, yytext); return NE; }
"<"         { printToken(yylineno, OPERATOR, yytext); return LT; }
">"         { printToken(yylineno, OPERATOR, yytext); return GT; }
"<="        { printToken(yylineno, OPERATOR, yytext); return LE; }
">="        { printToken(yylineno, OPERATOR, yytext); return GE; }
":="        { printToken(yylineno, PUNCTUATOR_H, ":");
              printToken(yylineno, OPERATOR, "=");
              return ASSIGN; }

{ID}        {
    // Convert yytext to lowercase for comparison
    char lowercaseText[1000];
    strcpy(lowercaseText, yytext);
    for (int i = 0; lowercaseText[i]; i++) {
        lowercaseText[i] = tolower(lowercaseText[i]);
    }
        if (strcmp(lowercaseText, "program") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return PROGRAM;
        } else if (strcmp(lowercaseText, "integer") == 0) {
            strcpy(yylval.obj.name,(yytext));
            yylval.obj.line = yylineno;
            printToken(yylineno, KEYWORD, yytext);
            return INTEGER;
        } else if (strcmp(lowercaseText, "real") == 0) {
            strcpy(yylval.obj.name,(yytext));
            yylval.obj.line = yylineno;
            printToken(yylineno, KEYWORD, yytext);
            return REAL;
        } else if (strcmp(lowercaseText, "boolean") == 0) {
            strcpy(yylval.obj.name,(yytext));
            yylval.obj.line = yylineno;
            printToken(yylineno, KEYWORD, yytext);
            return BOOLEAN;
        } else if (strcmp(lowercaseText, "char") == 0) {
            strcpy(yylval.obj.name,(yytext));
            yylval.obj.line = yylineno;
            printToken(yylineno, KEYWORD, yytext);
            return CHAR;
        } else if (strcmp(lowercaseText, "var") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return VAR;
        } else if (strcmp(lowercaseText, "to") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return TO;
        } else if (strcmp(lowercaseText, "downto") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return DOWNTO;
        } else if (strcmp(lowercaseText, "if") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return IF;
        } else if (strcmp(lowercaseText, "else") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return ELSE;
        } else if (strcmp(lowercaseText, "while") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return WHILE;
        } else if (strcmp(lowercaseText, "for") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return FOR;
        } else if (strcmp(lowercaseText, "do") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return DO;
        } else if (strcmp(lowercaseText, "array") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return ARRAY;
        } else if (strcmp(lowercaseText, "and") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return AND;
        } else if (strcmp(lowercaseText, "or") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return OR;
        } else if (strcmp(lowercaseText, "not") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return NOT;
        } else if (strcmp(lowercaseText, "begin") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return BEGINI;
        } else if (strcmp(lowercaseText, "end") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return END;
        } else if (strcmp(lowercaseText, "read") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return READ;
        } else if (strcmp(lowercaseText, "write") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return WRITE;
        } else if (strcmp(lowercaseText, "writeln") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return WRITE;
        } else if (strcmp(lowercaseText, "then") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return THEN;
        } else if (strcmp(lowercaseText, "of") == 0) {
            printToken(yylineno, KEYWORD, yytext);
            return OF;
        } else {
            printToken(yylineno, IDENTIFIER_H, yytext);
            strcpy(yylval.obj.name,(yytext));
            yylval.obj.line = yylineno;
            return IDENTIFIER;
        }
    }

[0-9]+      { printToken(yylineno, NUMBER_H, yytext);         
              strcpy(yylval.obj.name,(yytext));
              yylval.obj.line = yylineno;
              return NUMBER; }

[0-9]*\.[0-9]+([eE][-+]?[0-9]+)? {
    printToken(yylineno, REAL_H, yytext);
    strcpy(yylval.obj.name, yytext);
    yylval.obj.line = yylineno;
    return REAL_L; 
}

[0-9]+([eE][-+]?[0-9]+)   {
    printToken(yylineno, REAL_H, yytext);
    strcpy(yylval.obj.name, yytext);
    yylval.obj.line = yylineno;
    return REAL_L; 
}

'.'            { 
    yylval.obj.name[0] = yytext[1]; 
    yylval.obj.name[1] = '\0'; 
    printToken(yylineno, PUNCTUATOR_H, "'");
    printToken(yylineno, CHAR_H, yylval.obj.name);
    printToken(yylineno, PUNCTUATOR_H, "'");
    yylval.obj.line = yylineno;
    return CHAR_L; 
}



\n          {yylineno++; }

[ \t]+      ; /* Skip whitespace */

.           { return INVALID_TOKEN; }

%%







