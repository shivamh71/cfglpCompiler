
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
			return_statement_used_flag = false;
		}
|
	function_declaration_list procedure_list	
		{
			return_statement_used_flag = false;
		}
|
	declaration_statement_list procedure_list
		{
			return_statement_used_flag = false;
		}
|
	procedure_list
		{
			return_statement_used_flag = false;
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
	procedure_name	
		{
			return_statement_used_flag = false;
		}
	procedure_body
		{
			// nothing to be done
		}
;

procedure_name:
	NAME '(' comma_separated_declaration_list ')'
		{
			if (program_object.variable_in_symbol_list_check(*$1)) {
				int line = get_line_number();
				report_error("Procedure name cannot be same as global variable", line);
			}
			if (*$1=="main") {
				current_procedure = new Procedure(void_data_type, *$1);
				program_object.set_procedure_map(*current_procedure);
				current_procedure = program_object.get_procedure("main");
			}
			else {
				current_procedure = program_object.get_procedure(*$1);
				if (current_procedure == NULL) {
					int line = get_line_number();
					report_error("Procedure corresponding to the name is not found", line);
				}

				// check if variables in definition are consistent with variables in declaration
				list<Symbol_Table_Entry*> temp_list = $3->variable_table;
				list<Symbol_Table_Entry*> arg_list = current_procedure->local_arg_table.variable_table;
				list<Symbol_Table_Entry*>::iterator it_s, it_t;
				for (it_s=arg_list.begin(),it_t=temp_list.begin();it_s!=arg_list.end() && it_t!=temp_list.end();it_s++,it_t++) {
					if ((*it_s)->get_variable_name()!=(*it_t)->get_variable_name()) {
						int line = get_line_number();
						report_error("Variable name of one of the parameters of the procedre and its prototypes doesn't match",line);
					}
					if ((*it_s)->get_data_type()!=(*it_t)->get_data_type()) {
						int line = get_line_number();
						report_error("Formal parameter list of the procedure and its prototype should match",line);
					}
				}
				if (!(it_s==arg_list.end() && it_t==temp_list.end())) {
					int line = get_line_number();
					report_error("Procedure and its prototype parameter f_list length doens't match",line);	
				}
				// empty basic block num list
			}
			program_object.procedure_list.push_back(*$1);
			goto_bb_num->clear();
		}
|
	NAME '(' ')'
		{
			if (program_object.variable_in_symbol_list_check(*$1)) {
				int line = get_line_number();
				report_error("Procedure name cannot be same as global variable", line);
			}
			if (*$1=="main") {
				current_procedure = new Procedure(void_data_type, *$1);
				program_object.set_procedure_map(*current_procedure);
				current_procedure = program_object.get_procedure("main");
			}
			else {
				current_procedure = program_object.get_procedure(*$1);	
			}
			if (current_procedure == NULL) {
				int line = get_line_number();
				report_error("Procedure corresponding to the name is not found", line);
			}
			if (!current_procedure->local_arg_table.variable_table.empty()) {
				int line = get_line_number();
				report_error("Procedure and its prototype parameter f_list length doens't match",line);	
			}
			program_object.procedure_list.push_back(*$1);
			// empty basic block num list
			goto_bb_num->clear();
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
			if (program_object.procedure_map.find(*$2)!=program_object.procedure_map.end()) {
				int line = get_line_number();
				report_error("Overloading of the procedure is not allowed", line);
			}
			Procedure * new_proc = new Procedure(int_data_type, *$2);
			new_proc->set_arg_list(*$4);
			program_object.set_procedure_map(*new_proc);
		}
|
	FLOAT NAME '(' comma_separated_declaration_list ')' ';'
		{
			if (program_object.procedure_map.find(*$2)!=program_object.procedure_map.end()) {
				int line = get_line_number();
				report_error("Overloading of the procedure is not allowed", line);
			}
			Procedure * new_proc = new Procedure(float_data_type, *$2);
			new_proc->set_arg_list(*$4);
			program_object.set_procedure_map(*new_proc);
		}
|
	DOUBLE NAME '(' comma_separated_declaration_list ')' ';'
		{
			if (program_object.procedure_map.find(*$2)!=program_object.procedure_map.end()) {
				int line = get_line_number();
				report_error("Overloading of the procedure is not allowed", line);
			}
			Procedure * new_proc = new Procedure(double_data_type, *$2);
			new_proc->set_arg_list(*$4);
			program_object.set_procedure_map(*new_proc);
		}
|
	VOID NAME '(' comma_separated_declaration_list ')' ';'
		{
			if (program_object.procedure_map.find(*$2)!=program_object.procedure_map.end()) {
				int line = get_line_number();
				report_error("Overloading of the procedure is not allowed", line);
			}
			Procedure * new_proc = new Procedure(void_data_type, *$2);
			new_proc->set_arg_list(*$4);
			program_object.set_procedure_map(*new_proc);
		}
|
	INTEGER NAME '(' ')' ';'
		{
			if (program_object.procedure_map.find(*$2)!=program_object.procedure_map.end()) {
				int line = get_line_number();
				report_error("Overloading of the procedure is not allowed", line);
			}
			Procedure * new_proc = new Procedure(int_data_type, *$2);
			program_object.set_procedure_map(*new_proc);
		}
|
	FLOAT NAME '(' ')' ';'
		{
			if (program_object.procedure_map.find(*$2)!=program_object.procedure_map.end()) {
				int line = get_line_number();
				report_error("Overloading of the procedure is not allowed", line);
			}
			Procedure * new_proc = new Procedure(float_data_type, *$2);
			program_object.set_procedure_map(*new_proc);
		}
|
	DOUBLE NAME '(' ')' ';'
		{
			if (program_object.procedure_map.find(*$2)!=program_object.procedure_map.end()) {
				int line = get_line_number();
				report_error("Overloading of the procedure is not allowed", line);
			}
			Procedure * new_proc = new Procedure(double_data_type, *$2);
			program_object.set_procedure_map(*new_proc);
		}
|
	VOID NAME '(' ')' ';'
		{
			if (program_object.procedure_map.find(*$2)!=program_object.procedure_map.end()) {
				int line = get_line_number();
				report_error("Overloading of the procedure is not allowed", line);
			}
			Procedure * new_proc = new Procedure(void_data_type, *$2);
			program_object.set_procedure_map(*new_proc);
		}
;

comma_separated_declaration_list:
	comma_separated_declaration_list ',' func_arguement_statement
		{
			int line = get_line_number();
			// right now this check is not required
			// program_object.variable_in_proc_map_check($2->get_variable_name(), line);

			string var_name = $3->get_variable_name();
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
			$$->push_symbol($3);
		}
|
	func_arguement_statement
		{
			int line = get_line_number();
			// right now this check is not required
			// program_object.variable_in_proc_map_check($1->get_variable_name(), line);

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

declaration_statement_list:
	declaration_statement_list declaration_statement
		{
			/*
				if declaration is local then no need to check in global list
				if declaration is global then this list is global list
			*/
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
			if (current_procedure==NULL) {
				program_object.set_global_table(*$$);
			}
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
			if (current_procedure==NULL) {
				program_object.set_global_table(*$$);
			}
		}
;

func_arguement_statement:
	INTEGER NAME
		{
			$$ = new Symbol_Table_Entry(*$2, int_data_type);
			delete $2;
		}
|
	FLOAT NAME
		{
			$$ = new Symbol_Table_Entry(*$2, float_data_type);
			delete $2;
		}
|
	DOUBLE NAME
		{
			$$ = new Symbol_Table_Entry(*$2, double_data_type);
			delete $2;
		}
;

declaration_statement:
	INTEGER NAME ';'
		{
			if (current_procedure && current_procedure->variable_in_arg_list_check(*$2)) {
				int line = get_line_number();
				report_error("Formal parameter and local variable name cannot be same", line);	
			}
			$$ = new Symbol_Table_Entry(*$2, int_data_type);
			delete $2;
		}
|
	FLOAT NAME ';'
		{
			if (current_procedure && current_procedure->variable_in_arg_list_check(*$2)) {
				int line = get_line_number();
				report_error("Formal parameter and local variable name cannot be same", line);	
			}
			$$ = new Symbol_Table_Entry(*$2, float_data_type);
			delete $2;
		}
|
	DOUBLE NAME ';'
		{
			if (current_procedure && current_procedure->variable_in_arg_list_check(*$2)) {
				int line = get_line_number();
				report_error("Formal parameter and local variable name cannot be same", line);	
			}
			$$ = new Symbol_Table_Entry(*$2, double_data_type);
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
|
	function_call_statement ';'
		{
			$$ = $1;
		}
;

ifelse_statement:
	IF '(' expression ')' goto_statement ELSE goto_statement
		{
			if (!single_var_in_expr_check) {
				int line = get_line_number();
				report_error("Cannot parse the input program",line);
			}	
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
			single_var_in_expr_check = true;
			$$ = new Relational_Expr_Ast($1,GTOP,$3);
			int line = get_line_number();
			$$->check_ast(line);
		}
|
	greater_than_expression GE arithmetic_expression
		{
			single_var_in_expr_check = true;
			$$ = new Relational_Expr_Ast($1,GEOP,$3);
			int line = get_line_number();
			$$->check_ast(line);
		}
|
	greater_than_expression LT arithmetic_expression
		{
			single_var_in_expr_check = true;
			$$ = new Relational_Expr_Ast($1,LTOP,$3);
			int line = get_line_number();
			$$->check_ast(line);
		}
|
	greater_than_expression LE arithmetic_expression
		{
			single_var_in_expr_check = true;
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
			single_var_in_expr_check = true;
			$$ = new Relational_Expr_Ast($1,EQOP,$3);
			int line = get_line_number();
			$$->check_ast(line);
		}
|
	equality_expression NE greater_than_expression
		{
			single_var_in_expr_check = true;
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
	'(' type_name ')' '(' expression ')'
		{
			$$ = $5;
			$$->set_data_type(*$2);
		}
|
	'(' type_name ')' identifier
		{
			$$ = $4;
			$$->set_data_type(*$2);
		}
|
	'(' type_name ')' constant
		{
			$$ = $4;
			$$->set_data_type(*$2);
		}
|
	'(' type_name ')' function_call_statement
		{
			$$ = $4;
			$$->set_data_type(*$2);
		}
|
	identifier
		{
			$$ = $1;
		}
|
	function_call_statement
		{
			$$ = $1;
		}
|
	constant
		{
			$$ = $1;
		}
|
	'(' expression ')'
		{
			$$ = $2;
		}
;

type_name:
	FLOAT
		{
			string *t = new string;
			*t = "FLOAT";
			$$ = t;
		}
|
	DOUBLE
		{
			string *t = new string;
			*t = "FLOAT"; // changed
			$$ = t;
		}
|
	INTEGER
		{
			string *t = new string;
			*t = "INTEGER";
			$$ = t;
		}
;

basic_expression:
	'-' unary_expression
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
|
	unary_expression
		{
			$$ = $1;
		}
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
			if (current_procedure->get_return_type()!=void_data_type) {
				int line = get_line_number();
				report_error("Return type of procedure and its prototype should match", line);
			}
			$$ = new Return_Ast(NULL);
			$$->set_data_type("VOID");
			return_statement_used_flag = true; // Current procedure has an occurrence of return statement
		}
|
	RETURN  expression ';'
		{
			if ($2->get_data_type()!=current_procedure->get_return_type()) {
				int line = get_line_number();
				report_error("Return type of procedure and its prototype should match", line);
			}
			$$ = new Return_Ast($2);
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
			return_statement_used_flag = true; // Current procedure has an occurrence of return statement
		}
;

identifier:
	NAME
		{
			Symbol_Table_Entry var_table_entry;
			if (current_procedure->variable_in_symbol_list_check(*$1)) {
				 var_table_entry = current_procedure->get_symbol_table_entry(*$1);

			}
			else if (current_procedure->variable_in_arg_list_check(*$1)) {
				var_table_entry = current_procedure->get_arg_table_entry(*$1);

			}
			else if (program_object.variable_in_symbol_list_check(*$1)) {
				var_table_entry = program_object.get_symbol_table_entry(*$1);

			}
			else {
				int line = get_line_number();
				report_error("Variable has not been declared", line);
			}
			$$ = new Name_Ast(*$1, var_table_entry);
			delete $1;
		}
;

function_call_statement:
	NAME '(' comma_separated_expression_list ')'
		{
			// check if function call is valid
			Procedure * call_proc = program_object.get_procedure(*$1);
			list<Ast*> arg_list = *$3;
			list<Ast*>::iterator it_t;
			list<Symbol_Table_Entry*>::iterator it_s;
			for (it_s=call_proc->local_arg_table.variable_table.begin(),it_t=arg_list.begin();it_s!=call_proc->local_arg_table.variable_table.end() && it_t!=arg_list.end();it_t++,it_s++) {
				if ((*it_t)->get_data_type() != (*it_s)->get_data_type()) {
					int line = get_line_number();
					report_error("Actual and formal parameters data types are not matching", line);
				}
			}
			if (arg_list.size()!=call_proc->local_arg_table.variable_table.size()) {
				int line = get_line_number();
				report_error("Actual and formal parameter count do not match", line);
			}
			Function_Call_Ast * func = new Function_Call_Ast(*$3);
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
			$$ = func;
		}
|
	NAME '(' ')'
		{
			// check if function call is valid
			Procedure * call_proc = program_object.get_procedure(*$1);
			if (!call_proc->local_arg_table.variable_table.empty()) {
				int line = get_line_number();
				report_error("Actual and formal parameter count do not match", line);
			}
			list<Ast*> arg_list;
			Function_Call_Ast * func = new Function_Call_Ast(arg_list);
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
			$$ = func;
		}
;

comma_separated_expression_list:
	comma_separated_expression_list ',' expression
		{
			$$ = $1;
			$$->push_back($3);
		}
|
	expression
		{
			$$ = new list<Ast *>;
			$$->push_back($1);
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
			$$ = new Number_Ast<float>($1, float_data_type);
		}
;