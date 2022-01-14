module Transform

import Syntax;
import Resolve;
import AST;
import CST2AST;
import ParseTree;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  AExpr currentGuard = boolean(true);
  f.questions = flatten(f.questions, currentGuard);
  return f;
}

list[AQuestion] flatten(list[AQuestion] qs, AExpr currentGuard){
	list[AQuestion] returnQs = [];
	for(AQuestion q <- qs){
		switch(q){
			case qstn(str q, AId identifier, AType tp): returnQs += ifqstn(currentGuard, [qstn(q, identifier, tp)]);
			case qstn(str q, AId identifier, AType tp, AExpr expr): returnQs += ifqstn(currentGuard, [qstn(q, identifier, tp, expr)]);
			case ifqstn(AExpr guard, list[AQuestion] questions): {
				AExpr newGuard = and(currentGuard, guard);
				returnQs += flatten(questions, newGuard);
			}
			case ifelqstn(AExpr guard, list[AQuestion] tQuestions, list[AQuestion] fQuestions): {
				AExpr newGuard = and(currentGuard, guard);
				returnQs += flatten(tQuestions, newGuard);
				newGuard = and(currentGuard, not(guard));
				returnQs += flatten(fQuestions, newGuard);
			}
			case qblock(list[AQuestion] questions): returnQs += flatten(questions, currentGuard);
		}
	}
	return returnQs;
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
 start[Form] rename(start[Form] f, loc useOrDef, str newName) {
   RefGraph r = resolve(cst2ast(f));
   set[loc] renameLoc = {};
   if(useOrDef in r.uses<0>){
     if(<useOrDef, loc d> <- r.useDef){
     	renameLoc += {u | <loc u, d> <- r.useDef};
     	renameLoc += {d};
     }
   } else if (useOrDef in r.defs<1>) {
   	renameLoc += {useOrDef};
   	renameLoc += {u | <loc u, useOrDef> <- r.useDef};
   }
   
   return visit(f){
   	case Id x => [Id]newName 
   		when x@\loc in renameLoc
   } 
 } 
 
 
 

