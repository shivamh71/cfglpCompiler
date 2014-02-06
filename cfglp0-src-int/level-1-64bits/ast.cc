
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

#include<iostream>
#include<fstream>

using namespace std;

#include"user-options.hh"
#include"error-display.hh"
#include"local-environment.hh"
#include"symbol-table.hh"
#include"ast.hh"
#include"basic-block.hh"

Ast::Ast()
{}

Ast::~Ast()
{}

bool Ast::check_ast(int line)
{
	report_internal_error("Should not reach, Ast : check_ast");
}

int Ast::get_bb_number() {
	return bb_number;
}

Data_Type Ast::get_data_type()
{
	report_internal_error("Should not reach, Ast : get_data_type");
}

void Ast::print_value(Local_Environment & eval_env, ostream & file_buffer)
{
	report_internal_error("Should not reach, Ast : print_value");
}

Eval_Result & Ast::get_value_of_evaluation(Local_Environment & eval_env)
{
	report_internal_error("Should not reach, Ast : get_value_of_evaluation");
}

void Ast::set_value_of_evaluation(Local_Environment & eval_env, Eval_Result & result)
{
	report_internal_error("Should not reach, Ast : set_value_of_evaluation");
}

/*************************************************************************************************************/
Assignment_Ast::Assignment_Ast(Ast * temp_lhs, Ast * temp_rhs)
{
	lhs = temp_lhs;
	rhs = temp_rhs;
}

Assignment_Ast::~Assignment_Ast()
{
	delete lhs;
	delete rhs;
}

Data_Type Assignment_Ast::get_data_type()
{
	return node_data_type; // whats this node data type ?
}

bool Assignment_Ast::check_ast(int line) // ??
{
	if (lhs->get_data_type() == rhs->get_data_type())
	{
		node_data_type = lhs->get_data_type();
		return true;
	}

	report_error("Assignment statement data type not compatible", line);
}

void Assignment_Ast::print_ast(ostream & file_buffer)
{
	file_buffer << AST_SPACE << "Asgn:\n";

	file_buffer << AST_NODE_SPACE"LHS (";
	lhs->print_ast(file_buffer);
	file_buffer << ")\n";

	file_buffer << AST_NODE_SPACE << "RHS (";
	rhs->print_ast(file_buffer);
	file_buffer << ")\n";
}

Eval_Result & Assignment_Ast::evaluate(Local_Environment & eval_env, ostream & file_buffer)
{
	Eval_Result & result = rhs->evaluate(eval_env, file_buffer);

	if (result.is_variable_defined() == false)
		report_error("Variable should be defined to be on rhs", NOLINE);

	lhs->set_value_of_evaluation(eval_env, result);

	// Print the result

	file_buffer << "\n";
	print_ast(file_buffer);

	lhs->print_value(eval_env, file_buffer);

	Eval_Result * to_return = new Eval_Result_Value_Int();
	to_return->set_value(0);

	return *to_return;
}
/*************************************************************************************************************/

/*************************************************************************************************************/
Relational_Expr_Ast::Relational_Expr_Ast(Ast* arg_lhs, Comparator c, Ast* arg_rhs) {
	lhs = arg_lhs;
	rhs = arg_rhs;
	C = c;
}

void Relational_Expr_Ast::print_ast(ostream & file_buffer) {
	file_buffer << "\n";
	if (C==LTOP) file_buffer << AST_NODE_SPACE << "Condition: "<<"LT"<<"\n";
	if (C==LEOP) file_buffer << AST_NODE_SPACE << "Condition: "<<"LE"<<"\n";
	if (C==GTOP) file_buffer << AST_NODE_SPACE << "Condition: "<<"GT"<<"\n";
	if (C==GEOP) file_buffer << AST_NODE_SPACE << "Condition: "<<"GE"<<"\n";
	if (C==NEOP) file_buffer << AST_NODE_SPACE << "Condition: "<<"NE"<<"\n";
	if (C==EQOP) file_buffer << AST_NODE_SPACE << "Condition: "<<"EQ"<<"\n";
	file_buffer << AST_NODE_SPACE << "   LHS (";
	lhs->print_ast(file_buffer);
	file_buffer << ")\n";
	file_buffer << AST_NODE_SPACE "   RHS (";
	rhs->print_ast(file_buffer);
	file_buffer << ")";
}

