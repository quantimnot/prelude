## ATTRIBUTION
##   This is from @krux02:
##     https://github.com/nim-lang/Nim/issues/6676#issuecomment-489108350

import macros

proc processNode(arg, a,b, result: NimNode): void {.compileTime.} =
  case arg.kind
  of nnkIdentDefs:
    let field = arg[0]
    result.add quote do:
      if `a`.`field` != `b`.`field`:
        return false
  of nnkRecCase:
    let kindField = arg[0][0]
    processNode(arg[0], a,b, result)
    let caseStmt = nnkCaseStmt.newTree(newDotExpr(a, kindField))
    for i in 1 ..< arg.len:
      let inputBranch = arg[i]
      let outputBranch = newTree(inputBranch.kind)
      let body = newStmtList()
      if inputBranch.kind == nnkOfBranch:
        outputBranch.add inputBranch[0]
        processNode(inputBranch[1], a,b, body)
      else:
        inputBranch.expectKind nnkElse
        processNode(inputBranch[0], a,b, body)
      outputBranch.add body
      caseStmt.add outputBranch
    result.add caseStmt
  of nnkRecList:
    for child in arg:
      child.expectKind {nnkIdentDefs, nnkRecCase}
      processNode(child, a,b, result)
  else:
    arg.expectKind {nnkIdentDefs, nnkRecCase, nnkRecList}

macro compareVariantImpl(a,b: typed): untyped =
  a.expectKind nnkSym
  b.expectKind nnkSym
  let typeImpl = a.getTypeImpl
  # assert typeImpl == b.getTypeImpl # TODO: this is failing in some cases where they are the same
  # echo typeImpl.treeRepr # uncomment to debug
  result = newStmtList()
  processNode(typeImpl[2], a, b, result)
  result.add quote do:
    return true
  # echo result.repr # uncomment to debug

proc compareVariant*[T: object](a,b: T): bool =
  compareVariantImpl(a,b)

when isMainModule:
  type
    Kind = enum
      First, Second

    Subkind = enum
      SFirst, SSecond

    Foo = object
      value1: int
      value2: string
      value4, value5: float
      case kind: Kind
      of First:
        case subkind: Subkind
        of SFirst:
          n11: int
        of SSecond:
          n12: int
      else:
        n2: int

  proc `==`*(a,b: Foo): bool =
    compareVariant(a,b)

  var f1: Foo
  var f2: Foo

  echo f1 == f2 # true
  f2.n11 = 17
  echo f1 == f2 # false
