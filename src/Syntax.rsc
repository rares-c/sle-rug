module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = Str Id ":" Type // regular question
  | Str Id ":" Type "=" Expr // computed question
  | "if" "(" Expr ")" "{" Question* "}" ("else" "{" Question* "}")? // if-then + if-then-else
  | "{" Question* "}" // block
  ; 

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | Str 
  | Int 
  | Bool
  | bracket "(" Expr ")"
  | "!" Expr
  > left Expr ("*" | "/") Expr
  > left Expr ("+" | "-") Expr 
  > left Expr ("\<" | "\<=" | "\>" | "\>=") Expr
  > left Expr ("==" | "!=") Expr
  > left Expr "&&" Expr
  > left Expr "||" Expr
  ;
  
syntax Type
  = "integer" | "boolean";  
  
lexical Str = [\"] ![\"]* [\"];

lexical Int 
  = [0-9]+;

lexical Bool = "true" | "false";