Data_Type Relational_Expr_Ast::get_data_type() {
	return node_data_type;
}
	
bool Relational_Expr_Ast::check_ast(int line) {
	if (lhs->get_data_type() == rhs->get_data_type()) {
		node_data_type = lhs->get_data_type();
		return true;
	}
	report_error("Relational statement data type not compatible", line);
}

Eval_Result & Relational_Expr_Ast::evaluate(Local_Environment & eval_env, ostream & file_buffer) {
	
	Eval_Result & result1 = lhs->evaluate(eval_env, file_buffer);

	Eval_Result* result_lhs = new Eval_Result_Value_Int();

	if (result1.is_variable_defined() == false)
		report_error("Variable should be defined to be on lhs of condition", NOLINE);

	Eval_Result & result2 = rhs->evaluate(eval_env, file_buffer);

	Eval_Result* result_rhs = new Eval_Result_Value_Int();

	if (result2.is_variable_defined() == false)
		report_error("Variable should be defined to be on rhs of condition", NOLINE);

	result_lhs = &(result1);
	result_rhs = &(result2);

	int l = result_lhs->get_value();
	int r = result_rhs->get_value();

	int ans;

	if (C==LEOP) {
		ans = (l <= r);
	}
	else if (C==LTOP) {
		ans = (l < r);
	}
	else if (C==GEOP) {
		ans = (l >= r);
	}
	else if (C==GTOP) {
		ans = (l > r);
	}
	else if (C==EQOP) {
		ans = (l==r);
	}
	else {
		ans = (l!=r);
	}



	Eval_Result * result = new Eval_Result_Value_Int();
	result->set_value(ans);

	// Print the result


	return *result;
}

Relational_Expr_Ast::~Relational_Expr_Ast() {
	delete lhs;
	delete rhs;
}

/*************************************************************************************************************/

/*************************************************************************************************************/
Arithmetic_Expr_Ast::Arithmetic_Expr_Ast(Ast* arg_lhs, Operator o, Ast* arg_rhs) {
	lhs = arg_lhs;
	rhs = arg_rhs;
	O = o;
}

void Arithmetic_Expr_Ast::print_ast(ostream & file_buffer) {
	file_buffer << AST_SPACE << "Operator: "<<O<<"\n";
	file_buffer << AST_NODE_SPACE << "LHS (";
	lhs->print_ast(file_buffer);
	file_buffer << ")\n";
	file_buffer << AST_NODE_SPACE << "RHS (";
	rhs->print_ast(file_buffer);
	file_buffer << ")\n";
}

Data_Type Arithmetic_Expr_Ast::get_data_type() {
	return node_data_type;
}
	
bool Arithmetic_Expr_Ast::check_ast(int line) {
	if (lhs->get_data_type() == rhs->get_data_type()) {
		node_data_type = lhs->get_data_type();
		return true;
	}
	report_error("Arithmetic statement data type not compatible", line);
}

Eval_Result & Arithmetic_Expr_Ast::evaluate(Local_Environment & eval_env, ostream & file_buffer) {
	
	Eval_Result *result_lhs = new Eval_Result_Value_Int(); 
	*result_lhs = lhs->evaluate(eval_env, file_buffer);

	Eval_Result *result_rhs = new Eval_Result_Value_Int(); 
	*result_rhs = rhs->evaluate(eval_env, file_buffer);

	int l = result_lhs->get_value();
	int r = result_rhs->get_value();

	int ans;

	if (O==ADD) {
		ans = (l + r);
	}
	else if (O==SUB) {
		ans = (l - r);
	}
	else if (O==MUL) {
		ans = (l * r);
	}
	else {
		ans = (l/r);
	}

	Eval_Result * result = new Eval_Result_Value_Int();
	result->set_value(ans);

	// Print the result

	print_ast(file_buffer);

	return *result;
}

