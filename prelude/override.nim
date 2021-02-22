# Intended to be included rather than imported.
# TODO
#   - This module probably needs a better name.
import pkg/prelude/[alias, lib]

func getFieldInfoNodes*[T: object](self: typedesc[T]; fieldIdent: string): (NimNode, NimNode) {.compileTime.} =
  for field in getTypeImpl(self)[2]:
    if field[0].strVal == fieldIdent:
      return (field[1], newLit(field[0].isExported))

func getFieldInfoNodes*(self: NimNode; fieldIdent: string): (NimNode, NimNode) {.compileTime.} =
  getImpl(self).matchAst:
  of nnkTypeDef(_, _, nnkObjectTy(_, _, `params` @ nnkRecList)):
    for field in params:
      var ident = field[0].repr
      if ident[^1] == '*':
        if ident[0..^2] == fieldIdent:
          return (field[1], newLit true)
      else:
        if ident == fieldIdent:
          return (field[1], newLit false)

type ObjectFieldInfo*[T] = object
  t*: typedesc[T]
  x*: bool

macro getFieldInfo*[T: object](self: typedesc[T]; field: untyped): ObjectFieldInfo =
  macro inner(s, f): (NimNode, NimNode) =
    quote do: getFieldInfoNodes(`s`, `f`.strVal)
  let (t, x) = inner[T](self, field)
  quote do: ObjectFieldInfo[`t`](x: `x`)


when isMainModule and defined test:
  import std/unittest
  import fusion/astdsl

  suite "override object fields from tuple of matching fields":

    setup:
      type A = object
        a, b, c*: int

    test "a":
      check getFieldInfo(A, b).x == false

#    test "tuple can be a subset of the object's fields":
#      var a = A(b: 1, c: 2)
#      a.override (a: 1, b: 2)
#      check a.a == 1
#      check a.b == 2
#      check a.c == 2
#
#    test "calling from a macro":
#      macro setA(a: untyped): untyped =
#        expectKind a, nnkPar
#        result = newStmtList()
#        var b: A
#        b.override(a)
#        assert b.a == 7
#        result = quote do:
#          var b = A()
#          b.override(`a`)
#          check b.a == 7
#      setA (a: 7)

#    test "fusion.astdsl composition":
#      macro setB(a, b: untyped): untyped =
#        result = buildAst(stmtList):
#          a.override(b)
#      let b = setB (b: 7)

