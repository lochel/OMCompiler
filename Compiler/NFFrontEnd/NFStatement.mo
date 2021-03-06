/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated uniontype NFStatement
  import Absyn;
  import Type = NFType;
  import Expression = NFExpression;
  import NFInstNode.InstNode;
  import DAE;

protected
  import Statement = NFStatement;
  import ElementSource;
  import Util;

public
  record ASSIGNMENT
    Expression lhs "The asignee";
    Expression rhs "The expression";
    Type ty;
    DAE.ElementSource source;
  end ASSIGNMENT;

  record FUNCTION_ARRAY_INIT "Used to mark in which order local array variables in functions should be initialized"
    String name;
    Type ty;
    DAE.ElementSource source;
  end FUNCTION_ARRAY_INIT;

  record FOR
    InstNode iterator;
    Option<Expression> range;
    list<Statement> body "The body of the for loop.";
    DAE.ElementSource source;
  end FOR;

  record IF
    list<tuple<Expression, list<Statement>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    DAE.ElementSource source;
  end IF;

  record WHEN
    list<tuple<Expression, list<Statement>>> branches
      "List of branches, where each branch is a tuple of a condition and a body.";
    DAE.ElementSource source;
  end WHEN;

  record ASSERT
    Expression condition "The assert condition.";
    Expression message "The message to display if the assert fails.";
    Expression level;
    DAE.ElementSource source;
  end ASSERT;

  record TERMINATE
    Expression message "The message to display if the terminate triggers.";
    DAE.ElementSource source;
  end TERMINATE;

  record NORETCALL
    Expression exp;
    DAE.ElementSource source;
  end NORETCALL;

  record WHILE
    Expression condition;
    list<Statement> body;
    DAE.ElementSource source;
  end WHILE;

  record RETURN
    DAE.ElementSource source;
  end RETURN;

  record BREAK
    DAE.ElementSource source;
  end BREAK;

  record FAILURE
    list<Statement> body;
    DAE.ElementSource source;
  end FAILURE;

  function makeIf
    input list<tuple<Expression, list<Statement>>> branches;
    input DAE.ElementSource src;
    output Statement stmt;
  algorithm
    stmt := IF(branches, src);
    annotation(__OpenModelica_EarlyInline=true);
  end makeIf;

  function source
    input Statement stmt;
    output DAE.ElementSource source;
  algorithm
    source := match stmt
      case ASSIGNMENT() then stmt.source;
      case FUNCTION_ARRAY_INIT() then stmt.source;
      case FOR() then stmt.source;
      case IF() then stmt.source;
      case WHEN() then stmt.source;
      case ASSERT() then stmt.source;
      case TERMINATE() then stmt.source;
      case NORETCALL() then stmt.source;
      case WHILE() then stmt.source;
      case RETURN() then stmt.source;
      case BREAK() then stmt.source;
      case FAILURE() then stmt.source;
    end match;
  end source;

  function info
    input Statement stmt;
    output SourceInfo info = ElementSource.getInfo(source(stmt));
  end info;

  partial function ApplyFn
    input Statement stmt;
  end ApplyFn;

  function apply
    input Statement stmt;
    input ApplyFn func;
  algorithm
    () := match stmt
      case FOR()
        algorithm
          for e in stmt.body loop
            apply(e, func);
          end for;
        then
          ();

      case IF()
        algorithm
          for b in stmt.branches loop
            for e in Util.tuple22(b) loop
              apply(e, func);
            end for;
          end for;
        then
          ();

      case WHEN()
        algorithm
          for b in stmt.branches loop
            for e in Util.tuple22(b) loop
              apply(e, func);
            end for;
          end for;
        then
          ();

      case WHILE()
        algorithm
          for e in stmt.body loop
            apply(e, func);
          end for;
        then
          ();

      case FAILURE()
        algorithm
          for e in stmt.body loop
            apply(e, func);
          end for;
        then
          ();

      else ();
    end match;

    func(stmt);
  end apply;

  function map
    input output Statement stmt;
    input MapFn func;

    partial function MapFn
      input output Statement stmt;
    end MapFn;
  algorithm
    () := match stmt
      case FOR()
        algorithm
          stmt.body := list(map(s, func) for s in stmt.body);
        then
          ();

      case IF()
        algorithm
          stmt.branches := list(
            (Util.tuple21(b),
             list(map(s, func) for s in Util.tuple22(b))) for b in stmt.branches);
        then
          ();

      case WHEN()
        algorithm
          stmt.branches := list(
            (Util.tuple21(b),
             list(map(s, func) for s in Util.tuple22(b))) for b in stmt.branches);
        then
          ();

      case WHILE()
        algorithm
          stmt.body := list(map(s, func) for s in stmt.body);
        then
          ();

      else ();
    end match;

    stmt := func(stmt);
  end map;

  function mapExpList
    input output list<Statement> stmtl;
    input MapFunc func;

    partial function MapFunc
      input output Expression exp;
    end MapFunc;
  algorithm
    stmtl := list(mapExp(s, func) for s in stmtl);
  end mapExpList;

  function mapExp
    input output Statement stmt;
    input MapFunc func;

    partial function MapFunc
      input output Expression exp;
    end MapFunc;
  algorithm
    stmt := match stmt
      local
        Expression e1, e2, e3;

      case ASSIGNMENT()
        algorithm
          e1 := func(stmt.lhs);
          e2 := func(stmt.rhs);
        then
          if referenceEq(e1, stmt.lhs) and referenceEq(e2, stmt.rhs) then
            stmt else ASSIGNMENT(e1, e2, stmt.ty, stmt.source);

      case FOR()
        algorithm
          stmt.body := mapExpList(stmt.body, func);
          stmt.range := Util.applyOption(stmt.range, func);
        then
          stmt;

      case IF()
        algorithm
          stmt.branches := list(
            (func(Util.tuple21(b)), mapExpList(Util.tuple22(b), func)) for b in stmt.branches);
        then
          stmt;

      case WHEN()
        algorithm
          stmt.branches := list(
            (func(Util.tuple21(b)), mapExpList(Util.tuple22(b), func)) for b in stmt.branches);
        then
          stmt;

      case ASSERT()
        algorithm
          e1 := func(stmt.condition);
          e2 := func(stmt.message);
          e3 := func(stmt.level);
        then
          if referenceEq(e1, stmt.condition) and referenceEq(e2, stmt.message) and
            referenceEq(e3, stmt.level) then stmt else ASSERT(e1, e2, e3, stmt.source);

      case TERMINATE()
        algorithm
          e1 := func(stmt.message);
        then
          if referenceEq(e1, stmt.message) then stmt else TERMINATE(e1, stmt.source);

      case NORETCALL()
        algorithm
          e1 := func(stmt.exp);
        then
          if referenceEq(e1, stmt.exp) then stmt else NORETCALL(e1, stmt.source);

      case WHILE()
        then WHILE(func(stmt.condition), mapExpList(stmt.body, func), stmt.source);

      else stmt;
    end match;
  end mapExp;

  function foldExpList<ArgT>
    input list<Statement> stmt;
    input FoldFunc func;
    input output ArgT arg;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    for s in stmt loop
      arg := foldExp(s, func, arg);
    end for;
  end foldExpList;

  function foldExp<ArgT>
    input Statement stmt;
    input FoldFunc func;
    input output ArgT arg;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    () := match stmt
      case Statement.ASSIGNMENT()
        algorithm
          arg := func(stmt.lhs, arg);
          arg := func(stmt.rhs, arg);
        then
          ();

      case Statement.FOR()
        algorithm
          arg := foldExpList(stmt.body, func, arg);

          if isSome(stmt.range) then
            arg := func(Util.getOption(stmt.range), arg);
          end if;
        then
          ();

      case Statement.IF()
        algorithm
          for b in stmt.branches loop
            arg := func(Util.tuple21(b), arg);
            arg := foldExpList(Util.tuple22(b), func, arg);
          end for;
        then
          ();

      case Statement.WHEN()
        algorithm
          for b in stmt.branches loop
            arg := func(Util.tuple21(b), arg);
            arg := foldExpList(Util.tuple22(b), func, arg);
          end for;
        then
          ();

      case Statement.ASSERT()
        algorithm
          arg := func(stmt.condition, arg);
          arg := func(stmt.message, arg);
          arg := func(stmt.level, arg);
        then
          ();

      case Statement.TERMINATE()
        algorithm
          arg := func(stmt.message, arg);
        then
          ();

      case Statement.NORETCALL()
        algorithm
          arg := func(stmt.exp, arg);
        then
          ();

      case Statement.WHILE()
        algorithm
          arg := func(stmt.condition, arg);
          arg := foldExpList(stmt.body, func, arg);
        then
          ();

      else ();
    end match;
  end foldExp;

  function toString
    input Statement stmt;
    output String str;
  algorithm
    str := match stmt
      local
        String s1, s2;

      case ASSIGNMENT()
        then Expression.toString(stmt.lhs) + " := " + Expression.toString(stmt.rhs);

      case FUNCTION_ARRAY_INIT()
        then "array init " + stmt.name;

      case FOR()
        algorithm
          s1 := if isSome(stmt.range) then " in " + Expression.toString(Util.getOption(stmt.range)) else "";
          s2 := toStringList(stmt.body);
        then
          "for " + InstNode.name(stmt.iterator) + s1 + " loop\n" + s2 + "end for";

      case IF()
        then branchString(listHead(stmt.branches), "if", true) +
             stringDelimitList(list(branchString(b, "if", false) for b in listRest(stmt.branches)), "\n") +
             "\nend if";

      case WHEN()
        then branchString(listHead(stmt.branches), "when", true) +
             stringDelimitList(list(branchString(b, "when", false) for b in listRest(stmt.branches)), "\n") +
             "\nwhen if";

      case ASSERT()
        then "assert(" + Expression.toString(stmt.condition) + ", " +
             Expression.toString(stmt.message) + ", " + Expression.toString(stmt.level) + ")";

      case TERMINATE()
        then "terminate( " + Expression.toString(stmt.message) + ")";

      case NORETCALL()
        then Expression.toString(stmt.exp);

      case WHILE()
        then "while " + Expression.toString(stmt.condition) + " then\n" +
             toStringList(stmt.body) + "\nend while";

      case RETURN() then "return";
      case BREAK() then "break";
      else "#UNKNOWN STATEMENT#";
    end match;
  end toString;

  function branchString
    input tuple<Expression, list<Statement>> branch;
    input String stmtType;
    input Boolean firstBranch;
    output String str;
  protected
    Expression cond;
    list<Statement> body;
  algorithm
    (cond, body) := branch;

    str := (if firstBranch then stmtType elseif Expression.isTrue(cond) then "else" else "else" + stmtType) +
           " " + Expression.toString(cond) + "then\n" + toStringList(body);
  end branchString;

  function toStringList
    input list<Statement> stmtl;
    output String str;
  algorithm
    str := List.toString(stmtl, toString, "", " " , "\n  ", "", false) + "\n";
  end toStringList;

annotation(__OpenModelica_Interface="frontend");
end NFStatement;
