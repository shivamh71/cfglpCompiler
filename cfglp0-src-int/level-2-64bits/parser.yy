
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
	float float_value;
	std::string * string_value;
	list<Ast *> * ast_list;
	Ast * ast;
	Symbol_Table * symbol_table;
	Symbol_Table_Entry * symbol_entry;
	Basic_Block * basic_block;
	list<Basic_Block *> * basic_block_list;
	list<int> * goto_bb_num ; 
	Procedure * procedure;
};

%token <integer_value> INTEGER_NUMBER
%token <integer_value> BASIC_BLOCK 
%token <float_value> FLOAT_NUMBER 
%token <string_value> NAME
%token RETURN INTEGER FLOAT DOUBLE IF ELSE GOTO ASSIGN_OP NE EQ LT LE GT GE

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
%type <ast> unary_expression
%type <ast> statement
%type <ast> identifier
%type <ast> constant
%type <ast> expression
%type <string_value> type_name

%start program

%%

program:
	declaration_statement_list	procedure_name	
		{
			if (NOT_ONLY_PARSE)
			{
				program_object.set_global_table(*$1);
				return_statement_used_flag = false;
			}
		}
		procedure_body
		{
			if (NOT_ONLY_PARSE)
			{
				program_object.set_procedure_map(current_procedure, get_line_number());
				if ($1)
					$1->global_list_in_proc_map_check();
				delete $1;
			}
		}
|
	procedure_name	
		{
			if(NOT_ONLY_PARSE)
			{
				return_statement_used_flag = false;
			}
		}
	procedure_body
		{
			if(NOT_ONLY_PARSE)
			{
				program_object.set_procedure_map(current_procedure, get_line_number());
			}
		}
;

procedure_name:
	NAME '(' ')'
		{
			if(NOT_ONLY_PARSE)
			{
				current_procedure = new Procedure(void_data_type, *$1, get_line_number());
			}
		}
;

procedure_body:
	'{' declaration_statement_list	
		{
			if(NOT_ONLY_PARSE)
			{
				current_procedure->set_local_list(*$2);
				delete $2;
			}
		}
	basic_block_list '}'
		{
			if(NOT_ONLY_PARSE)
			{
				current_procedure->set_basic_block_list(*$4);
				goto_bb_exist_check(*$4, goto_bb_num);
				delete $4;
			}
		}
|
	'{' basic_block_list '}'
		{
			if(NOT_ONLY_PARSE)
			{
				current_procedure->set_basic_block_list(*$2);
				goto_bb_exist_check(*$2, goto_bb_num);
				delete $2;
			}
		}
;

declaration_statement_list:
	declaration_statement_list declaration_statement
		{
			if(NOT_ONLY_PARSE)
			{
				CHECK_INVARIANT(($2 != NULL), "The declaration statement cannot be null");
				CHECK_INVARIANT(($1 != NULL), "The declaration statement list cannot be null");
				string var_name = $2->get_variable_name();
				CHECK_INPUT ((program_object.variable_in_proc_map_check(var_name) == false), "Variable name cannot be same as the procedure name", get_line_number());
				if (current_procedure != NULL)
				{
					CHECK_INPUT((current_procedure->get_proc_name() != var_name), "Variable name cannot be same as procedure name", get_line_number());
				}
				CHECK_INPUT(($1->variable_in_symbol_list_check(var_name) == false), "Variable is declared twice", get_line_number());
				$$ = $1;
				$$->push_symbol($2);
			}
		}
|
	declaration_statement
		{
			if(NOT_ONLY_PARSE)
			{
				CHECK_INVARIANT(($1 != NULL), "The declaration statement cannot be null");
				string var_name = $1->get_variable_name();
				CHECK_INPUT ((program_object.variable_in_proc_map_check(var_name) == false), "Variable name cannot be same as the procedure name", get_line_number());
				if (current_procedure != NULL)
				{
					CHECK_INPUT((current_procedure->get_proc_name() != var_name), "Variable name cannot be same as procedure name", get_line_number());
				}
				$$ = new Symbol_Table();
				$$->push_symbol($1);
			}
		}
;

declaration_statement:
	INTEGER NAME ';'
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = new Symbol_Table_Entry(*$2, int_data_type, get_line_number());
				delete $2;
			}
		}
|
	FLOAT NAME ';'
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = new Symbol_Table_Entry(*$2, float_data_type, get_line_number());
				delete $2;
			}
		}
|
	DOUBLE NAME ';'
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = new Symbol_Table_Entry(*$2, double_data_type, get_line_number());
				delete $2;
			}
		}
;

basic_block_list:
	basic_block_list basic_block
		{
			if(NOT_ONLY_PARSE)
			{
				CHECK_INVARIANT(($2 != NULL), "Basic block doesn't exist");
				bb_strictly_increasing_order_check($$, $2->get_bb_number());
				$$ = $1;
				$$->back()->set_has_successor(true);
				$$->push_back($2);
			}
		}
|
	basic_block
		{
			if(NOT_ONLY_PARSE)
			{
				CHECK_INVARIANT(($1 != NULL), "Basic block doesn't exist");
				$$ = new list<Basic_Block *>;
				$$->push_back($1);
			}
		}
