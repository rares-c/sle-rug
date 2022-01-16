module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library
import String;
import Boolean;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

HTML5Node form2html(AForm f) {
  return html(
  "
  '\<head\>
  '	\<meta charset=\"UTF-8\"\>
  '	\<meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\"\>
  '	\<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"\>
  '	\<title\>Questionnaire\</title\>
  '	\<link rel=\"stylesheet\" href=\"https://stackpath.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css\" integrity=\"sha384-HSMxcRTRxnN+Bdg0JdbxYKrThecOKuH5zCYotlSAcp1+c8xmyTe9GYg1l9a69psu\" crossorigin=\"anonymous\"\>
  '\</head\>
  '\<body\>
  '	\<h1 style=\"display:flex; justify-content: center; text-align: center;\"\> <f.name> \</h1\>
  ' \<div class=\"container\" style=\"margin-left: auto; margin-right: auto;\" \>
  '	<questions2html(f.questions)>
  ' \</div\>
  '	\<script src=\"<split("/", f.src[extension="js"].top.uri)[-1]>\"\>\</script\>
  '\</body\>\n"
  );
}

str questions2html(list[AQuestion] questions) {
	str returnString = "";
	for (AQuestion q <- questions){
		switch(q){
			case qstn(str label, AId identifier, AType tp): {
				returnString += "<label[1..-1]>\<br\>\n";
				switch(tp){
					case integerType(): returnString += "\<input type=\"number\" id=\"<identifier.name + "-" + label[1..-1]>\" name=\"<identifier.name + "-" + label[1..-1]>\" oninput=\"updateForm(this.id)\"  \>\<br\>\n";
					case booleanType(): returnString += "\<input type=\"radio\" id=\"<identifier.name + "-" + label[1..-1] + "-true">\" name=\"<identifier.name + "-" + label[1..-1]>\" value=\"True\" oninput=\"updateForm(this.id)\" \>\n\<label for=\"<identifier.name + "-" + label[1..-1] + "-true">\"\> Yes \</label\>\<br\>\n\<input type=\"radio\" id=\"<identifier.name + "-" + label[1..-1] + "-false">\" name=\"<identifier.name + "-" + label[1..-1]>\" value=\"False\" oninput=\"updateForm(this.id)\" \>\n\<label for=\"<identifier.name + "-" + label[1..-1] + "-false">\"\> No \</label\>\<br\>\n";
					case stringType(): returnString += "\<input type=\"text\" id=\"<identifier.name + "-" + label[1..-1]>\" name=\"<identifier.name + "-" + label[1..-1]>\" oninput=\"updateForm(this.id)\" \>\<br\> \n";
				}
			}
			case qstn(str label, AId identifier, AType tp, AExpr _): {
				returnString += "<label[1..-1]>\<br\>\n";
				switch(tp){
					case integerType(): returnString += "\<input type=\"number\" disabled id=\"<identifier.name + "-" + label[1..-1]>\" name=\"<identifier.name + "-" + label[1..-1]>\"\>\<br\>\n";
					case booleanType(): returnString += "\<input type=\"radio\" disabled id=\"<identifier.name + "-" + label[1..-1] + "-true">\" name=\"<identifier.name + "-" + label[1..-1]>\" value=\"True\"\>\n\<label for=\"<identifier.name + "-" + label[1..-1] + "-true">\"\> Yes \</label\>\<br\>\n\<input type=\"radio\" disabled id=\"<identifier.name + "-" + label[1..-1] + "-false">\" name=\"<identifier.name + "-" + label[1..-1]>\" value=\"False\"\>\n\<label for=\"<identifier.name + "-" + label[1..-1] + "-false">\"\> No \</label\>\<br\>\n";
					case stringType(): returnString += "\<input type=\"text\" disabled id=\"<identifier.name + "-" + label[1..-1]>\" name=\"<identifier.name + "-" + label[1..-1]>\"\>\<br\> \n";
				}
			}
			case ifqstn(AExpr guard, list[AQuestion] qstns): {
				returnString += "\<div id=\"<guard.src>\" style=\"display: none;\" \>\n";
				returnString += questions2html(qstns);
				returnString += "\</div\>\n";
			}
			case ifelqstn(AExpr guard, list[AQuestion] tQuestions, list[AQuestion] fQuestions): {
				returnString += "\<div id=\"<guard.src>\" style=\"display: none;\" \>\n";
				returnString += questions2html(tQuestions);
				returnString += "\</div\>\n";
				returnString += "\<div id=\"else-<guard.src>\" style=\"display: none;\" \>\n";
				returnString += questions2html(fQuestions);
				returnString += "\</div\>\n";
			}
			case qblock(list[AQuestion] questions): {
				returnString += "\<div\>\n";
				returnString += questions2html(questions);
				returnString += "\</div\>\n";
			}
		}
	}
	
	return returnString;
}

