module Eval

import AST;
import Resolve;
import CST2AST;
import Syntax;
import ParseTree;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.

// Maps an abstract type to a default value. The default values are assumed to be the following:
// - 0 for integers
// - false for booleans
// - empty string "" for strings
Value atype2def(AType tp){
	switch(tp){
		case integerType(): 
            return vint(0);
		case booleanType(): 
            return vbool(false);
		case stringType(): 
            return vstr("");
		default: 
            throw("Unknown ATYPE");
	}
}

// Semantic domain for expressions (values)
data Value
    = vint(int n)
    | vbool(bool b)
    | vstr(str s)
    ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
    = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)

// Method that initialises each question to a default value in the value environment
VEnv initialEnv(AForm f) {
    VEnv venv = ();
    visit(f){
        case qstn(str _, AId identifier, AType tp): 
            venv += (identifier.name: atype2def(tp));
        case qstn(str _, AId identifier, AType tp, AExpr _): 
            venv += (identifier.name: atype2def(tp));
    }
    return venv;
}


// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
    return solve (venv) {
        venv = evalOnce(f, inp, venv);
    }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
	for(AQuestion q <- f.questions){
		venv = eval(q, inp, venv);
	}
    return venv; 
}

// Method that evaluates an abstract question
VEnv eval(AQuestion q, Input inp, VEnv venv) {
    // evaluate conditions for branching,
    // evaluate inp and computed questions to return updated VEnv
    switch(q){
        case qstn(str _, AId identifier, AType _): {
            if(identifier.name == inp.question) {
                venv[identifier.name] = inp.\value;
            }
        }
        case qstn(str _, AId identifier, AType _, AExpr expr): 
            venv[identifier.name] = eval(expr, venv);
        case ifqstn(AExpr guard, list[AQuestion] questions): {
            if(eval(guard, venv).b){
                for(AQuestion qs <- questions){
                    venv = eval(qs, inp, venv);
                }
            }
        }
        case ifelqstn(AExpr guard, list[AQuestion] tQuestions, list[AQuestion] fQuestions):{
            if(eval(guard, venv).b){
                for(AQuestion qs <- tQuestions){
                    venv = eval(qs, inp, venv);
                }
            } else {
                for(AQuestion qs <- fQuestions){
                    venv = eval(qs, inp, venv);
                }
            }
        }
        case qblock(list[AQuestion] questions):{
            for(AQuestion qs <- questions){
                venv = eval(qs, inp, venv);
            }
        }
    }
    return venv; 
}

// Method that evaluates an abstract expression
Value eval(AExpr e, VEnv venv) {
    switch (e) {
        case ref(id(str x)): 
            return venv[x];
        case string(str name): 
            return vstr(name);
        case integer(int vlue): 
            return vint(vlue);
        case boolean(bool boolean): 
            return vbool(boolean);
        case not(AExpr expr): 
            return vbool(!eval(expr, venv).b);
        case unminus(AExpr expr): 
            return vint(-1 * eval(expr, venv).n);
        case mul(AExpr lhs, AExpr rhs): 
            return vint(eval(lhs, venv).n * eval(rhs,venv).n);
        case div(AExpr lhs, AExpr rhs): 
            return vint(eval(lhs, venv).n / eval(rhs,venv).n);
        case sum(AExpr lhs, AExpr rhs): 
            return vint(eval(lhs, venv).n + eval(rhs,venv).n);
        case sub(AExpr lhs, AExpr rhs): 
            return vint(eval(lhs, venv).n - eval(rhs,venv).n);
        case lt(AExpr lhs, AExpr rhs): 
            return vbool(eval(lhs, venv).n < eval(rhs, venv).n);
        case leq(AExpr lhs, AExpr rhs): 
            return vbool(eval(lhs, venv).n <= eval(rhs, venv).n);
        case gt(AExpr lhs, AExpr rhs): 
            return vbool(eval(lhs, venv).n > eval(rhs, venv).n);
        case geq(AExpr lhs, AExpr rhs): 
            return vbool(eval(lhs, venv).n >= eval(rhs, venv).n);
        case equal(AExpr lhs, AExpr rhs): 
            return vbool(eval(lhs, venv) == eval(rhs, venv));
        case neq(AExpr lhs, AExpr rhs): 
            return vbool(eval(lhs, venv) != eval(rhs, venv));
        case and(AExpr lhs, AExpr rhs): 
            return vbool(eval(lhs, venv).b &&  eval(rhs, venv).b);
        case or(AExpr lhs, AExpr rhs): 
            return vbool(eval(lhs, venv).b ||  eval(rhs, venv).b);
        default: 
            throw "Unsupported expression <e>";
    }
}

// Test whether a boolean value is inputted correctly
test bool testEvaluation() = 
    (eval(cst2ast(parse(#start[Form], |project://QL/examples/tax.myql|)), input("hasMaintLoan", vbool(true)), initialEnv(cst2ast(parse(#start[Form], |project://QL/examples/tax.myql|))))
    == 
    ("valLoss":vstr(""),
    "hasMaintLoan":vbool(true),
    "hasSoldHouse":vbool(false),
    "privateDebt":vint(0),
    "sellingPrice":vint(0),
    "valueResidue":vint(0),
    "hasBoughtHouse":vbool(false)));
  
// Test whether the computed question Value loss is computed once the guard of the preceding if statement is true
test bool testEvaluation2() = 
    (eval(cst2ast(parse(#start[Form], |project://QL/examples/tax.myql|)), input("hasSoldHouse", vbool(true)), initialEnv(cst2ast(parse(#start[Form], |project://QL/examples/tax.myql|))))
    == 
    ("valLoss":vstr("there is no value loss"),
    "hasMaintLoan":vbool(false),
    "hasSoldHouse":vbool(true),
    "privateDebt":vint(0),
    "sellingPrice":vint(0),
    "valueResidue":vint(0),
    "hasBoughtHouse":vbool(false)));

// Test whether inputting a default value for a question doesn't change anything
test bool testEvaluation3() = 
    (eval(cst2ast(parse(#start[Form], |project://QL/examples/tax.myql|)), input("hasBoughtHouse", vbool(false)), initialEnv(cst2ast(parse(#start[Form], |project://QL/examples/tax.myql|))))
    == 
    ("valLoss":vstr(""),
    "hasMaintLoan":vbool(false),
    "hasSoldHouse":vbool(false),
    "privateDebt":vint(0),
    "sellingPrice":vint(0),
    "valueResidue":vint(0),
    "hasBoughtHouse":vbool(false)));
  
// Test whether setting a variable inside an if-statement doesn't do anything if the guard is false
test bool testEvaluation4() = 
    (eval(cst2ast(parse(#start[Form], |project://QL/examples/tax.myql|)), input("sellingPrice", vint(150)), initialEnv(cst2ast(parse(#start[Form], |project://QL/examples/tax.myql|))))
    == 
    ("valLoss":vstr(""),
    "hasMaintLoan":vbool(false),
    "hasSoldHouse":vbool(false),
    "privateDebt":vint(0),
    "sellingPrice":vint(0),
    "valueResidue":vint(0),
    "hasBoughtHouse":vbool(false)));