Arithmetic_Expr_Ast::~Arithmetic_Expr_Ast() {
	delete lhs;
	delete rhs;
}

/*************************************************************************************************************/

/*************************************************************************************************************/
Name_Ast::Name_Ast(string & name, Symbol_Table_Entry & var_entry)
{
	variable_name = name;
	variable_symbol_entry = var_entry;
}

Name_Ast::~Name_Ast()
{}

Data_Type Name_Ast::get_data_type()
{
	return variable_symbol_entry.get_data_type();
}

void Name_Ast::print_ast(ostream & file_buffer)
{
	file_buffer << "Name : " << variable_name;
}

void Name_Ast::print_value(Local_Environment & eval_env, ostream & file_buffer)
{
	Eval_Result_Value * loc_var_val = eval_env.get_variable_value(variable_name);
	Eval_Result_Value * glob_var_val = interpreter_global_table.get_variable_value(variable_name);

	file_buffer << "" << AST_SPACE << variable_name << " : ";

	if (!eval_env.is_variable_defined(variable_name) && !interpreter_global_table.is_variable_defined(variable_name))
		file_buffer << "undefined";

	else if (eval_env.is_variable_defined(variable_name) && loc_var_val != NULL)
	{
		if (loc_var_val->get_result_enum() == int_result)
			file_buffer << loc_var_val->get_value() << "\n";
		else
			report_internal_error("Result type can only be int and float");
	}

	else
	{
		if (glob_var_val->get_result_enum() == int_result)
		{
			if (glob_var_val == NULL)
				file_buffer << "0\n";
			else
				file_buffer << glob_var_val->get_value() << "\n";
		}
		else
			report_internal_error("Result type can only be int and float");
	}
	file_buffer << "\n";
}

Eval_Result & Name_Ast::get_value_of_evaluation(Local_Environment & eval_env)
{
	if (eval_env.does_variable_exist(variable_name))
	{
		Eval_Result * result = eval_env.get_variable_value(variable_name);
		return *result;
	}

	Eval_Result * result = interpreter_global_table.get_variable_value(variable_name);
	return *result;
}

void Name_Ast::set_value_of_evaluation(Local_Environment & eval_env, Eval_Result & result)
{
	Eval_Result_Value * i;
	if (result.get_result_enum() == int_result)
	{
		i = new Eval_Result_Value_Int();
	 	i->set_value(result.get_value());
	}


	if (eval_env.does_variable_exist(variable_name))
		eval_env.put_variable_value(*i, variable_name);
	else
		interpreter_global_table.put_variable_value(*i, variable_name);
}

Eval_Result & Name_Ast::evaluate(Local_Environment & eval_env, ostream & file_buffer)
{
	return get_value_of_evaluation(eval_env);
}

/*************************************************************************************************************/
template <class DATA_TYPE>
Number_Ast<DATA_TYPE>::Number_Ast(DATA_TYPE number, Data_Type constant_data_type)
{
	constant = number;
	node_data_type = constant_data_type;
}

template <class DATA_TYPE>
Number_Ast<DATA_TYPE>::~Number_Ast()
{}

template <class DATA_TYPE>
Data_Type Number_Ast<DATA_TYPE>::get_data_type()
{
	return node_data_type;
}

template <class DATA_TYPE>
void Number_Ast<DATA_TYPE>::print_ast(ostream & file_buffer)
{
	file_buffer << "Num : " << constant;
}

template <class DATA_TYPE>
Eval_Result & Number_Ast<DATA_TYPE>::evaluate(Local_Environment & eval_env, ostream & file_buffer)
{
	if (node_data_type == int_data_type)
	{
		Eval_Result & result = *new Eval_Result_Value_Int();
		result.set_value(constant);

		return result;
	}
}
/*************************************************************************************************************/

