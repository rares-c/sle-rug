module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDef
]; 

// Method that creates a reference graph. All the defining occurrences and all the use ocurrences are computed.
RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

// Method that computes all the use ocurrences of different names. For a name to be used, it can
// only appear inside an expression, so it is natural to match all the identifiers in every expression
Use uses(AForm f) {
  Use uses = {};
  for(/AExpr e := f){
    uses += {<identifier.src, identifier.name> | /AId identifier := e};
  }
  return uses; 
}

// Method that computes all the defining occurrences of different names. Each regular question and
// each computed question introduces a new definition, so we need to match on every regular and computed question.
Def defs(AForm f)
  = {<identifier.name, identifier.src> | /qstn(str _, AId identifier, AType _) := f}
  + {<identifier.name, identifier.src> | /qstn(str _, AId identifier, AType _, AExpr _) := f}
  ; 
