
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
%token RETURN INTEGER FLOAT DOUBLE VOID IF ELSE GOTO ASSIGN_OP NE EQ LT LE GT GE

%type <symbol_table> declaration_statement_list
%type <symbol_table> comma_separated_declaration_list
%type <symbol_entry> declaration_statement
%type <symbol_entry> func_arguement_statement
%type <basic_block_list> basic_block_list
%type <basic_block> basic_block
%type <ast_list> statement_list
%type <ast_list> comma_separated_expression_list
%type <ast> assignment_statement
%type <ast> function_call_statement
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
	declaration_statement_list function_declaration_list procedure_list
		{
			if (NOT_ONLY_PARSE)
			{
				for (int i=0;i<called_procedures.size();i++) {
					int check_flag = 1;
					for (int j=0;j<defined_procedures.size();j++) {
						if (defined_procedures[j] == called_procedures[i]) {
							check_flag = 0;
							break;
						}
					}
					CHECK_INVARIANT(!check_flag, "Called procedure is not defined");
				}
			}
		}
|
	function_declaration_list procedure_list
		{
			if (NOT_ONLY_PARSE)
			{
				for (int i=0;i<called_procedures.size();i++) {
					int check_flag = 1;
					for (int j=0;j<defined_procedures.size();j++) {
						if (defined_procedures[j] == called_procedures[i]) {
							check_flag = 0;
							break;
						}
					}
					CHECK_INVARIANT(!check_flag, "Called procedure is not defined");
				}
			}
		}
|
	declaration_statement_list procedure_list
		{
			if (NOT_ONLY_PARSE)
			{
				for (int i=0;i<called_procedures.size();i++) {
					int check_flag = 1;
					for (int j=0;j<defined_procedures.size();j++) {
						if (defined_procedures[j] == called_procedures[i]) {
							check_flag = 0;
							break;
						}
					}
					CHECK_INVARIANT(!check_flag, "Called procedure is not defined");
				}
			}
		}
|
	procedure_list
		{
			if (NOT_ONLY_PARSE)
			{
				for (int i=0;i<called_procedures.size();i++) {
					int check_flag = 1;
					for (int j=0;j<defined_procedures.size();j++) {
						if (defined_procedures[j] == called_procedures[i]) {
							check_flag = 0;
							break;
						}
					}
					CHECK_INVARIANT(!check_flag, "Called procedure is not defined");
				}
			}
		}
;

procedure_list:
	procedure_list procedure_statement
	{
		// nothing to be done here
	}
|
	procedure_statement
	{
		// nothing to be done here
	}
;

procedure_statement:
	procedure_name	procedure_body
		{
			if (NOT_ONLY_PARSE)
			{
				CHECK_INPUT(return_statement_used_flag, "Last return statement type, of procedure, and its prototype should match", get_line_number());
			}
		}
;

procedure_name:
	NAME '(' comma_separated_declaration_list ')'
		{
			if (NOT_ONLY_PARSE)
			{
				CHECK_INPUT(!program_object.variable_in_symbol_list_check(*$1), "Procedure name cannot be same as global variable", get_line_number());

				list<Symbol_Table_Entry*>::iterator it;
				for (it=$3->variable_table.begin();it!=$3->variable_table.end();it++) {
					CHECK_INPUT(program_object.procedure_map.find((*it)->variable_name)==program_object.procedure_map.end(), "Formal parameter list cannot be same as function name", get_line_number());
				}
				current_procedure = program_object.get_procedure(*$1);
				CHECK_INPUT(current_procedure != NULL, "Procedure corresponding to the name is not found", get_line_number());

				list<Symbol_Table_Entry*> temp_list = $3->variable_table;
				list<Symbol_Table_Entry*> arg_list = current_procedure->local_arg_table.variable_table;
				list<Symbol_Table_Entry*>::iterator it_s, it_t;
				for (it_s=arg_list.begin(),it_t=temp_list.begin();it_s!=arg_list.end() && it_t!=temp_list.end();it_s++,it_t++) {
					CHECK_INPUT((*it_s)->get_variable_name()==(*it_t)->get_variable_name(), "Variable name of one of the parameters of the procedre and its prototypes doesn't match", get_line_number());
					CHECK_INPUT((*it_s)->get_data_type()==(*it_t)->get_data_type(), "Formal parameter list of the procedure and its prototype should match", get_line_number());
				}
				CHECK_INPUT(it_s==arg_list.end() && it_t==temp_list.end(), "Procedure and its prototype parameter f_list length doens't match", get_line_number());

				program_object.procedure_list.push_back(*$1);
				defined_procedures.push_back(*$1);
				// empty basic block list
				goto_bb_num->clear();
				if (current_procedure->get_return_type() == void_data_type)
					return_statement_used_flag = true;
				else
					return_statement_used_flag = false;
			}
		}
