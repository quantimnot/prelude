from system/platforms import targetOS
export platforms.targetOS

type Backend* {.pure.} = enum
  c, cpp, objc, js, other

template backend*: untyped =
  when defined c: c
  elif defined cpp: cpp
  elif defined objc: objc
  elif defined js: js
  else: Backend.other

type Compiler* {.pure.} = enum
  gcc, clang, msvc, nodejs, other

template compiler*: untyped =
  when defined gcc: gcc
  elif defined clang: clang
  elif defined msvc: msvc
  elif defined nodejs: nodejs
  else: Compiler.other

type AppKind* {.pure.} = enum
  console, gui, lib, staticlib, other

template appKind*: untyped =
  when defined console: console
  elif defined gui: gui
  elif defined lib: lib
  elif defined staticlib: staticlib
  else: AppKind.other