;

basic_block:
	BASIC_BLOCK ':'
		{
			if(NOT_ONLY_PARSE)
			{
				CHECK_INPUT(($1 >= 2), "Illegal basic block lable", get_line_number());
				list<Ast *> * ast_list = new list<Ast *>;
				$$ = new Basic_Block($1, get_line_number());
				$$->set_ast_list(*ast_list);
			}
		}
|
	BASIC_BLOCK ':' statement_list
		{
			if(NOT_ONLY_PARSE)
			{
				CHECK_INPUT(($1 >= 2), "Illegal basic block lable", get_line_number());
				$$ = new Basic_Block($1, get_line_number());
				$$->set_ast_list(*$3);
				$$->set_has_successor(false);
				delete $3;
			}
		}
|
	BASIC_BLOCK ':' statement_list ifelse_statement
		{
			if(NOT_ONLY_PARSE)
			{
				CHECK_INPUT(($1 >= 2), "Illegal basic block lable", get_line_number());
				$3->push_back($4);
				$$ = new Basic_Block($1, get_line_number());
				$$->set_ast_list(*$3);
				$$->set_has_successor(true);
				delete $3;
			}
		}
|
	BASIC_BLOCK ':' statement_list return_statement
		{
			if(NOT_ONLY_PARSE)
			{
				CHECK_INPUT(($1 >= 2), "Illegal basic block lable", get_line_number());
				$3->push_back($4);
				$$ = new Basic_Block($1, get_line_number());
				$$->set_ast_list(*$3);
				$$->set_has_successor(true);
				delete $3;
			}
		}
|
	BASIC_BLOCK ':' statement_list goto_statement
		{
			if(NOT_ONLY_PARSE)
			{
				CHECK_INPUT(($1 >= 2), "Illegal basic block lable", get_line_number());
				$3->push_back($4);
				$$ = new Basic_Block($1, get_line_number());
				$$->set_ast_list(*$3);
				$$->set_has_successor(true);
				delete $3;
			}
		}
|
	BASIC_BLOCK ':' ifelse_statement
		{
			if(NOT_ONLY_PARSE)
			{
				CHECK_INPUT(($1 >= 2), "Illegal basic block lable", get_line_number());
				list<Ast *> * ast_list = new list<Ast *>;
				ast_list->push_back($3);
				$$ = new Basic_Block($1, get_line_number());
				$$->set_ast_list(*ast_list);
				$$->set_has_successor(true);
			}
		}
|
	BASIC_BLOCK ':' return_statement
		{
			if(NOT_ONLY_PARSE)
			{
				CHECK_INPUT(($1 >= 2), "Illegal basic block lable", get_line_number());
				list<Ast *> * ast_list = new list<Ast *>;
				ast_list->push_back($3);
				$$ = new Basic_Block($1, get_line_number());
				$$->set_ast_list(*ast_list);
				$$->set_has_successor(true);
			}
		}
|
	BASIC_BLOCK ':' goto_statement
		{
			if(NOT_ONLY_PARSE)
			{
				CHECK_INPUT(($1 >= 2), "Illegal basic block lable", get_line_number());
				list<Ast *> * ast_list = new list<Ast *>;
				ast_list->push_back($3);
				$$ = new Basic_Block($1, get_line_number());
				$$->set_ast_list(*ast_list);
				$$->set_has_successor(true);
			}
		}
;

statement_list:
	statement_list statement
		{
			if(NOT_ONLY_PARSE)
			{
				if ($1 != NULL)
					$$ = $1;
				else
					$$ = new list<Ast *>;
				$$->push_back($2);
			}
		}
|
	statement
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = new list<Ast *>;
				$$->push_back($1);
			}
		}
;

statement:
	assignment_statement
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = $1;
			}
		}
;

ifelse_statement:
	IF '(' expression ')' goto_statement ELSE goto_statement
		{
			if(NOT_ONLY_PARSE)
			{
				CHECK_INPUT(single_var_in_expr_check,"Cannot parse the input program",get_line_number());
				$$ = new If_Else_Ast($3,$5,$7,get_line_number());
			}
		}
;


goto_statement:
	GOTO BASIC_BLOCK ';'
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = new Goto_Ast($2,get_line_number());
				list<Basic_Block *>::iterator i;
				goto_bb_num->push_back($2);
			}
		}
;

expression:
	comparison_expression
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = $1;
			}
		}
;


greater_than_expression:
	greater_than_expression GT arithmetic_expression
		{
			if(NOT_ONLY_PARSE)
			{
				single_var_in_expr_check = true;
				$$ = new Relational_Expr_Ast($1,GTOP,$3,get_line_number());
				$$->check_ast();
			}
		}
|
	greater_than_expression GE arithmetic_expression
		{
			if(NOT_ONLY_PARSE)
			{
				single_var_in_expr_check = true;
				$$ = new Relational_Expr_Ast($1,GEOP,$3,get_line_number());
				$$->check_ast();
			}
		}
