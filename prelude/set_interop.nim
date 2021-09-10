## Declares common set operations.

import std/intsets
import "."/set_ctor_to_array_ctor


proc `<`*[T](x: set[T], y: IntSet): bool =
  ## Returns true if `x` is a subset of `y`.
  if y.len > x.len:
    return false
  for n in x:
    if not n in y:
      return false
  return true


proc `<=`*[T](x: set[T], y: IntSet): bool =
  ## Returns true if `x` is a proper subset of `y`.
  for n in x:
    if not n in y:
      return false
  return true


when isMainModule:
  import std/unittest
  test "init intset":
    var a = setCtorToArrayCtor({0, 1..5}).toIntSet
    check {0..5} <= a
    check not ({0..4} < a)
    check 0 in a
