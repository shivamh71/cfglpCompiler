
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
	list<int> * goto_bb_num; 
	Procedure * procedure;
};

%token <integer_value> INTEGER_NUMBER 
%token <integer_value> BASIC_BLOCK 
%token <string_value> NAME
%token RETURN INTEGER IF ELSE GOTO ASSIGN_OP NE EQ LT LE GT GE ADDOP MINUSOP MULTOP DIVOP

%type <symbol_table> declaration_statement_list
%type <symbol_entry> declaration_statement
%type <basic_block_list> basic_block_list
%type <basic_block> basic_block
%type <ast_list> statement_list
%type <ast> assignment_statement
%type <ast> return_statement
%type <ast> equality_expression
%type <ast> ifelse_statement
%type <ast> goto_statement
%type <ast> comparison_expression
%type <ast> arithmetic_expression
%type <ast> greater_than_expression
%type <ast> add_expression
%type <ast> mult_expression
%type <ast> basic_expression
%type <ast> statement
%type <ast> identifier
%type <ast> constant
%type <ast> expression

%start program

%%

program:
	declaration_statement_list	procedure_name	
		{
			// if (NOT_ONLY_PARSE) {
			// 	program_object.set_global_table(*$1);
			// 	return_statement_used_flag = false;
			// }
		}
		procedure_body
		{
			// if (NOT_ONLY_PARSE) {
			// 	program_object.set_procedure_map(current_procedure, get_line_number());
			// 	if ($1)
			// 		$1->global_list_in_proc_map_check();
			// 	delete $1;
			// }
		}
|
	procedure_name	
		{
			// if (NOT_ONLY_PARSE) {
			// 	return_statement_used_flag = false;
			// }
		}
	procedure_body
		{
			// if (NOT_ONLY_PARSE) {
			// 	program_object.set_procedure_map(current_procedure, get_line_number());
			// }
		}
;

procedure_name:
	NAME '(' ')'
		{
			// if (NOT_ONLY_PARSE) {
			// 	current_procedure = new Procedure(void_data_type, *$1, get_line_number());
			// }
		}
;

procedure_body:
	'{' declaration_statement_list	
		{
			// if (NOT_ONLY_PARSE) {
			// 	current_procedure->set_local_list(*$2);
			// 	delete $2;
			// }
		}
	basic_block_list '}'
		{
			// if (NOT_ONLY_PARSE) {
			// 	current_procedure->set_basic_block_list(*$4);
			// 	goto_bb_exist_check(*$4, goto_bb_num); // include check
			// 	delete $4;
			// }
		}
|
	'{' basic_block_list '}'
		{
			// if (NOT_ONLY_PARSE) {
			// 	current_procedure->set_basic_block_list(*$2);
			// 	goto_bb_exist_check(*$2, goto_bb_num);
			// 	delete $2;
			// }
		}
;

declaration_statement_list:
	declaration_statement_list declaration_statement
		{
			// if (NOT_ONLY_PARSE) {
			// 	int line = get_line_number();
			// 	program_object.variable_in_proc_map_check($2->get_variable_name());
			// 	string var_name = $2->get_variable_name();
			// 	if (current_procedure && current_procedure->get_proc_name() == var_name) {
			// 		CHECK_INPUT(true, "Variable name cannot be same as procedure name", get_line_number());
			// 	}
			// 	if ($1 != NULL) {
			// 		if($1->variable_in_symbol_list_check(var_name)) {
			// 			// CHECK_INPUT(true, "Variable is declared twice", get_line_number());
			// 		}
			// 		$$ = $1;
			// 	}
			// 	else
			// 		$$ = new Symbol_Table();
			// 	$$->push_symbol($2);
			// }
		}
|
	declaration_statement
		{
			// if (NOT_ONLY_PARSE) {
			// 	int line = get_line_number();
			// 	program_object.variable_in_proc_map_check($1->get_variable_name());
			// 	string var_name = $1->get_variable_name();
			// 	if (current_procedure && current_procedure->get_proc_name() == var_name) {
			// 		CHECK_INPUT(true, "Variable name cannot be same as procedure name", get_line_number());
			// 	}
			// 	$$ = new Symbol_Table();
			// 	$$->push_symbol($1);
			// }
		}
;

declaration_statement:
	INTEGER NAME ';'
		{
			// if (NOT_ONLY_PARSE) {
			// 	$$ = new Symbol_Table_Entry(*$2, int_data_type, get_line_number());
			// 	delete $2;
			// }
		}
;

basic_block_list:
	basic_block_list basic_block
		{
			// if (NOT_ONLY_PARSE) {
			// 	if (!$2) {
			// 		CHECK_INPUT(true, "Basic block doesn't exist", get_line_number());
			// 	}
			// 	bb_strictly_increasing_order_check($$, $2->get_bb_number());
			// 	$$ = $1;
			// 	$$->back()->set_has_successor(true);
			// 	$$->push_back($2);
			// }
		}