str form2js(AForm f) {
  return "
  ' var questions = {};
  ' <generateQuestions(f)>
  ' <generateInitialValues(f)>
  ' <generateInitialUpdate(f)>
  ' <generateUpdateFunction(f)>
  ";
}

str generateQuestions(AForm f){
	str returnString = "";
	for(/AQuestion q := f){
		switch(q){
			case qstn(str _, AId identifier, AType tp):
				returnString += "questions[\"<identifier.name>\"] = <type2def(tp)>;\n";
			case qstn(str _, AId identifier, AType tp, AExpr _):
				returnString += "questions[\"<identifier.name>\"] = <type2def(tp)>;\n";
		}
	}
	return returnString;
}

str auxGenInitValues(str label, AId identifier, AType tp){
	str returnString = "";
	switch(tp){
		case integerType(): returnString += "document.getElementById(\"<identifier.name + "-" + label[1..-1]>\").value = questions[\"<identifier.name>\"];\n";
		case stringType(): returnString += "document.getElementById(\"<identifier.name + "-" + label[1..-1]>\").value = questions[\"<identifier.name>\"];\n";
		case booleanType(): 
			returnString += "if(questions[\"<identifier.name>\"]) {
			'	document.getElementById(\"<identifier.name + "-" + label[1..-1] + "-true">\").checked = true;
			'	document.getElementById(\"<identifier.name + "-" + label[1..-1] + "-false">\").checked = false;
			'	} else {
			'	document.getElementById(\"<identifier.name + "-" + label[1..-1] + "-true">\").checked = false;
			'	document.getElementById(\"<identifier.name + "-" + label[1..-1] + "-false">\").checked = true;
			'	}
			'";
	}
	return returnString;
}

str generateInitialValues(AForm f){
	str returnString = "";
	for(/qstn(str label, AId identifier, AType tp) := f){
		returnString += auxGenInitValues(label, identifier, tp);
	}
	
	for(/qstn(str label, AId identifier, AType tp, AExpr _) := f){
		returnString += auxGenInitValues(label, identifier, tp);
	}
	return returnString;
}

str auxGenInitUpdate(str label, AId identifier, AType tp){
	str returnString = "";
	switch(tp){
		case booleanType(): {
			returnString += "updateForm(\"<identifier.name + "-" + label[1..-1] + "-true">\");\n";
			returnString += "updateForm(\"<identifier.name + "-" + label[1..-1] + "-false">\");\n";
		}
		case integerType(): returnString += "updateForm(\"<identifier.name + "-" + label[1..-1]>\");\n";
		case stringType(): returnString += "updateForm(\"<identifier.name + "-" + label[1..-1]>\");\n";
	}
	return returnString;
}

str generateInitialUpdate(AForm f){
	str returnString = "";
	for(/qstn(str label, AId identifier, AType tp) := f){
		returnString += auxGenInitUpdate(label, identifier, tp);
	}
	
	for(/qstn(str label, AId identifier, AType tp, AExpr _) := f){
		returnString += auxGenInitUpdate(label, identifier, tp);
	}
	return returnString;
}

str generateUpdateFunction(AForm f){
	return "
	' function updateForm(id) {
	'	var trigger = id.split(\"-\")[0];
	'	if(id.split(\"-\")[id.split(\"-\").length - 1] === \"true\" && document.getElementById(id).checked === true){
	'		questions[trigger] = true;	
	'	} else if (id.split(\"-\")[id.split(\"-\").length - 1] === \"false\" && document.getElementById(id).checked === true) {
	'		questions[trigger] = false;
	'	} else if (document.getElementById(id).type === \"number\") {
	'		if(isNaN(parseInt(document.getElementById(id).value))) return;
	'		questions[trigger] = parseInt(document.getElementById(id).value);
	'	} else {
	'		if(isNaN(document.getElementById(id).value)) return;
	'		questions[trigger] = document.getElementById(id).value;
	'	}
	'	<questions2js(f.questions)>
	'	}
	'";
}

