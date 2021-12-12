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

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc qdef, loc ndef, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  TEnv t = {};
  visit(f){
  	case qs:qstn(str q, AId identifier, AType tp): t += <qs.src, identifier.src, identifier.name, q, atype2type(tp)>; 
  	case qs:qstn(str q, AId identifier, AType tp, AExpr _): t += <qs.src, identifier.src, identifier.name, q, atype2type(tp)>;
  }
  
  return t; 
}

set[Message] check(AForm f){
  return check(f, collect(f), resolve(f).useDef);
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  set[str] seen = {};
  rel[str name, Type tp] seenWithTypes = {};
  rel[str name, str label, Type tp] seenLabelsTypes = {};
  set[str] seenLabels = {};
  
  for(<loc qdef, loc ndef, str name, str label, Type typ> <- tenv){
  	if(name in seen){ 
  	  if(<name, typ> notin seenWithTypes) {
  	  	msgs += {error("Duplicate names but different types", ndef)};  // same name but different types.
  	  } else if (<name, label, typ> notin seenLabelsTypes){
  	  	msgs += {warning("Different label for occurrences of the same questions", qdef)};
  	  }
  	} else {
  	  seen += {name};
  	  seenWithTypes += {<name, typ>};
  	  seenLabelsTypes += {<name, label, typ>};
  	}
  	
  	if(label in seenLabels){ // label already seen
  	  msgs += {warning("Duplicate label", qdef)};
  	} else {
  	  seenLabels += {label};
  	}
  }
  
  for(/AQuestion qs := f){
  	msgs += check(qs, tenv, useDef);
  }
  
  return msgs; 
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
// - check if the guard of the if statement is of type boolean
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
  		if(check(guard, tenv, useDef) == {} && typeOf(guard, tenv, useDef) != tbool())
  			msgs += {error("The guard of the if-statement is not of type boolean", q.src)};
  		msgs += check(guard, tenv, useDef);
  		}
  }
  return msgs; 
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
	case not(AExpr expr):{
		  set[Message] deeperErrors = check(expr, tenv, useDef);
		  if(deeperErrors == {}){
		    msgs += { error("Invalid type of argument of NOT", e.src) | typeOf(expr, tenv, useDef) != tbool()};
		  }
		  msgs += deeperErrors;
	  }
	case mul(AExpr lhs, AExpr rhs):{
		set[Message] deeperErrorsLhs = check(lhs, tenv, useDef);
		set[Message] deeperErrorsRhs = check(rhs, tenv, useDef);
		if(deeperErrorsLhs == {} && deeperErrorsRhs == {}){
			msgs += { error("Invalid types of arguments of multiplication", e.src) | typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()};
		}
		msgs += deeperErrorsLhs + deeperErrorsRhs;
	}
    case div(AExpr lhs, AExpr rhs):{
		set[Message] deeperErrorsLhs = check(lhs, tenv, useDef);
		set[Message] deeperErrorsRhs = check(rhs, tenv, useDef);
		if(deeperErrorsLhs == {} && deeperErrorsRhs == {}){
			msgs += { error("Invalid types of arguments of division", e.src) | typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()};
		}
		msgs += deeperErrorsLhs + deeperErrorsRhs;
	}
    case sum(AExpr lhs, AExpr rhs):{
		set[Message] deeperErrorsLhs = check(lhs, tenv, useDef);
		set[Message] deeperErrorsRhs = check(rhs, tenv, useDef);
		if(deeperErrorsLhs == {} && deeperErrorsRhs == {}){
			msgs += { error("Invalid types of arguments of sum", e.src) | typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()};
		}
		msgs += deeperErrorsLhs + deeperErrorsRhs;
	}
    case sub(AExpr lhs, AExpr rhs):{
		set[Message] deeperErrorsLhs = check(lhs, tenv, useDef);
		set[Message] deeperErrorsRhs = check(rhs, tenv, useDef);
		if(deeperErrorsLhs == {} && deeperErrorsRhs == {}){
			msgs += { error("Invalid types of arguments of subtraction", e.src) | typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()};
		}
		msgs += deeperErrorsLhs + deeperErrorsRhs;
	}
    case lt(AExpr lhs, AExpr rhs):{
		set[Message] deeperErrorsLhs = check(lhs, tenv, useDef);
		set[Message] deeperErrorsRhs = check(rhs, tenv, useDef);
		if(deeperErrorsLhs == {} && deeperErrorsRhs == {}){
			msgs += { error("Invalid types of arguments of \<", e.src) | typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()};
		}
		msgs += deeperErrorsLhs + deeperErrorsRhs;
	}
    case leq(AExpr lhs, AExpr rhs):{
		set[Message] deeperErrorsLhs = check(lhs, tenv, useDef);
		set[Message] deeperErrorsRhs = check(rhs, tenv, useDef);
		if(deeperErrorsLhs == {} && deeperErrorsRhs == {}){
			msgs += { error("Invalid types of arguments of \<=", e.src) | typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()};
		}
		msgs += deeperErrorsLhs + deeperErrorsRhs;
	}
    case gt(AExpr lhs, AExpr rhs):{
		set[Message] deeperErrorsLhs = check(lhs, tenv, useDef);
		set[Message] deeperErrorsRhs = check(rhs, tenv, useDef);
		if(deeperErrorsLhs == {} && deeperErrorsRhs == {}){
			msgs += { error("Invalid types of arguments of \>", e.src) | typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()};
		}
		msgs += deeperErrorsLhs + deeperErrorsRhs;
	}
    case geq(AExpr lhs, AExpr rhs):{
		set[Message] deeperErrorsLhs = check(lhs, tenv, useDef);
		set[Message] deeperErrorsRhs = check(rhs, tenv, useDef);
		if(deeperErrorsLhs == {} && deeperErrorsRhs == {}){
			msgs += { error("Invalid types of arguments of \>=", e.src) | typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()};
		}
		msgs += deeperErrorsLhs + deeperErrorsRhs;
	}
    case equal(AExpr lhs, AExpr rhs):{
		set[Message] deeperErrorsLhs = check(lhs, tenv, useDef);
		set[Message] deeperErrorsRhs = check(rhs, tenv, useDef);
		if(deeperErrorsLhs == {} && deeperErrorsRhs == {}){
			msgs += { error("Invalid types of arguments of ==", e.src) | typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) || typeOf(rhs, tenv, useDef) == tunknown()};
		}
		msgs += deeperErrorsLhs + deeperErrorsRhs;
	}
	   
    case neq(AExpr lhs, AExpr rhs):{
		set[Message] deeperErrorsLhs = check(lhs, tenv, useDef);
		set[Message] deeperErrorsRhs = check(rhs, tenv, useDef);
		if(deeperErrorsLhs == {} && deeperErrorsRhs == {}){
	  		msgs += { error("Invalid types of arguments of !=", e.src) | typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) || typeOf(rhs, tenv, useDef) == tunknown()}; 
		}
		msgs += deeperErrorsLhs + deeperErrorsRhs;
	}
    case and(AExpr lhs, AExpr rhs):{
		set[Message] deeperErrorsLhs = check(lhs, tenv, useDef);
		set[Message] deeperErrorsRhs = check(rhs, tenv, useDef);
		if(deeperErrorsLhs == {} && deeperErrorsRhs == {}){
	  		msgs += { error("Invalid types of arguments of AND", e.src) | typeOf(lhs, tenv, useDef) != tbool() || typeOf(rhs, tenv, useDef) != tbool()}; 
		}
		msgs += deeperErrorsLhs + deeperErrorsRhs;
	}
    case or(AExpr lhs, AExpr rhs):{
		set[Message] deeperErrorsLhs = check(lhs, tenv, useDef);
		set[Message] deeperErrorsRhs = check(rhs, tenv, useDef);
		if(deeperErrorsLhs == {} && deeperErrorsRhs == {}){
	  		msgs += { error("Invalid types of arguments of OR", e.src) | typeOf(lhs, tenv, useDef) != tbool() || typeOf(rhs, tenv, useDef) != tbool()}; 
		}
		msgs += deeperErrorsLhs + deeperErrorsRhs;
	}
   }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  {
      if (<u, loc d> <- useDef, <_, d, _, _, Type t> <- tenv) {
        return t;
      }
      }
    // Check(AExpr) takes care already of checking if the arguments of an expression are of the same type
    // So if it gets here, there's no need to check the deeper levels again
    case string(str _): return tstr();
    case integer(int _): return tint();
    case boolean(bool _): return tbool();
    case not(AExpr _): return tbool();
    case mul(AExpr _, AExpr _): return tint();
    case div(AExpr _, AExpr _): return tint();
  	case sum(AExpr _, AExpr _): return tint();
  	case sub(AExpr _, AExpr _): return tint();
  	case lt(AExpr _, AExpr _): return tbool();
  	case leq(AExpr _, AExpr _): return tbool();
  	case gt(AExpr _, AExpr _): return tbool();
  	case geq(AExpr _, AExpr _): return tbool();
  	case equal(AExpr _, AExpr _): return tbool();
  	case neq(AExpr _, AExpr _): return tbool();
  	case and(AExpr _, AExpr _): return tbool();
  	case or(AExpr _, AExpr _): return tbool();
  }
  return tunknown(); 
}

Type atype2type(AType t){
  switch(t){
  	case integerType(): return tint();
  	case booleanType(): return tbool();
  	case stringType(): return tstr();
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
 
 

