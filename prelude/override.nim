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
        if defs.len > 3:
          for def in defs:
            def.matchAst:
            of `ident` @ nnkIdent:
              if ident.repr == fieldIdent:
                return (defs[^2], newLit false)
            of nnkPostfix("*", `ident` @ nnkIdent):
              if ident.repr == fieldIdent:
                return (defs[^2], newLit true)
            of nnkSym: discard
            of nnkEmpty: discard

type ObjectFieldInfo*[T] = object
  `T`*: typedesc[T]
  `exported`*: bool # TODO: rename to `isExported`?

type FieldInitKind* {.pure.} = enum
  private, constructor, setter, assign, iterate

macro getFieldInfo*[T: object](self: typedesc[T]; field: untyped): ObjectFieldInfo =
  macro inner(s, f): (NimNode, NimNode) =
    quote do: getFieldInfoNodes(`s`, `f`.strVal)
  let (t, x) = inner(self, field)
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

#func hasSetterImpl*[T: object; V](
#    fieldIdent: string,
#    objType: typedesc[T],
#    valueType: typedesc[V]): NimNode {.compileTime.} =
#  var t = T()
#  macro inner(t, i): bool =
#    let setterIdent = ident(i.repr & '=')
#    quote do:
#      compiles(`setterIdent`(t, default(V)))
#  newLit inner(t, fieldIdent)
#
#func hasSetterImpl*(
#    fieldIdent: string,
#    objType, valueType: NimNode): NimNode {.compileTime.} =
#  expectKind objType, nnkSym
#  expectKind valueType, nnkSym
#  macro inner(f, o, v): untyped =
#    let setter = ident(f.strVal & '=')
#    quote do:
#      var t = default(`o`)
#      compiles(`setter`(t, default(`v`)))
#  quote do: inner `fieldIdent`, `objType`, `valueType` 

macro hasSetter*[T: object; V](
    objType: typedesc[T],
    valueType: typedesc[V],
    fieldIdent): bool =
  expectKind objType, nnkSym
  expectKind valueType, nnkSym
  macro inner(f, o, v): untyped =
    let setter = ident(f.strVal & '=')
    quote do:
      var t = default(`o`)
      compiles(`setter`(t, default(`v`)))
  quote do: inner `fieldIdent`, `objType`, `valueType` 
  #macro inner(f, o, v): untyped =
    #expectKind o, nnkSym
    #expectKind v, nnkSym
  #  quote do: hasSetterImpl(`f`, `o`, `v`)
  #let ident = fieldIdent.repr
  #inner(ident, objType, valueType)
  #quote do: hasSetterImpl(`ident`, T, V)

func insideDefiningModule*[T](): bool =
  discard

macro init[T: object](t: typedesc[T], initializer): untyped =
  ## Initialize an object with a custom initializer AST.
  ## DESIGN
  ##   - The initializer is a tuple with named fields.
  ##   - Sorts field assignments by those that can be set in an object constructor
  ##     versus those that need to use an assignment operator.
  ##   - compose this AST for type T:
  ##     WITH
  ##       type T = object
  ##         private: int
  ##         public*: int
  ##       func private*(self: T): int = self.private
  ##       func `private=`*(self: var T, value: int) = self.private = value
  ##     GIVEN
  ##       let t = init[T]((public: 2, private: 1))
  ##     EXPECT
  ##       let t = (proc: T =
  ##         result = T(public: 2)
  ##         `private=`(result, 1)
  ##       )()
  let initIdent = ident("init" & $t)
  result = quote do:
    func `initIdent`: `t` {.inline.} = discard
  echo result.repr
  #result = nnkObjConstr.newTree(T)
  #var sample = default T
  #var o = newLit sample
#[   for k, v in sample.fieldPairs:
    if k == "exitCode":
      when compiles(sample.exitCode = v):
        dbg "y"
      else: dbg "n" ]#
      #dbg k & " == " & $v.typeof
#[   macro inner(x: untyped): untyped =
    result = quote do:
      dbg sample.`x`.typeof
    dbg x.kind
    dbg result.repr
  proc print(x: NimNode) {.compileTime.} =
    inner x ]#
  #initializer.matchAst:
  #of nnkNilLit: return
  #of `i` @ nnkPar:
  #  for kv in i:
  #    let doAssign = hasSetter(kv[0])
      #inner kv[0]
  #    result.add nnkExprColonExpr.newTree(kv[0], kv[1])


when isMainModule and defined test:
  import std/unittest
  import typetraits

  suite "override object fields from tuple of matching fields":

    setup:
      type B = distinct char
      type A = object
        a, c: int
        b*: int
        d: B
      func a(self: A): int = self.a
      func `a=`(self: var A; value: int) = self.a = value
      func `d=`(self: var A; value: B) {.used.} = self.d = value
      func `d=`(self: var A; value: char) {.used.} = self.d = B(value)

    test "init fom tuple":
      let a = init(A, (a: 1, b: 3))
      check a.a == 1 # calls `a(A): int`
      check a.b == 3

    test "detect when an object property has a setter":
      doAssert hasSetter(A, B, d)
      check hasSetter(A, char, d)
      check not hasSetter(A, int, d)

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

