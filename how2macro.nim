import pkg/prelude/[common, lib]
import std/unittest

type A = object
type B = object
  a: int
  b*: A
  d*: char

macro typeOfExpr(expr): untyped =
  quote do:
    let v = `expr`
    v.typeof

proc callme(i: int): char =
  echo "side effect"
  'a'
macro typeOfCallExpr(expr): untyped =
  quote do:
    let v = `expr`
    v.typeof

macro compileTimeExprEval(expr): bool =
  quote do: `expr`

#type AstConverterProc = proc(ast:NimNode):NimNode{.nimcall,noSideEffect,compileTime.}

var astConverters {.compileTime.} : seq[(NimNode, NimNode)]

func intToChar(v: NimNode): NimNode {.compileTime.} =
  quote do: bindsym"void"

macro registerAstConverter(resultType, astConverter) =
  astConverters.add (`resultType`, `astConverter`)
#proc registerAstConverter(resultType, astConverter: NimNode): NimNode {.compileTime.} =
#  quote do: astConverters.add (`resultType`, `astConverter`)

proc b(f: NimNode) {.compileTime.} =
  let s = bindSym f

macro dslToConcreteType(expr): untyped =
  result = bindsym"bool"
  macro inner(e, f): untyped =
    quote do:
      let v = `e`
      echo lispRepr `f`
      when compiles(`f`(newLit(0))):
        echo "yup"
      else: echo "nope"
  for (t, f) in astConverters:
    inner expr, f
    #let r = f(expr)
    #if r.kind != nnkEmpty:
    #  result = quote do:
    #    let t = `r`
    #    typeof t

macro macroCallingMacro(expr): bool =
  quote do: compileTimeExprEval(`expr`)

registerAstConverter char, intToChar
echo compileTimeExprEval(5 == 5)
echo typeOfExpr(A())
echo macroCallingMacro(5 == 5)
echo typeOfCallExpr(callme(5))
#echo dslToConcreteType callme(5)
