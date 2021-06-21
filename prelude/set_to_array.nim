import pkg/ast_pattern_matching


macro setToArray*(initializer): array =
  var bracket = nnkBracket.newTree
  initializer.matchAst:
  of `setConstructor` @ nnkCurly:
    for child in setConstructor:
      child.matchAst:
      of `value` @ nnkIntLit:
        bracket.add newIntLitNode value.intVal
      of nnkInfix(ident"..", `low` @ nnkIntLit, `high` @ nnkIntLit):
        for value in low.intVal..high.intVal:
          bracket.add newIntLitNode value
  quote do: `bracket`


when isMainModule:
  import std/unittest
  test "macro setToArray*(initializer): array":
    check setToArray({0, 1..5}) == [0,1,2,3,4,5]
