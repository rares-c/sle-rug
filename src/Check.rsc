module Check

import AST;
import Resolve;
import Message; // see standard library

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// The type environment consisting of defined questions in the form. qdef represents the location
// of the entire question, whereas ndef represents the location of the question's identifier.
alias TEnv = rel[loc qdef, loc ndef, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 

// Method that computes the type environment of an abstract form. Components of each regular and computed
// question are added to the type environment.
TEnv collect(AForm f) {
  TEnv t = {};
  visit(f){
  	case qs:qstn(str q, AId identifier, AType tp): t += <qs.src, identifier.src, identifier.name, q, atype2type(tp)>; 
  	case qs:qstn(str q, AId identifier, AType tp, AExpr _): t += <qs.src, identifier.src, identifier.name, q, atype2type(tp)>;
  }
  
  return t; 
}

// Method that performs a semantic check on a given abstract form. The semantic checker will look for
// the following warnings/errors:
// - Duplicate names but different types (ERROR, example: "" q0: boolean "" q0: integer)
// - Different label for the same question (WARNING, example: "" q0: boolean "Label" q0: boolean)
// - Duplicate label (WARNING, example: "label1" q0: boolean "label1" q1: integer)
// - Expression type does not match the declared type (ERROR, example: "" q0: boolean = 2)
// - Guard of if-statement not boolean (ERROR, example: if(2 + 3) { ... })
// - Reference to undeclared question (ERROR, example: "" q0: integer = q200)
// - Invalid operands applied to operator (ERROR, example: "" q0: integer = 2 * true)
set[Message] check(AForm f){
  return check(f, collect(f), resolve(f).useDef);
}

// Method that performs a semantic check on a form given its type environment and its use and defining occurrences
set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  set[str] seen = {};
  rel[str name, Type tp] seenWithTypes = {};
  rel[str name, str label, Type tp] seenLabelsTypes = {};
  set[str] seenLabels = {};
  for(<loc qdef, loc ndef, str name, str label, Type typ> <- tenv){
  	if(name in seen){ 
  	  if(<name, typ> notin seenWithTypes) {
  	  	msgs += {error("Duplicate names but different types", ndef)};  // Same name but different types.
  	  } else if (<name, label, typ> notin seenLabelsTypes){
  	  	msgs += {warning("Different label for occurrences of the same questions", qdef)};
  	  }
  	} else {
  	  seen += {name};
  	  seenWithTypes += {<name, typ>};
  	  seenLabelsTypes += {<name, label, typ>};
  	}
  	
  	if(label in seenLabels){
  	  msgs += {warning("Duplicate label", qdef)}; // Label already seen
  	} else {
  	  seenLabels += {label};
  	}
  }
  // Check each question in the form
  for(/AQuestion qs := f){
  	msgs += check(qs, tenv, useDef);
  }
  return msgs; 
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
// - check if the guard of the if statement is of type boolean

// Method that performs a semantic check on a given question.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  switch(q){
    case qstn(str _, AId _, AType tp, AExpr expr): {
    	if(check(expr, tenv, useDef) == {} && atype2type(tp) != typeOf(expr, tenv, useDef)){
    		msgs += {error("The declared type of the computed question does not match the type of the expression", q.src)};
    	}
    	msgs += check(expr, tenv, useDef);
  	}
  	case ifqstn(AExpr guard, list[AQuestion] _): {
  		if(check(guard, tenv, useDef) == {} && typeOf(guard, tenv, useDef) != tbool()){
  			msgs += {error("The guard of the if-statement is not of type boolean", q.src)};
  		}
  		msgs += check(guard, tenv, useDef);
  	}
  	case ifelqstn(AExpr guard, list[AQuestion] _, list[AQuestion] _): {
  		if(check(guard, tenv, useDef) == {} && typeOf(guard, tenv, useDef) != tbool()){
  			msgs += {error("The guard of the if-statement is not of type boolean", q.src)};
  		}
  		msgs += check(guard, tenv, useDef);
  	}
  }
  return msgs; 
}

// Method that checks the errors at a deeper level of an expression by checking both the left-hand side and the right-hand
// side of the expression.
set[Message] deepErrors(AExpr lhs, AExpr rhs, TEnv tenv, UseDef useDef){
	return check(lhs, tenv, useDef) + check(rhs, tenv, useDef);
}

