## =========
## Optimized
## =========
##
## TODO
## ----
## * 
## * 
## * 
##

import "."/compiler_config_utils

when backend() in {c, cpp, objc}:

  template gccAndClang =
    {.passc: "-march=native".}

  when compiler() == gcc:
    # https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html
    {.passc: "-Ofast".}
    # https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html#index-fwhole-program
    {.passc: "-flto:auto".}
    {.passl: "-flto:auto".}
    # https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html#index-flto
    gccAndClang

  elif compiler() == clang:
    # https://llvm.org/docs/SpeculativeLoadHardening.html
    gccAndClang

  elif compiler() == msvc:
    # https://docs.microsoft.com/en-us/cpp/build/reference/compiler-options-listed-by-category
    {.passc: "/Ot".}
    # https://docs.microsoft.com/en-us/cpp/build/reference/ltcg-link-time-code-generation
    # https://docs.microsoft.com/en-us/cpp/build/reference/gl-whole-program-optimization
    # https://docs.microsoft.com/en-us/cpp/build/profile-guided-optimizations

  when defined nimscript:
    task pgo, "profile guided optimization":
      echo "running pgo build"
