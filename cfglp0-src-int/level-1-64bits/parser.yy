
/*********************************************************************************************

                                cfglp : A CFG Language Processor
                                --------------------------------

           About:

           Implemented   by  Tanu  Kanvar (tanu@cse.iitb.ac.in) and Uday
           Khedker    (http://www.cse.iitb.ac.in/~uday)  FOR the courses
           cs302+cs306: Language  Processors  (theory and  lab)  at  IIT
           Bombay.

           Release  date  Jan  15, 2013.  Copyrights  reserved  by  Uday
           Khedker. This  implemenation  has been made  available purely
           FOR academic purposes without any warranty of any kind.

           Documentation (functionality, manual, and design) and related
           tools are  available at http://www.cse.iitb.ac.in/~uday/cfglp


***********************************************************************************************/

%scanner ../scanner.h
%scanner-token-function d_scanner.lex()
%filenames parser
%parsefun-source parser.cc

%union {
	int integer_value;
	std::string * string_value;
	list<Ast *> * ast_list;
	Ast * ast;
	Symbol_Table * symbol_table;
	Symbol_Table_Entry * symbol_entry;
	Basic_Block * basic_block;
	list<Basic_Block *> * basic_block_list;
	Procedure * procedure;
};

%token <integer_value> INTEGER_NUMBER
%token <string_value> NAME
%token RETURN INTEGER IF ELSE GOTO


%start program

%%

program:
	declaration_statement_list	procedure_name	procedure_body
|
	procedure_name	procedure_body
;

procedure_name:
	NAME '(' ')'
;

procedure_body:
	'{' declaration_statement_list	basic_block_list '}'
|
	'{' basic_block_list '}'
;

declaration_statement_list:
	declaration_statement_list declaration_statement
|
	declaration_statement
;

declaration_statement:
	INTEGER identifier ';'
;

basic_block_list:
	basic_block_list basic_block
|
	basic_block
;

basic_block:
	'<' NAME INTEGER_NUMBER '>' ':' statement_list
;

statement_list:
	statement_list statement
|
	statement
;

statement:
	selection_statement
|
	assignment_statement
|
	condition_statement
|
	compound_statement
|
	goto_statement	
|
	return_statement
;

goto_statement:
	GOTO '<' NAME INTEGER_NUMBER '>' ';'
;

compound_statement:
	'{' declaration_statement_list statement_list '}'
;

selection_statement:
	ifelse_statement
;

ifelse_statement:
	IF '(' boolean_expression ')' goto_statement
|
	IF '(' boolean_expression ')' goto_statement ELSE goto_statement
;

expression:
	boolean_expression
;

less_than_expression:
	less_than_expression '<' arithmetic_expression
|
	less_than_expression '<' '=' arithmetic_expression
|
	arithmetic_expression
;

greater_than_expression:
	greater_than_expression '>' less_than_expression
|
	greater_than_expression '>' '=' less_than_expression
|
	less_than_expression	
;

equality_expression:
	equality_expression '=' '=' greater_than_expression
|
	equality_expression '!' '=' greater_than_expression
|
	greater_than_expression
;

comparison_expression:
	equality_expression
;

basic_expression:
	'(' expression ')'
|
	identifier
;

not_expression:
	'!' not_expression
|
	basic_expression
;

and_expression:
	and_expression '&' '&' comparison_expression
|
	comparison_expression
;

or_expression:
	or_expression '|' '|' and_expression
|
	and_expression
;

boolean_expression:
	or_expression
;

mult_expression:
	mult_expression '*' not_expression
|
	mult_expression '/' not_expression
|
	not_expression
;

add_expression:
	add_expression '+' mult_expression
|
	add_expression '-' mult_expression
|
	mult_expression
;

arithmetic_expression:
	add_expression
;

assignment_statement:
	identifier '=' expression ';'
|
	identifier '=' constant ';'
;

return_statement:
	RETURN ';'
;

condition_statement:
	identifier '=' '(' boolean_expression ')' '?' expression ':' expression ';'
;

identifier:
	NAME
|
	constant
;

constant:
	INTEGER_NUMBER
;