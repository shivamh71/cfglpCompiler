<h1> cfglpCompiler </h1>
cfglp stands for Context Flow Graph Language Processor. We upgraded this tool in four steps. Each level can run independently.

<h4> Team Members </h4>
    1. Shivam H Prasad
    2. Shubham Mehta

<h4> Steps </h4>
    1. level-0-64bits -- Source code with which we started
    2. level-1-64bits -- Added parsing, ast generation, evaluation, icode and assembly code generation 
                        for Relational Operations, If-Else and Goto Operations in C
    3. level-2-64bits -- Added parsing, ast generation, evaluation, icode and assembly code generation 
                        for Arithmetic Operations and Typecast Operation in C
    4. level-3-64bits -- Added parsing, ast generation, evaluation, icode and assembly code generation 
                        for Function Calls and changed register allocation scheme to a more efficient one

Details for running the code are given in USER MANUAL and README within directory for each level.
