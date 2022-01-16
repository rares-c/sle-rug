module Plugin

import Resolve;
import ParseTree;
import Syntax;
import CST2AST;
import AST;
import Check;
import IO;
import Eval;
import Compile;


loc binary = |project://QL/examples/binary.myql|;

loc cyclic = |project://QL/examples/cyclic.myql|;

loc empty = |project://QL/examples/empty.myql|;

loc errors = |project://QL/examples/errors.myql|;

loc tax = |project://QL/examples/tax.myql|;

loc chosen = tax;

AForm f = cst2ast(parse(#start[Form], chosen));

void main(){
	set[Message] errorsWarnings = check(f);
	bool errorsPresent = false;
	for(Message m <- errorsWarnings){
		if(error(str _, loc _) := m) errorsPresent = true;
		println(m);
	}
	if(errorsPresent) println("Errors detected. Aborting...");
	else compile(f);
}