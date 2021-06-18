include pkg/prelude

type A = object
  a: int
let a = new A
#with a:
#  a = 7
a.a = 7
assert a.a == 7
alias b, a.a
assert b == 7
