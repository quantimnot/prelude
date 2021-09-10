import pkg/ast_pattern_matching


macro setCtorToArrayCtor*(initializer): array =
  var bracket = nnkBracket.newTree
  initializer.matchAst:
  of `setConstructor` @ nnkCurly:
    for child in setConstructor:
      child.matchAst:
      of `value` @ nnkIntLit:
        bracket.add newIntLitNode value.intVal
      of nnkHiddenStdConv(nnkEmpty, `value` @ nnkIntLit):
        bracket.add newIntLitNode value.intVal
      of nnkInfix(ident"..", `low` @ nnkIntLit, `high` @ nnkIntLit):
        for value in low.intVal..high.intVal:
          bracket.add newIntLitNode value
      of nnkRange(nnkHiddenStdConv(nnkEmpty, `low` @ nnkIntLit), nnkHiddenStdConv(nnkEmpty, `high` @ nnkIntLit)):
        for value in low.intVal..high.intVal:
          bracket.add newIntLitNode value
  else:
    doAssert false, "invalid set constructor form; see https://nim-lang.github.io/Nim/macros.html#callsslashexpressions-curly-braces and https://nim-lang.github.io/Nim/macros.html#callsslashexpressions-ranges"
    bracket.add newEmptyNode() # never reached; just satisfies the compiler
  quote do: `bracket`


when isMainModule:
  import std/unittest
  test "macro setCtorToArrayCtor*(initializer): array":
    check setCtorToArrayCtor({0, 2..5}) == [0,2,3,4,5]
  test "passed through untyped template/macro":
    template t(i): array = setCtorToArrayCtor(i)
    check t({0, 2..5}) == [0,2,3,4,5]