/*************************************************************************************************************/
Goto_Ast::Goto_Ast(int bb_number) {
	this->bb_number = bb_number;
}

Goto_Ast::~Goto_Ast()
{}

Data_Type Goto_Ast::get_data_type() {
	return node_data_type;
}

int Goto_Ast::get_bb_number() {
	return bb_number;
}

void Goto_Ast::print_ast(ostream & file_buffer) {
	file_buffer << AST_SPACE << "Goto statement:\n";
	file_buffer << AST_NODE_SPACE << "Successor: " << get_bb_number() << "\n";
}

Eval_Result & Goto_Ast::evaluate(Local_Environment & eval_env, ostream & file_buffer) {
	Eval_Result * result = new Eval_Result_Value_Int();
	result->set_value(bb_number);
	file_buffer << "\n";
	print_ast(file_buffer);
	file_buffer << AST_SPACE << "GOTO (BB "<<bb_number<<")"; 
	file_buffer << "\n";
	
	return *result;
}
/*************************************************************************************************************/

/*************************************************************************************************************/
If_Else_Ast::If_Else_Ast(Ast* cond, Ast* true_successor, Ast* false_successor) {
	this->cond = cond;
	this->true_successor = true_successor;
	this->false_successor = false_successor;
}

If_Else_Ast::~If_Else_Ast() {
	delete cond;
	delete true_successor;
	delete false_successor;
}

void If_Else_Ast::print_ast(ostream & file_buffer) {
	file_buffer << AST_SPACE << "If_Else statement:";
	cond->print_ast(file_buffer);
	file_buffer << "\n";
	file_buffer << AST_NODE_SPACE << "True Successor: " << true_successor->get_bb_number();
	file_buffer << "\n";
	file_buffer << AST_NODE_SPACE << "False Successor: " << false_successor->get_bb_number();
	file_buffer << "\n";
}

Eval_Result & If_Else_Ast::evaluate(Local_Environment & eval_env, ostream & file_buffer) {
	file_buffer << "\n";
	file_buffer << AST_SPACE << "If_Else statement:";
	cond->print_ast(file_buffer);

	Eval_Result & result1 = cond->evaluate(eval_env, file_buffer);

	Eval_Result* result = new Eval_Result_Value_Int();
	file_buffer << "\n";
	file_buffer << AST_NODE_SPACE << "True Successor: " << true_successor->get_bb_number();
	file_buffer << "\n";
	file_buffer << AST_NODE_SPACE << "False Successor: " << false_successor->get_bb_number();
	file_buffer << "\n";

	// print_ast(file_buffer);

	result = &(result1);
	
	int flag = result->get_value();
	if (flag) {
		file_buffer << AST_SPACE << "Condition True : Goto (BB " << true_successor->get_bb_number() <<")";
		result->set_value(true_successor->get_bb_number());
	}
	else {
		file_buffer << AST_SPACE << "Condition False : Goto (BB " << false_successor->get_bb_number() <<")";
		result->set_value(false_successor->get_bb_number());
	}
	file_buffer<<"\n";
	return *result;
}
/*************************************************************************************************************/

/*************************************************************************************************************/
Return_Ast::Return_Ast()
{}

Return_Ast::~Return_Ast()
{}

void Return_Ast::print_ast(ostream & file_buffer)
{
	file_buffer << AST_SPACE << "Return <NOTHING>\n";
}

Eval_Result & Return_Ast::evaluate(Local_Environment & eval_env, ostream & file_buffer)
{
	Eval_Result & result = *new Eval_Result_Value_Int();
	file_buffer << "\n";
	print_ast(file_buffer);

	Eval_Result * to_return = new Eval_Result_Value_Int();
	to_return->set_value(-1);

	return *to_return;
	// return result;
}
/*************************************************************************************************************/

template class Number_Ast<int>;