|
	NAME '(' ')'
		{
			if (NOT_ONLY_PARSE)
			{
				CHECK_INPUT(!program_object.variable_in_symbol_list_check(*$1), "Procedure name cannot be same as global variable", get_line_number());
				current_procedure = program_object.get_procedure(*$1);	
				CHECK_INPUT(current_procedure != NULL, "Procedure corresponding to the name is not found", get_line_number());
				CHECK_INPUT(current_procedure->local_arg_table.variable_table.empty(), "Procedure and its prototype parameter f_list length doens't match", get_line_number());

				program_object.procedure_list.push_back(*$1);
				defined_procedures.push_back(*$1);
				// empty basic block num list
				goto_bb_num->clear();
				if (current_procedure->get_return_type() == void_data_type)
					return_statement_used_flag = true;
				else
					return_statement_used_flag = false;
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

function_declaration_list:
	function_declaration_list function_declaration_statement
		{
			// nothing to be done here
		}
|
	function_declaration_statement
		{
			// nothing to be done here
		}
;

function_declaration_statement:
	INTEGER NAME '(' comma_separated_declaration_list ')' ';'
		{
			if (NOT_ONLY_PARSE)
			{
				CHECK_INPUT(program_object.procedure_map.find(*$2)==program_object.procedure_map.end(), "Overloading of the procedure is not allowed", get_line_number());
				CHECK_INPUT(!$4->variable_in_symbol_list_check(*$2), "Procedure name cannot be same as formal parameter name", get_line_number());
				Procedure * new_proc = new Procedure(int_data_type, *$2, get_line_number());
				new_proc->set_arg_list(*$4);
				program_object.set_procedure_map(new_proc, get_line_number());
			}
		}
|
	FLOAT NAME '(' comma_separated_declaration_list ')' ';'
		{
			if (NOT_ONLY_PARSE)
			{
				CHECK_INPUT(program_object.procedure_map.find(*$2)==program_object.procedure_map.end(), "Overloading of the procedure is not allowed", get_line_number());
				CHECK_INPUT(!$4->variable_in_symbol_list_check(*$2), "Procedure name cannot be same as formal parameter name", get_line_number());
				Procedure * new_proc = new Procedure(float_data_type, *$2, get_line_number());
				new_proc->set_arg_list(*$4);
				program_object.set_procedure_map(new_proc, get_line_number());
			}
		}
|
	DOUBLE NAME '(' comma_separated_declaration_list ')' ';'
		{
			if (NOT_ONLY_PARSE)
			{
				CHECK_INPUT(program_object.procedure_map.find(*$2)==program_object.procedure_map.end(), "Overloading of the procedure is not allowed", get_line_number());
				CHECK_INPUT(!$4->variable_in_symbol_list_check(*$2), "Procedure name cannot be same as formal parameter name", get_line_number());
				Procedure * new_proc = new Procedure(double_data_type, *$2, get_line_number());
				new_proc->set_arg_list(*$4);
				program_object.set_procedure_map(new_proc, get_line_number());
			}
		}
|
	VOID NAME '(' comma_separated_declaration_list ')' ';'
		{
			if (NOT_ONLY_PARSE)
			{
				CHECK_INPUT(program_object.procedure_map.find(*$2)==program_object.procedure_map.end(), "Overloading of the procedure is not allowed", get_line_number());
				CHECK_INPUT(!$4->variable_in_symbol_list_check(*$2), "Procedure name cannot be same as formal parameter name", get_line_number());
				Procedure * new_proc = new Procedure(void_data_type, *$2, get_line_number());
				new_proc->set_arg_list(*$4);
				program_object.set_procedure_map(new_proc, get_line_number());
			}
		}
|
	INTEGER NAME '(' ')' ';'
		{
			if (NOT_ONLY_PARSE)
			{
				CHECK_INPUT(program_object.procedure_map.find(*$2)==program_object.procedure_map.end(), "Overloading of the procedure is not allowed", get_line_number());
				Procedure * new_proc = new Procedure(int_data_type, *$2, get_line_number());
				program_object.set_procedure_map(new_proc, get_line_number());
			}
		}
|
	FLOAT NAME '(' ')' ';'
		{
			if (NOT_ONLY_PARSE)
			{
				CHECK_INPUT(program_object.procedure_map.find(*$2)==program_object.procedure_map.end(), "Overloading of the procedure is not allowed", get_line_number());
				Procedure * new_proc = new Procedure(float_data_type, *$2, get_line_number());
				program_object.set_procedure_map(new_proc, get_line_number());
			}
		}
|
	DOUBLE NAME '(' ')' ';'
		{
			if (NOT_ONLY_PARSE)
			{
				CHECK_INPUT(program_object.procedure_map.find(*$2)==program_object.procedure_map.end(), "Overloading of the procedure is not allowed", get_line_number());
				Procedure * new_proc = new Procedure(double_data_type, *$2, get_line_number());
				program_object.set_procedure_map(new_proc, get_line_number());
			}
		}
|
	VOID NAME '(' ')' ';'
		{
			if (NOT_ONLY_PARSE)
			{
				CHECK_INPUT(program_object.procedure_map.find(*$2)==program_object.procedure_map.end(), "Overloading of the procedure is not allowed", get_line_number());
				Procedure * new_proc = new Procedure(void_data_type, *$2, get_line_number());
				program_object.set_procedure_map(new_proc, get_line_number());
			}
		}
;

comma_separated_declaration_list:
	comma_separated_declaration_list ',' func_arguement_statement
		{
			if (NOT_ONLY_PARSE)
			{
				int line = get_line_number();
				string var_name = $3->get_variable_name();
				CHECK_INPUT(!(current_procedure && current_procedure->get_proc_name() == var_name), "Variable name cannot be same as procedure name", get_line_number());
				if ($1 != NULL)
				{
					CHECK_INPUT(!$1->variable_in_symbol_list_check(var_name), "Variable is declared twice", get_line_number());
					$$ = $1;
				}
				else
					$$ = new Symbol_Table();
				$$->push_symbol($3);
			}
		}
|
	func_arguement_statement
		{
			if (NOT_ONLY_PARSE)
			{
				int line = get_line_number();
				string var_name = $1->get_variable_name();
				CHECK_INPUT(!(current_procedure && current_procedure->get_proc_name() == var_name), "Variable name cannot be same as procedure name", get_line_number());
				$$ = new Symbol_Table();
				$$->push_symbol($1);
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
				if (current_procedure==NULL) {
					program_object.set_global_table(*$$);
				}
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
				if (current_procedure==NULL) {
					program_object.set_global_table(*$$);
				}
			}
		}
;

func_arguement_statement:
	INTEGER NAME
		{
			if (NOT_ONLY_PARSE)
			{
				$$ = new Symbol_Table_Entry(*$2, int_data_type, get_line_number());
				delete $2;
			}
		}
|
	FLOAT NAME
		{
			if (NOT_ONLY_PARSE)
			{
				$$ = new Symbol_Table_Entry(*$2, float_data_type, get_line_number());
				delete $2;
			}
		}
|
	DOUBLE NAME
		{
			if (NOT_ONLY_PARSE)
			{
				$$ = new Symbol_Table_Entry(*$2, double_data_type, get_line_number());
				delete $2;
			}
		}
;

declaration_statement:
	INTEGER NAME ';'
		{
			if(NOT_ONLY_PARSE)
			{
				CHECK_INPUT(!(current_procedure && current_procedure->variable_in_arg_list_check(*$2)), "Formal parameter and local variable name cannot be same", get_line_number());
				$$ = new Symbol_Table_Entry(*$2, int_data_type, get_line_number());
				delete $2;
			}
		}
|
	FLOAT NAME ';'
		{
			if(NOT_ONLY_PARSE)
			{
				CHECK_INPUT(!(current_procedure && current_procedure->variable_in_arg_list_check(*$2)), "Formal parameter and local variable name cannot be same", get_line_number());
				$$ = new Symbol_Table_Entry(*$2, float_data_type, get_line_number());
				delete $2;
			}
		}
|
	DOUBLE NAME ';'
		{
			if(NOT_ONLY_PARSE)
			{
				CHECK_INPUT(!(current_procedure && current_procedure->variable_in_arg_list_check(*$2)), "Formal parameter and local variable name cannot be same", get_line_number());
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
|
	function_call_statement ';'
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
				switch($$->get_data_type()) {
					case int_data_type:
						if (*$2=="FLOAT") $$ = new Type_Cast_Ast($$,int_data_type,float_data_type,get_line_number());
						else if (*$2=="DOUBLE") $$ = new Type_Cast_Ast($$,int_data_type,double_data_type,get_line_number());
						break;
					case float_data_type:
						if (*$2=="INTEGER") $$ = new Type_Cast_Ast($$,float_data_type,int_data_type,get_line_number());
						break;
					case double_data_type:
						if (*$2=="INTEGER") $$ = new Type_Cast_Ast($$,double_data_type,int_data_type,get_line_number());
						break;
				}
			}
		}
|
	'(' type_name ')' identifier
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = $4;
				switch($$->get_data_type()) {
					case int_data_type:
						if (*$2=="FLOAT") $$ = new Type_Cast_Ast($$,int_data_type,float_data_type,get_line_number());
						else if (*$2=="DOUBLE") $$ = new Type_Cast_Ast($$,int_data_type,double_data_type,get_line_number());
						break;
					case float_data_type:
						if (*$2=="INTEGER") $$ = new Type_Cast_Ast($$,float_data_type,int_data_type,get_line_number());
						break;
					case double_data_type:
						if (*$2=="INTEGER") $$ = new Type_Cast_Ast($$,double_data_type,int_data_type,get_line_number());
						break;
				}
			}
		}