str questions2js(list[AQuestion] questions){
	str returnString = "";
	for (AQuestion q <- questions){
		switch(q){
			case qstn(str label, AId identifier, AType tp, AExpr expr): {
				returnString += "var oldValue = questions[\"<identifier.name>\"];
				'questions[\"<identifier.name>\"] = <expr2js(expr)>;\n";
				switch(tp){
					case integerType(): returnString += "document.getElementById(\"<identifier.name + "-" + label[1..-1]>\").value = questions[\"<identifier.name>\"];\n";
					case stringType(): returnString += "document.getElementById(\"<identifier.name + "-" + label[1..-1]>\").value = questions[\"<identifier.name>\"];\n";
					case booleanType(): 
						returnString += "if(questions[\"<identifier.name>\"]) {
						'	document.getElementById(\"<identifier.name + "-" + label[1..-1] + "-true">\").checked = true;
						'	document.getElementById(\"<identifier.name + "-" + label[1..-1] + "-false">\").checked = false;
						'	} else {
						'	document.getElementById(\"<identifier.name + "-" + label[1..-1] + "-true">\").checked = false;
						'	document.getElementById(\"<identifier.name + "-" + label[1..-1] + "-false">\").checked = true;
						'	}
						'";
				}
				returnString += "if(oldValue != questions[\"<identifier.name>\"]) updateForm(id);\n";
			}
			case ifqstn(AExpr guard, list[AQuestion] qstns):
				returnString += "if(<expr2js(guard)>) {
				'	document.getElementById(\"<guard.src>\").style.display = \"block\";
				'	<questions2js(qstns)>
				' } else {
				'	document.getElementById(\"<guard.src>\").style.display = \"none\";
				' }
				'";
			case ifelqstn(AExpr guard, list[AQuestion] tQuestions, list[AQuestion] fQuestions):
				returnString += "if(<expr2js(guard)>) {
				'	document.getElementById(\"<guard.src>\").style.display = \"block\";
				'	document.getElementById(\"else-<guard.src>\").style.display = \"none\";
				'	<questions2js(tQuestions)>
				' } else {
				'	document.getElementById(\"<guard.src>\").style.display = \"none\";
				'	document.getElementById(\"else-<guard.src>\").style.display = \"block\";
				'	<questions2js(fQuestions)>
				' }
				'";
			case qblock(list[AQuestion] qstns):
				returnString += questions2js(qstns);
		}
	}	
	return returnString;
}

str expr2js(AExpr expr){
	str returnString = "";
	switch(expr){
		case ref(AId id): returnString += "questions[\"<id.name>\"]";
		case string(str name): returnString += "\"<name>\"";
		case integer(int vlue): returnString += "<vlue>";
		case boolean(bool boolean): returnString += toString(boolean);
		case not(AExpr e): returnString += "!(" + expr2js(e) + ")";
		case mul(AExpr lhs, AExpr rhs): returnString += "(" + expr2js(lhs) + ")" + "*" + "(" + expr2js(rhs) + ")";
		case div(AExpr lhs, AExpr rhs): returnString += "(" + expr2js(lhs) + ")" + "/" + "(" + expr2js(rhs) + ")";
		case sum(AExpr lhs, AExpr rhs): returnString += "(" + expr2js(lhs) + ")" + "+" + "(" + expr2js(rhs) + ")";
		case sub(AExpr lhs, AExpr rhs): returnString += "(" + expr2js(lhs) + ")" + "-" + "(" + expr2js(rhs) + ")";
		case lt(AExpr lhs, AExpr rhs): returnString += "(" + expr2js(lhs) + ")" + "\<" + "(" + expr2js(rhs) + ")";
		case leq(AExpr lhs, AExpr rhs): returnString += "(" + expr2js(lhs) + ")" + "\<=" + "(" + expr2js(rhs) + ")";
		case gt(AExpr lhs, AExpr rhs): returnString += "(" + expr2js(lhs) + ")" + "\>" + "(" + expr2js(rhs) + ")";
		case geq(AExpr lhs, AExpr rhs): returnString += "(" + expr2js(lhs) + ")" + "\>=" + "(" + expr2js(rhs) + ")";
		case equal(AExpr lhs, AExpr rhs): returnString += "(" + expr2js(lhs) + ")" + "===" + "(" + expr2js(rhs) + ")";
		case neq(AExpr lhs, AExpr rhs): returnString += "(" + expr2js(lhs) + ")" + "!==" + "(" + expr2js(rhs) + ")";
		case and(AExpr lhs, AExpr rhs): returnString += "(" + expr2js(lhs) + ")" + "&&" + "(" + expr2js(rhs) + ")";
		case or(AExpr lhs, AExpr rhs): returnString += "(" + expr2js(lhs) + ")" + "||" + "(" + expr2js(rhs) + ")";
	}
	
	return returnString;
}

str type2def(AType tp){
	switch(tp){
		case integerType(): return "0";
		case booleanType(): return "false";
		case stringType(): return "\"\"";
		default: throw("Unknown AType");
	}
}
