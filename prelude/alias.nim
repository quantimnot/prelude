template alias*(newName, call: untyped) =
  ## Create an alias to a symbol.
  ## https://blog.johnnovak.net/2020/12/21/nim-apocrypha-vol1/#15--aliases
  ## TODO
  ##   - implement lhs assignments
  template newName(): untyped = call

template exportAlias*(newName, call: untyped) {.dirty.} =
  ## Create an exported alias to a symbol.
  ## DESIGN
  ##   This only exists because `alias b*, a` won't compile at
  ##   nim commit c548f97241c9f0da8f9442c07b99dd9d6adf225a.
  template newName*(): untyped {.dirty.} = call
