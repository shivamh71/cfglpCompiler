
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
#include<typeinfo>

using namespace std;

#include"common-classes.hh"
#include"error-display.hh"
#include"user-options.hh"
#include"local-environment.hh"
#include"icode.hh"
#include"reg-alloc.hh"
#include"symbol-table.hh"
#include"ast.hh"
#include"basic-block.hh"
#include"procedure.hh"
#include"program.hh"

Ast::Ast()
{}

Ast::~Ast()
{}

bool Ast::check_ast()
{
	stringstream msg;
	msg << "No check_ast() function for " << typeid(*this).name();
	CHECK_INVARIANT(CONTROL_SHOULD_NOT_REACH, msg.str());
}

int Ast::get_bb_number()
{
	return bb_number;
}

Data_Type Ast::get_data_type()
{
	stringstream msg;
	msg << "No get_data_type() function for " << typeid(*this).name();
	CHECK_INVARIANT(CONTROL_SHOULD_NOT_REACH, msg.str());
}

void Ast::set_data_type(string type) {
	stringstream msg;
	msg << "No set_data_type() function for " << typeid(*this).name();
	CHECK_INVARIANT(CONTROL_SHOULD_NOT_REACH, msg.str());
}

Symbol_Table_Entry & Ast::get_symbol_entry()
{
	stringstream msg;
	msg << "No get_symbol_entry() function for " << typeid(*this).name();
	CHECK_INVARIANT(CONTROL_SHOULD_NOT_REACH, msg.str());
}

void Ast::print_value(Local_Environment & eval_env, ostream & file_buffer)
{
	stringstream msg;
	msg << "No print_value() function for " << typeid(*this).name();
	CHECK_INVARIANT(CONTROL_SHOULD_NOT_REACH, msg.str());
}

Eval_Result & Ast::get_value_of_evaluation(Local_Environment & eval_env)
{
	stringstream msg;
	msg << "No get_value_of_evaluation() function for " << typeid(*this).name();
	CHECK_INVARIANT(CONTROL_SHOULD_NOT_REACH, msg.str());
}

void Ast::set_value_of_evaluation(Local_Environment & eval_env, Eval_Result & result)
{
	stringstream msg;
	msg << "No set_value_of_evaluation() function for " << typeid(*this).name();
	CHECK_INVARIANT(CONTROL_SHOULD_NOT_REACH, msg.str());
}

Code_For_Ast & Ast::create_store_stmt(Register_Descriptor * store_register)
{
	stringstream msg;
	msg << "No create_store_stmt() function for " << typeid(*this).name();
	CHECK_INVARIANT(CONTROL_SHOULD_NOT_REACH, msg.str());
}

/****************************************************************************************************************************************/

