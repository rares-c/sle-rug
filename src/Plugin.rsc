module Plugin

import Resolve;
import ParseTree;
import Syntax;
import CST2AST;
import AST;
import Check;
import IO;


loc binary = |project://QL/examples/binary.myql|;

loc cyclic = |project://QL/examples/cyclic.myql|;

loc empty = |project://QL/examples/empty.myql|;

loc errors = |project://QL/examples/errors.myql|;

loc tax = |project://QL/examples/tax.myql|;

loc chosen = errors;


void testProgram(){
	pt = parse(#start[Form], chosen);

	ast = cst2ast(pt);
	
	for(Message m <- check(ast)){
		println(m);
	}
}

