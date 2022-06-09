import system/platforms
export platforms
import std/compilesettings

type Backend* {.pure.} = enum
  c, cpp, objc, js

template backend*: untyped =
  when querySetting(SingleValueSetting.backend) == "c": c
  elif querySetting(SingleValueSetting.backend) == "cpp": cpp
  elif querySetting(SingleValueSetting.backend) == "objc": objc
  elif querySetting(SingleValueSetting.backend) == "js": js

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
