To compile & run the program for task 3 - 

yacc -d sssh2512.y
lex sssh2512.l
cc y.tab.c lex.yy.c -lm
./a.out input.txt
python tree.py

For task 4 - 

yacc -d sssh2512.y
lex sssh2512.l
cc y.tab.c lex.yy.c -lm
./a.out input.txt

The inputs are contained in the file input.txt