|
	basic_block
		{
			// if (NOT_ONLY_PARSE) {
			// 	if (!$1) {
			// 		CHECK_INPUT(true, "Basic block doesn't exist", get_line_number());
			// 	}
			// 	$$ = new list<Basic_Block *>;
			// 	$$->push_back($1);
			// }
		}
;

basic_block:
	BASIC_BLOCK ':'
		{
			// if (NOT_ONLY_PARSE) {
			// 	if ($1 < 2) {
			// 		CHECK_INPUT(true, "Illegal basic block lable", get_line_number());
			// 	}
			// 	list<Ast *> * ast_list = new list<Ast *>;
			// 	$$ = new Basic_Block($1, get_line_number());
			// 	$$->set_ast_list(*ast_list);
			// }
		}
|
	BASIC_BLOCK ':' statement_list
		{
			// if (NOT_ONLY_PARSE) {
			// 	if ($1 < 2) {
			// 		CHECK_INPUT(true, "Illegal basic block lable", get_line_number());
			// 	}
			// 	$$ = new Basic_Block($1, get_line_number());
			// 	$$->set_ast_list(*$3);
			// 	$$->set_has_successor(false);
			// 	delete $3;
			// }
		}
|
	BASIC_BLOCK ':' statement_list ifelse_statement
		{
			// if (NOT_ONLY_PARSE) {
			// 	if ($1 < 2) {
			// 		CHECK_INPUT(true, "Illegal basic block lable", get_line_number());
			// 	}
			// 	$3->push_back($4);
			// 	$$ = new Basic_Block($1, get_line_number());
			// 	$$->set_ast_list(*$3);
			// 	$$->set_has_successor(true);
			// 	delete $3;
			// }
		}
|
	BASIC_BLOCK ':' statement_list return_statement
		{
			// if (NOT_ONLY_PARSE) {
			// 	if ($1 < 2) {
			// 		CHECK_INPUT(true, "Illegal basic block lable", get_line_number());
			// 	}
			// 	$3->push_back($4);
			// 	$$ = new Basic_Block($1, get_line_number());
			// 	$$->set_ast_list(*$3);
			// 	$$->set_has_successor(true);
			// 	delete $3;
			// }
		}
|
	BASIC_BLOCK ':' statement_list goto_statement
		{
			// if (NOT_ONLY_PARSE) {
			// 	if ($1 < 2) {
			// 		CHECK_INPUT(true, "Illegal basic block lable", get_line_number());
			// 	}
			// 	$3->push_back($4);
			// 	$$ = new Basic_Block($1, get_line_number());
			// 	$$->set_ast_list(*$3);
			// 	$$->set_has_successor(true);
			// 	delete $3;
			// }
		}
|
	BASIC_BLOCK ':' ifelse_statement
		{
			// if (NOT_ONLY_PARSE) {
			// 	if ($1 < 2) {
			// 		CHECK_INPUT(true, "Illegal basic block lable", get_line_number());
			// 	}
			// 	list<Ast *> * ast_list = new list<Ast *>;
			// 	ast_list->push_back($3);
			// 	$$ = new Basic_Block($1, get_line_number());
			// 	$$->set_ast_list(*ast_list);
			// 	$$->set_has_successor(true);
			// }
		}
|
	BASIC_BLOCK ':' return_statement
		{
			// if (NOT_ONLY_PARSE) {
			// 	if ($1 < 2) {
			// 		CHECK_INPUT(true, "Illegal basic block lable", get_line_number());
			// 	}
			// 	list<Ast *> * ast_list = new list<Ast *>;
			// 	ast_list->push_back($3);
			// 	$$ = new Basic_Block($1, get_line_number());
			// 	$$->set_ast_list(*ast_list);
			// 	$$->set_has_successor(true);
			// }
		}
|
	BASIC_BLOCK ':' goto_statement
		{
			// if (NOT_ONLY_PARSE) {
			// 	if ($1 < 2) {
			// 		CHECK_INPUT(true, "Illegal basic block lable", get_line_number());
			// 	}
			// 	list<Ast *> * ast_list = new list<Ast *>;
			// 	ast_list->push_back($3);
			// 	$$ = new Basic_Block($1, get_line_number());
			// 	$$->set_ast_list(*ast_list);
			// 	$$->set_has_successor(true);
			// }
		}
;

statement_list:
	statement_list statement
		{
			// if ($1 != NULL)
			// 	$$ = $1;
			// else
			// 	$$ = new list<Ast *>;
			// $$->push_back($2);
		}
