# Intended to be included rather than imported.
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
  T*: typedesc[T]
  isExported*: bool
  isDeclaredInScope*: bool

type FieldInitKind* {.pure.} = enum
  private, constructor, setter, assign, iterate

macro getFieldInfo*[T: object](self: typedesc[T]; field: untyped): ObjectFieldInfo =
  macro inner(s, f): (NimNode, NimNode) =
    quote do: getFieldInfoNodes(`s`, `f`.strVal)
  let (t, x) = inner(self, field)
  quote do: ObjectFieldInfo[`t`](isExported: `x`, isDeclaredInScope: declaredInScope(`t`))

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

func hasSetterImpl*[T: object; V](
    objType: typedesc[T];
    valueType, fieldIdent: NimNode): NimNode  {.compileTime.} =
  ## For compiletime procs/funcs, macros and templates.
  expectKind objType, nnkSym
  expectKind valueType, nnkSym
  expectKind fieldIdent, nnkIdent
  macro inner(f, o, v): untyped =
    let setter = ident(f.strVal & '=')
    quote do:
      var t = default(`o`)
      compiles(`setter`(t, default(`v`)))
  quote do: inner `fieldIdent`, `objType`, `valueType` 

macro hasSetter*[T: object; V](
    objType: typedesc[T],
    valueType: typedesc[V],
    fieldIdent: untyped): bool =
  ## Not for compiletime procs/funcs, macros or templates.
  expectKind objType, nnkSym
  expectKind valueType, nnkSym
  # expectKind fieldIdent, nnkIdent
  macro inner(f, o, v): untyped =
    let setter = ident(f.strVal & '=')
    result = quote("@") do:
      var t = default(@o)
      compiles(`@setter`(t, default(@v)))
    echo repr result
  quote do: inner `fieldIdent`, `objType`, `valueType`

func insideDefiningModule*[T](): bool =
  discard

func getNimNodeType(v: NimNode): NimNode {.compiletime} =
  case v.kind:
  of nnkCharLit: return macros.getType(char)
  of nnkIntLit: return macros.getType(int)
  of nnkInt8Lit: return macros.getType(int8)
  of nnkInt16Lit: return macros.getType(int16)
  of nnkInt32Lit: return macros.getType(int32)
  of nnkInt64Lit: return macros.getType(int64)
  of nnkUIntLit: return macros.getType(uint)
  of nnkUInt8Lit: return macros.getType(uint8)
  of nnkUInt16Lit: return macros.getType(uint16)
  of nnkUInt32Lit: return macros.getType(uint32)
  of nnkUInt64Lit: return macros.getType(uint64)
  of nnkFloatLit: return macros.getType(float)
  of nnkFloat32Lit: return macros.getType(float32)
  of nnkFloat64Lit: return macros.getType(float64)
  #of nnkFloat128Lit: return macros.getType(float128) #TODO: ?
  of nnkStrLit: return macros.getType(string)
  of nnkRStrLit: return macros.getType(string)
  of nnkTripleStrLit: return macros.getType(string)
  of nnkNilLit: return macros.getType(nil)
  of nnkCall:
    # TODO: check if ident is object
    alias ident, v[0]
    # debugecho ident.getImpl.repr
    # debugecho v.getType.repr
    return macros.getType(nil)
  else:
    debugEcho type(v)
    doAssert false, "unhandled nimnode type: " & v.lispRepr

macro initFromTuple*[T: object](self: typedesc[T], initializer): untyped =
  ## Initialize an object with a custom initializer AST.
  ## DESIGN
  ##   - The initializer is a tuple with named fields.
  ##   - Sorts field assignments by those that can be set in an object constructor
  ##     versus those that need to use an assignment operator.
  ##     - 
  ##     - setter calls:
  ##       - try compiling a call to the setter with the given value type 
  ##     - constructor params (field has no setter for field with given value type):
  ##       - literal value type matches the field type.
  ##         lookup field type and compare it to the given value type
  ##       - literal value type implicitly convertable to the field's type.
  ##         lookup field type and try to compile an implicit conversion from the given value type
  ##   - WITH
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
  let sym = ident(self.strVal)
  var params: seq[(NimNode, NimNode)]

  initializer.matchAst:
  of `exprColonExpr` @ nnkTupleConstr:
    for kv in exprColonExpr:
      params.add (kv[0], kv[1])

  result = buildAst(call):
    par:
      funcDef:
        newEmptyNode()
        newEmptyNode()
        newEmptyNode()
        formalParams:
          command:
            ident"owned"
            sym
        newEmptyNode()
        newEmptyNode()
        stmtList:
          macroDef:
            ident"init0"
            newEmptyNode()
            newEmptyNode()
            formalParams:
              ident"untyped"
            newEmptyNode()
            newEmptyNode()
            stmtList:
              newVarStmt ident"constructor", nnkCall.newTree(
                nnkDotExpr.newTree(newIdentNode("nnkObjConstr"), newIdentNode("newTree"))
                )
              newVarStmt ident"setterCalls", newCall "newStmtList"
              command:
                dotExpr:
                  ident"constructor"
                  ident"add"
                command:
                  ident"ident"
                  newLit("A")
              varSection:
                identDefs:
                  ident"t"
                  newEmptyNode()
                  command:
                    ident"default"
                    sym
              for (k, v) in params:
                ifStmt:
                  elifBranch(newCall(ident"compiles", newCall(nnkAccQuoted.newTree(k.strVal.ident, ident"="), ident"t", v))):
                    command:
                      dotExpr:
                        ident"setterCalls"
                        ident"add"
                      call:
                        ident"quote"
                        newLit "@"
                        stmtList:
                          call:
                            accQuoted:
                              k.strVal.ident
                              ident"="
                            ident"result"
                            v
                  `else`:
                    command:
                      dotExpr:
                        ident"constructor"
                        ident"add"
                      call:
                        dotExpr:
                          ident"nnkExprColonExpr"
                          ident"newTree"
                        call:
                          ident"ident"
                          k.strVal.newLit
                        parseStmt(v.astGenRepr)
                  
              call:
                ident"quote"
                stmtList:
                  call:
                    par:
                      funcDef:
                        newEmptyNode()
                        newEmptyNode()
                        newEmptyNode()
                        formalParams:
                          command:
                            ident"owned"
                            sym
                        newEmptyNode()
                        newEmptyNode()
                        stmtList:
                          asgn(ident"result", accQuoted(ident"constructor"))
                          accQuoted:
                            ident"setterCalls"
          call:
            ident"init0"


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

    test "init from tuple":
      block:
        let a = initFromTuple(A, (a: 1, b: 3, d: '5'.B))
        check a.a == 1
        check a.b == 3
        check a.d.char == '5'

    # test "get expression type":
    #   doAssert type(0) is int
    #   doAssert type('5'.B) is B
    #   template x(e: untyped): untyped =
    #     type(e)
    #   macro y(e: untyped): untyped =
    #     getAst x e
    #   doAssert y('5'.B) is B

    # test "detect when an object property has a setter":
    #   doAssert hasSetter(A, B, d)
    #   check hasSetter(A, char, d)
    #   check not hasSetter(A, int, d)

    # test "a":
    #   doAssert getFieldInfo(A, a).T is int
    #   var info =  getFieldInfo(A, a)
    #   doAssert info.T is int
    #   info = getFieldInfo(A, b)
    #   check info.T is int
    #   check info.isExported
    #   check info.isDeclaredInScope

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

