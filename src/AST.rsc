module AST


/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = qstn(str q, AId identifier, AType tp)
  | qstn(str q, AId identifier, AType tp, AExpr expr)
  | ifqstn(AExpr guard, list[AQuestion] questions)
  | ifelqstn(AExpr guard, list[AQuestion] tQuestions, list[AQuestion] fQuestions)
  | qblock(list[AQuestion] questions)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | string(str name)
  | integer(int vlue)
  | boolean(bool boolean)
  | not(AExpr expr)
  | mul(AExpr lhs, AExpr rhs)
  | div(AExpr lhs, AExpr rhs)
  | sum(AExpr lhs, AExpr rhs)
  | sub(AExpr lhs, AExpr rhs)
  | lt(AExpr lhs, AExpr rhs)
  | leq(AExpr lhs, AExpr rhs)
  | gt(AExpr lhs, AExpr rhs)
  | geq(AExpr lhs, AExpr rhs)
  | eq(AExpr lhs, AExpr rhs)
  | neq(AExpr lhs, AExpr rhs)
  | and(AExpr lhs, AExpr rhs)
  | or(AExpr lhs, AExpr rhs)
  ;

data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
  = integerType()
  | booleanType()
  | stringType()
  ;
