## ========
## Hardened
## ========
##
## * [C-Based Toolchain Hardening Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/C-Based_Toolchain_Hardening_Cheat_Sheet.html)
## * [Debian: Hardening](https://wiki.debian.org/Hardening)
## * [Clang hardening optsions](https://blog.quarkslab.com/clang-hardening-cheat-sheet.html)
##
## TODO
## ----
## * Incorporate [Clang hardening optsions]
## * Incorporate [C-Based Toolchain Hardening Cheat Sheet]
## * 
## * 
## * 
##

import system/platforms

type Backend {.pure.} = enum
  c, cpp, objc, js, other

template backend: Backend =
  when defined c: c
  elif defined cpp: cpp
  elif defined objc: objc
  elif defined js: js
  else: Backend.other

type Compiler {.pure.} = enum
  gcc, clang, msvc, nodejs, other

template compiler: Compiler =
  when defined gcc: gcc
  elif defined clang: clang
  elif defined msvc: msvc
  elif defined nodejs: nodejs
  else: Compiler.other

type AppKind {.pure.} = enum
  console, gui, lib, staticlib, other

template appKind: AppKind =
  when defined console: console
  elif defined gui: gui
  elif defined lib: lib
  elif defined staticlib: staticlib
  else: AppKind.other

when backend() in {c, cpp, objc}:
  # https://security.stackexchange.com/questions/24444/what-is-the-most-hardened-set-of-options-for-gcc-compiling-c-c

  when compiler() in {gcc, clang}:
    {.passC: "-Wall -Wextra".}
    # Turn on all warnings to help ensure the underlying code is correct.
    {.passC: "-Wconversion -Wsign-conversion".}
    # > Warn on unsign/sign conversion.
    {.passC: "-Wformat­-security".}
    # > Warn about uses of format functions that represent possible security problems.
    {.passC: "-Werror".}
    # > Turns all warnings into errors.
    when appKind() in {lib, staticlib}:
      {.passC: "-fPIC".}
    else: {.passC: "-pie -fPIE".}
    # > Required to obtain the full security benefits of ASLR.

  elif compiler() in {gcc}:
    {.passC: "-mmitigate-rop".}
    # > Attempt to compile code without unintended return addresses, making ROP just a little harder.
    {.passC: "-mindirect-branch=thunk -mfunction-return=thunk".}
    # > Enables retpoline (return trampolines) to mitigate some variants of Spectre V2. The second flag is necessary on Skylake+ due to the fact that the branch target buffer is vulnerable.
    {.passL: "-fstack-protector-all -Wstack-protector --param ssp-buffer-size=4".}
    # > Your choice of "-fstack-protector" does not protect all functions (see comments). You need -fstack-protector-all to guarantee guards are applied to all functions, although this will likely incur a performance penalty. Consider -fstack-protector-strong as a middle ground.
    # > The -Wstack-protector flag here gives warnings for any functions that aren't going to get protected.
    {.passL: "-fstack-clash-protection".}
    # > Defeats a class of attacks called stack clashing.
    {.passL: "-ftrapv".}
    # > Generates traps for signed overflow (currently bugged in gcc, and may interfere with UBSAN).
    {.passL: "-­D_FORTIFY_SOURCE=2".}
    # > Buffer overflow checks. See also difference between =2 and =1.
    {.passL: "-z,relro,-z,now".}
    # > RELRO (read-only relocation). The options relro & now specified together are known as "Full RELRO". You can specify "Partial RELRO" by omitting the now flag. RELRO marks various ELF memory sections read­only (E.g. the GOT).
    {.passL: "-z,noexecheap".}
    {.passL: "-z,noexecstack".}
    # > Non-executable stack. This option marks the stack non-executable, probably incompatible with a lot of code but provides a lot of security against any possible code execution. (https://www.win.tue.nl/~aeb/linux/hh/protection.html)
    {.passL: "-fvtable-verify=std".}
    # > Vtable pointer verification. It enables verification at run time, for every virtual call, that the vtable pointer through which the call is made is valid for the type of the object, and has not been corrupted or overwritten. If an invalid vtable pointer is detected at run time, an error is reported and execution of the program is immediately halted.(https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html)
    {.passL: "-fcf-protection=full".}
    # > Enable code instrumentation of control-flow transfers to increase program security by checking that target addresses of control-flow transfer instructions (such as indirect function call, function return, indirect jump) are valid. Only available on x86(_64) with Intel's CET. (https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html)

  elif compiler() in {clang}:
    # https://llvm.org/docs/SpeculativeLoadHardening.html
    discard

  elif compiler() in {msvc}:
    # https://docs.microsoft.com/en-us/cpp/c-runtime-library/security-features-in-the-crt
    # https://docs.microsoft.com/en-us/cpp/build/reference/compiler-options-listed-by-category

    {.passC: "/RTCcsu".}
    # https://docs.microsoft.com/en-us/cpp/build/reference/rtc-run-time-error-checks
    {.passC: "/guard:cf".}
    # https://docs.microsoft.com/en-us/cpp/build/reference/guard-enable-control-flow-guard
    {.passC: "/guard:ehcont".}
    # https://docs.microsoft.com/en-us/cpp/build/reference/guard-enable-eh-continuation-metadata
    {.passC: "/Qspectre".}
    # https://docs.microsoft.com/en-us/cpp/build/reference/qspectre
    {.passC: "/Qspectre-load".}
    # https://docs.microsoft.com/en-us/cpp/build/reference/qspectre-load
    {.passC: "/Qspectre-load-cf".}
    # https://docs.microsoft.com/en-us/cpp/build/reference/qspectre-load-cf
    {.passC: "/analyze".}
    # https://docs.microsoft.com/en-us/cpp/build/reference/analyze-code-analysis
    {.passC: "/fsanitize=address".}
    # https://docs.microsoft.com/en-us/cpp/build/reference/fsanitize
    {.passC: "/fsanitize-address-use-after-return ".}
    # https://docs.microsoft.com/en-us/cpp/build/reference/fsanitize
    {.passC: "/fno-sanitize-address-vcasan-lib".}
    # https://docs.microsoft.com/en-us/cpp/build/reference/fsanitize
    {.passC: "/sdl".}
    # https://docs.microsoft.com/en-us/cpp/build/reference/sdl-enable-additional-security-checks
    {.passC: "/D_CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES 1".}
    {.passC: "/D_CRT_SECURE_CPP_OVERLOAD_STANDARD_NAMES_COUNT 1".}
    # https://docs.microsoft.com/en-us/cpp/c-runtime-library/secure-template-overloads
    {.passC: "/WE4789".}
    # https://www.slideshare.net/javitallon/mitigating-overflows-using-defense-indepth-what-can-your-compiler-do-for-you-97058340

    # MSVC Linker
    # https://docs.microsoft.com/en-us/cpp/build/reference/linker-options
    {.passL: "/INFERASANLIBS".}
    {.passL: "/GUARD:CF".}
    # https://docs.microsoft.com/en-us/cpp/build/reference/guard-enable-guard-checks
    {.passL: "/HIGHENTROPYVA".}
    # https://docs.microsoft.com/en-us/cpp/build/reference/highentropyva-support-64-bit-aslr
    {.passL: "/DYNAMICBASE".}
    # https://docs.microsoft.com/en-us/cpp/build/reference/dynamicbase-use-address-space-layout-randomization
    {.passL: "/INTEGRITYCHECK".}
    # https://docs.microsoft.com/en-us/cpp/build/reference/integritycheck-require-signature-check
    {.passL: "/NXCOMPAT".}
    # https://docs.microsoft.com/en-us/cpp/build/reference/nxcompat-compatible-with-data-execution-prevention

  when targetOS in {windows}:

    when compiler() in {gcc, clang}:
      {.passL: "-Wl,dynamicbase".}
      # > Tell linker to use ASLR protection.
      {.passL: "-Wl,nxcompat".}
      # > Tell linker to use DEP protection.

  elif targetOS in {macosx}:
    {.passL: "-Wl,-sectcreate,__RESTRICT,__restrict,/dev/null".}
    # Prevent symbol interposition. https://stackoverflow.com/a/29667177
    #
    # Note:
    # Interposition is not possible if SIP, Gatekeeper or AMFI are enabled.
    # https://jon-gabilondo-angulo-7635.medium.com/how-to-inject-code-into-mach-o-apps-part-ii-ddb13ebc8191
    # They are enabled by default.
    # TODO: macosx binaries can also be entitled with capabilities using the `codesign` tool
