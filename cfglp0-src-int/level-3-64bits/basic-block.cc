
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

using namespace std;

#include"local-environment.hh"
#include"error-display.hh"
#include"user-options.hh"

#include"symbol-table.hh"
#include"ast.hh"
#include"basic-block.hh"

Basic_Block::Basic_Block(int basic_block_number, list<Ast *> & ast_list)
{
	id_number = basic_block_number;
	statement_list = ast_list;
}

Basic_Block::~Basic_Block()
{
	list<Ast *>::iterator i;
	for (i = statement_list.begin(); i != statement_list.end(); i++)
		delete (*i);
}

int Basic_Block::get_bb_number()
{
	return id_number;
}

void Basic_Block::print_bb(ostream & file_buffer)
{
	file_buffer << endl << BB_SPACE << "Basic_Block " << id_number;

	list<Ast *>::iterator i;
	for(i = statement_list.begin(); i != statement_list.end(); i++)
		(*i)->print_ast(file_buffer);

	if (!get_has_successor())
  {
    report_internal_error("Atleast one of true, false, direct successors should be set");
  }
}

Eval_Result & Basic_Block::evaluate(Local_Environment & eval_env, ostream & file_buffer)
{
	Eval_Result * result = new Eval_Result_Value_Int();

	file_buffer << "\n" << BB_SPACE << "Basic Block: " << id_number << "\n";
	if (statement_list.size()==0) return *result;
	list <Ast *>::iterator i;
	for (i = statement_list.begin(); i != statement_list.end(); i++)
	{
		if((*i) == NULL)
			report_error ("Ast pointer seems to be NULL", NOLINE);

		result = &((*i)->evaluate(eval_env, file_buffer)); 
	}

	if (!get_has_successor())
  {
    report_internal_error("Atleast one of true, false, direct successors should be set");
  }
	return *result;

}

void Basic_Block::set_has_successor(bool check_successor){
	has_successor = check_successor;
}
bool Basic_Block::get_has_successor(){
	return has_successor;
}