|
	'(' type_name ')' constant
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = $4;
				switch($$->get_data_type()) {
					case int_data_type:
						if (*$2=="FLOAT") $$ = new Type_Cast_Ast($$,int_data_type,float_data_type,get_line_number());
						else if (*$2=="DOUBLE") $$ = new Type_Cast_Ast($$,int_data_type,double_data_type,get_line_number());
						break;
					case float_data_type:
						if (*$2=="INTEGER") $$ = new Type_Cast_Ast($$,float_data_type,int_data_type,get_line_number());
						break;
					case double_data_type:
						if (*$2=="INTEGER") $$ = new Type_Cast_Ast($$,double_data_type,int_data_type,get_line_number());
						break;
				}
			}
		}
// |
// 	'(' type_name ')' function_call_statement
// 		{
// 			if (NOT_ONLY_PARSE)
// 			{
// 				$$ = $4;
// 				switch($$->get_data_type()) {
// 					case int_data_type:
// 						if (*$2=="FLOAT") $$ = new Type_Cast_Ast($$,int_data_type,float_data_type,get_line_number());
// 						else if (*$2=="DOUBLE") $$ = new Type_Cast_Ast($$,int_data_type,double_data_type,get_line_number());
// 						break;
// 					case float_data_type:
// 						if (*$2=="INTEGER") $$ = new Type_Cast_Ast($$,float_data_type,int_data_type,get_line_number());
// 						break;
// 					case double_data_type:
// 						if (*$2=="INTEGER") $$ = new Type_Cast_Ast($$,double_data_type,int_data_type,get_line_number());
// 						break;
// 				}
// 			}
// 		}
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
// |
// 	function_call_statement
// 		{
// 			if (NOT_ONLY_PARSE)
// 			{
// 				$$ = $1;
// 			}
// 		}
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
				$$ = new Negation_Expr_Ast($2, get_line_number());
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
|
	identifier ASSIGN_OP function_call_statement ';'
		{
			if (NOT_ONLY_PARSE)
			{
				$$ = new Assignment_Ast($1, $3, get_line_number());
				$$->check_ast();
			}
		}
