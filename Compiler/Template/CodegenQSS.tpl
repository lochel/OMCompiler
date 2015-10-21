// This file defines templates for transforming Modelica/MetaModelica code to C
// code. They are used in the code generator phase of the compiler to write
// target code.
//
// There are two root templates intended to be called from the code generator:
// translateModel and translateFunctions. These templates do not return any
// result but instead write the result to files. All other templates return
// text and are used by the root templates (most of them indirectly).
//
// To future maintainers of this file:
//
// - A line like this
//     # var = ""
//   declares a text buffer that you can later append text to. It can also be
//   passed to other templates that in turn can append text to it. In the new
//   version of Susan it should be written like this instead:
//     let &var = buffer ""
//
// - A line like this
//     ..., Text var, ...
//   declares that a template takes a tmext buffer as input parameter. In the
//   new version of Susan it should be written like this instead:
//     ..., Text &var, ...
//
// - A line like this:
//     ..., var, ...
//   passes a text buffer to a template. In the new version of Susan it should
//   be written like this instead:
//     ..., &var, ...
//
// - Style guidelines:
//
//   - Try (hard) to limit each row to 80 characters
//
//   - Code for a template should be indented with 2 spaces
//
//     - Exception to this rule is if you have only a single case, then that
//       single case can be written using no indentation
//
//       This single case can be seen as a clarification of the input to the
//       template
//
//   - Code after a case should be indented with 2 spaces if not written on the
//     same line

package CodegenQSS

import interface SimCodeTV;
import CodegenUtil.*;
import CodegenCFunctions.*;

template translateModel(SimCode simCode)
 "Generates C code and Makefile for compiling and running a simulation of a
  Modelica model using the QSS solver suite."
::=
match simCode
case SIMCODE(modelInfo=modelInfo as MODELINFO(__)) then
  let()= textFile(generateMakefile(getName(modelInfo)), '<% getName(modelInfo) %>.makefile')
  ""
end translateModel;

template getName(ModelInfo modelInfo)
 "Returns the name of the model"
::=
match modelInfo
case MODELINFO(__) then
  '<%dotPath(name) %>'
end getName;

template generateMakefile(String name)
 "Generates a QSM model for simulation ."
::=
<<
all: <%name%>.mo <%name%>_parameters.h <%name%>_external_functions.c
<%\t%>mo2qsm ./<%name%>.mo
<%\t%>qssmg  ./<%name%>.qsm $(QSSPATH)
<%\t%>make
<%\t%>./<%name%>
<%\t%>echo "set terminal wxt persist; set grid; plot \"<%name%>_x0.dat\" with lines " | gnuplot
>>
end generateMakefile;

annotation(__OpenModelica_Interface="backend");
end CodegenQSS;
