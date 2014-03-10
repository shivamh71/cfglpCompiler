
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

#include<string>
#include<fstream>
#include<iostream>

using namespace std;

#include <stdio.h>
#include"error-display.hh"
#include"local-environment.hh"

#include"symbol-table.hh"
#include"ast.hh"
#include"basic-block.hh"
#include"procedure.hh"
#include"program.hh"
#define AST_SPACE "         "

Procedure::Procedure(Data_Type proc_return_type, string proc_name)
{
	return_type = proc_return_type;
	name = proc_name;
}

Procedure::~Procedure()
{
	list<Basic_Block *>::iterator i;
	for (i = basic_block_list.begin(); i != basic_block_list.end(); i++)
		delete (*i);
}

string Procedure::get_proc_name()
{
	return name;
}

void Procedure::set_basic_block_list(list<Basic_Block *> bb_list)
{
	basic_block_list = bb_list;
}

void Procedure::set_local_list(Symbol_Table & new_list)
{
	local_symbol_table = new_list;
	local_symbol_table.set_table_scope(local);
}

void Procedure::set_arg_list(Symbol_Table & new_list)
{
	local_arg_table = new_list;
	local_arg_table.set_table_scope(local);
}

Data_Type Procedure::get_return_type()
{
	return return_type;
}

bool Procedure::variable_in_symbol_list_check(string variable)
{
	return local_symbol_table.variable_in_symbol_list_check(variable);
}

bool Procedure::variable_in_arg_list_check(string variable)
{
	return local_arg_table.variable_in_symbol_list_check(variable);
}

Symbol_Table_Entry & Procedure::get_symbol_table_entry(string variable_name)
{
	return local_symbol_table.get_symbol_table_entry(variable_name);
}

Symbol_Table_Entry & Procedure::get_arg_table_entry(string variable_name)
{
	return local_arg_table.get_symbol_table_entry(variable_name);
}

void Procedure::print_ast(ostream & file_buffer)
{
	file_buffer << PROC_SPACE << "Procedure: "<<name << "\n";

	list<Basic_Block *>::iterator i;
	for(i = basic_block_list.begin(); i != basic_block_list.end(); i++)
		(*i)->print_bb(file_buffer);
}
	
Basic_Block & Procedure::get_start_basic_block()
{
	list<Basic_Block *>::iterator i;
	i = basic_block_list.begin();
	return **i;
}

Basic_Block * Procedure::get_next_bb(Basic_Block & current_bb)
{
	bool flag = false;

	list<Basic_Block *>::iterator i;
	for(i = basic_block_list.begin(); i != basic_block_list.end(); i++)
	{
		if((*i)->get_bb_number() == current_bb.get_bb_number())
		{
			flag = true;
			continue;
		}
		if (flag)
			return (*i);
	}
	
	return NULL;
}

Eval_Result & Procedure::evaluate(ostream & file_buffer,map<string, Eval_Result_Value *> arg_value_table)
{
	Local_Environment & eval_env = *new Local_Environment();
	local_symbol_table.create(eval_env);
	
	map<string, Eval_Result_Value *>::iterator i;

	for (i = arg_value_table.begin(); i != arg_value_table.end(); i++){
		eval_env.put_variable_value(*(*i).second, (*i).first);
	}
	Eval_Result * result = NULL;

	file_buffer <<"" PROC_SPACE << "Evaluating Procedure << " << name << " >>\n";
	file_buffer << LOC_VAR_SPACE << "Local Variables (before evaluating):\n";
	eval_env.flag = 1;
	eval_env.print(file_buffer);
	file_buffer << "\n";
	
	Basic_Block * current_bb = &(get_start_basic_block());
	while (current_bb)
	{
		result = &(current_bb->evaluate(eval_env, file_buffer));
		Eval_Result * temp = new Eval_Result_Value_Int();
		temp = result;
		int new_bb_number = temp->get_value();
		if(new_bb_number == -1){
			current_bb = NULL;	
		}
		else if (new_bb_number != 0) {
			list<Basic_Block *>::iterator i;
			for(i = basic_block_list.begin(); i != basic_block_list.end(); i++) {
				if((*i)->get_bb_number() == new_bb_number) {
					current_bb = *i;
					break;
				}
			}
		}
		else{
			current_bb = get_next_bb(*current_bb);
		}		
	}

	Eval_Result* final_return = NULL;
	// Eval_Result_Value* to_return = NULL;
	// char str[100];
	string temp_string  = "return";
	switch(return_type){
		case int_data_type:
			final_return = new Eval_Result_Value_Int();
			// to_return = new Eval_Result_Value_Int();
			final_return->set_value((int)eval_env.return_value);
			// to_return->set_value((int)eval_env.return_value);
			// eval_env.put_variable_value(*to_return, temp_string);
			break;
		case float_data_type:
			final_return = new Eval_Result_Value_Float();
			// to_return = new Eval_Result_Value_Float();
			final_return->set_value((double)eval_env.return_value);
			// to_return->set_value((double)eval_env.return_value);
			// eval_env.put_variable_value(*to_return, temp_string);
			break;
		case double_data_type:
			final_return = new Eval_Result_Value_Double();
			// to_return = new Eval_Result_Value_Double();
			final_return->set_value((double)eval_env.return_value);
			// to_return->set_value((double)eval_env.return_value);
			// eval_env.put_variable_value(*to_return, temp_string);
			break;
		default:
			final_return = new Eval_Result_Value_Int();
			break;
	}
	file_buffer << "\n\n";
	file_buffer << LOC_VAR_SPACE << "Local Variables (after evaluating) Function: << "<< name << " >>\n";
	eval_env.flag = 1;
	eval_env.print(file_buffer);

	return *final_return;
}