// Method that checks a binary expression
set[Message] checkBinary(AExpr e, TEnv tenv, UseDef useDef) {
	set[Message] msgs = {};
	switch(e){
		case mul(AExpr lhs, AExpr rhs):{ // both lhs and rhs have to be integers
			msgs += { error("Invalid types of arguments of multiplication", e.src) | typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()};
		}
	    case div(AExpr lhs, AExpr rhs):{ // both lhs and rhs have to be integers
			msgs += { error("Invalid types of arguments of division", e.src) | typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()};
		}
	    case sum(AExpr lhs, AExpr rhs):{ // both lhs and rhs have to be integers
			msgs += { error("Invalid types of arguments of sum", e.src) | typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()};
		}
	    case sub(AExpr lhs, AExpr rhs):{ // both lhs and rhs have to be integers
			msgs += { error("Invalid types of arguments of subtraction", e.src) | typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()};
		}
	    case lt(AExpr lhs, AExpr rhs):{ // both lhs and rhs have to be integers
			msgs += { error("Invalid types of arguments of \<", e.src) | typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()};
		}
	    case leq(AExpr lhs, AExpr rhs):{ // both lhs and rhs have to be integers
			msgs += { error("Invalid types of arguments of \<=", e.src) | typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()};
		}
	    case gt(AExpr lhs, AExpr rhs):{ // both lhs and rhs have to be integers
			msgs += { error("Invalid types of arguments of \>", e.src) | typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()};
		}
	    case geq(AExpr lhs, AExpr rhs):{ // both lhs and rhs have to be integers
			msgs += { error("Invalid types of arguments of \>=", e.src) | typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()};
		}
	    case equal(AExpr lhs, AExpr rhs):{ // both lhs and rhs have to be of the same known type
			msgs += { error("Invalid types of arguments of ==", e.src) | typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) || typeOf(rhs, tenv, useDef) == tunknown()};
		}
	    case neq(AExpr lhs, AExpr rhs):{ // both lhs and rhs have to be of the same known type
	  		msgs += { error("Invalid types of arguments of !=", e.src) | typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) || typeOf(rhs, tenv, useDef) == tunknown()}; 
		}
	    case and(AExpr lhs, AExpr rhs):{ // both lhs and rhs have to be booleans
	  		msgs += { error("Invalid types of arguments of AND", e.src) | typeOf(lhs, tenv, useDef) != tbool() || typeOf(rhs, tenv, useDef) != tbool()}; 
		}
	    case or(AExpr lhs, AExpr rhs):{ // both lhs and rhs have to be booleans
	  		msgs += { error("Invalid types of arguments of OR", e.src) | typeOf(lhs, tenv, useDef) != tbool() || typeOf(rhs, tenv, useDef) != tbool()}; 
		}
	}
	return msgs;
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()

// Method that semantically checks an expression
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  switch (e) {
    case ref(AId x): // check for undeclared references
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
	case not(AExpr expr):{ // argument must be boolean
		  set[Message] deeperErrors = check(expr, tenv, useDef);
		  if(deeperErrors == {}){
		    msgs += { error("Invalid type of argument of NOT", e.src) | typeOf(expr, tenv, useDef) != tbool()};
		  }
		  msgs += deeperErrors;
	}
	case unminus(AExpr expr):{ // argument must be an integer
		  set[Message] deeperErrors = check(expr, tenv, useDef);
		  if(deeperErrors == {}){
		    msgs += { error("Invalid type of argument of unary MINUS", e.src) | typeOf(expr, tenv, useDef) != tint()};
		  }
		  msgs += deeperErrors;
	}
	case string(str _): ; // literal, nothing to check so skip
  	case integer(int _): ; // literal, nothing to check so skip
  	case boolean(bool _): ; // literal, nothing to check so skip
	default:{ // binary expression
		deeperErrors = deepErrors(e.lhs, e.rhs, tenv, useDef);
		if(deeperErrors == {}) {
			msgs += checkBinary(e, tenv, useDef);
		} else {
			msgs += deeperErrors;
		}
	}
   }
  return msgs; 
}

// Method that gets the type of a given expression. Check(AExpr) takes care of ensuring that the
// compound expressions have the same type, hence there is no need to employ this check here again.
Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  {
      if (<u, loc d> <- useDef, <_, d, _, _, Type t> <- tenv) {
        return t;
      }
    }
    case string(str _): 
    	return tstr();
    case integer(int _): 
    	return tint();
    case boolean(bool _): 
    	return tbool();
    case not(AExpr _): 
    	return tbool();
    case unminus(AExpr _): 
    	return tint();
    case mul(AExpr _, AExpr _): 
    	return tint();
    case div(AExpr _, AExpr _): 
    	return tint();
  	case sum(AExpr _, AExpr _): 
  		return tint();
  	case sub(AExpr _, AExpr _): 
  		return tint();
  	case lt(AExpr _, AExpr _): 
  		return tbool();
  	case leq(AExpr _, AExpr _): 
  		return tbool();
  	case gt(AExpr _, AExpr _): 
  		return tbool();
  	case geq(AExpr _, AExpr _): 
  		return tbool();
  	case equal(AExpr _, AExpr _): 
  		return tbool();
  	case neq(AExpr _, AExpr _): 
  		return tbool();
  	case and(AExpr _, AExpr _): 
  		return tbool();
  	case or(AExpr _, AExpr _): 
  		return tbool();
  }
  return tunknown(); 
}

// Method that maps an abstract type to a type.
Type atype2type(AType t){
  switch(t){
  	case integerType(): 
  		return tint();
  	case booleanType(): 
  		return tbool();
  	case stringType(): 
  		return tstr();
  	default: return tunknown();
  }
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

