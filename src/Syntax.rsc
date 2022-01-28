module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
    = "form" Id "{" Question* "}"; 

// TODO: question, computed question, block, if-then-else, if-then

// Syntax for Questions in QL. 4 types of questions: regular, computed, if-then, if-then-else, and block questions.
syntax Question
    = Str Id ":" Type // regular question
    | Str Id ":" Type "=" Expr // computed question
    | "if" "(" Expr ")" "{" Question* "}" // if-then
    | "if" "(" Expr ")" "{" Question* "}" "else" "{" Question* "}" // if-then-else
    | "{" Question* "}" // block
    ; 

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)

// Syntax for Expressions in QL. An expression is either a literal, or a compound expression involving one of the operands
// + (binary), - (unary and binary), *, /, &&, ||, !, >, <, <=, >=, ==, !=. 
syntax Expr 
    = Id \ "true" \ "false" // true/false are reserved keywords.
    | Str 
    | Int 
    | Bool
    | bracket "(" Expr ")"
    | right "!" Expr  // ! and the unary - have the highest precedence
    | right "-" Expr
    > left Expr ("*" | "/") Expr // * and / have the same precedence
    > left Expr ("+" | "-") Expr // + and - have the same precedence
    > left Expr ("\<" | "\<=" | "\>" | "\>=") Expr // >, <, <=, and >= have the same precedence
    > left Expr ("==" | "!=") Expr // the equals and not equals have the same precedence
    > left Expr "&&" Expr
    > left Expr "||" Expr
    ;
  
 // Syntax for the types in QL. Three supported types: integer, boolean and strings.
syntax Type
    = "integer" | "boolean" | "string";  
  
 // Lexical for strings in QL
lexical Str = @category="StringLiteral" [\"] ![\"]* [\"];

// Lexical for integers in QL
lexical Int 
    = [0-9]+;
  
// Lexical for booleans in QL
lexical Bool 
    = "true" | "false";