|
	greater_than_expression LT arithmetic_expression
		{
			if(NOT_ONLY_PARSE)
			{
				single_var_in_expr_check = true;
				$$ = new Relational_Expr_Ast($1,LTOP,$3,get_line_number());
				$$->check_ast();
			}
		}
|
	greater_than_expression LE arithmetic_expression
		{
			if(NOT_ONLY_PARSE)
			{
				single_var_in_expr_check = true;
				$$ = new Relational_Expr_Ast($1,LEOP,$3,get_line_number());
				$$->check_ast();
			}
		}
|
	arithmetic_expression
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = $1;
			}
		}	
;

equality_expression:
	equality_expression EQ greater_than_expression
		{
			if(NOT_ONLY_PARSE)
			{
				single_var_in_expr_check = true;
				$$ = new Relational_Expr_Ast($1,EQOP,$3,get_line_number());
				$$->check_ast();
			}
		}
|
	equality_expression NE greater_than_expression
		{
			if(NOT_ONLY_PARSE)
			{
				single_var_in_expr_check = true;
				$$ = new Relational_Expr_Ast($1,NEOP,$3,get_line_number());
				$$->check_ast();
			}
		}
|
	greater_than_expression
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = $1;
			}
		}
;

comparison_expression:
	equality_expression
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = $1;
			}
		}
;

unary_expression:
	'(' type_name ')' '(' expression ')'
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = $5;
				$$->set_data_type(*$2);
			}
		}
|
	'(' type_name ')' identifier
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = $4;
				$$->set_data_type(*$2);
			}
		}
|
	'(' type_name ')' constant
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = $4;
				$$->set_data_type(*$2);
			}
		}
|
	identifier
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = $1;
			}
		}
|
	constant
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = $1;
			}
		}
|
	'(' expression ')'
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = $2;
			}
		}
;

type_name:
	FLOAT
		{
			if(NOT_ONLY_PARSE)
			{
				string *t = new string;
				*t = "FLOAT";
				$$ = t;
			}
		}
|
	DOUBLE
		{
			if(NOT_ONLY_PARSE)
			{
				string *t = new string;
				*t = "FLOAT";
				$$ = t;
			}
		}
|
	INTEGER
		{
			if(NOT_ONLY_PARSE)
			{
				string *t = new string;
				*t = "INTEGER";
				$$ = t;
			}
		}
;

basic_expression:
	'-' unary_expression
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = new Negation_Expr_Ast($2);
				if ($2->get_data_type()==1) {
					$$->set_data_type("INTEGER");
				}
				else if ($2->get_data_type()==3) {
					$$->set_data_type("FLOAT");
				}
				else if ($2->get_data_type()==4) {
					$$->set_data_type("DOUBLE");
				}
			}
		}
|
	unary_expression
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = $1;
			}
		}
;

mult_expression:
	mult_expression '*' basic_expression
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = new Arithmetic_Expr_Ast($1,MUL,$3,get_line_number());
				$$->check_ast();
			}
		}
|
	mult_expression '/' basic_expression
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = new Arithmetic_Expr_Ast($1,DIV,$3,get_line_number());
				$$->check_ast();
			}
		}
|
	basic_expression
;

add_expression:
	add_expression '+' mult_expression
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = new Arithmetic_Expr_Ast($1,ADD,$3,get_line_number());
				$$->check_ast();
			}
		}
|
	add_expression '-' mult_expression
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = new Arithmetic_Expr_Ast($1,SUB,$3,get_line_number());
				$$->check_ast();
			}
		}
|
	mult_expression
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = $1;
			}
		}
;

arithmetic_expression:
	add_expression
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = $1;
			}
		}
;

assignment_statement:
	identifier ASSIGN_OP expression ';'
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = new Assignment_Ast($1, $3, get_line_number());
				$$->check_ast();
			}
		}
;

return_statement:
	RETURN ';'
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = new Return_Ast(get_line_number());
				return_statement_used_flag = true;
			}
		}
;

identifier:
	NAME
		{
			if(NOT_ONLY_PARSE)
			{
				Symbol_Table_Entry * var_table_entry;
				CHECK_INVARIANT(($1 != NULL), "Variable name cannot be null");
				string var_name = *$1;
				if (current_procedure->variable_in_symbol_list_check(*$1))
					 var_table_entry = &(current_procedure->get_symbol_table_entry(*$1));
				else if (program_object.variable_in_symbol_list_check(*$1))
					var_table_entry = &(program_object.get_symbol_table_entry(*$1));
				else
					CHECK_INVARIANT(CONTROL_SHOULD_NOT_REACH, "Variable has not been declared");
				// cout<<var_table_entry->variable_name << " "<<var_table_entry->get_symbol_scope()<<endl;
				$$ = new Name_Ast(var_name, *var_table_entry, get_line_number());
				delete $1;
			}
		}
;

constant:
	INTEGER_NUMBER
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = new Number_Ast<int>($1, int_data_type, get_line_number());
			}
		}
|
	FLOAT_NUMBER
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = new Number_Ast<float>($1, float_data_type, get_line_number());
			}
		}
;