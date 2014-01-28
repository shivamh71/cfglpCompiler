
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
			if (return_statement_used_flag == false)
			{
				int line = get_line_number();
				report_error("Atleast 1 basic block should have a return statement", line);
			}
			current_procedure->set_basic_block_list(*$4);
			delete $4;
		}
|
	'{' basic_block_list '}'
		{
			if (return_statement_used_flag == false)
			{
				int line = get_line_number();
				report_error("Atleast 1 basic block should have a return statement", line);
			}
			current_procedure->set_basic_block_list(*$2);
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
	INTEGER identifier ';'
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
	'<' NAME INTEGER_NUMBER '>' ':' statement_list
|
	'<' NAME INTEGER_NUMBER '>' ':' statement_list ifelse_statement
|
	'<' NAME INTEGER_NUMBER '>' ':' ifelse_statement
;

statement_list:
	statement_list statement
|
	statement
;

statement:
	assignment_statement
|
	goto_statement	
|
	return_statement
;

goto_statement:
	GOTO '<' NAME INTEGER_NUMBER '>' ';'
;
 
ifelse_statement:
	IF '(' expression ')' goto_statement ELSE goto_statement 
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
|
	constant
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
		{
			$$ = new Assignment_Ast($1, $3);
			int line = get_line_number();
			$$->check_ast(line);
		}
;

return_statement:
	RETURN ';'
		{
			
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
		#if 0
			$$ = new Number_Ast<int>($1, int_data_type);
		#endif 
		}
;