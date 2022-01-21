module AST


/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

// Abstract form data type containing a name and a list of questions.
data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

// Abstract question data type. Each type of question from the concrete syntax is mapped to a corresponding
// abstract question.
data AQuestion(loc src = |tmp:///|)
  = qstn(str q, AId identifier, AType tp) // regular question
  | qstn(str q, AId identifier, AType tp, AExpr expr) // computed question
  | ifqstn(AExpr guard, list[AQuestion] questions) // if-then question
  | ifelqstn(AExpr guard, list[AQuestion] tQuestions, list[AQuestion] fQuestions) // if-then-else question
  | qblock(list[AQuestion] questions) // question block
  ; 

// Abstract expression data type. Each expression from the concrete syntax has a corresponding abstract expression.
data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | string(str name)
  | integer(int vlue)
  | boolean(bool boolean)
  | not(AExpr expr)
  | unminus(AExpr expr)
  | mul(AExpr lhs, AExpr rhs)
  | div(AExpr lhs, AExpr rhs)
  | sum(AExpr lhs, AExpr rhs)
  | sub(AExpr lhs, AExpr rhs)
  | lt(AExpr lhs, AExpr rhs)
  | leq(AExpr lhs, AExpr rhs)
  | gt(AExpr lhs, AExpr rhs)
  | geq(AExpr lhs, AExpr rhs)
  | equal(AExpr lhs, AExpr rhs)
  | neq(AExpr lhs, AExpr rhs)
  | and(AExpr lhs, AExpr rhs)
  | or(AExpr lhs, AExpr rhs)
  ;

// Abstract identifier data type
data AId(loc src = |tmp:///|)
  = id(str name);

// Abstract type data type
data AType(loc src = |tmp:///|)
  = integerType()
  | booleanType()
  | stringType()
  ;
