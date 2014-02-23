
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

#ifndef AST_HH
#define AST_HH

#include<string>

#define AST_SPACE "         "
#define AST_NODE_SPACE "            "

using namespace std;

class Ast;

class Ast {

protected:

	Data_Type node_data_type; 	// Data_Type is defined in symbol-table.hh but this file in not included here
								// rather it is included in ast.cc where node_data_type is actually used
								// here its just declared but never used
	int bb_number;

public:

	Ast();
	
	~Ast();

	// Following are pure virtual functions and hence should never be reached 

	virtual Data_Type get_data_type();

	virtual void set_data_type(string type);

	int get_bb_number();

	virtual bool check_ast(int line);

	virtual void print_ast(ostream & file_buffer) = 0;
	
	virtual void print_value(Local_Environment & eval_env, ostream & file_buffer);

	virtual Eval_Result & get_value_of_evaluation(Local_Environment & eval_env);
	
	virtual void set_value_of_evaluation(Local_Environment & eval_env, Eval_Result & result);
	
	virtual Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer) = 0;
};

class Assignment_Ast:public Ast {
	Ast * lhs;
	Ast * rhs;

public:

	Assignment_Ast(Ast * temp_lhs, Ast * temp_rhs);

	~Assignment_Ast();

	Data_Type get_data_type();

	void set_data_type(string type);
	
	bool check_ast(int line);

	void print_ast(ostream & file_buffer);

	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);
};

enum Comparator {LEOP, LTOP, GEOP, GTOP, EQOP, NEOP};

class Relational_Expr_Ast:public Ast {

public:

	Ast * lhs;
	Ast * rhs;
	Comparator C;

	Relational_Expr_Ast(Ast* arg_lhs, Comparator c, Ast* arg_rhs);

	~Relational_Expr_Ast();

	Data_Type get_data_type();

	void set_data_type(string type);
	
	bool check_ast(int line);

	void print_ast(ostream & file_buffer);

	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);
};

enum Operator {ADD, SUB, MUL, DIV};

class Arithmetic_Expr_Ast:public Ast {

public:

	Ast * lhs;
	Ast * rhs;
	Operator O;

	Arithmetic_Expr_Ast(Ast* arg_lhs, Operator c, Ast* arg_rhs);

	~Arithmetic_Expr_Ast();

	Data_Type get_data_type();

	void set_data_type(string type);
	
	bool check_ast(int line);

	void print_ast(ostream & file_buffer);

	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);
};

class Negation_Expr_Ast:public Ast {

public:

	Ast * lhs;

	Negation_Expr_Ast(Ast* arg_lhs);

	~Negation_Expr_Ast();

	Data_Type get_data_type();

	void set_data_type(string type);
	
	bool check_ast(int line);

	void print_ast(ostream & file_buffer);

	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);
};


class Name_Ast:public Ast
{
	string variable_name;
	Data_Type node_data_type;
	Symbol_Table_Entry variable_symbol_entry;

public:
	Name_Ast(string & name, Symbol_Table_Entry & var_entry);
	~Name_Ast();

	Data_Type get_data_type();

	void set_data_type(string type);

	void print_ast(ostream & file_buffer);

	void print_value(Local_Environment & eval_env, ostream & file_buffer);
	Eval_Result & get_value_of_evaluation(Local_Environment & eval_env);
	void set_value_of_evaluation(Local_Environment & eval_env, Eval_Result & result);
	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);
};

template <class T>
class Number_Ast:public Ast
{
	T constant;

public:
	Number_Ast(T number, Data_Type constant_data_type);
	~Number_Ast();

	Data_Type get_data_type();

	void set_data_type(string type);

	void print_ast(ostream & file_buffer);

	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);
};


class Goto_Ast:public Ast {

public:

	Goto_Ast(int bb_number);

	~Goto_Ast();

	int get_bb_number();

	Data_Type get_data_type();

	void set_data_type(string type);

	void print_ast(ostream & file_buffer);

	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);
	
};

class If_Else_Ast:public Ast
{

	Ast* cond;
	Ast* true_successor;
	Ast* false_successor;

public:
	If_Else_Ast(Ast* cond, Ast* true_successor, Ast* false_successor);
	~If_Else_Ast();

	void print_ast(ostream & file_buffer);

	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);
};

class Return_Ast:public Ast
{

public:
	Return_Ast();
	~Return_Ast();

	void print_ast(ostream & file_buffer);

	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);
};

#endif
