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
      field.matchAst:
      of nnkIdentDefs(`ident` @ nnkIdent, `fieldType` @ nnkSym, _):
        if ident.repr == fieldIdent:
          return (fieldType, newLit false)
      of nnkIdentDefs(nnkPostfix("*", `ident` @ nnkIdent), `fieldType` @ nnkSym, _):
        if ident.repr == fieldIdent:
          return (fieldType, newLit true)
      of `defs` @ nnkIdentDefs:
        debugEcho defs.lispRepr
        if defs.len > 3:
          for def in defs:
            debugEcho lispRepr def
            def.matchAst:
            of `ident` @ nnkIdent:
              if ident.repr == fieldIdent:
                return (defs[^2], newLit false)
            of nnkPostfix("*", `ident` @ nnkIdent):
              if ident.repr == fieldIdent:
                return (defs[^2], newLit true)
            #of `fieldType` @ nnkSym:
            #  if ident.repr == fieldIdent:
            #    return (defs[^2], newLit true)
            of nnkSym: continue
            of nnkEmpty: continue

type ObjectFieldInfo*[T] = object
  `T`*: typedesc[T]
  `exported`*: bool

type FieldInitKind* {.pure.} = enum
  private, constructor, setter, assign, iterate

macro getFieldInfo*[T: object](self: typedesc[T]; field: untyped): ObjectFieldInfo =
  macro inner(s, f): (NimNode, NimNode) =
    quote do: getFieldInfoNodes(`s`, `f`.strVal)
  let (t, x) = inner[T](self, field)
  quote do: ObjectFieldInfo[`t`](exported: `x`)

func getFieldInitKind[T: object](field: string): FieldInitKind =
  var t = T()
  when compiles(T(a: default(typeof(t.a)))):
    return constructor
  elif compiles(`a=`(t, default(typeof(t.a)))):
    return setter
  elif compiles(assign(t.a, default(typeof(t.a)))):
    return assign
  elif compiles(for _ in t.a: break):
    return iterate
  else: # Private or non-existent field. TODO: check if private
    discard


when isMainModule:
#dumpLisp:
  type A = object
    a: int
    b*: int

  let info = getFieldInfo(A, b)
  echo info.T.typeof
  assert info.exported == true

when isMainModule and defined test:
  import std/unittest
  import typetraits
  #import fusion/astdsl

  suite "override object fields from tuple of matching fields":

    setup:
      type A = object
        a, c: int
        b*: int

    test "a":
      doAssert getFieldInfo(A, a).T is int
      var info =  getFieldInfo(A, a)
      doAssert info.T is int
      info = getFieldInfo(A, b)
      doAssert info.T is int
      doAssert info.exported == true

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

