# Intended to be included rather than imported.
# TODO
#   - This module probably needs a better name.
import pkg/prelude/[alias, lib]

#macro override(a: typed{nkSym}; b: typed{nkPar|nkTupleConstr}): untyped =
macro override(a, b: untyped): untyped =
  result = newStmtList()
  matchAst b:
  of nnkPar:
    for override in b:
      alias ident, override[0]
      alias val, override[1]
      result.add quote do:
        `a`.`ident` = `val`
  of nnkIdent:
    let i = b.repr
    #result.add quote do:
    #  `a`.override `b`
  #echo result.repr
#macro override(a, b: typed{nkSym}): untyped =
#  result = newStmtList()
#  echo b.getImpl().repr
#  for override in b.getImpl():
#    alias ident, override[0]
#    alias val, override[1]
#    result.add quote do:
#      `a`.`ident` = `val`
macro o(a: NimNode, b: typed{nkSym}) =
  result = quote do:
    `a`.override `b`
macro oo[T: ref|object](a: T, b: typed{nkSym}): untyped =
  result = quote do:
    `a`.override `b`
proc overrideNimNode(a, b: NimNode): NimNode {.compileTime.} =
  expectKind b, nnkPar
  result = newStmtList()
  for override in b:
    alias ident, override[0]
    alias val, override[1]
    result.add quote do:
      `a`.`ident` = `val`
proc overrideNimNode[T](a: var T, b: NimNode): NimNode {.compileTime.} =
  expectKind b, nnkPar
  result = newStmtList()
  for override in b:
    alias ident, override[0]
    alias val, override[1]
    a.a = 7
    result.add quote do:
      `a`.`override[0]` = `val`
template t(a: untyped, b: untyped): untyped {.dirty.} =
  a.override b

when isMainModule and defined test:
  import std/unittest
  import fusion/astdsl

  suite "override object fields from tuple of matching fields":

    setup:
      type A = object
        a, b, c: int

    test "tuple can be a subset of the object's fields":
      var a = A(b: 1, c: 2)
      a.override (a: 1, b: 2)
      check a.a == 1
      check a.b == 2
      check a.c == 2

    test "calling from a macro":
      macro setA(a: untyped): untyped =
        expectKind a, nnkPar
        result = newStmtList()
        var b: A
        b.override(a)
        assert b.a == 7
        result = quote do:
          var b = A()
          b.override(`a`)
          check b.a == 7
      setA (a: 7)

#    test "fusion.astdsl composition":
#      macro setB(a, b: untyped): untyped =
#        result = buildAst(stmtList):
#          a.override(b)
#      let b = setB (b: 7)

