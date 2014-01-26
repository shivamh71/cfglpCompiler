
/*********************************************************************************************

                                cfglp : A CFG Language Processor
                                --------------------------------

           About:

           Implemented   by  Tanu  Kanvar (tanu@cse.iitb.ac.in) and Uday
           Khedker    (http://www.cse.iitb.ac.in/~uday)  for the courses
           cs302+cs306: Language  Processors  (theory and  lab)  at  IIT
           Bombay.

           Release  date  Jan  15, 2013.  Copyrights  reserved  by  Uday
           Khedker. This  implemenation  has been made  available purely
           for academic purposes without any warranty of any kind.

           Documentation (functionality, manual, and design) and related
           tools are  available at http://www.cse.iitb.ac.in/~uday/cfglp


***********************************************************************************************/

%scanner ../scanner.h
%scanner-token-function d_scanner.lex()
%filenames parser
%parsefun-source parser.cc

%union 
{
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
%token RETURN INTEGER GOTO IF ELSE

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
	INTEGER NAME ';'
;



identifier:
	NAME
|
	constant
;

constant:
	INTEGER_NUMBER
;

basic_block_list:
	basic_block_list basic_block
|
	basic_block
;

basic_block:
	'<' NAME INTEGER_NUMBER '>' ':' statement_list
|
	'<' NAME INTEGER_NUMBER '>' ':' statement_list ifelse_statement	
;

basic_block:
	'<' NAME INTEGER_NUMBER '>' ':' executable_statement_list
	
;

executable_statement_list:
	assignment_statement_list
	{
	#if 0
		$$ = $1;
	#endif 
	}
|
	assignment_statement_list 
	{
	#if 0
		Ast * ret = new Return_Ast();

		return_statement_used_flag = true;					// Current procedure has an occurrence of return statement

		if ($1 != NULL)
			$$ = $1;

		else
			$$ = new list<Ast *>;

		$$->push_back(ret);
	#endif 
	}
|
	RETURN ';'
	{
	
	}
;

assignment_statement_list:
	{
	#if 0
		$$ = NULL;
	#endif 
	}
|
	assignment_statement_list assignment_statement
	{
	#if 0
		if ($1 == NULL)
			$$ = new list<Ast *>;

		else
			$$ = $1;

		$$->push_back($2);
	#endif 
	}
;

assignment_statement:
	variable '=' variable ';'
	{
	#if 0
		$$ = new Assignment_Ast($1, $3);

		int line = get_line_number();
		$$->check_ast(line);
	#endif 
	}
|
	variable '=' constant ';'
	{
	#if 0
		$$ = new Assignment_Ast($1, $3);

		int line = get_line_number();
		$$->check_ast(line);
	#endif 
	}
;

variable:
	NAME
	{
	#if 0
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
	#endif	
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
