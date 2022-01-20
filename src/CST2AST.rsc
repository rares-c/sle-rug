module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import Boolean;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return cst2ast(f); 
}

AForm cst2ast(frm: (Form) `form <Id f> { <Question* qs> }`)
  = form("<f>", [ cst2ast(q) | Question q <- qs ], src = frm@\loc);


AQuestion cst2ast(Question q) { 
  switch (q) {
  	case (Question) `{ <Question* qs> }`: return qblock([cst2ast(qstn) | Question qstn <- qs], src=q@\loc);
  	case (Question) `<Str qsn> <Id f> : <Type t>`: return qstn("<qsn>", id("<f>", src=f@\loc), cst2ast(t), src=q@\loc);
  	case (Question) `<Str qsn> <Id f> : <Type t> = <Expr e>`: return qstn("<qsn>", id("<f>", src=f@\loc), cst2ast(t), cst2ast(e), src=q@\loc);
  	case (Question) `if (<Expr guard>) { <Question* qs> }`: return ifqstn(cst2ast(guard), [cst2ast(qstn) | Question qstn <- qs], src=q@\loc);
  	case (Question) `if (<Expr guard>) { <Question* qs> } else { <Question* qs2> }`: return ifelqstn(cst2ast(guard), [cst2ast(qstn) | Question qstn <- qs], [cst2ast(qstn2) | Question qstn2 <- qs2], src=q@\loc);
  	default: throw "Unhandled question <q>";
  }
}


AExpr cst2ast(Expr e) { 
  switch (e) {
    case (Expr)`<Id x>`: return ref(id("<x>", src=x@\loc), src=x@\loc);
    case (Expr)`<Str x>`: return string("<x>"[1..-1], src=e@\loc);
    case (Expr)`<Int x>`: return integer(toInt("<x>"), src=e@\loc);
    case (Expr)`<Bool x>`: return boolean(fromString("<x>"), src=e@\loc);
    case (Expr)`(<Expr x>)`: return cst2ast(x);
    case (Expr)`!<Expr x>`: return not(cst2ast(x), src=e@\loc);
    case (Expr)`-<Expr x>`: return unminus(cst2ast(x), src=e@\loc);
    case (Expr)`<Expr lhs> * <Expr rhs>`: return mul(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> / <Expr rhs>`: return div(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> + <Expr rhs>`: return sum(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> - <Expr rhs>`: return sub(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \< <Expr rhs>`: return lt(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \<= <Expr rhs>`: return leq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \> <Expr rhs>`: return gt(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \>= <Expr rhs>`: return geq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> == <Expr rhs>`: return equal(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> != <Expr rhs>`: return neq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> && <Expr rhs>`: return and(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> || <Expr rhs>`: return or(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
  switch(t) {
    case (Type)`integer`: return integerType(src=t@\loc);
    case (Type)`boolean`: return booleanType(src=t@\loc);
    case (Type)`string`: return stringType(src=t@\loc);
    default: throw "Unhandled type <t>";
  }
}
