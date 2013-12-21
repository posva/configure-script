
#! /bin/bash

# I usually have this kind of script in my project folder so that I don't have to manually write the configure options everytime I add new dependencies to the project
# This is a basic one for a C project
# You can find a better one for a C++ project here:
# https://github.com/posva/InputManager
# This script works on Windows. Installing cygwin is the easiest way to get this working

if [ `uname` = "Darwin" ]; then
  ./configure.sh -aD -s src -o obj -b bin -c "xcrun clang" -O "-Wall -Wextra -O2" -Isrc -L/usr/local/lib -e c -E main -M Makefile -l "-lm" $@
elif [ `uname` = "Linux" ]; then
  ./configure.sh -aD -s src -o obj -b bin -c "clang" -O "-Wall -Wextra -O2" -Isrc -L/usr/local/lib -e c -E main -M Makefile -l "-lm" $@
else
  ./configure.sh -aD -s src -o obj -b bin -c "mingw32-gcc" -O "-Wall -Wextra -O2" -Isrc -e cpp -E main -M Makefile -l "-lm" $@
fi
