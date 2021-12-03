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

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

Use uses(AForm f) {
  Use uses = {};
  for(/AExpr e := f){
    uses += {<identifier.src, identifier.name> | /AId identifier := e};
  }
  return uses; 
}

Def defs(AForm f)
  = {<identifier.name, identifier.src> | /qstn(str _, AId identifier, AType _) := f}
  + {<identifier.name, identifier.src> | /qstn(str _, AId identifier, AType _, AExpr _) := f}
  ; 
