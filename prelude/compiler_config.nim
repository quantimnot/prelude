# https://nim-lang.github.io/Nim/nimc.html
# https://nim-lang.github.io/Nim/nimscript.html

when defined nimscript:
  hint "Processing", off
  hint "GlobalVar", on
  hint "Performance", on
  switch("verbosity", "0")
  switch("styleCheck", "off")
  switch("excessiveStackTrace", "off")

  task build_debug, "Build debug target for the default backend":
    switch "undef", "release"
    switch "define", "debug"
    setCommand("c")

  task build_release, "Build release target for the default backend":
    switch "undef", "debug"
    switch "define", "release"
    setCommand("c")

  task build_ios_Sim, "Build for iOS simulator":
    doAssert false, "TODO" # TODO

  task run_ios_sim, "Run with iOS simulator":
    build_ios_simTask()
    doAssert false, "TODO" # TODO

  task build_android_sim, "Build for Android simulator":
    doAssert false, "TODO" # TODO

  task run_android_sim, "Run with Android simulator":
    build_android_simTask()
    doAssert false, "TODO" # TODO

  task build_nodejs, "Build for NodeJS":
    setCommand("js")
    doAssert false, "TODO" # TODO

  task run_nodejs, "Run with NodeJS":
    buildNodejsTask()
    switch("run")

  task build_web_js, "Build js for web browser":
    setCommand("js")

  task build_web_wasm, "Build emscripten-wasm for web browser":
    setCommand("js")
    doAssert false, "TODO" # TODO

  task build_web_emscripten, "Build emscripten for web browser":
    setCommand("js")
    doAssert false, "TODO" # TODO

  task run_browser, "Run with default web browser":
    buildWebJsTask()
    doAssert false, "TODO" # TODO

  task run_firefox, "Run with Firefox":
    buildWebJsTask()
    doAssert false, "TODO" # TODO

  task run_chrome, "Run with Chrome":
    buildWebJsTask()
    doAssert false, "TODO" # TODO

  task run_rr, "Run with RR":
    buildDebugTask()
    doAssert false, "TODO" # TODO

  task run_gdb, "Run with GDB":
    buildDebugTask()
    doAssert false, "TODO" # TODO

  task run_lldb, "Run with LLDB":
    buildDebugTask()
    doAssert false, "TODO" # TODO

when defined release:
  {.hint: "RELEASE MODE".}
  {.define: sanitize.}
  {.define: runtime_checks.}
  when defined nimscript:
    switch "opt", "speed"
else:
  {.hint: "DEBUG MODE".}
  {.define: debug.}
  {.define: sanitize.}
  {.define: runtime_checks.}
  when defined nimscript:
    switch "debugger", "native"

when defined runtime_checks:
  when defined nimscript:
    switch "checks", "on"
    switch "assertions", "on"
elif defined danger:
  {.warning: "DANGER MODE".}
  {.undef: hardened.}
  {.undef: sanitize.}
  {.undef: runtime_checks.}
  when defined nimscript:
    switch "checks", "off"
    switch "assertions", "off"
else:
  when defined hardened:
    import prelude/hardened