|
	statement
		{
			// $$ = new list<Ast *>;
			// $$->push_back($1);
		}
;

statement:
	assignment_statement
		{
			// $$ = $1;
		}
;

ifelse_statement:
	IF '(' expression ')' goto_statement ELSE goto_statement
		{
			// $$ = new If_Else_Ast($3,$5,$7, get_line_number());
		}
;


goto_statement:
	GOTO BASIC_BLOCK ';'
		{
			// $$ = new Goto_Ast($2, get_line_number());
			// list<Basic_Block *>::iterator i;
			// goto_bb_num->push_back($2);
			// 
		}
;

expression:
	comparison_expression
		{
			// $$ = $1;
		}
;


greater_than_expression:
	greater_than_expression GT arithmetic_expression
		{
			// $$ = new Relational_Expr_Ast($1,GTOP,$3,get_line_number());
			// $$->check_ast();
		}
|
	greater_than_expression GE arithmetic_expression
		{
			// $$ = new Relational_Expr_Ast($1,GEOP,$3,get_line_number());
			// $$->check_ast();
		}
|
	greater_than_expression LT arithmetic_expression
		{
			// $$ = new Relational_Expr_Ast($1,LTOP,$3,get_line_number());
			// $$->check_ast();
		}
|
	greater_than_expression LE arithmetic_expression
		{
			// $$ = new Relational_Expr_Ast($1,LEOP,$3,get_line_number());
			// $$->check_ast();
		}
|
	arithmetic_expression
		{
			// $$ = $1;
		}	
;

equality_expression:
	equality_expression EQ greater_than_expression
		{
			// $$ = new Relational_Expr_Ast($1,EQOP,$3,get_line_number());
			// $$->check_ast();
		}
|
	equality_expression NE greater_than_expression
		{
			// $$ = new Relational_Expr_Ast($1,NEOP,$3,get_line_number());
			// $$->check_ast();
		}
|
	greater_than_expression
		{
			// $$ = $1;
		}
;

comparison_expression:
	equality_expression
		{
			// $$ = $1;
		}
;

basic_expression:
	identifier
		{
			// $$ = $1;
		}
|
	constant
		{
			// $$ = $1;
		}
|
	'(' expression ')'
		{
			// $$ = $1;
		}
;


mult_expression:
	mult_expression MULTOP basic_expression
		{
			// $$ = new Arithmetic_Expr_Ast($1,MUL,$3, get_line_number());
			// $$->check_ast();
		}
|
	mult_expression DIVOP basic_expression
		{
			// $$ = new Arithmetic_Expr_Ast($1,DIV,$3, get_line_number());
			// $$->check_ast();
		}
|
	basic_expression
;

add_expression:
	add_expression ADDOP mult_expression
		{
			// $$ = new Arithmetic_Expr_Ast($1,ADD,$3, get_line_number());
			// $$->check_ast();
		}
|
	add_expression MINUSOP mult_expression
		{
			// $$ = new Arithmetic_Expr_Ast($1,SUB,$3, get_line_number());
			// $$->check_ast();
		}
|
	mult_expression
		{
			// $$ = $1;
		}
;

arithmetic_expression:
	add_expression
		{
			// $$ = $1;
		}
;

assignment_statement:
	identifier ASSIGN_OP expression ';'
		{
			// CHECK_INVARIANT((($1 != NULL) && ($3 != NULL)), "lhs/rhs cannot be null");
			// Ast * lhs = $1;
			// Ast * rhs = $3;
			// Ast * assign = new Assignment_Ast(lhs, rhs, get_line_number());
			// assign->check_ast();
			// $$ = assign;
		}
;

return_statement:
	RETURN ';'
		{
			// $$ = new Return_Ast(get_line_number());
			// return_statement_used_flag = true;
		}
;

identifier:
	NAME
		{
			// Symbol_Table_Entry * var_table_entry;
			// CHECK_INVARIANT(($1 != NULL), "Variable name cannot be null");
			// string var_name = *$1;
			// if (current_procedure->variable_in_symbol_list_check(var_name) == true)
			// 	 var_table_entry = &(current_procedure->get_symbol_table_entry(var_name));
			// else if (program_object.variable_in_symbol_list_check(var_name) == true)
			// 	var_table_entry = &(program_object.get_symbol_table_entry(var_name));
			// else
			// 	CHECK_INVARIANT(CONTROL_SHOULD_NOT_REACH, "Variable has not been declared");
			// Ast * name_ast = new Name_Ast(var_name, *var_table_entry, get_line_number());
			// $$ = name_ast;
		}
;

constant:
	INTEGER_NUMBER
		{
			// Ast * num_ast = new Number_Ast<int>($1, int_data_type, get_line_number());
			// $$ = num_ast;
		}
;