|
	identifier ASSIGN_OP '(' type_name ')' function_call_statement ';'
		{
			if (NOT_ONLY_PARSE)
			{
				$$ = $6;
				switch($$->get_data_type()) {
					case int_data_type:
						if (*$4=="FLOAT") $$ = new Type_Cast_Ast($$,int_data_type,float_data_type,get_line_number());
						else if (*$4=="DOUBLE") $$ = new Type_Cast_Ast($$,int_data_type,double_data_type,get_line_number());
						break;
					case float_data_type:
						if (*$4=="INTEGER") $$ = new Type_Cast_Ast($$,float_data_type,int_data_type,get_line_number());
						break;
					case double_data_type:
						if (*$4=="INTEGER") $$ = new Type_Cast_Ast($$,double_data_type,int_data_type,get_line_number());
						break;
				}
				$$ = new Assignment_Ast($1, $$, get_line_number());
				$$->check_ast();
			}
		}
;

return_statement:
	RETURN ';'
		{
			if(NOT_ONLY_PARSE)
			{
				$$ = new Return_Ast(NULL, current_procedure->get_return_type(), get_line_number());
				return_statement_used_flag = true;
			}
		}
|
	RETURN  expression ';'
		{
			if (NOT_ONLY_PARSE)
			{
				CHECK_INPUT($2->get_data_type()==current_procedure->get_return_type(), "Last return statement type, of procedure, and its prototype should match", get_line_number());
				return_statement_used_flag = true;
				$$ = new Return_Ast($2,current_procedure->get_return_type(), get_line_number());
				switch ($2->get_data_type()) {
					case 1:
						$$->set_data_type("INTEGER");
						break;
					case 3:
						$$->set_data_type("FLOAT");
						break;
					case 4:
						$$->set_data_type("DOUBLE");
						break;
				}
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
				else if (current_procedure->variable_in_arg_list_check(*$1))
					var_table_entry = &(current_procedure->get_arg_table_entry(*$1));
				else if (program_object.variable_in_symbol_list_check(*$1))
					var_table_entry = &(program_object.get_symbol_table_entry(*$1));
				else
					CHECK_INVARIANT(CONTROL_SHOULD_NOT_REACH, "Variable has not been declared");
				$$ = new Name_Ast(var_name, *var_table_entry, get_line_number());
				delete $1;
			}
		}
