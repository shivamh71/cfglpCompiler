
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
#include<iostream>
#include<iomanip>
#include<typeinfo>
#include<list>
#include "common-classes.hh"

#define AST_SPACE "         "
#define AST_NODE_SPACE "            "
#define AST_SUB_NODE_SPACE "               "

using namespace std;

class Ast;

class Ast {
protected:
	typedef enum {zero_arity = 0, unary_arity = 1, binary_arity = 2, tri_arity = 3} Ast_Arity;

	Data_Type node_data_type;

	Ast_Arity ast_num_child;

	int bb_number;

	int lineno;

	int is_constant;

public:
	Ast();
	
	~Ast();

	virtual Data_Type get_data_type();

	virtual void set_data_type(string type);

	int get_bb_number();
	
	virtual bool check_ast();

	virtual Symbol_Table_Entry & get_symbol_entry();

	virtual void print(ostream & file_buffer) = 0;
	
	virtual void print_value(Local_Environment & eval_env, ostream & file_buffer);

	virtual Eval_Result & get_value_of_evaluation(Local_Environment & eval_env);
	
	virtual void set_value_of_evaluation(Local_Environment & eval_env, Eval_Result & result);
	
	virtual Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer) = 0;

	virtual Code_For_Ast & compile() = 0;

	virtual Code_For_Ast & compile_and_optimize_ast(Lra_Outcome & lra) = 0;

	virtual Code_For_Ast & create_store_stmt(Register_Descriptor * store_register);
};

class Assignment_Ast:public Ast {
public:
	Ast * lhs;
	
	Ast * rhs;
	
	Assignment_Ast(Ast * temp_lhs, Ast * temp_rhs, int line);

	~Assignment_Ast();

	Data_Type get_data_type();

	void set_data_type(string type);
	
	bool check_ast();

	void print(ostream & file_buffer);

	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);

	Code_For_Ast & compile();

	Code_For_Ast & compile_and_optimize_ast(Lra_Outcome & lra);
};

enum Comparator {LEOP, LTOP, GEOP, GTOP, EQOP, NEOP};
class Relational_Expr_Ast:public Ast {
public:
	Ast * lhs;
	
	Ast * rhs;
	
	Comparator C;

	Relational_Expr_Ast(Ast* arg_lhs, Comparator c, Ast* arg_rhs, int line);

	~Relational_Expr_Ast();

	Data_Type get_data_type();

	void set_data_type(string type);
	
	bool check_ast();

	void print(ostream & file_buffer);

	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);

	Code_For_Ast & compile();

	Code_For_Ast & compile_and_optimize_ast(Lra_Outcome & lra);
};

enum Operator {ADD, SUB, MUL, DIV};
class Arithmetic_Expr_Ast:public Ast {
public:
	Ast * lhs;

	Ast * rhs;

	Operator O;

	Arithmetic_Expr_Ast(Ast* arg_lhs, Operator c, Ast* arg_rhs, int line);

	~Arithmetic_Expr_Ast();

	Data_Type get_data_type();

	void set_data_type(string type);
	
	bool check_ast();

	void print(ostream & file_buffer);

	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);

	Code_For_Ast & compile();

	Code_For_Ast & compile_and_optimize_ast(Lra_Outcome & lra);
};

class Type_Cast_Ast:public Ast {
public:
	Ast * lhs;

	Data_Type old_data_type;

	Type_Cast_Ast(Ast* arg_lhs, Data_Type old_type, Data_Type new_type, int line);

	~Type_Cast_Ast();

	Data_Type get_data_type();

	void set_data_type(string type);
	
	bool check_ast();

	void print(ostream & file_buffer);

	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);

	Code_For_Ast & compile();

	Code_For_Ast & compile_and_optimize_ast(Lra_Outcome & lra);
};

class Negation_Expr_Ast:public Ast {
public:
	Ast * lhs;

	Negation_Expr_Ast(Ast* arg_lhs, int line);

	~Negation_Expr_Ast();

	Data_Type get_data_type();

	void set_data_type(string type);
	
	bool check_ast();

	void print(ostream & file_buffer);

	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);

	Code_For_Ast & compile();

	Code_For_Ast & compile_and_optimize_ast(Lra_Outcome & lra);
};

class Name_Ast:public Ast {
public:
	string variable_name;

	int flag;

	Data_Type node_data_type;
	
	Symbol_Table_Entry * variable_symbol_entry;
	
	Name_Ast(string & name, Symbol_Table_Entry & var_entry, int line);

	Name_Ast(string & name, Symbol_Table_Entry & var_entry, int line, int flag);
	
	~Name_Ast();

	Data_Type get_data_type();

	void set_data_type(string type);

	Symbol_Table_Entry & get_symbol_entry();

	void print(ostream & file_buffer);

	void print_value(Local_Environment & eval_env, ostream & file_buffer);
	
	Eval_Result & get_value_of_evaluation(Local_Environment & eval_env);
	
	void set_value_of_evaluation(Local_Environment & eval_env, Eval_Result & result);
	
	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);

	Code_For_Ast & compile();
	
	Code_For_Ast & compile_and_optimize_ast(Lra_Outcome & lra);
	
	Code_For_Ast & create_store_stmt(Register_Descriptor * store_register);
};

template <class T>
class Number_Ast:public Ast {
public:
	T constant;
	
	Number_Ast(T number, Data_Type constant_data_type, int line);

	~Number_Ast();

	Data_Type get_data_type();

	void set_data_type(string type);

	void print(ostream & file_buffer);

	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);

	Code_For_Ast & compile();

	Code_For_Ast & compile_and_optimize_ast(Lra_Outcome & lra);
};


class Goto_Ast:public Ast {
public:
	Goto_Ast(int bb_number, int line);

	~Goto_Ast();

	int get_bb_number();

	Data_Type get_data_type();

	void set_data_type(string type);

	void print(ostream & file_buffer);

	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);
	
	Code_For_Ast & compile();

	Code_For_Ast & compile_and_optimize_ast(Lra_Outcome & lra);
};

class If_Else_Ast:public Ast {
public:
	Ast* cond;

	Ast* true_successor;

	Ast* false_successor;

	If_Else_Ast(Ast* cond, Ast* true_successor, Ast* false_successor, int line);

	~If_Else_Ast();

	void print(ostream & file_buffer);

	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);

	Code_For_Ast & compile();

	Code_For_Ast & compile_and_optimize_ast(Lra_Outcome & lra);
};

class Return_Ast:public Ast {
public:
	Ast* to_return;
	Data_Type function_return_type;
	string fun_name;

	Return_Ast(Ast* to_return, Data_Type T, string name, int line);

	~Return_Ast();

	Data_Type get_data_type();

	void set_data_type(string type);

	void print(ostream & file_buffer);

	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);

	Code_For_Ast & compile();

	Code_For_Ast & compile_and_optimize_ast(Lra_Outcome & lra);
};

class Function_Call_Ast:public Ast
{
public:
	string func_name;

	list<Ast*> arg_list;
	
	map<string, Eval_Result *> arg_value_table;

	Function_Call_Ast(list<Ast*> arguments, int line);
	
	~Function_Call_Ast();

	Data_Type get_data_type();

	void set_data_type(string type);

	void set_name(string name);

	void print(ostream & file_buffer);

	Eval_Result & evaluate(Local_Environment & eval_env, ostream & file_buffer);

	Code_For_Ast & compile();

	Code_For_Ast & compile_and_optimize_ast(Lra_Outcome & lra);
};

#endif
