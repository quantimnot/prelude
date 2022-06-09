# StdLib
import std/[sugar, with, os, strutils, times, parseutils, hashes, tables, sets, setutils, packedsets]
from std/sequtils import delete
export sugar, with, os, strutils, times, parseutils, hashes, tables, sets, sequtils.delete, setutils, packedsets

# Fusion
import fusion/[matching]
export matching

# Third Party
import pkg/[zero_functional, safeoptions, iface, print]
export zero_functional, safeoptions, iface, print

# First Party
import pkg/[error, debug, log, test]
import "."/alias, "."/init
export alias, error, debug, log, init, test

#when compileOption("rangechecks"):
#when compileOption("rangechecks"):

template preconditions*(body): untyped =
  when not defined danger:
    body

template postconditions*(body): untyped =
  when not defined danger:
    body

type
  Path* = string ## File path
