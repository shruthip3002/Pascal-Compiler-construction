To compile & run the program for task 1 - 

lex sssh2512.l
gcc lex.yy.c -lm
./a.out input.txt

For task 2 - 

yacc -d sssh2512.y
lex sssh2512.l
cc y.tab.c lex.yy.c -lm
./a.out input.txt

The inputs are contained in the file input.txt
