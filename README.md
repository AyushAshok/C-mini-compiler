# C-mini-compiler

## Prerequisites:
1) Flex
2) Bison </br>
Link to get the latest versions:- https://github.com/lexxmark/winflexbison/releases
## Steps to run:
Name your lexer as lexer.l and parser as parser.y
1) Run flex lexer.l . This creates a lex.yy.c file
2) Run bison -d parser.y . This creates the parser.tab.c and parser.tab.h files.
3) Run gcc lex.yy.c parser.tab.c -o a  . This creates an executable file a.exe .
   
5) ### If using Windows use:-
     Get-Content input.c | .\a.exe
   </br>
   ### If using Linux/Ubuntu use:-
     ./a input.c  or ./a < input.c

   where input.c is your input file name.
