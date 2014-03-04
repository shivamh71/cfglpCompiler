
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

#ifndef SYMBOL_TABLE_HH
#define SYMBOL_TABLE_HH

#include<string>
#include<list>

using namespace std;

class Symbol_Table; // table of all symbols in a scope and corresponding scope -- can be global or local

class Symbol_Table_Entry; // a single entry in symbol table -- has data type and name

// typedef for data type -- can be int or void
typedef enum
{
	void_data_type,
	int_data_type,
	bool_data_type,
	float_data_type,
	double_data_type
} Data_Type;

// typedef for variable scope -- can be global or local
typedef enum
{
	global,
	local
} Table_Scope;

class Symbol_Table {

public:

	list<Symbol_Table_Entry *> variable_table; // list to hold all symbols
	Table_Scope scope; // scope of symbols in this table

	Symbol_Table();

	~Symbol_Table();

	Table_Scope get_table_scope(); // return table scope

	void set_table_scope(Table_Scope list_scope); // sets table scope

	void push_symbol(Symbol_Table_Entry * variable); // push a symbol in list of symbols

	bool variable_in_symbol_list_check(string variable); // check if a symbol is already present in symbol list

	Symbol_Table_Entry & get_symbol_table_entry(string variable_name); // get symbol with given name

	void global_list_in_proc_map_check(int line); // ??

	void create(Local_Environment & local_global_variables_table); // ??
};

class Symbol_Table_Entry {

	string variable_name; // name of symbol
	Data_Type variable_data_type; // data type of symbol

public:

	Symbol_Table_Entry();

	Symbol_Table_Entry(string & name, Data_Type new_data_type); // overloaded constructor to create symbol with name and type

	~Symbol_Table_Entry();

	Data_Type get_data_type(); // get symbol data type

	string get_variable_name(); // get symbol name
};

#endif