Assignment_Ast::Assignment_Ast(Ast * temp_lhs, Ast * temp_rhs, int line)
{
	lhs = temp_lhs;
	rhs = temp_rhs;
	ast_num_child = binary_arity;
	node_data_type = void_data_type;
	lineno = line;
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

void Assignment_Ast::set_data_type(string type)
{
	if (type == "FLOAT") {
		node_data_type = float_data_type;
	}
	else if (type == "INTEGER") {

		node_data_type = int_data_type;

	}
	else if (type == "DOUBLE") {
		node_data_type = double_data_type;
	}
}

bool Assignment_Ast::check_ast()
{
	CHECK_INVARIANT((rhs != NULL), "Rhs of Assignment_Ast cannot be null");
	CHECK_INVARIANT((lhs != NULL), "Lhs of Assignment_Ast cannot be null");
	if (lhs->get_data_type() == rhs->get_data_type()) {
		node_data_type = lhs->get_data_type();
		return true;
	}
	CHECK_INVARIANT(CONTROL_SHOULD_NOT_REACH,"Assignment statement data type not compatible");
}

void Assignment_Ast::print(ostream & file_buffer)
{
	file_buffer << AST_SPACE << "Asgn:\n";

	file_buffer << AST_NODE_SPACE"LHS (";
	lhs->print(file_buffer);
	file_buffer << ")\n";

	file_buffer << AST_NODE_SPACE << "RHS (";
	rhs->print(file_buffer);
	file_buffer << ")\n";
}

Eval_Result & Assignment_Ast::evaluate(Local_Environment & eval_env, ostream & file_buffer)
{
	CHECK_INVARIANT((rhs != NULL), "Rhs of Assignment_Ast cannot be null");
	Eval_Result & result = rhs->evaluate(eval_env, file_buffer);
	CHECK_INPUT_AND_ABORT(result.is_variable_defined(), "Variable should be defined to be on rhs of Assignment_Ast", lineno);
	CHECK_INVARIANT((lhs != NULL), "Lhs of Assignment_Ast cannot be null");
	lhs->set_value_of_evaluation(eval_env, result);

	// Print the result
	file_buffer << "\n";
	print(file_buffer);
	lhs->print_value(eval_env, file_buffer);
	Eval_Result * to_return = new Eval_Result_Value_Float();
	to_return->set_value(0);
	return *to_return;
}

Code_For_Ast & Assignment_Ast::compile()
{
	CHECK_INVARIANT((lhs != NULL), "Lhs cannot be null");
	CHECK_INVARIANT((rhs != NULL), "Rhs cannot be null");

	Code_For_Ast & load_stmt = rhs->compile();

	Register_Descriptor * load_register = load_stmt.get_reg();

	Code_For_Ast store_stmt = lhs->create_store_stmt(load_register);

	// Store the statement in ic_list

	list<Icode_Stmt *> & ic_list = *new list<Icode_Stmt *>;

	if (load_stmt.get_icode_list().empty() == false)
		ic_list = load_stmt.get_icode_list();

	if (store_stmt.get_icode_list().empty() == false)
		ic_list.splice(ic_list.end(), store_stmt.get_icode_list());

	Code_For_Ast * assign_stmt;
	if (ic_list.empty() == false)
		assign_stmt = new Code_For_Ast(ic_list, load_register);

	return *assign_stmt;
}

Code_For_Ast & Assignment_Ast::compile_and_optimize_ast(Lra_Outcome & lra)
{
	CHECK_INVARIANT((lhs != NULL), "Lhs cannot be null");
	CHECK_INVARIANT((rhs != NULL), "Rhs cannot be null");

	Code_For_Ast load_stmt;
	Register_Descriptor * result_register;
	
	if ( (typeid(*rhs) == typeid(Name_Ast)) || (typeid(*rhs) == typeid(Number_Ast<int>)) || (typeid(*rhs) == typeid(Number_Ast<float>)) || (typeid(*rhs) == typeid(Number_Ast<double>)) ) {
		lra.optimize_lra(mc_2m, lhs, rhs);
		load_stmt = rhs->compile_and_optimize_ast(lra);
		result_register = load_stmt.get_reg();
	}
	else {
		load_stmt = rhs->compile_and_optimize_ast(lra);
		result_register = load_stmt.get_reg();
		Symbol_Table_Entry * destination_symbol_entry = &(lhs->get_symbol_entry());
		destination_symbol_entry->update_register(result_register);
	}

	Code_For_Ast store_stmt = lhs->create_store_stmt(result_register);

	list<Icode_Stmt *> ic_list;

	if (load_stmt.get_icode_list().empty() == false)
		ic_list = load_stmt.get_icode_list();

	if (store_stmt.get_icode_list().empty() == false)
		ic_list.splice(ic_list.end(), store_stmt.get_icode_list());

	Code_For_Ast * assign_stmt;
	if (ic_list.empty() == false)
		assign_stmt = new Code_For_Ast(ic_list, result_register);

	return *assign_stmt;
}

/****************************************************************************************************************************************/

Relational_Expr_Ast::Relational_Expr_Ast(Ast* arg_lhs, Comparator c, Ast* arg_rhs, int line) {
	lhs = arg_lhs;
	rhs = arg_rhs;
	ast_num_child = binary_arity;
	node_data_type = int_data_type;
	lineno = line;
	C = c;
}

Relational_Expr_Ast::~Relational_Expr_Ast() {
	delete lhs;
	delete rhs;
}

void Relational_Expr_Ast::print(ostream & file_buffer) {
	file_buffer << "\n";
	if (C==LTOP) file_buffer << AST_NODE_SPACE << "Condition: "<<"LT"<<"\n";
	if (C==LEOP) file_buffer << AST_NODE_SPACE << "Condition: "<<"LE"<<"\n";
	if (C==GTOP) file_buffer << AST_NODE_SPACE << "Condition: "<<"GT"<<"\n";
	if (C==GEOP) file_buffer << AST_NODE_SPACE << "Condition: "<<"GE"<<"\n";
	if (C==NEOP) file_buffer << AST_NODE_SPACE << "Condition: "<<"NE"<<"\n";
	if (C==EQOP) file_buffer << AST_NODE_SPACE << "Condition: "<<"EQ"<<"\n";
	file_buffer << AST_NODE_SPACE << "   LHS (";
	lhs->print(file_buffer);
	file_buffer << ")\n";
	file_buffer << AST_NODE_SPACE "   RHS (";
	rhs->print(file_buffer);
	file_buffer << ")";
}

Data_Type Relational_Expr_Ast::get_data_type()
{
	return node_data_type;
}

void Relational_Expr_Ast::set_data_type(string type) {
	if (type == "FLOAT") {
		node_data_type = float_data_type;
	}
	else if (type == "INTEGER") {

		node_data_type = int_data_type;

	}
	else if (type == "DOUBLE") {
		node_data_type = double_data_type;
	}
}
	
bool Relational_Expr_Ast::check_ast() {
	CHECK_INVARIANT((rhs != NULL), "Rhs of Relational_Ast cannot be null");
	CHECK_INVARIANT((lhs != NULL), "Lhs of Relational_Ast cannot be null");
	if (lhs->get_data_type() == rhs->get_data_type()) {
		node_data_type = int_data_type;
		return true;
	}
	CHECK_INVARIANT(CONTROL_SHOULD_NOT_REACH,"Relational statement data type not compatible");
}

Eval_Result & Relational_Expr_Ast::evaluate(Local_Environment & eval_env, ostream & file_buffer) {
	CHECK_INVARIANT((lhs!=NULL), "Lhs of Relational_Ast cannot be null")
	Eval_Result & result1 = lhs->evaluate(eval_env, file_buffer);
	Eval_Result* result_lhs = new Eval_Result_Value_Int();
	CHECK_INPUT_AND_ABORT(result1.is_variable_defined(),"Variable should be defined to be on lhs of condition", lineno);

	CHECK_INVARIANT((rhs!=NULL), "Rhs of Relational_Ast cannot be null")
	Eval_Result & result2 = rhs->evaluate(eval_env, file_buffer);
	Eval_Result* result_rhs = new Eval_Result_Value_Int();
	CHECK_INPUT_AND_ABORT(result1.is_variable_defined(),"Variable should be defined to be on rhs of condition", lineno);	

	result_lhs = &(result1);
	result_rhs = &(result2);
	double l = result_lhs->get_value();
	double r = result_rhs->get_value();
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
	return *result;
}

Code_For_Ast & Relational_Expr_Ast::compile() {
	CHECK_INVARIANT((lhs != NULL), "Lhs cannot be null");
	CHECK_INVARIANT((rhs != NULL), "Rhs cannot be null");

	Code_For_Ast & load_stmt1 = lhs->compile();
	Register_Descriptor * load_register1 = load_stmt1.get_reg();
	machine_dscr_object.spim_register_table[load_register1->reg_id]->used_for_expr_result = true;
	Code_For_Ast & load_stmt2 = rhs->compile();
	Register_Descriptor * load_register2 = load_stmt2.get_reg();
	machine_dscr_object.spim_register_table[load_register2->reg_id]->used_for_expr_result = true;
	Register_Descriptor * result_register = machine_dscr_object.get_new_register(int_num);
	CHECK_INVARIANT((result_register != NULL), "Result register cannot be null");
	Ics_Opd * register_opd1 = new Register_Addr_Opd(load_register1);
	Ics_Opd * register_opd2 = new Register_Addr_Opd(load_register2);
	Ics_Opd * register_opd3 = new Register_Addr_Opd(result_register);
	Icode_Stmt * comparison_stmt;

	switch (C) {
		case LEOP:
			comparison_stmt = new Compute_IC_Stmt(sle,register_opd1,register_opd2,register_opd3);
			break;
		case LTOP:
			comparison_stmt = new Compute_IC_Stmt(slt,register_opd1,register_opd2,register_opd3);
			break;
		case GEOP:
			comparison_stmt = new Compute_IC_Stmt(sge,register_opd1,register_opd2,register_opd3);
			break;
		case GTOP:
			comparison_stmt = new Compute_IC_Stmt(sgt,register_opd1,register_opd2,register_opd3);
			break;
		case EQOP:
			comparison_stmt = new Compute_IC_Stmt(seq,register_opd1,register_opd2,register_opd3);
			break;
		default:
			comparison_stmt = new Compute_IC_Stmt(sne,register_opd1,register_opd2,register_opd3);
			break;
	}

	// Store the statement in ic_list
	list<Icode_Stmt *> & ic_list = *new list<Icode_Stmt *>;

	Ics_Opd * register_opd4;
	Icode_Stmt * typecast_stmt;

	if (load_stmt1.get_icode_list().empty() == false)
		ic_list = load_stmt1.get_icode_list();
	if (load_stmt2.get_icode_list().empty() == false)
		ic_list.splice(ic_list.end(), load_stmt2.get_icode_list());
	ic_list.push_back(comparison_stmt);

	Code_For_Ast * comparison_code;
	if (ic_list.empty() == false) comparison_code = new Code_For_Ast(ic_list, result_register);
	machine_dscr_object.spim_register_table[load_register1->reg_id]->used_for_expr_result = false;
	machine_dscr_object.spim_register_table[load_register2->reg_id]->used_for_expr_result = false;
	machine_dscr_object.spim_register_table[result_register->reg_id]->used_for_expr_result = false;
	return *comparison_code;
}

Code_For_Ast & Relational_Expr_Ast::compile_and_optimize_ast(Lra_Outcome & lra)
{
	CHECK_INVARIANT((lhs != NULL), "Lhs cannot be null");
	CHECK_INVARIANT((rhs != NULL), "Rhs cannot be null");

	lra.optimize_lra(mc_2r, NULL, lhs);
	Code_For_Ast & load_stmt1 = lhs->compile_and_optimize_ast(lra);
	Register_Descriptor * load_register1 = load_stmt1.get_reg();
	machine_dscr_object.spim_register_table[load_register1->reg_id]->used_for_expr_result = true;
	
	lra.optimize_lra(mc_2r, NULL, rhs);
	Code_For_Ast & load_stmt2 = rhs->compile_and_optimize_ast(lra);
	Register_Descriptor * load_register2 = load_stmt2.get_reg();
	machine_dscr_object.spim_register_table[load_register2->reg_id]->used_for_expr_result = true;
	
	Register_Descriptor * result_register = machine_dscr_object.get_new_register(int_num);
	CHECK_INVARIANT((result_register != NULL), "Result register cannot be null");
	Ics_Opd * register_opd1 = new Register_Addr_Opd(load_register1);
	Ics_Opd * register_opd2 = new Register_Addr_Opd(load_register2);
	Ics_Opd * register_opd3 = new Register_Addr_Opd(result_register);
	Icode_Stmt * comparison_stmt;

	switch (C) {
		case LEOP:
			comparison_stmt = new Compute_IC_Stmt(sle,register_opd1,register_opd2,register_opd3);
			break;
		case LTOP:
			comparison_stmt = new Compute_IC_Stmt(slt,register_opd1,register_opd2,register_opd3);
			break;
		case GEOP:
			comparison_stmt = new Compute_IC_Stmt(sge,register_opd1,register_opd2,register_opd3);
			break;
		case GTOP:
			comparison_stmt = new Compute_IC_Stmt(sgt,register_opd1,register_opd2,register_opd3);
			break;
		case EQOP:
			comparison_stmt = new Compute_IC_Stmt(seq,register_opd1,register_opd2,register_opd3);
			break;
		default:
			comparison_stmt = new Compute_IC_Stmt(sne,register_opd1,register_opd2,register_opd3);
			break;
	}

	// Store the statement in ic_list
	list<Icode_Stmt *> & ic_list = *new list<Icode_Stmt *>;
	if (load_stmt1.get_icode_list().empty() == false)
		ic_list = load_stmt1.get_icode_list();
	if (load_stmt2.get_icode_list().empty() == false)
		ic_list.splice(ic_list.end(), load_stmt2.get_icode_list());
	ic_list.push_back(comparison_stmt);

	Code_For_Ast * comparison_code;
	if (ic_list.empty() == false) comparison_code = new Code_For_Ast(ic_list, result_register);
	machine_dscr_object.spim_register_table[load_register1->reg_id]->used_for_expr_result = false;
	machine_dscr_object.spim_register_table[load_register2->reg_id]->used_for_expr_result = false;
	machine_dscr_object.spim_register_table[result_register->reg_id]->used_for_expr_result = false;
	return *comparison_code;
}

/****************************************************************************************************************************************/

Arithmetic_Expr_Ast::Arithmetic_Expr_Ast(Ast* arg_lhs, Operator o, Ast* arg_rhs, int line) {
	lhs = arg_lhs;
	rhs = arg_rhs;
	ast_num_child = binary_arity;
	lineno = line;
	O = o;
}

Arithmetic_Expr_Ast::~Arithmetic_Expr_Ast() {
	delete lhs;
	delete rhs;
}

void Arithmetic_Expr_Ast::print(ostream & file_buffer) {
	file_buffer << "\n";
	if (O==ADD) file_buffer << AST_NODE_SPACE << "Arith: "<<"PLUS"<<"\n";
	if (O==SUB) file_buffer << AST_NODE_SPACE << "Arith: "<<"MINUS"<<"\n";
	if (O==MUL) file_buffer << AST_NODE_SPACE << "Arith: "<<"MULT"<<"\n";
	if (O==DIV) file_buffer << AST_NODE_SPACE << "Arith: "<<"DIV"<<"\n";
	file_buffer << AST_NODE_SPACE << "   LHS (";
	lhs->print(file_buffer);
	file_buffer << ")\n";
	file_buffer << AST_NODE_SPACE "   RHS (";
	rhs->print(file_buffer);
	file_buffer << ")";
}

Data_Type Arithmetic_Expr_Ast::get_data_type() {
	return node_data_type;
}

void Arithmetic_Expr_Ast::set_data_type(string type) {
	if (type == "FLOAT") {
		node_data_type = float_data_type;
	}
	else if (type == "INTEGER") {

		node_data_type = int_data_type;

	}
	else if (type == "DOUBLE") {
		node_data_type = double_data_type;
	}
}

bool Arithmetic_Expr_Ast::check_ast() {
	CHECK_INVARIANT((rhs != NULL), "Rhs of Arithmetic_Expr_Ast cannot be null");
	CHECK_INVARIANT((lhs != NULL), "Lhs of Arithmetic_Expr_Ast cannot be null");
	if (lhs->get_data_type() == rhs->get_data_type()) {
		node_data_type = lhs->get_data_type();
		return true;
	}
	CHECK_INVARIANT(CONTROL_SHOULD_NOT_REACH,"Arithmetic statement data type not compatible");
}

Eval_Result & Arithmetic_Expr_Ast::evaluate(Local_Environment & eval_env, ostream & file_buffer) {
	CHECK_INVARIANT((lhs!=NULL), "Lhs of Arithmetic_Ast cannot be null")
	Eval_Result & result1 = lhs->evaluate(eval_env, file_buffer);
	Eval_Result* result_lhs = new Eval_Result_Value_Int();
	CHECK_INPUT_AND_ABORT(result1.is_variable_defined(),"Variable should be defined to be on lhs of Arithmetic Expression", lineno);

	CHECK_INVARIANT((rhs!=NULL), "Rhs of Arithmetic_Ast cannot be null")
	Eval_Result & result2 = rhs->evaluate(eval_env, file_buffer);
	Eval_Result* result_rhs = new Eval_Result_Value_Int();
	CHECK_INPUT_AND_ABORT(result1.is_variable_defined(),"Variable should be defined to be on rhs of Arithmetic Expression", lineno);

	double ans;

	if (lhs->get_data_type() == int_data_type) {
		int temp1 = result1.get_value();
		int temp2 = result2.get_value();
		int temp;
		if (O==ADD) {
			temp = (temp1 + temp2);
		}
		else if (O==SUB) {
			temp = (temp1 - temp2);
		}
		else if (O==MUL) {
			temp = (temp1 * temp2);
		}
		else if (O==DIV) {
			CHECK_INPUT_AND_ABORT(temp2!=0,"Divide by 0",lineno);
			temp = (temp1 / temp2);
		}
		ans = temp;
	}
	else {
		double temp1 = result1.get_value();
		double temp2 = result2.get_value();
		double temp;
		if (O==ADD) {
			temp = (temp1 + temp2);
		}
		else if (O==SUB) {
			temp = (temp1 - temp2);
		}
		else if (O==MUL) {
			temp = (temp1 * temp2);
		}
		else if (O==DIV) {
			CHECK_INPUT_AND_ABORT(temp2!=0,"Divide by 0",lineno);
			temp = (temp1 / temp2);
		}
		ans = temp;
	}

	if (node_data_type == int_data_type) {
		Eval_Result * result = new Eval_Result_Value_Int();
		result->set_value(ans);
		return *result;
	}
	else if (node_data_type == float_data_type) {
		Eval_Result * result = new Eval_Result_Value_Float();
		result->set_value(ans);
		return *result;
	}
	else {
		Eval_Result * result = new Eval_Result_Value_Double();
		result->set_value(ans);
		return *result;
	}
}

Code_For_Ast & Arithmetic_Expr_Ast::compile()
{
	CHECK_INVARIANT((lhs != NULL), "Lhs cannot be null");
	CHECK_INVARIANT((rhs != NULL), "Rhs cannot be null");

	Code_For_Ast & load_stmt1 = lhs->compile();
	Register_Descriptor * load_register1 = load_stmt1.get_reg();
	machine_dscr_object.spim_register_table[load_register1->reg_id]->used_for_expr_result = true;

	Code_For_Ast & load_stmt2 = rhs->compile();
	Register_Descriptor * load_register2 = load_stmt2.get_reg();
	machine_dscr_object.spim_register_table[load_register2->reg_id]->used_for_expr_result = true;

	Register_Descriptor * result_register;
	Ics_Opd * register_opd3;

	if(node_data_type == int_data_type){
		result_register = machine_dscr_object.get_new_register(int_num);	
		register_opd3 = new Register_Addr_Opd(result_register);

	}
	else {
		result_register = machine_dscr_object.get_new_register(float_num);	
		register_opd3 = new Register_Addr_Opd(result_register);
	
	}
	CHECK_INVARIANT((result_register != NULL), "Result register cannot be null");
	Ics_Opd * register_opd1 = new Register_Addr_Opd(load_register1);
	Ics_Opd * register_opd2 = new Register_Addr_Opd(load_register2);
	Icode_Stmt * arithmetic_stmt;
	if(node_data_type == int_data_type) {
		switch (O) {
			case ADD:
				arithmetic_stmt = new Compute_IC_Stmt(add,register_opd1,register_opd2,register_opd3);
				break;
			case SUB:
				arithmetic_stmt = new Compute_IC_Stmt(sub,register_opd1,register_opd2,register_opd3);
				break;
			case MUL:
				arithmetic_stmt = new Compute_IC_Stmt(mul,register_opd1,register_opd2,register_opd3);
				break;
			case DIV:
				arithmetic_stmt = new Compute_IC_Stmt(divide,register_opd1,register_opd2,register_opd3);
				break;
		}
	} else {
		switch (O) {
			case ADD:
				arithmetic_stmt = new Compute_IC_Stmt(add_d,register_opd1,register_opd2,register_opd3);
				break;
			case SUB:
				arithmetic_stmt = new Compute_IC_Stmt(sub_d,register_opd1,register_opd2,register_opd3);
				break;
			case MUL:
				arithmetic_stmt = new Compute_IC_Stmt(mul_d,register_opd1,register_opd2,register_opd3);
				break;
			case DIV:
				arithmetic_stmt = new Compute_IC_Stmt(divide_d,register_opd1,register_opd2,register_opd3);
				break;
		}
	}

	// Store the statement in ic_list
	list<Icode_Stmt *> & ic_list = *new list<Icode_Stmt *>;
	if (load_stmt1.get_icode_list().empty() == false)
		ic_list = load_stmt1.get_icode_list();
	if (load_stmt2.get_icode_list().empty() == false)
		ic_list.splice(ic_list.end(), load_stmt2.get_icode_list());
	ic_list.push_back(arithmetic_stmt);

	Code_For_Ast * arithmetic_code;
	if (ic_list.empty() == false) arithmetic_code = new Code_For_Ast(ic_list, result_register);
	machine_dscr_object.spim_register_table[load_register1->reg_id]->used_for_expr_result = false;
	machine_dscr_object.spim_register_table[load_register2->reg_id]->used_for_expr_result = false;
	return *arithmetic_code;
}

Code_For_Ast & Arithmetic_Expr_Ast::compile_and_optimize_ast(Lra_Outcome & lra)
{
	CHECK_INVARIANT((lhs != NULL), "Lhs cannot be null");
	CHECK_INVARIANT((rhs != NULL), "Rhs cannot be null");

	lra.optimize_lra(mc_2r, NULL, lhs);
	Code_For_Ast & load_stmt1 = lhs->compile_and_optimize_ast(lra);
	Register_Descriptor * load_register1 = load_stmt1.get_reg();
	machine_dscr_object.spim_register_table[load_register1->reg_id]->used_for_expr_result = true;
	
	lra.optimize_lra(mc_2r, NULL, rhs);
	Code_For_Ast & load_stmt2 = rhs->compile_and_optimize_ast(lra);
	Register_Descriptor * load_register2 = load_stmt2.get_reg();
	machine_dscr_object.spim_register_table[load_register2->reg_id]->used_for_expr_result = true;

	Register_Descriptor * result_register;
	Ics_Opd * register_opd3;

	if(node_data_type == int_data_type){
		result_register = machine_dscr_object.get_new_register(int_num);	
		register_opd3 = new Register_Addr_Opd(result_register);

	}
	else {
		result_register = machine_dscr_object.get_new_register(float_num);	
		register_opd3 = new Register_Addr_Opd(result_register);
	
	}
	CHECK_INVARIANT((result_register != NULL), "Result register cannot be null");
	Ics_Opd * register_opd1 = new Register_Addr_Opd(load_register1);
	Ics_Opd * register_opd2 = new Register_Addr_Opd(load_register2);
	Icode_Stmt * arithmetic_stmt;
	if(node_data_type == int_data_type) {
		switch (O) {
			case ADD:
				arithmetic_stmt = new Compute_IC_Stmt(add,register_opd1,register_opd2,register_opd3);
				break;
			case SUB:
				arithmetic_stmt = new Compute_IC_Stmt(sub,register_opd1,register_opd2,register_opd3);
				break;
			case MUL:
				arithmetic_stmt = new Compute_IC_Stmt(mul,register_opd1,register_opd2,register_opd3);
				break;
			case DIV:
				arithmetic_stmt = new Compute_IC_Stmt(divide,register_opd1,register_opd2,register_opd3);
				break;
		}
	} else {
		switch (O) {
			case ADD:
				arithmetic_stmt = new Compute_IC_Stmt(add_d,register_opd1,register_opd2,register_opd3);
				break;
			case SUB:
				arithmetic_stmt = new Compute_IC_Stmt(sub_d,register_opd1,register_opd2,register_opd3);
				break;
			case MUL:
				arithmetic_stmt = new Compute_IC_Stmt(mul_d,register_opd1,register_opd2,register_opd3);
				break;
			case DIV:
				arithmetic_stmt = new Compute_IC_Stmt(divide_d,register_opd1,register_opd2,register_opd3);
				break;
		}
	}

	// Store the statement in ic_list
	list<Icode_Stmt *> & ic_list = *new list<Icode_Stmt *>;
	if (load_stmt1.get_icode_list().empty() == false)
		ic_list = load_stmt1.get_icode_list();
	if (load_stmt2.get_icode_list().empty() == false)
		ic_list.splice(ic_list.end(), load_stmt2.get_icode_list());
	ic_list.push_back(arithmetic_stmt);

	Code_For_Ast * arithmetic_code;
	if (ic_list.empty() == false) arithmetic_code = new Code_For_Ast(ic_list, result_register);
	machine_dscr_object.spim_register_table[load_register1->reg_id]->used_for_expr_result = false;
	machine_dscr_object.spim_register_table[load_register2->reg_id]->used_for_expr_result = false;
	return *arithmetic_code;
}

/****************************************************************************************************************************************/

Type_Cast_Ast::Type_Cast_Ast(Ast* arg_lhs, Data_Type old_type, Data_Type new_type, int line) {
	lhs = arg_lhs;
	lineno = line;
	ast_num_child = unary_arity;
	node_data_type = new_type;
	old_data_type = old_type;
}

void Type_Cast_Ast::print(ostream & file_buffer) {
	lhs->print(file_buffer);
}

Data_Type Type_Cast_Ast::get_data_type() {
	return node_data_type;
}

void Type_Cast_Ast::set_data_type(string type) {
	if (type == "FLOAT") {
		node_data_type = float_data_type;
	}
	else if (type == "INTEGER") {

		node_data_type = int_data_type;

	}
	else if (type == "DOUBLE") {
		node_data_type = double_data_type;
	}
}
	
bool Type_Cast_Ast::check_ast() {
	return true;
}

Eval_Result & Type_Cast_Ast::evaluate(Local_Environment & eval_env, ostream & file_buffer) {
	CHECK_INVARIANT((lhs!=NULL), "Lhs of Arithmetic_Ast cannot be null")
	Eval_Result & result1 = lhs->evaluate(eval_env, file_buffer);
	CHECK_INPUT_AND_ABORT(result1.is_variable_defined(),"Variable should be defined to be on lhs of Arithmetic Expression", lineno);
	Eval_Result * result;
	switch(node_data_type) {
		case int_data_type:
			result = new Eval_Result_Value_Int;
			result->set_value((int)result1.get_value());
			break;
		case float_data_type:
			result = new Eval_Result_Value_Float;
			result->set_value((double)result1.get_value());
			break;
		case double_data_type:
			result = new Eval_Result_Value_Double;
			result->set_value((double)result1.get_value());
			break;
	}
	return *result;
}

Type_Cast_Ast::~Type_Cast_Ast() {
	delete lhs;
}

Code_For_Ast & Type_Cast_Ast::compile()
{
	CHECK_INVARIANT((lhs != NULL), "Lhs cannot be null");
	Code_For_Ast & load_stmt1 = lhs->compile();
	Register_Descriptor * load_register1 = load_stmt1.get_reg();
	machine_dscr_object.spim_register_table[load_register1->reg_id]->used_for_expr_result = true;
	Register_Descriptor * result_register;
	Ics_Opd * register_opd2;
	Ics_Opd * register_opd3;
	Icode_Stmt * typecast_stmt;
	switch (node_data_type) {
		case int_data_type:
			register_opd2 = new Register_Addr_Opd(load_register1);
			result_register = machine_dscr_object.get_new_register(int_num);	
			register_opd3 = new Register_Addr_Opd(result_register);
			typecast_stmt = new Move_IC_Stmt(mfc1, register_opd2 , register_opd3);
			break;
		case float_data_type:
			register_opd2 = new Register_Addr_Opd(load_register1);
			result_register = machine_dscr_object.get_new_register(float_num);	
			register_opd3 = new Register_Addr_Opd(result_register);
			typecast_stmt = new Move_IC_Stmt(mtc1, register_opd2 , register_opd3);
			break;
		case double_data_type:
			register_opd2 = new Register_Addr_Opd(load_register1);
			result_register = machine_dscr_object.get_new_register(float_num);	
			register_opd3 = new Register_Addr_Opd(result_register);
			typecast_stmt = new Move_IC_Stmt(mtc1, register_opd2 , register_opd3);
			break;
		default:
			CHECK_INVARIANT(CONTROL_SHOULD_NOT_REACH,"Type_cast can be to int, float and double only");
	}
	list<Icode_Stmt *> & ic_list = *new list<Icode_Stmt *>;
	if (load_stmt1.get_icode_list().empty() == false)
		ic_list = load_stmt1.get_icode_list();
	ic_list.push_back(typecast_stmt);
	Code_For_Ast * arithmetic_code;
	if (ic_list.empty() == false) arithmetic_code = new Code_For_Ast(ic_list, result_register);
	machine_dscr_object.spim_register_table[load_register1->reg_id]->used_for_expr_result = false;
	return *arithmetic_code;
}

Code_For_Ast & Type_Cast_Ast::compile_and_optimize_ast(Lra_Outcome & lra)
{
	CHECK_INVARIANT((lhs != NULL), "Lhs cannot be null");

	lra.optimize_lra(mc_2r, NULL, lhs);
	Code_For_Ast & load_stmt1 = lhs->compile_and_optimize_ast(lra);
	Register_Descriptor * load_register1 = load_stmt1.get_reg();
	machine_dscr_object.spim_register_table[load_register1->reg_id]->used_for_expr_result = true;

	Register_Descriptor * result_register;
	Ics_Opd * register_opd2;
	Ics_Opd * register_opd3;
	Icode_Stmt * typecast_stmt;
	switch (node_data_type) {
		case int_data_type:
			register_opd2 = new Register_Addr_Opd(load_register1);
			result_register = machine_dscr_object.get_new_register(int_num);	
			register_opd3 = new Register_Addr_Opd(result_register);
			typecast_stmt = new Move_IC_Stmt(mfc1, register_opd2 , register_opd3);
			break;
		case float_data_type:
			register_opd2 = new Register_Addr_Opd(load_register1);
			result_register = machine_dscr_object.get_new_register(float_num);	
			register_opd3 = new Register_Addr_Opd(result_register);
			typecast_stmt = new Move_IC_Stmt(mtc1, register_opd2 , register_opd3);
			break;
		case double_data_type:
			register_opd2 = new Register_Addr_Opd(load_register1);
			result_register = machine_dscr_object.get_new_register(float_num);	
			register_opd3 = new Register_Addr_Opd(result_register);
			typecast_stmt = new Move_IC_Stmt(mtc1, register_opd2 , register_opd3);
			break;
		default:
			CHECK_INVARIANT(CONTROL_SHOULD_NOT_REACH,"Type_cast can be to int, float and double only");
	}

	list<Icode_Stmt *> & ic_list = *new list<Icode_Stmt *>;
	if (load_stmt1.get_icode_list().empty() == false)
		ic_list = load_stmt1.get_icode_list();
	ic_list.push_back(typecast_stmt);
	Code_For_Ast * arithmetic_code;
	if (ic_list.empty() == false) arithmetic_code = new Code_For_Ast(ic_list, result_register);
	machine_dscr_object.spim_register_table[load_register1->reg_id]->used_for_expr_result = false;
	return *arithmetic_code;
}

/****************************************************************************************************************************************/

Negation_Expr_Ast::Negation_Expr_Ast(Ast* arg_lhs, int line) {
	lhs = arg_lhs;
	lineno = line;
	ast_num_child = unary_arity;
}

void Negation_Expr_Ast::print(ostream & file_buffer) {
	file_buffer << "\n";
	file_buffer << AST_NODE_SPACE << "Arith: "<<"UMINUS"<<"\n";
	file_buffer << AST_NODE_SPACE << "   LHS (";
	lhs->print(file_buffer);
	file_buffer << ")";
}

Data_Type Negation_Expr_Ast::get_data_type() {
	return node_data_type;
}

void Negation_Expr_Ast::set_data_type(string type) {
	if (type == "FLOAT") {
		node_data_type = float_data_type;
	}
	else if (type == "INTEGER") {

		node_data_type = int_data_type;

	}
	else if (type == "DOUBLE") {
		node_data_type = double_data_type;
	}
}
	
bool Negation_Expr_Ast::check_ast() {
	return true;
}

Eval_Result & Negation_Expr_Ast::evaluate(Local_Environment & eval_env, ostream & file_buffer) {
	
	CHECK_INVARIANT((lhs!=NULL), "Lhs of Arithmetic_Ast cannot be null")
	Eval_Result & result1 = lhs->evaluate(eval_env, file_buffer);
	CHECK_INPUT_AND_ABORT(result1.is_variable_defined(),"Variable should be defined to be on lhs of Arithmetic Expression", lineno);

	Eval_Result * result;
	if (result1.get_result_enum()==0)
		result = new Eval_Result_Value_Int;
	else if (result1.get_result_enum()==3)
		result = new Eval_Result_Value_Float;
	else if (result1.get_result_enum()==4)
		result = new Eval_Result_Value_Double;
	result->set_value(-1 * result1.get_value());
	return *result;
}

Negation_Expr_Ast::~Negation_Expr_Ast() {
	delete lhs;
}

Code_For_Ast & Negation_Expr_Ast::compile()
{
	CHECK_INVARIANT((lhs != NULL), "Lhs cannot be null");

	Code_For_Ast & load_stmt1 = lhs->compile();
	Register_Descriptor * load_register1 = load_stmt1.get_reg();
	machine_dscr_object.spim_register_table[load_register1->reg_id]->used_for_expr_result = true;
	Register_Descriptor * result_register;
	Ics_Opd * register_opd2;
	Ics_Opd * register_opd3;
	Icode_Stmt * typecast_stmt;

	if(node_data_type == int_data_type){
		result_register = machine_dscr_object.get_new_register(int_num);	
		register_opd2 = new Register_Addr_Opd(result_register);

	}
	else {
		result_register = machine_dscr_object.get_new_register(float_num);	
		register_opd2 = new Register_Addr_Opd(result_register);
	
	}
	CHECK_INVARIANT((result_register != NULL), "Result register cannot be null");
	Ics_Opd * register_opd1 = new Register_Addr_Opd(load_register1);
	Icode_Stmt * negation_stmt;
	if(node_data_type == int_data_type) {
		negation_stmt = new Move_IC_Stmt(neg,register_opd1,register_opd2);
	} else {
		negation_stmt = new Move_IC_Stmt(neg_d,register_opd1,register_opd2);
	}

	// Store the statement in ic_list
	list<Icode_Stmt *> & ic_list = *new list<Icode_Stmt *>;
	if (load_stmt1.get_icode_list().empty() == false)
		ic_list = load_stmt1.get_icode_list();
	ic_list.push_back(negation_stmt);

	Code_For_Ast * arithmetic_code;
	if (ic_list.empty() == false) arithmetic_code = new Code_For_Ast(ic_list, result_register);
	machine_dscr_object.spim_register_table[load_register1->reg_id]->used_for_expr_result = false;
	return *arithmetic_code;
}

Code_For_Ast & Negation_Expr_Ast::compile_and_optimize_ast(Lra_Outcome & lra)
{
	CHECK_INVARIANT((lhs != NULL), "Lhs cannot be null");
	lra.optimize_lra(mc_2r, NULL, lhs);
	Code_For_Ast & load_stmt1 = lhs->compile_and_optimize_ast(lra);
	Register_Descriptor * load_register1 = load_stmt1.get_reg();
	machine_dscr_object.spim_register_table[load_register1->reg_id]->used_for_expr_result = true;
	Register_Descriptor * result_register;
	Ics_Opd * register_opd2;
	Ics_Opd * register_opd3;
	Icode_Stmt * typecast_stmt;

	if(node_data_type == int_data_type){
		result_register = machine_dscr_object.get_new_register(int_num);	
		register_opd2 = new Register_Addr_Opd(result_register);

	}
	else {
		result_register = machine_dscr_object.get_new_register(float_num);	
		register_opd2 = new Register_Addr_Opd(result_register);
	
	}
	CHECK_INVARIANT((result_register != NULL), "Result register cannot be null");
	Ics_Opd * register_opd1 = new Register_Addr_Opd(load_register1);
	Icode_Stmt * negation_stmt;
	if(node_data_type == int_data_type) {
		negation_stmt = new Move_IC_Stmt(neg,register_opd1,register_opd2);
	} else {
		negation_stmt = new Move_IC_Stmt(neg_d,register_opd1,register_opd2);
	}

	// Store the statement in ic_list
	list<Icode_Stmt *> & ic_list = *new list<Icode_Stmt *>;
	if (load_stmt1.get_icode_list().empty() == false)
		ic_list = load_stmt1.get_icode_list();
	ic_list.push_back(negation_stmt);

	Code_For_Ast * arithmetic_code;
	if (ic_list.empty() == false) arithmetic_code = new Code_For_Ast(ic_list, result_register);
	machine_dscr_object.spim_register_table[load_register1->reg_id]->used_for_expr_result = false;
	return *arithmetic_code;
}

/****************************************************************************************************************************************/

Goto_Ast::Goto_Ast(int bb_number, int line) {
	this->bb_number = bb_number;
	lineno = line;
	node_data_type = void_data_type;
	ast_num_child = zero_arity;
}

Goto_Ast::~Goto_Ast()
{}

Data_Type Goto_Ast::get_data_type() {
	return node_data_type;
}

void Goto_Ast::set_data_type(string type) {
	if (type == "FLOAT") {
		node_data_type = float_data_type;
	}
	else if (type == "INTEGER") {

		node_data_type = int_data_type;

	}
	else if (type == "DOUBLE") {
		node_data_type = double_data_type;
	}
}

int Goto_Ast::get_bb_number() {
	return bb_number;
}

void Goto_Ast::print(ostream & file_buffer) {
	file_buffer << AST_SPACE << "Goto statement:\n";
	file_buffer << AST_NODE_SPACE << "Successor: " << get_bb_number() << "\n";
}

Eval_Result & Goto_Ast::evaluate(Local_Environment & eval_env, ostream & file_buffer) {
	Eval_Result * result = new Eval_Result_Value_Int();
	result->set_value(bb_number);
	file_buffer << "\n";
	print(file_buffer);
	file_buffer << AST_SPACE << "GOTO (BB "<<bb_number<<")"; 
	file_buffer << "\n";
	return *result;
}

Code_For_Ast & Goto_Ast::compile()
{
	Icode_Stmt * goto_stmt = new Jump_IC_Stmt(jump,bb_number);
	list<Icode_Stmt *> & ic_list = *new list<Icode_Stmt *>;
	ic_list.push_back(goto_stmt);
	Code_For_Ast * goto_code;
	if (ic_list.empty() == false) goto_code = new Code_For_Ast(ic_list, machine_dscr_object.spim_register_table[v0]);
	return *goto_code;
}

Code_For_Ast & Goto_Ast::compile_and_optimize_ast(Lra_Outcome & lra)
{
	Icode_Stmt * goto_stmt = new Jump_IC_Stmt(jump,bb_number);
	list<Icode_Stmt *> & ic_list = *new list<Icode_Stmt *>;
	ic_list.push_back(goto_stmt);
	Code_For_Ast * goto_code;
	if (ic_list.empty() == false) goto_code = new Code_For_Ast(ic_list, machine_dscr_object.spim_register_table[v0]);
	return *goto_code;
}

/****************************************************************************************************************************************/

If_Else_Ast::If_Else_Ast(Ast* cond, Ast* true_successor, Ast* false_successor, int line) {
	this->cond = cond;
	this->true_successor = true_successor;
	this->false_successor = false_successor;
	node_data_type = void_data_type;
	ast_num_child = tri_arity;
	lineno = line;
}

If_Else_Ast::~If_Else_Ast() {
	delete cond;
	delete true_successor;
	delete false_successor;
}

void If_Else_Ast::print(ostream & file_buffer) {
	file_buffer << AST_SPACE << "If_Else statement:";
	cond->print(file_buffer);
	file_buffer << "\n";
	file_buffer << AST_NODE_SPACE << "True Successor: " << true_successor->get_bb_number();
	file_buffer << "\n";
	file_buffer << AST_NODE_SPACE << "False Successor: " << false_successor->get_bb_number();
	file_buffer << "\n";
}

Eval_Result & If_Else_Ast::evaluate(Local_Environment & eval_env, ostream & file_buffer) {
	file_buffer << "\n";
	file_buffer << AST_SPACE << "If_Else statement:";
	cond->print(file_buffer);

	CHECK_INVARIANT((cond!=NULL), "Condition of If_Else_Ast cannot be null")
	Eval_Result & result1 = cond->evaluate(eval_env, file_buffer);
	CHECK_INPUT_AND_ABORT(result1.is_variable_defined(),"Variable should be defined to be on lhs of Arithmetic Expression", lineno);

	Eval_Result* result = new Eval_Result_Value_Int();
	file_buffer << "\n";
	file_buffer << AST_NODE_SPACE << "True Successor: " << true_successor->get_bb_number();
	file_buffer << "\n";
	file_buffer << AST_NODE_SPACE << "False Successor: " << false_successor->get_bb_number();
	file_buffer << "\n";

	// print(file_buffer);

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

Code_For_Ast & If_Else_Ast::compile()
{
	CHECK_INVARIANT((cond != NULL), "Lhs cannot be null");

	Code_For_Ast & load_stmt1 = cond->compile();
	Register_Descriptor * load_register1 = load_stmt1.get_reg();
	Ics_Opd * register_opd1 = new Register_Addr_Opd(load_register1);

	Icode_Stmt * goto_stmt1 = new Jump_IC_Stmt(branch,register_opd1,true_successor->get_bb_number());
	Icode_Stmt * goto_stmt2 = new Jump_IC_Stmt(jump,false_successor->get_bb_number());

	// Store the statement in ic_list
	list<Icode_Stmt *> & ic_list = *new list<Icode_Stmt *>;
	if (load_stmt1.get_icode_list().empty() == false)
		ic_list = load_stmt1.get_icode_list();
	ic_list.push_back(goto_stmt1);
	ic_list.push_back(goto_stmt2);

	Code_For_Ast * if_else_code;
	if (ic_list.empty() == false) if_else_code = new Code_For_Ast(ic_list, load_register1);
	return *if_else_code;
}

Code_For_Ast & If_Else_Ast::compile_and_optimize_ast(Lra_Outcome & lra)
{
	CHECK_INVARIANT((cond != NULL), "Lhs cannot be null");

	Code_For_Ast & load_stmt1 = cond->compile_and_optimize_ast(lra);
	Register_Descriptor * load_register1 = load_stmt1.get_reg();
	Ics_Opd * register_opd1 = new Register_Addr_Opd(load_register1);

	Icode_Stmt * goto_stmt1 = new Jump_IC_Stmt(branch,register_opd1,true_successor->get_bb_number());
	Icode_Stmt * goto_stmt2 = new Jump_IC_Stmt(jump,false_successor->get_bb_number());

	// Store the statement in ic_list
	list<Icode_Stmt *> & ic_list = *new list<Icode_Stmt *>;
	if (load_stmt1.get_icode_list().empty() == false)
		ic_list = load_stmt1.get_icode_list();
	ic_list.push_back(goto_stmt1);
	ic_list.push_back(goto_stmt2);

	Code_For_Ast * if_else_code;
	if (ic_list.empty() == false) if_else_code = new Code_For_Ast(ic_list, load_register1);
	return *if_else_code;
}

/****************************************************************************************************************************************/

Return_Ast::Return_Ast(int line) {
	ast_num_child = zero_arity;
	node_data_type  =void_data_type;
	lineno = line;
}

Return_Ast::~Return_Ast()
{}

void Return_Ast::print(ostream & file_buffer)
{
	file_buffer << AST_SPACE << "Return <NOTHING>\n";
}

Eval_Result & Return_Ast::evaluate(Local_Environment & eval_env, ostream & file_buffer)
{
	Eval_Result & result = *new Eval_Result_Value_Int();
	file_buffer << "\n";
	print(file_buffer);

	Eval_Result * to_return = new Eval_Result_Value_Int();
	to_return->set_value(-1);

	return *to_return;
}

Code_For_Ast & Return_Ast::compile()
{
	Code_For_Ast & ret_code = *new Code_For_Ast();
	return ret_code;
}

Code_For_Ast & Return_Ast::compile_and_optimize_ast(Lra_Outcome & lra)
{
	Code_For_Ast & ret_code = *new Code_For_Ast();
	return ret_code;
}

/****************************************************************************************************************************************/

Name_Ast::Name_Ast(string & name, Symbol_Table_Entry & var_entry, int line)
{
	variable_symbol_entry = &var_entry;
	CHECK_INVARIANT((variable_symbol_entry->get_variable_name() == name), "Variable's symbol entry is not matching its name");
	ast_num_child = zero_arity;
	node_data_type = variable_symbol_entry->get_data_type();
	lineno = line;
	variable_name = variable_symbol_entry->get_variable_name();
	variable_symbol_entry->variable_data_type = node_data_type;
}

Name_Ast::~Name_Ast()
{}

Data_Type Name_Ast::get_data_type()
{
	return node_data_type;
}

void Name_Ast::set_data_type(string type) {
	if (type == "FLOAT") {
		node_data_type = float_data_type;
	}
	else if (type == "INTEGER") {

		node_data_type = int_data_type;

	}
	else if (type == "DOUBLE") {
		node_data_type = double_data_type;
	}
}

Symbol_Table_Entry & Name_Ast::get_symbol_entry()
{
	return *variable_symbol_entry;
}

void Name_Ast::print(ostream & file_buffer)
{
	file_buffer << "Name : " << variable_name;
}

void Name_Ast::print_value(Local_Environment & eval_env, ostream & file_buffer)
{
	Eval_Result * loc_var_val = eval_env.get_variable_value(variable_name);
	Eval_Result * glob_var_val = interpreter_global_table.get_variable_value(variable_name);
	file_buffer << "" << AST_SPACE << variable_name << " : ";

	if (!eval_env.is_variable_defined(variable_name) && !interpreter_global_table.is_variable_defined(variable_name))
		file_buffer << "undefined";
	else if (eval_env.is_variable_defined(variable_name) && loc_var_val != NULL)
	{
		CHECK_INVARIANT(((loc_var_val->get_result_enum() == int_result) || (loc_var_val->get_result_enum() == float_result) || (loc_var_val->get_result_enum() == double_result)) , "Result type can only be int and float");
		file_buffer << std::fixed;
		file_buffer << std::setprecision(2);
		if (node_data_type==float_data_type || node_data_type==double_data_type) {
			file_buffer << (float)loc_var_val->get_value();	
		}
		else if (node_data_type==int_data_type){
			file_buffer << (int)loc_var_val->get_value();
		}
		file_buffer << "\n";
	}
	else
	{
		CHECK_INVARIANT(((glob_var_val->get_result_enum() == int_result) || (glob_var_val->get_result_enum() == float_result) || (glob_var_val->get_result_enum() == double_result)), 
			"Result type can only be int and float");
		if (glob_var_val == NULL)
			file_buffer << "0\n";
		else {
			file_buffer << std::fixed;
			file_buffer << std::setprecision(2);
			if (node_data_type==float_data_type || node_data_type==double_data_type) {
				file_buffer << (float)glob_var_val->get_value();	
			}
			else if (node_data_type==int_data_type){
				file_buffer << (int)glob_var_val->get_value();
			}
			file_buffer << "\n";
		}
	}
	file_buffer << "\n";
}

Eval_Result & Name_Ast::get_value_of_evaluation(Local_Environment & eval_env)
{
	if (eval_env.does_variable_exist(variable_name))
	{
		CHECK_INPUT_AND_ABORT((eval_env.is_variable_defined(variable_name) == true), 
					"Variable should be defined before its use", lineno);

		Eval_Result * result = eval_env.get_variable_value(variable_name);
		return *result;
	}
	CHECK_INPUT_AND_ABORT((interpreter_global_table.is_variable_defined(variable_name) == true), "Variable should be defined before its use", lineno);

	Eval_Result * result = interpreter_global_table.get_variable_value(variable_name);
	return *result;
}

void Name_Ast::set_value_of_evaluation(Local_Environment & eval_env, Eval_Result & result)
{
	Eval_Result * i;
	if (get_data_type() == int_data_type)
	{
		i = new Eval_Result_Value_Int();
	 	i->set_value(result.get_value());
	}
	else if (get_data_type() == float_data_type)
	{
		i = new Eval_Result_Value_Float();
	 	i->set_value(result.get_value());
	}
	else if (get_data_type() == double_data_type)
	{
		i = new Eval_Result_Value_Double();
	 	i->set_value(result.get_value());
	}
	else
		CHECK_INPUT_AND_ABORT(CONTROL_SHOULD_NOT_REACH, "Type of a name can be int/float only", lineno);

	if (eval_env.does_variable_exist(variable_name))
		eval_env.put_variable_value(*i, variable_name);
	else
		interpreter_global_table.put_variable_value(*i, variable_name);
}

Eval_Result & Name_Ast::evaluate(Local_Environment & eval_env, ostream & file_buffer)
{
	return get_value_of_evaluation(eval_env);
}

Code_For_Ast & Name_Ast::compile()
{
	Ics_Opd * opd = new Mem_Addr_Opd(*variable_symbol_entry);
	Register_Descriptor * result_register;
	Ics_Opd * register_opd;
	Ics_Opd * register_opd_typed;
	Icode_Stmt * load_stmt;
	list<Icode_Stmt *> ic_list;

	if(get_data_type()==int_data_type){
		result_register = machine_dscr_object.get_new_register(int_num);
		register_opd = new Register_Addr_Opd(result_register);
		load_stmt = new Move_IC_Stmt(load, opd, register_opd);
	} else {
		result_register = machine_dscr_object.get_new_register(float_num);
		register_opd = new Register_Addr_Opd(result_register);
		load_stmt = new Move_IC_Stmt(load_d, opd, register_opd);
	}
	ic_list.push_back(load_stmt);

	Code_For_Ast & load_code = *new Code_For_Ast(ic_list, result_register);

	return load_code;
}

Code_For_Ast & Name_Ast::create_store_stmt(Register_Descriptor * store_register)
{
	CHECK_INVARIANT((store_register != NULL), "Store register cannot be null");

	Ics_Opd * register_opd = new Register_Addr_Opd(store_register);
	Ics_Opd * opd = new Mem_Addr_Opd(*variable_symbol_entry);
	Icode_Stmt * store_stmt;
	if(get_data_type()==int_data_type){
		store_stmt = new Move_IC_Stmt(store, register_opd, opd);
	} else{
		store_stmt = new Move_IC_Stmt(store_d, register_opd, opd);
	}
	if (command_options.is_do_lra_selected() == false)
		variable_symbol_entry->free_register(store_register);

	list<Icode_Stmt *> & ic_list = *new list<Icode_Stmt *>;
	ic_list.push_back(store_stmt);

	Code_For_Ast & name_code = *new Code_For_Ast(ic_list, store_register);

	return name_code;
}

Code_For_Ast & Name_Ast::compile_and_optimize_ast(Lra_Outcome & lra)
{
	list<Icode_Stmt *> & ic_list = *new list<Icode_Stmt *>;;

	bool load_needed = lra.is_load_needed();

	Register_Descriptor * result_register = lra.get_register();
	CHECK_INVARIANT((result_register != NULL), "Register cannot be null");
	Ics_Opd * register_opd = new Register_Addr_Opd(result_register);

	Icode_Stmt * load_stmt = NULL;
	if (load_needed)
	{
		Ics_Opd * opd = new Mem_Addr_Opd(*variable_symbol_entry);
		if (node_data_type == int_data_type)
			load_stmt = new Move_IC_Stmt(load, opd, register_opd);
		else
			load_stmt = new Move_IC_Stmt(load_d, opd, register_opd);
		ic_list.push_back(load_stmt);
	}

	Code_For_Ast & load_code = *new Code_For_Ast(ic_list, result_register);

	return load_code;
}

/****************************************************************************************************************************************/

template <class DATA_TYPE>
Number_Ast<DATA_TYPE>::Number_Ast(DATA_TYPE number, Data_Type constant_data_type, int line)
{
	constant = number;
	node_data_type = constant_data_type;
	ast_num_child = zero_arity;
	lineno = line;
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
void Number_Ast<DATA_TYPE>::set_data_type(string type) {
	if (type == "FLOAT") {
		node_data_type = float_data_type;
	}
	else if (type == "INTEGER") {

		node_data_type = int_data_type;

	}
	else if (type == "DOUBLE") {
		node_data_type = double_data_type;
	}
}

template <class DATA_TYPE>
void Number_Ast<DATA_TYPE>::print(ostream & file_buffer)
{
	file_buffer << std::fixed;
	file_buffer << std::setprecision(2);
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
	else if (node_data_type == float_data_type)
	{
		Eval_Result & result = *new Eval_Result_Value_Float();
		result.set_value(constant);

		return result;
	}

	else if (node_data_type == double_data_type)
	{
		Eval_Result & result = *new Eval_Result_Value_Double();
		result.set_value(constant);

		return result;
	}
}

template <class DATA_TYPE>
Code_For_Ast & Number_Ast<DATA_TYPE>::compile()
{
	Register_Descriptor * result_register;
	Ics_Opd * opd;
	Ics_Opd * load_register;
	Ics_Opd * load_register_typed;
	Icode_Stmt * typecast_stmt;

	if(node_data_type == int_data_type){
		result_register = machine_dscr_object.get_new_register(int_num);	
		opd = new Const_Opd<int>(constant);
		CHECK_INVARIANT((result_register != NULL), "Result register cannot be null");
		load_register = new Register_Addr_Opd(result_register);
	}
	else {
		result_register = machine_dscr_object.get_new_register(float_num);	
		opd = new Const_Opd<float>(constant);
		CHECK_INVARIANT((result_register != NULL), "Result register cannot be null");
		load_register = new Register_Addr_Opd(result_register);
	}
	
	Icode_Stmt * load_stmt;
	if(node_data_type == int_data_type){
		load_stmt = new Move_IC_Stmt(imm_load, opd, load_register);
	}else {
		load_stmt = new Move_IC_Stmt(imm_load_d, opd, load_register);
	}

	list<Icode_Stmt *> & ic_list = *new list<Icode_Stmt *>;
	ic_list.push_back(load_stmt);

	Code_For_Ast & num_code = *new Code_For_Ast(ic_list, result_register);

	return num_code;
}

template <class DATA_TYPE>
Code_For_Ast & Number_Ast<DATA_TYPE>::compile_and_optimize_ast(Lra_Outcome & lra)
{
	CHECK_INVARIANT((lra.get_register() != NULL), "Register assigned through optimize_lra cannot be null");
	Register_Descriptor * result_register = lra.get_register();
	Ics_Opd * load_register = new Register_Addr_Opd(result_register);
	Ics_Opd * opd;
	if (node_data_type == int_data_type)
		opd = new Const_Opd<int>(constant);
	else
		opd = new Const_Opd<float>(constant);

	Icode_Stmt * load_stmt;
	if(node_data_type == int_data_type){
		load_stmt = new Move_IC_Stmt(imm_load, opd, load_register);
	}else {
		load_stmt = new Move_IC_Stmt(imm_load_d, opd, load_register);
	}

	list<Icode_Stmt *> ic_list;
	ic_list.push_back(load_stmt);

	Code_For_Ast & num_code = *new Code_For_Ast(ic_list, result_register);

	return num_code;
}

/****************************************************************************************************************************************/

template class Number_Ast<float>;
template class Number_Ast<int>;
template class Number_Ast<double>;