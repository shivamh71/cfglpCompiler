
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

%start program

%%

program:
	declaration_statement_list	procedure_name	
		{
			program_object.set_global_table(*$1);
			return_statement_used_flag = false;	// No return statement in the current procedure till now
		}
		procedure_body
		{
			program_object.set_procedure_map(*current_procedure);
			if ($1)
				$1->global_list_in_proc_map_check(get_line_number());
			delete $1;
		}
|
	procedure_name	
		{
			return_statement_used_flag = false;	// No return statement in the current procedure till now
		}
	procedure_body
		{
			program_object.set_procedure_map(*current_procedure);
		}
;

procedure_name:
	NAME '(' ')'
		{
			current_procedure = new Procedure(void_data_type, *$1);
		}
;

procedure_body:
	'{' declaration_statement_list	
		{
			current_procedure->set_local_list(*$2);

			delete $2;
		}
	basic_block_list '}'
		{
			current_procedure->set_basic_block_list(*$4);
			goto_bb_exist_check(*$4, goto_bb_num);
			delete $4;
		}
|
	'{' basic_block_list '}'
		{
			current_procedure->set_basic_block_list(*$2);
			goto_bb_exist_check(*$2, goto_bb_num);

			delete $2;
		}
;

declaration_statement_list:
	declaration_statement_list declaration_statement
		{
			// if declaration is local then no need to check in global list
			// if declaration is global then this list is global list
			int line = get_line_number();
			program_object.variable_in_proc_map_check($2->get_variable_name(), line);

			string var_name = $2->get_variable_name();
			if (current_procedure && current_procedure->get_proc_name() == var_name)
			{
				int line = get_line_number();
				report_error("Variable name cannot be same as procedure name", line);
			}
			if ($1 != NULL)
			{
				if($1->variable_in_symbol_list_check(var_name))
				{
					int line = get_line_number();
					report_error("Variable is declared twice", line);
				}
				$$ = $1;
			}
			else
				$$ = new Symbol_Table();
			$$->push_symbol($2);
		}
|
	declaration_statement
		{
			int line = get_line_number();
			program_object.variable_in_proc_map_check($1->get_variable_name(), line);

			string var_name = $1->get_variable_name();
			if (current_procedure && current_procedure->get_proc_name() == var_name)
			{
				int line = get_line_number();
				report_error("Variable name cannot be same as procedure name", line);
			}

			$$ = new Symbol_Table();
			$$->push_symbol($1);
		}
;

declaration_statement:
	INTEGER NAME ';'
		{
			$$ = new Symbol_Table_Entry(*$2, int_data_type);
			delete $2;
		}
;

basic_block_list:
	basic_block_list basic_block
		{
			if (!$2)
			{
				int line = get_line_number();
				report_error("Basic block doesn't exist", line);
			}
			bb_strictly_increasing_order_check($$, $2->get_bb_number());
			$$ = $1;
			$$->back()->set_has_successor(true);
			$$->push_back($2);
		}
|
	basic_block
		{
			if (!$1)
			{
				int line = get_line_number();
				report_error("Basic block doesn't exist", line);
			}
			$$ = new list<Basic_Block *>;
			$$->push_back($1);
		}
;

basic_block:
	BASIC_BLOCK ':'
		{

			if ($1 < 2) {
				int line = get_line_number();
				report_error("Illegal basic block lable", line);
			}
			list<Ast *> * ast_list = new list<Ast *>;
			$$ = new Basic_Block($1, *ast_list);
		}
|
	BASIC_BLOCK ':' statement_list
		{
			if ($1 < 2) {
				int line = get_line_number();
				report_error("Illegal basic block lable", line);
			}

			$$ = new Basic_Block($1, *$3);
			$$->set_has_successor(false);

			delete $3;
		}
|
	BASIC_BLOCK ':' statement_list ifelse_statement
		{
			if ($1 < 2) {
				int line = get_line_number();
				report_error("Illegal basic block lable", line);
			}

			$3->push_back($4);
			$$ = new Basic_Block($1, *$3);
			$$->set_has_successor(true);


			delete $3;
		}
|
	BASIC_BLOCK ':' statement_list return_statement
		{
			// if (*$2 != "bb") {
			// 	int line = get_line_number();
			// 	report_error("Not basic block lable", line);
			// }

			if ($1 < 2) {
				int line = get_line_number();
				report_error("Illegal basic block lable", line);
			}

			$3->push_back($4);
			$$ = new Basic_Block($1, *$3);
			$$->set_has_successor(true);

			delete $3;
		}
|
	BASIC_BLOCK ':' statement_list goto_statement
		{
			// if (*$2 != "bb") {
			// 	int line = get_line_number();
			// 	report_error("Not basic block lable", line);
			// }
			
			if ($1 < 2) {
				int line = get_line_number();
				report_error("Illegal basic block lable", line);
			}

			$3->push_back($4);
			$$ = new Basic_Block($1, *$3);
			$$->set_has_successor(true);

			delete $3;
		}
|
	BASIC_BLOCK ':' ifelse_statement
		{
			// if (*$2 != "bb") {
			// 	int line = get_line_number();
			// 	report_error("Not basic block lable", line);
			// }

			if ($1 < 2) {
				int line = get_line_number();
				report_error("Illegal basic block lable", line);
			}

			list<Ast *> * ast_list = new list<Ast *>;
			ast_list->push_back($3);
			$$ = new Basic_Block($1, *ast_list);
			$$->set_has_successor(true);


		}