;

function_call_statement:
	NAME '(' comma_separated_expression_list ')'
		{
			if (NOT_ONLY_PARSE)
			{
				// check if function call is valid
				Procedure * call_proc = program_object.get_procedure(*$1);
				list<Ast*> arg_list = *$3;
				list<Ast*>::iterator it_t;
				list<Symbol_Table_Entry*>::iterator it_s;
				for (it_s=call_proc->local_arg_table.variable_table.begin(),it_t=arg_list.begin();it_s!=call_proc->local_arg_table.variable_table.end() && it_t!=arg_list.end();it_t++,it_s++) {
					CHECK_INPUT((*it_t)->get_data_type() == (*it_s)->get_data_type(), "Actual and formal parameters data types are not matching", get_line_number());
				}
				CHECK_INPUT(arg_list.size()==call_proc->local_arg_table.variable_table.size(), "Actual and formal parameter count do not match", get_line_number());
				Function_Call_Ast * func = new Function_Call_Ast(*$3, get_line_number());
				func->set_name(*$1);
				switch (program_object.get_procedure(*$1)->get_return_type()) {
					case 0:
						func->set_data_type("VOID");
						break;
					case 1:
						func->set_data_type("INTEGER");
						break;
					case 3:
						func->set_data_type("FLOAT");
						break;
					case 4:
						func->set_data_type("DOUBLE");
						break;
				}
				called_procedures.push_back(*$1);
				$$ = func;
			}
		}
|
	NAME '(' ')'
		{
			if (NOT_ONLY_PARSE)
			{
				// check if function call is valid
				Procedure * call_proc = program_object.get_procedure(*$1);
				CHECK_INPUT(call_proc->local_arg_table.variable_table.empty(), "Actual and formal parameter count do not match", get_line_number());
				list<Ast*> arg_list;
				Function_Call_Ast * func = new Function_Call_Ast(arg_list, get_line_number());
				func->set_name(*$1);
				switch (program_object.get_procedure(*$1)->get_return_type()) {
					case 0:
						func->set_data_type("VOID");
						break;
					case 1:
						func->set_data_type("INTEGER");
						break;
					case 3:
						func->set_data_type("FLOAT");
						break;
					case 4:
						func->set_data_type("DOUBLE");
						break;
				}
				called_procedures.push_back(*$1);
				$$ = func;
			}
		}
;

comma_separated_expression_list:
	comma_separated_expression_list ',' expression
		{
			if (NOT_ONLY_PARSE)
			{
				$$ = $1;
				$$->push_back($3);
			}
		}
|
	expression
		{
			if (NOT_ONLY_PARSE)
			{
				$$ = new list<Ast *>;
				$$->push_back($1);
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