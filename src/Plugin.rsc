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

loc chosen = errors;

AForm f = cst2ast(parse(#start[Form], chosen));

void testProgram(){
	set[Message] errorsWarnings = check(f);
	bool errorsPresent = false;
	for(Message m <- errorsWarnings){
		if(error(str _, loc _) := m) errorsPresent = true;
		println(m);
	}
	if(errorsPresent) println("Errors detected. Aborting...");
	else compile(f);
}

test bool testEvaluation() = (eval(f, input("hasMaintLoan", vbool(true)), initialEnv(f)) == ("valLoss":vstr(""),
  "hasMaintLoan":vbool(true),
  "hasSoldHouse":vbool(false),
  "privateDebt":vint(0),
  "sellingPrice":vint(0),
  "valueResidue":vint(0),
  "hasBoughtHouse":vbool(false)));
  
  test bool testEvaluation2() = (eval(f, input("hasSoldHouse", vbool(true)), initialEnv(f)) == ("valLoss":vstr("this is a test"),
  "hasMaintLoan":vbool(false),
  "hasSoldHouse":vbool(true),
  "privateDebt":vint(0),
  "sellingPrice":vint(0),
  "valueResidue":vint(0),
  "hasBoughtHouse":vbool(false)));
  
  test bool testEvaluation3() = (eval(f, input("hasBoughtHouse", vbool(false)), initialEnv(f)) == ("valLoss":vstr(""),
  "hasMaintLoan":vbool(false),
  "hasSoldHouse":vbool(false),
  "privateDebt":vint(0),
  "sellingPrice":vint(0),
  "valueResidue":vint(0),
  "hasBoughtHouse":vbool(false)));
  
  // Test whether setting a variable inside an if-statement doesn't do anything if the guard is false
  test bool testEvaluation4() = (eval(f, input("sellingPrice", vint(150)), initialEnv(f)) == ("valLoss":vstr(""),
  "hasMaintLoan":vbool(false),
  "hasSoldHouse":vbool(false),
  "privateDebt":vint(0),
  "sellingPrice":vint(0),
  "valueResidue":vint(0),
  "hasBoughtHouse":vbool(false)));