|
	BASIC_BLOCK ':' return_statement
		{
			// if (*$2 != "bb") {
			// 	int line = get_line_number();
			// 	report_error("Not basic block lable", line);
			// }

			if ($1 < 2) {
				int line = get_line_number();
				report_error("Illegal basic block lable", line);
			}

			list<Ast *> * ast_list = new list<Ast *>;
			ast_list->push_back($3);
			$$ = new Basic_Block($1, *ast_list);
			$$->set_has_successor(true);

		}
|
	BASIC_BLOCK ':' goto_statement
		{
			// if (*$2 != "bb") {
			// 	int line = get_line_number();
			// 	report_error("Not basic block lable", line);
			// }

			if ($1 < 2) {
				int line = get_line_number();
				report_error("Illegal basic block lable", line);
			}

			list<Ast *> * ast_list = new list<Ast *>;
			ast_list->push_back($3);
			$$ = new Basic_Block($1, *ast_list);
			$$->set_has_successor(true);

		}
;

statement_list:
	statement_list statement
		{
			if ($1 != NULL)
				$$ = $1;
			else
				$$ = new list<Ast *>;
			$$->push_back($2);
		}
|
	statement
		{
			$$ = new list<Ast *>;
			$$->push_back($1);
		}
;

statement:
	assignment_statement
		{
			$$ = $1;
		}
;

ifelse_statement:
	IF '(' expression ')' goto_statement ELSE goto_statement
		{
			$$ = new If_Else_Ast($3,$5,$7);
		}
;


goto_statement:
	GOTO BASIC_BLOCK ';'
		{
			$$ = new Goto_Ast($2);
			list<Basic_Block *>::iterator i;
			goto_bb_num->push_back($2);
			
		}
;

expression:
	comparison_expression
		{
			$$ = $1;
		}
;

greater_than_expression:
	greater_than_expression GT arithmetic_expression
		{
			$$ = new Relational_Expr_Ast($1,GTOP,$3);
			int line = get_line_number();
			$$->check_ast(line);
		}
|
	greater_than_expression GE arithmetic_expression
		{
			$$ = new Relational_Expr_Ast($1,GEOP,$3);
			int line = get_line_number();
			$$->check_ast(line);
		}
|
	greater_than_expression LT arithmetic_expression
		{
			$$ = new Relational_Expr_Ast($1,LTOP,$3);
			int line = get_line_number();
			$$->check_ast(line);
		}
|
	greater_than_expression LE arithmetic_expression
		{
			$$ = new Relational_Expr_Ast($1,LEOP,$3);
			int line = get_line_number();
			$$->check_ast(line);
		}
|
	arithmetic_expression
		{
			$$ = $1;
		}	
;

equality_expression:
	equality_expression EQ greater_than_expression
		{
			$$ = new Relational_Expr_Ast($1,EQOP,$3);
			int line = get_line_number();
			$$->check_ast(line);
		}
|
	equality_expression NE greater_than_expression
		{
			$$ = new Relational_Expr_Ast($1,NEOP,$3);
			int line = get_line_number();
			$$->check_ast(line);
		}
|
	greater_than_expression
		{
			$$ = $1;
		}
;

comparison_expression:
	equality_expression
		{
			$$ = $1;
		}
;

unary_expression:
	identifier
		{
			$$ = $1;
		}
|
	constant
		{
			$$ = $1;
		}
;

basic_expression:
	'-' unary_expression
|
	unary_expression
;

mult_expression:
	mult_expression '*' basic_expression
		{
			$$ = new Arithmetic_Expr_Ast($1,MUL,$3);
			int line = get_line_number();
			$$->check_ast(line);
		}
|
	mult_expression '/' basic_expression
		{
			$$ = new Arithmetic_Expr_Ast($1,DIV,$3);
			int line = get_line_number();
			$$->check_ast(line);
		}
|
	basic_expression
;

add_expression:
	add_expression '+' mult_expression
		{
			$$ = new Arithmetic_Expr_Ast($1,ADD,$3);
			int line = get_line_number();
			$$->check_ast(line);
		}
|
	add_expression '-' mult_expression
		{
			$$ = new Arithmetic_Expr_Ast($1,SUB,$3);
			int line = get_line_number();
			$$->check_ast(line);
		}
|
	mult_expression
		{
			$$ = $1;
		}
;

arithmetic_expression:
	add_expression
		{
			$$ = $1;
		}
;

assignment_statement:
	identifier ASSIGN_OP expression ';'
		{
			$$ = new Assignment_Ast($1, $3);
			int line = get_line_number();
			$$->check_ast(line);
		}
;

return_statement:
	RETURN ';'
		{
			$$ = new Return_Ast();
			return_statement_used_flag = true; // Current procedure has an occurrence of return statement
		}
;

identifier:
	NAME
		{
			Symbol_Table_Entry var_table_entry;

			if (current_procedure->variable_in_symbol_list_check(*$1))
				 var_table_entry = current_procedure->get_symbol_table_entry(*$1);

			else if (program_object.variable_in_symbol_list_check(*$1))
				var_table_entry = program_object.get_symbol_table_entry(*$1);

			else
			{
				int line = get_line_number();
				report_error("Variable has not been declared", line);
			}

			$$ = new Name_Ast(*$1, var_table_entry);
			delete $1;
		}
;

constant:
	INTEGER_NUMBER
		{
			$$ = new Number_Ast<int>($1, int_data_type);
		}
|
	FLOAT_NUMBER
		{
			// $$ = new 
		}
;