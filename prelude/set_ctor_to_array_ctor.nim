import
  std/[strutils, sequtils, sets],
  pkg/ast_pattern_matching


macro setToArray*(initializer: untyped): array =
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
        bracket.add child
  else:
    error dedent"""
      Error: invalid set constructor form
      See:
        https://nim-lang.github.io/Nim/macros.html#callsslashexpressions-curly-braces
        https://nim-lang.github.io/Nim/macros.html#callsslashexpressions-ranges
    """, initializer
    bracket.add newEmptyNode() # never reached; just satisfies the compiler
  quote do:
    (func(): auto {.compileTime.} =
      return static:
        const a = `bracket`
        const r = 0..a.len-1
        for idx0 in r:
          for idx1 in r:
            if idx0 != idx1 and a[idx0] == a[idx1]:
              error "Sets can't have duplicate values." # TODO: how can I get the NimNode here??
        a
    )()


when isMainModule:
  import std/unittest
  test "macro setToArray*(initializer): array":
    check setToArray({0, 2..5}) == [0,2,3,4,5]
  test "passed through untyped template/macro":
    template t(i): array = setToArray(i)
    check t({0, 2..5, int.high}) == [0,2,3,4,5,int.high]
